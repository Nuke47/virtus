-- ============================================================================
-- IVOSAM: UTILITIES & GLOBALS (ESTABLE Y PROTEGIDO CONTRA NIL VALUES)
-- ============================================================================
IVO_SAM = IVO_SAM or {}
my_admin = my_admin or {}

-- Creamos el puente seguro para SetUserRank si aún no se ha declarado en el init
my_admin.SetUserRank = my_admin.SetUserRank or function(target, rankName, expireTime, adminName)
    if not IsValid(target) or not IVO_SAM.Ranks[rankName] then return end
    local sid64 = target:SteamID64()
    expireTime = expireTime or 0
    adminName = adminName or "Console"

    target:SetNWString("UserGroup", rankName)
    target:SetUserGroup(rankName)

    local query = string.format(
        "REPLACE INTO ivosam_users (steamid64, `rank`, expire, admin, date) VALUES (%s, %s, %d, %s, %s);",
        IVO_SAM.DB.Escape(sid64), IVO_SAM.DB.Escape(rankName), expireTime, IVO_SAM.DB.Escape(adminName), IVO_SAM.DB.Escape(os.date("%d/%m/%Y"))
    )
    IVO_SAM.DB.Query(query)
end
IVO_SAM.SetUserRank = my_admin.SetUserRank

function IVO_SAM.FindPlayer(info)
    if not info or info == "" then return nil end
    info = string.lower(info)
    if info == "^" then return nil end 

    for _, v in ipairs(player.GetAll()) do
        if v:SteamID64() == info then return v end
        if string.lower(v:SteamID()) == info then return v end
        if string.find(string.lower(v:Nick()), info, 1, true) then
            return v
        end
    end
    return nil
end

function IVO_SAM.FindPlayers(info)
    local tbl = {}
    if not info or info == "" then return tbl end
    info = string.lower(info)

    for _, v in ipairs(player.GetAll()) do
        if v:SteamID64() == info or string.lower(v:SteamID()) == info or string.find(string.lower(v:Nick()), info, 1, true) then
            table.insert(tbl, v)
        end
    end
    return tbl
end

function IVO_SAM.Notify(admin, msg, target, isPublic, extra)
    if SERVER then
        local adminValidado = IsValid(admin) and admin or nil
        net.Start("Ivosam_Notify")
            net.WriteEntity(adminValidado)
            net.WriteString(msg)
            net.WriteEntity(target or adminValidado)
            net.WriteBool(isPublic or false)
            net.WriteString(tostring(extra or ""))
        
        if isPublic then
            net.Broadcast()
        else
            local admins = {}
            for _, v in ipairs(player.GetAll()) do
                if IVO_SAM.HasPermission(v, "menu") then table.insert(admins, v) end
            end
            if #admins > 0 then net.Send(admins) end
        end
    end
end

my_admin.FindPlayer = IVO_SAM.FindPlayer
my_admin.FindPlayers = IVO_SAM.FindPlayers
my_admin.Notify = IVO_SAM.Notify
IVO_SAM.Notify = my_admin.Notify