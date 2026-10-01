ENT.Type            = "anim"
ENT.Base            = "base_anim"
ENT.PrintName       = "Droide Sonda Imperial"
ENT.Author          = "Antigravity"
ENT.Category        = "Star Wars RP"
ENT.Spawnable       = false
ENT.AdminSpawnable  = false

ENT.RenderGroup     = RENDERGROUP_OPAQUE

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "ProbeOwner")
    self:NetworkVar("Bool",   0, "ProbeActive")
    self:NetworkVar("Bool",   1, "ProbeControlled")
    self:NetworkVar("Bool",   2, "ProbeLinked")
end
