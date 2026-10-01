
--SWEP.Base = "weapon_pvebase"
--DEFINE_BASECLASS( "weapon_pvebase" )
SWEP.Base = "weapon_base"

SWEP.Category			= "[LSCS]"

SWEP.PrintName		= "#lscsGlowstick"
SWEP.Author			= "Blu-x92 / Luna"

SWEP.ViewModel		= "models/weapons/c_arms.mdl"
SWEP.WorldModel		= "models/lscs/weapons/katarn.mdl"

SWEP.Spawnable		= true
SWEP.AdminOnly		= false

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

SWEP.RenderGroup = RENDERGROUP_BOTH 

SWEP.AutoSwitchFrom = false

SWEP.LSCS = true

SWEP._tblHilt = {}
SWEP._tblBlade = {}

SWEP.HAND_RIGHT = 1
SWEP.HAND_LEFT = 2
SWEP.HAND_STRING = {
	[SWEP.HAND_RIGHT] = "RH",
	[SWEP.HAND_LEFT] = "LH",
}

SWEP.CachedSounds = {
	[SWEP.HAND_RIGHT]	= {
		AttackSound = "",
		AttackSound1 = "",
		AttackSound2 = "",
		AttackSound3 = "",
		ActivateSound = "",
		DisableSound = "",
		IdleSound = "",
	},
	[SWEP.HAND_LEFT] = {
		AttackSound = "",
		AttackSound1 = "",
		AttackSound2 = "",
		AttackSound3 = "",
		ActivateSound = "",
		DisableSound = "",
		IdleSound = "",
	},
}

function SWEP:SetupDataTables()
	self:NetworkVar( "Bool",0, "Active" )
	self:NetworkVar( "Bool",1, "NWDMGActive" )
	self:NetworkVar( "Bool",2, "AnimHasCancelAnim" )

	self:NetworkVar( "Float",0, "NWNextAttack" )
	self:NetworkVar( "Float",1, "NWGestureTime" )
	self:NetworkVar( "Float",2, "Length" )
	self:NetworkVar( "Float",3, "ComboHits" )
	self:NetworkVar( "Float",4, "BlockPointNotifyTime" )

	self:NetworkVar( "Int",0, "NWStance" )
	self:NetworkVar( "Int",1, "BlockPoints" )

	self:NetworkVar( "Vector",0, "BlockPos" )

	self:NetworkVar( "String",0, "HiltR")
	self:NetworkVar( "String",1, "HiltL")
	self:NetworkVar( "String",2, "BladeR")
	self:NetworkVar( "String",3, "BladeL")

	self:NetworkVar( "Entity",0, "Projectile" )
	self:NetworkVar( "Bool",3, "IsDefending" )

	if SERVER then
		self:SetNWStance( 1 )
	end
end

function SWEP:IsThrown()
	return IsValid( self:GetProjectile() )
end

function SWEP:GetHiltData( hand )
	local HiltR = self:GetHiltR()
	local HiltL = self:GetHiltL()

	if self._oldHiltR ~= HiltR then
		self._oldHiltR = HiltR

		local _HiltR = LSCS:GetHilt( HiltR )

		self._tblHilt[self.HAND_RIGHT] = _HiltR

		if CLIENT then
			self:UpdateWorldModel(self.HAND_RIGHT, _HiltR)
		end
	end

	if self._oldHiltL ~= HiltL then
		self._oldHiltL = HiltL

		local _HiltL = LSCS:GetHilt( HiltL )

		self._tblHilt[self.HAND_LEFT] = _HiltL

		if CLIENT then
			self:UpdateWorldModel(self.HAND_LEFT, _HiltL)
		end
	end

	if hand then
		return self._tblHilt[ hand ]
	else
		return self._tblHilt
	end
end

function SWEP:GetBladeData( hand )
	local BladeR = self:GetBladeR()
	local BladeL = self:GetBladeL()

	if self._oldBladeR ~= BladeR then
		self._oldBladeR = BladeR
		self._tblBlade[1] = LSCS:GetBlade( BladeR )
	end

	if self._oldBladeL ~= BladeL then
		self._oldBladeL = BladeL
		self._tblBlade[2] = LSCS:GetBlade( BladeL )
	end

	if hand then
		return self._tblBlade[ hand ]
	else
		return self._tblBlade
	end
end

function SWEP:BuildSounds()
	if self:IsBrokenSaber() then return end

	for hand = 1, 2 do
		local data = self:GetBladeData()[ hand ]

		if data then
			local SND = data.sounds

			self.CachedSounds[ hand ] = {
				AttackSound = (SND.Attack or ""),
				AttackSound1 = (SND.Attack1 or ""),
				AttackSound2 = (SND.Attack2 or ""),
				AttackSound3 = (SND.Attack3 or ""),
				ActivateSound = (SND.Activate or ""),
				DisableSound = (SND.Disable or ""),
				IdleSound = (SND.Idle or ""),
			}
		else
			self.CachedSounds[ hand ] = {
				AttackSound = "",
				AttackSound1 = "",
				AttackSound2 = "",
				AttackSound3 = "",
				ActivateSound = "",
				DisableSound = "",
				IdleSound = "",
			}
		end
	end
end

function SWEP:SetDMGActive( active )
	if SERVER then
		self:SetNWDMGActive( active )
	else
		self.b_dmgActive = active
	end
end

function SWEP:GetDMGActive()
	if CLIENT and not self:IsThrown() then
		if self:GetOwner() ~= LocalPlayer() then
			return self:GetNWDMGActive()
		else
			return self.b_dmgActive
		end
	else
		return self:GetNWDMGActive()
	end
end

function SWEP:SetNextPrimaryAttack( time )
	self:SetNWNextAttack( time )
	self.f_NextAttack = time
end

function SWEP:GetNextPrimaryAttack()
	if game.SinglePlayer() then
		return (self.f_NextAttack or 0) -- singleplayer IS a prediction error
	else
		return math.max( (self.f_NextAttack or 0), self:GetNWNextAttack()) -- first variable is for prediction, second variable for correcting when the server responds.
	end
end

function SWEP:CanPrimaryAttack()
	return self:GetNextPrimaryAttack() < CurTime()
end

function SWEP:Initialize()
	self:SetHoldType( "normal" )
	self:DrawShadow( false )
	self:SetNextPrimaryAttack( CurTime() + 1 )
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
	-- Left empty, handled in Think
end

function SWEP:DoAttackSound( N, hand )
	if not self:GetDMGActive() then return end

	if hand then
		if hand == self.HAND_LEFT and not self:GetCombo().LeftSaberActive then return end -- this is gay

		if N then
			if N == 1 then
				self:EmitSoundUnpredicted( self.CachedSounds[ hand ].AttackSound1 )
			elseif N == 2 then
				self:EmitSoundUnpredicted( self.CachedSounds[ hand ].AttackSound2 )
			elseif N == 3 then
				self:EmitSoundUnpredicted( self.CachedSounds[ hand ].AttackSound3 )
			else
				self:EmitSoundUnpredicted( self.CachedSounds[ hand ].AttackSound )
			end
		else
			self:EmitSoundUnpredicted( self.CachedSounds[ hand ].AttackSound )
		end
	else
		for hand = self.HAND_RIGHT, self.HAND_LEFT do
			if hand == self.HAND_LEFT and not self:GetCombo().LeftSaberActive then continue end -- this is gay

			if N then
				if N == 1 then
					self:EmitSoundUnpredicted( self.CachedSounds[ hand ].AttackSound1 )
				elseif N == 2 then
					self:EmitSoundUnpredicted( self.CachedSounds[ hand ].AttackSound2 )
				elseif N == 3 then
					self:EmitSoundUnpredicted( self.CachedSounds[ hand ].AttackSound3 )
				else
					self:EmitSoundUnpredicted( self.CachedSounds[ hand ].AttackSound )
				end
			else
				self:EmitSoundUnpredicted( self.CachedSounds[ hand ].AttackSound )
			end
		end
	end
end

function SWEP:ResetBlockBones()
	if IsValid(self:GetOwner()) then
		local ply = self:GetOwner()
		local boneUpper = ply:LookupBone("ValveBiped.Bip01_R_UpperArm")
		if boneUpper then ply:ManipulateBoneAngles(boneUpper, Angle(0, 0, 0)) end

		local boneHand = ply:LookupBone("ValveBiped.Bip01_R_Hand")
		if boneHand then ply:ManipulateBoneAngles(boneHand, Angle(0, 0, 0)) end

		self.lscs_bone_angles = nil
	end
end

function SWEP:Holster( wep )
	self:SetActive( false )
	self:SetLength( 0 )

	self:FinishCombo()

	self:Think()

	self:ResetBlockBones()

	if SERVER then
		local ply = self:GetOwner()
		if IsValid( ply ) and ply:IsPlayer() then
			ply:lscsSetShouldBleed( true )
		end
	end

	return true
end

function SWEP:BeginAttack()
	self:SetDMGActive( true )
end

function SWEP:FinishAttack()
	self:SetDMGActive( false )

	local ply = self:GetOwner()
	if IsValid( ply ) then
		ply:lscsClearTimedMove()
		ply:Freeze( false )
	end

	self:SetBlockPos( Vector(0,0,0) )
end

function SWEP:Deploy()
	local ply = self:GetOwner()
	if SERVER and IsValid(ply) and ply:IsPlayer() and ply.lscsGetHilt then
		local HiltR, HiltL = ply:lscsGetHilt()
		local BladeR, BladeL = ply:lscsGetBlade()

		self:SetHiltR( HiltR or "" )
		self:SetHiltL( HiltL or "" )
		self:SetBladeR( BladeR or "" )
		self:SetBladeL( BladeL or "" )
		self:SetBlockPoints( 999999 )
	end
	return true
end

function SWEP:OwnerChanged()
	self:ResetBlockBones()
end

function SWEP:IsBrokenSaber()
	if not self._IsBroken then
		local Hilt1 = self:GetHiltR() == "" and 0 or 1
		local Hilt2 = self:GetHiltL() == "" and 0 or 1
		local Blade1 = self:GetBladeR() == "" and 0 or 1
		local Blade2 = self:GetBladeL() == "" and 0 or 1

		self._IsBroken = ((Hilt1 + Blade1) ~= 2 and (Hilt2 + Blade2) ~= 2)
	end

	return self._IsBroken
end

function SWEP:Think()
	self:ComboThink()

	local Active = self:GetActive()
	local Stance = self:GetStance()

	local FT = FrameTime()
	local Length = self:GetLength()

	self:SetLength( Length + math.Clamp((Active and 1 or 0) - Length,-FT * 1.5,FT * 3) )
	
	if IsValid(self:GetOwner()) then
		local ply = self:GetOwner()
		local isDef = ply:KeyDown(IN_ATTACK2) and Active
		local lastDeflect = self:GetNWFloat("lscs_last_deflect", 0)
		local isDeflecting = isDef and (CurTime() - lastDeflect < 0.5)

		if self:GetIsDefending() ~= isDef then
			self:SetIsDefending(isDef)
		end

		if self:IsThrown() then
			self:SetHoldType("magic")
			if self.playing_deflect_gesture then
				ply:AnimResetGestureSlot( GESTURE_SLOT_VCD )
				self.playing_deflect_gesture = false
				self.deflect_gesture_layer = nil
			end
		elseif isDeflecting then
			self:SetHoldType("lscs_deflecting")
			if not self.playing_deflect_gesture then
				local seq = ply:LookupSequence("block1")
				if seq and seq > 0 then
					self.deflect_gesture_layer = ply:AddVCDSequenceToGestureSlot( GESTURE_SLOT_VCD, seq, 0, false )
					if self.deflect_gesture_layer and ply.SetLayerPlaybackRate then
						ply:SetLayerPlaybackRate( self.deflect_gesture_layer, 0 ) -- Pause automatic playback
					end
				end
				self.playing_deflect_gesture = true
				self.deflect_gesture_time = 0
			end
			
			if self.deflect_gesture_layer and ply.SetLayerCycle then
				-- Ping-pong precisely between 0% and 100% of the block1 animation
				self.deflect_gesture_time = self.deflect_gesture_time + (FrameTime() * 1.5) -- Swing speed
				
				-- math.abs((time % 2) - 1) creates a perfect triangle wave from 1 to 0 to 1
				local cycle = math.abs((self.deflect_gesture_time % 2) - 1)
				
				ply:SetLayerCycle( self.deflect_gesture_layer, cycle )
				if ply.SetLayerWeight then
					ply:SetLayerWeight( self.deflect_gesture_layer, 1 )
				end
			end
		elseif isDef then
			self:SetHoldType("lscs_defense")
			if self.playing_deflect_gesture then
				ply:AnimResetGestureSlot( GESTURE_SLOT_VCD )
				self.playing_deflect_gesture = false
				self.deflect_gesture_layer = nil
			end
		else
			self:SetHoldType(self:GetCombo().HoldType or "normal")
			if self.playing_deflect_gesture then
				ply:AnimResetGestureSlot( GESTURE_SLOT_VCD )
				self.playing_deflect_gesture = false
				self.deflect_gesture_layer = nil
			end
		end

		-- Run bone manipulation on both Client and Server for smooth visuals and accurate hitboxes
		if not self.lscs_bone_angles then
				self.lscs_bone_angles = {
					shoulder = Angle(0, 0, 0),
					forearm = Angle(0, 0, 0),
					wrist = Angle(0, 0, 0)
				}
			elseif not self.lscs_bone_angles.forearm then
				self.lscs_bone_angles.forearm = Angle(0, 0, 0)
			end

			local targetShoulder = Angle(0, 0, 0)
			local targetForearm = Angle(0, 0, 0)
			local targetWrist = Angle(0, 0, 0)

			if isDeflecting then
				local targetPos = self:GetNWVector("lscs_block_target", vector_origin)
				if targetPos ~= vector_origin then
				local dir = (targetPos - ply:GetShootPos()):GetNormalized()
				local angleToTarget = ply:WorldToLocalAngles(dir:Angle())
				
				local yawOffset = math.Clamp(angleToTarget.y, -60, 60)
				local upOffset = math.Clamp(-angleToTarget.p, -50, 50)

				
				-- =================================================================
				-- GUÍA DE HUESOS Y ÁNGULOS (EDITA LOS NÚMEROS AQUÍ PARA PERSONALIZAR)
				-- =================================================================
				
				-- 1. HOMBRO (Bip01_R_UpperArm)
				-- Pitch: Tuerce el bíceps (crea el barrido tipo parabrisas).
				-- Yaw: Mueve el brazo entero hacia ADELANTE (negativo) o ATRÁS (positivo).
				-- Roll: Separa el codo de las costillas (positivo lo levanta como un alero).
				
				local hombroTorcer = math.sin(CurTime() * 12) * 65 -- Animación de barrido
				local hombroAdelanteAtras = -90 + (yawOffset * -1.6) + (math.cos(CurTime() * 8) * 5) -- Base -90 (frente)
				local hombroSeparacion = 10 + (upOffset * -2.6) -- Base 0 (sin separación extra)
				
				targetShoulder = Angle( hombroTorcer, hombroAdelanteAtras, hombroSeparacion )
				
				-- 2. ANTEBRAZO (Bip01_R_Forearm)
				-- Pitch: Rota todo el antebrazo. Dejalo en 0 para no torcerlo.
				-- Yaw: ¡ESTE DOBLA O ESTIRA EL CODO! Valores positivos (ej: 90) lo estiran hacia adelante.
				-- Roll: Movimiento lateral del codo.
				
				local codoBombear = math.sin(CurTime() * 18) * 5 -- Animación de estocadas rápidas
				
				-- EL SECRETO ESTÁ AQUÍ (Yaw): 
				-- La animación base lo tiene doblado a -100 (contra tu cara).
				-- Al ponerle +90, forzamos matemáticamente que la bisagra se abra hacia adelante.
				local antebrazoEstirarCodo = 0 + codoBombear
				
				targetForearm = Angle( -60, antebrazoEstirarCodo, 0 )
				
				-- 3. MUÑECA (Bip01_R_Hand)
				-- Pitch: Dobla la mano hacia adelante o atrás (apunta la espada al enemigo).
				-- Yaw: Dobla la mano hacia los lados.
				-- Roll: Gira la muñeca sobre sí misma (el péndulo cortante de la espada).
				
				local munecaApuntaAdelante = 40 + (upOffset * 0.5) -- -90 fuerza la espada a apuntar al frente
				local munecaApuntaLados = 60 + (yawOffset * -1.5)
				
				-- ANIMACIÓN: Péndulo orgánico hiper-variado.
				-- Combiné 3 ondas a diferentes velocidades para crear movimientos impredecibles (cortos, largos, lentos y rápidos).
				local onda1 = math.sin(CurTime() * 10) * 50
				local onda2 = math.cos(CurTime() * 17) * 40
				local onda3 = math.sin(CurTime() * 6) * 30
				local munecaBarridoVariado = onda1 + onda2 + onda3
				
				targetWrist = Angle( munecaApuntaAdelante, munecaApuntaLados, munecaBarridoVariado )
				-- =================================================================
				end
			end

			-- Make the wrist snap very fast (30), while the shoulder follows slightly smoother (15)
			local ftShoulder = FrameTime() * 15
			local ftWrist = FrameTime() * 30
			
			self.lscs_bone_angles.shoulder = LerpAngle(ftShoulder, self.lscs_bone_angles.shoulder, targetShoulder)
			self.lscs_bone_angles.forearm = LerpAngle(ftShoulder, self.lscs_bone_angles.forearm, targetForearm)
			self.lscs_bone_angles.wrist = LerpAngle(ftWrist, self.lscs_bone_angles.wrist, targetWrist)

			local boneUpper = ply:LookupBone("ValveBiped.Bip01_R_UpperArm")
			if boneUpper then ply:ManipulateBoneAngles(boneUpper, self.lscs_bone_angles.shoulder) end

			local boneForearm = ply:LookupBone("ValveBiped.Bip01_R_Forearm")
			if boneForearm then ply:ManipulateBoneAngles(boneForearm, self.lscs_bone_angles.forearm) end

			local boneHand = ply:LookupBone("ValveBiped.Bip01_R_Hand")
			if boneHand then ply:ManipulateBoneAngles(boneHand, self.lscs_bone_angles.wrist) end

		-- Speed logic
		if isDef then
			if SERVER then
				if not self.OldWalkSpeed then
					self.OldWalkSpeed = ply:GetWalkSpeed()
					self.OldRunSpeed = ply:GetRunSpeed()
				end
				ply:SetWalkSpeed(80)
				ply:SetRunSpeed(80)
			end
		else
			if SERVER then
				if self.OldWalkSpeed then
					ply:SetWalkSpeed(self.OldWalkSpeed)
					ply:SetRunSpeed(self.OldRunSpeed)
					self.OldWalkSpeed = nil
					self.OldRunSpeed = nil
				end
			end
		end
	end

	if Active ~= self.OldActive then
		self.OldActive = Active

		if Active then
			self:BuildSounds()

			self:SetHoldType( self:GetCombo().HoldType )

			self:EmitSoundUnpredicted( self.CachedSounds[1].ActivateSound )

			if self:GetCombo().LeftSaberActive then
				self:EmitSoundUnpredicted( self.CachedSounds[2].ActivateSound )
			end
		else
			self:SetHoldType( "normal" )

			self:EmitSoundUnpredicted( self.CachedSounds[1].DisableSound )

			if self:GetCombo().LeftSaberActive then
				self:EmitSoundUnpredicted( self.CachedSounds[2].DisableSound )
			end
		end

		self:OnActiveChanged( self.OldActive, Active )
	end

	if Stance ~= self.OldStance then
		if self:GetActive() then
			self:SetHoldType( self:GetCombo().HoldType )
		end

		self.OldStance = Stance
	end
	
	self:OnTick( Active )
end

function SWEP:AimDistanceTo( _pos )
	local ply = self:GetOwner()

	if not IsValid( ply ) then return 0 end

	local Pos = ply:lscsGetViewOrigin()
	local EndPos = Pos + ply:EyeAngles():Forward() * 500

	return util.DistanceToLine( Pos, EndPos, _pos )
end

function SWEP:GetBlockDistanceTo( _pos )
	local ply = self:GetOwner()

	if not IsValid( ply ) then return 100 end

	local BlockDistance = self:AimDistanceTo( _pos )

	if ply:WorldToLocal( _pos ).x < 0 then
		BlockDistance = 100
	end

	return BlockDistance
end