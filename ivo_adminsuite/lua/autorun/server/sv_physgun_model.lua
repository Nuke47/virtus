-- ==========================================================
-- IVOSAM: STAFF TOOLS CORE (SERVER) - DEFINITIVO
-- ==========================================================

local MODELO_COMBINE = "models/naval_eng/pm_naval_eng.mdl"

local ArmasStaff = {
    ["weapon_physgun"]    = true,
    ["gmod_tool"]         = true,
    ["weapon_physcannon"] = true
}

local ModelosOriginales = {}
local BodygroupsOriginales = {}

-- ==========================================================
-- 1. LÓGICA DE TRANSFORMACIÓN DE MODELO
-- ==========================================================

local function VerificarYTransformar(ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local armaActiva = ply:GetActiveWeapon()
    local classArma = IsValid(armaActiva) and armaActiva:GetClass() or ""

    if ArmasStaff[classArma] then
        if ply:GetModel() == MODELO_COMBINE then return end
        ModelosOriginales[ply:SteamID()] = ply:GetModel()
        
        local bgs = {}
        for _, bg in pairs(ply:GetBodyGroups() or {}) do
            bgs[bg.id] = ply:GetBodygroup(bg.id)
        end
        BodygroupsOriginales[ply:SteamID()] = bgs
        
        ply:SetModel(MODELO_COMBINE)
        ply:SetupHands()
    end
end

hook.Add("PlayerSwitchWeapon", "IVOSAM_StaffTools_Model_Switch", function(ply, oldWep, newWep)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local sNewWep = IsValid(newWep) and newWep:GetClass() or ""
    local sOldWep = IsValid(oldWep) and oldWep:GetClass() or ""

    if ArmasStaff[sNewWep] then
        if ply:GetModel() == MODELO_COMBINE then return end
        ModelosOriginales[ply:SteamID()] = ply:GetModel()
        
        local bgs = {}
        for _, bg in pairs(ply:GetBodyGroups() or {}) do
            bgs[bg.id] = ply:GetBodygroup(bg.id)
        end
        BodygroupsOriginales[ply:SteamID()] = bgs
        
        ply:SetModel(MODELO_COMBINE)
        ply:SetupHands() 
    elseif ArmasStaff[sOldWep] and not ArmasStaff[sNewWep] then
        local modeloViejo = ModelosOriginales[ply:SteamID()]
        if modeloViejo then
            ply:SetModel(modeloViejo)
            ply:SetupHands()
            ModelosOriginales[ply:SteamID()] = nil 
        else
            if ply.GetJobModel then 
                ply:SetModel(ply:GetJobModel())
                ply:SetupHands()
            end
        end
        
        timer.Simple(0.2, function()
            if not IsValid(ply) then return end
            if BodygroupsOriginales[ply:SteamID()] then
                for bg_id, bg_val in pairs(BodygroupsOriginales[ply:SteamID()]) do
                    ply:SetBodygroup(bg_id, bg_val)
                end
                BodygroupsOriginales[ply:SteamID()] = nil
            end
            
            timer.Simple(0.2, function()
                if IsValid(ply) and SW_InvShop and SW_InvShop.EnforceActiveBodygroups then
                    SW_InvShop.EnforceActiveBodygroups(ply)
                end
            end)
        end)
    end
end)

hook.Add("PlayerSpawn", "IVOSAM_StaffTools_Model_Spawn", function(ply)
    timer.Simple(0.1, function()
        VerificarYTransformar(ply)
    end)
end)



-- ==========================================================
-- 2. INTERACCIONES DE CONGELAMIENTO (SISTEMA DE SEGURIDAD IVO_SAM)
-- ==========================================================

-- Función de validación basada exactamente en tu sistema IVO_SAM
local function CanStaffTarget(ply, target)
    if not IsValid(ply) or not IsValid(target) then return false end

    -- 1. Rango y Poder del Administrador
    local plyRank = isfunction(ply.GetRank) and ply:GetRank():lower() or "user"
    local plyPower = IVO_SAM.Ranks[plyRank] and IVO_SAM.Ranks[plyRank].power or 0

    -- 2. Rango y Poder del Objetivo (Online)
    local targetRank = isfunction(target.GetRank) and target:GetRank():lower() or "user"
    local targetPower = IVO_SAM.Ranks[targetRank] and IVO_SAM.Ranks[targetRank].power or 0

    -- 3. Comparación de Inmunidad idéntica a tus comandos de baneo
    if plyPower < targetPower and targetPower > 0 then
        return false, targetRank:upper() -- Retornamos false y el nombre del rango superior
    end

    return true
end

-- CLICK DERECHO: Congelar e inmunizar al jugador (Verificando IVO_SAM)
hook.Add("OnPhysgunFreeze", "IVOSAM_Physgun_RightClick_Freeze", function(weapon, phys, target, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    if not IsValid(target) or not target:IsPlayer() then return end

    -- Ejecutamos tu control de seguridad
    local canTarget, targetRankStr = CanStaffTarget(ply, target)
    if not canTarget then
        ply:ChatPrint("[IVOSAM] Inmunidad: No puedes congelar a este jugador porque pertenece a un rango superior (" .. targetRankStr .. ").")
        return true -- Cancela la acción física
    end

    local exactPos = target:GetPos()

    timer.Simple(0, function()
        if not IsValid(target) then return end
        
        target:SetPos(exactPos)
        target:SetVelocity(Vector(0, 0, 0))
        target:SetLocalVelocity(Vector(0, 0, 0))
        
        target:Freeze(true)
        target:SetMoveType(MOVETYPE_NONE)
        target.IvosamFrozen = true
    end)

    ply:ChatPrint("[IVOSAM] Has congelado e hecho INMORTAL a " .. target:Nick())
    return true 
end)

-- CLICK IZQUIERDO: Descongelar y remover efectos (Verificando IVO_SAM)
hook.Add("KeyPress", "IVOSAM_Physgun_LeftClick_Unfreeze", function(ply, key)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    if key ~= IN_ATTACK then return end 

    local activeWep = ply:GetActiveWeapon()
    if not IsValid(activeWep) or activeWep:GetClass() ~= "weapon_physgun" then return end

    local trace = ply:GetEyeTrace()
    local target = trace.Entity

    if IsValid(target) and target:IsPlayer() and target.IvosamFrozen then
        
        -- Ejecutamos tu control de seguridad también al intentar descongelar
        local canTarget, targetRankStr = CanStaffTarget(ply, target)
        if not canTarget then
            ply:ChatPrint("[IVOSAM] Inmunidad: No puedes interactuar con este jugador porque fue congelado por un rango superior (" .. targetRankStr .. ").")
            return
        end
        
        target:Freeze(false)
        target:SetMoveType(MOVETYPE_WALK)
        target.IvosamFrozen = nil
        target:GodDisable() 
        
        ply:ChatPrint("[IVOSAM] Has descongelado y quitado la inmortalidad a " .. target:Nick())
    end
end)

-- ESCUDO DE DAÑO ACTIVO
hook.Add("EntityTakeDamage", "IVOSAM_Physgun_Inmortalidad", function(target, dmginfo)
    if IsValid(target) and target:IsPlayer() and target.IvosamFrozen then
        dmginfo:ScaleDamage(0)
        dmginfo:SetDamage(0)
        return true 
    end
end)