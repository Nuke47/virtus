-- sh_virtus_tfa_patch.lua
-- Este archivo parchea TFA Base para que el servidor y el cliente sepan exactamente 
-- cuándo el jugador está en tercera persona, previniendo tracers y efectos duplicados.
AddCSLuaFile()

hook.Add("InitPostEntity", "Virtus_TFA_Patch_Tracer", function()
    timer.Simple(2, function()
        local bases_to_patch = {
            "tfa_gun_base",
            "tfa_sw_gun_base",
            "tfa_sw_scoped_base",
            "tfa_swsft_base"
        }
        
        for _, base_name in ipairs(bases_to_patch) do
            local tfa_base = weapons.GetStored(base_name)
            if tfa_base and tfa_base.IsFirstPerson then
                -- Asegurarnos de no parchear dos veces
                if not tfa_base.VirtusPatched then
                    local original_IsFirstPerson = tfa_base.IsFirstPerson
                    tfa_base.VirtusPatched = true
                    tfa_base.IsFirstPerson = function(self)
                        local ply = self:GetOwner()
                        if IsValid(ply) and ply:IsPlayer() then
                            if SERVER and ply:GetNWBool("Virtus_ThirdPersonActive", false) then
                                return false
                            end
                            if CLIENT and ply.ThirdPerson then
                                return false
                            end
                        end
                        return original_IsFirstPerson(self)
                    end
                end
            end
        end
    end)
end)
