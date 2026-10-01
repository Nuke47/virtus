-- Archivo: lua/autorun/sh_shadow_visor.lua
-- Archivo: lua/autorun/sh_macrobinocular.lua

-- ==========================================
-- LÓGICA DE VALIDACIÓN (EQUIPOS SHADOW UNIT)
-- ==========================================
local function IsShadowUnit(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    local SU_TEAMS = {
        [TEAM_SU_AGT or -1] = true,
        [TEAM_SU_ARF or -1] = true,
        [TEAM_SU_ENG or -1] = true,
        [TEAM_SU_FRN or -1] = true,
        [TEAM_SU_ARC or -1] = true,
        [TEAM_SU_CMD or -1] = true,
        [TEAM_SU_MED or -1]  = true,
	[TEAM_SU_HEAVY or -1]  = true,
	[TEAM_SU_SPEC or -1]  = true,
    }

    return SU_TEAMS[ply:Team()] or false
end

-- Exportar la función para uso global
_G.IsShadowUnit = IsShadowUnit

local function HasSUBinos(ply)
    if not IsValid(ply) then return false end
    
    -- COMPROBAR LA TIENDA
    local ownsUnlock = false
    if SERVER then
        if ply.SW_Data and (ply.SW_Data.active["bg_macrobinocular"] or ply.SW_Data.armario["bg_macrobinocular"] or ply.SW_Data.active["bg_rangefinder"] or ply.SW_Data.armario["bg_rangefinder"]) then
            ownsUnlock = true
        end
    else
        if SW_InvShop and ((SW_InvShop.ActiveInv and (SW_InvShop.ActiveInv["bg_macrobinocular"] or SW_InvShop.ActiveInv["bg_rangefinder"])) or (SW_InvShop.Armario and (SW_InvShop.Armario["bg_macrobinocular"] or SW_InvShop.Armario["bg_rangefinder"]))) then
            ownsUnlock = true
        end
    end
    
    if not ownsUnlock then return false end

    for _, bg in pairs(ply:GetBodyGroups() or {}) do
        local currentVal = ply:GetBodygroup(bg.id)
        if currentVal > 0 then
            local bgName = string.lower(bg.name)
            local subName = bg.submodels and bg.submodels[currentVal] and string.lower(bg.submodels[currentVal]) or ""
            
            local isBino = false
            -- Solo es bino si el submodelo se llama explícitamente "bino up", "bino down", o si contiene bino/visor Y up/down
            if (string.find(subName, "bino") or string.find(subName, "visor") or string.find(subName, "nvg") or string.find(subName, "rangefinder")) and (string.find(subName, "up") or string.find(subName, "down")) then
                isBino = true
            elseif (string.find(bgName, "bino") or string.find(bgName, "visor") or string.find(bgName, "nvg") or string.find(bgName, "rangefinder")) and (string.find(subName, "up") or string.find(subName, "down")) then
                isBino = true
            end

            if isBino then
                return true
            end
        end
    end
    return false
end

-- ==========================================
-- CONTROL DE BODYGROUP ANIMADO (SERVIDOR)
-- ==========================================
if SERVER then
    util.AddNetworkString("SU_Binos_ToggleState")

    net.Receive("SU_Binos_ToggleState", function(len, ply)
        local turnOn = net.ReadBool()
        if not IsValid(ply) or not ply:Alive() or not IsShadowUnit(ply) or not HasSUBinos(ply) then return end

        for _, bg in pairs(ply:GetBodyGroups() or {}) do
            local currentVal = ply:GetBodygroup(bg.id)
            if currentVal > 0 then
                local bgName = string.lower(bg.name)
                local submodels = bg.submodels
                if not submodels then continue end
                
                local currentSubName = string.lower(submodels[currentVal] or "")
                
                local isBino = false
                if (string.find(currentSubName, "bino") or string.find(currentSubName, "visor") or string.find(currentSubName, "nvg") or string.find(currentSubName, "rangefinder")) and (string.find(currentSubName, "up") or string.find(currentSubName, "down")) then
                    isBino = true
                elseif (string.find(bgName, "bino") or string.find(bgName, "visor") or string.find(bgName, "nvg") or string.find(bgName, "rangefinder")) and (string.find(currentSubName, "up") or string.find(currentSubName, "down")) then
                    isBino = true
                end
                
                if isBino then
                    local targetWord = turnOn and "down" or "up"
                    
                    for subId, subName in pairs(submodels) do
                        if string.find(string.lower(subName), targetWord) then
                            ply:SetBodygroup(bg.id, subId)
                            break
                        end
                    end
                end
            end
        end
    end)
end

-- ==========================================
-- VISIÓN INFRARROJA Y RECURSOS (CLIENTE)
-- ==========================================
if CLIENT then
    -- Inicializamos la variable global correctamente en el entorno global
    _G.SU_IR_Active = false 

    surface.CreateFont("BinosAurebesh_Large", {
        font = "VirtusBe",
        size = 34,
        weight = 800,
        antialias = true,
    })

    surface.CreateFont("BinosAurebesh_Small", {
        font = "VirtusBe",
        size = 18,
        weight = 800,
        antialias = true,
    })

    local suZoomPressTime = 0
    local suTurnedOnThisPress = false
    local suWasZooming = false

    -- 1. SISTEMA LÓGICO DEL VISOR SU
    hook.Add("Think", "SU_NightVision_Logic", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() or not IsShadowUnit(ply) then
            if _G.SU_IR_Active then _G.SU_IR_Active = false end
            suWasZooming = false
            return
        end

        local isZooming = ply:KeyDown(IN_ZOOM)
        local hasBinos = HasSUBinos(ply)

        if hasBinos then
            if isZooming and not suWasZooming then
                suZoomPressTime = CurTime()
                if not _G.SU_IR_Active then
                    _G.SU_IR_Active = true
                    suTurnedOnThisPress = true
                    surface.PlaySound("items/nvg_on.wav")
                    net.Start("SU_Binos_ToggleState")
                    net.WriteBool(true)
                    net.SendToServer()
                else
                    suTurnedOnThisPress = false
                end
            elseif not isZooming and suWasZooming then
                if CurTime() - suZoomPressTime < 0.25 and not suTurnedOnThisPress then
                    _G.SU_IR_Active = false
                    surface.PlaySound("items/nvg_off.wav")
                    net.Start("SU_Binos_ToggleState")
                    net.WriteBool(false)
                    net.SendToServer()
                end
            end

            local currentState = "none"
            for _, bg in pairs(ply:GetBodyGroups() or {}) do
                local currentVal = ply:GetBodygroup(bg.id)
                if currentVal > 0 and bg.submodels then
                    local bgName = string.lower(bg.name)
                    local subName = string.lower(bg.submodels[currentVal] or "")
                    
                    local isBino = false
                    if string.find(subName, "bino") or string.find(subName, "visor") or string.find(subName, "nvg") or string.find(subName, "rangefinder") then isBino = true
                    elseif (string.find(bgName, "bino") or string.find(bgName, "visor") or string.find(bgName, "nvg") or string.find(bgName, "rangefinder")) and (string.find(subName, "up") or string.find(subName, "down")) then isBino = true end

                    if isBino then
                        if string.find(subName, "down") then currentState = "down" end
                        if string.find(subName, "up") then currentState = "up" end
                    end
                end
            end

            if currentState ~= ply.LastSUBinoState then
                if currentState == "down" and not _G.SU_IR_Active then
                    _G.SU_IR_Active = true
                    surface.PlaySound("items/nvg_on.wav")
                elseif (currentState == "up" or currentState == "none") and _G.SU_IR_Active then
                    _G.SU_IR_Active = false
                    surface.PlaySound("items/nvg_off.wav")
                end
                ply.LastSUBinoState = currentState
            end
        end

        suWasZooming = isZooming
    end)

    -- 2. CONTROL DE ZOOM Y ELEMENTOS NATIVOS
    hook.Add("HUDShouldDraw", "SU_HideNativeZoom", function(name)
        if name == "CHudZoom" and IsShadowUnit(LocalPlayer()) then return false end
    end)
    
    hook.Add("PlayerBindPress", "SU_BlockDefaultZoom", function(ply, bind, pressed)
        if string.find(string.lower(bind), "+zoom") then
            if not IsShadowUnit(ply) then return end
            
            if not HasSUBinos(ply) then
                if pressed then
                    _G.SU_IR_Active = not _G.SU_IR_Active
                    surface.PlaySound(_G.SU_IR_Active and "items/nvg_on.wav" or "items/nvg_off.wav")
                end
                return true -- Bloquea el zoom nativo de GMod porque no hay binos
            end
        end
    end)

    -- 3. EFECTO VISUAL DE PANTALLA (Infrarrojo)
    local colorModifyIR = {
        ["$pp_colour_addr"] = 0.05, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0.0, ["$pp_colour_contrast"] = 1.3, ["$pp_colour_colour"] = 0.15,
        ["$pp_colour_mulr"] = 0.5, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0
    }
    hook.Add("RenderScreenspaceEffects", "SU_Visor_IR_Effect", function()
        if not _G.SU_IR_Active then return end
        DrawColorModify(colorModifyIR)
        DrawBloom(0.4, 1.2, 9, 9, 1, 1, 1, 1, 1)
    end)

    -- LUZ AMBIENTAL SUAVE (Para ver en oscuridad total sin quemar el piso)
    hook.Add("Think", "SU_Visor_IR_Illumination", function()
        if not _G.SU_IR_Active then return end
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        
        local dlight = DynamicLight(ply:EntIndex() + 5000)
        if dlight then
            -- Posicionamos la luz un poco por encima de la cabeza para evitar que queme el piso directamente
            dlight.pos = ply:GetShootPos() + Vector(0, 0, 50) 
            dlight.r = 255
            dlight.g = 50
            dlight.b = 50
            dlight.brightness = 0.12  -- Brillo MUY bajo para no deslumbrar
            dlight.Decay = 1000
            dlight.Size = 1000      -- Tamaño reducido de 3000 a 1000 para optimizar FPS enormemente
            dlight.DieTime = CurTime() + 0.1
            dlight.noworld = false
            dlight.nomodel = false
        end
    end)

    local cachedPolysIR, cachedLinesIR, cachedReticleIR = nil, nil, nil
    local lastScrW_IR, lastScrH_IR = 0, 0
    
    local function GenerateVisorCacheIR(scrW, scrH)
        cachedPolysIR, cachedLinesIR, cachedReticleIR = {}, {}, {}
        local centerBarH = scrH * 0.10
        local curveDepth = scrH * 0.08
        local edgeBarH = centerBarH + curveDepth
        local steps = 40

        for i = 0, steps - 1 do
            local f1, f2 = i / steps, (i + 1) / steps
            local sine1, sine2 = math.sin(f1 * math.pi), math.sin(f2 * math.pi)
            local x1, x2 = f1 * scrW, f2 * scrW
            local yTop1, yTop2 = edgeBarH - (sine1 * curveDepth), edgeBarH - (sine2 * curveDepth)
            local yBot1, yBot2 = scrH - edgeBarH + (sine1 * curveDepth), scrH - edgeBarH + (sine2 * curveDepth)
            table.insert(cachedPolysIR, { {x=x1,y=0}, {x=x2,y=0}, {x=x2,y=yTop2}, {x=x1,y=yTop1} })
            table.insert(cachedPolysIR, { {x=x1,y=scrH}, {x=x1,y=yBot1}, {x=x2,y=yBot2}, {x=x2,y=scrH} })
        end

        local lastX, lastYTop, lastYBot
        for i = 0, steps do
            local f = i / steps
            local px = f * scrW
            local sine = math.sin(f * math.pi)
            local pyTop = edgeBarH - (sine * curveDepth)
            local pyBot = scrH - edgeBarH + (sine * curveDepth)
            if lastX then
                table.insert(cachedLinesIR, {x1=lastX, y1=lastYTop, x2=px, y2=pyTop})
                table.insert(cachedLinesIR, {x1=lastX, y1=lastYBot, x2=px, y2=pyBot})
            end
            lastX, lastYTop, lastYBot = px, pyTop, pyBot
        end

        local radius = 24
        local circleSteps = 32
        for i = 1, circleSteps do
            local a1 = math.rad((i / circleSteps) * -360)
            local a2 = math.rad(((i + 1) / circleSteps) * -360)
            table.insert(cachedReticleIR, {
                x1 = math.sin(a1) * radius, y1 = math.cos(a1) * radius,
                x2 = math.sin(a2) * radius, y2 = math.cos(a2) * radius
            })
        end
    end

    -- 4. INTERFAZ GRÁFICA COMPLETA (HUD ROJO TÁCTICO)
    hook.Add("HUDPaint", "SU_Visor_HUD", function()
        -- Solo dibujar si el visor está activo Y estamos en primera persona.
        if not _G.SU_IR_Active or LocalPlayer():ShouldDrawLocalPlayer() then return end
 
        local scrW, scrH = ScrW(), ScrH()
        local cx, cy = scrW / 2, scrH / 2
        local ply = LocalPlayer()

        -- Scanlines
        surface.SetDrawColor(0, 0, 0, 150)
        for i = 0, scrH, 4 do
            surface.DrawRect(0, i, scrW, 1)
        end

        local uiColor = Color(255, 60, 40, 220)
        local uiColorDim = Color(255, 60, 40, 100)

        -- BANDAS CURVAS (Efecto Visor 3D)
        local centerBarH = scrH * 0.10
        local curveDepth = scrH * 0.08
        local edgeBarH = centerBarH + curveDepth
        
        if lastScrW_IR ~= scrW or lastScrH_IR ~= scrH then
            GenerateVisorCacheIR(scrW, scrH)
            lastScrW_IR, lastScrH_IR = scrW, scrH
        end

        draw.NoTexture()
        surface.SetDrawColor(15, 0, 0, 240)
        for _, poly in ipairs(cachedPolysIR) do surface.DrawPoly(poly) end
        
        surface.SetDrawColor(uiColor)
        for _, line in ipairs(cachedLinesIR) do surface.DrawLine(line.x1, line.y1, line.x2, line.y2) end

        -- ==========================================
        -- ZONA SUPERIOR CENTRAL: Telémetro
        -- ==========================================
        local tr = ply:GetEyeTrace()
        local distanceMeters = math.Round(tr.HitPos:Distance(ply:EyePos()) * 0.01905, 1)

        draw.SimpleText("TELEMETRIA INFRARROJA", "BinosAurebesh_Small", cx, centerBarH / 2 - 15, uiColorDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("%.1f METROS", distanceMeters), "BinosAurebesh_Large", cx, centerBarH / 2 + 10, uiColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local decorW = 140
        surface.SetDrawColor(uiColorDim)
        surface.DrawLine(cx - decorW, centerBarH / 2 + 10, cx - decorW - 30, centerBarH / 2 - 15)
        surface.DrawLine(cx + decorW, centerBarH / 2 + 10, cx + decorW + 30, centerBarH / 2 - 15)

        local topEdgeY = edgeBarH / 2

        -- ==========================================
        -- ZONA LATERAL IZQUIERDA: Barra de Camuflaje
        -- ==========================================
        local camoEnergy = ply:GetNWFloat("SU_InvisEnergy", 100)
        local isInv = ply:GetNWBool("SU_Invisible", false)
        local camoStatus = isInv and "ACTIVO" or (camoEnergy < 100 and "RECARGA" or "LISTO")
        local camoColor = isInv and uiColor or uiColorDim
        
        local camoBarW = 15
        local camoBarH = 200
        local bx = 80
        local by = cy - camoBarH / 2

        surface.SetDrawColor(uiColorDim)
        surface.DrawOutlinedRect(bx, by, camoBarW, camoBarH)

        for i = 0, 10 do
            local my = by + (camoBarH * (i / 10))
            surface.DrawLine(bx + camoBarW, my, bx + camoBarW + 8, my)
        end

        if camoEnergy > 0 then
            surface.SetDrawColor(camoColor)
            local fillH = camoBarH * (camoEnergy / 100)
            surface.DrawRect(bx + 2, by + camoBarH - fillH, camoBarW - 4, fillH)
        end

        draw.SimpleText("CAMUFLAJE", "BinosAurebesh_Small", bx + camoBarW / 2, by - 15, uiColorDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(math.Round(camoEnergy) .. "%", "BinosAurebesh_Small", bx + camoBarW + 15, by + camoBarH, camoColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(camoStatus, "BinosAurebesh_Small", bx + camoBarW + 15, by + camoBarH - 20, camoColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

        -- ==========================================
        -- ZONA INFERIOR IZQUIERDA: Salud y Blindaje
        -- ==========================================
        local hp = math.Clamp(ply:Health(), 0, ply:GetMaxHealth())
        local maxhp = ply:GetMaxHealth()
        local ar = math.Clamp(ply:Armor(), 0, 100)
        local bY = (scrH - edgeBarH / 2) + 20

        draw.SimpleText("SHADOW UNIT: " .. string.upper(ply:Nick()) .. " | ESTADO", "BinosAurebesh_Small", 50, bY - 20, uiColorDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(hp .. " / " .. maxhp, "BinosAurebesh_Large", 50, bY + 5, uiColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        surface.SetDrawColor(50, 0, 0, 150)
        surface.DrawRect(50, bY + 25, 200, 4)
        surface.SetDrawColor(uiColor)
        surface.DrawRect(50, bY + 25, 200 * (hp / maxhp), 4)

        if ar > 0 then
            draw.SimpleText("BLINDAJE: " .. ar, "BinosAurebesh_Small", 50, bY + 40, uiColorDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        -- ==========================================
        -- ZONA SUPERIOR DERECHA: Brújula (IGUAL AL BINO)
        -- ==========================================
        local real_angle = (-ply:EyeAngles().y) % 360
        if real_angle < 0 then real_angle = real_angle + 360 end
        local rounded_angle = math.Round(real_angle)
        local markers = { [0] = "N", [45] = "NE", [90] = "E", [135] = "SE", [180] = "S", [225] = "SO", [270] = "O", [315] = "NO" }
        local closest_marker = math.Round(real_angle / 45) * 45 % 360
        local dir_text = markers[closest_marker] or ""

        draw.SimpleText("SISTEMA DE NAVEGACION", "BinosAurebesh_Small", scrW - 50, topEdgeY - 15, uiColorDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        draw.SimpleText(rounded_angle .. " " .. dir_text, "BinosAurebesh_Large", scrW - 50, topEdgeY + 10, uiColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        
        surface.SetDrawColor(uiColorDim)
        surface.DrawLine(scrW - 250, topEdgeY + 28, scrW - 50, topEdgeY + 28)

        -- ==========================================
        -- ZONA INFERIOR DERECHA: Jetpack (IGUAL AL BINO)
        -- ==========================================
        if _G.IVO_HasJetpack then
            local jetpackType = _G.IVO_HasJetpack(ply)
            if jetpackType then
                local fuel = ply.JetpackFuel or 100
                local maxFuel = _G.IVO_JetpackCfg and _G.IVO_JetpackCfg.MaxFuel or 100
                local fuelPercentage = math.Clamp(fuel / maxFuel, 0, 1)

                if jetpackType == "cody" then
                    local jumpCost = _G.IVO_JetpackCfg and _G.IVO_JetpackCfg.JumpPackCost or 100
                    local isReady = fuel >= jumpCost
                    local text = isReady and "SALTO: LISTO" or "RECARGANDO"
                    local col = isReady and Color(255, 100, 40) or Color(200, 50, 50)
                    local colDim = Color(col.r, col.g, col.b, 100)

                    draw.SimpleText("MOCHILA TACTICA", "BinosAurebesh_Small", scrW - 50, bY - 20, colDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(text, "BinosAurebesh_Large", scrW - 50, bY + 5, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    
                    surface.SetDrawColor(50, 20, 10, 150)
                    surface.DrawRect(scrW - 250, bY + 25, 200, 4)
                    surface.SetDrawColor(col)
                    surface.DrawRect(scrW - 50 - (200 * fuelPercentage), bY + 25, 200 * fuelPercentage, 4)
                else
                    draw.SimpleText("SISTEMA DE PROPULSION", "BinosAurebesh_Small", scrW - 50, bY - 20, uiColorDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(math.Round(fuelPercentage * 100) .. "%", "BinosAurebesh_Large", scrW - 50, bY + 5, uiColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    
                    surface.SetDrawColor(50, 20, 10, 150)
                    surface.DrawRect(scrW - 250, bY + 25, 200, 4)
                    surface.SetDrawColor(uiColor)
                    surface.DrawRect(scrW - 50 - (200 * fuelPercentage), bY + 25, 200 * fuelPercentage, 4)
                end
            end
        end

        -- ==========================================
        -- ZONA CENTRAL: Retícula Láser
        -- ==========================================
        surface.SetDrawColor(uiColor)
        for _, line in ipairs(cachedReticleIR) do surface.DrawLine(cx + line.x1, cy + line.y1, cx + line.x2, cy + line.y2) end
        local radius = 24
        surface.DrawRect(cx - 1, cy - 1, 2, 2)
        surface.DrawLine(cx, cy - radius, cx, cy - radius - 10)
        surface.DrawLine(cx, cy + radius, cx, cy + radius + 10)
        surface.DrawLine(cx - radius, cy, cx - radius - 10, cy)
        surface.DrawLine(cx + radius, cy, cx + radius + 10, cy)

        -- ==========================================
        -- ZONA LATERAL DERECHA: Barra de Zoom
        -- ==========================================
        local zoomBarW = 15
        local zoomBarH = 200
        local zx = scrW - 60
        local zy = cy - zoomBarH / 2

        surface.SetDrawColor(uiColorDim)
        surface.DrawOutlinedRect(zx, zy, zoomBarW, zoomBarH)

        for i = 0, 10 do
            local my = zy + (zoomBarH * (i / 10))
            surface.DrawLine(zx - 8, my, zx, my)
        end

        local defaultFOV = ply:GetInfoNum("fov_desired", 90)
        local currentFOV = ply:GetFOV()
        local maxZoomProgress = math.Clamp((defaultFOV - currentFOV) / (defaultFOV - 30), 0, 1)

        if maxZoomProgress > 0 then
            surface.SetDrawColor(uiColor)
            local fillH = zoomBarH * maxZoomProgress
            surface.DrawRect(zx + 2, zy + zoomBarH - fillH, zoomBarW - 4, fillH)
        end

        draw.SimpleText("ZOOM", "BinosAurebesh_Small", zx + zoomBarW / 2, zy - 15, uiColorDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(math.Round(maxZoomProgress * 100) .. "%", "BinosAurebesh_Small", zx - 15, zy + zoomBarH, uiColorDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)

        -- Brackets Sci-Fi
        local bw, bh = 200, 120
        surface.SetDrawColor(uiColorDim)
        surface.DrawLine(cx - bw, cy - bh, cx - bw + 20, cy - bh)
        surface.DrawLine(cx - bw, cy - bh, cx - bw, cy + bh)
        surface.DrawLine(cx - bw, cy + bh, cx - bw + 20, cy + bh)
        surface.DrawLine(cx + bw, cy - bh, cx + bw - 20, cy - bh)
        surface.DrawLine(cx + bw, cy - bh, cx + bw, cy + bh)
        surface.DrawLine(cx + bw, cy + bh, cx + bw - 20, cy + bh)

        -- ==========================================
        -- ZONA INFERIOR CENTRAL: Modelo del Sistema
        -- ==========================================
        draw.SimpleText("VISOR INFRARROJO [IR]", "BinosAurebesh_Small", cx, scrH - centerBarH / 2 - 10, uiColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        local opticalStatus = "OPTICA: MODO ESTANDAR"
        if ply:KeyDown(IN_ZOOM) then
            opticalStatus = HasSUBinos(ply) and "OPTICA: ZOOM ACTIVO" or "ERROR: NO HAY ADAPTADOR"
        end
        draw.SimpleText(opticalStatus, "BinosAurebesh_Small", cx, scrH - centerBarH / 2 + 10, uiColorDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        surface.DrawLine(cx - 110, scrH - centerBarH / 2 + 10, cx - 140, scrH - centerBarH / 2 - 10)
        surface.DrawLine(cx + 110, scrH - centerBarH / 2 + 10, cx + 140, scrH - centerBarH / 2 - 10)
    end)

    -- 5. RESALTADO TÉRMICO DE ENTIDADES
    local cachedTargetEnts_IR = {}
    local nextUpdate_IR = 0

    hook.Add("PostDrawOpaqueRenderables", "SU_Highlight_Entities", function()
        if not _G.SU_IR_Active then return end

        -- Caché de entidades: Escaneamos el mapa solo 2 veces por segundo en lugar de 144 veces
        if CurTime() > nextUpdate_IR then
            nextUpdate_IR = CurTime() + 0.5
            cachedTargetEnts_IR = {}
            
            local iter, state, var
            if ents.Iterator then iter, state, var = ents.Iterator() else iter, state, var = ipairs(ents.GetAll()) end
            
            for _, ent in iter, state, var do
                if IsValid(ent) and not ent:GetNoDraw() then
                    local class = ent:GetClass()
                    if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() or ent.IsSNPC or class == "prop_ragdoll" or class == "class C_ClientRagdoll" then 
                        table.insert(cachedTargetEnts_IR, ent)
                    end
                end
            end
        end

        render.SuppressEngineLighting(true)
        render.SetColorModulation(1.0, 0.2, 0.2) 
        render.SetBlend(0.8)
        local maxDistSqr = 16000000 -- Límite de dibujado: ~4000 unidades

        local localPly = LocalPlayer()
        for _, ent in ipairs(cachedTargetEnts_IR or {}) do
            if IsValid(ent) and ent ~= localPly and not ent:GetNoDraw() then
                if not (ent:IsPlayer() and not ent:Alive()) then
                    if ent:GetPos():DistToSqr(localPly:GetPos()) < maxDistSqr then
                        ent:DrawModel() 
                    end
                end
            end
        end

        render.SetBlend(1)
        render.SetColorModulation(1, 1, 1)
        render.SuppressEngineLighting(false)
    end)
end
