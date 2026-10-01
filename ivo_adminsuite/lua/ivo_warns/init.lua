-- ==========================================
-- IVO_WARNS - SERVIDOR (CORE)
-- ==========================================

util.AddNetworkString("IvoWarns_OpenMenu")
util.AddNetworkString("IvoWarns_RequestPlayers")
util.AddNetworkString("IvoWarns_SendPlayers")
util.AddNetworkString("IvoWarns_RequestWarns")
util.AddNetworkString("IvoWarns_SendWarns")
util.AddNetworkString("IvoWarns_DeleteSingle")
util.AddNetworkString("IvoWarns_DeleteAll")

local DECAY_TIME = IVO_WARNS.Config.DecayDays * 24 * 60 * 60

-- ==========================================
-- INICIALIZACIÓN DE BASE DE DATOS
-- ==========================================
IVO_WARNS.DB = IVO_WARNS.DB or {}

if IVO_WARNS.Config.USE_MYSQL then
    require("mysqloo")
    local db = mysqloo.connect(
        IVO_WARNS.Config.DB_HOST,
        IVO_WARNS.Config.DB_USER,
        IVO_WARNS.Config.DB_PASS,
        IVO_WARNS.Config.DB_NAME,
        IVO_WARNS.Config.DB_PORT
    )
    function db:onConnected()
        print("[Ivo_Warns] MySQL Connected!")
        IVO_WARNS.DB.InitTables()
    end
    function db:onConnectionFailed(err)
        print("[Ivo_Warns] MySQL Connection Failed: " .. err)
    end
    db:connect()
    IVO_WARNS.DB.Connection = db

    function IVO_WARNS.DB.Query(queryStr, callback)
        if not IVO_WARNS.DB.Connection then return end
        local q = IVO_WARNS.DB.Connection:query(queryStr)
        q.onSuccess = function(_, data)
            if data and #data == 0 then data = nil end
            if callback then callback(data) end
        end
        q.onError = function(_, err)
            print("[Ivo_Warns] MySQL Error: " .. err .. " (Query: " .. queryStr .. ")")
            if callback then callback(false, err) end
        end
        q:start()
    end
    
    function IVO_WARNS.DB.Escape(str)
        if not IVO_WARNS.DB.Connection then return sql.SQLStr(str) end
        return "'" .. IVO_WARNS.DB.Connection:escape(tostring(str)) .. "'"
    end
else
    function IVO_WARNS.DB.Query(queryStr, callback)
        local data = sql.Query(queryStr)
        if callback then callback(data) end
    end
    function IVO_WARNS.DB.Escape(str)
        return sql.SQLStr(str)
    end
    timer.Simple(0, function() IVO_WARNS.DB.InitTables() end)
end

function IVO_WARNS.DB.QueryValue(queryStr, callback)
    IVO_WARNS.DB.Query(queryStr, function(data)
        if data and data[1] then
            local _, val = next(data[1])
            if callback then callback(val) end
        else
            if callback then callback(nil) end
        end
    end)
end

function IVO_WARNS.DB.InitTables()
    if IVO_WARNS.Config.USE_MYSQL then
        IVO_WARNS.DB.Query("CREATE TABLE IF NOT EXISTS ivo_warns_players (steamid VARCHAR(255) PRIMARY KEY, name TEXT, last_warn INT)")
        IVO_WARNS.DB.Query("CREATE TABLE IF NOT EXISTS ivo_warns_records (id INT PRIMARY KEY AUTO_INCREMENT, steamid VARCHAR(255), admin TEXT, reason TEXT, time INT, is_deleted INT DEFAULT 0, delete_reason TEXT, delete_admin TEXT)")
    else
        IVO_WARNS.DB.Query("CREATE TABLE IF NOT EXISTS ivo_warns_players (steamid TEXT PRIMARY KEY, name TEXT, last_warn INTEGER)")
        IVO_WARNS.DB.Query("CREATE TABLE IF NOT EXISTS ivo_warns_records (id INTEGER PRIMARY KEY AUTOINCREMENT, steamid TEXT, admin TEXT, reason TEXT, time INTEGER, is_deleted INTEGER DEFAULT 0, delete_reason TEXT, delete_admin TEXT)")
        
        local table_info = sql.Query("PRAGMA table_info(ivo_warns_records)")
        local has_deleted_col = false
        if table_info then
            for _, col in ipairs(table_info) do
                if col.name == "is_deleted" then
                    has_deleted_col = true
                    break
                end
            end
        end
        if not has_deleted_col then
            print("[Ivo_Warns] Detectada base de datos antigua. Actualizando esquema...")
            sql.Query("ALTER TABLE ivo_warns_records ADD COLUMN is_deleted INTEGER DEFAULT 0")
            sql.Query("ALTER TABLE ivo_warns_records ADD COLUMN delete_reason TEXT")
            sql.Query("ALTER TABLE ivo_warns_records ADD COLUMN delete_admin TEXT")
            print("[Ivo_Warns] ¡Base de datos actualizada con éxito!")
        end
    end
end

-- ==========================================
-- FUNCIONES DE UTILIDAD
-- ==========================================

local function GetPlayerUID(ply)
    if not IsValid(ply) then return "UNKNOWN" end
    if ply:IsBot() then
        return "BOT_" .. string.gsub(ply:Nick(), "%s+", "_")
    end
    local sid = ply:SteamID()
    if not sid or sid == "BOT" then
        return "BOT_" .. string.gsub(ply:Nick(), "%s+", "_")
    end
    return sid
end

hook.Add("PlayerInitialSpawn", "IvoWarns_RegisterAllPlayers", function(ply)
    timer.Simple(2, function()
        if not IsValid(ply) then return end
        local uid  = GetPlayerUID(ply)
        local name = ply:Nick()

        IVO_WARNS.DB.QueryValue("SELECT steamid FROM ivo_warns_players WHERE steamid = " .. IVO_WARNS.DB.Escape(uid), function(exists)
            if not exists then
                IVO_WARNS.DB.Query(
                    "INSERT INTO ivo_warns_players (steamid, name, last_warn) VALUES ("
                    .. IVO_WARNS.DB.Escape(uid) .. ", " .. IVO_WARNS.DB.Escape(name) .. ", 0)"
                )
            else
                IVO_WARNS.DB.Query("UPDATE ivo_warns_players SET name = " .. IVO_WARNS.DB.Escape(name) .. " WHERE steamid = " .. IVO_WARNS.DB.Escape(uid))
            end
        end)
    end)
end)

local function GetCombinedPlayers(callback)
    local list = {}
    local map  = {}

    local players_online = player.GetAll()
    local pending = #players_online
    
    if pending == 0 then
        IVO_WARNS.DB.Query("SELECT steamid, name, last_warn FROM ivo_warns_players", function(db_players)
            db_players = db_players or {}
            for _, p in ipairs(db_players) do
                if not map[p.steamid] then
                    table.insert(list, { steamid = p.steamid, name = p.name, last_warn = tonumber(p.last_warn) or 0, is_online = false })
                    map[p.steamid] = true
                end
            end
            table.sort(list, function(a, b)
                if a.is_online ~= b.is_online then return a.is_online end
                return string.lower(a.name) < string.lower(b.name)
            end)
            if callback then callback(list) end
        end)
        return
    end

    for _, ply in ipairs(players_online) do
        local uid = GetPlayerUID(ply)
        if not uid then
            pending = pending - 1
            if pending == 0 then
                IVO_WARNS.DB.Query("SELECT steamid, name, last_warn FROM ivo_warns_players", function(db_players)
                    db_players = db_players or {}
                    for _, p in ipairs(db_players) do
                        if not map[p.steamid] then
                            table.insert(list, { steamid = p.steamid, name = p.name, last_warn = tonumber(p.last_warn) or 0, is_online = false })
                            map[p.steamid] = true
                        end
                    end
                    table.sort(list, function(a, b)
                        if a.is_online ~= b.is_online then return a.is_online end
                        return string.lower(a.name) < string.lower(b.name)
                    end)
                    if callback then callback(list) end
                end)
            end
            continue 
        end

        IVO_WARNS.DB.QueryValue("SELECT last_warn FROM ivo_warns_players WHERE steamid = " .. IVO_WARNS.DB.Escape(uid), function(lastw)
            table.insert(list, { steamid = uid, name = ply:Nick(), last_warn = tonumber(lastw) or 0, is_online = true })
            map[uid] = true
            pending = pending - 1
            
            if pending == 0 then
                IVO_WARNS.DB.Query("SELECT steamid, name, last_warn FROM ivo_warns_players", function(db_players)
                    db_players = db_players or {}
                    for _, p in ipairs(db_players) do
                        if not map[p.steamid] then
                            table.insert(list, { steamid = p.steamid, name = p.name, last_warn = tonumber(p.last_warn) or 0, is_online = false })
                            map[p.steamid] = true
                        end
                    end
                    table.sort(list, function(a, b)
                        if a.is_online ~= b.is_online then return a.is_online end
                        return string.lower(a.name) < string.lower(b.name)
                    end)
                    if callback then callback(list) end
                end)
            end
        end)
    end
end

-- ==========================================
-- FUNCIONES PRINCIPALES
-- ==========================================

local function RefreshAdminMenu(admin, steamid)
    if not IsValid(admin) then return end

    GetCombinedPlayers(function(players)
        if not IsValid(admin) then return end
        net.Start("IvoWarns_SendPlayers")
        net.WriteUInt(#players, 16)
        for _, p in ipairs(players) do
            net.WriteString(p.steamid)
            local display_name = p.is_online and ("[ON] " .. p.name) or p.name
            net.WriteString(display_name)
            net.WriteUInt(tonumber(p.last_warn) or 0, 32)
        end
        net.Send(admin)
        
        IVO_WARNS.DB.Query(
            "SELECT id, admin, reason, time, is_deleted, delete_reason, delete_admin FROM ivo_warns_records"
            .. " WHERE steamid = " .. IVO_WARNS.DB.Escape(steamid) .. " ORDER BY time DESC", 
            function(warns)
                warns = warns or {}
                if not IsValid(admin) then return end
                net.Start("IvoWarns_SendWarns")
                net.WriteUInt(#warns, 16)
                for _, w in ipairs(warns) do
                    net.WriteUInt(tonumber(w.id), 32)
                    net.WriteString(w.admin)
                    net.WriteString(w.reason)
                    net.WriteUInt(tonumber(w.time) or 0, 32)
                    net.WriteBit(tonumber(w.is_deleted) == 1)
                    net.WriteString(w.delete_reason or "")
                    net.WriteString(w.delete_admin or "")
                end
                net.Send(admin)
            end
        )
    end)
end

local function AddWarn(admin, target_uid, target_name, reason)
    local admin_name   = IsValid(admin) and admin:Nick() or "Consola"
    local current_time = os.time()
    local prefix       = IVO_WARNS.Config.Prefix

    local sid64 = (string.StartWith(target_uid, "STEAM_")) and util.SteamIDTo64(target_uid) or target_uid
    if sid64 == "0" then sid64 = target_uid end

    local function proceedWithAddWarn()
        IVO_WARNS.DB.QueryValue("SELECT steamid FROM ivo_warns_players WHERE steamid = " .. IVO_WARNS.DB.Escape(target_uid), function(ply_exists)
            if ply_exists then
                IVO_WARNS.DB.Query("UPDATE ivo_warns_players SET name = " .. IVO_WARNS.DB.Escape(target_name) .. ", last_warn = " .. current_time .. " WHERE steamid = " .. IVO_WARNS.DB.Escape(target_uid))
            else
                IVO_WARNS.DB.Query("INSERT INTO ivo_warns_players (steamid, name, last_warn) VALUES (" .. IVO_WARNS.DB.Escape(target_uid) .. ", " .. IVO_WARNS.DB.Escape(target_name) .. ", " .. current_time .. ")")
            end

            IVO_WARNS.DB.Query("INSERT INTO ivo_warns_records (steamid, admin, reason, time) VALUES (" .. IVO_WARNS.DB.Escape(target_uid) .. ", " .. IVO_WARNS.DB.Escape(admin_name) .. ", " .. IVO_WARNS.DB.Escape(reason) .. ", " .. current_time .. ")")

            if IsValid(admin) then
                admin:ChatPrint(prefix .. "Has warneado a " .. target_name .. " (" .. target_uid .. ") por: " .. reason)
                RefreshAdminMenu(admin, target_uid)
            end

            local target_ply = player.GetBySteamID64(sid64) or player.GetBySteamID(target_uid)
            local threshold_time = current_time - DECAY_TIME
            
            IVO_WARNS.DB.QueryValue(
                "SELECT COUNT(*) FROM ivo_warns_records WHERE steamid = " .. IVO_WARNS.DB.Escape(target_uid)
                .. " AND is_deleted = 0 AND time > " .. threshold_time,
                function(active_count)
                    active_count = tonumber(active_count) or 0

                    if IVO_WARNS.Config.EnableAutoBan and IVO_WARNS.Config.AutoBans[active_count] then
                        local ban_mins   = IVO_WARNS.Config.AutoBans[active_count]
                        local ban_reason = "Acumulación de advertencias: Alcanzaste " .. active_count .. " warns activos."
                        for _, v in ipairs(player.GetAll()) do
                            v:ChatPrint(prefix .. target_name .. " fue baneado automáticamente por alcanzar " .. active_count .. " warns.")
                        end
                        IVO_WARNS.ExecuteBan(target_uid, ban_mins, ban_reason)

                    elseif IVO_WARNS.Config.EnableAutoKick and IVO_WARNS.Config.AutoKicks[active_count] then
                        if IsValid(target_ply) then
                            local kick_reason = "Acumulación de advertencias: Alcanzaste " .. active_count .. " warns."
                            for _, v in ipairs(player.GetAll()) do
                                v:ChatPrint(prefix .. target_name .. " fue expulsado automáticamente por alcanzar " .. active_count .. " warns.")
                            end
                            target_ply:Kick("[Ivo_Warns] " .. kick_reason)
                        end
                    end
                end
            )
        end)
    end

    if IVO_SAM and IVO_SAM.DB then
        IVO_SAM.DB.Query("SELECT name FROM ivosam_users WHERE steamid64 = " .. IVO_SAM.DB.Escape(sid64) .. " LIMIT 1;", function(checkUser)
            if checkUser and checkUser[1] and checkUser[1].name then
                target_name = checkUser[1].name
                proceedWithAddWarn()
            else
                IVO_SAM.DB.Query("SELECT name FROM ivosam_playtime WHERE steamid64 = " .. IVO_SAM.DB.Escape(sid64) .. " LIMIT 1;", function(checkHistory)
                    if checkHistory and checkHistory[1] and checkHistory[1].name then
                        target_name = checkHistory[1].name
                    end
                    if not target_name or target_name == "" or target_name == "Desconocido/Offline" then
                        target_name = target_uid
                    end
                    proceedWithAddWarn()
                end)
            end
        end)
    else
        if not target_name or target_name == "" or target_name == "Desconocido/Offline" then
            target_name = target_uid
        end
        proceedWithAddWarn()
    end
end

-- ==========================================
-- COMANDOS DE CHAT
-- ==========================================

hook.Add("PlayerSay", "IvoWarns_ChatCommands", function(ply, text)
    local args = {}
    for match in string.gmatch(text, "[^%s]+") do
        table.insert(args, match)
    end

    local cmd    = string.lower(args[1] or "")
    local prefix = IVO_WARNS.Config.Prefix

    if cmd == IVO_WARNS.Config.CmdWarn then
        if #args == 1 then
            net.Start("IvoWarns_OpenMenu")
            net.Send(ply)
            return ""
        else
            if not IVO_WARNS.IsAdmin(ply) then 
                ply:ChatPrint(prefix .. "No tienes permisos para advertir a otros jugadores.")
                return "" 
            end

            local target_name = args[2]
            local reason      = table.concat(args, " ", 3)

            if reason == "" then
                ply:ChatPrint(prefix .. "Debes especificar una razón.")
                return ""
            end

            local target_ply = nil
            for _, v in ipairs(player.GetAll()) do
                if string.find(string.lower(v:Nick()), string.lower(target_name), 1, true) then
                    target_ply = v
                    break
                end
            end

            if IsValid(target_ply) then
                local uid = GetPlayerUID(target_ply)
                AddWarn(ply, uid, target_ply:Nick(), reason)
                if not target_ply:IsBot() then
                    target_ply:ChatPrint(prefix .. "Has sido warneado por: " .. reason)
                end
            else
                ply:ChatPrint(prefix .. "Jugador activo no encontrado. Usa " .. IVO_WARNS.Config.CmdWarnID .. " para offline.")
            end
            return ""
        end

       elseif cmd == IVO_WARNS.Config.CmdWarnID then
        if not IVO_WARNS.IsAdmin(ply) then return end

        if #args < 3 then
            ply:ChatPrint(prefix .. "Uso: " .. IVO_WARNS.Config.CmdWarnID .. " <steamid> <razón>")
            return ""
        end

        local target_uid = args[2]
        local reason     = table.concat(args, " ", 3)

        if reason == "" then
            ply:ChatPrint(prefix .. "Debes especificar una razón.")
            return ""
        end

        local target_name = nil 

        for _, v in ipairs(player.GetAll()) do
            local v_uid = GetPlayerUID(v)
            if v_uid == target_uid or (not v:IsBot() and (v:SteamID() == target_uid or v:SteamID64() == target_uid)) then
                target_name = v:Nick()
                if not v:IsBot() then
                    v:ChatPrint(prefix .. "Has sido warneado por: " .. reason)
                end
                break
            end
        end

        AddWarn(ply, target_uid, target_name, reason)
        return ""
    end
end)

-- ==========================================
-- RECEPTORES DE RED (CON BLINDAJE DE SEGURIDAD)
-- ==========================================

net.Receive("IvoWarns_RequestPlayers", function(len, ply)
    if not IVO_WARNS.IsAdmin(ply) then return end

    GetCombinedPlayers(function(players)
        if not IsValid(ply) then return end
        net.Start("IvoWarns_SendPlayers")
        net.WriteUInt(#players, 16)
        for _, p in ipairs(players) do
            net.WriteString(p.steamid)
            local display_name = p.is_online and ("[ON] " .. p.name) or p.name
            net.WriteString(display_name)
            net.WriteUInt(tonumber(p.last_warn) or 0, 32)
        end
        net.Send(ply)
    end)
end)

net.Receive("IvoWarns_RequestWarns", function(len, ply)
    local steamid = net.ReadString()
    
    if not IVO_WARNS.IsAdmin(ply) then
        steamid = GetPlayerUID(ply)
    end

    if not steamid or steamid == "" then return end

    IVO_WARNS.DB.Query(
        "SELECT id, admin, reason, time, is_deleted, delete_reason, delete_admin FROM ivo_warns_records"
        .. " WHERE steamid = " .. IVO_WARNS.DB.Escape(steamid) .. " ORDER BY time DESC",
        function(warns)
            warns = warns or {}
            if not IsValid(ply) then return end
            net.Start("IvoWarns_SendWarns")
            net.WriteUInt(#warns, 16)
            for _, w in ipairs(warns) do
                net.WriteUInt(tonumber(w.id), 32)
                net.WriteString(w.admin)
                net.WriteString(w.reason)
                net.WriteUInt(tonumber(w.time) or 0, 32)
                net.WriteBit(tonumber(w.is_deleted) == 1)
                net.WriteString(w.delete_reason or "")
                net.WriteString(w.delete_admin or "")
            end
            net.Send(ply)
        end
    )
end)

net.Receive("IvoWarns_DeleteSingle", function(len, ply)
    if not IVO_WARNS.IsAdmin(ply) then return end

    local warnID    = net.ReadUInt(32)
    local reason    = net.ReadString()
    local adminName = ply:Nick()

    if not warnID or warnID == 0 then return end
    if reason == "" then reason = "Sin motivo especificado" end

    IVO_WARNS.DB.Query(
        "UPDATE ivo_warns_records SET is_deleted = 1, delete_reason = " .. IVO_WARNS.DB.Escape(reason)
        .. ", delete_admin = " .. IVO_WARNS.DB.Escape(adminName)
        .. " WHERE id = " .. warnID
    )

    IVO_WARNS.DB.QueryValue("SELECT steamid FROM ivo_warns_records WHERE id = " .. warnID, function(steamid)
        if steamid then
            IVO_WARNS.DB.QueryValue(
                "SELECT time FROM ivo_warns_records WHERE steamid = " .. IVO_WARNS.DB.Escape(steamid)
                .. " AND is_deleted = 0 ORDER BY time DESC LIMIT 1",
                function(new_last)
                    if new_last then
                        IVO_WARNS.DB.Query("UPDATE ivo_warns_players SET last_warn = " .. new_last .. " WHERE steamid = " .. IVO_WARNS.DB.Escape(steamid))
                    else
                        IVO_WARNS.DB.Query("UPDATE ivo_warns_players SET last_warn = 0 WHERE steamid = " .. IVO_WARNS.DB.Escape(steamid))
                    end
                    RefreshAdminMenu(ply, steamid)
                end
            )
        end
    end)

    ply:ChatPrint(IVO_WARNS.Config.Prefix .. "Warn #" .. warnID .. " eliminado correctamente.")
end)

net.Receive("IvoWarns_DeleteAll", function(len, ply)
    if not IVO_WARNS.IsAdmin(ply) then return end

    local steamid   = net.ReadString()
    local reason    = net.ReadString()
    local adminName = ply:Nick()

    if not steamid or steamid == "" then return end
    if reason == "" then reason = "Remoción masiva" end

    IVO_WARNS.DB.Query(
        "UPDATE ivo_warns_records SET is_deleted = 1, delete_reason = " .. IVO_WARNS.DB.Escape(reason)
        .. ", delete_admin = " .. IVO_WARNS.DB.Escape(adminName)
        .. " WHERE steamid = " .. IVO_WARNS.DB.Escape(steamid) .. " AND is_deleted = 0"
    )
    IVO_WARNS.DB.Query("UPDATE ivo_warns_players SET last_warn = 0 WHERE steamid = " .. IVO_WARNS.DB.Escape(steamid))

    RefreshAdminMenu(ply, steamid)
    ply:ChatPrint(IVO_WARNS.Config.Prefix .. "Se han eliminado todos los warns activos del usuario.")
end)