if not CLIENT then return end

-- Usamos fuentes estándar de GMod (Roboto) que están 100% garantizadas en todos los clientes
surface.CreateFont("Datapad_Title", { font = "Roboto", size = 22, weight = 800, antialias = true })
surface.CreateFont("Datapad_SubTitle", { font = "Roboto", size = 18, weight = 600, antialias = true })
surface.CreateFont("Datapad_Text", { font = "Roboto", size = 15, weight = 500, antialias = true })
surface.CreateFont("Datapad_PIN", { font = "Roboto", size = 36, weight = 800, antialias = true })

local KeypadAdminMenu = nil
local KeypadList = {}

-- Helper Blur
local blur = Material("pp/blurscreen")
local function DrawBlur(panel, amount)
    local x, y = panel:LocalToScreen(0, 0)
    local scrW, scrH = ScrW(), ScrH()
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blur)
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * (amount or 6))
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
    end
end

-- =========================================================
-- PIN UI (Interfaz para ingresar el código)
-- =========================================================
local PINMenu = nil
net.Receive("Datapad_OpenPINUI", function()
    local keypad = net.ReadEntity()
    if not IsValid(keypad) then return end
    if IsValid(PINMenu) then PINMenu:Remove() end
    
    local isHacker = false
    local ply = LocalPlayer()
    if Datapad and Datapad.HasAccess and Datapad:HasAccess(ply, Datapad.Config.HackerJobs) then
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_ivo_datapad" then
            isHacker = true
        end
    end
    
    local w, h = 320, 480
    if isHacker then h = 540 end
    
    PINMenu = vgui.Create("DFrame")
    PINMenu:SetSize(w, h)
    PINMenu:Center()
    PINMenu:SetTitle("")
    PINMenu:MakePopup()
    PINMenu:ShowCloseButton(false)
    
    local currentPIN = ""
    
    PINMenu.Paint = function(s, w, h)
        DrawBlur(s, 6)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 35, 240))
        surface.SetDrawColor(50, 150, 255, 150)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        draw.SimpleText("ACCESO DE SEGURIDAD", "Datapad_Title", w/2, 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        
        -- Pantalla del PIN
        draw.RoundedBox(4, 25, 60, w - 50, 60, Color(15, 15, 18, 255))
        surface.SetDrawColor(50, 150, 255, 50)
        surface.DrawOutlinedRect(25, 60, w - 50, 60, 1)
        
        local displayStr = ""
        for i=1, #currentPIN do displayStr = displayStr .. "*" end
        if currentPIN == "" then displayStr = "INGRESE PIN" end
        
        draw.SimpleText(displayStr, "Datapad_PIN", w/2, 60 + 30, currentPIN == "" and Color(100, 100, 100) or Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    local closeBtn = vgui.Create("DButton", PINMenu)
    closeBtn:SetSize(30, 30)
    closeBtn:SetPos(w - 35, 10)
    closeBtn:SetText("✕")
    closeBtn:SetFont("Datapad_Title")
    closeBtn:SetTextColor(color_white)
    closeBtn.Paint = function(s, w, h)
        if s:IsHovered() then draw.RoundedBox(4, 0, 0, w, h, Color(200, 50, 50)) end
    end
    closeBtn.DoClick = function() PINMenu:Remove() end
    
    local padLayout = vgui.Create("DIconLayout", PINMenu)
    padLayout:SetPos(35, 140)
    padLayout:SetSize(250, 260)
    padLayout:SetSpaceX(10)
    padLayout:SetSpaceY(10)
    
    local keys = {"1","2","3","4","5","6","7","8","9","C","0","OK"}
    for _, k in ipairs(keys) do
        local btn = padLayout:Add("DButton")
        btn:SetSize(76, 76)
        btn:SetText(k)
        btn:SetFont("Datapad_PIN")
        btn:SetTextColor(color_white)
        btn.Paint = function(s, bw, bh)
            local bg = Color(50, 55, 60, 255)
            if k == "OK" then bg = Color(0, 120, 50, 255) end
            if k == "C" then bg = Color(150, 40, 40, 255) end
            if s:IsHovered() then bg.r = bg.r + 30; bg.g = bg.g + 30; bg.b = bg.b + 30 end
            if s:IsDown() then bg.r = bg.r - 20; bg.g = bg.g - 20; bg.b = bg.b - 20 end
            draw.RoundedBox(8, 0, 0, bw, bh, bg)
        end
        btn.DoClick = function()
            surface.PlaySound("buttons/lightswitch2.wav")
            if k == "C" then
                currentPIN = ""
            elseif k == "OK" then
                net.Start("Datapad_SubmitPIN")
                net.WriteEntity(keypad)
                net.WriteString(currentPIN)
                net.SendToServer()
                PINMenu:Remove()
            else
                if #currentPIN < 10 then
                    currentPIN = currentPIN .. k
                end
            end
        end
    end
    
    if isHacker then
        local hackBtn = vgui.Create("DButton", PINMenu)
        hackBtn:SetSize(w - 50, 40)
        hackBtn:SetPos(25, 480)
        hackBtn:SetText("VULNERAR SISTEMA")
        hackBtn:SetFont("Datapad_SubTitle")
        hackBtn:SetTextColor(color_white)
        hackBtn.Paint = function(s, bw, bh)
            draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and Color(200, 120, 0) or Color(160, 80, 0, 255))
        end
        hackBtn.DoClick = function()
            net.Start("Datapad_RequestKeypadHack")
            net.WriteEntity(keypad)
            net.SendToServer()
            PINMenu:Remove()
        end
    end
end)

-- =========================================================
-- ADMIN UI - REESCRITO DE CERO
-- =========================================================

local function CreateToggleSwitch(parent, label, defaultVal, activeColor)
    local panel = vgui.Create("DPanel", parent)
    panel:SetTall(40)
    panel:Dock(TOP)
    panel:DockMargin(0, 0, 0, 8)
    panel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(25, 25, 30, 255))
    end
    
    local lbl = vgui.Create("DLabel", panel)
    lbl:SetText(label)
    lbl:SetFont("Datapad_Text")
    lbl:SetTextColor(color_white)
    lbl:Dock(LEFT)
    lbl:DockMargin(15, 0, 0, 0)
    lbl:SizeToContents()
    
    local btn = vgui.Create("DButton", panel)
    btn:SetText("")
    btn:SetSize(60, 24)
    btn:Dock(RIGHT)
    btn:DockMargin(0, 8, 15, 8)
    
    btn.Checked = defaultVal
    local animPos = defaultVal and 1 or 0
    
    btn.Paint = function(self, w, h)
        animPos = Lerp(FrameTime() * 12, animPos, self.Checked and 1 or 0)
        
        local bgCol = Color(70, 70, 75)
        local onCol = activeColor or Color(0, 150, 255)
        
        local currentR = Lerp(animPos, bgCol.r, onCol.r)
        local currentG = Lerp(animPos, bgCol.g, onCol.g)
        local currentB = Lerp(animPos, bgCol.b, onCol.b)
        
        draw.RoundedBox(12, 0, 0, w, h, Color(currentR, currentG, currentB))
        
        local circleX = Lerp(animPos, 2, w - 20 - 2)
        draw.RoundedBox(10, circleX, 2, 20, 20, color_white)
    end
    
    btn.DoClick = function(self)
        self.Checked = not self.Checked
    end
    
    panel.GetChecked = function() return btn.Checked end
    panel.SetChecked = function(self, val) btn.Checked = val end
    return panel
end

local function RefreshAdminUI()
    if IsValid(KeypadAdminMenu) then KeypadAdminMenu:Remove() end
    
    local w, h = 850, 600
    KeypadAdminMenu = vgui.Create("DFrame")
    KeypadAdminMenu:SetSize(w, h)
    KeypadAdminMenu:Center()
    KeypadAdminMenu:SetTitle("")
    KeypadAdminMenu:MakePopup()
    
    KeypadAdminMenu.Paint = function(s, w, h)
        DrawBlur(s, 5)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 25, 240))
        surface.SetDrawColor(0, 100, 200, 100)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        -- Header Line
        surface.SetDrawColor(0, 150, 255, 255)
        surface.DrawRect(0, 0, w, 4)
        
        draw.SimpleText("SISTEMA DE GESTIÓN DE KEYPADS", "Datapad_Title", 20, 15, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    local closeBtn = vgui.Create("DButton", KeypadAdminMenu)
    closeBtn:SetSize(40, 40)
    closeBtn:SetPos(w - 40, 5)
    closeBtn:SetText("✕")
    closeBtn:SetFont("Datapad_Title")
    closeBtn:SetTextColor(color_white)
    closeBtn.Paint = function(s, bw, bh)
        if s:IsHovered() then draw.RoundedBox(4, 0, 0, bw, bh, Color(200, 50, 50)) end
    end
    closeBtn.DoClick = function() KeypadAdminMenu:Remove() end
    
    -- Left Panel (Lista)
    local leftPanel = vgui.Create("DPanel", KeypadAdminMenu)
    leftPanel:SetPos(15, 55)
    leftPanel:SetSize(260, h - 70)
    leftPanel.Paint = function(s, pw, ph)
        draw.RoundedBox(4, 0, 0, pw, ph, Color(15, 15, 18, 200))
    end
    
    local btnSpawn = vgui.Create("DButton", leftPanel)
    btnSpawn:Dock(BOTTOM)
    btnSpawn:SetTall(40)
    btnSpawn:DockMargin(5, 5, 5, 5)
    btnSpawn:SetText("CREAR NUEVO AQUÍ")
    btnSpawn:SetFont("Datapad_SubTitle")
    btnSpawn:SetTextColor(color_white)
    btnSpawn.Paint = function(s, bw, bh)
        draw.RoundedBox(4, 0, 0, bw, bh, s:IsHovered() and Color(0, 120, 200) or Color(0, 90, 150))
    end
    btnSpawn.DoClick = function()
        net.Start("Datapad_KeypadManager_Create")
        net.SendToServer()
    end
    
    local scroll = vgui.Create("DScrollPanel", leftPanel)
    scroll:Dock(FILL)
    scroll:DockMargin(5, 5, 5, 5)
    local sbar1 = scroll:GetVBar()
    sbar1:SetWide(4)
    sbar1.Paint = function() end
    sbar1.btnUp.Paint = function() end
    sbar1.btnDown.Paint = function() end
    sbar1.btnGrip.Paint = function(s, bw, bh) draw.RoundedBox(2, 0, 0, bw, bh, Color(100, 100, 100)) end
    
    local rightPanel = vgui.Create("DPanel", KeypadAdminMenu)
    rightPanel:SetPos(285, 55)
    rightPanel:SetSize(w - 300, h - 70)
    rightPanel.Paint = function(s, pw, ph)
        draw.RoundedBox(4, 0, 0, pw, ph, Color(15, 15, 18, 200))
    end
    
    local selectedKeypad = nil
    
    local function LoadRightPanel(k)
        rightPanel:Clear()
        if not k then return end
        
        local rw, rh = rightPanel:GetSize()
        
        local rightScroll = vgui.Create("DScrollPanel", rightPanel)
        rightScroll:Dock(FILL)
        rightScroll:DockMargin(15, 15, 15, 60)
        local sbar2 = rightScroll:GetVBar()
        sbar2:SetWide(6)
        sbar2.Paint = function() end
        sbar2.btnUp.Paint = function() end
        sbar2.btnDown.Paint = function() end
        sbar2.btnGrip.Paint = function(s, bw, bh) draw.RoundedBox(3, 0, 0, bw, bh, Color(0, 150, 255)) end
        
        local function AddHeader(text)
            local lbl = vgui.Create("DLabel", rightScroll)
            lbl:SetText(text)
            lbl:SetFont("Datapad_SubTitle")
            lbl:SetTextColor(Color(0, 150, 255))
            lbl:Dock(TOP)
            lbl:DockMargin(0, 10, 0, 5)
            lbl:SizeToContents()
        end
        
        local function AddInput(text)
            local txt = vgui.Create("DTextEntry", rightScroll)
            txt:SetTall(35)
            txt:Dock(TOP)
            txt:DockMargin(0, 0, 0, 10)
            txt:SetFont("Datapad_Text")
            txt:SetText(text)
            txt:SetTextColor(color_white)
            txt:SetDrawLanguageID(false)
            txt.Paint = function(s, tw, th)
                draw.RoundedBox(4, 0, 0, tw, th, Color(30, 30, 35))
                surface.SetDrawColor(0, 150, 255, 50)
                surface.DrawOutlinedRect(0, 0, tw, th, 1)
                s:DrawTextEntryText(color_white, Color(0, 150, 255), color_white)
            end
            return txt
        end
        
        local idLabel = vgui.Create("DLabel", rightScroll)
        idLabel:SetText("KEYPAD ID: #" .. k.id)
        idLabel:SetFont("Datapad_Title")
        idLabel:SetTextColor(color_white)
        idLabel:Dock(TOP)
        idLabel:DockMargin(0, 0, 0, 15)
        idLabel:SizeToContents()
        
        AddHeader("MODELO DE LA ENTIDAD")
        local txtModel = AddInput(k.model)
        
        AddHeader("TIPO DE KEYPAD")
        local switchType = CreateToggleSwitch(rightScroll, "Modo: Identificación Personal (OFF) / Código PIN (ON)", k.keypad_type == 1, Color(0, 200, 100))
        
        AddHeader("CÓDIGO PIN (Para Modo PIN)")
        local txtPass = AddInput(k.password)
        
        AddHeader("NIVEL DE ACCESO REQUERIDO (0 a 5)")
        local pnlAccess = vgui.Create("DPanel", rightScroll)
        pnlAccess:SetTall(40)
        pnlAccess:Dock(TOP)
        pnlAccess:DockMargin(0, 0, 0, 10)
        pnlAccess.Paint = function(s, pw, ph) draw.RoundedBox(4, 0, 0, pw, ph, Color(25, 25, 30)) end
        
        local sldAccess = vgui.Create("DNumSlider", pnlAccess)
        sldAccess:Dock(FILL)
        sldAccess:DockMargin(15, 0, 15, 0)
        sldAccess:SetText("Nivel Imperial:")
        sldAccess.Label:SetFont("Datapad_Text")
        sldAccess.Label:SetTextColor(color_white)
        sldAccess:SetMin(0)
        sldAccess:SetMax(5)
        sldAccess:SetDecimals(0)
        sldAccess:SetValue(k.access_level or 0)
        
        AddHeader("EXCEPCIONES DE TRABAJO (Nombres separados por comas)")
        local txtJobs = AddInput(k.access_jobs)
        
        AddHeader("DIFICULTAD DE HACKEO")
        local pnlDiff = vgui.Create("DPanel", rightScroll)
        pnlDiff:SetTall(40)
        pnlDiff:Dock(TOP)
        pnlDiff:DockMargin(0, 0, 0, 10)
        pnlDiff.Paint = function(s, pw, ph) draw.RoundedBox(4, 0, 0, pw, ph, Color(25, 25, 30)) end
        
        local sldDiff = vgui.Create("DNumSlider", pnlDiff)
        sldDiff:Dock(FILL)
        sldDiff:DockMargin(15, 0, 15, 0)
        sldDiff:SetText("Nivel de Seguridad:")
        sldDiff.Label:SetFont("Datapad_Text")
        sldDiff.Label:SetTextColor(color_white)
        sldDiff:SetMin(1)
        sldDiff:SetMax(5)
        sldDiff:SetDecimals(0)
        sldDiff:SetValue(k.difficulty or 1)
        
        AddHeader("MINIJUEGOS DE HACKEO PERMITIDOS")
        local cGames = k.games or "1,2,3"
        local dict = {}
        for _, v in ipairs(string.Explode(",", cGames)) do dict[string.Trim(v)] = true end
        
        local sw1 = CreateToggleSwitch(rightScroll, "Inyección de Datos (Fuerza Bruta)", dict["1"], Color(200, 100, 0))
        local sw2 = CreateToggleSwitch(rightScroll, "Puertos de Red (Circuitos)", dict["2"], Color(200, 100, 0))
        local sw3 = CreateToggleSwitch(rightScroll, "Frecuencias (Voltaje)", dict["3"], Color(200, 100, 0))
        
        AddHeader("PUERTAS VINCULADAS (MapCreationID)")
        local doorsPanel = vgui.Create("DPanel", rightScroll)
        doorsPanel:SetTall(35)
        doorsPanel:Dock(TOP)
        doorsPanel:DockMargin(0, 0, 0, 15)
        doorsPanel.Paint = function() end
        
        local txtDoors = vgui.Create("DTextEntry", doorsPanel)
        txtDoors:Dock(FILL)
        txtDoors:SetFont("Datapad_Text")
        txtDoors:SetText(k.doors)
        txtDoors:SetTextColor(color_white)
        txtDoors.Paint = function(s, tw, th)
            draw.RoundedBox(4, 0, 0, tw, th, Color(30, 30, 35))
            surface.SetDrawColor(0, 150, 255, 50)
            surface.DrawOutlinedRect(0, 0, tw, th, 1)
            s:DrawTextEntryText(color_white, Color(0, 150, 255), color_white)
        end
        
        local btnLink = vgui.Create("DButton", doorsPanel)
        btnLink:Dock(RIGHT)
        btnLink:SetWide(160)
        btnLink:DockMargin(10, 0, 0, 0)
        btnLink:SetText("VINCULAR APUNTADA")
        btnLink:SetFont("Datapad_Text")
        btnLink:SetTextColor(color_white)
        btnLink.Paint = function(s, bw, bh)
            draw.RoundedBox(4, 0, 0, bw, bh, s:IsHovered() and Color(0, 120, 200) or Color(0, 90, 150))
        end
        btnLink.DoClick = function()
            local ply = LocalPlayer()
            local tr = ply:GetEyeTrace()
            if IsValid(tr.Entity) and string.find(tr.Entity:GetClass(), "door") then
                local mapID = tr.Entity:MapCreationID()
                if mapID and mapID ~= -1 then
                    local current = txtDoors:GetValue()
                    txtDoors:SetValue(current == "" and tostring(mapID) or current .. "," .. mapID)
                    surface.PlaySound("buttons/blip1.wav")
                else
                    ply:ChatPrint("Esa puerta no tiene MapCreationID (fue spawneada manualmente).")
                end
            else
                ply:ChatPrint("No estás apuntando a una puerta.")
            end
        end
        
        -- Guardar
        local btnSave = vgui.Create("DButton", rightPanel)
        btnSave:SetSize(rw - 30, 45)
        btnSave:SetPos(15, rh - 55)
        btnSave:SetText("GUARDAR Y APLICAR CAMBIOS AL KEYPAD")
        btnSave:SetFont("Datapad_SubTitle")
        btnSave:SetTextColor(color_white)
        btnSave.Paint = function(s, bw, bh)
            draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and Color(0, 160, 80) or Color(0, 120, 60))
        end
        btnSave.DoClick = function()
            local glist = {}
            if sw1:GetChecked() then table.insert(glist, "1") end
            if sw2:GetChecked() then table.insert(glist, "2") end
            if sw3:GetChecked() then table.insert(glist, "3") end
            local gStr = table.concat(glist, ",")
            if gStr == "" then gStr = "1,2,3" end
            
            net.Start("Datapad_KeypadManager_Update")
            net.WriteUInt(k.id, 32)
            net.WriteString(txtModel:GetValue())
            net.WriteUInt(switchType:GetChecked() and 1 or 0, 4)
            net.WriteString(txtPass:GetValue())
            net.WriteString(txtJobs:GetValue())
            net.WriteUInt(math.Round(sldAccess:GetValue()), 4)
            net.WriteUInt(math.Round(sldDiff:GetValue()), 16)
            net.WriteString(gStr)
            net.WriteString(txtDoors:GetValue())
            net.SendToServer()
        end
    end
    
    local function CreateRow(k)
        local row = scroll:Add("DPanel")
        row:SetTall(50)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 5)
        row.Paint = function(s, pw, ph)
            local isSel = (selectedKeypad == k)
            draw.RoundedBox(4, 0, 0, pw, ph, isSel and Color(0, 100, 200, 80) or Color(30, 30, 35, 255))
            if isSel then
                surface.SetDrawColor(0, 150, 255, 255)
                surface.DrawRect(0, 0, 4, ph)
            end
            
            draw.SimpleText("Terminal #" .. k.id, "Datapad_SubTitle", 15, 8, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            local dist = math.Round(LocalPlayer():GetPos():Distance(k.pos))
            draw.SimpleText("Distancia: " .. dist .. "u", "Datapad_Text", 15, 28, Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        
        local btnSelect = vgui.Create("DButton", row)
        btnSelect:SetSize(160, 50)
        btnSelect:SetPos(0, 0)
        btnSelect:SetText("")
        btnSelect.Paint = function() end
        btnSelect.DoClick = function()
            selectedKeypad = k
            LoadRightPanel(k)
        end
        
        local btnTP = vgui.Create("DButton", row)
        btnTP:SetSize(30, 30)
        btnTP:SetPos(170, 10)
        btnTP:SetText("TP")
        btnTP:SetTextColor(color_white)
        btnTP.Paint = function(s, bw, bh) draw.RoundedBox(4, 0, 0, bw, bh, Color(0, 100, 200)) end
        btnTP.DoClick = function()
            RunConsoleCommand("ulx", "teleport", LocalPlayer():Nick(), tostring(k.pos.x) .. "," .. tostring(k.pos.y) .. "," .. tostring(k.pos.z))
        end
        
        local btnDel = vgui.Create("DButton", row)
        btnDel:SetSize(30, 30)
        btnDel:SetPos(205, 10)
        btnDel:SetText("X")
        btnDel:SetTextColor(color_white)
        btnDel.Paint = function(s, bw, bh) draw.RoundedBox(4, 0, 0, bw, bh, Color(200, 50, 50)) end
        btnDel.DoClick = function()
            net.Start("Datapad_KeypadManager_Delete")
            net.WriteUInt(k.id, 32)
            net.SendToServer()
        end
    end
    
    for _, k in ipairs(KeypadList) do
        CreateRow(k)
    end
end

net.Receive("Datapad_KeypadManager_Open", function()
    local count = net.ReadUInt(16)
    KeypadList = {}
    for i = 1, count do
        table.insert(KeypadList, {
            id = net.ReadUInt(32),
            pos = net.ReadVector(),
            ang = net.ReadAngle(),
            model = net.ReadString(),
            keypad_type = net.ReadUInt(4),
            password = net.ReadString(),
            access_jobs = net.ReadString(),
            access_level = net.ReadUInt(4),
            difficulty = net.ReadUInt(16),
            games = net.ReadString(),
            doors = net.ReadString()
        })
    end
    
    RefreshAdminUI()
end)
