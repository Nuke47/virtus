SWEP.Gun							= ("dual_dc17s")
if (GetConVar(SWEP.Gun.."_allowed")) != nil then
	if not (GetConVar(SWEP.Gun.."_allowed"):GetBool()) then SWEP.Base = "tfa_blacklisted" SWEP.PrintName = SWEP.Gun return end
end
SWEP.Base = "tfa_sw_gun_base"
SWEP.Category = "[VirtusRP]"
SWEP.Manufacturer 					= "Blastech Industries"
SWEP.Author							= "Ivo"
SWEP.Contact						= ""
SWEP.Spawnable						= true
SWEP.AdminSpawnable					= true
SWEP.DrawCrosshair					= true
SWEP.DrawCrosshairIS 				= false
SWEP.PrintName						= "Dual DC-17s"
SWEP.Type							= "Republic Advanced Dual Pistol Blaster"
SWEP.DrawAmmo						= true
SWEP.data 							= {}
SWEP.data.ironsights				= 0
SWEP.Secondary.IronFOV				= 75
SWEP.Slot							= 1
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
SWEP.DefaultFireMode 				= ""
SWEP.FireModeName 					= nil
SWEP.DisableChambering 				= true

SWEP.Primary.ClipSize				= 30*2
SWEP.Primary.DefaultClip = 0*8
SWEP.Primary.RPM					= 385*2*0.8
SWEP.Primary.RPM_Burst				= 385*2*0.8
SWEP.Primary.Ammo					= "ar2"
SWEP.Primary.AmmoConsumption 		= 1
SWEP.Primary.Range 					= 32000
SWEP.Primary.RangeFalloff 			= -1
SWEP.Primary.NumShots				= 1
SWEP.Primary.Automatic				= true
SWEP.Primary.RPM_Semi				= nil
SWEP.Primary.BurstDelay				= 0.2
SWEP.Primary.Sound 					= Sound ("w/dc17s_custom.wav");
SWEP.Primary.ReloadSound 			= Sound ("w/rifles.wav");
SWEP.Primary.PenetrationMultiplier 	= 0
SWEP.Primary.Damage					= 35
SWEP.Primary.HullSize 				= 0
SWEP.DamageType 					= nil

SWEP.Akimbo 						= true

SWEP.DoMuzzleFlash 					= false
SWEP.CustomMuzzleFlash 				= false
SWEP.MuzzleFlashEffect 				= "none"

SWEP.FireModes = {
	"Automatic",
	"Single",
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

SWEP.ViewModel						= "models/strasser/weapons/c_ddeagle.mdl"
SWEP.WorldModel						= "models/bf2017/w_scoutblaster.mdl"
SWEP.ViewModelFOV					= 90
SWEP.ViewModelFlip					= false
SWEP.MaterialTable 					= nil
SWEP.UseHands 						= true
SWEP.HoldType 						= "duel"

SWEP.ShowWorldModel = false

SWEP.BlowbackEnabled 				= true
SWEP.BlowbackVector 				= Vector(0,-3,0)
SWEP.BlowbackCurrentRoot			= 0
SWEP.BlowbackCurrent 				= 0
SWEP.BlowbackBoneMods 				= nil
SWEP.Blowback_Only_Iron 			= false
SWEP.Blowback_PistolMode 			= false
SWEP.Blowback_Shell_Enabled 		= false
SWEP.Blowback_Shell_Effect 			= ""

SWEP.Tracer = 0
SWEP.TracerName 					= "rw_sw_dual_laser_blue"
SWEP.TracerCount 					= 1
SWEP.TracerLua = true
SWEP.TracerDelay					= 0.01
SWEP.ImpactEffect 					= "rw_sw_impact_blue"
SWEP.ImpactDecal 					= "FadingScorch"

SWEP.VMPos = Vector(0, -6, -3)
SWEP.VMAng = Vector(0,0,0)

SWEP.IronSightTime 					= 0.6
SWEP.Primary.KickUp					= 0.10
SWEP.Primary.KickDown				= 0.08
SWEP.Primary.KickHorizontal			= 0.025
SWEP.Primary.StaticRecoilFactor 	= 0.5
SWEP.Primary.Spread					= 0.005
SWEP.Primary.IronAccuracy 			= 0.005
SWEP.Primary.SpreadMultiplierMax 	= 1.6
SWEP.Primary.SpreadIncrement 		= 0.3
SWEP.Primary.SpreadRecovery 		= 0.98
SWEP.DisableChambering 				= true
SWEP.MoveSpeed 						= 1
SWEP.IronSightsMoveSpeed 			= 0.8

SWEP.IronSightsPos = Vector(0, -5, 0)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.RunSightsPos = Vector(0, -7.5, -10)
SWEP.RunSightsAng = Vector(37.5, 0, 0)
SWEP.InspectPos = Vector(0, -5, -5)
SWEP.InspectAng = Vector(37.5,0,0)

SWEP.LuaShellEject = false

SWEP.VElements = {

	["dc17s"] = { type = "Model", model = "models/jajoff/sps/cgiweapons/tc13j/dc17s.mdl", bone = "LeftHand_1stP", rel = "", pos = Vector(-8, 3.5, 2), angle = Angle(-10, -2, 90), size = Vector(0.8, 0.8, 0.8), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {[1] = 1} },

	["ind1"] = { type = "Model", model = "models/hunter/plates/plate.mdl", bone = "", rel = "dc17s", pos = Vector(16.88-1-1-1-1, 1.35, 2.2), angle = Angle(0, -0, 90), size = Vector(0.32, 0.2, 0.2), color = Color(255, 0, 80, 255), surpresslightning = true, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	["ind2"] = { type = "Model", model = "models/hunter/plates/plate.mdl", bone = "", rel = "dc17s", pos = Vector(16.88-1-1-1, 1.35, 2.2), angle = Angle(0, -0, 90), size = Vector(0.32, 0.2, 0.2), color = Color(255, 0, 80, 255), surpresslightning = true, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	["ind3"] = { type = "Model", model = "models/hunter/plates/plate.mdl", bone = "", rel = "dc17s", pos = Vector(16.88-1-1, 1.35, 2.2), angle = Angle(0, -0, 90), size = Vector(0.32, 0.2, 0.2), color = Color(255, 0, 80, 255), surpresslightning = true, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	["ind4"] = { type = "Model", model = "models/hunter/plates/plate.mdl", bone = "", rel = "dc17s", pos = Vector(16.88-1, 1.35, 2.2), angle = Angle(0, -0, 90), size = Vector(0.32, 0.2, 0.2), color = Color(255, 0, 80, 255), surpresslightning = true, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	["ind5"] = { type = "Model", model = "models/hunter/plates/plate.mdl", bone = "", rel = "dc17s", pos = Vector(16.88, 1.35, 2.2), angle = Angle(0, -0, 90), size = Vector(0.32, 0.2, 0.2), color = Color(255, 0, 80, 255), surpresslightning = true, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	
	["dc17s+"] = { type = "Model", model = "models/jajoff/sps/cgiweapons/tc13j/dc17s.mdl", bone = "RightHand_1stP", rel = "", pos = Vector(7, -2.5, 0), angle = Angle(15, 178, 90), size = Vector(0.8, 0.8, 0.8), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {[1] = 1} },

	["ind1+"] = { type = "Model", model = "models/hunter/plates/plate.mdl", bone = "", rel = "dc17s+", pos = Vector(16.85-0.95-0.95-0.95-0.95, 0.3, 2.2), angle = Angle(0, -0, 90), size = Vector(0.3, 0.2, 0.2), color = Color(255, 0, 80, 255), surpresslightning = true, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	["ind2+"] = { type = "Model", model = "models/hunter/plates/plate.mdl", bone = "", rel = "dc17s+", pos = Vector(16.85-0.95-0.95-0.95, 0.3, 2.2), angle = Angle(0, -0, 90), size = Vector(0.3, 0.2, 0.2), color = Color(255, 0, 80, 255), surpresslightning = true, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	["ind3+"] = { type = "Model", model = "models/hunter/plates/plate.mdl", bone = "", rel = "dc17s+", pos = Vector(16.85-0.95-0.95, 0.3, 2.2), angle = Angle(0, -0, 90), size = Vector(0.3, 0.2, 0.2), color = Color(255, 0, 80, 255), surpresslightning = true, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	["ind4+"] = { type = "Model", model = "models/hunter/plates/plate.mdl", bone = "", rel = "dc17s+", pos = Vector(16.85-0.95, 0.3, 2.2), angle = Angle(0, -0, 90), size = Vector(0.3, 0.2, 0.2), color = Color(255, 0, 80, 255), surpresslightning = true, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	["ind5+"] = { type = "Model", model = "models/hunter/plates/plate.mdl", bone = "", rel = "dc17s+", pos = Vector(16.85, 0.3, 2.2), angle = Angle(0, -00, 90), size = Vector(0.3, 0.2, 0.2), color = Color(255, 0, 80, 255), surpresslightning = true, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },

}


SWEP.WElements = {

	["dc17s"] = { type = "Model", model = "models/jajoff/sps/cgiweapons/tc13j/dc17s.mdl", bone = "ValveBiped.Bip01_L_Hand", rel = "", pos = Vector(-8, 0.2, 2), angle = Angle(0, 0, 0), size = Vector(0.9, 0.9, 0.9), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },

	["dc17s+"] = { type = "Model", model = "models/jajoff/sps/cgiweapons/tc13j/dc17s.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(-8, 01.8, -1.7), angle = Angle(0, -5, 175), size = Vector(0.9, 0.9, 0.9), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },

}

SWEP.ProceduralHolsterPos = Vector(0,-8,-8)
SWEP.ProceduralHolsterAng = Vector(37.5,0,0)
SWEP.DoProceduralReload = true
SWEP.ProceduralReloadTime = 2.3

SWEP.ThirdPersonReloadDisable		= false
SWEP.Primary.DamageType 			= DMG_BULLET
SWEP.DamageType 					= DMG_BULLET
SWEP.RTScopeAttachment				= -1
SWEP.Scoped_3D 						= false
SWEP.ScopeReticule 					= "scope/gdcw_elcanreticle" 
SWEP.Secondary.ScopeZoom 			= 1
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

local ColorActive = Color(255, 0, 0, 255)
local ColorDisabled = Color(30, 30, 30, 255)

function SWEP:Think(...)
    BaseClass.Think(self, ...)

    -- Obtenemos el porcentaje del cargador (de 0 a 1)
    local clip = self.Weapon:Clip1()
    local maxClip = self.Primary.ClipSize
    local ratio = maxClip > 0 and (clip / maxClip) or 0
    
    -- Calculamos cuántos indicadores deben estar activos (del 0 al 5)
    local activeCount = math.ceil(ratio * 5)

    -- Iteramos del 1 al 5
    for i = 1, 5 do
        local name = "ind" .. i
        local namePlus = "ind" .. i .. "+"
        
        -- Si el índice es menor o igual al calculado, se activa, si no, se desactiva
        local isActive = (i <= activeCount)
        
        local targetColor = isActive and ColorActive or ColorDisabled
        local targetLight = isActive

        -- Aplicamos a los elementos si existen
        if self.VElements[name] then
            self.VElements[name].color = targetColor
            self.VElements[name].surpresslightning = targetLight
        end
        
        if self.VElements[namePlus] then
            self.VElements[namePlus].color = targetColor
            self.VElements[namePlus].surpresslightning = targetLight
        end
    end
end

