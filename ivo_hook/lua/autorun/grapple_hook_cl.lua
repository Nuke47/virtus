-- ============================================================
--  SW:RP Grappling Hook - autorun/grapple_hook_cl.lua (CLIENT)
-- ============================================================
if SERVER then return end

hook.Add("HUDShouldDraw", "GrappleHook_HideAmmo", function(elem)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    if wep:GetClass() ~= "weapon_grapple_hook" then return end
    if elem == "CHudAmmo" or elem == "CHudSecondaryAmmo" then
        return false
    end
end)

hook.Add("OnPlayerChat", "GrappleHook_ChatHelp", function(ply, text)
    if ply ~= LocalPlayer() then return end
    if string.lower(text) ~= "!grapple help" then return end
    chat.AddText(
        Color(255, 200, 60),  "[Grappling Hook] ",
        Color(200, 220, 255), "Controles: ",
        Color(180, 200, 230), "LMB = Disparar/Subir | RMB = Bajar | ENTER = Subir | E = Impulso | R = Romper"
    )
    return true
end)