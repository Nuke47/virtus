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
SWEP.PrintName						= "HH-12"
SWEP.Type							= "Galactic Rocket Launcher"
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
SWEP.Primary.Sound 					= Sound ("w/hh12.wav");
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
SWEP.ViewModelFOV					= 70
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

SWEP.VMPos = Vector(2, 1, -2)
SWEP.VMAng = Vector(0,0,0)

SWEP.IronSightTime 					= 0.5
SWEP.Primary.KickUp					= 0.0
SWEP.Primary.KickDown				= 0.0
SWEP.Primary.KickHorizontal			= 0.0
SWEP.Primary.StaticRecoilFactor 	= 1.2
SWEP.Primary.Spread					= 0.01
SWEP.Primary.IronAccuracy 			= 0.005
SWEP.Primary.SpreadMultiplierMax 	= 2.5
SWEP.Primary.SpreadIncrement 		= 0.22
SWEP.Primary.SpreadRecovery 		= 0.8
SWEP.DisableChambering 				= true
SWEP.MoveSpeed 						= 0.7
SWEP.IronSightsMoveSpeed 			= 0.75

SWEP.IronSightsPos = Vector(-2.11, -03.5, 4.025)
SWEP.IronSightsAng = Vector(0, 0, 0)

SWEP.RunSightsPos = Vector(0.0, 0, 07)
SWEP.RunSightsAng = Vector(-40, 0, 0)

SWEP.InspectPos = Vector(8, 4.8, -3)
SWEP.InspectAng = Vector(11.199, 38, 0)

SWEP.ProceduralHolsterPos = Vector(0,0,7)
SWEP.ProceduralHolsterAng = Vector(-40,0,0)
SWEP.DoProceduralReload = true
SWEP.ProceduralReloadTime = 3.5

SWEP.ViewModelBoneMods = {
	["v_dlt19_reference001"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 1), angle = Angle(0, 0, 0) }
}

SWEP.VElements = {
	["rocketlauncher"] = { type = "Model", model = "models/cs574/weapons/hh12.mdl", bone = "v_dlt19_reference001", rel = "", pos = Vector(0, 0, 3), angle = Angle(0, -90, 0), size = Vector(0.8, 0.8, 0.8), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["scope"] = { type = "Model", model = "models/rtcircle.mdl", bone = "v_dlt19_reference001", rel = "", pos = Vector(3.52, -3.65, 3.1), angle = Angle(0, 90, 0), size = Vector(0.3, 0.3, 0.3), color = Color(255, 255, 255, 255), surpresslightning = false, material = "!tfa_rtmaterial", skin = 0, bodygroup = {} },

	["ind"] = { type = "Model", model = "models/cs574/objects/indicateur.mdl", bone = "", rel = "rocketlauncher", pos = Vector(-3, -3, 0.8), angle = Angle(0, -180, 0), size = Vector(1, 1, 1), color = Color(150, 150, 150, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["laser"] = { type = "Model", model = "models/sw_battlefront/weapons/2019/a280cfe_laser.mdl", bone = "", rel = "ind", pos = Vector(-03.75, -01.6, -01.5), angle = Angle(0, 180, -55), size = Vector(0.8, 0.8, 0.8), color = Color(150, 150, 150, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {}},
	["laser_beam"] = { type = "Model", model = "models/cs574/weapons/atts/laser_beam.mdl", bone = "", rel = "laser", pos = Vector(13, 0.8, 2.55), angle = Angle(0, -90, 90), size = Vector(1.5, 1.5, 1.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {}},

	["target_ind"] = { type = "Model", model = "models/hunter/plates/plate.mdl", bone = "", rel = "ind", pos = Vector(0.485, -0.65, 0.12), angle = Angle(0, 0, 0), size = Vector(0.05, 0.1, 0.2), color = Color(0, 0, 0, 255), surpresslightning = true, material = "models/debug/debugwhite", skin = 0, bodygroup = {}},
	["txt_mod"] = { type = "Quad", bone = "", rel = "ind", pos = Vector(0.565, 0.16, 0.575), angle = Angle(0, 90, 90), size = 0.00085, draw_func = nil},
	["txt_ammo"] = { type = "Quad", bone = "", rel = "ind", pos = Vector(0.565, 0.35, 0.35), angle = Angle(0, 90, 90), size = 0.001, draw_func = nil},
	["txt_range"] = { type = "Quad", bone = "", rel = "ind", pos = Vector(0.565, -0.4, 0.35), angle = Angle(0, 90, 90), size = 0.0009, draw_func = nil},
}

SWEP.WElements = {
	["rocketlauncher"] = { type = "Model", model = "models/cs574/weapons/hh12.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3, 01.7, -7.5), angle = Angle(-12, 0, 180), size = Vector(0.8, 0.8, 0.8), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },

	["ind"] = { type = "Model", model = "models/cs574/objects/indicateur.mdl", bone = "", rel = "rocketlauncher", pos = Vector(-3, -3, 0.8), angle = Angle(0, -180, 0), size = Vector(1, 1, 1), color = Color(150, 150, 150, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["laser"] = { type = "Model", model = "models/sw_battlefront/weapons/2019/a280cfe_laser.mdl", bone = "", rel = "ind", pos = Vector(-03.75, -01.6, -01.5), angle = Angle(0, 180, -55), size = Vector(0.8, 0.8, 0.8), color = Color(150, 150, 150, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {}},
	["laser_beam"] = { type = "Model", model = "models/cs574/weapons/atts/laser_beam.mdl", bone = "", rel = "laser", pos = Vector(13, 0.8, 2.55), angle = Angle(0, -90, 90), size = Vector(1.5, 1.5, 1.5), color = Color(0, 0, 0, 0), surpresslightning = false, material = "", skin = 0, bodygroup = {}, active = true},

	["laser_beam_pointing"] = { type = "Model", model = "models/cs574/weapons/atts/laser_beam.mdl", bone = "", rel = "laser", pos = Vector(13, 0.8, 2.55), angle = Angle(0, -90, 90), size = Vector(1.5, 1.5, 1.5), color = Color(255, 20, 30, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {}, active = false},
	["laser_beam_tracking"] = { type = "Model", model = "models/cs574/weapons/atts/laser_beam.mdl", bone = "", rel = "laser", pos = Vector(13, 0.8, 2.55), angle = Angle(0, -90, 90), size = Vector(1.5, 1.5, 1.5), color = Color(100, 255, 30, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {}, active = false},
	["laser_beam_control"] = { type = "Model", model = "models/cs574/weapons/atts/laser_beam.mdl", bone = "", rel = "laser", pos = Vector(13, 0.8, 2.55), angle = Angle(0, -90, 90), size = Vector(1.5, 1.5, 1.5), color = Color(0, 100, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {}, active = false},
}

SWEP.LuaShellEject = false
SWEP.LuaShellEffect = ""

SWEP.ThirdPersonReloadDisable		=false
SWEP.Primary.DamageType 			= DMG_BULLET
SWEP.DamageType 					= DMG_BULLET
SWEP.RTScopeAttachment				= -1
SWEP.Scoped_3D 						= false
SWEP.ScopeReticule 					= "#sw/visor/sw_ret_redux_purple" 
SWEP.Secondary.ScopeZoom 			= 2
SWEP.ScopeReticule_Scale 			= {1.05,1.05}
if surface then
	SWEP.Secondary.ScopeTable = nil
end

SWEP.Attachments = {
	[1] = {
		header = "Modes",
		atts = {"rocket_mod_pointing","rocket_mod_tracking","rocket_mod_control"}
	},
}

DEFINE_BASECLASS( SWEP.Base )

SWEP.trackedent = nil
SWEP.tracktime = 0
SWEP.cld = 0
SWEP.cld2 = 0

if CLIENT then
	surface.CreateFont( "Test", {
		font = "VirtusBe",extended = false,size = 200,weight = 0,blursize = 0,scanlines = 0,
		antialias = false,underline = false,italic = false,strikeout = false,symbol = false,
		rotary = false,shadow = false,additive = false,outline = false,
	})
end

function SWEP:Think(...)
    BaseClass.Think(self, ...)
	if CLIENT then
		local o = self.Owner
		local oGSP = o:GetShootPos()
		local oGET = o:GetEyeTrace()
		local wu = oGSP:Distance( oGET.HitPos )
		wu = math.Round( wu, 0 )	
		local m = wu / 52.49
		m = math.Round( m, 0 )
		self.VElements["txt_range"].draw_func = function( weapon )
			draw.SimpleText(""..m.." m", "Test", 0, 0, Color(255, 255, 255, 81), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		end	

		if self:Clip1() == 0 then
			self.VElements["txt_ammo"].draw_func = function( weapon )
				draw.SimpleText("0/1", "Test", 0, 0, Color(185, 0, 0, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			end
		else 
			self.VElements["txt_ammo"].draw_func = function( weapon )
				draw.SimpleText("1/1", "Test", 0, 0, Color(0, 185, 0, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			end
		end

		if self:IsAttached("rocket_mod_tracking") then
			self.VElements["txt_mod"].draw_func = function( weapon )
				draw.SimpleText("tracking", "Test", 0, 0, Color(100, 255, 30, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			end
			self.VElements["laser_beam"].color = Color(100, 255, 30, 255)
		end
		if self:IsAttached("rocket_mod_pointing") then
			self.VElements["txt_mod"].draw_func = function( weapon )
				draw.SimpleText("pointing", "Test", 0, 0, Color(255, 20, 30, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			end
			self.VElements["laser_beam"].color = Color(255, 20, 30, 255)
		end
		if self:IsAttached("rocket_mod_control") then
			self.VElements["txt_mod"].draw_func = function( weapon )
				draw.SimpleText("control", "Test", 0, 0, Color(0, 100, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			end
			self.VElements["laser_beam"].color = Color(0, 100, 255, 255)
		end
		if !self:IsAttached("rocket_mod_control") && !self:IsAttached("rocket_mod_pointing") && !self:IsAttached("rocket_mod_tracking") then
			self.VElements["txt_mod"].draw_func = function( weapon )
				draw.SimpleText("default", "Test", 0, 0, Color(255, 100, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			end
			self.VElements["laser_beam"].color = Color(255, 100, 0, 0)
		end
		
		if self:IsAttached("rocket_mod_tracking") and self.tracktime >= 3 then
			self.VElements["target_ind"].color = Color(0, 255, 0, 255)
		elseif self:IsAttached("rocket_mod_tracking") and self.tracktime >= 2 then
			self.VElements["target_ind"].color = Color(255, 255, 0, 255)
		elseif self:IsAttached("rocket_mod_tracking") and self.tracktime >= 1 then
			self.VElements["target_ind"].color = Color(255, 125, 0, 255)
		elseif self:IsAttached("rocket_mod_tracking") and self.tracktime == 0 then
			self.VElements["target_ind"].color = Color(255, 0, 0, 255)
		else
			self.VElements["target_ind"].color = Color(255, 0, 0, 0)
		end
	end

    if self:Clip1() > 0 then
        if not self:IsAttached("rocket_mod_tracking") then return end
        if CurTime() < self.cld then return end
        if IsValid(self.trackedent) then
            local ent = self.trackedent
            local ownerang = self.Owner:GetAngles()
            local data = ( ent:GetPos() - self:EyePos()):Angle()
            local dify = math.AngleDifference(ownerang.y, data.y)
            if dify < 0 then dify = -dify end
            if dify > 5 then self.trackedent = nil self.tracktime = 0 return end
            local difp = math.AngleDifference(ownerang.p, data.p)
            if difp < 0 then difp = -difp end
            if difp > 5 then self.trackedent = nil self.tracktime = 0 return end
            self.tracktime = self.tracktime + 1
            self.cld = CurTime() + 1    
        else
            self.tracktime = 0
            self.trackedent = NULL
            for k,v in pairs(ents.GetAll()) do
                if not v:IsPlayer() and not v:IsNPC() and not v:IsVehicle() and not v.LFS then continue end
                if v == self.Owner then continue end
                local ownerang = self.Owner:GetAngles()
                local data = ( v:GetPos() - self:EyePos()):Angle()
                local dify = math.AngleDifference(ownerang.y, data.y)
                if dify < 0 then dify = -dify end
                if dify > 5 then continue end
                local difp = math.AngleDifference(ownerang.p, data.p)
                if difp < 0 then difp = -difp end
                if difp > 5 then continue end
                self.trackedent = v
            end
        end
    else 
        timer.Simple( 0, function()
            if not IsValid(self) then return end 
            self.tracktime    = 0
            self.trackedent = nil
        end )
    end

    if not CLIENT then return end
    if self.tracktime >= 3 then
        self:EmitSound("w/rocket/rocket_lock_confirmed.wav",75,100,1,CHAN_AUTO)
    elseif self.tracktime == 2 then
        self:EmitSound("w/rocket/rocket_lock_start.wav",75,100,1,CHAN_AUTO)
    elseif self.tracktime == 1 then
        self:EmitSound("w/rocket/rocket_lock_start.wav",75,100,1,CHAN_AUTO)
    end
end

function SWEP:DrawHUD()
    BaseClass.DrawHUD(self)
	if self:IsAttached("rocket_mod_tracking") then
		local target = self.trackedent
		if IsValid(target) then
			local pos = (target:GetPos() + target:OBBCenter()):ToScreen()
			local w = ScrW() / 40
			if self.tracktime >= 3 then
				surface.SetDrawColor(255, 0, 0)
			elseif self.tracktime >= 2 then
				surface.SetDrawColor(255, 255, 0)
			elseif self.tracktime >= 1 then
				surface.SetDrawColor(0, 255, 0)
			end
			surface.DrawOutlinedRect(pos.x - (w / 2), pos.y - (w / 2), w, w)
			if self.tracktime >= 3 then
				--draw.SimpleText("LOCK", "RocketLauncher.LockFont", pos.x, pos.y - (w / 2), Color(255, 0, 0, math.abs(math.sin(CurTime() * 10)) * 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			end
		end
	end
end

function SWEP:SecondaryAttack()
    if not CLIENT then return end
    local ent = self:GetNWEntity("control_rocket")
    if not IsValid(ent) then return end
    if hook.GetTable()["CalcView"]["Joe_CalcView"] then
        hook.Remove("CalcView", "Joe_CalcView")
    else
        hook.Add( "CalcView", "Joe_CalcView", function( ply, pos, angles, fov )
            if not IsValid(ent) or not ply:Alive() or not IsValid(self) then hook.Remove("CalcView", "Joe_CalcView") return end
            local view = {
                origin = ent:GetPos() + (self:GetForward()*8) + (self:GetUp()*0),
                angles = ent:GetAngles(),
                fov = fov,
                drawviewer = true
            }
            return view
        end )
    end
end

function SWEP:ShootBullet(...)
	if IsFirstTimePredicted() then
		if SERVER then
			timer.Simple(0, function()
				local ent = ents.Create("ent_rw_rocket_mods")
				ent.Owner = self.Owner
				if self:IsAttached("rocket_mod_tracking") and self.trackedent and self.tracktime >= 3 then
					ent.trackingmode = "track"
					ent.trackedent = self.trackedent
					self.tracktime	= 0
					self.trackedent = nil
				end
				if self:IsAttached("rocket_mod_pointing") then
					ent.trackingmode = "point"
				end
				if self:IsAttached("rocket_mod_control") then
					ent.trackingmode = "control"
					self:SetNWEntity("control_rocket", ent)
				end
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

