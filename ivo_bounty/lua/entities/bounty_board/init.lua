AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    -- Usamos un modelo de terminal estándar de Half-Life 2
    self:SetModel("models/props_combine/breenconsole.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:Use(activator, caller)
    if IsValid(caller) and caller:IsPlayer() then
        net.Start("BountySystem_OpenMenu")
        net.WriteEntity(self)
        net.Send(caller)
    end
end