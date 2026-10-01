include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local distSqr = ply:GetPos():DistToSqr(self:GetPos())
    if distSqr > 90000 then return end -- 300 units
    
    local fadeAlpha = 1 - math.Clamp((distSqr - 40000) / 50000, 0, 1)
    
    local pos = self:GetPos() + self:GetUp() * 55
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    
    local pulse = math.abs(math.sin(CurTime() * 1.5))
    local baseAlpha = (180 + 75 * pulse) * fadeAlpha
    
    cam.Start3D2D(pos, ang, 0.05)
        local pw, ph = 280, 80
        local cx, cy = -pw/2, -ph/2
        
        -- Background
        draw.NoTexture()
        surface.SetDrawColor(5, 5, 10, 180 * fadeAlpha)
        local bg = {
            {x = cx, y = cy},
            {x = cx + pw, y = cy},
            {x = cx + pw, y = cy + ph - 12},
            {x = cx + pw - 12, y = cy + ph},
            {x = cx, y = cy + ph}
        }
        surface.DrawPoly(bg)
        
        -- Scanlines
        surface.SetDrawColor(190, 180, 190, 6 * fadeAlpha)
        for k = 2, ph - 2, 4 do
            surface.DrawLine(cx, cy + k, cx + pw, cy + k)
        end
        
        -- Outline
        surface.SetDrawColor(0, 150, 255, 30 * fadeAlpha)
        surface.DrawLine(cx, cy, cx + pw, cy)
        surface.DrawLine(cx + pw, cy, cx + pw, cy + ph - 12)
        surface.DrawLine(cx + pw, cy + ph - 12, cx + pw - 12, cy + ph)
        surface.DrawLine(cx + pw - 12, cy + ph, cx, cy + ph)
        surface.DrawLine(cx, cy + ph, cx, cy)
        
        -- Corner accents
        surface.SetDrawColor(0, 150, 255, baseAlpha)
        surface.DrawRect(cx, cy, 8, 2)
        surface.DrawRect(cx, cy, 2, 8)
        surface.DrawRect(cx + pw - 8, cy, 8, 2)
        surface.DrawRect(cx + pw, cy, -2, 8)
        
        -- Top accent line
        surface.SetDrawColor(0, 150, 255, baseAlpha)
        surface.DrawLine(cx + 10, cy, cx + pw - 10, cy)
        
        -- Text
        draw.SimpleText("SISTEMA TÁCTICO", "SW_InvShop_BigTitle", 0, -8, Color(0, 150, 255, baseAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("[ E ]  DESPLIEGUE", "SW_InvShop_Aurebesh_Medium", 0, 18, Color(255, 255, 255, baseAlpha * 0.8), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
