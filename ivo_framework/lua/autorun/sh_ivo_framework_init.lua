-- Inicialización principal de IVO Framework
IVO_FW = IVO_FW or {}
IVO_FW.Version = "1.0.0"
IVO_FW.Config = IVO_FW.Config or {}

-- Función recursiva para cargar módulos
local function LoadFiles(path)
    local files, dirs = file.Find(path .. "*", "LUA")

    if files then
        for _, f in ipairs(files) do
            local fullPath = path .. f
            if string.match(f, "^sh_") then
                AddCSLuaFile(fullPath)
                include(fullPath)
            elseif string.match(f, "^cl_") then
                AddCSLuaFile(fullPath)
                if CLIENT then include(fullPath) end
            elseif string.match(f, "^sv_") then
                if SERVER then include(fullPath) end
            end
        end
    end

    if dirs then
        for _, d in ipairs(dirs) do
            LoadFiles(path .. d .. "/")
        end
    end
end

print("[IVO Framework] Iniciando carga de modulos...")

-- Cargamos el core primero
LoadFiles("ivo_framework/core/")
-- Cargamos los módulos (HUD, etc)
LoadFiles("ivo_framework/modules/")

print("[IVO Framework] Cargado correctamente! Version: " .. IVO_FW.Version)
