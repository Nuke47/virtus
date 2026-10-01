-- ============================================================================
-- STARFIGHTER HUD - Client-Side Rendering
-- Star Wars inspired HUD for LVS vehicles
-- Author: Ivo
-- ============================================================================

-- Wait for shared config to load
if not StarfighterHUD then
    include("autorun/sh_starfighter_hud_config.lua")
end

local SHUD = StarfighterHUD or {}

-- ============================================================================
-- LOCAL CACHES & MATERIALS
-- ============================================================================

local ScrW, ScrH = ScrW, ScrH
local math_sin, math_cos = math.sin, math.cos
local math_clamp = math.Clamp
local math_abs = math.abs
local math_rad = math.rad
local math_floor = math.floor
local math_Remap = math.Remap
local surface = surface
local draw = draw
local cam = cam
local render = render
local CurTime = CurTime
local RealFrameTime = RealFrameTime
local LocalPlayer = LocalPlayer
local IsValid = IsValid
local tostring = tostring
local string_format = string.format
local table_insert = table.insert
local table_sort = table.sort

-- ConVars
local cv_enabled = CreateClientConVar("starfighter_hud_enabled", "1", true, false, "Enable the starfighter HUD")
local cv_opacity = CreateClientConVar("starfighter_hud_opacity", "1", true, false, "HUD opacity multiplier (0-1)")
local cv_minimal = CreateClientConVar("starfighter_hud_minimal", "0", true, false, "Use minimal HUD mode")
local cv_tracking = CreateClientConVar("starfighter_hud_tracking", "1", true, false, "Show entity tracking brackets")
local cv_compass = CreateClientConVar("starfighter_hud_compass", "1", true, false, "Show compass")
local cv_horizon = CreateClientConVar("starfighter_hud_horizon", "1", true, false, "Show artificial horizon")
local cv_lockkey = CreateClientConVar("starfighter_hud_lock_key", "20", true, false, "Key code for target lock (default: T = 20)")

-- Smoothing vars
local sm_speed = 0
local sm_alt = 0
local sm_throttle = 0
local sm_health = 1
local sm_shield = 1
local sm_heat = 0
local sm_roll = 0
local sm_pitch = 0
local sm_lockProgress = 0

-- Tracking state
local TrackedTargets = {}
local LockedTarget = nil
local LockStartTime = 0
local IsLocking = false
local LockAcquired = false

-- Animation state
local animPulse = 0
local animBracket = 0
local animWarning = 0
local lastDamageTime = 0
local damageFlash = 0

-- Fonts
surface.CreateFont("StarfighterHUD_Large", {
    font = "Roboto Mono",
    size = 28,
    weight = 700,
    antialias = true,
})

surface.CreateFont("StarfighterHUD_Medium", {
    font = "Roboto Mono",
    size = 20,
    weight = 600,
    antialias = true,
})

surface.CreateFont("StarfighterHUD_Small", {
    font = "Roboto Mono",
    size = 14,
    weight = 500,
    antialias = true,
})

surface.CreateFont("StarfighterHUD_Tiny", {
    font = "Roboto Mono",
    size = 11,
    weight = 400,
    antialias = true,
})

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function GetAlphaColor(col, alpha)
    return Color(col.r, col.g, col.b, col.a * (alpha or 1) * cv_opacity:GetFloat())
end

local function Lerp(t, from, to)
    return from + (to - from) * math_clamp(t, 0, 1)
end

local function SmoothApproach(current, target, speed)
    local dt = RealFrameTime()
    return current + (target - current) * math_clamp(dt * speed, 0, 1)
end

local function FormatNumber(n)
    return string_format("%d", math_floor(n))
end

local function FormatSpeed(vel)
    -- Convert Source units to a Star Wars-ish speed display (MGLT-like)
    return string_format("%04d", math_floor(vel / 10))
end

local function FormatAlt(alt)
    return string_format("%05d", math_clamp(math_floor(alt / 10), 0, 99999))
end

local function DrawRotatedRect(x, y, w, h, ang, col)
    surface.SetDrawColor(col)
    local c = math_cos(math_rad(ang))
    local s = math_sin(math_rad(ang))
    
    local hw, hh = w/2, h/2
    local corners = {
        {x + (-hw * c - (-hh) * s), y + (-hw * s + (-hh) * c)},
        {x + (hw * c - (-hh) * s), y + (hw * s + (-hh) * c)},
        {x + (hw * c - hh * s), y + (hw * s + hh * c)},
        {x + (-hw * c - hh * s), y + (-hw * s + hh * c)},
    }
    
    surface.DrawPoly({
        {x = corners[1][1], y = corners[1][2]},
        {x = corners[2][1], y = corners[2][2]},
        {x = corners[3][1], y = corners[3][2]},
        {x = corners[4][1], y = corners[4][2]},
    })
end

-- Draw corner brackets (Star Wars targeting style)
local function DrawBrackets(x, y, size, thickness, col, gap)
    gap = gap or 0
    local len = size * 0.35
    surface.SetDrawColor(col)
    
    -- Top-left
    surface.DrawRect(x - size/2 - gap, y - size/2 - gap, len, thickness)
    surface.DrawRect(x - size/2 - gap, y - size/2 - gap, thickness, len)
    
    -- Top-right
    surface.DrawRect(x + size/2 + gap - len, y - size/2 - gap, len, thickness)
    surface.DrawRect(x + size/2 + gap - thickness, y - size/2 - gap, thickness, len)
    
    -- Bottom-left
    surface.DrawRect(x - size/2 - gap, y + size/2 + gap - thickness, len, thickness)
    surface.DrawRect(x - size/2 - gap, y + size/2 + gap - len, thickness, len)
    
    -- Bottom-right
    surface.DrawRect(x + size/2 + gap - len, y + size/2 + gap - thickness, len, thickness)
    surface.DrawRect(x + size/2 + gap - thickness, y + size/2 + gap - len, thickness, len)
end

-- Draw a diamond shape
local function DrawDiamond(x, y, size, col)
    local half = size / 2
    draw.NoTexture()
    surface.SetDrawColor(col)
    surface.DrawPoly({
        {x = x, y = y - half},
        {x = x + half, y = y},
        {x = x, y = y + half},
        {x = x - half, y = y},
    })
end

-- ============================================================================
-- HUD COMPONENTS
-- ============================================================================

-- Speed indicator (left side)
local function DrawSpeedIndicator(x, y, speed, vehicle)
    local w, h = 160, 200
    local col = SHUD.Colors and SHUD.Colors.HUDGreen or Color(0, 255, 100, 200)
    local dimCol = SHUD.Colors and SHUD.Colors.HUDGreenDim or Color(0, 180, 70, 120)
    local bgCol = SHUD.Colors and SHUD.Colors.HUDBackground or Color(0, 0, 0, 80)
    
    local alpha = cv_opacity:GetFloat()
    
    -- Background panel
    draw.RoundedBox(0, x - w/2, y - h/2, w, h, GetAlphaColor(bgCol))
    
    -- Title
    draw.SimpleText("SPEED", "StarfighterHUD_Tiny", x, y - h/2 + 8, GetAlphaColor(dimCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Speed value
    draw.SimpleText(FormatSpeed(speed), "StarfighterHUD_Large", x, y - 15, GetAlphaColor(col), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Unit label
    draw.SimpleText("MGLT", "StarfighterHUD_Tiny", x, y + 10, GetAlphaColor(dimCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Speed bar (vertical, left edge)
    local maxSpeed = 3000
    if vehicle and vehicle.MaxVelocity then
        maxSpeed = vehicle.MaxVelocity
    end
    local speedFrac = math_clamp(speed / maxSpeed, 0, 1)
    
    local barX = x - w/2 + 5
    local barW = 6
    local barH = h - 50
    local barY = y - h/2 + 40
    
    -- Bar background
    surface.SetDrawColor(GetAlphaColor(Color(30, 30, 30, 150)))
    surface.DrawRect(barX, barY, barW, barH)
    
    -- Bar fill
    local fillH = barH * speedFrac
    surface.SetDrawColor(GetAlphaColor(col))
    surface.DrawRect(barX, barY + barH - fillH, barW, fillH)
    
    -- Tick marks
    for i = 0, 4 do
        local tickY = barY + (barH / 4) * i
        surface.SetDrawColor(GetAlphaColor(dimCol))
        surface.DrawRect(barX + barW + 2, tickY, 4, 1)
    end
    
    -- Boost indicator
    if vehicle and vehicle.GetBoost then
        local boost = vehicle:GetBoost()
        if boost and boost > 0 then
            local boostCol = Color(100, 200, 255, 200 + math_sin(CurTime() * 8) * 55)
            draw.SimpleText("▶ BOOST", "StarfighterHUD_Tiny", x, y + h/2 - 18, GetAlphaColor(boostCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

-- Altitude indicator (right side)
local function DrawAltitudeIndicator(x, y, altitude, vehicle)
    local w, h = 160, 200
    local col = SHUD.Colors and SHUD.Colors.HUDGreen or Color(0, 255, 100, 200)
    local dimCol = SHUD.Colors and SHUD.Colors.HUDGreenDim or Color(0, 180, 70, 120)
    local bgCol = SHUD.Colors and SHUD.Colors.HUDBackground or Color(0, 0, 0, 80)
    
    -- Background panel
    draw.RoundedBox(0, x - w/2, y - h/2, w, h, GetAlphaColor(bgCol))
    
    -- Title
    draw.SimpleText("ALT", "StarfighterHUD_Tiny", x, y - h/2 + 8, GetAlphaColor(dimCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Altitude value
    draw.SimpleText(FormatAlt(altitude), "StarfighterHUD_Large", x, y - 15, GetAlphaColor(col), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Unit
    draw.SimpleText("M", "StarfighterHUD_Tiny", x, y + 10, GetAlphaColor(dimCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Vertical speed indicator
    if vehicle then
        local vel = vehicle:GetVelocity()
        if vel then
            local vspeed = vel.z
            local vsCol = vspeed > 50 and Color(100, 255, 100, 200) or (vspeed < -50 and Color(255, 100, 100, 200) or dimCol)
            local arrow = vspeed > 50 and "▲" or (vspeed < -50 and "▼" or "—")
            draw.SimpleText(arrow .. " " .. FormatNumber(math_abs(vspeed / 10)), "StarfighterHUD_Small", x, y + h/2 - 25, GetAlphaColor(vsCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

-- Shield & Health bars (bottom center)
local function DrawStatusBars(x, y, health, maxHealth, shield, maxShield, heat)
    local barW = 280
    local barH = 10
    local gap = 4
    local col = SHUD.Colors or {}
    local bgCol = col.HUDBackground or Color(0, 0, 0, 80)
    local healthCol = col.Health or Color(50, 255, 100, 200)
    local shieldCol = col.Shield or Color(50, 150, 255, 200)
    local heatCol = col.Heat or Color(255, 150, 0, 200)
    
    local healthFrac = maxHealth > 0 and math_clamp(health / maxHealth, 0, 1) or 0
    local shieldFrac = maxShield > 0 and math_clamp(shield / maxShield, 0, 1) or 0
    
    -- Smooth values
    sm_health = SmoothApproach(sm_health, healthFrac, 5)
    sm_shield = SmoothApproach(sm_shield, shieldFrac, 5)
    sm_heat = SmoothApproach(sm_heat, heat or 0, 8)
    
    local startY = y
    
    -- Shield bar (if vehicle has shield)
    if maxShield > 0 then
        -- Label
        draw.SimpleText("SHD", "StarfighterHUD_Tiny", x - barW/2 - 30, startY, GetAlphaColor(shieldCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Background
        surface.SetDrawColor(GetAlphaColor(bgCol))
        surface.DrawRect(x - barW/2, startY - barH/2, barW, barH)
        
        -- Fill
        local sCol = sm_shield < 0.25 and Color(shieldCol.r, shieldCol.g, shieldCol.b, 200 + math_sin(CurTime() * 6) * 55) or shieldCol
        surface.SetDrawColor(GetAlphaColor(sCol))
        surface.DrawRect(x - barW/2, startY - barH/2, barW * sm_shield, barH)
        
        -- Value text
        draw.SimpleText(FormatNumber(shield), "StarfighterHUD_Tiny", x + barW/2 + 25, startY, GetAlphaColor(shieldCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Border
        surface.SetDrawColor(GetAlphaColor(Color(shieldCol.r, shieldCol.g, shieldCol.b, 80)))
        surface.DrawOutlinedRect(x - barW/2, startY - barH/2, barW, barH, 1)
        
        startY = startY + barH + gap
    end
    
    -- Health bar
    do
        -- Label
        draw.SimpleText("HUL", "StarfighterHUD_Tiny", x - barW/2 - 30, startY, GetAlphaColor(healthCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Background
        surface.SetDrawColor(GetAlphaColor(bgCol))
        surface.DrawRect(x - barW/2, startY - barH/2, barW, barH)
        
        -- Fill - color changes when low
        local hCol = healthCol
        if sm_health < 0.25 then
            hCol = Color(255, 50, 50, 200 + math_sin(CurTime() * 8) * 55)
        elseif sm_health < 0.5 then
            hCol = Color(255, 200, 0, 200)
        end
        surface.SetDrawColor(GetAlphaColor(hCol))
        surface.DrawRect(x - barW/2, startY - barH/2, barW * sm_health, barH)
        
        -- Value text
        draw.SimpleText(FormatNumber(health), "StarfighterHUD_Tiny", x + barW/2 + 25, startY, GetAlphaColor(healthCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Border
        surface.SetDrawColor(GetAlphaColor(Color(healthCol.r, healthCol.g, healthCol.b, 80)))
        surface.DrawOutlinedRect(x - barW/2, startY - barH/2, barW, barH, 1)
        
        startY = startY + barH + gap
    end
    
    -- Heat bar
    if heat and heat > 0.01 then
        -- Label
        local htCol = sm_heat > 0.8 and Color(255, 50, 50, 200 + math_sin(CurTime() * 10) * 55) or heatCol
        draw.SimpleText("THM", "StarfighterHUD_Tiny", x - barW/2 - 30, startY, GetAlphaColor(htCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Background
        surface.SetDrawColor(GetAlphaColor(bgCol))
        surface.DrawRect(x - barW/2, startY - barH/2, barW, barH)
        
        -- Fill
        surface.SetDrawColor(GetAlphaColor(htCol))
        surface.DrawRect(x - barW/2, startY - barH/2, barW * sm_heat, barH)
        
        -- Border
        surface.SetDrawColor(GetAlphaColor(Color(heatCol.r, heatCol.g, heatCol.b, 80)))
        surface.DrawOutlinedRect(x - barW/2, startY - barH/2, barW, barH, 1)
    end
end

-- Throttle gauge (left bottom area)
local function DrawThrottleGauge(x, y, throttle, vehicle)
    local col = SHUD.Colors and SHUD.Colors.HUDGreen or Color(0, 255, 100, 200)
    local dimCol = SHUD.Colors and SHUD.Colors.HUDGreenDim or Color(0, 180, 70, 120)
    local bgCol = SHUD.Colors and SHUD.Colors.HUDBackground or Color(0, 0, 0, 80)
    
    sm_throttle = SmoothApproach(sm_throttle, throttle, 6)
    
    local h = 120
    local w = 30
    
    -- Background
    draw.RoundedBox(0, x - w/2, y - h/2, w, h, GetAlphaColor(bgCol))
    
    -- Title
    draw.SimpleText("THR", "StarfighterHUD_Tiny", x, y - h/2 - 10, GetAlphaColor(dimCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    
    -- Fill
    local fillH = (h - 8) * sm_throttle
    local thrCol = sm_throttle > 0.9 and Color(255, 200, 0, 200) or col
    surface.SetDrawColor(GetAlphaColor(thrCol))
    surface.DrawRect(x - w/2 + 4, y + h/2 - 4 - fillH, w - 8, fillH)
    
    -- Percentage
    draw.SimpleText(FormatNumber(sm_throttle * 100) .. "%", "StarfighterHUD_Tiny", x, y + h/2 + 8, GetAlphaColor(col), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

-- Compass (top center)
local function DrawCompass(x, y, yaw)
    if not cv_compass:GetBool() then return end
    
    local col = SHUD.Colors and SHUD.Colors.HUDGreen or Color(0, 255, 100, 200)
    local dimCol = SHUD.Colors and SHUD.Colors.HUDGreenDim or Color(0, 180, 70, 120)
    local bgCol = SHUD.Colors and SHUD.Colors.HUDBackground or Color(0, 0, 0, 80)
    
    local w = 300
    local h = 24
    
    -- Background
    draw.RoundedBox(0, x - w/2, y, w, h, GetAlphaColor(bgCol))
    
    -- Clip region for compass tape
    render.SetScissorRect(x - w/2 + 2, y, x + w/2 - 2, y + h, true)
    
    local directions = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}
    local degPerPixel = w / 120 -- show 120 degrees of compass
    
    for deg = -180, 360, 5 do
        local diff = ((deg - yaw + 180) % 360) - 180
        local px = x + diff * degPerPixel
        
        if px > x - w/2 - 20 and px < x + w/2 + 20 then
            if deg % 45 == 0 then
                -- Cardinal direction
                local dirIdx = ((deg % 360) / 45) + 1
                if dirIdx < 1 then dirIdx = dirIdx + 8 end
                if dirIdx > 8 then dirIdx = dirIdx - 8 end
                local dirName = directions[math_floor(dirIdx)] or ""
                
                local isCardinal = (deg % 90 == 0)
                local dCol = isCardinal and col or dimCol
                draw.SimpleText(dirName, "StarfighterHUD_Small", px, y + h/2, GetAlphaColor(dCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            elseif deg % 15 == 0 then
                -- Minor tick
                surface.SetDrawColor(GetAlphaColor(Color(dimCol.r, dimCol.g, dimCol.b, 80)))
                surface.DrawRect(px, y + h/2 - 3, 1, 6)
            end
        end
    end
    
    render.SetScissorRect(0, 0, 0, 0, false)
    
    -- Center indicator (triangle)
    draw.NoTexture()
    surface.SetDrawColor(GetAlphaColor(col))
    surface.DrawPoly({
        {x = x - 4, y = y},
        {x = x + 4, y = y},
        {x = x, y = y + 6},
    })
    
    -- Heading number
    local heading = math_floor(yaw) % 360
    if heading < 0 then heading = heading + 360 end
    draw.SimpleText(string_format("%03d°", heading), "StarfighterHUD_Tiny", x, y + h + 4, GetAlphaColor(col), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

-- Artificial horizon
local function DrawHorizon(cx, cy, pitch, roll)
    if not cv_horizon:GetBool() then return end
    
    local col = SHUD.Colors and SHUD.Colors.HUDGreen or Color(0, 255, 100, 200)
    local dimCol = SHUD.Colors and SHUD.Colors.HUDGreenDim or Color(0, 180, 70, 120)
    
    sm_pitch = SmoothApproach(sm_pitch, pitch, 8)
    sm_roll = SmoothApproach(sm_roll, roll, 8)
    
    local radius = 80
    
    -- Clip to circular area
    render.SetScissorRect(cx - radius, cy - radius, cx + radius, cy + radius, true)
    
    local rollRad = math_rad(-sm_roll)
    local pitchOffset = sm_pitch * 2
    
    -- Horizon line
    local lineLen = radius * 2
    local lx1 = cx - math_cos(rollRad) * lineLen
    local ly1 = cy + math_sin(rollRad) * lineLen + pitchOffset
    local lx2 = cx + math_cos(rollRad) * lineLen
    local ly2 = cy - math_sin(rollRad) * lineLen + pitchOffset
    
    surface.SetDrawColor(GetAlphaColor(col))
    surface.DrawLine(lx1, ly1, lx2, ly2)
    
    -- Pitch ladder lines
    for i = -6, 6 do
        if i == 0 then continue end
        local offset = i * 20
        local ladderLen = (i % 2 == 0) and 40 or 20
        local py = pitchOffset + offset
        
        local px1 = cx - math_cos(rollRad) * ladderLen
        local py1 = cy + math_sin(rollRad) * ladderLen + py
        local px2 = cx + math_cos(rollRad) * ladderLen
        local py2 = cy - math_sin(rollRad) * ladderLen + py
        
        local ladderCol = GetAlphaColor(Color(dimCol.r, dimCol.g, dimCol.b, 60))
        surface.SetDrawColor(ladderCol)
        surface.DrawLine(px1, py1, px2, py2)
        
        if i % 2 == 0 then
            draw.SimpleText(tostring(i * 5) .. "°", "StarfighterHUD_Tiny", px2 + 5, py2, ladderCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    
    render.SetScissorRect(0, 0, 0, 0, false)
    
    -- Center aircraft symbol (fixed)
    surface.SetDrawColor(GetAlphaColor(Color(255, 255, 255, 180)))
    surface.DrawRect(cx - 20, cy - 1, 15, 2) -- left wing
    surface.DrawRect(cx + 5, cy - 1, 15, 2)  -- right wing
    surface.DrawRect(cx - 2, cy - 2, 4, 4)    -- center dot
    
    -- Roll indicator arc at top
    local arcRadius = radius + 5
    for i = -6, 6 do
        local ang = math_rad(-90 + i * 10)
        local tx = cx + math_cos(ang) * arcRadius
        local ty = cy + math_sin(ang) * arcRadius
        local tickLen = (i == 0) and 8 or 4
        local tx2 = cx + math_cos(ang) * (arcRadius + tickLen)
        local ty2 = cy + math_sin(ang) * (arcRadius + tickLen)
        
        local tickCol = (i == 0) and col or dimCol
        surface.SetDrawColor(GetAlphaColor(tickCol))
        surface.DrawLine(tx, ty, tx2, ty2)
    end
end

-- ============================================================================
-- TARGET TRACKING SYSTEM (Star Wars style brackets)
-- ============================================================================

local function DrawTargetBracket(target, vehicle)
    if not cv_tracking:GetBool() then return end
    if not IsValid(target) then return end
    
    local col = SHUD.Colors or {}
    local pos = target:GetPos()
    
    -- Check if target is on screen
    local screenPos = pos:ToScreen()
    if not screenPos.visible then return end
    
    local sx, sy = screenPos.x, screenPos.y
    local dist = vehicle:GetPos():Distance(pos)
    
    -- Determine target type and color
    local isHostile = true
    local targetCol = col.HUDRed or Color(255, 50, 50, 200)
    local isLocked = (LockedTarget == target)
    
    -- Check AITEAM for friend/foe
    if vehicle.AITEAM and target.AITEAM then
        if vehicle.AITEAM == target.AITEAM then
            isHostile = false
            targetCol = col.HUDBlue or Color(80, 160, 255, 200)
        end
    end
    
    -- Size based on distance (closer = larger brackets)
    local baseSizeMul = math_clamp(math_Remap(dist, 500, 15000, 50, 18), 18, 50)
    
    -- Animate brackets
    local pulseAmt = math_sin(CurTime() * 3) * 0.1
    local bracketSize = baseSizeMul * (1 + pulseAmt)
    
    if isLocked then
        -- LOCKED TARGET - full lock-on display
        local lockCol = col.LockOn or Color(255, 50, 50, 255)
        local pulsingAlpha = 200 + math_sin(CurTime() * 6) * 55
        lockCol = Color(lockCol.r, lockCol.g, lockCol.b, pulsingAlpha)
        
        -- Diamond reticle
        DrawDiamond(sx, sy, bracketSize * 0.7, GetAlphaColor(lockCol))
        
        -- Outer rotating brackets
        local rotSpeed = CurTime() * 90
        
        -- Draw 4 rotating bracket sets
        for i = 0, 3 do
            local ang = rotSpeed + i * 90
            local rad = math_rad(ang)
            local bx = sx + math_cos(rad) * bracketSize * 0.8
            local by = sy + math_sin(rad) * bracketSize * 0.8
            
            surface.SetDrawColor(GetAlphaColor(lockCol))
            surface.DrawRect(bx - 3, by - 1, 6, 2)
            surface.DrawRect(bx - 1, by - 3, 2, 6)
        end
        
        -- Inner brackets (fixed)
        DrawBrackets(sx, sy, bracketSize * 0.9, 2, GetAlphaColor(lockCol))
        
        -- Target info display
        local infoY = sy + bracketSize/2 + 15
        local targetName = target.PrintName or target:GetClass()
        
        -- Name
        draw.SimpleText(targetName, "StarfighterHUD_Small", sx, infoY, GetAlphaColor(lockCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        infoY = infoY + 16
        
        -- Distance
        local distText = string_format("%.0fm", dist / 10)
        draw.SimpleText(distText, "StarfighterHUD_Tiny", sx, infoY, GetAlphaColor(lockCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        infoY = infoY + 14
        
        -- Target health (if available)
        if target.GetHealth and target.GetMaxHealth then
            local tHealth = target:GetHealth()
            local tMaxHealth = target:GetMaxHealth()
            if tMaxHealth and tMaxHealth > 0 then
                local hpFrac = math_clamp(tHealth / tMaxHealth, 0, 1)
                local hpBarW = 60
                local hpBarH = 4
                
                -- Background
                surface.SetDrawColor(GetAlphaColor(Color(0, 0, 0, 120)))
                surface.DrawRect(sx - hpBarW/2, infoY, hpBarW, hpBarH)
                
                -- Fill
                local hpCol = hpFrac > 0.5 and Color(50, 255, 100, 200) or (hpFrac > 0.25 and Color(255, 200, 0, 200) or Color(255, 50, 50, 200))
                surface.SetDrawColor(GetAlphaColor(hpCol))
                surface.DrawRect(sx - hpBarW/2, infoY, hpBarW * hpFrac, hpBarH)
            end
        end
        
        -- "LOCKED" text
        draw.SimpleText("◆ LOCKED", "StarfighterHUD_Tiny", sx, sy - bracketSize/2 - 18, GetAlphaColor(lockCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        
    elseif IsLocking and target == LockedTarget then
        -- LOCKING IN PROGRESS
        local lockingCol = col.Tracking or Color(255, 200, 0, 180)
        local progress = math_clamp(sm_lockProgress, 0, 1)
        
        -- Pulsing brackets
        DrawBrackets(sx, sy, bracketSize, 2, GetAlphaColor(lockingCol))
        
        -- Lock progress arc
        local arcSegments = math_floor(progress * 16)
        for i = 0, arcSegments do
            local ang = math_rad(-90 + (i / 16) * 360)
            local arcR = bracketSize * 0.6
            local px = sx + math_cos(ang) * arcR
            local py = sy + math_sin(ang) * arcR
            surface.SetDrawColor(GetAlphaColor(lockingCol))
            surface.DrawRect(px - 1, py - 1, 3, 3)
        end
        
        -- "LOCKING" text
        local lockText = string_format("LOCKING %d%%", math_floor(progress * 100))
        draw.SimpleText(lockText, "StarfighterHUD_Tiny", sx, sy - bracketSize/2 - 12, GetAlphaColor(lockingCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        
    else
        -- NORMAL TRACKING BRACKET
        DrawBrackets(sx, sy, bracketSize, 1, GetAlphaColor(targetCol))
        
        -- Small distance indicator
        if dist < 8000 then
            local distText = string_format("%.0f", dist / 10)
            draw.SimpleText(distText, "StarfighterHUD_Tiny", sx, sy + bracketSize/2 + 4, GetAlphaColor(Color(targetCol.r, targetCol.g, targetCol.b, 120)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
    end
end

-- Lead indicator (where to aim to hit a moving target)
local function DrawLeadIndicator(vehicle, target)
    if not IsValid(target) then return end
    if not LockAcquired then return end
    
    local col = SHUD.Colors and SHUD.Colors.LockOn or Color(255, 50, 50, 255)
    
    -- Calculate lead position
    local bulletSpeed = 50000 -- approximate LVS bullet speed
    local dist = vehicle:GetPos():Distance(target:GetPos())
    local travelTime = dist / bulletSpeed
    
    local leadPos = target:GetPos() + target:GetVelocity() * travelTime
    local screenPos = leadPos:ToScreen()
    
    if not screenPos.visible then return end
    
    -- Draw lead indicator (small circle with cross)
    local lx, ly = screenPos.x, screenPos.y
    local size = 8
    
    surface.SetDrawColor(GetAlphaColor(col))
    surface.DrawLine(lx - size, ly, lx + size, ly)
    surface.DrawLine(lx, ly - size, lx, ly + size)
    
    -- Draw a connecting line from target to lead
    local targetScreen = target:GetPos():ToScreen()
    if targetScreen.visible then
        surface.SetDrawColor(GetAlphaColor(Color(col.r, col.g, col.b, 80)))
        surface.DrawLine(targetScreen.x, targetScreen.y, lx, ly)
    end
end

-- ============================================================================
-- CENTER CROSSHAIR
-- ============================================================================

local function DrawCenterCrosshair(cx, cy)
    local col = SHUD.Colors and SHUD.Colors.HUDGreen or Color(0, 255, 100, 200)
    
    -- Small crosshair in center
    local size = 12
    local gap = 4
    
    surface.SetDrawColor(GetAlphaColor(col))
    -- Top
    surface.DrawRect(cx - 1, cy - size, 2, size - gap)
    -- Bottom
    surface.DrawRect(cx - 1, cy + gap, 2, size - gap)
    -- Left
    surface.DrawRect(cx - size, cy - 1, size - gap, 2)
    -- Right
    surface.DrawRect(cx + gap, cy - 1, size - gap, 2)
    
    -- Center dot
    surface.DrawRect(cx - 1, cy - 1, 2, 2)
end

-- ============================================================================
-- WARNING SYSTEM
-- ============================================================================

local function DrawWarnings(cx, cy, health, maxHealth, shield, maxShield, vehicle)
    local col = SHUD.Colors or {}
    local warningCol = col.HUDRed or Color(255, 50, 50, 200)
    local cautionCol = col.HUDYellow or Color(255, 200, 0, 200)
    
    local healthFrac = maxHealth > 0 and (health / maxHealth) or 1
    local warnings = {}
    
    -- Critical health warning
    if healthFrac < 0.2 then
        table_insert(warnings, {text = "⚠ HULL CRITICAL", col = warningCol, blink = true})
    elseif healthFrac < 0.4 then
        table_insert(warnings, {text = "⚠ HULL DAMAGE", col = cautionCol, blink = false})
    end
    
    -- Shield down
    if maxShield > 0 and shield <= 0 then
        table_insert(warnings, {text = "SHIELDS DOWN", col = warningCol, blink = true})
    end
    
    -- Overheated
    if vehicle and vehicle.GetOverheated and vehicle:GetOverheated() then
        table_insert(warnings, {text = "⚠ OVERHEATED", col = warningCol, blink = true})
    end
    
    -- Engine off
    if vehicle and vehicle.GetEngineActive and not vehicle:GetEngineActive() then
        table_insert(warnings, {text = "ENGINE OFFLINE", col = cautionCol, blink = true})
    end
    
    -- Draw warnings
    local startY = cy - 60
    for i, warning in ipairs(warnings) do
        local show = true
        if warning.blink then
            show = math_sin(CurTime() * 6) > 0
        end
        
        if show then
            draw.SimpleText(warning.text, "StarfighterHUD_Small", cx, startY - (i - 1) * 20, GetAlphaColor(warning.col), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

-- ============================================================================
-- WEAPON INFO (top-right ammo/weapon display)
-- ============================================================================

local function DrawWeaponInfo(x, y, vehicle)
    local col = SHUD.Colors and SHUD.Colors.HUDGreen or Color(0, 255, 100, 200)
    local dimCol = SHUD.Colors and SHUD.Colors.HUDGreenDim or Color(0, 180, 70, 120)
    local bgCol = SHUD.Colors and SHUD.Colors.HUDBackground or Color(0, 0, 0, 80)
    
    if not vehicle.GetAmmo then return end
    
    local ammo = vehicle:GetAmmo() or 0
    local maxAmmo = vehicle.MaxPrimaryAmmo or 0
    
    local w, h = 120, 45
    
    -- Background
    draw.RoundedBox(0, x - w/2, y, w, h, GetAlphaColor(bgCol))
    
    -- Ammo
    draw.SimpleText("AMMO", "StarfighterHUD_Tiny", x, y + 6, GetAlphaColor(dimCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    local ammoCol = col
    if maxAmmo > 0 then
        local ammoFrac = ammo / maxAmmo
        if ammoFrac < 0.15 then
            ammoCol = Color(255, 50, 50, 200 + math_sin(CurTime() * 6) * 55)
        elseif ammoFrac < 0.3 then
            ammoCol = Color(255, 200, 0, 200)
        end
    end
    
    draw.SimpleText(FormatNumber(ammo), "StarfighterHUD_Medium", x, y + 22, GetAlphaColor(ammoCol), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

-- ============================================================================
-- MAIN HUD PAINT HOOK
-- ============================================================================

local function GetPlayerVehicle(ply)
    local pod = ply:GetVehicle()
    if not IsValid(pod) then return nil end
    
    -- Direct LVS vehicle
    local parent = pod:GetParent()
    if IsValid(parent) then
        if parent.LVS then return parent end
        
        -- Check grandparent (pod might be in a turret entity)
        local grandparent = parent:GetParent()
        if IsValid(grandparent) and grandparent.LVS then
            return grandparent
        end
    end
    
    -- Check via LVS method
    if pod.lvsGetVehicle then
        local veh = pod:lvsGetVehicle()
        if IsValid(veh) then return veh end
    end
    
    return nil
end

hook.Add("HUDPaint", "StarfighterHUD_Main", function()
    if not cv_enabled:GetBool() then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local vehicle = GetPlayerVehicle(ply)
    if not IsValid(vehicle) then return end
    
    -- Check if this is an LVS vehicle
    if not vehicle.LVS then return end
    
    local isFirstPerson = not ply:ShouldDrawLocalPlayer()
    
    -- "debe tener su modo en primera persona" -> Solo renderizar este HUD cuando estemos dentro de la cabina
    if not isFirstPerson then return end
    
    local sw, sh = ScrW(), ScrH()
    local cx, cy = sw / 2, sh / 2
    
    -- Parallax effect based on eye movement vs vehicle movement
    if isFirstPerson then
        local eyeAng = ply:EyeAngles()
        local vehAng = vehicle:GetAngles()
        local pDiff = math.AngleDifference(eyeAng.p, vehAng.p)
        local yDiff = math.AngleDifference(eyeAng.y, vehAng.y)
        
        -- Smooth parallax
        vehicle.sm_paraX = SmoothApproach(vehicle.sm_paraX or 0, yDiff * 4, 10)
        vehicle.sm_paraY = SmoothApproach(vehicle.sm_paraY or 0, pDiff * 4, 10)
        
        local px = math.Clamp(vehicle.sm_paraX, -sw*0.1, sw*0.1)
        local py = math.Clamp(vehicle.sm_paraY, -sh*0.1, sh*0.1)
        
        cx = cx - px
        cy = cy + py
    end
    
    -- Update animations
    animPulse = CurTime()
    animBracket = math_sin(CurTime() * 2) * 3
    
    -- Get vehicle data
    local vel = vehicle:GetVelocity()
    local speed = vel:Length()
    local altitude = vehicle:GetPos().z
    local angles = vehicle:GetAngles()
    local pitch = angles.p
    local roll = angles.r
    local yaw = angles.y
    
    local health = vehicle:Health() or 0
    local maxHealth = vehicle:GetMaxHealth() or 1
    
    -- Try LVS-specific health methods
    if vehicle.GetHP then health = vehicle:GetHP() end
    if vehicle.MaxHealth then maxHealth = vehicle.MaxHealth end
    
    local shield = 0
    local maxShield = 0
    if vehicle.GetShield then shield = vehicle:GetShield() or 0 end
    if vehicle.MaxShield then maxShield = vehicle.MaxShield or 0 end
    
    local throttle = 0
    if vehicle.GetThrottle then throttle = vehicle:GetThrottle() or 0 end
    
    local heat = 0
    if vehicle.GetHeat then heat = vehicle:GetHeat() or 0 end
    
    -- Smooth values
    sm_speed = SmoothApproach(sm_speed, speed, 8)
    sm_alt = SmoothApproach(sm_alt, altitude, 8)
    
    -- ===== DRAW ALL HUD COMPONENTS =====
    
    if not cv_minimal:GetBool() then
        -- Compass (top center)
        DrawCompass(cx, sh * 0.05, yaw)
        
        -- Artificial horizon (center)
        DrawHorizon(cx, cy, pitch, roll)
        
        -- Speed indicator (left)
        DrawSpeedIndicator(sw * 0.12, cy, sm_speed, vehicle)
        
        -- Altitude indicator (right)
        DrawAltitudeIndicator(sw * 0.88, cy, sm_alt, vehicle)
        
        -- Throttle gauge (far left)
        DrawThrottleGauge(sw * 0.04, cy + 30, throttle, vehicle)
        
        -- Weapon info (top right)
        DrawWeaponInfo(sw * 0.88, sh * 0.05, vehicle)
    end
    
    -- Status bars (bottom center) - always shown
    DrawStatusBars(cx, sh * 0.88, health, maxHealth, shield, maxShield, heat)
    
    -- Center crosshair
    DrawCenterCrosshair(cx, cy)
    
    -- Warnings
    DrawWarnings(cx, sh * 0.78, health, maxHealth, shield, maxShield, vehicle)
    
    -- ===== TARGET TRACKING =====
    if cv_tracking:GetBool() then
        -- Scan for nearby targets
        local myPos = vehicle:GetPos()
        local myForward = vehicle:GetForward()
        local trackRange = 15000
        
        -- Find trackable entities
        local nearbyEnts = ents.FindInSphere(myPos, trackRange)
        local targets = {}
        
        for _, ent in ipairs(nearbyEnts) do
            if ent == vehicle then continue end
            if not IsValid(ent) then continue end
            
            -- Track LVS vehicles
            if ent.LVS then
                table_insert(targets, ent)
                continue
            end
            
            -- Track NPCs
            if ent:IsNPC() and ent:Health() > 0 then
                table_insert(targets, ent)
                continue
            end
            
            -- Track players in vehicles (not same vehicle)
            if ent:IsPlayer() and ent ~= ply then
                local theirVeh = GetPlayerVehicle(ent)
                if IsValid(theirVeh) and theirVeh.LVS and theirVeh ~= vehicle then
                    -- Don't double-track; the vehicle itself will be tracked
                end
            end
        end
        
        -- Sort by distance
        table_sort(targets, function(a, b)
            return myPos:DistToSqr(a:GetPos()) < myPos:DistToSqr(b:GetPos())
        end)
        
        -- Limit displayed targets
        local maxTargets = SHUD.MaxTargets or 12
        
        -- Draw brackets for each target
        for i = 1, math.min(#targets, maxTargets) do
            DrawTargetBracket(targets[i], vehicle)
        end
        
        -- Draw lead indicator for locked target
        if LockAcquired and IsValid(LockedTarget) then
            DrawLeadIndicator(vehicle, LockedTarget)
        end
    end
end)

-- ============================================================================
-- TARGET LOCK INPUT SYSTEM
-- ============================================================================

hook.Add("Think", "StarfighterHUD_LockSystem", function()
    if not cv_enabled:GetBool() then return end
    if not cv_tracking:GetBool() then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local vehicle = GetPlayerVehicle(ply)
    if not IsValid(vehicle) then
        -- Clear lock when exiting vehicle
        if LockedTarget then
            LockedTarget = nil
            LockAcquired = false
            IsLocking = false
        end
        return
    end
    
    -- Validate current locked target
    if IsValid(LockedTarget) then
        local dist = vehicle:GetPos():Distance(LockedTarget:GetPos())
        if dist > 20000 or (LockedTarget.Health and LockedTarget:Health() <= 0) then
            LockedTarget = nil
            LockAcquired = false
            IsLocking = false
        end
    end
    
    -- Update lock progress
    if IsLocking and IsValid(LockedTarget) then
        local lockTime = SHUD.LockTime or 1.5
        local elapsed = CurTime() - LockStartTime
        sm_lockProgress = SmoothApproach(sm_lockProgress, elapsed / lockTime, 10)
        
        if elapsed >= lockTime then
            LockAcquired = true
            IsLocking = false
            surface.PlaySound("buttons/button17.wav")
        end
    else
        sm_lockProgress = SmoothApproach(sm_lockProgress, 0, 5)
    end
end)

-- Key binding for target lock
hook.Add("PlayerButtonDown", "StarfighterHUD_LockKey", function(ply, button)
    if ply ~= LocalPlayer() then return end
    if not cv_enabled:GetBool() then return end
    
    local lockKey = cv_lockkey:GetInt()
    if button ~= lockKey then return end
    
    local vehicle = GetPlayerVehicle(ply)
    if not IsValid(vehicle) then return end
    
    -- If already locked, unlock
    if LockAcquired then
        LockedTarget = nil
        LockAcquired = false
        IsLocking = false
        surface.PlaySound("buttons/button18.wav")
        return
    end
    
    -- Find nearest target in front cone
    local myPos = vehicle:GetPos()
    local myForward = vehicle:GetForward()
    local lockRange = 20000
    local lockCone = math_cos(math_rad(SHUD.TrackingCone or 30))
    
    local nearbyEnts = ents.FindInSphere(myPos, lockRange)
    local bestTarget = nil
    local bestDot = lockCone
    
    for _, ent in ipairs(nearbyEnts) do
        if ent == vehicle then continue end
        if not IsValid(ent) then continue end
        if not ent.LVS and not ent:IsNPC() then continue end
        
        local dir = (ent:GetPos() - myPos):GetNormalized()
        local dot = myForward:Dot(dir)
        
        if dot > bestDot then
            bestDot = dot
            bestTarget = ent
        end
    end
    
    if IsValid(bestTarget) then
        LockedTarget = bestTarget
        LockStartTime = CurTime()
        IsLocking = true
        LockAcquired = false
        surface.PlaySound("buttons/button15.wav")
    end
end)

-- ============================================================================
-- HIDE DEFAULT HUD ELEMENTS WHEN IN LVS VEHICLE
-- ============================================================================

hook.Add("HUDShouldDraw", "StarfighterHUD_HideDefault", function(name)
    if not cv_enabled:GetBool() then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local vehicle = GetPlayerVehicle(ply)
    if not IsValid(vehicle) or not vehicle.LVS then return end
    
    local lName = string.lower(name)
    
    -- Excepciones: build (ej: gmod build text, hud custom) y dinero (DarkRP_Money)
    if string.find(lName, "money") or string.find(lName, "build") or name == "CHudGMod" or name == "CHudChat" then
        return
    end
    
    return false
end)

-- ============================================================================
-- DAMAGE FLASH EFFECT
-- ============================================================================

local lastHealth = 0

hook.Add("HUDPaint", "StarfighterHUD_DamageFlash", function()
    if not cv_enabled:GetBool() then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local vehicle = GetPlayerVehicle(ply)
    if not IsValid(vehicle) or not vehicle.LVS then return end
    
    local health = vehicle:Health() or 0
    if vehicle.GetHP then health = vehicle:GetHP() end
    
    if health < lastHealth then
        damageFlash = 0.8
        lastDamageTime = CurTime()
    end
    lastHealth = health
    
    -- Draw red flash overlay
    if damageFlash > 0.01 then
        damageFlash = damageFlash - RealFrameTime() * 2
        local alpha = math_clamp(damageFlash * 100, 0, 60)
        surface.SetDrawColor(255, 0, 0, alpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
end)

-- ============================================================================
-- CONSOLE COMMANDS
-- ============================================================================

concommand.Add("starfighter_hud_toggle", function()
    cv_enabled:SetBool(not cv_enabled:GetBool())
    if cv_enabled:GetBool() then
        print("[StarfighterHUD] HUD Enabled")
    else
        print("[StarfighterHUD] HUD Disabled")
    end
end)

concommand.Add("starfighter_hud_minimal_toggle", function()
    cv_minimal:SetBool(not cv_minimal:GetBool())
    if cv_minimal:GetBool() then
        print("[StarfighterHUD] Minimal mode ON")
    else
        print("[StarfighterHUD] Minimal mode OFF")
    end
end)

print("[StarfighterHUD] Client-side HUD loaded - v" .. (SHUD.Version or "1.0.0"))
