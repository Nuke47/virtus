

-- Archivo Compartido Raíz: lua/autorun/sh_bodygroups_init.lua
v_bodygroups = v_bodygroups or {}

if SERVER then
    -- Forzamos la creación del canal de red de manera absoluta en el servidor
    util.AddNetworkString("v_bodygroups_Update")

    -- Descargas obligatorias para los clientes (Workshop)
    resource.AddWorkshop("2796738424")
    resource.AddWorkshop("2607559539")
    -- resource.AddWorkshop("ID_DE_TU_WORKSHOP_AQUI")
    
    -- Enviamos los archivos necesarios al cliente
    AddCSLuaFile("v_bodygroups/cl_net.lua")
    AddCSLuaFile("v_bodygroups/cl_context_menu.lua")
    
    -- Cargamos el script del servidor
    include("v_bodygroups/sv_net.lua")
    print("[Bodygroups - Servidor] Red y scripts cargados.")
end

if CLIENT then
    -- Cargamos scripts del cliente
    include("v_bodygroups/cl_net.lua")
    include("v_bodygroups/cl_context_menu.lua")
    print("[Bodygroups - Cliente] Interfaz cargada.")
end