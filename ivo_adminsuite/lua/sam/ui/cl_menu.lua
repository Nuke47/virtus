-- ============================================================================
-- IVOSAM: PANEL DE ADMINISTRACIÓN — PREMIUM HUD & UI
-- ============================================================================

IVO_SAM = IVO_SAM or {}

-- Fuentes modernas para la interfaz
surface.CreateFont("IVOSAM_Title", { font = "Inter", size = 28, weight = 800, antialias = true })
surface.CreateFont("IVOSAM_Subtitle", { font = "Inter", size = 16, weight = 500, antialias = true })
surface.CreateFont("IVOSAM_Tab", { font = "Inter", size = 18, weight = 600, antialias = true })
surface.CreateFont("IVOSAM_Normal", { font = "Inter", size = 15, weight = 500, antialias = true })
surface.CreateFont("IVOSAM_Bold", { font = "Inter", size = 15, weight = 800, antialias = true })
surface.CreateFont("IVOSAM_Icon", { font = "Arial", size = 20, weight = 400, antialias = true }) -- Backup if missing icon fonts

-- Colores base del tema Premium
IVO_SAM.Theme = {
    BgBase = Color(15, 15, 18, 240),
    BgTop = Color(20, 20, 25, 250),
    BgSide = Color(12, 12, 15, 150),
    Accent = Color(0, 140, 255),
    AccentGlow = Color(0, 140, 255, 50),
    TextMain = Color(255, 255, 255),
    TextMuted = Color(160, 160, 170),
    CardBg = Color(22, 22, 28, 255),
    CardHover = Color(30, 30, 38, 255)
}

function IVO_SAM.FormatearTiempoMenu(segundos)
    local s = segundos or 0
    if s <= 0 then return "0s" end
    local w = math.floor(s / 604800)
    local d = math.floor((s % 604800) / 86400)
    local h = math.floor((s % 86400) / 3600)
    local m = math.floor((s % 3600) / 60)
    local seg = math.floor(s % 60)
    local texto = ""
    if w > 0 then texto = texto .. w .. "w " end
    if d > 0 then texto = texto .. d .. "d " end
    if h > 0 then texto = texto .. h .. "h " end
    if m > 0 then texto = texto .. m .. "m " end
    if seg > 0 or texto == "" then texto = texto .. seg .. "s" end
    return string.Trim(texto)
end

function IVO_SAM.StyleModernEntry(entry)
    entry:SetDrawLanguageID(false)
    entry:SetFont("IVOSAM_Normal")
    entry:SetTextColor(IVO_SAM.Theme.TextMain)
    entry:SetCursorColor(IVO_SAM.Theme.TextMain)
    entry:SetPlaceholderColor(IVO_SAM.Theme.TextMuted)
    entry.Paint = function(s, w, h)
        local bg = s:HasFocus() and Color(35, 35, 45) or Color(25, 25, 30)
        draw.RoundedBox(6, 0, 0, w, h, bg)
        if s:HasFocus() then
            surface.SetDrawColor(IVO_SAM.Theme.AccentGlow)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        s:DrawTextEntryText(IVO_SAM.Theme.TextMain, IVO_SAM.Theme.Accent, IVO_SAM.Theme.TextMain)
    end
end

-- Cargar módulos de tabs
include("sam/ui/cl_tab_players.lua")
include("sam/ui/cl_tab_history.lua")
include("sam/ui/cl_tab_ranks.lua")
include("sam/ui/cl_tab_commands.lua")
include("sam/ui/cl_tab_vote.lua")
include("sam/ui/cl_tab_xp.lua")

function OpenAdminMenu()
    if IsValid(IVO_SAM._adminFrame) then IVO_SAM._adminFrame:Remove() end

    net.Start("IVO_RequestHistoryData")
    net.SendToServer()

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

    local frame = vgui.Create("DFrame")
    IVO_SAM._adminFrame = frame
    frame:SetSize(1000, 650)
    frame:SetTitle("")
    frame:MakePopup()
    frame:Center()
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.2, 0)

    frame.OnMousePressed = function(s, code)
        local _, cursorY = s:CursorPos()
        if code == MOUSE_LEFT and cursorY < 60 then
            s:MouseCapture(true)
            s.Dragging = { gui.MouseX() - s.x, gui.MouseY() - s.y }
        end
    end

    frame.Paint = function(s, w, h)
        DrawBlur(s, 10)
        -- Fondo base semi-transparente
        draw.RoundedBox(12, 0, 0, w, h, IVO_SAM.Theme.BgBase)
        
        -- Header Superior
        draw.RoundedBoxEx(12, 0, 0, w, 70, IVO_SAM.Theme.BgTop, true, true, false, false)
        
        -- Gradiente sutil inferior
        surface.SetDrawColor(0, 140, 255, 10)
        surface.SetMaterial(Material("vgui/gradient-u"))
        surface.DrawTexturedRect(0, h - 150, w, 150)

        -- Textos
        draw.SimpleText("IVOSAM", "IVOSAM_Title", 25, 35, IVO_SAM.Theme.TextMain, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetFont("IVOSAM_Title")
        local tw = surface.GetTextSize("IVOSAM")
        draw.SimpleText("CONTROL CENTER", "IVOSAM_Subtitle", 25 + tw + 10, 36, IVO_SAM.Theme.Accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local close = vgui.Create("DButton", frame)
    close:SetSize(40, 40)
    close:SetPos(frame:GetWide() - 50, 15)
    close:SetText("✕")
    close:SetFont("IVOSAM_Title")
    close:SetColor(IVO_SAM.Theme.TextMuted)
    close.Paint = nil
    close.DoClick = function(s) 
        frame:AlphaTo(0, 0.15, 0, function()
            if IsValid(frame) then frame:Remove() end
        end)
    end

    local sidePanel = vgui.Create("DPanel", frame)
    sidePanel:SetSize(220, frame:GetTall() - 70)
    sidePanel:SetPos(0, 70)
    sidePanel.Paint = function(s, w, h)
        draw.RoundedBoxEx(12, 0, 0, w, h, IVO_SAM.Theme.BgSide, false, false, true, false)
        -- Separador lateral
        surface.SetDrawColor(255, 255, 255, 5)
        surface.DrawRect(w - 1, 0, 1, h)
    end

    local contentContainer = vgui.Create("DPanel", frame)
    contentContainer:SetSize(frame:GetWide() - 220, frame:GetTall() - 70)
    contentContainer:SetPos(220, 70)
    contentContainer.Paint = nil

    local activeTab = nil
    local tabs = {}
    local tabButtons = {}

    local function ShowTab(name)
        for k, p in pairs(tabs) do 
            if p:IsVisible() and k ~= name then
                p:AlphaTo(0, 0.1, 0, function() p:SetVisible(false) end)
            end
        end
        if tabs[name] then
            tabs[name]:SetVisible(true)
            tabs[name]:SetAlpha(0)
            tabs[name]:AlphaTo(255, 0.2, 0.1)
            activeTab = name
        end
    end

    local function AddMenuTab(name)
        local btn = vgui.Create("DButton", sidePanel)
        btn:SetSize(220, 55)
        btn:Dock(TOP)
        btn:SetText("")
        
        -- Animación de hover interpolada
        btn.HoverVal = 0

        local tabContent = vgui.Create("DPanel", contentContainer)
        tabContent:Dock(FILL)
        tabContent:SetVisible(false)
        tabContent.Paint = nil
        tabs[name] = tabContent
        table.insert(tabButtons, btn)

        btn.Paint = function(s, w, h)
            local isActive = (activeTab == name)
            
            if s:IsHovered() or isActive then
                s.HoverVal = math.Clamp(s.HoverVal + 5 * FrameTime(), 0, 1)
            else
                s.HoverVal = math.Clamp(s.HoverVal - 5 * FrameTime(), 0, 1)
            end

            -- Fondo animado
            if isActive then
                draw.RoundedBox(0, 0, 0, w, h, IVO_SAM.Theme.AccentGlow)
                draw.RoundedBox(0, 0, 0, 4, h, IVO_SAM.Theme.Accent)
            elseif s.HoverVal > 0 then
                draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 10 * s.HoverVal))
            end

            local tCol = isActive and IVO_SAM.Theme.TextMain or IVO_SAM.Theme.TextMuted
            if s.HoverVal > 0 and not isActive then
                tCol = Color(200 + 55 * s.HoverVal, 200 + 55 * s.HoverVal, 200 + 55 * s.HoverVal)
            end

            draw.SimpleText(name:upper(), "IVOSAM_Tab", 30, h / 2, tCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function() 
            if activeTab == name then return end
            surface.PlaySound("UI/buttonrollover.wav")
            ShowTab(name) 
        end
        return tabContent
    end

    -- Construir tabs usando sus módulos
    local plyP  = AddMenuTab("Jugadores")
    IVOSAM_BuildPlayersTab(plyP, frame, function() return activeTab end)

    local histP = AddMenuTab("Historial")
    IVOSAM_BuildHistoryTab(histP)

    local editP = AddMenuTab("Editor Rangos")
    IVOSAM_BuildRanksTab(editP)

    local cmdP  = AddMenuTab("Acciones")
    IVOSAM_BuildCommandsTab(cmdP)

    local voteP = AddMenuTab("Votaciones")
    if IVOSAM_BuildVoteTab then IVOSAM_BuildVoteTab(voteP) end

    if LocalPlayer():IsSuperAdmin() then
        local xpP = AddMenuTab("XP & Niveles")
        if IVOSAM_BuildXPTab then IVOSAM_BuildXPTab(xpP) end
    end

    ShowTab("Jugadores")
end

-- Busca la lista de baneos en el árbol de panels del frame
local function EncontrarListaBaneos(panel)
    if not IsValid(panel) then return nil end
    if panel.ClassName == "DListView" and panel.EsListaBaneos then return panel end
    for _, child in ipairs(panel:GetChildren()) do
        local encontrado = EncontrarListaBaneos(child)
        if encontrado then return encontrado end
    end
    return nil
end

net.Receive("IVO_SyncRanks", function()
    local updatedRanks = net.ReadTable()
    IVO_SAM.Ranks = updatedRanks
    if isfunction(RefreshRankList) then RefreshRankList() end
end)

net.Receive("IVO_SendHistoryData", function()
    IVO_SAM.ServerHistoryData = net.ReadTable() or {}
    IVO_SAM.ServerBansData    = net.ReadTable() or {}
    local rawRanks            = net.ReadTable() or {}

    IVO_SAM.ClientRankCache = {}
    for _, v in pairs(rawRanks) do
        if v.steamid64 then IVO_SAM.ClientRankCache[v.steamid64] = { rank = v.rank, sec_rank = v.sec_rank } end
    end

    if IsValid(IVO_SAM._adminFrame) then
        if isfunction(RefreshPlayerList) then
            local search = IVO_SAM._adminFrame:Find("DTextEntry") 
            local filterText = IsValid(search) and search:GetValue() or ""
            RefreshPlayerList(filterText)
        end
        local bList = EncontrarListaBaneos(IVO_SAM._adminFrame)
        if IsValid(bList) then IVO_SAM_LoadBans(bList) end
    end
end)

IVO_SAM.RefreshAdminMenu = function()
    if IsValid(IVO_SAM._adminFrame) then
        if isfunction(RefreshPlayerList) then RefreshPlayerList("") end
        local bList = EncontrarListaBaneos(IVO_SAM._adminFrame)
        if IsValid(bList) then IVO_SAM_LoadBans(bList) end
    end
end
