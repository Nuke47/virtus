if ( SERVER ) then

	AddCSLuaFile( "shared.lua" )

end

if ( CLIENT ) then

	SWEP.PrintName			= "Imperial Reciprocating Quad Blaster"	

	SWEP.Author				= "Sim"

    SWEP.Instructions       = "Primary Attack: Fire, Secondary Attack: ADS, Safety: Reload over time"

	SWEP.ViewModelFOV      	= 70

	SWEP.Slot				= 3

	SWEP.SlotPos			= 2

	--SWEP.WepSelectIcon = surface.GetTextureID("HUD/killicons/DC15A")

	--killicon.Add( "weapon_752_dc15a", "HUD/killicons/DC15A", Color( 255, 80, 0, 255 ) )

end

SWEP.HoldType				= "duel"

SWEP.Base					= "tfa_swsft_base_servius"

SWEP.Category = "Virtus"

SWEP.Spawnable				= true

SWEP.AdminSpawnable			= false

SWEP.ViewModelFOV = 56

SWEP.ViewModelFlip = false

SWEP.ViewModel = "models/twcustom/weapons/v_reciprocating_quad_blaster.mdl"

SWEP.WorldModel = "models/twcustom/weapons/w_reciprocating_quad_blaster.mdl"

SWEP.ShowViewModel = true

SWEP.ShowWorldModel = true

SWEP.UseHands = false

--[[SWEP.ViewModelBoneMods = {

	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(0.736, 5.183, 1.149), angle = Angle(-1.825, 2.803, -0.527) },

	["v_weapon.awm_parent"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }

}]]

SWEP.Primary.Sound = Sound ("weapons/dc15a/DC15A_fire.ogg");

SWEP.Primary.ReloadSound = Sound ("weapons/shared/standard_reload.ogg");

SWEP.Weight					= 5

SWEP.AutoSwitchTo			= false

SWEP.AutoSwitchFrom			= false

SWEP.Primary.Recoil			= 0.5

SWEP.Primary.Damage			= 50

SWEP.Primary.NumShots		= 1

-- Selective Fire Stuff

SWEP.SelectiveFire		= true --Allow selecting your firemode?

SWEP.DisableBurstFire	= false --Only auto/single?

SWEP.OnlyBurstFire		= false --No auto, only burst/single?

SWEP.DefaultFireMode 	= "Safe" --Default to auto or whatev

SWEP.FireModes = {

"Auto"

}

SWEP.FireModeName = nil --Change to a text value to override it

SWEP.Primary.Spread			= 0.0125

SWEP.Primary.IronAccuracy = .005	-- Ironsight accuracy, should be the same for shotguns

SWEP.Primary.SpreadMultiplierMax = 2 --How far the spread can expand when you shoot.

--Range Related

SWEP.Primary.Range = -1 -- The distance the bullet can travel in source units.  Set to -1 to autodetect based on damage/rpm.

SWEP.Primary.RangeFalloff = -1 -- The percentage of the range the bullet damage starts to fall off at.  Set to 0.8, for example, to start falling off after 80% of the range.

--Penetration Related

SWEP.MaxPenetrationCounter=1 --The maximum number of ricochets.  To prevent stack overflows.

SWEP.Primary.ClipSize		= 400

SWEP.Primary.RPM = 600

SWEP.Primary.DefaultClip	= 400*3

SWEP.Primary.Automatic		= true

SWEP.Primary.Ammo			= "ar2"

SWEP.TracerName = "effect_sw_laser_red"

SWEP.Secondary.Automatic	= false

SWEP.Secondary.Ammo			= "none"

SWEP.Secondary.IronFOV = 70

SWEP.BlowbackEnabled                 = true
SWEP.BlowbackVector                 = Vector(0,-1,0)
SWEP.BlowbackCurrentRoot            = 0
SWEP.BlowbackCurrent                 = 0
SWEP.BlowbackBoneMods                 = nil
SWEP.Blowback_Only_Iron             = false
SWEP.Blowback_PistolMode             = false
SWEP.Blowback_Shell_Enabled         = false
SWEP.Blowback_Shell_Effect             = "None"

SWEP.DoProceduralReload = true

SWEP.ProceduralReloadTime = 2.5

SWEP.VMPos = Vector(0, 11, -5)
SWEP.VMAng = Vector(0, 0, 0)
SWEP.VMPos_Additive = false
SWEP.Sights_Mode = TFA.Enum.LOCOMOTION_HYBRID
SWEP.Idle_Mode = TFA.Enum.IDLE_BOTH
SWEP.Sprint_Mode = TFA.Enum.LOCOMOTION_ANI
SWEP.IronSightsPos = Vector(0.03, 11, -1.85)
SWEP.IronSightsAng = Vector(0.209, -0.138, 0)
SWEP.RunSightsPos = Vector(0, 11, -5)
SWEP.RunSightsAng = Vector(0, 0, 0)
SWEP.InspectPos = Vector(0, 20, -20)
SWEP.InspectAng = Vector(30, 0, 0)

SWEP.MoveSpeed                         = 0.8
SWEP.IronSightsMoveSpeed               = 0.7

SWEP.VElements = {

	["txt_ammo"] = { type = "Quad", bone = "main_gun", pos = Vector(1.8, -1, 8), angle = Angle(0, 0, 90), size = 0.0175, draw_func = nil, active = true},

}

SWEP.TopBarrel = true
SWEP.AnimTime = CurTime()

if CLIENT then
    function SWEP:PlaceHandsOnGun()
        local leftElbow = self:GetOwner():LookupBone("ValveBiped.Bip01_L_Forearm")
        local rightShoulder = self:GetOwner():LookupBone("ValveBiped.Bip01_R_UpperArm")
        local rightElbow = self:GetOwner():LookupBone("ValveBiped.Bip01_R_Forearm")

        if not leftElbow or not rightShoulder or not rightElbow then return end

        self:GetOwner():ManipulateBoneAngles(leftElbow, Angle(20, -20, 0))
        self:GetOwner():ManipulateBoneAngles(rightShoulder, Angle(0, 15, 0))
        self:GetOwner():ManipulateBoneAngles(rightElbow, Angle(-30, -40, 0))
    end

    function SWEP:ResetBoneAngles()
        local leftElbow = self:GetOwner():LookupBone("ValveBiped.Bip01_L_Forearm")
        local rightShoulder = self:GetOwner():LookupBone("ValveBiped.Bip01_R_UpperArm")
        local rightElbow = self:GetOwner():LookupBone("ValveBiped.Bip01_R_Forearm")

        if not leftElbow or not rightShoulder or not rightElbow then return end

        self:GetOwner():ManipulateBoneAngles(leftElbow, Angle(0, 0, 0))
        self:GetOwner():ManipulateBoneAngles(rightShoulder, Angle(0, 0, 0))
        self:GetOwner():ManipulateBoneAngles(rightElbow, Angle(0, 0, 0))
    end
end

function SWEP:Holster()
    if CLIENT then
        self:ResetBoneAngles()
    end
    return true
end

function SWEP:Deploy()
    if self:IsSafety() then
        self:GetOwner():GetViewModel():SendViewModelMatchingSequence(0)
    end
end

function SWEP:GetShootPos()
    if self.TopBarrel then
        self.TopBarrel = false
        return self:GetBonePosition(self:LookupBone("barrel_top_right")), self:GetBonePosition(self:LookupBone("barrel_top_left"))
    else
        self.TopBarrel = true
        return self:GetBonePosition(self:LookupBone("barrel_bottom_right")), self:GetBonePosition(self:LookupBone("barrel_bottom_left"))
    end
end

function SWEP:GetFireModeName()
	local fm = self:GetFireMode()
	local fmn = string.lower( self:GetStat("FireModes")[fm] )
	if fmn == "safe" or fmn == "holster" then return "Safety" end
	if self:GetStat("FireModeName") then return self:GetStat("FireModeName") end
	if fmn == "auto" or fmn == "automatic" then return "Full-Auto" end

	if fmn == "semi" or fmn == "single" then
		if self:GetStat("Revolver") then
			if (self:GetStat("BoltAction")) then
				return "Single-Action"
			else
				return "Double-Action"
			end
		else
			if (self:GetStat("BoltAction")) then
				return "Bolt-Action"
			else
				if (self.Shotgun and self:GetStat("Primary.RPM") < 250) then
					return "Pump-Action"
				else
					return "Semi-Auto"
				end
			end
		end
	end

	local bpos = string.find(fmn, "burst")
	if bpos then return string.sub(fmn, 1, bpos - 1) .. " Round Burst" end
	return ""
end

function SWEP:Anims() end

function SWEP:ReloadTicker()end

function SWEP:Reload()
    return
end

function SWEP:DrawWorldModel()
    if IsValid(self.Owner) then 
        self:SetPoseParameter("head_pitch", self.Owner:EyeAngles()[1])
        self:InvalidateBoneCache()
    end
    self:DrawModel()
end

function SWEP:Think()
    self.Anims()

    self.ReloadTicker()
    if CLIENT then
        if self:IronSights() then
            if self:Clip1() > self:GetMaxClip1()/2 then
                self.VElements["txt_ammo"].draw_func = function( weapon )
                    draw.SimpleText(""..weapon:Clip1().."/"..self.Primary.ClipSize, "Trebuchet18", 0, 0, Color(0, 90, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                end
            end
            if self:Clip1() <= self:GetMaxClip1()/4 then
                self.VElements["txt_ammo"].draw_func = function( weapon )
                    draw.SimpleText(""..weapon:Clip1().."/"..self.Primary.ClipSize, "Trebuchet18", 0, 0, Color(0, 90, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                end
            end
            if self:Clip1() <= self:GetMaxClip1()/20 then
                self.VElements["txt_ammo"].draw_func = function( weapon )
                    draw.SimpleText("0"..weapon:Clip1().."/"..self.Primary.ClipSize, "Trebuchet18", 0, 0, Color(191, 179, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                end
            end
            if self:Clip1() == 0 then
                self.VElements["txt_ammo"].draw_func = function( weapon )
                    draw.SimpleText("000/"..self.Primary.ClipSize, "Trebuchet18", 0, 0, Color(255, 90, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                end
            end
        else
            self.VElements["txt_ammo"].draw_func = function( weapon )
                draw.SimpleText("", "Trebuchet18", 0, 0, Color(255, 90, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end
    end

    if SERVER then

        if self:GetOwner():KeyDown(IN_ATTACK) and not self:IsSafety() and CurTime() > self.AnimTime and self:Clip1() > 0 then
            self:SetSequence(5)
        end
        if self:GetOwner():KeyReleased(IN_ATTACK) and not self:IsSafety() and CurTime() > self.AnimTime or (self:Clip1() == 0 and not self:IsSafety())then
            self:SetSequence(1)
        end
        if self:GetSequence() == 5 then
            self:SetCycle( math.min(self:GetCycle() + 5*FrameTime(), 1))
        else
            self:SetCycle( math.min(self:GetCycle() + 0.5*FrameTime(), 1))
        end
        if self:GetCycle() >= 1 then
            if tonumber(self:GetSequence()) == 5 then
                self:SetCycle( 0 )
            end
        end
    end
end

function SWEP:CycleSafety()
    if not IsFirstTimePredicted() and !game.SinglePlayer() then return end
	local fm = self:GetFireMode()
	local fmt = self:GetStat("FireModes")
	if fm ~= #fmt then 
		self.LastFireMode = fm
		self:SetFireMode(#fmt)
	else
		self:SetFireMode(self.LastFireMode or 1)
	end
	self:EmitSound("Weapon_AR2.Empty")
	self.BurstCount = 0

    local vm = self:GetOwner():GetViewModel()

    if self:GetFireModeName() == "Safety" then
        if CLIENT then
            self:ResetBoneAngles()
        end
        self:SetHoldType("normal")
        self:SetSequence(3)
        self:SetCycle(0)
        vm:SendViewModelMatchingSequence(3)
        self.Anims = function()
            if CurTime() > self.AnimTime then
            self:SetSequence(0)
            vm:SendViewModelMatchingSequence(0)
            self.Anims = function()end
            end
        end
        self.ReloadWaitTime = CurTime()
        self.ReloadTicker = function()
            if self:IsSafety() then
                if CurTime() > self.ReloadWaitTime then
                    if self:Clip1() < self:GetMaxClip1() and self:GetOwner():GetAmmoCount(self:GetPrimaryAmmoType()) > 0 then
                        local ammo = math.Clamp(50, 0, self:GetOwner():GetAmmoCount(self:GetPrimaryAmmoType()))
                        ammo = math.min(ammo, self:GetMaxClip1()-self:Clip1())
                        self:SetClip1(math.Clamp(self:Clip1() + ammo, 0, self:GetMaxClip1()))
                        self:GetOwner():RemoveAmmo( ammo, self:GetPrimaryAmmoType() )
                        if self:Clip1() == self:GetMaxClip1() then
                            self.ReloadTicker = function()end
                        else
                            self.ReloadWaitTime = CurTime() + 0.5
                        end
                    end
                end
            else
                self.ReloadTicker = function()end
            end
        end
    else
        self.HoldType = "normal"
        self:SetSequence(2)
        self:SetCycle(0)
        vm:SendViewModelMatchingSequence(2)
        self.Anims = function()
            if CurTime() > self.AnimTime then
                self:SetSequence(1)
                self.HoldType = "duel"
                if CLIENT then
                    self:PlaceHandsOnGun()
                end
                vm:SendViewModelMatchingSequence(1)
                self.Anims = function()end
            end
        end
    end
    self.AnimTime = CurTime() + 1.5
    self:SetNextPrimaryFire(self.AnimTime)
    self:SetNextSecondaryFire(self.AnimTime)
end

local cv_forcemult = GetConVar("sv_tfa_force_multiplier")

function SWEP:ShootBullet(damage, recoil, num_bullets, aimcone, disablericochet, bulletoverride)
	if not IsFirstTimePredicted() and not game.SinglePlayer() then return end
	num_bullets = 1
	aimcone = aimcone or 0

    TracerName = self.TracerName

    local rightBarrel, leftBarrel = self:GetShootPos()

    self.MainBullet.Attacker = self:GetOwner()
    self.MainBullet.Inflictor = self
    self.MainBullet.Num = num_bullets
    self.MainBullet.Src = self:GetOwner():EyePos()
    self.MainBullet.Dir = self:GetOwner():GetAimVector()
    self.MainBullet.HullSize = self:GetStat("Primary.HullSize") or 0
    self.MainBullet.Spread.x = aimcone
    self.MainBullet.Spread.y = aimcone
    self.MainBullet.Tracer = self.TracerCount and self.TracerCount or 3
    self.MainBullet.TracerName = "nil"
    self.MainBullet.PenetrationCount = 0
    self.MainBullet.AmmoType = self:GetPrimaryAmmoType()
    self.MainBullet.Force = damage / 6 * math.sqrt(self:GetStat("Primary.KickUp") + self:GetStat("Primary.KickDown") + self:GetStat("Primary.KickHorizontal")) * cv_forcemult:GetFloat() * self:GetAmmoForceMultiplier()
    self.MainBullet.Damage = damage
    self.MainBullet.HasAppliedRange = false

    self:GetOwner():FireBullets(self.MainBullet)

    local data = EffectData()
    data:SetEntity(self)
    data:SetStart(rightBarrel)
    data:SetOrigin(self:GetOwner():GetEyeTrace().HitPos)
    util.Effect(TracerName, data)

    data = nil

    data = EffectData()
    data:SetEntity(self)
    data:SetStart(leftBarrel)
    data:SetOrigin(self:GetOwner():GetEyeTrace().HitPos)
    util.Effect(TracerName, data)

    data = nil
end

function SWEP:CanPrimaryAttack( )
	if self.Owner:IsNPC() then
		if SERVER then
			if CurTime() < self:GetNextPrimaryFire() then
				return false
			end
			return true
		end
	end
	stat = self:GetStatus()
	if not TFA.Enum.ReadyStatus[stat] and stat ~= TFA.Enum.STATUS_SHOOTING then
		if self.Shotgun and TFA.Enum.ReloadStatus[stat] then
			self:SetShotgunCancel( true )
		end
		return false
	end

	if self:IsSafety() then
		self:EmitSound("Weapon_AR2.Empty2")
		self.LastSafetyShoot = self.LastSafetyShoot or 0

		if CurTime() < self.LastSafetyShoot + 0.2 then
			self:CycleSafety()
			self:SetNextPrimaryFire(CurTime() + 1.5)
		end

		self.LastSafetyShoot = CurTime()

		return
	end

	if self:GetStat("Primary.ClipSize") <= 0 and self:Ammo1() < self:GetStat("Primary.AmmoConsumption") then
		return false
	end
	if self:GetSprinting() and not self.AllowSprintAttack then
		return false
	end
	if self:GetPrimaryClipSize(true) > 0 and self:Clip1() < self:GetStat("Primary.AmmoConsumption") then
		if self:GetOwner():KeyPressed(IN_ATTACK) then
			self:ChooseDryFireAnim()
		end
		if not self.HasPlayedEmptyClick then
			self:EmitSound("Weapon_Pistol.Empty2")

			self.HasPlayedEmptyClick = true
		end
		return false
	end
	if self.FiresUnderwater == false and self:GetOwner():WaterLevel() >= 3 then
		self:SetNextPrimaryFire(CurTime() + 0.5)
		self:EmitSound("Weapon_AR2.Empty")
		return false
	end

	self.HasPlayedEmptyClick = false

	if CurTime() < self:GetNextPrimaryFire() then return false end

	return true
end