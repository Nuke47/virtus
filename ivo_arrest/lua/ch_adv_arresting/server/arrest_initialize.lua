-- Download workshop content
resource.AddWorkshop( "2206554385" )

-- Utilize net messages
util.AddNetworkString( "CH_AdvArrest_JailMenu" )
util.AddNetworkString( "CH_AdvArrest_BailMenu" )
util.AddNetworkString( "CH_AdvArrest_BailPlayersMenu" )
util.AddNetworkString( "CH_AdvArrest_InspectPlayersMenu" )

util.AddNetworkString( "CH_ADVARREST_JailPlayer" )
util.AddNetworkString( "CH_ADVARREST_HandcuffPlayer" )
util.AddNetworkString( "CH_ADVARREST_PayBail" )

util.AddNetworkString( "CH_ADVARREST_CloseJailMenu" )
util.AddNetworkString( "CH_ADVARREST_ConfiscateIllegalWeapon" )

util.AddNetworkString( "CH_ADVARREST_UpdateHandcuffState" )

local map = string.lower( game.GetMap() )

-- Initialize script
local function CH_ADVArrest_Initialize()
	timer.Simple( 2, function()
		-- Default file locations
		if not file.IsDir( "craphead_scripts", "DATA" ) then
			file.CreateDir( "craphead_scripts", "DATA" )
		end
		
		if not file.IsDir( "craphead_scripts/ch_adv_arresting/".. map .."", "DATA" ) then
			file.CreateDir( "craphead_scripts/ch_adv_arresting/".. map .."", "DATA" )
		end

		-- Jailer NPC
		if not file.Exists( "craphead_scripts/ch_adv_arresting/".. map .."/jailernpc_location.txt", "DATA" ) then
			file.Write( "craphead_scripts/ch_adv_arresting/".. map .."/jailernpc_location.txt", "0;-0;-0;0;0;0", "DATA" )
		end
		
		-- Spawn NPC if config is enabled
		if CH_ADVArrest.Config.EnableJailerNPC then
			CH_ADVArrest.SpawnJailerNPC()
		end
	end )
end
hook.Add( "InitPostEntity", "CH_ADVArrest_Initialize", CH_ADVArrest_Initialize )

-- Give new weapons and strip the old ones
function CH_ADVArrest.Overwrite_Weapons( ply, before, after )
	timer.Simple( 0.5, function()
		if not IsValid( ply ) then
			return
		end
		
		if CH_ADVArrest.Config.StripOldWeapons then
			if ply:HasWeapon( "arrest_stick" ) then
				ply:StripWeapon( "arrest_stick" )
			end
			if ply:HasWeapon( "unarrest_stick" ) then
				ply:StripWeapon( "unarrest_stick" )
			end
			if ply:HasWeapon( "stunstick" ) then
				ply:StripWeapon( "stunstick" )
			end
		end
		
		-- Check if they're team
		if CH_ADVArrest.Config.AllowedTeams[ team.GetName( ply:Team() ) ] then
			ply:Give( "adv_arresting_handcuffs" )
		end
		
		-- Check if usergroup if enabled
		if CH_ADVArrest.Config.GiveUsergroupsOnSpawn and ply:CH_ADVARREST_IsAllowedUsergroup() then
			ply:Give( "adv_arresting_handcuffs" )
		end
	end )
end
hook.Add( "OnPlayerChangedTeam", "CH_ADVArrest.Overwrite_Weapons", CH_ADVArrest.Overwrite_Weapons ) -- DarkRP Hook
hook.Add( "PlayerSpawn", "CH_ADVArrest.Overwrite_Weapons", CH_ADVArrest.Overwrite_Weapons )