

util.PrecacheModel( "models/KingPommes/starwars/atrt/main.mdl" )
if (!util.IsValidModel( "models/KingPommes/starwars/atrt/main.mdl" )) then return end

ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "speeder_base"
ENT.Type = "vehicle"

ENT.PrintName = "AT-RT"
ENT.Author = "KingPommes"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Star Wars Vehicles: Republic"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.AutomaticFrameAdvance =  true 

ENT.Vehicle = "ATRT" 
ENT.EntModel = "models/KingPommes/starwars/atrt/main.mdl"

ENT.StartHealth = 1300
ENT.BurstShots = 4
ENT.NoWobble = true
ENT.HoverMod = 0

ENT.backAmount = 32
ENT.frontAmount = 128
ENT.upAmount = 16
ENT.leftAmount = 32
ENT.rightAmount = 32
ENT.Depth = -512

list.Set("SWVehicles", ENT.PrintName, ENT)

if SERVER then
	
	AddCSLuaFile()
	function ENT:SpawnFunction(pl, tr)
		local e = ents.Create("kingpommes_swv_atrt")
		e:SetPos(tr.HitPos)
		e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+0,0))
		e:Spawn()
		e:Activate()
		return e
	end
	
	function ENT:SpawnTurret(pos,ang)
		local e = ents.Create("base_anim")
		e:SetModel("models/KingPommes/starwars/atrt/turret.mdl")
		e:SetPos(pos)
		e:SetAngles(ang)
		e:SetParent(self)
		e:Spawn()
		e:Activate()
		self.Turret = e
	end
	
	function ENT:SpeederClassing()
	end
	
	function ENT:Initialize()
		self.BaseClass.Initialize(self)
		self.NextUse = {Use = CurTime(),Fire = CurTime(), Boost=CurTime()}
		self.Shots = 0
	
		self.Roll = 0;
		self.YawAccel = 0;
		self.num = 0;
	
		self.SeatClass = "phx_seat3"
		self.SpeederClass = 2
		self.ForwardSpeed = 128
		self.BoostSpeed = 300
		self.AccelSpeed = 10
		self.HoverMod = 0
		self.CanBack = false
		self.StartHover = 0
		self.StandbyHoverAmount = 0
		self.ExitModifier = {x=64,y=0,z=0}
	
	
		local driverPos = self:GetAttachment(self:LookupAttachment("driver")).Pos + self:GetUp()*-8
		local driverAng = self:GetAttachment(self:LookupAttachment("driver")).Ang
		local turretPos = Vector()
		local turretAng = Angle()
	
		self:SpawnChairs(driverPos, driverAng, false)
		self:SpawnTurret(turretPos, turretAng, false)
		self.DriverChair:Fire("setparentattachmentmaintainoffset", "driver", 0)
		self.Turret:Fire("setparentattachment", "turret", 0)
	
		self.WeaponLocations = {}
		self.Bullet = CreateBulletStructure(200,"blue_noion",true)
		self:SpawnWeapons()
	
		self:SetSequence(self:LookupSequence( "sitdown" ))
		self:SetPlaybackRate(1)
	end
	
	hook.Add("PlayerEnteredVehicle","ATRTSeatEnter", function(p,v)
		if(IsValid(v) and IsValid(p)) then
			local e = v:GetParent()
			if e.IsSWVehicle and e:GetClass() == "kingpommes_swv_atrt" then
				p:SetNetworkedEntity("ATRT",v:GetParent())
				e:SetNetworkedEntity("ATRT_PILOT", p)
			end
		end
	end)
	
	hook.Add("PlayerLeaveVehicle", "ATRTSeatExit", function(p,v)
		if(IsValid(p) and IsValid(v)) then
		local e = v:GetParent()
			if e.IsSWVehicle and e:GetClass() == "kingpommes_swv_atrt" then
				if(IsValid(e)) then
					p:SetPos(e:GetPos() + e:GetRight()*e.ExitModifier.x + e:GetForward() * e.ExitModifier.y + e:GetUp() * e.ExitModifier.z)
				end
				p:SetNetworkedEntity("ATRT",NULL)
				e:SetNetworkedEntity("ATRT_PILOT", NULL)
			end
		end
	end)
	
	local ZAxis = Vector(0,0,1)
	
	function ENT:Think()
		self:NextThink(CurTime())
		self.BaseClass.Think(self)
	
		if self.LastSkin ~= self:GetSkin() then
			self.LastSkin = self:GetSkin()
			self.Turret:SetSkin(self.LastSkin)
		end
	
		if self.LastColor ~= self:GetColor() then
			self.LastColor = self:GetColor()
			self.Turret:SetColor(self.LastColor)
		end
		
		if(self.Inflight) then
			if self.MiddleTrace.HitPos.z > self:GetPos().z - 50 then
				if self:GetNWInt("Speed") <= 0 then
					self:SetSequence(self:LookupSequence( "idle" ))
					self:SetPlaybackRate(1)
				end
	
				if self:GetNWInt("Speed") > 0 and self:GetNWInt("Speed") <= 100 then
					self:ResetSequence(self:LookupSequence( "walking" ))
					self:SetPlaybackRate(self:GetNWInt("Speed") / (self.ForwardSpeed / 2))
				end
				
				if self:GetNWInt("Speed") > 100 then
					self:ResetSequence(self:LookupSequence("running"))
					self:SetPlaybackRate(self:GetNWInt("Speed")/ (420 / 2 ))
				end
			else
				if (self:GetNWInt("Speed") > 130) then
					self:SetSequence(self:LookupSequence( "inair_l" ))
				end
			end
		
			if(IsValid(self.Pilot)) then
				if(self.Pilot:KeyDown(IN_ATTACK)) then
					self:FireWeapons()
				end
	
				if(self.Pilot:KeyPressed(IN_JUMP)) and not self.Pilot:KeyDown(IN_RELOAD) and self.MiddleTrace.HitPos.z > self:GetPos().z - 10 and self:GetNWInt("Speed") > 100 then
					self.Accel.UP = self.Accel.UP + self:GetNWInt("Speed")*2.5
				end
				return true
			end
		end
		self:NextThink(CurTime())
	end
	
	function ENT:Enter(p,driver)
		self.BaseClass.Enter(self, p, driver)
		
		self:SetSequence(self:LookupSequence( "standup" ))
		self:SetPlaybackRate(1)
	end
		
	function ENT:Exit(driver,kill)
		self.BaseClass.Exit(self, driver,kill)
		
		self:SetSequence(self:LookupSequence( "sitdown" ))
		self:SetPlaybackRate(1)
		
		self:ResetSequenceInfo()
	end
		
	function ENT:FireWeapons()
		if(self.NextUse.Fire < CurTime()) then
			local WeaponPos = self:GetAttachment(self:LookupAttachment("turret")).Pos
			
			local aim
			if IsValid(self.Pilot) then
				aim = self.Pilot:EyeAngles()
				
				tr = util.TraceLine({
					start = WeaponPos,
					endpos = self.Pilot:GetPos() + Angle(aim.x-14.5,aim.y):Forward() * 100000,
					filter = {
						self, 
						self.Pilot,
						self.Turret
					}
				})
				
				if tr.Entity == self or tr.Entity == self.Turret or tr.Entity == self.Pilot then
					return
				end
		
				local angPos = (tr.HitPos - WeaponPos)
		
				self.Bullet.Src	= WeaponPos + angPos
				self.Bullet.Dir = angPos
		
				self.Turret:FireBullets(self.Bullet)
		
				self.Turret:ResetSequence(self.Turret:LookupSequence("Shoot"))
				self.Turret:SetPlaybackRate(1)
		
				self:EmitSound("atrt.shoot")
		
				if self.NextUse.Fire < CurTime() - 0.75 then
					self.Shots = 1
				else
					self.Shots = (self.Shots + 1) % self.BurstShots
				end
		
				if self.Shots == 0 then
					self.NextUse.Fire = CurTime() + 0.75
				else
					self.NextUse.Fire = CurTime() + 0.1
				end
			end
		end
	end
	
	local FlightPhys={
		secondstoarrive	= 0.5;
		maxangular		= 50000;
		maxangulardamp	= 100000;
		maxspeed			= 1000000;
		maxspeeddamp		= 500000;
		dampfactor		= 1;
		teleportdistance	= 5000;
	}

	local ZAxis = Vector(0,0,1)

	function ENT:RunTraces()
		self.FrontTrace = util.TraceLine({
			start = self.FrontPos,
			endpos = self.FrontPos + self:GetUp()*self.Depth,
			mask = MASK_SOLID,
		})
		
		self.BackTrace = util.TraceLine({
			start = self.BackPos,
			endpos = self.BackPos + self:GetUp()*self.Depth,
			filter = function(ent) return !ent:IsPlayer() end,
			mask = MASK_SOLID,		
		})
		
		self.MiddleTrace = util.TraceLine({
			start = self.MiddlePos,
			endpos = self.MiddlePos + self:GetUp()*self.Depth,
			filter = function(ent) return !ent:IsPlayer() end,
			mask = MASK_SOLID,
		})
		-- self.BaseClass.RunTraces(self)
		-- remove WaterTrace so AT-RT can walk underwater
		-- instead of ontop like jebus
		self.WaterTrace = util.TraceLine({
		})
		
		-- we also introduce two more traces
		self.LeftTrace = util.TraceLine({
			start = self.LeftPos,
			endpos = self.LeftPos + self:GetUp() *self.Depth,
			filter = { self, self.Feet },
			mask = MASK_SOLID,
		})
		self.RightTrace = util.TraceLine({
			start = self.RightPos,
			endpos = self.RightPos + self:GetUp() *self.Depth,
			filter = { self, self.Feet },
			mask = MASK_SOLID,
		})
	end
	
	function ENT:PhysicsSimulate( phys, deltatime )
		self.BackPos = self:GetPos()+self:GetForward()*-self.backAmount+self:GetUp()*self.upAmount
		self.FrontPos = self:GetPos()+self:GetForward()*self.frontAmount+self:GetUp()*self.upAmount
		self.MiddlePos = self:GetPos()+self:GetUp()*self.upAmount
		self.LeftPos = self:GetPos()+self:GetRight()*-self.leftAmount+self:GetUp()*self.upAmount
		self.RightPos = self:GetPos()+self:GetRight()*self.rightAmount+self:GetUp()*self.upAmount
		if(self.Inflight) then
		
			-- skip if in jump
			if(self.Pilot:KeyDown(IN_JUMP) and self:GetNWInt("Speed") > 130) then
				return
			end
			
			local UP = ZAxis
			self.RightDir = self.Entity:GetRight()
			self.FWDDir = self.Entity:GetForward()
			
			self:RunTraces()
			
			-- stuck damage control
			if (math.abs(self.BackTrace.HitPos.z - self.FrontTrace.HitPos.z) > 100 or math.abs(self.LeftTrace.HitPos.z - self.RightTrace.HitPos.z) > 100) then
				if (self:GetAngles().x > 20 or self:GetAngles().x < -20 or self:GetAngles().z > 20 or self:GetAngles().z < -20) then
					self:SetPos(Vector(self:GetPos().x, self:GetPos().y, self:GetPos().z+50))
					self:SetAngles(Angle(0, self:GetAngles().y, 0))
				end
			end
		
			-- vehicle shouldnt bank in when turning
			self.ExtraRoll = Angle(0,0,0)
			-- adjust vehicle angle to ground
			if(!self.WaterTrace.Hit) then
				-- Forward depending on main model!!!
				-- angling forwards/ backwards
				if(self.FrontTrace.HitPos.z >= self.BackTrace.HitPos.z) then
					self.PitchMod = Angle(math.Clamp((self.BackTrace.HitPos.z - self.FrontTrace.HitPos.z),-45,45)/2, 0, 0)
				else
					self.PitchMod = Angle(math.Clamp(-(self.FrontTrace.HitPos.z - self.BackTrace.HitPos.z),-45,45)/2, 0, 0)
				end
				-- angling sideways left/ right
				if(self.RightTrace.HitPos.z >= self.LeftTrace.HitPos.z) then
					self.PitchMod = Angle(self.PitchMod.x,self.PitchMod.y,math.Clamp((self.LeftTrace.HitPos.z - self.RightTrace.HitPos.z),-45,45)/2)
				else
					self.PitchMod = Angle(self.PitchMod.x,self.PitchMod.y,math.Clamp(-(self.RightTrace.HitPos.z - self.LeftTrace.HitPos.z),-45,45)/2)
				end
			end
			worldZ = self:GetPos().z

			if self.MiddleTrace.HitPos.z < worldZ - 10 or self.Accel.UP > 0 then
				self.Accel.UP = self.Accel.UP - 10
			else
				self.Accel.UP = 0
				worldZ = self:GetHover()
			end
		end
		self.BaseClass.PhysicsSimulate(self,phys,deltatime)
	end

	function ENT:Rotorwash(b)
		-- Disabled Dust around vehicle
	end
end

if CLIENT then
	
	function ENT:StartClientsideSound(mode)
		if mode ~= "Engine" then
			self.BaseClass.StartClientsideSound(mode)
			self.SoundsOn.Engine = false
		end
	end
	
	
	
	function ENT:Think()
	
		self.BaseClass.Think(self)
	
		self.Pilot = self:GetNWEntity("ATRT_PILOT")
	
		if(IsValid(self.Pilot)) then
	
			local aim = self.Pilot:EyeAngles()
	
			self:ManipulateBoneAngles(self:LookupBone("turret_x"), Angle(0,0,aim.x))
			self:ManipulateBoneAngles(self:LookupBone("turret_z"), Angle(aim.y - 90,0,0))
	
			return true
		else
			self:ManipulateBoneAngles(self:LookupBone("turret_x"), Angle(0,0,0))
			self:ManipulateBoneAngles(self:LookupBone("turret_z"), Angle(0,0,0))
		end
	end

	ENT.HasCustomCalcView = true
	local View = {}
	function CalcView()
		
		local p = LocalPlayer()
		local self = p:GetNWEntity("ATRT", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL)
		local WalkingATTESeat = p:GetNWEntity("ATRTSeat",NULL)

		if(IsValid(self)) then

			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-150+self:GetUp()*100
					local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle()
						View.origin = pos
						View.angles = face
					return View
				end
			end
			
			if(IsValid(ATRTSeat)) then
				local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()--*-300+self:GetUp()*220
				local face = ((self:GetPos() + Vector(0,0,150))- pos):Angle()
					View.origin = pos
					View.angles = face
				return View
			end
		end
	end
	hook.Add("CalcView", "ATRTView", CalcView)
	
	function ATRTReticle()
	
		local p = LocalPlayer()
		local Flying = p:GetNWBool("FlyingATRT")
		local self = p:GetNWEntity("ATRT")
		if(Flying and IsValid(self)) then		
			local cannonpos = self:GetAttachment(self:LookupAttachment("turret")).Pos
			local cannonang = self:GetAttachment(self:LookupAttachment("turret")).Ang
	
	        surface.SetDrawColor( Color(0, 127, 255, 255) )		
			
			tr = util.TraceLine({
				start = cannonpos,
				endpos = cannonpos + cannonang:Forward()*100000,
				filter = {self},
			})
			
		    local vpos = tr.HitPos
		    local screen = vpos:ToScreen()
		    local x,y
		
			 x = 0
			 y = 0
			for k,v in pairs(screen) do
				if(k == "x") then
					x = v
				elseif(k == "y") then
					y = v
				end
			end
			
		    local w = ScrW()/100*2
		    local h = w
		    x = x - w/2
		    y = y - h/2
			
			surface.SetMaterial( Material( "hud/reticle.png", "noclamp" ) )
			surface.DrawTexturedRectUV( x , y, w, h, 0, 0, 1, 1 )
			SW_Speeder_DrawHull(self.StartHealth)
			SW_Speeder_DrawSpeedometer()
		end
	end
	hook.Add("HUDPaint", "ATRTReticle", ATRTReticle)
end