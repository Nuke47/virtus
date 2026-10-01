include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos() + Vector(0, 0, 40)
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)

    if LocalPlayer():GetPos():DistToSqr(self:GetPos()) < 100000 then
        cam.Start3D2D(pos, ang, 0.1)
            draw.SimpleText("CONSOLA DE CIUDADELA", "DermaLarge", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Presiona [E] para interactuar", "DermaDefault", 0, 30, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end

