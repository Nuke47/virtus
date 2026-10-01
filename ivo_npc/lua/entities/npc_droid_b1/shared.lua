ENT.Base = "npc_droid_base"
ENT.Type = "nextbot"
ENT.IsDroidNPC = true

ENT.Spawnable = false
ENT.PrintName = "Droide B1 (Facil)"
ENT.Category = "Star Wars"

-- B1 — easy: fragile, short-sighted, sloppy aim, slow, dumb pathing.
ENT.DroidConfig = {
    ShootSound     = { "npcs/shoots/b1/b_e5_1.wav", "npcs/shoots/b1/b_e5_2.wav", "npcs/shoots/b1/b_e5_3.wav", "npcs/shoots/b1/b_e5_4.wav", "npcs/shoots/b1/b_e5_5.wav", "npcs/shoots/b1/b_e5_6.wav" },
    TracerName     = "effect_sw_laser_red",

    Model        = "models/aussiwozzi/cgi/b1droids/b1_battledroid_pm.mdl",
    Health       = 80,

    DetectRadius = 1655,
    FireRange    = 900,

    BaseSpread       = 0.01,
    MaxSpread        = 0.05,
    AccurateFraction = 0.85,

    FireRateMult = 1.35,
    DamageMult   = 0.9,

    WalkSpeed = 70,
    RunSpeed  = 150,
    RushSpeed = 180,
    
    WalkDistanceFrac = 1.5,
    NeverHold = true, -- Nunca se detienen a disparar, avanzan como un muro


    RepathInterval = 0.5,
    LookAhead      = 200,
    AlertRadius    = 1500,
    ReactionTime   = 0.5,
    
    VoiceType      = "b1",
    FootsetType    = "b1",
}

list.Set("NPC", "npc_droid_b1", {
    Name     = "Droide B1 (Facil)",
    Class    = "npc_droid_b1",
    Category = "Star Wars",
})

