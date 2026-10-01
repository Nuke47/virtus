-- ============================================================================
-- IVOSAM: COMANDOS DE GESTIÓN DE RANGOS SECUNDARIOS
-- setsecrank, createsecrank, deletesecrank, setsecrankid
-- ============================================================================
my_admin = my_admin or {}

my_admin.RegisterCommand("setsecrank", function(ply, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("[IVOSAM] No tienes permisos para usar este comando.")
        return
    end

    local target = my_admin.FindPlayer(args[1])
    local rankName = string.lower(args[2] or "")
    local timeInput = args[3] or "0"

    -- Si el rango es vacío o "user" se removerá
    if rankName == "user" then rankName = "" end

    if IsValid(target) and (rankName == "" or IVO_SAM.Ranks[rankName]) then
        local seconds = IVO_SAM.ParseTime(timeInput)
        local expireAt = (seconds > 0) and (os.time() + seconds) or 0
        my_admin.SetSecondaryRank(target, rankName, expireAt, IsValid(ply) and ply:Nick() or "Console")
        
        if rankName == "" then
            my_admin.Notify(ply, " eliminó el rango secundario a ", target, true, "")
        else
            local tiempoTexto = (seconds > 0) and (" por " .. IVO_SAM.FormatTime(seconds)) or " permanentemente"
            my_admin.Notify(ply, " otorgó el rango secundario a ", target, true, " de " .. rankName:upper() .. tiempoTexto)
        end
    else
        if IsValid(ply) then
            ply:ChatPrint("[IVOSAM] Jugador o rango secundario no válido. Uso: !setsecrank <nombre> <rango> [tiempo]")
        end
    end
end, { usage = "!setsecrank <nombre> <rango> [tiempo]", desc = "Asignar rango secundario", level = "superadmin" })

my_admin.RegisterCommand("setsecrankid", function(ply, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("[IVOSAM] No tienes permisos para usar este comando.")
        return
    end

    local sid64 = args[1]
    local rankName = string.lower(args[2] or "")
    local timeInput = args[3] or "0"

    if rankName == "user" then rankName = "" end

    if not sid64 or sid64 == "" or (rankName ~= "" and not IVO_SAM.Ranks[rankName]) then
        if IsValid(ply) then
            ply:ChatPrint("[IVOSAM] SteamID64 o rango secundario no válido. Uso: !setsecrankid <steamid64> <rango> [tiempo]")
        end
        return
    end

    local seconds = IVO_SAM.ParseTime(timeInput)
    local expireAt = (seconds > 0) and (os.time() + seconds) or 0
    local adminName = IsValid(ply) and ply:Nick() or "Console"

    local tPlayer = player.GetBySteamID64(sid64)
    if IsValid(tPlayer) then
        my_admin.SetSecondaryRank(tPlayer, rankName, expireAt, adminName)
    else
        IVO_SAM.DB.Query("SELECT steamid64 FROM ivosam_users WHERE steamid64 = " .. IVO_SAM.DB.Escape(sid64), function(check)
            if check then
                IVO_SAM.DB.Query(string.format("UPDATE ivosam_users SET sec_rank = %s, sec_expire = %d WHERE steamid64 = %s;",
                    IVO_SAM.DB.Escape(rankName), expireAt, IVO_SAM.DB.Escape(sid64)))
            else
                IVO_SAM.DB.Query(string.format("INSERT INTO ivosam_users (steamid64, `rank`, expire, admin, date, sec_rank, sec_expire) VALUES (%s, 'user', 0, %s, %s, %s, %d);",
                    IVO_SAM.DB.Escape(sid64), IVO_SAM.DB.Escape(adminName), IVO_SAM.DB.Escape(os.date("%d/%m/%Y")), IVO_SAM.DB.Escape(rankName), expireAt))
            end
        end)
    end

    if rankName == "" then
        my_admin.Notify(ply, " eliminó el rango secundario a la ID " .. sid64 .. "", nil, true, "")
    else
        local tiempoTexto = (seconds > 0) and (" por " .. IVO_SAM.FormatTime(seconds)) or " permanentemente"
        my_admin.Notify(ply, " otorgó el rango secundario a la ID " .. sid64 .. " de ", nil, true, rankName:upper() .. tiempoTexto)
    end
end, { usage = "!setsecrankid <steamid64> <rango> [tiempo]", desc = "Asignar rango secundario por SteamID64 (offline)", level = "superadmin" })


