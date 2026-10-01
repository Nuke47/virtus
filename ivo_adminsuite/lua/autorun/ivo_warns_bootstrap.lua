-- ==========================================
-- IVO_WARNS - BOOTSTRAP (CARGADOR)
-- ==========================================

IVO_WARNS = IVO_WARNS or {}
IVO_WARNS.Version = "1.0.0"

-- 1. Cargar Configuración (Compartido)
AddCSLuaFile("ivo_warns/sh_config.lua")
include("ivo_warns/sh_config.lua")

-- 2. Cargar Servidor / Cliente
if SERVER then
    -- Enviar el archivo del cliente para que lo descargue
    AddCSLuaFile("ivo_warns/cl_init.lua")
    -- Incluir la lógica del servidor
    include("ivo_warns/init.lua")
    
    print("[Ivo_Warns] Servidor inicializado correctamente (Versión " .. IVO_WARNS.Version .. ")")
end

if CLIENT then
    -- Incluir la interfaz y lógica del cliente
    include("ivo_warns/cl_init.lua")
    
    print("[Ivo_Warns] Cliente inicializado correctamente (Versión " .. IVO_WARNS.Version .. ")")
end