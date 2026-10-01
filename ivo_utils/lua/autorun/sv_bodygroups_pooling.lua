-- Servidor Puro: lua/autorun/sv_bodygroups_pooling.lua
if SERVER then
    util.AddNetworkString("v_bodygroups_Update")
    print("[💥 FIJO DE RED] Canal v_bodygroups_Update forzado en el inicio del Servidor.")
end