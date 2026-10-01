
function ENT:ContraptionThink()
	local OnMoveableFloor = self:CheckGround()

	if not IsValid( self:GetDriver() ) and not self:GetAI() then
		self:ApproachTargetSpeed( 0 )
		self:SetTargetSteer( 0 )

		if math.abs(self:GetTargetSpeed()) < 1 and self:GetSequence() != self:LookupSequence("sitdown") then
			self:PlayAnimation("sitdown")
		end
	end

	self:CheckUpRight()
	self:CheckActive()
	self:CheckMotion( OnMoveableFloor )
end

function ENT:CheckUpRight()
	if self:GetIsCarried() or self:IsPlayerHolding() or self:AngleBetweenNormal( self:GetUp(), Vector(0,0,1) ) < 45 then return end
	
	self:BecomeRagdoll()
end

function ENT:CheckActive()
	local ShouldBeActive = not self:GetIsCarried() and not self:GetIsRagdoll()

	if ShouldBeActive ~= self:GetEngineActive() then
		self:SetEngineActive( ShouldBeActive )
	end
end

function ENT:OnLanding(velocity)
	self:SetIsJumping(false)
	self:SetProperJump(false)

	self._pVelocity = nil
	self._pAcceleration = nil

	if self:GetIsRagdoll() then return end

	local forward = self:GetForward()

	if velocity.z < -1 * self.MaxLandingUpVelocity then
		self:BecomeRagdoll()
		return
	end

	local normalizedVelocityAlignment = (velocity:Dot(forward) / (velocity:Length() * forward:Length()) + 1) / 2
	local shouldSurvive = normalizedVelocityAlignment > velocity:Length() / self.MaxLandingSideVelocity

	if not shouldSurvive then
		self:BecomeRagdoll()
		return
	end

	local angle = self:GetAngles()
	self:SetVelocity(Vector(0,0,0))
end

function ENT:ToggleGravity( PhysObj, Enable )
	if self:GetIsCarried() then Enable = false end

	if PhysObj:IsGravityEnabled() ~= Enable then
		PhysObj:EnableGravity( Enable )
	end
end

function ENT:CheckMotion( OnMoveableFloor )
	if self:GetIsRagdoll() or self:GetIsCarried() then
		if self:GetIsCarried() then self:ForceMotion() end
	
		return
	end

	local TargetSpeed = self:GetTargetSpeed()

	if not self:HitGround() or self:GetIsCarried() then
		self:SetIsMoving( false )
	else
		self:SetIsMoving( math.abs( TargetSpeed ) > 0 )
	end

	local IsHeld = self:IsPlayerHolding()

	if IsHeld then
		self:SetTargetSpeed( 200 )
	end

	if self:HitGround() and not OnMoveableFloor then
		local enable = self:GetIsMoving() or IsHeld

		for _, ent in ipairs( self:GetContraption() ) do
			if not IsValid( ent ) then continue end

			local phys = ent:GetPhysicsObject()

			if not IsValid( phys ) then continue end

			if phys:IsMotionEnabled() ~= enable then
				phys:EnableMotion( enable )
				phys:Wake()
			end
		end
	else
		local enable = self:GetIsMoving() or IsHeld or OnMoveableFloor

		for _, ent in ipairs( self:GetContraption() ) do
			if not IsValid( ent ) then continue end

			local phys = ent:GetPhysicsObject()

			if not IsValid( phys ) then continue end

			if not phys:IsMotionEnabled() then
				phys:EnableMotion( enable )
				phys:Wake()
			end
		end
	end
end

function ENT:HitGround()
	return self._HitGround == true
end

function ENT:CheckGround()
	local NumHits = 0
	local HitMoveable

	for _, ent in ipairs( self:GetContraption() ) do
		local phys = ent:GetPhysicsObject()

		if not IsValid( phys ) then continue end

		local masscenter = phys:LocalToWorld( phys:GetMassCenter() )

		local trace =  util.TraceHull( {
			start = masscenter, 
			endpos = masscenter - ent:GetUp() * self.HoverTraceLength,
			mins = Vector( -self.HoverHullRadius, -self.HoverHullRadius, 0 ),
			maxs = Vector( self.HoverHullRadius, self.HoverHullRadius, 0 ),
			filter = function( entity ) 
				if self:GetCrosshairFilterLookup()[ entity:EntIndex() ] or entity:IsPlayer() or entity:IsNPC() or entity:IsVehicle() or self.HoverCollisionFilter[ entity:GetCollisionGroup() ] then
					return false
				end

				return true
			end,
		} )

		if not HitMoveable then
			if IsValid( trace.Entity ) then
				HitMoveable = self.CanMoveOn[ trace.Entity:GetClass() ]
			end
		end

		if not trace.Hit or trace.HitSky then continue end

		NumHits = NumHits + 1
	end

	self._NumGround = NumHits
	self._HitGround = NumHits == 1

	return HitMoveable == true
end

function ENT:OnIsCarried( name, old, new)
	if new == old then return end

	if new then
		self:NudgeRagdoll()
	else
		self:SetTargetSpeed( 200 )
	end
end

function ENT:PhysicsSimulate( phys, deltatime )
	phys:Wake()

	if not self:GetEngineActive() then
		self:ToggleGravity( phys, true )
		return
	end

	local base = phys:GetEntity()
	local vel = phys:GetVelocity()
	local velL = phys:WorldToLocal( phys:GetPos() + vel )

	local masscenter = phys:LocalToWorld( phys:GetMassCenter() )

	local forward, right = self:GetAlignment( base, phys )
	local up = base:GetUp()

	local tracedata = {
		start = masscenter, 
		endpos = masscenter - up * self.HoverTraceLength,
		mins = Vector( -self.HoverHullRadius, -self.HoverHullRadius, 0 ),
		maxs = Vector( self.HoverHullRadius, self.HoverHullRadius, 0 ),
		filter = function( entity )
			if self:GetCrosshairFilterLookup()[ entity:EntIndex() ] or entity:IsPlayer() or entity:IsNPC() or entity:IsVehicle() or self.HoverCollisionFilter[ entity:GetCollisionGroup() ] then
				return false
			end

			return true
		end,
	}

	local trace = util.TraceHull( tracedata )
	local traceLine = util.TraceLine( tracedata )

	local OnGround = (trace.Hit or traceLine.hit) and not trace.HitSky and not traceLine.HitSky
	local isJumping = self:GetIsJumping()

	self:ToggleGravity( phys, isJumping )

	local Pos = trace.HitPos
	if traceLine.Hit then
		Pos = traceLine.HitPos
	end

	local CurDist = (Pos - masscenter):Length()

	local X, Y = self:GetMoveXY( base, phys )
	local Z = Vector(0, 0, -50000)

	if not isJumping and CurDist > 150 then
		self:SetLastJump(CurTime())
		self:SetIsJumping(true)
		isJumping = true
	end

	if isJumping and CurDist < 70 and self:GetLastJump() + 0.1 < CurTime() then
		self:OnLanding(self:GetVelocity())
	end

	if not isJumping then
		Z = ((self:GetHoverHeight( base, phys ) - CurDist) * 3 - velL.z * 0.5) * 3
	end

	local ForceLinear = Vector(X,Y,Z) * 2000 * deltatime * self.ForceLinearMultiplier

	local Normal = self:TransformNormal( base, trace.HitNormal )

	local Pitch = self:AngleBetweenNormal( Normal, forward ) - 90
	local Roll = self:AngleBetweenNormal( Normal, right ) - 90

	local GroundAngle = Vector(-Roll,-Pitch, self:GetSteer( base, phys ) )
	local AirAngle = Vector(0, 0, self:GetSteer( base, phys ) )

	local GroundDistRatio = math.Clamp(CurDist / 400, 0, 1)

	local ForceAngle = ( LerpVector(GroundDistRatio, GroundAngle, AirAngle) * 12 * self.ForceAngleMultiplier - phys:GetAngleVelocity() * self.ForceAngleDampingMultiplier) * 400 * deltatime

	local SIMULATE = (OnGround or isJumping) and SIM_LOCAL_ACCELERATION or SIM_NOTHING

	if isJumping then ForceLinear =	Vector(0, 0, 0) end

	return ForceAngle, ForceLinear, SIMULATE
end