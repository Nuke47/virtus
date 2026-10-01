-- Forzamos la creación de la tabla si no existe
my_admin = my_admin or {} 

-- =========================================================
-- CONFIGURACIÓN INICIAL (DEFCON 5 POR DEFECTO AL ENTRAR/INICIAR)
-- =========================================================
hook.Add("InitPostEntity", "IVOSAM_Defcon_Default_Level", function()
    -- Al iniciar el servidor o cambiar de mapa, forzamos el nivel base a 5
    SetGlobalInt("IVOSAM_DefconLevel", 5)
    print("[IVOSAM] Sistema de alerta inicializado. DEFCON establecido en Nivel 5 por defecto.")
end)

-- =========================================================
-- REGISTRO SEGURO DEL COMANDO
-- =========================================================
-- Usamos un hook de inicialización para asegurar que 'my_admin.RegisterCommand' ya exista
hook.Add("InitPostEntity", "IVOSAM_Register_Defcon_Command", function()
    
    if not my_admin or not my_admin.RegisterCommand then
        -- Intento secundario por si tu sistema usa otro hook específico de carga
        hook.Add("SAM:Initialized", "IVOSAM_Register_Defcon_Backup", function()
            if my_admin and my_admin.RegisterCommand then
                RegisterDefconActual()
            end
        end)
        return
    end

    RegisterDefconActual()
end)

-- Separamos la función del comando para que el código quede limpio y modular
function RegisterDefconActual()
    my_admin.RegisterCommand("defcon", function(ply, args)
        if IsValid(ply) and not IVO_SAM.HasPermission(ply, "defcon") then return end
        
        local level = tonumber(args[1])
        if not level or level < 0 or level > 5 then 
            return ply:ChatPrint("Uso: !defcon <0-5>") 
        end

        SetGlobalInt("IVOSAM_DefconLevel", level)

        -- Notificación nativa
        if sam and sam.player and sam.player.send_message then
            sam.player.send_message(nil, "{A} cambió el defcon del servidor a {S}", {
                A = ply, S = tostring(level)
            })
        elseif my_admin and my_admin.Notify then
            my_admin.Notify(ply, " cambió el defcon del servidor a ", "", false, tostring(level))
        end
    end)
    
    print("[IVOSAM] Comando !defcon inyectado y listo para usar.")
end