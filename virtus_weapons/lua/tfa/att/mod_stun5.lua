if not ATTACHMENT then
	ATTACHMENT = {}
end

ATTACHMENT.Name = "Stun Charge"
ATTACHMENT.ShortName = "5s" --Abbreviation, 5 chars or less please
--ATTACHMENT.ID = "base" -- normally this is just your filename
ATTACHMENT.Description = { 
	TFA.AttachmentColors["+"],"Stunned for 5 Seconds",
}
ATTACHMENT.Icon = "entities/icon/mod_stun5.png" --Revers to label, please give it an icon though!  This should be the path to a png, like "entities/tfa_ammo_match.png"

ATTACHMENT.WeaponTable = {
	["Primary"] = { ["Tracer"] = 0,
		["AmmoConsumption"] = 10, ["NumShots"] = function() return 1 end, ["TracerCount"] = 1,
		["StatusEffect"] = "stun",
		["StatusEffectDmg"] = 5,
		["StatusEffectDur"] = 5,
		["StatusEffectParticle"] = true,
	},
}

function ATTACHMENT:Attach(wep)
	wep.CustomBulletCallbackOld = wep.CustomBulletCallbackOld or wep.CustomBulletCallback
	wep.CustomBulletCallback = function(a, tr, dmg)
		local wep = dmg:GetInflictor()
		if wep:GetStat("Primary.StatusEffect") then
			dmg:SetDamage(0) dmg:SetDamageType(DMG_SHOCK) if SERVER and tr.Entity:IsPlayer() then VirtusKnockoutPlayer(tr.Entity, wep:GetStat("Primary.StatusEffectDur") or 5) end
			--util.Effect("BGOLightning", ED_Stun, true, true)
		end
	end
end

function ATTACHMENT:Detach(wep)
	wep.CustomBulletCallback = wep.CustomBulletCallbackOld
	wep.CustomBulletCallbackOld = nil
end

if not TFA_ATTACHMENT_ISUPDATING then
	TFAUpdateAttachments()
end

