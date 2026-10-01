ENT.Base = "npc_droid_base"
ENT.Type = "nextbot"
ENT.IsPirateNPC = true
ENT.IsDroidNPC = false -- Not a droid

ENT.Spawnable = false
ENT.PrintName = "Pirate Base"
ENT.Category = "Star Wars - Pirates"

ENT.PirateConfig = {
    Health       = 100,
    WeaponClass  = "tfa_sw_blaster_e5_upgrade",
    WeaponModel  = "models/kuro/sw_battlefront/weapons/e5_blaster.mdl",
    VoiceType    = "pirate",
    FootsetType  = "human",
}

function ENT:GetDefaultPirateConfig()
    return {
        Health       = 100,
        DetectRadius = 1655,
        FireRange    = 1200,
        BaseSpread       = 0.05,
        MaxSpread        = 0.18,
        AccurateFraction = 0.5,
        FireRateMult = 1.0,
        DamageMult   = 1.0,
        WalkSpeed    = 80,
        RunSpeed     = 180,
        RushSpeed    = 220,
        RepathInterval = 0.3,
        LookAhead      = 300,
        GoalTolerance  = 20,
        SquadRadius = 700,
        SquadMin    = 2,
        RetargetInterval = 4,
        ReactionTime = 0.4,
    }
end
