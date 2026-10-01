--[[---------------------------------------------------------------------------
DarkRP custom jobs
---------------------------------------------------------------------------
This file contains your custom jobs.
This file should also contain jobs from DarkRP that you edited.

Note: If you want to edit a default DarkRP job, first disable it in darkrp_config/disabled_defaults.lua
      Once you've done that, copy and paste the job to this file and edit it.

The default jobs can be found here:
https://github.com/FPtje/DarkRP/blob/master/gamemode/config/jobrelated.lua

For examples and explanation please visit this wiki page:
https://darkrp.miraheze.org/wiki/DarkRP:CustomJobFields

Add your custom jobs under the following line:
---------------------------------------------------------------------------]]
-- =========================================================================
-- CATEGORÍAS
-- =========================================================================
local CAT_CT = "Clone Troopers"
local CAT_SH = "Shock Troopers"
local CAT_SU = "Shadow Unit"
local CAT_AM = "Altos Mandos"

-- =========================================================================
-- TABLAS DE DATOS
-- =========================================================================
local jobWeapons = {
    -- Las armas nativas de DarkRP han sido removidas. 
    -- Ahora todos los jobs reciben sus armas iniciales a traves del sistema StarterLoadouts en ivo_utils/sh_config.lua.
}
local jobModels = {

    --CLONE TROOPERS

    ["CT: Soldado"] = {"models/aussiwozzi/cgi/base/trooper.mdl"}, 
    ["CT: Reconocimiento"] = {"models/aussiwozzi/cgi/base/unassigned_arf.mdl"}, 
    ["CT: Asalto"] = {"models/aussiwozzi/cgi/base/tedden/unassigned_med.mdl"}, 
    ["CT: Apoyo"] = {"models/aussiwozzi/cgi/base/unassigned_heavy.mdl", "models/aussiwozzi/cgi/base/unassigned_pilot.mdl"}, 
    ["CT: ARC"] = {"models/aussiwozzi/cgi/base/unassigned_arc.mdl"}, 
    ["CT: Comandante"] = {"models/aussiwozzi/cgi/base/trooper.mdl"}, 
    ["CT: SAR Soldado"] = {"models/aussiwozzi/cgi/base/trooper.mdl"}, 
    ["CT: SAR Reconocimiento"] = {"models/aussiwozzi/cgi/base/unassigned_arf.mdl"}, 
    ["CT: SAR Asalto"] = {"models/aussiwozzi/cgi/base/tedden/unassigned_med.mdl"}, 
    ["CT: SAR Apoyo"] = {"models/aussiwozzi/cgi/base/unassigned_heavy.mdl", "models/aussiwozzi/cgi/base/unassigned_pilot.mdl"}, 
    ["CT: SAR ARC"] = {"models/aussiwozzi/cgi/base/unassigned_arc.mdl"}, 
    ["CT: SAR Comandante"] = {"models/aussiwozzi/cgi/base/trooper.mdl"}, 
    ["CT: AIR Soldado"] = {"models/aussiwozzi/cgi/base/trooper.mdl"}, 
    ["CT: AIR Reconocimiento"] = {"models/aussiwozzi/cgi/base/unassigned_arf.mdl"}, 
    ["CT: AIR Asalto"] = {"models/aussiwozzi/cgi/base/tedden/unassigned_med.mdl"}, 
    ["CT: AIR Apoyo"] = {"models/aussiwozzi/cgi/base/unassigned_heavy.mdl", "models/aussiwozzi/cgi/base/unassigned_pilot.mdl"}, 
    ["CT: AIR ARC"] = {"models/aussiwozzi/cgi/base/unassigned_arc.mdl"}, 
    ["CT: AIR Comandante"] = {"models/aussiwozzi/cgi/base/trooper.mdl"}, 
    ["CT: Cody"] = {"models/aussiwozzi/cgi/base/imperial_cody.mdl"},
    ["CT: Wolffee"] = {"models/aussiwozzi/cgi/base/104th_wolffe.mdl"},
    ["CT: Grey"] = {"models/aussiwozzi/cgi/base/grey.mdl"},
    ["CT: Howzer"] = {"models/aussiwozzi/cgi/base/howzer.mdl"},
    ["CT: Clon Comando"] = {"models/aussiwozzi/cgi/commando/rc_plain.mdl"},

    -- SHADOW UNIT
    
    ["SU: Agente"] = {"models/aussiwozzi/cgi/base/shadow_trooper.mdl"}, 
    ["SU: ARF"] = {"models/aussiwozzi/cgi/base/shadow_arf.mdl"}, 
    ["SU: Ingeniero"] = {"models/aussiwozzi/cgi/base/shadow_arf.mdl"}, 
    ["SU: Francotirador"] = {"models/aussiwozzi/cgi/base/shadow_arf.mdl"}, 
    ["SU: Medico"] = {"models/aussiwozzi/cgi/base/shadow_medic.mdl"},
    ["SU: Especialista"] = {"models/aussiwozzi/cgi/base/shadow_pilot.mdl"}, 
    ["SU: Pesado"] = {"models/aussiwozzi/cgi/base/shadow_pilot.mdl"}, 
    ["SU: ARC"] = {"models/aussiwozzi/cgi/base/shadow_arc.mdl"}, 
    ["SU: Comandante"] = {"models/aussiwozzi/cgi/base/shadow_commander.mdl"},
    ["SU: Clon Comando"] = {"models/aussiwozzi/cgi/commando/rc_darman.mdl"},


    --LEGION SH

    ["SH: Soldado"] = {"models/aussiwozzi/cgi/base/cg_trooper.mdl"}, 
    ["SH: Reconocimiento"] = {"models/aussiwozzi/cgi/base/cg_tracker.mdl"}, 
    ["SH: Asalto"] = {"models/aussiwozzi/cgi/base/cg_medic.mdl"}, 
    ["SH: Apoyo"] = {"models/aussiwozzi/cgi/base/cg_pilot.mdl"}, 
    ["SH: ARC"] = {"models/aussiwozzi/cgi/base/cg_arc.mdl"},
    ["SH: Comandante"] = {"models/aussiwozzi/cgi/base/cg_officer.mdl"}, 
    ["SH: RT Soldado"] = {"models/aussiwozzi/cgi/base/cg_trooper.mdl"}, 
    ["SH: RT Reconocimiento"] = {"models/aussiwozzi/cgi/base/cg_tracker.mdl"}, 
    ["SH: RT Asalto"] = {"models/aussiwozzi/cgi/base/cg_medic.mdl"}, 
    ["SH: RT Apoyo"] = {"models/aussiwozzi/cgi/base/cg_riot.mdl"}, 
    ["SH: RT ARC"] = {"models/aussiwozzi/cgi/base/cg_arc.mdl"},
    ["SH: RT Comandante"] = {"models/aussiwozzi/cgi/base/cg_tracker_officer.mdl"},
    ["SH: Clon Comando"] = {"models/aussiwozzi/cgi/commando/clone_commando_royal.mdl"},

    --ICONICOS 65TH
    ["SH: RT Fox"] = {"models/aussiwozzi/cgi/base/cg_fox.mdl"},
    ["SH: RT Hound"] = {"models/aussiwozzi/cgi/base/cg_hound.mdl"},
    ["SH: Thire"] = {"models/aussiwozzi/cgi/base/cg_thire.mdl"},
    ["SH: Stone"] = {"models/aussiwozzi/cgi/base/cg_stone.mdl"},
}

local jobDescriptions = {

    --CLONE TROOPERS

    ["CT: Soldado"] = "Soldado base de la República.", 
    ["CT: Reconocimiento"] = "Especialista en sigilo.", 
    ["CT: Asalto"] = "Unidad de primera línea.", 
    ["CT: Apoyo"] = "Suministros y medicina.", 
    ["CT: ARC"] = "Comando de reconocimiento avanzado.",
    ["CT: Comandante"] = "Líder de CT.", 
    ["CT: SAR Soldado"] = "Soldado de Shock.", 
    ["CT: SAR Reconocimiento"] = "Reconocimiento de Shock.", 
    ["CT: SAR Asalto"] = "Asalto de Shock.", 
    ["CT: SAR Apoyo"] = "Apoyo de Shock.", 
    ["CT: SAR ARC"] = "ARC de Shock.", 
    ["CT: SAR Comandante"] = "Comandante de Shock.",    
    ["CT: AIR Soldado"] = "Soldado de Air.", 
    ["CT: AIR Reconocimiento"] = "Reconocimiento de Air.", 
    ["CT: AIR Asalto"] = "Asalto de Air.", 
    ["CT: AIR Apoyo"] = "Apoyo de Air.", 
    ["CT: AIR ARC"] = "ARC de Air.", 
    ["CT: AIR Comandante"] = "Comandante de Air.",
    ["CT: Cody"] = "Legendario Comandante Cody de la ex212th y de la Airborne.",
    ["CT: Wolffee"] = "Legendario Comandante Wolffee de la ex104th y lider del cuerpo de Seguridad y rescate.",
    ["CT: Grey"] = "Comandante Grey que sirvio al mando de Depa Billaba.",
    ["CT: Howzer"] = "Comandante Howzer que sirvio en el frente de Ryloth.",
    ["CT: Clon Comando"] = "Clon Comando del imperio.",
    

    
    --LEGION 65TH
    
    ["SH: Soldado"] = "Soldado de la 65th.", 
    ["SH: Reconocimiento"] = "Reconocimiento de la 65th.", 
    ["SH: Asalto"] = "Fuerzas de choque.", 
    ["SH: Apoyo"] = "Unidad de apoyo.", 
    ["SH: ARC"] = "Comando de reconocimiento avanzado.",
    ["SH: Comandante"] = "Comandante de la 65th.", 
    ["SH: RT Soldado"] = "Soldado RT.", 
    ["SH: RT Reconocimiento"] = "Reconocimiento RT.", 
    ["SH: RT Asalto"] = "Asalto RT.", 
    ["SH: RT Apoyo"] = "Apoyo RT.", 
    ["SH: RT ARC"] = "Comando de reconocimiento avanzado.",
    ["SH: RT Comandante"] = "Comandante RT.",
    ["SH: RT Fox"] = "Comandante Fox de la Guardia de Coruscant.",
    ["SH: RT Hound"] = "Buscador de la RT.",
    ["SH: Thire"] = "Thire",
    ["SH: Stone"] = "Comandante Stonede la Guardia de Coruscant.",
    ["SH: Clon Comando"] = "Clon Comando del imperio.",
    

}

-- =========================================================================
-- FUNCIÓN REGISTRO (LOGICA CORREGIDA)
-- =========================================================================
local function registerJob(fullName, config)
    local varName = config.shortName or "TEAM_" .. string.upper(string.gsub(fullName, "[: ]", "_"))
    config.shortName = nil 
    config.weapons = jobWeapons[fullName] or {}
    config.model = jobModels[fullName] or {"models/player/kleiner.mdl"}
    config.description = jobDescriptions[fullName] or "Un miembro de la unidad."
    
    -- Restricción por defecto para que sólo la Whitelist deje pasar
    config.customCheck = function(ply) return false end
    config.CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
    
    _G[varName] = DarkRP.createJob(fullName, config)
end

-- =========================================================================
-- BUCLES (USANDO ABREVIACIONES)
-- =========================================================================
local jobs_CT = {"Soldado", "Reconocimiento", "Asalto", "Apoyo", "ARC", "Comandante", "SAR Soldado", "SAR Reconocimiento", "SAR Asalto", "SAR Apoyo", "SAR ARC", "SAR Comandante", "AIR Soldado", "AIR Reconocimiento", "AIR Asalto", "AIR Apoyo", "AIR ARC", "AIR Comandante", "Cody", "Wolffee", "Grey", "Howzer", "Clon Comando"}
local abbr_CT = {"CT_SOL", "CT_REC", "CT_ASA", "CT_APO", "CT_ARC", "CT_CMD", "CT_SAR_SOL", "CT_SAR_REC", "CT_SAR_ASA", "CT_SAR_APO", "CT_SAR_ARC", "CT_SAR_CMD", "CT_AIR_SOL", "CT_AIR_REC", "CT_AIR_ASA", "CT_AIR_APO", "CT_AIR_ARC", "CT_AIR_CMD", "CT_CODY", "CT_WOLFFEE", "CT_GREY", "CT_HOWZER", "CT_COMANDO"}
for i, name in ipairs(jobs_CT) do
    registerJob("CT: " .. name, {
        color = Color(228, 228, 228), 
        category = CAT_CT, 
        command = "ct_" .. string.lower(string.gsub(name, " ", "_")), 
        max = 0, salary = 50, 
        shortName = "TEAM_" .. abbr_CT[i]
    })
end

local jobs_SU = {"Agente", "ARF", "Ingeniero", "Francotirador", "Medico", "Especialista", "Pesado", "ARC", "Comandante", "Clon Comando"}
local abbr_SU = {"SU_AGT", "SU_ARF", "SU_ENG", "SU_FRN", "SU_MED", "SU_SPEC", "SU_HEAVY", "SU_ARC", "SU_CMD", "SU_COMANDO"}
for i, name in ipairs(jobs_SU) do
    registerJob("SU: " .. name, {
        color = Color(165, 47, 47), 
        category = CAT_SU, 
        command = "su_" .. string.lower(string.gsub(name, " ", "_")), 
        max = 0, salary = 50, 
        shortName = "TEAM_" .. abbr_SU[i]
    })
end

local jobs_SH = {"Soldado", "Reconocimiento", "Asalto", "Apoyo", "ARC","Comandante", "RT Soldado", "RT Reconocimiento", "RT Asalto", "RT Apoyo", "RT ARC","RT Comandante", "RT Fox", "RT Hound", "Thire", "Stone", "Clon Comando"}
local abbr_SH = {"SH_SOL", "SH_REC", "SH_ASA", "SH_APO", "SH_ARC","SH_CMD", "SH_RT_SOL", "SH_RT_REC", "SH_RT_ASA", "SH_RT_APO", "SH_RT_ARC","SH_RT_CMD", "SH_RT_FOX", "SH_RT_HOUND", "SH_THIRE", "SH_STONE", "SH_COMANDO"}
for i, name in ipairs(jobs_SH) do
    registerJob("SH: " .. name, {
        color = Color(165, 47, 47), 
        category = CAT_SH, 
        command = "sh_" .. string.lower(string.gsub(name, " ", "_")), 
        max = 0, 
        salary = 75, 
        shortName = "TEAM_" .. abbr_SH[i]
    })
end




-- AM
TEAM_DIRECTOR = DarkRP.createJob("Director de Comandantes", {
    color = Color(36, 37, 37), 
    model = {"models/player/odst.mdl"}, 
    description = "Máximo mando operativo.", 
    weapons = {""}, 
    command = "director_comandantes", 
    max = 1, 
    salary = 500, 
    category = CAT_AM,
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_TARKIN = DarkRP.createJob("Wilhuff Tarkin", {
    color = Color(36, 37, 37), 
    model = {"models/navy/gnavytarkin.mdl"}, 
    description = "Gran Moff y lider de operaciones imperiales.", 
    weapons = {"weapon_lightsaber"}, 
    command = "tarkin", 
    max = 1, 
    salary = 500, 
    category = CAT_AM,
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_PALPATINE = DarkRP.createJob("Emperador Palpatine", {
    color = Color(36, 37, 37), 
    model = {"models/player/emperor_palpatine.mdl"}, 
    description = "El líder supremo del Imperio.", 
    weapons = {"weapon_lscs"}, 
    command = "palpatine", 
    max = 1, 
    salary = 1000, 
    category = CAT_AM, 
    vote = true,
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

-- Cadete

-- Define la variable antes de crear el job
TEAM_CADETE = DarkRP.createJob("Cadete Clon", {
    color = Color(255, 255, 255), 
    model = {"models/cadet_green/pm_training_cadet_domino.mdl"}, 
    description = "Bienvenido a Virtus Studios Cadete.", 
    weapons = {""}, 
    command = "cadete", 
    max = 0, 
    salary = 0, 
    category = "Cadetes"
})

TEAM_PRUEBA = DarkRP.createJob("Prueba", {
    color = Color(50, 50, 50), 
    model = {"models/aussiwozzi/cgi/base/basegeneral.mdl"}, 
    description = "Job de prueba con skin Shadow Base.", 
    weapons = {""}, 
    command = "prueba", 
    max = 0, 
    salary = 0, 
    category = "Cadetes"
})


-- REX SQUAD

TEAM_REX = DarkRP.createJob("Rex", {
    color = Color(103, 135, 199), 
    model = {"models/aussiwozzi/cgi/base/501st_rex.mdl"}, 
    description = "Legendario Ex-Capitan Rex.", 
    weapons = {""}, 
    command = "rex", 
    max = 0, 
    salary = 500, 
    category = "Red Clandestina Clon",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_NEMEC = DarkRP.createJob("Nemec", {
    color = Color(103, 135, 199), 
    model = {"models/rogue/nemec.mdl"}, 
    description = "Nemec", 
    weapons = {""}, 
    command = "nemec", 
    max = 0, 
    salary = 500, 
    category = "Red Clandestina Clon",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_FIREBALL = DarkRP.createJob("Fireball", {
    color = Color(103, 135, 199), 
    model = {"models/rogue/fireball.mdl"}, 
    description = "Fireball", 
    weapons = {""}, 
    command = "fireball", 
    max = 0, 
    salary = 500, 
    category = "Red Clandestina Clon",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_SAMSON = DarkRP.createJob("Samson", {
    color = Color(103, 135, 199), 
    model = {"models/rogue/samson.mdl"}, 
    description = "Samson", 
    weapons = {""}, 
    command = "Samson", 
    max = 0, 
    salary = 500, 
    category = "Red Clandestina Clon",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})


-- Bad Batch

TEAM_HUNTER = DarkRP.createJob("Hunter", {
    color = Color(103, 135, 199), 
    model = {"models/player/bad_batch/hunter.mdl"}, 
    description = "Lider de la fuerza clon 99", 
    weapons = {""}, 
    command = "hunter", 
    max = 0, 
    salary = 500, 
    category = "Bad Batch",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_TECH = DarkRP.createJob("Tech", {
    color = Color(103, 135, 199), 
    model = {"models/player/bad_batch/tech.mdl"}, 
    description = "Hacker de la fuerza clon 99", 
    weapons = {""}, 
    command = "tech", 
    max = 0, 
    salary = 500, 
    category = "Bad Batch",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_ECHO = DarkRP.createJob("Echo", {
    color = Color(103, 135, 199), 
    model = {"models/player/bad_batch/echo.mdl"}, 
    description = "Legendario ARC Trooper Echo", 
    weapons = {""}, 
    command = "echo", 
    max = 0, 
    salary = 500, 
    category = "Bad Batch",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_WRECKER = DarkRP.createJob("Wrecker", {
    color = Color(103, 135, 199), 
    model = {"models/player/bad_batch/wrecker.mdl"}, 
    description = "Demoledor de la fuerza clon 99", 
    weapons = {""}, 
    command = "wrecker", 
    max = 0, 
    salary = 500, 
    category = "Bad Batch",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_B1 = DarkRP.createJob("Droide B1", {
    color = Color(0, 58, 173), 
    model = {"models/aussiwozzi/cgi/b1droids/b1_battledroid_pm.mdl"}, 
    description = "Droide de batalla B1 de la Confederación de Sistemas Independientes.", 
    weapons = {""}, 
    command = "b1", 
    max = 0, 
    salary = 500, 
    category = "CIS",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_B2 = DarkRP.createJob("Droide B2", {
    color = Color(0, 58, 173), 
    model = {"models/aussiwozzi/cgi/b1droids/b2_battledroid_pm.mdl"}, 
    description = "Super Droide de batalla B2 de la Confederación de Sistemas Independientes.", 
    weapons = {""}, 
    command = "b2", 
    max = 0, 
    salary = 500, 
    category = "CIS",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_BX = DarkRP.createJob("Droide Comando BX", {
    color = Color(0, 58, 173), 
    model = {"models/bx/pm_droid_cis_bx.mdl"}, 
    description = "Droide Comando BX de la Confederación de Sistemas Independientes.", 
    weapons = {""}, 
    command = "bx", 
    max = 0, 
    salary = 500, 
    category = "CIS",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_KALANI = DarkRP.createJob("General Kalani", {
    color = Color(0, 58, 173), 
    model = {"models/player/swcw/std_kalani.mdl"}, 
    description = "General de la Confederación de Sistemas Independientes.", 
    weapons = {""}, 
    command = "kalani", 
    max = 0, 
    salary = 500, 
    category = "CIS",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_BX_CAPTAIN = DarkRP.createJob("Capitán BX", {
    color = Color(0, 58, 173), 
    model = {"models/bx_captain/pm_droid_cis_bx_captain.mdl"}, 
    description = "Capitán de la Confederación de Sistemas Independientes.", 
    weapons = {""}, 
    command = "bx_captain", 
    max = 0, 
    salary = 500, 
    category = "CIS",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_B1_CMD = DarkRP.createJob("Comandante B1", {
    color = Color(0, 58, 173), 
    model = {"models/aussiwozzi/cgi/b1droids/b1_battledroid_commander_pm.mdl"}, 
    description = "Comandante B1 de la Confederación de Sistemas Independientes.", 
    weapons = {""}, 
    command = "b1_cmd", 
    max = 0, 
    salary = 500, 
    category = "CIS",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

-- Trandoshanos
TEAM_TRANDOSHANO_LIDER = DarkRP.createJob("Trandoshano Lider", {
    color = Color(50, 150, 50),
    model = {"models/clutch/pm_trandoshan_clutch.mdl"},
    description = "Líder de los Trandoshanos.",
    weapons = {""},
    command = "trandoshano_lider",
    max = 0,
    salary = 500,
    category = "Trandoshanos",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_TRANDOSHANO_CAZADOR = DarkRP.createJob("Trandoshano Cazador", {
    color = Color(50, 150, 50),
    model = {"models/sniper/pm_trandoshan_sniper.mdl"},
    description = "Cazador Trandoshano.",
    weapons = {""},
    command = "trandoshano_cazador",
    max = 0,
    salary = 500,
    category = "Trandoshanos",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_TRANDOSHANO_PESADO = DarkRP.createJob("Trandoshano Pesado", {
    color = Color(50, 150, 50),
    model = {"models/hunter/pm_trandoshan_hunter.mdl"},
    description = "Trandoshano de asalto pesado.",
    weapons = {""},
    command = "trandoshano_pesado",
    max = 0,
    salary = 500,
    category = "Trandoshanos",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_TRANDOSHANO_NOVATO = DarkRP.createJob("Trandoshano Novato", {
    color = Color(50, 150, 50),
    model = {"models/lotaren/pm_trandoshan_lotaren.mdl"},
    description = "Novato Trandoshano.",
    weapons = {""},
    command = "trandoshano_novato",
    max = 0,
    salary = 500,
    category = "Trandoshanos",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

-- Sol Negro
TEAM_GAR_SAXON = DarkRP.createJob("Gar Saxon", {
    color = Color(20, 20, 20),
    model = {"models/dw_garsaxon/pm_deathwatch_maul_garsaxon.mdl"},
    description = "Gar Saxon del Sol Negro.",
    weapons = {""},
    command = "gar_saxon",
    max = 0,
    salary = 500,
    category = "Sol Negro",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_MANDALORIANO_SARGENTO = DarkRP.createJob("Mandaloriano Sargento", {
    color = Color(20, 20, 20),
    model = {"models/dw_sgt/pm_deathwatch_maul_sgt.mdl"},
    description = "Sargento Mandaloriano del Sol Negro.",
    weapons = {""},
    command = "mandaloriano_sargento",
    max = 0,
    salary = 500,
    category = "Sol Negro",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_MANDALORIANO_PESADO = DarkRP.createJob("Mandaloriano Pesado", {
    color = Color(20, 20, 20),
    model = {"models/dw_brute/pm_deathwatch_maul_brute.mdl"},
    description = "Mandaloriano Pesado del Sol Negro.",
    weapons = {""},
    command = "mandaloriano_pesado",
    max = 0,
    salary = 500,
    category = "Sol Negro",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_MANDALORIANO_FRANCOTIRADOR = DarkRP.createJob("Mandaloriano Francotirador", {
    color = Color(20, 20, 20),
    model = {"models/dw_huntress/pm_deathwatch_maul_huntress.mdl"},
    description = "Francotirador Mandaloriano del Sol Negro.",
    weapons = {""},
    command = "mandaloriano_francotirador",
    max = 0,
    salary = 500,
    category = "Sol Negro",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

-- Iconicos Enemigos
TEAM_HONDO_OHNAKA = DarkRP.createJob("Hondo Ohnaka", {
    color = Color(150, 50, 50),
    model = {"models/player/ohanak_gang/pm_pirate_hondo.mdl"},
    description = "Hondo Ohnaka.",
    weapons = {""},
    command = "hondo_ohnaka",
    max = 0,
    salary = 500,
    category = "Iconicos Enemigos",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_JABBA = DarkRP.createJob("Jabba", {
    color = Color(150, 50, 50),
    model = {"models/hutts/hutt_01.mdl"},
    description = "Jabba el Hutt.",
    weapons = {""},
    command = "jabba",
    max = 0,
    salary = 500,
    category = "Iconicos Enemigos",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_SAW_GERRERA = DarkRP.createJob("Saw Gerrera", {
    color = Color(150, 50, 50),
    model = {"models/player/tcw/human/saw_gerrera.mdl"},
    description = "Saw Gerrera.",
    weapons = {""},
    command = "saw_gerrera",
    max = 0,
    salary = 500,
    category = "Iconicos Enemigos",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_BOSK = DarkRP.createJob("Bosk", {
    color = Color(150, 50, 50),
    model = {"models/trando_bossk/pm_trando_bossk.mdl"},
    description = "Cazarrecompensas Bosk.",
    weapons = {""},
    command = "bosk",
    max = 0,
    salary = 500,
    category = "Iconicos Enemigos",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_BO_KATAN = DarkRP.createJob("Bo Katan", {
    color = Color(150, 50, 50),
    model = {"models/dw_bokatan/pm_deathwatch_bokatan.mdl"},
    description = "Bo Katan.",
    weapons = {""},
    command = "bo_katan",
    max = 0,
    salary = 500,
    category = "Iconicos Enemigos",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_CAD_BANE = DarkRP.createJob("Cad Bane", {
    color = Color(150, 50, 50),
    model = {"models/tfceventcadbane/cadbane.mdl"},
    description = "Cazarrecompensas Cad Bane.",
    weapons = {""},
    command = "cad_bane",
    max = 0,
    salary = 500,
    category = "Iconicos Enemigos",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

TEAM_DENGAR = DarkRP.createJob("Dengar", {
    color = Color(150, 50, 50),
    model = {"models/tfceventdengar/dengar.mdl"},
    description = "Cazarrecompensas Dengar.",
    weapons = {""},
    command = "dengar",
    max = 0,
    salary = 500,
    category = "Iconicos Enemigos",
    customCheck = function(ply) return false end,
    CustomCheckFailMsg = "No estás en la whitelist de este trabajo."
})

--=============================================================================
-- POST-PROCESSING
-- Añade 100 HP, 100 Armadura a todos los jobs, y modifica la escala del trandoshano
--=============================================================================
for k, v in pairs(RPExtraTeams or {}) do
    local oldSpawn = v.PlayerSpawn
    v.PlayerSpawn = function(ply)
        ply:SetHealth(100)
        ply:SetMaxHealth(100)
        ply:SetArmor(100)
        if k == TEAM_TRANDOSHANO_PESADO then
            ply:SetModelScale(1.1, 0)
        end
        if oldSpawn then oldSpawn(ply) end
    end
end

--[[---------------------------------------------------------------------------
Define which team joining players spawn into and what team you change to if demoted
---------------------------------------------------------------------------]]
GAMEMODE.DefaultTeam = TEAM_CADETE
--[[---------------------------------------------------------------------------
Define which teams belong to civil protection
Civil protection can set warrants, make people wanted and do some other police related things
---------------------------------------------------------------------------]]
GAMEMODE.CivilProtection = {
    [TEAM_POLICE] = false,
    [TEAM_CHIEF] = false,
    [TEAM_MAYOR] = false,
}
--[[---------------------------------------------------------------------------
Jobs that are hitmen (enables the hitman menu)
---------------------------------------------------------------------------]]
DarkRP.addHitmanTeam(TEAM_MOB)
