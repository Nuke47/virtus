-- lua/autorun/server/sv_music.lua

MusicQueue = MusicQueue or {} 
StartTime = StartTime or 0
local lastSkip = 0 

util.AddNetworkString("OpenMusicMenu")
util.AddNetworkString("Music_Stop")
util.AddNetworkString("Music_Action")
util.AddNetworkString("Music_Sync")

-- Hook de comandos para abrir el menú
hook.Add("PlayerSay", "AdminMusicCommand", function(ply, text)
    if string.lower(text) == "!adminmusic" then
        if ply:IsAdmin() then
            net.Start("OpenMusicMenu")
            net.Send(ply)
            return "" 
        else
            ply:ChatPrint("No tienes permisos para usar este comando.")
            return ""
        end
    end
end)

-- FUNCIÓN CRÍTICA: Aquí es donde calculamos y ENVIAMOS el segundo exacto
local function SendSync(ply)
    net.Start("Music_Sync")
    net.WriteTable(MusicQueue)
    
    -- MODIFICACIÓN AQUÍ: Calculamos cuántos segundos han pasado desde que empezó la canción
    local elapsed = (StartTime > 0 and #MusicQueue > 0) and (CurTime() - StartTime) or 0
    net.WriteFloat(elapsed) -- Le enviamos este número al cliente
    
    if ply then net.Send(ply) else net.Broadcast() end
end

-- Sincronizar al jugador cuando recién entra al servidor
hook.Add("PlayerInitialSpawn", "SyncMusicOnJoin", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) then
            SendSync(ply)
        end
    end)
end)

-- Receptor de acciones del menú
net.Receive("Music_Action", function(len, ply)
    local action = net.ReadString()
    
    -- AutoSkip: Lo envía cualquier cliente automáticamente cuando se le termina una canción
    if action == "AutoSkip" then
        if CurTime() - lastSkip < 3 then return end 
        lastSkip = CurTime()
        
        if #MusicQueue > 0 then
            table.remove(MusicQueue, 1)
            StartTime = (#MusicQueue > 0) and CurTime() or 0
        end
        
        if #MusicQueue == 0 then
            MusicQueue = {}
            StartTime = 0
            net.Start("Music_Stop")
            net.Broadcast()
            return
        end
        
        SendSync()
        return
    end
    
    -- El resto de acciones requieren estrictamente ser Admin
    if not ply:IsAdmin() then return end
    
    if action == "PlayNow" or action == "AddToQueue" then
        local name = net.ReadString()
        local url = net.ReadString()
        
        if action == "PlayNow" then
            MusicQueue = {{name = name, url = url}}
            StartTime = CurTime()
        elseif action == "AddToQueue" then
            table.insert(MusicQueue, {name = name, url = url})
            if #MusicQueue == 1 then StartTime = CurTime() end
        end
        
    elseif action == "Stop" then
        MusicQueue = {}
        StartTime = 0
        net.Start("Music_Stop")
        net.Broadcast()
        return 
        
    elseif action == "Skip" then
        if CurTime() - lastSkip < 2 then return end
        lastSkip = CurTime()
        
        if #MusicQueue > 0 then 
            table.remove(MusicQueue, 1) 
            StartTime = (#MusicQueue > 0) and CurTime() or 0
        end
        
        if #MusicQueue == 0 then
            net.Start("Music_Stop")
            net.Broadcast()
            return
        end
        
    elseif action == "Remove" then
        local index = net.ReadUInt(8)
        if index > 0 and index <= #MusicQueue then
            table.remove(MusicQueue, index)
            if index == 1 then 
                StartTime = (#MusicQueue > 0) and CurTime() or 0 
            end
            if #MusicQueue == 0 then
                net.Start("Music_Stop")
                net.Broadcast()
                return
            end
        end
    end
    
    SendSync() 
end)