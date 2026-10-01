AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

ENT.SpawnNormalOffset = 25

function ENT:OnSpawn( PObj )
	PObj:SetMass( 5000 )

	local DriverSeat = self:AddDriverSeat( Vector(469.85,-1.54,104.31), Angle(0,-90.68,-0.01) )
	DriverSeat:SetCameraDistance( 1.9 )
	DriverSeat.HidePlayer = true

	local Pod = self:AddPassengerSeat( Vector(373.66,154.18,92.04), Angle(-0.17,-35.78,1.17) )
	self:SetGunnerSeat( Pod )
	Pod.HidePlayer = true
	Pod.ExitPos = Vector(65.87,154.32,24.09)	
	
	local Pod = 	self:AddPassengerSeat( Vector(375.53,-161.86,91.72), Angle(-0.19,-145.52,1.17) )
	self:SetThirdGunnerSeat( Pod )
	Pod.HidePlayer = true
	Pod.ExitPos = Vector(65.87,-154.32,24.09)	
	
	local Pod = 	self:AddPassengerSeat( Vector(302.69,-4.34,132.71), Angle(0,-90.68,-0.01) )
	Pod.ExitPos = Vector(-63.93,131.42,24.09)	
	
	local Pod = 	self:AddPassengerSeat( Vector(302.69,-4.34,132.71), Angle(0,-90.68,-0.01) )
	Pod.ExitPos = Vector(-56.94,68.49,24.09)	

	local Pod = 	self:AddPassengerSeat( Vector(302.69,-4.34,132.71), Angle(0,-90.68,-0.01) )
	Pod.ExitPos = Vector(-46.9,3.52,24.09)	
	
	local Pod = 	self:AddPassengerSeat( Vector(302.69,-4.34,132.71), Angle(0,-90.68,-0.01) )
	Pod.ExitPos = Vector(-44.76,-50.96,24.09)	
	
	local Pod = 	self:AddPassengerSeat( Vector(302.69,-4.34,132.71), Angle(0,-90.68,-0.01) )
	Pod.ExitPos = Vector(-87.5,-44.87,24.09)	
	
	local Pod = 	self:AddPassengerSeat( Vector(302.69,-4.34,132.71), Angle(0,-90.68,-0.01) )
	Pod.ExitPos = Vector(-80.75,2.85,24.09)	
	
	local Pod = 	self:AddPassengerSeat( Vector(302.69,-4.34,132.71), Angle(0,-90.68,-0.01) )
	Pod.ExitPos = Vector(-81.6,62.83,24.09)	
	
	local Pod = 	self:AddPassengerSeat( Vector(302.69,-4.34,132.71), Angle(0,-90.68,-0.01) )
	Pod.ExitPos = Vector(-87.45,125.53,24.09)	
	
	local Pod = 	self:AddPassengerSeat( Vector(302.69,-4.34,132.71), Angle(0,-90.68,-0.01) )
	Pod.ExitPos = Vector(-150.25,121.67,24.09)	
	
	local Pod = 	self:AddPassengerSeat( Vector(302.69,-4.34,132.71), Angle(0,-90.68,-0.01) )
	Pod.ExitPos = Vector(-151.63,75.94,24.09)	
	
	local Pod = 	self:AddPassengerSeat( Vector(302.69,-4.34,132.71), Angle(0,-90.68,-0.01) )
	Pod.ExitPos = Vector(-152.28,-66.86,24.09)	
	
	local Pod = 	self:AddPassengerSeat( Vector(302.69,-4.34,132.71), Angle(0,-90.68,-0.01) )
	Pod.ExitPos = Vector(-148.51,-3.5,24.09)	
	
	local Pod = 	self:AddPassengerSeat( Vector(302.69,-4.34,132.71), Angle(0,-90.68,-0.01) )
	Pod.ExitPos = Vector(-146.84,-136.46,24.09)	
	
	
	self:AddEngine( Vector(201.22,-216.44,216.04) )
	self:AddEngine( Vector(201.22,216.44,216.04) )
	self:AddEngine( Vector(-245.76,0.24,300.5) )
	self:AddEngineSound( Vector(26.65,0.88,293.12), 150 )

	self.PrimarySND = self:AddSoundEmitter( Vector(118.24,0,49.96), "hmp/WPN_B2_BTLDROID_MULTI_LASER_SHOOT_01.mp3", "hmp/WPN_B2_BTLDROID_MULTI_LASER_SHOOT_01.mp3" )
	self.PrimarySND:SetSoundLevel( 110 )
	
	self.SNDTail = self:AddSoundEmitter( Vector(200,0,150), "hmp/WPN_B2_BTLDROID_MULTI_LASER_SHOOT_01.mp3", "hmp/WPN_B2_BTLDROID_MULTI_LASER_SHOOT_01.mp3" )
	self.SNDTail:SetSoundLevel( 110 )
end
