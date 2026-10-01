AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_c17/Lockers001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        -- Give it a heavy downward push
        phys:SetVelocity(Vector(0, 0, -1500))
    end
end

local function SpawnDroids(self)
    local count = self.DroidCount or 1
    local cls = self.DroidClass or "npc_droid_b1"
    local owner = self.CommanderOwner
    local cost = self.CostPerDroid or 1

    local origin = self:GetPos()

    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local spawnPos = origin + Vector(math.cos(angle) * 100, math.sin(angle) * 100, 10)

        local droid = ents.Create(cls)
        if IsValid(droid) then
            droid:SetPos(spawnPos)
            droid:SetAngles(Angle(0, math.deg(angle), 0))
            droid:Spawn()
            droid:Activate()

            if droid.SetAI then
                droid:SetAI(true)
            end
            
            if owner and owner:IsValid() then
                -- Assign RTS metadata
                droid:SetNWEntity("CommanderOwner", owner)
                droid.CommanderOwnerRaw = owner
                droid.Cost = cost
                droid.IsRTSUnit = true
            end
        end
    end
end

function ENT:PhysicsCollide(data, phys)
    if self.HasLanded then return end
    
    -- Only trigger on hard hits or hitting the world
    if data.Speed > 100 then
        self.HasLanded = true
        
        -- Effects
        self:EmitSound("physics/metal/metal_box_break1.wav", 100, 100)
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        util.Effect("Explosion", effectdata) -- A bit dramatic, but gets the point across
        
        -- Spawn Droids
        SpawnDroids(self)

        -- Remove the pod
        SafeRemoveEntity(self)
    end
end
