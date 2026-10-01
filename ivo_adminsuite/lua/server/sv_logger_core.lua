IvoLogsSystem.Logs = IvoLogsSystem.Logs or {}

-- 1. Actualizamos la tabla para incluir 'extradata'
sql.Query("CREATE TABLE IF NOT EXISTS server_deeplogs (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp TEXT, category TEXT, message TEXT, extradata TEXT)")

-- 2. Actualizamos AddLog para aceptar 'extra'
function IvoLogsSystem.AddLog(category, message, extra)
    local timeStr = os.date("%H:%M:%S - %d/%m/%Y")
    local extraTable = extra or {}
    
    -- Convertimos la tabla a formato JSON para guardarla en SQL
    local extraJSON = util.TableToJSON(extraTable)

    local safeCat = sql.SQLStr(category)
    local safeMsg = sql.SQLStr(message)
    local safeTime = sql.SQLStr(timeStr)
    local safeExtra = sql.SQLStr(extraJSON)

    -- Guardamos en SQL incluyendo la nueva columna
    sql.Query("INSERT INTO server_deeplogs (timestamp, category, message, extradata) VALUES (" .. safeTime .. ", " .. safeCat .. ", " .. safeMsg .. ", " .. safeExtra .. ")")

    local logEntry = {
        time = timeStr,
        category = category,
        msg = message,
        extra = extraTable -- Guardamos la tabla en memoria
    }

    table.insert(IvoLogsSystem.Logs, 1, logEntry)

    -- [REPARADO] Control de memoria aumentado por defecto a 1000 para soportar la paginación
    local maxMemory = 20000
    if IvoLogsSystem.Config and IvoLogsSystem.Config.MaxLogsMemory then
        maxMemory = IvoLogsSystem.Config.MaxLogsMemory
    end

    if #IvoLogsSystem.Logs > maxMemory then
        table.remove(IvoLogsSystem.Logs)
    end
end

function IvoLogsSystem.GetDeepLogs(limit)
    limit = limit or 500

    local query = "SELECT timestamp as time, category, message as msg FROM server_deeplogs ORDER BY id DESC LIMIT " .. limit
    local result = sql.Query(query)

    return result or {}
end

-- [REPARADO] Función de envío optimizada y sin límites forzados a 100
function IvoLogsSystem.SendMenu(ply)
    -- Validación de Config segura
    local isAdminOnly = true
    if IvoLogsSystem.Config and IvoLogsSystem.Config.AdminOnly ~= nil then
        isAdminOnly = IvoLogsSystem.Config.AdminOnly
    end

    if isAdminOnly and not ply:IsAdmin() then
        ply:ChatPrint("No tienes permisos para ver los logs.")
        return 
    end
    
    -- Recolectamos TODOS los logs actualmente en memoria (sin recortar a 100)
    local toSend = IvoLogsSystem.Logs or {}
    
    -- Convertimos a JSON y comprimimos para no saturar los 64KB de la red de GMod
    local jsonStr = util.TableToJSON(toSend)
    local compressedData = util.Compress(jsonStr)
    local bytesCount = #compressedData

    net.Start("IvoLogs_OpenMenu")
        net.WriteUInt(bytesCount, 32)        -- Tamaño del paquete comprimido
        net.WriteData(compressedData, bytesCount) -- Datos puros comprimidos
    net.Send(ply)
end

concommand.Add("ivo_logs", function(ply, cmd, args)
    if IsValid(ply) then
        IvoLogsSystem.SendMenu(ply)
    end
end)

-- ==========================================================
-- [DEEP STORAGE] COMUNICACIÓN Y LOGS HISTÓRICOS
-- ==========================================================
util.AddNetworkString("IvoLogs_RequestDeepStorage")
util.AddNetworkString("IvoLogs_SendDeepStorage")

-- Reescribimos/Aseguramos la función para que lea 'extradata'
function IvoLogsSystem.GetDeepLogs(limit)
    limit = limit or 500
    -- Extraemos todas las columnas necesarias, incluyendo extradata
    local query = "SELECT timestamp as time, category, message as msg, extradata FROM server_deeplogs ORDER BY id DESC LIMIT " .. limit
    local result = sql.Query(query)

    if not result then return {} end

    -- Procesamos las filas para decodificar el JSON de la metadata extra antes de enviarlo
    for _, log in ipairs(result) do
        if log.extradata then
            log.extra = util.JSONToTable(log.extradata) or {}
            log.extradata = nil -- Limpiamos el texto plano
        else
            log.extra = {}
        end
    end

    return result
end

net.Receive("IvoLogs_RequestDeepStorage", function(len, ply)
    if not IsValid(ply) then return end
    
    -- Verificamos permisos con tu configuración nativa
    local isAdminOnly = true
    if IvoLogsSystem.Config and IvoLogsSystem.Config.AdminOnly ~= nil then
        isAdminOnly = IvoLogsSystem.Config.AdminOnly
    end
    if isAdminOnly and not ply:IsAdmin() then return end

    -- Obtenemos hasta 500 registros antiguos de la base de datos SQL
    local deepLogs = IvoLogsSystem.GetDeepLogs(500)

    -- Lo empaquetamos, comprimimos y mandamos al administrador
    local jsonStr = util.TableToJSON(deepLogs)
    local compressedData = util.Compress(jsonStr)
    local bytesCount = #compressedData

    net.Start("IvoLogs_SendDeepStorage")
        net.WriteUInt(bytesCount, 32)
        net.WriteData(compressedData, bytesCount)
    net.Send(ply)
end)