if SERVER then return end

surface.CreateFont("LSCS_SkillTree_Title", {
	font = "Roboto",
	size = 40,
	weight = 800,
	antialias = true,
})

net.Receive("lscs_sync_unlocked_skills", function()
	local skills = net.ReadTable()
	LocalPlayer().m_lscs_unlocked_skills = skills
	
	-- Actualizar la info del jugador para que carguen los poderes en la selectora
	if LocalPlayer().lscsBuildPlayerInfo then
		LocalPlayer():lscsBuildPlayerInfo()
	end
end)

local function OpenSkillTree()
	local ply = LocalPlayer()
	
	local frame = vgui.Create("DFrame")
	frame:SetSize(800, 600)
	frame:Center()
	frame:SetTitle("Árbol de Habilidades LSCS")
	frame:MakePopup()
	
	frame:SetTitle("")
	frame:MakePopup()
	frame.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(24, 30, 54, 250))
		draw.RoundedBoxEx(8, 0, 0, w, 30, Color(0, 100, 200, 255), true, true, false, false)
		draw.SimpleText("ÁRBOL DE HABILIDADES LSCS", "DermaLarge", w/2, 15, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		draw.SimpleText("Puntos de Habilidad Disponibles: " .. ply:lscsGetSkillPoints(), "Trebuchet24", 20, 50, Color(255, 200, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
	
	-- Pestañas personalizadas
	local activeTab = 1
	local contentPanel = vgui.Create("DPanel", frame)
	contentPanel:SetPos(20, 120)
	contentPanel:SetSize(760, 410)
	contentPanel.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(15, 20, 40, 200))
	end

	local panels = {}

	local function PopulateList(panel, items, isForce)
		local scroll = vgui.Create("DScrollPanel", panel)
		scroll:Dock(FILL)
		
		-- Un poco de padding
		local scrollContainer = vgui.Create("DPanel", scroll)
		scrollContainer:Dock(FILL)
		scrollContainer.Paint = function() end
		
		for id, data in pairs(items) do
			if id == "default" then continue end
			
			local itemPnl = vgui.Create("DPanel", scroll)
			itemPnl:Dock(TOP)
			itemPnl:SetTall(90)
			itemPnl:DockMargin(10, 10, 10, 0)
			
			-- Verificación universal
			local oldFormat = "lscs_" .. (isForce and "force_" or "stance_") .. id
			local isUnlocked = table.HasValue(ply:lscsGetUnlockedSkills(), id) or table.HasValue(ply:lscsGetUnlockedSkills(), oldFormat)
			
			itemPnl.Paint = function(self, w, h)
				local bgColor = isUnlocked and Color(0, 80, 40, 200) or Color(40, 45, 60, 200)
				draw.RoundedBox(6, 0, 0, w, h, bgColor)
				
				if data.icon then
					surface.SetMaterial(data.icon)
					surface.SetDrawColor(255, 255, 255)
					surface.DrawTexturedRect(13, 13, 64, 64)
				end
				
				draw.SimpleText(data.name or id, "DermaLarge", 90, 10, Color(255, 255, 255))
				draw.SimpleText(data.description or "Sin descripción.", "DermaDefault", 90, 40, Color(180, 180, 180))
				
				if isUnlocked then
					draw.SimpleText("DESBLOQUEADO", "DermaDefaultBold", 90, 65, Color(0, 255, 100))
				else
					draw.SimpleText("Costo: 1 SP", "DermaDefaultBold", 90, 65, Color(255, 100, 100))
				end
			end
			
			if not isUnlocked then
				local btn = vgui.Create("DButton", itemPnl)
				btn:Dock(RIGHT)
				btn:SetWide(140)
				btn:DockMargin(10, 15, 15, 15)
				btn:SetText("")
				btn.Paint = function(self, w, h)
					draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(0, 150, 255, 255) or Color(0, 100, 200, 255))
					draw.SimpleText(self.TextOverride or "Desbloquear", "DermaDefaultBold", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				btn.DoClick = function()
					net.Start("lscs_unlock_skill")
					net.WriteString(id)
					net.WriteString(isForce and "force" or "stance")
					net.SendToServer()
					
					surface.PlaySound("buttons/blip1.wav")
					btn.TextOverride = "Comprando..."
					btn:SetEnabled(false)
					timer.Simple(1.0, function()
						if IsValid(frame) then
							frame:Close()
							OpenSkillTree()
						end
					end)
				end
			end
		end
	end

	-- Crear Paneles
	panels[1] = vgui.Create("DPanel", contentPanel)
	panels[1]:Dock(FILL)
	panels[1].Paint = function() end
	PopulateList(panels[1], LSCS.Stance, false)

	panels[2] = vgui.Create("DPanel", contentPanel)
	panels[2]:Dock(FILL)
	panels[2].Paint = function() end
	PopulateList(panels[2], LSCS.Force, true)

	panels[2]:Hide() -- Ocultar inicialmente

	-- Botones de Pestañas
	local btnStances = vgui.Create("DButton", frame)
	btnStances:SetPos(20, 80)
	btnStances:SetSize(180, 40)
	btnStances:SetText("")
	btnStances.Paint = function(self, w, h)
		draw.RoundedBoxEx(6, 0, 0, w, h, activeTab == 1 and Color(15, 20, 40, 255) or Color(30, 40, 60, 255), true, true, false, false)
		draw.SimpleText("POSTURAS", "DermaDefaultBold", w/2, h/2, activeTab == 1 and Color(255,255,255) or Color(150,150,150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnStances.DoClick = function()
		activeTab = 1
		panels[1]:Show()
		panels[2]:Hide()
		surface.PlaySound("buttons/lightswitch2.wav")
	end

	local btnForce = vgui.Create("DButton", frame)
	btnForce:SetPos(205, 80)
	btnForce:SetSize(180, 40)
	btnForce:SetText("")
	btnForce.Paint = function(self, w, h)
		draw.RoundedBoxEx(6, 0, 0, w, h, activeTab == 2 and Color(15, 20, 40, 255) or Color(30, 40, 60, 255), true, true, false, false)
		draw.SimpleText("PODERES", "DermaDefaultBold", w/2, h/2, activeTab == 2 and Color(255,255,255) or Color(150,150,150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnForce.DoClick = function()
		activeTab = 2
		panels[2]:Show()
		panels[1]:Hide()
		surface.PlaySound("buttons/lightswitch2.wav")
	end

	-- Botón de Reset
	local resetBtn = vgui.Create("DButton", frame)
	resetBtn:SetPos(600, 545)
	resetBtn:SetSize(180, 40)
	resetBtn:SetText("")
	resetBtn.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(220, 50, 50, 255) or Color(150, 30, 30, 255))
		draw.SimpleText("RESETEAR ÁRBOL", "DermaDefaultBold", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	resetBtn.DoClick = function()
		Derma_Query(
			"¿Estás seguro de que quieres resetear tu árbol de habilidades?\n\nPerderás todas las habilidades y posturas desbloqueadas, pero recuperarás todos los puntos gastados.",
			"Confirmar Reseteo",
			"Sí, resetear",
			function()
				net.Start("lscs_reset_skills")
				net.SendToServer()
				surface.PlaySound("buttons/button14.wav")
				frame:Close()
			end,
			"Cancelar",
			function() end
		)
	end
end

concommand.Add("lscs_skilltree", function()
	OpenSkillTree()
end)
