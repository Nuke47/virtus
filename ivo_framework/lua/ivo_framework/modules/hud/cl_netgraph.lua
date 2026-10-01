CreateClientConVar("c_netgraph", "0", true, false, "Variantes: 0 = Desactivado, 1 = Básico (FPS, Ping, Tickrate, Lerp), 5 = Detallado (Gráficas de rendimiento)")

surface.CreateFont("CNetGraph_Normal", {
    font = "SansSerifFLF",
    size = 14,
    weight = 500,
    antialias = true,
})

surface.CreateFont("CNetGraph_Small", {
    font = "SansSerifFLF",
    size = 12,
    weight = 500,
    antialias = true,
})

local fpsHistory = {}
local pingHistory = {}
local maxHistory = 120
local updateTimer = 0

-- Colores del estilo tienda 3D ivo_utils (Menos chillón, más gris y naranjas oscuros/blancos)
local clrText = Color(200, 200, 200, 255)
local clrValue = Color(255, 255, 255, 255)
local clrAccLine = Color(255, 180, 0, 80)
local clrBg = Color(0, 0, 0, 80) -- El fondo negro sutil de la tienda 3D

-- Para las gráficas usaremos blanco/gris para no llamar mucho la atención
local clrGraphFPS = Color(200, 200, 200, 100)
local clrGraphPing = Color(255, 180, 0, 100)

local function GetLerpTime()
    local cl_interp = GetConVar("cl_interp"):GetFloat()
    if cl_interp > 0 then return cl_interp * 1000 end
    
    local cl_updaterate = GetConVar("cl_updaterate"):GetFloat()
    local cl_interp_ratio = GetConVar("cl_interp_ratio"):GetFloat()
    
    if cl_updaterate == 0 then return 0 end
    return (cl_interp_ratio / cl_updaterate) * 1000
end

hook.Add("HUDPaint", "CustomNetGraph_Render", function()
    local mode = GetConVar("c_netgraph"):GetInt()
    if mode ~= 1 and mode ~= 5 then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local cvHide = GetConVar("virtus_hide_hud")
    if cvHide and cvHide:GetBool() then return end

    local ping = ply:Ping()
    local ft = FrameTime()
    local fps = math.floor(1 / ft)
    local tickrate = math.floor(1 / engine.TickInterval())
    local lerp = math.Round(GetLerpTime(), 1)
    local curTime = SysTime()

    if curTime > updateTimer then
        table.insert(fpsHistory, fps)
        if #fpsHistory > maxHistory then table.remove(fpsHistory, 1) end

        table.insert(pingHistory, ping)
        if #pingHistory > maxHistory then table.remove(pingHistory, 1) end
        
        updateTimer = curTime + 0.05
    end

    -- Limpiar el callback anterior que bloqueaba la consola
    cvars.RemoveChangeCallback("c_netgraph", "NetGraphBlocker")

    local padding = 15
    local width = 360
    local height = mode == 5 and 150 or 35
    
    local x = ScrW() - width - 80 
    local y = 0
    if mode == 5 then
        -- La versión con gráficas es muy alta, así que va por ENCIMA del HUD de gas
        y = ScrH() - 180 - height
    else
        -- La versión de solo texto es pequeña, cabe perfectamente por DEBAJO del gas
        y = ScrH() - 25 - height 
    end

    -- ==== INICIO EFECTO 3D (PARALAJE) ====
    if _G.VirtusSway and _G.VirtusSway.Begin3D then 
        _G.VirtusSway.Begin3D(2.5, x, y) 
    end

    -- Fondo
    draw.RoundedBox(16, x, y, width, height, clrBg)

    -- === MODO 1 y 5: Información Básica ===
    local textY = y + 10
    
    -- FPS
    draw.SimpleText("FPS: ", "CNetGraph_Normal", x + padding, textY, clrText)
    draw.SimpleText(tostring(fps), "CNetGraph_Normal", x + padding + 35, textY, clrValue)

    -- PING
    draw.SimpleText("PING: ", "CNetGraph_Normal", x + padding + 85, textY, clrText)
    draw.SimpleText(tostring(ping) .. "ms", "CNetGraph_Normal", x + padding + 125, textY, clrValue)

    -- LERP
    draw.SimpleText("LERP: ", "CNetGraph_Normal", x + padding + 180, textY, clrText)
    draw.SimpleText(tostring(lerp) .. "ms", "CNetGraph_Normal", x + padding + 225, textY, clrValue)

    -- TICKRATE
    draw.SimpleText("TICK: ", "CNetGraph_Normal", x + padding + 285, textY, clrText)
    draw.SimpleText(tostring(tickrate), "CNetGraph_Normal", x + padding + 325, textY, clrValue)

    -- === MODO 5: Gráficas detalladas ===
    if mode == 5 then
        local graphY = y + 35
        local graphW = width - (padding * 2)
        local graphH = 30

        -- Fondo gráfica FPS
        draw.RoundedBox(8, x + padding, graphY, graphW, graphH, Color(0, 0, 0, 50))
        draw.SimpleText("RENDIMIENTO FPS", "CNetGraph_Small", x + padding, graphY - 12, Color(120, 120, 120))

        local maxFPS = 300
        for i = 2, #fpsHistory do
            local prevFps = math.Clamp(fpsHistory[i-1], 0, maxFPS)
            local curFps = math.Clamp(fpsHistory[i], 0, maxFPS)
            local x1 = x + padding + (graphW / maxHistory) * (i - 2)
            local y1 = graphY + graphH - (prevFps / maxFPS) * graphH
            local x2 = x + padding + (graphW / maxHistory) * (i - 1)
            local y2 = graphY + graphH - (curFps / maxFPS) * graphH
            surface.SetDrawColor(clrGraphFPS)
            surface.DrawLine(x1, y1, x2, y2)
        end

        -- Gráfica de Ping
        local pingGraphY = graphY + graphH + 20
        draw.RoundedBox(8, x + padding, pingGraphY, graphW, graphH, Color(0, 0, 0, 50))
        draw.SimpleText("LATENCIA (PING)", "CNetGraph_Small", x + padding, pingGraphY - 12, Color(120, 120, 120))

        local maxPingValue = 200
        for i = 2, #pingHistory do
            local prevP = math.Clamp(pingHistory[i-1], 0, maxPingValue)
            local curP = math.Clamp(pingHistory[i], 0, maxPingValue)
            local x1 = x + padding + (graphW / maxHistory) * (i - 2)
            local y1 = pingGraphY + graphH - (prevP / maxPingValue) * graphH
            local x2 = x + padding + (graphW / maxHistory) * (i - 1)
            local y2 = pingGraphY + graphH - (curP / maxPingValue) * graphH
            surface.SetDrawColor(clrGraphPing)
            surface.DrawLine(x1, y1, x2, y2)
        end

        -- Información útil extra al fondo de las gráficas
        local extraY = pingGraphY + graphH + 10
        local entsCount = ents.GetCount()
        local memLua = math.Round(collectgarbage("count") / 1024, 1)

        draw.SimpleText("ENTIDADES: ", "CNetGraph_Small", x + padding, extraY, clrText)
        draw.SimpleText(tostring(entsCount), "CNetGraph_Small", x + padding + 65, extraY, clrValue)

        draw.SimpleText("MEMORIA LUA: ", "CNetGraph_Small", x + padding + 130, extraY, clrText)
        draw.SimpleText(tostring(memLua) .. " MB", "CNetGraph_Small", x + padding + 210, extraY, clrValue)
    end

    -- ==== FIN EFECTO 3D ====
    if _G.VirtusSway and _G.VirtusSway.End3D then 
        _G.VirtusSway.End3D() 
    end
end)
