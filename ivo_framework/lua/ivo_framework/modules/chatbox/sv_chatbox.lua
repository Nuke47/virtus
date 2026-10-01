util.AddNetworkString("VirtusChat_SyncConfig")
util.AddNetworkString("VirtusChat_SaveConfig")

local configPath = "virtus_chatbox.txt"

-- Cargar config
local function LoadConfig()
    if file.Exists(configPath, "DATA") then
        local data = file.Read(configPath, "DATA")
        VIRTUS_CHAT_CONFIG = util.JSONToTable(data) or {}
    else
        VIRTUS_CHAT_CONFIG = {
            ["superadmin"] = { name = "FUNDADOR", color = {r=255, g=50, b=50}, glow = true },
            ["admin"]      = { name = "ADMIN", color = {r=255, g=150, b=0}, glow = false },
            ["vip"]        = { name = "VIP", color = {r=255, g=215, b=0}, glow = true },
            ["user"]       = { name = "USER", color = {r=200, g=200, b=200}, glow = false }
        }
        file.Write(configPath, util.TableToJSON(VIRTUS_CHAT_CONFIG, true))
    end
end
LoadConfig()

-- Sincronizar al conectar
hook.Add("PlayerInitialSpawn", "VirtusChat_SyncOnJoin", function(ply)
    net.Start("VirtusChat_SyncConfig")
    net.WriteTable(VIRTUS_CHAT_CONFIG)
    net.Send(ply)
end)

-- Recibir cambios del superadmin
net.Receive("VirtusChat_SaveConfig", function(len, ply)
    if not ply:IsSuperAdmin() then return end
    
    local newConfig = net.ReadTable()
    if type(newConfig) == "table" then
        VIRTUS_CHAT_CONFIG = newConfig
        file.Write(configPath, util.TableToJSON(VIRTUS_CHAT_CONFIG, true))
        
        -- Enviar a todos
        net.Start("VirtusChat_SyncConfig")
        net.WriteTable(VIRTUS_CHAT_CONFIG)
        net.Broadcast()
        
        ply:ChatPrint("[Virtus Chatbox] Configuración guardada y sincronizada.")
    end
end)
