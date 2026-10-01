util.AddNetworkString("IvoQuest_SaveMission")
util.AddNetworkString("IvoQuest_DeleteMission")

-- RECIBIR MISIÓN NUEVA O EDITADA
net.Receive("IvoQuest_SaveMission", function(len, ply)
    if not ply:IsSuperAdmin() then return end
    
    local missionID = net.ReadString()
    local dataLength = net.ReadUInt(32)
    local rawData = net.ReadData(dataLength)
    
    -- Descomprimimos los datos que vienen del menú
    local json = util.Decompress(rawData)
    local missionData = util.JSONToTable(json)
    
    if not missionData then return end

    -- Guardamos en la Base de Datos
    MISSION_SYSTEM.Missions[missionID] = missionData
    MISSION_SYSTEM.SaveDB()

    -- Avisamos a todos los jugadores del servidor que se actualizó la BD
    local compressed = util.Compress(util.TableToJSON(MISSION_SYSTEM.Missions))
    net.Start("IvoQuest_SyncMissions")
    net.WriteUInt(#compressed, 32)
    net.WriteData(compressed, #compressed)
    net.Broadcast()

    ply:ChatPrint("[Ivo_quest] ¡Misión '" .. missionID .. "' guardada exitosamente en la Base de Datos!")
end)

-- ELIMINAR MISIÓN DESDE EL MENÚ
net.Receive("IvoQuest_DeleteMission", function(len, ply)
    if not ply:IsSuperAdmin() then return end
    
    local missionID = net.ReadString()
    
    if MISSION_SYSTEM.Missions[missionID] then
        MISSION_SYSTEM.Missions[missionID] = nil
        MISSION_SYSTEM.SaveDB()
        
        -- Sincronizamos
        local compressed = util.Compress(util.TableToJSON(MISSION_SYSTEM.Missions))
        net.Start("IvoQuest_SyncMissions")
        net.WriteUInt(#compressed, 32)
        net.WriteData(compressed, #compressed)
        net.Broadcast()
        
        ply:ChatPrint("[Ivo_quest] Misión eliminada de forma permanente.")
    end
end)