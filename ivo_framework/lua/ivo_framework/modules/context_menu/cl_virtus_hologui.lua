local function ParseColorStr(str, def)
    local p = string.Explode(' ', str)
    if #p >= 3 then return Color(tonumber(p[1]) or 255, tonumber(p[2]) or 255, tonumber(p[3]) or 255, tonumber(p[4]) or 255) end
    return def
end

_G.VIRTUS_GetHUDColor = function(typeStr)
    if typeStr == "bg" then return GetConVar("virtus_hud_bg") and ParseColorStr(GetConVar("virtus_hud_bg"):GetString(), Color(15, 15, 15, 200)) or Color(15, 15, 15, 200) end
    if typeStr == "accent" then return GetConVar("virtus_compass_col_accent") and ParseColorStr(GetConVar("virtus_compass_col_accent"):GetString(), Color(0, 150, 255, 255)) or Color(0, 150, 255, 255) end
    return Color(255, 255, 255)
end

_G.VIRTUS_DrawHoloBackground = function(w, h, alphaMult, customColor)
    alphaMult = alphaMult or 1
    local c = customColor or _G.VIRTUS_GetHUDColor('accent')
    local c_bg = _G.VIRTUS_GetHUDColor('bg')
    
    draw.NoTexture()
    local cut = 10
    local poly = { {x = 0, y = 0}, {x = w, y = 0}, {x = w, y = h - cut}, {x = w - cut, y = h}, {x = 0, y = h} }
    surface.SetDrawColor(c_bg.r, c_bg.g, c_bg.b, c_bg.a * alphaMult)
    surface.DrawPoly(poly)
    
    surface.SetDrawColor(c.r, c.g, c.b, 5 * alphaMult)
    for i=0, h, 8 do 
        local lineW = w
        if i > h - cut then lineW = w - (i - (h - cut)) end
        surface.DrawLine(0, i, lineW, i) 
    end
    
    surface.SetDrawColor(c.r, c.g, c.b, 150 * alphaMult)
    local lw, lh = w - 1, h - 1
    surface.DrawLine(0, 0, lw, 0)
    surface.DrawLine(lw, 0, lw, lh - cut)
    surface.DrawLine(lw, lh - cut, lw - cut, lh)
    surface.DrawLine(lw - cut, lh, 0, lh)
    surface.DrawLine(0, lh, 0, 0)
    
    
end

_G.VIRTUS_DrawHoloButton = function(w, h, hover, s, colorOverride)
    if not s then s = {} end
    local colorAcc = colorOverride or _G.VIRTUS_GetHUDColor('accent')
    if not s.HoverP then s.HoverP = 0 end
    s.HoverP = Lerp(FrameTime() * 12, s.HoverP, hover and 1 or 0)
    
    draw.NoTexture()
    local cut = 8
    local poly = { {x = 0, y = 0}, {x = w, y = 0}, {x = w, y = h - cut}, {x = w - cut, y = h}, {x = 0, y = h} }
    local c_bg = _G.VIRTUS_GetHUDColor("bg")
    surface.SetDrawColor(c_bg.r, c_bg.g, c_bg.b, c_bg.a)
    surface.DrawPoly(poly)
    
    if s.HoverP > 0.05 then
        surface.SetDrawColor(colorAcc.r, colorAcc.g, colorAcc.b, s.HoverP * 45)
        surface.DrawPoly(poly)
        
        surface.SetMaterial(Material("gui/gradient_down"))
        surface.SetDrawColor(colorAcc.r, colorAcc.g, colorAcc.b, s.HoverP * 80)
        surface.DrawTexturedRect(0, 0, w, h)
        draw.NoTexture()
    end
    
    surface.SetDrawColor(colorAcc.r, colorAcc.g, colorAcc.b, 50 + s.HoverP * 150)
    local lw, lh = w - 1, h - 1
    surface.DrawLine(0, 0, lw, 0)
    surface.DrawLine(lw, 0, lw, lh - cut)
    surface.DrawLine(lw, lh - cut, lw - cut, lh)
    surface.DrawLine(lw - cut, lh, 0, lh)
    surface.DrawLine(0, lh, 0, 0)
end

_G.VIRTUS_DrawHoloCloseButton = function(w, h, hover)
    if hover then draw.RoundedBox(0, 0, 0, w, h, Color(255, 50, 50, 150)) end
    surface.SetDrawColor(255, 255, 255, hover and 255 or 100)
    local p = 12
    surface.DrawLine(p, p, w - p, h - p)
    surface.DrawLine(p + 1, p, w - p + 1, h - p)
    surface.DrawLine(w - p, p, p, h - p)
    surface.DrawLine(w - p + 1, p, p + 1, h - p)
end








