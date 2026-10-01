-- ============================================================================
-- IVOSAM: COMANDO HUD
-- Oculta o muestra el nombre y vida de un jugador en específico
-- ============================================================================
my_admin = my_admin or {}

if SERVER then
    my_admin.RegisterCommand("hud", function(ply, args)
        local info = args[1]
        local state = args[2]
        
        if not info or not state then
            return ply:ChatPrint("[IVOSAM] Uso: !hud <nombre/id> <0/1>")
        end

        local target = my_admin.FindPlayer(info)
        if IsValid(target) then
            if target ~= ply and not IVO_SAM.CheckTarget(ply, target, "ocultarle el nombre a") then return end
            
            if state == "0" then
                target:SetNWBool("IVOSAM_HideNameplate", true)
                my_admin.Notify(ply, " ocultó el nombre y vida de ", target, false)
            elseif state == "1" then
                target:SetNWBool("IVOSAM_HideNameplate", false)
                my_admin.Notify(ply, " volvió a mostrar el nombre y vida de ", target, false)
            else
                ply:ChatPrint("[IVOSAM] Estado inválido. Usa 0 para apagar y 1 para prender.")
            end
        else
            ply:ChatPrint("[IVOSAM] No se encontró al jugador \"" .. info .. "\"")
        end
    end, { usage = "!hud <nombre/id> <0/1>", desc = "Oculta o muestra el nombre y vida de un jugador", level = "admin" })
end

if CLIENT then
    hook.Add("HUDDrawTargetID", "IVOSAM_HideTargetID", function()
        local tr = LocalPlayer():GetEyeTrace()
        local target = tr.Entity
        
        if IsValid(target) and target:IsPlayer() then
            if target:GetNWBool("IVOSAM_HideNameplate", false) then
                return false
            end
        end
    end)
    
    -- Para DarkRP (bloquea el dibujado individual en la función del HUD si es posible)
    -- DarkRP llama al hook basePlayerDrawHighlite o usa GetNoDraw.
    -- La mejor forma para el HUDDrawTargetID por defecto está cubierta arriba.
end
