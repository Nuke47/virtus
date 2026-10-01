include("shared.lua")

local cv_debug = GetConVar("ivo_droid_debug")
if not cv_debug then
    cv_debug = CreateConVar("ivo_droid_debug", "0", FCVAR_ARCHIVE, "Enable droid debug visualization")
end

function ENT:Draw()
    self:DrawModel()

    if cv_debug and cv_debug:GetInt() ~= 1 then return end
    
    local dev = GetConVar("developer")
    if not dev or dev:GetInt() < 1 then return end

    -- Draw proximity radius (90 units)
    local pos = self:GetPos() + Vector(0, 0, 50)
    render.DrawWireframeSphere(self:GetPos(), 90, 16, 16, Color(255, 0, 0), true)

    -- Draw FOV (~145 degrees -> 72.5 degrees each side)
    local forward = self:GetForward()
    local up = self:GetUp()

    local angleLeft = forward:Angle()
    angleLeft:RotateAroundAxis(up, 72.5)
    
    local angleRight = forward:Angle()
    angleRight:RotateAroundAxis(up, -72.5)

    render.SetColorMaterial()
    render.DrawLine(pos, pos + angleLeft:Forward() * 300, Color(255, 255, 0), false)
    render.DrawLine(pos, pos + angleRight:Forward() * 300, Color(255, 255, 0), false)
end
