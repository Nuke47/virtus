ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Terminal de Arresto 65th"
ENT.Category = "Ivo Datapad"
ENT.Spawnable = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "IsProcessing")
end
