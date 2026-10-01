if SERVER then return end

local function OpenStanceSelector()
	local ply = LocalPlayer()
	local combo = ply:lscsGetCombo()
	if not combo or #combo == 0 then return end
	
	-- Close existing if any
	if IsValid(LSCS_StanceSelectorFrame) then
		LSCS_StanceSelectorFrame:Remove()
	end
	
	local frame = vgui.Create("DFrame")
	LSCS_StanceSelectorFrame = frame
	frame:SetSize(400, 500)
	frame:Center()
	frame:SetTitle("Seleccionar Postura (Stance)")
	frame:MakePopup()
	
	local scroll = vgui.Create("DScrollPanel", frame)
	scroll:Dock(FILL)
	
	for i, stance_id in ipairs(combo) do
		local stance = LSCS:GetStance(stance_id)
		if not stance then continue end
		
		local btn = vgui.Create("DButton", scroll)
		btn:Dock(TOP)
		btn:SetTall(60)
		btn:DockMargin(5, 5, 5, 0)
		btn:SetText("")
		
		btn.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(80, 80, 80, 200) or Color(40, 40, 40, 200))
			if stance.icon then
				surface.SetMaterial(stance.icon)
				surface.SetDrawColor(255, 255, 255)
				surface.DrawTexturedRect(8, 8, 44, 44)
			end
			draw.SimpleText(stance.name, "DermaDefaultBold", 60, h/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		
		btn.DoClick = function()
			net.Start("lscs_equip_stance")
			net.WriteInt(i, 16)
			net.SendToServer()
			frame:Close()
		end
	end
end

net.Receive("lscs_open_stance_menu", function()
	OpenStanceSelector()
end)
