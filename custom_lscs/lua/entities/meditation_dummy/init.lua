AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	
	-- No need to simulate physics on this
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end
end

-- This function configures the dummy to look exactly like the player
function ENT:SetPlayer(ply)
	if not IsValid(ply) then return end
	
	self:SetModel(ply:GetModel())
	self:SetSkin(ply:GetSkin() or 0)
	for i = 0, ply:GetNumBodyGroups() - 1 do
		self:SetBodygroup(i, ply:GetBodygroup(i))
	end
	
	-- Try to get the player's color if they are using one
	self:SetColor(ply:GetColor())
	local plyColor = ply:GetPlayerColor()
	if plyColor then
		self.GetPlayerColor = function() return plyColor end
	end
	
	-- Play the meditation animation
	-- "sit_zen" is common in some models. If missing, we could fallback to "sit"
	local seq = self:LookupSequence("sit_zen")
	if seq <= 0 then seq = self:LookupSequence("sit") end
	if seq > 0 then
		self:ResetSequence(seq)
		self:SetPlaybackRate(1)
		self:SetCycle(0)
	end
end

function ENT:Think()
	self:NextThink(CurTime())
	return true
end
