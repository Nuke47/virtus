hook.Add("InitPostEntity", "SW_AutoVestimenta_Init", function()
    timer.Simple(2, function()
        SW_AutoApplyVestimenta()
    end)
end)

local lastModel = ""
local lastTeam = -1

function SW_AutoApplyVestimenta()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local modelClean = string.gsub(string.lower(ply:GetModel()), "[/%s%.]", "_")
    local teamID = ply:Team()
    
    -- Se guarda usando Job y Modelo como nombre para asegurar que sea especifico
    local filePath = "v_bodygroups/" .. teamID .. "_" .. modelClean .. ".txt"
    if not file.Exists(filePath, "DATA") then
        -- Retrocompatibilidad con el archivo viejo que sólo usaba modelo
        filePath = "v_bodygroups/" .. modelClean .. ".txt"
        if not file.Exists(filePath, "DATA") then return end
    end
    
    local savedData = file.Read(filePath, "DATA")
    if not savedData or savedData == "" then return end
    
    local outfit = util.JSONToTable(savedData)
    if not outfit then return end
    
    net.Start("v_bodygroups_Update")
        net.WriteString("preset")
        net.WriteInt(0, 8) 
        net.WriteInt(0, 8) 
        net.WriteString(ply:GetModel()) 
        net.WriteString(savedData)
    net.SendToServer()
    
    if outfit.skin then ply:SetSkin(outfit.skin) end
    if outfit.bgs then
        for bgID, val in pairs(outfit.bgs) do
            ply:SetBodygroup(tonumber(bgID), tonumber(val))
        end
    end
end

hook.Add("Think", "SW_AutoVestimenta_Check", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    if ply:GetModel() ~= lastModel or ply:Team() ~= lastTeam then
        lastModel = ply:GetModel()
        lastTeam = ply:Team()
        
        -- Añadimos un pequeño delay para asegurarnos de que el servidor terminó de asignar todo
        timer.Simple(0.5, function()
            SW_AutoApplyVestimenta()
        end)
    end
end)
