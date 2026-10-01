VIRTUS_CHAT = VIRTUS_CHAT or {}

-- ============================================================================
-- VIRTUS CHATBOX: CORE LOGIC & UI
-- ============================================================================

local isChatOpen = false
local activeTab = "ALL"
local currentChannel = ""
local messages = {
    ["ALL"] = {},
    ["OOC"] = {},
    ["PM"] = {}
}

local frame
local scrollPanel
local textEntry
local tabsPanel
local inputBg
local btnContainer
local cfgBtn

-- Oculta el chat por defecto
hook.Add("HUDShouldDraw", "VirtusChat_HideDefault", function(name)
    if name == "CHudChat" then return false end
end)

-- Limpia el chatbox actual si existe (para recargas)
if IsValid(VIRTUS_CHAT.Frame) then
    VIRTUS_CHAT.Frame:Remove()
end

local function BuildChatbox()
    local w = cookie.GetNumber("VirtusChat_W_v2", 600)
    local h = cookie.GetNumber("VirtusChat_H_v2", 150)
    local margin = 20

    frame = vgui.Create("DFrame")
    frame:SetSize(w, h)
    frame:SetCookieName("VirtusChat_PosConfig_TopLeft_2")
    
    -- Posición por defecto si no hay cookie
    if not frame:GetCookieNumber("x") then
        frame:SetPos(margin, 10) -- Más arriba todavía
    end
    
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(true)
    frame:SetSizable(true)
    frame:SetMinWidth(350)
    frame:SetMinHeight(120)
    VIRTUS_CHAT.Frame = frame

    frame.Paint = function(self, pw, ph)
        if isChatOpen then
            local bgH = ph
            if IsValid(btnContainer) and btnContainer:IsVisible() then
                local _, by = btnContainer:GetPos()
                bgH = by + btnContainer:GetTall() + 8
            elseif IsValid(inputBg) and inputBg:IsVisible() then
                local _, iy = inputBg:GetPos()
                bgH = iy + inputBg:GetTall() + 8
            end
            draw.RoundedBox(8, 0, 0, pw, bgH, Color(0, 0, 0, 80))
        end
    end

    -- Botón de configuración (oculto)
    cfgBtn = vgui.Create("DButton", frame)
    cfgBtn:SetSize(30, 30)
    cfgBtn:SetText("")
    cfgBtn:SetVisible(false)
    cfgBtn.Paint = function() end

    -- Pestañas (Totalmente desactivadas y ocultas)
    tabsPanel = vgui.Create("DPanel", frame)
    tabsPanel:SetVisible(false)
    tabsPanel.Paint = function() end

    -- Panel de scroll para mensajes
    scrollPanel = vgui.Create("DScrollPanel", frame)
    -- Quitamos Dock(FILL) para controlar su altura dinámicamente
    scrollPanel:SetPos(10, 10)
    
    local oldLayout = scrollPanel.PerformLayout
    scrollPanel.PerformLayout = function(self, w, h)
        oldLayout(self, w, h)
        -- Ajustar el tamaño del scrollPanel y la posición del inputBg según la cantidad de mensajes
        local frameW, frameH = frame:GetSize()
        local maxScrollH = frameH - 75 -- Espacio para el inputBg (28) y botones (25) + padding
        local canvasTall = self:GetCanvas():GetTall()
        
        local actualScrollH = math.min(maxScrollH, canvasTall)
        if actualScrollH == 0 then actualScrollH = 20 end
        
        self:SetSize(frameW - 20, actualScrollH)
        
        if IsValid(inputBg) then
            inputBg:SetPos(14, 10 + actualScrollH + 5)
            inputBg:SetSize(frameW - 34, 28)
        end
        
        if IsValid(btnContainer) then
            btnContainer:SetPos(14, 10 + actualScrollH + 5 + 28 + 1)
            btnContainer:SetSize(frameW - 34, 25)
        end
    end

    local sbar = scrollPanel:GetVBar()
    sbar:SetWide(3) -- Scrollbar muy chiquitito
    sbar:SetHideButtons(true)
    sbar.Paint = function() end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(self, pw, ph)
        if isChatOpen then
            draw.RoundedBox(1, 0, 0, pw, ph, Color(255, 255, 255, 30))
        end
    end

    VIRTUS_CHAT.MessageHistory = VIRTUS_CHAT.MessageHistory or {}
    VIRTUS_CHAT.HistoryIndex = 0

    -- Input
    inputBg = vgui.Create("DPanel", frame)
    -- Quitamos Dock(BOTTOM) para que persiga a los mensajes
    inputBg:SetHeight(28)
    inputBg:SetVisible(false)
    
    inputBg.Paint = function(self, pw, ph)
        local isFocused = textEntry:HasFocus()
        if isFocused then
            -- Solo una línea curva arriba (minimalismo extremo)
            draw.RoundedBox(1, 0, 0, pw, 2, Color(255, 255, 255, 100))
            
            -- Fondo casi imperceptible para que el texto sea legible
            draw.RoundedBox(0, 0, 2, pw, ph-2, Color(0, 0, 0, 20))
        end
    end

    btnContainer = vgui.Create("DPanel", frame)
    btnContainer:SetVisible(false)
    btnContainer.Paint = function() end

    local btns = {
        { name = "IMP", cmd = "/imp " },
        { name = "OOC", cmd = "// " },
        { name = "PM", cmd = "", tab = "PM" },
        { name = "ME", cmd = "/me " },
        { name = "ACCION", cmd = "/acc " },
        { name = "COMMS", cmd = "/comms " }
    }
    
    local bw = 60
    local spacing = 5
    for _, b in ipairs(btns) do
        local btn = vgui.Create("DButton", btnContainer)
        btn:SetText("")
        btn.HoverP = 0
        btn.Paint = function(s, w, h)
            local isActive = (b.tab and activeTab == b.tab) or (not b.tab and currentChannel == b.cmd)
            local targetHover = (s:IsHovered() or isActive) and 1 or 0
            s.HoverP = Lerp(FrameTime() * 15, s.HoverP, targetHover)
            if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
            
            draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 180))
            if s.HoverP > 0.01 then
                draw.RoundedBox(8, 0, 0, w, h, isActive and Color(255, 150, 0, s.HoverP * 255) or Color(255, 255, 255, s.HoverP * 255))
            end
            
            local tc = Lerp(s.HoverP, 200, 0)
            draw.SimpleText(b.name, "VChat_Tab", w/2, h/2, Color(tc, tc, tc), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function(s)
            LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
            if b.tab then
                if activeTab == b.tab then
                    activeTab = "ALL"
                else
                    activeTab = b.tab
                end
                VIRTUS_CHAT.RefreshMessages()
            else
                if currentChannel == b.cmd then
                    currentChannel = ""
                else
                    currentChannel = b.cmd
                end
            end
            textEntry:RequestFocus()
        end
    end
    
    btnContainer.PerformLayout = function(self, w, h)
        local count = #btns
        local actualBw = math.min(bw, (w - (count - 1) * spacing) / count)
        local startX = 0
        for i, child in ipairs(self:GetChildren()) do
            child:SetSize(actualBw, h)
            child:SetPos(startX + (i-1)*(actualBw + spacing), 0)
        end
    end

    textEntry = vgui.Create("DTextEntry", inputBg)
    textEntry:Dock(FILL)
    textEntry:DockMargin(4, 0, 4, 0)
    textEntry:SetFont("VChat_Input")
    textEntry:SetTextColor(VIRTUS_CHAT.Colors.InputText)
    textEntry:SetDrawBackground(false)
    textEntry:SetCursorColor(VIRTUS_CHAT.Colors.TabActive)
    textEntry:SetDrawLanguageID(false)
    textEntry:SetHistoryEnabled(false)
    textEntry:SetPlaceholderText("Escribe aquí...")

    textEntry.OnEnter = function(self)
        local txt = self:GetValue()
        local originalTxt = txt
        
        if string.Trim(txt) != "" then
            -- Si estamos en la pestaña OOC, forzar el uso del comando OOC
            if activeTab == "OOC" and not string.StartWith(txt, "/") and not string.StartWith(txt, "//") then
                txt = "// " .. txt
            end
            
            if currentChannel ~= "" and not string.StartWith(txt, "/") and not string.StartWith(txt, "//") then
                txt = currentChannel .. txt
            end

            if VIRTUS_CHAT.IsTeamChat then
                RunConsoleCommand("say_team", txt)
            else
                RunConsoleCommand("say", txt)
            end
            
            if VIRTUS_CHAT.MessageHistory[#VIRTUS_CHAT.MessageHistory] ~= originalTxt then
                table.insert(VIRTUS_CHAT.MessageHistory, originalTxt)
            end
            if #VIRTUS_CHAT.MessageHistory > 50 then table.remove(VIRTUS_CHAT.MessageHistory, 1) end
        end
        VIRTUS_CHAT.HistoryIndex = 0
        self:SetText("")
        chat.Close()
        
        -- Fallback por si chat.Close() no dispara el hook
        isChatOpen = false
        frame:SetMouseInputEnabled(false)
        frame:SetKeyboardInputEnabled(false)
        tabsPanel:SetVisible(false)
        inputBg:SetVisible(false)
        if IsValid(btnContainer) then btnContainer:SetVisible(false) end
        
        if activeTab ~= "ALL" then
            activeTab = "ALL"
            VIRTUS_CHAT.RefreshMessages()
        end
    end
    
    textEntry.OnKeyCodeTyped = function(self, code)
        if code == KEY_ENTER or code == KEY_PAD_ENTER then
            self:OnEnter()
            return true
        elseif code == KEY_ESCAPE then
            chat.Close()
            gui.HideGameUI()
            return true
        elseif code == KEY_UP then
            if #VIRTUS_CHAT.MessageHistory > 0 then
                VIRTUS_CHAT.HistoryIndex = math.Clamp(VIRTUS_CHAT.HistoryIndex + 1, 1, #VIRTUS_CHAT.MessageHistory)
                local msg = VIRTUS_CHAT.MessageHistory[#VIRTUS_CHAT.MessageHistory - VIRTUS_CHAT.HistoryIndex + 1]
                self:SetText(msg)
                self:SetCaretPos(string.len(msg))
            end
            return true
        elseif code == KEY_DOWN then
            if #VIRTUS_CHAT.MessageHistory > 0 then
                VIRTUS_CHAT.HistoryIndex = VIRTUS_CHAT.HistoryIndex - 1
                if VIRTUS_CHAT.HistoryIndex <= 0 then
                    VIRTUS_CHAT.HistoryIndex = 0
                    self:SetText("")
                else
                    local msg = VIRTUS_CHAT.MessageHistory[#VIRTUS_CHAT.MessageHistory - VIRTUS_CHAT.HistoryIndex + 1]
                    self:SetText(msg)
                    self:SetCaretPos(string.len(msg))
                end
            end
            return true
        end
    end

    frame.OnKeyCodePressed = function(self, code)
        if code == KEY_ESCAPE then
            chat.Close()
            gui.HideGameUI()
        end
    end

    frame:SetMouseInputEnabled(false)
    frame:SetKeyboardInputEnabled(false)

    -- Ajustar tamaño del texto al redimensionar la ventana
    frame.PerformLayout = function(self, pw, ph)
        if IsValid(self.lblTitle) then
            self.lblTitle:SetWide(pw - 50)
        end
        tabsPanel:SetSize(pw - 160 - 40, 35)
        tabsPanel:MoveToFront()
        cfgBtn:SetPos(pw - 35, 5)
        cfgBtn:MoveToFront()
        for _, pnl in ipairs(scrollPanel:GetCanvas():GetChildren()) do
            for _, child in ipairs(pnl:GetChildren()) do
                if child:GetClassName() == "Label" and child:GetWrap() then
                    local rx, ry = child:GetPos()
                    child:SetWide(pw - rx - 25)
                end
            end
        end
        
        -- Recalcular las alturas dinámicas
        if IsValid(scrollPanel) then
            scrollPanel:InvalidateLayout(true)
        end
    end
    
    -- Refrescar mensajes que llegaron antes de que el VGUI se creara
    VIRTUS_CHAT.RefreshMessages()
end

hook.Add("InitPostEntity", "VirtusChat_Init", function()
    BuildChatbox()
end)

if IsValid(LocalPlayer()) then
    BuildChatbox()
end

-- Renderizador de un mensaje
local function CreateMessagePanel(msgData)
    local pnl = vgui.Create("DPanel", scrollPanel)
    pnl:Dock(TOP)
    pnl:DockMargin(0, 0, 0, 2)
    
    local timeCreated = CurTime()
    
    pnl.Paint = function(self, pw, ph)
        local alpha = 255
        if not isChatOpen then
            local age = CurTime() - timeCreated
            if age > 10 then
                alpha = math.Clamp(255 - ((age - 10) * 255), 0, 255)
            end
        end
        self:SetAlpha(alpha)

        if alpha == 0 and not isChatOpen then return end

        if isChatOpen and self:IsHovered() then
            draw.RoundedBox(6, 0, 0, pw, ph, Color(255, 255, 255, 8))
        end


        local currentX = 0
        
        -- Dibujar Timestamp
        if msgData.timeStr then
            surface.SetFont("VChat_Time")
            local tw_time, th_time = surface.GetTextSize(msgData.timeStr)
            local timeY = math.floor((20 - th_time) / 2)
            if timeY < 0 then timeY = 0 end
            
            draw.SimpleText(msgData.timeStr, "VChat_Time", currentX, timeY, Color(180, 180, 190, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            -- Dibujar puntito separador custom
            local dotSize = 4
            local dotX = currentX + tw_time + 6 -- Centrado en los 16px de margen
            local dotY = math.floor((20 - dotSize) / 2)
            draw.RoundedBox(dotSize / 2, dotX, dotY, dotSize, dotSize, Color(150, 150, 160, 200))
        end

        if IsValid(msgData.ply) then
            local rankName, rankColor
            if msgData.customRank then
                rankName = msgData.customRank
                rankColor = msgData.customRankColor
            else
                local rn, rc, hg = VIRTUS_CHAT.GetPlayerRankInfo(msgData.ply)
                rankName = rn
                rankColor = rc
            end
            
            if rankName then
                local tagFont = msgData.isAction and "VChat_RankThin" or "VChat_Rank"
                surface.SetFont(tagFont)
                local tw, th = surface.GetTextSize(rankName)
                local boxW = tw + 16
                local boxH = th + 4
                
                -- Calcular el X del tag (después de la hora y el puntito)
                local tagX = currentX
                if msgData.timeStr then
                    surface.SetFont("VChat_Time")
                    local timeW, _ = surface.GetTextSize(msgData.timeStr)
                    tagX = tagX + timeW + 16
                end
                
                -- Centrado vertical perfecto del tag alineado a la primera línea
                local tagY = math.floor((20 - boxH) / 2)
                if tagY < 0 then tagY = 0 end
                
                -- Radio más cuadrado y limpio (evita el pixelado circular)
                local radius = 4
                
                -- Fondo del tag con color (flat y minimalista)
                draw.RoundedBox(radius, tagX, tagY, boxW, boxH, Color(rankColor.r, rankColor.g, rankColor.b, 255))
                
                -- Texto del tag (sin bordes negros molestos, pura legibilidad)
                draw.SimpleText(rankName, tagFont, tagX + 8, tagY + 2, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
        end
    end
    
    pnl._collapsing = false
    pnl._collapseStart = nil
    local collapseDuration = 0.35 -- segundos de animación
    
    pnl.Think = function(self)
        if not isChatOpen then
            local age = CurTime() - timeCreated
            if age > 11 then
                -- Iniciar animación de colapso
                if not self._collapsing and self:GetTall() > 0 then
                    self._collapsing = true
                    self._collapseStart = CurTime()
                end
                
                if self._collapsing then
                    local elapsed = CurTime() - self._collapseStart
                    local frac = math.Clamp(elapsed / collapseDuration, 0, 1)
                    -- Ease out para que sea más suave
                    frac = 1 - (1 - frac) * (1 - frac)
                    local targetH = math.floor(Lerp(frac, self.originalTall or 20, 0))
                    self:SetTall(targetH)
                    
                    if IsValid(scrollPanel) then 
                        local canvas = scrollPanel:GetCanvas()
                        if IsValid(canvas) then 
                            canvas:InvalidateLayout(true) 
                            canvas:SizeToChildren(false, true)
                        end
                        scrollPanel:InvalidateLayout(true) 
                    end
                    
                    if frac >= 1 then
                        self:SetVisible(false)
                        self._collapsing = false
                    end
                end
            end
        else
            if self:GetTall() < (self.originalTall or 20) then
                self._collapsing = false
                self._collapseStart = nil
                self:SetTall(self.originalTall or 20)
                self:SetVisible(true)
                if IsValid(scrollPanel) then 
                    local canvas = scrollPanel:GetCanvas()
                    if IsValid(canvas) then 
                        canvas:InvalidateLayout(true) 
                        canvas:SizeToChildren(false, true)
                    end
                    scrollPanel:InvalidateLayout(true) 
                end
            end
        end
    end

    local xOffset = msgData.tagOffset or 4
    if msgData.wrapLeft then
        xOffset = msgData.timeOffset or 0
    end
    
    local textY = 2
    local minHeight = 20
    local finalHeight = minHeight

    if msgData.isMarkup and msgData.markupObj then
        local mPanel = vgui.Create("DPanel", pnl)
        local mHeight = msgData.markupObj:GetHeight()
        
        -- Si el texto es de una sola línea, lo centramos
        if mHeight < 20 then
            textY = math.floor((minHeight - mHeight) / 2)
        end
        
        mPanel:SetPos(xOffset, textY)
        mPanel:SetSize(frame:GetWide() - xOffset - 10, mHeight + 10)
        mPanel.Paint = function(self, pw, ph)
            if msgData.shadowMarkupObj then
                msgData.shadowMarkupObj:Draw(1, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                msgData.shadowMarkupObj:Draw(0, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
            msgData.markupObj:Draw(0, 0, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        finalHeight = math.max(minHeight, mHeight + (textY * 2))
    else
        -- Pre-tag fallback
        if msgData.prefix then
            surface.SetFont("VChat_MsgBold")
            local preW, _ = surface.GetTextSize(msgData.prefix)
            local preLabel = vgui.Create("DLabel", pnl)
            preLabel:SetFont("VChat_MsgBold")
            preLabel:SetText(msgData.prefix)
            preLabel:SizeToContents()
            preLabel:SetPos(xOffset, textY)
            preLabel:SetTextColor(msgData.prefixColor or Color(255, 255, 255))
            preLabel:SetExpensiveShadow(1, Color(0, 0, 0, 200))
            xOffset = xOffset + preW + 5
        end

        local textLabel = vgui.Create("DLabel", pnl)
        textLabel:SetFont("VChat_Msg")
        textLabel:SetText(msgData.text or "")
        textLabel:SetPos(xOffset, textY)
        textLabel:SetTextColor(msgData.textColor or Color(255, 255, 255))
        textLabel:SetWrap(true)
        textLabel:SetAutoStretchVertical(true)
        textLabel:SetExpensiveShadow(1, Color(0, 0, 0, 200))
        
        local targetWide = 500
        if IsValid(frame) then targetWide = frame:GetWide() end
        textLabel:SetWide(targetWide - xOffset - 10)
        
        timer.Simple(0, function()
            if IsValid(pnl) and IsValid(textLabel) then
                local tH = textLabel:GetTall()
                if tH < 20 then
                    textLabel:SetPos(xOffset, math.floor((minHeight - tH) / 2))
                end
                pnl:SetTall(math.max(minHeight, tH + 4))
            end
        end)
    end

    if msgData.isMarkup then
        pnl:SetTall(finalHeight)
    end
    
    pnl.originalTall = finalHeight
    
    return pnl
end

function VIRTUS_CHAT.RefreshMessages()
    scrollPanel:Clear()
    
    for _, msgData in ipairs(messages[activeTab] or {}) do
        CreateMessagePanel(msgData)
    end
    
    timer.Simple(0.05, function()
        if IsValid(scrollPanel) then
            local canvas = scrollPanel:GetCanvas()
            local y = canvas:GetTall() - scrollPanel:GetTall()
            if y > 0 then
                scrollPanel:GetVBar():AnimateTo(y, 0.2)
            end
        end
    end)
end

local function AddMessage(tab, data)
    table.insert(messages[tab], data)
    if #messages[tab] > 500 then
        table.remove(messages[tab], 1)
        -- Si el panel sobrepasa el límite, podríamos borrar el primer child pero RefreshMessages lo limpia al cambiar de tab.
    end
    
    if activeTab == tab and IsValid(scrollPanel) then
        local pnl = CreateMessagePanel(data)
        timer.Simple(0.05, function()
            if IsValid(scrollPanel) then
                local canvas = scrollPanel:GetCanvas()
                local vbar = scrollPanel:GetVBar()
                local maxScroll = canvas:GetTall() - scrollPanel:GetTall()
                
                -- Permitir leer el historial: Solo hacer autoscroll si el chat está cerrado o si ya estaba abajo
                local isAtBottom = (vbar:GetScroll() >= maxScroll - 60)
                if not isChatOpen or isAtBottom then
                    if maxScroll > 0 then vbar:AnimateTo(maxScroll, 0.2) end
                end
            end
        end)
    end
end

-- ============================================================================
-- HOOKS
-- ============================================================================

hook.Add("StartChat", "VirtusChat_Start", function(isTeamChat)
    isChatOpen = true
    currentChannel = ""
    if activeTab ~= "ALL" then
        activeTab = "ALL"
        VIRTUS_CHAT.RefreshMessages()
    end
    VIRTUS_CHAT.IsTeamChat = isTeamChat
    frame:SetMouseInputEnabled(true)
    frame:SetKeyboardInputEnabled(true)
    frame:MakePopup()
    textEntry:RequestFocus()
    textEntry:SetText("")
    
    tabsPanel:SetVisible(true)
    inputBg:SetVisible(true)
    if IsValid(btnContainer) then btnContainer:SetVisible(true) end
    
    textEntry:RequestFocus()
    
    return true
end)

hook.Add("FinishChat", "VirtusChat_Finish", function()
    isChatOpen = false
    frame:SetMouseInputEnabled(false)
    frame:SetKeyboardInputEnabled(false)
    textEntry:SetText("")
    textEntry:UnselectAll()
    tabsPanel:SetVisible(false)
    inputBg:SetVisible(false)
    if IsValid(btnContainer) then btnContainer:SetVisible(false) end
    
    if activeTab ~= "ALL" then
        activeTab = "ALL"
        VIRTUS_CHAT.RefreshMessages()
    end
    
    -- Guardar tamaño al cerrar
    if IsValid(frame) then
        cookie.Set("VirtusChat_W_v2", tostring(frame:GetWide()))
        cookie.Set("VirtusChat_H_v2", tostring(frame:GetTall()))
    end
end)

hook.Add("GUIMousePressed", "VirtusChat_ClickOutside", function(mouseCode)
    if isChatOpen and mouseCode == MOUSE_LEFT then
        local hovered = vgui.GetHoveredPanel()
        if not IsValid(hovered) or (hovered ~= VIRTUS_CHAT.Frame and not hovered:HasParent(VIRTUS_CHAT.Frame)) then
            local isConfigOpen = (IsValid(VIRTUS_CHAT.ConfigFrame) and VIRTUS_CHAT.ConfigFrame:IsVisible())
            local isRankConfigOpen = (IsValid(VIRTUS_CHAT.RankConfigFrame) and VIRTUS_CHAT.RankConfigFrame:IsVisible())
            
            if not isConfigOpen and not isRankConfigOpen then
                chat.Close()
            end
        end
    end
end)

local LastChatPlayer = nil

hook.Add("OnPlayerChat", "AVirtusChat_GrabPly", function(ply)
    LastChatPlayer = ply
end)

-- Puente de chat.AddText para capturar SAM y DarkRP
    local oldChatAddText = chat.AddText
function chat.AddText(...)
    local args = {...}
    
    local ply = nil
    local markupStr = "<font=VChat_Msg>"
    local curColor = Color(255, 255, 255)
    
    local isOOC = false
    local isPM = false
    local textContent = ""
    local customRank = nil
    local customRankColor = nil
    local isAction = false
    
    for _, v in ipairs(args) do
        if type(v) == "table" and v.customRank then
            customRank = v.customRank
            customRankColor = v.customRankColor or Color(255, 255, 255)
            isAction = v.isAction or false
            if isAction then
                markupStr = string.Replace(markupStr, "<font=VChat_Msg>", "<font=VChat_MsgThin>")
            end
        elseif type(v) == "table" and v.r and v.g and v.b then
            curColor = v
            markupStr = markupStr .. string.format("<color=%d,%d,%d>", v.r, v.g, v.b)
        elseif type(v) == "Player" then
            if not IsValid(ply) then ply = v end
            if isAction then
                markupStr = markupStr .. string.format("<font=VChat_MsgThin><color=%d,%d,%d>%s</color></font>", customRankColor.r, customRankColor.g, customRankColor.b, v:Nick())
                -- Maintain the action color for the rest of the text
                markupStr = markupStr .. string.format("<color=%d,%d,%d>", customRankColor.r, customRankColor.g, customRankColor.b)
            else
                -- Misma fuente que el mensaje y color blanco uniforme (sin color de job)
                markupStr = markupStr .. string.format("<font=VChat_Msg><color=220,220,220>%s</color></font>", v:Nick())
                markupStr = markupStr .. string.format("<color=%d,%d,%d>", curColor.r, curColor.g, curColor.b)
            end
        else
            local str = tostring(v)
            textContent = textContent .. str
            
            str = string.Replace(str, "<", "&lt;")
            str = string.Replace(str, ">", "&gt;")
            markupStr = markupStr .. str
        end
    end
    
    local tl = string.lower(textContent)
    
    local isIvosam = false
    local info = debug.getinfo(2, "S")
    if info and info.short_src and string.find(string.lower(info.short_src), "ivosam") then
        isIvosam = true
    end
    if not isIvosam then
        info = debug.getinfo(3, "S")
        if info and info.short_src and string.find(string.lower(info.short_src), "ivosam") then
            isIvosam = true
        end
    end
    
    if string.StartWith(string.TrimLeft(textContent), "@") or (isIvosam and not string.find(tl, "%[ivosam%]")) then
        markupStr = "<font=VChat_MsgBold><color=255,150,0>|  </color></font>" .. markupStr
    end
    
    if not IsValid(ply) and IsValid(LastChatPlayer) then
        ply = LastChatPlayer
    end
    LastChatPlayer = nil
    
    if isIvosam or not IsValid(ply) then
        markupStr = string.Replace(markupStr, "<font=VChat_Msg>", "<font=VChat_ServerMsg>")
        markupStr = string.Replace(markupStr, "<font=VChat_MsgBold>", "<font=VChat_ServerMsgBold>")
    end
    
    markupStr = markupStr .. "</font>"
    
    if string.find(tl, "%[ooc%]") or string.find(tl, "%(ooc%)") or string.StartWith(tl, "//") then isOOC = true end
    if string.find(tl, "%[pm%]") then isPM = true end
    
    if isOOC and not customRank then
        customRank = "OOC"
        customRankColor = Color(100, 150, 255)
        markupStr = string.gsub(markupStr, "%[OOC%]%s*", "")
        markupStr = string.gsub(markupStr, "%(OOC%)%s*", "")
        markupStr = string.gsub(markupStr, "%[ooc%]%s*", "")
        markupStr = string.gsub(markupStr, "%(ooc%)%s*", "")
        markupStr = string.gsub(markupStr, ">//%s*", ">")
    elseif isPM and not customRank then
        customRank = "PM"
        customRankColor = Color(255, 100, 100)
        markupStr = string.gsub(markupStr, "%[PM%]%s*", "")
        markupStr = string.gsub(markupStr, "%(PM%)%s*", "")
        markupStr = string.gsub(markupStr, "%[pm%]%s*", "")
        markupStr = string.gsub(markupStr, "%(pm%)%s*", "")
    end
    
    local targetWide = 500
    if IsValid(frame) then targetWide = frame:GetWide() end

    -- Calcular hora
    local timeStr = os.date("%H:%M")
    surface.SetFont("VChat_Time")
    local timeW, _ = surface.GetTextSize(timeStr)
    
    local timeOffset = timeW + 16 -- Offset hasta el comienzo del tag
    local tagWidth = 0
    
    if IsValid(ply) then
        local rankName = customRank or VIRTUS_CHAT.GetPlayerRankInfo(ply)
        if rankName then
            surface.SetFont(isAction and "VChat_RankThin" or "VChat_Rank")
            local tw, _ = surface.GetTextSize(rankName)
            tagWidth = tw + 16 + 6
        end
    end
    
    -- El ancho de parseo disponible ahora empieza después de la hora
    local parseWidth = targetWide - timeOffset - 20
    
    surface.SetFont("VChat_Msg")
    local spaceW = surface.GetTextSize(" ")
    -- Solo indentamos el tamaño del tag, porque el panel entero se desplazará por timeOffset
    local numSpaces = math.ceil(tagWidth / spaceW)
    local indentStr = string.rep(" ", numSpaces)
    
    markupStr = "<font=VChat_Msg>" .. indentStr .. "</font>" .. markupStr
    
    local shadowMarkupStr = string.gsub(markupStr, "<color=(%d+),(%d+),(%d+)>", "<color=0,0,0,200>")
    
    local data = {
        isMarkup = true,
        markupObj = markup.Parse(markupStr, parseWidth),
        shadowMarkupObj = markup.Parse(shadowMarkupStr, parseWidth),
        ply = ply,
        customRank = customRank,
        customRankColor = customRankColor,
        isAction = isAction,
        text = textContent,
        tagOffset = timeOffset + tagWidth,
        timeOffset = timeOffset,
        timeStr = timeStr,
        wrapLeft = true
    }
    
    if isOOC then
        AddMessage("OOC", data)
    elseif isPM then
        AddMessage("PM", data)
    end
    AddMessage("ALL", data)
    
    chat.PlaySound()
    oldChatAddText(...)
end

-- Interceptar mensajes normales si no usan chat.AddText
hook.Add("OnPlayerChat", "VirtusChat_OnChat", function(ply, text, bTeamOnly, bPlayerIsDead)
    -- Lo dejamos correr para no bloquear a otros addons. Si otro addon (como DarkRP) 
    -- lo procesa, llamará a chat.AddText y lo capturaremos allí.
    -- Si no, el default chatbox se oculta de todos modos por HUDShouldDraw.
end)

hook.Add("ChatText", "VirtusChat_SysMsg", function(index, name, text, type)
    if type == "joinleave" or type == "none" or type == "server" then
        chat.AddText(Color(255, 255, 255), text)
        return true
    end
end)


