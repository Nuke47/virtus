-- Sistema Centralizado de Base de Datos para IVO Framework
-- Actúa como puente para usar la conexión MySQL de SAM si existe, o SQLite en su defecto.

IVO_FW = IVO_FW or {}
IVO_FW.DB = IVO_FW.DB or {}

-- Wrapper centralizado para hacer consultas (Queries)
function IVO_FW.DB.Query(queryStr, callback)
    if IVO_SAM and IVO_SAM.DB and IVO_SAM.DB.Query then
        IVO_SAM.DB.Query(queryStr, callback)
    else
        -- Fallback a SQLite local si SAM no está instalado
        local data = sql.Query(queryStr)
        if data == false then
            print("[IVO Framework] SQLite Error: " .. sql.LastError() .. " (Query: " .. queryStr .. ")")
            if callback then callback(false, sql.LastError()) end
        else
            if callback then callback(data) end
        end
    end
end

-- Wrapper centralizado para escapar strings (Prevención de inyección SQL)
function IVO_FW.DB.Escape(str)
    if IVO_SAM and IVO_SAM.DB and IVO_SAM.DB.Escape then
        return IVO_SAM.DB.Escape(str)
    else
        return sql.SQLStr(str)
    end
end

-- Hook que se ejecuta cuando la base de datos central de SAM está lista
hook.Add("IVOSAM_DatabaseConnected", "IVOFW_InitializeTables", function()
    print("[IVO Framework] Conexión central a Base de Datos detectada. Las tablas existentes serán consultadas.")
    
    -- Si alguna vez necesitas crear nuevas tablas, agrégalas aquí en lugar de crear conexiones nuevas en los addons.
    local queries = {
        -- Whitelist
        "CREATE TABLE IF NOT EXISTS virtus_whitelist (steamid VARCHAR(64), job_cmd VARCHAR(128), list_type VARCHAR(32), PRIMARY KEY(steamid, job_cmd, list_type))",
        
        -- Puedes ir moviendo aquí los CREATE TABLE IF NOT EXISTS de los demás addons en el futuro.
    }

    for _, q in ipairs(queries) do
        IVO_FW.DB.Query(q)
    end
    
    -- Avisamos a los demás scripts del framework que la BD está lista
    hook.Run("IVOFW_DatabaseReady")
end)
