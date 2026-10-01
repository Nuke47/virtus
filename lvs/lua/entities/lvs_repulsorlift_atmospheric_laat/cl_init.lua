include("shared.lua")
include( "sh_ballturret_left.lua" )
include( "sh_ballturret_right.lua" )
include( "cl_drawing.lua" )

function ENT:Initialize()
	self.nextEFX = 0
	self.nextDFX = 0
	self.nextBeepSound = 0
	self.nextLFX = 0
	self.NextAlertSound = 0
	--self.ActiveTime = CurTime()
	self.bommed = false
	self.onact = false
end


local spotlight = Material("effects/lvs/laat_spotlight")
local glow_spotlight = Material("sprites/light_glow02_add")
local spotlight_color = Color(255, 255, 255)
local glow_color = Color(255, 255, 255, 10)
local glow_reactor = Material("sprites/light_glow02_add")
local lamp_pos = Vector(3, 0, 135)
local lamp_color_black = Color(0, 0, 0)
local lamp_color_red = Color(255, 0, 0)
local lamp_color_green = Color(0, 255, 0)
local reactor_color = Color(0, 127, 255)
local reactor_pos = {
	Vector(-270, -20, 265),
	Vector(-270, 20, 265),
}

ENT.EngineGlow = Material( "sprites/light_glow02_add" )
ENT.LightGlow = Material( "sprites/light_glow02_add" )
ENT.LightMaterial = Material( "effects/lvs/laat_spotlight" )
ENT.Red = Color( 255, 0, 0, 255)
ENT.SignalSprite = Material( "sprites/light_glow02_add" )
ENT.Spotlight = Material( "effects/lvs/spotlight_projectorbeam" )

ENT.LightMaterial = Material( "effects/lvs/laat_spotlight" )
ENT.GlowMaterial = Material( "sprites/light_glow02_add" )

ENT.EngineColor = Color( 255, 220, 150, 255)
ENT.EngineGlow = Material( "sprites/light_glow02_add" )
ENT.EngineCenter = Material( "vgui/circle" )
ENT.EnginePos = {
	[1] = Vector(-155,0,76.85),
	[2] = Vector(-155,0,41.82),
}

function ENT:WingTurretProjector()
	local FireWingTurret = self:GetWingTurretFire()

	if FireWingTurret == self.OldWingTurretFire then return end

	self.OldWingTurretFire = FireWingTurret

	if FireWingTurret then
		local effectdata = EffectData()
		effectdata:SetEntity( self )
		util.Effect( "lfs_fb_wingturret_projector", effectdata )
	end
end



function ENT:OnFrame()
	self:Boom()

	self:WingTurretProjector()

	self:ENGCheck()

	self:DamageFX()

	self:ExhaustFX()

	self:BTLProjector()
	self:BTRProjector()

end

function ENT:Boom()
	if self:GetHP() > 2200 then
		self.bommed = false
		self:StopParticles()
	end
	if self.bommed == false then
		if self:GetHP() < 2200 then
			ParticleEffectAttach("env_fire_large_smoke", PATTACH_POINT_FOLLOW, self, self:LookupAttachment("R_Heat_Hatch"))
			self.bommed = true
			local effectdata = EffectData()
				effectdata:SetOrigin(self:LocalToWorld(Vector(-300, 0, 180)))
			util.Effect("lvs_explosion_small", effectdata)
		end
	end
end

function ENT:ENGCheck()
	if self.onact == false then
		if self:GetEngineActive() == true then
			self.ActiveTime = CurTime()
			self.onact = true
			self.nextEFX = CurTime() + 1
		end
	end
	if self.onact == true then
		if self:GetEngineActive() == false then
			self.onact = false
			self.StopTime = CurTime()
		end
	end
	if self:GetEngineActive() == false then
		self.onact = false
	end
end

function ENT:ExhaustFX()
	local FullThrottle = self:GetThrottle() >= 35

	if self.OldFullThrottle ~= FullThrottle then
		self.OldFullThrottle = FullThrottle
		if FullThrottle then 
			self:EmitSound("laat_bf2/boost_"..math.random(1, 2)..".wav")
		end
	end

	if self:GetEngineActive() then
		if self.nextEFX < CurTime() then
			self.nextEFX = CurTime() + 0.01
			
			local emitter = ParticleEmitter(self:GetPos(), false)
			local Pos = {
				Vector(-270, -20, 265),
				Vector(-270, 20, 265),
			}

			if emitter then
				for _, v in pairs(Pos) do
					local vOffset = self:LocalToWorld( v )
					local vNormal = -self:GetForward()
					local vOffset2 = vOffset + vNormal * 5

					local particle = emitter:Add("sprites/heatwave", vOffset2)
					if not particle then return end
						particle:SetVelocity(vNormal * math.Rand(1500, 1000) + self:GetVelocity())
						particle:SetLifeTime(0)
						particle:SetDieTime(0.1)
						particle:SetStartAlpha(255)
						particle:SetEndAlpha(0)
						particle:SetStartSize(math.Rand(35, 50))
						particle:SetEndSize(math.Rand(0, 5))
						particle:SetRoll(math.Rand(-1, 1) * 100)
						particle:SetColor(255, 255, 255)
				end
				
				emitter:Finish()
			end
		end
	end
end

function ENT:CanSound()
	self.NextSound = self.NextSound or 0
	return self.NextSound < CurTime()
end

function ENT:CanSound2()
	self.NextSound2 = self.NextSound2 or 0
	return self.NextSound2 < CurTime()
end

function ENT:DelayNextSound( fDelay )
	if not isnumber( fDelay ) then return end
	
	self.NextSound = CurTime() + fDelay
end

function ENT:DelayNextSound2( fDelay )
	if not isnumber( fDelay ) then return end
	
	self.NextSound2 = CurTime() + fDelay
end

function ENT:CalcEngineSound( RPM, Pitch, Doppler )
	if self.ENG then
		self.ENG:ChangePitch(math.Clamp(math.Clamp(80 + Pitch * 25, 50, 255) + Doppler, 0, 255))
		self.ENG:ChangeVolume(math.Clamp(-1 + Pitch * 6, 0.5, 1))
	end
	
	if self.DIST then
		local ply = LocalPlayer()
		local DistMul = math.min((self:GetPos() - ply:GetPos()):Length() / 8000, 1) ^ 2
		self.DIST:ChangePitch(math.Clamp(100 + Doppler * 0.2, 0, 255))
		self.DIST:ChangeVolume(math.Clamp(-1.5 + Pitch * 6, 0.5, 1) * DistMul)
	end
end

function ENT:DamageFX()
	local HP = self:GetHP()
	if HP <= 0 or HP > self:GetMaxHP() * 0.5 then return end

	if self.nextDFX < CurTime() then
		self.nextDFX = CurTime() + 0.05
		
		local effectdata = EffectData()
			effectdata:SetOrigin(self:LocalToWorld(Vector(-280, 0, 250)))
		util.Effect("lfs_blacksmoke", effectdata)
		local effectdata = EffectData()
			effectdata:SetOrigin(self:LocalToWorld(Vector(-280, 0, 250)))
		util.Effect("lfs_blacksmoke", effectdata)
		local effectdata = EffectData()
			effectdata:SetOrigin(self:LocalToWorld(Vector(-280, 0, 250)))
		util.Effect("lfs_blacksmoke", effectdata)

		if HP <= 2200 then
			if math.random(0, 45) < 3 then
				if math.random(1, 3) == 1 then
					local Pos = self:LocalToWorld(Vector(0, 0, 140) + VectorRand() * 20)
						effectdata:SetOrigin(Pos)
					util.Effect("cball_explode", effectdata, true, true)
					sound.Play("laat_bf2/spark"..math.random(1, 4)..".ogg", Pos, 75)
				end
			end

			local ply = LocalPlayer()
			if self.NextAlertSound < CurTime() then
				self.NextAlertSound = CurTime() + 0.27
				self:EmitSound( "laat_bf2/crash.mp3", 85 )

				--sound.Play("laat_bf2/crash.mp3", self:GetPos() + self:GetForward() * 190 + self:GetUp() * 160, 75)
			end
		end
	end
end



function ENT:Draw()
	self:DrawModel()

	if self:GetEngineActive() then
		render.SetMaterial(glow_reactor)
		local delta = CurTime() - self.ActiveTime
		local max = math.min(15 * ( delta / 1 ), 15)

		local t = 0
		for _, v in pairs(reactor_pos) do
			if self:GetHP() < 2200 then
				if self.nextLFX > CurTime() && t == 1 then continue end
				self.nextLFX = CurTime() + math.random(0, 2)
			end

			local vOffset = self:LocalToWorld(v)
			local vNormal = -self:GetForward()
			
			for i = 0, max do 
				local vUp = -self:GetUp()
				local ind = i * 2
				local vOffsetTmp = vOffset + vNormal * -2 + vUp * ind + vNormal * ind

				render.DrawSprite(vOffsetTmp, 60, 60, reactor_color)
			end

			t = t + 1
		end
	else
		if self:GetHP() < 2200 then
			if self.nextLFX <= CurTime() then 
				self.nextLFX = CurTime() + math.random(0, 1)

				render.SetMaterial(glow_reactor)

				local vOffset = self:LocalToWorld(reactor_pos[2])
				local vNormal = -self:GetForward()
				
				for i = 0, 15 do 
					local vUp = -self:GetUp()
					local ind = i * 2
					local vOffsetTmp = vOffset + vNormal * -2 + vUp * ind + vNormal * ind

					render.DrawSprite(vOffsetTmp, 60, 60, reactor_color)
				end
			end
			
		end
		if self:GetHP() < 2200 then
			if self.nextLFX <= CurTime() then 
				self.nextLFX = CurTime() + math.random(0, 2)

				render.SetMaterial(glow_reactor)

				local vOffset = self:LocalToWorld(reactor_pos[1])
				local vNormal = -self:GetForward()
				
				for i = 0, 15 do 
					local vUp = -self:GetUp()
					local ind = i * 2
					local vOffsetTmp = vOffset + vNormal * -2 + vUp * ind + vNormal * ind

					render.DrawSprite(vOffsetTmp, 60, 60, reactor_color)
				end
			end
		end
	end
end

function ENT:OnRemove()
	self:RemoveLight2()
end

function ENT:RemoveLight2()
	if IsValid( self.projector ) then
		self.projector:Remove()
		self.projector = nil
	end

	if IsValid( self.frojector ) then
		self.frojector:Remove()
		self.frojector = nil
	end
end
function ENT:OnSpawn()

end

--[[


function ENT:EngineEffects()
	if not self:GetEngineActive() then return end
end

function ENT:PostDraw()
	if not self:GetEngineActive() then return end
end

function ENT:PostDrawTranslucent()
	if not self:GetEngineActive() then return end
end
]]--
function ENT:OnStartBoost()
	self:EmitSound( "laat_bf2/boost_"..math.random(1, 2)..".wav", 85 )
end

function ENT:OnStopBoost()
	self:EmitSound( "lvs/vehicles/vwing/brake.wav", 85 )
end

function ENT:CalcViewOverride( ply, pos, angles, fov, pod )
	if pod == self:GetDriverSeat() then

		if pod:GetThirdPersonMode() then
			pos = pos + self:GetUp() * 100, angles, fov
		end

		return pos, angles, fov
	end

	if pod == self:GetGunnerSeat() then

		if pod:GetThirdPersonMode() then
			pos = pos + self:GetUp() * 100, angles, fov
		end

		return pos, angles, fov
	end

	if pod:GetThirdPersonMode() then
		pos = ply:GetShootPos() + pod:GetUp() * 40
	else
		pos = pos + pod:GetUp() * 40
	end

	return pos, angles, fov
end

--[[
function ENT:CalcViewOverride( ply, pos, angles, fov, pod )
	if pod == self:GetDriverSeat() or self:GetGunnerSeat() then

		if pod:GetThirdPersonMode() then
			pos = pos + self:GetUp() * 100, angles, fov
		end

		return pos, angles, fov
	end

	if pod:GetThirdPersonMode() then
		pos = ply:GetShootPos() + pod:GetUp() * 40
	else
		pos = pos + pod:GetUp() * 40
	end

	return pos, angles, fov
end]]

function ENT:PreDrawTranslucent()
	if self:GetSpotlightToggle() == false then 
		self:RemoveLight2()
		return false
	end

	if not IsValid( self.projector ) then
		local thelamp = ProjectedTexture()
		thelamp:SetBrightness( 20 ) 
		thelamp:SetTexture( "effects/flashlight/soft" )
		thelamp:SetColor( Color(255,255,255) ) 
		thelamp:SetEnableShadows( false ) 
		thelamp:SetFarZ( 4000 ) 
		thelamp:SetNearZ( 1 ) 
		thelamp:SetFOV( 80 )
		self.projector = thelamp
	end

	local attachment = {
		Pos = Vector(332.26,-2.1,5.41),
		Ang = Angle(135.25,-0.01,0.71)
	}

	if attachment then
		local StartPos = self:LocalToWorld(attachment.Pos)
		local Dir = self:LocalToWorldAngles(attachment.Ang):Up()

		render.SetMaterial( self.LightGlow )
		render.DrawSprite( StartPos + Dir * 0, 20, 20, Color( 255, 255, 255, 255) )

		render.SetMaterial( self.LightMaterial )
		render.DrawBeam(  StartPos - Dir * 0,  StartPos + Dir * 100, 90, 0, 1, Color( 255, 255, 255, 12) ) 
		
		if IsValid( self.projector ) then
			self.projector:SetPos( StartPos )
			self.projector:SetAngles( Dir:Angle() )
			self.projector:Update()
		end
	end

	return false
end

function ENT:BTRProjector()
	local Fire = self:GetBTRFire()
	if Fire == self.OldFireBTR then return end

	self.OldFireBTR = Fire

	if Fire then
		local effectdata = EffectData()
		effectdata:SetEntity( self )
		util.Effect( "lfs_fb_ballturret_right_projector", effectdata )
	end
end
	
function ENT:BTLProjector()
	local Fire = self:GetBTLFire()

	if Fire == self.OldFireBTL then return end

	self.OldFireBTL = Fire
	
	if Fire then
		local effectdata = EffectData()
		effectdata:SetEntity( self )
		util.Effect( "lfs_fb_ballturret_left_projector", effectdata )
	end
end