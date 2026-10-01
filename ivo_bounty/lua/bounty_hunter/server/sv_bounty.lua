-- ============================================
--  BOUNTY HUNTER SYSTEM - Servidor
--  Archivo: lua/bounty_hunter/server/sv_bounty.lua
-- ============================================

BountySystem.Bounties = BountySystem.Bounties or {}
BountySystem.NextID    = BountySystem.NextID    or 1
BountySystem.Stats    = BountySystem.Stats    or {}

local cfg = BountySystem.Config

-- ──────────────────────────────────────────
--  PERSISTENCIA
-- ──────────────────────────────────────────
local DATA_FILE = "bounty_hunter/bounties.txt"
local STATS_FILE = "bounty_hunter/stats.txt"

local function SaveBounties()
    if not file.IsDir("bounty_hunter", "DATA") then
        file.CreateDir("bounty_hunter")
    end
    local t = {}
    for id, b in pairs(BountySystem.Bounties) do
        t[id] = b
    end
    file.Write(DATA_FILE, util.TableToJSON(t, true))
end
BountySystem.SaveBounties = SaveBounties

local function LoadBounties()
    if not file.Exists(DATA_FILE, "DATA") then return end
    local raw = file.Read(DATA_FILE, "DATA")
    if not raw or raw == "" then return end
    local decoded = util.JSONToTable(raw)
    if not decoded then return end
    for id, b in pairs(decoded) do
        local numID = tonumber(id)
        BountySystem.Bounties[numID] = b
        if numID >= BountySystem.NextID then
            BountySystem.NextID = numID + 1
        end
    end
    print("[BountySystem] " .. table.Count(BountySystem.Bounties) .. " recompensas cargadas.")
end

local function SaveStats()
    if not file.IsDir("bounty_hunter", "DATA") then file.CreateDir("bounty_hunter") end
    file.Write(STATS_FILE, util.TableToJSON(BountySystem.Stats, true))
end

local function LoadStats()
    if not file.Exists(STATS_FILE, "DATA") then return end
    local raw = file.Read(STATS_FILE, "DATA")
    if not raw or raw == "" then return end
    local decoded = util.JSONToTable(raw)
    if decoded then BountySystem.Stats = decoded end
    print("[BountySystem] Estadísticas de jugadores cargadas.")
end

-- ──────────────────────────────────────────
--  UTILIDADES
-- ──────────────────────────────────────────
local function GetActiveBounties()
    local list = {}
    for id, b in pairs(BountySystem.Bounties) do
        if b.status == BountySystem.STATUS.ACTIVE then
            -- Expiración
            local dur = b.duration or cfg.BountyDurationMin or 600
            if dur > 0 and (os.time() - b.placedAt) > dur then
                b.status = BountySystem.STATUS.EXPIRED
                SaveBounties()
            else
                list[id] = b
            end
        end
    end
    return list
end

local function GetPlayerBountyTotal(steamID)
    local total = 0
    for _, b in pairs(GetActiveBounties()) do
        if b.targetSteam == steamID then
            total = total + b.amount
        end
    end
    return total
end

local function SyncToAll()
    local active = GetActiveBounties()
    for _, b in pairs(active) do
        local dur = b.duration or cfg.BountyDurationMin or 600
        b.timeLeft = math.max(0, dur - (os.time() - b.placedAt))
    end
    net.Start("BountySystem_SyncBounties")
        net.WriteTable(active)
    net.Broadcast()
end
BountySystem.SyncToAll = SyncToAll

local function SyncToPlayer(ply)
    local active = GetActiveBounties()
    for _, b in pairs(active) do
        local dur = b.duration or cfg.BountyDurationMin or 600
        b.timeLeft = math.max(0, dur - (os.time() - b.placedAt))
    end
    net.Start("BountySystem_SyncBounties")
        net.WriteTable(active)
    net.Send(ply)
end

local function NotifyAll(msg, color)
    color = color or color_white
    net.Start("BountySystem_Notify")
        net.WriteString(msg)
        net.WriteUInt(color.r, 8)
        net.WriteUInt(color.g, 8)
        net.WriteUInt(color.b, 8)
    net.Broadcast()
end
BountySystem.NotifyAll = NotifyAll

local function NotifyPlayer(ply, msg, color)
    color = color or color_white
    net.Start("BountySystem_Notify")
        net.WriteString(msg)
        net.WriteUInt(color.r, 8)
        net.WriteUInt(color.g, 8)
        net.WriteUInt(color.b, 8)
    net.Send(ply)
end

local function GetPlayerStats(steamID, name)
    if not BountySystem.Stats[steamID] then
        BountySystem.Stats[steamID] = { level = 1, xp = 0, prestige = 0, kills = 0, name = name or "Desconocido" }
    elseif name and BountySystem.Stats[steamID].name ~= name then
        BountySystem.Stats[steamID].name = name
    end
    return BountySystem.Stats[steamID]
end

local function SyncStatsToPlayer(ply)
    local steamID = ply:IsBot() and ("BOT_" .. ply:EntIndex()) or ply:SteamID()
    local stats = GetPlayerStats(steamID, ply:Nick())
    net.Start("BountySystem_SyncStats")
        net.WriteTable(stats)
    net.Send(ply)
end

local function AddPlayerXP(ply, amount)
    if not IsValid(ply) then return end
    local steamID = ply:IsBot() and ("BOT_" .. ply:EntIndex()) or ply:SteamID()
    local stats = GetPlayerStats(steamID, ply:Nick())
    
    if stats.level >= cfg.MaxLevel then return end -- No gana XP si está a nivel máximo y necesita prestigio

    stats.xp = stats.xp + amount
    local xpNeeded = stats.level * 1000
    
    local leveledUp = false
    while stats.xp >= xpNeeded and stats.level < cfg.MaxLevel do
        stats.xp = stats.xp - xpNeeded
        stats.level = stats.level + 1
        xpNeeded = stats.level * 1000
        leveledUp = true
    end
    
    if leveledUp then
        NotifyPlayer(ply, "¡Has ascendido al Nivel " .. stats.level .. "!", cfg.Colors.Primary)
    end
    
    SaveStats()
    SyncStatsToPlayer(ply)
end

-- ──────────────────────────────────────────
--  COLOCAR RECOMPENSA
-- ──────────────────────────────────────────
net.Receive("BountySystem_PlaceBounty", function(_, sender)
    local targetSteam = net.ReadString()
    local amount      = net.ReadUInt(32)
    local reason      = net.ReadString()

    -- Validaciones básicas
    if not IsValid(sender) then return end

    if amount < cfg.MinBounty or amount > cfg.MaxBounty then
        NotifyPlayer(sender, "Cantidad inválida (" .. cfg.CurrencySymbol .. cfg.MinBounty .. " - " .. cfg.CurrencySymbol .. cfg.MaxBounty .. ")", cfg.Colors.Danger)
        return
    end

    -- Contar cuántas recompensas activas tiene el objetivo
    local targetBounties = 0
    for _, b in pairs(GetActiveBounties()) do
        if b.targetSteam == targetSteam then
            targetBounties = targetBounties + 1
            -- Cooldown mismo emisor-objetivo
            if b.placerSteam == sender:SteamID() then
                local elapsed = os.time() - b.placedAt
                if elapsed < cfg.PlaceCooldown then
                    local remaining = cfg.PlaceCooldown - elapsed
                    NotifyPlayer(sender, "Debes esperar " .. math.ceil(remaining) .. "s antes de añadir otra recompensa a este jugador.", cfg.Colors.Danger)
                    return
                end
            end
        end
    end

    if targetBounties >= cfg.MaxBountiesPerTarget then
        NotifyPlayer(sender, "Este jugador ya tiene el máximo de recompensas activas.", cfg.Colors.Danger)
        return
    end

    if sender.canAfford and not sender:canAfford(amount) then
        NotifyPlayer(sender, "No tienes suficiente dinero.", cfg.Colors.Danger)
        return
    end

    -- Restamos el dinero
    if sender.addMoney then
        sender:addMoney(-amount)
    end


    local id = BountySystem.NextID
    BountySystem.NextID = BountySystem.NextID + 1

    BountySystem.Bounties[id] = {
        id           = id,
        targetSteam  = targetSteam,
        targetName   = net.ReadString(), -- nombre al momento de colocar
        placerSteam  = sender:SteamID(),
        placerName   = sender:Nick(),
        amount       = amount,
        reason       = reason ~= "" and reason or "Sin motivo especificado",
        status       = BountySystem.STATUS.ACTIVE,
        placedAt     = os.time(),
        duration     = math.random(cfg.BountyDurationMin or 600, cfg.BountyDurationMax or 900),
        claimedBy    = nil,
        claimedAt    = nil,
    }

    SaveBounties()
    SyncToAll()

    local msg = "⚠ RECOMPENSA: " .. BountySystem.Bounties[id].targetName .. " tiene una recompensa de " .. cfg.CurrencySymbol .. amount .. " puesta por " .. sender:Nick()
    if cfg.NotifyAll then
        NotifyAll(msg, cfg.Colors.Accent)
    else
        NotifyPlayer(sender, "Recompensa colocada correctamente.", cfg.Colors.Success)
    end

    hook.Run("BountySystem_OnPlaced", id, BountySystem.Bounties[id])
end)

-- ──────────────────────────────────────────
--  ACEPTAR RECOMPENSA (CAZAR)
-- ──────────────────────────────────────────
net.Receive("BountySystem_AcceptBounty", function(_, sender)
    local bountyID = net.ReadUInt(16)
    if not IsValid(sender) then return end

    local bounty = BountySystem.Bounties[bountyID]
    if not bounty or bounty.status ~= BountySystem.STATUS.ACTIVE then
        NotifyPlayer(sender, "Este contrato ya no está disponible.", cfg.Colors.Danger)
        return
    end

    -- Verificar si el trabajo es Cazarrecompensas (si la config lo exige)
    if cfg.BountyHunterJobs and table.Count(cfg.BountyHunterJobs) > 0 then
        local jobCmd = RPExtraTeams and RPExtraTeams[sender:Team()] and RPExtraTeams[sender:Team()].command or ""
        if not cfg.BountyHunterJobs[jobCmd] then
            NotifyPlayer(sender, "Tu facción actual no te permite cazar recompensas.", cfg.Colors.Danger)
            return
        end
    end

    if bounty.targetSteam == sender:SteamID() then
        NotifyPlayer(sender, "No puedes aceptar un contrato sobre ti mismo.", cfg.Colors.Danger)
        return
    end

    if bounty.acceptedBy then
        NotifyPlayer(sender, "Alguien más ya ha reclamado este contrato.", cfg.Colors.Danger)
        return
    end

    bounty.acceptedBy = sender:SteamID()
    bounty.acceptedByName = sender:Nick()

    SaveBounties()
    SyncToAll()

    NotifyPlayer(sender, "Has aceptado el contrato. ¡Ve a cazar a " .. bounty.targetName .. "!", cfg.Colors.Success)

    -- Advertir al objetivo por chat SOLO cuando alguien lo reclama
    for _, p in ipairs(player.GetAll()) do
        local pSteam = p:IsBot() and ("BOT_" .. p:EntIndex()) or p:SteamID()
        if pSteam == bounty.targetSteam then
            p:ChatPrint("⚠ ¡CUIDADO! Un Cazarrecompensas ha aceptado tu contrato y te está cazando.")
            break
        end
    end
end)

-- ──────────────────────────────────────────
--  COBRAR RECOMPENSA
-- ──────────────────────────────────────────
net.Receive("BountySystem_ClaimBounty", function(_, sender)
    local bountyID   = net.ReadUInt(16)
    local targetSteam = net.ReadString()

    if not IsValid(sender) then return end

    local bounty = BountySystem.Bounties[bountyID]
    if not bounty or bounty.status ~= BountySystem.STATUS.ACTIVE then
        NotifyPlayer(sender, "Esta recompensa ya no está activa.", cfg.Colors.Danger)
        return
    end

    -- El cazarrecompensas no puede cobrarse a sí mismo
    if bounty.targetSteam == sender:SteamID() then
        NotifyPlayer(sender, "No puedes cobrar tu propia recompensa.", cfg.Colors.Danger)
        return
    end

    -- Verificar que el objetivo esté muerto / capturado (hook personalizable)
    -- Por defecto se asume que el servidor valida al matar al objetivo
    -- Ver hook BountySystem_CanClaim

    local canClaim, reason = hook.Run("BountySystem_CanClaim", sender, bounty)
    if canClaim == false then
        NotifyPlayer(sender, reason or "No puedes cobrar esta recompensa ahora.", cfg.Colors.Danger)
        return
    end

    -- Calcular pago con impuesto
    local payout = math.floor(bounty.amount * (1 - cfg.TaxRate))

    -- Aplicar bono de prestigio
    local senderStats = GetPlayerStats(sender:SteamID(), sender:Nick())
    local prestigeBonus = 1 + (senderStats.prestige * (cfg.PrestigeMultiplier or 0.20))
    payout = math.floor(payout * prestigeBonus)

    bounty.status    = BountySystem.STATUS.CLAIMED
    bounty.claimedBy = sender:SteamID()
    bounty.claimedByName = sender:Nick()
    bounty.claimedAt = os.time()

    -- Dar dinero (integración DarkRP / personalizable)
    hook.Run("BountySystem_OnClaimed", bountyID, bounty, sender, payout)

    -- Fallback: si es DarkRP dar dinero directamente
    if sender.addMoney then
        sender:addMoney(payout)
    end

    SaveBounties()
    SyncToAll()

    -- Progresión del cazador (XP variable)
    senderStats.kills = senderStats.kills + 1
    local xpPercent = math.Rand(cfg.XPPercentageMin or 0.05, cfg.XPPercentageMax or 0.15)
    local xpEarned = math.max(100, math.floor(bounty.amount * xpPercent))
    AddPlayerXP(sender, xpEarned)

    local msg = "💀 " .. sender:Nick() .. " cobró la recompensa de " .. bounty.targetName .. " y recibió " .. cfg.CurrencySymbol .. payout
    if cfg.NotifyAll then
        NotifyAll(msg, cfg.Colors.Primary)
    else
        NotifyPlayer(sender, "¡Recompensa cobrada! Recibiste " .. cfg.CurrencySymbol .. payout, cfg.Colors.Success)
    end
end)

-- ──────────────────────────────────────────
--  CANCELAR RECOMPENSA
-- ──────────────────────────────────────────
net.Receive("BountySystem_CancelBounty", function(_, sender)
    local bountyID = net.ReadUInt(16)

    if not IsValid(sender) then return end

    local bounty = BountySystem.Bounties[bountyID]
    if not bounty or bounty.status ~= BountySystem.STATUS.ACTIVE then
        NotifyPlayer(sender, "Esta recompensa no se puede cancelar.", cfg.Colors.Danger)
        return
    end

    local isAdmin = sender:IsAdmin() -- o usar cfg.AdminPermission
    local isOwner = bounty.placerSteam == sender:SteamID()

    if not isAdmin and not isOwner then
        NotifyPlayer(sender, "No tienes permiso para cancelar esta recompensa.", cfg.Colors.Danger)
        return
    end

    bounty.status = BountySystem.STATUS.CANCELLED

    -- Devolver dinero al emisor si fue cancelada por él mismo (opcional)
    if isOwner then
        local placer = player.GetBySteamID(bounty.placerSteam)
        if IsValid(placer) and placer.addMoney then
            placer:addMoney(bounty.amount)
            NotifyPlayer(placer, "Tu recompensa fue cancelada y se te devolvieron " .. cfg.CurrencySymbol .. bounty.amount, cfg.Colors.Success)
        end
    end

    SaveBounties()
    SyncToAll()
    NotifyPlayer(sender, "Recompensa #" .. bountyID .. " cancelada.", cfg.Colors.Success)
end)

-- ──────────────────────────────────────────
--  ABRIR MENÚ (petición del cliente)
-- ──────────────────────────────────────────
net.Receive("BountySystem_RequestList", function(_, sender)
    SyncToPlayer(sender)
end)

-- ──────────────────────────────────────────
--  PRESTIGIO
-- ──────────────────────────────────────────
net.Receive("BountySystem_Prestige", function(len, sender)
    if not IsValid(sender) then return end
    local steamID = sender:IsBot() and ("BOT_" .. sender:EntIndex()) or sender:SteamID()
    local stats = GetPlayerStats(steamID, sender:Nick())
    
    if stats.level >= cfg.MaxLevel then
        stats.level = 1
        stats.xp = 0
        stats.prestige = stats.prestige + 1
        SaveStats()
        SyncStatsToPlayer(sender)
        NotifyAll("¡" .. sender:Nick() .. " ha alcanzado el Prestigio " .. stats.prestige .. " en el Gremio de Cazarrecompensas!", cfg.Colors.Gold)
    end
end)

-- ──────────────────────────────────────────
--  ADMINISTRACIÓN DE ESTADÍSTICAS
-- ──────────────────────────────────────────
net.Receive("BountySystem_RequestAdminStats", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    net.Start("BountySystem_SyncAdminStats")
        net.WriteTable(BountySystem.Stats)
    net.Send(ply)
end)

net.Receive("BountySystem_AdminAction", function(len, sender)
    if not IsValid(sender) or not sender:IsSuperAdmin() then return end

    local action = net.ReadString()
    local targetSteam = net.ReadString()
    local amount = net.ReadInt(32)

    local targetPly = nil
    
    if action == "reset_all" then
        BountySystem.Stats = {}
        for _, p in ipairs(player.GetAll()) do
            SyncStatsToPlayer(p)
        end
        NotifyAll("El Administrador ha borrado TODAS las estadísticas del Gremio.", cfg.Colors.Danger)
    else
        targetPly = player.GetBySteamID(targetSteam)
        local targetName = IsValid(targetPly) and targetPly:Nick() or nil
        local stats = GetPlayerStats(targetSteam, targetName)

        if action == "add_xp" then
            if IsValid(targetPly) then AddPlayerXP(targetPly, amount) else stats.xp = stats.xp + amount end
        elseif action == "set_level" then
            stats.level = math.Clamp(amount, 1, cfg.MaxLevel or 50)
        elseif action == "set_prestige" then
            stats.prestige = math.max(0, amount)
        elseif action == "reset" then
            stats.level = 1; stats.xp = 0; stats.prestige = 0; stats.kills = 0
        end
        NotifyPlayer(sender, "Estadísticas actualizadas para el objetivo.", cfg.Colors.Success)
    end

    SaveStats()
    if IsValid(targetPly) then SyncStatsToPlayer(targetPly) end
    NotifyPlayer(sender, "Estadísticas actualizadas para el objetivo.", cfg.Colors.Success)
    
    -- Re-sincronizar el panel de administrador
    net.Start("BountySystem_SyncAdminStats")
        net.WriteTable(BountySystem.Stats)
    net.Send(sender)
end)

-- ──────────────────────────────────────────
--  CONTRATAR CAZADOR (INTERACCIÓN)
-- ──────────────────────────────────────────
net.Receive("BountySystem_HireHunter", function(len, sender)
    local target = net.ReadEntity()
    if not IsValid(target) or not target:IsPlayer() then return end
    if sender:GetPos():DistToSqr(target:GetPos()) > 40000 then return end
    
    local jobCmd = RPExtraTeams and RPExtraTeams[target:Team()] and RPExtraTeams[target:Team()].command or ""
    local myJobCmd = RPExtraTeams and RPExtraTeams[sender:Team()] and RPExtraTeams[sender:Team()].command or ""
    
    if cfg.BountyHunterJobs and cfg.BountyHunterJobs[jobCmd] and not cfg.BountyHunterJobs[myJobCmd] then
        local targetSteam = target:IsBot() and ("BOT_" .. target:EntIndex()) or target:SteamID()
        local stats = GetPlayerStats(targetSteam, target:Nick())
        net.Start("BountySystem_OpenHireMenu")
            net.WriteEntity(target)
            net.WriteTable(stats)
        net.Send(sender)
    end
end)

-- ──────────────────────────────────────────
--  HOOK: cuando un jugador muere → auto-claim
-- ──────────────────────────────────────────
hook.Add("PlayerDeath", "BountySystem_AutoClaim", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if victim == attacker then return end

    local victimSteam = victim:IsBot() and ("BOT_" .. victim:EntIndex()) or victim:SteamID()
    local attackerSteam = attacker:IsBot() and ("BOT_" .. attacker:EntIndex()) or attacker:SteamID()

    for id, b in pairs(GetActiveBounties()) do
        if b.targetSteam == victimSteam and b.status == BountySystem.STATUS.ACTIVE then
            -- Verificar si el contrato requiere ser aceptado y quién lo aceptó
            if not b.acceptedBy or b.acceptedBy ~= attackerSteam then continue end

            -- Progresión y Bonos del cazador
            local attackerStats = GetPlayerStats(attackerSteam, attacker:Nick())
            local prestigeBonus = 1 + (attackerStats.prestige * (cfg.PrestigeMultiplier or 0.20))

            -- Disparar cobro automático
            local payout = math.floor(b.amount * (1 - cfg.TaxRate))
            payout = math.floor(payout * prestigeBonus)

            b.status = BountySystem.STATUS.CLAIMED
            b.claimedBy = attacker:IsBot() and ("BOT_" .. attacker:EntIndex()) or attacker:SteamID()
            b.claimedByName = attacker:Nick()
            b.claimedAt = os.time()

            if attacker.addMoney then
                attacker:addMoney(payout)
            end
            
            attackerStats.kills = attackerStats.kills + 1
            local xpPercent = math.Rand(cfg.XPPercentageMin or 0.05, cfg.XPPercentageMax or 0.15)
            local xpEarned = math.max(100, math.floor(b.amount * xpPercent))
            AddPlayerXP(attacker, xpEarned)

            hook.Run("BountySystem_OnClaimed", id, b, attacker, payout)

            local msg = "💀 " .. attacker:Nick() .. " eliminó a " .. victim:Nick() .. " y cobró " .. cfg.CurrencySymbol .. payout .. " de recompensa!"
            NotifyAll(msg, cfg.Colors.Accent)
        end
    end

    SaveBounties()
    SyncToAll()
end)

-- ──────────────────────────────────────────
--  HOOK: DESCONEXIÓN DE JUGADORES
-- ──────────────────────────────────────────
hook.Add("PlayerDisconnected", "BountySystem_PlayerDisconnect", function(ply)
    local steamID = ply:IsBot() and ("BOT_" .. ply:EntIndex()) or ply:SteamID()
    local changed = false

    for id, b in pairs(BountySystem.Bounties) do
        if b.status == BountySystem.STATUS.ACTIVE then
            -- Si el objetivo se desconecta, cancelar la recompensa
            if b.targetSteam == steamID then
                b.status = BountySystem.STATUS.CANCELLED
                changed = true
                
                -- Devolver dinero al emisor si fue puesto por un jugador real
                if b.placerSteam ~= "SYSTEM" then
                    local placer = player.GetBySteamID(b.placerSteam)
                    if IsValid(placer) and placer.addMoney then
                        placer:addMoney(b.amount)
                        NotifyPlayer(placer, "Tu objetivo (".. b.targetName ..") se desconectó. Contrato cancelado y dinero devuelto.", cfg.Colors.Success)
                    end
                end
            -- Si el cazador que lo aceptó se desconecta, liberar el contrato
            elseif b.acceptedBy == steamID then
                b.acceptedBy = nil
                b.acceptedByName = nil
                changed = true
            end
        end
    end

    if changed then
        SaveBounties()
        SyncToAll()
    end
end)

-- ──────────────────────────────────────────
--  COMANDOS DE CONSOLA
-- ──────────────────────────────────────────
concommand.Add("bounty_list", function(ply)
    local active = GetActiveBounties()
    if table.Count(active) == 0 then
        print("[BountySystem] No hay recompensas activas.")
        return
    end
    for id, b in pairs(active) do
        print(string.format("[BountySystem] #%d | Objetivo: %s | Importe: %s%d | Puesto por: %s | Razón: %s",
            id, b.targetName, cfg.CurrencySymbol, b.amount, b.placerName, b.reason))
    end
end)

concommand.Add("bounty_cancel_all", function(ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then
        if IsValid(ply) then ply:ChatPrint("[BountySystem] Acceso denegado.") end
        return
    end
    for _, b in pairs(BountySystem.Bounties) do
        if b.status == BountySystem.STATUS.ACTIVE then
            b.status = BountySystem.STATUS.CANCELLED
        end
    end
    SaveBounties()
    SyncToAll()
    if IsValid(ply) then ply:ChatPrint("[BountySystem] Todas las recompensas canceladas.") end
end)

-- ──────────────────────────────────────────
--  INICIALIZACIÓN
-- ──────────────────────────────────────────
hook.Add("Initialize", "BountySystem_Load", function()
    LoadBounties()
    LoadStats()
    SyncToAll()
    print("[BountySystem] ✓ Sistema de Cazarrecompensas iniciado.")
end)

hook.Add("PlayerInitialSpawn", "BountySystem_SendOnJoin", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) then SyncToPlayer(ply) end
        if IsValid(ply) then SyncStatsToPlayer(ply) SaveStats() end
    end)
end)

-- ──────────────────────────────────────────
--  CARGAR SISTEMAS ADICIONALES
-- ──────────────────────────────────────────
include("bounty_hunter/server/sv_random_bounties.lua")
