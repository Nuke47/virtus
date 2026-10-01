AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("IvoCitadel_OpenMenu")

function ENT:Initialize()
    self:SetModel("models/props_lab/reciever01b.mdl") -- Cambia esto al modelo de consola que desees
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if IvoCitadel.Config.HasPermission(activator) then
        net.Start("IvoCitadel_OpenMenu")
        net.WriteString(self:GetNWString("CitadelName", "Ciudadela 1"))
        net.Send(activator)
    else
        activator:ChatPrint("No tienes permiso para acceder a esta consola.")
    end
end

