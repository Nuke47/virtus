-- Los comandos se registran en el servidor
if SERVER then
    my_admin.RegisterCommand("gag", function(ply, args)
        local target = my_admin.FindPlayer(args[1] or "")
        if IsValid(target) then target:SetNWBool("IVOSAM_Gagged", true) my_admin.Notify(ply, " amordazó a ", target, true) end
    end)

    my_admin.RegisterCommand("ungag", function(ply, args)
        local target = my_admin.FindPlayer(args[1] or "")
        if IsValid(target) then target:SetNWBool("IVOSAM_Gagged", false) my_admin.Notify(ply, " desamordazó a ", target, true) end
    end)

    my_admin.RegisterCommand("mute", function(ply, args)
        local target = my_admin.FindPlayer(args[1] or "")
        if IsValid(target) then target:SetNWBool("IVOSAM_Muted", true) my_admin.Notify(ply, " silenció a ", target, true) end
    end)

    my_admin.RegisterCommand("unmute", function(ply, args)
        local target = my_admin.FindPlayer(args[1] or "")
        if IsValid(target) then target:SetNWBool("IVOSAM_Muted", false) my_admin.Notify(ply, " desilenció a ", target, true) end
    end)
end

-- Los HOOKS de bloqueo deben ejecutarse en ambos lados (Shared) o donde corresponda:
hook.Add("PlayerCanHearPlayersVoice", "IVOSAM_Bloquear_Gag", function(listener, talker)
    if talker:GetNWBool("IVOSAM_Gagged", false) then return false, false end
end)

hook.Add("PlayerSay", "IVOSAM_Bloquear_Mute", function(ply, text, teamChat)
    if ply:GetNWBool("IVOSAM_Muted", false) then
        if CLIENT and ply == LocalPlayer() then chat.AddText(Color(255,0,0), "[IVOSAM] Estás silenciado.") end
        return ""
    end
end)