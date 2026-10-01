-- ==========================================
-- CARGADOR MAESTRO DEL DATAPAD
-- ==========================================
Datapad = Datapad or {}

if SERVER then
    AddCSLuaFile("datapad/sh_config.lua")
    AddCSLuaFile("datapad/cl_ui.lua")
    AddCSLuaFile("datapad/cl_net.lua")

    local files, _ = file.Find("datapad/modules/*.lua", "LUA")
    for _, v in ipairs(files) do
        AddCSLuaFile("datapad/modules/" .. v)
    end
end

-- 1. Compartido
include("datapad/sh_config.lua")

-- 2. Cliente
if CLIENT then
    include("datapad/cl_ui.lua")
    include("datapad/cl_net.lua")
end

-- 3. Módulos (servidor + cliente según guard interno de cada archivo)
local files, _ = file.Find("datapad/modules/*.lua", "LUA")
for _, v in ipairs(files) do
    include("datapad/modules/" .. v)
end

print("[Datapad] Archivos cargados correctamente.")
