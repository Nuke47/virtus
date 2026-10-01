util.AddNetworkString("IvoQuest_AcceptMission")
util.AddNetworkString("IvoQuest_TurnInMission")
util.AddNetworkString("IvoQuest_SyncTracker")
util.AddNetworkString("IvoQuest_SyncWaypoint") 

IVO_QUEST = IVO_QUEST or {}
IVO_QUEST.Zones = IVO_QUEST.Zones or {}

function IVO_QUEST.SyncTracker(ply)
    net.Start("IvoQuest_SyncTracker")
    if ply.IvoQuest_Active then
        net.WriteBool(true)
        net.WriteString(ply.IvoQuest_Active.ID)
        net.WriteInt(ply.IvoQuest_Active.Progress, 32)
        net.WriteString(ply.IvoQuest_Active.Status)
        net.WriteUInt(ply.IvoQuest_Active.StageIdx or 1, 8)
        net.WriteUInt(ply.IvoQuest_Active.EndTime or 0, 32)
    else
        net.WriteBool(false)
    end
    net.Send(ply)
    IVO_QUEST.SyncWaypoint(ply)
end

function IVO_QUEST.AdvanceStage(ply)
    if not ply.IvoQuest_Active then return end
    local mData = MISSION_SYSTEM.Missions[ply.IvoQuest_Active.ID]
    if not mData then return end
    
    ply.IvoQuest_Active.StageIdx = (ply.IvoQuest_Active.StageIdx or 1) + 1
    ply.IvoQuest_Active.Progress = 0
    ply.IvoQuest_Active.SpawnedEnemies = false
    
    if mData.Stages and ply.IvoQuest_Active.StageIdx > #mData.Stages then
        if mData.Config and mData.Config.RequireReturn or mData.RequireReturn then
            ply.IvoQuest_Active.Status = "ready"
            ply:ChatPrint("[Quest] Todos los objetivos completados. Vuelve al punto de entrega.")
        else
            ply:ChatPrint("[Quest] ¡Misión Completada!")
            IVO_QUEST.FinishPlayerMission(ply, ply.IvoQuest_Active.ID)
        end
    else
        ply:ChatPrint("[Quest] Etapa completada. Siguiente objetivo marcado en el mapa.")
    end
    
    IVO_QUEST.SyncTracker(ply)
    timer.Simple(5, function() if IVO_QUEST.UpdateReceptors then IVO_QUEST.UpdateReceptors() end end)
end

function IVO_QUEST.SyncWaypoint(ply)
    net.Start("IvoQuest_SyncWaypoint")
    if ply.IvoQuest_Active then
        local mData = MISSION_SYSTEM.Missions[ply.IvoQuest_Active.ID]
        local hasWaypoint = false
        local waypointPos = Vector(0,0,0)
        local targetName = "Objetivo"

        if mData then
            local sIdx = ply.IvoQuest_Active.StageIdx or 1
            local cStage = mData.Stages and mData.Stages[sIdx]
            local sType = cStage and cStage.Type or mData.Type
            local sTarget = cStage and cStage.Target or mData.TargetNPC or mData.Target
            local sZone = cStage and cStage.SpawnZone or mData.SpawnZone

            if ply.IvoQuest_Active.Status == "active" then
                if sType == "kill" and sZone and IVO_QUEST.Zones[sZone] then
                    local z = IVO_QUEST.Zones[sZone]
                    waypointPos = (z.min + z.max) / 2 
                    hasWaypoint = true
                    targetName = cStage and cStage.ObjectiveText or "Zona Enemiga"
                elseif (sType == "goto" or sType == "zone_wait" or sType == "defend") and sTarget and IVO_QUEST.Zones[sTarget] then
                    local z = IVO_QUEST.Zones[sTarget]
                    waypointPos = (z.min + z.max) / 2 
                    hasWaypoint = true
                    if sType == "goto" then targetName = cStage and cStage.ObjectiveText or "Ir a Zona"
                    elseif sType == "zone_wait" then targetName = cStage and cStage.ObjectiveText or "Zona de Espera"
                    elseif sType == "defend" then targetName = cStage and cStage.ObjectiveText or "Zona a Defender" end
                elseif sType == "delivery" and sTarget then
                    for _, ent in ipairs(ents.FindByClass("npc_quest_giver")) do
                        if ent:GetNWString("MissionID") == sTarget then
                            waypointPos = ent:GetPos() + Vector(0, 0, 75) 
                            hasWaypoint = true
                            targetName = "Punto de Entrega"
                            break
                        end
                    end
                end
            elseif ply.IvoQuest_Active.Status == "ready" then
                for _, ent in ipairs(ents.FindByClass("npc_quest_giver")) do
                    if ent:GetNWString("MissionID") == ply.IvoQuest_Active.ID then
                        waypointPos = ent:GetPos() + Vector(0, 0, 75) 
                        hasWaypoint = true
                        targetName = "Punto de Entrega Final"
                        break
                    end
                end
            end
        end
        net.WriteBool(hasWaypoint)
        if hasWaypoint then
            net.WriteVector(waypointPos)
            net.WriteString(targetName)
        end
    else
        net.WriteBool(false)
    end
    net.Send(ply)
end

function IVO_QUEST.UpdateReceptors()
    if IVO_QUEST.AdminVisionActive then return end
    
    for _, ent in ipairs(ents.FindByClass("npc_quest_giver")) do
        local missionID = ent:GetNWString("MissionID")
        if not missionID or missionID == "" then continue end
        
        local baseMissionIDs = string.Explode(",", string.Replace(missionID, " ", ""))
        local isReceptor = false
        local shouldBeVisible = false
        local isTalkOverride = false
        local talkStageData = nil
        
        for mID, mData in pairs(MISSION_SYSTEM.Missions) do
            if mData.Stages then
                for stgIdx, stage in ipairs(mData.Stages) do
                    local isTarget = false
                    if (stage.Type == "delivery" or stage.Type == "talk") then for _, bID in ipairs(baseMissionIDs) do if stage.Target == bID then isTarget = true break end end end
                    
                    if isTarget then
                        isReceptor = true
                        for _, ply in ipairs(player.GetAll()) do
                            if ply.IvoQuest_Active and ply.IvoQuest_Active.ID == mID then
                                local plyStage = ply.IvoQuest_Active.StageIdx or 1
                                local hideUntil = stage.HideUntilStage
                                if hideUntil == nil then hideUntil = true end
                                
                                if hideUntil then
                                    if plyStage == stgIdx then shouldBeVisible = true end
                                else
                                    shouldBeVisible = true
                                end
                            end
                        end
                    end
                end
            elseif mData.Type == "delivery" then
                local isTarget = false
                for _, bID in ipairs(baseMissionIDs) do if mData.TargetNPC == bID then isTarget = true break end end
                if isTarget then
                    isReceptor = true
                    for _, ply in ipairs(player.GetAll()) do if ply.IvoQuest_Active and ply.IvoQuest_Active.ID == mID then shouldBeVisible = true break end end
                end
            end
        end
        
        if isReceptor then
            if ent.ForceVisibleUntil and CurTime() < ent.ForceVisibleUntil then
                shouldBeVisible = true
                if ent.ForcedTalkData then
                    isTalkOverride = true
                    talkStageData = ent.ForcedTalkData
                end
            elseif ent.ForceVisibleUntil and CurTime() >= ent.ForceVisibleUntil then
                ent.ForceVisibleUntil = nil
                ent.ForcedTalkData = nil
            end

            if isTalkOverride and talkStageData then
                if talkStageData.TalkModel and talkStageData.TalkModel ~= "" then ent:SetModel(talkStageData.TalkModel) end
                if talkStageData.TalkBodygroups and talkStageData.TalkBodygroups ~= "" then
                    ent:SetNWString("Bodygroups", talkStageData.TalkBodygroups)
                    local bgs = string.Explode(";", talkStageData.TalkBodygroups); for _, bg in ipairs(bgs) do local parts = string.Explode(":", bg) if #parts == 2 then ent:SetBodygroup(tonumber(parts[1]), tonumber(parts[2])) end end
                end
                
                local tGesture = talkStageData.TalkGesture or "none"
                if ent:GetNWString("CurrentGesture") ~= tGesture then
                    ent:SetNWString("CurrentGesture", tGesture)
                    IVO_QUEST.ApplyGesture(ent, tGesture)
                end
            else
                -- Restauramos la postura por defecto
                local mData = MISSION_SYSTEM.Missions[missionID]
                local defGest = ent:GetNWString("Gesture", "none")
                if mData and mData.Config and mData.Config.Gesture then defGest = mData.Config.Gesture end
                
                if ent:GetNWString("CurrentGesture") ~= defGest then
                    ent:SetNWString("CurrentGesture", defGest)
                    IVO_QUEST.ApplyGesture(ent, defGest)
                end
            end
            
            if shouldBeVisible then ent:UpdateVisibility(true) else ent:UpdateVisibility(false) end
        end
    end
end

-- NUEVA MAGIA: ENEMIGOS INSTANCIADOS PARA EL JUGADOR
function IVO_QUEST.SpawnMissionEntities(ply, missionID, stageData)
    local mData = MISSION_SYSTEM.Missions[missionID]
    if not mData then return end
    
    local spawnZone = stageData and stageData.SpawnZone or mData.SpawnZone
    local spawnEnt = stageData and stageData.SpawnEntity or mData.SpawnEntity
    if not spawnEnt or spawnEnt == "" then
        if stageData and stageData.Type == "kill" then spawnEnt = stageData.Target end
    end
    if not spawnZone or not spawnEnt then return end
    
    local isInstanced = stageData and stageData.Instanced or mData.Instanced
    
    local amount = 1
    if stageData and stageData.SpawnCount and stageData.SpawnCount > 0 then amount = stageData.SpawnCount
    elseif stageData and (stageData.Type == "defend" or stageData.Type == "zone_wait") then amount = 3
    else amount = stageData and stageData.Amount or mData.ReqAmount or 1 end
    
    for i = 1, amount do
        local spawnPos = IVO_QUEST.GetRandomPosInZone(spawnZone)
        if spawnPos then
            local ent = ents.Create(spawnEnt)
            if IsValid(ent) then
                ent:SetPos(spawnPos)
                ent:Spawn()
                ent:DropToFloor()

                if isInstanced then
                    ent.IvoQuest_Owner = ply -- Asignamos dueño
                    -- Ocultamos a todos excepto al dueño
                    for _, p in ipairs(player.GetAll()) do
                        if p ~= ply then ent:SetPreventTransmit(p, true) end
                    end
                    -- Si es un NPC, le decimos que solo persiga al dueño
                    if ent:IsNPC() then
                        ent:AddEntityRelationship(ply, D_HT, 99)
                    end
                end
            end
        end
    end
end

-- Gancho de Colisiones para que los demás jugadores no choquen con los monstruos instanciados
hook.Add("ShouldCollide", "IvoQuest_InstancedCollisions", function(ent1, ent2)
    if ent1.IvoQuest_Owner and ent1.IvoQuest_Owner:IsPlayer() then
        if ent2:IsPlayer() and ent2 ~= ent1.IvoQuest_Owner then return false end
    end
    if ent2.IvoQuest_Owner and ent2.IvoQuest_Owner:IsPlayer() then
        if ent1:IsPlayer() and ent1 ~= ent2.IvoQuest_Owner then return false end
    end
end)

function IVO_QUEST.FinishPlayerMission(ply, missionID)
    local mData = MISSION_SYSTEM.Missions[missionID]
    if not mData then return end

    local isRepeatable = (mData.Config and mData.Config.IsRepeatable) or mData.IsRepeatable

    if isRepeatable then
        local cd = (mData.Config and mData.Config.RepeatCooldown) or mData.RepeatCooldown or 300 
        ply:SetPData("IvoQuest_Cooldown_" .. missionID, os.time() + cd)
        -- Limpiamos el completado por si el admin cambió la misión de única a repetible recientemente
        ply:RemovePData("IvoQuest_Completed_" .. missionID)
    else
        ply:SetPData("IvoQuest_Completed_" .. missionID, "true")
        local nextMission = (mData.Config and mData.Config.NextMission) or mData.NextMission
        if nextMission and nextMission ~= "" then
            local cd = (mData.Config and mData.Config.Cooldown) or mData.Cooldown or 0
            ply:SetPData("IvoQuest_Cooldown_" .. nextMission, os.time() + cd)
        end
    end

    -- Entregar Recompensas configuradas en el VGUI Editor
    if mData.Config and mData.Config.Rewards then
        local rewards = mData.Config.Rewards
        
        -- Dinero (Soporte para DarkRP)
        if rewards.Money and tonumber(rewards.Money) > 0 then
            if ply.addMoney then
                ply:addMoney(tonumber(rewards.Money))
                DarkRP.notify(ply, 0, 4, "Has recibido $" .. rewards.Money .. " por completar la misión.")
            end
        end
        
        -- Vida
        if rewards.Health and tonumber(rewards.Health) > 0 then
            ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + tonumber(rewards.Health)))
            ply:ChatPrint("[Quest] Has recuperado " .. rewards.Health .. " puntos de vida.")
        end
        
        -- Arma
        if rewards.Weapon and rewards.Weapon ~= "" then
            ply:Give(rewards.Weapon)
            ply:ChatPrint("[Quest] Has recibido: " .. rewards.Weapon)
        end
    end

    if mData.OnComplete then mData.OnComplete(ply) end
    ply.IvoQuest_Active = nil
    IVO_QUEST.SyncTracker(ply)
end

timer.Create("IvoQuest_ServerTasks", 1, 0, function()
    IVO_QUEST.UpdateReceptors()
    
    for _, ply in ipairs(player.GetAll()) do
        if ply.IvoQuest_Active and ply.IvoQuest_Active.Status == "active" then
            if ply.IvoQuest_Active.EndTime and ply.IvoQuest_Active.EndTime > 0 and os.time() >= ply.IvoQuest_Active.EndTime then
                ply.IvoQuest_Active = nil
                IVO_QUEST.SyncTracker(ply)
                ply:ChatPrint("[Quest] ¡Se ha agotado el tiempo de la misión! Has fallado.")
                if IVO_QUEST.UpdateReceptors then IVO_QUEST.UpdateReceptors() end
                continue
            end
            
            local mData = MISSION_SYSTEM.Missions[ply.IvoQuest_Active.ID]
            if not mData then continue end
            
            local stageIdx = ply.IvoQuest_Active.StageIdx or 1
            local cStage = mData.Stages and mData.Stages[stageIdx]
            local sType = cStage and cStage.Type or mData.Type
            
            if sType == "goto" then
                local zName = cStage and cStage.Target or mData.Target
                if zName and IVO_QUEST.Zones[zName] then
                    local z = IVO_QUEST.Zones[zName]
                    local center = (z.min + z.max) / 2
                    if ply:GetPos():Distance(center) < 200 or IVO_QUEST.IsPosInZone(ply:GetPos(), zName) then
                        IVO_QUEST.AdvanceStage(ply)
                    end
                end
            elseif sType == "zone_wait" or sType == "defend" then
                local zName = cStage and cStage.Target or mData.Target
                if zName and IVO_QUEST.Zones[zName] and IVO_QUEST.IsPosInZone(ply:GetPos(), zName) then
                    if sType == "defend" and not ply.IvoQuest_Active.SpawnedEnemies then
                        ply.IvoQuest_Active.SpawnedEnemies = true
                        IVO_QUEST.SpawnMissionEntities(ply, ply.IvoQuest_Active.ID, cStage)
                        ply:ChatPrint("[Quest] ¡Estás en la zona! Sobrevive al ataque.")
                    end
                    
                    ply.IvoQuest_Active.Progress = (ply.IvoQuest_Active.Progress or 0) + 1
                    local req = cStage and cStage.Amount or mData.ReqAmount or 0
                    if ply.IvoQuest_Active.Progress >= req then
                        IVO_QUEST.AdvanceStage(ply)
                    else
                        IVO_QUEST.SyncTracker(ply)
                    end
                end
            elseif sType == "kill" and not ply.IvoQuest_Active.SpawnedEnemies then
                local sZone = cStage and cStage.SpawnZone or mData.SpawnZone
                if sZone and IVO_QUEST.Zones[sZone] then
                    local z = IVO_QUEST.Zones[sZone]
                    local center = (z.min + z.max) / 2
                    
                    if ply:GetPos():Distance(center) < 1500 then
                        ply.IvoQuest_Active.SpawnedEnemies = true
                        IVO_QUEST.SpawnMissionEntities(ply, ply.IvoQuest_Active.ID, cStage)
                        ply:ChatPrint("[Quest] ¡Cuidado! Los enemigos están en la zona.")
                    end
                end
            end
        end
    end
end)

net.Receive("IvoQuest_AcceptMission", function(len, ply)
    local missionID = net.ReadString()
    local mData = MISSION_SYSTEM.Missions[missionID]
    local eTime = 0
    if mData and mData.Config and mData.Config.TimeLimit and tonumber(mData.Config.TimeLimit) > 0 then eTime = os.time() + tonumber(mData.Config.TimeLimit) end
    
    ply.IvoQuest_Active = { ID = missionID, Progress = 0, Status = "active", SpawnedEnemies = false, StageIdx = 1, EndTime = eTime }
    IVO_QUEST.SyncTracker(ply)
    ply:ChatPrint("¡Misión iniciada! Sigue el marcador en tu pantalla.")
    IVO_QUEST.UpdateReceptors()
end)

net.Receive("IvoQuest_TurnInMission", function(len, ply)
    if ply.IvoQuest_Active then
        local mData = MISSION_SYSTEM.Missions[ply.IvoQuest_Active.ID]
        local cStage = mData and mData.Stages and mData.Stages[ply.IvoQuest_Active.StageIdx or 1]
        local sType = cStage and cStage.Type or (mData and mData.Type)
        local isDelivery = (sType == "delivery")

        if ply.IvoQuest_Active.Status == "ready" then
            IVO_QUEST.FinishPlayerMission(ply, ply.IvoQuest_Active.ID)
            timer.Simple(5, function()
                if IVO_QUEST.UpdateReceptors then IVO_QUEST.UpdateReceptors() end
            end)
        elseif ply.IvoQuest_Active.Status == "active" and isDelivery then
            IVO_QUEST.AdvanceStage(ply)
        end
    end
end)

hook.Add("OnNPCKilled", "IvoQuest_TrackKills", function(npc, attacker, inflictor)
    if IsValid(attacker) and attacker:IsPlayer() and attacker.IvoQuest_Active then
        local qData = attacker.IvoQuest_Active
        if qData.Status == "active" then
            local mData = MISSION_SYSTEM.Missions[qData.ID]
            local cStage = mData.Stages and mData.Stages[qData.StageIdx or 1]
            local isInstanced = cStage and cStage.Instanced or mData.Instanced
            
            if isInstanced and npc.IvoQuest_Owner and npc.IvoQuest_Owner ~= attacker then return end

            local sType = cStage and cStage.Type or mData.Type
            local sTarget = cStage and cStage.Target or mData.Target
            local sReq = cStage and cStage.Amount or mData.ReqAmount or 1

            if sType == "kill" and npc:GetClass() == sTarget then
                qData.Progress = qData.Progress + 1
                if qData.Progress >= sReq then
                    IVO_QUEST.AdvanceStage(attacker)
                else
                    IVO_QUEST.SyncTracker(attacker)
                end
            end
        end
    end
end)

hook.Add("PlayerDeath", "IvoQuest_FailOnDeath", function(victim, inflictor, attacker)
    if IsValid(victim) and victim:IsPlayer() and victim.IvoQuest_Active then
        local mData = MISSION_SYSTEM.Missions[victim.IvoQuest_Active.ID]
        victim.IvoQuest_Active = nil
        IVO_QUEST.SyncTracker(victim)
        victim:ChatPrint("[Quest] Has fallado la misión. Inténtalo de nuevo.")
        IVO_QUEST.UpdateReceptors()
    end
end)

hook.Add("PlayerDisconnected", "IvoQuest_CleanupOnDisconnect", function(ply)
    if ply.IvoQuest_Active then
        ply.IvoQuest_Active = nil
        IVO_QUEST.UpdateReceptors()
    end
end)

util.AddNetworkString("IvoQuest_AdvanceTalk")
net.Receive("IvoQuest_AdvanceTalk", function(len, ply)
    if ply.IvoQuest_Active then
        local mData = MISSION_SYSTEM.Missions[ply.IvoQuest_Active.ID]
        local cStage = mData and mData.Stages and mData.Stages[ply.IvoQuest_Active.StageIdx or 1]
        if cStage and cStage.Type == "talk" then
            local target = cStage.Target
            if target then
                for _, ent in ipairs(ents.FindByClass("npc_quest_giver")) do
                    local bIDs = string.Explode(",", string.Replace(ent:GetNWString("MissionID"), " ", ""))
                    for _, bID in ipairs(bIDs) do
                        if bID == target then
                            ent.ForceVisibleUntil = CurTime() + 5
                            ent.ForcedTalkData = cStage
                        end
                    end
                end
            end
            IVO_QUEST.AdvanceStage(ply)
        end
    end
end)