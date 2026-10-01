if not CLIENT then return end

-- Fuentes estilo CRT/Monospaced profesionales
surface.CreateFont("Circ_Title", { font = "Consolas", size = 35, weight = 800, antialias = true, shadow = true })
surface.CreateFont("Circ_Text",  { font = "Courier New", size = 22, weight = 600, antialias = true })
surface.CreateFont("Circ_Glow",  { font = "Consolas", size = 35, weight = 800, blursize = 4, antialias = true })
surface.CreateFont("Circ_Tiny",  { font = "Courier New", size = 10, weight = 400, antialias = true })
surface.CreateFont("Circ_Chip",  { font = "Consolas", size = 9, weight = 700, antialias = true })

-- Dimensiones del lienzo virtual
local boardW, boardH = 900, 500
local pathThick = 10
local playerSize = 10

-- Colores
local clr = {
    bg        = Color(10, 25, 18, 255),
    bgBoard   = Color(8, 30, 20, 255),
    grid      = Color(15, 40, 25, 60),
    trace     = Color(20, 100, 50, 255),
    traceDark = Color(12, 60, 30, 200),
    traceFaint= Color(18, 70, 40, 120),
    copper    = Color(45, 130, 65, 180),
    copperBright = Color(60, 180, 90, 255),
    solder    = Color(80, 200, 110, 200),
    solderDot = Color(50, 150, 80, 150),
    -- Chips DECORATIVOS (fondo, verde oscuro sutil)
    chipBg    = Color(10, 35, 20, 255),
    chipBorder= Color(30, 100, 55, 180),
    chipText  = Color(25, 80, 45, 160),
    chipPin   = Color(35, 110, 60, 200),
    -- PAREDES DE COLISIÓN (gris metálico, claramente distinto)
    wallBg     = Color(55, 65, 75, 255),
    wallBorder = Color(160, 180, 200, 255),
    wallInner  = Color(80, 95, 110, 255),
    wallPin    = Color(130, 150, 170, 240),
    wallText   = Color(120, 140, 165, 200),
    wallSolder = Color(170, 190, 210, 220),
    -- Hilo del jugador
    path      = Color(50, 255, 100, 255),
    pathGlow  = Color(50, 255, 100, 150),
    head      = Color(255, 255, 255, 255),
    headGlow  = Color(150, 255, 200, 255),
    portIn    = Color(100, 255, 130, 255),
    portOut   = Color(100, 255, 130, 255),
    ui        = Color(200, 255, 200, 255),
    viaHole   = Color(5, 20, 12, 255),
    viaRing   = Color(40, 130, 65, 200),
    resistor  = Color(60, 40, 20, 200),
    capColor  = Color(30, 100, 50, 180),
}

-- Precalcular decoraciones de PCB (Se generan una vez y se reusan)
local pcbDecorations = nil

local function GeneratePCBDecorations()
    local decs = {
        traces = {},    -- Pistas de cobre decorativas
        vias = {},      -- Puntos de soldadura (vías)
        chips = {},     -- Chips IC decorativos
        resistors = {}, -- Resistencias
        capacitors = {},-- Condensadores
        texts = {},     -- Textos técnicos
    }
    
    math.randomseed(os.time())
    
    -- Pistas de cobre decorativas horizontales y verticales
    for i = 1, 40 do
        local horizontal = math.random() > 0.5
        if horizontal then
            local y = math.random(10, boardH - 10)
            local x1 = math.random(0, boardW - 200)
            local len = math.random(40, 250)
            table.insert(decs.traces, {x = x1, y = y, w = len, h = 2, dir = "h"})
        else
            local x = math.random(10, boardW - 10)
            local y1 = math.random(0, boardH - 200)
            local len = math.random(40, 200)
            table.insert(decs.traces, {x = x, y = y1, w = 2, h = len, dir = "v"})
        end
    end
    
    -- Pistas de cobre con esquinas (L-shapes)
    for i = 1, 15 do
        local x = math.random(30, boardW - 100)
        local y = math.random(30, boardH - 100)
        local legH = math.random(30, 80)
        local legW = math.random(30, 100)
        local flipH = math.random() > 0.5
        local flipV = math.random() > 0.5
        table.insert(decs.traces, {x = x, y = flipV and y - legH or y, w = 2, h = legH, dir = "v"})
        table.insert(decs.traces, {x = flipH and x - legW or x, y = y, w = legW, h = 2, dir = "h"})
    end
    
    -- Vías (puntos de soldadura circulares)
    for i = 1, 60 do
        table.insert(decs.vias, {
            x = math.random(15, boardW - 15),
            y = math.random(15, boardH - 15),
            r = math.random(3, 6)
        })
    end
    
    -- Chips IC decorativos (rectángulos con pines)
    for i = 1, 8 do
        local cw = math.random(30, 70)
        local ch = math.random(20, 45)
        table.insert(decs.chips, {
            x = math.random(20, boardW - cw - 20),
            y = math.random(20, boardH - ch - 20),
            w = cw, h = ch,
            label = ({"U" .. math.random(1,99), "IC" .. math.random(1,30), "R" .. math.random(100,999), "74LS" .. math.random(0,9) .. math.random(0,9)})[math.random(1,4)]
        })
    end
    
    -- Resistencias decorativas
    for i = 1, 12 do
        local horizontal = math.random() > 0.5
        table.insert(decs.resistors, {
            x = math.random(20, boardW - 50),
            y = math.random(20, boardH - 30),
            horizontal = horizontal,
            len = math.random(15, 30)
        })
    end
    
    -- Condensadores decorativos
    for i = 1, 8 do
        table.insert(decs.capacitors, {
            x = math.random(20, boardW - 30),
            y = math.random(20, boardH - 30),
            size = math.random(6, 12)
        })
    end
    
    -- Textos técnicos (Silkscreen labels)
    local labels = {"GND", "VCC", "3V3", "CLK", "RST", "SDA", "SCL", "TX", "RX", "D0", "D1", "A0", "REF", "PWR", "EN", "CS", "MOSI", "MISO", "SS"}
    for i = 1, 14 do
        table.insert(decs.texts, {
            x = math.random(20, boardW - 40),
            y = math.random(20, boardH - 20),
            text = labels[math.random(1, #labels)],
            rot = math.random() > 0.7
        })
    end
    
    return decs
end

-- Función para dibujar las decoraciones de PCB
local function DrawPCBBackground(startX, startY)
    if not pcbDecorations then
        pcbDecorations = GeneratePCBDecorations()
    end
    
    local d = pcbDecorations
    
    -- Fondo de placa base
    surface.SetDrawColor(clr.bgBoard)
    surface.DrawRect(startX, startY, boardW, boardH)
    
    -- Grilla PCB muy sutil
    surface.SetDrawColor(clr.grid)
    for x = 0, boardW, 25 do
        surface.DrawLine(startX + x, startY, startX + x, startY + boardH)
    end
    for y = 0, boardH, 25 do
        surface.DrawLine(startX, startY + y, startX + boardW, startY + y)
    end
    
    -- Pistas de cobre decorativas
    surface.SetDrawColor(clr.traceFaint)
    for _, t in ipairs(d.traces) do
        surface.DrawRect(startX + t.x, startY + t.y, t.w, t.h)
    end
    
    -- Puntos de soldadura con terminales
    for _, t in ipairs(d.traces) do
        surface.SetDrawColor(clr.solderDot)
        if t.dir == "h" then
            -- Pads en los extremos de las pistas horizontales
            surface.DrawRect(startX + t.x - 2, startY + t.y - 3, 5, 8)
            surface.DrawRect(startX + t.x + t.w - 3, startY + t.y - 3, 5, 8)
        else
            surface.DrawRect(startX + t.x - 3, startY + t.y - 2, 8, 5)
            surface.DrawRect(startX + t.x - 3, startY + t.y + t.h - 3, 8, 5)
        end
    end
    
    -- Vías (Agujeros pasantes con anillo)
    for _, v in ipairs(d.vias) do
        -- Anillo exterior
        surface.SetDrawColor(clr.viaRing)
        local segments = 12
        for s = 0, segments - 1 do
            local a1 = (s / segments) * math.pi * 2
            local a2 = ((s + 1) / segments) * math.pi * 2
            surface.DrawLine(
                startX + v.x + math.cos(a1) * v.r,
                startY + v.y + math.sin(a1) * v.r,
                startX + v.x + math.cos(a2) * v.r,
                startY + v.y + math.sin(a2) * v.r
            )
        end
        -- Centro oscuro (agujero)
        surface.SetDrawColor(clr.viaHole)
        local inner = math.max(1, v.r - 2)
        surface.DrawRect(startX + v.x - inner, startY + v.y - inner, inner * 2, inner * 2)
    end
    
    -- Chips IC decorativos
    for _, c in ipairs(d.chips) do
        -- Cuerpo del chip
        surface.SetDrawColor(clr.chipBg)
        surface.DrawRect(startX + c.x, startY + c.y, c.w, c.h)
        surface.SetDrawColor(clr.chipBorder)
        surface.DrawOutlinedRect(startX + c.x, startY + c.y, c.w, c.h, 1)
        
        -- Muesca de orientación (semicírculo en la esquina)
        surface.SetDrawColor(clr.chipBorder)
        surface.DrawOutlinedRect(startX + c.x + 2, startY + c.y + 2, 4, 4, 1)
        
        -- Pines superiores e inferiores
        local pinCount = math.floor(c.w / 8)
        surface.SetDrawColor(clr.chipPin)
        for p = 0, pinCount - 1 do
            local px = c.x + 4 + p * 8
            surface.DrawRect(startX + px, startY + c.y - 4, 2, 4)
            surface.DrawRect(startX + px, startY + c.y + c.h, 2, 4)
        end
        
        -- Pines laterales
        local sidePins = math.floor(c.h / 8)
        for p = 0, sidePins - 1 do
            local py = c.y + 4 + p * 8
            surface.DrawRect(startX + c.x - 4, startY + py, 4, 2)
            surface.DrawRect(startX + c.x + c.w, startY + py, 4, 2)
        end
        
        -- Label del chip
        draw.SimpleText(c.label, "Circ_Chip", startX + c.x + c.w/2, startY + c.y + c.h/2, clr.chipText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Resistencias decorativas
    for _, r in ipairs(d.resistors) do
        surface.SetDrawColor(clr.copper)
        if r.horizontal then
            -- Leads
            surface.DrawRect(startX + r.x, startY + r.y + 1, 4, 1)
            surface.DrawRect(startX + r.x + r.len - 4, startY + r.y + 1, 4, 1)
            -- Cuerpo
            surface.SetDrawColor(clr.resistor)
            surface.DrawRect(startX + r.x + 4, startY + r.y - 2, r.len - 8, 6)
            -- Bandas de color
            surface.SetDrawColor(clr.copperBright)
            surface.DrawRect(startX + r.x + 6, startY + r.y - 2, 2, 6)
            surface.SetDrawColor(255, 50, 50, 150)
            surface.DrawRect(startX + r.x + 10, startY + r.y - 2, 2, 6)
            surface.SetDrawColor(clr.copperBright)
            surface.DrawRect(startX + r.x + r.len - 10, startY + r.y - 2, 2, 6)
        else
            surface.DrawRect(startX + r.x + 1, startY + r.y, 1, 4)
            surface.DrawRect(startX + r.x + 1, startY + r.y + r.len - 4, 1, 4)
            surface.SetDrawColor(clr.resistor)
            surface.DrawRect(startX + r.x - 2, startY + r.y + 4, 6, r.len - 8)
            surface.SetDrawColor(clr.copperBright)
            surface.DrawRect(startX + r.x - 2, startY + r.y + 6, 6, 2)
            surface.SetDrawColor(255, 50, 50, 150)
            surface.DrawRect(startX + r.x - 2, startY + r.y + 10, 6, 2)
        end
    end
    
    -- Condensadores decorativos (rectángulos con gap)
    for _, cap in ipairs(d.capacitors) do
        surface.SetDrawColor(clr.capColor)
        -- Lead superior
        surface.DrawRect(startX + cap.x + cap.size/2, startY + cap.y, 1, cap.size/3)
        -- Placa 1
        surface.DrawRect(startX + cap.x, startY + cap.y + cap.size/3, cap.size, 2)
        -- Placa 2
        surface.DrawRect(startX + cap.x, startY + cap.y + cap.size/3 + 4, cap.size, 2)
        -- Lead inferior
        surface.DrawRect(startX + cap.x + cap.size/2, startY + cap.y + cap.size/3 + 6, 1, cap.size/3)
    end
    
    -- Textos silkscreen
    for _, t in ipairs(d.texts) do
        draw.SimpleText(t.text, "Circ_Tiny", startX + t.x, startY + t.y, clr.chipText, TEXT_ALIGN_LEFT)
    end
    
    -- Borde de la placa
    surface.SetDrawColor(clr.copper)
    surface.DrawOutlinedRect(startX, startY, boardW, boardH, 2)
    -- Doble borde interior
    surface.SetDrawColor(clr.traceDark)
    surface.DrawOutlinedRect(startX + 4, startY + 4, boardW - 8, boardH - 8, 1)
    
    -- Agujeros de montaje en las esquinas
    local holeR = 6
    local holePositions = {
        {x = 12, y = 12}, {x = boardW - 12, y = 12},
        {x = 12, y = boardH - 12}, {x = boardW - 12, y = boardH - 12}
    }
    for _, hp in ipairs(holePositions) do
        surface.SetDrawColor(clr.viaRing)
        for s = 0, 15 do
            local a1 = (s / 16) * math.pi * 2
            local a2 = ((s + 1) / 16) * math.pi * 2
            surface.DrawLine(
                startX + hp.x + math.cos(a1) * holeR,
                startY + hp.y + math.sin(a1) * holeR,
                startX + hp.x + math.cos(a2) * holeR,
                startY + hp.y + math.sin(a2) * holeR
            )
        end
        surface.SetDrawColor(clr.viaHole)
        surface.DrawRect(startX + hp.x - 3, startY + hp.y - 3, 6, 6)
    end
end

local function CheckAABB(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x1 + w1 > x2 and y1 < y2 + h2 and y1 + h1 > y2
end

-- =========================================================================
-- DISEÑO DE NIVELES MANUALES (Playables 100%, Entradas/Salidas asimétricas)
-- =========================================================================
local circuitLevels = {
    { -- NIVEL 1: El Escáner (Zig-zag vertical con columnas completas)
        start = {y = 250}, target = {y = 250},
        chips = {
            {x = 160, y = -20, w = 40, h = 330}, -- Te empuja hacia abajo
            {x = 340, y = 190, w = 40, h = 330}, -- Te empuja hacia arriba
            {x = 520, y = -20, w = 40, h = 330}, -- Te empuja hacia abajo
            {x = 700, y = 190, w = 40, h = 330}, -- Te empuja hacia arriba
        }
    },
   { -- NIVEL 2: La Serpiente (Túneles asimétricos, laberinto perfecto sin bloqueos ciegos)
        start = {y = 250}, target = {y = 380},
        chips = {
            -- Columna 1
            {x = 140, y = -20, w = 40, h = 300}, 
            {x = 140, y = 360, w = 40, h = 160}, 
            {x = 180, y = 80,  w = 70, h = 40},  -- Trampa hacia la derecha
            
            -- Columna 2
            {x = 280, y = -20, w = 40, h = 120}, 
            {x = 280, y = 180, w = 40, h = 340}, 
            {x = 210, y = 380, w = 70, h = 40},  -- Trampa hacia la izquierda
            
            -- Columna 3
            {x = 420, y = -20, w = 40, h = 360}, 
            {x = 420, y = 420, w = 40, h = 100}, 
            {x = 350, y = 200, w = 70, h = 40},  -- Trampa hacia la izquierda
            
            -- Columna 4
            {x = 560, y = -20, w = 40, h = 160}, 
            {x = 560, y = 220, w = 40, h = 300}, 
            {x = 600, y = 280, w = 60, h = 40},  -- Trampa hacia la derecha
            
            -- Columna 5
            {x = 700, y = -20, w = 40, h = 320}, 
            {x = 700, y = 430, w = 40, h = 90},  
            {x = 640, y = 100, w = 60, h = 40},  -- Trampa hacia la izquierda
        }
    },
    { -- NIVEL 3: El Firewall (Densidad extrema, precisión requerida)
        start = {y = 250}, target = {y = 250},
        chips = {
            -- Columna 1 (Hueco exacto al medio)
            {x = 120, y = -20, w = 30, h = 200}, 
            {x = 120, y = 260, w = 30, h = 260},
            
            -- Columna 2 (Hueco por arriba)
            {x = 240, y = 100, w = 30, h = 420},
            
            -- Columna 3 (Hueco por abajo)
            {x = 360, y = -20, w = 30, h = 350},
            
            -- Columna 4 (Doble hueco con trampa al medio)
            {x = 480, y = 150, w = 30, h = 200}, 
            {x = 480, y = 420, w = 30, h = 100},
            {x = 480, y = -20, w = 30, h = 100},
            
            -- Columna 5 (Hueco por arriba)
            {x = 600, y = 100, w = 30, h = 420},
            
            -- Columna 6 (Hueco perfecto alineado con la meta)
            {x = 720, y = -20, w = 30, h = 230}, 
            {x = 720, y = 290, w = 30, h = 230},
            
            -- Bloques horizontales falsos para confundir
            {x = 240, y = 100, w = 80, h = 30},
            {x = 360, y = 300, w = 80, h = 30},
            {x = 600, y = 100, w = 80, h = 30},
        }
    }
}


function Datapad_LoadCircuit(parentPanel, themeColor, onComplete)
    local gamePnl = vgui.Create("DPanel", parentPanel)
    gamePnl:Dock(FILL)
    gamePnl:RequestFocus()
    gamePnl:SetKeyboardInputEnabled(true)
    
    -- Regenerar decoraciones para cada nueva sesión
    pcbDecorations = GeneratePCBDecorations()
    
    local currentLevel = 1
    local levelData = nil
    
    local playerPos = {x = 0, y = 0}
    local startPort = {x = 0, y = 0, w = 25, h = 100}
    local targetPort = {x = 0, y = 0, w = 25, h = 100}
    
    local trail = {}
    local currentDir = {x = 1, y = 0}
    local lastTurnPos = {x = 0, y = 0}
    
    local state = "WAITING"
    local speed = 350
    
    local function LoadLevel(lvl)
        levelData = circuitLevels[lvl]
        startPort.x, startPort.y = 0, levelData.start.y - startPort.h/2
        targetPort.x, targetPort.y = boardW - targetPort.w, levelData.target.y - targetPort.h/2
        playerPos.x = startPort.w + playerSize/2
        playerPos.y = levelData.start.y
        trail = { {x = playerPos.x, y = playerPos.y} }
        currentDir = {x = 1, y = 0}
        lastTurnPos = {x = playerPos.x, y = playerPos.y}
        state = "WAITING"
    end
    
    LoadLevel(currentLevel)

    gamePnl.Paint = function(self, w, h)
        local dt = FrameTime()
        
        local startX = (w - boardW) / 2
        local startY = (h - boardH) / 2 + 25
        
        -- Fondo exterior (scanlines estilo monitor CRT)
        surface.SetDrawColor(clr.bg)
        surface.DrawRect(0, 0, w, h)
        
        -- Scanlines sutiles sobre toda la pantalla
        surface.SetDrawColor(0, 0, 0, 25)
        for y = 0, h, 3 do
            surface.DrawLine(0, y, w, y)
        end
        
        -- Título y estado
        draw.SimpleText("VLSI CIRCUIT BREAKER 2.0", "Circ_Glow", w/2, 25, Color(clr.path.r, clr.path.g, clr.path.b, 100), TEXT_ALIGN_CENTER)
        draw.SimpleText("VLSI CIRCUIT BREAKER 2.0", "Circ_Title", w/2, 25, clr.path, TEXT_ALIGN_CENTER)
        draw.SimpleText("LAYER: " .. currentLevel .. "/3", "Circ_Text", startX + 10, 25, clr.ui, TEXT_ALIGN_LEFT)

        -- ========== PLACA BASE DETALLADA ==========
        DrawPCBBackground(startX, startY)

        -- ========== LÓGICA DE MOVIMIENTO ==========
        if state == "PLAYING" then
            playerPos.x = playerPos.x + (currentDir.x * speed * dt)
            playerPos.y = playerPos.y + (currentDir.y * speed * dt)
            
            local px = playerPos.x - playerSize/2
            local py = playerPos.y - playerSize/2
            local collision = false
            
            if playerPos.x < 0 or playerPos.x > boardW or playerPos.y < 0 or playerPos.y > boardH then
                collision = true
            end
            
            if not collision then
                for _, chip in ipairs(levelData.chips) do
                    if CheckAABB(px, py, playerSize, playerSize, chip.x, chip.y, chip.w, chip.h) then
                        collision = true
                        break
                    end
                end
            end
            
            if not collision and #trail > 2 then
                for i = 1, #trail - 2 do
                    local p1, p2 = trail[i], trail[i+1]
                    local lineX = math.min(p1.x, p2.x) - pathThick/2
                    local lineY = math.min(p1.y, p2.y) - pathThick/2
                    local lineW = math.abs(p2.x - p1.x) + pathThick
                    local lineH = math.abs(p2.y - p1.y) + pathThick
                    if CheckAABB(px, py, playerSize, playerSize, lineX, lineY, lineW, lineH) then
                        collision = true
                        break
                    end
                end
            end
            
            if collision then
                state = "LOST"
                surface.PlaySound("buttons/button10.wav")
            end
            
            if not collision and CheckAABB(px, py, playerSize, playerSize, targetPort.x, targetPort.y, targetPort.w, targetPort.h) then
                if currentLevel < 3 then
                    state = "NEXT_LEVEL"
                    surface.PlaySound("buttons/blip2.wav")
                    timer.Simple(1.5, function()
                        if IsValid(gamePnl) then
                            currentLevel = currentLevel + 1
                            pcbDecorations = GeneratePCBDecorations()
                            LoadLevel(currentLevel)
                        end
                    end)
                else
                    state = "WON"
                    surface.PlaySound("buttons/button14.wav")
                    timer.Simple(1.5, function() if onComplete then onComplete(true) end end)
                end
            end
        end

        -- ========== OBSTÁCULOS (Paredes metálicas - color distinto a decoraciones) ==========
        for _, chip in ipairs(levelData.chips) do
            -- Sombra
            surface.SetDrawColor(0, 0, 0, 100)
            surface.DrawRect(startX + chip.x + 3, startY + chip.y + 3, chip.w, chip.h)
            
            -- Cuerpo del muro (GRIS METÁLICO)
            surface.SetDrawColor(clr.wallBg)
            surface.DrawRect(startX + chip.x, startY + chip.y, chip.w, chip.h)
            
            -- Borde exterior brillante
            surface.SetDrawColor(clr.wallBorder)
            surface.DrawOutlinedRect(startX + chip.x, startY + chip.y, chip.w, chip.h, 1)
            -- Borde interior
            surface.SetDrawColor(clr.wallInner)
            surface.DrawOutlinedRect(startX + chip.x + 2, startY + chip.y + 2, chip.w - 4, chip.h - 4, 1)
            
            -- Pines superiores e inferiores
            local pinCount = math.floor(chip.w / 8)
            for p = 0, pinCount - 1 do
                local pinX = chip.x + 4 + p * 8
                surface.SetDrawColor(clr.wallPin)
                surface.DrawRect(startX + pinX, startY + chip.y - 5, 3, 5)
                surface.SetDrawColor(clr.wallSolder)
                surface.DrawRect(startX + pinX, startY + chip.y - 6, 3, 2)
                surface.SetDrawColor(clr.wallPin)
                surface.DrawRect(startX + pinX, startY + chip.y + chip.h, 3, 5)
                surface.SetDrawColor(clr.wallSolder)
                surface.DrawRect(startX + pinX, startY + chip.y + chip.h + 4, 3, 2)
            end
            
            -- Pines laterales
            local sidePins = math.floor(chip.h / 10)
            for p = 0, sidePins - 1 do
                local pinY = chip.y + 5 + p * 10
                surface.SetDrawColor(clr.wallPin)
                surface.DrawRect(startX + chip.x - 5, startY + pinY, 5, 3)
                surface.DrawRect(startX + chip.x + chip.w, startY + pinY, 5, 3)
                surface.SetDrawColor(clr.wallSolder)
                surface.DrawRect(startX + chip.x - 6, startY + pinY, 2, 3)
                surface.DrawRect(startX + chip.x + chip.w + 4, startY + pinY, 2, 3)
            end
            
            -- Muesca de orientación
            surface.SetDrawColor(clr.wallBorder)
            surface.DrawOutlinedRect(startX + chip.x + 3, startY + chip.y + 3, 5, 5, 1)
            
            -- Etiqueta interna
            if chip.w > 30 then
                local chipLabel = "FW" .. math.floor(chip.x / 100 + chip.y / 50)
                draw.SimpleText(chipLabel, "Circ_Chip", startX + chip.x + chip.w/2, startY + chip.y + chip.h/2, clr.wallText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            -- Líneas internas
            surface.SetDrawColor(clr.wallInner)
            if chip.h > 60 then
                for li = 1, math.min(3, math.floor(chip.h / 50)) do
                    local ly = chip.y + li * (chip.h / 4)
                    surface.DrawLine(startX + chip.x + 4, startY + ly, startX + chip.x + chip.w - 4, startY + ly)
                end
            end
        end

        -- ========== PUERTOS DE HARDWARE ==========
        -- Puerto de entrada
        surface.SetDrawColor(clr.portIn)
        surface.DrawRect(startX + startPort.x, startY + startPort.y, startPort.w, startPort.h)
        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawOutlinedRect(startX + startPort.x, startY + startPort.y, startPort.w, startPort.h, 2)
        -- Conector decorativo
        surface.SetDrawColor(clr.portIn.r, clr.portIn.g, clr.portIn.b, 100)
        surface.DrawRect(startX + startPort.x + startPort.w, startY + startPort.y + startPort.h/2 - 3, 10, 6)
        draw.SimpleText("IN", "Circ_Chip", startX + startPort.x + startPort.w/2, startY + startPort.y + startPort.h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Puerto de salida
        local portPulse = math.abs(math.sin(CurTime() * 6)) * 100 + 155
        surface.SetDrawColor(clr.portOut.r, clr.portOut.g, clr.portOut.b, portPulse)
        surface.DrawRect(startX + targetPort.x, startY + targetPort.y, targetPort.w, targetPort.h)
        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawOutlinedRect(startX + targetPort.x, startY + targetPort.y, targetPort.w, targetPort.h, 2)
        -- Conector decorativo
        surface.SetDrawColor(clr.portOut.r, clr.portOut.g, clr.portOut.b, 80)
        surface.DrawRect(startX + targetPort.x - 10, startY + targetPort.y + targetPort.h/2 - 3, 10, 6)
        draw.SimpleText("OUT", "Circ_Chip", startX + targetPort.x + targetPort.w/2, startY + targetPort.y + targetPort.h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- ========== RASTRO DEL JUGADOR (Hilo de datos) ==========
        if #trail > 0 then
            local fullTrail = table.Copy(trail)
            table.insert(fullTrail, {x = playerPos.x, y = playerPos.y})
            
            -- Glow exterior
            surface.SetDrawColor(clr.pathGlow)
            for i = 1, #fullTrail - 1 do
                local p1, p2 = fullTrail[i], fullTrail[i+1]
                local lineX = math.min(p1.x, p2.x)
                local lineY = math.min(p1.y, p2.y)
                local lineW = math.abs(p2.x - p1.x)
                local lineH = math.abs(p2.y - p1.y)
                if lineW == 0 then
                    surface.DrawRect(startX + lineX - pathThick/2, startY + lineY - pathThick/2, pathThick, lineH + pathThick)
                else
                    surface.DrawRect(startX + lineX - pathThick/2, startY + lineY - pathThick/2, lineW + pathThick, pathThick)
                end
            end
            
            -- Hilo sólido
            surface.SetDrawColor(clr.path)
            for i = 1, #fullTrail - 1 do
                local p1, p2 = fullTrail[i], fullTrail[i+1]
                local lineX = math.min(p1.x, p2.x)
                local lineY = math.min(p1.y, p2.y)
                local lineW = math.abs(p2.x - p1.x)
                local lineH = math.abs(p2.y - p1.y)
                if lineW == 0 then
                    surface.DrawRect(startX + lineX - pathThick/3, startY + lineY - pathThick/3, pathThick/1.5, lineH + pathThick/1.5)
                else
                    surface.DrawRect(startX + lineX - pathThick/3, startY + lineY - pathThick/3, lineW + pathThick/1.5, pathThick/1.5)
                end
            end
            
            -- Pulso de datos viajando por el rastro (animación)
            if state == "PLAYING" and #fullTrail > 1 then
                local pulseSpeed = CurTime() * 300
                local totalLen = 0
                for i = 1, #fullTrail - 1 do
                    local p1, p2 = fullTrail[i], fullTrail[i+1]
                    totalLen = totalLen + math.abs(p2.x - p1.x) + math.abs(p2.y - p1.y)
                end
                
                if totalLen > 0 then
                    local pulsePos = (pulseSpeed % totalLen)
                    local accumulated = 0
                    for i = 1, #fullTrail - 1 do
                        local p1, p2 = fullTrail[i], fullTrail[i+1]
                        local segLen = math.abs(p2.x - p1.x) + math.abs(p2.y - p1.y)
                        if accumulated + segLen >= pulsePos then
                            local frac = (pulsePos - accumulated) / segLen
                            local px = p1.x + (p2.x - p1.x) * frac
                            local py = p1.y + (p2.y - p1.y) * frac
                            surface.SetDrawColor(255, 255, 255, 200)
                            surface.DrawRect(startX + px - 3, startY + py - 3, 6, 6)
                            break
                        end
                        accumulated = accumulated + segLen
                    end
                end
            end
        end

        -- ========== CABEZA DEL JUGADOR ==========
        if state == "PLAYING" or state == "WAITING" then
            -- Glow
            surface.SetDrawColor(clr.headGlow)
            surface.DrawRect(startX + playerPos.x - playerSize, startY + playerPos.y - playerSize, playerSize*2, playerSize*2)
            -- Sólido
            surface.SetDrawColor(clr.head)
            surface.DrawRect(startX + playerPos.x - playerSize/2, startY + playerPos.y - playerSize/2, playerSize, playerSize)
        end

        -- ========== MENSAJES DE ESTADO ==========
        if state == "WAITING" then
            local blink = math.sin(CurTime()*7) > 0 and clr.ui or Color(100, 100, 100)
            draw.SimpleText("PRESIONA [ESPACIO] PARA RUTEAR SEÑAL", "Circ_Text", w/2, h - 35, blink, TEXT_ALIGN_CENTER)
        elseif state == "LOST" then
            surface.SetDrawColor(0, 0, 0, 230)
            surface.DrawRect(startX, startY + boardH/2 - 50, boardW, 100)
            draw.SimpleText("SIGNAL LOST", "Circ_Glow", w/2, h/2 - 5, Color(255, 50, 50, 100), TEXT_ALIGN_CENTER)
            draw.SimpleText("SIGNAL LOST", "Circ_Title", w/2, h/2 - 5, Color(255, 50, 50), TEXT_ALIGN_CENTER)
            draw.SimpleText("PRESIONA [ESPACIO] PARA REPETIR NIVEL", "Circ_Text", w/2, h/2 + 25, Color(200, 200, 200), TEXT_ALIGN_CENTER)
        elseif state == "NEXT_LEVEL" then
            surface.SetDrawColor(0, 0, 0, 220)
            surface.DrawRect(0, h/2 - 40, w, 80)
            draw.SimpleText("FIREWALL BYPASSED - MOVING TO NEXT SECTOR...", "Circ_Text", w/2, h/2, clr.portIn, TEXT_ALIGN_CENTER)
        elseif state == "WON" then
            surface.SetDrawColor(0, 0, 0, 230)
            surface.DrawRect(0, h/2 - 50, w, 100)
            draw.SimpleText("SYSTEM OVERRIDE COMPLETE", "Circ_Glow", w/2, h/2, Color(clr.path.r, clr.path.g, clr.path.b, 100), TEXT_ALIGN_CENTER)
            draw.SimpleText("SYSTEM OVERRIDE COMPLETE", "Circ_Title", w/2, h/2, clr.path, TEXT_ALIGN_CENTER)
        end
    end
    
    -- Inputs
    gamePnl.OnKeyCodePressed = function(self, key)
        if state == "LOST" and key == KEY_SPACE then
            surface.PlaySound("buttons/lightswitch2.wav")
            LoadLevel(currentLevel)
            return
        end

        if state == "WAITING" then
            if key == KEY_SPACE then
                state = "PLAYING"
                surface.PlaySound("buttons/lightswitch2.wav")
            end
            return
        end
        
        if state ~= "PLAYING" then return end
        
        local newDir = nil
        if (key == KEY_UP or key == KEY_W) and currentDir.y == 0 then newDir = {x = 0, y = -1}
        elseif (key == KEY_DOWN or key == KEY_S) and currentDir.y == 0 then newDir = {x = 0, y = 1}
        elseif (key == KEY_LEFT or key == KEY_A) and currentDir.x == 0 then newDir = {x = -1, y = 0}
        elseif (key == KEY_RIGHT or key == KEY_D) and currentDir.x == 0 then newDir = {x = 1, y = 0}
        end
        
        if newDir then
            local dist = math.abs(playerPos.x - lastTurnPos.x) + math.abs(playerPos.y - lastTurnPos.y)
            if dist > pathThick then
                table.insert(trail, {x = playerPos.x, y = playerPos.y})
                currentDir = newDir
                lastTurnPos = {x = playerPos.x, y = playerPos.y}
                surface.PlaySound("buttons/blip1.wav")
            end
        end
    end
end