-- ============================================================================
-- IVOSAM: COMANDOS DE MOVIMIENTO Y ESPECTADO
-- goto, bring, return, noclip, admin, unadmin, spectate + limpieza FSpectate
-- ============================================================================
my_admin = my_admin or {}

my_admin.RegisterCommand("goto", function(ply, args)
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !goto <nombre/steamid>") end

    local target = my_admin.FindPlayer(info)
    if IsValid(target) then
        if target == ply then return end
        
        -- LÓGICA DE REVIVIR: Si el administrador que se mueve está muerto, lo revivimos
        if not ply:Alive() then
            ply:Spawn()
        end

        my_admin.LastPositions[ply:SteamID64()] = ply:GetPos()
        ply:SetPos(target:GetPos() + target:GetForward() * -60 + Vector(0, 0, 10))
        ply:SetLocalVelocity(Vector(0, 0, 0))
        my_admin.Notify(ply, " fue hacia ", target, false)
    else
        ply:ChatPrint("No se encontró a \"" .. info .. "\"")
    end
end, { usage = "!goto <nombre/steamid>", desc = "Teletransportarte a un jugador", level = "admin" })

my_admin.RegisterCommand("bring", function(ply, args)
    local info = args[1]
    if not info then return ply:ChatPrint("Uso: !bring <nombre>") end

    my_admin.LastPositions = my_admin.LastPositions or {}
    local targets = my_admin.FindPlayers(info)

    if #targets > 0 then
        local namesTable = {}
        local count = #targets
        local radius = IVO_SAM.Config.BRING_RADIUS_BASE + (count * IVO_SAM.Config.BRING_RADIUS_STEP)

        for i, target in ipairs(targets) do
            if not IsValid(target) or target == ply then continue end
            
            -- ==========================================================
            -- TU SISTEMA DE SEGURIDAD JERÁRQUICA IVO_SAM (ONLINE)
            -- ==========================================================
            local plyRank = isfunction(ply.GetRank) and ply:GetRank():lower() or "user"
            local plyPower = IVO_SAM.Ranks[plyRank] and IVO_SAM.Ranks[plyRank].power or 0

            local targetRank = isfunction(target.GetRank) and target:GetRank():lower() or "user"
            local targetPower = IVO_SAM.Ranks[targetRank] and IVO_SAM.Ranks[targetRank].power or 0

            if plyPower < targetPower and targetPower > 0 then
                ply:ChatPrint("[IVOSAM] Inmunidad: No puedes traer a " .. target:Nick() .. " porque pertenece a un rango superior (" .. targetRank:upper() .. ").")
                continue -- Salta a este jugador inmune y continúa procesando al resto del bucle
            end
            -- ==========================================================
            
            if not IVO_SAM.CheckTarget(ply, target, "traer") then continue end
            
            -- LÓGICA DE REVIVIR: Si el jugador está muerto, lo revivimos
            if not target:Alive() then
                target:Spawn()
            end

            my_admin.LastPositions[target:SteamID64()] = target:GetPos()
            table.insert(namesTable, target:Nick())
            local angle = math.rad((i / count) * 360)
            local x = math.cos(angle) * radius
            local y = math.sin(angle) * radius
            target:SetPos(ply:GetPos() + Vector(x, y, 10))
            target:SetLocalVelocity(Vector(0, 0, 0))
            target:SetEyeAngles((ply:GetPos() - target:GetPos()):Angle())
        end

        -- Solo enviamos la notificación global si realmente se logró traer a alguien
        if #namesTable > 0 then
            if #namesTable == 1 then
                local targetEntity = my_admin.FindPlayer(namesTable[1])
                my_admin.Notify(ply, " trajo a ", targetEntity, true, "")
            else
                my_admin.Notify(ply, " trajo a ", nil, true, table.concat(namesTable, ","))
            end
        end
    else
        ply:ChatPrint("No se encontró a nadie.")
    end
end, { usage = "!bring <nombre/*>", desc = "Traer uno o varios jugadores a tu posición", level = "admin" })

my_admin.RegisterCommand("return", function(ply, args)
    local info = args[1]
    local target = (!info or info == "") and ply or my_admin.FindPlayer(info)

    if IsValid(target) then
        if target ~= ply and not IVO_SAM.CheckTarget(ply, target, "devolver") then return end
        local oldPos = my_admin.LastPositions[target:SteamID64()]
        if oldPos then
            target:SetPos(oldPos)
            my_admin.LastPositions[target:SteamID64()] = nil
            my_admin.Notify(ply, " devolvió a ", target, false)
        else
            ply:ChatPrint("No hay posición guardada para " .. target:Nick())
        end
    else
        ply:ChatPrint("No se encontró a \"" .. tostring(info) .. "\"")
    end
end, { usage = "!return [nombre]", desc = "Devolver a un jugador a su posición anterior", level = "admin" })

my_admin.RegisterCommand("noclip", function(ply, args)
    if ply:GetMoveType() != MOVETYPE_NOCLIP then
        ply:SetMoveType(MOVETYPE_NOCLIP)
    else
        ply:SetMoveType(MOVETYPE_WALK)
    end
end, { usage = "!noclip", desc = "Activar/desactivar noclip propio", level = "admin" })

my_admin.RegisterCommand("admin", function(ply, args)
    ply:SetMoveType(MOVETYPE_NOCLIP)
    ply:GodEnable()
    ply:SetNWBool("InGodMode", true)
    ply:SetNoDraw(true)
    ply:DrawShadow(false)
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) then weapon:SetNoDraw(true) end
    ply:SetNWBool("IsCloaked", true)
end, { usage = "!admin", desc = "Entrar en modo admin (noclip + god + invisible)", level = "admin" })

my_admin.RegisterCommand("unadmin", function(ply, args)
    ply:SetMoveType(MOVETYPE_WALK)
    ply:GodDisable()
    ply:SetNWBool("InGodMode", false)
    ply:SetNoDraw(false)
    ply:DrawShadow(true)
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) then weapon:SetNoDraw(false) end
    ply:SetNWBool("IsCloaked", false)
end, { usage = "!unadmin", desc = "Salir del modo admin (walk + sin god + visible)", level = "admin" })

my_admin.RegisterCommand("spectate", function(ply, args)
    if not IsValid(ply) then return end
    if SERVER then
        if ply.FSpectating then
            ply.FSpectating = false
            ply:UnSpectate()
            ply:Spawn()
        end
        net.Start("Ivosam_Freecam")
        net.Send(ply)
        my_admin.Notify(ply, " activó el modo espectador con cámara libre.", nil, false)
    end
end, { usage = "!spectate", desc = "Activar cámara libre de espectador (freecam)", level = "admin" })

-- Limpieza de FSpectate en servidor
if SERVER then
    hook.Add("Initialize", "IVO_SAM_Eliminar_FSpectate_SV", function()
        timer.Simple(1, function()
            hook.Remove("PlayerSay", "FSpectate")
            concommand.Remove("FSpectate")
            concommand.Remove("fspectate")
            concommand.Remove("_FSpectatePosUpdate")
            concommand.Remove("fadmin_spectate")
            if DarkRP and DarkRP.removeChatCommand then
                DarkRP.removeChatCommand("spectate")
            end
        end)
    end)

    hook.Add("PlayerSay", "!!!IVO_SAM_FuerzaBrutaSpectate", function(ply, text, teamOnly)
        if not IsValid(ply) then return end
        local limpio = string.lower(string.Trim(text))
        if limpio == "!spectate" or limpio == "/spectate" then
            if not IVO_SAM.HasPermission(ply, "spectate") then return "" end
            if ply.FSpectating then
                ply.FSpectating = false
                ply:UnSpectate()
                ply:Spawn()
            end
            net.Start("Ivosam_Freecam")
            net.Send(ply)
            if my_admin and my_admin.Notify then
                my_admin.Notify(ply, " activó el modo espectador con cámara libre.", nil, false)
            end
            return ""
        end
    end, -100)
end

-- Limpieza de FSpectate en cliente
if CLIENT then
    hook.Add("Initialize", "IVO_SAM_Eliminar_FSpectate_CL", function()
        timer.Simple(1, function()
            concommand.Remove("FSpectate")
            concommand.Remove("fspectate")
            hook.Remove("CalcView", "FSpectate")
            hook.Remove("PlayerBindPress", "FSpectate")
            hook.Remove("ShouldDrawLocalPlayer", "FSpectate")
            hook.Remove("Think", "FSpectate")
            hook.Remove("HUDPaint", "FSpectate")
            hook.Remove("FAdmin_ShowFAdminMenu", "FSpectate")
            hook.Remove("RenderScreenspaceEffects", "FSpectate")
        end)
    end)
end
