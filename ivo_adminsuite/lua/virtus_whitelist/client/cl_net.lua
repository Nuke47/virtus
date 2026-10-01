VirtusWhitelist = VirtusWhitelist or {}
VirtusWhitelist.JobData = VirtusWhitelist.JobData or {}

net.Receive("VirtusWhitelist_OpenMenu", function()
    VirtusWhitelist.OpenMenu()
end)

net.Receive("VirtusWhitelist_SendData", function()
    local job_cmd = net.ReadString()
    
    local wlCount = net.ReadUInt(16)
    local whitelist = {}
    for i = 1, wlCount do
        table.insert(whitelist, net.ReadString())
    end

    local blCount = net.ReadUInt(16)
    local blacklist = {}
    for i = 1, blCount do
        table.insert(blacklist, net.ReadString())
    end

    VirtusWhitelist.JobData[job_cmd] = {
        whitelist = whitelist,
        blacklist = blacklist
    }

    if IsValid(VirtusWhitelist.Menu) then
        if VirtusWhitelist.RefreshListUI then
            VirtusWhitelist.RefreshListUI()
        end
    end
end)
