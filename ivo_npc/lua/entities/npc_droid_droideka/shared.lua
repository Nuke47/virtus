ENT.Base = "npc_droid_base"
ENT.Type = "nextbot"
ENT.PrintName = "Droideka"
ENT.Spawnable = true
ENT.IsDroidNPC = true
ENT.Category = "Star Wars"

list.Set("NPC", "npc_droid_droideka", {
    Name     = "Droideka (Destructor)",
    Class    = "npc_droid_droideka",
    Category = "Star Wars",
})

ENT.DroidConfig = {
    Model        = "models/crossline/player/droideka/cl_droideka.mdl",
    Health       = 500, -- Mucha más vida por defecto (blindaje pesado)
    
    HasShield      = true,
    ShieldHealth   = 1000, -- Capacidad del escudo (aguanta mucho)
    ShieldRecharge = 8.0,  -- Tarda 8 segundos en regenerarse tras romperse
    
    -- Ajustes exclusivos de Droideka
    NoExternalWeapon = true,
    WeaponOffsets = {
        -- Brazo Izquierdo (2 cañones gemelos)
        {
            Vector(35, 27, 35), -- Superior
            Vector(35, 23, 32), -- Inferior (un poco más abajo)
        },
        -- Brazo Derecho (2 cañones gemelos)
        {
            Vector(35, -27, 35), -- Superior
            Vector(35, -23, 32), -- Inferior (un poco más abajo)
        }
    },
    
    CustomSequenceIdle = "idle",
    CustomSequenceWalk = "walk",
    CustomSequenceRun  = "roll",
    CustomSequenceRush = "roll",
    
    SoundWeapon = "droideka/disparos.wav",
    SoundRoll   = "droideka/rodando.wav",
    SoundDeploy = "droideka/armado.wav",

    WeaponClass  = "tfa_sw_blaster_e5_upgrade", -- Usamos stats base del bláster común pero...
    
    DetectRadius = 1800,
    FireRange    = 1000,

    BaseSpread       = 0.08,
    MaxSpread        = 0.18,
    AccurateFraction = 0.5,

    FireRateMult = 1.2, -- Aún más lento (cadencia más baja)
    DamageMult   = 1.5, -- Daño pesado

    WalkSpeed = 60,   -- Desplegado camina muy lento
    RunSpeed  = 550,  -- Rodando es MUY rápido
    RushSpeed = 650,

    RepathInterval = 0.3,
    LookAhead      = 300,
    ReactionTime   = 0.2,
    
    WalkDistanceFrac = 0.8, -- Cuando esté a 800 unidades de ti, se desplegará y avanzará lento disparando
    KeepDistance     = 450, -- Si se acerca a 450 unidades, se frena completamente para no chocarte
    NeverHold = true,       -- Nunca se frena del todo, sigue avanzando lentamente hacia ti (hasta llegar a 450)
    
    ExplodesOnDeath = true, -- Pequeño chispazo al morir
    
    FootsetType = "droideka",
}
