if SERVER then AddCSLuaFile() end
include("autorun/ivo_rts_config.lua")

if not CLIENT then return end

-- 1. Ocultar HUD normal del jugador
hook.Add("HUDShouldDraw", "IVO_RTS_HideHUD", function(name)
    local ply = LocalPlayer()
    if IsValid(ply) and ply:GetNWBool("IVO_RTSMode", false) then
        if name == "CHudGMod" then return end
        return false
    end
end)

-- Fuentes Modernas
surface.CreateFont("IVORTS_Title", { font = "SansSerifFLF", size = 26, weight = 800, antialias = true })
surface.CreateFont("IVORTS_TextBold", { font = "SansSerifFLF", size = 18, weight = 800, antialias = true })
surface.CreateFont("IVORTS_Text", { font = "SansSerifFLF", size = 14, weight = 500, antialias = true })

-- State
local SelectedDroids = {}
local DragStart = nil
local RightDragStart = nil
local CurrentDeploySelection = nil
local FormationType = "line"

local GunshipPayload = {}
local GunshipCostCache = 0
local GunshipPreparing = false

local Formations = {"line", "column", "wedge", "skirmish"}
local fIndex = 1

-- HUD Colors
local color_bg = Color(10, 15, 20, 240)
local color_bg_light = Color(20, 25, 30, 240)
local color_accent = Color(0, 150, 255, 255)
local color_text = Color(240, 240, 240, 255)
local color_text_dark = Color(150, 150, 150, 255)

local DeployOptions = IVO_RTS.Config.DeployOptions

local UI_Lerps = {}
local function GetLerp(id, target, speed)
    UI_Lerps[id] = UI_Lerps[id] or target
    UI_Lerps[id] = Lerp(FrameTime() * speed, UI_Lerps[id], target)
    return UI_Lerps[id]
end

local function RecalcGunshipCost()
    local total = 0
    for _, class in ipairs(GunshipPayload) do
        total = total + ((IVO_RTS.Config.UnitCostsGMP and IVO_RTS.Config.UnitCostsGMP[class]) or 0)
    end
    GunshipCostCache = total
end

local function ScreenToWorldPoint(x, y)
    local dir = gui.ScreenToVector(x, y)
    local ply = LocalPlayer()
    local origin = IVO_RTS.CurrentCameraPos or EyePos()
    local tr = util.TraceLine({ start = origin, endpos = origin + (dir * 10000), filter = ply })
    return tr.HitPos
end

local function SelectDroidsInBox(startX, startY, endX, endY)
    SelectedDroids = {}
    local minX, maxX = math.min(startX, endX), math.max(startX, endX)
    local minY, maxY = math.min(startY, endY), math.max(startY, endY)
    
    local function check_ent(ent)
        if IsValid(ent) and ent:GetNWEntity("CommanderOwner") == LocalPlayer() then
            local pos = ent:GetPos():ToScreen()
            if pos.visible and pos.x >= minX and pos.x <= maxX and pos.y >= minY and pos.y <= maxY then
                table.insert(SelectedDroids, ent)
            end
        end
    end

    for _, ent in ipairs(ents.FindByClass("npc_droid_*")) do check_ent(ent) end
    for _, ent in ipairs(ents.FindByClass("lvs_fakehover_aat")) do check_ent(ent) end
end

local function CalculateRTSGoals(targetPos, formation, validEnts)
    local ply = LocalPlayer()
    local center = Vector(0,0,0)
    for _, e in ipairs(validEnts) do center = center + e:GetPos() end
    center = center / #validEnts
    
    local diff = targetPos - center
    diff.z = 0
    local dir = Vector(1, 0, 0)
    if diff:LengthSqr() > 400 then dir = diff:GetNormalized() end
    local right = dir:Angle():Right()

    ply.IVO_RTS_PathLines = {}
    ply.IVO_RTS_PathLinesTime = CurTime() + 4
    
    local goals = {}
    for i, d in ipairs(validEnts) do
        local offset = Vector(0,0,0)
        if formation == "line" then
            local spread = 80
            local side = (i % 2 == 0) and 1 or -1
            local rank = math.floor(i / 2)
            offset = right * (side * rank * spread)
        elseif formation == "column" then
            local spreadX = 70
            local spreadY = 70
            local row = math.floor((i-1)/2)
            local col = (i-1)%2
            local side = (col == 0) and -0.5 or 0.5
            offset = right * (side * spreadX) - dir * (row * spreadY)
        elseif formation == "wedge" then
            local spreadX = 80
            local spreadY = 80
            local side = (i % 2 == 0) and 1 or -1
            local rank = math.floor(i / 2)
            offset = (right * (side * rank * spreadX)) - (dir * (rank * spreadY))
        elseif formation == "skirmish" then
            local radius = 30 * math.sqrt(i)
            local angle = i * 137.5
            local rad = math.rad(angle)
            offset = Vector(math.cos(rad) * radius, math.sin(rad) * radius, 0)
        end
        local targetGoal = targetPos + offset
        table.insert(goals, targetGoal)
    end
    
    for i, d in ipairs(validEnts) do
        table.insert(ply.IVO_RTS_PathLines, {ent = d, goal = goals[i]})
    end
end

-- UI Drawing Helpers
local blur = Material("pp/blurscreen")
local function DrawBlur(x, y, w, h, amount)
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blur)
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * (amount or 6))
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        render.SetScissorRect(x, y, x + w, y + h, true)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        render.SetScissorRect(0, 0, 0, 0, false)
    end
end

-- Layout Functions
local function GetTopBarLayout()
    local w = 750
    local h = 60
    local x = (ScrW() - w) / 2
    local y = 20
    return x, y, w, h
end

local function GetBottomCenterBarLayout()
    local w = 800
    local h = 120
    local x = (ScrW() - w) / 2
    local y = ScrH() - h - 20
    return x, y, w, h
end

local function GetRightGridLayout()
    -- Solo se dibuja cuando la cañonera está activa
    local gridW = 250
    local gridH = 250
    local gx = ScrW() - gridW - 20
    local gy = ScrH() - gridH - 20
    return gx, gy, gridW, gridH
end

local DeployMenuMode = nil
local SelectedGunshipCategory = "CIS"

-- Interactions
hook.Add("GUIMousePressed", "IVO_RTS_MousePress", function(mc)
    local ply = LocalPlayer()
    if not ply:GetNWBool("IVO_RTSMode", false) then return end
    local mx, my = gui.MouseX(), gui.MouseY()

    -- Top Bar Clicks
    local tx, ty, tw, th = GetTopBarLayout()
    if mx >= tx and mx <= tx + tw and my >= ty and my <= ty + th then
        if mc == MOUSE_LEFT then
            local btnW = 120
            local startX = tx + 180
            
            -- Formation
            if mx >= startX and mx <= startX + btnW then
                fIndex = (fIndex % #Formations) + 1
                FormationType = Formations[fIndex]
                surface.PlaySound("UI/buttonclick.wav")
                if #SelectedDroids > 0 then
                    local validEnts = {}
                    local avgPos = Vector(0,0,0)
                    for _, e in ipairs(SelectedDroids) do
                        if IsValid(e) then table.insert(validEnts, e); avgPos = avgPos + e:GetPos() end
                    end
                    if #validEnts > 0 then
                        avgPos = avgPos / #validEnts
                        CalculateRTSGoals(avgPos, FormationType, validEnts)
                        net.Start("IVO_RTS_Move")
                            net.WriteVector(avgPos)
                            net.WriteString(FormationType)
                            net.WriteUInt(#ply.IVO_RTS_PathLines, 16)
                            for _, path in ipairs(ply.IVO_RTS_PathLines) do
                                net.WriteEntity(path.ent)
                                net.WriteVector(path.goal)
                            end
                        net.SendToServer()
                    end
                end
                return
            end
            
            -- Stance
            if mx >= startX + btnW + 10 and mx <= startX + btnW*2 + 10 then
                surface.PlaySound("UI/buttonclick.wav")
                net.Start("IVO_RTS_Stance")
                net.SendToServer()
                return
            end
            
            -- Passive
            if mx >= startX + btnW*2 + 20 and mx <= startX + btnW*3 + 20 then
                surface.PlaySound("UI/buttonclick.wav")
                net.Start("IVO_RTS_Passive")
                net.SendToServer()
                return
            end
            
            -- Music
            if mx >= startX + btnW*3 + 30 and mx <= startX + btnW*4 + 30 then
                surface.PlaySound("UI/buttonclick.wav")
                RunConsoleCommand("music_menu")
                return
            end
        end
        return -- Handled top bar
    end

    -- Bottom Right Selectors (Solo cuando NO hay menú central)
    if not DeployMenuMode then
        local vehSize = 80
        local gunSize = 120
        local startX = ScrW() - 20 - gunSize - vehSize - 10
        local by = ScrH() - 20 - gunSize
        
        if mc == MOUSE_LEFT then
            -- Vehículos
            if mx >= startX and mx <= startX + vehSize and my >= by + (gunSize - vehSize) and my <= by + gunSize then
                DeployMenuMode = "Vehicles"
                surface.PlaySound("UI/buttonclick.wav")
                return
            end
            -- Nave
            local gunX = startX + vehSize + 10
            if mx >= gunX and mx <= gunX + gunSize and my >= by and my <= by + gunSize then
                DeployMenuMode = "Gunship"
                GunshipPayload = {}
                RecalcGunshipCost()
                surface.PlaySound("UI/buttonclick.wav")
                return
            end
        end
    else
        -- Menu Central
        local cx, cy, cw, ch = GetBottomCenterBarLayout()
        
        if DeployMenuMode == "Gunship" and not GunshipPreparing then
            -- Category Tabs
            local cats = IVO_RTS.Config.GunshipCategories or {"CIS"}
            local tabW = 120
            local tabH = 30
            local tabsStartX = cx + 20
            for i, cat in ipairs(cats) do
                local tabX = tabsStartX + (i-1)*tabW
                local tabY = cy - tabH
                if mx >= tabX and mx <= tabX + tabW and my >= tabY and my <= tabY + tabH then
                    if mc == MOUSE_LEFT then
                        SelectedGunshipCategory = cat
                        surface.PlaySound("UI/buttonclick.wav")
                        return
                    end
                end
            end
            
            if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
                if mc == MOUSE_LEFT then
                    -- Add units
                    local units = IVO_RTS.Config.GunshipUnits or {}
                    local filteredUnits = {}
                    for _, u in ipairs(units) do if u.category == SelectedGunshipCategory then table.insert(filteredUnits, u) end end
                    
                    local uW = 100
                    local startX = cx + 20
                    for i, unit in ipairs(filteredUnits) do
                        local ux = startX + (i-1)*(uW + 10)
                        if mx >= ux and mx <= ux + uW and my >= cy + 25 and my <= cy + 105 then
                            if #GunshipPayload < 25 then
                                table.insert(GunshipPayload, unit.class)
                                RecalcGunshipCost()
                                surface.PlaySound("UI/buttonclick.wav")
                            end
                            return
                        end
                    end
                    
                    -- Cancel
                    local gmpW = 200
                    if mx >= cx + cw - gmpW - 140 and mx <= cx + cw - gmpW - 20 and my >= cy + 20 and my <= cy + 50 then
                        DeployMenuMode = nil
                        GunshipPayload = {}
                        surface.PlaySound("UI/buttonclick.wav")
                        return
                    end
                    
                    -- Prepare Deploy
                    if mx >= cx + cw - gmpW - 140 and mx <= cx + cw - gmpW - 20 and my >= cy + 60 and my <= cy + 100 then
                        if #GunshipPayload > 0 then
                            GunshipPreparing = true
                            surface.PlaySound("UI/buttonclick.wav")
                        end
                        return
                    end
                end
                return
            end
            
            -- Right Side Grid (Remove units)
            local gx, gy, gw, gh = GetRightGridLayout()
            if mx >= gx and mx <= gx + gw and my >= gy and my <= gy + gh then
                if mc == MOUSE_LEFT then
                    local cellW, cellH = gw / 5, gh / 5
                    local col = math.floor((mx - gx) / cellW)
                    local row = math.floor((my - gy) / cellH)
                    local index = row * 5 + col + 1
                    if index <= #GunshipPayload then
                        table.remove(GunshipPayload, index)
                        RecalcGunshipCost()
                        surface.PlaySound("UI/buttonclick.wav")
                    end
                end
                return
            end
        end
        
        if DeployMenuMode == "Vehicles" then
            if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
                if mc == MOUSE_LEFT then
                    -- Buscar vehículos
                    local vehs = {}
                    for _, opt in ipairs(DeployOptions) do
                        if not opt.isCustomGunship then table.insert(vehs, opt) end
                    end
                    
                    local uW = 150
                    local startX = cx + 20
                    for i, veh in ipairs(vehs) do
                        local ux = startX + (i-1)*(uW + 10)
                        if mx >= ux and mx <= ux + uW and my >= cy + 20 and my <= cy + 100 then
                            local cdEnd = ply:GetNWFloat("IVO_RTS_CD_"..(veh.class or "Gunship"), 0)
                            if cdEnd > CurTime() then return end
                            
                            CurrentDeploySelection = veh
                            surface.PlaySound("UI/buttonclick.wav")
                            return
                        end
                    end
                    
                    -- Cancel
                    if mx >= cx + cw - 140 and mx <= cx + cw - 20 and my >= cy + 20 and my <= cy + 50 then
                        DeployMenuMode = nil
                        CurrentDeploySelection = nil
                        surface.PlaySound("UI/buttonclick.wav")
                        return
                    end
                end
            end
        end
    end

    -- Map Clicks
    if mc == MOUSE_LEFT then
        if DeployMenuMode == "Gunship" and GunshipPreparing then
            local targetPos = ScreenToWorldPoint(mx, my)
            net.Start("IVO_RTS_GunshipDeploy")
                net.WriteVector(targetPos)
                net.WriteTable(GunshipPayload)
            net.SendToServer()
            
            DeployMenuMode = nil
            GunshipPreparing = false
            GunshipPayload = {}
            surface.PlaySound("buttons/button15.wav")
        elseif DeployMenuMode == "Vehicles" and CurrentDeploySelection then
            local targetPos = ScreenToWorldPoint(mx, my)
            net.Start("IVO_RTS_Deploy")
                net.WriteVector(targetPos)
                net.WriteString(CurrentDeploySelection.class)
            net.SendToServer()
            
            DeployMenuMode = nil
            CurrentDeploySelection = nil
        elseif not DeployMenuMode then
            DragStart = {x = mx, y = my}
        end
    elseif mc == MOUSE_RIGHT then
        if DeployMenuMode then
            DeployMenuMode = nil
            GunshipPreparing = false
            CurrentDeploySelection = nil
        else
            RightDragStart = {x = mx, y = my, startYaw = IVO_RTS.CameraYaw or 0}
        end
    end
end)

hook.Add("GUIMouseReleased", "IVO_RTS_MouseRelease", function(mc)
    if not LocalPlayer():GetNWBool("IVO_RTSMode", false) then return end
    local mx, my = gui.MouseX(), gui.MouseY()

    if mc == MOUSE_LEFT and DragStart then
        SelectDroidsInBox(DragStart.x, DragStart.y, mx, my)
        DragStart = nil
    elseif mc == MOUSE_RIGHT and RightDragStart then
        local dist = math.abs(mx - RightDragStart.x) + math.abs(my - RightDragStart.y)
        if dist < 10 and #SelectedDroids > 0 then
            local targetPos = ScreenToWorldPoint(mx, my)
            local validEnts = {}
            for _, e in ipairs(SelectedDroids) do if IsValid(e) then table.insert(validEnts, e) end end
            
            if #validEnts > 0 then
                CalculateRTSGoals(targetPos, FormationType, validEnts)
                net.Start("IVO_RTS_Move")
                    net.WriteVector(targetPos)
                    net.WriteString(FormationType)
                    net.WriteUInt(#LocalPlayer().IVO_RTS_PathLines, 16)
                    for _, path in ipairs(LocalPlayer().IVO_RTS_PathLines) do
                        net.WriteEntity(path.ent)
                        net.WriteVector(path.goal)
                    end
                net.SendToServer()
                
                local edata = EffectData()
                edata:SetOrigin(targetPos)
                util.Effect("selection_ring", edata)
                surface.PlaySound("buttons/blip1.wav")
            end
        end
        RightDragStart = nil
    end
end)

hook.Add("Think", "IVO_RTS_RightDrag", function()
    if not LocalPlayer():GetNWBool("IVO_RTSMode", false) then return end
    if input.IsMouseDown(MOUSE_RIGHT) and RightDragStart then
        local mx = gui.MouseX()
        local dx = RightDragStart.x - mx
        if math.abs(dx) > 5 then
            local effectiveDx = dx > 0 and (dx - 5) or (dx + 5)
            IVO_RTS.CameraYaw = RightDragStart.startYaw + (effectiveDx * 0.5)
        end
    end
end)

hook.Add("PostDrawOpaqueRenderables", "IVO_RTS_DrawPathLines", function()
    local ply = LocalPlayer()
    if not ply:GetNWBool("IVO_RTSMode", false) then return end
    
    for _, ent in ipairs(SelectedDroids) do
        if IsValid(ent) then
            local pos = ent:GetPos()
            local tr = util.TraceLine({start = pos + Vector(0,0,50), endpos = pos - Vector(0,0,100), filter = ent})
            local isAAT = (ent:GetClass() == "lvs_fakehover_aat")
            local baseRadius = isAAT and 160 or math.Clamp(ent:BoundingRadius() * 1.5, 30, 200)
            local pulse = math.sin(CurTime() * 10) * (isAAT and 15 or 5)
            local radius = baseRadius + pulse
            local thickness = isAAT and 8 or 4
            
            local ang = tr.HitNormal:Angle()
            ang:RotateAroundAxis(ang:Right(), -90)
            
            cam.Start3D2D(tr.HitPos + Vector(0,0,2), ang, 1)
                surface.SetDrawColor(255, 255, 255, 150)
                draw.NoTexture()
                local segments = 40
                for i = 0, segments - 1 do
                    local a1 = math.rad((i / segments) * 360)
                    local a2 = math.rad(((i + 1) / segments) * 360)
                    surface.DrawPoly({
                        {x = math.cos(a1) * (radius - thickness), y = math.sin(a1) * (radius - thickness)},
                        {x = math.cos(a1) * radius, y = math.sin(a1) * radius},
                        {x = math.cos(a2) * radius, y = math.sin(a2) * radius},
                        {x = math.cos(a2) * (radius - thickness), y = math.sin(a2) * (radius - thickness)}
                    })
                end
            cam.End3D2D()
        end
    end
    
    if ply.IVO_RTS_PathLines and CurTime() < (ply.IVO_RTS_PathLinesTime or 0) then
        local alpha = math.Clamp((ply.IVO_RTS_PathLinesTime - CurTime()) / 1, 0, 1)
        render.SetColorMaterial()
        for _, path in ipairs(ply.IVO_RTS_PathLines) do
            if IsValid(path.ent) then
                local startPos = path.ent:GetPos() + Vector(0, 0, 15)
                local endPos = path.goal + Vector(0, 0, 15)
                render.DrawLine(startPos, endPos, Color(0, 200, 255, 100 * alpha), false)
                render.DrawWireframeBox(endPos, Angle(0,0,0), Vector(-10, -10, -5), Vector(10, 10, 5), Color(0, 255, 0, 150 * alpha), false)
            end
        end
    end
end)

hook.Add("HUDPaint", "IVO_RTS_DrawHUD", function()
    local ply = LocalPlayer()
    if not ply:GetNWBool("IVO_RTSMode", false) then return end
    local gmp = ply:GetNWInt("IVO_RTS_GMP", 0)
    local mx, my = gui.MouseX(), gui.MouseY()

    -- Crosshair / Drag Box
    if DragStart then
        surface.SetDrawColor(color_accent.r, color_accent.g, color_accent.b, 30)
        surface.DrawRect(DragStart.x, DragStart.y, mx - DragStart.x, my - DragStart.y)
        surface.SetDrawColor(color_accent)
        surface.DrawOutlinedRect(DragStart.x, DragStart.y, mx - DragStart.x, my - DragStart.y)
    elseif DeployMenuMode == "Gunship" and GunshipPreparing then
        surface.SetDrawColor(color_accent)
        surface.DrawLine(mx - 15, my, mx + 15, my)
        surface.DrawLine(mx, my - 15, mx, my + 15)
        draw.SimpleText("DEPLOY CAÑONERA", "SW_InvShop_Medium", mx + 20, my + 10, color_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    elseif DeployMenuMode == "Vehicles" and CurrentDeploySelection then
        surface.SetDrawColor(color_accent)
        surface.DrawLine(mx - 15, my, mx + 15, my)
        surface.DrawLine(mx, my - 15, mx, my + 15)
        draw.SimpleText("DEPLOY: " .. string.upper(CurrentDeploySelection.name), "SW_InvShop_Medium", mx + 20, my + 10, color_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        surface.SetDrawColor(color_text)
        surface.DrawLine(mx - 8, my, mx - 2, my)
        surface.DrawLine(mx + 2, my, mx + 8, my)
        surface.DrawLine(mx, my - 8, mx, my - 2)
        surface.DrawLine(mx, my + 2, mx, my + 8)
    end

    -- 1. Top Bar
    local tx, ty, tw, th = GetTopBarLayout()
    draw.RoundedBox(8, tx, ty, tw, th, Color(0, 0, 0, 180))
    surface.SetDrawColor(color_accent)
    surface.DrawRect(tx, ty + th - 2, tw, 2)
    
    local pop = ply:GetNWInt("IVO_RTSPop", 0)
    local popRatio = pop / 50
    local popColor = popRatio > 0.9 and Color(255, 50, 50) or color_accent
    draw.SimpleText("POBLACIÓN: " .. pop .. " / 50", "SW_InvShop_Medium", tx + 15, ty + th/2, popColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    
    local btnW = 120
    local startX = tx + 180
    
    -- Formation
    local fx, fy = startX, ty + 10
    local fHover = (mx >= fx and mx <= fx + btnW and my >= fy and my <= fy + 40)
    local fHoverP = GetLerp("btnF", fHover and 1 or 0, 15)
    draw.RoundedBox(4, fx, fy, btnW, 40, Color(0,0,0,80))
    if fHoverP > 0.01 then draw.RoundedBox(4, fx, fy, btnW, 40, Color(255,255,255, fHoverP*255)) end
    draw.SimpleText("FORMACIÓN", "SW_InvShop_Small", fx + btnW/2, fy + 12, Color(200,200,200, 255 - fHoverP*255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(string.upper(FormationType), "SW_InvShop_Medium", fx + btnW/2, fy + 28, Color(255 - fHoverP*255, 255 - fHoverP*255, 255 - fHoverP*255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Stance
    local sx, sy = startX + btnW + 10, ty + 10
    local holdPos = ply:GetNWBool("IVO_RTS_HoldPos", false)
    local stanceColor = holdPos and Color(255, 100, 100) or Color(100, 255, 100)
    local sHover = (mx >= sx and mx <= sx + btnW and my >= sy and my <= sy + 40)
    local sHoverP = GetLerp("btnS", sHover and 1 or 0, 15)
    draw.RoundedBox(4, sx, sy, btnW, 40, Color(0,0,0,80))
    if sHoverP > 0.01 then draw.RoundedBox(4, sx, sy, btnW, 40, Color(255,255,255, sHoverP*255)) end
    draw.SimpleText("POSTURA", "SW_InvShop_Small", sx + btnW/2, sy + 12, Color(200,200,200, 255 - sHoverP*255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local stC = Color(stanceColor.r, stanceColor.g, stanceColor.b)
    if sHoverP > 0.5 then stC = color_black end
    draw.SimpleText(holdPos and "MANTENER" or "LIBRE", "SW_InvShop_Medium", sx + btnW/2, sy + 28, stC, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Passive
    local px, py = startX + btnW*2 + 20, ty + 10
    local isPass = ply:GetNWBool("IVO_RTS_Passive", false)
    local passColor = isPass and Color(100, 200, 255) or Color(255, 100, 100)
    local pHover = (mx >= px and mx <= px + btnW and my >= py and my <= py + 40)
    local pHoverP = GetLerp("btnP", pHover and 1 or 0, 15)
    draw.RoundedBox(4, px, py, btnW, 40, Color(0,0,0,80))
    if pHoverP > 0.01 then draw.RoundedBox(4, px, py, btnW, 40, Color(255,255,255, pHoverP*255)) end
    draw.SimpleText("MODO", "SW_InvShop_Small", px + btnW/2, py + 12, Color(200,200,200, 255 - pHoverP*255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local psC = Color(passColor.r, passColor.g, passColor.b)
    if pHoverP > 0.5 then psC = color_black end
    draw.SimpleText(isPass and "PASIVO" or "ATAQUE", "SW_InvShop_Medium", px + btnW/2, py + 28, psC, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Music Button
    local mx_btn, my_btn = startX + btnW*3 + 30, ty + 10
    local mHover = (mx >= mx_btn and mx <= mx_btn + btnW and my >= my_btn and my <= my_btn + 40)
    local mHoverP = GetLerp("btnM", mHover and 1 or 0, 15)
    draw.RoundedBox(4, mx_btn, my_btn, btnW, 40, Color(0,0,0,80))
    if mHoverP > 0.01 then draw.RoundedBox(4, mx_btn, my_btn, btnW, 40, Color(255,255,255, mHoverP*255)) end
    draw.SimpleText("MÚSICA", "SW_InvShop_Small", mx_btn + btnW/2, my_btn + 12, Color(200,200,200, 255 - mHoverP*255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local muC = color_accent
    if mHoverP > 0.5 then muC = color_black end
    draw.SimpleText("ABRIR DJ", "SW_InvShop_Medium", mx_btn + btnW/2, my_btn + 28, muC, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Music Display Overlay
    if _G.AdminMusic_CurrentName and _G.AdminMusic_CurrentName ~= "" then
        draw.RoundedBox(8, 20, 20, 250, 60, Color(0, 0, 0, 180))
        surface.SetDrawColor(color_accent)
        surface.DrawRect(20, 78, 250, 2)
        draw.SimpleText("REPRODUCIENDO:", "SW_InvShop_Small", 30, 30, color_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(_G.AdminMusic_CurrentName, "SW_InvShop_Medium", 30, 50, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        if IsValid(_G.AdminMusic_CurrentStation) then
            local pos = _G.AdminMusic_CurrentStation:GetTime()
            local len = _G.AdminMusic_CurrentStation:GetLength()
            draw.SimpleText(string.FormattedTime(pos, "%02i:%02i") .. " / " .. string.FormattedTime(len, "%02i:%02i"), "SW_InvShop_Small", 260, 30, color_text_dark, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    -- 2. Bottom Right Squares (Normal Mode)
    if not DeployMenuMode then
        local vehSize = 80
        local gunSize = 120
        local startX = ScrW() - 20 - gunSize - vehSize - 10
        local by = ScrH() - 20 - gunSize
        
        -- GMP Display
        draw.RoundedBox(8, startX, by - 50, gunSize + vehSize + 10, 40, Color(0,0,0,180))
        surface.SetDrawColor(color_accent)
        surface.DrawRect(startX, by - 12, gunSize + vehSize + 10, 2)
        draw.SimpleText("GMP: " .. gmp, "SW_InvShop_Medium", startX + (gunSize + vehSize + 10)/2, by - 30, color_accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        local vehHover = (mx >= startX and mx <= startX + vehSize and my >= by + (gunSize - vehSize) and my <= by + gunSize)
        local cdEndVeh = ply:GetNWFloat("IVO_RTS_CD_lvs_fakehover_aat", 0)
        local vehCD = cdEndVeh > CurTime()

        local vehP = GetLerp("vehB", vehHover and 1 or 0, 15)
        draw.RoundedBox(8, startX, by + (gunSize - vehSize), vehSize, vehSize, Color(0,0,0,80))
        if vehP > 0.01 then draw.RoundedBox(8, startX, by + (gunSize - vehSize), vehSize, vehSize, Color(255,255,255, vehP*255)) end
        
        local tcVeh = color_text
        if vehP > 0.5 then tcVeh = color_black end
        draw.SimpleText("VEHÍCULO", "SW_InvShop_Small", startX + vehSize/2, by + gunSize - vehSize/2, tcVeh, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        if vehCD then
            draw.RoundedBox(8, startX, by + (gunSize - vehSize), vehSize, vehSize, Color(0,0,0,200))
            draw.SimpleText(math.ceil(cdEndVeh - CurTime()) .. "s", "SW_InvShop_Medium", startX + vehSize/2, by + gunSize - vehSize/2, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local gunX = startX + vehSize + 10
        local gunHover = (mx >= gunX and mx <= gunX + gunSize and my >= by and my <= by + gunSize)
        local cdEndGun = ply:GetNWFloat("IVO_RTS_CD_Gunship", 0)
        local gunCD = cdEndGun > CurTime()

        local gunP = GetLerp("gunB", gunHover and 1 or 0, 15)
        draw.RoundedBox(8, gunX, by, gunSize, gunSize, Color(0,0,0,80))
        if gunP > 0.01 then draw.RoundedBox(8, gunX, by, gunSize, gunSize, Color(255,255,255, gunP*255)) end
        
        local tcGun = color_text
        if gunP > 0.5 then tcGun = color_black end
        draw.SimpleText("NAVE", "SW_InvShop_BigTitle", gunX + gunSize/2, by + gunSize/2, tcGun, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        if gunCD then
            draw.RoundedBox(8, gunX, by, gunSize, gunSize, Color(0,0,0,200))
            draw.SimpleText(math.ceil(cdEndGun - CurTime()) .. "s", "SW_InvShop_BigTitle", gunX + gunSize/2, by + gunSize/2, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    -- 3. Center Menus
    if DeployMenuMode then
        local cx, cy, cw, ch = GetBottomCenterBarLayout()
        
        if DeployMenuMode == "Gunship" and not GunshipPreparing then
            -- Draw Category Tabs
            local cats = IVO_RTS.Config.GunshipCategories or {"CIS"}
            local tabW = 120
            local tabH = 30
            local tabsStartX = cx + 20
            for i, cat in ipairs(cats) do
                local tabX = tabsStartX + (i-1)*tabW
                local tabY = cy - tabH
                local isSel = (SelectedGunshipCategory == cat)
                
                draw.RoundedBoxEx(8, tabX, tabY, tabW, tabH, isSel and Color(0,0,0,180) or Color(0,0,0,80), true, true, false, false)
                if isSel then
                    surface.SetDrawColor(color_accent)
                    surface.DrawRect(tabX, tabY, tabW, 2)
                end
                draw.SimpleText(string.upper(cat), "SW_InvShop_Medium", tabX + tabW/2, tabY + tabH/2, isSel and color_accent or color_text_dark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            draw.RoundedBox(8, cx, cy, cw, ch, Color(0,0,0,180))
            surface.SetDrawColor(color_accent)
            surface.DrawRect(cx, cy + ch - 2, cw, 2)
            
            draw.SimpleText("CARGAR CAÑONERA (MAX 25)", "SW_InvShop_Medium", cx + 20, cy + 5, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            local units = IVO_RTS.Config.GunshipUnits or {}
            local filteredUnits = {}
            for _, u in ipairs(units) do if u.category == SelectedGunshipCategory then table.insert(filteredUnits, u) end end

            local uW = 100
            local startX = cx + 20
            for i, unit in ipairs(filteredUnits) do
                local ux = startX + (i-1)*(uW + 10)
                local uHover = (mx >= ux and mx <= ux + uW and my >= cy + 25 and my <= cy + 105)
                local uP = GetLerp("uB"..i, uHover and 1 or 0, 15)
                
                draw.RoundedBox(4, ux, cy + 25, uW, 80, Color(0,0,0,80))
                if uP > 0.01 then draw.RoundedBox(4, ux, cy + 25, uW, 80, Color(255,255,255, uP*255)) end
                
                local tc1, tc2 = color_text, color_accent
                if uP > 0.5 then tc1, tc2 = color_black, color_black end
                
                draw.SimpleText(unit.icon, "SW_InvShop_BigTitle", ux + uW/2, cy + 55, tc1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                local cost = (IVO_RTS.Config.UnitCostsGMP and IVO_RTS.Config.UnitCostsGMP[unit.class]) or 0
                draw.SimpleText(cost > 0 and (cost.." GMP") or "GRATIS", "SW_InvShop_Small", ux + uW/2, cy + 85, tc2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            -- Right side of center bar: GMP Info and Buttons
            local gmpW = 200
            local rx = cx + cw - gmpW
            
            draw.SimpleText("GMP DISPONIBLES: " .. gmp, "SW_InvShop_Medium", rx - 20, cy + 15, color_accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            draw.SimpleText("Costo Cañonera: " .. GunshipCostCache, "SW_InvShop_Small", rx - 20, cy + 40, color_text_dark, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

            -- Cancel Button
            local cX, cY = rx - 140, cy + 20
            local cHover = (mx >= cX and mx <= cX + 120 and my >= cY and my <= cY + 30)
            local cP = GetLerp("btnC", cHover and 1 or 0, 15)
            draw.RoundedBox(4, cX, cY, 120, 30, Color(150, 50, 50, 100))
            if cP > 0.01 then draw.RoundedBox(4, cX, cY, 120, 30, Color(255, 100, 100, cP*255)) end
            draw.SimpleText("CANCELAR", "SW_InvShop_Small", cX + 60, cY + 15, color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- Prepare Button
            local pX, pY = rx - 140, cy + 60
            local canAfford = gmp >= GunshipCostCache and #GunshipPayload > 0
            local pHover2 = canAfford and (mx >= pX and mx <= pX + 120 and my >= pY and my <= pY + 40)
            local pP2 = GetLerp("btnP2", pHover2 and 1 or 0, 15)
            draw.RoundedBox(4, pX, pY, 120, 40, canAfford and Color(50, 150, 50, 100) or Color(100, 100, 100, 50))
            if pP2 > 0.01 then draw.RoundedBox(4, pX, pY, 120, 40, Color(100, 255, 100, pP2*255)) end
            draw.SimpleText("DESPLEGAR", "SW_InvShop_Medium", pX + 60, pY + 20, color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- Right Side Grid (Payload Icons)
            if #GunshipPayload > 0 then
                local gx, gy, gw, gh = GetRightGridLayout()
                draw.RoundedBox(8, gx, gy, gw, gh, Color(0,0,0,180))
                surface.SetDrawColor(color_accent)
                surface.DrawRect(gx, gy + gh - 2, gw, 2)
                
                draw.SimpleText("CARGA ("..#GunshipPayload.."/25) - "..GunshipCostCache.." GMP", "SW_InvShop_Medium", gx + gw/2, gy - 20, color_accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                
                local cellW, cellH = gw / 5, gh / 5
                for i, class in ipairs(GunshipPayload) do
                    local row = math.floor((i-1) / 5)
                    local col = (i-1) % 5
                    local x = gx + col * cellW
                    local y = gy + row * cellH
                    
                    local icon = class
                    for _, u in ipairs(IVO_RTS.Config.GunshipUnits) do if u.class == class then icon = u.icon break end end
                    
                    local iHover = (mx >= x and mx <= x + cellW and my >= y and my <= y + cellH) and not GunshipPreparing
                    local iP = GetLerp("cell"..i, iHover and 1 or 0, 15)
                    
                    draw.RoundedBox(4, x + 2, y + 2, cellW - 4, cellH - 4, Color(20,25,30,100))
                    if iP > 0.01 then draw.RoundedBox(4, x + 2, y + 2, cellW - 4, cellH - 4, Color(255,50,50, iP*255)) end
                    
                    draw.SimpleText(iHover and "X" or icon, "SW_InvShop_Medium", x + cellW/2, y + cellH/2, iHover and color_black or color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
        elseif DeployMenuMode == "Gunship" and GunshipPreparing then
            draw.SimpleText("HAZ CLIC EN EL MAPA PARA DESPLEGAR LA CAÑONERA", "SW_InvShop_BigTitle", ScrW()/2, ScrH() - 100, color_accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("CLIC DERECHO PARA CANCELAR", "SW_InvShop_Medium", ScrW()/2, ScrH() - 70, color_text_dark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif DeployMenuMode == "Vehicles" then
            draw.RoundedBox(8, cx, cy, cw, ch, Color(0,0,0,180))
            surface.SetDrawColor(color_accent)
            surface.DrawRect(cx, cy + ch - 2, cw, 2)
            
            draw.SimpleText("SELECCIONAR VEHÍCULO", "SW_InvShop_Medium", cx + 20, cy + 5, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            local vehs = {}
            for _, opt in ipairs(DeployOptions) do
                if not opt.isCustomGunship then table.insert(vehs, opt) end
            end
            
            local uW = 150
            local startX = cx + 20
            for i, veh in ipairs(vehs) do
                local ux = startX + (i-1)*(uW + 10)
                local uHover = (mx >= ux and mx <= ux + uW and my >= cy + 25 and my <= cy + 105)
                local cdEnd = ply:GetNWFloat("IVO_RTS_CD_"..(veh.class or "Gunship"), 0)
                local isCD = cdEnd > CurTime()
                local isSel = (CurrentDeploySelection == veh)
                local uP = GetLerp("vB"..i, (uHover or isSel) and 1 or 0, 15)
                
                draw.RoundedBox(4, ux, cy + 25, uW, 80, Color(0,0,0,80))
                if uP > 0.01 then draw.RoundedBox(4, ux, cy + 25, uW, 80, Color(255,255,255, uP*255)) end
                
                local tcVeh = isSel and color_black or color_text
                if uP > 0.5 then tcVeh = color_black end
                draw.SimpleText(string.upper(veh.name), "SW_InvShop_Medium", ux + uW/2, cy + 45, tcVeh, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                
                if isCD then
                    draw.RoundedBox(4, ux, cy + 25, uW, 80, Color(0,0,0,200))
                    draw.SimpleText(math.ceil(cdEnd - CurTime()) .. "s", "SW_InvShop_BigTitle", ux + uW/2, cy + 65, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
            
            -- Cancel Button
            local cX, cY = cx + cw - 140, cy + 20
            local cHover = (mx >= cX and mx <= cX + 120 and my >= cY and my <= cY + 30)
            local cP = GetLerp("vbtnC", cHover and 1 or 0, 15)
            draw.RoundedBox(4, cX, cY, 120, 30, Color(150, 50, 50, 100))
            if cP > 0.01 then draw.RoundedBox(4, cX, cY, 120, 30, Color(255, 100, 100, cP*255)) end
            draw.SimpleText("CANCELAR", "SW_InvShop_Small", cX + 60, cY + 15, color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            if CurrentDeploySelection then
                draw.SimpleText("CLIC EN EL MAPA PARA DESPLEGAR", "SW_InvShop_Medium", cx + cw - 140, cy + 80, color_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
    end
end)
