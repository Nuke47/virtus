include("shared.lua")

-- =========================================================================
-- CONFIGURACIÓN VISUAL
-- =========================================================================
local PROBE_BOB_SPEED  = 1.5
local PROBE_BOB_HEIGHT = 2.0

-- Fuentes del HUD
surface.CreateFont("ProbeHUD_Title", { font = "Roboto", size = 22, weight = 800, antialias = true })
surface.CreateFont("ProbeHUD_Text",  { font = "Roboto", size = 16, weight = 600, antialias = true })
surface.CreateFont("ProbeHUD_Small", { font = "Roboto", size = 13, weight = 500, antialias = true })
surface.CreateFont("ProbeHUD_Large", { font = "Roboto", size = 28, weight = 800, antialias = true })

local scannedTargets = {}
local scanExpireTime = 0

-- =========================================================================
-- RENDERIZADO
-- =========================================================================
function ENT:Draw()
    local bobOffset = math.sin(CurTime() * PROBE_BOB_SPEED) * PROBE_BOB_HEIGHT
    local pos = self:GetPos()
    self:SetRenderOrigin(pos + Vector(0, 0, bobOffset))
    self:DrawModel()
    self:SetRenderOrigin(nil)
end

-- Luz dinámica para sondas no vinculadas (parpadeo verde)
function ENT:Think()
    if not self:GetProbeLinked() then
        local lp = LocalPlayer()
        if IsValid(lp) and lp:GetPos():DistToSqr(self:GetPos()) < 500 * 500 then
            local dlight = DynamicLight(self:EntIndex())
            if dlight then
                local pulse = math.abs(math.sin(CurTime() * 2)) * 0.5 + 0.5
                dlight.pos = self:GetPos() + Vector(0, 0, -10)
                dlight.r = 0
                dlight.g = math.floor(200 * pulse)
                dlight.b = math.floor(80 * pulse)
                dlight.brightness = 0.5 + pulse * 0.5
                dlight.Decay = 1000
                dlight.Size = 100
                dlight.DieTime = CurTime() + 0.1
            end
        end
    end
end

-- =========================================================================
-- SISTEMA DE CONTROL EN PRIMERA PERSONA
-- =========================================================================
local isControlling   = false
local controlledProbe = nil
local probeViewAngles = Angle(0, 0, 0)
local inputSendRate   = 0.05
local nextInputSend   = 0
local scanLineY       = 0

local playerOriginalAngles = Angle(0, 0, 0)
local old_virtus_hide_hud = nil

-- ─── Entrar al control ───────────────────────────────────────────────────
local function StartProbeControl(probe)
    if not IsValid(probe) then return end
    isControlling = true
    controlledProbe = probe
    probeViewAngles = probe:GetAngles()
    probeViewAngles.p = 0
    probeViewAngles.r = 0
    playerOriginalAngles = LocalPlayer():EyeAngles()
    
    local cv = GetConVar("virtus_hide_hud")
    if cv then
        old_virtus_hide_hud = cv:GetString()
        RunConsoleCommand("virtus_hide_hud", "1")
    end
    
    surface.PlaySound("lvs/vehicles/clone_attack_drone/start_up_1.wav")
end

-- ─── Salir del control ──────────────────────────────────────────────────
local function StopProbeControl()
    if not isControlling then return end
    isControlling = false
    controlledProbe = nil
    
    if old_virtus_hide_hud ~= nil then
        RunConsoleCommand("virtus_hide_hud", old_virtus_hide_hud)
        old_virtus_hide_hud = nil
    end
    
    surface.PlaySound("lvs/vehicles/clone_attack_drone/power_down_1.wav")
    net.Start("Probe_StopControl")
    net.SendToServer()
end

-- Net: Servidor fuerza salida
net.Receive("Probe_ForceExit", function()
    StopProbeControl()
end)

-- Net: Servidor confirma inicio de control
net.Receive("Probe_StartControl", function()
    local probe = net.ReadEntity()
    if IsValid(probe) then
        StartProbeControl(probe)
    end
end)

-- =========================================================================
-- INPUT: WASD + Mouse
-- =========================================================================
hook.Add("CreateMove", "ProbeDroid_CreateMove", function(cmd)
    if not isControlling or not IsValid(controlledProbe) then return end

    local mx = cmd:GetMouseX()
    local my = cmd:GetMouseY()
    local sens = 0.04

    probeViewAngles.y = probeViewAngles.y - mx * sens
    probeViewAngles.p = math.Clamp(probeViewAngles.p + my * sens, -60, 60)
    probeViewAngles.r = 0

    local moveForward, moveRight, moveUp = 0, 0, 0
    if cmd:KeyDown(IN_FORWARD)   then moveForward = 1 end
    if cmd:KeyDown(IN_BACK)      then moveForward = moveForward - 1 end
    if cmd:KeyDown(IN_MOVERIGHT) then moveRight = 1 end
    if cmd:KeyDown(IN_MOVELEFT)  then moveRight = moveRight - 1 end
    if cmd:KeyDown(IN_JUMP)      then moveUp = 1 end
    if cmd:KeyDown(IN_DUCK)      then moveUp = moveUp - 1 end

    local mult = cmd:KeyDown(IN_SPEED) and 2 or 1
    moveForward = moveForward * mult
    moveRight = moveRight * mult
    moveUp = moveUp * mult

    if cmd:KeyDown(IN_ATTACK) then
        if not controlledProbe.NextClientScan or CurTime() > controlledProbe.NextClientScan then
            controlledProbe.NextClientScan = CurTime() + 5
            net.Start("Probe_DoScan")
            net.SendToServer()
        end
    end

    if CurTime() >= nextInputSend then
        nextInputSend = CurTime() + inputSendRate
        net.Start("Probe_InputUpdate")
            net.WriteFloat(moveForward)
            net.WriteFloat(moveRight)
            net.WriteFloat(moveUp)
            net.WriteAngle(probeViewAngles)
        net.SendToServer()
    end

    -- Evitar que el cuerpo del jugador se mueva o cambie de dirección
    cmd:ClearMovement()
    cmd:ClearButtons()
    cmd:SetViewAngles(playerOriginalAngles)
end)

-- =========================================================================
-- CALCVIEW: Cámara FPV
-- =========================================================================
hook.Add("CalcView", "ProbeDroid_CalcView", function(ply, pos, angles, fov)
    if not isControlling or not IsValid(controlledProbe) then return end
    return {
        origin     = controlledProbe:GetPos() + Vector(0, 0, 45),
        angles     = probeViewAngles,
        fov        = 90,
        drawviewer = true,
    }
end)

hook.Add("ShouldDrawLocalPlayer", "ProbeDroid_DrawPlayer", function(ply)
    if isControlling and IsValid(controlledProbe) then return false end
end)

-- =========================================================================
-- HUD OVERLAY
-- =========================================================================
hook.Add("HUDPaint", "ProbeDroid_HUD", function()
    if not isControlling or not IsValid(controlledProbe) then return end

    local scrW, scrH = ScrW(), ScrH()
    local probe = controlledProbe
    local owner = LocalPlayer()
    local probePos = probe:GetPos()
    local probeHP = probe:Health()
    local probeMaxHP = probe:GetMaxHealth()
    local dist = probePos:Distance(owner:GetPos())
    local alt = probePos.z - owner:GetPos().z

    -- Vignette
    local vig = 120
    surface.SetDrawColor(0, 0, 0, 180)
    surface.DrawRect(0, 0, scrW, vig)
    surface.DrawRect(0, scrH - vig, scrW, vig)
    surface.DrawRect(0, 0, vig, scrH)
    surface.DrawRect(scrW - vig, 0, vig, scrH)

    -- Grid
    surface.SetDrawColor(0, 255, 100, 8)
    for i = 0, scrH, 40 do surface.DrawLine(0, i, scrW, i) end
    for i = 0, scrW, 40 do surface.DrawLine(i, 0, i, scrH) end

    -- Línea de escaneo
    scanLineY = (scanLineY + FrameTime() * 200) % scrH
    surface.SetDrawColor(0, 255, 100, 40)
    surface.DrawRect(0, scanLineY, scrW, 2)
    surface.SetDrawColor(0, 255, 100, 15)
    surface.DrawRect(0, scanLineY - 20, scrW, 20)

    -- Esquinas
    local cLen, cThick, cIn = 60, 2, 50
    surface.SetDrawColor(0, 255, 100, 200)
    surface.DrawRect(cIn, cIn, cLen, cThick)
    surface.DrawRect(cIn, cIn, cThick, cLen)
    surface.DrawRect(scrW - cIn - cLen, cIn, cLen, cThick)
    surface.DrawRect(scrW - cIn - cThick, cIn, cThick, cLen)
    surface.DrawRect(cIn, scrH - cIn - cThick, cLen, cThick)
    surface.DrawRect(cIn, scrH - cIn - cLen, cThick, cLen)
    surface.DrawRect(scrW - cIn - cLen, scrH - cIn - cThick, cLen, cThick)
    surface.DrawRect(scrW - cIn - cThick, scrH - cIn - cLen, cThick, cLen)

    -- Retícula
    local cx, cy = scrW / 2, scrH / 2
    local r = 25
    local rot = CurTime() * 50
    surface.SetDrawColor(0, 255, 100, 150)
    
    -- Animación de retícula
    local pulseRet = math.abs(math.sin(CurTime() * 4)) * 5 + 5
    surface.DrawLine(cx - r - pulseRet, cy, cx - 8 - pulseRet, cy)
    surface.DrawLine(cx + 8 + pulseRet, cy, cx + r + pulseRet, cy)
    surface.DrawLine(cx, cy - r - pulseRet, cx, cy - 8 - pulseRet)
    surface.DrawLine(cx, cy + 8 + pulseRet, cx, cy + r + pulseRet)
    surface.SetDrawColor(0, 255, 100, 255)
    surface.DrawRect(cx - 1, cy - 1, 3, 3)

    -- Info superior
    draw.SimpleText("DROIDE SONDA V-1X", "ProbeHUD_Title", 70, 70, Color(0, 255, 100))
    
    local isScanningNow = CurTime() <= scanExpireTime
    local modeText = isScanningNow and "MODO ESCANEO ACTIVO" or "MODO RECONOCIMIENTO"
    local modeColor = isScanningNow and Color(255, 50, 50, 200) or Color(0, 200, 80, 150)
    draw.SimpleText(modeText, "ProbeHUD_Small", 70, 95, modeColor)

    local pulse = math.abs(math.sin(CurTime() * 3)) * 100 + 155
    draw.SimpleText("● ENLACE ACTIVO", "ProbeHUD_Text", scrW - 70, 70, Color(0, 255, 100, pulse), TEXT_ALIGN_RIGHT)
    draw.SimpleText(os.date("%H:%M:%S"), "ProbeHUD_Small", scrW - 70, 90, Color(0, 200, 80, 120), TEXT_ALIGN_RIGHT)

    -- Telemetría inferior izquierda
    local bX, bY = 70, scrH - 160
    surface.SetDrawColor(0, 255, 100, 30)
    surface.DrawRect(bX - 5, bY - 5, 220, 95)
    surface.SetDrawColor(0, 255, 100, 80)
    surface.DrawOutlinedRect(bX - 5, bY - 5, 220, 95, 1)

    draw.SimpleText("TELEMETRÍA", "ProbeHUD_Text", bX, bY, Color(0, 255, 100, 200))
    draw.SimpleText("DIST:", "ProbeHUD_Small", bX, bY + 22, Color(0, 200, 80, 150))
    draw.SimpleText(math.floor(dist) .. " u", "ProbeHUD_Text", bX + 40, bY + 20, Color(0, 255, 100))
    draw.SimpleText("ALT:", "ProbeHUD_Small", bX, bY + 42, Color(0, 200, 80, 150))
    draw.SimpleText((alt >= 0 and "+" or "") .. math.floor(alt) .. " u", "ProbeHUD_Text", bX + 35, bY + 40, Color(0, 255, 100))
    draw.SimpleText("VEL:", "ProbeHUD_Small", bX, bY + 62, Color(0, 200, 80, 150))
    draw.SimpleText(math.floor(probe:GetVelocity():Length()) .. " u/s", "ProbeHUD_Text", bX + 35, bY + 60, Color(0, 255, 100))

    -- HP inferior derecha
    local hX, hY = scrW - 280, scrH - 120
    surface.SetDrawColor(0, 255, 100, 30)
    surface.DrawRect(hX, hY, 210, 55)
    surface.SetDrawColor(0, 255, 100, 80)
    surface.DrawOutlinedRect(hX, hY, 210, 55, 1)
    draw.SimpleText("INTEGRIDAD", "ProbeHUD_Text", hX + 5, hY + 2, Color(0, 255, 100, 200))

    local hpFrac = math.Clamp(probeHP / probeMaxHP, 0, 1)
    local barX, barY, barW, barH = hX + 5, hY + 25, 200, 20
    surface.SetDrawColor(0, 50, 20, 100)
    surface.DrawRect(barX, barY, barW, barH)

    local hpColor = hpFrac < 0.3 and Color(255, 50, 50, math.abs(math.sin(CurTime() * 8)) * 200 + 55) or (hpFrac < 0.6 and Color(255, 200, 50) or Color(0, 255, 100))
    surface.SetDrawColor(hpColor)
    surface.DrawRect(barX, barY, barW * hpFrac, barH)

    surface.SetDrawColor(0, 0, 0, 100)
    for i = 1, 9 do surface.DrawRect(barX + (barW / 10) * i, barY, 1, barH) end
    draw.SimpleText(probeHP .. "/" .. probeMaxHP, "ProbeHUD_Small", barX + barW / 2, barY + barH / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Advertencia de rango
    if dist > 2000 then
        local wp = math.abs(math.sin(CurTime() * 6)) * 255
        draw.SimpleText("⚠ LÍMITE DE RANGO", "ProbeHUD_Large", cx, scrH - 200, Color(255, 50, 50, wp), TEXT_ALIGN_CENTER)
        draw.SimpleText("REGRESE AL PERÍMETRO DE OPERACIÓN", "ProbeHUD_Small", cx, scrH - 170, Color(255, 100, 100, wp), TEXT_ALIGN_CENTER)
    end

    draw.SimpleText("[WASD] Mover  |  [SHIFT] Acelerar  |  [ESPACIO/CTRL] Subir/Bajar  |  [CLICK] Escaneo  |  [F] Salir", "ProbeHUD_Small", cx, scrH - 30, Color(0, 200, 80, 150), TEXT_ALIGN_CENTER)
end)

-- Ocultar HUD estándar y personalizado
hook.Add("HUDShouldDraw", "ProbeDroid_HideHUD", function(name)
    if isControlling and IsValid(controlledProbe) then
        -- Permitir el chat
        if name == "CHudChat" or name == "CHudGMod" then return end
        
        -- Retornar false incondicionalmente oculta casi todo (vida, dinero, brújula, CHudX)
        return false
    end
end)

-- F para desconectar
hook.Add("PlayerBindPress", "ProbeDroid_Disconnect", function(ply, bind, pressed)
    if not isControlling or not pressed then return end
    if bind == "+use" then
        StopProbeControl()
        return true
    end
end)

-- =========================================================================
-- API PÚBLICA (para el datapad)
-- =========================================================================
function ProbeDroid_IsControlling()
    return isControlling
end

function ProbeDroid_GetControlledProbe()
    return controlledProbe
end

function ProbeDroid_StartControl(probe)
    net.Start("Probe_StartControl")
    net.WriteEntity(probe)
    net.SendToServer()
end

function ProbeDroid_StopControl()
    StopProbeControl()
end

-- =========================================================================
-- SISTEMA DE ESCANEO (CLIENTE)
-- =========================================================================

net.Receive("Probe_ScanResults", function()
    local count = net.ReadUInt(16)
    scannedTargets = {}
    for i = 1, count do
        local ent = net.ReadEntity()
        if IsValid(ent) then
            table.insert(scannedTargets, ent)
        end
    end
    scanExpireTime = net.ReadFloat()
    surface.PlaySound("buttons/bell1.wav")
end)

hook.Add("PreDrawHalos", "Probe_ScanHalos", function()
    if CurTime() > scanExpireTime then return end
    local validTargets = {}
    for _, v in ipairs(scannedTargets) do
        if IsValid(v) then table.insert(validTargets, v) end
    end
    if #validTargets > 0 then
        halo.Add(validTargets, Color(255, 50, 50), 2, 2, 2, true, true)
    end
end)

hook.Add("HUDPaint", "Probe_ScanMarkers", function()
    if CurTime() > scanExpireTime then return end
    
    -- No dibujar marcadores si estamos en primera persona controlando el dron (ya tienen HUD del dron para eso si queremos, aunque no hace daño, pero es mejor para los de a pie)
    -- Bueno, en realidad sí es útil para el que controla el dron.
    for _, v in ipairs(scannedTargets) do
        if IsValid(v) then
            local pos = (v:GetPos() + Vector(0,0,50)):ToScreen()
            if pos.visible then
                surface.SetDrawColor(255, 50, 50, 200)
                local s = 15
                surface.DrawLine(pos.x - s, pos.y - s, pos.x - s/2, pos.y - s)
                surface.DrawLine(pos.x - s, pos.y - s, pos.x - s, pos.y - s/2)
                
                surface.DrawLine(pos.x + s, pos.y - s, pos.x + s/2, pos.y - s)
                surface.DrawLine(pos.x + s, pos.y - s, pos.x + s, pos.y - s/2)
                
                surface.DrawLine(pos.x - s, pos.y + s, pos.x - s/2, pos.y + s)
                surface.DrawLine(pos.x - s, pos.y + s, pos.x - s, pos.y + s/2)
                
                surface.DrawLine(pos.x + s, pos.y + s, pos.x + s/2, pos.y + s)
                surface.DrawLine(pos.x + s, pos.y + s, pos.x + s, pos.y + s/2)
                
                draw.SimpleText("OBJETIVO", "ProbeHUD_Small", pos.x, pos.y - s - 10, Color(255, 50, 50, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                
                -- Distancia
                local dist = LocalPlayer():GetPos():Distance(v:GetPos())
                draw.SimpleText(math.floor(dist) .. " u", "ProbeHUD_Small", pos.x, pos.y + s + 5, Color(255, 50, 50, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end
    end
end)
