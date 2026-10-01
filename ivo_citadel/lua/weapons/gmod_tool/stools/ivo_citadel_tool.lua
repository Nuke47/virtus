TOOL.Category = "Ivo"
TOOL.Name = "Configurador de Ciudadelas"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["citadel_name"] = "Ciudadela 1"
TOOL.ClientConVar["mode"] = "0" -- 0: General Area, 1: Spawn Area

if CLIENT then
    language.Add("tool.ivo_citadel_tool.name", "Configurador de Ciudadelas")
    language.Add("tool.ivo_citadel_tool.desc", "Delimita áreas y puntos de spawn para ciudadelas.")
    language.Add("tool.ivo_citadel_tool.0", "Click Izq: Poner punto de caja. Click Der: Borrar última caja. Recargar: Guardar.")
end

function TOOL.BuildCPanel(CPanel)
    CPanel:AddControl("Header", { Text = "Configuración de Ciudadela", Description = "Herramienta para definir zonas." })
    
    CPanel:AddControl("TextBox", {
        Label = "Nombre Ciudadela",
        Command = "ivo_citadel_tool_citadel_name"
    })
    
    CPanel:AddControl("ComboBox", {
        MenuButton = 0,
        Label = "Modo de Herramienta",
        Command = "ivo_citadel_tool_mode",
        Options = {
            ["Área General (Jugadores)"] = { ivo_citadel_tool_mode = "0" },
            ["Área de Spawn (Droides)"] = { ivo_citadel_tool_mode = "1" }
        }
    })
end

if SERVER then
    util.AddNetworkString("IvoCitadel_ToolAddBox")
    util.AddNetworkString("IvoCitadel_ToolRemoveBox")

    net.Receive("IvoCitadel_ToolAddBox", function(len, ply)
        if not ply:IsSuperAdmin() then return end
        
        local mode = net.ReadUInt(2)
        local min = net.ReadVector()
        local max = net.ReadVector()
        local name = net.ReadString()
        if name == "" then name = "Ciudadela 1" end
        
        if not IvoCitadel.Zones[name] then
            IvoCitadel.Zones[name] = { areas = {}, spawn_areas = {} }
        end
        if not IvoCitadel.Zones[name].areas then IvoCitadel.Zones[name].areas = {} end
        if not IvoCitadel.Zones[name].spawn_areas then IvoCitadel.Zones[name].spawn_areas = {} end
        
        if mode == 0 then
            table.insert(IvoCitadel.Zones[name].areas, {min = min, max = max})
            ply:ChatPrint("[Ciudadela - " .. name .. "] Área General agregada.")
        else
            table.insert(IvoCitadel.Zones[name].spawn_areas, {min = min, max = max})
            ply:ChatPrint("[Ciudadela - " .. name .. "] Área de Spawn agregada.")
        end
        
        IvoCitadel.SyncZones()
    end)
    
    net.Receive("IvoCitadel_ToolRemoveBox", function(len, ply)
        if not ply:IsSuperAdmin() then return end
        local mode = net.ReadUInt(2)
        local name = net.ReadString()
        if name == "" then name = "Ciudadela 1" end
        
        if not IvoCitadel.Zones[name] then return end
        
        if mode == 0 and IvoCitadel.Zones[name].areas and #IvoCitadel.Zones[name].areas > 0 then
            table.remove(IvoCitadel.Zones[name].areas)
            ply:ChatPrint("[Ciudadela - " .. name .. "] Última Área General eliminada.")
        elseif mode == 1 and IvoCitadel.Zones[name].spawn_areas and #IvoCitadel.Zones[name].spawn_areas > 0 then
            table.remove(IvoCitadel.Zones[name].spawn_areas)
            ply:ChatPrint("[Ciudadela - " .. name .. "] Última Área de Spawn eliminada.")
        end
        IvoCitadel.SyncZones()
    end)
end

TOOL.Point1 = nil

function TOOL:LeftClick(trace)
    if not trace.Hit then return false end
    
    if CLIENT then
        if not self.Point1 then
            self.Point1 = trace.HitPos
            chat.AddText(Color(0, 255, 0), "Punto 1 fijado. Haz clic para el punto 2 (opuesto).")
        else
            local p2 = trace.HitPos
            local min = Vector(math.min(self.Point1.x, p2.x), math.min(self.Point1.y, p2.y), math.min(self.Point1.z, p2.z))
            local max = Vector(math.max(self.Point1.x, p2.x), math.max(self.Point1.y, p2.y), math.max(self.Point1.z, p2.z))
            
            if math.abs(max.z - min.z) < 10 then max.z = max.z + 150 end
            
            net.Start("IvoCitadel_ToolAddBox")
            net.WriteUInt(tonumber(self:GetClientInfo("mode") or 0), 2)
            net.WriteVector(min)
            net.WriteVector(max)
            net.WriteString(self:GetClientInfo("citadel_name"))
            net.SendToServer()
            
            self.Point1 = nil
        end
    end
    
    return true
end

function TOOL:RightClick(trace)
    if CLIENT then
        if self.Point1 then
            self.Point1 = nil
            chat.AddText(Color(255, 100, 0), "Caja cancelada.")
        else
            net.Start("IvoCitadel_ToolRemoveBox")
            net.WriteUInt(tonumber(self:GetClientInfo("mode") or 0), 2)
            net.WriteString(self:GetClientInfo("citadel_name"))
            net.SendToServer()
        end
    end
    return true
end

function TOOL:Reload(trace)
    if SERVER then
        local ply = self:GetOwner()
        if not ply:IsSuperAdmin() then return false end
        IvoCitadel.SaveZones()
        ply:ChatPrint("[Ciudadela] ¡Todas las ciudadelas GUARDADAS en el disco exitosamente!")
    end
    return true
end

function TOOL:DrawToolScreen(width, height)
    if not CLIENT then return end
    surface.SetDrawColor(30, 30, 30, 255)
    surface.DrawRect(0, 0, width, height)
    draw.SimpleText("Setup Ciudadela", "DermaLarge", width/2, height/2 - 20, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

if CLIENT then
    IvoCitadel = IvoCitadel or {}
    IvoCitadel.ShowZones = false

    concommand.Add("ivo_citadel_toggle_view", function()
        IvoCitadel.ShowZones = not IvoCitadel.ShowZones
        if IvoCitadel.ShowZones then
            chat.AddText(Color(0,255,0), "[Ciudadela] Visualización ACTIVADA.")
        else
            chat.AddText(Color(255,100,0), "[Ciudadela] Visualización DESACTIVADA.")
        end
    end)

    hook.Add("PostDrawOpaqueRenderables", "IvoCitadel_DrawZoneBoxes", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local wep = ply:GetActiveWeapon()
        local isTool = (IsValid(wep) and wep:GetClass() == "gmod_tool" and ply:GetTool() and ply:GetTool().Mode == "ivo_citadel_tool")
        
        if not isTool and not IvoCitadel.ShowZones then return end
        if not IvoCitadel.Zones then return end

        render.SetColorMaterial()

        for name, data in pairs(IvoCitadel.Zones) do
            if data.areas then
                for _, box in ipairs(data.areas) do
                    render.SetColorMaterial()
                    render.DrawBox(Vector(0,0,0), Angle(0,0,0), box.min, box.max, Color(0, 255, 0, 30))
                    render.DrawWireframeBox(Vector(0,0,0), Angle(0,0,0), box.min, box.max, Color(0, 255, 0, 255), true)
                end
            end
            if data.spawn_areas then
                for _, box in ipairs(data.spawn_areas) do
                    render.SetColorMaterial()
                    render.DrawBox(Vector(0,0,0), Angle(0,0,0), box.min, box.max, Color(255, 0, 0, 30))
                    render.DrawWireframeBox(Vector(0,0,0), Angle(0,0,0), box.min, box.max, Color(255, 0, 0, 255), true)
                end
            end
            
            if data.areas and data.areas[1] then
                local b = data.areas[1]
                local center = (b.min + b.max) / 2
                center.z = b.max.z + 50
                cam.Start3D2D(center, Angle(0, ply:EyeAngles().y - 90, 90), 0.5)
                    draw.SimpleText(name, "DermaLarge", 0, -20, Color(0,255,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                cam.End3D2D()
            end
        end
        
        if isTool then
            local tool = ply:GetTool()
            if tool and tool.Point1 then
                local tr = ply:GetEyeTrace()
                if tr.Hit then
                    local p2 = tr.HitPos
                    local min = Vector(math.min(tool.Point1.x, p2.x), math.min(tool.Point1.y, p2.y), math.min(tool.Point1.z, p2.z))
                    local max = Vector(math.max(tool.Point1.x, p2.x), math.max(tool.Point1.y, p2.y), math.max(tool.Point1.z, p2.z))
                    if math.abs(max.z - min.z) < 10 then max.z = max.z + 150 end
                    
                    local color = (tool:GetClientInfo("mode") == "0") and Color(0,255,0,30) or Color(255,0,0,30)
                    local colorWire = (tool:GetClientInfo("mode") == "0") and Color(0,255,0,255) or Color(255,0,0,255)
                    render.SetColorMaterial()
                    render.DrawBox(Vector(0,0,0), Angle(0,0,0), min, max, color)
                    render.DrawWireframeBox(Vector(0,0,0), Angle(0,0,0), min, max, colorWire, true)
                end
            end
        end
    end)
end
