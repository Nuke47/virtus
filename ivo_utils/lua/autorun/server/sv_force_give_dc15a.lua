for k, v in ipairs(player.GetAll()) do
    if v.SW_Data and v.SW_Data.active then
        -- Force give base_dc15a if they are a job that should have it
        local myTeam = v:Team()
        if myTeam and myTeam > 1 then
            local specialty = string.lower(SW_InvShop.GetJobSpecialty(myTeam) or "")
            local jobName = string.lower(team.GetName(myTeam) or "")
            for key, items in pairs(SW_InvShop.Config.StarterLoadouts) do
                local lKey = string.lower(key)
                if lKey == specialty or string.find(jobName, lKey) then
                    for _, itemID in ipairs(items) do
                        if itemID == "base_dc15a" then
                            if not v.SW_Data.active[itemID] and not v.SW_Data.armario[itemID] then
                                v.SW_Data.active[itemID] = 1
                                v:ChatPrint("[Sistema] Se ha forzado la entrega de tu DC-15A debido a un parche de categoria.")
                            end
                        end
                    end
                end
            end
            SW_InvShop.SaveCurrentActiveAsLoadoutToDB(v)
        end
    end
end
