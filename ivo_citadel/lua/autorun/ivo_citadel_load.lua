-- Autorun Loader for Ivo Citadel System

print("[Ivo Citadel] Carga Iniciada...")

-- Load Config First
AddCSLuaFile("ivo_citadel/sh_config.lua")
include("ivo_citadel/sh_config.lua")

-- Load Server
if SERVER then
    include("ivo_citadel/sv_core.lua")
    AddCSLuaFile("ivo_citadel/cl_core.lua")
    AddCSLuaFile("ivo_citadel/cl_menu.lua")
    AddCSLuaFile("ivo_citadel/cl_freecam.lua")
end

-- Load Client
if CLIENT then
    include("ivo_citadel/cl_core.lua")
    include("ivo_citadel/cl_menu.lua")
    include("ivo_citadel/cl_freecam.lua")
end

print("[Ivo Citadel] Carga Completada!")
