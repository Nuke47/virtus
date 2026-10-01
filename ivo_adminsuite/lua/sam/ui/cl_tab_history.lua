-- ============================================================================
-- IVOSAM: TAB HISTORIAL DE BANEOS — PREMIUM UI
-- ============================================================================

function IVO_SAM_LoadBans(bList)
    if not IsValid(bList) then return end
    bList:Clear()

    local datosBaneos = IVO_SAM.ServerBansData or {}
    for _, v in ipairs(datosBaneos) do
        local unbanTime = tonumber(v.unban_date) or tonumber(v.unban_time) or 0
        local exp = (unbanTime == 0) and "Nunca (Permaban)" or os.date("%d/%m/%y %H:%M", unbanTime)
        local targetName = v.name or v.target_name or "Desconocido"
        local steamID = v.steamid or v.target_sid or "STEAM_0:X"
        local adminName = v.admin or v.admin_name or "Console"

        local line = bList:AddLine(targetName, steamID, adminName, exp)
        for _, col in pairs(line.Columns) do 
            col:SetFont("IVOSAM_Normal")
            col:SetTextColor(IVO_SAM.Theme.TextMain)
        end
        line.Paint = function(s, w, h)
            local isSelected = s:IsSelected()
            local isHovered = s:IsHovered()

            if isSelected then 
                draw.RoundedBox(0, 0, 0, w, h, IVO_SAM.Theme.AccentGlow)
            elseif isHovered then 
                draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 5))
            end
            
            surface.SetDrawColor(255, 255, 255, 5)
            surface.DrawRect(0, h - 1, w, 1)
        end
    end
end

function IVOSAM_BuildHistoryTab(tabPanel)
    tabPanel.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
    end

    local topPanel = vgui.Create("DPanel", tabPanel)
    topPanel:Dock(TOP)
    topPanel:SetTall(60)
    topPanel:DockMargin(20, 20, 20, 10)
    topPanel.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, IVO_SAM.Theme.BgTop)
        draw.RoundedBoxEx(8, 0, 0, 6, h, Color(220, 50, 50), true, false, true, false)
        draw.SimpleText("REGISTRO DE BANEOS", "IVOSAM_Title", 20, h/2 - 12, IVO_SAM.Theme.TextMain, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Historial de sanciones activas en el servidor", "IVOSAM_Normal", 20, h/2 + 10, IVO_SAM.Theme.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local listBg = vgui.Create("DPanel", tabPanel)
    listBg:Dock(FILL)
    listBg:DockMargin(20, 10, 20, 15)
    listBg.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, IVO_SAM.Theme.CardBg)
    end

    local bList = vgui.Create("DListView", listBg)
    bList.EsListaBaneos = true
    bList:Dock(FILL)
    bList:DockMargin(10, 10, 10, 10)
    bList:SetMultiSelect(false)
    bList:SetHideHeaders(false)
    bList:SetDataHeight(35)
    bList:SetHeaderHeight(30)
    
    bList:AddColumn("Jugador"):SetFixedWidth(200)
    bList:AddColumn("SteamID"):SetFixedWidth(160)
    bList:AddColumn("Admin")
    bList:AddColumn("Expiración"):SetFixedWidth(180)
    
    bList.Paint = function(s, w, h) end

    for _, header in pairs(bList.Columns) do
        header.Header:SetTextColor(IVO_SAM.Theme.TextMuted)
        header.Header:SetFont("IVOSAM_Bold")
        header.Header.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(15, 15, 20))
        end
    end

    local btnPanel = vgui.Create("DPanel", tabPanel)
    btnPanel:SetSize(0, 55)
    btnPanel:Dock(BOTTOM)
    btnPanel:DockMargin(20, 0, 20, 20)
    btnPanel.Paint = nil

    local btnUnban = vgui.Create("DButton", btnPanel)
    btnUnban:SetSize(200, 55)
    btnUnban:Dock(LEFT)
    btnUnban:SetText("DESBANEAR JUGADOR")
    btnUnban:SetFont("IVOSAM_Bold")
    btnUnban:SetTextColor(IVO_SAM.Theme.TextMain)
    btnUnban.HoverVal = 0
    btnUnban.Paint = function(s, w, h)
        s.HoverVal = math.Clamp(s.HoverVal + (s:IsHovered() and 5 or -5) * FrameTime(), 0, 1)
        draw.RoundedBox(8, 0, 0, w, h, Color(180, 40, 40))
        if s.HoverVal > 0 then
            draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, 30 * s.HoverVal))
        end
        draw.SimpleText(s:GetText(), s:GetFont(), w / 2, h / 2, IVO_SAM.Theme.TextMain, 1, 1)
        return true
    end
    btnUnban.DoClick = function()
        local line = bList:GetSelectedLine()
        if line then
            local steamID = bList:GetLine(line):GetValue(2)
            RunConsoleCommand("say", "!unban " .. steamID)
            timer.Simple(0.3, function() IVO_SAM_LoadBans(bList) end)
            surface.PlaySound("UI/buttonclick.wav")
        else
            chat.AddText(Color(255, 0, 0), "[IVOSAM] ", Color(255, 255, 255), "Selecciona un baneo primero.")
        end
    end

    local btnRef = vgui.Create("DButton", btnPanel)
    btnRef:SetSize(160, 55)
    btnRef:Dock(RIGHT)
    btnRef:SetText("ACTUALIZAR")
    btnRef:SetFont("IVOSAM_Bold")
    btnRef:SetTextColor(IVO_SAM.Theme.TextMain)
    btnRef.HoverVal = 0
    btnRef.Paint = function(s, w, h)
        s.HoverVal = math.Clamp(s.HoverVal + (s:IsHovered() and 5 or -5) * FrameTime(), 0, 1)
        draw.RoundedBox(8, 0, 0, w, h, Color(50, 50, 60))
        if s.HoverVal > 0 then
            draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, 20 * s.HoverVal))
        end
        draw.SimpleText(s:GetText(), s:GetFont(), w / 2, h / 2, IVO_SAM.Theme.TextMuted, 1, 1)
        return true
    end
    btnRef.DoClick = function()
        net.Start("IVO_RequestHistoryData")
        net.SendToServer()
        surface.PlaySound("UI/buttonrollover.wav")
    end

    IVO_SAM_LoadBans(bList)
end
