util.AddNetworkString("virtus_radio_toggle")

-- Guardar el estado de radio de cada jugador
VIRTUS_RadioDisabled = VIRTUS_RadioDisabled or {}

net.Receive("virtus_radio_toggle", function(len, ply)
    local state = net.ReadBool()
    VIRTUS_RadioDisabled[ply:SteamID64()] = not state -- If true, it's enabled. So if false, disabled.
end)

-- Interceptar el hook de radio existente para bloquear si esta deshabilitado
hook.Add("PlayerCanHearPlayersVoice", "VIRTUS_RadioToggle_Hook", function(listener, talker)
    if VIRTUS_RadioDisabled[talker:SteamID64()] or VIRTUS_RadioDisabled[listener:SteamID64()] then
        -- Si alguno tiene la radio desactivada, ignoramos el sistema de radio de este addon y dejamos el default
        -- Wait, the original hook is also named "RadioChannelVoiceSystem".
        -- If we return nil, it passes to the next hook. But wait, we want to OVERRIDE the original hook if radio is disabled!
        -- The best way is to redefine the original hook!
    end
end)
