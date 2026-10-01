
ENT.Base = "lvs_base_repulsorlift"

ENT.PrintName = "LAAT Gunship"
ENT.Author = "Ivo"
ENT.Information = "Atmospheric version of the LAAT"
ENT.Category = "[VIRTUS LVS]"

ENT.VehicleCategory = "Star Wars"
ENT.VehicleSubCategory = "Starfighters"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/fisher/laat/laat.mdl"
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

ENT.DamageSounds = {
	"physics/metal/metal_sheet_impact_bullet2.wav",
	"physics/metal/metal_sheet_impact_hard2.wav",
	"physics/metal/metal_sheet_impact_hard6.wav",
}

ENT.AITEAM = 2

ENT.MaxVelocity = 2650
ENT.MaxThrust = 2650

ENT.ThrustVtol = 55
ENT.ThrustRateVtol = 3

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1.25

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxHealth = 6000
ENT.MaxShield = 0

function ENT:OnSetupDataTables()
	self:AddDT( "Bool", "WingTurretFire" )
	self:AddDT( "Vector", "WingTurretTarget" )
	self:NetworkVar( "Int", 23, "LampMode" )
	self:AddDT( "Float", "Activetime" )
	self:AddDT( "Bool", "Foils" )
	self:AddDT( "Entity", "GunnerSeat" )
	self:AddDT( "Entity", "SecondGunnerSeat" )
	self:NetworkVar( "Bool", 24, "SpotlightOn" )
	self:AddDT( "Bool", "SpotlightToggle" )

	self:AddDT( "Entity", "BTPodL" )
	self:AddDT( "Entity", "BTPodR" )

	self:AddDT( "Bool", "BTLFire" )
	self:AddDT( "Bool", "BTRFire" )

	self:AddDT( "Float", "BallTurretLHeat" )
	self:AddDT( "Float", "BallTurretRHeat" )
end

ENT.FlyByAdvance = 0.5
ENT.FlyBySound = "laat_bf2/laat_takeoff.wav" 
ENT.DeathSound = "lvs/vehicles/generic_starfighter/crash.wav"

function ENT:CalcMainActivity( ply )
	local Pod = ply:GetVehicle()

	if Pod == self:GetDriverSeat() or Pod == self:GetGunnerSeat() then return end

	if ply.m_bWasNoclipping then 
		ply.m_bWasNoclipping = nil 
		ply:AnimResetGestureSlot( GESTURE_SLOT_CUSTOM ) 

		if CLIENT then 
			ply:SetIK( true )
		end 
	end 

	if Pod == self:GetBTPodL() or Pod == self:GetBTPodR() then
		ply.CalcIdeal = ACT_STAND
		ply.CalcSeqOverride = ply:LookupSequence( "drive_jeep" )

		return ply.CalcIdeal, ply.CalcSeqOverride
	end

	ply.CalcIdeal = ACT_STAND
	ply.CalcSeqOverride = ply:LookupSequence( "idle_all_02" )

	if ply:GetAllowWeaponsInVehicle() and IsValid( ply:GetActiveWeapon() ) then
		local holdtype = ply:GetActiveWeapon():GetHoldType()

		if holdtype == "smg" then 
			holdtype = "smg1"
		end

		local seqid = ply:LookupSequence( "idle_" .. holdtype )

		if seqid ~= -1 then
			ply.CalcSeqOverride = seqid
		end
	end

	return ply.CalcIdeal, ply.CalcSeqOverride
end

ENT.EngineSounds = {
	{
		sound = "laat_bf2/engine_loop.mp3",
		Pitch = 90,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 30,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		SoundLevel = 85,
	},
	{
		sound = "laat_bf2/laat_loop.wav",
		Pitch = 70,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 30,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
		SoundLevel = 75,
	},
}

sound.Add( {
	name = "LAAT_FIREMISSILE",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 125,
	pitch = {95, 105},
	sound = "laat_bf2/rocket_shot.mp3"
} )


function ENT:SetNextRearGunFire( delay )
	self._NextRGFire = CurTime() + delay
end

function ENT:CanFireRearGun()
	return (self._NextRGFire or 0) < CurTime()
end

function ENT:GetRearGunInRange( ent )
	return ent:AngleBetweenNormal( ent:GetAimVector(), -ent:GetForward() ) < 35
end

function ENT:HandleRearGun( ent, ShouldFire )

	local trace = ent:GetEyeTrace()

	local Pos,Ang = WorldToLocal( Vector(100,0,0), (trace.HitPos - self:LocalToWorld( Vector(-400,0,158.5)) ):GetNormalized():Angle(), Vector(0,0,0), self:LocalToWorldAngles( Angle(0,180,0) ) )

	if not self:GetRearGunInRange( ent ) then 
		self:SetPoseParameter("back_turret_y", 0 )

		return false
	end

	self:SetPoseParameter("back_turret_z", Ang.p )
	self:SetPoseParameter("back_turret_y", -Ang.y )

	if not ShouldFire or not self:CanFireRearGun() then self:GetRearGunInRange( ent ) return end

	local startpos = self:GetBonePosition(self:LookupBone("Rear_Gun_End"))

	self:SetNextRearGunFire( 0.2 )

	local bullet = {}
	bullet.Src 	= ent:LocalToWorld( Vector(-500,0 ,-20) )
	bullet.Dir 	= (trace.HitPos - bullet.Src):GetNormalized()
	bullet.Spread 	= Vector( 0.03,  0.03, 0.03 )
	bullet.TracerName = "lvs_laser_green_short"
	bullet.Force	= 10
	bullet.HullSize 	= 25
	bullet.Damage	= 65
	bullet.Velocity = 20000
	bullet.Attacker 	= ent:GetDriver()
	bullet.Callback = function(att, tr, dmginfo)
		local effectdata = EffectData()
			effectdata:SetStart( Vector(50,255,50) ) 
			effectdata:SetOrigin( tr.HitPos )
			effectdata:SetNormal( tr.HitNormal )
		util.Effect( "lvs_laser_impact", effectdata )
	end
	ent:LVSFireBullet( bullet )

	local NewHeat = ent:GetHeat() + 0.2


	ent:SetHeat( NewHeat )
	if NewHeat >= 1 then
		ent:SetOverheated( true )
	end

	if not IsValid( self.SNDTail ) then return end

	self.SNDTail:PlayOnce( 100 + math.Rand(-3,3), 1 )
end

function ENT:GetEyeTrace()
	local startpos = self:GetPos()

	local pod = self:GetDriverSeat()

	if IsValid( pod ) then
		startpos = pod:LocalToWorld( Vector(100,0,103) )
	end

	local trace = util.TraceLine( {
		start = startpos,
		endpos = (startpos + self:GetAimVector() * 50000),
		filter = self:GetCrosshairFilterEnts()
	} )

	return trace
end

function ENT:InitWeapons()
	local COLOR_RED = Color(255,0,0,255)
	local COLOR_WHITE = Color(255,255,255,255)
	local MaxRange = 60
	local MaxTailRange = 35

	self.lor = 1

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/dual_mg.png")
	weapon.Ammo = 600
	weapon.Delay = 0.18
	weapon.HeatRateUp = 0.1
	weapon.HeatRateDown = 0.1
	weapon.Attack = function( ent )
		local pod = ent:GetDriverSeat()

		if not IsValid( pod ) then return end

		if ent:AngleBetweenNormal( ent:GetAimVector(), ent:GetForward() ) >= 20 then return true end

		local startpos = pod:LocalToWorld( pod:OBBCenter() )
		local trace = ent:GetEyeTrace()

		local bullet = {}
		bullet.Spread 	= Vector( 0.02,  0.02, 0.02 )
		bullet.TracerName = "lvs_laser_green"
		bullet.Force	= 10
		bullet.HullSize 	= 25
		bullet.Damage	= 60
		bullet.SplashDamage = 200
		bullet.SplashDamageRadius = 200
		bullet.Velocity = 28000
		bullet.Attacker 	= ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo)
			local effectdata = EffectData()
				effectdata:SetStart( Vector(50,255,50) ) 
				effectdata:SetOrigin( tr.HitPos )
				effectdata:SetNormal( tr.HitNormal )
			util.Effect( "lvs_laser_impact", effectdata )
		end
	
		for i = -1,1,2 do
			bullet.Src 	= ent:LocalToWorld( Vector(320,32 * i,37) )
			bullet.Dir 	= (trace.HitPos - bullet.Src):GetNormalized()
			local effectdata = EffectData()
			effectdata:SetStart( Vector(50,255,50) )
			effectdata:SetOrigin( bullet.Src )
			effectdata:SetNormal( ent:GetForward() )
			effectdata:SetEntity( ent )
				
			ent:LVSFireBullet( bullet )
		end

		ent:TakeAmmo()

		ent.PrimarySND:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
	end
	weapon.OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	weapon.OnThink = function( ent, active )
		local trace = ent:GetEyeTrace()

		local AimAngles = ent:WorldToLocalAngles( (trace.HitPos - self:LocalToWorld(  Vector(256,0,36) ) ):GetNormalized():Angle() )

		ent.frontgunYaw = -AimAngles.y

		if math.abs( ent.frontgunYaw ) > 100 then
			ent:SetPoseParameter("Front_Turret_Z", 0 )
			ent:SetPoseParameter("Front_Turret_Y", 0 )

			return
		end

		ent:SetPoseParameter("Front_Turret_Z", AimAngles.p )
		ent:SetPoseParameter("Front_Turret_Y", -AimAngles.y )
	end
	self:AddWeapon( weapon )

	self:AddWeapon( LVS:GetWeaponPreset( "TURBO" ) )

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/laserbeam.png")
	weapon.Ammo = -1
	weapon.Delay = 0
	weapon.HeatRateUp = 0.4
	weapon.HeatRateDown = 0
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	weapon.StartAttack = function( ent )
		ent.ShouldFire = true
	end
	weapon.FinishAttack = function( ent )
		ent.ShouldFire = false

		local base = ent:GetVehicle()

		local snd = {
			[-1] = base.WingLeftSND,
			[1] = base.WingRightSND,
		}

		for _, sound in pairs( snd ) do
			if not IsValid( sound ) then continue end

			sound:Stop()
		end
	end
	weapon.OnThink = function( ent, active )
		local base = ent:GetVehicle()

		local ShouldFire = (ent.ShouldFire == true) and ent:AngleBetweenNormal( ent:GetAimVector(), ent:GetForward() ) < MaxRange
	
		if base:HandleRearGun( ent, ent.ShouldFire ) then
			ShouldFire = false
		end

		if base:SetWingTurretFire() ~= ShouldFire then
			base:SetWingTurretFire( ShouldFire ) 
		end

		local snd = {
			[-1] = base.WingLeftSND,
			[1] = base.WingRightSND,
		}

		if ent._oldShouldFire ~= ShouldFire then
			ent._oldShouldFire = ShouldFire
			if ShouldFire then
				for _, sound in pairs( snd ) do
					if not IsValid( sound ) then continue end

					sound:EmitSound( "lvs/vehicles/laat/ballturret_fire.mp3", 110 )
				end
			end
		end

		if not ShouldFire then
			for _, sound in pairs( snd ) do
				if not IsValid( sound ) then continue end
				sound:Stop()
			end

			ent:SetHeat( ent:GetHeat() - FrameTime() )

			return
		end
	
		if not active then
			return
		end

		local trace = ent:GetEyeTrace()
		local DesEndPos = trace.HitPos

		base:SetWingTurretTarget( DesEndPos )

		if not base:GetWingTurretFire() then return end
		
		local DesStartPos --= Vector(-55, 350, 90)

		if base:WorldToLocal( DesEndPos ).z < 0 then
			DesStartPos = Vector(-55, 350, 90)
		else
			DesStartPos = Vector(-55, 370, 125)
		end

		local NewHeat = ent:GetHeat()

		for i = -1,1,2 do
			local StartPos = self:LocalToWorld( DesStartPos * Vector(1,i,1)  )
			local beam = util.TraceLine( { start = StartPos, endpos = DesEndPos} )

			self:BallturretDamage( beam.Entity, ent:GetDriver(), trace.HitPos, (trace.HitPos - StartPos):GetNormalized() )

			if not IsValid( snd[i] ) then continue end

			if beam.Entity ~= base then
				snd[i]:Play()
				NewHeat = NewHeat + FrameTime() * 0.25
			else
				snd[i]:Stop()
			end
		end

		ent:SetHeat( NewHeat )
		if NewHeat >= 1 then
			ent:SetOverheated( true )
		end
	end
	weapon.CalcView = function( ent, ply, pos, angles, fov, pod )
		local base = ent:GetVehicle()

		local view = {}
		view.origin = pos
		view.angles = angles
		view.fov = fov
		view.drawviewer = false

		if not IsValid( base ) then return view end

		local radius = 800
		radius = radius + radius * pod:GetCameraDistance()

		local clamped_angles = pod:WorldToLocalAngles( angles )
		clamped_angles.p = math.max( clamped_angles.p, -20 )
		clamped_angles = pod:LocalToWorldAngles( clamped_angles )

		local StartPos = base:LocalToWorld( base:OBBCenter() ) + clamped_angles :Up() * (350 + radius * pod:GetCameraHeight())
		local EndPos = StartPos - clamped_angles:Forward() * radius

		local WallOffset = 4

		local tr = util.TraceHull( {
			start = StartPos,
			endpos = EndPos,
			filter = function( e )
				local c = e:GetClass()
				local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "gmod_" ) and not c:StartWith( "player" ) and not e.LVS
				
				return collide
			end,
			mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
			maxs = Vector( WallOffset, WallOffset, WallOffset ),
		} )

		view.drawviewer = true
		view.origin = tr.HitPos

		if tr.Hit and not tr.StartSolid then
			view.origin = view.origin + tr.HitNormal * WallOffset
		end

		return view
	end
	weapon.HudPaint = function( ent, X, Y, ply )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		local WingInRange = ent:AngleBetweenNormal( ent:GetAimVector(), ent:GetForward() ) >= MaxRange
		local RearGunInRange = not base:GetRearGunInRange( ent )

		local Col = (WingInRange and RearGunInRange) and COLOR_RED or COLOR_WHITE

		local Pos2D = ent:GetEyeTrace().HitPos:ToScreen() 

		base:PaintCrosshairCenter( Pos2D, Col )
		base:PaintCrosshairOuter( Pos2D, Col )
		base:LVSPaintHitMarker( Pos2D )
	end
	self:AddWeapon( weapon, 2 )

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/protontorpedo.png")
	weapon.Ammo = 10
	weapon.Delay = 0 
	weapon.HeatRateUp = 1
	weapon.HeatRateDown = 0.25
	weapon.Attack = function( ent )

		local T = CurTime()
		local pos = 0
		if IsValid( ent._ProtonTorpedo ) then
			if (ent._nextMissleTracking or 0) > T then return end

			ent._nextMissleTracking = T + 0.1 -- 0.1 second interval because those find functions can be expensive

			ent._ProtonTorpedo:FindTarget( ent:GetPos(), ent:GetForward(), 30, 7500 )

			return
		end

		local T = CurTime()

		if self.lor == 1 then
			pos = Vector(-63.81,-263.11,132.86)
			self.lor = 2
		else
			pos = Vector(-65.8,271.86,131.86)
			self.lor = 1
		end

		if (ent._nextMissle or 0) > T then return end

		ent._nextMissle = T + 0.5

		local Driver = self:GetDriver()

		local projectile = ents.Create( "lvs_concussionmissile" )
		projectile:SetPos( self:LocalToWorld( pos ) )
		projectile:SetAngles( ent:GetAngles() )
		projectile:SetParent( ent )
		projectile:Spawn()
		projectile:Activate()
		projectile:SetDamage( 1250 )
		projectile:SetRadius( 350 )
		projectile:SetAttacker( IsValid( Driver ) and Driver or self )
		projectile:SetEntityFilter( ent:GetCrosshairFilterEnts() )

		ent._ProtonTorpedo = projectile

		ent:SetNextAttack( CurTime() + 0.2 )
	end
	weapon.FinishAttack = function( ent )
		if not IsValid( ent._ProtonTorpedo ) then return end

		local projectile = ent._ProtonTorpedo

		projectile:Enable()
		projectile:EmitSound( "lvs/vehicles/vulturedroid/fire_missile.mp3", 125 )
		ent:TakeAmmo()

		ent._ProtonTorpedo = nil

		local NewHeat = ent:GetHeat() + 0.75

		ent:SetHeat( NewHeat )
		if NewHeat >= 1 then
			ent:SetOverheated( true )
		end
	end
	weapon.HudPaint = function( ent, X, Y, ply )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		local WingInRange = ent:AngleBetweenNormal( ent:GetAimVector(), ent:GetForward() ) >= MaxRange
		local RearGunInRange = not base:GetRearGunInRange( ent )

		local Col = (WingInRange and RearGunInRange) and COLOR_RED or COLOR_WHITE

		local Pos2D = ent:GetEyeTrace().HitPos:ToScreen() 

		base:PaintCrosshairCenter( Pos2D, Col )
		base:PaintCrosshairOuter( Pos2D, Col )
		base:LVSPaintHitMarker( Pos2D )
	end
	weapon.OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	self:AddWeapon( weapon )

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/protontorpedo.png")
	weapon.Ammo = 40
	weapon.Delay = 2
	weapon.HeatRateUp = 1 
	weapon.HeatRateDown = 0.08
	weapon.Attack = function( ent )


		--if not ent:WeaponsInRange() then return true end
		local veh = ent:GetVehicle()
		local Driver = ent:GetDriver()

		local pod = ent:GetDriverSeat()

		if not IsValid( pod ) then return end

		local dir = ent:GetAimVector()

		if ent:AngleBetweenNormal( dir, ent:GetForward() ) > 100 then return true end

		for i = 1, 2 do
			timer.Simple( (i / 7) * 0.1, function()
				if not IsValid( ent ) then return end


				if self.lor == 1 then
					pos = Vector(99.71,69.93,276.31)
					self.lor = 2
				else
					pos = Vector(88.08,-69.92,276.24)
					self.lor = 1
				end

				if ent:GetAmmo() <= 0 then ent:SetHeat( 1 ) return end
	
				ent:TakeAmmo()

				local trace = ent:GetEyeTrace()
				local Start = pos
				local Dir = (ent:GetEyeTrace().HitPos - veh:LocalToWorld(Start)):GetNormalized()
				local projectile = ents.Create( "lvs_protontorpedo" )
				projectile:SetPos(veh:LocalToWorld(Start))
				projectile:SetAngles( ent:GetAngles() )
				projectile:SetParent( )
				projectile:Spawn()
				projectile:Activate()
				projectile.GetTarget = function( missile ) return missile end
				projectile.GetTargetPos = function( missile )
					return missile:LocalToWorld( Vector(150,0,0) + VectorRand() * math.random(-5,5) )
				end
				projectile:SetAttacker( IsValid( Driver ) and Driver or self )
				projectile:SetEntityFilter( ent:GetCrosshairFilterEnts() )
				projectile:SetDamage( 1250 )
				projectile:SetRadius( 550 )
				projectile:Enable()
				projectile:EmitSound("LAAT_FIREMISSILE" )
			end)
			self.RocketsModel:ResetSequence("Load_Missile")

		end
	end
		weapon.CalcView = function( ent, ply, pos, angles, fov, pod )
		local base = ent:GetVehicle()

		local view = {}
		view.origin = pos
		view.angles = angles
		view.fov = fov
		view.drawviewer = false

		if not IsValid( base ) then return view end

		local radius = 800
		radius = radius + radius * pod:GetCameraDistance()

		local clamped_angles = pod:WorldToLocalAngles( angles )
		clamped_angles.p = math.max( clamped_angles.p, -20 )
		clamped_angles = pod:LocalToWorldAngles( clamped_angles )

		local StartPos = base:LocalToWorld( base:OBBCenter() ) + clamped_angles :Up() * (350 + radius * pod:GetCameraHeight())
		local EndPos = StartPos - clamped_angles:Forward() * radius

		local WallOffset = 4

		local tr = util.TraceHull( {
			start = StartPos,
			endpos = EndPos,
			filter = function( e )
				local c = e:GetClass()
				local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "gmod_" ) and not c:StartWith( "player" ) and not e.LVS
				
				return collide
			end,
			mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
			maxs = Vector( WallOffset, WallOffset, WallOffset ),
		} )

		view.drawviewer = true
		view.origin = tr.HitPos

		if tr.Hit and not tr.StartSolid then
			view.origin = view.origin + tr.HitNormal * WallOffset
		end

		return view
	end
	weapon.FinishAttack = function( ent )
	end
	weapon.HudPaint = function( ent, X, Y, ply )
		--[[
		local base = ent:GetVehicle()
	
		if not IsValid( base ) then return end
	
		local WingInRange = ent:AngleBetweenNormal( ent:GetAimVector(), ent:GetForward() ) >= MaxRange
		local RearGunInRange = not base:GetRearGunInRange( ent )
	
		local Col = (WingInRange and RearGunInRange) and COLOR_RED or COLOR_WHITE
	
		local Pos2D = ent:GetEyeTrace().HitPos:ToScreen() 
	
		base:PaintCrosshairCenter( Pos2D, Col )
		base:PaintCrosshairOuter( Pos2D, Col )
		base:LVSPaintHitMarker( Pos2D )]]
	end
	weapon.OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	self:AddWeapon( weapon, 2 )

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/gunship_reardoor.png")
	weapon.Ammo = -1
	weapon.Delay = 1.5
	weapon.HeatRateUp = 1
	weapon.HeatRateDown = 0.3
	weapon.StartAttack = function( ent )
		if self:GetAI() == true then return end
		self:ToggleHatch()
	end
	self:AddWeapon( weapon, 5 )

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/dropship_grabber.png")
	weapon.Ammo = -1
	weapon.Delay = 1.5
	weapon.HeatRateUp = 1
	weapon.HeatRateDown = 0.1
	weapon.StartAttack = function( ent )
		if self:GetAI() == true then return end
		if (self.gateDown) then
			self.gateDown = false
			self:DropHeldEntity()
		else
			self:GrabEntity()
			self.gateDown = true
		end
	end
	self:AddWeapon( weapon, 5 )

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/gunship_sidedoor.png")
	weapon.Ammo = -1
	weapon.Delay = 1.5
	weapon.HeatRateUp = 1
	weapon.HeatRateDown = 0.3
	weapon.StartAttack = function( ent )
		if self:GetAI() == true then return end
		self:DoorOC()
	end
	self:AddWeapon( weapon )

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/spotlight.png")
	weapon.Ammo = -1
	weapon.Delay = 0.1
	weapon.HeatRateUp = 0
	weapon.HeatRateDown = 1
	weapon.StartAttack = function( ent )
		if self:GetSpotlightToggle() == true then
			self:SetSpotlightToggle(false)
			self:EmitSound( "buttons/lightswitch2.wav", 75, 105 )
		else
			self:SetSpotlightToggle(true)
			self:EmitSound( "buttons/lightswitch2.wav", 75, 105 )
		end
	end
	weapon.OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	self:AddWeapon( weapon )

	self:InitWeaponBTL()
	self:InitWeaponBTR()
end

function ENT:IsSpotlightMounted()
	return self:GetBodygroup(7) == 1
end


-- Le decimos al juego que esta nave (LAAT) tiene las apariencias restringidas
ENT.IsLAATRestrictedSkin = true

function ENT:Initialize()
    if self.BaseClass.Initialize then
        self.BaseClass.Initialize( self )
    end
    
    if SERVER then
        self:SetSkin( 1 )
    end
end

function ENT:Think()
    if self.BaseClass.Think then
        self.BaseClass.Think( self )
    end

    if SERVER then
        local currentSkin = self:GetSkin()
        -- Si la skin que tiene puesta NO es la 1 y NO es la 3, la forzamos a la 1
        if currentSkin ~= 1 and currentSkin ~= 3 then
            self:SetSkin( 1 )
        end
    end
end

-- ==========================================================
-- REEMPLAZO DEL MENÚ "APARIENCIAS" (C MENU) PARA EL LAAT
-- ==========================================================

-- 1. Ocultamos el menú "Apariencias" que viene por defecto en GMod
hook.Add("CanProperty", "OcultarAparienciasPorDefecto_LAAT", function(ply, property, ent)
    if IsValid(ent) and ent.IsLAATRestrictedSkin and property == "skin" then
        return false 
    end
end)

-- 2. Creamos nuestro propio menú "Apariencias" limitado
properties.Add( "laat_apariencias_limitadas", {
    MenuLabel = "Apariencias", 
    Order = 601,
    MenuIcon = "icon16/picture_edit.png", 
    
    Filter = function( self, ent, ply ) 
        if not IsValid( ent ) then return false end
        return ent.IsLAATRestrictedSkin or false
    end,
    
    MenuOpen = function( self, option, ent, tr )
        local submenu = option:AddSubMenu()
        
        -- Hacemos una lista exclusiva con las skins que queremos mostrar
        local skinsPermitidas = {1, 3}
        
        for _, i in ipairs(skinsPermitidas) do
            local opt = submenu:AddOption( "Skin " .. i, function() 
                self:Setup( ent, i ) 
            end )
            
            -- Pone el check verde en la skin actual
            if ent:GetSkin() == i then
                opt:SetIcon( "icon16/tick.png" )
            end
        end
    end,
    
    Action = function( self, ent ) end,
    
    Setup = function( self, ent, skinid )
        self:MsgStart()
            net.WriteEntity( ent )
            net.WriteUInt( skinid, 8 )
        self:MsgEnd()
    end,
    
    Receive = function( self, length, ply )
        local ent = net.ReadEntity()
        local skinid = net.ReadUInt( 8 )
        
        if not IsValid( ent ) or not ent.IsLAATRestrictedSkin then return end
        if not properties.CanBeTargeted( ent, ply ) then return end
        
        -- Seguridad: Si intentan forzar una skin que no sea 1 o 3, se cancela y se pone la 1
        if skinid ~= 1 and skinid ~= 3 then 
            skinid = 1 
        end
        
        ent:SetSkin( skinid )
    end
} )