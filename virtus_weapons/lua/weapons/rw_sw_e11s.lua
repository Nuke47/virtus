SWEP.Gun							= ("gun_base")
if (GetConVar(SWEP.Gun.."_allowed")) != nil then
	if not (GetConVar(SWEP.Gun.."_allowed"):GetBool()) then SWEP.Base = "tfa_blacklisted" SWEP.PrintName = SWEP.Gun return end
end
SWEP.Base = "tfa_sw_scoped_base"
SWEP.Category = "[VirtusRP]"
SWEP.Manufacturer 					= "Blastech Industries"
SWEP.Author							= "ChanceSphere574"
SWEP.Contact						= ""
SWEP.Spawnable						= true
SWEP.AdminSpawnable					= true
SWEP.DrawCrosshair					= true
SWEP.DrawCrosshairIS 				= false
SWEP.PrintName						= "E-11S"
SWEP.Type							= "Imperial Sniper Blaster"
SWEP.DrawAmmo						= true
SWEP.data 							= {}
SWEP.data.ironsights				= 1
SWEP.Secondary.IronFOV				= 78
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
SWEP.DefaultFireMode 				= "single"
SWEP.FireModeName 					= nil
SWEP.DisableChambering 				= true

SWEP.Primary.ClipSize				= 9
SWEP.Primary.DefaultClip = 0*5
SWEP.Primary.RPM					= 135
SWEP.Primary.RPM_Burst				= 135
SWEP.Primary.Ammo					= "ar2"
SWEP.Primary.AmmoConsumption 		= 1
SWEP.Primary.Range 					= 35000
SWEP.Primary.RangeFalloff 			= -1
SWEP.Primary.NumShots				= 1
SWEP.Primary.Automatic				= false
SWEP.Primary.RPM_Semi				= nil
SWEP.Primary.BurstDelay				= 0.2
SWEP.Primary.Sound 					= Sound ("w/e11s.wav");
SWEP.Primary.ReloadSound 			= Sound ("w/heavy.wav");
SWEP.Primary.PenetrationMultiplier 	= 0
SWEP.Primary.Damage					= 125
SWEP.Primary.HullSize 				= 0
SWEP.DamageType 					= nil
SWEP.LuaShellEffect 				= nil

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

SWEP.ShowWorldModel = false
SWEP.LuaShellEject = false


SWEP.BlowbackEnabled 				= true
SWEP.BlowbackVector 				= Vector(0,-0.5,0)
SWEP.BlowbackCurrentRoot			= 0
SWEP.BlowbackCurrent 				= 0
SWEP.BlowbackBoneMods 				= nil
SWEP.Blowback_Only_Iron 			= true
SWEP.Blowback_PistolMode 			= false
SWEP.Blowback_Shell_Enabled 		= false
SWEP.Blowback_Shell_Effect 			= ""

SWEP.Tracer = 0
SWEP.TracerName 					= "rw_sw_laser_red"
SWEP.TracerCount 					= 1
SWEP.TracerLua = true
SWEP.TracerDelay					= 0.01
SWEP.ImpactEffect 					= "rw_sw_impact_red"
SWEP.ImpactDecal 					= "FadingScorch"

SWEP.VMPos = Vector(1, 0, -1)
SWEP.VMAng = Vector(0,0,0)

SWEP.IronSightTime 					= 0.55
SWEP.Primary.KickUp					= 0.2
SWEP.Primary.KickDown				= 0.15
SWEP.Primary.KickHorizontal			= 0.008
SWEP.Primary.StaticRecoilFactor 	= 0.65
SWEP.Primary.Spread					= 0.035
SWEP.Primary.IronAccuracy 			= 0.0001
SWEP.Primary.SpreadMultiplierMax 	= 1.5
SWEP.Primary.SpreadIncrement 		= 0.35
SWEP.Primary.SpreadRecovery 		= 0.98
SWEP.DisableChambering 				= true
SWEP.MoveSpeed 						= 1
SWEP.IronSightsMoveSpeed 			= 0.85

SWEP.IronSightsPos = Vector( -4.345, -3, 2.125)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.RunSightsPos = Vector(5.226, -2, -1.5)
SWEP.RunSightsAng = Vector(-22, 32.50, -19)
SWEP.InspectPos = Vector(8, -4.8, -3)
SWEP.InspectAng = Vector(11.199, 38, 0)

SWEP.ViewModelBoneMods = {
	["v_dlt19_reference001"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}

SWEP.VElements = {
    ["e5s"] = { type = "Model", model = "models/rising/w_e11s.mdl", bone = "v_dlt19_reference001", rel = "", pos = Vector(-0.85, 7.5, 2.25), angle = Angle(0, 0, 0), size = Vector(1.1, 1.1, 1.1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {[3] = 1, [4] = 1, [5] = 0} },
    ["scope"] = { type = "Model", model = "models/rtcircle.mdl", bone = "v_dlt19_reference001", rel = "e5s", pos = Vector(1.135, -12.35, 2.745), angle = Angle(0, 90, 0), size = Vector(0.21, 0.21, 0.21), color = Color(255, 255, 255, 255), surpresslightning = false, material = "!tfa_rtmaterial", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
    ["e5s"] = { type = "Model", model = "models/rising/w_e11s.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(10.5, 0, -05.2), angle = Angle(0, -90, 169), size = Vector(1.1, 1.1, 1.1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {[3] = 1, [4] = 1, [5] = 0} }
}

SWEP.ThirdPersonReloadDisable		=false
SWEP.Primary.DamageType 			= DMG_BULLET
SWEP.DamageType 					= DMG_BULLET
SWEP.RTScopeAttachment				= -1
SWEP.Scoped_3D 						= false
SWEP.ScopeReticule 					= "#sw/visor/sw_ret_redux_red" 
SWEP.Secondary.ScopeZoom 			= 10
SWEP.ScopeReticule_Scale 			= {1.02,1.02}

if surface then
	SWEP.Secondary.ScopeTable = {
		["ScopeMaterial"] =  Material("#sw/visor/sw_ret_redux_red.png", "smooth"),
		["ScopeBorder"] = color_black,
		["ScopeCrosshair"] = { ["r"] = 0, ["g"]  = 0, ["b"] = 0, ["a"] = 0, ["s"] = 1 }
	}
end

DEFINE_BASECLASS( SWEP.Base )

