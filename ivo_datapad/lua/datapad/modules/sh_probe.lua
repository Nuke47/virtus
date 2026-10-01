if not Datapad then return end

-- =========================================================================
-- [SERVIDOR] BACKEND DROIDE SONDA
-- =========================================================================
if SERVER then
    -- No necesitamos net strings adicionales aquí,
    -- ya se registran en sh_probe_net.lua del addon ivo_probe
end

-- =========================================================================
-- [CLIENTE] INTERFAZ DROIDE SONDA
-- =========================================================================
if CLIENT then

    -- ─── Fuentes ──────────────────────────────────────────────────────
    surface.CreateFont("Probe_Title",  { font = "Roboto", size = 20, weight = 800, antialias = true })
    surface.CreateFont("Probe_Bold",   { font = "Roboto", size = 15, weight = 700, antialias = true })
    surface.CreateFont("Probe_Body",   { font = "Roboto", size = 14, weight = 500, antialias = true })
    surface.CreateFont("Probe_Small",  { font = "Roboto", size = 12, weight = 400, antialias = true })
    surface.CreateFont("Probe_Status", { font = "Roboto", size = 18, weight = 700, antialias = true })

    -- ─── Paleta ───────────────────────────────────────────────────────
    local clrBg       = Color(10, 14, 12)
    local clrAccent   = Color(0, 200, 80)
    local clrAccentDk = Color(0, 120, 50)
    local clrCard     = Color(16, 22, 18)
    local clrText     = Color(220, 255, 230)
    local clrMuted    = Color(100, 140, 110)
    local clrDanger   = Color(220, 50, 50)
    local clrWarn     = Color(255, 180, 50)

    -- ─── Scrollbar personalizada ──────────────────────────────────────
    local function ProbeScrollbar(sp)
        local sbar = sp:GetVBar()
        if not IsValid(sbar) then return end
        sbar:SetWide(4)
        sbar.Paint       = function() end
        sbar.btnUp.Paint   = function() end
        sbar.btnDown.Paint = function() end
        sbar.btnGrip.Paint = function(s, w, h)
            draw.RoundedBox(2, 0, 0, w, h, Color(clrAccent.r, clrAccent.g, clrAccent.b, s:IsHovered() and 200 or 80))
        end
    end

    -- ─── Helper: Obtener probe activo ─────────────────────────────────
    local function GetActiveProbe()
        if ProbeDroid_Deployed and IsValid(ProbeDroid_Entity) then
            return ProbeDroid_Entity
        end
        -- Fallback: buscar en entidades del jugador
        for _, ent in ipairs(ents.FindByClass("ent_probe_droid")) do
            if IsValid(ent) and ent:GetProbeOwner() == LocalPlayer() then
                ProbeDroid_Deployed = true
                ProbeDroid_Entity = ent
                return ent
            end
        end
        return nil
    end

    -- =========================================================================
    -- REGISTRO DEL MÓDULO
    -- =========================================================================
    Datapad:RegisterModule("probe_droid", {
        Name  = "Droide Sonda",
        Icon  = "icon16/transmit.png",
        Order = 5,
        CanAccess = function(ply)
            if not Datapad.Config or not Datapad.Config.SUSpecJobs then return false end
            return Datapad:HasAccess(ply, Datapad.Config.SUSpecJobs)
        end,

        UI = function(parent)
            local modulePanel = vgui.Create("DPanel", parent)
            modulePanel:Dock(FILL)
            modulePanel.Paint = function() end

            -- ─── Header ──────────────────────────────────────────────
            local header = vgui.Create("DPanel", modulePanel)
            header:Dock(TOP)
            header:SetTall(60)
            header:DockMargin(15, 15, 15, 0)
            header.Paint = function(s, w, h)
                draw.RoundedBox(8, 0, 0, w, h, clrCard)
                surface.SetDrawColor(clrAccent.r, clrAccent.g, clrAccent.b, 30)
                surface.DrawOutlinedRect(0, 0, w, h, 1)

                draw.SimpleText("CONTROL DE DROIDE SONDA", "Probe_Title", 15, 12, clrAccent)
                draw.SimpleText("Sistema de reconocimiento remoto V-1X", "Probe_Small", 15, 36, clrMuted)
            end

            -- ─── Estado en vivo ──────────────────────────────────────
            local statusPanel = vgui.Create("DPanel", modulePanel)
            statusPanel:Dock(TOP)
            statusPanel:SetTall(110)
            statusPanel:DockMargin(15, 10, 15, 0)
            statusPanel.Paint = function(s, w, h)
                draw.RoundedBox(8, 0, 0, w, h, clrCard)
                surface.SetDrawColor(255, 255, 255, 5)
                surface.DrawOutlinedRect(0, 0, w, h, 1)

                local probe = GetActiveProbe()
                local isControlling = ProbeDroid_IsControlling and ProbeDroid_IsControlling() or false

                -- Indicador de estado
                local statusText, statusColor
                if not probe or not IsValid(probe) then
                    statusText = "EN ESPERA"
                    statusColor = clrMuted
                elseif isControlling then
                    statusText = "● CONTROLANDO"
                    local pulse = math.abs(math.sin(CurTime() * 3)) * 100 + 155
                    statusColor = Color(0, 255, 100, pulse)
                else
                    statusText = "● DESPLEGADO"
                    statusColor = clrAccent
                end

                draw.SimpleText("ESTADO:", "Probe_Bold", 15, 12, clrMuted)
                draw.SimpleText(statusText, "Probe_Status", 80, 10, statusColor)

                if IsValid(probe) then
                    local owner = LocalPlayer()
                    local dist = math.floor(probe:GetPos():Distance(owner:GetPos()))
                    local alt  = math.floor(probe:GetPos().z - owner:GetPos().z)
                    local hp   = probe:Health()
                    local maxHP = probe:GetMaxHealth()

                    -- Telemetría
                    draw.SimpleText("DISTANCIA:", "Probe_Small", 15, 38, clrMuted)
                    draw.SimpleText(dist .. " u", "Probe_Bold", 90, 36, clrText)

                    draw.SimpleText("ALTITUD:", "Probe_Small", 15, 56, clrMuted)
                    draw.SimpleText((alt >= 0 and "+" or "") .. alt .. " u", "Probe_Bold", 78, 54, clrText)

                    -- Barra de HP
                    draw.SimpleText("INTEGRIDAD:", "Probe_Small", 15, 78, clrMuted)

                    local barX, barY, barW, barH = 100, 80, w - 120, 14
                    surface.SetDrawColor(0, 40, 20, 150)
                    surface.DrawRect(barX, barY, barW, barH)

                    local hpFrac = math.Clamp(hp / maxHP, 0, 1)
                    local hpColor = clrAccent
                    if hpFrac < 0.3 then
                        hpColor = clrDanger
                    elseif hpFrac < 0.6 then
                        hpColor = clrWarn
                    end
                    surface.SetDrawColor(hpColor)
                    surface.DrawRect(barX, barY, barW * hpFrac, barH)

                    surface.SetDrawColor(0, 0, 0, 80)
                    for i = 1, 9 do
                        surface.DrawRect(barX + (barW / 10) * i, barY, 1, barH)
                    end

                    draw.SimpleText(hp .. "/" .. maxHP, "Probe_Small", barX + barW / 2, barY + barH / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                else
                    draw.SimpleText("Sin droide activo", "Probe_Body", 15, 45, Color(100, 100, 100))
                    draw.SimpleText("Despliegue un droide sonda para comenzar", "Probe_Small", 15, 65, Color(80, 80, 80))
                end
            end

            -- ─── Botones de acción ───────────────────────────────────
            local buttonArea = vgui.Create("DPanel", modulePanel)
            buttonArea:Dock(FILL)
            buttonArea:DockMargin(15, 15, 15, 15)
            buttonArea.Paint = function() end

            -- Botón: ACTIVAR CÁMARA
            local btnCamera = vgui.Create("DButton", buttonArea)
            btnCamera:Dock(TOP)
            btnCamera:SetTall(45)
            btnCamera:DockMargin(0, 0, 0, 8)
            btnCamera:SetText("ACTIVAR CÁMARA")
            btnCamera:SetFont("Probe_Bold")
            btnCamera:SetTextColor(clrText)
            btnCamera.Paint = function(s, w, h)
                local probe = GetActiveProbe()
                local enabled = IsValid(probe) and not (ProbeDroid_IsControlling and ProbeDroid_IsControlling())
                local bgColor

                if not enabled then
                    bgColor = Color(30, 35, 30)
                    s:SetTextColor(Color(80, 80, 80))
                    s:SetCursor("no")
                elseif s:IsHovered() then
                    bgColor = Color(0, 150, 255)
                    s:SetTextColor(color_white)
                    s:SetCursor("hand")
                else
                    bgColor = Color(0, 90, 150)
                    s:SetTextColor(clrText)
                    s:SetCursor("hand")
                end
                draw.RoundedBox(6, 0, 0, w, h, bgColor)
            end
            btnCamera.DoClick = function()
                local probe = GetActiveProbe()
                if not IsValid(probe) then return end
                if ProbeDroid_IsControlling and ProbeDroid_IsControlling() then return end

                -- Cerrar menú y activar control
                if IsValid(Datapad.MenuFrame) then
                    Datapad.MenuFrame:Close()
                end

                if ProbeDroid_StartControl then
                    ProbeDroid_StartControl(probe)
                else
                    net.Start("Probe_StartControl")
                    net.WriteEntity(probe)
                    net.SendToServer()
                end
            end

            -- Botón: DESCONECTAR CÁMARA
            local btnDisconnect = vgui.Create("DButton", buttonArea)
            btnDisconnect:Dock(TOP)
            btnDisconnect:SetTall(45)
            btnDisconnect:DockMargin(0, 0, 0, 8)
            btnDisconnect:SetText("DESCONECTAR CÁMARA")
            btnDisconnect:SetFont("Probe_Bold")
            btnDisconnect:SetTextColor(clrText)
            btnDisconnect.Paint = function(s, w, h)
                local isCtrl = ProbeDroid_IsControlling and ProbeDroid_IsControlling()
                local bgColor

                if not isCtrl then
                    bgColor = Color(30, 35, 30)
                    s:SetTextColor(Color(80, 80, 80))
                    s:SetCursor("no")
                elseif s:IsHovered() then
                    bgColor = Color(255, 180, 50)
                    s:SetTextColor(color_white)
                    s:SetCursor("hand")
                else
                    bgColor = Color(180, 120, 30)
                    s:SetTextColor(clrText)
                    s:SetCursor("hand")
                end
                draw.RoundedBox(6, 0, 0, w, h, bgColor)
            end
            btnDisconnect.DoClick = function()
                if not (ProbeDroid_IsControlling and ProbeDroid_IsControlling()) then return end
                if ProbeDroid_StopControl then
                    ProbeDroid_StopControl()
                else
                    net.Start("Probe_StopControl")
                    net.SendToServer()
                end
            end

            -- Botón: DESVINCULAR SONDA
            local btnRecall = vgui.Create("DButton", buttonArea)
            btnRecall:Dock(TOP)
            btnRecall:SetTall(45)
            btnRecall:DockMargin(0, 0, 0, 0)
            btnRecall:SetText("DESVINCULAR SONDA")
            btnRecall:SetFont("Probe_Bold")
            btnRecall:SetTextColor(clrText)
            btnRecall.Paint = function(s, w, h)
                local probe = GetActiveProbe()
                local enabled = IsValid(probe)
                local bgColor

                if not enabled then
                    bgColor = Color(30, 30, 30)
                    s:SetTextColor(Color(80, 80, 80))
                    s:SetCursor("no")
                elseif s:IsHovered() then
                    bgColor = clrDanger
                    s:SetTextColor(color_white)
                    s:SetCursor("hand")
                else
                    bgColor = Color(140, 35, 35)
                    s:SetTextColor(clrText)
                    s:SetCursor("hand")
                end
                draw.RoundedBox(6, 0, 0, w, h, bgColor)
            end
            btnRecall.DoClick = function()
                local probe = GetActiveProbe()
                if not IsValid(probe) then return end

                -- Salir del control si estamos controlando
                if ProbeDroid_IsControlling and ProbeDroid_IsControlling() then
                    if ProbeDroid_StopControl then
                        ProbeDroid_StopControl()
                    else
                        net.Start("Probe_StopControl")
                        net.SendToServer()
                    end
                end

                net.Start("Probe_Unlink")
                net.SendToServer()

                ProbeDroid_Deployed = false
                ProbeDroid_Entity = nil
            end
        end
    })
end
