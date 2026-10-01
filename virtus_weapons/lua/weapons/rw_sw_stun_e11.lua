SWEP.Gun							= ("rw_sw_e11")
if (GetConVar(SWEP.Gun.."_allowed")) != nil then
	if not (GetConVar(SWEP.Gun.."_allowed"):GetBool()) then SWEP.Base = "tfa_blacklisted" SWEP.PrintName = SWEP.Gun return end
end
SWEP.Base = "tfa_sw_gun_base"
SWEP.Category = "[VirtusRP]"
SWEP.Manufacturer 					= "Blastech Industries"
SWEP.Author							= "ChanceSphere574"
SWEP.Contact						= ""
SWEP.Spawnable						= true
SWEP.AdminSpawnable					= true
SWEP.DrawCrosshair					= true
SWEP.DrawCrosshairIS 				= false
SWEP.PrintName						= "Stun E-11"
SWEP.Type							= "Stun Imperial Carbine Blaster"
SWEP.DrawAmmo						= true
SWEP.data 							= {}
SWEP.data.ironsights				= 1
SWEP.Secondary.IronFOV				= 75
SWEP.Slot							= 2
SWEP.SlotPos						= 100

SWEP.FiresUnderwater 				= true

SWEP.IronInSound 					= nil
SWEP.IronOutSound 					= nil
SWEP.CanBeSilenced					= false
SWEP.Silenced 						= false
SWEP.DoMuzzleFlash 					= false
SWEP.SelectiveFire					= true
SWEP.DisableBurstFire				= false
SWEP.OnlyBurstFire					= false
SWEP.DefaultFireMode 				= "Automatic"
SWEP.FireModeName 					= nil
SWEP.DisableChambering 				= true

SWEP.Primary.ClipSize				= 10
SWEP.Primary.DefaultClip = 0
SWEP.Primary.RPM					= 300
SWEP.Primary.RPM_Burst				= 300
SWEP.Primary.Ammo					= "battery"
SWEP.Primary.AmmoConsumption 		= 11
SWEP.Primary.Range 					= 40000
SWEP.Primary.RangeFalloff 			= -1
SWEP.Primary.NumShots				= 1
SWEP.Primary.Automatic				= true
SWEP.Primary.RPM_Semi				= nil
SWEP.Primary.BurstDelay				= 0.2
SWEP.Primary.Sound 					= Sound ("w/e11.wav");
SWEP.Primary.ReloadSound 			= Sound ("w/rifles.wav");
SWEP.Primary.PenetrationMultiplier 	= 0
SWEP.Primary.Damage					= 2
SWEP.Primary.HullSize 				= 0
SWEP.DamageType 					= nil

SWEP.DoMuzzleFlash 					= false

SWEP.FireModes = {
	"Automatic",
	"Single"
}


SWEP.IronRecoilMultiplier			= 1
SWEP.CrouchRecoilMultiplier			= 1
SWEP.JumpRecoilMultiplier			= 1
SWEP.WallRecoilMultiplier			= 1
SWEP.ChangeStateRecoilMultiplier	= 1
SWEP.CrouchAccuracyMultiplier		= 1
SWEP.ChangeStateAccuracyMultiplier	= 1
SWEP.JumpAccuracyMultiplier			= 1
SWEP.WalkAccuracyMultiplier			= 1
SWEP.NearWallTime 					= 1
SWEP.ToCrouchTime 					= 1
SWEP.WeaponLength 					= 35
SWEP.SprintFOVOffset 				= 12
SWEP.ProjectileVelocity 			= 9

SWEP.ProjectileEntity 				= nil
SWEP.ProjectileModel 				= nil

SWEP.ViewModel						= "models/bf2017/c_e11.mdl"
SWEP.WorldModel						= "models/bf2017/w_e11.mdl"
SWEP.ViewModelFOV					= 65
SWEP.ViewModelFlip					= false
SWEP.MaterialTable 					= nil
SWEP.UseHands 						= true
SWEP.HoldType 						= "ar2"
SWEP.ReloadHoldTypeOverride 		= "smg"

SWEP.ShowWorldModel = false

SWEP.BlowbackEnabled 				= true
SWEP.BlowbackVector 				= Vector(0,-1.5,0)
SWEP.BlowbackCurrentRoot			= 0
SWEP.BlowbackCurrent 				= 0
SWEP.BlowbackBoneMods 				= nil
SWEP.Blowback_Only_Iron 			= true
SWEP.Blowback_PistolMode 			= false
SWEP.Blowback_Shell_Enabled 		= false
SWEP.Blowback_Shell_Effect 			= "None"

SWEP.Tracer = 0
SWEP.TracerName 					= "rw_sw_laser_aqua"
SWEP.TracerCount 					= 1
SWEP.TracerLua = true
SWEP.TracerDelay					= 0.01
SWEP.ImpactEffect 					= "rw_sw_impact_aqua"
SWEP.ImpactDecal 					= "FadingScorch"

SWEP.VMPos = Vector(2.01, -02, -0.545)
SWEP.VMAng = Vector(0,0,0)

SWEP.IronSightTime 					= 0.2
SWEP.Primary.KickUp					= 0
SWEP.Primary.KickDown				= 0
SWEP.Primary.KickHorizontal			= 0
SWEP.Primary.StaticRecoilFactor 	= 0
SWEP.Primary.Spread					= 0.01
SWEP.Primary.IronAccuracy 			= 0.01
SWEP.Primary.SpreadMultiplierMax 	= 0
SWEP.Primary.SpreadIncrement 		= 0
SWEP.Primary.SpreadRecovery 		= 0
SWEP.DisableChambering 				= true
SWEP.MoveSpeed 						= 1
SWEP.IronSightsMoveSpeed 			= 0.85

SWEP.IronSightsPos = Vector(-4.9, -8, 3.925)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.RunSightsPos = Vector(5.226, -2, 0)
SWEP.RunSightsAng = Vector(-18, 36, -13.5)
SWEP.InspectPos = Vector(8, -4.8, -3)
SWEP.InspectAng = Vector(11.199, 38, 0)

SWEP.ViewModelBoneMods = {
	["v_e11_reference001"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(-3, 0, 0), angle = Angle(0, 0, 0) }
}

SWEP.VElements = {
	["e11"] = { type = "Model", model = "models/sw_battlefront/weapons/e11_noscope.mdl", bone = "v_e11_reference001", rel = "", pos = Vector(-1, 6, -3), angle = Angle(0, -90, 0), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["trd"] = { type = "Model", model = "models/props_phx/construct/metal_angle360.mdl", bone = "v_e11_reference001", rel = "e11", pos = Vector(-1.385, -2.75, 5), angle = Angle(90, -5, 0), size = Vector(0.006, 0.006, 0.006), color = Color(255, 120, 0, 255), surpresslightning = true, material = "models/debug/debugwhite", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["e11"] = { type = "Model", model = "models/sw_battlefront/weapons/e11_noscope.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(10, 0.4, 1), angle = Angle(192, 180, 0), size = Vector(1.2, 1.2, 1.2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.Attachments = {
	[1] = { offset = { 0, 0 }, atts = {"mod_stun5","mod_stun10","mod_stun15","mod_stun20"}, sel = 1, order = 1 },
}

SWEP.ThirdPersonReloadDisable		=false
SWEP.Primary.DamageType 			= DMG_BULLET
SWEP.DamageType 					= DMG_BULLET
SWEP.RTScopeAttachment				= -1
SWEP.Scoped_3D 						= false
SWEP.ScopeReticule 					= "#sw/visor/sw_ret_redux_aqua" 
SWEP.Secondary.ScopeZoom 			= 7.5
SWEP.ScopeReticule_Scale 			= {1,1}
if surface then
	SWEP.Secondary.ScopeTable = nil --[[
		{
			scopetex = surface.GetTextureID("scope/gdcw_closedsight"),
			reticletex = surface.GetTextureID("scope/gdcw_acogchevron"),
			dottex = surface.GetTextureID("scope/gdcw_acogcross")
		}
	]]--
end

DEFINE_BASECLASS( SWEP.Base )


local MaxTimer				= 12
local CurrentTimer			= 0

function SWEP:Think(...)
	BaseClass.Think(self, ...)

	if (self.Weapon:Clip1() < self.Primary.ClipSize) and SERVER then
		if (CurrentTimer >= 12) then 
			CurrentTimer = 0
			self.Weapon:SetClip1( self.Weapon:Clip1() + 1 )
		else
			CurrentTimer = CurrentTimer + 1
		end
	end

	if( self.Weapon:Clip1() <= 10 ) then 
		self.VElements["trd"].color = Color(30, 250, 250, 255)
	end

	if( self.Weapon:Clip1() <= 9 ) then
		self.VElements["trd"].color = Color(220, 220, 30, 255)
	end

	if( self.Weapon:Clip1() <= 8 ) then
		self.VElements["trd"].color = Color(200, 200, 30, 255)
	end

	if( self.Weapon:Clip1() <= 7 ) then
		self.VElements["trd"].color = Color(180, 180, 30, 255)
	end

	if( self.Weapon:Clip1() == 6 ) then 
		self.VElements["trd"].color = Color(160, 160, 30, 255)
	end

	if( self.Weapon:Clip1() <= 5 ) then 
		self.VElements["trd"].color = Color(140, 140, 30, 255)
	end

	if( self.Weapon:Clip1() <= 4 ) then
		self.VElements["trd"].color = Color(120, 120, 30, 255)
	end

	if( self.Weapon:Clip1() <= 3 ) then
		self.VElements["trd"].color = Color(100, 100, 30, 255)
	end

	if( self.Weapon:Clip1() <= 2 ) then
		self.VElements["trd"].color = Color(80, 80, 30, 255)
	end

	if( self.Weapon:Clip1() == 1 ) then 
		self.VElements["trd"].color = Color(60, 60, 30, 255)
	end

	if( self.Weapon:Clip1() == 0 ) then 
		self.VElements["trd"].color = Color(30, 30, 30, 255)
	end
end

