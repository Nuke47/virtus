if not CLIENT then return end

-- Fuentes universales para los minijuegos
surface.CreateFont("GTA_Hack_Title", { font = "Courier New", size = 48, weight = 800, antialias = true })
surface.CreateFont("GTA_Hack_Sub", { font = "Courier New", size = 24, weight = 600, antialias = true })
surface.CreateFont("GTA_Hack_Timer", { font = "Courier New", size = 34, weight = 800, antialias = true })
surface.CreateFont("GTA_Hack_TimerLabel", { font = "Courier New", size = 14, weight = 800, antialias = true })
surface.CreateFont("GTA_Hack_Digital", { font = "Lucida Console", size = 60, weight = 800, antialias = true })

local activeHackPanel = nil

function Datapad_StartMinigame(hackType, targetEnt, customTime, allowedGamesStr)
    if IsValid(activeHackPanel) then activeHackPanel:Remove() end

    activeHackPanel = vgui.Create("DFrame")
    activeHackPanel:SetSize(ScrW(), ScrH())
    activeHackPanel:Center()
    activeHackPanel:MakePopup()
    activeHackPanel:SetTitle("")
    activeHackPanel:ShowCloseButton(false)
    activeHackPanel:SetDraggable(false)
    
    local startTime = CurTime()
    local timeLimit = (customTime and customTime > 0) and customTime or 45 -- Tiempo global dinámico
    
    activeHackPanel.Paint = function(self, w, h)
        -- Fondo negro absoluto
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, w, h)
        
        -- Viñeta sutil en los bordes
        surface.SetDrawColor(0, 5, 10, 100)
        surface.SetMaterial(Material("gui/gradient_up"))
        surface.DrawTexturedRect(0, 0, w, h * 0.2)
        surface.SetMaterial(Material("gui/gradient_down"))
        surface.DrawTexturedRect(0, h * 0.8, w, h * 0.2)

        -- Efecto CRT (Scanlines)
        surface.SetDrawColor(255, 255, 255, 3)
        for i = 0, h, 4 do
            surface.DrawLine(0, i, w, i)
        end
        
        -- Línea divisoria del "Header" (Crea un área de barra de estado arriba)
        surface.SetDrawColor(255, 255, 255, 15)
        surface.DrawLine(0, 90, w, 90)
        surface.SetDrawColor(255, 255, 255, 5)
        surface.DrawLine(0, 92, w, 92)
        
        -- Lógica del Temporizador
        local timeLeft = math.max(0, timeLimit - (CurTime() - startTime))
        local secs = math.floor(timeLeft)
        local millis = math.floor((timeLeft % 1) * 100)
        local timeStr = string.format("%02d.%02d", secs, millis)
        
        -- Colores base de la caja del Timer
        local boxColor = Color(15, 15, 15, 240)
        local outlineColor = Color(100, 100, 100, 255)
        local timeColor = Color(255, 50, 50)
        local labelColor = Color(150, 150, 150)

        -- Efecto de Alarma cuando quedan menos de 10 segundos
        if timeLeft <= 10 then
            if math.sin(CurTime() * 12) > 0 then
                timeColor = Color(255, 255, 255)
                boxColor = Color(150, 20, 20, 240)
                outlineColor = Color(255, 50, 50, 255)
                labelColor = Color(255, 150, 150)
            else
                timeColor = Color(150, 0, 0)
                outlineColor = Color(100, 0, 0, 255)
                labelColor = Color(100, 50, 50)
            end
        end
        
        -- DIBUJAR CAJA DEL TEMPORIZADOR (Centro superior)
        local boxW, boxH = 220, 55
        local boxX, boxY = (w - boxW) / 2, 20
        
        surface.SetDrawColor(boxColor)
        surface.DrawRect(boxX, boxY, boxW, boxH)
        
        surface.SetDrawColor(outlineColor)
        surface.DrawOutlinedRect(boxX, boxY, boxW, boxH, 2)
        
        -- Detalles de la caja (esquinitas técnicas para que no sea un simple cuadrado)
        surface.DrawRect(boxX - 2, boxY + 10, 2, boxH - 20)
        surface.DrawRect(boxX + boxW, boxY + 10, 2, boxH - 20)
        
        -- Textos del Timer
        draw.SimpleText("TIME REMAINING", "GTA_Hack_TimerLabel", w / 2, boxY + 10, labelColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(timeStr, "GTA_Hack_Timer", w / 2, boxY + 34, timeColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        if timeLeft <= 0 then
            Datapad_EndMinigame(false, hackType, targetEnt)
        end
    end

    -- Contenedor donde vivirán los minijuegos
    local gameContainer = vgui.Create("DPanel", activeHackPanel)
    gameContainer:SetSize(1000, 700)
    gameContainer:SetPos((ScrW() - 1000) / 2, (ScrH() - 700) / 2 + 30)
    gameContainer.Paint = function() end

    -- Botón de salida de emergencia (Estilo GTA V Arriba Izquierda)
    local exitBtn = vgui.Create("DButton", activeHackPanel)
    exitBtn:SetSize(140, 40)
    exitBtn:SetPos(40, 28)
    exitBtn:SetText("ESC - ABORT")
    exitBtn:SetFont("GTA_Hack_Sub")
    exitBtn:SetTextColor(Color(255, 255, 255, 200))
    exitBtn.Paint = function(self, w, h)
        -- Animación al pasar el mouse por encima
        if self:IsHovered() then 
            surface.SetDrawColor(255, 50, 50, 50)
            surface.DrawRect(0, 0, w, h) 
            surface.SetDrawColor(255, 50, 50, 255)
        else
            surface.SetDrawColor(255, 255, 255, 100)
        end
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end
    exitBtn.DoClick = function() Datapad_EndMinigame(false, hackType, targetEnt) end

    -- Selección aleatoria del minijuego
    local gamesAllowed = string.Explode(",", allowedGamesStr or "1,2,3")
    if #gamesAllowed == 0 then gamesAllowed = {"1", "2", "3"} end
    
    local randIdx = math.random(1, #gamesAllowed)
    local gameID = tonumber(gamesAllowed[randIdx]) or 1

    if gameID == 1 and Datapad_LoadBruteforce then
        Datapad_LoadBruteforce(gameContainer, Color(0, 255, 0), function(success) Datapad_EndMinigame(success, hackType, targetEnt) end)
    elseif gameID == 2 and Datapad_LoadCircuit then
        Datapad_LoadCircuit(gameContainer, Color(0, 255, 0), function(success) Datapad_EndMinigame(success, hackType, targetEnt) end)
    elseif Datapad_LoadVoltage then
        Datapad_LoadVoltage(gameContainer, Color(0, 255, 0), function(success) Datapad_EndMinigame(success, hackType, targetEnt) end)
    else
        Datapad_EndMinigame(true, hackType, targetEnt)
    end
end

function Datapad_EndMinigame(success, hackType, targetEnt)
    if IsValid(activeHackPanel) then activeHackPanel:Remove() end
    if success then
        surface.PlaySound("buttons/button14.wav")
        net.Start("Datapad_HackSuccess")
        net.WriteString(hackType)
        if targetEnt then net.WriteEntity(targetEnt) end
        net.SendToServer()
    else
        surface.PlaySound("buttons/button10.wav")
        net.Start("Datapad_HackFailed")
        net.WriteString(hackType)
        if targetEnt then net.WriteEntity(targetEnt) end
        net.SendToServer()
    end
end

net.Receive("Datapad_StartHack", function()
    local ent = net.ReadEntity()
    local diff = 45
    -- Verificamos si hay más datos en el buffer (por retrocompatibilidad con keypads)
    local readDiff = net.ReadUInt(16)
    if readDiff and readDiff > 0 then diff = readDiff end
    
    local allowedGamesStr = "1,2,3"
    -- Intentar leer el string de juegos si existe
    -- Si estamos en Garry's mod antiguo, podría fallar si no viene, pero usaremos pcall o chequearemos si queda buffer
    -- Un simple ReadString() retornará "" si el buffer está vacío.
    local readGames = net.ReadString()
    if readGames and readGames ~= "" then allowedGamesStr = readGames end
    
    Datapad_StartMinigame("keypad", ent, diff, allowedGamesStr)
end)