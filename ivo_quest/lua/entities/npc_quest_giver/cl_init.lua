include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    -- Si estamos en diálogo, no dibujamos el icono de arriba
    if IVO_QUEST and IVO_QUEST.InDialogue then return end
    
    -- Distancia de dibujo
    if LocalPlayer():GetPos():Distance(self:GetPos()) > 500 then return end
    
    local pos = self:GetPos() + Vector(0, 0, 80)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    cam.Start3D2D(pos, ang, 0.1)
        draw.SimpleText("!", "DermaLarge", 0, 0, Color(255, 200, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Misiones", "DermaDefault", 0, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end