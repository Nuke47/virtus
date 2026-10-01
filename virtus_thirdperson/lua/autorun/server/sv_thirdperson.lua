-- sv_thirdperson.lua
if CLIENT then return end

-- Forzamos a Garry's Mod a enviar el archivo de la cámara a todos los jugadores que entren
AddCSLuaFile("autorun/client/cl_thirdperson.lua")

-- Registrar la red de comunicación
util.AddNetworkString("TP_Toggle_Camera")
util.AddNetworkString("Virtus_TP_State")

-- Comando de consola en servidor por si acaso
concommand.Add("toggle_thirdperson", function(ply)
    if not IsValid(ply) then return end
    net.Start("TP_Toggle_Camera")
    net.Send(ply)
end)

-- Recibir el estado de la cámara del cliente
net.Receive("Virtus_TP_State", function(len, ply)
    if not IsValid(ply) then return end
    local state = net.ReadBool()
    ply:SetNWBool("Virtus_ThirdPersonActive", state)
end)

-- Prevenir tracers dobles desde el lado del servidor
hook.Add("EntityFireBullets", "Virtus_TP_FixTracers_SV", function(ent, data)
    if IsValid(ent) and ent:IsPlayer() and ent:GetNWBool("Virtus_ThirdPersonActive", false) then
        local wep = ent:GetActiveWeapon()
        if IsValid(wep) and wep.IsTFAWeapon then
            data.Tracer = 0
            return true
        end
    end
end)