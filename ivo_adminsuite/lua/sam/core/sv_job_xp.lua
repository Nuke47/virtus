-- ============================================================================
-- IVOSAM: SISTEMA DE EXPERIENCIA Y TIEMPO POR TRABAJO (DARKRP)
-- ============================================================================

-- Crear tabla si no existe
IVO_SAM.DB.Query("CREATE TABLE IF NOT EXISTS ivosam_job_xp (steamid64 VARCHAR(64), job_cmd VARCHAR(64), xp INTEGER, level INTEGER, playtime INTEGER, PRIMARY KEY (steamid64, job_cmd));")

-- Limpieza de seguridad
IVO_SAM.DB.Query("DELETE FROM ivosam_job_xp WHERE steamid64 NOT LIKE '7656119%' AND steamid64 NOT LIKE 'STEAM_%';")

-- Memoria temporal para no saturar SQL con queries constantes
IVO_SAM.JobDataCache = IVO_SAM.JobDataCache or {}

function IVO_SAM.LoadPlayerJobs(ply)
    if not IsValid(ply) or ply:IsBot() then return end
    local sid64 = ply:SteamID64()
    
    IVO_SAM.JobDataCache[sid64] = {}
    
    IVO_SAM.DB.Query(string.format("SELECT * FROM ivosam_job_xp WHERE steamid64 = %s;", IVO_SAM.DB.Escape(sid64)), function(res)
        if not IsValid(ply) then return end
        if res then
            for _, row in ipairs(res) do
                local cmd = row.job_cmd
                local xp = tonumber(row.xp) or 0
                local level = tonumber(row.level) or 1
                local playtime = tonumber(row.playtime) or 0
                
                IVO_SAM.JobDataCache[sid64][cmd] = { xp = xp, level = level, playtime = playtime }
                
                ply:SetNWInt("IVO_JobXP_" .. cmd, xp)
                ply:SetNWInt("IVO_JobLevel_" .. cmd, level)
                ply:SetNWInt("IVO_JobTime_" .. cmd, playtime)
            end
        end
    end)
end

function IVO_SAM.SavePlayerJobs(ply)
    if not IsValid(ply) or ply:IsBot() then return end
    local sid64 = ply:SteamID64()
    
    local cache = IVO_SAM.JobDataCache[sid64]
    if not cache then return end
    
    for cmd, data in pairs(cache) do
        IVO_SAM.DB.Query(string.format(
            "REPLACE INTO ivosam_job_xp (steamid64, job_cmd, xp, level, playtime) VALUES (%s, %s, %d, %d, %d);",
            IVO_SAM.DB.Escape(sid64), IVO_SAM.DB.Escape(cmd), data.xp, data.level, data.playtime
        ))
    end
end

hook.Add("PlayerInitialSpawn", "IVO_SAM_LoadJobXP", function(ply)
    IVO_SAM.LoadPlayerJobs(ply)
end)

hook.Add("PlayerDisconnected", "IVO_SAM_SaveJobXP", function(ply)
    IVO_SAM.SavePlayerJobs(ply)
    if ply:SteamID64() then
        IVO_SAM.JobDataCache[ply:SteamID64()] = nil
    end
end)

-- Verificar si el trabajo actual está baneado de ganar XP
local function IsJobBlacklisted(ply)
    if not ply.getJobTable or not ply:getJobTable() then return true end
    local jobName = string.lower(ply:getJobTable().name or "")
    if string.find(jobName, "cadete") then return true end
    return false
end

function IVO_SAM.AddJobPlaytime(ply, amount)
    if not IsValid(ply) or IsJobBlacklisted(ply) then return end
    
    local sid64 = ply:SteamID64()
    local cmd = IVO_SAM.GetJobSpecialty(ply:getJobTable())
    if not cmd or cmd == "" then return end
    
    IVO_SAM.JobDataCache[sid64] = IVO_SAM.JobDataCache[sid64] or {}
    IVO_SAM.JobDataCache[sid64][cmd] = IVO_SAM.JobDataCache[sid64][cmd] or { xp = 0, level = 1, playtime = 0 }
    
    IVO_SAM.JobDataCache[sid64][cmd].playtime = IVO_SAM.JobDataCache[sid64][cmd].playtime + amount
    ply:SetNWInt("IVO_JobTime_" .. cmd, IVO_SAM.JobDataCache[sid64][cmd].playtime)
end

util.AddNetworkString("IVO_JobLevelUpAnim")

function IVO_SAM.AddJobXP(ply, amount)
    if not IsValid(ply) or IsJobBlacklisted(ply) then return end
    
    local sid64 = ply:SteamID64()
    local cmd, isSpecialty = IVO_SAM.GetJobSpecialty(ply:getJobTable())
    local jobName = ply:getJobTable().name
    if not cmd or cmd == "" then return end
    
    if isSpecialty then
        jobName = string.upper(cmd:sub(1,1)) .. string.lower(cmd:sub(2))
    end
    
    IVO_SAM.JobDataCache[sid64] = IVO_SAM.JobDataCache[sid64] or {}
    local data = IVO_SAM.JobDataCache[sid64][cmd] or { xp = 0, level = 1, playtime = 0 }
    
    data.xp = data.xp + amount
    local initialLevel = data.level
    
    local xpNeeded = IVO_SAM.GetJobXPNeededForLevel(data.level)
    local iterations = 0
    while data.xp >= xpNeeded and iterations < 500 do
        data.xp = data.xp - xpNeeded
        data.level = data.level + 1
        xpNeeded = IVO_SAM.GetJobXPNeededForLevel(data.level)
        iterations = iterations + 1
    end
    
    IVO_SAM.JobDataCache[sid64][cmd] = data
    
    ply:SetNWInt("IVO_JobXP_" .. cmd, data.xp)
    ply:SetNWInt("IVO_JobLevel_" .. cmd, data.level)
    
    -- Notificar de subida de nivel de trabajo si aplica
    if data.level > initialLevel then
        net.Start("IVO_JobLevelUpAnim")
            net.WriteInt(data.level, 16)
            net.WriteString(jobName)
        net.Send(ply)
        
        hook.Run("IVOSAM_JobLevelUp", ply, cmd, data.level)
    end
end

-- Timer pasivo: Añade 60s de tiempo de juego al job, y 25 de XP pasiva por minuto
-- Verificar si el trabajo actual es elegible para subir nivel de pilotaje
local function CanGainPilotXP(ply)
    if not ply.getJobTable or not ply:getJobTable() then return false end
    local jobName = string.lower(ply:getJobTable().name or "")
    
    if string.find(jobName, "apoyo") then return true end
    if string.find(jobName, "arc") then return true end
    if string.find(jobName, "comandante") or string.find(jobName, "cmd") then return true end
    if string.find(jobName, "cazarrecompensas") then return true end
    
    return false
end

function IVO_SAM.AddPilotXP(ply, amount)
    if not IsValid(ply) or not CanGainPilotXP(ply) then return end
    
    local sid64 = ply:SteamID64()
    local cmd = "piloto"
    local jobName = "Pilotaje"
    
    IVO_SAM.JobDataCache[sid64] = IVO_SAM.JobDataCache[sid64] or {}
    local data = IVO_SAM.JobDataCache[sid64][cmd] or { xp = 0, level = 1, playtime = 0 }
    
    data.xp = data.xp + amount
    local initialLevel = data.level
    
    local xpNeeded = IVO_SAM.GetJobXPNeededForLevel(data.level)
    local iterations = 0
    while data.xp >= xpNeeded and iterations < 500 do
        data.xp = data.xp - xpNeeded
        data.level = data.level + 1
        xpNeeded = IVO_SAM.GetJobXPNeededForLevel(data.level)
        iterations = iterations + 1
    end
    
    IVO_SAM.JobDataCache[sid64][cmd] = data
    
    ply:SetNWInt("IVO_JobXP_" .. cmd, data.xp)
    ply:SetNWInt("IVO_JobLevel_" .. cmd, data.level)
    
    if data.level > initialLevel then
        net.Start("IVO_JobLevelUpAnim")
            net.WriteInt(data.level, 16)
            net.WriteString(jobName)
        net.Send(ply)
        
        hook.Run("IVOSAM_PilotLevelUp", ply, data.level)
    end
end

timer.Create("IVO_SAM_JobPassiveLoop", 60, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.getJobTable and ply:getJobTable() then
            IVO_SAM.AddJobPlaytime(ply, 60)
            IVO_SAM.AddJobXP(ply, 25)
            IVO_SAM.AddPilotXP(ply, 25) -- Añade XP de pilotaje si cumple los requisitos
            IVO_SAM.SavePlayerJobs(ply) -- Guardado progresivo
        end
    end
end)
