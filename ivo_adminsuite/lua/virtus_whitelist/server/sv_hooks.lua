VirtusWhitelist = VirtusWhitelist or {}

-- Wrap customCheck after DarkRP loads all jobs
hook.Add("PostGamemodeLoaded", "VirtusWhitelist_OverrideCustomChecks", function()
    timer.Simple(1, function()
        for teamNum, jobTable in pairs(RPExtraTeams) do
            local oldCheck = jobTable.customCheck
            local job_cmd = jobTable.command

            jobTable.customCheck = function(ply)
                -- Asegurarnos de que el jugador existe
                if not IsValid(ply) then return false end
                
                local steamid = ply:SteamID()
                local status = VirtusWhitelist.GetPlayerStatus(steamid, job_cmd)

                -- Si es superadmin, ignoramos restricciones y permitimos acceso total
                if ply:IsSuperAdmin() then
                    return true
                end

                -- 1. Si está en la blacklist, bloqueamos directamente
                if status == "blacklist" then
                    jobTable.CustomCheckFailMsg = "Estás en la blacklist de este trabajo."
                    return false
                end

                -- 2. Si está en la whitelist, permitimos el acceso (bypasseando otros checks si los hubiera)
                if status == "whitelist" then
                    return true
                end

                -- 3. Si no está ni en whitelist ni en blacklist:
                if oldCheck then
                    -- Si el trabajo YA tenía un customCheck, lo evaluamos.
                    -- Si el usuario puso un customCheck para restringirlo por defecto (ej. return false), 
                    -- esto lo respetará y el jugador no podrá usarlo (tal como pidió el usuario).
                    local passed = oldCheck(ply)
                    if not passed then
                        jobTable.CustomCheckFailMsg = jobTable.CustomCheckFailMsg or "No tienes acceso a este trabajo."
                        return false
                    end
                    return true
                else
                    -- 4. Si el trabajo no tiene customCheck original, es público.
                    return true
                end
            end
        end
    end)
end)

hook.Add("PlayerInitialSpawn", "VirtusWhitelist_SyncClient", function(ply)
    local steamid = ply:SteamID()
    for job_cmd, lists in pairs(VirtusWhitelist.Cache) do
        if lists.whitelist[steamid] then
            ply:SetNWBool("VirtusWL_" .. job_cmd, true)
        end
    end
end)
