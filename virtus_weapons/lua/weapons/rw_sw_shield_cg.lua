SWEP.Gun							= ("tfa_shield_cs574_base")
if (GetConVar(SWEP.Gun.."_allowed")) != nil then
	if not (GetConVar(SWEP.Gun.."_allowed"):GetBool()) then SWEP.Base = "tfa_blacklisted" SWEP.PrintName = SWEP.Gun return end
end
SWEP.Base = "tfa_gun_base"
SWEP.Category = "[VirtusRP]"
SWEP.Manufacturer 					= ""
SWEP.Author							= "Ivo"
SWEP.Contact						= ""
SWEP.Spawnable						= true
SWEP.AdminSpawnable					= true
SWEP.DrawCrosshair = false
SWEP.DrawCrosshairIS 				= false
SWEP.PrintName						= "Escudo Riot"
SWEP.Type							= "Riot Shield"
SWEP.DrawAmmo						= false
SWEP.data 							= {}
SWEP.data.ironsights				= 0
SWEP.Secondary.IronFOV				= 75
SWEP.Slot							= 2
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

SWEP.Primary.ClipSize				= 0
SWEP.Primary.DefaultClip = 0
SWEP.Primary.RPM					= 0
SWEP.Primary.RPM_Burst				= 0
SWEP.Primary.Ammo					= "none"
SWEP.Primary.AmmoConsumption 		= 1
SWEP.Primary.Range 					= 32000
SWEP.Primary.RangeFalloff 			= -1
SWEP.Primary.NumShots				= 1
SWEP.Primary.Automatic				= false
SWEP.Primary.RPM_Semi				= nil
SWEP.Primary.BurstDelay				= 0.2
SWEP.Primary.Sound 					= Sound ("w/dc17.wav");
SWEP.Primary.ReloadSound 			= Sound ("w/pistols.wav");
SWEP.Primary.PenetrationMultiplier 	= 0
SWEP.Primary.Damage					= 0
SWEP.Primary.HullSize 				= 0
SWEP.DamageType 					= nil

SWEP.DoMuzzleFlash 					= false

SWEP.FireModes = {
	"Single"
}

SWEP.IronRecoilMultiplier			= 0.44
SWEP.CrouchRecoilMultiplier			= 0.33
SWEP.JumpRecoilMultiplier			= 1.3
SWEP.WallRecoilMultiplier			= 1.1
SWEP.ChangeStateRecoilMultiplier	= 1.18
SWEP.CrouchAccuracyMultiplier		= 0.7
SWEP.ChangeStateAccuracyMultiplier	= 1
SWEP.JumpAccuracyMultiplier			= 5
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
SWEP.HoldType 						= "physgun"

SWEP.ShowWorldModel = false

SWEP.BlowbackEnabled 				= true
SWEP.BlowbackVector 				= Vector(0,-2.5,-0.05)
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

SWEP.VMPos = Vector(0,-20,0)
SWEP.VMAng = Vector(0,0,0)

SWEP.IronSightTime 					= 0.6
SWEP.Primary.KickUp					= 0.35
SWEP.Primary.KickDown				= 0.15
SWEP.Primary.KickHorizontal			= 0.055
SWEP.Primary.StaticRecoilFactor 	= 0.5
SWEP.Primary.Spread					= 0.01
SWEP.Primary.IronAccuracy 			= 0.01
SWEP.Primary.SpreadMultiplierMax 	= 2
SWEP.Primary.SpreadIncrement 		= 0.3
SWEP.Primary.SpreadRecovery 		= 0.98
SWEP.DisableChambering 				= true
SWEP.MoveSpeed 						= 1
SWEP.IronSightsMoveSpeed 			= 0.8

SWEP.IronSightsPos = Vector(0, 0, 0)
SWEP.IronSightsAng = Vector(0, 0, 0)

SWEP.RunSightsPos = Vector(2, -9.5, -15)
SWEP.RunSightsAng = Vector(39, -0.5, -2)

SWEP.InspectPos = Vector(8, -4.8, -3)
SWEP.InspectAng = Vector(11.199, 38, 0)


SWEP.ViewModelBoneMods = {
	["v_scoutblaster_reference001"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, -0.3, 0), angle = Angle(0, 0, 0) },
}

SWEP.VElements = {}
SWEP.WElements = {}

DEFINE_BASECLASS( SWEP.Base )


function SWEP:Deploy()
	self:SetupShield();
	return true
end


SWEP.canBeDestroyedByDamage = false;
SWEP.onlyExplosionDamage = false;
SWEP.defaultHealth = 5000;

function SWEP:SetupShield()
	if CLIENT then return end;
	self.shieldProp = ents.Create("prop_physics");
	self.shieldProp:SetModel("models/cs574/weapons/shields/shield2.mdl");
	self.shieldProp:Spawn(); 
	self.shieldProp:SetModelScale(0,0);
	local phys = self.shieldProp:GetPhysicsObject();

	if not IsValid(phys) then
		self.Owner:ChatPrint("not valid physics object!");
		return;
	end

	phys:SetMass(5000);
	
	local nothand = false;

	local attach = self.Owner:LookupAttachment("anim_attachment_RH");
	
	up = 10;
	forward = 11;
	aforward = 20;
	aup = 90;
	right = 0;
	
	if nothand then
	    up = 0;
		forward = 0;
		aforward = 0;
		aup = 0;
		right = 0;
	end

	local attachTable = self.Owner:GetAttachment(attach);
	self.shieldProp:SetPos(attachTable.Pos + attachTable.Ang:Up()*up + attachTable.Ang:Forward()*forward + attachTable.Ang:Right()*right);
	attachTable.Ang:RotateAroundAxis(attachTable.Ang:Forward(),aforward);
	attachTable.Ang:RotateAroundAxis(attachTable.Ang:Up(),aup);
	self.shieldProp:SetAngles( attachTable.Ang );
	self.shieldProp:SetCollisionGroup( COLLISION_GROUP_WORLD );
	self.shieldProp:SetParent(self.Owner,attach);

	timer.Simple(0.2,function()
		if IsValid(self) and IsValid(self.shieldProp) then
			self.shieldProp:SetModelScale(1,0);
		end
	end)

end


function SWEP:Holster()
	if CLIENT then return end;
	if not IsValid(self.shieldProp) then return true end;
	self.shieldProp:Remove();
	return true;
end

function SWEP:OnDrop()
	if CLIENT then return end;
	if not IsValid(self.shieldProp) then return true end;
	self.shieldProp:Remove();
	return true;
end

function SWEP:OnRemove()
	if CLIENT then return end;
	if not IsValid(self.shieldProp) then return true end;
	self.shieldProp:Remove();
	return true;
end
function SWEP:PrimaryAttack()
    return false
end

function SWEP:SecondaryAttack()
    return false
end

