AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

local map = string.lower( game.GetMap() )

function CH_ADVArrest.SpawnJailerNPC()	
	local PositionFile = file.Read( "craphead_scripts/ch_adv_arresting/".. map .."/jailernpc_location.txt", "DATA" )

	local ThePosition = string.Explode( ";", PositionFile )

	local TheVector = Vector( ThePosition[1], ThePosition[2], ThePosition[3] )
	local TheAngle = Angle( tonumber(ThePosition[4]), ThePosition[5], ThePosition[6] )
	
	local JailerNPC = ents.Create( "ch_adv_arresting_jailer_npc" )
	JailerNPC:SetModel( CH_ADVArrest.Config.JailerNPCModel )
	JailerNPC:SetPos( TheVector )
	JailerNPC:SetAngles( TheAngle )
	JailerNPC:Spawn()
	JailerNPC:SetMoveType( MOVETYPE_NONE )
	JailerNPC:SetSolid( SOLID_BBOX )
	JailerNPC:SetCollisionGroup( COLLISION_GROUP_PLAYER )
	
	CH_ADVArrest.JailerNPCEntity = JailerNPC
end

function ENT:Initialize()
	self:SetHullType( HULL_HUMAN )
	self:SetHullSizeNormal()
	self:SetNPCState( NPC_STATE_SCRIPT )
	self:SetSolid( SOLID_BBOX )
	self:CapabilitiesAdd( CAP_ANIMATEDFACE )
	self:CapabilitiesAdd( CAP_TURN_HEAD )
	self:DropToFloor()
	self:SetMaxYawSpeed( 90 )
	self:SetCollisionGroup( 1 )
end

function ENT:OnTakeDamage( dmg )
	return 0
end

local function CH_ADVARREST_SetJailerNPCPos( ply )
	if not ply:IsAdmin() then
		ply:ChatPrint( CH_ADVArrest.Config.Lang["Only administrators can perform this action!"][CH_ADVArrest.Config.Language] )
		return
	end
	
	local HisVector = string.Explode(" ", tostring(ply:GetPos()))
	local HisAngles = string.Explode(" ", tostring(ply:GetAngles()))
	
	file.Write( "craphead_scripts/ch_adv_arresting/".. map .."/jailernpc_location.txt", ""..(HisVector[1])..";"..(HisVector[2])..";"..(HisVector[3])..";"..(HisAngles[1])..";"..(HisAngles[2])..";"..(HisAngles[3]).."", "DATA" )
	ply:ChatPrint( CH_ADVArrest.Config.Lang["New position for the jailer NPC has been succesfully set."][CH_ADVArrest.Config.Language] )
	ply:ChatPrint( CH_ADVArrest.Config.Lang["The NPC will respawn in 5 seconds. Move out the way."][CH_ADVArrest.Config.Language] )
	
	-- Respawn the jailer npc
	local npc = CH_ADVArrest.JailerNPCEntity
	if IsValid( npc ) then
		npc:Remove()
	end
	
	timer.Simple( 5, function()
		if IsValid( ply ) then
			CH_ADVArrest.SpawnJailerNPC()
			ply:ChatPrint( CH_ADVArrest.Config.Lang["The jailer NPC has been respawned."][CH_ADVArrest.Config.Language] )
		end
	end )
end
concommand.Add( "ch_adv_arrest_jailer_pos", CH_ADVARREST_SetJailerNPCPos )

function ENT:AcceptInput( ply, arrester )
	local cur_time = CurTime()
	
	if arrester:IsPlayer() and ( self.LastUsed or 0 ) <= cur_time then
		self.LastUsed = cur_time + 1
		
		if not arrester:CH_ADVARREST_IsAuthorizedToArrest() then
			self:EmitSound( "npc/metropolice/vo/finalwarning.wav" )
			return 
		end
		
		if self:HandcuffedPlayerNearby() then
			DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["You are about to arrest"][CH_ADVArrest.Config.Language] .." ".. self:HandcuffedPlayerNearby():Nick() )
			
			if not arrester.CH_ADVArrest_MenuOpen then
				arrester.CH_ADVArrest_MenuOpen = true
				
				net.Start( "CH_AdvArrest_JailMenu" )
					net.WriteEntity( self:HandcuffedPlayerNearby() )
				net.Send( arrester )
			end
		else
			DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["There is no handcuffed player nearby. Please bring them closer to the NPC."][CH_ADVArrest.Config.Language] )
		end
	end
end

function ENT:HandcuffedPlayerNearby()
	local ply_nearby = nil
	
	for k, ply in ipairs( player.GetAll() ) do
		if self:GetPos():DistToSqr( ply:GetPos() ) < CH_ADVArrest.Config.ArrestDistance then
			if ply:GetNWBool( "CH_ADVARREST_Handcuffed" ) then
				ply_nearby = ply
				
				return ply_nearby
			end
		end
	end
end