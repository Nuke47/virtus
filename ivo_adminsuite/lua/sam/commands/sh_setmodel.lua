if SERVER then
    my_admin.RegisterCommand("setmodel", function(ply, args)

        local info = args[1]
        local modelo = args[2]
        if not info or not modelo then return ply:ChatPrint("[IVOSAM] Uso: !setmodel <nombre> <modelo.mdl>") end

        modelo = string.gsub(modelo, '"', "")
        local target = my_admin.FindPlayer(info)
        if not IsValid(target) then return ply:ChatPrint("[IVOSAM] Jugador no encontrado.") end
        if not target:Alive() then return ply:ChatPrint("[IVOSAM] El jugador está muerto.") end

        if not util.IsValidModel(modelo) then return ply:ChatPrint("[IVOSAM] Modelo inválido.") end

        util.PrecacheModel(modelo)
        target:SetModel(modelo)
        target:SetupHands()
        my_admin.Notify(ply, " cambió el modelo de ", target, true, " a: " .. modelo)
    end)
end