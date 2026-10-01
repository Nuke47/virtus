if CLIENT then return end

util.AddNetworkString("lscs_unlock_skill")
util.AddNetworkString("lscs_open_stance_menu")
util.AddNetworkString("lscs_equip_stance")
util.AddNetworkString("lscs_set_force_slots")
util.AddNetworkString("lscs_sync_unlocked_skills")
util.AddNetworkString("lscs_hotbar_sync")

net.Receive("lscs_unlock_skill", function(len, ply)
	if not IsValid(ply) then return end
	local skill_id = net.ReadString()
	local skill_type = net.ReadString() -- "stance" or "force"
	
	local cost = 1 -- Default cost
	
	local unlocked = ply:lscsGetUnlockedSkills()
	if table.HasValue(unlocked, skill_id) then
		ply:ChatPrint("[LSCS] Ya tienes esta habilidad desbloqueada.")
		return
	end
	
	if ply:lscsGetSkillPoints() >= cost then
		ply:lscsAddSkillPoints(-cost)
		ply:lscsUnlockSkill(skill_id)
		ply:ChatPrint("[LSCS] Habilidad desbloqueada: " .. skill_id)
	else
		ply:ChatPrint("[LSCS] No tienes suficientes Puntos de Habilidad.")
	end
end)

concommand.Add("lscs_giveskillpoints", function(ply, cmd, args)
	if IsValid(ply) and not ply:IsSuperAdmin() then
		ply:ChatPrint("[LSCS] Acceso denegado.")
		return
	end
	
	local target = args[1]
	local points = tonumber(args[2]) or 1
	
	if not target then
		if IsValid(ply) then
			ply:lscsAddSkillPoints(points)
			ply:ChatPrint("[LSCS] Te has dado " .. points .. " Puntos de Habilidad.")
		end
		return
	end
	
	for _, p in ipairs(player.GetAll()) do
		if string.find(string.lower(p:Nick()), string.lower(target)) then
			p:lscsAddSkillPoints(points)
			if IsValid(ply) then
				ply:ChatPrint("[LSCS] Has dado " .. points .. " Puntos de Habilidad a " .. p:Nick() .. ".")
			end
			p:ChatPrint("[LSCS] Un admin te ha dado " .. points .. " Puntos de Habilidad.")
			return
		end
	end
	
	if IsValid(ply) then
		ply:ChatPrint("[LSCS] Jugador no encontrado.")
	end
end)

net.Receive("lscs_equip_stance", function(len, ply)
	if not IsValid(ply) then return end
	local index = net.ReadInt(16)
	
	local wep = ply:GetWeapon("weapon_lscs")
	if IsValid(wep) then
		local totalStances = #ply:lscsGetCombo()
		if index >= 1 and index <= totalStances then
			wep:SetNWStance(index)
			ply:EmitSound("weapons/smg1/switch_single.wav")
		end
	end
end)

-- Sistema para guardar el orden de los poderes de la fuerza (Drag & Drop)
net.Receive("lscs_set_force_slots", function(len, ply)
	if not IsValid(ply) then return end
	
	local numSlots = net.ReadUInt(4)
	local newPowers = {}
	for i = 1, numSlots do
		table.insert(newPowers, net.ReadString())
	end
	
	local unlocked = ply:lscsGetUnlockedSkills()
	ply.m_equipped_lscs = ply.m_equipped_lscs or {}
	
	-- Desequipar todos los poderes de la fuerza actuales (manteniendo posturas u otros items)
	local toKeep = {}
	for k, item in pairs(ply.m_equipped_lscs) do
		if type(item) == "table" and item.type == "force" then
			hook.Run("LSCS:OnPlayerUnEquippedItem", ply, item)
		else
			table.insert(toKeep, item)
		end
	end
	ply.m_equipped_lscs = toKeep
	
	-- Insertar los nuevos poderes en el orden elegido (protegiendo contra duplicados)
	local added = {}
	for _, skill_id in ipairs(newPowers) do
		if table.HasValue(unlocked, skill_id) and not added[skill_id] then
			added[skill_id] = true
			local newItem = { id = skill_id, type = "force" }
			table.insert(ply.m_equipped_lscs, newItem)
			hook.Run("LSCS:OnPlayerEquippedItem", ply, newItem)
		end
	end
	
	ply:lscsSaveData()
	if ply.lscsSyncInventory then ply:lscsSyncInventory() end
	if ply.lscsBuildPlayerInfo then ply:lscsBuildPlayerInfo() end
	
	-- Enviar la sincronizaciǭn especǭfica del hotbar para evitar el bug del HUD base
	net.Start("lscs_hotbar_sync")
	net.WriteTable(added)
	net.Send(ply)
end)

util.AddNetworkString("lscs_reset_skills")
net.Receive("lscs_reset_skills", function(len, ply)
	if not IsValid(ply) then return end
	
	local unlocked = ply:lscsGetUnlockedSkills() or {}
	local pointsToRefund = #unlocked
	
	if pointsToRefund <= 0 then
		ply:ChatPrint("[LSCS] No tienes habilidades para resetear.")
		return
	end
	
	-- Dar los puntos
	ply:lscsAddSkillPoints(pointsToRefund)
	
	-- Limpiar desbloqueados
	ply.m_lscs_unlocked_skills = {}
	
	-- Limpiar los poderes y posturas equipadas (mantener sables)
	local toKeep = {}
	ply.m_equipped_lscs = ply.m_equipped_lscs or {}
	for k, item in pairs(ply.m_equipped_lscs) do
		if type(item) == "table" and (item.type == "force" or item.type == "stance") then
			hook.Run("LSCS:OnPlayerUnEquippedItem", ply, item)
		else
			table.insert(toKeep, item)
		end
	end
	ply.m_equipped_lscs = toKeep
	
	-- Guardar y sincronizar
	ply:lscsSaveData()
	ply:lscsSyncSkillTree()
	if ply.lscsSyncInventory then ply:lscsSyncInventory() end
	if ply.lscsBuildPlayerInfo then ply:lscsBuildPlayerInfo() end
	
	ply:ChatPrint("[LSCS] Has reseteado tu árbol de habilidades y recuperado " .. pointsToRefund .. " Puntos.")
end)
