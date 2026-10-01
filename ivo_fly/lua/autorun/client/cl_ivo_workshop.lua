-- ============================================================
-- IVO FLY - TALLER 3D (LVS UPGRADES)
-- ============================================================
IvoFly = IvoFly or {}

local CAM_POS = Vector(-9289.020508, -5634.080566, -14580)

IvoFly.WorkshopActive = false
local WS_Frame = NULL
local WS_ShipModel = NULL
local WS_ManualRot = 0
local currentCamRot = 0
local lastMouseX = 0

-- Funciones globales para que cl_ivo_fly_ui pueda cerrarlas
function IvoFly.HideWorkshopUI()
    if IsValid(WS_Frame) then WS_Frame:SetVisible(false) end
end

function IvoFly.CloseWorkshopCinematic()
    IvoFly.WorkshopActive = false
    if IsValid(WS_Frame) then WS_Frame:Close() end
end

local UPGRADES = {
    ["Motor"] = {
        { id = "engine", level = 1, name = "Filtros de Alto Flujo", desc = "+10% Vel. Máxima y Aceleración", price = 5000, stat = 15, reqLevel = 5 },
        { id = "engine", level = 2, name = "Inyectores Mejorados", desc = "+20% Vel. Máxima y Aceleración", price = 15000, stat = 30, reqLevel = 10 },
        { id = "engine", level = 3, name = "Turbinas de Competición", desc = "+35% Vel. Máxima y Aceleración", price = 45000, stat = 60, reqLevel = 20 },
        { id = "engine", level = 4, name = "Motor Militar", desc = "+50% Vel. Máxima y Aceleración", price = 85000, stat = 100, reqLevel = 35 }
    },
    ["Blindaje"] = {
        { id = "armor", level = 1, name = "Refuerzo Estructural", desc = "+15% Integridad del Chasis", price = 5000, stat = 15, reqLevel = 5 },
        { id = "armor", level = 2, name = "Aleación Ligera", desc = "+30% Integridad del Chasis", price = 12000, stat = 30, reqLevel = 10 },
        { id = "armor", level = 3, name = "Placas de Titanio", desc = "+60% Integridad del Chasis", price = 38000, stat = 60, reqLevel = 20 },
        { id = "armor", level = 4, name = "Blindaje Reactivo", desc = "+100% Integridad, Resist. Explosivos", price = 75000, stat = 100, reqLevel = 35 }
    },
    ["Agilidad"] = {
        { id = "agility", level = 1, name = "Sensores de Vuelo Base", desc = "+10% Maniobrabilidad", price = 4000, stat = 15, reqLevel = 5 },
        { id = "agility", level = 2, name = "Giroscopios Calibrados", desc = "+20% Maniobrabilidad", price = 10000, stat = 30, reqLevel = 10 },
        { id = "agility", level = 3, name = "Aletas de Maniobra", desc = "+35% Maniobrabilidad y Frenado", price = 30000, stat = 60, reqLevel = 20 },
        { id = "agility", level = 4, name = "Vuelo Asistido por IA", desc = "+50% Maniobrabilidad Extrema", price = 60000, stat = 100, reqLevel = 35 }
    },
    ["Armamento"] = {
        { id = "weapons", level = 1, name = "Calibración de Lentes", desc = "+10% Daño General", price = 8000, stat = 15, reqLevel = 5 },
        { id = "weapons", level = 2, name = "Disipadores de Calor", desc = "+25% Daño General", price = 25000, stat = 30, reqLevel = 10 },
        { id = "weapons", level = 3, name = "Munición Perforante", desc = "+45% Daño General", price = 60000, stat = 60, reqLevel = 20 },
        { id = "weapons", level = 4, name = "Sistemas Avanzados", desc = "+70% Daño General", price = 120000, stat = 100, reqLevel = 35 }
    }
}

local function DrawKeyLegend(x, y, key, desc)
    surface.SetFont("SW_InvShop_Medium")
    local tw, th = surface.GetTextSize(key)
    local kw = tw + 20; local kh = 26
    draw.RoundedBox(6, x, y - kh/2, kw, kh, Color(20, 25, 30, 240))
    draw.RoundedBox(6, x, y - kh/2 + kh - 4, kw, 4, Color(10, 15, 20, 250))
    draw.SimpleText(key, "SW_InvShop_Medium", x + kw/2, y - 2, color_white, 1, 1)
    draw.SimpleText(desc, "SW_InvShop_Medium", x + kw + 10, y - 1, Color(150, 150, 150), 0, 1)
    return kw + 10 + surface.GetTextSize(desc) + 30
end

function IvoFly.OpenWorkshop(shipClass, currentUpgrades)
    IvoFly.WorkshopActive = true
    WS_ManualRot = 0
    currentCamRot = 0
    local expandedCat = nil
    local selectedItem = nil

    if IsValid(WS_ShipModel) then WS_ShipModel:Remove() end
    local mdl = "models/error.mdl"
    local entTbl = scripted_ents.GetStored(shipClass)
    
    local shipName = "NAVE DESCONOCIDA"
    local shipCat = "VEHÍCULO AÉREO"
    
    if entTbl and entTbl.t then
        if entTbl.t.MDL then mdl = entTbl.t.MDL end
        shipName = string.upper(entTbl.t.PrintName or shipName)
        shipCat = string.upper(entTbl.t.VehicleSubCategory or entTbl.t.VehicleCategory or shipCat)
    end
    
    WS_ShipModel = ClientsideModel(mdl)
    if IsValid(WS_ShipModel) then 
        WS_ShipModel:SetNoDraw(true) 
        if shipClass == "lvs_repulsorlift_atmospheric_laat" then
            WS_ShipModel:SetSkin(1)
        elseif shipClass == "lvs_arc" then
            WS_ShipModel:SetSkin(3)
        end
    end

    if IsValid(WS_Frame) then WS_Frame:Remove() end
    WS_Frame = vgui.Create("DFrame")
    WS_Frame:SetSize(ScrW(), ScrH())
    WS_Frame:Center()
    WS_Frame:SetTitle("")
    WS_Frame:ShowCloseButton(false)
    WS_Frame:MakePopup()

    local isDragging = false
    WS_Frame.OnMousePressed = function(s, code) if code == MOUSE_LEFT then isDragging = true; lastMouseX = gui.MouseX() end end
    WS_Frame.OnMouseReleased = function(s, code) if code == MOUSE_LEFT then isDragging = false end end
    WS_Frame.Think = function(s)
        if not LocalPlayer():Alive() then s:Close() end
        if isDragging then
            local mx = gui.MouseX()
            WS_ManualRot = WS_ManualRot - ((mx - lastMouseX) * 0.5) 
            lastMouseX = mx
        end
    end

    WS_Frame.Paint = function(s, w, h)
        local textY = h - 110
        surface.SetDrawColor(0, 150, 255, 150)
        surface.DrawRect(w - 350, textY - 15, 300, 2)
        draw.SimpleText(shipName, "SW_InvShop_BigTitle", w - 50, textY, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        draw.SimpleText(shipCat, "SW_InvShop_Aurebesh_Title", w - 50, textY + 22, Color(150, 150, 150, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

        local y = h - 35; local tW = 0
        surface.SetFont("SW_InvShop_Medium")
        tW = tW + surface.GetTextSize("BACKSPACE") + 20 + 10 + surface.GetTextSize("VOLVER") + 30
        tW = tW + surface.GetTextSize("CLICK IZQ") + 20 + 10 + surface.GetTextSize("ROTAR CÁMARA")
        local cx = w/2 - tW/2
        
        draw.RoundedBox(12, cx - 30, y - 25, tW + 40, 50, Color(0, 0, 0, 200))
        surface.SetDrawColor(255, 180, 0, 80)
        surface.DrawOutlinedRect(cx - 30, y - 25, tW + 40, 50)
        
        cx = cx + DrawKeyLegend(cx, y, "BACKSPACE", "VOLVER")
        DrawKeyLegend(cx, y, "CLICK IZQ", "ROTAR CÁMARA")
    end

    WS_Frame.OnKeyCodePressed = function(s, key)
        if key == KEY_BACKSPACE then
            if selectedItem then selectedItem = nil; if IsValid(WS_Frame.InfoPanel) then WS_Frame.InfoPanel:Remove() end; s.BuildList()
            elseif expandedCat then expandedCat = nil; s.BuildList()
            else s:Close() end
        end
    end

    local MenuPanel = vgui.Create("DPanel", WS_Frame)
    MenuPanel:SetSize(310, 480) 
    MenuPanel:SetPos(50, ScrH() * 0.12)
    MenuPanel.Paint = function(s, w, h)
        draw.SimpleText("TALLER MECÁNICO", "SW_InvShop_BigTitle", 20, 20, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("MEJORAS LVS", "SW_InvShop_Aurebesh_Title", 20, 42, Color(150, 150, 150, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(255, 180, 0, 150)
        surface.DrawRect(20, 50, w - 40, 2)
        
        local myCr = LocalPlayer().getDarkRPVar and LocalPlayer():getDarkRPVar("money") or 0
        local glowAlpha = 100 + math.sin(CurTime() * 4) * 50
        draw.SimpleText("SALDO:", "SW_InvShop_Medium", 20, 77, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("$ " .. string.Comma(myCr), "SW_InvShop_Aurebesh_Medium", 90, 77, Color(255, 200, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("$ " .. string.Comma(myCr), "SW_InvShop_Aurebesh_Medium", 90, 77, Color(255, 200, 0, glowAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(255, 180, 0, 150)
        surface.DrawRect(20, 88, 150, 1)
    end

    local btnWalk = vgui.Create("DButton", MenuPanel)
    btnWalk:SetText("")
    btnWalk:Dock(BOTTOM)
    btnWalk:DockMargin(10, 5, 10, 10)
    btnWalk:SetTall(38)
    btnWalk.Paint = function(s, w, h)
        s.HoverP = Lerp(FrameTime() * 15, s.HoverP or 0, s:IsHovered() and 1 or 0)
        if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
        
        draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
        if s.HoverP > 0.01 then draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255)) end
        
        local tc = Lerp(s.HoverP, 255, 0)
        draw.SimpleText("SALIR CAMINANDO", "SW_InvShop_Medium", w/2, h/2, Color(tc, tc, tc), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnWalk.DoClick = function()
        LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
        WS_Frame:Close()
    end

    local btnDeploy = vgui.Create("DButton", MenuPanel)
    btnDeploy:SetText("")
    btnDeploy:Dock(BOTTOM)
    btnDeploy:DockMargin(10, 5, 10, 0)
    btnDeploy:SetTall(38)
    btnDeploy.Paint = function(s, w, h)
        s.HoverP = Lerp(FrameTime() * 15, s.HoverP or 0, s:IsHovered() and 1 or 0)
        if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
        
        draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
        if s.HoverP > 0.01 then draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255)) end
        
        local tc = Lerp(s.HoverP, 255, 0)
        draw.SimpleText("SALIR CON VEHÍCULO", "SW_InvShop_Medium", w/2, h/2, Color(tc, tc, tc), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnDeploy.DoClick = function()
        LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
        net.Start("IvoFly_SpawnFromWorkshop")
        net.WriteString(shipClass)
        net.SendToServer()
        -- IMPORTANTE: Ya no cerramos el taller aquí, dejamos que lo cierre la cinemática
    end

    local sepPanel = vgui.Create("DPanel", MenuPanel)
    sepPanel:Dock(BOTTOM)
    sepPanel:DockMargin(20, 10, 20, 5)
    sepPanel:SetTall(1)
    sepPanel.Paint = function(s, w, h)
        surface.SetDrawColor(0, 150, 255, 50)
        surface.DrawRect(0, 0, w, h)
    end

    local Scroll = vgui.Create("DScrollPanel", MenuPanel)
    Scroll:Dock(FILL)
    Scroll:DockMargin(10, 100, 10, 0)

    WS_Frame.BuildList = function()
        Scroll:Clear()
        local totalH = 0

        if not expandedCat then
            for catName, _ in pairs(UPGRADES) do
                local btn = Scroll:Add("DButton")
                btn:SetText(""); btn:Dock(TOP); btn:DockMargin(5, 5, 5, 5); btn:SetTall(50)
                totalH = totalH + 60 
                btn.HoverP = 0
                btn.Paint = function(s, w, h)
                    s.HoverP = Lerp(FrameTime() * 12, s.HoverP, s:IsHovered() and 1 or 0)
                    draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                    if s.HoverP > 0.01 then draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255)) end
                    
                    local tc = Lerp(s.HoverP, 255, 0)
                    draw.SimpleText(string.upper(catName), "SW_InvShop_Medium", 15, h/2 - 6, Color(tc, tc, tc), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText("SISTEMA", "SW_InvShop_Aurebesh_ExtraSmall", 15, h/2 + 8, Color(tc, tc, tc, 100 + s.HoverP * 155), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                btn.DoClick = function() expandedCat = catName; WS_Frame.BuildList(); LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5) end
            end
        else
            local btnBack = Scroll:Add("DButton")
            btnBack:SetText(""); btnBack:Dock(TOP); btnBack:DockMargin(5, 5, 5, 5); btnBack:SetTall(30)
            totalH = totalH + 40
            btnBack.Paint = function(s, w, h)
                draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 150))
                draw.SimpleText("< VOLVER A CATEGORÍAS", "SW_InvShop_Small", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            btnBack.DoClick = function() expandedCat = nil; selectedItem = nil; if IsValid(WS_Frame.InfoPanel) then WS_Frame.InfoPanel:Remove() end; WS_Frame.BuildList() end

            for _, item in ipairs(UPGRADES[expandedCat]) do
                local currentLvl = currentUpgrades[item.id] or 0
                
                local btnItm = Scroll:Add("DButton")
                btnItm:SetText(""); btnItm:Dock(TOP); btnItm:DockMargin(5, 5, 5, 5); btnItm:SetTall(60)
                totalH = totalH + 70
                btnItm.HoverP = 0
                btnItm.Paint = function(s, w, h)
                    local isSel = (selectedItem == item)
                    s.HoverP = Lerp(FrameTime() * 15, s.HoverP, (s:IsHovered() or isSel) and 1 or 0)
                    
                    local isEquipped = (currentLvl >= item.level)
                    draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                    if isSel then draw.RoundedBox(16, 0, 0, w, h, Color(255, 180, 0, 40)) end
                    if s.HoverP > 0.01 then draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255)) end
                    
                    local tc = Lerp(s.HoverP, 200, 0)
                    draw.SimpleText(item.name, "SW_InvShop_Medium", 10, h/2 - 6, Color(tc, tc, tc), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText("NIVEL " .. item.level, "SW_InvShop_Aurebesh_ExtraSmall", 10, h/2 + 7, Color(tc, tc, tc, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    
                    if isEquipped then
                        draw.SimpleText("INSTALADO", "SW_InvShop_Aurebesh_Medium", w - 10, h/2, Color(46, 204, 113, 180), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    else
                        draw.SimpleText("$ " .. string.Comma(item.price), "SW_InvShop_Aurebesh_Medium", w - 10, h/2, Color(255, 170, 0), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    end
                end
                
                btnItm.DoClick = function()
                    selectedItem = item
                    LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                    WS_Frame.BuildList()

                    if IsValid(WS_Frame.InfoPanel) then WS_Frame.InfoPanel:Remove() end
                    WS_Frame.InfoPanel = vgui.Create("DPanel", WS_Frame)
                    local ip = WS_Frame.InfoPanel
                    ip:SetSize(400, 230)
                    ip.curY = MenuPanel:GetY() + MenuPanel:GetTall() + 10
                    ip.Think = function(s) s:SetPos(50, s.curY) end
                    
                    ip.Paint = function(s, w, h)
                        draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 180))
                        surface.SetDrawColor(255, 180, 0, 150)
                        surface.DrawRect(15, 65, w - 30, 1)
                        
                        draw.SimpleText(string.upper(item.name), "SW_InvShop_Header", 20, 20, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        
                        local isEq = (currentLvl >= item.level)
                        local priceTxt = isEq and "EQUIPADO" or ("$ " .. string.Comma(item.price))
                        local pColor = isEq and Color(46, 204, 113) or Color(255, 170, 0)
                        
                        draw.SimpleText("PRECIO:", "SW_InvShop_Small", 20, 48, Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        draw.SimpleText(priceTxt, "SW_InvShop_Aurebesh_Medium", 75, 48, pColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                        local reqLv = item.reqLevel or 1
                        local myLvl = LocalPlayer():GetNWInt("IVO_JobLevel_piloto", 1)
                        local lvlColor = myLvl >= reqLv and Color(46, 204, 113) or Color(255, 60, 60)
                        draw.SimpleText("NIVEL PILOTO:", "SW_InvShop_Small", 180, 48, Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        draw.SimpleText("NVL " .. reqLv, "SW_InvShop_Aurebesh_Medium", 270, 48, lvlColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                        draw.SimpleText(expandedCat, "SW_InvShop_Small", 20, 95, Color(180, 180, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        local barW = w - 150
                        surface.SetDrawColor(0, 0, 0, 180)
                        surface.DrawRect(110, 95 - 3, barW, 6)
                        surface.SetDrawColor(0, 150, 255, 200)
                        surface.DrawRect(110, 95 - 3, barW * (item.stat/100), 6)
                        surface.SetDrawColor(0, 150, 255, 100)
                        surface.DrawOutlinedRect(110, 95 - 3, barW, 6)
                        
                        draw.DrawText(item.desc, "SW_InvShop_Medium", 20, 120, Color(200, 200, 200), TEXT_ALIGN_LEFT)
                    end

                    local btnAct = vgui.Create("DButton", ip)
                    btnAct:SetSize(ip:GetWide() - 40, 35)
                    btnAct:SetPos(20, ip:GetTall() - 45)
                    btnAct:SetText("")
                    btnAct.HoverP = 0
                    btnAct.Paint = function(s, bw, bh)
                        s.HoverP = Lerp(FrameTime() * 15, s.HoverP, s:IsHovered() and 1 or 0)
                        local isEq = (currentLvl >= item.level)
                        local reqLv = item.reqLevel or 1
                        local myLvl = LocalPlayer():GetNWInt("IVO_JobLevel_piloto", 1)
                        
                        if isEq then
                            draw.RoundedBox(16, 0, 0, bw, bh, Color(50, 50, 50, 200))
                            draw.SimpleText("YA INSTALADO", "SW_InvShop_Medium", bw/2, bh/2, Color(100, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        elseif myLvl < reqLv then
                            draw.RoundedBox(16, 0, 0, bw, bh, Color(150, 50, 50, 50 + (s.HoverP * 50)))
                            surface.SetDrawColor(255, 50, 50, 200)
                            surface.DrawOutlinedRect(0,0,bw,bh)
                            draw.SimpleText("NIVEL DE PILOTAJE INSUFICIENTE", "SW_InvShop_Medium", bw/2, bh/2, Color(255, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        else
                            draw.RoundedBox(16, 0, 0, bw, bh, Color(0, 150, 255, 50 + (s.HoverP * 100)))
                            surface.SetDrawColor(0, 150, 255, 255)
                            surface.DrawOutlinedRect(0,0,bw,bh)
                            draw.SimpleText("INSTALAR MEJORA", "SW_InvShop_Medium", bw/2, bh/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        end
                    end
                    btnAct.DoClick = function()
                        if currentLvl >= item.level then return end
                        if LocalPlayer():GetNWInt("IVO_JobLevel_piloto", 1) < (item.reqLevel or 1) then return end
                        net.Start("IvoFly_BuyUpgrade")
                        net.WriteString(shipClass)
                        net.WriteString(item.id)
                        net.WriteUInt(item.level, 8)
                        net.SendToServer()
                    end
                end
            end
        end
        
        local baseH = 200 
        local targetH = math.min(ScrH() * 0.9, baseH + totalH)
        MenuPanel:SizeTo(310, targetH, 0.2, 0, -1)
    end

    WS_Frame.BuildList()

    WS_Frame.OnClose = function()
        IvoFly.WorkshopActive = false
        if IsValid(WS_ShipModel) then WS_ShipModel:Remove() end
        if IsValid(WS_Frame.InfoPanel) then WS_Frame.InfoPanel:Remove() end
    end
end

local curCamPos, curCamAng

hook.Add("CalcView", "IvoFly_WorkshopCam", function(ply, pos, angles, fov)
    if not IvoFly.WorkshopActive then 
        curCamPos, curCamAng = nil, nil
        return 
    end
    
    currentCamRot = Lerp(FrameTime() * 5, currentCamRot, WS_ManualRot)
    
    local radius = 1600 
    local height = 400
    local rad = math.rad(currentCamRot + 135) 
    
    local anchorPoint = CAM_POS + Vector(0, 0, 150)
    local idealCamPos = anchorPoint + Vector(math.cos(rad) * radius, math.sin(rad) * radius, height)
    
    local tr = util.TraceHull({
        start = anchorPoint,
        endpos = idealCamPos,
        mins = Vector(-30, -30, -30),
        maxs = Vector(30, 30, 30),
        mask = MASK_SOLID_BRUSHONLY 
    })
    
    if tr.Hit then
        idealCamPos = tr.HitPos + tr.HitNormal * 30
    end
    
    local idealCamAng = (anchorPoint - idealCamPos):Angle()

    if not curCamPos then curCamPos = pos; curCamAng = angles end
    
    curCamPos = LerpVector(FrameTime() * 4, curCamPos, idealCamPos)
    curCamAng = LerpAngle(FrameTime() * 4, curCamAng, idealCamAng)
    
    return { origin = curCamPos, angles = curCamAng, fov = 75, drawviewer = true }
end)

hook.Add("PostDrawOpaqueRenderables", "IvoFly_WorkshopModel", function()
    if not IvoFly.WorkshopActive or not IsValid(WS_ShipModel) then return end
    
    local minZ = WS_ShipModel:OBBMins().z
    local floorPos = Vector(CAM_POS.x, CAM_POS.y, CAM_POS.z - minZ)

    local m = Matrix()
    m:Translate(floorPos)
    m:Rotate(Angle(0, 135, 0)) 
    
    WS_ShipModel:SetPos(m:GetTranslation())
    WS_ShipModel:SetAngles(m:GetAngles())
    WS_ShipModel:SetupBones()
    WS_ShipModel:DrawModel()
end)

hook.Add("HUDShouldDraw", "IvoFly_WorkshopHide", function(name)
    if IvoFly.WorkshopActive then return false end
end)
hook.Add("PrePlayerDraw", "IvoFly_WorkshopHidePly", function(ply)
    if IvoFly.WorkshopActive then return true end
end)

net.Receive("IvoFly_OpenWorkshop", function()
    local class = net.ReadString()
    local currentUpgrades = net.ReadTable()
    IvoFly.OpenWorkshop(class, currentUpgrades)
end)

net.Receive("IvoFly_UpdateWorkshop", function()
    local currentUpgrades = net.ReadTable()
    if IvoFly.WorkshopActive and IsValid(WS_Frame) then
        WS_Frame.currentUpgrades = currentUpgrades
        WS_Frame.BuildList()
    end
end)