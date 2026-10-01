ENT.Base = "npc_pirate_base"
ENT.Type = "nextbot"
ENT.IsPirateNPC = true
ENT.IsDroidNPC = false

ENT.Spawnable = true
ENT.PrintName = "Pirata (Soldier)"
ENT.Category = "Star Wars - Piratas"

ENT.PirateConfig = {
    Model = "models/player/ohanak_gang/pm_pirate_soldier.mdl",
    Health = 120,
    WeaponClass = "tfa_sw_blaster_e5_upgrade",
    WeaponModel = "models/kuro/sw_battlefront/weapons/e5_blaster.mdl",
    CustomSequenceIdle = "idle_submachinegun",
    CustomSequenceWalk = "walk_ar2",
    CustomSequenceRun  = "run_ar2",
    CustomSequenceRush = "run_ar2",
    BoneManipulations = {},
    CombatBoneManipulations = {}
}

list.Set("NPC", "npc_pirate_soldier", {
    Name     = "Pirata (Soldier)",
    Class    = "npc_pirate_soldier",
    Category = "Star Wars - Piratas",
})
