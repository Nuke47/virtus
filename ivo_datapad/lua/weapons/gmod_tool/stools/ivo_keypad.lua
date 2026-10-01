TOOL.Category = "Datapad"
TOOL.Name = "Keypad Slicer"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add("tool.ivo_keypad.name", "Datapad Keypad")
    language.Add("tool.ivo_keypad.desc", "Coloca un keypad hackeable. Permite vincular múltiples puertas.")
    language.Add("tool.ivo_keypad.0", "Click Izq: Colocar Keypad | Click Der: Añadir/Quitar Puerta | Recargar (R): Limpiar selección.")
end

function TOOL:LeftClick(trace)
    if not trace.HitPos then return false end
    if CLIENT then return true end

    local ply = self:GetOwner()
    local ent = ents.Create("ivo_keypad")
    if not IsValid(ent) then return false end

    ent:SetPos(trace.HitPos)
    local angle = trace.HitNormal:Angle()
    angle:RotateAroundAxis(angle:Right(), -90)
    angle:RotateAroundAxis(angle:Up(), 180)
    ent:SetAngles(angle)
    
    ent:Spawn()
    ent:Activate()
    
    -- Por defecto, los keypads de toolgun están bloqueados para forzar el hackeo
    ent:SetAccessJobs("LOCKED")

    ply.Datapad_SelectedDoors = ply.Datapad_SelectedDoors or {}

    -- Asignar las puertas seleccionadas
    if table.Count(ply.Datapad_SelectedDoors) > 0 then
        -- Guardar la tabla en la entidad del keypad
        ent.TargetDoors = table.Copy(ply.Datapad_SelectedDoors)
        
        local count = 0
        for _, door in pairs(ent.TargetDoors) do
            if IsValid(door) then
                door:Fire("Close")
                door:Fire("Lock")
                count = count + 1
            end
        end
        
        ply:ChatPrint("Keypad colocado y enlazado a " .. count .. " puerta(s). Todas han sido BLOQUEADAS.")
        
        -- Limpiar la memoria para los próximos keypads
        table.Empty(ply.Datapad_SelectedDoors)
    else
        ply:ChatPrint("Keypad colocado (Sin puertas enlazadas. Buscará en un radio cercano).")
    end

    -- Congelar el prop a la pared
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end

    undo.Create("Datapad Keypad")
        undo.AddEntity(ent)
        undo.SetPlayer(ply)
    undo.Finish()

    return true
end

function TOOL:RightClick(trace)
    local ent = trace.Entity
    if not IsValid(ent) then return false end

    if SERVER then
        if ent:IsWorld() then
            self:GetOwner():ChatPrint("No puedes seleccionar el mapa.")
            return false
        end

        local ply = self:GetOwner()
        ply.Datapad_SelectedDoors = ply.Datapad_SelectedDoors or {}

        -- Toggle (Añadir o quitar si ya está)
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
            ply:ChatPrint("[+] Puerta añadida a la selección (" .. ent:GetClass() .. "). (Total: " .. table.Count(ply.Datapad_SelectedDoors) .. ")")
        end
        return true
    end
    return true
end

function TOOL:Reload(trace)
    if SERVER then
        local ply = self:GetOwner()
        ply.Datapad_SelectedDoors = {}
        ply:ChatPrint("Lista de puertas limpiada. (0 seleccionadas)")
    end
    return true
end

function TOOL.BuildCPanel(panel)
    panel:AddControl("Header", {Text = "Datapad Keypad", Description = "Coloca keypads en paredes cerca de puertas para que puedan ser hackeados con el Datapad."})
end
