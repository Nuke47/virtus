
if SERVER then
	util.AddNetworkString( "lscs_force_anims" )
	util.AddNetworkString( "lscs_force_use" )
	util.AddNetworkString( "lscs_start_jump" )

	function LSCS:PlayVCDSequence( ply, anim, start )
		start = start or 0

		if not IsValid( ply ) then return end

		net.Start( "lscs_force_anims" ) 
			net.WriteEntity( ply )
			net.WriteString( anim )
			net.WriteFloat( start )
		net.Broadcast()

		ply:AddVCDSequenceToGestureSlot( GESTURE_SLOT_GRENADE, ply:LookupSequence( anim ), start, true )
	end

	function LSCS:ForceApply( Ent, Vel, att )
		if Ent.Alive and not Ent:Alive() then return end
		if Ent.GetObserverMode and Ent:GetObserverMode() ~= OBS_MODE_NONE then return end

		if hook.Run( "LSCS:PlayerCanManipulate", att, Ent ) then return end

		local StartPos = att:GetShootPos()
		local EndPos = Ent:LocalToWorld( Ent:OBBCenter() )

		local tr = util.TraceLine( {
			start = StartPos,
			endpos = EndPos,
			mask = MASK_SHOT,
			filter = att,
		} )

		if tr.Entity ~= Ent then return end

		if Ent.loco then
			Ent:SetPos( Ent:GetPos() + Vector(0,0,50) )
			Ent.loco:SetVelocity( Vel )
			local effectdata = EffectData()
				effectdata:SetOrigin( Ent:GetPos() )
				effectdata:SetEntity( Ent )
			util.Effect( "force_effects", effectdata, true, true )
		else
			local Phys = Ent:GetPhysicsObject()

			if IsValid( Phys ) and not Ent:IsPlayer() then
				Ent:SetPhysicsAttacker( att, 5 )

				if Phys:IsMotionEnabled() and Ent:GetMoveType() ~= MOVETYPE_NONE then
					Phys:Wake()

					if Ent:GetClass() == "prop_ragdoll" then
						for i = 1, Ent:GetPhysicsObjectCount() do
							local bone = Ent:GetPhysicsObjectNum( i )

							if bone and bone.IsValid and bone:IsValid() then
								bone:AddVelocity(  Vel )
							end
						end
					else
						if Ent:IsNPC() and Ent:GetMoveType() == MOVETYPE_STEP then
							local d = DamageInfo()
							d:SetDamage( 50 )
							d:SetDamageForce( Vel * 100 )
							d:SetAttacker( att )
							d:SetDamageType( DMG_CRUSH ) 
							d:SetDamagePosition( EndPos )

							Ent:TakeDamageInfo( d )
						else
							Phys:SetVelocity( Vel )
						end
					end

					local effectdata = EffectData()
						effectdata:SetOrigin( Ent:GetPos() )
						effectdata:SetEntity( Ent )
					util.Effect( "force_effects", effectdata, true, true )
				end
			else
				if Ent.IsPlayer and Ent:IsPlayer() then
					local effectdata = EffectData()
						effectdata:SetOrigin( Ent:GetPos() )
						effectdata:SetEntity( Ent )
					util.Effect( "force_effects", effectdata, true, true )

					if Ent:OnGround() then
						Ent:SetPos( Ent:GetPos() + Vector(0,0,10) )
					end

					Ent:SetVelocity( Vel )
				end
			end
		end
	end

	hook.Add( "StartCommand", "!!!!!!lscs_forcejumpforcer", function( ply, cmd )
		if (ply._lscsForceJumpTime or 0) > CurTime() then
			cmd:SetButtons( bit.bor( cmd:GetButtons(), IN_JUMP ) )
		end
	end )

	local TICK_MIN = 1/14
	local NEXT_THINK = 0

	hook.Add( "Think", "!!!!lscs_unforgiveable_playerGetAll_loop_in_think_hook", function()
		local TIME = CurTime()

		if FrameTime() <= TICK_MIN then -- below this tickrate we run risk skipping the correct timing...
			if NEXT_THINK > TIME then return end

			NEXT_THINK = TIME + 0.1 -- slow it down to be nice to the server. The HUD is specifically designed to mask this slow updating.
		end

		for _, ply in ipairs( player.GetAll() ) do
			if not ply:lscsGetForceAllowed() then continue end

			hook.Run( "LSCS:PlayerForcePowerThink", ply, TIME )

			if (ply._lscsNextForceRegen or 0) > TIME then continue end

			if not ply:InVehicle() then
				if not ply:OnGround() and ply:GetMoveType() ~= MOVETYPE_NOCLIP then continue end
			end

			local OldValue = ply:lscsGetForce()
			local NewValue = math.min(OldValue + ply:lscsGetForceRegenAmount(),ply:lscsGetMaxForce())

			if NewValue == OldValue then continue end

			ply:lscsSetForce( NewValue )
		end
	end )

	net.Receive( "lscs_force_use", function( len, ply )
		if not IsValid( ply ) then return end
		if not ply:Alive() then return end

		if ply:InVehicle() and not ply:GetAllowWeaponsInVehicle() then return end

		local ID = net.ReadInt( 8 )
		local Activate = net.ReadBool()
		local ForcePowers = ply:lscsGetForceAbilities()

		local selectedF = ForcePowers[ ID ]

		if not selectedF then return end

		local item = selectedF.item

		if not item then return end

		if not ply._lscsUsedPowers then
			ply._lscsUsedPowers = {}
		end

		if Activate then
			if not ply:lscsGetForceAllowed() then return end

			if hook.Run( "LSCS:OnPlayerForceUse", ply, item.id, item ) == false then return end

			ply._lscsUsedPowers[ ID ] = true

			ProtectedCall( function() LSCS.Force[ item.id ].StartUse( ply ) end )
		else
			if ply._lscsUsedPowers[ ID ] then
				ply._lscsUsedPowers[ ID ] = nil

				ProtectedCall( function() LSCS.Force[ item.id ].StopUse( ply ) end )
			end
		end
	end )

	hook.Add( "LSCS:OnPlayerEquippedItem", "!!!!lscs_forcepower_equip_handler", function( ply, item )
		if not IsValid( ply ) or not item then return end

		if item.type == "force" then
			ProtectedCall( function() LSCS.Force[ item.id ].Equip( ply ) end )
		end
	end)

	hook.Add( "LSCS:OnPlayerUnEquippedItem", "!!!!lscs_forcepower_unequip_handler", function( ply, item )
		if not IsValid( ply ) or not item then return end

		if item.type == "force" then
			ProtectedCall( function() LSCS.Force[ item.id ].UnEquip( ply ) end )
		end
	end)

	hook.Add( "PlayerDeath", "!!!!lscs_forcepower_playerdeath", function( ply )
		if not ply._lscsUsedPowers then return end

		local ForcePowers = ply:lscsGetForceAbilities()

		for ID, _ in pairs( ply._lscsUsedPowers ) do
			ProtectedCall( function() LSCS.Force[ ForcePowers[ ID ].item.id ].StopUse( ply ) end )
			ply._lscsUsedPowers[ ID ]= nil
		end

		net.Start("lscs_force_use")
		net.Send( ply )
	end )
else
	local smAlpha = 0

	local ForceIcon = Material( "lscs/ui/force_hud.png" )

	hook.Add( "InitPostEntity", "!!!lscs_bullshit", function()
		local ply = LocalPlayer()
		ply._lscsOldIsMax = CurTime() - 1
	end )

	hook.Add( "HUDPaint", "!!!!lscs_ShowForceMana", function()
    if LSCS:HUDShouldHide( LSCS_HUD_POINTS_FORCE ) then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or (ply:InVehicle() and not ply:GetAllowWeaponsInVehicle()) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not wep.LSCS then return end

    local Time = CurTime()
    local F = ply:lscsGetForce()
    local Fmax = ply:lscsGetMaxForce()

    local IsMax = F == Fmax

    if IsMax then
        if not ply._lscsOldIsMax then
            ply._lscsOldIsMax = Time + 5 
        end
    else
        ply._lscsOldIsMax = nil
    end

    local smRate = RealFrameTime()
    local tAlpha = (IsMax and ply._lscsOldIsMax < Time) and 0 or 1

    smAlpha = smAlpha + math.Clamp(tAlpha - smAlpha,-smRate * 3,smRate * 6)

    if IsValid( wep ) and wep.LSCS then
        if ply:InVehicle() then
            if ply:GetAllowWeaponsInVehicle() then
                smAlpha = 1
            end
        else
            smAlpha = 1
        end
    end

    if smAlpha <= 0.01 then return end

    local centerX = ScrW() / 2
    local baseY = ScrH() - 150 
    
    local barW = 260 
    local barH = 8
    local fRatio = math.Clamp( F / Fmax, 0, 1 )
    local currentWidth = math.max(1, barW * fRatio)

    local xPos = centerX - barW / 2
    local yPos = baseY - 20

    -- 1. EL BORDE NEGRO: Rectángulo duro de 1 píxel (Igual a la barra celeste)
    surface.SetDrawColor( 0, 0, 0, 200 * smAlpha )
    surface.DrawRect( xPos - 1, yPos - 1, barW + 2, barH + 2 )
    
    -- 2. FONDO VACÍO: Rectángulo duro
    surface.SetDrawColor( 0, 0, 0, 150 * smAlpha )
    surface.DrawRect( xPos, yPos, barW, barH )

    -- 3. BARRA BLANCA RECTANGULAR
    if fRatio > 0 then
        -- Base blanca plana
        surface.SetDrawColor( 220, 240, 255, 200 * smAlpha )
        surface.DrawRect( xPos, yPos, currentWidth, barH )

        -- 4. LOS GRADIENTES (Ahora cubren el 100% de la barra, sin cortes feos)
        -- B. Sombreado vertical (Volumen)
        surface.SetMaterial( Material("vgui/gradient-d") )
        surface.SetDrawColor( 0, 0, 0, 120 * smAlpha )
        surface.DrawTexturedRect( xPos, yPos, currentWidth, barH )

        -- C. Brillo Punta Izquierda
        local leftW = math.min(currentWidth, 60)
        surface.SetMaterial( Material("vgui/gradient-l") )
        surface.SetDrawColor( 255, 255, 255, 150 * smAlpha ) 
        surface.DrawTexturedRect( xPos, yPos, leftW, barH )
        
        -- D. Brillo Punta Derecha
        local rightW = math.min(currentWidth, 60)
        surface.SetMaterial( Material("vgui/gradient-r") )
        surface.SetDrawColor( 255, 255, 255, 220 * smAlpha )
        surface.DrawTexturedRect( xPos + currentWidth - rightW, yPos, rightW, barH )
    end
end )

	net.Receive( "lscs_start_jump", function( len )
		local ply = LocalPlayer()

		ply.m_bJumping = true

		ply.m_bFirstJumpFrame = true
		ply.m_flJumpStartTime = CurTime()

		ply:AnimRestartMainSequence()
	end )

	net.Receive( "lscs_force_anims", function( len )
		local ply = net.ReadEntity()
		
		if not IsValid( ply ) then return end

		local seq = net.ReadString()
		local start = net.ReadFloat()

		ply:AddVCDSequenceToGestureSlot( GESTURE_SLOT_GRENADE, ply:LookupSequence( seq ), start, true )
	end )
end