AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/tkaro/starwars/vehicle/tx130/gibs/tx130_main_gib.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then phys:Wake() end

    self.HP = 100
end

function ENT:Explode()
	
    local pos = self:GetPos()
    
    local effectdata = EffectData()
    effectdata:SetOrigin(pos)
    util.Effect("Explosion", effectdata)
   
    self:EmitSound("BaseExplosionEffect.Sound")

    self:Remove()
end


function ENT:OnTakeDamage(dmginfo)
    local dmg = dmginfo:GetDamage()
    self.HP = self.HP - dmg

    if self.HP <= 0 then
		self:Explode()
    end
end

