CreateConVar("sv_physgun_beam_default", "0", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Si está en 0, desactiva el rayo de la physgun para todos los jugadores en el servidor.")

if CLIENT then
    hook.Add("DrawPhysgunBeam", "ServerDisablePhysgunBeam", function(ply, physgun, enabled, target, bone, hitpos)
        if not GetConVar("sv_physgun_beam_default"):GetBool() then
            return false -- Oculta el rayo
        end
        -- Si es true, retorna nil y permite que el comportamiento normal (y los ajustes del cliente) se apliquen.
    end)
end
