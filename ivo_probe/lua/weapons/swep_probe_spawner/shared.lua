SWEP.PrintName = "Spawneador de Droide Sonda"
SWEP.Author = "Antigravity"
SWEP.Instructions = "Click izquierdo para spawnear el Droide Sonda."

SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Category = "Star Wars RP"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 3
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.UseHands = true

-- CONFIGURACIÓN DEL TRABAJO PERMITIDO
-- Cambia esto por el nombre del team de tu DarkRP. 
-- Si no usas un check de nombre, simplemente dale el arma al job en jobs.lua
SWEP.AllowedJobName = "SU: Especialista" 
SWEP.CheckJob = true -- Pon esto en false si solo quieres dársela al job y ya

function SWEP:Initialize()
	self:SetHoldType("pistol")
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 2)
	self:ShootEffects()

	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	-- Comprobación de Job (Solo Server y si CheckJob está activo)
	if SERVER and self.CheckJob then
		local teamName = team.GetName(owner:Team())
		if teamName ~= self.AllowedJobName then
			owner:ChatPrint("No tienes el trabajo correcto para usar este SWEP.")
			return
		end
	end

	if SERVER then
		local tr = owner:GetEyeTrace()
		if not tr.Hit then return end

		-- Limitar a 1 droide activo a la vez
		if IsValid(owner.ActiveProbeDroid) then
			owner:ChatPrint("Ya tienes un Droide Sonda activo.")
			return
		end

		local spawnPos = tr.HitPos + tr.HitNormal * 16

		local ent = ents.Create("ent_probe_droid")
		if not IsValid(ent) then return end

		ent:SetPos(spawnPos)
		ent:SetAngles(Angle(0, owner:EyeAngles().y, 0))
		ent:Spawn()
		ent:Activate()
		
		-- Solo registrar para limitar spawn, no asignar dueño (para que deba vincularla)
		owner.ActiveProbeDroid = ent
		
		owner:ChatPrint("Droide Sonda desplegado. Use su datapad para vincularlo.")
	end
end

function SWEP:SecondaryAttack()
end
