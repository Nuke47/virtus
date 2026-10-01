AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("IvoQuest_OpenMenu")
util.AddNetworkString("IvoQuest_CloseMenu")

function ENT:Initialize()
    self:SetNWString("MissionID", "default")
    local missionData = MISSION_SYSTEM.Missions[self:GetNWString("MissionID")]
    if missionData and missionData.Model then self:SetModel(missionData.Model) end
    
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:SetNPCState(NPC_STATE_SCRIPT)
    self:SetSolid(SOLID_BBOX)
    self:CapabilitiesAdd(CAP_ANIMATEDFACE + CAP_TURN_HEAD)
    self:SetUseType(SIMPLE_USE)
    self:DropToFloor()
end

function ENT:AcceptInput(name, activator, caller)
    if name == "Use" and IsValid(activator) and activator:IsPlayer() then
        if activator:GetNWBool("InQuestDialogue") then return end
        
        local missionIDStr = self:GetNWString("MissionID")
        local baseMissionIDs = string.Explode(",", string.Replace(missionIDStr, " ", ""))
        local activeTargetID = baseMissionIDs[1] or "default"
        
        -- 1. Verificar si viene a entregar un paquete PRIMERO
        if activator.IvoQuest_Active then
            local activeData = MISSION_SYSTEM.Missions[activator.IvoQuest_Active.ID]
            if activeData then
                local isDelivery = false
                
                local stageIdx = activator.IvoQuest_Active.StageIdx or 1
                if activeData.Stages and activeData.Stages[stageIdx] then
                    local s = activeData.Stages[stageIdx]
                    if (s.Type == "delivery" or s.Type == "talk") then
                        for _, bID in ipairs(baseMissionIDs) do
                            if s.Target == bID then
                                isDelivery = true
                                activeTargetID = bID
                                
                                if s.Type == "talk" then
                                    activator:Freeze(true)
                                    activator:SetNWBool("InQuestDialogue", true)
                                    net.Start("IvoQuest_OpenMenu")
                                        net.WriteString(activeTargetID)
                                        net.WriteEntity(self)
                                        net.WriteString("talk_stage")
                                    net.Send(activator)
                                    return 
                                end
                                break
                            end
                        end
                    end
                elseif not activeData.Stages and activeData.Type == "delivery" then
                    for _, bID in ipairs(baseMissionIDs) do
                        if activeData.TargetNPC == bID then isDelivery = true; activeTargetID = bID; break end
                    end
                end
                
                if isDelivery then
                    local rText = self:GetNWString("ReceptorText", "")
                    
                    if rText ~= "" then
                        activator:Freeze(true)
                        activator:SetNWBool("InQuestDialogue", true)
                        net.Start("IvoQuest_OpenMenu")
                            net.WriteString(activeTargetID)
                            net.WriteEntity(self)
                            net.WriteString("delivery_receptor")
                        net.Send(activator)
                    else
                        activator:ChatPrint("[Quest] ¡Paquete entregado con éxito!")
                        if IVO_QUEST and IVO_QUEST.FinishPlayerMission then
                            IVO_QUEST.FinishPlayerMission(activator, activator.IvoQuest_Active.ID)
                        end
                        self.ForceVisibleUntil = CurTime() + 5
                    end
                    return 
                end
            end
        end
        
        -- 2. LÓGICA DE CADENAS Y MÚLTIPLES MISIONES (Y JOBS)
        local targetMission = nil
        local isOnCooldown = false
        local cooldownTime = 0
        local jobFailed = false

        for _, startID in ipairs(baseMissionIDs) do
            local currentID = startID
            
            while true do
                local mData = MISSION_SYSTEM.Missions[currentID]
                if not mData then break end

                local allowedJobs = mData.Config and mData.Config.AllowedJobs or ""
                local canDoJob = true
                if allowedJobs ~= "" then
                    canDoJob = false
                    local pTeam = activator:Team()
                    local pJob = team.GetName(pTeam)
                    local pCat = (RPExtraTeams and RPExtraTeams[pTeam] and RPExtraTeams[pTeam].category) or ""
                    
                    local jobsList = string.Explode(",", allowedJobs)
                    for _, j in ipairs(jobsList) do
                        local cleanJ = string.Trim(j)
                        if cleanJ == pJob or cleanJ == pCat then canDoJob = true break end
                    end
                end

                local isRepeatable = (mData.Config and mData.Config.IsRepeatable) or mData.IsRepeatable
                local isCompleted = (not isRepeatable) and (activator:GetPData("IvoQuest_Completed_" .. currentID, "false") == "true")

                if not isCompleted then
                    if not canDoJob then jobFailed = true break end
                    
                    local cd = tonumber(activator:GetPData("IvoQuest_Cooldown_" .. currentID, "0")) or 0
                    if os.time() < cd then
                        isOnCooldown = true
                        cooldownTime = cd - os.time()
                        break 
                    else
                        targetMission = currentID
                        break 
                    end
                else
                    local nextMission = (mData.Config and mData.Config.NextMission) or mData.NextMission
                    if nextMission and nextMission ~= "" then
                        currentID = string.Trim(nextMission)
                    else
                        break 
                    end
                end
            end
            
            if targetMission then break end 
        end

        if not targetMission then
            if jobFailed then
                activator:ChatPrint("[Quest] No tienes la profesión necesaria para este encargo.")
            elseif isOnCooldown then
                local min = math.floor(cooldownTime / 60)
                local sec = cooldownTime % 60
                activator:ChatPrint("[Quest] Aún no tengo nada nuevo. Vuelve en " .. min .. "m " .. sec .. "s.")
            else
                activator:ChatPrint("[Quest] Ya no tengo más trabajo para ti por ahora.")
            end
            return
        end
        
        -- 3. Abrir el menú de diálogo
        local playerQuestState = "new" 
        if activator.IvoQuest_Active and activator.IvoQuest_Active.ID == targetMission then
            playerQuestState = activator.IvoQuest_Active.Status 
        elseif activator.IvoQuest_Active then
            activator:ChatPrint("Ya tienes una misión activa. Termínala primero.")
            return
        end
        
        self:SetAngles((activator:GetPos() - self:GetPos()):Angle())
        activator:SetEyeAngles((self:GetPos() - activator:GetPos()):Angle())
        activator:Freeze(true)
        activator:SetNWBool("InQuestDialogue", true)
        
        net.Start("IvoQuest_OpenMenu")
            net.WriteString(targetMission)
            net.WriteEntity(self)
            net.WriteString(playerQuestState) 
        net.Send(activator)
    end
end

function ENT:UpdateVisibility(visible)
    if visible then
        self:SetNoDraw(false)
        self:SetSolid(SOLID_BBOX)
        self:SetCollisionGroup(COLLISION_GROUP_NPC)
    else
        self:SetNoDraw(true)
        self:SetSolid(SOLID_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_NONE)
    end
end

net.Receive("IvoQuest_CloseMenu", function(len, ply)
    ply:Freeze(false)
    ply:SetNWBool("InQuestDialogue", false)
end)