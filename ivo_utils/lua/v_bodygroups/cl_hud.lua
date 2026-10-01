-- Cliente: HUD de Estado de Vestimenta
if not CLIENT then return end

local function DrawBodygroupHUD()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    -- No dibujar si el menú de la C está abierto (para evitar superposición visual molesta)
    if g_ContextMenu and g_ContextMenu:IsVisible() then return end

    local activeBGs = 0
    local totalBGs = ply:GetNumBodyGroups()

    for i = 0, totalBGs - 1 do
        if ply:GetBodygroup(i) > 0 then
            activeBGs = activeBGs + 1
        end
    end

    -- Coordenadas del HUD (Esquina inferior izquierda, arriba de la vida estándar)
    local x, y = 30, ScrH() - 180
    local w, h = 180, 35

    -- Dibujado del fondo moderno
    draw.RoundedBox(4, x, y, w, h, Color(15, 15, 15, 180))
    surface.SetDrawColor(60, 60, 60, 100)
    surface.DrawOutlinedRect(x, y, w, h, 1)

    -- Indicador visual
    draw.RoundedBox(2, x + 5, y + 5, 4, h - 10, Color(0, 150, 255, 255))

    -- Texto informativo
    draw.SimpleText("Accesorios Equipados: " .. activeBGs, "DermaDefault", x + 15, y + h/2, Color(230, 230, 230), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "v_bodygroups_DrawHUD", DrawBodygroupHUD)