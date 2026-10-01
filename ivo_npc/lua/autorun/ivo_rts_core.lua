-- ivo_rts_core.lua
-- Core RTS camera and networking for Droid Commander

if SERVER then
    AddCSLuaFile("ivo_rts_config.lua")
    include("ivo_rts_config.lua")

    util.AddNetworkString("IVO_RTS_Deploy")
    util.AddNetworkString("IVO_RTS_Move")
    util.AddNetworkString("IVO_RTS_CamSync")
    util.AddNetworkString("IVO_RTS_Stance")

    net.Receive("IVO_RTS_Stance", function(len, ply)
        if not ply:GetNWBool("IVO_RTSMode", false) then return end
        local cur = ply:GetNWBool("IVO_RTS_HoldPos", false)
        ply:SetNWBool("IVO_RTS_HoldPos", not cur)
        ply:ChatPrint(cur and "Postura: MODO LIBRE" or "Postura: MANTENER POSICIÓN")
    end)

    net.Receive("IVO_RTS_CamSync", function(len, ply)
        if not ply:GetNWBool("IVO_RTSMode", false) then return end
        ply.RTSCamPos = net.ReadVector()
    end)

    hook.Add("SetupPlayerVisibility", "IVO_RTS_PVS", function(ply, viewEntity)
        if ply:GetNWBool("IVO_RTSMode", false) and ply.RTSCamPos then
            AddOriginToPVS(ply.RTSCamPos)
        end
    end)

    function IVO_RTS.InjectAAT_AI(ent)
        if ent:GetClass() ~= "lvs_fakehover_aat" then return end
        if ent.OriginalRunAI then return end
        ent.OriginalRunAI = ent.RunAI
        ent.RunAI = function(self)
            if not self.IsRTSUnit then
                if self.OriginalRunAI then self:OriginalRunAI() end
                return
            end
            
            local owner = self:GetNWEntity("CommanderOwner")
            local holdPos = IsValid(owner) and owner:GetNWBool("IVO_RTS_HoldPos", false)
            
            -- Priority 1: Commander Goal (Moving to a point)
            if self.CommanderGoal then
                local DistToTarget = (self.CommanderGoal - self:GetPos()):Length2D()
                if DistToTarget > 150 then
                    local moveDir = (self.CommanderGoal - self:GetPos()):GetNormalized()
                    self:SetSteerTo(moveDir:Angle().y)
                    
                    local LocalMove = self:WorldToLocal(self.CommanderGoal)
                    local X = 0
                    if LocalMove.x > 0 and LocalMove.x > math.abs(LocalMove.y) then
                        X = 1
                    end
                    local boost = (DistToTarget > 800 and LocalMove.x > 100)
                    self:SetMove(X, 0, boost)
                    
                    local Target = self:AIGetTarget(180)
                    if IsValid(Target) then
                        local targetPos = Target:LocalToWorld(Target:OBBCenter())
                        local pod = self:GetDriverSeat()
                        if IsValid(pod) then
                            local aimDir = (targetPos - pod:LocalToWorld(Vector(0,0,33))):GetNormalized()
                            self:SetAIAimVector(aimDir)
                        end
                        if self:AITargetInFront(Target, 65) then
                            self._AIFireInput = true
                            if self.AISelectWeapon then
                                local CurHeat = self:GetNWHeat()
                                local CurWeapon = self:GetSelectedWeapon()
                                if CurWeapon > 2 then self:AISelectWeapon(1)
                                elseif CurHeat > 0.9 then
                                    if CurWeapon == 1 and self:AIHasWeapon(2) then self:AISelectWeapon(2)
                                    elseif CurWeapon == 2 then self:AISelectWeapon(1) end
                                elseif CurHeat == 0 and math.cos(CurTime()) > 0 then self:AISelectWeapon(1) end
                            end
                        else
                            self._AIFireInput = false
                        end
                    else
                        self._AIFireInput = false
                        self:SetAIAimVector(moveDir)
                    end
                    
                    return -- Skip default AI
                else
                    self.CommanderGoal = nil
                end
            end
            
            -- Priority 2: Hold Position (Standing still like a turret)
            if holdPos then
                self:SetMove(0, 0, false)
                
                local Target = self:AIGetTarget(180)
                if IsValid(Target) then
                    local targetPos = Target:LocalToWorld(Target:OBBCenter())
                    local pod = self:GetDriverSeat()
                    if IsValid(pod) then
                        local aimDir = (targetPos - pod:LocalToWorld(Vector(0,0,33))):GetNormalized()
                        self:SetSteerTo(aimDir:Angle().y)
                        self:SetAIAimVector(aimDir)
                    end
                    if self:AITargetInFront(Target, 65) then
                        self._AIFireInput = true
                        if self.AISelectWeapon then
                            local CurHeat = self:GetNWHeat()
                            local CurWeapon = self:GetSelectedWeapon()
                            if CurWeapon > 2 then self:AISelectWeapon(1)
                            elseif CurHeat > 0.9 then
                                if CurWeapon == 1 and self:AIHasWeapon(2) then self:AISelectWeapon(2)
                                elseif CurWeapon == 2 then self:AISelectWeapon(1) end
                            elseif CurHeat == 0 and math.cos(CurTime()) > 0 then self:AISelectWeapon(1) end
                        end
                    else
                        self._AIFireInput = false
                    end
                else
                    self._AIFireInput = false
                end
                
                return -- Skip default AI
            end
            
            -- Priority 3: Free Roam (Use default LVS logic)
            if self.OriginalRunAI then
                self:OriginalRunAI()
            end
        end
    end

    local function AssimilateDroid(ent, ply)
        if IsValid(ent:GetNWEntity("CommanderOwner")) then return end

        ent.IsRTSUnit = true
        ent:SetNWEntity("CommanderOwner", ply)
        ent.CommanderOwnerRaw = ply
        
        if ent.SetAITEAM then
            ent:SetAITEAM(1)
        end

        local c = ent:GetClass()
        if c == "lvs_fakehover_aat" then 
            ent.Cost = 10
            IVO_RTS.InjectAAT_AI(ent)
        elseif c == "npc_droid_droideka" then ent.Cost = 5
        elseif c == "npc_droid_bx" then ent.Cost = 3
        elseif c == "npc_droid_b2" then ent.Cost = 2
        else ent.Cost = 1 end

        ply.IVOPopulation = (ply.IVOPopulation or 0) + ent.Cost
        ply:SetNWInt("IVO_RTSPop", ply.IVOPopulation)
    end

    hook.Add("OnEntityCreated", "IVO_RTS_AssimilateCreated", function(ent)
        timer.Simple(0.1, function()
            if IsValid(ent) and (string.find(ent:GetClass(), "npc_droid_") or ent:GetClass() == "lvs_fakehover_aat") then
                if IsValid(ent:GetNWEntity("CommanderOwner")) then return end
                for _, ply in ipairs(player.GetAll()) do
                    if ply:GetNWBool("IVO_RTSMode", false) then
                        AssimilateDroid(ent, ply)
                        break
                    end
                end
            end
        end)
    end)

    hook.Add("PlayerSay", "IVO_RTS_Command", function(ply, text)
        if string.lower(text) == "!rts" then
            if ply:IsAdmin() or ply:IsSuperAdmin() then
                local isRTS = not ply:GetNWBool("IVO_RTSMode", false)
                ply:SetNWBool("IVO_RTSMode", isRTS)

                if isRTS then
                    ply:ChatPrint("Modo RTS Activado. Usa WASD para mover la cámara y el ratón para comandar.")
                    ply:SetMoveType(MOVETYPE_NONE) -- Freeze their physical body
                    -- Make them invisible/invincible or ignored by AI
                    ply:SetNoDraw(true)
                    ply:SetNotSolid(true)
                    ply:GodEnable()
                    ply:SetNoTarget(true)

                    -- Initialize population limit if missing
                    if not ply.IVOPopulation then ply.IVOPopulation = 0 end
                    
                    -- Assimilate all existing droids on the map
                    for _, ent in ipairs(ents.FindByClass("npc_droid_*")) do
                        AssimilateDroid(ent, ply)
                    end
                    for _, ent in ipairs(ents.FindByClass("lvs_fakehover_aat")) do
                        AssimilateDroid(ent, ply)
                    end
                else
                    ply:ChatPrint("Modo RTS Desactivado.")
                    ply:SetMoveType(MOVETYPE_WALK)
                    ply:SetNoDraw(false)
                    ply:SetNotSolid(false)
                    ply:GodDisable()
                    ply:SetNoTarget(false)
                end
                return "" -- Hide command from chat
            else
                ply:ChatPrint("No tienes permisos para usar el modo RTS.")
            end
        end
    end)

    -- Game Master Points Generation
    hook.Add("PlayerInitialSpawn", "IVO_RTS_InitGMP", function(ply)
        ply:SetNWInt("IVO_RTS_GMP", 50)
        ply.IVO_RTS_Cooldowns = {}
    end)

    util.AddNetworkString("IVO_RTS_Passive")
    net.Receive("IVO_RTS_Passive", function(len, ply)
        if not ply:GetNWBool("IVO_RTSMode", false) then return end
        local cur = ply:GetNWBool("IVO_RTS_Passive", false)
        ply:SetNWBool("IVO_RTS_Passive", not cur)
        ply:ChatPrint(cur and "Comportamiento: ATAQUE" or "Comportamiento: PASIVO")
    end)

    timer.Create("IVO_RTS_GMPRegen", 5.0, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetNWBool("IVO_RTSMode", false) then
                local gmp = ply:GetNWInt("IVO_RTS_GMP", 0)
                if gmp < 500 then
                    ply:SetNWInt("IVO_RTS_GMP", math.min(500, gmp + 1))
                end
            end
        end
    end)
    
    -- Recompensas GMP por acciones de NPC
    hook.Add("EntityTakeDamage", "IVO_RTS_GMP_Damage", function(target, dmginfo)
        local attacker = dmginfo:GetAttacker()
        if IsValid(attacker) and attacker.IsRTSUnit and IsValid(attacker.CommanderOwnerRaw) then
            if target:IsPlayer() then
                local ply = attacker.CommanderOwnerRaw
                local gmp = ply:GetNWInt("IVO_RTS_GMP", 0)
                ply:SetNWInt("IVO_RTS_GMP", gmp + 2)
            end
        end
    end)
    
    hook.Add("EntityRemoved", "IVO_RTS_GMP_Destroy", function(ent)
        -- Si un NPC aliado destruye algo importante (vehiculo, prop de jugador)
        -- Es complejo saber exactamente quién lo destruyó en OnRemove,
        -- pero LVS.OnVehicleDestroyed ya lo maneja para vehículos.
    end)

    -- Removed hardcoded CPCosts here

    util.AddNetworkString("IVO_RTS_GunshipDeploy")

    net.Receive("IVO_RTS_GunshipDeploy", function(len, ply)
        if not ply:GetNWBool("IVO_RTSMode", false) then return end
        
        local targetPos = net.ReadVector()
        local payload = net.ReadTable()
        
        local cfg = nil
        for _, opt in ipairs(IVO_RTS.Config.DeployOptions) do
            if opt.isCustomGunship then cfg = opt break end
        end
        if not cfg then return end
        
        -- Verificar Cooldown
        ply.IVO_RTS_Cooldowns = ply.IVO_RTS_Cooldowns or {}
        local cdName = "Gunship"
        if ply.IVO_RTS_Cooldowns[cdName] and ply.IVO_RTS_Cooldowns[cdName] > CurTime() then
            ply:ChatPrint("Cañonera en enfriamiento (" .. math.ceil(ply.IVO_RTS_Cooldowns[cdName] - CurTime()) .. "s)")
            return
        end
        
        local maxPop = IVO_RTS.Config.MaxPopulation or 50
        ply.IVOPopulation = ply.IVOPopulation or 0
        
        local count = #payload
        if count > 25 then
            ply:ChatPrint("¡La cañonera solo admite 25 unidades!")
            return
        end
        
        if ply.IVOPopulation + count > maxPop then
            ply:ChatPrint("¡Límite de población alcanzado!")
            return
        end
        
        local totalGMP = 0
        for _, class in ipairs(payload) do
            local cost = (IVO_RTS.Config.UnitCostsGMP and IVO_RTS.Config.UnitCostsGMP[class]) or 0
            totalGMP = totalGMP + cost
        end
        
        local currentGMP = ply:GetNWInt("IVO_RTS_GMP", 0)
        if currentGMP < totalGMP then
            ply:ChatPrint("¡Game Master Points insuficientes! (Necesitas " .. totalGMP .. " GMP)")
            return
        end
        
        ply:SetNWInt("IVO_RTS_GMP", currentGMP - totalGMP)
        ply.IVOPopulation = ply.IVOPopulation + count
        ply:SetNWInt("IVO_RTSPop", ply.IVOPopulation)
        
        ply.IVO_RTS_Cooldowns[cdName] = CurTime() + (cfg.cooldown or 60)
        ply:SetNWFloat("IVO_RTS_CD_"..cdName, ply.IVO_RTS_Cooldowns[cdName])
        
        local hmp = ents.Create("ent_rts_hmp_drop")
        if IsValid(hmp) then
            hmp:SetPos(targetPos)
            hmp:SetAngles(Angle(0, math.random(0, 360), 0))
            hmp.CommanderOwner = ply
            hmp.PayloadTable = payload
            hmp:Spawn()
            hmp:Activate()
        end
    end)

    net.Receive("IVO_RTS_Deploy", function(len, ply)
        if not ply:GetNWBool("IVO_RTSMode", false) then return end

        local targetPos = net.ReadVector()
        local droidClass = net.ReadString()

        local cfg = IVO_RTS.GetUnitConfig(droidClass)
        if not cfg then return end
        
        ply.IVO_RTS_Cooldowns = ply.IVO_RTS_Cooldowns or {}
        local cdName = droidClass
        if ply.IVO_RTS_Cooldowns[cdName] and ply.IVO_RTS_Cooldowns[cdName] > CurTime() then
            ply:ChatPrint("Unidad en enfriamiento (" .. math.ceil(ply.IVO_RTS_Cooldowns[cdName] - CurTime()) .. "s)")
            return
        end
        
        local maxPop = IVO_RTS.Config.MaxPopulation or 50
        ply.IVOPopulation = ply.IVOPopulation or 0

        local popCost = cfg.cost or 1
        
        if ply.IVOPopulation + popCost > maxPop then
            ply:ChatPrint("¡Límite de población alcanzado!")
            return
        end

        local totalGMP = cfg.gmp or 0
        local currentGMP = ply:GetNWInt("IVO_RTS_GMP", 0)
        
        if currentGMP < totalGMP then
            ply:ChatPrint("¡Game Master Points insuficientes! (Necesitas " .. totalGMP .. " GMP)")
            return
        end

        ply:SetNWInt("IVO_RTS_GMP", currentGMP - totalGMP)
        ply.IVOPopulation = ply.IVOPopulation + popCost
        ply:SetNWInt("IVO_RTSPop", ply.IVOPopulation)
        
        ply.IVO_RTS_Cooldowns[cdName] = CurTime() + (cfg.cooldown or 30)
        ply:SetNWFloat("IVO_RTS_CD_"..cdName, ply.IVO_RTS_Cooldowns[cdName])

        if droidClass == "lvs_fakehover_aat" then
            local hmp = ents.Create("ent_rts_hmp_drop")
            if IsValid(hmp) then
                hmp:SetPos(targetPos)
                hmp:SetAngles(Angle(0, math.random(0, 360), 0))
                hmp.CommanderOwner = ply
                hmp.PayloadTable = {"lvs_fakehover_aat"}
                hmp:Spawn()
                hmp:Activate()
            end
            return
        end

        local pod = ents.Create("ent_droid_pod")
        if not IsValid(pod) then return end
        pod:SetPos(targetPos + Vector(0, 0, 1000))
        pod:SetAngles(Angle(0, math.random(0, 360), 0))
        pod.DroidClass = droidClass
        pod.DroidCount = 1
        pod.CommanderOwner = ply
        pod.CostPerDroid = popCost
        pod:Spawn()
        pod:Activate()
    end)

    hook.Add("EntityRemoved", "IVO_RTS_PopDeduct", function(ent)
        if ent.IsRTSUnit and IsValid(ent.CommanderOwnerRaw) then
            local ply = ent.CommanderOwnerRaw
            ply.IVOPopulation = math.max(0, (ply.IVOPopulation or 0) - (ent.Cost or 1))
            ply:SetNWInt("IVO_RTSPop", ply.IVOPopulation)
        end
    end)

    hook.Add("LVS.OnVehicleDestroyed", "IVO_RTS_DarkRPMoney", function(ent, attacker, inflictor)
        if ent.IsRTSUnit and IsValid(attacker) and attacker:IsPlayer() then
            if attacker.addMoney then
                local mult = (IVO_RTS and IVO_RTS.Config and IVO_RTS.Config.DarkRPRewardMultiplier) or 50
                local reward = ent.Cost and (ent.Cost * mult) or 500
                attacker:addMoney(reward)
                if DarkRP and DarkRP.notify then
                    DarkRP.notify(attacker, 0, 4, "Has recibido $" .. reward .. " por destruir un vehículo enemigo.")
                end
            end
        end
    end)

    -- Handle movement and formations
    net.Receive("IVO_RTS_Move", function(len, ply)
        if not ply:GetNWBool("IVO_RTSMode", false) then return end
        
        local targetPos = net.ReadVector()
        local formation = net.ReadString()
        local numEnts = net.ReadUInt(16)
        
        for i = 1, numEnts do
            local e = net.ReadEntity()
            local goal = net.ReadVector()
            
            if IsValid(e) and e.IsRTSUnit and e:GetNWEntity("CommanderOwner") == ply then
                e.CommanderGoal = goal
            end
        end
    end)
end

if CLIENT then
    local RTSCameraPos = nil
    IVO_RTS.CameraYaw = IVO_RTS.CameraYaw or 0
    local RTSZoom = 1000
    local camSpeed = 1000

    hook.Add("GUIMousePressed", "IVO_RTS_Zoom", function(mc)
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:GetNWBool("IVO_RTSMode", false) then return end
        
        if mc == MOUSE_WHEEL_UP then
            RTSZoom = math.Clamp(RTSZoom - 100, 300, 3000)
        elseif mc == MOUSE_WHEEL_DOWN then
            RTSZoom = math.Clamp(RTSZoom + 100, 300, 3000)
        end
    end)

    local wasRTSMode = false
    hook.Add("CalcView", "IVO_RTS_Camera", function(ply, pos, angles, fov)
        local isRTSMode = ply:GetNWBool("IVO_RTSMode", false)
        if isRTSMode then
            wasRTSMode = true
            if not RTSCameraPos then
                RTSCameraPos = pos -- Start ground target at player
            end

            local view = {}
            view.angles = Angle(60, IVO_RTS.CameraYaw, 0) -- Inclined view with dynamic yaw
            view.origin = RTSCameraPos - view.angles:Forward() * RTSZoom
            view.fov = fov
            view.drawviewer = true
            
            IVO_RTS.CurrentCameraPos = view.origin

            return view
        else
            RTSCameraPos = nil
            IVO_RTS.CameraYaw = 0
            if wasRTSMode then
                gui.EnableScreenClicker(false)
                wasRTSMode = false
            end
            if IsValid(IVO_RTS_CursorPanel) then
                IVO_RTS_CursorPanel:Remove()
            end
        end
    end)

    hook.Add("Think", "IVO_RTS_CameraMove", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:GetNWBool("IVO_RTSMode", false) then return end

        gui.EnableScreenClicker(true)
        if not IsValid(IVO_RTS_CursorPanel) then
            IVO_RTS_CursorPanel = vgui.Create("DPanel")
            IVO_RTS_CursorPanel:SetSize(ScrW(), ScrH())
            IVO_RTS_CursorPanel:SetCursor("blank")
            IVO_RTS_CursorPanel.Paint = function() end
            
            IVO_RTS_CursorPanel.Think = function(s)
                local mx, my = gui.MouseX(), gui.MouseY()
                local sx, sy, sw, sh = ScrW() - 340, 20, 320, ScrH() - 40
                if mx >= sx and mx <= sx + sw and my >= sy and my <= sy + sh then
                    s:SetCursor("arrow")
                else
                    s:SetCursor("blank")
                end
            end
            
            IVO_RTS_CursorPanel.OnMousePressed = function(s, mc)
                hook.Run("GUIMousePressed", mc)
            end
            IVO_RTS_CursorPanel.OnMouseReleased = function(s, mc)
                hook.Run("GUIMouseReleased", mc)
            end
        end

        if not RTSCameraPos then return end

        local ft = FrameTime()
        local speed = camSpeed * ft
        if input.IsKeyDown(KEY_LSHIFT) then speed = speed * 2 end

        -- Movement relative to camera yaw
        local fwd = Angle(0, IVO_RTS.CameraYaw, 0):Forward()
        local rgt = Angle(0, IVO_RTS.CameraYaw, 0):Right()
        local up = Vector(0, 0, 1)

        if input.IsKeyDown(KEY_W) then RTSCameraPos = RTSCameraPos + fwd * speed end
        if input.IsKeyDown(KEY_S) then RTSCameraPos = RTSCameraPos - fwd * speed end
        if input.IsKeyDown(KEY_A) then RTSCameraPos = RTSCameraPos - rgt * speed end
        if input.IsKeyDown(KEY_D) then RTSCameraPos = RTSCameraPos + rgt * speed end
        if input.IsKeyDown(KEY_SPACE) then RTSCameraPos = RTSCameraPos + up * speed end
        if input.IsKeyDown(KEY_LCONTROL) then RTSCameraPos = RTSCameraPos - up * speed end

        if not ply.NextRTSSync or CurTime() > ply.NextRTSSync then
            ply.NextRTSSync = CurTime() + 0.1
            net.Start("IVO_RTS_CamSync")
                net.WriteVector(RTSCameraPos)
            net.SendToServer()
        end
    end)
end
