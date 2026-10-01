--[[
    ivo_bombs - Lógica de Desactivación (Server)
    Networking y validación del sistema de desactivación
]]

if not SERVER then return end

util.AddNetworkString("ivo_bombs_request_defuse")
util.AddNetworkString("ivo_bombs_start_defuse")
util.AddNetworkString("ivo_bombs_module_solved")
util.AddNetworkString("ivo_bombs_strike")
util.AddNetworkString("ivo_bombs_defuse_result")
util.AddNetworkString("ivo_bombs_close_panel")

IVO_BOMBS.ActiveDefusers = IVO_BOMBS.ActiveDefusers or {}

-- ============================================================
-- Iniciar desactivación
-- ============================================================
function IVO_BOMBS.StartDefuse(ply, bomb)
    if not IsValid(ply) or not IsValid(bomb) then return end
    if not bomb:GetArmed() or bomb:GetDefused() then return end

    -- Ya desactivando?
    if IVO_BOMBS.ActiveDefusers[ply] then
        ply:ChatPrint("[BOMBA] Ya estás desactivando una bomba.")
        return
    end

    -- Distancia
    if ply:GetPos():Distance(bomb:GetPos()) > 250 then
        ply:ChatPrint("[BOMBA] Estás muy lejos de la bomba.")
        return
    end

    -- SWEP requerido
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "weapon_ivo_defuser" then
        ply:ChatPrint("[BOMBA] Necesitas equipar el Kit de Desactivación.")
        return
    end

    -- Registrar
    IVO_BOMBS.ActiveDefusers[ply] = {
        bomb           = bomb,
        modulesSolved  = 0,
        strikes        = 0,
    }

    -- Enviar al cliente
    local diff = bomb:GetDifficulty()
    local seed = bomb:GetSeed()

    net.Start("ivo_bombs_start_defuse")
        net.WriteEntity(bomb)
        net.WriteUInt(diff, 4)
        net.WriteUInt(seed, 32)
    net.Send(ply)

    -- Anunciar
    local config = IVO_BOMBS.Difficulties[diff]
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply then
            p:ChatPrint("[BOMBA] " .. ply:Nick() .. " está intentando desactivar una bomba (" .. (config and config.name or "?") .. ").")
        end
    end
end

-- ============================================================
-- Recibir solicitud de desactivación (desde SWEP o Use)
-- ============================================================
net.Receive("ivo_bombs_request_defuse", function(len, ply)
    local bomb = net.ReadEntity()
    if not IsValid(bomb) or bomb:GetClass() ~= "ent_ivo_bomb" then return end
    IVO_BOMBS.StartDefuse(ply, bomb)
end)

-- ============================================================
-- Módulo resuelto
-- ============================================================
net.Receive("ivo_bombs_module_solved", function(len, ply)
    local data = IVO_BOMBS.ActiveDefusers[ply]
    if not data then return end

    local bomb = data.bomb
    if not IsValid(bomb) or not bomb:GetArmed() then
        IVO_BOMBS.ActiveDefusers[ply] = nil
        return
    end

    data.modulesSolved = data.modulesSolved + 1
    bomb:SetModulesSolved(data.modulesSolved)

    local config = IVO_BOMBS.Difficulties[bomb:GetDifficulty()]
    if not config then return end

    if data.modulesSolved >= config.modules then
        -- ¡Todas resueltas! Desactivar
        bomb:OnDefused(ply)
        IVO_BOMBS.ActiveDefusers[ply] = nil

        net.Start("ivo_bombs_defuse_result")
            net.WriteBool(true)
        net.Send(ply)
    end
end)

-- ============================================================
-- Strike
-- ============================================================
net.Receive("ivo_bombs_strike", function(len, ply)
    local data = IVO_BOMBS.ActiveDefusers[ply]
    if not data then return end

    local bomb = data.bomb
    if not IsValid(bomb) or not bomb:GetArmed() then
        IVO_BOMBS.ActiveDefusers[ply] = nil
        return
    end

    data.strikes = data.strikes + 1
    bomb:SetStrikeCount(data.strikes)

    local config = IVO_BOMBS.Difficulties[bomb:GetDifficulty()]
    if not config then return end

    if data.strikes >= config.maxStrikes then
        -- Demasiados errores → explota
        bomb:Explode()
        IVO_BOMBS.ActiveDefusers[ply] = nil

        net.Start("ivo_bombs_defuse_result")
            net.WriteBool(false)
        net.Send(ply)
    end
end)

-- ============================================================
-- Panel cerrado por el cliente
-- ============================================================
net.Receive("ivo_bombs_close_panel", function(len, ply)
    IVO_BOMBS.ActiveDefusers[ply] = nil
end)

-- ============================================================
-- Limpieza de desactivadores
-- ============================================================
hook.Add("PlayerDisconnected", "ivo_bombs_cleanup_defuser", function(ply)
    IVO_BOMBS.ActiveDefusers[ply] = nil
end)

-- Chequeo de distancia periódico (seguridad del servidor)
timer.Create("ivo_bombs_defuser_check", 1, 0, function()
    for ply, data in pairs(IVO_BOMBS.ActiveDefusers) do
        if not IsValid(ply) or not IsValid(data.bomb) or not data.bomb:GetArmed() then
            IVO_BOMBS.ActiveDefusers[ply] = nil
        elseif ply:GetPos():Distance(data.bomb:GetPos()) > 400 then
            IVO_BOMBS.ActiveDefusers[ply] = nil
            net.Start("ivo_bombs_defuse_result")
                net.WriteBool(false)
            net.Send(ply)
            ply:ChatPrint("[BOMBA] Te alejaste demasiado. Desactivación cancelada.")
        end
    end
end)
