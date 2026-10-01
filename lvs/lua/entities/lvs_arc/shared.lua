--DO NOT EDIT OR REUPLOAD THIS FILE

ENT.Base = "lvs_base_starfighter"

ENT.PrintName = "ARC 170"
ENT.Author = "Ivo"
ENT.Information = ""
ENT.Category = "[VIRTUS LVS]"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/arc170.mdl"
ENT.GibModels = {
	"models/salza/arc170_gib1.mdl",
	"models/salza/arc170_gib2.mdl",
	"models/salza/arc170_gib3.mdl",
	"models/salza/arc170_gib4.mdl",
	"models/salza/arc170_gib5.mdl",
	"models/salza/arc170_gib6.mdl"
}

ENT.AITEAM = 2

ENT.MaxVelocity = 2150
ENT.MaxThrust = 2150

ENT.ThrustVtol = 55
ENT.ThrustRateVtol = 3

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxHealth = 800
ENT.MaxShield = 100

function ENT:OnSetupDataTables()
	self:AddDT( "Bool", "Foils" )
	self:AddDT( "Entity", "TailGunnerSeat" )

	if SERVER then
		self:NetworkVarNotify( "Foils", self.OnFoilsChanged )
	end
end

function ENT:InitWeapons()
	self.FirePositions = {
		Vector(207.65,-303.52,-48.35),
		Vector(207.65,303.52,-48.35),
	}

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/hmg.png")
	weapon.Ammo = 1000
	weapon.Delay = 0.15
	weapon.HeatRateUp = 0.5
	weapon.HeatRateDown = 1
	weapon.Attack = function( ent )
		ent.NumPrim = ent.NumPrim and ent.NumPrim + 1 or 1
		if ent.NumPrim > #ent.FirePositions then ent.NumPrim = 1 end

		if not ent:GetFoils() then
			ent:SetHeat( ent:GetHeat() + 0.5 )
		end
	
		local pod = ent:GetDriverSeat()

		if not IsValid( pod ) then return end

		local startpos = pod:LocalToWorld( pod:OBBCenter() )
		local trace = util.TraceHull( {
			start = startpos,
			endpos = (startpos + ent:GetForward() * 50000),
			mins = Vector( -10, -10, -10 ),
			maxs = Vector( 10, 10, 10 ),
			filter = ent:GetCrosshairFilterEnts()
		} )

		local CurPos = ent.FirePositions[ent.NumPrim]

		local bullet = {}
		bullet.Src 	= ent:LocalToWorld( CurPos )
		bullet.Dir 	= (trace.HitPos - bullet.Src):GetNormalized()
		bullet.Spread 	= Vector( 0.025,  0.025, 0 )
		bullet.TracerName = "lvs_laser_green"
		bullet.Force	= 10
		bullet.HullSize 	= 30
		bullet.Damage	= 40
		bullet.SplashDamage = 60
		bullet.SplashDamageRadius = 250
		bullet.Velocity = 50000
		bullet.Attacker 	= ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo)
			local effectdata = EffectData()
				effectdata:SetStart( Vector(0,255,0) ) 
				effectdata:SetOrigin( tr.HitPos )
			util.Effect( "lvs_laser_explosion", effectdata )
		end
		ent:LVSFireBullet( bullet )
		

		local effectdata = EffectData()
		effectdata:SetStart( Vector(50,255,50) )
		effectdata:SetOrigin( bullet.Src )
		effectdata:SetNormal( ent:GetForward() )
		effectdata:SetEntity( ent )
		util.Effect( "lvs_muzzle_colorable", effectdata )

		ent:TakeAmmo()

		if CurPos.y > 0 then
			ent.SNDLeft:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
		else
			ent.SNDRight:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
		end
	end
	weapon.OnSelect = function( ent )
		ent:EmitSound("physics/metal/weapon_impact_soft3.wav")
		if ent.SetFoils then ent:SetFoils( true ) end
	end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	self:AddWeapon( weapon )



	local weapon = {}
	weapon.Icon = Material("lvs/weapons/protontorpedo.png")
	weapon.Ammo = 12
	weapon.Delay = 0 -- this will turn weapon.Attack to a somewhat think function
	weapon.HeatRateUp = -0.5 -- cool down when attack key is held. This system fires on key-release.
	weapon.HeatRateDown = 0.25
	weapon.Attack = function( ent )
		local T = CurTime()

		if IsValid( ent._ProtonTorpedo ) then
			if (ent._nextMissleTracking or 0) > T then return end

			ent._nextMissleTracking = T + 0.1 -- 0.1 second interval because those find functions can be expensive

			ent._ProtonTorpedo:FindTarget( ent:GetPos(), ent:GetForward(), 30, 7500 )

			return
		end

		local T = CurTime()

		if (ent._nextMissle or 0) > T then return end

		ent._nextMissle = T + 0.5

		ent._swapMissile = not ent._swapMissile

		local Pos = Vector( 90, (ent._swapMissile and -304 or 304), -32 )

		local Driver = self:GetDriver()

		local projectile = ents.Create( "lvs_protontorpedo" )
		projectile:SetPos( ent:LocalToWorld( Pos ) )
		projectile:SetAngles( ent:LocalToWorldAngles( Angle(0,ent._swapMissile and 2 or -2,0) ) )
		projectile:SetParent( ent )
		projectile:Spawn()
		projectile:Activate()
		projectile:SetAttacker( IsValid( Driver ) and Driver or self )
		projectile:SetEntityFilter( ent:GetCrosshairFilterEnts() )
		projectile:SetSpeed( ent:GetVelocity():Length() + 4000 )

		ent._ProtonTorpedo = projectile

		ent:SetNextAttack( CurTime() + 0.1 ) -- wait 0.1 second before starting to track
	end
	weapon.FinishAttack = function( ent )
		if not IsValid( ent._ProtonTorpedo ) then return end

		local projectile = ent._ProtonTorpedo

		projectile:Enable()
		projectile:EmitSound( "lvs/vehicles/naboo_n1_starfighter/proton_fire.mp3", 125 )
		ent:TakeAmmo()

		ent._ProtonTorpedo = nil

		local NewHeat = ent:GetHeat() + 0.75

		ent:SetHeat( NewHeat )
		if NewHeat >= 1 then
			ent:SetOverheated( true )
		end
	end
	weapon.OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	self:AddWeapon( weapon )


	local COLOR_RED = Color(255,0,0,255)
	local COLOR_WHITE = Color(255,255,255,255)

	local weapon = {}
	weapon.Icon = Material("lvs/weapons/hmg.png")
	weapon.Delay = 0.15
	weapon.Attack = function( ent )
		local pod = ent:GetDriverSeat()

		if not IsValid( pod ) then return end

		local dir = ent:GetAimVector()

		if ent:AngleBetweenNormal( dir, ent:GetForward() ) > 60 then return true end

		local trace = ent:GetEyeTrace()

		ent.SwapTopBottom = not ent.SwapTopBottom

		local veh = ent:GetVehicle()


		local bullet = {}
		bullet.Src = veh:LocalToWorld( ent.SwapTopBottom and Vector(-175.81,0,50.26) or Vector(-171.69,0,5.81) )
		bullet.Dir = (trace.HitPos - bullet.Src):GetNormalized()
		bullet.Spread 	= Vector( 0.03,  0.03, 0.03 )
		bullet.TracerName = "lvs_laser_green"
		bullet.Force	= 10
		bullet.HullSize 	= 25
		bullet.Damage	= 45
		bullet.Velocity = 30000
		bullet.Attacker 	= ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo)
			local effectdata = EffectData()
				effectdata:SetStart( Vector(50,255,50) ) 
				effectdata:SetOrigin( tr.HitPos )
				effectdata:SetNormal( tr.HitNormal )
			util.Effect( "lvs_laser_explosion", effectdata )
		end
		ent:LVSFireBullet( bullet )
		ent:EmitSound("lvs/vehicles/arc170/fire_gunner.mp3")
	end
	weapon.OnSelect = function( ent )
		ent:EmitSound("physics/metal/weapon_impact_soft3.wav")
	end
	weapon.OnOverheat = function( ent )
		ent:EmitSound("lvs/overheat.wav")
	end
	weapon.CalcView = function( ent, ply, pos, angles, fov, pod )
		local base = ent:GetVehicle()

		if not IsValid( base ) then 
			return LVS:CalcView( ent, ply, pos, angles, fov, pod )
		end

		if pod:GetThirdPersonMode() then
			pos = pos + base:GetUp() * 100
		end

		return LVS:CalcView( base, ply, pos, angles, fov, pod )
	end
	weapon.HudPaint = function( ent, X, Y, ply )
		local Col = (ent:AngleBetweenNormal( ent:GetAimVector(), ent:GetForward() ) > 60) and COLOR_RED or COLOR_WHITE

		local Pos2D = ent:GetEyeTrace().HitPos:ToScreen() 

		local base = ent:GetVehicle()
		base:PaintCrosshairCenter( Pos2D, Col )
		base:PaintCrosshairOuter( Pos2D, Col )
		base:LVSPaintHitMarker( Pos2D )
	end
	self:AddWeapon( weapon, 3 )
end

ENT.FlyByAdvance = 0.5
ENT.FlyBySound = "lvs/vehicles/arc170/flyby.wav" 
ENT.DeathSound = "lvs/vehicles/generic_starfighter/crash.wav"

ENT.EngineSounds = {
	{
		sound = "lvs/vehicles/arc170/loop.wav",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 40,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
	},
}






ENT.MDL = "models/sdog/arc170ch.mdl"
ENT.GibModels = {
	"models/salza/arc170_gib1.mdl",
	"models/salza/arc170_gib2.mdl",
	"models/salza/arc170_gib3.mdl",
	"models/salza/arc170_gib4.mdl",
	"models/salza/arc170_gib5.mdl",
	"models/salza/arc170_gib6.mdl"
}

ENT.AITEAM = 2

ENT.Mass = 5000
ENT.Inertia = Vector(400000,400000,400000)
ENT.Drag = 1

ENT.SeatPos = Vector(55,0,3.5)
ENT.SeatAng = Angle(0,-90,11)

ENT.IdleRPM = 1
ENT.MaxRPM = 2700
ENT.LimitRPM = 3300

ENT.RotorPos = Vector(220,0,10)
ENT.WingPos = Vector(100,0,10)
ENT.ElevatorPos = Vector(-200,0,0)
ENT.RudderPos = Vector(-200,0,0)

ENT.MaxVelocity = 2600

ENT.MaxThrust = 50000

ENT.MaxTurnPitch = 600
ENT.MaxTurnYaw = 600
ENT.MaxTurnRoll = 400

ENT.MaxPerfVelocity = 1500

ENT.MaxHealth = 1700
ENT.MaxShield = 800

ENT.Stability = 0.7

ENT.VerticalTakeoff = true
ENT.VtolAllowInputBelowThrottle = 10
ENT.MaxThrustVtol = 12000

ENT.MaxPrimaryAmmo = 1000
ENT.MaxSecondaryAmmo = 9

sound.Add( {
	name = "arclaz",
	channel = CHAN_ITEM,
	volume = 1.0,
	level = 105,
	pitch = {0, 0},
	sound = {
		"lfs/arc170ch/arcls1.wav",
		"lfs/arc170ch/arcls2.wav",
		"lfs/arc170ch/arcls3.wav",
		"lfs/arc170ch/arcls4.wav",
		"lfs/arc170ch/arcls5.wav",
		"lfs/arc170ch/arcls6.wav",
		"lfs/arc170ch/arcls7.wav",
		"lfs/arc170ch/arcls8.wav",
	}
} )

sound.Add( {
	name = "arctail",
	channel = CHAN_ITEM,
	volume = 1.0,
	level = 105,
	pitch = {0, 0},
	sound = {
		"lfs/arc170ch/arctail1.wav",
		"lfs/arc170ch/arctail2.wav",
		"lfs/arc170ch/arctail3.wav",
		"lfs/arc170ch/arctail4.wav",
		"lfs/arc170ch/arctail5.wav",
		"lfs/arc170ch/arctail6.wav",
	}
} )

sound.Add( {
	name = "tonnnn",
	channel = CHAN_STATIC,
	volume = 0.9,
	level = 110,
	sound = "lfs/arc170ch/arcton.wav"
} )

sound.Add( {
	name = "arcproton",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 105,
	sound = "lfs/arc170ch/arcproton.wav"
} )

sound.Add( {
	name = "tonnnn2",
	channel = CHAN_STATIC,
	volume = 0.9,
	level = 110,
	sound = "lfs/arc170ch/arcton2.wav"
} )

sound.Add( {
	name = "foilss",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 100,
	sound = "lfs/arc170ch/arcfoils.wav"
} )

-- Le decimos al juego que esta nave tiene las apariencias restringidas
ENT.IsARC170RestrictedSkin = true

function ENT:Initialize()
    if self.BaseClass.Initialize then
        self.BaseClass.Initialize( self )
    end
    -- Fuerza a la nave a aparecer con una skin del 3 al 6
    if SERVER then
        self:SetSkin( math.random( 3, 6 ) )
    end
end

-- ==========================================================
-- REEMPLAZO DEL MENÚ "APARIENCIAS" (C MENU)
-- ==========================================================

-- 1. Ocultamos el menú "Apariencias" que viene por defecto en GMod
hook.Add("CanProperty", "OcultarAparienciasPorDefecto_ARC", function(ply, property, ent)
    -- El nombre interno de "Apariencias" en Gmod es "skin"
    if IsValid(ent) and ent.IsARC170RestrictedSkin and property == "skin" then
        return false -- Esto lo borra del menú de la C
    end
end)

-- 2. Creamos nuestro propio menú "Apariencias" limitado
properties.Add( "arc170_apariencias_limitadas", {
    MenuLabel = "Apariencias", -- Se llamará exactamente igual en el menú
    Order = 601,
    MenuIcon = "icon16/picture_edit.png", -- Usa el mismo icono original
    
    -- Solo aparece si es esta nave
    Filter = function( self, ent, ply ) 
        if not IsValid( ent ) then return false end
        return ent.IsARC170RestrictedSkin or false
    end,
    
    -- Aquí limitamos para que SOLO muestre del 3 al 6
    MenuOpen = function( self, option, ent, tr )
        local submenu = option:AddSubMenu()
        
        for i = 3, 6 do
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
        
        if not IsValid( ent ) or not ent.IsARC170RestrictedSkin then return end
        if not properties.CanBeTargeted( ent, ply ) then return end
        
        -- Seguridad para que no pongan skins menores a 3 o mayores a 6 usando hacks
        if skinid < 3 then skinid = 3 end
        if skinid > 6 then skinid = 6 end
        
        ent:SetSkin( skinid )
    end
} )