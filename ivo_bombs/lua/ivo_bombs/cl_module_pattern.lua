--[[
    ivo_bombs - Módulo: Patrón de Memoria (Pattern Grid)
    
    Se muestra un patrón de celdas iluminadas en una grilla que el jugador
    debe memorizar y recrear.
    
    Por dificultad:
      Fácil:   grilla 5x5,  4 celdas, mostrar 4.0s
      Normal:  grilla 5x5,  6 celdas, mostrar 3.0s
      Difícil: grilla 6x6,  8 celdas, mostrar 2.5s
      Extremo: grilla 6x6, 10 celdas, mostrar 2.0s
    
    Fases:
      1. "showing" - El patrón se muestra brevemente
      2. "input"   - El jugador marca celdas
      3. "verify"  - El jugador presiona Verificar
      
    Error = strike + el patrón se muestra de nuevo (1s menos, mínimo 1s)
    Correcto = módulo resuelto
]]

if not CLIENT then return end

IVO_BOMBS.Modules = IVO_BOMBS.Modules or {}

surface.CreateFont("PatternStatus", {
    font = "Roboto", size = 14, weight = 700, antialias = true,
})
surface.CreateFont("PatternBtn", {
    font = "Roboto", size = 13, weight = 700, antialias = true,
})
surface.CreateFont("PatternCounter", {
    font = "Roboto", size = 12, weight = 600, antialias = true,
})

local MODULE = {}
MODULE.Name = "Patrón"
MODULE.Icon = "🔲"

function MODULE.Create(parent, w, h, difficulty, rng, onComplete, onStrike)
    local config = IVO_BOMBS.Difficulties[difficulty]
    local gridSize    = config and config.patternGrid     or 5
    local numCells    = config and config.patternCells     or 4
    local showTime    = config and config.patternShowTime  or 4

    local panel = vgui.Create("DPanel", parent)
    panel:SetPos(0, 0)
    panel:SetSize(w, h)

    -- Estado
    panel.gridSize = gridSize
    panel.targetCells = {} -- {[row_col] = true}
    panel.playerCells = {} -- {[row_col] = true}
    panel.phase = "showing" -- showing, input, solved
    panel.showEndTime = 0
    panel.currentShowTime = showTime
    panel.solved = false
    panel.attempts = 0

    -- Generar patrón
    local function GeneratePattern()
        panel.targetCells = {}
        local positions = {}
        for r = 1, gridSize do
            for c = 1, gridSize do
                table.insert(positions, r .. "_" .. c)
            end
        end

        -- Seleccionar celdas aleatorias
        for i = 1, numCells do
            if #positions == 0 then break end
            local idx = rng(1, #positions)
            panel.targetCells[positions[idx]] = true
            table.remove(positions, idx)
        end

        panel.playerCells = {}
    end

    local function StartShowing()
        panel.phase = "showing"
        panel.showEndTime = CurTime() + panel.currentShowTime
        panel.playerCells = {}
    end

    local function VerifyPattern()
        -- Comparar playerCells con targetCells
        local correct = true

        -- Verificar que todas las target están marcadas
        for key, _ in pairs(panel.targetCells) do
            if not panel.playerCells[key] then
                correct = false
                break
            end
        end

        -- Verificar que no hay celdas extra
        if correct then
            for key, _ in pairs(panel.playerCells) do
                if not panel.targetCells[key] then
                    correct = false
                    break
                end
            end
        end

        if correct then
            panel.solved = true
            panel.phase = "solved"
            timer.Simple(0.5, function()
                if onComplete then onComplete() end
            end)
        else
            panel.attempts = panel.attempts + 1
            if onStrike then onStrike() end

            -- Reducir tiempo de display
            panel.currentShowTime = math.max(1, panel.currentShowTime - 0.5)

            -- Regenerar patrón y mostrar de nuevo
            timer.Simple(0.8, function()
                if not IsValid(panel) or panel.solved then return end
                GeneratePattern()
                StartShowing()
            end)
        end
    end

    -- Layout de la grilla
    local cellSize = math.min(
        math.floor((w - 30) / gridSize),
        math.floor((h - 75) / gridSize)
    )
    cellSize = math.min(cellSize, 42)
    local cellGap = 2
    local gridW = gridSize * (cellSize + cellGap) - cellGap
    local gridH = gridSize * (cellSize + cellGap) - cellGap
    local gridX = (w - gridW) / 2
    local gridY = 28

    -- Crear botones de celda
    panel.cellButtons = {}
    for r = 1, gridSize do
        for c = 1, gridSize do
            local key = r .. "_" .. c
            local bx = gridX + (c - 1) * (cellSize + cellGap)
            local by = gridY + (r - 1) * (cellSize + cellGap)

            local btn = vgui.Create("DButton", panel)
            btn:SetPos(bx, by)
            btn:SetSize(cellSize, cellSize)
            btn:SetText("")
            btn.cellKey = key

            btn.Paint = function(self2, bw, bh)
                local isTarget = panel.targetCells[key]
                local isPlayerSelected = panel.playerCells[key]
                local isShowing = panel.phase == "showing"
                local isSolved = panel.phase == "solved"

                local bgCol

                if isSolved then
                    if isTarget then
                        bgCol = Color(40, 180, 80)
                    else
                        bgCol = Color(20, 28, 45)
                    end
                elseif isShowing then
                    if isTarget then
                        -- Celda target iluminada
                        local pulse = math.abs(math.sin(CurTime() * 4))
                        bgCol = Color(0, 180 + pulse * 75, 255, 255)
                    else
                        bgCol = Color(20, 28, 45)
                    end
                else
                    -- Fase de input
                    if isPlayerSelected then
                        bgCol = Color(0, 160, 220)
                    elseif self2:IsHovered() then
                        bgCol = Color(35, 45, 65)
                    else
                        bgCol = Color(20, 28, 45)
                    end
                end

                draw.RoundedBox(4, 0, 0, bw, bh, bgCol)

                -- Borde
                local borCol = (isShowing and isTarget) and Color(0, 220, 255, 150)
                    or isPlayerSelected and Color(0, 180, 255, 150)
                    or Color(35, 45, 60)
                surface.SetDrawColor(borCol)
                surface.DrawOutlinedRect(0, 0, bw, bh, 1)

                -- Brillo en celdas activas
                if (isShowing and isTarget) or isPlayerSelected then
                    draw.RoundedBox(2, 2, 2, bw - 4, bh / 3, Color(255, 255, 255, 30))
                end
            end

            btn.DoClick = function()
                if panel.phase ~= "input" or panel.solved then return end

                if panel.playerCells[key] then
                    panel.playerCells[key] = nil
                    surface.PlaySound("buttons/lightswitch2.wav")
                else
                    panel.playerCells[key] = true
                    surface.PlaySound("buttons/lightswitch2.wav")
                end
            end

            panel.cellButtons[key] = btn
        end
    end

    -- Botón de verificar
    local verifyBtnW = math.min(120, w - 40)
    local verifyBtnH = 28
    local verifyBtnX = (w - verifyBtnW) / 2
    local verifyBtnY = gridY + gridH + 8

    local verifyBtn = vgui.Create("DButton", panel)
    verifyBtn:SetPos(verifyBtnX, verifyBtnY)
    verifyBtn:SetSize(verifyBtnW, verifyBtnH)
    verifyBtn:SetText("")

    verifyBtn.Paint = function(self2, bw, bh)
        if panel.phase ~= "input" then
            draw.RoundedBox(6, 0, 0, bw, bh, Color(30, 35, 50, 100))
            draw.SimpleText("VERIFICAR", "PatternBtn", bw/2, bh/2,
                Color(80, 80, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end

        local hovered = self2:IsHovered()
        local bgCol = hovered and Color(0, 140, 200) or Color(0, 100, 160)
        draw.RoundedBox(6, 0, 0, bw, bh, bgCol)
        surface.SetDrawColor(hovered and Color(0, 200, 255) or Color(0, 150, 200))
        surface.DrawOutlinedRect(0, 0, bw, bh, 1)
        draw.SimpleText("VERIFICAR", "PatternBtn", bw/2, bh/2,
            Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    verifyBtn.DoClick = function()
        if panel.phase ~= "input" or panel.solved then return end
        VerifyPattern()
    end

    -- Botón limpiar
    local clearBtnW = math.min(90, w / 3)
    local clearBtn = vgui.Create("DButton", panel)
    clearBtn:SetPos(verifyBtnX + verifyBtnW + 5, verifyBtnY)
    clearBtn:SetSize(clearBtnW, verifyBtnH)
    clearBtn:SetText("")

    clearBtn.Paint = function(self2, bw, bh)
        if panel.phase ~= "input" then
            draw.RoundedBox(6, 0, 0, bw, bh, Color(30, 30, 30, 100))
            draw.SimpleText("LIMPIAR", "PatternBtn", bw/2, bh/2,
                Color(80, 80, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end

        local hovered = self2:IsHovered()
        draw.RoundedBox(6, 0, 0, bw, bh, hovered and Color(80, 40, 40) or Color(50, 30, 30))
        draw.SimpleText("LIMPIAR", "PatternBtn", bw/2, bh/2,
            Color(255, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    clearBtn.DoClick = function()
        if panel.phase ~= "input" or panel.solved then return end
        panel.playerCells = {}
    end

    -- Think: manejar transiciones
    panel.Think = function(self)
        if self.phase == "showing" and CurTime() >= self.showEndTime then
            self.phase = "input"
        end
    end

    -- Pintar
    panel.Paint = function(self, pw, ph)
        draw.RoundedBox(4, 0, 0, pw, ph, Color(12, 16, 28))

        -- Info superior
        if self.phase == "showing" then
            local remaining = math.max(0, self.showEndTime - CurTime())
            local barW = (remaining / self.currentShowTime) * (pw - 20)
            draw.RoundedBox(3, 10, 5, pw - 20, 8, Color(20, 25, 40))
            draw.RoundedBox(3, 10, 5, barW, 8, IVO_BOMBS.Colors.accent)

            draw.SimpleText("Memoriza el patrón", "PatternStatus", pw/2, 18,
                IVO_BOMBS.Colors.warning, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif self.phase == "input" then
            -- Contar celdas seleccionadas
            local count = 0
            for _ in pairs(self.playerCells) do count = count + 1 end

            draw.SimpleText("Marca " .. numCells .. " celdas (" .. count .. "/" .. numCells .. ")",
                "PatternStatus", pw/2, 12, IVO_BOMBS.Colors.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif self.phase == "solved" then
            draw.SimpleText("✓ Patrón correcto", "PatternStatus", pw/2, 12,
                IVO_BOMBS.Colors.success, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Intentos
        if self.attempts > 0 and not self.solved then
            draw.SimpleText("Errores: " .. self.attempts, "PatternCounter",
                pw - 10, ph - 10, IVO_BOMBS.Colors.danger, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        end
    end

    -- Generar e iniciar
    GeneratePattern()
    StartShowing()

    return panel
end

IVO_BOMBS.Modules["pattern"] = MODULE
