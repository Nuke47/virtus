import sys

path = r'd:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\ivosam\lua\autorun\sh_init.lua'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

start_marker = '    function IVO_SAM.ForzarGuardadoSQL(p)'
end_marker = '    net.Receive("IVO_RequestHistoryData", function(len, ply)'

start_idx = text.find(start_marker)
end_idx = text.find(end_marker)

if start_idx == -1 or end_idx == -1:
    print("Markers not found!")
    sys.exit(1)

new_code = '''    function IVO_SAM.ForzarGuardadoSQL(p)
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

'''

text = text[:start_idx] + new_code + text[end_idx:]
with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print("Fixed successfully")
