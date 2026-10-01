AddCSLuaFile()

ENT.Base = "lvs_walker_atte_component"

if SERVER then
	function ENT:Initialize()	
		self:SetModel( "models/kingpommes/starwars/atte/lfs_rear.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:AddFlags( FL_OBJECT )
		self:SetSkin( 1 )
	end

	function ENT:Think()
		self:NextThink( CurTime() )
		return true
	end

	return
end

include("entities/lvs_mixy_atte/cl_ikfunctions.lua")

function ENT:OnRemove()
	self:OnRemoved()
end