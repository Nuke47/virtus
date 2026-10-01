include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos() + Vector(0, 0, 60)
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), -90)
    
    -- Hacer que el texto siempre mire al jugador
    if LocalPlayer():GetPos():DistToSqr(pos) < 90000 then
        cam.Start3D2D(pos, ang, 0.1)
            surface.SetDrawColor(0, 0, 0, 200)
            surface.DrawRect(-150, -40, 300, 80)
            
            surface.SetDrawColor(255, 50, 50, 255)
            surface.DrawOutlinedRect(-150, -40, 300, 80, 2)
            
            local pulse = math.abs(math.sin(CurTime() * 4)) * 100 + 155
            draw.SimpleText("SISTEMA DE PROCESAMIENTO", "Trebuchet24", 0, -10, Color(255, 50, 50, pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("65TH SHOCK TROOPERS", "DermaDefault", 0, 15, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end

-- Menú de arresto
net.Receive("IvoDatapad_OpenArrestMenu", function()
    local target = net.ReadEntity()
    if not IsValid(target) then return end
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 350)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 25, 240))
        surface.SetDrawColor(255, 50, 50, 150)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        draw.SimpleText("PROCESAMIENTO CRIMINAL", "Trebuchet24", w/2, 20, Color(255, 50, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Sujeto: " .. target:Nick(), "DermaDefault", w/2, 50, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    local reasons = {
        { name = "Asesinato / Homicidio", time = 300 },
        { name = "Agresión a Oficial", time = 240 },
        { name = "Infiltración / Espionaje", time = 400 },
        { name = "Robo de Propiedad Imperial", time = 180 },
        { name = "Desobediencia / Insubordinación", time = 120 },
        { name = "Faltar el respeto a un Superior", time = 90 }
    }
    
    local yPos = 80
    for _, data in ipairs(reasons) do
        local btn = vgui.Create("DButton", frame)
        btn:SetPos(20, yPos)
        btn:SetSize(360, 30)
        btn:SetText("")
        btn.Paint = function(self, w, h)
            local isHover = self:IsHovered()
            draw.RoundedBox(4, 0, 0, w, h, isHover and Color(255, 50, 50, 50) or Color(50, 50, 50, 100))
            draw.SimpleText(data.name .. " (" .. data.time .. "s)", "DermaDefault", w/2, h/2, isHover and Color(255, 255, 255) or Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function()
            net.Start("IvoDatapad_SubmitArrest")
                net.WriteEntity(target)
                net.WriteString(data.name)
                net.WriteUInt(data.time, 16)
            net.SendToServer()
            frame:Close()
        end
        yPos = yPos + 35
    end
    
    -- Opción manual
    local customEntry = vgui.Create("DTextEntry", frame)
    customEntry:SetPos(20, yPos + 10)
    customEntry:SetSize(250, 30)
    customEntry:SetPlaceholderText("Motivo personalizado...")
    
    local customBtn = vgui.Create("DButton", frame)
    customBtn:SetPos(280, yPos + 10)
    customBtn:SetSize(100, 30)
    customBtn:SetText("ARRESTAR (150s)")
    customBtn.DoClick = function()
        local txt = customEntry:GetValue()
        if txt == "" then txt = "Motivo Clasificado" end
        net.Start("IvoDatapad_SubmitArrest")
            net.WriteEntity(target)
            net.WriteString(txt)
            net.WriteUInt(150, 16)
        net.SendToServer()
        frame:Close()
    end
end)
