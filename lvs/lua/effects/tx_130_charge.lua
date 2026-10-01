local glow = Material("sprites/light_glow02_add")

function EFFECT:Init(data)
	self.Entity = data:GetEntity()
	self.LocalPos = data:GetStart()
	self.DieTime = CurTime() + 0.1
end

function EFFECT:Think()
	return IsValid(self.Entity)
		and CurTime() < self.DieTime
end

function EFFECT:Render()
	if not IsValid(self.Entity) then return end

	local pos = self.Entity:LocalToWorld(
		self.LocalPos
	)

	render.SetMaterial(glow)
	render.DrawSprite(
		pos,
		30,
		30,
		Color(255, 0, 50, 200)
	)
end