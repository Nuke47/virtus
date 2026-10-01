
function ENT:CalcViewDriver( ply, pos, angles, fov, pod )
	local view = {}
	view.origin = pos
	view.angles = angles
	view.fov = fov
	view.drawviewer = false

	-- pos is not consistent, not sure why. calculate pos based on vehicle instead
	view.origin = self:LocalToWorld( self:OBBCenter() ) + self:GetUp() * 60

	if not pod:GetThirdPersonMode() then return view end

	local mn = self:OBBMins()
	local mx = self:OBBMaxs()
	local radius = ( mn - mx ):Length()
	local radius = radius + radius * pod:GetCameraDistance()

	local clamped_angles = pod:WorldToLocalAngles( angles )
	clamped_angles.p = math.max( clamped_angles.p, -20 )
	clamped_angles = pod:LocalToWorldAngles( clamped_angles )

	local StartPos = self:LocalToWorld( self:OBBCenter() ) + clamped_angles:Up() * 40
	local EndPos = StartPos - clamped_angles:Forward() * radius + clamped_angles:Up() * (radius * 0.2 + radius * pod:GetCameraHeight())

	local WallOffset = 4

	local tr = util.TraceHull( {
		start = StartPos,
		endpos = EndPos,
		filter = function( e )
			local c = e:GetClass()
			local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "gmod_" ) and not c:StartWith( "lvs_" ) and not c:StartWith( "player" ) and not e.LVS

			return collide
		end,
		mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
		maxs = Vector( WallOffset, WallOffset, WallOffset ),
	} )

	view.angles = angles + Angle(5,0,0)
	view.origin = tr.HitPos
	view.drawviewer = true

	if tr.Hit and  not tr.StartSolid then
		view.origin = view.origin + tr.HitNormal * WallOffset
	end

	return view
end

function ENT:LVSCalcView( ply, pos, angles, fov, pod )
	if self:GetIsChargingJump() then
		self.FOVModifier = self.FOVModifier or 1

		self.FOVModifier = math.Approach( self.FOVModifier, 0.95, FrameTime() * 0.05 / self.JumpChargeTime )

		fov = fov * self.FOVModifier
	else
		self.FOVModifier = 1
	end
	
	if self:GetDriver() == ply then
		return self:CalcViewDriver( ply, pos, angles, fov, pod )
	end
end