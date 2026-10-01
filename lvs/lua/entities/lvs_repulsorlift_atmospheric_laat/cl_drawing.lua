
function ENT:PreDraw()
	self:DrawDriverBTL()
	self:DrawDriverBTR()

	return true
end

function ENT:DrawDriverBTL()
	local pod = self:GetBTPodL()

	if not IsValid( pod ) then return end

	local plyL = LocalPlayer()
	local ply = pod:GetDriver()

	if not IsValid( ply ) or (ply == plyL and plyL:GetViewEntity() == plyL) then return end

	local ID = self:LookupAttachment( "L_Ball_Attachement" )
	local Muzzle = self:GetAttachment( ID )

	if not Muzzle then return end

	local _,Ang = LocalToWorld( Vector(0,0,0), Angle(-90,0,-90), Muzzle.Pos, Muzzle.Ang )

	ply:SetSequence( "drive_jeep" )
	ply:SetRenderAngles( Ang )
	ply:DrawModel()
end

function ENT:DrawDriverBTR()
	local pod = self:GetBTPodR()

	if not IsValid( pod ) then return end

	local plyL = LocalPlayer()
	local ply = pod:GetDriver()

	if not IsValid( ply ) or (ply == plyL and plyL:GetViewEntity() == plyL) then return end

	local ID = self:LookupAttachment( "R_Ball_Attachement" )
	local Muzzle = self:GetAttachment( ID )

	if not Muzzle then return end

	local _,Ang = LocalToWorld( Vector(0,0,0), Angle(-90,0,-90), Muzzle.Pos, Muzzle.Ang )

	ply:SetSequence( "drive_jeep" )
	ply:SetRenderAngles( Ang )
	ply:DrawModel()
end