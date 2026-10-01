if SERVER then AddCSLuaFile() end

function EFFECT:Init(data)
	self.Start = data:GetOrigin()
	self.size = data:GetScale()
	self.Emitter = ParticleEmitter(self.Start)
	
	for i = 1, 55 do
		local p = self.Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), self.Start)
		p:SetDieTime(math.Rand((4/3), 4))
		p:SetStartAlpha(95)
		p:SetEndAlpha(0)
		p:SetStartSize(math.random(100, 140) * self.size)
		p:SetEndSize(55 * self.size)
		p:SetRoll(math.Rand(-1, 1))
		p:SetRollDelta(math.Rand(-1, 1))
		p:SetCollide(true)	
		p:SetVelocity(VectorRand():GetNormal()*220)
		p:SetColor(115, 115, 115)
	end

	for i = 1, math.random(20, 50) do
		local p = self.Emitter:Add("effects/muzzleflash"..math.random(1,4), self.Start)
		p:SetDieTime(math.Rand(0.1, 0.25))
		p:SetStartAlpha(255)
		p:SetEndAlpha(0)
		p:SetStartSize(math.random(50, 150) * self.size)
		p:SetEndSize(50 * self.size)
		p:SetRoll(math.Rand(-50, 50))
		p:SetRollDelta(math.Rand(-10, 10))
		p:SetCollide(true)
		p:SetVelocity(VectorRand():GetNormal() * math.random(25, 75) * self.size)
		p:SetColor(255, 150, 0)
	end

	for i = 1, math.random(40, 70) do
		local vec = VectorRand():GetNormal()
		vec.z = 0
		local pos = (self.Start + vec * 5)
		local p = self.Emitter:Add("sprites/orangeflare1", self.Start + vec * 10)
		p:SetDieTime(math.Rand(2, 3))
		p:SetStartAlpha(255)
		p:SetEndAlpha(0)
		p:SetStartSize(15)
		p:SetEndSize(3)
		p:SetVelocity(((pos - self.Start):GetNormal() * math.random(200, 350)) + Vector(0, 0, math.random(50, 300)) * self.size)
		p:SetGravity( Vector( 0, 0, -1750 ) );
		p:SetColor(255, 255, 255)
		p:SetCollide(true)
	end

	self.Emitter:Finish()
end

function EFFECT:Think()
	return false
end