-- Registro de tipos de munición personalizados para el sistema de cinturón
game.AddAmmoType({ name = "sw_mag_std", force = 1000, maxcarry = 10, plydmg = 0, npcdmg = 0, tracer = TRACER_NONE })
game.AddAmmoType({ name = "sw_mag_sec", force = 1000, maxcarry = 10, plydmg = 0, npcdmg = 0, tracer = TRACER_NONE })
game.AddAmmoType({ name = "sw_mag_z6", force = 1000, maxcarry = 10, plydmg = 0, npcdmg = 0, tracer = TRACER_NONE })

if CLIENT then
    language.Add("sw_mag_std_ammo", "Cargador Estándar")
    language.Add("sw_mag_sec_ammo", "Cargador Secundario")
    language.Add("sw_mag_z6_ammo", "Núcleo Z-6")
end

if SERVER then
    hook.Add("DoPlayerDeath", "SW_Magazines_SaveGas", function(ply)
        ply.SW_SavedGasLevels = {}
        for _, wep in ipairs(ply:GetWeapons()) do
            if wep.IsTFAWeapon then
                ply.SW_SavedGasLevels[wep:GetClass()] = wep:GetNW2Float("SW_GasLevel", 100)
            end
        end
    end)

    hook.Add("PlayerSpawn", "SW_Magazines_Spawn", function(ply)
        if ply.SW_IsBeingRevived then
            -- Restaurar niveles de gas a las armas dadas por el desfibrilador
            timer.Simple(0.2, function()
                if IsValid(ply) and ply.SW_SavedGasLevels then
                    for class, gas in pairs(ply.SW_SavedGasLevels) do
                        local wep = ply:GetWeapon(class)
                        if IsValid(wep) then
                            wep:SetNW2Float("SW_GasLevel", gas)
                        end
                    end
                end
            end)
            return
        end

        timer.Simple(0.1, function()
            if IsValid(ply) then
                ply:SetAmmo(2, "sw_mag_std")
                ply:SetAmmo(1, "sw_mag_sec")
                ply:SetAmmo(0, "sw_mag_z6")
                ply.SW_SavedGasLevels = nil
            end
        end)
    end)
end
