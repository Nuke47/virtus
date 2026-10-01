AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- =========================================================================
-- CONFIGURACIÓN
-- =========================================================================
local PROBE_MODEL        = "models/starwars/syphadias/ships/probe_droid/probe_droid.mdl"
local PROBE_HP           = 250
local PROBE_SPEED        = 800 -- Aumentado de 320
local PROBE_MAX_RANGE    = 2500
local PROBE_HOVER_HEIGHT = 45

local HOVER_SOUND = "vehicle/probe_droid/probe_droid_hover_loop.wav"
local CHAT_SOUNDS = {
    "vehicle/probe_droid/probe_droid_chat_1.wav",
    "vehicle/probe_droid/probe_droid_chat_2.wav",
    "vehicle/probe_droid/probe_droid_chat_3.wav",
    "vehicle/probe_droid/probe_droid_chat_4.wav",
    "vehicle/probe_droid/probe_droid_chat_5.wav",
    "vehicle/probe_droid/probe_droid_chat_6.wav",
    "vehicle/probe_droid/probe_droid_chat_7.wav",
}
local STARTUP_SOUNDS = {
    "lvs/vehicles/clone_attack_drone/start_up_1.wav",
    "lvs/vehicles/clone_attack_drone/start_up_6.wav",
    "lvs/vehicles/clone_attack_drone/start_up_7.wav",
}
local POWERDOWN_SOUNDS = {
    "lvs/vehicles/clone_attack_drone/power_down_1.wav",
    "lvs/vehicles/clone_attack_drone/power_down_2.wav",
    "lvs/vehicles/clone_attack_drone/power_down_3.wav",
}

-- =========================================================================
-- INICIALIZACIÓN
-- =========================================================================
function ENT:Initialize()
    self:SetModel(PROBE_MODEL)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(30)
        phys:EnableGravity(false)
        phys:SetDamping(2, 2) -- Reducido de 8 para mayor movilidad
        phys:SetBuoyancyRatio(0)
    end

    self:SetHealth(PROBE_HP)
    self:SetMaxHealth(PROBE_HP)

    -- Estado inicial: flotando, sin vincular
    self:SetProbeActive(true)
    self:SetProbeControlled(false)
    self:SetProbeLinked(false)

    -- Movimiento
    self.MoveForward = 0
    self.MoveRight   = 0
    self.MoveUp      = 0
    self.AimAngles   = self:GetAngles()

    -- Sonido de inicio
    self:EmitSound(STARTUP_SOUNDS[math.random(#STARTUP_SOUNDS)], 70, 100, 0.4) -- Volumen bajado

    -- Hover loop
    self.HoverSound = CreateSound(self, HOVER_SOUND)
    if self.HoverSound then
        self.HoverSound:Play()
        self.HoverSound:ChangeVolume(0.15, 0.5) -- Volumen bajado
        self.HoverSound:ChangePitch(95, 0.5)
    end

    self.NextChatTime = CurTime() + math.random(8, 20)
end

-- =========================================================================
-- THINK
-- =========================================================================
function ENT:Think()
    if not self:GetProbeActive() then return end

    local phys = self:GetPhysicsObject()
    if not IsValid(phys) then return end

    -- Charla aleatoria
    if CurTime() >= self.NextChatTime then
        self:EmitSound(CHAT_SOUNDS[math.random(#CHAT_SOUNDS)], 65, math.random(90, 110), 0.2)
        self.NextChatTime = CurTime() + math.random(10, 30)
    end

    -- Movimiento cuando está controlado
    if self:GetProbeControlled() and IsValid(self:GetProbeOwner()) then
        local owner = self:GetProbeOwner()
        local ang = self.AimAngles or self:GetAngles()

        -- Verificar rango
        local dist = self:GetPos():Distance(owner:GetPos())
        if dist > PROBE_MAX_RANGE then
            local dirBack = (owner:GetPos() - self:GetPos()):GetNormalized()
            phys:ApplyForceCenter(dirBack * phys:GetMass() * 200)
        else
            -- Aplicar input
            local horizForward = Vector(ang:Forward().x, ang:Forward().y, 0):GetNormalized()
            local horizRight   = Vector(ang:Right().x, ang:Right().y, 0):GetNormalized()
            local up = Vector(0, 0, 1)

            local moveDir = horizForward * (self.MoveForward or 0) + horizRight * (self.MoveRight or 0) + up * (self.MoveUp or 0)
            local speedMult = moveDir:Length() > 1.5 and 2 or 1

            if moveDir:LengthSqr() > 0 then
                moveDir:Normalize()
                phys:ApplyForceCenter(moveDir * phys:GetMass() * PROBE_SPEED * speedMult)
            else
                local vel = phys:GetVelocity()
                phys:ApplyForceCenter(-vel * phys:GetMass() * 2)
            end
        end

        -- Rotación yaw
        local curAng = self:GetAngles()
        local newAng = Angle(0, math.ApproachAngle(curAng.y, ang.y, FrameTime() * 200), 0)
        phys:SetAngles(newAng)

        -- Prevenir suelo
        local floorTr = util.TraceLine({
            start = self:GetPos(),
            endpos = self:GetPos() - Vector(0, 0, 30),
            filter = self
        })
        if floorTr.Hit then
            phys:ApplyForceCenter(Vector(0, 0, phys:GetMass() * 300))
        end
    else
        -- Auto-hover cuando no está controlado (suave y sin temblores)
        local tr = util.TraceLine({
            start = self:GetPos(),
            endpos = self:GetPos() - Vector(0, 0, 1000),
            filter = self
        })
        if tr.Hit then
            local targetZ = tr.HitPos.z + PROBE_HOVER_HEIGHT
            local currentZ = self:GetPos().z
            local diff = targetZ - currentZ
            
            local vel = phys:GetVelocity()
            
            -- Usar SetVelocity en Z elimina la oscilación elástica de las fuerzas
            local targetVelZ = math.Clamp(diff * 3, -40, 40)
            
            -- Frenar gradualmente el movimiento X, Y
            local newVelX = math.Approach(vel.x, 0, FrameTime() * 150)
            local newVelY = math.Approach(vel.y, 0, FrameTime() * 150)
            
            phys:SetVelocity(Vector(newVelX, newVelY, targetVelZ))
        else
            -- Si está muy alto y no detecta suelo, dejar que caiga suavemente
            local vel = phys:GetVelocity()
            local newVelX = math.Approach(vel.x, 0, FrameTime() * 100)
            local newVelY = math.Approach(vel.y, 0, FrameTime() * 100)
            phys:SetVelocity(Vector(newVelX, newVelY, -30))
        end
    end

    -- Límite de velocidad
    local vel = phys:GetVelocity()
    local maxSpeed = PROBE_SPEED * 1.5
    if vel:Length() > maxSpeed then
        phys:SetVelocity(vel:GetNormalized() * maxSpeed)
    end

    self:NextThink(CurTime())
    return true
end

-- =========================================================================
-- DAÑO Y DESTRUCCIÓN
-- =========================================================================
function ENT:OnTakeDamage(dmg)
    self:SetHealth(self:Health() - dmg:GetDamage())
    if self:Health() <= 0 then
        self:ProbeDestroy()
    end
end

function ENT:ProbeDestroy()
    local owner = self:GetProbeOwner()

    local ef = EffectData()
    ef:SetOrigin(self:GetPos())
    ef:SetScale(2)
    util.Effect("Explosion", ef)

    self:EmitSound(POWERDOWN_SOUNDS[math.random(#POWERDOWN_SOUNDS)], 75, 100, 0.4)

    if IsValid(owner) then
        net.Start("Probe_ForceExit")
        net.Send(owner)
        owner.LinkedProbe = nil
        owner.ActiveProbeDroid = nil
    end

    SafeRemoveEntity(self)
end

-- =========================================================================
-- LIMPIEZA
-- =========================================================================
function ENT:OnRemove()
    if self.HoverSound then
        self.HoverSound:Stop()
    end

    local owner = self:GetProbeOwner()
    if IsValid(owner) then
        if owner.LinkedProbe == self then
            owner.LinkedProbe = nil
        end
        if owner.ActiveProbeDroid == self then
            owner.ActiveProbeDroid = nil
        end
        net.Start("Probe_ForceExit")
        net.Send(owner)
    end
end
