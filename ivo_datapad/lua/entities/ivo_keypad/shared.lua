ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Datapad Keypad"
ENT.Author = "Antigravity"
ENT.Category = "Ivo Datapad"
ENT.Spawnable = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "IsHacked")
    self:NetworkVar("Int", 0, "KeypadType") -- 0 = ID, 1 = PIN
    self:NetworkVar("String", 0, "AccessJobs")
    self:NetworkVar("Int", 2, "AccessLevel")
    self:NetworkVar("Int", 1, "HackDifficulty")
    self:NetworkVar("String", 1, "HackGames")
end
