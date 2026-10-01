include("shared.lua")
include("cl_attached_playermodels.lua")

function ENT:Initialize()
end

function ENT:DamageFX()
	self.nextDFX = self.nextDFX or 0

	if self.nextDFX < CurTime() then
		self.nextDFX = CurTime() + 0.05

		local HP = self:GetHP()
		local MaxHP = self:GetMaxHP()
	
		if HP > MaxHP * 0.5 then return end
		
		local effectdata = EffectData()
			effectdata:SetOrigin( self:LocalToWorld( Vector(15,3,50) ) )
			effectdata:SetEntity( self )
		util.Effect( "lvs_engine_blacksmoke", effectdata )
		
		if HP <= 1500 then
			local effectdata = EffectData()
				effectdata:SetOrigin( self:LocalToWorld( Vector(50,-50,30) ) )
				effectdata:SetNormal( self:GetUp() )
				effectdata:SetMagnitude( math.Rand(0.5,1.5) )
				effectdata:SetEntity( self )
			util.Effect( "lvs_exhaust_fire", effectdata )
			if math.random(0,45) < 3 then
				if math.random(1,2) == 1 then
					local Pos = self:LocalToWorld( Vector(0,0,20) + VectorRand() * 30 )
					local effectdata = EffectData()
						effectdata:SetOrigin( Pos )
					util.Effect( "cball_explode", effectdata, true, true )
					
					sound.Play( "ambient/energy/spark"..math.random(1,6)..".wav", Pos, 75 )
				end
			end
		end
		
		if HP <= MaxHP * 0.25 then
			local effectdata = EffectData()
				effectdata:SetOrigin( self:LocalToWorld( Vector(-20,40,46) ) )
				effectdata:SetNormal( self:GetUp() )
				effectdata:SetMagnitude( math.Rand(0.5,1.5) )
				effectdata:SetEntity( self )
			util.Effect( "lvs_exhaust_fire", effectdata )
			
			local effectdata = EffectData()
				effectdata:SetOrigin( self:LocalToWorld( Vector(-130,-35,50) ) )
				effectdata:SetNormal( -self:GetForward() )
				effectdata:SetMagnitude( math.Rand(0.5,1.5) )
				effectdata:SetEntity( self )
			util.Effect( "lvs_exhaust_fire", effectdata )
		end
	end
end

function ENT:OnFrame()
	self:AnimCabin()
	self:DamageFX()
	self:SideChargeFX()
end

local SideChargePositions = {
	Vector(-100, 44, 64),
	Vector(-105, 44, 62),
	Vector(-108, 44, 58),

	Vector(-100, -44, 64),
	Vector(-105, -44, 62),
	Vector(-108, -44, 58),
}

function ENT:SideChargeFX()
	if not self:GetSideChargeActive() then
		return
	end

	self._NextSideChargeFX =
		self._NextSideChargeFX or 0

	if CurTime() < self._NextSideChargeFX then
		return
	end

	self._NextSideChargeFX = CurTime() + 0.05

	for _, localPos in ipairs(
		SideChargePositions
	) do
		local effectData = EffectData()

		effectData:SetOrigin(
			self:LocalToWorld(localPos)
		)

		effectData:SetEntity(self)
		effectData:SetStart(localPos)

		util.Effect(
			"tx_130_charge",
			effectData
		)
	end
end

function ENT:AnimCabin()
	local Fire = self:GetBTLFire()
	if Fire ~= self.OldFireBTL then
		self.OldFireBTL = Fire
		
		if Fire then		
			self:EmitSound("LAATi_BT_FIRE")

			self.BTLLOOP = CreateSound( self, "RX_BEAM" )
			self.BTLLOOP:Play()
			
			local effectdata = EffectData()
			effectdata:SetEntity( self )
			util.Effect( "tx_130_projector", effectdata )
			else
			if self.BTLLOOP then
				self.BTLLOOP:Stop()
			end
		end
	end
end

function ENT:SoundStop()
	if self.DIST then
		self.DIST:Stop()
	end
	
	if self.ENG then
		self.ENG:Stop()
	end
	
	if self.BTLLOOP then
		self.BTLLOOP:Stop()
	end
	
	if self._ChargeSound then 
	self._ChargeSound:Stop() 
	end
	
	if self._ChargeElectroSound then 
	self._ChargeElectroSound:Stop() 
	end
end

function ENT:CalcViewOverride(ply, pos, angles, fov, pod)
	if pod == self:GetDriverSeat() then
		pos = self:LocalToWorld(
			Vector(-65, 25, 55)
		)

		return pos, angles, fov
	end

	if pod == self:GetCommanderSeat() then
		pos = self:LocalToWorld(
			Vector(-65, -25, 55)
		)

		return pos, angles, fov
	end

	return pos, angles, fov
end

function ENT:CalcViewCommander(ply, pos, angles, fov, pod)
    local view = {}

    view.origin = pos
    view.fov = fov
    view.drawviewer = true
    view.angles = angles

    if not pod:GetThirdPersonMode() then
        view.drawviewer = false
        return view
    end

    local radius = 550 + 550 * pod:GetCameraDistance()

    local target =
        view.origin
        - view.angles:Forward() * radius
        + view.angles:Up() * (radius * 0.2 + radius * pod:GetCameraHeight())

    local tr = util.TraceHull({
        start = view.origin,
        endpos = target,
        filter = function( e )
			local c = e:GetClass()
			local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "gmod_" ) and not c:StartWith( "lvs_" ) and not c:StartWith( "player" ) and not e.LVS

			return collide
		end,
        mins = Vector(-4, -4, -4),
        maxs = Vector(4, 4, 4),
    })

    view.origin = tr.HitPos

    if tr.Hit and not tr.StartSolid then
        view.origin = view.origin + tr.HitNormal * 4
    end

    return view
end

function ENT:LVSCalcView(ply, pos, ang, fov, pod)
    local viewPos, viewAng, viewFov =
        self:CalcViewOverride(ply, pos, ang, fov, pod)

    if pod == self:GetDriverSeat() then
        return self:CalcViewDriver(
            ply,
            viewPos,
            viewAng,
            viewFov,
            pod
        )
    elseif pod == self:GetCommanderSeat() then
        return self:CalcViewCommander(
            ply,
            viewPos,
            viewAng,
            viewFov,
            pod
        )
    end

    return self:CalcViewPassenger(
        ply,
        pos,
        ang,
        fov,
        pod
    )
end

function ENT:RemoveLight()
	if IsValid( self.projector ) then
		self.projector:Remove()
		self.projector = nil
	end
end

function ENT:OnRemove()
	self:SoundStop()
	
	self:RemoveLight()
end

local spotlight = Material( "effects/lvs/spotlight_projectorbeam" )
local glow_spotlight = Material( "sprites/light_glow02_add" )

function ENT:PostDraw()
	self:DrawModel()
	
	
	if self:GetBodygroup( 10 ) ~= 1 then 
		self:RemoveLight()

		return
	end

	if not IsValid( self.projector ) then
		local thelamp = ProjectedTexture()
		thelamp:SetBrightness( 20 ) 
		thelamp:SetTexture( "effects/flashlight/soft" )
		thelamp:SetColor( Color(255,255,255) ) 
		thelamp:SetEnableShadows( false ) 
		thelamp:SetFarZ( 2500 ) 
		thelamp:SetNearZ( 75 ) 
		thelamp:SetFOV( 80 )
		self.projector = thelamp
	end

	local StartPos = self:LocalToWorld( Vector(60,0,10.5) )
	local Dir = self:GetForward()

	render.SetMaterial( glow_spotlight )
	render.DrawSprite( StartPos + Dir * -10 , 220, 120, Color( 255, 255, 255, 255) )

	render.SetMaterial( spotlight )
	render.DrawBeam(  StartPos - Dir * 10,  StartPos + Dir * 800, 250, 0, 0.99, Color( 255, 255, 255, 10) ) 
	
	if IsValid( self.projector ) then
		self.projector:SetPos( StartPos )
		self.projector:SetAngles( Dir:Angle() )
		self.projector:Update()
	end
end

