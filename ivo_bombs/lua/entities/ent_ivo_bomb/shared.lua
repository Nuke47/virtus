--[[
    ivo_bombs - Entidad Bomba (Shared)
    Variables de red compartidas entre servidor y cliente
]]

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName    = "Bomba"
ENT.Author       = "Ivo"
ENT.Category     = "ivo_bombs"
ENT.Spawnable    = true
ENT.AdminSpawnable = true
ENT.RenderGroup  = RENDERGROUP_BOTH

function ENT:SetupDataTables()
    self:NetworkVar("Float",  0, "DetonateTime")
    self:NetworkVar("Int",    0, "Difficulty")       -- 1-4
    self:NetworkVar("Int",    1, "Seed")             -- Semilla para puzzles
    self:NetworkVar("Int",    2, "StrikeCount")
    self:NetworkVar("Int",    3, "ModulesSolved")
    self:NetworkVar("Bool",   0, "Armed")
    self:NetworkVar("Bool",   1, "Defused")
end
