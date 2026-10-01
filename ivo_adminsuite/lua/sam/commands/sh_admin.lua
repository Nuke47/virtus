
-- COMANDO GOTO
my_admin.RegisterCommand("goto", function(ply, args)
    
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !goto <nombre/steamid>") end

    local target = my_admin.FindPlayer(info)

    if IsValid(target) then
        if target == ply then return end
        my_admin.LastPositions[ply:SteamID64()] = ply:GetPos()
        
        ply:SetPos(target:GetPos() + target:GetForward() * -60 + Vector(0,0,10))
        ply:SetLocalVelocity(Vector(0,0,0))
        
        my_admin.Notify(ply, " fue hacia ", target, false)
    else
        -- Aquí es donde ocurre la magia: usamos 'info' que es lo que tú escribiste
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end)

-- COMANDO BRING
my_admin.RegisterCommand("bring", function(ply, args)
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !bring <nombre>") end

    my_admin.LastPositions = my_admin.LastPositions or {}
    local targets = my_admin.FindPlayers(info)

    if #targets > 0 then
        local namesTable = {}
        local count = #targets
        local radius = 80 + (count * 5)

        for i, target in ipairs(targets) do
            if not IsValid(target) or target == ply then continue end
            my_admin.LastPositions[target:SteamID64()] = target:GetPos()
            table.insert(namesTable, target:Nick())

            -- Teletransporte en círculo
            local angle = math.rad((i / count) * 360)
            local x = math.cos(angle) * radius
            local y = math.sin(angle) * radius
            target:SetPos(ply:GetPos() + Vector(x, y, 10))
            target:SetLocalVelocity(Vector(0, 0, 0))
            target:SetEyeAngles((ply:GetPos() - target:GetPos()):Angle())
        end

        if #namesTable == 1 then
            -- BRING NORMAL: Enviamos la entidad del único jugador
            local targetEntity = my_admin.FindPlayer(namesTable[1])
            IVO_SAM.Notify(ply, " trajo a ", targetEntity, true, "")
        else
            -- BRING MASIVO: Enviamos la lista de nombres con comas
            local listaNombres = table.concat(namesTable, ",")
            IVO_SAM.Notify(ply, " trajo a ", nil, true, listaNombres)
        end
    else
        ply:ChatPrint("No se encontró a nadie.")
    end
end)

-- COMANDO RETURN
my_admin.RegisterCommand("return", function(ply, args)
    
    local info = args[1]
    local target

    -- Si no pones nada, el objetivo eres tú mismo
    if not info or info == "" then
        target = ply
    else
        target = my_admin.FindPlayer(info)
    end

    if IsValid(target) then
        local oldPos = my_admin.LastPositions[target:SteamID64()]
        if oldPos then
            target:SetPos(oldPos)
            my_admin.LastPositions[target:SteamID64()] = nil
            my_admin.Notify(ply, " devolvió a ", target, false)
        else
            ply:ChatPrint("No hay posición guardada para " .. target:Nick())
        end
    else
        -- Si buscaste a alguien que no existe
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end)

--HP
my_admin.RegisterCommand("hp", function(ply, args)
    
    local info = args[1]
    local cantidad = tonumber(args[2]) or 100 -- Si no pones número, da 100
    
    if not info then return ply:ChatPrint("Uso: !hp <nombre/id> <cantidad>") end

    local target = my_admin.FindPlayer(info)

    if IsValid(target) then
        target:SetHealth(cantidad)

        -- El "cantidad" al final hará que salga en verde
        my_admin.Notify(ply, " cambió la vida de ", target, false, cantidad)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end)

--ARMOR

my_admin.RegisterCommand("armor", function(ply, args)
    
    local info = args[1]
    local cantidad = tonumber(args[2]) or 100
    
    if not info then return ply:ChatPrint("Uso: !armor <nombre/id> <cantidad>") end

    local target = my_admin.FindPlayer(info)

    if IsValid(target) then
        target:SetArmor(cantidad)
        
        -- El "cantidad" al final hará que salga en verde
        my_admin.Notify(ply, " cambió la armadura de ", target, false, cantidad)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end)

-- SLAY

my_admin.RegisterCommand("slay", function(ply, args)
    
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !slay <nombre/id>") end

    local target = my_admin.FindPlayer(info)

    if IsValid(target) then
        target:Kill()
        
        my_admin.Notify(ply, " asesinó a ", target, false)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end)

-- FREEZE (Congelar)
my_admin.RegisterCommand("freeze", function(ply, args)
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !freeze <nombre>") end

    local target = my_admin.FindPlayer(info)
    if IsValid(target) then
        target:Lock() -- Función nativa de GMod para congelar
        my_admin.Notify(ply, " congeló a ", target, false)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end)

-- UNFREEZE (Descongelar)
my_admin.RegisterCommand("unfreeze", function(ply, args)
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !unfreeze <nombre>") end

    local target = my_admin.FindPlayer(info)
    if IsValid(target) then
        target:UnLock()
        my_admin.Notify(ply, " descongeló a ", target, false)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end)

-- COMANDO CLOAK (Hacer invisible)
my_admin.RegisterCommand("cloak", function(ply, args)
    
    local info = args[1]
    local target = (not info or info == "") and ply or my_admin.FindPlayer(info)

    if IsValid(target) then
        -- Si ya es invisible, avisamos
        if target:GetNWBool("IsCloaked", false) then
            ply:ChatPrint(target:Nick() .. " ya es invisible.")
        else
            -- Aplicamos invisibilidad
            target:SetNoDraw(true)
            target:DrawShadow(false)
            -- Ocultamos también el arma que tenga en mano
            local weapon = target:GetActiveWeapon()
            if IsValid(weapon) then weapon:SetNoDraw(true) end
            
            target:SetNWBool("IsCloaked", true)
            my_admin.Notify(ply, " hizo invisible a ", target, false)
        end
    else
        ply:ChatPrint("No se encontró a \"" .. tostring(info) .. "\"")
    end
end)

-- COMANDO UNCLOAK (Hacer visible)
my_admin.RegisterCommand("uncloak", function(ply, args)
    
    local info = args[1]
    local target = (not info or info == "") and ply or my_admin.FindPlayer(info)

    if IsValid(target) then
        -- Si ya es visible, avisamos
        if not target:GetNWBool("IsCloaked", false) then
            ply:ChatPrint(target:Nick() .. " no es invisible.")
        else
            -- Quitamos invisibilidad
            target:SetNoDraw(false)
            target:DrawShadow(true)
            -- Mostramos el arma
            local weapon = target:GetActiveWeapon()
            if IsValid(weapon) then weapon:SetNoDraw(false) end
            
            target:SetNWBool("IsCloaked", false)
            my_admin.Notify(ply, " hizo visible a ", target, false)
        end
    else
        ply:ChatPrint("No se encontró a \"" .. tostring(info) .. "\"")
    end
end)

-- COMANDO GOD (Solo activar)
my_admin.RegisterCommand("god", function(ply, args)
    
    local info = args[1]
    local target = (not info or info == "") and ply or my_admin.FindPlayer(info)

    if IsValid(target) then
        -- Verificamos si ya está en modo dios
        if target:GetNWBool("InGodMode", false) then
            -- Mensaje en blanco avisando que ya lo tiene
            ply:ChatPrint(target:Nick() .. " ya está en modo dios.")
        else
            -- Lo activamos
            target:GodEnable()
            target:SetNWBool("InGodMode", true)
            my_admin.Notify(ply, " activó el God a ", target, false)
        end
    else
        ply:ChatPrint("No se encontró a \"" .. tostring(info) .. "\"")
    end
end)

-- COMANDO UNGOD (Solo desactivar)
my_admin.RegisterCommand("ungod", function(ply, args)
    
    local info = args[1]
    local target = (not info or info == "") and ply or my_admin.FindPlayer(info)

    if IsValid(target) then
        -- Verificamos si NO está en modo dios
        if not target:GetNWBool("InGodMode", false) then
            -- Mensaje en blanco avisando que no lo tiene
            ply:ChatPrint(target:Nick() .. " no está en modo dios.")
        else
            -- Lo desactivamos
            target:GodDisable()
            target:SetNWBool("InGodMode", false)
            my_admin.Notify(ply, " le desactivó el modo dios a ", target, false)
        end
    else
        ply:ChatPrint("No se encontró a \"" .. tostring(info) .. "\"")
    end
end)

-- COMANDO NOCLIP (Solo para uno mismo y silencioso)
my_admin.RegisterCommand("noclip", function(ply, args)
    
    -- Ignoramos args[1], siempre usamos 'ply'
    if ply:GetMoveType() != MOVETYPE_NOCLIP then
        ply:SetMoveType(MOVETYPE_NOCLIP)
    else
        ply:SetMoveType(MOVETYPE_WALK)
    end
    -- Sin Notificaciones
end)

-- COMANDO ADMIN (Modo Staff completo, solo para uno mismo y silencioso)
my_admin.RegisterCommand("admin", function(ply, args)

    -- 1. Noclip
    ply:SetMoveType(MOVETYPE_NOCLIP)

    -- 2. God
    ply:GodEnable()
    ply:SetNWBool("InGodMode", true)

    -- 3. Cloak
    ply:SetNoDraw(true)
    ply:DrawShadow(false)
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) then weapon:SetNoDraw(true) end
    ply:SetNWBool("IsCloaked", true)

    -- Sin Notificaciones
end)

-- COMANDO UNADMIN (Salir de modo Staff, solo para uno mismo y silencioso)
my_admin.RegisterCommand("unadmin", function(ply, args)

    -- 1. Quitar Noclip
    ply:SetMoveType(MOVETYPE_WALK)

    -- 2. Quitar God
    ply:GodDisable()
    ply:SetNWBool("InGodMode", false)

    -- 3. Quitar Cloak
    ply:SetNoDraw(false)
    ply:DrawShadow(true)
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) then weapon:SetNoDraw(false) end
    ply:SetNWBool("IsCloaked", false)

    -- Sin Notificaciones
end)

-- COMANDO STRIP (Quitar todas las armas)
my_admin.RegisterCommand("strip", function(ply, args)
    
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !strip <nombre/id>") end

    local target = my_admin.FindPlayer(info)

    if IsValid(target) then
        -- Quitamos todas las armas
        target:StripWeapons()
        
        -- Notificación: (Admin, Mensaje, Objetivo, Público)
        my_admin.Notify(ply, " desarmó a ", target, false)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end)

-- COMANDO KICK (Versión con notificación previa)
my_admin.RegisterCommand("kick", function(ply, args)
    
    local info = args[1]
    local reason = table.concat(args, " ", 2)
    if reason == "" then reason = "No especificado" end
    
    if not info then return ply:ChatPrint("Uso: !kick <nombre/id> <motivo>") end

    local target = my_admin.FindPlayer(info)

    if IsValid(target) then
        -- 1. PRIMERO NOTIFICAMOS (cuando el target aún existe)
        my_admin.Notify(ply, " expulsó a ", target, false)
        
        -- 2. DESPUÉS LO EXPULSAMOS (con un pequeño retraso de 0.1s para asegurar que el mensaje llegue)
        local targetToKick = target
        timer.Simple(0.1, function()
            if IsValid(targetToKick) then
                targetToKick:Kick("Expulsado por: " .. reason)
            end
        end)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end)

local timeMultiplier = {
    ["s"] = 1/60, -- segundos
    ["m"] = 1,    -- minutos
    ["h"] = 60,   -- horas
    ["d"] = 1440, -- días
    ["w"] = 10080,-- semanas
    ["mo"] = 43200, -- meses (30 días)
    ["y"] = 525600  -- años
}

local function ParseBanTime(timeStr)
    if timeStr == "0" then return 0 end -- Permanente
    
    local amount = tonumber(string.match(timeStr, "%d+"))
    local unit = string.match(timeStr, "%a+")
    
    if not amount then return 60 end -- Si no pone número, 1 hora por defecto
    if not unit or not timeMultiplier[unit] then return amount end -- Si no pone letra, asume minutos

    return math.ceil(amount * timeMultiplier[unit])
end

--BAN
my_admin.RegisterCommand("ban", function(ply, args)
    
    local info = args[1]
    local rawTime = args[2] or "0"
    local reason = table.concat(args, " ", 3)
    if not reason or reason == "" then reason = "Sin motivo especificado" end
    
    if not info then return ply:ChatPrint("Uso: !ban <nombre/id> <tiempo> <motivo>") end

    local target = my_admin.FindPlayer(info)

    if IsValid(target) then
        local seconds = IVO_SAM.ParseTime(rawTime)
        local sid64 = target:SteamID64()
        local targetNick = target:Nick() -- Guardamos el nombre antes de que se vaya

        -- Guardar ban en archivo
        local banData = {
            targetName = targetNick,
            adminName = IsValid(ply) and ply:Nick() or "Console",
            reason = reason,
            unbanTime = (seconds == 0) and 0 or (os.time() + seconds)
        }
        file.Write("ivosam/bans/" .. sid64 .. ".txt", util.TableToJSON(banData))

        -- Formato de tiempo
        local tiempoTexto = (seconds > 0) and (" por " .. IVO_SAM.FormatTime(seconds)) or " permanentemente"
        local msgFinal = tiempoTexto .. " (" .. reason .. ")"

        -- MANDAMOS EL NOMBRE EN EL NOTIFY para que no dependa de si el jugador sigue en el server
        -- Usamos el campo de mensaje para asegurar que llegue
        IVO_SAM.Notify(ply, " baneó a ", target, true, msgFinal)

        -- KICK con un poco más de retraso (0.5 segundos) para asegurar que el chat cargue
        timer.Simple(0.5, function()
            if IsValid(target) then
                target:Kick("\n[IVOSAM]\nBaneado" .. tiempoTexto .. "\nMotivo: " .. reason)
            end
        end)
    else
        ply:ChatPrint("No se encontró al jugador.")
    end
end)

--UNBAN
my_admin.RegisterCommand("unban", function(ply, args)

    local id = args[1] -- Espera un SteamID (STEAM_0:X:XXXXX) o SteamID64
    if not id then return ply:ChatPrint("Uso: !unban <SteamID>") end

    -- Convertimos a SteamID64 si nos pasan un SteamID normal (para encontrar el archivo)
    local sid64 = id
    if string.match(id, "STEAM_%d:%d:%d+") then
        sid64 = util.SteamIDTo64(id)
    end

    local path = "ivosam/bans/" .. sid64 .. ".txt"

    -- 1. Eliminamos el archivo de datos del ban
    if file.Exists(path, "DATA") then
        file.Delete(path)
        
        -- 2. Quitamos el ban del motor de GMod (Source)
        -- Usamos el ID original por si acaso
        RunConsoleCommand("removeid", id)
        RunConsoleCommand("writeid")

        my_admin.Notify(ply, " desbaneó a la ID ", nil, false, id)
    else
        -- Si no hay archivo, intentamos quitarlo de GMod por si acaso
        RunConsoleCommand("removeid", id)
        RunConsoleCommand("writeid")
        ply:ChatPrint("No se encontró registro de ban para esa ID, pero se ha ejecutado removeid por seguridad.")
    end
end)

-- COMANDO GIVE (Armas/Entidades)
my_admin.RegisterCommand("give", function(ply, args)
    
    local info = args[1]
    local class = args[2] -- La clase del arma (ej: weapon_smg1)
    
    if not info or not class then return ply:ChatPrint("Uso: !give <nombre/id> <clase_arma>") end

    local target = my_admin.FindPlayer(info)

    if IsValid(target) then
        target:Give(class)
        
        -- Notificación: (Admin, Mensaje, Objetivo, Público, Extra para resaltar el arma)
        my_admin.Notify(ply, " le dio " .. class .. " a ", target, false)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end)

-- COMANDO JAIL (Encarcelar)
my_admin.RegisterCommand("jail", function(ply, args)
    
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !jail <nombre/id>") end

    local target = my_admin.FindPlayer(info)

    if IsValid(target) then
        target:Lock() -- No se mueve
        target:StripWeapons() -- Sin armas
        target:SetMoveType(MOVETYPE_NONE)
        target:SetNWBool("IsJailed", true)
        
        my_admin.Notify(ply, " encarceló a ", target, false)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end)

-- COMANDO UNJAIL (Liberar)
my_admin.RegisterCommand("unjail", function(ply, args)
    
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !unjail <nombre/id>") end

    local target = my_admin.FindPlayer(info)

    if IsValid(target) then
        target:UnLock()
        target:SetMoveType(MOVETYPE_WALK)
        target:SetNWBool("IsJailed", false)
        target:Spawn() -- Lo respawnearnos para que tenga sus cosas de vuelta
        
        my_admin.Notify(ply, " liberó a ", target, false)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end)


my_admin.RegisterCommand("spectate", function(ply, args)
    
    -- Ahora que está declarada, esto funcionará perfecto
    net.Start("Ivosam_Freecam")
    net.Send(ply)
end)

hook.Add("CheckPassword", "Ivosam_CustomBanSystem", function(sid64)
    local path = "ivosam/bans/" .. sid64 .. ".txt"
    
    if file.Exists(path, "DATA") then
        local data = util.JSONToTable(file.Read(path, "DATA"))
        
        -- Verificar si el ban expiró
        if data.unbanTime != 0 then
            local remaining = data.unbanTime - os.time()
            
            if remaining <= 0 then
                file.Delete(path)
                return true 
            end
            
            -- Calculamos el tiempo detallado (Años, Meses, etc.)
            local timeLeft = FormatBanTime(remaining)
            
            return false, "\n[ SISTEMA DE ADMINISTRACIÓN ]\n" ..
                          "------------------------------------\n" ..
                          "ESTADO: BANEADO TEMPORALMENTE\n\n" ..
                          "Admin: " .. (data.adminName or "Consola") .. "\n" ..
                          "Motivo: " .. data.reason .. "\n\n" ..
                          "TIEMPO RESTANTE:\n" .. timeLeft .. "\n" ..
                          "------------------------------------"
        else
            -- Mensaje para ban Permanente
            return false, "\n[ SISTEMA DE ADMINISTRACIÓN ]\n" ..
                          "------------------------------------\n" ..
                          "ESTADO: BANEADO PERMANENTE\n\n" ..
                          "Admin: " .. (data.adminName or "Consola") .. "\n" ..
                          "Motivo: " .. data.reason .. "\n\n" ..
                          "No puedes volver a entrar al servidor.\n" ..
                          "------------------------------------"
        end
    end
end)

my_admin.RegisterCommand("setrank", function(ply, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local target = my_admin.FindPlayer(args[1])
    local rankName = string.lower(args[2] or "")
    local timeInput = args[3] or "0"

    if IsValid(target) and IVO_SAM.Ranks[rankName] then
        local seconds = IVO_SAM.ParseTime(timeInput)
        local expireAt = (seconds > 0) and (os.time() + seconds) or 0
        
        -- Guardar persistencia
        my_admin.SetUserRank(target, rankName, expireAt, IsValid(ply) and ply:Nick() or "Console")

        -- Definimos el tiempo: "por 1h" o "permanentemente"
        local tiempoTexto = (seconds > 0) and (" por " .. IVO_SAM.FormatTime(seconds)) or " permanentemente"

        -- CONSTRUCCIÓN DE LA FRASE (Sin letras sueltas)
        local msgAccion = " otorgó a " -- El sistema pondrá: ADMIN [otorgó a] TARGET
        local msgFinal = " el rango de " .. rankName:upper() .. tiempoTexto

        -- Llamamos a tu función Notify
        IVO_SAM.Notify(ply, msgAccion, target, true, msgFinal)
        
        print("[IVOSAM] " .. (IsValid(ply) and ply:Nick() or "Console") .. " -> " .. target:Nick() .. " | " .. rankName:upper() .. tiempoTexto)
    else
        ply:ChatPrint("[IVO] Uso: !setrank <nombre> <rango> [tiempo]")
    end
end)