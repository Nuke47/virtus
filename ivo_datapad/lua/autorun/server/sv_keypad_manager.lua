if not SERVER then return end
AddCSLuaFile("autorun/client/cl_keypad_manager_ui.lua")

util.AddNetworkString("Datapad_KeypadManager_Open")
util.AddNetworkString("Datapad_KeypadManager_Sync")
util.AddNetworkString("Datapad_KeypadManager_Create")
util.AddNetworkString("Datapad_KeypadManager_Update")
util.AddNetworkString("Datapad_KeypadManager_Delete")
util.AddNetworkString("Datapad_KeypadManager_LinkDoor")

-- Inicializar Base de Datos
hook.Add("Initialize", "IVO_Datapad_InitKeypadsDB", function()
    sql.Query([[
        CREATE TABLE IF NOT EXISTS ivo_datapad_keypads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            map VARCHAR(255),
            pos_x FLOAT, pos_y FLOAT, pos_z FLOAT,
            ang_p FLOAT, ang_y FLOAT, ang_r FLOAT,
            model VARCHAR(255),
            keypad_type INTEGER,
            password VARCHAR(255),
            access_jobs TEXT,
            difficulty INTEGER,
            games VARCHAR(255),
            doors TEXT
        )
    ]])
end)

-- Ejecutar la actualización de la tabla inmediatamente por si no se reinicia el servidor
sql.Query("ALTER TABLE ivo_datapad_keypads ADD COLUMN access_level INTEGER DEFAULT 0")

local function SpawnKeypads()
    local map = game.GetMap()
    local keypads = sql.Query("SELECT * FROM ivo_datapad_keypads WHERE map = " .. sql.SQLStr(map))
    
    if keypads then
        for _, k in ipairs(keypads) do
            local ent = ents.Create("ivo_keypad")
            if not IsValid(ent) then continue end
            
            ent:SetPos(Vector(tonumber(k.pos_x), tonumber(k.pos_y), tonumber(k.pos_z)))
            ent:SetAngles(Angle(tonumber(k.ang_p), tonumber(k.ang_y), tonumber(k.ang_r)))
            
            ent:SetModel(k.model or "models/props_lab/keypad.mdl")
            ent:Spawn()
            
            ent.DB_ID = tonumber(k.id)
            ent:SetKeypadType(tonumber(k.keypad_type) or 0)
            ent.Password = k.password or ""
            ent:SetAccessJobs(k.access_jobs or "")
            ent:SetAccessLevel(tonumber(k.access_level) or 0)
            ent:SetHackDifficulty(tonumber(k.difficulty) or 1)
            ent:SetHackGames(k.games or "1,2,3")
            ent.TargetDoorsData = k.doors or ""
            
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(false)
            end
        end
        print("[Datapad] Se spawnearon " .. #keypads .. " keypads para el mapa " .. map)
    end
end

hook.Add("InitPostEntity", "IVO_Datapad_SpawnKeypads", function()
    SpawnKeypads()
end)

-- Comando para abrir el menú
concommand.Add("swrp_keypad", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    
    -- Recolectar datos y enviarlos al admin
    local map = game.GetMap()
    local keypads = sql.Query("SELECT * FROM ivo_datapad_keypads WHERE map = " .. sql.SQLStr(map)) or {}
    
    net.Start("Datapad_KeypadManager_Open")
    net.WriteUInt(#keypads, 16)
    for _, k in ipairs(keypads) do
        net.WriteUInt(tonumber(k.id), 32)
        net.WriteVector(Vector(tonumber(k.pos_x), tonumber(k.pos_y), tonumber(k.pos_z)))
        net.WriteAngle(Angle(tonumber(k.ang_p), tonumber(k.ang_y), tonumber(k.ang_r)))
        net.WriteString(k.model or "models/props_lab/keypad.mdl")
        net.WriteUInt(tonumber(k.keypad_type) or 0, 4)
        net.WriteString(k.password or "")
        net.WriteString(k.access_jobs or "")
        net.WriteUInt(tonumber(k.access_level) or 0, 4)
        net.WriteUInt(tonumber(k.difficulty) or 1, 16)
        net.WriteString(k.games or "1,2,3")
        net.WriteString(k.doors or "")
    end
    net.Send(ply)
end)

-- Recibir peticiones de creación
net.Receive("Datapad_KeypadManager_Create", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    
    local tr = ply:GetEyeTrace()
    if not tr.Hit then return end
    
    local pos = tr.HitPos
    local ang = tr.HitNormal:Angle()
    ang:RotateAroundAxis(ang:Right(), -90)
    ang:RotateAroundAxis(ang:Up(), 90)
    
    local map = game.GetMap()
    local model = "models/props_lab/keypad.mdl"
    local query = string.format([[
        INSERT INTO ivo_datapad_keypads (map, pos_x, pos_y, pos_z, ang_p, ang_y, ang_r, model, keypad_type, password, access_jobs, access_level, difficulty, games, doors)
        VALUES (%s, %f, %f, %f, %f, %f, %f, %s, 0, '', '', 0, 1, '1,2,3', '')
    ]], 
    sql.SQLStr(map), pos.x, pos.y, pos.z, ang.p, ang.y, ang.r, sql.SQLStr(model))
    
    sql.Query(query)
    
    local newID = sql.QueryValue("SELECT seq FROM sqlite_sequence WHERE name='ivo_datapad_keypads'")
    if not newID then newID = 1 end
    
    -- Spawn immediate
    local ent = ents.Create("ivo_keypad")
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:SetModel(model)
    ent:Spawn()
    ent.DB_ID = tonumber(newID)
    ent:SetKeypadType(0)
    ent.Password = ""
    ent:SetAccessJobs("")
    ent:SetAccessLevel(0)
    ent:SetHackDifficulty(1)
    ent:SetHackGames("1,2,3")
    ent.TargetDoorsData = ""
    
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    
    ply:ChatPrint("[Keypads] Keypad creado y guardado.")
    ply:ConCommand("swrp_keypad") -- Refrescar
end)

-- Recibir actualización
net.Receive("Datapad_KeypadManager_Update", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    
    local id = net.ReadUInt(32)
    local model = net.ReadString()
    local kType = net.ReadUInt(4)
    local pass = net.ReadString()
    local access = net.ReadString()
    local accessLvl = net.ReadUInt(4)
    local diff = net.ReadUInt(16)
    local games = net.ReadString()
    local doors = net.ReadString()
    
    sql.Query(string.format([[
        UPDATE ivo_datapad_keypads SET
        model = %s, keypad_type = %d, password = %s, access_jobs = %s, access_level = %d, difficulty = %d, games = %s, doors = %s
        WHERE id = %d
    ]], sql.SQLStr(model), kType, sql.SQLStr(pass), sql.SQLStr(access), accessLvl, diff, sql.SQLStr(games), sql.SQLStr(doors), id))
    
    -- Update in-game entity
    for _, ent in ipairs(ents.FindByClass("ivo_keypad")) do
        if ent.DB_ID == id then
            ent:SetModel(model)
            ent:SetKeypadType(kType)
            ent.Password = pass
            ent:SetAccessJobs(access)
            ent:SetAccessLevel(accessLvl)
            ent:SetHackDifficulty(diff)
            ent:SetHackGames(games)
            ent.TargetDoorsData = doors
            break
        end
    end
    
    ply:ChatPrint("[Keypads] Configuración guardada.")
    ply:ConCommand("swrp_keypad")
end)

-- Recibir borrado
net.Receive("Datapad_KeypadManager_Delete", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local id = net.ReadUInt(32)
    
    sql.Query("DELETE FROM ivo_datapad_keypads WHERE id = " .. id)
    
    for _, ent in ipairs(ents.FindByClass("ivo_keypad")) do
        if ent.DB_ID == id then
            ent:Remove()
            break
        end
    end
    
    ply:ChatPrint("[Keypads] Keypad eliminado.")
    ply:ConCommand("swrp_keypad")
end)
