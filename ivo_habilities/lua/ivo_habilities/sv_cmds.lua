concommand.Add("ivo_recalc_points", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    
    local target = ply
    if args[1] then
        for _, p in ipairs(player.GetAll()) do
            if string.find(string.lower(p:Nick()), string.lower(args[1])) then
                target = p
                break
            end
        end
    end
    
    if not IsValid(target) or not target.IVO_Habilities then return end
    
    local dirty = false
    
    -- Generales
    local generalLvl = target:GetNWInt("IVO_Level", 1)
    local expectedGen = math.max(0, generalLvl - 1)
    local spentGen = 0
    for _, sId in ipairs(target.IVO_Habilities.skills) do
        local sData = IVO_HABILITIES.SkillsList[sId]
        if sData and sData.type == "general" then spentGen = spentGen + sData.cost end
    end
    local currentGen = target.IVO_Habilities.points["general"] or 0
    if (currentGen + spentGen) < expectedGen then
        target.IVO_Habilities.points["general"] = expectedGen - spentGen
        dirty = true
    end
    
    -- Especialidades
    local specs = {"arc", "asalto", "reconocimiento", "ingeniero", "medico", "pesado", "piloto", "francotirador", "apoyo"}
    for _, spec in ipairs(specs) do
        local specLvl = target:GetNWInt("IVO_JobLevel_" .. spec, 1)
        local expectedSpec = math.max(0, specLvl - 1)
        local spentSpec = 0
        for _, sId in ipairs(target.IVO_Habilities.skills) do
            local sData = IVO_HABILITIES.SkillsList[sId]
            if sData and sData.type == spec then spentSpec = spentSpec + sData.cost end
        end
        local currentSpec = target.IVO_Habilities.points[spec] or 0
        if (currentSpec + spentSpec) < expectedSpec then
            target.IVO_Habilities.points[spec] = expectedSpec - spentSpec
            dirty = true
        end
    end
    
    if dirty then
        IVO_HABILITIES.SavePlayer(target)
        IVO_HABILITIES.SyncPlayer(target)
        if IsValid(ply) then ply:ChatPrint("Puntos recalculados y actualizados para " .. target:Nick()) end
    else
        if IsValid(ply) then ply:ChatPrint(target:Nick() .. " ya tiene sus puntos al dia.") end
    end
end)
