-- Utilidades generales del Framework compartidas (Server/Client)
IVO_FW.Utils = IVO_FW.Utils or {}

-- Función para formatear números (ej: 1000 -> 1,000)
function IVO_FW.Utils.FormatNumber(amount)
    local formatted = amount
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then
            break
        end
    end
    return formatted
end

if SERVER then
    -- Enviar notificación a un jugador
    function IVO_FW.Utils.Notify(ply, msg, msgType, length)
        -- Compatible con DarkRP, etc.
        if DarkRP and DarkRP.notify then
            DarkRP.notify(ply, msgType or 0, length or 4, msg)
        else
            ply:ChatPrint("[IVO] " .. msg)
        end
    end
end

if CLIENT then
    -- Imprimir mensaje en el chat con colores
    function IVO_FW.Utils.ChatPrint(msg)
        chat.AddText(IVO_FW.Theme.Colors.Accent, "[IVO] ", color_white, msg)
    end
    
    -- Utilidad para escalar tamaños en pantallas diferentes
    function IVO_FW.Utils.Scale(size)
        return size * (ScrH() / 1080)
    end
end
