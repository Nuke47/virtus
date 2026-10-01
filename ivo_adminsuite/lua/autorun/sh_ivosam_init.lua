-- ============================================================================
-- IVOSAM: CORE INITIALIZATION, DATABASE MASTER, PLAYTIME & BAN PERSISTENCE
-- ============================================================================
IVO_SAM = IVO_SAM or {}
my_admin = my_admin or {}

-- Configuración central y guards: deben cargarse antes que cualquier otro módulo
include("sam/config/sh_config.lua")
if SERVER then include("sam/core/sv_database.lua") end
include("sam/core/sh_guards.lua")
include("sam/core/sh_xp.lua")

-- 1. TABLA BASE DE RESPALDO CON PERMISOS POR DEFECTO
IVO_SAM.Ranks = IVO_SAM.Ranks or {
    ["user"] = {
        power = 0,
        color = Color(255, 255, 255),
        permissions = { ["IsAdmin"] = false, ["CanBan"] = false, ["CanKick"] = false, ["CanSlay"] = false, ["CanSeeESP"] = false }
    },
    ["admin"] = {
        power = 50,
        color = Color(255, 200, 0),
        permissions = { ["IsAdmin"] = true, ["CanBan"] = false, ["CanKick"] = true, ["CanSlay"] = true, ["CanSeeESP"] = true }
    },
    ["superadmin"] = {
        power = 100,
        color = Color(255, 0, 0),
        permissions = { ["IsAdmin"] = true, ["CanBan"] = true, ["CanKick"] = true, ["CanSlay"] = true, ["CanSeeESP"] = true }
    }
}

function IVO_SAM.LoadRanks()
    if SERVER then
        if not file.Exists("ivosam", "DATA") then file.CreateDir("ivosam") end
        if file.Exists("ivosam/ranks_database.txt", "DATA") then
            local data = file.Read("ivosam/ranks_database.txt", "DATA")
            local tbl = util.JSONToTable(data)
            if tbl and table.Count(tbl) > 0 then
                for rankName, rankData in pairs(tbl) do
                    rankData.permissions = rankData.permissions or {}
                end
                IVO_SAM.Ranks = tbl
            end
        else
            file.Write("ivosam/ranks_database.txt", util.TableToJSON(IVO_SAM.Ranks, true))
        end

    end
end

IVO_SAM.LoadRanks()

-- ============================================================================
-- JERARQUÍA E INMUNIDAD (COMPARTIDA)
-- ============================================================================
function IVO_SAM.CanTarget(ply, target)
    if not IsValid(ply) then return true end
    if not IsValid(target) then return false end
    if ply == target then return true end

    local plyRank    = isfunction(ply.GetRank)    and ply:GetRank():lower()    or "user"
    local targetRank = isfunction(target.GetRank) and target:GetRank():lower() or "user"

    local plyPower    = IVO_SAM.Ranks[plyRank]    and IVO_SAM.Ranks[plyRank].power    or 0
    local targetPower = IVO_SAM.Ranks[targetRank] and IVO_SAM.Ranks[targetRank].power or 0

    return plyPower >= targetPower
end

-- ============================================================================
-- UTILIDADES DE TIEMPO
-- ============================================================================
local timeUnits = { ["m"] = 60, ["h"] = 3600, ["d"] = 86400, ["w"] = 604800, ["mo"] = 2592000, ["y"] = 31536000 }

function IVO_SAM.ParseTime(timeStr)
    if not timeStr or timeStr == "0" or timeStr == "" then return 0 end
    if tonumber(timeStr) then return tonumber(timeStr) * 60 end
    local s = string.lower(timeStr)
    local totalSeconds = 0
    local found = false
    for amount, unit in s:gmatch("(%d+)([a-z]+)") do
        if timeUnits[unit] then totalSeconds = totalSeconds + (tonumber(amount) * timeUnits[unit]) found = true end
    end
    return found and totalSeconds or 0
end

function IVO_SAM.FormatPlaytime(seconds)
    local s = tonumber(seconds) or 0
    if s <= 0 then return "0s" end
    local w   = math.floor(s / 604800)
    local d   = math.floor((s % 604800) / 86400)
    local h   = math.floor((s % 86400) / 3600)
    local m   = math.floor((s % 3600) / 60)
    local seg = math.floor(s % 60)
    local res = ""
    if w   > 0 then res = res .. w   .. "w " end
    if d   > 0 then res = res .. d   .. "d " end
    if h   > 0 then res = res .. h   .. "h " end
    if m   > 0 then res = res .. m   .. "m " end
    if seg > 0 or res == "" then res = res .. seg .. "s" end
    return string.Trim(res)
end

function IVO_SAM.FormatTime(seconds)
    if not seconds or seconds <= 0 then return "PERMANENTE" end
    local remaining = seconds - os.time()
    if remaining <= 0 then return "EXPIRADO" end
    local days    = math.floor(remaining / 86400)
    local hours   = math.floor((remaining % 86400) / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    local res = {}
    if days    > 0 then table.insert(res, days    .. "d") end
    if hours   > 0 then table.insert(res, hours   .. "h") end
    if minutes > 0 then table.insert(res, minutes .. "m") end
    return #res > 0 and table.concat(res, " ") or "Menos de 1m"
end

-- ============================================================================
-- METATABLAS DE JUGADORES (SHARED)
-- ============================================================================
local plyMeta = FindMetaTable("Player")
function plyMeta:GetRank() return self:GetNWString("UserGroup", "user") end
function plyMeta:IsAdmin()
    local rankData = IVO_SAM.Ranks[self:GetRank()]
    return (rankData and (rankData.power or rankData.val or 0) >= 50) or self:IsSuperAdmin()
end
function plyMeta:IsSuperAdmin()
    local rankData = IVO_SAM.Ranks[self:GetRank()]
    return self:GetRank() == "superadmin" or (rankData and (rankData.power or rankData.val or 0) >= 100)
end
function plyMeta:GetPlayTime()
    return (self.IVO_TotalAcumulado or 0) + (os.time() - (self.IVO_JoinTime or os.time()))
end

-- ============================================================================
-- LADO SERVIDOR
-- ============================================================================
if SERVER then
    -- Net strings
    util.AddNetworkString("Ivosam_Notify")
    util.AddNetworkString("Ivosam_Freecam")
    util.AddNetworkString("Ivosam_FreecamTP")
    util.AddNetworkString("IVO_SyncRanks")
    util.AddNetworkString("IVO_RequestHistoryData")
    util.AddNetworkString("IVO_SendHistoryData")
    util.AddNetworkString("IVO_UpdateRankPermissions")
    util.AddNetworkString("IVO_RequestHistoryRefresh")
    util.AddNetworkString("IVOSAM_RequestPlayerHistory")
    util.AddNetworkString("IVOSAM_SendPlayerHistory")
    util.AddNetworkString("IVO_FreecamSetTarget")
    
    util.AddNetworkString("IVO_Vote_Start")
    util.AddNetworkString("IVO_Vote_Cast")
    util.AddNetworkString("IVO_Vote_End")

    -- Registrar archivos cliente
    AddCSLuaFile("sam/config/sh_config.lua")
    AddCSLuaFile("sam/core/sh_util.lua")
    AddCSLuaFile("sam/core/sh_guards.lua")
    AddCSLuaFile("sam/core/sh_xp.lua")
    AddCSLuaFile("sam/core/cl_init.lua")
    AddCSLuaFile("sam/ui/cl_menu.lua")
    AddCSLuaFile("sam/ui/cl_tab_players.lua")
    AddCSLuaFile("sam/ui/cl_tab_history.lua")
    AddCSLuaFile("sam/ui/cl_tab_ranks.lua")
    AddCSLuaFile("sam/ui/cl_tab_commands.lua")
    AddCSLuaFile("sam/ui/cl_tab_vote.lua")
    AddCSLuaFile("sam/ui/cl_tab_xp.lua")
    AddCSLuaFile("sam/ui/cl_xp_hud.lua")
    AddCSLuaFile("sam/systems/tickets/cl_admin_chat.lua")
    AddCSLuaFile("sam/systems/tickets/cl_tickets_menu.lua")

    -- Incluir módulos servidor
    include("sam/core/sh_util.lua")
    include("sam/core/sv_xp.lua")
    include("sam/core/sv_job_xp.lua")
            include("sam/systems/defcon/sv_defcon.lua")
    include("sam/systems/tickets/sv_tickets.lua")
    include("sam/systems/vote/sv_vote.lua")

    IVO_SAM.LastPositions = IVO_SAM.LastPositions or {}

    hook.Add("IVOSAM_DatabaseConnected", "IVO_InitTables", function()
        IVO_SAM.DB.Query("CREATE TABLE IF NOT EXISTS ivosam_users (steamid64 VARCHAR(64) PRIMARY KEY, `rank` VARCHAR(64), expire INTEGER, admin VARCHAR(64), date VARCHAR(64));")
        IVO_SAM.DB.Query("ALTER TABLE ivosam_users ADD COLUMN sec_rank VARCHAR(64);")
        IVO_SAM.DB.Query("ALTER TABLE ivosam_users ADD COLUMN sec_expire INTEGER;")
        IVO_SAM.DB.Query("CREATE TABLE IF NOT EXISTS ivosam_playtime (steamid64 VARCHAR(64) PRIMARY KEY, name VARCHAR(128), steamid VARCHAR(64), total_time INTEGER);")
        IVO_SAM.DB.Query("CREATE TABLE IF NOT EXISTS ivosam_bans (steamid64 VARCHAR(64) PRIMARY KEY, name VARCHAR(128), steamid VARCHAR(64), duration INTEGER, unban_time INTEGER, reason VARCHAR(255), admin VARCHAR(64), date VARCHAR(64));")
        
        -- TABLAS WEB
        IVO_SAM.DB.Query("CREATE TABLE IF NOT EXISTS web_creditos (steamid64 VARCHAR(64) PRIMARY KEY, balance INT DEFAULT 0);")
        IVO_SAM.DB.Query("CREATE TABLE IF NOT EXISTS web_notifications (id INT AUTO_INCREMENT PRIMARY KEY, steamid64 VARCHAR(64), playername VARCHAR(128), message TEXT, is_read TINYINT(1) DEFAULT 0);")
    end)

    function IVO_SAM.ForzarGuardadoSQL(p)
        if not IsValid(p) or p:IsBot() then return end
        p.IVO_JoinTime = p.IVO_JoinTime or os.time()
        local tiempoTotal = p:GetPlayTime()
        p:SetNWInt("IVO_Playtime", tiempoTotal)
        IVO_SAM.DB.Query(string.format(
            "REPLACE INTO ivosam_playtime (steamid64, name, steamid, total_time) VALUES (%s, %s, %s, %d);",
            IVO_SAM.DB.Escape(p:SteamID64()), IVO_SAM.DB.Escape(p:Nick()), IVO_SAM.DB.Escape(p:SteamID()), tiempoTotal
        ))
    end

    timer.Create("IVO_Playtime_Loop", IVO_SAM.Config.PLAYTIME_SAVE_INTERVAL, 0, function()
        for _, p in ipairs(player.GetAll()) do IVO_SAM.ForzarGuardadoSQL(p) end
    end)
    
    -- POLLING DE NOTIFICACIONES WEB
    util.AddNetworkString("IVO_Web_HUD_Notify")

    timer.Create("IVO_WebNotifications_Poll", 10, 0, function()
        if not IVO_SAM.DB.Connection then return end
        IVO_SAM.DB.Query("SELECT id, steamid64, playername, message FROM web_notifications WHERE is_read = 0 ORDER BY id ASC LIMIT 5;", function(data)
            if data and #data > 0 then
                for _, notif in ipairs(data) do
                    -- Enviar mensaje al HUD de todos los jugadores
                    net.Start("IVO_Web_HUD_Notify")
                    net.WriteString(notif.playername)
                    net.WriteString(notif.message)
                    net.Broadcast()

                    -- Sincronización Automática si el jugador está conectado
                    if notif.steamid64 then
                        local ply = player.GetBySteamID64(notif.steamid64)
                        if IsValid(ply) then
                            -- 1. Recargar Rango VIP
                            IVO_SAM.DB.QueryRow(string.format("SELECT * FROM ivosam_users WHERE steamid64 = %s;", IVO_SAM.DB.Escape(notif.steamid64)), function(resUser)
                                if not IsValid(ply) then return end
                                if resUser and resUser.rank then
                                    ply:SetNWString("UserGroup", resUser.rank) 
                                    ply:SetUserGroup(resUser.rank)
                                    ply:ChatPrint("¡Tus beneficios VIP han sido sincronizados automáticamente!")
                                end
                            end)
                            
                            -- 2. Recargar Animaciones
                            ply.IvoAnims_Unlocked = {}
                            IVO_SAM.DB.Query(string.format("SELECT anim_id FROM ivo_anims_purchases WHERE steamid = %s", IVO_SAM.DB.Escape(notif.steamid64)), function(animData)
                                if not IsValid(ply) then return end
                                if animData then
                                    for _, row in ipairs(animData) do
                                        ply.IvoAnims_Unlocked[row.anim_id] = true
                                    end
                                end
                                -- Sincronizar al cliente
                                net.Start("IvoAnims_SyncUnlocked")
                                    net.WriteString("ALL")
                                    net.WriteTable(ply.IvoAnims_Unlocked)
                                net.Send(ply)
                                ply:ChatPrint("¡Tus animaciones han sido desbloqueadas automáticamente!")
                            end)
                        end
                    end

                    -- Marcar como leida (borrarla o setear is_read)
                    IVO_SAM.DB.Query("DELETE FROM web_notifications WHERE id = " .. tonumber(notif.id) .. ";")
                end
            end
        end)
    end)

    hook.Add("PlayerInitialSpawn", "IVO_MasterLoadSQL", function(p)
        if p:IsBot() then return end
        local sid64 = p:SteamID64()
        p.IVO_JoinTime = os.time()

        net.Start("IVO_SyncRanks") net.WriteTable(IVO_SAM.Ranks) net.Send(p)

        IVO_SAM.DB.QueryRow(string.format("SELECT total_time FROM ivosam_playtime WHERE steamid64 = %s;", IVO_SAM.DB.Escape(sid64)), function(resPlay)
            if not IsValid(p) then return end
            if resPlay == false then print("[IVOSAM] Error loading playtime for " .. p:Nick()) end
            
            p.IVO_TotalAcumulado = (resPlay and resPlay ~= false) and tonumber(resPlay.total_time) or 0
            p:SetNWInt("IVO_Playtime", p.IVO_TotalAcumulado)
            
            IVO_SAM.DB.QueryRow(string.format("SELECT * FROM ivosam_users WHERE steamid64 = %s;", IVO_SAM.DB.Escape(sid64)), function(resUser)
                if not IsValid(p) then return end
                if resUser == false then
                    print("[IVOSAM] Error loading rank for " .. p:Nick() .. " - Keeping current rank to prevent data loss.")
                    timer.Simple(2, function() if IsValid(p) then IVO_SAM.ForzarGuardadoSQL(p) end end)
                    return
                end
                
                if resUser then
                    local expireTime = tonumber(resUser.expire) or 0
                    if expireTime != 0 and os.time() > expireTime then
                        p:SetNWString("UserGroup", "user") p:SetUserGroup("user")
                        IVO_SAM.DB.Query(string.format("UPDATE ivosam_users SET `rank`='user', expire=0 WHERE steamid64 = %s;", IVO_SAM.DB.Escape(sid64)))
                    else
                        p:SetNWString("UserGroup", resUser.rank) p:SetUserGroup(resUser.rank)
                    end
        
                    local secExpire = tonumber(resUser.sec_expire) or 0
                    if resUser.sec_rank and resUser.sec_rank ~= "" and resUser.sec_rank ~= "NULL" then
                        if secExpire != 0 and os.time() > secExpire then
                            p:SetNWString("SecondaryRank", "")
                            IVO_SAM.DB.Query(string.format("UPDATE ivosam_users SET sec_rank='', sec_expire=0 WHERE steamid64 = %s;", IVO_SAM.DB.Escape(sid64)))
                        else
                            p:SetNWString("SecondaryRank", resUser.sec_rank)
                        end
                    else
                        p:SetNWString("SecondaryRank", "")
                    end
                else
                    p:SetNWString("UserGroup", "user") p:SetUserGroup("user")
                    p:SetNWString("SecondaryRank", "")
                end
                timer.Simple(2, function() if IsValid(p) then IVO_SAM.ForzarGuardadoSQL(p) end end)
            end)
        end)
    end)

    hook.Add("PlayerDisconnected", "IVO_MasterDisconnectSQL", function(p)
        if IsValid(p) and not p:IsBot() then IVO_SAM.ForzarGuardadoSQL(p) end
    end)

    net.Receive("IVO_RequestHistoryData", function(len, ply)
        if not IsValid(ply) or not IVO_SAM.HasPermission(ply, "menu") then return end
        IVO_SAM.DB.Query("SELECT * FROM ivosam_playtime ORDER BY total_time DESC LIMIT 100;", function(historial)
            IVO_SAM.DB.Query("SELECT * FROM ivosam_bans;", function(listaBans)
                IVO_SAM.DB.Query("SELECT steamid64, `rank` FROM ivosam_users;", function(listaRanks)
                    if not IsValid(ply) then return end
                    net.Start("IVO_SendHistoryData")
                        net.WriteTable(historial or {})
                        net.WriteTable(listaBans or {})
                        net.WriteTable(listaRanks or {})
                    net.Send(ply)
                end)
            end)
        end)
    end)
    function my_admin.SetUserRank(target, rankName, expireTime, adminName)
        if not IsValid(target) or not IVO_SAM.Ranks[rankName] then return end
        target:SetNWString("UserGroup", rankName) target:SetUserGroup(rankName)
        
        local sid64 = IVO_SAM.DB.Escape(target:SteamID64())
        IVO_SAM.DB.Query("SELECT steamid64 FROM ivosam_users WHERE steamid64 = " .. sid64, function(check)
            if check then
                IVO_SAM.DB.Query(string.format(
                    "UPDATE ivosam_users SET `rank` = %s, expire = %d, admin = %s, date = %s WHERE steamid64 = %s;",
                    IVO_SAM.DB.Escape(rankName), expireTime or 0, IVO_SAM.DB.Escape(adminName or "Console"), IVO_SAM.DB.Escape(os.date("%d/%m/%Y")), sid64
                ))
            else
                IVO_SAM.DB.Query(string.format(
                    "INSERT INTO ivosam_users (steamid64, `rank`, expire, admin, date) VALUES (%s, %s, %d, %s, %s);",
                    sid64, IVO_SAM.DB.Escape(rankName), expireTime or 0, IVO_SAM.DB.Escape(adminName or "Console"), IVO_SAM.DB.Escape(os.date("%d/%m/%Y"))
                ))
            end
        end)
    end

    function my_admin.SetSecondaryRank(target, rankName, expireTime, adminName)
        if not IsValid(target) or (rankName ~= "" and not IVO_SAM.Ranks[rankName]) then return end
        target:SetNWString("SecondaryRank", rankName)
        
        local sid64 = IVO_SAM.DB.Escape(target:SteamID64())
        IVO_SAM.DB.Query("SELECT steamid64 FROM ivosam_users WHERE steamid64 = " .. sid64, function(check)
            if check then
                IVO_SAM.DB.Query(string.format(
                    "UPDATE ivosam_users SET sec_rank = %s, sec_expire = %d WHERE steamid64 = %s;",
                    IVO_SAM.DB.Escape(rankName), expireTime or 0, sid64
                ))
            else
                IVO_SAM.DB.Query(string.format(
                    "INSERT INTO ivosam_users (steamid64, `rank`, expire, admin, date, sec_rank, sec_expire) VALUES (%s, 'user', 0, %s, %s, %s, %d);",
                    sid64, IVO_SAM.DB.Escape(adminName or "Console"), IVO_SAM.DB.Escape(os.date("%d/%m/%Y")), IVO_SAM.DB.Escape(rankName), expireTime or 0
                ))
            end
        end)
    end

    net.Receive("IVO_UpdateRankPermissions", function(len, ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        local rankName     = net.ReadString()
        local permissionID = net.ReadString()
        local newValue     = net.ReadBool()

        if IVO_SAM.Ranks[rankName] then
            IVO_SAM.Ranks[rankName].permissions = IVO_SAM.Ranks[rankName].permissions or {}
            IVO_SAM.Ranks[rankName].permissions[permissionID] = newValue
            file.Write("ivosam/ranks_database.txt", util.TableToJSON(IVO_SAM.Ranks, true))
            net.Start("IVO_SyncRanks")
                net.WriteTable(IVO_SAM.Ranks)
            net.Broadcast()
        end
    end)



    net.Receive("IVO_RequestHistoryRefresh", function(len, ply)
        if not IsValid(ply) or not IVO_SAM.HasPermission(ply, "menu") then return end
        net.Start("IVO_SendHistoryData")
            net.WriteTable(IVO_SAM.ServerHistoryData or {})
            net.WriteTable(IVO_SAM.ServerBansData or {})
        net.Send(ply)
    end)

    include("sam/core/sv_commands.lua")

    net.Receive("Ivosam_Freecam", function(len, ply)
        if not IsValid(ply) or not ply:IsAdmin() then return end
        local isActive = net.ReadBool()
        if isActive then
            ply.FreecamTarget = nil
        else
            ply.FreecamTarget = nil
        end
    end)

    net.Receive("IVO_FreecamSetTarget", function(len, ply)
        if not IsValid(ply) or not ply:IsAdmin() then return end
        local target = net.ReadEntity()
        ply.FreecamTarget = IsValid(target) and target:IsPlayer() and target or nil
    end)

    hook.Add("PlayerSay", "IVO_FreecamReadChat", function(talker, text, bTeamOnly)
        for _, listener in ipairs(player.GetAll()) do
            if not IVO_SAM.HasPermission(listener, "spectate") then continue end
            local isTracked = IsValid(listener.FreecamTarget) and listener.FreecamTarget == talker
            if isTracked then
                net.Start("Ivosam_Notify")
                    net.WriteEntity(talker)
                    net.WriteString(" dijo: " .. text)
                    net.WriteEntity(talker)
                    net.WriteBool(false)
                    net.WriteString("")
                net.Send(listener)
            end
        end
    end)

    hook.Add("PlayerConsoleCommand", "IVO_FreecamSpyConsole", function(ply, command, args)
        for _, listener in ipairs(player.GetAll()) do
            if IVO_SAM.HasPermission(listener, "spectate") and IsValid(listener.FreecamTarget) and listener.FreecamTarget == ply then
                net.Start("Ivosam_Notify")
                    net.WriteEntity(ply)
                    net.WriteString(" ejecutó: " .. command .. " " .. table.concat(args, " "))
                    net.WriteEntity(ply)
                    net.WriteBool(false)
                    net.WriteString("")
                net.Send(listener)
            end
        end
    end)
    -- HOOK DE VOZ: Escuchar a los jugadores cerca de la cámara
    hook.Add("PlayerCanHearPlayersVoice", "Ivosam_FreecamVoiceProximity", function(listener, talker)
        if not IsValid(listener) or not IsValid(talker) then return end
        if IVO_SAM.HasPermission(listener, "spectate") then
            local isTracked = IsValid(listener.FreecamTarget) and listener.FreecamTarget == talker
            if isTracked then
                return true, true
            end
        end
    end)

    -- HOOK DE TEXTO: Leer el chat local/proximidad cerca de la cámara
    hook.Add("PlayerCanSeePlayersChat", "Ivosam_FreecamTextProximity", function(text, bTeamOnly, listener, talker)
        if not IsValid(listener) or not IsValid(talker) then return end
        if bTeamOnly then return end -- Permitir que el chat de equipo normal siga sus reglas
        
        if IVO_SAM.HasPermission(listener, "spectate") then
            local isTracked = IsValid(listener.FreecamTarget) and listener.FreecamTarget == talker
            if isTracked then
                return true
            end
        end
    end)
end
-- ============================================================================
-- LADO CLIENTE
-- ============================================================================
if CLIENT then
    include("sam/core/sh_util.lua")
    include("sam/core/cl_init.lua")
    include("sam/ui/cl_menu.lua")
    include("sam/systems/tickets/cl_admin_chat.lua")
    include("sam/systems/tickets/cl_tickets_menu.lua")

    -- CARGAR SUB-COMANDOS (SHARED/CLIENT)
    my_admin = my_admin or {}
    my_admin.commands = my_admin.commands or {}
    my_admin.commandMeta = my_admin.commandMeta or {}
    my_admin.RegisterCommand = my_admin.RegisterCommand or function(name, callback, meta)
        name = string.lower(name)
        my_admin.commands[name] = callback
        if meta then my_admin.commandMeta[name] = meta end
    end

    local archivos, _ = file.Find("sam/commands/*.lua", "LUA")
    if archivos then
        for _, archivo in ipairs(archivos) do
            include("sam/commands/" .. archivo)
        end
    end

    local meta = FindMetaTable("Player")
    function meta:GetPlayTime() return self:GetNWInt("IVO_Playtime", 0) end

    -- Fix para el Menú Q: Recargar cuando SAM asigna el rango de admin
    hook.Add("EntityNetworkedVarChanged", "SAM_ReloadSpawnmenu", function(ent, name, old, new)
        if ent == LocalPlayer() and name == "UserGroup" and old ~= new then
            RunConsoleCommand("spawnmenu_reload")
        end
    end)
    
    -- HUD DE NOTIFICACIONES WEB
    local activeWebNotifs = {}
    
    net.Receive("IVO_Web_HUD_Notify", function()
        local plyName = net.ReadString()
        local msg = net.ReadString()
        -- surface.PlaySound("garrysmod/save_load1.wav") -- Quitado por peticion del usuario (era muy fuerte)
        surface.PlaySound("buttons/lightswitch2.wav") -- Sonido mucho más sutil y suave        
        table.insert(activeWebNotifs, {
            name = plyName,
            text = msg,
            time = CurTime() + 8 -- Se muestra por 8 segundos
        })
    end)
    
    surface.CreateFont("IVO_WebNotifTitle", { font = "Orbitron", size = 20, weight = 800 })
    surface.CreateFont("IVO_WebNotifText", { font = "Rajdhani", size = 18, weight = 600 })
    
    hook.Add("HUDPaint", "IVO_DrawWebNotificationsHUD", function()
        if #activeWebNotifs == 0 then return end
        
        local x = ScrW() - 20
        local y = 150
        
        for i = #activeWebNotifs, 1, -1 do
            local notif = activeWebNotifs[i]
            local timeLeft = notif.time - CurTime()
            
            if timeLeft <= 0 then
                table.remove(activeWebNotifs, i)
                continue
            end
            
            -- Animación de Fade In / Fade Out
            local alpha = 255
            if timeLeft > 7.5 then
                alpha = math.Clamp((8 - timeLeft) * 2 * 255, 0, 255)
            elseif timeLeft < 0.5 then
                alpha = math.Clamp(timeLeft * 2 * 255, 0, 255)
            end
            
            local w = 380
            local h = 75
            
            -- Fondo y Borde lateral
            draw.RoundedBox(6, x - w, y, w, h, Color(15, 20, 30, alpha * 0.95))
            draw.RoundedBoxEx(6, x - w, y, 6, h, Color(0, 229, 255, alpha), true, false, true, false)
            
            -- Textos
            draw.SimpleText("¡ACTUALIZACIÓN DE MERCADO!", "IVO_WebNotifTitle", x - w + 20, y + 12, Color(0, 229, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(notif.text, "IVO_WebNotifText", x - w + 20, y + 40, Color(255, 255, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            y = y + h + 15
        end
    end)
end

-- ============================================================================
-- PERMISOS (SHARED)
-- ============================================================================
function IVO_SAM.HasPermission(ply, permissionID)
    if not IsValid(ply) then return false end
    if ply:IsSuperAdmin() then return true end
    
    local rankName = ply:GetUserGroup()
    if IVO_SAM.Ranks[rankName] and IVO_SAM.Ranks[rankName].permissions then
        if IVO_SAM.Ranks[rankName].permissions[permissionID] then return true end
    end

    local secRankName = ply:GetNWString("SecondaryRank", "")
    if secRankName ~= "" and IVO_SAM.Ranks and IVO_SAM.Ranks[secRankName] and IVO_SAM.Ranks[secRankName].permissions then
        if IVO_SAM.Ranks[secRankName].permissions[permissionID] then return true end
    end

    return false
end
