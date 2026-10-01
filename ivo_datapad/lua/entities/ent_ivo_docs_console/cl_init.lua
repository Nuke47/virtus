include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos() + Vector(0, 0, 45)
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    
    local dist = LocalPlayer():GetPos():Distance(self:GetPos())
    if dist > 400 then return end
    
    local alphaFade = math.Clamp(1 - (dist / 400), 0, 1)
    local pulse = math.abs(math.sin(CurTime() * 2)) * 30
    local isDownloading = self:GetIsDownloading()
    
    -- Colores Base (Imperial / Star Wars style)
    local colBg = Color(5, 10, 15, 220 * alphaFade)
    local colBorder = isDownloading and Color(255, 100, 0, (150 + pulse) * alphaFade) or Color(0, 150, 255, (100 + pulse) * alphaFade)
    local colTextMain = isDownloading and Color(255, 150, 50, 255 * alphaFade) or Color(200, 230, 255, 255 * alphaFade)
    local colTextSec = Color(100, 150, 200, 200 * alphaFade)
    
    cam.Start3D2D(pos, ang, 0.08)
        cam.IgnoreZ(true)
        
        -- Fondo principal estilo "panel de datos"
        draw.RoundedBox(0, -220, -70, 440, 140, colBg)
        
        -- Bordes superior e inferior gruesos
        surface.SetDrawColor(colBorder)
        surface.DrawRect(-220, -70, 440, 4)
        surface.DrawRect(-220, 66, 440, 4)
        
        -- Esquinas estilo Sci-Fi
        local cornerSize = 15
        local thick = 3
        -- Arriba Izquierda
        surface.DrawRect(-225, -75, cornerSize, thick)
        surface.DrawRect(-225, -75, thick, cornerSize)
        -- Arriba Derecha
        surface.DrawRect(225 - cornerSize, -75, cornerSize, thick)
        surface.DrawRect(225 - thick, -75, thick, cornerSize)
        -- Abajo Izquierda
        surface.DrawRect(-225, 75 - thick, cornerSize, thick)
        surface.DrawRect(-225, 75 - cornerSize, thick, cornerSize)
        -- Abajo Derecha
        surface.DrawRect(225 - cornerSize, 75 - thick, cornerSize, thick)
        surface.DrawRect(225 - thick, 75 - cornerSize, thick, cornerSize)
        
        if isDownloading then
            -- Estado: Extrayendo / Hackeado
            local timeLeft = math.max(0, self:GetDownloadEndTime() - CurTime())
            local totalTime = math.max(1, self:GetDownloadTime() or 15)
            local progress = math.Clamp(1 - (timeLeft / totalTime), 0, 1)
            
            if timeLeft > 0 then
                draw.SimpleText("SISTEMA COMPROMETIDO", "Datapad_Title", 0, -40, Color(255, 50, 50, 255 * alphaFade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("EXTRAYENDO ARCHIVOS DE DATOS...", "Datapad_Text", 0, -15, colTextMain, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                
                -- Barra de progreso Sci-Fi
                local barW = 380
                local barH = 12
                surface.SetDrawColor(30, 10, 0, 200 * alphaFade)
                surface.DrawRect(-(barW/2), 10, barW, barH)
                
                surface.SetDrawColor(255, 100, 0, 255 * alphaFade)
                surface.DrawRect(-(barW/2), 10, barW * progress, barH)
                
                -- Cuadricula en la barra (Efecto tecnológico)
                surface.SetDrawColor(5, 10, 15, 150 * alphaFade)
                for i=1, 20 do
                    surface.DrawRect(-(barW/2) + (barW/20)*i, 10, 2, barH)
                end
                
                draw.SimpleText(string.format("T.R. %02d SECS", math.ceil(timeLeft)), "Datapad_Text", 0, 40, colBorder, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                draw.SimpleText("EXTRACCIÓN COMPLETADA", "Datapad_Title", 0, -20, Color(0, 255, 150, 255 * alphaFade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("ESPERANDO RECUPERACIÓN MANUAL...", "Datapad_Text", 0, 20, colTextSec, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        else
            -- Estado: Reposo
            draw.SimpleText("TERMINAL DE DATOS IMPERIAL", "Datapad_Title", 0, -25, colTextMain, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            surface.SetDrawColor(colBorder)
            surface.DrawLine(-150, -5, 150, -5)
            
            local access = self:GetAccessJobs()
            if access == "" then
                draw.SimpleText("// ESTADO: EN LÍNEA (PÚBLICO)", "Datapad_Text", 0, 20, Color(100, 255, 150, 255 * alphaFade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                draw.SimpleText("// ESTADO: EN LÍNEA (RESTRINGIDO)", "Datapad_Text", 0, 20, colBorder, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            -- Líneas de escaneo decorativas
            if math.random(1, 10) > 8 then
                surface.SetDrawColor(colBorder.r, colBorder.g, colBorder.b, math.random(20, 50) * alphaFade)
                local scanY = math.random(-65, 60)
                surface.DrawRect(-215, scanY, 430, 2)
            end
        end
        cam.IgnoreZ(false)
    cam.End3D2D()
end

-- Propiedades del Context Menu (Tecla C) para Admins
properties.Add("ivo_docs_console_edit", {
    MenuLabel = "Configurar Terminal",
    Order = 900,
    MenuIcon = "icon16/cog.png",

    Filter = function(self, ent, ply)
        if not IsValid(ent) or ent:GetClass() ~= "ent_ivo_docs_console" then return false end
        if not ply:IsSuperAdmin() then return false end
        return true
    end,

    Action = function(self, ent)
        IVO_Docs_OpenAdminConfig(ent)
    end
})

-- Función global para que se pueda llamar también desde cl_ivo_docs_ui.lua
function IVO_Docs_OpenAdminConfig(ent)
    if not IsValid(ent) then return end
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(500, 650)
    frame:SetTitle("")
    frame:Center()
    frame:MakePopup()
    
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
    
    frame.Paint = function(self, w, h)
        DrawBlur(self, 4)
        draw.RoundedBox(12, 0, 0, w, h, Color(15, 20, 25, 220))
        surface.SetDrawColor(0, 150, 255, 50)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        draw.SimpleText("CONFIGURACIÓN DE TERMINAL", "Datapad_Title", 20, 15, Color(0, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(0, 200, 255, 100)
        surface.DrawLine(20, 45, w - 20, 45)
    end
    
    -- Función auxiliar para crear Switches
    local function CreateSwitch(parent, label, defaultVal, isPublicSwitch)
        local panel = vgui.Create("DPanel", parent)
        panel:SetTall(35)
        panel:Dock(TOP)
        panel:DockMargin(0, 0, 0, 5)
        panel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(0, 0, 0, 100))
        end
        
        local lbl = vgui.Create("DLabel", panel)
        lbl:SetText(label)
        lbl:SetFont("Datapad_Text")
        if isPublicSwitch then
            lbl:SetTextColor(Color(255, 200, 50))
        else
            lbl:SetTextColor(Color(200, 200, 200))
        end
        lbl:Dock(LEFT)
        lbl:DockMargin(10, 0, 0, 0)
        lbl:SizeToContents()
        
        local btnSwitch = vgui.Create("DButton", panel)
        btnSwitch:SetText("")
        btnSwitch:SetSize(50, 20)
        btnSwitch:Dock(RIGHT)
        btnSwitch:DockMargin(0, 7, 10, 8)
        
        btnSwitch.Checked = defaultVal
        local animTarget = defaultVal and 1 or 0
        local animCurrent = animTarget
        
        btnSwitch.Paint = function(self, w, h)
            -- Interpolar animación
            animCurrent = Lerp(FrameTime() * 10, animCurrent, animTarget)
            
            -- Dibujar fondo de píldora
            local r, g, b = 100, 100, 100
            if isPublicSwitch then
                r, g, b = Lerp(animCurrent, 100, 255), Lerp(animCurrent, 100, 150), Lerp(animCurrent, 100, 50)
            else
                r, g, b = Lerp(animCurrent, 100, 0), Lerp(animCurrent, 100, 150), Lerp(animCurrent, 100, 255)
            end
            
            draw.RoundedBox(10, 0, 0, w, h, Color(r, g, b, self:IsEnabled() and 255 or 100))
            
            -- Dibujar bolita blanca
            local circleX = Lerp(animCurrent, 10, w - 10)
            draw.RoundedBox(8, circleX - 8, 2, 16, 16, Color(255, 255, 255, self:IsEnabled() and 255 or 100))
        end
        
        btnSwitch.DoClick = function(self)
            self.Checked = not self.Checked
            animTarget = self.Checked and 1 or 0
            if self.OnChange then self:OnChange(self.Checked) end
        end
        
        panel.GetChecked = function() return btnSwitch.Checked end
        panel.SetChecked = function(self, val)
            btnSwitch.Checked = val
            animTarget = val and 1 or 0
        end
        panel.SetDisabled = function(self, val) btnSwitch:SetEnabled(not val) end
        panel.OnChange = function(val) end
        btnSwitch.OnChange = function(self, val) panel.OnChange(val) end
        
        return panel
    end
    
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(15, 45, 15, 15)
    
    local sbar = scroll:GetVBar()
    sbar:SetWide(6)
    sbar.Paint = function() end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, Color(0, 150, 255, 100))
    end
    
    local lblModel = vgui.Create("DLabel", scroll)
    lblModel:SetText("MODELO 3D DE LA CONSOLA")
    lblModel:SetFont("Datapad_Text")
    lblModel:Dock(TOP)
    lblModel:DockMargin(0, 10, 0, 5)
    lblModel:SetTextColor(Color(0, 150, 255))
    
    local txtModel = vgui.Create("DTextEntry", scroll)
    txtModel:Dock(TOP)
    txtModel:SetTall(35)
    txtModel:DockMargin(0, 0, 0, 15)
    txtModel:SetText(ent:GetConsoleModel())
    txtModel:SetFont("Datapad_Text")
    txtModel.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(0, 0, 0, 150))
        surface.SetDrawColor(0, 150, 255, 50)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        self:DrawTextEntryText(Color(255, 255, 255), Color(0, 150, 255), Color(255, 255, 255))
    end
    
    local lblDiff = vgui.Create("DLabel", scroll)
    lblDiff:SetText("TIEMPO DE HACKEO (SEGUNDOS)")
    lblDiff:SetFont("Datapad_Text")
    lblDiff:Dock(TOP)
    lblDiff:DockMargin(0, 0, 0, 5)
    lblDiff:SetTextColor(Color(0, 150, 255))
    
    local sliderDiff = vgui.Create("DNumSlider", scroll)
    sliderDiff:Dock(TOP)
    sliderDiff:SetTall(35)
    sliderDiff:DockMargin(0, 0, 0, 15)
    sliderDiff:SetText("")
    sliderDiff:SetMin(10)
    sliderDiff:SetMax(120)
    sliderDiff:SetDecimals(0)
    sliderDiff:SetValue(ent:GetHackDifficulty() or 45)
    sliderDiff.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(0, 0, 0, 100))
    end
    
    local lblDown = vgui.Create("DLabel", scroll)
    lblDown:SetText("TIEMPO DE EXTRACCIÓN AL DATAPAD (SEGUNDOS)")
    lblDown:SetFont("Datapad_Text")
    lblDown:Dock(TOP)
    lblDown:DockMargin(0, 0, 0, 5)
    lblDown:SetTextColor(Color(0, 150, 255))
    
    local sliderDown = vgui.Create("DNumSlider", scroll)
    sliderDown:Dock(TOP)
    sliderDown:SetTall(35)
    sliderDown:DockMargin(0, 0, 0, 15)
    sliderDown:SetText("")
    sliderDown:SetMin(5)
    sliderDown:SetMax(120)
    sliderDown:SetDecimals(0)
    sliderDown:SetValue(ent:GetDownloadTime() or 15)
    sliderDown.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(0, 0, 0, 100))
    end
    
    local lblAccess = vgui.Create("DLabel", scroll)
    lblAccess:SetText("PERMISOS DE LECTURA/ESCRITURA")
    lblAccess:SetFont("Datapad_Text")
    lblAccess:Dock(TOP)
    lblAccess:DockMargin(0, 0, 0, 5)
    lblAccess:SetTextColor(Color(0, 150, 255))
    
    -- Parsear permisos actuales
    local currentJobs = string.Explode(",", ent:GetAccessJobs())
    local jobsDict = {}
    for _, j in ipairs(currentJobs) do
        local t = string.Trim(j)
        if t ~= "" then jobsDict[string.lower(t)] = true end
    end
    
    local isPublic = ent:GetAccessJobs() == ""
    
    local switchPublic = CreateSwitch(scroll, "HACER PÚBLICO (No requiere hackeo)", isPublic, true)
    switchPublic:DockMargin(0, 0, 0, 15)
    
    local jobListPanel = vgui.Create("DPanel", scroll)
    jobListPanel:Dock(TOP)
    jobListPanel:DockMargin(0, 0, 0, 15)
    jobListPanel.Paint = function() end
    jobListPanel.PerformLayout = function(self)
        self:SizeToChildren(false, true)
    end
    
    local jobCheckboxes = {}
    local heightCounter = 0
    
    -- Agrupar jobs por categorías (DarkRP)
    if RPExtraTeams then
        local cats = DarkRP and DarkRP.getCategories and DarkRP.getCategories().jobs or {}
        
        if table.Count(cats) == 0 then
            cats = {{ name = "Todos los Trabajos", members = RPExtraTeams }}
        end
        
        for _, cat in pairs(cats) do
            -- Solo mostrar categoría si tiene jobs
            if cat.members and #cat.members > 0 then
                local catCol = vgui.Create("DCollapsibleCategory", jobListPanel)
                catCol:Dock(TOP)
                catCol:DockMargin(0, 5, 0, 0)
                catCol:SetLabel(string.upper(cat.name))
                catCol:SetExpanded(false)
                
                -- Cambiar el estilo del título de la categoría
                catCol.Header:SetTall(35)
                catCol.Header:SetFont("Datapad_Text")
                catCol.Header:SetTextColor(Color(100, 200, 255))
                catCol.Paint = function(self, w, h)
                    draw.RoundedBox(6, 0, 0, w, 35, Color(0, 0, 0, 150))
                end
                
                local catContent = vgui.Create("DPanel")
                catContent:DockPadding(5, 5, 5, 5)
                catContent.Paint = function(self, w, h)
                    draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 50))
                end
                catCol:SetContents(catContent)
                
                local catSwitch = CreateSwitch(catContent, "── " .. "SELECCIONAR TODOS" .. " ──", false)
                catSwitch:Dock(TOP)
                
                local catChecks = {}
                
                for _, job in ipairs(cat.members) do
                    local isChecked = jobsDict[string.lower(job.name)] == true
                    local chk = CreateSwitch(catContent, job.name, isChecked)
                    chk:Dock(TOP)
                    chk.JobName = job.name
                    
                    table.insert(jobCheckboxes, chk)
                    table.insert(catChecks, chk)
                end
                
                catSwitch.OnChange = function(val)
                    for _, c in ipairs(catChecks) do
                        c:SetChecked(val)
                    end
                end
                
                -- Auto ajustamos el tamaño del panel de contenido interior
                catContent:SetTall(35 + (#cat.members * 40) + 10)
            end
        end
    end
    
    switchPublic.OnChange = function(val)
        jobListPanel:SetAlpha(val and 50 or 255)
        for _, chk in ipairs(jobCheckboxes) do
            chk:SetDisabled(val)
        end
    end
    switchPublic.OnChange(isPublic)
    
    local lblGames = vgui.Create("DLabel", scroll)
    lblGames:SetText("MINIJUEGOS DE HACKEO PERMITIDOS")
    lblGames:SetFont("Datapad_Text")
    lblGames:Dock(TOP)
    lblGames:DockMargin(0, 10, 0, 5)
    lblGames:SetTextColor(Color(0, 150, 255))
    
    local currentGames = ent:GetHackGames() or ""
    if currentGames == "" then currentGames = "1,2,3" end -- Default
    local allowedGames = string.Explode(",", currentGames)
    local gamesDict = {}
    for _, g in ipairs(allowedGames) do gamesDict[string.Trim(g)] = true end
    
    local switchGame1 = CreateSwitch(scroll, "Inyección de Datos (Bruteforce)", gamesDict["1"])
    local switchGame2 = CreateSwitch(scroll, "Puertos de Red (Circuit)", gamesDict["2"])
    local switchGame3 = CreateSwitch(scroll, "Frecuencias (Voltage)", gamesDict["3"])
    
    local btnSave = vgui.Create("DButton", frame)
    btnSave:SetText("APLICAR PROTOCOLOS DE SEGURIDAD")
    btnSave:Dock(BOTTOM)
    btnSave:DockMargin(15, 0, 15, 15)
    btnSave:SetTall(45)
    btnSave:SetFont("Datapad_Title")
    btnSave:SetTextColor(Color(255, 255, 255))
    btnSave.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox(8, 0, 0, w, h, Color(0, 150, 255, 200))
            surface.SetDrawColor(0, 255, 255, 255)
        else
            draw.RoundedBox(8, 0, 0, w, h, Color(0, 100, 200, 150))
            surface.SetDrawColor(0, 150, 255, 100)
        end
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    btnSave.DoClick = function()
        local accessString = ""
        if not switchPublic:GetChecked() then
            local selected = {}
            for _, chk in ipairs(jobCheckboxes) do
                if chk:GetChecked() then
                    table.insert(selected, chk.JobName)
                end
            end
            accessString = table.concat(selected, ",")
            if accessString == "" then accessString = "NADIE_TIENE_ACCESO" end
        end
        
        local gamesList = {}
        if switchGame1:GetChecked() then table.insert(gamesList, "1") end
        if switchGame2:GetChecked() then table.insert(gamesList, "2") end
        if switchGame3:GetChecked() then table.insert(gamesList, "3") end
        local gamesString = table.concat(gamesList, ",")
        if gamesString == "" then gamesString = "1,2,3" end -- fallback to all if none selected
        
        net.Start("IVO_Docs_AdminSave")
        net.WriteEntity(ent)
        net.WriteString(txtModel:GetText())
        net.WriteString(accessString)
        net.WriteUInt(math.Round(sliderDiff:GetValue()), 16)
        net.WriteUInt(math.Round(sliderDown:GetValue()), 16)
        net.WriteString(gamesString)
        net.SendToServer()
        frame:Close()
    end
end

net.Receive("IVO_Docs_AdminSave_Trigger", function()
    local ent = net.ReadEntity()
    IVO_Docs_OpenAdminConfig(ent)
end)
