include("shared.lua")

function ENT:Draw()
	self:DrawModel()
	
	local pos = self:GetPos() + Vector(0, 0, 40)
	local ang = LocalPlayer():EyeAngles()
	ang:RotateAroundAxis(ang:Forward(), 90)
	ang:RotateAroundAxis(ang:Right(), 90)
	
	if LocalPlayer():GetPos():DistToSqr(self:GetPos()) < 40000 then
		cam.Start3D2D(pos, ang, 0.1)
			draw.SimpleTextOutlined("Lightsaber Workbench", "DermaLarge", 0, 0, Color(255, 200, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
			draw.SimpleTextOutlined("Presiona E para usar", "DermaDefault", 0, 25, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
		cam.End3D2D()
	end
end
