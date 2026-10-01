if CLIENT then return end

local meta = FindMetaTable("Player")

-- Función para añadir XP y manejar la subida de niveles
function meta:lscsAddXP( amount )
	if not amount or amount <= 0 then return end
	local currentXP = self:lscsGetXP() or 0
	local currentLevel = self:lscsGetLevel() or 1
	
	currentXP = currentXP + amount
	local leveledUp = false
	
	-- Calculamos subidas de nivel en bucle por si se gana mucha XP de golpe
	while true do
		local requiredXP = math.max(1, currentLevel * 1000)
		if currentXP >= requiredXP then
			currentXP = currentXP - requiredXP
			currentLevel = currentLevel + 1
			self:lscsAddSkillPoints( 1 )
			leveledUp = true
		else
			break
		end
	end
	
	self:lscsSetXP( currentXP )
	
	if leveledUp then
		self:lscsSetLevel( currentLevel )
		self:EmitSound("garrysmod/save_load1.wav") -- Sonido de nivel
		self:ChatPrint("¡Has subido al nivel " .. currentLevel .. " en la Fuerza! Has obtenido +1 Punto de Habilidad.")
	end
end

local function IsLSCSKill(attacker, inflictor)
	if not IsValid(inflictor) then return false end
	-- Sable de luz directo o entidad de daño vinculada al arma
	if inflictor:GetClass() == "weapon_lscs" then return true end
	-- Si el inflictor es el propio atacante, suele ser un ataque Lua (como los poderes de la Fuerza)
	if inflictor == attacker then return true end
	
	return false
end

hook.Add("EntityTakeDamage", "LSCS_XP_KillCheck", function(target, dmginfo)
	-- Evitar contar la muerte varias veces
	if target.LSCS_AlreadyDead then return end

	-- Verificamos si el daño será letal
	if target:Health() - dmginfo:GetDamage() <= 0 then
		local attacker = dmginfo:GetAttacker()
		local inflictor = dmginfo:GetInflictor()

		if IsValid(attacker) and attacker:IsPlayer() and attacker ~= target then
			if IsLSCSKill(attacker, inflictor) then
				
				-- Si matamos a un jugador
				if target:IsPlayer() then
					target.LSCS_AlreadyDead = true
					local xpGain = math.random(150, 300)
					attacker:lscsAddXP( xpGain )
					-- attacker:ChatPrint("+" .. xpGain .. " XP (Jugador Eliminado)")
					
				-- Si matamos a un NPC o NextBot
				elseif target:IsNPC() or target:IsNextBot() then
					target.LSCS_AlreadyDead = true
					local xpGain = math.random(50, 100)
					attacker:lscsAddXP( xpGain )
					-- attacker:ChatPrint("+" .. xpGain .. " XP (Unidad Destruida)")
				end
				
			end
		end
	end
end)
