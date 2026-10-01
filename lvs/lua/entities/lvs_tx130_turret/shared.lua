ENT.Type = "anim"
ENT.Base = "lvs_base_fakehover"

ENT.PrintName = "TX-130T"
ENT.Author = "Ivo"
ENT.Information = "Republic Fighter Tank"
ENT.Category = "[VIRTUS LVS]"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/tkaro/starwars/vehicle/tx130/tx130.mdl"
ENT.GibModels = {
	"models/tkaro/starwars/vehicle/tx130/gibs/tx130_charge_gib.mdl",
	"models/tkaro/starwars/vehicle/tx130/gibs/tx130_flap_gib.mdl",
    "models/tkaro/starwars/vehicle/tx130/gibs/tx130_hatch_gib.mdl",
	--"models/tkaro/starwars/vehicle/tx130/gibs/tx130_main_gib.mdl",
	"models/tkaro/starwars/vehicle/tx130/gibs/tx130_sidegun_gib_1.mdl",
	"models/tkaro/starwars/vehicle/tx130/gibs/tx130_sidegun_gib_2.mdl",
	"models/tkaro/starwars/vehicle/tx130/gibs/tx130_model_turret_gib.mdl",
	"models/tkaro/starwars/vehicle/tx130/gibs/tx130_wing_gib_1.mdl",
	"models/tkaro/starwars/vehicle/tx130/gibs/tx130_wing_gib_2.mdl",
}

ENT.AITEAM = 2

ENT.ForceAngleMultiplier = 2
ENT.ForceAngleDampingMultiplier = 1

ENT.ForceLinearMultiplier = 1
ENT.ForceLinearRate = 0.25

ENT.SpawnNormalOffset = 50

ENT.MaxTurnRate = 0.5

ENT.MaxHealth = 4000

ENT.MaxVelocityX = 275
ENT.MaxVelocityY = 275

ENT.BoostAddVelocityX = 100
ENT.BoostAddVelocityY = 100

ENT.IgnoreWater = false

ENT.GroundTraceLength = 50
ENT.GroundTraceHull = 100


function ENT:OnSetupDataTables()

	self:AddDT( "Entity", "GunnerSeat" )
	self:AddDT( "Entity", "CommanderSeat" )
	
	self:AddDT( "Int", "DoorMode" )
	
	self:AddDT("Bool", "IsCarried")
	self:AddDT("Bool", "BTLFire" )
	self:AddDT("Bool", "SideChargeActive")
	
	
	if SERVER then
        self:NetworkVarNotify("IsCarried", self.OnIsCarried)
    end
end

sound.Add( {
	name = "LVS.TX.PASSBY",
	sound = {
		"lvs/tx130/txpassby1.wav",
		"lvs/tx130/txpassby2.wav",
		"lvs/tx130/txpassby3.wav",
		"lvs/tx130/txpassby4.wav",
		"lvs/tx130/txpassby5.wav",
		"lvs/tx130/txpassby6.wav",
	}
} )

ENT.FlyByAdvance = 1
ENT.FlyBySound = "LVS.TX.PASSBY"

ENT.EngineSounds = {
	{
		channel = CHAN_STATIC,
		volume = 1.1,
		level = 100,
		sound = "lvs/tx130/engine.wav",
		sound_int = "lvs/tx130/interior.wav",
		Pitch = 100,
		PitchMin = 100,
		PitchMax = 100,
		PitchMul = 1,
	},
	{
		sound = "^lvs/tx130/dist.wav",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 40,
		FadeIn = 0.35,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
		VolumeMin = 0,
		VolumeMax = 1,
		SoundLevel = 110,
	},
}

ENT.LAATC_PICKUPABLE = true
ENT.LAATC_DROP_IN_AIR = true
ENT.LAATC_PICKUP_POS = Vector(-200,0,30)
ENT.LAATC_PICKUP_Angle = Angle(0,0,0)

function ENT:GetAimAngles()
	local trace = self:GetEyeTrace()

	local AimAnglesR = self:WorldToLocalAngles( (trace.HitPos - self:LocalToWorld( Vector(-93,-62,46) ) ):GetNormalized():Angle() )
	local AimAnglesL = self:WorldToLocalAngles( (trace.HitPos - self:LocalToWorld( Vector(-93,62,46) ) ):GetNormalized():Angle() )

	return AimAnglesR, AimAnglesL
end

function ENT:InitWeapons()
	local COLOR_RED = Color(255,0,0,255)
	local COLOR_WHITE = Color(255,255,255,255)
	self.curfire = false

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/dual_mg.png")
	weapon.Delay = 0.5
	weapon.HeatRateUp = 0.40
	weapon.HeatRateDown = 0.8
	weapon.Attack = function( ent )
	   if not self:GetEngineActive() then return end
		if self:GetIsCarried() then return end
		
		local ID_L = self:LookupAttachment( "muzzle_left" )
		local ID_R = self:LookupAttachment( "muzzle_right" )
		local MuzzleL = self:GetAttachment( ID_L )
		local MuzzleR = self:GetAttachment( ID_R )
		
		if not MuzzleL or not MuzzleR then return end
	
		self.MirrorPrimary = not self.MirrorPrimary
	
		local Pos = self.MirrorPrimary and MuzzleL.Pos or MuzzleR.Pos
		local Dir = (self.MirrorPrimary and MuzzleL.Ang or MuzzleR.Ang):Up()
		
		local bullet = {}
		bullet.Src 	= Pos
		bullet.Dir 	= Dir
		bullet.Spread 	= Vector( 0.01,  0.01, 0 )
		bullet.TracerName = "lvs_laser_red_short"
		bullet.Force	= 10000
		bullet.HullSize 	= 1
		bullet.Damage	= 150
		bullet.SplashDamage	= 10
		bullet.SplashDamageRadius	= 30
		bullet.Velocity = 	40000
		bullet.Attacker = ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo)
			local effectdata = EffectData()
				effectdata:SetStart( Vector(255,50,50) ) 
				effectdata:SetOrigin( tr.HitPos )
				effectdata:SetNormal( tr.HitNormal )
			util.Effect( "lvs_laser_impact", effectdata )
		end

		local effectdata = EffectData()
		effectdata:SetStart( Vector(255,50,50) )
		effectdata:SetOrigin( bullet.Src )
		effectdata:SetNormal( Dir )
		effectdata:SetEntity( ent )
		util.Effect( "lvs_muzzle_colorable", effectdata )
		
		ent:LVSFireBullet( bullet )
		
		if ent.MirrorPrimary then
			ent:PlayAnimation( "gun_l_anim" )
	
			if not IsValid( ent.SNDLeft ) then return end
	
			ent.SNDLeft:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
			ent:TakeAmmo()

			return
		end

		ent:PlayAnimation( "gun_r_anim" )
		if not IsValid( ent.SNDRight ) then return end

		ent.SNDRight:PlayOnce( 100 + math.sin( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )

	end
	weapon.OnThink = function( ent, active )
		local base = ent:GetVehicle()
		
		if not IsValid( base ) then return end
		
		if self:GetIsCarried() then 
			self:SetPoseParameter("sidegun_left_yaw", 0 )
			self:SetPoseParameter("sidegun_right_yaw", 0 )
			self:SetPoseParameter("sidegun_pitch", 0 )
		return 
		end

		local Angles = base:WorldToLocalAngles( ent:GetAimVector():Angle() )
		Angles:Normalize()
		
		local AimAnglesR, AimAnglesL = ent:GetAimAngles()

		self:SetPoseParameter("sidegun_pitch", -Angles.p )
		self:SetPoseParameter("sidegun_left_yaw", -AimAnglesL.y )
		self:SetPoseParameter("sidegun_right_yaw", -AimAnglesR.y )
	
	end
	weapon.OnSelect = function( ent )
		ent:EmitSound("physics/metal/weapon_impact_soft3.wav")
	end
	weapon.OnOverheat = function( ent )
		ent:EmitSound("lvs/overheat.wav")
	end
	weapon.HudPaint = function( ent, X, Y, ply )
	
		local base = ent:GetVehicle()
		
		if not IsValid(base) then return end
		
		local ID1 = self:LookupAttachment( "muzzle_left" )
		local ID2 = self:LookupAttachment( "muzzle_right" )
	
		local Muzzle1 = self:GetAttachment(ID1)
		local Muzzle2 = self:GetAttachment(ID2)
	
		if not Muzzle1 or not Muzzle2 then return end
		
		local trace1 = util.TraceLine({
			start = Muzzle1.Pos,
			endpos = Muzzle1.Pos + Muzzle1.Ang:Up() * 50000,
			filter = base:GetCrosshairFilterEnts()
		})

		local trace2 = util.TraceLine({
			start = Muzzle2.Pos,
			endpos = Muzzle2.Pos + Muzzle2.Ang:Up() * 50000,
			filter = base:GetCrosshairFilterEnts()
		})

		local MuzzlePos2D1 = trace1.HitPos:ToScreen()
		local MuzzlePos2D2 = trace2.HitPos:ToScreen()

		base:LVSPaintHitMarker(MuzzlePos2D1)
		base:LVSPaintHitMarker(MuzzlePos2D2)
		
		local Col = COLOR_WHITE 

		base:PaintCrosshairCenter( MuzzlePos2D1, Col )
		base:PaintCrosshairCenter( MuzzlePos2D2, Col )
	end
	
	self:AddWeapon( weapon )
	
	local MissileAttachments = {
		"left_launch_tube_1",
		"right_launch_tube_1",
		"left_launch_tube_2",
		"right_launch_tube_2",
		"left_launch_tube_3",
		"right_launch_tube_3",
		"left_launch_tube_4",
		"right_launch_tube_4",
		"left_launch_tube_5",
		"right_launch_tube_5",
	}

	local weapon = {}

	weapon.Icon = Material("lvs/weapons/missile.png")
	weapon.Ammo = 20
	weapon.Delay = 0.3
	weapon.HeatRateUp = 0
	weapon.HeatRateDown = 0.9

	weapon.Attack = function(ent)
		if not ent:GetEngineActive() then return end
		if ent:GetIsCarried() then return end
		if ent:GetDoorMode() == 0 then return end
		if (ent.smRocketHatch or 0) < 0.99 then
			return
		end


		if ent:GetAmmo() <= 0 then
			ent:SetHeat(1)
			return
		end

		ent.FireIndex2 = (ent.FireIndex2 or 0) + 1

		if ent.FireIndex2 > #MissileAttachments then
			ent.FireIndex2 = 1
		end

		local attachmentID =
			ent:LookupAttachment(
				MissileAttachments[ent.FireIndex2]
			)

		if attachmentID <= 0 then return end

		local muzzle = ent:GetAttachment(attachmentID)

		if not muzzle then return end

		local driver = ent:GetDriver()

		local spawnPos = muzzle.Pos + ent:GetForward() * 25 + ent:GetUp() * 10

		local projectile = ents.Create("lvs_missile")

		if not IsValid(projectile) then return end

		ent:TakeAmmo()
		ent:EmitSound("lvs/tx130/rocket.wav")

		projectile:SetPos(spawnPos)
		projectile:SetAngles(ent:GetAngles())
		projectile:SetParent(ent)
		projectile:Spawn()
		projectile:Activate()

		projectile.GetTargetPos = function(missile)
			return missile:LocalToWorld( Vector(150, 0, 0) + VectorRand() * math.random(-5, 5) )
		end

		projectile:SetAttacker(driver)
		projectile:SetEntityFilter( ent:GetCrosshairFilterEnts() )

		projectile:SetDamage(1500)
		projectile:SetRadius(300)
		projectile:Enable()

		ent:SetHeat(1)
		ent:SetOverheated(true)

		local dustPos = spawnPos - ent:GetUp() * 30

		for _ = 1, 2 do
			local effectData = EffectData()

			effectData:SetOrigin(dustPos)
			effectData:SetRadius(80 * 80)
			effectData:SetScale(10 * 10)

			util.Effect(
				"ThumperDust",
				effectData,
				true,
				true
			)
		end
	end
	weapon.HudPaint = function( ent, X, Y, ply )
		local Col = (ent:AngleBetweenNormal( ent:GetAimVector(), ent:GetForward() ) > 30) and COLOR_RED or COLOR_WHITE

		local Pos2D = ent:GetEyeTrace().HitPos:ToScreen() 

		local base = ent:GetVehicle()
		base:PaintCrosshairCenter( Pos2D, Col )
		base:PaintCrosshairOuter( Pos2D, Col )
		base:LVSPaintHitMarker( Pos2D )
	end
	weapon.OnSelect = function( ent )
		ent:EmitSound("weapons/shotgun/shotgun_cock.wav")
	end
	self:AddWeapon( weapon )
	
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/hmg.png")
	weapon.Delay = 0.1
	weapon.HeatRateUp = 0.7
	weapon.HeatRateDown = 0.1
	weapon.Attack = function( ent )
	   if not self:GetEngineActive() then return end
		if self:GetIsCarried() then return end
		
		local ID_L = self:LookupAttachment( "muzzle_left" )
		local ID_R = self:LookupAttachment( "muzzle_right" )
		local MuzzleL = self:GetAttachment( ID_L )
		local MuzzleR = self:GetAttachment( ID_R )
		
		if not MuzzleL or not MuzzleR then return end
	
		self.MirrorPrimary = not self.MirrorPrimary
	
		local Pos = MuzzleL.Pos
		local Dir = MuzzleL.Ang:Up()

		local bullet = {}
		bullet.Src 	= Pos
		bullet.Dir 	= Dir
		bullet.Spread 	= Vector( 0.01,  0.01, 0.01 )
		bullet.TracerName = "lvs_laser_red_short"
		bullet.Force	= 10000
		bullet.HullSize 	= 1
		bullet.Damage	= 100
		bullet.SplashDamage	= 10
		bullet.SplashDamageRadius	= 30
		bullet.Velocity = 	40000
		bullet.Attacker = ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo)
			local effectdata = EffectData()
				effectdata:SetStart( Vector(255,50,50) ) 
				effectdata:SetOrigin( tr.HitPos )
				effectdata:SetNormal( tr.HitNormal )
			util.Effect( "lvs_laser_impact", effectdata )
		end

		local effectdata = EffectData()
			effectdata:SetStart(Vector(255, 50, 50))
			effectdata:SetOrigin(MuzzleL.Pos)
			effectdata:SetNormal(MuzzleL.Ang:Up())
			effectdata:SetEntity(ent)
		util.Effect("lvs_muzzle_colorable", effectdata)

		ent:LVSFireBullet(bullet)

		bullet.Src = MuzzleR.Pos
		bullet.Dir = MuzzleR.Ang:Up()

		local effectdata = EffectData()
		effectdata:SetStart(Vector(255, 50, 50))
		effectdata:SetOrigin(MuzzleR.Pos)
		effectdata:SetNormal(MuzzleR.Ang:Up())
		effectdata:SetEntity(ent)

		util.Effect("lvs_muzzle_colorable", effectdata)

		if not IsValid(ent.SNDLeft)
		and not IsValid(ent.SNDRight) then
			return
		end

		ent.SNDLeft:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
		ent.SNDRight:PlayOnce( 100 + math.sin( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
		ent:LVSFireBullet(bullet)
	end
	weapon.OnThink = function( ent, active )
		local base = ent:GetVehicle()
		
		if not IsValid( base ) then return end
		
		local chargeActive = active and ent:GetEngineActive() and not ent:GetIsCarried() and not ent:GetOverheated()

		ent:SetSideChargeActive(chargeActive)
		
		if self:GetIsCarried() then 
			self:SetPoseParameter("sidegun_left_yaw", 0 )
			self:SetPoseParameter("sidegun_right_yaw", 0 )
			self:SetPoseParameter("sidegun_pitch", 0 )
		return 
		end

		local Angles = base:WorldToLocalAngles( ent:GetAimVector():Angle() )
		Angles:Normalize()
		
		local AimAnglesR, AimAnglesL = ent:GetAimAngles()

		self:SetPoseParameter("sidegun_pitch", -Angles.p )
		self:SetPoseParameter("sidegun_left_yaw", -AimAnglesL.y )
		self:SetPoseParameter("sidegun_right_yaw", -AimAnglesR.y )
	
	end
	weapon.OnSelect = function( ent )
		ent:SetSideChargeActive(true)
		
		if CurTime() < (ent._NextReadySound or 0) then
			return
		end

		ent._NextReadySound = CurTime() + 2
		
		ent:EmitSound("lvs/tx130/chargeready.wav")
	end
	weapon.OnDeSelect = function( ent )
		ent:SetSideChargeActive(false)
	end
	weapon.OnOverheat = function( ent )
		ent:EmitSound("lvs/overheat.wav")
	end
	weapon.HudPaint = function( ent, X, Y, ply )
	
		local base = ent:GetVehicle()
		
		if not IsValid(base) then return end
		
		local ID1 = self:LookupAttachment( "muzzle_left" )
		local ID2 = self:LookupAttachment( "muzzle_right" )
	
		local Muzzle1 = self:GetAttachment(ID1)
		local Muzzle2 = self:GetAttachment(ID2)
	
		if not Muzzle1 or not Muzzle2 then return end
		
		local trace1 = util.TraceLine({
			start = Muzzle1.Pos,
			endpos = Muzzle1.Pos + Muzzle1.Ang:Up() * 50000,
			filter = base:GetCrosshairFilterEnts()
		})

		local trace2 = util.TraceLine({
			start = Muzzle2.Pos,
			endpos = Muzzle2.Pos + Muzzle2.Ang:Up() * 50000,
			filter = base:GetCrosshairFilterEnts()
		})

		local MuzzlePos2D1 = trace1.HitPos:ToScreen()
		local MuzzlePos2D2 = trace2.HitPos:ToScreen()

		base:LVSPaintHitMarker(MuzzlePos2D1)
		base:LVSPaintHitMarker(MuzzlePos2D2)
		
		local Col = COLOR_WHITE 

		base:PaintCrosshairCenter( MuzzlePos2D1, Col )
		base:PaintCrosshairCenter( MuzzlePos2D2, Col )
	end
	self:AddWeapon( weapon )

  -----

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/laserbeam.png")
	weapon.Ammo = -1
	weapon.Delay = 0
	weapon.HeatRateUp = 0.8
	weapon.HeatRateDown = 0.4
	weapon.Attack = function( ent )
	   if not self:GetEngineActive() then return true end
	   if self:GetIsCarried() then return end
		local Pod = self:GetGunnerSeat()
		local Driver = Pod:GetDriver()
		if self:GetBodygroup(1) == 1 then
			if IsValid( Driver ) and IsValid( Pod ) then
				local veh = ent:GetVehicle()
				self:SetBTLFire( true )
				if self.curfire == false then
					veh.SecSND:PlayOnce()
					self.curfire = true
				end
				
				local ID = self:LookupAttachment( "lazer_cannon_muzzle" )
				local Muzzle = self:GetAttachment( ID )
							
				local Dir = Muzzle.Ang:Up()
				local startpos = Muzzle.Pos
						
				local Trace = util.TraceLine( {
					start = startpos,
					endpos = (startpos + Dir * 50000),
				} )
					
				self:BallturretDamage( Trace.Entity, Driver, Trace.HitPos, Dir )
			end
		end
	end
	weapon.FinishAttack = function( ent )
		self:SetBTLFire( false )
		self.curfire = false
	end
	weapon.OnThink = function( ent, active )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end
		
		if self:GetBodygroup(1) == 0 then return true end
		
		if not active then 
		base:SetPoseParameter("cannon_yaw", 0 )
		base:SetPoseParameter("cannon_pitch", 0 )
		return end
		
		

		local Angles = base:WorldToLocalAngles( ent:GetAimVector():Angle() )
		Angles:Normalize()

		base:SetPoseParameter("cannon_pitch", -Angles.p )
		base:SetPoseParameter("cannon_yaw", Angles.y )
	end
	weapon.HudPaint = function( ent, X, Y, ply )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		if self:GetBodygroup(1) == 1 then

			local Pos2D = base:TraceBTL().HitPos:ToScreen()

			base:PaintCrosshairCenter( Pos2D, color_white )
			base:PaintCrosshairOuter( Pos2D, color_white )
			base:LVSPaintHitMarker( Pos2D )
		end
	end
	self:AddWeapon( weapon, 2 )

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/tx_spotlight.png")
	weapon.Ammo = -1
	weapon.Delay = 0.1
	weapon.HeatRateUp = 0
	weapon.HeatRateDown = 1
	weapon.StartAttack = function( ent )
	   if not self:GetEngineActive() then return end
		if self.lighton == true then
			self:SetBodygroup(10, 0)
			self.lighton = false
			self:EmitSound( "buttons/lightswitch2.wav", 75, 105 )
		else
			self.lighton = true
			self:SetBodygroup(10, 1)
			self:EmitSound( "buttons/lightswitch2.wav", 75, 105 )
		end
	end

	self:AddWeapon( weapon, 3 )
end

function ENT:TraceBTL()
	local ID = self:LookupAttachment( "lazer_cannon_muzzle" )
	local Muzzle = self:GetAttachment( ID )

	if not Muzzle then return end

	local dir = Muzzle.Ang:Up()
	local pos = Muzzle.Pos

	local trace = util.TraceLine( {
		start = pos,
		endpos = (pos + dir * 50000),
	} )

	return trace
end

-- ==========================================================
-- RESTRICCIÓN DE SKINS (SOLO SKIN 2)
-- ==========================================================

-- Identificador único para el tanque
ENT.IsTX130RestrictedSkin = true

function ENT:Initialize()
    if self.BaseClass and self.BaseClass.Initialize then
        self.BaseClass.Initialize( self )
    end
    
    -- Fuerza al tanque a aparecer siempre con la skin 2
    if SERVER then
        self:SetSkin( 2 )
    end
end

function ENT:Think()
    if self.BaseClass and self.BaseClass.Think then
        self.BaseClass.Think( self )
    end

    -- Obliga a la entidad a mantener la skin 2 por si algo intenta cambiarla
    if SERVER then
        if self:GetSkin() ~= 2 then
            self:SetSkin( 2 )
        end
    end
end

-- ==========================================================
-- REEMPLAZO DEL MENÚ "APARIENCIAS" (C MENU)
-- ==========================================================

-- 1. Ocultamos el menú "Apariencias" que viene por defecto
hook.Add("CanProperty", "OcultarAparienciasPorDefecto_TX130", function(ply, property, ent)
    if IsValid(ent) and ent.IsTX130RestrictedSkin and property == "skin" then
        return false 
    end
end)

-- 2. Creamos nuestro propio menú "Apariencias" limitado a la Skin 2
properties.Add( "tx130_apariencias_limitadas", {
    MenuLabel = "Apariencias", 
    Order = 601,
    MenuIcon = "icon16/picture_edit.png", 
    
    Filter = function( self, ent, ply ) 
        if not IsValid( ent ) then return false end
        return ent.IsTX130RestrictedSkin or false
    end,
    
    MenuOpen = function( self, option, ent, tr )
        local submenu = option:AddSubMenu()
        
        -- Solo mostramos la skin 2
        local skinsPermitidas = {2}
        
        for _, i in ipairs(skinsPermitidas) do
            local opt = submenu:AddOption( "Skin " .. i, function() 
                self:Setup( ent, i ) 
            end )
            
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
        
        if not IsValid( ent ) or not ent.IsTX130RestrictedSkin then return end
        if not properties.CanBeTargeted( ent, ply ) then return end
        
        -- Seguridad absoluta: Si intentan forzar cualquier otra skin, se pone la 2
        if skinid ~= 2 then 
            skinid = 2 
        end
        
        ent:SetSkin( skinid )
    end
} )