ENT.Base = "npc_droid_base"
ENT.Type = "nextbot"
ENT.IsDroidNPC = true

ENT.Spawnable = true
ENT.PrintName = "Droide BX Francotirador"
ENT.Category = "Star Wars"

-- BX Francotirador: Distinct sniper droid with a jetpack for high ground.
ENT.DroidConfig = {
    ShootSound     = { "npcs/shoots/bx/b_e5bx_1.wav", "npcs/shoots/bx/b_e5bx_2.wav", "npcs/shoots/bx/b_e5bx_3.wav" },
    TracerName     = "effect_sw_laser_red",

    Model        = "models/bx/pm_droid_cis_bx.mdl",
    Health       = 250,

    DetectRadius = 4500,
    FireRange    = 3500,

    BaseSpread       = 0.005,
    MaxSpread        = 0.02,
    AccurateFraction = 0.9,

    FireRateMult = 3.5,
    DamageMult   = 3.0,

    WalkSpeed = 60,
    RunSpeed  = 280,
    RushSpeed = 350,

    RepathInterval = 0.3,
    LookAhead      = 400,
    ReactionTime   = 0.15,

    SquadMin = 99,
    
    WalkDistanceFrac = 0.95,
    KeepDistance     = 800,
    NeverHold        = false,
    
    VoiceType      = "bx",
    FootsetType    = "b1",
    UseAR2HoldType = true,
}

list.Set("NPC", "npc_droid_bx_sniper", {
    Name     = "Droide BX Francotirador",
    Class    = "npc_droid_bx_sniper",
    Category = "Star Wars",
})
