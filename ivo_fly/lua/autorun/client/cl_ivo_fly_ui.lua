-- ============================================================
-- IVO FLY - CLIENT DEPLOYMENT UI (SHOP AESTHETIC)
-- ============================================================
IvoFly = IvoFly or {}

surface.CreateFont("SW_InvShop_BigTitle", { font = "SansSerifFLF", size = 32, weight = 500, antialias = true })
surface.CreateFont("SW_InvShop_Medium", { font = "SansSerifFLF", size = 20, weight = 500, antialias = true })
surface.CreateFont("SW_InvShop_Small", { font = "SansSerifFLF", size = 14, weight = 500, antialias = true })
surface.CreateFont("SW_InvShop_Aurebesh_Title", { font = "VirtusBe", size = 16, weight = 500, antialias = true })
surface.CreateFont("SW_InvShop_Aurebesh_ExtraSmall", { font = "VirtusBe", size = 9, weight = 500, antialias = true })

local isMenuOpen = false
local currentZoneIndex = 1
local currentVehicleIndex = 1
local menuPanel = nil
local targetCameraPos = nil
local targetCameraAng = nil
local currentCamPos = nil
local currentCamAng = nil

local ghostEnt = nil
local lastGhostClass = ""

local VEHICLES = {
    {name = "ARC-170", class = "lvs_arc"},
    {name = "LAAT", class = "lvs_repulsorlift_atmospheric_laat"}
}

local function GetVehicleModel(class)
    local entTbl = scripted_ents.GetStored(class)
    if entTbl and entTbl.t and entTbl.t.MDL then return entTbl.t.MDL end
    if entTbl and entTbl.t and entTbl.t.Model then return entTbl.t.Model end
    local listVeh = list.Get("Vehicles")
    if listVeh and listVeh[class] and listVeh[class].Model then return listVeh[class].Model end
    
    if class == "lvs_arc" then return "models/sdog/arc170ch.mdl" end
    if class == "lvs_repulsorlift_atmospheric_laat" then return "models/blu/laat.mdl" end
    
    return "models/error.mdl"
end

local function UpdateGhost()
    if not isMenuOpen then
        if IsValid(ghostEnt) then ghostEnt:Remove(); ghostEnt = nil end
        return
    end

    local zone = IvoFly.Zones and IvoFly.Zones[currentZoneIndex]
    if not zone then return end

    local class = VEHICLES[currentVehicleIndex].class
    if class ~= lastGhostClass or not IsValid(ghostEnt) then
        if IsValid(ghostEnt) then ghostEnt:Remove() end
        ghostEnt = ClientsideModel(GetVehicleModel(class))
        if IsValid(ghostEnt) then 
            ghostEnt:SetNoDraw(true) 
            if class == "lvs_repulsorlift_atmospheric_laat" then
                ghostEnt:SetSkin(1)
            elseif class == "lvs_arc" then
                ghostEnt:SetSkin(3)
            end
        end
        lastGhostClass = class
    end
end

hook.Add("PostDrawTranslucentRenderables", "IvoFly_DrawGhost", function()
    if isMenuOpen and IsValid(ghostEnt) then
        local zone = IvoFly.Zones and IvoFly.Zones[currentZoneIndex]
        if zone then
            local centerPos = Vector((zone.min.x + zone.max.x)/2, (zone.min.y + zone.max.y)/2, zone.min.z + 10)
            ghostEnt:SetAngles(Angle(0, 180, 0))
            
            local offset = ghostEnt:OBBCenter()
            offset:Rotate(Angle(0, 180, 0))
            centerPos.x = centerPos.x - offset.x
            centerPos.y = centerPos.y - offset.y
            centerPos.z = centerPos.z - ghostEnt:OBBMins().z
            
            ghostEnt:SetPos(centerPos)
            
            render.SetBlend(0.4)
            render.SetColorModulation(0.1, 0.8, 1)
            render.MaterialOverride(Material("models/shiny"))
            ghostEnt:DrawModel()
            
            render.SetBlend(0.1)
            render.SetColorModulation(0.3, 0.9, 1)
            render.MaterialOverride(Material("models/debug/debugwhite"))
            ghostEnt:DrawModel()
            
            render.MaterialOverride(nil)
            render.SetColorModulation(1, 1, 1)
            render.SetBlend(1)
        end
    end
end)

local function UpdateCameraTarget()
    if not isMenuOpen then return end
    local zone = IvoFly.Zones and IvoFly.Zones[currentZoneIndex]
    if zone then
        local center = (zone.min + zone.max) / 2
        targetCameraPos = center + Vector(-700, -700, 600)
        targetCameraAng = (center - targetCameraPos):Angle()
    end
end

hook.Add("CalcView", "IvoFly_CalcView", function(ply, pos, angles, fov)
    if isMenuOpen and targetCameraPos and targetCameraAng then
        if not currentCamPos then
            currentCamPos = pos; currentCamAng = angles
        end
        currentCamPos = LerpVector(FrameTime() * 3, currentCamPos, targetCameraPos)
        currentCamAng = LerpAngle(FrameTime() * 3, currentCamAng, targetCameraAng)
        return { origin = currentCamPos, angles = currentCamAng, fov = fov, drawviewer = true }
    else
        currentCamPos = nil; currentCamAng = nil
    end
end)

local function CloseIvoFlyMenu()
    if IsValid(menuPanel) then menuPanel:Remove() end
    isMenuOpen = false
    gui.EnableScreenClicker(false)
    UpdateGhost()
end

local function DrawKeyLegend(x, y, key, desc)
    surface.SetFont("SW_InvShop_Medium")
    local tw, th = surface.GetTextSize(key)
    local kw = tw + 20; local kh = 26
    draw.RoundedBox(6, x, y - kh/2, kw, kh, Color(20, 25, 30, 240))
    draw.RoundedBox(6, x, y - kh/2 + kh - 4, kw, 4, Color(10, 15, 20, 250))
    draw.SimpleText(key, "SW_InvShop_Medium", x + kw/2, y - 2, color_white, 1, 1)
    draw.SimpleText(desc, "SW_InvShop_Medium", x + kw + 10, y - 1, Color(150, 150, 150), 0, 1)
    local dw, _ = surface.GetTextSize(desc)
    return kw + 10 + dw + 30
end

local function OpenIvoFlyMenu()
    if IsValid(menuPanel) then menuPanel:Remove() end

    currentZoneIndex = 1
    currentVehicleIndex = 1
    isMenuOpen = true
    gui.EnableScreenClicker(true)
    UpdateGhost()
    UpdateCameraTarget()

    menuPanel = vgui.Create("DFrame")
    menuPanel:SetSize(ScrW(), ScrH())
    menuPanel:Center()
    menuPanel:SetTitle("")
    menuPanel:MakePopup()
    menuPanel:ShowCloseButton(false)

    menuPanel.Paint = function(s, w, h)
        local y = h - 35
        local tW = 0
        surface.SetFont("SW_InvShop_Medium")
        tW = tW + surface.GetTextSize("CLICK IZQ") + 20 + 10 + surface.GetTextSize("SELECCIONAR") + 30
        tW = tW + surface.GetTextSize("BACKSPACE") + 20 + 10 + surface.GetTextSize("SALIR")
        local cx = w/2 - tW/2
        
        draw.RoundedBox(12, cx - 30, y - 25, tW + 40, 50, Color(0, 0, 0, 200))
        surface.SetDrawColor(0, 150, 255, 80)
        surface.DrawOutlinedRect(cx - 30, y - 25, tW + 40, 50)
        
        cx = cx + DrawKeyLegend(cx, y, "CLICK IZQ", "SELECCIONAR")
        DrawKeyLegend(cx, y, "BACKSPACE", "SALIR")
    end

    menuPanel.OnKeyCodePressed = function(s, key)
        if key == KEY_BACKSPACE then CloseIvoFlyMenu() end
    end

    local sidePanel = vgui.Create("DPanel", menuPanel)
    sidePanel:SetSize(310, 480)
    sidePanel:SetPos(50, ScrH() * 0.12)
    sidePanel.Paint = function(s, w, h)
        -- Background for the menu so buttons are not lost
        draw.RoundedBox(8, 0, 0, w, h, Color(15, 15, 20, 240))
        draw.SimpleText("SISTEMA TÁCTICO", "SW_InvShop_BigTitle", 20, 20, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("DESPLIEGUE AÉREO", "SW_InvShop_Aurebesh_Title", 20, 42, Color(150, 150, 150, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(0, 150, 255, 150)
        surface.DrawRect(20, 55, w - 40, 2)
    end

    local function CreateSelector(yPos, title, getValueText, onPrev, onNext)
        local pnl = vgui.Create("DPanel", sidePanel)
        pnl:SetPos(20, yPos); pnl:SetSize(270, 65)
        pnl.Paint = function(s, w, h)
            draw.SimpleText(title, "SW_InvShop_Small", 5, 10, Color(150,150,150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.RoundedBox(8, 0, 25, w, 40, Color(0,0,0,120))
            draw.SimpleText(getValueText(), "SW_InvShop_Medium", w/2, 45, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local btnPrev = vgui.Create("DButton", pnl)
        btnPrev:SetPos(0, 25); btnPrev:SetSize(40, 40); btnPrev:SetText("")
        btnPrev.Paint = function(s,w,h) draw.SimpleText("<", "SW_InvShop_Medium", w/2, h/2, s:IsHovered() and color_white or Color(150,150,150), 1, 1); return true end
        btnPrev.DoClick = function() LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5); onPrev() end

        local btnNext = vgui.Create("DButton", pnl)
        btnNext:SetPos(pnl:GetWide()-40, 25); btnNext:SetSize(40, 40); btnNext:SetText("")
        btnNext.Paint = function(s,w,h) draw.SimpleText(">", "SW_InvShop_Medium", w/2, h/2, s:IsHovered() and color_white or Color(150,150,150), 1, 1); return true end
        btnNext.DoClick = function() LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5); onNext() end
    end

    CreateSelector(75, "PLATAFORMA", 
        function() return "PAD " .. currentZoneIndex .. " / " .. #IvoFly.Zones end,
        function() currentZoneIndex = currentZoneIndex - 1; if currentZoneIndex < 1 then currentZoneIndex = #IvoFly.Zones end; UpdateCameraTarget(); UpdateGhost() end,
        function() currentZoneIndex = currentZoneIndex + 1; if currentZoneIndex > #IvoFly.Zones then currentZoneIndex = 1 end; UpdateCameraTarget(); UpdateGhost() end
    )

    CreateSelector(150, "VEHÍCULO", 
        function() return VEHICLES[currentVehicleIndex].name end,
        function() currentVehicleIndex = currentVehicleIndex - 1; if currentVehicleIndex < 1 then currentVehicleIndex = #VEHICLES end; UpdateGhost() end,
        function() currentVehicleIndex = currentVehicleIndex + 1; if currentVehicleIndex > #VEHICLES then currentVehicleIndex = 1 end; UpdateGhost() end
    )

    local function CreateActionBtn(yPos, title, subtitle, color, onClick)
        local btn = vgui.Create("DButton", sidePanel)
        btn:SetPos(20, yPos); btn:SetSize(270, 50); btn:SetText("")
        btn.HoverP = 0
        btn.Paint = function(s, w, h)
            s.HoverP = Lerp(FrameTime() * 15, s.HoverP, s:IsHovered() and 1 or 0)
            if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
            
            -- Fondo base oscuro
            draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 150))
            
            -- Borde falso de color (arriba/abajo)
            surface.SetDrawColor(color.r, color.g, color.b, 100)
            surface.DrawRect(0, 0, w, 2)
            surface.DrawRect(0, h-2, w, 2)
            
            -- Llenado al hover
            if s.HoverP > 0.01 then 
                draw.RoundedBox(8, 0, 0, w, h, Color(color.r, color.g, color.b, s.HoverP * 255)) 
            end
            
            local txtR = Lerp(s.HoverP, 255, 0)
            local txtG = Lerp(s.HoverP, 255, 0)
            local txtB = Lerp(s.HoverP, 255, 0)
            local txtColor = Color(txtR, txtG, txtB)
            
            draw.SimpleText(title, "SW_InvShop_Medium", 15, h/2 - 6, txtColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(subtitle, "SW_InvShop_Aurebesh_ExtraSmall", 15, h/2 + 8, Color(txtR, txtG, txtB, 150 + s.HoverP * 105), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function() LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5); onClick() end
    end

    CreateActionBtn(240, "DESPLEGAR NAVE", "INICIAR VUELO", Color(0, 150, 255), function()
        local class = VEHICLES[currentVehicleIndex].class
        if IvoFly.Zones[currentZoneIndex] then
            net.Start("IvoFly_Action")
            net.WriteString("spawn")
            net.WriteUInt(currentZoneIndex, 8)
            net.WriteString(class)
            net.SendToServer()
            -- IMPORTANTE: Ya no cerramos el menú aquí. Dejamos que la cinemática tome el control.
        end
    end)

    CreateActionBtn(300, "TALLER MECÁNICO", "MEJORAS LVS", Color(255, 170, 0), function()
        local class = VEHICLES[currentVehicleIndex].class
        CloseIvoFlyMenu()
        net.Start("IvoFly_RequestWorkshop")
        net.WriteString(class)
        net.SendToServer()
    end)

    CreateActionBtn(360, "RETIRAR NAVE", "LIMPIAR PLATAFORMA", Color(255, 60, 60), function()
        if IvoFly.Zones[currentZoneIndex] then
            net.Start("IvoFly_Action")
            net.WriteString("delete")
            net.WriteUInt(currentZoneIndex, 8)
            net.WriteString("")
            net.SendToServer()
        end
    end)
end

net.Receive("IvoFly_OpenMenu", function()
    if not IvoFly.Zones or #IvoFly.Zones == 0 then
        chat.AddText(Color(255, 80, 80), "[Ivo Fly] ", Color(255, 255, 255), "No hay plataformas de aterrizaje configuradas.")
        return
    end
    if LocalPlayer():GetViewEntity() == LocalPlayer() then
        targetCameraPos = LocalPlayer():EyePos()
        targetCameraAng = LocalPlayer():EyeAngles()
    end
    OpenIvoFlyMenu()
end)

net.Receive("IvoFly_Notification", function()
    local msg = net.ReadString()
    chat.AddText(Color(0, 150, 255), "[Ivo Fly] ", Color(255, 255, 255), msg)
end)

-- ============================================================
-- IVO FLY - EFECTO DE DESPLIEGUE CINEMATOGRÁFICO
-- ============================================================
local deployingShips = {}

local function DrawCircle3D(x, y, radius, seg)
    local cir = {}
    for i = 0, seg do
        local a = math.rad((i / seg) * -360)
        table.insert(cir, { x = x + math.sin(a) * radius, y = y + math.cos(a) * radius, u = math.sin(a) / 2 + 0.5, v = math.cos(a) / 2 + 0.5 })
    end
    surface.DrawPoly(cir)
end

net.Receive("IvoFly_DeployEffect", function()
    local activator = net.ReadEntity()
    local class = net.ReadString()
    local pos = net.ReadVector()
    local ang = net.ReadAngle()
    local zoneIdx = net.ReadUInt(8)

    -- Si soy el jugador que pidió la nave, activo el modo cinemático
    if activator == LocalPlayer() then
        if isMenuOpen then
            -- Ya estamos en el menú: Ocultamos los botones y el fantasma temporalmente
            if IsValid(menuPanel) then menuPanel:SetVisible(false) end
            if IsValid(ghostEnt) then ghostEnt:SetNoDraw(true) end
            
            timer.Simple(6.5, function()
                if isMenuOpen then CloseIvoFlyMenu() end
            end)
            
        elseif IvoFly.WorkshopActive then
            -- Venimos del taller: Hacemos transición de cámara hacia el PAD asignado
            if IvoFly.HideWorkshopUI then IvoFly.HideWorkshopUI() end
            IvoFly.WorkshopActive = false -- Desactiva la cámara del taller
            
            isMenuOpen = true 
            currentZoneIndex = zoneIdx
            UpdateCameraTarget()
            
            -- Hacemos un "Snap" de la cámara para que no vuele por todo el mapa
            currentCamPos = targetCameraPos
            currentCamAng = targetCameraAng
            
            timer.Simple(6.5, function()
                isMenuOpen = false
                currentCamPos = nil
                currentCamAng = nil
                if IvoFly.CloseWorkshopCinematic then IvoFly.CloseWorkshopCinematic() end
            end)
        end
    end

    local mdl = "models/error.mdl"
    local entTbl = scripted_ents.GetStored(class)
    if entTbl and entTbl.t and entTbl.t.MDL then mdl = entTbl.t.MDL end
    if class == "lvs_arc" then mdl = "models/sdog/arc170ch.mdl" end
    
    local cModel = ClientsideModel(mdl)
    if IsValid(cModel) then
        cModel:SetNoDraw(true)
        cModel:SetRenderBounds(Vector(-5000, -5000, -5000), Vector(5000, 5000, 5000))
        if class == "lvs_repulsorlift_atmospheric_laat" then cModel:SetSkin(1) end
        if class == "lvs_arc" then cModel:SetSkin(3) end
    end
    
    surface.PlaySound("ambient/machines/teleport4.wav")

    table.insert(deployingShips, {
        ent = cModel,
        endPos = pos,
        ang = ang,
        startTime = CurTime(),
        endTime = CurTime() + 6.5
    })
end)

hook.Add("PostDrawTranslucentRenderables", "IvoFly_DrawDeployEffects", function()
    for i = #deployingShips, 1, -1 do
        local data = deployingShips[i]
        local progress = math.Clamp((CurTime() - data.startTime) / (data.endTime - data.startTime), 0, 1)

        if progress >= 1 then
            if IsValid(data.ent) then data.ent:Remove() end
            table.remove(deployingShips, i)
            surface.PlaySound("weapons/physcannon/physcannon_drop.wav")
            continue
        end

        local ease = 1 - math.pow(1 - progress, 3)
        local minZ = 0
        local maxZ = 100
        local radius = 300
        
        if IsValid(data.ent) then 
            minZ = data.ent:OBBMins().z
            maxZ = data.ent:OBBMaxs().z
            local maxs = data.ent:OBBMaxs()
            local mins = data.ent:OBBMins()
            radius = math.max(maxs.x - mins.x, maxs.y - mins.y) * 0.6 
        end
        
        local dropDist = math.abs(maxZ - minZ) + 150
        local floorZ = data.endPos.z + minZ
        local floorPos = Vector(data.endPos.x, data.endPos.y, floorZ)
        
        -- Posicion actual de la nave (sube desde abajo)
        local currentPos = data.endPos - Vector(0, 0, dropDist * (1 - ease))
        
        local floorAng = Angle(0, 0, 0)
        floorAng:RotateAroundAxis(floorAng:Right(), 90)

        -- Fraccion de apertura de las puertas (abren rapido al inicio, cierran al final)
        local doorOpenFrac = math.Clamp(progress * 4, 0, 1)
        if progress > 0.85 then doorOpenFrac = math.Clamp((1 - progress) / 0.15, 0, 1) end
        local doorSlide = radius * doorOpenFrac

        -- ========== CIRCULO OSCURO DEL FOSO (solo cuando puertas abiertas) ==========
        if doorOpenFrac > 0.01 then
            cam.Start3D2D(floorPos + Vector(0,0,0.3), floorAng, 1)
                render.CullMode(MATERIAL_CULLMODE_NONE)
                draw.NoTexture()
                -- Foso oscuro
                surface.SetDrawColor(8, 8, 12, 240 * doorOpenFrac)
                DrawCircle3D(0, 0, radius * 0.95, 48)
                -- Anillo de borde luminoso
                surface.SetDrawColor(0, 120, 255, 180 * doorOpenFrac)
                local ringSegs = 48
                for j = 0, ringSegs - 1 do
                    local a1 = math.rad((j / ringSegs) * 360)
                    local a2 = math.rad(((j + 1) / ringSegs) * 360)
                    local r1 = radius * 0.94
                    local r2 = radius * 0.98
                    surface.DrawPoly({
                        {x = math.cos(a1) * r1, y = math.sin(a1) * r1},
                        {x = math.cos(a2) * r1, y = math.sin(a2) * r1},
                        {x = math.cos(a2) * r2, y = math.sin(a2) * r2},
                        {x = math.cos(a1) * r2, y = math.sin(a1) * r2},
                    })
                end
                render.CullMode(MATERIAL_CULLMODE_CW)
            cam.End3D2D()
        end

        -- ========== PUERTAS BLINDADAS (rectangulos simples que se deslizan) ==========
        if doorOpenFrac < 0.99 then
            cam.Start3D2D(floorPos + Vector(0,0,0.6), floorAng, 1)
                render.CullMode(MATERIAL_CULLMODE_NONE)
                draw.NoTexture()
                
                local doorW = radius
                local doorH = radius * 2
                
                -- Puerta Izquierda (se desliza hacia -X)
                surface.SetDrawColor(35, 38, 45, 255)
                surface.DrawRect(-doorSlide - doorW, -doorH/2, doorW, doorH)
                -- Linea de borde
                surface.SetDrawColor(255, 160, 0, 200)
                surface.DrawRect(-doorSlide - 2, -doorH/2, 3, doorH)
                -- Textura de rayas de peligro
                surface.SetDrawColor(255, 160, 0, 60)
                for k = 0, 6 do
                    surface.DrawRect(-doorSlide - doorW + k * 30, -doorH/2, 8, doorH)
                end
                
                -- Puerta Derecha (se desliza hacia +X)
                surface.SetDrawColor(35, 38, 45, 255)
                surface.DrawRect(doorSlide, -doorH/2, doorW, doorH)
                -- Linea de borde
                surface.SetDrawColor(255, 160, 0, 200)
                surface.DrawRect(doorSlide - 1, -doorH/2, 3, doorH)
                -- Textura de rayas de peligro
                surface.SetDrawColor(255, 160, 0, 60)
                for k = 0, 6 do
                    surface.DrawRect(doorSlide + k * 30, -doorH/2, 8, doorH)
                end
                
                render.CullMode(MATERIAL_CULLMODE_CW)
            cam.End3D2D()
        end

        -- ========== NAVE (clip-plane en el suelo para que solo se vea lo que sube) ==========
        if IsValid(data.ent) then
            data.ent:SetPos(currentPos)
            data.ent:SetAngles(data.ang)
            data.ent:SetupBones()
            
            -- Clip plane: solo dibujar la parte de la nave POR ENCIMA del suelo
            local clipNormal = Vector(0, 0, 1)
            local clipDist = clipNormal:Dot(Vector(0, 0, floorZ))
            
            local oldClip = render.EnableClipping(true)
            render.PushCustomClipPlane(clipNormal, clipDist)
            
            render.SetColorModulation(1, 1, 1)
            render.SetBlend(1)
            data.ent:DrawModel()
            
            render.PopCustomClipPlane()
            render.EnableClipping(oldClip)
        end

        -- ========== LUCES AMBIENTAL DEL FOSO (beams sutiles) ==========
        if doorOpenFrac > 0.3 then
            local beamAlpha = 80 * doorOpenFrac * (1 - ease)
            render.SetMaterial(Material("sprites/light_glow02_add"))
            render.DrawBeam(floorPos, floorPos + Vector(0, 0, 400), radius * 0.4, 0, 1, Color(0, 100, 255, beamAlpha))
        end
    end
end)