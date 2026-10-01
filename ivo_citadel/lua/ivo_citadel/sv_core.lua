util.AddNetworkString("IvoCitadel_SyncState")
util.AddNetworkString("IvoCitadel_SyncZones")
util.AddNetworkString("IvoCitadel_StartPredefined")
util.AddNetworkString("IvoCitadel_StartCustom")
util.AddNetworkString("IvoCitadel_SyncConsoles")
util.AddNetworkString("IvoCitadel_ToggleFreecam")

IvoCitadel.Active = false
IvoCitadel.ActiveCitadelName = ""
IvoCitadel.ActiveDroids = {}

IvoCitadel.Zones = {}
IvoCitadel.Consoles = {}

local dataFolder = "ivo_citadel"
local dataFile = dataFolder .. "/zones_" .. game.GetMap() .. ".json"
local consoleFile = dataFolder .. "/consoles_" .. game.GetMap() .. ".json"

function IvoCitadel.SaveZones()
    if not file.Exists(dataFolder, "DATA") then file.CreateDir(dataFolder) end
    file.Write(dataFile, util.TableToJSON(IvoCitadel.Zones, true))
    print("[Ivo Citadel] Zonas guardadas en " .. dataFile)
    IvoCitadel.SyncZones()
end

function IvoCitadel.LoadZones()
    if file.Exists(dataFile, "DATA") then
        local data = util.JSONToTable(file.Read(dataFile, "DATA"))
        if data then
            for k, v in pairs(data) do
                if not v.areas then v.areas = {} end
                if not v.spawn_areas then v.spawn_areas = {} end
            end
            IvoCitadel.Zones = data
            print("[Ivo Citadel] Zonas cargadas.")
        end
    else
        IvoCitadel.Zones = {}
    end
end

function IvoCitadel.SaveConsoles()
    if not file.Exists(dataFolder, "DATA") then file.CreateDir(dataFolder) end
    local cons = {}
    for _, ent in ipairs(ents.FindByClass("ivo_citadel_console")) do
        table.insert(cons, {
            pos = ent:GetPos(),
            ang = ent:GetAngles(),
            model = ent:GetModel(),
            citadel = ent:GetNWString("CitadelName", "Ciudadela 1")
        })
    end
    file.Write(consoleFile, util.TableToJSON(cons, true))
    print("[Ivo Citadel] Consolas guardadas.")
end

function IvoCitadel.LoadConsoles()
    for _, ent in ipairs(ents.FindByClass("ivo_citadel_console")) do
        ent:Remove()
    end
    timer.Simple(0.1, function()
        if file.Exists(consoleFile, "DATA") then
            local data = util.JSONToTable(file.Read(consoleFile, "DATA")) or {}
            for _, c in ipairs(data) do
                local ent = ents.Create("ivo_citadel_console")
                ent:SetPos(c.pos)
                ent:SetAngles(c.ang)
                if c.model then ent:SetModel(c.model) end
                ent:Spawn()
                ent:SetNWString("CitadelName", c.citadel)
                
                local phys = ent:GetPhysicsObject()
                if IsValid(phys) then phys:EnableMotion(false) end
            end
            print("[Ivo Citadel] Consolas cargadas.")
        end
    end)
end

hook.Add("Initialize", "IvoCitadel_LoadData", function()
    IvoCitadel.LoadZones()
end)
hook.Add("PostCleanupMap", "IvoCitadel_LoadDataCleanup", function()
    IvoCitadel.LoadZones()
    IvoCitadel.LoadConsoles()
end)
hook.Add("InitPostEntity", "IvoCitadel_LoadDataInit", function()
    IvoCitadel.LoadConsoles()
end)

function IvoCitadel.SyncZones(ply)
    net.Start("IvoCitadel_SyncZones")
    net.WriteTable(IvoCitadel.Zones)
    if ply then net.Send(ply) else net.Broadcast() end
end

hook.Add("PlayerInitialSpawn", "IvoCitadel_SyncOnSpawn", function(ply)
    timer.Simple(2, function() if IsValid(ply) then IvoCitadel.SyncZones(ply) end end)
end)

function IvoCitadel.SyncState()
    net.Start("IvoCitadel_SyncState")
    net.WriteBool(IvoCitadel.Active)
    net.WriteString(IvoCitadel.ActiveCitadelName)
    net.WriteUInt(table.Count(IvoCitadel.ActiveDroids), 16)
    net.Broadcast()
end

local function GetRandomSpawnPos(spawnAreas)
    if not spawnAreas or #spawnAreas == 0 then return nil end
    for attempt = 1, 20 do
        local area = spawnAreas[math.random(#spawnAreas)]
        local randX = math.Rand(area.min.x, area.max.x)
        local randY = math.Rand(area.min.y, area.max.y)
        local randZ = math.Rand(area.min.z, area.max.z)
        local pos = Vector(randX, randY, randZ)
        
        local trGround = util.TraceLine({
            start = pos,
            endpos = pos - Vector(0,0,500),
            mask = MASK_SOLID
        })
        if trGround.Hit then
            pos = trGround.HitPos + Vector(0,0,5)
        end
        
        local tr = util.HullTrace({
            start = pos,
            endpos = pos,
            mins = Vector(-16, -16, 0),
            maxs = Vector(16, 16, 72),
            mask = MASK_NPCSOLID
        })
        if not tr.Hit then return pos end
    end
    return nil
end

local function StartEvent(ply, citadelName, droidsList)
    if ply and not IvoCitadel.Config.HasPermission(ply) then return end
    if IvoCitadel.Active then 
        if ply then ply:ChatPrint("Ya hay una ciudadela activa.") end 
        return 
    end
    
    local zoneData = IvoCitadel.Zones[citadelName]
    if not zoneData then 
        if ply then ply:ChatPrint("Ciudadela no encontrada.") end 
        return 
    end
    if not zoneData.spawn_areas or #zoneData.spawn_areas == 0 then 
        if ply then ply:ChatPrint("No hay areas de spawn en " .. citadelName) end 
        return 
    end

    IvoCitadel.ActiveDroids = {}
    local totalSpawned = 0

    for class, count in pairs(droidsList) do
        for i=1, count do
            local spawnPos = GetRandomSpawnPos(zoneData.spawn_areas)
            if spawnPos then
                local npc = ents.Create(class)
                if IsValid(npc) then
                    npc:SetPos(spawnPos)
                    npc:Spawn()
                    npc:Activate()
                    table.insert(IvoCitadel.ActiveDroids, npc)
                    totalSpawned = totalSpawned + 1
                end
            end
        end
    end
    
    if totalSpawned == 0 then 
        if ply then ply:ChatPrint("No se pudo spawnear droides (espacio bloqueado).") end 
        return 
    end

    IvoCitadel.Active = true
    IvoCitadel.ActiveCitadelName = citadelName
    IvoCitadel.SyncState()
    
    local starterName = ply and ply:Nick() or "el Sistema"
    for _, v in ipairs(player.GetAll()) do
        v:SendLua([[surface.PlaySound("]] .. IvoCitadel.Config.SoundStart .. [[")]])
        v:ChatPrint("¡La ciudadela [" .. citadelName .. "] ha sido iniciada por " .. starterName .. "!")
    end
end

net.Receive("IvoCitadel_StartPredefined", function(len, ply)
    local citadelName = net.ReadString()
    local id = net.ReadUInt(8)
    local preset = IvoCitadel.Config.Predefined[id]
    if preset then StartEvent(ply, citadelName, preset.droids) end
end)

net.Receive("IvoCitadel_StartCustom", function(len, ply)
    local citadelName = net.ReadString()
    local count = net.ReadUInt(8)
    local customList = {}
    for i=1, count do
        local class = net.ReadString()
        local amount = net.ReadUInt(8)
        customList[class] = amount
    end
    StartEvent(ply, citadelName, customList)
end)

hook.Add("OnNPCKilled", "IvoCitadel_NPCDeath", function(npc, attacker, inflictor)
    if not IvoCitadel.Active then return end

    for i, activeNpc in ipairs(IvoCitadel.ActiveDroids) do
        if activeNpc == npc then
            table.remove(IvoCitadel.ActiveDroids, i)
            IvoCitadel.SyncState()
            break
        end
    end

    if table.Count(IvoCitadel.ActiveDroids) == 0 then
        local name = IvoCitadel.ActiveCitadelName
        IvoCitadel.Active = false
        IvoCitadel.ActiveCitadelName = ""
        IvoCitadel.SyncState()
        for _, v in ipairs(player.GetAll()) do
            v:SendLua([[surface.PlaySound("]] .. IvoCitadel.Config.SoundEnd .. [[")]])
            v:ChatPrint("¡La ciudadela [" .. name .. "] ha sido despejada!")
        end
    end
end)

concommand.Add("ivo_citadel_set_console", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    local name = args[1]
    if not name or name == "" then 
        ply:ChatPrint("Uso: ivo_citadel_set_console \"Nombre Ciudadela\"")
        return
    end
    
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity
    if IsValid(ent) and ent:GetClass() == "ivo_citadel_console" then
        ent:SetNWString("CitadelName", name)
        
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        
        IvoCitadel.SaveConsoles()
        ply:ChatPrint("[Ivo Citadel] Consola vinculada a " .. name .. " y guardada.")
    else
        ply:ChatPrint("Debes estar mirando a una consola de ciudadela.")
    end
end)

concommand.Add("ivo_citadel_save", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    IvoCitadel.SaveConsoles()
    ply:ChatPrint("[Ivo Citadel] Todas las consolas han sido guardadas.")
end)

local nextCheck = 0
hook.Add("Think", "IvoCitadel_AutoStartCheck", function()
    if CurTime() < nextCheck then return end
    nextCheck = CurTime() + 2
    
    if IvoCitadel.Active then return end
    
    for cName, zData in pairs(IvoCitadel.Zones) do
        if zData.areas and #zData.areas > 0 then
            local hasPlayers = false
            for _, ply in ipairs(player.GetAll()) do
                if ply:Alive() and ply:GetObserverMode() == OBS_MODE_NONE then
                    local pos = ply:GetPos()
                    for _, area in ipairs(zData.areas) do
                        if pos:WithinAABox(area.min, area.max) then
                            hasPlayers = true
                            break
                        end
                    end
                end
                if hasPlayers then break end
            end
            
            if hasPlayers then
                break
            end
        end
    end
end)


net.Receive("IvoCitadel_ToggleFreecam", function(len, ply)
    local state = net.ReadBool()
    if state then
        ply:Lock() -- Congela al jugador
    else
        ply:UnLock() -- Descongela
    end
end)


concommand.Add("ivo_citadel_clear", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    local name = args[1]
    if not name or name == "" then
        ply:ChatPrint("Uso: ivo_citadel_clear \"Nombre Ciudadela\"")
        return
    end
    
    if IvoCitadel.Zones[name] then
        IvoCitadel.Zones[name] = nil
        IvoCitadel.SaveZones()
        ply:ChatPrint("[Ivo Citadel] Se ha borrado toda la informacion de la ciudadela: " .. name)
    else
        ply:ChatPrint("Esa ciudadela no existe.")
    end
end)

concommand.Add("ivo_citadel_force_sync", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    IvoCitadel.SyncZones()
    ply:ChatPrint("Sincronizando zonas...")
end)

