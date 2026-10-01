hook.Add("Initialize", "Virtus_DisableTFAJamming", function()
    RunConsoleCommand("sv_tfa_jamming", "0")
    RunConsoleCommand("sv_tfa_jamming_mult", "0")
    RunConsoleCommand("sv_tfa_jamming_factor", "0")
    RunConsoleCommand("sv_tfa_jamming_factor_override", "0")
end)

hook.Add("PlayerSwitchWeapon", "Virtus_ForceUnjamTFA", function(ply, oldWep, newWep)
    if IsValid(newWep) and newWep.IsTFAWeapon then
        if newWep:GetStat("Primary.Jamming") then
            newWep.Primary.Jamming = false
            newWep:ClearStatCache("Primary.Jamming")
        end
        if newWep.GetJammed and newWep:GetJammed() then
            newWep:SetJammed(false)
        end
    end
end)
