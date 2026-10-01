-- =========================================================================
-- SISTEMA DE ESCÁNER 65TH (Datapad 3D)
-- =========================================================================

if SERVER then
    util.AddNetworkString("Datapad_Scan_Start")
    util.AddNetworkString("Datapad_Scan_Stop")
    util.AddNetworkString("Datapad_Scan_Alert")
    util.AddNetworkString("Datapad_Scan_Accept")
    util.AddNetworkString("Datapad_Scan_Result")
    
    local ActiveScans = {} -- Tracking active scans: [scannerPly] = { target = targetPly, endTime = CurTime() + 3 }
    
    local function GetJobName(ply)
        if team and team.GetName then
            return team.GetName(ply:Team()) or "Civil"
        end
        return "Desconocido"
    end
    
    local function GetIDCode(ply)
        local acc = tostring(ply:AccountID())
        return "ID-" .. string.sub(acc, math.max(1, #acc - 4))
    end
    
    local function FormatTargetData(ply)
        local nick = ply:Nick()
        local jobName = string.upper(GetJobName(ply))
        local numbers = nil
        
        -- Buscar el número que más parezca un ID (Ignorando 5th, 104th, etc.)
        for word in string.gmatch(nick, "%S+") do
            local n = string.match(word, "%d+")
            if n then
                if string.match(string.lower(word), "%d+[a-z]+") then
                    if not numbers then numbers = n end
                else
                    numbers = n
                end
            end
        end
        
        -- Verificar si el Job es de una facción imperial
        local isImperialJob = false
        if Datapad and Datapad.IsImperial then
            isImperialJob = Datapad:IsImperial(ply)
        end
        
        -- Si no tiene números, pero es imperial, usa su SteamID como números
        if not numbers and isImperialJob then
            local acc = tostring(ply:AccountID())
            numbers = string.sub(acc, math.max(1, #acc - 4))
        end
        
        -- Extraer siempre la última palabra (Apellido/Nombre clave)
        local lastWord = string.match(nick, "[^%s]+$") or nick
        
        if numbers then
            local prefix = "CT"
            
            -- Detectar prefijo según el nombre del Job (Prioridades)
            if string.find(jobName, "ISB") then
                prefix = "ISB"
            elseif string.find(jobName, "ARC") then
                prefix = "ARC"
            elseif string.find(jobName, "CLON COMANDO") then
                prefix = "IC"
            elseif string.find(jobName, "COMANDANTE") then
                prefix = "CC"
            end
            
            return lastWord, prefix .. "-" .. numbers
        else
            -- Es Civil
            return lastWord, GetIDCode(ply)
        end
    end
    
    local function FinishScan(scanner, target)
        if not IsValid(scanner) or not IsValid(target) then return end
        
        -- Ocultar alerta en la víctima
        net.Start("Datapad_Scan_Alert")
            net.WriteBool(false)
        net.Send(target)
        
        local finalName, finalID = FormatTargetData(target)
        
        -- Check database
        local isCivilian = string.StartWith(finalID, "ID-")
        local record = { arrests = 0, warrant = false }
        if IvoDB and IvoDB.GetRecord then
            record = IvoDB.GetRecord(target, isCivilian)
        end
        
        -- Enviar datos al datapad del escáner
        net.Start("Datapad_Scan_Result")
            net.WriteString(finalName)
            net.WriteString(GetJobName(target))
            net.WriteString(finalID)
            net.WriteEntity(target)
            net.WriteUInt(record.arrests, 16)
            net.WriteBool(record.warrant)
        net.Send(scanner)
        
        ActiveScans[scanner] = nil
    end

    net.Receive("Datapad_Scan_Start", function(len, ply)
        local target = net.ReadEntity()
        if not IsValid(target) or not target:IsPlayer() then return end
        
        -- Validar distancia (max 80 unidades por compensación de lag ~ 1.5 metros)
        if ply:GetPos():DistToSqr(target:GetPos()) > 6400 then return end
        
        ActiveScans[ply] = { target = target, endTime = CurTime() + 3 }
        
        -- Alertar a la víctima
        net.Start("Datapad_Scan_Alert")
            net.WriteBool(true)
        net.Send(target)
    end)
    
    net.Receive("Datapad_Scan_Stop", function(len, ply)
        local scanData = ActiveScans[ply]
        if scanData and IsValid(scanData.target) then
            -- Borrar alerta en la víctima si el escáner se cancela
            net.Start("Datapad_Scan_Alert")
                net.WriteBool(false)
            net.Send(scanData.target)
        end
        ActiveScans[ply] = nil
    end)
    
    net.Receive("Datapad_Scan_Accept", function(len, ply)
        -- Si la víctima presiona E, completamos todos los escaneos dirigidos a ella
        for scanner, data in pairs(ActiveScans) do
            if data.target == ply then
                FinishScan(scanner, ply)
            end
        end
    end)
    
    -- Tick del servidor para verificar escaneos completados por tiempo
    hook.Add("Think", "Datapad_Scan_Think", function()
        for scanner, data in pairs(ActiveScans) do
            if not IsValid(scanner) or not IsValid(data.target) or CurTime() >= data.endTime then
                if IsValid(scanner) and IsValid(data.target) then
                    -- Verificar distancia nuevamente
                    if scanner:GetPos():DistToSqr(data.target:GetPos()) <= 6400 then
                        FinishScan(scanner, data.target)
                    else
                        ActiveScans[scanner] = nil
                        net.Start("Datapad_Scan_Alert")
                            net.WriteBool(false)
                        net.Send(data.target)
                    end
                else
                    ActiveScans[scanner] = nil
                end
            end
        end
    end)
end

if CLIENT then
    surface.CreateFont("Datapad_ScanAlert", { font = "Roboto", size = 24, weight = 800 })
    surface.CreateFont("Datapad_ScanSub", { font = "Roboto", size = 18, weight = 400 })

    local isBeingScanned = false
    
    net.Receive("Datapad_Scan_Alert", function()
        isBeingScanned = net.ReadBool()
        if isBeingScanned then
            surface.PlaySound("buttons/blip1.wav")
        end
    end)
    
    net.Receive("Datapad_Scan_Result", function()
        local name = net.ReadString()
        local job = net.ReadString()
        local id = net.ReadString()
        local ent = net.ReadEntity()
        local arrests = net.ReadUInt(16)
        local warrant = net.ReadBool()
        
        local ply = LocalPlayer()
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_ivo_datapad" then
            wep.ScanResult_Name = name
            wep.ScanResult_Job = job
            wep.ScanResult_ID = id
            wep.ScanResult_Ent = ent
            wep.ScanResult_Arrests = arrests
            wep.ScanResult_Warrant = warrant
            
            wep.ScanHistory = wep.ScanHistory or {}
            table.insert(wep.ScanHistory, 1, {
                name = name,
                job = job,
                isCivilian = string.StartWith(id, "ID-"),
                warrant = warrant,
                arrests = arrests
            })
            if #wep.ScanHistory > 10 then
                table.remove(wep.ScanHistory)
            end
            
            if wep.SetDatapadState then
                wep:SetDatapadState("scan_result")
                surface.PlaySound("buttons/button14.wav")
            end
        end
    end)
    
    hook.Add("HUDPaint", "Datapad_Scan_HUD", function()
        if not isBeingScanned then return end
        
        local scrW, scrH = ScrW(), ScrH()
        local boxW, boxH = 650, 80
        local cx, cy = scrW/2, scrH/2 + 200
        
        -- Efecto de pulso rojo
        local pulse = math.abs(math.sin(CurTime() * 8)) * 100 + 155
        
        draw.RoundedBox(8, cx - boxW/2, cy - boxH/2, boxW, boxH, Color(15, 15, 20, 240))
        surface.SetDrawColor(255, 50, 50, pulse)
        surface.DrawOutlinedRect(cx - boxW/2, cy - boxH/2, boxW, boxH, 2)
        
        draw.SimpleText("⚠️ INSPECCIÓN DE IDENTIDAD (65TH)", "Datapad_ScanAlert", cx, cy - 15, Color(255, 50, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Te están escaneando. Presiona [E] para cooperar y presentar identificación rápidamente.", "Datapad_ScanSub", cx, cy + 15, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)
    
    hook.Add("KeyPress", "Datapad_Scan_Accept_Key", function(ply, key)
        if key == IN_USE and isBeingScanned then
            isBeingScanned = false -- predicción cliente
            net.Start("Datapad_Scan_Accept")
            net.SendToServer()
            surface.PlaySound("buttons/button24.wav")
        end
    end)
end
