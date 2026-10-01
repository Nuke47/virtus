-- ============================================
--  BOUNTY HUNTER SYSTEM - Cliente
--  Archivo: lua/bounty_hunter/client/cl_bounty.lua
-- ============================================

BountySystem.LocalBounties = {}
BountySystem.MyStats = BountySystem.MyStats or { level = 1, xp = 0, prestige = 0, kills = 0 }
local cfg = BountySystem.Config
local C   = cfg.Colors

-- ──────────────────────────────────────────
--  UI PRINCIPAL Y COLORES
-- ──────────────────────────────────────────
local FONT_TITLE  = "BountySystem_Title"
local FONT_HEADER = "BountySystem_Header"
local FONT_BODY   = "BountySystem_Body"
local FONT_MONO   = "BountySystem_Mono"

surface.CreateFont(FONT_TITLE,  { font = "Roboto", size = 28, weight = 800 })
surface.CreateFont(FONT_HEADER, { font = "Roboto", size = 16, weight = 700 })
surface.CreateFont(FONT_BODY,   { font = "Roboto", size = 14, weight = 400 })
surface.CreateFont(FONT_MONO,   { font = "Roboto",  size = 13, weight = 600 })

-- Colores UI HoloNet (Terminal AR)
local UI = {
    BG       = Color(2, 6, 12, 210),
    Panel    = Color(5, 15, 25, 180),
    Row      = Color(0, 20, 40, 150),
    RowHover = Color(0, 50, 80, 200),
    Divider  = Color(0, 150, 255, 100),
    Red      = Color(255, 50, 50),
    Gold     = Color(255, 200, 50),
    Green    = Color(50, 255, 100),
    Blue     = Color(0, 200, 255),
    White    = Color(230, 245, 255),
    Gray     = Color(120, 150, 180),
}

-- Materiales cacheados para el efecto Holograma 3D
local matSolid = Material("models/debug/debugwhite")
local matWire  = Material("models/wireframe")
local matGlow  = Material("sprites/light_glow02_add")

-- ──────────────────────────────────────────
--  UTILIDAD: CLONAR APARIENCIA (Bodygroups, Skins, etc)
-- ──────────────────────────────────────────
function BountySystem.CopyModelData(source, target)
    if not IsValid(source) or not IsValid(target) then return end
    target:SetSkin(source:GetSkin() or 0)
    for _, bg in ipairs(source:GetBodyGroups()) do
        target:SetBodygroup(bg.id, source:GetBodygroup(bg.id))
    end
    for i = 0, 31 do target:SetSubMaterial(i, source:GetSubMaterial(i)) end
    target:SetMaterial(source:GetMaterial() or "")
    target:SetColor(source:GetColor())
end

-- ──────────────────────────────────────────
--  RECIBIR LISTA DE RECOMPENSAS
-- ──────────────────────────────────────────
net.Receive("BountySystem_SyncBounties", function()
    BountySystem.LocalBounties = net.ReadTable()
    for id, b in pairs(BountySystem.LocalBounties) do
        b.clientReceiveTime = CurTime()
    end
    -- Actualizar UI si está abierta
    if IsValid(BountySystem.Frame) then
        BountySystem.PopulateBountyList()
    end
    BountySystem.UpdateTrackerHUD()
end)

-- ──────────────────────────────────────────
--  NOTIFICACIONES
-- ──────────────────────────────────────────
BountySystem.Notifications = {}

net.Receive("BountySystem_Notify", function()
    local msg = net.ReadString()
    local r   = net.ReadUInt(8)
    local g   = net.ReadUInt(8)
    local b   = net.ReadUInt(8)
    local col = Color(r, g, b)

    table.insert(BountySystem.Notifications, {
        msg     = msg,
        color   = col,
        created = CurTime(),
        alpha   = 255,
    })
    -- Limitar a 5 notificaciones
    if #BountySystem.Notifications > 5 then
        table.remove(BountySystem.Notifications, 1)
    end

    surface.PlaySound("buttons/button17.wav")
end)

-- ──────────────────────────────────────────
--  RECIBIR ESTADÍSTICAS
-- ──────────────────────────────────────────
net.Receive("BountySystem_SyncStats", function()
    BountySystem.MyStats = net.ReadTable()
    if IsValid(BountySystem.Frame) and BountySystem.ActiveTab == "profile" then
        BountySystem.BuildProfilePanel(BountySystem.ContentPanel)
    end
end)

net.Receive("BountySystem_SyncAdminStats", function()
    BountySystem.AllStats = net.ReadTable()
end)

net.Receive("BountySystem_OpenHireMenu", function()
    local target = net.ReadEntity()
    local stats = net.ReadTable()
    if IsValid(target) then
        BountySystem.OpenMenu(target, stats)
    end
end)

-- ──────────────────────────────────────────
--  HUD - RECOMPENSA PROPIA + NOTIFICACIONES
-- ──────────────────────────────────────────
hook.Add("HUDPaint", "BountySystem_HUD", function()
    local sw, sh = ScrW(), ScrH()
    local now = CurTime()
    local me = LocalPlayer()
    if not IsValid(me) then return end

    -- ── 1. NOTIFICACIONES ESTILO HOLONET ──
    local notifY = sh * 0.15
    for i = #BountySystem.Notifications, 1, -1 do
        local n = BountySystem.Notifications[i]
        local age = now - n.created
        if age > 5 then
            table.remove(BountySystem.Notifications, i)
        else
            local alpha = 255
            if age < 0.3 then alpha = (age / 0.3) * 255 -- Fade in suave
            elseif age > 4 then alpha = 255 * (1 - (age - 4)) end

            local w = 450
            local x = sw - w - 20
            local h = 50

            -- Fondo AR y Bordes
            draw.RoundedBox(0, x, notifY, w, h, Color(2, 6, 12, alpha * 0.85))
            surface.SetDrawColor(n.color.r, n.color.g, n.color.b, alpha * 0.5)
            surface.DrawOutlinedRect(x, notifY, w, h, 1)
            
            -- Detalles Cibernéticos
            surface.SetDrawColor(ColorAlpha(n.color, alpha))
            surface.DrawRect(x, notifY, 4, h)
            surface.DrawRect(x + w - 10, notifY, 10, 2)
            surface.DrawRect(x + w - 10, notifY + h - 2, 10, 2)

            -- Textos
            draw.SimpleText("TRANSMISIÓN ENTRANTE", "BountySystem_Mono", x + 14, notifY + 6, Color(0, 200, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(n.msg, "BountySystem_Body", x + 14, notifY + 22, Color(230, 245, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            notifY = notifY + h + 10
        end
    end

    -- ── 3. HUD DE INTERACCIÓN (CONTRATAR) ──
    local tr = util.TraceLine({ start = me:EyePos(), endpos = me:EyePos() + me:GetAimVector() * 100, filter = me })
    if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
        local target = tr.Entity
        local jobCmd = RPExtraTeams and RPExtraTeams[target:Team()] and RPExtraTeams[target:Team()].command or ""
        local myJobCmd = RPExtraTeams and RPExtraTeams[me:Team()] and RPExtraTeams[me:Team()].command or ""
        
        if cfg.BountyHunterJobs and cfg.BountyHunterJobs[jobCmd] and not cfg.BountyHunterJobs[myJobCmd] then
            draw.SimpleText("Presiona [E] para contratar", "BountySystem_Header", sw/2, sh/2 + 30, UI.Gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end)

-- ──────────────────────────────────────────
--  HUD VGUI DE RASTREO (PRESA ACTIVA)
-- ──────────────────────────────────────────
function BountySystem.UpdateTrackerHUD()
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local mySteam = me:SteamID()
    local activeTarget = nil
    
    for id, b in pairs(BountySystem.LocalBounties) do
        if b.acceptedBy == mySteam and (b.status == "active" or (BountySystem.STATUS and b.status == BountySystem.STATUS.ACTIVE)) then
            activeTarget = b
            break
        end
    end

    if not activeTarget then
        if IsValid(BountySystem.TrackerPanel) then
            BountySystem.TrackerPanel:Remove()
        end
        return
    end

    if not IsValid(BountySystem.TrackerPanel) then
        local w, h = 350, 140
        local pnl = vgui.Create("DPanel")
        BountySystem.TrackerPanel = pnl
        pnl:SetSize(w, h)
        pnl:SetPos(ScrW() - w - 20, ScrH() * 0.45)
        pnl:ParentToHUD()
        
        pnl.TargetName = ""
        pnl.TargetAmount = 0
        pnl.TargetPly = nil

        local mdlPanel = vgui.Create("DModelPanel", pnl)
        mdlPanel:SetPos(10, 10)
        mdlPanel:SetSize(60, h - 20)
        mdlPanel:SetModel("models/player/kleiner.mdl")
        mdlPanel.LayoutEntity = function(self, ent)
            ent:SetAngles(Angle(0, 15, 0)) -- Retrato fijo y serio, sin girar
        end
        mdlPanel.PreDrawModel = function(self, ent)
            local flicker = 0.8 + math.sin(RealTime() * 20) * 0.1
            render.SetBlend(flicker * 0.8)
            render.SetColorModulation(0.3, 0.7, 1)
            render.MaterialOverride(nil)
            ent:DrawModel()
            
            render.SetBlend(flicker * 0.2)
            render.SetColorModulation(0, 0.4, 1)
            render.MaterialOverride(matSolid)
            ent:DrawModel()
            
            render.MaterialOverride(nil)
            render.SetBlend(1)
            render.SetColorModulation(1, 1, 1)
            return false
        end
        pnl.MdlPanel = mdlPanel

        pnl.Paint = function(self, pw, ph)
            local now = CurTime()
            -- Fondo de Interfaz Táctica
            draw.RoundedBox(0, 0, 0, pw, ph, Color(2, 6, 12, 180))
            
            -- Bordes de Alerta Roja
            surface.SetDrawColor(255, 50, 50, 150)
            surface.DrawOutlinedRect(0, 0, pw, ph, 1)
            surface.SetDrawColor(255, 50, 50, 220)
            surface.DrawRect(0, 0, pw, 4) -- Barra superior
            surface.DrawRect(0, ph - 4, 15, 4) -- Esquina inferior izq
            surface.DrawRect(pw - 15, ph - 4, 15, 4) -- Esquina inferior der

            -- Animación de escáner (Scanline)
            surface.SetDrawColor(255, 50, 50, 15)
            surface.DrawRect(0, (now * 60) % ph, pw, 4)

            -- Textos
            local textX = 85
            draw.SimpleText("⚠ PRESA ACTIVA", "BountySystem_Title", textX, 10, Color(255, 50, 50), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            draw.SimpleText("Objetivo: " .. self.TargetName, "BountySystem_Body", textX, 45, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("Pago: " .. (BountySystem.Config.CurrencySymbol or "$") .. self.TargetAmount, "BountySystem_Mono", textX, 65, Color(255, 200, 50), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            -- Cálculo de Distancia en tiempo real
            if IsValid(self.TargetPly) and self.TargetPly:Alive() then
                local dist = math.Round(LocalPlayer():GetPos():Distance(self.TargetPly:GetPos()) * 0.01905)
                if dist <= 50 then
                    draw.SimpleText("Distancia: CERCA", "BountySystem_Header", textX, 85, Color(255, 50, 50), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                else
                    draw.SimpleText("Distancia: " .. dist .. "m", "BountySystem_Header", textX, 85, Color(50, 255, 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
            else
                draw.SimpleText("Señal perdida...", "BountySystem_Header", textX, 85, Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
            
            local elapsed = now - (self.TargetReceiveTime or now)
            local remaining = math.max(0, (self.TargetTimeLeft or 0) - elapsed)
            local mins = math.floor(remaining / 60)
            local secs = math.floor(remaining % 60)
            local timeStr = string.format("%02d:%02d", mins, secs)
            local timeColor = remaining <= 60 and Color(255, 50, 50) or Color(200, 200, 200)
            draw.SimpleText("Tiempo Restante: " .. timeStr, "BountySystem_Header", textX, 105, timeColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end

    local pnl = BountySystem.TrackerPanel
    pnl.TargetName = activeTarget.targetName or "Desconocido"
    pnl.TargetAmount = activeTarget.amount
    pnl.TargetTimeLeft = activeTarget.timeLeft or 0
    pnl.TargetReceiveTime = activeTarget.clientReceiveTime or CurTime()
    
    local targetPly = nil
    for _, p in ipairs(player.GetAll()) do
        local pSteam = p:IsBot() and ("BOT_" .. p:EntIndex()) or p:SteamID()
        if pSteam == activeTarget.targetSteam then
            targetPly = p
            break
        end
    end
    pnl.TargetPly = targetPly

    if IsValid(targetPly) then
        pnl.MdlPanel:SetModel(targetPly:GetModel())
        BountySystem.CopyModelData(targetPly, pnl.MdlPanel.Entity)
        local mn, mx = pnl.MdlPanel.Entity:GetRenderBounds()
        local headZ = mx.z - 6 -- Localizamos la altura exacta de la cara/ojos
        pnl.MdlPanel:SetFOV(35) -- Zoom fuerte hacia la cabeza
        pnl.MdlPanel:SetCamPos(Vector(25, 5, headZ))
        pnl.MdlPanel:SetLookAt(Vector(0, 0, headZ))
        local sequence = pnl.MdlPanel.Entity:SelectWeightedSequence(ACT_IDLE)
        pnl.MdlPanel.Entity:ResetSequence(sequence)
    end
end

-- ========================================================
--  SISTEMA 1: DATAPAD (F3 / !contratos) - UI 2D
-- ========================================================
function BountySystem.OpenMenu(hireTarget, hireStats)
    if IsValid(BountySystem.Frame) then
        BountySystem.Frame:Remove()
        return
    end

    BountySystem.HireTarget = hireTarget
    BountySystem.HireStats = hireStats

    -- Pedir lista actualizada al servidor
    net.Start("BountySystem_RequestList") net.SendToServer()

    -- Rework: Datapad vertical
    local W, H = 550, 800

    local frame = vgui.Create("DFrame")
    BountySystem.Frame = frame
    frame:SetSize(W, H)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:MakePopup()

    frame.startTime = SysTime()
    frame.Paint = function(self, w, h)
        -- Fondo principal AR
        draw.RoundedBox(0, 0, 0, w, h, UI.BG)
        
        -- Cuadrícula Táctica HoloNet
        surface.SetDrawColor(0, 150, 255, 10)
        for x = 0, w, 40 do surface.DrawLine(x, 0, x, h) end
        for y = 0, h, 40 do surface.DrawLine(0, y, w, y) end
        
        -- Bordes Cibernéticos
        surface.SetDrawColor(UI.Blue)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        surface.SetDrawColor(ColorAlpha(UI.Blue, 30))
        surface.DrawRect(0, 0, w, 70)
        surface.DrawRect(0, 68, w, 2)
        -- Título
        draw.SimpleText("GREMIO DE CAZARRECOMPENSAS", FONT_TITLE, 24, 28, UI.Blue, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Red HoloNet de Contratos", FONT_BODY, 24, 50, UI.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        -- Scanline Global Animado
        surface.SetDrawColor(0, 255, 255, 10)
        surface.DrawRect(0, (RealTime() * 150) % h, w, 4)
    end

    -- Botón cerrar
    local btnClose = vgui.Create("DButton", frame)
    btnClose:SetPos(W - 44, 12)
    btnClose:SetSize(32, 32)
    btnClose:SetText("✕")
    btnClose:SetFont(FONT_HEADER)
    btnClose:SetTextColor(UI.Gray)
    btnClose.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox(6, 0, 0, w, h, Color(60, 20, 20))
        end
    end
    btnClose.DoClick = function() frame:Remove() end

    -- ── TABS ────────────────────────────────
    local tabPanel = vgui.Create("DPanel", frame)
    tabPanel:SetPos(10, 72)
    tabPanel:SetSize(W - 20, 45)
    tabPanel.Paint = function(self, w, h)
        -- No background
    end

    local tabs = {}
    local activeTab = "list"

    local contentPanel = vgui.Create("DPanel", frame)
    contentPanel:SetPos(10, 120)
    contentPanel:SetSize(W - 20, H - 130)
    contentPanel.Paint = function() end

    local function SetActiveTab(name)
        activeTab = name
        BountySystem.ActiveTab = name
        for n, btn in pairs(tabs) do
            btn.active = (n == name)
        end
        -- Limpiar contenido
        contentPanel:Clear()
        BountySystem.ContentPanel = contentPanel
        
        if name == "list" then
            BountySystem.BuildListPanel(contentPanel)
        elseif name == "place" then
            BountySystem.BuildPlacePanel(contentPanel)
        elseif name == "profile" then
            BountySystem.BuildProfilePanel(contentPanel)
        elseif name == "admin" then
            net.Start("BountySystem_RequestAdminStats") net.SendToServer()
            BountySystem.BuildAdminPanel(contentPanel)
        end
    end

    local tabDefs = {}
    if IsValid(BountySystem.HireTarget) then
        tabDefs = {
            { name = "place",   label = "Emitir"    },
            { name = "profile", label = "Perfil"    },
        }
    else
        tabDefs = {
            { name = "list",    label = "Contratos" },
            { name = "place",   label = "Emitir"    },
            { name = "profile", label = "Perfil"    },
        }
        if LocalPlayer():IsSuperAdmin() then
            table.insert(tabDefs, { name = "admin", label = "Admin" })
        end
    end

    for i, td in ipairs(tabDefs) do
        local btn = vgui.Create("DButton", tabPanel)
        local tabWidth = (W - 20) / #tabDefs
        btn:SetPos((i - 1) * tabWidth, 0)
        btn:SetSize(tabWidth, 42)
        btn:SetText(td.label)
        btn:SetFont(FONT_BODY)
        btn:SetTextColor(UI.Gray)
        btn.active = (td.name == activeTab)

        btn.Paint = function(self, w, h)
            -- Rework: Top tabs
            if self.active then
                draw.RoundedBoxEx(6, 0, 0, w, h, Color(0, 60, 100, 200), true, true, false, false)
                surface.SetDrawColor(UI.Blue)
                surface.DrawRect(0, h - 3, w, 3)
                self:SetTextColor(UI.White)
            elseif self:IsHovered() then
                draw.RoundedBoxEx(6, 0, 0, w, h, Color(0, 30, 60, 150), true, true, false, false)
                self:SetTextColor(UI.White)
            else
                self:SetTextColor(UI.Gray)
            end
        end

        btn.DoClick = function() SetActiveTab(td.name) end
        tabs[td.name] = btn
    end

    SetActiveTab(IsValid(BountySystem.HireTarget) and "place" or "list")
end

-- ── PANEL: LISTA DE RECOMPENSAS ────────────
function BountySystem.BuildListPanel(parent)
    local W, H = parent:GetWide(), parent:GetTall()
    local me = LocalPlayer()

    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:SetPos(0, 0)
    scroll:SetSize(W, H)

    local sbar = scroll:GetVBar()
    sbar:SetWide(4)
    sbar.Paint = function() end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(self, w, h) draw.RoundedBox(2, 0, 0, w, h, UI.Blue) end

    -- Guardar referencia para refresco
    BountySystem.ActiveScroll = scroll
    local expandedItem = nil

    local function BuildDetails(parent, bounty)
        local detailContainer = vgui.Create("DPanel", parent)
        detailContainer:Dock(FILL)
        detailContainer.Paint = function() end
        detailContainer:Clear()
        if not bounty then return end

        local id = bounty.id
        local targetPly = nil
        for _, p in ipairs(player.GetAll()) do
            local pSteam = p:IsBot() and ("BOT_" .. p:EntIndex()) or p:SteamID()
            if pSteam == bounty.targetSteam then
                targetPly = p
                break
            end
        end

        local mdl = "models/player/kleiner.mdl"
        local jobDisplay = "Desconocido"
        if IsValid(targetPly) then
            mdl = targetPly:GetModel() or mdl
            if RPExtraTeams and RPExtraTeams[targetPly:Team()] and RPExtraTeams[targetPly:Team()].category then
                jobDisplay = RPExtraTeams[targetPly:Team()].category
            end
        end

        -- ── Botones (Cancelar / Aceptar) ──
        local btnPanel = vgui.Create("DPanel", detailContainer)
        btnPanel:Dock(BOTTOM)
        btnPanel:SetTall(50)
        btnPanel.Paint = function() end

        local isOwner = bounty.placerSteam == me:SteamID()
        local isAdmin = me:IsAdmin()
        local isTarget = bounty.targetSteam == me:SteamID()

        if isOwner or isAdmin then
            local btnCancel = vgui.Create("DButton", btnPanel)
            btnCancel:Dock(RIGHT)
            btnCancel:SetWide(100)
            btnCancel:DockMargin(10, 5, 0, 5)
            btnCancel:SetText("CANCELAR")
            btnCancel:SetFont(FONT_BODY)
            btnCancel:SetTextColor(UI.White)
            btnCancel.Paint = function(self, w, h)
                local col = self:IsHovered() and Color(180, 30, 30) or Color(130, 20, 20)
                draw.RoundedBox(0, 0, 0, w, h, col)
                surface.SetDrawColor(UI.Red)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            btnCancel.DoClick = function()
                net.Start("BountySystem_CancelBounty")
                    net.WriteUInt(id, 16)
                net.SendToServer()
                detailContainer:Clear()
            end
        end

        if not isTarget and not isOwner and not bounty.acceptedBy then
            local btnAccept = vgui.Create("DButton", btnPanel)
            btnAccept:Dock(RIGHT)
            btnAccept:SetWide(140)
            btnAccept:DockMargin(10, 5, 0, 5)
            btnAccept:SetText("ACEPTAR CONTRATO")
            btnAccept:SetFont(FONT_HEADER)
            btnAccept:SetTextColor(UI.White)
            btnAccept.Paint = function(self, w, h)
                local col = self:IsHovered() and Color(0, 100, 150, 200) or Color(0, 50, 100, 200)
                draw.RoundedBox(0, 0, 0, w, h, col)
                surface.SetDrawColor(UI.Blue)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            btnAccept.DoClick = function()
                net.Start("BountySystem_AcceptBounty")
                    net.WriteUInt(id, 16)
                net.SendToServer()
            end
        elseif bounty.acceptedBy then
            local lblStatus = vgui.Create("DLabel", btnPanel)
            lblStatus:Dock(RIGHT)
            lblStatus:SetWide(140)
            lblStatus:DockMargin(10, 5, 0, 5)
            lblStatus:SetFont(FONT_HEADER)
            lblStatus:SetContentAlignment(5)
            if bounty.acceptedBy == me:SteamID() then
                lblStatus:SetText("EN CURSO")
                lblStatus:SetTextColor(UI.Blue)
            else
                lblStatus:SetText("OCUPADO")
                lblStatus:SetTextColor(UI.Red)
            end
        end

        -- ── Modelo 3D (Efecto Holograma Datapad) ──
        local mdlPanel = vgui.Create("DModelPanel", detailContainer)
        mdlPanel:Dock(LEFT)
        mdlPanel:SetWide(220)
        mdlPanel:SetModel(mdl)
        if IsValid(targetPly) and IsValid(mdlPanel.Entity) then
            BountySystem.CopyModelData(targetPly, mdlPanel.Entity)
        end
        mdlPanel.StartTime = SysTime()
        
        mdlPanel.LayoutEntity = function(self, ent)
            local progress = math.Clamp((SysTime() - self.StartTime) * 1.5, 0, 1)
            ent:SetModelScale(progress, 0)
            ent:SetAngles(Angle(0, RealTime() * 15, 0))
        end
        
        mdlPanel.PreDrawModel = function(self, ent)
            local flicker = 0.8 + math.sin(RealTime() * 20) * 0.1
            
            -- Primera pasada: Texturas normales, semitransparentes y tintadas de azul/cian
            render.SetBlend(flicker * 0.8)
            render.SetColorModulation(0.3, 0.7, 1)
            render.MaterialOverride(nil)
            ent:DrawModel()
            
            -- Segunda pasada: Brillo interno sólido para dar el efecto de emisión de luz
            render.SetBlend(flicker * 0.2)
            render.SetColorModulation(0, 0.4, 1)
            render.MaterialOverride(matSolid)
            ent:DrawModel()
            
            render.MaterialOverride(nil)
            render.SetBlend(1)
            render.SetColorModulation(1, 1, 1)
            return false
        end
        
        if IsValid(mdlPanel.Entity) then
            local mn, mx = mdlPanel.Entity:GetRenderBounds()
            local size = math.max(math.abs(mn.x) + math.abs(mx.x), math.abs(mn.y) + math.abs(mx.y), math.abs(mn.z) + math.abs(mx.z))
            mdlPanel:SetFOV(45)
            mdlPanel:SetCamPos(Vector(size * 0.9, size * 0.9, size * 0.4))
            mdlPanel:SetLookAt((mn + mx) * 0.5)
            local sequence = mdlPanel.Entity:SelectWeightedSequence(ACT_IDLE)
            mdlPanel.Entity:ResetSequence(sequence)
        end

        -- ── Información de la Presa ──
        local infoPanel = vgui.Create("DPanel", detailContainer)
        infoPanel:Dock(FILL)
        infoPanel.Paint = function() end

        local lblTarget = vgui.Create("DLabel", infoPanel)
        lblTarget:SetPos(10, 10)
        lblTarget:SetSize(300, 30)
        lblTarget:SetFont(FONT_TITLE)
        lblTarget:SetTextColor(UI.Red)
        lblTarget:SetText(bounty.targetName or "Desconocido")

        local lblJob = vgui.Create("DLabel", infoPanel)
        lblJob:SetPos(10, 45)
        lblJob:SetSize(300, 20)
        lblJob:SetFont(FONT_MONO)
        lblJob:SetTextColor(UI.Gray)
        lblJob:SetText("Facción: " .. jobDisplay)

        local lblAmount = vgui.Create("DLabel", infoPanel)
        lblAmount:SetPos(10, 75)
        lblAmount:SetSize(300, 25)
        lblAmount:SetFont(FONT_HEADER)
        lblAmount:SetTextColor(UI.Gold)
        lblAmount:SetText("Recompensa: " .. cfg.CurrencySymbol .. bounty.amount)

        local lblPlacer = vgui.Create("DLabel", infoPanel)
        lblPlacer:SetPos(10, 105)
        lblPlacer:SetSize(300, 20)
        lblPlacer:SetFont(FONT_BODY)
        lblPlacer:SetTextColor(UI.Gray)
        lblPlacer:SetText("Emitido por: " .. (bounty.placerName or "El Sistema HoloNet"))
    end

    local function Populate()
        if not IsValid(scroll) then return end
        
        scroll:Clear()
        local count = 0
        
        for id, b in pairs(BountySystem.LocalBounties) do
            count = count + 1
            local item = scroll:Add("DPanel")
            item:Dock(TOP)
            item:SetTall(60)
            item:DockMargin(0, 0, 0, 5)
            item.Paint = function() end

            local header = vgui.Create("DButton", item)
            header:Dock(TOP)
            header:SetTall(60)
            header:SetText("")

            header.Paint = function(self, w, h)
                local bg = self:IsHovered() and UI.RowHover or UI.Row
                if expandedItem == item then bg = Color(0, 80, 120, 220) end
                draw.RoundedBox(0, 0, 0, w, h, bg)
                
                surface.SetDrawColor(ColorAlpha(UI.Blue, 50))
                surface.DrawOutlinedRect(0, 0, w, h, 1)

                draw.SimpleText(b.targetName or "Desconocido", FONT_HEADER, 10, h/2, UI.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(cfg.CurrencySymbol .. b.amount, FONT_HEADER, w - 150, h/2, UI.Gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                
                if b.acceptedBy then
                    draw.SimpleText("OCUPADO", FONT_MONO, w - 10, h/2, UI.Red, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                else
                    draw.SimpleText("DISPONIBLE", FONT_MONO, w - 10, h/2, UI.Green, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
            end

            local details = vgui.Create("DPanel", item)
            details:Dock(TOP)
            details:SetTall(300)
            details:SetVisible(false)
            details.Paint = function(s,w,h) draw.RoundedBox(0, 0, 0, w, h, Color(0,10,20,200)) end
            BuildDetails(details, b)

            header.DoClick = function()
                if expandedItem == item then
                    item:SizeTo(item:GetWide(), 60, 0.2)
                    details:SetVisible(false)
                    expandedItem = nil
                else
                    if IsValid(expandedItem) then
                        expandedItem:SizeTo(expandedItem:GetWide(), 60, 0.2)
                        expandedItem.Details:SetVisible(false)
                    end
                    item:SizeTo(item:GetWide(), 60 + 300, 0.2)
                    details:SetVisible(true)
                    expandedItem = item
                    item.Details = details
                end
            end
        end

        if count == 0 then
            local empty = vgui.Create("DLabel", scroll)
            empty:SetText("No hay contratos activos en la HoloNet.")
            empty:SetFont(FONT_BODY)
            empty:SetTextColor(UI.Gray)
            empty:SetContentAlignment(5)
            empty:Dock(TOP)
            empty:SetTall(60)
        end
    end

    BountySystem.PopulateBountyList = Populate
    Populate()
end

-- ── PANEL: COLOCAR RECOMPENSA ──────────────
function BountySystem.BuildPlacePanel(parent)
    local W, H = parent:GetWide(), parent:GetTall()

    local topPanel = vgui.Create("DPanel", parent)
    topPanel:SetPos(0,0)
    topPanel:SetSize(W, H - 215)
    topPanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, UI.Panel)
        surface.SetDrawColor(ColorAlpha(UI.Blue, 100))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("SELECCIONAR PRESA", FONT_HEADER, 10, 10, UI.Blue, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.DrawRect(10, 30, w - 20, 1)
    end

    local scroll = vgui.Create("DScrollPanel", topPanel)
    scroll:SetPos(10, 40)
    scroll:SetSize(topPanel:GetWide() - 20, topPanel:GetTall() - 50)
    
    local sbar = scroll:GetVBar()
    sbar:SetWide(4)
    sbar.Paint = function() end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(self, w, h) draw.RoundedBox(2, 0, 0, w, h, UI.Blue) end

    local bottomPanel = vgui.Create("DPanel", parent)
    bottomPanel:SetPos(0, H - 210)
    bottomPanel:SetSize(W, 210)
    bottomPanel:SetVisible(false)
    bottomPanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, UI.Panel)
        surface.SetDrawColor(ColorAlpha(UI.Blue, 100))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("DATOS DEL CONTRATO", FONT_HEADER, 10, 10, UI.Blue, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.DrawRect(10, 30, w - 20, 1)
    end

    local selectedPlayer = nil
    local cfg = BountySystem.Config

    -- Holograma
    local mdlPanel = vgui.Create("DModelPanel", bottomPanel)
    mdlPanel:SetPos(10, 40)
    mdlPanel:SetSize(110, 160)
    mdlPanel:SetModel("models/player/kleiner.mdl")
    mdlPanel.StartTime = SysTime()
    mdlPanel.LayoutEntity = function(self, ent)
        local progress = math.Clamp((SysTime() - self.StartTime) * 1.5, 0, 1)
        ent:SetModelScale(progress, 0)
        ent:SetAngles(Angle(0, RealTime() * 15, 0))
    end
    mdlPanel.PreDrawModel = function(self, ent)
        local flicker = 0.8 + math.sin(RealTime() * 20) * 0.1
        render.SetBlend(flicker * 0.8)
        render.SetColorModulation(0.3, 0.7, 1)
        render.MaterialOverride(nil)
        ent:DrawModel()
        render.SetBlend(flicker * 0.2)
        render.SetColorModulation(0, 0.4, 1)
        render.MaterialOverride(matSolid)
        ent:DrawModel()
        render.MaterialOverride(nil)
        render.SetBlend(1)
        render.SetColorModulation(1, 1, 1)
        return false
    end

    -- Contenedor de datos a la derecha del holograma
    local infoContainer = vgui.Create("DPanel", bottomPanel)
    infoContainer:SetPos(130, 40)
    infoContainer:SetSize(W - 140, 160)
    infoContainer.Paint = function(self, w, h)
        if not IsValid(selectedPlayer) then return end
        draw.SimpleText(selectedPlayer:Nick(), FONT_TITLE, 0, 5, UI.Red, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        local teamDisplay = (RPExtraTeams and RPExtraTeams[selectedPlayer:Team()] and RPExtraTeams[selectedPlayer:Team()].category) or team.GetName(selectedPlayer:Team())
        draw.SimpleText("Facción: " .. teamDisplay, FONT_MONO, 0, 35, UI.Gray, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local lblAmount = vgui.Create("DLabel", infoContainer)
    lblAmount:SetPos(0, 60)
    lblAmount:SetSize(infoContainer:GetWide() - 20, 20)
    lblAmount:SetFont(FONT_BODY)
    lblAmount:SetTextColor(UI.Gray)
    lblAmount:SetText("Importe (" .. (cfg.CurrencySymbol or "$") .. (cfg.MinBounty or 1000) .. " - " .. (cfg.MaxBounty or 100000) .. "):")

    local amountInput = vgui.Create("DTextEntry", infoContainer)
    amountInput:SetPos(0, 80)
    amountInput:SetSize(infoContainer:GetWide() - 20, 30)
    amountInput:SetFont(FONT_BODY)
    amountInput:SetNumeric(true)
    amountInput:SetTextColor(UI.White)
    amountInput:SetCursorColor(UI.White)
    amountInput.Paint = function(self, sw, sh)
        draw.RoundedBox(0, 0, 0, sw, sh, Color(0, 20, 40, 150))
        surface.SetDrawColor(self:HasFocus() and UI.Blue or ColorAlpha(UI.Divider, 50))
        surface.DrawOutlinedRect(0, 0, sw, sh, 1)
        self:DrawTextEntryText(Color(255, 255, 255), UI.Blue, Color(255, 255, 255))
        if self:GetText() == "" and not self:HasFocus() then
            draw.SimpleText("Ej: 5000", FONT_BODY, 8, sh/2, UI.Gray, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    local btnPlace = vgui.Create("DButton", infoContainer)
    btnPlace:SetPos(0, 120)
    btnPlace:SetSize(infoContainer:GetWide() - 20, 30)
    btnPlace:SetText("☠  EMITIR CONTRATO")
    btnPlace:SetFont(FONT_HEADER)
    btnPlace:SetTextColor(UI.White)
    btnPlace.Paint = function(self, w, h)
        local col = self:IsHovered() and Color(0, 100, 150, 200) or Color(0, 50, 100, 200)
        draw.RoundedBox(0, 0, 0, w, h, col)
        surface.SetDrawColor(UI.Blue)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    -- Llenar lista de jugadores
    for _, ply in ipairs(player.GetAll()) do
        if ply == LocalPlayer() then continue end

        -- Ignorar trabajos restringidos
        local jobCmd = ""
        if RPExtraTeams and RPExtraTeams[ply:Team()] then
            jobCmd = RPExtraTeams[ply:Team()].command
        end
        if cfg.RestrictedTargetJobs and cfg.RestrictedTargetJobs[jobCmd] then continue end

        local btn = scroll:Add("DButton")
        btn:Dock(TOP)
        btn:SetTall(46)
        btn:DockMargin(0, 0, 0, 4)
        btn:SetText("")
        btn.Paint = function(self, w, h)
            local bg = self:IsHovered() and UI.RowHover or UI.Row
            if selectedPlayer == ply then bg = Color(0, 80, 120, 220) end
            draw.RoundedBox(0, 0, 0, w, h, bg)
            
            draw.SimpleText(ply:Nick(), FONT_HEADER, 10, h/2 - 8, UI.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local teamColor = team.GetColor(ply:Team())
            local teamDisplay = team.GetName(ply:Team())
            if RPExtraTeams and RPExtraTeams[ply:Team()] and RPExtraTeams[ply:Team()].category then
                teamDisplay = RPExtraTeams[ply:Team()].category
            end
            draw.SimpleText(teamDisplay, FONT_MONO, 10, h/2 + 8, teamColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            if selectedPlayer == ply then
                surface.SetDrawColor(UI.Blue)
                surface.DrawRect(0, 0, 4, h)
                surface.DrawRect(w-4, 0, 4, h)
            end
        end
        btn.DoClick = function()
            selectedPlayer = ply
            bottomPanel:SetVisible(true)
            
            mdlPanel:SetModel(ply:GetModel())
            if IsValid(mdlPanel.Entity) then
                BountySystem.CopyModelData(ply, mdlPanel.Entity)
            end
            mdlPanel.StartTime = SysTime()
            local mn, mx = mdlPanel.Entity:GetRenderBounds()
            local size = math.max(math.abs(mn.x) + math.abs(mx.x), math.abs(mn.y) + math.abs(mx.y), math.abs(mn.z) + math.abs(mx.z))
            mdlPanel:SetFOV(45)
            mdlPanel:SetCamPos(Vector(size * 0.9, size * 0.9, size * 0.4))
            mdlPanel:SetLookAt((mn + mx) * 0.5)
            local sequence = mdlPanel.Entity:SelectWeightedSequence(ACT_IDLE)
            mdlPanel.Entity:ResetSequence(sequence)
        end
    end

    btnPlace.DoClick = function()
        local amount = tonumber(amountInput:GetValue()) or 0

        if not IsValid(selectedPlayer) then
            chat.AddText(UI.Red, "[BountySystem] Selecciona un objetivo válido.")
            return
        end
        if amount < (cfg.MinBounty or 1000) or amount > (cfg.MaxBounty or 100000) then
            chat.AddText(UI.Red, "[BountySystem] Importe inválido.")
            return
        end

        net.Start("BountySystem_PlaceBounty")
            local targetID = selectedPlayer:IsBot() and ("BOT_" .. selectedPlayer:EntIndex()) or selectedPlayer:SteamID()
            net.WriteString(targetID)
            net.WriteUInt(amount, 32)
            net.WriteString("")
            net.WriteString(selectedPlayer:Nick())
        net.SendToServer()

        amountInput:SetValue("")
    end
end

-- ── PANEL: PERFIL ─────────────────────────
function BountySystem.BuildProfilePanel(parent)
    local W, H = parent:GetWide(), parent:GetTall()
    local stats = BountySystem.HireStats or BountySystem.MyStats
    local targetPly = BountySystem.HireTarget or LocalPlayer()
    local maxLevel = BountySystem.Config.MaxLevel or 50
    local xpNeeded = stats.level * 1000

    local bg = vgui.Create("DPanel", parent)
    bg:Dock(FILL)
    
    -- Holograma del Perfil
    local mdlPanel = vgui.Create("DModelPanel", bg)
    mdlPanel:SetPos(W/2 - 100, 110)
    mdlPanel:SetSize(200, 220)
    mdlPanel:SetModel(targetPly:GetModel())
    BountySystem.CopyModelData(targetPly, mdlPanel.Entity)
    mdlPanel.StartTime = SysTime()
    mdlPanel.LayoutEntity = function(self, ent)
        ent:SetAngles(Angle(0, 15, 0)) -- Retrato fijo y serio
    end
    mdlPanel.PreDrawModel = function(self, ent)
        local flicker = 0.8 + math.sin(RealTime() * 20) * 0.1
        render.SetBlend(flicker * 0.8)
        render.SetColorModulation(0.3, 0.7, 1)
        render.MaterialOverride(nil)
        ent:DrawModel()
        render.SetBlend(flicker * 0.2)
        render.SetColorModulation(0, 0.4, 1)
        render.MaterialOverride(matSolid)
        ent:DrawModel()
        render.MaterialOverride(nil)
        render.SetBlend(1)
        render.SetColorModulation(1, 1, 1)
        return false
    end
    if IsValid(mdlPanel.Entity) then
        local mn, mx = mdlPanel.Entity:GetRenderBounds()
        local headZ = mx.z - 6 -- Altura del rostro
        mdlPanel:SetFOV(35)
        mdlPanel:SetCamPos(Vector(25, 5, headZ))
        mdlPanel:SetLookAt(Vector(0, 0, headZ))
        local sequence = mdlPanel.Entity:SelectWeightedSequence(ACT_IDLE)
        mdlPanel.Entity:ResetSequence(sequence)
    end

    bg.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, UI.Panel)
        surface.SetDrawColor(ColorAlpha(UI.Blue, 100))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        draw.SimpleText("EXPEDIENTE DEL CAZADOR", FONT_TITLE, w/2, 40, UI.Blue, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Agente: " .. targetPly:Nick(), FONT_HEADER, w/2, 70, UI.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Nivel y Prestigio
        draw.SimpleText("Nivel " .. stats.level, FONT_TITLE, w/2, 350, UI.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if stats.prestige > 0 then
            draw.SimpleText("Prestigio " .. stats.prestige, FONT_TITLE, w/2, 390, UI.Gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        -- Barra XP
        local barW, barH = 400, 30
        local barX, barY = w/2 - barW/2, 440
        draw.RoundedBox(0, barX, barY, barW, barH, Color(0, 20, 40, 200))
        surface.SetDrawColor(UI.Blue)
        surface.DrawOutlinedRect(barX, barY, barW, barH, 1)
        
        local xpFill = math.Clamp(stats.xp / xpNeeded, 0, 1)
        draw.RoundedBox(0, barX + 2, barY + 2, (barW - 4) * xpFill, barH - 4, Color(0, 150, 255, 150))
        draw.SimpleText("XP: " .. stats.xp .. " / " .. xpNeeded, FONT_MONO, w/2, barY + barH/2, UI.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Estadísticas
        draw.SimpleText("Contratos Ejecutados: " .. stats.kills, FONT_TITLE, w/2, 510, UI.Red, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        local multi = stats.prestige * ((BountySystem.Config.PrestigeMultiplier or 0.20) * 100)
        draw.SimpleText("Bono de Pagos: +" .. multi .. "%", FONT_HEADER, w/2, 540, UI.Green, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    if not IsValid(BountySystem.HireTarget) and stats.level >= maxLevel then
        local btnPrestige = vgui.Create("DButton", bg)
        btnPrestige:SetSize(240, 50)
        btnPrestige:SetPos(W/2 - 120, 580)
        btnPrestige:SetText("ASCENDER A PRESTIGIO")
        btnPrestige:SetFont(FONT_HEADER)
        btnPrestige:SetTextColor(UI.White)
        btnPrestige.Paint = function(self, w, h)
            local col = self:IsHovered() and Color(200, 150, 0, 200) or Color(150, 100, 0, 200)
            draw.RoundedBox(0, 0, 0, w, h, col)
            surface.SetDrawColor(UI.Gold)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        btnPrestige.DoClick = function()
            net.Start("BountySystem_Prestige")
            net.SendToServer()
        end
    end
end

-- ── PANEL: ADMIN (Solo Datapad F3) ────────
function BountySystem.BuildAdminPanel(parent)
    local W, H = parent:GetWide(), parent:GetTall()

    local topPanel = vgui.Create("DPanel", parent)
    topPanel:SetPos(0,0)
    topPanel:SetSize(W, H - 250)
    topPanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, UI.Panel)
        surface.SetDrawColor(ColorAlpha(UI.Red, 100))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("ADMINISTRACIÓN DE AGENTES", FONT_HEADER, 10, 10, UI.Red, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.DrawRect(10, 30, w - 20, 1)
    end

    local scroll = vgui.Create("DScrollPanel", topPanel)
    scroll:SetPos(10, 40)
    scroll:SetSize(topPanel:GetWide() - 20, topPanel:GetTall() - 50)
    
    local sbar = scroll:GetVBar()
    sbar:SetWide(4)
    sbar.Paint = function() end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(self, w, h) draw.RoundedBox(2, 0, 0, w, h, UI.Red) end

    local bottomPanel = vgui.Create("DPanel", parent)
    bottomPanel:SetPos(0, H - 245)
    bottomPanel:SetSize(W, 245)
    bottomPanel:SetVisible(false)
    bottomPanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, UI.Panel)
        surface.SetDrawColor(ColorAlpha(UI.Red, 100))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("GESTIÓN DE ESTADÍSTICAS", FONT_HEADER, 10, 10, UI.Red, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.DrawRect(10, 30, w - 20, 1)
    end

    local selectedPlayer = nil
    local selectedLabel = vgui.Create("DLabel", bottomPanel)
    selectedLabel:SetPos(10, 40)
    selectedLabel:SetSize(bottomPanel:GetWide() - 20, 30)
    selectedLabel:SetFont(FONT_TITLE)
    selectedLabel:SetTextColor(UI.White)
    selectedLabel:SetText("Nadie seleccionado")

    local lblStats = vgui.Create("DLabel", bottomPanel)
    lblStats:SetPos(10, 75)
    lblStats:SetSize(bottomPanel:GetWide() - 20, 20)
    lblStats:SetFont(FONT_MONO)
    lblStats:SetTextColor(UI.Gray)
    lblStats:SetText("Cargando...")

    local function SendAdminAction(action, amount)
        if not IsValid(selectedPlayer) then return end
        local targetID = selectedPlayer:IsBot() and ("BOT_" .. selectedPlayer:EntIndex()) or selectedPlayer:SteamID()
        net.Start("BountySystem_AdminAction")
        net.WriteString(action)
        net.WriteString(targetID)
        net.WriteInt(amount or 0, 32)
        net.SendToServer()
    end

    local btnXP = vgui.Create("DButton", bottomPanel)
    btnXP:SetPos(10, 120)
    btnXP:SetSize(120, 35)
    btnXP:SetText("+ 1000 XP")
    btnXP:SetFont(FONT_HEADER)
    btnXP:SetTextColor(UI.White)
    btnXP.Paint = function(s,w,h) 
        draw.RoundedBox(0,0,0,w,h,s:IsHovered() and Color(0,150,0) or Color(0,100,0)) 
        surface.SetDrawColor(UI.Green) surface.DrawOutlinedRect(0,0,w,h,1)
    end
    btnXP.DoClick = function() SendAdminAction("add_xp", 1000) end

    local btnLevel = vgui.Create("DButton", bottomPanel)
    btnLevel:SetPos(140, 120)
    btnLevel:SetSize(120, 35)
    btnLevel:SetText("SET NIVEL")
    btnLevel:SetFont(FONT_HEADER)
    btnLevel:SetTextColor(UI.White)
    btnLevel.Paint = function(s,w,h) 
        draw.RoundedBox(0,0,0,w,h,s:IsHovered() and Color(0,150,200) or Color(0,100,150))
        surface.SetDrawColor(UI.Blue) surface.DrawOutlinedRect(0,0,w,h,1)
    end
    btnLevel.DoClick = function()
        Derma_StringRequest("Setear Nivel", "Introduce el nuevo nivel (1-X):", "", function(text)
            local num = tonumber(text)
            if num then SendAdminAction("set_level", num) end
        end)
    end

    local btnPrestige = vgui.Create("DButton", bottomPanel)
    btnPrestige:SetPos(270, 120)
    btnPrestige:SetSize(120, 35)
    btnPrestige:SetText("SET PRESTIGIO")
    btnPrestige:SetFont(FONT_HEADER)
    btnPrestige:SetTextColor(UI.White)
    btnPrestige.Paint = function(s,w,h) 
        draw.RoundedBox(0,0,0,w,h,s:IsHovered() and Color(200,150,0) or Color(150,100,0))
        surface.SetDrawColor(UI.Gold) surface.DrawOutlinedRect(0,0,w,h,1)
    end
    btnPrestige.DoClick = function()
        Derma_StringRequest("Setear Prestigio", "Introduce el nuevo prestigio:", "", function(text)
            local num = tonumber(text)
            if num then SendAdminAction("set_prestige", num) end
        end)
    end

    local btnReset = vgui.Create("DButton", bottomPanel)
    btnReset:SetPos(400, 120)
    btnReset:SetSize(120, 35)
    btnReset:SetText("BORRAR TODO")
    btnReset:SetFont(FONT_HEADER)
    btnReset:SetTextColor(UI.White)
    btnReset.Paint = function(s,w,h) 
        draw.RoundedBox(0,0,0,w,h,s:IsHovered() and Color(200,0,0) or Color(150,0,0))
        surface.SetDrawColor(UI.Red) surface.DrawOutlinedRect(0,0,w,h,1)
    end
    btnReset.DoClick = function()
        Derma_Query("¿Estás seguro de que quieres borrar TODAS las estadísticas de este jugador?", "Confirmar Borrado", 
            "Sí, borrar", function() SendAdminAction("reset", 0) end, 
            "Cancelar", function() end)
    end

    local function RefreshStatsDisplay()
        if not IsValid(selectedPlayer) then return end
        local targetID = selectedPlayer:IsBot() and ("BOT_" .. selectedPlayer:EntIndex()) or selectedPlayer:SteamID()
        local pStats = BountySystem.AllStats and BountySystem.AllStats[targetID] or {level=1, xp=0, prestige=0, kills=0}
        lblStats:SetText("Nivel: " .. pStats.level .. "  |  Prestigio: " .. pStats.prestige .. "  |  XP: " .. pStats.xp .. "  |  Bajas: " .. pStats.kills)
    end

    bottomPanel.Think = function()
        if IsValid(selectedPlayer) then RefreshStatsDisplay() end
    end

    for _, ply in ipairs(player.GetAll()) do
        local btn = scroll:Add("DButton")
        btn:Dock(TOP)
        btn:SetTall(46)
        btn:DockMargin(0, 0, 0, 4)
        btn:SetText("")
        btn.Paint = function(self, w, h)
            local bg = self:IsHovered() and Color(40, 20, 20, 200) or UI.Row
            if selectedPlayer == ply then bg = Color(80, 0, 0, 220) end
            draw.RoundedBox(0, 0, 0, w, h, bg)
            
            draw.SimpleText(ply:Nick(), FONT_HEADER, 10, h/2 - 8, UI.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            local tID = ply:IsBot() and ("BOT_" .. ply:EntIndex()) or ply:SteamID()
            local pStats = BountySystem.AllStats and BountySystem.AllStats[tID] or {level=1, prestige=0}
            draw.SimpleText("Nivel " .. pStats.level .. " | Prestigio " .. pStats.prestige, FONT_MONO, 10, h/2 + 8, UI.Gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            if selectedPlayer == ply then
                surface.SetDrawColor(UI.Red)
                surface.DrawRect(0, 0, 4, h)
                surface.DrawRect(w-4, 0, 4, h)
            end
        end
        btn.DoClick = function()
            selectedPlayer = ply
            bottomPanel:SetVisible(true)
            selectedLabel:SetText(ply:Nick())
            RefreshStatsDisplay()
        end
    end
end

-- ── PANEL: ADMIN ─────────────────────────
function BountySystem.BuildAdminPanel(parent)
    local W, H = parent:GetWide(), parent:GetTall()

    -- Popups Holográficos Personalizados
    local function HoloInputRequest(title, prompt, callback)
        local f = vgui.Create("DFrame")
        f:SetSize(450, 200)
        f:Center()
        f:MakePopup()
        f:SetTitle("")
        f:ShowCloseButton(false)
        f.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(5, 15, 25, 240))
            surface.SetDrawColor(UI.Blue)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            draw.SimpleText(title, FONT_TITLE, w/2, 20, UI.Blue, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            draw.SimpleText(prompt, FONT_BODY, w/2, 60, UI.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end

        local txt = vgui.Create("DTextEntry", f)
        txt:SetPos(40, 90)
        txt:SetSize(370, 35)
        txt:SetFont(FONT_HEADER)
        txt:SetNumeric(true)
        txt:SetTextColor(UI.White)
        txt:SetCursorColor(UI.White)
        txt.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 20, 40, 150))
            surface.SetDrawColor(self:HasFocus() and UI.Blue or ColorAlpha(UI.Divider, 50))
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            self:DrawTextEntryText(UI.White, UI.Blue, UI.White)
        end
        txt:RequestFocus()

        local btnOk = vgui.Create("DButton", f)
        btnOk:SetPos(40, 140)
        btnOk:SetSize(175, 40)
        btnOk:SetText("CONFIRMAR")
        btnOk:SetFont(FONT_HEADER)
        btnOk:SetTextColor(UI.White)
        btnOk.Paint = function(s, w, h)
            draw.RoundedBox(0, 0, 0, w, h, s:IsHovered() and Color(0, 100, 150, 200) or Color(0, 50, 100, 200))
            surface.SetDrawColor(UI.Blue)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        btnOk.DoClick = function()
            if txt:GetValue() ~= "" then callback(txt:GetValue()) end
            f:Remove()
        end

        local btnCancel = vgui.Create("DButton", f)
        btnCancel:SetPos(235, 140)
        btnCancel:SetSize(175, 40)
        btnCancel:SetText("CANCELAR")
        btnCancel:SetFont(FONT_HEADER)
        btnCancel:SetTextColor(UI.White)
        btnCancel.Paint = function(s, w, h)
            draw.RoundedBox(0, 0, 0, w, h, s:IsHovered() and Color(150, 0, 0, 200) or Color(100, 0, 0, 200))
            surface.SetDrawColor(UI.Red)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        btnCancel.DoClick = function() f:Remove() end
    end

    local function HoloQuery(title, prompt, confirmTxt, onConfirm)
        local f = vgui.Create("DFrame")
        f:SetSize(450, 200)
        f:Center()
        f:MakePopup()
        f:SetTitle("")
        f:ShowCloseButton(false)
        f.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(25, 5, 5, 240))
            surface.SetDrawColor(UI.Red)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            draw.SimpleText(title, FONT_TITLE, w/2, 30, UI.Red, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            draw.SimpleText(prompt, FONT_BODY, w/2, 80, UI.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end

        local btnOk = vgui.Create("DButton", f)
        btnOk:SetPos(40, 140)
        btnOk:SetSize(175, 40)
        btnOk:SetText(confirmTxt)
        btnOk:SetFont(FONT_HEADER)
        btnOk:SetTextColor(UI.White)
        btnOk.Paint = function(s, w, h)
            draw.RoundedBox(0, 0, 0, w, h, s:IsHovered() and Color(150, 0, 0, 200) or Color(100, 0, 0, 200))
            surface.SetDrawColor(UI.Red)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        btnOk.DoClick = function()
            if onConfirm then onConfirm() end
            f:Remove()
        end

        local btnCancel = vgui.Create("DButton", f)
        btnCancel:SetPos(235, 140)
        btnCancel:SetSize(175, 40)
        btnCancel:SetText("CANCELAR")
        btnCancel:SetFont(FONT_HEADER)
        btnCancel:SetTextColor(UI.White)
        btnCancel.Paint = function(s, w, h)
            draw.RoundedBox(0, 0, 0, w, h, s:IsHovered() and Color(50, 50, 50, 200) or Color(30, 30, 30, 200))
            surface.SetDrawColor(UI.Gray)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        btnCancel.DoClick = function() f:Remove() end
    end

    local topPanel = vgui.Create("DPanel", parent)
    topPanel:SetPos(0,0)
    topPanel:SetSize(W, H - 250)
    topPanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, UI.Panel)
        surface.SetDrawColor(ColorAlpha(UI.Red, 100))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("ADMINISTRACIÓN DE AGENTES", FONT_HEADER, 10, 10, UI.Red, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.DrawRect(10, 30, w - 20, 1)
    end

    local searchBar = vgui.Create("DTextEntry", topPanel)
    searchBar:SetPos(10, 40)
    searchBar:SetSize(topPanel:GetWide() - 170, 35)
    searchBar:SetFont(FONT_BODY)
    searchBar:SetTextColor(UI.White)
    searchBar:SetCursorColor(UI.White)
    searchBar.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 20, 40, 150))
        surface.SetDrawColor(self:HasFocus() and UI.Red or ColorAlpha(UI.Divider, 50))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        self:DrawTextEntryText(UI.White, UI.Red, UI.White)
        if self:GetText() == "" and not self:HasFocus() then
            draw.SimpleText("Buscar por Nombre, SteamID o SteamID64...", FONT_BODY, 10, h/2, UI.Gray, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    local btnResetAll = vgui.Create("DButton", topPanel)
    btnResetAll:SetPos(topPanel:GetWide() - 150, 40)
    btnResetAll:SetSize(140, 35)
    btnResetAll:SetText("WIPE GLOBAL")
    btnResetAll:SetFont(FONT_HEADER)
    btnResetAll:SetTextColor(UI.White)
    btnResetAll.Paint = function(s,w,h) 
        draw.RoundedBox(0,0,0,w,h,s:IsHovered() and Color(200,0,0) or Color(150,0,0))
        surface.SetDrawColor(UI.Red) surface.DrawOutlinedRect(0,0,w,h,1)
    end
    btnResetAll.DoClick = function()
        HoloQuery("WIPE GLOBAL", "¿Borrar TODAS las estadísticas del SERVIDOR?", "SÍ, BORRAR TODO", function() 
            net.Start("BountySystem_AdminAction")
            net.WriteString("reset_all")
            net.WriteString("")
            net.WriteInt(0, 32)
            net.SendToServer()
        end)
    end

    local scroll = vgui.Create("DScrollPanel", topPanel)
    scroll:SetPos(10, 85)
    scroll:SetSize(topPanel:GetWide() - 20, topPanel:GetTall() - 95)
    
    local sbar = scroll:GetVBar()
    sbar:SetWide(4)
    sbar.Paint = function() end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(self, w, h) draw.RoundedBox(2, 0, 0, w, h, UI.Red) end

    local bottomPanel = vgui.Create("DPanel", parent)
    bottomPanel:SetPos(0, H - 245)
    bottomPanel:SetSize(W, 245)
    bottomPanel:SetVisible(false)
    bottomPanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, UI.Panel)
        surface.SetDrawColor(ColorAlpha(UI.Red, 100))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("GESTIÓN DE ESTADÍSTICAS", FONT_HEADER, 10, 10, UI.Red, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.DrawRect(10, 30, w - 20, 1)
    end

    local selectedPlayer = nil
    local selectedLabel = vgui.Create("DLabel", bottomPanel)
    selectedLabel:SetPos(10, 40)
    selectedLabel:SetSize(bottomPanel:GetWide() - 20, 30)
    selectedLabel:SetFont(FONT_TITLE)
    selectedLabel:SetTextColor(UI.White)
    selectedLabel:SetText("Nadie seleccionado")

    local lblStats = vgui.Create("DLabel", bottomPanel)
    lblStats:SetPos(10, 75)
    lblStats:SetSize(bottomPanel:GetWide() - 20, 20)
    lblStats:SetFont(FONT_MONO)
    lblStats:SetTextColor(UI.Gray)
    lblStats:SetText("Cargando...")

    local function SendAdminAction(action, amount)
        if not IsValid(selectedPlayer) then return end
        local targetID = selectedPlayer:IsBot() and ("BOT_" .. selectedPlayer:EntIndex()) or selectedPlayer:SteamID()
        net.Start("BountySystem_AdminAction")
        net.WriteString(action)
        net.WriteString(targetID)
        net.WriteInt(amount or 0, 32)
        net.SendToServer()
    end

    local btnXP = vgui.Create("DButton", bottomPanel)
    btnXP:SetPos(10, 120)
    btnXP:SetSize(120, 35)
    btnXP:SetText("+ 1000 XP")
    btnXP:SetFont(FONT_HEADER)
    btnXP:SetTextColor(UI.White)
    btnXP.Paint = function(s,w,h) 
        draw.RoundedBox(0,0,0,w,h,s:IsHovered() and Color(0,150,0) or Color(0,100,0)) 
        surface.SetDrawColor(UI.Green) surface.DrawOutlinedRect(0,0,w,h,1)
    end
    btnXP.DoClick = function() SendAdminAction("add_xp", 1000) end

    local btnLevel = vgui.Create("DButton", bottomPanel)
    btnLevel:SetPos(140, 120)
    btnLevel:SetSize(120, 35)
    btnLevel:SetText("SET NIVEL")
    btnLevel:SetFont(FONT_HEADER)
    btnLevel:SetTextColor(UI.White)
    btnLevel.Paint = function(s,w,h) 
        draw.RoundedBox(0,0,0,w,h,s:IsHovered() and Color(0,150,200) or Color(0,100,150))
        surface.SetDrawColor(UI.Blue) surface.DrawOutlinedRect(0,0,w,h,1)
    end
    btnLevel.DoClick = function()
        HoloInputRequest("SETEAR NIVEL", "Introduce el nuevo nivel (1-" .. (BountySystem.Config.MaxLevel or 50) .. "):", function(text)
            local num = tonumber(text)
            if num then SendAdminAction("set_level", num) end
        end)
    end

    local btnPrestige = vgui.Create("DButton", bottomPanel)
    btnPrestige:SetPos(270, 120)
    btnPrestige:SetSize(120, 35)
    btnPrestige:SetText("SET PRESTIGIO")
    btnPrestige:SetFont(FONT_HEADER)
    btnPrestige:SetTextColor(UI.White)
    btnPrestige.Paint = function(s,w,h) 
        draw.RoundedBox(0,0,0,w,h,s:IsHovered() and Color(200,150,0) or Color(150,100,0))
        surface.SetDrawColor(UI.Gold) surface.DrawOutlinedRect(0,0,w,h,1)
    end
    btnPrestige.DoClick = function()
        HoloInputRequest("SETEAR PRESTIGIO", "Introduce el nuevo nivel de prestigio:", function(text)
            local num = tonumber(text)
            if num then SendAdminAction("set_prestige", num) end
        end)
    end

    local btnReset = vgui.Create("DButton", bottomPanel)
    btnReset:SetPos(400, 120)
    btnReset:SetSize(120, 35)
    btnReset:SetText("BORRAR TODO")
    btnReset:SetFont(FONT_HEADER)
    btnReset:SetTextColor(UI.White)
    btnReset.Paint = function(s,w,h) 
        draw.RoundedBox(0,0,0,w,h,s:IsHovered() and Color(200,0,0) or Color(150,0,0))
        surface.SetDrawColor(UI.Red) surface.DrawOutlinedRect(0,0,w,h,1)
    end
    btnReset.DoClick = function()
        HoloQuery("CONFIRMAR BORRADO", "¿Borrar TODAS las estadísticas del jugador?", "SÍ, BORRAR", function() 
            SendAdminAction("reset", 0) 
        end)
    end

    local function RefreshStatsDisplay()
        if not IsValid(selectedPlayer) then return end
        local targetID = selectedPlayer:IsBot() and ("BOT_" .. selectedPlayer:EntIndex()) or selectedPlayer:SteamID()
        local pStats = BountySystem.AllStats and BountySystem.AllStats[targetID] or {level=1, xp=0, prestige=0, kills=0}
        lblStats:SetText("Nivel: " .. pStats.level .. "  |  Prestigio: " .. pStats.prestige .. "  |  XP: " .. pStats.xp .. "  |  Bajas: " .. pStats.kills)
    end

    bottomPanel.Think = function()
        if IsValid(selectedPlayer) then RefreshStatsDisplay() end
    end

    local function PopulatePlayers(filter)
        scroll:Clear()
        filter = filter and string.lower(filter) or ""

        for _, ply in ipairs(player.GetAll()) do
            local name = string.lower(ply:Nick())
            local sid = string.lower(ply:SteamID())
            local sid64 = string.lower(ply:SteamID64() or "")

            -- Comprobar si el texto introducido coincide con el Nombre o alguna de las SteamIDs (Búsqueda "Plain Text")
            if filter ~= "" and not (string.find(name, filter, 1, true) or string.find(sid, filter, 1, true) or string.find(sid64, filter, 1, true)) then
                continue
            end

            local btn = scroll:Add("DButton")
            btn:Dock(TOP)
            btn:SetTall(46)
            btn:DockMargin(0, 0, 0, 4)
            btn:SetText("")
            btn.Paint = function(self, w, h)
                local bg = self:IsHovered() and Color(40, 20, 20, 200) or UI.Row
                if selectedPlayer == ply then bg = Color(80, 0, 0, 220) end
                draw.RoundedBox(0, 0, 0, w, h, bg)
                
                draw.SimpleText(ply:Nick(), FONT_HEADER, 10, h/2 - 8, UI.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                
                local tID = ply:IsBot() and ("BOT_" .. ply:EntIndex()) or ply:SteamID()
                local pStats = BountySystem.AllStats and BountySystem.AllStats[tID] or {level=1, prestige=0}
                draw.SimpleText("Nivel " .. pStats.level .. " | Prestigio " .. pStats.prestige, FONT_MONO, 10, h/2 + 8, UI.Gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                
                if selectedPlayer == ply then
                    surface.SetDrawColor(UI.Red)
                    surface.DrawRect(0, 0, 4, h)
                    surface.DrawRect(w-4, 0, 4, h)
                end
            end
            btn.DoClick = function()
                selectedPlayer = ply
                bottomPanel:SetVisible(true)
                selectedLabel:SetText(ply:Nick())
                RefreshStatsDisplay()
            end
        end
    end

    searchBar.OnChange = function(self)
        PopulatePlayers(self:GetValue())
    end

    PopulatePlayers()
end

-- ========================================================
--  SISTEMA 2: TERMINAL 3D CINEMÁTICA (Realidad Aumentada)
-- ========================================================
function BountySystem.OpenTerminal(ent)
    if IsValid(BountySystem.TermFrame) then return end

    net.Start("BountySystem_RequestList") net.SendToServer()

    BountySystem.TermTab = "list"
    BountySystem.TermSelected = nil
    BountySystem.TermPage = 1
    BountySystem.TermAmount = BountySystem.Config.MinBounty
    BountySystem.HoloScale = 0

    -- Iniciar modelo de proyección 3D
    if IsValid(BountySystem.HoloModel) then BountySystem.HoloModel:Remove() end
    BountySystem.HoloModel = ClientsideModel("models/player/kleiner.mdl")
    BountySystem.HoloModel:SetNoDraw(true)

    -- Crear un Frame invisible a pantalla completa para capturar ratón y eventos
    local frame = vgui.Create("DFrame")
    BountySystem.TermFrame = frame
    frame:SetSize(ScrW(), ScrH())
    frame:MakePopup()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    
    local isPressed = false
    frame.OnMousePressed = function(self, key)
        if key == MOUSE_LEFT then isPressed = true end
        if key == MOUSE_RIGHT then frame:Remove() end
    end

    frame.Paint = function(self, w, h)
        if not IsValid(ent) or not LocalPlayer():Alive() then self:Remove() return end
        -- Efecto sutil en la pantalla completa (scanlines ligeros)
        surface.SetDrawColor(0, 200, 255, 3)
        surface.DrawRect(0, (RealTime() * 150) % h, w, 8)
        -- Puntero para ayudar a apuntar en 3D
        surface.SetDrawColor(0, 255, 255, 100)
        surface.DrawRect(w/2 - 2, h/2 - 2, 4, 4)
        draw.SimpleText("[ CLICK DERECHO PARA DESCONECTAR ]", "BountySystem_Header", w/2, h - 50, UI.Red, 1, 1)
    end

    frame.OnRemove = function()
        hook.Remove("CalcView", "BountyTermCam")
        hook.Remove("PostDrawTranslucentRenderables", "BountyTermHolo")
        hook.Remove("PreDrawViewModel", "BountyTermHideVM")
        if IsValid(BountySystem.HoloModel) then BountySystem.HoloModel:Remove() end
    end

    -- ── CÁMARA (Secuestro Cinematográfico)
    hook.Add("CalcView", "BountyTermCam", function(ply, pos, angles, fov)
        if not IsValid(ent) then return end
        local view = {}
        
        -- [CONFIGURACIÓN DE CÁMARA] Ajusta estos números si quieres mover la vista
        local camOffsetForward = 100
        local camOffsetUp = 60
        
        view.origin = ent:GetPos() + ent:GetForward() * camOffsetForward + ent:GetUp() * camOffsetUp
        
        -- Mirar al centro del menú
        view.angles = (ent:GetPos() + ent:GetUp() * 55 - view.origin):Angle()
        view.fov = fov
        view.drawviewer = false -- Oculta tu modelo de jugador de la vista de la cámara
        BountySystem.TermCamPos = view.origin
        return view
    end)

    -- Ocultar el arma que llevas en la mano (viewmodel)
    hook.Add("PreDrawViewModel", "BountyTermHideVM", function()
        return true
    end)

    -- ── RENDER 3D (Holograma Físico y Menú 3D2D)
    hook.Add("PostDrawTranslucentRenderables", "BountyTermHolo", function()
        if not IsValid(ent) then return end

        -- [CONFIGURACIÓN DEL HOLOGRAMA Y MENÚ] Ajustes para "mitad y mitad"
        local holoOffsetForward = 45
        local holoOffsetRight = 18   -- ANTES: 35 | AHORA: 18 (Acerca el holograma al centro-izquierdo)
        local menuOffsetForward = 35 -- ANTES: 30 | AHORA: 35 (Aleja el menú un poco para mejor lectura)
        local menuOffsetRight = -30  -- ANTES: -20 | AHORA: -30 (Mueve el menú un poco más a la derecha)
        local menuOffsetUp = 65      -- ANTES: 70 | AHORA: 65 (Baja el menú para alinearlo mejor con el modelo)
        local menuTilt = -10         -- ANTES: -15 | AHORA: -10 (Lo hace un poco más vertical)

        -- El holograma aparece entre la cámara y la consola (en el suelo)
        local holoPos = ent:GetPos() + ent:GetForward() * holoOffsetForward + ent:GetRight() * holoOffsetRight + ent:GetUp() * 5
        
        -- Dibujar el holograma
        if (BountySystem.TermSelected or BountySystem.TermTab == "profile") and IsValid(BountySystem.HoloModel) then
            BountySystem.HoloScale = math.Approach(BountySystem.HoloScale, 1, FrameTime() * 3)
            BountySystem.HoloModel:SetPos(holoPos + Vector(0, 0, 5))
            BountySystem.HoloModel:SetAngles(Angle(0, RealTime() * 15, 0))
            
            -- Animar el modelo
            BountySystem.HoloModel:FrameAdvance(FrameTime())
            
            local mat = Matrix()
            mat:Scale(Vector(BountySystem.HoloScale, BountySystem.HoloScale, BountySystem.HoloScale))
            BountySystem.HoloModel:EnableMatrix("RenderMultiply", mat)
            
            local flicker = 0.8 + math.sin(RealTime() * 20) * 0.1
            
            -- Primera pasada: Texturas normales
            render.SetBlend(flicker * 0.8)
            render.SetColorModulation(0.3, 0.7, 1)
            render.MaterialOverride(nil)
            BountySystem.HoloModel:DrawModel()
            
            -- Segunda pasada: Brillo base
            render.SetBlend(flicker * 0.2)
            render.SetColorModulation(0, 0.4, 1)
            render.MaterialOverride(matSolid)
            BountySystem.HoloModel:DrawModel()
            
            render.MaterialOverride(nil)
            render.SetBlend(1)
            render.SetColorModulation(1, 1, 1)
            
            -- Proyector de luz base
            render.SetMaterial(matGlow)
            render.DrawSprite(holoPos, 60, 60, Color(0, 200, 255, 150))
        end

        -- ── MATEMÁTICA INTERACTIVA 3D2D
        local mx, my = gui.MousePos()
        local dir = gui.ScreenToVector(mx, my)
        
        -- Usar la posición exacta de la cámara para que el puntero sea 100% preciso
        local camPos = BountySystem.TermCamPos or (ent:GetPos() + ent:GetForward() * 100 + ent:GetUp() * 60)
        
        -- El panel 3D2D flota justo sobre la terminal
        local menuPos = ent:GetPos() + ent:GetUp() * menuOffsetUp + ent:GetForward() * menuOffsetForward + ent:GetRight() * menuOffsetRight
        local menuAng = ent:GetAngles()
        
        -- NUEVO: Gira el menú levemente hacia el centro para un efecto envolvente (hacia el jugador)
        menuAng:RotateAroundAxis(menuAng:Up(), -12) 
        
        menuAng:RotateAroundAxis(menuAng:Right(), menuTilt)
        -- Alinear formato estándar de cam.Start3D2D (X Derecha, Y Abajo)
        menuAng:RotateAroundAxis(menuAng:Up(), 90)
        menuAng:RotateAroundAxis(menuAng:Forward(), 90)
        local scale = 0.05
        local menuW, menuH = 800, 720
        
        -- Corrección de desfase: Desplazamos el origen a la esquina superior izquierda
        menuPos = menuPos - menuAng:Forward() * (menuW / 2 * scale)
        menuPos = menuPos - menuAng:Right() * (menuH / 2 * scale)

        -- Raycast para ver dónde apunta el ratón en la pantalla 3D
        local cx, cy = -1, -1
        if dir then
            local hit = util.IntersectRayWithPlane(camPos, dir, menuPos, menuAng:Up())
            if hit then
                local diff = hit - menuPos
                cx = diff:Dot(menuAng:Forward()) / scale
                cy = diff:Dot(menuAng:Right()) / scale
            end
        end

        -- Lógica de dibujo de botones 3D2D
        local function DrawBtn(x, y, w, h, text, col, active, subtext)
            local hover = (cx >= x and cx <= x+w and cy >= y and cy <= y+h)
            if hover then
                surface.SetDrawColor(col.r, col.g, col.b, 150)
                surface.DrawRect(x, y, w, h)
                if isPressed then 
                    isPressed = false -- Consumir el click para no activar múltiples botones
                    surface.PlaySound("UI/buttonclick.wav")
                    return true 
                end
            elseif active then
                surface.SetDrawColor(col.r, col.g, col.b, 80)
                surface.DrawRect(x, y, w, h)
            else
                surface.SetDrawColor(0, 20, 40, 220)
                surface.DrawRect(x, y, w, h)
            end
            surface.SetDrawColor(col)
            surface.DrawOutlinedRect(x, y, w, h, 3)
            if subtext then
                draw.SimpleText(text, "BountySystem_Title", x + w/2, y + h/2 - 16, color_white, 1, 1)
                draw.SimpleText(subtext, "BountySystem_Title", x + w/2, y + h/2 + 16, Color(150, 200, 255), 1, 1)
            else
                draw.SimpleText(text, "BountySystem_Title", x + w/2, y + h/2, color_white, 1, 1)
            end
            return false
        end

        -- ── DIBUJAR MENÚ 3D2D
        cam.Start3D2D(menuPos, menuAng, scale)
            surface.SetDrawColor(0, 10, 20, 240)
            surface.DrawRect(0, 0, 800, 720)
            surface.SetDrawColor(UI.Blue)
            surface.DrawOutlinedRect(0, 0, 800, 720, 4)
            
            -- Scanlines del menú
            surface.SetDrawColor(0, 200, 255, 15)
            for i = 0, 720, 10 do surface.DrawRect(0, i, 800, 2) end
            
            -- TABS
            local myJobCmd = RPExtraTeams and RPExtraTeams[LocalPlayer():Team()] and RPExtraTeams[LocalPlayer():Team()].command or ""
            local isHunter = BountySystem.Config.BountyHunterJobs and BountySystem.Config.BountyHunterJobs[myJobCmd]
            local btnW = isHunter and 370 or 240
            
            if DrawBtn(20, 20, btnW, 60, "CONTRATOS", UI.Blue, BountySystem.TermTab == "list") then
                BountySystem.TermTab = "list"
                BountySystem.TermSelected = nil
                BountySystem.TermPage = 1
            end
            if not isHunter then
                if DrawBtn(280, 20, btnW, 60, "EMITIR", UI.Red, BountySystem.TermTab == "place") then
                    BountySystem.TermTab = "place"
                    BountySystem.TermSelected = nil
                    BountySystem.TermPage = 1
                end
            end
            local profX = isHunter and 410 or 540
            if DrawBtn(profX, 20, btnW, 60, "PERFIL", UI.Green, BountySystem.TermTab == "profile") then
                BountySystem.TermTab = "profile"
                BountySystem.TermSelected = nil
                BountySystem.HoloScale = 0
                if IsValid(BountySystem.HoloModel) then 
                    BountySystem.HoloModel:SetModel(LocalPlayer():GetModel()) 
                    BountySystem.CopyModelData(LocalPlayer(), BountySystem.HoloModel)
                    local sequence = BountySystem.HoloModel:SelectWeightedSequence(ACT_IDLE)
                    BountySystem.HoloModel:ResetSequence(sequence)
                end
            end

            -- LISTA DE CONTRATOS
            if BountySystem.TermTab == "list" then
                local bounties = {}
                for id, b in pairs(BountySystem.LocalBounties) do table.insert(bounties, b) end

                local maxPages = math.ceil(math.max(1, #bounties) / 4)
                if BountySystem.TermPage > maxPages then BountySystem.TermPage = maxPages end

                local startIdx = (BountySystem.TermPage - 1) * 4 + 1
                local endIdx = math.min(startIdx + 3, #bounties)

                local yOffset = 100
                for i = startIdx, endIdx do
                    local b = bounties[i]
                    local isSel = (BountySystem.TermSelected == b)

                    local targetPly = nil
                    for _, p in ipairs(player.GetAll()) do
                        local pSteam = p:IsBot() and ("BOT_" .. p:EntIndex()) or p:SteamID()
                        if pSteam == b.targetSteam then targetPly = p break end
                    end

                    local jobDisplay = "Desconocido"
                    if IsValid(targetPly) then
                        jobDisplay = (RPExtraTeams and RPExtraTeams[targetPly:Team()] and RPExtraTeams[targetPly:Team()].category) or team.GetName(targetPly:Team())
                    end

                    local subtext = jobDisplay .. " | Pago: " .. cfg.CurrencySymbol .. b.amount

                    if DrawBtn(20, yOffset, 760, 85, b.targetName, UI.White, isSel, subtext) then
                        BountySystem.TermSelected = b
                        BountySystem.HoloScale = 0
                        -- Cargar modelo físico
                        local targetPly = nil
                        for _, p in ipairs(player.GetAll()) do
                            local pSteam = p:IsBot() and ("BOT_" .. p:EntIndex()) or p:SteamID()
                            if pSteam == b.targetSteam then targetPly = p break end
                        end
                        if IsValid(targetPly) and IsValid(BountySystem.HoloModel) then
                            BountySystem.HoloModel:SetModel(targetPly:GetModel())
                            BountySystem.CopyModelData(targetPly, BountySystem.HoloModel)
                            local sequence = BountySystem.HoloModel:SelectWeightedSequence(ACT_IDLE)
                            BountySystem.HoloModel:ResetSequence(sequence)
                        end
                    end
                    yOffset = yOffset + 95
                end

                -- Paginación
                if DrawBtn(20, 490, 100, 50, "<", UI.Blue) and BountySystem.TermPage > 1 then BountySystem.TermPage = BountySystem.TermPage - 1 end
                draw.SimpleText("Página " .. BountySystem.TermPage .. " de " .. maxPages, "BountySystem_Title", 400, 515, UI.White, 1, 1)
                if DrawBtn(680, 490, 100, 50, ">", UI.Blue) and BountySystem.TermPage < maxPages then BountySystem.TermPage = BountySystem.TermPage + 1 end

                -- Acción Aceptar
                if BountySystem.TermSelected then
                    local b = BountySystem.TermSelected
                    local canAccept = (not b.acceptedBy) and (b.placerSteam ~= LocalPlayer():SteamID()) and (b.targetSteam ~= LocalPlayer():SteamID())
                    if canAccept then
                        if DrawBtn(20, 570, 760, 90, "ACEPTAR PRESA", UI.Green) then
                            net.Start("BountySystem_AcceptBounty")
                            net.WriteUInt(b.id, 16)
                            net.SendToServer()
                            frame:Remove()
                        end
                    else
                        local txt = b.acceptedBy and "OCUPADO" or "NO DISPONIBLE"
                        DrawBtn(20, 570, 760, 90, txt, UI.Red)
                    end
                end

            -- EMITIR RECOMPENSA
            elseif BountySystem.TermTab == "place" then
                local plys = {}
                for _, p in ipairs(player.GetAll()) do
                    if p ~= LocalPlayer() then
                        local jcmd = RPExtraTeams and RPExtraTeams[p:Team()] and RPExtraTeams[p:Team()].command or ""
                        if not cfg.RestrictedTargetJobs[jcmd] then table.insert(plys, p) end
                    end
                end
                
                local maxPages = math.ceil(math.max(1, #plys) / 4)
                if BountySystem.TermPage > maxPages then BountySystem.TermPage = maxPages end
                local startIdx = (BountySystem.TermPage - 1) * 4 + 1
                local endIdx = math.min(startIdx + 3, #plys)
                
                local yOffset = 100
                for i = startIdx, endIdx do
                    local p = plys[i]
                    local isSel = (BountySystem.TermSelected == p)
                    local teamDisplay = team.GetName(p:Team())
                    if RPExtraTeams and RPExtraTeams[p:Team()] and RPExtraTeams[p:Team()].category then
                        teamDisplay = RPExtraTeams[p:Team()].category
                    end
                    
                    if DrawBtn(20, yOffset, 760, 85, p:Nick(), UI.White, isSel, teamDisplay) then
                        BountySystem.TermSelected = p
                        BountySystem.HoloScale = 0
                        if IsValid(BountySystem.HoloModel) then 
                            BountySystem.HoloModel:SetModel(p:GetModel()) 
                            BountySystem.CopyModelData(p, BountySystem.HoloModel)
                            local sequence = BountySystem.HoloModel:SelectWeightedSequence(ACT_IDLE)
                            BountySystem.HoloModel:ResetSequence(sequence)
                        end
                    end
                    yOffset = yOffset + 95
                end
                
                -- Paginación
                if DrawBtn(20, 480, 100, 50, "<", UI.Red) and BountySystem.TermPage > 1 then BountySystem.TermPage = BountySystem.TermPage - 1 end
                draw.SimpleText("Página " .. BountySystem.TermPage .. " de " .. maxPages, "BountySystem_Title", 400, 505, UI.White, 1, 1)
                if DrawBtn(680, 480, 100, 50, ">", UI.Red) and BountySystem.TermPage < maxPages then BountySystem.TermPage = BountySystem.TermPage + 1 end

                -- Precio y Emitir
                if BountySystem.TermSelected then
                    draw.SimpleText("Recompensa: " .. cfg.CurrencySymbol .. BountySystem.TermAmount, "BountySystem_Title", 400, 560, UI.Gold, 1, 1)
                    if DrawBtn(20, 540, 150, 40, "- 5000", UI.Red) then BountySystem.TermAmount = math.max(cfg.MinBounty, BountySystem.TermAmount - 5000) end
                    if DrawBtn(630, 540, 150, 40, "+ 5000", UI.Green) then BountySystem.TermAmount = math.min(cfg.MaxBounty, BountySystem.TermAmount + 5000) end

                    if DrawBtn(20, 600, 760, 90, "EMITIR CONTRATO", UI.Red) then
                        net.Start("BountySystem_PlaceBounty")
                        local tID = BountySystem.TermSelected:IsBot() and ("BOT_" .. BountySystem.TermSelected:EntIndex()) or BountySystem.TermSelected:SteamID()
                        net.WriteString(tID)
                        net.WriteUInt(BountySystem.TermAmount, 32)
                        net.WriteString("Contrato emitido desde la Terminal Central")
                        net.WriteString(BountySystem.TermSelected:Nick())
                        net.SendToServer()
                        frame:Remove()
                    end
                end
            
            -- PERFIL
            elseif BountySystem.TermTab == "profile" then
                local stats = BountySystem.MyStats
                local xpNeeded = stats.level * 1000
                
                draw.SimpleText("EXPEDIENTE DE CAZADOR", "BountySystem_Title", 400, 150, UI.Blue, 1, 1)
                draw.SimpleText("Agente: " .. LocalPlayer():Nick(), "BountySystem_Title", 400, 200, UI.White, 1, 1)
                
                draw.SimpleText("NIVEL " .. stats.level, "BountySystem_Title", 400, 280, UI.White, 1, 1)
                if stats.prestige > 0 then
                    draw.SimpleText("PRESTIGIO " .. stats.prestige, "BountySystem_Title", 400, 320, UI.Gold, 1, 1)
                end
                
                -- Barra XP 3D
                surface.SetDrawColor(0, 20, 40, 200)
                surface.DrawRect(150, 370, 500, 40)
                local xpFill = math.Clamp(stats.xp / xpNeeded, 0, 1)
                surface.SetDrawColor(0, 150, 255, 150)
                surface.DrawRect(150, 370, 500 * xpFill, 40)
                surface.SetDrawColor(UI.Blue)
                surface.DrawOutlinedRect(150, 370, 500, 40, 3)
                draw.SimpleText("XP: " .. stats.xp .. " / " .. xpNeeded, "BountySystem_Header", 400, 390, UI.White, 1, 1)
                
                draw.SimpleText("Contratos Ejecutados: " .. stats.kills, "BountySystem_Title", 400, 480, UI.Red, 1, 1)
                
                if stats.level >= (BountySystem.Config.MaxLevel or 50) then
                    if DrawBtn(250, 550, 300, 80, "ASCENDER A PRESTIGIO", UI.Gold) then
                        net.Start("BountySystem_Prestige")
                        net.SendToServer()
                    end
                end
            end

        cam.End3D2D()
        isPressed = false
    end)
end

-- ──────────────────────────────────────────
--  KEYBIND y CHAT COMMAND (Datapad F3)
-- ──────────────────────────────────────────
hook.Add("PlayerButtonDown", "BountySystem_KeyBind", function(ply, btn)
    if btn == KEY_F3 then BountySystem.OpenMenu() end
end)

chat.AddText(Color(0, 200, 255), "[HoloNet]", color_white, " Gremio de Cazarrecompensas conectado. Usa ", Color(255, 50, 50), "F3", color_white, " o escribe ", Color(255, 50, 50), "!contratos", color_white, " en el chat.")

hook.Add("OnPlayerChat", "BountySystem_ChatCmd", function(ply, text)
    if ply == LocalPlayer() and (text == "!bounty" or text == "!contratos") then
        timer.Simple(0, function() BountySystem.OpenMenu() end)
    end
end)

-- ──────────────────────────────────────────
--  INTERACCIÓN CON CAZARRECOMPENSAS (TECLA E)
-- ──────────────────────────────────────────
hook.Add("KeyPress", "BountySystem_HireInteract", function(ply, key)
    if key == IN_USE and ply == LocalPlayer() then
        local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 100, filter = ply })
        if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
            local target = tr.Entity
            local jobCmd = RPExtraTeams and RPExtraTeams[target:Team()] and RPExtraTeams[target:Team()].command or ""
            local myJobCmd = RPExtraTeams and RPExtraTeams[ply:Team()] and RPExtraTeams[ply:Team()].command or ""
            if cfg.BountyHunterJobs and cfg.BountyHunterJobs[jobCmd] and not cfg.BountyHunterJobs[myJobCmd] then
                net.Start("BountySystem_HireHunter")
                net.WriteEntity(target)
                net.SendToServer()
            end
        end
    end
end)

-- ──────────────────────────────────────────
--  ABRIR MENÚ DESDE LA ENTIDAD
-- ──────────────────────────────────────────
net.Receive("BountySystem_OpenMenu", function()
    local ent = net.ReadEntity()
    if IsValid(ent) then
        BountySystem.OpenTerminal(ent)
    end
end)
