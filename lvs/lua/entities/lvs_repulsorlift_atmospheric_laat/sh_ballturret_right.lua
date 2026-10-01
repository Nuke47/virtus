function ENT:SetPosBTR()
end

function ENT:TraceBTR()
    local ID = self:LookupAttachment( "R_Ball_Attachement" )
    local Muzzle = self:GetAttachment( ID )

    if not Muzzle then 
        return util.TraceLine({start = self:GetPos(), endpos = self:GetPos()})
    end

    local dir = -Muzzle.Ang:Forward()
    local pos = Muzzle.Pos

    local trace = util.TraceLine( {
        start = pos,
        endpos = (pos + dir * 150000),
    } )

    return trace
end

function ENT:SetPoseParameterBTR( weapon )
	if not IsValid( weapon:GetDriver() ) and not weapon:GetAI() then return end

	local Driver = weapon:GetDriver()
	local Pod = Driver:GetVehicle()
	local EyeAngles = Pod:WorldToLocalAngles( Driver:EyeAngles() )
	
	local _, LocalAng = WorldToLocal( Vector(0,0,0), EyeAngles, Vector(0,0,0), self:LocalToWorldAngles( Angle(0,90,0)  ) )
	LocalAng = LocalAng * .2

	self:SetPoseParameter("right_side_turret_z", LocalAng.p)
	self:SetPoseParameter("right_side_turret_y", -LocalAng.y)
end

function ENT:ReduceBallTurretRHeat()
	if self:GetBallTurretRHeat() <= 0 then return end
	local curtime = CurTime()
	if (self.NextReduceBallTurretRHeat or 0) >= curtime then return end
	self.NextReduceBallTurretRHeat = curtime + 0.1
	self:SetBallTurretRHeat(math.max(self:GetBallTurretRHeat() - 4, 0))
end

function ENT:UpBallTurretRHeat()
	local curtime = CurTime()
	if (self.NextUpBallTurretRHeat or 0) >= curtime then return end
	self.NextUpBallTurretRHeat = curtime + 0.1
	self:SetBallTurretRHeat(math.min(self:GetBallTurretRHeat() + 4, 100))
end

function ENT:InitWeaponBTR()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/laserbeam.png")
	weapon.Ammo = -1
	weapon.Delay = 0
	weapon.HeatRateUp = 0.25
	weapon.HeatRateDown = 0.3
	weapon.Attack = function( ent )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end
		if not base._CanUseBT then return end

		local trace = base:TraceBTR()
		if not trace then return end

		base:BallturretDamage( trace.Entity, ent:GetDriver(), trace.HitPos, (trace.HitPos - ent:GetPos()):GetNormalized() )
		base:UpBallTurretRHeat()
	end
	weapon.StartAttack = function( ent )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end
		if not base._CanUseBT then return end

		if base:GetBallTurretRHeat() >= 100 then
			base.BallTurretRSurcharged = true
			return
		end

		base:SetBTRFire( true )

		if not IsValid( base.sndBTR ) then return end

		base.sndBTR:Play()
		base.sndBTR:EmitSound( "laat_bf2/ballturret_fire.mp3", 110 )
	end
	weapon.FinishAttack = function( ent )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		base:SetBTRFire( false )

		if not IsValid( base.sndBTR ) then return end

		base.sndBTR:Stop()
	end
	weapon.OnThink = function( ent, active )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		base:SetPoseParameterBTR( ent )

		if base.BallTurretRSurcharged and base:GetBallTurretRHeat() <= 0 then
			base.BallTurretRSurcharged = false
		end

		if not base:GetBTRFire() then
			base:ReduceBallTurretRHeat()
		end

		if not ent:GetAI() then return end

		local ID = base:LookupAttachment( "R_Ball_Attachement" )
		local Muzzle = base:GetAttachment( ID )
		if not Muzzle then return end

		if ent:AngleBetweenNormal(-Muzzle.Ang:Forward(),ent:GetAimVector()) > 5 then
			ent:SetHeat( 1 )
			ent:SetOverheated( true )
		end
	end
	weapon.CalcView = function( ent, ply, pos, angles, fov, pod )
		local base = ent:GetVehicle()

		local view = {}
		view.origin = pos
		view.angles = angles
		view.fov = fov
		view.drawviewer = false

		if not IsValid( base ) then return view end

		local ID = base:LookupAttachment( "R_Ball_Attachement" )
		local Muzzle = base:GetAttachment( ID )

		if Muzzle then
			local Pos, Ang = LocalToWorld( Vector(-3,0,35), Angle(0,-180,0), Muzzle.Pos, Muzzle.Ang )
			
			view.angles = Ang
			view.origin = Pos
			view.drawviewer = false
		end

		return view
	end
	weapon.HudPaint = function( ent, X, Y, ply )
		local base = ent:GetVehicle()

		if not IsValid( base ) then return end

		local trace = base:TraceBTR()
		if not trace then return end
		
		local Pos2D = trace.HitPos:ToScreen()

		base:PaintCrosshairCenter( Pos2D, color_white )
		base:PaintCrosshairOuter( Pos2D, color_white )
		base:LVSPaintHitMarker( Pos2D )
		
		local heat = base:GetBallTurretRHeat() / 100
		if heat > 0.01 then
			local sX = 70
			local sY = 6
			local hX = X - sX * 0.5
			local hY = Y + 25
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(hX - 1, hY - 1, sX + 2, sY + 2)
			surface.SetDrawColor(150, 150, 150, 100)
			surface.DrawRect(hX, hY, sX, sY)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawRect(hX, hY, sX * math.min(heat, 1), sY)

			if heat > 1 then
				surface.SetDrawColor(255, 0, 0, 255)
				surface.DrawRect(hX + sX, hY, sX * math.min(heat - 1, 1), sY)
			end
		end
	end
	self:AddWeapon( weapon, 4 )
end
