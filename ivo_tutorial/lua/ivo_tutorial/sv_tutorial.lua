util.AddNetworkString("Tutorial_StartCinematic")
util.AddNetworkString("Tutorial_UpdateDimension")
util.AddNetworkString("Tutorial_StaffEnter")
util.AddNetworkString("Tutorial_CinematicDone")
util.AddNetworkString("Tutorial_Finish")
util.AddNetworkString("Tutorial_Step_Weapon")
util.AddNetworkString("Tutorial_SpawnTargets")
util.AddNetworkString("Tutorial_TargetsSpawned")
util.AddNetworkString("Tutorial_TargetKilled")

local activeTutorials = {}
local activeStaffHelpers = {}

local function startTutorial(ply)
    ply:SetNWBool("InTutorial", true)
    ply:SetCustomCollisionCheck(true)
    ply:SetNWVector("Tutorial_FixedPos", ply:GetPos())
    ply:StripWeapons()
    
    activeTutorials[ply] = true
    
    for k, v in ipairs(player.GetAll()) do
        if v ~= ply then
            ply:SetPreventTransmit(v, true)
            v:SetPreventTransmit(ply, true)
        end
    end
    
    net.Start("Tutorial_UpdateDimension")
    net.WriteBool(true)
    net.Send(ply)
end

local function finishTutorial(ply)
    if not activeTutorials[ply] then return end
    
    activeTutorials[ply] = nil
    ply:SetNWBool("InTutorial", false)
    ply:SetNWBool("VIRTUS_NeedsTutorial", false)
    ply:SetNWVector("Tutorial_FixedPos", Vector(0,0,0))
    
    -- Cleanup targets
    if ply.TutorialTargets then
        for _, t in ipairs(ply.TutorialTargets) do
            if IsValid(t) then t:Remove() end
        end
        ply.TutorialTargets = nil
    end
    
        for k, v in ipairs(player.GetAll()) do
        if v ~= ply then
            ply:SetPreventTransmit(v, false)
            v:SetPreventTransmit(ply, false)
        end
    end
    
    net.Start("Tutorial_UpdateDimension")
    net.WriteBool(false)
    net.Send(ply)
    
    timer.Simple(0.1, function()
        if IsValid(ply) then
            if SW_InvShop and SW_InvShop.GiveActiveWeapons then
                SW_InvShop.GiveActiveWeapons(ply)
                SW_InvShop.ApplyLoadout(ply)
            else
                hook.Run("PlayerLoadout", ply)
            end
        end
    end)
end

hook.Add("PlayerInitialSpawn", "Tutorial_CheckFirstTime", function(ply)
    ply:SetNWBool("VIRTUS_NeedsTutorial", true)

    timer.Simple(5, function()
        if not IsValid(ply) then return end
        
        ply:StripWeapons() -- Strip just before cinematic
        ply:SetNWBool("VIRTUS_FirstTime", true)
        startTutorial(ply)
        net.Start("Tutorial_StartCinematic")
        net.Send(ply)
    end)
end)

net.Receive("Tutorial_CinematicDone", function(len, ply)
    -- Just for backwards compat if needed
end)

net.Receive("Tutorial_Finish", function(len, ply)
    finishTutorial(ply)
end)

net.Receive("Tutorial_Step_Weapon", function(len, ply)
    if ply:GetNWBool("InTutorial") and not ply:HasWeapon("tfa_swch_dc15a") then
        local wep = ply:Give("tfa_swch_dc15a")
        ply:GiveAmmo(300, wep:GetPrimaryAmmoType() or "ar2")
        ply:SelectWeapon("tfa_swch_dc15a")
    end
end)

net.Receive("Tutorial_SpawnTargets", function(len, ply)
    if not ply:GetNWBool("InTutorial") then return end
    if ply.TutorialTargets then return end -- Already spawned
    
    ply.TutorialTargets = {}
    local pos = ply:GetPos()
    local fwd = ply:GetForward()
    local right = ply:GetRight()
    
    local offsets = {
        fwd * 300,
        fwd * 300 + right * 150,
        fwd * 300 - right * 150
    }
    
    for i, off in ipairs(offsets) do
        local target = ents.Create("npc_combine_s")
        target:SetPos(pos + off)
        target:SetAngles((pos - (pos + off)):Angle())
        target:Spawn()
        target:SetHealth(10)
        target:SetNoDraw(false)
        target.IsTutorialTarget = true
        target.TutorialOwner = ply
        
        -- Make them dummy
        target:SetNPCState(NPC_STATE_IDLE)
        target:CapabilitiesClear()
        target:SetMoveType(MOVETYPE_NONE)
        
        table.insert(ply.TutorialTargets, target)
    end
    
    net.Start("Tutorial_TargetsSpawned")
    net.Send(ply)
end)

hook.Add("EntityTakeDamage", "Tutorial_TargetDamage", function(target, dmginfo)
    if target.IsTutorialTarget then
        if target:Health() - dmginfo:GetDamage() <= 0 then
            local ply = target.TutorialOwner
            if IsValid(ply) then
                net.Start("Tutorial_TargetKilled")
                net.Send(ply)
            end
        end
    end
end)

hook.Add("PlayerSpawn", "Tutorial_PreventSpawnReset", function(ply)
    if ply:GetNWBool("VIRTUS_NeedsTutorial") then
        timer.Simple(0.1, function()
            if IsValid(ply) and ply:GetNWBool("VIRTUS_NeedsTutorial") then
                ply:StripWeapons()
            end
        end)
    end
end)

hook.Add("ShouldCollide", "Tutorial_NoCollide", function(ent1, ent2)
    if ent1:IsPlayer() and ent1:GetNWBool("InTutorial") and ent2:IsPlayer() then return false end
    if ent2:IsPlayer() and ent2:GetNWBool("InTutorial") and ent1:IsPlayer() then return false end
end)

hook.Add("PlayerShouldTakeDamage", "Tutorial_NoDamage", function(ply, attacker)
    if ply:GetNWBool("InTutorial") then return false end
end)

hook.Add("EntityTakeDamage", "Tutorial_NoEntDamage", function(ent, dmg)
    local att = dmg:GetAttacker()
    if att:IsPlayer() and att:GetNWBool("InTutorial") and not ent.IsTutorialTarget then
        return true -- block damage to anything else
    end
end)



concommand.Add("tutorial_force_start", function(ply)
    if IsValid(ply) then
        ply:StripWeapons()
        ply:SetNWBool("VIRTUS_NeedsTutorial", true)
        ply:SetNWBool("VIRTUS_FirstTime", true)
        startTutorial(ply)
        net.Start("Tutorial_StartCinematic")
        net.Send(ply)
    end
end)

hook.Add("FinishMove", "Tutorial_Treadmill_SV", function(ply, mv)
    if ply:GetNWBool("InTutorial") then
        local fixedPos = ply.Tutorial_FixedPos or ply:GetNWVector("Tutorial_FixedPos", Vector(0,0,0))
        if fixedPos ~= Vector(0,0,0) then
            if mv:KeyDown(IN_JUMP) or not ply:IsOnGround() then 
                ply.Tutorial_WasJumping = true
                return 
            end
            
            if ply.Tutorial_WasJumping then
                ply.Tutorial_WasJumping = false
                local newPos = mv:GetOrigin()
                ply.Tutorial_FixedPos = newPos
                ply:SetNWVector("Tutorial_FixedPos", newPos)
                return
            end
            
            local org = mv:GetOrigin()
            org.x = fixedPos.x
            org.y = fixedPos.y
            mv:SetOrigin(org)
        end
    end
end)




