SWEP.Gun							= ("gun_base")
if (GetConVar(SWEP.Gun.."_allowed")) != nil then
	if not (GetConVar(SWEP.Gun.."_allowed"):GetBool()) then SWEP.Base = "tfa_blacklisted" SWEP.PrintName = SWEP.Gun return end
end
SWEP.Base							= "tfa_sw_special_base"
SWEP.Category = "[VirtusRP]"
SWEP.Manufacturer 					= ""
SWEP.Author							= "ChanceSphere574"
SWEP.Contact						= ""
SWEP.Spawnable						= true
SWEP.AdminSpawnable					= true
SWEP.DrawCrosshair					= true
SWEP.DrawCrosshairIS 				= false
SWEP.PrintName						= "HH-15"
SWEP.Type							= "Rebel Rocket Launcher (waiting a new model for update it)"
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
SWEP.DoMuzzleFlash 					= true
SWEP.SelectiveFire					= true
SWEP.DisableBurstFire				= false
SWEP.OnlyBurstFire					= false
SWEP.DefaultFireMode 				= "single"
SWEP.FireModeName 					= nil
SWEP.DisableChambering 				= true
SWEP.MuzzleFlashEffect 				= ""

SWEP.Primary.ClipSize				= 1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.RPM					= 100
SWEP.Primary.RPM_Burst				= nil
SWEP.Primary.Ammo					= "RPG_Round"
SWEP.Primary.AmmoConsumption 		= 1
SWEP.Primary.Range 					= 35500
SWEP.Primary.RangeFalloff 			= -1
SWEP.Primary.NumShots				= 1
SWEP.Primary.Automatic				= false
SWEP.Primary.RPM_Semi				= nil
SWEP.Primary.BurstDelay				= 0.2
SWEP.Primary.Sound 					= Sound ("w/launcher.wav");
SWEP.Primary.ReloadSound 			= Sound ("w/reload.wav");
SWEP.Primary.PenetrationMultiplier 	= 0
local rocket_damage = (GetConVar("rw_sw_rocket_damage") and GetConVar("rw_sw_rocket_damage"):GetInt() or 200)
SWEP.Primary.Damage					= rocket_damage
SWEP.Primary.HullSize 				= 0
SWEP.DamageType 					= nil
SWEP.Primary.Force 					= 0
SWEP.Primary.Knockback 				= 0

SWEP.Primary.RangeFalloffLUT = {
    bezier = false,
    range_func = "quintic",
    units = "meters",
    lut = {
        {range = (35500)/52.495, damage = 1},
        {range = (35500+50)/52.495, damage = 0},
    }
}

SWEP.DoMuzzleFlash 					= false

SWEP.FireModes = {
	"Single"
}

SWEP.ProceduralHolsterPos = Vector(0,0,1)
SWEP.ProceduralHolsterAng = Vector(-40,0,0)
SWEP.DoProceduralReload = true
SWEP.ProceduralReloadTime = 3.5

SWEP.IronRecoilMultiplier			= 0.5
SWEP.CrouchRecoilMultiplier			= 0.25
SWEP.JumpRecoilMultiplier			= 1.3
SWEP.WallRecoilMultiplier			= 1.1
SWEP.ChangeStateRecoilMultiplier	= 1.3
SWEP.CrouchAccuracyMultiplier		= 0.81
SWEP.ChangeStateAccuracyMultiplier	= 1.18
SWEP.JumpAccuracyMultiplier			= 2
SWEP.WalkAccuracyMultiplier			= 1.18
SWEP.NearWallTime 					= 0.25
SWEP.ToCrouchTime 					= 0.25
SWEP.WeaponLength 					= 35
SWEP.SprintFOVOffset 				= 12
SWEP.ProjectileVelocity 			= 8

SWEP.ProjectileEntity 				= "ent_rw_rocket_mods"

SWEP.ViewModel						= "models/bf2017/c_dlt19.mdl"
SWEP.WorldModel						= "models/bf2017/w_dlt19.mdl"
SWEP.ViewModelFOV					= 75
SWEP.ViewModelFlip					= false
SWEP.MaterialTable 					= nil
SWEP.UseHands 						= false
SWEP.HoldType 						= "rpg"
SWEP.ReloadHoldTypeOverride 		= "rpg"

SWEP.ShowWorldModel = false

SWEP.BlowbackEnabled 				= true
SWEP.BlowbackVector 				= Vector(0,-1)
SWEP.BlowbackCurrentRoot			= 0
SWEP.BlowbackCurrent 				= 0
SWEP.BlowbackBoneMods 				= nil
SWEP.Blowback_Only_Iron 			= true
SWEP.Blowback_PistolMode 			= false
SWEP.Blowback_Shell_Enabled 		= false
SWEP.Blowback_Shell_Effect 			= "None"
tfa_use_legacy_shells				= true

SWEP.Tracer = 0
SWEP.TracerName 					= nil
SWEP.TracerCount 					= 1
SWEP.TracerLua = true
SWEP.TracerDelay					= 0.01
SWEP.ImpactEffect 					= nil
SWEP.ImpactDecal 					= "FadingScorch"

SWEP.VMPos = Vector(5.96, -3, 0)
SWEP.VMAng = Vector(0,0,0)

SWEP.IronSightTime 					= 0.7
SWEP.Primary.KickUp					= 0.35
SWEP.Primary.KickDown				= 0.30
SWEP.Primary.KickHorizontal			= 0.30
SWEP.Primary.StaticRecoilFactor 	= 1.2
SWEP.Primary.Spread					= 0.01
SWEP.Primary.IronAccuracy 			= 0.005
SWEP.Primary.SpreadMultiplierMax 	= 2.5
SWEP.Primary.SpreadIncrement 		= 0.22
SWEP.Primary.SpreadRecovery 		= 0.8
SWEP.DisableChambering 				= true
SWEP.MoveSpeed 						= 0.7
SWEP.IronSightsMoveSpeed 			= 0.75

SWEP.IronSightsPos = Vector(-2.55, -3, 02.5)
SWEP.IronSightsAng = Vector(0, 0, 0)

SWEP.RunSightsPos = Vector(0.0, 0, 03)
SWEP.RunSightsAng = Vector(-40, 0, 0)

SWEP.InspectPos = Vector(8, 4.8, -3)
SWEP.InspectAng = Vector(11.199, 38, 0)

SWEP.ProceduralHolsterPos = Vector(0,0,3)
SWEP.ProceduralHolsterAng = Vector(-40,0,0)
SWEP.DoProceduralReload = true
SWEP.ProceduralReloadTime = 3.5

SWEP.ViewModelBoneMods = {
	["v_dlt19_reference001"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 1), angle = Angle(0, 0, 0) }
}

SWEP.VElements = {
	["rocketlauncher"] = { type = "Model", model = "models/weapons/star_wars_battlefront/reb_rocket_launcher.mdl", bone = "v_dlt19_reference001", rel = "", pos = Vector(0, 10, 0), angle = Angle(0, 180, 0), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["scope"] = { type = "Model", model = "models/rtcircle.mdl", bone = "", rel = "rocketlauncher", pos = Vector(-7.01, 10.68, 2.6), angle = Angle(180, 90, 180), size = Vector(0.25, 0.25, 0.25), color = Color(255, 255, 255, 255), surpresslightning = true, material = "!tfa_rtmaterial", skin = 0, bodygroup = {} },
}

SWEP.WElements = {
	["rocketlauncher"] = { type = "Model", model = "models/weapons/star_wars_battlefront/reb_rocket_launcher.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(8, 1, -4.5), angle = Angle(0, 90, 192), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.LuaShellEject = false
SWEP.LuaShellEffect = ""

SWEP.ThirdPersonReloadDisable		=false
SWEP.Primary.DamageType 			= DMG_BULLET
SWEP.DamageType 					= DMG_BULLET
SWEP.RTScopeAttachment				= -1
SWEP.Scoped_3D 						= false
SWEP.ScopeReticule 					= "cs574/scopes/cgi_hd/sw_redux_cgi_ret_yellow" 
SWEP.Secondary.ScopeZoom 			= 2
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


function SWEP:Think()
	if CLIENT then
		if self:GetIronSights( issighting ) then
			self.VElements["scope"].color = Color(255, 255, 255, 255)
		else
			self.VElements["scope"].color = Color(255, 255, 255, 0)
		end
	end
end

function SWEP:ShootBullet(...)
	if IsFirstTimePredicted() then
		if SERVER then
			timer.Simple(0, function()
				local ent = ents.Create("ent_rw_rocket_mods")
				ent.Owner = self.Owner
				local ang = self.Owner:EyeAngles()
				ent:SetPos(self.Owner:GetShootPos() + ang:Forward()*25 + ang:Right()*10 + ang:Up()*-2)
				ent:SetAngles(ang)
				ent:Spawn()
			end)
		end
		return
	end
	return BaseClass.ShootBullet(self,...)
end

