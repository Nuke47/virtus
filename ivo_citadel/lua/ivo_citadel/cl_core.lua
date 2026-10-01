IvoCitadel = IvoCitadel or {}
IvoCitadel.Active = false
IvoCitadel.ActiveCitadelName = ""
IvoCitadel.DroidsLeft = 0
IvoCitadel.Zones = {}

net.Receive("IvoCitadel_SyncZones", function()
    IvoCitadel.Zones = net.ReadTable()
end)

net.Receive("IvoCitadel_SyncState", function()
    IvoCitadel.Active = net.ReadBool()
    IvoCitadel.ActiveCitadelName = net.ReadString()
    IvoCitadel.DroidsLeft = net.ReadUInt(16)
end)

local function PointInPolygon(point, polygon)
    local x = point.x
    local y = point.y
    local inside = false
    local j = #polygon

    for i = 1, #polygon do
        local xi = polygon[i].x
        local yi = polygon[i].y
        local xj = polygon[j].x
        local yj = polygon[j].y
        
        local intersect = ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
        if intersect then inside = not inside end
        
        j = i
    end
    return inside
end

local function GetFloorHeight(pos, zoneData)
    if not zoneData.heightmap or not zoneData.gridSize then return nil end
    
    local gs = zoneData.gridSize
    local key = math.floor(pos.x / gs) .. "_" .. math.floor(pos.y / gs)
    
    if zoneData.heightmap[key] then
        return zoneData.heightmap[key]
    end
    
    -- Si no hay dato exacto, buscar el punto más cercano en vecinos
    local gx = math.floor(pos.x / gs)
    local gy = math.floor(pos.y / gs)
    local bestDist = math.huge
    local bestZ = nil
    
    for dx = -1, 1 do
        for dy = -1, 1 do
            local nKey = (gx + dx) .. "_" .. (gy + dy)
            if zoneData.heightmap[nKey] then
                local cx = (gx + dx) * gs + gs/2
                local cy = (gy + dy) * gs + gs/2
                local dist = (pos.x - cx)^2 + (pos.y - cy)^2
                if dist < bestDist then
                    bestDist = dist
                    bestZ = zoneData.heightmap[nKey]
                end
            end
        end
    end
    
    return bestZ
end

local function IsInZone(ply, citadelName)
    if not ply or not citadelName or citadelName == "" then return false end
    
    local zoneData = IvoCitadel.Zones[citadelName]
    if not zoneData then return false end
    if not zoneData.poly or #zoneData.poly < 3 then return false end

    local pos = ply:GetPos()

    -- Primero verificar si está dentro del polígono 2D
    if not PointInPolygon(pos, zoneData.poly) then return false end

    -- Si hay heightmap, verificar contra el suelo real
    if zoneData.heightmap then
        local floorZ = GetFloorHeight(pos, zoneData)
        if floorZ then
            local ceilOffset = zoneData.ceilOffset or 300
            if pos.z < (floorZ - 50) or pos.z > (floorZ + ceilOffset) then
                return false
            end
        end
    end

    return true
end

hook.Add("HUDPaint", "IvoCitadel_HUD", function()
    if not IvoCitadel.Active then return end
    
    local ply = LocalPlayer()
    if not IsInZone(ply, IvoCitadel.ActiveCitadelName) then return end

    local w, h = ScrW(), ScrH()
    local boxW, boxH = 400, 100
    local x, y = (w - boxW) / 2, 50

    draw.RoundedBox(8, x, y, boxW, boxH, IvoCitadel.Config.Colors.bg)
    draw.SimpleText("EVENTO: " .. string.upper(IvoCitadel.ActiveCitadelName), "DermaLarge", w / 2, y + 20, IvoCitadel.Config.Colors.main, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("Droides Restantes: " .. IvoCitadel.DroidsLeft, "Trebuchet24", w / 2, y + 60, IvoCitadel.Config.Colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

