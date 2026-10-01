-- ============================================================
--  IvoLogs · cl_death_scene.lua  (versión mejorada v3)
--  Fixes v3:
--    · Carteles: posición calculada con proyección manual post-cam
--      para que no se desplacen al mover la cámara
--    · FocusOn: resetea currentCamPos al activarse para evitar
--      el lerp errático desde posición lejana
--    · Modo libre: tecla X o botón vuelve la cámara al centro
--      después de un focus, sin romper el drag
--    · HP: lectura robusta (nil, 0, número negativo cubiertos)
--    · infoBar fila 2 muestra [X] Libre como atajo extra
-- ============================================================

function IvoLogs_OpenDeathScene(attData, vicData)
    if not vicData.pos then return end

    -- ── Posiciones base ──────────────────────────────────────────
    local vPos = Vector(vicData.pos.x, vicData.pos.y, vicData.pos.z)
    local vAng = Angle(vicData.ang.p, vicData.ang.y, vicData.ang.r)

    local aPos = attData.pos and Vector(attData.pos.x, attData.pos.y, attData.pos.z) or vPos
    local aAng = attData.ang and Angle(attData.ang.p, attData.ang.y, attData.ang.r) or Angle(0, 0, 0)

    local hookID = "IvoLogs_Death_" .. tostring(CurTime())

    -- ── Ventana principal ────────────────────────────────────────
    local frame = vgui.Create("DFrame")
    frame:SetSize(1000, 700)
    frame:Center()
    frame:SetTitle("IvoLogs - Reconstrucción de la escena")
    frame:MakePopup()
    function frame:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(25, 30, 35))
    end

    -- ── HUD superior ─────────────────────────────────────────────
    local hud = vgui.Create("DPanel", frame)
    hud:Dock(TOP)
    hud:SetTall(60)
    function hud:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(20, 25, 30, 250))
        surface.SetDrawColor(46, 204, 113)
        surface.DrawRect(0, h - 2, w, 2)

        draw.SimpleText("VÍCTIMA",  "Ivo_logs_Bold", w * 0.25, 12, Color(231, 76, 60),  TEXT_ALIGN_CENTER)
        draw.SimpleText(vicData.name or "Desconocido", "Ivo_logsT", w * 0.25, 30, color_white, TEXT_ALIGN_CENTER)

        draw.SimpleText("VS", "Ivo_logsT", w * 0.5, 20, Color(100, 100, 100), TEXT_ALIGN_CENTER)

        draw.SimpleText("ATACANTE", "Ivo_logs_Bold", w * 0.75, 12, Color(52, 152, 219), TEXT_ALIGN_CENTER)
        draw.SimpleText(attData.name or "Desconocido", "Ivo_logsT", w * 0.75, 30, color_white, TEXT_ALIGN_CENTER)
    end

    -- ── Panel de datos tácticos (parte inferior) ─────────────────
    local infoBar = vgui.Create("DPanel", frame)
    infoBar:Dock(BOTTOM)
    infoBar:SetTall(52)
    function infoBar:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(15, 18, 22, 240))
        surface.SetDrawColor(46, 204, 113)
        surface.DrawRect(0, 0, w, 1)

        local row1 = 14
        local row2 = 38

        -- ── Fila 1: datos ────────────────────────────────────────
        local dist   = math.Round(vPos:Distance(aPos))
        local weapon = attData.weapon or "Desconocida"

        -- HP robusto: cubre nil, false, 0, número negativo
        local hpRaw = vicData.hp
        local hpStr
        if hpRaw == nil or hpRaw == false then
            hpStr = "N/D"
        else
            hpStr = tostring(math.max(0, math.Round(tonumber(hpRaw) or 0)))
        end

        draw.SimpleText("DISTANCIA: " .. dist .. " u",
            "Ivo_logsT", 16, row1, Color(160, 170, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        draw.SimpleText("|", "Ivo_logsT", w * 0.28, row1, Color(50, 60, 70), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        draw.SimpleText("ARMA: " .. weapon,
            "Ivo_logsT", w * 0.30, row1, Color(160, 170, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        draw.SimpleText("|", "Ivo_logsT", w * 0.65, row1, Color(50, 60, 70), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        draw.SimpleText("HP VÍCTIMA: " .. hpStr,
            "Ivo_logsT", w * 0.67, row1, Color(231, 76, 60), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Línea divisoria
        surface.SetDrawColor(30, 36, 44)
        surface.DrawRect(0, 26, w, 1)

        -- ── Fila 2: atajos ───────────────────────────────────────
        local kCol = Color(100, 110, 125)
        local sep  = Color(50, 60, 70)

        local slots = {
            { key = "[R]",      desc = "Reset",         col = Color(46, 204, 113) },
            { key = "[F]",      desc = "Ver víctima",   col = Color(231, 76, 60)  },
            { key = "[Tab]",    desc = "Ver atacante",  col = Color(52, 152, 219) },
            { key = "[X]",      desc = "Cámara libre",  col = Color(180, 150, 80) },
            { key = "[Scroll]", desc = "Zoom",          col = Color(150, 150, 150)},
        }

        local slotW = w / #slots
        for i, s in ipairs(slots) do
            local slotLeft = slotW * (i - 1)   -- borde izquierdo de este slot
            local slotMid  = slotLeft + slotW * 0.5  -- centro del slot

            -- Separador centrado entre el slot anterior y éste
            if i > 1 then
                surface.SetDrawColor(40, 48, 58)
                surface.DrawRect(slotLeft, row2 - 6, 1, 12)
            end

            -- Medir tecla y descripción juntas para centrar el bloque en el slot
            surface.SetFont("Ivo_logs_Bold")
            local kw = surface.GetTextSize(s.key)
            surface.SetFont("Ivo_logsT")
            local dw = surface.GetTextSize(s.desc)
            local gap   = 5
            local total = kw + gap + dw
            local tx    = slotMid - total * 0.5  -- inicio del bloque centrado

            draw.SimpleText(s.key,  "Ivo_logs_Bold", tx,            row2, s.col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(s.desc, "Ivo_logsT",     tx + kw + gap, row2, kCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    -- ── Panel de escena 3D ───────────────────────────────────────
    local scene = vgui.Create("DPanel", frame)
    scene:Dock(FILL)

    -- ── Modelos ──────────────────────────────────────────────────

    -- Víctima
    local vicEnt = ClientsideModel(vicData.model or "models/player/kleiner.mdl")
    vicEnt:SetPos(vPos)
    vicEnt:SetAngles(vAng)
    vicEnt:SetNoDraw(true)

    local deathSeqs = { "death_01", "die_simple", "die01", "dead_simple", "ragdoll" }
    local vicSeq = -1
    for _, seq in ipairs(deathSeqs) do
        vicSeq = vicEnt:LookupSequence(seq)
        if vicSeq > 0 then break end
    end
    if vicSeq > 0 then
        vicEnt:ResetSequence(vicSeq)
        vicEnt:SetCycle(1)
    else
        vicEnt:SetAngles(Angle(0, vAng.y, 90))
        vicEnt:SetPos(vPos + Vector(0, 0, 5))
    end

    -- Atacante
    local attEnt = nil
    if attData.pos then
        attEnt = ClientsideModel(attData.model or "models/player/kleiner.mdl")
        attEnt:SetPos(aPos)
        attEnt:SetAngles(aAng)
        attEnt:SetNoDraw(true)

        local weaponSeqs = {
            "idle_smg1", "idle_ar2", "idle_pistol", "idle_shotgun",
            "ref_aim_pistol", "ref_aim_rifle",
            "shoot_pistol", "shoot_rifle",
            "idle_all_01", "idle_all_02", "idle", "stand_idle",
        }
        local attSeq = -1
        for _, seq in ipairs(weaponSeqs) do
            attSeq = attEnt:LookupSequence(seq)
            if attSeq > 0 then break end
        end
        if attSeq > 0 then
            attEnt:ResetSequence(attSeq)
            attEnt:SetCycle(0)
        end

        local lookDir = (vPos - aPos)
        lookDir.z = 0
        if lookDir:Length() > 1 then
            attEnt:SetAngles(lookDir:Angle())
        end
    end

    -- ── Posiciones de los pines (se actualizan cada frame tras DrawModel) ──
    -- Fallbacks usados hasta que el modelo dibuje su primer frame.
    local vicPinPos3D = vPos + Vector(0, 0, 40)   -- víctima tirada
    local attPinPos3D = aPos + Vector(0, 0, 82)   -- atacante parado

    -- ── Estado de cámara ─────────────────────────────────────────
    local initCenter   = (vPos + aPos) / 2
    initCenter.z       = initCenter.z + 40
    local center       = Vector(initCenter.x, initCenter.y, initCenter.z)

    local initDist     = 200
    local camDist      = initDist
    local targetDist   = initDist

    local initAngY     = (vPos - aPos):Angle().y + 90
    local camAng       = Angle(25, initAngY, 0)
    local targetCamAng = Angle(25, initAngY, 0)

    local currentCamPos = center - camAng:Forward() * camDist

    local dragging     = false
    local lastX, lastY = 0, 0
    local lastMoveTime = CurTime()

    -- modo focus: cuando está activo la cámara orbita alrededor
    -- de un jugador individual; X o drag lo libera
    local focusMode    = false   -- false = libre, "vic" | "att" = foco

    -- ── Helpers ──────────────────────────────────────────────────
    local function GetSafeCamPos(startP, endP)
        local tr = util.TraceLine({
            start  = startP,
            endpos = endP,
            mask   = MASK_SOLID_BRUSHONLY,
        })
        return tr.HitPos + tr.HitNormal * 5
    end

    local function SetFreeCamera()
        focusMode = false
        center    = Vector(initCenter.x, initCenter.y, initCenter.z)
        -- NO tocamos targetDist ni targetCamAng para que quede donde el usuario lo dejó
        lastMoveTime = CurTime()
    end

    local function ResetCamera()
        focusMode      = false
        center         = Vector(initCenter.x, initCenter.y, initCenter.z)
        targetDist     = initDist
        targetCamAng.p = 25
        targetCamAng.y = initAngY
        lastMoveTime   = CurTime()
    end

    local function FocusOn(pos)
        local newCenter = pos + Vector(0, 0, 40)
        -- Teletransportar currentCamPos al equivalente con el nuevo centro
        -- para que el lerp no arranque desde el otro lado del mapa
        local offset = currentCamPos - center
        center          = newCenter
        currentCamPos   = newCenter + offset   -- mantiene dirección/distancia relativa
        targetDist      = 110
        focusMode       = true
        lastMoveTime    = CurTime()
    end

    -- ── Eventos del panel de escena ──────────────────────────────
    function scene:OnMousePressed(btn)
        if btn == MOUSE_LEFT then
            dragging = true
            lastX, lastY = input.GetCursorPos()
            self:MouseCapture(true)
            -- Un click manual cancela el focus para no pelearse con el drag
            if focusMode then SetFreeCamera() end
        end
    end

    function scene:OnMouseReleased(btn)
        if btn == MOUSE_LEFT then
            dragging = false
            self:MouseCapture(false)
        end
    end

    function scene:OnMouseWheeled(delta)
        targetDist   = math.Clamp(targetDist - delta * 25, 40, 900)
        lastMoveTime = CurTime()
    end

    -- ── Teclas globales ──────────────────────────────────────────
    hook.Add("Think", hookID .. "_Keys", function()
        if not IsValid(frame) then
            hook.Remove("Think", hookID .. "_Keys")
            return
        end
        if not frame:IsVisible() then return end

        if input.IsKeyDown(KEY_R) then
            ResetCamera()
        end
        if input.IsKeyDown(KEY_F) then
            FocusOn(vPos)
        end
        if input.IsKeyDown(KEY_TAB) and attData.pos then
            FocusOn(aPos)
        end
        if input.IsKeyDown(KEY_X) then
            SetFreeCamera()
        end
    end)

    -- ── Proyección 3D→2D manual (fuera de cam.Start3D) ───────────
    -- Recibe un Vector3D y la cámara actual, devuelve x,y en pantalla
    -- absoluta + visible. Funciona igual que :ToScreen() pero usando
    -- la cámara que nosotros controlamos, no la del jugador.
    local function WorldToScreen3D(worldPos, camOrigin, camAngles, fov, scrX, scrY, w, h)
        -- Vector desde la cámara al punto
        local delta    = worldPos - camOrigin
        local forward  = camAngles:Forward()
        local right    = camAngles:Right()
        local up       = camAngles:Up()

        local dotF = delta:Dot(forward)
        if dotF <= 0 then
            return { x = 0, y = 0, visible = false }
        end

        local dotR = delta:Dot(right)
        local dotU = delta:Dot(up)

        local aspect   = w / h
        local fovRad   = math.rad(fov * 0.5)
        local tanFov   = math.tan(fovRad)

        local ndcX = dotR / (dotF * tanFov * aspect)
        local ndcY = dotU / (dotF * tanFov)

        -- fuera del frustum con margen
        if ndcX < -1.15 or ndcX > 1.15 or ndcY < -1.15 or ndcY > 1.15 then
            return { x = 0, y = 0, visible = false }
        end

        local px = scrX + (0.5 + ndcX * 0.5) * w
        local py = scrY + (0.5 - ndcY * 0.5) * h

        return {
            x       = px,
            y       = py,
            visible = ndcX >= -1 and ndcX <= 1 and ndcY >= -1 and ndcY <= 1,
        }
    end

    -- ── Función de dibujo principal ──────────────────────────────
    function scene:Paint(w, h)
        local dt  = FrameTime()
        local now = CurTime()

        -- ── Drag de mouse ──
        if dragging then
            local mx, my = input.GetCursorPos()
            local dx, dy = mx - lastX, my - lastY
            if dx ~= 0 or dy ~= 0 then
                targetCamAng.y = targetCamAng.y - dx * 0.4
                targetCamAng.p = math.Clamp(targetCamAng.p + dy * 0.4, -89, 89)
                lastX, lastY   = mx, my
                lastMoveTime   = now
            end
        end

        -- ── Auto-orbit (solo si no hay focus activo) ──
        if not dragging and not focusMode and (now - lastMoveTime) > 2 then
            targetCamAng.y = targetCamAng.y + dt * 14
        end

        -- ── Lerp suave ──
        local ls = dt * 9
        camAng.p = Lerp(ls, camAng.p, targetCamAng.p)
        camAng.y = Lerp(ls, camAng.y, targetCamAng.y)
        camDist  = Lerp(ls, camDist,  targetDist)

        local idealPos  = center - camAng:Forward() * camDist
        local safePos   = GetSafeCamPos(center, idealPos)
        currentCamPos   = LerpVector(ls, currentCamPos, safePos)

        local scrX, scrY = self:LocalToScreen(0, 0)

        -- ── 1. Renderizar mapa ──
        render.SetScissorRect(scrX, scrY, scrX + w, scrY + h, true)
        render.RenderView({
            x = scrX, y = scrY, w = w, h = h,
            origin      = currentCamPos,
            angles      = camAng,
            fov         = 90,
            drawviewer  = true,
            drawentities = false,
        })

        -- ── 2. Dibujar modelos y leer huesos en el mismo contexto 3D ──
        -- GetBonePosition solo devuelve coordenadas correctas después de
        -- DrawModel() y dentro del mismo cam.Start3D donde se dibujó.
        cam.Start3D(currentCamPos, camAng, 90, scrX, scrY, w, h)
            if IsValid(vicEnt) then
                vicEnt:DrawModel()
                -- Leer cabeza DESPUÉS del draw (huesos actualizados)
                local hb = vicEnt:LookupBone("ValveBiped.Bip01_Head1")
                if hb and hb >= 0 then
                    local bp = vicEnt:GetBonePosition(hb)
                    if bp then vicPinPos3D = bp + Vector(0, 0, 12) end
                end
            end

            if IsValid(attEnt) then
                attEnt:DrawModel()
                local hb = attEnt:LookupBone("ValveBiped.Bip01_Head1")
                if hb and hb >= 0 then
                    local bp = attEnt:GetBonePosition(hb)
                    if bp then attPinPos3D = bp + Vector(0, 0, 14) end
                end
            end

            -- Línea de trayectoria 3D
            if IsValid(attEnt) and attData.pos then
                local startLine = aPos + Vector(0, 0, 50)
                local endLine   = vPos + Vector(0, 0, 40)
                render.SetColorMaterial()
                render.DrawLine(startLine, endLine, Color(255, 80, 50, 180), true)
                render.DrawSphere(endLine,   4,   8, 8, Color(231, 76, 60, 200))
                render.DrawSphere(startLine, 2.5, 8, 8, Color(52, 152, 219, 180))
            end
        cam.End3D()
        render.SetScissorRect(0, 0, 0, 0, false)

        -- ── 3. Proyectar posiciones de los pines FUERA de cam ────
        -- Esto garantiza que la proyección sea consistente con el
        -- render que acabamos de hacer (misma cámara, mismo fov).
        local vicScreen = WorldToScreen3D(vicPinPos3D, currentCamPos, camAng, 90, scrX, scrY, w, h)
        local attScreen = attPinPos3D and WorldToScreen3D(attPinPos3D, currentCamPos, camAng, 90, scrX, scrY, w, h) or nil

        -- ── 4. Dibujar carteles tácticos ─────────────────────────
        local function DrawTacticalPin(screenData, label, col)
            if not screenData or not screenData.visible then return end

            -- Convertir de pantalla absoluta a coordenadas locales del panel
            local lx, ly = self:ScreenToLocal(screenData.x, screenData.y)

            -- Clip estricto dentro del panel
            if lx < 4 or lx > (w - 4) or ly < 4 or ly > (h - 4) then return end

            surface.SetFont("Ivo_logsT")
            local tw, th = surface.GetTextSize(label)
            local boxW = tw + 20
            local boxH = th + 10

            -- Cartel 16px encima del punto de ancla (cabeza + offset)
            local boxX = math.Clamp(lx - boxW * 0.5, 4, w - boxW - 4)
            local boxY = math.Clamp(ly - boxH - 16, 4, h - boxH - 4)
            local cx   = boxX + boxW * 0.5

            -- Línea conectora
            surface.SetDrawColor(col.r, col.g, col.b, 150)
            surface.DrawLine(cx, boxY + boxH, lx, ly)

            -- Dot en el punto del hueso
            draw.RoundedBox(3, lx - 3, ly - 3, 6, 6, Color(col.r, col.g, col.b, 230))

            -- Fondo
            draw.RoundedBox(4, boxX, boxY, boxW, boxH, Color(12, 14, 18, 240))

            -- Borde superior color
            surface.SetDrawColor(col.r, col.g, col.b, 255)
            surface.DrawRect(boxX, boxY, boxW, 2)

            -- Borde exterior sutil
            surface.SetDrawColor(col.r, col.g, col.b, 55)
            surface.DrawOutlinedRect(boxX, boxY, boxW, boxH, 1)

            -- Texto
            draw.SimpleText(label, "Ivo_logsT", cx, boxY + boxH * 0.5,
                color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        DrawTacticalPin(vicScreen, "VÍCTIMA",  Color(231, 76, 60))
        DrawTacticalPin(attScreen, "ATACANTE", Color(52, 152, 219))

        -- ── 5. Indicadores HUD ───────────────────────────────────
        if focusMode then
            local modeLabel = focusMode == "vic" and "FOCO: VÍCTIMA" or "FOCO: ATACANTE"
            local modeCol   = focusMode == "vic" and Color(231, 76, 60) or Color(52, 152, 219)
            draw.SimpleText(modeLabel .. "  ·  [X] para cámara libre",
                "Ivo_logsT", w * 0.5, h - 12,
                modeCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif not dragging and (now - lastMoveTime) > 2 then
            draw.SimpleText("⟳ Auto-órbita  ·  Click para controlar",
                "Ivo_logsT", w * 0.5, h - 12,
                Color(80, 90, 100, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    -- ── Limpieza ─────────────────────────────────────────────────
    frame.OnRemove = function()
        hook.Remove("Think", hookID .. "_Keys")
        if IsValid(vicEnt) then vicEnt:Remove() end
        if IsValid(attEnt) then attEnt:Remove() end
    end
end