-- ============================================================================
-- IVOSAM: TAB JUGADORES — PREMIUM UI
-- ============================================================================

function IVOSAM_BuildPlayersTab(tabPanel, frameRef, getActiveTab)
    tabPanel.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0)) -- Transparente para usar el fondo global
    end

    local searchBG = vgui.Create("DPanel", tabPanel)
    searchBG:Dock(TOP)
    searchBG:SetHeight(50)
    searchBG:DockMargin(15, 15, 15, 10)
    searchBG.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, IVO_SAM.Theme.BgTop)
    end

    local searchEntry = vgui.Create("DTextEntry", searchBG)
    searchEntry:Dock(FILL)
    searchEntry:DockMargin(45, 10, 10, 10)
    searchEntry:SetPlaceholderText("Buscar jugador por nombre o SteamID...")
    searchEntry:SetUpdateOnType(true)
    IVO_SAM.StyleModernEntry(searchEntry)

    local pScroll = vgui.Create("DScrollPanel", tabPanel)
    pScroll:Dock(FILL)
    pScroll:DockMargin(15, 0, 15, 15)

    local sbar = pScroll:GetVBar()
    sbar:SetWide(6)
    function sbar:Paint(w, h) end
    function sbar.btnUp:Paint() end
    function sbar.btnDown:Paint() end
    function sbar.btnGrip:Paint(w, h) draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 15)) end

    function RefreshPlayerList(filter)
        if not IsValid(pScroll) then return end
        pScroll:Clear()
        filter = (filter or ""):lower()

        local historialData = IVO_SAM.ServerHistoryData or {}
        
        for _, data in ipairs(historialData) do
            local name = data.name or "Desconocido"
            local sid64 = data.steamid64 or ""
            local sid = data.steamid or util.SteamIDFrom64(sid64) or "STEAM_0:UNKNOWN"
            local rawTime = tonumber(data.total_time) or 0

            local plyObj = player.GetBySteamID64(sid64)
            local isOnline = IsValid(plyObj)
            local isBot = isOnline and plyObj:IsBot()
            
            -- Obtener ambos rangos
            local rank = "USER"
            local secRank = ""
            
            if isOnline and isfunction(plyObj.GetRank) then
                rank = plyObj:GetRank()
                secRank = plyObj:GetNWString("SecondaryRank", "")
            elseif IVO_SAM.ClientRankCache and IVO_SAM.ClientRankCache[sid64] then
                rank = IVO_SAM.ClientRankCache[sid64].rank or "USER"
                secRank = IVO_SAM.ClientRankCache[sid64].sec_rank or ""
            end
            
            rank = rank:upper()
            secRank = secRank:upper()
            if secRank == "USER" then secRank = "" end

            local tiempoStr = IVO_SAM.FormatearTiempoMenu(rawTime)

            if filter ~= "" and not (name:lower():find(filter) or sid:lower():find(filter) or sid64:find(filter)) then
                continue
            end

            local estadoTexto = isOnline and (isBot and "Bot" or "Online") or "Offline"
            local colorIndicador = isOnline and (isBot and Color(100, 150, 255) or Color(0, 255, 150)) or Color(100, 100, 100)

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

                -- Indicador online status (borde izq)
                draw.RoundedBoxEx(8, 0, 0, 4, h, colorIndicador, true, false, true, false)
                
                -- Textos
                draw.SimpleText(name, "IVOSAM_Tab", 65, 15, IVO_SAM.Theme.TextMain)
                draw.SimpleText(estadoTexto .. "  •  " .. (isBot and "ENTIDAD RED" or sid), "IVOSAM_Normal", 65, 38, IVO_SAM.Theme.TextMuted)
                
                draw.SimpleText(tiempoStr, "IVOSAM_Bold", w - 25, h / 2, isOnline and IVO_SAM.Theme.Accent or IVO_SAM.Theme.TextMuted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

                -- Badges de Rango
                surface.SetFont("IVOSAM_Tab")
                local rx = 65 + surface.GetTextSize(name) + 15
                
                -- Badge Primario
                surface.SetFont("IVOSAM_Normal")
                local pW = surface.GetTextSize(rank) + 16
                draw.RoundedBox(6, rx, 14, pW, 20, Color(0, 140, 255, 30))
                draw.SimpleText(rank, "IVOSAM_Normal", rx + pW/2, 24, Color(0, 160, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                
                rx = rx + pW + 8
                
                -- Badge Secundario
                if secRank ~= "" then
                    local sW = surface.GetTextSize(secRank) + 16
                    draw.RoundedBox(6, rx, 14, sW, 20, Color(255, 160, 0, 30))
                    draw.SimpleText(secRank, "IVOSAM_Normal", rx + sW/2, 24, Color(255, 180, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
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
            if isBot then av:SetSteamID("STEAM_0:0:0", 64) else av:SetSteamID(sid64, 64) end

            card.OnMousePressed = function(s, mouse)
                if mouse == MOUSE_RIGHT then
                    local m = DermaMenu()
                    
                    local function StyleMenu(menu)
                        menu.Paint = function(s, w, h)
                            draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 30, 250))
                            surface.SetDrawColor(IVO_SAM.Theme.AccentGlow)
                            surface.DrawOutlinedRect(0, 0, w, h, 1)
                        end
                    end
                    
                    local function AddStyledOption(menu, text, func, icon)
                        local opt = menu:AddOption(text, func)
                        if icon then opt:SetIcon(icon) end
                        opt:SetTextColor(IVO_SAM.Theme.TextMain)
                        opt.Paint = function(s, w, h)
                            if s:IsHovered() then 
                                draw.RoundedBox(4, 2, 2, w-4, h-4, IVO_SAM.Theme.AccentGlow) 
                            end
                        end
                        return opt
                    end
                    
                    local function AddStyledSpacer(menu)
                        local spc = menu:AddSpacer()
                        spc.Paint = function(s, w, h)
                            draw.RoundedBox(0, 4, h/2, w-8, 1, Color(255, 255, 255, 10))
                        end
                    end
                    
                    local function AddStyledSubMenu(menu, text, icon)
                        local subMenu, subOpt = menu:AddSubMenu(text)
                        if icon then subOpt:SetIcon(icon) end
                        subOpt:SetTextColor(IVO_SAM.Theme.TextMain)
                        subOpt.Paint = function(s, w, h)
                            if s:IsHovered() then 
                                draw.RoundedBox(4, 2, 2, w-4, h-4, IVO_SAM.Theme.AccentGlow) 
                            end
                        end
                        StyleMenu(subMenu)
                        return subMenu, subOpt
                    end

                    StyleMenu(m)
                    
                    if isOnline and not isBot then
                        AddStyledOption(m, "Traer (Bring)", function() RunConsoleCommand("say", "!bring " .. name) end, "icon16/arrow_in.png")
                        AddStyledOption(m, "Ir a él (Goto)", function() RunConsoleCommand("say", "!goto " .. name) end, "icon16/arrow_out.png")
                        AddStyledOption(m, "Slay", function() RunConsoleCommand("say", "!slay " .. name) end, "icon16/lightning.png")
                        AddStyledOption(m, "Encarcelar (Jail)", function() RunConsoleCommand("say", "!jail " .. name) end, "icon16/lock.png")
                        AddStyledSpacer(m)
                    end
                    
                    -- SUB-MENU: Setear Rangos (Online y Offline)
                    if LocalPlayer():IsSuperAdmin() then
                        local subRanks = AddStyledSubMenu(m, "Setear Rango Principal", "icon16/star.png")
                        local subSecRanks = AddStyledSubMenu(m, "Setear Rango Secundario", "icon16/award_star_gold_2.png")
                        
                        local availableRanks = IVO_SAM.Ranks or {}
                        
                        AddStyledOption(subRanks, "Quitar (Usuario Normal)", function() RunConsoleCommand("say", "!setrankid " .. sid64 .. " user") end, "icon16/user.png")
                        AddStyledOption(subSecRanks, "Quitar Rango Secundario", function() RunConsoleCommand("say", "!setsecrankid " .. sid64 .. " user") end, "icon16/user.png")
                        
                        AddStyledSpacer(subRanks)
                        AddStyledSpacer(subSecRanks)

                        for rName, _ in pairs(availableRanks) do
                            if rName ~= "superadmin" and rName ~= "user" then
                                AddStyledOption(subRanks, rName:upper(), function() RunConsoleCommand("say", "!setrankid " .. sid64 .. " " .. rName) end)
                                AddStyledOption(subSecRanks, rName:upper(), function() RunConsoleCommand("say", "!setsecrankid " .. sid64 .. " " .. rName) end)
                            end
                        end
                        AddStyledSpacer(m)
                    end
                    
                    AddStyledOption(m, "Copiar Nombre", function() SetClipboardText(name) end, "icon16/user.png")
                    
                    if not isBot then
                        AddStyledOption(m, "Copiar SteamID", function() SetClipboardText(sid) end, "icon16/tag_blue.png")
                        AddStyledOption(m, "Copiar SteamID64", function() SetClipboardText(sid64) end, "icon16/vcard.png")
                        AddStyledSpacer(m)
                        AddStyledOption(m, "Banear por ID (!banid)", function()
                            Derma_StringRequest("Sanción Avanzada a: " .. name, "Especifica duración y motivo (Ej: 3d Insultar / 0 Toxicidad):", "1d Comportamiento inadecuado",
                                function(inputTexto)
                                    if inputTexto and inputTexto ~= "" then RunConsoleCommand("say", "!banid " .. sid64 .. " " .. inputTexto) end
                                end
                            )
                        end, "icon16/exclamation.png")
                    end
                    
                    m:Open()
                end
            end
        end
    end

    searchEntry.OnValueChange = function(s, val) RefreshPlayerList(val) end

    timer.Create("IVOSAM_Menu_LiveRefresh", 5, 0, function()
        if IsValid(frameRef) and getActiveTab() == "Jugadores" then
            net.Start("IVO_RequestHistoryData")
            net.SendToServer()
        else
            timer.Remove("IVOSAM_Menu_LiveRefresh")
        end
    end)

    if IVO_SAM.ServerHistoryData and #IVO_SAM.ServerHistoryData > 0 then
        RefreshPlayerList(searchEntry:GetValue())
    end
end
