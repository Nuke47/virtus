local inDimension = false
local isCinematic = false
local isTransitioning = false
local isStaffHelping = false
local transitionStart = 0
local transitionDuration = 1.0

local virtualOffset = Vector(0,0,0)
local tutorialCenter = Vector(0,0,0)
local tutorialCenterSet = false

local step = 0
local targetsAlive = 0
local testQuestions = {
    {
        q = "¿En qué consiste la formación Diamante?",
        opts = { "Ataque frontal", "Defensa perimetral de 360 grados" },
        ans = 2
    },
    {
        q = "¿Qué debes hacer si tu DC-15A se sobrecalienta?",
        opts = { "Realizar el minijuego de enfriamiento", "Lanzarla y usar los puños" },
        ans = 1
    }
}
local currentQuestion = 1

surface.CreateFont("Tutorial_Title", { font = "SansSerifFLF", size = 50, weight = 800, antialias = true, extended = true })
surface.CreateFont("Tutorial_Text", { font = "SansSerifFLF", size = 24, weight = 500, antialias = true, extended = true })

net.Receive("Tutorial_StartCinematic", function()
    inDimension = true
    isCinematic = true
    tutorialCenterSet = false
    virtualOffset = Vector(0,0,0)
    step = 0
    currentQuestion = 1
    
    if VIRTUSMENU and IsValid(VIRTUSMENU.EscapeMenu) then VIRTUSMENU.EscapeMenu:Remove() end
    gui.HideGameUI()
end)

net.Receive("Tutorial_UpdateDimension", function()
    inDimension = net.ReadBool()
    if not inDimension then
        isCinematic = false
        isTransitioning = false
        gui.EnableScreenClicker(false)
    end
end)

net.Receive("Tutorial_StaffEnter", function()
    inDimension = true
    isStaffHelping = true
end)

net.Receive("Tutorial_TargetsSpawned", function()
    targetsAlive = 3
end)

net.Receive("Tutorial_TargetKilled", function()
    targetsAlive = math.max(0, targetsAlive - 1)
    if targetsAlive == 0 and step == 5 then
        step = 8
    end
end)

hook.Add("FinishMove", "Tutorial_Treadmill_CL", function(ply, mv)
    if ply:GetNWBool("InTutorial") then
        local fixedPos = ply.Tutorial_FixedPos or ply:GetNWVector("Tutorial_FixedPos", Vector(0,0,0))
        if fixedPos ~= Vector(0,0,0) then
            if mv:KeyDown(IN_JUMP) or not ply:IsOnGround() then 
                ply.Tutorial_WasJumping = true
                return 
            end
            
            if ply.Tutorial_WasJumping then
                ply.Tutorial_WasJumping = false
                ply.Tutorial_FixedPos = mv:GetOrigin()
                return
            end
            
            local org = mv:GetOrigin()
            org.x = fixedPos.x
            org.y = fixedPos.y
            mv:SetOrigin(org)
        end
    end
end)

hook.Add("Think", "Tutorial_EnvironmentMove", function()
    if inDimension and not isCinematic and not isTransitioning and not isStaffHelping then
        local ply = LocalPlayer()
        local vel = ply:GetVelocity()
        vel.z = 0
        virtualOffset = virtualOffset + (vel * FrameTime())
    end
end)

hook.Add("CalcView", "Tutorial_CinematicCamera", function(ply, pos, angles, fov)
    if isCinematic or isTransitioning then
        local ct = CurTime()
        local orbitAng = Angle(10, ct * 5, 0)
        local orbitPos = ply:GetPos() + Vector(0, 0, 40) - (orbitAng:Forward() * 200)
        
        if isTransitioning then
            local progress = math.Clamp((SysTime() - transitionStart) / transitionDuration, 0, 1)
            local ease = progress * progress * (3 - 2 * progress)
            if progress >= 1 then
                isTransitioning = false
            end
            return { origin = LerpVector(ease, orbitPos, pos), angles = LerpAngle(ease, orbitAng, angles), fov = fov, drawviewer = (ease < 0.95) }
        end
        return { origin = orbitPos, angles = orbitAng, fov = fov, drawviewer = true }
    end
end)

local matSky = Material("vgui/black")
local matStars = Material("effects/spark")
local matBeam = Material("trails/laser")
local matGlow = Material("sprites/light_glow02_add")
local tutorialStars = {}
local tutorialForceMotes = {}

for i=1, 300 do table.insert(tutorialStars, { x = math.random(-8000, 8000), y = math.random(-8000, 8000), z = math.random(-2000, 8000), size = math.random(10, 40) }) end
for i=1, 50 do table.insert(tutorialForceMotes, { x = math.random(-300, 300), y = math.random(-300, 300), z = math.random(-200, 800), speed = math.random(20, 100), phase = math.random(0, 10) }) end

hook.Add("RenderScene", "Tutorial_HideWorld", function(origin, angles, fov)
    if inDimension then
        if not tutorialCenterSet then
            local pPos = LocalPlayer():GetPos()
            tutorialCenter = pPos
            tutorialCenterSet = true
        end
        local center = tutorialCenter - virtualOffset
        render.Clear(12, 14, 18, 255, true, true)
        
        cam.Start3D(origin, angles, fov)
            render.SetMaterial(matSky)
            render.DrawBox(center, Angle(0,0,0), Vector(-10000,-10000,-10000), Vector(10000,10000,10000), Color(255,255,255,255), true)
            render.SetMaterial(matStars)
            for _, s in ipairs(tutorialStars) do render.DrawSprite(center + Vector(s.x, s.y, s.z), s.size, s.size, Color(255,255,255,math.random(100, 255))) end
            
            local ct = CurTime()
            render.SetMaterial(matGlow)
            for _, m in ipairs(tutorialForceMotes) do
                m.z = m.z + m.speed * FrameTime()
                if m.z > 800 then m.z = -200 end
                local xOffset = math.sin(ct * 0.5 + m.phase) * 30
                local yOffset = math.cos(ct * 0.5 + m.phase) * 30
                local p = center + Vector(m.x + xOffset, m.y + yOffset, m.z)
                local distToCam = origin:Distance(p)
                local alpha = math.Clamp(255 - (distToCam * 0.2), 0, 150)
                render.DrawSprite(p, 4, 4, Color(150, 200, 255, alpha))
            end
            
            render.SetMaterial(matBeam)
            for i=1, 5 do
                local radius = i * 120
                local prevPos = center + Vector(math.cos(0)*radius, math.sin(0)*radius, 1)
                local ringColor = Color(80, 150, 255, (i % 3 == 0) and 20 or 5)
                for j=1, 48 do
                    local angle = j * ((math.pi * 2) / 48)
                    local nextPos = center + Vector(math.cos(angle)*radius, math.sin(angle)*radius, 1)
                    render.DrawBeam(prevPos, nextPos, 2, 0, 1, ringColor)
                    prevPos = nextPos
                end
            end
            for i=1, 8 do
                local angle = i * (math.pi / 4)
                render.DrawBeam(center, center + Vector(math.cos(angle)*1200, math.sin(angle)*1200, 1), 1.5, 0, 1, Color(80, 150, 255, 8))
            end
            
            for _, ply in ipairs(player.GetAll()) do
                if not ply:IsDormant() then
                    if ply ~= LocalPlayer() or isCinematic or hook.Run("ShouldDrawLocalPlayer", ply) then
                        ply:DrawModel()
                        if not isCinematic then
                            local wep = ply:GetActiveWeapon()
                            if IsValid(wep) then wep:DrawModel() end
                        end
                    end
                end
            end
            
            for _, ent in ipairs(ents.FindByClass("npc_combine_s")) do
                if not ent:IsDormant() then
                    ent:DrawModel()
                end
            end
        cam.End3D()
        
        local vm = LocalPlayer():GetViewModel()
        if IsValid(vm) and not isCinematic then
            cam.Start3D(origin, angles, fov)
                cam.IgnoreZ(true)
                vm:DrawModel()
                cam.IgnoreZ(false)
            cam.End3D()
        end
        return true
    end
end)

hook.Add("HUDShouldDraw", "Tutorial_HideHUD_Progressive", function(name)
    if inDimension and not isStaffHelping then
        if step < 2 then
            if name == "CHudChat" or name == "HUDPaint" or name == "CHudAll" or name == "CHudGMod" then return true end
            return false
        end
    end
end)

local function DrawInstructorDialog(title, text, options)
    local w, h = ScrW(), ScrH()
    local boxW, boxH = 900, 220
    local bx, by = w/2 - boxW/2, h - boxH - 20
    
    surface.SetDrawColor(0, 0, 0, 220)
    surface.DrawRect(bx, by, boxW, boxH)
    surface.SetDrawColor(255, 180, 0, 200)
    surface.DrawOutlinedRect(bx, by, boxW, boxH, 2)
    surface.DrawRect(bx + 20, by + 50, boxW - 40, 2)
    
    draw.DrawText(title, "Tutorial_Title", w/2, by + 10, Color(255, 180, 0), TEXT_ALIGN_CENTER)
    
    local lines = string.Explode("\n", text)
    for i, line in ipairs(lines) do
        draw.SimpleText(line, "Tutorial_Text", w/2, by + 70 + (i-1)*30, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    
    if not options or #options == 0 then
        draw.SimpleText("[ CLIC IZQ PARA CONTINUAR ]", "Tutorial_Text", w/2, by + boxH - 30, Color(255, 180, 0, 150 + math.sin(CurTime()*5)*100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        local mx, my = input.GetCursorPos()
        for i, opt in ipairs(options) do
            local btnW, btnH = 300, 40
            local btnX = w/2 - (#options * btnW / 2) + (i-1)*btnW + 10
            local btnY = by + boxH - 60
            
            local hovered = (mx > btnX and mx < btnX + btnW and my > btnY and my < btnY + btnH)
            
            surface.SetDrawColor(0, 0, 0, 150)
            surface.DrawRect(btnX, btnY, btnW-20, btnH)
            surface.SetDrawColor(255, 180, 0, hovered and 255 or 100)
            surface.DrawOutlinedRect(btnX, btnY, btnW-20, btnH, 2)
            draw.SimpleText(opt.text, "Tutorial_Text", btnX + (btnW-20)/2, btnY + btnH/2, hovered and Color(255,255,255) or Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            if hovered and input.IsMouseDown(MOUSE_LEFT) and not opt.clicked then
                opt.clicked = true
                surface.PlaySound("UI/buttonclick.wav")
                opt.func()
            elseif not input.IsMouseDown(MOUSE_LEFT) then
                opt.clicked = false
            end
        end
    end
end

hook.Add("HUDPaint", "Tutorial_DrawUI", function()
    if inDimension and not isStaffHelping then
        local w, h = ScrW(), ScrH()
        
        local success, err = pcall(function()
            if step == 0 then
                DrawInstructorDialog("INSTRUCTOR", "Bienvenido recluta al simulador imperial.\nHe sido asignado para guiarte hoy.", nil)
            elseif step == 1 then
                gui.EnableScreenClicker(true)
                DrawInstructorDialog("INSTRUCTOR", "¿Deseas realizar el tutorial de entrenamiento\no ir directamente a la prueba final?", {
                    { text = "Iniciar Tutorial", func = function() step = 2 gui.EnableScreenClicker(false) end },
                    { text = "Iniciar Prueba", func = function() step = 6 gui.EnableScreenClicker(false) end }
                })
            elseif step == 2 then
                DrawInstructorDialog("INSTRUCTOR", "Comenzaremos con las formaciones basicas.\nTu posicionamiento en combate dictara tu supervivencia.\nManten la linea, sigue a tu comandante y aprendelas.")
            elseif step == 3 then
                DrawInstructorDialog("INSTRUCTOR", "Interfaz de Radio.\nUtilizala para coordinar ataques y escuchar reportes de estado.\nPresiona tu bind asignado para hablar por el canal de escuadron.")
                surface.SetDrawColor(255, 180, 0, 150 + math.sin(CurTime()*6)*100)
                surface.DrawOutlinedRect(10, h - 350, 350, 160, 4)
                draw.SimpleText("INTERFAZ DE RADIO", "Tutorial_Text", 185, h - 360, Color(255, 180, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            elseif step == 4 then
                DrawInstructorDialog("INSTRUCTOR", "Te he entregado tu Blaster DC-15A.\nEsta arma tiene un sistema de GAS en vez de recargas normales.\nEvita que se sobrecaliente, usa el Seguro y no la trabes.")
            elseif step == 5 then
                if targetsAlive > 0 then
                    DrawInstructorDialog("INSTRUCTOR", "He desplegado blancos holograficos.\nDispara a los objetivos y destruyelos (" .. targetsAlive .. " restantes).", {{ text = "Destruyendo...", func = function() end }})
                else
                    DrawInstructorDialog("INSTRUCTOR", "Excelente punteria recluta.", nil)
                end
            elseif step == 6 then
                gui.EnableScreenClicker(true)
                local q = testQuestions[currentQuestion]
                if q then
                    local opts = {}
                    for i, text in ipairs(q.opts) do
                        table.insert(opts, { text = text, func = function()
                            if i == q.ans then
                                currentQuestion = currentQuestion + 1
                            else
                                surface.PlaySound("buttons/button10.wav")
                            end
                        end })
                    end
                    DrawInstructorDialog("PRUEBA TEORICA", "Pregunta " .. currentQuestion .. ":\n" .. q.q, opts)
                else
                    gui.EnableScreenClicker(false)
                    step = 7
                end
            elseif step == 7 then
                DrawInstructorDialog("INSTRUCTOR", "Has pasado la parte teorica.\nEn la base deberas demostrar las formaciones a tu comandante.\nClic para graduarte.", nil)
            elseif step == 8 then
                inDimension = false
                step = 0
                gui.EnableScreenClicker(false)
                net.Start("Tutorial_Finish")
                net.SendToServer()
            end
        end)
        if not success then
            draw.SimpleText("UI ERROR: " .. tostring(err), "DermaLarge", 50, 50, Color(255,0,0))
        end
    end
end)

hook.Add("PlayerBindPress", "Tutorial_Advance", function(ply, bind, pressed)
    if inDimension and not isStaffHelping and pressed and string.find(bind, "+attack") then
        if vgui.CursorVisible() then return false end -- Using screen clicker
        
        if isCinematic then
            isCinematic = false
            isTransitioning = true
            transitionStart = SysTime()
            return true
        end
        
        if step == 0 then step = 1 surface.PlaySound("UI/buttonclick.wav") return true
        elseif step == 2 then step = 3 surface.PlaySound("UI/buttonclick.wav") return true
        elseif step == 3 then 
            step = 4 
            surface.PlaySound("UI/buttonclick.wav")
            net.Start("Tutorial_Step_Weapon")
            net.SendToServer()
            return true
        elseif step == 4 then 
            step = 5 
            surface.PlaySound("UI/buttonclick.wav")
            net.Start("Tutorial_SpawnTargets")
            net.SendToServer()
            return true
        elseif step == 5 then
            if targetsAlive == 0 then
                step = 8
                surface.PlaySound("UI/buttonclick.wav")
                return true
            end
        elseif step == 7 then
            step = 8
            surface.PlaySound("UI/buttonclick.wav")
            return true
        elseif step == 8 then
            inDimension = false
            step = 0
            gui.EnableScreenClicker(false)
            net.Start("Tutorial_Finish")
            net.SendToServer()
            return true
        end
    end
end)

hook.Add("Think", "Tutorial_HideCustomHUDs", function()
    local cv = GetConVar("virtus_hide_hud")
    if cv then
        if inDimension and not isStaffHelping then
            if step < 2 or step == 6 or step == 8 then
                if not cv:GetBool() then cv:SetBool(true) end
            else
                if cv:GetBool() then cv:SetBool(false) end
            end
        else
            if cv:GetBool() and LocalPlayer():GetNWBool("VIRTUS_NeedsTutorial") == false then
                cv:SetBool(false)
            end
        end
    end
end)








