include("shared.lua")

function ENT:Draw()
    local ply = LocalPlayer()
    local isAdmin = ply:IsUserGroup("superadmin")
    if SAM then
        isAdmin = ply:HasPermission("manage_spawns") or ply:IsSuperAdmin()
    end
    if IVO_SAM then
        isAdmin = IVO_SAM.HasPermission(ply, "manage_spawns") or ply:IsSuperAdmin()
    end

    local adminEyes = false
    local cv = GetConVar("ivan_spawns_admineyes")
    if cv then adminEyes = cv:GetBool() end

    if not self:GetIsInvisible() or (isAdmin and adminEyes) then
        self:DrawModel()
        
        local shouldDrawName = self:GetShowName()
        if isAdmin and adminEyes then shouldDrawName = true end
        
        if shouldDrawName and self:GetSpawnName() ~= "" then
            local pos = self:GetPos() + Vector(0, 0, 15)
            local ang = LocalPlayer():EyeAngles()
            ang:RotateAroundAxis(ang:Forward(), 90)
            ang:RotateAroundAxis(ang:Right(), 90)

            cam.Start3D2D(pos, ang, 0.1)
                surface.SetFont("Ivan_UI_Title")
                local tw, th = surface.GetTextSize(self:GetSpawnName())
                draw.RoundedBox(4, -(tw/2) - 5, -(th/2) - 5, tw + 10, th + 10, Color(0, 0, 0, 200))
                draw.SimpleText(self:GetSpawnName(), "Ivan_UI_Title", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end
end