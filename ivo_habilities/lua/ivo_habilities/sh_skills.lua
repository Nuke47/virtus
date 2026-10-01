IVO_HABILITIES.SkillsList = {
    -- Habilidades Generales (Requieren puntos generales)
    ["gen_speed_1"] = {
        name = "Velocidad Mejorada I",
        desc = "Aumenta tu velocidad de movimiento en un 5%.",
        type = "general",
        cost = 1,
        req = nil
    },
    ["gen_speed_2"] = {
        name = "Velocidad Mejorada II",
        desc = "Aumenta tu velocidad de movimiento en un 10%.",
        type = "general",
        cost = 2,
        req = "gen_speed_1"
    },
    ["gen_stamina_1"] = {
        name = "Acondicionamiento Físico I",
        desc = "Aumenta tu resistencia máxima (Stamina) en un 20%.",
        type = "general",
        cost = 1,
        req = nil
    },
    ["gen_stamina_2"] = {
        name = "Acondicionamiento Físico II",
        desc = "Aumenta tu resistencia máxima (Stamina) en un 40%.",
        type = "general",
        cost = 2,
        req = "gen_stamina_1"
    },
    -- Placeholders ARC
    ["arc_placeholder_1"] = {
        name = "Entrenamiento Avanzado ARC",
        desc = "Primera habilidad de la rama ARC.",
        type = "arc",
        cost = 1,
        req = nil
    },
    ["arc_placeholder_2"] = {
        name = "Especialista ARC",
        desc = "Segunda habilidad de la rama ARC.",
        type = "arc",
        cost = 2,
        req = "arc_placeholder_1"
    },
    -- Placeholders Apoyo
    ["apoyo_placeholder_1"] = {
        name = "Logística de Apoyo I",
        desc = "Primera habilidad de la rama de Apoyo.",
        type = "apoyo",
        cost = 1,
        req = nil
    }
}

if SERVER then
    util.AddNetworkString("IVO_Habilities_Sync")
    util.AddNetworkString("IVO_Habilities_Unlock")
end
