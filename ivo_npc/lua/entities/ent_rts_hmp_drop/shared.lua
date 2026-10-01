ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "HMP Gunship Drop"
ENT.Author = "IVO"
ENT.Category = "IVO RTS"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "ETA")
    self:NetworkVar("String", 0, "PayloadClass")
end
