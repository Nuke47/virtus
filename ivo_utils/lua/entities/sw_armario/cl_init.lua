include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 250000 then return end

    local pos = self:GetPos() + self:GetForward() * 15 + Vector(0, 0, 95)
    local ang = EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    if _G.SW_Armario3D_Active then return end
    local tr = LocalPlayer():GetEyeTrace()
    if tr.Entity ~= self then return end
    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.06)
        surface.SetFont("HUDMundoTitle")
        local textW = surface.GetTextSize("[E] INGRESAR")
        surface.SetDrawColor(46, 204, 113, 200)
        surface.DrawLine(-textW/2 - 20, 0, -textW/2 - 5, 0)
        surface.DrawLine(textW/2 + 5, 0, textW/2 + 20, 0)
        draw.SimpleText("ARMARIO PERSONAL", "HUDMundoJob", 0, -22, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("[E] INGRESAR", "HUDMundoTitle", 0, 2, Color(46, 204, 113), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end