local function SafeUpper(str)
    if not str then return "" end
    local utf8_lower = "aábcdeéfghiíjklmnñoópqrstuúüvwxyz"
    local utf8_upper = "AÁBCDEÉFGHIÍJKLMNÑOÓPQRSTUÚÜVWXYZ"
    local res = ""
    local success = pcall(function()
        for p, c in utf8.codes(str) do
            local ch = utf8.char(c)
            local idx = utf8_lower:find(ch, 1, true)
            if idx then
                res = res .. utf8_upper:sub(idx, idx + #ch - 1)
            else
                res = res .. string.upper(ch)
            end
        end
    end)
    if not success then return string.upper(str) end
    return res
end

if SERVER then return end

-- =========================
-- FONTS
-- =========================

-- Force-load VirtusBe so it's available across all addons
-- The font file lives in content_pack_recursos; we reference it by internal name
-- surface.CreateFont will use the internal TTF name "VirtusBe" which was patched
-- into the file. If the file hasn't loaded yet we add a fallback.

surface.CreateFont("VirtusHUD_Name", {
    font = "SansSerifFLF",
    size = 24,
    weight = 600,
    antialias = true
})

surface.CreateFont("VirtusHUD_Job", {
    font = "SansSerifFLF",
    size = 18,
    weight = 500,
    antialias = true
})

surface.CreateFont("VirtusHUD_Info", {
    font = "SansSerifFLF",
    size = 18,
    weight = 500,
    antialias = true
})

surface.CreateFont("VirtusHUD_Aurebesh", {
    font = "VirtusBe",
    size = 16,
    weight = 500,
    antialias = true
})

surface.CreateFont("VirtusHUD_Money", {
    font = "VirtusBe",
    size = 20,
    weight = 500,
    antialias = true
})

surface.CreateFont("VirtusHUD_AurebeshBar", {
    font = "VirtusBe",
    size = 12,
    weight = 500,
    antialias = true
})

surface.CreateFont("VirtusHUD_Val", {
    font = "SansSerifFLF",
    size = 22,
    weight = 500,
    antialias = true
})

surface.CreateFont("VirtusHUD_Header", {
    font = "SF Distant Galaxy",
    size = 22,
    weight = 500,
    antialias = true
})

surface.CreateFont("VirtusHUD_SubHeader", {
    font = "SansSerifFLF",
    size = 18,
    weight = 500,
    antialias = true
})

-- =========================
-- UTILIDADES DE COLOR
-- =========================
local function ParseCol(cv, def)
    local cvObj = GetConVar(cv)
    if not cvObj then return def end
    local p = string.Explode(" ", cvObj:GetString())
    if #p >= 3 then return Color(tonumber(p[1]) or 255, tonumber(p[2]) or 255, tonumber(p[3]) or 255, tonumber(p[4]) or 255) end
    return def
end

-- =========================
-- HIDE DEFAULT HUD
-- =========================
local hide = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudAmmo"] = true,
    ["DarkRP_HUD"] = true,
    ["DarkRP_EntityDisplay"] = true,
    ["DarkRP_ChatBubbles"] = true,
    ["DarkRP_DrawVoiceChat"] = true,
    ["CHudVoiceStatus"] = true,
    ["CHudVoiceSelfStatus"] = true
}

hook.Add("HUDShouldDraw", "ModernHUD_HideDefault", function(name)
    if hide[name] then return false end
end)

-- =========================
-- SMOOTH VALUES
-- =========================
local lerpHP = 0
local lerpAR = 0

-- =========================
-- ESTILOS COMPARTIDOS
-- =========================
local holoColors = {
    bg = Color(5, 5, 10, 220),
    header = Color(10, 15, 20, 240),
    outline = Color(0, 150, 255, 30),
    accent = Color(0, 150, 255, 255),
    accentArmor = Color(0, 150, 255, 255),
    accentHealth = Color(255, 102, 102, 255),
    text = Color(255, 255, 255, 255),
    subtext = Color(150, 150, 150, 150)
}

local function DrawHoloPanel(x, y, w, h)
    -- Fondo base
    draw.NoTexture()
    surface.SetDrawColor(holoColors.bg.r, holoColors.bg.g, holoColors.bg.b, holoColors.bg.a)
    
    local bg_poly = { {x=x, y=y}, {x=x+w, y=y}, {x=x+w, y=y+h-15}, {x=x+w-15, y=y+h}, {x=x, y=y+h} }
    surface.DrawPoly(bg_poly)

    -- Scanlines sutiles
    surface.SetDrawColor(190, 180, 190, 8)
    for k = 2, h - 2, 4 do surface.DrawLine(x, y + k, x + w, y + k) end
    
    -- Borde hologrfico perimetral
    surface.SetDrawColor(holoColors.outline.r, holoColors.outline.g, holoColors.outline.b, holoColors.outline.a)
    surface.DrawLine(x, y, x + w, y)
    surface.DrawLine(x + w, y, x + w, y + h - 15)
    surface.DrawLine(x + w, y + h - 15, x + w - 15, y + h)
    surface.DrawLine(x + w - 15, y + h, x, y + h)
    surface.DrawLine(x, y + h, x, y)
    
    -- Esquinas mecnicas
    surface.SetDrawColor(holoColors.accent.r, holoColors.accent.g, holoColors.accent.b, 200)
    surface.DrawRect(x, y, 8, 2)
    surface.DrawRect(x, y, 2, 8)
end

local function GetHexagon(cx, cy, R)
    local poly = {}
    for i = 0, 5 do
        local angle = math.rad(i * 60)
        table.insert(poly, {
            x = cx + math.cos(angle) * R,
            y = cy + math.sin(angle) * R
        })
    end
    return poly
end

if IsValid(Virtus_HUD_Avatar) then Virtus_HUD_Avatar:Remove() end
Virtus_HUD_Avatar = vgui.Create("AvatarImage")
Virtus_HUD_Avatar:SetSize(64, 64)
Virtus_HUD_Avatar:SetPos(-100, -100)
Virtus_HUD_Avatar:SetPaintedManually(true)

-- =========================
-- MAIN HUD
-- =========================
-- ==========================================================
-- FUNCIONES AUXILIARES PARA EL HEXGONO CENTRAL PERFECTO
-- ==========================================================
local function DrawThickHexFrame(cx, cy, R_out, R_in, color)
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    draw.NoTexture()
    for i = 0, 5 do
        local A1 = math.rad(i * 60)
        local A2 = math.rad((i + 1) * 60)
        
        local O1 = Vector(cx + math.cos(A1)*R_out, cy + math.sin(A1)*R_out)
        local O2 = Vector(cx + math.cos(A2)*R_out, cy + math.sin(A2)*R_out)
        local I1 = Vector(cx + math.cos(A1)*R_in, cy + math.sin(A1)*R_in)
        local I2 = Vector(cx + math.cos(A2)*R_in, cy + math.sin(A2)*R_in)
        
        surface.DrawPoly({
            {x = O1.x, y = O1.y},
            {x = O2.x, y = O2.y},
            {x = I2.x, y = I2.y},
            {x = I1.x, y = I1.y}
        })
    end
end

local function DrawCornerCuts(cx, cy, R_outer, R_inner, thickness, color)
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    draw.NoTexture()
    for i = 0, 5 do
        local a = math.rad(i * 60)
        local c1 = Vector(cx + math.cos(a)*R_outer, cy + math.sin(a)*R_outer)
        local c2 = Vector(cx + math.cos(a)*R_inner, cy + math.sin(a)*R_inner)
        
        local dir = c1 - c2
        local len = dir:Length()
        local ang = math.deg(math.atan2(dir.y, dir.x))
        local mid = (c1 + c2) / 2
        
        -- Exact length so it doesn't poke out of the borders
        surface.DrawTexturedRectRotated(mid.x, mid.y, len, thickness, -ang)
    end
end

local function DrawHexSegment(cx, cy, R_out, R_in, index, progress, col, invertDir, frameColor)
    local A1 = math.rad(index * 60)
    local A2 = math.rad((index + 1) * 60)
    
    local O1 = Vector(cx + math.cos(A1)*R_out, cy + math.sin(A1)*R_out)
    local O2 = Vector(cx + math.cos(A2)*R_out, cy + math.sin(A2)*R_out)
    local I1 = Vector(cx + math.cos(A1)*R_in, cy + math.sin(A1)*R_in)
    local I2 = Vector(cx + math.cos(A2)*R_in, cy + math.sin(A2)*R_in)
    
    -- Fondo de la barra (Vaco, del mismo color que la barra pero muy oscurecido)
    surface.SetDrawColor(col.r * 0.2, col.g * 0.2, col.b * 0.2, 200)
    draw.NoTexture()
    surface.DrawPoly({
        {x = O1.x, y = O1.y},
        {x = O2.x, y = O2.y},
        {x = I2.x, y = I2.y},
        {x = I1.x, y = I1.y}
    })
    
    -- Parte llena
    if progress > 0 then
        if invertDir then
            local O_mid = LerpVector(progress, O2, O1)
            local I_mid = LerpVector(progress, I2, I1)
            
            surface.SetDrawColor(col.r, col.g, col.b, 255)
            surface.DrawPoly({
                {x = O_mid.x, y = O_mid.y},
                {x = O2.x, y = O2.y},
                {x = I2.x, y = I2.y},
                {x = I_mid.x, y = I_mid.y}
            })
        else
            local O_mid = LerpVector(progress, O1, O2)
            local I_mid = LerpVector(progress, I1, I2)
            
            surface.SetDrawColor(col.r, col.g, col.b, 255)
            surface.DrawPoly({
                {x = O1.x, y = O1.y},
                {x = O_mid.x, y = O_mid.y},
                {x = I_mid.x, y = I_mid.y},
                {x = I1.x, y = I1.y}
            })
        end
    end
    
    -- Detalles: Marcas de segmentacin gruesas (Celdas estilo batera)
    if frameColor then
        surface.SetDrawColor(frameColor.r, frameColor.g, frameColor.b, frameColor.a)
    else
        surface.SetDrawColor(160, 165, 170, 240)
    end
    for k = 1, 4 do
        local t = k / 5
        local tickO = LerpVector(t, O1, O2)
        local tickI = LerpVector(t, I1, I2)
        
        local dir = tickO - tickI
        local len = dir:Length()
        local ang = math.deg(math.atan2(dir.y, dir.x))
        local mid = (tickO + tickI) / 2
        
        surface.DrawTexturedRectRotated(mid.x, mid.y, len + 2, 4, -ang) -- 4 pxeles de grosor para que se vea slido
    end
end

local function GetBarProgress(totalProgress, barIndex, totalBars)
    local pctPerBar = 1.0 / totalBars
    local barStart = (barIndex - 1) * pctPerBar
    local barEnd = barIndex * pctPerBar
    
    if totalProgress <= barStart then return 0 end
    if totalProgress >= barEnd then return 1 end
    
    return (totalProgress - barStart) / pctPerBar
end

-- ==========================================================
-- LGICA DE LA BARRA DE VIDA (CENTRO DE LA PANTALLA)
-- ==========================================================
hook.Add("HUDPaint", "BarraVidaMinimalista", function()
    if (_G.IVOBinosActive or _G.SU_IR_Active) and not LocalPlayer():ShouldDrawLocalPlayer() then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not ply:Alive() or ply:Health() <= 0 then return end
    if ply:GetNWBool("IVO_RTSMode", false) then return end
    
    local cvHide = GetConVar("virtus_hide_hud")
    if cvHide and cvHide:GetBool() then return end
    
    local hp = math.Clamp(ply:Health() / ply:GetMaxHealth(), 0, 1)
    local ar = math.Clamp(ply:Armor() / 100, 0, 1)
    
    lerpHP = Lerp(FrameTime() * 8, lerpHP, hp)
    lerpAR = Lerp(FrameTime() * 8, lerpAR, ar)
    
    local c_bg = _G.VIRTUS_GetHUDColor and _G.VIRTUS_GetHUDColor("bg") or Color(10, 15, 25, 200)
    local c_acc = _G.VIRTUS_GetHUDColor and _G.VIRTUS_GetHUDColor("accent") or Color(0, 150, 255)
    
    local colVida = Color(Lerp(lerpHP, 255, 79), Lerp(lerpHP, 50, 255), Lerp(lerpHP, 50, 100))
    local colArmor = Color(0, 210, 225, 255)
    
    local name = SafeUpper(ply:Nick())
    local job = SafeUpper(ply.getDarkRPVar and ply:getDarkRPVar("job") or team.GetName(ply:Team()))
    local money = ply.getDarkRPVar and DarkRP.formatMoney(ply:getDarkRPVar("money") or 0) or "$0"
    
    surface.SetFont("VirtusHUD_Name")
    local nameW = surface.GetTextSize(name)
    surface.SetFont("VirtusHUD_Job")
    local jobW = surface.GetTextSize(job)
    surface.SetFont("VirtusHUD_Info")
    local moneyW = surface.GetTextSize(money)
    
    local w = math.max(340, nameW + 140)
    local hasJetpack = _G.IVO_HasJetpack and _G.IVO_HasJetpack(ply)
    local h = hasJetpack and 105 or 90
    local x = 80
    local y = ScrH() - h - 80
    local cut = 20
    
    -- HUD BOTTOM LEFT (ROTATED AND SWAYED)
    local tx = x
    local ty = y + 10
    
    if _G.VirtusSway then _G.VirtusSway.Begin3D(-2.5, tx, ty) end
    
    -- Notificación de Puntos
    if IVO_HABILITIES and IVO_HABILITIES.HasUnspentPoints and IVO_HABILITIES.HasUnspentPoints() then
        local pulseAlpha = 150 + math.abs(math.sin(CurTime() * 4)) * 105
        draw.SimpleText("↑ PUNTOS DE HABILIDAD DISPONIBLES", "VirtusHUD_Job", tx, ty - 22, Color(255, 200, 0, pulseAlpha))
    end
    
    -- Name
    draw.SimpleText(name, "VirtusHUD_Name", tx, ty, Color(255, 255, 255))
    
    -- Underline under name
    surface.SetFont("VirtusHUD_Name")
    local nameW = surface.GetTextSize(name)
    surface.SetDrawColor(c_acc.r, c_acc.g, c_acc.b, 120)
    surface.DrawRect(tx, ty + 25, nameW, 1)
    
    -- Job
    surface.SetFont("VirtusHUD_Job")
    local actualJobW, _ = surface.GetTextSize(job)
    draw.SimpleText(job, "VirtusHUD_Job", tx, ty + 34, c_acc)
    
    -- Date & Time (Next to Job)
    local fecha = os.date("%d/%m/%Y")
    local hora = os.date("%H:%M")
    local timeTxt = "[ " .. fecha .. " - " .. hora .. " ]"
    draw.SimpleText(timeTxt, "VirtusHUD_Job", tx + actualJobW + 12, ty + 34, Color(150, 150, 150, 200))
    
    -- ==========================
    -- ARMOR OUTLINE (Drawn BEFORE health bar)
    -- ==========================
    local iconSize = 20
    local barW = math.max(220, w - 50)
    local barH = 22
    
    local bx = tx
    local by = ty + 66
    
    local armorPad = 6
    local a_bx = bx - armorPad
    local a_by = by - armorPad
    local a_barW = barW + armorPad * 2
    local a_barH = barH + armorPad * 2
    local colArmadura = Color(0, 150, 255, 255)
    
    if lerpAR > 0.01 then
        local wA = a_barW * lerpAR
        local t = 2 -- grosor
        local r = 6 -- radio de esquina (curva suave)
        
        surface.SetDrawColor(colArmadura)
        
        -- Borde izquierdo siempre fijo
        surface.DrawRect(a_bx, a_by + r, t, a_barH - r*2)
        
        -- Esquinas izquierdas (curva de 6px)
        surface.DrawRect(a_bx + 4, a_by + 1, 2, 1)
        surface.DrawRect(a_bx + 2, a_by + 2, 2, 1)
        surface.DrawRect(a_bx + 1, a_by + 3, 2, 1)
        surface.DrawRect(a_bx, a_by + 4, 2, 2)
        
        surface.DrawRect(a_bx, a_by + a_barH - 6, 2, 2)
        surface.DrawRect(a_bx + 1, a_by + a_barH - 4, 2, 1)
        surface.DrawRect(a_bx + 2, a_by + a_barH - 3, 2, 1)
        surface.DrawRect(a_bx + 4, a_by + a_barH - 2, 2, 1)
        
        -- Si la armadura está al 100% (o casi), se dibuja el lado derecho completo
        if wA >= a_barW - 2 then
            surface.DrawRect(a_bx + r, a_by, a_barW - r*2, t)
            surface.DrawRect(a_bx + r, a_by + a_barH - t, a_barW - r*2, t)
            
            surface.DrawRect(a_bx + a_barW - t, a_by + r, t, a_barH - r*2)
            
            surface.DrawRect(a_bx + a_barW - 6, a_by + 1, 2, 1)
            surface.DrawRect(a_bx + a_barW - 4, a_by + 2, 2, 1)
            surface.DrawRect(a_bx + a_barW - 3, a_by + 3, 2, 1)
            surface.DrawRect(a_bx + a_barW - 2, a_by + 4, 2, 2)
            
            surface.DrawRect(a_bx + a_barW - 2, a_by + a_barH - 6, 2, 2)
            surface.DrawRect(a_bx + a_barW - 3, a_by + a_barH - 4, 2, 1)
            surface.DrawRect(a_bx + a_barW - 4, a_by + a_barH - 3, 2, 1)
            surface.DrawRect(a_bx + a_barW - 6, a_by + a_barH - 2, 2, 1)
        else
            -- Wipe effect: cut off at wA
            local topW = math.max(0, wA - r)
            if topW > 0 then
                surface.DrawRect(a_bx + r, a_by, topW, t)
                surface.DrawRect(a_bx + r, a_by + a_barH - t, topW, t)
            end
        end
    end
    
    -- ==========================
    -- HEALTH BAR WITH HP ICON
    -- ==========================
    
    -- HEALTH BAR TRACK (Empty translucent dark background)
    draw.RoundedBox(6, bx, by, barW, barH, Color(10, 10, 15, 140))
    
    -- HEALTH FILL (Always White)
    local hpFillW = barW * lerpHP
    if lerpHP > 0.01 then
        draw.RoundedBox(6, bx, by, hpFillW, barH, Color(255, 255, 255, 255))
    end
    
    -- HP ICON (Inside the bar, left aligned)
    if not _G.VirtusHUD_HPMat then 
        _G.VirtusHUD_HPMat = Material("virtus/hp.png", "noclamp smooth")
        if _G.VirtusHUD_HPMat:IsError() then _G.VirtusHUD_HPMat = Material("virtus/hp", "noclamp smooth") end
    end
    
    local iconCol = lerpHP > 0.05 and Color(15, 15, 15, 230) or Color(255, 255, 255, 230)
    surface.SetMaterial(_G.VirtusHUD_HPMat)
    surface.SetDrawColor(iconCol.r, iconCol.g, iconCol.b, iconCol.a)
    surface.DrawTexturedRect(bx + 6, by + barH/2 - iconSize/2, iconSize, iconSize)
    
    -- HEALTH NUMBER inside bar (right-aligned)
    local hpText = tostring(math.max(0, math.Round(ply:Health())))
    surface.SetFont("VirtusHUD_AurebeshBar") 
    local txtW, _ = surface.GetTextSize(hpText)
    
    -- Pasa a blanco cuando la barra deja de cubrirlo
    local numCol = hpFillW > (barW - txtW - 8) and Color(15, 15, 15, 230) or Color(255, 255, 255, 230)
    draw.SimpleText(hpText, "VirtusHUD_AurebeshBar", bx + barW - 6, by + barH/2 - 1, numCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    
    local finalBottomY = by + barH
    
    -- ==========================
    -- STAMINA BAR
    -- ==========================
    local stamina = ply:GetNWFloat("IVO_Stamina", 100)
    local maxStamina = ply:GetNWFloat("IVO_MaxStamina", 100)
    
    if maxStamina > 0 then
        by = by + barH + 12 -- Aumentado de 5 a 12 para evitar que toque la armadura
        local sBarH = 10
        finalBottomY = by + sBarH
        
        local stamPct = math.Clamp(stamina / maxStamina, 0, 1)
        
        -- Background
        draw.RoundedBox(4, bx, by, barW, sBarH, Color(10, 10, 15, 140))
        
        -- Fill
        if stamPct > 0.01 then
            local sCol = Color(255, 150, 0) -- Naranja para stamina
            if stamPct < 0.25 then sCol = Color(255, 50, 50) end
            draw.RoundedBox(4, bx, by, barW * stamPct, sBarH, sCol)
        end
    end
    
    if hasJetpack then
        by = finalBottomY + 5
        finalBottomY = by + barH
        local fuel = ply.JetpackFuel or 100
        local maxFuel = _G.IVO_JetpackCfg and _G.IVO_JetpackCfg.MaxFuel or 100
        local fuelPct = math.Clamp(fuel / maxFuel, 0, 1)
        
        local colJetpack = Color(0, 150, 255)
        if hasJetpack == "cody" then
            local cost = _G.IVO_JetpackCfg and _G.IVO_JetpackCfg.JumpPackCost or 100
            colJetpack = fuel >= cost and Color(255, 140, 0) or Color(200, 50, 50)
        else
            if fuelPct < 0.25 then colJetpack = Color(255, 50, 50)
            elseif fuelPct < 0.5 then colJetpack = Color(255, 180, 0) end
        end

        draw.RoundedBox(8, bx, by, barW, barH - 4, Color(0, 0, 0, 150))
        if fuelPct > 0 then
            draw.RoundedBox(8, bx, by, barW * fuelPct, barH - 4, colJetpack)
        end
        draw.SimpleText(tostring(math.max(0, math.Round(fuel))), "VirtusHUD_AurebeshBar", bx + barW - 6, by + (barH-4)/2, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    if _G.VirtusSway then _G.VirtusSway.End3D() end
    
    _G.VirtusHUD_AnchorX = tx
    _G.VirtusHUD_AnchorY = finalBottomY
end)
-- VIRTUS STUDIOS HEADER (SUPERIOR DERECHA)
-- =========================================================
hook.Add("HUDPaint", "DibujarHUDVirtusHorizontal", function()
    if not LocalPlayer():Alive() or LocalPlayer():Health() <= 0 then return end
    if LocalPlayer():GetNWBool("IVO_RTSMode", false) then return end
    
    local cvHide = GetConVar("virtus_hide_hud")
    if cvHide and cvHide:GetBool() then return end
    
    local ply = LocalPlayer()
    local texto1 = "VIRTUS STUDIOS"
    local build = "V1.0.0"
    
    local targetMoney = ply.getDarkRPVar and (ply:getDarkRPVar("money") or 0) or 0
    _G.VirtusDisplayedMoney = _G.VirtusDisplayedMoney or targetMoney
    _G.VirtusLastTargetMoney = _G.VirtusLastTargetMoney or targetMoney
    
    -- Detección de ganancia/pérdida
    if targetMoney ~= _G.VirtusLastTargetMoney then
        local diff = targetMoney - _G.VirtusLastTargetMoney
        
        -- Acumular si ya había un popup reciente
        if _G.VirtusMoneyPopupTime and (CurTime() - _G.VirtusMoneyPopupTime) < 2.5 then
            _G.VirtusMoneyPopupDiff = (_G.VirtusMoneyPopupDiff or 0) + diff
        else
            _G.VirtusMoneyPopupDiff = diff
        end
        
        _G.VirtusMoneyPopupTime = CurTime()
        _G.VirtusLastTargetMoney = targetMoney
        _G.VirtusMoneyLastUpdate = CurTime()
    end
    
    -- Si el dinero cambia, actualizamos el temporizador para que se muestre
    if math.Round(_G.VirtusDisplayedMoney) ~= targetMoney then
        _G.VirtusMoneyLastUpdate = CurTime()
        -- Interpolación mucho más smooth y lenta (Lerp) para el conteo de la suma
        _G.VirtusDisplayedMoney = Lerp(FrameTime() * 3, _G.VirtusDisplayedMoney, targetMoney)
        
        -- Si está muy cerca, forzar a igualarse para que no quede decimal infinito
        if math.abs(_G.VirtusDisplayedMoney - targetMoney) < 0.5 then
            _G.VirtusDisplayedMoney = targetMoney
        end
    end
    
    -- El texto va alineado a la derecha, para no chocar con la caja de radio
    local padX = 15
    local y = 10 -- Pegado al techo

    local c_acc = _G.VIRTUS_GetHUDColor and _G.VIRTUS_GetHUDColor("accent") or Color(0, 150, 255, 255)

    if _G.VirtusSway then _G.VirtusSway.Begin3D(-2.5, ScrW() - padX, y) end
    draw.SimpleTextOutlined(texto1, "VirtusHUD_Header", ScrW() - padX, y, Color(255, 255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 150))
    draw.SimpleTextOutlined(build, "VirtusHUD_Aurebesh", ScrW() - padX, y + 20, c_acc, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 150))
    
    -- Mostrar dinero total animado
    if _G.VirtusMoneyLastUpdate and (CurTime() - _G.VirtusMoneyLastUpdate) < 5 then
        local alpha = 255
        if (CurTime() - _G.VirtusMoneyLastUpdate) > 4 then
            alpha = 255 * (1 - ((CurTime() - _G.VirtusMoneyLastUpdate) - 4))
        end
        local formattedMoney = DarkRP and DarkRP.formatMoney(math.Round(_G.VirtusDisplayedMoney)) or ("$" .. math.Round(_G.VirtusDisplayedMoney))
        -- Verde claro para el balance
        draw.SimpleTextOutlined(formattedMoney, "VirtusHUD_Money", ScrW() - padX, y + 45, Color(150, 255, 150, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, alpha * 0.6))
    end
    
    -- Mostrar popup flotante de (+ $X) o (- $X)
    if _G.VirtusMoneyPopupTime and (CurTime() - _G.VirtusMoneyPopupTime) < 3 then
        local t = CurTime() - _G.VirtusMoneyPopupTime
        local alpha = 255
        if t > 2 then alpha = 255 * (1 - (t - 2)) end
        
        -- Animación fluida: flota hacia abajo súper lento y poquito
        -- (Uso interpolación lineal para que la velocidad sea constante y lenta)
        local floatOffset = (math.Clamp(t / 3, 0, 1)) * 12
        local diffVal = _G.VirtusMoneyPopupDiff or 0
        
        if diffVal ~= 0 then
            local sign = diffVal > 0 and "+" or "-"
            -- Suma un poco más oscura (verde oscuro o rojo oscuro)
            local col = diffVal > 0 and Color(30, 180, 30, alpha) or Color(180, 30, 30, alpha)
            local txt = sign .. " " .. (DarkRP and DarkRP.formatMoney(math.abs(diffVal)) or ("$" .. math.abs(diffVal)))
            
            draw.SimpleTextOutlined(txt, "VirtusHUD_Money", ScrW() - padX, y + 70 + floatOffset, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, alpha * 0.6))
        end
    end
    
    if _G.VirtusSway then _G.VirtusSway.End3D() end
end)

hook.Add("HUDPaint", "DibujarLineaDegradadaInvertida", function() end)

-- =========================================================
-- HUD MUNDO SOBRE CABEZAS


surface.CreateFont( "HUDMundoTitle", {
    font = "SansSerifFLF", 
    size = 36,           
    weight = 500,        
    antialias = true,    
} )
surface.CreateFont( "HUDMundoJob", {
    font = "SansSerifFLF", 
    size = 22,           
    weight = 500,        
    antialias = true,    
} )

hook.Add( "PostPlayerDraw", "HUD_SobreCabezas_Smooth", function( ply )
    if ply == LocalPlayer() or not ply:Alive() or ply:GetNoDraw() then return end
    if ply:GetNWBool("SU_Invisible", false) and not _G.SU_IR_Active and not LocalPlayer():GetNWBool("SU_Invisible", false) then return end
    
    local cvHide = GetConVar("virtus_hide_hud")
    if cvHide and cvHide:GetBool() then return end

    if ply:GetNWBool("IVOSAM_HideNameplate", false) then return end

    local distMaximaSqr = 62500
    local distComienzoDesvanecidoSqr = 40000

    local distanciaSqr = LocalPlayer():GetPos():DistToSqr( ply:GetPos() )
    if distanciaSqr > distMaximaSqr then return end

    local alpha = 255
    if distanciaSqr > distComienzoDesvanecidoSqr then
        local factor = ( distMaximaSqr - distanciaSqr ) / ( distMaximaSqr - distComienzoDesvanecidoSqr )
        alpha = math.Clamp( factor * 255, 0, 255 )
    end

    local huesoCabeza = ply.SU_HeadBoneCache
    if huesoCabeza == nil then
        huesoCabeza = ply:LookupBone( "ValveBiped.Bip01_Head1" ) or false
        ply.SU_HeadBoneCache = huesoCabeza
    end
    local pos3D
    if huesoCabeza then
        local bp = ply:GetBonePosition(huesoCabeza)
        if bp then
            pos3D = bp + Vector(0, 0, 18)
        else
            pos3D = ply:GetPos() + Vector(0, 0, 85)
        end
    else
        pos3D = ply:GetPos() + Vector( 0, 0, 85 )
    end

    local angulos = LocalPlayer():EyeAngles()
    angulos:RotateAroundAxis( angulos:Forward(), 90 )
    angulos:RotateAroundAxis( angulos:Right(), 90 )

    cam.Start3D2D( pos3D, angulos, 0.1 )
        
        local nombre = SafeUpper(ply:Nick())
        local job = SafeUpper(ply.getDarkRPVar and ply:getDarkRPVar("job") or team.GetName(ply:Team()))
        local colJob = team.GetColor(ply:Team())
        
        local vida = ply:Health()
        local vidaMax = ply:GetMaxHealth()
        local pct = math.Clamp( vida / vidaMax, 0, 1 ) * 100

        draw.SimpleText( nombre, "HUDMundoTitle", 2, -38, Color(0, 0, 0, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
        draw.SimpleText( nombre, "HUDMundoTitle", 0, -40, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )

        draw.SimpleText( job, "HUDMundoJob", 2, -8, Color(0, 0, 0, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
        draw.SimpleText( job, "HUDMundoJob", 0, -10, Color(colJob.r, colJob.g, colJob.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )

        local bw = 240
        local bh = 8
        local bx = -(bw / 2)
        local by = 5

        surface.SetDrawColor( 0, 0, 0, math.min(alpha, 180) )
        surface.DrawRect( bx, by, bw, bh )

        local hpCol = Color(Lerp(pct, 255, 79), Lerp(pct, 50, 255), Lerp(pct, 50, 100), alpha)
        
        surface.SetDrawColor( hpCol.r, hpCol.g, hpCol.b, alpha )
        surface.DrawRect( bx, by, bw * (pct/100), bh )
        
        surface.SetDrawColor( 0, 0, 0, math.min(alpha, 150) )
        for i = 1, 3 do
            local tx = bx + (bw * (i / 4))
            surface.DrawRect( tx, by, 2, bh )
        end

        surface.SetDrawColor( 0, 210, 225, math.min(alpha, 150) )
        surface.DrawOutlinedRect( bx - 1, by - 1, bw + 2, bh + 2 )

        -- DIBUJO DEL MICRFONO AL HABLAR
        if ply:IsSpeaking() then
            local glowMat = Material("sprites/light_glow02_add")
            local micMat = Material("voice/microfono")
            
            local glowSize = 120
            local micSize = 72
            local micY = -140

            surface.SetMaterial(glowMat)
            surface.SetDrawColor(0, 255, 0, alpha)
            surface.DrawTexturedRect(-(glowSize / 2), micY - (glowSize / 2), glowSize, glowSize)
            
            surface.SetMaterial(micMat)
            surface.SetDrawColor(255, 255, 255, alpha)
            surface.DrawTexturedRect(-(micSize / 2), micY - (micSize / 2), micSize, micSize)
        end

    cam.End3D2D()
end )
