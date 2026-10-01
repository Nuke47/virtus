-- ============================================================
--  SW:RP Grappling Hook - autorun/grapple_hook_sv.lua (SERVER)
-- ============================================================
if CLIENT then return end

-- Red para detectar la tecla ENTER del cliente
util.AddNetworkString("GrappleHook_EnterKey")
net.Receive("GrappleHook_EnterKey", function(len, ply)
    ply.GrappleReelingIn = net.ReadBool()
end)

local function FindPlayerTarget(targetStr)
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()) == string.lower(targetStr) then return p end
    end
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()):find(string.lower(targetStr), 1, true) then return p end
    end
    return nil
end

concommand.Add("grapple_give", function(ply, _, args)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then
        ply:ChatPrint("[Grappling Hook] Comando exclusivo de Super Admin.")
        return
    end

    local target = args[1]
    if not target then
        ply:ChatPrint("[Grappling Hook] Uso: grapple_give <nombre_jugador>")
        return
    end

    local found = FindPlayerTarget(target)
    if not IsValid(found) then
        ply:ChatPrint("[Grappling Hook] Jugador no encontrado: " .. target)
        return
    end

    found:Give("weapon_grapple_hook")
    ply:ChatPrint("[Grappling Hook] Entregado a " .. found:Nick())
    found:ChatPrint("[Grappling Hook] Has recibido un Grappling Hook de " .. ply:Nick())
end, nil, "Entregar un gancho", FCVAR_PROTECTED)

concommand.Add("grapple_take", function(ply, _, args)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then
        ply:ChatPrint("[Grappling Hook] Comando exclusivo de Super Admin.")
        return
    end

    local target = args[1]
    if not target then
        ply:ChatPrint("[Grappling Hook] Uso: grapple_take <nombre_jugador>")
        return
    end

    local found = FindPlayerTarget(target)
    if IsValid(found) then
        if IsValid(found:GetWeapon("weapon_grapple_hook")) then
            found:StripWeapon("weapon_grapple_hook")
            ply:ChatPrint("[Grappling Hook] Retirado de " .. found:Nick())
            found:ChatPrint("[Grappling Hook] Tu Grappling Hook fue retirado.")
        else
            ply:ChatPrint("[Grappling Hook] " .. found:Nick() .. " no tiene un Grappling Hook.")
        end
    else
        ply:ChatPrint("[Grappling Hook] Jugador no encontrado: " .. target)
    end
end, nil, "Retirar un gancho", FCVAR_PROTECTED)

local LOG_PREFIX = "[GrappleHook] "
local function GrappleLog(msg)
    MsgC(Color(255, 200, 60), LOG_PREFIX, Color(200, 220, 255), msg .. "\n")
end

hook.Add("PlayerDeath", "GrappleHook_CleanupOnDeath", function(victim)
    local wep = victim:GetWeapon("weapon_grapple_hook")
    if IsValid(wep) then wep:RetractHook(true) end
end)

hook.Add("PlayerDisconnected", "GrappleHook_CleanupOnLeave", function(ply)
    local wep = ply:GetWeapon("weapon_grapple_hook")
    if IsValid(wep) then wep:RetractHook(true) end
end)

GrappleLog("Grappling Hook - Cargado con controles definitivos (LMB/ENTER / E / RMB / R)")