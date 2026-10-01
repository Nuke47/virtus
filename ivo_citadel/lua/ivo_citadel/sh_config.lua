IvoCitadel = IvoCitadel or {}
IvoCitadel.Config = IvoCitadel.Config or {}

-- Función para verificar si un jugador tiene permisos para iniciar ciudadelas (SGT+)
function IvoCitadel.Config.HasPermission(ply)
    if not IsValid(ply) then return false end
    
    -- Si eres admin siempre puedes
    if ply:IsAdmin() or ply:IsSuperAdmin() then return true end

    -- Ejemplo con rangos de ULX / SAM
    local group = ply:GetUserGroup()
    local allowed_groups = {
        ["superadmin"] = true,
        ["admin"] = true,
        ["commander"] = true,
        ["sgt"] = true,
    }
    if allowed_groups[group] then return true end

    -- Ejemplo con DarkRP Jobs (TEAM_*)
    -- Cambia "TEAM_SGT" por el nombre real de tus variables de trabajo si usas DarkRP.
    -- if ply:Team() == TEAM_SGT or ply:Team() == TEAM_COMMANDER then return true end

    return false
end

-- Lista de droides disponibles para elegir en el modo personalizado
IvoCitadel.Config.AvailableDroids = {
    { name = "Droide B1", class = "npc_droid_b1" },
    { name = "Droide B2", class = "npc_droid_b2" },
    { name = "Droide Comando BX", class = "npc_droid_bx" },
    { name = "Droideka", class = "npc_droid_droideka" },
}

-- Configuración de ciudadelas predefinidas
IvoCitadel.Config.Predefined = {
    [1] = {
        name = "Ataque Ligero (B1s)",
        droids = {
            ["npc_droid_b1"] = 10 -- spawneará 10 de estos
        }
    },
    [2] = {
        name = "Ataque Medio",
        droids = {
            ["npc_droid_b1"] = 15,
            ["npc_droid_b2"] = 3
        }
    },
    [3] = {
        name = "Asalto Pesado",
        droids = {
            ["npc_droid_b1"] = 20,
            ["npc_droid_b2"] = 5,
            ["npc_droid_bx"] = 2,
            ["npc_droid_droideka"] = 1
        }
    }
}

-- Colores del HUD
IvoCitadel.Config.Colors = {
    main = Color(255, 0, 0, 200),
    text = Color(255, 255, 255, 255),
    bg = Color(0, 0, 0, 150)
}

-- Sonidos
IvoCitadel.Config.SoundStart = "ambient/alarms/klaxon1.wav"
IvoCitadel.Config.SoundEnd = "misc/jingle.wav" -- Cambiar por un sonido de victoria

