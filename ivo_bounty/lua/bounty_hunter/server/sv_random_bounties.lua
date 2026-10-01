-- Sistema de Contratos Aleatorios

local function InitRandomBounties()
    if not BountySystem.Config.EnableRandomBounties then return end

    timer.Create("BountySystem_RandomTimer", BountySystem.Config.RandomBountyInterval, 0, function()
        -- 1. Expirar contratos aleatorios activos que no fueron reclamados
        for id, b in pairs(BountySystem.Bounties) do
            if b.placerSteam == "SYSTEM" and b.status == BountySystem.STATUS.ACTIVE and not b.acceptedBy then
                b.status = BountySystem.STATUS.EXPIRED
            end
        end

        local validTargets = {}
        
        -- Filtrar jugadores válidos
        for _, ply in ipairs(player.GetAll()) do
            local jobCmd = ""
            if RPExtraTeams and RPExtraTeams[ply:Team()] then
                jobCmd = RPExtraTeams[ply:Team()].command
            end
            
            -- Verificar si el trabajo NO está restringido
            if not BountySystem.Config.RestrictedTargetJobs[jobCmd] then
                table.insert(validTargets, ply)
            end
        end
        
        -- Elegir múltiples objetivos únicos al azar
        local selectedTargets = {}
        local amountToPick = math.min(BountySystem.Config.ConcurrentRandomBounties or 1, #validTargets)
        
        for i = 1, amountToPick do
            local rnd = math.random(1, #validTargets)
            table.insert(selectedTargets, validTargets[rnd])
            table.remove(validTargets, rnd)
        end
        
        -- Crear los nuevos contratos
        if #selectedTargets > 0 then
            for _, target in ipairs(selectedTargets) do
                local amount = math.random(BountySystem.Config.RandomBountyMin, BountySystem.Config.RandomBountyMax)
                
                -- Redondear la cantidad a múltiplos de 100 (ej: 5312 -> 5300)
                amount = math.Round(amount / 100) * 100
                
                local reason = "Contrato de Eliminación Automatizado"
                
                -- ── REGISTRO REAL DE LA RECOMPENSA ──
                local id = BountySystem.NextID
                BountySystem.NextID = BountySystem.NextID + 1

                BountySystem.Bounties[id] = {
                    id           = id,
                    targetSteam  = target:IsBot() and ("BOT_" .. target:EntIndex()) or target:SteamID(),
                    targetName   = target:Nick(),
                    placerSteam  = "SYSTEM",
                    placerName   = "El Sistema",
                    amount       = amount,
                    reason       = reason,
                    status       = BountySystem.STATUS.ACTIVE,
                    placedAt     = os.time(),
                    duration     = math.random(BountySystem.Config.BountyDurationMin or 600, BountySystem.Config.BountyDurationMax or 900),
                }
            end

            if BountySystem.SaveBounties then BountySystem.SaveBounties() end
            if BountySystem.SyncToAll then BountySystem.SyncToAll() end
            
            local msg = "⚠ ALERTA GLOBAL: El Sistema ha renovado los contratos de eliminación automatizados."
            if BountySystem.NotifyAll then BountySystem.NotifyAll(msg, BountySystem.Config.Colors.Danger) end
        end
    end)
end

-- Iniciar el sistema de inmediato al cargar el archivo
InitRandomBounties()