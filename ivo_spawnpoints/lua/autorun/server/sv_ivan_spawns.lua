util.AddNetworkString("IvanSpawns_OpenMenu")
util.AddNetworkString("IvanSpawns_SaveConfig")
util.AddNetworkString("IvanSpawns_Delete")

local function IsAdmin(ply)
    if ply:IsSuperAdmin() then return true end
    if SAM and ply:HasPermission("manage_spawns") then return true end
    if IVO_SAM and IVO_SAM.HasPermission(ply, "manage_spawns") then return true end
    return ply:IsUserGroup("superadmin")
end

local function SaveSpawns()
    local spawns = {}
    for _, ent in ipairs(ents.FindByClass("ivan_spawn_point")) do
        if ent.SpawnData and ent.SpawnData.IsPersistent then
            table.insert(spawns, {
                Pos = ent:GetPos(),
                Ang = ent:GetAngles(),
                SpawnName = ent:GetSpawnName(),
                ShowName = ent:GetShowName(),
                IsInvisible = ent:GetIsInvisible(),
                SpawnData = ent.SpawnData
            })
        end
    end
    
    file.CreateDir("ivan_spawns")
    file.Write("ivan_spawns/" .. game.GetMap() .. ".json", util.TableToJSON(spawns, true))
end

local function LoadSpawns()
    local data = file.Read("ivan_spawns/" .. game.GetMap() .. ".json", "DATA")
    if not data then return end
    
    local spawns = util.JSONToTable(data)
    if not spawns then return end
    
    for _, v in ipairs(spawns) do
        local ent = ents.Create("ivan_spawn_point")
        if not IsValid(ent) then continue end
        
        ent:SetPos(v.Pos)
        ent:SetAngles(v.Ang)
        ent:Spawn()
        
        ent:SetSpawnName(v.SpawnName or "Spawn")
        ent:SetShowName(v.ShowName == true)
        ent:SetIsInvisible(v.IsInvisible == true)
        
        ent.SpawnData = v.SpawnData or {
            AllowedJobs = {},
            AllowedCategories = {},
            AllowedSteamIDs = {},
            AllowedSAMRanks = {},
            IsPersistent = true
        }
        
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(false)
        end
    end
end
hook.Add("InitPostEntity", "IvanSpawns_Load", LoadSpawns)
hook.Add("PostCleanupMap", "IvanSpawns_Reload", LoadSpawns)

net.Receive("IvanSpawns_SaveConfig", function(len, ply)
    if not IsAdmin(ply) then return end
    
    local ent = net.ReadEntity()
    if not IsValid(ent) or ent:GetClass() ~= "ivan_spawn_point" then return end
    
    local name = net.ReadString()
    local showName = net.ReadBool()
    local isInvisible = net.ReadBool()
    local data = net.ReadTable()
    
    ent:SetSpawnName(name)
    ent:SetShowName(showName)
    ent:SetIsInvisible(isInvisible)
    ent.SpawnData = data
    
    SaveSpawns()
    ply:ChatPrint("Spawn '" .. name .. "' guardado correctamente.")
end)

net.Receive("IvanSpawns_Delete", function(len, ply)
    if not IsAdmin(ply) then return end
    
    local ent = net.ReadEntity()
    if not IsValid(ent) or ent:GetClass() ~= "ivan_spawn_point" then return end
    
    ent:Remove()
    SaveSpawns()
    ply:ChatPrint("Spawn eliminado.")
end)

local function FindEmptyPos(pos)
    local mins, maxs = Vector(-16, -16, 0), Vector(16, 16, 72)
    local maxRadius = 150
    local step = 45
    
    local tr = util.TraceHull({
        start = pos,
        endpos = pos,
        mins = mins,
        maxs = maxs,
        mask = MASK_PLAYERSOLID
    })
    
    if not tr.Hit then return pos end
    
    for radius = step, maxRadius, step do
        for angle = 0, 315, 45 do
            local rad = math.rad(angle)
            local offset = Vector(math.cos(rad) * radius, math.sin(rad) * radius, 0)
            local testPos = pos + offset
            
            local trOffset = util.TraceHull({
                start = testPos,
                endpos = testPos,
                mins = mins,
                maxs = maxs,
                mask = MASK_PLAYERSOLID
            })
            
            if not trOffset.Hit then
                return testPos
            end
        end
    end
    
    return pos
end

hook.Add("PlayerSelectSpawn", "IvanSpawns_Select", function(ply)
    local possibleSpawns = {}
    
    for _, ent in ipairs(ents.FindByClass("ivan_spawn_point")) do
        if not ent.SpawnData then continue end
        
        local data = ent.SpawnData
        local canSpawn = false
        
        if data.AllowedSteamIDs[ply:SteamID()] or data.AllowedSteamIDs[ply:SteamID64()] then
            canSpawn = true
        end
        
        if not canSpawn and ply.GetUserGroup and data.AllowedSAMRanks[ply:GetUserGroup()] then
            canSpawn = true
        end
        
        if not canSpawn and ply.Team then
            local job = team.GetName(ply:Team())
            if data.AllowedJobs[job] then
                canSpawn = true
            end
            
            local jobTable = RPExtraTeams and RPExtraTeams[ply:Team()]
            if jobTable and data.AllowedCategories[jobTable.category] then
                canSpawn = true
            end
        end
        
        if canSpawn then
            table.insert(possibleSpawns, ent)
        end
    end
    
    if #possibleSpawns > 0 then
        local chosen = possibleSpawns[math.random(#possibleSpawns)]
        ply.IvanChosenSpawn = chosen
        return chosen
    end
end)

hook.Add("PlayerSpawn", "IvanSpawns_AntiStuck", function(ply)
    timer.Simple(0.1, function()
        if IsValid(ply) and IsValid(ply.IvanChosenSpawn) then
            local pos = ply.IvanChosenSpawn:GetPos()
            local safePos = FindEmptyPos(pos)
            if pos ~= safePos then
                ply:SetPos(safePos)
            end
            ply:SetEyeAngles(ply.IvanChosenSpawn:GetAngles())
            ply.IvanChosenSpawn = nil
        end
    end)
end)
