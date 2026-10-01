-- ============================================
--  BOUNTY HUNTER SYSTEM - Autorun Loader
--  Archivo: lua/autorun/bounty_hunter_loader.lua
-- ============================================

-- Cargar config compartida (server y client)
include("bounty_hunter/shared/config.lua")

if SERVER then
    -- Enviar archivos al cliente
    AddCSLuaFile("bounty_hunter/shared/config.lua")
    AddCSLuaFile("bounty_hunter/client/cl_bounty.lua")

    -- Cargar lógica del servidor
    include("bounty_hunter/server/sv_bounty.lua")
end

if CLIENT then
    -- Cargar UI del cliente
    include("bounty_hunter/client/cl_bounty.lua")
end
