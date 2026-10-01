-- ============================================================================
-- IVOSAM: PESTAÑA DE XP Y NIVELES (PREMIUM UI)
-- ============================================================================

function IVOSAM_BuildXPTab(parent)
    local pnl = vgui.Create("DPanel", parent)
    pnl:Dock(FILL)
    pnl.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0)) -- Transparente
    end

    -- Header y Buscador (Estilo Tab Jugadores)
    local searchBG = vgui.Create("DPanel", pnl)
    searchBG:Dock(TOP)
    searchBG:SetHeight(50)
    searchBG:DockMargin(15, 15, 15, 10)
    searchBG.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, IVO_SAM.Theme.BgTop)
    end

    local searchEntry = vgui.Create("DTextEntry", searchBG)
    searchEntry:Dock(FILL)
    searchEntry:DockMargin(15, 10, 60, 10)
    searchEntry:SetPlaceholderText("Buscar por SteamID o Nombre...")
    searchEntry:SetUpdateOnType(true)
    IVO_SAM.StyleModernEntry(searchEntry)
    
    local btnRefresh = vgui.Create("DButton", searchBG)
    btnRefresh:SetSize(40, 30)
    btnRefresh:Dock(RIGHT)
    btnRefresh:DockMargin(0, 10, 15, 10)
    btnRefresh:SetText("↻")
    btnRefresh:SetFont("IVOSAM_Icon")
    btnRefresh:SetTextColor(IVO_SAM.Theme.TextMain)
    btnRefresh.Paint = function(s, w, h)
        local bg = s:IsHovered() and Color(35, 35, 45) or Color(25, 25, 30)
        draw.RoundedBox(6, 0, 0, w, h, bg)
    end
    btnRefresh.DoClick = function()
        net.Start("IVO_RequestXPData")
        net.SendToServer()
    end

    local pScroll = vgui.Create("DScrollPanel", pnl)
    pScroll:Dock(FILL)
    pScroll:DockMargin(15, 0, 15, 15)

    local sbar = pScroll:GetVBar()
    sbar:SetWide(6)
    function sbar:Paint(w, h) end
    function sbar.btnUp:Paint() end
    function sbar.btnDown:Paint() end
    function sbar.btnGrip:Paint(w, h) draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 15)) end

    local cachedData = {}

    local function PopulateList(filter)
        if not IsValid(pScroll) then return end
        pScroll:Clear()
        
        filter = (filter or ""):lower()

        for _, row in ipairs(cachedData) do
            local sid64 = tostring(row.steamid64 or "")
            local name = tostring(row.pName or "Desconocido")
            local xp = tonumber(row.xp) or 0
            local lvl = tonumber(row.level) or 1
            
            if filter ~= "" and not (name:lower():find(filter) or sid64:lower():find(filter)) then
                continue
            end
            
            local plyObj = player.GetBySteamID64(sid64)
            local isOnline = IsValid(plyObj)
            
            -- Crear tarjeta estilo premium
            local card = pScroll:Add("DPanel")
            card:Dock(TOP)
            card:SetHeight(65)
            card:DockMargin(0, 0, 5, 8)
            card.HoverVal = 0
            
            card.Paint = function(s, w, h)
                if s:IsHovered() then
                    s.HoverVal = math.Clamp(s.HoverVal + 8 * FrameTime(), 0, 1)
                else
                    s.HoverVal = math.Clamp(s.HoverVal - 8 * FrameTime(), 0, 1)
                end

                local baseCol = IVO_SAM.Theme.CardBg
                draw.RoundedBox(8, 0, 0, w, h, baseCol)
                
                if s.HoverVal > 0 then
                    draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, 5 * s.HoverVal))
                end

                local colorIndicador = isOnline and Color(0, 255, 150) or Color(100, 100, 100)
                draw.RoundedBoxEx(8, 0, 0, 4, h, colorIndicador, true, false, true, false)
                
                draw.SimpleText(name, "IVOSAM_Tab", 65, 15, IVO_SAM.Theme.TextMain)
                draw.SimpleText(sid64 .. (isOnline and " (Online)" or " (Offline)"), "IVOSAM_Normal", 65, 38, IVO_SAM.Theme.TextMuted)
                
                -- Badges de Nivel y XP
                local rx = w - 180
                
                surface.SetFont("IVOSAM_Normal")
                local lvlText = "Nvl: " .. lvl
                local lvlW = surface.GetTextSize(lvlText) + 16
                draw.RoundedBox(6, rx - lvlW, 14, lvlW, 37, Color(255, 160, 0, 20))
                draw.SimpleText(lvlText, "IVOSAM_Tab", rx - lvlW/2, 32, Color(255, 180, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                
                rx = rx + 8
                local xpText = "XP: " .. xp
                local xpW = surface.GetTextSize(xpText) + 16
                draw.RoundedBox(6, rx, 14, xpW, 37, Color(0, 140, 255, 20))
                draw.SimpleText(xpText, "IVOSAM_Tab", rx + xpW/2, 32, Color(0, 160, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            card:SetCursor("hand")

            local avBG = vgui.Create("DPanel", card)
            avBG:SetSize(44, 44)
            avBG:SetPos(12, 10)
            avBG.Paint = function(s, w, h)
                draw.RoundedBox(8, 0, 0, w, h, IVO_SAM.Theme.BgTop)
            end

            local av = vgui.Create("AvatarImage", avBG)
            av:SetSize(40, 40)
            av:SetPos(2, 2)
            av:SetSteamID(sid64, 64)

            card.OnMousePressed = function(s, mouse)
                if mouse == MOUSE_RIGHT then
                    local m = DermaMenu()
                    
                    local function StyleMenu(menu)
                        menu.Paint = function(sm, w, h)
                            draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 30, 250))
                            surface.SetDrawColor(IVO_SAM.Theme.AccentGlow)
                            surface.DrawOutlinedRect(0, 0, w, h, 1)
                        end
                    end
                    
                    local function AddStyledOption(menu, text, func, icon)
                        local opt = menu:AddOption(text, func)
                        if icon then opt:SetIcon(icon) end
                        opt:SetTextColor(IVO_SAM.Theme.TextMain)
                        opt.Paint = function(so, w, h)
                            if so:IsHovered() then 
                                draw.RoundedBox(4, 2, 2, w-4, h-4, IVO_SAM.Theme.AccentGlow) 
                            end
                        end
                        return opt
                    end
                    
                    local function AddStyledSpacer(menu)
                        local spc = menu:AddSpacer()
                        spc.Paint = function(sp, w, h)
                            draw.RoundedBox(0, 4, h/2, w-8, 1, Color(255, 255, 255, 10))
                        end
                    end

                    StyleMenu(m)

                    AddStyledOption(m, "Copiar SteamID64", function() SetClipboardText(sid64) chat.AddText("SteamID64 copiado!") end, "icon16/vcard.png")
                    AddStyledSpacer(m)
                    
                    AddStyledOption(m, "Dar XP", function()
                        Derma_StringRequest("Dar XP", "¿Cuánta XP añadir a " .. name .. "?", "", function(text)
                            local amount = tonumber(text)
                            if amount then
                                RunConsoleCommand("sam_addxp", sid64, tostring(amount))
                                timer.Simple(0.5, function() net.Start("IVO_RequestXPData") net.SendToServer() end)
                            end
                        end)
                    end, "icon16/add.png")
                    
                    AddStyledOption(m, "Setear XP", function()
                        Derma_StringRequest("Setear XP", "¿A qué cantidad establecer la XP de " .. name .. "?", "", function(text)
                            local amount = tonumber(text)
                            if amount then
                                RunConsoleCommand("sam_setxp", sid64, tostring(amount))
                                timer.Simple(0.5, function() net.Start("IVO_RequestXPData") net.SendToServer() end)
                            end
                        end)
                    end, "icon16/pencil.png")

                    AddStyledOption(m, "Setear Nivel", function()
                        Derma_StringRequest("Setear Nivel", "¿A qué nivel establecer a " .. name .. "?", "", function(text)
                            local amount = tonumber(text)
                            if amount then
                                RunConsoleCommand("sam_setlevel", sid64, tostring(amount))
                                timer.Simple(0.5, function() net.Start("IVO_RequestXPData") net.SendToServer() end)
                            end
                        end)
                    end, "icon16/star.png")

                    m:Open()
                end
            end
        end
    end

    searchEntry.OnChange = function(s)
        PopulateList(s:GetValue())
    end

    net.Receive("IVO_SendXPData", function()
        cachedData = net.ReadTable()
        if IsValid(pScroll) then
            PopulateList(searchEntry:GetValue())
        end
    end)

    -- Solicitar datos iniciales
    net.Start("IVO_RequestXPData")
    net.SendToServer()
end
