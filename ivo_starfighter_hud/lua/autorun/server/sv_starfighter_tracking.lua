--[[
    Starfighter HUD - Server-Side Tracking System
    Handles target detection, lock-on mechanics, and data broadcasting for LVS vehicles.
]]--

util.AddNetworkString("StarfighterHUD_LockTarget")
util.AddNetworkString("StarfighterHUD_UnlockTarget")
util.AddNetworkString("StarfighterHUD_TrackingData")

-- ConVars
local cv_enabled = CreateConVar("starfighter_hud_enabled", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable Starfighter HUD system")
local cv_track_range = CreateConVar("starfighter_hud_tracking_range", "15000", {FCVAR_ARCHIVE}, "Max range to track entities")
local cv_lock_range = CreateConVar("starfighter_hud_lock_range", "20000", {FCVAR_ARCHIVE}, "Max range to maintain target lock")

-- Helper to get the actual LVS vehicle from a player
local function GetLVSVehicle(ply)
    if not IsValid(ply) or not ply:InVehicle() then return nil end
    
    local pod = ply:GetVehicle()
    if not IsValid(pod) then return nil end

    -- LVS Base entity is typically the parent of the pod
    local parent = pod:GetParent()
    if IsValid(parent) and (parent.LVS or string.StartWith(parent:GetClass(), "lvs_")) then
        return parent
    end
    
    -- Fallback for LVS getter if available
    if ply.lvsGetVehicle then
        local lvsVeh = ply:lvsGetVehicle()
        if IsValid(lvsVeh) then return lvsVeh end
    end

    return nil
end

-- Helper to check if an entity is a valid target
local function IsValidTarget(ent, myVehicle)
    if not IsValid(ent) or ent == myVehicle then return false end
    
    -- Ignore dead targets
    if ent:IsPlayer() and not ent:Alive() then return false end
    if ent:IsNPC() and ent:Health() <= 0 then return false end

    -- Other LVS vehicles
    if ent.LVS or string.StartWith(ent:GetClass(), "lvs_") then return true end
    
    -- NPCs
    if ent:IsNPC() then return true end
    
    -- Players not in our vehicle
    if ent:IsPlayer() then
        if ent:InVehicle() then
            local targetVeh = GetLVSVehicle(ent)
            if targetVeh == myVehicle then return false end -- Same vehicle
        end
        return true
    end

    return false
end

-- Helper to determine if a target is friendly based on LVS AITEAM
local function IsFriendly(ent, myVehicle)
    local myTeam = myVehicle.GetAITEAM and myVehicle:GetAITEAM() or myVehicle.AITEAM or 0
    local targetTeam = ent.GetAITEAM and ent:GetAITEAM() or ent.AITEAM
    
    -- If target has no team, assume hostile/neutral
    if not targetTeam then return false end
    
    -- In LVS, 0 is typically neutral/none. If both have the same non-zero team, they are friendly.
    if myTeam ~= 0 and myTeam == targetTeam then
        return true
    end
    
    return false
end

-- Process target lock requests from clients
net.Receive("StarfighterHUD_LockTarget", function(len, ply)
    if not cv_enabled:GetBool() then return end
    
    local myVehicle = GetLVSVehicle(ply)
    if not IsValid(myVehicle) then return end
    
    -- Client can pass true to explicitly request an unlock
    local isUnlockRequest = net.ReadBool()
    if isUnlockRequest then
        ply._SFHUD_LockedTarget = nil
        net.Start("StarfighterHUD_UnlockTarget")
        net.Send(ply)
        return
    end

    -- Find nearest target in 30-degree cone (15 degrees off-center)
    local bestTarget = nil
    local bestDot = math.cos(math.rad(15)) 
    local maxDist = cv_track_range:GetFloat()
    local myPos = myVehicle:GetPos()
    local myFwd = myVehicle:GetForward()

    local entsInSphere = ents.FindInSphere(myPos, maxDist)
    for _, ent in ipairs(entsInSphere) do
        if IsValidTarget(ent, myVehicle) then
            local dir = (ent:GetPos() - myPos):GetNormalized()
            local dot = myFwd:Dot(dir)
            
            -- Prioritize targets closest to the center of our forward view
            if dot > bestDot then
                bestDot = dot
                bestTarget = ent
            end
        end
    end

    -- If we found a target, assign it and send back to client
    if IsValid(bestTarget) then
        ply._SFHUD_LockedTarget = bestTarget
        
        net.Start("StarfighterHUD_LockTarget")
        net.WriteEntity(bestTarget)
        net.Send(ply)
    end
end)

-- Main tracking loop
hook.Add("Think", "StarfighterHUD_TrackingLoop", function()
    if not cv_enabled:GetBool() then return end

    local curTime = CurTime()

    for _, ply in ipairs(player.GetAll()) do
        local myVehicle = GetLVSVehicle(ply)
        
        -- Reset tracking if player is not in an LVS vehicle
        if not IsValid(myVehicle) then
            if ply._SFHUD_LockedTarget then
                ply._SFHUD_LockedTarget = nil
                net.Start("StarfighterHUD_UnlockTarget")
                net.Send(ply)
            end
            ply._SFHUD_CachedTargets = nil
            continue
        end

        -- Initialize loop timers if nil
        ply._SFHUD_NextTrackTime = ply._SFHUD_NextTrackTime or curTime
        ply._SFHUD_NextDataTime = ply._SFHUD_NextDataTime or curTime

        -- 1. Scan and Target Maintenance Loop (Throttled to 0.2s)
        if curTime >= ply._SFHUD_NextTrackTime then
            ply._SFHUD_NextTrackTime = curTime + 0.2

            -- Maintain Lock Status
            if ply._SFHUD_LockedTarget then
                local target = ply._SFHUD_LockedTarget
                local shouldUnlock = false

                if not IsValid(target) then
                    shouldUnlock = true
                elseif target:IsPlayer() and not target:Alive() then
                    shouldUnlock = true
                elseif target:IsNPC() and target:Health() <= 0 then
                    shouldUnlock = true
                else
                    local distSqr = myVehicle:GetPos():DistToSqr(target:GetPos())
                    local lockRange = cv_lock_range:GetFloat()
                    if distSqr > (lockRange * lockRange) then
                        shouldUnlock = true
                    end
                end

                if shouldUnlock then
                    ply._SFHUD_LockedTarget = nil
                    net.Start("StarfighterHUD_UnlockTarget")
                    net.Send(ply)
                end
            end

            -- Cache nearby valid targets
            ply._SFHUD_CachedTargets = {}
            local myPos = myVehicle:GetPos()
            local trackRange = cv_track_range:GetFloat()

            for _, ent in ipairs(ents.FindInSphere(myPos, trackRange)) do
                if IsValidTarget(ent, myVehicle) then
                    table.insert(ply._SFHUD_CachedTargets, ent)
                end
            end
        end

        -- 2. Broadcast Data Loop (Throttled to 0.3s)
        if curTime >= ply._SFHUD_NextDataTime then
            ply._SFHUD_NextDataTime = curTime + 0.3
            
            if ply._SFHUD_CachedTargets then
                local myPos = myVehicle:GetPos()
                local maxSent = math.min(#ply._SFHUD_CachedTargets, 64) -- Limit data size
                
                net.Start("StarfighterHUD_TrackingData")
                net.WriteUInt(maxSent, 7)
                
                for i = 1, maxSent do
                    local ent = ply._SFHUD_CachedTargets[i]
                    if IsValid(ent) then
                        local dist = myPos:Distance(ent:GetPos())
                        local isFriendly = IsFriendly(ent, myVehicle)
                        
                        net.WriteEntity(ent)
                        net.WriteFloat(dist)
                        net.WriteBool(isFriendly)
                    else
                        -- Fallback for removed entities during cycle
                        net.WriteEntity(Entity(0))
                        net.WriteFloat(0)
                        net.WriteBool(false)
                    end
                end
                
                net.Send(ply)
            end
        end
    end
end)
