TOOL.Category = "Ivo Tools"
TOOL.Name = "NPC Spawner"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["class"] = "npc_droid_b1"
TOOL.ClientConVar["key_mode"] = "1"
TOOL.ClientConVar["key_move"] = "2"

if CLIENT then
    language.Add("tool.ivo_npc_spawner.name", "NPC Spawner")
    language.Add("tool.ivo_npc_spawner.desc", "Spawnea NPCs y gestiona sus controles.")
    language.Add("tool.ivo_npc_spawner.0", "Click Izquierdo: Spawnear NPC | Click Derecho: Remover NPC apuntado")
end

function TOOL:LeftClick(trace)
    if not trace.Hit then return false end
    if CLIENT then return true end
    
    local ply = self:GetOwner()
    local class = self:GetClientInfo("class")
    
    if class == "" then return false end

    if not self:GetWeapon():CheckLimit("npcs") then return false end

    local spawnPos = trace.HitPos + trace.HitNormal * 10
    
    local ent = ents.Create(class)
    if not IsValid(ent) then return false end
    
    ent:SetPos(spawnPos)
    
    -- Face the player
    local angle = (ply:GetPos() - spawnPos):Angle()
    angle.pitch = 0
    angle.roll = 0
    ent:SetAngles(angle)
    
    ent:Spawn()
    ent:Activate()
    
    -- Establecer el dueño para los comandos de RTS
    ent:SetNWEntity("CommanderOwner", ply)
    
    -- Register undo
    undo.Create("NPC")
        undo.AddEntity(ent)
        undo.SetPlayer(ply)
    undo.Finish()
    
    ply:AddCount("npcs", ent)
    ply:AddCleanup("npcs", ent)
    
    -- (Removed buggy numpad.OnDown bindings to fix ping/lag issue)
    
    return true
end

function TOOL:RightClick(trace)
    if not trace.Hit then return false end
    if CLIENT then return true end
    
    local ent = trace.Entity
    if IsValid(ent) and (ent:IsNPC() or ent:IsNextBot()) then
        ent:Remove()
        return true
    end
    
    return false
end

if CLIENT then
    function TOOL:DrawHUD()
        local ply = LocalPlayer()
        local passive = ply:GetNWBool("IVO_RTS_Passive", false)
        local holdpos = ply:GetNWBool("IVO_RTS_HoldPos", false)
        
        local modeText = passive and "Pasivo" or "Agresivo"
        local modeColor = passive and Color(100, 255, 100) or Color(255, 100, 100)
        
        local moveText = holdpos and "Estático" or "Libre"
        local moveColor = holdpos and Color(255, 200, 50) or Color(100, 200, 255)
        
        surface.SetFont("Trebuchet24")
        
        local t1 = "Modo Combate: "
        local tw1, th1 = surface.GetTextSize(t1)
        
        local t2 = "Modo Movimiento: "
        local tw2, th2 = surface.GetTextSize(t2)
        
        local x = ScrW() / 2 + 50
        local y = ScrH() / 2 + 50
        
        draw.SimpleTextOutlined(t1, "Trebuchet24", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
        draw.SimpleTextOutlined(modeText, "Trebuchet24", x + tw1, y, modeColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
        
        draw.SimpleTextOutlined(t2, "Trebuchet24", x, y + th1 + 5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
        draw.SimpleTextOutlined(moveText, "Trebuchet24", x + tw2, y + th1 + 5, moveColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
    end
end

if SERVER then
    hook.Add("PlayerButtonDown", "Ivo_NPC_NumpadHooks", function(ply, btn)
        -- Leer convars para obtener la tecla de cada modo
        local key_mode = ply:GetInfoNum("ivo_npc_spawner_key_mode", -1)
        local key_move = ply:GetInfoNum("ivo_npc_spawner_key_move", -1)
        
        if key_mode > 0 and btn == key_mode then
            local current = ply:GetNWBool("IVO_RTS_Passive", false)
            ply:SetNWBool("IVO_RTS_Passive", not current)
            ply:ChatPrint("Tus droides ahora están en modo combate: " .. (not current and "Pasivo" or "Agresivo"))
        elseif key_move > 0 and btn == key_move then
            local current = ply:GetNWBool("IVO_RTS_HoldPos", false)
            ply:SetNWBool("IVO_RTS_HoldPos", not current)
            ply:ChatPrint("Tus droides ahora están en modo movimiento: " .. (not current and "Estático (Mantener posición)" or "Libre"))
        end
    end)
end

function TOOL.BuildCPanel(CPanel)
    CPanel:AddControl("Header", { Description = "Selecciona un NPC y configura las teclas para controlarlos." })
    
    local options = {}
    for class, data in pairs(list.Get("NPC")) do
        if data.Category == "Star Wars" or string.find(class, "npc_droid_") or string.find(class, "npc_pirate_") then
            options[data.Name or class] = { ivo_npc_spawner_class = class }
        end
    end
    
    CPanel:AddControl("ComboBox", {
        Label = "NPC a Spawnear",
        MenuButton = "0",
        Options = options
    })
    
    CPanel:AddControl("Numpad", {
        Label = "Alternar Ataque/Pasivo",
        Command = "ivo_npc_spawner_key_mode",
    })
    
    CPanel:AddControl("Numpad", {
        Label = "Alternar Movimiento Libre/Quieto",
        Command = "ivo_npc_spawner_key_move",
    })
end
