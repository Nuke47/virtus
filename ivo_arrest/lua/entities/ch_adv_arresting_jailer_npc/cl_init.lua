include( "shared.lua" )

function ENT:DrawTranslucent()
	self:DrawModel()
	
	if LocalPlayer():GetPos():DistToSqr( self:GetPos() ) > 750000 then
		return
	end

	local Ang = self:GetAngles()
	local EyeAng = LocalPlayer():EyeAngles()

	Ang:RotateAroundAxis( Ang:Forward(), 90 )
	Ang:RotateAroundAxis( Ang:Right(), -90 )

	cam.Start3D2D( self:GetPos() + self:GetUp() * 76, Angle( 0, EyeAng.y - 90, 90 ), 0.03 )
		draw.SimpleTextOutlined( CH_ADVArrest.Config.Lang["Jailer"][CH_ADVArrest.Config.Language], "ADVARREST_Font_JailNPC", 0, -40, CH_ADVArrest.Config.NPCTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, CH_ADVArrest.Config.NPCTextColorOutline )
		draw.SimpleTextOutlined( CH_ADVArrest.Config.Lang["Bring criminals here to arrest them"][CH_ADVArrest.Config.Language], "ADVARREST_Font_JailNPCSmall", 0, 40, CH_ADVArrest.Config.NPCTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, CH_ADVArrest.Config.NPCTextColorOutline )
	cam.End3D2D()
end