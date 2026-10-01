SWEP.Base = "tfa_sw_gun_base"
SWEP.Category = "[VirtusRP]"
SWEP.Manufacturer 					= ""
SWEP.Author							= "Ki_Banana"
SWEP.Contact						= "Ki_Banana"
SWEP.Spawnable						= true
SWEP.AdminSpawnable					= true
SWEP.DrawCrosshair					= true
SWEP.DrawCrosshairIS 				= false
SWEP.PrintName						= "E-5 Blaster Rifle"
SWEP.SubCategory 					= "Confederacy of Independent Systems"
SWEP.Type							= "Blaster Rifle"
SWEP.DrawAmmo						= true
SWEP.data 							= {}
SWEP.data.ironsights				= 1
SWEP.Secondary.IronFOV				= 85
SWEP.Slot							= 2
SWEP.SlotPos						= 5

SWEP.FiresUnderwater 				= false

SWEP.IronInSound 					= nil
SWEP.IronOutSound 					= nil
SWEP.CanBeSilenced					= false
SWEP.Silenced 						= false
SWEP.DoMuzzleFlash 					= true
SWEP.MuzzleFlashEffect 				= "ar2"
SWEP.SelectiveFire					= false
SWEP.DisableBurstFire				= true
SWEP.OnlyBurstFire					= false
SWEP.DefaultFireMode 				= "Auto"
SWEP.FireModeName 					= nil
SWEP.DisableChambering 				= true

SWEP.Primary.ClipSize				= 30
SWEP.Primary.DefaultClip = 0*5
SWEP.Primary.RPM					= 375
SWEP.Primary.AmmoConsumption 		= 1

SWEP.Primary.Range 					= 29770
SWEP.Primary.RangeFalloff 			= -1

SWEP.Primary.NumShots				= 1
SWEP.Primary.Automatic				= true
SWEP.Primary.BurstDelay				= 0.15
SWEP.Primary.Sound 					= Sound ("w/e5.wav")
SWEP.Primary.ReloadSound 			= Sound ("weapons/bf3/rifles.wav")
SWEP.Primary.PenetrationMultiplier 	= 0
SWEP.Primary.Damage					= 30
SWEP.Primary.HullSize 				= 0
SWEP.Primary.Sound_DryFire          = Sound("weapons/bf3/click.wav")

SWEP.DoMuzzleFlash 					= true
SWEP.CustomMuzzleFlash 				= true

SWEP.IronRecoilMultiplier			= 0.5
SWEP.CrouchRecoilMultiplier			= 0.75
SWEP.JumpRecoilMultiplier			= 1.3
SWEP.WallRecoilMultiplier			= 1.1
SWEP.ChangeStateRecoilMultiplier	= 1.3

SWEP.CrouchAccuracyMultiplier		= 0.75
SWEP.ChangeStateAccuracyMultiplier	= 1.18
SWEP.JumpAccuracyMultiplier			= 5
SWEP.WalkAccuracyMultiplier			= 2

SWEP.NearWallTime 					= 0.25
SWEP.ToCrouchTime 					= 0.1
SWEP.WeaponLength 					= 35

SWEP.ViewModel						= "models/Fallout/fonv/plasmarifle/e5/c_fallout_plasma_rifle.mdl"
SWEP.WorldModel						= "models/Fallout/fonv/laer/w_fallout_laer.mdl"
SWEP.ViewModelFOV					= 70
SWEP.ViewModelFlip					= false
SWEP.MaterialTable 					= nil
SWEP.UseHands 						= true
SWEP.HoldType 						= "ar2"
SWEP.ReloadHoldTypeOverride 		= "ar2"

SWEP.BlowbackEnabled 				= true
SWEP.BlowbackVector 				= Vector(0,0,0)
SWEP.BlowbackCurrentRoot			= 0
SWEP.BlowbackCurrent 				= 0
SWEP.BlowbackBoneMods 				= nil
SWEP.Blowback_Only_Iron 			= true
SWEP.Blowback_PistolMode 			= false
SWEP.Blowback_Shell_Enabled 		= false
SWEP.Blowback_Shell_Effect 			= "None"

SWEP.IronSightTime 					= 0.4

SWEP.Primary.KickUp					= 0.35
SWEP.Primary.KickDown				= 0.35
SWEP.Primary.KickHorizontal			= 0.25
SWEP.Primary.StaticRecoilFactor 	= 0.5

SWEP.Primary.Spread					= .012
SWEP.Primary.IronAccuracy 			= .002

SWEP.Primary.SpreadMultiplierMax 	= 1
SWEP.Primary.SpreadIncrement 		= 1
SWEP.Primary.SpreadRecovery 		= 6

SWEP.DisableChambering 				= true
SWEP.MoveSpeed 						= .85
SWEP.IronSightsMoveSpeed 			= .7

SWEP.IronSightsPos = Vector(-3.3, 3, 1.3)
SWEP.IronSightsAng = Vector(0.6, -1.65, 0)

SWEP.RunSightsPos = Vector(1, -3.5, -4)
SWEP.RunSightsAng = Vector(-10, 37, -30)

SWEP.InspectPos = Vector(8, 0, -3)
SWEP.InspectAng = Vector(15.5, 42, 0)

SWEP.VMPos = Vector(-3.25, 4, -2)
SWEP.VMAng = Vector(1, 1, 0)

SWEP.VElements = {
	["e5"] = { type = "Model", model = "models/kuro/sw_battlefront/weapons/e5_blaster.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(4.2, 1.3, 1.2), angle = Angle(0, 3, 180), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["e5"] = { type = "Model", model = "models/kuro/sw_battlefront/weapons/e5_blaster.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(4.879, 1.187, 2.127), angle = Angle(-11.275, 2.697, 180), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.ViewModelBoneMods = {
	["Plasma"] = { scale = Vector(0, 0, 0), pos = Vector(-8.3,-0.3,0.7), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(1.3, -2, 0.5), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0.2, 0, 0), angle = Angle(40, 0, 0) },
	["ValveBiped.Bip01_L_Finger0"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -10, 0) },
	["ValveBiped.Bip01_L_Finger01"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(10, -35, 10) },
	["ValveBiped.Bip01_L_Finger1"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-20, -60, 0) },
	["ValveBiped.Bip01_L_Finger2"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, -60, 0) },
	["ValveBiped.Bip01_L_Finger3"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -55, 0) },
	["ValveBiped.Bip01_L_Finger4"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(20, -60, 0) },
	["ValveBiped.Bip01_R_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(0, -2, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Finger1"] = { scale = Vector(1, 1, 1), pos = Vector(-0.5, 0, 0), angle = Angle(-20, 0, 0) },
	["ValveBiped.Bip01_R_Finger2"] = { scale = Vector(1, 1, 1), pos = Vector(0, -0.2, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Finger3"] = { scale = Vector(1, 1, 1), pos = Vector(0, -0.2, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Finger4"] = { scale = Vector(1, 1, 1), pos = Vector(0, -0.2, 0), angle = Angle(0, 0, 0) },
}


SWEP.Offset = {
	Pos = {
		Up = -7,
		Right = 0.6,
		Forward = 17.5
	},
	Ang = {
		Up = 91,
		Right = 0,
		Forward = 190
	},
	Scale = 0
}

SWEP.ThirdPersonReloadDisable		= false
SWEP.Primary.DamageType 			= DMG_ENERGYBEAM
SWEP.DamageType 					= DMG_ENERGYBEAM
SWEP.RTScopeAttachment				= -1
SWEP.Scoped_3D 						= false
SWEP.ScopeReticule 					= "scope/star_ret_red" 
SWEP.Secondary.ScopeZoom 			= 4
SWEP.ScopeReticule_Scale 			= {1.31,1.31}

DEFINE_BASECLASS( SWEP.Base )

SWEP.TracerName 					= "tfa_effect_swrp_laser_red"
SWEP.MuzzleFlashEffect 				= "tfa_swrp_muzzleflash_red"
SWEP.Primary.ColorR 				= 255
SWEP.Primary.ColorG 				= 0
SWEP.Primary.ColorB 				= 0
SWEP.Primary.Ammo					= "redtibanna"
SWEP.ImpactDecal 					= "FadingScorch"


