-- ============================================================================
-- IVOSAM: CLIENT CORE & FREECAM PREMIUM RENDERING SUITE
-- ============================================================================
IVO_SAM = IVO_SAM or {}

function IVO_SAM.HasPermission(ply, permissionID)
    if not IsValid(ply) then return false end
    if ply:IsSuperAdmin() then return true end
    
    local rankName = ply:GetUserGroup()
    if IVO_SAM.Ranks and IVO_SAM.Ranks[rankName] and IVO_SAM.Ranks[rankName].permissions then
        if IVO_SAM.Ranks[rankName].permissions[permissionID] then return true end
    end

    local secRankName = ply:GetNWString("SecondaryRank", "")
    if secRankName ~= "" and IVO_SAM.SecondaryRanks and IVO_SAM.SecondaryRanks[secRankName] and IVO_SAM.SecondaryRanks[secRankName].permissions then
        if IVO_SAM.SecondaryRanks[secRankName].permissions[permissionID] then return true end
    end

    return false
end

net.Receive("IVO_SyncRanks", function()
    IVO_SAM.Ranks = net.ReadTable()
end)

net.Receive("IVO_SyncSecRanks", function()
    IVO_SAM.SecondaryRanks = net.ReadTable()
end)

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

-- RECEPCIÓN DE NOTIFICACIONES
-- RECEPCIÓN DE NOTIFICACIONES
net.Receive("Ivosam_Notify", function()
    local admin = net.ReadEntity()
    local message = net.ReadString() 
    local target = net.ReadEntity()
    local isPublic = net.ReadBool()
    local extraValue = net.ReadString() 

    local line = {}

    if admin == LocalPlayer() then
        table.insert(line, Color(0, 255, 0))
        table.insert(line, "Tu")
    else
        table.insert(line, Color(0, 150, 255))
        table.insert(line, IsValid(admin) and admin:Nick() or "Console")
    end

    table.insert(line, Color(255, 255, 255))
    table.insert(line, message)

    if extraValue and string.find(extraValue, ",") then
        local nombres = string.Explode(",", extraValue)
        for i, nombre in ipairs(nombres) do
            table.insert(line, Color(255, 50, 50)) 
            table.insert(line, nombre)
            if i < #nombres then
                table.insert(line, Color(255, 255, 255)) 
                table.insert(line, ", ")
            end
        end
    elseif IsValid(target) then
        if admin == target then
            -- ==========================================
            -- FILTRO INTELIGENTE:
            -- Si el mensaje termina en " a ", imprimimos "él mismo".
            -- Si no, lo omitimos para que la frase no quede redundante
            -- (Ej: "Tu entró en modo espectador" sin añadir "él mismo" al final)
            -- ==========================================
            if string.match(message, " a $") or string.match(message, " a la ID $") or string.match(message, " de $") then
                table.insert(line, Color(255, 128, 0))
                table.insert(line, "él mismo")
            end
        else
            table.insert(line, Color(255, 50, 50))
            table.insert(line, target:Nick())
        end

        if extraValue and extraValue != "" then
            table.insert(line, Color(255, 255, 255))
            table.insert(line, extraValue)
        end
    elseif extraValue and extraValue != "" then
        table.insert(line, Color(255, 50, 50))
        table.insert(line, extraValue)
    end

    chat.AddText(unpack(line))
end)

-- HOOK APERTURA DE MENÚ (CORREGIDO TYPEOF)
hook.Add("OnPlayerChat", "IVO_OpenMenu", function(ply, text)
    if ply == LocalPlayer() and string.lower(text) == "!menu" then
        if IVO_SAM.HasPermission(ply, "menu") then 
            if RoyalAdminMenu and IsValid(RoyalAdminMenu) then
                RoyalAdminMenu:Remove()
            end
            
            -- Corregido: Usamos 'type' nativo de Lua en lugar de 'typeof'
            if type(OpenAdminMenu) == "function" then
                OpenAdminMenu()
            else
                ply:ChatPrint("[IVOSAM-ERROR] La interfaz visual (cl_menu.lua) no está cargada en el cliente.")
            end
        end
        return true
    end
end)

-- LÓGICA INTEGRADORA DE FREECAM
local isFreecam = false
local targetPlayer = nil 
local freecamPos = Vector(0, 0, 0)
local freecamAng = Angle(0, 0, 0)

net.Receive("Ivosam_Freecam", function()
    isFreecam = not isFreecam
    if isFreecam then
        local ply = LocalPlayer()
        freecamPos = ply:EyePos() - (ply:GetForward() * 60) + Vector(0, 0, 15)
        freecamAng = ply:EyeAngles()
    else
        RunConsoleCommand("stopsounds") 
    end
end)

hook.Add("PlayerButtonDown", "Ivosam_FreecamClick", function(ply, button)
    if not isFreecam then return end

    if button == MOUSE_FIRST then
        if IsValid(targetPlayer) then
            local oldName = targetPlayer:Nick()
            net.Start("IVO_FreecamSetTarget")
                net.WriteEntity(game.GetWorld())
            net.SendToServer()
            targetPlayer = nil
            surface.PlaySound("buttons/button16.wav")
            chat.AddText(Color(255, 255, 255), "Has dejado de espectear a ", Color(255, 100, 100), oldName, ".")
            return 
        end

        local tr = util.TraceLine({
            start = freecamPos,
            endpos = freecamPos + (freecamAng:Forward() * 50000),
            filter = LocalPlayer()
        })

        if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
            targetPlayer = tr.Entity
            net.Start("IVO_FreecamSetTarget")
                net.WriteEntity(targetPlayer)
            net.SendToServer()
            surface.PlaySound("buttons/button14.wav")
            chat.AddText(Color(255, 255, 255), "Estás especteando a ", team.GetColor(targetPlayer:Team()), targetPlayer:Nick(), Color(200, 200, 200), " [" .. targetPlayer:SteamID() .. "]")
        end

    elseif button == KEY_R then
        local tpPos = IsValid(targetPlayer) and (targetPlayer:GetPos() - (targetPlayer:GetForward() * 65) + Vector(0, 0, 5)) or freecamPos

        net.Start("Ivosam_FreecamTP")
            net.WriteVector(tpPos)
        net.SendToServer()

        net.Start("IVO_FreecamSetTarget")
            net.WriteEntity(game.GetWorld())
        net.SendToServer()

        isFreecam = false
        targetPlayer = nil
        surface.PlaySound("ambient/levels/citadel/citadel_teleport_batch_01.wav")
    end
end)

hook.Add("CalcView", "Ivosam_FreecamView", function(ply, pos, ang, fov)
    if not isFreecam then return end

    if IsValid(targetPlayer) and targetPlayer:Alive() then
        local targetPos = targetPlayer:GetPos() + Vector(0, 0, 60)
        freecamPos = targetPos - (freecamAng:Forward() * 120)
        freecamAng = ply:EyeAngles() 
        return { origin = freecamPos, angles = freecamAng, fov = fov, drawviewer = true }
    end

    local view = { origin = freecamPos, angles = freecamAng, fov = fov, drawviewer = true }
    local move = Vector(0,0,0)
    local speed = IVO_SAM.Config.FREECAM_SPEED
    if input.IsKeyDown(KEY_W) then move = move + freecamAng:Forward() end
    if input.IsKeyDown(KEY_S) then move = move - freecamAng:Forward() end
    if input.IsKeyDown(KEY_A) then move = move - freecamAng:Right() end
    if input.IsKeyDown(KEY_D) then move = move + freecamAng:Right() end
    if input.IsKeyDown(KEY_LSHIFT) then speed = IVO_SAM.Config.FREECAM_SPEED_FAST end

    -- Multiplicamos por RealFrameTime() y un factor de escala (66) para mantener tu velocidad original habitual.
    -- Esto garantiza fluidez matemática absoluta independientemente de los tirones de FPS.
    freecamPos = freecamPos + (move * speed * (RealFrameTime() * 66))
    freecamAng = ply:EyeAngles() 
    return view
end)

hook.Add("CreateMove", "Ivosam_FreecamControl", function(cmd)
    if isFreecam then
        if cmd:KeyDown(IN_JUMP) then 
            if IsValid(targetPlayer) then
                targetPlayer = nil
                surface.PlaySound("buttons/button16.wav")
            else

                net.Start("IVO_FreecamSetTarget")
                    net.WriteEntity(game.GetWorld())
                net.SendToServer()
                isFreecam = false 
                targetPlayer = nil 
            end
        end
        cmd:ClearButtons()
        cmd:ClearMovement()
    end
end)



-- RENDERIZADO INTERFAZ HUD FREE-LOOK
surface.CreateFont("IVOSAM_Panel_Title", { font = "Inter", size = 26, weight = 1000, antialias = true })
surface.CreateFont("IVOSAM_Panel_Status", { font = "Inter", size = 12, weight = 800, antialias = true, kerning = 2 })
surface.CreateFont("IVOSAM_Panel_Key", { font = "Consolas", size = 14, weight = 800, antialias = true })
surface.CreateFont("IVOSAM_Panel_Desc", { font = "Inter", size = 13, weight = 500, antialias = true })
surface.CreateFont("IVOSAM_Player_Name", { font = "Inter", size = 18, weight = 800, antialias = true })
surface.CreateFont("IVOSAM_Player_Small", { font = "Inter", size = 13, weight = 700, antialias = true })

hook.Add("HUDPaint", "IVOSAM_Full_Elite_System", function()
    if not isFreecam then return end

    local sw, sh = ScrW(), ScrH()
    local centerX, centerY = sw / 2, sh / 2
    local time = CurTime()

    local pw, ph = 280, 190
    local px, py = 40, (sh / 2) - (ph / 2)

    draw.RoundedBox(16, px - 2, py - 2, pw + 4, ph + 4, Color(0, 150, 255, 10)) 
    draw.RoundedBox(16, px, py, pw, ph, Color(10, 10, 15, 250)) 
    
    draw.SimpleText("IVOSAM", "IVOSAM_Panel_Title", px + 20, py + 15, Color(255, 255, 255))
    local pulse = math.abs(math.sin(time * 2)) * 255
    draw.RoundedBox(4, px + 115, py + 25, 8, 8, Color(0, 255, 150, pulse))
    draw.SimpleText("SISTEMA ACTIVO", "IVOSAM_Panel_Status", px + 130, py + 23, Color(0, 255, 150, 200))

    surface.SetDrawColor(255, 255, 255, 5)
    surface.DrawRect(px + 15, py + 50, pw - 30, 1) 

    local function DrawPremiumKey(key, desc, yOffset)
        draw.RoundedBox(4, px + 20, py + 65 + yOffset, 50, 22, Color(255, 255, 255, 5))
        surface.SetDrawColor(0, 150, 255, 100)
        surface.DrawOutlinedRect(px + 20, py + 65 + yOffset, 50, 22, 1)
        draw.SimpleText(key, "IVOSAM_Panel_Key", px + 45, py + 68 + yOffset, Color(0, 150, 255), TEXT_ALIGN_CENTER)
        draw.SimpleText("• " .. desc, "IVOSAM_Panel_Desc", px + 80, py + 68 + yOffset, Color(200, 200, 200))
    end

    DrawPremiumKey("WASD", "Vuelo de precisión", 0)
    DrawPremiumKey("M1", IsValid(targetPlayer) and "Liberar objetivo" or "Fijar objetivo", 28)
    DrawPremiumKey("R", "Teleport & Salir", 56)
    DrawPremiumKey("SPACE", "Desactivar Sistema", 84)

    local scanY = (time * 50) % ph
    surface.SetDrawColor(0, 150, 255, 15)
    surface.DrawRect(px, py + scanY, pw, 2)

    local trTarget = util.TraceLine({
        start = freecamPos,
        endpos = freecamPos + (freecamAng:Forward() * 10000),
        filter = LocalPlayer()
    })

    if not IsValid(targetPlayer) then
        if IsValid(trTarget.Entity) and trTarget.Entity:IsPlayer() then
            local ent = trTarget.Entity
            local ePos = ent:WorldSpaceCenter():ToScreen()
            if ePos.visible then
                local s = 30 + (math.sin(time * 10) * 5)
                surface.SetDrawColor(255, 255, 255, 200)
                surface.DrawLine(ePos.x - s, ePos.y - s, ePos.x - s + 10, ePos.y - s)
                surface.DrawLine(ePos.x - s, ePos.y - s, ePos.x - s, ePos.y - s + 10)
                surface.DrawLine(ePos.x + s, ePos.y + s, ePos.x + s - 10, ePos.y + s)
                surface.DrawLine(ePos.x + s, ePos.y + s, ePos.x + s, ePos.y + s - 10)

                draw.SimpleText("DETECTADO: " .. ent:Nick():upper(), "IVOSAM_Panel_Status", ePos.x, ePos.y - s - 15, Color(255, 255, 255), TEXT_ALIGN_CENTER)
                draw.SimpleText("CLICK PARA ANCLAR", "IVOSAM_Panel_Desc", ePos.x, ePos.y + s + 10, Color(0, 150, 255, pulse), TEXT_ALIGN_CENTER)
            end
        end
    else
        draw.SimpleText("LOCK-ON: " .. targetPlayer:Nick():upper(), "IVOSAM_Panel_Status", centerX, centerY + 60, Color(0, 255, 150, pulse), TEXT_ALIGN_CENTER)
        surface.SetDrawColor(0, 255, 150, 150)
        surface.DrawOutlinedRect(centerX - 20, centerY - 20, 40, 40, 2)
    end

    for _, p in ipairs(player.GetAll()) do
        if not IsValid(p) or not p:Alive() then continue end
        local isLocal = (p == LocalPlayer())
        if isLocal and not isFreecam then continue end
        local jobCol = team.GetColor(p:Team())
        
        local eyePos = p:EyePos()
        local aimVec = p:GetAimVector()
        local trLaser = util.TraceLine({ start = eyePos, endpos = eyePos + (aimVec * 2000), filter = p })
        local sPos = eyePos:ToScreen()
        local ePos = trLaser.HitPos:ToScreen()
        
        if sPos.visible and ePos.visible and not isLocal then
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawLine(sPos.x, sPos.y, ePos.x, ePos.y)
            surface.SetDrawColor(jobCol.r, jobCol.g, jobCol.b, 255)
            surface.DrawLine(sPos.x - 1, sPos.y - 1, ePos.x - 1, ePos.y - 1)
            surface.SetDrawColor(255, 255, 255, 200)
            surface.DrawLine(sPos.x, sPos.y, ePos.x, ePos.y)
        end

        local headPos = (p:GetPos() + Vector(0, 0, 80)):ToScreen()
        if headPos.visible then
            local hp = math.Clamp(p:Health(), 0, 100)
            local hpCol = Color(255 - (hp * 2.55), hp * 2.55, 50)
            local bxW, bxH = 170, 85
            local bx, by = headPos.x - (bxW/2), headPos.y - bxH

            draw.RoundedBox(12, bx, by, bxW, bxH, Color(10, 10, 15, 240))
            surface.SetDrawColor(jobCol)
            surface.DrawRect(bx, by + 10, 3, bxH - 20)

            draw.SimpleText(p:Nick(), "IVOSAM_Player_Name", bx + 15, by + 12, Color(255, 255, 255))
            draw.SimpleText(team.GetName(p:Team()):upper(), "IVOSAM_Player_Small", bx + 15, by + 32, jobCol)
            draw.SimpleText(p:GetUserGroup():upper(), "IVOSAM_Player_Small", bx + 15, by + 46, Color(255, 255, 255, 20))

            draw.SimpleText(hp .. "% HP", "IVOSAM_Player_Small", bx + bxW - 15, by + 58, hpCol, TEXT_ALIGN_RIGHT)
            draw.RoundedBox(2, bx + 15, by + 72, bxW - 30, 5, Color(255, 255, 255, 5))
            draw.RoundedBox(2, bx + 15, by + 72, ((bxW - 30) * hp) / 100, 5, hpCol)
        end
    end
end)

hook.Add("PreDrawHalos", "Ivosam_AdminHalos", function()
    if not isFreecam then return end
    local targets = {}
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() then table.insert(targets, p) end
    end
    halo.Add(targets, Color(255, 255, 255), 2, 2, 2, true, true)
end)