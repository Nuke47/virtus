IVO_QUEST = IVO_QUEST or {}
IVO_QUEST.Zones = IVO_QUEST.Zones or {}

-- Variable temporal para almacenar los puntos mientras el admin crea la zona
local tempZones = {}

-----------------------------------------------------------
-- 1. PERSISTENCIA DE ZONAS
-----------------------------------------------------------
function IVO_QUEST.SaveZones()
    file.CreateDir("ivo_quest")
    local fileName = "ivo_quest/zones_" .. game.GetMap() .. ".json"
    file.Write(fileName, util.TableToJSON(IVO_QUEST.Zones, true))
    print("[Ivo_quest] Zonas guardadas en: " .. fileName)
end

function IVO_QUEST.LoadZones()
    local fileName = "ivo_quest/zones_" .. game.GetMap() .. ".json"
    if file.Exists(fileName, "DATA") then
        local raw_data = file.Read(fileName, "DATA")
        IVO_QUEST.Zones = util.JSONToTable(raw_data) or {}
        print("[Ivo_quest] Se han cargado " .. table.Count(IVO_QUEST.Zones) .. " zonas de misión.")
    end
end
hook.Add("InitPostEntity", "Ivo_quest_LoadMapZones", IVO_QUEST.LoadZones)

-----------------------------------------------------------
-- 2. COMANDOS DE ADMINISTRADOR PARA CREAR ZONAS
-----------------------------------------------------------
-- Marcar Esquina 1
concommand.Add("ivo_zone_pos1", function(ply)
    if not ply:IsSuperAdmin() then return end
    local pos = ply:GetEyeTrace().HitPos
    
    tempZones[ply:SteamID()] = tempZones[ply:SteamID()] or {}
    tempZones[ply:SteamID()].pos1 = pos
    ply:ChatPrint("[Ivo_quest] Posición 1 marcada: " .. tostring(pos))
end)

-- Marcar Esquina 2
concommand.Add("ivo_zone_pos2", function(ply)
    if not ply:IsSuperAdmin() then return end
    local pos = ply:GetEyeTrace().HitPos
    
    tempZones[ply:SteamID()] = tempZones[ply:SteamID()] or {}
    tempZones[ply:SteamID()].pos2 = pos
    ply:ChatPrint("[Ivo_quest] Posición 2 marcada: " .. tostring(pos))
end)

-- Guardar la Zona
concommand.Add("ivo_zone_save", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    local zoneID = args[1]
    
    if not zoneID then 
        ply:ChatPrint("Uso: ivo_zone_save [nombre_de_la_zona]") 
        return 
    end

    local tZone = tempZones[ply:SteamID()]
    if not tZone or not tZone.pos1 or not tZone.pos2 then
        ply:ChatPrint("[Ivo_quest] Error: Necesitas marcar pos1 y pos2 primero.")
        return
    end

    -- GMod necesita un Vector Min y un Max para crear una "Caja" perfecta.
    -- Aquí ordenamos las coordenadas sin importar cómo las haya marcado el Admin.
    local min = Vector(math.min(tZone.pos1.x, tZone.pos2.x), math.min(tZone.pos1.y, tZone.pos2.y), math.min(tZone.pos1.z, tZone.pos2.z))
    local max = Vector(math.max(tZone.pos1.x, tZone.pos2.x), math.max(tZone.pos1.y, tZone.pos2.y), math.max(tZone.pos1.z, tZone.pos2.z))

    IVO_QUEST.Zones[zoneID] = { min = min, max = max }
    IVO_QUEST.SaveZones()

    ply:ChatPrint("[Ivo_quest] ¡Zona '" .. zoneID .. "' guardada exitosamente!")
    tempZones[ply:SteamID()] = nil -- Limpiamos la memoria
end)

-----------------------------------------------------------
-- 3. LÓGICA DE ZONAS (Para usar dentro de las misiones)
-----------------------------------------------------------

-- Genera una posición aleatoria dentro de una zona (IDEAL PARA SPAWNEAR ENEMIGOS)
function IVO_QUEST.GetRandomPosInZone(zoneID)
    local zone = IVO_QUEST.Zones[zoneID]
    if not zone then return nil end
    
    return Vector(
        math.random(zone.min.x, zone.max.x),
        math.random(zone.min.y, zone.max.y),
        zone.min.z + 10 -- Le sumamos 10 en Z para que los NPCs no se queden atascados en el piso
    )
end

-- Verifica si un punto (jugador o entidad) está dentro de la zona (IDEAL PARA ZONAS DE ENTREGA)
function IVO_QUEST.IsPosInZone(pos, zoneID)
    local zone = IVO_QUEST.Zones[zoneID]
    if not zone then return false end
    
    -- WithinAABox es una función nativa de GMod que detecta si un vector está dentro de un cubo
    return pos:WithinAABox(zone.min, zone.max)
end

-----------------------------------------------------------
-- 4. VISUALIZADOR DE ZONAS (DEBUG)
-----------------------------------------------------------
util.AddNetworkString("IvoQuest_ShowZones")

concommand.Add("ivo_zone_show", function(ply)
    if not ply:IsSuperAdmin() then return end
    
    local count = table.Count(IVO_QUEST.Zones)
    
    if count > 0 then
        -- En vez de intentar dibujarlo en el servidor, le mandamos las zonas al jugador
        net.Start("IvoQuest_ShowZones")
        net.WriteTable(IVO_QUEST.Zones)
        net.Send(ply)
        
        ply:ChatPrint("[Ivo_quest] Hologramas activados. Mostrando " .. count .. " zonas por 15 segundos...")
    else
        ply:ChatPrint("[Ivo_quest] No hay zonas creadas en este mapa.")
    end
end)

-----------------------------------------------------------
-- 5. ELIMINAR ZONAS
-----------------------------------------------------------
concommand.Add("ivo_zone_remove", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    local zoneID = args[1]
    
    if not zoneID then 
        ply:ChatPrint("Uso: ivo_zone_remove [nombre_de_la_zona]") 
        return 
    end

    -- Verificamos si la zona realmente existe en nuestra tabla
    if IVO_QUEST.Zones[zoneID] then
        -- La borramos de la memoria
        IVO_QUEST.Zones[zoneID] = nil
        
        -- Llamamos a la función de guardado para actualizar el archivo JSON
        IVO_QUEST.SaveZones()
        
        ply:ChatPrint("[Ivo_quest] ¡La zona '" .. zoneID .. "' ha sido eliminada permanentemente!")
    else
        ply:ChatPrint("[Ivo_quest] Error: No existe ninguna zona llamada '" .. zoneID .. "'.")
    end
end)

-----------------------------------------------------------
-- 6. CONEXIÓN CON EL EDITOR VISUAL (VGUI)
-----------------------------------------------------------
util.AddNetworkString("IvoQuest_RequestZones")
util.AddNetworkString("IvoQuest_SendZones")

net.Receive("IvoQuest_RequestZones", function(len, ply)
    if not ply:IsSuperAdmin() then return end
    net.Start("IvoQuest_SendZones")
    net.WriteTable(IVO_QUEST.Zones or {})
    net.Send(ply)
end)

concommand.Add("ivo_zone_tp", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    local zoneID = args[1]
    if not zoneID or not IVO_QUEST.Zones[zoneID] then return end
    local center = (IVO_QUEST.Zones[zoneID].min + IVO_QUEST.Zones[zoneID].max) / 2
    ply:SetPos(center)
    ply:ChatPrint("[Ivo_quest] Teletransportado al centro de la zona '" .. zoneID .. "'.")
end)