-- ============================================================================
-- IVOSAM: CONFIGURACIÓN CENTRAL — Todas las constantes del sistema
-- Modificar aquí para ajustar comportamiento sin tocar la lógica.
-- ============================================================================
IVO_SAM = IVO_SAM or {}

IVO_SAM.Config = {
    -- Freecam
    FREECAM_SPEED           = 15,       -- velocidad normal (teclas WASD)
    FREECAM_SPEED_FAST      = 35,       -- velocidad con Shift presionado

    -- Sistema de Tickets
    TICKET_LIFETIME         = 40,       -- segundos hasta auto-expirar un ticket en pantalla

    -- Comando !slap
    SLAP_FORCE_H            = 150,      -- fuerza horizontal máxima del slap (±random)
    SLAP_FORCE_V_MIN        = 250,      -- fuerza vertical mínima del slap
    SLAP_FORCE_V_MAX        = 350,      -- fuerza vertical máxima del slap

    -- Comando !bring
    BRING_RADIUS_BASE       = 80,       -- radio base alrededor del admin
    BRING_RADIUS_STEP       = 5,        -- radio extra por cada jugador adicional

    -- Persistencia de playtime
    PLAYTIME_SAVE_INTERVAL  = 30,       -- segundos entre guardados automáticos a SQL

    -- Razones por defecto en moderación
    DEFAULT_BAN_REASON      = "Sin motivo especificado",
    DEFAULT_KICK_REASON     = "No especificado",

    -- Cooldowns por comando (segundos). Comandos no listados: sin cooldown.
    COOLDOWNS = {
        ban      = 5,
        banid    = 5,
        kick     = 3,
        slay     = 2,
        freeze   = 2,
        jail     = 2,
        cloak    = 2,
        uncloak  = 2,
        hp       = 1,
        armor    = 1,
        slap     = 1,
        ignite   = 2,
    },
}
IVO_SAM.Config.USE_MYSQL = true
IVO_SAM.Config.DB_HOST = "45.235.98.238"
IVO_SAM.Config.DB_USER = "_ivan75"
IVO_SAM.Config.DB_PASS = "f3WEFVf34$"
IVO_SAM.Config.DB_NAME = "_ivan75"
IVO_SAM.Config.DB_PORT = 3306
