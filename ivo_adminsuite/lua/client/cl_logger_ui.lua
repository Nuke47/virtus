
local Colors = {
    background    = Color(40, 44, 52),
    sidebar       = Color(33, 37, 43),
    listBg        = Color(28, 32, 38), 
    detailsBg     = Color(50, 54, 60), 
    text          = Color(220, 220, 220),
    timeBg        = Color(80, 85, 95),
    accent        = Color(52, 152, 219), -- <--- ¡ESTA COMA ES VITAL!
    -- Paleta de colores para el fondo de los títulos de categorías
    CatColors = {
        ["LOGS"]    = Color(241, 196, 15),   -- Amarillo
        ["GENERAL"] = Color(52, 152, 219),   -- Azul
        ["SANDBOX"] = Color(46, 204, 113),   -- Verde
        ["DARKRP"]  = Color(231, 76, 60),    -- Rojo
        ["ADMIN"]   = Color(155, 89, 182)    -- Morado
    }
}




surface.CreateFont("Ivo_logsT", { font = "Roboto", size = 24, weight = 800 })
surface.CreateFont("Ivo_logs_Small", { font = "Roboto", size = 15, weight = 400 })
surface.CreateFont("Ivo_logs_Bold", { font = "Roboto", size = 16, weight = 800 })
surface.CreateFont("Ivo_logs_Category", { font = "Roboto", size = 12, weight = 800 })

-- Componente de Tarjetas Inferiores
local function CreateLogBox(type, title, subtitle, iconSource)
    local box = vgui.Create("DPanel")
    box:SetSize(220, 46)

    function box:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(65, 70, 80))
        draw.RoundedBox(4, 0, 0, 4, h, type == "player" and Color(50, 150, 250) or Color(250, 150, 50))
        
        draw.SimpleText(title, "Ivo_logs_Bold", 50, 5, color_white)
        draw.SimpleText(subtitle, "Ivo_logs_Small", 50, 25, Color(180, 180, 180))
    end

    if type == "player" then
        local av = vgui.Create("AvatarImage", box)
        av:SetSize(32, 32)
        av:SetPos(10, 7)
        av:SetSteamID(iconSource, 64)
    elseif type == "item" then
        local mdl = vgui.Create("SpawnIcon", box)
        mdl:SetSize(32, 32)
        mdl:SetPos(10, 7)
        mdl:SetModel(iconSource)
        mdl:SetMouseInputEnabled(false)
        mdl:SetToolTip(nil)
    end
    
    return box
end

-- Menú Principal
local function IvoLogsOpenMenu(logData)
    local frame = vgui.Create("DFrame")
    IvoLogs_MainFrame = frame -- Guardamos la referencia global aquí
    frame:SetSize(1100, 700)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(true)
    frame:MakePopup()

    function frame:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Colors.background)
    end

    -- PANEL DE DETALLES (Inferior Absoluto)
    local detailsPanel = vgui.Create("DPanel", frame)
    detailsPanel:Dock(BOTTOM)
    detailsPanel:SetTall(80) 
    detailsPanel:DockMargin(0, 0, 0, 0)
    function detailsPanel:Paint(w, h)
        draw.RoundedBoxEx(8, 0, 0, w, h, Colors.detailsBg, false, false, true, true)
        if #self:GetChildren() == 0 then
            draw.SimpleText("Selecciona un log de la lista para ver los detalles aquí...", "Ivo_logs_Small", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    
    -- SIDEBAR (Izquierda)
    -- Bajamos el sidebar un poquito (15px) para dejar espacio al título
    local sidebar = vgui.Create("DPanel", frame)
    sidebar:Dock(LEFT)
    sidebar:SetWide(180)
    sidebar:DockMargin(0, 45, 0, 0) -- Margin Top de 45px para bajar el sidebar
    function sidebar:Paint(w, h)
        draw.RoundedBoxEx(8, 0, 0, w, h, Colors.sidebar, false, false, false, false) -- Ajuste de bordes
    end

    -- TÍTULO "IvoLogs" arriba a la izquierda
    local logoPanel = vgui.Create("DPanel", frame)
    logoPanel:SetPos(10, 10)
    logoPanel:SetSize(160, 40)
    function logoPanel:Paint(w, h)
        draw.SimpleText("IvoLogs", "Ivo_logsT", 0, 0, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        -- Opcional: una pequeña línea decorativa abajo del texto
        draw.RoundedBox(0, 0, 32, 80, 2, Colors.accent)
    end

    local sidebarScroll = vgui.Create("DScrollPanel", sidebar)
    sidebarScroll:Dock(FILL)
    sidebarScroll:DockMargin(5, 15, 5, 5)

    local sbarSide = sidebarScroll:GetVBar()
    sbarSide:SetWide(0) -- Esto hace que la barra sea invisible
    sbarSide:SetVisible(false)

    -- ÁREA DE CONTENIDO (Derecha)
    local mainArea = vgui.Create("DPanel", frame)
    mainArea:Dock(FILL)
    function mainArea:Paint(w, h) end

    -- ENCABEZADO DE COLUMNAS (Top del Main Area)
    local header = vgui.Create("DPanel", mainArea)
    header:Dock(TOP)
    header:SetTall(25)
    header:DockMargin(10, 10, 10, 0)
    function header:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(35, 39, 47))
        draw.SimpleText("TIEMPO / FECHA", "Ivo_logs_Bold", 15, h/2, Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("CATEGORÍA", "Ivo_logs_Bold", 185, h/2, Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("LOG / MENSAJE DETALLADO", "Ivo_logs_Bold", 305, h/2, Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- BARRA DE NAVEGACIÓN Y BÚSQUEDA (Abajo de la Lista)
    local controlPanel = vgui.Create("DPanel", mainArea)
    controlPanel:Dock(BOTTOM)
    controlPanel:SetTall(35)
    controlPanel:DockMargin(10, 5, 10, 5)
    function controlPanel:Paint(w, h) end

    -- SCROLL DE LOGS (Rellena el espacio entre Header y ControlPanel)
    local scroll = vgui.Create("DScrollPanel", mainArea)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 5, 10, 0)
    function scroll:Paint(w, h) draw.RoundedBox(4, 0, 0, w, h, Colors.listBg) end

    local sbar = scroll:GetVBar()
    sbar:SetWide(8) -- Más delgada y minimalista
    sbar:DockMargin(0, 4, 4, 4) -- Separación ligera de los bordes del contenedor

    function sbar:Paint(w, h)
        -- Fondo de la barra transparente para que no ensucie tu fondo 'Colors.listBg'
    end

    -- El botón/barra que se arrastra (Grip)
    function sbar.btnGrip:Paint(w, h)
        local gripColor = Color(100, 110, 125, 100) -- Gris azulado sutil con transparencia
        
        if self:IsHovered() then
            gripColor = Color(130, 145, 165, 180) -- Más visible al pasar el mouse
        elseif self.Depressed then
            gripColor = Color(230, 126, 34, 200) -- Cambia a un tono naranja (a juego con tu línea) al arrastrarlo
        end
        
        draw.RoundedBox(4, 0, 0, w, h, gripColor)
    end

    -- Ocultamos los botones antiguos de arriba y abajo
    function sbar.btnUp:Paint(w, h) end
    function sbar.btnDown:Paint(w, h) end

    -- VARIABLES DE ESTADO DE PAGINACIÓN Y FILTRADO
    local activeFilter = "All"
    local searchText = ""
    local currentPage = 1
    local totalPages = 1

    -- ELEMENTOS INTERNOS DEL PANEL DE CONTROL (Botones e Inputs)
    local btnPrev = vgui.Create("DButton", controlPanel)
    btnPrev:Dock(LEFT)
    btnPrev:SetWide(35)
    btnPrev:SetText("◀")
    btnPrev:SetFont("Ivo_logs_Small")
    btnPrev:SetTextColor(color_white)
    function btnPrev:Paint(w, h)
        local bg = self:IsHovered() and Color(60, 65, 75) or Color(35, 39, 47)
        draw.RoundedBox(4, 0, 4, w, h - 8, bg)
    end

    local pageLabel = vgui.Create("DLabel", controlPanel)
    pageLabel:Dock(LEFT)
    pageLabel:SetWide(120)
    pageLabel:SetText("Página 1 de 1")
    pageLabel:SetFont("Ivo_logs_Small")
    pageLabel:SetColor(Color(180, 180, 180))
    pageLabel:SetContentAlignment(5)

    local btnNext = vgui.Create("DButton", controlPanel)
    btnNext:Dock(LEFT)
    btnNext:SetWide(35)
    btnNext:SetText("▶")
    btnNext:SetFont("Ivo_logs_Small")
    btnNext:SetTextColor(color_white)
    function btnNext:Paint(w, h)
        local bg = self:IsHovered() and Color(60, 65, 75) or Color(35, 39, 47)
        draw.RoundedBox(4, 0, 4, w, h - 8, bg)
    end

    local jumpBtn = vgui.Create("DButton", controlPanel)
    jumpBtn:Dock(RIGHT)
    jumpBtn:SetWide(65)
    jumpBtn:SetText("Jump")
    jumpBtn:SetFont("Ivo_logs_Bold")
    jumpBtn:SetTextColor(color_white)
    function jumpBtn:Paint(w, h)
        local bg = self:IsHovered() and Colors.accent or Color(45, 50, 60)
        draw.RoundedBox(4, 0, 4, w, h - 8, bg)
    end

    local searchBar = vgui.Create("DTextEntry", controlPanel)
    searchBar:Dock(RIGHT)
    searchBar:SetWide(220)
    searchBar:DockMargin(0, 4, 8, 4)
    searchBar:SetPlaceholderText("Buscar texto o Nº de página...")
    searchBar:SetFont("Ivo_logs_Small")
    searchBar:SetTextColor(Color(230, 230, 230))
    searchBar:SetCursorColor(Colors.accent)
    function searchBar:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(28, 32, 38))
        self:DrawTextEntryText(Color(220, 220, 220), Colors.accent, Color(220, 220, 220))
    end

    -- FUNCIÓN PRINCIPAL DE RENDERIZACIÓN POR PÁGINAS (Max 50)
    local function RefreshLogs()
        scroll:Clear()
        scroll:GetVBar():SetScroll(0)
        detailsPanel:Clear()

        -- DETERMINAR FUENTE DE DATOS
        -- Si el filtro activo es 'deep_storage', usamos la data guardada, si no, la normal
        local sourceData = (activeFilter == "deep_storage") and IvoLogs_DeepData or logData -- Corrección para leer de la tabla correcta local

        -- 1. Filtrar la data global en una tabla secuencial limpia
        local filtered = {}
        for k, v in ipairs(sourceData) do
            local allowed = false
            local loopCatLower = string.lower(v.category or "")

            if activeFilter == "All" or activeFilter == "deep_storage" then
                allowed = true
            elseif type(activeFilter) == "table" then
                for _, f in ipairs(activeFilter) do
                    local fLower = string.lower(f or "")
                    if loopCatLower == fLower or (fLower ~= "" and string.find(loopCatLower, fLower, 1, true)) then 
                        allowed = true 
                        break 
                    end
                end
            elseif type(activeFilter) == "string" then
                local fLower = string.lower(activeFilter)
                if loopCatLower == fLower or (fLower ~= "" and string.find(loopCatLower, fLower, 1, true)) then
                    allowed = true
                end
            end

            if allowed and searchText ~= "" then
                local msgLower = string.lower(v.msg or "")
                local searchLower = string.lower(searchText)
                if not string.find(msgLower, searchLower, 1, true) then
                    allowed = false
                end
            end

            if allowed then
                table.insert(filtered, v)
            end
        end

        -- 2. Calcular límites exactos de páginas
        totalPages = math.max(1, math.ceil(#filtered / 50))
        currentPage = math.Clamp(currentPage, 1, totalPages)

        if IsValid(pageLabel) then
            pageLabel:SetText("Página " .. currentPage .. " de " .. totalPages)
        end

        -- 3. Renderizar estrictamente el rango correspondiente a la página actual
        local startIndex = (currentPage - 1) * 50 + 1
        local endIndex = math.min(currentPage * 50, #filtered)

        for i = startIndex, endIndex do
            local v = filtered[i]
            if not v then continue end

            local btn = scroll:Add("DButton")
            btn:Dock(TOP)
            btn:DockMargin(5, 5, 5, 0)
            btn:SetTall(30)
            btn:SetText("")
            
            function btn:Paint(w, h)
                local bgColor = self:IsHovered() and Color(60, 65, 75) or Color(45, 50, 60)
                draw.RoundedBox(4, 0, 0, w, h, bgColor)
                
                -- Tiempo
                draw.SimpleText(v.time or "", "Ivo_logs_Small", 15, h/2, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                
                -- Categoría
                local catLower = string.lower(v.category or "")
                local catColor = Color(46, 204, 113)
                if catLower == "kill" then catColor = Color(231, 76, 60)
                elseif string.find(catLower, "da", 1, true) then catColor = Color(230, 126, 34)
                elseif catLower == "chat" then catColor = Color(52, 152, 219)
                elseif catLower == "sweps" or catLower == "pickups" then catColor = Color(155, 89, 182)
                elseif string.find(catLower, "conex", 1, true) then catColor = Color(22, 160, 133)
                elseif catLower == "props" or catLower == "sents" then catColor = Color(216, 219, 52)
                elseif catLower == "remove" then catColor = Color(219, 127, 52)
                elseif catLower == "ban" then catColor = Color(255,255,255)
                elseif catLower == "unban" then catColor = Color(255,255,255)
                elseif catLower == "job" then catColor = Color(255,255,255)
                elseif catLower == "dinero" then catColor = Color(255,255,255)
                elseif catLower == "allanamiento" then catColor = Color(255,255,255)
                elseif catLower == "compra" then catColor = Color(255,255,255)
                elseif catLower == "kick" then catColor = Color(255,255,255)
                end
                draw.SimpleText(v.category or "Log", "Ivo_logs_Bold", 185, h/2, catColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                
                -- [SOLUCIÓN] 
                -- 1. Parseamos sin límite de ancho (para que no salte de línea)
                if not self.ParsedMarkup then
                    local baseMarkup = "<color=255,255,255><font=Ivo_logs_Small>" .. (v.msg or "") .. "</font></color>"
                    self.ParsedMarkup = markup.Parse(baseMarkup, 9999) 
                end
                
                -- 2. Recortamos visualmente con ScissorRect para que parezca cortado en el borde derecho
                local x, y = self:LocalToScreen(305, 0)
                render.SetScissorRect(x, y, x + (w - 320), y + h, true)
                
                -- 3. Dibujamos centrado verticalmente
                local _, markupHeight = self.ParsedMarkup:Size()
                self.ParsedMarkup:Draw(305, h/2 - markupHeight/2)
                
                -- 4. Desactivamos el recorte
                render.SetScissorRect(0, 0, 0, 0, false)
            end
            
            
            -- [CLICK IZQUIERDO NORMAL] - Abre el panel inferior (Tu código actual)
            btn.DoClick = function()
                detailsPanel:Clear() 

                local leftBlock = vgui.Create("DPanel", detailsPanel)
                leftBlock:Dock(LEFT)
                leftBlock:SetWide(160)
                function leftBlock:Paint(w, h)
                    local catLower = string.lower(v.category or "")
                    local catColor = Color(46, 204, 113) 

                    if catLower == "kill" then catColor = Color(231, 76, 60)
                    elseif string.find(catLower, "da", 1, true) then catColor = Color(230, 126, 34)
                    elseif catLower == "chat" then catColor = Color(52, 152, 219)
                    elseif string.find(catLower, "conex", 1, true) then catColor = Color(22, 160, 133) end

                    draw.RoundedBox(0, 0, 0, w, h/2, catColor)
                    draw.SimpleText(v.category or "Log", "Ivo_logs_Bold", w/2, h/4, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                    draw.RoundedBoxEx(8, 0, h/2, w, h/2, Colors.timeBg, false, false, true, false)
                    draw.SimpleText(v.time or "00:00:00", "Ivo_logs_Small", w/2, h*0.75, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end

                local rightBlock = vgui.Create("DHorizontalScroller", detailsPanel)
                rightBlock:Dock(RIGHT)
                rightBlock:SetWide(460)
                rightBlock:DockMargin(15, 17, 10, 17) 
                rightBlock:SetOverlap(-5)

                if v.extra then
                    if v.extra.attacker then rightBlock:AddPanel(CreateLogBox("player", v.extra.attacker.name, v.extra.attacker.sid, v.extra.attacker.sid64)) end
                    if v.extra.weapon then rightBlock:AddPanel(CreateLogBox("item", v.extra.weapon.name, v.extra.weapon.class, v.extra.weapon.model)) end
                    if v.extra.victim then rightBlock:AddPanel(CreateLogBox("player", v.extra.victim.name, v.extra.victim.sid, v.extra.victim.sid64)) end
                end

                local separator = vgui.Create("DPanel", detailsPanel)
                separator:Dock(RIGHT)
                separator:SetWide(2)
                separator:DockMargin(5, 10, 5, 10)
                function separator:Paint(w, h)
                    draw.RoundedBox(0, 0, 0, w, h, Color(230, 126, 34, 150))
                end

                local allowedWidth = detailsPanel:GetWide() - 670
                if allowedWidth < 200 then allowedWidth = 400 end 

                local detailMarkup = markup.Parse("<color=255,255,255><font=Ivo_logs_Small>" .. (v.msg or "") .. "</font></color>", allowedWidth)
                local _, detailHeight = detailMarkup:Size()

                local midBlock = vgui.Create("DPanel", detailsPanel)
                midBlock:Dock(FILL)
                midBlock:DockMargin(15, 2, 5, 2) 
                
                function midBlock:Paint(w, h)
                    local renderY = (h - detailHeight) / 2
                    if renderY < 0 then renderY = 5 end
                    detailMarkup:Draw(0, renderY, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
            end

            btn.DoRightClick = function(self)
                local menu = DermaMenu()

                function menu:Paint(w, h)
                    draw.RoundedBox(6, 0, 0, w, h, Color(30, 35, 45, 255)) 
                    surface.SetDrawColor(60, 65, 75, 100) 
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end

                local function EstilizarOpcion(opt, icon)
                    if not IsValid(opt) then return end
                    opt:SetFont("Ivo_logs_Small")
                    opt:SetTextColor(Color(230, 230, 230))
                    if icon then opt:SetIcon(icon) end
                    
                    function opt:Paint(w, h)
                        if self:IsHovered() then
                            draw.RoundedBox(4, 2, 2, w - 4, h - 4, Color(55, 65, 80, 255))
                            self:SetTextColor(color_white)
                        else
                            self:SetTextColor(Color(210, 210, 210))
                        end
                    end
                end

                local function EstilizarEspaciador(spacer)
                    if not IsValid(spacer) then return end
                    function spacer:Paint(w, h)
                        surface.SetDrawColor(45, 50, 60, 255)
                        surface.DrawLine(5, h / 2, w - 5, h / 2)
                    end
                end

                -- [NUEVO CÓDIGO AÑADIDO AQUÍ] Botón de Cámara Libre para Asesinatos
                local catLower = string.lower(v.category or "")
                if catLower == "kill" and v.extra and v.extra.attacker and v.extra.victim then
                    local optScene = menu:AddOption("Ver posición de muerte", function()
                        -- Llamamos a la función global del nuevo archivo
                        if IvoLogs_OpenDeathScene then
                            IvoLogs_OpenDeathScene(v.extra.attacker, v.extra.victim)
                        else
                            chat.AddText(Color(231, 76, 60), "[IvoLogs] ", color_white, "Error: El archivo de cámara 3D no está cargado.")
                        end
                    end)
                    EstilizarOpcion(optScene, "icon16/camera.png")
                    
                    local spacerTop = menu:AddSpacer()
                    EstilizarEspaciador(spacerTop)
                end
                -- [FIN DEL NUEVO CÓDIGO]

                local optLog = menu:AddOption("Copiar log completo", function()
                    local cleanMsg = string.gsub(v.msg or "", "<.->", "")
                    local fullLog = "[" .. (v.time or "00:00:00") .. "] [" .. (v.category or "Log") .. "] " .. cleanMsg
                    SetClipboardText(fullLog)
                    chat.AddText(Color(46, 204, 113), "[IvoLogs] ", color_white, "¡Log completo copiado al portapapeles!")
                end)
                EstilizarOpcion(optLog, "icon16/page_white_copy.png")

                local spacer1 = menu:AddSpacer()
                EstilizarEspaciador(spacer1)

                -- 2. Submenú para el ATACANTE
                if v.extra and v.extra.attacker then
                    local att = v.extra.attacker
                    local attMenu, attOption = menu:AddSubMenu("Datos del Atacante")
                    EstilizarOpcion(attOption, "icon16/user.png")
                    
                    -- Estilizar el menú desplegable del submenú
                    function attMenu:Paint(w, h)
                        draw.RoundedBox(6, 0, 0, w, h, Color(30, 35, 45, 255))
                        surface.SetDrawColor(60, 65, 75, 100)
                        surface.DrawOutlinedRect(0, 0, w, h, 1)
                    end

                    local o1 = attMenu:AddOption("Copiar Nombre: " .. att.name, function() SetClipboardText(att.name) end)
                    EstilizarOpcion(o1, "icon16/textfield_rename.png")

                    if att.sid then
                        local o2 = attMenu:AddOption("Copiar SteamID", function() SetClipboardText(att.sid) end)
                        EstilizarOpcion(o2, "icon16/tag_blue.png")
                    end

                    if att.sid64 then
                        local o3 = attMenu:AddOption("Copiar SteamID64", function() SetClipboardText(att.sid64) end)
                        EstilizarOpcion(o3, "icon16/key.png")
                    end
                end

                -- 3. Submenú para la VÍCTIMA
                if v.extra and v.extra.victim then
                    local vic = v.extra.victim
                    local vicMenu, vicOption = menu:AddSubMenu("Datos de la Víctima")
                    EstilizarOpcion(vicOption, "icon16/user_female.png")

                    function vicMenu:Paint(w, h)
                        draw.RoundedBox(6, 0, 0, w, h, Color(30, 35, 45, 255))
                        surface.SetDrawColor(60, 65, 75, 100)
                        surface.DrawOutlinedRect(0, 0, w, h, 1)
                    end

                    local o1 = vicMenu:AddOption("Copiar Nombre: " .. vic.name, function() SetClipboardText(vic.name) end)
                    EstilizarOpcion(o1, "icon16/textfield_rename.png")

                    if vic.sid then
                        local o2 = vicMenu:AddOption("Copiar SteamID", function() SetClipboardText(vic.sid) end)
                        EstilizarOpcion(o2, "icon16/tag_pink.png")
                    end

                    if vic.sid64 then
                        local o3 = vicMenu:AddOption("Copiar SteamID64", function() SetClipboardText(vic.sid64) end)
                        EstilizarOpcion(o3, "icon16/key.png")
                    end
                end

                -- Abrir el menú
                menu:Open()
            end
        end
    end
    
    frame.RefreshLogs = RefreshLogs -- Exponemos la función al frame

    -- LÓGICA DE EVENTOS DE LOS CONTROLES
    btnPrev.DoClick = function()
        if currentPage > 1 then
            currentPage = currentPage - 1
            RefreshLogs()
        end
    end

    btnNext.DoClick = function()
        if currentPage < totalPages then
            currentPage = currentPage + 1
            RefreshLogs()
        end
    end

    local function ExecuteJump()
        local val = searchBar:GetValue()
        local pageNum = tonumber(val)

        if pageNum then
            -- Si es un número válido, salta a la página limpia manteniendo filtros actuales
            currentPage = math.Clamp(pageNum, 1, totalPages)
        else
            -- Si es texto, aplica el criterio de búsqueda y resetea a la primera página de resultados
            searchText = val
            currentPage = 1
        end
        RefreshLogs()
    end

    jumpBtn.DoClick = ExecuteJump
    searchBar.OnEnter = ExecuteJump

    -- ESTRUCTURA DEL SIDEBAR
    local MenuStructure = {
        {
            header = "LOGS",
            buttons = {
                { name = "Todos los logs", filter = "All" },
                { name = "Deep Storage", filter = "deep_storage" }
            }
        },
        {
            header = "GENERAL",
            buttons = {
                { name = "Chat", filter = "Chat" },
                { name = "Connections", filter = { "conex" } }, 
                { name = "Damage", filter = { "da" } }, 
                { name = "Kill/Deaths", filter = "Kill" },
                { name = "Pickups", filter = { "Pickups", "SWEPs" } }
            }
        },
        {
            header = "SANDBOX",
            buttons = {
                { name = "Props", filter = "Props" },
                { name = "SENTs", filter = { "Spawn", "SENTs", "Remove" } }, 
                { name = "SWEPs", filter = { "da" } }, 
                { name = "NPCs", filter = {  } },
                { name = "Pickups", filter = { "Pickups", "SWEPs" } }
            }
        },
        {
            header = "DARKRP",
            buttons = {
                { name = "Jobs", filter = "JOB" },
                { name = "Arrestos", filter = "ARRESTO" }, 
                { name = "Dinero", filter = "DINERO" }, 
                { name = "Allanamiento", filter =  "ALLANAMIENTO" },
                { name = "Compras", filter = "COMPRA" }
            }
        },
        {
            header = "ADMIN",
            buttons = {
                { name = "BANs", filter = { "BAN", "UNBAN" } },
                { name = "WARNs", filter = "BAN" },
                { name = "KICKs", filter = "KICK" }
            }
        }
    }

    -- CONSTRUCCIÓN DEL MENÚ DESPLEGABLE
    for _, section in ipairs(MenuStructure) do
        local catHeader = sidebarScroll:Add("DButton")
        catHeader:Dock(TOP)
        catHeader:SetTall(22)
        catHeader:SetText("")
        catHeader:DockMargin(5, 10, 5, 2)
        
        catHeader.Expanded = true 

        local targetTall = #section.buttons * 30 
        
        local subContainer = sidebarScroll:Add("DPanel")
        subContainer:Dock(TOP)
        subContainer:SetPaintBackground(false)
        subContainer:SetTall(targetTall)
        subContainer:DockMargin(0, 0, 0, 0)

        -- [NUEVO] Obtener color de categoría o usar gris por defecto
        local catColor = Colors.CatColors[section.header] or Color(160, 165, 175)

        function catHeader:Paint(w, h)
            -- Medimos cuánto ocupa la palabra de la categoría
            surface.SetFont("Ivo_logs_Category")
            local textWidth = surface.GetTextSize(section.header)
            
            -- Dibujamos el icono de la flecha a la izquierda
            local icon = self.Expanded and "▼" or "▶"
            draw.SimpleText(icon, "Ivo_logs_Category", 5, h / 2, Color(160, 165, 175), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            -- Dibujamos el rectángulo coloreado EXACTAMENTE detrás de la palabra
            -- Posición X: 20 (dejando espacio para la flecha). Ancho: tamaño de la palabra + 10px de margen
            draw.RoundedBox(4, 20, 2, textWidth + 10, h - 4, catColor)
            
            -- Dibujamos el nombre de la categoría encima del rectángulo
            draw.SimpleText(section.header, "Ivo_logs_Category", 25, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        catHeader.DoClick = function()
            catHeader.Expanded = not catHeader.Expanded
            subContainer:SetTall(catHeader.Expanded and targetTall or 0)
            subContainer:SetVisible(catHeader.Expanded)
            
            if IsValid(sidebarScroll:GetCanvas()) then
                sidebarScroll:GetCanvas():InvalidateLayout(true)
            end
        end

        for _, btnData in ipairs(section.buttons) do
            local sBtn = subContainer:Add("DButton")
            sBtn:Dock(TOP)
            sBtn:SetTall(28)
            sBtn:SetText("")
            sBtn:DockMargin(5, 2, 5, 0)

            function sBtn:Paint(w, h)
                local isCurrent = activeFilter == btnData.filter or (type(activeFilter) == "table" and type(btnData.filter) == "table" and activeFilter[1] == btnData.filter[1])
                local bgColor = Color(0, 0, 0, 0)
                local textColor = Color(160, 165, 175)

                if isCurrent then
                    bgColor = Color(55, 65, 80)
                    textColor = color_white
                elseif self:IsHovered() then
                    bgColor = Color(45, 50, 60)
                    textColor = color_white
                end

                draw.RoundedBox(4, 0, 0, w, h, bgColor)
                
                -- [NUEVO] Pintamos una pequeña línea lateral del color de la categoría
                if isCurrent then
                    draw.RoundedBox(2, 2, 4, 3, h - 8, catColor)
                end

                draw.SimpleText(btnData.name, "Ivo_logs_Small", 12, h / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            sBtn.DoClick = function()
                if btnData.filter == "deep_storage" or btnData.name == "Deep Storage" then
                    -- Cambiamos el filtro y la página para que la UI sepa que estamos en Deep Storage
                    activeFilter = "deep_storage"
                    searchText = ""
                    currentPage = 1
                    if IsValid(searchBar) then searchBar:SetText("") end
                    
                    -- Pedimos la información al servidor
                    net.Start("IvoLogs_RequestDeepStorage")
                    net.SendToServer()
                    
                    RefreshLogs() -- Refrescamos la UI (mostrará vacío o datos viejos hasta que llegue el net.Receive)
                    return
                end

                -- Comportamiento normal para las demás categorías
                activeFilter = btnData.filter
                searchText = ""
                currentPage = 1 -- Reiniciar a la página 1 al cambiar de categoría
                if IsValid(searchBar) then searchBar:SetText("") end
                RefreshLogs()
            end
        end
    end

    RefreshLogs()
end

net.Receive("IvoLogs_OpenMenu", function()
    local bytesCount = net.ReadUInt(32)
    local compressedData = net.ReadData(bytesCount)
    
    local jsonStr = util.Decompress(compressedData)
    if not jsonStr then return end

    local logData = util.JSONToTable(jsonStr)

    if logData and type(logData) == "table" then
        IvoLogsOpenMenu(logData)
    end
end)

-- ==========================================================
-- [DEEP STORAGE] RECEPTOR Y RENDERIZADO EN LA UI EXISTENTE
-- ==========================================================
IvoLogs_DeepData = IvoLogs_DeepData or {}

net.Receive("IvoLogs_SendDeepStorage", function()
    local bytesCount = net.ReadUInt(32)
    local compressedData = net.ReadData(bytesCount)
    local jsonStr = util.Decompress(compressedData)
    if not jsonStr then return end
    
    -- Guardamos los logs en la variable global sin destruir el menú
    IvoLogs_DeepData = util.JSONToTable(jsonStr) or {}
    
    -- Verificamos que el frame exista y que tenga la función adjunta
    if IsValid(IvoLogs_MainFrame) and IvoLogs_MainFrame.RefreshLogs then
        chat.AddText(Color(230, 126, 34), "[IvoLogs] ", color_white, "Histórico cargado: " .. #IvoLogs_DeepData .. " registros.")
        
        -- Ejecutamos la función de refresco del frame actual
        IvoLogs_MainFrame.RefreshLogs()
    end
end)
