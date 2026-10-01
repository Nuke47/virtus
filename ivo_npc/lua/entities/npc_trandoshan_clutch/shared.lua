ENT.Base = "npc_pirate_base"
ENT.Type = "nextbot"
ENT.IsPirateNPC = true
ENT.IsDroidNPC = false

ENT.Spawnable = true
ENT.PrintName = "Trandoshano (Clutch)"
ENT.Category = "Star Wars - Trandoshanos"

ENT.PirateConfig = {
    Model = "models/clutch/pm_trandoshan_clutch.mdl",
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

list.Set("NPC", "npc_trandoshan_clutch", {
    Name     = "Trandoshano (Clutch)",
    Class    = "npc_trandoshan_clutch",
    Category = "Star Wars - Trandoshanos",
})
