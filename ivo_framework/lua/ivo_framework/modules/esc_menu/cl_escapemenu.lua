local function SafeUpper(str)
    if not str then return "" end
    local utf8_lower = "aábcdeéfghiíjklmnñoópqrstuúüvwxyz"
    local utf8_upper = "AÁBCDEÉFGHIÍJKLMNÑOÓPQRSTUÚÜVWXYZ"
    local res = ""
    local success = pcall(function()
        for p, c in utf8.codes(str) do
            local ch = utf8.char(c)
            local idx = utf8_lower:find(ch, 1, true)
            if idx then
                res = res .. utf8_upper:sub(idx, idx + #ch - 1)
            else
                res = res .. string.upper(ch)
            end
        end
    end)
    if not success then return string.upper(str) end
    return res
end

VIRTUSMENU = VIRTUSMENU or {}
VIRTUSMENU.CustomBinds = VIRTUSMENU.CustomBinds or {}

local bindFile = "virtus_custom_binds.txt"

function VIRTUSMENU.LoadBinds()
    if file.Exists(bindFile, "DATA") then
        local content = file.Read(bindFile, "DATA")
        VIRTUSMENU.CustomBinds = util.JSONToTable(content) or {}
    else
        VIRTUSMENU.CustomBinds = {}
    end
end

function VIRTUSMENU.SaveBinds()
    file.Write(bindFile, util.TableToJSON(VIRTUSMENU.CustomBinds))
end

function VIRTUSMENU.AddBind(keyNum, cmd)
    VIRTUSMENU.CustomBinds[tostring(keyNum)] = cmd
    VIRTUSMENU.SaveBinds()
end

function VIRTUSMENU.RemoveBind(keyNum)
    VIRTUSMENU.CustomBinds[tostring(keyNum)] = nil
    VIRTUSMENU.SaveBinds()
end

local lastPressed = {}
hook.Add("Think", "Virtus_CustomBinds_Think", function()
    if vgui.CursorVisible() then return end
    
    for keyStr, cmd in pairs(VIRTUSMENU.CustomBinds) do
        local key = tonumber(keyStr)
        if input.IsKeyDown(key) then
            if not lastPressed[key] then
                lastPressed[key] = true
                LocalPlayer():ConCommand(cmd)
            end
        else
            lastPressed[key] = false
        end
    end
end)

VIRTUSMENU.LoadBinds()
surface.CreateFont("VIRTUS_LogoFont_Large", { font = "SF Distant Galaxy", size = 65, weight = 800, antialias = true, extended = true })
surface.CreateFont("VIRTUS_LogoFont_Small", { font = "SF Distant Galaxy", size = 45, weight = 800, antialias = true, extended = true })
CreateClientConVar("virtus_vfx_volume", "0.5", true, false)
CreateClientConVar("virtus_radio_enabled", "1", true, false)
CreateClientConVar("virtus_radio_vol", "0.5", true, false)

function VIRTUSMENU.PlayUI(soundName)
    local vol = GetConVar("virtus_vfx_volume") and GetConVar("virtus_vfx_volume"):GetFloat() or 0.5
    if vol > 0 then
        LocalPlayer():EmitSound(soundName, 75, 100, vol)
    end
end

function VIRTUSMENU.Query(text, title, btn1Text, btn1Func, btn2Text, btn2Func)
    local frame = vgui.Create('DFrame')
    frame:SetSize(450, 160)
    frame:Center()
    frame:SetTitle('')
    frame:MakePopup()
    frame:SetDrawOnTop(true)
    frame:ShowCloseButton(false)
    frame.Paint = function(s, w, h)
        if _G.VIRTUS_DrawHoloBackground then _G.VIRTUS_DrawHoloBackground(w, h) end
        draw.SimpleText(title, 'VF4_Medium', w/2, 25, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(Color(255, 255, 255, 20))
        surface.DrawRect(20, 45, w - 40, 1)
    end
    local lbl = vgui.Create('DLabel', frame)
    lbl:SetFont('VF4_Small')
    lbl:SetText(text)
    lbl:SetTextColor(color_white)
    lbl:SetContentAlignment(5)
    lbl:SetWrap(true)
    lbl:SetPos(20, 55)
    lbl:SetSize(frame:GetWide() - 40, 50)
    local btn1 = vgui.Create('DButton', frame)
    btn1:SetSize(150, 30)
    btn1:SetPos(frame:GetWide()/2 - 160, 115)
    btn1:SetText(SafeUpper(btn1Text))
    btn1:SetFont('VF4_Small')
    btn1:SetTextColor(color_white)
    btn1.Paint = function(s, w, h)
        if _G.VIRTUS_DrawHoloButton then _G.VIRTUS_DrawHoloButton(w, h, s:IsHovered()) end
    end
    btn1.DoClick = function() frame:Remove() if btn1Func then btn1Func() end end
    if btn2Text then
        local btn2 = vgui.Create('DButton', frame)
        btn2:SetSize(150, 30)
        btn2:SetPos(frame:GetWide()/2 + 10, 115)
        btn2:SetText(SafeUpper(btn2Text))
        btn2:SetFont('VF4_Small')
        btn2:SetTextColor(color_white)
        btn2.Paint = btn1.Paint
        btn2.DoClick = function() frame:Remove() if btn2Func then btn2Func() end end
    else
        btn1:SetPos(frame:GetWide()/2 - 75, 115)
    end
end

function VIRTUSMENU.StyleScroll(scroll)
    local sbar = scroll:GetVBar()
    sbar:SetWide(6)
    sbar:SetHideButtons(true)
    sbar.Paint = function(s, w, h) end
    sbar.btnUp.Paint = function(s, w, h) end
    sbar.btnDown.Paint = function(s, w, h) end
    sbar.btnGrip.Paint = function(s, w, h)
        local col = s:IsHovered() and Color(255, 170, 0, 200) or Color(150, 150, 150, 50)
        draw.RoundedBox(3, 0, 0, w, h, col)
    end
end

CreateClientConVar("virtus_texture_quality", "0", true, false)
CreateClientConVar("virtus_hide_hud", "0", true, false)
CreateClientConVar("virtus_hide_compass", "0", true, false)
CreateClientConVar("virtus_netgraph_enable", "0", true, false)
CreateClientConVar("virtus_netgraph_detailed", "0", true, false)

hook.Add("HUDShouldDraw", "VIRTUS_CinematicMode", function(name)
    if GetConVar("virtus_hide_hud") and GetConVar("virtus_hide_hud"):GetBool() then
        if name == "CHudChat" or name == "CHudGMod" then return true end
        return false
    end
end)

-- Hook para abrir/cerrar menu con ESC
hook.Add("PreRender", "virtus_menu_hook", function()
    -- Verificamos si el usuario presiona ESC
    if input.IsKeyDown(KEY_ESCAPE) and gui.IsGameUIVisible() then
        -- Evitamos que se ejecute en cada frame mientras la tecla sigue presionada
        if not VIRTUSMENU.Debounce then
            VIRTUSMENU.Debounce = true
            
            if IsValid(VIRTUSMENU.EscapeMenu) then
                gui.HideGameUI()
                VIRTUSMENU.EscapeMenu:Remove()
            else
                gui.HideGameUI()
                VIRTUSMENU.openMenu()
            end
        end
    else
        -- Reseteamos el debounce al soltar la tecla
        VIRTUSMENU.Debounce = false
    end
end)


local stars = {}
-- Creamos 250 estrellas aleatorias para mejor inmersin espacial
for i = 1, 250 do
    local r = math.random(1, 100)
    local col = Color(255, 255, 255, 255)
    if r > 90 then col = Color(150, 200, 255, 255) -- Azuladas
    elseif r < 10 then col = Color(255, 200, 150, 255) end -- Anaranjadas

    table.insert(stars, {
        x = math.random(0, ScrW() * 2),
        y = math.random(0, ScrH() * 2),
        size = math.random(1, 2) + (math.random() > 0.9 and 1 or 0),
        speed = math.random() * 2 + 0.1,
        color = col,
        blink_speed = math.random() * 3 + 1
    })
end

function VIRTUSMENU.DrawStars(w, h)
    local time = SysTime()
    draw.NoTexture()
    for _, star in ipairs(stars) do
        -- Movimiento lateral suave (efecto 3D parallax)
        local x = (star.x + (time * star.speed * 8)) % w
        
        -- El brillo parpadea suavemente
        local alpha = (math.sin(time * star.blink_speed + star.x) + 1) / 2
        alpha = alpha * 150 + 50 -- Rango de 50 a 200
        
        surface.SetDrawColor(star.color.r, star.color.g, star.color.b, alpha)
        surface.DrawRect(x, star.y % h, star.size, star.size)
    end
end

local asteroidModels = {
    "models/props_wasteland/rockgranite03b.mdl",
    "models/props_wasteland/rockgranite03c.mdl",
    "models/props_wasteland/rockgranite02a.mdl",
    "models/props_wasteland/rockcliff01b.mdl",
    "models/props_debris/concrete_chunk01a.mdl",
    "models/props_debris/concrete_chunk08a.mdl"
}

VIRTUSMENU.AsteroidEnts = VIRTUSMENU.AsteroidEnts or {}

function VIRTUSMENU.CreateAsteroids()
    VIRTUSMENU.ClearAsteroids()
    for i = 1, 35 do
        local mdl = table.Random(asteroidModels)
        if not util.IsValidModel(mdl) then mdl = "models/props_junk/rock001a.mdl" end
        
        local ent = ClientsideModel(mdl)
        if not IsValid(ent) then continue end
        ent:SetNoDraw(true)
        
        local dist = 100 + (math.random() ^ 2) * 2500 -- More rocks farther away
        local scl = (math.random() * 0.8 + 0.2) * (dist / 400) -- Farther rocks appear somewhat scaled appropriately
        if scl > 6 then scl = 6 end
        if scl < 0.2 then scl = 0.2 end
        
        table.insert(VIRTUSMENU.AsteroidEnts, {
            ent = ent,
            pos = Vector(dist, math.random(-2000, 2000), math.random(-1500, 1500)),
            vel = Vector(math.random(-15, -60), math.random(-10, 10), math.random(-10, 10)),
            ang = Angle(math.random(0, 360), math.random(0, 360), math.random(0, 360)),
            angVel = Angle(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10)),
            scale = scl
        })
        ent:SetModelScale(VIRTUSMENU.AsteroidEnts[#VIRTUSMENU.AsteroidEnts].scale, 0)
    end
end

function VIRTUSMENU.ClearAsteroids()
    for _, ast in ipairs(VIRTUSMENU.AsteroidEnts) do
        if IsValid(ast.ent) then ast.ent:Remove() end
    end
    VIRTUSMENU.AsteroidEnts = {}
end

function VIRTUSMENU.DrawAsteroids()
    if #VIRTUSMENU.AsteroidEnts == 0 then return end
    
    local ft = FrameTime()
    
    cam.Start3D(Vector(-200, 0, 0), Angle(0, 0, 0), 90, 0, 0, ScrW(), ScrH())
        render.SuppressEngineLighting(true)
        render.SetLightingOrigin(Vector(0, 0, 0))
        
        -- Iluminacion cinemática: Cyan profundo y Naranja rojizo
        render.ResetModelLighting(0.05, 0.05, 0.1)
        render.SetModelLighting(BOX_TOP, 0.2, 0.5, 0.9) -- Luz azul/cyan principal
        render.SetModelLighting(BOX_FRONT, 0.1, 0.3, 0.6)
        render.SetModelLighting(BOX_RIGHT, 0.8, 0.3, 0.1) -- Luz de borde naranja (rim light)
        render.SetModelLighting(BOX_BOTTOM, 0.0, 0.0, 0.05)
        
        for _, ast in ipairs(VIRTUSMENU.AsteroidEnts) do
            if IsValid(ast.ent) then
                ast.pos = ast.pos + (ast.vel * ft)
                ast.ang = ast.ang + (ast.angVel * ft)
                
                -- Respawn when off screen
                if ast.pos.x < -300 or math.abs(ast.pos.y) > 2000 or math.abs(ast.pos.z) > 1500 then
                    ast.pos = Vector(math.random(1500, 2500), math.random(-1500, 1500), math.random(-1000, 1000))
                end
                
                ast.ent:SetPos(ast.pos)
                ast.ent:SetAngles(ast.ang)
                ast.ent:DrawModel()
            end
        end
        render.SuppressEngineLighting(false)
    cam.End3D()
end

-- FIX: bloquearTodo declarado antes de openMenu para que OnRemove pueda referenciarlo
local bloquearTodo = true

-- Materiales cacheados para rendimiento (no crear Material() dentro de Paint)
local matGradientU = Material("vgui/gradient-u")

VIRTUSMENU.SettingsPanel = nil

function VIRTUSMENU.PlayStarWarsCredits()
    if not IsValid(VIRTUSMENU.EscapeMenu) then return end
    
    local children = VIRTUSMENU.EscapeMenu:GetChildren()
    for _, child in ipairs(children) do
        if child.SetAlpha and child:IsVisible() then
            child:AlphaTo(0, 1, 0)
            if child.SetMouseInputEnabled then child:SetMouseInputEnabled(false) end
        end
    end
    
    -- Crear el panel de creditos
    local creditsPnl = vgui.Create("DPanel", VIRTUSMENU.EscapeMenu)
    creditsPnl:SetSize(ScrW(), ScrH())
    creditsPnl:SetPos(0, 0)
    creditsPnl:SetZPos(9999)
    creditsPnl.StartTime = SysTime() + 1 -- start text scrolling after transition
    creditsPnl:SetAlpha(0)
    creditsPnl:AlphaTo(255, 1, 0)
    
    timer.Simple(1, function()
        if not IsValid(VIRTUSMENU.EscapeMenu) then return end
        for _, child in ipairs(children) do
            if IsValid(child) and child ~= creditsPnl and child.SetVisible then
                child:SetVisible(false)
            end
        end
    end)
    
    surface.CreateFont("StarWars_CreditsName", { font = "SF Distant Galaxy", size = 45, weight = 800, antialias = true, extended = true })
    surface.CreateFont("StarWars_CreditsTitle", { font = "SF Distant Galaxy", size = 70, weight = 800, antialias = true, extended = true })

    local colorYellow = Color(255, 213, 79)
    local colorText = Color(200, 200, 200)

    local swLines = {
        { text = "VIRTUS", font = "StarWars_CreditsTitle", color = colorYellow },
        { text = "STUDIOS", font = "StarWars_CreditsName", color = colorYellow },
        { text = "", font = "StarWars_CreditsName" },
        { text = "Hace mucho tiempo, en una galaxia", font = "VF4_TitleBig", color = colorText },
        { text = "muy, muy lejana...", font = "VF4_TitleBig", color = colorText },
        { text = "", font = "StarWars_CreditsName" },
        { text = "Un proyecto nacio de la pasion y la dedicacion", font = "VF4_Header", color = colorText },
        { text = "inquebrantable de un grupo de visionarios.", font = "VF4_Header", color = colorText },
        { text = "Lo que comenzo como una simple idea en el borde", font = "VF4_Header", color = colorText },
        { text = "exterior, termino forjando un Imperio.", font = "VF4_Header", color = colorText },
        { text = "", font = "StarWars_CreditsName" },
        { text = "Queremos expresar nuestro mas profundo agradecimiento", font = "VF4_Header", color = colorText },
        { text = "a cada una de las personas que han formado parte", font = "VF4_Header", color = colorText },
        { text = "de esta increible aventura.", font = "VF4_Header", color = colorText },
        { text = "", font = "StarWars_CreditsName" },
        { text = "Desde las innumerables horas de desarrollo,", font = "VF4_Header", color = colorText },
        { text = "diseno, y configuracion, hasta las noches", font = "VF4_Header", color = colorText },
        { text = "enteras resolviendo errores en el codigo...", font = "VF4_Header", color = colorText },
        { text = "cada segundo invertido ha valido la pena.", font = "VF4_Header", color = colorText },
        { text = "", font = "StarWars_CreditsName" },
        { text = "--- ALTO MANDO Y DESARROLLO ---", font = "VF4_TitleBig", color = colorYellow },
        { text = "", font = "StarWars_CreditsName" },
        { text = "ALIX", font = "StarWars_CreditsName", color = colorYellow },
        { text = "KARBO", font = "StarWars_CreditsName", color = colorYellow },
        { text = "DOC", font = "StarWars_CreditsName", color = colorYellow },
        { text = "DAVID", font = "StarWars_CreditsName", color = colorYellow },
        { text = "CHICHO", font = "StarWars_CreditsName", color = colorYellow },
        { text = "LUCHO", font = "StarWars_CreditsName", color = colorYellow },
        { text = "HUNTER", font = "StarWars_CreditsName", color = colorYellow },
        { text = "NUKE", font = "StarWars_CreditsName", color = colorYellow },
        { text = "", font = "StarWars_CreditsName" },
        { text = "--- ADMINISTRACION Y SOPORTE ---", font = "VF4_TitleBig", color = colorYellow },
        { text = "", font = "StarWars_CreditsName" },
        { text = "A todo el equipo de Staff que se asegura de", font = "VF4_Header", color = colorText },
        { text = "mantener la paz y el orden en la galaxia.", font = "VF4_Header", color = colorText },
        { text = "", font = "StarWars_CreditsName" },
        { text = "--- NUESTRA COMUNIDAD ---", font = "VF4_TitleBig", color = colorYellow },
        { text = "", font = "StarWars_CreditsName" },
        { text = "A todos los soldados, comandantes, pilotos", font = "VF4_Header", color = colorText },
        { text = "y ciudadanos que le dan vida al servidor.", font = "VF4_Header", color = colorText },
        { text = "Ustedes son el verdadero motor del Imperio.", font = "VF4_Header", color = colorText },
        { text = "Sin su lealtad, nada de esto existiria.", font = "VF4_Header", color = colorText },
        { text = "", font = "StarWars_CreditsName" },
        { text = "", font = "StarWars_CreditsName" },
        { text = "QUE LA FUERZA LOS ACOMPAñE, SIEMPRE!", font = "VF4_TitleBig", color = colorYellow },
        { text = "", font = "StarWars_CreditsName" },
    }
    
    creditsPnl.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(5, 5, 10, 255))
        VIRTUSMENU.DrawStars(w, h)
        
        local timeElapsed = SysTime() - s.StartTime
        if timeElapsed < 0 then timeElapsed = 0 end
        
        local scrollSpeed = 60
        local yOffset = h + 100 - (timeElapsed * scrollSpeed)
        
        local currentY = yOffset
        for _, line in ipairs(swLines) do
            if line.text ~= "" then
                draw.SimpleText(line.text, line.font, w/2, currentY, line.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
            surface.SetFont(line.font)
            local _, th = surface.GetTextSize(line.text ~= "" and line.text or "A")
            currentY = currentY + th + 15
        end
        
        surface.SetMaterial(Material("vgui/gradient-u"))
        surface.SetDrawColor(5, 5, 10, 255)
        surface.DrawTexturedRect(0, 0, w, h * 0.25)
    end
    
    local backBtn = vgui.Create("DButton", creditsPnl)
    backBtn:SetSize(200, 40)
    backBtn:SetPos(ScrW()/2 - 100, ScrH() - 70)
    backBtn:SetText("VOLVER AL MENU")
    backBtn:SetFont("VF4_Medium")
    backBtn:SetTextColor(Color(255, 255, 255))
    backBtn:SetAlpha(0)
    backBtn:AlphaTo(255, 1, 1) -- Fade in the button after 1 second (when transition ends)
    backBtn.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, s:IsHovered() and Color(0, 150, 255) or Color(30, 30, 30))
        surface.SetDrawColor(0, 150, 255, 100)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
    backBtn.DoClick = function()
        if VIRTUSMENU.PlayUI then VIRTUSMENU.PlayUI("navigation/aceptar.wav") end
        
        creditsPnl:AlphaTo(0, 0.5, 0, function()
            if IsValid(creditsPnl) then creditsPnl:Remove() end
        end)
        for _, child in ipairs(children) do
            if IsValid(child) and child ~= creditsPnl and child.SetVisible then
                child:SetVisible(true)
                if child.SetAlpha then child:AlphaTo(255, 0.5, 0) end
                if child.SetMouseInputEnabled then child:SetMouseInputEnabled(true) end
            end
        end
    end
end

function VIRTUSMENU.openMenu(startTab)
    if IsValid(VIRTUSMENU.EscapeMenu) then return end

    VIRTUSMENU.EscapeMenu = vgui.Create("DPanel")
    VIRTUSMENU.EscapeMenu:SetSize(ScrW(), ScrH())
    VIRTUSMENU.EscapeMenu.OnMousePressed = function(s, kc)
        if IsValid(VIRTUSMENU.ActiveDropdown) then VIRTUSMENU.ActiveDropdown:Remove() end
    end
    VIRTUSMENU.EscapeMenu:MakePopup()
    VIRTUSMENU.CreateAsteroids()

    VIRTUSMENU.EscapeMenu.WipeFraction = 1

    VIRTUSMENU.EscapeMenu.Paint = function(self, w, h)
        if self.WipeFraction and self.WipeFraction < 1 then
            local wipeX = w * self.WipeFraction
            render.SetScissorRect(0, 0, wipeX, h, true)
        end
        
        local scrX, scrY = self:LocalToScreen(0, 0)
        
        -- Ignoramos el clipping para que el fondo llene la pantalla incluso si el panel se mueve
        DisableClipping(true)
        
        local mat = Matrix()
        mat:Translate(Vector(-scrX, -scrY, 0))
        
        cam.PushModelMatrix(mat)
        -- Fondo negro espacio profundo
        draw.RoundedBox(0, 0, 0, ScrW(), ScrH(), Color(5, 5, 10))
        
        -- Estrellas
        VIRTUSMENU.DrawStars(ScrW(), ScrH())
        VIRTUSMENU.DrawAsteroids()
        cam.PopModelMatrix()
        
        -- Blur
        Derma_DrawBackgroundBlur(self, SysTime())
        
        -- Vieta oscura en los bordes para mayor inmersin
        cam.PushModelMatrix(mat)
        surface.SetDrawColor(0, 0, 0, 120)
        local scrW, scrH = ScrW(), ScrH()
        surface.SetMaterial(Material("vgui/gradient-u"))
        surface.DrawTexturedRect(0, 0, scrW, scrH * 0.15)
        surface.SetMaterial(Material("vgui/gradient-d"))
        surface.DrawTexturedRect(0, scrH * 0.85, scrW, scrH * 0.15)
        
        surface.SetMaterial(Material("vgui/gradient-l"))
        surface.DrawTexturedRect(scrW * 0.85, 0, scrW * 0.15, scrH)
        surface.SetMaterial(Material("vgui/gradient-r"))
        surface.DrawTexturedRect(0, 0, scrW * 0.15, scrH)
        
        -- Global Ambient Glow Blue (Fondo ms suave y concentrado abajo para evitar banding)
        surface.SetMaterial(Material("vgui/gradient-d"))
        surface.SetDrawColor(0, 150, 255, 10)
        surface.DrawTexturedRect(0, scrH * 0.5, scrW, scrH * 0.5)
        
        cam.PopModelMatrix()
        
        -- Logo Virtus Studios (Limpio, sin borde negro grueso, con sombra suave)
        draw.SimpleText("VIRTUS", "VIRTUS_LogoFont_Large", 82, 22, Color(0, 0, 0, 150), 0, 0)
        draw.SimpleText("VIRTUS", "VIRTUS_LogoFont_Large", 80, 20, Color(255, 255, 255), 0, 0)
        
        draw.SimpleText("STUDIOS", "VIRTUS_LogoFont_Small", 87, 72, Color(0, 0, 0, 150), 0, 0)
        draw.SimpleText("STUDIOS", "VIRTUS_LogoFont_Small", 85, 70, Color(0, 150, 255), 0, 0)
        
        DisableClipping(false)
    end
    
    VIRTUSMENU.EscapeMenu.PaintOver = function(self, w, h)
        if self.WipeFraction and self.WipeFraction < 1 then
            render.SetScissorRect(0, 0, 0, 0, false)
        end

    end
    
    local currentTab = "INICIO"
    VIRTUSMENU.CurrentTab = currentTab
    
    -- Configuramos el panel principal (contenedor de pestanas)
    local mainContainer = vgui.Create("DPanel", VIRTUSMENU.EscapeMenu)
    mainContainer:SetPos(80, 150)
    mainContainer:SetSize(ScrW() * 0.58, ScrH() - 380)
    mainContainer.Paint = nil

        local function CreateCard(parent, title, subtitle, x, y, w, h, isMain, func)
        local btn = vgui.Create("DButton", parent)
        btn:SetSize(w, h)
        btn:SetPos(x, y)
        btn:SetText("")
        btn.HoverP = 0
        btn.OnCursorEntered = function(s) VIRTUSMENU.PlayUI("navigation/movimiento.wav") end
        btn.Paint = function(s, pw, ph)
            s.HoverP = Lerp(FrameTime() * 10, s.HoverP, s:IsHovered() and 1 or 0)
            
            local c = isMain and Color(255, 170, 0) or Color(0, 150, 255)
            
            -- 1. FONDO OSCURO CON BORDE REDONDEADO
            local bordeAlpha = 100 + s.HoverP * 155
            draw.RoundedBox(8, 0, 0, pw, ph, Color(c.r, c.g, c.b, bordeAlpha))
            
            local interiorAlpha = 245 - (s.HoverP * 15)
            draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(12, 16, 22, interiorAlpha))
            
            if s.HoverP > 0.01 then
                draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(c.r, c.g, c.b, s.HoverP * 40))
            end
            
            -- =================================================================== --
            -- 2. MAPA ESTELAR HOLOGRAFICO (UNICO Y CON MOVIMIENTO CONDICIONAL)
            -- =================================================================== --
            -- Generar un valor único (seed) basado en el texto del botón
            local seed = 0
            for i = 1, #title do seed = seed + string.byte(title, i) end
            
            -- Centros y radios únicos por cada tarjeta
            local mapX = pw * (0.4 + ((seed % 40) / 100)) -- Centro X varía
            local mapY = ph * (0.3 + ((seed % 30) / 100)) -- Centro Y varía
            local r1 = 60 + (seed % 20)
            local r2 = 140 + (seed % 40)
            local r3 = 260 + (seed % 60)
            
            -- Lógica de animación: acelera suavemente al hacer hover, y se detiene suavemente al salir
            s.MapSpeed = s.MapSpeed or 0
            s.MapAnim = s.MapAnim or 0
            s.MapSpeed = Lerp(FrameTime() * 5, s.MapSpeed, s:IsHovered() and 1 or 0)
            s.MapAnim = s.MapAnim + (FrameTime() * s.MapSpeed) -- El tiempo avanza según la velocidad
            
            local mapAlpha = 30 + (s.HoverP * 70) 
            surface.SetDrawColor(c.r, c.g, c.b, mapAlpha)

            local function DrawOrbit(cx, cy, radius, dashed)
                local step = 3
                local lastX, lastY = cx + radius, cy
                for i = step, 360, step do
                    local rad = math.rad(i)
                    local curX = cx + math.cos(rad) * radius
                    local curY = cy + math.sin(rad) * radius
                    if not dashed or (i % 12 < 6) then
                        surface.DrawLine(lastX, lastY, curX, curY)
                    end
                    lastX, lastY = curX, curY
                end
            end
            
            local function DrawTicks(cx, cy, radius, count, length, offset)
                local step = 360 / count
                for i = 0, 360, step do
                    local ang = math.rad(i + offset)
                    local cosA, sinA = math.cos(ang), math.sin(ang)
                    surface.DrawLine(cx + cosA * radius, cy + sinA * radius, cx + cosA * (radius + length), cy + sinA * (radius + length))
                end
            end
            
            local function DrawDiamond(cx, cy, size)
                local poly = {
                    {x = cx, y = cy - size}, {x = cx + size, y = cy},
                    {x = cx, y = cy + size}, {x = cx - size, y = cy}
                }
                surface.DrawPoly(poly)
            end

            -- Núcleo estelar (Sol)
            surface.SetDrawColor(c.r, c.g, c.b, mapAlpha * 1.5)
            DrawOrbit(mapX, mapY, 8, false)
            DrawDiamond(mapX, mapY, 6)
            surface.SetDrawColor(c.r, c.g, c.b, mapAlpha * 0.4)
            DrawOrbit(mapX, mapY, 15, false)

            surface.SetDrawColor(c.r, c.g, c.b, mapAlpha)
            DrawOrbit(mapX, mapY, r1, false)
            DrawOrbit(mapX, mapY, r2, true) -- Orbita media punteada
            DrawOrbit(mapX, mapY, r3, false)

            -- Líneas orbitales transversales (Radar style)
            local axisRot = (s.MapAnim * 10) + (seed % 90)
            for i = 0, 3 do
                local ang = math.rad(axisRot + (i * 45))
                local lx = math.cos(ang) * 500
                local ly = math.sin(ang) * 500
                surface.SetDrawColor(c.r, c.g, c.b, mapAlpha * 0.5)
                surface.DrawLine(mapX - lx, mapY - ly, mapX + lx, mapY + ly)
            end

            surface.SetDrawColor(c.r, c.g, c.b, mapAlpha * 2)

            -- Anillo Interior: Nodo 1 (Estación Espacial)
            local rot1 = (s.MapAnim * 20 * (seed % 2 == 0 and 1 or -1))
            DrawTicks(mapX, mapY, r1, 8, 8, rot1)
            local n1Rad = math.rad(rot1 * 1.5 + seed)
            local nx1, ny1 = mapX + math.cos(n1Rad) * r1, mapY + math.sin(n1Rad) * r1
            DrawDiamond(nx1, ny1, 5)
            surface.DrawOutlinedRect(nx1 - 8, ny1 - 8, 16, 16)
            surface.DrawLine(nx1, ny1 - 8, nx1, ny1 + 8)

            -- Anillo Medio: Nodo 2 (Planeta enano)
            local rot2 = (s.MapAnim * 15 * (seed % 3 == 0 and 1 or -1))
            DrawTicks(mapX, mapY, r2, 16, -6, rot2)
            local n2Rad = math.rad(rot2 * -0.8 + (seed * 2))
            local nx2, ny2 = mapX + math.cos(n2Rad) * r2, mapY + math.sin(n2Rad) * r2
            surface.DrawRect(nx2 - 3, ny2 - 3, 6, 6)
            DrawOrbit(nx2, ny2, 10, false)

            -- Anillo Exterior: Planeta con luna
            local n3Rad = math.rad((s.MapAnim * 8) + seed)
            local nx3, ny3 = mapX + math.cos(n3Rad) * r3, mapY + math.sin(n3Rad) * r3
            DrawDiamond(nx3, ny3, 7)
            
            local moonRad = math.rad(s.MapAnim * 50)
            local mx, my = nx3 + math.cos(moonRad)*14, ny3 + math.sin(moonRad)*14
            surface.DrawRect(mx - 2, my - 2, 4, 4)
            DrawOrbit(nx3, ny3, 14, true)
            -- =================================================================== --
            
            -- 3. BORDES BRILLANTES (Removido por peticion)
            
            -- 4. TEXTOS E ICONOS
            local push = s.HoverP * 10
            draw.SimpleText(title, "VF4_TitleBig", 25 + push, 25, Color(255, 255, 255, 255), 0, 0)
            
            if subtitle then draw.SimpleText(title, "VF4_Subtitle_Aurebesh", 27 + push, 68, Color(150, 150, 150, 255), 0, 0) end
            
            if title == "DISCORD" or title == "FACCIONES" then
                local matStr = title == "DISCORD" and "virtus/discord" or "virtus/imperio"
                local mat = Material(matStr, "smooth")
                surface.SetMaterial(mat)
                local lightFact = Lerp(s.HoverP, 0.4, 1)
                surface.SetDrawColor(c.r * lightFact, c.g * lightFact, c.b * lightFact, 255)
                local isz = (title == "FACCIONES") and 220 or 100
                
                s.IconTime = s.IconTime or 0
                if s:IsHovered() then
                    s.IconTime = s.IconTime + FrameTime() * 4
                else
                    local rem = s.IconTime % (math.pi * 2)
                    if rem > math.pi then rem = rem - (math.pi * 2) end
                    s.IconTime = Lerp(FrameTime() * 10, rem, 0)
                end
                
                local cosVal = math.cos(s.IconTime)
                local scale = math.abs(cosVal)
                local currentW = isz * scale
                local cx = (title == "FACCIONES") and (pw / 2) or (pw - isz/2 - 40)
                local cy = ph / 2
                local rx = cx - currentW / 2
                local ry = cy - isz / 2
                
                if cosVal > 0 then
                    surface.DrawTexturedRectUV(rx, ry, currentW, isz, 0, 0, 1, 1)
                else
                    surface.DrawTexturedRectUV(rx, ry, currentW, isz, 1, 0, 0, 1)
                end
            end
            
            local actionText = isMain and "> INICIAR DESPLIEGUE" or "> ACCEDER"
            local actionColor = Color(c.r, c.g, c.b, 150 + s.HoverP * 105)
            draw.SimpleText(actionText, "VF4_Medium", pw - 25, ph - 25, actionColor, 2, 1)
        end
        btn.DoClick = function(s)
            VIRTUSMENU.PlayUI("navigation/aceptar.wav")
            if func then func() end
        end
        return btn
    end

    local function CreateSocialPopup(x, y, w, h, title, buildFunc)
        if IsValid(VIRTUSMENU.SocialPopup) then VIRTUSMENU.SocialPopup:Remove() end
        if IsValid(VIRTUSMENU.SocialOverlay) then VIRTUSMENU.SocialOverlay:Remove() end
        local close = vgui.Create("DButton", VIRTUSMENU.EscapeMenu)
        close:SetSize(ScrW(), ScrH())
        close:MoveToBack()
        close:SetText("")
        close.Paint = function() end
        VIRTUSMENU.SocialOverlay = close
        local pop = vgui.Create("DPanel", VIRTUSMENU.EscapeMenu)
        pop:SetPos(x, y)
        pop:SetSize(w, h)
        pop:SetZPos(100)
        pop.Paint = function(s, pw, ph)
            draw.RoundedBox(8, 0, 0, pw, ph, Color(255, 170, 0, 100))
            draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(15, 15, 15, 245))
            draw.SimpleText(title, "VF4_Medium", 15, 15, Color(255,255,255), 0, 1)
        end
        VIRTUSMENU.SocialPopup = pop
        if buildFunc then buildFunc(pop) end
    end

    local function SwitchTab(tabID)
        if IsValid(VIRTUSMENU.ActiveDropdown) then VIRTUSMENU.ActiveDropdown:Remove() end
        currentTab = tabID
        VIRTUSMENU.CurrentTab = tabID
        mainContainer:Clear()
        
        local targetH = ScrH() - 380
        if tabID == "FACCIONES" or tabID == "AJUSTES" or tabID == "PROGRESO" then
            targetH = ScrH() - 230
        elseif tabID == "CARRERA" then
            targetH = ScrH() - 280
        elseif tabID == "BARRACON" then
            targetH = ScrH() - 250
        end

        if tabID == "FACCIONES" or tabID == "PROGRESO" then
            if IsValid(VIRTUSMENU.EscapeMenu.ClonePanel) then
                VIRTUSMENU.EscapeMenu.ClonePanel:SetVisible(false)
            end
            mainContainer:SetSize(ScrW() * 0.90, targetH)
            mainContainer:SetPos(50, 150)
        elseif tabID == "BARRACON" then
            if IsValid(VIRTUSMENU.EscapeMenu.ClonePanel) then
                VIRTUSMENU.EscapeMenu.ClonePanel:SetVisible(true)
            end
            mainContainer:SetSize(ScrW() * 0.90, targetH)
            mainContainer:SetPos(50, 150)
        else
            if IsValid(VIRTUSMENU.EscapeMenu.ClonePanel) then
                VIRTUSMENU.EscapeMenu.ClonePanel:SetVisible(true)
            end
            mainContainer:SetSize(ScrW() * 0.60, targetH)
            mainContainer:SetPos(80, 150)
        end
        
        mainContainer:SetAlpha(0)
        mainContainer:AlphaTo(255, 0.4, 0)
        
        if tabID == "INICIO" then
            local ply = LocalPlayer()
            local w = mainContainer:GetWide()
            local h = mainContainer:GetTall()
            local space = 20
            local col1 = 0
            local col2 = w * 0.48
            local secCardH = (h - space) / 2
            
            -- Facciones toma casi todo el alto, dejando espacio para Reanudar
            local faccionesH = h - 60
            CreateCard(mainContainer, "FACCIONES", "ROLES Y GRUPOS", col1, 0, col2, faccionesH, true, function() SwitchTab("FACCIONES") end)
            
            local reBtn = vgui.Create("DButton", mainContainer)
            reBtn:SetSize(col2, 45)
            reBtn:SetPos(col1, faccionesH + 15)
            reBtn:SetText("")
            reBtn:SetFont("VF4_Medium")
            reBtn:SetTextColor(Color(255,255,255))
            reBtn.HoverP = 0
            reBtn.Paint = function(s, pw, ph)
                s.HoverP = Lerp(FrameTime() * 10, s.HoverP or 0, s:IsHovered() and 1 or 0)
                local c = Color(0, 150, 255) -- Standard blue instead of green
                
                local bordeAlpha = 50 + s.HoverP * 150
                draw.RoundedBox(8, 0, 0, pw, ph, Color(c.r, c.g, c.b, bordeAlpha))
                
                draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(15, 15, 15, 220))
                
                if s.HoverP > 0.01 then
                    draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(c.r, c.g, c.b, s.HoverP * 40))
                end
                
                local txtCol = Color(200 + 55 * s.HoverP, 200 + 55 * s.HoverP, 255)
                draw.SimpleText("REANUDAR", "VF4_Medium", pw/2, ph/2, txtCol, 1, 1)
            end
            reBtn.DoClick = function()
                VIRTUSMENU.PlayUI("navigation/aceptar.wav")
                if IsValid(VIRTUSMENU.EscapeMenu) then VIRTUSMENU.EscapeMenu:Remove() end
            end
            
            CreateCard(mainContainer, "DONACIONES", "TIENDA OFICIAL", col1 + col2 + space, 0, w - (col2 + space), secCardH, false, function() 
                gui.OpenURL("https://tusitio.com") 
            end)
            
            CreateCard(mainContainer, "DISCORD", "RED DE COMUNICACIONES", col1 + col2 + space, secCardH + space, w - (col2 + space), secCardH, false, function() 
                gui.OpenURL("https://discord.gg/tu-link") 
            end)
            
        elseif tabID == "CARRERA" then
            local ply = LocalPlayer()
            local w = mainContainer:GetWide()
            local h = mainContainer:GetTall()
            
            local midX = 20
            local midW = math.min(w - 40, (ScrW() * 0.50) - 150)
            local centerX = midX + midW / 2
            
            local contentHeight = 710
            local startY = 0
            
            local infoPnl = vgui.Create("DPanel", mainContainer)
            infoPnl:SetPos(midX, startY)
            infoPnl:SetSize(midW, contentHeight)
            infoPnl.Paint = function(s, pw, ph) 
                local c = Color(0, 150, 255)
                draw.RoundedBox(8, 0, 0, pw, ph, Color(c.r, c.g, c.b, 100))
                draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(12, 16, 22, 245))
                
                surface.SetDrawColor(c.r, c.g, c.b, 5)
                for i=0, ph, 8 do 
                    surface.DrawLine(0, i, pw, i) 
                end
                
                -- Esquinas decorativas removidas por peticion
            end
            
            local innerMidW = infoPnl:GetWide()
            local innerCenterX = innerMidW / 2
            
            local avatarSize = 150
            local avatar = vgui.Create("AvatarImage", infoPnl)
            avatar:SetSize(avatarSize, avatarSize)
            avatar:SetPos(innerCenterX - avatarSize/2, 20)
            avatar:SetPlayer(ply, 256)
            
            local btnPerfil = vgui.Create("DButton", infoPnl)
            btnPerfil:SetSize(avatarSize, avatarSize)
            btnPerfil:SetPos(innerCenterX - avatarSize/2, 20)
            btnPerfil:SetText("")
            btnPerfil.Paint = function(s, pw, ph)
                s.HoverP = Lerp(FrameTime() * 10, s.HoverP or 0, s:IsHovered() and 1 or 0)
                if s.HoverP > 0.01 then
                    surface.SetDrawColor(0, 150, 255, s.HoverP * 50)
                    surface.DrawRect(0, 0, pw, ph)
                    draw.SimpleText("VER PERFIL", "VF4_Small", pw/2, ph/2, Color(255,255,255, s.HoverP * 255), 1, 1)
                end
                surface.SetDrawColor(0, 150, 255, 100)
                surface.DrawOutlinedRect(0, 0, pw, ph)
            end
            btnPerfil.DoClick = function()
                ply:ShowProfile()
            end
            
            local rankText = SafeUpper(ply:GetUserGroup())
            surface.SetFont("VF4_Medium")
            local rankW = surface.GetTextSize(rankText) + 30
            local rankLbl = vgui.Create("DLabel", infoPnl)
            rankLbl:SetText(rankText)
            rankLbl:SetFont("VF4_Medium")
            rankLbl:SetTextColor(Color(255, 255, 255))
            rankLbl:SetPos(innerCenterX - rankW/2, 185)
            rankLbl:SetSize(rankW, 30)
            rankLbl:SetContentAlignment(5)
            rankLbl.Paint = function(s, pw, ph)
                draw.RoundedBox(4, 0, 0, pw, ph, Color(0, 150, 255, 200))
            end
            
            local nameLbl = vgui.Create("DLabel", infoPnl)
            nameLbl:SetText(SafeUpper(ply:Nick()))
            nameLbl:SetFont("VF4_TitleBig")
            nameLbl:SetPos(0, 225)
            nameLbl:SetSize(innerMidW, 40)
            nameLbl:SetContentAlignment(5)
            
            local chevron = vgui.Create("DLabel", infoPnl)
            chevron:SetText(">>")
            chevron:SetFont("VF4_Medium")
            chevron:SetPos(0, 260)
            chevron:SetSize(innerMidW, 20)
            chevron:SetContentAlignment(5)
            chevron:SetTextColor(Color(0, 150, 255, 150))
            
            local lvl = ply.GetLevel and ply:GetLevel() or ply:GetNWInt("IVO_Level", 1)
            local lvlLbl = vgui.Create("DLabel", infoPnl)
            lvlLbl:SetText("NIVEL " .. lvl)
            lvlLbl:SetFont("VF4_TitleBig")
            lvlLbl:SetPos(0, 280)
            lvlLbl:SetSize(innerMidW, 40)
            lvlLbl:SetContentAlignment(5)
            
            local bar = vgui.Create("DPanel", infoPnl)
            bar:SetPos(70, 330)
            bar:SetSize(innerMidW - 140, 15)
            bar.TargetProgress = 0
            bar.CurProgress = 0
            bar.Paint = function(s, pw, ph)
                local xp = ply.GetXP and ply:GetXP() or ply:GetNWInt("IVO_XP", 0)
                local maxXp = IVO_SAM and IVO_SAM.GetXPNeededForLevel and IVO_SAM.GetXPNeededForLevel(lvl) or 100
                if maxXp <= 0 then maxXp = 100 end
                
                s.TargetProgress = math.Clamp(xp / maxXp, 0, 1)
                s.CurProgress = Lerp(FrameTime() * 2, s.CurProgress, s.TargetProgress)
                
                local c = Color(0, 150, 255)
                surface.SetDrawColor(10, 15, 25, 200)
                surface.DrawRect(0, 0, pw, ph)
                
                surface.SetDrawColor(c.r, c.g, c.b, 100)
                surface.DrawOutlinedRect(0, 0, pw, ph)
                
                local fillW = pw * s.CurProgress
                surface.SetDrawColor(c.r, c.g, c.b, 200 + math.sin(SysTime() * 4) * 55)
                surface.DrawRect(0, 0, fillW, ph)
                
                surface.SetDrawColor(0, 0, 0, 150)
                for i = 0, pw, 20 do
                    surface.DrawRect(i, 0, 2, ph)
                end
            end
            
            local xpLbl = vgui.Create("DLabel", infoPnl)
            xpLbl.Think = function(s)
                local xp = ply.GetXP and ply:GetXP() or ply:GetNWInt("IVO_XP", 0)
                local maxXp = IVO_SAM and IVO_SAM.GetXPNeededForLevel and IVO_SAM.GetXPNeededForLevel(lvl) or 100
                s:SetText(xp .. " / " .. maxXp)
            end
            xpLbl:SetFont("VF4_Small")
            xpLbl:SetPos(0, 347)
            xpLbl:SetSize(innerMidW, 20)
            xpLbl:SetContentAlignment(5)
            xpLbl:SetTextColor(Color(150, 150, 150))
            
            local multiLbl = vgui.Create("DLabel", infoPnl)
            multiLbl:SetText("MULTIJUGADOR")
            multiLbl:SetFont("VF4_TitleBig")
            multiLbl:SetPos(0, 370)
            multiLbl:SetSize(innerMidW, 40)
            multiLbl:SetContentAlignment(5)
            
            local stats = vgui.Create("DIconLayout", infoPnl)
            stats:SetPos(20, 410)
            stats:SetSize(innerMidW - 40, 160)
            stats:SetSpaceY(10)
            stats:SetSpaceX(10)
            
            local statW = (innerMidW - 50) / 2
            
            local function AddRawStat(title, val)
                local p = stats:Add("DPanel")
                p:SetSize(statW, 45)
                p.Paint = function(s, pw, ph)
                    draw.RoundedBox(0, 0, 0, pw, ph, Color(15, 20, 25, 200))
                    surface.SetDrawColor(0, 150, 255, 30)
                    surface.DrawOutlinedRect(0, 0, pw, ph)
                    surface.SetDrawColor(0, 150, 255, 150)
                    surface.DrawRect(0, 0, 3, ph)
                    
                    draw.SimpleText(title, "VF4_Small", 15, ph/2, Color(150, 150, 150), 0, 1)
                    draw.SimpleText(tostring(val), "VF4_Medium", pw - 15, ph/2, Color(255, 255, 255), 2, 1)
                end
                return p
            end
            
            AddRawStat("ASESINATOS", ply:GetNWInt("VIRTUS_TotalKills", 0))
            local kd = "0"
            local d = ply:GetNWInt("VIRTUS_TotalDeaths", 0)
            local k = ply:GetNWInt("VIRTUS_TotalKills", 0)
            if d > 0 then kd = tostring(math.Round(k / d, 2)) else kd = tostring(k) end
            AddRawStat("RATIO K/D", kd)
            
            local money = ply.getDarkRPVar and ply:getDarkRPVar("money") or 0
            local fnd = DarkRP and DarkRP.formatMoney(money) or ("$" .. money)
            AddRawStat("FONDOS", fnd)
            
            AddRawStat("MUERTES", d)
            
            local ivoTime = ply:GetNWInt("VIRTUS_TotalPlaytime", 0)
            local tH = math.floor(ivoTime / 3600)
            local tM = math.floor((ivoTime % 3600) / 60)
            local tS = math.floor(ivoTime % 60)
            local timeStr = string.format("%d:%02d:%02d", tH, tM, tS)
            AddRawStat("TIEMPO JUGADO", timeStr)
            
            AddRawStat("ENEMIGOS ELIMINADOS", ply:GetNWInt("VIRTUS_NPCKills", 0))
            
            local defJob = "SOLDADO IMPERIAL"
            if team and team.GetName then defJob = SafeUpper(team.GetName(ply:Team())) end
            local bestJobRaw = ply:GetNWString("VIRTUS_BestJob", "")
            if bestJobRaw == "" then bestJobRaw = defJob end
            local bestJobName = SafeUpper(bestJobRaw)
            if bestJobName == "CADETE CLON" or bestJobName == "CADETE" then
                bestJobName = defJob
            end
            
            local bestMdl = ply:GetModel()
            for k, job in pairs(RPExtraTeams or {}) do
                if SafeUpper(job.name) == bestJobName then
                    bestMdl = type(job.model) == "table" and job.model[1] or job.model
                    break
                end
            end
            
            local best = vgui.Create("DPanel", infoPnl)
            best:SetSize(innerMidW - 40, 100)
            best:SetPos(20, 580)
            
            local bestIcon = vgui.Create("DModelPanel", best)
            bestIcon:SetSize(90, 90)
            bestIcon:SetPos(5, 5)
            bestIcon:SetModel(bestMdl)
            bestIcon:SetMouseInputEnabled(false)
            bestIcon:SetFOV(30)
            bestIcon:SetCamPos(Vector(40, 0, 62))
            bestIcon:SetLookAt(Vector(0, 0, 62))
            bestIcon:SetAmbientLight(Color(200, 200, 200))
            bestIcon:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
            bestIcon:SetDirectionalLight(BOX_FRONT, Color(255, 255, 255))
            function bestIcon:LayoutEntity(ent) return end
            
            best.Paint = function(s, pw, ph)
                local c = Color(0, 150, 255)
                draw.RoundedBox(8, 0, 0, pw, ph, Color(c.r, c.g, c.b, 100))
                draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(10, 15, 20, 240))
                
                surface.SetDrawColor(c.r, c.g, c.b, 50)
                surface.DrawOutlinedRect(5, 5, 90, 90)
                
                draw.SimpleText("ESPECIALIDAD MAS USADA", "VF4_Small", 100, 30, Color(150,150,150), 0, 1)
                
                local txtW = surface.GetTextSize(bestJobName)
                local font = (txtW > pw - 120) and "VF4_Header" or "VF4_TitleBig"
                draw.SimpleText(bestJobName, font, 100, 60, c, 0, 1)
            end
            
        elseif tabID == "BARRACON" then
            local ply = LocalPlayer()
            local w = mainContainer:GetWide()
            local h = mainContainer:GetTall()
            
            local leftW = w * 0.25
            local leftScroll = vgui.Create("DScrollPanel", mainContainer)
            leftScroll:SetPos(0, 0)
            leftScroll:SetSize(leftW, h)
            VIRTUSMENU.StyleScroll(leftScroll)
            
            local midX = leftW + 20
            local midW = w * 0.4
            
            local rightX = midX + midW + 20
            local rightW = w - rightX
            
            local selectedBtn = nil
            
            local glowPnl = vgui.Create("DPanel", mainContainer)
            glowPnl:SetPos(midX, 0)
            glowPnl:SetSize(midW, h)
            glowPnl.Paint = function(s, pw, ph)
                draw.RoundedBox(8, 0, 0, pw, ph, Color(0, 150, 255, 50))
                draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(15, 20, 25, 180))
            end
            
            local centerModel = vgui.Create("DModelPanel", mainContainer)
            centerModel:SetPos(midX, 0)
            centerModel:SetSize(midW, h)
            centerModel:SetModel("")
            centerModel:SetFOV(26)
            centerModel:SetCamPos(Vector(115, 0, 48))
            centerModel:SetLookAt(Vector(0, 0, 48))
            centerModel:SetAmbientLight(Color(20, 20, 30))
            centerModel:SetDirectionalLight(BOX_TOP, Color(150, 200, 255))
            centerModel:SetDirectionalLight(BOX_FRONT, Color(255, 255, 255))
            centerModel:SetDirectionalLight(BOX_RIGHT, Color(255, 30, 30))
            
            centerModel.ModelAngle = 50 -- 50 degrees usually makes it look straight at the camera slightly angled, wait, 0 faces the camera directly if camera is at (X,0,Z). Let's use 0.
            centerModel.ModelAngle = 0
            centerModel.IsDragging = false
            centerModel.LastX = 0
            
            function centerModel:OnMousePressed(mc)
                if mc == MOUSE_LEFT then
                    self.IsDragging = true
                    self.LastX = gui.MouseX()
                end
            end
            
            function centerModel:OnMouseReleased(mc)
                if mc == MOUSE_LEFT then self.IsDragging = false end
            end
            
            function centerModel:OnCursorExited()
                self.IsDragging = false
            end
            
            function centerModel:LayoutEntity(ent)
                if self.IsDragging then
                    local mx = gui.MouseX()
                    self.ModelAngle = self.ModelAngle + (mx - self.LastX) * 0.8
                    self.LastX = mx
                end
                ent:SetAngles(Angle(0, self.ModelAngle, 0))
            end
            
            local oldPaint = centerModel.Paint
            centerModel.Paint = function(s, pw, ph)
                local m = s:GetModel()
                if not m or m == "" or m == "models/player/kleiner.mdl" then
                    local mat = Material("virtus/imperio", "smooth")
                    surface.SetMaterial(mat)
                    local c = _G.VIRTUS_GetHUDColor and _G.VIRTUS_GetHUDColor("accent") or Color(0, 150, 255)
                    surface.SetDrawColor(c.r, c.g, c.b, 150)
                    local isz = 250
                    
                    local cosVal = math.cos(CurTime() * 2)
                    local scale = math.abs(cosVal)
                    local currentW = isz * scale
                    local rx = pw/2 - currentW / 2
                    local ry = ph/2 - isz / 2
                    
                    if cosVal > 0 then
                        surface.DrawTexturedRectUV(rx, ry, currentW, isz, 0, 0, 1, 1)
                    else
                        surface.DrawTexturedRectUV(rx, ry, currentW, isz, 1, 0, 0, 1)
                    end
                else
                    oldPaint(s, pw, ph)
                end
            end
            
            local infoPnl = vgui.Create("DPanel", mainContainer)
            infoPnl:SetPos(rightX, 40)
            infoPnl:SetSize(rightW, h - 80)
            infoPnl.Paint = function(s, pw, ph) 
                local c = Color(0, 150, 255)
                draw.RoundedBox(8, 0, 0, pw, ph, Color(c.r, c.g, c.b, 100))
                draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(12, 16, 22, 245))
                
                surface.SetDrawColor(c.r, c.g, c.b, 5)
                for i=0, ph, 8 do 
                    surface.DrawLine(0, i, pw, i) 
                end
                
                -- Esquinas decorativas removidas por peticion
            end
            infoPnl:SetAlpha(0)
            
            local selName = vgui.Create("DLabel", infoPnl)
            selName:SetFont("VF4_TitleBig")
            selName:SetText("SELECCIONA UN ROL")
            selName:SetPos(20, 15)
            selName:SetSize(rightW - 40, 45)
            
            local selSubName = vgui.Create("DLabel", infoPnl)
            selSubName:SetFont("VF4_Subtitle_Aurebesh_Large")
            selSubName:SetText("SELECCIONA UN ROL")
            selSubName:SetPos(22, 58)
            selSubName:SetSize(rightW - 40, 26)
            selSubName:SetTextColor(Color(150, 150, 150))
            
            local sep = vgui.Create("DPanel", infoPnl)
            sep:SetPos(20, 90)
            sep:SetSize(rightW - 40, 1)
            sep.Paint = function(s, pw, ph) surface.SetDrawColor(0, 150, 255, 50) surface.DrawRect(0, 0, pw, ph) end
            
            local lvlPnl = vgui.Create("DPanel", infoPnl)
            lvlPnl:SetPos(20, 130)
            lvlPnl:SetSize(rightW - 40, 230)
            lvlPnl.jobData = nil
            lvlPnl.CurProgress = 0
            lvlPnl.Paint = function(s, pw, ph)
                if not s.jobData then return end
                
                if not _G.CreatedGiganticFont then
                    -- =============================================== --
-- INICIALIZACION DE CONVARS (Para que guarden config)
-- =============================================== --
CreateClientConVar("virtus_compass_y", "0", true, false)
CreateClientConVar("virtus_compass_width", "600", true, false)
CreateClientConVar("virtus_compass_spacing", "8", true, false)
CreateClientConVar("virtus_hide_hud", "0", true, false)
CreateClientConVar("virtus_hide_compass", "0", true, false)
CreateClientConVar("virtus_netgraph_enable", "0", true, false)
CreateClientConVar("virtus_netgraph_detailed", "0", true, false)
CreateClientConVar("virtus_vfx_volume", "1", true, false)
CreateClientConVar("virtus_radio_enabled", "1", true, false)
CreateClientConVar("virtus_radio_vol", "1", true, false)
CreateClientConVar("virtus_bind_tp", tostring(KEY_F1), true, false)
CreateClientConVar("virtus_bind_radio_talk", tostring(KEY_H), true, false)
CreateClientConVar("virtus_bind_radio_menu", tostring(KEY_P), true, false)
CreateClientConVar("virtus_bind_util", tostring(KEY_B), true, false)
CreateClientConVar("virtus_bind_anims", "109", true, false)
CreateClientConVar("virtus_bind_invis", tostring(KEY_M), true, false)
CreateClientConVar("virtus_bind_tfa_reload", tostring(KEY_R), true, false)

surface.CreateFont("VF4_Gigantic", { font = "SansSerifFLF-Demibold", size = 110, weight = 500, antialias = true })
                    _G.CreatedGiganticFont = true
                end
                
                local lvl = s.jobData.lvl
                local jobCmd = s.jobData.job.command
                local xp = LocalPlayer():GetNWInt("IVO_JobXP_" .. jobCmd, 0)
                local maxXp = IVO_SAM and IVO_SAM.GetXPNeededForLevel and IVO_SAM.GetXPNeededForLevel(lvl) or (lvl * 1000)
                if maxXp <= 0 then maxXp = 100 end
                
                local targetP = math.Clamp(xp / maxXp, 0, 1)
                s.CurProgress = Lerp(FrameTime() * 2, s.CurProgress, targetP)
                
                local r = 85
                local cx, cy = pw / 2, r + 5
                local poly = { {x=cx, y=cy-r}, {x=cx+r, y=cy}, {x=cx, y=cy+r}, {x=cx-r, y=cy} }
                draw.NoTexture()
                surface.SetDrawColor(0, 150, 255, 50)
                surface.DrawPoly(poly)
                surface.SetDrawColor(0, 150, 255, 255)
                for i=1, 4 do
                    local p1, p2 = poly[i], poly[i%4+1]
                    surface.DrawLine(p1.x, p1.y, p2.x, p2.y)
                end
                
                draw.SimpleText(lvl, "VF4_Gigantic", cx, cy - 2, Color(255,255,255), 1, 1)
                
                local barW = pw - 60
                local barX = 30
                local barH = 25
                local barY = cy + r + 20
                
                surface.SetDrawColor(10, 15, 25, 200)
                surface.DrawRect(barX, barY, barW, barH)
                surface.SetDrawColor(0, 150, 255, 100)
                surface.DrawOutlinedRect(barX, barY, barW, barH)
                
                local fillW = barW * s.CurProgress
                surface.SetDrawColor(0, 150, 255, 200)
                surface.DrawRect(barX, barY, fillW, barH)
                
                draw.SimpleText(xp .. " / " .. maxXp, "VF4_Medium", barX + barW/2, barY + barH/2, Color(200,200,200), 1, 1)
            end
            
            local statsLayout = vgui.Create("DIconLayout", infoPnl)
            statsLayout:SetPos(20, h - 340)
            statsLayout:SetSize(rightW - 40, 200)
            statsLayout:SetSpaceY(10)
            statsLayout:SetSpaceX(0)
            
            local deployBtn = vgui.Create("DButton", infoPnl)
            deployBtn:SetPos(20, h - 160)
            deployBtn:SetSize(rightW - 40, 50)
            deployBtn:SetText("")
            deployBtn:SetFont("VF4_Medium")
            deployBtn:SetVisible(false)
            deployBtn.Paint = function(s, pw, ph)
                s.HoverP = Lerp(FrameTime() * 10, s.HoverP or 0, s:IsHovered() and 1 or 0)
                local c = Color(0, 150, 255)
                
                local bordeAlpha = 100 + s.HoverP * 155
                draw.RoundedBox(8, 0, 0, pw, ph, Color(c.r, c.g, c.b, bordeAlpha))
                
                local interiorAlpha = 240 - (s.HoverP * 10)
                draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(10, 15, 20, interiorAlpha))
                
                if s.HoverP > 0.01 then
                    draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(c.r, c.g, c.b, s.HoverP * 30))
                end
                local txtCol = Color(200 + 55 * s.HoverP, 200 + 55 * s.HoverP, 255)
                draw.SimpleText("DESPLEGAR", "VF4_Medium", pw/2, ph/2, txtCol, 1, 1)
            end
            
            local sortedJobs = {}
            for k, job in ipairs(RPExtraTeams or {}) do
                -- Mostrar si está en la whitelist (ignoramos superadmin para que solo muestre las que tiene asignadas)
                if ply:GetNWBool("VirtusWL_" .. job.command, false) then
                    local lvl = ply:GetNWInt("IVO_JobLevel_" .. job.command, 1)
                    local time = ply:GetNWInt("VIRTUS_Playtime_" .. job.command, 0)
                    local kills = ply:GetNWInt("VIRTUS_Kills_" .. job.command, 0)
                    local deaths = ply:GetNWInt("VIRTUS_Deaths_" .. job.command, 0)
                    table.insert(sortedJobs, { job = job, lvl = lvl, time = time, kills = kills, deaths = deaths })
                end
            end
            table.sort(sortedJobs, function(a, b)
                return a.time > b.time
            end)
            
            local yPos = 10
            local firstBtn = nil
            
            for i, data in ipairs(sortedJobs) do
                local job = data.job
                local btn = vgui.Create("DButton", leftScroll)
                btn:SetSize(leftW - 15, 100)
                btn:SetPos(0, yPos)
                btn:SetText("")
                yPos = yPos + 110
                
                local m = type(job.model) == "table" and job.model[1] or job.model
                if not m or m == "" or not util.IsValidModel(m) or string.lower(m) == "models/error.mdl" then m = "models/player/kleiner.mdl" end
                
                local icon = vgui.Create("DModelPanel", btn)
                icon:SetSize(90, 90)
                icon:SetPos(5, 5)
                icon:SetModel(m)
                icon:SetMouseInputEnabled(false)
                icon:SetFOV(30)
                icon:SetCamPos(Vector(40, 0, 62))
                icon:SetLookAt(Vector(0, 0, 62))
                icon:SetAmbientLight(Color(200, 200, 200))
                icon:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
                icon:SetDirectionalLight(BOX_FRONT, Color(255, 255, 255))
                function icon:LayoutEntity(ent) return end
                
                btn.Paint = function(s, pw, ph)
                    local isSel = (selectedBtn == s)
                    local c = isSel and Color(0, 150, 255, 80) or (s:IsHovered() and Color(0, 150, 255, 30) or Color(0, 0, 0, 220))
                    local bC = isSel and Color(0, 150, 255, 255) or (s:IsHovered() and Color(0, 150, 255, 100) or Color(0, 150, 255, 20))
                    
                    local bordeAlpha = bC.a
                    draw.RoundedBox(8, 0, 0, pw, ph, Color(bC.r, bC.g, bC.b, bordeAlpha))
                    draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(c.r, c.g, c.b, c.a))
                    
                    surface.SetDrawColor(0, 150, 255, isSel and 25 or 10)
                    for k=0, ph, 8 do 
                        surface.DrawLine(0, k, pw, k) 
                    end
                    
                    if isSel then
                        surface.SetDrawColor(bC.r, bC.g, bC.b, 150)
                        surface.DrawRect(0, ph - 4, pw - 10, 4)
                    end
                    
                    surface.SetDrawColor(bC.r, bC.g, bC.b, 50)
                    surface.DrawOutlinedRect(5, 5, 90, 90)
                    
                    draw.SimpleText(SafeUpper(job.name), "VF4_JobList_Name", 100, 13, Color(255,255,255), 0, 0)
                    draw.SimpleText(SafeUpper(job.name), "VF4_Subtitle_Aurebesh_Small", 100, 36, Color(150, 150, 150), 0, 0)
                    
                    surface.SetDrawColor(bC.r, bC.g, bC.b, 100)
                    surface.DrawLine(100, 55, pw - 65, 55)
                    
                    local r = 15
                    local cx, cy = pw - 30, ph / 2
                    local dPoly = { {x=cx, y=cy-r}, {x=cx+r, y=cy}, {x=cx, y=cy+r}, {x=cx-r, y=cy} }
                    draw.NoTexture()
                    surface.SetDrawColor(0, 150, 255, 50)
                    surface.DrawPoly(dPoly)
                    surface.SetDrawColor(bC.r, bC.g, bC.b, 255)
                    for i=1, 4 do
                        local p1, p2 = dPoly[i], dPoly[i%4+1]
                        surface.DrawLine(p1.x, p1.y, p2.x, p2.y)
                    end
                    draw.SimpleText(data.lvl, "VF4_Small", cx, cy, Color(255,255,255), 1, 1)
                    
                    local xp = LocalPlayer():GetNWInt("IVO_JobXP_" .. job.command, 0)
                    local maxXp = IVO_SAM and IVO_SAM.GetXPNeededForLevel and IVO_SAM.GetXPNeededForLevel(data.lvl) or (data.lvl * 1000)
                    if maxXp <= 0 then maxXp = 100 end
                    local targetP = math.Clamp(xp / maxXp, 0, 1)
                    s.CurProgress = Lerp(FrameTime() * 2, s.CurProgress or 0, targetP)
                    
                    local barX, barY = 100, 60
                    local barW, barH = pw - 100 - 65, 6
                    surface.SetDrawColor(10, 15, 25, 200)
                    surface.DrawRect(barX, barY, barW, barH)
                    surface.SetDrawColor(bC.r, bC.g, bC.b, 100)
                    surface.DrawOutlinedRect(barX, barY, barW, barH)
                    surface.SetDrawColor(0, 200, 255, 200)
                    surface.DrawRect(barX, barY, barW * s.CurProgress, barH)
                end
                
                if i == 1 then firstBtn = btn end
                
                btn.DoClick = function(s, silent)
                    if not silent then VIRTUSMENU.PlayUI("navigation/aceptar.wav") end
                    selectedBtn = s
                    infoPnl:SetAlpha(0)
                    infoPnl:AlphaTo(255, 0.3, 0)
                    if IsValid(VIRTUSMENU.EscapeMenu.ClonePanel) then
                        VIRTUSMENU.EscapeMenu.ClonePanel:SetVisible(false)
                    end
                    centerModel:SetPos(midX, 0)
                    centerModel:SetSize(midW, h)
                    
                    centerModel:SetModel(m)
                    if IsValid(centerModel.Entity) then
                        local modelFile = string.GetFileFromFilename(m)
                        local path = "v_bodygroups/" .. modelFile .. ".json"
                        if file.Exists(path, "DATA") then
                            local data = util.JSONToTable(file.Read(path, "DATA"))
                            if data and data.bgs then
                                for k, v in pairs(data.bgs) do
                                    centerModel.Entity:SetBodygroup(tonumber(k) or 0, tonumber(v) or 0)
                                end
                            end
                            if data and data.skin then
                                centerModel.Entity:SetSkin(tonumber(data.skin) or 0)
                            end
                        else
                            for i = 0, centerModel.Entity:GetNumBodyGroups() - 1 do
                                centerModel.Entity:SetBodygroup(i, 0)
                            end
                            centerModel.Entity:SetSkin(0)
                        end
                    end
                    selName:SetText(SafeUpper(job.name))
                    selSubName:SetText(SafeUpper(job.name))
                    selName:SetTextColor(job.color or Color(255,255,255))
                    lvlPnl.jobData = data
                    
                    statsLayout:Clear()
                    
                    local function AddStat(title, val)
                        local p = statsLayout:Add("DPanel")
                        p:SetSize(rightW - 40, 45)
                        p.Paint = function(s, pw, ph)
                            draw.RoundedBox(0, 0, 0, pw, ph, Color(15, 20, 25, 200))
                            surface.SetDrawColor(0, 150, 255, 30)
                            surface.DrawOutlinedRect(0, 0, pw, ph)
                            surface.SetDrawColor(0, 150, 255, 150)
                            surface.DrawRect(0, 0, 3, ph)
                            draw.SimpleText(title, "VF4_Small", 15, ph/2, Color(150, 150, 150), 0, 1)
                            draw.SimpleText(tostring(val), "VF4_Medium", pw - 15, ph/2, Color(255, 255, 255), 2, 1)
                        end
                    end
                    
                    local tH = math.floor(data.time / 3600)
                    local tM = math.floor((data.time % 3600) / 60)
                    local tS = math.floor(data.time % 60)
                    local tStr = string.format("%d:%02d:%02d", tH, tM, tS)
                    
                    AddStat("TIEMPO JUGADO:", tStr)
                    AddStat("ASESINATOS:", data.kills)
                    AddStat("MUERTES:", data.deaths)
                    
                    deployBtn:SetVisible(true)
                    deployBtn.DoClick = function()
                        VIRTUSMENU.PlayUI("navigation/aceptar.wav")
                        RunConsoleCommand("darkrp", job.command)
                        if IsValid(VIRTUSMENU.EscapeMenu) then VIRTUSMENU.EscapeMenu:Remove() end
                    end
                end
            end
            
            if firstBtn then
                firstBtn:DoClick(true)
            end
        elseif tabID == "FACCIONES" then
            if VIRTUSMENU.BuildF4Tab then
                VIRTUSMENU.BuildF4Tab(mainContainer)
            end
        elseif tabID == "PROGRESO" then
            local lbl = vgui.Create("DLabel", mainContainer)
            lbl:SetText("ARBOL DE HABILIDADES Y PROGRESO")
            lbl:SetFont("VF4_TitleBig")
            lbl:SizeToContents()
            lbl:SetPos(0, 0)
            
            local subContent = vgui.Create("DPanel", mainContainer)
            subContent:SetPos(0, 60)
            subContent:SetSize(mainContainer:GetWide(), mainContainer:GetTall() - 60)
            subContent.Paint = function() end
            
            local btnHab = vgui.Create("DButton", subContent)
            btnHab:SetSize(subContent:GetWide() / 2 - 10, subContent:GetTall())
            btnHab:SetPos(0, 0)
            btnHab:SetText("")
            btnHab.HoverP = 0
            btnHab.Paint = function(s, w, h)
                s.HoverP = Lerp(FrameTime() * 10, s.HoverP, s:IsHovered() and 1 or 0)
                if s.HoverP > 0.05 then
                    draw.RoundedBox(8, 0, 0, w, h, Color(0, 150, 255, s.HoverP * 255))
                    draw.RoundedBox(8, 2, 2, w - 4, h - 4, Color(15, 20, 25, 200))
                    draw.RoundedBox(8, 2, 2, w - 4, h - 4, Color(0, 150, 255, s.HoverP * 20))
                else
                    draw.RoundedBox(8, 0, 0, w, h, Color(15, 20, 25, 200))
                end
                
                draw.SimpleText("HABILIDADES", "VF4_TitleBig", w/2, h/2 - 20, Color(255, 255, 255), 1, 1)
                draw.SimpleText("Mejora tus capacidades y especialidades", "VF4_Medium", w/2, h/2 + 20, Color(150, 150, 150), 1, 1)
            end
            btnHab.DoClick = function()
                VIRTUSMENU.PlayUI("navigation/aceptar.wav")
                if IVO_HABILITIES and IVO_HABILITIES.OpenFullSkillTree then
                    IVO_HABILITIES.OpenFullSkillTree(mainContainer)
                end
            end
            
            local btnLog = vgui.Create("DButton", subContent)
            btnLog:SetSize(subContent:GetWide() / 2 - 10, subContent:GetTall())
            btnLog:SetPos(subContent:GetWide() / 2 + 10, 0)
            btnLog:SetText("")
            btnLog.HoverP = 0
            btnLog.Paint = function(s, w, h)
                s.HoverP = Lerp(FrameTime() * 10, s.HoverP, s:IsHovered() and 1 or 0)
                if s.HoverP > 0.05 then
                    draw.RoundedBox(8, 0, 0, w, h, Color(255, 170, 0, s.HoverP * 255))
                    draw.RoundedBox(8, 2, 2, w - 4, h - 4, Color(15, 20, 25, 200))
                    draw.RoundedBox(8, 2, 2, w - 4, h - 4, Color(255, 170, 0, s.HoverP * 20))
                else
                    draw.RoundedBox(8, 0, 0, w, h, Color(15, 20, 25, 200))
                end
                
                draw.SimpleText("LOGROS", "VF4_TitleBig", w/2, h/2 - 20, Color(255, 255, 255), 1, 1)
                draw.SimpleText("Proximamente...", "VF4_Medium", w/2, h/2 + 20, Color(150, 150, 150), 1, 1)
            end

        elseif tabID == "AJUSTES" then
            local lbl = vgui.Create("DLabel", mainContainer)
            lbl:SetText("CONFIGURACION DEL SISTEMA IMPERIAL")
            lbl:SetFont("VF4_TitleBig")
            lbl:SizeToContents()
            lbl:SetPos(0, 0)
            
            local subContent = vgui.Create("DPanel", mainContainer)
            subContent:SetPos(0, 60)
            subContent:SetSize(mainContainer:GetWide(), mainContainer:GetTall() - 60)
            subContent.Paint = function() end
            
            local activeSubTab = "MENU"
            
            local function DrawSettingBg(pw, ph, isHovered)
                local c = Color(0, 150, 255)
                
                local bordeAlpha = isHovered and 100 or 30
                draw.RoundedBox(8, 0, 0, pw, ph, Color(c.r, c.g, c.b, bordeAlpha))
                
                local interiorAlpha = 200
                draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(10, 15, 20, interiorAlpha))
                
                if isHovered then
                    draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(c.r, c.g, c.b, 20))
                end
            end

            local function BuildSubTab()
                subContent:Clear()
                
                if activeSubTab == "MENU" then
                    local w = subContent:GetWide()
                    local h = subContent:GetTall()
                    local spaceX = 20
                    local spaceY = 20
                    local cardW = (w - (spaceX * 2)) / 3
                    local cardH = (h - spaceY) / 2
                    
                    local tabs = {
                        {id = "INTERFAZ", desc = "HUD y Brujula", icon = "virtus/imperio"},
                        {id = "ACCESIBILIDAD", desc = "Rendimiento y Camara", icon = "virtus/rebelde"},
                        {id = "SONIDO", desc = "Volumen y Radio", icon = "virtus/audio"},
                        {id = "CONTROLES", desc = "Mapeo de Teclas", icon = "virtus/controles"},
                        {id = "SISTEMAS EXTERNOS", desc = "LVS, TFA y Otros", icon = "virtus/imperio"},
                        {id = "CREDITOS", desc = "Acerca de", icon = "virtus/discord"}
                    }
                    
                    for i, t in ipairs(tabs) do
                        local col = (i - 1) % 3
                        local row = math.floor((i - 1) / 3)
                        local cx = col * (cardW + spaceX)
                        local cy = row * (cardH + spaceY)
                        
                        local btn = vgui.Create("DButton", subContent)
                        btn:SetSize(cardW, cardH)
                        btn:SetPos(cx, cy)
                        btn:SetText("")
                        btn.HoverP = 0
                        btn.OnCursorEntered = function(s) if VIRTUSMENU.PlayUI then VIRTUSMENU.PlayUI("navigation/movimiento.wav") end end
                        btn.Paint = function(s, pw, ph)
                            s.HoverP = Lerp(FrameTime() * 10, s.HoverP, s:IsHovered() and 1 or 0)
                            local c = Color(0, 150, 255)
                            local bordeAlpha = 50 + s.HoverP * 150
                            draw.RoundedBox(8, 0, 0, pw, ph, Color(c.r, c.g, c.b, bordeAlpha))
                            
                            local interiorAlpha = 230 - (s.HoverP * 10)
                            draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(10, 15, 20, interiorAlpha))
                            
                            if s.HoverP > 0.01 then
                                draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(c.r, c.g, c.b, s.HoverP * 30))
                            end
                            
                            s.MapAnim = (s.MapAnim or 0) + FrameTime() * (10 + s.HoverP * 50)
                            surface.SetDrawColor(c.r, c.g, c.b, 20 + s.HoverP * 40)
                            
                            local function DrawOrbit(cx, cy, radius, dashed, stepSz, gap)
                                local step = stepSz or 5
                                local gapAmt = gap or (step*2)
                                local lastX, lastY = cx + radius, cy
                                for ang = step, 360, step do
                                    local rad = math.rad(ang)
                                    local curX = cx + math.cos(rad) * radius
                                    local curY = cy + math.sin(rad) * radius
                                    if not dashed or (ang % (gapAmt*2) < gapAmt) then
                                        surface.DrawLine(lastX, lastY, curX, curY)
                                    end
                                    lastX, lastY = curX, curY
                                end
                            end

                            local mx, my
                            if i == 1 then mx, my = pw * 0.75, ph * 0.75
                            elseif i == 2 then mx, my = pw * 0.85, ph * 0.25
                            elseif i == 3 then mx, my = pw * 0.6, ph * 0.8
                            elseif i == 4 then mx, my = pw * 0.9, ph * 0.85
                            elseif i == 5 then mx, my = pw * 0.75, ph * 0.35
                            else mx, my = pw * 0.8, ph * 0.5 end
                            
                            if i == 1 then
                                -- Basic planetary system
                                DrawOrbit(mx, my, 40, false)
                                DrawOrbit(mx, my, 80, true, 5, 10)
                                DrawOrbit(mx, my, 130, false)
                                local p1 = math.rad(s.MapAnim * 1.5)
                                surface.DrawRect(mx + math.cos(p1)*40 - 2, my + math.sin(p1)*40 - 2, 4, 4)
                                local p2 = math.rad(s.MapAnim * 0.8)
                                surface.DrawOutlinedRect(mx + math.cos(p2)*80 - 4, my + math.sin(p2)*80 - 4, 8, 8)
                            elseif i == 2 then
                                -- Radar sweep
                                DrawOrbit(mx, my, 30, true, 10, 10)
                                DrawOrbit(mx, my, 60, false)
                                DrawOrbit(mx, my, 100, true, 5, 20)
                                local rad = math.rad(s.MapAnim * 2)
                                surface.DrawLine(mx, my, mx + math.cos(rad)*100, my + math.sin(rad)*100)
                                surface.DrawRect(mx + math.cos(rad-0.5)*60 - 2, my + math.sin(rad-0.5)*60 - 2, 4, 4)
                            elseif i == 3 then
                                -- Pulsing rings
                                local r1 = 30 + math.sin(s.MapAnim * 0.05) * 10
                                local r2 = 70 + math.cos(s.MapAnim * 0.05) * 15
                                local r3 = 110 + math.sin(s.MapAnim * 0.03) * 20
                                DrawOrbit(mx, my, r1, false)
                                DrawOrbit(mx, my, r2, true, 6, 12)
                                DrawOrbit(mx, my, r3, true, 8, 16)
                            elseif i == 4 then
                                -- Binary star
                                local bx1 = mx + math.cos(math.rad(s.MapAnim))*40
                                local by1 = my + math.sin(math.rad(s.MapAnim))*40
                                local bx2 = mx + math.cos(math.rad(s.MapAnim + 180))*40
                                local by2 = my + math.sin(math.rad(s.MapAnim + 180))*40
                                DrawOrbit(bx1, by1, 20, false)
                                DrawOrbit(bx2, by2, 20, false)
                                surface.DrawLine(bx1, by1, bx2, by2)
                                DrawOrbit(mx, my, 90, true, 5, 15)
                            elseif i == 5 then
                                -- Hexagon tech grid
                                DrawOrbit(mx, my, 80, false, 60)
                                DrawOrbit(mx, my, 40, false, 60)
                                local t = math.rad(s.MapAnim)
                                surface.DrawLine(mx, my, mx + math.cos(t)*80, my + math.sin(t)*80)
                                surface.DrawLine(mx, my, mx + math.cos(t+math.pi)*80, my + math.sin(t+math.pi)*80)
                            else
                                -- Orbiting data nodes
                                DrawOrbit(mx, my, 50, true, 10, 20)
                                DrawOrbit(mx, my, 120, true, 5, 30)
                                for j=1, 3 do
                                    local p = math.rad(s.MapAnim * (1 + j*0.2) + (j*120))
                                    surface.DrawOutlinedRect(mx + math.cos(p)*50 - 3, my + math.sin(p)*50 - 3, 6, 6)
                                    surface.DrawRect(mx + math.cos(-p)*120 - 2, my + math.sin(-p)*120 - 2, 4, 4)
                                end
                            end
                            
                            draw.SimpleText(t.id, "VF4_Header", 20, 20, Color(255,255,255), 0, 0)
                            draw.SimpleText(t.id, "VF4_Subtitle_Aurebesh", 20, 50, Color(150,150,150), 0, 0)
                            
                            if t.icon then
                                local mat = Material(t.icon, "noclamp smooth")
                                surface.SetMaterial(mat)
                                
                                local r = Lerp(s.HoverP, c.r, 255)
                                local g = Lerp(s.HoverP, c.g, 255)
                                local b = Lerp(s.HoverP, c.b, 255)
                                local a = Lerp(s.HoverP, 150, 255)
                                
                                surface.SetDrawColor(r, g, b, a)
                                local isz = 110
                                surface.DrawTexturedRect(pw / 2 - isz / 2, ph / 2 - isz / 2, isz, isz)
                            end
                            
                            local actionColor = Color(c.r, c.g, c.b, 150 + s.HoverP * 105)
                            draw.SimpleText("> ABRIR", "VF4_Medium", pw - 25, ph - 25, actionColor, 2, 1)
                        end
                        if i == 1 then firstBtn = btn end
                
                btn.DoClick = function(s)
                            if VIRTUSMENU.PlayUI then VIRTUSMENU.PlayUI("navigation/aceptar.wav") end
                            if t.id == "CREDITOS" then
                                VIRTUSMENU.PlayStarWarsCredits()
                            else
                                activeSubTab = t.id
                                BuildSubTab()
                            end
                        end
                    end
                    return
                end
                
                local btnBack = vgui.Create("DButton", subContent)
                btnBack:SetSize(120, 30)
                btnBack:SetPos(0, 0)
                btnBack:SetText("< VOLVER")
                btnBack:SetFont("VF4_Medium")
                btnBack:SetTextColor(Color(255, 255, 255))
                btnBack.Paint = function(s, w, h)
                    draw.RoundedBox(0, 0, 0, w, h, s:IsHovered() and Color(0, 150, 255, 100) or Color(50, 50, 50, 100))
                end
                btnBack.DoClick = function(s)
                    if VIRTUSMENU.PlayUI then VIRTUSMENU.PlayUI("navigation/aceptar.wav") end
                    activeSubTab = "MENU"
                    BuildSubTab()
                end
                
                local titleLbl = vgui.Create("DLabel", subContent)
                titleLbl:SetText(activeSubTab)
                titleLbl:SetFont("VF4_Header")
                titleLbl:SetTextColor(Color(0, 150, 255))
                titleLbl:SizeToContents()
                titleLbl:SetPos(140, 2)
                
                local leftScroll = vgui.Create("DScrollPanel", subContent)
                VIRTUSMENU.StyleScroll(leftScroll)
                leftScroll:SetSize(subContent:GetWide() * 0.48, subContent:GetTall() - 40)
                leftScroll:SetPos(0, 40)
                
                local rightScroll = vgui.Create("DScrollPanel", subContent)
                VIRTUSMENU.StyleScroll(rightScroll)
                rightScroll:SetSize(subContent:GetWide() * 0.48, subContent:GetTall() - 40)
                rightScroll:SetPos(subContent:GetWide() * 0.52, 40)
                
                local yLeft, yRight = 0, 0
                
                                                local function DrawArcSeg(x, y, r, th, r1, r2, c)
                    r1 = math.rad(r1 - 90)
                    r2 = math.rad(r2 - 90)
                    local p1 = {x = x + math.cos(r1) * r, y = y + math.sin(r1) * r}
                    local p2 = {x = x + math.cos(r2) * r, y = y + math.sin(r2) * r}
                    local p3 = {x = x + math.cos(r2) * (r - th), y = y + math.sin(r2) * (r - th)}
                    local p4 = {x = x + math.cos(r1) * (r - th), y = y + math.sin(r1) * (r - th)}
                    surface.SetDrawColor(c)
                    surface.DrawPoly({p1, p2, p3, p4})
                end
                
                local function DrawArcFull(x, y, r, th, startang, endang, step, c)
                    for i = startang, endang - step, step do DrawArcSeg(x, y, r, th, i, i + step, c) end
                    local remain = (endang - startang) % step
                    if remain > 0 then DrawArcSeg(x, y, r, th, endang - remain, endang, c) end
                end

                local function CreateTFACrosshairPreview(parent, isLeft)
                    local p = vgui.Create("DPanel", parent)
                    p:SetPos(0, isLeft and yLeft or yRight)
                    p:SetSize(parent:GetWide() - 20, 120)
                    p.Paint = function(s, w, h)
                        draw.RoundedBox(0, 0, 0, w, h, Color(10, 10, 10, 200))
                        
                        local cv = GetConVar("tfa_sw_hud_crosshair_color")
                        local str = cv and cv:GetString() or "255 255 255 255"
                        local exp = string.Explode(" ", str)
                        local r = tonumber(exp[1]) or 255
                        local g = tonumber(exp[2]) or 255
                        local b = tonumber(exp[3]) or 255
                        local a = tonumber(exp[4]) or 255
                        local baseColor = Color(r, g, b, a)

                        local cx, cy = w / 2, h / 2
                        local radius = 10
                        local thickness = 2
                        
                        draw.NoTexture()
                        -- Center dot
                        surface.SetDrawColor(baseColor.r, baseColor.g, baseColor.b, 100)
                        surface.DrawRect(cx - 1, cy - 1, 2, 2)
                        
                        DrawArcFull(cx, cy, radius, thickness, 5, 55, 2, baseColor)
                        DrawArcFull(cx, cy, radius, thickness, 125, 175, 2, baseColor)
                        DrawArcFull(cx, cy, radius, thickness, 245, 295, 2, baseColor)
                        
                        local outerRad = radius + 8
                        local outerThick = 3
                        DrawArcFull(cx, cy, outerRad, outerThick, 89, 91, 1, baseColor)
                        DrawArcFull(cx, cy, outerRad, outerThick, 209, 211, 1, baseColor)
                        DrawArcFull(cx, cy, outerRad, outerThick, 329, 331, 1, baseColor)
                    end
                    if isLeft then yLeft = yLeft + 130 else yRight = yRight + 130 end
                end
                local function CreateColorMixerStr(parent, isLeft, title, cvarName)
                    local p = vgui.Create("DPanel", parent)
                    p:SetPos(0, isLeft and yLeft or yRight)
                    p:SetSize(parent:GetWide() - 20, 200)
                    p.Paint = function(s, w, h)
                        DrawSettingBg(w, h, false)
                        draw.SimpleText(title, "VF4_Medium", 15, 10, Color(255, 255, 255), 0, 0)
                    end
                    local mixer = vgui.Create("DColorMixer", p)
                    mixer:SetSize(p:GetWide() - 30, 150)
                    mixer:SetPos(15, 35)
                    mixer:SetPalette(true)
                    mixer:SetAlphaBar(true)
                    mixer:SetWangs(true)
                    
                    local cv = GetConVar(cvarName)
                    local str = cv and cv:GetString() or "255 255 255 255"
                    local exp = string.Explode(" ", str)
                    local r = tonumber(exp[1]) or 255
                    local g = tonumber(exp[2]) or 255
                    local b = tonumber(exp[3]) or 255
                    local a = tonumber(exp[4]) or 255
                    mixer:SetColor(Color(r, g, b, a))
                    
                    mixer.ValueChanged = function(s, col)
                        RunConsoleCommand(cvarName, col.r .. " " .. col.g .. " " .. col.b .. " " .. col.a)
                    end
                    
                    if isLeft then yLeft = yLeft + 210 else yRight = yRight + 210 end
                end
                local function CreateHeader(parent, isLeft, title)
                    local p = vgui.Create("DPanel", parent)
                    p:SetPos(0, isLeft and yLeft or yRight)
                    p:SetSize(parent:GetWide() - 20, 30)
                    p.Paint = function(s, w, h)
                        draw.SimpleText(title, "VF4_Header", 0, h/2, Color(255, 255, 255), 0, 1)
                        surface.SetDrawColor(0, 150, 255, 150)
                        surface.DrawRect(0, h - 2, w, 1)
                    end
                    if isLeft then yLeft = yLeft + 40 else yRight = yRight + 40 end
                end

                local function CreateSlider(parent, isLeft, title, cvarName, min, max, dec)
                    local p = vgui.Create("DPanel", parent)
                    p:SetPos(0, isLeft and yLeft or yRight)
                    p:SetSize(parent:GetWide() - 20, 50)
                    local cv = GetConVar(cvarName)
                    local val = cv and cv:GetFloat() or min
                    local dragging = false
                    p.Paint = function(s, w, h)
                        DrawSettingBg(w, h, s:IsHovered() or dragging)
                        draw.SimpleText(title, "VF4_Medium", 15, 12, Color(255, 255, 255), 0, 1)
                        local displayVal = math.Round(val, dec)
                        draw.SimpleText(tostring(displayVal), "VF4_Medium", w - 20, 12, Color(0, 150, 255), 2, 1)
                        local trackX, trackY, trackW, trackH = 15, h - 15, w - 30, 2
                        surface.SetDrawColor(50, 50, 50, 255)
                        surface.DrawRect(trackX, trackY, trackW, trackH)
                        local pct = math.Clamp((val - min) / (max - min), 0, 1)
                        surface.SetDrawColor(0, 150, 255, 255)
                        surface.DrawRect(trackX, trackY, trackW * pct, trackH)
                        local knobX = trackX + (trackW * pct)
                        draw.RoundedBox(4, knobX - 4, trackY - 3, 8, 8, Color(255, 255, 255))
                    end
                    local function UpdateValue(mx)
                        local trackX = 15
                        local trackW = p:GetWide() - 30
                        local pct = math.Clamp((mx - trackX) / trackW, 0, 1)
                        val = min + (pct * (max - min))
                        if cv then cv:SetFloat(math.Round(val, dec)) end
                    end
                    p.OnMousePressed = function(s) dragging = true; s:MouseCapture(true); UpdateValue(s:CursorPos()) end
                    p.OnMouseReleased = function(s) dragging = false; s:MouseCapture(false) end
                    p.OnCursorMoved = function(s, mx, my) if dragging then UpdateValue(mx) end end
                    if isLeft then yLeft = yLeft + 60 else yRight = yRight + 60 end
                end

                local function CreateToggle(parent, isLeft, title, cvarName, func)
                    local p = vgui.Create("DButton", parent)
                    p:SetPos(0, isLeft and yLeft or yRight)
                    p:SetSize(parent:GetWide() - 20, 40)
                    p:SetText("")
                    local cv = GetConVar(cvarName)
                    local enabled = cv and cv:GetBool() or false
                    if cvarName == "virtus_ivosam_sound" and not cv then
                        CreateClientConVar("virtus_ivosam_sound", "1", true, false)
                        enabled = true
                    end
                    p.Paint = function(s, w, h)
                        DrawSettingBg(w, h, s:IsHovered())
                        draw.SimpleText(title, "VF4_Medium", 15, h/2, Color(255, 255, 255), 0, 1)
                        local switchW = 30
                        local switchH = 14
                        local switchX = w - switchW - 15
                        local switchY = h/2 - switchH/2
                        draw.RoundedBox(8, switchX, switchY, switchW, switchH, enabled and Color(0, 150, 255, 100) or Color(50, 50, 50, 255))
                        local knobSize = 10
                        local knobX = enabled and (switchX + switchW - knobSize - 2) or (switchX + 2)
                        draw.RoundedBox(5, knobX, switchY + 2, knobSize, knobSize, enabled and Color(0, 150, 255) or Color(150, 150, 150))
                    end
                    p.DoClick = function(s)
                        if VIRTUSMENU.PlayUI then VIRTUSMENU.PlayUI("navigation/aceptar.wav") end
                        enabled = not enabled
                        RunConsoleCommand(cvarName, enabled and "1" or "0")
                        if func then func(enabled) end
                    end
                    if isLeft then yLeft = yLeft + 50 else yRight = yRight + 50 end
                end

                local function CreateButtonSetting(parent, isLeft, title, btnText, func)
                    local p = vgui.Create("DPanel", parent)
                    p:SetPos(0, isLeft and yLeft or yRight)
                    p:SetSize(parent:GetWide() - 20, 40)
                    p.Paint = function(s, w, h)
                        DrawSettingBg(w, h, false)
                        draw.SimpleText(title, "VF4_Medium", 15, h/2, Color(255, 255, 255), 0, 1)
                    end
                    local btn = vgui.Create("DButton", p)
                    btn:SetSize(120, 24)
                    btn:SetPos(p:GetWide() - 135, 8)
                    btn:SetText(btnText)
                    btn:SetFont("VF4_Small_Bold")
                    btn:SetTextColor(Color(255, 255, 255))
                    btn.Paint = function(s, w, h)
                        draw.RoundedBox(0, 0, 0, w, h, s:IsHovered() and Color(0, 150, 255) or Color(40, 40, 40))
                    end
                    if i == 1 then firstBtn = btn end
                
                btn.DoClick = function(s)
                        if VIRTUSMENU.PlayUI then VIRTUSMENU.PlayUI("navigation/aceptar.wav") end
                        func(s)
                    end
                    if isLeft then yLeft = yLeft + 50 else yRight = yRight + 50 end
                end

                local function CreateKeyBind(parent, isLeft, title, cvarName, defaultKey)
                    local p = vgui.Create("DPanel", parent)
                    p:SetPos(0, isLeft and yLeft or yRight)
                    p:SetSize(parent:GetWide() - 20, 40)
                    p.Paint = function(s, w, h)
                        DrawSettingBg(w, h, false)
                        draw.SimpleText(title, "VF4_Medium", 15, h/2, Color(255, 255, 255), 0, 1)
                    end
                    local binder = vgui.Create("DBinder", p)
                    binder:SetSize(90, 26)
                    binder:SetPos(p:GetWide() - 135, 7)
                    binder:SetFont("VF4_Medium")
                    binder:SetTextColor(Color(0,0,0,0)) -- hide native text to avoid overlap
                    local cv = GetConVar(cvarName)
                    binder:SetSelectedNumber(cv and cv:GetInt() or defaultKey)
                    binder.Paint = function(s, w, h)
                        local bgCol = s:IsHovered() and Color(30, 80, 130) or Color(20, 25, 30)
                        draw.RoundedBox(0, 0, 0, w, h, bgCol)
                        surface.SetDrawColor(0, 150, 255, 100)
                        surface.DrawOutlinedRect(0, 0, w, h)
                        local txt = s:GetText()
                        if not txt or txt == "" or txt == SafeUpper(input.GetKeyName(s:GetValue()) or "") then 
                            local keyNum = s:GetValue()
                            if keyNum == 0 then
                                txt = "NINGUNO"
                            else
                                txt = SafeUpper(input.GetKeyName(keyNum) or "NINGUNO")
                            end
                        end
                        draw.SimpleText(txt, "VF4_Medium", w/2, h/2, Color(0, 150, 255), 1, 1)
                    end
                    binder.OnChange = function(self, numKey)
                        local c = GetConVar(cvarName)
                        if c then
                            c:SetInt(numKey)
                        else
                            RunConsoleCommand(cvarName, tostring(numKey))
                        end
                    end

                    local clearBtn = vgui.Create("DButton", p)
                    clearBtn:SetSize(26, 26)
                    clearBtn:SetPos(p:GetWide() - 35, 7)
                    clearBtn:SetText("X")
                    clearBtn:SetFont("VF4_Medium")
                    clearBtn:SetTextColor(Color(255, 100, 100))
                    clearBtn.Paint = function(s, w, h)
                        draw.RoundedBox(0, 0, 0, w, h, s:IsHovered() and Color(150, 50, 50, 50) or Color(20, 25, 30))
                        surface.SetDrawColor(255, 100, 100, 100)
                        surface.DrawOutlinedRect(0, 0, w, h)
                    end
                    clearBtn.DoClick = function()
                        binder:SetValue(0)
                        binder:OnChange(0)
                    end

                    if isLeft then yLeft = yLeft + 50 else yRight = yRight + 50 end
                end

                if activeSubTab == "INTERFAZ" then
                    CreateHeader(leftScroll, true, "VISIBILIDAD")
                    CreateToggle(leftScroll, true, "MODO CINEMATICO (OCULTAR HUD)", "virtus_hide_hud")
                    CreateToggle(leftScroll, true, "OCULTAR BRUJULA", "virtus_hide_compass")
                    
                    CreateHeader(leftScroll, true, "METRICAS Y RED")
                    CreateToggle(leftScroll, true, "MOSTRAR METRICAS (NETGRAPH)", "virtus_netgraph_enable", function(val)
                        if val then
                            local ver = GetConVar("virtus_netgraph_detailed"):GetBool() and "5" or "1"
                            RunConsoleCommand("c_netgraph", ver)
                        else
                            RunConsoleCommand("c_netgraph", "0")
                        end
                    end)
                    CreateToggle(leftScroll, true, "VERSION DETALLADA (GRAFICAS)", "virtus_netgraph_detailed", function(val)
                        if GetConVar("virtus_netgraph_enable"):GetBool() then
                            RunConsoleCommand("c_netgraph", val and "5" or "1")
                        end
                    end)
                    
                    CreateHeader(leftScroll, true, "PREVISUALIZACION DE BRUJULA")
                    local compassPreview = vgui.Create("DPanel", leftScroll)
                    compassPreview:SetPos(0, yLeft)
                    compassPreview:SetSize(leftScroll:GetWide() - 20, 120)
                    compassPreview.Paint = function(s, w, h)
                        DrawSettingBg(w, h, false)
                        if _G.DrawMinimalistImperialCompass then _G.DrawMinimalistImperialCompass(true, w/2, 45) end
                    end
                    yLeft = yLeft + 135
                    
                    CreateHeader(leftScroll, true, "AJUSTES DE BRUJULA")
                    CreateSlider(leftScroll, true, "POSICION VERTICAL (Y)", "virtus_compass_y", 0, ScrH() / 2, 0)
                    CreateSlider(leftScroll, true, "ANCHO DE LA BRUJULA", "virtus_compass_width", 300, 1200, 0)
                    CreateSlider(leftScroll, true, "SEPARACION DE GRADOS", "virtus_compass_spacing", 4, 16, 1)
                    
                    CreateHeader(rightScroll, false, "COLORES DE LA INTERFAZ")
                    CreateColorMixerStr(rightScroll, false, "FONDO PRINCIPAL", "virtus_hud_bg")
                    CreateColorMixerStr(rightScroll, false, "COLOR DE ACENTO (HUD Y BRUJULA)", "virtus_compass_col_accent")
                    CreateColorMixerStr(rightScroll, false, "COLOR DEL TEXTO (BRUJULA)", "virtus_compass_col_text")
                    CreateColorMixerStr(rightScroll, false, "COLOR DE LA LINEA (BRUJULA)", "virtus_compass_col_line")
                    CreateColorMixerStr(rightScroll, false, "COLOR EXACTO (NUMEROS)", "virtus_compass_col_exact")
                    
                    CreateHeader(rightScroll, false, "REINICIAR INTERFAZ")
                    CreateButtonSetting(rightScroll, false, "RESTABLECER CONFIGURACION", "RESETEAR", function()
                        RunConsoleCommand("virtus_hide_hud", "0")
                        RunConsoleCommand("virtus_hide_compass", "0")
                        RunConsoleCommand("virtus_compass_y", "40")
                        RunConsoleCommand("virtus_compass_width", "400")
                        RunConsoleCommand("virtus_compass_spacing", "8")
                        RunConsoleCommand("virtus_hud_bg", "10 15 20 160")
                        RunConsoleCommand("virtus_compass_col_accent", "0 150 255 255")
                        RunConsoleCommand("virtus_compass_col_text", "239 240 245 255")
                        RunConsoleCommand("virtus_compass_col_line", "150 150 150 150")
                        RunConsoleCommand("virtus_compass_col_exact", "255 255 255 255")
                        BuildSubTab()
                    end)
                elseif activeSubTab == "ACCESIBILIDAD" then
                    CreateHeader(leftScroll, true, "GRAFICOS Y RENDIMIENTO")
                    CreateToggle(leftScroll, true, "RENDERIZADO MULTINUCLEO (MEJORA FPS)", "gmod_mcore_test")
                    CreateButtonSetting(leftScroll, true, "RECARGAR TEXTURAS Y MODELOS", "RECARGAR", function() 
                        RunConsoleCommand("mat_reloadalltextures")
                    end)
                    
                    CreateHeader(rightScroll, false, "ACCESIBILIDAD Y CAMARA")
                    CreateToggle(rightScroll, false, "CAMARA CINEMATICA (MOVIMIENTO AL APUNTAR)", "virtus_tp_cinematic")
                    CreateToggle(rightScroll, false, "3RA PERSONA DINAMICA (BALANCEO Y PESO)", "virtus_tp_dynamic")
                    CreateToggle(rightScroll, false, "PARALAJE Y HUD 3D (MOVIMIENTO Y RETROCESO)", "virtus_hud_3d")
                elseif activeSubTab == "SONIDO" then
                    CreateHeader(leftScroll, true, "AUDIO Y COMUNICACIONES")
                    CreateSlider(leftScroll, true, "VOLUMEN DE EFECTOS (VFX / UI)", "virtus_vfx_volume", 0, 1, 2)
                    CreateSlider(leftScroll, true, "VOLUMEN DE MUSICA (SERVIDORES)", "music_volume", 0, 1, 2)
                    CreateSlider(leftScroll, true, "VOLUMEN DE AMBIENTE", "ambient_music_volume", 0, 1, 2)
                    
                    CreateHeader(rightScroll, false, "SISTEMAS ADICIONALES")
                    CreateToggle(rightScroll, false, "SONIDO DE SUBIDA DE NIVEL (IVOSAM)", "virtus_ivosam_sound")
                    
                    CreateHeader(rightScroll, false, "COMUNICACIONES DE RADIO")
                    CreateToggle(rightScroll, false, "HABILITAR SISTEMA DE RADIO", "virtus_radio_enabled", function(val)
                        if val then
                            net.Start("virtus_radio_toggle") net.WriteBool(true) net.SendToServer()
                        else
                            net.Start("virtus_radio_toggle") net.WriteBool(false) net.SendToServer()
                        end
                    end)
                    CreateSlider(rightScroll, false, "VOLUMEN DE EFECTOS DE RADIO", "virtus_radio_vol", 0, 1, 2)
                    
                elseif activeSubTab == "CONTROLES" then
                    CreateHeader(leftScroll, true, "BINDS DEL SERVIDOR Y UTILIDADES")
                    CreateKeyBind(leftScroll, true, "TECLA DE TERCERA PERSONA", "virtus_bind_tp", KEY_F1)
                    CreateKeyBind(leftScroll, true, "HABLAR POR RADIO", "virtus_bind_radio_talk", KEY_H)
                    CreateKeyBind(leftScroll, true, "MENU DE FRECUENCIAS", "virtus_bind_radio_menu", KEY_P)
                    CreateKeyBind(leftScroll, true, "MENU DE ANIMACIONES", "virtus_bind_anims", 109)
                    
                    CreateHeader(rightScroll, false, "BINDS DE EQUIPAMIENTO")
                    CreateKeyBind(rightScroll, false, "VISORES (MACROBINO / RANGEFINDER)", "virtus_bind_util", KEY_B)
                    CreateKeyBind(rightScroll, false, "INVISIBILIDAD (SHADOW)", "virtus_bind_invis", KEY_M)
                    CreateKeyBind(rightScroll, false, "RECARGAR ARMA (TFA)", "virtus_bind_tfa_reload", KEY_R)
                    
                    CreateHeader(rightScroll, false, "REINICIAR TODO")
                    CreateButtonSetting(rightScroll, false, "RESETEAR BINDEOS A POR DEFECTO", "RESETEAR", function()
                        RunConsoleCommand("virtus_bind_tp", tostring(KEY_F1))
                        RunConsoleCommand("virtus_bind_radio_talk", tostring(KEY_H))
                        RunConsoleCommand("virtus_bind_radio_menu", tostring(KEY_P))
                        RunConsoleCommand("virtus_bind_anims", "109")
                        RunConsoleCommand("virtus_bind_util", tostring(KEY_B))
                        RunConsoleCommand("virtus_bind_invis", tostring(KEY_M))
                        RunConsoleCommand("virtus_bind_tfa_reload", tostring(KEY_R))
                        BuildSubTab()
                    end)
                    
                    CreateHeader(leftScroll, true, "BINDEOS CUSTOMIZADOS DE CHAT/CONSOLA")
                    
                    local pCustom = vgui.Create("DPanel", leftScroll)
                    pCustom:SetPos(0, yLeft)
                    pCustom:SetSize(leftScroll:GetWide() - 20, 280)
                    pCustom.Paint = function(s, w, h)
                        DrawSettingBg(w, h, false)
                        draw.SimpleText("COMANDO (Ej: say /me saluda)", "VF4_Medium", 10, 10, Color(200,200,200), 0, 0)
                    end
                    local txtCmdStr = ""
                    local txtCmd = vgui.Create("DButton", pCustom)
                    txtCmd:SetPos(10, 35)
                    txtCmd:SetSize(pCustom:GetWide() - 20, 30)
                    txtCmd:SetText("")
                    txtCmd.Paint = function(s, w, h)
                        draw.RoundedBox(0, 0, 0, w, h, Color(20, 25, 30))
                        surface.SetDrawColor(0, 150, 255, 100)
                        surface.DrawOutlinedRect(0, 0, w, h)
                        local displayTxt = txtCmdStr == "" and "Click para escribir comando..." or txtCmdStr
                        draw.SimpleText(displayTxt, "VF4_Medium", 10, h/2, txtCmdStr == "" and Color(150,150,150) or Color(255,255,255), 0, 1)
                    end
                    txtCmd.DoClick = function(s)
                        Derma_StringRequest("NUEVO BIND", "Ingresa el comando (Ej: say hola):", txtCmdStr, function(txt)
                            txtCmdStr = txt
                        end)
                    end
                    
                    local lblKey = vgui.Create("DLabel", pCustom)
                    lblKey:SetPos(10, 75)
                    lblKey:SetText("TECLADO VIRTUAL:")
                    lblKey:SetFont("VF4_Medium")
                    lblKey:SizeToContents()
                    
                    local selectedKey = -1
                    
                    local keyboardPnl = vgui.Create("DPanel", pCustom)
                    keyboardPnl:SetPos(10, 100)
                    keyboardPnl:SetSize(pCustom:GetWide() - 20, 140)
                    keyboardPnl.Paint = nil
                    
                    local rows = {
                        {KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0},
                        {KEY_Q, KEY_W, KEY_E, KEY_R, KEY_T, KEY_Y, KEY_U, KEY_I, KEY_O, KEY_P},
                        {KEY_A, KEY_S, KEY_D, KEY_F, KEY_G, KEY_H, KEY_J, KEY_K, KEY_L},
                        {KEY_Z, KEY_X, KEY_C, KEY_V, KEY_B, KEY_N, KEY_M}
                    }
                    
                    local btnW, btnH = 38, 30
                    local spacing = 5
                    
                    for r, rowKeys in ipairs(rows) do
                        local rowW = (#rowKeys * btnW) + ((#rowKeys - 1) * spacing)
                        local offsetX = (keyboardPnl:GetWide() - rowW) / 2
                        local offsetY = (r - 1) * (btnH + spacing)
                        
                        for c, kEnum in ipairs(rowKeys) do
                            local kBtn = vgui.Create("DButton", keyboardPnl)
                            kBtn:SetSize(btnW, btnH)
                            kBtn:SetPos(offsetX + (c - 1) * (btnW + spacing), offsetY)
                            kBtn:SetText("")
                            local kName = input.GetKeyName(kEnum)
                            kBtn.Paint = function(s, w, h)
                                local isSel = (selectedKey == kEnum)
                                local bg = isSel and Color(0, 150, 255) or (s:IsHovered() and Color(40, 40, 40) or Color(20, 25, 30))
                                draw.RoundedBox(4, 0, 0, w, h, bg)
                                surface.SetDrawColor(0, 150, 255, isSel and 255 or 50)
                                surface.DrawOutlinedRect(0, 0, w, h)
                                draw.SimpleText(kName and SafeUpper(kName) or "?", "VF4_Header", w/2, h/2, isSel and Color(255,255,255) or Color(200,200,200), 1, 1)
                            end
                            kBtn.DoClick = function()
                                selectedKey = kEnum
                                VIRTUSMENU.PlayUI("navigation/movimiento.wav")
                            end
                        end
                    end
                    
                    local btnAddBind = vgui.Create("DButton", pCustom)
                    btnAddBind:SetSize(pCustom:GetWide() - 20, 30)
                    btnAddBind:SetPos(10, 245)
                    btnAddBind:SetText("GUARDAR BIND SELECCIONADO")
                    btnAddBind:SetFont("VF4_Medium")
                    btnAddBind:SetTextColor(Color(255,255,255))
                    btnAddBind.Paint = function(s, w, h)
                        draw.RoundedBox(0, 0, 0, w, h, s:IsHovered() and Color(0, 150, 255) or Color(20, 100, 20))
                    end
                    btnAddBind.DoClick = function(s)
                        if txtCmdStr != "" and selectedKey > 0 then
                            local keyName = input.GetKeyName(selectedKey)
                            VIRTUSMENU.AddBind(selectedKey, txtCmdStr)
                            VIRTUSMENU.Query("Bind guardado correctamente en la tecla " .. SafeUpper(keyName) .. ".\nSistema de Bindeos Virtus activo.", "EXITO", "OK", function() end)
                        end
                    end
                    
                    yLeft = yLeft + 290
                    
                elseif activeSubTab == "SISTEMAS EXTERNOS" then
                    CreateHeader(leftScroll, true, "VEHICULOS LVS")
                    CreateButtonSetting(leftScroll, true, "ABRIR MENU DE CONFIGURACION LVS", "ABRIR LVS", function()
                        gui.HideGameUI()
                        if IsValid(VIRTUSMENU.EscapeMenu) then VIRTUSMENU.EscapeMenu:Remove() end
                        RunConsoleCommand("lvs_openmenu")
                        RunConsoleCommand("lvs_settings")
                    end)
                    
                                        CreateHeader(rightScroll, false, "ARMAS TFA BASE")
                    CreateButtonSetting(rightScroll, false, "ABRIR MENU DE CONFIGURACION TFA", "ABRIR TFA", function()
                        gui.HideGameUI()
                        if IsValid(VIRTUSMENU.EscapeMenu) then VIRTUSMENU.EscapeMenu:Remove() end
                        RunConsoleCommand("cl_tfa_options")
                    end)
                    CreateTFACrosshairPreview(rightScroll, false)
                    CreateColorMixerStr(rightScroll, false, "COLOR DE LA MIRA TFA (HUD STAR WARS)", "tfa_sw_hud_crosshair_color")
                elseif activeSubTab == "CREDITOS" then
                    local txt = "VIRTUS STUDIOS - SISTEMA IMPERIAL\n--------------------------------------------------\n\nDesarrollo Principal: Equipo de Virtus Studios\nAsistencia Tecnica de IA: Antigravity AI\n\nMotor: Garry's Mod (Source Engine)\nSistemas Integrados: DarkRP, TFA Base, SAM Admin\n\nGracias por formar parte de esta comunidad."
                    local lbl = vgui.Create("DLabel", leftScroll)
                    lbl:SetText(txt)
                    lbl:SetFont("VF4_Medium")
                    lbl:SetTextColor(Color(0, 150, 255))
                    lbl:SizeToContents()
                    lbl:SetPos(0, yLeft)
                    yLeft = yLeft + 150
                end
            end
            
            BuildSubTab()
        end
    end
    -- =============================================== --
    
            -- ======= MINI TABS SUPERIORES (SOCIAL / PERFIL) ======= --
    local ply = LocalPlayer()
    local topPnl = vgui.Create("DPanel", VIRTUSMENU.EscapeMenu)
    topPnl:SetPos(ScrW() - 60, ScrH() - 220)
    topPnl:SetSize(50, 160)
    topPnl:SetZPos(100)
    topPnl.Paint = nil
    
    local function CreateTinyTab(y, iconMat, title, doClick, isAvatar)
        local btn = vgui.Create("DButton", topPnl)
        btn:SetPos(0, y)
        btn:SetSize(45, 45)
        btn:SetText("")
        btn.HoverP = 0
        
        if isAvatar then
            btn.Avatar = vgui.Create("AvatarImage", btn)
            btn.Avatar:SetSize(35, 35)
            btn.Avatar:SetPos(5, 5)
            btn.Avatar:SetPlayer(ply, 64)
            btn.Avatar:SetMouseInputEnabled(false)
        end
        
        btn.Paint = function(s, bw, bh)
            s.HoverP = Lerp(FrameTime() * 12, s.HoverP, s:IsHovered() and 1 or 0)
            local colorAcc = Color(0, 150, 255)
            
            local bordeAlpha = 50 + (s.HoverP * 155)
            draw.RoundedBox(8, 0, 0, bw, bh, Color(colorAcc.r, colorAcc.g, colorAcc.b, bordeAlpha))
            
            draw.RoundedBox(8, 1, 1, bw - 2, bh - 2, Color(10, 15, 20, 200))
            
            if s.HoverP > 0.01 then
                draw.RoundedBox(8, 1, 1, bw - 2, bh - 2, Color(colorAcc.r, colorAcc.g, colorAcc.b, s.HoverP * 45))
            end
            
            if iconMat then
                surface.SetMaterial(iconMat)
                surface.SetDrawColor(255, 255, 255, 150 + s.HoverP * 105)
                surface.DrawTexturedRect(bw/2 - 12, bh/2 - 12, 24, 24)
            end
        end
        btn.DoClick = function(s)
            if VIRTUSMENU.PlayUI then VIRTUSMENU.PlayUI("navigation/aceptar.wav") end
            if doClick then doClick(s) end
        end
        
        return btn
    end
    
    local function CreateDropdown(s, dw, dh, populateFunc)
        if IsValid(VIRTUSMENU.ActiveDropdown) then
            if VIRTUSMENU.ActiveDropdown.ParentBtn == s then
                local bx, by = s:LocalToScreen(0, 0)
                local pbx, pby = VIRTUSMENU.EscapeMenu:ScreenToLocal(bx, by)
                local endX = pbx - dw - 5
                local endY = pby + s:GetTall() - dh
                VIRTUSMENU.ActiveDropdown:SizeTo(0, dh, 0.2, 0, -1, function()
                    if IsValid(VIRTUSMENU.ActiveDropdown) then VIRTUSMENU.ActiveDropdown:Remove() end
                end)
                VIRTUSMENU.ActiveDropdown:MoveTo(pbx, endY, 0.2, 0, -1)
                return
            end
            VIRTUSMENU.ActiveDropdown:Remove()
        end
        local bx, by = s:LocalToScreen(0, 0)
        local pbx, pby = VIRTUSMENU.EscapeMenu:ScreenToLocal(bx, by)
        
        local endX = pbx - dw - 5
        local endY = pby + s:GetTall() - dh
        
        local d = vgui.Create("DPanel", VIRTUSMENU.EscapeMenu)
        VIRTUSMENU.ActiveDropdown = d
        d:SetZPos(105)
        d.ParentBtn = s
        
        local startX = pbx
        
        d:SetPos(startX, endY)
        d:SetSize(0, dh)
        d:SizeTo(dw, dh, 0.2, 0, -1)
        d:MoveTo(endX, endY, 0.2, 0, -1)
        d.Paint = function(self, pw, ph)
            draw.RoundedBox(8, 0, 0, pw, ph, Color(0, 150, 255, 50))
            draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(15, 20, 25, 245))
        end
        
        -- Inner panel to prevent clipping during animation
        local inner = vgui.Create("DPanel", d)
        inner:Dock(FILL)
        inner.Paint = nil
        populateFunc(inner)
    end

    local profileTab = CreateTinyTab(0, nil, function() return SafeUpper(ply.SteamName and ply:SteamName() or ply:Nick()) end, function() SwitchTab("CARRERA") end, true)
    
    local function countFriends()
        local c = 0
        for _, p in ipairs(player.GetAll()) do
            if p ~= ply and p:GetFriendStatus() == "friend" then c = c + 1 end
        end
        return c
    end

    local amigosTab = CreateTinyTab(50, Material("icon16/group.png"), function() 
        local fc = countFriends()
        return fc > 0 and ("AMIGOS (" .. fc .. ")") or "AMIGOS"
    end, function(s)
        CreateDropdown(s, 300, 250, function(pop)
            local scroll = vgui.Create("DScrollPanel", pop)
            scroll:Dock(FILL)
            scroll:DockMargin(5, 5, 5, 5)
            VIRTUSMENU.StyleScroll(scroll)
            local y = 0
            local friendsFound = false
            for _, p in ipairs(player.GetAll()) do
                if p ~= ply and p:GetFriendStatus() == "friend" then
                    friendsFound = true
                    local pnl = vgui.Create("DPanel", scroll)
                    pnl:SetPos(0, y)
                    pnl:SetSize(280, 40)
                    pnl.Paint = function(self, w, h)
                        draw.RoundedBox(0, 0, 0, w, h, Color(20, 25, 30, 200))
                        surface.SetDrawColor(0, 150, 255, 50)
                        surface.DrawOutlinedRect(0, 0, w, h)
                        draw.SimpleText(SafeUpper(p:Nick()), "VF4_Small", 50, h/2, Color(255,255,255), 0, 1)
                    end
                    local av = vgui.Create("AvatarImage", pnl)
                    av:SetSize(30, 30)
                    av:SetPos(5, 5)
                    av:SetPlayer(p, 32)
                    y = y + 45
                end
            end
            if not friendsFound then
                local lbl = vgui.Create("DLabel", pop)
                lbl:SetText("NO HAY AMIGOS CONECTADOS")
                lbl:SetFont("VF4_Small")
                lbl:SetTextColor(Color(150,150,150))
                lbl:SizeToContents()
                lbl:SetPos(300/2 - lbl:GetWide()/2, 250/2 - lbl:GetTall()/2)
            end
        end)
    end, false)
    
    local escuadronesTab = CreateTinyTab(100, Material("icon16/shield.png"), "ESCUADRONES", function(s)
        VIRTUSMENU.PlayUI("navigation/aceptar.wav")
        CreateDropdown(s, 300, 250, function(pop)
            local lbl = vgui.Create("DLabel", pop)
            lbl:SetText("INVITAR AMIGOS")
            lbl:SetFont("VF4_Small")
            lbl:SetTextColor(Color(0,150,255))
            lbl:SizeToContents()
            lbl:SetPos(10, 10)
            
            local scroll = vgui.Create("DScrollPanel", pop)
            scroll:SetPos(5, 30)
            scroll:SetSize(290, 215)
            VIRTUSMENU.StyleScroll(scroll)
            
            local y = 0
            local amigosCount = 0
            for _, p in ipairs(player.GetAll()) do
                if p ~= ply and p:GetFriendStatus() == "friend" then
                    amigosCount = amigosCount + 1
                    local pnl = vgui.Create("DPanel", scroll)
                    pnl:SetPos(0, y)
                    pnl:SetSize(280, 40)
                    pnl.Paint = function(self, w, h)
                        draw.RoundedBox(0, 0, 0, w, h, Color(20, 25, 30, 200))
                        draw.SimpleText(SafeUpper(p:Nick()), "VF4_Small", 10, h/2, Color(255,255,255), 0, 1)
                    end
                    local btnInv = vgui.Create("DButton", pnl)
                    btnInv:SetPos(200, 5)
                    btnInv:SetSize(70, 30)
                    btnInv:SetText("INVITAR")
                    btnInv:SetTextColor(Color(255,255,255))
                    btnInv.Paint = function(self, w, h)
                        draw.RoundedBox(0, 0, 0, w, h, self:IsHovered() and Color(0, 150, 255) or Color(50, 50, 50))
                    end
                    btnInv.DoClick = function()
                        VIRTUSMENU.PlayUI("navigation/aceptar.wav")
                        btnInv:SetText("ENVIADO")
                        btnInv:SetEnabled(false)
                    end
                    y = y + 45
                end
            end
            
            if amigosCount == 0 then
                local noneLbl = vgui.Create("DLabel", pop)
                noneLbl:SetText("NO HAY AMIGOS PARA INVITAR")
                noneLbl:SetFont("VF4_Small")
                noneLbl:SetTextColor(Color(150,150,150))
                noneLbl:SizeToContents()
                noneLbl:SetPos(300/2 - noneLbl:GetWide()/2, 250/2 - noneLbl:GetTall()/2)
            end
        end)
    end, false)

    -- =================================================================== --
    -- SISTEMA DE NAVEGACION SUPERIOR (PESTAÑAS + TECLAS Q/E)
    -- =================================================================== --
    local tabOrder = {"INICIO", "CARRERA", "BARRACON", "FACCIONES", "PROGRESO", "AJUSTES"}
    
    local function GetNextTab(dir)
        local currentIndex = 1
        for i, tab in ipairs(tabOrder) do
            if currentTab == tab then currentIndex = i; break end
        end
        
        local nextIndex = currentIndex + dir
        if nextIndex > #tabOrder then nextIndex = 1 end
        if nextIndex < 1 then nextIndex = #tabOrder end
        
        return tabOrder[nextIndex]
    end

    -- Hook interno para capturar Q y E sin spamear
    VIRTUSMENU.EscapeMenu.LastTabSwitch = 0
    VIRTUSMENU.EscapeMenu.Think = function(self)
        -- Obtenemos qué elemento tiene la atención del teclado
        local focus = vgui.GetKeyboardFocus()
        -- Si el elemento es una caja de texto (TextEntry), no hacemos nada para dejarte escribir
        if IsValid(focus) and focus:GetClassName() == "TextEntry" then return end

        -- Retraso de 0.25s para que no saltes 3 pestañas de un solo toque
        if SysTime() - self.LastTabSwitch < 0.25 then return end

        if input.IsKeyDown(KEY_Q) then
            SwitchTab(GetNextTab(-1))
            if VIRTUSMENU.PlayUI then VIRTUSMENU.PlayUI("navigation/movimiento.wav") end
            self.LastTabSwitch = SysTime()
        elseif input.IsKeyDown(KEY_E) then
            SwitchTab(GetNextTab(1))
            if VIRTUSMENU.PlayUI then VIRTUSMENU.PlayUI("navigation/movimiento.wav") end
            self.LastTabSwitch = SysTime()
        end
    end

    local navX = 480

    -- Crea los recuadros visuales de las teclas (HUD)
    -- Crea los recuadros visuales de las teclas (HUD redondeado estilo MENU GMOD)
    local function AddKeyUI(text, keyEnum, dir)
        local btn = vgui.Create("DButton", VIRTUSMENU.EscapeMenu)
        btn:SetSize(32, 32)
        btn:SetPos(navX, 77)
        btn:SetText("")
        btn.HoverP = 0
        btn.Paint = function(s, pw, ph)
            local isPressed = input.IsKeyDown(keyEnum)
            
            -- Prevenir que se active al escribir en la consola/chat
            local focus = vgui.GetKeyboardFocus()
            if IsValid(focus) and focus:GetClassName() == "TextEntry" then isPressed = false end

            -- Se activa tanto si presionas la tecla física como si pones el ratón encima
            local isActive = isPressed or s:IsHovered()
            
            -- Transición suave (Lerp) idéntica a la del botón inferior
            s.HoverP = Lerp(FrameTime() * 12, s.HoverP or 0, isActive and 1 or 0)
            
            -- 1. Fondo base inactivo (Gris oscuro/transparente con bordes redondeados)
            -- Nota: Usa '8' para un cuadrado redondeado o '16' si quieres que sea un círculo perfecto
            draw.RoundedBox(8, 0, 0, pw, ph, Color(15, 20, 25, 200))
            
            -- 2. Fondo activo (Se llena de blanco brillante según el Lerp)
            if s.HoverP > 0.01 then
                draw.RoundedBox(8, 0, 0, pw, ph, Color(255, 255, 255, s.HoverP * 255))
            end

            -- 3. Transición del color del texto (De gris claro a negro absoluto)
            local txtR = Lerp(s.HoverP, 180, 0)
            local txtG = Lerp(s.HoverP, 180, 0)
            local txtB = Lerp(s.HoverP, 180, 0)

            draw.SimpleText(text, "VF4_Header", pw/2, ph/2, Color(txtR, txtG, txtB, 255), 1, 1)
        end
        
        btn.DoClick = function()
            SwitchTab(GetNextTab(dir))
            if VIRTUSMENU.PlayUI then VIRTUSMENU.PlayUI("navigation/movimiento.wav") end
        end
        
        navX = navX + 42 -- Espacio ajustado
    end

    -- 1. Añadimos el HUD de la tecla Q (Retroceder)
    AddKeyUI("Q", KEY_Q, -1)

    -- 2. Añadimos las pestañas normales
    local function AddTopNav(text, tabID, func)
        surface.SetFont("VF4_Header")
        local tw, th = surface.GetTextSize(text)
        local w = tw + 40
        local btn = vgui.Create("DButton", VIRTUSMENU.EscapeMenu)
        btn:SetSize(w, 36)
        btn:SetPos(navX, 75)
        btn:SetText("")
        btn.HoverP = 0
        btn.OnCursorEntered = function(s) VIRTUSMENU.PlayUI("navigation/movimiento.wav") end
        btn.Paint = function(s, w, h)
            local isActive = (currentTab == tabID)
            s.HoverP = Lerp(FrameTime() * 12, s.HoverP, (s:IsHovered() or isActive) and 1 or 0)
            
            local colorAcc = isActive and Color(255, 170, 0) or Color(0, 150, 255)
            
            local lineW = w * s.HoverP
            if lineW > 0.5 then
                draw.RoundedBox(2, w/2 - lineW/2, h - 3, lineW, 3, colorAcc)
            end
            
            local col = (s:IsHovered() or isActive) and Color(255, 255, 255) or Color(150, 150, 150)
            draw.SimpleText(text, "VF4_Header", w/2, h/2, col, 1, 1)
        end
        btn.DoClick = function(s)
            VIRTUSMENU.PlayUI("navigation/aceptar.wav")
            if func then func() else SwitchTab(tabID) end
        end
        navX = navX + w + 10
    end

    AddTopNav("INICIO", "INICIO")
    AddTopNav("CARRERA", "CARRERA")
    AddTopNav("BARRACON", "BARRACON")
    AddTopNav("FACCIONES", "FACCIONES")
    AddTopNav("PROGRESO", "PROGRESO")
    AddTopNav("AJUSTES", "AJUSTES")

    -- 3. Añadimos el HUD de la tecla E (Avanzar) al final
    AddKeyUI("E", KEY_E, 1)
    -- =================================================================== --

    -- BOTONES INFERIORES
    local function AddBottomButton(text, x, y, func, isDanger)
        surface.SetFont("VF4_Header")
        local tw = surface.GetTextSize(text)
        local btn = vgui.Create("DButton", VIRTUSMENU.EscapeMenu)
        local w = tw + 60
        btn:SetSize(w, 36)
        btn:SetPos(x, y)
        btn:SetText("")
        btn.HoverP = 0
        btn.OnCursorEntered = function(s) VIRTUSMENU.PlayUI("navigation/movimiento.wav") end
        
        btn.Paint = function(s, w, h)
            s.HoverP = Lerp(FrameTime() * 12, s.HoverP, s:IsHovered() and 1 or 0)
            
            -- Solo dibujar fondo si está hovered
            if s.HoverP > 0.01 then
                if isDanger then
                    draw.RoundedBox(16, 0, 0, w, h, Color(230, 50, 50, s.HoverP * 255))
                else
                    draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
                end
            end
            
            -- Colores de texto elegantes
            local txtR, txtG, txtB = 255, 255, 255
            
            if isDanger then
                -- El texto siempre es blanco, el fondo se vuelve rojo intenso
            else
                -- El texto pasa de blanco a negro cuando el fondo se vuelve blanco
                txtR = Lerp(s.HoverP, 200, 0)
                txtG = Lerp(s.HoverP, 200, 0)
                txtB = Lerp(s.HoverP, 200, 0)
            end
            
            draw.SimpleText(text, "VF4_Header", w / 2, h / 2, Color(txtR, txtG, txtB, 255), 1, 1)
        end
        btn.DoClick = function(s)
            VIRTUSMENU.PlayUI("navigation/aceptar.wav")
            if func then func() end
        end
        return btn
    end
    
    local bottomY = ScrH() - 70
    local btnDesconectar = AddBottomButton("DESCONECTAR", 50, bottomY, function() RunConsoleCommand("disconnect") end, true)
    AddBottomButton("MENU GMOD", 50 + btnDesconectar:GetWide() + 30, bottomY, function() 
        if IsValid(VIRTUSMENU.EscapeMenu) then VIRTUSMENU.EscapeMenu:Remove() end 
        gui.ActivateGameUI() 
    end, false)

    VIRTUSMENU.EscapeMenu.SwitchTab = SwitchTab

    -- ======= APARICION DE CLON IMPERIAL ======= --
    local Imperiales = {
        ["Cadetes"] = true,
        ["Clone Troopers"] = true,
        ["Shock Troopers"] = true,
        ["Shadow Unit"] = true,
        ["Altos Mandos"] = true
    }

    local validModels = {}
    for _, job in ipairs(RPExtraTeams or {}) do
        if Imperiales[job.category] then
            local mdl = type(job.model) == "table" and job.model[1] or job.model
            if util.IsValidModel(mdl) then table.insert(validModels, mdl) end
        end
    end
    
    local ply = LocalPlayer()
    local chosenModel = #validModels > 0 and table.Random(validModels) or "models/player/kleiner.mdl"

    local clonePnl = vgui.Create("DModelPanel", VIRTUSMENU.EscapeMenu)
    VIRTUSMENU.EscapeMenu.ClonePanel = clonePnl
    local pnlW = ScrW() * 0.45
    clonePnl:SetSize(pnlW, ScrH())
    clonePnl:SetPos(ScrW(), 0) -- Empieza fuera de pantalla
    clonePnl:SetMouseInputEnabled(false) -- No bloquear clics
    
    -- Animacion de entrada "caminando hacia el menu"
    clonePnl:SetModel(chosenModel)
    clonePnl:SetFOV(32)
    clonePnl:SetCamPos(Vector(120, 0, 42)) -- Camara mas lejos y baja para hacerlo ver imponente
    clonePnl:SetLookAt(Vector(0, 0, 42))
    
    clonePnl:SetAmbientLight(Color(20, 20, 30))
    clonePnl:SetDirectionalLight(BOX_TOP, Color(150, 200, 255))
    clonePnl:SetDirectionalLight(BOX_FRONT, Color(255, 255, 255))
    clonePnl:SetDirectionalLight(BOX_RIGHT, Color(255, 30, 30))
    
    local ent = clonePnl.Entity
    if IsValid(ent) then
        local modelFile = string.GetFileFromFilename(chosenModel)
        local path = "v_bodygroups/" .. modelFile .. ".json"
        if file.Exists(path, "DATA") then
            local data = util.JSONToTable(file.Read(path, "DATA"))
            if data and data.bgs then
                for k, v in pairs(data.bgs) do
                    ent:SetBodygroup(tonumber(k) or 0, tonumber(v) or 0)
                end
            end
            if data and data.skin then
                ent:SetSkin(tonumber(data.skin) or 0)
            end
        end
    end
    
    clonePnl.IsWalking = true
    clonePnl.StartTime = SysTime()
    clonePnl.WalkDuration = 2.5
    
    local walkSeq = -1
    local idleSeq = -1
    
    if IsValid(ent) then
        ent:SetAngles(Angle(0, -25, 0))
        
        for _, name in ipairs({"walk_all", "walk_all_unarmed", "walk_passive", "walk", "walk_hl2", "run_all"}) do
            local s = ent:LookupSequence(name)
            if s and s >= 0 then walkSeq = s; break end
        end
        
        for _, name in ipairs({"idle_subtle", "idle_unarmed", "idle_all_01", "idle", "cidle_all"}) do
            local s = ent:LookupSequence(name)
            if s and s >= 0 then idleSeq = s; break end
        end
        
        if walkSeq >= 0 then
            ent:ResetSequence(walkSeq)
            ent:SetPlaybackRate(0.8) 
        end
    end
    
    local targetX = ScrW() - pnlW + 50
    clonePnl:MoveTo(targetX, 0, 2.5, 0.4, -1, function()
        if IsValid(clonePnl) and IsValid(ent) then
            clonePnl.IsWalking = false
            if idleSeq >= 0 then
                ent:ResetSequence(idleSeq)
                ent:SetPlaybackRate(1) 
            end
        end
    end)
    
    function clonePnl:LayoutEntity(Entity)
        self:RunAnimation()
        local timeElapsed = (SysTime() - self.StartTime) - 0.4 
        local startPos = Vector(-180, 80, 0) 
        local endPos = Vector(0, 0, 0) 
        
        if timeElapsed < 0 then
            Entity:SetPoseParameter("move_x", 0)
            Entity:SetPos(startPos)
        elseif self.IsWalking then
            Entity:SetPoseParameter("move_x", 1)
            Entity:SetPos(LerpVector(math.Clamp(timeElapsed / self.WalkDuration, 0, 1), startPos, endPos))
        else
            Entity:SetPoseParameter("move_x", 0)
            Entity:SetPos(endPos)
        end
    end
    
    VIRTUSMENU.EscapeMenu.UpdateCloneModel = function(newModel, jobData, jobLvl, timeStr, kills, deaths)
        if not IsValid(clonePnl) then return end
        clonePnl:SetModel(newModel)
        local newEnt = clonePnl.Entity
        if not IsValid(newEnt) then return end
        
        -- Cargar bodygroups guardados localmente
        local modelFile = string.GetFileFromFilename(newModel)
        local path = "v_bodygroups/" .. modelFile .. ".json"
        if file.Exists(path, "DATA") then
            local data = util.JSONToTable(file.Read(path, "DATA"))
            if data and data.bgs then
                for k, v in pairs(data.bgs) do
                    newEnt:SetBodygroup(tonumber(k) or 0, tonumber(v) or 0)
                end
            end
            if data and data.skin then
                newEnt:SetSkin(tonumber(data.skin) or 0)
            end
        else
            for i = 0, newEnt:GetNumBodyGroups() - 1 do
                newEnt:SetBodygroup(i, 0)
            end
            newEnt:SetSkin(0)
        end
        
        clonePnl:SetPos(ScrW(), 0)
        clonePnl.IsWalking = true
        clonePnl.StartTime = SysTime()
        clonePnl:MoveTo(ScrW() - ScrW() * 0.45 + 50, 0, 2.5, 0.4, -1, function()
            if IsValid(clonePnl) and IsValid(newEnt) then
                clonePnl.IsWalking = false
                for _, name in ipairs({"idle_subtle", "idle_unarmed", "idle_all_01", "idle", "cidle_all"}) do
                    local s = newEnt:LookupSequence(name)
                    if s and s >= 0 then newEnt:ResetSequence(s); newEnt:SetPlaybackRate(1); break end
                end
            end
        end)
        
        newEnt:SetAngles(Angle(0, -25, 0))
        for _, name in ipairs({"walk_all", "walk_all_unarmed", "walk_passive", "walk", "walk_hl2", "run_all"}) do
            local s = newEnt:LookupSequence(name)
            if s and s >= 0 then newEnt:ResetSequence(s); newEnt:SetPlaybackRate(0.8); break end
        end
        
        -- Si pasamos datos del job, crear la info emergente
        if jobData then
            if IsValid(VIRTUSMENU.EscapeMenu.JobInfoPnl) then VIRTUSMENU.EscapeMenu.JobInfoPnl:Remove() end
            
            local infoPnl = vgui.Create("DPanel", VIRTUSMENU.EscapeMenu)
            infoPnl:SetSize(400, 230)
            infoPnl:SetPos(ScrW(), ScrH() - 300)
            infoPnl:MoveTo(ScrW() - 480, ScrH() - 300, 0.5, 0, -1)
            
            infoPnl.Paint = function(s, w, h)
                draw.RoundedBox(6, 0, 0, w, h, Color(10, 10, 15, 240))
                surface.SetDrawColor(255, 170, 0, 100)
                surface.DrawOutlinedRect(0, 0, w, h)
                
                surface.SetDrawColor(255, 170, 0, 255)
                surface.DrawRect(0, h - 3, w, 3)
                
                draw.SimpleText(SafeUpper(jobData.name), "VF4_Medium", 20, 20, Color(255,255,255), 0, 0)
                
                draw.SimpleText("TIEMPO JUGADO:", "VF4_Small", 20, 60, Color(150,150,150), 0, 0)
                draw.SimpleText(timeStr, "VF4_Header", 20, 80, Color(255,170,0), 0, 0)
                
                draw.SimpleText("ASESINATOS:", "VF4_Small", 20, 110, Color(150,150,150), 0, 0)
                draw.SimpleText(tostring(kills or 0), "VF4_Header", 20, 130, Color(255,170,0), 0, 0)
                
                draw.SimpleText("MUERTES:", "VF4_Small", 200, 110, Color(150,150,150), 0, 0)
                draw.SimpleText(tostring(deaths or 0), "VF4_Header", 200, 130, Color(255,50,50), 0, 0)
            end
            
            local btn = vgui.Create("DButton", infoPnl)
            btn:SetSize(360, 45)
            btn:SetPos(20, 170)
            btn:SetText("DESPLEGAR COMO " .. SafeUpper(jobData.name))
            btn:SetFont("VF4_Small")
            btn:SetTextColor(Color(0, 0, 0))
            btn.HoverP = 0
            btn.Paint = function(s, w, h)
                s.HoverP = Lerp(FrameTime() * 10, s.HoverP, s:IsHovered() and 1 or 0)
                draw.RoundedBox(0, 0, 0, w, h, Color(200 + 55 * s.HoverP, 200 + 55 * s.HoverP, 200 + 55 * s.HoverP))
            end
            btn.DoClick = function()
                VIRTUSMENU.PlayUI("navigation/aceptar.wav")
                RunConsoleCommand("darkrp", jobData.command)
                VIRTUSMENU.EscapeMenu:Remove()
            end
            
            VIRTUSMENU.EscapeMenu.JobInfoPnl = infoPnl
        end
    end

    SwitchTab(startTab or "INICIO")

    -- FIX: OnRemove unificado - desbloquea pantalla negra del InitPostEntity
    VIRTUSMENU.EscapeMenu.OnRemove = function()
        bloquearTodo = false
        VIRTUSMENU.ClearAsteroids()
    end
end

hook.Add("RenderScene", "BloqueoInicialStarWars", function(pos, ang, fov)
    if bloquearTodo and not LocalPlayer():GetNWBool("VIRTUS_NeedsTutorial", false) then
        render.Clear(0, 0, 0, 255)
        return true
    end
end)

hook.Add("InitPostEntity", "AbrirMenuInmediato", function()
    timer.Simple(1, function()
        if LocalPlayer():GetNWBool("VIRTUS_NeedsTutorial", false) then
            -- El tutorial se encargará de destrabar la pantalla y mostrar lo suyo
            bloquearTodo = false
            return
        end
        if not IsValid(VIRTUSMENU.EscapeMenu) then
            VIRTUSMENU.openMenu("INICIO")
        end
    end)
end)

-- Bind para F4
hook.Add("ShowSpare2", "VIRTUSMENU_OpenF4", function()
    if IsValid(VIRTUSMENU.EscapeMenu) then
        VIRTUSMENU.EscapeMenu:Remove()
    else
        VIRTUSMENU.openMenu("FACCIONES")
    end
    return true
end)



















-- Override de IvoSam Sound
if not _G.VIRTUS_OldPlaySound then
    _G.VIRTUS_OldPlaySound = surface.PlaySound
    function surface.PlaySound(snd)
        if (snd == "nivel.wav" or snd == "especialidad.wav" or string.find(snd, "garrysmod/save_load1")) then
            local cv = GetConVar("virtus_ivosam_sound")
            if cv and not cv:GetBool() then return end
        end
        _G.VIRTUS_OldPlaySound(snd)
    end
end

-- Procesador de binds personalizados de Virtus
hook.Add("PlayerButtonDown", "VIRTUS_CustomBindsProcessor", function(ply, key)
    if not IsFirstTimePredicted() then return end
    if ply ~= LocalPlayer() then return end
    if gui.IsConsoleVisible() or gui.IsGameUIVisible() or vgui.GetKeyboardFocus() then return end

    local utilBind = GetConVar("virtus_bind_util")
    if utilBind and key == utilBind:GetInt() then
        RunConsoleCommand("+zoom")
        timer.Simple(0.1, function() RunConsoleCommand("-zoom") end)
    end

    local tfaReload = GetConVar("virtus_bind_tfa_reload")
    if tfaReload and key == tfaReload:GetInt() and key ~= KEY_R then
        RunConsoleCommand("+reload")
        timer.Simple(0.1, function() RunConsoleCommand("-reload") end)
    end
end)















