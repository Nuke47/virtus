if not Datapad then return end

-- =========================================================================
-- [SERVIDOR] BACKEND ISB
-- =========================================================================
if SERVER then
    util.AddNetworkString("Datapad_RequestISBData")
    util.AddNetworkString("Datapad_SendISBData")
    util.AddNetworkString("Datapad_SaveISBReport")
    util.AddNetworkString("Datapad_UpdateISBReport")
    util.AddNetworkString("Datapad_DeleteISBReport")
    util.AddNetworkString("Datapad_SendISBMessage")
    util.AddNetworkString("Datapad_ISBTyping")
    util.AddNetworkString("Datapad_ISBIssueWarrant")
    util.AddNetworkString("Datapad_SendRTData")

    -- Tablas SQL
    sql.Query([[
        CREATE TABLE IF NOT EXISTS datapad_isb_reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operative_name TEXT, operative_steamid TEXT,
            subject_name TEXT, intel_text TEXT, timestamp INTEGER
        )
    ]])
    sql.Query([[
        CREATE TABLE IF NOT EXISTS datapad_isb_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender_name TEXT, sender_steamid TEXT,
            message_text TEXT, sender_model TEXT, timestamp INTEGER
        )
    ]])

    -- Columna sender_model si no existe (ALTER seguro con pcall)
    pcall(function()
        sql.Query("ALTER TABLE datapad_isb_messages ADD COLUMN sender_model TEXT")
    end)

    local function SyncISBDataToAll()
        local reports  = sql.Query("SELECT * FROM datapad_isb_reports ORDER BY id DESC LIMIT 50")  or {}
        local messages = sql.Query("SELECT * FROM datapad_isb_messages ORDER BY id DESC LIMIT 100") or {}
        net.Start("Datapad_SendISBData")
            net.WriteTable(reports)
            net.WriteTable(messages)
        net.Broadcast()
    end

    net.Receive("Datapad_RequestISBData", function(len, ply)
        if not IsValid(ply) then return end
        local reports  = sql.Query("SELECT * FROM datapad_isb_reports ORDER BY id DESC LIMIT 50")  or {}
        local messages = sql.Query("SELECT * FROM datapad_isb_messages ORDER BY id DESC LIMIT 100") or {}
        net.Start("Datapad_SendISBData")
            net.WriteTable(reports)
            net.WriteTable(messages)
        net.Send(ply)
    end)

    -- ─── Expedientes ──────────────────────────────────────────────────────
    net.Receive("Datapad_SaveISBReport", function(len, ply)
        if not IsValid(ply) then return end
        local subject = net.ReadString()
        local text    = net.ReadString()
        if subject == "" or text == "" then return end
        sql.Query(string.format(
            "INSERT INTO datapad_isb_reports (operative_name, operative_steamid, subject_name, intel_text, timestamp) VALUES (%s, %s, %s, %s, %d)",
            sql.SQLStr(ply:Nick()), sql.SQLStr(ply:SteamID()), sql.SQLStr(subject), sql.SQLStr(text), os.time()
        ))
        SyncISBDataToAll()
    end)

    net.Receive("Datapad_UpdateISBReport", function(len, ply)
        if not IsValid(ply) then return end
        local reportID = net.ReadInt(32)
        local subject  = net.ReadString()
        local text     = net.ReadString()
        if not reportID or subject == "" or text == "" then return end
        local check = sql.QueryRow(string.format("SELECT operative_steamid FROM datapad_isb_reports WHERE id = %d", reportID))
        if check then
            local isStaff = Datapad.Config and Datapad:HasAccess(ply, Datapad.Config.StaffJobs)
            if check.operative_steamid ~= ply:SteamID() and not isStaff then return end
        end
        sql.Query(string.format(
            "UPDATE datapad_isb_reports SET subject_name = %s, intel_text = %s WHERE id = %d",
            sql.SQLStr(subject), sql.SQLStr(text), reportID
        ))
        SyncISBDataToAll()
    end)

    net.Receive("Datapad_DeleteISBReport", function(len, ply)
        if not IsValid(ply) then return end
        local reportID = net.ReadInt(32)
        sql.Query(string.format("DELETE FROM datapad_isb_reports WHERE id = %d", reportID))
        SyncISBDataToAll()
    end)

    -- ─── Mensajería ───────────────────────────────────────────────────────
    net.Receive("Datapad_SendISBMessage", function(len, ply)
        if not IsValid(ply) then return end
        local text = net.ReadString()
        if text == "" then return end
        local currentModel = ply:GetModel() or "models/player/combine_soldier.mdl"
        sql.Query(string.format(
            "INSERT INTO datapad_isb_messages (sender_name, sender_steamid, message_text, sender_model, timestamp) VALUES (%s, %s, %s, %s, %d)",
            sql.SQLStr(ply:Nick()), sql.SQLStr(ply:SteamID()), sql.SQLStr(text), sql.SQLStr(currentModel), os.time()
        ))
        SyncISBDataToAll()
    end)

    -- ─── Typing indicator ─────────────────────────────────────────────────
    local typingAgents = {}
    net.Receive("Datapad_ISBTyping", function(len, ply)
        if not IsValid(ply) then return end
        local isTyping = net.ReadBool()
        local sid      = ply:SteamID()
        if isTyping then typingAgents[sid] = ply:Nick() else typingAgents[sid] = nil end
        net.Start("Datapad_ISBTyping")
            net.WriteTable(typingAgents)
        net.Broadcast()
    end)

    -- ─── Orden de arresto → RT ────────────────────────────────────────────
    net.Receive("Datapad_ISBIssueWarrant", function(len, ply)
        if not IsValid(ply) then return end
        local subject = net.ReadString()
        local reason  = net.ReadString()
        if subject == "" or reason == "" then return end

        local fullReason = "[DIRECTIVA ISB - PRIORIDAD MÁXIMA]\nSe ordena la detención inmediata del sujeto.\nMotivo: " .. reason
        local isbName    = "DIR. ISB: " .. ply:Nick()

        sql.Query(string.format(
            "INSERT INTO datapad_rt_reports (officer_name, officer_steamid, subject_name, report_text, timestamp) VALUES (%s, %s, %s, %s, %d)",
            sql.SQLStr(isbName), sql.SQLStr(ply:SteamID()), sql.SQLStr(subject), sql.SQLStr(fullReason), os.time()
        ))

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
    end)
end

-- =========================================================================
-- [CLIENTE] INTERFAZ ISB
-- =========================================================================
if CLIENT then
    Datapad.ISB_ReportsCache  = Datapad.ISB_ReportsCache  or {}
    Datapad.ISB_MessagesCache = Datapad.ISB_MessagesCache or {}
    Datapad.ISB_TypingCache   = Datapad.ISB_TypingCache   or {}

    net.Receive("Datapad_SendISBData", function()
        Datapad.ISB_ReportsCache  = net.ReadTable() or {}
        Datapad.ISB_MessagesCache = net.ReadTable() or {}
        hook.Run("Datapad_RefreshISBUI")
    end)

    net.Receive("Datapad_ISBTyping", function()
        Datapad.ISB_TypingCache = net.ReadTable() or {}
    end)

    -- ─── Fuentes ──────────────────────────────────────────────────────────
    surface.CreateFont("ISB_Title",  { font = "Montserrat", size = 20, weight = 800, antialias = true })
    surface.CreateFont("ISB_Bold",   { font = "Montserrat", size = 15, weight = 700, antialias = true })
    surface.CreateFont("ISB_Body",   { font = "Roboto",     size = 14, weight = 500, antialias = true })
    surface.CreateFont("ISB_Small",  { font = "Roboto",     size = 12, weight = 400, antialias = true, italic = true })
    surface.CreateFont("ISB_Header", { font = "Roboto",     size = 15, weight = 700, antialias = true })

    -- ─── Paleta ───────────────────────────────────────────────────────────
    local clrBg      = Color(10, 11, 15)
    local clrAccent  = Color(210, 40, 40)
    local clrCardBg  = Color(20, 22, 28)
    local clrBubbleL = Color(28, 31, 40)
    local clrBubbleR = Color(60, 18, 18)
    local clrText    = Color(240, 240, 245)
    local clrMuted   = Color(140, 145, 160)

    local function ISBScrollbar(sp)
        local sbar = sp:GetVBar()
        if not IsValid(sbar) then return end
        sbar:SetWide(6)
        sbar.Paint      = function() end
        sbar.btnUp.Paint  = function() end
        sbar.btnDown.Paint = function() end
        sbar.btnGrip.Paint = function(s, w, h)
            draw.RoundedBox(3, 0, 0, w, h, Color(clrAccent.r, clrAccent.g, clrAccent.b, s:IsHovered() and 200 or 100))
        end
    end

    -- ─── Chat ─────────────────────────────────────────────────────────────
    local function PopulateChatList(scroll, autoScrollBottom)
        scroll:Clear()

        if #Datapad.ISB_MessagesCache == 0 then
            local noData = scroll:Add("DLabel")
            noData:SetText("SIN TRANSMISIONES EN EL CANAL")
            noData:SetFont("ISB_Bold")
            noData:SetTextColor(Color(255, 255, 255, 25))
            noData:SetContentAlignment(5)
            noData:Dock(FILL)
            noData:DockMargin(0, 100, 0, 0)
            return
        end

        for i = #Datapad.ISB_MessagesCache, 1, -1 do
            local msg   = Datapad.ISB_MessagesCache[i]
            local isMe  = msg.sender_steamid == LocalPlayer():SteamID()

            local modelPath = msg.sender_model
            if not modelPath or modelPath == "" or modelPath == "NULL" then
                local targetPly = player.GetBySteamID(msg.sender_steamid or "")
                if IsValid(targetPly) and targetPly:GetModel() ~= "" then
                    modelPath = targetPly:GetModel()
                else
                    modelPath = "models/player/combine_soldier.mdl"
                end
            end

            local timeStr = os.date("%H:%M", tonumber(msg.timestamp) or os.time())
            local nameStr = tostring(msg.sender_name  or "Desconocido")
            local textStr = tostring(msg.message_text or "")

            local msgRow = scroll:Add("DPanel")
            msgRow:Dock(TOP)
            msgRow:DockMargin(10, 8, 10, 8)
            msgRow.Paint = function() end

            -- Calcular ancho de burbuja
            surface.SetFont("ISB_Body")
            local maxTextW = 320
            local textW, _ = surface.GetTextSize(textStr)
            local finalTextW = math.min(textW, maxTextW)

            surface.SetFont("ISB_Header")
            local nameW, _ = surface.GetTextSize(nameStr)
            local bubbleW = math.max(170, math.max(finalTextW, nameW) + 24)

            -- Calcular alto del texto
            local hCalc = vgui.Create("DLabel")
            hCalc:SetFont("ISB_Body")
            hCalc:SetText(textStr)
            hCalc:SetWrap(true)
            hCalc:SetWide(finalTextW)
            hCalc:SizeToContentsY()
            local txtH = math.max(16, hCalc:GetTall())
            hCalc:Remove()

            local bubbleH = txtH + 45
            msgRow:SetTall(math.max(bubbleH, 50))

            -- Avatar 3D
            local avatar = vgui.Create("DModelPanel", msgRow)
            avatar:SetSize(46, 46)
            avatar:SetModel(modelPath)
            if avatar.SetCamPos then
                avatar:SetCamPos(Vector(18, 0, 65))
                avatar:SetLookAt(Vector(0, 0, 64))
                avatar:SetFOV(30)
            end
            avatar:SetAnimated(false)
            avatar.LayoutEntity = function() end
            local oldPaint = avatar.Paint
            avatar.Paint = function(s, w, h)
                draw.RoundedBox(6, 0, 0, w, h, Color(12, 12, 15))
                oldPaint(s, w, h)
            end
            avatar.PaintOver = function(s, w, h)
                surface.SetDrawColor(isMe and clrAccent or clrMuted)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end

            -- Burbuja
            local bubble = vgui.Create("DPanel", msgRow)
            bubble:SetSize(bubbleW, bubbleH)

            local txtLabel = vgui.Create("DLabel", bubble)
            txtLabel:SetFont("ISB_Body")
            txtLabel:SetText(textStr)
            txtLabel:SetWrap(true)
            txtLabel:SetTextColor(clrText)
            txtLabel:SetSize(finalTextW, txtH)

            if isMe then
                txtLabel:SetPos(bubbleW - finalTextW - 12, 24)
                avatar:Dock(RIGHT) avatar:DockMargin(8, 0, 0, 0)
                bubble:Dock(RIGHT)
                bubble.Paint = function(s, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, Color(45, 15, 15))
                    surface.SetDrawColor(clrAccent.r, clrAccent.g, clrAccent.b, 60)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    draw.SimpleText(nameStr, "ISB_Header", w - 12, 5,    clrAccent, TEXT_ALIGN_RIGHT)
                    draw.SimpleText(timeStr, "ISB_Small",  12,     h-16, clrMuted,  TEXT_ALIGN_LEFT)
                end
            else
                txtLabel:SetPos(12, 24)
                avatar:Dock(LEFT) avatar:DockMargin(0, 0, 8, 0)
                bubble:Dock(LEFT)
                bubble.Paint = function(s, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, clrCardBg)
                    surface.SetDrawColor(255, 255, 255, 6)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    draw.SimpleText(nameStr, "ISB_Header", 12,     5,    clrAccent, TEXT_ALIGN_LEFT)
                    draw.SimpleText(timeStr, "ISB_Small",  w - 12, h-16, clrMuted,  TEXT_ALIGN_RIGHT)
                end
            end
        end

        if autoScrollBottom then
            timer.Simple(0.02, function()
                if IsValid(scroll) then
                    scroll:GetVBar():SetScroll(999999)
                end
            end)
        end
    end

    -- ─── Lista de expedientes ─────────────────────────────────────────────
    local function PopulateReportsList(scroll)
        local currentScroll = IsValid(scroll) and scroll:GetVBar():GetScroll() or 0
        scroll:Clear()

        if #Datapad.ISB_ReportsCache == 0 then
            local noData = scroll:Add("DLabel")
            noData:SetText("NO HAY EXPEDIENTES CLASIFICADOS")
            noData:SetFont("ISB_Bold")
            noData:SetTextColor(Color(255, 255, 255, 25))
            noData:SetContentAlignment(5)
            noData:Dock(FILL)
            noData:DockMargin(0, 100, 0, 0)
            return
        end

        for _, v in ipairs(Datapad.ISB_ReportsCache) do
            local subName   = tostring(v.subject_name    or "Desconocido")
            local opName    = tostring(v.operative_name  or "Agente ISB")
            local intelText = tostring(v.intel_text      or "")

            local card = scroll:Add("DButton")
            card:SetText("") card:Dock(TOP) card:DockMargin(15, 10, 15, 5) card:SetTall(85)
            card.Paint = function(s, w, h)
                local hov = s:IsHovered()
                draw.RoundedBox(8, 0, 0, w, h, hov and Color(30, 32, 40) or clrBubbleL)
                draw.RoundedBoxEx(8, 0, 0, 5, h, clrAccent, true, false, true, false)
                draw.SimpleText("OBJETIVO: " .. string.upper(subName), "ISB_Bold",   20, 12, clrText)
                draw.SimpleText("Agente: " .. opName,                  "ISB_Small",  20, 32, clrMuted)
                local body = string.sub(string.gsub(intelText, "\n", " "), 1, 85)
                if #intelText > 85 then body = body .. "..." end
                draw.SimpleText(body, "ISB_Body", 20, 55, Color(180, 185, 195))
                local date = os.date("%d/%m/%y %H:%M", tonumber(v.timestamp) or os.time())
                draw.SimpleText("EXP-" .. (v.id or "?"), "ISB_Title",  w - 20, 12, clrAccent, TEXT_ALIGN_RIGHT)
                draw.SimpleText(date,                     "ISB_Small",  w - 20, 35, clrMuted,  TEXT_ALIGN_RIGHT)
            end

            card.DoClick = function()
                local f = vgui.Create("DFrame")
                f:SetSize(520, 480) f:Center() f:MakePopup() f:SetTitle("") f:SetAlpha(0) f:AlphaTo(255, 0.15)
                f.Paint = function(s, w, h)
                    draw.RoundedBox(8, 0, 0, w, h, clrBg)
                    draw.RoundedBoxEx(8, 0, 0, w, 45, clrCardBg, true, true, false, false)
                    surface.SetDrawColor(clrAccent) surface.DrawRect(0, 44, w, 2)
                    draw.SimpleText("EXPEDIENTE DE INTELIGENCIA #" .. (v.id or "?"), "ISB_Title", 15, 12, clrText)
                end

                local close = vgui.Create("DButton", f)
                close:SetPos(482, 8) close:SetSize(30, 30) close:SetText("✕") close:SetFont("ISB_Bold") close:SetTextColor(color_white) close.Paint = function() end
                close.DoClick = function() f:Close() end

                local meta = vgui.Create("DPanel", f)
                meta:Dock(TOP) meta:SetTall(50) meta:DockMargin(20, 60, 20, 0)
                meta.Paint = function(s, w, h)
                    draw.SimpleText("SUJETO: " .. subName, "ISB_Bold",  0, 5,  clrAccent)
                    draw.SimpleText("CLASIFICADO POR: " .. opName, "ISB_Small", 0, 28, clrMuted)
                end

                local body = vgui.Create("DTextEntry", f)
                body:Dock(FILL) body:DockMargin(20, 10, 20, 20) body:SetMultiline(true)
                body:SetText(intelText) body:SetEditable(false)
                body:SetFont("ISB_Body") body:SetTextColor(color_white)
                body.Paint = function(s, w, h)
                    draw.RoundedBox(6, 0, 0, w, h, clrBubbleL)
                    s:DrawTextEntryText(clrText, clrAccent, clrText)
                end

                -- Botones de editar / borrar (solo autor o staff)
                local myID = LocalPlayer():SteamID()
                local isAuthor = tostring(v.operative_steamid or "") == myID
                local isStaff = Datapad.Config and Datapad:HasAccess(LocalPlayer(), Datapad.Config.StaffJobs)
                if isAuthor or isStaff then
                    local delBtn = vgui.Create("DButton", f)
                    delBtn:Dock(BOTTOM) delBtn:DockMargin(20, 0, 20, 15) delBtn:SetTall(35)
                    delBtn:SetText("ELIMINAR EXPEDIENTE") delBtn:SetFont("ISB_Bold") delBtn:SetTextColor(color_white)
                    delBtn.Paint = function(s, w, h)
                        draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and Color(200, 45, 45) or Color(140, 30, 30))
                    end
                    delBtn.DoClick = function()
                        net.Start("Datapad_DeleteISBReport") net.WriteInt(v.id, 32) net.SendToServer()
                        f:Close()
                    end
                end
            end
        end
        timer.Simple(0, function() if IsValid(scroll) then scroll:GetVBar():SetScroll(currentScroll) end end)
    end

    -- ─── Registro del módulo ──────────────────────────────────────────────
    Datapad:RegisterModule("isb_network", {
        Name  = "Inteligencia ISB",
        Icon  = "icon16/eye.png",
        Order = 3,
        CanAccess = function(ply)
            if not Datapad.Config or not Datapad.Config.ISBJobs then return true end
            return Datapad:HasAccess(ply, Datapad.Config.ISBJobs)
        end,

        UI = function(parent)
            net.Start("Datapad_RequestISBData") net.SendToServer()

            local modulePanel = vgui.Create("DPanel", parent)
            modulePanel:Dock(FILL)
            modulePanel.Paint = function() end

            local navBar = vgui.Create("DPanel", modulePanel)
            navBar:Dock(TOP) navBar:SetTall(50) navBar:DockMargin(15, 15, 15, 0)
            navBar.Paint = function() end

            local contentArea = vgui.Create("DPanel", modulePanel)
            contentArea:Dock(FILL) contentArea:DockMargin(15, 15, 15, 15)
            contentArea.Paint = function(s, w, h)
                draw.RoundedBox(8, 0, 0, w, h, clrCardBg)
                surface.SetDrawColor(255, 255, 255, 2)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end

            local activeTab = 1

            local function LoadTab()
                contentArea:Clear()

                local scroll = vgui.Create("DScrollPanel", contentArea)
                scroll:Dock(FILL)
                ISBScrollbar(scroll)
                contentArea.InternalScroll = scroll

                if activeTab == 1 then
                    -- ── PESTAÑA CHAT ──────────────────────────────────────
                    local bottomSection = vgui.Create("DPanel", contentArea)
                    bottomSection:Dock(BOTTOM) bottomSection:SetTall(68) bottomSection:DockMargin(15, 0, 15, 15)
                    bottomSection.Paint = function() end

                    local typingLabel = vgui.Create("DLabel", bottomSection)
                    typingLabel:Dock(TOP) typingLabel:SetTall(16)
                    typingLabel:SetFont("ISB_Small") typingLabel:SetTextColor(clrAccent)
                    typingLabel.Think = function(s)
                        local typists = {}
                        for sid, name in pairs(Datapad.ISB_TypingCache) do
                            if sid ~= LocalPlayer():SteamID() then table.insert(typists, name) end
                        end
                        if #typists == 1 then
                            s:SetText(typists[1] .. " está transmitiendo" .. string.rep(".", math.floor(CurTime() % 3) + 1))
                        elseif #typists > 1 then
                            s:SetText("Varios agentes transmitiendo" .. string.rep(".", math.floor(CurTime() % 3) + 1))
                        else
                            s:SetText("")
                        end
                    end

                    local entryRow = vgui.Create("DPanel", bottomSection)
                    entryRow:Dock(FILL) entryRow:DockMargin(0, 5, 0, 0) entryRow.Paint = function() end

                    local chatInput = vgui.Create("DTextEntry", entryRow)
                    chatInput:Dock(FILL) chatInput:SetFont("ISB_Body")
                    chatInput:SetPlaceholderText(" Escriba un mensaje encriptado...")
                    chatInput:SetTextColor(clrText) chatInput:SetCursorColor(clrAccent)
                    chatInput.Paint = function(s, w, h)
                        draw.RoundedBox(6, 0, 0, w, h, clrBg)
                        surface.SetDrawColor(s:HasFocus() and clrAccent or Color(255, 255, 255, 10))
                        surface.DrawOutlinedRect(0, 0, w, h, 1)
                        s:DrawTextEntryText(clrText, clrAccent, clrText)
                    end

                    local isTypingLocal = false
                    local typingTimerName = "ISB_Typing_" .. LocalPlayer():SteamID()
                    chatInput.OnChange = function(s)
                        local txt = s:GetText()
                        if txt ~= "" and not isTypingLocal then
                            isTypingLocal = true
                            net.Start("Datapad_ISBTyping") net.WriteBool(true) net.SendToServer()
                        elseif txt == "" and isTypingLocal then
                            isTypingLocal = false
                            net.Start("Datapad_ISBTyping") net.WriteBool(false) net.SendToServer()
                        end
                        if isTypingLocal then
                            timer.Create(typingTimerName, 3, 1, function()
                                isTypingLocal = false
                                net.Start("Datapad_ISBTyping") net.WriteBool(false) net.SendToServer()
                            end)
                        end
                    end

                    local btnSend = vgui.Create("DButton", entryRow)
                    btnSend:Dock(RIGHT) btnSend:SetWide(110) btnSend:DockMargin(10, 0, 0, 0)
                    btnSend:SetText("ENVIAR") btnSend:SetFont("ISB_Bold") btnSend:SetTextColor(clrText)
                    btnSend.Paint = function(s, w, h)
                        draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and clrAccent or Color(40, 15, 15))
                    end

                    local function SendMsg()
                        local txt = chatInput:GetText()
                        if txt == "" then return end
                        net.Start("Datapad_SendISBMessage") net.WriteString(txt) net.SendToServer()
                        chatInput:SetText("") chatInput:RequestFocus()
                        isTypingLocal = false
                        net.Start("Datapad_ISBTyping") net.WriteBool(false) net.SendToServer()
                    end
                    btnSend.DoClick = SendMsg
                    chatInput.OnEnter = SendMsg

                    PopulateChatList(scroll, true)

                elseif activeTab == 2 then
                    -- ── PESTAÑA EXPEDIENTES ───────────────────────────────
                    local btnAdd = vgui.Create("DButton", contentArea)
                    btnAdd:Dock(BOTTOM) btnAdd:SetTall(45) btnAdd:DockMargin(15, 10, 15, 15)
                    btnAdd:SetText("+ ABRIR NUEVO EXPEDIENTE") btnAdd:SetFont("ISB_Bold") btnAdd:SetTextColor(clrText)
                    btnAdd.Paint = function(s, w, h)
                        draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and clrAccent or clrBg)
                        if not s:IsHovered() then
                            surface.SetDrawColor(clrAccent) surface.DrawOutlinedRect(0, 0, w, h, 1)
                        end
                    end
                    btnAdd.DoClick = function()
                        local f = vgui.Create("DFrame")
                        f:SetSize(460, 390) f:Center() f:MakePopup() f:SetTitle("") f:SetAlpha(0) f:AlphaTo(255, 0.15)
                        f.Paint = function(s, w, h)
                            draw.RoundedBox(8, 0, 0, w, h, clrBg)
                            draw.RoundedBoxEx(8, 0, 0, w, 45, clrCardBg, true, true, false, false)
                            surface.SetDrawColor(clrAccent) surface.DrawRect(0, 44, w, 2)
                            draw.SimpleText("CLASIFICAR INTELIGENCIA", "ISB_Title", 15, 12, clrText)
                        end
                        local close2 = vgui.Create("DButton", f)
                        close2:SetPos(425, 8) close2:SetSize(30, 30) close2:SetText("✕") close2:SetFont("ISB_Bold") close2:SetTextColor(color_white) close2.Paint = function() end
                        close2.DoClick = function() f:Close() end

                        local sub = vgui.Create("DTextEntry", f)
                        sub:Dock(TOP) sub:SetTall(40) sub:DockMargin(20, 65, 20, 0)
                        sub:SetPlaceholderText(" Identificación del Objetivo...") sub:SetFont("ISB_Body")
                        sub.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, clrBubbleL) s:DrawTextEntryText(clrText, clrAccent, clrText) end

                        local txt = vgui.Create("DTextEntry", f)
                        txt:Dock(FILL) txt:SetMultiline(true) txt:DockMargin(20, 15, 20, 15)
                        txt:SetPlaceholderText(" Detalles de la operación...") txt:SetFont("ISB_Body")
                        txt.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, clrBubbleL) s:DrawTextEntryText(clrText, clrAccent, clrText) end

                        local sv = vgui.Create("DButton", f)
                        sv:Dock(BOTTOM) sv:SetTall(45) sv:DockMargin(20, 0, 20, 20)
                        sv:SetText("ARCHIVAR EN BASE DE DATOS") sv:SetFont("ISB_Bold") sv:SetTextColor(clrText)
                        sv.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and clrAccent or clrCardBg) end
                        sv.DoClick = function()
                            if sub:GetText() == "" or txt:GetText() == "" then return end
                            net.Start("Datapad_SaveISBReport")
                                net.WriteString(sub:GetText())
                                net.WriteString(txt:GetText())
                            net.SendToServer()
                            f:Close()
                        end
                    end
                    PopulateReportsList(scroll)
                end
            end

            -- Botones de navegación
            local btnChat = vgui.Create("DButton", navBar)
            btnChat:Dock(LEFT) btnChat:SetWide(180) btnChat:SetText("COMUNICACIÓN ISB") btnChat:SetFont("ISB_Bold")

            local btnReports = vgui.Create("DButton", navBar)
            btnReports:Dock(LEFT) btnReports:SetWide(150) btnReports:SetText("EXPEDIENTES") btnReports:SetFont("ISB_Bold")
            btnReports:DockMargin(5, 0, 0, 0)

            -- Botón emitir orden RT
            local btnWarrant = vgui.Create("DButton", navBar)
            btnWarrant:Dock(RIGHT) btnWarrant:SetWide(210) btnWarrant:SetText("[!] EMITIR ORDEN A RT")
            btnWarrant:SetFont("ISB_Bold") btnWarrant:SetTextColor(clrText)
            btnWarrant.Paint = function(s, w, h)
                draw.RoundedBox(6, 0, 8, w, h - 8, s:IsHovered() and Color(255, 60, 60) or clrAccent)
            end
            btnWarrant.DoClick = function()
                local f = vgui.Create("DFrame")
                f:SetSize(460, 310) f:Center() f:MakePopup() f:SetTitle("") f:SetAlpha(0) f:AlphaTo(255, 0.15)
                f.Paint = function(s, w, h)
                    draw.RoundedBox(8, 0, 0, w, h, clrBg)
                    draw.RoundedBoxEx(8, 0, 0, w, 45, Color(150, 30, 30), true, true, false, false)
                    draw.SimpleText("EMITIR ORDEN A RED TÁCTICA", "ISB_Title", 15, 12, clrText)
                end
                local close3 = vgui.Create("DButton", f)
                close3:SetPos(425, 8) close3:SetSize(30, 30) close3:SetText("✕") close3:SetFont("ISB_Bold") close3:SetTextColor(color_white) close3.Paint = function() end
                close3.DoClick = function() f:Close() end

                local sub = vgui.Create("DTextEntry", f)
                sub:Dock(TOP) sub:SetTall(40) sub:DockMargin(20, 65, 20, 0)
                sub:SetPlaceholderText(" Nombre del Implicado...") sub:SetFont("ISB_Body")
                sub.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, clrBubbleL) s:DrawTextEntryText(clrText, clrAccent, clrText) end

                local txt = vgui.Create("DTextEntry", f)
                txt:Dock(FILL) txt:SetMultiline(true) txt:DockMargin(20, 15, 20, 15)
                txt:SetPlaceholderText(" Motivo del arresto (llegará directo a las tropas)...") txt:SetFont("ISB_Body")
                txt.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, clrBubbleL) s:DrawTextEntryText(clrText, clrAccent, clrText) end

                local sv = vgui.Create("DButton", f)
                sv:Dock(BOTTOM) sv:SetTall(45) sv:DockMargin(20, 0, 20, 20)
                sv:SetText("TRANSMITIR ORDEN GLOBAL") sv:SetFont("ISB_Bold") sv:SetTextColor(clrText)
                sv.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and Color(200, 50, 50) or Color(150, 30, 30)) end
                sv.DoClick = function()
                    if sub:GetText() == "" or txt:GetText() == "" then return end
                    net.Start("Datapad_ISBIssueWarrant")
                        net.WriteString(sub:GetText())
                        net.WriteString(txt:GetText())
                    net.SendToServer()
                    f:Close()
                end
            end

            local function UpdateTabColors()
                btnChat.Paint = function(s, w, h)
                    local act = activeTab == 1
                    draw.RoundedBoxEx(8, 0, 10, w, h - 10, act and clrCardBg or clrBg, true, true, false, false)
                    s:SetTextColor(act and clrText or clrMuted)
                end
                btnReports.Paint = function(s, w, h)
                    local act = activeTab == 2
                    draw.RoundedBoxEx(8, 0, 10, w, h - 10, act and clrCardBg or clrBg, true, true, false, false)
                    s:SetTextColor(act and clrText or clrMuted)
                end
            end

            btnChat.DoClick    = function() activeTab = 1 UpdateTabColors() LoadTab() end
            btnReports.DoClick = function() activeTab = 2 UpdateTabColors() LoadTab() end

            UpdateTabColors()
            LoadTab()

            -- Hook de refresco automático
            local hookUID = "Datapad_ISB_" .. string.gsub(tostring(modulePanel), "[^%w]", "")
            hook.Add("Datapad_RefreshISBUI", hookUID, function()
                timer.Simple(0, function()
                    if not IsValid(modulePanel) then hook.Remove("Datapad_RefreshISBUI", hookUID) return end
                    if not IsValid(contentArea.InternalScroll) then return end
                    if activeTab == 1 then
                        PopulateChatList(contentArea.InternalScroll, false)
                    else
                        PopulateReportsList(contentArea.InternalScroll)
                    end
                end)
            end)
            modulePanel.OnRemove = function() hook.Remove("Datapad_RefreshISBUI", hookUID) end
        end
    })
end
