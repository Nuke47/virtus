if SERVER then
    -- Función interna inteligente para encontrar jugadores por nombres similares o parciales
    local function BuscarJugadorFuzzy(criterio)
        if not criterio or criterio == "" then return nil end
        criterio = string.lower(criterio)

        -- 1. Intentar buscar coincidencia exacta primero
        for _, p in ipairs(player.GetAll()) do
            if string.lower(p:Nick()) == criterio or p:SteamID() == criterio then
                return p
            end
        end

        -- 2. Búsqueda difusa: ¿El nombre del jugador contiene el texto buscado?
        local coincidencias = {}
        for _, p in ipairs(player.GetAll()) do
            if string.find(string.lower(p:Nick()), criterio, 1, true) then
                table.insert(coincidencias, p)
            end
        end

        -- Si hay una sola coincidencia clara, lo devolvemos
        if #coincidencias == 1 then
            return coincidencias[1]
        elseif #coincidencias > 1 then
            -- Si hay muchos que se llaman igual (ej. tres tipos con "Gamer"), avisamos en lugar de adivinar
            return "multiples"
        end

        return nil
    end

    my_admin.RegisterCommand("respawn", function(ply, args)
        -- Validacin de rango gestionada por my_admin.RegisterCommand

        local info = args[1]
        local target

        if not info or info == "" then
            -- Si no pone ningún argumento, se revive a sí mismo
            target = ply
        else
            -- Intentamos buscarlo con el algoritmo difuso
            local resultado = BuscarJugadorFuzzy(info)
            
            if resultado == "multiples" then
                if IsValid(ply) then
                    ply:ChatPrint("[IVOSAM] Se encontraron múltiples jugadores con nombres similares. ¡Sé más específico!")
                end
                return
            elseif IsValid(resultado) then
                target = resultado
            end
        end

        -- Si después de todo no se encontró a nadie válido
        if not IsValid(target) then 
            if IsValid(ply) then
                ply:ChatPrint("[IVOSAM] No se encontró a ningún jugador activo con ese nombre o SteamID.")
            end
            return 
        end

        -- Ejecutar el respawn nativo
        target:Spawn()
        
        -- Notificación centralizada del sistema
        my_admin.Notify(ply, " revivió/respawneó a ", target, true)
    end)
end