AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    -- Puedes cambiar este modelo por el de un Pyke, Trandoshano, Mercenario, etc.
    self:SetModel("models/npc_blue_pvt/npc_droid_b1_pilot_pvt_h.mdl") 
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:SetNPCState(NPC_STATE_SCRIPT)
    self:SetSolid(SOLID_BBOX)
    self:CapabilitiesAdd(CAP_ANIMATEDFACE + CAP_TURN_HEAD)
    self:SetUseType(SIMPLE_USE)
    self:SetMaxHealth(500)
    self:SetHealth(500)
    self:DropToFloor()
end

function ENT:AcceptInput(name, activator, caller)
    if name == "Use" and IsValid(activator) and activator:IsPlayer() then
        -- Anti-spam (1 segundo)
        if (self.NextUse or 0) > CurTime() then return end
        self.NextUse = CurTime() + 1
        
        -- Abrir menú de contrabando
        net.Start("SW_OpenBlackMarketMenu")
        net.WriteEntity(self)
        net.Send(activator)
    end
end