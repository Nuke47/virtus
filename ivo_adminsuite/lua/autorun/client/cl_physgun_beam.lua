-- ==========================================================
-- IVOSAM: OCULTAR RAYO DE PHYSGUN AL AGARRAR JUGADORES
-- ==========================================================

hook.Add("DrawPhysgunBeam", "IVOSAM_Ocultar_Rayo_Staff", function(ply, physgun, enabled, target, physBone, hitPos)
    -- Verificaciones básicas de seguridad en el cliente
    if not IsValid(ply) or not IsValid(target) then return end

    -- Si el que dispara la Physgun es Admin y está apuntando/agarrando a un Jugador...
    if ply:IsAdmin() and target:IsPlayer() then
        return false -- RETORNAMOS FALSE: Esto le ordena a GMod NO dibujar el rayo láser
    end
end)

