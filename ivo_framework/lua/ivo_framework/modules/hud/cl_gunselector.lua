-- 1. Ocultar el selector de armas por defecto
hook.Add("HUDShouldDraw", "OcultarSelectorPorDefecto", function(name)
    if name == "CHudWeaponSelection" then 
        return false 
    end
end)

local menuAbierto = false
local tiempoOcultar = 0
local selectedIndex = 1
local scrollAnim = 1
local alphaMenu = 0 

surface.CreateFont("Compass_Selector_Text", {
    font = "Inter", size = 18, weight = 700, antialias = true
})
surface.CreateFont("Compass_Selector_Small", {
    font = "Inter", size = 14, weight = 500, antialias = true
})

local function GetValidWeapons(ply)
    local w = {}
    if not IsValid(ply) then return w end
    for _, wep in ipairs(ply:GetWeapons()) do
        table.insert(w, wep)
    end
    table.sort(w, function(a, b)
        local sA = a.GetSlot and a:GetSlot() or 0
        local sB = b.GetSlot and b:GetSlot() or 0
        if sA == sB then
            local pA = a.GetSlotPos and a:GetSlotPos() or 0
            local pB = b.GetSlotPos and b:GetSlotPos() or 0
            return pA < pB
        end
        return sA < sB
    end)
    return w
end

hook.Add("PlayerBindPress", "ControlarSelectorArmas", function(ply, bind, pressed)
    if not pressed then return end
    
    local weps = GetValidWeapons(ply)
    if #weps == 0 then return end
    
    if string.match(bind, "slot%d") then
        local slotP = tonumber(string.match(bind, "%d"))
        if not slotP or slotP < 1 or slotP > 6 then return end
        
        local foundIndex = -1
        for i, w in ipairs(weps) do
            if w.GetSlot and w:GetSlot() + 1 == slotP then
                foundIndex = i
                break
            end
        end
        if foundIndex != -1 then
            selectedIndex = foundIndex
            menuAbierto = true
            tiempoOcultar = CurTime() + 3
            surface.PlaySound("bf2nav.wav")
            return true
        end
    end

    if bind == "invnext" or bind == "invprev" then
        menuAbierto = true
        tiempoOcultar = CurTime() + 3

        if bind == "invnext" then
            selectedIndex = selectedIndex + 1
            if selectedIndex > #weps then selectedIndex = 1 end
        elseif bind == "invprev" then
            selectedIndex = selectedIndex - 1
            if selectedIndex < 1 then selectedIndex = #weps end
        end
        surface.PlaySound("bf2nav.wav")
        return true
    end

    if bind == "+attack" and menuAbierto then
        local w = weps[selectedIndex]
        if IsValid(w) then
            input.SelectWeapon(w)
        end
        menuAbierto = false
        surface.PlaySound("garrysmod/ui_click.wav")
        return true
    end
end)

hook.Add("HUDPaint", "DibujarSelectorArmas", function()
    if GetConVar("virtus_hide_hud") and GetConVar("virtus_hide_hud"):GetBool() then return end

    if CurTime() > tiempoOcultar then
        menuAbierto = false
    end

    local targetAlpha = menuAbierto and 255 or 0
    alphaMenu = Lerp(FrameTime() * 12, alphaMenu, targetAlpha)
    if alphaMenu < 1 then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local weps = GetValidWeapons(ply)
    if #weps == 0 then return end
    
    if selectedIndex > #weps then selectedIndex = #weps end
    if selectedIndex < 1 then selectedIndex = 1 end
    
    local diffCheck = selectedIndex - scrollAnim
    if diffCheck > #weps / 2 then scrollAnim = scrollAnim + #weps end
    if diffCheck < -#weps / 2 then scrollAnim = scrollAnim - #weps end
    
    scrollAnim = Lerp(FrameTime() * 15, scrollAnim, selectedIndex)
    
    local baseY = ScrH() / 2 - 80
    local rightEdge = ScrW() - 40
    
    for i = 1, #weps do
        local wep = weps[i]
        
        local diff1 = i - scrollAnim
        local diff2 = (i + #weps) - scrollAnim
        local diff3 = (i - #weps) - scrollAnim
        
        local diff = diff1
        if math.abs(diff2) < math.abs(diff) then diff = diff2 end
        if math.abs(diff3) < math.abs(diff) then diff = diff3 end
        
        if diff > -0.2 and diff < 3.5 then
            local isSelected = (i == selectedIndex)
            
            local itemScale = math.Clamp(1 - (math.abs(diff) * 0.15), 0, 1)
            local itemAlpha = math.Clamp(255 - (math.abs(diff) * 90), 0, 255) * (alphaMenu / 255)
            
            local yOffset = diff * 45
            
            local y = baseY + yOffset
            local itemWidth = 250 * itemScale
            local itemHeight = 40
            local x = rightEdge - itemWidth
            
            wep._hudAnim = wep._hudAnim or 0
            wep._hudAnim = Lerp(FrameTime() * 15, wep._hudAnim, isSelected and 1 or 0)
            
            local bgAlpha = 80 * (itemAlpha / 255)
            local fillAlpha = 255 * wep._hudAnim * (itemAlpha / 255)
            
            draw.RoundedBox(16, x, y, itemWidth, itemHeight, Color(0, 0, 0, bgAlpha))
            if wep._hudAnim > 0.01 then
                draw.RoundedBox(16, x, y, itemWidth, itemHeight, Color(255, 255, 255, fillAlpha))
            end
            
            local name = wep:GetPrintName()
            if not name or name == "" then name = wep:GetClass() end
            if name == "#GMOD_ToolGun" or wep:GetClass() == "gmod_tool" then name = "TOOLGUN" end
            if name == "#GMOD_Camera" or wep:GetClass() == "gmod_camera" then name = "CÁMARA" end
            if name == "#HL2_Physcannon" or wep:GetClass() == "weapon_physcannon" then name = "GRAVITY GUN" end
            if name == "#HL2_PhysicsGun" or wep:GetClass() == "weapon_physgun" then name = "PHYSGUN" end
            name = string.upper(name)
            
            local tc = Lerp(wep._hudAnim, 200, 0)
            local tColor = Color(tc, tc, tc, itemAlpha)
            if wep._hudAnim > 0.9 then tColor = Color(0, 0, 0, itemAlpha) end
            
            local font = isSelected and "SW_InvShop_Medium" or "SW_InvShop_Small"
            draw.SimpleText(name, font, x + itemWidth - 15, y + itemHeight/2, tColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            
            local slotText = tostring((wep.GetSlot and wep:GetSlot() or 0) + 1)
            draw.SimpleText(slotText, "SW_InvShop_Aurebesh_ExtraSmall", x + 15, y + itemHeight/2, Color(tc, tc, tc, 100 * (itemAlpha / 255) + fillAlpha * 0.6), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end)


