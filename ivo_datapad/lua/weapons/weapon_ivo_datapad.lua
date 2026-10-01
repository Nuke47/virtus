AddCSLuaFile()

SWEP.PrintName          = "Datapad Imperial"
SWEP.Category           = "Ivo Datapad"
SWEP.Author             = "Antigravity"
SWEP.Instructions       = "Click Izquierdo o Recargar para abrir la interfaz del Datapad."
SWEP.Purpose            = "Terminal de datos portátil"

SWEP.Spawnable          = true
SWEP.AdminSpawnable     = true

SWEP.ViewModel          = "models/weapons/c_slam.mdl"
SWEP.WorldModel         = "models/wield_item/wield_civ_item_datapad.mdl"
SWEP.ViewModelFOV       = 70
SWEP.UseHands           = true

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = "none"

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"

SWEP.DrawAmmo           = false
SWEP.DrawCrosshair      = true

SWEP.LerpProgress       = 0

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "MenuOpen")
end

if SERVER then
    util.AddNetworkString("Datapad_SyncMenu")
    net.Receive("Datapad_SyncMenu", function(len, ply)
        local isOpen = net.ReadBool()
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_ivo_datapad" then
            wep:SetMenuOpen(isOpen)
        end
    end)
end

function SWEP:Initialize()
    self:SetHoldType("slam")
end

function SWEP:Deploy()
    self.IsHolstering = false
    local vm = self.Owner:GetViewModel()
    if IsValid(vm) then
        local seq = vm:LookupSequence("throw_to_tripmine_ND")
        if seq == -1 then seq = vm:LookupSequence("draw") end
        vm:SendViewModelMatchingSequence(self.CurrentSeq or seq)
        vm:SetPlaybackRate(0.7)
        self.NextIdle = CurTime() + (vm:SequenceDuration(seq) / 0.7)
        
        if CLIENT then
            -- Pantalla negra dura exactamente la animación de sacar el arma + 0.2s extra
            self.BootTime = CurTime() + (vm:SequenceDuration(seq) / 0.7) + 0.2
        end
    else
        if CLIENT then self.BootTime = CurTime() + 0.8 end
    end
    return true
end

function SWEP:Holster(wep)
    if not IsValid(wep) then return true end

    if CLIENT then
        self.DatapadActive = false
        self.ThirdPersonRP = false
        self.BootTime = nil -- Limpiar estado de inicio
        if self.WasDatapadActive then
            gui.EnableScreenClicker(false)
            self.WasDatapadActive = false
        end
    end

    -- Si ya estamos en proceso de guardado, dejamos que finalice el tiempo
    if self.IsHolstering then
        if CurTime() >= (self.HolsterTime or 0) then
            self.IsHolstering = false
            if CLIENT then
                local ply = LocalPlayer()
                if IsValid(ply) then
                    local hands = ply:GetHands()
                    if IsValid(hands) and self.OldHandsModel then
                        hands:SetModel(self.OldHandsModel)
                        self.OldHandsModel = nil
                    end
                end
            end
            if SERVER then self:SetMenuOpen(false) end
            return true
        end
        return false
    end
    
    -- Si no hay arma objetivo (ej: estamos dropeando el arma o muriendo), no hay animación
    if not IsValid(wep) then 
        if CLIENT then
            local ply = LocalPlayer()
            if IsValid(ply) then
                self:ResetTPBones(ply)
                local hands = ply:GetHands()
                if IsValid(hands) and self.OldHandsModel then
                    hands:SetModel(self.OldHandsModel)
                    self.OldHandsModel = nil
                end
            end
        end
        return true 
    end
    
    -- Iniciar animación de guardado
    self.IsHolstering = true
    self.TargetWeapon = wep
    self.HolsterTime = CurTime() + 0.5
    
    local vm = self.Owner:GetViewModel()
    if IsValid(vm) then
        local seq = vm:LookupSequence("throw_draw_ND")
        if seq ~= -1 then
            vm:SendViewModelMatchingSequence(seq)
            vm:SetPlaybackRate(-0.7)
            -- Forzar el ciclo al final para reproducir hacia atrás en el cliente
            if CLIENT then vm:SetCycle(1) end
            self.HolsterTime = CurTime() + ((vm:SequenceDuration(seq) / 0.7) or 0.7)
        end
    end
    
    return false
end

function SWEP:ResetTPBones(ply)
    if not IsValid(ply) then return end
    local bones = {
        "ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_R_Hand"
    }
    for _, b in ipairs(bones) do
        local id = ply:LookupBone(b)
        if id then ply:ManipulateBoneAngles(id, Angle(0,0,0)) end
    end
end

function SWEP:Think()
    if CLIENT then
        if self.DatapadActive and not self.WasDatapadActive then
            self.WasDatapadActive = true
            self.DrawCrosshair = false -- Oculta la mira nativa
            surface.PlaySound("weapons/universal/uni_weapon_draw_02.wav")
            
            if IsValid(self.CursorPanel) then self.CursorPanel:Remove() end
            
            self.CursorPanel = vgui.Create("DPanel")
            self.CursorPanel:SetSize(ScrW(), ScrH())
            self.CursorPanel.Paint = function() end
            self.CursorPanel:MakePopup()
            self.CursorPanel:SetKeyboardInputEnabled(false) -- Permite seguir caminando con WASD
            self.CursorPanel:SetCursor("blank") -- Oculta el cursor nativo de Windows
            
            self.CursorPanel.OnMousePressed = function(pnl, mouseCode)
                if mouseCode == MOUSE_RIGHT then
                    self.DatapadActive = false
                    surface.PlaySound("weapons/universal/uni_weapon_holster.wav")
                elseif mouseCode == MOUSE_LEFT then
                    local cx, cy = self:GetCursorPos3D()
                    if cx and cy then
                        for _, btn in ipairs(self.VirtualButtons or {}) do
                            if cx >= btn.x and cx <= btn.x + btn.w and cy >= btn.y and cy <= btn.y + btn.h then
                                surface.PlaySound("buttons/blip1.wav")
                                print("Botón presionado: " .. btn.text)
                                if btn.isClose then
                                    self.DatapadActive = false
                                    surface.PlaySound("weapons/universal/uni_weapon_holster.wav")
                                elseif btn.action then 
                                    btn.action(LocalPlayer()) 
                                end
                            end
                        end
                    end
                end
            end
            
        elseif not self.DatapadActive and self.WasDatapadActive then
            self.WasDatapadActive = false
            self.DrawCrosshair = true -- Devuelve la mira
            if IsValid(self.CursorPanel) then
                self.CursorPanel:Remove()
            end
        end
        
        local owner = self:GetOwner()
        if IsValid(owner) then
            if owner == LocalPlayer() then
                local isOpen = self.DatapadActive or self.ThirdPersonRP or false
                if self.LastMenuState ~= isOpen then
                    self.LastMenuState = isOpen
                    net.Start("Datapad_SyncMenu")
                    net.WriteBool(isOpen)
                    net.SendToServer()
                end
            end
        end
        
        -- Lógica del modo escáner en tiempo real
        if self.DatapadState == "scan_mode" then
            local ply = self.Owner
            if IsValid(ply) then
                local tr = util.TraceLine({
                    start = ply:EyePos(),
                    endpos = ply:EyePos() + ply:GetAimVector() * 60,
                    filter = ply
                })
                
                local hitEnt = tr.Entity
                if IsValid(hitEnt) and hitEnt:IsPlayer() then
                    if self.ScanTarget ~= hitEnt then
                        self.ScanTarget = hitEnt
                        self.ScanProgressStartTime = CurTime()
                        net.Start("Datapad_Scan_Start")
                        net.WriteEntity(hitEnt)
                        net.SendToServer()
                    end
                else
                    if IsValid(self.ScanTarget) then
                        net.Start("Datapad_Scan_Stop")
                        net.SendToServer()
                        self.ScanTarget = nil
                        self.ScanProgressStartTime = nil
                    end
                end
            end
        elseif self.DatapadState == "probe_link_mode" then
            local ply = self.Owner
            if IsValid(ply) then
                local tr = util.TraceLine({
                    start = ply:EyePos(),
                    endpos = ply:EyePos() + ply:GetAimVector() * 100,
                    filter = ply
                })
                
                local hitEnt = tr.Entity
                if IsValid(hitEnt) and hitEnt:GetClass() == "ent_probe_droid" then
                    if self.ScanTarget ~= hitEnt then
                        self.ScanTarget = hitEnt
                        self.ScanProgressStartTime = CurTime()
                        surface.PlaySound("npc/scanner/scanner_scan2.wav")
                    end
                    
                    if self.ScanProgressStartTime and (CurTime() - self.ScanProgressStartTime) >= 2.0 then
                        net.Start("Probe_Link")
                        net.WriteEntity(hitEnt)
                        net.SendToServer()
                        self:SetDatapadState("hub")
                        surface.PlaySound("npc/scanner/scanner_scan5.wav")
                        self.ScanTarget = nil
                        self.ScanProgressStartTime = nil
                    end
                else
                    if IsValid(self.ScanTarget) then
                        self.ScanTarget = nil
                        self.ScanProgressStartTime = nil
                    end
                end
            end
        end
    end

    if self.CurrentSeq then return end -- Si está buscando animaciones manuales, no forzar idle
    
    if self.IsHolstering then
        local vm = self.Owner:GetViewModel()
        if IsValid(vm) then
            vm:SetPlaybackRate(-1) -- Asegurarse de que siga en reversa
        end
        if CurTime() >= self.HolsterTime then
            if SERVER and IsValid(self.TargetWeapon) then
                self.Owner:SelectWeapon(self.TargetWeapon:GetClass())
            end
        end
        return
    end

    if self.NextIdle and CurTime() >= self.NextIdle then
        self.NextIdle = nil
        local vm = self.Owner:GetViewModel()
        if IsValid(vm) then
            local seq = vm:LookupSequence("throw_detonate")
            if seq ~= -1 then
                vm:SendViewModelMatchingSequence(seq)
            end
        end
    end
end

-- Bloquea todos los sonidos que vienen integrados en las animaciones del modelo
function SWEP:FireAnimationEvent(pos, ang, event, options)
    return true
end

function SWEP:GetViewModelPosition(pos, ang)
    local isOpen = self.DatapadActive and 1 or 0
    self.LerpProgress = Lerp(FrameTime() * 8, self.LerpProgress or 0, isOpen)

    local idleR, idleF, idleU = 0, 0, 0
    local idlePitch, idleYaw, idleRoll = 0, 0, 0

    local activeR = 0
    local activeF = -12
    local activeU = 0
    
    local activePitch = 9
    local activeYaw = 6
    local activeRoll = 1.5

    local curR = Lerp(self.LerpProgress, idleR, activeR)
    local curF = Lerp(self.LerpProgress, idleF, activeF)
    local curU = Lerp(self.LerpProgress, idleU, activeU)

    local curPitch = Lerp(self.LerpProgress, idlePitch, activePitch)
    local curYaw = Lerp(self.LerpProgress, idleYaw, activeYaw)
    local curRoll = Lerp(self.LerpProgress, idleRoll, activeRoll)

    pos = pos + ang:Right() * curR
    pos = pos + ang:Forward() * curF
    pos = pos + ang:Up() * curU
    
    ang:RotateAroundAxis(ang:Right(), curPitch)
    ang:RotateAroundAxis(ang:Up(), curYaw)
    ang:RotateAroundAxis(ang:Forward(), curRoll)

    return pos, ang
end

function SWEP:SetDatapadState(state)
    self.DatapadState = state
    self.StateStartTime = CurTime()
    
    if CLIENT and state ~= "scan_result" then
        if IsValid(self.HoloModel) then
            SafeRemoveEntity(self.HoloModel)
            self.HoloModel = nil
        end
    end

    if state == "login" then
        self:BuildLoginScreen()
    elseif state == "hub" then
        self:BuildHubScreen()
    elseif state == "docs_list" then
        self:BuildDocsListScreen()
    elseif state == "doc_view" then
        self:BuildDocViewScreen()
    elseif state == "isb" then
        self:BuildISBScreen()
    elseif state == "65th" then
        self:Build65thScreen()
    elseif state == "scan_mode" then
        self:BuildScanModeScreen()
        self.ScanTarget = nil
        self.ScanProgressStartTime = nil
    elseif state == "scan_result" then
        self:BuildScanResultScreen()
    elseif state == "scan_history" then
        self:BuildScanHistoryScreen()
    elseif state == "probe_link_mode" then
        self:BuildProbeLinkModeScreen()
        self.ScanTarget = nil
        self.ScanProgressStartTime = nil
    end
end

function SWEP:PrimaryAttack()
    if CLIENT then
        self.DatapadActive = true
        self.ThirdPersonRP = false
        self:SetDatapadState("login")
    end
end

function SWEP:CanPrimaryAttack()
    return true
end

function SWEP:SecondaryAttack()
    if CLIENT and IsFirstTimePredicted() then
        local owner = self:GetOwner()
        if IsValid(owner) and owner == LocalPlayer() and owner:ShouldDrawLocalPlayer() then
            if not self.DatapadActive then
                self.ThirdPersonRP = not self.ThirdPersonRP
                if self.ThirdPersonRP then
                    surface.PlaySound("weapons/universal/uni_weapon_draw_02.wav")
                else
                    surface.PlaySound("weapons/universal/uni_weapon_holster.wav")
                end
            end
        end
    end
end

function SWEP:Reload()
end



function SWEP:OnRemove()
    if CLIENT then
        self.DatapadActive = false
        self.ThirdPersonRP = false
        self.BootTime = nil
        if self.WasDatapadActive then
            self.WasDatapadActive = false
        end
        if IsValid(self.CursorPanel) then
            self.CursorPanel:Remove()
        end
        self:ResetTPBones(self:GetOwner())
        if IsValid(self.DatapadModel) then
            self.DatapadModel:Remove()
        end
        self:ResetHands(LocalPlayer())
    end
end

if CLIENT then
    local invisMat = Material("engine/occlusionproxy")

    function SWEP:BuildLoginScreen()
        local ply = LocalPlayer()
        
        -- Verificar si existe el archivo sh_config.lua
        if not (Datapad and Datapad.HasAccess) then
            self.VirtualButtons = {
                { id = "close", text = "CERRAR SISTEMA", x = -100, y = 160, w = 200, h = 45, color = Color(200, 50, 50), isClose = true }
            }
            return
        end

        local hasAccess = Datapad:HasAccess(ply, Datapad.Config.ISBJobs) or Datapad:HasAccess(ply, Datapad.Config.ShockJobs) or Datapad:HasAccess(ply, Datapad.Config.RiotJobs) or (Datapad.Config.SUSpecJobs and Datapad:HasAccess(ply, Datapad.Config.SUSpecJobs))
        
        if hasAccess then
            self.VirtualButtons = {
                { id = "login", text = "INICIAR SESIÓN", x = -100, y = 100, w = 200, h = 45, color = Color(50, 255, 50), action = function(p)
                    self:PerformLogin(p)
                end },
                { id = "close", text = "CERRAR SISTEMA", x = -100, y = 160, w = 200, h = 45, color = Color(200, 50, 50), isClose = true }
            }
        else
            self.VirtualButtons = {
                { id = "close", text = "CERRAR SISTEMA", x = -100, y = 160, w = 200, h = 45, color = Color(200, 50, 50), isClose = true }
            }
        end
    end

    function SWEP:PerformLogin(ply)
        surface.PlaySound("buttons/button14.wav")
        self:SetDatapadState("hub")
    end

    function SWEP:BuildHubScreen()
        local ply = LocalPlayer()
        self.VirtualButtons = {}
        
        -- Verificación estricta del trabajo para que los SuperAdmins no vean los menús de ISB
        -- cuando están jugando en SU: Especialista
        local jobName = string.upper(team.GetName(ply:Team()) or "")
        local isSU = false
        if Datapad.Config.SUSpecJobs then
            for _, jobVar in ipairs(Datapad.Config.SUSpecJobs) do
                if _G[jobVar] and ply:Team() == _G[jobVar] then isSU = true end
                if string.upper(jobVar) == jobName then isSU = true end
                if jobVar == "TEAM_SU_ESPECIALISTA" and jobName == "SU: ESPECIALISTA" then isSU = true end
            end
        end
        
        local yPos = -10
        
        if isSU then
            -- Buscar si el jugador ya tiene una sonda vinculada
            local activeProbe = self.KnownActiveProbe
            if not IsValid(activeProbe) then
                for _, ent in ipairs(ents.FindByClass("ent_probe_droid")) do
                    if IsValid(ent) and ent:GetProbeOwner() == ply then
                        activeProbe = ent
                        self.KnownActiveProbe = ent
                        break
                    end
                end
            end
            
            if IsValid(activeProbe) then
                table.insert(self.VirtualButtons, {
                    id = "hub_drone_control", text = "ACTIVAR CÁMARA", x = -120, y = yPos, w = 240, h = 45, color = Color(0, 200, 255), action = function(p)
                        -- Mantener ThirdPersonRP activo para que otros vean el datapad arriba
                        self.ThirdPersonRP = true
                        
                        if IsValid(self.CursorPanel) then self.CursorPanel:Remove() end
                        
                        -- Efecto de transición cinematográfica (cerrar pantalla en negro)
                        LocalPlayer():ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 1, 0.2)
                        surface.PlaySound("weapons/physcannon/physcannon_charge.wav")
                        
                        -- Timer para cambiar de vista una vez que la pantalla esté negra
                        timer.Simple(1, function()
                            if not IsValid(self) then return end
                            
                            self.DatapadActive = false
                            self.WasDatapadActive = false
                            self.DrawCrosshair = true
                            
                            -- Aclarar la pantalla
                            LocalPlayer():ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 1, 0)
                            
                            if ProbeDroid_StartControl then
                                ProbeDroid_StartControl(activeProbe)
                            else
                                net.Start("Probe_StartControl")
                                net.WriteEntity(activeProbe)
                                net.SendToServer()
                            end
                        end)
                    end
                })
                yPos = yPos + 60
                
                table.insert(self.VirtualButtons, {
                    id = "hub_drone_unlink", text = "DESVINCULAR SONDA", x = -120, y = yPos, w = 240, h = 45, color = Color(255, 50, 50), action = function(p)
                        net.Start("Probe_Unlink")
                        net.SendToServer()
                        surface.PlaySound("buttons/button11.wav")
                        self.KnownActiveProbe = nil
                        -- Recargar la pantalla para mostrar el botón de vincular
                        timer.Simple(0.2, function()
                            if IsValid(self) and self.DatapadState == "hub" then
                                self:BuildHubScreen()
                            end
                        end)
                    end
                })
                yPos = yPos + 60
            else
                table.insert(self.VirtualButtons, {
                    id = "hub_drone_link", text = "VINCULAR SONDA", x = -120, y = yPos, w = 240, h = 45, color = Color(0, 255, 100), action = function(p)
                        self:SetDatapadState("probe_link_mode")
                    end
                })
                yPos = yPos + 60
            end
        else
            local actionTactical = function(p)
                if Datapad:HasAccess(p, Datapad.Config.ISBJobs) then
                    self:SetDatapadState("isb")
                elseif Datapad:HasAccess(p, Datapad.Config.ShockJobs) or Datapad:HasAccess(p, Datapad.Config.RiotJobs) then
                    self:SetDatapadState("65th")
                end
            end
            
            table.insert(self.VirtualButtons, { id = "hub_docs", text = "ARCHIVOS PERSONALES", x = -120, y = yPos, w = 240, h = 45, color = Color(0, 150, 255), action = function(p)
                net.Start("IVO_Docs_RequestSync")
                net.SendToServer()
                self:SetDatapadState("docs_list")
            end })
            yPos = yPos + 60
            
            table.insert(self.VirtualButtons, { id = "hub_tactical", text = "MÓDULO TÁCTICO", x = -120, y = yPos, w = 240, h = 45, color = Color(255, 50, 50), action = actionTactical })
            yPos = yPos + 60
        end
        
        table.insert(self.VirtualButtons, { id = "logout", text = "CERRAR SESIÓN", x = -120, y = yPos, w = 240, h = 45, color = Color(100, 100, 100), action = function(p) self:SetDatapadState("login") end })
    end

    function SWEP:BuildProbeLinkModeScreen()
        self.VirtualButtons = {
            { id = "back", text = "CANCELAR ENLACE", x = -120, y = 140, w = 240, h = 45, color = Color(100, 100, 100), action = function(p)
                self:SetDatapadState("hub")
                self.ScanTarget = nil
            end },
        }
    end

    function SWEP:BuildDocsListScreen()
        self.DocsPage = self.DocsPage or 1
        
        self.VirtualButtons = {
            { id = "docs_back", text = "VOLVER AL HUB", x = -120, y = 140, w = 240, h = 45, color = Color(100, 100, 100), action = function(p)
                self:SetDatapadState("hub")
            end }
        }
        
        -- Los botones de los documentos se agregarán dinámicamente en el render,
        -- pero como la librería UI usa hitboxes estáticos generados aquí,
        -- los crearemos asumiendo la lista sincronizada actual.
        if IVO_PlayerDocs then
            local startY = -120
            local limit = 5
            local offset = (self.DocsPage - 1) * limit
            
            for i = 1, limit do
                local doc = IVO_PlayerDocs[offset + i]
                if doc then
                    table.insert(self.VirtualButtons, {
                        id = "doc_" .. doc.id,
                        text = "LEER",
                        x = 70, y = startY + 5, w = 50, h = 30,
                        color = Color(0, 150, 255),
                        action = function(p)
                            self.SelectedDoc = doc
                            self:SetDatapadState("doc_view")
                        end
                    })
                end
                startY = startY + 45
            end
            
            -- Botones de paginación
            if #IVO_PlayerDocs > limit then
                if self.DocsPage > 1 then
                    table.insert(self.VirtualButtons, {
                        id = "docs_prev", text = "<", x = -30, y = 105, w = 30, h = 30, color = Color(150, 150, 150),
                        action = function(p) self.DocsPage = self.DocsPage - 1; self:BuildDocsListScreen() end
                    })
                end
                if offset + limit < #IVO_PlayerDocs then
                    table.insert(self.VirtualButtons, {
                        id = "docs_next", text = ">", x = 10, y = 105, w = 30, h = 30, color = Color(150, 150, 150),
                        action = function(p) self.DocsPage = self.DocsPage + 1; self:BuildDocsListScreen() end
                    })
                end
            end
        end
    end

    function SWEP:BuildDocViewScreen()
        self.VirtualButtons = {
            { id = "doc_transfer", text = "TRANSFERIR OBJETIVO", x = -120, y = 85, w = 240, h = 45, color = Color(0, 255, 0), action = function(p)
                local tr = util.TraceLine({
                    start = p:GetShootPos(),
                    endpos = p:GetShootPos() + p:GetAimVector() * 150,
                    filter = p
                })
                local target = tr.Entity
                if IsValid(target) and target:IsPlayer() then
                    net.Start("IVO_Docs_Transfer")
                    net.WriteUInt(self.SelectedDoc.id, 32)
                    net.WriteEntity(target)
                    net.SendToServer()
                    self:SetDatapadState("docs_list") -- Volver porque ya no es dueño
                else
                    p:ChatPrint("No hay ningún jugador en frente.")
                end
            end },
            { id = "doc_delete", text = "ELIMINAR ARCHIVO", x = -120, y = 140, w = 115, h = 45, color = Color(255, 50, 50), action = function(p)
                net.Start("IVO_Docs_Delete")
                net.WriteUInt(self.SelectedDoc.id, 32)
                net.SendToServer()
                self:SetDatapadState("docs_list")
            end },
            { id = "doc_back", text = "VOLVER", x = 5, y = 140, w = 115, h = 45, color = Color(100, 100, 100), action = function(p)
                self:SetDatapadState("docs_list")
            end }
        }
    end

    function SWEP:BuildISBScreen()
        self.VirtualButtons = {
            { id = "isb_chats", text = "INTERCEPTAR COMUNICACIONES", x = -120, y = -100, w = 240, h = 45, color = Color(50, 150, 255) },
            { id = "isb_reports", text = "BASE DE EXPEDIENTES", x = -120, y = -45, w = 240, h = 45, color = Color(50, 150, 255) },
            { id = "isb_warrant", text = "EMITIR ORDEN DE BÚSQUEDA", x = -120, y = 10, w = 240, h = 45, color = Color(200, 50, 50) },
            
            -- Botones de Navegación Abajo
            { id = "isb_back", text = "VOLVER ATRÁS", x = -120, y = 140, w = 240, h = 45, color = Color(150, 150, 150), action = function(p)
                self:SetDatapadState("hub")
            end }
        }
    end

    function SWEP:Build65thScreen()
        self.VirtualButtons = {
            { id = "rt_scan", text = "SISTEMA DE INSPECCIÓN", x = -120, y = -100, w = 240, h = 45, color = Color(255, 150, 50), action = function(p)
                self:SetDatapadState("scan_mode")
            end },
            { id = "rt_add", text = "EMITIR ORDEN DE CAPTURA", x = -120, y = -45, w = 240, h = 45, color = Color(255, 50, 50), action = function(p)
                if IsValid(self.ScanResult_Ent) then
                    local isCivilian = string.StartWith(tostring(self.ScanResult_ID or ""), "ID-")
                    net.Start("Datapad_Warrant_Add")
                        net.WriteEntity(self.ScanResult_Ent)
                        net.WriteBool(isCivilian)
                    net.SendToServer()
                    surface.PlaySound("buttons/button14.wav")
                end
            end },
            { id = "rt_clear", text = "REVOCAR CARGOS", x = -120, y = 10, w = 240, h = 45, color = Color(50, 200, 100), action = function(p)
                if IsValid(self.ScanResult_Ent) then
                    local isCivilian = string.StartWith(tostring(self.ScanResult_ID or ""), "ID-")
                    net.Start("Datapad_Warrant_Clear")
                        net.WriteEntity(self.ScanResult_Ent)
                        net.WriteBool(isCivilian)
                    net.SendToServer()
                    surface.PlaySound("buttons/button14.wav")
                end
            end },
            { id = "rt_history", text = "REGISTROS RECIENTES", x = -120, y = 65, w = 240, h = 45, color = Color(100, 150, 255), action = function(p)
                self:SetDatapadState("scan_history")
            end },
            
            -- Botones de Navegación Abajo
            { id = "rt_back", text = "VOLVER ATRÁS", x = -120, y = 140, w = 240, h = 45, color = Color(150, 150, 150), action = function(p)
                self:SetDatapadState("hub")
            end }
        }
    end

    function SWEP:BuildScanModeScreen()
        self.VirtualButtons = {
            { id = "back", text = "CANCELAR ESCANEO", x = -120, y = 140, w = 240, h = 45, color = Color(100, 100, 100), action = function(p)
                self:SetDatapadState("65th")
                if IsValid(self.ScanTarget) then
                    net.Start("Datapad_Scan_Stop")
                    net.SendToServer()
                    self.ScanTarget = nil
                end
            end },
        }
    end

    function SWEP:BuildScanResultScreen()
        self.VirtualButtons = {
            { id = "back", text = "VOLVER AL MENÚ", x = -120, y = 140, w = 240, h = 45, color = Color(100, 100, 100), action = function(p)
                self:SetDatapadState("65th")
            end },
        }
    end

    function SWEP:BuildScanHistoryScreen()
        self.VirtualButtons = {
            { id = "back", text = "VOLVER AL MENÚ", x = -120, y = 160, w = 240, h = 45, color = Color(100, 100, 100), action = function(p)
                self:SetDatapadState("65th")
            end },
        }
    end

    function SWEP:GetCursorPos3D()
        if not self.LastScreenPos or not self.LastScreenAng then return nil, nil end
        
        local scrW, scrH = ScrW(), ScrH()
        local mx, my = gui.MousePos()
        local fov = self.ViewModelFOV or 62
        local eyeAngles = EyeAngles()
        
        -- Corrección de Perspectiva (Desfase de FOV)
        -- El Viewmodel se dibuja a 70 FOV, pero el mundo a 90. 
        -- Esto evita que el cursor se separe al alejarse del centro.
        local aspect = scrW / scrH
        local fov_y = 2 * math.atan( math.tan( math.rad( fov ) / 2 ) * ( 3 / 4 ) )
        local fov_x = 2 * math.atan( math.tan( fov_y / 2 ) * aspect )
        
        local right_scale = math.tan( fov_x / 2 )
        local up_scale = math.tan( fov_y / 2 )
        
        local x_diff = (mx - scrW / 2) / (scrW / 2)
        local y_diff = (scrH / 2 - my) / (scrH / 2)
        
        local aimVector = eyeAngles:Forward() + eyeAngles:Right() * (x_diff * right_scale) + eyeAngles:Up() * (y_diff * up_scale)
        aimVector:Normalize()
        
        local eyePos = EyePos()
        local hitPos = util.IntersectRayWithPlane(eyePos, aimVector, self.LastScreenPos, self.LastScreenAng:Up())
        if not hitPos then return nil, nil end
        
        local diff = hitPos - self.LastScreenPos
        local scale = 0.012
        
        -- Ejes corregidos:
        -- Como el modelo 3D tiene múltiples rotaciones (Pitch 90, Yaw 90, Roll 90),
        -- los vectores locales del plano terminan invertidos respecto a la vista.
        -- Según las pruebas: Forward apunta a la Derecha de la pantalla, Right apunta Abajo de la pantalla.
        local cx = diff:Dot(self.LastScreenAng:Forward()) / scale
        local cy = diff:Dot(self.LastScreenAng:Right()) / scale
        
        return cx, cy
    end

    function SWEP:DrawWorldModel()
        local owner = self:GetOwner()
        if IsValid(owner) then
            local bone = owner:LookupBone("ValveBiped.Bip01_R_Hand")
            if bone then
                local matrix = owner:GetBoneMatrix(bone)
                if matrix then
                    local pos = matrix:GetTranslation()
                    local ang = matrix:GetAngles()

                    -- ======== AJUSTE DE TERCERA PERSONA ========
                    -- Usa estos números para acomodar el datapad en la mano de tu personaje
                    pos = pos + ang:Right() * 3
                    pos = pos + ang:Forward() * 5
                    pos = pos + ang:Up() * -3
                    
                    ang:RotateAroundAxis(ang:Forward(), 0)
                    ang:RotateAroundAxis(ang:Right(), 120)
                    ang:RotateAroundAxis(ang:Up(), -0)

                    self:SetRenderOrigin(pos)
                    self:SetRenderAngles(ang)
                    self:DrawModel()
                    return
                end
            end
        end
        self:DrawModel()
    end

    function SWEP:PreDrawViewModel(vm, wep, ply)
        render.SetBlend(0)
        render.MaterialOverride(invisMat)
        
        local hands = ply:GetHands()
        if IsValid(hands) then
            local targetModel = "models/aussiwozzi/cgi/base/trooper_arms.mdl"
            if string.lower(hands:GetModel()) ~= targetModel then
                wep.OldHandsModel = hands:GetModel()
                hands:SetModel(targetModel)
            end
        end
    end

    function SWEP:GetScreenMargins(y)
        -- Ecuación lineal para la forma de la pantalla (más ancha arriba, más angosta abajo)
        -- En Y = -225 (arriba), halfW = 145
        -- En Y = 225 (abajo), halfW = 100
        -- Pendiente = -0.1
        local halfW = -0.1 * y + 122.5
        return -halfW, halfW
    end

    function SWEP:DrawScannerGrid(color, alpha)
        surface.SetDrawColor(color.r, color.g, color.b, alpha or 8)
        local timeOffset = CurTime() * 30
        
        local h = 450
        local oy = -h/2
        
        for i = oy, oy + h, 15 do
            local lineY = i + (timeOffset % 15)
            if lineY > oy + h then continue end
            
            local leftX, rightX = self:GetScreenMargins(lineY)
            surface.DrawRect(leftX, lineY, rightX - leftX, 1)
        end
    end

    function SWEP:PostDrawViewModel(vm, wep, ply)
        render.MaterialOverride(nil)
        render.SetBlend(1)
        
        if IsValid(vm) then
            vm:SetNoDraw(false)
        end
        
        -- Crear y renderizar el Datapad acoplado
        if not IsValid(self.DatapadModel) then
            self.DatapadModel = ClientsideModel("models/wield_item/wield_civ_item_datapad.mdl")
            self.DatapadModel:SetNoDraw(true)
        end
        
        -- Usamos la matriz del Viewmodel para obtener la posición exacta del hueso de la mano derecha nativa
        local bone = vm:LookupBone("ValveBiped.Bip01_R_Hand")
        if not bone then return end
        
        local m = vm:GetBoneMatrix(bone)
        if not m then return end
        
        local pos, ang = m:GetTranslation(), m:GetAngles()
        
        -- ======== AJUSTE DE LA MANO ========
        pos = pos + ang:Right() * 4
        pos = pos + ang:Forward() * 5.3
        pos = pos + ang:Up() * -3.4
        
        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), 40)
        ang:RotateAroundAxis(ang:Up(), 90)
        
        self.DatapadModel:SetRenderOrigin(pos)
        self.DatapadModel:SetRenderAngles(ang)
        self.DatapadModel:DrawModel()
        
        -- ======== PANTALLA 3D DEL DATAPAD ========
        -- Al estar centrado, screenPos ahora es el EXACTO CENTRO de la pantalla oscura
        local screenPos = pos + ang:Up() * 1 + ang:Forward() * -0.3 + ang:Right() * 0.03
        local screenAng = Angle(ang.p, ang.y, ang.r)
        
        screenAng:RotateAroundAxis(screenAng:Right(), 0)
        screenAng:RotateAroundAxis(screenAng:Up(), 90)
        screenAng:RotateAroundAxis(screenAng:Forward(), 0)
        
        -- LUZ DINÁMICA (Ilumina la cara del jugador y el entorno)
        if self.BootTime and CurTime() >= self.BootTime then
            local dlight = DynamicLight(self:EntIndex())
            if dlight then
                -- Posicionar la luz en el centro de la pantalla, un poco desplazada hacia afuera
                dlight.pos = screenPos + screenAng:Up() * 5
                dlight.brightness = 1.5
                dlight.Decay = 1000
                dlight.Size = 160
                dlight.DieTime = CurTime() + 0.1
                
                if not self.DatapadActive then
                    -- Pantalla Reposo (Verde Suave)
                    dlight.r = 20; dlight.g = 150; dlight.b = 20; dlight.brightness = 0.3
                elseif self.DatapadState == "login" then
                    -- Login (Azul Brillante)
                    dlight.r = 0; dlight.g = 150; dlight.b = 255; dlight.brightness = 0.8
                elseif self.DatapadState == "hub" or self.DatapadState == "docs_list" or self.DatapadState == "doc_view" then
                    -- Hub y Archivos (Azul Neón Claro)
                    dlight.r = 0; dlight.g = 200; dlight.b = 255; dlight.brightness = 0.8
                elseif self.DatapadState == "isb" then
                    -- ISB (Rojo Alarma)
                    dlight.r = 255; dlight.g = 20; dlight.b = 20; dlight.brightness = 1
                elseif self.DatapadState == "65th" then
                    -- 65th (Naranja Táctico)
                    dlight.r = 255; dlight.g = 100; dlight.b = 20; dlight.brightness = 0.8
                elseif self.DatapadState == "scan_mode" then
                    -- Escáner Activo (Naranja/Amarillo Parpadeante)
                    dlight.r = 255; dlight.g = 150; dlight.b = 50; dlight.brightness = 0.8 + math.abs(math.sin(CurTime() * 10)) * 0.4
                elseif self.DatapadState == "probe_link_mode" then
                    -- Escáner de Sonda (Verde Brillante Parpadeante)
                    dlight.r = 0; dlight.g = 255; dlight.b = 100; dlight.brightness = 0.8 + math.abs(math.sin(CurTime() * 10)) * 0.4
                elseif self.DatapadState == "scan_result" or self.DatapadState == "scan_history" then
                    -- Resultado y Registros (Celeste Neón)
                    dlight.r = 50; dlight.g = 200; dlight.b = 255; dlight.brightness = 1.2
                end
            end
        end

        render.SuppressEngineLighting(true)
        cam.Start3D2D(screenPos, screenAng, 0.012)
            self.LastScreenPos = screenPos
            self.LastScreenAng = screenAng
            
            local w = 280
            local h = 470 -- Alargado hacia abajo (antes 450)
            local ox = -w/2
            local oy = -235 -- Mantener la parte superior en la misma posición original
            
            local topInset = -15
            local bottomInset = 32
            
            local poly = {
                { x = ox + topInset, y = oy },
                { x = ox + w - topInset, y = oy },
                { x = ox + w - bottomInset, y = oy + h },
                { x = ox + bottomInset, y = oy + h }
            }
            
            draw.NoTexture()
            
            if self.DatapadActive then
                -- Fondo General UI Activo (Completamente Opaco)
                surface.SetDrawColor(2, 5, 10, 255)
                surface.DrawPoly(poly)
                
                local cx, cy = self:GetCursorPos3D()
                local timeInState = CurTime() - (self.StateStartTime or CurTime())
                
                -- ====== MAQUINA DE ESTADOS ======
                if self.DatapadState == "login" then
                    local ply = LocalPlayer()
                    
                    local hasAccess = false
                    local prefix = "UNK"
                    if Datapad and Datapad.HasAccess then
                        local jobName = string.upper(team.GetName(ply:Team()) or "")
                        local isSU = false
                        if Datapad.Config.SUSpecJobs then
                            for _, jobVar in ipairs(Datapad.Config.SUSpecJobs) do
                                if _G[jobVar] and ply:Team() == _G[jobVar] then isSU = true end
                                if string.upper(jobVar) == jobName then isSU = true end
                                if jobVar == "TEAM_SU_ESPECIALISTA" and jobName == "SU: ESPECIALISTA" then isSU = true end
                            end
                        end
                        
                        if isSU then
                            prefix = "SU"
                            hasAccess = true
                        elseif Datapad:HasAccess(ply, Datapad.Config.ISBJobs) then 
                            prefix = "ISB"
                            hasAccess = true
                        elseif Datapad:HasAccess(ply, Datapad.Config.ShockJobs) or Datapad:HasAccess(ply, Datapad.Config.RiotJobs) then 
                            prefix = "SH"
                            hasAccess = true
                        end
                    end
                    local acc = tostring(ply:AccountID())
                    local rpID = prefix .. string.sub(acc, math.max(1, #acc - 4))
                    
                    local colorTheme = hasAccess and Color(0, 150, 255) or Color(255, 50, 50)
                    if timeInState < 1.8 then colorTheme = Color(0, 150, 255) end
                    
                    self:DrawScannerGrid(colorTheme, 8)

                    local pulse = math.abs(math.sin(CurTime() * 4)) * 100 + 155
                    
                    -- Efecto Typewriter (Escritura)
                    local title = "SISTEMA CENTRAL"
                    local typedTitle = string.sub(title, 1, math.floor(timeInState * 25))
                    draw.SimpleText(typedTitle, "Datapad_Title", 0, -180, colorTheme, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                    local tl, tr = self:GetScreenMargins(-165)
                    surface.SetDrawColor(colorTheme.r, colorTheme.g, colorTheme.b, 100)
                    surface.DrawLine(tl + 10, -165, tr - 10, -165)
                    
                    local function DrawTrapezoidLine(yPos, color)
                        local lx, rx = self:GetScreenMargins(yPos)
                        local fm = 15
                        surface.SetDrawColor(color)
                        surface.DrawLine(lx + fm, yPos, rx - fm, yPos)
                        return lx + fm + 5, rx - fm - 5
                    end
                    
                    if timeInState > 0.6 and timeInState < 1.4 then
                        -- LOGO IMPERIAL GIRATORIO
                        local mat = Material("virtus/imperio", "smooth")
                        surface.SetMaterial(mat)
                        surface.SetDrawColor(colorTheme.r, colorTheme.g, colorTheme.b, pulse)
                        
                        local isz = 120
                        local cosVal = math.cos(CurTime() * 3)
                        local scale = math.abs(cosVal)
                        local currentW = isz * scale
                        local rx = -currentW / 2
                        local ry = -120
                        
                        if cosVal > 0 then
                            surface.DrawTexturedRectUV(rx, ry, currentW, isz, 0, 0, 1, 1)
                        else
                            surface.DrawTexturedRectUV(rx, ry, currentW, isz, 1, 0, 0, 1)
                        end
                        
                        draw.SimpleText("IDENTIFICANDO USUARIO...", "Datapad_Text", 0, 20, Color(100, 150, 200, pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        
                        -- Escáner de carga
                        local wL, wR = self:GetScreenMargins(40)
                        surface.SetDrawColor(0, 150, 255, 50)
                        surface.DrawRect(wL + 40, 40, (wR - wL) - 80, 10)
                        
                        local prog = (timeInState - 0.6) / 0.8
                        surface.SetDrawColor(0, 150, 255, 200)
                        surface.DrawRect(wL + 40, 40, ((wR - wL) - 80) * prog, 10)
                    end
                    
                    if timeInState > 1.4 then
                        -- Diseño de Perfil
                        local startY = -120
                        local lineC = Color(colorTheme.r, colorTheme.g, colorTheme.b, 50)
                        
                        local lX, rX = DrawTrapezoidLine(startY, lineC)
                        draw.SimpleText("AGENTE:", "Datapad_Text", lX, startY + 10, Color(150, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        
                        -- Obtener solo la última palabra del nombre
                        local nameParts = string.Explode(" ", ply:Nick())
                        local lastName = nameParts[#nameParts] or "DESCONOCIDO"
                        local nameStr = string.upper(string.sub(lastName, 1, 15))
                        
                        draw.SimpleText(nameStr, "Datapad_Title", rX, startY + 10, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        
                        lX, rX = DrawTrapezoidLine(startY + 30, lineC)
                        draw.SimpleText("ID OPERATIVO:", "Datapad_Text", lX, startY + 40, Color(150, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        draw.SimpleText(rpID, "Datapad_Title", rX, startY + 40, colorTheme, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        
                        lX, rX = DrawTrapezoidLine(startY + 60, lineC)
                        
                        if timeInState > 1.8 then
                            local statY = startY + 100
                            if hasAccess then
                                draw.SimpleText("AUTORIZACIÓN VERIFICADA", "Datapad_Title", 0, statY, Color(50, 255, 50, pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                                draw.SimpleText("ACCESO CONCEDIDO", "Datapad_Text", 0, statY + 20, Color(150, 255, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            else
                                draw.SimpleText("ACCESO DENEGADO", "Datapad_Title", 0, statY, Color(255, 50, 50, pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                                draw.SimpleText("CREDENCIALES INSUFICIENTES", "Datapad_Text", 0, statY + 20, Color(255, 50, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            end
                        else
                            draw.SimpleText("COMPROBANDO PERMISOS...", "Datapad_Text", 0, startY + 100, Color(150, 150, 150, pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        end
                    end
                    
                elseif self.DatapadState == "isb" then
                    self:DrawScannerGrid(Color(200, 50, 50), 8)
                    draw.SimpleText("BASE DE DATOS ISB", "Datapad_Title", 0, -180, Color(200, 50, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    -- TODO: Interfaz ISB Real
                    
                elseif self.DatapadState == "65th" then
                    self:DrawScannerGrid(Color(255, 100, 50), 8)
                    draw.SimpleText("RED TÁCTICA 65TH", "Datapad_Title", 0, -180, Color(255, 100, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    -- TODO: Interfaz 65th Real
                
                elseif self.DatapadState == "scan_mode" then
                    self:DrawScannerGrid(Color(255, 150, 50), 10)
                    draw.SimpleText("SISTEMA DE ESCANEO", "Datapad_Title", 0, -180, Color(255, 150, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                    local tL, tR = self:GetScreenMargins(-165)
                    surface.SetDrawColor(255, 150, 50, 100)
                    surface.DrawLine(tL + 10, -165, tR - 10, -165)
                    
                    if IsValid(self.ScanTarget) and self.ScanProgressStartTime then
                        local progress = math.Clamp((CurTime() - self.ScanProgressStartTime) / 3, 0, 1)
                        
                        -- Efecto de brackets esquineros fijando el objetivo
                        local pulse = math.abs(math.sin(CurTime() * 12)) * 100 + 155
                        surface.SetDrawColor(255, 150, 50, pulse)
                        
                        -- Bracket margins
                        local bLTop, bRTop = self:GetScreenMargins(-130)
                        local bLBot, bRBot = self:GetScreenMargins(10)
                        local bm = 20
                        local bx, by, bw, bh = bLTop + bm, -130, (bRTop - bLTop) - bm*2, 140
                        local len = 20
                        -- Top Left
                        surface.DrawLine(bx, by, bx + len, by)
                        surface.DrawLine(bx, by, bx, by + len)
                        -- Top Right
                        surface.DrawLine(bx + bw, by, bx + bw - len, by)
                        surface.DrawLine(bx + bw, by, bx + bw, by + len)
                        
                        -- Abajo
                        local bxBot = bLBot + bm
                        local bwBot = (bRBot - bLBot) - bm*2
                        
                        -- Bottom Left
                        surface.DrawLine(bxBot, by + bh, bxBot + len, by + bh)
                        surface.DrawLine(bxBot, by + bh, bxBot, by + bh - len)
                        -- Bottom Right
                        surface.DrawLine(bxBot + bwBot, by + bh, bxBot + bwBot - len, by + bh)
                        surface.DrawLine(bxBot + bwBot, by + bh, bxBot + bwBot, by + bh - len)
                        
                        draw.SimpleText("OBJETIVO FIJADO:", "Datapad_Text", 0, -100, Color(255, 150, 50, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        draw.SimpleText("SUJETO DESCONOCIDO", "Datapad_Title", 0, -75, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        
                        local dots = string.rep(".", math.floor(CurTime() * 4) % 4)
                        draw.SimpleText("EXTRAYENDO DATOS BIOMÉTRICOS" .. dots, "Datapad_Text", 0, -35, Color(255, 200, 50, pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        
                        -- Barra de progreso segmentada (Sci-Fi)
                        local pL, pR = self:GetScreenMargins(-10)
                        local barW, barH = (pR - pL) - 40, 16
                        local startX = pL + 20
                        local segments = 10
                        local segW = (barW / segments) - 2
                        
                        surface.SetDrawColor(255, 150, 50, 30)
                        for i = 0, segments - 1 do
                            surface.DrawRect(startX + (i * (segW + 2)), -10, segW, barH)
                        end
                        
                        surface.SetDrawColor(255, 200, 50, 255)
                        local filledSegs = math.floor(progress * segments)
                        for i = 0, filledSegs - 1 do
                            surface.DrawRect(startX + (i * (segW + 2)), -10, segW, barH)
                        end
                        
                        draw.SimpleText(math.floor(progress * 100) .. "%", "Datapad_Text", 0, 18, Color(255, 150, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    else
                        draw.SimpleText("APUNTE A UN CIUDADANO", "Datapad_Title", 0, -50, Color(150, 150, 150, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        draw.SimpleText("MANTENGA LÍNEA DE VISIÓN", "Datapad_Text", 0, -30, Color(150, 150, 150, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        
                        -- Retícula de búsqueda giratoria (Logo Imperial)
                        local mat = Material("virtus/imperio", "smooth")
                        surface.SetMaterial(mat)
                        surface.SetDrawColor(255, 100, 50, 150)
                        
                        local isz = 80
                        local cosVal = math.cos(CurTime() * 3)
                        local scale = math.abs(cosVal)
                        local currentW = isz * scale
                        local rx = -currentW / 2
                        local ry = -isz / 2
                        
                        if cosVal > 0 then
                            surface.DrawTexturedRectUV(rx, ry, currentW, isz, 0, 0, 1, 1)
                        else
                            surface.DrawTexturedRectUV(rx, ry, currentW, isz, 1, 0, 0, 1)
                        end
                        
                        surface.DrawOutlinedRect(-40, -40, 80, 80, 1)
                    end
                    
                elseif self.DatapadState == "probe_link_mode" then
                    self:DrawScannerGrid(Color(0, 255, 100), 8)
                    draw.SimpleText("SISTEMA DE ENLACE DE SONDA", "Datapad_Title", 0, -180, Color(0, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                    if IsValid(self.ScanTarget) and self.ScanProgressStartTime then
                        local progress = math.Clamp((CurTime() - self.ScanProgressStartTime) / 2.0, 0, 1)
                        local pulse = math.abs(math.sin(CurTime() * 10)) * 100 + 155
                        
                        draw.SimpleText("SONDA DETECTADA:", "Datapad_Text", 0, -100, Color(0, 255, 100, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        draw.SimpleText("VÍPER PROBE DROID", "Datapad_Title", 0, -75, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        
                        local dots = string.rep(".", math.floor(CurTime() * 4) % 4)
                        draw.SimpleText("ESTABLECIENDO CONEXIÓN" .. dots, "Datapad_Text", 0, -35, Color(0, 255, 100, pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        
                        local pL, pR = self:GetScreenMargins(-10)
                        local barW, barH = (pR - pL) - 40, 16
                        local startX = pL + 20
                        local segments = 10
                        local segW = (barW / segments) - 2
                        
                        surface.SetDrawColor(0, 255, 100, 30)
                        for i = 0, segments - 1 do
                            surface.DrawRect(startX + (i * (segW + 2)), -10, segW, barH)
                        end
                        
                        surface.SetDrawColor(0, 255, 100, 255)
                        local filledSegs = math.floor(progress * segments)
                        for i = 0, filledSegs - 1 do
                            surface.DrawRect(startX + (i * (segW + 2)), -10, segW, barH)
                        end
                        
                        draw.SimpleText(math.floor(progress * 100) .. "%", "Datapad_Text", 0, 18, Color(0, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    else
                        draw.SimpleText("APUNTE A UNA SONDA", "Datapad_Title", 0, -50, Color(150, 150, 150, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        draw.SimpleText("MANTENGA LÍNEA DE VISIÓN", "Datapad_Text", 0, -30, Color(150, 150, 150, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        
                        local mat = Material("virtus/imperio", "smooth")
                        surface.SetMaterial(mat)
                        surface.SetDrawColor(0, 255, 100, 150)
                        
                        local isz = 80
                        local cosVal = math.cos(CurTime() * 3)
                        local scale = math.abs(cosVal)
                        local currentW = isz * scale
                        local rx = -currentW / 2
                        local ry = -isz / 2
                        
                        if cosVal > 0 then
                            surface.DrawTexturedRectUV(rx, ry, currentW, isz, 0, 0, 1, 1)
                        else
                            surface.DrawTexturedRectUV(rx, ry, currentW, isz, 1, 0, 0, 1)
                        end
                        surface.DrawOutlinedRect(-40, -40, 80, 80, 1)
                    end
                    
                elseif self.DatapadState == "hub" then
                    self:DrawScannerGrid(Color(0, 150, 255), 8)
                    
                    local tl, tr = self:GetScreenMargins(-165)
                    surface.SetDrawColor(0, 150, 255, 100)
                    surface.DrawLine(tl + 10, -165, tr - 10, -165)
                    draw.SimpleText("HUB CENTRAL", "Datapad_Title", 0, -180, Color(0, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                    local lTop, rTop = self:GetScreenMargins(-100)
                    draw.SimpleText("SISTEMA DE ARCHIVOS Y TÁCTICA", "Datapad_Text", 0, -130, Color(150, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                elseif self.DatapadState == "docs_list" then
                    self:DrawScannerGrid(Color(0, 150, 255), 8)
                    local tl, tr = self:GetScreenMargins(-165)
                    surface.SetDrawColor(0, 150, 255, 100)
                    surface.DrawLine(tl + 10, -165, tr - 10, -165)
                    draw.SimpleText("MIS ARCHIVOS", "Datapad_Title", 0, -180, Color(0, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                    if not IVO_PlayerDocs then
                        draw.SimpleText("SINCRONIZANDO...", "Datapad_Title", 0, 0, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    elseif #IVO_PlayerDocs == 0 then
                        draw.SimpleText("NO HAY DOCUMENTOS", "Datapad_Title", 0, 0, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    else
                        local startY = -120
                        local limit = 5
                        local offset = (self.DocsPage - 1) * limit
                        
                        for i = 1, limit do
                            local doc = IVO_PlayerDocs[offset + i]
                            if not doc then break end
                            
                            local lBot, rBot = self:GetScreenMargins(startY + 40)
                            local lTop, rTop = self:GetScreenMargins(startY)
                            local padding = 10
                            
                            local itemPoly = {
                                { x = lTop + padding, y = startY },
                                { x = rTop - padding, y = startY },
                                { x = rBot - padding, y = startY + 40 },
                                { x = lBot + padding, y = startY + 40 }
                            }
                            
                            surface.SetDrawColor(0, 100, 200, 30)
                            draw.NoTexture()
                            surface.DrawPoly(itemPoly)
                            
                            -- Nombre y Fecha
                            local titleStr = string.sub(doc.title, 1, 20)
                            local dateStr = os.date("%d/%m/%Y", doc.timestamp)
                            draw.SimpleText(titleStr, "Datapad_Title", lTop + padding + 10, startY + 5, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                            draw.SimpleText(dateStr, "Datapad_Text", rTop - padding - 60, startY + 10, Color(150, 150, 150), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                            
                            startY = startY + 45
                        end
                    end
                    
                elseif self.DatapadState == "doc_view" then
                    self:DrawScannerGrid(Color(0, 150, 255), 5)
                    local doc = self.SelectedDoc
                    if doc then
                        local tl, tr = self:GetScreenMargins(-165)
                        surface.SetDrawColor(0, 150, 255, 100)
                        surface.DrawLine(tl + 10, -165, tr - 10, -165)
                        
                        local titleStr = string.sub(doc.title, 1, 15)
                        draw.SimpleText("DOC: " .. titleStr, "Datapad_Title", 0, -180, Color(0, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        
                        -- Envolver el texto para el ancho del datapad (aprox 200px utilizables)
                        surface.SetFont("Datapad_Text")
                        local words = string.Explode(" ", doc.content)
                        local lines = {}
                        local currentLine = ""
                        for _, w in ipairs(words) do
                            local test = currentLine .. " " .. w
                            if surface.GetTextSize(test) > 200 then
                                table.insert(lines, currentLine)
                                currentLine = w
                            else
                                currentLine = test
                            end
                        end
                        if currentLine ~= "" then table.insert(lines, currentLine) end
                        
                        local startY = -140
                        for i=1, math.min(10, #lines) do
                            local lY, rY = self:GetScreenMargins(startY)
                            draw.SimpleText(lines[i], "Datapad_Text", lY + 20, startY, Color(200, 220, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                            startY = startY + 20
                        end
                        if #lines > 10 then
                            draw.SimpleText("... [CONT. EN TERMINAL]", "Datapad_Text", 0, startY, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                        end
                    end
                    
                elseif self.DatapadState == "scan_result" then
                    local isWarrant = self.ScanResult_Warrant
                    local pulse = math.abs(math.sin(CurTime() * 10)) * 255
                    
                    if isWarrant then
                        self:DrawScannerGrid(Color(255, 50, 50), 15 + pulse * 0.2)
                        draw.SimpleText("¡PRÓFUGO DETECTADO!", "Datapad_Title", 0, -180, Color(255, 50, 50, pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        
                        local tl, tr = self:GetScreenMargins(-165)
                        surface.SetDrawColor(255, 50, 50, 200)
                        surface.DrawLine(tl + 10, -165, tr - 10, -165)
                    else
                        self:DrawScannerGrid(Color(50, 200, 255), 10)
                        draw.SimpleText("INSPECCIÓN COMPLETADA", "Datapad_Title", 0, -180, Color(50, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        
                        local tl, tr = self:GetScreenMargins(-165)
                        surface.SetDrawColor(50, 255, 255, 100)
                        surface.DrawLine(tl + 10, -165, tr - 10, -165)
                    end
                    
                    if self.ScanResult_Name then
                        local isCivilian = string.StartWith(tostring(self.ScanResult_ID), "ID-")
                        local labelJob = isCivilian and "ESTADO:" or "ASIGNACIÓN:"
                        local labelID = isCivilian and "ID CÍVICO:" or "ID:"
                        
                        -- Marco holográfico de foto (Adaptado al trapecio)
                        local frameColor = isWarrant and Color(255, 50, 50, 50) or Color(0, 150, 255, 20)
                        local frameOutline = isWarrant and Color(255, 50, 50, 200) or Color(0, 150, 255, 150)
                        
                        local fm = 15 -- margin
                        local fLTop, fRTop = self:GetScreenMargins(-140)
                        local fLBot, fRBot = self:GetScreenMargins(120)
                        
                        local framePoly = {
                            { x = fLTop + fm, y = -140 },
                            { x = fRTop - fm, y = -140 },
                            { x = fRBot - fm, y = 120 },
                            { x = fLBot + fm, y = 120 }
                        }
                        
                        surface.SetDrawColor(frameColor)
                        draw.NoTexture()
                        surface.DrawPoly(framePoly)
                        
                        surface.SetDrawColor(frameOutline)
                        for k=1, #framePoly do
                            local next_k = (k % #framePoly) + 1
                            surface.DrawLine(framePoly[k].x, framePoly[k].y, framePoly[next_k].x, framePoly[next_k].y)
                        end
                        
                        -- Helper interno para dibujar las líneas horizontales relativas al trapecio
                        local function DrawTrapezoidLine(yPos, color)
                            local lx, rx = self:GetScreenMargins(yPos)
                            surface.SetDrawColor(color)
                            surface.DrawLine(lx + fm, yPos, rx - fm, yPos)
                            return lx + fm + 5, rx - fm - 5
                        end
                        
                        -- Datos
                        local lineC = isWarrant and Color(255,50,50,100) or Color(0, 150, 255, 50)
                        local lX, rX = DrawTrapezoidLine(-15, lineC)
                        draw.SimpleText("SUJETO:", "Datapad_Text", lX, -5, Color(150, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        
                        -- Auto-escalado de texto cortando si es muy largo
                        local nameStr = string.upper(tostring(self.ScanResult_Name))
                        surface.SetFont("Datapad_Title")
                        local nw = surface.GetTextSize(nameStr)
                        if nw > 140 then nameStr = string.sub(nameStr, 1, 12) .. "..." end
                        draw.SimpleText(nameStr, "Datapad_Title", rX, -5, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        
                        lX, rX = DrawTrapezoidLine(15, lineC)
                        
                        local jobStr = string.upper(tostring(self.ScanResult_Job))
                        surface.SetFont("Datapad_Text")
                        local jw1 = surface.GetTextSize(labelJob)
                        local jw2 = surface.GetTextSize(jobStr)
                        if jw1 + jw2 > 185 and labelJob == "ASIGNACIÓN:" then
                            labelJob = "ASIG:"
                        end
                        if jw2 > 135 then jobStr = string.sub(jobStr, 1, 15) .. "..." end
                        
                        draw.SimpleText(labelJob, "Datapad_Text", lX, 25, Color(150, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        draw.SimpleText(jobStr, "Datapad_Text", rX, 25, Color(200, 200, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        
                        lX, rX = DrawTrapezoidLine(45, lineC)
                        draw.SimpleText(labelID, "Datapad_Text", lX, 55, Color(150, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        draw.SimpleText(tostring(self.ScanResult_ID), "Datapad_Title", rX, 55, Color(255, 200, 50), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        
                        lX, rX = DrawTrapezoidLine(75, lineC)
                        
                        local arrests = tonumber(self.ScanResult_Arrests) or 0
                        local arrColor = arrests > 0 and Color(255, 150, 50) or Color(150, 255, 150)
                        draw.SimpleText("ARRESTOS PREVIOS:", "Datapad_Text", lX, 85, Color(150, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        draw.SimpleText(tostring(arrests), "Datapad_Title", rX, 85, arrColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        
                        DrawTrapezoidLine(105, lineC)
                        
                        if isWarrant then
                            draw.SimpleText("ESTADO: PRÓFUGO", "Datapad_Title", 0, 115, Color(255, 50, 50, pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        else
                            local stampColor = Color(50, 255, 50, math.abs(math.sin(CurTime()*5))*255)
                            draw.SimpleText("ESTADO: VERIFICADO", "Datapad_Title", 0, 115, stampColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        end
                    else
                        draw.SimpleText("ERROR: DATOS PERDIDOS", "Datapad_Title", 0, -50, Color(255, 50, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                elseif self.DatapadState == "scan_history" then
                    self:DrawScannerGrid(Color(150, 200, 255), 8)
                    draw.SimpleText("ÚLTIMOS ESCANEOS", "Datapad_Title", 0, -180, Color(150, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                    local tl, tr = self:GetScreenMargins(-165)
                    surface.SetDrawColor(150, 200, 255, 100)
                    surface.DrawLine(tl + 10, -165, tr - 10, -165)
                    
                    self.ScanHistory = self.ScanHistory or {}
                    
                    if #self.ScanHistory == 0 then
                        draw.SimpleText("NO HAY REGISTROS", "Datapad_Title", 0, 0, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    else
                        local startY = -140
                        -- Solo mostrar los 5 más recientes para que quepan en pantalla
                        local maxToDraw = math.min(5, #self.ScanHistory)
                        
                        for i = 1, maxToDraw do
                            local rec = self.ScanHistory[i]
                            local bgColor = rec.isCivilian and Color(0, 150, 255, 20) or Color(150, 50, 50, 20)
                            if rec.warrant then bgColor = Color(255, 50, 50, 40) end
                            
                            local lTop, rTop = self:GetScreenMargins(startY)
                            local lBot, rBot = self:GetScreenMargins(startY + 50)
                            local padding = 15
                            
                            local itemPoly = {
                                { x = lTop + padding, y = startY },
                                { x = rTop - padding, y = startY },
                                { x = rBot - padding, y = startY + 50 },
                                { x = lBot + padding, y = startY + 50 }
                            }
                            
                            surface.SetDrawColor(bgColor)
                            draw.NoTexture()
                            surface.DrawPoly(itemPoly)
                            
                            -- Nombre y Categoria
                            local catText = rec.isCivilian and "CIV" or "IMP"
                            local nStr = string.sub(rec.name, 1, 15)
                            local titleColor = rec.warrant and Color(255, 50, 50) or Color(255, 255, 255)
                            draw.SimpleText("[" .. catText .. "] " .. nStr, "Datapad_Text", lTop + padding + 5, startY + 5, titleColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                            
                            -- Job
                            local jStr = string.sub(rec.job, 1, 22)
                            draw.SimpleText(jStr, "Datapad_Text", rTop - padding - 5, startY + 5, Color(150, 150, 150), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                            
                            -- Arrestos
                            local arrStr = "Arrestos: " .. rec.arrests
                            local arrC = rec.arrests > 0 and Color(255, 150, 50) or Color(150, 255, 150)
                            draw.SimpleText(arrStr, "Datapad_Text", lBot + padding + 10, startY + 25, arrC, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                            
                            startY = startY + 58
                        end
                    end
                end
                
                -- Alpha maestro para botones
                local btnAlpha = 255
                if self.DatapadState == "login" then
                    btnAlpha = math.Clamp((timeInState - 1.8) * 255, 0, 255)
                end
                
                -- Dibujar botones virtuales dinámicos (estilo Sci-Fi Asimétrico)
                for _, btn in ipairs(self.VirtualButtons or {}) do
                    if btnAlpha <= 0 then continue end
                    
                    local isFullWidth = (btn.w > 200)
                    local poly = {}
                    local cx_btn, cy_btn = btn.x + btn.w / 2, btn.y + btn.h / 2
                    
                    if isFullWidth then
                        local margin = 10
                        local lTop, rTop = self:GetScreenMargins(btn.y)
                        local lBot, rBot = self:GetScreenMargins(btn.y + btn.h)
                        
                        lTop = lTop + margin
                        rTop = rTop - margin
                        lBot = lBot + margin
                        rBot = rBot - margin
                        
                        btn.x = lTop
                        btn.w = rTop - lTop
                        cx_btn, cy_btn = (lTop + rTop) / 2, btn.y + btn.h / 2
                        
                        poly = {
                            { x = lTop, y = btn.y },
                            { x = rTop, y = btn.y },
                            { x = rBot, y = btn.y + btn.h },
                            { x = lBot, y = btn.y + btn.h }
                        }
                    else
                        -- Si no es ancho completo, usar sus coordenadas originales como un rectángulo normal
                        poly = {
                            { x = btn.x, y = btn.y },
                            { x = btn.x + btn.w, y = btn.y },
                            { x = btn.x + btn.w, y = btn.y + btn.h },
                            { x = btn.x, y = btn.y + btn.h }
                        }
                    end
                    
                    local isHovered = (cx and cy and cx >= btn.x and cx <= btn.x + btn.w and cy >= btn.y and cy <= btn.y + btn.h)
                    
                    if isHovered then
                        surface.SetDrawColor(btn.color.r, btn.color.g, btn.color.b, math.min(200, btnAlpha))
                    else
                        surface.SetDrawColor(btn.color.r, btn.color.g, btn.color.b, math.min(30, btnAlpha))
                    end
                    
                    surface.DrawPoly(poly)
                    
                    if btn.text and btn.text ~= "" then
                        local txtC = isHovered and color_white or Color(btn.color.r + 50, btn.color.g + 50, btn.color.b + 50, btnAlpha)
                        draw.SimpleText(btn.text, "Datapad_Text", cx_btn, cy_btn, txtC, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end
                
                -- Dibujar cursor falso 3D
                if cx and cy and cx >= ox and cx <= ox + w and cy >= oy and cy <= oy + h then
                    surface.SetDrawColor(255, 255, 255, 200)
                    surface.DrawRect(cx - 3, cy - 3, 6, 6)
                end
                
            else
                -- Iniciar temporizador la primera vez que se dibuja el arma en la pantalla
                if not self.BootTime then
                    local dur = 1.0
                    local vm = self:GetOwner():GetViewModel()
                    if IsValid(vm) then
                        local seq = vm:LookupSequence("throw_to_tripmine_ND")
                        if seq == -1 then seq = vm:LookupSequence("draw") end
                        if seq ~= -1 then dur = vm:SequenceDuration(seq) end
                    end
                    self.BootTime = CurTime() + math.max(0, dur - 0.1)
                end

                if CurTime() < self.BootTime then
                    -- Pantalla Negra (Iniciando)
                    surface.SetDrawColor(2, 2, 2, 255)
                    surface.DrawPoly(poly)
                else
                    local timeSinceBoot = CurTime() - self.BootTime
                    local fade = math.Clamp(timeSinceBoot * 2, 0, 1) -- Fundido de 0.5 segundos
                    
                    -- Fondo negro base
                    surface.SetDrawColor(2, 2, 2, 255)
                    surface.DrawPoly(poly)
                    
                    -- Tinte verde holográfico encima (hace fade-in)
                    surface.SetDrawColor(0, 20, 5, 200 * fade)
                    surface.DrawPoly(poly)
                    
                    -- Grid escáner en reposo (holográfico)
                    self:DrawScannerGrid(Color(50, 255, 50), 10 * fade)
                    
                    local pulse = math.abs(math.sin(CurTime() * 3)) * 100 + 155
                    local clrGreen = Color(50, 255, 50, pulse * fade)
                    local clrDimGreen = Color(50, 200, 50, 150 * fade)
                    
                    -- LOGO IMPERIAL REPOSO
                    local mat = Material("virtus/imperio", "smooth")
                    surface.SetMaterial(mat)
                    surface.SetDrawColor(clrGreen)
                    local isz = 80
                    surface.DrawTexturedRect(-isz/2, -50 - isz/2, isz, isz)                    
                    -- Efecto de Escáner Inicial (Barrido de arriba hacia abajo)
                    if timeSinceBoot < 1.0 then
                        local scanY = -225 + (timeSinceBoot * 450)
                        surface.SetDrawColor(50, 255, 50, 255 * (1 - timeSinceBoot))
                        surface.DrawRect(-130, scanY, 260, 2)
                    end
                    
                    draw.SimpleText("IMPERIO GALÁCTICO", "Datapad_Title", 0, 40, clrGreen, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText("SISTEMA ONLINE", "Datapad_Text", 0, 70, clrDimGreen, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
        cam.End3D2D()
        render.SuppressEngineLighting(false)
        
        -- ======== HOLOGRAFÍA 3D DEL JUGADOR ========
        if self.DatapadActive and self.DatapadState == "scan_result" and self.ScanResult_Name and IsValid(self.ScanResult_Ent) then
            local mdlName = self.ScanResult_Ent:GetModel()
            
            if not IsValid(self.HoloModel) or string.lower(self.HoloModel:GetModel()) ~= string.lower(mdlName) then
                if IsValid(self.HoloModel) then SafeRemoveEntity(self.HoloModel) end
                self.HoloModel = ClientsideModel(mdlName)
                if IsValid(self.HoloModel) then
                    self.HoloModel:SetNoDraw(true)
                    self.HoloModel:ResetSequence(self.HoloModel:LookupSequence("idle_all_01") or 0)
                end
            end
            
            if IsValid(self.HoloModel) then
                -- En el contexto de este 3D2D:
                -- Eje X (Derecha en pantalla) = screenAng:Forward()
                -- Eje Y (Abajo en pantalla) = screenAng:Right()
                -- Eje Z (Afuera de pantalla) = screenAng:Up()
                
                -- Centro de la caja de la foto real (La caja pequeña va de Y=-130 a Y=-30, centro en Y=-80)
                local holoPos = screenPos + screenAng:Right() * (-80 * 0.012) + screenAng:Up() * 0.5
                
                -- Arriba del modelo = Arriba en pantalla (que es -Right en world space)
                local upVec = screenAng:Right() * -1
                -- Frente = Afuera de la pantalla
                local forwardVec = screenAng:Up()
                
                local holoAng = forwardVec:AngleEx(upVec)
                
                -- Rotación lenta que inicia SIEMPRE mirando de frente (0 grados)
                local timeInState = CurTime() - (self.StateStartTime or CurTime())
                holoAng:RotateAroundAxis(holoAng:Up(), timeInState * -15)
                
                -- Escala más pequeña a petición del usuario
                local scale = 0.075
                local headZ = 64 * scale
                local origin = holoPos - upVec * headZ
                
                self.HoloModel:SetRenderOrigin(origin)
                self.HoloModel:SetRenderAngles(holoAng)
                self.HoloModel:SetModelScale(scale, 0)
                
                -- ======== CLIP PLANES ========
                local oldClip = render.EnableClipping(true)
                
                -- Plano Inferior (Y = -30, límite inferior de la caja de foto)
                local pBottom = screenPos + screenAng:Right() * (-30 * 0.012)
                local nBottom = screenAng:Right() * -1
                render.PushCustomClipPlane(nBottom, nBottom:Dot(pBottom))
                
                -- Plano Superior (Y = -130, límite superior de la caja de foto)
                local pTop = screenPos + screenAng:Right() * (-130 * 0.012)
                local nTop = screenAng:Right()
                render.PushCustomClipPlane(nTop, nTop:Dot(pTop))
                
                -- Plano Izquierdo (X = -100)
                local pLeft = screenPos + screenAng:Forward() * (-100 * 0.012)
                local nLeft = screenAng:Forward()
                render.PushCustomClipPlane(nLeft, nLeft:Dot(pLeft))
                
                -- Plano Derecho (X = 100)
                local pRight = screenPos + screenAng:Forward() * (100 * 0.012)
                local nRight = screenAng:Forward() * -1
                render.PushCustomClipPlane(nRight, nRight:Dot(pRight))
                
                -- Renderizar el modelo (Completamente sólido)
                render.SetBlend(1)
                render.SetColorModulation(0.7, 0.9, 1)
                self.HoloModel:DrawModel()
                
                render.PopCustomClipPlane()
                render.PopCustomClipPlane()
                render.PopCustomClipPlane()
                render.PopCustomClipPlane()
                render.EnableClipping(oldClip)
                
                render.SetBlend(1)
                render.SetColorModulation(1, 1, 1)
            end
        else
            if IsValid(self.HoloModel) then
                self.HoloModel:Remove()
                self.HoloModel = nil
            end
        end
    end

    -- Restauración total del esqueleto de manos
    function SWEP:ResetHands(ply)
        if not IsValid(ply) then return end
        local hands = ply:GetHands()
        if IsValid(hands) then
            if self.OldHandsModel then
                hands:SetModel(self.OldHandsModel)
                self.OldHandsModel = nil
            end
        end
    end
    
    hook.Add("PrePlayerDraw", "Datapad_TPAnim_Bones", function(ply)
        if not IsValid(ply) then return end
        local wep = ply:GetActiveWeapon()
        
        if IsValid(wep) and wep:GetClass() == "weapon_ivo_datapad" then
            local isOpen = wep:GetMenuOpen()
            if ply == LocalPlayer() then
                isOpen = wep.DatapadActive or wep.ThirdPersonRP or false
            end
            
            -- Reducido el multiplicador de velocidad (de 4 a 2.5) para que sea más lento
            wep.TPAnimProgress = Lerp(FrameTime() * 2.5, wep.TPAnimProgress or 0, isOpen and 1 or 0)
            
            local rUpper = ply:LookupBone("ValveBiped.Bip01_R_UpperArm")
            local rForearm = ply:LookupBone("ValveBiped.Bip01_R_Forearm")
            local rHand = ply:LookupBone("ValveBiped.Bip01_R_Hand")
            if rUpper and rForearm and rHand then
                local activeUpper = Angle(40, -50, 0)
                local activeForearm = Angle(0, -10, 0)
                local activeHand = Angle(-70, 00, 15)
                
                ply:ManipulateBoneAngles(rUpper, LerpAngle(wep.TPAnimProgress, Angle(0,0,0), activeUpper))
                ply:ManipulateBoneAngles(rForearm, LerpAngle(wep.TPAnimProgress, Angle(0,0,0), activeForearm))
                ply:ManipulateBoneAngles(rHand, LerpAngle(wep.TPAnimProgress, Angle(0,0,0), activeHand))
            end
            
            ply.DatapadWasActive_Anim = true
        else
            if ply.DatapadWasActive_Anim then
                ply.DatapadWasActive_Anim = false
                local rUpper = ply:LookupBone("ValveBiped.Bip01_R_UpperArm")
                local rForearm = ply:LookupBone("ValveBiped.Bip01_R_Forearm")
                local rHand = ply:LookupBone("ValveBiped.Bip01_R_Hand")
                if rUpper then ply:ManipulateBoneAngles(rUpper, Angle(0,0,0)) end
                if rForearm then ply:ManipulateBoneAngles(rForearm, Angle(0,0,0)) end
                if rHand then ply:ManipulateBoneAngles(rHand, Angle(0,0,0)) end
            end
        end
    end)
end
