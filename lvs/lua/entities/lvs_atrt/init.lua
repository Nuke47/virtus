AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_camera.lua" )
AddCSLuaFile( "cl_prediction.lua" )
include("shared.lua")
include("sv_ragdoll.lua")
include("sv_controls.lua")
include("sv_contraption.lua")

function ENT:OnSpawn( PObj )
	PObj:SetMass( 10000 )

	local SeatAttachment = self:GetAttachment( self:LookupAttachment( "driver" ) )

	local SeatPos = SeatAttachment.Pos
	local SeatAng = SeatAttachment.Ang

	SeatPos = self:WorldToLocal( SeatPos )
	SeatAng = self:WorldToLocalAngles( SeatAng )

	local DriverSeat = self:AddDriverSeat( SeatPos, SeatAng )
	DriverSeat:SetCameraDistance( 0.05 )

	self:PlayAnimation( "sitdown" )

	self.SNDPrimary = self:AddSoundEmitter( Vector(50,0,93), "kingpommes/starwars/hailfire/laser.wav", "kingpommes/starwars/hailfire/laser.wav" )
	self.SNDPrimary:SetSoundLevel( 110 )

	self.Turret = ents.Create("base_anim")
	self.Turret:SetModel("models/KingPommes/starwars/atrt/turret.mdl")
	self.Turret:SetPos(Vector())
	self.Turret:SetAngles(Angle())
	self.Turret:SetParent(self)
	self.Turret:Spawn()
	self.Turret:Activate()
	self.Turret:Fire("setparentattachment", "turret", 0)
end

function ENT:OnTick()
	self:ContraptionThink()
end

function ENT:OnMaintenance()
	self:UnRagdoll()
end

function ENT:AlignView( ply, SetZero )
	if not IsValid( ply ) then return end

	timer.Simple( 0, function()
		if not IsValid( ply ) or not IsValid( self ) then return end

		ply:SetEyeAngles( Angle(0,90,0) )
	end)
end
