util.AddNetworkString("SW_ShopTP")
util.AddNetworkString("SW_ShopEndTP")

-- =================================================================
-- SISTEMA DE GUARDADO DE TIENDAS
-- =================================================================
local function GetTiendaSaveFile()
    return "sw_tiendas_" .. game.GetMap() .. ".json"
end

local function SaveTiendas(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("Solo superadmins pueden guardar las tiendas.")
        return
    end

    local tiendas = {}
    for _, ent in ipairs(ents.FindByClass("sw_tienda")) do
        table.insert(tiendas, {
            pos = ent:GetPos(),
            ang = ent:GetAngles()
        })
    end

    file.Write(GetTiendaSaveFile(), util.TableToJSON(tiendas, true))
    
    if IsValid(ply) then
        ply:ChatPrint("Se han guardado " .. #tiendas .. " tiendas permanentemente en " .. game.GetMap() .. ".")
    else
        print("Tiendas guardadas para el mapa " .. game.GetMap() .. ".")
    end
end
concommand.Add("sw_savetiendas", SaveTiendas)

local function LoadTiendas()
    if file.Exists(GetTiendaSaveFile(), "DATA") then
        local data = util.JSONToTable(file.Read(GetTiendaSaveFile(), "DATA") or "[]")
        if data then
            for _, t in ipairs(data) do
                local ent = ents.Create("sw_tienda")
                if IsValid(ent) then
                    ent:SetPos(t.pos)
                    ent:SetAngles(t.ang)
                    ent:Spawn()
                    local phys = ent:GetPhysicsObject()
                    if IsValid(phys) then phys:EnableMotion(false) end
                end
            end
        end
    end
end
hook.Add("InitPostEntity", "SW_LoadTiendas", LoadTiendas)
hook.Add("PostCleanupMap", "SW_LoadTiendas", LoadTiendas)

hook.Add("PlayerSay", "SW_Shop_ChatCommand", function(ply, text)
    if string.lower(text) == "!tienda" then
        if SW_InvShop and SW_InvShop.SyncPlayerData then
            SW_InvShop.SyncPlayerData(ply)
        end
        net.Start("SW_OpenShopMenu")
        -- Enviamos una entidad nula. El cliente lo interpretará como "no hay NPC 3D" y abrirá el menú 2D viejo.
        net.WriteEntity(NULL)
        net.Send(ply)
        return ""
    end
end)


-- =================================================================
-- SISTEMA DE TELETRANSPORTE PARA PROBADOR
-- =================================================================
net.Receive("SW_ShopTP", function(len, ply)
    local tpPos = net.ReadVector()
    local tpAng = net.ReadAngle()
    
    if not ply.SW_ShopPrevPos then
        ply.SW_ShopPrevPos = ply:GetPos()
        ply.SW_ShopPrevAng = ply:EyeAngles()
    end
    
    ply:SetPos(tpPos)
    ply:SetEyeAngles(tpAng)
    ply:Lock() -- Evitar que se mueva o dispare
end)

net.Receive("SW_ShopEndTP", function(len, ply)
    if ply.SW_ShopPrevPos then
        ply:SetPos(ply.SW_ShopPrevPos)
        ply:SetEyeAngles(ply.SW_ShopPrevAng)
        ply.SW_ShopPrevPos = nil
        ply.SW_ShopPrevAng = nil
    end
    ply:UnLock()
end)

hook.Add("PlayerSpawn", "SW_Shop_ResetSpawnLock", function(ply)
    if ply.SW_ShopPrevPos then
        ply.SW_ShopPrevPos = nil
        ply.SW_ShopPrevAng = nil
    end
    ply:UnLock()
end)
