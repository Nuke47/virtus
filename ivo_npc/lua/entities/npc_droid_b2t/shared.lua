ENT.Base = "npc_droid_base"
ENT.Type = "nextbot"
ENT.IsDroidNPC = true

ENT.Spawnable = false
ENT.PrintName = "Droide B2 Entrenamiento"
ENT.Category = "Star Wars"

-- B2 — medium: tougher, longer range, balanced aim and speed.
ENT.DroidConfig = {
    ShootSound     = { "npcs/shoots/b2/blaster_b2_1.wav", "npcs/shoots/b2/blaster_b2_2.wav", "npcs/shoots/b2/blaster_b2_3.wav", "npcs/shoots/b2/blaster_b2_4.wav", "npcs/shoots/b2/blaster_b2_5.wav" },
    TracerName     = "effect_sw_laser_red",

    VoiceType      = "b2",
    FootsetType    = "b2",

    Model        = "models/aussiwozzi/cgi/b1droids/b2_battledroid_training_pm.mdl",
    Scale        = 1.15,
    Health       = 160,

    DetectRadius = 1900,
    FireRange    = 1300,

    BaseSpread       = 0.045,
    MaxSpread        = 0.13,
    AccurateFraction = 0.5,
    -- Le damos el arma física E-5 igual que el B1
    NoExternalWeapon = false,
    InvisibleWeapon = true,
    WeaponOffsets = {
        -- Esto es relativo al arma invisible. 
        -- X = Adelante, Y = Derecha/Izquierda, Z = Arriba/Abajo del arma
        Vector(-8, 0, 1)
},

    CustomSequenceIdle = "idle_pistol",
    CustomSequenceWalk = "walk_pistol",
    CustomSequenceRun  = "run_pistol",
    CustomSequenceRush = "run_pistol",

    BoneManipulations = {
        ["ValveBiped.Bip01_R_Forearm"] = Angle(0, -90, 0),
        ["ValveBiped.Bip01_R_Hand"]    = Angle(0, 0, 0)
},
    
    CombatBoneManipulations = {
        ["ValveBiped.Bip01_R_Forearm"] = Angle(0, 0, -90),
        ["ValveBiped.Bip01_R_Hand"]    = Angle(0, -90, 0)
},

    FireRateMult = 1.0,
    DamageMult   = 1.0,

    WalkSpeed = 90,
    RunSpeed  = 190,
    RushSpeed = 220,

    RepathInterval = 0.3,
    LookAhead      = 300,
    ReactionTime   = 0.3,
}

list.Set("NPC", "npc_droid_b2t", {
    Name     = "Droide B2 Entrenamiento",
    Class    = "npc_droid_b2t",
    Category = "Star Wars",
})






