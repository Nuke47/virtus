IVO_QUEST = IVO_QUEST or {}
IVO_QUEST.InDialogue = false
IVO_QUEST.DialogueTarget = nil
IVO_QUEST.CurrentMissionID = nil
IVO_QUEST.CurrentMission = nil
IVO_QUEST.CameraState = "npc" 
IVO_QUEST.PlayerQuestState = "new" 
IVO_QUEST.ActiveMissionData = nil
IVO_QUEST.CurrentDialogueLine = 1 
IVO_QUEST.IsPreview = false 
IVO_QUEST.PreviewEditorFrame = nil
IVO_QUEST.PendingOption = nil

local dialogueFrame = nil
local hudAlpha = 0 

surface.CreateFont("IvoQuest_HUD_Text", { font = "Roboto", size = 16, weight = 500, antialias = true })
surface.CreateFont("IvoQuest_HUD_Key", { font = "Roboto", size = 15, weight = 900, antialias = true })
surface.CreateFont("IvoQuest_Dialog_Name", { font = "Roboto", size = 26, weight = 800, antialias = true })
surface.CreateFont("IvoQuest_Dialog_Text", { font = "Roboto", size = 22, weight = 400, antialias = true })
surface.CreateFont("IvoQuest_Dialog_Btn", { font = "Roboto", size = 18, weight = 600, antialias = true })
surface.CreateFont("IvoQuest_Tracker_Title", { font = "Roboto", size = 20, weight = 800, antialias = true })
surface.CreateFont("IvoQuest_Tracker_Obj", { font = "Roboto", size = 18, weight = 400, antialias = true })

net.Receive("IvoQuest_SyncTracker", function()
    local hasMission = net.ReadBool()
    if hasMission then
        IVO_QUEST.ActiveMissionData = { ID = net.ReadString(), Progress = net.ReadInt(32), Status = net.ReadString(), StageIdx = net.ReadUInt(8), EndTime = net.ReadUInt(32) }
    else IVO_QUEST.ActiveMissionData = nil end
end)

hook.Add("HUDPaint", "IvoQuest_DrawTracker", function()
    if not IVO_QUEST.ActiveMissionData or IVO_QUEST.InDialogue then return end
    
    local mData = MISSION_SYSTEM.Missions[IVO_QUEST.ActiveMissionData.ID]
    if not mData then return end
    
    local missionName = (mData.Config and mData.Config.Name) or mData.Name or "Misión Desconocida"
    local txtTitle = "MISIÓN ACTIVA: " .. string.upper(missionName)
    local txtObj = ""
    local objColor = Color(220, 220, 220)
    
    if IVO_QUEST.ActiveMissionData.Status == "active" then
        local currentStage = mData.Stages and mData.Stages[IVO_QUEST.ActiveMissionData.StageIdx or 1]
        local mType = currentStage and currentStage.Type or mData.Type or "unknown"
        local mTarget = currentStage and (currentStage.TargetName or currentStage.Target) or mData.TargetName or mData.Target or "Desconocido"
        local mReq = currentStage and currentStage.Amount or mData.ReqAmount or 0
        local objText = currentStage and currentStage.ObjectiveText or ""
        
        if mType == "kill" then
            if objText ~= "" then txtObj = objText .. " (" .. IVO_QUEST.ActiveMissionData.Progress .. "/" .. mReq .. ")"
            else txtObj = "Objetivo: Eliminar " .. mTarget .. " (" .. IVO_QUEST.ActiveMissionData.Progress .. "/" .. mReq .. ")" end
        elseif mType == "delivery" then
            if objText ~= "" then txtObj = objText else txtObj = "Objetivo: Entregar paquete a " .. mTarget end
        elseif mType == "goto" then
            if objText ~= "" then txtObj = objText else txtObj = "Objetivo: Dirígete a la zona " .. mTarget end
        elseif mType == "zone_wait" then
            if objText ~= "" then txtObj = objText
            else txtObj = "Objetivo: Espera en la zona" end
        elseif mType == "defend" then
            if objText ~= "" then txtObj = objText
            else txtObj = "Objetivo: Defiende la zona" end
        elseif mType == "talk" then
            if objText ~= "" then txtObj = objText
            else txtObj = "Objetivo: Habla con " .. mTarget end
        end
    elseif IVO_QUEST.ActiveMissionData.Status == "ready" then
        local npcName = (mData.Config and mData.Config.NPCName) or mData.NPCName or "NPC"
        txtObj = "Objetivo Completado: Vuelve con " .. npcName
        objColor = Color(100, 255, 100) 
    end
    
    local boxWidth = 360 
    local x = ScrW() - boxWidth - 20 
    local y = 130 
    
    local boxHeight = 70
    local timeStr = ""
    if IVO_QUEST.ActiveMissionData.Status == "active" and IVO_QUEST.ActiveMissionData.EndTime and IVO_QUEST.ActiveMissionData.EndTime > 0 then
        local timeLeft = math.max(0, IVO_QUEST.ActiveMissionData.EndTime - os.time())
        timeStr = string.format("%02d:%02d", math.floor(timeLeft / 60), timeLeft % 60)
        boxHeight = 95
    end
    
    draw.RoundedBox(6, x, y, boxWidth, boxHeight, Color(15, 15, 15, 200))
    draw.RoundedBox(0, x, y, 3, boxHeight, Color(200, 150, 0)) 
    draw.SimpleText(txtTitle, "IvoQuest_Tracker_Title", x + 15, y + 10, Color(255, 180, 50))
    draw.SimpleText(txtObj, "IvoQuest_Tracker_Obj", x + 15, y + 40, objColor)
    if timeStr ~= "" then
        draw.SimpleText("⏱ Tiempo Restante: " .. timeStr, "IvoQuest_Tracker_Obj", x + 15, y + 65, (IVO_QUEST.ActiveMissionData.EndTime - os.time() <= 30) and Color(255,80,80) or Color(200,200,200))
    end
end)

hook.Add("HUDPaint", "IvoQuest_ProximityPrompt", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or IVO_QUEST.InDialogue then hudAlpha = Lerp(FrameTime() * 10, hudAlpha, 0) return end
    local trace = ply:GetEyeTrace()
    local target = trace.Entity
    local shouldShow = false
    local npcData = nil

    if IsValid(target) and target:GetClass() == "npc_quest_giver" and ply:GetPos():Distance(target:GetPos()) < 110 then
        npcData = MISSION_SYSTEM.Missions[target:GetNWString("MissionID")] or MISSION_SYSTEM.Missions["default"]
        shouldShow = true
    end

    hudAlpha = shouldShow and Lerp(FrameTime() * 12, hudAlpha, 255) or Lerp(FrameTime() * 12, hudAlpha, 0)
    if hudAlpha < 1 then return end

    local text = "Hablar con " .. (npcData and npcData.NPCName or "NPC")
    surface.SetFont("IvoQuest_HUD_Text")
    local textW, textH = surface.GetTextSize(text)
    local keyW, keyH = 22, 22
    local padding = 10; local spacing = 8
    local boxW = padding * 2 + keyW + spacing + textW; local boxH = 34
    local x = (ScrW() - boxW) / 2; local y = (ScrH() / 2) + 60 

    draw.RoundedBox(6, x, y, boxW, boxH, Color(15, 15, 15, hudAlpha * 0.85))
    draw.RoundedBox(0, x + 5, y, boxW - 10, 1, Color(255, 255, 255, hudAlpha * 0.1))

    local keyX = x + padding; local keyY = y + (boxH - keyH) / 2
    draw.RoundedBox(4, keyX, keyY, keyW, keyH, Color(240, 240, 240, hudAlpha)) 
    draw.SimpleText("E", "IvoQuest_HUD_Key", keyX + (keyW / 2), keyY + (keyH / 2) - 1, Color(20, 20, 20, hudAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(text, "IvoQuest_HUD_Text", keyX + keyW + spacing, y + (boxH / 2), Color(230, 230, 230, hudAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end)

hook.Add("CalcView", "IvoQuest_CinematicCamera", function(ply, pos, angles, fov)
    if not IVO_QUEST.InDialogue or not IsValid(IVO_QUEST.DialogueTarget) then return end
    local view = { fov = 45, drawviewer = true }
    local targetEnt = (IVO_QUEST.CameraState == "npc") and IVO_QUEST.DialogueTarget or ply
    local targetPos = targetEnt:GetPos() + Vector(0, 0, 60)
    local forward = targetEnt:GetForward()
    view.origin = targetPos + forward * 45 + targetEnt:GetRight() * 15
    view.angles = (targetPos - view.origin):Angle()
    return view
end)

local function CloseDialogue()
    if IsValid(dialogueFrame) then dialogueFrame:Remove() end
    IVO_QUEST.InDialogue = false
    IVO_QUEST.PendingOption = nil
    
    if IVO_QUEST.IsPreview then
        IVO_QUEST.IsPreview = false
        if IsValid(IVO_QUEST.PreviewEditorFrame) then IVO_QUEST.PreviewEditorFrame:SetVisible(true) end
    else
        net.Start("IvoQuest_CloseMenu")
        net.SendToServer()
    end
end

local function ReadNextLine()
    local mData = IVO_QUEST.CurrentMission
    if not mData then return end
    
    if IsValid(dialogueFrame) then dialogueFrame:Remove() end

    local pnlW = ScrW() * 0.65; local pnlH = 180
    local pnlX = (ScrW() - pnlW) / 2; local pnlY = ScrH() - 230

    dialogueFrame = vgui.Create("DPanel")
    dialogueFrame:SetSize(pnlW, pnlH) dialogueFrame:SetPos(pnlX, pnlY)
    dialogueFrame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(10, 10, 10, 240)) 
        draw.RoundedBox(0, 0, 0, w, 2, Color(200, 150, 0, 255)) 
    end
    dialogueFrame:MakePopup() 

    local nameLabel = vgui.Create("DLabel", dialogueFrame)
    nameLabel:SetPos(150, 20) nameLabel:SetFont("IvoQuest_Dialog_Name")

    local textLabel = vgui.Create("DLabel", dialogueFrame)
    textLabel:SetPos(150, 50) textLabel:SetSize(pnlW - 170, 50) 
    textLabel:SetFont("IvoQuest_Dialog_Text") textLabel:SetTextColor(Color(230, 230, 230))
    textLabel:SetWrap(true) textLabel:SetContentAlignment(7)

    if IVO_QUEST.PendingOption then
        -- =================================================
        -- JUGADOR HABLANDO (Elegió una opción)
        -- =================================================
        IVO_QUEST.CameraState = "player"
        local opt = IVO_QUEST.PendingOption

        local playerBg = vgui.Create("DPanel", dialogueFrame)
        playerBg:SetPos(20, 20) playerBg:SetSize(110, 110)
        playerBg.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200)) end

        local playerIcon = vgui.Create("SpawnIcon", playerBg)
        playerIcon:Dock(FILL) playerIcon:SetModel(LocalPlayer():GetModel())
        playerIcon:SetTooltip(false) playerIcon:SetMouseInputEnabled(false)

        nameLabel:SetText(LocalPlayer():Nick())
        nameLabel:SetTextColor(Color(100, 200, 255))
        nameLabel:SizeToContents()

        textLabel:SetText(opt.Text)

        local btnNext = vgui.Create("DButton", dialogueFrame)
        btnNext:SetPos(pnlW - 160, 130) btnNext:SetSize(140, 35) btnNext:SetText("")
        
        local btnText = "Siguiente ➔"
        if opt.Action == "accept" then btnText = "Aceptar Misión"
        elseif opt.Action == "turnin" then btnText = "Entregar"
        elseif opt.Action == "complete_talk" then btnText = "Finalizar Charla"
        elseif opt.Action == "close" then btnText = "Cerrar" end

        btnNext.DoClick = function()
            local action = opt.Action
            IVO_QUEST.PendingOption = nil
            if action == "next" then
                IVO_QUEST.CurrentDialogueLine = IVO_QUEST.CurrentDialogueLine + 1
                ReadNextLine()
            elseif action == "goto" then
                IVO_QUEST.CurrentDialogueLine = opt.Target or (IVO_QUEST.CurrentDialogueLine + 1)
                ReadNextLine()
            elseif action == "accept" then
                if not IVO_QUEST.IsPreview then net.Start("IvoQuest_AcceptMission") net.WriteString(IVO_QUEST.CurrentMissionID) net.SendToServer() end
                CloseDialogue()
            elseif action == "turnin" then
                if not IVO_QUEST.IsPreview then net.Start("IvoQuest_TurnInMission") net.SendToServer() end
                CloseDialogue()
            elseif action == "complete_talk" then
                if not IVO_QUEST.IsPreview then net.Start("IvoQuest_AdvanceTalk") net.SendToServer() end
                CloseDialogue()
            else
                CloseDialogue()
            end
        end
        
        btnNext.Paint = function(self, w, h)
            local isHovered = self:IsHovered()
            draw.RoundedBox(4, 0, 0, w, h, isHovered and Color(255, 255, 255, 15) or Color(255, 255, 255, 5))
            draw.SimpleText(btnText, "IvoQuest_Dialog_Btn", w/2, h/2, isHovered and Color(255, 255, 255) or Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    else
        -- =================================================
        -- NPC HABLANDO (Esperando respuesta)
        -- =================================================
        IVO_QUEST.CameraState = "npc"

        local currentText = ""
        local options = {}

        if IVO_QUEST.PlayerQuestState == "active" then
            currentText = mData.InProgressText or "..."
            options = mData.OptionsActive or {{Text = "Continuar", Action = "close"}}
        elseif IVO_QUEST.PlayerQuestState == "ready" then
            currentText = mData.ReadyText or "..."
            options = mData.OptionsReady or {{Text = "Entregar", Action = "turnin"}}
    elseif IVO_QUEST.PlayerQuestState == "delivery_receptor" then
        currentText = IVO_QUEST.DialogueTarget:GetNWString("ReceptorText", "¡Gracias por el paquete!")
        options = {{Text = "Entregar", Action = "turnin"}}
    elseif IVO_QUEST.PlayerQuestState == "talk_stage" then
        local mData = IVO_QUEST.CurrentMission
        local cStage = mData.Stages and mData.Stages[IVO_QUEST.ActiveMissionData.StageIdx or 1]
        
        local stepData = cStage and cStage.Dialogues and cStage.Dialogues[IVO_QUEST.CurrentDialogueLine]
        if stepData then
            currentText = stepData.NPCText or "..."
            options = stepData.Options or {}
        else
            currentText = "No hay diálogo configurado para esta etapa."
            options = {{Text = "Cerrar", Action = "close"}}
        end
        else
            local stepData = mData.Dialogues and mData.Dialogues[IVO_QUEST.CurrentDialogueLine]
            if stepData and stepData.Speaker then 
                stepData.NPCText = stepData.Text 
                stepData.Options = { { Text = "Continuar", Action = "next" } } 
            end

            if stepData then
                currentText = stepData.NPCText or "..."
                options = stepData.Options or {}
            else
                currentText = "No hay diálogo configurado."
                options = {{Text = "Cerrar", Action = "close"}}
            end
        end

        if IVO_QUEST.IsPreview and currentText == "..." then currentText = "[Nota: No hay texto de Progreso o Entrega configurado.]" end

        local npcBg = vgui.Create("DPanel", dialogueFrame)
        npcBg:SetPos(20, 20) npcBg:SetSize(110, 110)
        npcBg.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200)) end

        local npcIcon = vgui.Create("SpawnIcon", npcBg)
        npcIcon:Dock(FILL) npcIcon:SetModel(IVO_QUEST.DialogueTarget:GetModel())
        npcIcon:SetTooltip(false) npcIcon:SetMouseInputEnabled(false)

        nameLabel:SetText((mData.Config and mData.Config.NPCName) or mData.NPCName or "NPC")
        nameLabel:SetTextColor(Color(255, 180, 50))
        nameLabel:SizeToContents()

        textLabel:SetText(currentText)

        local optScroll = vgui.Create("DScrollPanel", dialogueFrame)
        optScroll:SetPos(150, 110) optScroll:SetSize(pnlW - 170, 60)
        local sbar = optScroll:GetVBar()
        sbar:SetWide(4) sbar:SetHideButtons(true)
        sbar.Paint = function() end
        sbar.btnGrip.Paint = function(self, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(100, 100, 100, 100)) end

        local optLayout = vgui.Create("DIconLayout", optScroll)
        optLayout:Dock(FILL)
        optLayout:SetSpaceX(10) optLayout:SetSpaceY(5)

        for i, opt in ipairs(options) do
            local btn = optLayout:Add("DButton")
            btn:SetSize(220, 26)
            btn:SetText("")
            
            local shortText = i .. ". " .. opt.Text
            if string.len(shortText) > 28 then shortText = string.sub(shortText, 1, 25) .. "..." end
            
            local btnColor = Color(200, 200, 200)
            if opt.Action == "accept" then btnColor = Color(80, 255, 80)
            elseif opt.Action == "turnin" then btnColor = Color(255, 200, 50)
            elseif opt.Action == "close" then btnColor = Color(255, 80, 80) end

            btn.DoClick = function()
                IVO_QUEST.PendingOption = opt
                ReadNextLine()
            end
            
            btn.Paint = function(self, w, h)
                local isHovered = self:IsHovered()
                if isHovered then draw.RoundedBox(0, 0, 0, w, h, Color(btnColor.r, btnColor.g, btnColor.b, 15)) draw.RoundedBox(0, 0, 0, 3, h, btnColor) end
                draw.SimpleText(shortText, "IvoQuest_Dialog_Btn", 10, h / 2, isHovered and btnColor or Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end

        if #options == 0 then
            local btn = optLayout:Add("DButton")
            btn:SetSize(120, 26) btn:SetText("")
            btn.DoClick = function() CloseDialogue() end
            btn.Paint = function(self, w, h)
                local isHovered = self:IsHovered()
                if isHovered then draw.RoundedBox(0, 0, 0, w, h, Color(255, 80, 80, 15)) draw.RoundedBox(0, 0, 0, 3, h, Color(255, 80, 80)) end
                draw.SimpleText("Salir", "IvoQuest_Dialog_Btn", 10, h / 2, isHovered and Color(255, 100, 100) or Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
    end
end

-- =========================================================
-- SISTEMA DE VISTA PREVIA (HOOK DESDE EL EDITOR)
-- =========================================================
function IVO_QUEST.TestPreview(data, editorFrame, state)
    editorFrame:SetVisible(false)
    IVO_QUEST.IsPreview = true
    IVO_QUEST.PreviewEditorFrame = editorFrame
    IVO_QUEST.CurrentMissionID = "preview_id"
    IVO_QUEST.DialogueTarget = LocalPlayer() -- Usamos al jugador como dummy de cámara
    IVO_QUEST.PlayerQuestState = state or "new"
    IVO_QUEST.CurrentMission = data
    IVO_QUEST.InDialogue = true
    IVO_QUEST.PendingOption = nil 
    IVO_QUEST.CurrentDialogueLine = 1 
    
    ReadNextLine()
end

net.Receive("IvoQuest_OpenMenu", function()
    IVO_QUEST.CurrentMissionID = net.ReadString()
    IVO_QUEST.DialogueTarget = net.ReadEntity()
    IVO_QUEST.PlayerQuestState = net.ReadString()
    IVO_QUEST.CurrentMission = MISSION_SYSTEM.Missions[IVO_QUEST.CurrentMissionID]
    
    if not IVO_QUEST.CurrentMission then return end

    IVO_QUEST.InDialogue = true
    IVO_QUEST.PendingOption = nil 
    IVO_QUEST.CurrentDialogueLine = 1 
    
    ReadNextLine()
end)