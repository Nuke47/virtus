IvoCitadel = IvoCitadel or {}
IvoCitadel.InFreecam = false
local camPos = Vector(0,0,0)
local camAng = Angle(0,0,0)

net.Receive("IvoCitadel_ToggleFreecam", function()
    local state = net.ReadBool()
    IvoCitadel.InFreecam = state
    
    if state then
        camPos = LocalPlayer():EyePos()
        camAng = LocalPlayer():EyeAngles()
        chat.AddText(Color(0,255,0), "[Ciudadela] Cámara de Comandante ACTIVADA. Usa WASD y el ratón para moverte. Presiona la tecla [USAR] (E) para salir.")
    else
        chat.AddText(Color(255,100,0), "[Ciudadela] Cámara de Comandante DESACTIVADA.")
    end
end)

hook.Add("CalcView", "IvoCitadel_FreecamView", function(ply, pos, angles, fov)
    if not IvoCitadel.InFreecam then return end
    
    local view = {
        origin = camPos,
        angles = camAng,
        fov = fov,
        drawviewer = true
    }
    return view
end)

hook.Add("CreateMove", "IvoCitadel_FreecamMove", function(cmd)
    if not IvoCitadel.InFreecam then return end
    
    local ft = FrameTime()
    local speed = 500 * ft
    if cmd:KeyDown(IN_SPEED) then speed = speed * 3 end
    
    local mX = cmd:GetMouseX()
    local mY = cmd:GetMouseY()
    
    camAng.p = math.Clamp(camAng.p + mY * 0.02, -89, 89)
    camAng.y = camAng.y - mX * 0.02
    
    local fwd = camAng:Forward()
    local right = camAng:Right()
    
    if cmd:KeyDown(IN_FORWARD) then camPos = camPos + fwd * speed end
    if cmd:KeyDown(IN_BACK) then camPos = camPos - fwd * speed end
    if cmd:KeyDown(IN_MOVERIGHT) then camPos = camPos + right * speed end
    if cmd:KeyDown(IN_MOVELEFT) then camPos = camPos - right * speed end
    if cmd:KeyDown(IN_JUMP) then camPos = camPos + Vector(0,0,speed) end
    if cmd:KeyDown(IN_DUCK) then camPos = camPos - Vector(0,0,speed) end
    
    if cmd:KeyDown(IN_USE) then
        IvoCitadel.InFreecam = false
        net.Start("IvoCitadel_ToggleFreecam")
        net.WriteBool(false)
        net.SendToServer()
        chat.AddText(Color(255,100,0), "[Ciudadela] Cámara de Comandante DESACTIVADA.")
    end
    
    cmd:ClearMovement()
    cmd:ClearButtons()
end)

hook.Add("HUDPaint", "IvoCitadel_FreecamHUD", function()
    if not IvoCitadel.InFreecam then return end
    
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(0, 0, ScrW(), 50)
    
    draw.SimpleText("CÁMARA DE COMANDANTE", "DermaLarge", ScrW()/2, 10, Color(255,100,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText("Presiona [USAR] (Normalmente 'E') para volver a tu cuerpo", "DermaDefault", ScrW()/2, 35, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    surface.SetDrawColor(255,255,255,100)
    surface.DrawLine(ScrW()/2 - 10, ScrH()/2, ScrW()/2 + 10, ScrH()/2)
    surface.DrawLine(ScrW()/2, ScrH()/2 - 10, ScrW()/2, ScrH()/2 + 10)
end)
