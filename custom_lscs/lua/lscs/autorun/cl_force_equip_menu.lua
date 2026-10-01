if SERVER then return end

-- Recibir las habilidades desbloqueadas desde el servidor (Workbench)
net.Receive("lscs_sync_skilltree", function()
	local num = net.ReadUInt(16)
	local skills = {}
	for i = 1, num do
		table.insert(skills, net.ReadString())
	end
	
	local ply = LocalPlayer()
	if IsValid(ply) then
		ply.m_lscs_unlocked_skills = skills
		if ply.lscsBuildPlayerInfo then
			ply:lscsBuildPlayerInfo()
		end
	end
end)

local EquipMenuFrame = nil

local function GetClientLayout()
	if LSCS_ClientLayoutCache then return LSCS_ClientLayoutCache end
	local content = file.Read("lscs_client_layout.json", "DATA")
	LSCS_ClientLayoutCache = content and util.JSONToTable(content) or {}
	return LSCS_ClientLayoutCache
end

local function SaveClientLayout(tbl)
	local flat = {}
	for k, v in pairs(tbl) do
		flat[tostring(k)] = tostring(v)
	end
	LSCS_ClientLayoutCache = flat
	file.Write("lscs_client_layout.json", util.TableToJSON(flat))
end

-- Variables para la UI
local selectedToEquip = {}
local TargetSlot = 1

local function OpenForceEquipMenu()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or not wep.LSCS then return end

	-- Obtener poderes desbloqueados
	local unlocked_raw = ply.lscsGetUnlockedSkills and ply:lscsGetUnlockedSkills() or {}
	local unlocked_powers = {}
	
	-- Filtrar solo los poderes de la fuerza válidos
	for _, id in ipairs(unlocked_raw) do
		local forceID = string.Replace(id, "lscs_force_", "")
		local powerData = LSCS:GetForce(forceID)
		if powerData then
			table.insert(unlocked_powers, {id = id, data = powerData})
		end
	end

	-- Cargar lo que ya tenemos equipado
	selectedToEquip = {}
	local server_powers = LSCS_SyncedForcePowers or {}
	if table.IsEmpty(server_powers) then
		local force_abilities = ply:lscsGetForceAbilities()
		if force_abilities then
			for _, object in pairs(force_abilities) do
				if object and object.id then
					server_powers[object.id] = true
				end
			end
		end
	end

	local layout = GetClientLayout()
	local assigned = {}

	for slot, id in pairs(layout) do
		slot = tonumber(slot)
		if slot and slot >= 1 and slot <= 9 and server_powers[id] then
			selectedToEquip[slot] = id
			assigned[id] = true
		end
	end

	for id, _ in pairs(server_powers) do
		if not assigned[id] then
			for i=1, 9 do
				if not selectedToEquip[i] then
					selectedToEquip[i] = id
					break
				end
			end
		end
	end

	if IsValid(EquipMenuFrame) then EquipMenuFrame:Remove() end

	EquipMenuFrame = vgui.Create("DFrame")
	EquipMenuFrame:SetSize(800, 600)
	EquipMenuFrame:Center()
	EquipMenuFrame:SetTitle("")
	EquipMenuFrame:MakePopup()
	EquipMenuFrame:SetKeyboardInputEnabled(true)
	EquipMenuFrame.OnKeyCodePressed = function(self, key)
		if key >= KEY_1 and key <= KEY_9 then
			TargetSlot = key - KEY_1 + 1
			RefreshUI()
		end
	end
	EquipMenuFrame.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(24, 30, 54, 250))
		draw.RoundedBoxEx(8, 0, 0, w, 30, Color(0, 100, 200, 255), true, true, false, false)		
		draw.SimpleText("EQUIPAMIENTO DE PODERES DE LA FUERZA", "DermaLarge", w/2, 15, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		draw.SimpleText("Tus Poderes Desbloqueados:", "Trebuchet24", w/2, 50, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end

	-- Panel Central: Lista de Poderes Desbloqueados
	local leftPanel = vgui.Create("DScrollPanel", EquipMenuFrame)
	leftPanel:SetPos(150, 90)
	leftPanel:SetSize(500, 320)
	
	local leftLayout = vgui.Create("DIconLayout", leftPanel)
	leftLayout:Dock(FILL)
	leftLayout:SetSpaceX(10)
	leftLayout:SetSpaceY(10)

	-- El panel inferior horizontal
	local bottomPanel = vgui.Create("DPanel", EquipMenuFrame)
	bottomPanel:SetPos(0, 430)
	bottomPanel:SetSize(800, 100)
	bottomPanel.Paint = function(self, w, h)
		-- Fondo oscuro transparente detrás de la barra
		draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 150))
	end

	local function RefreshUI()
		leftLayout:Clear()
		bottomPanel:Clear()
		
		-- Renderizar Desbloqueados en la lista central
		for _, powerInfo in ipairs(unlocked_powers) do
			local pID = powerInfo.id
			local pData = powerInfo.data
			
			local isEquipped = table.HasValue(selectedToEquip, pID)
			
			local btn = leftLayout:Add("DButton")
			btn:SetSize(235, 60)
			btn:SetText("")
			btn.Paint = function(self, w, h)
				draw.RoundedBox(4, 0, 0, w, h, isEquipped and Color(0, 150, 50, 150) or Color(50, 50, 50, 200))
				if pData.icon then
					surface.SetDrawColor(255, 255, 255, 255)
					surface.SetMaterial(pData.icon)
					surface.DrawTexturedRect(5, 5, 50, 50)
				end
				draw.SimpleText(pData.name or pID, "DermaDefaultBold", 65, h/2, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
			btn.DoClick = function()
				local old_pos = table.KeyFromValue(selectedToEquip, pID)
				
				if old_pos then
					selectedToEquip[old_pos] = nil
					if old_pos < TargetSlot then
						TargetSlot = TargetSlot - 1
					end
				end

				-- Insertamos exactamente en la ranura deseada, sobrescribiendo si hay algo
				selectedToEquip[TargetSlot] = pID
				TargetSlot = math.min(TargetSlot + 1, 9)
				
				RefreshUI()
			end
		end
		
		-- Renderizar Barra Horizontal Inferior (Exactamente 9 casillas)
		local slotSize = 50
		local padding = 10
		local totalWidth = (9 * slotSize) + (8 * padding)
		local startX = (800 / 2) - (totalWidth / 2)
		local yPos = 25

		for i = 1, 9 do
			local slotBtn = vgui.Create("DButton", bottomPanel)
			slotBtn:SetSize(slotSize, slotSize)
			slotBtn:SetPos(startX + ((i - 1) * (slotSize + padding)), yPos)
			slotBtn:SetText("")
			
			local eqID = selectedToEquip[i]
			local forceID = eqID and string.Replace(eqID, "lscs_force_", "") or nil
			local eqData = forceID and LSCS:GetForce(forceID) or nil
			
			slotBtn.Paint = function(self, w, h)
				local isHovered = self:IsHovered()
				local bgColor = eqData and Color(0, 150, 255, 200) or Color(30, 30, 30, 180)
				
				if TargetSlot == i then
					bgColor = Color(200, 150, 0, 255)
				elseif isHovered then
					bgColor = Color(100, 200, 255, 255)
				end

				draw.RoundedBox(4, 0, 0, w, h, bgColor)
				
				-- Borde brillante al pasar el ratón o si está equipado
				if isHovered or eqData then
					surface.SetDrawColor(255, 255, 255, isHovered and 255 or 100)
					surface.DrawOutlinedRect(0, 0, w, h, 2)
				end

				if eqData and eqData.icon then
					surface.SetDrawColor(255, 255, 255, 255)
					surface.SetMaterial(eqData.icon)
					surface.DrawTexturedRect(5, 5, w - 10, h - 10)
				end
				
				draw.SimpleText(tostring(i), "DermaDefaultBold", w - 10, h - 12, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			
			slotBtn.DoClick = function()
				TargetSlot = i
				RefreshUI()
			end
			
			slotBtn.DoRightClick = function()
				if eqID then
					selectedToEquip[i] = nil
					RefreshUI()
				end
			end
		end
	end

	RefreshUI()

	-- Botón Guardar
	local saveBtn = vgui.Create("DButton", EquipMenuFrame)
	saveBtn:SetPos(300, 545)
	saveBtn:SetSize(200, 40)
	saveBtn:SetText("")
	saveBtn.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, self:IsHovered() and Color(0, 200, 100, 255) or Color(0, 150, 50, 255))
		draw.SimpleText("GUARDAR Y EQUIPAR", "Trebuchet24", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	saveBtn.DoClick = function()
		SaveClientLayout(selectedToEquip)

		local finalTable = {}
		for i=1, 9 do
			if selectedToEquip[i] then
				table.insert(finalTable, selectedToEquip[i])
			end
		end

		net.Start("lscs_set_force_slots")
		net.WriteUInt(#finalTable, 4)
		for _, id in ipairs(finalTable) do
			net.WriteString(id)
		end
		net.SendToServer()
		
		surface.PlaySound("buttons/button14.wav")
		EquipMenuFrame:Close()
		chat.AddText(Color(0, 255, 0), "[LSCS] Poderes de la Fuerza actualizados correctamente.")
	end
end

concommand.Add("lscs_equip_menu", OpenForceEquipMenu)

-- Hook para abrir con ALT + G
hook.Add("PlayerButtonDown", "LSCS_OpenEquipMenu_AltG", function(ply, btn)
	if IsFirstTimePredicted() and btn == KEY_G and input.IsKeyDown(KEY_LALT) then
		local wep = ply:GetActiveWeapon()
		if IsValid(wep) and wep.LSCS then
			OpenForceEquipMenu()
		end
	end
end)
