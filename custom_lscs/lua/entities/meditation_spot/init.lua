AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	-- Set a generic placeholder model (like a circular rug or a stone)
	self:SetModel("models/hunter/tubes/tube2x2x025.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
	end
	
	-- Optional aesthetic: set a dark or distinct color for the spot
	self:SetColor(Color(50, 50, 50, 255))
end

function ENT:Use(activator, caller)
	if IsValid(activator) and activator:IsPlayer() then
		-- Fire a hook so our main logic can handle entering meditation
		hook.Run("Meditation_Enter", activator, self)
	end
end
