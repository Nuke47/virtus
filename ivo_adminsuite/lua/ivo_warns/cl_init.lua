-- ==========================================
-- IVO_WARNS - CLIENTE (VGUI MODERNO)
-- ==========================================

-- Fuentes personalizadas (Se usa Roboto para un look más limpio)
surface.CreateFont("IvoWarns_Title", { font = "Inter", size = 28, weight = 800, antialias = true })
surface.CreateFont("IvoWarns_Bold", { font = "Inter", size = 15, weight = 800, antialias = true })
surface.CreateFont("IvoWarns_Regular", { font = "Inter", size = 15, weight = 500, antialias = true })
surface.CreateFont("IvoWarns_Small", { font = "Inter", size = 13, weight = 500, antialias = true })

local DECAY_TIME = IVO_WARNS.Config.DecayDays * 24 * 60 * 60

-- Variables Globales de UI
local WarnMenu            = nil
local PlayerListPanel     = nil
local SearchBar           = nil
local RightContentCanvas  = nil
local CachedPlayers       = {}
local CurrentSelectedSteamID  = ""
local CurrentLastWarnTime     = 0

-- Colores del Tema Oscuro Moderno (Estilo IVOSAM)
local Theme = {
    Background = Color(15, 15, 18, 240),
    Sidebar    = Color(12, 12, 15, 150),
    Header     = Color(20, 20, 25, 250),
    Card       = Color(22, 22, 28, 255),
    CardHover  = Color(30, 30, 38, 255),
    TextMain   = Color(255, 255, 255, 255),
    TextMuted  = Color(160, 160, 170, 255),
    Accent     = Color(0, 140, 255, 255),
    Danger     = Color(220, 50, 50, 255),
    Success    = Color(50, 200, 80, 255),
    DeletedBg  = Color(22, 22, 28, 200)
}

-- ==========================================
-- FUNCIONES DE UTILIDAD (UI)
-- ==========================================

-- Función para estilizar las barras de scroll
local function StyleScrollbar(panel)
    local sbar = panel:GetVBar()
    sbar:SetWide(6)
    sbar:SetHideButtons(true)
    sbar.Paint = function(self, w, h) draw.RoundedBox(3, 0, 0, w, h, Color(0, 0, 0, 50)) end
    sbar.btnGrip.Paint = function(self, w, h) draw.RoundedBox(3, 0, 0, w, h, Color(100, 100, 110, 100)) end
end

-- ==========================================
-- RENDERIZADO DEL HISTORIAL (LADO DERECHO)
-- ==========================================

local function RenderWarns(warns_data)
    if not IsValid(RightContentCanvas) then return end
    RightContentCanvas:Clear()

    -- Detectamos si el usuario local es administrador
    local isAdmin = IVO_WARNS.IsAdmin(LocalPlayer())

    local totalWarns  = 0
    local activeWarns = 0

    for _, w in ipairs(warns_data) do
        if not w.is_deleted then
            totalWarns = totalWarns + 1
            if (os.time() - w.time) < DECAY_TIME then
                activeWarns = activeWarns + 1
            end
        end
    end

    local tiene_activos = activeWarns > 0

    -- PANEL DE CABECERA (ESTADÍSTICAS)
    local HeaderPanel = RightContentCanvas:Add("DPanel")
    HeaderPanel:Dock(TOP)
    HeaderPanel:SetHeight(80)
    HeaderPanel:DockMargin(15, 15, 15, 5)
    HeaderPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Theme.Header)
        
        -- Cambiar título dependiendo del rango
        local headerTitle = isAdmin and "Resumen de Jugador" or "Mi Historial de Advertencias"
        draw.SimpleText(headerTitle, "IvoWarns_Bold", 20, 15, Theme.TextMain)
        
        local col_activos = tiene_activos and Theme.Danger or Theme.Success
        local status_txt = tiene_activos and "ESTADO: BAJO ADVERTENCIA" or "ESTADO: LIMPIO"
        draw.SimpleText(status_txt, "IvoWarns_Bold", isAdmin and 200 or 250, 15, col_activos)
        
        draw.SimpleText("Warns Totales: " .. totalWarns, "IvoWarns_Regular", 20, 45, Theme.TextMuted)
        draw.SimpleText("Warns Activos: " .. activeWarns, "IvoWarns_Regular", 160, 45, col_activos)
    end

    -- BOTÓN BORRAR TODO (SOLO SE MUESTRA A ADMINISTRADORES)
    if tiene_activos and isAdmin then
        local deleteAllBtn = vgui.Create("DButton", HeaderPanel)
        deleteAllBtn:SetSize(130, 36)
        deleteAllBtn:SetText("LIMPIAR WARNS")
        deleteAllBtn:SetFont("IvoWarns_Bold")
        deleteAllBtn:SetTextColor(Color(255, 255, 255))
        deleteAllBtn:Dock(RIGHT)
        deleteAllBtn:DockMargin(10, 30, 20, 22)
        deleteAllBtn.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Theme.Danger or Color(180, 40, 40))
        end
        deleteAllBtn.DoClick = function()
            Derma_StringRequest(
                "Remoción Masiva",
                "Motivo para limpiar todos los warns activos:",
                "",
                function(text)
                    if not text or text == "" then return end
                    net.Start("IvoWarns_DeleteAll")
                    net.WriteString(CurrentSelectedSteamID)
                    net.WriteString(text)
                    net.SendToServer()
                end
            )
        end
    end

    -- SCROLL CON LISTA DE WARNS
    local WarnScrollList = RightContentCanvas:Add("DScrollPanel")
    WarnScrollList:Dock(FILL)
    WarnScrollList:DockMargin(15, 10, 15, 15)
    StyleScrollbar(WarnScrollList)

    for _, w in ipairs(warns_data) do
        local date_str = os.date("%d/%m/%Y %H:%M", w.time)
        local warn_individual_activo = not w.is_deleted and ((os.time() - w.time) < DECAY_TIME)

        local row_height = w.is_deleted and 90 or 75
        local warnRow = WarnScrollList:Add("DPanel")
        warnRow:Dock(TOP)
        warnRow:SetHeight(row_height)
        warnRow:DockMargin(0, 0, 0, 10)

        warnRow.Paint = function(self, wp, hp)
            if w.is_deleted then
                draw.RoundedBox(8, 0, 0, wp, hp, Theme.DeletedBg)
                draw.SimpleText("Motivo: " .. w.reason, "IvoWarns_Bold", 15, 15, Color(120, 120, 120))
                draw.SimpleText("Aplicado por: " .. w.admin .. " • " .. date_str, "IvoWarns_Small", 15, 35, Color(90, 90, 90))
                
                draw.RoundedBox(6, 15, 55, wp - 30, 25, Color(30, 20, 20, 150))
                draw.SimpleText("Removido por: " .. w.del_admin .. "  |  Razón: " .. w.del_reason, "IvoWarns_Small", 25, 60, Theme.Danger, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                draw.RoundedBox(8, 0, 0, wp, hp, Theme.Card)
                draw.SimpleText("Motivo: " .. w.reason, "IvoWarns_Bold", 15, 18, Theme.TextMain)
                draw.SimpleText("Sanción aplicada por: " .. w.admin .. " • " .. date_str, "IvoWarns_Regular", 15, 42, Theme.TextMuted)
                
                -- Tag Activo/Expirado (Ajustamos posición si el jugador común no tiene el botón de cruz)
                local tag_text = warn_individual_activo and "ACTIVO" or "EXPIRADO"
                local tag_col  = warn_individual_activo and Theme.Danger or Theme.Success
                local tag_w = warn_individual_activo and 65 or 80
                local offset_right = isAdmin and 65 or 20
                
                draw.RoundedBox(6, wp - tag_w - offset_right, 23, tag_w, 28, Color(20, 20, 25, 150))
                draw.SimpleText(tag_text, "IvoWarns_Bold", wp - (tag_w/2) - offset_right, 37, tag_col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        -- BOTÓN DE BORRADO INDIVIDUAL (SOLO SE GENERA SI ES ADMINISTRADOR)
        if not w.is_deleted and isAdmin then
            local deleteBtn = vgui.Create("DButton", warnRow)
            deleteBtn:SetSize(40, 40)
            deleteBtn:SetText("")
            
            deleteBtn.Paint = function(self, bw, bh)
                local hover = self:IsHovered()
                draw.RoundedBox(6, 0, 0, bw, bh, hover and Theme.Danger or Color(45, 45, 55))
                local iconCol = hover and Color(255,255,255) or Theme.TextMuted
                draw.SimpleText("✕", "IvoWarns_Bold", bw/2, bh/2 - 1, iconCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            warnRow.PerformLayout = function(self, wp, hp)
                deleteBtn:SetPos(wp - 55, (hp - 40) / 2)
            end

            deleteBtn.DoClick = function()
                Derma_StringRequest(
                    "Eliminar Sanción",
                    "Ingresa el motivo para remover esta advertencia:",
                    "",
                    function(text)
                        if not text or text == "" then return end
                        net.Start("IvoWarns_DeleteSingle")
                        net.WriteUInt(w.id, 32)
                        net.WriteString(text)
                        net.SendToServer()
                    end
                )
            end
        end
    end
end
-- ==========================================
-- LISTA DE JUGADORES Y BUSCADOR
-- ==========================================

local function PopulatePlayerList(filter)
    if not IsValid(PlayerListPanel) then return end
    PlayerListPanel:Clear()

    local query = string.lower(filter or "")

    for _, ply in ipairs(CachedPlayers) do
        if query == "" 
            or string.find(string.lower(ply.name), query, 1, true) 
            or string.find(string.lower(ply.steamid), query, 1, true) 
        then
            local btn = PlayerListPanel:Add("DButton")
            btn:Dock(TOP)
            btn:SetHeight(55)
            btn:SetText("")
            btn:DockMargin(0, 0, 5, 8)

            local isSelected = (CurrentSelectedSteamID == ply.steamid)

            btn.Paint = function(self, w, h)
                local base_col = isSelected and Theme.Accent or (self:IsHovered() and Theme.CardHover or Theme.Card)
                draw.RoundedBox(8, 0, 0, w, h, base_col)
                
                local txtCol = isSelected and Color(255,255,255) or Theme.TextMain
                local mutCol = isSelected and Color(220,220,220) or Theme.TextMuted
                
                -- Indicador de estado (ON/OFF omitido del nombre crudo, lo hacemos visual)
                local isOnline = string.match(ply.name, "^%[ON%]")
                local cleanName = string.gsub(ply.name, "^%[ON%]%s*", "")
                
                if isOnline then
                    draw.RoundedBox(8, 12, h/2 - 4, 8, 8, Theme.Success)
                else
                    draw.RoundedBox(8, 12, h/2 - 4, 8, 8, Color(100, 100, 100))
                end

                draw.SimpleText(cleanName, "IvoWarns_Bold", 30, 10, txtCol)
                draw.SimpleText(ply.steamid, "IvoWarns_Small", 30, 32, mutCol)
            end

            -- REEMPLAZA LA FUNCIÓN DoClick DENTRO DE PopulatePlayerList EN cl_init_4.lua
            btn.DoClick = function()
                CurrentSelectedSteamID = ply.steamid
                CurrentLastWarnTime    = ply.last_warn

                -- 1. Forzar el redibujado de la lista para actualizar los colores
                PopulatePlayerList(SearchBar:GetValue()) 

                -- 2. Mostrar indicador de carga
                if IsValid(RightContentCanvas) then
                    RightContentCanvas:Clear()
                    local loading = RightContentCanvas:Add("DLabel")
                    loading:SetText("Sincronizando base de datos...")
                    loading:SetFont("IvoWarns_Regular")
                    loading:SetTextColor(Theme.TextMuted)
                    loading:Dock(TOP)
                    loading:SetContentAlignment(5)
                    loading:DockMargin(0, 40, 0, 0)
                end

                net.Start("IvoWarns_RequestWarns")
                net.WriteString(ply.steamid)
                net.SendToServer()
            end
        end
    end
end

-- ==========================================
-- APERTURA DEL MENÚ PRINCIPAL
-- ==========================================

local function OpenWarnMenu()
    if IsValid(WarnMenu) then WarnMenu:Remove() end

    local isAdmin = IVO_WARNS.IsAdmin(LocalPlayer())

    -- Frame Principal (Ajustamos tamaño: si es usuario común lo hacemos más angosto al no llevar barra lateral)
    WarnMenu = vgui.Create("DFrame")
    if isAdmin then
        WarnMenu:SetSize(950, 650)
    else
        WarnMenu:SetSize(670, 650)
    end
    WarnMenu:Center()
    WarnMenu:SetTitle("") 
    WarnMenu:MakePopup()

    -- Efecto de Blur y fondo
    WarnMenu.Paint = function(self, w, h)
        Derma_DrawBackgroundBlur(self, self.m_fCreateTime)
        draw.RoundedBox(12, 0, 0, w, h, Theme.Background)
        
        -- Header personalizado
        draw.RoundedBoxEx(12, 0, 0, w, 45, Theme.Sidebar, true, true, false, false)
        local titleMenu = isAdmin and "Panel de Sanciones Administrativas" or "Mis Sanciones y Advertencias"
        draw.SimpleText(titleMenu, "IvoWarns_Title", 15, 11, Theme.TextMain)
    end

    -- RENDERS EXCLUSIVOS DE ADMINISTRADOR (LISTA DE JUGADORES Y BUSCADOR)
    if isAdmin then
        local LeftPanel = vgui.Create("DPanel", WarnMenu)
        LeftPanel:Dock(LEFT)
        LeftPanel:SetWidth(280)
        LeftPanel:DockMargin(15, 15, 5, 15)
        LeftPanel.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, Theme.Sidebar)
        end

        local SearchContainer = vgui.Create("DPanel", LeftPanel)
        SearchContainer:Dock(TOP)
        SearchContainer:SetHeight(45)
        SearchContainer:DockMargin(10, 10, 10, 10)
        SearchContainer.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, Theme.Card)
        end

        SearchBar = vgui.Create("DTextEntry", SearchContainer)
        SearchBar:Dock(FILL)
        SearchBar:DockMargin(35, 5, 5, 5)
        SearchBar:SetFont("IvoWarns_Regular")
        SearchBar:SetTextColor(Theme.TextMain)
        SearchBar:SetCursorColor(Theme.TextMain)
        SearchBar:SetPaintBackground(false)
        SearchBar:SetPlaceholderText("Buscar SteamID o Nombre...")

        SearchBar.OnChange = function(self)
            PopulatePlayerList(self:GetValue())
        end

        PlayerListPanel = vgui.Create("DScrollPanel", LeftPanel)
        PlayerListPanel:Dock(FILL)
        PlayerListPanel:DockMargin(10, 0, 5, 10)
        StyleScrollbar(PlayerListPanel)
    end

    -- CONTENEDOR DE HISTORIAL
    RightContentCanvas = vgui.Create("DPanel", WarnMenu)
    RightContentCanvas:Dock(FILL)
    RightContentCanvas:DockMargin(isAdmin and 5 or 15, 15, 15, 15)
    RightContentCanvas.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Theme.Sidebar)
        if isAdmin and CurrentSelectedSteamID == "" then
            draw.SimpleText("Selecciona un jugador del panel izquierdo", "IvoWarns_Bold", w/2, h/2, Theme.TextMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    -- PETICIONES INICIALES SEGÚN RANGO
    if isAdmin then
        net.Start("IvoWarns_RequestPlayers")
        net.SendToServer()
    else
        -- Si es un usuario común, le pedimos directamente al servidor sus propios datos
        CurrentSelectedSteamID = LocalPlayer():SteamID()
        net.Start("IvoWarns_RequestWarns")
        net.WriteString(CurrentSelectedSteamID)
        net.SendToServer()
    end
end

-- ==========================================
-- RECEPTORES DE RED
-- ==========================================

net.Receive("IvoWarns_OpenMenu", function()
    OpenWarnMenu()
end)

net.Receive("IvoWarns_SendPlayers", function()
    local count = net.ReadUInt(16)
    CachedPlayers = {}
    for i = 1, count do
        table.insert(CachedPlayers, {
            steamid  = net.ReadString(),
            name     = net.ReadString(),
            last_warn = net.ReadUInt(32)
        })
    end

    local current_filter = (IsValid(SearchBar) and SearchBar:GetValue()) or ""
    PopulatePlayerList(current_filter)
end)

net.Receive("IvoWarns_SendWarns", function()
    local count     = net.ReadUInt(16)
    local lista_data = {}

    for i = 1, count do
        table.insert(lista_data, {
            id         = net.ReadUInt(32),
            admin      = net.ReadString(),
            reason     = net.ReadString(),
            time       = net.ReadUInt(32),
            is_deleted = net.ReadBit() == 1,
            del_reason = net.ReadString(),
            del_admin  = net.ReadString()
        })
    end

    RenderWarns(lista_data)
end)