include("shared.lua")

function ENT:Draw()
    self:DrawModel()
end

-- Título holográfico sobre la cabeza del NPC
function ENT:DrawTranslucent()
    local dist = LocalPlayer():GetPos():DistToSqr(self:GetPos())
    if dist > 250000 then return end -- Solo se ve si estás cerca (500 unidades)

    local headBone = self:LookupBone("ValveBiped.Bip01_Head1")
    local pos = headBone and self:GetBonePosition(headBone) or self:GetPos()
    pos = pos + Vector(0, 0, 15)

    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    cam.Start3D2D(pos, ang, 0.08)
        draw.SimpleText("CONTRABANDISTA", "HUDMundoTitle", 0, 0, Color(230, 50, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("< Contacto Ilegal >", "HUDMundoJob", 0, 32, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end