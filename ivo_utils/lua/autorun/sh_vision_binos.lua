-- Archivo: lua/autorun/sh_vision_binos.lua

-- ==========================================
-- LGICA DE VALIDACIN (BODYGROUP BINOCULARES)
-- ==========================================
local function HasBinos(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if _G.IsShadowUnit and _G.IsShadowUnit(ply) then return false end
    if _G.HasRangefinder and _G.HasRangefinder(ply) then return false end

    for _, bg in pairs(ply:GetBodyGroups() or {}) do
        local currentVal = ply:GetBodygroup(bg.id)
        
        -- Solo verificamos si hay algo equipado en este bodygroup
        if currentVal > 0 then
            local bgName = string.lower(bg.name)
            local submodelName = ""
            
            if bg.submodels and bg.submodels[currentVal] then
                submodelName = string.lower(bg.submodels[currentVal])
            end

            -- Buscamos palabras clave. Si tu bodygroup se llama diferente, adelo aqu:
            if string.find(bgName, "bino") or string.find(submodelName, "bino") or 
               string.find(bgName, "visor") or string.find(submodelName, "visor") or 
               string.find(bgName, "nvg") or string.find(submodelName, "nvg") then
                if (string.find(submodelName, "up") or string.find(submodelName, "down")) then return true end
            end
        end
    end

    return false
end

-- ==========================================
-- CONTROL DE BODYGROUP ANIMADO (SERVIDOR)
-- ==========================================
if SERVER then
    util.AddNetworkString("Binos_ToggleState")

    -- Asegura que los jugadores descarguen la fuente (respetando maysculas)
    resource.AddFile("resource/fonts/Aurebesh_Bold.otf")

    net.Receive("Binos_ToggleState", function(len, ply)
        local turnOn = net.ReadBool()
        if not IsValid(ply) or not ply:Alive() then return end

        for _, bg in pairs(ply:GetBodyGroups() or {}) do
            local currentVal = ply:GetBodygroup(bg.id)
            if currentVal > 0 then
                local bgName = string.lower(bg.name)
                local submodels = bg.submodels
                if not submodels then continue end
                
                local currentSubName = string.lower(submodels[currentVal] or "")
                
                -- Verificamos si este es el bodygroup de los binoculares
                if string.find(bgName, "bino") or string.find(currentSubName, "bino") or 
                   string.find(bgName, "visor") or string.find(currentSubName, "visor") or 
                   string.find(bgName, "nvg") or string.find(currentSubName, "nvg") then
                    if not (string.find(currentSubName, "up") or string.find(currentSubName, "down")) then continue end
                    
                    -- Buscamos "down" (abajo) si se enciende, o "up" (arriba) si se apaga
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
-- BLOQUEO DEL ZOOM POR DEFECTO (TECLA B)
-- ==========================================
hook.Add("PlayerBindPress", "Binos_BlockDefaultZoom", function(ply, bind, pressed)
    if string.find(string.lower(bind), "+zoom") then
        -- Si el jugador es una Shadow Unit, dejamos que su propio script se encargue de la tecla.
        if _G.IsShadowUnit and _G.IsShadowUnit(ply) then
            return
        end

        -- Para el resto, si no tienen binoculares, bloqueamos el zoom del traje.
        if not HasBinos(ply) then
            return true
        end
    end
end)

-- ==========================================
-- VISIN NOCTURNA Y RECURSOS (CLIENTE)
-- ==========================================
if CLIENT then
    -- Registro de las fuentes Aurebesh Bold
    surface.CreateFont("BinosAurebesh_Large", {
        font = "VirtusBe", -- Nombre interno de la fuente. Cambia a "Aurebesh" si falla.
        size = 34,
        weight = 800,
        antialias = true,
        additive = false,
    })

    surface.CreateFont("BinosAurebesh_Small", {
        font = "VirtusBe",
        size = 18,
        weight = 800,
        antialias = true,
        additive = false,
    })

    local binosActive = false
    local zoomPressTime = 0
    local turnedOnThisPress = false
    local wasZooming = false

    -- Sistema lgico: Tocar para encender/apagar, Mantener para hacer zoom
    hook.Add("Think", "Binos_NightVision_Logic", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() or not HasBinos(ply) then
            if binosActive then binosActive = false end
            wasZooming = false
            return
        end

        local isZooming = ply:KeyDown(IN_ZOOM)

        if isZooming and not wasZooming then
            zoomPressTime = CurTime()
            if not binosActive then
                binosActive = true
                turnedOnThisPress = true
                surface.PlaySound("items/nvg_on.wav")
                
                net.Start("Binos_ToggleState")
                net.WriteBool(true)
                net.SendToServer()
            else
                turnedOnThisPress = false
            end
        elseif not isZooming and wasZooming then
            if CurTime() - zoomPressTime < 0.25 and not turnedOnThisPress then
                binosActive = false
                
                
                net.Start("Binos_ToggleState")
                net.WriteBool(false)
                net.SendToServer()
            end
        end

        -- Sincronizacin manual del bodygroup
        local currentState = "none"
        for _, bg in pairs(ply:GetBodyGroups() or {}) do
            local currentVal = ply:GetBodygroup(bg.id)
            if currentVal > 0 and bg.submodels then
                local bgName = string.lower(bg.name)
                local subName = string.lower(bg.submodels[currentVal] or "")
                
                if string.find(bgName, "bino") or string.find(subName, "bino") or string.find(bgName, "visor") or string.find(subName, "visor") or string.find(bgName, "nvg") or string.find(subName, "nvg") then
                    if string.find(subName, "down") then currentState = "down" end
                    if string.find(subName, "up") then currentState = "up" end
                end
            end
        end

        if currentState ~= ply.LastBinoState then
            if currentState == "down" and not binosActive then
                binosActive = true
                
            elseif (currentState == "up" or currentState == "none") and binosActive then
                binosActive = false
                
            end
            ply.LastBinoState = currentState
        end

        wasZooming = isZooming
        _G.IVOBinosActive = binosActive
    end)

    -- Ocultar el HUD nativo de Zoom de GMod
    hook.Add("HUDShouldDraw", "Binos_HideNativeZoom", function(name)
        if name == "CHudZoom" and HasBinos(LocalPlayer()) then
            return false
        end
    end)

    -- Efecto visual de pantalla
    local colorModifyBino = {
        ["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0.08, ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0.15, ["$pp_colour_contrast"] = 1.2, ["$pp_colour_colour"] = 0.4,
        ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0.8, ["$pp_colour_mulb"] = 0
    }
    hook.Add("RenderScreenspaceEffects", "Binos_NightVision_Effect", function()
        if not binosActive or not HasBinos(LocalPlayer()) then return end
        DrawColorModify(colorModifyBino)
        DrawBloom(0.3, 0.8, 9, 9, 1, 1, 1, 1, 1)
    end)

    -- LUZ AMBIENTAL SUAVE (Para ver en oscuridad total sin quemar el piso)
    hook.Add("Think", "Binos_NightVision_Illumination", function()
        if not _G.IVOBinosActive or not HasBinos(LocalPlayer()) then return end
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        
        local dlight = DynamicLight(ply:EntIndex() + 5001)
        if dlight then
            -- Posicionamos la luz un poco por encima de la cabeza para evitar que queme el piso
            dlight.pos = ply:GetShootPos() + Vector(0, 0, 50)
            dlight.r = 50
            dlight.g = 255
            dlight.b = 50
            dlight.brightness = 0.12  -- Brillo MUY bajo para no deslumbrar
            dlight.Decay = 1000
            dlight.Size = 1000      -- Tamao reducido de 3000 a 1000 para optimizar FPS enormemente
            dlight.DieTime = CurTime() + 0.1
            dlight.noworld = false
            dlight.nomodel = false
        end
    end)

    local cachedPolysBino, cachedLinesBino = nil, nil
    local lastScrW_Bino, lastScrH_Bino = 0, 0
    
    local function GenerateVisorCacheBino(scrW, scrH)
        cachedPolysBino, cachedLinesBino = {}, {}
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
            table.insert(cachedPolysBino, { {x=x1,y=0}, {x=x2,y=0}, {x=x2,y=yTop2}, {x=x1,y=yTop1} })
            table.insert(cachedPolysBino, { {x=x1,y=scrH}, {x=x1,y=yBot1}, {x=x2,y=yBot2}, {x=x2,y=scrH} })
        end

        local lastX, lastYTop, lastYBot
        for i = 0, steps do
            local f = i / steps
            local px = f * scrW
            local sine = math.sin(f * math.pi)
            local pyTop = edgeBarH - (sine * curveDepth)
            local pyBot = scrH - edgeBarH + (sine * curveDepth)
            if lastX then
                table.insert(cachedLinesBino, {x1=lastX, y1=lastYTop, x2=px, y2=pyTop})
                table.insert(cachedLinesBino, {x1=lastX, y1=lastYBot, x2=px, y2=pyBot})
                table.insert(cachedLinesBino, {x1=lastX, y1=lastYTop-1, x2=px, y2=pyTop-1})
                table.insert(cachedLinesBino, {x1=lastX, y1=lastYBot+1, x2=px, y2=pyBot+1})
            end
            lastX, lastYTop, lastYBot = px, pyTop, pyBot
        end
    end

    function _G.DrawBinosStarWarsHUD(customColor, customColorDim)
        local scrW, scrH = ScrW(), ScrH()
        local cx, cy = scrW / 2, scrH / 2
        local ply = LocalPlayer()

        -- Scanlines
        surface.SetDrawColor(0, 0, 0, 100)
        for i = 0, scrH, 4 do
            surface.DrawRect(0, i, scrW, 1)
        end

        local uiColor = customColor or Color(50, 255, 100, 220)
        local uiColorDim = customColorDim or Color(50, 255, 100, 100)

        -- BANDAS CURVAS (Efecto Visor 3D)
        local centerBarH = scrH * 0.10
        local curveDepth = scrH * 0.08
        local edgeBarH = centerBarH + curveDepth
        
        if lastScrW_Bino ~= scrW or lastScrH_Bino ~= scrH then
            GenerateVisorCacheBino(scrW, scrH)
            lastScrW_Bino, lastScrH_Bino = scrW, scrH
        end

        draw.NoTexture()
        surface.SetDrawColor(0, 10, 0, 240)
        for _, poly in ipairs(cachedPolysBino) do surface.DrawPoly(poly) end
        
        surface.SetDrawColor(uiColor)
        for _, line in ipairs(cachedLinesBino) do surface.DrawLine(line.x1, line.y1, line.x2, line.y2) end

        -- Clculo del Telmetro
        local tr = ply:GetEyeTrace()
        local distanceMeters = math.Round(tr.HitPos:Distance(ply:EyePos()) * 0.01905, 1)
        
        -- ==========================================
        -- ZONA SUPERIOR: Telmetro y Datos
        -- ==========================================
        draw.SimpleText("TELEMETRIA", "BinosAurebesh_Small", cx, centerBarH / 2 - 15, uiColorDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("%.1f METROS", distanceMeters), "BinosAurebesh_Large", cx, centerBarH / 2 + 10, uiColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local decorW = 140
        surface.SetDrawColor(uiColorDim)
        surface.DrawLine(cx - decorW, centerBarH / 2 + 10, cx - decorW - 30, centerBarH / 2 - 15)
        surface.DrawLine(cx + decorW, centerBarH / 2 + 10, cx + decorW + 30, centerBarH / 2 - 15)

        -- ==========================================
        -- ZONA INFERIOR IZQUIERDA: Salud y Blindaje
        -- ==========================================
        local hp = math.Clamp(ply:Health(), 0, ply:GetMaxHealth())
        local maxhp = ply:GetMaxHealth()
        local ar = math.Clamp(ply:Armor(), 0, 100)
        local bY = (scrH - edgeBarH / 2) + 20

        draw.SimpleText("OPERADOR: " .. string.upper(ply:Nick()) .. " | INTEGRIDAD", "BinosAurebesh_Small", 50, bY - 20, uiColorDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(hp .. " / " .. maxhp, "BinosAurebesh_Large", 50, bY + 5, uiColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        surface.SetDrawColor(0, 50, 0, 150)
        surface.DrawRect(50, bY + 25, 200, 4)
        surface.SetDrawColor(uiColor)
        surface.DrawRect(50, bY + 25, 200 * (hp / maxhp), 4)

        if ar > 0 then
            draw.SimpleText("BLINDAJE: " .. ar, "BinosAurebesh_Small", 50, bY + 40, uiColorDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        -- ==========================================
        -- ZONA SUPERIOR DERECHA: Brjula
        -- ==========================================
        local real_angle = (-ply:EyeAngles().y) % 360
        if real_angle < 0 then real_angle = real_angle + 360 end
        local rounded_angle = math.Round(real_angle)
        
        local markers = { [0] = "N", [45] = "NE", [90] = "E", [135] = "SE", [180] = "S", [225] = "SO", [270] = "O", [315] = "NO" }
        local closest_marker = math.Round(real_angle / 45) * 45 % 360
        local dir_text = markers[closest_marker] or ""
        local topEdgeY = edgeBarH / 2

        draw.SimpleText("SISTEMA DE NAVEGACION", "BinosAurebesh_Small", scrW - 50, topEdgeY - 15, uiColorDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        draw.SimpleText(rounded_angle .. " " .. dir_text, "BinosAurebesh_Large", scrW - 50, topEdgeY + 10, uiColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        
        surface.SetDrawColor(uiColorDim)
        surface.DrawLine(scrW - 250, topEdgeY + 28, scrW - 50, topEdgeY + 28)

        -- ==========================================
        -- ZONA INFERIOR DERECHA: Jetpack
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
                    local col = isReady and Color(255, 160, 0) or Color(200, 50, 50)
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
                    
                    local r, g, b = 0, 200, 255
                    if fuelPercentage < 0.25 then r, g, b = 255, 50, 50 elseif fuelPercentage < 0.5 then r, g, b = 255, 180, 0 end
                    
                    surface.SetDrawColor(30, 40, 50, 150)
                    surface.DrawRect(scrW - 250, bY + 25, 200, 4)
                    surface.SetDrawColor(r, g, b, 255)
                    surface.DrawRect(scrW - 50 - (200 * fuelPercentage), bY + 25, 200 * fuelPercentage, 4)
                end
            end
        end

        -- ==========================================
        -- ZONA CENTRAL: Retcula Lser
        -- ==========================================
        surface.SetDrawColor(uiColor)
        local radius = 24
        local circleSteps = 32
        for i = 1, circleSteps do
            local a1 = math.rad((i / circleSteps) * -360)
            local a2 = math.rad(((i + 1) / circleSteps) * -360)
            surface.DrawLine(cx + math.sin(a1) * radius, cy + math.cos(a1) * radius, cx + math.sin(a2) * radius, cy + math.cos(a2) * radius)
        end
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
        local maxZoomProgress = math.Clamp((defaultFOV - currentFOV) / (defaultFOV - 20), 0, 1)

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
        draw.SimpleText("SISTEMA MACROBINOCULAR", "BinosAurebesh_Small", cx, scrH - centerBarH / 2 - 10, uiColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        local zoomText = ply:KeyDown(IN_ZOOM) and "OPTICA: ZOOM ACTIVO" or "OPTICA: MODO ESTANDAR"
        draw.SimpleText(zoomText, "BinosAurebesh_Small", cx, scrH - centerBarH / 2 + 10, uiColorDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        surface.DrawLine(cx - 110, scrH - centerBarH / 2 + 10, cx - 140, scrH - centerBarH / 2 - 10)
        surface.DrawLine(cx + 110, scrH - centerBarH / 2 + 10, cx + 140, scrH - centerBarH / 2 - 10)
    end

    -- Interfaz Grfica (HUD): Visor tctico
    hook.Add("HUDPaint", "Binos_StarWars_HUD", function()
        -- Solo dibujar si los binos estn activos Y estamos en primera persona.
        if not binosActive or LocalPlayer():ShouldDrawLocalPlayer() then return end
        _G.DrawBinosStarWarsHUD()
    end)

    -- ==========================================
    -- RENDERIZADO Y RESALTADO DE ENTIDADES
    -- ==========================================
    local cachedTargetEnts_Bino = {}
    local nextUpdate_Bino = 0

    hook.Add("PostDrawOpaqueRenderables", "Binos_Highlight_Entities", function()
        if not binosActive then return end

        -- Cach de entidades: Escaneamos el mapa solo 2 veces por segundo en lugar de 144 veces para subir los FPS
        if CurTime() > nextUpdate_Bino then
            nextUpdate_Bino = CurTime() + 0.5
            cachedTargetEnts_Bino = {}
            for _, ent in ipairs(ents.GetAll()) do
                if IsValid(ent) and not ent:GetNoDraw() then
                    local class = ent:GetClass()
                    if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() or ent.IsSNPC or class == "prop_ragdoll" or class == "class C_ClientRagdoll" then 
                        table.insert(cachedTargetEnts_Bino, ent)
                    end
                end
            end
        end

        render.SuppressEngineLighting(true)
        render.SetColorModulation(0.85, 1.0, 0.85)
        render.SetBlend(0.7)
        local maxDistSqr = 16000000 -- Lmite de dibujado: ~4000 unidades

        local localPly = LocalPlayer()
        for _, ent in ipairs(cachedTargetEnts_Bino) do
            if IsValid(ent) and ent ~= localPly and not ent:GetNoDraw() then
                local shouldDraw = false
                
                if ent:IsPlayer() and ent:Alive() then
                    -- Si el jugador est usando el camuflaje de la SU, los binos normales no pueden resaltarlo
                    if not ent:GetNWBool("SU_Invisible", false) then
                        shouldDraw = true
                    end
                elseif ent:IsNPC() or ent:IsNextBot() or ent.IsSNPC then
                    shouldDraw = true
                elseif ent:GetClass() == "prop_ragdoll" or ent:GetClass() == "class C_ClientRagdoll" then
                    shouldDraw = true
                end
                
                if shouldDraw and ent:GetPos():DistToSqr(localPly:GetPos()) < maxDistSqr then
                    ent:DrawModel()
                end
            end
        end

        render.SetBlend(1)
        render.SetColorModulation(1, 1, 1)
        render.SuppressEngineLighting(false)
    end)

    hook.Add("PreDrawViewModel", "Binos_Highlight_ViewModel", function(vm, ply, weapon)
        if not binosActive then return end
        render.SuppressEngineLighting(true)
        render.SetColorModulation(0.3, 0.6, 0.3)
    end)

    hook.Add("PostDrawViewModel", "Binos_Highlight_ViewModel_End", function(vm, ply, weapon)
        if not binosActive then return end
        render.SuppressEngineLighting(false)
        render.SetColorModulation(1, 1, 1)
    end)

    hook.Add("PreDrawPlayerHands", "Binos_Highlight_Hands", function(hands, vm, ply, weapon)
        if not binosActive then return end
        render.SuppressEngineLighting(true)
        render.SetColorModulation(0.45, 0.55, 0.45)
    end)

    hook.Add("PostDrawPlayerHands", "Binos_Highlight_Hands_End", function(hands, vm, ply, weapon)
        if not binosActive then return end
        render.SuppressEngineLighting(false)
        render.SetColorModulation(1, 1, 1)
    end)


end
hook.Add('Think', 'IVO_Binos_Global_Fix', function() if LocalPlayer and IsValid(LocalPlayer()) and not HasBinos(LocalPlayer()) then _G.IVOBinosActive = false end end) 
