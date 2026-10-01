local blur = Material("pp/blurscreen")

local SelectorWidth = 410
local SelectorItemHeight = 64
local SelectedItemHeight = 72
local SelectedItemHalfHeight = SelectedItemHeight * 0.5
local StartOffsetToSelectable = 5
local FrameThickness = 3
local SelectorHeight = SelectedItemHeight + 2 * FrameThickness

local X = ScrW() * 0.5 - SelectorWidth * 0.5
local Y = ScrH() - SelectorHeight - 25

local MouseWheelScroller = false
local Selected = cookie.GetNumber("lscs_selected_force_slot", 1)

local function UpdateSelected(val)
	Selected = val
	cookie.Set("lscs_selected_force_slot", tostring(val))
end

local smOffset = 0
local smAlpha = 0
local FadeTimer = 0

LSCS.ForceSelector = LSCS.ForceSelector or {
	KeyActivate = CreateClientConVar( "lscs_key_selector_activate", KEY_LALT, true, true ),
	KeyNext = CreateClientConVar( "lscs_key_selector_next", KEY_G, true, true ),
	KeyPrev = CreateClientConVar( "lscs_key_selector_prev", KEY_H, true, true ),
	KeyUse = CreateClientConVar( "lscs_key_selector_use", KEY_F, true, true ),
}

local ID_IN_USE

local function Use( ID )
	ID_IN_USE = ID

	net.Start("lscs_force_use")
		net.WriteInt( ID, 8 ) -- 127 equipped force powers are enough?
		net.WriteBool( true )
	net.SendToServer()
end

local function StopUse( ID )
	ID_IN_USE = nil

	net.Start("lscs_force_use")
		net.WriteInt( ID, 8 )
		net.WriteBool( false )
	net.SendToServer()
end

net.Receive( "lscs_force_use", function( len )
	ID_IN_USE = nil
end )

local NextNav = 0

local function GetClientLayout()
	if LSCS_ClientLayoutCache then return LSCS_ClientLayoutCache end
	local content = file.Read("lscs_client_layout.json", "DATA")
	LSCS_ClientLayoutCache = content and util.JSONToTable(content) or {}
	return LSCS_ClientLayoutCache
end

LSCS_SyncedForcePowers = LSCS_SyncedForcePowers or {}

net.Receive("lscs_hotbar_sync", function()
	LSCS_SyncedForcePowers = net.ReadTable() or {}
end)

local function GetHotbarForcePowers(ply)
	local ForcePowers = {}
	local server_powers = LSCS_SyncedForcePowers
	
	-- Fallback a lscsGetForceAbilities si aún no ha sincronizado o recién se conecta
	if table.IsEmpty(server_powers) then
		local force_abilities = ply:lscsGetForceAbilities()
		if force_abilities then
			for _, object in ipairs(force_abilities) do
				if object and object.item and object.item.id then
					server_powers["lscs_force_" .. object.item.id] = true
				end
			end
		end
	end

	local real_indices = {}
	local unlocked = ply.lscsGetUnlockedSkills and ply:lscsGetUnlockedSkills() or {}
	local idx = 1
	for _, skill_id in ipairs(unlocked) do
		local clean_force = string.Replace(skill_id, "lscs_force_", "")
		if LSCS:GetForce(clean_force) then
			real_indices[skill_id] = idx
			idx = idx + 1
		end
	end

	local layout = GetClientLayout()
	local assigned = {}
	
	for slot, id in pairs(layout) do
		slot = tonumber(slot)
		if slot and slot >= 1 and slot <= 9 and server_powers[id] then
			local forceID = string.Replace(id, "lscs_force_", "")
			local pData = LSCS:GetForce(forceID)
			if pData then
				ForcePowers[slot] = {id = id, item = pData, server_idx = real_indices[id]}
				assigned[id] = true
			end
		end
	end

	for id, _ in pairs(server_powers) do
		if not assigned[id] then
			for i=1, 9 do
				if not ForcePowers[i] then
					local forceID = string.Replace(id, "lscs_force_", "")
					local pData = LSCS:GetForce(forceID)
					if pData then
						ForcePowers[i] = {id = id, item = pData, server_idx = real_indices[id]}
					end
					break
				end
			end
		end
	end
	return ForcePowers
end

local function PlayerButtonDown( ply, button )
	local selector = LSCS.ForceSelector

	local InVehicle = ply:InVehicle()

	local AllowForce = not InVehicle or (InVehicle and ply:GetAllowWeaponsInVehicle())

	if AllowForce then
		if button == selector.KeyActivate:GetInt() and ply:lscsGetForceAllowed() then
			if #ply:lscsGetForceAbilities() == 0 then return end

			MouseWheelScroller = true
			FadeTimer = CurTime() + 9999
		end
		if button == selector.KeyUse:GetInt() then
			local FP = GetHotbarForcePowers(ply)
			if FP[Selected] and FP[Selected].server_idx then
				Use( FP[Selected].server_idx )
			end
		end
	end
end

local function PlayerButtonUp( ply, button )
	local selector = LSCS.ForceSelector

	if button == selector.KeyActivate:GetInt() then
		MouseWheelScroller = false
		FadeTimer = 0
	end
	if ID_IN_USE and button == selector.KeyUse:GetInt() then
		StopUse( ID_IN_USE )
	end

	local Input = LSCS.KeyToForce[ button ]

	if not Input then return end

	local ForcePowers = GetHotbarForcePowers(ply)

	for _, name in pairs( Input ) do
		for ID, power in pairs( ForcePowers ) do
			if power.item.id == name then
				if power.server_idx then
					StopUse( power.server_idx )
				end
			end
		end
	end
end

if game.SinglePlayer() then
	local IS_MOUSE_ENUM = {
		[MOUSE_LEFT] = true,
		[MOUSE_RIGHT] = true,
		[MOUSE_MIDDLE] = true,
		[MOUSE_4] = true,
		[MOUSE_5] = true,
		[MOUSE_WHEEL_UP] = true,
		[MOUSE_WHEEL_DOWN] = true,
	}

	local function InputPressed( key )
		if IS_MOUSE_ENUM[ key ] then
			return input.IsMouseDown( key ) 
		else
			return input.IsKeyDown( key ) 
		end
	end

	local OldPressed = {false, false,false,false}
	local OldPressedForce = {}

	hook.Add( "Think", "!!!lscs_gmods_prediction_system_is_cancer", function()
		local ply = LocalPlayer()

		local selector = LSCS.ForceSelector

		local SelectorButtons = {selector.KeyActivate:GetInt(),selector.KeyUse:GetInt(),selector.KeyNext:GetInt(),selector.KeyPrev:GetInt()}

		for id, key in pairs( SelectorButtons ) do
			local pressed = InputPressed( key )

			if OldPressed[ id ] ~= pressed then
				OldPressed[ id ] = pressed
				if pressed then
					PlayerButtonDown( ply, key )
				else
					PlayerButtonUp( ply, key )
				end
			end
		end

		for _, entry in pairs( LSCS.Force ) do
			local key = entry.cmd:GetInt()
			if not OldPressedForce[ key ] then OldPressedForce[ key ] = false end
	
			local pressed = InputPressed( key )

			if OldPressedForce[ key ] ~= pressed then
				OldPressedForce[ key ] = pressed
				if pressed then
					PlayerButtonDown( ply, key )
				else
					PlayerButtonUp( ply, key )
				end
			end
		end
	end )
else
	hook.Add( "PlayerButtonDown", "!!!!lscs_buttondownstuff", function( ply, button )
		if IsFirstTimePredicted() then
			PlayerButtonDown( ply, button )
		end
	end)

	hook.Add( "PlayerButtonUp", "!!!!lscs_buttonupstuff", function( ply, button )
		if IsFirstTimePredicted() then
			PlayerButtonUp( ply, button )
		end
	end)
end

local LAST_USED_LMB

hook.Add( "PlayerBindPress", "!!!!_lscs_playerbindpress", function( ply, bind, pressed )
	if not MouseWheelScroller then

		if not LAST_USED_LMB then return end

		if bind ~= "+attack" or pressed then return end

		StopUse( LAST_USED_LMB )

		return
	end

	if ply:InVehicle() and not ply:GetAllowWeaponsInVehicle() then return end

	local Time = CurTime()

	if bind == "+attack" then
		if pressed then
			LAST_USED_LMB = Selected
			
			local FP = GetHotbarForcePowers(ply)
			if FP[Selected] and FP[Selected].server_idx then
				Use( FP[Selected].server_idx )
			end
		else
			if LAST_USED_LMB then
				local FP = GetHotbarForcePowers(ply)
				if FP[LAST_USED_LMB] and FP[LAST_USED_LMB].server_idx then
					StopUse( FP[LAST_USED_LMB].server_idx )
				end
			end

			LAST_USED_LMB = nil
		end

		return true
	end
end )

-- =========================================================
-- HOTBAR DE PODERES (1 al 9)
-- =========================================================
-- REDISEÑO COMPLETO DE LA SELECTORA INFERIOR (HUD)
-- =========================================================
local LSCS_Hotbar_Toggled = false
local HotbarAnim = 0

hook.Add("HUDPaint", "LSCS_InventoryHotbar", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if ply:InVehicle() and not ply:GetAllowWeaponsInVehicle() then return end

	-- Solo mostrar si tenemos un sable LSCS equipado en mano
	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or not wep.LSCS then return end

	local ForcePowers = GetHotbarForcePowers(ply)

	HotbarAnim = Lerp(FrameTime() * 10, HotbarAnim, LSCS_Hotbar_Toggled and 1 or 0)

	local totalSlots = 9
	local slotSize = Lerp(HotbarAnim, 30, 45) -- 30 normal, 45 expandida
	local padding = 5
	local totalWidth = (totalSlots * slotSize) + ((totalSlots - 1) * padding)
	
	local startX = (ScrW() / 2) - (totalWidth / 2)
	local yPos = ScrH() - 100 - (HotbarAnim * 20) -- Sube un poco al expandirse

	for i = 1, totalSlots do
		local power = ForcePowers[i]
		local xPos = startX + ((i - 1) * (slotSize + padding))
		local isSelected = (Selected == i) and (power ~= nil)

		-- Fondo del slot (más opaco cuando se expande)
		local bgAlpha = Lerp(HotbarAnim, 100, 200)
		draw.RoundedBox(4, xPos, yPos, slotSize, slotSize, isSelected and Color(0, 150, 255, bgAlpha) or Color(30, 30, 30, bgAlpha))
		
		-- Borde brillante SOLO se muestra si está expandida
		if isSelected and HotbarAnim > 0.05 then
			surface.SetDrawColor(255, 255, 255, (math.abs(math.sin(CurTime() * 5)) * 100 + 100) * HotbarAnim)
			surface.DrawOutlinedRect(xPos - 1, yPos - 1, slotSize + 2, slotSize + 2, 2)
		end

		-- Ícono del poder
		if power and power.item and power.item.icon then
			local iconAlpha = Lerp(HotbarAnim, 100, 255)
			surface.SetDrawColor(255, 255, 255, isSelected and 255 or iconAlpha)
			surface.SetMaterial(power.item.icon)
			surface.DrawTexturedRect(xPos + 4, yPos + 4, slotSize - 8, slotSize - 8)
		end

		-- Número del teclado (aparece al expandir)
		if HotbarAnim > 0.05 then
			draw.SimpleText(tostring(i), "DermaDefaultBold", xPos + slotSize / 2, yPos - 15, Color(255, 255, 255, 200 * HotbarAnim), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
end)

-- Manejar las teclas del 1 al 9 para seleccionar poderes rápidamente y la G para alternar
hook.Add("PlayerButtonDown", "LSCS_HotbarKeys", function(ply, button)
	if not game.SinglePlayer() and not IsFirstTimePredicted() then return end
	
	-- Alternar con G
	if button == KEY_G and not input.IsKeyDown(KEY_LALT) then
		LSCS_Hotbar_Toggled = not LSCS_Hotbar_Toggled
		if LSCS_Hotbar_Toggled then
			surface.PlaySound("buttons/lightswitch2.wav")
		end
		return
	end

	-- Si está abierto, permitir números
	if LSCS_Hotbar_Toggled then
		if button >= KEY_1 and button <= KEY_9 then
			local slotIndex = button - KEY_1 + 1
			local ForcePowers = GetHotbarForcePowers(ply)
			
			if ForcePowers and ForcePowers[slotIndex] then
				UpdateSelected(slotIndex)
				surface.PlaySound("lscs/force_next.mp3")
			end
		end
	end
end)

-- Bloquear el cambio de armas de GMod (slot1, slot2...) si está abierto
hook.Add("PlayerBindPress", "LSCS_BlockWeaponSwitch", function(ply, bind, pressed)
	if LSCS_Hotbar_Toggled and string.match(bind, "slot") then
		return true
	end
end)
