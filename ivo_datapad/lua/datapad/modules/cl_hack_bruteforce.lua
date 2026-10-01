if not CLIENT then return end

-- Fuentes estilo Terminal Scomp de Star Wars
surface.CreateFont("SW_Hack_Title", { font = "Trebuchet MS", size = 42, weight = 800, antialias = true })
surface.CreateFont("SW_Hack_Sub", { font = "Trebuchet MS", size = 18, weight = 600, antialias = true })
surface.CreateFont("SW_Hack_Letter", { font = "Lucida Console", size = 36, weight = 800, antialias = true })
surface.CreateFont("SW_Hack_Alert", { font = "Lucida Console", size = 24, weight = 800, antialias = true })

function Datapad_LoadBruteforce(parentPanel, themeColor, onComplete)
    local gamePnl = vgui.Create("DPanel", parentPanel)
    gamePnl:Dock(FILL)
    gamePnl:RequestFocus()
    gamePnl:SetKeyboardInputEnabled(true)
    
    -- Si no se pasa un color, usamos un Azul "Holograma" de Star Wars por defecto
    local mainColor = themeColor or Color(0, 180, 255)
    
    -- Diccionario de palabras variadas para StarwarsRP (De 3 a 8 letras)
    local words = {
        "SYS", "LOG", "KEY", "NET",
        "DATA", "CODE", "PORT", "NODE", "SITH", "JEDI", "DOOR",
        "SCOMP", "PANEL", "PROBE", "POWER", "CRED", "DROID",
        "ACCESS", "SYSTEM", "BYPASS", "SHIELD", "SECTOR",
        "NETWORK", "SLICING", "CONTROL", "CONSOLE",
        "OVERRIDE", "SECURITY", "DATACRON"
    }
    
    local targetWord = words[math.random(1, #words)]
    local cols = #targetWord
    
    local columns = {}
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" -- Letras y números para más estilo sci-fi
    
    -- Función para inicializar/reiniciar las columnas
    local function SetupColumns()
        columns = {}
        for i = 1, cols do
            local letters = {}
            for j = 1, 20 do table.insert(letters, alphabet[math.random(1, #alphabet)]) end
            
            -- Asegurar que la letra correcta exista en esta cinta
            letters[math.random(1, 20)] = targetWord[i]
            
            columns[i] = {
                letters = letters,
                yOffset = math.random(0, 100), -- Desfase inicial aleatorio
                speed = math.random(250, 450), -- Velocidad de caída
                locked = false,
                lockedChar = ""
            }
        end
    end
    
    SetupColumns()
    
    local currentCol = 1
    local state = "PLAYING"
    local letterHeight = 40
    local strikes = 0
    local maxStrikes = 3

    gamePnl.Paint = function(self, w, h)
        -- Fondo del panel
        surface.SetDrawColor(5, 10, 15, 250)
        surface.DrawRect(0, 0, w, h)
        
        -- Textos estáticos (Header)
        draw.SimpleText("SCOMP LINK - SLICING PROTOCOL", "SW_Hack_Title", w/2, 40, mainColor, TEXT_ALIGN_CENTER)
        draw.SimpleText("DECRYPTING DATA STREAM...", "SW_Hack_Sub", w/2, 80, Color(150, 150, 150), TEXT_ALIGN_CENTER)
        
        -- Intentos restantes
        local strikeColor = strikes > 1 and Color(255, 50, 50) or mainColor
        draw.SimpleText("ATTEMPTS REMAINING: " .. (maxStrikes - strikes), "SW_Hack_Alert", w/2, 110, strikeColor, TEXT_ALIGN_CENTER)
        
        if state ~= "PLAYING" then
            local msg = state == "WON" and "SYSTEM OVERRIDE SUCCESSFUL" or "SECURITY LOCKOUT - ACCESS DENIED"
            local col = state == "WON" and Color(50, 255, 50) or Color(255, 50, 50)
            surface.SetDrawColor(0, 0, 0, 200)
            surface.DrawRect(0, h/2 - 40, w, 80)
            draw.SimpleText(msg, "SW_Hack_Title", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end

        local centerY = h / 2 + 30
        local colWidth = 55
        local totalWidth = cols * colWidth
        local startX = (w - totalWidth) / 2
        
        -- Franja Central (Zona de captura de datos)
        surface.SetDrawColor(mainColor.r, mainColor.g, mainColor.b, 40)
        surface.DrawRect(0, centerY - letterHeight/2, w, letterHeight)
        
        surface.SetDrawColor(mainColor.r, mainColor.g, mainColor.b, 200)
        surface.DrawLine(0, centerY - letterHeight/2, w, centerY - letterHeight/2)
        surface.DrawLine(0, centerY + letterHeight/2, w, centerY + letterHeight/2)
        
        -- Mira lateral tecnológica
        draw.SimpleText(">", "SW_Hack_Letter", startX - 30, centerY, mainColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("<", "SW_Hack_Letter", startX + totalWidth + 30, centerY, mainColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Resaltado brillante para la columna actual
        if columns[currentCol] and not columns[currentCol].locked then
            surface.SetDrawColor(mainColor.r, mainColor.g, mainColor.b, 25)
            surface.DrawRect(startX + (currentCol - 1) * colWidth, centerY - letterHeight * 4, colWidth, letterHeight * 8)
            -- Bordes de la columna activa
            surface.SetDrawColor(mainColor.r, mainColor.g, mainColor.b, 150)
            surface.DrawOutlinedRect(startX + (currentCol - 1) * colWidth, centerY - letterHeight * 4, colWidth, letterHeight * 8)
        end

        -- Lógica de dibujado y movimiento de letras
        for i = 1, cols do
            local col = columns[i]
            local cx = startX + (i - 1) * colWidth + colWidth/2
            
            if col.locked then
                local color = col.lockedChar == targetWord[i] and Color(50, 255, 50) or Color(255, 50, 50)
                draw.SimpleText(col.lockedChar, "SW_Hack_Letter", cx, centerY, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                -- Mover offset
                col.yOffset = col.yOffset + (col.speed * FrameTime())
                local maxOffset = #col.letters * letterHeight
                if col.yOffset > maxOffset then col.yOffset = col.yOffset - maxOffset end
                
                -- Dibujar letras en loop
                for j = 1, #col.letters do
                    local charY = (centerY - letterHeight * 2) + (j * letterHeight) + col.yOffset
                    
                    -- Teletransportar letras para hacer el loop infinito
                    while charY > centerY + letterHeight * 4.5 do charY = charY - maxOffset end
                    while charY < centerY - letterHeight * 4.5 do charY = charY + maxOffset end
                    
                    -- Rendering de Clipping manual
                    if charY > centerY - letterHeight * 4 and charY < centerY + letterHeight * 4 then
                        local color = Color(150, 150, 150)
                        
                        -- La letra correcta que buscamos se resalta levemente en color rojo/naranja (Ayuda visual)
                        if col.letters[j] == targetWord[i] then
                            color = Color(255, 100, 50) 
                        end
                        
                        -- Efecto de fundido hacia los bordes
                        local distToCenter = math.abs(charY - centerY)
                        local alpha = math.Clamp(255 - (distToCenter * 1.5), 0, 255)
                        color.a = alpha
                        
                        draw.SimpleText(col.letters[j], "SW_Hack_Letter", cx, charY, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end
            end
        end
        
        -- Instrucciones abajo
        local blink = math.sin(CurTime() * 8) > 0 and Color(255, 255, 255) or Color(150, 150, 150)
        draw.SimpleText("PRESIONA [ESPACIO] PARA CAPTURAR DATO", "SW_Hack_Sub", w/2, h - 50, blink, TEXT_ALIGN_CENTER)
    end

    gamePnl.OnKeyCodePressed = function(self, key)
        if state ~= "PLAYING" then return end
        
        if key == KEY_SPACE or key == KEY_ENTER then
            local col = columns[currentCol]
            local centerY = self:GetTall() / 2 + 30
            local maxOffset = #col.letters * letterHeight
            
            -- Encontrar exactamente la letra que está más cerca del centro visual
            local closestIdx = 1
            local minDistance = 9999
            
            for j = 1, #col.letters do
                local charY = (centerY - letterHeight * 2) + (j * letterHeight) + col.yOffset
                while charY > centerY + letterHeight * 4 do charY = charY - maxOffset end
                while charY < centerY - letterHeight * 4 do charY = charY + maxOffset end
                
                local dist = math.abs(charY - centerY)
                if dist < minDistance then
                    minDistance = dist
                    closestIdx = j
                end
            end
            
            col.lockedChar = col.letters[closestIdx]
            col.locked = true
            
            if col.lockedChar == targetWord[currentCol] then
                -- Acertó la letra
                surface.PlaySound("buttons/blip1.wav")
                currentCol = currentCol + 1
                
                if currentCol > cols then
                    state = "WON"
                    timer.Simple(1.2, function() if onComplete then onComplete(true) end end)
                end
            else
                -- Falló la letra (STRIKE)
                strikes = strikes + 1
                surface.PlaySound("buttons/button10.wav")
                
                if strikes >= maxStrikes then
                    state = "LOST"
                    timer.Simple(1.5, function() if onComplete then onComplete(false) end end)
                else
                    -- Penalización: Reiniciar la palabra pero sigue jugando
                    currentCol = 1
                    SetupColumns() -- Vuelve a barajar la velocidad de las columnas
                end
            end
        end
    end
end