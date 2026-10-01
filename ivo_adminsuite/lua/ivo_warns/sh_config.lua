-- ========================================================================
-- IVO_WARNS - CONFIGURACIÓN GLOBAL (COMPLETA Y ADAPTABLE)
-- ========================================================================

IVO_WARNS = IVO_WARNS or {}
IVO_WARNS.Config = IVO_WARNS.Config or {}

-- ------------------------------------------------------------------------
-- 1. CONFIGURACIÓN BÁSICA DEL SISTEMA
-- ------------------------------------------------------------------------

-- ¿Usar MySQL en lugar de SQLite (Local)?
IVO_WARNS.Config.USE_MYSQL = false
IVO_WARNS.Config.DB_HOST   = "127.0.0.1"
IVO_WARNS.Config.DB_USER   = "root"
IVO_WARNS.Config.DB_PASS   = ""
IVO_WARNS.Config.DB_NAME   = "gmod_server"
IVO_WARNS.Config.DB_PORT   = 3306

-- Tiempo en días para que expiren los warns (si el jugador no recibe otro)
IVO_WARNS.Config.DecayDays = 15

-- Comandos de chat principales
IVO_WARNS.Config.CmdWarn   = "!warn"
IVO_WARNS.Config.CmdWarnID = "!warnid"

-- Prefijo para los mensajes de chat que envía el addon
IVO_WARNS.Config.Prefix = "[Ivo_Warns] "

-- ------------------------------------------------------------------------
-- 2. VERIFICACIÓN DE PERMISOS (ADMINISTRADORES)
-- ------------------------------------------------------------------------
function IVO_WARNS.IsAdmin(ply)
    if not IsValid(ply) then return false end
    return ply:IsAdmin() or ply:IsSuperAdmin()
end

-- ------------------------------------------------------------------------
-- 3. CONFIGURACIÓN DEL SISTEMA DE AUTO-BAN
-- ------------------------------------------------------------------------
-- ¿Activar el baneo automático al acumular advertencias activas?
IVO_WARNS.Config.EnableAutoBan = true

-- Tabla de penalizaciones de BAN: [Cantidad de Warns] = Minutos de Ban
IVO_WARNS.Config.AutoBans = {
    [3] = 1440,
    [5] = 4320
}

-- ------------------------------------------------------------------------
-- 3.5. CONFIGURACIÓN DEL SISTEMA DE AUTO-KICK
-- ------------------------------------------------------------------------
-- ¿Activar la expulsión (kick) automática al acumular advertencias?
IVO_WARNS.Config.EnableAutoKick = true

-- Tabla de penalizaciones de KICK: [Cantidad de Warns] = true
-- -> Al llegar a 2 warns, el jugador/bot será expulsado de la partida.
IVO_WARNS.Config.AutoKicks = {
    [2] = true
}

-- ------------------------------------------------------------------------
-- 4. CONTROLADOR UNIVERSAL DE SISTEMAS ADMINISTRATIVOS (SWITCH)
-- ------------------------------------------------------------------------
IVO_WARNS.Config.AdminSystem = "IVO_SAM"

function IVO_WARNS.ExecuteBan(uid, mins, reason)
    local system = IVO_WARNS.Config.AdminSystem
    local prefix = IVO_WARNS.Config.Prefix

    if system == "IVO_SAM" then
        local time_str = (mins >= 1440) and (math.floor(mins / 1440) .. "d") or (mins .. "m")
        RunConsoleCommand("sam_banid", uid, time_str, reason)
        print(prefix .. "Auto-ban enviado a IVO_SAM para: " .. uid .. " | Tiempo: " .. time_str)

    elseif system == "SAM" then
        if string.match(uid, "^BOT_") then return print(prefix .. "SAM no soporta bots. Ban omitido.") end
        RunConsoleCommand("sam", "banid", uid, tostring(mins), reason)
        print(prefix .. "Auto-ban enviado a SAM para: " .. uid .. " | Tiempo: " .. mins .. " min.")

    elseif system == "ULX" then
        if string.match(uid, "^BOT_") then return print(prefix .. "ULX no soporta bots. Ban omitido.") end
        RunConsoleCommand("ulx", "banid", uid, reason, tostring(mins))
        print(prefix .. "Auto-ban enviado a ULX para: " .. uid .. " | Tiempo: " .. mins .. " min.")

    elseif system == "XADMIN" then
        if string.match(uid, "^BOT_") then return print(prefix .. "XAdmin no soporta bots. Ban omitido.") end
        RunConsoleCommand("xadmin", "ban", uid, tostring(mins), reason)
        print(prefix .. "Auto-ban enviado a XADMIN para: " .. uid .. " | Tiempo: " .. mins .. " min.")

    elseif system == "NATIVO" then
        if string.match(uid, "^BOT_") then return print(prefix .. "El sistema nativo de bans no soporta bots.") end
        RunConsoleCommand("banid", tostring(mins), uid)
        RunConsoleCommand("writeid")
        print(prefix .. "Auto-ban NATIVO ejecutado para: " .. uid .. " | Tiempo: " .. mins .. " min.")

    else
        print(prefix .. "ERROR: Sistema admin desconocido '" .. tostring(system) .. "'. No se ejecutó el ban.")
    end
end