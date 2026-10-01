-- ============================================================================
-- IVOSAM: COMANDOS FUN (IGNITE, SLAP & SCALE)
-- ============================================================================

-- 1. COMANDO IGNITE (!ignite <jugador> <segundos>)
my_admin.RegisterCommand("ignite", function(ply, args)
    
    local info = args[1]
    local tiempo = tonumber(args[2]) or 10 -- Si no pone tiempo, por defecto son 10 segundos
    if not info then return ply:ChatPrint("Uso: !ignite <nombre/id> <segundos>") end

    local target = my_admin.FindPlayer(info)
    if IsValid(target) then
        if not target:Alive() then return ply:ChatPrint(target:Nick() .. " está muerto.") end

        if SERVER then
            -- Prendemos fuego al jugador visualmente
            target:Ignite(tiempo)

            -- Creamos un temporizador que le hace 1 de daño por segundo
            local timerID = "IVO_IgniteDamage_" .. target:SteamID64()
            timer.Create(timerID, 1, tiempo, function()
                if IsValid(target) and target:Alive() then
                    target:TakeDamage(1, ply, ply)
                else
                    timer.Remove(timerID)
                end
            end)
            
            my_admin.Notify(ply, " quemó a ", target, false, " por " .. tiempo .. " segundos")
        end
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end, { usage = "!ignite <nombre/id> [segundos]", desc = "Prender fuego a un jugador", level = "admin" })

-- 2. COMANDO SLAP (!slap <jugador> [daño])
my_admin.RegisterCommand("slap", function(ply, args)

    local info = args[1]
    local dmg = tonumber(args[2]) or 0 -- Si no se especifica daño, es 0 por defecto
    if not info then return ply:ChatPrint("Uso: !slap <nombre/id> [daño]") end

    local target = my_admin.FindPlayer(info)
    if IsValid(target) then
        if not target:Alive() then return ply:ChatPrint(target:Nick() .. " está muerto.") end

        if SERVER then
            -- Si tiene daño asignado, se lo aplicamos
            if dmg > 0 then
                target:TakeDamage(dmg, ply, ply)
            end

            -- Empujón físico aleatorio para hacerlo saltar y desestabilizarlo
            local fH = IVO_SAM.Config.SLAP_FORCE_H
            local fuerzaAleatoria = Vector(math.random(-fH, fH), math.random(-fH, fH), math.random(IVO_SAM.Config.SLAP_FORCE_V_MIN, IVO_SAM.Config.SLAP_FORCE_V_MAX))
            target:SetVelocity(fuerzaAleatoria)

            -- Sonido clásico de cachetada/bofetada
            target:EmitSound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 75, 100)

            my_admin.Notify(ply, " le dio una bofetada a ", target, false, " (Daño: " .. dmg .. ")")
        end
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end, { usage = "!slap <nombre/id> [daño]", desc = "Golpear y lanzar a un jugador", level = "admin" })

-- 3. COMANDO SCALE (!scale <jugador> <0.1 a 2.0>)
my_admin.RegisterCommand("scale", function(ply, args)

    local info = args[1]
    local escala = tonumber(args[2])
    if not info or not escala then return ply:ChatPrint("Uso: !scale <nombre/id> <0.1-2.0>") end

    -- Limitamos la escala entre 0.1 (muy chiquito) y 2.0 (el doble de grande) para que no crashee el servidor
    escala = math.Clamp(escala, 0.1, 2.0)

    local target = my_admin.FindPlayer(info)
    if IsValid(target) then
        if SERVER then
            -- Cambia el tamaño del modelo físico del jugador
            target:SetModelScale(escala, 0.5) -- El 0.5 es el tiempo de transición en segundos

            -- Ajustamos la caja de colisiones para que coincida con el tamaño visual
            if escala == 1 then
                target:ResetHull() -- Restablece al tamaño humano por defecto (Escala 1)
            else
                -- Escalamos las cajas de colisiones parados y agachados proporcionalmente
                target:SetHull(Vector(-16, -16, 0) * escala, Vector(16, 16, 72) * escala)
                target:SetHullDuck(Vector(-16, -16, 0) * escala, Vector(16, 16, 36) * escala)
            end

            -- Corregimos la vista de los ojos para que no vea desde el estómago o el aire
            target:SetViewOffset(Vector(0, 0, 64) * escala)
            target:SetViewOffsetDucked(Vector(0, 0, 28) * escala)

            my_admin.Notify(ply, " cambió el tamaño de ", target, false, " a una escala de " .. escala)
        end
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end, { usage = "!scale <nombre/id> <0.1-2.0>", desc = "Cambiar el tamaño del modelo de un jugador", level = "admin" })