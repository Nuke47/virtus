
function ENT:TransformNormal( ent, Normal )
	ent.smNormal = ent.smNormal and ent.smNormal + (Normal - ent.smNormal) * FrameTime() * 2 or Normal

	return ent.smNormal
end

function ENT:SetTargetSteer( num )
	self._TargetSteer = num
end

function ENT:SetTargetSpeed( num )
	self._TargetVel = num
end

function ENT:GetTargetSpeed()
	local TargetSpeed = (self._TargetVel or 0)

	return TargetSpeed
end

function ENT:GetTargetSteer()
	return (self._TargetSteer or 0)
end

function ENT:ApproachTargetSpeed( MoveX )
	local Cur = self:GetTargetSpeed()
	local New = Cur + (MoveX - Cur) * FrameTime() * 3
	self:SetTargetSpeed( New )
end

function ENT:CalcThrottle( ply, cmd )
	if self:GetIsJumping() then return end

	local MoveSpeed = cmd:KeyDown( IN_SPEED ) and 600 or 200
	local MoveX = (cmd:KeyDown( IN_FORWARD ) and MoveSpeed or 0) + (cmd:KeyDown( IN_BACK ) and -MoveSpeed * 0.5 or 0)

	if self:GetIsChargingJump() then
		MoveX = 0
	end

	self:ApproachTargetSpeed( MoveX )
end

function ENT:CalcSteer( ply, cmd )
	if self:GetIsJumping() then 
		self:SetTargetSteer(0)
		return
	end

	local KeyLeft = cmd:KeyDown( IN_MOVELEFT )
	local KeyRight = cmd:KeyDown( IN_MOVERIGHT )
	local Steer = ((KeyLeft and 1 or 0) - (KeyRight and 1 or 0)) * 0.2 * math.abs( self:GetTargetSpeed() )

	if self:GetTargetSpeed() < 0 then
		Steer = -Steer
	end

	local Cur = self:GetTargetSteer()
	local RotateSpeed = cmd:KeyDown( IN_SPEED ) and 7.5 or 5
	local New = Cur + (Steer - Cur) * FrameTime() * RotateSpeed

	self:SetTargetSteer( New )
end

function ENT:CalcJump(ply, cmd)
	if not self:GetEngineActive() or self:GetIsJumping() or self:GetLastJump() + self.JumpDelay > CurTime() then return end

	local KeyJump = cmd:KeyDown( IN_JUMP )

	self.JumpChargeStart = self.JumpChargeStart or 0
	local timeSinceCharge = CurTime() - self.JumpChargeStart

	-- no longer holding button, do the jump 
	if self:GetIsChargingJump() and not KeyJump then 
		self:SetIsChargingJump(false)
		self:SetLastJump(CurTime())

		self:SetIsJumping(true)
		self:SetProperJump(true)

		local phys = self:GetPhysicsObject()
		local plyDirection = ply:GetAimVector()
		local vehicleDirection = self:GetUp() + self:GetForward()
		local speed = self:GetTargetSpeed()

		local jumpForce = vehicleDirection

		if timeSinceCharge < 0.2 then
			jumpForce = jumpForce * ((speed * 0.5 / 600) + 0.5)
		else
			local chargeAmount = math.Clamp(timeSinceCharge / self.JumpChargeTime, 0, 1) * 2.5
			jumpForce = jumpForce * chargeAmount
		end

		self:GetPhysicsObject():ApplyForceCenter(jumpForce * self.JumpForce)

		self:SetSequence(self:LookupSequence( "idle" ))
		self:SetPlaybackRate(0)

		return 
	end

	if self:GetIsChargingJump() and KeyJump and timeSinceCharge > 0.2 and self:GetSequence() != self:LookupSequence("sitdown") then
		self:PlayAnimation( "sitdown", 0.2 * self.JumpChargeTime )
		self:SetCycle(0)
	end

	-- starting to hold button
	if not self:GetIsChargingJump() and KeyJump then
		self.JumpChargeStart = CurTime()
		self:SetIsChargingJump(true)
		return
	end
end

function ENT:StartCommand( ply, cmd )
	if self:GetDriver() ~= ply then return end

	self:CalcThrottle( ply, cmd )
	self:CalcSteer( ply, cmd )
	self:CalcJump( ply, cmd )
end

function ENT:GetHoverHeight(ent, phys)
	if self:GetIsJumping() then return 
		self.HoverHeight * 10
	end

	return self.HoverHeight
end

function ENT:CalcMove( speed )
	self:SetMove( self:GetMove() + speed * 0.027 )

	local Move = self:GetMove()

	if Move > 360 then
		self:SetMove( Move - 360 )
	end

	if Move < -360 then
		self:SetMove( Move + 360 )
	end
end

function ENT:GetMoveXY( ent, phys, deltatime )
	local VelL = ent:WorldToLocal( ent:GetPos() + ent:GetVelocity() )

	local X = (self:GetTargetSpeed() - VelL.x)
	local Y = -VelL.y * 0.6

	if ent == self then self:CalcMove( VelL.x ) end

	local moveSpeed = math.abs(self:GetTargetSpeed())

	if not self:GetIsChargingJump() and moveSpeed > 1 and not self:GetIsJumping() then
		local reverse = self:GetTargetSpeed() < 0

		if (moveSpeed >= 100) then
			self:ResetSequence(self:LookupSequence("running"))
			self:SetPlaybackRate((reverse and -1 or 1) * (moveSpeed/333))
		elseif (moveSpeed >= 10) then
			self:ResetSequence(self:LookupSequence( "walking" ))
			self:SetPlaybackRate((reverse and -1 or 1) * (moveSpeed/75))
		else
			self:SetSequence(self:LookupSequence( "idle" ))
			self:SetPlaybackRate(0)
		end
	end

	if self:GetIsJumping() then
		self:SetSequence(self:LookupSequence( "idle" ))
		self:SetPlaybackRate(0)
	end

	return X, Y
end

function ENT:GetSteer( ent, phys )
	local Steer = -phys:GetAngleVelocity().z * 0.5

	if not IsValid( self:GetDriver() ) and not self:GetAI() then return Steer end

	return Steer + self:GetTargetSteer()
end
