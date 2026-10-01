IVO_HABILITIES = IVO_HABILITIES or {}

if SERVER then
    include("ivo_habilities/sv_database.lua")
    include("ivo_habilities/sh_skills.lua")
    include("ivo_habilities/sv_core.lua")
    include("ivo_habilities/sv_cmds.lua")
    include("ivo_habilities/sh_stamina.lua")
    
    AddCSLuaFile("ivo_habilities/sh_skills.lua")
    AddCSLuaFile("ivo_habilities/cl_core.lua")
    AddCSLuaFile("ivo_habilities/sh_stamina.lua")
    AddCSLuaFile("ivo_habilities/cl_skilltree.lua")
else
    include("ivo_habilities/sh_skills.lua")
    include("ivo_habilities/cl_core.lua")
    include("ivo_habilities/sh_stamina.lua")
    include("ivo_habilities/cl_skilltree.lua")
end

print("[IVO HABILITIES] Addon cargado correctamente.")
