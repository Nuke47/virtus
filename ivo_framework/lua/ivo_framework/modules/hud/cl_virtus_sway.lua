_G.VirtusSway = _G.VirtusSway or {}

local swayX, swayY = 0, 0
local smoothedVelocity = 0

-- Sistema de retroceso del HUD al disparar y recibir daño
local recoilX, recoilY = 0, 0
local lastClip = -1
local lastHealth = -1

hook.Add("Think", "Virtus_HUDSway_Calc", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local ang = ply:EyeAngles()
    if not ply.lastCamAng then ply.lastCamAng = ang end
    
    -- Prevenir latigazos visuales al respawnear o revivir
    local isAlive = ply:Alive()
    if not isAlive then
        ply.virtus_wasDead = true
        swayX, swayY = 0, 0
        ply.lastCamAng = ang
    elseif ply.virtus_wasDead then
        ply.virtus_wasDead = false
        swayX, swayY = 0, 0
        ply.lastCamAng = ang
    end
    
    -- Detectar disparos: si el clip bajó, el jugador disparó
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep.Clip1 then
        local clip = wep:Clip1()
        if lastClip >= 0 and clip < lastClip then
            local shots = lastClip - clip
            recoilY = recoilY - math.Rand(2, 5) * shots
            recoilX = recoilX + math.Rand(-1.5, 1.5) * shots
        end
        lastClip = clip
    else
        lastClip = -1
    end
    
    -- Detectar daño (balazos, caídas, explosiones)
    local hp = ply:Health()
    if lastHealth >= 0 and hp < lastHealth then
        local dmg = lastHealth - hp
        local shake = math.Clamp(dmg * 0.6, 5, 25) -- Mientras más daño, más tiembla (tope de 25px)
        recoilX = recoilX + math.Rand(-shake, shake)
        recoilY = recoilY + math.Rand(-shake, shake)
    end
    lastHealth = hp
    
    local diff = ang - ply.lastCamAng
    diff:Normalize()
    
    local speed = ply:GetVelocity():Length()
    if not ply:IsOnGround() then speed = 0 end
    smoothedVelocity = Lerp(FrameTime() * 5, smoothedVelocity, speed)
    
    -- Bobbing effect based on velocity
    local bobX = math.sin(CurTime() * 8) * (smoothedVelocity / 150) * 1.5
    local bobY = math.cos(CurTime() * 16) * (smoothedVelocity / 150) * 1.5
    
    swayX = Lerp(FrameTime() * 8, swayX, math.Clamp(diff.yaw * 2.5, -50, 50) + bobX)
    swayY = Lerp(FrameTime() * 8, swayY, math.Clamp(diff.pitch * 2.5, -50, 50) + bobY)
    
    -- Aplicar retroceso DIRECTAMENTE al sway (no al target del Lerp)
    swayX = swayX + recoilX
    swayY = swayY + recoilY
    
    -- El retroceso se disipa rápidamente
    recoilX = Lerp(FrameTime() * 15, recoilX, 0)
    recoilY = Lerp(FrameTime() * 15, recoilY, 0)
    
    ply.lastCamAng = ang
end)

local workMat = Matrix()
local vecTrans = Vector(0, 0, 0)
local vecPivot = Vector(0, 0, 0)
local vecNegPivot = Vector(0, 0, 0)
local angRot = Angle(0, 0, 0)

CreateClientConVar("virtus_hud_3d", "1", true, false)

function _G.VirtusSway.Begin3D(rotation, px, py)
    if not GetConVar("virtus_hud_3d"):GetBool() then return end
    
    workMat:Identity()
    px = px or (ScrW() / 2)
    py = py or (ScrH() / 2)
    
    -- Inercia 2D
    vecTrans.x = swayX
    vecTrans.y = swayY
    workMat:Translate(vecTrans)
    
    -- Mover al pivot
    vecPivot.x = px
    vecPivot.y = py
    workMat:Translate(vecPivot)
    
    -- Rotar/Sesgar sobre el pivot
    if rotation and rotation ~= 0 then
        angRot.y = rotation
        workMat:SetAngles(angRot)
    end
    
    -- Volver del pivot
    vecNegPivot.x = -px
    vecNegPivot.y = -py
    workMat:Translate(vecNegPivot)
    
    cam.PushModelMatrix(workMat)
end

function _G.VirtusSway.End3D()
    if not GetConVar("virtus_hud_3d"):GetBool() then return end
    cam.PopModelMatrix()
end
