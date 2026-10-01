include("shared.lua")

function ENT:Initialize()
    self.CurrentHeadYaw = 0
    self.CurrentHeadPitch = 0
end

function ENT:Think()
    self.CurrentHeadYaw = self.CurrentHeadYaw or 0
    self.CurrentHeadPitch = self.CurrentHeadPitch or 0

    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    if _G.SW_Shop3D_Active then
        self.CurrentHeadYaw = Lerp(FrameTime() * 3, self.CurrentHeadYaw, 0)
        self.CurrentHeadPitch = Lerp(FrameTime() * 3, self.CurrentHeadPitch, 0)
    else
        local dist = self:GetPos():DistToSqr(ply:GetPos())
        if dist < 60000 then
            local headBone = self:LookupBone("ValveBiped.Bip01_Head1")
            local headPos = headBone and self:GetBonePosition(headBone) or (self:GetPos() + Vector(0, 0, 65))
            
            self:SetEyeTarget(ply:EyePos())
            
            local localAng = self:WorldToLocalAngles((ply:EyePos() - headPos):Angle())
            
            -- El yaw local en los modelos suele estar invertido o ajustado, dependemos de si está de frente
            local targetYaw = math.Clamp(localAng.y, -70, 70)
            local targetPitch = math.Clamp(localAng.p, -40, 40)
            
            -- Si el jugador está detrás del NPC, no torcer el cuello
            if math.abs(localAng.y) > 90 then
                targetYaw = 0
                targetPitch = 0
            end
            
            self.CurrentHeadYaw = Lerp(FrameTime() * 5, self.CurrentHeadYaw, targetYaw)
            self.CurrentHeadPitch = Lerp(FrameTime() * 5, self.CurrentHeadPitch, targetPitch)
        else
            self.CurrentHeadYaw = Lerp(FrameTime() * 3, self.CurrentHeadYaw, 0)
            self.CurrentHeadPitch = Lerp(FrameTime() * 3, self.CurrentHeadPitch, 0)
            self:SetEyeTarget(self:GetPos() + self:GetForward() * 100 + Vector(0,0,65))
        end
    end
    
    self:SetPoseParameter("head_yaw", self.CurrentHeadYaw)
    self:SetPoseParameter("head_pitch", self.CurrentHeadPitch)
    self:SetPoseParameter("aim_yaw", self.CurrentHeadYaw)
    self:SetPoseParameter("aim_pitch", self.CurrentHeadPitch)
    
    self:InvalidateBoneCache()
    self:NextThink(CurTime())
    return true
end

function ENT:Draw()
    self:DrawModel()
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if _G.SW_Shop3D_Active then return end
    
    -- Solo mostrar si está cerca
    local dist = ply:GetPos():DistToSqr(self:GetPos())
    if dist > 35000 then return end
    
    -- Tolerancia para mirar al NPC (por si el Hitbox de Garry's Mod falla)
    local isLooking = false
    local tr = ply:GetEyeTrace()
    if tr.Entity == self then 
        isLooking = true 
    else
        -- Comprobar si está mirando en su dirección general
        local dirToNpc = (self:GetPos() + Vector(0,0,40) - ply:EyePos()):GetNormalized()
        local aimDir = ply:GetAimVector()
        if aimDir:Dot(dirToNpc) > 0.95 then
            isLooking = true
        end
    end
    
    if not isLooking then return end
    
    local headBone = self:LookupBone("ValveBiped.Bip01_Head1")
    local pos = headBone and self:GetBonePosition(headBone) or (self:GetPos() + Vector(0, 0, 75))
    pos = pos + Vector(0, 0, 15) -- Ligeramente por encima de la cabeza
    
    local ang = ply:EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.06)
        surface.SetFont("HUDMundoTitle")
        local textW = surface.GetTextSize("[E] INGRESAR")
        
        -- Líneas de acento
        surface.SetDrawColor(0, 150, 255, 200)
        surface.DrawLine(-textW/2 - 20, 0, -textW/2 - 5, 0)
        surface.DrawLine(textW/2 + 5, 0, textW/2 + 20, 0)
        
        draw.SimpleText("VENDEDOR", "HUDMundoJob", 0, -22, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("[E] INGRESAR", "HUDMundoTitle", 0, 2, Color(255, 170, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end