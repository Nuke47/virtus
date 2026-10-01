function CH_ADVArrest.DrawWeaponSelection( element )
	local ply = LocalPlayer()
	if IsValid( ply ) then
		if ply:GetNWBool( "CH_ADVARREST_Handcuffed" ) and element == "CHudWeaponSelection" then
			return false
		end
	end
end
hook.Add( "HUDShouldDraw", "CH_ADVArrest.DrawWeaponSelection", CH_ADVArrest.DrawWeaponSelection )

function CH_ADVArrest.DrawHandcuffed()
	local ply = LocalPlayer()
	
	for k, v in ipairs( player.GetAll() ) do
		if ply != v and v:Alive() then
			if ply:GetPos():DistToSqr( v:GetPos() ) > 160000 then
				return
			end
			
			local VPos = v:GetPos() + Vector( 0, 0, 64 )

			local ScrPos = ( VPos + Vector( 0, 0, 10 )):ToScreen()
			
			local thetrace = {}
			thetrace.start = ply:GetPos() + Vector( 0, 0, 64 )
			thetrace.endpos = VPos
			thetrace.filter = {ply, v}
		
			local tr = util.TraceLine( thetrace )

			if not tr.Hit then
				local alp = 255
			
				local flash_col = Color( 190 * math.abs( math.sin( CurTime() * 1.5 ) ), 0, 0, 255 )

				if ply:CH_ADVARREST_IsAuthorizedToArrest() then
					if v:GetNWBool( "CH_ADVARREST_Handcuffed" ) then
						draw.SimpleTextOutlined( CH_ADVArrest.Config.Lang["Player Handcuffed"][CH_ADVArrest.Config.Language], "ADVARREST_Font_JailMenu", ScrPos.x, ScrPos.y - 65, flash_col, 1, 1, 1, color_black )
					end
				end	
			end
		end
	end
end
hook.Add( "HUDDrawTargetID", "CH_ADVArrest.DrawHandcuffed", CH_ADVArrest.DrawHandcuffed )