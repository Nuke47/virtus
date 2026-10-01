-- cl_thirdperson.lua
if SERVER then return end
CreateClientConVar("virtus_tp_cinematic", "1", true, false)
CreateClientConVar("virtus_tp_dynamic", "1", true, false)

-- LIMPIEZA DE HOOKS ANTIGUOS
hook.Remove("RenderScreenspaceEffects", "Virtus_TP_TransitionBlur")
hook.Remove("HUDPaint", "Virtus_TP_TransitionBlink")

-- Estructura de datos con F1 (ID 92) por defecto
VIRTUS_TP_CONFIG = {
    distance = 110,
    height = 8,
    side = 30,
    fov = 80,
    key = 92,
    active = false
}

local FILE_PATH = "virtus_tp_config.json"

surface.CreateFont("TP_Menu_Title", { font = "Montserrat", size = 20, weight = 1000, antialias = true })
surface.CreateFont("TP_Menu_Label", { font = "Montserrat", size = 13, weight = 700, antialias = true })

-- Cargar configuración JSON de forma segura
if file.Exists(FILE_PATH, "DATA") then
    local decoded = util.JSONToTable(file.Read(FILE_PATH, "DATA") or "")
    if decoded then 
        for k, v in pairs(decoded) do VIRTUS_TP_CONFIG[k] = v end 
    end
else
    file.Write(FILE_PATH, util.TableToJSON(VIRTUS_TP_CONFIG, true))
end

local thirdperson = VIRTUS_TP_CONFIG.active or false

function VIRTUS_SaveThirdPersonConfig()
    file.Write(FILE_PATH, util.TableToJSON(VIRTUS_TP_CONFIG, true))
end

-- ============================================================================
-- LÓGICA DE DETECCIÓN POR TECLA (SILENCIOSA)
-- ============================================================================
local nextToggle = 0
hook.Add("Think", "Virtus_TP_KeyDetector", function()
    if not vgui.CursorVisible() and input.IsKeyDown(VIRTUS_TP_CONFIG.key) and CurTime() > nextToggle then
        nextToggle = CurTime() + 0.2
        thirdperson = not thirdperson
        VIRTUS_TP_CONFIG.active = thirdperson
        VIRTUS_SaveThirdPersonConfig()
    end
end)

-- ============================================================================
-- LÓGICA DE RENDERING DE LA CÁMARA (CALCVIEW)
-- ============================================================================
local function IsThirdPersonActive(ply)
    if not thirdperson then return false end
    if not IsValid(ply) then return false end
    if not ply:Alive() then return false end

    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then
        local class = wep:GetClass()
        if class ~= "weapon_physgun" and class ~= "gmod_tool" and class ~= "weapon_camera" then
            local aiming = false
            if wep.GetIronSights and wep:GetIronSights() then aiming = true end
            if wep.GetIronsights and wep:GetIronsights() then aiming = true end
            if wep.GetNWBool and wep:GetNWBool("Ironsights") then aiming = true end
            if aiming then return false end
        end
    end

    return true
end

-- Variables de estado globales para el suavizado y transición
local currentCamOffset = nil 
local currentCamAng = nil
local camTransition = 0 

hook.Add("CalcView", "CustomThirdPersonView", function(ply, pos, ang, baseFov)
    if _G.SW_Armario3D_Active or _G.SW_Shop3D_Active then return end

    local targetState = IsThirdPersonActive(ply)
    ply.ThirdPerson = targetState 
    
    -- Si la cámara cinemática está desactivada, la transición es instantánea
    local cinematic = GetConVar("virtus_tp_cinematic"):GetBool()
    camTransition = math.Approach(camTransition, targetState and 1 or 0, FrameTime() * (cinematic and 4 or 999))
    _G.VirtusTP_CamTransition = camTransition

    if camTransition == 0 then 
        currentCamOffset = nil 
        currentCamAng = nil
        return 
    end

    if not currentCamOffset then
        currentCamOffset = Vector(0, 0, 0)
        currentCamAng = ang
    end

    local view = {}
    local frameTime = FrameTime()
    local easeTransition = math.ease.InOutSine(camTransition)
    
    local vel = ply:GetVelocity()
    local speed = vel:Length2D()

    local bobOffset = Vector(0, 0, 0)
    local velOffset = Vector(0, 0, 0)
    local mouseSwayOffset = Vector(0, 0, 0)
    
    local yawDelta = math.AngleDifference(ang.y, currentCamAng.y)
    local pitchDelta = math.AngleDifference(ang.p, currentCamAng.p)
    
    local isDynamic = GetConVar("virtus_tp_dynamic"):GetBool()
    
    if isDynamic then
        if ply:IsOnGround() and speed > 10 then
            local intensity = math.Clamp(speed / 250, 0, 0.8)
            local bobX = math.sin(CurTime() * 10) * intensity
            local bobZ = math.cos(CurTime() * 20) * intensity 
            bobOffset = ang:Right() * bobX + ang:Up() * bobZ
        end

        velOffset = -vel * 0.015 
        velOffset.x = math.Clamp(velOffset.x, -8, 8)
        velOffset.y = math.Clamp(velOffset.y, -8, 8)
        velOffset.z = math.Clamp(velOffset.z, -8, 8)
        
        local swayX = math.Clamp(yawDelta * 0.2, -5, 5)
        local swayZ = math.Clamp(pitchDelta * 0.2, -5, 5)
        mouseSwayOffset = ang:Right() * swayX - ang:Up() * swayZ
    end

    local basePos = pos - ang:Forward() * VIRTUS_TP_CONFIG.distance + ang:Right() * VIRTUS_TP_CONFIG.side + Vector(0, 0, VIRTUS_TP_CONFIG.height)
    local desiredTPPos = basePos + bobOffset + velOffset + mouseSwayOffset

    local trace = util.TraceHull({
        start = pos,
        endpos = desiredTPPos,
        filter = ply,
        mins = Vector(-4, -4, -4),
        maxs = Vector(4, 4, 4),
        mask = MASK_SOLID
    })

    local finalTargetPos = LerpVector(easeTransition, pos, trace.HitPos)
    local targetOffset = finalTargetPos - pos

    if currentCamOffset:DistToSqr(targetOffset) > 250000 then
        currentCamOffset = targetOffset
        currentCamAng = ang
    end

    local smoothSpeed = 15
    currentCamOffset = LerpVector(frameTime * smoothSpeed, currentCamOffset, targetOffset)
    local currentCamPos = pos + currentCamOffset
    
    local targetRoll = 0
    if isDynamic then
        targetRoll = math.Clamp(yawDelta * 0.25, -10, 10) * easeTransition
    end
    local targetAng = Angle(ang.p, ang.y, targetRoll)
    currentCamAng = LerpAngle(frameTime * smoothSpeed, currentCamAng, targetAng)

    view.origin = currentCamPos
    view.angles = currentCamAng
    view.fov = Lerp(easeTransition, baseFov, VIRTUS_TP_CONFIG.fov)
    view.drawviewer = (camTransition > 0.15)

    return view
end)

hook.Add("ShouldDrawLocalPlayer", "Virtus_TP_DrawLocalPlayer", function(ply)
    if camTransition > 0.15 then return true end
end)

hook.Add("PreDrawViewModel", "Virtus_TP_HideViewModel", function(vm, ply, wep)
    if camTransition > 0.15 then return true end
end)

-- IMPORTANTE: Esto arregla el bug de los "brazos rojos" de primera persona
hook.Add("PreDrawPlayerHands", "Virtus_TP_HideHands", function(hands, vm, ply, wep)
    if camTransition > 0.15 then return true end
end)

hook.Add("EntityFireBullets", "Virtus_TP_FixTracers", function(ent, data)
    if ent == LocalPlayer() and camTransition > 0.15 then
        local wep = ent:GetActiveWeapon()
        if IsValid(wep) and wep.IsTFAWeapon then
            data.Tracer = 0
            return true
        end
    end
end)

local lastState = nil
hook.Add("Think", "Virtus_TP_StateSync", function()
    if not IsValid(LocalPlayer()) then return end
    local currentState = IsThirdPersonActive(LocalPlayer())
    if currentState ~= lastState then
        lastState = currentState
        net.Start("Virtus_TP_State")
        net.WriteBool(currentState)
        net.SendToServer()
    end
end)

-- ============================================================================
-- PANEL DE CONFIGURACIÓN (MENU C)
-- ============================================================================
list.Set("DesktopWindows", "ThirdPersonSettings", {
    title = "Third Person Cam",
    icon = "icon64/camera.png",
    width = 460,
    height = 540,
    onewindow = true,

    init = function(icon, window)
        window:SetTitle("")
        window.Paint = function(self, w, h)
            if _G.VIRTUS_DrawHoloBackground then _G.VIRTUS_DrawHoloBackground(w, h) end
        end

        local panel = vgui.Create("DPanel", window)
        panel:Dock(FILL)
        panel:DockPadding(15, 15, 15, 15)
        panel.Paint = nil

        local title = vgui.Create("DLabel", panel)
        title:Dock(TOP)
        title:SetTall(30)
        title:SetText("AJUSTES DE CAMARA")
        title:SetFont("TP_Menu_Title")
        title:SetTextColor(Color(255, 255, 255))
        title:SetContentAlignment(4)
        
        local div = vgui.Create("DPanel", panel)
        div:Dock(TOP)
        div:SetTall(1)
        div:DockMargin(0, 0, 0, 15)
        div.Paint = function(self, w, h) surface.SetDrawColor(255, 255, 255, 40) surface.DrawRect(0, 0, w, h) end

        local grid = vgui.Create("DPanel", panel)
        grid:Dock(TOP)
        grid:SetTall(240)
        grid:DockMargin(0, 0, 0, 15)

        local dragging = false

        local function UpdateCameraGrid(mx, my, w, h)
            local SIDE_MIN, SIDE_MAX = -50, 50
            local HEIGHT_MIN, HEIGHT_MAX = -17.5, 17.5

            local side = SIDE_MIN + (mx / w) * (SIDE_MAX - SIDE_MIN)
            local height = HEIGHT_MAX - (my / h) * (HEIGHT_MAX - HEIGHT_MIN)

            VIRTUS_TP_CONFIG.side = math.Round(side)
            VIRTUS_TP_CONFIG.height = math.Round(height)
            
            VIRTUS_SaveThirdPersonConfig()
        end

        grid.Paint = function(self, w, h)
            local time = CurTime()
            local c_accent = _G.VIRTUS_GetHUDColor and _G.VIRTUS_GetHUDColor('accent') or Color(200, 50, 50)
            
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 220))
            surface.SetDrawColor(c_accent.r, c_accent.g, c_accent.b, 50)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            surface.SetDrawColor(255, 255, 255, 12)
            for i = 1, 19 do
                local xLine = (w / 20) * i
                surface.DrawLine(xLine, 0, xLine, h)
                local yLine = (h / 20) * i
                surface.DrawLine(0, yLine, w, yLine)
            end

            surface.SetDrawColor(255, 255, 255, 40)
            surface.DrawLine(w/2, 0, w/2, h)
            surface.DrawLine(0, h/2, w, h/2)
            
            local cx = ((VIRTUS_TP_CONFIG.side - (-50)) / (50 - (-50))) * w
            local cy = ((17.5 - VIRTUS_TP_CONFIG.height) / (17.5 - (-17.5))) * h

            local pulse = 12 + math.abs(math.sin(time * 5)) * 6
            surface.SetDrawColor(c_accent.r, c_accent.g, c_accent.b, 40)
            local shape_diamond = { { x = cx, y = cy - pulse }, { x = cx + pulse, y = cy }, { x = cx, y = cy + pulse }, { x = cx - pulse, y = cy } }
            draw.NoTexture()
            surface.DrawPoly(shape_diamond)

            surface.SetDrawColor(c_accent)
            surface.DrawLine(cx - 15, cy, cx + 15, cy)
            surface.DrawLine(cx, cy - 15, cx, cy + 15)

            draw.SimpleText("X: " .. VIRTUS_TP_CONFIG.side .. "  Y: " .. VIRTUS_TP_CONFIG.height, "TP_Menu_Label", w - 10, h - 20, Color(255, 255, 255, 50), TEXT_ALIGN_RIGHT)
        end

        grid.OnMousePressed = function(self)
            dragging = true
            self:MouseCapture(true)
            local mx, my = self:CursorPos()
            UpdateCameraGrid(mx, my, self:GetWide(), self:GetTall())
        end

        grid.OnMouseReleased = function(self)
            dragging = false
            self:MouseCapture(false)
        end

        grid.OnCursorMoved = function(self, x, y)
            if not dragging then return end
            x = math.Clamp(x, 0, self:GetWide())
            y = math.Clamp(y, 0, self:GetTall())
            UpdateCameraGrid(x, y, self:GetWide(), self:GetTall())
        end

        local function CreateConfigSlider(cfgKey, labelText, min, max)
            local slider = vgui.Create("DNumSlider", panel)
            slider:Dock(TOP)
            slider:DockMargin(0, 10, 0, 10)
            slider:SetMin(min)
            slider:SetMax(max)
            slider:SetDecimals(0)
            slider:SetValue(VIRTUS_TP_CONFIG[cfgKey])
            
            slider.Label:SetFont("TP_Menu_Label")
            slider.Label:SetTextColor(Color(255, 255, 255, 150))
            slider.Label:SetText(labelText:upper())
            slider.TextArea:SetTextColor(color_white)
            slider.TextArea:SetFont("TP_Menu_Label")
            
            slider.Slider.Paint = function(self, w, h)
                local c_accent = _G.VIRTUS_GetHUDColor and _G.VIRTUS_GetHUDColor('accent') or Color(200, 50, 50)
                draw.RoundedBox(0, 0, h/2 - 1, w, 2, Color(255, 255, 255, 10))
                local valW = (slider:GetValue() - min) / (max - min) * w
                surface.SetDrawColor(c_accent)
                surface.DrawRect(0, h/2 - 1, valW, 2)
            end
            slider.Slider.Knob.Paint = function(self, w, h)
                local c_accent = _G.VIRTUS_GetHUDColor and _G.VIRTUS_GetHUDColor('accent') or Color(200, 50, 50)
                draw.RoundedBox(0, 2, 2, w - 4, h - 4, c_accent)
            end
            
            slider.OnValueChanged = function(self, value)
                VIRTUS_TP_CONFIG[cfgKey] = math.Round(value)
                timer.Create("TP_JSON_SaveDelay_" .. cfgKey, 0.3, 1, function()
                    VIRTUS_SaveThirdPersonConfig()
                end)
            end
        end

        CreateConfigSlider("distance", "DISTANCIA CAM", 30, 110)
        CreateConfigSlider("fov", "CAMPO DE VISIÓN (FOV)", 70, 90)

        local binderContainer = vgui.Create("DPanel", panel)
        binderContainer:Dock(TOP)
        binderContainer:SetTall(35)
        binderContainer:DockMargin(0, 10, 0, 0)
        binderContainer.Paint = nil

        local binderLabel = vgui.Create("DLabel", binderContainer)
        binderLabel:Dock(LEFT)
        binderLabel:SetWide(150)
        binderLabel:SetText("ASIGNAR TECLA:")
        binderLabel:SetFont("TP_Menu_Label")
        binderLabel:SetTextColor(Color(200, 200, 200))

        local binder = vgui.Create("DBinder", binderContainer)
        binder:Dock(FILL)
        binder:SetFont("TP_Menu_Label")
        binder:SetSelectedNumber(VIRTUS_TP_CONFIG.key)
        
        binder.Paint = function(self, w, h)
            if _G.VIRTUS_DrawHoloButton then _G.VIRTUS_DrawHoloButton(w, h, self:IsHovered()) end
        end
        binder:SetTextColor(Color(255, 255, 255))

        binder.OnChange = function(self, numKey)
            VIRTUS_TP_CONFIG.key = numKey
            VIRTUS_SaveThirdPersonConfig()
        end
    end
})