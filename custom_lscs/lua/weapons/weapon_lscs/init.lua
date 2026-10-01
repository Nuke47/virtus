AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_effects.lua" )
AddCSLuaFile( "cl_worldmodel.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "sh_combo.lua" )
AddCSLuaFile( "sh_animations.lua" )
AddCSLuaFile( "sh_blockpoints.lua" )
AddCSLuaFile( "sh_stance_override.lua" )
include( "shared.lua" )
include("sh_combo.lua")
include("sh_animations.lua")
include("sv_blocking.lua")
include("sh_blockpoints.lua")
include( "sh_stance_override.lua" )

function SWEP:ResetHoldType()
	local Active = self:GetActive()

	if Active then
		local Combo = self:GetCombo()

		if istable( Combo ) and Combo.HoldType then
			self:SetHoldType( Combo.HoldType )
		else
			self:SetHoldType( "normal" )
		end
	else
		self:SetHoldType( "normal" )
	end
end

function SWEP:Reload()
	if (self.NextReload or 0) > CurTime() then return end
	self.NextReload = CurTime() + 0.3

	local ply = self:GetOwner()
	if not IsValid(ply) then return end

	if ply:KeyDown(IN_USE) then
		net.Start("lscs_open_stance_menu")
		net.Send(ply)
		return
	end

	if self:GetIsDefending() then
		local CurStance = self:GetNWStance()
		if CurStance == -1 then return end
		local totalStances = #ply:lscsGetCombo()
		local nextStance = CurStance + 1
		if nextStance > totalStances then nextStance = 1 end
		self:SetNWStance(nextStance)
		ply:EmitSound("weapons/smg1/switch_single.wav")
	else
		self.NextReload = CurTime() + 1
		self:SetActive( not self:GetActive() )
		if not self:GetActive() then self:SetDMGActive( false ) end
	end
end

function SWEP:OnActiveChanged( oldActive, active )
	if oldActive == nil then return end

	local IdleSound1 = self.CachedSounds[self.HAND_RIGHT].IdleSound
	local IdleSound2 = self.CachedSounds[self.HAND_LEFT].IdleSound

	if active then
		if IdleSound1 ~= "" then
			self.SaberHumSound1 = CreateSound(self, IdleSound1)
			self.SaberHumSound1:Play()
		end
		if IdleSound2 ~= "" then
			self.SaberHumSound2 = CreateSound(self:GetOwner(), IdleSound2)
			self.SaberHumSound2:Play()
		end
	else
		self:StopIdleSound()
	end
end

function SWEP:OnTick( active )
	local CurTime = CurTime()

	self:CalcBPRegen( CurTime )

	if (self.Next_Think or 0) > CurTime then return end

	local go = self:GetDMGActive()
	local vol = go and 0 or 1, 0.4
	local pitch = go and 140 or 100

	if self.SaberHumSound1 then
		self.SaberHumSound1:ChangeVolume( vol )
		self.SaberHumSound1:ChangePitch( pitch , 0.2 )
	end

	if self.SaberHumSound2 then
		vol = self:GetCombo().LeftSaberActive and vol or 0 -- this is gay

		self.SaberHumSound2:ChangeVolume( vol )
		self.SaberHumSound2:ChangePitch( pitch , 0.2 )
	end

	self.Next_Think = CurTime + 0.05
end

function SWEP:StopIdleSound()
	if self.SaberHumSound1 then
		self.SaberHumSound1:Stop()
		self.SaberHumSound1 = nil
	end
	if self.SaberHumSound2 then
		self.SaberHumSound2:Stop()
		self.SaberHumSound2 = nil
	end
end

function SWEP:OnRemove()
	self:FinishCombo()
	self:StopIdleSound()
end

function SWEP:OnDrop()
	self:FinishCombo()
	self:SetActive( false )
	self:ResetBlockBones()
	self:SetLength( 0 )
	self:StopIdleSound()

	local ply = self:GetOwner()
	if IsValid( ply ) and ply:IsPlayer() then
		ply:lscsSetShouldBleed( true )
	end
end

function SWEP:ShouldDropOnDie()
	return false
end

function SWEP:EmitSoundUnpredicted( sound )
	--break default prediction because if client/server go slightly out of sync the sounds will not play at all or will play twice.
	--imo having serverside sounds with lag is better than having no sounds at all

	timer.Simple(0, function()
		if not IsValid( self ) then return end
		self:EmitSound( sound )
	end)
end
