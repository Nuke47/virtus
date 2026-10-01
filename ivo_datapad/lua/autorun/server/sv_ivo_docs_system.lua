if not SERVER then return end

util.AddNetworkString("IVO_Docs_Create")
util.AddNetworkString("IVO_Docs_Delete")
util.AddNetworkString("IVO_Docs_Transfer")
util.AddNetworkString("IVO_Docs_Sync")
util.AddNetworkString("IVO_Docs_RequestSync")
util.AddNetworkString("IVO_Docs_AdminSave")
util.AddNetworkString("IVO_Docs_AdminSave_Trigger")
util.AddNetworkString("IVO_Docs_AdminSaveContent")
util.AddNetworkString("IVO_Docs_StartExtraction")

net.Receive("IVO_Docs_AdminSave", function(len, ply)
    if not ply:IsSuperAdmin() then return end
    local ent = net.ReadEntity()
    local mdl = net.ReadString()
    local access = net.ReadString()
    local diff = net.ReadUInt(16)
    local download = net.ReadUInt(16)
    local games = net.ReadString()
    
    if IsValid(ent) and ent:GetClass() == "ent_ivo_docs_console" then
        ent:SetConsoleModel(mdl)
        ent:SetAccessJobs(access)
        ent:SetHackDifficulty(diff)
        if download and download > 0 then ent:SetDownloadTime(download) end
        if games then ent:SetHackGames(games) end
        ply:ChatPrint("[Consola] Configuración guardada correctamente.")
    end
end)

net.Receive("IVO_Docs_AdminSaveContent", function(len, ply)
    if not ply:IsSuperAdmin() then return end
    local ent = net.ReadEntity()
    local title = net.ReadString()
    local content = net.ReadString()
    
    if IsValid(ent) and ent:GetClass() == "ent_ivo_docs_console" then
        ent:SetDocTitle(title)
        ent:SetDocContent(content)
        ply:ChatPrint("[Consola] Contenido del documento guardado en la terminal.")
    end
end)

net.Receive("IVO_Docs_StartExtraction", function(len, ply)
    local ent = net.ReadEntity()
    if IsValid(ent) and ent:GetClass() == "ent_ivo_docs_console" then
        ent:StartExtraction(ply)
    end
end)

-- Initialize Database
hook.Add("Initialize", "IVO_Docs_InitDB", function()
    sql.Query([[
        CREATE TABLE IF NOT EXISTS ivo_datapad_docs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            owner_id VARCHAR(255),
            title VARCHAR(255),
            content TEXT,
            timestamp INTEGER
        )
    ]])
end)

-- Fetch documents for a specific player (by SteamID64 / AccountID)
local function GetPlayerDocs(ply)
    local accountID = ply:AccountID()
    local docs = sql.Query("SELECT * FROM ivo_datapad_docs WHERE owner_id = " .. sql.SQLStr(tostring(accountID)) .. " ORDER BY timestamp DESC")
    return docs or {}
end

-- Sync documents to the client
local function SyncPlayerDocs(ply)
    local docs = GetPlayerDocs(ply)
    
    net.Start("IVO_Docs_Sync")
    net.WriteUInt(#docs, 16)
    for _, doc in ipairs(docs) do
        net.WriteUInt(tonumber(doc.id), 32)
        net.WriteString(doc.title)
        net.WriteString(doc.content)
        net.WriteUInt(tonumber(doc.timestamp), 32)
    end
    net.Send(ply)
end

-- Client requested a sync (e.g. when opening the datapad docs list)
net.Receive("IVO_Docs_RequestSync", function(len, ply)
    SyncPlayerDocs(ply)
end)

-- Create a new document (Network)
net.Receive("IVO_Docs_Create", function(len, ply)
    local title = net.ReadString()
    local content = net.ReadString()
    IVO_Docs_InjectDocument(ply, title, content)
end)

-- Inject a document directly (Server-Side)
function IVO_Docs_InjectDocument(ply, title, content)
    if not IsValid(ply) then return end
    
    -- Anti-Spam / Size limit
    if #title > 50 then title = string.sub(title, 1, 50) end
    if #content > 5000 then content = string.sub(content, 1, 5000) end
    
    local accountID = tostring(ply:AccountID())
    local ts = os.time()
    
    local query = string.format("INSERT INTO ivo_datapad_docs (owner_id, title, content, timestamp) VALUES (%s, %s, %s, %s)",
        sql.SQLStr(accountID),
        sql.SQLStr(title),
        sql.SQLStr(content),
        ts
    )
    sql.Query(query)
    
    ply:ChatPrint("[Docs] Documento guardado en tu Datapad personal.")
    SyncPlayerDocs(ply)
end

-- Delete a document
net.Receive("IVO_Docs_Delete", function(len, ply)
    local docID = net.ReadUInt(32)
    local accountID = tostring(ply:AccountID())
    
    sql.Query("DELETE FROM ivo_datapad_docs WHERE id = " .. docID .. " AND owner_id = " .. sql.SQLStr(accountID))
    ply:ChatPrint("[Docs] Documento eliminado.")
    SyncPlayerDocs(ply)
end)

-- Transfer a document
net.Receive("IVO_Docs_Transfer", function(len, ply)
    local docID = net.ReadUInt(32)
    local targetPly = net.ReadEntity()
    
    if not IsValid(targetPly) or not targetPly:IsPlayer() then
        ply:ChatPrint("[Docs] Objetivo inválido.")
        return
    end
    
    local accountID = tostring(ply:AccountID())
    local targetAccountID = tostring(targetPly:AccountID())
    
    -- Verify ownership
    local verify = sql.QueryValue("SELECT id FROM ivo_datapad_docs WHERE id = " .. docID .. " AND owner_id = " .. sql.SQLStr(accountID))
    if verify then
        -- We transfer ownership completely
        sql.Query("UPDATE ivo_datapad_docs SET owner_id = " .. sql.SQLStr(targetAccountID) .. " WHERE id = " .. docID)
        ply:ChatPrint("[Docs] Has transferido el documento a " .. targetPly:Nick() .. ".")
        targetPly:ChatPrint("[Docs] Has recibido un nuevo documento de " .. ply:Nick() .. ".")
        
        -- Sync both
        SyncPlayerDocs(ply)
        SyncPlayerDocs(targetPly)
    else
        ply:ChatPrint("[Docs] Error de transferencia: Documento no encontrado o no autorizado.")
    end
end)
