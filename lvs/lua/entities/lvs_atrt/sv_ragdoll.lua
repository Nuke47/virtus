
function ENT:UnRagdoll()
	if not self.Constrainer then return end

	self:SetAngles(Angle(0, 0, 0))

	self:SetTargetSpeed( 200 )
	self:SetIsRagdoll( false )

	self:SetIsSitting(false)
	self:PlayAnimation( "idle" )

	self.Constrainer = nil

	self.DoNotDuplicate = false
end

function ENT:BecomeRagdoll()
	if self.Constrainer then return end

	self.Constrainer = {[0] = self}

	self:SetIsRagdoll( true )
	self:ForceMotion()

	self.DoNotDuplicate = true

	if self:GetSequence() != self:LookupSequence("sitdown") then
		self:PlayAnimation( "sitdown" )
	end 
end

function ENT:NudgeRagdoll()
	if not istable( self.Constrainer ) then return end

	for _, ent in pairs( self.Constrainer ) do
		if not IsValid( ent ) or ent == self then continue end

		local PhysObj = ent:GetPhysicsObject()

		if not IsValid( PhysObj ) then continue end

		PhysObj:EnableMotion( false )

		ent:SetPos( ent:GetPos() + self:GetUp() * 100 )

		timer.Simple( FrameTime() * 2, function()
			if not IsValid( ent ) then return end

			local PhysObj = ent:GetPhysicsObject()
			if IsValid( PhysObj ) then
				PhysObj:EnableMotion( true )
			end
		end)
	end
end

function ENT:ForceMotion()
	for _, ent in ipairs( self:GetContraption() ) do
		if not IsValid( ent ) then continue end

		local phys = ent:GetPhysicsObject()

		if not IsValid( phys ) then continue end

		if not phys:IsMotionEnabled() then
			phys:EnableMotion( true )
		end
	end
end