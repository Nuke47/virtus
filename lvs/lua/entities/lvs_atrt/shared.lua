ENT.Base = "lvs_walker_atte_hoverscript"

ENT.PrintName = "AT-RT"
ENT.Author = "Ivo"
ENT.Information = "Test"
ENT.Category = "[VIRTUS LVS]"

ENT.Spawnable		= true
ENT.AdminSpawnable	= false

ENT.MDL = "models/KingPommes/starwars/atrt/main.mdl"
ENT.GibModels = {
	"models/KingPommes/starwars/atrt/main.mdl"
}

ENT.AITEAM = 2

ENT.MaxHealth = 2700

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.HoverHeight = 73
ENT.HoverTraceLength = 400
ENT.HoverHullRadius = 5

ENT.JumpDelay = 1
ENT.JumpForce = 3000000
ENT.JumpChargeTime = 2 -- how long it takes to max charge a jump

ENT.MaxLandingUpVelocity = 1500
ENT.MaxLandingSideVelocity = 2500

ENT.LAATC_PICKUPABLE = true
ENT.LAATC_DROP_IN_AIR = true
ENT.LAATC_PICKUP_POS = Vector(-220,0,0)
ENT.LAATC_PICKUP_Angle = Angle(0,0,0)

ENT.CanMoveOn = {
	["func_door"] = true,
	["func_movelinear"] = true,
	["prop_physics"] = true,
}

ENT.lvsShowInSpawner = true

function ENT:OnSetupDataTables()
	self:AddDT( "Float", "Move" )
	self:AddDT( "Bool", "IsMoving" )
	self:AddDT( "Bool", "IsCarried" )
	self:AddDT( "Bool", "IsRagdoll" )
	self:AddDT( "Bool", "IsJumping" )
	self:AddDT( "Bool", "ProperJump" )
	self:AddDT( "Bool", "IsChargingJump" )
	self:AddDT( "Int", "LastJump")
	self:AddDT( "Vector", "AIAimVector" )

	if SERVER then
		self:NetworkVarNotify( "IsCarried", self.OnIsCarried )
	end
end

function ENT:GetContraption()
	return {self}
end

function ENT:GetEyeTrace()
	local startpos = self:GetPos()

	local pod = self:GetDriverSeat()

	if IsValid( pod ) then
		startpos = pod:LocalToWorld( Vector(0,0,60) )
	end

	local trace = util.TraceLine( {
		start = startpos,
		endpos = (startpos + self:GetAimVector() * 50000),
		filter = self:GetCrosshairFilterEnts()
	} )

	return trace
end

function ENT:GetAimVector()
	if self:GetAI() then
		return self:GetAIAimVector()
	end

	local Driver = self:GetDriver()

	if IsValid( Driver ) then
		return Driver:GetAimVector()
	else
		return self:GetForward()
	end
end

function ENT:GetMainAimAngles()
	local trace = self:GetEyeTrace()

	local AimAngles = self:WorldToLocalAngles( (trace.HitPos - self:LocalToWorld( Vector(0,0,100)) ):GetNormalized():Angle() )

	local ID = self:LookupAttachment( "turret" )
	local Muzzle = self:GetAttachment( ID )

	if not Muzzle then return AimAngles, trace.HitPos, false end

	local DirAng = self:WorldToLocalAngles( (trace.HitPos - self:GetDriverSeat():LocalToWorld( Vector(0,0,33) ) ):Angle() )

	return AimAngles, trace.HitPos, (math.abs( DirAng.p ) < 30) and math.abs( DirAng.y ) < 80
end

function ENT:ShootTurret(ent)
	local muzzle = self:GetAttachment( self:LookupAttachment( "turret" ) )

	if not muzzle then return end

	local AimAngles, AimPos, InRange = self:GetMainAimAngles()

	local Pos = muzzle.Pos
	local Dir = (AimPos - Pos):GetNormalized()

	if not InRange then return true end

	local bullet = {}
	bullet.Src 	= Pos
	bullet.Dir 	= Dir
	bullet.Spread 	= Vector( 0.01,  0.01, 0 )
	bullet.TracerName = "lvs_laser_green_short"
	bullet.Force	= 10
	bullet.HullSize 	= 30
	bullet.Damage	= 80
	bullet.SplashDamage = 40
	bullet.SplashDamageRadius = 100
	bullet.Velocity = 8000
	bullet.Attacker 	= ent:GetDriver()
	bullet.Callback = function(att, tr, dmginfo)
		local effectdata = EffectData()
			effectdata:SetStart( Vector(50,255,50) ) 
			effectdata:SetOrigin( tr.HitPos )
			effectdata:SetNormal( tr.HitNormal )
		util.Effect( "lvs_laser_impact", effectdata )
	end
	ent:LVSFireBullet( bullet )

	local effectdata = EffectData()
	effectdata:SetStart( Vector(50,255,50) )
	effectdata:SetOrigin( bullet.Src )
	effectdata:SetNormal( Dir )
	effectdata:SetEntity( ent )
	util.Effect( "lvs_muzzle_colorable", effectdata )

	ent:TakeAmmo()

	if not IsValid( ent.SNDPrimary ) then return end

	ent.SNDPrimary:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
end

function ENT:InitWeapons()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/hmg.png")
	weapon.Ammo = 400
	weapon.Delay = 0.3

	weapon.Attack = function( ent )
		if ent:GetIsCarried() then return true end
		if self.Ammo == 0 then return false end

		return self:ShootTurret(ent)
	end

	weapon.OnThink = function( ent, active )
		local base = ent:GetVehicle()

		if IsValid( base ) and base:GetIsCarried() then return end

		local AimAngles = ent:GetMainAimAngles()

		local p = math.Clamp(AimAngles.p, -25, 35)
		local y = math.Clamp(AimAngles.y, -78, 78)

		ent:ManipulateBoneAngles(2, Angle(0,0,p))
		ent:ManipulateBoneAngles(1, Angle(y,0,0))
	end
	self:AddWeapon( weapon )
end