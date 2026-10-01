--[[
    ivo_bombs - Módulo: Código Numérico
    
    Muestra indicadores de colores. Cada color tiene un dígito asignado.
    El jugador debe calcular el código correcto e ingresarlo en el teclado.
    
    Colores → Dígitos:
      Rojo = 1, Azul = 2, Verde = 3, Amarillo = 4, Blanco = 5, Morado = 6
    
    Reglas por dificultad:
    
    FÁCIL (3 indicadores → código de 3 dígitos):
      El código son los dígitos de los colores en orden.
      Ej: Verde, Rojo, Azul → 312
    
    NORMAL (4 indicadores → código de 3 dígitos):
      Sumar el primer y último dígito (mod 10).
      Código = (suma mod 10), 2do dígito, 3er dígito
      Ej: Azul(2), Verde(3), Rojo(1), Amarillo(4) → (2+4)%10=6 → 631
    
    DIFÍCIL (4 indicadores → código de 4 dígitos):
      Invertir el orden de los dígitos.
      Ej: Rojo(1), Blanco(5), Azul(2), Verde(3) → 3251
    
    EXTREMO (5 indicadores → código de 4 dígitos):
      Multiplicar pares consecutivos y tomar último dígito:
      d1*d2, d2*d3, d3*d4, d4*d5 (cada resultado mod 10)
      Ej: Morado(6), Rojo(1), Verde(3), Azul(2), Amarillo(4) → 6,3,6,8 → 6368
]]

if not CLIENT then return end

IVO_BOMBS.Modules = IVO_BOMBS.Modules or {}

surface.CreateFont("KeypadButton", {
    font = "Roboto Mono", size = 22, weight = 800, antialias = true,
})
surface.CreateFont("KeypadDisplay", {
    font = "Roboto Mono", size = 28, weight = 800, antialias = true,
})
surface.CreateFont("KeypadLabel", {
    font = "Roboto", size = 12, weight = 600, antialias = true,
})
surface.CreateFont("KeypadStatus", {
    font = "Roboto", size = 14, weight = 700, antialias = true,
})

local MODULE = {}
MODULE.Name = "Código"
MODULE.Icon = "🔢"

local function CalculateCode(indicators, difficulty)
    local digits = {}
    for _, ind in ipairs(indicators) do
        table.insert(digits, ind.digit)
    end

    if difficulty == 1 then
        -- Fácil: dígitos en orden
        local code = ""
        for i = 1, math.min(3, #digits) do
            code = code .. tostring(digits[i])
        end
        return code

    elseif difficulty == 2 then
        -- Normal: (primero + último) mod 10, luego 2do y 3ro
        local sum = (digits[1] + digits[#digits]) % 10
        return tostring(sum) .. tostring(digits[2]) .. tostring(digits[3])

    elseif difficulty == 3 then
        -- Difícil: invertir
        local code = ""
        for i = #digits, 1, -1 do
            code = code .. tostring(digits[i])
        end
        return code

    elseif difficulty == 4 then
        -- Extremo: multiplicar pares consecutivos mod 10
        local code = ""
        for i = 1, #digits - 1 do
            code = code .. tostring((digits[i] * digits[i + 1]) % 10)
        end
        return code
    end

    return "000"
end

function MODULE.Create(parent, w, h, difficulty, rng, onComplete, onStrike)
    local config = IVO_BOMBS.Difficulties[difficulty]
    local numIndicators = config and config.codeIndicators or 3
    local codeLength    = config and config.codeDigits or 3
    local indicatorColors = IVO_BOMBS.IndicatorColors

    local panel = vgui.Create("DPanel", parent)
    panel:SetPos(0, 0)
    panel:SetSize(w, h)

    -- Generar indicadores aleatorios
    local indicators = {}
    for i = 1, numIndicators do
        local idx = rng(1, #indicatorColors)
        table.insert(indicators, indicatorColors[idx])
    end

    local correctCode = CalculateCode(indicators, difficulty)
    panel.indicators = indicators
    panel.correctCode = correctCode
    panel.currentInput = ""
    panel.maxLength = #correctCode
    panel.solved = false
    panel.wrongFlash = 0
    panel.attempts = 0

    -- Layout
    local indicatorY = 8
    local indicatorSize = 18
    local indicatorGap = 6
    local totalIndW = numIndicators * (indicatorSize + indicatorGap) - indicatorGap
    local indStartX = (w - totalIndW) / 2

    -- Display
    local displayY = indicatorY + indicatorSize + 15
    local displayW = math.min(180, w - 40)
    local displayH = 36
    local displayX = (w - displayW) / 2

    -- Keypad
    local btnSize = math.min(42, (w - 60) / 5)
    local btnGap = 4
    local keypadW = 5 * (btnSize + btnGap) - btnGap
    local keypadX = (w - keypadW) / 2
    local keypadY = displayY + displayH + 12

    panel.Paint = function(self, pw, ph)
        draw.RoundedBox(4, 0, 0, pw, ph, Color(12, 16, 28))

        -- Indicadores de color
        for i, ind in ipairs(self.indicators) do
            local ix = indStartX + (i - 1) * (indicatorSize + indicatorGap)
            local iy = indicatorY

            -- Circulo del indicador
            draw.RoundedBox(indicatorSize / 2, ix, iy, indicatorSize, indicatorSize, ind.color)

            -- Brillo
            draw.RoundedBox(indicatorSize / 2, ix + 3, iy + 2, indicatorSize - 6, indicatorSize / 3,
                Color(255, 255, 255, 40))

            -- Dígito debajo
            draw.SimpleText(tostring(ind.digit), "KeypadLabel", ix + indicatorSize / 2, iy + indicatorSize + 4,
                Color(ind.color.r, ind.color.g, ind.color.b, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end

        -- Nombre de colores
        local colorNames = ""
        for i, ind in ipairs(self.indicators) do
            colorNames = colorNames .. ind.name
            if i < #self.indicators then colorNames = colorNames .. " → " end
        end
        draw.SimpleText(colorNames, "KeypadLabel", pw / 2, indicatorY + indicatorSize + 18,
            IVO_BOMBS.Colors.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Display de entrada
        local flashCol = self.wrongFlash > CurTime() and Color(80, 20, 20) or Color(8, 12, 20)
        draw.RoundedBox(4, displayX, displayY, displayW, displayH, flashCol)
        surface.SetDrawColor(self.wrongFlash > CurTime() and IVO_BOMBS.Colors.danger or IVO_BOMBS.Colors.border)
        surface.DrawOutlinedRect(displayX, displayY, displayW, displayH, 1)

        -- Texto del display
        local displayText = self.currentInput
        -- Agregar underscores para dígitos faltantes
        while #displayText < self.maxLength do
            displayText = displayText .. "_"
        end

        local displayCol = self.solved and IVO_BOMBS.Colors.success
            or (self.wrongFlash > CurTime() and IVO_BOMBS.Colors.danger or IVO_BOMBS.Colors.accent)
        draw.SimpleText(displayText, "KeypadDisplay", displayX + displayW / 2, displayY + displayH / 2,
            displayCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Estado
        local statusY = keypadY + 2 * (btnSize + btnGap) + btnSize + 8
        if self.solved then
            draw.SimpleText("✓ Código correcto", "KeypadStatus", pw/2, statusY,
                IVO_BOMBS.Colors.success, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif self.attempts > 0 then
            draw.SimpleText("Intentos fallidos: " .. self.attempts, "KeypadStatus", pw/2, statusY,
                IVO_BOMBS.Colors.danger, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    -- Crear botones del teclado numérico
    -- Fila 1: 1-5, Fila 2: 6-0, Fila 3: Borrar, Enviar
    local keyLayout = {
        { "1", "2", "3", "4", "5" },
        { "6", "7", "8", "9", "0" },
    }

    for row, keys in ipairs(keyLayout) do
        for col, key in ipairs(keys) do
            local bx = keypadX + (col - 1) * (btnSize + btnGap)
            local by = keypadY + (row - 1) * (btnSize + btnGap)

            local btn = vgui.Create("DButton", panel)
            btn:SetPos(bx, by)
            btn:SetSize(btnSize, btnSize)
            btn:SetText("")

            btn.Paint = function(self2, bw, bh)
                local hovered = self2:IsHovered()
                local bgCol = hovered and Color(40, 50, 70) or Color(25, 30, 45)
                draw.RoundedBox(6, 0, 0, bw, bh, bgCol)
                surface.SetDrawColor(hovered and IVO_BOMBS.Colors.accent or IVO_BOMBS.Colors.border)
                surface.DrawOutlinedRect(0, 0, bw, bh, 1)
                draw.SimpleText(key, "KeypadButton", bw/2, bh/2,
                    hovered and Color(255, 255, 255) or Color(180, 190, 200),
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            btn.DoClick = function()
                if panel.solved then return end
                if #panel.currentInput >= panel.maxLength then return end

                panel.currentInput = panel.currentInput .. key
                surface.PlaySound("buttons/lightswitch2.wav")

                -- Auto-submit cuando se completa
                if #panel.currentInput >= panel.maxLength then
                    timer.Simple(0.3, function()
                        if not IsValid(panel) or panel.solved then return end

                        if panel.currentInput == panel.correctCode then
                            panel.solved = true
                            surface.PlaySound("buttons/button9.wav")
                            timer.Simple(0.5, function()
                                if onComplete then onComplete() end
                            end)
                        else
                            panel.wrongFlash = CurTime() + 0.6
                            panel.currentInput = ""
                            panel.attempts = panel.attempts + 1
                            surface.PlaySound("buttons/button10.wav")

                            if onStrike then onStrike() end

                            -- Regenerar indicadores
                            timer.Simple(1, function()
                                if not IsValid(panel) or panel.solved then return end
                                local newInd = {}
                                for ix = 1, numIndicators do
                                    local idx = rng(1, #indicatorColors)
                                    table.insert(newInd, indicatorColors[idx])
                                end
                                panel.indicators = newInd
                                panel.correctCode = CalculateCode(newInd, difficulty)
                                panel.maxLength = #panel.correctCode
                            end)
                        end
                    end)
                end
            end
        end
    end

    -- Botón borrar
    local clearBtnW = 2 * btnSize + btnGap
    local clearBtn = vgui.Create("DButton", panel)
    clearBtn:SetPos(keypadX, keypadY + 2 * (btnSize + btnGap))
    clearBtn:SetSize(clearBtnW, btnSize)
    clearBtn:SetText("")

    clearBtn.Paint = function(self2, bw, bh)
        local hovered = self2:IsHovered()
        draw.RoundedBox(6, 0, 0, bw, bh, hovered and Color(80, 40, 40) or Color(50, 25, 25))
        surface.SetDrawColor(hovered and IVO_BOMBS.Colors.danger or Color(100, 50, 50))
        surface.DrawOutlinedRect(0, 0, bw, bh, 1)
        draw.SimpleText("BORRAR", "KeypadLabel", bw/2, bh/2,
            Color(255, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    clearBtn.DoClick = function()
        if panel.solved then return end
        panel.currentInput = ""
        surface.PlaySound("buttons/combine_button1.wav")
    end

    return panel
end

IVO_BOMBS.Modules["keypad"] = MODULE
