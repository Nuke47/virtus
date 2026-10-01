-- ============================================================================
-- [StarWarsRP] Sistema de Inventario, Armario y Tienda Galáctica
-- Autorun Principal del Addon
-- ============================================================================

-- Declaramos la tabla global del addon para evitar conflictos con otros sistemas
SW_InvShop = SW_InvShop or {}

-- Función optimizada para incluir y enviar archivos según su entorno (Realm)
local function LoadFile(filePath, realm)
    realm = string.lower(realm)

    if realm == "shared" then
        if SERVER then 
            AddCSLuaFile(filePath) 
        end
        include(filePath)
    elseif realm == "server" then
        if SERVER then 
            include(filePath) 
        end
    elseif realm == "client" then
        if SERVER then 
            AddCSLuaFile(filePath) 
        else 
            include(filePath) 
        end
    end
end

-- ============================================================================
-- CARGA DE ARCHIVOS EN ORDEN CRÍTICO
-- ============================================================================

-- 1. Base y Configuración (Esencial que cargue antes que todo lo demás)
LoadFile("sw_invshop/shared/sh_config.lua", "shared")

-- 2. Lógica del Servidor (Base de datos temporal, Net Messages y compras)
LoadFile("sw_invshop/inventory/sv_inventory.lua", "server")

-- 3. Lógica del Cliente (Receptores de red y actualización de datos)
LoadFile("sw_invshop/inventory/cl_inventory.lua", "client")

-- 4. Interfaces Visuales / Derma (Solo cliente)
LoadFile("sw_invshop/vgui/cl_shop_tools.lua", "client")
LoadFile("sw_invshop/vgui/cl_menu_main.lua", "client")
LoadFile("sw_invshop/vgui/cl_3d_shop.lua", "client")
LoadFile("sw_invshop/vgui/cl_3d_armario.lua", "client")

-- ============================================================================
-- CONFIRMACIÓN EN CONSOLA
-- ============================================================================
if SERVER then
    print("\n[SW_InvShop] --------------------------------------------------")
    print("[SW_InvShop] SERVIDOR: Lógica e hilos de red inicializados.")
    print("[SW_InvShop] --------------------------------------------------\n")
else
    print("\n[SW_InvShop] --------------------------------------------------")
    print("[SW_InvShop] CLIENTE: Interfaces Derma y sincronización listas.")
    print("[SW_InvShop] --------------------------------------------------\n")
end