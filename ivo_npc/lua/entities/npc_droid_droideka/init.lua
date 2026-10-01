AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
DEFINE_BASECLASS("npc_droid_base")

function ENT:Initialize()
    BaseClass.Initialize(self)
    
    -- El modelo del Droideka es muy ancho y su origen físico suele bugearse con el suelo.
    -- Le forzamos una caja de colisión estándar de NextBot que toca el piso (Z=0).
    self:SetCollisionBounds(Vector(-30, -30, 0), Vector(30, 30, 65))
    
    -- Le decimos al motor de físicas que use la colisión de un NPC grande
    self:SetSolidMask(MASK_NPCSOLID)
    
    -- Previene que se quede atascado en el suelo al aparecer
    self.loco:SetStepHeight(20)
    self:SetPos(self:GetPos() + Vector(0,0,10))
end
