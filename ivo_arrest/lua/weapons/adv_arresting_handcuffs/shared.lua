--[[ INFO
#Handcuffs
models/craphead_scripts/ocrp2/props_meow/weapons/c_handcuffs.mdl
models/craphead_scripts/ocrp2/props_meow/weapons/w_handcuffs.mdl
FOV: 80
Hold type: pistol/normal/slam
Sequences:
(sequence_name       activity)
idle 		ACT_IDLE
arrest 		ACT_VM_PRIMARYATTACK
handcuff 	ACT_VM_SECONDARYATTACK
draw 		ACT_VM_DRAW
--]]

if SERVER then
	AddCSLuaFile( "shared.lua" )
end

if CLIENT then
	SWEP.PrintName = "Handcuffs"
	SWEP.Slot = 1
	SWEP.SlotPos = 3
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = true
end

SWEP.Author = "Crap-Head"
SWEP.Instructions = CH_ADVArrest.Config.Lang["Left click to arrest or unarrest a handcuffed target.\nRight click to handcuff your target.\nReload to open player inspection menu."][CH_ADVArrest.Config.Language]
SWEP.Contact = ""
SWEP.Purpose = CH_ADVArrest.Config.Lang["Used to arrest, unarrest, handcuff and inspect players."][CH_ADVArrest.Config.Language]

SWEP.UseHands = true
SWEP.ViewModelFOV = 80
SWEP.ViewModelFlip = false
SWEP.AnimPrefix = "stunstick"

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Category = "Crap-Head Scripts"

SWEP.NextStrike = 0

SWEP.ViewModel = "models/craphead_scripts/ocrp2/props_meow/weapons/c_handcuffs.mdl"
SWEP.WorldModel = "models/craphead_scripts/ocrp2/props_meow/weapons/w_handcuffs.mdl"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

function SWEP:SetupDataTables()
	self:NetworkVar( "Float" , 0 , "NextIdle" )
end

function SWEP:Initialize()
	self:SetWeaponHoldType( "melee" )
	
	self:SetNextIdle( 0 )

	return true
end

function SWEP:Deploy()
	local cur_time = CurTime()
	
	self:SendWeaponAnim( ACT_VM_DRAW )
	self:SetNextIdle( cur_time + self:SequenceDuration() )
	
	-- Do delay
	self:SetNextPrimaryFire( cur_time + self:SequenceDuration() )
	self:SetNextSecondaryFire( cur_time + self:SequenceDuration() )
	
	return true
end

function SWEP:PrimaryAttack()
	local cur_time = CurTime()
	local arrester = self:GetOwner()
	local tr = util.TraceHull({
		start = arrester:GetShootPos(),
		endpos = arrester:GetShootPos() + (arrester:GetAimVector() * CH_ADVArrest.Config.ArrestDistance),
		filter = arrester,
		mins = Vector(-15, -15, -15),
		maxs = Vector(15, 15, 15),
		mask = MASK_SHOT_HULL
	})
	local target = tr.Entity
	
	self:SetNextPrimaryFire( cur_time + self:SequenceDuration() )
	self:SetNextSecondaryFire( cur_time + self:SequenceDuration() )
	
	if not IsValid(target) or not target:IsPlayer() then
		if SERVER then
			DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["You need to be aiming at a player."][CH_ADVArrest.Config.Language] )
		end
		return
	end
	
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	self:SetNextIdle( cur_time + self:SequenceDuration() )
	arrester:SetAnimation( PLAYER_ATTACK1 )
	
	if SERVER then
		if not target:getDarkRPVar("Arrested") then -- Player is not arrested
			if target:GetNWBool( "CH_ADVARREST_Handcuffed" ) then
				if arrester.CH_ADVArrest_Dragging == target then
					arrester.CH_ADVArrest_Dragging = nil
					target:SetNWEntity("CH_ADVARREST_DraggedBy", NULL)
					DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, "Has soltado a " .. target:Nick() .. "." )
				else
					arrester.CH_ADVArrest_Dragging = target
					target:SetNWEntity("CH_ADVARREST_DraggedBy", arrester)
					DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, "Estás arrastrando a " .. target:Nick() .. "." )
				end
			else
				DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["You need to handcuff the player before you can arrest them."][CH_ADVArrest.Config.Language] )
			end
		else -- Player is arrested, unarresting code here
			self:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
			target:unArrest( arrester )
			DarkRP.notify( target, 0, CH_ADVArrest.Config.NotificationTime, DarkRP.getPhrase("youre_unarrested_by", arrester:Nick() ) )

			if arrester.SteamName then
				DarkRP.log( arrester:Nick() .. " (" .. arrester:SteamID() .. ") unarrested " .. target:Nick(), Color(0, 255, 255) )
			end
		end
	end
end

function SWEP:SecondaryAttack()
	local cur_time = CurTime()
	local arrester = self:GetOwner()
	local tr = util.TraceHull({
		start = arrester:GetShootPos(),
		endpos = arrester:GetShootPos() + (arrester:GetAimVector() * CH_ADVArrest.Config.ArrestDistance),
		filter = arrester,
		mins = Vector(-15, -15, -15),
		maxs = Vector(15, 15, 15),
		mask = MASK_SHOT_HULL
	})
	local target = tr.Entity
	
	self:SetNextPrimaryFire( cur_time + self:SequenceDuration() )
	self:SetNextSecondaryFire( cur_time + self:SequenceDuration() )
	
	if not IsValid(target) or not target:IsPlayer() then
		if SERVER then
			DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["You need to be aiming at a player."][CH_ADVArrest.Config.Language] )
		end
		return
	end
	
	self:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
	self:SetNextIdle( cur_time + self:SequenceDuration() )
	arrester:SetAnimation( PLAYER_ATTACK1 )

	if SERVER then
		if target:GetClass() == "prop_ragdoll" and not IsValid( target ) then
			return
		end
		
		if target:GetClass() == "prop_ragdoll" and IsValid( target ) then
			DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["You've handcuffed"][CH_ADVArrest.Config.Language] .." ".. target:Nick()..".")
			target:SetNWBool( "CH_ADVARREST_Handcuffed", true )
			target:SetWalkSpeed( CH_ADVArrest.Config.ArrestedWalkSpeed )
			target:SetRunSpeed( CH_ADVArrest.Config.ArrestedRunSpeed )
		else
			if target:isArrested() then
				DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, target:Nick().." ".. CH_ADVArrest.Config.Lang["is arrested. Left click to unarrest them!"][CH_ADVArrest.Config.Language] )
				return
			end
			
			if target:GetNWBool( "CH_ADVARREST_Handcuffed" ) then
				target:SetNWBool( "CH_ADVARREST_Handcuffed", false )
				CH_ADVArrest.SetHandcuffedBones(target, false)
				DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, target:Nick().." ".. CH_ADVArrest.Config.Lang["has been released from their handcuffs."][CH_ADVArrest.Config.Language] )
				target:SetWalkSpeed( GAMEMODE.Config.walkspeed )
				target:SetRunSpeed( GAMEMODE.Config.runspeed )
				return
			else
				-- Handcuff instantáneamente
				local canArrest, message = hook.Call( "canArrest", DarkRP.hooks, arrester, target )
				if not canArrest then
					if message then DarkRP.notify( arrester, 1, 5, message ) end
					return
				end
				
				DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["You've handcuffed"][CH_ADVArrest.Config.Language] .." ".. target:Nick()..".")
				target:SelectWeapon( CH_ADVArrest.Config.WeaponSwitchedHandcuffed ) 
				target:SetNWBool( "CH_ADVARREST_Handcuffed", true )
				CH_ADVArrest.SetHandcuffedBones(target, true)
				target:SetWalkSpeed( CH_ADVArrest.Config.ArrestedWalkSpeed )
				target:SetRunSpeed( CH_ADVArrest.Config.ArrestedRunSpeed )
			end
		end	
	end
end

function SWEP:Reload()
	local cur_time = CurTime()
	local arrester = self:GetOwner()
	local tr = util.TraceHull({
		start = arrester:GetShootPos(),
		endpos = arrester:GetShootPos() + (arrester:GetAimVector() * CH_ADVArrest.Config.ArrestDistance),
		filter = arrester,
		mins = Vector(-15, -15, -15),
		maxs = Vector(15, 15, 15),
		mask = MASK_SHOT_HULL
	})
	local target = tr.Entity
	
	self:SetNextPrimaryFire( cur_time + 0.5 )
	self:SetNextSecondaryFire( cur_time + 0.5 )
	
	if ( self.CurDelay or 0 ) > cur_time then
		return
	end
	
	self.CurDelay = cur_time + 2

	if not IsValid(target) or not target:IsPlayer() then
		if SERVER then
			DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["You need to be aiming at a player."][CH_ADVArrest.Config.Language] )
		end
		return
	end
	
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	self:SetNextIdle( cur_time + self:SequenceDuration() )
	arrester:SetAnimation( PLAYER_ATTACK1 )
	
	if SERVER then
		-- Player is already arrested 76561198379569886
		if target:getDarkRPVar( "Arrested" ) then
			return
		end
		
		if target:GetNWBool( "CH_ADVARREST_Handcuffed" ) then
			DarkRP.notify( target, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["An officer is inspecting your belongings. Please do what the officer says to avoid any conflicts."][CH_ADVArrest.Config.Language] )
			
			net.Start( "CH_AdvArrest_InspectPlayersMenu" )
				net.WriteEntity( target )
				-- Send custom inventory
				local targetInv = target.CustomInventory or {}
				net.WriteUInt(table.Count(targetInv), 16)
				for k, v in ipairs(targetInv) do
					net.WriteString(v.class or "")
					net.WriteString(v.name or "")
					net.WriteString(v.model or "")
					net.WriteUInt(v.amount or 1, 16)
				end
			net.Send( arrester )
		else
			DarkRP.notify( arrester, 1, CH_ADVArrest.Config.NotificationTime, CH_ADVArrest.Config.Lang["You need to handcuff the player before you can inspect them."][CH_ADVArrest.Config.Language] )
		end
	end
end

function SWEP:Think()
	local arrester = self:GetOwner()
	local tr = arrester:GetEyeTrace()
	
	if not tr.Entity:IsPlayer() then 
		return 
	end
	
	local Dist = arrester:EyePos():DistToSqr( tr.HitPos )
	if Dist > CH_ADVArrest.Config.ArrestDistance then 
		return
	end
end

if CLIENT then
	local bg_stripes = Material( "craphead_scripts/adv_arresting/bg_stripes.png" )
	local color_gms_blue = Color( 52, 152, 219, 255 )
	
	function SWEP:DrawHUD()
		-- Timer interface removed
	end
end

function SWEP:Think()
	-- Used to reset idle animation for deployment and primaryattack
	if self:GetNextIdle() ~= 0 and self:GetNextIdle() < CurTime() then
		self:SendWeaponAnim( ACT_IDLE )
		self:SetNextIdle( 0 )
	end
end

local mat_crosshair = Material( "craphead_scripts/adv_arresting/close.png", "noclamp smooth" )

function SWEP:DoDrawCrosshair( x, y )
	local size = 16

	surface.SetDrawColor( color_white )
	surface.SetMaterial( mat_crosshair )
	surface.DrawTexturedRect( x - 8, y - 8, size, size )
	return true
end