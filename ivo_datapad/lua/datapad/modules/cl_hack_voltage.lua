if not CLIENT then return end

-- Fuentes digitales y limpias
surface.CreateFont("Volt_Digital_Huge", { font = "Courier New", size = 65, weight = 800, antialias = true })
surface.CreateFont("Volt_Digital_Large", { font = "Courier New", size = 45, weight = 800, antialias = true })
surface.CreateFont("Volt_Text", { font = "Arial", size = 16, weight = 600, antialias = true })
surface.CreateFont("Volt_Icon", { font = "Consolas", size = 35, weight = 600, antialias = true })

-- Función auxiliar para dibujar líneas gruesas perfectas (Usado para los círculos)
local function DrawThickLine(x1, y1, x2, y2, thickness)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then return end
    local nx, ny = dx / len, dy / len
    local tx, ty = -ny * thickness * 0.5, nx * thickness * 0.5
    
    draw.NoTexture()
    surface.DrawPoly({
        { x = x1 + tx, y = y1 + ty },
        { x = x1 - tx, y = y1 - ty },
        { x = x2 - tx, y = y2 - ty },
        { x = x2 + tx, y = y2 + ty }
    })
end

-- Función auxiliar para dibujar círculos (Nodos derechos)
local function DrawCircle(cx, cy, radius, thickness, color)
    surface.SetDrawColor(color)
    local segments = 32
    for i = 0, segments - 1 do
        local a1 = (i / segments) * math.pi * 2
        local a2 = ((i + 1) / segments) * math.pi * 2
        DrawThickLine(
            cx + math.cos(a1) * radius, cy + math.sin(a1) * radius,
            cx + math.cos(a2) * radius, cy + math.sin(a2) * radius,
            thickness
        )
    end
end

function Datapad_LoadVoltage(parentPanel, themeColor, onComplete)
    local gamePnl = vgui.Create("DPanel", parentPanel)
    gamePnl:Dock(FILL)
    
    -- Lienzo Virtual (Para posicionamiento exacto)
    local boardW, boardH = 900, 600
    
    -- Valores del juego
    local inputs = { math.random(1, 9), math.random(1, 9), math.random(1, 9) }
    local modifiers = { 1, 2, 10 }
    local modIcons = { "[]", "X", "Φ" } 
    
    -- Mezclar multiplicadores
    for i = 3, 2, -1 do
        local j = math.random(i)
        modifiers[i], modifiers[j] = modifiers[j], modifiers[i]
        modIcons[i], modIcons[j] = modIcons[j], modIcons[i]
    end
    
    -- Generar TARGET garantizando una solución válida
    local targetVolt = 0
    local secretCombo = {1, 2, 3}
    for i = 3, 2, -1 do
        local j = math.random(i)
        secretCombo[i], secretCombo[j] = secretCombo[j], secretCombo[i]
    end
    for i=1, 3 do targetVolt = targetVolt + (inputs[i] * modifiers[secretCombo[i]]) end
    
    local connections = {0, 0, 0}
    local colors = { Color(255, 170, 0), Color(255, 40, 40), Color(40, 70, 255) }
    local selectedInput = 0
    
    -- Crear Botones Invisibles para interacción
    local btnIns, btnOuts = {}, {}
    local nodeSize = 70
    
    for i=1, 3 do
        btnIns[i] = vgui.Create("DButton", gamePnl)
        btnIns[i]:SetText("")
        btnIns[i].Paint = function() end
        btnIns[i].DoClick = function()
            selectedInput = i
            connections[i] = 0
            surface.PlaySound("buttons/lightswitch2.wav")
        end
        
        btnOuts[i] = vgui.Create("DButton", gamePnl)
        btnOuts[i]:SetText("")
        btnOuts[i].Paint = function() end
        btnOuts[i].DoClick = function()
            if selectedInput > 0 then
                for j=1, 3 do if connections[j] == i then connections[j] = 0 end end
                connections[selectedInput] = i
                selectedInput = 0
                surface.PlaySound("buttons/blip1.wav")
                
                -- Check Win Condition
                local currentVolt, totalConnected = 0, 0
                for k=1, 3 do
                    if connections[k] > 0 then
                        currentVolt = currentVolt + (inputs[k] * modifiers[connections[k]])
                        totalConnected = totalConnected + 1
                    end
                end
                
                if totalConnected == 3 then
                    if currentVolt == targetVolt then
                        surface.PlaySound("buttons/button14.wav")
                        timer.Simple(0.8, function() if onComplete then onComplete(true) end end)
                    else
                        surface.PlaySound("buttons/button10.wav")
                        connections = {0, 0, 0} -- Cortocircuito
                    end
                end
            end
        end
    end

    gamePnl.Paint = function(self, w, h)
        local startX = (w - boardW) / 2
        local startY = (h - boardH) / 2
        
        -- Fondo gris oscuro
        surface.SetDrawColor(10, 12, 15, 255)
        surface.DrawRect(0, 0, w, h)
        
        -- Scanlines
        surface.SetDrawColor(0, 0, 0, 80)
        for i = 0, h, 3 do surface.DrawLine(0, i, w, i) end
        
        -- Grilla técnica (puntos de anclaje)
        surface.SetDrawColor(40, 45, 50, 100)
        for x = 0, boardW, 30 do
            for y = 0, boardH, 30 do
                surface.DrawRect(startX + x, startY + y, 2, 2)
            end
        end
        
        local cx = w / 2
        
        -- ========== DECORACIONES TÉCNICAS ==========
        surface.SetDrawColor(100, 100, 100, 255)
        surface.DrawRect(startX + 100, startY + 49, cx - 200, 2)
        local zx, zy = startX + 220, startY + 50
        surface.DrawLine(zx, zy, zx+10, zy-15) surface.DrawLine(zx+10, zy-15, zx+30, zy+15)
        surface.DrawLine(zx+30, zy+15, zx+50, zy-15) surface.DrawLine(zx+50, zy-15, zx+70, zy+15)
        surface.DrawLine(zx+70, zy+15, zx+80, zy)
        
        surface.DrawRect(startX + 100, startY + 549, cx - 200, 2)
        local bx, by = startX + 200, startY + 535
        surface.SetDrawColor(50, 50, 50, 255)
        surface.DrawOutlinedRect(bx, by, 90, 30, 2)
        surface.DrawRect(bx - 5, by + 10, 5, 10)
        surface.SetDrawColor(50, 255, 100, 255)
        for b = 1, 5 do surface.DrawRect(bx + 5 + (b-1)*16, by + 5, 12, 20) end
        
        -- ========== PANTALLAS DIGITALES ==========
        draw.SimpleText("TARGET", "Volt_Text", cx, startY + 15, Color(255, 50, 50), TEXT_ALIGN_CENTER)
        surface.SetDrawColor(20, 20, 20, 255)
        surface.DrawRect(cx - 100, startY + 30, 200, 80)
        surface.SetDrawColor(100, 100, 100, 255)
        surface.DrawOutlinedRect(cx - 100, startY + 30, 200, 80, 2)
        surface.DrawLine(cx - 33, startY + 30, cx - 33, startY + 110)
        surface.DrawLine(cx + 33, startY + 30, cx + 33, startY + 110)
        draw.SimpleText(string.format("%03d", targetVolt), "Volt_Digital_Huge", cx, startY + 35, Color(255, 50, 50), TEXT_ALIGN_CENTER)
        
        local currentVolt = 0
        for i=1, 3 do
            if connections[i] > 0 then currentVolt = currentVolt + (inputs[i] * modifiers[connections[i]]) end
        end
        
        surface.SetDrawColor(20, 20, 20, 255)
        surface.DrawRect(cx - 100, startY + 490, 200, 80)
        surface.SetDrawColor(100, 100, 100, 255)
        surface.DrawOutlinedRect(cx - 100, startY + 490, 200, 80, 2)
        surface.DrawLine(cx - 33, startY + 490, cx - 33, startY + 570)
        surface.DrawLine(cx + 33, startY + 490, cx + 33, startY + 570)
        draw.SimpleText(string.format("%03d", currentVolt), "Volt_Digital_Huge", cx, startY + 495, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        draw.SimpleText("RESULT", "Volt_Text", cx, startY + 580, Color(150, 150, 150), TEXT_ALIGN_CENTER)
        
        -- ========== DIBUJO DE CABLES (ENRUTAMIENTO ORTOGONAL / MANHATTAN) ==========
        local nodeX_In = startX + 150
        local nodeX_Out = startX + 750
        local mx, my = self:CursorPos()
        
        for i=1, 3 do
            local y1 = startY + 150 + (i-1)*130 + nodeSize/2
            local x1 = nodeX_In + nodeSize + 5
            
            if connections[i] > 0 or selectedInput == i then
                surface.SetDrawColor(colors[i])
                
                local x2, y2
                local midX
                
                if connections[i] > 0 then
                    -- CABLE CONECTADO
                    x2 = nodeX_Out - 5
                    y2 = startY + 150 + (connections[i]-1)*130 + nodeSize/2
                    -- Escalonar el quiebre para que los 3 cables no se monten en la misma línea
                    midX = startX + 390 + (i * 30) 
                else
                    -- CABLE INTERACTIVO (Arrastrando)
                    x2 = mx
                    y2 = my
                    -- Que el quiebre siga la cuadrícula de 30px
                    midX = startX + math.floor(((x1 + x2) / 2 - startX) / 30) * 30
                    if midX < x1 + 15 then midX = x1 + 15 end
                    -- Dibujar la punta en el ratón
                    surface.DrawRect(mx - 5, my - 5, 10, 10)
                end
                
                -- Dibujar los 3 segmentos ortogonales (Grosor 6px)
                if x2 > x1 then
                    -- Segmento 1: Horizontal (Origen -> Mitad)
                    surface.DrawRect(x1, y1 - 3, midX - x1 + 3, 6)
                    -- Segmento 2: Vertical (Mitad Arriba -> Mitad Abajo)
                    surface.DrawRect(midX - 3, math.min(y1, y2) - 3, 6, math.abs(y2 - y1) + 6)
                    -- Segmento 3: Horizontal (Mitad -> Destino)
                    surface.DrawRect(math.min(midX, x2) - 3, y2 - 3, math.abs(x2 - midX) + 6, 6)
                else
                    -- Si el cursor se va hacia atrás, dibujamos línea directa sencilla
                    surface.DrawRect(math.min(x1, x2) - 3, y1 - 3, math.abs(x2 - x1) + 6, 6)
                    surface.DrawRect(x2 - 3, math.min(y1, y2) - 3, 6, math.abs(y2 - y1) + 6)
                end
                
                -- Animación de pulso de energía recorriendo las esquinas
                if connections[i] > 0 then
                    local prc = (CurTime() * 1.5) % 1
                    local len1 = math.abs(midX - x1)
                    local len2 = math.abs(y2 - y1)
                    local len3 = math.abs(x2 - midX)
                    local totalLen = len1 + len2 + len3
                    
                    if totalLen > 0 then
                        local currentDist = prc * totalLen
                        local px, py
                        
                        -- Calcular en qué segmento está el pulso actual
                        if currentDist <= len1 then
                            local t = currentDist / len1
                            px = x1 + (midX - x1) * t
                            py = y1
                        elseif currentDist <= len1 + len2 then
                            local t = (currentDist - len1) / len2
                            px = midX
                            py = y1 + (y2 - y1) * t
                        else
                            local t = (currentDist - len1 - len2) / len3
                            px = midX + (x2 - midX) * t
                            py = y2
                        end
                        
                        surface.SetDrawColor(colors[i])
                        surface.DrawRect(px - 5, py - 5, 10, 10)
                        surface.SetDrawColor(255, 255, 255)
                        surface.DrawRect(px - 2, py - 2, 4, 4)
                    end
                end
            end
        end

        -- ========== NODOS (Inputs y Outputs) ==========
        for i=1, 3 do
            local yPos = startY + 150 + (i-1)*130
            local col = colors[i]
            
            -- CUADRADOS IZQUIERDOS (INPUTS)
            surface.SetDrawColor(15, 15, 15, 255)
            surface.DrawRect(nodeX_In, yPos, nodeSize, nodeSize)
            surface.SetDrawColor(col)
            surface.DrawOutlinedRect(nodeX_In, yPos, nodeSize, nodeSize, (selectedInput == i) and 4 or 2)
            
            surface.DrawRect(nodeX_In - 4, yPos + 10, 4, 10)
            surface.DrawRect(nodeX_In - 4, yPos + nodeSize - 20, 4, 10)
            surface.DrawRect(nodeX_In + nodeSize, yPos + nodeSize/2 - 8, 10, 16)
            
            draw.SimpleText(inputs[i], "Volt_Digital_Large", nodeX_In + nodeSize/2, yPos + nodeSize/2 - 2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- CÍRCULOS DERECHOS (MULTIPLIERS)
            local outColor = Color(100, 100, 100)
            for j=1, 3 do if connections[j] == i then outColor = colors[j] end end
            
            surface.SetDrawColor(15, 15, 15, 255)
            draw.RoundedBox(nodeSize/2, nodeX_Out, yPos, nodeSize, nodeSize, Color(15, 15, 15))
            DrawCircle(nodeX_Out + nodeSize/2, yPos + nodeSize/2, nodeSize/2, 2, outColor)
            
            surface.SetDrawColor(outColor)
            surface.DrawRect(nodeX_Out + nodeSize, yPos + 10, 4, 10)
            surface.DrawRect(nodeX_Out + nodeSize, yPos + nodeSize - 20, 4, 10)
            surface.DrawRect(nodeX_Out - 10, yPos + nodeSize/2 - 8, 10, 16)
            
            draw.SimpleText(modIcons[i], "Volt_Icon", nodeX_Out + nodeSize/2, yPos + nodeSize/2 - 2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            if IsValid(btnIns[i]) then
                btnIns[i]:SetPos(nodeX_In, yPos)
                btnIns[i]:SetSize(nodeSize + 10, nodeSize)
            end
            if IsValid(btnOuts[i]) then
                btnOuts[i]:SetPos(nodeX_Out - 10, yPos)
                btnOuts[i]:SetSize(nodeSize + 10, nodeSize)
            end
        end
    end
end