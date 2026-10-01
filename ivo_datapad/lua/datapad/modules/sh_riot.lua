if not Datapad then return end

-- =========================================================================
-- [SERVIDOR] BACKEND RED TÁCTICA (RT) — SIN MÓDULO DE ARRESTOS
-- =========================================================================
if SERVER then
    util.AddNetworkString("Datapad_RequestRTData")
    util.AddNetworkString("Datapad_SendRTData")
    util.AddNetworkString("Datapad_SaveRTReport")
    util.AddNetworkString("Datapad_DeleteRTReport")
    util.AddNetworkString("Datapad_ReportToISB")

    -- Tabla de informes tácticos
    sql.Query([[
        CREATE TABLE IF NOT EXISTS datapad_rt_reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            officer_name TEXT, officer_steamid TEXT,
            subject_name TEXT, report_text TEXT, timestamp INTEGER
        )
    ]])

    -- Columna officer_steamid si no existe (ALTER seguro)
    pcall(function()
        sql.Query("ALTER TABLE datapad_rt_reports ADD COLUMN officer_steamid TEXT")
    end)

    local function SyncRTDataToAll()
        local reports = sql.Query("SELECT * FROM datapad_rt_reports ORDER BY id DESC LIMIT 50") or {}
        for _, r in pairs(reports) do
            r.officer_steamid = r.officer_steamid or "STEAM_0:0:000000"
            r.officer_name    = r.officer_name    or "Sistema Central"
            r.subject_name    = r.subject_name    or "Desconocido"
            r.report_text     = r.report_text     or ""
        end
        net.Start("Datapad_SendRTData")
            net.WriteTable(reports)
        net.Broadcast()
    end

    net.Receive("Datapad_RequestRTData", function(len, ply)
        if not IsValid(ply) then return end
        local reports = sql.Query("SELECT * FROM datapad_rt_reports ORDER BY id DESC LIMIT 50") or {}
        for _, r in pairs(reports) do
            r.officer_steamid = r.officer_steamid or "STEAM_0:0:000000"
            r.officer_name    = r.officer_name    or "Sistema Central"
            r.subject_name    = r.subject_name    or "Desconocido"
            r.report_text     = r.report_text     or ""
        end
        net.Start("Datapad_SendRTData")
            net.WriteTable(reports)
        net.Send(ply)
    end)

    net.Receive("Datapad_SaveRTReport", function(len, ply)
        if not IsValid(ply) then return end
        local subject = net.ReadString()
        local text    = net.ReadString()
        if subject == "" or text == "" then return end
        sql.Query(string.format(
            "INSERT INTO datapad_rt_reports (officer_name, officer_steamid, subject_name, report_text, timestamp) VALUES (%s, %s, %s, %s, %d)",
            sql.SQLStr(ply:Nick()), sql.SQLStr(ply:SteamID()), sql.SQLStr(subject), sql.SQLStr(text), os.time()
        ))
        SyncRTDataToAll()
    end)

    net.Receive("Datapad_DeleteRTReport", function(len, ply)
        if not IsValid(ply) then return end
        local reportID = net.ReadInt(32)
        sql.Query(string.format("DELETE FROM datapad_rt_reports WHERE id = %d", reportID))
        SyncRTDataToAll()
    end)

    -- ─── Reporte sospechoso al ISB ────────────────────────────────────────
    net.Receive("Datapad_ReportToISB", function(len, ply)
        if not IsValid(ply) then return end
        local suspectName = net.ReadString()
        local suspectJob  = net.ReadString()
        local reportText  = net.ReadString()
        if suspectName == "" or reportText == "" then return end

        local finalIntel = string.format(
            "[REPORTE RT → ISB]\nReportado por: %s\nSospechoso: %s (%s)\n\nDetalle:\n%s",
            ply:Nick(), suspectName, suspectJob, reportText
        )

        sql.Query(string.format(
            "INSERT INTO datapad_isb_reports (operative_name, operative_steamid, subject_name, intel_text, timestamp) VALUES (%s, %s, %s, %s, %d)",
            sql.SQLStr("RT: " .. ply:Nick()), sql.SQLStr(ply:SteamID()),
            sql.SQLStr(suspectName), sql.SQLStr(finalIntel), os.time()
        ))

        -- Sincronizar ISB si hay jugadores con acceso
        local isbReports  = sql.Query("SELECT * FROM datapad_isb_reports ORDER BY id DESC LIMIT 50")  or {}
        local isbMessages = sql.Query("SELECT * FROM datapad_isb_messages ORDER BY id DESC LIMIT 100") or {}
        net.Start("Datapad_SendISBData")
            net.WriteTable(isbReports)
            net.WriteTable(isbMessages)
        net.Broadcast()
    end)
end

-- =========================================================================
-- [CLIENTE] INTERFAZ RED TÁCTICA
-- =========================================================================
if CLIENT then
    Datapad.RT_ReportsCache = Datapad.RT_ReportsCache or {}

    net.Receive("Datapad_SendRTData", function()
        Datapad.RT_ReportsCache = net.ReadTable() or {}
        hook.Run("Datapad_RefreshRTUI")
    end)

    -- ─── Fuentes ──────────────────────────────────────────────────────────
    surface.CreateFont("RT_Title",  { font = "Roboto", size = 22, weight = 800, antialias = true })
    surface.CreateFont("RT_Header", { font = "Roboto", size = 16, weight = 700, antialias = true })
    surface.CreateFont("RT_Body",   { font = "Roboto", size = 14, weight = 500, antialias = true })
    surface.CreateFont("RT_Small",  { font = "Roboto", size = 11, weight = 400, antialias = true })

    local function GetColor(key, default)
        if Datapad.Config and Datapad.Config.Colors and Datapad.Config.Colors[key] then return Datapad.Config.Colors[key] end
        return default
    end

    local function RTScrollbar(sp, clr)
        local sbar = sp:GetVBar()
        if not IsValid(sbar) then return end
        sbar:SetWide(6)
        sbar.Paint = function() end sbar.btnUp.Paint = function() end sbar.btnDown.Paint = function() end
        sbar.btnGrip.Paint = function(s, w, h)
            draw.RoundedBox(3, 0, 0, w, h, Color(clr.r, clr.g, clr.b, s:IsHovered() and 180 or 100))
        end
    end

    Datapad:RegisterModule("rt_database", {
        Name  = "Red Táctica RT",
        Icon  = "icon16/shield.png",
        Order = 2,
        CanAccess = function(ply)
            if not Datapad.Config or not Datapad.Config.RiotJobs then return true end
            return Datapad:HasAccess(ply, Datapad.Config.RiotJobs)
        end,

        UI = function(parent)
            net.Start("Datapad_RequestRTData") net.SendToServer()

            local modulePanel = vgui.Create("DPanel", parent)
            modulePanel:Dock(FILL)
            modulePanel.Paint = function() end

            local clrBg     = GetColor("Background", Color(14, 16, 22))
            local clrAccent = GetColor("Accent",     Color(0, 153, 204))
            local clrCardBg = Color(23, 27, 38)
            local clrText   = GetColor("Text",       color_white)
            local clrMuted  = Color(160, 170, 190)

            -- Barra de acciones superior
            local topBar = vgui.Create("DPanel", modulePanel)
            topBar:Dock(TOP) topBar:SetTall(55) topBar:DockMargin(15, 15, 15, 5)
            topBar.Paint = function() end

            -- Botón "Reportar sospechoso al ISB"
            local btnISBReport = vgui.Create("DButton", topBar)
            btnISBReport:Dock(RIGHT) btnISBReport:SetWide(260)
            btnISBReport:SetText("⚠  REPORTAR SOSPECHOSO AL ISB")
            btnISBReport:SetFont("RT_Header") btnISBReport:SetTextColor(color_white)
            btnISBReport.Paint = function(s, w, h)
                draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and Color(200, 160, 0) or Color(130, 100, 0))
                surface.SetDrawColor(200, 160, 0) surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            btnISBReport.DoClick = function()
                local f = vgui.Create("DFrame")
                f:SetSize(480, 370) f:Center() f:MakePopup() f:SetTitle("") f:SetAlpha(0) f:AlphaTo(255, 0.15)
                f.Paint = function(s, w, h)
                    draw.RoundedBox(8, 0, 0, w, h, clrBg)
                    draw.RoundedBoxEx(8, 0, 0, w, 45, Color(110, 90, 0), true, true, false, false)
                    surface.SetDrawColor(200, 160, 0) surface.DrawRect(0, 44, w, 2)
                    draw.SimpleText("REPORTAR SOSPECHOSO AL ISB", "RT_Title", 15, 12, color_white)
                end
                local close = vgui.Create("DButton", f)
                close:SetPos(445, 8) close:SetSize(30, 30) close:SetText("✕") close:SetFont("RT_Header") close:SetTextColor(color_white) close.Paint = function() end
                close.DoClick = function() f:Close() end

                local lblName = vgui.Create("DLabel", f)
                lblName:SetPos(20, 58) lblName:SetSize(200, 20)
                lblName:SetText("Nombre del sospechoso:") lblName:SetFont("RT_Body") lblName:SetTextColor(Color(200, 180, 100))

                local entName = vgui.Create("DTextEntry", f)
                entName:SetPos(20, 78) entName:SetSize(430, 36) entName:SetFont("RT_Body")
                entName:SetPlaceholderText(" Ej: CT-1234 Nombre...")
                entName.Paint = function(s, w, h)
                    draw.RoundedBox(6, 0, 0, w, h, Color(22, 25, 32))
                    surface.SetDrawColor(s:HasFocus() and Color(200, 160, 0) or Color(255, 255, 255, 8))
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    s:DrawTextEntryText(color_white, Color(200, 160, 0), color_white)
                end

                local lblJob = vgui.Create("DLabel", f)
                lblJob:SetPos(20, 124) lblJob:SetSize(200, 20)
                lblJob:SetText("Rango / Unidad:") lblJob:SetFont("RT_Body") lblJob:SetTextColor(Color(200, 180, 100))

                local entJob = vgui.Create("DTextEntry", f)
                entJob:SetPos(20, 144) entJob:SetSize(430, 36) entJob:SetFont("RT_Body")
                entJob:SetPlaceholderText(" Ej: Médico de la 212th...")
                entJob.Paint = function(s, w, h)
                    draw.RoundedBox(6, 0, 0, w, h, Color(22, 25, 32))
                    surface.SetDrawColor(s:HasFocus() and Color(200, 160, 0) or Color(255, 255, 255, 8))
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    s:DrawTextEntryText(color_white, Color(200, 160, 0), color_white)
                end

                local lblDetail = vgui.Create("DLabel", f)
                lblDetail:SetPos(20, 192) lblDetail:SetSize(200, 20)
                lblDetail:SetText("Descripción del comportamiento sospechoso:") lblDetail:SetFont("RT_Body") lblDetail:SetTextColor(Color(200, 180, 100))

                local entDetail = vgui.Create("DTextEntry", f)
                entDetail:SetPos(20, 212) entDetail:SetSize(430, 90) entDetail:SetMultiline(true) entDetail:SetFont("RT_Body")
                entDetail:SetPlaceholderText(" Describe el comportamiento observado...")
                entDetail.Paint = function(s, w, h)
                    draw.RoundedBox(6, 0, 0, w, h, Color(22, 25, 32))
                    surface.SetDrawColor(s:HasFocus() and Color(200, 160, 0) or Color(255, 255, 255, 8))
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    s:DrawTextEntryText(color_white, Color(200, 160, 0), color_white)
                end

                local btnSend = vgui.Create("DButton", f)
                btnSend:SetPos(20, 315) btnSend:SetSize(430, 40)
                btnSend:SetText("ENVIAR REPORTE AL ISB") btnSend:SetFont("RT_Header") btnSend:SetTextColor(color_white)
                btnSend.Paint = function(s, w, h)
                    draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and Color(200, 160, 0) or Color(130, 100, 0))
                end
                btnSend.DoClick = function()
                    local name   = entName:GetText()
                    local job    = entJob:GetText()
                    local detail = entDetail:GetText()
                    if name == "" or detail == "" then return end
                    net.Start("Datapad_ReportToISB")
                        net.WriteString(name)
                        net.WriteString(job)
                        net.WriteString(detail)
                    net.SendToServer()
                    f:Close()
                    chat.AddText(Color(200, 160, 0), "[RT → ISB] Reporte enviado.")
                end
            end

            -- Botón nuevo informe
            local btnAdd = vgui.Create("DButton", topBar)
            btnAdd:Dock(RIGHT) btnAdd:SetWide(250) btnAdd:DockMargin(0, 0, 10, 0)
            btnAdd:SetText("+ NUEVA ALERTA DE INTELIGENCIA") btnAdd:SetFont("RT_Header") btnAdd:SetTextColor(color_white)
            btnAdd.Paint = function(s, w, h)
                draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and clrAccent or clrCardBg)
                if not s:IsHovered() then
                    surface.SetDrawColor(clrAccent.r, clrAccent.g, clrAccent.b, 100)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end
            end
            btnAdd.DoClick = function()
                local f = vgui.Create("DFrame")
                f:SetSize(440, 360) f:Center() f:MakePopup() f:SetTitle("") f:SetAlpha(0) f:AlphaTo(255, 0.15)
                f.Paint = function(s, w, h)
                    draw.RoundedBox(8, 0, 0, w, h, clrBg)
                    draw.SimpleText("REDACTAR ALERTA", "RT_Title", 20, 15, clrText)
                end
                local close = vgui.Create("DButton", f)
                close:SetPos(405, 8) close:SetSize(30, 30) close:SetText("✕") close:SetFont("RT_Header") close:SetTextColor(clrMuted) close.Paint = function() end
                close.DoClick = function() f:Close() end

                local sub = vgui.Create("DTextEntry", f)
                sub:Dock(TOP) sub:SetTall(36) sub:DockMargin(20, 58, 20, 0)
                sub:SetPlaceholderText("Identificación del Sujeto (Ej: CT-7567 Rex)") sub:SetFont("RT_Body")
                sub.Paint = function(s, w, h)
                    draw.RoundedBox(6, 0, 0, w, h, clrCardBg)
                    surface.SetDrawColor(s:HasFocus() and clrAccent or Color(255, 255, 255, 4))
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    s:DrawTextEntryText(color_white, clrAccent, color_white)
                end

                local txt = vgui.Create("DTextEntry", f)
                txt:Dock(FILL) txt:SetMultiline(true) txt:DockMargin(20, 15, 20, 15)
                txt:SetPlaceholderText("Cargos, observaciones tácticas y estado actual...") txt:SetFont("RT_Body")
                txt.Paint = function(s, w, h)
                    draw.RoundedBox(6, 0, 0, w, h, clrCardBg)
                    surface.SetDrawColor(s:HasFocus() and clrAccent or Color(255, 255, 255, 4))
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    s:DrawTextEntryText(color_white, clrAccent, color_white)
                end

                local sv = vgui.Create("DButton", f)
                sv:Dock(BOTTOM) sv:SetTall(40) sv:DockMargin(20, 0, 20, 20)
                sv:SetText("SUBIR A LA RED CENTRAL") sv:SetFont("RT_Header") sv:SetTextColor(color_white)
                sv.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and clrAccent or Color(35, 40, 55)) end
                sv.DoClick = function()
                    if sub:GetText() == "" or txt:GetText() == "" then return end
                    net.Start("Datapad_SaveRTReport")
                        net.WriteString(sub:GetText())
                        net.WriteString(txt:GetText())
                    net.SendToServer()
                    f:Close()
                end
            end

            -- Lista de informes
            local scroll = vgui.Create("DScrollPanel", modulePanel)
            scroll:Dock(FILL) scroll:DockMargin(15, 5, 15, 15)
            RTScrollbar(scroll, clrAccent)

            local function PopulateReports()
                local curScroll = IsValid(scroll) and scroll:GetVBar():GetScroll() or 0
                scroll:Clear()

                if #Datapad.RT_ReportsCache == 0 then
                    local noData = scroll:Add("DLabel")
                    noData:SetText("NO SE REGISTRAN INFORMES EN LA RED")
                    noData:SetFont("RT_Header") noData:SetTextColor(Color(255, 255, 255, 25))
                    noData:SetContentAlignment(5) noData:Dock(FILL) noData:DockMargin(0, 100, 0, 0)
                    return
                end

                for _, v in ipairs(Datapad.RT_ReportsCache) do
                    local subName = tostring(v.subject_name  or "Desconocido")
                    local offName = tostring(v.officer_name  or "Oficial Central")
                    local offSID  = tostring(v.officer_steamid or "N/A")
                    local rText   = tostring(v.report_text   or "")

                    local card = scroll:Add("DButton")
                    card:SetText("") card:Dock(TOP) card:DockMargin(2, 0, 6, 10) card:SetTall(75)
                    card.Paint = function(s, w, h)
                        local hov = s:IsHovered()
                        draw.RoundedBox(6, 0, 0, w, h, hov and Color(30, 36, 51) or clrCardBg)
                        draw.RoundedBoxEx(6, 0, 0, 4, h, clrAccent, true, false, true, false)
                        surface.SetDrawColor(255, 255, 255, hov and 12 or 4)
                        surface.DrawOutlinedRect(0, 0, w, h, 1)
                        draw.SimpleText("SUJETO: " .. string.upper(subName), "RT_Header", 16, 14, clrText)
                        draw.SimpleText("OFICIAL: " .. offName,              "RT_Small",  16, 34, clrMuted)
                        local bodyClean = string.sub(string.gsub(rText, "\n", " "), 1, 75)
                        if #rText > 75 then bodyClean = bodyClean .. "..." end
                        draw.SimpleText(bodyClean, "RT_Body", 16, 50, Color(200, 205, 215))
                        local date = os.date("%d/%m/%y %H:%M", tonumber(v.timestamp) or os.time())
                        draw.SimpleText("#" .. (v.id or "?"), "RT_Header", w - 16, 14, Color(clrAccent.r, clrAccent.g, clrAccent.b, 150), TEXT_ALIGN_RIGHT)
                        draw.SimpleText(date,                 "RT_Small",  w - 16, 34, clrMuted, TEXT_ALIGN_RIGHT)
                    end

                    card.DoClick = function()
                        local f = vgui.Create("DFrame")
                        f:SetSize(480, 400) f:Center() f:MakePopup() f:SetTitle("") f:SetAlpha(0) f:AlphaTo(255, 0.15)
                        f.Paint = function(s, w, h)
                            draw.RoundedBox(8, 0, 0, w, h, clrBg)
                            draw.RoundedBoxEx(8, 0, 0, w, 45, clrCardBg, true, true, false, false)
                            surface.SetDrawColor(255, 255, 255, 4) surface.DrawRect(0, 44, w, 1)
                            draw.SimpleText("EXPEDIENTE TÁCTICO #" .. (v.id or "?"), "RT_Title", 16, 11, clrText)
                        end
                        local close = vgui.Create("DButton", f)
                        close:SetPos(443, 7) close:SetSize(30, 30) close:SetText("✕") close:SetFont("RT_Header") close:SetTextColor(clrMuted) close.Paint = function() end
                        close.DoClick = function() f:Close() end
                        close.OnCursorEntered = function(s) s:SetTextColor(Color(240, 70, 70)) end
                        close.OnCursorExited  = function(s) s:SetTextColor(clrMuted) end

                        local meta = vgui.Create("DPanel", f)
                        meta:Dock(TOP) meta:SetTall(50) meta:DockMargin(15, 60, 15, 0)
                        meta.Paint = function(s, w, h)
                            draw.SimpleText("IMPLICADO: " .. subName, "RT_Header", 0, 5,  clrText)
                            draw.SimpleText("REGISTRADO POR: " .. offName, "RT_Small", 0, 25, clrMuted)
                        end

                        local body = vgui.Create("DTextEntry", f)
                        body:Dock(FILL) body:DockMargin(15, 10, 15, 15) body:SetMultiline(true)
                        body:SetText(rText) body:SetEditable(false) body:SetFont("RT_Body") body:SetTextColor(color_white)
                        body.Paint = function(s, w, h)
                            draw.RoundedBox(6, 0, 0, w, h, Color(8, 9, 13))
                            surface.SetDrawColor(255, 255, 255, 4) surface.DrawOutlinedRect(0, 0, w, h, 1)
                            s:DrawTextEntryText(color_white, clrAccent, color_white)
                        end

                        local myID    = LocalPlayer():SteamID()
                        local isOwner = offSID == myID
                        local isStaff = Datapad.Config and Datapad:HasAccess(LocalPlayer(), Datapad.Config.StaffJobs)
                        if isOwner or isStaff then
                            local del = vgui.Create("DButton", f)
                            del:Dock(BOTTOM) del:DockMargin(15, 0, 15, 15) del:SetTall(35)
                            del:SetText("PURGAR INFORME DE LA RED") del:SetFont("RT_Header") del:SetTextColor(color_white)
                            del.Paint = function(s, w, h)
                                draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and Color(200, 45, 45) or Color(140, 35, 35))
                            end
                            del.DoClick = function()
                                net.Start("Datapad_DeleteRTReport") net.WriteInt(v.id, 32) net.SendToServer()
                                f:Close()
                            end
                        end
                    end
                end

                timer.Simple(0, function() if IsValid(scroll) then scroll:GetVBar():SetScroll(curScroll) end end)
            end

            PopulateReports()

            local hookUID = "Datapad_RT_" .. string.gsub(tostring(modulePanel), "[^%w]", "")
            hook.Add("Datapad_RefreshRTUI", hookUID, function()
                timer.Simple(0, function()
                    if not IsValid(modulePanel) then hook.Remove("Datapad_RefreshRTUI", hookUID) return end
                    PopulateReports()
                end)
            end)
            modulePanel.OnRemove = function() hook.Remove("Datapad_RefreshRTUI", hookUID) end
        end
    })
end
