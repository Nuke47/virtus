-- ============================================================================
-- IVOSAM: SISTEMA DE XP Y NIVELES (SHARED)
-- ============================================================================
IVO_SAM = IVO_SAM or {}

function IVO_SAM.GetJobSpecialty(jobTable)
    if not jobTable then return "" end
    local name = string.lower(jobTable.name or "")
    local cmd = jobTable.command or ""
    
    if string.find(name, "comandante") then return "comandante", true end
    if string.find(name, "reconocimiento") then return "reconocimiento", true end
    if string.find(name, "asalto") then return "asalto", true end
    if string.find(name, "apoyo") then return "apoyo", true end
    if string.find(name, "medico") or string.find(name, "médico") then return "medico", true end
    if string.find(name, "ingeniero") then return "ingeniero", true end
    if string.find(name, "francotirador") or string.find(name, "sniper") then return "francotirador", true end
    if string.find(name, "pesado") then return "pesado", true end
    
    return cmd, false
end

local plyMeta = FindMetaTable("Player")

function plyMeta:GetXP()
    return self:GetNWInt("IVO_XP", 0)
end

function plyMeta:GetLevel()
    return self:GetNWInt("IVO_Level", 1)
end

-- Función auxiliar para calcular cuánta XP se requiere para avanzar al siguiente nivel
function IVO_SAM.GetXPNeededForLevel(level)
    local baseXP = 500
    local multiplier = 500
    
    return math.floor((level ^ 1) * multiplier + baseXP)
end

-- Curva de XP específica para Jobs (Un poco más rápida que la general)
function IVO_SAM.GetJobXPNeededForLevel(level)
    return math.floor((level ^ 0.8) * 300 + 200)
end

function plyMeta:GetJobXP(jobCmd)
    if not jobCmd then return 0 end
    return self:GetNWInt("IVO_JobXP_" .. jobCmd, 0)
end

function plyMeta:GetJobLevel(jobCmd)
    if not jobCmd then return 1 end
    return self:GetNWInt("IVO_JobLevel_" .. jobCmd, 1)
end

function plyMeta:GetJobPlaytime(jobCmd)
    if not jobCmd then return 0 end
    return self:GetNWInt("IVO_JobTime_" .. jobCmd, 0)
end
