VirtusWhitelist = VirtusWhitelist or {}
VirtusWhitelist.CurrentPage = 1
VirtusWhitelist.ItemsPerPage = 10 -- Reducido por la barra de búsqueda y barra inferior
VirtusWhitelist.ActiveTab = "whitelist"
VirtusWhitelist.SearchFilter = ""

-- Paleta de colores súper limpia
local THEME = {
    BgBase = Color(18, 18, 22, 245),
    BgSide = Color(12, 12, 16, 200),
    CardBg = Color(28, 28, 34, 255),
    CardHover = Color(35, 35, 42, 255),
    TextMain = Color(255, 255, 255, 255),
    TextMuted = Color(140, 140, 150, 255),
    Accent = Color(0, 140, 255, 255),
    Success = Color(46, 204, 113, 255),
    Danger = Color(231, 76, 60, 255),
}

surface.CreateFont("IVOWL_Title", { font = "Inter", size = 32, weight = 800, antialias = true })
surface.CreateFont("IVOWL_Subtitle", { font = "Inter", size = 16, weight = 500, antialias = true })
surface.CreateFont("IVOWL_Tab", { font = "Inter", size = 16, weight = 700, antialias = true })
surface.CreateFont("IVOWL_Normal", { font = "Inter", size = 15, weight = 500, antialias = true })
surface.CreateFont("IVOWL_Bold", { font = "Inter", size = 14, weight = 800, antialias = true })
surface.CreateFont("IVOWL_Icon", { font = "Inter", size = 22, weight = 400, antialias = true })

local blur = Material("pp/blurscreen")
local function DrawBlur(panel, amount)
    local x, y = panel:LocalToScreen(0, 0)
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blur)
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * (amount or 6))
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
    end
end

function VirtusWhitelist.OpenMenu()
    if IsValid(VirtusWhitelist.Menu) then VirtusWhitelist.Menu:Remove() end

    local frame = vgui.Create("DFrame")
    VirtusWhitelist.Menu = frame
    frame:SetSize(1150, 680)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.2, 0)

    -- Arrastrar desde la barra superior
    frame.OnMousePressed = function(s, code)
        local _, cursorY = s:CursorPos()
        if code == MOUSE_LEFT and cursorY < 70 then
            s:MouseCapture(true)
            s.Dragging = { gui.MouseX() - s.x, gui.MouseY() - s.y }
        end
    end
    frame.OnMouseReleased = function(s, code)
        s:MouseCapture(false)
        s.Dragging = nil
    end
    frame.Think = function(s)
        if s.Dragging then
            local x = gui.MouseX() - s.Dragging[1]
            local y = gui.MouseY() - s.Dragging[2]
            s:SetPos(x, y)
        end
    end

    frame.Paint = function(s, w, h)
        DrawBlur(s, 12)
        draw.RoundedBox(12, 0, 0, w, h, THEME.BgBase)
        surface.SetDrawColor(0, 0, 0, 100)
        surface.DrawRect(0, 0, w, 70)
        surface.SetDrawColor(255, 255, 255, 5)
        surface.DrawRect(0, 70, w, 1)

        draw.SimpleText("IVOWHITELIST", "IVOWL_Title", 30, 35, THEME.TextMain, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetFont("IVOWL_Title")
        local tw = surface.GetTextSize("IVOWHITELIST")
        draw.SimpleText("CONTROL CENTER", "IVOWL_Subtitle", 30 + tw + 10, 36, THEME.Accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local close = vgui.Create("DButton", frame)
    close:SetSize(40, 40)
    close:SetPos(frame:GetWide() - 50, 15)
    close:SetText("✕")
    close:SetFont("IVOWL_Icon")
    close:SetColor(THEME.TextMuted)
    close.Paint = nil
    close.DoClick = function(s) 
        frame:AlphaTo(0, 0.15, 0, function()
            if IsValid(frame) then frame:Remove() end
        end)
    end
    close.OnCursorEntered = function(s) s:SetColor(THEME.Danger) end
    close.OnCursorExited = function(s) s:SetColor(THEME.TextMuted) end

    -- Panel Lateral (Categorías)
    local sidePanel = vgui.Create("DPanel", frame)
    sidePanel:SetSize(280, frame:GetTall() - 71)
    sidePanel:SetPos(0, 71)
    sidePanel.Paint = function(s, w, h)
        draw.RoundedBoxEx(12, 0, 0, w, h, THEME.BgSide, false, false, true, false)
        surface.SetDrawColor(255, 255, 255, 5)
        surface.DrawRect(w - 1, 0, 1, h)
    end

    local scrollCategories = vgui.Create("DScrollPanel", sidePanel)
    scrollCategories:Dock(FILL)
    scrollCategories:DockMargin(0, 10, 0, 10)
    local vbarCat = scrollCategories:GetVBar()
    vbarCat:SetWide(4) vbarCat:Hide() vbarCat.Paint = function() end vbarCat.btnUp.Paint = function() end vbarCat.btnDown.Paint = function() end
    vbarCat.btnGrip.Paint = function(s, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(255, 255, 255, 10)) end

    -- Panel Lateral Derecho (Jugadores Conectados)
    local playersPanel = vgui.Create("DPanel", frame)
    playersPanel:SetSize(270, frame:GetTall() - 71)
    playersPanel:SetPos(frame:GetWide() - 270, 71)
    playersPanel.Paint = function(s, w, h)
        draw.RoundedBoxEx(12, 0, 0, w, h, THEME.BgSide, false, false, false, true)
        surface.SetDrawColor(255, 255, 255, 5)
        surface.DrawRect(0, 0, 1, h)
        draw.SimpleText("JUGADORES CONECTADOS", "IVOWL_Bold", 20, 25, THEME.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(255,255,255,5)
        surface.DrawRect(20, 45, w - 40, 1)
    end

    local plyScroll = vgui.Create("DScrollPanel", playersPanel)
    plyScroll:Dock(FILL)
    plyScroll:DockMargin(15, 60, 15, 15)
    local vbarPly = plyScroll:GetVBar()
    vbarPly:SetWide(4) vbarPly:Hide() vbarPly.Paint = function() end vbarPly.btnUp.Paint = function() end vbarPly.btnDown.Paint = function() end
    vbarPly.btnGrip.Paint = function(s, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(255, 255, 255, 10)) end

    for _, ply in ipairs(player.GetAll()) do
        local pBtn = vgui.Create("DButton", plyScroll)
        pBtn:Dock(TOP)
        pBtn:SetTall(50)
        pBtn:DockMargin(0, 0, 0, 8)
        pBtn:SetText("")
        pBtn.Paint = function(s, w, h)
            local bg = s:IsHovered() and THEME.CardHover or THEME.CardBg
            draw.RoundedBox(6, 0, 0, w, h, bg)
            
            if s:IsHovered() and VirtusWhitelist.SelectedJobCmd then
                local actColor = (VirtusWhitelist.ActiveTab == "whitelist") and THEME.Success or THEME.Danger
                draw.RoundedBoxEx(6, 0, 0, 4, h, actColor, true, false, true, false)
            end
            
            draw.SimpleText(ply:Nick(), "IVOWL_Normal", 15, 15, THEME.TextMain, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(ply:SteamID(), "IVOWL_Bold", 15, 35, THEME.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        pBtn.DoClick = function()
            if not VirtusWhitelist.SelectedJobCmd then
                Derma_Message("Selecciona un trabajo en el panel izquierdo primero.", "Error", "OK")
                return
            end
            net.Start("VirtusWhitelist_AddPlayer")
            net.WriteString(ply:SteamID())
            net.WriteString(VirtusWhitelist.SelectedJobCmd)
            net.WriteString(VirtusWhitelist.ActiveTab)
            net.SendToServer()
        end
    end

    -- Contenedor Central
    local contentContainer = vgui.Create("DPanel", frame)
    contentContainer:SetSize(frame:GetWide() - 280 - 270, frame:GetTall() - 71)
    contentContainer:SetPos(280, 71)
    contentContainer.Paint = function() end
    VirtusWhitelist.RightPanel = contentContainer

    -- Llenar Menús Desplegables
    local categories = DarkRP.getCategories().jobs
    for _, cat in ipairs(categories) do
        if not cat.members or #cat.members == 0 then continue end

        local catColor = cat.color or THEME.Accent

        local catBtn = vgui.Create("DButton", scrollCategories)
        catBtn:Dock(TOP)
        catBtn:SetTall(45)
        catBtn:SetText("")
        
        local jobsContainer = vgui.Create("DPanel", scrollCategories)
        jobsContainer:Dock(TOP)
        jobsContainer.Paint = function() end
        
        local jobCount = #cat.members
        local expandedHeight = jobCount * 40
        jobsContainer:SetTall(0)
        
        catBtn.Expanded = false
        catBtn.Paint = function(s, w, h)
            if s:IsHovered() then
                draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 2))
            end
            local barW = s.Expanded and 4 or 0
            if s.Expanded then draw.RoundedBox(0, 0, 0, barW, h, catColor) end
            
            local textColor = s.Expanded and catColor or THEME.TextMain
            if not s.Expanded and s:IsHovered() then textColor = color_white end
            
            draw.SimpleText(cat.name, "IVOWL_Bold", 20, h/2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local sym = s.Expanded and "-" or "+"
            draw.SimpleText(sym, "IVOWL_Icon", w - 20, h/2 - 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(255, 255, 255, 5)
            surface.DrawRect(20, h - 1, w - 40, 1)
        end
        
        catBtn.DoClick = function(s)
            s.Expanded = not s.Expanded
            if s.Expanded then
                jobsContainer:SizeTo(jobsContainer:GetWide(), expandedHeight, 0.2, 0, -1)
            else
                jobsContainer:SizeTo(jobsContainer:GetWide(), 0, 0.2, 0, -1)
            end
        end

        for _, job in ipairs(cat.members) do
            local jBtn = vgui.Create("DButton", jobsContainer)
            jBtn:Dock(TOP)
            jBtn:SetTall(40)
            jBtn:SetText("")
            jBtn.job_cmd = job.command
            jBtn.Paint = function(s, w, h)
                local isSelected = VirtusWhitelist.SelectedJobCmd == s.job_cmd
                if isSelected then
                    draw.RoundedBox(0, 0, 0, w, h, Color(catColor.r, catColor.g, catColor.b, 15))
                    draw.RoundedBox(0, 0, 0, 3, h, catColor)
                elseif s:IsHovered() then
                    draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 2))
                end
                
                local col = isSelected and THEME.TextMain or THEME.TextMuted
                if s:IsHovered() then col = THEME.TextMain end
                draw.SimpleText(job.name, "IVOWL_Normal", 25, h/2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            jBtn.DoClick = function(s)
                VirtusWhitelist.SelectedJobCmd = s.job_cmd
                VirtusWhitelist.SelectedJobName = job.name
                VirtusWhitelist.SelectedJobColor = catColor
                VirtusWhitelist.CurrentPage = 1
                VirtusWhitelist.SearchFilter = ""
                net.Start("VirtusWhitelist_RequestData")
                net.WriteString(s.job_cmd)
                net.SendToServer()
                VirtusWhitelist.BuildRightPanel()
            end
        end
    end

    VirtusWhitelist.BuildRightPanel()
end

function VirtusWhitelist.BuildRightPanel()
    local pnl = VirtusWhitelist.RightPanel
    if not IsValid(pnl) then return end
    pnl:Clear()

    if not VirtusWhitelist.SelectedJobCmd then
        local lbl = vgui.Create("DLabel", pnl)
        lbl:Dock(FILL)
        lbl:SetFont("IVOWL_Tab")
        lbl:SetText("SELECCIONA UN TRABAJO EN EL MENÚ PARA EMPEZAR")
        lbl:SetTextColor(THEME.TextMuted)
        lbl:SetContentAlignment(5)
        return
    end

    local catColor = VirtusWhitelist.SelectedJobColor or THEME.Accent

    -- Header Ultra Premium
    local header = vgui.Create("DPanel", pnl)
    header:Dock(TOP)
    header:SetTall(80)
    header:DockMargin(30, 30, 30, 10)
    header.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, THEME.CardBg)
        draw.RoundedBoxEx(8, 0, 0, w, 4, catColor, true, true, false, false)
        surface.SetDrawColor(catColor.r, catColor.g, catColor.b, 25)
        surface.SetMaterial(Material("vgui/gradient-r"))
        surface.DrawTexturedRect(0, 4, w, h-4)
        draw.SimpleText(VirtusWhitelist.SelectedJobName, "IVOWL_Title", 25, h/2 + 2, THEME.TextMain, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Pestañas Inferiores Elegantes (Underline Style)
    local tabsContainer = vgui.Create("DPanel", pnl)
    tabsContainer:Dock(TOP)
    tabsContainer:SetTall(40)
    tabsContainer:DockMargin(30, 0, 30, 15)
    tabsContainer.Paint = function(s, w, h)
        surface.SetDrawColor(255, 255, 255, 10)
        surface.DrawRect(0, h - 2, w, 2)
    end

    local btnWL = vgui.Create("DButton", tabsContainer)
    btnWL:Dock(LEFT)
    btnWL:SetWide(150)
    btnWL:SetText("")
    btnWL.Paint = function(s, w, h)
        local isActive = VirtusWhitelist.ActiveTab == "whitelist"
        local col = isActive and THEME.TextMain or THEME.TextMuted
        if s:IsHovered() then col = THEME.TextMain end
        draw.SimpleText("WHITELIST", "IVOWL_Tab", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if isActive then draw.RoundedBox(0, 0, h - 2, w, 2, THEME.Success) end
    end
    btnWL.DoClick = function()
        VirtusWhitelist.ActiveTab = "whitelist"
        VirtusWhitelist.CurrentPage = 1
        VirtusWhitelist.RefreshListUI()
    end

    local btnBL = vgui.Create("DButton", tabsContainer)
    btnBL:Dock(LEFT)
    btnBL:SetWide(150)
    btnBL:SetText("")
    btnBL.Paint = function(s, w, h)
        local isActive = VirtusWhitelist.ActiveTab == "blacklist"
        local col = isActive and THEME.TextMain or THEME.TextMuted
        if s:IsHovered() then col = THEME.TextMain end
        draw.SimpleText("BLACKLIST", "IVOWL_Tab", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if isActive then draw.RoundedBox(0, 0, h - 2, w, 2, THEME.Danger) end
    end
    btnBL.DoClick = function()
        VirtusWhitelist.ActiveTab = "blacklist"
        VirtusWhitelist.CurrentPage = 1
        VirtusWhitelist.RefreshListUI()
    end

    -- Barra de búsqueda (En el panel central)
    local searchPanel = vgui.Create("DPanel", pnl)
    searchPanel:Dock(TOP)
    searchPanel:SetTall(40)
    searchPanel:DockMargin(30, 0, 30, 15)
    searchPanel.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, THEME.CardBg)
    end

    local searchIcon = vgui.Create("DLabel", searchPanel)
    searchIcon:Dock(LEFT)
    searchIcon:SetWide(40)
    searchIcon:SetText("🔍")
    searchIcon:SetFont("IVOWL_Normal")
    searchIcon:SetContentAlignment(5)

    local searchEntry = vgui.Create("DTextEntry", searchPanel)
    searchEntry:Dock(FILL)
    searchEntry:DockMargin(0, 5, 10, 5)
    searchEntry:SetFont("IVOWL_Normal")
    searchEntry:SetTextColor(THEME.TextMain)
    searchEntry:SetCursorColor(THEME.TextMain)
    searchEntry:SetDrawLanguageID(false)
    searchEntry:SetPaintBackground(false)
    searchEntry:SetValue(VirtusWhitelist.SearchFilter or "")
    searchEntry.OnChange = function(s)
        VirtusWhitelist.SearchFilter = s:GetValue():lower()
        VirtusWhitelist.CurrentPage = 1
        VirtusWhitelist.RefreshListUI()
    end
    searchEntry.Paint = function(s, w, h)
        s:DrawTextEntryText(THEME.TextMain, THEME.Accent, THEME.TextMain)
        if s:GetValue() == "" and not s:HasFocus() then
            draw.SimpleText("Buscar SteamID en esta lista...", "IVOWL_Normal", 0, h/2, THEME.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    -- Contenedor de la lista
    VirtusWhitelist.ListContainer = vgui.Create("DPanel", pnl)
    VirtusWhitelist.ListContainer:Dock(FILL)
    VirtusWhitelist.ListContainer:DockMargin(30, 0, 30, 30)
    VirtusWhitelist.ListContainer.Paint = function() end

    VirtusWhitelist.RefreshListUI()
end

function VirtusWhitelist.RefreshListUI()
    local container = VirtusWhitelist.ListContainer
    if not IsValid(container) then return end
    container:Clear()

    local data = VirtusWhitelist.JobData[VirtusWhitelist.SelectedJobCmd]
    if not data then return end 

    local sourceList = VirtusWhitelist.ActiveTab == "whitelist" and data.whitelist or data.blacklist
    
    -- Filtro de Búsqueda
    local filteredList = {}
    local filterStr = VirtusWhitelist.SearchFilter or ""
    for _, steamid in ipairs(sourceList) do
        if filterStr == "" or string.find(steamid:lower(), filterStr, 1, true) then
            table.insert(filteredList, steamid)
        end
    end

    local totalItems = #filteredList
    local totalPages = math.max(1, math.ceil(totalItems / VirtusWhitelist.ItemsPerPage))
    
    if VirtusWhitelist.CurrentPage > totalPages then VirtusWhitelist.CurrentPage = totalPages end

    local startIndex = (VirtusWhitelist.CurrentPage - 1) * VirtusWhitelist.ItemsPerPage + 1
    local endIndex = math.min(startIndex + VirtusWhitelist.ItemsPerPage - 1, totalItems)
    
    local catColor = VirtusWhitelist.SelectedJobColor or THEME.Accent

    -- Botones de acción inferiores (Input Manual en línea)
    local bottomBar = vgui.Create("DPanel", container)
    bottomBar:Dock(BOTTOM)
    bottomBar:SetTall(45)
    bottomBar:DockMargin(0, 15, 0, 0)
    bottomBar.Paint = function() end

    -- Paginación minimalista (A la derecha)
    local pagPanel = vgui.Create("DPanel", bottomBar)
    pagPanel:Dock(RIGHT)
    pagPanel:SetWide(120)
    pagPanel.Paint = function() end

    local btnPrev = vgui.Create("DButton", pagPanel)
    btnPrev:Dock(LEFT)
    btnPrev:SetWide(30)
    btnPrev:SetText("")
    btnPrev.Paint = function(s, w, h) 
        local col = s:IsHovered() and THEME.TextMain or THEME.TextMuted
        draw.SimpleText("<", "IVOWL_Icon", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnPrev.DoClick = function()
        if VirtusWhitelist.CurrentPage > 1 then
            VirtusWhitelist.CurrentPage = VirtusWhitelist.CurrentPage - 1
            VirtusWhitelist.RefreshListUI()
        end
    end

    local btnNext = vgui.Create("DButton", pagPanel)
    btnNext:Dock(RIGHT)
    btnNext:SetWide(30)
    btnNext:SetText("")
    btnNext.Paint = function(s, w, h) 
        local col = s:IsHovered() and THEME.TextMain or THEME.TextMuted
        draw.SimpleText(">", "IVOWL_Icon", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnNext.DoClick = function()
        if VirtusWhitelist.CurrentPage < totalPages then
            VirtusWhitelist.CurrentPage = VirtusWhitelist.CurrentPage + 1
            VirtusWhitelist.RefreshListUI()
        end
    end

    local lblPage = vgui.Create("DLabel", pagPanel)
    lblPage:Dock(FILL)
    lblPage:SetText(VirtusWhitelist.CurrentPage .. " / " .. totalPages)
    lblPage:SetFont("IVOWL_Normal")
    lblPage:SetTextColor(THEME.TextMain)
    lblPage:SetContentAlignment(5)

    -- Contenedor para añadir SteamID manualmente (Izquierda)
    local addContainer = vgui.Create("DPanel", bottomBar)
    addContainer:Dock(FILL)
    addContainer:DockMargin(0, 0, 15, 0)
    addContainer.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, THEME.CardBg)
    end

    local btnAdd = vgui.Create("DButton", addContainer)
    btnAdd:Dock(RIGHT)
    btnAdd:SetWide(110)
    btnAdd:SetText("")
    btnAdd.Paint = function(s, w, h)
        local bg = s:IsHovered() and THEME.Accent or Color(THEME.Accent.r, THEME.Accent.g, THEME.Accent.b, 200)
        draw.RoundedBoxEx(6, 0, 0, w, h, bg, false, true, false, true)
        draw.SimpleText("AÑADIR", "IVOWL_Bold", w/2, h/2, THEME.TextMain, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local manualEntry = vgui.Create("DTextEntry", addContainer)
    manualEntry:Dock(FILL)
    manualEntry:DockMargin(15, 10, 10, 10)
    manualEntry:SetFont("IVOWL_Normal")
    manualEntry:SetDrawLanguageID(false)
    manualEntry:SetTextColor(THEME.TextMain)
    manualEntry:SetCursorColor(THEME.TextMain)
    manualEntry:SetPaintBackground(false)
    manualEntry.Paint = function(s, w, h)
        s:DrawTextEntryText(THEME.TextMain, THEME.Accent, THEME.TextMain)
        if s:GetValue() == "" and not s:HasFocus() then
            draw.SimpleText("Pega un SteamID manualmente aquí...", "IVOWL_Normal", 0, h/2, THEME.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    btnAdd.DoClick = function()
        local text = string.Trim(manualEntry:GetValue())
        if string.match(text, "^STEAM_%d:%d:%d+$") then
            net.Start("VirtusWhitelist_AddPlayer")
            net.WriteString(text)
            net.WriteString(VirtusWhitelist.SelectedJobCmd)
            net.WriteString(VirtusWhitelist.ActiveTab)
            net.SendToServer()
            manualEntry:SetValue("")
        else
            Derma_Message("Formato de SteamID inválido.", "Error", "OK")
        end
    end

    -- Lista de Jugadores (Scroll)
    local scroll = vgui.Create("DScrollPanel", container)
    scroll:Dock(FILL)
    
    local vbar = scroll:GetVBar()
    vbar:SetWide(4)
    vbar:Hide()
    vbar.Paint = function() end
    vbar.btnUp.Paint = function() end
    vbar.btnDown.Paint = function() end
    vbar.btnGrip.Paint = function(s, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(255, 255, 255, 10)) end

    if totalItems == 0 then
        local lblEmpty = vgui.Create("DLabel", scroll)
        lblEmpty:Dock(TOP)
        lblEmpty:SetTall(100)
        lblEmpty:SetText(filterStr == "" and "La lista está vacía." or "No se encontraron resultados.")
        lblEmpty:SetFont("IVOWL_Tab")
        lblEmpty:SetTextColor(Color(255, 255, 255, 20))
        lblEmpty:SetContentAlignment(5)
    else
        for i = startIndex, endIndex do
            local steamid = filteredList[i]
            local row = vgui.Create("DPanel", scroll)
            row:Dock(TOP)
            row:SetTall(46)
            row:DockMargin(0, 0, 0, 8)
            row.Paint = function(s, w, h)
                local bg = s:IsHovered() and THEME.CardHover or THEME.CardBg
                draw.RoundedBox(6, 0, 0, w, h, bg)
                draw.RoundedBoxEx(6, 0, 0, 3, h, THEME.TextMuted, true, false, true, false)
                draw.SimpleText(steamid, "IVOWL_Normal", 20, h/2, THEME.TextMain, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local btnRem = vgui.Create("DButton", row)
            btnRem:Dock(RIGHT)
            btnRem:SetWide(46)
            btnRem:SetText("")
            btnRem.Paint = function(s, w, h)
                if s:IsHovered() then
                    draw.RoundedBoxEx(6, 0, 0, w, h, THEME.Danger, false, true, false, true)
                end
                draw.SimpleText("✕", "IVOWL_Bold", w/2, h/2, s:IsHovered() and THEME.TextMain or THEME.TextMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            btnRem.DoClick = function()
                net.Start("VirtusWhitelist_RemovePlayer")
                net.WriteString(steamid)
                net.WriteString(VirtusWhitelist.SelectedJobCmd)
                net.WriteString(VirtusWhitelist.ActiveTab)
                net.SendToServer()
            end
        end
    end
end
