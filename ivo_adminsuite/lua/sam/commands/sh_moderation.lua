-- ============================================================================
-- IVOSAM: COMANDOS DE MODERACIÓN
-- freeze, unfreeze, cloak, uncloak, jail, unjail, kick, ban, banid, unban
-- + CheckPassword (fuente canónica del sistema de baneos)
-- ============================================================================
my_admin = my_admin or {}

my_admin.RegisterCommand("freeze", function(ply, args)
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !freeze <nombre>") end

    local target = my_admin.FindPlayer(info)
    if IsValid(target) then
        
        -- ==========================================================
        -- TU SISTEMA DE SEGURIDAD JERÁRQUICA IVO_SAM (ONLINE)
        -- ==========================================================
        if IsValid(ply) and target ~= ply then
            local plyRank = isfunction(ply.GetRank) and ply:GetRank():lower() or "user"
            local plyPower = IVO_SAM.Ranks[plyRank] and IVO_SAM.Ranks[plyRank].power or 0

            local targetRank = isfunction(target.GetRank) and target:GetRank():lower() or "user"
            local targetPower = IVO_SAM.Ranks[targetRank] and IVO_SAM.Ranks[targetRank].power or 0

            if plyPower < targetPower and targetPower > 0 then
                return ply:ChatPrint("[IVOSAM] Inmunidad: No puedes congelar a " .. target:Nick() .. " porque pertenece a un rango superior (" .. targetRank:upper() .. ").")
            end
        end
        -- ==========================================================

        if target ~= ply and not IVO_SAM.CheckTarget(ply, target, "congelar") then return end
        
        target:Lock()
        my_admin.Notify(ply, " congeló a ", target, false)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end, { usage = "!freeze <nombre>", desc = "Congelar a un jugador en su lugar", level = "admin" })

my_admin.RegisterCommand("unfreeze", function(ply, args)
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !unfreeze <nombre>") end

    local target = my_admin.FindPlayer(info)
    if IsValid(target) then
        
        -- ==========================================================
        -- TU SISTEMA DE SEGURIDAD JERÁRQUICA IVO_SAM (ONLINE)
        -- ==========================================================
        if IsValid(ply) and target ~= ply then
            local plyRank = isfunction(ply.GetRank) and ply:GetRank():lower() or "user"
            local plyPower = IVO_SAM.Ranks[plyRank] and IVO_SAM.Ranks[plyRank].power or 0

            local targetRank = isfunction(target.GetRank) and target:GetRank():lower() or "user"
            local targetPower = IVO_SAM.Ranks[targetRank] and IVO_SAM.Ranks[targetRank].power or 0

            if plyPower < targetPower and targetPower > 0 then
                return ply:ChatPrint("[IVOSAM] Inmunidad: No puedes descongelar a " .. target:Nick() .. " porque pertenece a un rango superior (" .. targetRank:upper() .. ").")
            end
        end
        -- ==========================================================

        -- 1. Limpieza del comando de chat clásico (!freeze)
        target:UnLock()
        
        -- 2. Limpieza de los efectos físicos aplicados por la Physgun (sv_physgun_model_2.lua)
        target:Freeze(false)
        target:SetMoveType(MOVETYPE_WALK)
        target.IvosamFrozen = nil
        target:GodDisable() -- Remueve cualquier residuo de God Mode
        
        -- Opcional: Si manejas logs para este comando, puedes descomentar la siguiente línea
        -- if IVO_SAM and IVO_SAM.Log then IVO_SAM.Log(ply, "unfreeze", target) end

        my_admin.Notify(ply, " descongeló a ", target, false)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end, { usage = "!unfreeze <nombre>", desc = "Descongelar y remover inmortalidad a un jugador", level = "admin" })

my_admin.RegisterCommand("cloak", function(ply, args)
    local info = args[1]
    local target = (not info or info == "") and ply or my_admin.FindPlayer(info)

    if IsValid(target) then
        if target ~= ply and not IVO_SAM.CheckTarget(ply, target, "hacer invisible a") then return end
        if target:GetNWBool("IsCloaked", false) then
            ply:ChatPrint(target:Nick() .. " ya es invisible.")
        else
            target:SetNoDraw(true)
            target:DrawShadow(false)
            local weapon = target:GetActiveWeapon()
            if IsValid(weapon) then weapon:SetNoDraw(true) end
            target:SetNWBool("IsCloaked", true)
            my_admin.Notify(ply, " hizo invisible a ", target, false)
        end
    else
        ply:ChatPrint("No se encontró a \"" .. tostring(info) .. "\"")
    end
end, { usage = "!cloak [nombre]", desc = "Hacer invisible a un jugador (o a ti mismo)", level = "admin" })

my_admin.RegisterCommand("uncloak", function(ply, args)
    local info = args[1]
    local target = (not info or info == "") and ply or my_admin.FindPlayer(info)

    if IsValid(target) then
        if target ~= ply and not IVO_SAM.CheckTarget(ply, target, "quitarle la invisibilidad a") then return end
        if not target:GetNWBool("IsCloaked", false) then
            ply:ChatPrint(target:Nick() .. " no es invisible.")
        else
            target:SetNoDraw(false)
            target:DrawShadow(true)
            local weapon = target:GetActiveWeapon()
            if IsValid(weapon) then weapon:SetNoDraw(false) end
            target:SetNWBool("IsCloaked", false)
            my_admin.Notify(ply, " hizo visible a ", target, false)
        end
    else
        ply:ChatPrint("No se encontró a \"" .. tostring(info) .. "\"")
    end
end, { usage = "!uncloak [nombre]", desc = "Quitar invisibilidad a un jugador", level = "admin" })

my_admin.RegisterCommand("jail", function(ply, args)
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !jail <nombre/id>") end

    local target = my_admin.FindPlayer(info)
    if IsValid(target) then
        
        -- ==========================================================
        -- TU SISTEMA DE SEGURIDAD JERÁRQUICA IVO_SAM (ONLINE)
        -- ==========================================================
        if IsValid(ply) and target ~= ply then
            local plyRank = isfunction(ply.GetRank) and ply:GetRank():lower() or "user"
            local plyPower = IVO_SAM.Ranks[plyRank] and IVO_SAM.Ranks[plyRank].power or 0

            local targetRank = isfunction(target.GetRank) and target:GetRank():lower() or "user"
            local targetPower = IVO_SAM.Ranks[targetRank] and IVO_SAM.Ranks[targetRank].power or 0

            if plyPower < targetPower and targetPower > 0 then
                return ply:ChatPrint("[IVOSAM] Inmunidad: No puedes encarcelar a " .. target:Nick() .. " porque pertenece a un rango superior (" .. targetRank:upper() .. ").")
            end
        end
        -- ==========================================================

        if target ~= ply and not IVO_SAM.CheckTarget(ply, target, "encarcelar") then return end
        
        -- Acciones nativas del jail (así se evitan desarmes accidentales a staffs superiores)
        target:Lock()
        target:StripWeapons()
        target:SetMoveType(MOVETYPE_NONE)
        target:SetNWBool("IsJailed", true)
        
        my_admin.Notify(ply, " encarceló a ", target, false)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end, { usage = "!jail <nombre/id>", desc = "Encarcelar a un jugador (sin movimiento ni armas)", level = "admin" })

my_admin.RegisterCommand("unjail", function(ply, args)
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !unjail <nombre/id>") end

    local target = my_admin.FindPlayer(info)
    if IsValid(target) then
        target:UnLock()
        target:SetMoveType(MOVETYPE_WALK)
        target:SetNWBool("IsJailed", false)
        target:Spawn()
        my_admin.Notify(ply, " liberó a ", target, false)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end, { usage = "!unjail <nombre/id>", desc = "Liberar a un jugador encarcelado", level = "admin" })

my_admin.RegisterCommand("kick", function(ply, args)
    local info = args[1]
    local reason = table.concat(args, " ", 2)
    if reason == "" then reason = IVO_SAM.Config.DEFAULT_KICK_REASON end
    if not info then return ply:ChatPrint("Uso: !kick <nombre/id> <motivo>") end

    local target = my_admin.FindPlayer(info)
    if IsValid(target) then
        
        -- ==========================================================
        -- TU SISTEMA DE SEGURIDAD JERÁRQUICA IVO_SAM (ONLINE)
        -- ==========================================================
        if IsValid(ply) and target ~= ply then
            local plyRank = isfunction(ply.GetRank) and ply:GetRank():lower() or "user"
            local plyPower = IVO_SAM.Ranks[plyRank] and IVO_SAM.Ranks[plyRank].power or 0

            local targetRank = isfunction(target.GetRank) and target:GetRank():lower() or "user"
            local targetPower = IVO_SAM.Ranks[targetRank] and IVO_SAM.Ranks[targetRank].power or 0

            if plyPower < targetPower and targetPower > 0 then
                return ply:ChatPrint("[IVOSAM] Inmunidad: No puedes expulsar a " .. target:Nick() .. " porque pertenece a un rango superior (" .. targetRank:upper() .. ").")
            end
        end
        -- ==========================================================

        if target ~= ply and not IVO_SAM.CheckTarget(ply, target, "expulsar") then return end
        
        -- ==========================================================
        -- [NUEVO] LANZAR EL HOOK PARA TU SISTEMA DE LOGS
        -- ==========================================================
        hook.Run("IVO_SAM_PlayerKicked", ply, target, reason)
        -- ==========================================================

        my_admin.Notify(ply, " expulsó a ", target, false)
        local targetToKick = target
        timer.Simple(0.1, function()
            if IsValid(targetToKick) then targetToKick:Kick("Expulsado por: " .. reason) end
        end)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end, { usage = "!kick <nombre/id> [motivo]", desc = "Expulsar a un jugador del servidor", level = "admin" })


my_admin.RegisterCommand("ban", function(ply, args)
    local info = args[1]
    local rawTime = args[2] or "0"
    local reason = table.concat(args, " ", 3)
    if not reason or reason == "" then reason = IVO_SAM.Config.DEFAULT_BAN_REASON end
    if not info then return ply:ChatPrint("Uso: !ban <nombre/id> <tiempo> <motivo>") end

    local target = my_admin.FindPlayer(info)
    if IsValid(target) then
        
        -- ==========================================================
        -- TU SISTEMA DE SEGURIDAD JERÁRQUICA IVO_SAM (ONLINE)
        -- ==========================================================
        if IsValid(ply) and target ~= ply then
            local plyRank = isfunction(ply.GetRank) and ply:GetRank():lower() or "user"
            local plyPower = IVO_SAM.Ranks[plyRank] and IVO_SAM.Ranks[plyRank].power or 0

            local targetRank = isfunction(target.GetRank) and target:GetRank():lower() or "user"
            local targetPower = IVO_SAM.Ranks[targetRank] and IVO_SAM.Ranks[targetRank].power or 0

            if plyPower < targetPower and targetPower > 0 then
                return ply:ChatPrint("[IVOSAM] Inmunidad: No puedes banear a " .. target:Nick() .. " porque pertenece a un rango superior (" .. targetRank:upper() .. ").")
            end
        end
        -- ==========================================================

        if IsValid(ply) and target ~= ply and not IVO_SAM.CheckTarget(ply, target, "banear") then return end

        local seconds = IVO_SAM.ParseTime(rawTime) or 0
        local targetNick = target:Nick()
        local adminNick = IsValid(ply) and ply:Nick() or "Console"

        local sid64, steamid
        if target:IsBot() then
            -- Prefijo BOT_ para evitar colisiones con SteamID64 reales
            sid64 = "BOT_" .. target:UserID()
            steamid = "BOT_" .. target:UserID()
        else
            sid64 = target:SteamID64()
            steamid = target:SteamID()
        end

        if not sid64 or not steamid then
            return IsValid(ply) and ply:ChatPrint("Error: No se pudo obtener la identidad de red del jugador.")
        end

        local unbanTime = (seconds == 0) and 0 or (os.time() + seconds)
        IVO_SAM.DB.Query(string.format(
            "REPLACE INTO ivosam_bans (steamid64, name, steamid, duration, unban_time, reason, admin, date) VALUES (%s, %s, %s, %d, %d, %s, %s, %s);",
            IVO_SAM.DB.Escape(sid64), IVO_SAM.DB.Escape(targetNick), IVO_SAM.DB.Escape(steamid), seconds, unbanTime,
            IVO_SAM.DB.Escape(reason), IVO_SAM.DB.Escape(adminNick), IVO_SAM.DB.Escape(os.date("%d/%m/%Y"))
        ))

        local tiempoTexto = " permanentemente"
        if seconds > 0 then
            tiempoTexto = isfunction(IVO_SAM.FormatPlaytime) and (" por " .. IVO_SAM.FormatPlaytime(seconds)) or (" por " .. math.floor(seconds / 60) .. " minutos")
        end

        -- ==========================================================
        -- [NUEVO] LANZAR EL HOOK PARA TU SISTEMA DE LOGS
        -- ==========================================================
        hook.Run("IVO_SAM_PlayerBanned", ply, target, seconds, reason, tiempoTexto, steamid, sid64)
        -- ==========================================================

        my_admin.Notify(ply, " baneó a ", target, true, tiempoTexto .. " (" .. reason .. ")")
        timer.Simple(0.3, function()
            if IsValid(target) then target:Kick("\n[IVOSAM]\nBaneado" .. tiempoTexto .. "\nMotivo: " .. reason) end
        end)
    else
        if IsValid(ply) then ply:ChatPrint("No se encontró al jugador.") end
    end
end, { usage = "!ban <nombre/id> <tiempo> [motivo]", desc = "Banear a un jugador online (ej: 1h, 7d, 0=permanente)", level = "admin" })

my_admin.RegisterCommand("banid", function(ply, args)
    local inputID = args[1]
    local rawTime = args[2] or "0"
    local reason = table.concat(args, " ", 3)
    if not reason or reason == "" then reason = IVO_SAM.Config.DEFAULT_BAN_REASON end
    if not inputID then
        return IsValid(ply) and ply:ChatPrint("Uso: !banid <SteamID / SteamID64> <tiempo> <motivo>")
    end

    local sid64, steamid
    if string.StartWith(inputID, "7656119") and string.len(inputID) == 17 then
        sid64 = inputID
        steamid = util.SteamIDFrom64(sid64) or "STEAM_0:UNKNOWN"
    elseif string.StartWith(inputID, "STEAM_") then
        steamid = inputID
        sid64 = util.SteamIDTo64(steamid)
        if sid64 == "0" then sid64 = nil end
    elseif string.StartWith(inputID, "BOT_") then
        steamid = inputID
        sid64 = inputID
    end

    if not sid64 or not steamid then
        return IsValid(ply) and ply:ChatPrint("[IVOSAM] Error: El formato de ID ingresado no es válido.")
    end

    local onlinePlayer = nil
    local targetNick = "Jugador Offline"

    if string.StartWith(steamid, "BOT_") then
        for _, p in ipairs(player.GetAll()) do
            if p:IsBot() then
                local warnFormat = "BOT_" .. string.gsub(p:Nick(), "%s+", "_")
                local adminFormat = "BOT_" .. p:UserID()
                if steamid == warnFormat or steamid == adminFormat then
                    onlinePlayer = p
                    break
                end
            end
        end
    else
        onlinePlayer = player.GetBySteamID64(sid64)
    end

    if IsValid(onlinePlayer) then
        targetNick = onlinePlayer:Nick()
    end

    local seconds = IVO_SAM.ParseTime(rawTime) or 0
    local adminNick = IsValid(ply) and ply:Nick() or "Console"
    local unbanTime = (seconds == 0) and 0 or (os.time() + seconds)

    IVO_SAM.DB.Query(string.format(
        "REPLACE INTO ivosam_bans (steamid64, name, steamid, duration, unban_time, reason, admin, date) VALUES (%s, %s, %s, %d, %d, %s, %s, %s);",
        IVO_SAM.DB.Escape(sid64), IVO_SAM.DB.Escape(targetNick), IVO_SAM.DB.Escape(steamid), seconds, unbanTime,
        IVO_SAM.DB.Escape(reason), IVO_SAM.DB.Escape(adminNick), IVO_SAM.DB.Escape(os.date("%d/%m/%Y"))
    ))

    local tiempoTexto = " permanentemente"
    if seconds > 0 then
        tiempoTexto = isfunction(IVO_SAM.FormatPlaytime) and (" por " .. IVO_SAM.FormatPlaytime(seconds)) or (" por " .. math.floor(seconds / 60) .. " minutos")
    end

    local msgFinal = tiempoTexto .. " (" .. reason .. ")"
    
    hook.Run("IVO_SAM_PlayerBanID", ply, onlinePlayer, targetNick, steamid, sid64, seconds, reason, tiempoTexto)

    if IsValid(onlinePlayer) then
        my_admin.Notify(ply, " baneó a ", onlinePlayer, true, msgFinal)
        timer.Simple(0.3, function()
            if IsValid(onlinePlayer) then onlinePlayer:Kick("\n[IVOSAM]\nBaneado" .. tiempoTexto .. "\nMotivo: " .. reason) end
        end)
    else
        my_admin.Notify(ply, " baneó a la ID (" .. steamid .. " - " .. targetNick .. ") ", nil, true, msgFinal .. " [OFFLINE]")
    end
end, { usage = "!banid <id> <tiempo> [motivo]", desc = "Banear por SteamID/SteamID64", level = "admin" })


hook.Add("CheckPassword", "IVO_SAM_CheckBans", function(sid64, ipAddress, svPassword, clPassword, name)
    local p = player.GetBySteamID64(sid64)
    if IsValid(p) and p:IsBot() then return end
    
    local qSid64 = IVO_SAM.DB.Escape(sid64)
    IVO_SAM.DB.QueryRow("SELECT * FROM ivosam_bans WHERE steamid64 = " .. qSid64 .. ";", function(data)
        if not data then return end

        local unbanTime = tonumber(data.unban_time) or 0
        local reason = data.reason or "Sin motivo especificado"
        local adminName = data.admin or "Consola"

        if unbanTime ~= 0 then
            local remaining = unbanTime - os.time()
            if remaining <= 0 then
                IVO_SAM.DB.Query("DELETE FROM ivosam_bans WHERE steamid64 = " .. qSid64 .. ";")
                return
            end
            local timeLeft = isfunction(IVO_SAM.FormatPlaytime) and IVO_SAM.FormatPlaytime(remaining) or (math.ceil(remaining / 60) .. " minutos")
            game.KickID(sid64, "\n[ SISTEMA DE ADMINISTRACIÓN ]\n" ..
                          "------------------------------------\n" ..
                          "ESTADO: BANEADO TEMPORALMENTE\n\n" ..
                          "Admin: " .. adminName .. "\n" ..
                          "Motivo: " .. reason .. "\n\n" ..
                          "TIEMPO RESTANTE:\n" .. timeLeft .. "\n" ..
                          "------------------------------------")
        else
            game.KickID(sid64, "\n[ SISTEMA DE ADMINISTRACIÓN ]\n" ..
                          "------------------------------------\n" ..
                          "ESTADO: BANEADO PERMANENTE\n\n" ..
                          "Admin: " .. adminName .. "\n" ..
                          "Motivo: " .. reason .. "\n\n" ..
                          "No puedes volver a entrar al servidor.\n" ..
                          "------------------------------------")
        end
    end)
end)
