AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Muñeco de Pruebas (RCP)"
ENT.Author = "Gemini Mods"
ENT.Category = "Médico RP"
ENT.Spawnable = true
ENT.AdminSpawnable = true

if SERVER then
	function ENT:SpawnFunction(ply, tr, ClassName)
		if not tr.Hit then return end

		local ent = ents.Create("prop_ragdoll")
		ent:SetModel("models/aussiwozzi/cgi/base/unassigned_trp.mdl")
		ent:SetPos(tr.HitPos + tr.HitNormal * 16)
		ent:SetAngles(angle_zero)
		ent:Spawn()
		ent:Activate()

		-- MARCA DE RED: Le dice a todos los jugadores que este trapo es un muñeco de entrenamiento
		ent:SetNWBool("IsTestDummy", true)

		return ent
	end
end