IVO_HABILITIES = IVO_HABILITIES or {}

local NodeLayouts = {
    general = {
        ["gen_speed_1"]   = { x = 0.4, y = 0.3, icon = "»" },
        ["gen_speed_2"]   = { x = 0.4, y = 0.6, icon = "»»" },
        ["gen_stamina_1"] = { x = 0.6, y = 0.3, icon = "♥" },
        ["gen_stamina_2"] = { x = 0.6, y = 0.6, icon = "♥♥" },
    },
    arc = {
        -- Ejemplos temporales para que veas la pestaña
        ["arc_placeholder_1"] = { x = 0.5, y = 0.2, icon = "A" },
        ["arc_placeholder_2"] = { x = 0.5, y = 0.6, icon = "R" },
    },
    apoyo = {
        ["apoyo_placeholder_1"] = { x = 0.5, y = 0.3, icon = "S" },
    }
}

-- Función auxiliar para verificar si se tiene una habilidad
local function HasSkill(ply, id)
    return IVO_HABILITIES.ClientSkills[id] == true
end

-- Función auxiliar para verificar si se puede desbloquear
local function CanUnlock(ply, id)
    local skill = IVO_HABILITIES.SkillsList[id]
    if not skill then return false end
    
    local pts = IVO_HABILITIES.ClientPoints[skill.type] or 0
    if pts < skill.cost then return false end
    
    if skill.req and not HasSkill(ply, skill.req) then return false end
    
    return true
end

-- Utilidad para dibujar círculos
function IVO_HABILITIES.DrawCircle(x, y, radius, seg)
    local cir = {}
    table.insert(cir, { x = x, y = y, u = 0.5, v = 0.5 })
    for i = 0, seg do
        local a = math.rad((i / seg) * -360)
        table.insert(cir, { x = x + math.sin(a) * radius, y = y + math.cos(a) * radius, u = math.sin(a) / 2 + 0.5, v = math.cos(a) / 2 + 0.5 })
    end
    local a = math.rad(0)
    table.insert(cir, { x = x + math.sin(a) * radius, y = y + math.cos(a) * radius, u = math.sin(a) / 2 + 0.5, v = math.cos(a) / 2 + 0.5 })
    surface.DrawPoly(cir)
end

function IVO_HABILITIES.OpenFullSkillTree(parent)
    parent:Clear()
    
    local w, h = parent:GetWide(), parent:GetTall()
    
    -- Barra de navegación de árboles
    local navBar = vgui.Create("DPanel", parent)
    navBar:SetPos(0, 0)
    navBar:SetSize(w, 50)
    navBar.Paint = function(s, pw, ph)
        draw.RoundedBox(8, 0, 0, pw, ph, Color(15, 20, 25, 240))
    end
    
    -- Content container for the actual tree and info area
    local contentArea = vgui.Create("DPanel", parent)
    contentArea:SetPos(0, 60)
    contentArea:SetSize(w, h - 60)
    contentArea.Paint = function() end
    
    local currentTree = "general"
    local offsetX = 0
    local offsetY = 0
    
    local function RenderTree()
        contentArea:Clear()
        
        local layout = NodeLayouts[currentTree] or {}
        
        -- ÁREA DEL ÁRBOL OCUPA TODO
        local treeArea = vgui.Create("DPanel", contentArea)
        treeArea:SetPos(0, 0)
        treeArea:SetSize(w, contentArea:GetTall())
        
        local isDragging = false
        local dragStartX = 0
        local dragStartY = 0
        
        treeArea.OnMousePressed = function(s, mc)
            if mc == MOUSE_LEFT then
                isDragging = true
                dragStartX, dragStartY = gui.MousePos()
                s.oldOffsetX = offsetX
                s.oldOffsetY = offsetY
            end
        end
        
        treeArea.OnMouseReleased = function(s, mc)
            if mc == MOUSE_LEFT then isDragging = false end
        end
        
        treeArea.nodeButtons = {}
        
        treeArea.Think = function(s)
            if isDragging then
                local mx, my = gui.MousePos()
                offsetX = s.oldOffsetX + (mx - dragStartX)
                offsetY = s.oldOffsetY + (my - dragStartY)
                
                for btn, origin in pairs(s.nodeButtons) do
                    if IsValid(btn) then
                        btn:SetPos(origin.x + offsetX, origin.y + offsetY)
                    end
                end
            end
        end
        
        treeArea.Paint = function(s, pw, ph)
            if _G.VirtusSway then _G.VirtusSway.Begin3D(0) end
            
            -- Fondo completamente transparente para ver el espacio
            
            -- Líneas de conexión
            for id, lyt in pairs(layout) do
                local skill = IVO_HABILITIES.SkillsList[id]
                if skill and skill.req and layout[skill.req] then
                    local reqLyt = layout[skill.req]
                    
                    local startX = reqLyt.x * pw + offsetX
                    local startY = reqLyt.y * ph + offsetY
                    local endX = lyt.x * pw + offsetX
                    local endY = lyt.y * ph + offsetY
                    
                    local isUnlc = HasSkill(LocalPlayer(), id)
                    local isAvail = CanUnlock(LocalPlayer(), id)
                    
                    local lineCol = Color(50, 50, 50, 255)
                    if isUnlc then
                        lineCol = Color(0, 150, 255, 255)
                    elseif isAvail then
                        local pulse = math.abs(math.sin(CurTime() * 3)) * 100
                        lineCol = Color(255, 170, 0, 150 + pulse)
                    end
                    
                    surface.SetDrawColor(lineCol)
                    for i=-1, 1 do
                        surface.DrawLine(startX + i, startY + i, endX + i, endY + i)
                    end
                    
                    if isUnlc then
                        -- Efecto de pulso viajando por la línea
                        local offset = string.byte(id, 1) / 100
                        local frac = (CurTime() * 0.4 + offset) % 1
                        local px = Lerp(frac, startX, endX)
                        local py = Lerp(frac, startY, endY)
                        surface.SetDrawColor(255, 255, 255, 200 * math.sin(frac * math.pi))
                        IVO_HABILITIES.DrawCircle(px, py, 4, 16)
                        surface.SetDrawColor(0, 200, 255, 100 * math.sin(frac * math.pi))
                        IVO_HABILITIES.DrawCircle(px, py, 8, 16)
                    end
                end
            end
            
            if _G.VirtusSway then _G.VirtusSway.End3D() end
        end
        
        local hoverAlpha = 0
        local hoverTarget = nil
        local hoverSkillId = nil
        local hoverBoxW, hoverBoxH = 320, 160
        
        treeArea.PaintOver = function(s, pw, ph)
            local isHoveringAny = false
            for btn, origin in pairs(s.nodeButtons) do
                if IsValid(btn) and btn:IsHovered() then
                    isHoveringAny = true
                    if hoverTarget ~= btn then
                        hoverTarget = btn
                        hoverSkillId = btn.skillId
                        hoverAlpha = 0
                    end
                    break
                end
            end
            
            hoverAlpha = Lerp(FrameTime() * 12, hoverAlpha, isHoveringAny and 1 or 0)
            
            if hoverAlpha > 0.01 and hoverTarget and IsValid(hoverTarget) then
                local skill = IVO_HABILITIES.SkillsList[hoverSkillId]
                if not skill then return end
                
                local tx, ty = hoverTarget:GetPos()
                local cx, cy = tx + hoverTarget:GetWide()/2, ty + hoverTarget:GetTall()/2
                
                local boxX = cx + 60
                local boxY = cy - hoverBoxH / 2
                
                if boxX + hoverBoxW > pw then boxX = cx - 60 - hoverBoxW end
                if boxY < 0 then boxY = 10 end
                if boxY + hoverBoxH > ph then boxY = ph - hoverBoxH - 10 end
                
                local currentW = hoverBoxW * (0.8 + 0.2 * hoverAlpha)
                
                surface.SetAlphaMultiplier(hoverAlpha)
                
                -- Línea conectora
                surface.SetDrawColor(0, 150, 255, 150)
                surface.DrawLine(cx, cy, boxX, boxY + hoverBoxH/2)
                
                -- Caja flotante
                draw.RoundedBox(8, boxX, boxY, currentW, hoverBoxH, Color(10, 15, 20, 240))
                surface.SetDrawColor(0, 150, 255, 80)
                surface.DrawOutlinedRect(boxX, boxY, currentW, hoverBoxH)
                
                -- Esquinas decorativas
                local l = 10
                surface.SetDrawColor(255, 255, 255, 100)
                surface.DrawRect(boxX, boxY, l, 2)
                surface.DrawRect(boxX, boxY, 2, l)
                surface.DrawRect(boxX + currentW - l, boxY, l, 2)
                surface.DrawRect(boxX + currentW - 2, boxY, 2, l)
                
                -- Info
                draw.SimpleText(skill.name, "VF4_Medium_Bold", boxX + 15, boxY + 15, Color(255, 255, 255), 0, 0)
                draw.SimpleText("Costo: " .. skill.cost, "VF4_Small_Bold", boxX + currentW - 15, boxY + 15, Color(255, 170, 0), 2, 0)
                
                local reqTxt = "Requisito: Ninguno"
                local reqColor = Color(150, 150, 150)
                if skill.req then
                    local reqSkill = IVO_HABILITIES.SkillsList[skill.req]
                    if reqSkill then
                        reqTxt = "Requisito: " .. reqSkill.name
                        if not HasSkill(LocalPlayer(), skill.req) then
                            reqColor = Color(255, 50, 50)
                        else
                            reqColor = Color(50, 255, 50)
                        end
                    end
                end
                draw.SimpleText(reqTxt, "VF4_Small", boxX + 15, boxY + 35, reqColor, 0, 0)
                
                surface.SetDrawColor(255, 255, 255, 20)
                surface.DrawLine(boxX + 15, boxY + 55, boxX + currentW - 15, boxY + 55)
                
                -- Descripción con auto-wrap manual (simplificado a un tamaño manejable)
                -- O simplemente lo dibujamos con saltos de línea si es largo
                draw.DrawText(skill.desc, "VF4_Small", boxX + 15, boxY + 65, Color(200, 200, 200), TEXT_ALIGN_LEFT)
                
                local btnTxt = ""
                local btnCol = Color(100, 100, 100)
                
                if HasSkill(LocalPlayer(), hoverSkillId) then
                    btnTxt = "ADQUIRIDO"
                    btnCol = Color(0, 200, 100)
                elseif CanUnlock(LocalPlayer(), hoverSkillId) then
                    btnTxt = "[ CLICK IZQUIERDO PARA DESBLOQUEAR ]"
                    btnCol = Color(255, 170, 0)
                else
                    btnTxt = "BLOQUEADO"
                    btnCol = Color(255, 50, 50)
                end
                
                draw.SimpleText(btnTxt, "VF4_Small_Bold", boxX + currentW/2, boxY + hoverBoxH - 20, btnCol, 1, 1)
                
                surface.SetAlphaMultiplier(1)
            end
        end
        
        -- Barra inferior de puntos
        local function DrawBottomBar(pw, ph)
            local pts = IVO_HABILITIES.ClientPoints[currentTree] or 0
            local totalSkills = 0
            local unlockedSkills = 0
            for k, v in pairs(IVO_HABILITIES.SkillsList) do
                if v.type == currentTree then
                    totalSkills = totalSkills + 1
                    if HasSkill(LocalPlayer(), k) then unlockedSkills = unlockedSkills + 1 end
                end
            end
            
            local lvlTxt = ""
            if currentTree == "general" then
                lvlTxt = "   |   NV " .. LocalPlayer():GetNWInt("IVO_Level", 1)
            else
                lvlTxt = "   |   NV " .. LocalPlayer():GetNWInt("IVO_JobLevel_" .. currentTree, 1)
            end
            
            local barTxt = "◆ " .. pts .. " PUNTOS DISPONIBLES   |   " .. unlockedSkills .. "/" .. totalSkills .. " HABILIDADES" .. lvlTxt
            surface.SetFont("VF4_Medium_Bold")
            local tw, th = surface.GetTextSize(barTxt)
            
            local barW = tw + 60
            local barH = 40
            local barX = pw/2 - barW/2
            local barY = ph - barH - 20
            
            draw.RoundedBox(8, barX, barY, barW, barH, Color(10, 15, 20, 240))
            surface.SetDrawColor(0, 150, 255, 80)
            surface.DrawOutlinedRect(barX, barY, barW, barH)
            
            -- Líneas decorativas al lado
            surface.SetDrawColor(255, 255, 255, 50)
            surface.DrawLine(barX - 100, barY + barH/2, barX - 20, barY + barH/2)
            surface.DrawLine(barX + barW + 20, barY + barH/2, barX + barW + 100, barY + barH/2)
            
            draw.SimpleText(barTxt, "VF4_Medium_Bold", pw/2, barY + barH/2 - 1, Color(255, 255, 255), 1, 1)
        end
        
        -- Nodos
        for id, lyt in pairs(layout) do
            local nx, ny = lyt.x * treeArea:GetWide(), lyt.y * treeArea:GetTall()
            local bw, bh = 100, 110
            
            local btn = vgui.Create("DButton", treeArea)
            btn:SetSize(bw, bh)
            local targetX, targetY = nx - bw/2, ny - bh/2
            btn:SetPos(targetX + offsetX, targetY + offsetY)
            btn:SetText("")
            btn.HoverP = 0
            btn.skillId = id
            
            treeArea.nodeButtons[btn] = {x = targetX, y = targetY}
            
            btn.OnCursorEntered = function(s)
                VIRTUSMENU.PlayUI("navigation/movimiento.wav")
            end
            
            btn.DoClick = function(s)
                if not HasSkill(LocalPlayer(), id) and CanUnlock(LocalPlayer(), id) then
                    VIRTUSMENU.PlayUI("navigation/aceptar.wav")
                    net.Start("IVO_Habilities_Unlock")
                    net.WriteString(id)
                    net.SendToServer()
                    IVO_HABILITIES.ClientSkills[id] = true
                    IVO_HABILITIES.ClientPoints[currentTree] = (IVO_HABILITIES.ClientPoints[currentTree] or 0) - IVO_HABILITIES.SkillsList[id].cost
                else
                    VIRTUSMENU.PlayUI("navigation/error.wav")
                end
            end
            
            btn.Paint = function(s, pw, ph)
                if _G.VirtusSway then _G.VirtusSway.Begin3D(0) end
                
                s.HoverP = Lerp(FrameTime() * 10, s.HoverP, s:IsHovered() and 1 or 0)
                local isUnlc = HasSkill(LocalPlayer(), id)
                local isAvail = CanUnlock(LocalPlayer(), id)
                local skill = IVO_HABILITIES.SkillsList[id] or {}
                
                local colBg = Color(20, 25, 30, 240)
                local colBorder = Color(50, 60, 70)
                local iconCol = Color(150, 150, 150)
                
                if isUnlc then
                    colBg = Color(0, 100, 50, 200)
                    colBorder = Color(0, 255, 100)
                    iconCol = Color(0, 255, 100)
                elseif isAvail then
                    colBg = Color(40, 45, 50, 240)
                    colBorder = Color(200, 200, 200)
                    iconCol = Color(200, 200, 200)
                    if s.HoverP > 0.05 then
                        colBorder = Color(255, 170, 0)
                        iconCol = Color(255, 170, 0)
                    end
                else
                    colBg = Color(10, 12, 15, 200)
                    colBorder = Color(30, 35, 40)
                    iconCol = Color(80, 80, 80)
                end
                
                -- Draw Poly
                local poly = {
                    {x = 10, y = 0}, {x = pw - 10, y = 0}, {x = pw, y = 10},
                    {x = pw, y = ph - 10}, {x = pw - 10, y = ph}, {x = 10, y = ph},
                    {x = 0, y = ph - 10}, {x = 0, y = 10}
                }
                
                draw.NoTexture()
                surface.SetDrawColor(colBg)
                surface.DrawPoly(poly)
                
                surface.SetDrawColor(colBorder)
                for i = 1, #poly do
                    local p1 = poly[i]
                    local p2 = poly[i%#poly + 1]
                    surface.DrawLine(p1.x, p1.y, p2.x, p2.y)
                end
                
                if s.HoverP > 0.05 and not isUnlc then
                    surface.SetDrawColor(255, 170, 0, s.HoverP * 50)
                    surface.DrawPoly(poly)
                end
                
                -- Accents
                surface.SetDrawColor(colBorder)
                surface.DrawLine(0, 20, 0, 40)
                surface.DrawLine(pw-1, ph-40, pw-1, ph-20)
                
                -- Separator
                surface.DrawLine(15, 45, pw-15, 45)
                
                -- Content
                draw.SimpleText(lyt.icon or "?", "VF4_TitleBig", pw/2, 22, iconCol, 1, 1)
                
                -- Nombre en varias líneas si es largo (simplificado)
                local name = skill.name or "Unknown"
                if string.len(name) > 12 then
                    local p1 = string.sub(name, 1, 12)
                    local p2 = string.sub(name, 13)
                    draw.SimpleText(p1, "VF4_Small_Bold", pw/2, 60, Color(255, 255, 255), 1, 1)
                    draw.SimpleText(p2, "VF4_Small_Bold", pw/2, 75, Color(255, 255, 255), 1, 1)
                else
                    draw.SimpleText(name, "VF4_Small_Bold", pw/2, 65, Color(255, 255, 255), 1, 1)
                end
                
                -- Costo
                if not isUnlc and not isAvail and skill.req then
                    draw.SimpleText("REQ LOCK", "VF4_Small", pw/2, 90, Color(255, 50, 50), 1, 1)
                else
                    draw.SimpleText("◇ " .. (skill.cost or 0) .. " PT", "VF4_Small", pw/2, 90, iconCol, 1, 1)
                end
                
                if _G.VirtusSway then _G.VirtusSway.End3D() end
            end
        end
        
        -- Override para agregar el Bottom Bar a PaintOver
        local oldPaintOver = treeArea.PaintOver
        treeArea.PaintOver = function(s, pw, ph)
            oldPaintOver(s, pw, ph)
            DrawBottomBar(pw, ph)
        end
    end
    
    local navTabs = {
        { id = "general", name = "GENERALES" },
        { id = "arc", name = "ARC" },
        { id = "asalto", name = "ASALTO" },
        { id = "reconocimiento", name = "RECONOCIMIENTO" },
        { id = "apoyo", name = "APOYO" },
    }
    
    local lastTabSwitch = 0
    navBar.Think = function(s)
        if not input.IsKeyDown(KEY_A) and not input.IsKeyDown(KEY_D) then return end
        
        local focus = vgui.GetKeyboardFocus()
        if IsValid(focus) and focus:GetClassName() == "TextEntry" then return end
        
        if CurTime() > lastTabSwitch then
            lastTabSwitch = CurTime() + 0.25
            
            local currentIdx = 1
            for k, v in ipairs(navTabs) do if v.id == currentTree then currentIdx = k break end end
            
            if input.IsKeyDown(KEY_D) then
                currentIdx = currentIdx + 1
            elseif input.IsKeyDown(KEY_A) then
                currentIdx = currentIdx - 1
            end
            
            if currentIdx > #navTabs then currentIdx = 1 end
            if currentIdx < 1 then currentIdx = #navTabs end
            
            if currentTree ~= navTabs[currentIdx].id then
                VIRTUSMENU.PlayUI("navigation/aceptar.wav")
                currentTree = navTabs[currentIdx].id
                offsetX = 0
                offsetY = 0
                RenderTree()
            end
        end
    end
    
    local tabX = 20
    for _, tab in ipairs(navTabs) do
        surface.SetFont("VF4_Medium_Bold")
        local tw, th = surface.GetTextSize(tab.name)
        local btnW = tw + 40
        
        local navBtn = vgui.Create("DButton", navBar)
        navBtn:SetPos(tabX, 0)
        navBtn:SetSize(btnW, 50)
        navBtn:SetText("")
        navBtn.HoverP = 0
        
        navBtn.DoClick = function()
            if currentTree ~= tab.id then
                VIRTUSMENU.PlayUI("navigation/aceptar.wav")
                currentTree = tab.id
                offsetX = 0
                offsetY = 0
                RenderTree()
            end
        end
        
        navBtn.Paint = function(s, pw, ph)
            local isActive = (currentTree == tab.id)
            s.HoverP = Lerp(FrameTime() * 10, s.HoverP, (s:IsHovered() or isActive) and 1 or 0)
            
            local c = isActive and Color(255, 170, 0) or Color(0, 150, 255)
            
            local lineW = pw * s.HoverP
            if lineW > 0.5 then
                draw.RoundedBox(2, pw/2 - lineW/2, ph - 4, lineW, 4, c)
            end
            
            local txtCol = (s:IsHovered() or isActive) and Color(255, 255, 255) or Color(150, 150, 150)
            draw.SimpleText(tab.name, "VF4_Medium_Bold", pw/2, ph/2, txtCol, 1, 1)
            
            -- Dot indicator si hay puntos disponibles
            local pts = IVO_HABILITIES.ClientPoints[tab.id] or 0
            if pts > 0 then
                local pulse = math.abs(math.sin(CurTime() * 4)) * 0.5 + 0.5
                local dotR = 4 + pulse * 2
                local dotX = pw/2 + tw/2 + 10
                local dotY = ph/2 - 2
                
                draw.NoTexture()
                -- Glow
                surface.SetDrawColor(255, 170, 0, 40 * pulse)
                IVO_HABILITIES.DrawCircle(dotX, dotY, dotR + 4, 16)
                -- Core dot
                surface.SetDrawColor(255, 170, 0, 200 + 55 * pulse)
                IVO_HABILITIES.DrawCircle(dotX, dotY, dotR, 16)
            end
        end
        
        tabX = tabX + btnW + 10
    end
    
    RenderTree()
end
