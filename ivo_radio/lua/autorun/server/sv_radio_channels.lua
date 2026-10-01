AddCSLuaFile("autorun/sh_radio_config.lua")
AddCSLuaFile("autorun/client/cl_radio_ui.lua")

util.AddNetworkString("NetworkRadioChannel")
util.AddNetworkString("RadioTransmitState")

_G.PlayerRadioChannels = _G.PlayerRadioChannels or {}
local playerRadioChannels = _G.PlayerRadioChannels
local playersTransmitting = {}

-- 1. Registro ultra-estable del estado de transmisiÃ³n
net.Receive("RadioTransmitState", function(len, ply)
    if not IsValid(ply) then return end
    playersTransmitting[ply:SteamID64()] = net.ReadBool()
end)

-- 2. ConexiÃ³n a canales con validaciÃ³n en tiempo real
net.Receive("NetworkRadioChannel", function(len, ply)
    if not IsValid(ply) then return end
    local channel = net.ReadInt(16)
    
    if channel == 0 then
        playerRadioChannels[ply:SteamID64()] = nil
        ply:ChatPrint("[Radio] Has apagado la radio.")
        return
    end

    local tienePermiso = false
    local nombreCanal = "Desconocido"

    if RadioFrequencies then
        local myTeamID = ply:Team()
        
        -- EscÃ¡ner de nombre de variable (Altos Mandos)
        local myJobStringName = ""
        for name, data in pairs(_G) do
            if string.sub(name, 1, 5) == "TEAM_" and data == myTeamID then
                myJobStringName = name
                break
            end
        end

        -- EscÃ¡ner de CategorÃ­a F4 del DarkRP
        local myCategory = "Desconocida"
        if DarkRP and DarkRP.getCategories and DarkRP.getCategories().jobs then
            for _, catTable in pairs(DarkRP.getCategories().jobs) do
                if catTable.members then
                    for _, jobData in ipairs(catTable.members) do
                        if jobData.team == myTeamID then
                            myCategory = catTable.name
                            break
                        end
                    end
                end
            end
        end

        if myCategory == "Desconocida" and RPExtraTeams and RPExtraTeams[myTeamID] then
            myCategory = RPExtraTeams[myTeamID].category or "Desconocida"
        end

        for _, data in ipairs(RadioFrequencies) do
            if data.channel == channel then
                nombreCanal = data.name

                if not data.category and not data.jobs then
                    tienePermiso = true
                end

                if data.category and myCategory == data.category then
                    tienePermiso = true
                end

                if data.jobs then
                    for _, jobString in ipairs(data.jobs) do
                        if myJobStringName == jobString then 
                            tienePermiso = true
                            break 
                        end
                    end
                end
                break
            end
        end
    end

    if tienePermiso then
        playerRadioChannels[ply:SteamID64()] = channel
        ply:ChatPrint("[Radio] Conectado a: " .. nombreCanal)
    else
        ply:ChatPrint("[Radio] Error: Tu rango o legiÃ³n militar no tiene acceso a esta frecuencia.")
    end
end)

-- =========================================================================
-- 3. ENRUTADOR FÃSICO DE AUDIO DEFINITIVO (BLOQUEA LA VOZ SI ESTÃ MUERTO)
-- =========================================================================
hook.Add("PlayerCanHearPlayersVoice", "RadioChannelVoiceSystem", function(listener, talker)
    -- VerificaciÃ³n de seguridad bÃ¡sica
    if not IsValid(listener) or not IsValid(talker) then return end

    -- REGLA CRÃTICA MILITAR: Si el emisor actual (talker) estÃ¡ muerto, se le bloquea la voz de inmediato
    if not talker:Alive() then 
        return false, false -- Cancela la radio y tambiÃ©n la voz por proximidad local
    end

    -- Obtenemos las sintonÃ­as de radio de ambos jugadores
    local talkerChannel = playerRadioChannels[talker:SteamID64()]
    local listenerChannel = playerRadioChannels[listener:SteamID64()]

    -- Si ambos comparten exactamente la misma frecuencia de radio en el servidor
    if talkerChannel and listenerChannel and (talkerChannel == listenerChannel) then
        -- Y el emisor mantiene pulsada su tecla H para modular por el canal
        if playersTransmitting[talker:SteamID64()] then
            return true, false -- Fuerza la escucha global en todo el mapa eliminando el eco 3D
        end
    end

    -- Si no estÃ¡n transmitiendo por radio, el juego aplica la voz de proximidad nativa por defecto
end)
-- 4. Enrutador fÃ­sico de voz bidireccional estable
hook.Add("PlayerCanHearPlayersVoice", "RadioChannelVoiceSystem", function(listener, talker)
    if not IsValid(listener) or not IsValid(talker) then return end

    if VIRTUS_RadioDisabled and (VIRTUS_RadioDisabled[talker:SteamID64()] or VIRTUS_RadioDisabled[listener:SteamID64()]) then
        return -- Si la radio esta apagada para cualquiera de los dos, dejamos que GMod maneje el audio local 3D normal
    end

    local talkerChannel = playerRadioChannels[talker:SteamID64()]
    local listenerChannel = playerRadioChannels[listener:SteamID64()]

    if talkerChannel and listenerChannel and (talkerChannel == listenerChannel) then
        if playersTransmitting[talker:SteamID64()] then
            return true, false 
        end
    end
end)

