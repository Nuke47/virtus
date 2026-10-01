local f = SERVER and AddCSLuaFile or include

if SERVER then
    f("ivo_tutorial/cl_tutorial.lua")
    include("ivo_tutorial/sv_tutorial.lua")
else
    include("ivo_tutorial/cl_tutorial.lua")
end
