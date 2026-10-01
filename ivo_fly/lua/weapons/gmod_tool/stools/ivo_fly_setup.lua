TOOL.Category = "Ivo Fly"
TOOL.Name = "Constructor de Plataformas"
TOOL.Command = nil
TOOL.ConfigName = ""

local cv = CreateConVar("ivo_fly_tool_enabled", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Muestra u oculta la tool de Ivo Fly en el menu Q")
TOOL.AddToMenu = cv:GetBool()

if CLIENT then
    language.Add("tool.ivo_fly_setup.name", "Ivo Fly - Constructor")
    language.Add("tool.ivo_fly_setup.desc", "Crea plataformas de aterrizaje holográficas y consolas.")
    language.Add("tool.ivo_fly_setup.0", "Click Izquierdo: Fijar P1 / P2 de plataforma | Click Derecho: Crear Consola | Recargar: Cancelar / Borrar Todo")
    
    local p1 = nil
    net.Receive("IvoFly_ToolP1", function()
        local has = net.ReadBool()
        if has then
            p1 = net.ReadVector()
        else
            p1 = nil
        end
    end)
    
    hook.Add("PostDrawTranslucentRenderables", "IvoFly_ToolPreview", function()
        if p1 then
            local ply = LocalPlayer()
            if not IsValid(ply:GetActiveWeapon()) or ply:GetActiveWeapon():GetClass() ~= "gmod_tool" then return end
            
            local tool = ply:GetTool()
            if tool and tool.Mode == "ivo_fly_setup" then
                local tr = ply:GetEyeTrace()
                local p2 = tr.HitPos
                
                local min = Vector(math.min(p1.x, p2.x), math.min(p1.y, p2.y), math.min(p1.z, p2.z))
                local max = Vector(math.max(p1.x, p2.x), math.max(p1.y, p2.y), math.max(p1.z, p2.z))
                max.z = min.z + 800
                
                render.SetColorMaterial()
                render.DrawWireframeBox(Vector(0,0,0), Angle(0,0,0), min, max, Color(255, 100, 0, 255), true)
            end
        end
    end)
    
    function TOOL.BuildCPanel(panel)
        panel:AddControl("Header", {Text = "Constructor de Plataformas", Description = "Crea zonas y consolas para tus naves."})
        panel:AddControl("Button", {Label = "Guardar Zonas y Consolas", Command = "ivo_fly_save"})
        panel:AddControl("Button", {Label = "Borrar Todo (Reset)", Command = "ivo_fly_clear"})
        panel:AddControl("Button", {Label = "Mostrar/Ocultar Hologramas", Command = "ivo_fly_toggle_pads"})
    end
end

if SERVER then
    util.AddNetworkString("IvoFly_ToolP1")
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsSuperAdmin() then return false end
    
    if not ply.IvoFlyP1 then
        ply.IvoFlyP1 = trace.HitPos
        ply:ChatPrint("[Ivo Fly] Punto 1 fijado. Camina y dispara en otra esquina para crear la zona.")
        
        net.Start("IvoFly_ToolP1")
        net.WriteBool(true)
        net.WriteVector(ply.IvoFlyP1)
        net.Send(ply)
    else
        local p1 = ply.IvoFlyP1
        local p2 = trace.HitPos
        
        local min = Vector(math.min(p1.x, p2.x), math.min(p1.y, p2.y), math.min(p1.z, p2.z))
        local max = Vector(math.max(p1.x, p2.x), math.max(p1.y, p2.y), math.max(p1.z, p2.z))
        max.z = min.z + 800
        
        table.insert(IvoFly.Zones, {min = min, max = max})
        
        ply.IvoFlyP1 = nil
        net.Start("IvoFly_ToolP1")
        net.WriteBool(false)
        net.Send(ply)
        
        ply:ChatPrint("[Ivo Fly] ¡Plataforma creada! No olvides usar el comando ivo_fly_save")
        
        -- Sync zones immediately
        net.Start("IvoFly_SyncZones")
        net.WriteUInt(#IvoFly.Zones, 8)
        for _, z in ipairs(IvoFly.Zones) do
            net.WriteVector(z.min)
            net.WriteVector(z.max)
        end
        net.Broadcast()
    end
    return true
end

function TOOL:RightClick(trace)
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsSuperAdmin() then return false end
    
    local cons = ents.Create("ivo_fly_console")
    cons:SetPos(trace.HitPos + trace.HitNormal * 10)
    
    local ang = (ply:GetPos() - trace.HitPos):Angle()
    ang.p = 0
    cons:SetAngles(ang)
    
    cons:Spawn()
    
    ply:ChatPrint("[Ivo Fly] Consola creada. Acomódala con la Physgun y luego usa ivo_fly_save.")
    return true
end

function TOOL:Reload(trace)
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsSuperAdmin() then return false end
    
    if ply.IvoFlyP1 then
        ply.IvoFlyP1 = nil
        net.Start("IvoFly_ToolP1")
        net.WriteBool(false)
        net.Send(ply)
        ply:ChatPrint("[Ivo Fly] P1 Cancelado.")
    else
        ply:ConCommand("ivo_fly_clear")
    end
    return true
end
