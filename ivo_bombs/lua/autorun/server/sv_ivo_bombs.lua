--[[
    ivo_bombs - Comandos de Spawn (Server)
    
    Comandos de chat:
      !bomb                   → Spawnea bomba Fácil donde miras
      !bomb 1/2/3/4           → Spawnea con dificultad (1=Fácil, 2=Normal, 3=Difícil, 4=Extremo)
      !bomb facil/normal/dificil/extremo
      !bombremove              → Elimina todas las bombas activas
    
    Comandos de consola:
      ivo_bomb_spawn <dificultad>
      ivo_bomb_removeall
      ivo_bomb_give_defuser    → Da el kit de desactivación
]]

if not SERVER then return end

local activeBombs = {}

local function CleanBombList()
    for i = #activeBombs, 1, -1 do
        if not IsValid(activeBombs[i]) then
            table.remove(activeBombs, i)
        end
    end
end

local function GetActiveBombCount()
    CleanBombList()
    return #activeBombs
end

local MAX_BOMBS = 5

-- Mapeo de nombres a IDs de dificultad
local DIFF_NAMES = {
    ["facil"]    = 1, ["fácil"]    = 1, ["easy"]   = 1, ["1"] = 1,
    ["normal"]   = 2, ["medium"]   = 2, ["2"]      = 2,
    ["dificil"]  = 3, ["difícil"]  = 3, ["hard"]   = 3, ["3"] = 3,
    ["extremo"]  = 4, ["extreme"]  = 4, ["4"]      = 4,
}

local function ParseDifficulty(str)
    if not str or str == "" then return 1 end
    str = string.lower(string.Trim(str))
    return DIFF_NAMES[str] or 1
end

local function SpawnBomb(ply, diffID)
    -- Permisos
    if not ply:IsSuperAdmin() and not ply:IsAdmin() then
        ply:ChatPrint("[BOMBA] No tienes permisos para spawnear bombas.")
        return
    end

    -- Límite
    if GetActiveBombCount() >= MAX_BOMBS then
        ply:ChatPrint("[BOMBA] Máximo de bombas activas alcanzado (" .. MAX_BOMBS .. ").")
        return
    end

    -- Validar dificultad
    diffID = math.Clamp(diffID or 1, 1, 4)
    local config = IVO_BOMBS.Difficulties[diffID]
    if not config then diffID = 1 end

    -- Posición
    local tr = ply:GetEyeTrace()
    local spawnPos = tr.HitPos + tr.HitNormal * 15

    -- Crear bomba
    local bomb = ents.Create("ent_ivo_bomb")
    if not IsValid(bomb) then
        ply:ChatPrint("[BOMBA] Error al crear la bomba.")
        return
    end

    bomb:SetDifficulty(diffID)
    bomb:SetPos(spawnPos)
    bomb:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    bomb:Spawn()
    bomb:Activate()

    table.insert(activeBombs, bomb)

    ply:ChatPrint("[BOMBA] Bomba colocada. Dificultad: " .. config.name)
    print("[ivo_bombs] " .. ply:Nick() .. " (" .. ply:SteamID() .. ") spawneó bomba dificultad " .. config.name)
end

-- ============================================================
-- Comandos de consola
-- ============================================================
concommand.Add("ivo_bomb_spawn", function(ply, cmd, args)
    if not IsValid(ply) then return end
    local diffID = ParseDifficulty(args[1])
    SpawnBomb(ply, diffID)
end)

concommand.Add("ivo_bomb_removeall", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then
        ply:ChatPrint("[BOMBA] Solo superadmins pueden remover todas las bombas.")
        return
    end

    CleanBombList()
    for _, bomb in ipairs(activeBombs) do
        if IsValid(bomb) then bomb:Remove() end
    end
    activeBombs = {}
    ply:ChatPrint("[BOMBA] Todas las bombas removidas.")
    for _, p in ipairs(player.GetAll()) do
        p:ChatPrint("[BOMBA] Un admin removió todas las bombas.")
    end
end)

concommand.Add("ivo_bomb_give_defuser", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() and not ply:IsAdmin() then
        ply:ChatPrint("[BOMBA] No tienes permisos.")
        return
    end

    local target = ply
    if args[1] then
        for _, p in ipairs(player.GetAll()) do
            if string.find(string.lower(p:Nick()), string.lower(args[1]), 1, true) then
                target = p
                break
            end
        end
    end

    target:Give("weapon_ivo_defuser")
    ply:ChatPrint("[BOMBA] Kit de desactivación entregado a " .. target:Nick() .. ".")
end)

-- ============================================================
-- Comandos de chat
-- ============================================================
hook.Add("PlayerSay", "ivo_bombs_chatcmd", function(ply, text, teamChat)
    local lower = string.lower(string.Trim(text))

    -- !bomb [dificultad]
    if string.sub(lower, 1, 5) == "!bomb" and string.sub(lower, 1, 10) ~= "!bombremov" then
        local arg = string.Trim(string.sub(text, 6))
        local diffID = ParseDifficulty(arg)
        SpawnBomb(ply, diffID)
        return ""
    end

    -- !bombremove
    if lower == "!bombremove" or lower == "!bombremoveall" then
        if not ply:IsSuperAdmin() then
            ply:ChatPrint("[BOMBA] Solo superadmins pueden remover bombas.")
            return ""
        end

        CleanBombList()
        for _, bomb in ipairs(activeBombs) do
            if IsValid(bomb) then bomb:Remove() end
        end
        activeBombs = {}
        ply:ChatPrint("[BOMBA] Todas las bombas removidas.")
        return ""
    end

    -- !defuser [nombre]
    if string.sub(lower, 1, 8) == "!defuser" then
        if not ply:IsAdmin() then
            ply:ChatPrint("[BOMBA] No tienes permisos.")
            return ""
        end

        local arg = string.Trim(string.sub(text, 9))
        local target = ply
        if arg ~= "" then
            for _, p in ipairs(player.GetAll()) do
                if string.find(string.lower(p:Nick()), string.lower(arg), 1, true) then
                    target = p
                    break
                end
            end
        end

        target:Give("weapon_ivo_defuser")
        ply:ChatPrint("[BOMBA] Kit entregado a " .. target:Nick() .. ".")
        return ""
    end
end)

-- Limpieza al cambiar mapa
hook.Add("ShutDown", "ivo_bombs_cleanup", function()
    for _, bomb in ipairs(activeBombs) do
        if IsValid(bomb) then bomb:Remove() end
    end
end)
