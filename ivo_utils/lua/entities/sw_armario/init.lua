AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/reizer_props/srsp/sci_fi/armory_02_3/armory_02_3.mdl") 
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then 
        phys:EnableMotion(false)
        phys:Sleep()
    end
end

function ENT:Use(activator, caller)
    if IsValid(activator) and activator:IsPlayer() then
        -- 1. Obligamos al servidor a sincronizar los datos del jugador
        if SW_InvShop and SW_InvShop.SyncPlayerData then
            SW_InvShop.SyncPlayerData(activator)
        end
        
        -- 2. Abrimos el menú
        net.Start("SW_OpenArmarioMenu")
        net.WriteEntity(self)
        net.Send(activator)
    end
end