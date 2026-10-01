-- Archivo: lua/autorun/sh_rangefinder.lua

-- ==========================================
-- LÓGICA DE VALIDACIÓN (BODYGROUP RANGEFINDER)
-- ==========================================
local function HasRangefinder(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    local ownsUnlock = false
    if SERVER then
        if ply.SW_Data and (ply.SW_Data.active["bg_rangefinder"] or ply.SW_Data.armario["bg_rangefinder"]) then
            ownsUnlock = true
        end
    else
        if SW_InvShop and ((SW_InvShop.ActiveInv and SW_InvShop.ActiveInv["bg_rangefinder"]) or (SW_InvShop.Armario and SW_InvShop.Armario["bg_rangefinder"])) then
            ownsUnlock = true
        end
    end
    
    if not ownsUnlock then return false end

    for _, bg in pairs(ply:GetBodyGroups() or {}) do
        local currentVal = ply:GetBodygroup(bg.id)
        if currentVal > 0 then
            local bgName = string.lower(bg.name)
            local subName = bg.submodels and bg.submodels[currentVal] and string.lower(bg.submodels[currentVal]) or ""

            local isRangefinder = false
            if (string.find(subName, "rangefinder") or string.find(subName, "range finder")) and (string.find(subName, "up") or string.find(subName, "down")) then
                isRangefinder = true
            elseif (string.find(bgName, "rangefinder") or string.find(bgName, "range finder")) and (string.find(subName, "up") or string.find(subName, "down")) then
                isRangefinder = true
            end

            if isRangefinder then
                return true
            end
        end
    end
    return false
end

_G.HasRangefinder = HasRangefinder

-- ==========================================
-- CONTROL DE BODYGROUP ANIMADO (SERVIDOR)
-- ==========================================
if SERVER then
    util.AddNetworkString("Rangefinder_ToggleState")

    net.Receive("Rangefinder_ToggleState", function(len, ply)
        local turnOn = net.ReadBool()
        if not IsValid(ply) or not ply:Alive() or not HasRangefinder(ply) then return end

        for _, bg in pairs(ply:GetBodyGroups() or {}) do
            local bgName = string.lower(bg.name)
            local hasRangefinderInside = false
            
            if string.find(bgName, "rangefinder") or string.find(bgName, "range finder") then
                hasRangefinderInside = true
            elseif bg.submodels then
                for subId, subNameRaw in pairs(bg.submodels) do
                    local subName = string.lower(subNameRaw)
                    if string.find(subName, "rangefinder") or string.find(subName, "range finder") then
                        hasRangefinderInside = true
                        break
                    end
                end
            end

            if hasRangefinderInside and bg.submodels then
                local targetSubId = 0
                
                for subId, subNameRaw in pairs(bg.submodels) do
                    local subName = string.lower(subNameRaw)
                    if turnOn then
                        if string.find(subName, "down") then
                            targetSubId = subId
                            break
                        end
                    else
                        if string.find(subName, "up") or string.find(subName, "rangefinder") or string.find(subName, "range finder") then
                            targetSubId = subId
                            break
                        end
                    end
                end
                
                if targetSubId == 0 and not turnOn then
                    for subId, subNameRaw in pairs(bg.submodels) do
                        local subName = string.lower(subNameRaw)
                        if string.find(subName, "up") then
                            targetSubId = subId
                            break
                        end
                    end
                end

                ply:SetBodygroup(bg.id, targetSubId)
            end
        end
    end)
end

-- ==========================================
-- VISIÓN, TRACKING Y HUD (CLIENTE)
-- ==========================================
if CLIENT then
    surface.CreateFont("BinosAurebesh_Tiny", {
        font = "VirtusBe",
        size = 14,
        weight = 500,
        antialias = true,
    })

    local rfActive = false
    local rfLoopSound = nil
    
    local zoomPressTime = 0
    local turnedOnThisPress = false

    local function DrawFilledCircle(x, y, radius, quality)
        local circle = {}
        quality = quality or 16
        local step = (math.pi * 2) / quality
        for i = 1, quality do
            circle[i] = {
                x = x + math.cos(i * step) * radius,
                y = y + math.sin(i * step) * radius
            }
        end
        draw.NoTexture()
        surface.DrawPoly(circle)
    end
    local wasZooming = false

    -- Variable global para apagar otros addons (ej. Compas o Defcon)
    _G.IVORangefinderActive = false

    hook.Add("Think", "Rangefinder_Logic", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() or not HasRangefinder(ply) then
            if rfActive then rfActive = false end
            wasZooming = false
            _G.IVORangefinderActive = false
            return
        end

        local isSU = false
        if _G.IsShadowUnit and _G.IsShadowUnit(ply) then isSU = true end
        if not isSU and string.find(string.lower(ply:GetModel() or ""), "shadow") then isSU = true end
        
        local isZooming = (ply:KeyDown(IN_ZOOM) or _G.IVO_ZoomDown)
        
        if isSU then
            local desiredState = _G.SU_IR_Active == true
            if rfActive ~= desiredState then
                rfActive = desiredState
                
                net.Start("Rangefinder_ToggleState")
                net.WriteBool(rfActive)
                net.SendToServer()
            end
        else
            if isZooming and not wasZooming then
                zoomPressTime = CurTime()
                if not rfActive then
                    rfActive = true
                    turnedOnThisPress = true
                    surface.PlaySound("items/nvg_on.wav")
                    
                    net.Start("Rangefinder_ToggleState")
                    net.WriteBool(true)
                    net.SendToServer()
                else
                    turnedOnThisPress = false
                end
            elseif not isZooming and wasZooming then
                if CurTime() - zoomPressTime < 0.25 and not turnedOnThisPress then
                    rfActive = false
                    surface.PlaySound("items/nvg_off.wav")
                    
                    net.Start("Rangefinder_ToggleState")
                    net.WriteBool(false)
                    net.SendToServer()
                end
            end
        end

        local currentState = "none"
        for _, bg in pairs(ply:GetBodyGroups() or {}) do
            local currentVal = ply:GetBodygroup(bg.id)
            if bg.submodels and bg.submodels[currentVal] then
                local bgName = string.lower(bg.name)
                local subName = string.lower(bg.submodels[currentVal])
                
                if string.find(bgName, "rangefinder") or string.find(bgName, "range finder") or string.find(subName, "rangefinder") or string.find(subName, "range finder") then
                    if string.find(subName, "down") then 
                        currentState = "down" 
                    elseif string.find(subName, "up") or string.find(subName, "rangefinder") or string.find(subName, "range finder") then 
                        currentState = "up" 
                    end
                end
            end
        end

        if currentState ~= ply.LastRFState then
            if currentState == "down" and not rfActive then
                rfActive = true
            elseif (currentState == "up" or currentState == "none") and rfActive then
                rfActive = false
            end
            ply.LastRFState = currentState
        end

        wasZooming = isZooming
        _G.IVORangefinderActive = rfActive
    end)

    -- OCULTAR EL RESTO DEL HUD
    local allowedHUDs = {
        ["CHudChat"] = true,
        ["CHudGMod"] = true,
        ["CHudWeaponSelection"] = true,
        ["CHudMenu"] = true,
        ["NetGraph"] = true
    }
    hook.Add("HUDShouldDraw", "Rangefinder_HideHUDs", function(name)
        if _G.IVORangefinderActive then
            if not allowedHUDs[name] then
                return false
            end
        end
    end)


    hook.Add("CalcView", "Rangefinder_CustomZoomView", function(ply, pos, angles, fov)
        if not IsValid(ply) or not ply:Alive() or ply:ShouldDrawLocalPlayer() or (hook.Call("ShouldDrawLocalPlayer", GAMEMODE, ply) == true) or ply:GetViewEntity() ~= ply then return end
        if not HasRangefinder(ply) then return end
        local targetFOV = fov
        if _G.IVORangefinderActive and (ply:KeyDown(IN_ZOOM) or _G.IVO_ZoomDown) then targetFOV = 30 end
        ply.IVO_RFSmoothFOV = ply.IVO_RFSmoothFOV or fov
        ply.IVO_RFSmoothFOV = Lerp(FrameTime() * 10, ply.IVO_RFSmoothFOV, targetFOV)
        if math.abs(ply.IVO_RFSmoothFOV - fov) > 0.5 then
            return { origin = pos, angles = angles, fov = ply.IVO_RFSmoothFOV }
        end
    end)
    -- EFECTO DE PANTALLA
    local colorModifyRF = {
        ["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0.05, ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0.1, ["$pp_colour_contrast"] = 1.1, ["$pp_colour_colour"] = 0.6,
        ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0.6, ["$pp_colour_mulb"] = 0
    }

    local colorModifySU = {
        ["$pp_colour_addr"] = 0.08, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0.1, ["$pp_colour_contrast"] = 1.1, ["$pp_colour_colour"] = 0.6,
        ["$pp_colour_mulr"] = 0.6, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0
    }
    
    hook.Add("RenderScreenspaceEffects", "Rangefinder_Effect", function()
        if not _G.IVORangefinderActive or not HasRangefinder(LocalPlayer()) then return end
        
        local ply = LocalPlayer()
        local isSU = false
        if _G.IsShadowUnit and _G.IsShadowUnit(ply) then isSU = true end
        if not isSU and string.find(string.lower(ply:GetModel() or ""), "shadow") then isSU = true end
        if isSU then return end -- Shadow Unit visor handles its own screen effects
        
        DrawColorModify(colorModifyRF)
        DrawBloom(0.2, 0.5, 9, 9, 1, 1, 1, 1, 1)
    end)

    hook.Add("Think", "Rangefinder_Illumination", function()
        if not _G.IVORangefinderActive then return end
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        
        local isSU = false
        if _G.IsShadowUnit and _G.IsShadowUnit(ply) then isSU = true end
        if not isSU and string.find(string.lower(ply:GetModel() or ""), "shadow") then isSU = true end
        if isSU then return end -- Shadow Unit visor handles its own light
        
        if not ply:ShouldDrawLocalPlayer() then
            local dlight = DynamicLight(ply:EntIndex() + 5002)
            if dlight then
                dlight.pos = ply:GetShootPos() + Vector(0, 0, 50)
                
                dlight.r = 0
                dlight.g = 100
                dlight.b = 255
                
                dlight.brightness = 0.12
                dlight.Decay = 1000
                dlight.Size = 1000
                dlight.DieTime = CurTime() + 0.1
                dlight.noworld = false
                dlight.nomodel = false
            end
        end
    end)

    -- TRACKING DE ENEMIGOS EN RANGO VISUAL (Line of Sight)
    local cachedTargetEnts_RF = {}
    local nextUpdate_RF = 0

    hook.Add("Think", "Rangefinder_UpdateTargets", function()
        if not _G.IVORangefinderActive then return end
        if CurTime() > nextUpdate_RF then
            nextUpdate_RF = CurTime() + 0.25
            cachedTargetEnts_RF = {}
            local ply = LocalPlayer()
            local eyePos = ply:EyePos()
            
            local scrW, scrH = ScrW(), ScrH()
            local cx, cy = scrW / 2, scrH / 2
            
            local nearestEnt = nil
            local nearestDist = math.huge

            for _, ent in ipairs(ents.GetAll()) do
                if IsValid(ent) and not ent:GetNoDraw() and ent ~= ply then
                    if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() or ent.IsSNPC then
                        if ent:IsPlayer() and not ent:Alive() then continue end
                        if ent:Health() <= 0 then continue end
                        
                        local pos = ent:WorldSpaceCenter()
                        local headPos = ent.EyePos and ent:EyePos() or (ent:GetPos() + Vector(0, 0, 64))
                        local distSq = eyePos:DistToSqr(pos)
                        
                        if distSq < 16000000 then
                            local screenPos = pos:ToScreen()
                            if screenPos.visible then
                                -- Trace a la cabeza primero (ayuda cuando el NPC sube escaleras y su pecho está oculto)
                                local tr = util.TraceLine({
                                    start = eyePos,
                                    endpos = headPos,
                                    filter = {ply, ent},
                                    mask = MASK_OPAQUE
                                })
                                
                                -- Si la cabeza no se ve, intentar con el centro
                                if tr.Hit then
                                    tr = util.TraceLine({
                                        start = eyePos,
                                        endpos = pos,
                                        filter = {ply, ent},
                                        mask = MASK_OPAQUE
                                    })
                                end
                                
                                if not tr.Hit then
                                    local distToCenter = math.abs(screenPos.x - cx) + math.abs(screenPos.y - cy)
                                    if distToCenter < nearestDist then
                                        nearestDist = distToCenter
                                        nearestEnt = ent
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            if IsValid(nearestEnt) then
                table.insert(cachedTargetEnts_RF, nearestEnt)
            end
        end
    end)

    -- GENERADOR DE GEOMETRIA DEL HUD
    local cachedLinesRF = nil
    local cachedPolysRF = nil
    local lastScrW_RF, lastScrH_RF = 0, 0

    local function GenerateRangefinderCache(scrW, scrH)
        cachedLinesRF = {}
        cachedPolysRF = {}
        
        local cx, cy = scrW / 2, scrH / 2
        
        local topH = scrH * 0.15
        local botH = scrH * 0.15
        
        local panelW = scrW * 0.1 -- Flechas laterales
        local topW = scrW * 0.25 -- MUCHO más ancho para que la brújula y texto quepan perfectamente
        
        -- Extremos superior e inferior de las flechas laterales
        local pTop = topH * 1.5
        local pBot = scrH - botH * 1.5
        
        -- Polígono Izquierdo (Forma de flecha)
        table.insert(cachedPolysRF, {
            {x = 0, y = pTop},
            {x = panelW, y = cy},
            {x = 0, y = pBot}
        })
        -- Contornos Izquierdo (Gruesos)
        for i = 0, 3 do
            local o = i
            table.insert(cachedLinesRF, {x1 = o, y1 = pTop + o*2, x2 = panelW - o, y2 = cy})
            table.insert(cachedLinesRF, {x1 = panelW - o, y1 = cy, x2 = o, y2 = pBot - o*2})
            table.insert(cachedLinesRF, {x1 = o, y1 = pTop + o*2, x2 = o, y2 = pBot - o*2})
        end

        -- Polígono Derecho (Forma de flecha)
        table.insert(cachedPolysRF, {
            {x = scrW, y = pTop},
            {x = scrW, y = pBot},
            {x = scrW - panelW, y = cy}
        })
        -- Contornos Derecho (Gruesos)
        for i = 0, 3 do
            local o = i
            table.insert(cachedLinesRF, {x1 = scrW - o, y1 = pTop + o*2, x2 = scrW - panelW + o, y2 = cy})
            table.insert(cachedLinesRF, {x1 = scrW - panelW + o, y1 = cy, x2 = scrW - o, y2 = pBot - o*2})
            table.insert(cachedLinesRF, {x1 = scrW - o, y1 = pTop + o*2, x2 = scrW - o, y2 = pBot - o*2})
        end

        -- Polígono Superior (Forma de flecha hacia abajo)
        local arrowTopY = scrH * 0.18
        table.insert(cachedPolysRF, {
            {x = cx - topW, y = 0},
            {x = cx + topW, y = 0},
            {x = cx, y = arrowTopY}
        })
        -- Contornos Superior
        for i = 0, 3 do
            local o = i
            table.insert(cachedLinesRF, {x1 = cx - topW + o*2, y1 = o, x2 = cx + topW - o*2, y2 = o})
            table.insert(cachedLinesRF, {x1 = cx - topW + o*2, y1 = o, x2 = cx, y2 = arrowTopY - o})
            table.insert(cachedLinesRF, {x1 = cx + topW - o*2, y1 = o, x2 = cx, y2 = arrowTopY - o})
        end

        -- Polígono Inferior (Forma de flecha hacia arriba)
        local arrowBotY = scrH - scrH * 0.18
        table.insert(cachedPolysRF, {
            {x = cx - topW, y = scrH},
            {x = cx, y = arrowBotY},
            {x = cx + topW, y = scrH}
        })
        -- Contornos Inferior
        for i = 0, 3 do
            local o = i
            table.insert(cachedLinesRF, {x1 = cx - topW + o*2, y1 = scrH - o, x2 = cx + topW - o*2, y2 = scrH - o})
            table.insert(cachedLinesRF, {x1 = cx - topW + o*2, y1 = scrH - o, x2 = cx, y2 = arrowBotY + o})
            table.insert(cachedLinesRF, {x1 = cx + topW - o*2, y1 = scrH - o, x2 = cx, y2 = arrowBotY + o})
        end
    end

    hook.Add("HUDPaint", "Rangefinder_HUD", function()
        if not rfActive or not HasRangefinder(LocalPlayer()) or LocalPlayer():ShouldDrawLocalPlayer() then return end
        
        local scrW, scrH = ScrW(), ScrH()
        local cx, cy = scrW / 2, scrH / 2
        local ply = LocalPlayer()
        
        local isSU = false
        if _G.IsShadowUnit and _G.IsShadowUnit(ply) then isSU = true end
        if not isSU and string.find(string.lower(ply:GetModel() or ""), "shadow") then isSU = true end

        local uiColor = Color(140, 240, 255, 255)
        local uiColorBg = Color(20, 100, 150, 45) -- Holographic cyan background
        
        if isSU then
            uiColor = Color(255, 50, 50, 255)
            uiColorBg = Color(150, 20, 20, 45)
        end

        if not isSU then
            -- DIBUJAR HUD NORMAL DE RANGEFINDER (FLECHAS CELESTES)
            surface.SetDrawColor(0, 0, 0, 100)
            for i = 0, scrH, 4 do surface.DrawRect(0, i, scrW, 1) end

            if lastScrW_RF ~= scrW or lastScrH_RF ~= scrH then
                GenerateRangefinderCache(scrW, scrH)
                lastScrW_RF, lastScrH_RF = scrW, scrH
            end

            draw.NoTexture()
            
            surface.SetDrawColor(uiColorBg)
            for _, poly in ipairs(cachedPolysRF) do surface.DrawPoly(poly) end
            
            surface.SetDrawColor(uiColor)
            for _, line in ipairs(cachedLinesRF) do surface.DrawLine(line.x1, line.y1, line.x2, line.y2) end

            -- CENTRAL RETICLE (Dinámico por Zoom)
            local isZooming = (ply.IVO_RFSmoothFOV or ply:GetFOV()) < (ply:GetInfoNum("fov_desired", 90) - 5)
            local rRadius = isZooming and 16 or 8
            surface.DrawCircle(cx, cy, rRadius, uiColor.r, uiColor.g, uiColor.b, 255)
            surface.DrawCircle(cx, cy, rRadius + 1, uiColor.r, uiColor.g, uiColor.b, 255)

            -- BRÚJULA SUPERIOR (TIPO TAPE)
            local topY = scrH * 0.05
            local compassW = 400
            local compassLeftX = cx - compassW/2
            
            local real_angle = (-ply:EyeAngles().y) % 360
            if real_angle < 0 then real_angle = real_angle + 360 end
            
            surface.SetDrawColor(uiColor)
            surface.DrawLine(compassLeftX, topY + 25, cx + compassW/2, topY + 25)
            
            local fovRange = 60
            local pxPerDegree = compassW / (fovRange * 2)
            
            render.SetScissorRect(compassLeftX, topY, cx + compassW/2, topY + 40, true)
            for i = -fovRange, fovRange do
                local deg = math.Round(real_angle + i)
                local drawnDeg = deg % 360
                if drawnDeg < 0 then drawnDeg = drawnDeg + 360 end
                
                if deg % 15 == 0 then
                    local lineX = cx + (i * pxPerDegree)
                    surface.SetDrawColor(uiColor)
                    
                    local text = ""
                    if drawnDeg == 0 then text = "N"
                    elseif drawnDeg == 45 then text = "NE"
                    elseif drawnDeg == 90 then text = "E"
                    elseif drawnDeg == 135 then text = "SE"
                    elseif drawnDeg == 180 then text = "S"
                    elseif drawnDeg == 225 then text = "SO"
                    elseif drawnDeg == 270 then text = "O"
                    elseif drawnDeg == 315 then text = "NO"
                    end
                    
                    if text ~= "" then
                        surface.DrawRect(lineX - 1, topY + 15, 2, 10)
                        draw.SimpleText(text, "BinosAurebesh_Small", lineX, topY + 5, uiColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    else
                        surface.DrawRect(lineX, topY + 20, 1, 5)
                        if deg % 30 == 0 then
                            draw.SimpleText(tostring(drawnDeg), "BinosAurebesh_Small", lineX, topY + 5, uiColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        end
                    end
                end
            end
            render.SetScissorRect(0, 0, 0, 0, false)
            
            -- Cono central
            local triY = topY + 35
            surface.SetDrawColor(uiColorBg)
            surface.DrawPoly({
                {x = cx - 15, y = triY}, {x = cx + 15, y = triY}, {x = cx, y = triY + 25}
            })
            surface.SetDrawColor(uiColor)
            for i = 0, 1 do
                surface.DrawLine(cx - 15 + i, triY, cx + i, triY + 25)
                surface.DrawLine(cx + 15 - i, triY, cx - i, triY + 25)
                surface.DrawLine(cx - 15, triY + i, cx + 15, triY + i)
            end

            -- INTERACTIVIDAD: PANEL IZQUIERDO
            local panelW = scrW * 0.1
            local leftTextX = panelW * 0.15 
            
            local pPos = ply:GetPos()
            
            local currentTime = os.date("%H %M")
            local coords = math.Round(pPos.x) .. " " .. math.Round(pPos.y)
            local distCenter = string.format("%.1f", pPos:Distance(Vector(0,0,0))/1000)
            
            surface.DrawLine(leftTextX + 60, cy - 40, leftTextX + 80, cy - 50)
            surface.DrawLine(leftTextX + 80, cy - 50, leftTextX + 95, cy - 50)
            surface.DrawLine(leftTextX + 65, cy - 15, leftTextX + 85, cy - 15)

            draw.SimpleText(currentTime, "BinosAurebesh_Tiny", leftTextX, cy - 40, uiColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(coords, "BinosAurebesh_Tiny", leftTextX, cy - 15, uiColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            surface.DrawRect(leftTextX - 10, cy + 4, 110, 2)
            
            draw.SimpleText(distCenter, "BinosAurebesh_Tiny", leftTextX + 80, cy + 30, uiColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            local hpPct = math.Clamp(ply:Health() / ply:GetMaxHealth(), 0, 1)
            local arPct = math.Clamp(ply:Armor() / 100, 0, 1)
            local ammoPct = 0
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and wep:GetMaxClip1() > 0 then
                ammoPct = math.Clamp(wep:Clip1() / wep:GetMaxClip1(), 0, 1)
            end

            local circleX = panelW * 0.25 
            surface.SetDrawColor(uiColor.r, uiColor.g, uiColor.b, 50)
            surface.DrawCircle(circleX, cy + 55, 12, uiColor.r, uiColor.g, uiColor.b, 255)
            surface.SetDrawColor(uiColor.r, uiColor.g, uiColor.b, 255)
            DrawFilledCircle(circleX, cy + 55, math.max(1, 12 * hpPct))
            
            surface.SetDrawColor(uiColor.r, uiColor.g, uiColor.b, 50)
            surface.DrawCircle(circleX, cy + 85, 8, uiColor.r, uiColor.g, uiColor.b, 255)
            surface.SetDrawColor(uiColor.r, uiColor.g, uiColor.b, 255)
            DrawFilledCircle(circleX, cy + 85, math.max(1, 8 * arPct))
            
            surface.SetDrawColor(uiColor.r, uiColor.g, uiColor.b, 50)
            surface.DrawCircle(circleX, cy + 105, 4, uiColor.r, uiColor.g, uiColor.b, 255)
            surface.SetDrawColor(uiColor.r, uiColor.g, uiColor.b, 255)
            DrawFilledCircle(circleX, cy + 105, math.max(1, 4 * ammoPct))

            -- INTERACTIVIDAD: PANEL DERECHO
            local rightX = scrW - (panelW * 0.45) 
            local r_radius = 45
            
            surface.DrawCircle(rightX, cy, r_radius, uiColor.r, uiColor.g, uiColor.b, 255)
            surface.DrawCircle(rightX, cy, 6, uiColor.r, uiColor.g, uiColor.b, 255)
            
            local northAngle = math.rad(ply:EyeAngles().y + 90) 
            local arrX = rightX + math.cos(northAngle) * 35
            local arrY = cy - math.sin(northAngle) * 35
            surface.DrawLine(rightX, cy, arrX, arrY)
            surface.DrawLine(rightX+1, cy, arrX+1, arrY)
            surface.DrawLine(rightX-1, cy, arrX-1, arrY)
            surface.DrawCircle(arrX, arrY, 4, uiColor.r, uiColor.g, uiColor.b, 255)
            
            surface.DrawRect(rightX - 4, cy - r_radius - 15, 8, 20)
            surface.DrawRect(rightX - 4, cy + r_radius - 5, 8, 20) 
            surface.DrawRect(rightX - r_radius - 15, cy - 4, 20, 8)
            surface.DrawRect(rightX + r_radius - 5, cy - 4, 20, 8)
            
            surface.DrawLine(rightX - 20, cy + r_radius + 40, rightX + 20, cy + r_radius + 40) 
            draw.SimpleText(math.Round(pPos.z), "BinosAurebesh_Small", rightX, cy + r_radius + 55, uiColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- BOTTOM ARROW INFO (Objetivo actual)
            local botY = scrH - scrH * 0.05 
            local tEnt = ply:GetEyeTrace().Entity
            if IsValid(tEnt) and (tEnt:IsPlayer() or tEnt:IsNPC()) then
                local tHp = tEnt:Health()
                local tMax = tEnt:GetMaxHealth()
                local tWep = "UNARMED"
                if tEnt.GetActiveWeapon and IsValid(tEnt:GetActiveWeapon()) then
                    tWep = tEnt:GetActiveWeapon():GetPrintName() or tEnt:GetActiveWeapon():GetClass()
                end
                
                draw.SimpleText("TARGET HP :  " .. tHp, "BinosAurebesh_Small", cx, botY - 20, uiColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(string.upper(tWep), "BinosAurebesh_Small", cx, botY + 5, uiColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                draw.SimpleText("NO TARGET DATA", "BinosAurebesh_Small", cx, botY, Color(uiColor.r, uiColor.g, uiColor.b, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
        -- DIBUJADO DE BRACKETS Y VIDA PARA ENEMIGOS VISIBLES
        if isSU and not _G.SU_IR_Active then return end -- Si es Shadow Unit, solo dibujar si su visor estǭ activo
        
        surface.SetDrawColor(uiColor)
        local nearestEnt = cachedTargetEnts_RF[1]
        
        if IsValid(nearestEnt) then
            local ent = nearestEnt
            local pos = ent.WorldSpaceCenter and ent:WorldSpaceCenter() or (ent:GetPos() + Vector(0, 0, 40))
            local screenPos = pos:ToScreen()
            
            if screenPos.visible then
                local dist = ply:GetPos():Distance(ent:GetPos())
                local sizeW = math.Clamp(8000 / dist, 30, 200)
                local sizeH = sizeW * 1.2
                local cut = sizeW * 0.2
                local x, y = screenPos.x, screenPos.y
                
                -- Dibujar brackets básicos para el MÁS CERCANO
                surface.SetDrawColor(uiColor.r, uiColor.g, uiColor.b, 255)
                for i = 0, 1 do
                    local o = i 
                    surface.DrawLine(x - sizeW + cut, y - sizeH + o, x + sizeW - cut, y - sizeH + o)
                    surface.DrawLine(x - sizeW + cut, y - sizeH + o, x - sizeW + o, y - sizeH + cut)
                    surface.DrawLine(x + sizeW - cut, y - sizeH + o, x + sizeW + o, y - sizeH + cut)
                    surface.DrawLine(x - sizeW + o, y - sizeH + cut, x - sizeW + o, y + sizeH - 20)
                    surface.DrawLine(x + sizeW + o, y - sizeH + cut, x + sizeW + o, y + sizeH - 20)
                    surface.DrawLine(x - sizeW - 20, y + sizeH - 20 + o, x + sizeW + 20, y + sizeH - 20 + o)
                    surface.DrawLine(x - sizeW/2 + o, y + sizeH - 20, x - sizeW/2 + o, y + sizeH)
                    surface.DrawLine(x + sizeW/2 + o, y + sizeH - 20, x + sizeW/2 + o, y + sizeH)
                end
                
                -- Línea punteada desde el centro
                local dx = x - cx
                local dy = y - cy
                local distPxls = math.sqrt(dx*dx + dy*dy)
                local steps = math.floor(distPxls / 15)
                
                surface.SetDrawColor(uiColorBg.r, uiColorBg.g, uiColorBg.b, 150)
                if steps > 2 then
                    for i = 1, steps, 2 do
                        local lx1 = cx + (dx * (i / steps))
                        local ly1 = cy + (dy * (i / steps))
                        local lx2 = cx + (dx * ((i+0.5) / steps))
                        local ly2 = cy + (dy * ((i+0.5) / steps))
                        surface.DrawLine(lx1, ly1, lx2, ly2)
                    end
                end
                
                -- Vida del enemigo a la derecha del bracket
                local entHealth = ent:Health()
                local entMaxHealth = ent:GetMaxHealth()
                if entMaxHealth > 0 and entHealth > 0 then
                    draw.SimpleText("HP: " .. entHealth, "BinosAurebesh_Tiny", x + sizeW + 15, y - sizeH/2, uiColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    
                    local hpPct = math.Clamp(entHealth / entMaxHealth, 0, 1)
                    surface.SetDrawColor(uiColorBg)
                    surface.DrawRect(x + sizeW + 15, y - sizeH/2 + 10, 40, 4)
                    surface.SetDrawColor(uiColor)
                    surface.DrawRect(x + sizeW + 15, y - sizeH/2 + 10, 40 * hpPct, 4)
                end
            end
        end
    end)
    
    hook.Add("PostDrawOpaqueRenderables", "Rangefinder_Highlight_Entities", function()
        if not rfActive then return end

        render.SuppressEngineLighting(true)
        render.SetColorModulation(1.0, 0.3, 0.3)
        render.SetBlend(0.8)

        for _, ent in ipairs(cachedTargetEnts_RF) do
            if IsValid(ent) and not ent:GetNoDraw() then
                ent:DrawModel()
            end
        end

        render.SetBlend(1)
        render.SetColorModulation(1, 1, 1)
        render.SuppressEngineLighting(false)
    end)
end
