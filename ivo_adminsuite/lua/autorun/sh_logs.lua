IvoLogsSystem = IvoLogsSystem or {}

IvoLogsSystem.Config = {
    MaxLogsMemory = 1000000, -- Logs guardados en ram
    AdminOnly = true -- solo admins usan !logs
}

if SERVER then
    util.AddNetworkString("IvoLogs_OpenMenu")

    include("server/sv_logger_core.lua")
    include("server/sv_logger_hooks.lua")

    -- Enviamos los archivos al cliente
    AddCSLuaFile("client/cl_logger_ui.lua")
    AddCSLuaFile("client/cl_death_scene.lua") -- [NUEVO] Enviamos el archivo al cliente
end

if CLIENT then
    include("client/cl_logger_ui.lua")
    include("client/cl_death_scene.lua")      -- [NUEVO] Cargamos el archivo en el cliente
end