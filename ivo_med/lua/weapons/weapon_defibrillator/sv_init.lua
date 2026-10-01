
if CLIENT then return end

util.AddNetworkString("defib_start_minigame")
util.AddNetworkString("defib_minigame_result")

function makefx(ent1, pos, str, ent2, broadcast)
	net.Start("defibfx")
	net.WriteEntity(ent1)
	net.WriteVector(pos)
	net.WriteString(str)
	net.WriteEntity(ent2)
	if broadcast then net.Broadcast()
	else net.Send(ent2) end
end

-- MUERTE DEL JUGADOR (FÍSICAS PERFECTAS Y TRASPASABLE)
function PlayerDied(ply, attacker, dmginfo)
	makefx(ply, Vector(0, 0, 0), "decharge", ply, false)
	local defib = weapons.GetStored("weapon_defibrillator")
	if defib.GiveWeaponsBack then
		ply.DefibWeps = {}
		for k,v in pairs(ply:GetWeapons()) do table.insert(ply.DefibWeps, v:GetClass()) end
	end
	if defib.DeathBeepEnabled then makefx(ply, Vector(0, 0, 0), "sound", ply, false) end
	ply.TimeDied = CurTime()
	makefx(ply, Vector(0, 0, 0), "timedied", ply, true)

	local plyVel = ply:GetVelocity()
	local damageForce = Vector(0, 0, 0)
	local damagePos = ply:GetPos()

	if IsValid(dmginfo) then
		damagePos = dmginfo:GetDamagePosition()
		local rawForce = dmginfo:GetDamageForce()
		if rawForce:LengthSqr() > 0 then
			damageForce = rawForce:GetNormalized() * math.min(rawForce:Length(), 4000)
		end
	end

	local customRagdoll = ents.Create("prop_ragdoll")
	customRagdoll:SetModel(ply:GetModel())
	customRagdoll:SetSkin(ply:GetSkin())
	for i = 0, ply:GetNumBodyGroups() - 1 do customRagdoll:SetBodygroup(i, ply:GetBodygroup(i)) end
	customRagdoll:SetPos(ply:GetPos())
	customRagdoll:SetAngles(ply:GetAngles())
	customRagdoll:Spawn()
	customRagdoll:Activate()
	
	customRagdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	local physCount = customRagdoll:GetPhysicsObjectCount()
	for i = 0, physCount - 1 do
		local phys = customRagdoll:GetPhysicsObjectNum(i)
		if IsValid(phys) then
			local boneId = customRagdoll:TranslatePhysBoneToBone(i)
			if boneId then
				local bp, ba = ply:GetBonePosition(boneId)
				if bp and ba then
					phys:SetPos(bp)
					phys:SetAngles(ba)
				end
			end
			phys:SetVelocity(plyVel)
		end
	end

	customRagdoll:SetNWBool("IsPlayerCorpse", true)
	customRagdoll:SetNWEntity("CorpseOwner", ply)
	ply.DefibRagdoll = customRagdoll
	ply.LastCorpsePos = customRagdoll:GetPos() 

	ply:Spectate(OBS_MODE_CHASE)
	ply:SpectateEntity(customRagdoll)

	local isTrainingDroid = false
	if IsValid(attacker) and attacker.IsDroidNPC then
		local cls = attacker:GetClass()
		local name = attacker.PrintName and string.lower(attacker.PrintName) or ""
		if string.match(cls, "t$") or string.find(name, "entrenamiento") or string.find(name, "training") then
			isTrainingDroid = true
		end
	end

	if isTrainingDroid then
		ply.IsUnconsciousFromDroid = true
		customRagdoll:SetNWBool("IsUnconscious", true)
		ply:PrintMessage(HUD_PRINTTALK, "Has quedado inconsciente.")
		
		timer.Create("DefibAutoRevive_" .. ply:EntIndex(), 120, 1, function()
			if IsValid(ply) and not ply:Alive() and ply.IsUnconsciousFromDroid then
				if IvoCitadel and IvoCitadel.Active then
					ply:PrintMessage(HUD_PRINTTALK, "La ciudadela está activa, no puedes revivir aún. Espera a que finalice.")
					timer.Create("DefibAutoReviveWaitCitadel_" .. ply:EntIndex(), 2, 0, function()
						if not (IvoCitadel and IvoCitadel.Active) then
							if IsValid(ply) and not ply:Alive() and ply.IsUnconsciousFromDroid then
								ply.IsUnconsciousFromDroid = false
								if IsValid(ply.DefibRagdoll) then
									local targetRevivePos = ply.DefibRagdoll:GetPos()
									ply.DefibRagdoll.SkipAutoRevive = true
									ply.DefibRagdoll:Remove()
									ply:UnSpectate()
									ply:Spawn()
									timer.Simple(0, function() if IsValid(ply) and ply:Alive() then ply:SetPos(targetRevivePos + Vector(0, 0, 15)) end end)
									local weaponData = weapons.GetStored("weapon_defibrillator")
									ply:SetHealth(weaponData and weaponData.HPAfterRespawn or 100)
									if weaponData and weaponData.GiveWeaponsBack and ply.DefibWeps then
										for k,v in pairs(ply.DefibWeps) do ply:Give(v) end
									end
								end
							end
							timer.Remove("DefibAutoReviveWaitCitadel_" .. ply:EntIndex())
						end
					end)
				else
					ply.IsUnconsciousFromDroid = false
					if IsValid(ply.DefibRagdoll) then
						local targetRevivePos = ply.DefibRagdoll:GetPos()
						ply.DefibRagdoll.SkipAutoRevive = true
						ply.DefibRagdoll:Remove()
						ply:UnSpectate()
						ply:Spawn()
						timer.Simple(0, function() if IsValid(ply) and ply:Alive() then ply:SetPos(targetRevivePos + Vector(0, 0, 15)) end end)
						local weaponData = weapons.GetStored("weapon_defibrillator")
						ply:SetHealth(weaponData and weaponData.HPAfterRespawn or 100)
						if weaponData and weaponData.GiveWeaponsBack and ply.DefibWeps then
							for k,v in pairs(ply.DefibWeps) do ply:Give(v) end
						end
					end
				end
			end
		end)
	else
		ply.IsUnconsciousFromDroid = false
	end

	timer.Simple(0, function()
		if !IsValid(ply) or !IsValid(customRagdoll) then return end
		
		local nativeRagdoll = ply:GetRagdollEntity()
		local usedNative = false

		if IsValid(nativeRagdoll) then
			for i = 0, physCount - 1 do
				local physCustom = customRagdoll:GetPhysicsObjectNum(i)
				local physNative = nativeRagdoll:GetPhysicsObjectNum(i)
				
				if IsValid(physCustom) and IsValid(physNative) then
					local nativeVel = physNative:GetVelocity()
					if nativeVel:Length() < plyVel:Length() * 0.5 then
						nativeVel = plyVel
					end
					physCustom:SetVelocity(nativeVel)
					physCustom:AddAngleVelocity(physNative:GetAngleVelocity())
					
					if damageForce:LengthSqr() > 0 then
						physCustom:ApplyForceOffset(damageForce / physCount, damagePos)
					end
				end
			end
			nativeRagdoll:Remove()
			usedNative = true
		end

		if !usedNative then
			for i = 0, physCount - 1 do
				local phys = customRagdoll:GetPhysicsObjectNum(i)
				if IsValid(phys) then
					phys:SetVelocity(plyVel)
					if damageForce:LengthSqr() > 0 then
						phys:ApplyForceOffset(damageForce / physCount, damagePos)
					end
				end
			end
		end
	end)
end

function PlayerSpawned(ply)
	ply:UnSpectate()

	if IsValid(ply.DefibRagdoll) then
		ply.DefibRagdoll.SkipAutoRevive = true 
		ply.DefibRagdoll:Remove()
		ply.DefibRagdoll = nil
	end

	ply.DefibJustSpawned = true
	timer.Simple(5, function() if (IsValid(ply)) then ply.DefibJustSpawned = nil end end)
end

hook.Add("EntityRemoved", "DefibRemoverToolRevive", function(ent)
	if ent:GetClass() == "prop_ragdoll" and ent:GetNWBool("IsPlayerCorpse") then
		if ent.SkipAutoRevive then return end 

		local owner = ent:GetNWEntity("CorpseOwner")
		if IsValid(owner) and !owner:Alive() then
			local finalPos = ent:GetPos()
			local weaponData = weapons.GetStored("weapon_defibrillator")
			
			timer.Simple(0.1, function()
				if IsValid(owner) and !owner:Alive() then
					owner:UnSpectate()
					owner:Spawn()
					
					timer.Simple(0, function()
						if IsValid(owner) and owner:Alive() then
							owner:SetPos(finalPos + Vector(0, 0, 15))
						end
					end)
					
					owner:SetHealth(weaponData and weaponData.HPAfterRespawn or 70)
					if weaponData and weaponData.GiveWeaponsBack and owner.DefibWeps then
						for k,v in pairs(owner.DefibWeps) do owner:Give(v) end
					end
				end
			end)
		end
	end
end)

hook.Add("Think", "TrackDefibCorpsePositions", function()
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply.DefibRagdoll) then ply.LastCorpsePos = ply.DefibRagdoll:GetPos() end
	end
end)

hook.Add("DoPlayerDeath", "defibhandledeath", PlayerDied)
hook.Add("PlayerSpawn", "defibhandlespawn", PlayerSpawned)
hook.Add("PlayerDeathSound", "defibmakedeath", function() return !weapons.Get("weapon_defibrillator").DeathBeepEnabled end)

-- RECEPCIÓN DE SOLICITUD DE REVIVIR
net.Receive("defibgiveents", function(len, ply)
    local weapon = ply:GetActiveWeapon()
    local isRevive, otherPly, pos = net.ReadBool(), net.ReadEntity(), net.ReadVector()
    local eyetrace = ply:GetEyeTraceNoCursor()
    
    if (!IsValid(ply) or !IsValid(otherPly) or !IsValid(weapon)) then return end
    if (CurTime() > weapon.CanUse) then return end

    -- Entrenamiento con maniquí
    if otherPly:GetNWBool("IsTestDummy") then
        ply.DefibTargetData = { target = otherPly, weapon = weapon, isDummy = true, pos = pos }
        net.Start("defib_start_minigame")
        net.WriteInt(0, 4) 
        net.Send(ply)
        return
    end

    -- Revivir jugador
    if otherPly:GetNWBool("IsPlayerCorpse") then
        local owner = otherPly:GetNWEntity("CorpseOwner")
        if !IsValid(owner) then return end
        
        if IvoCitadel and IvoCitadel.Active then
            ply:PrintMessage(HUD_PRINTTALK, "No puedes reanimar mientras hay una Ciudadela activa.")
            if DarkRP then DarkRP.notify(ply, 1, 5, "Reanimación bloqueada por evento Ciudadela.") end
            return
        end

        -- Verificar intentos por MÈDICO usando SteamID
        owner.MedicFails = owner.MedicFails or {}
        local medicID = ply:SteamID()
        local currentFails = owner.MedicFails[medicID] or 0

        if currentFails >= 2 then
            ply:PrintMessage(HUD_PRINTTALK, "Ya has agotado tus 2 intentos con este paciente. Deja que otro médico lo intente.")
            if DarkRP then DarkRP.notify(ply, 1, 5, "Mala praxis: Has agotado tus intentos con este paciente.") end
            return
        end

        if (owner.TimeDied + weapon.TimeToRevive) - CurTime() < 0 then
            makefx(ply, Vector(1, 1, 1), "toolongdead", ply, false)
            return
        end

        ply.DefibTargetData = { target = owner, corpseEnt = otherPly, weapon = weapon, isDummy = false, eyetrace = eyetrace }
        net.Start("defib_start_minigame")
        net.WriteInt(currentFails, 4) 
        net.Send(ply)
        return
    end

    -- Daño normal
    if !isRevive and otherPly:IsPlayer() and weapon.AllowDamage then
        makefx(ply, ply:GetEyeTrace().HitPos, "spark", ply, true)
        otherPly:TakeDamage(weapon.Damage)
        ply:SetAnimation(PLAYER_ATTACK1)
        weapon.CanUse = 0
        makefx(ply, Vector(0, 0, 0), "decharge", ply, false)
    end
end)

-- RESULTADO DEL MINIJUEGO
net.Receive("defib_minigame_result", function(len, ply)
    local success = net.ReadBool()
    if !ply.DefibTargetData then return end

    local data = ply.DefibTargetData
    ply.DefibTargetData = nil 
    local weapon = data.weapon
    
    if !IsValid(ply) or !IsValid(weapon) or !IsValid(data.target) then return end

    -- Lógica del maniquí
    if data.isDummy then
        if !success then
            weapon:EmitSound("buttons/button8.wav", 60, 100)
            weapon.CanUse = 0 
            makefx(ply, Vector(0, 0, 0), "decharge", ply, false)
            return
        end
        weapon:EmitSound("weapons/physcannon/superphys_small_zap" .. math.random(1, 4) .. ".wav")
        weapon.CanUse = 0 
        weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        makefx(ply, Vector(0, 0, 0), "decharge", ply, false)
        makefx(data.target, data.target:GetPos(), "spark", data.target, true)
        ply:PrintMessage(HUD_PRINTTALK, "¡[ENTRENAMIENTO] Práctica de RCP exitosa en el muñeco!")
        return
    end

    local owner = data.target
    -- Lógica de fallo
    if !success then
        weapon:EmitSound("buttons/button8.wav", 60, 100)
        
        -- SUMAR FALLOS A ESTE MÉDICO ESPECÍFICO
        owner.MedicFails = owner.MedicFails or {}
        local medicID = ply:SteamID()
        owner.MedicFails[medicID] = (owner.MedicFails[medicID] or 0) + 1
        
        if owner.MedicFails[medicID] >= 2 then
            if DarkRP then 
                DarkRP.notify(ply, 1, 6, "¡HAS FALLADO! Agotaste tus intentos con este paciente.")
                DarkRP.notify(owner, 1, 6, "El médico " .. ply:Nick() .. " no logró estabilizarte.")
            end
        else
            if DarkRP then DarkRP.notify(ply, 1, 5, "¡RCP FALLIDA! Solo queda 1 intento antes de que NO puedas intervenir más.") end
        end

        weapon.CanUse = 0 
        weapon:SetNextSecondaryFire(CurTime())
        weapon:SetNextPrimaryFire(CurTime())
        makefx(ply, Vector(0, 0, 0), "decharge", ply, false)
        return
    end
    
    -- === ÉXITO ===
    -- Limpiamos el historial de todos los médicos, el paciente ya está a salvo
    owner.MedicFails = nil

    local targetRevivePos = ply:GetPos() 
    if IsValid(data.corpseEnt) then
        targetRevivePos = data.corpseEnt:GetPos()
        data.corpseEnt:Remove()
    end

    weapon:EmitSound("weapons/physcannon/superphys_small_zap" .. math.random(1, 4) .. ".wav")
    weapon.CanUse = 0
    makefx(ply, Vector(0, 0, 0), "decharge", ply, false)

    if weapon.GiveMedicRPCash != 0 and DarkRP != nil then
        ply:addMoney(weapon.GiveMedicRPCash)
        DarkRP.notify(ply, 3, 6, "Has recibido $"..weapon.GiveMedicRPCash)
    end

    makefx(owner, targetRevivePos, "spark", owner, true)
    
    timer.Simple(0.3, function()
        if (!IsValid(owner)) then return end
        owner:UnSpectate()
        owner:Spawn()
        local finalPos = targetRevivePos
        timer.Simple(0, function()
            if IsValid(owner) and owner:Alive() then owner:SetPos(finalPos + Vector(0, 0, 15)) end
        end)
        owner:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        owner:SetHealth(weapon.HPAfterRespawn)
        if weapon.GiveWeaponsBack and owner.DefibWeps then
            for k,v in pairs(owner.DefibWeps) do owner:Give(v) end
        end
        owner:SetRenderMode(RENDERMODE_TRANSALPHA)
        owner:SetColor(Color(255, 255, 255, 125))
    end)

    timer.Simple(weapon.GhostTime, function()
        if (!IsValid(owner)) then return end
        owner:SetCollisionGroup(COLLISION_GROUP_NONE)
        owner:SetColor(Color(255, 255, 255, 255))
    end)
end)

-- RESETEAR AL REAPARECER
hook.Add("PlayerSpawn", "Defib_ResetMedicFails", function(ply)
    ply.MedicFails = nil
end)

-- SISTEMA DE ARRASTRE REALISTA (PESADO, AJUSTABLE Y LENTO)
hook.Add("Think", "DefibDragAndRemoveRagdoll", function()
	for _, ply in pairs(player.GetAll()) do
		if !IsValid(ply) or !ply:Alive() then continue end
		
		local wep = ply:GetActiveWeapon()
		if IsValid(wep) and wep:GetClass() == "weapon_defibrillator" and ply:KeyDown(IN_USE) then
			
			if !IsValid(ply.DraggingRagdoll) then
				local tr = ply:GetEyeTraceNoCursor()
				local ent = tr.Entity
				if IsValid(ent) and ent:GetClass() == "prop_ragdoll" and (ent:GetNWBool("IsTestDummy") or ent:GetNWBool("IsPlayerCorpse")) then
					-- AUMENTAMOS DISTANCIA: Cambiamos 15000 a 40000 (aprox 2 metros)
					if ply:GetPos():DistToSqr(ent:GetPos()) < 40000 then 
						ply.DraggingRagdoll = ent
						ply.DraggingBone = tr.PhysicsBone or 0
					end
				end
			else
				local rag = ply.DraggingRagdoll
				
				-- Soltar si está muy lejos (ajustado a la nueva distancia)
				if !IsValid(rag) or ply:GetPos():DistToSqr(rag:GetPos()) > 60000 then
					ply.DraggingRagdoll = nil
				else
					local phys = rag:GetPhysicsObjectNum(ply.DraggingBone or 0)
					-- SISTEMA DE ARRASTRE: EQUILIBRIO DE PESO (NO LIGERO, NO ANCLADO)
					if IsValid(phys) then
						local targetPos = ply:GetShootPos() + ply:GetAimVector() * 70
						local dir = targetPos - phys:GetPos()
						local dist = dir:Length()

						if dist > 200 then
							ply.DraggingRagdoll = nil
							continue
						end

						dir:Normalize()
						
						-- Velocidad de arrastre (horizontal) constante
						local speed = math.Clamp(dist * 6, 0, 200)
						local targetVel = dir * speed

						-- AJUSTE DE PESO EQUILIBRADO:
						if targetVel.z > 0 then
							-- Multiplicador 0.35: Permite levantarlo, pero se siente la resistencia.
							-- Límite 50: Permite subir escalones y bordes, pero no llega a la cabeza.
							targetVel.z = math.Clamp(targetVel.z * 5, 0, 130)
						end
						
						-- Eliminamos el empujón hacia abajo (-10) y dejamos que la gravedad 
						-- natural de GMod haga el trabajo. Esto lo hará sentir más natural.
						
						phys:Wake()
						phys:SetVelocity(targetVel)
					end

					if ply:KeyPressed(IN_RELOAD) then
						rag:Remove()
						ply.DraggingRagdoll = nil
					end
				end
			end
		else
			ply.DraggingRagdoll = nil
		end
	end
end)

-- REDUCCIÓN DE VELOCIDAD MIENTRAS ARRASTRA
hook.Add("Move", "SlowPlayerWhileDragging", function(ply, mv)
	if IsValid(ply.DraggingRagdoll) then
		local newSpeed = mv:GetMaxSpeed() * 0.50 -- Reduce la velocidad un 30%
		mv:SetMaxSpeed(newSpeed)
		mv:SetMaxClientSpeed(newSpeed)
	end
end)

util.AddNetworkString("DefibPedirAyuda")
util.AddNetworkString("DefibDesistir")

net.Receive("DefibPedirAyuda", function(len, ply)
    if ply:Health() > 0 then return end
    if ply.DefibLastHelp and CurTime() - ply.DefibLastHelp < 5 then return end
    ply.DefibLastHelp = CurTime()
    
    local sentToAny = false
    for _, v in pairs(player.GetAll()) do
        if v:GetActiveWeapon() and IsValid(v:GetActiveWeapon()) and v:GetActiveWeapon():GetClass() == "weapon_defibrillator" then
            v:PrintMessage(HUD_PRINTTALK, "[S.O.S] El paciente " .. ply:Nick() .. " está pidiendo ayuda médica urgente.")
            v:SendLua([[surface.PlaySound("npc/overwatch/radiovoice/on1.wav")]])
            sentToAny = true
        end
    end
    
    if sentToAny then
        ply:PrintMessage(HUD_PRINTTALK, "Has emitido una señal de auxilio a los médicos cercanos.")
    else
        ply:PrintMessage(HUD_PRINTTALK, "Has emitido una señal de auxilio, pero no hay médicos equipados.")
    end
end)

util.AddNetworkString("DefibDesistir_Hold")

net.Receive("DefibDesistir_Hold", function(len, ply)
    if ply:Health() > 0 then return end
    ply.IsBleedingOut = net.ReadBool()
end)

hook.Add("Think", "DefibBleedingOutProcess", function()
    local globalwep = weapons.GetStored("weapon_defibrillator")
    local defaultWait = globalwep and globalwep.disableRespawnTime or 60
    local reviveTime = globalwep and globalwep.TimeToRevive or 200
    
    for _, ply in ipairs(player.GetAll()) do
        if not ply:Alive() and ply.TimeDied then
            if ply.IsBleedingOut then
                -- Reduce the remaining time by moving TimeDied further into the past
                -- FrameTime() * 4 means the timer goes 5x faster in total
                ply.TimeDied = ply.TimeDied - (FrameTime() * 4)
            end
                
            -- Check if skip timer reached 0 (Only when actively bleeding out)
            local totalTime = ply.IsUnconsciousFromDroid and 120 or defaultWait
            if ply.IsBleedingOut and CurTime() >= ply.TimeDied + totalTime then
                ply.IsBleedingOut = false
                
                if ply.IsUnconsciousFromDroid then
                    ply.IsUnconsciousFromDroid = false
                    ply:PrintMessage(HUD_PRINTTALK, "Has desistido. Reapareciendo...")
                else
                    ply:PrintMessage(HUD_PRINTTALK, "Has desistido de la reanimación.")
                end
                
                if IsValid(ply.DefibRagdoll) then
                    ply.DefibRagdoll.SkipAutoRevive = true
                    ply.DefibRagdoll:Remove()
                end
                
                ply:UnSpectate()
                ply:Spawn()
            end
            
            -- Check for max revive time auto-respawn (Regardless of bleeding out, unless unconscious)
            if not ply.IsUnconsciousFromDroid and CurTime() >= ply.TimeDied + reviveTime then
                ply:PrintMessage(HUD_PRINTTALK, "Tiempo de reanimación agotado. Reapareciendo...")
                if IsValid(ply.DefibRagdoll) then
                    ply.DefibRagdoll.SkipAutoRevive = true
                    ply.DefibRagdoll:Remove()
                end
                ply:UnSpectate()
                ply:Spawn()
            end
        end
    end
end)