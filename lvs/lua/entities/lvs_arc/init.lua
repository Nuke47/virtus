--DO NOT EDIT OR REUPLOAD THIS FILE

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName )

	if not tr.Hit then return end

	local ent = ents.Create( ClassName )
	ent.dOwnerEntLFS = ply
	ent:SetPos( tr.HitPos + tr.HitNormal * 120 )
	ent:Spawn()
	ent:Activate()

	return ent

end

--thanks to the guy who made this line of code down here, really saved a lot of time.
local AnimateOnce = true
local HasAnimated = false;
function ENT:OnTick()
local Driver = self:GetDriver()
	if not IsValid( Driver ) then return end
local trH = util.TraceLine( {
		start = self:LocalToWorld( Vector(0,0,50) ),
		endpos = self:LocalToWorld( Vector(0,0,-150) ),
		filter = self
	} )
		
	if trH.HitWorld == false or (self:GetVelocity():Length()) > 500 then
		if self.AnimateOnce == false or self.AnimateOnce == nil then
			self:PlayAnimation("f")
			self:EmitSound("vehicles/tank_readyfire1.wav")
			self.AnimateOnce = true
		end
	else
		if self.AnimateOnce == true and (self:GetVelocity():Length()) <= 500 then
			self:PlayAnimation("b")
			self:EmitSound("vehicles/tank_readyfire1.wav")
			self.AnimateOnce = false
		end
	end
end


function ENT:OnSpawn( PObj )
	PObj:SetMass( 1000 )

	self:AddDriverSeat( Vector(45,0,5), Angle(0,-90,0) )

	self:AddPassengerSeat( Vector(-30,0,18), Angle(0,-90,0) )

	local Pod = self:AddPassengerSeat( Vector(-107,0,18), Angle(0,90,0) ) -- TOP POD
	self:SetTailGunnerSeat( Pod )

	self:AddEngine( Vector(-95,65,7) )
	self:AddEngine( Vector(-95,-65,7) )
	self:AddEngineSound( Vector(0,0,10) )

	self.SNDLeft = self:AddSoundEmitter( Vector(207.65,303.52,-48.35), "lvs/vehicles/arc170/fire.mp3", "lvs/vehicles/arc170/fire.mp3" )
	self.SNDLeft:SetSoundLevel( 110 )

	self.SNDRight = self:AddSoundEmitter( Vector(207.65,-303.52,-48.35), "lvs/vehicles/arc170/fire.mp3", "lvs/vehicles/arc170/fire.mp3" )
	self.SNDRight:SetSoundLevel( 110 )

	self.SNDTail = self:AddSoundEmitter( Vector(-900.65,-303.52,-48.35), "lvs/vehicles/arc170/fire_gunner.mp3", "lvs/vehicles/arc170/fire_gunner.mp3" )
	self.SNDTail:SetSoundLevel( 110 )

	self:SetMaxThrottle( 1.2 )
end

function ENT:OnEngineActiveChanged( Active )
	if Active then
		self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/start.wav" )
	else
		self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/stop.wav" )
		self:SetFoils( false )
	end
end

--function ENT:OnTick()
--	if self:ForceDisableFoils() then
--		if self:GetThrottle() < 0.1 then
--			self:DisableVehicleSpecific()
--		end
--	end
--end

function ENT:OnVehicleSpecificToggled( new )
	local cur = self:GetFoils()

	if not cur and self:ForceDisableFoils() then return end

	if cur ~= new then
		self:SetFoils( new )
	end
end

function ENT:OnFoilsChanged( name, old, new)
	if new == old then return end

	if new == true then
		self:SetMaxThrottle( 1 )
	else
		self:SetMaxThrottle( 1.2 )
	end
end

function ENT:ForceDisableFoils()
	local trace = util.TraceLine( {
		start = self:LocalToWorld( Vector(0,0,50) ),
		endpos = self:LocalToWorld( Vector(0,0,-150) ),
		filter = self:GetCrosshairFilterEnts()
	} )
	
	return trace.Hit
end

function ENT:CreateAI()
	self:SetBodygroup ( 1, 1 )
	self:PlayAnimation("f")
end

function ENT:RemoveAI()
	self:SetBodygroup( 1, 0 ) 
end



















