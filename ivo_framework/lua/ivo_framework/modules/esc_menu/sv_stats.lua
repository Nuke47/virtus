if not SERVER then return end

sql.Query([[
    CREATE TABLE IF NOT EXISTS virtus_global_stats (
        steamid VARCHAR(50) PRIMARY KEY,
        npc_kills INT DEFAULT 0
    )
]])

sql.Query([[
    CREATE TABLE IF NOT EXISTS virtus_job_stats (
        steamid VARCHAR(50),
        jobcmd VARCHAR(100),
        kills INT DEFAULT 0,
        deaths INT DEFAULT 0,
        playtime INT DEFAULT 0,
        PRIMARY KEY (steamid, jobcmd)
    )
]])

-- Categorias imperiales para saber quien es de que bando
-- NOTA: Deben coincidir con las categorias definidas en cl_f4menu.lua y cl_escapemenu.lua
local Imperiales = {
    ["Cadetes"] = true,
    ["Clone Troopers"] = true,
    ["Shock Troopers"] = true,
    ["Shadow Unit"] = true,
    ["Altos Mandos"] = true
}

local function IsImperial(ply)
    local jobTable = RPExtraTeams[ply:Team()]
    if not jobTable then return false end
    return Imperiales[jobTable.category] == true
end

local function GetJobCmd(ply)
    local jobTable = RPExtraTeams[ply:Team()]
    if not jobTable then return "desconocido" end
    return jobTable.command
end

-- Funciones de guardado
local function SaveGlobalStats(ply)
    local sid = ply:SteamID64()
    if not sid then return end
    
    local npc = ply:GetNWInt("VIRTUS_NPCKills", 0)
    
    local exists = sql.Query("SELECT 1 FROM virtus_global_stats WHERE steamid = " .. sql.SQLStr(sid))
    if exists then
        sql.Query("UPDATE virtus_global_stats SET npc_kills = " .. npc .. " WHERE steamid = " .. sql.SQLStr(sid))
    else
        sql.Query("INSERT INTO virtus_global_stats (steamid, npc_kills) VALUES (" .. sql.SQLStr(sid) .. ", " .. npc .. ")")
    end
end

local function SaveJobStats(ply, jobcmd)
    local sid = ply:SteamID64()
    if not sid then return end
    
    local k = ply:GetNWInt("VIRTUS_Kills_" .. jobcmd, 0)
    local d = ply:GetNWInt("VIRTUS_Deaths_" .. jobcmd, 0)
    local t = ply:GetNWInt("VIRTUS_Playtime_" .. jobcmd, 0)
    
    local exists = sql.Query("SELECT 1 FROM virtus_job_stats WHERE steamid = " .. sql.SQLStr(sid) .. " AND jobcmd = " .. sql.SQLStr(jobcmd))
    if exists then
        sql.Query(string.format("UPDATE virtus_job_stats SET kills = %d, deaths = %d, playtime = %d WHERE steamid = %s AND jobcmd = %s", k, d, t, sql.SQLStr(sid), sql.SQLStr(jobcmd)))
    else
        sql.Query(string.format("INSERT INTO virtus_job_stats (steamid, jobcmd, kills, deaths, playtime) VALUES (%s, %s, %d, %d, %d)", sql.SQLStr(sid), sql.SQLStr(jobcmd), k, d, t))
    end
end

-- Calculamos los totales
local function RecalculateTotals(ply)
    local sid = ply:SteamID64()
    if not sid then return end
    
    local stats = sql.Query("SELECT * FROM virtus_job_stats WHERE steamid = " .. sql.SQLStr(sid))
    local totalK = 0
    local totalD = 0
    local totalT = 0
    local bestJob = "NINGUNA"
    local bestTime = -1
    
    if stats then
        for _, row in ipairs(stats) do
            totalK = totalK + tonumber(row.kills)
            totalD = totalD + tonumber(row.deaths)
            totalT = totalT + tonumber(row.playtime)
            
            if tonumber(row.playtime) > bestTime then
                bestTime = tonumber(row.playtime)
                bestJob = row.jobcmd
            end
        end
    end
    
    -- Leemos las variables temporales del rol actual, ya que pueden no estar guardadas aún en DB
    local curJob = GetJobCmd(ply)
    if curJob and curJob ~= "desconocido" then
        if not stats or not sql.Query("SELECT 1 FROM virtus_job_stats WHERE steamid = " .. sql.SQLStr(sid) .. " AND jobcmd = " .. sql.SQLStr(curJob)) then
            -- El job actual no está en la DB, sumamos lo que lleva
            totalK = totalK + ply:GetNWInt("VIRTUS_Kills_" .. curJob, 0)
            totalD = totalD + ply:GetNWInt("VIRTUS_Deaths_" .. curJob, 0)
            local ct = ply:GetNWInt("VIRTUS_Playtime_" .. curJob, 0)
            totalT = totalT + ct
            
            if ct > bestTime then
                bestJob = curJob
            end
        else
            -- Ya está en DB, pero hay que actualizar el total sumando la diferencia? 
            -- No, es mejor guardar en DB antes de recalcular.
        end
    end
    
    -- Convertimos el comando a nombre real
    local realName = "SOLDADO IMPERIAL"
    for _, j in ipairs(RPExtraTeams or {}) do
        if j.command == bestJob then
            realName = j.name
            break
        end
    end
    
    ply:SetNWInt("VIRTUS_TotalKills", totalK)
    ply:SetNWInt("VIRTUS_TotalDeaths", totalD)
    ply:SetNWInt("VIRTUS_TotalPlaytime", totalT)
    ply:SetNWString("VIRTUS_BestJob", realName)
end

local function LoadStats(ply)
    local sid = ply:SteamID64()
    if not sid then return end
    
    local global = sql.Query("SELECT * FROM virtus_global_stats WHERE steamid = " .. sql.SQLStr(sid))
    if global and global[1] then
        ply:SetNWInt("VIRTUS_NPCKills", tonumber(global[1].npc_kills))
    end
    
    local stats = sql.Query("SELECT * FROM virtus_job_stats WHERE steamid = " .. sql.SQLStr(sid))
    if stats then
        for _, row in ipairs(stats) do
            ply:SetNWInt("VIRTUS_Kills_" .. row.jobcmd, tonumber(row.kills))
            ply:SetNWInt("VIRTUS_Deaths_" .. row.jobcmd, tonumber(row.deaths))
            ply:SetNWInt("VIRTUS_Playtime_" .. row.jobcmd, tonumber(row.playtime))
        end
    end
    
    RecalculateTotals(ply)
end

-- Hooks principales
hook.Add("PlayerInitialSpawn", "Virtus_LoadStats", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) then LoadStats(ply) end
    end)
end)

hook.Add("PlayerDisconnected", "Virtus_SaveStatsDisconnect", function(ply)
    local curJob = GetJobCmd(ply)
    SaveJobStats(ply, curJob)
    SaveGlobalStats(ply)
end)

hook.Add("PlayerDeath", "Virtus_TrackKills", function(victim, inflictor, attacker)
    if not IsValid(victim) or not victim:IsPlayer() then return end
    
    -- Sumar muerte
    local vicJob = GetJobCmd(victim)
    victim:SetNWInt("VIRTUS_Deaths_" .. vicJob, victim:GetNWInt("VIRTUS_Deaths_" .. vicJob, 0) + 1)
    
    SaveJobStats(victim, vicJob)
    RecalculateTotals(victim)
    
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        local isVicImp = IsImperial(victim)
        local isAttImp = IsImperial(attacker)
        
        -- Si son de distintos bandos, es un asesinato válido
        if isVicImp ~= isAttImp then
            local attJob = GetJobCmd(attacker)
            attacker:SetNWInt("VIRTUS_Kills_" .. attJob, attacker:GetNWInt("VIRTUS_Kills_" .. attJob, 0) + 1)
            SaveJobStats(attacker, attJob)
            RecalculateTotals(attacker)
        end
    end
end)

hook.Add("OnNPCKilled", "Virtus_TrackNPCs", function(npc, attacker, inflictor)
    if IsValid(attacker) and attacker:IsPlayer() then
        attacker:SetNWInt("VIRTUS_NPCKills", attacker:GetNWInt("VIRTUS_NPCKills", 0) + 1)
        SaveGlobalStats(attacker)
    end
end)

-- Sistema de rastreo de tiempo
timer.Create("Virtus_PlaytimeTracker", 60, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local curJob = GetJobCmd(ply)
        if curJob and curJob ~= "desconocido" then
            ply:SetNWInt("VIRTUS_Playtime_" .. curJob, ply:GetNWInt("VIRTUS_Playtime_" .. curJob, 0) + 60)
            SaveJobStats(ply, curJob)
            RecalculateTotals(ply)
        end
    end
end)

hook.Add("OnPlayerChangedTeam", "Virtus_SaveBeforeChange", function(ply, before, after)
    local oldTable = RPExtraTeams[before]
    if oldTable then
        SaveJobStats(ply, oldTable.command)
    end
    -- Al cambiar de team, recalcula por si acaso
    timer.Simple(0.5, function()
        if IsValid(ply) then RecalculateTotals(ply) end
    end)
end)
