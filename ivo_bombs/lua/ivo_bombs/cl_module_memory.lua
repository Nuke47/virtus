--[[
    ivo_bombs - Módulo: Secuencia de Memoria (Simon Says)
    
    4 botones de colores (Rojo, Azul, Verde, Amarillo)
    Se muestra una secuencia de flashes que el jugador debe repetir.
    
    Por dificultad:
      Fácil:   3 rondas, secuencia inicial de 3
      Normal:  3 rondas, secuencia inicial de 4
      Difícil: 4 rondas, secuencia inicial de 4
      Extremo: 4 rondas, secuencia inicial de 5
    
    Cada ronda agrega 1 flash. Error = strike + se repite la secuencia.
    Completar todas las rondas = módulo resuelto.
]]

if not CLIENT then return end

IVO_BOMBS.Modules = IVO_BOMBS.Modules or {}

surface.CreateFont("MemoryModuleInfo", {
    font = "Roboto", size = 14, weight = 600, antialias = true,
})
surface.CreateFont("MemoryModuleStatus", {
    font = "Roboto", size = 16, weight = 700, antialias = true,
})

local MODULE = {}
MODULE.Name = "Memoria"
MODULE.Icon = "🧠"

function MODULE.Create(parent, w, h, difficulty, rng, onComplete, onStrike)
    local config = IVO_BOMBS.Difficulties[difficulty]
    local totalRounds  = config and config.memoryRounds   or 3
    local startLen     = config and config.memoryStartLen  or 3
    local memColors    = IVO_BOMBS.MemoryColors

    local panel = vgui.Create("DPanel", parent)
    panel:SetPos(0, 0)
    panel:SetSize(w, h)

    -- Estado
    panel.sequence = {}
    panel.currentRound = 1
    panel.inputIndex = 1
    panel.phase = "generating" -- generating, showing, input, correct, wrong, solved
    panel.showIndex = 0
    panel.showTimer = 0
    panel.flashDuration = 0.5
    panel.pauseDuration = 0.25
    panel.solved = false
    panel.buttons = {}
    panel.activeButton = nil
    panel.roundsTotal = totalRounds

    -- Generar secuencia inicial
    local function GenerateSequence(length)
        local seq = {}
        for i = 1, length do
            seq[i] = rng(1, 4)
        end
        return seq
    end

    -- Agregar un elemento a la secuencia
    local function ExtendSequence()
        table.insert(panel.sequence, rng(1, 4))
    end

    -- Iniciar ronda
    local function StartRound()
        if panel.currentRound == 1 then
            panel.sequence = GenerateSequence(startLen)
        else
            ExtendSequence()
        end
        panel.phase = "showing"
        panel.showIndex = 0
        panel.showTimer = CurTime() + 0.8 -- pausa antes de mostrar
        panel.inputIndex = 1
        panel.activeButton = nil
    end

    -- Layout de botones 2x2
    local btnSize = math.min(w / 2 - 20, (h - 60) / 2 - 10)
    local btnGap = 8
    local gridW = btnSize * 2 + btnGap
    local gridH = btnSize * 2 + btnGap
    local gridX = (w - gridW) / 2
    local gridY = 35

    -- Colores de botones
    local btnPositions = {
        { x = gridX,                y = gridY,                col = memColors[1] }, -- TL = Rojo
        { x = gridX + btnSize + btnGap, y = gridY,                col = memColors[2] }, -- TR = Azul
        { x = gridX,                y = gridY + btnSize + btnGap, col = memColors[3] }, -- BL = Verde
        { x = gridX + btnSize + btnGap, y = gridY + btnSize + btnGap, col = memColors[4] }, -- BR = Amarillo
    }

    -- Crear botones
    for i, pos in ipairs(btnPositions) do
        local btn = vgui.Create("DButton", panel)
        btn:SetPos(pos.x, pos.y)
        btn:SetSize(btnSize, btnSize)
        btn:SetText("")
        btn.colorData = pos.col
        btn.btnIndex = i
        btn.isLit = false
        btn.clickFlash = 0

        btn.Paint = function(self, bw, bh)
            local lit = self.isLit or self.clickFlash > CurTime()
            local baseCol = lit and self.colorData.color or self.colorData.colorDim

            -- Fondo del botón
            draw.RoundedBox(8, 0, 0, bw, bh, baseCol)

            -- Borde
            local borderCol = lit and Color(255, 255, 255, 80) or Color(20, 20, 20, 100)
            surface.SetDrawColor(borderCol)
            surface.DrawOutlinedRect(0, 0, bw, bh, 2)

            -- Brillo cuando encendido
            if lit then
                draw.RoundedBox(6, 4, 4, bw - 8, bh / 3,
                    Color(255, 255, 255, 40))
            end

            -- Hover
            if self:IsHovered() and panel.phase == "input" and not panel.solved then
                surface.SetDrawColor(255, 255, 255, 30)
                surface.DrawRect(0, 0, bw, bh)
            end
        end

        btn.DoClick = function(self)
            if panel.phase ~= "input" or panel.solved then return end

            self.clickFlash = CurTime() + 0.2
            surface.PlaySound("buttons/lightswitch2.wav")

            local expected = panel.sequence[panel.inputIndex]

            if self.btnIndex == expected then
                -- Correcto
                panel.inputIndex = panel.inputIndex + 1

                if panel.inputIndex > #panel.sequence then
                    -- Ronda completada
                    panel.currentRound = panel.currentRound + 1

                    if panel.currentRound > panel.roundsTotal then
                        -- ¡Módulo completado!
                        panel.solved = true
                        panel.phase = "solved"
                        timer.Simple(0.5, function()
                            if onComplete then onComplete() end
                        end)
                    else
                        -- Siguiente ronda
                        panel.phase = "correct"
                        timer.Simple(1, function()
                            if IsValid(panel) and not panel.solved then
                                StartRound()
                            end
                        end)
                    end
                end
            else
                -- Incorrecto - strike
                panel.phase = "wrong"
                if onStrike then onStrike() end

                -- Repetir la secuencia después de un delay
                timer.Simple(1.2, function()
                    if IsValid(panel) and not panel.solved then
                        panel.phase = "showing"
                        panel.showIndex = 0
                        panel.showTimer = CurTime() + 0.5
                        panel.inputIndex = 1
                        panel.activeButton = nil
                    end
                end)
            end
        end

        panel.buttons[i] = btn
    end

    -- Think: manejar la secuencia de display
    panel.Think = function(self)
        -- Apagar todos los botones
        for _, btn in ipairs(self.buttons) do
            btn.isLit = false
        end

        if self.phase == "showing" and CurTime() >= self.showTimer then
            if self.showIndex < #self.sequence then
                -- Calcular qué botón está encendido
                local elapsed = CurTime() - self.showTimer
                local stepTime = self.flashDuration + self.pauseDuration
                local currentStep = math.floor(elapsed / stepTime) + 1

                if currentStep > #self.sequence then
                    -- Fin de la secuencia → pasar a input
                    self.phase = "input"
                    self.inputIndex = 1
                else
                    local withinStep = elapsed - (currentStep - 1) * stepTime
                    if withinStep < self.flashDuration then
                        local btnIdx = self.sequence[currentStep]
                        if self.buttons[btnIdx] then
                            self.buttons[btnIdx].isLit = true
                        end
                    end
                    self.showIndex = currentStep
                end
            else
                self.phase = "input"
                self.inputIndex = 1
            end
        end
    end

    -- Pintar info
    panel.Paint = function(self, pw, ph)
        draw.RoundedBox(4, 0, 0, pw, ph, Color(12, 16, 28))

        -- Info de ronda
        local roundText = "Ronda " .. math.min(self.currentRound, self.roundsTotal) .. "/" .. self.roundsTotal
        draw.SimpleText(roundText, "MemoryModuleInfo", pw/2, 12,
            IVO_BOMBS.Colors.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Estado
        local statusY = gridY + gridH + 12
        if self.phase == "showing" then
            local dots = string.rep(".", math.floor(CurTime() * 3) % 4)
            draw.SimpleText("Observa la secuencia" .. dots, "MemoryModuleStatus",
                pw/2, statusY, IVO_BOMBS.Colors.warning, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif self.phase == "input" then
            draw.SimpleText("Repite la secuencia (" .. (self.inputIndex - 1) .. "/" .. #self.sequence .. ")",
                "MemoryModuleStatus", pw/2, statusY, IVO_BOMBS.Colors.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif self.phase == "correct" then
            draw.SimpleText("¡Correcto! Siguiente ronda...", "MemoryModuleStatus",
                pw/2, statusY, IVO_BOMBS.Colors.success, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif self.phase == "wrong" then
            draw.SimpleText("✗ Error - Repitiendo secuencia...", "MemoryModuleStatus",
                pw/2, statusY, IVO_BOMBS.Colors.danger, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif self.phase == "solved" then
            draw.SimpleText("✓ Completado", "MemoryModuleStatus",
                pw/2, statusY, IVO_BOMBS.Colors.success, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Secuencia visual (puntos)
        if self.phase == "input" then
            local dotSize = 8
            local dotGap = 4
            local totalDotsW = #self.sequence * (dotSize + dotGap) - dotGap
            local dotStartX = pw/2 - totalDotsW/2

            for i = 1, #self.sequence do
                local dx = dotStartX + (i - 1) * (dotSize + dotGap)
                local dy = statusY + 18
                local col = i < self.inputIndex and IVO_BOMBS.Colors.success
                          or (i == self.inputIndex and IVO_BOMBS.Colors.accent or Color(50, 50, 50))
                draw.RoundedBox(dotSize/2, dx, dy, dotSize, dotSize, col)
            end
        end
    end

    -- Iniciar primera ronda
    StartRound()

    return panel
end

IVO_BOMBS.Modules["memory"] = MODULE
