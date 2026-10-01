net.Receive("IvoCitadel_OpenMenu", function()
    local boundCitadel = net.ReadString()
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 500)
    frame:Center()
    frame:SetTitle("Consola de Gestión de Ciudadela")
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 240))
        draw.RoundedBox(4, 0, 0, w, 25, Color(10, 10, 10, 255))
    end

    if IvoCitadel.Active then
        local lbl = vgui.Create("DLabel", frame)
        lbl:SetText("¡Ciudadela [" .. IvoCitadel.ActiveCitadelName .. "] en curso!")
        lbl:SetFont("DermaLarge")
        lbl:SizeToContents()
        lbl:SetPos(600/2 - lbl:GetWide()/2, 100)
        lbl:SetTextColor(Color(255, 50, 50))
        
        local btnCam = vgui.Create("DButton", frame)
        btnCam:SetSize(250, 50)
        btnCam:SetPos(175, 200)
        btnCam:SetText("Activar Cámara de Comandante")
        btnCam:SetFont("Trebuchet24")
        btnCam.DoClick = function()
            net.Start("IvoCitadel_ToggleFreecam")
            net.WriteBool(true)
            net.SendToServer()
            frame:Close()
        end
        return
    end

    local lblTarget = vgui.Create("DLabel", frame)
    lblTarget:SetText("Objetivo Asignado:")
    lblTarget:SetPos(15, 35)
    lblTarget:SetFont("Trebuchet24")
    lblTarget:SizeToContents()

    local comboCitadel = vgui.Create("DComboBox", frame)
    comboCitadel:SetPos(200, 35)
    comboCitadel:SetSize(380, 25)
    
    local hasCitadels = false
    if IvoCitadel.Zones then
        for name, data in pairs(IvoCitadel.Zones) do
            comboCitadel:AddChoice(name)
            hasCitadels = true
        end
    end

    if hasCitadels then
        if boundCitadel and boundCitadel ~= "" and IvoCitadel.Zones[boundCitadel] then
            comboCitadel:SetValue(boundCitadel)
        else
            comboCitadel:ChooseOptionID(1)
        end
    else
        comboCitadel:SetValue("No hay ciudadelas configuradas.")
    end

    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:SetPos(10, 70)
    sheet:SetSize(580, 360)
    
    -- PESTAÑA: PREDEFINIDAS
    local panelPre = vgui.Create("DPanel", sheet)
    panelPre.Paint = function() end
    sheet:AddSheet("Predefinidas", panelPre, "icon16/shield.png")

    local scrollPre = vgui.Create("DScrollPanel", panelPre)
    scrollPre:Dock(FILL)
    scrollPre:DockMargin(10, 10, 10, 10)

    for k, v in ipairs(IvoCitadel.Config.Predefined) do
        local btn = vgui.Create("DButton", scrollPre)
        btn:SetText(v.name)
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, 10)
        btn:SetTall(40)
        btn.DoClick = function()
            local target = comboCitadel:GetValue()
            if target == "Selecciona una ciudadela..." or not IvoCitadel.Zones[target] then
                chat.AddText(Color(255,0,0), "Selecciona una ciudadela válida primero.")
                return
            end

            net.Start("IvoCitadel_StartPredefined")
            net.WriteString(target)
            net.WriteUInt(k, 8)
            net.SendToServer()
            frame:Close()
        end
    end

    -- PESTAÑA: PERSONALIZADA
    local panelCustom = vgui.Create("DPanel", sheet)
    panelCustom.Paint = function() end
    sheet:AddSheet("Personalizada", panelCustom, "icon16/cog.png")

    local scrollCustom = vgui.Create("DScrollPanel", panelCustom)
    scrollCustom:Dock(FILL)
    scrollCustom:DockMargin(10, 10, 10, 50)

    local customSelection = {}
    
    for _, droid in ipairs(IvoCitadel.Config.AvailableDroids) do
        customSelection[droid.class] = 0

        local pnl = vgui.Create("DPanel", scrollCustom)
        pnl:Dock(TOP)
        pnl:DockMargin(0,0,0,5)
        pnl:SetTall(35)
        pnl.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(50,50,50,255))
            draw.SimpleText(droid.name, "DermaDefaultBold", 10, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local wang = vgui.Create("DNumberWang", pnl)
        wang:SetSize(50, 25)
        wang:SetPos(480, 5)
        wang:SetMinMax(0, 50)
        wang:SetValue(0)
        wang.OnValueChanged = function(self, val)
            customSelection[droid.class] = math.Round(tonumber(val) or 0)
        end
    end

    local btnStartCustom = vgui.Create("DButton", panelCustom)
    btnStartCustom:SetSize(200, 35)
    btnStartCustom:SetPos(190, 280)
    btnStartCustom:SetText("Iniciar Personalizada")
    btnStartCustom.DoClick = function()
        local target = comboCitadel:GetValue()
        if target == "Selecciona una ciudadela..." or not IvoCitadel.Zones[target] then
            chat.AddText(Color(255,0,0), "Selecciona una ciudadela válida primero.")
            return
        end

        net.Start("IvoCitadel_StartCustom")
        net.WriteString(target)
        
        local count = 0
        for class, amount in pairs(customSelection) do
            if amount > 0 then count = count + 1 end
        end
        
        net.WriteUInt(count, 8)
        for class, amount in pairs(customSelection) do
            if amount > 0 then
                net.WriteString(class)
                net.WriteUInt(amount, 8)
            end
        end

        net.SendToServer()
        frame:Close()
    end
    
    -- Botón de cámara (incluso si no ha iniciado)
    local btnCam2 = vgui.Create("DButton", frame)
    btnCam2:SetSize(580, 40)
    btnCam2:SetPos(10, 440)
    btnCam2:SetText("Entrar a Cámara de Comandante")
    btnCam2:SetFont("Trebuchet24")
    btnCam2.DoClick = function()
        net.Start("IvoCitadel_ToggleFreecam")
        net.WriteBool(true)
        net.SendToServer()
        frame:Close()
    end
end)
