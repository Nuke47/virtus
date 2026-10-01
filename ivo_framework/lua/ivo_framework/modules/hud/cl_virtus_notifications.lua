local NoticeMaterial = {}
NoticeMaterial[NOTIFY_GENERIC] = Material("vgui/notices/generic")
NoticeMaterial[NOTIFY_ERROR] = Material("vgui/notices/error")
NoticeMaterial[NOTIFY_UNDO] = Material("vgui/notices/undo")
NoticeMaterial[NOTIFY_HINT] = Material("vgui/notices/hint")
NoticeMaterial[NOTIFY_CLEANUP] = Material("vgui/notices/cleanup")

local HUDNotes = {}

function notification.AddLegacy(text, type, length)
    table.insert(HUDNotes, {
        text = text,
        type = type,
        length = length,
        time = CurTime(),
        y = 0,
        x = ScrW() + 300
    })
    if IsValid(LocalPlayer()) then
        -- LocalPlayer():EmitSound("garrysmod/content_downloaded.wav", 75, 100, 0.2)
    end
end

-- Override DarkRP notifications if they exist
hook.Add("InitPostEntity", "Virtus_DarkRP_Notify_Override", function()
    if DarkRP and DarkRP.notify then
        DarkRP.notify = function(ply, msgtype, len, msg)
            if ply == LocalPlayer() or ply == nil then
                notification.AddLegacy(msg, msgtype, len)
            end
        end
    end
end)

surface.CreateFont("Virtus_Notify", {
    font = "Inter",
    size = 18,
    weight = 500,
    antialias = true
})

hook.Add("HUDPaint", "Virtus_DrawNotifications", function()
    if GetConVar("virtus_hide_hud") and GetConVar("virtus_hide_hud"):GetBool() then return end

    local c_bg = _G.VIRTUS_GetHUDColor and _G.VIRTUS_GetHUDColor("bg") or Color(10, 15, 25, 200)
    local c_acc = _G.VIRTUS_GetHUDColor and _G.VIRTUS_GetHUDColor("accent") or Color(0, 150, 255)

    local baseY = ScrH() * 0.75
    
    for k = #HUDNotes, 1, -1 do
        local v = HUDNotes[k]
        if not v then continue end

        local timeLeft = (v.time + v.length) - CurTime()
        local targetX = ScrW() - 20
        local alpha = 255
        
        if timeLeft < 0 then
            targetX = ScrW() + 500
        elseif timeLeft < 0.5 then
            alpha = (timeLeft / 0.5) * 255
        end

        v.x = Lerp(FrameTime() * 10, v.x, targetX)
        
        local idealY = baseY - (k * 45)
        if v.y == 0 then v.y = idealY end
        v.y = Lerp(FrameTime() * 10, v.y, idealY)
        
        if v.x > ScrW() + 300 then
            table.remove(HUDNotes, k)
            continue
        end
        
        surface.SetFont("Virtus_Notify")
        local tw, th = surface.GetTextSize(v.text)
        local w = tw + 40
        local h = 35
        local x = v.x - w
        local y = v.y
        
        local cut = 10
        draw.NoTexture()
        surface.SetDrawColor(c_bg.r, c_bg.g, c_bg.b, c_bg.a * (alpha/255))
        local poly = { {x=x, y=y}, {x=x+w, y=y}, {x=x+w, y=y+h-cut}, {x=x+w-cut, y=y+h}, {x=x, y=y+h} }
        surface.DrawPoly(poly)
        
        local typeColor = c_acc
        if v.type == 1 or v.type == NOTIFY_ERROR then typeColor = Color(220, 50, 50) end
        if v.type == 0 or v.type == NOTIFY_GENERIC then typeColor = c_acc end
        if v.type == 2 or v.type == NOTIFY_UNDO then typeColor = Color(200, 150, 50) end
        
        surface.SetDrawColor(typeColor.r, typeColor.g, typeColor.b, 150 * (alpha/255))
        surface.DrawLine(x, y, x + w, y)
        surface.DrawLine(x + w, y, x + w, y + h - cut)
        surface.DrawLine(x + w, y + h - cut, x + w - cut, y + h)
        surface.DrawLine(x + w - cut, y + h, x, y + h)
        surface.DrawLine(x, y + h, x, y)
        
        surface.SetDrawColor(typeColor.r, typeColor.g, typeColor.b, 255 * (alpha/255))
        surface.DrawRect(x, y, 4, h)
        
        surface.SetDrawColor(typeColor.r, typeColor.g, typeColor.b, 10 * (alpha/255))
        for k = 0, h, 4 do 
            local lw = w
            if k > h - cut then lw = w - (k - (h - cut)) end
            surface.DrawLine(x, y + k, x + lw, y + k) 
        end
        
        draw.SimpleText(v.text, "Virtus_Notify", x + 15, y + h/2, Color(255, 255, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end)

hook.Add("DrawDeathNotice", "HideDefaultDeathNotice", function()
    -- Return true o false dependiendo de si queremos ocultar las killfeeds. Por ahora las dejamos nativas, solo cambiamos AddLegacy.
end)


