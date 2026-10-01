IVO_QUEST = IVO_QUEST or {}
IVO_QUEST.UnassignedNPCs = IVO_QUEST.UnassignedNPCs or {}

IVO_QUEST.Gestures = {
    ["crossed_arms"] = {
        ["ValveBiped.Bip01_R_Forearm"] = Angle(-43.779933929443,-107.18412780762,15.918969154358),
        ["ValveBiped.Bip01_R_UpperArm"] = Angle(20.256689071655, -57.223915100098, -6.1269416809082),
        ["ValveBiped.Bip01_L_UpperArm"] = Angle(-28.913911819458, -59.408206939697, 1.0253102779388),
        ["ValveBiped.Bip01_R_Thigh"] = Angle(4.7250719070435, -6.0294013023376, -0.46876749396324),
        ["ValveBiped.Bip01_L_Thigh"] = Angle(-7.6583762168884, -0.21996378898621, 0.4060270190239),
        ["ValveBiped.Bip01_L_Forearm"] = Angle(51.038677215576, -120.44165039063, -18.86986541748),
        ["ValveBiped.Bip01_R_Hand"] = Angle(14.424224853516, -33.406204223633, -7.2624106407166),
        ["ValveBiped.Bip01_L_Hand"] = Angle(25.959447860718, 31.564517974854, -14.979378700256),
    },
    ["crossed_arms_behind"] = {
        ["ValveBiped.Bip01_R_UpperArm"] = Angle(3.809, 15.382, 2.654),
        ["ValveBiped.Bip01_R_Forearm"] = Angle(-63.658, 1.8 , -84.928),
        ["ValveBiped.Bip01_L_UpperArm"] = Angle(3.809, 15.382, 2.654),
        ["ValveBiped.Bip01_L_Forearm"] = Angle(53.658, -29.718, 31.455),
        ["ValveBiped.Bip01_R_Thigh"] = Angle(4.829, 0, 0),
        ["ValveBiped.Bip01_L_Thigh"] = Angle(-8.89, 0, 0),
    }
}

function IVO_QUEST.ApplyGesture(ent, gestureID)
    if not IsValid(ent) then return end
    for i = 0, ent:GetBoneCount() - 1 do ent:ManipulateBoneAngles(i, Angle(0,0,0)) end
    
    local targetSeq = -1
    
    if gestureID == "sit" then
        targetSeq = ent:LookupSequence("sit")
    else
        targetSeq = ent:LookupSequence("idle_subtle")
        if targetSeq == -1 then targetSeq = ent:LookupSequence("idle_unarmed") end
        if targetSeq == -1 then targetSeq = ent:LookupSequence("idle_all_01") end
        if targetSeq == -1 then targetSeq = ent:LookupSequence("idle1") end
        if targetSeq == -1 then targetSeq = ent:LookupSequence("idle") end
    end
    
    if targetSeq ~= -1 then 
        ent:ResetSequence(targetSeq) 
    end

    if gestureID and gestureID ~= "sit" and IVO_QUEST.Gestures[gestureID] then
        for boneName, ang in pairs(IVO_QUEST.Gestures[gestureID]) do
            local boneID = ent:LookupBone(boneName)
            if boneID then ent:ManipulateBoneAngles(boneID, ang) end
        end
    end
end

function IVO_QUEST.SaveNPCs()
    local npc_data = {}
    for _, ent in ipairs(ents.FindByClass("npc_quest_giver")) do
        table.insert(npc_data, {
            pos = ent:GetPos(), ang = ent:GetAngles(), model = ent:GetModel(), mission = ent:GetNWString("MissionID"),
            bodygroups = ent:GetNWString("Bodygroups", ""), receptorText = ent:GetNWString("ReceptorText", ""), gesture = ent:GetNWString("Gesture", "none")
        })
    end
    for _, data in ipairs(IVO_QUEST.UnassignedNPCs) do
        table.insert(npc_data, {
            mission = data.mission, model = data.model, bodygroups = data.bodygroups, 
            receptorText = data.receptorText, gesture = data.gesture or "none", unassigned = true
        })
    end
    file.CreateDir("ivo_quest")
    file.Write("ivo_quest/" .. game.GetMap() .. ".json", util.TableToJSON(npc_data, true))
    print("[Ivo_quest] Archivo JSON actualizado con todos los NPCs activos.")
end

function IVO_QUEST.LoadNPCs()
    local fileName = "ivo_quest/" .. game.GetMap() .. ".json"
    if not file.Exists(fileName, "DATA") then return end
    
    local npc_data = util.JSONToTable(file.Read(fileName, "DATA")) or {}
    IVO_QUEST.UnassignedNPCs = {}
    
    for _, data in ipairs(npc_data) do
        if data.unassigned then
            table.insert(IVO_QUEST.UnassignedNPCs, { mission = data.mission, model = data.model, bodygroups = data.bodygroups, receptorText = data.receptorText, gesture = data.gesture, unassigned = true })
            continue
        end
        
        local ent = ents.Create("npc_quest_giver")
        ent:SetPos(data.pos)
        ent:SetAngles(data.ang)
        ent:Spawn()
        
        -- Aplicar MissionID
        ent:SetNWString("MissionID", data.mission)
        
        -- Aplicar el modelo basándose en la misión (si la misión existe)
        local mData = MISSION_SYSTEM.Missions[data.mission]
        if mData and mData.Config and mData.Config.Model then
            ent:SetModel(mData.Config.Model)
        elseif data.model then
            -- Si no hay misión, usar el modelo que tenía guardado antes
            ent:SetModel(data.model)
        end
        
        if mData and mData.Config and mData.Config.Bodygroups and mData.Config.Bodygroups ~= "" then
            ent:SetNWString("Bodygroups", mData.Config.Bodygroups)
            local bgs = string.Explode(";", mData.Config.Bodygroups)
            for _, bg in ipairs(bgs) do
                local parts = string.Explode(":", bg)
                if #parts == 2 then ent:SetBodygroup(tonumber(parts[1]), tonumber(parts[2])) end
            end
        elseif data.bodygroups and data.bodygroups ~= "" then
            ent:SetNWString("Bodygroups", data.bodygroups)
            local bgs = string.Explode(";", data.bodygroups)
            for _, bg in ipairs(bgs) do
                local parts = string.Explode(":", bg)
                if #parts == 2 then ent:SetBodygroup(tonumber(parts[1]), tonumber(parts[2])) end
            end
        end
        
        local defaultGesture = data.gesture or "none"
        if mData and mData.Config and mData.Config.Gesture and mData.Config.Gesture ~= "none" then 
            defaultGesture = mData.Config.Gesture 
        end
        
        ent:PhysicsInit(SOLID_BBOX)
        ent:SetMoveType(MOVETYPE_STEP)

        timer.Simple(2, function()
            if IsValid(ent) then
                ent:SetNWString("CurrentGesture", defaultGesture)
                IVO_QUEST.ApplyGesture(ent, defaultGesture)
            end
        end)
    end
end
hook.Add("InitPostEntity", "Ivo_quest_LoadMapNPCs", IVO_QUEST.LoadNPCs)

concommand.Add("ivo_npc_save", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    IVO_QUEST.SaveNPCs()
    if IsValid(ply) then ply:ChatPrint("[Ivo_quest] ¡Todos los NPCs actuales han sido GUARDADOS permanentemente!") end
end)

concommand.Add("ivo_npc_reload", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    for _, ent in ipairs(ents.FindByClass("npc_quest_giver")) do ent:Remove() end
    timer.Simple(0.2, function()
        IVO_QUEST.LoadNPCs()
        if IsValid(ply) then ply:ChatPrint("[Ivo_quest] ¡Base de datos recargada!") end
    end)
end)

-- COMANDO MEJORADO: Acepta un modelo opcional y un ID de entidad (para edición remota)
concommand.Add("ivo_set_id", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    
    local newID = args[1]
    local customModel = args[2]
    local bodygroups = args[3] or ""
    local targetEntID = tonumber(args[4])
    local receptorText = args[5] or ""
    local gesture = args[6] or "none"
    
    local target = nil
    if targetEntID then
        target = Entity(targetEntID)
    else
        target = ply:GetEyeTrace().Entity
    end
    
    if not newID or not IsValid(target) or target:GetClass() ~= "npc_quest_giver" then
        ply:ChatPrint("Uso: ivo_set_id [id_mision] (asegúrate de mirar al NPC o editar desde el menú)")
        return
    end

    local mData = MISSION_SYSTEM.Missions[newID]

    -- 2. Aplicamos ID y Modelo
    target:SetNWString("MissionID", newID)
    target:SetNWString("ReceptorText", receptorText)
    target:SetNWString("Gesture", gesture)
    
    if customModel and customModel ~= "" then
        target:SetModel(customModel)
    elseif mData and mData.Config and mData.Config.Model then
        target:SetModel(mData.Config.Model)
    end
    
    if bodygroups ~= "" then
        target:SetNWString("Bodygroups", bodygroups)
        local bgs = string.Explode(";", bodygroups)
        for _, bg in ipairs(bgs) do
            local parts = string.Explode(":", bg)
            if #parts == 2 then target:SetBodygroup(tonumber(parts[1]), tonumber(parts[2])) end
        end
    else
        target:SetNWString("Bodygroups", "")
        target:SetBodyGroups("0")
    end
    
    local defGest = gesture
    if mData and mData.Config and mData.Config.Gesture and mData.Config.Gesture ~= "none" then 
        defGest = mData.Config.Gesture 
    end
    target:SetNWString("CurrentGesture", defGest)
    IVO_QUEST.ApplyGesture(target, defGest)

    -- 3. Forzamos actualización física (Crucial para que el modelo cambie bien)
    target:PhysicsInit(SOLID_BBOX)
    target:SetMoveType(MOVETYPE_STEP)
    
    -- 4. Guardamos en el JSON para que sea persistente
    IVO_QUEST.SaveNPCs()
    
    -- 5. Actualizamos los receptores para que el NPC recién vinculado se vuelva invisible inmediatamente
    if IVO_QUEST.UpdateReceptors then IVO_QUEST.UpdateReceptors() end
    
    local msgType = mData and "Misión" or "Receptor Genérico"
    ply:ChatPrint("[Ivo_quest] NPC vinculado a '" .. newID .. "' (" .. msgType .. ").")
end)

IVO_QUEST.AdminVisionActive = false
concommand.Add("ivo_admin_reveal", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    IVO_QUEST.AdminVisionActive = not IVO_QUEST.AdminVisionActive
    local estado = IVO_QUEST.AdminVisionActive
    
    for _, ent in ipairs(ents.FindByClass("npc_quest_giver")) do
        if estado then
            if ent.UpdateVisibility then ent:UpdateVisibility(true) end
        end
    end
    
    if not estado then
        if IVO_QUEST.UpdateReceptors then IVO_QUEST.UpdateReceptors() end
    end
    
    ply:ChatPrint("[Ivo_quest] Visión de Administrador " .. (estado and "ACTIVADA" or "DESACTIVADA"))
end)

hook.Add("CanTool", "IvoQuest_ProtectNPCs", function(ply, tr, tool)
    if tool == "remover" then
        local ent = tr.Entity
        if IsValid(ent) and ent:GetClass() == "npc_quest_giver" then
            if not ply:IsSuperAdmin() then
                if SERVER then ply:ChatPrint("[Ivo_quest] Permiso Denegado.") end
                return false
            end
        end
    end
end)

util.AddNetworkString("IvoQuest_RequestReceptors")
util.AddNetworkString("IvoQuest_SendReceptors")

net.Receive("IvoQuest_RequestReceptors", function(len, ply)
    if not ply:IsSuperAdmin() then return end
    
    local npcs = {}
    for _, ent in ipairs(ents.FindByClass("npc_quest_giver")) do
        table.insert(npcs, {
            id = ent:GetNWString("MissionID", "Desconocido"),
            pos = ent:GetPos(),
            ang = ent:GetAngles(),
            model = ent:GetModel(),
            entID = ent:EntIndex(),
            bodygroups = ent:GetNWString("Bodygroups", ""),
            receptorText = ent:GetNWString("ReceptorText", ""),
            gesture = ent:GetNWString("Gesture", "none"),
            isUnassigned = false
        })
    end
    
    for i, data in ipairs(IVO_QUEST.UnassignedNPCs) do
        table.insert(npcs, {
            id = data.mission,
            pos = Vector(0,0,0),
            ang = Angle(0,0,0),
            model = data.model,
            entID = "unassigned_" .. i,
            bodygroups = data.bodygroups,
            receptorText = data.receptorText or "",
            gesture = data.gesture or "none",
            isUnassigned = true
        })
    end
    
    net.Start("IvoQuest_SendReceptors")
    net.WriteTable(npcs)
    net.Send(ply)
end)

concommand.Add("ivo_tp_receptor", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local entID = tonumber(args[1])
    if not entID then return end
    
    local ent = Entity(entID)
    if IsValid(ent) and ent:GetClass() == "npc_quest_giver" then
        local forward = ent:GetForward()
        ply:SetPos(ent:GetPos() + forward * 50 + Vector(0, 0, 5))
        ply:SetEyeAngles((-forward):Angle())
        ply:ChatPrint("[Ivo_quest] Teletransportado frente al NPC con éxito.")
    else
        ply:ChatPrint("[Ivo_quest] Error: El NPC ya no existe en el mapa.")
    end
end)

concommand.Add("ivo_npc_remove", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local entID = tonumber(args[1])
    if not entID then return end
    
    local ent = Entity(entID)
    if IsValid(ent) and ent:GetClass() == "npc_quest_giver" then
        ent:Remove()
        IVO_QUEST.SaveNPCs()
        ply:ChatPrint("[Ivo_quest] NPC eliminado con éxito.")
    end
end)

concommand.Add("ivo_create_unassigned", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    local newID = args[1]
    local customModel = args[2]
    local bodygroups = args[3] or ""
    local updateIdx = tonumber(args[4])
    local receptorText = args[5] or ""
    local gesture = args[6] or "none"
    
    if not newID or newID == "" then return end
    
    if updateIdx and IVO_QUEST.UnassignedNPCs[updateIdx] then
        IVO_QUEST.UnassignedNPCs[updateIdx].mission = newID
        IVO_QUEST.UnassignedNPCs[updateIdx].model = customModel
        IVO_QUEST.UnassignedNPCs[updateIdx].bodygroups = bodygroups
        IVO_QUEST.UnassignedNPCs[updateIdx].receptorText = receptorText
        IVO_QUEST.UnassignedNPCs[updateIdx].gesture = gesture
    else
        table.insert(IVO_QUEST.UnassignedNPCs, { mission = newID, model = customModel, bodygroups = bodygroups, receptorText = receptorText, gesture = gesture, unassigned = true })
    end
    
    IVO_QUEST.SaveNPCs()
    ply:ChatPrint("[Ivo_quest] Perfil '" .. newID .. "' guardado sin asignar.")
end)

concommand.Add("ivo_unassigned_remove", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local idx = tonumber(args[1])
    if not idx then return end
    
    if IVO_QUEST.UnassignedNPCs and IVO_QUEST.UnassignedNPCs[idx] then
        table.remove(IVO_QUEST.UnassignedNPCs, idx)
        IVO_QUEST.SaveNPCs()
        ply:ChatPrint("[Ivo_quest] Perfil eliminado con éxito.")
    end
end)

concommand.Add("ivo_unassigned_spawn", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    local idx = tonumber(args[1])
    if not idx then return end
    
    local data = IVO_QUEST.UnassignedNPCs and IVO_QUEST.UnassignedNPCs[idx]
    if data then
        local tr = ply:GetEyeTrace()
        local ent = ents.Create("npc_quest_giver")
        ent:SetPos(tr.HitPos)
        ent:SetAngles(Angle(0, ply:EyeAngles().y - 180, 0))
        ent:Spawn()
        
        ent:SetNWString("MissionID", data.mission)
        if data.receptorText then ent:SetNWString("ReceptorText", data.receptorText) end
        ent:SetNWString("Gesture", data.gesture or "none")
        if data.model and data.model ~= "" then ent:SetModel(data.model) end
        if data.bodygroups and data.bodygroups ~= "" then
            ent:SetNWString("Bodygroups", data.bodygroups)
            local bgs = string.Explode(";", data.bodygroups)
            for _, bg in ipairs(bgs) do
                local parts = string.Explode(":", bg)
                if #parts == 2 then ent:SetBodygroup(tonumber(parts[1]), tonumber(parts[2])) end
            end
        end
        
        
        ent:PhysicsInit(SOLID_BBOX)
        ent:SetMoveType(MOVETYPE_STEP)
        
        local targetGesture = data.gesture or "none"
        timer.Simple(0.5, function()
            if IsValid(ent) then
                ent:SetNWString("CurrentGesture", targetGesture)
                IVO_QUEST.ApplyGesture(ent, targetGesture)
            end
        end)
        
        table.remove(IVO_QUEST.UnassignedNPCs, idx)
        IVO_QUEST.SaveNPCs()
        if IVO_QUEST.UpdateReceptors then IVO_QUEST.UpdateReceptors() end
        ply:ChatPrint("[Ivo_quest] NPC '" .. data.mission .. "' spawneado y asignado exitosamente.")
    end
end)