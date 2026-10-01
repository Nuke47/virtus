include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + self:GetForward() * 1.5 + self:GetUp() * 5 + self:GetRight() * -3
    local ang = self:GetAngles()
    
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)

    cam.Start3D2D(pos, ang, 0.1)
        if self:GetIsHacked() then
            draw.SimpleText("ACCESO", "DermaDefaultBold", 0, 0, Color(0, 255, 0), TEXT_ALIGN_CENTER)
            draw.SimpleText("CONCEDIDO", "DermaDefaultBold", 0, 15, Color(0, 255, 0), TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("TERMINAL", "DermaDefaultBold", 0, 0, Color(255, 50, 50), TEXT_ALIGN_CENTER)
            draw.SimpleText("BLOQUEADA", "DermaDefaultBold", 0, 15, Color(255, 50, 50), TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end
