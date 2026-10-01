-- ============================================
--  BOUNTY HUNTER SYSTEM - Configuración Shared
--  Archivo: lua/bounty_hunter/shared/config.lua
-- ============================================

BountySystem = BountySystem or {}
BountySystem.Config = {

    -- Precio mínimo y máximo de recompensa
    MinBounty      = 5000,
    MaxBounty      = 20000,

    -- Tiempo máximo que dura una recompensa activa (segundos)
    BountyDurationMin = 600,  -- 10 minutos
    BountyDurationMax = 900,  -- 15 minutos

    -- Porcentaje del botín que va al servidor/fondo común (0 = todo al jugador)
    TaxRate        = 0.05, -- 5%

    -- Cuántas recompensas puede tener activas un jugador a la vez (como objetivo)
    MaxBountiesPerTarget = 3,

    -- Cooldown entre recompensas del mismo emisor al mismo objetivo (segundos)
    PlaceCooldown  = 300,  -- 5 minutos

    -- Moneda (display)
    CurrencySymbol = "₢",
    CurrencyName   = "créditos galácticos",

    -- Permiso para administrar recompensas (cancelar cualquiera, ver lista admin)
    AdminPermission = "superadmin",

    -- Notificación en pantalla al poner/cobrar recompensa
    NotifyAll = true,

    -- Colores de la UI (HoloNet Star Wars)
    Colors = {
        Primary    = Color(0, 255, 255),
        Secondary  = Color(10, 15, 20),
        Accent     = Color(255, 60, 60),
        Background = Color(8, 12, 16),
        Text       = Color(220, 240, 255),
        TextDark   = Color(100, 140, 180),
        Success    = Color(50,  255, 100),
        Danger     = Color(255, 50,  50),
        Panel      = Color(15,  25,  35),
        Border     = Color(0,   150, 255),
    },

    -- ========================================================
    -- RESTRICCIONES DE TRABAJOS (DarkRP)
    -- ========================================================
    RestrictedTargetJobs = {
        ["police"] = true,
        ["chief"]  = true,
        ["mayor"]  = true,
        ["admin"]  = true
    },

    -- ========================================================
    -- TRABAJOS DE CAZARRECOMPENSAS
    -- ========================================================
    -- Si tiene trabajos, SOLO estos podrán aceptar contratos. Dejar vacío {} para que todos puedan.
    BountyHunterJobs = {
        ["cadete"] = true,
        ["mandalorian"] = true,
    },

    -- ========================================================
    -- CONTRATOS ALEATORIOS DEL SERVIDOR
    -- ========================================================
    EnableRandomBounties = true,
    RandomBountyInterval = 600,   -- Tiempo en segundos (600 = 10 minutos)
    RandomBountyMin = 5000,       -- Recompensa mínima aleatoria
    RandomBountyMax = 25000,      -- Recompensa máxima aleatoria
    ConcurrentRandomBounties = 3, -- Cantidad de contratos aleatorios creados al mismo tiempo

    -- ========================================================
    -- SISTEMA DE PROGRESO (NIVELES Y PRESTIGIO)
    -- ========================================================
    MaxLevel  = 10,             -- Nivel máximo antes de poder prestigiar
    XPPercentageMin = 0.05,     -- Mínimo 5% del importe del contrato como XP
    XPPercentageMax = 0.15,     -- Máximo 15% del importe del contrato como XP
    PrestigeMultiplier = 0.20,  -- +20% de dinero extra por cada nivel de prestigio
}

-- Estados de una recompensa
BountySystem.STATUS = {
    ACTIVE    = "active",
    CLAIMED   = "claimed",
    CANCELLED = "cancelled",
    EXPIRED   = "expired",
}

-- Nétwork strings
if SERVER then
    util.AddNetworkString("BountySystem_OpenMenu")
    util.AddNetworkString("BountySystem_SyncBounties")
    util.AddNetworkString("BountySystem_PlaceBounty")
    util.AddNetworkString("BountySystem_ClaimBounty")
    util.AddNetworkString("BountySystem_AcceptBounty")
    util.AddNetworkString("BountySystem_CancelBounty")
    util.AddNetworkString("BountySystem_Notify")
    util.AddNetworkString("BountySystem_RequestList")
    util.AddNetworkString("BountySystem_SyncStats")
    util.AddNetworkString("BountySystem_Prestige")
    util.AddNetworkString("BountySystem_AdminAction")
    util.AddNetworkString("BountySystem_RequestAdminStats")
    util.AddNetworkString("BountySystem_SyncAdminStats")
    util.AddNetworkString("BountySystem_HireHunter")
    util.AddNetworkString("BountySystem_OpenHireMenu")
end
