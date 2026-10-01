AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/fisher/laat/laat_bomb.mdl")
    self:PhysicsInit(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_BBOX)

    local phys = self:GetPhysicsObject()
	if IsValid(phys) then
        phys:Wake()
    end

    self.ExplodeTime = CurTime() + 3
end

function ENT:Think()
    if self.ExplodeTime <= CurTime() then
        self:Explode()
    end
end

local function GetValidEntity(ent)
    return IsValid(ent) && ent || Entity(0)
end

function ENT:Explode()
    local Pos = self:GetPos()

    util.BlastDamage(GetValidEntity(self.Inflictor), GetValidEntity(self.Attacker), Pos, 500, 500)

    local effectdata = EffectData()
	    effectdata:SetOrigin(Pos)
	util.Effect("HelicopterMegaBomb", effectdata)
	util.Effect("ThumperDust", effectdata)
	util.Effect("Explosion", effectdata)
	util.Effect("lfs_fb_detonator_explosion", effectdata)
    util.Effect("lfs_missile_explosion", effectdata)

	ParticleEffect("100lb_ground", Pos, self:GetAngles())

    self:Remove()
end