SWEP.Gun							= ("gun_base")
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
SWEP.PrintName						= "Training DLT-19"
SWEP.Type							= "Imperial Training Heavy Blaster Rifle"
SWEP.DrawAmmo						= true
SWEP.data 							= {}
SWEP.data.ironsights				= 1
SWEP.Secondary.IronFOV				= 75
SWEP.Slot							= 3
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

SWEP.Primary.ClipSize				= 50
SWEP.Primary.DefaultClip = 0*4
SWEP.Primary.RPM					= 600
SWEP.Primary.RPM_Burst				= 600
SWEP.Primary.Ammo					= "ar2"
SWEP.Primary.AmmoConsumption 		= 1
SWEP.Primary.Range 					= 40000
SWEP.Primary.RangeFalloff 			= -1
SWEP.Primary.NumShots				= 1
SWEP.Primary.Automatic				= true
SWEP.Primary.RPM_Semi				= nil
SWEP.Primary.BurstDelay				= 0.2
SWEP.Primary.Sound 					= Sound ("w/dlt19.wav");
SWEP.Primary.ReloadSound 			= Sound ("w/heavy.wav");
SWEP.Primary.PenetrationMultiplier 	= 0
SWEP.Primary.Damage					= 5.5
SWEP.Primary.HullSize 				= 0
SWEP.DamageType 					= nil

SWEP.DoMuzzleFlash 					= false

SWEP.FireModes = {
	"Automatic",
	"Single"
}


SWEP.IronRecoilMultiplier			= 0.65
SWEP.CrouchRecoilMultiplier			= 0.85
SWEP.JumpRecoilMultiplier			= 2
SWEP.WallRecoilMultiplier			= 1.1
SWEP.ChangeStateRecoilMultiplier	= 1.2
SWEP.CrouchAccuracyMultiplier		= 0.8
SWEP.ChangeStateAccuracyMultiplier	= 1
SWEP.JumpAccuracyMultiplier			= 2.6
SWEP.WalkAccuracyMultiplier			= 1.8
SWEP.NearWallTime 					= 0.5
SWEP.ToCrouchTime 					= 0.25
SWEP.WeaponLength 					= 35
SWEP.SprintFOVOffset 				= 12
SWEP.ProjectileVelocity 			= 9

SWEP.ProjectileEntity 				= nil
SWEP.ProjectileModel 				= nil

SWEP.ViewModel						= "models/weapons/synbf3/c_dlt19.mdl"
SWEP.WorldModel						= "models/weapons/synbf3/w_dlt19.mdl"
SWEP.ViewModelFOV					= 75
SWEP.ViewModelFlip					= false
SWEP.MaterialTable 					= nil
SWEP.UseHands 						= true
SWEP.HoldType 						= "ar2"
SWEP.ReloadHoldTypeOverride 		= "ar2"

SWEP.ShowWorldModel = false

SWEP.BlowbackEnabled 				= true
SWEP.BlowbackVector 				= Vector(0,-1.5,-0.05)
SWEP.BlowbackCurrentRoot			= 0
SWEP.BlowbackCurrent 				= 0
SWEP.BlowbackBoneMods 				= nil
SWEP.Blowback_Only_Iron 			= true
SWEP.Blowback_PistolMode 			= false
SWEP.Blowback_Shell_Enabled 		= false
SWEP.Blowback_Shell_Effect 			= "None"

SWEP.Tracer = 0
SWEP.TracerName 					= "rw_sw_laser_orange"
SWEP.TracerCount 					= 1
SWEP.TracerLua = true
SWEP.TracerDelay					= 0.01
SWEP.ImpactEffect 					= "rw_sw_impact_orange"
SWEP.ImpactDecal 					= "FadingScorch"

SWEP.VMPos = Vector(0, -06, -02)
SWEP.VMAng = Vector(0.5, 0, 0)

SWEP.IronSightTime 					= 0.45
SWEP.Primary.KickUp					= 0.12
SWEP.Primary.KickDown				= 0.09
SWEP.Primary.KickHorizontal			= 0.055
SWEP.Primary.StaticRecoilFactor 	= 0.65
SWEP.Primary.Spread					= 0.015
SWEP.Primary.IronAccuracy 			= 0.005
SWEP.Primary.SpreadMultiplierMax 	= 1.5
SWEP.Primary.SpreadIncrement 		= 0.35
SWEP.Primary.SpreadRecovery 		= 0.98
SWEP.DisableChambering 				= true
SWEP.MoveSpeed 						= 1
SWEP.IronSightsMoveSpeed 			= 0.85

SWEP.IronSightsPos = Vector(-3.1, -5, 3.8)
SWEP.IronSightsAng = Vector(1, 0, 0)
SWEP.RunSightsPos = Vector(5.226, -2, 0)
SWEP.RunSightsAng = Vector(-18, 36, -13.5)
SWEP.InspectPos = Vector(8, -4.8, -3)
SWEP.InspectAng = Vector(11.199, 38, 0)

SWEP.ViewModelBoneMods = {
	["v_dlt19_reference001"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}

SWEP.VElements = {
	["dlt19"] = { type = "Model", model = "models/kuro/sw_battlefront/weapons/bf1/dlt19.mdl", bone = "v_dlt19_reference001", rel = "", pos = Vector(0.5, -1, -4), angle = Angle(0, -90, 0), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["trd"] = { type = "Model", model = "models/squad/sf_plates/sf_plate1x1.mdl", bone = "v_dlt19_reference001", rel = "dlt19", pos = Vector(7, 0.57, 7.6), angle = Angle(0, 90, 0), size = Vector(0.1, 0.2, 0.1), color = Color(255, 120, 0, 255), surpresslightning = true, material = "models/debug/debugwhite", skin = 0, bodygroup = {} }
}	

SWEP.WElements = {
	["dlt19"] = { type = "Model", model = "models/kuro/sw_battlefront/weapons/bf1/dlt19.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.5, 0.5, 3), angle = Angle(-13, 0, 180), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.ThirdPersonReloadDisable		=false
SWEP.Primary.DamageType 			= DMG_BULLET
SWEP.DamageType 					= DMG_BULLET
SWEP.RTScopeAttachment				= -1
SWEP.Scoped_3D 						= false
SWEP.ScopeReticule 					= "scope/gdcw_elcanreticle" 
SWEP.Secondary.ScopeZoom 			= 3
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

function SWEP:Think(...)
	BaseClass.Think(self, ...)
	self.VElements["trd"].color = Color((self.Weapon:Clip1()/self.Primary.ClipSize)*255, (self.Weapon:Clip1()/self.Primary.ClipSize)*120, 0, 255)	
end

