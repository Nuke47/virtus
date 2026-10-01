-- ============================================================================
-- IVOSAM: COMANDOS DE GESTIÓN DE RANGOS
-- setrank, createrank, deleterank
-- ============================================================================
my_admin = my_admin or {}

my_admin.RegisterCommand("setrank", function(ply, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("[IVOSAM] No tienes permisos para usar este comando.")
        return
    end

    local target = my_admin.FindPlayer(args[1])
    local rankName = string.lower(args[2] or "")
    local timeInput = args[3] or "0"

    if IsValid(target) and IVO_SAM.Ranks[rankName] then
        local seconds = IVO_SAM.ParseTime(timeInput)
        local expireAt = (seconds > 0) and (os.time() + seconds) or 0
        my_admin.SetUserRank(target, rankName, expireAt, IsValid(ply) and ply:Nick() or "Console")
        local tiempoTexto = (seconds > 0) and (" por " .. IVO_SAM.FormatTime(seconds)) or " permanentemente"
        my_admin.Notify(ply, " otorgó a ", target, true, " el rango de " .. rankName:upper() .. tiempoTexto)
    else
        if IsValid(ply) then
            ply:ChatPrint("[IVOSAM] Jugador o rango no válido. Uso: !setrank <nombre> <rango> [tiempo]")
        end
    end
end, { usage = "!setrank <nombre> <rango> [tiempo]", desc = "Asignar rango a un jugador (ej: !setrank Lucas admin 7d)", level = "superadmin" })

my_admin.RegisterCommand("setrankid", function(ply, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("[IVOSAM] No tienes permisos para usar este comando.")
        return
    end

    local sid64 = args[1]
    local rankName = string.lower(args[2] or "")
    local timeInput = args[3] or "0"

    if not sid64 or sid64 == "" or not IVO_SAM.Ranks[rankName] then
        if IsValid(ply) then
            ply:ChatPrint("[IVOSAM] SteamID64 o rango no válido. Uso: !setrankid <steamid64> <rango> [tiempo]")
        end
        return
    end

    local seconds = IVO_SAM.ParseTime(timeInput)
    local expireAt = (seconds > 0) and (os.time() + seconds) or 0
    local adminName = IsValid(ply) and ply:Nick() or "Console"

    local tPlayer = player.GetBySteamID64(sid64)
    if IsValid(tPlayer) then
        my_admin.SetUserRank(tPlayer, rankName, expireAt, adminName)
    else
        IVO_SAM.DB.Query("SELECT steamid64 FROM ivosam_users WHERE steamid64 = " .. IVO_SAM.DB.Escape(sid64), function(check)
            if check then
                IVO_SAM.DB.Query(string.format("UPDATE ivosam_users SET `rank` = %s, expire = %d, admin = %s, date = %s WHERE steamid64 = %s;",
                    IVO_SAM.DB.Escape(rankName), expireAt, IVO_SAM.DB.Escape(adminName), IVO_SAM.DB.Escape(os.date("%d/%m/%Y")), IVO_SAM.DB.Escape(sid64)))
            else
                IVO_SAM.DB.Query(string.format("INSERT INTO ivosam_users (steamid64, `rank`, expire, admin, date) VALUES (%s, %s, %d, %s, %s);",
                    IVO_SAM.DB.Escape(sid64), IVO_SAM.DB.Escape(rankName), expireAt, IVO_SAM.DB.Escape(adminName), IVO_SAM.DB.Escape(os.date("%d/%m/%Y"))))
            end
        end)
    end

    local tiempoTexto = (seconds > 0) and (" por " .. IVO_SAM.FormatTime(seconds)) or " permanentemente"
    my_admin.Notify(ply, " otorgó a la ID " .. sid64 .. " el rango de ", nil, true, rankName:upper() .. tiempoTexto)
end, { usage = "!setrankid <steamid64> <rango> [tiempo]", desc = "Asignar rango por SteamID64 (offline)", level = "superadmin" })

my_admin.RegisterCommand("createrank", function(ply, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("[IVOSAM] No tienes permisos para usar este comando.")
        return
    end

    local rankName = string.lower(args[1] or "")
    local powerVal = tonumber(args[2]) or 0

    if rankName == "" then
        return ply:ChatPrint("[IVOSAM] Uso: !createrank <nombre_rango> <poder>")
    end

    if IVO_SAM.Ranks[rankName] then
        return ply:ChatPrint("[IVOSAM] El rango '" .. rankName .. "' ya existe.")
    end

    IVO_SAM.Ranks[rankName] = {
        power = powerVal,
        color = Color(255, 255, 255),
        permissions = { ["IsAdmin"] = false, ["CanBan"] = false, ["CanKick"] = false, ["CanSlay"] = false, ["CanSeeESP"] = false }
    }

    file.Write("ivosam/ranks_database.txt", util.TableToJSON(IVO_SAM.Ranks, true))

    net.Start("IVO_SyncRanks")
        net.WriteTable(IVO_SAM.Ranks)
    net.Broadcast()

    my_admin.Notify(ply, " creó el rango de manera exitosa: ", nil, false, rankName .. " (Poder: " .. powerVal .. ")")
end, { usage = "!createrank <nombre> <poder>", desc = "Crear un nuevo rango personalizado (poder 1-100)", level = "superadmin" })

my_admin.RegisterCommand("deleterank", function(ply, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("[IVOSAM] No tienes permisos para usar este comando.")
        return
    end

    local rankName = string.lower(args[1] or "")

    if rankName == "" then
        return ply:ChatPrint("[IVOSAM] Uso: !deleterank <nombre_rango>")
    end

    if rankName == "user" or rankName == "admin" or rankName == "superadmin" then
        return ply:ChatPrint("[IVOSAM] No puedes eliminar los rangos por defecto del sistema.")
    end

    if not IVO_SAM.Ranks[rankName] then
        return ply:ChatPrint("[IVOSAM] El rango '" .. rankName .. "' no existe.")
    end

    IVO_SAM.Ranks[rankName] = nil
    file.Write("ivosam/ranks_database.txt", util.TableToJSON(IVO_SAM.Ranks, true))

    net.Start("IVO_SyncRanks")
        net.WriteTable(IVO_SAM.Ranks)
    net.Broadcast()

    my_admin.Notify(ply, " eliminó el rango del sistema: ", nil, false, rankName)
end, { usage = "!deleterank <nombre>", desc = "Eliminar un rango personalizado del sistema", level = "superadmin" })
