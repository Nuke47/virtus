SWEP.Gun							= ("rw_sw_dc15s")
if (GetConVar(SWEP.Gun.."_allowed")) != nil then
	if not (GetConVar(SWEP.Gun.."_allowed"):GetBool()) then SWEP.Base = "tfa_blacklisted" SWEP.PrintName = SWEP.Gun return end
end
SWEP.Base = "tfa_sw_gun_base"
SWEP.Category = "[VirtusRP]"
SWEP.Manufacturer 					= "BlasTech Industries"
SWEP.Author							= "ChanceSphere574"
SWEP.Contact						= ""
SWEP.Spawnable						= true
SWEP.AdminSpawnable					= true
SWEP.DrawCrosshair					= true
SWEP.DrawCrosshairIS 				= false
SWEP.PrintName						= "Stun DC-15S"
SWEP.Type							= "Republic Stun Light Blaster Carabine"
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
SWEP.DefaultFireMode 				= "auto"
SWEP.FireModeName 					= nil
SWEP.DisableChambering 				= true

SWEP.Primary.ClipSize				= 25
SWEP.Primary.DefaultClip = 0*5
SWEP.Primary.RPM					= 375
SWEP.Primary.RPM_Burst				= 375
SWEP.Primary.Ammo					= "ar2"
SWEP.Primary.AmmoConsumption 		= 1
SWEP.Primary.Range 					= 40000
SWEP.Primary.RangeFalloff 			= -1
SWEP.Primary.NumShots				= 1
SWEP.Primary.Automatic				= true
SWEP.Primary.RPM_Semi				= nil
SWEP.Primary.BurstDelay				= 0.2
SWEP.Primary.Sound 					= Sound ("w/dc15.wav");
SWEP.Primary.ReloadSound 			= Sound ("w/rifles.wav");
SWEP.Primary.PenetrationMultiplier 	= 0
SWEP.Primary.Damage					= 30
SWEP.Primary.HullSize 				= 0
SWEP.DamageType 					= nil

SWEP.DoMuzzleFlash 					= false

SWEP.FireModes = {
	"Auto",
	"Single"
}


SWEP.IronRecoilMultiplier			= 0.5
SWEP.CrouchRecoilMultiplier			= 0.55
SWEP.JumpRecoilMultiplier			= 1.3
SWEP.WallRecoilMultiplier			= 1.1
SWEP.ChangeStateRecoilMultiplier	= 1.3
SWEP.CrouchAccuracyMultiplier		= 0.5
SWEP.ChangeStateAccuracyMultiplier	= 1.18
SWEP.JumpAccuracyMultiplier			= 2
SWEP.WalkAccuracyMultiplier			= 1.8
SWEP.NearWallTime 					= 0.5
SWEP.ToCrouchTime 					= 0.25
SWEP.WeaponLength 					= 35
SWEP.SprintFOVOffset 				= 12
SWEP.ProjectileVelocity 			= 9

SWEP.ProjectileEntity 				= nil
SWEP.ProjectileModel 				= nil

SWEP.ViewModel						= "models/bf2017/c_e11.mdl"
SWEP.WorldModel						= "models/bf2017/w_e11.mdl"
SWEP.ViewModelFOV					= 75
SWEP.ViewModelFlip					= false
SWEP.MaterialTable 					= nil
SWEP.UseHands 						= true
SWEP.HoldType 						= "smg"
SWEP.ReloadHoldTypeOverride 		= "smg"

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
SWEP.TracerName 					= "rw_sw_laser_blue"
SWEP.TracerCount 					= 1
SWEP.TracerLua = true
SWEP.TracerDelay					= 0.01
SWEP.ImpactEffect 					= "rw_sw_impact_blue"
SWEP.ImpactDecal 					= "FadingScorch"

SWEP.VMPos = Vector(2, -7, -1.5)
SWEP.VMAng = Vector(0,0,0)

SWEP.IronSightTime 					= 0.4
SWEP.Primary.KickUp					= 0.1
SWEP.Primary.KickDown				= 0.08
SWEP.Primary.KickHorizontal			= 0.08
SWEP.Primary.StaticRecoilFactor 	= 0.6
SWEP.Primary.Spread					= 0.02
SWEP.Primary.IronAccuracy 			= 0.005
SWEP.Primary.SpreadMultiplierMax 	= 2.3
SWEP.Primary.SpreadIncrement 		= 0.2
SWEP.Primary.SpreadRecovery 		= 0.8
SWEP.DisableChambering 				= true
SWEP.MoveSpeed 						= 1
SWEP.IronSightsMoveSpeed 			= 0.85

SWEP.IronSightsPos = Vector(-5, -8, 4.2)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.RunSightsPos = Vector(5.226, -2, 0)
SWEP.RunSightsAng = Vector(-18, 36, -13.5)
SWEP.InspectPos = Vector(8, -4.8, -3)
SWEP.InspectAng = Vector(11.199, 38, 0)

SWEP.Attachments = {
	[1] = { offset = { 0, 0 }, atts = {"rw_rep_mod_stun5","rw_rep_mod_stun10","rw_rep_mod_stun20","rw_rep_mod_stun30"}, order = 1 },
}

SWEP.ViewModelBoneMods = {
	["v_e11_reference001"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(-3, 0, 0), angle = Angle(0, 0, 0) }
}

SWEP.VElements = {
	["dc15s"] = { type = "Model", model = "models/sw_battlefront/weapons/dc15s_carbine.mdl", bone = "v_e11_reference001", rel = "", pos = Vector(-1.1, 2.2, 0), angle = Angle(1, -90, 0), size = Vector(1.3, 1.3, 1.3), color = Color(255, 255, 255, 255), surpresslightning = false, material = "models/sw_battlefront/weapons/dc15s/t_dc15a_cs", skin = 0, bodygroup = {} },
	["trd"] = { type = "Model", model = "models/hunter/plates/plate025.mdl", bone = "v_e11_reference001", rel = "", pos = Vector(-01.1, 9.9, 3.7), angle = Angle(0, 90, 0), size = Vector(0.1, 0.07, 0.1), color = Color(255, 120, 0, 255), surpresslightning = true, material = "models/debug/debugwhite", skin = 0, bodygroup = {} }

}

SWEP.WElements = {
	["dc15s"] = { type = "Model", model = "models/sw_battlefront/weapons/dc15s_carbine.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3, 0.4, -0.5), angle = Angle(-13, 0, 180), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "models/sw_battlefront/weapons/dc15s/t_dc15a_cs", skin = 0, bodygroup = {} }
}

SWEP.ThirdPersonReloadDisable		=false
SWEP.Primary.DamageType 			= DMG_BULLET
SWEP.DamageType 					= DMG_BULLET
SWEP.RTScopeAttachment				= -1
SWEP.Scoped_3D 						= false
SWEP.ScopeReticule 					= "scope/gdcw_elcanreticle" 
SWEP.Secondary.ScopeZoom 			= 0
SWEP.ScopeReticule_Scale 			= {1.1,1.1}
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

local CurrentTimer			= 0

function SWEP:Think(...)
	BaseClass.Think(self, ...)
	if( self:IsAttached("rw_rep_mod_stun5") or self:IsAttached("rw_rep_mod_stun10") or self:IsAttached("rw_rep_mod_stun20") or self:IsAttached("rw_rep_mod_stun30")) then 
		self.VElements["trd"].color = Color(0, 150, 255, 255)
	else
		self.VElements["trd"].color = Color(200, 200, 200, 255)

	end
end

