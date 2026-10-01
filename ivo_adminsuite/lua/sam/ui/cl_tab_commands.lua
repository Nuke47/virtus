-- ============================================================================
-- IVOSAM: TAB COMANDOS RÁPIDOS — PREMIUM UI & CATEGORIZADO
-- ============================================================================

function IVOSAM_BuildCommandsTab(tabPanel)
    tabPanel.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
    end

    local cScroll = vgui.Create("DScrollPanel", tabPanel)
    cScroll:Dock(FILL)
    cScroll:DockMargin(20, 20, 20, 20)

    local sbar = cScroll:GetVBar()
    sbar:SetWide(6)
    function sbar:Paint(w, h) end
    function sbar.btnUp:Paint() end
    function sbar.btnDown:Paint() end
    function sbar.btnGrip:Paint(w, h) draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 15)) end

    -- Diccionario de categorías y comandos
    local categories = {
        {
            name = "Administración",
            icon = "",
            color = Color(220, 50, 50),
            commands = {
                { cmd = "!map",   desc = "Cambiar Mapa del Servidor", color = Color(200, 50, 150), hasValue = true, placeholder = "Mapa...", noTarget = true, isMapDropdown = true },
                { cmd = "!kick",  desc = "Expulsar del Servidor", color = Color(220, 100, 50), hasValue = true, placeholder = "Razón..." },
                { cmd = "!ban",   desc = "Banear (Online)",       color = Color(220, 50, 50),  hasValue = true, placeholder = "Tiempo y Razón (ej: 1d Toxicidad)..." },
                { cmd = "!banid", desc = "Banear (Offline ID)",   color = Color(180, 40, 40),  hasValue = true, placeholder = "Tiempo y Razón..." }
            }
        },
        {
            name = "Teletransporte",
            icon = "",
            color = Color(0, 150, 255),
            commands = {
                { cmd = "!goto",   desc = "Ir hacia jugador", color = Color(0, 180, 255), hasValue = false },
                { cmd = "!bring",  desc = "Traer jugador",    color = Color(0, 120, 255), hasValue = false },
                { cmd = "!return", desc = "Devolver",         color = Color(0, 200, 200), hasValue = false }
            }
        },
        {
            name = "Moderación Ligera",
            icon = "",
            color = Color(255, 140, 0),
            commands = {
                { cmd = "!jail",   desc = "Encarcelar",     color = Color(255, 140, 0), hasValue = true, placeholder = "Tiempo (seg)..." },
                { cmd = "!freeze", desc = "Congelar",       color = Color(0, 200, 255), hasValue = false },
                { cmd = "!slay",   desc = "Matar",          color = Color(200, 50, 50), hasValue = false },
                { cmd = "!strip",  desc = "Quitar Armas",   color = Color(150, 150, 150), hasValue = false },
                { cmd = "!gag",    desc = "Bloquear Voz",   color = Color(255, 180, 0), hasValue = false },
                { cmd = "!mute",   desc = "Bloquear Chat",  color = Color(255, 180, 0), hasValue = false }
            }
        },
        {
            name = "Atributos y Utilidad",
            icon = "",
            color = Color(50, 220, 100),
            commands = {
                { cmd = "!hp",       desc = "Setear Vida",     color = Color(220, 50, 50), hasValue = true, placeholder = "Cantidad HP..." },
                { cmd = "!armor",    desc = "Setear Escudo",   color = Color(50, 150, 255), hasValue = true, placeholder = "Cantidad Armor..." },
                { cmd = "!give",     desc = "Dar Arma",        color = Color(255, 200, 50), hasValue = true, placeholder = "Clase de arma..." },
                { cmd = "!setmodel", desc = "Cambiar Modelo",  color = Color(200, 100, 255), hasValue = true, placeholder = "Ruta del .mdl..." }
            }
        },
        {
            name = "Diversión & Eventos",
            icon = "",
            color = Color(255, 50, 200),
            commands = {
                { cmd = "!ignite", desc = "Prender Fuego", color = Color(255, 100, 50), hasValue = true, placeholder = "Segundos..." },
                { cmd = "!slap",   desc = "Abofetear",     color = Color(255, 150, 50), hasValue = false },
                { cmd = "!scale",  desc = "Cambiar Tamaño", color = Color(150, 50, 255), hasValue = true, placeholder = "Escala (ej: 0.5 o 2.0)..." }
            }
        }
    }

    for _, cat in ipairs(categories) do
        -- Header de Categoría
        local catHeader = cScroll:Add("DPanel")
        catHeader:Dock(TOP)
        catHeader:SetTall(40)
        catHeader:DockMargin(0, 0, 0, 10)
        catHeader.Paint = function(s, w, h)
            draw.RoundedBoxEx(8, 0, 0, w, h, IVO_SAM.Theme.BgTop, true, true, false, false)
            draw.RoundedBoxEx(8, 0, 0, 4, h, cat.color, true, false, false, false)
            draw.SimpleText(cat.icon .. "  " .. cat.name:upper(), "IVOSAM_Bold", 15, h / 2, cat.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(255, 255, 255, 10)
            surface.DrawRect(0, h - 1, w, 1)
        end

        -- Grid de Comandos dentro de la categoría
        -- Usaremos un panel contenedor flexible
        local catContainer = cScroll:Add("DPanel")
        catContainer:Dock(TOP)
        catContainer.Paint = function(s, w, h)
            draw.RoundedBoxEx(8, 0, 0, w, h, Color(18, 18, 22, 255), false, false, true, true)
        end

        local totalHeight = 10

        for _, data in ipairs(cat.commands) do
            local base = vgui.Create("DPanel", catContainer)
            base:Dock(TOP)
            base:SetTall(55)
            base:DockMargin(15, 0, 15, 10)
            base.Expanded = false
            base.HoverVal = 0
            base.Paint = function(s, w, h)
                local colBg = IVO_SAM.Theme.CardBg
                draw.RoundedBox(8, 0, 0, w, h, colBg)
                
                if s.HoverVal > 0 then
                    draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, 5 * s.HoverVal))
                end

                draw.RoundedBoxEx(8, 0, 0, 4, 55, data.color, true, false, false, false)
            end

            totalHeight = totalHeight + 65

            local btn = vgui.Create("DButton", base)
            btn:Dock(TOP)
            btn:SetTall(55)
            btn:SetText("")
            btn.Paint = function(s, w, h)
                if s:IsHovered() then
                    base.HoverVal = math.Clamp(base.HoverVal + 5 * FrameTime(), 0, 1)
                else
                    base.HoverVal = math.Clamp(base.HoverVal - 5 * FrameTime(), 0, 1)
                end

                draw.SimpleText(data.cmd:upper(), "IVOSAM_Bold", 20, h/2 - 10, IVO_SAM.Theme.TextMain)
                draw.SimpleText(data.desc, "IVOSAM_Normal", 20, h/2 + 8, IVO_SAM.Theme.TextMuted)
                
                local arrow = base.Expanded and "▲" or "▼"
                draw.SimpleText(arrow, "IVOSAM_Bold", w - 25, h/2, IVO_SAM.Theme.TextMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            local hud = vgui.Create("DPanel", base)
            hud:SetPos(15, 65)
            hud:SetSize(700, 45) -- se reajusta el width en layout si es necesario
            hud:SetVisible(false)
            hud.Paint = nil

            local inputX = 0
            
            local pSearch, pListBtn
            if not data.noTarget then
                pSearch = vgui.Create("DTextEntry", hud)
                pSearch:SetSize(180, 36)
                pSearch:SetPos(inputX, 0)
                pSearch:SetPlaceholderText("Jugador/SteamID...")
                IVO_SAM.StyleModernEntry(pSearch)

                pListBtn = vgui.Create("DButton", hud)
                pListBtn:SetSize(36, 36)
                pListBtn:SetPos(inputX + 180, 0)
                pListBtn:SetText("▼")
                pListBtn:SetTextColor(Color(200, 200, 200))
                pListBtn.Paint = function(s, w, h)
                    draw.RoundedBoxEx(6, 0, 0, w, h, Color(45, 45, 50), false, true, false, true)
                    if s:IsHovered() then draw.RoundedBoxEx(6, 0, 0, w, h, Color(60, 60, 65), false, true, false, true) end
                end
                pListBtn.DoClick = function()
                    local menu = DermaMenu()
                    menu.Paint = function(s, w, h)
                        draw.RoundedBox(6, 0, 0, w, h, IVO_SAM.Theme.BgTop)
                        surface.SetDrawColor(255, 255, 255, 10)
                        surface.DrawOutlinedRect(0, 0, w, h, 1)
                    end
                    for _, ply in ipairs(player.GetAll()) do
                        local opt = menu:AddOption(ply:Nick(), function() pSearch:SetText(ply:Nick()) end)
                        opt:SetTextColor(IVO_SAM.Theme.TextMain)
                        opt.Paint = function(s, w, h)
                            if s:IsHovered() then draw.RoundedBox(4, 2, 2, w-4, h-4, IVO_SAM.Theme.AccentGlow) end
                        end
                    end
                    menu:Open()
                end
                
                inputX = inputX + 230
            end

            local valEntry
            if data.hasValue then
                if data.isMapDropdown then
                    valEntry = vgui.Create("DComboBox", hud)
                    valEntry:SetSize(220, 36)
                    valEntry:SetPos(inputX, 0)
                    valEntry:SetValue("Seleccionar Mapa...")
                    valEntry:SetTextColor(IVO_SAM.Theme.TextMain)
                    valEntry.Paint = function(s, w, h)
                        draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 30))
                        if s:IsMenuOpen() then
                            surface.SetDrawColor(IVO_SAM.Theme.AccentGlow)
                            surface.DrawOutlinedRect(0, 0, w, h, 1)
                        end
                    end
                    
                    -- Usar la lista de mapas DEL SERVIDOR (no del cliente)
                    local serverMaps = IVO_SAM._serverMaps or {}
                    if #serverMaps == 0 then
                        -- Si aún no la tenemos, pedirla y usar fallback local mientras tanto
                        IVO_SAM.RequestServerMaps()
                        local localMaps = file.Find("maps/*.bsp", "GAME")
                        for _, map in ipairs(localMaps) do
                            valEntry:AddChoice(string.StripExtension(map))
                        end
                    else
                        for _, mapName in ipairs(serverMaps) do
                            valEntry:AddChoice(mapName)
                        end
                    end
                else
                    valEntry = vgui.Create("DTextEntry", hud)
                    valEntry:SetSize(220, 36)
                    valEntry:SetPos(inputX, 0)
                    valEntry:SetPlaceholderText(data.placeholder)
                    IVO_SAM.StyleModernEntry(valEntry)
                end
                inputX = inputX + 230
            end

            local exec = vgui.Create("DButton", hud)
            exec:SetSize(140, 36)
            exec:SetPos(inputX, 0)
            exec:SetText("EJECUTAR")
            exec:SetFont("IVOSAM_Bold")
            exec.HoverVal = 0
            exec.Paint = function(s, w, h)
                s.HoverVal = math.Clamp(s.HoverVal + (s:IsHovered() and 5 or -5) * FrameTime(), 0, 1)
                
                draw.RoundedBox(6, 0, 0, w, h, data.color)
                if s.HoverVal > 0 then
                    draw.RoundedBox(6, 0, 0, w, h, Color(255, 255, 255, 40 * s.HoverVal))
                end
                
                surface.SetDrawColor(255, 255, 255, 10)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                
                draw.SimpleText("EJECUTAR", "IVOSAM_Bold", w/2, h/2, IVO_SAM.Theme.TextMain, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                return true
            end
            exec.DoClick = function()
                local val = ""
                if data.hasValue and valEntry then
                    if data.isMapDropdown then
                        local _, mapData = valEntry:GetSelected()
                        if mapData then
                            val = mapData
                        else
                            val = valEntry:GetValue()
                        end
                    else
                        val = valEntry:GetValue()
                    end
                end

                if data.noTarget then
                    if data.hasValue and val == "" then return end
                    LocalPlayer():ConCommand("say " .. data.cmd .. " \"" .. val .. "\"")
                else
                    local tgt = pSearch and pSearch:GetValue() or ""
                    if tgt == "" then return end
                    if data.hasValue then
                        LocalPlayer():ConCommand("say " .. data.cmd .. " \"" .. tgt .. "\" \"" .. val .. "\"")
                    else
                        LocalPlayer():ConCommand("say " .. data.cmd .. " \"" .. tgt .. "\"")
                    end
                end
                
                surface.PlaySound("buttons/button14.wav")
            end

            btn.DoClick = function()
                base.Expanded = not base.Expanded
                base:SizeTo(-1, base.Expanded and 120 or 55, 0.2, 0, -1, function()
                    if IsValid(cScroll) then cScroll:InvalidateLayout() end
                end)
                hud:SetVisible(base.Expanded)
                
                -- Ajustamos el alto del contenedor animando para que empuje lo de abajo
                local diff = base.Expanded and 65 or -65
                totalHeight = totalHeight + diff
                catContainer:SizeTo(-1, totalHeight, 0.2, 0, -1)
            end
        end

        catContainer:SetTall(totalHeight)
        
        -- Separador grande entre categorías
        local spacer = cScroll:Add("DPanel")
        spacer:Dock(TOP)
        spacer:SetTall(20)
        spacer.Paint = nil
    end
end
