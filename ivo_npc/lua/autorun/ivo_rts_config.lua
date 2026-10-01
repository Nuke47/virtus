if SERVER then AddCSLuaFile() end

IVO_RTS = IVO_RTS or {}
IVO_RTS.Config = IVO_RTS.Config or {}

-- Límite máximo de población
IVO_RTS.Config.MaxPopulation = 50

-- Multiplicador de dinero DarkRP al destruir unidades
IVO_RTS.Config.DarkRPRewardMultiplier = 50

-- Opciones de despliegue del menú RTS
-- Las cañoneras y AATs tienen cooldowns en segundos
IVO_RTS.Config.DeployOptions = {
    { category = "CIS", name = "Cañonera HMP", isCustomGunship = true, cooldown = 60, desc = "Despliega una cañonera personalizable (Máx 25 unidades)" },
    { category = "CIS", name = "AAT Hover Tank", class = "lvs_fakehover_aat", cost = 10, cooldown = 120, desc = "Tanque de Asalto Blindado (Gratis)", isAAT = true },
    { category = "Trandoshanos", name = "Cápsula Trandoshana", class = "npc_trando_elite", cost = 2, cooldown = 30, desc = "Despliegue de Mercenario" },
    { category = "Piratas", name = "Pirata Weequay", class = "npc_pirate_soldier", cost = 2, cooldown = 30, desc = "Despliegue de Pirata" },
    { category = "Entrenamientos", name = "Clon de Entrenamiento", class = "npc_clone_train", cost = 1, cooldown = 10, desc = "Muñeco de Prácticas" },
}

-- Costos en Game Master Points (GMP) de cada tipo de infantería
IVO_RTS.Config.UnitCostsGMP = {
    npc_droid_b1 = 0,
    npc_droid_b2 = 5,
    npc_droid_bx = 10,
    npc_droid_droideka = 100,
    npc_trando_elite = 8,
    npc_pirate_soldier = 3,
    npc_clone_train = 1
}

-- Definición de unidades disponibles para cargar en la cañonera
IVO_RTS.Config.GunshipUnits = {
    { category = "CIS", class = "npc_droid_b1", name = "B1 Battledroid", desc = "Infantería Ligera", icon = "B1" },
    { category = "CIS", class = "npc_droid_b2", name = "B2 Superdroid", desc = "Infantería Pesada", icon = "B2" },
    { category = "CIS", class = "npc_droid_bx", name = "BX Commando", desc = "Fuerza Especial", icon = "BX" },
    { category = "CIS", class = "npc_droid_droideka", name = "Droideka", desc = "Artillería", icon = "DKA" },
    { category = "Trandoshanos", class = "npc_trando_elite", name = "Élite", desc = "Mercenario", icon = "TRN" },
    { category = "Piratas", class = "npc_pirate_soldier", name = "Weequay", desc = "Pirata Básico", icon = "PIR" },
    { category = "Entrenamientos", class = "npc_clone_train", name = "Clon Dummy", desc = "Prácticas", icon = "DUM" }
}

IVO_RTS.Config.GunshipCategories = { "CIS", "Trandoshanos", "Piratas", "Entrenamientos" }

IVO_RTS.Config.Categories = { "CIS", "Trandoshanos", "Piratas", "Entrenamientos" }

function IVO_RTS.GetUnitConfig(class)
    for _, opt in ipairs(IVO_RTS.Config.DeployOptions) do
        if opt.class == class then return opt end
    end
    return nil
end
