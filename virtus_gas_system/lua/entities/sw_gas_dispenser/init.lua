AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_combine/health_charger001.mdl")
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
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    -- Evitar spam
    if (self.NextUse or 0) > CurTime() then return end
    self.NextUse = CurTime() + 1.5

    local wep = activator:GetActiveWeapon()
    if not IsValid(wep) or not wep.IsTFAWeapon then
        activator:ChatPrint("[Gas] Necesitas tener un arma de blaster en las manos para recargar su gas.")
        return
    end

    local gas = wep:GetNW2Float("SW_GasLevel", 100)
    if gas >= 100 then
        activator:ChatPrint("[Gas] El cartucho de tu arma actual ya esta al 100%.")
        return
    end

    wep:SetNW2Float("SW_GasLevel", 100)
    self:EmitSound("items/medshot4.wav", 65, 100, 1)
    activator:ChatPrint("[Gas] Cartucho de gas Tibanna recargado exitosamente.")
end
