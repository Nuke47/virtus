SWEP.Gun							= ("rw_sw_valkenx38")
if (GetConVar(SWEP.Gun.."_allowed")) != nil then
	if not (GetConVar(SWEP.Gun.."_allowed"):GetBool()) then SWEP.Base = "tfa_blacklisted" SWEP.PrintName = SWEP.Gun return end
end
SWEP.Base							= "tfa_sw_scoped_base"
SWEP.Category = "[VirtusRP]"
SWEP.Manufacturer 					= "Unknown Factory"
SWEP.Author							= "ChanceSphere574"
SWEP.Contact						= ""
SWEP.Spawnable						= true
SWEP.AdminSpawnable					= true
SWEP.DrawCrosshair					= true
SWEP.DrawCrosshairIS 				= false
SWEP.PrintName						= "Valken 38x"
SWEP.Type							= "Republic Sniper Blaster Rifle"
SWEP.DrawAmmo						= true
SWEP.data 							= {}
SWEP.data.ironsights				= 1
SWEP.Secondary.IronFOV				= 75
SWEP.Slot							= 4
SWEP.SlotPos						= 100

SWEP.FiresUnderwater 				= true

SWEP.IronInSound 					= nil
SWEP.IronOutSound 					= nil
SWEP.CanBeSilenced					= false
SWEP.Silenced 						= false
SWEP.DoMuzzleFlash 					= false
SWEP.SelectiveFire					= false
SWEP.DisableBurstFire				= false
SWEP.OnlyBurstFire					= false
SWEP.DefaultFireMode 				= "auto"
SWEP.FireModeName 					= nil
SWEP.DisableChambering 				= true

SWEP.Primary.ClipSize				= 10
SWEP.Primary.DefaultClip = 0*4
SWEP.Primary.RPM					= 165
SWEP.Primary.RPM_Burst				= 165
SWEP.Primary.Ammo					= "ar2"
SWEP.Primary.AmmoConsumption 		= 1
SWEP.Primary.Range 					= 40000
SWEP.Primary.RangeFalloff 			= -1
SWEP.Primary.NumShots				= 1
SWEP.Primary.Automatic				= true
SWEP.Primary.RPM_Semi				= nil
SWEP.Primary.BurstDelay				= 0.2
SWEP.Primary.Sound 					= Sound ("w/valken.wav");
SWEP.Primary.ReloadSound 			= Sound ("w/heavy.wav");
SWEP.Primary.PenetrationMultiplier 	= 0
SWEP.Primary.Damage					= 95
SWEP.Primary.HullSize 				= 0
SWEP.DamageType 					= nil

SWEP.DoMuzzleFlash 					= false

SWEP.FireModes = {
	"Single"
}


SWEP.IronRecoilMultiplier			= 0.65
SWEP.CrouchRecoilMultiplier			= 0.85
SWEP.JumpRecoilMultiplier			= 2
SWEP.WallRecoilMultiplier			= 1.1
SWEP.ChangeStateRecoilMultiplier	= 1.2
SWEP.CrouchAccuracyMultiplier		= 0.8
SWEP.ChangeStateAccuracyMultiplier	= 1
SWEP.JumpAccuracyMultiplier			= 10
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
SWEP.ViewModelFOV					= 70
SWEP.ViewModelFlip					= false
SWEP.MaterialTable 					= nil
SWEP.UseHands 						= true
SWEP.HoldType 						= "ar2"
SWEP.ReloadHoldTypeOverride 		= "ar2"

SWEP.ShowWorldModel = false

SWEP.BlowbackEnabled 				= true
SWEP.BlowbackVector 				= Vector(0,-1,0.05)
SWEP.BlowbackCurrentRoot			= 0
SWEP.BlowbackCurrent 				= 0
SWEP.BlowbackBoneMods 				= nil
SWEP.Blowback_Only_Iron 			= true
SWEP.Blowback_PistolMode 			= false
SWEP.Blowback_Shell_Enabled 		= false
SWEP.Blowback_Shell_Effect 			= "None"

SWEP.Tracer = 0
SWEP.TracerName 					= "rw_sw_laser_blue"
SWEP.TracerCount 					= 1
SWEP.TracerLua = true
SWEP.TracerDelay					= 0.01
SWEP.ImpactEffect 					= "rw_sw_impact_blue"
SWEP.ImpactDecal 					= "FadingScorch"

SWEP.VMPos = Vector(1.96, 0, -2)
SWEP.VMAng = Vector(0,0,0)

SWEP.IronSightTime 					= 0.5
SWEP.Primary.KickUp					= 0.3
SWEP.Primary.KickDown				= 0.18
SWEP.Primary.KickHorizontal			= 0.055
SWEP.Primary.StaticRecoilFactor 	= 0.65
SWEP.Primary.Spread					= 0.015
SWEP.Primary.IronAccuracy 			= 0.001
SWEP.Primary.SpreadMultiplierMax 	= 1.5
SWEP.Primary.SpreadIncrement 		= 0.35
SWEP.Primary.SpreadRecovery 		= 0.98
SWEP.DisableChambering 				= true
SWEP.MoveSpeed 						= 1
SWEP.IronSightsMoveSpeed 			= 0.85

SWEP.IronSightsPos = Vector(-5.09, -5.75, 2.66)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.RunSightsPos = Vector(5.226, -2, 0)
SWEP.RunSightsAng = Vector(-18, 36, -13.5)
SWEP.InspectPos = Vector(8, -4.8, -3)
SWEP.InspectAng = Vector(11.199, 38, 0)

SWEP.ViewModelBoneMods = {
	["v_dlt19_reference001"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(-3, 0, 0), angle = Angle(0, 0, 0) }
}

SWEP.VElements = {
	["valken"] = { type = "Model", model = "models/sw_battlefront/weapons/valken_38x.mdl", bone = "v_dlt19_reference001", rel = "", pos = Vector(0.5, 3, -0.5), angle = Angle(0, -90, 0), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["scope"] = { type = "Model", model = "models/rtcircle.mdl", bone = "v_dlt19_reference001", rel = "valken", pos = Vector(-1.3, 0, 5.98), angle = Angle(0, 180, 0), size = Vector(0.25, 0.25, 0.25), color = Color(255, 255, 255, 255), surpresslightning = false, material = "!tfa_rtmaterial", skin = 0, bodygroup = {} }
}	

SWEP.WElements = {
	["valken"] = { type = "Model", model = "models/sw_battlefront/weapons/valken_38x.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3, 0.4, -0.5), angle = Angle(-13, 0, 180), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
}

SWEP.ThirdPersonReloadDisable		=false
SWEP.Primary.DamageType 			= DMG_BULLET
SWEP.DamageType 					= DMG_BULLET
SWEP.RTScopeAttachment				= -1
SWEP.Scoped_3D 						= false
SWEP.ScopeReticule 					= "#sw/visor/sw_ret_redux_blue" 
SWEP.Secondary.ScopeZoom 			= 12
SWEP.ScopeReticule_Scale 			= {1.05,1.05}

if surface then
	SWEP.Secondary.ScopeTable = {
		["ScopeMaterial"] =  Material("#sw/visor/sw_ret_redux_blue.png", "smooth"),
		["ScopeBorder"] = color_black,
		["ScopeCrosshair"] = { ["r"] = 0, ["g"]  = 0, ["b"] = 0, ["a"] = 0, ["s"] = 1 }
	}
end

DEFINE_BASECLASS( SWEP.Base )

