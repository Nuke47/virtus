util.AddNetworkString("Meditation_Sync")

local function PlayDummyAnim(dummy, animName)
	if not IsValid(dummy) then return 1 end
	local seq = dummy:LookupSequence(animName)
	if seq <= 0 then seq = dummy:LookupSequence("sit_zen") end
	if seq <= 0 then seq = dummy:LookupSequence("sit") end
	if seq > 0 then
		dummy:ResetSequence(seq)
		dummy:SetPlaybackRate(1)
		dummy:SetCycle(0)
		local dur = dummy:SequenceDuration(seq)
		return (dur > 0) and dur or 1
	end
	return 1
end

local function EnterMeditation(ply, spot)
	if ply:GetNWInt("MeditationPhase", 0) ~= 0 then return end

	ply:SetNWInt("MeditationPhase", 1)
	
	-- Stop player movement instantly
	ply.Meditation_OldMoveType = ply:GetMoveType()
	ply:SetMoveType(MOVETYPE_NONE)
	
	-- Save current state
	ply.Meditation_OldPos = ply:GetPos()
	ply.Meditation_OldAngles = ply:EyeAngles()
	
	-- Spawn dummy
	local dummy = ents.Create("meditation_dummy")
	if IsValid(dummy) then
		dummy:SetPos(ply:GetPos())
		dummy:SetAngles(Angle(0, ply:EyeAngles().y, 0))
		dummy:Spawn()
		dummy:SetPlayer(ply)
		dummy:SetAutomaticFrameAdvance(true)
		ply.Meditation_Dummy = dummy
		
		-- Override default animation
		local duration = PlayDummyAnim(dummy, "wos_bs_shared_sit_down")
		
		-- Hide physical player
		ply:SetSolid(SOLID_NONE)
		ply:SetNoDraw(true)
		ply:DrawViewModel(false)
		
		if IsValid(ply:GetActiveWeapon()) then
			ply:GetActiveWeapon():SetNoDraw(true)
		end
		
		-- Timer to transition to Phase 2 (Void)
		timer.Simple(duration, function()
			if not IsValid(ply) or ply:GetNWInt("MeditationPhase", 0) ~= 1 then return end
			
			-- Fade to pure black smoothly
			ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 0.6, 0.1)
			ply:EmitSound("ambient/atmosphere/cave_hit" .. math.random(1, 6) .. ".wav", 50, 80)
			
			timer.Simple(0.6, function()
				if not IsValid(ply) or ply:GetNWInt("MeditationPhase", 0) ~= 1 then return end
				
				ply:SetNWInt("MeditationPhase", 2)
				if IsValid(ply.Meditation_Dummy) then
					PlayDummyAnim(ply.Meditation_Dummy, "sit_zen")
				end
				
				ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 0.6, 0)
			end)
		end)
	end
end
hook.Add("Meditation_Enter", "HandleMeditationEnter", EnterMeditation)

local function ExitMeditation(ply)
	if ply:GetNWInt("MeditationPhase", 0) ~= 2 then return end
	
	-- Fade out from void FIRST (don't change phase yet)
	ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 0.6, 0.1)
	
	timer.Simple(0.6, function()
		if not IsValid(ply) or ply:GetNWInt("MeditationPhase", 0) ~= 2 then return end
		
		ply:SetNWInt("MeditationPhase", 3)
		
		-- Fade into reality while standing up
		ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 0.6, 0)
		
		local duration = 1
		if IsValid(ply.Meditation_Dummy) then
			duration = PlayDummyAnim(ply.Meditation_Dummy, "wos_bs_shared_sit_up")
		end
		
		timer.Simple(duration, function()
			if not IsValid(ply) or ply:GetNWInt("MeditationPhase", 0) ~= 3 then return end
			
			ply:SetNWInt("MeditationPhase", 0)
			
			if IsValid(ply.Meditation_Dummy) then
				ply.Meditation_Dummy:Remove()
			end
			
			if ply.Meditation_OldPos then ply:SetPos(ply.Meditation_OldPos) end
			if ply.Meditation_OldAngles then ply:SetEyeAngles(ply.Meditation_OldAngles) end
			if ply.Meditation_OldMoveType then ply:SetMoveType(ply.Meditation_OldMoveType) else ply:SetMoveType(MOVETYPE_WALK) end
			
			ply:SetSolid(SOLID_BBOX)
			ply:SetNoDraw(false)
			ply:DrawViewModel(true)
			if IsValid(ply:GetActiveWeapon()) then ply:GetActiveWeapon():SetNoDraw(false) end
		end)
	end)
end

util.AddNetworkString("Meditation_Action_Rest")
util.AddNetworkString("Meditation_Action_Exit")

net.Receive("Meditation_Action_Rest", function(len, ply)
	if ply:GetNWInt("MeditationPhase", 0) ~= 2 then return end
	
	ply:SetHealth(ply:GetMaxHealth())
	if ply:GetMaxArmor() > 0 then
		ply:SetArmor(ply:GetMaxArmor())
	end
	
	-- Salir de la meditación automáticamente al descansar
	ExitMeditation(ply)
end)

net.Receive("Meditation_Action_Exit", function(len, ply)
	if ply:GetNWInt("MeditationPhase", 0) ~= 2 then return end
	ExitMeditation(ply)
end)

-- Congelar los controles físicos del jugador en el mundo real mientras medita
hook.Add("StartCommand", "Meditation_FreezeRealBody", function(ply, cmd)
	if ply:GetNWBool("IsMeditating", false) then
		cmd:ClearMovement()
		if ply.Meditation_OldAngles then
			cmd:SetViewAngles(ply.Meditation_OldAngles)
		end
	end
end)

-- Prevent player from taking damage while meditating
hook.Add("EntityTakeDamage", "MeditationDamage", function(target, dmginfo)
	if target:IsPlayer() and target:GetNWBool("IsMeditating", false) then
		return true
	end
end)

hook.Add("PlayerShouldTakeDamage", "MeditationDamagePlayer", function(ply, attacker)
	if ply:GetNWBool("IsMeditating", false) then return false end
end)

-- Prevent players from using weapons while meditating
hook.Add("PlayerCanHearPlayersVoice", "MeditationVoice", function(listener, talker)
	-- Optional: isolate voice chat
end)
