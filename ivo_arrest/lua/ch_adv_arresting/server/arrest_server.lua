net.Receive( "CH_ADVARREST_JailPlayer", function( lenght, ply )
	local target = net.ReadEntity()
	local arrest_time = net.ReadUInt( 10 )
	local bail = net.ReadUInt( 32 )
	local arrester = ply

	local canArrest, message = hook.Call( "canArrest", DarkRP.hooks, arrester, target )
	if not canArrest then
		if message then DarkRP.notify( arrester, 1, 5, message ) end
		return
	end
	
	if not arrester:CH_ADVARREST_IsAuthorizedToArrest() then
		return 
	end
	
	if arrester:GetPos():DistToSqr( target:GetPos() ) > CH_ADVArrest.Config.ArrestDistance then
		DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["The player is not close enough."][CH_ADVArrest.Config.Language] )
		return 
	end
	
	arrest_time = math.Clamp( math.Round( arrest_time ), CH_ADVArrest.Config.MinTime, CH_ADVArrest.Config.MaxTime )
	target.CH_ADVArrest_Bail = math.Clamp( math.Round( bail ), CH_ADVArrest.Config.MinBail, CH_ADVArrest.Config.MaxBail )

	if not target:GetNWBool( "CH_ADVARREST_Handcuffed" ) then
		target:SetNWBool( "CH_ADVARREST_Handcuffed", true )
		
		target:SetWalkSpeed( CH_ADVArrest.Config.ArrestedWalkSpeed )
		target:SetRunSpeed( CH_ADVArrest.Config.ArrestedRunSpeed )
	end

	target:arrest( arrest_time, arrester )
end )

net.Receive( "CH_ADVARREST_HandcuffPlayer", function()
	local arrester = net.ReadEntity()
	local target = net.ReadEntity()
	
	local canArrest, message = hook.Call( "canArrest", DarkRP.hooks, arrester, target )
	if not canArrest then
		if message then DarkRP.notify( arrester, 1, 5, message ) end
		return
	end
	
	if arrester:GetPos():DistToSqr( target:GetPos() ) > CH_ADVArrest.Config.ArrestDistance then
		DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["The player is not close enough."][CH_ADVArrest.Config.Language] )
		return 
	end
	
	if not arrester:CH_ADVARREST_IsAuthorizedToArrest() then 
		return 
	end

	DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["You've handcuffed"][CH_ADVArrest.Config.Language] .." ".. target:Nick()..".")
	
	target:SelectWeapon( CH_ADVArrest.Config.WeaponSwitchedHandcuffed ) 
	target:SetNWBool( "CH_ADVARREST_Handcuffed", true )
	CH_ADVArrest.SetHandcuffedBones(target, true)
	target:SetWalkSpeed( CH_ADVArrest.Config.ArrestedWalkSpeed )
	target:SetRunSpeed( CH_ADVArrest.Config.ArrestedRunSpeed )
end )

net.Receive( "CH_ADVARREST_PayBail", function( lenght, ply )
	local target = ply
	local arrester = net.ReadEntity()
	
	local bail = tonumber( target.CH_ADVArrest_Bail )
	
	if not bail or bail <= 0 then
		return
	end
	
	-- Target is not arrested
	if not target:isArrested() then
		return
	end
	
	-- Can't afford bail
	if target:getDarkRPVar( "money" ) < bail then
		DarkRP.notify( target, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["You cannot afford to pay your bail! You must serve all of your time in jail."][CH_ADVArrest.Config.Language] )
		return
	end

	-- All good
	target:addMoney( bail * -1 )
	target:unArrest()
	
	-- Who do we give the money to?
	if CH_ADVArrest.Config.MoneyDistribution == 1 then -- Give them to the person fining.
		if IsValid( arrester ) then
			arrester:addMoney( bail )
			DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, target:Nick().." ".. CH_ADVArrest.Config.Lang["has paid their bail of"][CH_ADVArrest.Config.Language] .. " ".. DarkRP.formatMoney( bail ) ..". ".. CH_ADVArrest.Config.Lang["The money has been added to your wallet."][CH_ADVArrest.Config.Language] )
		end
	elseif CH_ADVArrest.Config.MoneyDistribution == 2 then -- Give them to the mayor, if there is one.
		for k, mayor in ipairs( player.GetAll() ) do
			if team.GetName( mayor:Team() ) == CH_ADVArrest.Config.MayorTeam then
				mayor:addMoney( bail )
				break
			end
		end
		
		if IsValid( arrester ) then
			DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, target:Nick().." ".. CH_ADVArrest.Config.Lang["has paid their bail of"][CH_ADVArrest.Config.Language] .. " ".. DarkRP.formatMoney( bail ) ..". ".. CH_ADVArrest.Config.Lang["The money has been added to the mayors wallet."][CH_ADVArrest.Config.Language] )
		end
	elseif CH_ADVArrest.Config.MoneyDistribution == 3 then -- Remove them.
		if IsValid( arrester ) then
			DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, target:Nick().." ".. CH_ADVArrest.Config.Lang["has paid their bail of"][CH_ADVArrest.Config.Language] .. " ".. DarkRP.formatMoney( bail ) ..". ".. CH_ADVArrest.Config.Lang["The money has been destroyed."][CH_ADVArrest.Config.Language] )
		end
	end

	target.CH_ADVArrest_Bail = nil
end )

net.Receive( "CH_ADVARREST_ConfiscateIllegalWeapon", function( lenght, ply )
	local target = net.ReadEntity()
	local wep = net.ReadEntity()
	
	local wep_class = wep:GetClass()
	local wep_name = wep.PrintName or wep_class

	if not wep_class then
		return
	end
	
	if GAMEMODE.Config.weaponCheckerHideDefault and table.HasValue( GAMEMODE.Config.DefaultWeapons, wep_class ) then
		return
	end
	
	if table.HasValue( GAMEMODE.Config.AdminWeapons, wep_class ) then
		return
	end

	if target:getJobTable() and target:getJobTable().weapons then
		if table.HasValue( target:getJobTable().weapons, wep_class ) then
			return
		end
	end
	
	if CH_ADVArrest.Config.InspectBlacklistWeapons[ wep_class ] then
		return
	end
	
	if not ply:CH_ADVARREST_IsAuthorizedToArrest() then 
		return 
	end
	
	if ply:GetPos():DistToSqr( target:GetPos() ) > CH_ADVArrest.Config.ArrestDistance then
		DarkRP.notify( ply, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["The player is not close enough."][CH_ADVArrest.Config.Language] )
		return 
	end
	
	-- Everything checks out, passed all security
	target:StripWeapon( wep_class )
	DarkRP.notify( target, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["The inspecting police officer has confiscated your"][CH_ADVArrest.Config.Language] .." ".. wep_name )
end )

net.Receive( "CH_ADVARREST_CloseJailMenu", function( length, ply )
	ply.CH_ADVArrest_MenuOpen = false
end )



hook.Add("PlayerDeath", "CH_ADVArrest_DragDeath", function(ply)
	if IsValid(ply.CH_ADVArrest_Dragging) then
		ply.CH_ADVArrest_Dragging:SetNWEntity("CH_ADVARREST_DraggedBy", NULL)
		ply.CH_ADVArrest_Dragging = nil
	end
	local dragger = ply:GetNWEntity("CH_ADVARREST_DraggedBy")
	if IsValid(dragger) then
		dragger.CH_ADVArrest_Dragging = nil
		ply:SetNWEntity("CH_ADVARREST_DraggedBy", NULL)
	end
end)

hook.Add("PlayerSwitchWeapon", "CH_ADVArrest_DragSwitch", function(ply, oldwep, newwep)
    if IsValid(ply.CH_ADVArrest_Dragging) then
        ply.CH_ADVArrest_Dragging:SetNWEntity("CH_ADVARREST_DraggedBy", NULL)
        ply.CH_ADVArrest_Dragging = nil
        DarkRP.notify(ply, 1, 3, "Has dejado de arrastrar al jugador por cambiar de arma.")
    end
end)