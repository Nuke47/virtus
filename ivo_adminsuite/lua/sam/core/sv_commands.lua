-- ============================================================================
-- IVOSAM: MOTOR DE COMANDOS CENTRALIZADO Y BLINDADO
-- ============================================================================
IVO_SAM = IVO_SAM or {}
my_admin = my_admin or {}

my_admin.commands     = my_admin.commands or {}
my_admin.commandMeta  = my_admin.commandMeta or {}

-- Aliases explícitos hacia IVO_SAM (fix B6 namespace: antes era my_admin = IVO_SAM,
-- lo que contaminaba el namespace global de IVO_SAM con la lógica de comandos).
-- FindPlayer/FindPlayers viven en sh_util.lua (cargado antes que este archivo).
my_admin.FindPlayer    = IVO_SAM.FindPlayer
my_admin.FindPlayers   = IVO_SAM.FindPlayers
my_admin.Notify        = IVO_SAM.Notify
my_admin.SetUserRank   = my_admin.SetUserRank or IVO_SAM.SetUserRank
my_admin.LastPositions = IVO_SAM.LastPositions


-- ----------------------------------------------------------------------------
-- RATE LIMITING
-- Tabla: _cooldowns[sid64][cmdName] = CurTime() del último uso
-- ----------------------------------------------------------------------------
IVO_SAM._cooldowns = IVO_SAM._cooldowns or {}

local function CheckCooldown(ply, cmdName)
    local cd = IVO_SAM.Config.COOLDOWNS and IVO_SAM.Config.COOLDOWNS[cmdName]
    if not cd then return true end

    local sid64 = ply:SteamID64()
    IVO_SAM._cooldowns[sid64] = IVO_SAM._cooldowns[sid64] or {}
    local lastUse = IVO_SAM._cooldowns[sid64][cmdName] or 0
    local elapsed = CurTime() - lastUse

    if elapsed < cd then
        local remaining = math.ceil(cd - elapsed)
        ply:ChatPrint("[IVOSAM] Cooldown: espera " .. remaining .. "s para usar !" .. cmdName .. " de nuevo.")
        return false
    end

    IVO_SAM._cooldowns[sid64][cmdName] = CurTime()
    return true
end

-- Limpia cooldowns de jugadores que se desconectan
hook.Add("PlayerDisconnected", "IVO_SAM_LimpiarCooldowns", function(ply)
    if IsValid(ply) then IVO_SAM._cooldowns[ply:SteamID64()] = nil end
end)

-- ----------------------------------------------------------------------------
-- [PASO 2] REGISTRADOR Y BLINDAJE DE COMANDOS
-- ----------------------------------------------------------------------------
local comandosCriticos = {
    ["setrank"] = true,
    ["createrank"] = true,
    ["deleterank"] = true
}

-- meta = { usage = "!cmd <arg>", desc = "Descripción", level = "admin"|"superadmin" }
function my_admin.RegisterCommand(name, callback, meta)
    name = string.lower(name)
    my_admin.commands[name] = callback
    if meta then my_admin.commandMeta[name] = meta end

    concommand.Add("sam_" .. name, function(ply, cmd, args)
        if not IsValid(ply) then 
            callback(ply, args)
            return 
        end

        if comandosCriticos[name] then
            if not ply:IsSuperAdmin() then
                ply:ChatPrint("[IVOSAM] ERROR: No tienes rango suficiente (SuperAdmin) para ejecutar 'sam_" .. name .. "'")
                return 
            end
        else
            if not IVO_SAM.HasPermission(ply, name) then
                ply:ChatPrint("[IVOSAM] ERROR: No tienes permisos (" .. name .. ") para ejecutar 'sam_" .. name .. "'")
                return 
            end
        end

        callback(ply, args)
    end)
    
    print("[IVOSAM] Comando blindado registrado -> Chat: !" .. name .. " | Consola: sam_" .. name)
end

-- Procesador del chat (!comando)
hook.Add("PlayerSay", "IVO_SAM_ProcesadorChat", function(ply, text)
    if not IsValid(ply) then return end
    
    local prefijo = string.sub(text, 1, 1)
    if prefijo == "!" or prefijo == "/" then
        local str = string.sub(text, 2)
        local args = string.Explode(" ", str)
        local cmdName = string.lower(args[1] or "")
        table.remove(args, 1)

        -- Limpiar comillas de los argumentos (la UI envía args entre comillas)
        for i, v in ipairs(args) do
            args[i] = string.gsub(v, '"', "")
        end
        -- Eliminar argumentos vacíos que quedan tras limpiar comillas
        for i = #args, 1, -1 do
            if args[i] == "" then table.remove(args, i) end
        end

        local callback = my_admin.commands[cmdName]
        if callback then
            if comandosCriticos[cmdName] then
                if not ply:IsSuperAdmin() then
                    ply:ChatPrint("[IVOSAM] No tienes permisos (SuperAdmin) para usar !" .. cmdName)
                    return "" 
                end
            else
                if not IVO_SAM.HasPermission(ply, cmdName) then
                    ply:ChatPrint("[IVOSAM] No tienes permisos (" .. cmdName .. ") para usar !" .. cmdName)
                    return ""
                end
            end

            if not CheckCooldown(ply, cmdName) then return "" end
            callback(ply, args)
            return ""
        end
    end
end)

net.Receive("Ivosam_FreecamTP", function(len, ply)
    if not IVO_SAM.HasPermission(ply, "spectate") then return end
    local pos = net.ReadVector()
    
    ply:SetPos(pos)
    -- ply:SetMoveType(MOVETYPE_WALK) -- ELIMINADO: esto quitaba el noclip al usar tp con R
    
end)

-- ----------------------------------------------------------------------------
-- COMANDO !help
-- ----------------------------------------------------------------------------
hook.Add("PlayerSay", "IVO_SAM_Help", function(ply, text)
    if not IsValid(ply) or not IVO_SAM.HasPermission(ply, "menu") then return end

    local lower = string.lower(string.Trim(text))
    if lower ~= "!help" and not string.StartWith(lower, "!help ") then return end

    local arg = string.Trim(string.sub(lower, 7))

    if arg ~= "" then
        -- Ayuda de un comando específico
        local meta = my_admin.commandMeta[arg]
        if meta then
            ply:ChatPrint("━━━━ !" .. arg .. " ━━━━")
            ply:ChatPrint("Uso:    " .. (meta.usage or "!" .. arg))
            ply:ChatPrint("Desc:   " .. (meta.desc  or "Sin descripción"))
            ply:ChatPrint("Nivel:  " .. (meta.level or "admin"))
        else
            ply:ChatPrint("[IVOSAM] Comando '!" .. arg .. "' no encontrado o sin documentación.")
        end
    else
        -- Lista de todos los comandos disponibles para su rango
        local isSuperAdmin = ply:IsSuperAdmin()
        ply:ChatPrint("━━━━ COMANDOS IVOSAM DISPONIBLES ━━━━")
        local sorted = {}
        for cmdName, meta in pairs(my_admin.commandMeta) do
            if meta.level == "superadmin" and not isSuperAdmin then continue end
            if not isSuperAdmin and not IVO_SAM.HasPermission(ply, cmdName) then continue end
            table.insert(sorted, { name = cmdName, desc = meta.desc or "" })
        end
        table.sort(sorted, function(a, b) return a.name < b.name end)
        for _, entry in ipairs(sorted) do
            ply:ChatPrint("  !" .. entry.name .. " — " .. entry.desc)
        end
        ply:ChatPrint("Usa !help <comando> para ver el uso detallado.")
    end

    return ""
end)

-- ----------------------------------------------------------------------------
-- [PASO 3] CARGADOR AUTOMÁTICO DE SUB-COMANDOS (Al final para que ya exista todo lo anterior)
-- ----------------------------------------------------------------------------
function IVOSAM_CargarSubComandos()
    local archivos, _ = file.Find("sam/commands/*.lua", "LUA")
    if archivos then
        for _, archivo in ipairs(archivos) do
            local ruta_completa = "sam/commands/" .. archivo
            AddCSLuaFile(ruta_completa)
            include(ruta_completa)
            print("[IVOSAM] Cargado sub-comando dinámico: " .. archivo)
        end
    end
end

IVOSAM_CargarSubComandos()