ENT.Base            = "base_entity"
ENT.Type            = "anim"

ENT.PrintName       = "Hatch"
ENT.Author          = "Ivo"
ENT.Information     = ""
ENT.Category        = "[VIRTUS LVS]"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

ENT.RenderGroup = RENDERGROUP_BOTH

ENT.AutomaticFrameAdvance = true

function ENT:Initialize()
    if self.BaseClass and self.BaseClass.Initialize then
        self.BaseClass.Initialize( self )
    end
    
    if SERVER then
        self:SetSkin( 1 )
    end
end

function ENT:Think()
    if self.BaseClass and self.BaseClass.Think then
        self.BaseClass.Think( self )
    end
    
    -- TRUCO ANTI-LAG: 
    -- En el primer frame en el que la puerta existe, verificamos si ya le inyectaron el modelo.
    -- Si es así, forzamos la skin 1 antes de que el servidor intente renderizar la skin 0.
    if SERVER and not self.SkinCorregida then
        self:SetSkin( 1 )
        self.SkinCorregida = true -- Esto hace que solo se ejecute una vez y no consuma recursos
    end
    
    -- Le decimos a la entidad que piense lo más rápido posible para atrapar el cambio de skin
    self:NextThink( CurTime() )
    return true
end