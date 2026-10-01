AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "sh_ballturret_left.lua" )
AddCSLuaFile( "sh_ballturret_right.lua" )
AddCSLuaFile( "cl_drawing.lua" )
include("shared.lua")
include( "sh_ballturret_left.lua" )
include( "sh_ballturret_right.lua" )

ENT.SpawnNormalOffset = 25

function ENT:OnSpawn( PObj )

	ParticleEffectAttach("env_fire_large_smoke", PATTACH_POINT_FOLLOW, self, self:LookupAttachment("R_Heat_Hatch"))
	self:StopParticles()

	PObj:SetMass( 100000 )

	self.PrimarySND = self:AddSoundEmitter( Vector(256,0,36), "laat_bf2/cannon_shot.mp3", "laat_bf2/cannon_shot.mp3" )
	self.PrimarySND:SetSoundLevel( 110 )

	self.WingRightSND = self:AddSoundEmitter( Vector(-55, -350, 90), "laat_bf2/ballturret_loop.wav", "laat_bf2/ballturret_loop.wav" )
	self.WingRightSND:SetSoundLevel( 110 )

	self.WingLeftSND = self:AddSoundEmitter( Vector(-55, 350, 90), "laat_bf2/ballturret_loop.wav", "laat_bf2/ballturret_loop.wav" )
	self.WingLeftSND:SetSoundLevel( 110 )

	self.SNDTail = self:AddSoundEmitter( Vector(-440,0,157), "laat_bf2/cannon_shot.mp3", "laat_bf2/cannon_shot.mp3" )
	self.SNDTail:SetSoundLevel( 110 )

	local DriverSeat = self:AddDriverSeat( Vector(280, 0, 125), Angle(0, -90, 0) )
	DriverSeat:SetCameraDistance( 1 )
	DriverSeat.ExitPos = Vector(170, 0, 36)

	local GunnerSeat = self:AddPassengerSeat(Vector(180, 0, 160), Angle(0, -90, 0))
	GunnerSeat.ExitPos = Vector(170, 0, 33)
	self:SetGunnerSeat(GunnerSeat)

	-- Ball Turret Left
	do
		local BallTurretPod = self:AddPassengerSeat( Vector(0,0,100), Angle(0,-90,0) )
		BallTurretPod.HidePlayer = false 
        BallTurretPod:SetCameraDistance(1)
        BallTurretPod:SetThirdPersonMode(false)

		local ID = self:LookupAttachment( "L_Ball_Attachement" )
		local Muzzle = self:GetAttachment( ID )

		if Muzzle then
			local Pos,Ang = LocalToWorld( Vector(-10,0,-12), Angle(0,-90,15), Muzzle.Pos, Muzzle.Ang )

			BallTurretPod:SetParent( NULL )
			BallTurretPod:SetPos( Pos )
			BallTurretPod:SetAngles( Ang )
			BallTurretPod:SetParent( self, ID )
			self:SetBTPodL( BallTurretPod )

			self.sndBTL = self:AddSoundEmitter( Vector(0,0,0), "laat_bf2/ballturret_loop.wav", "laat_bf2/ballturret_loop.wav" )
			self.sndBTL:SetSoundLevel( 110 )
			self.sndBTL:SetParent( NULL )
			self.sndBTL:SetPos( Muzzle.Pos )
			self.sndBTL:SetAngles( Muzzle.Ang )
			self.sndBTL:SetParent( self, ID )
		end
	end

	-- Ball Turret Right
	do
		local BallTurretPod = self:AddPassengerSeat( Vector(0,0,100), Angle(0,-90,0) )
		BallTurretPod.HidePlayer = false
        BallTurretPod:SetCameraDistance(1)
        BallTurretPod:SetThirdPersonMode(false)

		local ID = self:LookupAttachment( "R_Ball_Attachement" )
		local Muzzle = self:GetAttachment( ID )

		if Muzzle then
			local Pos,Ang = LocalToWorld( Vector(-10,0,-12), Angle(0,90,15), Muzzle.Pos, Muzzle.Ang )

			BallTurretPod:SetParent( NULL )
			BallTurretPod:SetPos( Pos )
			BallTurretPod:SetAngles( Ang )
			BallTurretPod:SetParent( self, ID )
			self:SetBTPodR( BallTurretPod )

			self.sndBTR = self:AddSoundEmitter( Vector(0,0,0), "laat_bf2/ballturret_loop.wav", "laat_bf2/ballturret_loop.wav" )
			self.sndBTR:SetSoundLevel( 110 )
			self.sndBTR:SetParent( NULL )
			self.sndBTR:SetPos( Muzzle.Pos )
			self.sndBTR:SetAngles( Muzzle.Ang )
			self.sndBTR:SetParent( self, ID )
		end
	end

	self:SetPoseParameter("left_side_turret_z", 0)
	self:SetPoseParameter("left_side_turret_y", -5)
	self:SetPoseParameter("right_side_turret_z", 0)
	self:SetPoseParameter("right_side_turret_y", 5)
	self:SetPoseParameter("back_turret_z", 0)
	self:SetPoseParameter("back_turret_y", 0)
	self:SetBallTurretLHeat( 0 )
	self:SetBallTurretRHeat( 0 )

	local seat = self:AddPassengerSeat(Vector(-60, 0, 7), Angle(0, 90, 0))
	seat.ExitPos = Vector(135, 0, 33)
	self:SetSecondGunnerSeat(seat)

	self:AddPassengerSeat(Vector(135, 0, 7), Angle(0, 90, 0)).ExitPos = Vector(135, 0, 36)

	local ang1, ang2, ang3 = Angle(0, 0, 0), Angle(0, -90, 0), Angle(0, 180, 0) 
	for i = 0, 5 do
		local X = i * 35
		local Y = 35 + i * 3
		
		self:AddPassengerSeat(Vector(120 - X, Y, 7), ang1).ExitPos = Vector(10 - X, 25, 33)
		if i <= 3 then 
			self:AddPassengerSeat(Vector(105 - X, 0, 7), ang2).ExitPos = Vector(10 - X, 0, 33)
		end
		self:AddPassengerSeat(Vector(120 - X, -Y, 7), ang3).ExitPos = Vector(10 - X, -25, 33)
	end

	self:AddEngine(  Vector(-105,0,58) )
	self:AddEngineSound( Vector(-105,0,58) )

	self.SNDLeft = self:AddSoundEmitter( Vector(5,56.3,55), "lvs/vehicles/vwing/fire.mp3", "lvs/vehicles/vwing/fire.mp3" )
	self.SNDLeft:SetSoundLevel( 110 )

	self.SNDRight = self:AddSoundEmitter( Vector(5,-56.3,55), "lvs/vehicles/vwing/fire.mp3", "lvs/vehicles/vwing/fire.mp3" )
	self.SNDRight:SetSoundLevel( 110 )

	self.RocketsModel = ents.Create("laat_rocketlauncher")
	self.RocketsModel:SetPos(self:GetPos())
	self.RocketsModel:SetAngles(self:GetAngles())
	self.RocketsModel:SetParent(self)
	self.RocketsModel:Spawn()

	self.HatchModel = ents.Create("laat_hatch")
	self.HatchModel:SetPos(self:GetPos())
	self.HatchModel:SetAngles(self:GetAngles())
	self.HatchModel:SetParent(self)
	self.HatchModel:Spawn()

	self.NextUseHatch = 0

	self.OldSkin = self:GetSkin()

	self.NextFind = 0
	self.HeldEntities = {}
	self.NextGrab = 0
	self.NextDrop = 0

	self.DamageSounds = {
		"physics/metal/metal_sheet_impact_bullet2.wav",
		"physics/metal/metal_sheet_impact_hard2.wav",
		"physics/metal/metal_sheet_impact_hard6.wav",
	}

	self.DoorMode = 0


	self:InitDoors()
	self:InitHatch()

	self.Light = ents.Create("light_dynamic")
		self.Light:SetKeyValue("brightness", "6")
		self.Light:SetKeyValue("distance", "150")
		self.Light:SetPos(self:GetPos() + self:GetForward() * 50 + self:GetUp() * 120 + self:GetRight() * 3)
		self.Light:SetLocalAngles(Angle(0, 0, 0))
		self.Light:Fire("Color", "255 0 0")
		self.Light:SetParent(self)
		self.Light:Spawn()
		self.Light:Activate()
		self.Light:Fire("TurnOn", "", 0)
		self:DeleteOnRemove(self.Light)

	self.Light2 = ents.Create("light_dynamic")
		self.Light2:SetKeyValue("brightness", "6")
		self.Light2:SetKeyValue("distance", "150")
		self.Light2:SetPos(self:GetPos() + self:GetForward() * -60 + self:GetUp() * 120 + self:GetRight() * 3)
		self.Light2:SetLocalAngles(Angle(0, 0, 0))
		self.Light2:Fire("Color", "255 0 0")
		self.Light2:SetParent(self)
		self.Light2:Spawn()
		self.Light2:Activate()
		self.Light2:Fire("TurnOn", "", 0)
		self:DeleteOnRemove(self.Light2)

	self.nextLFX = 0
	self.nextLightState = "TurnOff"

	self.IsLightOn = true
	self.LastLightState = 1
	self:SetLampMode(1)

	self.closeSequence = ""
	
	self:TurnLightRed()

end

function ENT:GetLoadMaster()
	local seat = self:GetSecondGunnerSeat()
	return IsValid(seat) && seat:GetDriver() || NULL
end


function ENT:HatchOpen()
	hatch:Remove()
end

function ENT:DoorOpen()
	door:Remove()
end

function ENT:OnTick()
	local hp = self:GetHP()
	if hp < 2200 then
		self:StopEngine()
		self:TurnLightRed()
		if self.nextLFX < CurTime() then
			self.nextLFX = CurTime() + math.random(0, 0.01)
			self.Light:Fire(self.nextLightState, "", 0)
			self.Light2:Fire(self.nextLightState, "", 0)

			if self:GetLampMode() != 0 then self:SetLampMode(0) end

			self.nextLightState = self.nextLightState == "TurnOn" && "TurnOff" || "TurnOn"
		end
	end

	local curSkin = self:GetSkin()
	if curSkin ~= self.OldSkin then
		self.OldSkin = curSkin
		self.HatchModel:SetSkin(curSkin)
	end

	local BTbodygroup = self:GetBodygroup(5)

	if BTbodygroup ~= self.oldBTbodygroup then
		self:OnBallturretMounted( BTbodygroup == 0, self.oldBTbodygroup == 0 )
		self.oldBTbodygroup = BTbodygroup
	end

	self:Grabber()
end

local GrabberValidType = {
	["dual_atrt"] = 2,
	["dual_barc"] = 2,
	["solo_barc"] = 1,
}
local GrabberValidClass = {
	["lunasflightschool_niksacokica_at-rt"] = {type = "dual_atrt", pos = Vector(0, 0, 0), ang = Angle(27, -90, 0)},
	["lunasflightschool_niksacokica_barc"] = {type = "dual_barc", pos = Vector(0, 30, 30), ang = Angle(27, -90, 0)},
	["lvs_fakehover_barc"] = {type = "dual_barc", pos = Vector(0, 30, 30), ang = Angle(27, -90, 0)},
	["lvs_atrt"] = {type = "dual_atrt", pos = Vector(0, 0, 0), ang = Angle(27, -90, 0)},
	["lvs_fakehover_74z"] = {type = "dual_barc", pos = Vector(0, -20, 20), ang = Angle(30, -90, 0)},
	["lvs_fakehover_barc_medical"] = {type = "solo_barc", pos = Vector(0, 30, 30), ang = Angle(27, -90, 0)},
	["lunasflightschool_niksacokica_barc_stretcher"] = {type = "solo_barc", pos = Vector(0, 30, 30), ang = Angle(27, -90, 0)},
	["lunasflightschool_niksacokica_74-z_speeder_bike"] = {type = "dual_barc", pos = Vector(0, -20, 20), ang = Angle(30, -90, 0)},
}

function ENT:Grabber()
	local HeldEntitiesAmount = #self.HeldEntities
	if HeldEntitiesAmount < 2 then
		if self.NextFind < CurTime() then
			self.NextFind = CurTime() + 1
			
			local StartPos = self:LocalToWorld(Vector(-200, 0, 100))
			self.CanPickupEnt = NULL
			local Dist = 1000
			local SphereRadius = 150

			for k, v in pairs(ents.FindInSphere(StartPos, SphereRadius)) do
				if v.LAATIsHelding then continue end

				if GrabberValidType[v.LAATHeldType] && isvector(v.LAATHeldPos) && isangle(v.LAATHeldAngle) then
					local Len = (StartPos - v:GetPos()):Length()

					if Len < Dist then
						self.CanPickupEnt = v
						Dist = Len
					end
				else
					local heldData = GrabberValidClass[v:GetClass()]
					if heldData then
						if self.HeldEntitiesType && self.HeldEntitiesType != heldData.type then continue end
						local Len = (StartPos - v:GetPos()):Length()

						if Len < Dist then
							self.CanPickupEnt = v
							Dist = Len
						end
					end
				end
			end
		end
	end
end

function ENT:ToggleHatch()
	if self.NextUseHatch >= CurTime() then return end
	self.NextUseHatch = CurTime() + 2.5

	self.IsHatchOpen = not self.IsHatchOpen
	
	self:EmitSound("laat_bf2/ramp.mp3")

	if self.IsHatchOpen then	
		self.HatchModel:ResetSequence("Rear_Hatch_Open")
		self.HatchModel:SetPlaybackRate(0.7)

		self:TurnLightGreen()
	else
		self.HatchModel:ResetSequence("Rear_Hatch_Closed")
		self.HatchModel:SetPlaybackRate(0.7)

		if self.DoorMode != 1 then
			self:TurnLightRed()
		end
	end
end

function ENT:OnBallturretMounted( ismounted, oldvar )
	if ismounted == oldvar then return end

	self._CanUseBT = ismounted

	if ismounted then
		if IsValid( self.BTPodR_ent_orig ) then 
			self:SetBTPodR( self.BTPodR_ent_orig )
			self.BTPodR_ent_orig:SetNWInt( "pPodIndex", self.BTPodR_index_orig )
		end

		if IsValid( self.BTPodL_ent_orig ) then 
			self:SetBTPodL( self.BTPodL_ent_orig )
			self.BTPodL_ent_orig:SetNWInt( "pPodIndex", self.BTPodL_index_orig )
		end
	else
		local Pod_R = self:GetBTPodR()
		if IsValid( Pod_R ) then 
			self.BTPodR_ent_orig = Pod_R
			self.BTPodR_index_orig = Pod_R:GetNWInt( "pPodIndex" )
			Pod_R:SetNWInt( "pPodIndex", -1 )

			local ply = Pod_R:GetDriver()
			if IsValid( ply ) then
				ply:ExitVehicle()
			end
		end

		local Pod_L = self:GetBTPodL()
		if IsValid( Pod_L ) then 
			self.BTPodL_ent_orig = Pod_L
			self.BTPodL_index_orig = Pod_L:GetNWInt( "pPodIndex" )
			Pod_L:SetNWInt( "pPodIndex", -1 )

			local ply = Pod_L:GetDriver()
			if IsValid( ply ) then
				ply:ExitVehicle()
			end
		end

		self:SetBTPodR( NULL )
		self:SetBTPodL( NULL )
	end
end

function ENT:BallturretDamage( target, attacker, HitPos, HitDir )
	if not IsValid( target ) then return end

	if not IsValid( attacker ) then
		attacker = self
	end

	if target ~= self then
		local dmginfo = DamageInfo()
		dmginfo:SetDamage( 3000 * FrameTime() )
		dmginfo:SetAttacker( attacker )
		dmginfo:SetDamageType( DMG_SHOCK + DMG_ENERGYBEAM + DMG_AIRBOAT )
		dmginfo:SetInflictor( self ) 
		dmginfo:SetDamagePosition( HitPos ) 
		dmginfo:SetDamageForce( HitDir * 10000 ) 
		target:TakeDamageInfo( dmginfo )
	end
end

function ENT:CreateDoor(pos, ang, model)
	local door = ents.Create("prop_dynamic")
		door:SetModel(model || "models/fisher/laat/door_phys.mdl")
		door:SetPos(pos)
		door:SetAngles(ang)
		door:SetColor(Color(255, 255, 255, 0))
		door:SetRenderMode(RENDERMODE_TRANSALPHA)
		door:PhysicsInit(SOLID_VPHYSICS)
		door:SetSolid(SOLID_VPHYSICS)
		door:Spawn()
		door:Activate()
		door:SetParent(self)
		door:SetLightingOriginEntity(self)
		self:DeleteOnRemove(door)
		door:DeleteOnRemove(self)
		door.LAATDoor = true

		function door:OnTakeDamage(dmginfo)
			self:TakeDamageInfo(dmginfo)
		end

	constraint.NoCollide(door, self, 0, 0)

	return door
end

function ENT:CreateHatchb(pos, ang, model)
	local hatch = ents.Create("prop_dynamic")
		hatch:SetModel(model || "models/fisher/laat/door_phys.mdl")
		hatch:SetPos(pos)
		hatch:SetAngles(ang)
		hatch:SetColor(Color(255, 255, 255, 0))
		hatch:SetRenderMode(RENDERMODE_TRANSALPHA)
		hatch:PhysicsInit(SOLID_VPHYSICS)
		hatch:SetSolid(SOLID_VPHYSICS)
		hatch:Spawn()
		hatch:Activate()
		hatch:SetParent(self)
		hatch:SetLightingOriginEntity(self)
		self:DeleteOnRemove(hatch)
		hatch:DeleteOnRemove(self)
		hatch.LAATDoor = true

		function hatch:OnTakeDamage(dmginfo)
			self:TakeDamageInfo(dmginfo)
		end

	constraint.NoCollide(hatch, self, 0, 0)

	return hatch
end

function ENT:CreateHatch(pos, ang)
	return self:CreateHatchb(pos, ang, "models/fisher/laat/hatch_phys.mdl")
end

function ENT:TurnLightGreen()
	self.Light:Fire("Color", "0 255 0")
	self.Light:SetKeyValue("brightness", "5")
	self.Light2:Fire("Color", "0 255 0")
	self.Light2:SetKeyValue("brightness", "5")

	self.LastLightState = 2
	if self.IsLightOn then self:SetLampMode(2) end
end

function ENT:TurnLightRed()
	self.Light:Fire("Color", "255 0 0")
	self.Light:SetKeyValue("brightness", "6")
	self.Light2:Fire("Color", "255 0 0")
	self.Light2:SetKeyValue("brightness", "6")

	self.LastLightState = 1
	if self.IsLightOn then self:SetLampMode(1) end
end

function ENT:InitHatch()

	local bonePos, boneAng = self:GetBonePosition(self:LookupBone("LAAT")) 
	local boneAngL = Angle(boneAng.p, boneAng.y, boneAng.r)
		boneAngL.y = boneAngL.y - 90

	local boneAngRear = Angle(boneAng.p, boneAng.y, boneAng.r)
		boneAngRear.y = boneAngRear.y - 90
		boneAngRear.p = boneAngRear.p + 1
	local offset = self:GetRight() * 2 + self:GetForward() * 20 + self:GetUp() * -140
	local hatch = self:CreateHatch(bonePos + offset, boneAngRear)
	hatch:SetParent(self.HatchModel, self.HatchModel:LookupAttachment("Hatch_L_Barc"))
	self.HatchPhysic = hatch
end

function ENT:GetDoorMode()
	return self.DoorMode
end

function ENT:SetDoorMode(amount)
	self.DoorMode = amount
end


function ENT:InitDoors()
	self.Doors = {}

	local bonePos, boneAng = self:GetBonePosition(self:LookupBone("LAAT")) 
	local boneAngL = Angle(boneAng.p, boneAng.y, boneAng.r)
		boneAngL.y = boneAngL.y - 90

	local offset = self:GetRight() * 10 + self:GetForward() * 0 + self:GetUp() * -110
	local door = self:CreateDoor(bonePos + offset, boneAngL)
	self.Doors["L_Door2"] = {ent = door, closeoffset = Vector(10, 0, -110), openoffsethalf = Vector(-20, -140, -110), openoffsetboth = Vector(0, 125, -110)}

	local offset = self:GetRight() * 3 + self:GetForward() * -130 + self:GetUp() * -110
	local door = self:CreateDoor(bonePos + offset, boneAngL)
	self.Doors["L_Door1"] = {ent = door, closeoffset = Vector(3, -130, -110), openoffsetboth = Vector(-10, -200, -110)}

	local boneAngR = Angle(boneAng.p, boneAng.y, boneAng.r)
		boneAngR.y = boneAngR.y + 95

	local offset = self:GetRight() * -20 + self:GetForward() * 100 + self:GetUp() * -110
	local door = self:CreateDoor(bonePos + offset, boneAngR)
	self.Doors["R_Door2"] = {ent = door, closeoffset = Vector(-20, 100, -110), openoffsethalf = Vector(10, -35, -115), openoffsetboth = Vector(-10, 230, -115)}

	local offset = self:GetRight() * -17 + self:GetForward() * -25 + self:GetUp() * -110
	local door = self:CreateDoor(bonePos + offset, boneAngR)
	self.Doors["R_Door1"] = {ent = door, closeoffset = Vector(-17, -25, -110), openoffsetboth = Vector(0, -90, -115)}

	local boneAngRear = Angle(boneAng.p, boneAng.y, boneAng.r)
		boneAngRear.y = boneAngRear.y - 90
		boneAngRear.p = boneAngRear.p + 1
	local offset = self:GetRight() * 2 + self:GetForward() * 20 + self:GetUp() * -140
	local hatch = self:CreateHatch(bonePos + offset, boneAngRear)
	hatch:SetParent(self.HatchModel, self.HatchModel:LookupAttachment("Hatch_L_Barc"))
	self.HatchPhysic = hatch
end

function ENT:OnEngineActiveChanged( Active )
	if Active then
		self:EmitSound( "laat_bf2/engine_start.mp3" )
	else
		self:EmitSound( "laat_bf2/engine_end.mp3" )
	end
end

function ENT:OnVehicleSpecificToggled( new )
end


function ENT:DoorOC()	

	local Driver = self:GetDriver()

	local DoorMode = self:GetDoorMode() + 1
	DoorMode = DoorMode >= 2 && 0 || DoorMode
	self:SetDoorMode(DoorMode)

	if DoorMode == 0 then
		self:ResetSequence(self.closeSequence)
		self:SetPlaybackRate(1.5)

		local bonePos, _ = self:GetBonePosition(self:LookupBone("LAAT"))
		
		for doorID, _ in pairs(self.DoorsToClose) do
			local doorData = self.Doors[doorID]
			local offset = self:GetRight() * doorData.closeoffset.x + self:GetForward() * doorData.closeoffset.y + self:GetUp() * doorData.closeoffset.z
			doorData.ent:SetParent(nil)
			doorData.ent:SetPos(bonePos + offset)
			doorData.ent:SetParent(self)
		end

		timer.Simple(0.75, function()
			if not IsValid(self) then return end
			self:EmitSound("laat_bf2/door_close.mp3")

			if not self.IsHatchOpen then
				self:TurnLightRed()
			end
		end)
	end

	if DoorMode == 1 then
		self:ResetSequence("Door_Open_Half")
		self.closeSequence = "Door_Closed_Half"
		
		local bonePos = self:GetBonePosition(self:LookupBone("LAAT"))
		
		local doorData = self.Doors["L_Door2"]
		local offset = self:GetRight() * doorData.openoffsethalf.x + self:GetForward() * doorData.openoffsethalf.y + self:GetUp() * doorData.openoffsethalf.z
		doorData.ent:SetParent(nil)
		doorData.ent:SetPos(bonePos + offset)
		doorData.ent:SetParent(self)

		local doorData = self.Doors["R_Door2"]
		local offset = self:GetRight() * doorData.openoffsethalf.x + self:GetForward() * doorData.openoffsethalf.y + self:GetUp() * doorData.openoffsethalf.z
		doorData.ent:SetParent(nil)
		doorData.ent:SetPos(bonePos + offset)
		doorData.ent:SetParent(self)

		self.DoorsToClose = {
			["L_Door2"] = true,
			["R_Door2"] = true,
		}
		self:EmitSound("laat_bf2/door_open.mp3")
		self:TurnLightGreen()
	end	
end


function ENT:GetAttachmentID(heldType)
	local attachment

	if heldType == "dual_barc" then
		attachment = #self.HeldEntities == 0 && "Hatch_L_Barc" || "Hatch_R_Barc"
	elseif heldType == "solo_barc" then
		attachment = "Hatch_R_Barc"
	elseif heldType == "dual_atrt" then
		attachment = #self.HeldEntities == 0 && "Hatch_L_ATRT" || "Hatch_R_ATRT"
	end

	return self.HatchModel:LookupAttachment(attachment)
end

function ENT:GrabEntity()
	if self.HeldEntitiesLimit && #self.HeldEntities >= self.HeldEntitiesLimit then return end
	if self.NextGrab >= CurTime() then return end
	self.NextGrab = CurTime() + 1

	if IsValid(self.CanPickupEnt) then
		local entData = GrabberValidClass[self.CanPickupEnt:GetClass()]

		self.lagent = self.CanPickupEnt:GetClass()

		if not istable(entData) then
			entData = {}
			entData.pos = self.CanPickupEnt.LAATHeldPos
			entData.ang = self.CanPickupEnt.LAATHeldAngle
			entData.type = self.CanPickupEnt.LAATHeldType
		end

		local attachmentID = self:GetAttachmentID(entData.type)
		local Muzzle = self.HatchModel:GetAttachment(attachmentID)

		if Muzzle then
			local Pos, Ang = LocalToWorld(entData.pos, entData.ang, Muzzle.Pos, Muzzle.Ang)

			self.CanPickupEnt:StopEngine()

			--self.CanPickupEnt:PhysicsDestroy()
			
			--[[if self.CanPickupEnt.SetIsCarried then
				self.CanPickupEnt:SetIsCarried(true)
			end]]

			self.CanPickupEnt:SetPos(Pos)
			self.CanPickupEnt:SetAngles(Ang)
			self.CanPickupEnt:SetParent(self.HatchModel, attachmentID)

			local OldOnTick = self.CanPickupEnt.OnTick
			self.CanPickupEnt.OnTick = function(self) end

			local OldToggleEngine = self.CanPickupEnt.ToggleEngine
			self.CanPickupEnt.ToggleEngine = function(self) end

			self.CanPickupEnt.LAATIsHelding = true

			self.HeldEntitiesLimit = GrabberValidType[entData.type]
			self.HeldEntitiesType = entData.type

			self.HeldEntities[#self.HeldEntities + 1] = {ent = self.CanPickupEnt, PosEnt = PosEnt, OldOnTick = OldOnTick, OldToggleEngine = OldToggleEngine} 
		end
	end
end

function ENT:DropHeldEntity()
	if #self.HeldEntities <= 0 then return end
	if self.NextDrop >= CurTime() then return end
	self.NextDrop = CurTime() + 1
	
	local heldEntityData = self.HeldEntities[#self.HeldEntities]
	local FrontEnt = heldEntityData.ent
	if IsValid(FrontEnt) then
		if FrontEnt.SetIsCarried then
			FrontEnt:SetIsCarried(false)
		end

		local mirror = #self.HeldEntities > 1 && -1 || 1
		FrontEnt:SetParent(NULL)
		FrontEnt:SetPos(self:GetPos() + self:GetForward() * -400 + self:GetUp() * 50 + self:GetRight() * 60 * mirror)
	
		FrontEnt:PhysicsInit(SOLID_VPHYSICS)
		FrontEnt:SetMoveType(MOVETYPE_VPHYSICS)
		FrontEnt:SetSolid(SOLID_VPHYSICS)
		FrontEnt:SetUseType(SIMPLE_USE)
		FrontEnt:SetRenderMode(RENDERMODE_TRANSALPHA)
		FrontEnt:AddFlags(FL_OBJECT)

		local PObj = FrontEnt:GetPhysicsObject()
		if not IsValid(PObj) then 
			FrontEnt:Remove()
			print("LVS: missing model. Vehicle terminated.")
			return
		end
	
		FrontEnt.OnTick = heldEntityData.OldOnTick
		FrontEnt.ToggleEngine = heldEntityData.OldToggleEngine
		

		
		local playertransport = FrontEnt:GetDriver()
		local hptrasport = FrontEnt:GetHP()
		FrontEnt:Remove()

		FrontEnt.smSpeed = 200
		local mirror = #self.HeldEntities > 1 && -1 || 1
		FrontEnt.LAATIsHelding = false

		local vehicledrop = ents.Create( self.lagent )
		vehicledrop:SetPos(self:GetPos() + self:GetForward() * -400 + self:GetUp() * 50 + self:GetRight() * 60 * mirror)
		vehicledrop:SetAngles( self:GetAngles() )
		vehicledrop:Spawn()
		vehicledrop:Activate()
		vehicledrop:SetHP(hptrasport)
		if IsValid(playertransport) then 
			timer.Simple( 0.1, function()
				playertransport:EnterVehicle( vehicledrop:GetDriverSeat() )
				--vehicledrop:SetPassenger(playertransport)
			end )
		end
		self.lagent = 0


	end
	
	self.HeldEntities[#self.HeldEntities] = nil

	if #self.HeldEntities == 0 then
		self.HeldEntitiesLimit = nil
		self.HeldEntitiesType = nil
	end
end