--[[
    ivo_bombs - Entidad Bomba (Client)
    Renderizado 3D: timer, dificultad, luces dinámicas, HUD de proximidad
]]

include("shared.lua")

-- Fuentes
surface.CreateFont("BombTimer3D", {
    font = "Roboto", size = 28, weight = 700, antialias = true, shadow = true,
})
surface.CreateFont("BombTimerLarge3D", {
    font = "Roboto", size = 40, weight = 800, antialias = true, shadow = true,
})
surface.CreateFont("BombLabel3D", {
    font = "Roboto", size = 16, weight = 500, antialias = true, shadow = true,
})
surface.CreateFont("BombStatus3D", {
    font = "Roboto", size = 22, weight = 700, antialias = true, shadow = true,
})
surface.CreateFont("BombHUDTimer", {
    font = "Roboto", size = 32, weight = 800, antialias = true, shadow = true,
})
surface.CreateFont("BombHUDLabel", {
    font = "Roboto", size = 14, weight = 500, antialias = true,
})

function ENT:Initialize()
    self._glowPulse = 0
end

function ENT:Draw()
    if self:GetArmed() and not self:GetDefused() then
        local timeLeft = self:GetDetonateTime() - CurTime()
        local pulseSpeed = timeLeft > 10 and 2 or (timeLeft > 5 and 4 or 8)
        self._glowPulse = math.abs(math.sin(CurTime() * pulseSpeed))

        -- Vibración cuando queda poco
        if timeLeft < 5 then
            self:SetRenderOrigin(self:GetPos() + VectorRand() * 0.5)
        else
            self:SetRenderOrigin(nil)
        end

        self:DrawModel()
        self:SetRenderOrigin(nil)

        -- Luz dinámica
        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = self:GetPos() + Vector(0, 0, 20)
            dlight.r = 255
            dlight.g = 50 + self._glowPulse * 50
            dlight.b = 20
            dlight.brightness = 2 + self._glowPulse * 3
            dlight.decay = 500
            dlight.size = 180 + self._glowPulse * 80
            dlight.dietime = CurTime() + 0.1
        end
    else
        self:DrawModel()

        if self:GetDefused() then
            local dlight = DynamicLight(self:EntIndex())
            if dlight then
                dlight.pos = self:GetPos() + Vector(0, 0, 20)
                dlight.r, dlight.g, dlight.b = 50, 255, 80
                dlight.brightness = 2
                dlight.decay = 500
                dlight.size = 120
                dlight.dietime = CurTime() + 0.1
            end
        end
    end
end

function ENT:DrawTranslucent()
    local ply = LocalPlayer()
    local dist = ply:GetPos():Distance(self:GetPos())
    if dist > 600 then return end

    local pos = self:GetPos() + Vector(0, 0, 55)
    local ang = (pos - ply:EyePos()):Angle()
    ang:RotateAroundAxis(ang:Up(), -90)
    ang:RotateAroundAxis(ang:Forward(), 90)

    local scale = math.Clamp(1 - (dist / 600), 0.4, 1)

    cam.Start3D2D(pos, ang, 0.08 * scale)
        local w, h = 300, 100
        local diff = self:GetDifficulty()
        local config = IVO_BOMBS and IVO_BOMBS.Difficulties[diff]

        if self:GetDefused() then
            draw.RoundedBox(12, -w/2, -h/2, w, h, Color(20, 80, 20, 200))
            draw.RoundedBox(10, -w/2+2, -h/2+2, w-4, h-4, Color(30, 120, 30, 180))
            draw.SimpleText("DESACTIVADA", "BombStatus3D", 0, -10, Color(80, 255, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Bomba neutralizada", "BombLabel3D", 0, 20, Color(180, 255, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        elseif self:GetArmed() then
            local timeLeft = math.max(0, self:GetDetonateTime() - CurTime())
            local mins = math.floor(timeLeft / 60)
            local secs = math.floor(timeLeft % 60)
            local ms   = math.floor((timeLeft % 1) * 100)

            local timerColor
            if timeLeft > 20 then timerColor = Color(255, 255, 255)
            elseif timeLeft > 10 then timerColor = Color(255, 230, 50)
            elseif timeLeft > 5 then timerColor = Color(255, 160, 40)
            else timerColor = Color(255, 50, 50, 200 + math.sin(CurTime() * 15) * 55) end

            local bgAlpha = timeLeft < 5 and (180 + math.sin(CurTime() * 10) * 40) or 180

            -- Panel
            draw.RoundedBox(12, -w/2, -h/2, w, h+20, Color(15, 15, 15, bgAlpha))
            draw.RoundedBox(10, -w/2+2, -h/2+2, w-4, h+16, Color(40, 10, 10, bgAlpha - 20))

            -- Borde pulsante
            local borderA = 120 + self._glowPulse * 135
            surface.SetDrawColor(255, 40, 40, borderA)
            surface.DrawOutlinedRect(-w/2, -h/2, w, h+20, 2)

            -- Título con dificultad
            local diffName = config and config.name or "?"
            local diffColor = config and config.color or Color(200, 200, 200)
            draw.SimpleText("BOMBA", "BombStatus3D", -30, -h/2+18, Color(255, 60, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("[" .. diffName .. "]", "BombLabel3D", 40, -h/2+18, diffColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Separador
            surface.SetDrawColor(255, 50, 50, 80)
            surface.DrawRect(-w/2+20, -h/2+35, w-40, 1)

            -- Timer
            local timerStr = string.format("%01d:%02d.%02d", mins, secs, ms)
            draw.SimpleText(timerStr, "BombTimerLarge3D", 0, -h/2+65, timerColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Strikes
            local strikes = self:GetStrikeCount()
            local maxStrikes = config and config.maxStrikes or 3
            local strikeStr = ""
            for i = 1, maxStrikes do
                strikeStr = strikeStr .. (i <= strikes and "X " or "O ")
            end
            draw.SimpleText("Strikes: " .. strikeStr, "BombLabel3D", 0, -h/2+95, Color(255, 100, 100, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Módulos
            local solved = self:GetModulesSolved()
            local total = config and config.modules or 0
            draw.SimpleText("Módulos: " .. solved .. "/" .. total, "BombLabel3D", 0, -h/2+112, Color(200, 200, 200, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end

-- HUD de proximidad en pantalla
hook.Add("HUDPaint", "ivo_bombs_proximity_hud", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local bombs = ents.FindByClass("ent_ivo_bomb")
    local closest, closestDist = nil, math.huge

    for _, b in ipairs(bombs) do
        if IsValid(b) and b:GetArmed() and not b:GetDefused() then
            local d = ply:GetPos():Distance(b:GetPos())
            if d < closestDist then
                closestDist = d
                closest = b
            end
        end
    end

    if not IsValid(closest) or closestDist > 2000 then return end

    local timeLeft = math.max(0, closest:GetDetonateTime() - CurTime())
    local scrW, scrH = ScrW(), ScrH()
    local pw, ph = 260, 44
    local px = scrW/2 - pw/2
    local py = 8
    local alpha = math.Clamp((1 - closestDist / 2000) * 255, 0, 255)
    if alpha <= 0 then return end

    -- Fondo
    draw.RoundedBox(6, px, py, pw, ph, Color(10, 10, 10, alpha * 0.85))
    local borderCol = timeLeft < 10 and Color(255, 50, 50, alpha) or Color(255, 160, 40, alpha)
    surface.SetDrawColor(borderCol)
    surface.DrawOutlinedRect(px, py, pw, ph, 1)

    -- Timer
    local mins = math.floor(timeLeft / 60)
    local secs = math.floor(timeLeft % 60)
    local timerStr = string.format("%01d:%02d", mins, secs)

    local timerCol
    if timeLeft > 20 then timerCol = Color(255, 255, 255, alpha)
    elseif timeLeft > 10 then timerCol = Color(255, 230, 50, alpha)
    else timerCol = Color(255, 50, 50, alpha * (0.5 + math.abs(math.sin(CurTime() * 6)) * 0.5)) end

    draw.SimpleText("BOMBA", "BombHUDLabel", px + 15, py + ph/2, Color(255, 80, 60, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(timerStr, "BombHUDTimer", px + 80, py + ph/2, timerCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(math.floor(closestDist) .. "m", "BombHUDLabel", px + pw - 15, py + ph/2, Color(180, 180, 180, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end)
