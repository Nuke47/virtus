include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    -- Texto flotante sobre la terminal
    local pos = self:GetPos() + Vector(0, 0, 65)
    local ang = self:GetAngles()
    
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    
    if LocalPlayer():GetPos():DistToSqr(pos) < 250000 then -- Sólo renderizar si estás cerca
        cam.Start3D2D(pos, ang, 0.1)
            draw.SimpleText("TERMINAL DE RECOMPENSAS", "DermaLarge", 0, 0, Color(0, 180, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Pulsa [E] para acceder", "DermaDefaultBold", 0, 30, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end