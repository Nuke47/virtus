--[[
    ivo_bombs - Módulo: Corte de Cables
    
    Reglas por dificultad:
    
    3 CABLES (Fácil):
      1. Si no hay cables rojos → cortar cable 2
      2. Si el último cable es blanco → cortar el último cable (3)
      3. Si hay más de un cable azul → cortar el último cable azul
      4. Default → cortar el último cable (3)
    
    4 CABLES (Normal):
      1. Si hay 2+ cables rojos → cortar el último cable rojo
      2. Si el último cable es amarillo y no hay rojos → cortar cable 1
      3. Si hay exactamente 1 cable azul → cortar cable 1
      4. Si hay 2+ cables amarillos → cortar cable 4
      5. Default → cortar cable 2
    
    5 CABLES (Difícil):
      1. Si el último cable es negro → cortar cable 4
      2. Si hay exactamente 1 rojo y 2+ amarillos → cortar cable 1
      3. Si no hay cables negros → cortar cable 2
      4. Default → cortar cable 1
    
    6 CABLES (Extremo):
      1. Si no hay cables amarillos → cortar cable 3
      2. Si hay exactamente 1 amarillo y 2+ blancos → cortar cable 4
      3. Si no hay cables rojos → cortar cable 6
      4. Default → cortar cable 4
]]

if not CLIENT then return end

IVO_BOMBS.Modules = IVO_BOMBS.Modules or {}

-- Fuente
surface.CreateFont("WireModuleLabel", {
    font = "Roboto", size = 13, weight = 600, antialias = true,
})
surface.CreateFont("WireModuleStatus", {
    font = "Roboto", size = 16, weight = 700, antialias = true,
})

local MODULE = {}
MODULE.Name = "Cables"
MODULE.Icon = "✂"

local function CountColor(wires, colorName)
    local c = 0
    for _, w in ipairs(wires) do
        if w.colorName == colorName then c = c + 1 end
    end
    return c
end

local function LastColorIndex(wires, colorName)
    for i = #wires, 1, -1 do
        if wires[i].colorName == colorName then return i end
    end
    return nil
end

local function DetermineCorrectWire(wires, wireCount)
    if wireCount == 3 then
        -- 3 Cables (Fácil)
        if CountColor(wires, "Rojo") == 0 then return 2 end
        if wires[#wires].colorName == "Blanco" then return #wires end
        if CountColor(wires, "Azul") > 1 then return LastColorIndex(wires, "Azul") end
        return #wires

    elseif wireCount == 4 then
        -- 4 Cables (Normal)
        if CountColor(wires, "Rojo") >= 2 then return LastColorIndex(wires, "Rojo") end
        if wires[#wires].colorName == "Amarillo" and CountColor(wires, "Rojo") == 0 then return 1 end
        if CountColor(wires, "Azul") == 1 then return 1 end
        if CountColor(wires, "Amarillo") >= 2 then return 4 end
        return 2

    elseif wireCount == 5 then
        -- 5 Cables (Difícil)
        if wires[#wires].colorName == "Negro" then return 4 end
        if CountColor(wires, "Rojo") == 1 and CountColor(wires, "Amarillo") >= 2 then return 1 end
        if CountColor(wires, "Negro") == 0 then return 2 end
        return 1

    elseif wireCount == 6 then
        -- 6 Cables (Extremo)
        if CountColor(wires, "Amarillo") == 0 then return 3 end
        if CountColor(wires, "Amarillo") == 1 and CountColor(wires, "Blanco") >= 2 then return 4 end
        if CountColor(wires, "Rojo") == 0 then return 6 end
        return 4
    end

    return 1
end

function MODULE.Create(parent, w, h, difficulty, rng, onComplete, onStrike)
    local config = IVO_BOMBS.Difficulties[difficulty]
    local wireCount = config and config.wireCount or 3
    local wireColors = IVO_BOMBS.WireColors

    -- Panel principal
    local panel = vgui.Create("DPanel", parent)
    panel:SetPos(0, 0)
    panel:SetSize(w, h)

    -- Generar cables aleatorios
    local wires = {}
    for i = 1, wireCount do
        local colorIdx = rng(1, #wireColors)
        local wc = wireColors[colorIdx]
        table.insert(wires, {
            colorName = wc.name,
            color     = wc.color,
            cut       = false,
            cutAnim   = 0,
        })
    end

    local correctWire = DetermineCorrectWire(wires, wireCount)
    panel.wires = wires
    panel.correctWire = correctWire
    panel.solved = false
    panel.failed = false
    panel.hoverWire = nil

    -- Dimensiones de cables
    local wireStartX = 40
    local wireEndX = w - 40
    local wireAreaTop = 25
    local wireAreaBot = h - 20
    local wireSpacing = (wireAreaBot - wireAreaTop) / (wireCount + 1)
    local wireThickness = math.Clamp(14 - wireCount, 6, 12)

    panel.Paint = function(self, pw, ph)
        -- Fondo
        draw.RoundedBox(4, 0, 0, pw, ph, Color(12, 16, 28))

        -- Conectores izquierdo y derecho
        draw.RoundedBox(4, wireStartX - 20, wireAreaTop - 5, 20, wireAreaBot - wireAreaTop + 10, Color(40, 45, 55))
        draw.RoundedBox(4, wireEndX, wireAreaTop - 5, 20, wireAreaBot - wireAreaTop + 10, Color(40, 45, 55))

        -- Dibujar cables
        for i, wire in ipairs(self.wires) do
            local y = wireAreaTop + wireSpacing * i
            local col = wire.color

            if wire.cut then
                -- Cable cortado - dos mitades separadas con animación
                local gapSize = wire.cutAnim * 30
                local midX = (wireStartX + wireEndX) / 2

                -- Parte izquierda
                surface.SetDrawColor(col.r, col.g, col.b, 180)
                surface.DrawRect(wireStartX, y - wireThickness/2, midX - wireStartX - gapSize/2, wireThickness)

                -- Parte derecha
                surface.DrawRect(midX + gapSize/2, y - wireThickness/2, wireEndX - midX - gapSize/2, wireThickness)

                -- Chispas
                if wire.cutAnim < 1 then
                    local sparkAlpha = (1 - wire.cutAnim) * 255
                    for s = 1, 3 do
                        local sx = midX + math.sin(CurTime() * 20 + s) * 15
                        local sy = y + math.cos(CurTime() * 15 + s) * 10
                        draw.RoundedBox(2, sx - 2, sy - 2, 4, 4, Color(255, 220, 80, sparkAlpha))
                    end
                end
            else
                -- Cable intacto
                local isHover = self.hoverWire == i and not self.solved and not self.failed

                -- Sombra
                surface.SetDrawColor(0, 0, 0, 60)
                surface.DrawRect(wireStartX, y - wireThickness/2 + 2, wireEndX - wireStartX, wireThickness)

                -- Cable principal
                local r, g, b = col.r, col.g, col.b
                if isHover then
                    r = math.min(255, r + 60)
                    g = math.min(255, g + 60)
                    b = math.min(255, b + 60)
                end
                surface.SetDrawColor(r, g, b, 255)
                surface.DrawRect(wireStartX, y - wireThickness/2, wireEndX - wireStartX, wireThickness)

                -- Brillo superior
                surface.SetDrawColor(255, 255, 255, isHover and 50 or 20)
                surface.DrawRect(wireStartX, y - wireThickness/2, wireEndX - wireStartX, 2)

                -- Número del cable
                draw.SimpleText(tostring(i), "WireModuleLabel", wireStartX - 25, y,
                    Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                -- Nombre del color
                draw.SimpleText(wire.colorName, "WireModuleLabel", wireEndX + 25, y,
                    wire.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                -- Hover highlight
                if isHover then
                    surface.SetDrawColor(255, 255, 255, 20)
                    surface.DrawRect(wireStartX - 5, y - wireThickness/2 - 3, wireEndX - wireStartX + 10, wireThickness + 6)

                    -- Icono de tijera
                    local mx, my = self:CursorPos()
                    draw.SimpleText("✂", "WireModuleStatus", mx, my - 15,
                        Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
        end

        -- Estado
        if self.solved then
            draw.SimpleText("✓ CORRECTO", "WireModuleStatus", pw/2, ph - 12,
                IVO_BOMBS.Colors.success, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif self.failed then
            draw.SimpleText("✗ INCORRECTO - Reintentando...", "WireModuleStatus", pw/2, ph - 12,
                IVO_BOMBS.Colors.danger, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    -- Detectar hover
    panel.Think = function(self)
        if self.solved or self.failed then
            self.hoverWire = nil

            -- Animar cortes
            for _, wire in ipairs(self.wires) do
                if wire.cut and wire.cutAnim < 1 then
                    wire.cutAnim = math.Approach(wire.cutAnim, 1, FrameTime() * 3)
                end
            end
            return
        end

        local mx, my = self:CursorPos()
        self.hoverWire = nil

        for i, wire in ipairs(self.wires) do
            if wire.cut then continue end
            local wy = wireAreaTop + wireSpacing * i
            if mx >= wireStartX and mx <= wireEndX and
               my >= wy - wireThickness/2 - 5 and my <= wy + wireThickness/2 + 5 then
                self.hoverWire = i
                break
            end
        end
    end

    -- Click para cortar
    panel.OnMousePressed = function(self, keyCode)
        if keyCode ~= MOUSE_LEFT then return end
        if self.solved or self.failed then return end
        if not self.hoverWire then return end

        local clickedWire = self.hoverWire
        self.wires[clickedWire].cut = true
        self.wires[clickedWire].cutAnim = 0

        surface.PlaySound("physics/metal/metal_sheet_impact_hard6.wav")

        if clickedWire == self.correctWire then
            -- ¡Correcto!
            self.solved = true
            timer.Simple(0.8, function()
                if onComplete then onComplete() end
            end)
        else
            -- Incorrecto
            self.failed = true
            if onStrike then onStrike() end

            -- Regenerar después de un delay
            timer.Simple(1.5, function()
                if not IsValid(self) then return end

                -- Regenerar cables
                local newWires = {}
                for i = 1, wireCount do
                    local colorIdx = rng(1, #wireColors)
                    local wc = wireColors[colorIdx]
                    table.insert(newWires, {
                        colorName = wc.name,
                        color     = wc.color,
                        cut       = false,
                        cutAnim   = 0,
                    })
                end
                self.wires = newWires
                self.correctWire = DetermineCorrectWire(newWires, wireCount)
                self.failed = false
                self.hoverWire = nil
            end)
        end
    end

    return panel
end

IVO_BOMBS.Modules["wires"] = MODULE
