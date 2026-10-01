SWEP.Gun							= ("gun_base")
if (GetConVar(SWEP.Gun.."_allowed")) != nil then
	if not (GetConVar(SWEP.Gun.."_allowed"):GetBool()) then SWEP.Base = "tfa_blacklisted" SWEP.PrintName = SWEP.Gun return end
end
SWEP.Base = "tfa_sw_gun_base"
SWEP.Category = "[VirtusRP]"
SWEP.Manufacturer 					= "Concordian Crescent Technologies"
SWEP.Author							= "ChanceSphere574"
SWEP.Contact						= ""
SWEP.Spawnable						= true
SWEP.AdminSpawnable					= true
SWEP.DrawCrosshair					= true
SWEP.DrawCrosshairIS 				= false
SWEP.PrintName						= "Westar-35"
SWEP.Type							= "Galactic Blaster Pistol"
SWEP.DrawAmmo						= true
SWEP.data 							= {}
SWEP.data.ironsights				= 1
SWEP.Secondary.IronFOV				= 75
SWEP.Slot							= 1
SWEP.SlotPos						= 100

SWEP.FiresUnderwater 				= true

SWEP.IronInSound 					= nil --Sound ("w/sw_in.wav");
SWEP.IronOutSound 					= nil --Sound ("w/sw_out.wav");
SWEP.CanBeSilenced					= false
SWEP.Silenced 						= false
SWEP.DoMuzzleFlash 					= false
SWEP.SelectiveFire					= true
SWEP.DisableBurstFire				= false
SWEP.OnlyBurstFire					= false
SWEP.DefaultFireMode 				= "Single"
SWEP.FireModeName 					= nil
SWEP.DisableChambering 				= true

SWEP.Primary.ClipSize				= 22
SWEP.Primary.DefaultClip = 0*5
SWEP.Primary.RPM					= 260
SWEP.Primary.RPM_Burst				= 260*2
SWEP.Primary.Ammo					= "ar2"
SWEP.Primary.AmmoConsumption 		= 1
SWEP.Primary.Range 					= 32000
SWEP.Primary.RangeFalloff 			= -1
SWEP.Primary.NumShots				= 1
SWEP.Primary.Automatic				= false
SWEP.Primary.RPM_Semi				= nil
SWEP.Primary.BurstDelay				= 0.3
SWEP.Primary.Sound 					= Sound ("w/westar35.wav");
SWEP.Primary.ReloadSound 			= Sound ("w/pistols.wav");
SWEP.Primary.PenetrationMultiplier 	= 0
SWEP.Primary.Damage					= 35
SWEP.Primary.HullSize 				= 0
SWEP.DamageType 					= nil

SWEP.DoMuzzleFlash 					= false

SWEP.FireModes = {
	"2Burst",
	"Single"
}

SWEP.IronRecoilMultiplier			= 0.44
SWEP.CrouchRecoilMultiplier			= 0.33
SWEP.JumpRecoilMultiplier			= 1.3
SWEP.WallRecoilMultiplier			= 1.1
SWEP.ChangeStateRecoilMultiplier	= 1.18
SWEP.CrouchAccuracyMultiplier		= 0.7
SWEP.ChangeStateAccuracyMultiplier	= 1
SWEP.JumpAccuracyMultiplier			= 2.6
SWEP.WalkAccuracyMultiplier			= 1.18
SWEP.NearWallTime 					= 0.25
SWEP.ToCrouchTime 					= 0.1
SWEP.WeaponLength 					= 35
SWEP.SprintFOVOffset 				= 12
SWEP.ProjectileVelocity 			= 9

SWEP.ProjectileEntity 				= nil
SWEP.ProjectileModel 				= nil

SWEP.ViewModel						= "models/bf2017/c_scoutblaster.mdl"
SWEP.WorldModel						= "models/bf2017/w_scoutblaster.mdl"
SWEP.ViewModelFOV					= 75
SWEP.ViewModelFlip					= false
SWEP.MaterialTable 					= nil
SWEP.UseHands 						= true
SWEP.HoldType 						= "pistol"

SWEP.ShowWorldModel = false

SWEP.BlowbackEnabled 				= true
SWEP.BlowbackVector 				= Vector(0,-2,-0.075)
SWEP.BlowbackCurrentRoot			= 0
SWEP.BlowbackCurrent 				= 0
SWEP.BlowbackBoneMods 				= nil
SWEP.Blowback_Only_Iron 			= true
SWEP.Blowback_PistolMode 			= false
SWEP.Blowback_Shell_Enabled 		= false
SWEP.Blowback_Shell_Effect 			= "None"

SWEP.Tracer = 0
SWEP.TracerName 					= "rw_sw_laser_yellow"
SWEP.TracerCount 					= 1
SWEP.TracerLua = true
SWEP.TracerDelay					= 0.01
SWEP.ImpactEffect 					= "rw_sw_impact_yellow"
SWEP.ImpactDecal 					= "FadingScorch"

SWEP.VMPos = Vector(0.91, -9, -0.175)
SWEP.VMAng = Vector(0,0,0)

SWEP.IronSightTime 					= 0.3
SWEP.Primary.KickUp					= 0.35
SWEP.Primary.KickDown				= 0.15
SWEP.Primary.KickHorizontal			= 0.055
SWEP.Primary.StaticRecoilFactor 	= 0.5
SWEP.Primary.Spread					= 0.025
SWEP.Primary.IronAccuracy 			= 0.005
SWEP.Primary.SpreadMultiplierMax 	= 1.5
SWEP.Primary.SpreadIncrement 		= 0.3
SWEP.Primary.SpreadRecovery 		= 0.98
SWEP.DisableChambering 				= true
SWEP.MoveSpeed 						= 1
SWEP.IronSightsMoveSpeed 			= 0.85

SWEP.IronSightsPos = Vector(-4.9, -6, 2.9)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.RunSightsPos = Vector(2, -9.5, -15)
SWEP.RunSightsAng = Vector(39, -0.5, -2)
SWEP.InspectPos = Vector(8, -4.8, -3)
SWEP.InspectAng = Vector(11.199, 38, 0)

SWEP.ViewModelBoneMods = {
	["v_scoutblaster_reference001"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, -0.3, 0), angle = Angle(0, 0, 0) }
}

SWEP.VElements = {
	["w35"] = { type = "Model", model = "models/sw_battlefront/weapons/westar_35_pistol.mdl", bone = "v_scoutblaster_reference001", rel = "", pos = Vector(-0.25, -0.5, 0), angle = Angle(0, 180, 0), size = Vector(1.1, 1.1, 1.1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["visor"] = { type = "Model", model = "models/squad/sf_plates/sf_plate1x1.mdl", bone = "", rel = "w35", pos = Vector(0.605, 0, 1.87), angle = Angle(90, 0, 90), size = Vector(0.1, 0.1, 0.1), color = Color(255, 255, 255, 255), surpresslightning = true, material = "cs574/ironsights/sw_ironsight_yellow", skin = 0, bodygroup = {} },
}

SWEP.WElements = {
	["w35"] = { type = "Model", model = "models/sw_battlefront/weapons/westar_35_pistol.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(4, 1.5, -1.3), angle = Angle(0, -95, 170), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.Animations = { --Override this after SWEP:Initialize, for example, in attachments
	["reload"] = {
		["type"] = TFA.Enum.ANIMATION_ACT, --Sequence or act
		["value"] = ACT_VM_RELOAD_EMPTY,
		["enabled"] = true
	},
	["reload_empty"] = {
		["type"] = TFA.Enum.ANIMATION_ACT, --Sequence or act
		["value"] = ACT_VM_RELOAD_EMPTY
	},
	["reload_silenced"] = {
		["type"] = TFA.Enum.ANIMATION_ACT, --Sequence or act
		["value"] = ACT_VM_RELOAD_EMPTY,
		["enabled"] = true
	},
}

SWEP.ThirdPersonReloadDisable		=false
SWEP.Primary.DamageType 			= DMG_BULLET
SWEP.DamageType 					= DMG_BULLET
SWEP.RTScopeAttachment				= -1
SWEP.Scoped_3D 						= false
SWEP.ScopeReticule 					= "#sw/visor/sw_ret_redux_yellow" 
SWEP.Secondary.ScopeZoom 			= 6
SWEP.ScopeReticule_Scale 			= {1,1}
if surface then
	SWEP.Secondary.ScopeTable = nil
end
DEFINE_BASECLASS( SWEP.Base )

function SWEP:Think(...)
	BaseClass.Think(self, ...)
	if CLIENT then
		if self:IronSights() then
			if( self.Weapon:Clip1() <= self.Primary.ClipSize/4 ) then 
				self.VElements["visor"].color = Color(255, 80, 0, 255)
			else
				self.VElements["visor"].color = Color(255, 255, 255, 255)
			end
		else
			self.VElements["visor"].color = Color(0, 0, 0, 0)
		end
	end
end

