-- lua/autorun/client/cl_music.lua

local music_volume = CreateClientConVar("music_volume", "1.0", true, false)
local music_enabled = CreateClientConVar("music_enabled", "1", true, false)

local ambient_volume = CreateClientConVar("ambient_music_volume", "0.02", true, false)
local ambient_enabled = CreateClientConVar("ambient_music_enabled", "1", true, false)

local COL_BG = Color(5, 5, 10, 220)
local COL_HEADER = Color(10, 15, 20, 240)
local COL_ACCENT = Color(0, 150, 255)
local COL_TEXT = Color(255, 255, 255)
local COL_MUTED = Color(160, 160, 170)
local COL_CARD = Color(15, 15, 20, 255)

surface.CreateFont("Music_Title", { font = "Montserrat", size = 20, weight = 800, antialias = true })
surface.CreateFont("Music_Large", { font = "Montserrat", size = 28, weight = 800, antialias = true })
surface.CreateFont("Music_Normal", { font = "Montserrat", size = 16, weight = 600, antialias = true })
surface.CreateFont("Music_Small", { font = "Montserrat", size = 14, weight = 500, antialias = true })

local blur = Material("pp/blurscreen")
local function DrawBlur(panel, amount)
    local x, y = panel:LocalToScreen(0, 0)
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blur)
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * (amount or 6))
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
    end
end

local currentQueue = {}
local currentStation = nil
local currentPlayingName = ""
local songStarted = false 
local initialSyncReceived = false 

-- NUEVAS VARIABLES PARA SEGUIMIENTO DE TIEMPO RECOBRADO
local pendingTimeOffset = 0
local timeOffsetApplied = false

local ambientStation = nil

cvars.AddChangeCallback("music_volume", function(convar_name, value_old, value_new)
    if IsValid(currentStation) and music_enabled:GetBool() then
        currentStation:SetVolume(tonumber(value_new) or 0)
    end
end, "AdminMusic_VolumeSync")

cvars.AddChangeCallback("ambient_music_volume", function(convar_name, value_old, value_new)
    if IsValid(ambientStation) and ambient_enabled:GetBool() then
        ambientStation:SetVolume(tonumber(value_new) or 0)
    end
end, "AdminMusic_AmbientVolumeSync")

cvars.AddChangeCallback("music_enabled", function(convar_name, value_old, value_new)
    if IsValid(currentStation) then
        currentStation:SetVolume((tonumber(value_new) == 1) and music_volume:GetFloat() or 0)
    end
end, "AdminMusic_EnabledSync")

cvars.AddChangeCallback("ambient_music_enabled", function(convar_name, value_old, value_new)
    if IsValid(ambientStation) then
        ambientStation:SetVolume((tonumber(value_new) == 1) and ambient_volume:GetFloat() or 0)
    end
end, "AdminMusic_AmbientEnabledSync")

-- === FUNCIONES DE AMBIENTE ===
local function StopAmbient()
    if IsValid(ambientStation) then
        ambientStation:Stop()
        ambientStation = nil
    end
end

local isAmbientLoading = false

local function PlayRandomAmbient()
    if not ambient_enabled:GetBool() then return end
    if not MUSIC_CONFIG.AmbientSongs or #MUSIC_CONFIG.AmbientSongs == 0 then return end
    if IsValid(currentStation) and currentStation:GetState() == 1 then return end
    if IsValid(ambientStation) and ambientStation:GetState() == 1 then return end
    if isAmbientLoading then return end

    isAmbientLoading = true
    local randomURL = MUSIC_CONFIG.AmbientSongs[math.random(#MUSIC_CONFIG.AmbientSongs)]

    sound.PlayURL(randomURL, "noblock", function(station, errCode, errStr)
        isAmbientLoading = false
        if IsValid(station) then
            if IsValid(currentStation) and currentStation:GetState() == 1 then
                station:Stop()
                return
            end
            
            if IsValid(ambientStation) then
                ambientStation:Stop()
            end
            
            ambientStation = station
            ambientStation:SetVolume(ambient_volume:GetFloat())
            ambientStation:Play()
        end
    end)
end

timer.Create("AmbientMusicManager", 3, 0, function()
    if not initialSyncReceived then return end 

    if IsValid(currentStation) and currentStation:GetState() == 1 then
        StopAmbient()
        return
    end

    if ambient_enabled:GetBool() then
        if not IsValid(ambientStation) or ambientStation:GetState() ~= 1 then
            PlayRandomAmbient()
        end
    else
        StopAmbient()
    end
end)

local fadingStations = {}
local function FadeOutAndStop(station)
    if not IsValid(station) then return end
    local startVol = station:GetVolume()
    local fadeTime = 3
    local startTime = CurTime()
    table.insert(fadingStations, {stat = station, startV = startVol, startT = startTime, duration = fadeTime})
end

hook.Add("Think", "AdminMusic_Fades", function()
    for i = #fadingStations, 1, -1 do
        local fade = fadingStations[i]
        if IsValid(fade.stat) then
            local fraction = (CurTime() - fade.startT) / fade.duration
            if fraction >= 1 then
                fade.stat:Stop()
                table.remove(fadingStations, i)
            else
                fade.stat:SetVolume(Lerp(fraction, fade.startV, 0))
            end
        else
            table.remove(fadingStations, i)
        end
    end
end)

-- === FUNCIONES DE ADMIN MUSIC ===
local function AttemptPlay(timeOffset)
    if #currentQueue == 0 then return end
    local songToPlay = currentQueue[1]

    if IsValid(currentStation) and currentPlayingName == songToPlay.name then return end
    if IsValid(currentStation) then FadeOutAndStop(currentStation) end
    
    StopAmbient()
    songStarted = false 
    
    -- Guardamos el retraso que hay que aplicar de forma global temporalmente
    pendingTimeOffset = timeOffset or 0
    timeOffsetApplied = false
    
    sound.PlayURL(songToPlay.url, "noblock", function(station, errCode, errStr)
        if IsValid(station) then
            currentStation = station
            currentPlayingName = songToPlay.name
            currentStation:SetVolume(music_volume:GetFloat())
            currentStation:Play()
        end
    end)
end

-- === SINCRONIZACIÓN INTELIGENTE ===
net.Receive("Music_Sync", function()
    initialSyncReceived = true 

    local oldFirst = currentQueue[1] and currentQueue[1].name or nil
    
    currentQueue = net.ReadTable()
    local elapsedTime = net.ReadFloat() 
    
    local newFirst = currentQueue[1] and currentQueue[1].name or nil
    
    if IsValid(GMusicFrame) and GMusicFrame.RefreshQueueList then
        GMusicFrame:RefreshQueueList()
    end
    
    if oldFirst ~= newFirst then
        if IsValid(currentStation) then FadeOutAndStop(currentStation) end
        currentStation = nil
        currentPlayingName = ""
        songStarted = false 
        
        if newFirst then
            AttemptPlay(elapsedTime) 
        else
            timer.Simple(1, function() PlayRandomAmbient() end) 
        end
    elseif not IsValid(currentStation) and #currentQueue > 0 then
        AttemptPlay(elapsedTime) 
    end
end)

net.Receive("Music_Stop", function()
    if IsValid(currentStation) then FadeOutAndStop(currentStation) end
    currentStation = nil
    currentPlayingName = ""
    songStarted = false 
    currentQueue = {}
    pendingTimeOffset = 0
    timeOffsetApplied = false
    if IsValid(GMusicFrame) then GMusicFrame:RefreshQueueList() end
    timer.Simple(1, function() PlayRandomAmbient() end)
end)

-- === INTERFAZ PRINCIPAL DE ADMINISTRADOR ===
net.Receive("OpenMusicMenu", function()
    if IsValid(GMusicFrame) then GMusicFrame:Remove() end
    
    GMusicFrame = vgui.Create("DFrame")
    GMusicFrame:SetSize(ScrW(), ScrH())
    GMusicFrame:Center()
    GMusicFrame:SetTitle("")
    GMusicFrame:ShowCloseButton(false)
    GMusicFrame:MakePopup()
    GMusicFrame.Paint = function() end
    
    local isDragging = false
    local lastMouseX, lastMouseY = 0, 0
    GMusicFrame.OnMousePressed = function(s, code)
        if code == MOUSE_LEFT then
            isDragging = true
            lastMouseX, lastMouseY = gui.MouseX(), gui.MouseY()
        end
    end
    GMusicFrame.OnMouseReleased = function(s, code)
        if code == MOUSE_LEFT then isDragging = false end
    end
    GMusicFrame.Think = function(s)
        if not LocalPlayer():Alive() then s:Close() end
    end

    local MenuPanel = vgui.Create("DPanel", GMusicFrame)
    MenuPanel:SetSize(400, ScrH() * 0.75)
    MenuPanel:SetPos(50, ScrH() * 0.12)
    MenuPanel.Paint = function(s, pw, ph)
        -- Blur local al panel
        local x, y = s:LocalToScreen(0, 0)
        render.SetScissorRect(x, y, x + pw, y + ph, true)
        DrawBlur(s, 6)
        render.SetScissorRect(0, 0, 0, 0, false)
        
        draw.RoundedBox(8, 0, 0, pw, ph, Color(0, 0, 0, 180))
        
        local shopTitle = "PANEL DE MÚSICA"
        draw.SimpleText(shopTitle, "SW_InvShop_BigTitle", 20, 20, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(shopTitle, "SW_InvShop_Aurebesh_Title", 20, 42, Color(150, 150, 150, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(0, 150, 255, 150)
        surface.DrawRect(20, 50, 360, 2)
    end
    
    local btnBack = vgui.Create("DButton", MenuPanel)
    btnBack:SetText("")
    btnBack:Dock(BOTTOM)
    btnBack:DockMargin(10, 10, 10, 10)
    btnBack:SetTall(38)
    btnBack.HoverP = 0
    btnBack.Paint = function(s, w, h)
        s.HoverP = Lerp(FrameTime() * 15, s.HoverP or 0, s:IsHovered() and 1 or 0)
        if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
        
        -- Base blanco
        draw.RoundedBox(16, 0, 0, w, h, color_white)
        -- Oscurecer al pasar el ratón
        if s.HoverP > 0.01 then draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, s.HoverP * 200)) end
        
        -- Texto: de negro (normal) a blanco (hover)
        local tc = Lerp(s.HoverP, 0, 255)
        draw.SimpleText("CERRAR PANEL", "SW_InvShop_Medium", w/2, h/2, Color(tc, tc, tc), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnBack.DoClick = function() GMusicFrame:Remove() end

    local sepPanel = vgui.Create("DPanel", MenuPanel)
    sepPanel:Dock(BOTTOM)
    sepPanel:DockMargin(20, 10, 20, 10)
    sepPanel:SetTall(1)
    sepPanel.Paint = function(s, w, h)
        surface.SetDrawColor(0, 150, 255, 50)
        surface.DrawRect(0, 0, w, h)
    end

    local topNavContainer = vgui.Create("DPanel", MenuPanel)
    topNavContainer:SetPos(20, 70)
    topNavContainer:SetSize(360, 35)
    topNavContainer.Paint = nil

    local contentContainer = vgui.Create("DPanel", MenuPanel)
    contentContainer:SetPos(10, 115)
    contentContainer:SetSize(380, MenuPanel:GetTall() - 115 - 58 - 21)
    contentContainer.Paint = nil
    
    local topNavX = 0
    GMusicFrame.TabPanels = {}
    local function AddTopNav(text, pnlObj)
        surface.SetFont("SW_InvShop_Medium")
        local tw = surface.GetTextSize(text)
        local w = tw + 20
        local btn = vgui.Create("DButton", topNavContainer)
        btn:SetSize(w, 35)
        btn:SetPos(topNavX, 0)
        btn:SetText("")
        btn.HoverP = 0
        btn.Paint = function(s, pw, ph)
            local isActive = pnlObj:IsVisible()
            s.HoverP = Lerp(FrameTime() * 15, s.HoverP, (s:IsHovered() or isActive) and 1 or 0)
            draw.RoundedBox(8, 0, 0, pw, ph, Color(0, 0, 0, 80))
            if s.HoverP > 0.01 then draw.RoundedBox(8, 0, 0, pw, ph, Color(255, 255, 255, s.HoverP * 255)) end
            local tc = Lerp(s.HoverP, 200, 0)
            draw.SimpleText(text, "SW_InvShop_Medium", pw/2, ph/2, Color(tc, tc, tc), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function()
            surface.PlaySound("navigation/aceptar.wav")
            for _, p in ipairs(GMusicFrame.TabPanels) do p:SetVisible(false) end
            pnlObj:SetVisible(true)
        end
        topNavX = topNavX + w + 10
    end

    -- === PESTAÑA BIBLIOTECA ===
    local libPanel = vgui.Create("DPanel", contentContainer); libPanel:Dock(FILL); table.insert(GMusicFrame.TabPanels, libPanel)
    libPanel.Paint = nil
    
    local songFolders = {}
    if file.Exists("adminmusic_folders.json", "DATA") then
        songFolders = util.JSONToTable(file.Read("adminmusic_folders.json", "DATA")) or {}
    end
    
    local scrollLib = vgui.Create("DScrollPanel", libPanel)
    scrollLib:Dock(FILL)
    scrollLib:GetVBar():SetWide(0)

    local function RefreshLibrary()
        scrollLib:Clear()
        
        -- Agrupar canciones
        local categories = {}
        for _, v in pairs(MUSIC_CONFIG.Songs) do
            local cat = songFolders[v.url] or "Música General"
            if not categories[cat] then categories[cat] = {} end
            table.insert(categories[cat], v)
        end
        
        for catName, songs in pairs(categories) do
            local catHeader = scrollLib:Add("DButton")
            catHeader:Dock(TOP)
            catHeader:DockMargin(10, 5, 10, 0)
            catHeader:SetTall(30)
            catHeader:SetText("")
            catHeader.Expanded = true
            catHeader.Paint = function(s, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(0, 150, 255, 50))
                draw.SimpleText(s.Expanded and "▼ " .. catName or "▶ " .. catName, "SW_InvShop_Medium", 10, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            
            local catContainer = scrollLib:Add("DPanel")
            catContainer:Dock(TOP)
            catContainer.Paint = nil
            
            catHeader.DoClick = function(s)
                s.Expanded = not s.Expanded
                catContainer:SetVisible(s.Expanded)
                catContainer:InvalidateLayout(true)
                scrollLib:InvalidateLayout()
            end
            
            local currentH = 0
            for _, v in ipairs(songs) do
                local btnAdd = vgui.Create("DButton", catContainer)
                btnAdd:Dock(TOP)
                btnAdd:DockMargin(10, 2, 10, 2)
                btnAdd:SetTall(35)
                btnAdd:SetText("")
                btnAdd.HoverP = 0
                btnAdd.Paint = function(s, w, h)
                    s.HoverP = Lerp(FrameTime() * 15, s.HoverP, s:IsHovered() and 1 or 0)
                    if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                    
                    draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                    if s.HoverP > 0.01 then draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255)) end
                    
                    local tc = Lerp(s.HoverP, 200, 0)
                    draw.SimpleText(v.name, "SW_InvShop_Medium", 15, h/2, Color(tc, tc, tc), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    
                    local txtAdd = "AGREGAR"
                    local tcRight = Lerp(s.HoverP, 200, 0)
                    if s.HoverP > 0.5 then tcRight = 0 end
                    draw.SimpleText(txtAdd, "SW_InvShop_Aurebesh_Medium", w - 15, h/2, Color(0, 150, 255, 255 - tcRight), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
                btnAdd.DoClick = function()
                    net.Start("Music_Action")
                    net.WriteString("AddToQueue")
                    net.WriteString(v.name)
                    net.WriteString(v.url)
                    net.SendToServer()
                    surface.PlaySound("buttons/button14.wav")
                end
                btnAdd.DoRightClick = function()
                    local menu = DermaMenu()
                    local sub = menu:AddSubMenu("Mover a carpeta...")
                    
                    for cName, _ in pairs(categories) do
                        sub:AddOption(cName, function()
                            songFolders[v.url] = cName
                            file.Write("adminmusic_folders.json", util.TableToJSON(songFolders))
                            RefreshLibrary()
                        end)
                    end
                    
                    sub:AddSpacer()
                    sub:AddOption("Crear nueva carpeta...", function()
                        Derma_StringRequest("Nueva Carpeta", "Ingresa el nombre de la carpeta:", "", function(text)
                            if text and text ~= "" then
                                songFolders[v.url] = text
                                file.Write("adminmusic_folders.json", util.TableToJSON(songFolders))
                                RefreshLibrary()
                            end
                        end)
                    end)
                    
                    if catName ~= "Música General" then
                        menu:AddOption("Quitar de carpeta", function()
                            songFolders[v.url] = nil
                            file.Write("adminmusic_folders.json", util.TableToJSON(songFolders))
                            RefreshLibrary()
                        end)
                    end
                    
                    menu:Open()
                end
                currentH = currentH + 39
            end
            catContainer:SetTall(currentH)
        end
    end
    
    RefreshLibrary()
    AddTopNav("BIBLIOTECA", libPanel)

    -- === PESTAÑA REPRODUCTOR ===
    local pnl = vgui.Create("DPanel", contentContainer); pnl:Dock(FILL); pnl:SetVisible(false); table.insert(GMusicFrame.TabPanels, pnl)
    pnl.Paint = nil
    
    local queueScroll = vgui.Create("DScrollPanel", pnl)
    queueScroll:Dock(FILL)
    queueScroll:DockMargin(0, 0, 0, 10)
    queueScroll:GetVBar():SetWide(0)

    local statusPnl = vgui.Create("DPanel", pnl)
    statusPnl:Dock(BOTTOM)
    statusPnl:SetTall(60)
    statusPnl.Paint = nil
    
    lblName = vgui.Create("DLabel", statusPnl)
    lblName:Dock(TOP)
    lblName:SetFont("SW_InvShop_Medium")
    lblName:SetTextColor(Color(255,255,255))
    lblName:SetContentAlignment(5)
    
    lblTime = vgui.Create("DLabel", statusPnl)
    lblTime:Dock(TOP)
    lblTime:SetFont("SW_InvShop_Medium")
    lblTime:SetTextColor(Color(150,150,150))
    lblTime:SetContentAlignment(5)

    local btnContainer = vgui.Create("DPanel", pnl)
    btnContainer:Dock(BOTTOM)
    btnContainer:SetTall(40)
    btnContainer:DockMargin(0, 10, 0, 0)
    btnContainer.Paint = nil

    local btnSkip = vgui.Create("DButton", btnContainer)
    btnSkip:Dock(LEFT)
    btnSkip:SetWide(180)
    btnSkip:SetText("")
    btnSkip.HoverP = 0
    btnSkip.Paint = function(s, w, h)
        s.HoverP = Lerp(FrameTime() * 15, s.HoverP, s:IsHovered() and 1 or 0)
        draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
        if s.HoverP > 0.01 then draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255)) end
        local tc = Lerp(s.HoverP, 200, 0)
        draw.SimpleText("SALTAR CANCIÓN", "SW_InvShop_Medium", w/2, h/2, Color(tc, tc, tc), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnSkip.DoClick = function() 
        net.Start("Music_Action") 
        net.WriteString("Skip")
        net.SendToServer()
        surface.PlaySound("buttons/button10.wav")
    end

    local btnStop = vgui.Create("DButton", btnContainer)
    btnStop:Dock(RIGHT)
    btnStop:SetWide(180)
    btnStop:SetText("")
    btnStop.HoverP = 0
    btnStop.Paint = function(s, w, h)
        s.HoverP = Lerp(FrameTime() * 15, s.HoverP, s:IsHovered() and 1 or 0)
        draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
        if s.HoverP > 0.01 then draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255)) end
        local tc = Lerp(s.HoverP, 200, 0)
        draw.SimpleText("DETENER TODO", "SW_InvShop_Medium", w/2, h/2, Color(tc, tc, tc), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnStop.DoClick = function() 
        net.Start("Music_Action") 
        net.WriteString("Stop")
        net.SendToServer()
        surface.PlaySound("buttons/button10.wav")
    end
    
    AddTopNav("REPRODUCTOR", pnl)

    GMusicFrame.RefreshQueueList = function()
        queueScroll:Clear()
        for k, v in ipairs(currentQueue) do
            local btnRemove = queueScroll:Add("DButton")
            btnRemove:Dock(TOP)
            btnRemove:DockMargin(10, 2, 10, 2)
            btnRemove:SetTall(35)
            btnRemove:SetText("")
            btnRemove.HoverP = 0
            btnRemove.Paint = function(s, w, h)
                s.HoverP = Lerp(FrameTime() * 15, s.HoverP, s:IsHovered() and 1 or 0)
                if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                
                draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                if s.HoverP > 0.01 then
                    draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
                end
                
                local tc = Lerp(s.HoverP, 200, 0)
                draw.SimpleText(k .. ". " .. v.name, "SW_InvShop_Medium", 15, h/2, Color(tc, tc, tc), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                
                local txtRm = k == 1 and "SALTAR" or "ELIMINAR"
                local tcRight = Lerp(s.HoverP, 200, 0)
                if s.HoverP > 0.5 then tcRight = 0 end
                draw.SimpleText(txtRm, "SW_InvShop_Aurebesh_Medium", w - 15, h/2, Color(255, 50, 50, 255 - tcRight), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            btnRemove.DoClick = function()
                net.Start("Music_Action")
                if k == 1 then
                    net.WriteString("Skip")
                else
                    net.WriteString("Remove")
                    net.WriteUInt(k, 8)
                end
                net.SendToServer()
                surface.PlaySound("buttons/button14.wav")
            end
        end
    end
    GMusicFrame:RefreshQueueList()
end)

-- === MONITOR SENSING / CORRECCIÓN DE TIEMPO SEGURO ===
timer.Create("MusicUIUpdate", 0.1, 0, function() -- Bajamos el delay a 0.1 para que la corrección sea instantánea
    if IsValid(currentStation) then
        local state = currentStation:GetState()
        
        if state == 1 then
            songStarted = true
            
            -- FORZADO DE TIEMPO AQUÍ: Esperamos a que esté lista para aplicar el SetTime de forma segura
            if pendingTimeOffset > 0 and not timeOffsetApplied then
                currentStation:SetTime(pendingTimeOffset)
                timeOffsetApplied = true -- Nos aseguramos de aplicarlo una sola vez
                pendingTimeOffset = 0
            end
            
            local len = currentStation:GetLength()
            local pos = currentStation:GetTime()
            if len > 3 and pos >= len - 3 and not currentStation._crossfadeTriggered then
                currentStation._crossfadeTriggered = true
                net.Start("Music_Action")
                net.WriteString("AutoSkip")
                net.SendToServer()
            end
            
        elseif songStarted and state == 0 then
            songStarted = false
            currentStation = nil
            currentPlayingName = ""
            pendingTimeOffset = 0
            timeOffsetApplied = false
            net.Start("Music_Action")
            net.WriteString("AutoSkip")
            net.SendToServer()
        end
    elseif songStarted then
        songStarted = false
        currentPlayingName = ""
        pendingTimeOffset = 0
        timeOffsetApplied = false
        net.Start("Music_Action")
        net.WriteString("AutoSkip")
        net.SendToServer()
    end

    if not IsValid(GMusicFrame) then return end
    if IsValid(currentStation) and currentPlayingName ~= "" then
        lblName:SetText("Reproduciendo: " .. currentPlayingName)
        local pos = currentStation:GetTime()
        local len = currentStation:GetLength()
        lblTime:SetText(string.FormattedTime(pos, "%02i:%02i") .. " / " .. string.FormattedTime(len, "%02i:%02i"))
    else
        lblName:SetText("Esperando música...")
        lblTime:SetText("00:00 / 00:00")
    end
    
    _G.AdminMusic_CurrentStation = currentStation
    _G.AdminMusic_CurrentName = currentPlayingName
end)

-- === MENÚ DE LA "C" (CONTEXT MENU) ===
list.Set("DesktopWindows", "MusicSettings", {
    title = "CONTROL DE MUSICA",
    icon = "icon64/tool.png",
    width = 320,
    height = 300,
    onewindow = true,
    init = function(icon, window)
        local panel = vgui.Create("DPanel", window)
        panel:Dock(FILL)
        panel:DockPadding(15, 15, 15, 15)
        panel.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(15, 15, 20, 255))
        end

        local title = vgui.Create("DLabel", panel)
        title:Dock(TOP)
        title:SetTall(30)
        title:SetText("AJUSTES DE MUSICA")
        title:SetFont("SW_InvShop_Medium")
        title:SetTextColor(Color(255, 255, 255))
        title:SetContentAlignment(4)
        
        local div = vgui.Create("DPanel", panel)
        div:Dock(TOP)
        div:SetTall(1)
        div:DockMargin(0, 0, 0, 15)
        div.Paint = function(self, w, h) surface.SetDrawColor(0, 150, 255, 150) surface.DrawRect(0, 0, w, h) end

        local function CreateConfigToggle(labelText, checked, onChange)
            local container = vgui.Create("DPanel", panel)
            container:Dock(TOP)
            container:SetTall(24)
            container:DockMargin(0, 5, 0, 5)
            container.Paint = nil
            
            local lbl = vgui.Create("DLabel", container)
            lbl:Dock(LEFT)
            lbl:SetWide(200)
            lbl:SetText(labelText)
            lbl:SetFont("SW_InvShop_Small")
            lbl:SetTextColor(Color(200, 200, 200))
            
            local btn = vgui.Create("DButton", container)
            btn:Dock(RIGHT)
            btn:SetWide(40)
            btn:SetText("")
            btn.Checked = checked
            btn.Paint = function(s, w, h)
                local c_accent = Color(0, 150, 255)
                draw.RoundedBox(4, 0, 4, w, h - 8, Color(0, 0, 0, 150))
                if s.Checked then
                    draw.RoundedBox(4, w/2, 4, w/2, h - 8, c_accent)
                else
                    draw.RoundedBox(4, 0, 4, w/2, h - 8, Color(100, 100, 100, 100))
                end
            end
            btn.DoClick = function(s)
                s.Checked = not s.Checked
                onChange(s.Checked)
            end
        end
        
        local function CreateConfigSlider(labelText, val, onChange)
            local slider = vgui.Create("DNumSlider", panel)
            slider:Dock(TOP)
            slider:DockMargin(0, 5, 0, 10)
            slider:SetMin(0)
            slider:SetMax(1)
            slider:SetDecimals(2)
            slider:SetValue(val)
            
            slider.Label:SetFont("SW_InvShop_Small")
            slider.Label:SetTextColor(Color(255, 255, 255, 150))
            slider.Label:SetText(labelText)
            slider.TextArea:SetTextColor(color_white)
            slider.TextArea:SetFont("SW_InvShop_Small")
            
            slider.Slider.Paint = function(self, w, h)
                local c_accent = Color(0, 150, 255)
                draw.RoundedBox(0, 0, h/2 - 1, w, 2, Color(255, 255, 255, 10))
                local min, max = slider:GetMin(), slider:GetMax()
                local val = slider:GetValue()
                local fraction = (val - min) / math.max(max - min, 0.001)
                fraction = math.Clamp(fraction, 0, 1)
                local valW = fraction * w
                surface.SetDrawColor(c_accent)
                surface.DrawRect(0, h/2 - 1, valW, 2)
            end
            slider.Slider.Knob.Paint = function(self, w, h)
                local c_accent = Color(0, 150, 255)
                draw.RoundedBox(0, 2, 2, w - 4, h - 4, c_accent)
            end
            
            slider.OnValueChanged = function(self, value)
                onChange(value)
            end
        end

        CreateConfigToggle("MUSICA ADMIN", music_enabled:GetBool(), function(val)
            RunConsoleCommand("music_enabled", val and "1" or "0")
            if IsValid(currentStation) then currentStation:SetVolume(val and music_volume:GetFloat() or 0) end
        end)
        
        CreateConfigSlider("VOLUMEN", music_volume:GetFloat(), function(val)
            RunConsoleCommand("music_volume", val)
            if IsValid(currentStation) and music_enabled:GetBool() then currentStation:SetVolume(val) end
        end)
        
        CreateConfigToggle("MUSICA AMBIENTE", ambient_enabled:GetBool(), function(val)
            RunConsoleCommand("ambient_music_enabled", val and "1" or "0")
            if not val then StopAmbient() end
        end)
        
        CreateConfigSlider("VOLUMEN AMBIENTE", ambient_volume:GetFloat(), function(val)
            RunConsoleCommand("ambient_music_volume", val)
            if IsValid(ambientStation) and ambient_enabled:GetBool() then ambientStation:SetVolume(val) end
        end)

        local btnRestartLocal = vgui.Create("DButton", panel)
        btnRestartLocal:Dock(TOP)
        btnRestartLocal:DockMargin(0, 10, 0, 0)
        btnRestartLocal:SetTall(30)
        btnRestartLocal:SetText("")
        btnRestartLocal.HoverP = 0
        btnRestartLocal.Paint = function(s, w, h) 
            s.HoverP = Lerp(FrameTime() * 15, s.HoverP, s:IsHovered() and 1 or 0)
            draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 80))
            if s.HoverP > 0.01 then draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255)) end
            local tc = Lerp(s.HoverP, 200, 0)
            draw.SimpleText("REINICIAR AUDIO", "SW_InvShop_Medium", w/2, h/2, Color(tc, tc, tc), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        btnRestartLocal.DoClick = function()
            StopAmbient() 
            PlayRandomAmbient() 
            surface.PlaySound("buttons/button14.wav")
        end
    end
})
