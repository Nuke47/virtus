-----------------------------------------------------------
-- VISUALIZADOR DE ZONAS (HOLOGRAMAS Y CARTELES)
-----------------------------------------------------------
local DebugZones = {}
local ShowZonesTime = 0

-- Recibimos las zonas desde el servidor
net.Receive("IvoQuest_ShowZones", function()
    DebugZones = net.ReadTable()
    ShowZonesTime = CurTime() + 15 -- Durará 15 segundos visible
end)

-- Dibujamos las cajas y carteles en el mundo 3D
hook.Add("PostDrawOpaqueRenderables", "IvoQuest_RenderZones", function()
    if CurTime() > ShowZonesTime then return end

    for zoneID, data in pairs(DebugZones) do
        local min = data.min
        local max = data.max
        local center = (min + max) / 2
        
        -- Calculamos la parte más alta de la caja y le sumamos 25 unidades para que flote encima
        local topCenter = Vector(center.x, center.y, max.z + 25)

        -- 1. Dibujamos el interior de la caja (Verde translúcido)
        render.SetColorMaterial()
        render.DrawBox(Vector(0,0,0), Angle(0,0,0), min, max, Color(0, 255, 0, 30))

        -- 2. Dibujamos los bordes (Verde brillante)
        render.DrawWireframeBox(Vector(0,0,0), Angle(0,0,0), min, max, Color(0, 255, 0, 255), false)

        -- 3. Dibujamos el CARTEL FLOTANTE encima de la caja
        local ang = LocalPlayer():EyeAngles()
        ang:RotateAroundAxis(ang:Up(), -90)
        ang:RotateAroundAxis(ang:Forward(), 90)

        cam.Start3D2D(topCenter, ang, 0.5)
            -- IgnoreZ(true) hace que el cartel se vea a través de las paredes y edificios
            cam.IgnoreZ(true)
            
            local text = "ZONA: " .. string.upper(zoneID)
            surface.SetFont("Trebuchet24")
            local tw, th = surface.GetTextSize(text)
            
            -- Dibujamos el fondo negro del cartel
            draw.RoundedBox(4, -(tw / 2) - 10, -(th / 2) - 5, tw + 20, th + 10, Color(0, 0, 0, 220))
            
            -- Dibujamos el texto en verde brillante
            draw.SimpleText(text, "Trebuchet24", 0, 0, Color(50, 255, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            cam.IgnoreZ(false)
        cam.End3D2D()
    end
end)