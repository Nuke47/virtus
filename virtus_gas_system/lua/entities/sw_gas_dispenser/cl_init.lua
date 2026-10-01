include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local dist = LocalPlayer():GetPos():DistToSqr(self:GetPos())
    if dist > 200000 then return end -- Solo dibujar si esta cerca

    local pos = self:GetPos() + self:GetUp() * 15 + self:GetForward() * 3
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)

    cam.Start3D2D(pos, ang, 0.08)
        draw.SimpleText("RECARGA DE GAS", "HUDMundoTitle", 0, 0, Color(46, 204, 113), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Presiona [E] para recargar", "HUDMundoJob", 0, 32, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
