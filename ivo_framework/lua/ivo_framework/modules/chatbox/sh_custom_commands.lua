if SERVER then
    util.AddNetworkString("VirtusChat_CustomCommand")

    local commands = {
        ["/imp"] = { tag = "IMPERIO", color = Color(200, 0, 0), global = true },
        ["/reb"] = { tag = "REBELION", color = Color(255, 100, 0), global = true },
        ["/cr"] = { tag = "CRIMINALES", color = Color(100, 100, 100), global = true },
        ["/a"] = { tag = "PUBLICO", color = Color(0, 200, 255), global = true },
        ["/acc"] = { tag = "ACCION", color = Color(180, 80, 255), global = true },
        ["/accion"] = { tag = "ACCION", color = Color(180, 80, 255), global = true },
        ["/me"] = { tag = "ME", color = Color(255, 200, 0), global = false, range = 300 },
        ["/comms"] = { tag = "COMMS", color = Color(50, 255, 100), global = false, isRadio = true },
        ["!comms"] = { tag = "COMMS", color = Color(50, 255, 100), global = false, isRadio = true }
    }

    -- Prioridad alta para anular comandos base si es necesario
    hook.Add("PlayerSay", "VirtusChat_CommandsHook", function(ply, text, teamChat)
        local args = string.Explode(" ", text)
        local cmd = string.lower(args[1] or "")
        
        if commands[cmd] then
            local msg = string.sub(text, string.len(args[1]) + 2)
            if string.Trim(msg) == "" then return "" end
            
            local cmdData = commands[cmd]
            
            if cmdData.global then
                net.Start("VirtusChat_CustomCommand")
                net.WriteEntity(ply)
                net.WriteString(cmdData.tag)
                net.WriteColor(cmdData.color)
                net.WriteString(msg)
                net.Broadcast()
            elseif cmdData.isRadio then
                local miCanal = _G.PlayerRadioChannels and _G.PlayerRadioChannels[ply:SteamID64()]
                
                if not miCanal then
                    ply:ChatPrint("[Radio] No estás conectado a ninguna frecuencia.")
                    return ""
                end
                
                local canalNombre = "RADIO"
                if RadioFrequencies then
                    for _, data in ipairs(RadioFrequencies) do
                        if data.channel == miCanal then
                            canalNombre = data.name
                            break
                        end
                    end
                end
                
                net.Start("VirtusChat_CustomCommand")
                net.WriteEntity(ply)
                net.WriteString(canalNombre)
                net.WriteColor(cmdData.color)
                net.WriteString(msg)
                
                local receivers = {}
                for _, p in ipairs(player.GetAll()) do
                    local suCanal = _G.PlayerRadioChannels and _G.PlayerRadioChannels[p:SteamID64()]
                    if suCanal == miCanal then
                        table.insert(receivers, p)
                    end
                end
                net.Send(receivers)
            else
                net.Start("VirtusChat_CustomCommand")
                net.WriteEntity(ply)
                net.WriteString(cmdData.tag)
                net.WriteColor(cmdData.color)
                net.WriteString(msg)
                
                -- Chat local
                local receivers = {}
                for _, p in ipairs(player.GetAll()) do
                    if p:GetPos():DistToSqr(ply:GetPos()) <= (cmdData.range * cmdData.range) then
                        table.insert(receivers, p)
                    end
                end
                net.Send(receivers)
            end
            
            MsgC(cmdData.color, "[" .. cmdData.tag .. "] ", ply, Color(255,255,255), ": " .. msg .. "\n")
            
            return "" -- Evita que el chat normal o DarkRP lo procese
        end
    end)
else
    net.Receive("VirtusChat_CustomCommand", function()
        local ply = net.ReadEntity()
        local tag = net.ReadString()
        local tagColor = net.ReadColor()
        local msg = net.ReadString()
        
        if not IsValid(ply) then return end
        
        local isAction = (tag == "ACCION" or tag == "ME")
        local sep = isAction and " " or ": "
        local msgColor = isAction and tagColor or Color(255, 255, 255)
        
        chat.AddText(
            { customRank = tag, customRankColor = tagColor, isAction = isAction },
            ply,
            msgColor,
            sep .. msg
        )
    end)
end
