if not SERVER then return end

util.AddNetworkString("Datapad_HackSuccess")
util.AddNetworkString("Datapad_HackFailed")

-- Recibir señal de victoria del minijuego
net.Receive("Datapad_HackSuccess", function(len, ply)
    local hackType = net.ReadString() -- "keypad" o "database"
    
    if hackType == "keypad" then
        local targetEnt = net.ReadEntity()
        if IsValid(targetEnt) then
            -- Asegurar que el jugador está cerca
            if ply:GetPos():DistToSqr(targetEnt:GetPos()) < 40000 then
                if targetEnt:GetClass() == "ivo_keypad" then
                    targetEnt:OnHackSuccess()
                    ply:ChatPrint("Hackeo completado: Puerta desbloqueada.")
                elseif targetEnt:GetClass() == "ent_ivo_docs_console" then
                    targetEnt:OnHackSuccess(ply)
                end
            end
        end
    elseif hackType == "database" then
        -- Dar recompensa de cazarrecompensas
        if DarkRP and DarkRP.notify then
            DarkRP.notify(ply, 0, 4, "Datos extraídos. Has recibido 5000 créditos.")
        else
            ply:ChatPrint("Datos extraídos. Has recibido 5000 créditos.")
        end
        if ply.addMoney then
            ply:addMoney(5000)
        end
    end
end)

-- Recibir señal de fracaso (Solo Cazarrecompensas)
net.Receive("Datapad_HackFailed", function(len, ply)
    local hackType = net.ReadString()
    
    if hackType == "database" then
        -- Alertar a la 65th
        local alertMsg = "ALERTA DE SEGURIDAD: Intento de intrusión detectado en el sector de " .. ply:Nick() .. "!"
        
        for _, v in ipairs(player.GetAll()) do
            local jobName = team.GetName(v:Team())
            if string.find(jobName, "65th") or string.find(jobName, "Shock") or string.find(jobName, "RT") then
                if DarkRP and DarkRP.notify then
                    DarkRP.notify(v, 1, 8, alertMsg)
                else
                    v:ChatPrint(alertMsg)
                end
                v:EmitSound("ambient/alarms/alarm_citizen_loop1.wav", 75, 100, 0.5, CHAN_AUTO)
                timer.Simple(3, function() if IsValid(v) then v:StopSound("ambient/alarms/alarm_citizen_loop1.wav") end end)
            end
        end
        
        if DarkRP and DarkRP.notify then
            DarkRP.notify(ply, 1, 5, "Hackeo fallido. Tu ubicación ha sido transmitida a la 65th.")
        else
            ply:ChatPrint("Hackeo fallido. Tu ubicación ha sido transmitida a la 65th.")
        end
    end
end)

-- ==========================================
-- COMANDO DE CHAT PARA BYPASS DE FPP
-- ==========================================
hook.Add("PlayerSay", "Datapad_LinkDoorBypass", function(ply, text)
    if string.lower(text) == "!linkdoor" then
        if not Datapad:HasAccess(ply, Datapad.Config.StaffJobs) and not ply:IsSuperAdmin() then
            ply:ChatPrint("Solo admins pueden enlazar puertas.")
            return ""
        end

        local tr = ply:GetEyeTrace()
        local ent = tr.Entity

        if IsValid(ent) and not ent:IsWorld() then
            ply.Datapad_SelectedDoors = ply.Datapad_SelectedDoors or {}
            
            -- Toggle
            local found = false
            for k, v in pairs(ply.Datapad_SelectedDoors) do
                if v == ent then
                    table.remove(ply.Datapad_SelectedDoors, k)
                    found = true
                    break
                end
            end
            
            if found then
                ply:ChatPrint("[-] Puerta removida de la selección. (Total: " .. table.Count(ply.Datapad_SelectedDoors) .. ")")
            else
                table.insert(ply.Datapad_SelectedDoors, ent)
                ply:ChatPrint("[+] Puerta guardada (" .. ent:GetClass() .. "). Pon un keypad para enlazar. (Total: " .. table.Count(ply.Datapad_SelectedDoors) .. ")")
            end
        else
            ply:ChatPrint("No estás mirando a una entidad válida.")
        end
        return ""
    end
end)
