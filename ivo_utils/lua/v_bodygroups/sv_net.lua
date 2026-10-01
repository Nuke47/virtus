-- Servidor: sv_net.lua (Soporte nativo para carga masiva de Presets)
if not SERVER then return end

net.Receive("v_bodygroups_Update", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end

    local updateType = net.ReadString()
    local index = net.ReadInt(8)
    local value = net.ReadInt(8)
    local expectedModel = net.ReadString()
    
    local jsonRaw = nil
    if updateType == "preset" then
        jsonRaw = net.ReadString()
    end

    -- =========================================================================
    -- PREVENCIÓN DE RACE CONDITION (Contaminación Cruzada de Modelos)
    -- Si el jugador envió este paquete pero el servidor ya le cambió el modelo 
    -- (por la Physgun Admin o Jobs), ignoramos el paquete para no bugear la ropa.
    -- =========================================================================
    if expectedModel and expectedModel ~= "" and updateType ~= "model" then
        if string.lower(ply:GetModel()) ~= string.lower(expectedModel) then return end
    end

    -- ACCIÓN ESPECIAL: Carga masiva de preset saltando el flood de red
    if updateType == "preset" then
        if not jsonRaw or jsonRaw == "" then return end

        local outfit = util.JSONToTable(jsonRaw)
        if outfit then
            -- 1. Aplicar la skin texturizada
            if outfit.skin and outfit.skin >= 0 and outfit.skin < ply:SkinCount() then
                ply:SetSkin(outfit.skin)
                ply.v_SavedSkinsCache = outfit.skin
            end

            -- 2. Aplicar todos los bodygroups juntos en el mismo frame
            ply.v_SavedBGsCache = ply.v_SavedBGsCache or {}
            if outfit.bgs then
                for bgID, val in pairs(outfit.bgs) do
                    local bgNum = tonumber(bgID)
                    local valNum = tonumber(val)

                    if bgNum and valNum and bgNum >= 0 and bgNum < ply:GetNumBodyGroups() then
                        local maxBGs = ply:GetBodygroupCount(bgNum)
                        if valNum >= 0 and valNum < maxBGs then
                            local isLocked = false
                            if SW_InvShop and SW_InvShop.HasBodygroupAccess then
                                local bgName = ply:GetBodygroupName(bgNum)
                                local subName = ""
                                for _, bg in pairs(ply:GetBodyGroups() or {}) do
                                    if bg.id == bgNum then
                                        subName = bg.submodels and bg.submodels[valNum] or ""
                                        break
                                    end
                                end
                                if not SW_InvShop.HasBodygroupAccess(ply, bgName, subName) then
                                    isLocked = true
                                end
                            end
                            
                            if not isLocked then
                                ply:SetBodygroup(bgNum, valNum)
                                ply.v_SavedBGsCache[bgNum] = valNum
                            end
                        end
                    end
                end
            end

            -- Guardado de datos nativos si aplica
            if v_bodygroups and type(v_bodygroups.SavePlayerBodygroups) == "function" then
                v_bodygroups.SavePlayerBodygroups(ply)
            end
        end
        return -- Terminamos la ejecución temprano de forma segura
    end

    -- Control anti-exploit estándar (Solo para clicks individuales de botones < y >)
    ply.v_BGFloodTick = ply.v_BGFloodTick or 0
    if CurTime() < ply.v_BGFloodTick then return end
    ply.v_BGFloodTick = CurTime() + 0.1

    -- CAMBIO DE MODELO INTEGRADO CON DARKRP
    if updateType == "model" then
        if ply.getJobTable and ply:getJobTable() then
            local jobModels = ply:getJobTable().model
            if type(jobModels) == "table" then
                local newMdl = jobModels[index]
                if newMdl then
                    ply:SetModel(newMdl)
                end
            end
        end
        return -- Terminamos la ejecución temprano
    end

    if updateType == "skin" then
        if value >= 0 and value < ply:SkinCount() then
            ply:SetSkin(value)
            ply.v_SavedSkinsCache = value
        end
    elseif updateType == "bodygroup" then
        if index >= 0 and index < ply:GetNumBodyGroups() then
            local maxBGs = ply:GetBodygroupCount(index)
            if value >= 0 and value < maxBGs then
                -- ENFORCE STORE LOCKS
                local isLocked = false
                if SW_InvShop and SW_InvShop.HasBodygroupAccess then
                    local bgName = ply:GetBodygroupName(index)
                    local subName = ""
                    for _, bg in pairs(ply:GetBodyGroups() or {}) do
                        if bg.id == index then
                            subName = bg.submodels and bg.submodels[value] or ""
                            break
                        end
                    end
                    if not SW_InvShop.HasBodygroupAccess(ply, bgName, subName) then
                        isLocked = true
                    end
                end

                if not isLocked then
                    ply:SetBodygroup(index, value)
                    ply.v_SavedBGsCache = ply.v_SavedBGsCache or {}
                    ply.v_SavedBGsCache[index] = value
                end
            end
        end
    end

    if v_bodygroups and type(v_bodygroups.SavePlayerBodygroups) == "function" then
        v_bodygroups.SavePlayerBodygroups(ply)
    end
end)

hook.Add("PlayerSpawn", "v_bodygroups_PersistSpawn", function(ply)
    timer.Simple(0.2, function()
        if not IsValid(ply) then return end
        
        if ply.v_SavedSkinsCache then
            ply:SetSkin(ply.v_SavedSkinsCache)
        end
        
        if ply.v_SavedBGsCache then
            for index, value in pairs(ply.v_SavedBGsCache) do
                local isLocked = false
                if SW_InvShop and SW_InvShop.HasBodygroupAccess then
                    local bgName = ply:GetBodygroupName(index)
                    local subName = ""
                    for _, bg in pairs(ply:GetBodyGroups() or {}) do
                        if bg.id == index then
                            subName = bg.submodels and bg.submodels[value] or ""
                            break
                        end
                    end
                    if not SW_InvShop.HasBodygroupAccess(ply, bgName, subName) then
                        isLocked = true
                    end
                end

                if not isLocked then
                    ply:SetBodygroup(index, value)
                else
                    ply.v_SavedBGsCache[index] = 0 -- Reset cache if no longer authorized
                end
            end
        end
    end)
end)