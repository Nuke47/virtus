-- ============================================================
-- IVO FLY - SISTEMA DE MEJORAS Y DESPLIEGUE (LÓGICA SERVIDOR)
-- ============================================================
if not SERVER then return end 

IvoFly = IvoFly or {}

sql.Query("CREATE TABLE IF NOT EXISTS ivo_fly_upgrades_v2 (steamid TEXT, class TEXT, engine INTEGER, armor INTEGER, agility INTEGER, weapons INTEGER, PRIMARY KEY (steamid, class))")

-- Registros de Red obligatorios
util.AddNetworkString("IvoFly_RequestWorkshop")
util.AddNetworkString("IvoFly_OpenWorkshop")
util.AddNetworkString("IvoFly_BuyUpgrade")
util.AddNetworkString("IvoFly_UpdateWorkshop")
util.AddNetworkString("IvoFly_SpawnFromWorkshop")
util.AddNetworkString("IvoFly_DeployEffect")

function IvoFly.GetUpgrades(ply, class)
    if not IsValid(ply) or not class then return {engine = 0, armor = 0, agility = 0, weapons = 0} end
    local steamid = ply:SteamID()
    local data = sql.QueryRow("SELECT * FROM ivo_fly_upgrades_v2 WHERE steamid = " .. sql.SQLStr(steamid) .. " AND class = " .. sql.SQLStr(class))
    if data then
        return {
            engine = tonumber(data.engine) or 0,
            armor = tonumber(data.armor) or 0,
            agility = tonumber(data.agility) or 0,
            weapons = tonumber(data.weapons) or 0
        }
    else return {engine = 0, armor = 0, agility = 0, weapons = 0} end
end

function IvoFly.SetUpgrade(ply, class, category, level)
    local steamid = ply:SteamID()
    local upg = IvoFly.GetUpgrades(ply, class)
    upg[category] = level
    
    local exists = sql.QueryValue("SELECT steamid FROM ivo_fly_upgrades_v2 WHERE steamid = " .. sql.SQLStr(steamid) .. " AND class = " .. sql.SQLStr(class))
    if exists then
        sql.Query(string.format("UPDATE ivo_fly_upgrades_v2 SET %s = %d WHERE steamid = %s AND class = %s", category, level, sql.SQLStr(steamid), sql.SQLStr(class)))
    else
        sql.Query(string.format("INSERT INTO ivo_fly_upgrades_v2 (steamid, class, engine, armor, agility, weapons) VALUES (%s, %s, %d, %d, %d, %d)", 
            sql.SQLStr(steamid), sql.SQLStr(class), upg.engine, upg.armor, upg.agility, upg.weapons))
    end
    
    if ply:InVehicle() then
        local pod = ply:GetVehicle()
        local base = pod:GetParent()
        if IsValid(base) and base.LVS then IvoFly.ApplyVehicleStats(ply, base) end
    end
end

function IvoFly.ApplyVehicleStats(ply, veh)
    if not veh.IvoBaseStats then
        veh.IvoBaseStats = {
            MaxHP = veh:GetMaxHP(),
            MaxVelocity = veh.MaxVelocity or 2000,
            MaxThrust = veh.MaxThrust or 2000,
            TurnRatePitch = veh.TurnRatePitch or 1,
            TurnRateYaw = veh.TurnRateYaw or 1,
            TurnRateRoll = veh.TurnRateRoll or 1,
        }
    end

    local upg = IvoFly.GetUpgrades(ply, veh:GetClass())
    local engMult = 1 + (upg.engine * 0.10)
    local armMult = 1 + (upg.armor * 0.15)
    local agiMult = 1 + (upg.agility * 0.10)

    veh.MaxVelocity = veh.IvoBaseStats.MaxVelocity * engMult
    veh.MaxThrust = veh.IvoBaseStats.MaxThrust * engMult
    
    local currentHpPercent = veh:GetHP() / veh:GetMaxHP()
    veh:SetMaxHP(veh.IvoBaseStats.MaxHP * armMult)
    veh:SetHP(veh:GetMaxHP() * currentHpPercent)

    veh.TurnRatePitch = veh.IvoBaseStats.TurnRatePitch * agiMult
    veh.TurnRateYaw = veh.IvoBaseStats.TurnRateYaw * agiMult
    veh.TurnRateRoll = veh.IvoBaseStats.TurnRateRoll * agiMult

    if upg.engine > 0 or upg.armor > 0 or upg.agility > 0 then
        ply:PrintMessage(HUD_PRINTTALK, "[Taller] Mejoras personales instaladas en esta nave.")
    end
end

function IvoFly.ResetVehicleStats(veh)
    if not veh.IvoBaseStats then return end
    veh.MaxVelocity = veh.IvoBaseStats.MaxVelocity
    veh.MaxThrust = veh.IvoBaseStats.MaxThrust
    local currentHpPercent = veh:GetHP() / veh:GetMaxHP()
    veh:SetMaxHP(veh.IvoBaseStats.MaxHP)
    veh:SetHP(veh:GetMaxHP() * currentHpPercent)
    veh.TurnRatePitch = veh.IvoBaseStats.TurnRatePitch
    veh.TurnRateYaw = veh.IvoBaseStats.TurnRateYaw
    veh.TurnRateRoll = veh.IvoBaseStats.TurnRateRoll
end

hook.Add("PlayerEnteredVehicle", "IvoFly_ApplyUpgrades", function(ply, pod, role)
    local baseEnt = pod:GetParent()
    if IsValid(baseEnt) and baseEnt.LVS then
        if baseEnt:GetDriverSeat() == pod then IvoFly.ApplyVehicleStats(ply, baseEnt) end
    elseif pod.LVS then IvoFly.ApplyVehicleStats(ply, pod) end
end)

hook.Add("PlayerLeaveVehicle", "IvoFly_RemoveUpgrades", function(ply, pod)
    local baseEnt = pod:GetParent()
    if IsValid(baseEnt) and baseEnt.LVS and baseEnt:GetDriverSeat() == pod then IvoFly.ResetVehicleStats(baseEnt) end
end)

hook.Add("EntityTakeDamage", "IvoFly_WeaponUpgrades", function(target, dmginfo)
    local attacker = dmginfo:GetAttacker()
    local ply, veh
    if attacker:IsPlayer() and attacker:InVehicle() then
        local base = attacker:GetVehicle():GetParent()
        if IsValid(base) and base.LVS then ply = attacker; veh = base end
    elseif attacker.LVS then veh = attacker; ply = veh:GetDriver() end

    if IsValid(ply) and IsValid(veh) then
        local upg = IvoFly.GetUpgrades(ply, veh:GetClass())
        if upg.weapons > 0 then dmginfo:ScaleDamage(1 + (upg.weapons * 0.15)) end
    end
end)

net.Receive("IvoFly_RequestWorkshop", function(len, ply)
    local class = net.ReadString()
    local upg = IvoFly.GetUpgrades(ply, class)
    net.Start("IvoFly_OpenWorkshop")
    net.WriteString(class); net.WriteTable(upg); net.Send(ply)
end)

local UPGRADE_PRICES = {
    ["engine_1"] = 5000,  ["engine_2"] = 15000, ["engine_3"] = 45000, ["engine_4"] = 85000,
    ["armor_1"]  = 5000,  ["armor_2"]  = 12000, ["armor_3"]  = 38000, ["armor_4"]  = 75000,
    ["agility_1"]= 4000,  ["agility_2"]= 10000, ["agility_3"]= 30000, ["agility_4"]= 60000,
    ["weapons_1"]= 8000,  ["weapons_2"]= 25000, ["weapons_3"]= 60000, ["weapons_4"]= 120000,
}

net.Receive("IvoFly_BuyUpgrade", function(len, ply)
    local class = net.ReadString(); local cat = net.ReadString(); local lvl = net.ReadUInt(8)
    local upgId = cat .. "_" .. lvl; local price = UPGRADE_PRICES[upgId]
    if not price then return end
    local currentUpg = IvoFly.GetUpgrades(ply, class)
    if currentUpg[cat] >= lvl then DarkRP.notify(ply, 1, 4, "Ya tienes esta mejora instalada."); return end
    
    local reqLvls = { [1] = 5, [2] = 10, [3] = 20, [4] = 35 }
    local reqLv = reqLvls[lvl] or 1
    if ply:GetNWInt("IVO_JobLevel_piloto", 1) < reqLv then 
        DarkRP.notify(ply, 1, 4, "Nivel de pilotaje insuficiente.")
        return 
    end

    if ply:canAfford(price) then
        ply:addMoney(-price)
        IvoFly.SetUpgrade(ply, class, cat, lvl)
        DarkRP.notify(ply, 0, 4, "¡Mejora " .. string.upper(cat) .. " al nivel " .. lvl .. " instalada!")
        net.Start("IvoFly_UpdateWorkshop"); net.WriteTable(IvoFly.GetUpgrades(ply, class)); net.Send(ply)
    else
        DarkRP.notify(ply, 1, 4, "No tienes suficientes créditos para esta mejora.")
    end
end)

local function RecursiveSetNoDraw(ent, state)
    if not IsValid(ent) then return end
    ent:SetNoDraw(state)
    for _, child in ipairs(ent:GetChildren()) do
        RecursiveSetNoDraw(child, state)
    end
end

local function DeployVehicleWithEffect(class, zoneIndex, ply, isWorkshop)
    if IvoFly.ActiveVehicles >= 5 then
        net.Start("IvoFly_Notification")
        net.WriteString("Se ha alcanzado el límite de 5 naves desplegadas.")
        net.Send(ply)
        return
    end

    local zone = IvoFly.Zones[zoneIndex]
    local veh = ents.Create(class)
    if not IsValid(veh) then return end
    
    local initialPos = Vector((zone.min.x + zone.max.x)/2, (zone.min.y + zone.max.y)/2, zone.min.z + 50)
    veh:SetPos(initialPos)
    veh:SetAngles(Angle(0, 180, 0))
    veh:Spawn()
    
    local centerPos = Vector((zone.min.x + zone.max.x)/2, (zone.min.y + zone.max.y)/2, zone.min.z + 10)
    local offset = veh:OBBCenter()
    offset:Rotate(Angle(0, 180, 0))
    centerPos.x = centerPos.x - offset.x
    centerPos.y = centerPos.y - offset.y
    centerPos.z = centerPos.z - veh:OBBMins().z
    
    veh:SetPos(centerPos)
    veh.IvoFlySpawned = true
    veh:Activate()

    IvoFly.ActiveVehicles = IvoFly.ActiveVehicles + 1

    RecursiveSetNoDraw(veh, true)
    local phys = veh:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end

    net.Start("IvoFly_DeployEffect")
    net.WriteEntity(ply) -- Avisa qué jugador activó el evento para la cinemática
    net.WriteString(class)
    net.WriteVector(centerPos)
    net.WriteAngle(Angle(0, 180, 0))
    net.WriteUInt(zoneIndex, 8)
    net.Broadcast()

    net.Start("IvoFly_Notification")
    if isWorkshop then
        net.WriteString("Saliendo de Taller. Vehículo posicionado en PAD " .. zoneIndex .. ".")
    else
        net.WriteString("Iniciando secuencia de despliegue en PAD " .. zoneIndex .. ".")
    end
    net.Send(ply)

    timer.Simple(6.5, function()
        if IsValid(veh) then
            RecursiveSetNoDraw(veh, false)
            local p = veh:GetPhysicsObject()
            if IsValid(p) then p:EnableMotion(true); p:Wake() end
            
            local effectdata = EffectData()
            effectdata:SetOrigin(centerPos)
            util.Effect("cball_explode", effectdata)
        end
    end)
end

net.Receive("IvoFly_Action", function(len, ply)
    local action = net.ReadString()
    local zoneIndex = net.ReadUInt(8)
    local class = net.ReadString()
    
    local zone = IvoFly.Zones[zoneIndex]
    if not zone then return end

    if action == "spawn" then
        local occupied = false
        for _, ent in ipairs(ents.FindInBox(zone.min, zone.max)) do
            if ent:IsVehicle() or ent.LVS then occupied = true; break end
        end
        if occupied then
            net.Start("IvoFly_Notification")
            net.WriteString("La plataforma de despliegue está ocupada.")
            net.Send(ply)
            return
        end
        DeployVehicleWithEffect(class, zoneIndex, ply, false)
        
    elseif action == "delete" then
        local foundVeh = nil
        local hasPlayers = false
        for _, ent in ipairs(ents.FindInBox(zone.min, zone.max)) do
            if ent.IvoFlySpawned then
                foundVeh = ent
                if IsValid(ent:GetDriver()) then hasPlayers = true end
                for _, child in ipairs(ent:GetChildren()) do
                    if child:IsVehicle() and IsValid(child:GetDriver()) then hasPlayers = true end
                end
                break
            end
        end
        if foundVeh then
            if hasPlayers then
                net.Start("IvoFly_Notification"); net.WriteString("No se puede borrar la nave: hay tripulantes a bordo."); net.Send(ply)
            else
                foundVeh:Remove()
                IvoFly.ActiveVehicles = math.max(0, IvoFly.ActiveVehicles - 1)
                net.Start("IvoFly_Notification"); net.WriteString("Nave recogida con éxito."); net.Send(ply)
            end
        else
            net.Start("IvoFly_Notification"); net.WriteString("No hay ninguna nave generada por consola en la plataforma."); net.Send(ply)
        end
    end
end)

net.Receive("IvoFly_SpawnFromWorkshop", function(len, ply)
    local class = net.ReadString()
    local availableZoneIndex = nil
    
    for i, zone in ipairs(IvoFly.Zones) do
        local occupied = false
        for _, ent in ipairs(ents.FindInBox(zone.min, zone.max)) do
            if ent:IsVehicle() or ent.LVS then occupied = true; break end
        end
        if not occupied then availableZoneIndex = i; break end
    end
    
    if not availableZoneIndex then
        net.Start("IvoFly_Notification")
        net.WriteString("No hay plataformas disponibles. El hangar está lleno.")
        net.Send(ply)
        return
    end
    
    DeployVehicleWithEffect(class, availableZoneIndex, ply, true)
end)