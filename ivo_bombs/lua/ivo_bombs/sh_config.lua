--[[
    ivo_bombs - Configuración Compartida
    Dificultades, colores, utilidades
]]

IVO_BOMBS = IVO_BOMBS or {}
IVO_BOMBS.Modules = IVO_BOMBS.Modules or {}

-- ============================================================
-- DIFICULTADES
-- ============================================================
IVO_BOMBS.Difficulties = {
    [1] = {
        name        = "Fácil",
        color       = Color(80, 200, 80),
        bombTime    = 120,
        modules     = 2,
        maxStrikes  = 5,
        wireCount   = 3,
        memoryRounds    = 3,
        memoryStartLen  = 3,
        codeDigits      = 3,
        codeIndicators  = 3,
        patternCells    = 4,
        patternShowTime = 4,
        patternGrid     = 5,
    },
    [2] = {
        name        = "Normal",
        color       = Color(220, 200, 50),
        bombTime    = 90,
        modules     = 3,
        maxStrikes  = 3,
        wireCount   = 4,
        memoryRounds    = 3,
        memoryStartLen  = 4,
        codeDigits      = 3,
        codeIndicators  = 4,
        patternCells    = 6,
        patternShowTime = 3,
        patternGrid     = 5,
    },
    [3] = {
        name        = "Difícil",
        color       = Color(220, 120, 30),
        bombTime    = 60,
        modules     = 4,
        maxStrikes  = 2,
        wireCount   = 5,
        memoryRounds    = 4,
        memoryStartLen  = 4,
        codeDigits      = 4,
        codeIndicators  = 4,
        patternCells    = 8,
        patternShowTime = 2.5,
        patternGrid     = 6,
    },
    [4] = {
        name        = "Extremo",
        color       = Color(220, 40, 40),
        bombTime    = 45,
        modules     = 4,
        maxStrikes  = 1,
        wireCount   = 6,
        memoryRounds    = 4,
        memoryStartLen  = 5,
        codeDigits      = 4,
        codeIndicators  = 5,
        patternCells    = 10,
        patternShowTime = 2,
        patternGrid     = 6,
    },
}

-- Orden de módulos disponibles
IVO_BOMBS.ModuleList = { "wires", "memory", "keypad", "pattern" }

-- ============================================================
-- PALETA DE COLORES UI
-- ============================================================
IVO_BOMBS.Colors = {
    bg          = Color(10, 14, 26),
    panel       = Color(18, 24, 40),
    panelLight  = Color(25, 32, 52),
    panelDark   = Color(8, 10, 18),
    border      = Color(40, 50, 70),
    borderLight = Color(60, 75, 100),
    accent      = Color(0, 200, 255),
    accentDark  = Color(0, 100, 150),
    danger      = Color(255, 60, 60),
    dangerDark  = Color(150, 30, 30),
    success     = Color(60, 255, 120),
    successDark = Color(30, 150, 60),
    warning     = Color(255, 180, 40),
    text        = Color(220, 230, 240),
    textDim     = Color(120, 140, 160),
    textDark    = Color(60, 70, 90),
}

-- ============================================================
-- GENERADOR DE NÚMEROS ALEATORIOS DETERMINISTA
-- ============================================================
function IVO_BOMBS.CreateRNG(seed)
    local state = (seed or os.time()) % 2147483646 + 1  -- state must be 1..2147483646
    return function(min, max)
        -- Park-Miller MINSTD: 16807 * state stays within Lua double precision (< 2^53)
        state = (state * 16807) % 2147483647
        if min and max then
            return min + (state % (max - min + 1))
        end
        return state / 2147483647
    end
end

-- ============================================================
-- COLORES DE CABLES
-- ============================================================
IVO_BOMBS.WireColors = {
    { name = "Rojo",     color = Color(220, 40, 40) },
    { name = "Azul",     color = Color(40, 100, 220) },
    { name = "Amarillo", color = Color(220, 200, 40) },
    { name = "Verde",    color = Color(40, 180, 60) },
    { name = "Blanco",   color = Color(220, 220, 220) },
    { name = "Negro",    color = Color(50, 50, 50) },
}

-- ============================================================
-- COLORES DE INDICADORES (MÓDULO CÓDIGO)
-- ============================================================
IVO_BOMBS.IndicatorColors = {
    { name = "Rojo",     color = Color(220, 40, 40),   digit = 1 },
    { name = "Azul",     color = Color(40, 100, 220),  digit = 2 },
    { name = "Verde",    color = Color(40, 180, 60),   digit = 3 },
    { name = "Amarillo", color = Color(220, 200, 40),  digit = 4 },
    { name = "Blanco",   color = Color(220, 220, 220), digit = 5 },
    { name = "Morado",   color = Color(160, 50, 200),  digit = 6 },
}

-- ============================================================
-- COLORES DE MEMORIA (MÓDULO SIMON)
-- ============================================================
IVO_BOMBS.MemoryColors = {
    { name = "Rojo",     color = Color(220, 40, 40),   colorDim = Color(110, 20, 20) },
    { name = "Azul",     color = Color(40, 100, 255),  colorDim = Color(20, 50, 130) },
    { name = "Verde",    color = Color(40, 220, 60),   colorDim = Color(20, 110, 30) },
    { name = "Amarillo", color = Color(220, 200, 40),  colorDim = Color(110, 100, 20) },
}
