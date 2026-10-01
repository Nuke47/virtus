RadioFrequencies = {
    -- FRECUENCIA GENERAL (Pública para todo el servidor, no lleva filtros)
    { 
        name = "Frecuencia General", 
        channel = 1, 
        color = Color(0, 191, 165) 
    },

    { 
        name = "ESCUADRON ALFA", 
        channel = 2, 
        color = Color(0, 191, 165) 
    },

    { 
        name = "ESCUADRON BETA", 
        channel = 3, 
        color = Color(0, 191, 165) 
    },
-- 1. FRECUENCIA GENERAL DE CLONES (Por Categoría)
    { 
        name = "Clone Troopers", 
        channel = 10, 
        color = Color(240, 240, 245), -- Blanco brillante
        category = "Clone Troopers" -- Nombre exacto de la pestaña en tu F4
    },

    -- 2. FRECUENCIA DE LA 501ST (Por Categoría)
    { 
        name = "SAR", 
        channel = 104, 
        color = Color(66, 165, 245), -- Azul 501
        jobs = { 
            "TEAM_CT_SAR_CMD", "TEAM_CT_SAR_SOL", "TEAM_CT_SAR_ARC", "TEAM_CT_SAR_APO", "TEAM_CT_SAR_ASA", "TEAM_CT_SAR_REC"
        }  -- Nombre exacto de la pestaña en tu F4
    },

    -- 3. FRECUENCIA DE LA 65TH (Por Categoría)
    { 
        name = "AIR", 
        channel = 212, 
        color = Color(239, 144, 80), -- Rojo Guardia de Coruscant
        jobs = { 
            "TEAM_CT_AIR_CMD", "TEAM_CT_AIR_SOL", "TEAM_CT_AIR_ARC", "TEAM_CT_AIR_APO", "TEAM_CT_AIR_ASA", "TEAM_CT_AIR_REC"
        } 
    },

    -- 4. FRECUENCIA DE LA 5TH (Por Categoría)
    { 
        name = "ShocK Troopers", 
        channel = 5, 
        color = Color(173, 26, 26), -- Morado
        category = "Shock Troopers" -- Nombre exacto de la pestaña en tu F4
    },

    { 
        name = "Shadow Unit", 
        channel = 100, 
        color = Color(53, 18, 109), -- Dorado
        category = "Shadow Unit" -- Nombre exacto de la pestaña en tu F4
    },

    -- Estructura oficial de frecuencias militares por batallón y rol
    -- 1. FRECUENCIA DE COMANDANTES
    { 
        name = "Frecuencia de Comandantes", 
        channel = 100, 
        color = Color(255, 215, 0), -- Dorado
        jobs = { 
            "TEAM_CT_CMD", "TEAM_SU_CMD", "TEAM_CT_SAR_CMD", "TEAM_CT_AIR_CMD", 
            "TEAM_SH_CMD", "TEAM_SH_RT_CMD", "TEAM_SH_RT_FOX", "TEAM_SH_STONE" 
        } 
    },

    -- 2. FRECUENCIA DE ASALTOS
    { 
        name = "Frecuencia de Asaltos", 
        channel = 200, 
        color = Color(239, 83, 80), -- Rojo
        jobs = { 
            "TEAM_CT_ASA", "TEAM_CT_SAR_ASA", "TEAM_CT_AIR_ASA", "TEAM_SH_ASA", "TEAM_SH_RT_ASA" 
        } 
    },

    -- 3. FRECUENCIA DE APOYOS
    { 
        name = "Frecuencia de Apoyos", 
        channel = 300, 
        color = Color(66, 165, 245), -- Azul
        jobs = { 
            "TEAM_CT_APO", "TEAM_CT_SAR_APO", "TEAM_CT_AIR_APO", "TEAM_SH_APO", "TEAM_SH_RT_APO" 
        } 
    },

    -- 4. FRECUENCIA DE RECONOCIMIENTOS
    { 
        name = "Frecuencia de Reconocimientos", 
        channel = 400, 
        color = Color(76, 175, 80), -- Verde
        jobs = { 
            "TEAM_CT_REC", "TEAM_CT_SAR_REC", "TEAM_CT_AIR_REC", "TEAM_SH_REC", "TEAM_SH_RT_REC" 
        } 
    },
}

