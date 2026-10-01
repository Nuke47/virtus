-- ==============================================================================
-- BRJULA TCTICA IMPERIALRP - VIRTUS STUDIOS (VERSIN MINIMALISTA V4)
-- ==============================================================================

CreateClientConVar("virtus_compass_y", "40", true, false)
CreateClientConVar("virtus_compass_width", "400", true, false)
CreateClientConVar("virtus_compass_spacing", "8", true, false)
CreateClientConVar("virtus_compass_col_text", "239 240 245 255", true, false)
CreateClientConVar("virtus_compass_col_line", "150 150 150 150", true, false)
CreateClientConVar("virtus_compass_col_accent", "0 150 255 255", true, false)
CreateClientConVar("virtus_compass_col_exact", "255 255 255 255", true, false)

surface.CreateFont("Compass_Main", { font = "SansSerifFLF", size = 16, weight = 500, antialias = true })
surface.CreateFont("Compass_North", { font = "SansSerifFLF", size = 18, weight = 500, antialias = true, shadow=true })
surface.CreateFont("Compass_Exact", { font = "SansSerifFLF", size = 20, weight = 500, antialias = true })
surface.CreateFont("Compass_Aurebesh", { font = "VirtusBe", size = 10, weight = 500, antialias = true })

local smooth_angle = 0

local function ParseCol(cv, def)
    local cvObj = GetConVar(cv)
    if not cvObj then return def end
    local p = string.Explode(" ", cvObj:GetString())
    if #p >= 3 then return Color(tonumber(p[1]) or 255, tonumber(p[2]) or 255, tonumber(p[3]) or 255, tonumber(p[4]) or 255) end
    return def
end

function _G.DrawMinimalistImperialCompass(preview_mode, previewX, previewY)
    if not preview_mode then
        if (_G.IVOBinosActive or _G.SU_IR_Active) and not LocalPlayer():ShouldDrawLocalPlayer() then return end
    end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local w = GetConVar("virtus_compass_width"):GetInt()
    local y = previewY or GetConVar("virtus_compass_y"):GetInt()
    local centerX = previewX or (ScrW() / 2)
    local h = 40
    local cut = 10
    
    local c_acc = _G.VIRTUS_GetHUDColor and _G.VIRTUS_GetHUDColor("accent") or Color(0, 150, 255)
    local c_text = ParseCol("virtus_compass_col_text", Color(240, 240, 245, 255))
    local c_line = ParseCol("virtus_compass_col_line", Color(150, 150, 150, 150))
    local c_exact = ParseCol("virtus_compass_col_exact", Color(255, 255, 255, 255))
    
    local real_angle = (-ply:EyeAngles().y) % 360
    if real_angle < 0 then real_angle = real_angle + 360 end
    smooth_angle = LerpAngle(RealFrameTime() * 15, Angle(0, smooth_angle, 0), Angle(0, real_angle, 0)).y

    draw.NoTexture()
    local rightX = centerX + w/2
    local leftX = centerX - w/2
    
    -- Fondo translucido más bajo y redondeado (sin linea celeste)
    draw.RoundedBox(12, leftX - 15, y + 4, w + 30, 30, Color(10, 15, 25, 120))
    
    render.SetScissorRect(leftX, y, rightX, y + h, true)
    
    local markers = { [0] = "N", [45] = "NE", [90] = "E", [135] = "SE", [180] = "S", [225] = "SO", [270] = "O", [315] = "NO" }
    local fov_pixels = w * 1.5 
    local fov_degrees = 90
    local pixels_per_degree = fov_pixels / fov_degrees

    -- Ticks and texts
    for i = 0, 359, 15 do
        local diff = math.AngleDifference(i, smooth_angle)
        local px = centerX + (diff * pixels_per_degree)
        
        if px > leftX and px < rightX then
            local alpha = 255
            local dist = math.abs(px - centerX)
            if dist > (w/2 - 40) then alpha = math.Clamp(255 - ((dist - (w/2 - 40)) * 6), 0, 255) end
            
            if markers[i] then
                local isNorth = (i == 0)
                local font = isNorth and "Compass_North" or "Compass_Main"
                local color = isNorth and c_acc or c_text
                draw.SimpleText(markers[i], font, px, y + h/2 - 8, Color(color.r, color.g, color.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                
                surface.SetDrawColor(color.r, color.g, color.b, alpha * 0.3)
                surface.DrawLine(px - 6, y + h/2 + 1, px + 6, y + h/2 + 1)
                
                draw.SimpleText(markers[i], "Compass_Aurebesh", px, y + h/2 + 9, Color(color.r, color.g, color.b, alpha * 0.6), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                -- Mostrar grados en cada marca de 15°
                draw.SimpleText(tostring(i) .. "\xC2\xB0", "Compass_Main", px, y + h/2 - 8, Color(c_line.r, c_line.g, c_line.b, alpha * 0.8), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                
                surface.SetDrawColor(c_line.r, c_line.g, c_line.b, alpha * 0.3)
                surface.DrawLine(px - 6, y + h/2 + 1, px + 6, y + h/2 + 1)
                
                draw.SimpleText(tostring(i), "Compass_Aurebesh", px, y + h/2 + 9, Color(c_line.r, c_line.g, c_line.b, alpha * 0.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end
    
    render.SetScissorRect(0,0,0,0,false)
    
    -- Contenedor del grado exacto mejorado
    local boxW = 46
    local boxH = 22
    local boxX = centerX - boxW / 2
    local boxY = y - boxH - 6
    
    -- Fondo con estilo más elegante (sin linea celeste)
    draw.RoundedBox(4, boxX, boxY, boxW, boxH, Color(10, 15, 25, 180))

    local degree_text = tostring(math.Round(real_angle)) .. "\xC2\xB0"
    draw.SimpleText(degree_text, "Compass_Exact", centerX, boxY + boxH/2 - 1, c_exact, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Indicadores de centro en la linea de la brujula
    local tw = 8
    local th = 6
    local tri_bot = { {x=centerX, y=y+th}, {x=centerX-tw/2, y=y}, {x=centerX+tw/2, y=y} }
    local tri_top = { {x=centerX, y=y+h-th}, {x=centerX-tw/2, y=y+h}, {x=centerX+tw/2, y=y+h} }
    
    draw.NoTexture()
    surface.SetDrawColor(c_acc.r, c_acc.g, c_acc.b, 255)
    surface.DrawPoly(tri_bot)
    surface.DrawPoly(tri_top)
end

hook.Add("HUDPaint", "ImperialCompass_Minimal", function()
    if LocalPlayer():GetNWBool("IVO_RTSMode", false) then return end
    if GetConVar("virtus_hide_hud") and GetConVar("virtus_hide_hud"):GetBool() then return end
    if GetConVar("virtus_hide_compass") and GetConVar("virtus_hide_compass"):GetBool() then return end
    
    if _G.VirtusSway then _G.VirtusSway.Begin3D(0) end
    if _G.DrawMinimalistImperialCompass then
        _G.DrawMinimalistImperialCompass(false)
    end
    if _G.VirtusSway then _G.VirtusSway.End3D() end
end)

