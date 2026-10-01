-- Cliente: cl_context_menu.lua (Optimizado para Carga masiva de Presets)
-- Cliente: cl_context_menu.lua (Actualización Cinemática 3ra Persona)
-- Cliente: cl_context_menu.lua (Actualización Cinemática y UI 3D2D Real)
if not CLIENT then return end

v_bodygroups = v_bodygroups or {}
v_bodygroups.MenuOpen = false
v_bodygroups.Options = {}
v_bodygroups.Scroll = 0

-- Configuración del tamaño de la interfaz holográfica
local uiW, uiH = 500, 750
local uiScale = 0.05

-- Función matemática para obtener la posición y rotación del panel holográfico en el mundo
function v_bodygroups.GetUIPosAng()
    local ply = LocalPlayer()
    -- Centro de enfoque (pecho del jugador)
    local targetPos = ply:GetPos() + Vector(0, 0, 50)
    
    -- Cámara cinemática: Alejada y con un ángulo ligeramente más elevado
    local idealPos = targetPos + ply:GetForward() * 110 + ply:GetRight() * 55 + Vector(0, 0, 15)
    
    local tr = util.TraceLine({
        start = targetPos,
        endpos = idealPos,
        filter = ply
    })
    local camPos = tr.HitPos + tr.HitNormal * 10
    
    local viewDir = (targetPos - camPos):GetNormalized()
    local lookAt = targetPos + viewDir:Angle():Right() * 15
    local camAng = (lookAt - camPos):Angle()
    
    -- Posición del panel: Más a la izquierda (cerca del jugador) y ligeramente más bajo
    local uiPos = targetPos + camAng:Right() * 32 - camAng:Forward() * 15 + Vector(0, 0, 20)
    
    local dirToCam = camPos - uiPos
    dirToCam.z = 0 -- Evita que el panel se incline hacia abajo o hacia arriba, manteniéndolo perfectamente vertical
    local uiAng = dirToCam:Angle()
    
    -- Estas dos rotaciones preparan el plano para que el 3D2D se dibuje de pie y mirando a la cámara.
    -- Por lo general, NO debes tocar estas dos a menos que el panel esté de cabeza o en el suelo.
    uiAng:RotateAroundAxis(uiAng:Right(), -90) 
    uiAng:RotateAroundAxis(uiAng:Up(), 90)
    
    -- ==== AJUSTE DEL ÁNGULO (EFECTO PUERTA) ====
    -- Aquí es donde controlas qué tanto "gira" el panel para mirar al jugador.
    -- Tu código original tenía '18'. 
    -- * Si pones '0', el menú estará completamente plano mirando a la cámara.
    -- * Si pones un valor como '5' u '8', tendrá un efecto 3D sutil sin exagerar.
    uiAng:RotateAroundAxis(uiAng:Forward(), 5) 
    
    -- ==== (OPCIONAL) AJUSTE DE INCLINACIÓN VERTICAL ====
    -- Si sientes que el menú está "cayéndose" hacia atrás o hacia adelante, 
    -- puedes descomentar esta línea y ajustar el valor (ej: -5 para inclinar hacia adelante, 5 hacia atrás).
    -- uiAng:RotateAroundAxis(uiAng:Right(), -5)
    
    return uiPos, uiAng, camPos, targetPos
end

-- Sistema de Raycast para detectar el ratón sobre la pantalla 3D
function v_bodygroups.GetHovered3D2D()
    if not v_bodygroups.MenuOpen then return nil, nil end
    local uiPos, uiAng = v_bodygroups.GetUIPosAng()
    
    -- Disparamos un rayo desde la cámara por donde apunta el ratón
    local rayOrigin = EyePos()
    local rayDir = gui.ScreenToVector(gui.MousePos())
    
    local intersect = util.IntersectRayWithPlane(rayOrigin, rayDir, uiPos, uiAng:Up())
    if intersect then
        local localPos = WorldToLocal(intersect, Angle(0,0,0), uiPos, uiAng)
        -- Retornamos coordenadas relativas al panel
        return localPos.x / uiScale, -localPos.y / uiScale
    end
    return nil, nil
end

function v_bodygroups.PopulateOptions()
    v_bodygroups.Options = {}
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- 1. Modelos del Job (DarkRP)
    local jobModels = {}
    if ply.getJobTable and ply:getJobTable() then
        local mdl = ply:getJobTable().model
        if type(mdl) == "table" then
            jobModels = mdl
        elseif type(mdl) == "string" then
            jobModels = {mdl}
        end
    end

    if #jobModels > 1 then
        local currentMdl = string.lower(ply:GetModel())
        local currentIdx = 0
        for i, mdl in ipairs(jobModels) do
            if string.lower(mdl) == currentMdl then
                currentIdx = i - 1
                break
            end
        end

        table.insert(v_bodygroups.Options, {
            title = "Modelo del Trabajo",
            val = currentIdx,
            displayVal = currentIdx + 1,
            max = #jobModels,
            expanded = false,
            onUpdate = function(val)
                local newModel = jobModels[val + 1]
                v_bodygroups.NetworkUpdate("model", val + 1, 0)
                ply:SetModel(newModel)
                
                -- Limpiar localmente para evitar el efecto de arrastre del modelo viejo
                ply:SetSkin(0)
                for i = 0, ply:GetNumBodyGroups() - 1 do
                    ply:SetBodygroup(i, 0)
                end
                
                -- Damos un poco más de tiempo para que el servidor envíe los bodygroups guardados
                timer.Simple(0.3, v_bodygroups.PopulateOptions)
            end
        })
    end

    -- 2. Skins
    local numSkins = ply:SkinCount()
    if numSkins > 1 then
        table.insert(v_bodygroups.Options, {
            title = "Variante de Skin",
            val = ply:GetSkin(),
            displayVal = ply:GetSkin(),
            max = numSkins,
            expanded = false,
            onUpdate = function(val)
                v_bodygroups.NetworkUpdate("skin", 0, val)
                ply:SetSkin(val)
            end
        })
    end

    -- 3. Bodygroups
    for i = 0, ply:GetNumBodyGroups() - 1 do
        local bgCount = ply:GetBodygroupCount(i)
        if bgCount > 1 then
            local bgName = ply:GetBodygroupName(i) or "Objeto"
            
            -- Contar cuantas opciones están desbloqueadas
            local unlockedCount = 0
            if SW_InvShop and SW_InvShop.HasBodygroupAccess then
                for subVal = 0, bgCount - 1 do
                    local subName = ""
                    for _, bg in pairs(ply:GetBodyGroups() or {}) do
                        if bg.id == i then
                            subName = bg.submodels and bg.submodels[subVal] or ""
                            break
                        end
                    end
                    if SW_InvShop.HasBodygroupAccess(ply, bgName, subName) then
                        unlockedCount = unlockedCount + 1
                    end
                end
            else
                unlockedCount = bgCount
            end
            
            if unlockedCount > 1 then
                local friendlyName = string.upper(string.sub(bgName, 1, 1)) .. string.sub(bgName, 2)
                table.insert(v_bodygroups.Options, {
                    title = friendlyName,
                    val = ply:GetBodygroup(i),
                    displayVal = ply:GetBodygroup(i),
                    max = bgCount,
                    bgIndex = i,
                    expanded = false,
                    onUpdate = function(val)
                        v_bodygroups.NetworkUpdate("bodygroup", i, val)
                        ply:SetBodygroup(i, val)
                    end
                })
            end
        end
    end
end

-- Prioridad en Cámara Cinemática (se fuerza su registro)
function v_bodygroups.CalcView(ply, pos, angles, fov)
    if not v_bodygroups.MenuOpen then return end
    local uiPos, uiAng, camPos, targetPos = v_bodygroups.GetUIPosAng()
    
    local viewDir = (targetPos - camPos):GetNormalized()
    local lookAt = targetPos + viewDir:Angle():Right() * 25
    
    return {
        origin = camPos,
        angles = (lookAt - camPos):Angle(),
        fov = 45, -- FOV más cerrado (zoom) para un aspecto más dramático/película
        drawviewer = true
    }
end

-- Sistema agresivo para suspender temporalmente otras cámaras (Mods de 3ra persona)
function v_bodygroups.ForceHookPriority()
    v_bodygroups.SuspendedHooks = v_bodygroups.SuspendedHooks or { CalcView = {}, ShouldDrawLocalPlayer = {} }
    
    local hooksToEnforce = {
        CalcView = "v_bodygroups_CinematicCam",
        ShouldDrawLocalPlayer = "v_bodygroups_DrawPlayer"
    }
    
    for hookName, ourHookID in pairs(hooksToEnforce) do
        local currentHooks = hook.GetTable()[hookName]
        if currentHooks then
            for k, v in pairs(currentHooks) do
                if k ~= ourHookID then
                    v_bodygroups.SuspendedHooks[hookName][k] = v
                    hook.Remove(hookName, k)
                end
            end
        end
    end
end

function v_bodygroups.RestoreHooks()
    if not v_bodygroups.SuspendedHooks then return end
    for hookName, hooks in pairs(v_bodygroups.SuspendedHooks) do
        for k, v in pairs(hooks) do
            hook.Add(hookName, k, v)
        end
    end
    v_bodygroups.SuspendedHooks = nil
end

function v_bodygroups.CloseCinematicMenu()
    v_bodygroups.MenuOpen = false
    if IsValid(v_bodygroups.MainFrame) then v_bodygroups.MainFrame:Remove() end
    
    hook.Remove("CalcView", "v_bodygroups_CinematicCam")
    hook.Remove("ShouldDrawLocalPlayer", "v_bodygroups_DrawPlayer")
    hook.Remove("PostDrawTranslucentRenderables", "v_bodygroups_3DUI")
    hook.Remove("Think", "v_bodygroups_CamEnforcer")
    v_bodygroups.RestoreHooks()
end

function v_bodygroups.OpenCinematicMenu()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    v_bodygroups.CloseCinematicMenu()

    v_bodygroups.MenuOpen = true
    v_bodygroups.Scroll = 0
    v_bodygroups.PopulateOptions()

    -- Inyectamos los hooks dinámicamente para aplastar otros addons de tercera persona
    hook.Add("CalcView", "v_bodygroups_CinematicCam", v_bodygroups.CalcView)
    hook.Add("ShouldDrawLocalPlayer", "v_bodygroups_DrawPlayer", function() return true end)
    hook.Add("Think", "v_bodygroups_CamEnforcer", function() if v_bodygroups.MenuOpen then v_bodygroups.ForceHookPriority() end end)
    v_bodygroups.ForceHookPriority()

    if IsValid(g_ContextMenu) then g_ContextMenu:Hide() end

    -- 1. Marco invisible 2D para capturar clics del ratón (No dibuja nada, es transparente)
    local frame = vgui.Create("DFrame")
    frame:SetSize(ScrW(), ScrH())
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame.Paint = function() end -- Totalmente invisible
    v_bodygroups.MainFrame = frame

    frame.OnMouseWheeled = function(self, delta)
        local totalHeight = 0
        for _, opt in ipairs(v_bodygroups.Options) do
            totalHeight = totalHeight + 60
            if opt.expanded then totalHeight = totalHeight + math.ceil(opt.max / 6) * 50 + 10 end
        end
        v_bodygroups.Scroll = math.Clamp(v_bodygroups.Scroll - delta * 40, 0, math.max(0, totalHeight - (uiH - 240)))
    end

    frame.OnMousePressed = function(self, key)
        -- Sistema de seguridad: Clic derecho en cualquier parte cierra el menú
        if key == MOUSE_RIGHT then
            surface.PlaySound("ui/buttonclick.wav")
            v_bodygroups.CloseCinematicMenu()
            return
        end
        if key ~= MOUSE_LEFT then return end
        local hx, hy = v_bodygroups.GetHovered3D2D()
        if not hx then return end
        
        -- Cerrar
        if hx >= uiW - 40 and hx <= uiW - 10 and hy >= 10 and hy <= 40 then
            surface.PlaySound("ui/buttonclick.wav")
            v_bodygroups.CloseCinematicMenu()
            return
        end
        
        -- Botones de Opciones
        local endY = uiH - 120
        local currentY = 100 - v_bodygroups.Scroll
        
        for i, opt in ipairs(v_bodygroups.Options) do
            if currentY > uiH then break end -- Optimización si ya estamos fuera de pantalla
            
            -- Click en el encabezado (Abrir/Cerrar menú)
            if hy >= 90 and hy <= endY then -- Restricción: No clickear si está escondido por scroll
                if hx >= 30 and hx <= uiW - 30 and hy >= currentY and hy <= currentY + 50 then
                    opt.expanded = not opt.expanded
                    surface.PlaySound("ui/buttonclick.wav")
                    return
                end
            end
            currentY = currentY + 60
            
            -- Clicks en la cuadrícula de botones (si está desplegado)
            if opt.expanded then
                local cols = 6
                for j = 0, opt.max - 1 do
                    local row = math.floor(j / cols)
                    local col = j % cols
                    local btnX = 40 + col * 70
                    local btnY = currentY + row * 50
                    
                    if hy >= 90 and hy <= endY then -- Restricción: No clickear si está escondido por scroll
                        if hx >= btnX and hx <= btnX + 60 and hy >= btnY and hy <= btnY + 40 then
                            local isLocked = false
                            if opt.title ~= "Modelo del Trabajo" and opt.title ~= "Variante de Skin" and SW_InvShop and SW_InvShop.HasBodygroupAccess then
                                local bgName = ply:GetBodygroupName(opt.bgIndex)
                                local subName = ""
                                for _, bg in pairs(ply:GetBodyGroups() or {}) do
                                    if bg.id == opt.bgIndex then
                                        subName = bg.submodels and bg.submodels[j] or ""
                                        break
                                    end
                                end
                                if not SW_InvShop.HasBodygroupAccess(ply, bgName, subName) then
                                    isLocked = true
                                end
                            end

                            if isLocked then
                                surface.PlaySound("buttons/button10.wav")
                            elseif opt.val ~= j then
                                opt.val = j
                                opt.displayVal = j + (opt.title == "Modelo del Trabajo" and 1 or 0)
                                opt.onUpdate(j)
                                surface.PlaySound("ui/click1.wav")
                            end
                            return
                        end
                    end
                end
                currentY = currentY + math.ceil(opt.max / cols) * 50 + 10
            end
        end
        
        -- Guardar Preset
        if hx >= 30 and hx <= 230 and hy >= uiH - 80 and hy <= uiH - 30 then
            surface.PlaySound("buttons/button14.wav")
            local currentOutfit = { skin = ply:GetSkin(), bgs = {} }
            for i = 0, ply:GetNumBodyGroups() - 1 do currentOutfit.bgs[i] = ply:GetBodygroup(i) end
            local modelClean = string.gsub(string.lower(ply:GetModel()), "[/%s%.]", "_")
            if not file.Exists("v_bodygroups", "DATA") then file.CreateDir("v_bodygroups") end
            file.Write("v_bodygroups/" .. modelClean .. ".txt", util.TableToJSON(currentOutfit))
            chat.AddText(Color(255, 255, 255), "[Accesorios] ¡Combinación guardada!")
        end
        
        -- Cargar Preset
        if hx >= uiW - 230 and hx <= uiW - 30 and hy >= uiH - 80 and hy <= uiH - 30 then
            local modelClean = string.gsub(string.lower(ply:GetModel()), "[/%s%.]", "_")
            local filePath = "v_bodygroups/" .. modelClean .. ".txt"
            if not file.Exists(filePath, "DATA") then
                surface.PlaySound("common/wpn_denyselect.wav")
                chat.AddText(Color(236, 59, 59), "[Accesorios] No tienes presets para este modelo.")
                return
            end
            local savedData = file.Read(filePath, "DATA")
            local outfit = util.JSONToTable(savedData)
            if outfit then
                surface.PlaySound("buttons/button14.wav")
                net.Start("v_bodygroups_Update")
                    net.WriteString("preset")
                    net.WriteInt(0, 8) 
                    net.WriteInt(0, 8) 
                    net.WriteString(ply:GetModel()) -- Firma Anti-Contaminación
                    net.WriteString(savedData)
                net.SendToServer()
                if outfit.skin then ply:SetSkin(outfit.skin) end
                if outfit.bgs then
                    for bgID, val in pairs(outfit.bgs) do
                        ply:SetBodygroup(tonumber(bgID), tonumber(val))
                    end
                end
                v_bodygroups.PopulateOptions()
                chat.AddText(Color(34, 255, 144), "[Accesorios] ¡Preset aplicado!")
            end
        end
    end

    -- 2. DIBUJADO 3D FÍSICO (Renderizado Holográfico)
    hook.Add("PostDrawTranslucentRenderables", "v_bodygroups_3DUI", function()
        if not v_bodygroups.MenuOpen then return end
        
        local uiPos, uiAng = v_bodygroups.GetUIPosAng()
        local hx, hy = v_bodygroups.GetHovered3D2D()
        
        cam.Start3D2D(uiPos, uiAng, uiScale)
            -- COLORES DEL TEMA (Holograma Dinámico)
            local function ParseCol(cv, def)
                local cvObj = GetConVar(cv)
                if not cvObj then return def end
                local p = string.Explode(" ", cvObj:GetString())
                if #p >= 3 then return Color(tonumber(p[1]) or 255, tonumber(p[2]) or 255, tonumber(p[3]) or 255, tonumber(p[4]) or 255) end
                return def
            end
            
            local c_bg = Color(5, 15, 25, 230)
            local c_bg_solid = Color(5, 15, 25, 255)
            local c_border = ParseCol("virtus_compass_col_line", Color(0, 150, 255, 200))
            local c_accent = ParseCol("virtus_compass_col_accent", Color(0, 200, 255, 255))
            local c_textMain = ParseCol("virtus_compass_col_text", Color(240, 250, 255, 255))
            local c_textDim = Color(100, 150, 200, 255)
            
            -- Aplicamos opacidad extra para la línea
            c_border = Color(c_border.r, c_border.g, c_border.b, 200)
            
            local endY = uiH - 120
            
            -- 1. FONDO ÁREA DE SCROLL
            surface.SetDrawColor(c_bg)
            surface.DrawRect(0, 90, uiW, endY - 90)
            
            -- 2. DIBUJAR OPCIONES (Para que queden bajo los bordes sólidos si sobresalen)
            if #v_bodygroups.Options == 0 then
                draw.SimpleText(">> SIN MODIFICACIONES DISPONIBLES <<", "DermaDefaultBold", uiW/2, 200, Color(255, 50, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                local currentY = 100 - v_bodygroups.Scroll
                for i, opt in ipairs(v_bodygroups.Options) do
                    local itemHeight = 60
                    if opt.expanded then itemHeight = itemHeight + math.ceil(opt.max / 6) * 50 + 10 end
                    
                    -- Optimización inteligente de Scroll
                    if currentY + itemHeight < 90 then  
                        currentY = currentY + itemHeight
                        continue 
                    end
                    if currentY > endY then break end
                    
                    -- Dibujado del Encabezado (Categoría)
                    local isRowHovered = (hx and hx >= 30 and hx <= uiW - 30 and hy >= currentY and hy <= currentY + 50)
                    if hy and (hy < 90 or hy > endY) then isRowHovered = false end -- Quitar brillo si está escondido
                    
                    if isRowHovered then surface.SetDrawColor(0, 150, 255, 30) surface.DrawRect(30, currentY, uiW - 60, 50) end
                    surface.SetDrawColor(c_border)
                    surface.DrawOutlinedRect(30, currentY, uiW - 60, 50, 1)
                    
                    local titleText = "> " .. string.upper(opt.title) .. " [" .. string.format("%02d", opt.displayVal) .. "]"
                    draw.SimpleText(titleText, "DermaDefaultBold", 45, currentY + 25, isRowHovered and c_accent or c_textMain, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    
                    local chevron = opt.expanded and "v" or "<"
                    draw.SimpleText(chevron, "DermaDefaultBold", uiW - 50, currentY + 25, c_accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                    currentY = currentY + 60
                    
                    -- Dibujado de la cuadrícula de botones (Si está expandido)
                    if opt.expanded then
                        local cols = 6
                        for j = 0, opt.max - 1 do
                            local row = math.floor(j / cols)
                            local col = j % cols
                            local btnX = 40 + col * 70
                            local btnY = currentY + row * 50
                            
                            local isBtnHovered = (hx and hx >= btnX and hx <= btnX + 60 and hy >= btnY and hy <= btnY + 40)
                            if hy and (hy < 90 or hy > endY) then isBtnHovered = false end
                            local isSelected = (opt.val == j)
                            local isLocked = false
                            
                            if opt.title ~= "Modelo del Trabajo" and opt.title ~= "Variante de Skin" and SW_InvShop and SW_InvShop.HasBodygroupAccess then
                                local bgName = ply:GetBodygroupName(opt.bgIndex)
                                local subName = ""
                                for _, bg in pairs(ply:GetBodyGroups() or {}) do
                                    if bg.id == opt.bgIndex then
                                        subName = bg.submodels and bg.submodels[j] or ""
                                        break
                                    end
                                end
                                if not SW_InvShop.HasBodygroupAccess(ply, bgName, subName) then
                                    isLocked = true
                                end
                            end

                            if isLocked then
                                surface.SetDrawColor(Color(150, 0, 0, 150))
                                surface.DrawOutlinedRect(btnX, btnY, 60, 40, 1)
                                if isBtnHovered then surface.DrawRect(btnX, btnY, 60, 40) end
                                draw.SimpleText("X", "DermaDefaultBold", btnX + 30, btnY + 20, Color(255, 100, 100, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            elseif isSelected then
                                surface.SetDrawColor(c_accent)
                                surface.DrawRect(btnX, btnY, 60, 40)
                                draw.SimpleText(string.format("%02d", j + (opt.title == "Modelo del Trabajo" and 1 or 0)), "DermaDefaultBold", btnX + 30, btnY + 20, c_bg_solid, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            else
                                surface.SetDrawColor(isBtnHovered and c_accent or c_border)
                                surface.DrawOutlinedRect(btnX, btnY, 60, 40, 1)
                                if isBtnHovered then surface.DrawRect(btnX, btnY, 60, 40) end
                                draw.SimpleText(string.format("%02d", j + (opt.title == "Modelo del Trabajo" and 1 or 0)), "DermaDefaultBold", btnX + 30, btnY + 20, isBtnHovered and c_bg_solid or c_textMain, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            end
                        end
                        currentY = currentY + math.ceil(opt.max / cols) * 50 + 10
                    end
                end
            end
            
            -- 3. FONDOS SÓLIDOS (MÁSCARA DE RECORTE PARA SCROLL)
            surface.SetDrawColor(c_bg_solid)
            surface.DrawRect(0, 0, uiW, 90) -- Tapa Superior
            surface.DrawRect(0, endY, uiW, uiH - endY) -- Tapa Inferior
            
            -- 4. BORDES Y DECORACIONES (Sobre la máscara)
            surface.SetDrawColor(c_border)
            surface.DrawOutlinedRect(0, 0, uiW, uiH, 2)
            
            -- Esquinas decorativas de la consola
            surface.DrawRect(0, 0, 25, 6) surface.DrawRect(0, 0, 6, 25)
            surface.DrawRect(uiW - 25, 0, 25, 6) surface.DrawRect(uiW - 6, 0, 6, 25)
            surface.DrawRect(0, uiH - 6, 25, 6) surface.DrawRect(0, uiH - 25, 6, 25)
            surface.DrawRect(uiW - 25, uiH - 6, 25, 6) surface.DrawRect(uiW - 6, uiH - 25, 6, 25)
            
            -- Encabezados Data-Pad
            draw.SimpleText("DATAPAD TÁCTICO //", "DermaLarge", 30, 35, c_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("MODIFICACIÓN DE EQUIPAMIENTO - ID: " .. ply:SteamID64(), "DermaDefaultBold", 30, 65, c_textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            -- Línea separadora superior
            surface.SetDrawColor(c_accent)
            surface.DrawRect(30, 85, uiW - 60, 1)
            
            -- Scanline dinámico decorativo
            local scanY = (CurTime() * 150) % uiH
            surface.SetDrawColor(0, 150, 255, 15)
            surface.DrawRect(0, scanY, uiW, 10)
            
            -- Botón Cerrar X
            local hoverClose = (hx and hx >= uiW - 40 and hx <= uiW - 10 and hy >= 10 and hy <= 40)
            draw.SimpleText("[ X ]", "DermaLarge", uiW - 35, 35, hoverClose and Color(255, 50, 50) or c_border, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- 5. PRESETS (PIE DE PÁGINA)
            if #v_bodygroups.Options > 0 then
                surface.SetDrawColor(c_accent)
                surface.DrawRect(30, endY + 15, uiW - 60, 1)
                
                local hoverSave = (hx and hx >= 30 and hx <= 230 and hy >= uiH - 80 and hy <= uiH - 30)
                surface.SetDrawColor(hoverSave and Color(0, 255, 100, 200) or Color(0, 150, 50, 100))
                surface.DrawOutlinedRect(30, uiH - 80, 200, 45, 1)
                if hoverSave then surface.DrawRect(30, uiH - 80, 200, 45) end
                draw.SimpleText("EJECUTAR GUARDADO", "DermaDefaultBold", 130, uiH - 57, hoverSave and c_bg_solid or Color(150, 255, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                
                local hoverLoad = (hx and hx >= uiW - 230 and hx <= uiW - 30 and hy >= uiH - 80 and hy <= uiH - 30)
                surface.SetDrawColor(hoverLoad and c_accent or c_border)
                surface.DrawOutlinedRect(uiW - 230, uiH - 80, 200, 45, 1)
                if hoverLoad then surface.DrawRect(uiW - 230, uiH - 80, 200, 45) end
                draw.SimpleText("CARGAR DATOS", "DermaDefaultBold", uiW - 130, uiH - 57, hoverLoad and c_bg_solid or c_accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        cam.End3D2D()
    end)
end

-- Context Menu integration removed. Now accessible via Armario menu.