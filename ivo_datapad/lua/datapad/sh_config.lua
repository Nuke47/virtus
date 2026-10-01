-- ==========================================
-- INICIALIZACIÓN GLOBAL
-- ==========================================
Datapad = Datapad or {}
Datapad.Config  = Datapad.Config  or {}
Datapad.Modules = Datapad.Modules or {}

-- ==========================================
-- CONFIGURACIÓN DE ACCESOS (JOBS)
-- Usamos STRINGS para evitar nil errors por orden de carga
-- ==========================================

-- ISB: Inteligencia Imperial
Datapad.Config.ISBJobs = {
    "TEAM_5_ISB_SOL",
    "TEAM_5_ISB_ASA",
    "TEAM_5_ISB_APO",
    "TEAM_5_ISB_ARC",
    "TEAM_5_ISB_CMD",
    "TEAM_5_ISB_REC",
}

-- 65th / Riot Troopers: Red Táctica
Datapad.Config.RiotJobs = {
    "TEAM_65_RT_SOL",
    "TEAM_65_RT_REC",
    "TEAM_65_RT_APO",
    "TEAM_65_RT_ASA",
    "TEAM_65_RT_ARC",
    "TEAM_65_RT_CMD",
    "TEAM_65_RT_FOX",
    "TEAM_65_RT_HOUND",
}

-- 65th / Shocktroopers: Base de Datos de Arrestos
Datapad.Config.ShockJobs = {
    "TEAM_65_RT_SOL",
    "TEAM_65_RT_REC",
    "TEAM_65_RT_APO",
    "TEAM_65_RT_ASA",
    "TEAM_65_RT_ARC",
    "TEAM_65_RT_CMD",
    "TEAM_65_RT_FOX",
    "TEAM_65_RT_HOUND",
}

-- Sindicato / Criminales (Hackeo y Robo de Datos)
Datapad.Config.HackerJobs = {
    "TEAM_CT_SU_SOL",
    "TEAM_CT_SU_ASA",
    "TEAM_CT_SU_APO",
    "TEAM_CT_SU_REC",
    "TEAM_CT_SU_ARC",
    "TEAM_CT_SU_CMD",
    "TEAM_CADETE", -- Para pruebas de hackeo de puertas
}

-- Cazarrecompensas
Datapad.Config.BountyHunters = {
    "TEAM_CAZARRECOMPENSAS",
    "TEAM_CR",
    "TEAM_BOUNTY_HUNTER"
}

-- SU Spec: Operadores de Droide Sonda
Datapad.Config.SUSpecJobs = {
    "TEAM_SU_SPEC",
    "TEAM_SU_ESPECIALISTA",
}

-- Staff con acceso omnipotente
Datapad.Config.StaffJobs = {
    "TEAM_STAFF"
}

-- ==========================================
-- SISTEMA DE VERIFICACIÓN DE PERMISOS
-- ==========================================
Datapad.Cache65th = Datapad.Cache65th or {}

function Datapad:HasAccess(ply, allowedJobsTable)
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    -- Bypass para SuperAdmins
    if ply:IsSuperAdmin() then return true end

    local plyTeam = ply:Team()
    local jobName = string.upper(team.GetName(plyTeam) or "")

    -- Bypass automático para Staff
    for _, staffJobVar in ipairs(self.Config.StaffJobs) do
        if _G[staffJobVar] and plyTeam == _G[staffJobVar] then return true end
    end

    -- Verificar job actual contra la tabla permitida
    if allowedJobsTable then
        for _, jobVar in ipairs(allowedJobsTable) do
            -- Chequeo por variable global
            if _G[jobVar] and plyTeam == _G[jobVar] then return true end
            -- Chequeo por nombre de trabajo (string fallback)
            if string.upper(jobVar) == jobName then return true end
            -- Si el jobVar es TEAM_SU_SPEC y el nombre del job es "SU: ESPECIALISTA"
            if jobVar == "TEAM_SU_SPEC" and jobName == "SU: ESPECIALISTA" then return true end
            if jobVar == "TEAM_SU_ESPECIALISTA" and jobName == "SU: ESPECIALISTA" then return true end
        end
    end
    
    -- Bypass dinámico para cualquier job que empiece con TEAM_65_
    if allowedJobsTable == self.Config.ShockJobs or allowedJobsTable == self.Config.RiotJobs then
        if self.Cache65th[plyTeam] then return true end
        for k, v in pairs(_G) do
            if type(v) == "number" and v == plyTeam and type(k) == "string" and string.StartWith(k, "TEAM_65_") then
                self.Cache65th[plyTeam] = true
                return true
            end
        end
    end

    return false
end

Datapad.CacheImperial = Datapad.CacheImperial or {}
function Datapad:IsImperial(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local plyTeam = ply:Team()
    
    if self.CacheImperial[plyTeam] ~= nil then return self.CacheImperial[plyTeam] end
    
    local isImp = false
    for k, v in pairs(_G) do
        if type(v) == "number" and v == plyTeam and type(k) == "string" then
            if string.StartWith(k, "TEAM_5_") or string.StartWith(k, "TEAM_501_") or string.StartWith(k, "TEAM_CT_") or string.StartWith(k, "TEAM_65_") then
                isImp = true
                break
            end
        end
    end
    
    self.CacheImperial[plyTeam] = isImp
    return isImp
end

-- ==========================================
-- SISTEMA DE NIVELES DE ACCESO (0 - 5)
-- ==========================================
Datapad.AccessCache = Datapad.AccessCache or {}

function Datapad:GetPlayerAccessLevel(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return 0 end
    
    local plyTeam = ply:Team()
    
    -- Si ya calculamos su nivel y no ha cambiado de job, devolvemos el cache
    if self.AccessCache[plyTeam] ~= nil then 
        return self.AccessCache[plyTeam] 
    end
    
    local level = 0
    local jobName = team.GetName(plyTeam) or ""
    local jobNameUpper = string.upper(jobName)
    local jobTable = RPExtraTeams and RPExtraTeams[plyTeam] or nil
    
    -- Variables para verificación
    local isImperialForce = false
    for k, v in pairs(_G) do
        if type(v) == "number" and v == plyTeam and type(k) == "string" then
            if string.StartWith(k, "TEAM_5_") or string.StartWith(k, "TEAM_65_") then
                isImperialForce = true
                break
            end
        end
    end
    
    -- Nivel 5: GRL, Moff, o Categoría "Altos Mandos"
    if string.find(jobNameUpper, "GRL") or string.find(jobNameUpper, "MOFF") then
        level = 5
    elseif jobTable and string.lower(jobTable.category or "") == "altos mandos" then
        level = 5
    -- Nivel 4: ISB, RT, o Comandante
    elseif string.find(jobNameUpper, "ISB") or string.find(jobNameUpper, "RT") or string.find(jobNameUpper, "COMANDANTE") or string.find(jobNameUpper, "CMD") then
        level = 4
    -- Nivel 3: Personal de seguridad/mantención (TEAM_5_, TEAM_65_) o CPT
    elseif isImperialForce or string.find(jobNameUpper, "CPT") then
        level = 3
    -- Nivel 2: SGT
    elseif string.find(jobNameUpper, "SGT") then
        level = 2
    -- Nivel 1: CDT, SDO, CBO
    elseif string.find(jobNameUpper, "CDT") or string.find(jobNameUpper, "SDO") or string.find(jobNameUpper, "CBO") then
        level = 1
    end
    
    -- Staff siempre tiene Nivel 5 (Omnipotente)
    for _, staffJobVar in ipairs(self.Config.StaffJobs) do
        if _G[staffJobVar] and plyTeam == _G[staffJobVar] then 
            level = 5 
            break
        end
    end
    
    self.AccessCache[plyTeam] = level
    return level
end

-- ==========================================
-- TIMINGS
-- ==========================================
Datapad.Config.HackTimeConsole = 10
Datapad.Config.SliceTime       = 15

-- ==========================================
-- PALETA DE COLORES BASE
-- ==========================================
Datapad.Config.Colors = {
    Background = Color(15, 20, 25, 240),
    Sidebar    = Color(10, 15, 20, 255),
    Accent     = Color(0, 150, 255),
    Text       = Color(200, 220, 255),
    Warning    = Color(255, 50, 50),
}

-- ==========================================
-- SISTEMA DE REGISTRO DE MÓDULOS
-- ==========================================
function Datapad:RegisterModule(id, data)
    self.Modules[id] = {
        Name      = data.Name      or "Módulo Desconocido",
        Icon      = data.Icon      or "icon16/cog.png",
        Order     = data.Order     or 99,
        CanAccess = data.CanAccess or function(ply) return false end,
        UI        = data.UI        or function(parent) end,
    }
    print("[Datapad] Módulo cargado: " .. self.Modules[id].Name)
end
