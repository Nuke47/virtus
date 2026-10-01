ENT.Type = "anim"
DEFINE_BASECLASS( "lunasflightschool_basescript_gunship" )
ENT.Base = "lvs_base_fakehover"

ENT.PrintName = "BARC Speeder"
ENT.Author = "Ivo"
ENT.Information = "BARC brr "
ENT.Category = "[VIRTUS LVS]"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/barc/barc.mdl"
ENT.GibModels = {
	"models/gibs/helicopter_brokenpiece_01.mdl",
	"models/gibs/helicopter_brokenpiece_02.mdl",
	"models/gibs/helicopter_brokenpiece_03.mdl",
	"models/combine_apc_destroyed_gib02.mdl",
	"models/combine_apc_destroyed_gib04.mdl",
	"models/combine_apc_destroyed_gib05.mdl",
	"models/props_c17/trappropeller_engine.mdl",
	"models/gibs/airboat_broken_engine.mdl",
}

ENT.AITEAM = 2

ENT.MaxHealth = 2700

ENT.ForceAngleMultiplier = 2
ENT.ForceAngleDampingMultiplier = 1

ENT.ForceLinearMultiplier = 1
ENT.ForceLinearRate = 0.25

ENT.MaxVelocityX = 950
ENT.MaxVelocityY = 950

ENT.MaxTurnRate = 0.8

ENT.BoostAddVelocityX = 260
ENT.BoostAddVelocityY = 260

ENT.GroundTraceHitWater = true
ENT.GroundTraceLength = 50
ENT.GroundTraceHull = 100

ENT.LAATC_PICKUPABLE = true
ENT.LAATC_DROP_IN_AIR = true
ENT.LAATC_PICKUP_POS = Vector(-200,0,25)
ENT.LAATC_PICKUP_Angle = Angle(0,0,0)


function ENT:OnSetupDataTables()
	self:AddDT( "Bool", "BTLFire" )
	self:AddDT( "Bool", "IsCarried" )
	self:AddDT( "Entity", "GunnerSeat" )

	if SERVER then
		self:NetworkVarNotify( "IsCarried", self.OnIsCarried )
	end
end

function ENT:GetAimAngles()
	local trace = self:GetEyeTrace()

	local AimAnglesR = self:WorldToLocalAngles( (trace.HitPos - self:LocalToWorld( Vector(-60,-51,43) ) ):GetNormalized():Angle() )
	local AimAnglesL = self:WorldToLocalAngles( (trace.HitPos - self:LocalToWorld( Vector(-60,51,43) ) ):GetNormalized():Angle() )

	return AimAnglesR, AimAnglesL
end

function ENT:WeaponsInRange()
	if self:GetIsCarried() then return false end

	local AimAnglesR, AimAnglesL = self:GetAimAngles()

	return not ((AimAnglesR.p >= 10 and AimAnglesL.p >= 10) or (AimAnglesR.p <= -25 and AimAnglesL.p <= -25) or (math.abs(AimAnglesL.y) + math.abs(AimAnglesL.y)) >= 30)
end

function ENT:InitWeapons()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/dual_mg.png")
	weapon.Ammo = 400
	weapon.Delay = 0.25
	weapon.HeatRateUp = 0.5
	weapon.HeatRateDown = 1
	weapon.Attack = function( ent )
		local bullet = {}
		bullet.Dir 	= ent:GetForward()
		bullet.Spread 	= Vector( 0.015,  0.015, 0 )
		bullet.TracerName = "lvs_laser_blue_short"
		bullet.Force	= 10
		bullet.HullSize 	= 25
		bullet.Damage	= 40
		bullet.Velocity = 60000
		bullet.Attacker 	= ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo)
			local effectdata = EffectData()
				effectdata:SetStart( Vector(50,50,255) ) 
				effectdata:SetOrigin( tr.HitPos )
				effectdata:SetNormal( tr.HitNormal )
			util.Effect( "lvs_laser_impact", effectdata )
		end

		for i = -1,1,2 do
			bullet.Src 	= ent:LocalToWorld( Vector(95,-15 * i,4) )
			
			local effectdata = EffectData()
			effectdata:SetStart( Vector(50,50,255) )
			effectdata:SetOrigin( bullet.Src )
			effectdata:SetNormal( ent:GetForward() )
			effectdata:SetEntity( ent )
			util.Effect( "lvs_muzzle_colorable", effectdata )

			ent:LVSFireBullet( bullet )

		end

		ent:TakeAmmo()

		ent.PrimarySND:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
	end
	weapon.OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	self:AddWeapon( weapon )

	

end

ENT.EngineSounds = {
	{
		sound = "lvs/vehicles/barc/loop.wav",
		Pitch = 70,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 30,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
		SoundLevel = 205,
	},
	{
		sound = "lvs/vehicles/barc/loop.wav",
		Pitch = 70,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 30,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
		SoundLevel = 85,
	},
	{
		sound = "lvs/vehicles/barc/loop.wav",
		Pitch = 70,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 30,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		SoundLevel = 90,
	},
}
