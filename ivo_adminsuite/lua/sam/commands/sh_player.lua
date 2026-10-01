-- ============================================================================
-- IVOSAM: COMANDOS DE JUGADOR
-- hp, armor, slay, god, ungod, strip, give
-- ============================================================================
my_admin = my_admin or {}

my_admin.RegisterCommand("hp", function(ply, args)
    local info = args[1]
    local cantidad = tonumber(args[2]) or 100
    if not info then return ply:ChatPrint("Uso: !hp <nombre/id> <cantidad>") end

    local target = my_admin.FindPlayer(info)
    if IsValid(target) then
        if target ~= ply and not IVO_SAM.CheckTarget(ply, target, "modificar la vida de") then return end
        target:SetHealth(cantidad)
        my_admin.Notify(ply, " cambió la vida de ", target, false, " a " .. cantidad .. " HP")
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end, { usage = "!hp <nombre/id> <cantidad>", desc = "Establecer los puntos de vida de un jugador", level = "admin" })

my_admin.RegisterCommand("armor", function(ply, args)
    local info = args[1]
    local cantidad = tonumber(args[2]) or 100
    if not info then return ply:ChatPrint("Uso: !armor <nombre/id> <cantidad>") end

    local target = my_admin.FindPlayer(info)
    if IsValid(target) then
        if target ~= ply and not IVO_SAM.CheckTarget(ply, target, "modificar el escudo de") then return end
        target:SetArmor(cantidad)
        my_admin.Notify(ply, " cambió la armadura de ", target, false, " a " .. cantidad .. " AP")
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end, { usage = "!armor <nombre/id> <cantidad>", desc = "Establecer la armadura de un jugador", level = "admin" })

my_admin.RegisterCommand("slay", function(ply, args)
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !slay <nombre/id>") end

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
                return ply:ChatPrint("[IVOSAM] Inmunidad: No puedes aplicar slay a " .. target:Nick() .. " porque pertenece a un rango superior (" .. targetRank:upper() .. ").")
            end
        end
        -- ==========================================================

        if target ~= ply and not IVO_SAM.CheckTarget(ply, target, "slaear") then return end
        
        target:Kill()
        my_admin.Notify(ply, " asesinó a ", target, false)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end, { usage = "!slay <nombre/id>", desc = "Matar instantáneamente a un jugador", level = "admin" })

my_admin.RegisterCommand("god", function(ply, args)
    local info = args[1]
    local target = (not info or info == "") and ply or my_admin.FindPlayer(info)

    if IsValid(target) then
        if target ~= ply and not IVO_SAM.CheckTarget(ply, target, "activarle el God a") then return end
        if target:GetNWBool("InGodMode", false) then
            ply:ChatPrint(target:Nick() .. " ya está en modo dios.")
        else
            target:GodEnable()
            target:SetNWBool("InGodMode", true)
            my_admin.Notify(ply, " activó el God de ", target, false)
        end
    else
        ply:ChatPrint("No se encontró a \"" .. tostring(info) .. "\"")
    end
end, { usage = "!god [nombre]", desc = "Activar modo dios (invulnerabilidad)", level = "admin" })

my_admin.RegisterCommand("ungod", function(ply, args)
    local info = args[1]
    local target = (not info or info == "") and ply or my_admin.FindPlayer(info)

    if IsValid(target) then
        if target ~= ply and not IVO_SAM.CheckTarget(ply, target, "desactivarle el God a") then return end
        if not target:GetNWBool("InGodMode", false) then
            ply:ChatPrint(target:Nick() .. " no está en modo dios.")
        else
            target:GodDisable()
            target:SetNWBool("InGodMode", false)
            my_admin.Notify(ply, " desactivó el God de ", target, false)
        end
    else
        ply:ChatPrint("No se encontró a \"" .. tostring(info) .. "\"")
    end
end, { usage = "!ungod [nombre]", desc = "Desactivar modo dios", level = "admin" })

my_admin.RegisterCommand("strip", function(ply, args)
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !strip <nombre/id>") end

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
                return ply:ChatPrint("[IVOSAM] Inmunidad: No puedes desarmar a " .. target:Nick() .. " porque pertenece a un rango superior (" .. targetRank:upper() .. ").")
            end
        end
        -- ==========================================================

        if target ~= ply and not IVO_SAM.CheckTarget(ply, target, "desarmar") then return end
        
        target:StripWeapons()
        my_admin.Notify(ply, " desarmó a ", target, false)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end, { usage = "!strip <nombre/id>", desc = "Quitar todas las armas de un jugador", level = "admin" })

my_admin.RegisterCommand("give", function(ply, args)
    local info = args[1]
    local class = args[2]
    if not info or not class then return ply:ChatPrint("Uso: !give <nombre/id> <clase_arma>") end

    local target = my_admin.FindPlayer(info)
    if IsValid(target) then
        target:Give(class)
        my_admin.Notify(ply, " le dio " .. class .. " a ", target, false)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end, { usage = "!give <nombre/id> <clase_arma>", desc = "Dar un arma a un jugador por nombre de clase", level = "admin" })

my_admin.RegisterCommand("notarget", function(ply, args)
    local info = args[1]
    local target = (not info or info == "") and ply or my_admin.FindPlayer(info)

    if IsValid(target) then
        if target ~= ply and not IVO_SAM.CheckTarget(ply, target, "cambiar el notarget de") then return end
        
        if target:IsFlagSet(FL_NOTARGET) then
            target:SetNoTarget(false)
            if target == ply then
                ply:ChatPrint("Te has DESACTIVADO el notarget.")
            else
                my_admin.Notify(ply, " desactivó el notarget de ", target, false)
            end
        else
            target:SetNoTarget(true)
            if target == ply then
                ply:ChatPrint("Te has ACTIVADO el notarget.")
            else
                my_admin.Notify(ply, " activó el notarget de ", target, false)
            end
        end
    else
        ply:ChatPrint("No se encontró a \"" .. tostring(info) .. "\"")
    end
end, { usage = "!notarget [nombre]", desc = "Alternar notarget a ti o a otro jugador", level = "admin" })
