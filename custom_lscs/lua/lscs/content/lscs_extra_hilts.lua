local hilt = {}

hilt.PrintName = "Aayla Secura"
hilt.Author = "Custom"
hilt.id = "aaylasecura"
hilt.mdl = "models/starwars/cwa/lightsabers/aaylasecura.mdl"
hilt.info = {
	ParentData = {
		["RH"] = {
			bone = "ValveBiped.Bip01_R_Hand",
			pos = Vector(4.25, -1.5, -1),
			ang = Angle(-100, 0, 10),
		},
		["LH"] = {
			bone = "ValveBiped.Bip01_L_Hand",
			pos = Vector(4.25, -1.5, 1),
			ang = Angle(8, 0, -10),
		},
	},
	GetBladePos = function( ent, swep, ply )
		if not ent.BladeID then
			ent.BladeID = ent:LookupAttachment( "primary_blade" )
			-- Fallback to a common name if attachment not found
			if ent.BladeID == 0 then ent.BladeID = ent:LookupAttachment( "blade" ) end
		end

		local att = ent:GetAttachment( ent.BladeID )

		if att then
			local blades = {
				[1] = {
					pos = att.Pos,
					dir = att.Ang:Up(),
				}
			}
			return blades
		end
		
		-- Default fallback if the model doesn't have proper attachments
		local dir = ent:GetUp()
		local pos = ent:GetPos() + dir * 1
		return { [1] = { pos = pos, dir = dir } }
	end,
}
LSCS:RegisterHilt( hilt )

-- Adi Gallia
hilt.PrintName = "Adi Gallia"
hilt.id = "adigalia"
hilt.mdl = "models/starwars/cwa/lightsabers/adigalia.mdl"
LSCS:RegisterHilt( hilt )

-- Ahsoka
hilt.PrintName = "Ahsoka Tano"
hilt.id = "ahsoka"
hilt.mdl = "models/starwars/cwa/lightsabers/ahsoka.mdl"
LSCS:RegisterHilt( hilt )

-- Byph
hilt.PrintName = "Byph"
hilt.id = "byph"
hilt.mdl = "models/starwars/cwa/lightsabers/byph.mdl"
LSCS:RegisterHilt( hilt )

-- Exile
hilt.PrintName = "The Exile"
hilt.id = "exile"
hilt.mdl = "models/starwars/cwa/lightsabers/exile.mdl"
LSCS:RegisterHilt( hilt )

-- Darksaber
hilt.PrintName = "Darksaber"
hilt.id = "darksaber"
hilt.mdl = "models/starwars/cwa/lightsabers/darksaber.mdl"
LSCS:RegisterHilt( hilt )

-- Inquisitor
hilt.PrintName = "Inquisitor"
hilt.id = "inquisitor"
hilt.mdl = "models/star/venator/inqusitor_saber.mdl"
-- The inquisitor saber is likely a staff/dual blade. Let's provide a custom info for it just in case.
hilt.info = {
	ParentData = {
		["RH"] = {
			bone = "ValveBiped.Bip01_R_Hand",
			pos = Vector(4.25, -1.5, -1),
			ang = Angle(90, 50, 0), -- Cambiado a 0, 0, 0 para probar la rotacion base
		},
		["LH"] = {
			bone = "ValveBiped.Bip01_L_Hand",
			pos = Vector(4.25, -1.5, 1),
			ang = Angle(0, 0, 0),
		},
	},
	GetBladePos = function( ent, swep, ply )
		if not ent.BladeID1 then
			ent.BladeID1 = ent:LookupAttachment( "primary_blade" )
			if ent.BladeID1 == 0 then ent.BladeID1 = ent:LookupAttachment( "blade1" ) end
			if ent.BladeID1 == 0 then ent.BladeID1 = ent:LookupAttachment( "blade" ) end
		end
		if not ent.BladeID2 then
			ent.BladeID2 = ent:LookupAttachment( "secondary_blade" )
			if ent.BladeID2 == 0 then ent.BladeID2 = ent:LookupAttachment( "blade2" ) end
		end

		local att1 = ent:GetAttachment( ent.BladeID1 )
		local att2 = ent:GetAttachment( ent.BladeID2 )

		if att1 and att2 then
			local blades = {
				[1] = {
					pos = att1.Pos,
					dir = att1.Ang:Up(),
				},
				[2] = {
					pos = att2.Pos,
					dir = att2.Ang:Up(),
				}
			}
			return blades
		elseif att1 then
			return { [1] = { pos = att1.Pos, dir = att1.Ang:Up() } }
		end
		
		-- Fallback for double blades without attachments (Inquisitor ring)
		-- Often the blades shoot out along the Forward or Right vector
		local dir = ent:GetRight()
		local pos1 = ent:GetPos() + dir * 15
		local pos2 = ent:GetPos() - dir * 15
		return { 
			[1] = { pos = pos1, dir = dir },
			[2] = { pos = pos2, dir = -dir }
		}
	end,
}
LSCS:RegisterHilt( hilt )
