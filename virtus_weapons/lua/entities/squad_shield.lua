AddCSLuaFile()

ENT.PrintName		= 'Squad Shield'
ENT.Base			= 'base_gmodentity'
ENT.Type			= 'anim'
ENT.Model			= 'models/hunter/misc/shell2x2a.mdl'
ENT.RenderGroup		= RENDERGROUP_OTHER
ENT.Radius			= 47									-- Actual prop radius (Do not change this value!)
ENT.SphereScale		= 6										-- Sphere scale
ENT.LifeTime		= 30									-- Life time of shield activity, in seconds
ENT.CoolDownTime	= 60									-- Cooldown time, in seconds
ENT.Spawnable		= false




function ENT:SetupDataTables()
	self:NetworkVar('Entity',0,'ShieldOwner')
	self:NetworkVar('Bool',0,'Active')
	self:NetworkVar('Int',0,'TimeOffset')
end



if CLIENT then

	function ENT:Initialize()
		local dlight = DynamicLight(self:EntIndex())
		if dlight then
			dlight.pos = self:GetPos()
			dlight.r = 0
			dlight.g = 64
			dlight.b = 255
			dlight.brightness = 2
			dlight.Decay = 0
			dlight.Size = 512
			dlight.DieTime = CurTime()+self.LifeTime
		end
	end

end


if CLIENT then return end

function ENT:Initialize(owner)
	if !IsValid(owner) then return end

	self:PhysicsInit(SOLID_NONE)
	self:SetNoDraw(true)
	self:PhysWake()
	self:SetPos(owner:GetPos())
	self:Spawn()
	self:AddEffects(EF_NOSHADOW)
	self:SetOwner(owner)
	self:Activate()

	self.VisualProp = ents.Create('prop_dynamic')
	self.VisualProp:SetModel('models/squadshield/squad_shield.mdl')
	self.VisualProp:SetPos(owner:GetPos()+Vector(0,0,2))
	self.VisualProp:SetParent(self)
	self.VisualProp:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self.VisualProp:AddEffects(EF_NOSHADOW)
	self.VisualProp:Spawn()
	self.VisualProp:Activate()

	self.BulletHolder = ents.Create('prop_physics')
	self.BulletHolder:SetModel(self.Model)
	self.BulletHolder:SetModelScale(self.SphereScale)
	self.BulletHolder:SetNoDraw(true)
	self.BulletHolder:SetPos(owner:GetPos())
	self.BulletHolder:SetParent(self)
	self.BulletHolder:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self.BulletHolder:SetSolid(SOLID_BSP)
	self.BulletHolder:AddEffects(EF_NOSHADOW)
	self.BulletHolder:Spawn()
	self.BulletHolder:Activate()
	self.BulletHolder.PleaseKillMe = true

	self:SetShieldOwner(owner)
	owner:SetNWEntity('CSquadShield',self)
	self.SoundLoop = CreateSound(self,'ambient/levels/citadel/field_loop2.wav') --'ambient/machines/combine_shield_loop3.wav'
	self.SoundLoop:SetSoundLevel(80)
	self:ToggleShield(true)
	self:SetTimeOffset(CurTime())
end

function ENT:ToggleShield(bool)
	self:SetActive(bool)
	self.BulletHolder:SetSolid(bool and SOLID_BSP or SOLID_NONE)
	local owner = self:GetShieldOwner()
	if bool then
		self.SoundLoop:PlayEx(0.32,64)
		self:EmitSound('ambient/machines/thumper_hit.wav',80,64,.64)
		self:EmitSound('npc/scanner/scanner_siren1.wav',80,88,.64)
		self:EmitSound('ambient/levels/citadel/pod_open1.wav',80,100,.64)
		owner:SetNWInt('CSqShCooldown',-1)
	else
		self.SoundLoop:Stop()
		self:EmitSound('ambient/levels/canals/headcrab_canister_open1.wav',80,120,.64)
		self:EmitSound('ambient/levels/citadel/pod_close1.wav',80,100,.64)
		self.Destructable = CurTime()
		owner:SetNWInt('CSqShCooldown',CurTime()+self.CoolDownTime)
	end
end

function ENT:Think()
	if self:GetActive() and CurTime() >= self:GetTimeOffset()+self.LifeTime then
		self:ToggleShield(false)
	end
	if !self:GetActive() and self.Destructable and CurTime() >= self.Destructable+1 then
		self:Remove()
	end
end

function ENT:OnRemove()
	self.SoundLoop:Stop()
	self:GetShieldOwner():SetNWInt('CSqShCooldown',CurTime()+self.CoolDownTime)
end

function ENT:OnTakeDamage(dmg)
	if !self:GetActive() then return end
	local ed = EffectData()
	ed:SetOrigin(dmg:GetDamagePosition())
	ed:SetNormal((dmg:GetDamagePosition()-self:GetPos()):GetNormalized())
	ed:SetRadius(1)
	util.Effect('cball_bounce',ed)
	util.Effect('AR2Explosion',ed)
	self:EmitSound(('ambient/energy/weld%s.wav'):format(math.random(1,2)),75,math.random(144,192),.64,CHAN_ITEM)
end