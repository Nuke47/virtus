util.AddNetworkString("VirtusWhitelist_OpenMenu")
util.AddNetworkString("VirtusWhitelist_RequestData")
util.AddNetworkString("VirtusWhitelist_SendData")
util.AddNetworkString("VirtusWhitelist_AddPlayer")
util.AddNetworkString("VirtusWhitelist_RemovePlayer")

VirtusWhitelist = VirtusWhitelist or {}

-- Command to open the menu
hook.Add("PlayerSay", "VirtusWhitelist_ChatCommand", function(ply, text)
    if string.lower(text) == "!whitelist" or string.lower(text) == "!jobaccess" then
        if ply:IsAdmin() or ply:IsSuperAdmin() then
            net.Start("VirtusWhitelist_OpenMenu")
            net.Send(ply)
        else
            DarkRP.notify(ply, 1, 4, "No tienes permisos para abrir este menú.")
        end
        return ""
    end
end)

-- Send data to client when requested
net.Receive("VirtusWhitelist_RequestData", function(len, ply)
    if not (ply:IsAdmin() or ply:IsSuperAdmin()) then return end

    local job_cmd = net.ReadString()
    local data = VirtusWhitelist.GetJobLists(job_cmd)

    net.Start("VirtusWhitelist_SendData")
    net.WriteString(job_cmd)
    
    -- Send Whitelist
    local wlCount = table.Count(data.whitelist)
    net.WriteUInt(wlCount, 16)
    for steamid, _ in pairs(data.whitelist) do
        net.WriteString(steamid)
    end

    -- Send Blacklist
    local blCount = table.Count(data.blacklist)
    net.WriteUInt(blCount, 16)
    for steamid, _ in pairs(data.blacklist) do
        net.WriteString(steamid)
    end

    net.Send(ply)
end)

-- Receive Add Player request
net.Receive("VirtusWhitelist_AddPlayer", function(len, ply)
    if not (ply:IsAdmin() or ply:IsSuperAdmin()) then return end

    local steamid = net.ReadString()
    local job_cmd = net.ReadString()
    local list_type = net.ReadString() -- "whitelist" or "blacklist"

    if not steamid or steamid == "" or not job_cmd or job_cmd == "" then return end

    VirtusWhitelist.AddPlayer(steamid, job_cmd, list_type)
    DarkRP.notify(ply, 0, 4, "Se actualizó la lista para " .. steamid .. " en el trabajo " .. job_cmd)

    -- Refresh the client who sent it (or we could broadcast to all admins)
    local data = VirtusWhitelist.GetJobLists(job_cmd)
    
    net.Start("VirtusWhitelist_SendData")
    net.WriteString(job_cmd)
    
    local wlCount = table.Count(data.whitelist)
    net.WriteUInt(wlCount, 16)
    for sid, _ in pairs(data.whitelist) do
        net.WriteString(sid)
    end

    local blCount = table.Count(data.blacklist)
    net.WriteUInt(blCount, 16)
    for sid, _ in pairs(data.blacklist) do
        net.WriteString(sid)
    end
    net.Send(ply)
end)

-- Receive Remove Player request
net.Receive("VirtusWhitelist_RemovePlayer", function(len, ply)
    if not (ply:IsAdmin() or ply:IsSuperAdmin()) then return end

    local steamid = net.ReadString()
    local job_cmd = net.ReadString()
    local list_type = net.ReadString() -- "whitelist" or "blacklist"

    if not steamid or steamid == "" or not job_cmd or job_cmd == "" then return end

    VirtusWhitelist.RemovePlayer(steamid, job_cmd, list_type)
    DarkRP.notify(ply, 0, 4, "Se eliminó a " .. steamid .. " de la lista " .. list_type)

    -- Refresh the client
    local data = VirtusWhitelist.GetJobLists(job_cmd)
    
    net.Start("VirtusWhitelist_SendData")
    net.WriteString(job_cmd)
    
    local wlCount = table.Count(data.whitelist)
    net.WriteUInt(wlCount, 16)
    for sid, _ in pairs(data.whitelist) do
        net.WriteString(sid)
    end

    local blCount = table.Count(data.blacklist)
    net.WriteUInt(blCount, 16)
    for sid, _ in pairs(data.blacklist) do
        net.WriteString(sid)
    end
    net.Send(ply)
end)
