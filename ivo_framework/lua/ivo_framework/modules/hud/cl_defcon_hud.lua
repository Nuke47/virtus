-- Fuentes consistentes con el HUD
surface.CreateFont("Defcon_Title", { font = "SansSerifFLF", size = 18, weight = 700, antialias = true })
surface.CreateFont("Defcon_Sub", { font = "SansSerifFLF", size = 13, weight = 500, antialias = true })

local defconData = {
    [0] = { name = "OFFLINE", col = Color(100, 100, 100), msg = "ESPERA" },
    [5] = { name = "LEVEL 5", col = Color(30, 144, 255), msg = "PAZ TOTAL" },
    [4] = { name = "LEVEL 4", col = Color(0, 255, 150), msg = "VIGILANCIA" },
    [3] = { name = "LEVEL 3", col = Color(255, 200, 0), msg = "PATRULLAJE" },
    [2] = { name = "LEVEL 2", col = Color(255, 80, 0), msg = "ALERTA" },
    [1] = { name = "LEVEL 1", col = Color(239, 83, 80), msg = "BAJO ATAQUE" }
}

-- Smooth transition
local lerpAlpha = 0

hook.Add("HUDPaint", "IVOSAM_Defcon_Elite_Top", function()
    if LocalPlayer():GetNWBool("IVO_RTSMode", false) then return end
    if not LocalPlayer():Alive() or LocalPlayer():Health() <= 0 then return end
    local level = GetGlobalInt("IVOSAM_DefconLevel", 0)
    if level == 0 then return end

    local data = defconData[level]
    local time = CurTime()
    local pulse = math.abs(math.sin(time * 3))
    
    -- Textos
    local levelNum = string.gsub(data.name, "LEVEL ", "")
    local txtTop = "DEFCON " .. levelNum
    local txtBot = data.msg
    
    surface.SetFont("Defcon_Title")
    local twTop, thTop = surface.GetTextSize(txtTop)
    surface.SetFont("Defcon_Sub")
    local twBot, thBot = surface.GetTextSize(txtBot)
    
    local totalTxtW = math.max(twTop, twBot)
    local paddingX = 30
    local paddingY = 6
    local w = totalTxtW + paddingX * 2
    local h = thTop + thBot + paddingY * 2 + 4
    
    -- Posicion: centro-top (donde estaba la fecha)
    local x = (ScrW() - w) / 2
    local y = 80

    if _G.VirtusSway then _G.VirtusSway.Begin3D(0) end

    -- Fondo redondeado translucido
    draw.RoundedBox(8, x, y, w, h, Color(10, 15, 25, 160))
    
    -- Barra de acento lateral izquierda (color del nivel)
    local glowAlpha = level <= 2 and (150 + 105 * pulse) or 200
    draw.RoundedBox(4, x + 4, y + 6, 3, h - 12, Color(data.col.r, data.col.g, data.col.b, glowAlpha))
    
    -- Linea fina inferior del color del nivel
    draw.RoundedBox(2, x + 12, y + h - 4, w - 24, 2, Color(data.col.r, data.col.g, data.col.b, 80))
    
    -- Texto principal (DEFCON X)
    local alphaIndicador = level <= 2 and (120 + (135 * pulse)) or 255
    draw.SimpleText(txtTop, "Defcon_Title", x + w/2, y + paddingY + 1, Color(data.col.r, data.col.g, data.col.b, alphaIndicador), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Texto secundario (mensaje)
    draw.SimpleText(txtBot, "Defcon_Sub", x + w/2, y + paddingY + thTop + 4, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    if _G.VirtusSway then _G.VirtusSway.End3D() end
end)
