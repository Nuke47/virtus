-- sh_tfa_sw_hud.lua (Visuals only, no gameplay logic)

if CLIENT then
    surface.CreateFont("BF2_HUD_Small", { font = "Montserrat Medium", size = 16, weight = 500, antialias = true })
    surface.CreateFont("TFA_SW_Prompt", { font = "Montserrat Bold", size = 20, weight = 600, antialias = true })

    local color_white = Color(255, 255, 255, 240)
    local color_grey = Color(200, 200, 210, 150)
    local color_red = Color(255, 50, 50, 255)
    local color_yellow = Color(255, 200, 0, 255)
    local color_bg = Color(15, 15, 20, 180)

    local smooth_heat = 0
    local smooth_alpha = 0
    local crosshair_expand = 0

    local function DrawArcSegment(x, y, radius, thickness, ang1, ang2, color, alpha)
        surface.SetDrawColor(color.r, color.g, color.b, (color.a * alpha))
        draw.NoTexture()
        local r1, r2 = math.rad(ang1), math.rad(ang2)
        local p1 = {x = x + math.cos(r1) * radius, y = y + math.sin(r1) * radius}
        local p2 = {x = x + math.cos(r2) * radius, y = y + math.sin(r2) * radius}
        local p3 = {x = x + math.cos(r2) * (radius - thickness), y = y + math.sin(r2) * (radius - thickness)}
        local p4 = {x = x + math.cos(r1) * (radius - thickness), y = y + math.sin(r1) * (radius - thickness)}
        surface.DrawPoly({p1, p2, p3, p4})
    end

    local function DrawArc(x, y, radius, thickness, startang, endang, step, color, alpha)
        for i = startang, endang - step, step do
            DrawArcSegment(x, y, radius, thickness, i, i + step, color, alpha)
        end
        local remain = (endang - startang) % step
        if remain > 0 then
            DrawArcSegment(x, y, radius, thickness, endang - remain, endang, color, alpha)
        end
    end

    CreateClientConVar("tfa_sw_hud_enable", "1", true, false)
    CreateClientConVar("tfa_sw_hud_crosshair_color", "255 255 255 240", true, false)

    cvars.AddChangeCallback("tfa_sw_hud_enable", function(convar_name, value_old, value_new)
        local enabled = tonumber(value_new) == 1
        local cvar_hud = GetConVar("cl_tfa_hud_enabled")
        if cvar_hud then cvar_hud:SetBool(not enabled) end
        local cvar_ch = GetConVar("cl_tfa_hud_crosshair_enable")
        if cvar_ch then cvar_ch:SetBool(not enabled) end
    end)

    -- Force initial state
    timer.Simple(1, function()
        local enabled = GetConVar("tfa_sw_hud_enable"):GetBool()
        local cvar_hud = GetConVar("cl_tfa_hud_enabled")
        if cvar_hud then cvar_hud:SetBool(not enabled) end
        local cvar_ch = GetConVar("cl_tfa_hud_crosshair_enable")
        if cvar_ch then cvar_ch:SetBool(not enabled) end
    end)

    hook.Add("HUDPaint", "TFA_StarWars_HUD", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then return end
        
        if ply:GetNWBool("IVO_RTSMode", false) then return end

        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or not wep.IsTFAWeapon then return end

        local class = wep:GetClass()
        if class == "weapon_squadshield_arm" or class == "rw_sw_shield_cg" or string.find(class, "shield") then return end

        local scrW, scrH = ScrW(), ScrH()
        local cx, cy = scrW / 2, scrH / 2

        local tr = ply:GetEyeTrace()
        local sc = tr.HitPos:ToScreen()
        if sc.visible then
            cx, cy = sc.x, sc.y
        end
        
        local clip = wep:Clip1()
        local maxClip = wep:GetMaxClip1() or 0
        if wep.GetStat then maxClip = wep:GetStat("Primary.ClipSize") or maxClip end
        
        local status = wep.GetStatus and wep:GetStatus() or 0
        
        if maxClip > 0 then
            local isCooling = wep:GetNW2Bool("BF2_IsCooling")
            local superEnd = wep:GetNW2Float("BF2_SupercooledUntil", 0)
            local isSupercooled = CurTime() < superEnd
            
            -- Heat logic (0 = full clip, 1 = empty)
            local target_heat = 1 - math.Clamp(clip / maxClip, 0, 1)
            
            if isCooling then 
                target_heat = 1 
            elseif isSupercooled then
                -- The heat bar becomes the buff timer
                target_heat = math.Clamp((superEnd - CurTime()) / 7, 0, 1)
            end
            
            smooth_heat = Lerp(FrameTime() * 15, smooth_heat, target_heat)
            
            -- Alpha logic: Show only if we have heat, or if reloading
            local shouldShow = (target_heat > 0.01) or (status == 4) or isCooling or isSupercooled
            smooth_alpha = Lerp(FrameTime() * 12, smooth_alpha, shouldShow and 1 or 0)
            
            local activeColor = color_white
            if isSupercooled then
                activeColor = color_yellow
            else
                if smooth_heat > 0.70 then activeColor = color_yellow end
                if smooth_heat > 0.95 or clip == 0 then activeColor = color_red end
            end

            if smooth_alpha > 0.01 then
                local isIron = wep:GetIronSights()
                local isPenalty = wep:GetNW2Bool("BF2_IsPenalty")
                
                if isIron then
                    local barW = 280
                    local barH = 6
                    local bx = cx - (barW / 2)
                    local by = cy + 120
                    local r = 3 -- Corner radius for pill shape
                    
                    if isCooling or isPenalty then
                        local progress = 0
                        if isPenalty then
                            local pStart = wep:GetNW2Float("BF2_PenaltyStartTime")
                            local pDur = wep.PenaltyTime or 2.5
                            progress = (CurTime() - pStart) / pDur
                        else
                            local startTime = wep:GetNW2Float("BF2_CoolStartTime")
                            local coolingDuration = wep.CoolingDuration or 1.5
                            progress = (CurTime() - startTime) / coolingDuration
                        end
                        if progress > 1 then progress = 1 end
                        
                        -- Soft translucent outline/glow
                        draw.RoundedBox(r + 1, bx - 1, by - 1, barW + 2, barH + 2, Color(255, 255, 255, smooth_alpha * 15))
                        
                        -- Dark translucent background
                        local bgAlpha = isPenalty and 120 or 100
                        local bgColor = isPenalty and color_red or color_black
                        draw.RoundedBox(r, bx, by, barW, barH, Color(bgColor.r, bgColor.g, bgColor.b, smooth_alpha * bgAlpha))
                        
                        if not isPenalty then
                            local blueStart = wep:GetNW2Float("BF2_BlueStart", 0.15)
                            local blueEnd = wep:GetNW2Float("BF2_BlueEnd", 0.3)
                            local yellowStart = wep:GetNW2Float("BF2_YellowStart", 0.3)
                            local yellowEnd = wep:GetNW2Float("BF2_YellowEnd", 0.35)
                            
                            local colBlue = Color(0, 150, 255)
                            
                            surface.SetDrawColor(colBlue.r, colBlue.g, colBlue.b, smooth_alpha * 200)
                            surface.DrawRect(bx + (barW * blueStart), by, barW * (blueEnd - blueStart), barH)
                            
                            surface.SetDrawColor(color_yellow.r, color_yellow.g, color_yellow.b, smooth_alpha * 200)
                            surface.DrawRect(bx + (barW * yellowStart), by, barW * (yellowEnd - yellowStart), barH)
                        end
                        
                        -- Soft rounded marker
                        local mX = bx + (barW * progress)
                        draw.RoundedBox(2, mX - 1, by - 4, 3, barH + 8, Color(255, 255, 255, smooth_alpha * 255))
                    else
                        -- Soft supercool pulse or normal outline
                        if isSupercooled then
                            local pulse = math.abs(math.sin(CurTime() * 10))
                            draw.RoundedBox(r + 2, bx - 2, by - 2, barW + 4, barH + 4, Color(255, 255, 0, smooth_alpha * (40 + 100 * pulse)))
                            draw.RoundedBox(r + 4, bx - 4, by - 4, barW + 8, barH + 8, Color(255, 255, 0, smooth_alpha * (10 + 40 * pulse)))
                        else
                            draw.RoundedBox(r + 1, bx - 1, by - 1, barW + 2, barH + 2, Color(255, 255, 255, smooth_alpha * 15))
                        end
                        
                        -- Dark translucent background
                        draw.RoundedBox(r, bx, by, barW, barH, Color(0, 0, 0, smooth_alpha * 100))
                        
                        -- Soft continuous fill
                        local fillW = barW * smooth_heat
                        if fillW > 4 then
                            if isSupercooled then
                                -- Timer drains from right to left
                                draw.RoundedBox(r, bx, by, fillW, barH, Color(activeColor.r, activeColor.g, activeColor.b, smooth_alpha * 180))
                            else
                                -- Heat builds from center
                                draw.RoundedBox(r, cx - (fillW / 2), by, fillW, barH, Color(activeColor.r, activeColor.g, activeColor.b, smooth_alpha * 180))
                            end
                        end
                        
                        if target_heat > 0.5 and smooth_alpha > 0.5 and not isSupercooled then
                            surface.SetFont("TFA_SW_Prompt")
                            local txt = "R"
                            local tw, th = surface.GetTextSize(txt)
                            
                            local boxW = 24
                            local boxH = 24
                            local rBx = cx - (boxW / 2)
                            local rBy = by + barH + 12
                            
                            -- Classic Smooth Box Style
                            draw.RoundedBox(4, rBx - 1, rBy - 1, boxW + 2, boxH + 2, Color(255, 255, 255, smooth_alpha * 100))
                            draw.RoundedBox(4, rBx, rBy, boxW, boxH, Color(20, 20, 20, smooth_alpha * 200))
                            
                            surface.SetTextColor(255, 255, 255, smooth_alpha * 255)
                            surface.SetTextPos(rBx + (boxW / 2) - (tw / 2), rBy + (boxH / 2) - (th / 2))
                            surface.DrawText(txt)
                        end
                    end
                else
                    local isSniper = string.find(class, "dc15x") or string.find(class, "valken") or string.find(class, "sniper") or string.find(class, "dlt19x") or string.find(class, "iqa11") or string.find(class, "nt242")
                    local isRPG = string.find(class, "rps") or string.find(class, "plx1") or string.find(class, "rocket") or string.find(class, "rpg")

                    if isSniper then
                        -- MIRA DE SNIPER: Barra de recalentamiento recta
                        local barW = 80
                        local barH = 4
                        local bx = cx - (barW / 2)
                        local by = cy + 40 + crosshair_expand
                        
                        local isCooling = wep:GetNW2Bool("BF2_IsCooling")
                        if isCooling then
                            local isPenalty = wep:GetNW2Bool("BF2_IsPenalty")
                            local progress = 0
                            if isPenalty then
                                local pStart = wep:GetNW2Float("BF2_PenaltyStartTime")
                                local pDur = wep.PenaltyTime or 2.5
                                progress = (CurTime() - pStart) / pDur
                            else
                                local startTime = wep:GetNW2Float("BF2_CoolStartTime")
                                local coolingDuration = wep.CoolingDuration or 1.5
                                progress = (CurTime() - startTime) / coolingDuration
                            end
                            if progress > 1 then progress = 1 end
                            
                            local bgColor = isPenalty and color_red or color_bg
                            draw.RoundedBox(2, bx, by, barW, barH, Color(bgColor.r, bgColor.g, bgColor.b, smooth_alpha * 200))
                            
                            if not isPenalty then
                                local blueStart = wep:GetNW2Float("BF2_BlueStart", 0.3)
                                local blueEnd = wep:GetNW2Float("BF2_BlueEnd", 0.45)
                                local yellowStart = wep:GetNW2Float("BF2_YellowStart", 0.45)
                                local yellowEnd = wep:GetNW2Float("BF2_YellowEnd", 0.5)
                                
                                surface.SetDrawColor(0, 150, 255, smooth_alpha * 255)
                                surface.DrawRect(bx + (barW * blueStart), by, barW * (blueEnd - blueStart), barH)
                                
                                surface.SetDrawColor(color_yellow.r, color_yellow.g, color_yellow.b, smooth_alpha * 255)
                                surface.DrawRect(bx + (barW * yellowStart), by, barW * (yellowEnd - yellowStart), barH)
                            end
                            
                            -- Marker
                            surface.SetDrawColor(255, 255, 255, smooth_alpha * 255)
                            surface.DrawRect(bx + (barW * progress) - 2, by - 2, 4, barH + 4)
                        else
                            if isSupercooled then
                                local pulse = math.abs(math.sin(CurTime() * 10))
                                local glowColor = Color(255, 255, 0, smooth_alpha * (50 + 150 * pulse))
                                draw.RoundedBox(2, bx - 2, by - 2, barW + 4, barH + 4, glowColor)
                            end
                            
                            draw.RoundedBox(2, bx, by, barW, barH, Color(color_bg.r, color_bg.g, color_bg.b, smooth_alpha * 150))
                            local fillW = barW * smooth_heat
                            if fillW > 1 then
                                if isSupercooled then
                                    draw.RoundedBox(2, cx - (fillW / 2), by, fillW, barH, Color(activeColor.r, activeColor.g, activeColor.b, smooth_alpha * 200))
                                else
                                    draw.RoundedBox(2, cx - (fillW / 2), by, fillW, barH, Color(activeColor.r, activeColor.g, activeColor.b, smooth_alpha * 180))
                                end
                            end
                            
                            if target_heat > 0.5 and smooth_alpha > 0.5 and not isSupercooled then
                                surface.SetFont("BF2_HUD_Small")
                                local txt = "R"
                                local tw, th = surface.GetTextSize(txt)
                                
                                local boxW = 24
                                local boxH = 24
                                local rBx = cx - (boxW / 2)
                                local rBy = by + barH + 6
                                
                                -- Classic Smooth Box Style
                                draw.RoundedBox(4, rBx - 1, rBy - 1, boxW + 2, boxH + 2, Color(255, 255, 255, smooth_alpha * 100))
                                draw.RoundedBox(4, rBx, rBy, boxW, boxH, Color(20, 20, 20, smooth_alpha * 200))
                                
                                surface.SetTextColor(255, 255, 255, smooth_alpha * 255)
                                surface.SetTextPos(rBx + (boxW / 2) - (tw / 2), rBy + (boxH / 2) - (th / 2))
                                surface.DrawText(txt)
                            end
                        end
                    elseif isRPG then
                        -- MIRA DE RPG: Indicador de Misiles y Recarga (Sin barra de calor)
                        local by = cy + 40 + crosshair_expand
                        
                        if status == 4 then -- Recargando
                            -- Anillo de recarga giratorio
                            local r = 25 + crosshair_expand
                            DrawArc(cx, cy, r, 2, 0, 360, 5, color_bg, smooth_alpha)
                            
                            local spin = (CurTime() * 300) % 360
                            DrawArc(cx, cy, r, 3, spin, spin + 90, 5, color_yellow, smooth_alpha)
                            
                            draw.SimpleText("RECARGANDO", "BF2_HUD_Small", cx, by, Color(255, 200, 0, smooth_alpha * 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        else
                            -- Mostrar cantidad de misiles en forma de bloques
                            if maxClip > 0 then
                                local padding = 6
                                local blockW = 16
                                local totalW = (maxClip * blockW) + ((maxClip - 1) * padding)
                                local startX = cx - (totalW / 2)
                                
                                for i = 1, maxClip do
                                    local blockX = startX + (i - 1) * (blockW + padding)
                                    local col = (i <= clip) and color_white or color_bg
                                    if clip == 0 then col = color_red end
                                    
                                    draw.RoundedBox(2, blockX, by, blockW, 8, Color(col.r, col.g, col.b, smooth_alpha * 220))
                                end
                                
                                if clip == 0 then
                                    local blink = (math.sin(CurTime() * 15) + 1) / 2
                                    draw.SimpleText("VACÍO", "BF2_HUD_Small", cx, by + 18, Color(255, 50, 50, smooth_alpha * (155 + 100 * blink)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                                end
                            end
                        end
                    else
                        local radius = 18 + crosshair_expand
                local thickness = 3
                
                -- Boundary Notches (Aesthetic frame for the heat bar)
                DrawArc(cx, cy, radius + 2, 5, 43, 45, 1, color_white, smooth_alpha * 0.5)
                DrawArc(cx, cy, radius + 2, 5, 135, 137, 1, color_white, smooth_alpha * 0.5)
                
                local isCooling = wep:GetNW2Bool("BF2_IsCooling")
                if isCooling then
                    local isPenalty = wep:GetNW2Bool("BF2_IsPenalty")
                    local progress = 0

                    if isPenalty then
                        local pStart = wep:GetNW2Float("BF2_PenaltyStartTime")
                        local pDur = wep.PenaltyTime or 2.5
                        progress = (CurTime() - pStart) / pDur
                    else
                        local startTime = wep:GetNW2Float("BF2_CoolStartTime")
                        local coolingDuration = wep.CoolingDuration or 1.5
                        progress = (CurTime() - startTime) / coolingDuration
                    end
                    
                    if progress > 1 then progress = 1 end

                    -- Minigame Background
                    local bgColor = color_bg
                    if isPenalty then bgColor = color_red end
                    
                    DrawArc(cx, cy, radius, thickness, 45, 135, 2, bgColor, smooth_alpha)
                    
                    if not isPenalty then
                        local blueStart = wep:GetNW2Float("BF2_BlueStart", 0.3)
                        local blueEnd = wep:GetNW2Float("BF2_BlueEnd", 0.45)
                        local yellowStart = wep:GetNW2Float("BF2_YellowStart", 0.45)
                        local yellowEnd = wep:GetNW2Float("BF2_YellowEnd", 0.5)
                        
                        local colBlue = Color(0, 150, 255, 255)
                        local colYellow = color_yellow

                        -- Single Blue Arc (left to right)
                        local bAngStart = 135 - (90 * blueEnd)
                        local bAngEnd = 135 - (90 * blueStart)
                        DrawArc(cx, cy, radius, thickness, bAngStart, bAngEnd, 1, colBlue, smooth_alpha)

                        -- Single Yellow Arc (left to right)
                        local yAngStart = 135 - (90 * yellowEnd)
                        local yAngEnd = 135 - (90 * yellowStart)
                        DrawArc(cx, cy, radius, thickness, yAngStart, yAngEnd, 1, colYellow, smooth_alpha)
                    end

                    -- Single Moving marker
                    local mColor = color_white
                    local markerAng = 135 - (90 * progress)
                    DrawArc(cx, cy, radius - 2, thickness + 4, markerAng - 1, markerAng + 1, 1, mColor, smooth_alpha)
                else
                    if isSupercooled then
                        local pulse = math.abs(math.sin(CurTime() * 10))
                        local glowColor = Color(255, 255, 0, smooth_alpha * (50 + 150 * pulse))
                        DrawArc(cx, cy, radius + thickness, 2, 44, 136, 2, glowColor, 1)
                        DrawArc(cx, cy, radius - 2, 2, 44, 136, 2, glowColor, 1)
                    end
                    
                    -- Right half background (46 to 88)
                    DrawArc(cx, cy, radius, thickness, 46, 88, 2, color_bg, smooth_alpha)
                    -- Left half background (92 to 134)
                    DrawArc(cx, cy, radius, thickness, 92, 134, 2, color_bg, smooth_alpha)
                    
                    local spread = 42 * smooth_heat
                    if spread > 0.5 then
                        -- Right half fill (fills from bottom center 88 upwards)
                        DrawArc(cx, cy, radius, thickness, 88 - spread, 88, 2, activeColor, smooth_alpha)
                        -- Left half fill (fills from bottom center 92 upwards)
                        DrawArc(cx, cy, radius, thickness, 92, 92 + spread, 2, activeColor, smooth_alpha)
                    end
                    
                    -- Draw stylized Vent Prompt 'R' if heat is high enough
                    if target_heat > 0.5 and smooth_alpha > 0.5 then
                        surface.SetFont("TFA_SW_Prompt")
                        local txt = "R"
                        local tw, th = surface.GetTextSize(txt)
                        
                        local boxW = 24
                        local boxH = 24
                        local bx = cx - (boxW / 2)
                        local by = cy + radius + 15
                        
                        -- Classic Smooth Box Style
                        draw.RoundedBox(4, bx - 1, by - 1, boxW + 2, boxH + 2, Color(255, 255, 255, smooth_alpha * 100))
                        draw.RoundedBox(4, bx, by, boxW, boxH, Color(20, 20, 20, smooth_alpha * 200))
                        
                        -- Letter R
                        surface.SetTextColor(255, 255, 255, smooth_alpha * 255)
                        surface.SetTextPos(bx + (boxW / 2) - (tw / 2), by + (boxH / 2) - (th / 2))
                        surface.DrawText(txt)
                    end
                    end
                    end
                end
            end
            
            -- ESTILO VIRTUS HUD PARA LA CELDA (DERECHA) - REMOVIDO PARA USAR EL NUEVO CINTURON MINIMALISTA
        end
    end)

    hook.Add("HUDPaint", "TFA_StarWars_Crosshair", function()
        if not GetConVar("tfa_sw_hud_enable"):GetBool() then return end
        
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then return end
        if ply:GetNWBool("IVO_RTSMode", false) then return end
        
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or not wep.IsTFAWeapon then return end
        
        local class = wep:GetClass()
        -- 1. Ocultar la mira para los escudos (Imperial y Riot/Shock)
        if class == "weapon_squadshield_arm" or class == "rw_sw_shield_cg" or string.find(class, "shield") then return end

        if wep:GetIronSights() then return end

        local cx, cy = ScrW() / 2, ScrH() / 2
        
        local tr = ply:GetEyeTrace()
        local sc = tr.HitPos:ToScreen()
        if sc.visible then
            cx, cy = sc.x, sc.y
        end
        local cone = wep.CalculateCone and wep:CalculateCone() or 0.05
        local status = wep.GetStatus and wep:GetStatus() or 0
        local clip = wep:Clip1()
        
        local isCooling = wep:GetNW2Bool("BF2_IsCooling")
        local isSupercooled = CurTime() < wep:GetNW2Float("BF2_SupercooledUntil", 0)
        
        -- Custom Color from ConVar
        local colorStr = GetConVar("tfa_sw_hud_crosshair_color"):GetString()
        local cParts = string.Explode(" ", colorStr)
        local baseColor = color_white
        if #cParts >= 3 then
            baseColor = Color(tonumber(cParts[1]) or 255, tonumber(cParts[2]) or 255, tonumber(cParts[3]) or 255, tonumber(cParts[4]) or 240)
        end
        
        -- Dynamic Color: Turn red if reloading or empty, yellow if supercooled
        local crosshairColor = baseColor
        if status == 4 or clip == 0 or isCooling then
            crosshairColor = color_red
        elseif isSupercooled then
            crosshairColor = color_yellow
        end
        
        -- Movement expansion
        local speed = ply:GetVelocity():Length()
        local moveExpand = math.Clamp(speed / 15, 0, 30)
        
        local targetExpand = math.Clamp(cone * 400, 0, 40) + moveExpand
        crosshair_expand = Lerp(FrameTime() * 12, crosshair_expand, targetExpand)
        
        -- 2. Detectar si es Sniper o RPG para miras personalizadas
        local isRPG = string.find(class, "rps") or string.find(class, "plx1") or string.find(class, "rocket") or string.find(class, "rpg")
        
        -- Quitamos la comprobacion de "scoped" general para evitar afectar a armas como la DC-15LE
        local isSniper = string.find(class, "dc15x") or string.find(class, "valken") or string.find(class, "sniper") or string.find(class, "dlt19x") or string.find(class, "iqa11") or string.find(class, "nt242")

        -- Solo usar estas miras si estamos en tercera persona
        if isSniper then
            -- MIRA DE SNIPER ULTRA LIMPIA
            surface.SetDrawColor(crosshairColor.r, crosshairColor.g, crosshairColor.b, 255)

            -- Chevron central (punto de mira)
            surface.DrawLine(cx - 4, cy + 2, cx, cy - 4)
            surface.DrawLine(cx + 4, cy + 2, cx, cy - 4)
            
            -- Lineas horizontales a los lados del chevron (- ^ -)
            local gap = 10 + crosshair_expand
            local lineLength = 12
            
            surface.SetDrawColor(crosshairColor.r, crosshairColor.g, crosshairColor.b, 200)
            surface.DrawRect(cx - gap - lineLength, cy + 2, lineLength, 2) -- Izquierda
            surface.DrawRect(cx + gap, cy + 2, lineLength, 2)              -- Derecha
            
            return
        elseif isRPG then
            -- MIRA DE RPG MEJORADA (Reticula táctica de lanzacohetes)
            local rSize = 20 + crosshair_expand
            surface.SetDrawColor(crosshairColor.r, crosshairColor.g, crosshairColor.b, 200)
            
            -- Brackets circulares exteriores (Izquierda y derecha)
            DrawArc(cx, cy, rSize, 2, 135, 225, 2, crosshairColor, 1) -- Izquierda
            DrawArc(cx, cy, rSize, 2, 315, 45, 2, crosshairColor, 1)  -- Derecha
            
            -- Linea central horizontal (telemetría)
            surface.DrawRect(cx - rSize - 10, cy - 1, 10, 2)
            surface.DrawRect(cx + rSize, cy - 1, 10, 2)
            
            -- Marcas de caída (drop marks) debajo del centro
            surface.DrawRect(cx - 6, cy + 10, 12, 1)
            surface.DrawRect(cx - 4, cy + 20, 8, 1)
            surface.DrawRect(cx - 2, cy + 30, 4, 1)
            
            -- Punto central hueco
            surface.DrawOutlinedRect(cx - 2, cy - 2, 4, 4)
            return
        end

        -- MIRA STANDARD (Blaster normal)
        -- Subtle center dot
        surface.SetDrawColor(crosshairColor.r, crosshairColor.g, crosshairColor.b, 100)
        surface.DrawRect(cx - 1, cy - 1, 2, 2)
        
        local radius = 4 + crosshair_expand
        local thickness = 2
        
        -- 3 separations for crosshair
        DrawArc(cx, cy, radius, thickness, 5, 55, 2, crosshairColor, 1)    -- Right
        DrawArc(cx, cy, radius, thickness, 125, 175, 2, crosshairColor, 1) -- Left
        DrawArc(cx, cy, radius, thickness, 245, 295, 2, crosshairColor, 1) -- Top
        
        -- Sci-Fi Detail: Outer diagonal lines in the gaps
        DrawArc(cx, cy, radius + 8, 3, 89, 91, 1, crosshairColor, 1)  -- Bottom line
        DrawArc(cx, cy, radius + 8, 3, 209, 211, 1, crosshairColor, 1) -- Top Left line
        DrawArc(cx, cy, radius + 8, 3, 329, 331, 1, crosshairColor, 1) -- Top Right line
    end)

    hook.Add("HUDShouldDraw", "TFA_SW_HideDefaultCrosshair", function(name)
        if not GetConVar("tfa_sw_hud_enable"):GetBool() then return end
        if name == "CHudCrosshair" then
            local ply = LocalPlayer()
            if IsValid(ply) then
                local wep = ply:GetActiveWeapon()
                if IsValid(wep) and wep.IsTFAWeapon then
                    return false
                end
            end
        end
    end)
end







