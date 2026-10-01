if SERVER then return end

-- 1. CREAMOS LA FUENTE PRIMERO (Evita el error 'w' a nil value)
surface.CreateFont( "MyFont", {
	font = "SansSerifFLF",
	size = 15,
	weight = 500,
	antialias = true,
	shadow = true
})

surface.CreateFont( "DefibHUD_Text", {
	font = "SansSerifFLF",
	size = 16,
	weight = 600,
	antialias = true
})

local scrx, scry = ScrW(), ScrH()
local chargeActive = false
include("shared.lua")

function drawcharge(isCharge)
	local globalwep = weapons.GetStored("weapon_defibrillator")
	if isCharge then
		if CurTime() >= globalwep.CanUse and !chargeActive then
			frame = vgui.Create("DPanel")
			frame:SetSize(400, 40)
			frame:SetPos(scrx/2 - 200, scry - 150) -- Movido hacia la parte inferior
			
			local startTime = CurTime()
			local duration = globalwep.ChargeTime
			
			function frame:Paint(w, h) 
				local progress = math.Clamp((CurTime() - startTime) / duration, 0, 1)
				local remaining = 1 - progress
				
				-- Fondo del HUD estilo Star Wars (Bordes rectos y colores holográficos)
				draw.RoundedBox(0, 0, 0, w, h, Color(10, 10, 15, 240))
				
				-- Bordes holográficos tipo panel sci-fi
				surface.SetDrawColor(0, 180, 255, 200)
				surface.DrawOutlinedRect(0, 0, w, h, 2)
				-- Detalles gruesos en las esquinas
				surface.DrawRect(0, 0, 10, 3)
				surface.DrawRect(0, 0, 3, 10)
				surface.DrawRect(w - 10, 0, 10, 3)
				surface.DrawRect(w - 3, 0, 3, 10)
				surface.DrawRect(0, h - 3, 10, 3)
				surface.DrawRect(0, h - 10, 3, 10)
				surface.DrawRect(w - 10, h - 3, 10, 3)
				surface.DrawRect(w - 3, h - 10, 3, 10)
				
				-- Barra de progreso animada (Empieza llena y se vacía)
				local barW = (w - 12) * remaining
				local r = math.Clamp(255 - (remaining * 255), 50, 255)
				local g = math.Clamp(remaining * 200, 50, 200)
				local b = math.Clamp(remaining * 255, 50, 255)
				
				draw.RoundedBox(0, 6, 6, barW, h - 12, Color(r, g, b, 255))
				
				-- Texto parpadeante inmersivo con fuente de Star Wars ("MyFont")
				local alpha = 155 + math.abs(math.sin(CurTime() * 10)) * 100
				draw.SimpleText("CARGANDO CAPACITORES", "MyFont", w/2, h/2, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				
				if progress >= 1 then self:Remove() end
			end
		end
	else
		if IsValid(frame) then
			frame:Remove()
		end
		if timer.Exists("fadethething") then timer.Destroy("fadethething") end
	end
end

net.Receive("defibfx", function(len)
	local globalwep = weapons.GetStored("weapon_defibrillator")
	local ent = net.ReadEntity()
	local entpos = net.ReadVector()
	local fx = net.ReadString()
	local ply = net.ReadEntity()
	
	if fx == "spark" then
		local sparkData = EffectData()
		sparkData:SetStart(LocalPlayer():GetShootPos()+LocalPlayer():GetForward(50))
		sparkData:SetOrigin(entpos)
		util.Effect("StunstickImpact", sparkData)
	elseif fx == "sound" then
		surface.PlaySound(globalwep.DeathSound)
	elseif fx == "charge" then
		drawcharge(true)
	elseif fx == "decharge" then
		drawcharge(false)
	elseif fx == "toolongdead" then
		if entpos == Vector(1, 1, 1) then notification.AddLegacy("Está muerto. No puedes reanimarlo.", 1, 6)
		else notification.AddLegacy("Estás muerto. No pueden reanimarte.", 1, 6) end
	elseif fx == "timedied" then
		ply.TimeDied = CurTime()
	end
end)

-- SISTEMA DE DETECCIÓN (RAGDOLLS NATIVOS Y MUÑECOS)
net.Receive("defibgetents", function(len)
	local globalwep = weapons.GetStored("weapon_defibrillator")
	local ply = LocalPlayer()
	local targetEnt = nil
	local isRevive = false
	
	for k,v in pairs(ents.FindInSphere(ply:GetPos(), 164)) do
		local class = v:GetClass()
		if (class == "prop_ragdoll" or class == "class C_HL2MPRagdoll") and (v:GetNWBool("IsPlayerCorpse") or v:GetNWBool("IsTestDummy")) then
			if ply:GetPos():Distance(v:GetPos()) <= globalwep.ReviveDistance then
				targetEnt = v
				isRevive = true
				break
			end
		end
	end
	
	if targetEnt == nil then
		local lookat = ply:GetEyeTrace().Entity
		if lookat:IsPlayer() then 
			targetEnt = lookat 
			isRevive = false
		end
	end
	
	if !IsValid(targetEnt) then return end
	
	net.Start("defibgiveents")
	net.WriteBool(isRevive)
	net.WriteEntity(targetEnt)
	net.WriteVector(targetEnt:GetPos())
	net.SendToServer()
end)

local function DrawCircleArc(x, y, radius, thickness, start_ang, end_ang, color)
    draw.NoTexture()
    surface.SetDrawColor(color)
    local step = 3 -- Smooth circle
    for i = start_ang, end_ang - step, step do
        local rad1 = math.rad(i)
        local rad2 = math.rad(i + step)
        local p1 = {x = x + math.cos(rad1) * radius, y = y + math.sin(rad1) * radius}
        local p2 = {x = x + math.cos(rad2) * radius, y = y + math.sin(rad2) * radius}
        local p3 = {x = x + math.cos(rad2) * (radius - thickness), y = y + math.sin(rad2) * (radius - thickness)}
        local p4 = {x = x + math.cos(rad1) * (radius - thickness), y = y + math.sin(rad1) * (radius - thickness)}
        surface.DrawPoly({p1, p2, p3, p4})
    end
    -- Draw the final piece to close the gap exactly at end_ang
    local rad1 = math.rad(end_ang - step)
    local rad2 = math.rad(end_ang)
    local p1 = {x = x + math.cos(rad1) * radius, y = y + math.sin(rad1) * radius}
    local p2 = {x = x + math.cos(rad2) * radius, y = y + math.sin(rad2) * radius}
    local p3 = {x = x + math.cos(rad2) * (radius - thickness), y = y + math.sin(rad2) * (radius - thickness)}
    local p4 = {x = x + math.cos(rad1) * (radius - thickness), y = y + math.sin(rad1) * (radius - thickness)}
    surface.DrawPoly({p1, p2, p3, p4})
end

local function DrawMouseIcon(x, y, scale, leftClick)
    local w, h = 20 * scale, 32 * scale
    draw.RoundedBox(8 * scale, x - w/2, y - h/2, w, h, Color(255, 255, 255, 200))
    draw.RoundedBox(8 * scale, x - w/2 + 2, y - h/2 + 2, w - 4, h - 4, Color(30, 30, 30, 255))
    
    surface.SetDrawColor(255, 255, 255, 200)
    surface.DrawLine(x - w/2, y - h/6, x + w/2, y - h/6)
    surface.DrawLine(x, y - h/2, x, y - h/6)
    
    if leftClick then
        draw.RoundedBoxEx(6 * scale, x - w/2 + 2, y - h/2 + 2, w/2 - 2, h/3, Color(255, 50, 50, 255), true, false, false, false)
    else
        draw.RoundedBoxEx(6 * scale, x, y - h/2 + 2, w/2 - 2, h/3, Color(255, 50, 50, 255), false, true, false, false)
    end
end

hook.Add("HUDPaint", "DrawDefibGUI", function()
	local globalwep = weapons.GetStored("weapon_defibrillator")
	local ply = LocalPlayer()
	local isDefib = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "weapon_defibrillator"
	
	if isDefib then
		for k,v in pairs(ents.GetAll()) do
			local class = v:GetClass()
			if (class == "prop_ragdoll" or class == "class C_HL2MPRagdoll") and v:GetNWBool("IsPlayerCorpse") then 
				local dist = ply:GetPos():Distance(v:GetPos())
				if dist <= globalwep.ReviveHeartDistance then
					cam.Start2D()
					local heartPos = (v:GetPos() + Vector(0, 0, 25)):ToScreen()
					local size = math.Round(math.max(80 - (dist/100)*4, 20))
					local alpha = 150 + math.sin(CurTime() * 4) * 50
					
					surface.SetDrawColor(0, 180, 255, alpha * 0.3)
					surface.DrawRect(heartPos.x - size/2 - 5, heartPos.y - size/2 - 5, size + 10, size + 10)
					surface.SetDrawColor(0, 255, 255, alpha)
					surface.DrawOutlinedRect(heartPos.x - size/2 - 5, heartPos.y - size/2 - 5, size + 10, size + 10, 2)
					surface.SetDrawColor(255, 255, 255, 255)
					surface.SetMaterial(Material("vgui/revive.png"))
					surface.DrawTexturedRect(heartPos.x - size/2, heartPos.y - size/2, size, size)
					
					local stateText = v:GetNWBool("IsUnconscious") and "INCONSCIENTE" or "ESTADO CRÍTICO"
					draw.SimpleTextOutlined(stateText, "DefibHUD_Text", heartPos.x, heartPos.y + size/2 + 10, Color(255, 100, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
					cam.End2D()
				end
			end
		end
	end
	
	if ply:Health() <= 0 and ply.TimeDied != nil then
		local obs = ply:GetObserverTarget()
		local isUnconscious = IsValid(obs) and obs:GetNWBool("IsUnconscious")
		
		if isUnconscious then
			-- Más oscuro (oscila entre 195 y 255) y más lento (multiplicador 1)
			local fadeAlpha = 225 + math.sin(CurTime() * 1) * 30
			surface.SetDrawColor(0, 0, 0, fadeAlpha)
			surface.DrawRect(0, 0, ScrW(), ScrH())
		end
		
        local totalTime = isUnconscious and 120 or (globalwep.disableRespawnTime or 60)
        local timeLeft = (ply.TimeDied + totalTime) - CurTime()
        local progress = math.Clamp(timeLeft / totalTime, 0, 1)

        local reviveTime = globalwep.TimeToRevive or 200
        local timeToReviveLeft = (ply.TimeDied + reviveTime) - CurTime()
        local reviveProgress = math.Clamp(timeToReviveLeft / reviveTime, 0, 1)

        local cx, cy = ScrW()/2, ScrH() - 80
        local radius = 30
        local thickness = 4
        
        -- Background circle (Respawn Skip)
        DrawCircleArc(cx, cy, radius, thickness, 0, 360, Color(255, 255, 255, 50))
        if progress > 0 then
            local endAngle = 360 * progress
            DrawCircleArc(cx, cy, radius, thickness, 0, endAngle, Color(255, 255, 255, 255))
        end
        
        -- Inner circle (Revive Window)
        if not isUnconscious then
            local innerRadius = 24
            local innerThickness = 3
            DrawCircleArc(cx, cy, innerRadius, innerThickness, 0, 360, Color(255, 255, 255, 20))
            if reviveProgress > 0 then
                local innerEndAngle = 360 * reviveProgress
                -- Cyan color for medical revive window
                DrawCircleArc(cx, cy, innerRadius, innerThickness, 0, innerEndAngle, Color(0, 200, 255, 200))
            end
        end
        
        -- Revive Icon inside circle
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(Material("vgui/revive.png"))
        surface.DrawTexturedRect(cx - 14, cy - 14, 28, 28)
        
        -- Call for Help
        local helpX = cx - 120
        DrawMouseIcon(helpX, cy - 10, 1, true)
        draw.SimpleTextOutlined("Pedir Ayuda", "DefibHUD_Text", helpX, cy + 20, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,255))
        
        -- Skip
        local skipX = cx + 120
        DrawMouseIcon(skipX, cy - 10, 1, false)
        draw.SimpleTextOutlined("Desistir", "DefibHUD_Text", skipX, cy + 20, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,255))
	end
end)

local isBleedingOut = false
local wasHelpPressed = false

hook.Add("Think", "DefibBleedOutThink", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if ply:Health() > 0 then 
        if isBleedingOut then
            isBleedingOut = false
            net.Start("DefibDesistir_Hold")
            net.WriteBool(false)
            net.SendToServer()
        end
        return 
    end
    
    local pressingRight = input.IsMouseDown(MOUSE_RIGHT)
    if pressingRight ~= isBleedingOut then
        isBleedingOut = pressingRight
        net.Start("DefibDesistir_Hold")
        net.WriteBool(pressingRight)
        net.SendToServer()
    end
    
    if isBleedingOut and ply.TimeDied then
        -- Sync acceleration with server
        ply.TimeDied = ply.TimeDied - (FrameTime() * 4)
    end
    
    local pressingLeft = input.IsMouseDown(MOUSE_LEFT)
    if pressingLeft and not wasHelpPressed then
        if not ply.DefibLastHelp or CurTime() - ply.DefibLastHelp > 5 then
            ply.DefibLastHelp = CurTime()
            net.Start("DefibPedirAyuda")
            net.SendToServer()
        end
    end
    wasHelpPressed = pressingLeft
end)

hook.Add("PostPlayerDraw", "DefibTwoHanded", function(ply)
	local model = ply.Defib
	local attach = ply:GetAttachment(ply:LookupAttachment("anim_attachment_LH"))
	if !ply or !ply:Alive() or ply:GetActiveWeapon() == NULL or ply:GetActiveWeapon():GetClass() != "weapon_defibrillator" or !attach then 
		if ply.Defib then ply.Defib:Remove(); ply.Defib = nil; end
		return
	end
	if model == nil then
		ply.Defib = ClientsideModel("models/weapons/custom/defib2.mdl")
		model = ply.Defib
	end
	local pos, ang = attach.Pos, attach.Ang
	ang:RotateAroundAxis(ang:Up(), 90)
	ang:RotateAroundAxis(ang:Right(), -60)
	ang:RotateAroundAxis(ang:Forward(), 45)
	pos = attach.Pos + ang:Forward()*0 + ang:Right()*1.5 + ang:Up()*2
	model:SetRenderOrigin(pos)
	model:SetRenderAngles(ang)
	model:SetupBones()
	model:DrawModel()
	model:SetRenderOrigin()
	model:SetRenderAngles()
end)

net.Receive("defib_start_minigame", function()
    local fails = net.ReadInt(4)
    local currentAttempt = fails + 1

    local frame = vgui.Create("DFrame")
    frame:SetSize(550, 400) -- Ventana más grande para el mega-laberinto
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame:ShowCloseButton(false)

    -- Definición de TODOS los caminos seguros (Laberinto Difícil)
    local paths = {
        {x = 30, y = 250, w = 30, h = 100},  -- P1: Subida desde inicio
        {x = 30, y = 250, w = 150, h = 30},  -- P2: Pasillo superior 1
        {x = 100, y = 100, w = 30, h = 150}, -- TRAMPA 1: Sube desde P2
        {x = 150, y = 250, w = 30, h = 100}, -- P3: Bajada a P4
        {x = 150, y = 320, w = 100, h = 30}, -- P4: Pasillo inferior 1
        {x = 220, y = 80, w = 30, h = 270},  -- P5: Subida muy larga central
        {x = 250, y = 180, w = 70, h = 30},  -- TRAMPA 2: Derecha desde P5
        {x = 220, y = 80, w = 200, h = 30},  -- P6: Pasillo superior 2
        {x = 320, y = 110, w = 30, h = 60},  -- TRAMPA 3: Baja desde P6
        {x = 390, y = 80, w = 30, h = 150},  -- P7: Bajada derecha
        {x = 300, y = 200, w = 120, h = 30}, -- P8: Pasillo medio vuelta a la izquierda
        {x = 300, y = 200, w = 30, h = 150}, -- P9: Bajada final
        {x = 300, y = 320, w = 210, h = 30}  -- P10: Pasillo final hacia la meta
    }

    local startZone = {x = 30, y = 320, w = 30, h = 30}
    local endZone = {x = 480, y = 320, w = 30, h = 30}

    -- Obstáculos móviles (Ahora funcionan como puertas/pistones que se abren y cierran)
    local obstacles = {
        {
            -- Puerta 1 en P2 (Pasillo superior 1) - Retrae hacia arriba
            update = function(t)
                local oy = 232 + math.sin(t * 7) * 18
                return 90, oy, 15, 30
            end
        },
        {
            -- Puerta 2 en P5 (Subida larga central) - Retrae hacia la izquierda
            update = function(t)
                local ox = 202 + math.cos(t * 8) * 18
                return ox, 220, 30, 15
            end
        },
        {
            -- Puerta 3 en P6 (Pasillo superior 2) - Retrae hacia arriba
            update = function(t)
                local oy = 62 + math.sin(t * 9) * 18
                return 320, oy, 15, 30
            end
        },
        {
            -- Puerta 4 en P9 (Bajada final) - Retrae hacia la izquierda
            update = function(t)
                local ox = 282 + math.cos(t * 7.5) * 18
                return ox, 260, 30, 15
            end
        },
        {
            -- Puerta 5 en P10 (Pasillo hacia la meta) - Retrae hacia abajo
            update = function(t)
                local oy = 338 + math.sin(t * 12) * 18
                return 390, oy, 15, 30
            end
        }
    }

    local gameState = 0 
    local timeLeft = 18 -- Aumentado a 18 por la mayor dificultad
    local startTime = 0
    local trail = {}
    
    -- Variables para el Nivel 2 (Sincronización de descarga)
    local currentLevel = 1
    local indicatorX = 50
    local indicatorDir = 1
    local level2Speed = 750 -- Velocidad de la barra (px por segundo)
    local wasMouseDown = false

    function frame:Paint(w, h)
        -- Fondo estilo Monitor Cardíaco (EKG)
        draw.RoundedBox(8, 0, 0, w, h, Color(10, 25, 10, 250))
        
        -- Cuadrícula del monitor
        surface.SetDrawColor(20, 50, 20, 100)
        for i = 0, w, 20 do surface.DrawLine(i, 0, i, h) end
        for i = 0, h, 20 do surface.DrawLine(0, i, w, i) end
        
        -- El header ya no cambia a rojo, mantiene siempre el verde general
        local headerColor = Color(30, 80, 30, 255)
        draw.RoundedBox(0, 0, 0, w, 30, headerColor)
        
        if currentLevel == 1 then
            draw.SimpleText("INTENTO " .. currentAttempt .. "/2 - ESTABILIZA EL RITMO CARDÍACO", "DefibHUD_Text", w/2, 8, Color(255,255,255), TEXT_ALIGN_CENTER)

            -- Dibujar Caminos Seguros
            for _, p in ipairs(paths) do
                draw.RoundedBox(0, p.x, p.y, p.w, p.h, Color(40, 120, 40, 255))
            end

            -- Dibujar Zonas de Inicio y Fin
            local pulse = math.abs(math.sin(SysTime() * 4)) * 55
            draw.RoundedBox(0, startZone.x, startZone.y, startZone.w, startZone.h, Color(0, 255, 0, 200 + pulse))
            draw.RoundedBox(0, endZone.x, endZone.y, endZone.w, endZone.h, Color(0, 200, 255, 200 + pulse))

            -- Dibujar Obstáculos (Animados)
            local t = SysTime()
            for _, obs in ipairs(obstacles) do
                local ox, oy, ow, oh = obs.update(t)
                draw.RoundedBox(0, ox, oy, ow, oh, Color(255, 40, 40, 255))
                surface.SetDrawColor(255, 0, 0, 80)
                surface.DrawOutlinedRect(ox - 2, oy - 2, ow + 4, oh + 4)
            end
            
            -- Dibujar estela del cursor (Trail EKG)
            if gameState == 1 then
                local cx, cy = self:CursorPos()
                table.insert(trail, {x = cx, y = cy, time = SysTime()})
                for i = #trail, 1, -1 do
                    if SysTime() - trail[i].time > 0.4 then table.remove(trail, i) end
                end
                surface.SetDrawColor(0, 255, 100, 150)
                for i = 1, #trail - 1 do
                    local p1, p2 = trail[i], trail[i+1]
                    surface.DrawLine(p1.x, p1.y, p2.x, p2.y)
                    surface.DrawLine(p1.x+1, p1.y+1, p2.x+1, p2.y+1)
                end
                draw.RoundedBox(4, cx - 2, cy - 2, 4, 4, Color(255, 255, 255))
            end

            if gameState == 0 then
                draw.SimpleText("Mueve el ratón al cuadro VERDE para iniciar.", "DefibHUD_Text", w/2, 360, Color(150,255,150), TEXT_ALIGN_CENTER)
            elseif gameState == 1 then
                local currentLeft = math.max(0, timeLeft - (SysTime() - startTime))
                draw.SimpleText("Ritmo cayendo en: " .. math.Round(currentLeft, 1) .. "s", "DefibHUD_Text", w/2, 360, Color(255,255,255), TEXT_ALIGN_CENTER)
            end
        else
            -- RENDERIZADO DEL NIVEL 2
            draw.SimpleText("INTENTO " .. currentAttempt .. "/2 - DESCARGA SINCRONIZADA", "DefibHUD_Text", w/2, 8, Color(255,255,255), TEXT_ALIGN_CENTER)
            
            -- Linea base del monitor
            surface.SetDrawColor(0, 150, 0, 150)
            surface.DrawLine(50, h/2, w - 50, h/2)

            -- Zona objetivo
            local targetX = w/2 - 40
            local targetW = 80
            local pulse = math.abs(math.sin(SysTime() * 8)) * 100
            draw.RoundedBox(4, targetX, h/2 - 25, targetW, 50, Color(0, 255, 0, 50 + pulse))
            surface.SetDrawColor(0, 255, 0, 200)
            surface.DrawOutlinedRect(targetX, h/2 - 25, targetW, 50, 2)
            
            -- Barra móvil (Indicador)
            local indW = 6
            draw.RoundedBox(2, indicatorX, h/2 - 35, indW, 70, Color(255, 255, 255, 255))
            
            -- Pistas visuales (estela de la barra)
            surface.SetDrawColor(0, 255, 100, 100)
            surface.DrawLine(indicatorX + indW/2, h/2, indicatorX - (indicatorDir * 30), h/2)

            if gameState == 1 then
                local currentLeft = math.max(0, timeLeft - (SysTime() - startTime))
                draw.SimpleText("¡HAZ CLICK IZQUIERDO EN LA ZONA VERDE!", "DefibHUD_Text", w/2, 330, Color(150,255,150), TEXT_ALIGN_CENTER)
                draw.SimpleText("Tiempo límite: " .. math.Round(currentLeft, 1) .. "s", "DefibHUD_Text", w/2, 360, Color(255,255,255), TEXT_ALIGN_CENTER)
            end
        end
    end

    local function EndGame(success)
        if gameState == 2 then return end
        gameState = 2
        net.Start("defib_minigame_result")
        net.WriteBool(success)
        net.SendToServer()
        
        if success then
            surface.PlaySound("buttons/bell1.wav")
        else
            surface.PlaySound("buttons/button10.wav")
        end
        
        frame:Close()
    end

    local function StartLevel2()
        currentLevel = 2
        gameState = 1
        startTime = SysTime()
        timeLeft = 10 -- 10 Segundos para reaccionar
        indicatorX = 50
        indicatorDir = 1
        surface.PlaySound("buttons/bell1.wav") -- Sonido de pase al siguiente nivel
    end

    function frame:Think()
        if gameState == 2 then return end

        if currentLevel == 1 then
            local cx, cy = self:CursorPos()
            local inFrame = (cx >= 0 and cx <= self:GetWide() and cy >= 0 and cy <= self:GetTall())

            if gameState == 0 then
                if cx >= startZone.x and cx <= startZone.x + startZone.w and cy >= startZone.y and cy <= startZone.y + startZone.h then
                    gameState = 1
                    startTime = SysTime()
                    surface.PlaySound("buttons/button17.wav")
                end
            elseif gameState == 1 then
                if SysTime() - startTime >= timeLeft then EndGame(false) return end
                if not inFrame then EndGame(false) return end

                if cx >= endZone.x and cx <= endZone.x + endZone.w and cy >= endZone.y and cy <= endZone.y + endZone.h then
                    StartLevel2() 
                    return
                end

                -- 1. Comprobar choque contra obstáculos
                local t = SysTime()
                for _, obs in ipairs(obstacles) do
                    local ox, oy, ow, oh = obs.update(t)
                    if cx >= ox and cx <= ox + ow and cy >= oy and cy <= oy + oh then
                        EndGame(false)
                        return
                    end
                end

                -- 2. Comprobar si sigue en el camino seguro
                local isOnPath = false
                for _, p in ipairs(paths) do
                    if cx >= p.x and cx <= p.x + p.w and cy >= p.y and cy <= p.y + p.h then
                        isOnPath = true 
                        break
                    end
                end

                if not isOnPath then EndGame(false) end
            end
        elseif currentLevel == 2 then
            if gameState == 1 then
                if SysTime() - startTime >= timeLeft then EndGame(false) return end
                
                -- Mover el indicador (rebota en los bordes)
                indicatorX = indicatorX + (indicatorDir * level2Speed * FrameTime())
                if indicatorX <= 50 then indicatorX = 50; indicatorDir = 1 end
                if indicatorX >= self:GetWide() - 50 - 6 then indicatorX = self:GetWide() - 50 - 6; indicatorDir = -1 end

                -- Detectar el clic de sincronización
                local isMouseDown = input.IsMouseDown(MOUSE_LEFT)
                if isMouseDown and not wasMouseDown then
                    local targetX = self:GetWide()/2 - 40
                    local targetW = 80
                    local indCenter = indicatorX + 3
                    
                    -- ¿Está el centro de la barra dentro del objetivo verde?
                    if indCenter >= targetX and indCenter <= targetX + targetW then
                        EndGame(true)
                    else
                        EndGame(false)
                    end
                end
                wasMouseDown = isMouseDown
            end
        end
    end
end)