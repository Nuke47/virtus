--[[
    Shadow Skin Addon
    Reemplaza los materiales del modelo basegeneral.mdl con los de shadow_base
    cuando el jugador tiene el job "Prueba" (categoría Cadetes).
]]

local TARGET_MODEL = "models/aussiwozzi/cgi/base/basegeneral.mdl"

--- Aplica los materiales shadow_base a un jugador
local function ApplyShadowSkin(ply)
    if not IsValid(ply) then return end

    local mdl = ply:GetModel()
    if mdl ~= TARGET_MODEL then return end

    local materials = ply:GetMaterials()
    print("[Shadow Skin] Aplicando shadow_base a " .. ply:Nick() .. " (" .. #materials .. " materiales)")

    for i, matPath in ipairs(materials) do
        -- Normalizar separadores
        local normalized = string.gsub(matPath, "\\", "/")

        -- El modelo usa aussiwozzi/cgi/trp_base/, reemplazar por shadow_base
        local newMat = string.gsub(normalized, "aussiwozzi/cgi/trp_base/", "aussiwozzi/cgi/shadow_base/")

        if newMat ~= normalized then
            print("[Shadow Skin]   [" .. i .. "] " .. matPath .. " -> " .. newMat)
            ply:SetSubMaterial(i - 1, newMat)
        end
    end

    print("[Shadow Skin] Skin aplicado correctamente.")
end

--- Limpia los materiales custom de un jugador
local function ClearShadowSkin(ply)
    if not IsValid(ply) then return end

    local materials = ply:GetMaterials()
    for i = 1, #materials do
        ply:SetSubMaterial(i - 1, "")
    end
end

--- Lógica central: verifica job y aplica/limpia
local function CheckAndApply(ply)
    if not IsValid(ply) then return end

    local jobName = ply:getDarkRPVar("job")

    if jobName == "Prueba" then
        ApplyShadowSkin(ply)
    else
        ClearShadowSkin(ply)
    end
end

-- Hook: Aplicar skin cuando el jugador spawnea
hook.Add("PlayerSpawn", "ShadowSkin_ApplyOnSpawn", function(ply)
    timer.Simple(1, function() CheckAndApply(ply) end)
end)

-- Hook: Aplicar skin cuando el jugador cambia de job
hook.Add("OnPlayerChangedTeam", "ShadowSkin_ApplyOnTeamChange", function(ply, oldTeam, newTeam)
    timer.Simple(1, function() CheckAndApply(ply) end)
end)

-- Hook: Aplicar skin cuando el modelo cambia
hook.Add("PlayerSetModel", "ShadowSkin_ApplyOnModelSet", function(ply)
    timer.Simple(0.5, function() CheckAndApply(ply) end)
end)

print("[Shadow Skin] Addon cargado correctamente (v3).")
