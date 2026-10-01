ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Ivan Spawn Point"
ENT.Author = "Ivan"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "Ivan Spawnpoints"

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "SpawnName")
    self:NetworkVar("Bool", 0, "ShowName")
    self:NetworkVar("Bool", 1, "IsInvisible")
end
