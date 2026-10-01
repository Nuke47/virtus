AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    self:SetUseType(SIMPLE_USE)
    self:SetMaterial("models/shiny")
    self:SetColor(Color(0, 150, 255))
    
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
        phys:EnableMotion(false)
    end
    
    if self:GetSpawnName() == "" then
        self:SetSpawnName("Nuevo Spawn")
        self:SetShowName(true)
        self:SetIsInvisible(false)
    end
    
    if not self.SpawnData then
        self.SpawnData = {
            AllowedJobs = {},
            AllowedCategories = {},
            AllowedSteamIDs = {},
            AllowedSAMRanks = {},
            IsPersistent = false
        }
    end
end

util.AddNetworkString("IvanSpawns_OpenMenu")

local function IsAdmin(ply)
    if ply:IsSuperAdmin() then return true end
    if SAM and ply:HasPermission("manage_spawns") then return true end
    if IVO_SAM and IVO_SAM.HasPermission(ply, "manage_spawns") then return true end
    return ply:IsUserGroup("superadmin")
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if activator:GetNWBool("InTutorial") then return end
    
    if IsAdmin(activator) then
        net.Start("IvanSpawns_OpenMenu")
        net.WriteEntity(self)
        net.WriteTable(self.SpawnData)
        net.Send(activator)
    end
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end