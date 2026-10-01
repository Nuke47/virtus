-- Usa la base de datos de ivosam
hook.Add("IVOSAM_DatabaseConnected", "IVO_Habilities_InitDB", function()
    -- points es un JSON que guarda { "general": 5, "ARC": 2, "ASALTO": 1 }
    -- skills es un JSON array de skills desbloqueadas
    local q = "CREATE TABLE IF NOT EXISTS ivo_habilities_data (steamid64 VARCHAR(64) PRIMARY KEY, points TEXT, skills TEXT);"
    IVO_SAM.DB.Query(q, function()
        print("[IVO HABILITIES] Tabla SQL verificada.")
    end)
end)

function IVO_HABILITIES.LoadPlayer(ply)
    if not IsValid(ply) or ply:IsBot() then return end
    local sid64 = ply:SteamID64()
    
    IVO_SAM.DB.QueryRow(string.format("SELECT * FROM ivo_habilities_data WHERE steamid64 = %s;", IVO_SAM.DB.Escape(sid64)), function(res)
        if not IsValid(ply) then return end
        
        ply.IVO_Habilities = ply.IVO_Habilities or {}
        
        if res then
            ply.IVO_Habilities.points = util.JSONToTable(res.points or "{}") or {}
            ply.IVO_Habilities.skills = util.JSONToTable(res.skills or "[]") or {}
        else
            ply.IVO_Habilities.points = {}
            ply.IVO_Habilities.skills = {}
            IVO_HABILITIES.SavePlayer(ply)
        end
        
        -- Cálculo retroactivo de puntos (espera a que ivosam cargue sus NWInts)
        local retryName = "IVO_Hab_Recalc_" .. ply:SteamID64()
        local retries = 0
        timer.Create(retryName, 3, 10, function()
            retries = retries + 1
            if not IsValid(ply) or not ply.IVO_Habilities then timer.Remove(retryName) return end
            
            local generalLvl = ply:GetNWInt("IVO_Level", 1)
            -- Si ivosam aún no cargó los datos, el nivel será 1. Esperamos un poco más.
            if generalLvl <= 1 and retries < 5 then return end
            
            local dirty = false
            
            -- Generales
            local expectedGen = math.max(0, generalLvl - 1)
            local spentGen = 0
            for _, sId in ipairs(ply.IVO_Habilities.skills) do
                local sData = IVO_HABILITIES.SkillsList[sId]
                if sData and sData.type == "general" then spentGen = spentGen + sData.cost end
            end
            local currentGen = ply.IVO_Habilities.points["general"] or 0
            if (currentGen + spentGen) < expectedGen then
                ply.IVO_Habilities.points["general"] = expectedGen - spentGen
                dirty = true
            end
            
            -- Especialidades
            local specs = {"arc", "asalto", "reconocimiento", "ingeniero", "medico", "pesado", "piloto", "francotirador", "apoyo"}
            for _, spec in ipairs(specs) do
                local specLvl = ply:GetNWInt("IVO_JobLevel_" .. spec, 1)
                local expectedSpec = math.max(0, specLvl - 1)
                local spentSpec = 0
                for _, sId in ipairs(ply.IVO_Habilities.skills) do
                    local sData = IVO_HABILITIES.SkillsList[sId]
                    if sData and sData.type == spec then spentSpec = spentSpec + sData.cost end
                end
                local currentSpec = ply.IVO_Habilities.points[spec] or 0
                if (currentSpec + spentSpec) < expectedSpec then
                    ply.IVO_Habilities.points[spec] = expectedSpec - spentSpec
                    dirty = true
                end
            end
            
            if dirty then
                IVO_HABILITIES.SavePlayer(ply)
            end
            IVO_HABILITIES.SyncPlayer(ply)
            timer.Remove(retryName)
        end)
        
        -- Sincronizar con el cliente
        IVO_HABILITIES.SyncPlayer(ply)
        
        -- Aplicar habilidades pasivas
        IVO_HABILITIES.ApplySkills(ply)
    end)
end

function IVO_HABILITIES.SavePlayer(ply)
    if not IsValid(ply) or ply:IsBot() then return end
    local sid64 = ply:SteamID64()
    
    if not ply.IVO_Habilities then return end
    
    local p_json = util.TableToJSON(ply.IVO_Habilities.points)
    local s_json = util.TableToJSON(ply.IVO_Habilities.skills)
    
    IVO_SAM.DB.Query(string.format(
        "REPLACE INTO ivo_habilities_data (steamid64, points, skills) VALUES (%s, %s, %s);",
        IVO_SAM.DB.Escape(sid64), IVO_SAM.DB.Escape(p_json), IVO_SAM.DB.Escape(s_json)
    ))
end

hook.Add("PlayerInitialSpawn", "IVO_Habilities_Load", function(ply)
    -- Esperar a que conecte ivosam
    timer.Simple(2, function()
        if IsValid(ply) then
            IVO_HABILITIES.LoadPlayer(ply)
        end
    end)
end)

hook.Add("PlayerDisconnected", "IVO_Habilities_Save", function(ply)
    IVO_HABILITIES.SavePlayer(ply)
end)
