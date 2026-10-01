if not Datapad then return end

-- =========================================================================
-- MÓDULO: BASE DE DATOS 65th / SHOCKTROOPERS
-- Registro permanente de arrestos por nombre de jugador y job
-- =========================================================================

if SERVER then
    util.AddNetworkString("Datapad_RequestShockData")
    util.AddNetworkString("Datapad_SendShockData")
    util.AddNetworkString("Datapad_ShockAddArrest")
    util.AddNetworkString("Datapad_ShockDeleteArrest")

    -- Tabla principal: un registro por arresto, permanente
    sql.Query([[
        CREATE TABLE IF NOT EXISTS datapad_shock_arrests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            criminal_name TEXT,
            criminal_job  TEXT,
            cop_name      TEXT,
            reason        TEXT,
            jail_time     INTEGER,
            timestamp     INTEGER
        )
    ]])

    local function SyncShockDataToAll()
        local arrests = sql.Query("SELECT * FROM datapad_shock_arrests ORDER BY id DESC LIMIT 200") or {}
        net.Start("Datapad_SendShockData")
            net.WriteTable(arrests)
        net.Broadcast()
    end

    net.Receive("Datapad_RequestShockData", function(len, ply)
        if not IsValid(ply) then return end
        local arrests = sql.Query("SELECT * FROM datapad_shock_arrests ORDER BY id DESC LIMIT 200") or {}
        net.Start("Datapad_SendShockData")
            net.WriteTable(arrests)
        net.Send(ply)
    end)

    -- ─── Registro manual de arresto ───────────────────────────────────────
    net.Receive("Datapad_ShockAddArrest", function(len, ply)
        if not IsValid(ply) then return end
        local crimName = net.ReadString()
        local crimJob  = net.ReadString()
        local reason   = net.ReadString()
        local jailTime = net.ReadInt(32)
        if crimName == "" or reason == "" then return end

        sql.Query(string.format(
            "INSERT INTO datapad_shock_arrests (criminal_name, criminal_job, cop_name, reason, jail_time, timestamp) VALUES (%s, %s, %s, %s, %d, %d)",
            sql.SQLStr(crimName), sql.SQLStr(crimJob), sql.SQLStr(ply:Nick()), sql.SQLStr(reason), jailTime, os.time()
        ))
        SyncShockDataToAll()
    end)

    -- ─── Borrar registro (solo staff) ─────────────────────────────────────
    net.Receive("Datapad_ShockDeleteArrest", function(len, ply)
        if not IsValid(ply) then return end
        if not ply:IsSuperAdmin() then return end
        local arrestID = net.ReadInt(32)
        sql.Query(string.format("DELETE FROM datapad_shock_arrests WHERE id = %d", arrestID))
        SyncShockDataToAll()
    end)

    -- ─── Auto-registro via hook DarkRP playerArrested ─────────────────────
    hook.Add("playerArrested", "Datapad_ShockAutoArrest", function(ply, time, arrester)
        if not IsValid(ply) then return end
        local copName  = (IsValid(arrester) and arrester:IsPlayer()) and arrester:Nick() or "Sistema"
        local crimName = ply:Nick()
        local crimJob  = team.GetName(ply:Team()) or "Desconocido"
        local jailTime = tonumber(time) or 0

        sql.Query(string.format(
            "INSERT INTO datapad_shock_arrests (criminal_name, criminal_job, cop_name, reason, jail_time, timestamp) VALUES (%s, %s, %s, %s, %d, %d)",
            sql.SQLStr(crimName), sql.SQLStr(crimJob), sql.SQLStr(copName),
            sql.SQLStr("[ARRESTO AUTOMÁTICO - Sin motivo especificado]"), jailTime, os.time()
        ))
        SyncShockDataToAll()
    end)
end

-- =========================================================================
-- [CLIENTE] INTERFAZ SHOCKTROOPERS / 65th
-- =========================================================================
if CLIENT then
    Datapad.Shock_ArrestsCache = Datapad.Shock_ArrestsCache or {}

    net.Receive("Datapad_SendShockData", function()
        Datapad.Shock_ArrestsCache = net.ReadTable() or {}
        hook.Run("Datapad_RefreshShockUI")
    end)

    -- ─── Fuentes ──────────────────────────────────────────────────────────
    surface.CreateFont("Shock_Title",  { font = "Roboto", size = 22, weight = 800, antialias = true })
    surface.CreateFont("Shock_Header", { font = "Roboto", size = 15, weight = 700, antialias = true })
    surface.CreateFont("Shock_Body",   { font = "Roboto", size = 13, weight = 500, antialias = true })
    surface.CreateFont("Shock_Small",  { font = "Roboto", size = 11, weight = 400, antialias = true })
    surface.CreateFont("Shock_Big",    { font = "Roboto", size = 28, weight = 800, antialias = true })

    -- ─── Paleta 65th / Shock (azul imperial) ─────────────────────────────
    local clrBg      = Color(10, 12, 18)
    local clrAccent  = Color(30, 120, 220)
    local clrCardBg  = Color(18, 22, 32)
    local clrText    = Color(220, 228, 245)
    local clrMuted   = Color(130, 140, 165)
    local clrGold    = Color(200, 160, 50)
    local clrRed     = Color(220, 50, 50)

    local function ShockScrollbar(sp)
        local sbar = sp:GetVBar()
        if not IsValid(sbar) then return end
        sbar:SetWide(5)
        sbar.Paint = function() end sbar.btnUp.Paint = function() end sbar.btnDown.Paint = function() end
        sbar.btnGrip.Paint = function(s, w, h)
            draw.RoundedBox(3, 0, 0, w, h, Color(clrAccent.r, clrAccent.g, clrAccent.b, s:IsHovered() and 200 or 100))
        end
    end

    -- ─── Función de búsqueda / filtrado ──────────────────────────────────
    local searchFilter = ""

    local function GetFilteredArrests()
        if searchFilter == "" then return Datapad.Shock_ArrestsCache end
        local filtered = {}
        local query = string.lower(searchFilter)
        for _, v in ipairs(Datapad.Shock_ArrestsCache) do
            local name = string.lower(tostring(v.criminal_name or ""))
            local job  = string.lower(tostring(v.criminal_job  or ""))
            if string.find(name, query, 1, true) or string.find(job, query, 1, true) then
                table.insert(filtered, v)
            end
        end
        return filtered
    end

    -- ─── Contar arrestos por persona ─────────────────────────────────────
    local function CountByName(name)
        local count = 0
        for _, v in ipairs(Datapad.Shock_ArrestsCache) do
            if tostring(v.criminal_name or "") == name then count = count + 1 end
        end
        return count
    end

    -- ─── Vista de perfil de detenido ──────────────────────────────────────
    local function OpenProfile(crimName)
        local records = {}
        for _, v in ipairs(Datapad.Shock_ArrestsCache) do
            if tostring(v.criminal_name or "") == crimName then
                table.insert(records, v)
            end
        end

        local f = vgui.Create("DFrame")
        f:SetSize(580, 520) f:Center() f:MakePopup() f:SetTitle("") f:SetAlpha(0) f:AlphaTo(255, 0.15)
        f.Paint = function(s, w, h)
            draw.RoundedBox(8, 0, 0, w, h, clrBg)
            draw.RoundedBoxEx(8, 0, 0, w, 55, clrCardBg, true, true, false, false)
            surface.SetDrawColor(clrAccent) surface.DrawRect(0, 54, w, 2)
            draw.SimpleText("EXPEDIENTE DE DETENIDO", "Shock_Title", 18, 10, clrText)
            draw.SimpleText(crimName,                 "Shock_Title", 18, 30, clrAccent)
            draw.SimpleText(#records .. " arresto(s) registrado(s)", "Shock_Header", w - 18, 20, clrGold, TEXT_ALIGN_RIGHT)
        end

        local close = vgui.Create("DButton", f)
        close:SetPos(545, 10) close:SetSize(28, 28) close:SetText("✕") close:SetFont("Shock_Header") close:SetTextColor(clrMuted) close.Paint = function() end
        close.DoClick = function() f:Close() end

        local scroll = vgui.Create("DScrollPanel", f)
        scroll:Dock(FILL) scroll:DockMargin(15, 70, 15, 15)
        ShockScrollbar(scroll)

        if #records == 0 then
            local noData = scroll:Add("DLabel")
            noData:SetText("Sin registros") noData:SetFont("Shock_Body")
            noData:SetTextColor(Color(255, 255, 255, 25)) noData:SetContentAlignment(5)
            noData:Dock(FILL) noData:DockMargin(0, 80, 0, 0)
            return
        end

        for i, v in ipairs(records) do
            local reasonText = tostring(v.reason    or "Sin motivo especificado")
            local copName    = tostring(v.cop_name  or "Sistema")
            local jobText    = tostring(v.criminal_job or "Desconocido")
            local jailSec    = tonumber(v.jail_time) or 0
            local dateStr    = os.date("%d/%m/%Y %H:%M", tonumber(v.timestamp) or os.time())

            local isAuto  = string.find(reasonText, "AUTOMÁTICO", 1, true) ~= nil

            local card = scroll:Add("DPanel")
            card:Dock(TOP) card:DockMargin(0, 0, 6, 10)

            -- Calcular altura del texto del motivo
            local hCalc = vgui.Create("DLabel")
            hCalc:SetFont("Shock_Body") hCalc:SetText(reasonText) hCalc:SetWrap(true) hCalc:SetWide(490)
            hCalc:SizeToContentsY()
            local reasonH = math.max(16, hCalc:GetTall())
            hCalc:Remove()
            card:SetTall(reasonH + 68)

            card.Paint = function(s, w, h)
                draw.RoundedBox(6, 0, 0, w, h, clrCardBg)
                draw.RoundedBoxEx(6, 0, 0, 4, h, isAuto and clrMuted or clrAccent, true, false, true, false)
                surface.SetDrawColor(255, 255, 255, 3) surface.DrawOutlinedRect(0, 0, w, h, 1)

                -- Número de orden
                draw.SimpleText("ARRESTO #" .. (v.id or i), "Shock_Header", 16, 10, isAuto and clrMuted or clrAccent)
                draw.SimpleText("Job: " .. jobText, "Shock_Small", 16, 28, clrMuted)

                draw.SimpleText("Oficial: " .. copName,   "Shock_Small",  w - 16, 10, clrMuted,  TEXT_ALIGN_RIGHT)
                draw.SimpleText(dateStr,                   "Shock_Small",  w - 16, 26, clrMuted,  TEXT_ALIGN_RIGHT)
                if jailSec > 0 then
                    draw.SimpleText("Condena: " .. jailSec .. "s", "Shock_Small", w - 16, 42, clrGold, TEXT_ALIGN_RIGHT)
                end

                draw.SimpleText("MOTIVO:", "Shock_Small", 16, 46, Color(150, 160, 180))
            end

            local lblReason = vgui.Create("DLabel", card)
            lblReason:SetFont("Shock_Body") lblReason:SetText(reasonText)
            lblReason:SetTextColor(clrText) lblReason:SetWrap(true)
            lblReason:SetPos(16, 60) lblReason:SetSize(card:GetWide() - 32, reasonH)

            -- Botón borrar (solo staff)
            local isStaff = Datapad.Config and Datapad:HasAccess(LocalPlayer(), Datapad.Config.StaffJobs)
            if isStaff and v.id then
                local delBtn = vgui.Create("DButton", card)
                delBtn:SetSize(22, 22)
                delBtn:SetPos(card:GetWide() - 30, 60)
                delBtn:SetText("🗑") delBtn:SetFont("Shock_Small") delBtn:SetTextColor(clrRed)
                delBtn.Paint = function(s, w, h)
                    if s:IsHovered() then draw.RoundedBox(4, 0, 0, w, h, Color(80, 20, 20)) end
                end
                delBtn.DoClick = function()
                    net.Start("Datapad_ShockDeleteArrest") net.WriteInt(v.id, 32) net.SendToServer()
                    f:Close()
                end
            end
        end
    end

    -- ─── Registro del módulo ──────────────────────────────────────────────
    Datapad:RegisterModule("shock_db", {
        Name  = "Base de Datos 65th",
        Icon  = "icon16/database.png",
        Order = 4,
        CanAccess = function(ply)
            if not Datapad.Config or not Datapad.Config.ShockJobs then return true end
            return Datapad:HasAccess(ply, Datapad.Config.ShockJobs)
        end,

        UI = function(parent)
            net.Start("Datapad_RequestShockData") net.SendToServer()
            searchFilter = ""

            local modulePanel = vgui.Create("DPanel", parent)
            modulePanel:Dock(FILL)
            modulePanel.Paint = function() end

            -- ── Barra superior ────────────────────────────────────────────
            local topBar = vgui.Create("DPanel", modulePanel)
            topBar:Dock(TOP) topBar:SetTall(60) topBar:DockMargin(15, 15, 15, 5)
            topBar.Paint = function(s, w, h)
                draw.RoundedBox(6, 0, 0, w, h, clrCardBg)
                surface.SetDrawColor(clrAccent) surface.DrawRect(0, h - 2, w, 2)
                draw.SimpleText("BASE DE DATOS 65th SHOCKTROOPERS", "Shock_Header", 15, 12, clrAccent)
            end

            -- Buscador
            local searchEntry = vgui.Create("DTextEntry", topBar)
            searchEntry:Dock(RIGHT) searchEntry:SetWide(280) searchEntry:DockMargin(0, 8, 10, 8)
            searchEntry:SetFont("Shock_Body") searchEntry:SetPlaceholderText(" 🔍  Buscar por nombre o rango...")
            searchEntry.Paint = function(s, w, h)
                draw.RoundedBox(6, 0, 0, w, h, Color(12, 15, 22))
                surface.SetDrawColor(s:HasFocus() and clrAccent or Color(255, 255, 255, 8))
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                s:DrawTextEntryText(clrText, clrAccent, clrText)
            end

            -- Botón registro manual
            local btnAdd = vgui.Create("DButton", topBar)
            btnAdd:Dock(RIGHT) btnAdd:SetWide(220) btnAdd:DockMargin(0, 8, 8, 8)
            btnAdd:SetText("+ REGISTRAR ARRESTO") btnAdd:SetFont("Shock_Header") btnAdd:SetTextColor(clrText)
            btnAdd.Paint = function(s, w, h)
                draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and clrAccent or Color(20, 50, 100))
                if not s:IsHovered() then
                    surface.SetDrawColor(clrAccent) surface.DrawOutlinedRect(0, 0, w, h, 1)
                end
            end

            -- ── Panel de estadísticas ─────────────────────────────────────
            local statsBar = vgui.Create("DPanel", modulePanel)
            statsBar:Dock(TOP) statsBar:SetTall(38) statsBar:DockMargin(15, 0, 15, 5)
            statsBar.Paint = function(s, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(14, 17, 26))
                local total = #Datapad.Shock_ArrestsCache
                local unique = {}
                for _, v in ipairs(Datapad.Shock_ArrestsCache) do
                    unique[v.criminal_name or "?"] = true
                end
                local uCount = 0
                for _ in pairs(unique) do uCount = uCount + 1 end
                draw.SimpleText("TOTAL DE ARRESTOS: " .. total, "Shock_Body", 15, 10, clrText)
                draw.SimpleText("DETENIDOS ÚNICOS: " .. uCount, "Shock_Body", 220, 10, clrMuted)
            end

            -- ── Scroll de lista ───────────────────────────────────────────
            local listScroll = vgui.Create("DScrollPanel", modulePanel)
            listScroll:Dock(FILL) listScroll:DockMargin(15, 0, 15, 15)
            ShockScrollbar(listScroll)

            local function RefreshList()
                local curScroll = IsValid(listScroll) and listScroll:GetVBar():GetScroll() or 0
                listScroll:Clear()

                local filtered = GetFilteredArrests()

                if #filtered == 0 then
                    local noData = listScroll:Add("DLabel")
                    noData:SetText(searchFilter ~= "" and "SIN RESULTADOS PARA: " .. searchFilter or "NO HAY ARRESTOS REGISTRADOS")
                    noData:SetFont("Shock_Header") noData:SetTextColor(Color(255, 255, 255, 20))
                    noData:SetContentAlignment(5) noData:Dock(FILL) noData:DockMargin(0, 100, 0, 0)
                    return
                end

                -- Agrupar por nombre para mostrar contador de reincidencia
                local nameCount = {}
                for _, v in ipairs(Datapad.Shock_ArrestsCache) do
                    local n = tostring(v.criminal_name or "?")
                    nameCount[n] = (nameCount[n] or 0) + 1
                end

                for _, v in ipairs(filtered) do
                    local crimName  = tostring(v.criminal_name or "Desconocido")
                    local crimJob   = tostring(v.criminal_job  or "Desconocido")
                    local copName   = tostring(v.cop_name      or "Sistema")
                    local reasonStr = tostring(v.reason        or "Sin motivo")
                    local jailSec   = tonumber(v.jail_time)    or 0
                    local dateStr   = os.date("%d/%m/%Y %H:%M", tonumber(v.timestamp) or os.time())
                    local totalArrests = nameCount[crimName] or 1
                    local isAuto  = string.find(reasonStr, "AUTOMÁTICO", 1, true) ~= nil
                    local isRecid = totalArrests >= 3

                    local row = listScroll:Add("DButton")
                    row:SetText("") row:Dock(TOP) row:DockMargin(2, 0, 6, 6) row:SetTall(58)
                    row.Paint = function(s, w, h)
                        local hov = s:IsHovered()
                        draw.RoundedBox(5, 0, 0, w, h, hov and Color(22, 28, 45) or clrCardBg)

                        -- Barra lateral de color según reincidencia
                        local barColor = isRecid and clrRed or (isAuto and clrMuted or clrAccent)
                        draw.RoundedBoxEx(5, 0, 0, 4, h, barColor, true, false, true, false)

                        -- Nombre y job
                        draw.SimpleText(crimName, "Shock_Header", 18, 8,  clrText)
                        draw.SimpleText(crimJob,  "Shock_Small",  18, 26, clrMuted)

                        -- Motivo corto
                        local shortReason = string.sub(string.gsub(reasonStr, "\n", " "), 1, 60)
                        if #reasonStr > 60 then shortReason = shortReason .. "..." end
                        draw.SimpleText(shortReason, "Shock_Small", 18, 42, Color(160, 165, 185))

                        -- Fecha y oficial
                        draw.SimpleText(dateStr, "Shock_Small",  w - 16, 8,  clrMuted,  TEXT_ALIGN_RIGHT)
                        draw.SimpleText("Oficial: " .. copName, "Shock_Small", w - 16, 24, clrMuted, TEXT_ALIGN_RIGHT)

                        -- Badge de reincidencia
                        if isRecid then
                            local badgeW = 90
                            draw.RoundedBox(4, w - badgeW - 16, 40, badgeW, 14, Color(180, 30, 30, 180))
                            draw.SimpleText("⚠ REINCIDENTE x" .. totalArrests, "Shock_Small", w - 16 - badgeW/2, 47, color_white, TEXT_ALIGN_CENTER)
                        end

                        -- Condena
                        if jailSec > 0 then
                            local jailW = 80
                            draw.SimpleText(jailSec .. "s", "Shock_Small", w - 16, 41, clrGold, TEXT_ALIGN_RIGHT)
                        end

                        surface.SetDrawColor(255, 255, 255, 2) surface.DrawOutlinedRect(0, 0, w, h, 1)
                    end

                    row.DoClick = function() OpenProfile(crimName) end
                end

                timer.Simple(0, function() if IsValid(listScroll) then listScroll:GetVBar():SetScroll(curScroll) end end)
            end

            -- Búsqueda en tiempo real
            searchEntry.OnChange = function(s)
                searchFilter = s:GetText()
                RefreshList()
            end

            -- Formulario de registro manual
            btnAdd.DoClick = function()
                local f = vgui.Create("DFrame")
                f:SetSize(500, 420) f:Center() f:MakePopup() f:SetTitle("") f:SetAlpha(0) f:AlphaTo(255, 0.15)
                f.Paint = function(s, w, h)
                    draw.RoundedBox(8, 0, 0, w, h, clrBg)
                    draw.RoundedBoxEx(8, 0, 0, w, 48, clrCardBg, true, true, false, false)
                    surface.SetDrawColor(clrAccent) surface.DrawRect(0, 47, w, 2)
                    draw.SimpleText("REGISTRAR NUEVO ARRESTO", "Shock_Title", 18, 12, clrText)
                end
                local close = vgui.Create("DButton", f)
                close:SetPos(465, 10) close:SetSize(28, 28) close:SetText("✕") close:SetFont("Shock_Header") close:SetTextColor(clrMuted) close.Paint = function() end
                close.DoClick = function() f:Close() end

                local function MakeField(parent, label, placeholder, y, h)
                    local lbl = vgui.Create("DLabel", parent)
                    lbl:SetPos(20, y) lbl:SetSize(460, 18)
                    lbl:SetText(label) lbl:SetFont("Shock_Small") lbl:SetTextColor(Color(140, 160, 200))

                    local ent = vgui.Create("DTextEntry", parent)
                    ent:SetPos(20, y + 20) ent:SetSize(460, h or 36)
                    if (h or 36) > 36 then ent:SetMultiline(true) end
                    ent:SetFont("Shock_Body") ent:SetPlaceholderText(" " .. placeholder)
                    ent.Paint = function(s, w, h2)
                        draw.RoundedBox(6, 0, 0, w, h2, Color(14, 17, 25))
                        surface.SetDrawColor(s:HasFocus() and clrAccent or Color(255, 255, 255, 6))
                        surface.DrawOutlinedRect(0, 0, w, h2, 1)
                        s:DrawTextEntryText(clrText, clrAccent, clrText)
                    end
                    return ent
                end

                local entName   = MakeField(f, "Nombre del detenido:",  "Ej: CT-1234 Tano",           66, 36)
                local entJob    = MakeField(f, "Rango / Unidad:",        "Ej: Médico de la 104th",    128, 36)
                local entReason = MakeField(f, "Motivo del arresto:",    "Descripción detallada...",  190, 90)
                local entTime   = MakeField(f, "Tiempo de condena (segundos, 0 si no aplica):", "Ej: 120", 306, 36)

                local sv = vgui.Create("DButton", f)
                sv:SetPos(20, 360) sv:SetSize(460, 42)
                sv:SetText("REGISTRAR EN BASE DE DATOS") sv:SetFont("Shock_Header") sv:SetTextColor(clrText)
                sv.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and clrAccent or Color(20, 50, 100)) end
                sv.DoClick = function()
                    local name   = entName:GetText()
                    local job    = entJob:GetText()
                    local reason = entReason:GetText()
                    local jt     = tonumber(entTime:GetText()) or 0
                    if name == "" or reason == "" then return end
                    net.Start("Datapad_ShockAddArrest")
                        net.WriteString(name)
                        net.WriteString(job)
                        net.WriteString(reason)
                        net.WriteInt(jt, 32)
                    net.SendToServer()
                    f:Close()
                end
            end

            RefreshList()

            local hookUID = "Datapad_Shock_" .. string.gsub(tostring(modulePanel), "[^%w]", "")
            hook.Add("Datapad_RefreshShockUI", hookUID, function()
                timer.Simple(0, function()
                    if not IsValid(modulePanel) then hook.Remove("Datapad_RefreshShockUI", hookUID) return end
                    statsBar:InvalidateLayout(true)
                    RefreshList()
                end)
            end)
            modulePanel.OnRemove = function() hook.Remove("Datapad_RefreshShockUI", hookUID) end
        end
    })
end
