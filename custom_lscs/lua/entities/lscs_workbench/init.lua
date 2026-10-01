AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/props_c17/FurnitureTable001a.mdl") -- Placeholder model
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end
end

util.AddNetworkString("lscs_open_workbench_ui")

function ENT:Use(activator, caller)
	if IsValid(activator) and activator:IsPlayer() then
		net.Start("lscs_open_workbench_ui")
		net.Send(activator)
	end
end
