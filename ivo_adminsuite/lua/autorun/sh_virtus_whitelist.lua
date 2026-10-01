-- Virtus Whitelist - Loader

print("[Virtus Whitelist] Inicializando sistema de whitelist...")

if SERVER then
    AddCSLuaFile("virtus_whitelist/client/cl_menu.lua")
    AddCSLuaFile("virtus_whitelist/client/cl_net.lua")
    AddCSLuaFile("virtus_whitelist/client/cl_properties.lua")

    include("virtus_whitelist/server/sv_db.lua")
    include("virtus_whitelist/server/sv_net.lua")
    include("virtus_whitelist/server/sv_hooks.lua")
end

if CLIENT then
    include("virtus_whitelist/client/cl_net.lua")
    include("virtus_whitelist/client/cl_menu.lua")
    include("virtus_whitelist/client/cl_properties.lua")
end
