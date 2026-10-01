-- ============================================================
--  SW:RP Grappling Hook - init.lua  (SERVER)
-- ============================================================
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function SWEP:RemoveProjectile()
    if IsValid(self.HookProjectile) then self.HookProjectile:Remove() end
    self.HookProjectile = nil
    self.HookInFlight   = false
end

function SWEP:FireHook()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    self:RetractHook(true)

    local cfg = self.GrappleConfig
    local eyePos = owner:EyePos()
    local aimDir = owner:GetAimVector()

    local proj = ents.Create("prop_physics")
    if not IsValid(proj) then return end

    proj:SetModel(cfg.HookModel)
    proj:SetPos(eyePos + aimDir * 24)
    proj:SetAngles(aimDir:Angle())
    proj:Spawn()
    proj:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    proj:DrawShadow(false)
    proj:SetColor(Color(200, 160, 80))

    local phys = proj:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetMass(1)
        phys:EnableGravity(true)
        phys:EnableDrag(false)
        phys:SetVelocity(aimDir * cfg.GrappleSpeed)
    end

    proj:AddCallback("PhysicsCollide", function(ent, data)
        if not IsValid(self) or self.HookDeployed then return end
        self:AnchorHook(data.HitPos, data.HitEntity)
    end)

    self.HookProjectile = proj
    self.HookInFlight   = true
    self:SetHookWorldPos(eyePos + aimDir * 24)
    self:SetRopeVisible(true)

    timer.Simple(3, function()
        if IsValid(self) and self.HookInFlight then self:RetractHook() end
    end)
end

function SWEP:AnchorHook(hitPos, hitEnt)
    local owner = self:GetOwner()
    if not IsValid(owner) then self:RetractHook(true); return end

    local proj = self.HookProjectile
    if IsValid(proj) then
        proj:SetNoDraw(true)
        local phys = proj:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        proj:SetPos(hitPos)
        if IsValid(hitEnt) and not hitEnt:IsWorld() then
            proj:SetParent(hitEnt)
        end
    end

    self.HookEntity     = proj
    self.HookDeployed   = true
    self.HookInFlight   = false
    local len = math.Clamp((hitPos - owner:GetPos()):Length(), self.GrappleConfig.MinRopeLength, self.GrappleConfig.MaxRopeLength)
    self:SetCurrentRopeLength(len)
    self:SetBreakProgress(0)

    self:SetHookActive(true)
    self:SetHookWorldPos(hitPos)
    self:SetRopeVisible(true)
    owner:EmitSound(self.GrappleConfig.SoundHit, 75, 100)
end

function SWEP:RetractHook(silent)
    self:RemoveProjectile()
    if IsValid(self.HookEntity) then self.HookEntity:Remove() end

    self.HookEntity     = nil
    self.HookDeployed   = false
    self:SetBreakProgress(0)
    self:SetHookActive(false)
    self:SetRopeVisible(false)

    if not silent then
        local owner = self:GetOwner()
        if IsValid(owner) then owner:EmitSound(self.GrappleConfig.SoundDetach, 65, 100) end
    end
end

function SWEP:Think()
    local owner = self:GetOwner()
    if not IsValid(owner) then self:RetractHook(true); return end

    if self.HookInFlight and IsValid(self.HookProjectile) then
        if self.HookProjectile:GetPos():DistToSqr(owner:GetPos()) > (self.GrappleConfig.MaxRopeLength ^ 2) then
            self:RetractHook(true)
            return
        end
        self:SetHookWorldPos(self.HookProjectile:GetPos())
        return
    end

    if not self.HookDeployed then return end

    if not IsValid(self.HookEntity) then
        self:RetractHook(true)
        return
    end
    
    self:SetHookWorldPos(self.HookEntity:GetPos())

    -- Impulso
    if owner:KeyDown(IN_USE) then
        local aim = owner:GetAimVector()
        owner:SetVelocity((aim * 800 + Vector(0, 0, 300)) - owner:GetVelocity())
        owner:EmitSound("physics/metal/metal_box_impact_soft3.wav", 75, 120)
        self:RetractHook()
        return
    end

    local cfg = self.GrappleConfig
    
    -- Subir: Se detecta con ENTER o con Clic Izquierdo (IN_ATTACK)
    local inKey  = owner.GrappleReelingIn or owner:KeyDown(IN_ATTACK) 
    
    -- Bajar: Se detecta con Clic Derecho
    local outKey = owner:KeyDown(IN_ATTACK2)

    local ownerPos = owner:GetPos() + Vector(0, 0, 36)
    local anchorPos = self:GetHookWorldPos()
    local dist = (anchorPos ~= vector_origin) and (anchorPos - ownerPos):Length() or 0

    local reelSpeed = 0
    if inKey and not outKey then
        reelSpeed = -cfg.ReelSpeed
    elseif outKey and not inKey then
        reelSpeed = cfg.ReelSpeed
    end

    if reelSpeed ~= 0 then
        local current = self:GetCurrentRopeLength()
        local newLen = current + reelSpeed * FrameTime()
        if reelSpeed < 0 and dist > 0 then
            newLen = math.max(newLen, dist - 150)
        end
        self:SetCurrentRopeLength(math.Clamp(newLen, cfg.MinRopeLength, cfg.MaxRopeLength))
    end
    
    if anchorPos ~= vector_origin then
        local toAnchor = anchorPos - ownerPos
        local ropeLen = self:GetCurrentRopeLength()

        if dist > ropeLen then
            local diff = dist - ropeLen
            local dirToAnc = toAnchor:GetNormalized()
            
            local curVel = owner:GetVelocity()
            local outwardVel = curVel:Dot(-dirToAnc)
            if outwardVel > 0 then
                owner:SetVelocity(dirToAnc * (outwardVel * 6 * FrameTime()))
            end
            
            self:SetBreakProgress(0) 

            local pull = math.Clamp(diff * 5, 100, cfg.PullForce)
            local gravityComp = (owner:GetGroundEntity() == NULL) and (physenv.GetGravity() * -1 * 0.8) or Vector(0,0,0)
            
            owner:SetVelocity(((dirToAnc * pull) + gravityComp) * FrameTime())
        end
    end
end

function SWEP:OnRemove() self:RetractHook(true) end
function SWEP:Holster() self:RetractHook(true); return true end