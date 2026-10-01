-- Sincroniza todos los datos al cliente
function IVO_HABILITIES.SyncPlayer(ply)
    if not ply.IVO_Habilities then return end
    net.Start("IVO_Habilities_Sync")
        net.WriteTable(ply.IVO_Habilities.points)
        net.WriteTable(ply.IVO_Habilities.skills)
    net.Send(ply)
end

function IVO_HABILITIES.HasSkill(ply, skillID)
    if not ply.IVO_Habilities then return false end
    for _, v in ipairs(ply.IVO_Habilities.skills) do
        if v == skillID then return true end
    end
    return false
end

-- Añade puntos (general o especialidad)
function IVO_HABILITIES.AddPoint(ply, category, amount)
    if not ply.IVO_Habilities then return end
    ply.IVO_Habilities.points[category] = (ply.IVO_Habilities.points[category] or 0) + amount
    IVO_HABILITIES.SavePlayer(ply)
    IVO_HABILITIES.SyncPlayer(ply)
end

-- Hook cuando subes de nivel general (da un punto general)
hook.Add("IVOSAM_LevelUp", "IVO_Habilities_GlobalLevel", function(ply, newLevel)
    IVO_HABILITIES.AddPoint(ply, "general", 1)
end)

-- Hook cuando subes de nivel de trabajo/especialidad (da un punto de especialidad)
hook.Add("IVOSAM_JobLevelUp", "IVO_Habilities_JobLevel", function(ply, jobName, newLevel)
    IVO_HABILITIES.AddPoint(ply, jobName, 1)
end)

-- Aplica efectos de las habilidades (como la velocidad)
function IVO_HABILITIES.ApplySkills(ply)
    if not IsValid(ply) then return end
    
    -- Reset default stats antes de aplicar buffs
    local walk = 160
    local run = 240
    
    if IVO_HABILITIES.HasSkill(ply, "gen_speed_2") then
        walk = walk * 1.10
        run = run * 1.10
    elseif IVO_HABILITIES.HasSkill(ply, "gen_speed_1") then
        walk = walk * 1.05
        run = run * 1.05
    end
    
    ply:SetWalkSpeed(walk)
    ply:SetRunSpeed(run)
    
    -- Stamina max logic in sv_stamina.lua will read from skills
end

hook.Add("PlayerSpawn", "IVO_Habilities_ApplyOnSpawn", function(ply)
    timer.Simple(0.1, function()
        if IsValid(ply) then
            IVO_HABILITIES.ApplySkills(ply)
        end
    end)
end)

net.Receive("IVO_Habilities_Unlock", function(len, ply)
    local skillID = net.ReadString()
    
    if not ply.IVO_Habilities then return end
    
    local skillData = IVO_HABILITIES.SkillsList[skillID]
    if not skillData then return end
    
    if IVO_HABILITIES.HasSkill(ply, skillID) then return end
    
    -- Chequea prerrequisito
    if skillData.req and not IVO_HABILITIES.HasSkill(ply, skillData.req) then return end
    
    local cat = skillData.type
    local pts = ply.IVO_Habilities.points[cat] or 0
    
    if pts >= skillData.cost then
        ply.IVO_Habilities.points[cat] = pts - skillData.cost
        table.insert(ply.IVO_Habilities.skills, skillID)
        
        IVO_HABILITIES.SavePlayer(ply)
        IVO_HABILITIES.SyncPlayer(ply)
        IVO_HABILITIES.ApplySkills(ply)
        
        ply:ChatPrint("[PROGRESO] Habilidad desbloqueada: " .. skillData.name)
        ply:SendLua([[surface.PlaySound("garrysmod/save_load1.wav")]])
    else
        ply:ChatPrint("[PROGRESO] No tienes suficientes puntos (" .. cat .. ").")
    end
end)
