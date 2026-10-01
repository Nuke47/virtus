if CLIENT then return end

sql.Query( "CREATE TABLE IF NOT EXISTS lscs_player_data ( steamid TEXT PRIMARY KEY, inventory TEXT, equipped TEXT, skillpoints INTEGER, unlocked_skills TEXT, level INTEGER, xp INTEGER )" )
-- Agregamos las columnas si ya existe la tabla pero es de una version vieja
sql.Query("ALTER TABLE lscs_player_data ADD COLUMN level INTEGER DEFAULT 1")
sql.Query("ALTER TABLE lscs_player_data ADD COLUMN xp INTEGER DEFAULT 0")
sql.Query("ALTER TABLE lscs_player_data ADD COLUMN unlocked_skills TEXT DEFAULT '[]'")
sql.Query("ALTER TABLE lscs_player_data ADD COLUMN skillpoints INTEGER DEFAULT 0")

local meta = FindMetaTable( "Player" )

function meta:lscsSaveData()
	if self:IsBot() then return end
	local steamid = self:SteamID64()
	if not steamid then return end

	local inventory = util.TableToJSON( self:lscsGetInventory() or {} )
	
	local eq_table = self:lscsGetEquipped() or {}
	local eq_flat = {}
	for k, v in pairs(eq_table) do
		eq_flat[tostring(k)] = v
	end
	local equipped = util.TableToJSON( eq_flat )
	local skillpoints = self:lscsGetSkillPoints() or 0
	local unlocked_skills = util.TableToJSON( self:lscsGetUnlockedSkills() or {} )
	local level = self:lscsGetLevel() or 1
	local xp = self:lscsGetXP() or 0

	local query = string.format(
		"REPLACE INTO lscs_player_data (steamid, inventory, equipped, skillpoints, unlocked_skills, level, xp) VALUES (%s, %s, %s, %i, %s, %i, %i)",
		sql.SQLStr( steamid ),
		sql.SQLStr( inventory ),
		sql.SQLStr( equipped ),
		skillpoints,
		sql.SQLStr( unlocked_skills ),
		level,
		xp
	)
	sql.Query( query )
end

function meta:lscsLoadData()
	if self:IsBot() then return end
	local steamid = self:SteamID64()
	if not steamid then return end

	local query = string.format( "SELECT * FROM lscs_player_data WHERE steamid = %s", sql.SQLStr( steamid ) )
	local result = sql.Query( query )

	if result and result[1] then
		local data = result[1]
		self.m_inventory_lscs = util.JSONToTable( data.inventory or "[]" ) or {}
		
		-- Fix boolean keys being converted to string or other types during JSON translation
		local equipped_raw = util.JSONToTable( data.equipped or "[]" ) or {}
		self.m_equipped_lscs = {}
		for k, v in pairs(equipped_raw) do
			self.m_equipped_lscs[tonumber(k) or k] = v
		end

		self:lscsSetSkillPoints( tonumber( data.skillpoints ) or 0, true )
		self.m_lscs_unlocked_skills = util.JSONToTable( data.unlocked_skills or "[]" ) or {}
		self:lscsSetLevel( tonumber( data.level ) or 1, true )
		self:lscsSetXP( tonumber( data.xp ) or 0, true )
	else
		self.m_inventory_lscs = {}
		self.m_equipped_lscs = {}
		self:lscsSetSkillPoints( 0, true )
		self.m_lscs_unlocked_skills = {}
		self:lscsSetLevel( 1, true )
		self:lscsSetXP( 0, true )
	end

	self:lscsSyncInventory()
	self:lscsBuildPlayerInfo()
	self:lscsSyncSkillTree()
	
	-- Enviar estado de hotbar al conectar
	local added = {}
	if self.m_equipped_lscs then
		for k, item in pairs(self.m_equipped_lscs) do
			if type(item) == "table" and item.type == "force" then
				added[item.id] = true
			end
		end
	end
	net.Start("lscs_hotbar_sync")
	net.WriteTable(added)
	net.Send(self)
end

function meta:lscsSetSkillPoints(points, no_save)
	self:SetNWInt("lscs_skillpoints", points)
	if not no_save then
		self:lscsSaveData()
	end
end

function meta:lscsAddSkillPoints(points)
	self:lscsSetSkillPoints(self:lscsGetSkillPoints() + points)
end

function meta:lscsSetLevel(level, no_save)
	self:SetNWInt("lscs_level", level)
	if not no_save then
		self:lscsSaveData()
	end
end

function meta:lscsSetXP(xp, no_save)
	self:SetNWInt("lscs_xp", xp)
	if not no_save then
		self:lscsSaveData()
	end
end

function meta:lscsUnlockSkill(skill_id)
	local skills = self:lscsGetUnlockedSkills()
	if not table.HasValue(skills, skill_id) then
		table.insert(skills, skill_id)
		self:lscsSaveData()
		self:lscsSyncSkillTree()
	end
end

util.AddNetworkString("lscs_sync_skilltree")
function meta:lscsSyncSkillTree()
	local skills = self:lscsGetUnlockedSkills()
	net.Start("lscs_sync_skilltree")
		net.WriteUInt(#skills, 16)
		for _, v in ipairs(skills) do
			net.WriteString(v)
		end
	net.Send(self)
end

hook.Add( "PlayerInitialSpawn", "LSCS_Persistence_Load", function( ply )
	timer.Simple(2, function()
		if IsValid(ply) then
			ply:lscsLoadData()
		end
	end)
end )

hook.Add( "PlayerDisconnected", "LSCS_Persistence_Save", function( ply )
	ply:lscsSaveData()
end )

hook.Add( "ShutDown", "LSCS_Persistence_SaveAll", function()
	for _, ply in ipairs( player.GetAll() ) do
		ply:lscsSaveData()
	end
end )

-- Hooks para guardar cuando cambia el inventario
hook.Add( "LSCS:PostPlayerInventory", "LSCS_Persistence_Add", function( ply ) ply:lscsSaveData() end )
hook.Add( "LSCS:OnPlayerEquippedItem", "LSCS_Persistence_Eq", function( ply ) 
	ply:lscsSaveData() 
	
	-- Actualización instantánea: si el jugador tiene un sable en la mano, le aplicamos el nuevo diseño
	if IsValid(ply) and ply:HasWeapon("weapon_lscs") then
		local SWEP = ply:GetWeapon("weapon_lscs")
		if IsValid(SWEP) then
			local HiltR, HiltL = ply:lscsGetHilt()
			local BladeR, BladeL = ply:lscsGetBlade()

			SWEP:SetHiltR( HiltR or "" )
			SWEP:SetHiltL( HiltL or "" )
			SWEP:SetBladeR( BladeR or "" )
			SWEP:SetBladeL( BladeL or "" )
		end
	end
end )
hook.Add( "LSCS:OnPlayerUnEquippedItem", "LSCS_Persistence_UnEq", function( ply ) 
	ply:lscsSaveData() 
	
	-- Actualización instantánea: si el jugador tiene un sable en la mano, le aplicamos el nuevo diseño
	if IsValid(ply) and ply:HasWeapon("weapon_lscs") then
		local SWEP = ply:GetWeapon("weapon_lscs")
		if IsValid(SWEP) then
			local HiltR, HiltL = ply:lscsGetHilt()
			local BladeR, BladeL = ply:lscsGetBlade()

			SWEP:SetHiltR( HiltR or "" )
			SWEP:SetHiltL( HiltL or "" )
			SWEP:SetBladeR( BladeR or "" )
			SWEP:SetBladeL( BladeL or "" )
		end
	end
end )
hook.Add( "LSCS:OnPlayerDroppedItem", "LSCS_Persistence_Drop", function( ply ) ply:lscsSaveData() end )

-- Override de removeitem para asegurar el guardado
local oldRemoveItem = meta.lscsRemoveItem
function meta:lscsRemoveItem( id )
	if oldRemoveItem then oldRemoveItem( self, id ) end
	self:lscsSaveData()
end

local oldWipeInventory = meta.lscsWipeInventory
function meta:lscsWipeInventory( wipe_unequipped )
	if oldWipeInventory then oldWipeInventory( self, wipe_unequipped ) end
	self:lscsSaveData()
end

-- Desactivar linterna al presionar F mientras se tiene el sable equipado
hook.Add("PlayerSwitchFlashlight", "LSCS_BlockFlashlight", function(ply, enabled)
	if enabled then
		local wep = ply:GetActiveWeapon()
		if IsValid(wep) and wep.LSCS then
			return false
		end
	end
end)
