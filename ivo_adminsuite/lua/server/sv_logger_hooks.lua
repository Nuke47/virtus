-- Función auxiliar para obtener Nombre, SteamID y Job del jugador
local function GetPlayerInfo(ply)
    if not IsValid(ply) then return "<color=255,255,255>Desconocido</color>" end
    if not ply:IsPlayer() then return "<color=255,255,255>" .. ply:GetClass() .. "</color>" end
    
    local jobName = team.GetName(ply:Team()) or "Desconocido"
    
    -- %s Amarillo para el Nick | %s y %s Rojo para SteamID y Job
    return string.format("<color=255,215,0>%s</color> <color=231,76,60>(%s) [%s]</color>", ply:Nick(), ply:SteamID(), jobName)
end

-- Función auxiliar para obtener el nombre y clase del arma (SWEP) o entidad
local function GetWeaponInfo(inflictor, attacker)
    local wepClass = "desconocido"
    local wepName = "desconocido"

    -- Caso 1: Daño por proyectil/entidad (ej. granada lanzada, C4, prop)
    if IsValid(inflictor) and inflictor ~= attacker and inflictor:GetClass() ~= "player" then
        wepClass = inflictor:GetClass()
        wepName = inflictor.PrintName or wepClass
        
    -- Caso 2: Daño directo del jugador (bala de un arma, golpe cuerpo a cuerpo)
    elseif IsValid(attacker) and attacker:IsPlayer() then
        local wep = attacker:GetActiveWeapon()
        if IsValid(wep) then
            wepClass = wep:GetClass()
            wepName = wep.PrintName or wepClass
        else
            wepClass = "físicas/manos"
            wepName = "físicas/manos"
        end
    end
    
    -- Formatear: Si tiene nombre bonito, mostramos ambos. Si no, solo la clase.
    if wepName == wepClass then
        return wepClass
    else
        return string.format("%s (%s)", wepName, wepClass)
    end
end

-- ==========================================
-- HOOKS DE REGISTRO
-- ==========================================

-- Interceptar comandos de chat
hook.Add("PlayerSay", "IvoLogs_Chat", function(ply, text)
    if string.lower(text) == "!logs" then
        IvoLogsSystem.SendMenu(ply)
        return "" 
    end
    
    IvoLogsSystem.AddLog("Chat", GetPlayerInfo(ply) .. ": " .. text)
end)

-- Conexiones de jugadores
hook.Add("PlayerInitialSpawn", "IvoLogs_Join", function(ply)
    IvoLogsSystem.AddLog("Conexión", GetPlayerInfo(ply) .. " entró al servidor.")
end)

hook.Add("PlayerDisconnected", "IvoLogs_Leave", function(ply)
    IvoLogsSystem.AddLog("Desconexión", GetPlayerInfo(ply) .. " salió.")
end)

-- Kills y Muertes
hook.Add("PlayerDeath", "IvoLogs_Death", function(victim, inflictor, attacker)
    -- Estructura de datos extendida con POSICIÓN y ÁNGULO
    local extra = {
        attacker = IsValid(attacker) and attacker:IsPlayer() and {
            name = attacker:Nick(), 
            sid = attacker:SteamID(), 
            sid64 = attacker:SteamID64(),
            model = attacker:GetModel(),
            pos = {x = attacker:GetPos().x, y = attacker:GetPos().y, z = attacker:GetPos().z},
            ang = {p = attacker:GetAngles().p, y = attacker:GetAngles().y, r = attacker:GetAngles().r}
        } or nil,
        victim = {
            name = victim:Nick(), 
            sid = victim:SteamID(), 
            sid64 = victim:SteamID64(),
            model = victim:GetModel(),
            pos = {x = victim:GetPos().x, y = victim:GetPos().y, z = victim:GetPos().z},
            ang = {p = victim:GetAngles().p, y = victim:GetAngles().y, r = victim:GetAngles().r}
        }
    }

    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        local weaponDetails = GetWeaponInfo(inflictor, attacker)
        
        extra.weapon = {
            name = (attacker:GetActiveWeapon():IsValid() and attacker:GetActiveWeapon().PrintName or "Físicas"), 
            class = attacker:GetActiveWeapon():IsValid() and attacker:GetActiveWeapon():GetClass() or "None", 
            model = attacker:GetActiveWeapon():IsValid() and attacker:GetActiveWeapon():GetModel() or ""
        }
        
        IvoLogsSystem.AddLog("Kill", GetPlayerInfo(attacker) .. " mató a " .. GetPlayerInfo(victim) .. " con " .. weaponDetails, extra)
        
    elseif attacker == victim then
        IvoLogsSystem.AddLog("Suicidio", GetPlayerInfo(victim) .. " se suicidó.", extra)
        
    elseif IsValid(attacker) and attacker:IsWorld() then
        IvoLogsSystem.AddLog("Muerte Mundo", GetPlayerInfo(victim) .. " murió por el entorno (caída, fuego, etc).", extra)
        
    elseif IsValid(attacker) then
        local entName = attacker:GetClass()
        IvoLogsSystem.AddLog("Muerte Entidad", GetPlayerInfo(victim) .. " fue asesinado por una entidad: " .. entName , extra)
        
    else
        IvoLogsSystem.AddLog("Muerte", GetPlayerInfo(victim) .. " murió por causas desconocidas.", extra)
    end
end)

-- Registro de Daño
hook.Add("EntityTakeDamage", "IvoLogs_Damage", function(target, dmginfo)
    if not target:IsPlayer() then return end

    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()
    local damage = math.Round(dmginfo:GetDamage())
    
    if damage <= 0 then return end

    -- Daño de jugador a jugador
    if IsValid(attacker) and attacker:IsPlayer() then
        local weaponDetails = GetWeaponInfo(inflictor, attacker)
        
        -- Construimos la tabla extra para la interfaz gráfica (UI)
        local extra = {
            attacker = { 
                name = attacker:Nick(), 
                sid = attacker:SteamID(), 
                sid64 = attacker:SteamID64() 
            },
            victim = { 
                name = target:Nick(), 
                sid = target:SteamID(), 
                sid64 = target:SteamID64() 
            }
        }
        
        -- Añadimos datos del arma a la caja extra si el atacante tiene una
        local wep = attacker:GetActiveWeapon()
        if IsValid(wep) then
            extra.weapon = { 
                name = wep.PrintName or wep:GetClass(), 
                class = wep:GetClass(), 
                model = wep:GetModel() or "models/weapons/w_crowbar.mdl"
            }
        end

        -- Registramos el log usando GetPlayerInfo para el texto visible
        IvoLogsSystem.AddLog("Daño", GetPlayerInfo(attacker) .. " le hizo " .. damage .. " de daño a " .. GetPlayerInfo(target) .. " con " .. weaponDetails, extra)
        
    -- Daño del mundo / caídas / entorno
    else
        local tipoDano = "Daño ambiental"
        
        if dmginfo:IsDamageType(DMG_FALL) then tipoDano = "Daño por caída"
        elseif dmginfo:IsDamageType(DMG_BURN) or dmginfo:IsDamageType(DMG_SLOWBURN) then tipoDano = "Daño por fuego/quemadura"
        elseif dmginfo:IsDamageType(DMG_DROWN) then tipoDano = "Daño por ahogamiento"
        elseif dmginfo:IsDamageType(DMG_BLAST) then tipoDano = "Daño por explosión"
        elseif dmginfo:IsDamageType(DMG_CRUSH) then tipoDano = "Daño por aplastamiento"
        elseif dmginfo:IsDamageType(DMG_SHOCK) then tipoDano = "Daño por electricidad"
        end

        -- Para el daño de mundo, solo enviamos la caja de la víctima
        local extra = {
            victim = { 
                name = target:Nick(), 
                sid = target:SteamID(), 
                sid64 = target:SteamID64() 
            }
        }

        -- Registramos usando GetPlayerInfo
        IvoLogsSystem.AddLog("Daño Mundo", GetPlayerInfo(target) .. " recibió " .. damage .. " de daño de tipo: " .. tipoDano, extra)
    end
end)

-- Spawneo de Entidades (Props)

hook.Add("PlayerSpawnedProp", "IvoLogs_SpawnProp", function(ply, model, ent)
    local extra = {
        attacker = { name = ply:Nick(), sid = ply:SteamID(), sid64 = ply:SteamID64() },
        weapon = { name = "Prop", class = "prop_physics", model = model }
    }
    IvoLogsSystem.AddLog("Props", GetPlayerInfo(ply) .. " creó el prop: " .. model, extra)
end)

-- Hook para Vehículos
hook.Add("PlayerSpawnedVehicle", "IvoLogs_SpawnVeh", function(ply, ent)
    local extra = {
        attacker = { name = ply:Nick(), sid = ply:SteamID(), sid64 = ply:SteamID64() },
        weapon = { name = "Vehículo", class = ent:GetClass(), model = ent:GetModel() }
    }
    IvoLogsSystem.AddLog("Spawn", GetPlayerInfo(ply) .. " creó un vehículo.", extra)
end)

-- Hook para Scripted Entities (SENTs)
hook.Add("PlayerSpawnedSENT", "IvoLogs_SpawnSENT", function(ply, ent)
    local sName = ent:GetClass()
    local extra = {
        attacker = { name = ply:Nick(), sid = ply:SteamID(), sid64 = ply:SteamID64() },
        weapon = { name = sName, class = sName, model = ent:GetModel() }
    }
    IvoLogsSystem.AddLog("SENTs", GetPlayerInfo(ply) .. " creó una entidad: " .. sName, extra)
end)

-- Hook para Eliminación
hook.Add("EntityRemoved", "IvoLogs_RemoveEntity", function(ent)
    if not ent.CPPIGetOwner then return end
    local ply = ent:CPPIGetOwner()
    
    if IsValid(ply) then
        local class = ent:GetClass()
        local model = ent:GetModel()
        
        local extra = {
            attacker = { name = ply:Nick(), sid = ply:SteamID(), sid64 = ply:SteamID64() },
            weapon = { name = class, class = class, model = model }
        }

        local action = " eliminó una entidad: " .. class
        if class == "prop_physics" then
            action = " eliminó el prop: " .. model
        elseif string.find(class, "vehicle") then
            action = " eliminó un vehículo."
        end

        IvoLogsSystem.AddLog("Remove", GetPlayerInfo(ply) .. action, extra)
    end
end)

hook.Add("WeaponEquip", "IvoLogs_WeaponEquip", function(wep, ply)
    -- 1. Validación de seguridad
    if not IsValid(wep) or not IsValid(ply) or not ply:IsPlayer() then return end
    
    -- 2. Extraemos los datos necesarios
    local wepName = isstring(wep.PrintName) and wep.PrintName or "Desconocido"
    local wepClass = wep:GetClass()
    
    -- 3. Formateamos el texto del arma: "DC15A (dc15_a)"
    local weaponDisplay = string.format("%s (%s)", wepName, wepClass)
    
    -- 4. Registro usando GetPlayerInfo para incluir Job, Nombre y SteamID
    IvoLogsSystem.AddLog("SWEPs", GetPlayerInfo(ply) .. " obtuvo el arma: " .. weaponDisplay, {
        attacker = { 
            name = ply:Nick(), 
            sid = ply:SteamID(), 
            sid64 = ply:SteamID64() 
        },
        weapon = { 
            name = wepName, 
            class = wepClass, 
            model = wep:GetModel() or "models/weapons/w_pistol.mdl" 
        }
    })
end)

-- ==========================================
-- 1. KICKEOS (Sistemas Base y Addons)
-- ==========================================

-- Hook nativo para cuando un jugador es expulsado
hook.Add("PlayerDisconnected", "IvoLogs_KickBase", function(ply)
    -- GMod por defecto no dice quién lo kickeó en este hook,
    -- pero podemos detectar si fue un kick por un admin a través de ULX/SAM.
    -- La mayoría de los kickeos específicos se guardan en los hooks de abajo.
end)

-- Si usas SAM Admin System
hook.Add("SAM.PlayerKicked", "IvoLogs_SAM_Kick", function(ply, admin, reason)
    local adminName = IsValid(admin) and admin:Nick() or "Consola"
    local adminSid = IsValid(admin) and admin:SteamID() or "CONSOLE"
    local adminSid64 = IsValid(admin) and admin:SteamID64() or "CONSOLE"

    local extra = {
        attacker = { name = adminName, sid = adminSid, sid64 = adminSid64 },
        victim = { name = ply:Nick(), sid = ply:SteamID(), sid64 = ply:SteamID64() }
    }

    IvoLogsSystem.AddLog("Kick", adminName .. " kickeó a " .. ply:Nick() .. " | Razón: " .. (reason or "Sin razón"), extra)
end)

-- Si usas ULX
hook.Add("ULXLoggedKick", "IvoLogs_ULX_Kick", function(admin, targetPly, reason)
    local adminName = IsValid(admin) and admin:Nick() or "Consola"
    local adminSid = IsValid(admin) and admin:SteamID() or "CONSOLE"
    local adminSid64 = IsValid(admin) and admin:SteamID64() or "CONSOLE"

    local extra = {
        attacker = { name = adminName, sid = adminSid, sid64 = adminSid64 },
        victim = { name = targetPly:Nick(), sid = targetPly:SteamID(), sid64 = targetPly:SteamID64() }
    }

    IvoLogsSystem.AddLog("Kick", adminName .. " kickeó a " .. targetPly:Nick() .. " | Razón: " .. (reason or "Sin razón"), extra)
end)


-- ==========================================
-- 2. BANEOS (Sistemas Base y Addons)
-- ==========================================

-- Hook para capturar baneos hechos por el sistema nativo de GMod o la consola
hook.Add("PlayerBanned", "IvoLogs_BaneoBase", function(steamID, time, reason, admin)
    local adminName = "Consola"
    local adminSid = "CONSOLE"
    local adminSid64 = "CONSOLE"

    if IsValid(admin) and admin:IsPlayer() then
        adminName = admin:Nick()
        adminSid = admin:SteamID()
        adminSid64 = admin:SteamID64()
    end

    -- Nota: Al estar baneado, no tenemos el objeto 'ply' de la víctima, solo su SteamID
    local extra = {
        attacker = { name = adminName, sid = adminSid, sid64 = adminSid64 },
        victim = { name = "Jugador Desconectado", sid = steamID, sid64 = util.SteamIDTo64(steamID) }
    }

    local tiempoTexto = (time == 0) and "Permanente" or (time .. " minutos")
    IvoLogsSystem.AddLog("Ban", adminName .. " baneó a " .. steamID .. " | Tiempo: " .. tiempoTexto .. " | Razón: " .. (reason or "Sin razón"), extra)
end)

-- Si usas SAM Admin System (Baneos)
hook.Add("SAM.PlayerBanned", "IvoLogs_SAM_Ban", function(steamid, duration, reason, admin, name)
    local adminName = IsValid(admin) and admin:Nick() or "Consola"
    local adminSid = IsValid(admin) and admin:SteamID() or "CONSOLE"
    local adminSid64 = IsValid(admin) and admin:SteamID64() or "CONSOLE"

    local extra = {
        attacker = { name = adminName, sid = adminSid, sid64 = adminSid64 },
        victim = { name = name or "Desconocido", sid = steamid, sid64 = util.SteamIDTo64(steamid) }
    }

    local tiempoTexto = (duration == 0) and "Permanente" or (duration .. " segundos")
    IvoLogsSystem.AddLog("Ban", adminName .. " baneó a " .. (name or steamid) .. " | Tiempo: " .. tiempoTexto .. " | Razón: " .. (reason or "Sin razón"), extra)
end)

-- Si usas ULX (Baneos)
hook.Add("ULXLoggedBan", "IvoLogs_ULX_Ban", function(admin, steamID, time, reason, targetPlyName)
    local adminName = IsValid(admin) and admin:Nick() or "Consola"
    local adminSid = IsValid(admin) and admin:SteamID() or "CONSOLE"
    local adminSid64 = IsValid(admin) and admin:SteamID64() or "CONSOLE"

    local extra = {
        attacker = { name = adminName, sid = adminSid, sid64 = adminSid64 },
        victim = { name = targetPlyName or "Desconocido", sid = steamID, sid64 = util.SteamIDTo64(steamID) }
    }

    IvoLogsSystem.AddLog("Ban", adminName .. " baneó a " .. (targetPlyName or steamID) .. " | Tiempo: " .. time .. " | Razón: " .. (reason or "Sin razón"), extra)
end)

hook.Add("IVO_SAM_PlayerBanned", "IvoLogs_CaptureBans", function(ply, target, seconds, reason, tiempoTexto, steamid, sid64)
    if not IsValid(target) then return end

    -- Obtenemos el texto formateado con colores de la consola o del administrador
    local adminInfo = IsValid(ply) and GetPlayerInfo(ply) or "<color=231,76,60>Console</color>"
    -- Obtenemos el texto formateado con colores de la víctima
    local targetInfo = GetPlayerInfo(target)

    local extra = {
        attacker = {
            name = IsValid(ply) and ply:Nick() or "Console",
            sid = IsValid(ply) and ply:SteamID() or "CONSOLE",
            sid64 = IsValid(ply) and ply:SteamID64() or "CONSOLE"
        },
        victim = {
            name = target:Nick(),
            sid = steamid,
            sid64 = sid64
        }
    }
    
    -- Construimos el mensaje usando el formato coloreado de GMod Markup
    local logMsg = adminInfo .. " baneó a " .. targetInfo .. tiempoTexto .. " — Motivo: " .. reason
    
    -- Lo enviamos a tus logs (Categoría "Kill" para el color rojo en el indicador izquierdo)
    IvoLogsSystem.AddLog("BAN", logMsg, extra)
end)

hook.Add("IVO_SAM_PlayerBanID", "IvoLogs_CaptureBanID", function(ply, onlinePlayer, targetNick, steamid, sid64, seconds, reason, tiempoTexto)
    -- Formatear al Administrador
    local adminInfo = IsValid(ply) and GetPlayerInfo(ply) or "<color=231,76,60>Console</color>"
    
    -- Formatear a la Víctima (Online u Offline)
    local targetInfo
    if IsValid(onlinePlayer) then
        targetInfo = GetPlayerInfo(onlinePlayer)
    else
        -- Formato de color manual emulando GetPlayerInfo si el usuario no está en el servidor
        targetInfo = "<color=241,196,15>" .. targetNick .. "</color> (<color=149,165,166>" .. steamid .. "</color>) [Offline]"
    end

    -- Metadata para tus contenedores gráficos inferiores
    local extra = {
        attacker = {
            name = IsValid(ply) and ply:Nick() or "Console",
            sid = IsValid(ply) and ply:SteamID() or "CONSOLE",
            sid64 = IsValid(ply) and ply:SteamID64() or "CONSOLE"
        },
        victim = {
            name = targetNick,
            sid = steamid,
            sid64 = sid64 or "Desconocido"
        }
    }

    local logMsg = adminInfo .. " baneó por ID a " .. targetInfo .. tiempoTexto .. " — Motivo: " .. reason
    
    -- Registramos el log bajo la categoría crítica "Kill" (Rojo)
    IvoLogsSystem.AddLog("BAN", logMsg, extra)
end)

hook.Add("IVO_SAM_PlayerUnbanned", "IvoLogs_CaptureUnbans", function(ply, targetName, steamid, sid64)
    -- Evitar que variables vacías rompan el guardado
    targetName = targetName or "Desconocido"
    steamid = steamid or "BOT_UNKNOWN"
    sid64 = sid64 or "BOT_UNKNOWN"

    -- Administrador
    local adminInfo
    local adminName = "Console"
    local adminSid = "CONSOLE"
    local adminSid64 = "CONSOLE"

    if IsValid(ply) and ply:IsPlayer() then
        adminInfo = GetPlayerInfo(ply)
        adminName = ply:Nick()
        adminSid = ply:SteamID()
        adminSid64 = ply:SteamID64()
    else
        adminInfo = "<color=231,76,60>Console</color>"
    end
    
    -- Detectar si es Bot
    local esBot = string.StartWith(string.upper(sid64), "BOT_") or string.StartWith(string.upper(steamid), "BOT_")
    local targetInfo
    
    if esBot then
        targetInfo = "<color=52, 152, 219>" .. targetName .. "</color> (<color=149,165,166>" .. steamid .. "</color>) [BOT]"
    else
        targetInfo = "<color=46, 204, 113>" .. targetName .. "</color> (<color=149,165,166>" .. steamid .. "</color>)"
    end

    local extra = {
        attacker = {
            name = adminName,
            sid = adminSid,
            sid64 = adminSid64
        },
        victim = {
            name = targetName,
            sid = steamid,
            sid64 = sid64
        }
    }

    local logMsg = adminInfo .. " desbaneó al jugador " .. targetInfo
    
    -- Agregamos el log. Nota: Si la pestaña "Chat" no te actualiza, 
    -- prueba temporalmente cambiando "Chat" por "Kill" para ver si aparece en la pestaña roja de inmediato.
    IvoLogsSystem.AddLog("UNBAN", logMsg, extra)
end)

hook.Add("IVO_SAM_PlayerKicked", "IvoLogs_CaptureKicks", function(ply, target, reason)
    if not IsValid(target) then return end

    -- Obtenemos la información formateada en colores para el admin y la víctima
    local adminInfo = IsValid(ply) and GetPlayerInfo(ply) or "<color=231,76,60>Console</color>"
    local targetInfo = GetPlayerInfo(target)

    -- Almacenamos la metadata para los contenedores gráficos del panel inferior
    local extra = {
        attacker = {
            name = IsValid(ply) and ply:Nick() or "Console",
            sid = IsValid(ply) and ply:SteamID() or "CONSOLE",
            sid64 = IsValid(ply) and ply:SteamID64() or "CONSOLE"
        },
        victim = {
            name = target:Nick(),
            sid = target:IsBot() and ("BOT_" .. target:UserID()) or target:SteamID(),
            sid64 = target:IsBot() and ("BOT_" .. target:UserID()) or target:SteamID64()
        }
    }
    
    -- Construimos el mensaje final con markup de color
    local logMsg = adminInfo .. " expulsó a " .. targetInfo .. " — Motivo: " .. reason
    
    -- Registramos el log bajo la categoría "Remove" (que se pinta color naranja/marrón)
    IvoLogsSystem.AddLog("KICK", logMsg, extra)
end)


--- DARKRP LOGS

hook.Add("OnPlayerChangedTeam", "IvoLogs_DarkRP_Jobs", function(ply, oldTeam, newTeam)
    if not IsValid(ply) then return end

    local plyInfo = GetPlayerInfo(ply)
    local oldJob = team.GetName(oldTeam) or "Desconocido"
    local newJob = team.GetName(newTeam) or "Desconocido"

    local extra = {
        attacker = {
            name = ply:Nick(),
            sid = ply:SteamID(),
            sid64 = ply:SteamID64()
        }
    }

    local logMsg = plyInfo .. " cambió de trabajo: <color=231,76,60>" .. oldJob .. "</color> ➔ <color=46,204,113>" .. newJob .. "</color>"
    
    -- Categoría personalizada
    IvoLogsSystem.AddLog("JOB", logMsg, extra)
end)

hook.Add("playerGiveMoney", "IvoLogs_DarkRP_MoneyTransfer", function(attacker, victim, amount)
    if not IsValid(attacker) or not IsValid(victim) then return end

    local attInfo = GetPlayerInfo(attacker)
    local vicInfo = GetPlayerInfo(victim)

    local extra = {
        attacker = { name = attacker:Nick(), sid = attacker:SteamID(), sid64 = attacker:SteamID64() },
        victim = { name = victim:Nick(), sid = victim:SteamID(), sid64 = victim:SteamID64() }
    }

    local logMsg = attInfo .. " le dio <color=46,204,113>$" .. string.Comma(amount) .. "</color> a " .. vicInfo
    
    -- Categoría personalizada
    IvoLogsSystem.AddLog("DINERO", logMsg, extra)
end)

-- Cuando un policía arresta a alguien
hook.Add("playerArrested", "IvoLogs_DarkRP_Arrest", function(victim, time, attacker)
    if not IsValid(victim) then return end

    local victimInfo = GetPlayerInfo(victim)
    local attInfo = IsValid(attacker) and GetPlayerInfo(attacker) or "<color=231,76,60>Consola/Sistema</color>"

    local extra = {
        attacker = IsValid(attacker) and { name = attacker:Nick(), sid = attacker:SteamID(), sid64 = attacker:SteamID64() } or nil,
        victim = { name = victim:Nick(), sid = victim:SteamID(), sid64 = victim:SteamID64() }
    }

    local logMsg = attInfo .. " arrestó a " .. victimInfo .. " por " .. math.floor(time) .. " segundos."
    
    -- Categoría personalizada
    IvoLogsSystem.AddLog("ARRESTO", logMsg, extra)
end)

-- Cuando un jugador es liberado de prisión
hook.Add("playerUnArrested", "IvoLogs_DarkRP_Unarrest", function(victim, attacker)
    if not IsValid(victim) then return end

    local victimInfo = GetPlayerInfo(victim)
    local attInfo = IsValid(attacker) and GetPlayerInfo(attacker) or "<color=46,204,113>Tiempo Cumplido</color>"

    local extra = {
        attacker = IsValid(attacker) and { name = attacker:Nick(), sid = attacker:SteamID(), sid64 = attacker:SteamID64() } or nil,
        victim = { name = victim:Nick(), sid = victim:SteamID(), sid64 = victim:SteamID64() }
    }

    local logMsg = victimInfo .. " fue liberado por: " .. attInfo
    
    -- Categoría personalizada
    IvoLogsSystem.AddLog("ARRESTO", logMsg, extra)
end)

-- Compra de entidades individuales (Impresoras, drogas, etc.)
hook.Add("playerBoughtCustomEntity", "IvoLogs_DarkRP_BuyEntity", function(ply, entTable, ent, price)
    if not IsValid(ply) then return end

    local plyInfo = GetPlayerInfo(ply)
    local entName = entTable.name or "Entidad Desconocida"

    local extra = {
        attacker = { name = ply:Nick(), sid = ply:SteamID(), sid64 = ply:SteamID64() }
    }

    local logMsg = plyInfo .. " compró la entidad: <color=241,196,15>" .. entName .. "</color> por <color=46,204,113>$" .. price .. "</color>"
    
    -- Categoría personalizada
    IvoLogsSystem.AddLog("COMPRA", logMsg, extra)
end)

-- Compra de cargamentos de armas (Shipments)
hook.Add("playerBoughtShipment", "IvoLogs_DarkRP_BuyShipment", function(ply, shipTable, ent, price)
    if not IsValid(ply) then return end

    local plyInfo = GetPlayerInfo(ply)
    local shipName = shipTable.name or "Cargamento Desconocido"

    local extra = {
        attacker = { name = ply:Nick(), sid = ply:SteamID(), sid64 = ply:SteamID64() }
    }

    local logMsg = plyInfo .. " compró un cargamento de: <color=241,196,15>" .. shipName .. "</color> por <color=46,204,113>$" .. price .. "</color>"
    
    -- Categoría personalizada
    IvoLogsSystem.AddLog("COMPRA", logMsg, extra)
end)

hook.Add("playerWarranted", "IvoLogs_DarkRP_Warrants", function(victim, attacker, reason)
    if not IsValid(victim) then return end

    local vicInfo = GetPlayerInfo(victim)
    local attInfo = IsValid(attacker) and GetPlayerInfo(attacker) or "<color=231,76,60>Consola</color>"

    local extra = {
        attacker = IsValid(attacker) and { name = attacker:Nick(), sid = attacker:SteamID(), sid64 = attacker:SteamID64() } or nil,
        victim = { name = victim:Nick(), sid = victim:SteamID(), sid64 = victim:SteamID64() }
    }

    local logMsg = attInfo .. " emitió una orden de registro (Warrant) contra " .. vicInfo .. " — Motivo: " .. reason
    
    -- Categoría personalizada
    IvoLogsSystem.AddLog("ALLANAMIENTO", logMsg, extra)
end)

hook.Add("playerDisconnectedFromArrest", "IvoLogs_DarkRP_LTA", function(ply)
    if not IsValid(ply) then return end

    local plyInfo = GetPlayerInfo(ply)

    local extra = {
        victim = { name = ply:Nick(), sid = ply:SteamID(), sid64 = ply:SteamID64() }
    }

    local logMsg = "[LTA] " .. plyInfo .. " se desconectó estando bajo arresto en el servidor."
    
    -- Categoría personalizada orientada a infracciones
    IvoLogsSystem.AddLog("SANCION", logMsg, extra)
end)