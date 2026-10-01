AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/lordtrilobite/starwars/isd/imp_console_large01.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end
end

function ENT:AcceptInput(name, activator, caller)
    if name == "Use" and IsValid(activator) and activator:IsPlayer() then
        if not IvoFly.Zones or #IvoFly.Zones == 0 then
            activator:ChatPrint("[Ivo Fly] No hay plataformas de aterrizaje seteadas.")
            return
        end
        
        net.Start("IvoFly_OpenMenu")
        net.Send(activator)
    end
end
