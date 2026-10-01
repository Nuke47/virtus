-- ============================================================================
-- IVOSAM: GUARDS — Validaciones centrales de jerarquía y permisos
-- Reemplaza los 20+ bloques de CanTarget copy-pasteados en los comandos.
-- ============================================================================
IVO_SAM = IVO_SAM or {}

-- Verifica jerarquía y notifica al admin si no puede actuar sobre el target.
-- Retorna true si puede proceder, false si está bloqueado por inmunidad.
function IVO_SAM.CheckTarget(admin, target, actionVerb)
    if not IsValid(admin) then return true end
    if not IsValid(target) then return false end
    if admin == target then return true end
    if not IVO_SAM.CanTarget(admin, target) then
        admin:ChatPrint("[IVOSAM] Inmunidad: No puedes " .. actionVerb .. " a " ..
                        target:Nick() .. " (rango superior o igual al tuyo).")
        return false
    end
    return true
end

-- Verifica que el jugador tenga rango Admin o superior.
function IVO_SAM.RequireAdmin(ply)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("[IVOSAM] No tienes permisos de Administrador.")
        return false
    end
    return true
end

-- Verifica que el jugador tenga rango SuperAdmin.
function IVO_SAM.RequireSuperAdmin(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("[IVOSAM] No tienes permisos de SuperAdministrador.")
        return false
    end
    return true
end
