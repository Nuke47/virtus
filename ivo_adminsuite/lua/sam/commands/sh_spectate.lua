-- ============================================================================
-- IVOSAM: COMANDO SPECTATE & ANIQUILADOR ASÍNCRONO DE FSPECTATE
-- ============================================================================

-- 1. REGISTRO NATIVO IVOSAM
my_admin.RegisterCommand("spectate", function(ply, args)
    if not IsValid(ply) then return end
    

    if SERVER then
        -- Forzamos la desactivación de cualquier rastro de FSpectate en el administrador
        if ply.FSpectating then 
            ply.FSpectating = false
            ply:UnSpectate()
            ply:Spawn()
        end

        -- Lanzamos tu red nativa con HUD azul
        net.Start("Ivosam_Freecam")
        net.Send(ply)
        
        my_admin.Notify(ply, " activó el modo espectador con cámara libre.", nil, false)
    end
end)

-- 2. ANIQUILACIÓN QUIRÚRGICA EN EL SERVIDOR (Con retraso de 1 segundo)
if SERVER then
    hook.Add("Initialize", "IVO_SAM_TemporizadorFSpectate_SV", function()
        -- Esperamos 1 segundo después de que TODO el servidor haya cargado
        timer.Simple(1, function()
            print("[IVOSAM] Ejecutando limpieza forzada de FSpectate en el Servidor...")

            -- Eliminamos el hook del chat de FSpectate
            hook.Remove("PlayerSay", "FSpectate")

            -- Eliminamos los comandos de consola en mayúsculas y minúsculas
            concommand.Remove("FSpectate")
            concommand.Remove("fspectate")
            concommand.Remove("_FSpectatePosUpdate")
            concommand.Remove("fadmin_spectate")

            -- Si DarkRP registró el comando de chat nativo, lo borramos de su lista
            if DarkRP and DarkRP.removeChatCommand then
                DarkRP.removeChatCommand("spectate")
            end
        end)
    end)

    -- Interceptor de chat de respaldo (Por si algo falla)
    hook.Add("PlayerSay", "!!!IVO_SAM_FuerzaBrutaSpectate", function(ply, text, teamOnly)
        if not IsValid(ply) then return end
        
        local limpio = string.lower(string.Trim(text))
        if limpio == "!spectate" or limpio == "/spectate" then

            if ply.FSpectating then 
                ply.FSpectating = false
                ply:UnSpectate()
                ply:Spawn()
            end

            net.Start("Ivosam_Freecam")
            net.Send(ply)
            
            if my_admin and my_admin.Notify then
                my_admin.Notify(ply, " activó el modo espectador con cámara libre.", nil, false)
            end
            
            return "" -- Rompe el flujo del chat de FSpectate
        end
    end, -100)
end

-- 3. ANIQUILACIÓN QUIRÚRGICA EN EL CLIENTE (Con retraso de 1 segundo)
if CLIENT then
    hook.Add("Initialize", "IVO_SAM_TemporizadorFSpectate_CL", function()
        -- Esperamos 1 segundo en la PC de cada jugador para borrar los comandos cliente
        timer.Simple(1, function()
            print("[IVOSAM] Ejecutando limpieza forzada de FSpectate en el Cliente...")

            -- Borramos el comando de la consola del cliente
            concommand.Remove("FSpectate")
            concommand.Remove("fspectate")

            -- Desarmamos todos sus hooks visuales del cl_init.lua original
            hook.Remove("CalcView", "FSpectate")
            hook.Remove("PlayerBindPress", "FSpectate")
            hook.Remove("ShouldDrawLocalPlayer", "FSpectate")
            hook.Remove("Think", "FSpectate")
            hook.Remove("HUDPaint", "FSpectate")
            hook.Remove("FAdmin_ShowFAdminMenu", "FSpectate")
            hook.Remove("RenderScreenspaceEffects", "FSpectate")
        end)
    end)
end