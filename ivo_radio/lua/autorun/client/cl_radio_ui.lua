if IsValid(radioFrame) then radioFrame:Close() radioFrame = nil end
if IsValid(radioHUD) then radioHUD:Close() radioHUD = nil end

local radioFrame = nil
local radioHUD = nil

local ANCHO_PANEL = 340
local MARGEN_DERECHO = 25 

local function ParseCol(cv, def)
    local cvObj = GetConVar(cv)
    if not cvObj then return def end
    local p = string.Explode(" ", cvObj:GetString())
    if #p >= 3 then return Color(tonumber(p[1]) or 255, tonumber(p[2]) or 255, tonumber(p[3]) or 255, tonumber(p[4]) or 255) end
    return def
end

local function GetColAccent() return ParseCol("virtus_compass_col_accent", Color(0, 191, 165, 255)) end
local function GetColLine() return ParseCol("virtus_compass_col_line", Color(180, 180, 190, 80)) end
local function GetColText() return ParseCol("virtus_compass_col_text", Color(240, 240, 250, 255)) end

local COLOR_RED = Color(239, 83, 80, 255)           

surface.CreateFont("RadioMontserrat_HD", {
    font = "SansSerifFLF", size = 16, weight = 500, antialias = true, extended = true
})

surface.CreateFont("RadioMontserrat_Titulo", {
    font = "SansSerifFLF", size = 18, weight = 500, antialias = true, extended = true
})

hook.Add("InitPostEntity", "RadioFuerzaPermisoMicrofono", function()
    timer.Simple(2, function()
        if permissions and permissions.EnableVoiceChat then permissions.EnableVoiceChat(false) end
    end)
end)

if permissions and permissions.EnableVoiceChat then permissions.EnableVoiceChat(false) end

-- 1. HUD Integral Continuo (ESTILO HOLOGRÁFICO IMPERIAL)
local RadioHUD_State = {
    IsOn = false,
    TextoFrecuencia = "ESTADO » RADIO APAGADA",
    CanalActualSintonizado = "APAGADO"
}

local function ActualizarRadioHUD(channelName)
    if not IsValid(LocalPlayer()) then return end

    RadioHUD_State.CanalActualSintonizado = channelName

    if LocalPlayer():Health() <= 5 or not LocalPlayer():Alive() then
        RadioHUD_State.IsOn = false
        RadioHUD_State.TextoFrecuencia = "?? ESTADO » DISPOSITIVO DAÑADO"
    elseif channelName == "APAGADO" then
        RadioHUD_State.IsOn = false
        RadioHUD_State.TextoFrecuencia = "ESTADO » RADIO APAGADA"
    else
        RadioHUD_State.IsOn = true
        RadioHUD_State.TextoFrecuencia = "EN LÍNEA » " .. string.upper(channelName)
    end
end

if IsValid(radioHUD) then radioHUD:Remove() end

ActualizarRadioHUD("APAGADO")

hook.Add("HUDPaint", "RadioHUD_PaintHook", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or ply:Health() <= 0 then return end
    if ply:GetNWBool("IVO_RTSMode", false) then return end
    local cvHide = GetConVar("virtus_hide_hud")
    if cvHide and cvHide:GetBool() then return end

    local w, h = 320, 26
    -- Dinámico según la barra de vida/jetpack
    local x = _G.VirtusHUD_AnchorX or 80
    local anchorY = _G.VirtusHUD_AnchorY or (ScrH() - 170)
    local y = anchorY + 15
    
    -- Pivot sincronizado con la nueva posición
    if _G.VirtusSway then _G.VirtusSway.Begin3D(-2.5, x, y - 20) end
    
    local isSpeaking = _G.IsRadioTransmitting 
    if RadioHUD_State.IsOn and ply:IsSpeaking() then isSpeaking = true end
    
    local currentAccent = Color(255, 50, 50)
    local stateText = "DESCONECTADO"
    if isSpeaking then 
        currentAccent = Color(46, 204, 113)
        stateText = "TRANSMITIENDO"
    elseif RadioHUD_State.IsOn then
        currentAccent = GetColAccent()
        stateText = "RECIBIENDO"
    end
    
    -- Logo de audio
    local iconSize = 24
    if not _G.VirtusHUD_AudioMat then
        _G.VirtusHUD_AudioMat = Material("virtus/audio.png", "noclamp smooth")
        if _G.VirtusHUD_AudioMat:IsError() then _G.VirtusHUD_AudioMat = Material("virtus/audio", "noclamp smooth") end
    end
    
    surface.SetMaterial(_G.VirtusHUD_AudioMat)
    surface.SetDrawColor(currentAccent.r, currentAccent.g, currentAccent.b, 255)
    surface.DrawTexturedRect(x, y + h/2 - iconSize/2 - 8, iconSize, iconSize)
    
    if not RadioHUD_State.IsOn then
        surface.SetDrawColor(255, 50, 50, 255)
        surface.DrawLine(x, y + h/2 - iconSize/2 - 8, x + iconSize, y + h/2 + iconSize/2 - 8)
        surface.DrawLine(x, y + h/2 + iconSize/2 - 8, x + iconSize, y + h/2 - iconSize/2 - 8)
    end
    
    -- Texto Principal (Canal)
    local tx = x + iconSize + 10
    local colorTexto = currentAccent
    
    local canalTxt = string.upper(RadioHUD_State.TextoFrecuencia)
    draw.SimpleText(canalTxt, "RadioMontserrat_Titulo", tx, y + h/2 - 14, colorTexto, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    
    -- Texto Secundario (Aurebesh) estilo Tienda
    -- Limpiar acentos y flechas para que Aurebesh no tire error
    local txtAurebesh = canalTxt
    txtAurebesh = string.Replace(txtAurebesh, "»", ">")
    txtAurebesh = string.Replace(txtAurebesh, "Á", "A")
    txtAurebesh = string.Replace(txtAurebesh, "É", "E")
    txtAurebesh = string.Replace(txtAurebesh, "Í", "I")
    txtAurebesh = string.Replace(txtAurebesh, "Ó", "O")
    txtAurebesh = string.Replace(txtAurebesh, "Ú", "U")
    txtAurebesh = string.Replace(txtAurebesh, "Ñ", "N")
    
    draw.SimpleText(txtAurebesh, "VirtusHUD_AurebeshBar", tx, y + h/2 + 2, Color(255, 255, 255, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    if _G.VirtusSway then _G.VirtusSway.End3D() end
end)

-- =========================================================================
-- 2. MENÚ DE FRECUENCIAS (ESTILO HOLOGRÁFICO)
-- =========================================================================
local blurMat = Material("pp/blurscreen")
local function DrawBlur(alpha)
    surface.SetDrawColor(255, 255, 255, alpha)
    surface.SetMaterial(blurMat)
    for i = 1, 3 do
        blurMat:SetFloat("$blur", (i / 3) * 6 * (alpha/255))
        blurMat:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
    end
    surface.SetDrawColor(0, 0, 0, alpha * 0.4)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end

local function DrawSlice(centerX, centerY, radius, innerRadius, startAngle, endAngle, color, cutDepth, outlineColor)
    cutDepth = cutDepth or 18
    local cutAngle = 0.05
    
    if radius <= innerRadius then return end
    
    local currentCutDepth = math.min(cutDepth, (radius - innerRadius) * 0.8)
    local segments = math.max(12, math.ceil(80 * (endAngle - startAngle) / (math.pi * 2)))
    local step = (endAngle - startAngle) / segments
    
    local function GetInnerPos(a)
        if a <= endAngle - cutAngle + 0.0001 then
            return {x = centerX + math.cos(a) * innerRadius, y = centerY + math.sin(a) * innerRadius}
        else
            local pStart = {x = centerX + math.cos(endAngle - cutAngle) * innerRadius, y = centerY + math.sin(endAngle - cutAngle) * innerRadius}
            local pEnd = {x = centerX + math.cos(endAngle) * (innerRadius + currentCutDepth), y = centerY + math.sin(endAngle) * (innerRadius + currentCutDepth)}
            local fraction = math.Clamp((a - (endAngle - cutAngle)) / cutAngle, 0, 1)
            return {x = Lerp(fraction, pStart.x, pEnd.x), y = Lerp(fraction, pStart.y, pEnd.y)}
        end
    end

    surface.SetDrawColor(color)
    draw.NoTexture()
    
    local outlinePointsOuter = {}
    local outlinePointsInner = {}

    for i = 0, segments - 1 do
        local a1 = startAngle + i * step
        local a2 = startAngle + (i + 1) * step
        if i == segments - 1 then a2 = endAngle end
        
        local p1 = {x = centerX + math.cos(a1) * radius, y = centerY + math.sin(a1) * radius}
        local p2 = {x = centerX + math.cos(a2) * radius, y = centerY + math.sin(a2) * radius}
        local p3 = GetInnerPos(a2)
        local p4 = GetInnerPos(a1)
        
        surface.DrawPoly({p1, p2, p3, p4})
        
        if i == 0 then
            table.insert(outlinePointsOuter, p1)
            table.insert(outlinePointsInner, p4)
        end
        table.insert(outlinePointsOuter, p2)
        table.insert(outlinePointsInner, p3)
    end
    
    if outlineColor then
        surface.SetDrawColor(outlineColor)
        
        for i = 1, #outlinePointsOuter - 1 do
            surface.DrawLine(outlinePointsOuter[i].x, outlinePointsOuter[i].y, outlinePointsOuter[i+1].x, outlinePointsOuter[i+1].y)
        end
        
        for i = 1, #outlinePointsInner - 1 do
            surface.DrawLine(outlinePointsInner[i].x, outlinePointsInner[i].y, outlinePointsInner[i+1].x, outlinePointsInner[i+1].y)
        end
        
        surface.DrawLine(outlinePointsInner[1].x, outlinePointsInner[1].y, outlinePointsOuter[1].x, outlinePointsOuter[1].y)
        surface.DrawLine(outlinePointsInner[#outlinePointsInner].x, outlinePointsInner[#outlinePointsInner].y, outlinePointsOuter[#outlinePointsOuter].x, outlinePointsOuter[#outlinePointsOuter].y)
    end
end

local function DrawCurvedText(text, font, cx, cy, radius, midAngle, color)
    surface.SetFont(font)
    local tw, th = surface.GetTextSize(text)
    
    local span = tw / radius
    
    local normAngle = midAngle
    while normAngle < 0 do normAngle = normAngle + math.pi * 2 end
    while normAngle >= math.pi * 2 do normAngle = normAngle - math.pi * 2 end
    
    local isBottom = (normAngle > 0 and normAngle < math.pi)
    
    local chars = {}
    if utf8 and utf8.codes then
        local success = pcall(function()
            for p, c in utf8.codes(text) do table.insert(chars, utf8.char(c)) end
        end)
        if not success then
            chars = {}
            for i = 1, #text do table.insert(chars, string.sub(text, i, i)) end
        end
    else
        for i = 1, #text do table.insert(chars, string.sub(text, i, i)) end
    end
    
    if isBottom then
        local currentAngle = midAngle + span / 2
        for _, char in ipairs(chars) do
            local cw, ch = surface.GetTextSize(char)
            local charSpan = cw / radius
            local a = currentAngle - charSpan / 2
            
            local px = cx + math.cos(a) * radius
            local py = cy + math.sin(a) * radius
            
            local m = Matrix()
            m:Translate(Vector(px, py, 0))
            m:Rotate(Angle(0, math.deg(a) - 90, 0))
            m:Translate(Vector(-cw/2, -ch/2, 0))
            
            cam.PushModelMatrix(m)
            draw.SimpleText(char, font, 0, 0, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            cam.PopModelMatrix()
            
            currentAngle = currentAngle - charSpan
        end
    else
        local currentAngle = midAngle - span / 2
        for _, char in ipairs(chars) do
            local cw, ch = surface.GetTextSize(char)
            local charSpan = cw / radius
            local a = currentAngle + charSpan / 2
            
            local px = cx + math.cos(a) * radius
            local py = cy + math.sin(a) * radius
            
            local m = Matrix()
            m:Translate(Vector(px, py, 0))
            m:Rotate(Angle(0, math.deg(a) + 90, 0))
            m:Translate(Vector(-cw/2, -ch/2, 0))
            
            cam.PushModelMatrix(m)
            draw.SimpleText(char, font, 0, 0, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            cam.PopModelMatrix()
            
            currentAngle = currentAngle + charSpan
        end
    end
end

local function AbrirMenuFrecuenciasV2()
    if IsValid(radioFrame) then radioFrame:Close() end

    local myTeamID = LocalPlayer():Team()
    local myJobStringName = ""
    for name, data in pairs(gmod and _G or {}) do
        if string.sub(name, 1, 5) == "TEAM_" and data == myTeamID then
            myJobStringName = name
            break
        end
    end

    local myCategory = "Desconocida"
    if DarkRP and DarkRP.getCategories and DarkRP.getCategories().jobs then
        for _, catTable in pairs(DarkRP.getCategories().jobs) do
            if catTable.members then
                for _, jobData in ipairs(catTable.members) do
                    if jobData.team == myTeamID then
                        myCategory = catTable.name
                        break
                    end
                end
            end
        end
    end

    if myCategory == "Desconocida" and RPExtraTeams and RPExtraTeams[myTeamID] then
        myCategory = RPExtraTeams[myTeamID].category or "Desconocida"
    end

    local frecuenciasDisponibles = {}
    if RadioFrequencies then
        for _, data in ipairs(RadioFrequencies) do
            local tieneAcceso = false 
            if not data.category and not data.jobs then tieneAcceso = true end
            if data.category and myCategory == data.category then tieneAcceso = true end
            if data.jobs then
                for _, jobString in ipairs(data.jobs) do
                    if myJobStringName == jobString then tieneAcceso = true break end
                end
            end
            if tieneAcceso then table.insert(frecuenciasDisponibles, data) end
        end
    end

    radioFrame = vgui.Create("DFrame")
    radioFrame:SetSize(ScrW(), ScrH()) 
    radioFrame:SetPos(0, 0)
    radioFrame:SetTitle("") 
    radioFrame:ShowCloseButton(false)
    radioFrame:SetDraggable(false)
    radioFrame:MakePopup()
    radioFrame:SetKeyboardInputEnabled(false)
    radioFrame.StartTime = SysTime()
    radioFrame.AlphaAnim = 0
    radioFrame.SegHover = {}
    radioFrame.CenterHover = 0
    
    gui.EnableScreenClicker(true)
    local centerX, centerY = ScrW() / 2, ScrH() / 2
    input.SetCursorPos(centerX, centerY)

    local outerRadius = 240
    local innerRadius = 100
    local numItems = #frecuenciasDisponibles

    radioFrame.Paint = function(self, w, h)
        local animProgress = math.Clamp((SysTime() - self.StartTime) / 0.2, 0, 1)
        self.AlphaAnim = Lerp(FrameTime() * 10, self.AlphaAnim, self.Closing and 0 or 255 * animProgress)
        
        if self.Closing and self.AlphaAnim < 5 then
            self:Remove()
            return
        end
        
        DrawBlur(self.AlphaAnim)
        
        local mouseX, mouseY = input.GetCursorPos()
        local dx = mouseX - centerX
        local dy = mouseY - centerY
        local dist = math.sqrt(dx*dx + dy*dy)
        
        local mouseAngle = math.atan2(dy, dx)
        if mouseAngle < 0 then mouseAngle = mouseAngle + math.pi * 2 end
        
        local segmentAngle = math.pi * 2 / math.max(1, numItems)
        
        local hoveredIndex = nil
        if dist > innerRadius - 10 then
            local adjustedAngle = mouseAngle + segmentAngle / 2
            if adjustedAngle > math.pi * 2 then adjustedAngle = adjustedAngle - math.pi * 2 end
            hoveredIndex = math.floor(adjustedAngle / segmentAngle) + 1
            if hoveredIndex > numItems then hoveredIndex = nil end
        end
        
        if hoveredIndex and hoveredIndex ~= self.HoveredIndex then
            LocalPlayer():EmitSound("UI/buttonrollover.wav", 75, 100, 0.5)
        end
        self.HoveredIndex = hoveredIndex
        
        local sliceAlpha = (self.AlphaAnim / 255)
        
        for i, data in ipairs(frecuenciasDisponibles) do
            local startAngle = (i - 1) * segmentAngle - (segmentAngle / 2)
            local endAngle = startAngle + segmentAngle
            local padAngle = 0.04
            
            local isHovered = (i == hoveredIndex)
            
            self.SegHover[i] = Lerp(FrameTime() * 12, self.SegHover[i] or 0, isHovered and 1 or 0)
            local hp = self.SegHover[i]
            
            local baseColor = Color(0, 0, 0, 150 * sliceAlpha)
            local borderColor = Color(255, 255, 255, 25 * sliceAlpha)
            
            local animOuterRadius = outerRadius * (0.9 + 0.1 * animProgress)
            DrawSlice(centerX, centerY, animOuterRadius, innerRadius, startAngle + padAngle, endAngle - padAngle, baseColor, 18, borderColor)
            
            if hp > 0.01 then
                local animRadius = innerRadius + (animOuterRadius - innerRadius) * hp
                local hoverColor = Color(255, 255, 255, 200 * hp * sliceAlpha)
                local hoverBorder = Color(255, 255, 255, 255 * hp * sliceAlpha)
                DrawSlice(centerX, centerY, animRadius, innerRadius, startAngle + padAngle, endAngle - padAngle, hoverColor, 18, hoverBorder)
            end
            
            local midAngle = (startAngle + endAngle) / 2
            local textRadius = innerRadius + (animOuterRadius - innerRadius) / 2
            
            local nameStr = string.upper(data.name)
            local chStr = "CH " .. data.channel
            
            local tc = Lerp(hp, 200, 0)
            local textAlpha = tc * sliceAlpha
            local txtColor = Color(tc, tc, tc, textAlpha)
            local aurebeshColor = Color(tc, tc, tc, (100 + hp * 155) * sliceAlpha)
            
            local r1 = textRadius + 16
            local r2 = textRadius
            local r3 = textRadius - 16
            
            local normA = midAngle
            while normA < 0 do normA = normA + math.pi * 2 end
            while normA >= math.pi * 2 do normA = normA - math.pi * 2 end
            local isBottom = (normA > 0 and normA < math.pi)
            
            if isBottom then
                r1, r3 = r3, r1
            end
            
            DrawCurvedText(nameStr, "SW_InvShop_Medium", centerX, centerY, r1, midAngle, txtColor)
            DrawCurvedText(nameStr, "SW_InvShop_Aurebesh_ExtraSmall", centerX, centerY, r2, midAngle, aurebeshColor)
            DrawCurvedText(chStr, "SW_InvShop_Medium", centerX, centerY, r3, midAngle, txtColor)
        end
        
        local isCancelHovered = (dist <= innerRadius - 10 and dist > 15)
        if isCancelHovered and not self.WasCancelHovered then
            LocalPlayer():EmitSound("UI/buttonrollover.wav", 75, 100, 0.5)
        end
        self.WasCancelHovered = isCancelHovered
        
        self.CenterHover = Lerp(FrameTime() * 12, self.CenterHover, isCancelHovered and 1 or 0)
        
        surface.SetDrawColor(0, 0, 0, 150 * sliceAlpha)
        draw.NoTexture()
        
        local circlePoly = {}
        for i=0, 32 do
            local a = math.rad( (i/32) * -360 )
            table.insert(circlePoly, {x = centerX + math.cos(a) * (innerRadius - 10), y = centerY + math.sin(a) * (innerRadius - 10)})
        end
        surface.DrawPoly(circlePoly)
        
        if self.CenterHover > 0.01 then
            surface.SetDrawColor(255, 50, 50, 200 * self.CenterHover * sliceAlpha)
            surface.DrawPoly(circlePoly)
        end
        
        local tcCenter = Lerp(self.CenterHover, 200, 255)
        local hColor = isCancelHovered and 255 or tcCenter
        local txtColorCenter = Color(255, hColor, hColor, tcCenter * sliceAlpha)
        draw.SimpleText("DESCONECTAR", "SW_InvShop_Medium", centerX, centerY - 6, txtColorCenter, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("DESCONECTAR", "SW_InvShop_Aurebesh_ExtraSmall", centerX, centerY + 8, Color(255, hColor, hColor, (100 + self.CenterHover * 155) * sliceAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    radioFrame.SelectHovered = function(self)
        if self.HoveredIndex and frecuenciasDisponibles[self.HoveredIndex] then
            local data = frecuenciasDisponibles[self.HoveredIndex]
            LocalPlayer():EmitSound("UI/buttonclick.wav", 75, 100, 0.5)
            net.Start("NetworkRadioChannel")
                net.WriteInt(data.channel, 16)
            net.SendToServer()
            
            ActualizarRadioHUD(data.name)
        elseif self.WasCancelHovered then
            LocalPlayer():EmitSound("UI/buttonclick.wav", 75, 100, 0.5)
            net.Start("NetworkRadioChannel")
                net.WriteInt(0, 16)
            net.SendToServer()
            ActualizarRadioHUD("APAGADO")
        end
        
        self.Closing = true
        gui.EnableScreenClicker(false)
    end
    
    radioFrame.OnMouseReleased = function(self, keyCode)
        if keyCode == MOUSE_LEFT then
            self:SelectHovered()
        end
    end
end

-- 3. Control de Teclado Inteligente (Mantener P)
local flagP_Presionada = false
hook.Add("Think", "FuerzaRadioHoldV2", function()
    local keyPressed = input.IsButtonDown(GetConVar("virtus_bind_radio_menu") and GetConVar("virtus_bind_radio_menu"):GetInt() or KEY_P)
    if keyPressed and not flagP_Presionada then
        if not gui.IsConsoleVisible() and not gui.IsGameUIVisible() and not vgui.GetKeyboardFocus() then
            flagP_Presionada = true
            AbrirMenuFrecuenciasV2()
        end
    elseif not keyPressed and flagP_Presionada then
        if IsValid(radioFrame) and not radioFrame.Closing then
            radioFrame:SelectHovered()
        end
        flagP_Presionada = false
    end
end)

-- =========================================================================
-- 4. TRANSMISIÃƒâ€œN NATIVA BLINDADA POR SALUD CRÃƒÂÃ‚ÂTICA (TECLA H)
-- =========================================================================
local isTransmitting = false
local ultimoEnvioDeRed = 0 

hook.Add("Think", "RadioTransmitKeyH", function()
    if IsValid(radioHUD) and radioHUD.CanalActualSintonizado == "APAGADO" then
        if isTransmitting then
            isTransmitting = false
            net.Start("RadioTransmitState")
                net.WriteBool(false)
            net.SendToServer()
            permissions.EnableVoiceChat(false) 
        end
        return 
    end

    if LocalPlayer():Health() <= 5 or not LocalPlayer():Alive() then
        if IsValid(radioHUD) and radioHUD.TextoFrecuencia ~= "?? ESTADO \xC2\xBB DISPOSITIVO DA\xC3\x91ADO" then
            radioHUD.IsOn = false
            radioHUD.TextoFrecuencia = "?? ESTADO \xC2\xBB DISPOSITIVO DA\xC3\x91ADO"
        end
        if isTransmitting then
            isTransmitting = false
            net.Start("RadioTransmitState")
                net.WriteBool(false)
            net.SendToServer()
            permissions.EnableVoiceChat(false) 
        end
        return 
    else
        if IsValid(radioHUD) and radioHUD.TextoFrecuencia == "?? ESTADO \xC2\xBB DISPOSITIVO DA\xC3\x91ADO" then
            ActualizarRadioHUD(radioHUD.CanalActualSintonizado or "APAGADO")
        end
    end

    if vgui.GetKeyboardFocus() or gui.IsConsoleVisible() or gui.IsGameUIVisible() then 
        if isTransmitting then
            isTransmitting = false
            net.Start("RadioTransmitState")
                net.WriteBool(false)
            net.SendToServer()
            permissions.EnableVoiceChat(false)
        end
        return 
    end

    local keyPressed = input.IsButtonDown(GetConVar("virtus_bind_radio_talk") and GetConVar("virtus_bind_radio_talk"):GetInt() or KEY_H)
    local tiempoActual = RealTime()

    if tiempoActual < ultimoEnvioDeRed + 0.05 then return end

    if keyPressed and not isTransmitting then
        isTransmitting = true
        ultimoEnvioDeRed = tiempoActual
        LocalPlayer():EmitSound("npc/metropolice/vo/on1.wav", 65, 100, GetConVar("virtus_radio_vol") and GetConVar("virtus_radio_vol"):GetFloat() or 0.5)
        net.Start("RadioTransmitState")
            net.WriteBool(true)
        net.SendToServer()
        permissions.EnableVoiceChat(true) 
    elseif not keyPressed and isTransmitting then
        isTransmitting = false
        ultimoEnvioDeRed = tiempoActual
        LocalPlayer():EmitSound("npc/metropolice/vo/off4.wav", 65, 100, GetConVar("virtus_radio_vol") and GetConVar("virtus_radio_vol"):GetFloat() or 0.5)
        net.Start("RadioTransmitState")
            net.WriteBool(false)
        net.SendToServer()
        permissions.EnableVoiceChat(false) 
    end
end)

-- =========================================================================
-- 5. CAJA DE VOZ HOLOGRÃƒÂÃ‚ÂFICA (VOICE UI) CON AVATAR 3D
-- =========================================================================

local ActiveVoicePanels = {}

local function CreateVoicePanel(ply)
    if not IsValid(ply) then return end
    if IsValid(ActiveVoicePanels[ply]) then return end

    local pnl = vgui.Create("DPanel")
    pnl:SetSize(280, 50) 
    
    local baseY = 64 + 32 + 15
    local baseX = ScrW() - 280 - MARGEN_DERECHO
    
    local offset = 0
    for k, v in pairs(ActiveVoicePanels) do
        if IsValid(v) then offset = offset + 55 end
    end
    
    pnl:SetPos(baseX + 280, baseY + offset) 
    pnl:MoveTo(baseX, baseY + offset, 0.2, 0, -1) 
    
    pnl.ply = ply
    pnl.Volume = 0

    -- Modelo de la cabeza en 3D
    local mdl = vgui.Create("DModelPanel", pnl)
    mdl:SetSize(42, 42)
    mdl:SetPos(15, 4)
    mdl:SetModel(ply:GetModel())
    mdl:SetColor(GetColAccent()) -- Filtro verde nativo en el modelo
    function mdl:LayoutEntity(ent) return end 
    
    local headBone = mdl.Entity:LookupBone("ValveBiped.Bip01_Head1")
    if headBone then
        local headpos = mdl.Entity:GetBonePosition(headBone)
        if headpos then
            mdl:SetLookAt(headpos)
            mdl:SetCamPos(headpos + Vector(15, 0, 0))
        end
    else
        mdl:SetCamPos(Vector(40, 0, 60))
        mdl:SetLookAt(Vector(0, 0, 40))
    end
    
    -- Overlay hologrÃƒÂÃ‚Â¡fico verde que parpadea al hablar
    mdl.PaintOver = function(self, w, h)
        if IsValid(pnl.ply) then
            -- Tintado ambiental
            surface.SetDrawColor(GetColAccent().r, GetColAccent().g, GetColAccent().b, 30)
            surface.DrawRect(0, 0, w, h)
            
            -- Brillo reactivo
            local pulse = pnl.Volume * 150
            surface.SetDrawColor(GetColAccent().r, GetColAccent().g, GetColAccent().b, pulse)
            surface.DrawRect(0, 0, w, h)
            
            -- Scanlines densas tipo lente
            surface.SetDrawColor(0, 20, 0, 100)
            for k = 1, h, 2 do surface.DrawLine(0, k, w, k) end
        end
    end

    pnl.Paint = function(self, w, h)
        if not IsValid(self.ply) then self:Remove() return end

        local vol = self.ply:VoiceVolume()
        self.Volume = math.Approach(self.Volume, vol, FrameTime() * 10)

        local c_bg = _G.VIRTUS_GetHUDColor and _G.VIRTUS_GetHUDColor("bg") or Color(10, 15, 25, 200)
        local c_acc = _G.VIRTUS_GetHUDColor and _G.VIRTUS_GetHUDColor("accent") or Color(0, 150, 255)
        
        draw.NoTexture()
        local cut = 10
        local poly = { {x = 0, y = 0}, {x = w, y = 0}, {x = w, y = h - cut}, {x = w - cut, y = h}, {x = 0, y = h} }
        surface.SetDrawColor(c_bg.r, c_bg.g, c_bg.b, c_bg.a)
        surface.DrawPoly(poly)
        
        if self.Volume > 0.05 then
            surface.SetDrawColor(c_acc.r, c_acc.g, c_acc.b, self.Volume * 45)
            surface.DrawPoly(poly)
        end
        
        surface.SetDrawColor(c_acc.r, c_acc.g, c_acc.b, 5)
        for k = 2, h - 2, 6 do
            local lineW = w
            if k > h - cut then lineW = w - (k - (h - cut)) end
            surface.DrawLine(0, k, lineW, k)
        end

        local bAlpha = 50 + (self.Volume * 155)
        surface.SetDrawColor(c_acc.r, c_acc.g, c_acc.b, bAlpha)
        local lw, lh = w - 1, h - 1
        surface.DrawLine(0, 0, lw, 0)
        surface.DrawLine(lw, 0, lw, lh - cut)
        surface.DrawLine(lw, lh - cut, lw - cut, lh)
        surface.DrawLine(lw - cut, lh, 0, lh)
        surface.DrawLine(0, lh, 0, 0)
        
        surface.DrawRect(0, 0, 4, h)
        
        local plyName = string.upper(self.ply:Nick())
        draw.SimpleText(plyName, "RadioMontserrat_HD", 65, h / 2 + 1, Color(0, 0, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(plyName, "RadioMontserrat_HD", 65, h / 2 - 1, GetColText(), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        local waveX = w - 45
        for i = 1, 4 do
            local waveH = 4 + (math.sin(RealTime() * 15 + i) * 6 * self.Volume) + (self.Volume * 20)
            waveH = math.Clamp(waveH, 2, h - 10)
            surface.SetDrawColor(GetColAccent().r, GetColAccent().g, GetColAccent().b, accentAlpha)
            surface.DrawRect(waveX + (i * 7), (h / 2) - (waveH / 2), 3, waveH)
        end
    end

    ActiveVoicePanels[ply] = pnl
end

local function RemoveVoicePanel(ply)
    if IsValid(ActiveVoicePanels[ply]) then
        local pnl = ActiveVoicePanels[ply]
        local x, y = pnl:GetPos()
        pnl:MoveTo(x + 280, y, 0.2, 0, -1, function()
            if IsValid(pnl) then pnl:Remove() end
        end)
        ActiveVoicePanels[ply] = nil
        
        -- Reordenar los paneles restantes
        local offset = 0
        local baseY = 64 + 32 + 15
        local baseX = ScrW() - 280 - MARGEN_DERECHO
        for k, v in pairs(ActiveVoicePanels) do
            if IsValid(v) then
                v:MoveTo(baseX, baseY + offset, 0.2, 0, -1)
                offset = offset + 55
            end
        end
    end
end

hook.Add("InitPostEntity", "HideDefaultVoiceUI", function()
    timer.Simple(2, function()
        if IsValid(g_VoicePanelList) then
            g_VoicePanelList:SetVisible(false)
        end
    end)
end)

hook.Add("PlayerStartVoice", "RadioHolographicVoiceHook", function(ply)
    CreateVoicePanel(ply)
end)

hook.Add("PlayerEndVoice", "RadioHolographicVoiceHook", function(ply)
    RemoveVoicePanel(ply)
end)




















