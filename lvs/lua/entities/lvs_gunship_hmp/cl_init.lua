include("shared.lua")

function ENT:OnSpawn()
	self:RegisterTrail( Vector(-306.32,-529.84,149.92), 0, 20, 2, 1000, 150 )
	self:RegisterTrail( Vector(-306.32,529.84,149.92), 0, 20, 2, 1000, 150 )
	self:RegisterTrail( Vector(-314.74,-474.83,234.39), 0, 20, 2, 1000, 150 )
	self:RegisterTrail( Vector(-314.74,474.83,234.39), 0, 20, 2, 1000, 150 )
end

function ENT:OnFrame()
end

ENT.EngineGlow = Material( "sprites/light_glow02_add" )
ENT.EngineFXColor = Color(255, 192, 0)
ENT.EngineFxPos = {
	--left
	Vector(-593,311.06,238.35),
	Vector(-597.54,305.85,238.09),
	Vector(-601.49,300.42,237.94),
	Vector(-607.29,295.7,238.21),
	Vector(-610.4,289.49,238.15),
	Vector(-614.91,284.03,238.38),
	Vector(-618.13,277.97,238.14),
	Vector(-622.7,272.94,238.44),
	Vector(-627.85,267.1,238.71),
	Vector(-631.05,261.81,238.38),
	Vector(-634.33,255.62,238.26),
	Vector(-637.66,249.51,238.26),
	Vector(-643.17,244.69,238.61),
	Vector(-646.48,237.98,238.58),
	Vector(-649.64,231.77,238.5),
	Vector(-652.27,225.64,238.41),
	Vector(-657.42,220.29,238.79),
	Vector(-659.51,213.81,238.67),
	Vector(-662.24,207.18,238.74),
	Vector(-664.73,200.6,238.56),
	Vector(-669.11,194.78,238.86),
	Vector(-671.12,188.14,238.84),
	Vector(-675.44,182.48,239.09),
	Vector(-677.48,175.8,239.05),
	Vector(-679.69,169.06,238.96),
	Vector(-681.83,162.54,238.87),
	Vector(-683.76,155.7,238.88),
	Vector(-687.69,149.68,239.16),
	Vector(-689.48,142.85,239.12),
	Vector(-691.1,136.2,239.11),
	Vector(-692.81,129.32,239.17),
	Vector(-694.47,122.47,239.13),
	Vector(-695.87,115.78,239.2),
	Vector(-697.42,108.81,239.11),
	Vector(-700.06,102.45,239.34),
	Vector(-701.45,95.67,239.25),
	Vector(-702.79,88.5,239.17),
	Vector(-703.67,81.94,239.08),
	Vector(-704.7,74.91,239.38),
	Vector(-622.7,272.94,238.44),
	--right
	Vector(-593,-311.06,238.35),
	Vector(-597.54,-305.85,238.09),
	Vector(-601.49,-300.42,237.94),
	Vector(-607.29,-295.7,238.21),
	Vector(-610.4,-289.49,238.15),
	Vector(-614.91,-284.03,238.38),
	Vector(-618.13,-277.97,238.14),
	Vector(-622.7,-272.94,238.44),
	Vector(-627.85,-267.1,238.71),
	Vector(-631.05,-261.81,238.38),
	Vector(-634.33,-255.62,238.26),
	Vector(-637.66,-249.51,238.26),
	Vector(-643.17,-244.69,238.61),
	Vector(-646.48,-237.98,238.58),
	Vector(-649.64,-231.77,238.5),
	Vector(-652.27,-225.64,238.41),
	Vector(-657.42,-220.29,238.79),
	Vector(-659.51,-213.81,238.67),
	Vector(-662.24,-207.18,238.74),
	Vector(-664.73,-200.6,238.56),
	Vector(-669.11,-194.78,238.86),
	Vector(-671.12,-188.14,238.84),
	Vector(-675.44,-182.48,239.09),
	Vector(-677.48,-175.8,239.05),
	Vector(-679.69,-169.06,238.96),
	Vector(-681.83,-62.54,238.87),
	Vector(-683.76,-155.7,238.88),
	Vector(-687.69,-149.68,239.16),
	Vector(-689.48,-142.85,239.12),
	Vector(-691.1,-136.2,239.11),
	Vector(-692.81,-129.32,239.17),
	Vector(-694.47,-122.47,239.13),
	Vector(-695.87,-115.78,239.2),
	Vector(-697.42,-108.81,239.11),
	Vector(-700.06,-102.45,239.34),
	Vector(-701.45,-95.67,239.25),
	Vector(-702.79,-88.5,239.17),
	Vector(-703.67,-81.94,239.08),
	Vector(-704.7,-74.91,239.38),
	Vector(-622.7,-272.94,238.44),
	Vector(-681.36,-159.23,238.58),

}

function ENT:PostDrawTranslucent()
	if not self:GetEngineActive() then return end

	local Size = 25 + self:GetThrottle() * 90 + self:GetBoost() * 0.9

	render.SetMaterial( self.EngineGlow )

	for _, v in pairs( self.EngineFxPos ) do
		local pos = self:LocalToWorld( v )
		render.DrawSprite( pos, Size, Size, self.EngineFXColor )

	end
end


function ENT:OnStartBoost()
	self:EmitSound( "hmp/throttlepunch_6.mp3", 85 )
end

