local col_gray_dark = Color( 30, 30, 30, 255 )
local col_gray_light = Color( 50, 50, 50, 255 )
local col_gray_lighter = Color( 75, 75, 75, 255 )

local col_green = Color( 0, 130, 0, 255 )
local col_green_hovered = Color( 0, 160, 0, 255 )

local col_red = Color( 130, 0, 0, 255 )
local col_red_hovered = Color( 160, 0, 0, 255 )
local col_red_bail = Color( 225, 0, 0, 255 )

local icon_name = Material( "craphead_scripts/adv_arresting/name_icon.png" )
local icon_job = Material( "craphead_scripts/adv_arresting/job_icon.png" )
local icon_wallet = Material( "craphead_scripts/adv_arresting/wallet_icon.png" )

net.Receive( "CH_AdvArrest_JailMenu", function( len, ply )
	-- Menú de arresto desactivado, ahora se arrastra al jugador.
end )

net.Receive( "CH_AdvArrest_BailMenu", function( len, ply )
	local bail = net.ReadDouble()
	local arrester = net.ReadEntity()

	local GUI_Bail_Frame = vgui.Create( "DFrame" )
	GUI_Bail_Frame:SetTitle( "" )
	GUI_Bail_Frame:SetSize( ScrW() * 0.16, ScrH() * 0.1425 )
	GUI_Bail_Frame:Center()
	GUI_Bail_Frame.Paint = function( self, w, h )
		-- Draw frame
		draw.RoundedBox( 8, 0, 0, w, h, col_gray_light )
		-- Draw top
		draw.RoundedBoxEx( 8, 0, 0, w, ScrH() * 0.03, col_gray_dark, true, true, false, false )

		-- Draw the top title.
		draw.SimpleText( CH_ADVArrest.Config.Lang["Bail Options"][CH_ADVArrest.Config.Language], "ADVARREST_Font_JailMenu", w / 2, ScrH() * 0.015, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		-- Draw text
		draw.SimpleText( CH_ADVArrest.Config.Lang["You have been arrested!"][CH_ADVArrest.Config.Language], "ADVARREST_Font_JailMenu", w / 2, ScrH() * 0.05, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		-- Draw text
		draw.SimpleText( CH_ADVArrest.Config.Lang["Bail Price:"][CH_ADVArrest.Config.Language] .." ".. DarkRP.formatMoney( bail ), "ADVARREST_Font_JailMenu", w / 2, ScrH() * 0.075, col_red_bail, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	GUI_Bail_Frame:MakePopup()
	GUI_Bail_Frame:SetDraggable( false )
	GUI_Bail_Frame:ShowCloseButton( false )

	local GUI_PayBail = vgui.Create( "DButton", GUI_Bail_Frame )	
	GUI_PayBail:SetPos( ScrW() * 0.007, ScrH() * 0.095 )
	GUI_PayBail:SetSize( ScrW() * 0.07, ScrH() * 0.035 )
	GUI_PayBail:SetText( "" )
	GUI_PayBail.Paint = function( self, w, h )
		if self:IsHovered() then
			draw.RoundedBox( 8, 0, 0, w, h, col_green_hovered )
		else
			draw.RoundedBox( 8, 0, 0, w, h, col_green )
		end

		draw.SimpleText( CH_ADVArrest.Config.Lang["Pay Bail"][CH_ADVArrest.Config.Language], "ADVARREST_Font_JailMenu", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	GUI_PayBail.DoClick = function()
		net.Start( "CH_ADVARREST_PayBail" )
			net.WriteEntity( arrester )
		net.SendToServer()
		
		GUI_Bail_Frame:Remove()
	end

	local GUI_DeclineBail = vgui.Create( "DButton", GUI_Bail_Frame )	
	GUI_DeclineBail:SetPos( ScrW() * 0.084, ScrH() * 0.095 )
	GUI_DeclineBail:SetSize( ScrW() * 0.07, ScrH() * 0.035 )
	GUI_DeclineBail:SetText( "" )
	GUI_DeclineBail.Paint = function( self, w, h )
		if self:IsHovered() then
			draw.RoundedBox( 8, 0, 0, w, h, col_red_hovered )
		else
			draw.RoundedBox( 8, 0, 0, w, h, col_red )
		end

		draw.SimpleText( CH_ADVArrest.Config.Lang["Decline Bail"][CH_ADVArrest.Config.Language], "ADVARREST_Font_JailMenu", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	GUI_DeclineBail.DoClick = function()
		GUI_Bail_Frame:Remove()
	end
end )

net.Receive( "CH_AdvArrest_InspectPlayersMenu", function( len, ply )
	if not LocalPlayer():CH_ADVARREST_IsAuthorizedToArrest() then
		return
	end
	
	local target = net.ReadEntity()
	
	local targetInvCount = net.ReadUInt(16)
	local targetInv = {}
	for i = 1, targetInvCount do
		table.insert(targetInv, {
			index = i,
			class = net.ReadString(),
			name = net.ReadString(),
			model = net.ReadString(),
			amount = net.ReadUInt(16)
		})
	end
	
	local GUI_InspectPlayer_Frame = vgui.Create( "DFrame" )
	GUI_InspectPlayer_Frame:SetTitle( "" )
	GUI_InspectPlayer_Frame:SetSize( ScrW() * 0.2, ScrH() * 0.457 )
	GUI_InspectPlayer_Frame:Center()
	GUI_InspectPlayer_Frame.CurrentBail = 0
	GUI_InspectPlayer_Frame.Paint = function( self, w, h )
		-- Draw frame
		draw.RoundedBox( 8, 0, 0, w, h, col_gray_light )
		-- Draw top
		draw.RoundedBoxEx( 8, 0, 0, w, ScrH() * 0.03, col_gray_dark, true, true, false, false )

		-- Draw the top title.
		draw.SimpleText( CH_ADVArrest.Config.Lang["Inspecting Player"][CH_ADVArrest.Config.Language], "ADVARREST_Font_JailMenu", w / 2, ScrH() * 0.015, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		-- Player name
		draw.RoundedBox( 8, ScrW() * 0.007, ScrH() * 0.042, ScrW() * 0.187, ScrH() * 0.035, col_gray_lighter )
		
		surface.SetMaterial( icon_name )
		surface.SetDrawColor( color_white )
		surface.DrawTexturedRect( ScrW() * 0.011, ScrH() * 0.0448, 32, 32 )
		
		draw.SimpleText( CH_ADVArrest.Config.Lang["Name"][CH_ADVArrest.Config.Language], "ADVARREST_Font_JailMenu", ScrW() * 0.032, ScrH() * 0.049, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT )
		draw.SimpleText( target:Nick(), "ADVARREST_Font_JailMenu", ScrW() * 0.19, ScrH() * 0.049, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT )
		
		-- Player job
		draw.RoundedBox( 8, ScrW() * 0.007, ScrH() * 0.09, ScrW() * 0.187, ScrH() * 0.035, col_gray_lighter )
		
		surface.SetMaterial( icon_job )
		surface.SetDrawColor( color_white )
		surface.DrawTexturedRect( ScrW() * 0.011, ScrH() * 0.0935, 32, 32 )
		
		draw.SimpleText( CH_ADVArrest.Config.Lang["Job"][CH_ADVArrest.Config.Language], "ADVARREST_Font_JailMenu", ScrW() * 0.032, ScrH() * 0.097, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT )
		draw.SimpleText( team.GetName( target:Team() ), "ADVARREST_Font_JailMenu", ScrW() * 0.19, ScrH() * 0.097, team.GetColor( target:Team() ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT )
		
		-- Player wallet
		draw.RoundedBox( 8, ScrW() * 0.007, ScrH() * 0.138, ScrW() * 0.187, ScrH() * 0.035, col_gray_lighter )
		
		surface.SetMaterial( icon_wallet )
		surface.SetDrawColor( color_white )
		surface.DrawTexturedRect( ScrW() * 0.011, ScrH() * 0.1415, 32, 32 )
		
		draw.SimpleText( CH_ADVArrest.Config.Lang["Wallet"][CH_ADVArrest.Config.Language], "ADVARREST_Font_JailMenu", ScrW() * 0.032, ScrH() * 0.146, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT )
		draw.SimpleText( DarkRP.formatMoney( target:getDarkRPVar("money") ), "ADVARREST_Font_JailMenu", ScrW() * 0.19, ScrH() * 0.146, col_green_hovered, TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT )
	end
	GUI_InspectPlayer_Frame:MakePopup()
	GUI_InspectPlayer_Frame:SetDraggable( false )
	GUI_InspectPlayer_Frame:ShowCloseButton( false )
	
	local GUI_PlayerWepsPanel = vgui.Create( "DPanelList", GUI_InspectPlayer_Frame )
	GUI_PlayerWepsPanel:SetSize( ScrW() * 0.187, ScrH() * 0.215 )
	GUI_PlayerWepsPanel:SetPos( ScrW() * 0.007, ScrH() * 0.183 )
	GUI_PlayerWepsPanel:EnableVerticalScrollbar( true )
	GUI_PlayerWepsPanel:EnableHorizontal( true )
	GUI_PlayerWepsPanel.Paint = function( self, w, h )
		draw.RoundedBox( 8, 0, 2, w, h, col_gray_lighter )
	end
	if ( GUI_PlayerWepsPanel.VBar ) then
		GUI_PlayerWepsPanel.VBar.Paint = function( self, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, color_transparent ) -- BG
		end
		
		GUI_PlayerWepsPanel.VBar.btnUp.Paint = function( self, w, h )
			draw.RoundedBox( 4, 0, 2, w, h, color_transparent )
		end
		
		GUI_PlayerWepsPanel.VBar.btnGrip.Paint = function( self, w, h )
			draw.RoundedBoxEx( 16, 0, 0, w - 5, h, col_gray_dark, true, true, true, true )
		end
		
		GUI_PlayerWepsPanel.VBar.btnDown.Paint = function( self, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, color_transparent )
		end
	end
	
	for k, v in pairs( target:GetWeapons() ) do
		if v then
			local wep_class = v:GetClass()
			
			if GAMEMODE.Config.weaponCheckerHideDefault and table.HasValue( GAMEMODE.Config.DefaultWeapons, wep_class ) then
				continue
            end
			
			if table.HasValue( GAMEMODE.Config.AdminWeapons, wep_class ) then
				continue
            end
			
			if target:getJobTable() and target:getJobTable().weapons then
				if table.HasValue( target:getJobTable().weapons, wep_class ) then
					continue
				end
			end

			if CH_ADVArrest.Config.InspectBlacklistWeapons[ wep_class ] then
				continue
            end
			
			local wep_name = v.PrintName or wep_class
			
			local GUI_WeaponPanel = vgui.Create( "DPanelList" )
			GUI_WeaponPanel:SetSize( ScrW() * 0.2, ScrH() * 0.07 )
			GUI_WeaponPanel:SetPos( ScrW() * 0.01, ScrH() * 0.2 )
			GUI_WeaponPanel.Paint = function( self, w, h )
				-- Outer
				draw.RoundedBox( 8, ScrW() * 0.005, ScrH() * 0.012, ScrW() * 0.1725, ScrH() * 0.0575, col_gray_dark )
				
				-- Weapon Name
				draw.SimpleText( wep_name, "ADVARREST_Font_JailMenu", ScrW() * 0.055, ScrH() * 0.03, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT )
			end
			
			local valid_model = util.IsValidModel( v:GetModel() )
			
			if valid_model then
				local GUI_WepIcon = vgui.Create( "DModelPanel", GUI_WeaponPanel )
				GUI_WepIcon:SetPos( 0, ScrH() * 0.002 )
				GUI_WepIcon:SetSize( ScrW() * 0.06, ScrH() * 0.09 )
				GUI_WepIcon:SetModel( v:GetModel() )
				GUI_WepIcon:GetEntity():SetAngles( Angle( -10, 0, 15 ) )
				local mn, mx = GUI_WepIcon.Entity:GetRenderBounds()
				local size = 0
				size = math.max( size, math.abs( mn.x ) + math.abs( mx.x ) )
				size = math.max( size, math.abs( mn.y ) + math.abs( mx.y ) )
				size = math.max( size, math.abs( mn.z ) + math.abs( mx.z ) )
				GUI_WepIcon:SetFOV( 45 )
				GUI_WepIcon:SetCamPos( Vector( size, size, size ) )
				GUI_WepIcon:SetLookAt( (mn + mx) * 0.5 )
				function GUI_WepIcon:LayoutEntity( Entity ) return end
				-- 76561198379569886
			end
			
			-- Confiscate weapon button
			local GUI_ConfiscateButton = vgui.Create( "DButton", GUI_WeaponPanel )
			GUI_ConfiscateButton:SetPos( ScrW() * 0.12, ScrH() * 0.019 )
			GUI_ConfiscateButton:SetSize( ScrW() * 0.055, ScrH() * 0.045 )
			GUI_ConfiscateButton:SetTextColor( Color( 0, 0, 0, 255 ) )
			GUI_ConfiscateButton:SetText( "" )
			GUI_ConfiscateButton.Paint = function( self, w, h )
				if self:IsHovered() then
					draw.RoundedBox( 8, 0, 0, w, h, col_red_hovered )
				else
					draw.RoundedBox( 8, 0, 0, w, h, col_red )
				end

				draw.SimpleText( CH_ADVArrest.Config.Lang["Confiscate"][CH_ADVArrest.Config.Language], "ADVARREST_Font_JailMenu", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end
			GUI_ConfiscateButton.DoClick = function()
				GUI_WeaponPanel:Remove()
				
				net.Start( "CH_ADVARREST_ConfiscateIllegalWeapon" )
					net.WriteEntity( target )
					net.WriteEntity( v )
				net.SendToServer()
			end
			
			GUI_PlayerWepsPanel:AddItem( GUI_WeaponPanel )
		end
	end
	
	-- Draw Inventory Items
	for k, v in ipairs( targetInv ) do
		local wep_name = v.name
		
		local GUI_WeaponPanel = vgui.Create( "DPanelList" )
		GUI_WeaponPanel:SetSize( ScrW() * 0.2, ScrH() * 0.07 )
		GUI_WeaponPanel:SetPos( ScrW() * 0.01, ScrH() * 0.2 )
		GUI_WeaponPanel.Paint = function( self, w, h )
			-- Outer
			draw.RoundedBox( 8, ScrW() * 0.005, ScrH() * 0.012, ScrW() * 0.1725, ScrH() * 0.0575, col_gray_dark )
			
			-- Weapon Name
			draw.SimpleText( wep_name .. " (x" .. tostring(v.amount) .. ")", "ADVARREST_Font_JailMenu", ScrW() * 0.055, ScrH() * 0.03, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT )
		end
		
		local valid_model = util.IsValidModel( v.model )
		
		if valid_model then
			local GUI_WepIcon = vgui.Create( "DModelPanel", GUI_WeaponPanel )
			GUI_WepIcon:SetPos( 0, ScrH() * 0.002 )
			GUI_WepIcon:SetSize( ScrW() * 0.06, ScrH() * 0.09 )
			GUI_WepIcon:SetModel( v.model )
			GUI_WepIcon:GetEntity():SetAngles( Angle( -10, 0, 15 ) )
			local mn, mx = GUI_WepIcon.Entity:GetRenderBounds()
			local size = 0
			size = math.max( size, math.abs( mn.x ) + math.abs( mx.x ) )
			size = math.max( size, math.abs( mn.y ) + math.abs( mx.y ) )
			size = math.max( size, math.abs( mn.z ) + math.abs( mx.z ) )
			GUI_WepIcon:SetFOV( 45 )
			GUI_WepIcon:SetCamPos( Vector( size, size, size ) )
			GUI_WepIcon:SetLookAt( (mn + mx) * 0.5 )
			function GUI_WepIcon:LayoutEntity( Entity ) return end
		end
		
		-- Confiscate weapon button
		local GUI_ConfiscateButton = vgui.Create( "DButton", GUI_WeaponPanel )
		GUI_ConfiscateButton:SetPos( ScrW() * 0.12, ScrH() * 0.019 )
		GUI_ConfiscateButton:SetSize( ScrW() * 0.055, ScrH() * 0.045 )
		GUI_ConfiscateButton:SetTextColor( Color( 0, 0, 0, 255 ) )
		GUI_ConfiscateButton:SetText( "" )
		GUI_ConfiscateButton.Paint = function( self, w, h )
			if self:IsHovered() then
				draw.RoundedBox( 8, 0, 0, w, h, col_red_hovered )
			else
				draw.RoundedBox( 8, 0, 0, w, h, col_red )
			end

			draw.SimpleText( CH_ADVArrest.Config.Lang["Confiscate"][CH_ADVArrest.Config.Language], "ADVARREST_Font_JailMenu", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
		GUI_ConfiscateButton.DoClick = function()
			GUI_WeaponPanel:Remove()
			
			net.Start( "CH_ADVARREST_ConfiscateInventoryItem" )
				net.WriteEntity( target )
				net.WriteInt( v.index, 16 )
			net.SendToServer()
		end
		
		GUI_PlayerWepsPanel:AddItem( GUI_WeaponPanel )
	end
	
	local GUI_CloseButton = vgui.Create( "DButton", GUI_InspectPlayer_Frame )
	GUI_CloseButton:SetPos( ScrW() * 0.007, ScrH() * 0.41 )
	GUI_CloseButton:SetSize( ScrW() * 0.187, ScrH() * 0.035 )
	GUI_CloseButton:SetTextColor( Color( 0, 0, 0, 255 ) )
	GUI_CloseButton:SetText( "" )
	GUI_CloseButton.Paint = function( self, w, h )
		if self:IsHovered() then
			draw.RoundedBox( 8, 0, 0, w, h, col_red_hovered )
		else
			draw.RoundedBox( 8, 0, 0, w, h, col_red )
		end

		draw.SimpleText( CH_ADVArrest.Config.Lang["Finish Inspection"][CH_ADVArrest.Config.Language], "ADVARREST_Font_JailMenu", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	GUI_CloseButton.DoClick = function()
		GUI_InspectPlayer_Frame:Remove()
	end
end )