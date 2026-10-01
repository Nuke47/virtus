if CLIENT then return end
util.AddNetworkString("VirtusStunState")
AddCSLuaFile("autorun/client/cl_virtus_stun.lua")

function VirtusKnockoutPlayer(ply, duration)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() or ply.IsVirtusStunned then return end
    
    ply.IsVirtusStunned = true

    -- Save state
    ply.VirtusStunWeps = {}
    for _, w in pairs(ply:GetWeapons()) do
        ply.VirtusStunWeps[w:GetClass()] = {
            clip1 = w:Clip1(),
            clip2 = w:Clip2()
        }
    end
    ply.VirtusStunActiveWep = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() or nil
    
    ply.VirtusStunAmmo = {}
    for _, ammoName in pairs(game.GetAmmoTypes()) do
        local count = ply:GetAmmoCount(ammoName)
        if count > 0 then
            ply.VirtusStunAmmo[ammoName] = count
        end
    end
    
    ply.VirtusStunHP = ply:Health()
    ply.VirtusStunArmor = ply:Armor()

    local plyVel = ply:GetVelocity()

    -- Create ragdoll
    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetModel(ply:GetModel())
    ragdoll:SetSkin(ply:GetSkin())
    for i = 0, ply:GetNumBodyGroups() - 1 do
        ragdoll:SetBodygroup(i, ply:GetBodygroup(i))
    end
    ragdoll:SetPos(ply:GetPos())
    ragdoll:SetAngles(ply:GetAngles())
    ragdoll:Spawn()
    ragdoll:Activate()
    ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    local physCount = ragdoll:GetPhysicsObjectCount()
    for i = 0, physCount - 1 do
        local phys = ragdoll:GetPhysicsObjectNum(i)
        if IsValid(phys) then
            local boneId = ragdoll:TranslatePhysBoneToBone(i)
            if boneId then
                local bp, ba = ply:GetBonePosition(boneId)
                if bp and ba then
                    phys:SetPos(bp)
                    phys:SetAngles(ba)
                end
            end
            phys:SetVelocity(plyVel)
        end
    end

    ply.VirtusStunRagdoll = ragdoll
    
    net.Start("VirtusStunState")
    net.WriteEntity(ragdoll)
    net.WriteFloat(duration)
    net.Broadcast()
    
    -- Lock player and hide them
    ply:SetNoDraw(true)
    ply:SetNotSolid(true)
    ply:Freeze(true)
    ply:GodEnable() 
    if IsValid(ply:GetActiveWeapon()) then
        ply:GetActiveWeapon():SetNoDraw(true)
    end

    ply:Spectate(OBS_MODE_CHASE)
    ply:SpectateEntity(ragdoll)

    timer.Create("VirtusUnstun_" .. ply:EntIndex(), duration, 1, function()
        if IsValid(ply) then
            ply.IsVirtusStunned = false
            ply:UnSpectate()
            
            -- Re-spawn to fix camera and observer mode physics bugs
            ply:Spawn()
            
            timer.Simple(0, function()
                if not IsValid(ply) then return end
                
                -- Restore stats
                ply:SetHealth(ply.VirtusStunHP or 100)
                ply:SetArmor(ply.VirtusStunArmor or 0)
                
                ply:StripWeapons()
                ply:StripAmmo()
                
                if ply.VirtusStunWeps then
                    for class, data in pairs(ply.VirtusStunWeps) do
                        local wep = ply:Give(class)
                        if IsValid(wep) then
                            wep:SetClip1(data.clip1)
                            wep:SetClip2(data.clip2)
                        end
                    end
                end
                
                if ply.VirtusStunActiveWep then
                    ply:SelectWeapon(ply.VirtusStunActiveWep)
                end
                
                if ply.VirtusStunAmmo then
                    for ammoName, count in pairs(ply.VirtusStunAmmo) do
                        ply:SetAmmo(count, ammoName)
                    end
                end
                
                if IsValid(ply.VirtusStunRagdoll) then
                    local targetPos = ply.VirtusStunRagdoll:GetPos()
                    ply.VirtusStunRagdoll:Remove()
                    ply:SetPos(targetPos + Vector(0, 0, 15))
                end

                ply:SetNoDraw(false)
                ply:SetNotSolid(false)
                ply:Freeze(false)
                ply:GodDisable()
            end)
        end
    end)
end

hook.Add("PlayerDeath", "VirtusStunCleanup", function(ply)
    if ply.IsVirtusStunned then
        ply.IsVirtusStunned = false
        if timer.Exists("VirtusUnstun_" .. ply:EntIndex()) then
            timer.Remove("VirtusUnstun_" .. ply:EntIndex())
        end
        if IsValid(ply.VirtusStunRagdoll) then
            ply.VirtusStunRagdoll:Remove()
        end
        ply:SetNoDraw(false)
        ply:SetNotSolid(false)
        ply:Freeze(false)
        ply:GodDisable()
    end
end)

hook.Add("PlayerDisconnected", "VirtusStunCleanupDisconnect", function(ply)
    if IsValid(ply.VirtusStunRagdoll) then
        ply.VirtusStunRagdoll:Remove()
    end
end)
