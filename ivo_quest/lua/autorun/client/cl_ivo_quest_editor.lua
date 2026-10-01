IVO_QUEST = IVO_QUEST or {}
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
        ent:SetCycle(0)
        ent:SetPlaybackRate(1)
    end

    if gestureID and gestureID ~= "sit" and IVO_QUEST.Gestures[gestureID] then
        for boneName, ang in pairs(IVO_QUEST.Gestures[gestureID]) do
            local boneID = ent:LookupBone(boneName)
            if boneID then ent:ManipulateBoneAngles(boneID, ang) end
        end
    end
end

-- =========================================================
-- FUENTES PROFESIONALES
-- =========================================================
local function SafeFont(name, font, size, weight)
    if not istable(font.props) then surface.CreateFont(name, { font = font, size = size, weight = weight }) end
end

SafeFont("IvoEditor_Title", "Roboto", 26, 800)
SafeFont("IvoEditor_Subtitle", "Roboto", 20, 600)
SafeFont("IvoEditor_Text", "Roboto", 16, 500)
SafeFont("IvoEditor_SquareTitle", "Roboto", 22, 900)
SafeFont("IvoEditor_SquareSub", "Roboto", 16, 500)
SafeFont("IvoEditor_SideBtn", "Roboto", 18, 700)
SafeFont("IvoEditor_CloseBtn", "Roboto", 18, 900)

-- Hack para el Drag & Drop: Indicador Naranja y Zonas Bloqueadas
hook.Add("Think", "IvoQuest_FixPinkDrop", function()
    if dragndrop and IsValid(dragndrop.m_DropMenu) then
        dragndrop.m_DropMenu.Paint = function(s, w, h)
            local target = dragndrop.DropTarget
            if IsValid(target) then
                local pos = dragndrop.DropPos
                -- Oculta el indicador si intentas soltar ANTES del módulo Principal
                if target.IsMainModule and (pos == 4 or pos == 2 or pos == 1) then return end
                -- Oculta el indicador si intentas soltar DESPUÉS del módulo Añadir
                if target.IsAddModule and (pos == 6 or pos == 8 or pos == 3) then return end
            end
            -- Si es una zona válida, dibuja la barra naranja
            draw.RoundedBox(4, 0, 0, w, h, Color(255, 150, 50, 200))
        end
    end
end)

IVO_QUEST = IVO_QUEST or {}
IVO_QUEST.ReceptorListPanel = nil
IVO_QUEST.SelectedReceptorEntID = nil

net.Receive("IvoQuest_SendReceptors", function()
    local npcs = net.ReadTable()
    if IsValid(IVO_QUEST.ReceptorListPanel) then
        IVO_QUEST.ReceptorListPanel:Clear()
        IVO_QUEST.SelectedReceptorEntID = nil
        
        for _, npc in ipairs(npcs) do
            local isGiver = MISSION_SYSTEM.Missions[npc.id] ~= nil
            local isReceptor = false
            if MISSION_SYSTEM and MISSION_SYSTEM.Missions then
                for mID, mData in pairs(MISSION_SYSTEM.Missions) do
                    if mData.Type == "delivery" and mData.TargetNPC == npc.id then isReceptor = true break end
                    if mData.Stages then
                        for _, stage in ipairs(mData.Stages) do
                            if stage.Type == "delivery" and stage.Target == npc.id then isReceptor = true break end
                        end
                    end
                    if isReceptor then break end
                end
            end

            local typeTxt = "Sin Rol / Inactivo"
            local typeColor = Color(150, 150, 150)
            if npc.isUnassigned then typeTxt = "PERFIL FALTA VINCULAR"; typeColor = Color(200, 80, 80)
            elseif isGiver and isReceptor then typeTxt = "Giver y Receptor"; typeColor = Color(200, 150, 255)
            elseif isGiver then typeTxt = "NPC Giver (Da Misión)"; typeColor = Color(100, 255, 100)
            elseif isReceptor then typeTxt = "NPC Receptor (Recibe Entregas)"; typeColor = Color(255, 150, 50)
            end

            local card = vgui.Create("DPanel", IVO_QUEST.ReceptorListPanel)
            card:Dock(TOP)
            card:DockMargin(0, 0, 10, 8)
            card:SetTall(60)
            
            local iconBg = vgui.Create("DPanel", card)
            iconBg:SetPos(15, 6); iconBg:SetSize(48, 48)
            iconBg.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 25)) end
            
            local icon = vgui.Create("SpawnIcon", iconBg)
            icon:Dock(FILL); icon:SetModel(npc.model); icon:SetTooltip(false)
            
            local btnSelect = vgui.Create("DButton", card)
            btnSelect:Dock(FILL); btnSelect:SetText(""); btnSelect.Paint = function() end
            btnSelect.DoClick = function()
                IVO_QUEST.SelectedReceptorEntID = npc.entID
                surface.PlaySound("UI/buttonclick.wav")
            end
            btnSelect.DoRightClick = function()
                hook.Run("IvoQuest_OnReceptorRightClick", npc)
            end

            card.Paint = function(self, w, h)
                local hovered = btnSelect:IsHovered()
                draw.RoundedBox(6, 0, 0, w, h, hovered and Color(40, 45, 55) or Color(35, 35, 45))
                draw.RoundedBoxEx(6, 0, 0, 6, h, typeColor, true, false, true, false)
                
                draw.SimpleText(npc.id, "IvoEditor_Subtitle", 75, 10, Color(255, 255, 255))
                draw.SimpleText(typeTxt, "IvoEditor_Text", 75, 32, typeColor)
                
                if npc.isUnassigned then
                    draw.SimpleText("Falta Vincular", "IvoEditor_Text", w - 20, h/2, Color(200, 80, 80), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                else
                    local dist = math.Round(LocalPlayer():GetPos():Distance(npc.pos) * 0.01905)
                    draw.SimpleText("Distancia: " .. dist .. "m", "IvoEditor_Text", w - 20, h/2, Color(180, 180, 180), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
                
                if IVO_QUEST.SelectedReceptorEntID == npc.entID then
                    draw.RoundedBox(6, 0, 0, w, h, Color(100, 200, 255, 15))
                    surface.SetDrawColor(100, 200, 255, 150)
                    surface.DrawOutlinedRect(0, 0, w, h, 2)
                end
            end
        end
    end
end)

IVO_QUEST.ZoneListPanel = nil
IVO_QUEST.SelectedZoneID = nil
IVO_QUEST.CachedZones = {}

net.Receive("IvoQuest_SendZones", function()
    IVO_QUEST.CachedZones = net.ReadTable()
    if IsValid(IVO_QUEST.ZoneListPanel) then
        IVO_QUEST.ZoneListPanel:Clear()
        IVO_QUEST.SelectedZoneID = nil
        
        for zID, data in pairs(IVO_QUEST.CachedZones) do
            local center = (data.min + data.max) / 2
            local card = vgui.Create("DPanel", IVO_QUEST.ZoneListPanel)
            card:Dock(TOP); card:DockMargin(0, 0, 10, 8); card:SetTall(60)
            
            local btnSelect = vgui.Create("DButton", card)
            btnSelect:Dock(FILL); btnSelect:SetText(""); btnSelect.Paint = function() end
            btnSelect.DoClick = function()
                IVO_QUEST.SelectedZoneID = zID
                surface.PlaySound("UI/buttonclick.wav")
            end
            
            card.Paint = function(self, w, h)
                local hovered = btnSelect:IsHovered()
                draw.RoundedBox(6, 0, 0, w, h, hovered and Color(40, 45, 55) or Color(35, 35, 45))
                draw.RoundedBoxEx(6, 0, 0, 6, h, Color(100, 200, 255), true, false, true, false)
                draw.SimpleText(string.upper(zID), "IvoEditor_Subtitle", 20, 10, Color(255, 255, 255))
                draw.SimpleText("Zona Mapeada", "IvoEditor_Text", 20, 32, Color(100, 200, 255))
                local dist = math.Round(LocalPlayer():GetPos():Distance(center) * 0.01905)
                draw.SimpleText("Distancia: " .. dist .. "m", "IvoEditor_Text", w - 20, h/2, Color(180, 180, 180), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                if IVO_QUEST.SelectedZoneID == zID then
                    draw.RoundedBox(6, 0, 0, w, h, Color(100, 200, 255, 15))
                    surface.SetDrawColor(100, 200, 255, 150)
                    surface.DrawOutlinedRect(0, 0, w, h, 2)
                end
            end
        end
    end
end)

-- =========================================================
-- FUNCIÓN PARA MODERNIZAR BARRAS DE SCROLL
-- =========================================================
local function ModernizeScrollbar(scrollPanel)
    local sbar = scrollPanel:GetVBar()
    sbar:SetWide(6)
    sbar:SetHideButtons(true)
    sbar.Paint = function(self, w, h) draw.RoundedBox(3, 0, 0, w, h, Color(15, 15, 20, 200)) end
    sbar.btnGrip.Paint = function(self, w, h) draw.RoundedBox(3, 0, 0, w, h, self:IsHovered() and Color(90, 90, 100) or Color(60, 60, 70)) end
end

-- =========================================================
-- FUNCIÓN PARA MODERNIZAR INPUTS (TEXTBOX Y COMBOBOX)
-- =========================================================
local function ModernizeInput(entry)
    if entry.ClassName == "DTextEntry" then
        entry:SetFont("IvoEditor_Text")
        entry:SetPaintBackground(false)
        entry:SetTextColor(Color(255, 255, 255))
        entry:SetCursorColor(Color(255, 255, 255))
        entry:SetUpdateOnType(true)
        entry.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(15, 15, 20))
            if self:IsEditing() then draw.RoundedBox(0, 0, h-2, w, 2, Color(100, 200, 255)) else draw.RoundedBox(0, 0, h-1, w, 1, Color(60, 60, 70)) end
            self:DrawTextEntryText(Color(255,255,255), Color(100,150,255), Color(255,255,255))
        end
    elseif entry.ClassName == "DComboBox" then
        entry:SetFont("IvoEditor_Text")
        entry:SetTextColor(Color(220, 220, 220))
        entry.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(15, 15, 20))
            draw.RoundedBox(0, 0, h-1, w, 1, Color(60, 60, 70))
        end
    end
end

-- =========================================================
-- APLICACIÓN PRINCIPAL
-- =========================================================

-- Exorcista de botones fantasma: Elimina cualquier botón huérfano atascado en la pantalla
for _, pnl in ipairs(vgui.GetWorldPanel():GetChildren()) do
    if pnl:GetName() == "DButton" and pnl.GetText then
        local txt = pnl:GetText() or ""
        if string.find(txt, "Visión Admin") or string.find(txt, "TELETRANSPORTARSE") then
            pnl:Remove()
        end
    end
end

concommand.Add("ivo_quest_editor", function(ply)
    if not ply:IsSuperAdmin() then return end
    
    if not MISSION_SYSTEM or not MISSION_SYSTEM.Missions then
        ply:ChatPrint("[IvoQuest] Error: Las misiones aún no se han cargado desde el servidor. Espera un momento.")
        return
    end

    local currentView = "dashboard" 
    
    -- Sistema Singleton: Evita múltiples ventanas y borra la anterior si ya estaba abierta
    if IsValid(IVO_QUEST.EditorFrame) then IVO_QUEST.EditorFrame:Remove() end
    IVO_QUEST.EditorFrame = vgui.Create("DFrame")
    local frame = IVO_QUEST.EditorFrame
    frame:SetSize(1150, 780)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(true)
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(35, 35, 40, 255))
        draw.RoundedBoxEx(8, 0, 0, w, 30, Color(20, 20, 25, 255), true, true, false, false)
    end

    -- =========================================================
    -- MENÚ LATERAL (SIDEBAR)
    -- =========================================================
    local sidebar = vgui.Create("DPanel", frame)
    sidebar:Dock(LEFT)
    sidebar:SetWide(240)
    sidebar:DockMargin(0, 5, 0, 0)
    sidebar.Paint = function(self, w, h)
        draw.RoundedBoxEx(8, 0, 0, w, h, Color(25, 25, 30, 255), false, false, true, false)
        draw.SimpleText("IvoQuest", "IvoEditor_Title", w/2, 30, Color(100, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Dev Engine", "IvoEditor_Text", w/2, 55, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.RoundedBox(0, 20, 80, w - 40, 2, Color(50, 50, 60))
    end

    local contentArea = vgui.Create("DPanel", frame)
    contentArea:Dock(FILL)
    contentArea:DockMargin(15, 15, 15, 15)
    contentArea.Paint = function() end

    local BuildDashboard, BuildEditor, BuildReceptors, BuildZones

    local function CreateSideButton(text, icon, yPos, targetView, onClickAction)
        local btn = vgui.Create("DButton", sidebar)
        btn:SetPos(10, yPos)
        btn:SetSize(220, 50)
        btn:SetText("")
        btn.DoClick = function()
            if currentView == targetView and targetView ~= "editor_new" then return end
            currentView = targetView
            if onClickAction then onClickAction() end
        end
        btn.Paint = function(self, w, h)
            local isHovered = self:IsHovered()
            local isActive = (currentView == targetView) or (currentView == "editor" and targetView == "editor_new")
            
            local bgColor = isActive and Color(50, 100, 200, 50) or (isHovered and Color(255, 255, 255, 10) or Color(0,0,0,0))
            draw.RoundedBox(6, 0, 0, w, h, bgColor)
            if isActive then draw.RoundedBox(0, 0, 10, 4, h-20, Color(100, 200, 255)) end
            
            local textColor = isActive and Color(255, 255, 255) or Color(180, 180, 180)
            draw.SimpleText(text, "IvoEditor_SideBtn", 20, h/2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        return btn
    end

    CreateSideButton("Gestor de Misiones", "", 100, "dashboard", function() BuildDashboard() end)
    CreateSideButton("Crear Nueva", "", 160, "editor_new", function() BuildEditor(nil, nil) end)
    CreateSideButton("Gestor Receptores", "", 220, "receptors", function() BuildReceptors() end)
    CreateSideButton("Gestor Zonas", "", 280, "zones", function() BuildZones() end)

    -- =========================================================
    -- VISTA 1: DASHBOARD
    -- =========================================================
    BuildDashboard = function()
        contentArea:Clear()
        currentView = "dashboard"
        local SelectedMissionID = nil

        local leftPanel = vgui.Create("DPanel", contentArea)
        leftPanel:Dock(LEFT); leftPanel:SetWide(380); leftPanel:DockMargin(0, 0, 15, 0)
        leftPanel.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(30, 30, 35)) end

        local rightPanel = vgui.Create("DPanel", contentArea)
        rightPanel:Dock(FILL)
        rightPanel.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(30, 30, 35)) end

        local lblList = vgui.Create("DLabel", leftPanel)
        lblList:Dock(TOP); lblList:DockMargin(15, 15, 15, 5); lblList:SetText("Misiones Instaladas"); lblList:SetFont("IvoEditor_Title"); lblList:SetTextColor(Color(100, 255, 150)); lblList:SizeToContents()

        local listScroll = vgui.Create("DScrollPanel", leftPanel)
        listScroll:Dock(FILL); listScroll:DockMargin(15, 10, 15, 15)
        ModernizeScrollbar(listScroll)

        local pnlDetails = vgui.Create("DPanel", rightPanel)
        pnlDetails:Dock(FILL); pnlDetails:DockMargin(20, 20, 20, 20); pnlDetails.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 30)) end

        local lblSelected = vgui.Create("DLabel", pnlDetails)
        lblSelected:Dock(TOP); lblSelected:DockMargin(20, 20, 20, 5); lblSelected:SetText("Ninguna Misión Seleccionada"); lblSelected:SetFont("IvoEditor_Title"); lblSelected:SetTextColor(Color(100, 255, 150)); lblSelected:SizeToContents()

        local lblData = vgui.Create("DLabel", pnlDetails)
        lblData:Dock(TOP); lblData:DockMargin(20, 0, 20, 20); lblData:SetText("Selecciona una misión de la lista para ver sus detalles o editarla."); lblData:SetFont("IvoEditor_Text"); lblData:SetTextColor(Color(180, 180, 180)); lblData:SetAutoStretchVertical(true); lblData:SetWrap(true)

        local bottomActions = vgui.Create("DPanel", pnlDetails)
        bottomActions:Dock(BOTTOM); bottomActions:SetTall(45); bottomActions:DockMargin(20, 0, 20, 20); bottomActions.Paint = function() end

        local btnEdit = vgui.Create("DButton", bottomActions)
        btnEdit:Dock(LEFT); btnEdit:SetWide(200); btnEdit:SetText("EDITAR MISIÓN"); btnEdit:SetFont("IvoEditor_Title"); btnEdit:SetTextColor(color_white)
        btnEdit.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(60, 120, 220) or Color(50, 100, 200)) end
        btnEdit:SetVisible(false)

        local btnDel = vgui.Create("DButton", bottomActions)
        btnDel:Dock(RIGHT); btnDel:SetWide(200); btnDel:SetText("ELIMINAR MISIÓN"); btnDel:SetFont("IvoEditor_Title"); btnDel:SetTextColor(color_white)
        btnDel.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(200, 50, 50) or Color(150, 40, 40)) end
        btnDel:SetVisible(false)

        local function RefreshList()
            listScroll:Clear()
            SelectedMissionID = nil
            btnEdit:SetVisible(false)
            btnDel:SetVisible(false)
            lblSelected:SetText("Ninguna Misión Seleccionada")
            lblData:SetText("Selecciona una misión de la lista para ver sus detalles o editarla.")

            for id, data in pairs(MISSION_SYSTEM.Missions) do
                if id ~= "default" then 
                    local stageCount = data.Stages and #data.Stages or 0
                    local mName = data.Config and data.Config.Name or "Sin Nombre"
                    local isRep = data.Config and data.Config.IsRepeatable
                    
                    local card = vgui.Create("DPanel", listScroll)
                    card:Dock(TOP); card:DockMargin(0, 0, 0, 8); card:SetTall(60)
                    
                    local btnSelect = vgui.Create("DButton", card)
                    btnSelect:Dock(FILL); btnSelect:SetText(""); btnSelect.Paint = function() end
                    btnSelect.DoClick = function()
                        SelectedMissionID = id
                        surface.PlaySound("UI/buttonclick.wav")
                        
                        btnEdit:SetVisible(true)
                        btnDel:SetVisible(true)
                        lblSelected:SetText("MISIÓN: " .. string.upper(id))
                        
                        local infoStr = "Nombre Público: " .. mName .. "\n"
                        infoStr = infoStr .. "NPC Asignado: " .. (data.Config and data.Config.NPCName or "Desconocido") .. "\n"
                        infoStr = infoStr .. "Fases/Etapas: " .. stageCount .. "\n"
                        infoStr = infoStr .. "Misión Repetible: " .. (isRep and "Sí" or "No") .. "\n\n"
                        
                        local rw = data.Config and data.Config.Rewards or {}
                        infoStr = infoStr .. "Recompensas:\n"
                        infoStr = infoStr .. "- Dinero: $" .. (rw.Money or 0) .. "\n"
                        infoStr = infoStr .. "- Curación: " .. (rw.Health or 0) .. " HP\n"
                        infoStr = infoStr .. "- Arma: " .. (rw.Weapon and rw.Weapon ~= "" and rw.Weapon or "Ninguna")
                        
                        lblData:SetText(infoStr)
                    end
                    
                    card.Paint = function(self, w, h)
                        local hovered = btnSelect:IsHovered()
                        draw.RoundedBox(6, 0, 0, w, h, hovered and Color(40, 45, 55) or Color(35, 35, 45))
                        draw.RoundedBoxEx(6, 0, 0, 6, h, Color(100, 255, 100), true, false, true, false)
                        draw.SimpleText(id, "IvoEditor_Subtitle", 15, 10, Color(255, 255, 255))
                        draw.SimpleText(mName, "IvoEditor_Text", 15, 32, Color(180, 180, 180))
                        draw.SimpleText(stageCount .. " Etapas", "IvoEditor_Text", w - 15, h/2, Color(100, 255, 100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        if SelectedMissionID == id then
                            draw.RoundedBox(6, 0, 0, w, h, Color(100, 255, 100, 15))
                            surface.SetDrawColor(100, 255, 100, 150)
                            surface.DrawOutlinedRect(0, 0, w, h, 2)
                        end
                    end
                end
            end
        end
        RefreshList()

        btnEdit.DoClick = function()
            if SelectedMissionID then BuildEditor(SelectedMissionID, MISSION_SYSTEM.Missions[SelectedMissionID]) end
        end

        btnDel.DoClick = function()
            if SelectedMissionID then
                Derma_Query("¿Seguro que quieres borrar la misión '"..SelectedMissionID.."' permanentemente?", "Confirmar", 
                    "Sí, Borrar", function() 
                        net.Start("IvoQuest_DeleteMission") 
                        net.WriteString(SelectedMissionID) 
                        net.SendToServer() 
                        timer.Simple(0.5, RefreshList) 
                    end, "Cancelar", function() end)
            end
        end
    end

    -- =========================================================
    -- VISTA 3: GESTOR DE RECEPTORES
    -- =========================================================
    BuildReceptors = function()
        contentArea:Clear()
        currentView = "receptors"
        local EditingReceptorID = nil

        -- Divide screen into Left (List) and Right (Editor)
        local leftPanel = vgui.Create("DPanel", contentArea)
        leftPanel:Dock(LEFT); leftPanel:SetWide(380); leftPanel:DockMargin(0, 0, 15, 0)
        leftPanel.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(30, 30, 35)) end

        local rightPanel = vgui.Create("DPanel", contentArea)
        rightPanel:Dock(FILL)
        rightPanel.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(30, 30, 35)) end

        -- ======================================
        -- LEFT PANEL: LIST OF RECEPTORS
        -- ======================================
        local lblList = vgui.Create("DLabel", leftPanel)
        lblList:Dock(TOP); lblList:DockMargin(15, 15, 15, 5); lblList:SetText("Receptores Activos y Perfiles"); lblList:SetFont("IvoEditor_Title"); lblList:SetTextColor(Color(255, 150, 50)); lblList:SizeToContents()

        local btnReveal = vgui.Create("DButton", leftPanel)
        btnReveal:Dock(TOP); btnReveal:SetTall(30); btnReveal:DockMargin(15, 0, 15, 10); btnReveal:SetText("Modo Visión Admin"); btnReveal:SetFont("IvoEditor_Text"); btnReveal:SetTextColor(Color(255, 255, 255))
        btnReveal.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(80, 80, 90) or Color(60, 60, 70)) end
        btnReveal.DoClick = function() RunConsoleCommand("ivo_admin_reveal") end

        local btnTp = vgui.Create("DButton", leftPanel)
        btnTp:Dock(BOTTOM); btnTp:SetTall(40); btnTp:DockMargin(15, 10, 15, 15); btnTp:SetText("TELETRANSPORTARSE AL SELECCIONADO"); btnTp:SetFont("IvoEditor_Text"); btnTp:SetTextColor(Color(255, 255, 255))
        btnTp.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(60, 180, 220) or Color(50, 150, 200)) end
        btnTp.DoClick = function()
            if IVO_QUEST.SelectedReceptorEntID then
                if type(IVO_QUEST.SelectedReceptorEntID) == "string" and string.StartWith(IVO_QUEST.SelectedReceptorEntID, "unassigned_") then
                    LocalPlayer():ChatPrint("No puedes teletransportarte a un NPC que no está ubicado en el mapa.")
                else
                    RunConsoleCommand("ivo_tp_receptor", tostring(IVO_QUEST.SelectedReceptorEntID))
                end
            else
                LocalPlayer():ChatPrint("Selecciona un NPC de la lista primero.")
            end
        end

        IVO_QUEST.ReceptorListPanel = vgui.Create("DScrollPanel", leftPanel)
        IVO_QUEST.ReceptorListPanel:Dock(FILL); IVO_QUEST.ReceptorListPanel:DockMargin(15, 0, 15, 0)
        ModernizeScrollbar(IVO_QUEST.ReceptorListPanel)
        
        -- ======================================
        -- RIGHT PANEL: EDITOR / CREATOR
        -- ======================================
        local lblEdit = vgui.Create("DLabel", rightPanel)
        lblEdit:Dock(TOP); lblEdit:DockMargin(20, 15, 20, 5); lblEdit:SetText("Configuración de Receptor"); lblEdit:SetFont("IvoEditor_Title"); lblEdit:SetTextColor(Color(255, 255, 255)); lblEdit:SizeToContents()

        local infoLbl = vgui.Create("DLabel", rightPanel)
        infoLbl:Dock(TOP); infoLbl:DockMargin(20, 0, 20, 15); infoLbl:SetText("Asigna ID, Modelo y personaliza los Bodygroups (accesorios) del NPC antes de vincularlo o guardarlo como perfil."); infoLbl:SetFont("IvoEditor_Text"); infoLbl:SetWrap(true); infoLbl:SetTextColor(Color(180, 180, 180)); infoLbl:SetAutoStretchVertical(true)

        local topInputs = vgui.Create("DPanel", rightPanel)
        topInputs:Dock(TOP); topInputs:SetTall(130); topInputs:DockMargin(20, 0, 20, 10); topInputs.Paint = function() end
        
        local topRow = vgui.Create("DPanel", topInputs)
        topRow:Dock(TOP); topRow:SetTall(60); topRow.Paint = function() end

        local pnlID = vgui.Create("DPanel", topRow)
        pnlID:Dock(LEFT); pnlID:SetWide(200); pnlID.Paint = function() end
        local lblID = vgui.Create("DLabel", pnlID); lblID:Dock(TOP); lblID:SetText("IDs (Separar con coma):"); lblID:SetFont("IvoEditor_Text"); lblID:DockMargin(0,0,0,5)
        local entryID = vgui.Create("DTextEntry", pnlID); entryID:Dock(TOP); entryID:SetTall(30)
        ModernizeInput(entryID)

        local pnlModel = vgui.Create("DPanel", topRow)
        pnlModel:Dock(FILL); pnlModel:DockMargin(15, 0, 0, 0); pnlModel.Paint = function() end
        local lblModel = vgui.Create("DLabel", pnlModel); lblModel:Dock(TOP); lblModel:SetText("Modelo (.mdl):"); lblModel:SetFont("IvoEditor_Text"); lblModel:DockMargin(0,0,0,5)
        local entryModel = vgui.Create("DTextEntry", pnlModel); entryModel:Dock(TOP); entryModel:SetTall(30); entryModel:SetText("models/player/barney.mdl")
        ModernizeInput(entryModel)

        local pnlOptions = vgui.Create("DPanel", topInputs)
        pnlOptions:Dock(TOP); pnlOptions:SetTall(60); pnlOptions:DockMargin(0, 10, 0, 0); pnlOptions.Paint = function() end

        local pnlGesture = vgui.Create("DPanel", pnlOptions)
        pnlGesture:Dock(RIGHT); pnlGesture:SetWide(180); pnlGesture:DockMargin(15, 0, 0, 0); pnlGesture.Paint = function() end
        local lblGesture = vgui.Create("DLabel", pnlGesture); lblGesture:Dock(TOP); lblGesture:SetText("Postura (Gesto):"); lblGesture:SetFont("IvoEditor_Text"); lblGesture:DockMargin(0,0,0,5); lblGesture:SetTextColor(Color(180,180,180))
        local comboGesture = vgui.Create("DComboBox", pnlGesture); comboGesture:Dock(TOP); comboGesture:SetTall(30)
        comboGesture:AddChoice("Ninguno", "none"); comboGesture:AddChoice("Brazos Cruzados", "crossed_arms"); comboGesture:AddChoice("Brazos en la Espalda", "crossed_arms_behind"); comboGesture:AddChoice("Sentado", "sit")
        comboGesture:ChooseOptionID(1); ModernizeInput(comboGesture)

        local pnlMsg = vgui.Create("DPanel", pnlOptions)
        pnlMsg:Dock(FILL); pnlMsg.Paint = function() end
        local lblText = vgui.Create("DLabel", pnlMsg); lblText:Dock(TOP); lblText:SetText("Mensaje al Entregarle (Vacío = Sin Diálogo):"); lblText:SetFont("IvoEditor_Text"); lblText:DockMargin(0,0,0,5); lblText:SetTextColor(Color(180,180,180))
        local entryText = vgui.Create("DTextEntry", pnlMsg); entryText:Dock(TOP); entryText:SetTall(30)
        ModernizeInput(entryText)

        local midContent = vgui.Create("DPanel", rightPanel)
        midContent:Dock(FILL); midContent:DockMargin(20, 0, 20, 15); midContent.Paint = function() end

        local previewBg = vgui.Create("DPanel", midContent)
        previewBg:Dock(LEFT); previewBg:SetWide(220); previewBg.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(20, 20, 25)) end

        local previewPnl = vgui.Create("DModelPanel", previewBg)
        previewPnl:Dock(FILL)
        previewPnl:SetModel(entryModel:GetValue())
        
        previewPnl.Angles = Angle(0, 0, 0)
        function previewPnl:LayoutEntity(ent)
            self:RunAnimation()
            if self.Pressed then
                local mx = gui.MouseX()
                self.Angles = self.Angles - Angle(0, (self.PressX or mx) - mx, 0)
                self.PressX = mx
            end
            ent:SetAngles(self.Angles)
            ent:SetupBones()
        end
        function previewPnl:OnMousePressed(mc) if mc == MOUSE_LEFT then self.PressX = gui.MouseX(); self.Pressed = true; self:MouseCapture(true) end end
        function previewPnl:OnMouseReleased(mc) if mc == MOUSE_LEFT then self.Pressed = false; self:MouseCapture(false) end end

        previewPnl.PaintOver = function(self, w, h)
            if EditingReceptorID and type(EditingReceptorID) == "string" and string.StartWith(EditingReceptorID, "unassigned_") then
                draw.RoundedBox(4, 10, 10, w - 20, 25, Color(200, 50, 50, 200))
                draw.SimpleText("FALTA VINCULAR", "IvoEditor_Text", w/2, 22, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        local bgPanel = vgui.Create("DPanel", midContent)
        bgPanel:Dock(FILL); bgPanel:DockMargin(15, 0, 0, 0); bgPanel.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(20, 20, 25)) end
        
        local lblBg = vgui.Create("DLabel", bgPanel)
        lblBg:Dock(TOP); lblBg:DockMargin(10, 10, 10, 5); lblBg:SetText("Bodygroups (Accesorios)"); lblBg:SetFont("IvoEditor_Subtitle"); lblBg:SetTextColor(Color(200, 200, 200))
        
        local bgScroll = vgui.Create("DScrollPanel", bgPanel)
        bgScroll:Dock(FILL); bgScroll:DockMargin(10, 0, 10, 10)
        ModernizeScrollbar(bgScroll)

        local currentBodygroups = {}
        local function RefreshBodygroups()
            bgScroll:Clear(); currentBodygroups = {}
            if not IsValid(previewPnl.Entity) then return end
            
            local ent = previewPnl.Entity; local hasBodygroups = false
            for i = 0, ent:GetNumBodyGroups() - 1 do
                local count = ent:GetBodygroupCount(i)
                if count > 1 then
                    hasBodygroups = true
                    currentBodygroups[i] = ent:GetBodygroup(i)
                    local bgName = ent:GetBodygroupName(i)
                    
                    local pnl = vgui.Create("DPanel", bgScroll)
                    pnl:Dock(TOP); pnl:SetTall(35); pnl:DockMargin(0,0,0,5); pnl.Paint = function() end
                    
                    local lbl = vgui.Create("DLabel", pnl)
                    lbl:Dock(LEFT); lbl:SetWide(90); lbl:SetText(string.upper(bgName)); lbl:SetFont("IvoEditor_Text")
                    
                    local combo = vgui.Create("DComboBox", pnl)
                    combo:Dock(FILL); combo:DockMargin(5,5,5,5)
                    for j = 0, count - 1 do combo:AddChoice("Variación " .. j, j) end
                    ModernizeInput(combo)
                    combo:ChooseOptionID(currentBodygroups[i] + 1)
                    combo.OnSelect = function(_, index, value, data) ent:SetBodygroup(i, data); currentBodygroups[i] = data end
                end
            end
            if not hasBodygroups then
                local lbl = vgui.Create("DLabel", bgScroll); lbl:Dock(TOP); lbl:SetText("El modelo no tiene accesorios."); lbl:SetFont("IvoEditor_Text"); lbl:SetTextColor(Color(150, 150, 150))
            end
        end

        entryModel.OnChange = function(self)
            local mdl = self:GetValue()
            previewPnl:SetModel(mdl)
            
            timer.Create("IvoQuest_ModelPreviewUpdate", 0.2, 1, function()
                if IsValid(previewPnl) and IsValid(previewPnl.Entity) then
                    local mn, mx = previewPnl.Entity:GetRenderBounds()
                    local size = 0
                    size = math.max(size, math.abs(mn.x) + math.abs(mx.x)); size = math.max(size, math.abs(mn.y) + math.abs(mx.y)); size = math.max(size, math.abs(mn.z) + math.abs(mx.z))
                    previewPnl:SetFOV(35); previewPnl:SetCamPos(Vector(size * 0.7, size * 0.7, size * 0.7)); previewPnl:SetLookAt((mn + mx) * 0.5)
                    local gst = comboGesture:GetOptionData(comboGesture:GetSelectedID()) or "none"
                    IVO_QUEST.ApplyGesture(previewPnl.Entity, gst)
                    RefreshBodygroups()
                end
            end)
        end
        timer.Simple(0.2, function() if IsValid(entryModel) then entryModel:OnChange() end end)
        
        comboGesture.OnSelect = function(_, index, value, data)
            if IsValid(previewPnl) and IsValid(previewPnl.Entity) then IVO_QUEST.ApplyGesture(previewPnl.Entity, data) end
        end

        local actionPanel = vgui.Create("DPanel", rightPanel)
        actionPanel:Dock(BOTTOM); actionPanel:SetTall(85); actionPanel:DockMargin(20, 0, 20, 20); actionPanel.Paint = function() end

        local btnApply = vgui.Create("DButton", actionPanel)
        btnApply:Dock(TOP); btnApply:SetTall(45); btnApply:SetText("VINCULAR AL NPC EN LA MIRA"); btnApply:SetFont("IvoEditor_Title"); btnApply:SetTextColor(Color(255, 255, 255))
        btnApply.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(255, 150, 50) or Color(200, 100, 20)) end
        
        local botBtns = vgui.Create("DPanel", actionPanel)
        botBtns:Dock(BOTTOM); botBtns:SetTall(30); botBtns.Paint = function() end

        local btnSaveProfile = vgui.Create("DButton", botBtns)
        btnSaveProfile:Dock(LEFT); btnSaveProfile:SetWide(200); btnSaveProfile:SetText("GUARDAR SIN ASIGNAR"); btnSaveProfile:SetFont("IvoEditor_Text"); btnSaveProfile:SetTextColor(Color(200, 200, 200))
        btnSaveProfile.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(60, 60, 70) or Color(40, 40, 50)) end

        local btnCancel = vgui.Create("DButton", botBtns)
        btnCancel:Dock(RIGHT); btnCancel:SetWide(180); btnCancel:SetText("Cancelar Edición"); btnCancel:SetFont("IvoEditor_Text"); btnCancel:SetTextColor(Color(255, 100, 100))
        btnCancel.Paint = function(self, w, h) if self:IsHovered() then draw.RoundedBox(4, 0, 0, w, h, Color(255, 50, 50, 20)) end end
        btnCancel:SetVisible(false)
        
        btnApply.DoClick = function()
            local id = string.Trim(entryID:GetValue())
            local mdl = string.Trim(entryModel:GetValue())
            local rText = string.Trim(entryText:GetValue())
            local gst = comboGesture:GetOptionData(comboGesture:GetSelectedID()) or "none"
            if id == "" then LocalPlayer():ChatPrint("El ID no puede estar vacío.") return end
            
            local bgStr = ""
            for k, v in pairs(currentBodygroups) do bgStr = bgStr .. k .. ":" .. v .. ";" end
            if bgStr ~= "" then bgStr = string.sub(bgStr, 1, -2) end
            
            if EditingReceptorID then
                RunConsoleCommand("ivo_set_id", id, mdl, bgStr, tostring(EditingReceptorID), rText, gst)
                btnCancel:DoClick()
            else
                RunConsoleCommand("ivo_set_id", id, mdl, bgStr, "", rText, gst)
            end
            timer.Simple(0.5, function() net.Start("IvoQuest_RequestReceptors") net.SendToServer() end)
        end
        
        btnSaveProfile.DoClick = function()
            local id = string.Trim(entryID:GetValue())
            local mdl = string.Trim(entryModel:GetValue())
            local rText = string.Trim(entryText:GetValue())
            local gst = comboGesture:GetOptionData(comboGesture:GetSelectedID()) or "none"
            if id == "" then LocalPlayer():ChatPrint("El ID no puede estar vacío.") return end
            
            local bgStr = ""
            for k, v in pairs(currentBodygroups) do bgStr = bgStr .. k .. ":" .. v .. ";" end
            if bgStr ~= "" then bgStr = string.sub(bgStr, 1, -2) end
            
            if EditingReceptorID and type(EditingReceptorID) == "string" and string.StartWith(EditingReceptorID, "unassigned_") then
                RunConsoleCommand("ivo_create_unassigned", id, mdl, bgStr, string.sub(EditingReceptorID, 12), rText, gst)
            else
                RunConsoleCommand("ivo_create_unassigned", id, mdl, bgStr, "", rText, gst)
            end
            
            if btnCancel:IsVisible() then btnCancel:DoClick() end
            timer.Simple(0.5, function() net.Start("IvoQuest_RequestReceptors") net.SendToServer() end)
        end

        btnCancel.DoClick = function()
            EditingReceptorID = nil
            btnApply:SetText("VINCULAR AL NPC EN LA MIRA")
            btnSaveProfile:SetText("GUARDAR SIN ASIGNAR")
            btnCancel:SetVisible(false)
            entryID:SetValue("")
            entryModel:SetValue("models/player/barney.mdl")
            entryModel:OnChange()
            entryText:SetValue("")
        end
        
        net.Start("IvoQuest_RequestReceptors")
        net.SendToServer()
        
        hook.Add("IvoQuest_OnReceptorRightClick", "IvoQuest_ReceptorContext", function(npc)
            if currentView ~= "receptors" then return end
            local menu = DermaMenu()
            
            if npc.isUnassigned then
                menu:AddOption("Spawnear y Asignar aquí", function()
                    RunConsoleCommand("ivo_unassigned_spawn", string.sub(npc.entID, 12))
                    timer.Simple(0.5, function() net.Start("IvoQuest_RequestReceptors") net.SendToServer() end)
                end)
            end
            
            menu:AddOption("Editar NPC (Cargar en Creador)", function()
                EditingReceptorID = npc.entID
                if IsValid(btnApply) then btnApply:SetText("GUARDAR CAMBIOS AL NPC") end
                if IsValid(btnSaveProfile) then btnSaveProfile:SetText("GUARDAR CAMBIOS AL PERFIL") end
                if IsValid(btnCancel) then btnCancel:SetVisible(true) end
                
                if IsValid(entryID) then entryID:SetValue(npc.id) end
                if IsValid(entryModel) then 
                    entryModel:SetValue(npc.model) 
                    if IsValid(previewPnl) then previewPnl:SetModel(npc.model) end
                end
                if IsValid(entryText) then entryText:SetValue(npc.receptorText or "") end
                if IsValid(comboGesture) then
                    local selId = 1; if npc.gesture == "crossed_arms" then selId = 2 elseif npc.gesture == "crossed_arms_behind" then selId = 3 elseif npc.gesture == "sit" then selId = 4 end
                    comboGesture:ChooseOptionID(selId)
                end
                
                timer.Create("IvoQuest_ModelPreviewUpdate", 0.2, 1, function()
                    if IsValid(previewPnl) and IsValid(previewPnl.Entity) then
                        local mn, mx = previewPnl.Entity:GetRenderBounds()
                        local size = 0
                        size = math.max(size, math.abs(mn.x) + math.abs(mx.x)); size = math.max(size, math.abs(mn.y) + math.abs(mx.y)); size = math.max(size, math.abs(mn.z) + math.abs(mx.z))
                        previewPnl:SetFOV(35); previewPnl:SetCamPos(Vector(size * 0.7, size * 0.7, size * 0.7)); previewPnl:SetLookAt((mn + mx) * 0.5)
                        IVO_QUEST.ApplyGesture(previewPnl.Entity, npc.gesture or "none")
                        
                        if npc.bodygroups and npc.bodygroups ~= "" then
                            local bgs = string.Explode(";", npc.bodygroups)
                            for _, bg in ipairs(bgs) do
                                local parts = string.Explode(":", bg)
                                if #parts == 2 then previewPnl.Entity:SetBodygroup(tonumber(parts[1]), tonumber(parts[2])) end
                            end
                        end
                        RefreshBodygroups()
                    end
                end)
            end)
            
            menu:AddOption("Eliminar NPC", function()
                Derma_Query("¿Estás seguro de eliminar este NPC permanentemente?", "Confirmar Eliminación", 
                "Sí, Eliminar", function() 
                    if npc.isUnassigned then
                        RunConsoleCommand("ivo_unassigned_remove", string.sub(npc.entID, 12))
                    else
                        RunConsoleCommand("ivo_npc_remove", npc.entID)
                    end
                    timer.Simple(0.5, function() net.Start("IvoQuest_RequestReceptors") net.SendToServer() end)
                end, "Cancelar", function() end)
            end)
            
            menu:Open()
            
            -- Fin del menú contextual
        end)
    end

    -- =========================================================
    -- VISTA 4: GESTOR DE ZONAS
    -- =========================================================
    BuildZones = function()
        contentArea:Clear()
        currentView = "zones"

        local leftPanel = vgui.Create("DPanel", contentArea)
        leftPanel:Dock(LEFT); leftPanel:SetWide(380); leftPanel:DockMargin(0, 0, 15, 0)
        leftPanel.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(30, 30, 35)) end

        local rightPanel = vgui.Create("DPanel", contentArea)
        rightPanel:Dock(FILL)
        rightPanel.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(30, 30, 35)) end

        local lblList = vgui.Create("DLabel", leftPanel)
        lblList:Dock(TOP); lblList:DockMargin(15, 15, 15, 5); lblList:SetText("Zonas Creadas en el Mapa"); lblList:SetFont("IvoEditor_Title"); lblList:SetTextColor(Color(100, 200, 255)); lblList:SizeToContents()

        local btnShowZones = vgui.Create("DButton", leftPanel)
        btnShowZones:Dock(TOP); btnShowZones:SetTall(30); btnShowZones:DockMargin(15, 0, 15, 10); btnShowZones:SetText("Mostrar Hologramas (15s)"); btnShowZones:SetFont("IvoEditor_Text"); btnShowZones:SetTextColor(Color(255, 255, 255))
        btnShowZones.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(60, 120, 180) or Color(40, 90, 150)) end
        btnShowZones.DoClick = function() RunConsoleCommand("ivo_zone_show") end

        local btnTp = vgui.Create("DButton", leftPanel)
        btnTp:Dock(BOTTOM); btnTp:SetTall(40); btnTp:DockMargin(15, 10, 15, 15); btnTp:SetText("TELETRANSPORTARSE A LA ZONA"); btnTp:SetFont("IvoEditor_Text"); btnTp:SetTextColor(Color(255, 255, 255))
        btnTp.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(60, 180, 220) or Color(50, 150, 200)) end
        btnTp.DoClick = function()
            if IVO_QUEST.SelectedZoneID then RunConsoleCommand("ivo_zone_tp", IVO_QUEST.SelectedZoneID) else LocalPlayer():ChatPrint("Selecciona una Zona de la lista primero.") end
        end

        IVO_QUEST.ZoneListPanel = vgui.Create("DScrollPanel", leftPanel)
        IVO_QUEST.ZoneListPanel:Dock(FILL); IVO_QUEST.ZoneListPanel:DockMargin(15, 0, 15, 0)
        ModernizeScrollbar(IVO_QUEST.ZoneListPanel)

        local lblEdit = vgui.Create("DLabel", rightPanel)
        lblEdit:Dock(TOP); lblEdit:DockMargin(20, 15, 20, 5); lblEdit:SetText("Información de la Zona"); lblEdit:SetFont("IvoEditor_Title"); lblEdit:SetTextColor(Color(255, 255, 255)); lblEdit:SizeToContents()

        local infoLbl = vgui.Create("DLabel", rightPanel)
        infoLbl:Dock(TOP); infoLbl:DockMargin(20, 0, 20, 15); infoLbl:SetText("Las zonas se crean usando comandos (ivo_zone_pos1, ivo_zone_pos2, ivo_zone_save [nombre]) mirando al piso o techo. Aquí puedes gestionarlas y eliminarlas."); infoLbl:SetFont("IvoEditor_Text"); infoLbl:SetWrap(true); infoLbl:SetTextColor(Color(180, 180, 180)); infoLbl:SetAutoStretchVertical(true)

        local pnlDetails = vgui.Create("DPanel", rightPanel)
        pnlDetails:Dock(FILL); pnlDetails:DockMargin(20, 0, 20, 20); pnlDetails.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 30)) end

        local lblSelected = vgui.Create("DLabel", pnlDetails)
        lblSelected:Dock(TOP); lblSelected:DockMargin(20, 20, 20, 5); lblSelected:SetText("Ninguna Zona Seleccionada"); lblSelected:SetFont("IvoEditor_Title"); lblSelected:SetTextColor(Color(100, 200, 255)); lblSelected:SizeToContents()

        local lblData = vgui.Create("DLabel", pnlDetails)
        lblData:Dock(TOP); lblData:DockMargin(20, 0, 20, 20); lblData:SetText("Selecciona una zona de la lista izquierda para ver sus detalles matemáticos y dimensiones."); lblData:SetFont("IvoEditor_Text"); lblData:SetTextColor(Color(180, 180, 180)); lblData:SetAutoStretchVertical(true); lblData:SetWrap(true)

        local btnDelete = vgui.Create("DButton", pnlDetails)
        btnDelete:Dock(BOTTOM); btnDelete:SetTall(45); btnDelete:DockMargin(20, 0, 20, 20); btnDelete:SetText("ELIMINAR ZONA PERMANENTEMENTE"); btnDelete:SetFont("IvoEditor_Title"); btnDelete:SetTextColor(Color(255, 255, 255))
        btnDelete.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(200, 50, 50) or Color(150, 40, 40)) end
        btnDelete.DoClick = function()
            if IVO_QUEST.SelectedZoneID then
                Derma_Query("¿Estás seguro de eliminar la zona '" .. IVO_QUEST.SelectedZoneID .. "'? Si una misión dependía de ella, no funcionará.", "Confirmar Eliminación", 
                "Sí, Eliminar", function() RunConsoleCommand("ivo_zone_remove", IVO_QUEST.SelectedZoneID) timer.Simple(0.5, function() net.Start("IvoQuest_RequestZones") net.SendToServer() end) lblSelected:SetText("Ninguna Zona Seleccionada") lblData:SetText("") end, "Cancelar", function() end)
            end
        end

        pnlDetails.Think = function()
            if IVO_QUEST.SelectedZoneID and IVO_QUEST.CachedZones and IVO_QUEST.CachedZones[IVO_QUEST.SelectedZoneID] then
                local z = IVO_QUEST.CachedZones[IVO_QUEST.SelectedZoneID]
                lblSelected:SetText("ZONA: " .. string.upper(IVO_QUEST.SelectedZoneID))
                lblData:SetText("Centro Matemático: " .. tostring(math.Round((z.min.x + z.max.x)/2)) .. ", " .. tostring(math.Round((z.min.y + z.max.y)/2)) .. ", " .. tostring(math.Round((z.min.z + z.max.z)/2)) .. "\n\nTamaño (Largo x Ancho x Alto): " .. tostring(math.Round(math.abs(z.max.x - z.min.x))) .. " x " .. tostring(math.Round(math.abs(z.max.y - z.min.y))) .. " x " .. tostring(math.Round(math.abs(z.max.z - z.min.z))) .. " unidades.\n\nVolumen de Spawn: " .. tostring(math.Round(math.abs(z.max.x - z.min.x) * math.abs(z.max.y - z.min.y) * math.abs(z.max.z - z.min.z))) .. " u³")
            end
        end

        net.Start("IvoQuest_RequestZones")
        net.SendToServer()
    end

    -- =========================================================
    -- VISTA 2: EL CREADOR / EDITOR DE CUADRÍCULA
    -- =========================================================
    BuildEditor = function(missionID, existingData)
        contentArea:Clear()
        currentView = "editor"

        local data = existingData and util.JSONToTable(util.TableToJSON(existingData)) or {
            Config = { Name = "Nueva Mision", NPCName = "Desconocido", Model = "models/player/barney.mdl", Bodygroups = "", TimeLimit = 0, NextMission = "", AllowedJobs = "", IsRepeatable = false, RepeatCooldown = 300, RequireReturn = true, Rewards = { Money = 0, Health = 0, Weapon = "" } },
            Dialogues = {},
            Stages = {}
        }

        local activeTab = "main"
        local activeStageData = nil
        
        -- Tamaño recalculado para encajar siempre 4 por línea con la barra de scroll (864px libres / 4 = 216 - márgenes = 200)
        local sqSize = 200 

        local pnlGridView = vgui.Create("DPanel", contentArea)
        pnlGridView:Dock(FILL); pnlGridView:DockMargin(0, 0, 0, 60); pnlGridView.Paint = function() end

        local pnlEditorView = vgui.Create("DPanel", contentArea)
        pnlEditorView:Dock(FILL); pnlEditorView:DockMargin(0, 0, 0, 60); pnlEditorView.Paint = function() end
        pnlEditorView:Hide() 

        local gridScroll = vgui.Create("DScrollPanel", pnlGridView)
        gridScroll:Dock(FILL)
        ModernizeScrollbar(gridScroll)

        local grid = vgui.Create("DIconLayout", gridScroll)
        grid:Dock(TOP); grid:SetSpaceX(15); grid:SetSpaceY(15)
        grid:MakeDroppable("QuestModules") 

        local btnMain, btnAdd
        local LoadInnerEditor 
        local RefreshGrid 

        local function SyncStagesOrder()
            local newStages = {}
            for _, child in ipairs(grid:GetChildren()) do
                if child.IsStage and child.StageData then table.insert(newStages, child.StageData) end
            end
            data.Stages = newStages
        end

        grid.OnModified = function(self)
            if self.IsRefreshing then return end
            timer.Create("IvoQuest_ForceGridOrder", 0.05, 1, function()
                if IsValid(self) then
                    SyncStagesOrder()
                    RefreshGrid()
                end
            end)
        end

        RefreshGrid = function()
            grid.IsRefreshing = true
            grid:Clear()

            -- 1. EL MÓDULO PRINCIPAL (Fijo)
            btnMain = grid:Add("DPanel")
            btnMain:SetSize(sqSize, sqSize)
            btnMain:SetCursor("hand")
            btnMain.IsMainModule = true -- Etiqueta para el Hook de Drag&Drop
            btnMain.OnMousePressed = function(self, mc) 
                if mc == MOUSE_LEFT then SyncStagesOrder(); activeTab = "main"; pnlGridView:Hide(); pnlEditorView:Show(); LoadInnerEditor() end 
            end
            btnMain.Paint = function(self, w, h)
                local isHovered = self:IsHovered()
                draw.RoundedBox(8, 0, 0, w, h, isHovered and Color(50, 70, 90) or Color(40, 45, 50))
                draw.RoundedBoxEx(8, 0, 0, w, 10, Color(100, 200, 255), true, true, false, false)
                draw.SimpleText("PRINCIPAL", "IvoEditor_SquareTitle", w/2, h/2 - 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("Identidad y Diálogos", "IvoEditor_SquareSub", w/2, h/2 + 10, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("(Fijo)", "IvoEditor_Text", w/2, h - 20, Color(150, 150, 150, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            -- 2. LAS ETAPAS (Arrastrables, Ordenables, y con Cruz de Borrado)
            for i, sData in ipairs(data.Stages) do
                local stagePnl = grid:Add("DPanel")
                stagePnl:SetSize(sqSize, sqSize)
                stagePnl:SetCursor("hand")
                stagePnl.IsStage = true 
                stagePnl.StageData = sData
                
                stagePnl.OnMousePressed = function(self, mc)
                    if mc == MOUSE_LEFT then
                        self.DragStart = {gui.MouseX(), gui.MouseY()}
                        self:DragMousePress(mc) 
                    end
                end
                
                stagePnl.OnMouseReleased = function(self, mc)
                    if mc == MOUSE_LEFT and self.DragStart then
                        local dist = math.abs(gui.MouseX() - self.DragStart[1]) + math.abs(gui.MouseY() - self.DragStart[2])
                        if dist < 5 then
                            SyncStagesOrder(); activeTab = "stage"; activeStageData = sData; pnlGridView:Hide(); pnlEditorView:Show(); LoadInnerEditor()
                        end
                        self.DragStart = nil
                    end
                    self:DragMouseRelease(mc)
                end

                stagePnl.Paint = function(self, w, h)
                    local isHovered = self:IsHovered()
                    draw.RoundedBox(8, 0, 0, w, h, isHovered and Color(90, 70, 50) or Color(50, 45, 45))
                    draw.RoundedBoxEx(8, 0, 0, w, 10, Color(255, 150, 50), true, true, false, false)
                    draw.SimpleText("ETAPA", "IvoEditor_SquareTitle", w/2, h/2 - 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    local objTxt = sData.ObjectiveText or "Sin objetivo"
                    if string.len(objTxt) > 16 then objTxt = string.sub(objTxt, 1, 13) .. "..." end
                    draw.SimpleText(objTxt, "IvoEditor_SquareSub", w/2, h/2 + 10, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText("(" .. (sData.Type or "kill") .. ")", "IvoEditor_SquareSub", w/2, h/2 + 25, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                
                -- BOTÓN "X" PARA ELIMINAR ETAPA DIRECTAMENTE
                local btnDelCross = vgui.Create("DButton", stagePnl)
                btnDelCross:SetSize(26, 26)
                btnDelCross:SetPos(sqSize - 30, 4)
                btnDelCross:SetText("X")
                btnDelCross:SetFont("IvoEditor_CloseBtn")
                btnDelCross:SetTextColor(Color(255, 100, 100))
                btnDelCross.Paint = function(self, w, h)
                    if self:IsHovered() then
                        draw.RoundedBox(6, 0, 0, w, h, Color(255, 50, 50, 80))
                        self:SetTextColor(Color(255, 255, 255))
                    else
                        self:SetTextColor(Color(255, 100, 100))
                    end
                end
                btnDelCross.DoClick = function()
                    Derma_Query("¿Seguro que quieres eliminar esta etapa?", "Eliminar Etapa", "Sí", function() 
                        SyncStagesOrder() 
                        table.RemoveByValue(data.Stages, sData)
                        RefreshGrid() 
                    end, "Cancelar", function() end)
                end
            end

            -- 3. EL MÓDULO AÑADIR (Fijo al final)
            btnAdd = grid:Add("DPanel")
            btnAdd:SetSize(sqSize, sqSize)
            btnAdd:SetCursor("hand")
            btnAdd.IsAddModule = true -- Etiqueta para el Hook de Drag&Drop
            btnAdd.OnMousePressed = function(self, mc) 
                if mc == MOUSE_LEFT then SyncStagesOrder(); table.insert(data.Stages, { Type = "kill", Target = "", Amount = 1, ObjectiveText = "Nueva Etapa" }); RefreshGrid() end 
            end
            btnAdd.Paint = function(self, w, h)
                local isHovered = self:IsHovered()
                draw.RoundedBox(8, 0, 0, w, h, isHovered and Color(40, 60, 40) or Color(30, 45, 30))
                draw.RoundedBoxEx(8, 0, 0, w, 10, Color(100, 255, 100), true, true, false, false)
                draw.SimpleText("+", "DermaLarge", w/2, h/2 - 20, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("AÑADIR ETAPA", "IvoEditor_SquareTitle", w/2, h/2 + 20, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("(Fijo)", "IvoEditor_Text", w/2, h - 20, Color(150, 150, 150, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            grid:Layout(); grid:SizeToChildren(false, true)
            grid.IsRefreshing = false
        end

        local function TrashReceiver(self, panels, bDoDrop, Command, x, y)
            if bDoDrop then
                SyncStagesOrder() 
                local didDelete = false
                for _, pnl in ipairs(panels) do
                    if pnl.IsStage and pnl.StageData then table.RemoveByValue(data.Stages, pnl.StageData); didDelete = true end
                end
                if didDelete then surface.PlaySound("garrysmod/ui_click.wav"); RefreshGrid() end
            end
        end
        pnlGridView:Receiver("QuestModules", TrashReceiver)

        -- ==========================================
        -- EL EDITOR INTERNO (Drill Down)
        -- ==========================================
        local btnBack = vgui.Create("DButton", pnlEditorView)
        btnBack:Dock(TOP); btnBack:SetTall(45); btnBack:DockMargin(0, 0, 0, 10); btnBack:SetText("VOLVER A LA CUADRÍCULA"); btnBack:SetFont("IvoEditor_Title"); btnBack:SetTextColor(color_white)
        btnBack.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(80, 80, 90) or Color(60, 60, 70)) end
        btnBack.DoClick = function() pnlEditorView:Hide(); pnlGridView:Show(); RefreshGrid() end

        local editorScroll = vgui.Create("DScrollPanel", pnlEditorView)
        editorScroll:Dock(FILL)
        ModernizeScrollbar(editorScroll)

        local function CreateTitle(parent, text, color)
            local lbl = vgui.Create("DLabel", parent)
            lbl:Dock(TOP); lbl:DockMargin(0, 15, 0, 10); lbl:SetText(text); lbl:SetFont("IvoEditor_Subtitle"); lbl:SetTextColor(color); lbl:SizeToContents()
        end
        
        local function CreateFoldableSection(parent, title, color, defaultExpanded)
            local container = vgui.Create("DPanel", parent)
            container:Dock(TOP); container:DockMargin(0, 10, 0, 5); container.Paint = function() end
            
            local header = vgui.Create("DButton", container)
            header:Dock(TOP); header:SetTall(40); header:SetText("")
            
            local content = vgui.Create("DPanel", container)
            content:Dock(TOP); content:DockMargin(0, 5, 0, 0); content:DockPadding(15, 15, 15, 15)
            content.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(30, 30, 35)) end
            
            local isExp = defaultExpanded
            header.DoClick = function()
                isExp = not isExp
                content:SetVisible(isExp)
                if IsValid(parent) then parent:InvalidateLayout(true) end
                
                timer.Simple(0.01, function()
                    if IsValid(content) then content:InvalidateLayout(true) end
                    if IsValid(container) then container:InvalidateLayout(true) end
                    if IsValid(parent) then parent:InvalidateLayout(true) end
                end)
            end
            header.Paint = function(self, w, h)
                local hover = self:IsHovered()
                draw.RoundedBox(6, 0, 0, w, h, hover and Color(45, 45, 50) or Color(35, 35, 40))
                draw.RoundedBoxEx(4, 0, 0, 4, h, color, true, false, true, false)
                draw.SimpleText(title, "IvoEditor_Subtitle", 15, h/2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(isExp and "▼ Plegar Panel" or "▶ Desplegar Panel", "IvoEditor_Text", w - 15, h/2, Color(150, 150, 150), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            content.PerformLayout = function(self)
                self:SizeToChildren(false, true)
                self:SetTall(self:GetTall() + 15) -- Compensa el Padding inferior para que no quede apretado
            end
            container.PerformLayout = function(self) self:SizeToChildren(false, true) end
            content:SetVisible(isExp)
            timer.Simple(0.1, function() if IsValid(content) then content:InvalidateLayout(true) end end)
            return content
        end

        local function CreateBindEntry(parent, labelText, targetTable, targetKey, isNumeric)
            local lbl = vgui.Create("DLabel", parent)
            lbl:Dock(TOP); lbl:DockMargin(0, 5, 0, 0); lbl:SetText(labelText); lbl:SetFont("IvoEditor_Text")
            local entry = vgui.Create("DTextEntry", parent)
            entry:Dock(TOP); entry:DockMargin(0, 2, 0, 15); entry:SetText(tostring(targetTable[targetKey] or ""))
            if isNumeric then entry:SetNumeric(true) end
            ModernizeInput(entry)
            entry.OnChange = function(self) targetTable[targetKey] = isNumeric and (tonumber(self:GetValue()) or 0) or self:GetValue() end
            return entry
        end

        LoadInnerEditor = function()
            editorScroll:Clear()

            if activeTab == "main" then
                local configSection = CreateFoldableSection(editorScroll, "1. CONFIGURACIÓN BÁSICA Y MODELO 3D", Color(220, 220, 220), true)

                local topSplit = vgui.Create("DPanel", configSection)
                topSplit:Dock(TOP); topSplit:SetTall(520); topSplit.Paint = function() end

                local leftCol = vgui.Create("DScrollPanel", topSplit)
                leftCol:Dock(LEFT); leftCol:SetWide(320); leftCol:DockMargin(0, 0, 15, 0)
                ModernizeScrollbar(leftCol)

                local rightCol = vgui.Create("DPanel", topSplit)
                rightCol:Dock(FILL); rightCol.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 30)) end
                
                local pnlID = vgui.Create("DPanel", leftCol); pnlID:Dock(TOP); pnlID:SetPaintBackground(false); pnlID:SetTall(45)
                local lblID = vgui.Create("DLabel", pnlID); lblID:Dock(TOP); lblID:DockMargin(0, 0, 0, 0); lblID:SetText("ID de Misión (Ej: robo_banco):"); lblID:SetFont("IvoEditor_Text")
                local entryID = vgui.Create("DTextEntry", pnlID); entryID:Dock(TOP); entryID:DockMargin(0, 2, 0, 5); entryID:SetText(missionID or "")
                if missionID then entryID:SetEnabled(false) end
                ModernizeInput(entryID)
                entryID.OnChange = function(self) missionID = self:GetValue() end 

                CreateBindEntry(leftCol, "Nombre Público:", data.Config, "Name")
                CreateBindEntry(leftCol, "Nombre del NPC:", data.Config, "NPCName")
                local entryModel = CreateBindEntry(leftCol, "Modelo del NPC (.mdl):", data.Config, "Model")
                CreateBindEntry(leftCol, "Tiempo Límite (Segs, 0 = Sin límite):", data.Config, "TimeLimit", true)
                CreateBindEntry(leftCol, "Siguiente Misión (ID, opcional):", data.Config, "NextMission")
                
                -- ===============================================
                -- NUEVO SISTEMA DE TRABAJOS Y CATEGORÍAS (DARKRP)
                -- ===============================================
                local pnlJobs = vgui.Create("DPanel", leftCol)
                pnlJobs:Dock(TOP); pnlJobs:DockMargin(0, 5, 0, 15); pnlJobs.Paint = function() end

                local pnlSwitch = vgui.Create("DPanel", pnlJobs)
                pnlSwitch:Dock(TOP); pnlSwitch:SetTall(30); pnlSwitch:DockMargin(0, 0, 0, 10); pnlSwitch.Paint = function() end

                local lblJobs = vgui.Create("DLabel", pnlSwitch)
                lblJobs:Dock(LEFT); lblJobs:SetText("Restricción de Trabajos:"); lblJobs:SetFont("IvoEditor_Text"); lblJobs:SizeToContents()

                local isRestricted = (data.Config.AllowedJobs and data.Config.AllowedJobs ~= "")
                
                local switchBtn = vgui.Create("DButton", pnlSwitch)
                switchBtn:Dock(RIGHT); switchBtn:SetWide(50); switchBtn:SetText("")
                local switchAnim = isRestricted and 1 or 0
                switchBtn.Paint = function(self, w, h)
                    switchAnim = Lerp(FrameTime() * 15, switchAnim, isRestricted and 1 or 0)
                    draw.RoundedBox(10, 0, h/2 - 10, w, 20, Color(60 + (switchAnim * 40), 60 + (switchAnim * 140), 60 + (switchAnim * 40)))
                    local circleX = switchAnim * (w - 20)
                    draw.RoundedBox(10, circleX, h/2 - 10, 20, 20, Color(255, 255, 255))
                end

                local pnlJobInputs = vgui.Create("DPanel", pnlJobs)
                pnlJobInputs:Dock(TOP); pnlJobInputs:SetVisible(isRestricted); pnlJobInputs.Paint = function() end
                
                local btnAddJob = vgui.Create("DButton", pnlJobInputs)
                btnAddJob:Dock(TOP); btnAddJob:SetTall(35); btnAddJob:SetText("Elegir Trabajo o Categoría para añadir ▼")
                btnAddJob:SetFont("IvoEditor_Text"); btnAddJob:SetTextColor(Color(100, 255, 100))
                btnAddJob.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(40, 60, 80) or Color(30, 40, 60)) end

                local tagsContainer = vgui.Create("DIconLayout", pnlJobInputs)
                tagsContainer:Dock(TOP); tagsContainer:DockMargin(0, 10, 0, 0); tagsContainer:SetSpaceX(5); tagsContainer:SetSpaceY(5)

                local lblNoRestr = vgui.Create("DLabel", pnlJobs)
                lblNoRestr:Dock(TOP); lblNoRestr:SetText("Todos (Sin restricción)"); lblNoRestr:SetFont("IvoEditor_Text"); lblNoRestr:SetTextColor(Color(150, 150, 150)); lblNoRestr:SetVisible(not isRestricted)

                local function RefreshJobTags()
                    tagsContainer:Clear()
                    local jobsStr = string.Trim(data.Config.AllowedJobs or "")
                    if jobsStr ~= "" then
                        local jList = string.Explode(",", jobsStr)
                        for i, jName in ipairs(jList) do
                            jName = string.Trim(jName)
                            if jName == "" then continue end
                            
                            local tag = tagsContainer:Add("DPanel"); tag:SetTall(24)
                            tag.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(40, 90, 150)) end
                            
                            local lbl = vgui.Create("DLabel", tag); lbl:Dock(LEFT); lbl:DockMargin(8, 0, 5, 0); lbl:SetText(jName); lbl:SetFont("IvoEditor_Text"); lbl:SizeToContents()
                            local btnDel = vgui.Create("DButton", tag); btnDel:Dock(RIGHT); btnDel:SetWide(20); btnDel:SetText("X"); btnDel:SetTextColor(Color(255, 100, 100))
                            btnDel.Paint = function(self, w, h) if self:IsHovered() then draw.RoundedBox(4, 0, 0, w, h, Color(255,50,50,50)) end end
                            btnDel.DoClick = function()
                                local newList = {}
                                for _, v in ipairs(string.Explode(",", data.Config.AllowedJobs)) do if string.Trim(v) ~= jName and string.Trim(v) ~= "" then table.insert(newList, string.Trim(v)) end end
                                data.Config.AllowedJobs = table.concat(newList, ", ")
                                RefreshJobTags()
                            end
                            tag:SetWide(lbl:GetWide() + 35)
                        end
                    end
                    tagsContainer:Layout()
                    pnlJobInputs:InvalidateLayout(true); pnlJobInputs:SizeToChildren(false, true)
                    pnlJobs:InvalidateLayout(true); pnlJobs:SizeToChildren(false, true)
                    
                    timer.Simple(0.01, function()
                        if IsValid(tagsContainer) then tagsContainer:Layout() end
                        if IsValid(pnlJobInputs) then pnlJobInputs:InvalidateLayout(true); pnlJobInputs:SizeToChildren(false, true) end
                        if IsValid(pnlJobs) then pnlJobs:InvalidateLayout(true); pnlJobs:SizeToChildren(false, true) end
                        if IsValid(leftCol) then leftCol:InvalidateLayout(true) end
                        if IsValid(configSection) then configSection:InvalidateLayout(true) end
                    end)
                end

                switchBtn.DoClick = function()
                    isRestricted = not isRestricted
                    if not isRestricted then data.Config.AllowedJobs = "" end
                    lblNoRestr:SetVisible(not isRestricted)
                    pnlJobInputs:SetVisible(isRestricted)
                    RefreshJobTags()
                end

                btnAddJob.DoClick = function()
                    local menu = DermaMenu()
                    if RPExtraTeams then
                        local byCat = {}
                        for k, v in pairs(RPExtraTeams) do
                            local cat = v.category or "Otros"
                            byCat[cat] = byCat[cat] or {}
                            table.insert(byCat[cat], v.name)
                        end
                        
                        local sortedCats = {}
                        for c, _ in pairs(byCat) do table.insert(sortedCats, c) end
                        table.sort(sortedCats)
                        
                        for _, cat in ipairs(sortedCats) do
                            local sub, opt = menu:AddSubMenu(cat)
                            opt:SetIcon("icon16/folder.png")
                            
                            sub:AddOption("Añadir Categoría Completa", function()
                                local current = string.Explode(",", data.Config.AllowedJobs or "")
                                local exists = false
                                for i, v in ipairs(current) do if string.Trim(v) == cat then exists = true break end end
                                if not exists then
                                    if not data.Config.AllowedJobs or data.Config.AllowedJobs == "" then data.Config.AllowedJobs = cat else data.Config.AllowedJobs = data.Config.AllowedJobs .. ", " .. cat end
                                    RefreshJobTags()
                                end
                            end):SetIcon("icon16/add.png")
                            
                            sub:AddSpacer()
                            
                            table.sort(byCat[cat])
                            for _, jName in ipairs(byCat[cat]) do
                                sub:AddOption(jName, function()
                                    local current = string.Explode(",", data.Config.AllowedJobs or "")
                                    local exists = false
                                    for i, v in ipairs(current) do if string.Trim(v) == jName then exists = true break end end
                                    if not exists then
                                        if not data.Config.AllowedJobs or data.Config.AllowedJobs == "" then data.Config.AllowedJobs = jName else data.Config.AllowedJobs = data.Config.AllowedJobs .. ", " .. jName end
                                        RefreshJobTags()
                                    end
                                end):SetIcon("icon16/user.png")
                            end
                        end
                    else
                        menu:AddOption("DarkRP no detectado", function() end)
                    end
                    menu:Open()
                end
                RefreshJobTags()
                
                local pnlGesture = vgui.Create("DPanel", leftCol); pnlGesture:Dock(TOP); pnlGesture.Paint = function() end
                local lblGesture = vgui.Create("DLabel", pnlGesture); lblGesture:Dock(TOP); lblGesture:DockMargin(0, 5, 0, 0); lblGesture:SetText("Postura (Gesto):"); lblGesture:SetFont("IvoEditor_Text")
                local comboGesture = vgui.Create("DComboBox", pnlGesture); comboGesture:Dock(TOP); comboGesture:DockMargin(0, 2, 0, 15); comboGesture:SetTall(30)
                comboGesture:AddChoice("Ninguno", "none"); comboGesture:AddChoice("Brazos Cruzados", "crossed_arms")
                comboGesture:AddChoice("Brazos en la Espalda", "crossed_arms_behind"); comboGesture:AddChoice("Sentado", "sit")
                local selId = 1; if data.Config.Gesture == "crossed_arms" then selId = 2 elseif data.Config.Gesture == "crossed_arms_behind" then selId = 3 elseif data.Config.Gesture == "sit" then selId = 4 end; comboGesture:ChooseOptionID(selId); ModernizeInput(comboGesture)
                comboGesture.OnSelect = function(_, index, value, dataVal) data.Config.Gesture = dataVal; if IsValid(previewPnl) and IsValid(previewPnl.Entity) then IVO_QUEST.ApplyGesture(previewPnl.Entity, dataVal) end end
                pnlGesture.PerformLayout = function(self) self:SizeToChildren(false, true) end

                local repeatCheck = vgui.Create("DCheckBoxLabel", leftCol)
                repeatCheck:Dock(TOP); repeatCheck:DockMargin(0, 5, 0, 5); repeatCheck:SetText("Misión Repetible (Farmeo)"); repeatCheck:SetValue(data.Config.IsRepeatable)
                repeatCheck.OnChange = function(self, val) data.Config.IsRepeatable = val end
                CreateBindEntry(leftCol, "Cooldown de repetición (Segs):", data.Config, "RepeatCooldown", true)
                
                CreateTitle(leftCol, "TEXTOS DE ESTADO DEL NPC", Color(200, 200, 210))
                CreateBindEntry(leftCol, "Texto si jugador vuelve antes de terminar:", data, "InProgressText")
                CreateBindEntry(leftCol, "Texto final al entregar la misión:", data, "ReadyText")

                local returnCheck = vgui.Create("DCheckBoxLabel", leftCol)
                returnCheck:Dock(TOP); returnCheck:DockMargin(0, 5, 0, 15); returnCheck:SetText("Exigir volver con este NPC para cobrar"); returnCheck:SetValue(data.Config.RequireReturn)
                returnCheck.OnChange = function(self, val) data.Config.RequireReturn = val end

                CreateTitle(leftCol, "RECOMPENSAS (0 = Nada)", Color(200, 200, 210))
                CreateBindEntry(leftCol, "Dinero DarkRP ($):", data.Config.Rewards, "Money", true)
                CreateBindEntry(leftCol, "Curación (Vida):", data.Config.Rewards, "Health", true)
                CreateBindEntry(leftCol, "Dar Arma (Ej: weapon_shotgun):", data.Config.Rewards, "Weapon")

                local lblVisor = vgui.Create("DLabel", rightCol)
                lblVisor:Dock(TOP); lblVisor:DockMargin(15, 10, 15, 5); lblVisor:SetText("Visor 3D y Accesorios del Giver"); lblVisor:SetFont("IvoEditor_Subtitle"); lblVisor:SetTextColor(Color(200, 200, 210)); lblVisor:SizeToContents()

                local midContent = vgui.Create("DPanel", rightCol)
                midContent:Dock(FILL); midContent:DockMargin(15, 5, 15, 15); midContent.Paint = function() end

                local previewBg = vgui.Create("DPanel", midContent)
                previewBg:Dock(LEFT); previewBg:SetWide(220); previewBg.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(20, 20, 25)) end

                local previewPnl = vgui.Create("DModelPanel", previewBg)
                previewPnl:Dock(FILL)
                previewPnl:SetModel(entryModel:GetValue())
                
                previewPnl.Angles = Angle(0, 0, 0)
                function previewPnl:LayoutEntity(ent)
                    self:RunAnimation()
                    if self.Pressed then
                        local mx = gui.MouseX()
                        self.Angles = self.Angles - Angle(0, (self.PressX or mx) - mx, 0)
                        self.PressX = mx
                    end
                    ent:SetAngles(self.Angles)
                    ent:SetupBones()
                end
                function previewPnl:OnMousePressed(mc) if mc == MOUSE_LEFT then self.PressX = gui.MouseX(); self.Pressed = true; self:MouseCapture(true) end end
                function previewPnl:OnMouseReleased(mc) if mc == MOUSE_LEFT then self.Pressed = false; self:MouseCapture(false) end end

                local bgPanel = vgui.Create("DPanel", midContent)
                bgPanel:Dock(FILL); bgPanel:DockMargin(15, 0, 0, 0); bgPanel.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(20, 20, 25)) end
                
                local lblBg = vgui.Create("DLabel", bgPanel)
                lblBg:Dock(TOP); lblBg:DockMargin(10, 10, 10, 5); lblBg:SetText("Bodygroups (Accesorios)"); lblBg:SetFont("IvoEditor_Subtitle"); lblBg:SetTextColor(Color(200, 200, 200))
                
                local bgScroll = vgui.Create("DScrollPanel", bgPanel)
                bgScroll:Dock(FILL); bgScroll:DockMargin(10, 0, 10, 10)
                ModernizeScrollbar(bgScroll)

                data.Config.Bodygroups = data.Config.Bodygroups or ""
                local currentBodygroups = {}
                if data.Config.Bodygroups ~= "" then
                    local bgs = string.Explode(";", data.Config.Bodygroups)
                    for _, bg in ipairs(bgs) do
                        local parts = string.Explode(":", bg)
                        if #parts == 2 then currentBodygroups[tonumber(parts[1])] = tonumber(parts[2]) end
                    end
                end

                local function RefreshBodygroups()
                    bgScroll:Clear()
                    if not IsValid(previewPnl.Entity) then return end
                    
                    local ent = previewPnl.Entity; local hasBodygroups = false
                    for k, v in pairs(currentBodygroups) do ent:SetBodygroup(k, v) end

                    for i = 0, ent:GetNumBodyGroups() - 1 do
                        local count = ent:GetBodygroupCount(i)
                        if count > 1 then
                            hasBodygroups = true
                            currentBodygroups[i] = ent:GetBodygroup(i)
                            local bgName = ent:GetBodygroupName(i)
                            
                            local pnl = vgui.Create("DPanel", bgScroll)
                            pnl:Dock(TOP); pnl:SetTall(35); pnl:DockMargin(0,0,0,5); pnl.Paint = function() end
                            
                            local lbl = vgui.Create("DLabel", pnl)
                            lbl:Dock(LEFT); lbl:SetWide(90); lbl:SetText(string.upper(bgName)); lbl:SetFont("IvoEditor_Text")
                            
                            local combo = vgui.Create("DComboBox", pnl)
                            combo:Dock(FILL); combo:DockMargin(5,5,5,5)
                            for j = 0, count - 1 do combo:AddChoice("Variación " .. j, j) end
                            ModernizeInput(combo)
                            combo:ChooseOptionID(currentBodygroups[i] + 1)
                            combo.OnSelect = function(_, index, value, dataVal) 
                                ent:SetBodygroup(i, dataVal); currentBodygroups[i] = dataVal 
                                local bgStr = ""
                                for k, v in pairs(currentBodygroups) do bgStr = bgStr .. k .. ":" .. v .. ";" end
                                if bgStr ~= "" then bgStr = string.sub(bgStr, 1, -2) end
                                data.Config.Bodygroups = bgStr
                            end
                        end
                    end
                    if not hasBodygroups then
                        local lbl = vgui.Create("DLabel", bgScroll); lbl:Dock(TOP); lbl:SetText("El modelo no tiene accesorios."); lbl:SetFont("IvoEditor_Text"); lbl:SetTextColor(Color(150, 150, 150))
                    end
                end

                entryModel.OnChange = function(self)
                    local mdl = self:GetValue()
                    data.Config.Model = mdl
                    previewPnl:SetModel(mdl)
                    
                    timer.Create("IvoQuest_MainModelPreviewUpdate", 0.2, 1, function()
                        if IsValid(previewPnl) and IsValid(previewPnl.Entity) then
                            local mn, mx = previewPnl.Entity:GetRenderBounds()
                            local size = 0
                            size = math.max(size, math.abs(mn.x) + math.abs(mx.x)); size = math.max(size, math.abs(mn.y) + math.abs(mx.y)); size = math.max(size, math.abs(mn.z) + math.abs(mx.z))
                            previewPnl:SetFOV(35); previewPnl:SetCamPos(Vector(size * 0.7, size * 0.7, size * 0.7)); previewPnl:SetLookAt((mn + mx) * 0.5)
                            IVO_QUEST.ApplyGesture(previewPnl.Entity, data.Config.Gesture or "none")
                            RefreshBodygroups()
                        end
                    end)
                end
                timer.Simple(0.2, function() if IsValid(entryModel) then entryModel:OnChange() end end)

                local dialogSectionFold = CreateFoldableSection(editorScroll, "2. SISTEMA DE DIÁLOGOS INTERACTIVOS Y RESPUESTAS", Color(220, 220, 220), false)

                local diagSection = vgui.Create("DPanel", dialogSectionFold)
                diagSection:Dock(TOP); diagSection:DockMargin(0, 0, 0, 10); diagSection:SetPaintBackground(false)
                diagSection.PerformLayout = function(self) self:SizeToChildren(false, true) end
                
                local function RefreshDialogues()
                    diagSection:Clear()
                    for i, diag in ipairs(data.Dialogues) do
                        -- Retrocompatibilidad: Si era PingPong, lo transformamos mágicamente al nuevo sistema
                        if diag.Speaker then 
                            diag.NPCText = diag.Text 
                            diag.Options = { { Text = "Continuar", Action = "next" } }
                            diag.Speaker = nil; diag.Text = nil 
                        end

                        local stepPnl = vgui.Create("DPanel", diagSection)
                        stepPnl:Dock(TOP); stepPnl:DockMargin(0, 0, 0, 15); stepPnl:DockPadding(0, 0, 0, 5)
                        stepPnl:Dock(TOP); stepPnl:DockMargin(0, 0, 0, 15); stepPnl:DockPadding(0, 0, 0, 0)
                        stepPnl.Paint = function(self, w, h) 
                            draw.RoundedBox(6, 0, 0, w, h, Color(35, 35, 40))
                            draw.RoundedBoxEx(6, 0, 0, 4, h, Color(255, 150, 50), true, false, true, false)
                        end
                        stepPnl.PerformLayout = function(self) self:SizeToChildren(false, true) end
                        
                        local topBar = vgui.Create("DPanel", stepPnl)
                        topBar:Dock(TOP); topBar:SetTall(35); topBar:DockMargin(15, 10, 10, 5)
                        topBar.Paint = function() end
                        local lblStep = vgui.Create("DLabel", topBar)
                        lblStep:Dock(LEFT); lblStep:SetText("Paso de Diálogo #" .. i); lblStep:SetFont("IvoEditor_Subtitle"); lblStep:SetTextColor(Color(220, 220, 220)); lblStep:SizeToContents()
                        
                        local btnDelStep = vgui.Create("DButton", topBar)
                        btnDelStep:Dock(RIGHT); btnDelStep:SetWide(30); btnDelStep:SetText("X"); btnDelStep:SetTextColor(Color(255, 100, 100))
                        btnDelStep.Paint = function(self, w, h) if self:IsHovered() then draw.RoundedBox(4, 0, 0, w, h, Color(255,50,50,20)) end end
                        btnDelStep.DoClick = function() table.remove(data.Dialogues, i); RefreshDialogues() end

                        local pnlNpcText = vgui.Create("DPanel", stepPnl)
                        pnlNpcText:Dock(TOP); pnlNpcText:SetTall(30); pnlNpcText:DockMargin(15, 0, 15, 10)
                        pnlNpcText.Paint = function() end
                        
                        local lblNpc = vgui.Create("DLabel", pnlNpcText)
                        lblNpc:Dock(LEFT); lblNpc:SetWide(100); lblNpc:SetText("El NPC dice:"); lblNpc:SetFont("IvoEditor_Text"); lblNpc:SetTextColor(Color(180, 180, 180))
                        
                        local txtNpc = vgui.Create("DTextEntry", pnlNpcText)
                        txtNpc:Dock(FILL); txtNpc:SetText(diag.NPCText or "")
                        ModernizeInput(txtNpc)
                        txtNpc.OnChange = function(self) data.Dialogues[i].NPCText = self:GetValue() end
                        
                        local optsContainer = vgui.Create("DPanel", stepPnl)
                        optsContainer:Dock(TOP); optsContainer:DockMargin(15, 5, 15, 0); optsContainer.Paint = function() end
                        optsContainer.PerformLayout = function(self) self:SizeToChildren(false, true) end
                        
                        local function RefreshOptions()
                            optsContainer:Clear()
                            diag.Options = diag.Options or {}
                            for j, opt in ipairs(diag.Options) do
                                local optPnl = vgui.Create("DPanel", optsContainer)
                                optPnl:Dock(TOP); optPnl:DockMargin(0, 0, 0, 8); optPnl:SetTall(38); optPnl:DockPadding(5, 5, 5, 5)
                                optPnl.Paint = function(self, w, h) 
                                    draw.RoundedBox(6, 0, 0, w, h, Color(35, 35, 40)) 
                                    draw.RoundedBoxEx(6, 0, 0, 4, h, Color(100, 200, 255), true, false, true, false)
                                end
                                
                                -- 1. CREAMOS ELEMENTOS DERECHOS PRIMERO (Fix para que no salte al escribir)
                                local btnDelOpt = vgui.Create("DButton", optPnl)
                                btnDelOpt:Dock(RIGHT); btnDelOpt:SetWide(25); btnDelOpt:DockMargin(5, 0, 0, 0); btnDelOpt:SetText("X"); btnDelOpt:SetColor(Color(255, 50, 50))
                                btnDelOpt.Paint = function(self, w, h) if self:IsHovered() then draw.RoundedBox(4, 0, 0, w, h, Color(255,50,50,20)) end end
                                btnDelOpt.DoClick = function() table.remove(diag.Options, j); RefreshOptions() end
                                
                                local txtTarget = vgui.Create("DTextEntry", optPnl)
                                txtTarget:Dock(RIGHT); txtTarget:SetWide(40); txtTarget:DockMargin(5, 0, 0, 0); txtTarget:SetNumeric(true)
                                txtTarget:SetText(tostring(opt.Target or (i + 1)))
                                txtTarget:SetVisible(opt.Action == "goto")
                                ModernizeInput(txtTarget)
                                txtTarget.OnChange = function(self) diag.Options[j].Target = tonumber(self:GetValue()) or (i + 1) end

                                local comboAct = vgui.Create("DComboBox", optPnl)
                                comboAct:Dock(RIGHT); comboAct:SetWide(130); comboAct:DockMargin(5, 0, 0, 0)
                                comboAct:AddChoice("Siguiente Paso", "next")
                                comboAct:AddChoice("Ir a Paso...", "goto")
                                comboAct:AddChoice("Aceptar Misión", "accept")
                                comboAct:AddChoice("Cerrar Diálogo", "close")
                                ModernizeInput(comboAct)
                                
                                local selId = 1
                                if opt.Action == "goto" then selId = 2 elseif opt.Action == "accept" then selId = 3 elseif opt.Action == "close" then selId = 4 end
                                comboAct:ChooseOptionID(selId)
                                comboAct.OnSelect = function(_, index, value, dataVal) 
                                    diag.Options[j].Action = dataVal 
                                    txtTarget:SetVisible(dataVal == "goto")
                                end
                                
                                local txtOpt = vgui.Create("DTextEntry", optPnl)
                                txtOpt:Dock(FILL); txtOpt:DockMargin(0, 0, 5, 0); txtOpt:SetText(opt.Text or "")
                                ModernizeInput(txtOpt)
                                txtOpt.OnChange = function(self) diag.Options[j].Text = self:GetValue() end
                            end
                            optsContainer:InvalidateLayout(true); optsContainer:SizeToChildren(false, true)
                            stepPnl:InvalidateLayout(true); stepPnl:SizeToChildren(false, true)
                            diagSection:InvalidateLayout(true); diagSection:SizeToChildren(false, true)
                        end
                        RefreshOptions()
                        
                        local btnAddOpt = vgui.Create("DButton", stepPnl)
                        btnAddOpt:Dock(TOP); btnAddOpt:SetTall(25); btnAddOpt:DockMargin(15, 10, 15, 5); btnAddOpt:SetText("+ Añadir Respuesta")
                        btnAddOpt:SetFont("IvoEditor_Text"); btnAddOpt:SetTextColor(Color(150, 255, 150))
                        btnAddOpt.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(40, 70, 40) or Color(30, 45, 30)) end
                        btnAddOpt.DoClick = function() 
                            diag.Options = diag.Options or {}
                            table.insert(diag.Options, {Text = "Nueva respuesta", Action = "next"})
                            RefreshOptions()
                        end
                    end
                end
                RefreshDialogues()

                local btnAddDiag = vgui.Create("DButton", dialogSectionFold)
                btnAddDiag:Dock(TOP); btnAddDiag:DockMargin(0, 0, 0, 15); btnAddDiag:SetTall(35); btnAddDiag:SetText("+ Añadir Nuevo Paso de Diálogo")
                btnAddDiag:SetFont("IvoEditor_Text"); btnAddDiag:SetTextColor(Color(180, 200, 255))
                btnAddDiag.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(60, 70, 90) or Color(40, 45, 55)) end
                btnAddDiag.DoClick = function() table.insert(data.Dialogues, {NPCText = "...", Options = {{Text = "Continuar", Action = "next"}}}); RefreshDialogues() end
                
                local function CreateOptionsEditor(parent, title, targetKey, defaultOptions)
                    data[targetKey] = data[targetKey] or defaultOptions
                    CreateTitle(parent, title, Color(200, 200, 210))
                    local optList = vgui.Create("DPanel", parent)
                    optList:Dock(TOP); optList:DockMargin(15, 0, 15, 10); optList:SetPaintBackground(false)
                    optList.PerformLayout = function(self) self:SizeToChildren(false, true) end
                    
                    local function Refresh()
                        optList:Clear()
                        for i, opt in ipairs(data[targetKey]) do
                            local node = vgui.Create("DPanel", optList)
                            node:Dock(TOP); node:DockMargin(0, 0, 0, 8); node:SetTall(38); node:DockPadding(5, 5, 5, 5)
                            node.Paint = function(self, w, h) 
                                draw.RoundedBox(6, 0, 0, w, h, Color(35, 35, 40)) 
                                draw.RoundedBoxEx(6, 0, 0, 4, h, Color(100, 255, 100), true, false, true, false)
                            end
                            
                            local btnDel = vgui.Create("DButton", node)
                            btnDel:Dock(RIGHT); btnDel:SetWide(25); btnDel:DockMargin(5, 0, 0, 0); btnDel:SetText("X"); btnDel:SetColor(Color(255, 50, 50))
                            btnDel.Paint = function(self, w, h) if self:IsHovered() then draw.RoundedBox(4, 0, 0, w, h, Color(255,50,50,20)) end end
                            btnDel.DoClick = function() table.remove(data[targetKey], i); Refresh() end

                            local comboAct = vgui.Create("DComboBox", node)
                            comboAct:Dock(RIGHT); comboAct:SetWide(140); comboAct:DockMargin(5, 0, 0, 0)
                            comboAct:AddChoice("Aceptar Misión", "accept"); comboAct:AddChoice("Entregar Misión", "turnin"); comboAct:AddChoice("Cerrar Menú", "close")
                            local selId = 3; if opt.Action == "accept" then selId = 1 elseif opt.Action == "turnin" then selId = 2 end
                            comboAct:ChooseOptionID(selId)
                            comboAct.OnSelect = function(_, index, value, dataVal) data[targetKey][i].Action = dataVal end
                            ModernizeInput(comboAct)
                            
                            local txtLine = vgui.Create("DTextEntry", node)
                            txtLine:Dock(FILL); txtLine:SetText(opt.Text or "")
                            txtLine.OnChange = function(self) data[targetKey][i].Text = self:GetValue() end
                            ModernizeInput(txtLine)
                        end
                        optList:InvalidateLayout(true); optList:SizeToChildren(false, true)
                        if IsValid(parent) then parent:InvalidateLayout(true) end
                    end
                    Refresh()
                    local btnAdd = vgui.Create("DButton", parent)
                    btnAdd:Dock(TOP); btnAdd:DockMargin(15, 0, 15, 15); btnAdd:SetTall(30); btnAdd:SetText("+ Añadir Opción")
                    btnAdd:SetFont("IvoEditor_Text"); btnAdd:SetTextColor(Color(150, 255, 150))
                    btnAdd.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(40, 70, 40) or Color(30, 45, 30)) end
                    btnAdd.DoClick = function() table.insert(data[targetKey], {Text = "Nueva Opción", Action = "close"}); Refresh() end
                end
                
                CreateOptionsEditor(dialogSectionFold, "OPCIONES DE RESPUESTA: MISIÓN EN PROGRESO", "OptionsActive", {{Text = "Continuar", Action = "close"}})
                CreateOptionsEditor(dialogSectionFold, "OPCIONES DE RESPUESTA: AL ENTREGAR LA MISIÓN", "OptionsReady", {{Text = "Entregar", Action = "turnin"}})

            elseif activeTab == "stage" and activeStageData then
                local configSection = CreateFoldableSection(editorScroll, "CONFIGURACIÓN DE LA ETAPA", Color(220, 220, 220), true)

                local pnlContent = vgui.Create("DPanel", configSection)
                pnlContent:Dock(TOP); pnlContent:DockPadding(15, 15, 15, 15)
                pnlContent.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 30)) end
                
                CreateBindEntry(pnlContent, "Texto del Objetivo para el HUD (Ej: Mata a 5 zombies):", activeStageData, "ObjectiveText")
                
                local lblType = vgui.Create("DLabel", pnlContent)
                lblType:Dock(TOP); lblType:DockMargin(0, 5, 0, 0); lblType:SetText("Tipo de Acción:"); lblType:SetFont("IvoEditor_Text")
                local comboType = vgui.Create("DComboBox", pnlContent)
                comboType:Dock(TOP); comboType:SetTall(30); comboType:DockMargin(0, 0, 0, 15)
                comboType:AddChoice("kill (Matar Enemigos)", "kill"); comboType:AddChoice("delivery (Llevar Paquete a Receptor)", "delivery"); comboType:AddChoice("goto (Ir a Zona)", "goto")
                comboType:AddChoice("zone_wait (Esperar tiempo en Zona)", "zone_wait"); comboType:AddChoice("defend (Defender Zona de Enemigos)", "defend")
                comboType:AddChoice("talk (Hablar con un NPC)", "talk")
                ModernizeInput(comboType)

                local pnlTarget = vgui.Create("DPanel", pnlContent); pnlTarget:Dock(TOP); pnlTarget.Paint = function() end
                local lblTarget = vgui.Create("DLabel", pnlTarget); lblTarget:Dock(TOP); lblTarget:DockMargin(0, 5, 0, 0); lblTarget:SetFont("IvoEditor_Text")
                local entryTarget = vgui.Create("DTextEntry", pnlTarget); entryTarget:Dock(TOP); entryTarget:DockMargin(0, 2, 0, 15); entryTarget:SetText(tostring(activeStageData.Target or ""))
                ModernizeInput(entryTarget); entryTarget.OnChange = function(self) activeStageData.Target = self:GetValue() end
                pnlTarget.PerformLayout = function(self) self:SizeToChildren(false, true) end

                local pnlAmount = vgui.Create("DPanel", pnlContent); pnlAmount:Dock(TOP); pnlAmount.Paint = function() end
                local lblAmount = vgui.Create("DLabel", pnlAmount); lblAmount:Dock(TOP); lblAmount:DockMargin(0, 5, 0, 0); lblAmount:SetFont("IvoEditor_Text")
                local entryAmount = vgui.Create("DTextEntry", pnlAmount); entryAmount:Dock(TOP); entryAmount:DockMargin(0, 2, 0, 15); entryAmount:SetNumeric(true); entryAmount:SetText(tostring(activeStageData.Amount or ""))
                ModernizeInput(entryAmount); entryAmount.OnChange = function(self) activeStageData.Amount = tonumber(self:GetValue()) or 0 end
                pnlAmount.PerformLayout = function(self) self:SizeToChildren(false, true) end

                local pnlTargetName = vgui.Create("DPanel", pnlContent); pnlTargetName:Dock(TOP); pnlTargetName.Paint = function() end
                local lblTargetName = vgui.Create("DLabel", pnlTargetName); lblTargetName:Dock(TOP); lblTargetName:DockMargin(0, 5, 0, 0); lblTargetName:SetText("Nombre en el HUD (Ej: Deportistas):"); lblTargetName:SetFont("IvoEditor_Text")
                local entryTargetName = vgui.Create("DTextEntry", pnlTargetName); entryTargetName:Dock(TOP); entryTargetName:DockMargin(0, 2, 0, 15); entryTargetName:SetText(tostring(activeStageData.TargetName or ""))
                ModernizeInput(entryTargetName); entryTargetName.OnChange = function(self) activeStageData.TargetName = self:GetValue() end
                pnlTargetName.PerformLayout = function(self) self:SizeToChildren(false, true) end
                
                local hideCheck = vgui.Create("DCheckBoxLabel", pnlContent)
                hideCheck:Dock(TOP); hideCheck:DockMargin(0, 10, 0, 15); hideCheck:SetText("Ocultar NPC hasta llegar a esta etapa (Faseo)"); 
                if activeStageData.HideUntilStage == nil then activeStageData.HideUntilStage = true end
                hideCheck:SetValue(activeStageData.HideUntilStage)
                hideCheck.OnChange = function(self, val) activeStageData.HideUntilStage = val end
                
                local pnlAdvanced = vgui.Create("DPanel", pnlContent); pnlAdvanced:Dock(TOP); pnlAdvanced.Paint = function() end
                local lblDivider = vgui.Create("DLabel", pnlAdvanced)
                lblDivider:Dock(TOP); lblDivider:DockMargin(0, 15, 0, 5); lblDivider:SetText("Opciones Avanzadas de Enemigos (Para Kill o Defend)"); lblDivider:SetFont("IvoEditor_Subtitle"); lblDivider:SetTextColor(Color(100, 200, 255))
                
                local function CreateInnerEntry(parent, labelText, targetKey, isNumeric)
                    local pnl = vgui.Create("DPanel", parent); pnl:Dock(TOP); pnl.Paint = function() end
                    local lbl = vgui.Create("DLabel", pnl); lbl:Dock(TOP); lbl:DockMargin(0, 5, 0, 0); lbl:SetText(labelText); lbl:SetFont("IvoEditor_Text")
                    local entry = vgui.Create("DTextEntry", pnl); entry:Dock(TOP); entry:DockMargin(0, 2, 0, 15); entry:SetText(tostring(activeStageData[targetKey] or ""))
                    if isNumeric then entry:SetNumeric(true) end; ModernizeInput(entry)
                    entry.OnChange = function(self) activeStageData[targetKey] = isNumeric and (tonumber(self:GetValue()) or 0) or self:GetValue() end
                    pnl.PerformLayout = function(self) self:SizeToChildren(false, true) end
                    pnl.Entry = entry -- FIX: Guardamos la referencia directa a la caja de texto
                    return pnl
                end
                
                local pnlSpawnZone = CreateInnerEntry(pnlAdvanced, "Zona de Spawn de Enemigos:", "SpawnZone")
                local pnlSpawnEnt = CreateInnerEntry(pnlAdvanced, "Entidad a spawnear (Ej: npc_zombie):", "SpawnEntity")
                local pnlSpawnCount = CreateInnerEntry(pnlAdvanced, "Cantidad de Enemigos a Spawnear:", "SpawnCount", true)
                
                local instCheck = vgui.Create("DCheckBoxLabel", pnlAdvanced)
                instCheck:Dock(TOP); instCheck:DockMargin(0, 15, 0, 10); instCheck:SetText("Enemigos Instanciados (Faseo: Solo los ve el jugador)"); instCheck:SetValue(activeStageData.Instanced or false)
                instCheck.OnChange = function(self, val) activeStageData.Instanced = val end
                pnlAdvanced.PerformLayout = function(self) self:SizeToChildren(false, true) end
                
                local pnlTalk = vgui.Create("DPanel", pnlContent)
                pnlTalk:Dock(TOP); pnlTalk:DockMargin(0, 15, 0, 0); pnlTalk.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(20, 20, 25)) end
                
                local lblTalkTitle = vgui.Create("DLabel", pnlTalk)
                lblTalkTitle:Dock(TOP); lblTalkTitle:DockMargin(15, 15, 15, 10); lblTalkTitle:SetText("CONFIGURACIÓN DEL NPC Y SUS DIÁLOGOS"); lblTalkTitle:SetFont("IvoEditor_Subtitle"); lblTalkTitle:SetTextColor(Color(200, 150, 255))
                
                local talkSplit = vgui.Create("DPanel", pnlTalk)
                talkSplit:Dock(TOP); talkSplit:SetTall(300); talkSplit.Paint = function() end

                local tLeftCol = vgui.Create("DScrollPanel", talkSplit)
                tLeftCol:Dock(LEFT); tLeftCol:SetWide(320); tLeftCol:DockMargin(15, 0, 15, 0)
                ModernizeScrollbar(tLeftCol)

                local tRightCol = vgui.Create("DPanel", talkSplit)
                tRightCol:Dock(FILL); tRightCol:DockMargin(0, 0, 15, 0); tRightCol.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(15, 15, 20)) end
                
                local pnlTalkModel = CreateInnerEntry(tLeftCol, "Modelo del NPC (.mdl):", "TalkModel", false)
                if not activeStageData.TalkModel then pnlTalkModel.Entry:SetValue("models/player/barney.mdl"); activeStageData.TalkModel = "models/player/barney.mdl" end

                local pnlTalkGesture = vgui.Create("DPanel", tLeftCol); pnlTalkGesture:Dock(TOP); pnlTalkGesture.Paint = function() end
                local lblTalkGesture = vgui.Create("DLabel", pnlTalkGesture); lblTalkGesture:Dock(TOP); lblTalkGesture:DockMargin(0, 5, 0, 0); lblTalkGesture:SetText("Postura (Gesto):"); lblTalkGesture:SetFont("IvoEditor_Text")
                local comboTalkGesture = vgui.Create("DComboBox", pnlTalkGesture); comboTalkGesture:Dock(TOP); comboTalkGesture:DockMargin(0, 2, 0, 15); comboTalkGesture:SetTall(30)
                comboTalkGesture:AddChoice("Ninguno", "none"); comboTalkGesture:AddChoice("Brazos Cruzados", "crossed_arms")
                comboTalkGesture:AddChoice("Brazos en la Espalda", "crossed_arms_behind"); comboTalkGesture:AddChoice("Sentado", "sit")
                local selIdT = 1; if activeStageData.TalkGesture == "crossed_arms" then selIdT = 2 elseif activeStageData.TalkGesture == "crossed_arms_behind" then selIdT = 3 elseif activeStageData.TalkGesture == "sit" then selIdT = 4 end; comboTalkGesture:ChooseOptionID(selIdT); ModernizeInput(comboTalkGesture)
                comboTalkGesture.OnSelect = function(_, index, value, dataVal) activeStageData.TalkGesture = dataVal; if IsValid(previewTalk) and IsValid(previewTalk.Entity) then IVO_QUEST.ApplyGesture(previewTalk.Entity, dataVal) end end
                pnlTalkGesture.PerformLayout = function(self) self:SizeToChildren(false, true) end

                local previewTalk = vgui.Create("DModelPanel", tRightCol)
                previewTalk:Dock(LEFT); previewTalk:SetWide(200)
                previewTalk:SetModel(pnlTalkModel.Entry:GetValue())
                previewTalk.Angles = Angle(0, 0, 0)
                function previewTalk:LayoutEntity(ent)
                    self:RunAnimation()
                    if self.Pressed then local mx = gui.MouseX() self.Angles = self.Angles - Angle(0, (self.PressX or mx) - mx, 0) self.PressX = mx end
                    ent:SetAngles(self.Angles)
                    ent:SetupBones()
                end
                function previewTalk:OnMousePressed(mc) if mc == MOUSE_LEFT then self.PressX = gui.MouseX(); self.Pressed = true; self:MouseCapture(true) end end
                function previewTalk:OnMouseReleased(mc) if mc == MOUSE_LEFT then self.Pressed = false; self:MouseCapture(false) end end

                local bgTalkScroll = vgui.Create("DScrollPanel", tRightCol)
                bgTalkScroll:Dock(FILL); bgTalkScroll:DockMargin(10, 10, 10, 10)
                ModernizeScrollbar(bgTalkScroll)

                activeStageData.TalkBodygroups = activeStageData.TalkBodygroups or ""
                local talkBodygroups = {}
                if activeStageData.TalkBodygroups ~= "" then
                    local bgs = string.Explode(";", activeStageData.TalkBodygroups)
                    for _, bg in ipairs(bgs) do local parts = string.Explode(":", bg) if #parts == 2 then talkBodygroups[tonumber(parts[1])] = tonumber(parts[2]) end end
                end

                local function RefreshTalkBodygroups()
                    bgTalkScroll:Clear()
                    if not IsValid(previewTalk.Entity) then return end
                    local ent = previewTalk.Entity; local hasBodygroups = false
                    for k, v in pairs(talkBodygroups) do ent:SetBodygroup(k, v) end
                    for i = 0, ent:GetNumBodyGroups() - 1 do
                        local count = ent:GetBodygroupCount(i)
                        if count > 1 then
                            hasBodygroups = true; talkBodygroups[i] = ent:GetBodygroup(i); local bgName = ent:GetBodygroupName(i)
                            local pnl = vgui.Create("DPanel", bgTalkScroll); pnl:Dock(TOP); pnl:SetTall(35); pnl:DockMargin(0,0,0,5); pnl.Paint = function() end
                            local lbl = vgui.Create("DLabel", pnl); lbl:Dock(LEFT); lbl:SetWide(90); lbl:SetText(string.upper(bgName)); lbl:SetFont("IvoEditor_Text")
                            local combo = vgui.Create("DComboBox", pnl); combo:Dock(FILL); combo:DockMargin(5,5,5,5)
                            for j = 0, count - 1 do combo:AddChoice("Variación " .. j, j) end; ModernizeInput(combo); combo:ChooseOptionID(talkBodygroups[i] + 1)
                            combo.OnSelect = function(_, index, value, dataVal) 
                                ent:SetBodygroup(i, dataVal); talkBodygroups[i] = dataVal; local bgStr = ""
                                for k, v in pairs(talkBodygroups) do bgStr = bgStr .. k .. ":" .. v .. ";" end
                                if bgStr ~= "" then bgStr = string.sub(bgStr, 1, -2) end; activeStageData.TalkBodygroups = bgStr
                            end
                        end
                    end
                    if not hasBodygroups then local lbl = vgui.Create("DLabel", bgTalkScroll); lbl:Dock(TOP); lbl:SetText("El modelo no tiene accesorios."); lbl:SetFont("IvoEditor_Text"); lbl:SetTextColor(Color(150, 150, 150)) end
                end

                pnlTalkModel.Entry.OnChange = function(self)
                    local mdl = self:GetValue(); activeStageData.TalkModel = mdl; previewTalk:SetModel(mdl)
                    timer.Create("IvoQuest_StageModelPreviewUpdate", 0.2, 1, function()
                        if IsValid(previewTalk) and IsValid(previewTalk.Entity) then
                            local mn, mx = previewTalk.Entity:GetRenderBounds()
                            local size = math.max(0, math.abs(mn.x) + math.abs(mx.x), math.abs(mn.y) + math.abs(mx.y), math.abs(mn.z) + math.abs(mx.z))
                            previewTalk:SetFOV(35); previewTalk:SetCamPos(Vector(size * 0.7, size * 0.7, size * 0.7)); previewTalk:SetLookAt((mn + mx) * 0.5)
                            IVO_QUEST.ApplyGesture(previewTalk.Entity, activeStageData.TalkGesture or "none")
                            RefreshTalkBodygroups()
                        end
                    end)
                end
                timer.Simple(0.2, function() if IsValid(pnlTalkModel.Entry) then pnlTalkModel.Entry:OnChange() end end)

                local diagTalkSection = vgui.Create("DPanel", pnlTalk)
                diagTalkSection:Dock(TOP); diagTalkSection:DockMargin(15, 10, 15, 10); diagTalkSection:SetPaintBackground(false)
                
                local function RefreshTalkDialogues()
                    diagTalkSection:Clear()
                    activeStageData.Dialogues = activeStageData.Dialogues or {}
                    for i, diag in ipairs(activeStageData.Dialogues) do
                        local stepPnl = vgui.Create("DPanel", diagTalkSection); stepPnl:Dock(TOP); stepPnl:DockMargin(0, 0, 0, 15); stepPnl:DockPadding(0, 0, 0, 0)
                        stepPnl.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(30, 30, 35)); draw.RoundedBoxEx(6, 0, 0, 4, h, Color(200, 150, 255), true, false, true, false) end
                        local topBar = vgui.Create("DPanel", stepPnl); topBar:Dock(TOP); topBar:SetTall(35); topBar:DockMargin(15, 10, 10, 5); topBar.Paint = function() end
                        local lblStep = vgui.Create("DLabel", topBar); lblStep:Dock(LEFT); lblStep:SetText("Paso de Diálogo #" .. i); lblStep:SetFont("IvoEditor_Subtitle"); lblStep:SetTextColor(Color(220, 220, 220)); lblStep:SizeToContents()
                        local btnDelStep = vgui.Create("DButton", topBar); btnDelStep:Dock(RIGHT); btnDelStep:SetWide(30); btnDelStep:SetText("X"); btnDelStep:SetTextColor(Color(255, 100, 100))
                        btnDelStep.Paint = function(self, w, h) if self:IsHovered() then draw.RoundedBox(4, 0, 0, w, h, Color(255,50,50,20)) end end
                        btnDelStep.DoClick = function() table.remove(activeStageData.Dialogues, i); RefreshTalkDialogues() end
                        local pnlNpcText = vgui.Create("DPanel", stepPnl); pnlNpcText:Dock(TOP); pnlNpcText:SetTall(30); pnlNpcText:DockMargin(15, 0, 15, 10); pnlNpcText.Paint = function() end
                        local lblNpc = vgui.Create("DLabel", pnlNpcText); lblNpc:Dock(LEFT); lblNpc:SetWide(100); lblNpc:SetText("El NPC dice:"); lblNpc:SetFont("IvoEditor_Text"); lblNpc:SetTextColor(Color(180, 180, 180))
                        local txtNpc = vgui.Create("DTextEntry", pnlNpcText); txtNpc:Dock(FILL); txtNpc:SetText(diag.NPCText or ""); ModernizeInput(txtNpc); txtNpc.OnChange = function(self) activeStageData.Dialogues[i].NPCText = self:GetValue() end
                        
                        local optsContainer = vgui.Create("DPanel", stepPnl); optsContainer:Dock(TOP); optsContainer:DockMargin(15, 5, 15, 0); optsContainer.Paint = function() end
                        
                        local function RefreshTalkOptions()
                            optsContainer:Clear(); diag.Options = diag.Options or {}
                            for j, opt in ipairs(diag.Options) do
                                local optPnl = vgui.Create("DPanel", optsContainer); optPnl:Dock(TOP); optPnl:DockMargin(0, 0, 0, 8); optPnl:SetTall(38); optPnl:DockPadding(5, 5, 5, 5)
                                optPnl.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 30)); draw.RoundedBoxEx(6, 0, 0, 4, h, Color(100, 200, 255), true, false, true, false) end
                                local btnDelOpt = vgui.Create("DButton", optPnl); btnDelOpt:Dock(RIGHT); btnDelOpt:SetWide(25); btnDelOpt:DockMargin(5, 0, 0, 0); btnDelOpt:SetText("X"); btnDelOpt:SetColor(Color(255, 50, 50))
                                btnDelOpt.Paint = function(self, w, h) if self:IsHovered() then draw.RoundedBox(4, 0, 0, w, h, Color(255,50,50,20)) end end
                                btnDelOpt.DoClick = function() table.remove(diag.Options, j); RefreshTalkOptions() end
                                local txtTarget = vgui.Create("DTextEntry", optPnl); txtTarget:Dock(RIGHT); txtTarget:SetWide(40); txtTarget:DockMargin(5, 0, 0, 0); txtTarget:SetNumeric(true); txtTarget:SetText(tostring(opt.Target or (i + 1))); txtTarget:SetVisible(opt.Action == "goto"); ModernizeInput(txtTarget)
                                txtTarget.OnChange = function(self) diag.Options[j].Target = tonumber(self:GetValue()) or (i + 1) end
                                local comboAct = vgui.Create("DComboBox", optPnl); comboAct:Dock(RIGHT); comboAct:SetWide(140); comboAct:DockMargin(5, 0, 0, 0)
                                comboAct:AddChoice("Siguiente Paso", "next"); comboAct:AddChoice("Ir a Paso...", "goto"); comboAct:AddChoice("Finalizar Charla", "complete_talk"); comboAct:AddChoice("Cerrar Diálogo", "close")
                                ModernizeInput(comboAct); local selId = 1; if opt.Action == "goto" then selId = 2 elseif opt.Action == "complete_talk" then selId = 3 elseif opt.Action == "close" then selId = 4 end; comboAct:ChooseOptionID(selId)
                                comboAct.OnSelect = function(_, index, value, dataVal) diag.Options[j].Action = dataVal; txtTarget:SetVisible(dataVal == "goto") end
                                local txtOpt = vgui.Create("DTextEntry", optPnl); txtOpt:Dock(FILL); txtOpt:DockMargin(0, 0, 5, 0); txtOpt:SetText(opt.Text or ""); ModernizeInput(txtOpt)
                                txtOpt.OnChange = function(self) diag.Options[j].Text = self:GetValue() end
                            end
                            optsContainer:InvalidateLayout(true); optsContainer:SizeToChildren(false, true); stepPnl:InvalidateLayout(true); stepPnl:SizeToChildren(false, true)
                            diagTalkSection:InvalidateLayout(true); diagTalkSection:SizeToChildren(false, true)
                            if IsValid(pnlTalk) then pnlTalk:InvalidateLayout(true) end
                            if IsValid(configSection) then configSection:InvalidateLayout(true) end
                        end
                        RefreshTalkOptions()
                        local btnAddOpt = vgui.Create("DButton", stepPnl); btnAddOpt:Dock(TOP); btnAddOpt:SetTall(25); btnAddOpt:DockMargin(15, 10, 15, 10); btnAddOpt:SetText("+ Añadir Respuesta"); btnAddOpt:SetFont("IvoEditor_Text"); btnAddOpt:SetTextColor(Color(150, 255, 150))
                        btnAddOpt.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(40, 70, 40) or Color(30, 45, 30)) end
                        btnAddOpt.DoClick = function() diag.Options = diag.Options or {}; table.insert(diag.Options, {Text = "Nueva respuesta", Action = "next"}); RefreshTalkOptions() end
                    end
                end
                RefreshTalkDialogues()

                local btnAddDiag = vgui.Create("DButton", pnlTalk)
                btnAddDiag:Dock(TOP); btnAddDiag:DockMargin(15, 0, 15, 15); btnAddDiag:SetTall(35); btnAddDiag:SetText("+ Añadir Nuevo Paso de Diálogo")
                btnAddDiag:SetFont("IvoEditor_Text"); btnAddDiag:SetTextColor(Color(180, 200, 255))
                btnAddDiag.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(60, 70, 90) or Color(40, 45, 55)) end
                btnAddDiag.DoClick = function() activeStageData.Dialogues = activeStageData.Dialogues or {}; table.insert(activeStageData.Dialogues, {NPCText = "...", Options = {{Text = "Continuar", Action = "next"}}}); RefreshTalkDialogues() end
                pnlTalk.PerformLayout = function(self) self:SizeToChildren(false, true) end

                local function UpdateStageUI()
                    local t = activeStageData.Type or "kill"
                    pnlTarget:SetVisible(true)
                    pnlAmount:SetVisible(t == "kill" or t == "zone_wait" or t == "defend")
                    pnlTargetName:SetVisible(t == "kill" or t == "talk")
                    pnlAdvanced:SetVisible(t == "kill" or t == "defend")
                    hideCheck:SetVisible(t == "talk" or t == "delivery")
                    pnlTalk:SetVisible(t == "talk")
                    
                    pnlSpawnEnt:SetVisible(t == "defend")
                    pnlSpawnCount:SetVisible(t == "defend")
                    
                    if t == "kill" then lblTarget:SetText("Clase del NPC a Matar (Ej: npc_combine_s):"); lblAmount:SetText("Cantidad a Matar:")
                    elseif t == "delivery" then lblTarget:SetText("ID del Receptor (Ej: pablo_medico):")
                    elseif t == "goto" then lblTarget:SetText("Nombre de la Zona Destino:")
                    elseif t == "zone_wait" then lblTarget:SetText("Nombre de la Zona:"); lblAmount:SetText("Tiempo a Esperar (Segundos):")
                    elseif t == "defend" then lblTarget:SetText("Nombre de la Zona a Defender:"); lblAmount:SetText("Tiempo a Sobrevivir (Segundos):")
                    elseif t == "talk" then lblTarget:SetText("ID del NPC con el que Hablar (ID de Receptor):"); lblTargetName:SetText("Nombre del NPC en el HUD:") end
                    
                    timer.Simple(0.01, function() if IsValid(pnlContent) then pnlContent:InvalidateLayout(true) end if IsValid(configSection) then configSection:InvalidateLayout(true) end end)
                end

                comboType:SetValue(activeStageData.Type or "kill")
                comboType.OnSelect = function(_, index, value, dataVal) activeStageData.Type = dataVal; UpdateStageUI() end
                UpdateStageUI()

                pnlContent.PerformLayout = function(self) self:SizeToChildren(false, true) end

                local btnDelStage = vgui.Create("DButton", editorScroll)
                btnDelStage:Dock(TOP); btnDelStage:SetTall(45); btnDelStage:DockMargin(0, 20, 0, 10); btnDelStage:SetText("ELIMINAR ESTA ETAPA"); btnDelStage:SetFont("IvoEditor_Title"); btnDelStage:SetTextColor(color_white)
                btnDelStage.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(200, 50, 50) or Color(150, 40, 40)) end
                btnDelStage.DoClick = function()
                    Derma_Query("¿Seguro que quieres eliminar esta etapa?", "Eliminar", "Sí", function() table.RemoveByValue(data.Stages, activeStageData); btnBack:DoClick() end, "No", function() end)
                end
            end
        end

        RefreshGrid()

        -- ==========================================
        -- BOTÓN DE GUARDADO FINAL
        -- ==========================================
        local bottomPnl = vgui.Create("DPanel", contentArea)
        bottomPnl:Dock(BOTTOM); bottomPnl:SetTall(50); bottomPnl.Paint = function() end
        bottomPnl:Receiver("QuestModules", TrashReceiver)

        local btnSave = vgui.Create("DButton", bottomPnl)
        btnSave:Dock(FILL); btnSave:SetText("COMPILAR Y GUARDAR MISIÓN"); btnSave:SetFont("IvoEditor_Title"); btnSave:SetTextColor(Color(50, 255, 50))
        btnSave.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(30, 80, 30) or Color(20, 60, 20)) end
        
        btnSave.DoClick = function()
            local newID = string.Trim(missionID or "")
            if newID == "" then LocalPlayer():ChatPrint("El ID no puede estar vacío. Ve a PRINCIPAL para ponerle uno.") return end
            
            SyncStagesOrder() 
            for i, stg in ipairs(data.Stages) do stg.StageID = i end

            local json = util.TableToJSON(data)
            local compressed = util.Compress(json)
            net.Start("IvoQuest_SaveMission") net.WriteString(newID) net.WriteUInt(#compressed, 32) net.WriteData(compressed, #compressed) net.SendToServer()
            
            timer.Simple(0.3, function() BuildDashboard() end)
            LocalPlayer():ChatPrint("[IvoQuest] Misión Guardada Exitosamente.")
        end
    end

    BuildDashboard()
end)