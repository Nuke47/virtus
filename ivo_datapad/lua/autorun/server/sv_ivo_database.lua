if not SERVER then return end

IvoDB = IvoDB or {}

util.AddNetworkString("Datapad_Warrant_Add")
util.AddNetworkString("Datapad_Warrant_Clear")

-- Inicializar la base de datos
function IvoDB.Init()
    local q = [[
        CREATE TABLE IF NOT EXISTS ivo_datapad_records (
            SteamID TEXT,
            IsCivilian INTEGER,
            Arrests INTEGER DEFAULT 0,
            Warrant INTEGER DEFAULT 0,
            PRIMARY KEY (SteamID, IsCivilian)
        )
    ]]
    sql.Query(q)
end

hook.Add("Initialize", "IvoDB_Init", IvoDB.Init)
IvoDB.Init() -- Llamar en caliente si el archivo se recarga

-- Obtener registro de un jugador
function IvoDB.GetRecord(ply, isCivilian)
    local civInt = isCivilian and 1 or 0
    local sid = ply:SteamID64()
    if not sid then return { arrests = 0, warrant = false } end
    
    local q = string.format("SELECT Arrests, Warrant FROM ivo_datapad_records WHERE SteamID = %s AND IsCivilian = %d", sql.SQLStr(sid), civInt)
    local result = sql.Query(q)
    
    if result and result[1] then
        return {
            arrests = tonumber(result[1].Arrests) or 0,
            warrant = tonumber(result[1].Warrant) == 1
        }
    end
    
    return { arrests = 0, warrant = false }
end

-- Sumar arresto
function IvoDB.AddArrest(ply, isCivilian)
    local civInt = isCivilian and 1 or 0
    local sid = ply:SteamID64()
    if not sid then return end
    
    local record = IvoDB.GetRecord(ply, isCivilian)
    local newArrests = record.arrests + 1
    
    local q = string.format("INSERT OR REPLACE INTO ivo_datapad_records (SteamID, IsCivilian, Arrests, Warrant) VALUES (%s, %d, %d, %d)", 
        sql.SQLStr(sid), civInt, newArrests, record.warrant and 1 or 0)
    
    sql.Query(q)
end

-- Establecer estado de prófugo (Warrant) por SteamID64
function IvoDB.SetWarrantByID(sid, isCivilian, state)
    local civInt = isCivilian and 1 or 0
    local warrantInt = state and 1 or 0
    
    local checkQ = string.format("SELECT Arrests FROM ivo_datapad_records WHERE SteamID = %s AND IsCivilian = %d", sql.SQLStr(sid), civInt)
    local result = sql.Query(checkQ)
    
    local arrests = 0
    if result and result[1] then
        arrests = tonumber(result[1].Arrests) or 0
    end
    
    local q = string.format("INSERT OR REPLACE INTO ivo_datapad_records (SteamID, IsCivilian, Arrests, Warrant) VALUES (%s, %d, %d, %d)", 
        sql.SQLStr(sid), civInt, arrests, warrantInt)
    
    sql.Query(q)
end

function IvoDB.SetWarrant(ply, isCivilian, state)
    local sid = ply:SteamID64()
    if not sid then return end
    IvoDB.SetWarrantByID(sid, isCivilian, state)
end

-- Networking para Emitir / Quitar Búsqueda
net.Receive("Datapad_Warrant_Add", function(len, ply)
    local target = net.ReadEntity()
    if not IsValid(target) or not target:IsPlayer() then return end
    
    if not (Datapad and Datapad.HasAccess) then return end
    if not Datapad:HasAccess(ply, Datapad.Config.ShockJobs) and not Datapad:HasAccess(ply, Datapad.Config.RiotJobs) then return end
    
    local isCivilian = net.ReadBool()
    IvoDB.SetWarrant(target, isCivilian, true)
    
    ply:PrintMessage(HUD_PRINTTALK, "[65TH] Se ha emitido orden de captura para " .. target:Nick())
end)

net.Receive("Datapad_Warrant_Clear", function(len, ply)
    local target = net.ReadEntity()
    if not IsValid(target) or not target:IsPlayer() then return end
    
    if not (Datapad and Datapad.HasAccess) then return end
    if not Datapad:HasAccess(ply, Datapad.Config.ShockJobs) and not Datapad:HasAccess(ply, Datapad.Config.RiotJobs) then return end
    
    local isCivilian = net.ReadBool()
    IvoDB.SetWarrant(target, isCivilian, false)
    
    ply:PrintMessage(HUD_PRINTTALK, "[65TH] Se ha limpiado el registro de búsqueda de " .. target:Nick())
end)
