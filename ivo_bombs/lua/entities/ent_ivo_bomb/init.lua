--[[
    ivo_bombs - Entidad Bomba (Server)
    Temporizador, explosión, beeps, Use → desactivación con SWEP
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local BOMB_MODEL      = "models/props_c17/oildrum001.mdl"
local BEEP_SOUND      = "buttons/button17.wav"
local EXPLOSION_SOUND = "ambient/explosions/explode_4.wav"
local DEFUSE_SOUND    = "buttons/button9.wav"
local ARM_SOUND       = "buttons/button3.wav"

function ENT:Initialize()
    self:SetModel(BOMB_MODEL)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    self:SetColor(Color(200, 50, 50))
    self:SetMaterial("models/debug/debugwhite")

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(50)
    end

    -- Dificultad (puede ser establecida antes de Spawn por el spawner)
    local diff = self:GetDifficulty()
    if diff < 1 or diff > 4 then diff = 1 end
    self:SetDifficulty(diff)

    local config = IVO_BOMBS.Difficulties[diff]
    local bombTime = config and config.bombTime or 60

    -- Semilla aleatoria para los puzzles
    self:SetSeed(math.random(1, 2147483647))

    -- Estado
    self:SetArmed(true)
    self:SetDefused(false)
    self:SetStrikeCount(0)
    self:SetModulesSolved(0)
    self:SetDetonateTime(CurTime() + bombTime)

    self:EmitSound(ARM_SOUND, 75, 100, 1, CHAN_ITEM)

    -- Anunciar
    local diffName = config and config.name or "?"
    for _, ply in ipairs(player.GetAll()) do
        ply:ChatPrint("[BOMBA] ¡Bomba colocada! Dificultad: " .. diffName .. " | Tiempo: " .. bombTime .. "s")
    end

    self._nextBeep = 0
end

function ENT:Think()
    if self:GetDefused() then return end
    if not self:GetArmed() then return end

    local curTime = CurTime()
    local timeLeft = self:GetDetonateTime() - curTime

    -- Beep con frecuencia acelerada
    if curTime >= self._nextBeep then
        local interval
        if timeLeft > 20 then
            interval = 2
        elseif timeLeft > 10 then
            interval = 1
        elseif timeLeft > 5 then
            interval = 0.4
        else
            interval = 0.15
        end

        local pitch = math.Clamp(100 + (120 - timeLeft) * 2, 100, 220)
        self:EmitSound(BEEP_SOUND, 65, pitch, 0.8, CHAN_ITEM)
        self._nextBeep = curTime + interval
    end

    -- Explosión
    if timeLeft <= 0 then
        self:Explode()
    end

    self:NextThink(curTime)
    return true
end

-- Use: E sobre la bomba con el SWEP equipado
function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if self:GetDefused() or not self:GetArmed() then return end

    local wep = activator:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "weapon_ivo_defuser" then
        activator:ChatPrint("[BOMBA] Necesitas el Kit de Desactivación para desactivar bombas.")
        return
    end

    -- Delegar al sistema de desactivación
    if IVO_BOMBS and IVO_BOMBS.StartDefuse then
        IVO_BOMBS.StartDefuse(activator, self)
    end
end

function ENT:OnDefused(defuser)
    self:SetDefused(true)
    self:SetArmed(false)
    self:SetColor(Color(50, 200, 50))

    self:EmitSound(DEFUSE_SOUND, 80, 100, 1, CHAN_ITEM)

    local name = IsValid(defuser) and defuser:Nick() or "Alguien"
    for _, ply in ipairs(player.GetAll()) do
        ply:ChatPrint("[BOMBA] ¡" .. name .. " ha desactivado la bomba!")
    end

    timer.Simple(15, function()
        if IsValid(self) then self:Remove() end
    end)
end

function ENT:Explode()
    if self:GetDefused() then return end
    self:SetArmed(false)

    local pos = self:GetPos()

    -- Obtener radio y daño de la config de dificultad
    local diff = self:GetDifficulty()
    local config = IVO_BOMBS.Difficulties[diff]
    local radius = config and 500 or 500
    local damage = config and 200 or 200

    util.BlastDamage(self, self, pos, radius, damage)

    local effectData = EffectData()
    effectData:SetOrigin(pos)
    effectData:SetScale(3)
    effectData:SetMagnitude(damage)
    effectData:SetRadius(radius)
    util.Effect("Explosion", effectData)

    util.ScreenShake(pos, 25, 150, 3, radius * 1.5)
    self:EmitSound(EXPLOSION_SOUND, 100, 100, 1, CHAN_STATIC)

    for _, ply in ipairs(player.GetAll()) do
        ply:ChatPrint("[BOMBA] ¡La bomba ha explotado!")
    end

    -- Explosiones secundarias
    for i = 1, 5 do
        timer.Simple(i * 0.1, function()
            if IsValid(self) then
                local ed = EffectData()
                ed:SetOrigin(pos + VectorRand() * 50)
                ed:SetScale(2)
                util.Effect("Explosion", ed)
            end
        end)
    end

    timer.Simple(0.5, function()
        if IsValid(self) then self:Remove() end
    end)
end

function ENT:OnRemove() end
