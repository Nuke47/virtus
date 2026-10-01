-- ============================================================================
-- IVOSAM: COMANDOS DE XP Y NIVEL
-- ============================================================================

local function ResolveTarget(ply, targetId)
    if not targetId or targetId == "" then return nil, nil end
    local target = my_admin.FindPlayer(targetId)
    
    if IsValid(target) then
        return target, target:SteamID64()
    end
    
    -- Si no se encontró online, validar si es una ID válida
    if string.match(targetId, "^STEAM_") or string.match(targetId, "^7656119%d+$") then
        return nil, targetId
    end
    
    if IsValid(ply) then ply:ChatPrint("No se encontró al jugador o la ID es inválida: " .. targetId) end
    return nil, nil
end

my_admin.RegisterCommand("addxp", function(ply, args)
    local targetId = args[1]
    local amount = tonumber(args[2])
    
    if not targetId or not amount then
        if IsValid(ply) then ply:ChatPrint("[IVOSAM] Uso: !addxp <Nombre/SteamID> <cantidad>") end
        return
    end

    local targetEnt, finalId = ResolveTarget(ply, targetId)
    if not finalId then return end

    local success = IVO_SAM.ModifyOfflinePlayerXP(finalId, "xp", amount, true)
    if success then
        if IsValid(targetEnt) then
            my_admin.Notify(ply, " añadió experiencia a ", targetEnt, false, amount .. " XP")
        else
            my_admin.Notify(ply, " añadió experiencia a la ID ", nil, false, finalId .. " (" .. amount .. " XP)")
        end
    else
        if IsValid(ply) then ply:ChatPrint("[IVOSAM] Error al modificar la XP de " .. targetId) end
    end
end, { usage = "!addxp <Nombre/SteamID> <cantidad>", desc = "Añade XP a un jugador", level = "superadmin" })

my_admin.RegisterCommand("setxp", function(ply, args)
    local targetId = args[1]
    local amount = tonumber(args[2])
    
    if not targetId or not amount then
        if IsValid(ply) then ply:ChatPrint("[IVOSAM] Uso: !setxp <Nombre/SteamID> <cantidad>") end
        return
    end

    local targetEnt, finalId = ResolveTarget(ply, targetId)
    if not finalId then return end

    local success = IVO_SAM.ModifyOfflinePlayerXP(finalId, "xp", amount, false)
    if success then
        if IsValid(targetEnt) then
            my_admin.Notify(ply, " le estableció la XP a ", targetEnt, false, " a " .. amount)
        else
            my_admin.Notify(ply, " le estableció la XP a la ID ", nil, false, finalId .. " a " .. amount)
        end
    else
        if IsValid(ply) then ply:ChatPrint("[IVOSAM] Error al modificar la XP de " .. targetId) end
    end
end, { usage = "!setxp <Nombre/SteamID> <cantidad>", desc = "Establece la XP de un jugador", level = "superadmin" })

my_admin.RegisterCommand("setlevel", function(ply, args)
    local targetId = args[1]
    local amount = tonumber(args[2])
    
    if not targetId or not amount then
        if IsValid(ply) then ply:ChatPrint("[IVOSAM] Uso: !setlevel <Nombre/SteamID> <nivel>") end
        return
    end

    local targetEnt, finalId = ResolveTarget(ply, targetId)
    if not finalId then return end

    local success = IVO_SAM.ModifyOfflinePlayerXP(finalId, "level", amount, false)
    if success then
        if IsValid(targetEnt) then
            my_admin.Notify(ply, " le estableció el Nivel a ", targetEnt, false, " a Nivel " .. amount)
        else
            my_admin.Notify(ply, " le estableció el Nivel a la ID ", nil, false, finalId .. " a Nivel " .. amount)
        end
    else
        if IsValid(ply) then ply:ChatPrint("[IVOSAM] Error al establecer el nivel de " .. targetId) end
    end
end, { usage = "!setlevel <Nombre/SteamID> <nivel>", desc = "Establece el nivel de un jugador", level = "superadmin" })

my_admin.RegisterCommand("resetxp", function(ply, args)
    local targetId = args[1]
    if not targetId then
        if IsValid(ply) then ply:ChatPrint("[IVOSAM] Uso: !resetxp <Nombre/SteamID>") end
        return
    end

    local targetEnt, finalId = ResolveTarget(ply, targetId)
    if not finalId then return end

    IVO_SAM.ModifyOfflinePlayerXP(finalId, "xp", 0, false)
    IVO_SAM.ModifyOfflinePlayerXP(finalId, "level", 1, false)

    if IsValid(targetEnt) then
        my_admin.Notify(ply, " reinició completamente la XP Global y Nivel de ", targetEnt, false, "")
    else
        my_admin.Notify(ply, " reinició completamente la XP Global y Nivel de la ID ", nil, false, finalId)
    end
end, { usage = "!resetxp <Nombre/SteamID>", desc = "Reinicia la XP global a 0 y nivel 1", level = "superadmin" })

my_admin.RegisterCommand("resetjobxp", function(ply, args)
    local targetId = args[1]
    if not targetId then
        if IsValid(ply) then ply:ChatPrint("[IVOSAM] Uso: !resetjobxp <Nombre/SteamID>") end
        return
    end

    local targetEnt, finalId = ResolveTarget(ply, targetId)
    if not finalId then return end

    IVO_SAM.DB.Query(string.format("DELETE FROM ivosam_job_xp WHERE steamid64 = %s;", IVO_SAM.DB.Escape(finalId)))
    
    if IsValid(targetEnt) then
        -- Borrar la memoria en cache y recargarla vacía
        if IVO_SAM.JobDataCache and IVO_SAM.JobDataCache[finalId] then
            for cmd, _ in pairs(IVO_SAM.JobDataCache[finalId]) do
                targetEnt:SetNWInt("IVO_JobXP_" .. cmd, 0)
                targetEnt:SetNWInt("IVO_JobLevel_" .. cmd, 1)
                targetEnt:SetNWInt("IVO_JobTime_" .. cmd, 0)
            end
            IVO_SAM.JobDataCache[finalId] = {}
        end
        my_admin.Notify(ply, " borró TODO el progreso de Trabajos de ", targetEnt, false, "")
    else
        my_admin.Notify(ply, " borró TODO el progreso de Trabajos de la ID ", nil, false, finalId)
    end
end, { usage = "!resetjobxp <Nombre/SteamID>", desc = "Borra el progreso de todos los trabajos del jugador", level = "superadmin" })

my_admin.RegisterCommand("resetjob", function(ply, args)
    local targetId = args[1]
    if not targetId then
        if IsValid(ply) then ply:ChatPrint("[IVOSAM] Uso: !resetjob <Nombre/SteamID>") end
        return
    end

    local targetEnt, finalId = ResolveTarget(ply, targetId)
    if not finalId then return end
    
    if not IsValid(targetEnt) then
        if IsValid(ply) then ply:ChatPrint("[IVOSAM] El jugador debe estar conectado para borrar su trabajo actual.") end
        return
    end
    
    local cmd = targetEnt.getJobTable and targetEnt:getJobTable() and IVO_SAM.GetJobSpecialty(targetEnt:getJobTable())
    if not cmd or cmd == "" then return end

    -- Borrar de la base de datos SOLO el trabajo actual
    IVO_SAM.DB.Query(string.format("DELETE FROM ivosam_job_xp WHERE steamid64 = %s AND job_cmd = %s;", IVO_SAM.DB.Escape(finalId), IVO_SAM.DB.Escape(cmd)))
    
    -- Borrar de la memoria en red
    if IVO_SAM.JobDataCache and IVO_SAM.JobDataCache[finalId] and IVO_SAM.JobDataCache[finalId][cmd] then
        targetEnt:SetNWInt("IVO_JobXP_" .. cmd, 0)
        targetEnt:SetNWInt("IVO_JobLevel_" .. cmd, 1)
        targetEnt:SetNWInt("IVO_JobTime_" .. cmd, 0)
        IVO_SAM.JobDataCache[finalId][cmd] = nil
    end
    
    my_admin.Notify(ply, " reinició el progreso del TRABAJO ACTUAL (", targetEnt, false, string.upper(targetEnt:getJobTable().name) .. ")")
end, { usage = "!resetjob <Nombre/SteamID>", desc = "Borra el progreso SOLO del trabajo que tiene puesto el jugador", level = "superadmin" })
