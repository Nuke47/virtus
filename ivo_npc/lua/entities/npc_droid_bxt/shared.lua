ENT.Base = "npc_droid_base"
ENT.Type = "nextbot"
ENT.IsDroidNPC = true

ENT.Spawnable = false
ENT.PrintName = "Droide BX Entrenamiento"
ENT.Category = "Star Wars"

-- BX — hard: durable commando, long range, very accurate, fast, smart pathing,
-- aggressive rusher.
ENT.DroidConfig = {
    ShootSound     = { "npcs/shoots/bx/b_e5bx_1.wav", "npcs/shoots/bx/b_e5bx_2.wav", "npcs/shoots/bx/b_e5bx_3.wav", "npcs/shoots/bx/b_e5bx_4.wav", "npcs/shoots/bx/b_e5bx_5.wav" },
    TracerName     = "effect_sw_laser_red",

    VoiceType      = "bx",
    FootsetType    = "b1",
    UseAR2HoldType = true,

    Model        = "models/bx_training/pm_droid_cis_bx_training.mdl",   -- swap to a BX model when available
    Health       = 300,

    DetectRadius = 2400,
    FireRange    = 1900,

    BaseSpread       = 0.018,
    MaxSpread        = 0.06,
    AccurateFraction = 0.5,

    FireRateMult = 0.7,
    DamageMult   = 1.25,

    WalkSpeed = 150,
    RunSpeed  = 350,
    RushSpeed = 450,

    RepathInterval = 0.15,
    LookAhead      = 420,
    ReactionTime   = 0.1,

    SquadMin = 2,   -- BX commandos rush even in pairs
    
    WalkDistanceFrac = 0.15,
    NeverHold        = true,
    ZigZagWidth      = 150,
    ZigZagInterval   = 0.8,
    DashChance       = 0.15, -- 15% chance to do a fast ground dash
    JumpChance       = 0.03, -- 3% chance to do a jumping dash (very rare)
}

list.Set("NPC", "npc_droid_bxt", {
    Name     = "Droide BX Entrenamiento",
    Class    = "npc_droid_bxt",
    Category = "Star Wars",
})






