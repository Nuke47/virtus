if CLIENT then return end

util.AddNetworkString("lscs_admin_give_item")
util.AddNetworkString("lscs_admin_set_level")
util.AddNetworkString("lscs_admin_set_xp")
util.AddNetworkString("lscs_admin_reset_inventory")
util.AddNetworkString("lscs_admin_give_sp")

net.Receive("lscs_admin_give_item", function(len, ply)
	if not IsValid(ply) or not ply:IsSuperAdmin() then return end
	
	local itemClass = net.ReadString()
	
	-- Verify it's a valid item
	local object = LSCS:ClassToItem(itemClass)
	if not object then return end
	
	if object.type == "hilt" or object.type == "crystal" then
		local ent = ents.Create(itemClass)
		if IsValid(ent) then
			local tr = ply:GetEyeTrace()
			local pos = tr.HitPos + Vector(0, 0, 10)
			if ply:GetPos():DistToSqr(pos) > 10000 then -- prevent spawning too far
				pos = ply:GetPos() + ply:GetForward() * 50 + Vector(0, 0, 10)
			end
			ent:SetPos(pos)
			ent:SetAngles(Angle(90, ply:EyeAngles().y, 0))
			ent:Spawn()
			ent:Activate()
			ent.PreventTouch = true
			ent.DieTime = CurTime() + 240
			
			ply:ChatPrint("[LSCS Admin] Objeto spawneado: " .. object.name)
		end
	end
end)

net.Receive("lscs_admin_set_level", function(len, ply)
	if not IsValid(ply) or not ply:IsSuperAdmin() then return end
	local target = net.ReadEntity()
	local level = net.ReadInt(32)
	if IsValid(target) and target:IsPlayer() then
		target:lscsSetLevel(level)
		ply:ChatPrint("[LSCS Admin] Nivel de " .. target:Nick() .. " seteado a " .. level)
	end
end)

net.Receive("lscs_admin_set_xp", function(len, ply)
	if not IsValid(ply) or not ply:IsSuperAdmin() then return end
	local target = net.ReadEntity()
	local xp = net.ReadInt(32)
	if IsValid(target) and target:IsPlayer() then
		target:lscsSetXP(xp)
		ply:ChatPrint("[LSCS Admin] XP de " .. target:Nick() .. " seteada a " .. xp)
	end
end)

net.Receive("lscs_admin_reset_inventory", function(len, ply)
	if not IsValid(ply) or not ply:IsSuperAdmin() then return end
	local target = net.ReadEntity()
	if IsValid(target) and target:IsPlayer() then
		target:lscsWipeInventory(false)
		target.m_lscs_unlocked_skills = {}
		target:lscsSetSkillPoints(0)
		target:lscsSaveData()
		target:lscsSyncSkillTree()
		ply:ChatPrint("[LSCS Admin] Inventario y habilidades de " .. target:Nick() .. " reseteados.")
	end
end)

net.Receive("lscs_admin_give_sp", function(len, ply)
	if not IsValid(ply) or not ply:IsSuperAdmin() then return end
	local target = net.ReadEntity()
	local sp = net.ReadInt(32)
	if IsValid(target) and target:IsPlayer() then
		target:lscsAddSkillPoints(sp)
		ply:ChatPrint("[LSCS Admin] Has dado " .. sp .. " Puntos de Habilidad a " .. target:Nick())
		target:ChatPrint("[LSCS] Un admin te ha dado " .. sp .. " Puntos de Habilidad.")
	end
end)
