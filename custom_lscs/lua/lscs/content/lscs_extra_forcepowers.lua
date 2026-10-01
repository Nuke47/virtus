local function IsValidNPC( ent )
	return IsValid(ent) and (ent:IsNPC() or ent:IsNextBot())
end

-- 1. Force Speed
local force = {}
force.PrintName = "Velocidad"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Aumenta tu velocidad al correr por unos segundos"
force.id = "speed"
force.OnClk =  function( ply, TIME )
	if not ply:GetNWBool( "_lscsForceSpeed", false ) then return end
	if not ply:Alive() or ply:GetObserverMode() ~= OBS_MODE_NONE then
		ply:SetNWBool( "_lscsForceSpeed", false )
		if ply._lscsOrigRunSpeed then
			ply:SetRunSpeed(ply._lscsOrigRunSpeed)
			ply:SetWalkSpeed(ply._lscsOrigWalkSpeed)
		end
		return
	end
	ply:lscsTakeForce(0.1)
	if (ply._lscsSpeedTime or 0) < TIME or ply:lscsGetForce() <= 0 then
		ply:SetNWBool( "_lscsForceSpeed", false )
		if ply._lscsOrigRunSpeed then
			ply:SetRunSpeed(ply._lscsOrigRunSpeed)
			ply:SetWalkSpeed(ply._lscsOrigWalkSpeed)
		end
	end
end
force.UnEquip = function( ply ) 
	ply:SetNWBool( "_lscsForceSpeed", false ) 
	if ply._lscsOrigRunSpeed then
		ply:SetRunSpeed(ply._lscsOrigRunSpeed)
		ply:SetWalkSpeed(ply._lscsOrigWalkSpeed)
	end
end
force.StartUse = function( ply )
	local Time = CurTime()
	local CanDo = (ply._lscsNextForce or 0) < Time
	if not CanDo then return end
	ply._lscsNextForce = Time + 1
	if ply:GetNWBool( "_lscsForceSpeed", false ) then
		ply:SetNWBool( "_lscsForceSpeed", false )
		if ply._lscsOrigRunSpeed then
			ply:SetRunSpeed(ply._lscsOrigRunSpeed)
			ply:SetWalkSpeed(ply._lscsOrigWalkSpeed)
		end
	else
		if ply:lscsGetForce() >= 10 then
			ply:SetNWBool( "_lscsForceSpeed", true )
			ply._lscsSpeedTime = CurTime() + 10
			ply._lscsOrigRunSpeed = ply:GetRunSpeed()
			ply._lscsOrigWalkSpeed = ply:GetWalkSpeed()
			ply:SetRunSpeed(ply._lscsOrigRunSpeed * 2)
			ply:SetWalkSpeed(ply._lscsOrigWalkSpeed * 1.5)
			ply:lscsTakeForce( 10 )
			ply:EmitSound("npc/scanner/combat_scan4.wav")
		end
	end
end
LSCS:RegisterForce( force )

-- 2. Force Repulse
local force = {}
force.PrintName = "Repulsion"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Empuja todo a tu alrededor en 360 grados"
force.id = "repulse"
force.StartUse = function( ply )
	if ply:lscsGetForce() < 30 then return end
	local Time = CurTime()
	local CanPush = (ply._lscsNextForce or 0) < Time
	if not CanPush then return end
	ply._lscsNextForce = Time + 2
	ply:EmitSound("lscs/force/push.mp3", 100, 80)
	ply:lscsTakeForce( 30 )
	local MyPos = ply:GetShootPos()
	LSCS:PlayVCDSequence( ply, "gesture_item_throw", 0.5 )
	local effectdata = EffectData()
		effectdata:SetOrigin( MyPos )
		effectdata:SetEntity( ply )
	util.Effect( "force_push", effectdata, true, true )
	for _, Ent in pairs( ents.FindInSphere( MyPos, 500 ) ) do
		if Ent == ply then continue end
		local Sub = (Ent.GetShootPos and Ent:GetShootPos() or Ent:GetPos()) - MyPos
		local Dist = Sub:Length()
		if IsValid( Ent ) and Dist < 500 then
			local Vel = Sub:GetNormalized() * 1000 + Vector(0,0,200)
			LSCS:ForceApply( Ent, Vel, ply )
		end
	end
end
LSCS:RegisterForce( force )

-- 3. Force Cloak
local force = {}
force.PrintName = "Camuflaje"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Te vuelve temporalmente invisible"
force.id = "cloak"
force.OnClk =  function( ply, TIME )
	if not ply:GetNWBool( "_lscsForceCloak", false ) then return end
	if not ply:Alive() or ply:GetObserverMode() ~= OBS_MODE_NONE then
		ply:SetNWBool( "_lscsForceCloak", false )
		ply:SetMaterial("")
		return
	end
	ply:lscsTakeForce(0.5)
	if (ply._lscsCloakTime or 0) < TIME or ply:lscsGetForce() <= 0 then
		ply:SetNWBool( "_lscsForceCloak", false )
		ply:SetMaterial("")
	end
end
force.UnEquip = function( ply ) 
	ply:SetNWBool( "_lscsForceCloak", false ) 
	ply:SetMaterial("")
end
force.StartUse = function( ply )
	local Time = CurTime()
	local CanDo = (ply._lscsNextForce or 0) < Time
	if not CanDo then return end
	ply._lscsNextForce = Time + 1
	if ply:GetNWBool( "_lscsForceCloak", false ) then
		ply:SetNWBool( "_lscsForceCloak", false )
		ply:SetMaterial("")
	else
		if ply:lscsGetForce() >= 20 then
			ply:SetNWBool( "_lscsForceCloak", true )
			ply._lscsCloakTime = CurTime() + 15
			ply:SetMaterial("models/effects/vol_light001")
			ply:lscsTakeForce( 20 )
			ply:EmitSound("physics/glass/glass_impact_soft1.wav")
		end
	end
end
LSCS:RegisterForce( force )

-- 4. Force Choke
local force = {}
force.PrintName = "Asfixia"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Asfixia al objetivo, inmovilizandolo y causando dano"
force.id = "choke"
force.OnClk = function( ply, TIME )
	if not ply._lscsChokeTime then return end
	ply:lscsTakeForce( 1 )
	local target = ply._lscsChokeTarget
	if IsValid(target) and target:Health() > 0 then
		if target.IsPlayer and target:IsPlayer() and hook.Run( "LSCS:PlayerCanManipulate", ply, target, true ) then 
		else
			target:SetPos(target:GetPos() + Vector(0,0,2))
			target:SetVelocity(Vector(0,0,50))
			if target:IsPlayer() or IsValidNPC(target) then 
				target:SetMoveType(MOVETYPE_NONE) 
				if target.SetCondition then target:SetCondition(67) end
			end
			if (target._lscsNextChokeDmg or 0) < TIME then
				target._lscsNextChokeDmg = TIME + 1
				local dmginfo = DamageInfo()
				dmginfo:SetDamage( 5 )
				dmginfo:SetAttacker( ply )
				dmginfo:SetInflictor( ply ) 
				dmginfo:SetDamageType( DMG_CRUSH )
				target:TakeDamageInfo( dmginfo )
				target:EmitSound("player/pl_drown1.wav")
			end
		end
	end
	if ply._lscsChokeTime < TIME or ply:lscsGetForce() <= 0 or not ply:Alive() then
		ply._lscsChokeTime = nil
		if IsValid(target) and (target:IsPlayer() or IsValidNPC(target)) then 
			target:SetMoveType(target:IsPlayer() and MOVETYPE_WALK or MOVETYPE_STEP) 
		end
		ply._lscsChokeTarget = nil
	end
end
force.StopUse = function( ply )
	ply._lscsChokeTime = nil
	if IsValid(ply._lscsChokeTarget) and (ply._lscsChokeTarget:IsPlayer() or IsValidNPC(ply._lscsChokeTarget)) then
		ply._lscsChokeTarget:SetMoveType(ply._lscsChokeTarget:IsPlayer() and MOVETYPE_WALK or MOVETYPE_STEP)
	end
	ply._lscsChokeTarget = nil
end
force.StartUse = function( ply )
	local Time = CurTime()
	if (ply._lscsChokeTime or 0) > Time then
		force.StopUse(ply)
		return
	end
	if ply:lscsGetForce() < 10 then return end
	local CanDo = (ply._lscsNextForce or 0) < Time
	if not CanDo then return end
	ply._lscsNextForce = Time + 1
	local AimVector = ply:GetAimVector()
	local MyPos = ply:GetShootPos()
	local foundTarget = nil
	for _, victim in pairs( ents.FindInSphere( MyPos, 600 ) ) do
		if victim == ply then continue end
		local TargetPos = victim.GetShootPos and victim:GetShootPos() or victim:GetPos()
		local Sub = TargetPos - MyPos
		local ToTarget = Sub:GetNormalized()
		if math.deg( math.acos( math.Clamp( AimVector:Dot( ToTarget ) ,-1,1) ) ) < 15 then
			if util.TraceLine( {start = MyPos,endpos = victim:LocalToWorld( victim:OBBCenter() ),mask = MASK_SHOT,filter = ply,} ).Entity == victim then
				foundTarget = victim
				break
			end
		end
	end
	if IsValid(foundTarget) then
		ply._lscsChokeTime = CurTime() + 5
		ply._lscsChokeTarget = foundTarget
		ply:lscsTakeForce( 10 )
		LSCS:PlayVCDSequence( ply, "gesture_becon", 0.8 )
	end
end
LSCS:RegisterForce( force )

-- 5. Drain Life
local force = {}
force.PrintName = "Absorcion"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Drena la vida de un enemigo y cura la tuya"
force.id = "drain"
force.StartUse = function( ply )
	if ply:lscsGetForce() < 20 then return end
	local Time = CurTime()
	if (ply._lscsNextForce or 0) > Time then return end
	ply._lscsNextForce = Time + 2
	local MyPos = ply:GetShootPos()
	local AimVector = ply:GetAimVector()
	local target = nil
	for _, victim in pairs( ents.FindInSphere( MyPos, 500 ) ) do
		if victim == ply then continue end
		local ToTarget = (victim:GetPos() - MyPos):GetNormalized()
		if math.deg(math.acos(math.Clamp(AimVector:Dot(ToTarget),-1,1))) < 20 then
			target = victim
			break
		end
	end
	if IsValid(target) and target:Health() > 0 then
		ply:lscsTakeForce(20)
		local dmg = 25
		local dmginfo = DamageInfo()
		dmginfo:SetDamage( dmg )
		dmginfo:SetAttacker( ply )
		dmginfo:SetInflictor( ply ) 
		dmginfo:SetDamageType( DMG_SHOCK )
		target:TakeDamageInfo( dmginfo )
		ply:SetHealth( math.min(ply:GetMaxHealth(), ply:Health() + dmg) )
		ply:EmitSound("npc/barnacle/barnacle_gulp2.wav")
		
		local effectdata = EffectData()
		effectdata:SetOrigin( target:GetPos() )
		effectdata:SetEntity( target )
		util.Effect( "force_heal", effectdata, true, true )
	end
end
LSCS:RegisterForce( force )

-- 6. Stasis (Freeze)
local force = {}
force.PrintName = "Estasis"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Congela a los enemigos frente a ti temporalmente"
force.id = "stasis"
force.StartUse = function( ply )
	if ply:lscsGetForce() < 30 then return end
	local Time = CurTime()
	if (ply._lscsNextForce or 0) > Time then return end
	ply._lscsNextForce = Time + 2
	ply:lscsTakeForce(30)
	local MyPos = ply:GetShootPos()
	local AimVector = ply:GetAimVector()
	ply:EmitSound("physics/glass/glass_strain4.wav")
	for _, victim in pairs( ents.FindInSphere( MyPos, 600 ) ) do
		if victim == ply then continue end
		local ToTarget = ((victim.GetShootPos and victim:GetShootPos() or victim:GetPos()) - MyPos):GetNormalized()
		if math.deg(math.acos(math.Clamp(AimVector:Dot(ToTarget),-1,1))) < 30 then
			if victim:IsPlayer() or IsValidNPC(victim) then
				victim:SetMoveType(MOVETYPE_NONE)
				if victim.SetCondition then victim:SetCondition(68) end
				timer.Simple(4, function() 
					if IsValid(victim) then 
						victim:SetMoveType(victim:IsPlayer() and MOVETYPE_WALK or MOVETYPE_STEP) 
					end 
				end)
			end
		end
	end
end
LSCS:RegisterForce( force )

-- 7. Force Destruction
local force = {}
force.PrintName = "Destruccion"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Explosion de la fuerza donde apuntas"
force.id = "destruction"
force.StartUse = function( ply )
	if ply:lscsGetForce() < 40 then return end
	local Time = CurTime()
	if (ply._lscsNextForce or 0) > Time then return end
	ply._lscsNextForce = Time + 3
	ply:lscsTakeForce(40)
	ply:EmitSound("ambient/explosions/explode_9.wav")
	local tr = ply:GetEyeTrace()
	if tr.Hit then
		util.BlastDamage(ply, ply, tr.HitPos, 200, 100)
		local effectdata = EffectData()
		effectdata:SetOrigin( tr.HitPos )
		util.Effect( "Explosion", effectdata, true, true )
	end
end
LSCS:RegisterForce( force )

-- 8. Force Blink
local force = {}
force.PrintName = "Teletransporte"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Manten presionado para apuntar. Suelta para teletransportarte."
force.id = "blink"
force.StartUse = function( ply )
	if ply:lscsGetForce() < 25 then return end
	ply:SetNWBool("_lscsAimingBlink", true)
end
force.StopUse = function( ply )
	if not ply:GetNWBool("_lscsAimingBlink", false) then return end
	ply:SetNWBool("_lscsAimingBlink", false)
	
	if ply:lscsGetForce() < 25 then return end
	local Time = CurTime()
	if (ply._lscsNextForce or 0) > Time then return end
	ply._lscsNextForce = Time + 1.5
	ply:lscsTakeForce(25)
	
	local tr = util.TraceLine({
		start = ply:GetShootPos(),
		endpos = ply:GetShootPos() + ply:GetAimVector() * 10000,
		filter = ply
	})
	
	local effectdata = EffectData()
	effectdata:SetOrigin( ply:GetPos() )
	util.Effect( "force_pull", effectdata, true, true )
	
	local safePos = tr.HitPos + tr.HitNormal * 20
	ply:SetPos(safePos)
	ply:EmitSound("weapons/physcannon/physcannon_charge.wav")
	
	local effectdata2 = EffectData()
	effectdata2:SetOrigin( ply:GetPos() )
	util.Effect( "force_push", effectdata2, true, true )
end
LSCS:RegisterForce( force )

if CLIENT then
	hook.Add("PostDrawTranslucentRenderables", "!!!lscs_extra_blink_marker", function()
		local ply = LocalPlayer()
		if not IsValid(ply) or not ply:GetNWBool("_lscsAimingBlink", false) then return end
		
		local tr = util.TraceLine({
			start = ply:GetShootPos(),
			endpos = ply:GetShootPos() + ply:GetAimVector() * 10000,
			filter = ply
		})
		
		render.SetColorMaterial()
		render.DrawWireframeSphere( tr.HitPos, 20, 16, 16, Color(0, 150, 255, 255), true )
		render.DrawSphere( tr.HitPos, 19, 16, 16, Color(0, 150, 255, 50) )
	end)
end

-- 9. Force Ignite
local force = {}
force.PrintName = "Combustion"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Prende fuego a los enemigos en tu vista"
force.id = "ignite"
force.StartUse = function( ply )
	if ply:lscsGetForce() < 25 then return end
	local Time = CurTime()
	if (ply._lscsNextForce or 0) > Time then return end
	ply._lscsNextForce = Time + 2
	ply:lscsTakeForce(25)
	ply:EmitSound("ambient/fire/ignite.wav")
	local MyPos = ply:GetShootPos()
	local AimVector = ply:GetAimVector()
	for _, victim in pairs( ents.FindInSphere( MyPos, 600 ) ) do
		if victim == ply then continue end
		local ToTarget = ((victim.GetShootPos and victim:GetShootPos() or victim:GetPos()) - MyPos):GetNormalized()
		if math.deg(math.acos(math.Clamp(AimVector:Dot(ToTarget),-1,1))) < 25 then
			victim:Ignite(5)
		end
	end
end
LSCS:RegisterForce( force )

-- 10. Force Scream
local force = {}
force.PrintName = "Grito"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Un grito sonico que dana y aturde"
force.id = "scream"
force.StartUse = function( ply )
	if ply:lscsGetForce() < 20 then return end
	local Time = CurTime()
	if (ply._lscsNextForce or 0) > Time then return end
	ply._lscsNextForce = Time + 2
	ply:lscsTakeForce(20)
	ply:EmitSound("npc/fast_zombie/fz_scream1.wav", 120, 80)
	local MyPos = ply:GetShootPos()
	util.BlastDamage(ply, ply, MyPos, 400, 30)
	for _, victim in pairs( ents.FindInSphere( MyPos, 400 ) ) do
		if victim == ply then continue end
		if victim:IsPlayer() then
			victim:SetViewPunchAngles(Angle(math.random(-10,10),math.random(-10,10),math.random(-10,10)))
		elseif IsValidNPC(victim) then
			if victim.SetSchedule then victim:SetSchedule(SCHED_FLINCH_PHYSICS) end
		end
	end
end
LSCS:RegisterForce( force )

-- 11. Force Rage
local force = {}
force.PrintName = "Rabia"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Te fortalece inmensamente, a costa de tu salud"
force.id = "rage"
force.OnClk =  function( ply, TIME )
	if not ply:GetNWBool( "_lscsForceRage", false ) then return end
	if not ply:Alive() or ply:GetObserverMode() ~= OBS_MODE_NONE then
		ply:SetNWBool( "_lscsForceRage", false )
		return
	end
	if (ply._lscsNextRageDmg or 0) < TIME then
		ply._lscsNextRageDmg = TIME + 1
		ply:SetHealth(math.max(1, ply:Health() - 2))
		ply:lscsSetForce(ply:lscsGetMaxForce())
	end
	if (ply._lscsRageTime or 0) < TIME then
		ply:SetNWBool( "_lscsForceRage", false )
	end
end
force.UnEquip = function( ply ) ply:SetNWBool( "_lscsForceRage", false ) end
force.StartUse = function( ply )
	local Time = CurTime()
	if (ply._lscsNextForce or 0) > Time then return end
	ply._lscsNextForce = Time + 1
	if ply:GetNWBool( "_lscsForceRage", false ) then
		ply:SetNWBool( "_lscsForceRage", false )
	else
		ply:SetNWBool( "_lscsForceRage", true )
		ply._lscsRageTime = CurTime() + 15
		ply:EmitSound("npc/antlion_guard/angry1.wav")
	end
end
LSCS:RegisterForce( force )

-- 12. Force Quake
local force = {}
force.PrintName = "Terremoto"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Causa un temblor destructivo a tu alrededor"
force.id = "quake"
force.StartUse = function( ply )
	if ply:lscsGetForce() < 35 then return end
	if not ply:OnGround() then return end
	local Time = CurTime()
	if (ply._lscsNextForce or 0) > Time then return end
	ply._lscsNextForce = Time + 3
	ply:lscsTakeForce(35)
	ply:EmitSound("ambient/explosions/explode_4.wav")
	local MyPos = ply:GetPos()
	util.ScreenShake(MyPos, 5, 5, 2, 800)
	for _, victim in pairs( ents.FindInSphere( MyPos, 600 ) ) do
		if victim == ply then continue end
		if victim:OnGround() and (victim:IsPlayer() or IsValidNPC(victim)) then
			local dmginfo = DamageInfo()
			dmginfo:SetDamage( 40 )
			dmginfo:SetAttacker( ply )
			dmginfo:SetInflictor( ply ) 
			dmginfo:SetDamageType( DMG_CRUSH )
			victim:TakeDamageInfo( dmginfo )
			victim:SetPos(victim:GetPos() + Vector(0,0,5))
			victim:SetVelocity(Vector(0,0,400))
		end
	end
end
LSCS:RegisterForce( force )

-- 13. Meditation
local force = {}
force.PrintName = "Meditacion"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Recupera vida y fuerza pero no puedes moverte"
force.id = "meditation"
force.OnClk =  function( ply, TIME )
	if not ply:GetNWBool( "_lscsForceMeditate", false ) then return end
	if not ply:Alive() or ply:GetObserverMode() ~= OBS_MODE_NONE then
		ply:SetNWBool( "_lscsForceMeditate", false )
		ply:SetMoveType(MOVETYPE_WALK)
		return
	end
	if (ply._lscsNextMeditateHeal or 0) < TIME then
		ply._lscsNextMeditateHeal = TIME + 1
		ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + 5))
		ply:lscsSetForce(math.min(ply:lscsGetMaxForce(), ply:lscsGetForce() + 10))
	end
end
force.UnEquip = function( ply ) 
	ply:SetNWBool( "_lscsForceMeditate", false ) 
	if ply:IsPlayer() then ply:SetMoveType(MOVETYPE_WALK) end
end
force.StartUse = function( ply )
	local Time = CurTime()
	if (ply._lscsNextForce or 0) > Time then return end
	ply._lscsNextForce = Time + 1
	if ply:GetNWBool( "_lscsForceMeditate", false ) then
		ply:SetNWBool( "_lscsForceMeditate", false )
		ply:SetMoveType(MOVETYPE_WALK)
	else
		ply:SetNWBool( "_lscsForceMeditate", true )
		ply:SetMoveType(MOVETYPE_NONE)
		ply:EmitSound("ambient/wind/wind_moan1.wav")
	end
end
LSCS:RegisterForce( force )

-- 14. Force Grip
local force = {}
force.PrintName = "Agarre"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Agarra y mueve un objeto con la mente"
force.id = "grip"
force.StartUse = function( ply )
	if ply:lscsGetForce() < 5 then return end
	local tr = ply:GetEyeTrace()
	if tr.Hit and IsValid(tr.Entity) and not tr.Entity:IsPlayer() and not IsValidNPC(tr.Entity) then
		ply:lscsTakeForce(5)
		if SERVER then
			tr.Entity:SetVelocity(ply:GetAimVector() * 500 + Vector(0,0,200))
		end
		ply:EmitSound("weapons/physcannon/superphys_launch1.wav")
	end
end
LSCS:RegisterForce( force )

-- 15. Aura of Healing
local force = {}
force.PrintName = "Aura Curativa"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Cura a todos los aliados cercanos"
force.id = "auraheal"
force.StartUse = function( ply )
	if ply:lscsGetForce() < 30 then return end
	local Time = CurTime()
	if (ply._lscsNextForce or 0) > Time then return end
	ply._lscsNextForce = Time + 3
	ply:lscsTakeForce(30)
	ply:EmitSound("items/medshot4.wav")
	local MyPos = ply:GetPos()
	for _, victim in pairs( ents.FindInSphere( MyPos, 500 ) ) do
		if victim:IsPlayer() or IsValidNPC(victim) then
			victim:SetHealth(math.min(victim:GetMaxHealth(), victim:Health() + 30))
			local effectdata = EffectData()
			effectdata:SetOrigin( victim:GetPos() )
			effectdata:SetEntity( victim )
			util.Effect( "force_heal", effectdata, true, true )
		end
	end
end
LSCS:RegisterForce( force )

-- 16. Zero-G
local force = {}
force.PrintName = "Gravedad Cero"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Eleva y suspende a los enemigos en el aire"
force.id = "zerog"
force.StartUse = function( ply )
	if ply:lscsGetForce() < 30 then return end
	local Time = CurTime()
	if (ply._lscsNextForce or 0) > Time then return end
	ply._lscsNextForce = Time + 5
	ply:lscsTakeForce(30)
	ply:EmitSound("weapons/physcannon/physcannon_claws_close.wav")
	local MyPos = ply:GetPos()
	for _, victim in pairs( ents.FindInSphere( MyPos, 600 ) ) do
		if victim == ply then continue end
		if victim:IsPlayer() or IsValidNPC(victim) then
			victim:SetPos(victim:GetPos() + Vector(0,0,5))
			victim:SetVelocity(Vector(0,0,200))
			victim:SetMoveType(MOVETYPE_NONE)
			timer.Simple(3, function() 
				if IsValid(victim) then 
					victim:SetMoveType(victim:IsPlayer() and MOVETYPE_WALK or MOVETYPE_STEP) 
				end 
			end)
		end
	end
end
LSCS:RegisterForce( force )

-- 17. Force Blind
local force = {}
force.PrintName = "Ceguera"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Ciega temporalmente a tus enemigos"
force.id = "blind"
force.StartUse = function( ply )
	if ply:lscsGetForce() < 20 then return end
	local Time = CurTime()
	if (ply._lscsNextForce or 0) > Time then return end
	ply._lscsNextForce = Time + 2
	ply:lscsTakeForce(20)
	ply:EmitSound("weapons/flashbang/flashbang_explode2.wav")
	local MyPos = ply:GetShootPos()
	local AimVector = ply:GetAimVector()
	for _, victim in pairs( ents.FindInSphere( MyPos, 600 ) ) do
		if victim == ply then continue end
		local ToTarget = ((victim.GetShootPos and victim:GetShootPos() or victim:GetPos()) - MyPos):GetNormalized()
		if math.deg(math.acos(math.Clamp(AimVector:Dot(ToTarget),-1,1))) < 45 then
			if victim:IsPlayer() then
				victim:SetDSP(31, false)
				victim:ScreenFade( SCREENFADE.IN, Color( 255, 255, 255, 255 ), 2, 1 )
			elseif IsValidNPC(victim) then
				if victim.SetSchedule then victim:SetSchedule(SCHED_RUN_RANDOM) end
			end
		end
	end
end
LSCS:RegisterForce( force )

-- 18. Force Barrier
local force = {}
force.PrintName = "Burbuja Protectora"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Te hace invulnerable por unos segundos"
force.id = "barrier"
force.OnClk =  function( ply, TIME )
	if not ply:GetNWBool( "_lscsForceBarrier", false ) then return end
	if not ply:Alive() or ply:GetObserverMode() ~= OBS_MODE_NONE then
		ply:SetNWBool( "_lscsForceBarrier", false )
		return
	end
	ply:lscsTakeForce(0.5)
	if (ply._lscsBarrierTime or 0) < TIME or ply:lscsGetForce() <= 0 then
		ply:SetNWBool( "_lscsForceBarrier", false )
	end
end
force.UnEquip = function( ply ) ply:SetNWBool( "_lscsForceBarrier", false ) end
force.StartUse = function( ply )
	local Time = CurTime()
	if (ply._lscsNextForce or 0) > Time then return end
	ply._lscsNextForce = Time + 1
	if ply:GetNWBool( "_lscsForceBarrier", false ) then
		ply:SetNWBool( "_lscsForceBarrier", false )
	else
		if ply:lscsGetForce() >= 20 then
			ply:SetNWBool( "_lscsForceBarrier", true )
			ply._lscsBarrierTime = CurTime() + 5
			ply:lscsTakeForce( 20 )
			ply:EmitSound("ambient/energy/force_field_loop1.wav")
		end
	end
end
LSCS:RegisterForce( force )

-- 19. Force Deflect
local force = {}
force.PrintName = "Reflejo"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Refleja dano de vuelta al atacante"
force.id = "deflect"
force.OnClk =  function( ply, TIME )
	if not ply:GetNWBool( "_lscsForceDeflect", false ) then return end
	if not ply:Alive() or ply:GetObserverMode() ~= OBS_MODE_NONE then
		ply:SetNWBool( "_lscsForceDeflect", false )
		return
	end
	ply:lscsTakeForce(0.2)
	if (ply._lscsDeflectTime or 0) < TIME or ply:lscsGetForce() <= 0 then
		ply:SetNWBool( "_lscsForceDeflect", false )
	end
end
force.UnEquip = function( ply ) ply:SetNWBool( "_lscsForceDeflect", false ) end
force.StartUse = function( ply )
	local Time = CurTime()
	if (ply._lscsNextForce or 0) > Time then return end
	ply._lscsNextForce = Time + 1
	if ply:GetNWBool( "_lscsForceDeflect", false ) then
		ply:SetNWBool( "_lscsForceDeflect", false )
	else
		if ply:lscsGetForce() >= 15 then
			ply:SetNWBool( "_lscsForceDeflect", true )
			ply._lscsDeflectTime = CurTime() + 10
			ply:lscsTakeForce( 15 )
			ply:EmitSound("weapons/physcannon/energy_sing_loop4.wav")
		end
	end
end
LSCS:RegisterForce( force )

-- 20. Seismic Throw
local force = {}
force.PrintName = "Lanzamiento Sismico"
force.Author = "Blu-x92 / Luna / AI"
force.Description = "Levanta y lanza fuertemente a tu objetivo hacia abajo"
force.id = "seismicthrow"
force.StartUse = function( ply )
	if ply:lscsGetForce() < 25 then return end
	local Time = CurTime()
	if (ply._lscsNextForce or 0) > Time then return end
	ply._lscsNextForce = Time + 2
	local tr = ply:GetEyeTrace()
	if IsValid(tr.Entity) and (tr.Entity:IsPlayer() or IsValidNPC(tr.Entity)) then
		ply:lscsTakeForce(25)
		ply:EmitSound("ambient/wind/wind_hit1.wav")
		tr.Entity:SetPos(tr.Entity:GetPos() + Vector(0,0,5))
		tr.Entity:SetVelocity(Vector(0,0,400))
		timer.Simple(0.5, function()
			if IsValid(tr.Entity) then
				tr.Entity:SetVelocity(Vector(0,0,-2000))
				local dmg = DamageInfo()
				dmg:SetDamage(50)
				dmg:SetAttacker(ply)
				dmg:SetDamageType(DMG_CRUSH)
				tr.Entity:TakeDamageInfo(dmg)
			end
		end)
	end
end
LSCS:RegisterForce( force )

-- Hooks
if SERVER then
	hook.Add("EntityTakeDamage", "!!!lscs_extra_forcepowers_damage", function( target, dmginfo )
		if target:IsPlayer() and target:GetNWBool("_lscsForceBarrier", false) then
			dmginfo:ScaleDamage(0)
			return true
		end
		
		if target:IsPlayer() and target:GetNWBool("_lscsForceRage", false) then
			dmginfo:ScaleDamage(0.5)
		end
		local attacker = dmginfo:GetAttacker()
		if IsValid(attacker) and attacker:IsPlayer() and attacker:GetNWBool("_lscsForceRage", false) then
			dmginfo:ScaleDamage(2)
		end
		
		if target:IsPlayer() and target:GetNWBool("_lscsForceDeflect", false) then
			local dmg = dmginfo:GetDamage()
			if IsValid(attacker) and attacker ~= target then
				local refdmg = DamageInfo()
				refdmg:SetDamage(dmg)
				refdmg:SetAttacker(target)
				refdmg:SetDamageType(DMG_SHOCK)
				attacker:TakeDamageInfo(refdmg)
				dmginfo:ScaleDamage(0.5)
			end
		end
	end)
end
