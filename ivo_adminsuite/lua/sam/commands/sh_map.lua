-- ============================================================================
-- IVOSAM: COMANDO CAMBIAR MAPA (con soporte Workshop)
-- ============================================================================

my_admin = my_admin or {}

if SERVER then
    -- ========================================================================
    -- SERVIDOR: Lista de mapas y networking
    -- ========================================================================
    util.AddNetworkString("Ivosam_RequestMapList")
    util.AddNetworkString("Ivosam_SendMapList")

    -- Cachear la lista de mapas del servidor (incluye Workshop montados)
    local function GetServerMaps()
        local maps = file.Find("maps/*.bsp", "GAME")
        local clean = {}
        for _, m in ipairs(maps) do
            table.insert(clean, string.StripExtension(m))
        end
        table.sort(clean)
        return clean
    end

    -- Cuando un cliente pide la lista, se la enviamos
    net.Receive("Ivosam_RequestMapList", function(len, ply)
        if not IsValid(ply) then return end

        local maps = GetServerMaps()
        local json = util.TableToJSON(maps)
        local compressed = util.Compress(json)

        net.Start("Ivosam_SendMapList")
            net.WriteUInt(#compressed, 32)
            net.WriteData(compressed, #compressed)
        net.Send(ply)
    end)

    -- Comando de cambio de mapa
    my_admin.RegisterCommand("map", function(ply, args)
        if not IsValid(ply) then return end

        local mapName = args[1]
        if not mapName or mapName == "" then
            ply:ChatPrint("[IVOSAM] Uso: !map <nombre_mapa>")
            return
        end

        -- Notificar a todo el servidor
        for _, v in ipairs(player.GetAll()) do
            v:ChatPrint("===============================================")
            v:ChatPrint("[ATENCIÓN] El servidor está cambiando de nivel.")
            v:ChatPrint("[ATENCIÓN] Cambiando al mapa " .. mapName:upper() .. " en 10 segundos.")
            v:ChatPrint("===============================================")
            if my_admin.Notify then
                my_admin.Notify(v, "El servidor cambiará de mapa a " .. mapName:upper() .. " en 10 segundos.", nil, false)
            end
        end

        print("[IVOSAM] Cambio de mapa a " .. mapName .. " iniciado por " .. ply:Nick())

        -- Cambiar mapa tras 10 segundos
        timer.Simple(10, function()
            RunConsoleCommand("changelevel", mapName)
        end)

    end, { usage = "!map <mapa>", desc = "Cambiar de mapa con aviso de 10s", level = "superadmin" })

end

if CLIENT then
    -- ========================================================================
    -- CLIENTE: Recibir lista de mapas del servidor
    -- ========================================================================
    IVO_SAM = IVO_SAM or {}
    IVO_SAM._serverMaps = IVO_SAM._serverMaps or {}

    -- Pedir la lista de mapas al servidor
    function IVO_SAM.RequestServerMaps()
        net.Start("Ivosam_RequestMapList")
        net.SendToServer()
    end

    -- Recibir la lista
    net.Receive("Ivosam_SendMapList", function()
        local len = net.ReadUInt(32)
        local compressed = net.ReadData(len)
        local json = util.Decompress(compressed)
        if json then
            IVO_SAM._serverMaps = util.JSONToTable(json) or {}
            print("[IVOSAM] Recibida lista de mapas del servidor: " .. #IVO_SAM._serverMaps .. " mapas")
        end
    end)

    -- Pedir la lista automáticamente al conectar
    hook.Add("InitPostEntity", "IVOSAM_RequestMapList", function()
        timer.Simple(3, function()
            IVO_SAM.RequestServerMaps()
        end)
    end)
end
