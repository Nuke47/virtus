if SERVER then AddCSLuaFile() end
IvoFly = IvoFly or {}
IvoFly.Zones = IvoFly.Zones or {}
IvoFly.ActiveVehicles = IvoFly.ActiveVehicles or 0
IvoFly.DataDir = "ivo_fly"

if SERVER then
    util.AddNetworkString("IvoFly_OpenMenu")
    util.AddNetworkString("IvoFly_Action")
    util.AddNetworkString("IvoFly_Notification")
    util.AddNetworkString("IvoFly_SyncZones")
    util.AddNetworkString("IvoFly_ReloadMenu")

    if not file.Exists(IvoFly.DataDir, "DATA") then
        file.CreateDir(IvoFly.DataDir)
    end

    function IvoFly.SaveZones()
        local data = {}
        for _, z in ipairs(IvoFly.Zones) do
            table.insert(data, {
                min = {x = z.min.x, y = z.min.y, z = z.min.z},
                max = {x = z.max.x, y = z.max.y, z = z.max.z}
            })
        end
        file.Write(IvoFly.DataDir .. "/zones_" .. game.GetMap() .. ".txt", util.TableToJSON(data))
    end

    function IvoFly.SaveConsole()
        local data = {}
        for _, cons in ipairs(ents.FindByClass("ivo_fly_console")) do
            local p = cons:GetPos()
            local a = cons:GetAngles()
            table.insert(data, {
                pos = {x = p.x, y = p.y, z = p.z},
                ang = {p = a.p, y = a.y, r = a.r}
            })
        end
        file.Write(IvoFly.DataDir .. "/console_" .. game.GetMap() .. ".txt", util.TableToJSON(data))
    end

    function IvoFly.LoadData()
        local zonesFile = IvoFly.DataDir .. "/zones_" .. game.GetMap() .. ".txt"
        if file.Exists(zonesFile, "DATA") then
            local data = util.JSONToTable(file.Read(zonesFile, "DATA"))
            if data then
                for _, v in ipairs(data) do
                    table.insert(IvoFly.Zones, {
                        min = Vector(v.min.x, v.min.y, v.min.z),
                        max = Vector(v.max.x, v.max.y, v.max.z)
                    })
                end
            end
        end

        local consoleFile = IvoFly.DataDir .. "/console_" .. game.GetMap() .. ".txt"
        if file.Exists(consoleFile, "DATA") then
            local data = util.JSONToTable(file.Read(consoleFile, "DATA"))
            if data then
                for _, v in ipairs(data) do
                    local cons = ents.Create("ivo_fly_console")
                    cons:SetPos(Vector(v.pos.x, v.pos.y, v.pos.z))
                    cons:SetAngles(Angle(v.ang.p, v.ang.y, v.ang.r))
                    cons:Spawn()
                    
                    cons.IvoFlySaved = true
                    local phys = cons:GetPhysicsObject()
                    if IsValid(phys) then phys:EnableMotion(false) end
                end
            end
        end
    end

    hook.Add("InitPostEntity", "IvoFly_Load", function()
        IvoFly.LoadData()
    end)

    hook.Add("PostCleanupMap", "IvoFly_LoadCleanup", function()
        IvoFly.Zones = {}
        IvoFly.ActiveVehicles = 0
        IvoFly.LoadData()
    end)

    hook.Add("PhysgunPickup", "IvoFly_BlockPhysgun", function(ply, ent)
        if ent:GetClass() == "ivo_fly_console" and ent.IvoFlySaved then
            return false
        end
    end)

    net.Receive("IvoFly_Action", function(len, ply)
        local action = net.ReadString()
        local zoneIndex = net.ReadUInt(8)
        local class = net.ReadString()
        
        local zone = IvoFly.Zones[zoneIndex]
        if not zone then return end

        if action == "spawn" then
            if IvoFly.ActiveVehicles >= 5 then
                net.Start("IvoFly_Notification")
                net.WriteString("Se ha alcanzado el límite de 5 naves desplegadas.")
                net.Send(ply)
                return
            end
            
            local occupied = false
            for _, ent in ipairs(ents.FindInBox(zone.min, zone.max)) do
                if ent:IsVehicle() or ent.LVS then
                    occupied = true
                    break
                end
            end
            
            if occupied then
                net.Start("IvoFly_Notification")
                net.WriteString("La plataforma de despliegue está ocupada.")
                net.Send(ply)
                return
            end
            
            local veh = ents.Create(class)
            if not IsValid(veh) then return end
            
            local initialPos = Vector((zone.min.x + zone.max.x)/2, (zone.min.y + zone.max.y)/2, zone.min.z + 50)
            veh:SetPos(initialPos)
            veh:SetAngles(Angle(0,180,0))
            veh:Spawn()
            
            local centerPos = Vector((zone.min.x + zone.max.x)/2, (zone.min.y + zone.max.y)/2, zone.min.z + 10)
            local offset = veh:OBBCenter()
            offset:Rotate(Angle(0,180,0))
            centerPos.x = centerPos.x - offset.x
            centerPos.y = centerPos.y - offset.y
            centerPos.z = centerPos.z - veh:OBBMins().z
            
            veh:SetPos(centerPos)
            veh.IvoFlySpawned = true
            veh:Activate()
            
            IvoFly.ActiveVehicles = IvoFly.ActiveVehicles + 1
            
            net.Start("IvoFly_Notification")
            net.WriteString("Nave desplegada con éxito.")
            net.Send(ply)
            
        elseif action == "delete" then
            local foundVeh = nil
            local hasPlayers = false
            
            for _, ent in ipairs(ents.FindInBox(zone.min, zone.max)) do
                if ent.IvoFlySpawned then
                    foundVeh = ent
                    if IsValid(ent:GetDriver()) then hasPlayers = true end
                    for _, child in ipairs(ent:GetChildren()) do
                        if child:IsVehicle() and IsValid(child:GetDriver()) then
                            hasPlayers = true
                        end
                    end
                    break
                end
            end
            
            if foundVeh then
                if hasPlayers then
                    net.Start("IvoFly_Notification")
                    net.WriteString("No se puede borrar la nave: hay tripulantes a bordo.")
                    net.Send(ply)
                else
                    foundVeh:Remove()
                    IvoFly.ActiveVehicles = math.max(0, IvoFly.ActiveVehicles - 1)
                    net.Start("IvoFly_Notification")
                    net.WriteString("Nave recogida con éxito.")
                    net.Send(ply)
                end
            else
                net.Start("IvoFly_Notification")
                net.WriteString("No hay ninguna nave generada por consola en la plataforma.")
                net.Send(ply)
            end
        end
    end)

    local function HasPassengers(ent)
        if IsValid(ent:GetDriver()) then return true end
        for _, child in ipairs(ent:GetChildren()) do
            if child:IsVehicle() and IsValid(child:GetDriver()) then
                return true
            end
        end
        return false
    end

    hook.Add("Think", "IvoFly_AutoDelete", function()
        if not IvoFly.NextAutoDeleteThink then IvoFly.NextAutoDeleteThink = 0 end
        if CurTime() < IvoFly.NextAutoDeleteThink then return end
        IvoFly.NextAutoDeleteThink = CurTime() + 5
        
        local activeCount = 0
        for _, ent in ipairs(ents.GetAll()) do
            if ent.IvoFlySpawned then
                activeCount = activeCount + 1
                
                if HasPassengers(ent) then
                    ent.IvoFlyEmptySince = nil
                else
                    if not ent.IvoFlyEmptySince then
                        ent.IvoFlyEmptySince = CurTime()
                    end
                    
                    if CurTime() - ent.IvoFlyEmptySince > 120 then
                        ent:Remove()
                        activeCount = activeCount - 1
                    end
                end
            end
        end
        IvoFly.ActiveVehicles = activeCount
    end)

    concommand.Add("ivo_fly_p1", function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        ply.IvoFlyP1 = ply:GetEyeTrace().HitPos
        ply:ChatPrint("[Ivo Fly] Punto 1 fijado.")
    end)

    concommand.Add("ivo_fly_p2", function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        ply.IvoFlyP2 = ply:GetEyeTrace().HitPos
        ply:ChatPrint("[Ivo Fly] Punto 2 fijado. Ahora usa ivo_fly_create_pad.")
    end)

    concommand.Add("ivo_fly_create_pad", function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        if not ply.IvoFlyP1 or not ply.IvoFlyP2 then return end

        local min = Vector(math.min(ply.IvoFlyP1.x, ply.IvoFlyP2.x), math.min(ply.IvoFlyP1.y, ply.IvoFlyP2.y), math.min(ply.IvoFlyP1.z, ply.IvoFlyP2.z))
        local max = Vector(math.max(ply.IvoFlyP1.x, ply.IvoFlyP2.x), math.max(ply.IvoFlyP1.y, ply.IvoFlyP2.y), math.max(ply.IvoFlyP1.z, ply.IvoFlyP2.z))
        max.z = min.z + 800

        table.insert(IvoFly.Zones, {min = min, max = max})
        ply:ChatPrint("[Ivo Fly] Plataforma de aterrizaje creada. Usa ivo_fly_save para guardar.")
        
        net.Start("IvoFly_SyncZones")
        net.WriteUInt(#IvoFly.Zones, 8)
        for _, z in ipairs(IvoFly.Zones) do
            net.WriteVector(z.min)
            net.WriteVector(z.max)
        end
        net.Broadcast()
    end)

    concommand.Add("ivo_fly_save", function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        
        for _, cons in ipairs(ents.FindByClass("ivo_fly_console")) do
            cons.IvoFlySaved = true
            local phys = cons:GetPhysicsObject()
            if IsValid(phys) then phys:EnableMotion(false) end
        end
        
        IvoFly.SaveZones()
        IvoFly.SaveConsole()
        ply:ChatPrint("[Ivo Fly] Consolas y zonas guardadas.")
    end)
    
    concommand.Add("ivo_fly_clear", function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        
        for _, ent in ipairs(ents.FindByClass("ivo_fly_console")) do ent:Remove() end
        IvoFly.Zones = {}
        
        file.Delete(IvoFly.DataDir .. "/zones_" .. game.GetMap() .. ".txt")
        file.Delete(IvoFly.DataDir .. "/console_" .. game.GetMap() .. ".txt")
        
        ply:ChatPrint("[Ivo Fly] Zonas y consolas borradas (del mapa y archivo).")
        
        net.Start("IvoFly_SyncZones")
        net.WriteUInt(0, 8)
        net.Broadcast()
    end)
    
    concommand.Add("ivo_fly_toggle_tool", function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        
        local cv = GetConVar("ivo_fly_tool_enabled")
        if not cv then return end
        
        local newVal = cv:GetBool() and "0" or "1"
        RunConsoleCommand("ivo_fly_tool_enabled", newVal)
        
        if newVal == "1" then
            ply:ChatPrint("[Ivo Fly] Tool HABILITADA. Aparecerá en tu menú Q (recarga el menú).")
        else
            ply:ChatPrint("[Ivo Fly] Tool DESHABILITADA. Se ocultará de tu menú Q (recarga el menú).")
        end
        
        net.Start("IvoFly_ReloadMenu")
        net.Broadcast()
    end)
    
    hook.Add("PlayerInitialSpawn", "IvoFly_SyncSpawn", function(ply)
        timer.Simple(2, function()
            if IsValid(ply) then
                net.Start("IvoFly_SyncZones")
                net.WriteUInt(#IvoFly.Zones, 8)
                for _, z in ipairs(IvoFly.Zones) do
                    net.WriteVector(z.min)
                    net.WriteVector(z.max)
                end
                net.Send(ply)
            end
        end)
    end)
end

if CLIENT then
    IvoFly.Zones = {}
    
    net.Receive("IvoFly_SyncZones", function()
        local count = net.ReadUInt(8)
        IvoFly.Zones = {}
        for i = 1, count do
            table.insert(IvoFly.Zones, {
                min = net.ReadVector(),
                max = net.ReadVector()
            })
        end
    end)
    
    net.Receive("IvoFly_ReloadMenu", function()
        local cv = GetConVar("ivo_fly_tool_enabled")
        if cv then
            local wep = weapons.GetStored("gmod_tool")
            if wep and wep.Tool and wep.Tool["ivo_fly_setup"] then
                wep.Tool["ivo_fly_setup"].AddToMenu = cv:GetBool()
            end
        end
        if spawnmenu then
            spawnmenu.Reload()
        end
    end)
    
    CreateClientConVar("ivo_fly_show_pads", "0", true, false, "Show Ivo Fly pads")
    
    hook.Add("PostDrawTranslucentRenderables", "IvoFly_DrawZones", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        
        local show = GetConVar("ivo_fly_show_pads"):GetBool()
        local wepClass = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() or ""
        
        if show then
            render.SetColorMaterial()
            for _, z in ipairs(IvoFly.Zones) do
                render.DrawWireframeBox(Vector(0,0,0), Angle(0,0,0), z.min, z.max, Color(0, 255, 255, 255), true)
            end
        end
    end)
    
    concommand.Add("ivo_fly_toggle_pads", function(ply, cmd, args)
        local cv = GetConVar("ivo_fly_show_pads")
        if cv:GetBool() then
            cv:SetBool(false)
            ply:ChatPrint("[Ivo Fly] Zonas ocultas.")
        else
            cv:SetBool(true)
            ply:ChatPrint("[Ivo Fly] Zonas visibles (holograma azul).")
        end
    end)
end
