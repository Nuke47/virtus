-- ============================================================================
-- IVOSAM: SISTEMA DE XP Y NIVELES (SERVER)
-- ============================================================================
if not SERVER then return end

util.AddNetworkString("IVO_RequestXPData")
util.AddNetworkString("IVO_SendXPData")
util.AddNetworkString("IVO_LevelUpAnim")


-- Crear la tabla si no existe
IVO_SAM.DB.Query("CREATE TABLE IF NOT EXISTS ivosam_xp (steamid64 VARCHAR(64) PRIMARY KEY, xp INTEGER, level INTEGER);")

-- Limpieza de seguridad: Eliminar entradas que no sean SteamID64 válidas (Ej. si se guardó un nombre por error)
IVO_SAM.DB.Query("DELETE FROM ivosam_xp WHERE steamid64 NOT LIKE '7656119%' AND steamid64 NOT LIKE 'STEAM_%';")

-- Forzar guardado a SQL
function IVO_SAM.SaveXP(ply)
    if not IsValid(ply) or ply:IsBot() then return end
    IVO_SAM.DB.Query(string.format(
        "REPLACE INTO ivosam_xp (steamid64, xp, level) VALUES (%s, %d, %d);",
        IVO_SAM.DB.Escape(ply:SteamID64()), ply:GetXP(), ply:GetLevel()
    ))
end

-- Cargar datos al conectar
hook.Add("PlayerInitialSpawn", "IVO_LoadXP", function(ply)
    if ply:IsBot() then return end
    
    local sid64 = ply:SteamID64()
    IVO_SAM.DB.QueryRow(string.format("SELECT * FROM ivosam_xp WHERE steamid64 = %s;", IVO_SAM.DB.Escape(sid64)), function(res)
        if not IsValid(ply) then return end
        if res then
            ply:SetNWInt("IVO_XP", tonumber(res.xp) or 0)
            ply:SetNWInt("IVO_Level", tonumber(res.level) or 1)
        else
            ply:SetNWInt("IVO_XP", 0)
            ply:SetNWInt("IVO_Level", 1)
            IVO_SAM.SaveXP(ply)
        end
    end)
end)

-- Guardar datos al desconectar
hook.Add("PlayerDisconnected", "IVO_SaveXP_Disc", function(ply)
    IVO_SAM.SaveXP(ply)
end)

-- Guardado periódico cada 5 minutos
timer.Create("IVO_XPSaveLoop", 300, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        IVO_SAM.SaveXP(ply)
    end
end)

function IVO_SAM.SetPlayerXP(ply, amount)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    amount = math.Clamp(amount, 0, 10000000)
    
    local oldLevel = ply:GetLevel()
    
    local tempXP = amount
    local tempLevel = 1
    local xpNeeded = IVO_SAM.GetXPNeededForLevel(tempLevel)
    
    local iterations = 0
    while tempXP >= xpNeeded and iterations < 1000 do
        tempXP = tempXP - xpNeeded
        tempLevel = tempLevel + 1
        xpNeeded = IVO_SAM.GetXPNeededForLevel(tempLevel)
        iterations = iterations + 1
    end
    
    ply:SetNWInt("IVO_XP", tempXP)
    ply:SetNWInt("IVO_Level", tempLevel)
    IVO_SAM.SaveXP(ply)
    
    if tempLevel > oldLevel then
        -- Solo reproducir animación si de verdad subió por encima del nivel que tenía antes del seteo
        ply:SendLua([[surface.PlaySound("garrysmod/save_load1.wav")]])
        net.Start("IVO_LevelUpAnim")
            net.WriteInt(oldLevel, 16)
            net.WriteInt(tempLevel, 16)
        net.Send(ply)
        
        hook.Run("IVOSAM_LevelUp", ply, tempLevel)
    end
end

function IVO_SAM.SetPlayerLevel(ply, level)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    level = math.Clamp(level, 1, 1000) -- límite seguro
    ply:SetNWInt("IVO_Level", level)
    ply:SetNWInt("IVO_XP", 0) -- Reseteamos su barra actual de XP al cambiar de nivel
    IVO_SAM.SaveXP(ply)
end

function IVO_SAM.AddPlayerXP(ply, amount)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    
    amount = math.Clamp(amount, 0, 10000000)
    
    local xp = ply:GetXP() + amount
    local level = ply:GetLevel()
    local initialLevel = level
    
    local xpNeeded = IVO_SAM.GetXPNeededForLevel(level)
    local iterations = 0
    while xp >= xpNeeded and iterations < 1000 do
        xp = xp - xpNeeded
        level = level + 1
        xpNeeded = IVO_SAM.GetXPNeededForLevel(level)
        iterations = iterations + 1
    end
    
    ply:SetNWInt("IVO_XP", xp)
    ply:SetNWInt("IVO_Level", level)
    IVO_SAM.SaveXP(ply)
    
    -- Dar la misma cantidad de experiencia al trabajo actual (si aplica)
    if IVO_SAM.AddJobXP then
        IVO_SAM.AddJobXP(ply, amount)
    end

    if level > initialLevel then
        
        -- Enviar mensaje de red para la animación cinematográfica
        net.Start("IVO_LevelUpAnim")
            net.WriteInt(initialLevel, 16)
            net.WriteInt(level, 16)
        net.Send(ply)
        
        hook.Run("IVOSAM_LevelUp", ply, level)
    end
end

util.AddNetworkString("IVO_XP_Popup")

-- ============================================================================
-- CONFIGURACIÓN DE EXPERIENCIA Y DINERO
-- ============================================================================
local XP_CONFIG = {
    NPC_Normal = 50,       -- XP por matar NPCs comunes (zombies, combine, etc.)
    Player_Kill = 300,     -- XP por matar a un jugador enemigo
}

local MONEY_CONFIG = {
    NPC_Normal = 50,       -- Dinero por matar NPCs comunes
    Player_Kill = 300,     -- Dinero por matar a un jugador enemigo
}

-- XP específica por tipo de Droide (De menos a más)
local DROID_XP = {
    b1 = 50,
    b2 = 100,
    bx = 200,
    droideka = 350,
    default = 80
}

-- Dinero específico por tipo de Droide (Restaurado a valores originales)
local DROID_MONEY = {
    b1 = 50,
    b2 = 100,
    bx = 150,
    droideka = 250,
    default = 50
}

-- Categorías de DarkRP que NO dan XP/Dinero si las matas (tus aliados)
local ForbiddenCategories = {
    ["clone trooper"] = true,
    ["shadow unit"] = true,
    ["shock trooper"] = true,
    ["altos mandos"] = true
}

-- Desactivamos la notificación nativa de dinero de DarkRP para NPCs usando un Timer de seguridad
hook.Add("InitPostEntity", "IVO_SAM_DisableNativeNPCMoney", function()
    timer.Simple(2, function()
        hook.Remove("OnNPCKilled", "DarkRP_NPCKillPay")
        if GAMEMODE and GAMEMODE.Config then
            GAMEMODE.Config.npckillpay = 0
        end
    end)
end)

-- Helper para identificar si es un NPC del pack ivo_npc
local function IsIvoCustomNPC(ent)
    if not IsValid(ent) then return false end
    local class = string.lower(ent:GetClass())
    return string.find(class, "ivo_npc") or string.find(class, "droid") or string.find(class, "rts_")
end

-- Helper para obtener la XP exacta según el tipo de droide
local function GetDroidXP(ent)
    local class = string.lower(ent:GetClass())
    if string.find(class, "droideka") then return DROID_XP.droideka end
    if string.find(class, "bx") then return DROID_XP.bx end
    if string.find(class, "b2") then return DROID_XP.b2 end
    if string.find(class, "b1") then return DROID_XP.b1 end
    return DROID_XP.default
end

-- Helper para obtener el dinero exacto según el tipo de droide
local function GetDroidMoney(ent)
    local class = string.lower(ent:GetClass())
    if string.find(class, "droideka") then return DROID_MONEY.droideka end
    if string.find(class, "bx") then return DROID_MONEY.bx end
    if string.find(class, "b2") then return DROID_MONEY.b2 end
    if string.find(class, "b1") then return DROID_MONEY.b1 end
    return DROID_MONEY.default
end

-- Función segura para dar dinero
local function GivePlayerMoney(ply, amount)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if ply.addMoney then
        ply:addMoney(amount)
    elseif ply.AddMoney then
        ply:AddMoney(amount)
    elseif DarkRP and DarkRP.storeMoney then
        -- Método manual (muy raro que sea necesario, pero es un fallback seguro)
        local current = ply:getDarkRPVar("money") or 0
        ply:setDarkRPVar("money", current + amount)
        DarkRP.storeMoney(ply, current + amount)
    end
end

-- Hook para dar XP y Dinero al matar NPCs estándar
hook.Add("OnNPCKilled", "IVO_SAM_XPNPCKill", function(npc, attacker, inflictor)
    if IsValid(npc) and npc.IVO_XP_Given then return end
    
    if IsValid(attacker) and not attacker:IsPlayer() and IsValid(attacker:GetOwner()) and attacker:GetOwner():IsPlayer() then
        attacker = attacker:GetOwner()
    end
    
    if IsValid(attacker) and attacker:IsPlayer() then
        local xpAmount = XP_CONFIG.NPC_Normal 
        local moneyAmount = MONEY_CONFIG.NPC_Normal
        
        if IsIvoCustomNPC(npc) then
            xpAmount = GetDroidXP(npc)
            moneyAmount = GetDroidMoney(npc)
            npc.IVO_XP_Given = true
        end
        
        IVO_SAM.AddPlayerXP(attacker, xpAmount)
        GivePlayerMoney(attacker, moneyAmount)
        
        net.Start("IVO_XP_Popup")
            net.WriteInt(xpAmount, 16)
            net.WriteInt(moneyAmount, 32)
        net.Send(attacker)
    end
end)

-- Hook alternativo para NextBots o Entidades Custom (ivo_npc/droid) que no disparan OnNPCKilled
hook.Add("EntityTakeDamage", "IVO_SAM_XPCustomBotKill", function(target, dmginfo)
    if IsIvoCustomNPC(target) then
        if target:Health() > 0 and (target:Health() - dmginfo:GetDamage()) <= 0 then
            
            if target.IVO_XP_Given then return end
            target.IVO_XP_Given = true
            
            local attacker = dmginfo:GetAttacker()
            if IsValid(attacker) and not attacker:IsPlayer() and IsValid(attacker:GetOwner()) and attacker:GetOwner():IsPlayer() then
                attacker = attacker:GetOwner()
            end
            
            if IsValid(attacker) and attacker:IsPlayer() then
                local xpAmount = GetDroidXP(target)
                local moneyAmount = GetDroidMoney(target)
                
                IVO_SAM.AddPlayerXP(attacker, xpAmount)
                GivePlayerMoney(attacker, moneyAmount)
                
                net.Start("IVO_XP_Popup")
                    net.WriteInt(xpAmount, 16)
                    net.WriteInt(moneyAmount, 32)
                net.Send(attacker)
            end
        end
    end
end)

-- Hook para dar XP y Dinero al matar a otros jugadores (PvP)
hook.Add("PlayerDeath", "IVO_SAM_XPPlayerKill", function(victim, inflictor, attacker)
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        
        -- Verificamos la categoría del trabajo del jugador muerto (DarkRP)
        if victim.getJobTable and victim:getJobTable() then
            local category = string.lower(victim:getJobTable().category or "")
            
            -- Si el jugador NO pertenece a las categorías aliadas, damos XP y Dinero
            if not ForbiddenCategories[category] then
                local xpAmount = XP_CONFIG.Player_Kill
                local moneyAmount = MONEY_CONFIG.Player_Kill
                
                IVO_SAM.AddPlayerXP(attacker, xpAmount)
                GivePlayerMoney(attacker, moneyAmount)
                
                net.Start("IVO_XP_Popup")
                    net.WriteInt(xpAmount, 16)
                    net.WriteInt(moneyAmount, 32)
                net.Send(attacker)
            end
        end
        
    end
end)

-- Función que modifica a un jugador ya sea que esté online u offline
function IVO_SAM.ModifyOfflinePlayerXP(steamid_or_64, field, newValue, isAdd)
    local ply
    -- Intentar buscar si está online
    if string.match(steamid_or_64, "^STEAM_") then
        ply = player.GetBySteamID(steamid_or_64)
    else
        ply = player.GetBySteamID64(steamid_or_64)
    end
    
    if IsValid(ply) then
        if field == "xp" then
            if isAdd then IVO_SAM.AddPlayerXP(ply, newValue) else IVO_SAM.SetPlayerXP(ply, newValue) end
        elseif field == "level" then
            IVO_SAM.SetPlayerLevel(ply, newValue)
        end
        return true
    end
    
    -- Jugador offline
    local sid64 = steamid_or_64
    if string.match(sid64, "^STEAM_") then
        sid64 = util.SteamIDTo64(sid64)
        if not sid64 then return false end
    end
    
    IVO_SAM.DB.QueryRow(string.format("SELECT * FROM ivosam_xp WHERE steamid64 = %s;", IVO_SAM.DB.Escape(sid64)), function(res)
        local currentXP = res and tonumber(res.xp) or 0
        local currentLevel = res and tonumber(res.level) or 1
        
        if field == "xp" then
            newValue = math.Clamp(newValue, 0, 10000000)
            
            if not isAdd then
                currentXP = 0
                currentLevel = 1
            end
            
            currentXP = currentXP + newValue
            local xpNeeded = IVO_SAM.GetXPNeededForLevel(currentLevel)
            local iterations = 0
            while currentXP >= xpNeeded and iterations < 1000 do
                currentXP = currentXP - xpNeeded
                currentLevel = currentLevel + 1
                xpNeeded = IVO_SAM.GetXPNeededForLevel(currentLevel)
                iterations = iterations + 1
            end
        elseif field == "level" then
            currentLevel = math.Clamp(newValue, 1, 1000)
            currentXP = 0
        end
        
        if res then
            IVO_SAM.DB.Query(string.format("UPDATE ivosam_xp SET xp = %d, level = %d WHERE steamid64 = %s;", currentXP, currentLevel, IVO_SAM.DB.Escape(sid64)))
        else
            IVO_SAM.DB.Query(string.format("INSERT INTO ivosam_xp (steamid64, xp, level) VALUES (%s, %d, %d);", IVO_SAM.DB.Escape(sid64), currentXP, currentLevel))
        end
    end)
    return true
end

-- Petición de datos para el menú UI (exclusivo superadmin)
net.Receive("IVO_RequestXPData", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    IVO_SAM.DB.Query("SELECT x.steamid64, x.xp, x.level, u.name as pName FROM ivosam_xp x LEFT JOIN ivosam_playtime u ON x.steamid64 = u.steamid64;", function(data)
        data = data or {}
        
        -- Agregar los que están online y quizás aún no guardados
        local onlineData = {}
        for _, p in ipairs(player.GetAll()) do
            onlineData[p:SteamID64()] = {
                steamid64 = p:SteamID64(),
                xp = p:GetXP(),
                level = p:GetLevel(),
                pName = p:Nick()
            }
        end
        
        for i, row in ipairs(data) do
            local sid64 = row.steamid64
            if onlineData[sid64] then
                data[i] = onlineData[sid64]
                onlineData[sid64] = nil
            end
        end
        
        -- Agregar a la lista los online que no estaban en la db
        for sid64, row in pairs(onlineData) do
            table.insert(data, row)
        end
        
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        net.Start("IVO_SendXPData")
            net.WriteTable(data)
        net.Send(ply)
    end)
end)
