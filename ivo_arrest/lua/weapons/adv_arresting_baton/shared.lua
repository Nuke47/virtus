--[[ INFO
#Police Baton
models/craphead_scripts/ocrp2/props_meow/weapons/c_policebaton.mdl
models/craphead_scripts/ocrp2/props_meow/weapons/w_policebaton.mdl
FOV: 90
Hold type: melee
Sequences:
(sequence_name       activity)
idle 		ACT_IDLE
attack 		ACT_VM_HITCENTER
draw 		ACT_VM_DRAW
--]]

if SERVER then
	AddCSLuaFile( "shared.lua" )
end

if CLIENT then
	SWEP.PrintName			= "Police Baton"
	SWEP.Slot = 2
	SWEP.SlotPos = 1
	SWEP.DrawAmmo			= false
	SWEP.DrawCrosshair		= true
end

SWEP.Author = "Crap-Head"
SWEP.Instructions = CH_ADVArrest.Config.Lang["Left Click: Hit using the baton"][CH_ADVArrest.Config.Language]

SWEP.ViewModelFOV	= 90
SWEP.ViewModel		= "models/craphead_scripts/ocrp2/props_meow/weapons/c_policebaton.mdl"
SWEP.WorldModel		= "models/craphead_scripts/ocrp2/props_meow/weapons/w_policebaton.mdl" 

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Category = "Crap-Head Scripts"

SWEP.UseHands 			= true
SWEP.ViewModelFlip      = false
SWEP.AnimPrefix  		= "stunstick"

SWEP.Primary.Range			= 90
SWEP.Primary.Recoil			= 4.6
SWEP.Primary.Damage			= 2
SWEP.Primary.Cone			= 0.02
SWEP.Primary.NumShots		= 1

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false	
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

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
	
	self:SetNextPrimaryFire( cur_time + CH_ADVArrest.Config.BatonHitDelay )
	self:SetNextSecondaryFire( cur_time + CH_ADVArrest.Config.BatonHitDelay )
	
	local ply = self:GetOwner()
 	local trace = util.GetPlayerTrace( ply )
 	local tr = util.TraceLine( trace )
	local target = tr.Entity
	
	self:EmitSound( "weapons/stunstick/stunstick_swing1.wav", 100, math.random( 90, 120 ) )
	
	self:SendWeaponAnim( ACT_VM_HITCENTER )
	self:SetNextIdle( cur_time + self:SequenceDuration() )
	ply:SetAnimation( PLAYER_ATTACK1 )

	if ( ply:GetPos() - tr.HitPos ):Length() < self.Primary.Range then
		ply:ViewPunch( Angle( math.random( -1, 1 ) * self.Primary.Recoil, math.random( -1, 1 ) * self.Primary.Recoil, 0 ) )
		if tr.HitNonWorld then
			if SERVER then 
				if target:IsPlayer() then
					target:TakeDamage( CH_ADVArrest.Config.BatonDamage, ply ) 
					target:SetVelocity( ply:GetAngles():Forward() * 50 + ply:GetAngles():Up() * 10 )
				elseif target:GetClass() != "prop_vehicle_jeep" and not target:IsNPC() then
					target:TakeDamage( 5, ply ) 
				end
			end				

			if target:IsPlayer() then
				self:EmitSound( "physics/body/body_medium_impact_hard1.wav", 100, math.random( 95, 110 ) )
			elseif target:GetClass() != "prop_vehicle_jeep" and not target:IsNPC()  then
				self:EmitSound( "physics/body/body_medium_impact_hard1.wav", 100, math.random( 95, 110 ) )
				local phys = target:GetPhysicsObject()
				
				if phys and IsValid( phys ) then
					phys:ApplyForceCenter( ply:GetAimVector() * 120 )
				end
			end
		else
			self:EmitSound( "physics/body/body_medium_impact_hard1.wav", 100, math.random(95,110) )
		end
	end
end

function SWEP:SecondaryAttack()
	self:PrimaryAttack()
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