surface.CreateFont("Virtus_Scoreboard_Aurebesh_ExtraSmall", { font = "VirtusBe", size = 9, weight = 500, antialias = true })
surface.CreateFont("Virtus_Scoreboard_Aurebesh_Title", { font = "VirtusBe", size = 16, weight = 500, antialias = true })
surface.CreateFont("Virtus_Scoreboard_BigTitle", { font = "SansSerifFLF", size = 32, weight = 500, antialias = true })
surface.CreateFont("Virtus_Scoreboard_Medium", { font = "SansSerifFLF", size = 20, weight = 500, antialias = true })
surface.CreateFont("Virtus_Scoreboard_Small", { font = "SansSerifFLF", size = 14, weight = 500, antialias = true })
surface.CreateFont("Virtus_Scoreboard_Header", { font = "SansSerifFLF", size = 28, weight = 500, antialias = true })

local function SafeUpper(str) 
    if not str then return "" end 
    local s = string.gsub(str, "[a-z]", function(c) return string.char(string.byte(c) - 32) end)
    s = string.Replace(s, "á", "Á")
    s = string.Replace(s, "é", "É")
    s = string.Replace(s, "í", "Í")
    s = string.Replace(s, "ó", "Ó")
    s = string.Replace(s, "ú", "Ú")
    s = string.Replace(s, "ñ", "Ñ")
    return s
end

local RanksConfig = {
    ["superadmin"]  = { name = "Ejecutivo Virtus", color = Color(255, 50, 50) },
    ["personajes1"] = { name = "VIP Personajes", color = Color(255, 215, 0) },
    ["personajes2"] = { name = "VIP Personajes", color = Color(255, 215, 0) },
    ["personajes3"] = { name = "VIP Personajes", color = Color(255, 215, 0) },
    ["cloncomando"] = { name = "VIP Clon Comando", color = Color(255, 165, 0) },
    ["director"]    = { name = "Director", color = Color(150, 0, 255) },
    ["gamemaster"]  = { name = "Game Master", color = Color(0, 200, 255) },
    ["moderador"]   = { name = "Moderador", color = Color(0, 200, 100) },
}

local ScoreboardBase = nil

local function SkinModernScrollbar(scrollPanel)
    local sbar = scrollPanel:GetVBar()
    sbar:SetWide(0)
end

local function CloseVirtusScoreboard()
    if IsValid(ScoreboardBase) then
        ScoreboardBase:Remove()
        ScoreboardBase = nil
    end
end

local function CreateScoreboard()
    if IsValid(ScoreboardBase) then ScoreboardBase:Remove() end

    ScoreboardBase = vgui.Create("DFrame")
    ScoreboardBase:SetSize(ScrW(), ScrH())
    ScoreboardBase:MakePopup()
    ScoreboardBase:SetTitle("")
    ScoreboardBase:SetDraggable(false)
    ScoreboardBase:ShowCloseButton(false)
    ScoreboardBase:Center()
    ScoreboardBase:SetKeyboardInputEnabled(false)

    ScoreboardBase.Think = function(self)
        local bindName = input.LookupBinding("+showscores")
        local key = bindName and input.GetKeyCode(bindName) or KEY_TAB
        if key ~= 0 and not input.IsKeyDown(key) and not input.IsMouseDown(key) then
            CloseVirtusScoreboard()
        end
    end

    ScoreboardBase.Paint = function(self, w, h)
        -- Fondo oscuro
        draw.RoundedBox(0, 0, 0, w, h, Color(12, 14, 18, 245))
    end

    -- Coordenadas absolutas X para alineación perfecta
    local abs_x = {
        name   = ScrW() * 0.12,
        job    = ScrW() * 0.38,
        rank   = ScrW() * 0.60,
        kills  = ScrW() * 0.74,
        deaths = ScrW() * 0.83,
        ping   = ScrW() * 0.92
    }

    local mainArea = vgui.Create("DPanel", ScoreboardBase)
    mainArea:Dock(FILL)
    mainArea:DockMargin(40, 60, 40, 60)
    mainArea.Paint = function(self, w, h)
        local title = "VIRTUS STUDIOS"
        draw.SimpleText(title, "Virtus_Scoreboard_BigTitle", 20, 0, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(title, "Virtus_Scoreboard_Aurebesh_Title", 20, 32, Color(150, 150, 150, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        surface.SetDrawColor(255, 180, 0, 180)
        surface.DrawRect(20, 55, w - 40, 2)

        local staff_count = 0
        local plyList = player.GetAll()
        for _, ply in ipairs(plyList) do
            local group = ply:GetUserGroup()
            if group == "gamemaster" or group == "moderador" or group == "director" or group == "superadmin" then
                staff_count = staff_count + 1
            end
        end

        local txt2 = "JUGADORES EN LÍNEA: " .. #plyList
        local txt1 = "STAFF ACTIVO: " .. staff_count
        
        draw.SimpleText(txt2, "Virtus_Scoreboard_Medium", w - 20, 5, Color(200, 200, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        draw.SimpleText(txt1, "Virtus_Scoreboard_Medium", w - 20, 28, Color(255, 180, 0), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

        -- List Headers
        local headerY = 85
        local mx = 40 -- Margen izquierdo absoluto de mainArea

        local hdrColor = Color(180, 190, 200)

        -- ID/Jugador alineado a la izquierda junto con el avatar
        draw.SimpleText("ID / JUGADOR", "Virtus_Scoreboard_Medium", abs_x.name - mx, headerY, hdrColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("ID / JUGADOR", "Virtus_Scoreboard_Aurebesh_ExtraSmall", abs_x.name - mx, headerY + 14, Color(150, 150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        -- Resto centrado
        draw.SimpleText("FACCIONES / ROLES", "Virtus_Scoreboard_Medium", abs_x.job - mx, headerY, hdrColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("RANGO", "Virtus_Scoreboard_Medium", abs_x.rank - mx, headerY, hdrColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        draw.SimpleText("KILLS", "Virtus_Scoreboard_Medium", abs_x.kills - mx, headerY, hdrColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("DEATHS", "Virtus_Scoreboard_Medium", abs_x.deaths - mx, headerY, hdrColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("PING", "Virtus_Scoreboard_Medium", abs_x.ping - mx, headerY, hdrColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local scroll = vgui.Create("DScrollPanel", mainArea)
    scroll:Dock(FILL)
    -- Ajustado el margen superior para dar más espacio entre headers y la lista
    scroll:DockMargin(10, 130, 10, 0)
    SkinModernScrollbar(scroll)

    local sortedPlayers = player.GetAll()
    table.sort(sortedPlayers, function(a, b)
        if not IsValid(a) or not IsValid(b) then return false end
        return a:Team() < b:Team()
    end)

    for _, ply in ipairs(sortedPlayers) do
        if not IsValid(ply) then continue end

        local pnl = scroll:Add("DButton")
        pnl:SetText("")
        pnl:Dock(TOP)
        pnl:SetHeight(56) -- Filas un poco más altas para que respire
        pnl:DockMargin(0, 0, 10, 8)
        pnl:SetTooltip("Clic Izquierdo: Copiar SteamID\nClic Derecho: Abrir Menu de Opciones")

        local pID = ply:SteamID()
        local pGroup = ply:GetUserGroup()
        local rankData = RanksConfig[pID] or RanksConfig[pGroup] or { name = SafeUpper(pGroup), color = Color(150, 150, 150) }

        pnl.HoverP = 0
        pnl.Paint = function(self, w, h)
            if not IsValid(ply) then return end
            
            self.HoverP = Lerp(FrameTime() * 15, self.HoverP or 0, self:IsHovered() and 1 or 0)
            if self:IsHovered() and not self._playHover then 
                self._playHover = true
                LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) 
            elseif not self:IsHovered() then 
                self._playHover = false 
            end
            
            -- Fondo base de la fila un poco más claro para distinguir
            draw.RoundedBox(6, 0, 0, w, h, Color(22, 26, 32, 180))
            
            -- Línea de acento a la izquierda del color del rango
            surface.SetDrawColor(rankData.color.r, rankData.color.g, rankData.color.b, 255)
            surface.DrawRect(0, 0, 4, h)

            if self.HoverP > 0.01 then
                draw.RoundedBox(6, 0, 0, w, h, Color(255, 255, 255, self.HoverP * 255))
            end

            local tc = Lerp(self.HoverP, 255, 0)
            local txtColor = Color(tc, tc, tc)
            
            -- px = margen absoluto de mainArea(40) + margen del scroll(10) = 50
            local px = 50 
            
            local nick = SafeUpper(ply:Nick())
            -- Alineado a la izquierda junto con el header
            draw.SimpleText(nick, "Virtus_Scoreboard_Medium", abs_x.name - px, h/2 - 7, txtColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(nick, "Virtus_Scoreboard_Aurebesh_ExtraSmall", abs_x.name - px, h/2 + 8, Color(tc, tc, tc, 100 + self.HoverP * 155), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            local jobName = SafeUpper(ply.getDarkRPVar and ply:getDarkRPVar("job") or team.GetName(ply:Team()))
            local jobColor = team.GetColor(ply:Team())
            if self.HoverP > 0.5 then jobColor = color_black end
            draw.SimpleText(jobName, "Virtus_Scoreboard_Small", abs_x.job - px, h/2, jobColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            local rankName = SafeUpper(rankData.name)
            local rColor = rankData.color
            if self.HoverP > 0.5 then rColor = color_black end
            draw.SimpleText(rankName, "Virtus_Scoreboard_Medium", abs_x.rank - px, h/2, rColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            local ping = ply:Ping()
            draw.SimpleText(ply:Frags(), "Virtus_Scoreboard_Medium", abs_x.kills - px, h/2, txtColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(ply:Deaths(), "Virtus_Scoreboard_Medium", abs_x.deaths - px, h/2, txtColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            local pingCol = Color(0, 255, 100)
            if ping >= 100 then pingCol = Color(255, 180, 0) end
            if ping >= 200 then pingCol = Color(255, 50, 50) end
            if self.HoverP > 0.5 then pingCol = color_black end
            
            draw.SimpleText(ping .. " ms", "Virtus_Scoreboard_Medium", abs_x.ping - px, h/2, pingCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local av = vgui.Create("AvatarImage", pnl)
        av:SetSize(36, 36)
        -- Avatar se sitúa a 45 pixeles a la izquierda del inicio del nombre
        av:SetPos(abs_x.name - 50 - 45, (56/2) - 18)
        av:SetPlayer(ply, 64)

        pnl.DoClick = function()
            if IsValid(ply) then
                LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                SetClipboardText(ply:SteamID())
                notification.AddLegacy("SteamID Copiado: " .. ply:Nick(), NOTIFY_GENERIC, 2)
            end
        end

        pnl.DoRightClick = function()
            if IsValid(ply) then
                local menu = DermaMenu()
                
                menu.Paint = function(self, mw, mh)
                    draw.RoundedBox(4, 0, 0, mw, mh, Color(20, 24, 30, 240))
                end

                local function StyleMenuOption(opt)
                    opt:SetTextColor(Color(240, 240, 240))
                    opt:SetFont("Virtus_Scoreboard_Small")
                    opt.Paint = function(self, mw, mh)
                        if self:IsHovered() then
                            draw.RoundedBox(0, 0, 0, mw, mh, Color(255, 255, 255, 15))
                        end
                    end
                end

                local copyName = menu:AddOption("Copiar Nombre", function() SetClipboardText(ply:Nick()) end)
                StyleMenuOption(copyName)
                local copySteam = menu:AddOption("Copiar SteamID", function() SetClipboardText(ply:SteamID()) end)
                StyleMenuOption(copySteam)
                
                if LocalPlayer():IsAdmin() then
                    menu:AddSpacer()
                    local gotoBtn = menu:AddOption("Ir a Jugador", function() RunConsoleCommand("sam", "goto", ply:Nick()) end)
                    StyleMenuOption(gotoBtn)
                    local bringBtn = menu:AddOption("Traer Jugador", function() RunConsoleCommand("sam", "bring", ply:Nick()) end)
                    StyleMenuOption(bringBtn)
                    local kickBtn = menu:AddOption("Expulsar", function() RunConsoleCommand("sam", "kick", ply:Nick(), "Expulsado por admin.") end)
                    StyleMenuOption(kickBtn)
                end
                
                menu:Open()
            end
        end
    end
end

hook.Add("ScoreboardShow", "Virtus_Scoreboard_Open", function()
    CreateScoreboard()
    return true
end)

hook.Add("ScoreboardHide", "Virtus_Scoreboard_Close", function()
    CloseVirtusScoreboard()
end)

hook.Add("HUDShouldDraw", "Virtus_Scoreboard_HideHUD", function(name)
    if IsValid(ScoreboardBase) then
        return false
    end
end)

hook.Add("InitPostEntity", "Virtus_RemoveDefaultScoreboards", function()
    hook.Remove("ScoreboardShow", "FAdmin_scoreboard")
    hook.Remove("ScoreboardHide", "FAdmin_scoreboard")
    
    timer.Simple(1, function()
        hook.Remove("ScoreboardShow", "FAdmin_scoreboard")
        hook.Remove("ScoreboardHide", "FAdmin_scoreboard")
    end)
end)

timer.Simple(2, function()
    if GAMEMODE then
        GAMEMODE.ScoreboardShow = function()
            CreateScoreboard()
            return true
        end
        GAMEMODE.ScoreboardHide = function()
            CloseVirtusScoreboard()
        end
    end
end)
