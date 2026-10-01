if SERVER then return end

local stunnedRagdolls = {}
local isLocalStunned = false
local stunEnd = 0

net.Receive("VirtusStunState", function()
    local ragdoll = net.ReadEntity()
    local duration = net.ReadFloat()
    
    if IsValid(ragdoll) then
        table.insert(stunnedRagdolls, {ent = ragdoll, start = CurTime(), dur = duration})
    end
    
    -- Si estamos spectateando este ragdoll, estamos estuneados nosotros
    local ply = LocalPlayer()
    if IsValid(ply) and IsValid(ragdoll) then
        timer.Simple(0.1, function()
            if IsValid(ply) and IsValid(ragdoll) and ply:GetObserverTarget() == ragdoll then
                isLocalStunned = true
                stunEnd = CurTime() + duration
            end
        end)
    end
end)

-- Chequeo constante para salir del estado de stun
hook.Add("Think", "VirtusStun_CheckState", function()
    if isLocalStunned then
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        
        -- Si ya pasó el tiempo O si el jugador ya no está spectateando, salir del stun
        if CurTime() > stunEnd or ply:GetObserverMode() == OBS_MODE_NONE then
            isLocalStunned = false
        end
    end
end)

-- Ocultar viewmodel (arma) cuando estamos estuneados
hook.Add("PreDrawViewModel", "VirtusStun_HideVM", function(vm, ply, wep)
    if isLocalStunned then return true end
end)

-- Ocultar manos cuando estamos estuneados
hook.Add("PreDrawPlayerHands", "VirtusStun_HideHands", function(hands, vm, ply, wep)
    if isLocalStunned then return true end
end)

-- Ocultar el HUD del arma (crosshair, ammo TFA, etc) cuando estuneado
hook.Add("HUDShouldDraw", "VirtusStun_HideHUD", function(name)
    if isLocalStunned then
        if name == "CHudWeaponSelection" or name == "CHudCrosshair" then
            return false
        end
    end
end)

-- Halos para ragdolls estuneados (original)
hook.Add("PreDrawHalos", "VirtusStunHalo", function()
    local toDraw = {}
    local maxPulseAlpha = 0
    
    for i = #stunnedRagdolls, 1, -1 do
        local data = stunnedRagdolls[i]
        if not IsValid(data.ent) then
            table.remove(stunnedRagdolls, i)
            continue
        end
        
        local elapsed = CurTime() - data.start
        local remaining = data.dur - elapsed
        
        if elapsed < 0 or remaining <= 0 then
            table.remove(stunnedRagdolls, i)
            continue
        end
        
        -- Progresivo: aparece rápido, parpadea suavemente, y se desvanece antes de terminar.
        local fraction = 1
        if elapsed < 0.5 then
            fraction = elapsed / 0.5
        elseif remaining < 1.0 then
            fraction = remaining / 1.0
        end
        
        local pulse = fraction * 200 + math.sin(CurTime() * 8) * 55 * fraction
        pulse = math.Clamp(pulse, 0, 255)
        
        if pulse > maxPulseAlpha then
            maxPulseAlpha = pulse
        end
        
        table.insert(toDraw, data.ent)
    end
    
    if #toDraw > 0 then
        halo.Add(toDraw, Color(0, 150, 255, maxPulseAlpha), 2, 2, 2, true, false)
    end
end)
