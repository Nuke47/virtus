properties.Add( "virtus_whitelist", {
	MenuLabel = "Gestión de Whitelist",
	Order = 999,
	MenuIcon = "icon16/shield.png",

	Filter = function( self, ent, ply )
		if not IsValid( ent ) or not ent:IsPlayer() then return false end
		if not (ply:IsAdmin() or ply:IsSuperAdmin()) then return false end
		return true
	end,

	Action = function( self, ent )
		-- No direct action, it's a menu
	end,

	MenuOpen = function( self, option, ent, tr )
		local submenu = option:AddSubMenu()

		if not DarkRP or not DarkRP.getCategories then return end
		local categories = DarkRP.getCategories().jobs
		
		for _, cat in ipairs(categories) do
			if not cat.members or #cat.members == 0 then continue end
			
			local catMenu, catOption = submenu:AddSubMenu( cat.name )
			catOption:SetIcon( "icon16/folder.png" )
			
			for _, job in ipairs(cat.members) do
				local jobMenu, jobOption = catMenu:AddSubMenu( job.name )
				jobOption:SetIcon( "icon16/user.png" )
				
				jobMenu:AddOption("Añadir a Whitelist", function()
					net.Start("VirtusWhitelist_AddPlayer")
					net.WriteString(ent:SteamID())
					net.WriteString(job.command)
					net.WriteString("whitelist")
					net.SendToServer()
				end):SetIcon("icon16/accept.png")

				jobMenu:AddOption("Añadir a Blacklist", function()
					net.Start("VirtusWhitelist_AddPlayer")
					net.WriteString(ent:SteamID())
					net.WriteString(job.command)
					net.WriteString("blacklist")
					net.SendToServer()
				end):SetIcon("icon16/cancel.png")

				jobMenu:AddOption("Remover de Listas", function()
					net.Start("VirtusWhitelist_RemovePlayer")
					net.WriteString(ent:SteamID())
					net.WriteString(job.command)
					net.WriteString("whitelist")
					net.SendToServer()

					net.Start("VirtusWhitelist_RemovePlayer")
					net.WriteString(ent:SteamID())
					net.WriteString(job.command)
					net.WriteString("blacklist")
					net.SendToServer()
				end):SetIcon("icon16/bin_empty.png")
			end
		end
	end
} )
