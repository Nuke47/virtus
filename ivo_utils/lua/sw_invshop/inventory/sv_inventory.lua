SW_InvShop = SW_InvShop or {}

util.AddNetworkString("SW_OpenArmarioMenu")
util.AddNetworkString("SW_OpenShopMenu")
util.AddNetworkString("SW_OpenBlackMarketMenu")
util.AddNetworkString("SW_OpenAmmoShopMenu")
util.AddNetworkString("SW_SyncData")
util.AddNetworkString("SW_MoveItem")
util.AddNetworkString("SW_BuyItem")
util.AddNetworkString("SW_SellItem")

-- ============================================================================
-- INICIALIZACION DE LA BASE DE DATOS SQL (SQLite NATIVO)
-- ============================================================================
local function CreateSQLTables()
    if not IVO_SAM or not IVO_SAM.DB then return end
    IVO_SAM.DB.Query("CREATE TABLE IF NOT EXISTS sw_inventory_armario (steamid VARCHAR(40), item_id VARCHAR(60), quantity INT, PRIMARY KEY(steamid, item_id))")
    IVO_SAM.DB.Query("CREATE TABLE IF NOT EXISTS sw_inv_loadouts_spec (steamid VARCHAR(40), specialty VARCHAR(60), item_id VARCHAR(60), quantity INT, PRIMARY KEY(steamid, specialty, item_id))")
    IVO_SAM.DB.Query("CREATE TABLE IF NOT EXISTS sw_inv_starters_spec (steamid VARCHAR(40), specialty VARCHAR(60), PRIMARY KEY(steamid, specialty))")
    print("[SW_InvShop] MySQL Tables verified/created successfully via IVOSAM.")
end

hook.Add("IVOSAM_DatabaseConnected", "SW_Inv_InitDatabase", CreateSQLTables)

-- En caso de que se recargue el script o el hook ya haya pasado:
timer.Simple(1, function()
    if IVO_SAM and IVO_SAM.DB and IVO_SAM.DB.Query then
        CreateSQLTables()
    end
end)

-- ============================================================================
-- NUEVO SISTEMA: DETECTOR DE CATEGORIAS/ESPECIALIDADES
-- ============================================================================
function SW_InvShop.GetJobSpecialty(teamID)
    -- Escanea todas las categorias legales
    for catName, catConfig in pairs(SW_InvShop.Config.Categories or {}) do
        if catConfig.allowedJobs then
            for _, jobIdentifier in pairs(catConfig.allowedJobs) do
                local requiredID = type(jobIdentifier) == "string" and _G[jobIdentifier] or jobIdentifier
                if requiredID and teamID == requiredID then return catName end
            end
        end
    end
    
    -- Escanea las categorias del mercado negro
    for catName, catConfig in pairs(SW_InvShop.Config.BMCategories or {}) do
        if catConfig.allowedJobs then
            for _, jobIdentifier in pairs(catConfig.allowedJobs) do
                local requiredID = type(jobIdentifier) == "string" and _G[jobIdentifier] or jobIdentifier
                if requiredID and teamID == requiredID then return catName end
            end
        end
    end
    
    -- Si el job no pertenece a ninguna categoria grupal, se le asigna una individual
    local jobName = team.GetName(teamID)
    if jobName and jobName ~= "" then
        return jobName
    end
    return "JOB_" .. tostring(teamID)
end

-- ============================================================================
-- FUNCIONES HELPER: GUARDADO Y CARGA SQL
-- ============================================================================
function SW_InvShop.LoadPlayerData(ply)
    if not IsValid(ply) then return end
    local sid = "'" .. ply:SteamID() .. "'"
    
    ply.SW_Data = { 
        active = {}, 
        armario = {},
        receivedStarter = {}, 
        savedLoadouts = {}    
    } 
    ply.SW_LoadedSpecialties = {}

    -- Usando MySQL async
    IVO_SAM.DB.Query("SELECT item_id, quantity FROM sw_inventory_armario WHERE steamid = " .. sid, function(resArmario)
        if not IsValid(ply) then return end
        if resArmario then
            for _, row in ipairs(resArmario) do
                ply.SW_Data.armario[row.item_id] = tonumber(row.quantity) or 1 
            end
        end

        IVO_SAM.DB.Query("SELECT specialty, item_id, quantity FROM sw_inv_loadouts_spec WHERE steamid = " .. sid, function(resLoadouts)
            if not IsValid(ply) then return end
            if resLoadouts then
                for _, row in ipairs(resLoadouts) do
                    local spec = row.specialty
                    ply.SW_Data.savedLoadouts[spec] = ply.SW_Data.savedLoadouts[spec] or {}
                    ply.SW_Data.savedLoadouts[spec][row.item_id] = tonumber(row.quantity) or 1 
                end
            end

            IVO_SAM.DB.Query("SELECT specialty FROM sw_inv_starters_spec WHERE steamid = " .. sid, function(resStarters)
                if not IsValid(ply) then return end
                if resStarters then
                    for _, row in ipairs(resStarters) do
                        ply.SW_Data.receivedStarter[row.specialty] = true
                    end
                end
                
                -- Una vez cargado todo de MySQL, marcamos flag y le damos las armas
                ply.SW_DataLoaded = true
                
                local spec = SW_InvShop.GetJobSpecialty(ply:Team())
                if ply.SW_Data.savedLoadouts[spec] then
                    ply.SW_Data.active = table.Copy(ply.SW_Data.savedLoadouts[spec])
                else
                    ply.SW_Data.active = {}
                end

                SW_InvShop.SyncPlayerData(ply)
                SW_InvShop.ApplyLoadout(ply)
            end)
        end)
    end)
end

function SW_InvShop.SaveArmarioToDB(ply)
    if not ply.SW_Data or not ply.SW_Data.armario then return end
    if not IVO_SAM or not IVO_SAM.DB or not IVO_SAM.DB.Connection then 
        print("[SW_InvShop] ERROR: Cannot save armario - DB not connected!")
        return 
    end
    local sid = "'" .. ply:SteamID() .. "'"
    
    local armarioCopy = table.Copy(ply.SW_Data.armario)
    IVO_SAM.DB.Query("DELETE FROM sw_inventory_armario WHERE steamid = " .. sid, function()
        if not IVO_SAM or not IVO_SAM.DB or not IVO_SAM.DB.Connection then return end
        for itemID, qty in pairs(armarioCopy) do
            if qty and qty > 0 then
                local safeID = "'" .. IVO_SAM.DB.Connection:escape(itemID) .. "'"
                IVO_SAM.DB.Query("INSERT INTO sw_inventory_armario (steamid, item_id, quantity) VALUES ("..sid..", "..safeID..", "..qty..")")
            end
        end
    end)
end

function SW_InvShop.SaveLoadoutToDB(ply, specialty)
    if not ply.SW_Data or not ply.SW_Data.savedLoadouts[specialty] then return end
    if not IVO_SAM or not IVO_SAM.DB or not IVO_SAM.DB.Connection then 
        print("[SW_InvShop] ERROR: Cannot save loadout - DB not connected!")
        return 
    end
    local sid = "'" .. ply:SteamID() .. "'"
    local safeSpec = "'" .. IVO_SAM.DB.Connection:escape(specialty) .. "'"
    
    local loadoutCopy = table.Copy(ply.SW_Data.savedLoadouts[specialty])
    IVO_SAM.DB.Query("DELETE FROM sw_inv_loadouts_spec WHERE steamid = " .. sid .. " AND specialty = " .. safeSpec, function()
        if not IVO_SAM or not IVO_SAM.DB or not IVO_SAM.DB.Connection then return end
        for itemID, qty in pairs(loadoutCopy) do
            if qty and qty > 0 then
                local safeID = "'" .. IVO_SAM.DB.Connection:escape(itemID) .. "'"
                IVO_SAM.DB.Query("INSERT INTO sw_inv_loadouts_spec (steamid, specialty, item_id, quantity) VALUES ("..sid..", "..safeSpec..", "..safeID..", "..qty..")")
            end
        end
    end)
end

function SW_InvShop.SaveCurrentActiveAsLoadoutToDB(ply)
    if not ply.SW_Data or not ply.SW_Data.active then return end
    local spec = SW_InvShop.GetJobSpecialty(ply:Team())
    
    ply.SW_Data.savedLoadouts[spec] = table.Copy(ply.SW_Data.active)
    SW_InvShop.SaveLoadoutToDB(ply, spec)
end

function SW_InvShop.SaveStarterFlagToDB(ply, specialty)
    if not ply.SW_Data then return end
    ply.SW_Data.receivedStarter[specialty] = true
    local sid = "'" .. ply:SteamID() .. "'"
    local safeSpec = "'" .. IVO_SAM.DB.Connection:escape(specialty) .. "'"
    IVO_SAM.DB.Query("REPLACE INTO sw_inv_starters_spec (steamid, specialty) VALUES ("..sid..", "..safeSpec..")")
end

hook.Add("PlayerInitialSpawn", "SW_Inv_LoadPlayer", function(ply)
    SW_InvShop.LoadPlayerData(ply)
end)

function SW_InvShop.SyncPlayerData(ply)
    if not ply.SW_Data then return end
    net.Start("SW_SyncData")
        net.WriteTable(ply.SW_Data.active)
        net.WriteTable(ply.SW_Data.armario)
        net.WriteTable(ply.SW_Data.savedLoadouts or {})
    net.Send(ply)
end

-- ============================================================================
-- LOGICA DE BANDOS Y PERMISOS
-- ============================================================================
local function IsPlayerRightSide(ply, itemData)
    if not SW_InvShop.Config.UnderworldJobs then return true end
    local isUnderworld = false
    local myTeam = ply:Team()
    
    for _, jobIdentifier in pairs(SW_InvShop.Config.UnderworldJobs) do
        local requiredID = type(jobIdentifier) == "string" and _G[jobIdentifier] or jobIdentifier
        if requiredID and myTeam == requiredID then isUnderworld = true break end
    end
    
    if itemData.isContraband and not isUnderworld then return false end
    if not itemData.isContraband and isUnderworld then return false end
    return true
end

local function CanPlayerUseItem(ply, itemID)
    local itemData = SW_InvShop.Config.Items[itemID]
    if not itemData or not itemData.category then return true end
    if not IsPlayerRightSide(ply, itemData) then return false end

    -- 0. Check Level Restrictions (IVOSAM)
    local reqLevel = itemData.levelReq or 0
    if reqLevel == 0 then
        local catConfigLevel = nil
        if itemData.isContraband then 
            catConfigLevel = SW_InvShop.Config.BMCategories[itemData.category]
        elseif itemData.isAmmo then 
            catConfigLevel = SW_InvShop.Config.AmmoCategories[itemData.category]
        else 
            catConfigLevel = SW_InvShop.Config.Categories[itemData.category]
        end
        if catConfigLevel and catConfigLevel.levelReq then
            reqLevel = catConfigLevel.levelReq
        end
    end
    
    if reqLevel > 0 then
        local plyLevel = ply.GetLevel and ply:GetLevel() or 1
        if plyLevel < reqLevel then return false end
    end

    local myJobNum = ply:Team()
    local myJobName = string.lower(team.GetName(myJobNum) or "")

    -- 1. Check Item-Level Restrictions (Overrides Category)
    local itemHasJobs = (itemData.allowedJobs and table.Count(itemData.allowedJobs) > 0)
    local itemHasKeywords = (itemData.allowedKeywords and table.Count(itemData.allowedKeywords) > 0)

    if itemHasJobs or itemHasKeywords then
        local allowed = false
        if itemHasJobs then
            for _, jobIdentifier in pairs(itemData.allowedJobs) do
                local requiredID = type(jobIdentifier) == "string" and _G[jobIdentifier] or jobIdentifier
                if requiredID and myJobNum == requiredID then allowed = true break end
            end
        end
        if not allowed and itemHasKeywords then
            for _, keyword in pairs(itemData.allowedKeywords) do
                if string.find(myJobName, string.lower(keyword)) then
                    allowed = true
                    break
                end
            end
        end
        if not allowed then return false end
    end

    -- 2. Check Category-Level Restrictions
    local catConfig = SW_InvShop.Config.Categories[itemData.category]
    if itemData.isContraband then catConfig = SW_InvShop.Config.BMCategories[itemData.category] end
    if itemData.isAmmo then catConfig = SW_InvShop.Config.AmmoCategories[itemData.category] end
    if not catConfig then return true end

    local catHasJobs = (catConfig.allowedJobs and table.Count(catConfig.allowedJobs) > 0)
    local catHasKeywords = (catConfig.allowedKeywords and table.Count(catConfig.allowedKeywords) > 0)
    
    if not catHasJobs and not catHasKeywords then return true end
    
    if catHasJobs then
        for _, jobIdentifier in pairs(catConfig.allowedJobs) do
            local requiredID = type(jobIdentifier) == "string" and _G[jobIdentifier] or jobIdentifier
            if requiredID and myJobNum == requiredID then return true end
        end
    end
    
    if catHasKeywords then
        for _, keyword in pairs(catConfig.allowedKeywords) do
            if string.find(myJobName, string.lower(keyword)) then
                return true
            end
        end
    end
    
    return false
end

local function GiveWeaponPhysically(ply, class)
    if not IsValid(ply) or not ply:Alive() then return end
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        ply:Give(class)
        timer.Simple(0.1, function()
            if IsValid(ply) and ply:HasWeapon(class) then ply:SelectWeapon(class) end
        end)
    end)
end

function SW_InvShop.GiveActiveWeapons(ply)
    if not IsValid(ply) or not ply:Alive() or not ply.SW_Data or not ply.SW_Data.active then return end
    
    if ply:GetNWBool("InTutorial") or string.lower(team.GetName(ply:Team()) or "") == "cadete" then
        return
    end
    
    for itemID, qty in pairs(ply.SW_Data.active) do
        local itemData = SW_InvShop.Config.Items[itemID]
        if itemData and CanPlayerUseItem(ply, itemID) then
            if itemData.isWeapon and itemData.class then 
                if not ply:HasWeapon(itemData.class) then
                    ply:Give(itemData.class)
                end
            elseif itemData.isAmmo and itemData.ammoType then
                local amountToGive = (itemData.ammoCount or 1) * (qty or 1)
                ply:GiveAmmo(amountToGive, itemData.ammoType, true)
            end
        end
    end
end

local function CheckAndClearUnauthorizedSlots(ply)
    if not IsValid(ply) or not ply.SW_Data or not ply.SW_Data.active then return false end
    
    local jobTable = RPExtraTeams and RPExtraTeams[ply:Team()]
    local jobWeapons = {}
    if jobTable and jobTable.weapons then
        for _, w in ipairs(jobTable.weapons) do
            jobWeapons[w] = true
        end
    end

    local changed = false
    for itemID, _ in pairs(ply.SW_Data.active) do
        if not CanPlayerUseItem(ply, itemID) then
            local itemData = SW_InvShop.Config.Items[itemID]
            if itemData and itemData.class and not jobWeapons[itemData.class] then 
                ply:StripWeapon(itemData.class) 
            end
            
            ply.SW_Data.armario[itemID] = 1 
            ply.SW_Data.active[itemID] = nil
            changed = true
        end
    end
    return changed
end

local function GetStarterLoadout(teamNum)
    local starter = {}
    
    if SW_InvShop.Config.StarterLoadouts then
        local specialty = string.lower(SW_InvShop.GetJobSpecialty(teamNum) or "")
        local jobName = string.lower(team.GetName(teamNum) or "")
        for key, items in pairs(SW_InvShop.Config.StarterLoadouts) do
            local lKey = string.lower(key)
            if _G[key] == teamNum or lKey == specialty or lKey == jobName or string.find(jobName, lKey) then 
                for _, itemID in ipairs(items) do
                    if not table.HasValue(starter, itemID) then table.insert(starter, itemID) end
                end
            end
        end
    end
    
    local jobTable = RPExtraTeams and RPExtraTeams[teamNum]
    if jobTable and jobTable.weapons then
        for _, wepClass in ipairs(jobTable.weapons) do
            local foundItemID = nil
            for itemID, itemData in pairs(SW_InvShop.Config.Items) do
                if itemData.class == wepClass then
                    if itemData.isBaseItem then
                        foundItemID = itemID
                        break
                    elseif not foundItemID then
                        foundItemID = itemID
                    end
                end
            end
            if foundItemID and not table.HasValue(starter, foundItemID) then
                table.insert(starter, foundItemID)
            end
        end
    end
    
    if #starter > 0 then return starter end
    return nil
end

local function GetPlayerActiveSlotCounts(ply)
    local counts = { [1] = 0, [2] = 0, [3] = 0, [4] = 0 }
    if ply.SW_Data and ply.SW_Data.active then
        for itemID, _ in pairs(ply.SW_Data.active) do
            local stype = SW_InvShop.GetItemSlot(itemID)
            counts[stype] = counts[stype] + 1
        end
    end
    return counts
end

local function DistributeStarterItems(ply, starter)
    for _, itemID in ipairs(starter) do
        if SW_InvShop.Config.Items[itemID] then
            local hasActive = ply.SW_Data.active[itemID]
            local hasArmario = ply.SW_Data.armario[itemID]
            
            if not hasActive then
                local stype = SW_InvShop.GetItemSlot(itemID)
                local counts = GetPlayerActiveSlotCounts(ply)
                local totalSlots = table.Count(ply.SW_Data.active)
                
                local canEquip = false
                if stype <= 3 then
                    if counts[stype] == 0 and totalSlots < SW_InvShop.Config.MaxActiveSlots then
                        canEquip = true
                    end
                else
                    if totalSlots < SW_InvShop.Config.MaxActiveSlots then
                        canEquip = true
                    end
                end

                if canEquip then
                    ply.SW_Data.active[itemID] = 1
                    if hasArmario then
                        ply.SW_Data.armario[itemID] = nil
                    end
                elseif not hasArmario then
                    ply.SW_Data.armario[itemID] = 1
                end
            end
        end
    end
end

-- ============================================================================
-- SPAWN Y CAMBIO DE TRABAJOS (CONTROL POR CATEGORIAS/ESPECIALIDAD)
-- ============================================================================
local function StripUnequippedWeapons(ply)
    timer.Simple(0.5, function()
        if not IsValid(ply) or not ply.SW_Data then return end
        local jobTable = RPExtraTeams and RPExtraTeams[ply:Team()]
        local jobWeapons = {}
        if jobTable and jobTable.weapons then
            for _, w in ipairs(jobTable.weapons) do
                jobWeapons[string.lower(w)] = true
            end
        end

        for _, wep in ipairs(ply:GetWeapons()) do
            local class = string.lower(wep:GetClass())
            
            if jobWeapons[class] then continue end
            
            local isInvItem = false
            local isEquipped = false
            for itemID, itemData in pairs(SW_InvShop.Config.Items) do
                if itemData.class == class then
                    isInvItem = true
                    if ply.SW_Data.active[itemID] then
                        isEquipped = true
                    end
                end
            end
            if isInvItem and not isEquipped then
                ply:StripWeapon(class)
            end
        end
    end)
end

function SW_InvShop.ApplyLoadout(ply)
    if ply:GetNWBool("InTutorial") or string.lower(team.GetName(ply:Team()) or "") == "cadete" then
        return
    end
    SW_InvShop.EnforceActiveBodygroups(ply)
    timer.Simple(0.5, function()
        if not IsValid(ply) or not ply.SW_Data then return end
        
        -- PARCHE DE SEGURIDAD: Evita errores si se recarga el script en vivo
        ply.SW_LoadedSpecialties = ply.SW_LoadedSpecialties or {}
        
        local myTeam = ply:Team()
        if myTeam == 0 or myTeam == 1 then return end 
        
        local mySpecialty = SW_InvShop.GetJobSpecialty(myTeam)
        local databaseChanged = false
        
        if not ply.SW_LoadedSpecialties[mySpecialty] then
            ply.SW_LoadedSpecialties[mySpecialty] = true
            if ply.SW_Data.savedLoadouts[mySpecialty] then
                ply.SW_Data.active = table.Copy(ply.SW_Data.savedLoadouts[mySpecialty])
            end
            
            if not ply.SW_Data.receivedStarter[mySpecialty] then
                local starter = GetStarterLoadout(myTeam)
                if starter then
                    ply.SW_Data.receivedStarter[mySpecialty] = true
                    SW_InvShop.SaveStarterFlagToDB(ply, mySpecialty)
                    
                    DistributeStarterItems(ply, starter)
                    -- ply:ChatPrint("[Inventario] Has recibido tu equipamiento estandar de esta especialidad.")
                end
            end
            databaseChanged = true
        end
        
        if CheckAndClearUnauthorizedSlots(ply) then
            databaseChanged = true
        end

        if databaseChanged then
            SW_InvShop.SaveCurrentActiveAsLoadoutToDB(ply)
            SW_InvShop.SaveArmarioToDB(ply)
        end
        
        SW_InvShop.SyncPlayerData(ply)
        SW_InvShop.GiveActiveWeapons(ply)
        SW_InvShop.EnforceActiveBodygroups(ply)
        
        local sid = ply:SteamID64()
        if sid then
            timer.Create("SW_BGApply_" .. sid, 1.5, 10, function()
                if IsValid(ply) and SW_InvShop and SW_InvShop.EnforceActiveBodygroups then
                    SW_InvShop.EnforceActiveBodygroups(ply)
                end
            end)
        end
    end)
end
hook.Add("PlayerSpawn", "SW_Inv_ApplyLoadout", SW_InvShop.ApplyLoadout)

hook.Add("OnPlayerChangedTeam", "SW_Inv_OnJobChange", function(ply, oldTeam, newTeam)
    if not ply.SW_Data then return end
    
    ply.SW_LoadedSpecialties = ply.SW_LoadedSpecialties or {}
    
    local oldSpecialty = SW_InvShop.GetJobSpecialty(oldTeam)
    local newSpecialty = SW_InvShop.GetJobSpecialty(newTeam)
    
    if ply.SW_LoadedSpecialties[oldSpecialty] then
        ply.SW_Data.savedLoadouts[oldSpecialty] = table.Copy(ply.SW_Data.active)
        SW_InvShop.SaveLoadoutToDB(ply, oldSpecialty)
    end
    
    timer.Simple(0.5, function()
        if not IsValid(ply) or not ply.SW_Data then return end
        
        -- Si cambiamos a una Especialidad DISTINTA, vaciamos el inventario al baul
        if oldSpecialty ~= newSpecialty then
            for itemID, _ in pairs(ply.SW_Data.active) do
                ply.SW_Data.armario[itemID] = 1 
            end
            ply.SW_Data.active = {} 
            
            if not ply.SW_LoadedSpecialties[newSpecialty] then
                ply.SW_LoadedSpecialties[newSpecialty] = true
                
                if ply.SW_Data.savedLoadouts[newSpecialty] then
                    ply.SW_Data.active = table.Copy(ply.SW_Data.savedLoadouts[newSpecialty])
                end
                
                if not ply.SW_Data.receivedStarter[newSpecialty] then
                    ply.SW_Data.receivedStarter[newSpecialty] = true
                    SW_InvShop.SaveStarterFlagToDB(ply, newSpecialty)
                    
                    local starter = GetStarterLoadout(newTeam)
                    if starter then
                        DistributeStarterItems(ply, starter)
                        -- ply:ChatPrint("[Inventario] Has recibido tu equipamiento estandar de esta especialidad.")
                    end
                end
            else
                local previousLoadout = ply.SW_Data.savedLoadouts[newSpecialty]
                if previousLoadout then
                    local totalSlots = table.Count(ply.SW_Data.active)
                    for itemID, _ in pairs(previousLoadout) do
                        if ply.SW_Data.armario[itemID] then
                            if totalSlots >= SW_InvShop.Config.MaxActiveSlots then break end
                            
                            ply.SW_Data.armario[itemID] = nil
                            ply.SW_Data.active[itemID] = 1
                            totalSlots = totalSlots + 1
                        end
                    end
                    
                    if table.Count(previousLoadout) == 0 then
                        -- ply:ChatPrint("[Inventario] Has cambiado de especialidad sin armas equipadas previamente.")
                    else
                        -- ply:ChatPrint("[Inventario] Tu equipamiento guardado para esta especialidad ha sido restaurado.")
                    end
                end
            end
        else
            -- SI ES LA MISMA ESPECIALIDAD (Ej: CT Apoyo a 501 Apoyo)
            if not ply.SW_Data.receivedStarter[newSpecialty] then
                ply.SW_Data.receivedStarter[newSpecialty] = true
                SW_InvShop.SaveStarterFlagToDB(ply, newSpecialty)
                
                local starter = GetStarterLoadout(newTeam)
                if starter then DistributeStarterItems(ply, starter) end
            end
        end
        
        CheckAndClearUnauthorizedSlots(ply)
        
        SW_InvShop.SaveCurrentActiveAsLoadoutToDB(ply)
        SW_InvShop.SaveArmarioToDB(ply)
        SW_InvShop.SyncPlayerData(ply)
        SW_InvShop.GiveActiveWeapons(ply) 
        StripUnequippedWeapons(ply)
        SW_InvShop.EnforceActiveBodygroups(ply)
        
        local sid = ply:SteamID64()
        if sid then
            timer.Create("SW_BGJob_" .. sid, 1.5, 10, function()
                if IsValid(ply) and SW_InvShop and SW_InvShop.EnforceActiveBodygroups then
                    SW_InvShop.EnforceActiveBodygroups(ply)
                end
            end)
        end
    end)
end)

-- ============================================================================
-- COMUNICACION DE RED (Mover, Comprar, Vender)
-- ============================================================================
local function GetMaxAmmoLimit(ply)
    local hasBackpack = false
    if IsValid(ply) then
        for _, bg in pairs(ply:GetBodyGroups() or {}) do
            local current = ply:GetBodygroup(bg.id)
            if current > 0 and bg.submodels and bg.submodels[current] then
                local subName = string.lower(bg.submodels[current])
                if string.find(subName, "backpack") or string.find(subName, "pack") or string.find(subName, "mochila") then
                    hasBackpack = true
                    break
                end
            end
        end
    end
    return hasBackpack and 2 or 0
end

function SW_InvShop.EnforceActiveBodygroups(ply)
    if not IsValid(ply) or not ply.SW_Data or not ply.SW_Data.active then return end
    for itemID, itemData in pairs(SW_InvShop.Config.Items) do
        if itemData.class == "bg_unlock" then
            local isEq = (ply.SW_Data.active[itemID] and ply.SW_Data.active[itemID] > 0)
            SW_InvShop.ForceApplyBodygroupItem(ply, itemID, isEq)
        end
    end
end

net.Receive("SW_MoveItem", function(len, ply)
    local itemID = net.ReadString()
    local toLocation = net.ReadString()
    
    if not ply.SW_Data or not SW_InvShop.Config.Items[itemID] then return end
    
    local fromLocation = (toLocation == "active") and "armario" or "active"
    local qtyInFrom = ply.SW_Data[fromLocation][itemID] or 0
    if qtyInFrom <= 0 then return end
    
    local itemData = SW_InvShop.Config.Items[itemID]
    
    if toLocation == "active" then
        if not CanPlayerUseItem(ply, itemID) then
            ply:ChatPrint("[Inventario] No tienes autorizacion de faccion o rango para equipar esto.")
            return
        end
        
        if itemData.isAmmo then
            local maxLimit = GetMaxAmmoLimit(ply)
            if maxLimit == 0 then
                ply:ChatPrint("[Inventario] Necesitas llevar equipada una mochila para poder cargar municion pesada.")
                return
            end
            
            local activeAmmo = 0
            for id, qty in pairs(ply.SW_Data.active) do
                if SW_InvShop.Config.Items[id] and SW_InvShop.Config.Items[id].isAmmo then activeAmmo = activeAmmo + qty end
            end
            if activeAmmo >= maxLimit then
                ply:ChatPrint("[Inventario] Has alcanzado el limite maximo de slots de municion en tu cinturon.")
                return
            end
        else
            local activeWeapons = 0
            for id, qty in pairs(ply.SW_Data.active) do
                if SW_InvShop.Config.Items[id] and not SW_InvShop.Config.Items[id].isAmmo then activeWeapons = activeWeapons + 1 end
            end
            if activeWeapons >= (SW_InvShop.Config.MaxActiveSlots or 3) then
                ply:ChatPrint("[Inventario] No tienes espacio suficiente en tu inventario movil.")
                return
            end
            
            local stype = SW_InvShop.GetItemSlot(itemID)
            if stype <= 3 then
                local counts = GetPlayerActiveSlotCounts(ply)
                if counts[stype] > 0 then
                    ply:ChatPrint("[Inventario] Ya tienes un arma de este tipo equipada. Mueve otra al baul primero.")
                    return
                end
            end
        end
    end
    
    if qtyInFrom <= 1 then
        ply.SW_Data[fromLocation][itemID] = nil
    else
        ply.SW_Data[fromLocation][itemID] = qtyInFrom - 1
    end
    
    ply.SW_Data[toLocation][itemID] = (ply.SW_Data[toLocation][itemID] or 0) + 1
    
    if toLocation == "active" then
        if itemData.isWeapon and itemData.class then
            GiveWeaponPhysically(ply, itemData.class)
        elseif itemData.isAmmo and itemData.ammoType then
            ply:GiveAmmo(itemData.ammoCount or 1, itemData.ammoType, true)
        elseif itemData.class == "bg_unlock" then
            SW_InvShop.ForceApplyBodygroupItem(ply, itemID, true)
        end
    elseif toLocation == "armario" then
        if itemData.isWeapon and itemData.class then
            ply:StripWeapon(itemData.class)
        elseif itemData.isAmmo and itemData.ammoType then
            ply:RemoveAmmo(itemData.ammoCount or 1, itemData.ammoType)
        elseif itemData.class == "bg_unlock" then
            SW_InvShop.ForceApplyBodygroupItem(ply, itemID, false)
        end
    end
    
    SW_InvShop.SaveCurrentActiveAsLoadoutToDB(ply)
    SW_InvShop.SaveArmarioToDB(ply)
    SW_InvShop.SyncPlayerData(ply)
end)

local function GetTotalAmmoItems(ply)
    local total = 0
    for id, qty in pairs(ply.SW_Data.active or {}) do
        if SW_InvShop.Config.Items[id] and SW_InvShop.Config.Items[id].isAmmo then
            total = total + qty
        end
    end
    for id, qty in pairs(ply.SW_Data.armario or {}) do
        if SW_InvShop.Config.Items[id] and SW_InvShop.Config.Items[id].isAmmo then
            total = total + qty
        end
    end
    return total
end

net.Receive("SW_BuyItem", function(len, ply)
    local itemID = net.ReadString()
    local itemData = SW_InvShop.Config.Items[itemID]
    if not itemData or not ply.SW_Data then return end

    if itemData.isBaseItem then
        ply:ChatPrint("[Tienda] Las armas de dotacion no estan a la venta.")
        return
    end

    if not CanPlayerUseItem(ply, itemID) then
        ply:ChatPrint("[Tienda] No estas autorizado para comprar equipamiento de esta categoria.")
        return
    end

    if itemData.isAmmo then
        local maxLimit = GetMaxAmmoLimit(ply)
        if maxLimit == 0 then
            ply:ChatPrint("[Tienda] Necesitas llevar equipada una mochila para poder comprar y transportar municion pesada.")
            return
        elseif GetTotalAmmoItems(ply) >= maxLimit then
            ply:ChatPrint("[Tienda] Has alcanzado la capacidad maxima de municion pesada que puedes poseer.")
            return
        end
    else
        if ply.SW_Data.active[itemID] or ply.SW_Data.armario[itemID] then
            ply:ChatPrint("[Tienda] Ya posees esta arma. No puedes tener duplicados.")
            return
        end
    end
    
    local money = SW_InvShop.Config.UseDarkRPMoney and ply:getDarkRPVar("money") or 99999
    if money < itemData.price then
        ply:ChatPrint("[Tienda] Creditos insuficientes.")
        return
    end
    
    if SW_InvShop.Config.UseDarkRPMoney then ply:addMoney(-itemData.price) end
    
    local canEquip = false
    if itemData.isAmmo then
        local activeAmmo = 0
        for id, qty in pairs(ply.SW_Data.active) do
            if SW_InvShop.Config.Items[id] and SW_InvShop.Config.Items[id].isAmmo then activeAmmo = activeAmmo + qty end
        end
        if activeAmmo < GetMaxAmmoLimit(ply) then canEquip = true end
    else
        local activeWeapons = 0
        for id, qty in pairs(ply.SW_Data.active) do
            if SW_InvShop.Config.Items[id] and not SW_InvShop.Config.Items[id].isAmmo then activeWeapons = activeWeapons + 1 end
        end
        if activeWeapons < (SW_InvShop.Config.MaxActiveSlots or 3) then
            local stype = SW_InvShop.GetItemSlot(itemID)
            if stype <= 3 then
                local counts = GetPlayerActiveSlotCounts(ply)
                if counts[stype] == 0 then canEquip = true end
            else
                canEquip = true
            end
        end
    end

    if canEquip then
        ply.SW_Data.active[itemID] = (ply.SW_Data.active[itemID] or 0) + 1
        ply:ChatPrint("[Tienda] Compraste " .. itemData.name .. ". Se ha agregado a tus manos!")
        if itemData.isWeapon and itemData.class then 
            GiveWeaponPhysically(ply, itemData.class) 
        elseif itemData.isAmmo and itemData.ammoType then 
            ply:GiveAmmo(itemData.ammoCount or 1, itemData.ammoType, true) 
        elseif not itemData.isWeapon and not itemData.isAmmo then
            SW_InvShop.ForceApplyBodygroupItem(ply, itemID, true)
        end
    else
        ply.SW_Data.armario[itemID] = (ply.SW_Data.armario[itemID] or 0) + 1
        ply:ChatPrint("[Tienda] " .. itemData.name .. " fue enviado directamente a tu Armario.")
    end

    SW_InvShop.SaveCurrentActiveAsLoadoutToDB(ply)
    SW_InvShop.SaveArmarioToDB(ply)
    SW_InvShop.SyncPlayerData(ply)
end)

net.Receive("SW_SellItem", function(len, ply)
    local itemID = net.ReadString()
    local itemData = SW_InvShop.Config.Items[itemID]
    if not itemData or not ply.SW_Data then return end
    
    if itemData.isBaseItem then
        ply:ChatPrint("[Sistema] No puedes vender tu arma de dotacion estandar.")
        return
    end
    
    if itemData.isAmmo then
        ply:ChatPrint("[Sistema] No puedes vender municion.")
        return
    end
    
    local jobTable = RPExtraTeams and RPExtraTeams[ply:Team()]
    if jobTable and jobTable.weapons and table.HasValue(jobTable.weapons, itemData.class) then
        ply:ChatPrint("[Sistema] No puedes vender un arma que pertenece al equipamiento por defecto de tu trabajo.")
        return
    end
    
    local inActive = (ply.SW_Data.active[itemID] or 0) > 0
    local inArmario = (ply.SW_Data.armario[itemID] or 0) > 0
    
    if not inActive and not inArmario then
        ply:ChatPrint("[Sistema] No posees este objeto para venderlo.")
        return
    end
    
    if inArmario then
        if ply.SW_Data.armario[itemID] <= 1 then
            ply.SW_Data.armario[itemID] = nil
        else
            ply.SW_Data.armario[itemID] = ply.SW_Data.armario[itemID] - 1
        end
    else
        if ply.SW_Data.active[itemID] <= 1 then
            ply.SW_Data.active[itemID] = nil
        else
            ply.SW_Data.active[itemID] = ply.SW_Data.active[itemID] - 1
        end
        if itemData.isWeapon and itemData.class then ply:StripWeapon(itemData.class) end
        if itemData.class == "bg_unlock" then SW_InvShop.ForceApplyBodygroupItem(ply, itemID, false) end
    end
    
    local sellPrice = math.floor((itemData.price or 0) * 0.4)
    if SW_InvShop.Config.UseDarkRPMoney and ply.addMoney then ply:addMoney(sellPrice) end
    
    ply:ChatPrint("[Economia] Has vendido " .. itemData.name .. " recuperando " .. sellPrice .. " CR.")

    SW_InvShop.SaveCurrentActiveAsLoadoutToDB(ply)
    SW_InvShop.SaveArmarioToDB(ply)
    SW_InvShop.SyncPlayerData(ply)
end)

-- ============================================================================
-- SINCRONIZACION AUTOMATICA DE MUNICION Y MOCHILA
-- ============================================================================
timer.Create("SW_InvShop_AmmoLimitCheck", 5, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if ply.SW_Data and ply.SW_Data.active then
            local changed = false
            -- 1. Sync real GMod ammo -> Inventory
            for itemID, qty in pairs(ply.SW_Data.active) do
                local itemData = SW_InvShop.Config.Items[itemID]
                if itemData and itemData.isAmmo and itemData.ammoType then
                    local realAmmo = ply:GetAmmoCount(itemData.ammoType)
                    local targetQty = math.ceil(realAmmo / (itemData.ammoCount or 1))
                    if targetQty < qty then
                        ply.SW_Data.active[itemID] = targetQty > 0 and targetQty or nil
                        changed = true
                    end
                end
            end
            
            -- 2. Enforce Backpack Limits (in case they unequipped it)
            local maxLimit = GetMaxAmmoLimit(ply)
            local currentAmmoCount = 0
            for itemID, qty in pairs(ply.SW_Data.active) do
                local itemData = SW_InvShop.Config.Items[itemID]
                if itemData and itemData.isAmmo then
                    if currentAmmoCount + qty > maxLimit then
                        local allowedQty = math.max(0, maxLimit - currentAmmoCount)
                        local excess = qty - allowedQty
                        if excess > 0 then
                            ply.SW_Data.active[itemID] = allowedQty > 0 and allowedQty or nil
                            ply.SW_Data.armario[itemID] = (ply.SW_Data.armario[itemID] or 0) + excess
                            if itemData.ammoType then
                                ply:RemoveAmmo((itemData.ammoCount or 1) * excess, itemData.ammoType)
                            end
                            changed = true
                        end
                        currentAmmoCount = currentAmmoCount + allowedQty
                    else
                        currentAmmoCount = currentAmmoCount + qty
                    end
                end
            end
            
            if changed then
                SW_InvShop.SaveCurrentActiveAsLoadoutToDB(ply)
                SW_InvShop.SaveArmarioToDB(ply)
                SW_InvShop.SyncPlayerData(ply)
            end
        end
    end
end)

hook.Add("PlayerDisconnected", "SW_InvShop_SaveOnDisconnect", function(ply)
    if ply.SW_Data and ply.SW_Data.active then
        for itemID, qty in pairs(ply.SW_Data.active) do
            local itemData = SW_InvShop.Config.Items[itemID]
            if itemData and itemData.isAmmo and itemData.ammoType then
                local realAmmo = ply:GetAmmoCount(itemData.ammoType)
                local targetQty = math.ceil(realAmmo / (itemData.ammoCount or 1))
                if targetQty < qty then
                    ply.SW_Data.active[itemID] = targetQty > 0 and targetQty or nil
                end
            end
        end
        SW_InvShop.SaveCurrentActiveAsLoadoutToDB(ply)
        SW_InvShop.SaveArmarioToDB(ply)
    end
end)

function SW_InvShop.ForceApplyBodygroupItem(ply, itemID, enable)
    local unlocks = SW_InvShop.Config.BodygroupUnlocks[itemID]
    if not unlocks then return end
    
    local keywords = type(unlocks) == "table" and (unlocks.keywords or unlocks) or {unlocks}
    local excludes = type(unlocks) == "table" and unlocks.excludes or {}
    
    for _, bg in pairs(ply:GetBodyGroups() or {}) do
        local bgName = string.lower(bg.name or "")
        local currentVal = ply:GetBodygroup(bg.id)
        local currentSubName = bg.submodels and bg.submodels[currentVal] and string.lower(bg.submodels[currentVal]) or ""
        
        local isExplicitlyOff = function(name, val)
            if name == "" then return false end
            return string.find(name, "none") or string.find(name, "empty") or string.find(name, "blank") or string.find(name, "off") or string.find(name, "default") or string.find(name, "sin") or string.find(name, "no ")
        end
        
        -- Verificar si el estado ACTUAL está restringido por esta compra
        local isCurrentlyRestricted = false
        if not isExplicitlyOff(currentSubName, currentVal) then
            for _, kw in ipairs(keywords) do
                local kwLower = string.lower(kw)
                if string.find(bgName, kwLower) or string.find(currentSubName, kwLower) then
                    isCurrentlyRestricted = true
                    break
                elseif (string.find(bgName, "bino") or string.find(bgName, "visor")) and (string.find(currentSubName, "up") or string.find(currentSubName, "down")) then
                    isCurrentlyRestricted = true
                    break
                end
            end
        end
        
        if isCurrentlyRestricted then
            for _, ex in ipairs(excludes) do
                if string.find(currentSubName, string.lower(ex)) or string.find(bgName, string.lower(ex)) then
                    isCurrentlyRestricted = false
                    break
                end
            end
        end
        
        if enable then
            -- El jugador LO TIENE COMPRADO. Si está restringido, ¡está bien! Lo dejamos equipado.
            -- Pero si actualmente NO lo tiene equipado, se lo equipamos automáticamente buscando la variante.
            if not isCurrentlyRestricted then
                local foundOn = nil
                for subID, subName in pairs(bg.submodels or {}) do
                    subName = string.lower(subName)
                    if not isExplicitlyOff(subName, subID) then
                        for _, kw in ipairs(keywords) do
                            local kwLower = string.lower(kw)
                            if string.find(bgName, kwLower) or string.find(subName, kwLower) then
                                foundOn = subID; break
                            elseif (string.find(bgName, "bino") or string.find(bgName, "visor")) and (string.find(subName, "up") or string.find(subName, "down")) then
                                foundOn = subID; break
                            end
                        end
                    end
                    if foundOn then break end
                end
                if foundOn then
                    ply:SetBodygroup(bg.id, foundOn)
                end
            end
        else
            -- El jugador NO LO TIENE COMPRADO. Si está restringido, hay que quitárselo.
            if isCurrentlyRestricted then
                local foundOff = nil
                
                -- Primero buscamos una variante que sea explícitamente "empty", "none", etc.
                for subID, subName in pairs(bg.submodels or {}) do
                    if isExplicitlyOff(string.lower(subName), subID) then
                        foundOff = subID
                        break
                    end
                end
                
                -- Si no hay "empty", buscamos cualquier variante que NO esté restringida
                if not foundOff then
                    for subID, subName in pairs(bg.submodels or {}) do
                        subName = string.lower(subName)
                        local restricted = false
                        for _, kw in ipairs(keywords) do
                            local kwLower = string.lower(kw)
                            if string.find(subName, kwLower) then
                                restricted = true; break
                            elseif (string.find(bgName, "bino") or string.find(bgName, "visor")) and (string.find(subName, "up") or string.find(subName, "down")) then
                                restricted = true; break
                            end
                        end
                        if not restricted then foundOff = subID; break end
                    end
                end
                
                if foundOff then
                    ply:SetBodygroup(bg.id, foundOff)
                else
                    ply:SetBodygroup(bg.id, 0)
                end
            end
        end
    end
end

concommand.Add("sw_reset_starters", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    if IVO_SAM and IVO_SAM.DB then
        IVO_SAM.DB.Query("DELETE FROM sw_inv_starters_spec")
        for k, v in pairs(player.GetAll()) do
            if v.SW_Data then v.SW_Data.receivedStarter = {} end
        end
        if IsValid(ply) then ply:ChatPrint("Starter Loadouts reset for everyone in DB!") else print("Starter Loadouts reset!") end
    end
end)
  
hook.Add("InitPostEntity", "SW_InvShop_VBodygroupsPatch", function()
    if v_bodygroups and v_bodygroups.LoadPlayerBodygroups then
        local oldLoad = v_bodygroups.LoadPlayerBodygroups
        v_bodygroups.LoadPlayerBodygroups = function(ply)
            oldLoad(ply)
            timer.Simple(0.2, function()
                if IsValid(ply) and SW_InvShop and SW_InvShop.EnforceActiveBodygroups then
                    SW_InvShop.EnforceActiveBodygroups(ply)
                end
            end)
        end
    end
end)

hook.Add("PlayerSpawn", "SW_InvShop_FallbackBGPatch", function(ply)
    if not IsValid(ply) then return end
    local sid = ply:SteamID64()
    if not sid then return end
    
    timer.Create("SW_BGPatch_" .. sid, 1.5, 10, function()
        if IsValid(ply) and SW_InvShop and SW_InvShop.EnforceActiveBodygroups then
            SW_InvShop.EnforceActiveBodygroups(ply)
        end
    end)
end)

util.AddNetworkString("SW_ReEnforceBGs")
net.Receive("SW_ReEnforceBGs", function(len, ply)
    timer.Simple(0.2, function()
        if IsValid(ply) and SW_InvShop and SW_InvShop.EnforceActiveBodygroups then
            SW_InvShop.EnforceActiveBodygroups(ply)
        end
    end)
end)
