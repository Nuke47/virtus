VirtusWhitelist = VirtusWhitelist or {}
VirtusWhitelist.Cache = VirtusWhitelist.Cache or {}

VirtusWhitelist.Config = {
    UseMySQL = true,
    Host = "45.235.98.238",
    Username = "_ivan75",
    Password = "f3WEFVf34$",
    Database = "_ivan75",
    Port = 3306
}

local function Query(queryStr, callback)
    if VirtusWhitelist.Config.UseMySQL and mysqloo then
        if not VirtusWhitelist.DB then return end
        local q = VirtusWhitelist.DB:query(queryStr)
        q.onSuccess = function(_, data)
            if data and #data == 0 then data = nil end
            if callback then callback(data) end
        end
        q.onError = function(_, err)
            print("[Virtus Whitelist] MySQL Error: " .. err .. " (Query: " .. queryStr .. ")")
            if callback then callback(false, err) end
        end
        q:start()
    else
        local data = sql.Query(queryStr)
        if data == false then
            print("[Virtus Whitelist] SQLite Error: " .. sql.LastError() .. " (Query: " .. queryStr .. ")")
            if callback then callback(false, sql.LastError()) end
        else
            if callback then callback(data) end
        end
    end
end

local function Escape(str)
    if VirtusWhitelist.Config.UseMySQL and mysqloo and VirtusWhitelist.DB then
        return "'" .. VirtusWhitelist.DB:escape(tostring(str)) .. "'"
    else
        return sql.SQLStr(str)
    end
end

-- Initialize Database
function VirtusWhitelist.InitDB()
    if VirtusWhitelist.Config.UseMySQL then
        require("mysqloo")
        VirtusWhitelist.DB = mysqloo.connect(
            VirtusWhitelist.Config.Host,
            VirtusWhitelist.Config.Username,
            VirtusWhitelist.Config.Password,
            VirtusWhitelist.Config.Database,
            VirtusWhitelist.Config.Port
        )
        
        function VirtusWhitelist.DB:onConnected()
            print("[Virtus Whitelist] MySQL Connected!")
            Query("CREATE TABLE IF NOT EXISTS virtus_whitelist (steamid VARCHAR(64), job_cmd VARCHAR(128), list_type VARCHAR(32), PRIMARY KEY(steamid, job_cmd, list_type))", function()
                print("[Virtus Whitelist] Base de datos verificada/creada.")
                VirtusWhitelist.LoadCache()
            end)
        end
        
        function VirtusWhitelist.DB:onConnectionFailed(err)
            print("[Virtus Whitelist] MySQL Connection Failed: " .. err)
        end
        
        VirtusWhitelist.DB:connect()
    else
        if not sql.TableExists("virtus_whitelist") then
            sql.Query("CREATE TABLE virtus_whitelist (steamid TEXT, job_cmd TEXT, list_type TEXT, PRIMARY KEY(steamid, job_cmd, list_type))")
            print("[Virtus Whitelist] Tabla de base de datos creada (SQLite).")
        end
        VirtusWhitelist.LoadCache()
    end
end

-- Load all entries into memory for fast lookup
function VirtusWhitelist.LoadCache()
    VirtusWhitelist.Cache = {}
    Query("SELECT * FROM virtus_whitelist", function(data)
        if data then
            for _, row in ipairs(data) do
                local steamid = row.steamid
                local job_cmd = row.job_cmd
                local list_type = row.list_type

                if not VirtusWhitelist.Cache[job_cmd] then
                    VirtusWhitelist.Cache[job_cmd] = { whitelist = {}, blacklist = {} }
                end

                if list_type == "whitelist" then
                    VirtusWhitelist.Cache[job_cmd].whitelist[steamid] = true
                elseif list_type == "blacklist" then
                    VirtusWhitelist.Cache[job_cmd].blacklist[steamid] = true
                end
            end
        end
        print("[Virtus Whitelist] Caché de la base de datos cargada.")
    end)
end

-- Add a player to a list
function VirtusWhitelist.AddPlayer(steamid, job_cmd, list_type)
    -- Remove from the opposite list if they are in it, or from the same list to avoid duplicates
    VirtusWhitelist.RemovePlayer(steamid, job_cmd, "whitelist")
    VirtusWhitelist.RemovePlayer(steamid, job_cmd, "blacklist")

    Query(string.format("INSERT INTO virtus_whitelist (steamid, job_cmd, list_type) VALUES (%s, %s, %s)", 
        Escape(steamid), Escape(job_cmd), Escape(list_type)))

    if not VirtusWhitelist.Cache[job_cmd] then
        VirtusWhitelist.Cache[job_cmd] = { whitelist = {}, blacklist = {} }
    end

    if list_type == "whitelist" then
        VirtusWhitelist.Cache[job_cmd].whitelist[steamid] = true
        local ply = player.GetBySteamID(steamid)
        if IsValid(ply) then ply:SetNWBool("VirtusWL_" .. job_cmd, true) end
    elseif list_type == "blacklist" then
        VirtusWhitelist.Cache[job_cmd].blacklist[steamid] = true
    end
end

-- Remove a player from a list
function VirtusWhitelist.RemovePlayer(steamid, job_cmd, list_type)
    Query(string.format("DELETE FROM virtus_whitelist WHERE steamid = %s AND job_cmd = %s AND list_type = %s", 
        Escape(steamid), Escape(job_cmd), Escape(list_type)))

    if VirtusWhitelist.Cache[job_cmd] then
        if list_type == "whitelist" then
            VirtusWhitelist.Cache[job_cmd].whitelist[steamid] = nil
            local ply = player.GetBySteamID(steamid)
            if IsValid(ply) then ply:SetNWBool("VirtusWL_" .. job_cmd, false) end
        elseif list_type == "blacklist" then
            VirtusWhitelist.Cache[job_cmd].blacklist[steamid] = nil
        end
    end
end

-- Get a player's status for a job
function VirtusWhitelist.GetPlayerStatus(steamid, job_cmd)
    if not VirtusWhitelist.Cache[job_cmd] then return "none" end

    if VirtusWhitelist.Cache[job_cmd].blacklist[steamid] then
        return "blacklist"
    elseif VirtusWhitelist.Cache[job_cmd].whitelist[steamid] then
        return "whitelist"
    end

    return "none"
end

-- Get all entries for a specific job
function VirtusWhitelist.GetJobLists(job_cmd)
    if not VirtusWhitelist.Cache[job_cmd] then
        return { whitelist = {}, blacklist = {} }
    end
    return VirtusWhitelist.Cache[job_cmd]
end

hook.Add("Initialize", "VirtusWhitelist_InitDB", VirtusWhitelist.InitDB)
