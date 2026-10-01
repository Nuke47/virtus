-- ============================================================================
-- IVOSAM: COMANDO DE VOTACIÓN
-- ============================================================================

my_admin = my_admin or {}

my_admin.RegisterCommand("vote", function(ply, args)
    if not IsValid(ply) then return end
    
    if #args < 2 then
        ply:ChatPrint("[IVOSAM] Uso: !vote \"Motivo\" \"Opcion 1\" \"Opcion 2\" ...")
        return
    end

    if SERVER then
        if IVO_SAM.CurrentVote then
            ply:ChatPrint("[IVOSAM] Ya hay una votación en curso.")
            return
        end

        -- Ya que la cadena args en chat puede no venir separada por comillas si el admin no las usó,
        -- lo ideal es usar la cadena entera y separarla por comas si se escribió así.
        -- Pero los args de Garry's Mod ya agrupan las comillas. Asumimos que usan comillas o comas.
        -- Vamos a procesarlo de manera flexible:
        
        local rawString = table.concat(args, " ")
        local parts = {}
        
        -- Si hay comas, dividimos por comas.
        if string.find(rawString, ",") then
            parts = string.Explode(",", rawString)
            for i, v in ipairs(parts) do
                parts[i] = string.Trim(v)
            end
        else
            -- Si no, asumimos que usó comillas y Garry's mod ya lo separó en `args`.
            parts = args
        end

        local title = parts[1]
        local options = {}
        for i = 2, math.min(#parts, 6) do -- Máximo 5 opciones
            if parts[i] and parts[i] ~= "" then
                table.insert(options, parts[i])
            end
        end

        if #options < 1 then
            options = {"Sí", "No"} -- Default options
        end

        IVO_SAM.StartVote(title, options)
    end
end, { usage = "!vote Motivo, Opcion1, Opcion2", desc = "Inicia una votación global en el servidor", level = "admin" })