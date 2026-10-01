if SERVER then return end

local function OpenAdminMenu()
	local ply = LocalPlayer()
	if not ply:IsSuperAdmin() then return end
	
	local frame = vgui.Create("DFrame")
	frame:SetSize(800, 600)
	frame:Center()
	frame:SetTitle("LSCS Admin Menu - Spawn de Objetos")
	frame:MakePopup()
	
	local tabs = vgui.Create("DPropertySheet", frame)
	tabs:Dock(FILL)
	
	local function PopulateAdminList(panel, items)
		local scroll = vgui.Create("DScrollPanel", panel)
		scroll:Dock(FILL)
		
		local grid = vgui.Create("DIconLayout", scroll)
		grid:Dock(FILL)
		grid:SetSpaceX(10)
		grid:SetSpaceY(10)
		
		for id, data in pairs(items) do
			local itemBtn = vgui.Create("DButton", grid)
			itemBtn:SetSize(120, 150)
			itemBtn:SetText("")
			
			itemBtn.Paint = function(self, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 200))
				if self:IsHovered() then
					draw.RoundedBox(4, 0, 0, w, h, Color(80, 80, 80, 250))
				end
				
				if data.icon then
					surface.SetMaterial(data.icon)
					surface.SetDrawColor(255, 255, 255)
					surface.DrawTexturedRect(28, 10, 64, 64)
				end
				
				draw.SimpleText(data.name, "DermaDefault", w/2, 90, Color(255, 255, 255), TEXT_ALIGN_CENTER)
				draw.SimpleText("Click para Spawnear", "DermaDefault", w/2, 110, Color(150, 255, 150), TEXT_ALIGN_CENTER)
			end
			
			itemBtn.DoClick = function()
				net.Start("lscs_admin_give_item")
				net.WriteString(data.class)
				net.SendToServer()
			end
		end
	end
	
	local hiltsTab = vgui.Create("DPanel", tabs)
	PopulateAdminList(hiltsTab, LSCS.Hilt)
	tabs:AddSheet("Mangos (Hilts)", hiltsTab, "icon16/wrench.png")
	
	local crystalsTab = vgui.Create("DPanel", tabs)
	PopulateAdminList(crystalsTab, LSCS.Blade)
	tabs:AddSheet("Cristales (Blades)", crystalsTab, "icon16/color_wheel.png")
	
	local playersTab = vgui.Create("DPanel", tabs)
	local plyScroll = vgui.Create("DScrollPanel", playersTab)
	plyScroll:Dock(FILL)
	
	for _, p in ipairs(player.GetAll()) do
		local pnl = vgui.Create("DPanel", plyScroll)
		pnl:Dock(TOP)
		pnl:SetTall(50)
		pnl:DockMargin(5, 5, 5, 0)
		pnl.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 200))
			draw.SimpleText(p:Nick(), "DermaDefaultBold", 10, h/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("LVL: " .. p:lscsGetLevel() .. " | XP: " .. p:lscsGetXP() .. " | SP: " .. p:lscsGetSkillPoints(), "DermaDefault", 150, h/2, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		
		local btnReset = vgui.Create("DButton", pnl)
		btnReset:Dock(RIGHT)
		btnReset:SetWide(100)
		btnReset:DockMargin(5, 10, 10, 10)
		btnReset:SetText("Reset Inv")
		btnReset.DoClick = function()
			net.Start("lscs_admin_reset_inventory")
			net.WriteEntity(p)
			net.SendToServer()
		end
		
		local btnXP = vgui.Create("DButton", pnl)
		btnXP:Dock(RIGHT)
		btnXP:SetWide(60)
		btnXP:DockMargin(5, 10, 5, 10)
		btnXP:SetText("Set XP")
		btnXP.DoClick = function()
			Derma_StringRequest("Set XP", "Ingrese la cantidad de XP:", "0", function(text)
				net.Start("lscs_admin_set_xp")
				net.WriteEntity(p)
				net.WriteInt(tonumber(text) or 0, 32)
				net.SendToServer()
			end)
		end
		
		local btnLvl = vgui.Create("DButton", pnl)
		btnLvl:Dock(RIGHT)
		btnLvl:SetWide(60)
		btnLvl:DockMargin(5, 10, 5, 10)
		btnLvl:SetText("Set LVL")
		btnLvl.DoClick = function()
			Derma_StringRequest("Set Nivel", "Ingrese el nivel:", "1", function(text)
				net.Start("lscs_admin_set_level")
				net.WriteEntity(p)
				net.WriteInt(tonumber(text) or 1, 32)
				net.SendToServer()
			end)
		end
		
		local btnSP = vgui.Create("DButton", pnl)
		btnSP:Dock(RIGHT)
		btnSP:SetWide(60)
		btnSP:DockMargin(5, 10, 5, 10)
		btnSP:SetText("Give SP")
		btnSP.DoClick = function()
			Derma_StringRequest("Give SP", "Ingrese los SP a dar:", "1", function(text)
				net.Start("lscs_admin_give_sp")
				net.WriteEntity(p)
				net.WriteInt(tonumber(text) or 1, 32)
				net.SendToServer()
			end)
		end
	end
	
	tabs:AddSheet("Jugadores", playersTab, "icon16/group.png")
end

concommand.Add("ivolscsadmin", function()
	OpenAdminMenu()
end)
