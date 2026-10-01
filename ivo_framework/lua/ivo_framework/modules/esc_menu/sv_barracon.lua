if not SERVER then return end

util.AddNetworkString("Virtus_Barracon_ApplyLoadout")

net.Receive("Virtus_Barracon_ApplyLoadout", function(len, ply)
    local bgs = net.ReadTable()
    local weps = net.ReadTable()
    
    ply.Barracon_BGs = bgs
    ply.Barracon_Weps = weps
end)

hook.Add("PlayerSpawn", "Virtus_Barracon_RespawnApplier", function(ply)
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        
        -- Apply BGs
        if ply.Barracon_BGs then
            for bgId, bgVal in pairs(ply.Barracon_BGs) do
                ply:SetBodygroup(bgId, bgVal)
            end
        end
        
        -- Apply Weapons (Loadout)
        if ply.Barracon_Weps then
            for wclass, enabled in pairs(ply.Barracon_Weps) do
                if enabled then
                    ply:Give(wclass)
                end
            end
        end
    end)
end)

-- Make sure we don't strip the loadout after they spawn
hook.Add("PlayerLoadout", "Virtus_Barracon_EnsureLoadout", function(ply)
    timer.Simple(0.15, function()
        if not IsValid(ply) then return end
        if ply.Barracon_Weps then
            for wclass, enabled in pairs(ply.Barracon_Weps) do
                if enabled and not ply:HasWeapon(wclass) then
                    ply:Give(wclass)
                end
            end
        end
    end)
end)
