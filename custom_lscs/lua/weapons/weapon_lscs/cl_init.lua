include( "shared.lua" )
include("sh_combo.lua")
include("sh_animations.lua")
include("sh_blockpoints.lua")
include( "sh_stance_override.lua" )
include("cl_worldmodel.lua")
include("cl_effects.lua")

SWEP.Slot = 0
SWEP.SlotPos = 0

language.Add( "lscsGlowstick", "Lightsaber" )

local mat_xhair = Material( "sprites/hud/v_crosshair1" )
local mat_glow = Material( "sprites/light_glow02_add" )

local COLOR_WHITE = Color( 255, 255, 255, 255 )
local VECTOR_NULL = Vector(0,0,0)

local segmentLength = 5
local segmentSpace = 10

local OldCombo
local ComboIcon = Material("entities/item_stance_yongli.png")

function SWEP:DrawHUD()
	local ply = LocalPlayer()

	if ply:InVehicle() and not ply:GetAllowWeaponsInVehicle() then return end

	local combo = self:GetCombo()

	local T = CurTime()
	local notifyTime = self:GetBlockPointNotifyTime()

	local segmentDist = segmentLength + segmentSpace

	local BlockPoints = self:GetBlockPoints()

	if combo ~= OldCombo then
		OldCombo = combo

		ComboIcon = self:GetCombo().icon
	end

	local centerX = ScrW() / 2
	local baseY = ScrH() - 155
	local barW = 400
	local barH = 6

	if not LSCS:HUDShouldHide( LSCS_HUD_POINTS_ADVANTAGE ) then
		local comboHits = math.floor(self:GetComboHits())
		if comboHits > 0 then
			draw.SimpleText("Combo x" .. comboHits, "DermaLarge", (centerX + barW / 2) + 20, baseY - 8, Color(255, 215, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end

	if combo.AutoBlock and not LSCS:HUDShouldHide( LSCS_HUD_POINTS_BLOCK ) then
		-- Calculamos el porcentaje
		local bpRatio = math.Clamp( BlockPoints / self:GetMaxBlockPoints(), 0, 1 )
		local bpColor = Color( 120, 190, 255, 255 )

		-- Parpadeo si la guardia se rompe
		if notifyTime > T and BlockPoints <= 1 then
			local Mul = math.abs( math.cos( T * 7.5 ) )
			bpColor = Color( 200, 100 * Mul, 100 * Mul, 255 )
		end

		local stBarW = 400 
		local currentWidth = math.max(1, stBarW * bpRatio)

		-- 1. BORDE NEGRO
		surface.SetDrawColor( 0, 0, 0, 255 )
		surface.DrawRect( (centerX - stBarW / 2) - 1, baseY - 1, stBarW + 2, barH + 2 )
		
		-- 2. FONDO VACÍO
		surface.SetDrawColor( 0, 0, 0, 150 )
		surface.DrawRect( centerX - stBarW / 2, baseY, stBarW, barH )

		-- 3. BARRA CELESTE CON EFECTOS
		if bpRatio > 0 then
			-- A. Base celeste sólida
			surface.SetDrawColor( bpColor.r, bpColor.g, bpColor.b, bpColor.a )
			surface.DrawRect( centerX - stBarW / 2, baseY, currentWidth, barH )
			
			-- B. Sombreado oscuro vertical (le da volumen al centro)
			surface.SetMaterial( Material("vgui/gradient-d") )
			surface.SetDrawColor( 0, 0, 0, 90 )
			surface.DrawTexturedRect( centerX - stBarW / 2, baseY, currentWidth, barH )
			
			-- C. GRADIENTE CLARO EN LAS PUNTAS (El brillo del video)
			-- Punta Izquierda (Brillo difuminado que nace de la izquierda)
			surface.SetMaterial( Material("vgui/gradient-l") )
			surface.SetDrawColor( 255, 255, 255, 120 ) 
			surface.DrawTexturedRect( centerX - stBarW / 2, baseY, math.min(currentWidth, 50), barH )
			
			-- Punta Derecha (Brillo difuminado que termina en la derecha)
			surface.SetMaterial( Material("vgui/gradient-r") )
			surface.SetDrawColor( 255, 255, 255, 180 )
			surface.DrawTexturedRect( (centerX - stBarW / 2) + currentWidth - math.min(currentWidth, 50), baseY, math.min(currentWidth, 50), barH )		end
	end

	local Pos = ply:GetPos()

	if self:IsComboActive() then return end	

	for _,v in ipairs( player.GetAll() ) do -- oh no he did it again... How else would you do it tho?
		if v == ply or (v:GetPos() - Pos):Length() > 400 then continue end

		local _pos = self:GetPlayerBlockPos( v )

		if _pos and _pos ~= VECTOR_NULL then
			local Pos2D = _pos:ToScreen()
			if not Pos2D.visible then continue end

			local BlockDistance = self:GetBlockDistanceTo( _pos )

			local Col

			if BlockDistance < self:GetBlockDistanceNormal() then
				if BlockDistance < self:GetBlockDistancePerfect() then
					Col = Color( 0, 255, 0, 255 ) -- why
				else
					Col = Color( 255, 255, 0, 255 ) -- am i not
				end
			else
				Col = Color( 255, 0, 0, 255 ) -- caching these?
			end

			surface.SetDrawColor( Col.r, Col.g, Col.b, Col.a )

			if self:GetPlayerCurComboUnblockable( v ) then
				draw.SimpleText( "!", "LSCS_BLOCK_FONT", Pos2D.x, Pos2D.y, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			else
				surface.SetMaterial( mat_xhair )
				surface.DrawTexturedRectRotated( Pos2D.x, Pos2D.y, 40, 40, 0 )
			end

			surface.SetDrawColor( Col.r * 0.5, Col.g * 0.5, Col.b * 0.5, Col.a )
			local SZ = 1000 * self:GetAttackMultiplier( v )
			surface.SetMaterial( mat_glow )
			surface.DrawTexturedRectRotated( Pos2D.x, Pos2D.y, SZ, SZ, 0 )
		end
	end
end

function SWEP:GetPlayerBlockPos( ply )
	if not IsValid( ply ) or not ply.GetActiveWeapon then return false end

	local wep = ply:GetActiveWeapon()

	if not IsValid( wep ) or not wep.LSCS or not wep.GetBlockPos then return false end

	return wep:GetBlockPos()
end

function SWEP:GetPlayerCurComboUnblockable( ply )
	if not IsValid( ply ) or not ply.GetActiveWeapon then return false end

	local wep = ply:GetActiveWeapon()

	if not IsValid( wep ) or not wep.LSCS or not wep.CurComboUnblockable then return false end

	return wep:CurComboUnblockable()
end

function SWEP:GetAttackMultiplier( ply )
	if not IsValid( ply ) or not ply.GetActiveWeapon then return false end

	local wep = ply:GetActiveWeapon()

	if not IsValid( wep ) or not wep.LSCS or not wep.GetComboHits then return false end

	return wep:GetComboHits()
end

local circle = Material( "vgui/circle" )
local size = 5

function SWEP:DoDrawCrosshair( x, y )
	local ply = LocalPlayer()

	local pos = ply:lscsGetViewOrigin() + ply:EyeAngles():Forward() * 100 -- this method IS needed in case some other third person addon is overwriting the view

	local scr = pos:ToScreen()

	if scr.visible then
		surface.SetMaterial( circle )
		surface.SetDrawColor( 0, 0, 0, 255 )
		surface.DrawTexturedRect( scr.x - size * 0.5 + 1, scr.y - size * 0.5 + 1, size, size )

		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawTexturedRect( scr.x - size * 0.5, scr.y - size * 0.5, size, size )
	end

	return true
end

function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
	draw.SimpleText( "n", "WeaponIcons", x + wide/2, y + tall*0.2, Color( 255, 210, 0, 255 ), TEXT_ALIGN_CENTER )
end

function SWEP:CalcView( ply, pos, angles, fov )
	if not IsValid( ply ) or ply:GetViewEntity() ~= ply or not ply:Alive() then return end

	ply._lscsCalcViewTime = CurTime() + 0.1 -- this is used to detect if its broken

	return ply:lscsGetViewOrigin(), ply:EyeAngles(), fov
end

function SWEP:Reload()
end

function SWEP:OnActiveChanged( oldActive, active )
end

function SWEP:OnTick()
end

function SWEP:OnRemove()
	self:ClearWorldModel()
	self:ClearBladeModel()
end

function SWEP:EmitSoundUnpredicted( sound )
	-- dont do anything on client
end

surface.CreateFont( "LSCS_BP_FONT", {
	font = "Verdana",
	extended = false,
	size = 16,
	weight = 2000,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
} )

surface.CreateFont( "LSCS_BLOCK_FONT", {
	font = "Verdana",
	extended = false,
	size = 60,
	weight = 2000,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
} )