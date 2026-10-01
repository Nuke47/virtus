--[[
    ivo_bombs - Loader
    Carga todos los archivos del sistema de bombas
]]

IVO_BOMBS = IVO_BOMBS or {}
IVO_BOMBS.Modules = IVO_BOMBS.Modules or {}

-- Shared
include("ivo_bombs/sh_config.lua")
AddCSLuaFile("ivo_bombs/sh_config.lua")

if SERVER then
    AddCSLuaFile("ivo_bombs/cl_defuse_panel.lua")
    AddCSLuaFile("ivo_bombs/cl_module_wires.lua")
    AddCSLuaFile("ivo_bombs/cl_module_memory.lua")
    AddCSLuaFile("ivo_bombs/cl_module_keypad.lua")
    AddCSLuaFile("ivo_bombs/cl_module_pattern.lua")

    include("ivo_bombs/sv_defuse.lua")
end

if CLIENT then
    include("ivo_bombs/cl_module_wires.lua")
    include("ivo_bombs/cl_module_memory.lua")
    include("ivo_bombs/cl_module_keypad.lua")
    include("ivo_bombs/cl_module_pattern.lua")
    include("ivo_bombs/cl_defuse_panel.lua")
end

print("[ivo_bombs] Sistema de bombas cargado.")
