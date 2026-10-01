EFFECT.Mat = Material( "effects/lvs/ballturret_projectorbeam" )
EFFECT.HitMat = Material( "sprites/light_glow02_add" )

function EFFECT:Init( data )
	self.Entity = data:GetEntity()
	
	self.DownPos = Vector(-55, 350, 90)
	self.UpPos = Vector(-55, 370, 125)
	self.StartPos = self.DownPos
	self.EndPos = self.Entity:GetWingTurretTarget()
end

function EFFECT:Think()
	if not IsValid( self.Entity ) or not self.Entity:GetWingTurretFire() then
		return false
	end
	
	self.EndPosDesired = self.Entity:GetWingTurretTarget() 
	self:SetRenderBoundsWS( self.Entity:GetPos(), self.EndPosDesired )
	
	return true
end

local color_white = Color(255, 255, 255, 255)
local color_green = Color(0, 255, 0, 255)
local trData = {}
function EFFECT:Render()
	if not self.EndPosDesired then return end
	
	self.EndPos = self.EndPos + (self.EndPosDesired - self.EndPos) * FrameTime() * 10
	
	for i = -1, 1, 2 do
		local StartPos = self.Entity:LocalToWorld(self.StartPos * Vector(1, i, 1))
		
		trData.start = StartPos
		trData.endpos = self.EndPos
		local Trace = util.TraceLine(trData)
		local EndPos = Trace.HitPos
		
		if self.Entity:WorldToLocal( EndPos ).z < 0 then
			self.StartPos = self.DownPos
		else
			self.StartPos = self.UpPos
		end
		
		if Trace.Entity ~= self.Entity then
			render.SetMaterial(self.Mat)
			render.DrawBeam(StartPos, EndPos, 14 + math.random(0, 4), 1, 0, color_green)
			render.DrawBeam(StartPos, EndPos, 3 + math.random(0, 4), 1, 0, color_white)
			
			render.SetMaterial( self.HitMat )
			local A = 150 + math.random(0, 20)
			local B = 70 + math.random(0, 20)
			render.DrawSprite(StartPos, A, A, color_green)
			render.DrawSprite(StartPos, B, B, color_white)
			
			render.DrawSprite(EndPos, A, A, color_green)
			render.DrawSprite(EndPos + VectorRand() * 10, B, B, color_white)
			
			if math.random(0,5) == 1 then
				local emitter = ParticleEmitter(EndPos, false)
				local dir = (self.Entity:GetPos() - EndPos):GetNormalized()
				
				for i = 0, 10 do
					local particle = emitter:Add("sprites/rico1", EndPos)
					local vel = VectorRand() * 100 + dir * 40
					
					if particle then
						particle:SetVelocity(vel)
						particle:SetAngles(vel:Angle() + Angle(0, 90, 0))
						particle:SetDieTime(math.Rand(0.1, 0.3) * 0.5)
						particle:SetStartAlpha(math.Rand( 200, 255 ))
						particle:SetEndAlpha(0)
						particle:SetStartSize(math.Rand(1, 30))
						particle:SetEndSize(0)
						particle:SetRoll(math.Rand(-100, 100))
						particle:SetRollDelta(math.Rand(-100, 100))
						particle:SetAirResistance(0)
					end
				end
				
				emitter:Finish()
			end
		end
	end
end