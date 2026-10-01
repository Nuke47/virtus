AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/vendor/pm_protocol_vendor.mdl")
    self:SetSkin(6)
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:SetNPCState(NPC_STATE_SCRIPT)
    self:SetSolid(SOLID_BBOX)
    self:CapabilitiesAdd(CAP_ANIMATEDFACE + CAP_TURN_HEAD)
    self:SetUseType(SIMPLE_USE)
    
    self:DropToFloor()
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

function ENT:Use(activator, caller)
    if IsValid(activator) and activator:IsPlayer() then
        print("E PRESSED ON TIENDA BY", activator)
        -- 1. Sincronizamos datos
        if SW_InvShop and SW_InvShop.SyncPlayerData then
            SW_InvShop.SyncPlayerData(activator)
        end
        
        -- 2. Abrimos la tienda
        net.Start("SW_OpenShopMenu")
        net.WriteEntity(self)
        net.Send(activator)
    end
end