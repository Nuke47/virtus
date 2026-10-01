local ply = FindMetaTable("Player")

-- Obtiene el ID del rango del jugador
function ply:GetRank()
    -- Prioridad 1: Rango asignado por tu sistema
    local rank = self:GetNWString("my_rank", "user")
    
    -- Prioridad 2: Si es superadmin de GMod y no tiene rango, darle superadmin del sistema
    if rank == "user" and self:IsSuperAdmin() then
        return "superadmin"
    end
    
    return rank
end

-- Nueva función: Obtiene toda la tabla de datos del rango del jugador
function ply:GetRankData()
    local rankName = self:GetRank()
    -- Buscamos en la tabla global que definimos en sh_init
    return IVO_SAM.Ranks[rankName] or IVO_SAM.Ranks["user"]
end

-- Función actualizada: Ahora pregunta si el rango tiene permiso "IsAdmin"
function ply:IsAdmin()
    local data = self:GetRankData()
    return data and data.IsAdmin == true
end

-- Función de utilidad para chequear cualquier permiso
-- Ejemplo: if ply:HasPermission("CanBan") then ...
function ply:HasPermission(perm)
    local data = self:GetRankData()
    if not data then return false end
    
    -- Los superadmins con poder 100 suelen saltarse los chequeos
    if data.val and data.val >= 100 then return true end
    
    return data[perm] == true
end