ENT.Base = "npc_pirate_base"
ENT.Type = "nextbot"
ENT.IsPirateNPC = true
ENT.IsDroidNPC = false

ENT.Spawnable = true
ENT.PrintName = "Trandoshano (Hunter)"
ENT.Category = "Star Wars - Trandoshanos"

ENT.PirateConfig = {
    Model = "models/hunter/pm_trandoshan_hunter.mdl",
    Health = 150,
    WeaponClass = "tfa_sw_blaster_e5_upgrade",
    WeaponModel = "models/kuro/sw_battlefront/weapons/e5_blaster.mdl",
    CustomSequenceIdle = "idle_submachinegun",
    CustomSequenceWalk = "walk_ar2",
    CustomSequenceRun  = "run_ar2",
    CustomSequenceRush = "run_ar2",
    BoneManipulations = {},
    CombatBoneManipulations = {}
}

list.Set("NPC", "npc_trandoshan_hunter", {
    Name     = "Trandoshano (Hunter)",
    Class    = "npc_trandoshan_hunter",
    Category = "Star Wars - Trandoshanos",
})
