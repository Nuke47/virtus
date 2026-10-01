--[[
    ivo_bombs - Panel de Desactivación (Client)
    VGUI principal que muestra los módulos del minijuego
]]

if not CLIENT then return end

-- Fuentes del panel
surface.CreateFont("DefusePanelTitle", {
    font = "Roboto", size = 26, weight = 800, antialias = true,
})
surface.CreateFont("DefusePanelTimer", {
    font = "Roboto Mono", size = 38, weight = 800, antialias = true,
})
surface.CreateFont("DefusePanelInfo", {
    font = "Roboto", size = 16, weight = 600, antialias = true,
})
surface.CreateFont("DefusePanelStrike", {
    font = "Roboto", size = 24, weight = 800, antialias = true,
})
surface.CreateFont("DefuseModuleTitle", {
    font = "Roboto", size = 18, weight = 700, antialias = true,
})
surface.CreateFont("DefuseModuleSolved", {
    font = "Roboto", size = 32, weight = 800, antialias = true,
})
surface.CreateFont("DefuseResultTitle", {
    font = "Roboto", size = 48, weight = 900, antialias = true,
})
surface.CreateFont("DefuseResultSub", {
    font = "Roboto", size = 20, weight = 600, antialias = true,
})

local C = IVO_BOMBS.Colors

-- Panel activo
local activePanel = nil

-- ============================================================
-- Abrir panel de desactivación
-- ============================================================
function IVO_BOMBS.OpenDefusePanel(bomb, difficulty, seed)
    if IsValid(activePanel) then activePanel:Remove() end

    local config = IVO_BOMBS.Difficulties[difficulty]
    if not config then return end

    local scrW, scrH = ScrW(), ScrH()
    local panelW = math.min(1100, scrW - 40)
    local panelH = math.min(700, scrH - 40)

    -- Frame principal
    local frame = vgui.Create("DFrame")
    frame:SetSize(panelW, panelH)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)
    activePanel = frame

    -- Variables de estado
    frame.bomb = bomb
    frame.difficulty = difficulty
    frame.seed = seed
    frame.config = config
    frame.modulesSolved = 0
    frame.totalModules = config.modules
    frame.strikes = 0
    frame.maxStrikes = config.maxStrikes
    frame.finished = false
    frame.startTime = CurTime()

    -- Seleccionar módulos aleatorios
    local rng = IVO_BOMBS.CreateRNG(seed)
    local available = table.Copy(IVO_BOMBS.ModuleList)
    frame.selectedModules = {}
    for i = 1, config.modules do
        local idx = rng(1, #available)
        table.insert(frame.selectedModules, available[idx])
        table.remove(available, idx)
        if #available == 0 then
            available = table.Copy(IVO_BOMBS.ModuleList)
        end
    end

    frame.modulePanels = {}
    frame.moduleSolved = {}

    -- Pintar fondo
    frame.Paint = function(self, w, h)
        -- Fondo con gradiente
        draw.RoundedBox(10, 0, 0, w, h, C.bg)
        draw.RoundedBox(8, 2, 2, w-4, h-4, C.panel)

        -- Borde exterior
        surface.SetDrawColor(C.border)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        -- Header bar
        local headerH = 60
        draw.RoundedBoxEx(8, 2, 2, w-4, headerH, C.panelDark, true, true, false, false)

        -- Línea bajo header
        surface.SetDrawColor(C.border)
        surface.DrawRect(2, headerH + 2, w-4, 1)

        -- Título
        draw.SimpleText("SISTEMA DE DESACTIVACIÓN", "DefusePanelTitle", 20, headerH/2,
            C.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Dificultad
        local diffText = "[ " .. config.name .. " ]"
        draw.SimpleText(diffText, "DefusePanelInfo", 330, headerH/2,
            config.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Timer de la bomba
        if IsValid(self.bomb) then
            local timeLeft = math.max(0, self.bomb:GetDetonateTime() - CurTime())
            local mins = math.floor(timeLeft / 60)
            local secs = math.floor(timeLeft % 60)
            local timerStr = string.format("%02d:%02d", mins, secs)

            local timerCol
            if timeLeft > 30 then timerCol = Color(255, 255, 255)
            elseif timeLeft > 15 then timerCol = Color(255, 230, 50)
            elseif timeLeft > 5 then timerCol = Color(255, 140, 30)
            else timerCol = Color(255, 50, 50, 200 + math.sin(CurTime()*10)*55) end

            draw.SimpleText(timerStr, "DefusePanelTimer", w/2, headerH/2,
                timerCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Strikes
        local strikeX = w - 20
        for i = self.maxStrikes, 1, -1 do
            local col = i <= self.strikes and C.danger or Color(60, 60, 60)
            local symbol = i <= self.strikes and "X" or "O"
            draw.SimpleText(symbol, "DefusePanelStrike", strikeX, headerH/2,
                col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            strikeX = strikeX - 30
        end

        draw.SimpleText("Strikes:", "DefusePanelInfo", strikeX - 5, headerH/2,
            C.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

        -- Módulos resueltos
        draw.SimpleText("Módulos: " .. self.modulesSolved .. "/" .. self.totalModules,
            "DefusePanelInfo", w - 20, headerH + 18, C.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    -- Crear módulos
    local headerH = 62
    local modAreaY = headerH + 30
    local modAreaH = panelH - modAreaY - 15
    local modAreaW = panelW - 30
    local padding = 10

    local cols = frame.totalModules <= 2 and 2 or 2
    local rows = math.ceil(frame.totalModules / cols)
    local cellW = math.floor((modAreaW - padding * (cols - 1)) / cols)
    local cellH = math.floor((modAreaH - padding * (rows - 1)) / rows)

    for i, modName in ipairs(frame.selectedModules) do
        local mod = IVO_BOMBS.Modules[modName]
        if not mod then continue end

        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        local mx = 15 + col * (cellW + padding)
        local my = modAreaY + row * (cellH + padding)

        -- Contenedor del módulo
        local container = vgui.Create("DPanel", frame)
        container:SetPos(mx, my)
        container:SetSize(cellW, cellH)
        container.modName = modName
        container.solved = false
        container.modIndex = i

        container.Paint = function(self2, w2, h2)
            -- Fondo del módulo
            local bgCol = self2.solved and Color(20, 60, 30, 220) or C.panelLight
            draw.RoundedBox(8, 0, 0, w2, h2, bgCol)

            -- Borde
            local borCol = self2.solved and C.successDark or C.border
            surface.SetDrawColor(borCol)
            surface.DrawOutlinedRect(0, 0, w2, h2, 1)

            -- Título del módulo
            local titleH = 30
            draw.RoundedBoxEx(6, 1, 1, w2-2, titleH, self2.solved and C.successDark or C.panelDark,
                true, true, false, false)

            local icon = mod.Icon or "?"
            local name = mod.Name or modName
            draw.SimpleText(icon .. " " .. name, "DefuseModuleTitle", 10, titleH/2,
                self2.solved and C.success or C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            if self2.solved then
                draw.SimpleText("✓", "DefuseModuleSolved",
                    w2 - 20, titleH/2, C.success, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            -- Línea bajo título
            surface.SetDrawColor(self2.solved and C.successDark or C.border)
            surface.DrawRect(1, titleH, w2-2, 1)
        end

        -- Área del contenido del módulo (debajo del título)
        local contentY = 32
        local contentH = cellH - contentY - 5

        local contentPanel = vgui.Create("DPanel", container)
        contentPanel:SetPos(3, contentY)
        contentPanel:SetSize(cellW - 6, contentH)
        contentPanel.Paint = function() end

        -- RNG único para este módulo
        local modRNG = IVO_BOMBS.CreateRNG(seed + i * 7919)

        -- Callbacks
        local function onComplete()
            if frame.finished then return end
            if container.solved then return end

            container.solved = true
            frame.moduleSolved[i] = true
            frame.modulesSolved = frame.modulesSolved + 1

            -- Notificar servidor
            net.Start("ivo_bombs_module_solved")
            net.SendToServer()

            -- Sonido de éxito
            surface.PlaySound("buttons/button9.wav")

            -- Comprobar si se completó todo
            if frame.modulesSolved >= frame.totalModules then
                frame.finished = true
                timer.Simple(0.5, function()
                    if IsValid(frame) then
                        IVO_BOMBS.ShowResult(frame, true)
                    end
                end)
            end
        end

        local function onStrike()
            if frame.finished then return end

            frame.strikes = frame.strikes + 1
            surface.PlaySound("buttons/button10.wav")

            -- Notificar servidor
            net.Start("ivo_bombs_strike")
            net.SendToServer()

            -- Flash rojo
            frame._strikeFlash = CurTime()

            -- ¿Demasiados strikes?
            if frame.strikes >= frame.maxStrikes then
                frame.finished = true
                timer.Simple(0.3, function()
                    if IsValid(frame) then
                        IVO_BOMBS.ShowResult(frame, false)
                    end
                end)
            end
        end

        -- Crear el minijuego del módulo
        mod.Create(contentPanel, cellW - 6, contentH, difficulty, modRNG, onComplete, onStrike)

        frame.modulePanels[i] = container
    end

    -- Botón de cerrar (esquina)
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetPos(panelW - 35, 5)
    closeBtn:SetSize(28, 28)
    closeBtn:SetText("")
    closeBtn.Paint = function(self2, w2, h2)
        local hovered = self2:IsHovered()
        draw.RoundedBox(6, 0, 0, w2, h2, hovered and C.danger or Color(60, 30, 30))
        draw.SimpleText("X", "DefuseModuleTitle", w2/2, h2/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function()
        IVO_BOMBS.CloseDefusePanel()
    end

    -- Think: verificar bomba válida y distancia
    frame.Think = function(self)
        if not IsValid(self.bomb) or not self.bomb:GetArmed() then
            if not self.finished then
                IVO_BOMBS.CloseDefusePanel()
            end
            return
        end

        local dist = LocalPlayer():GetPos():Distance(self.bomb:GetPos())
        if dist > 350 then
            IVO_BOMBS.CloseDefusePanel()
        end
    end
end

-- ============================================================
-- Mostrar resultado
-- ============================================================
function IVO_BOMBS.ShowResult(frame, success)
    if not IsValid(frame) then return end

    -- Overlay de resultado
    local overlay = vgui.Create("DPanel", frame)
    overlay:SetPos(0, 0)
    overlay:SetSize(frame:GetWide(), frame:GetTall())
    overlay:MoveToFront()

    local startTime = CurTime()

    overlay.Paint = function(self, w, h)
        local elapsed = CurTime() - startTime
        local alpha = math.Clamp(elapsed * 3 * 255, 0, 220)

        draw.RoundedBox(10, 0, 0, w, h, Color(0, 0, 0, alpha))

        if alpha > 100 then
            local textAlpha = math.Clamp((elapsed - 0.3) * 4 * 255, 0, 255)

            if success then
                draw.SimpleText("DESACTIVADA", "DefuseResultTitle", w/2, h/2 - 20,
                    Color(60, 255, 120, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("Bomba neutralizada exitosamente", "DefuseResultSub", w/2, h/2 + 30,
                    Color(180, 255, 200, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                local flash = math.abs(math.sin(CurTime() * 5))
                draw.SimpleText("FALLIDO", "DefuseResultTitle", w/2, h/2 - 20,
                    Color(255, 50 + flash * 30, 50, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("Demasiados errores", "DefuseResultSub", w/2, h/2 + 30,
                    Color(255, 180, 180, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end

    -- Cerrar automáticamente después de 3s
    timer.Simple(3, function()
        IVO_BOMBS.CloseDefusePanel()
    end)
end

-- ============================================================
-- Cerrar panel
-- ============================================================
function IVO_BOMBS.CloseDefusePanel()
    if IsValid(activePanel) then
        activePanel:Remove()
        activePanel = nil
    end

    net.Start("ivo_bombs_close_panel")
    net.SendToServer()
end

-- ============================================================
-- Recibir inicio de desactivación del servidor
-- ============================================================
net.Receive("ivo_bombs_start_defuse", function()
    local bomb  = net.ReadEntity()
    local diff  = net.ReadUInt(4)
    local seed  = net.ReadUInt(32)

    if not IsValid(bomb) then return end

    IVO_BOMBS.OpenDefusePanel(bomb, diff, seed)
end)

-- Recibir resultado forzado del servidor
net.Receive("ivo_bombs_defuse_result", function()
    local success = net.ReadBool()

    if IsValid(activePanel) and not activePanel.finished then
        activePanel.finished = true
        IVO_BOMBS.ShowResult(activePanel, success)
    else
        IVO_BOMBS.CloseDefusePanel()
    end
end)
