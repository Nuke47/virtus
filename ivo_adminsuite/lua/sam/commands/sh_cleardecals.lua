if SERVER then
    my_admin.RegisterCommand("cleardecals", function(ply, args)
        -- 1. Verificación de permisos

        -- 2. Limpiar visuales y forzar limpieza en los clientes (Como ULX)
        for _, v in ipairs(player.GetAll()) do
            if IsValid(v) and not v:IsBot() then
                -- Esto es lo que hace que ULX funcione:
                v:SendLua("game.RemoveRagdolls()")
                v:ConCommand("r_cleardecals")
            end
        end

        -- 3. Limpieza de servidor (por redundancia)
        game.RemoveRagdolls()

        -- 4. Notificación
        my_admin.Notify(ply, " limpio ragdolls y detalles.", nil, true)
    end)
end