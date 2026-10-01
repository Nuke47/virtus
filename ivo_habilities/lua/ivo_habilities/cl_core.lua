IVO_HABILITIES = IVO_HABILITIES or {}
IVO_HABILITIES.ClientPoints = IVO_HABILITIES.ClientPoints or {}
IVO_HABILITIES.ClientSkills = IVO_HABILITIES.ClientSkills or {}

net.Receive("IVO_Habilities_Sync", function()
    IVO_HABILITIES.ClientPoints = net.ReadTable() or {}
    
    local seq = net.ReadTable() or {}
    IVO_HABILITIES.ClientSkills = {}
    for _, v in ipairs(seq) do
        IVO_HABILITIES.ClientSkills[v] = true
    end
end)

function IVO_HABILITIES.HasUnspentPoints()
    for _, pts in pairs(IVO_HABILITIES.ClientPoints) do
        if pts > 0 then return true end
    end
    return false
end
