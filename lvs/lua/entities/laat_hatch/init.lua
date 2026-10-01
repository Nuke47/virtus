AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/fisher/laat/hatch.mdl")
    self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_NONE)
end