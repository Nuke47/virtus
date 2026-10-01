function CH_ADVArrest.PlayerArrested( criminal, time, arrester )
	DarkRP.notify( criminal, 0, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["You've been arrested by"][CH_ADVArrest.Config.Language] .." " .. arrester:Nick() )
	
	if tonumber( criminal.CH_ADVArrest_Bail ) and tonumber( criminal.CH_ADVArrest_Bail ) > 0 then
		net.Start( "CH_AdvArrest_BailMenu" )
			net.WriteDouble( criminal.CH_ADVArrest_Bail )
			net.WriteEntity( arrester )
		net.Send( criminal )
	end
	
	if CH_ADVArrest.Config.ChangeJobOnArrested then
		criminal.CH_ADVARREST_PreviousTeam = criminal:Team()

		criminal:changeTeam( CH_ADVArrest.Config.JobChangeTo, true )
	end
end
hook.Add( "playerArrested", "CH_ADVArrest.PlayerArrested", CH_ADVArrest.PlayerArrested )

function CH_ADVArrest.SetHandcuffedBones(ply, bState)
    local l_upper = ply:LookupBone("ValveBiped.Bip01_L_UpperArm")
    local l_fore = ply:LookupBone("ValveBiped.Bip01_L_Forearm")
    local r_upper = ply:LookupBone("ValveBiped.Bip01_R_UpperArm")
    local r_fore = ply:LookupBone("ValveBiped.Bip01_R_Forearm")

    if not l_upper or not l_fore or not r_upper or not r_fore then return end

    if bState then
        ply:ManipulateBoneAngles(l_upper, Angle( 15, 10, 50 ))
        ply:ManipulateBoneAngles(l_fore, Angle( 15, -35, 0 ))
        ply:ManipulateBoneAngles(r_upper, Angle( -15, 10, -50 ))
        ply:ManipulateBoneAngles(r_fore, Angle( -15, -35, 0 ))
    else
        ply:ManipulateBoneAngles(l_upper, Angle(0, 0, 0))
        ply:ManipulateBoneAngles(l_fore, Angle(0, 0, 0))
        ply:ManipulateBoneAngles(r_upper, Angle(0, 0, 0))
        ply:ManipulateBoneAngles(r_fore, Angle(0, 0, 0))
    end
end

function CH_ADVArrest.PlayerUnArrested( criminal, unarrester )
	DarkRP.notify( criminal, 0, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["You have been released from jail!"][CH_ADVArrest.Config.Language] )
	criminal:SetNWBool( "CH_ADVARREST_Handcuffed", false )
	CH_ADVArrest.SetHandcuffedBones(criminal, false)
	
	criminal:SetWalkSpeed( GAMEMODE.Config.walkspeed )
	criminal:SetRunSpeed( GAMEMODE.Config.runspeed )
	
	if CH_ADVArrest.Config.ChangeJobOnArrested then
		if criminal.CH_ADVARREST_PreviousTeam then
			criminal:changeTeam( criminal.CH_ADVARREST_PreviousTeam, true )
		end
	end
end
hook.Add( "playerUnArrested", "CH_ADVArrest.PlayerUnArrested", CH_ADVArrest.PlayerUnArrested )

function CH_ADVArrest.PlayerDeath( ply )
	ply:SetNWBool( "CH_ADVARREST_Handcuffed", false )
	CH_ADVArrest.SetHandcuffedBones(ply, false)
	ply:SetWalkSpeed( GAMEMODE.Config.walkspeed )
	ply:SetRunSpeed( GAMEMODE.Config.runspeed )
end
hook.Add( "PlayerDeath", "CH_ADVArrest.PlayerDeath", CH_ADVArrest.PlayerDeath )

function CH_ADVArrest.CanSwitchWeapon( ply, oldwep, newwep )
	if ply:GetNWBool( "CH_ADVARREST_Handcuffed" ) then
		return true
	end
end
hook.Add( "PlayerSwitchWeapon", "CH_ADVArrest.CanSwitchWeapon", CH_ADVArrest.CanSwitchWeapon )

local function CH_ADVArrest_StopDropWeapons( ply, wep )
	if wep:GetClass() == "adv_arresting_baton" or wep:GetClass() == "adv_arresting_handcuffs" then
		return false
	end
end
hook.Add( "canDropWeapon", "CH_ADVArrest_StopDropWeapons", CH_ADVArrest_StopDropWeapons )