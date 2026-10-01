include("shared.lua")
include( "cl_camera.lua" )
include( "cl_prediction.lua" )

function ENT:DamageFX()
	self.nextDFX = self.nextDFX or 0

	if self.nextDFX < CurTime() then
	self.nextDFX = CurTime() + 0.05

	if self:GetIsRagdoll() then
		if math.random(0,45) < 3 then
	 			if math.random(1,2) == 1 then
	 				local Pos = self:LocalToWorld( Vector(0,0,40) + VectorRand() * 50 )
	 				local effectdata = EffectData()
	 					effectdata:SetOrigin( Pos )
	 				util.Effect( "cball_explode", effectdata, true, true )
					
	 				sound.Play( "lvs/vehicles/atte/spark"..math.random(1,4)..".ogg", Pos, 75 )
	 			end
	 		end
	 	end

	 	local HP = self:GetHP()
	 	local MaxHP = self:GetMaxHP()

	 	if HP > MaxHP * 0.5 then return end

	 	local effectdata = EffectData()
	 		effectdata:SetOrigin( self:LocalToWorld( Vector(0,0,40) ) )
	 		effectdata:SetEntity( self )
	 	util.Effect( "lvs_engine_blacksmoke", effectdata )

	 	if HP <= MaxHP * 0.25 then
	 		local effectdata = EffectData()
	 			effectdata:SetOrigin( self:LocalToWorld( Vector(-20,0,40) ) )
	 			effectdata:SetNormal( self:GetUp() )
	 			effectdata:SetMagnitude( math.Rand(1,3) )
	 			effectdata:SetEntity( self )
	 		util.Effect( "lvs_exhaust_fire", effectdata )
	 	end
	end
end

function ENT:OnJump()
	local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
	util.Effect( "lvs_walker_stomp", effectdata )

	sound.Play( Sound( "lvs/vehicles/atte/stomp"..math.random(1,4).."_light.ogg" ), self:GetPos(), SNDLVL_70dB)
end

function ENT:OnFrame()
	self:DamageFX()
	self:DrawDriver()

	self.jumpPrevFrame = self.jumpPrevFrame or false
	if self:GetIsJumping() and not self.jumpPrevFrame and self:GetProperJump() then
		self:OnJump()
	end
	self.jumpPrevFrame = self:GetIsJumping()
end

function ENT:DrawDriver()
	local pod = self:GetDriverSeat()

	if not IsValid( pod ) then return end

	local ply = pod:GetDriver()

	if not IsValid( ply ) or (ply == plyL and plyL:GetViewEntity() == plyL and not pod:GetThirdPersonMode()) then return end

	local ID = self:LookupAttachment( "driver" )
	local Att = self:GetAttachment( ID )

	if not Att then return end

	local _,Ang = LocalToWorld( self:GetPos(), Angle(0,90,0), Att.Pos, Att.Ang )

	local PosL = self:WorldToLocal( Att.Pos + Att.Ang:Right() * 5 - Att.Ang:Up() * 7 )
	pod:SetLocalPos( PosL )

	ply:SetSequence( "drive_jeep" )
	ply:SetRenderAngles( Ang )
	ply:DrawModel()
end

local zoom = 0
local zoom_mat = Material( "vgui/zoom" )

local white = Color(255,255,255,255)
local red = Color(255,0,0,255)

function ENT:PaintZoom( X, Y, ply )
	local TargetZoom = ply:lvsKeyDown( "ZOOM" ) and 1 or 0

	zoom = zoom + (TargetZoom - zoom) * RealFrameTime() * 10

	X = X * 0.5
	Y = Y * 0.5

	surface.SetDrawColor( Color(255,255,255,255 * zoom) )
	surface.SetMaterial(zoom_mat ) 
	surface.DrawTexturedRectRotated( X + X * 0.5, Y * 0.5, X, Y, 0 )
	surface.DrawTexturedRectRotated( X + X * 0.5, Y + Y * 0.5, Y, X, 270 )
	surface.DrawTexturedRectRotated( X * 0.5, Y * 0.5, Y, X, 90 )
	surface.DrawTexturedRectRotated( X * 0.5, Y + Y * 0.5, X, Y, 180 )
end

function ENT:LVSHudPaint( X, Y, ply )
	if self:GetIsCarried() then return end

	local Pos2D = self:GetEyeTrace().HitPos:ToScreen()

	local _,_, InRange = self:GetMainAimAngles()

	local Col = InRange and white or red

	self:PaintCrosshairCenter( Pos2D, Col )
	self:PaintCrosshairOuter( Pos2D, Col )
	self:LVSPaintHitMarker( Pos2D )

	self:PaintZoom( X, Y, ply )
end

ENT.IconEngine = Material( "lvs/engine.png" )

function ENT:LVSHudPaintInfoText( X, Y, W, H, ScrX, ScrY, ply )
	local Vel = self:GetVelocity():Length()
	local kmh = math.Round(Vel * 0.09144,0)

	draw.DrawText( "km/h ", "LVS_FONT", X + 72, Y + 35, color_white, TEXT_ALIGN_RIGHT )
	draw.DrawText( kmh, "LVS_FONT_HUD_LARGE", X + 72, Y + 20, color_white, TEXT_ALIGN_LEFT )

	if ply ~= self:GetDriver() then return end

	local hX = X + W - H * 0.5
	local hY = Y + H * 0.25 + H * 0.25

	surface.SetMaterial( self.IconEngine )
	surface.SetDrawColor( 0, 0, 0, 200 )
	surface.DrawTexturedRectRotated( hX + 4, hY + 1, H * 0.5, H * 0.5, 0 )
	surface.SetDrawColor( color_white )
	surface.DrawTexturedRectRotated( hX + 2, hY - 1, H * 0.5, H * 0.5, 0 )

	if self:GetIsCarried() then
		draw.SimpleText( "X" , "LVS_FONT",  hX, hY, Color(0,0,0,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	else
		local Throttle = Vel / 150
		self:LVSDrawCircle( hX, hY, H * 0.35, math.min( Throttle, 1 ) )
	end
end
