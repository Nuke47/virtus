hook.Add("Think", "SW_Block_TFA_Inspect", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep.IsTFAWeapon then
        if wep:GetNW2Bool("Inspecting") then
            if wep.SetNW2Bool then wep:SetNW2Bool("Inspecting", false) end
        end
        wep.Inspecting = false
        wep.InspectingProgress = 0
        if wep.ToggleInspect ~= TFA_Blocker_EmptyFn then
            TFA_Blocker_EmptyFn = function() end
            wep.ToggleInspect = TFA_Blocker_EmptyFn
        end
        if IsValid(ply.TFAAttachmentPanel) then ply.TFAAttachmentPanel:Remove() end
    end
end)

hook.Add("HUDPaint", "SW_Magazines_HUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    if ply:GetNWBool("IVO_RTSMode", false) then return end
    
    local cvHide = GetConVar("virtus_hide_hud")
    if cvHide and cvHide:GetBool() then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not wep.IsTFAWeapon then return end
    
    local gas = 0
    local reserve = 0
    local showGas = false
    local isTFA = wep.IsTFAWeapon
    local ammoType = wep:GetPrimaryAmmoType()
    
    if isTFA then
        local isSec = (wep.Slot == 1)
        local key = isSec and "CellStatus_Secondary" or "CellStatus_Primary"
        gas = ply:GetNW2Int(key, 100)
        showGas = true
    end
    
    if ammoType ~= -1 then
        local maxClip = wep:GetMaxClip1()
        if maxClip <= 0 then maxClip = 50 end
        reserve = math.floor(ply:GetAmmoCount(ammoType) / maxClip)
    end
    
    local wepName = wep:GetPrintName() or "ARMA"
    if wepName == "" then wepName = "ARMA" end
    wepName = string.upper(wepName)
    
    local subText = "ESTADO DEL ARMA"
    if showGas then
        subText = "SISTEMA DE ENFRIAMIENTO"
    elseif ammoType ~= -1 then
        subText = "CINTURON DE CARGADORES"
    end
    
    local h = 90
    local rx = ScrW() - 80
    local ry = ScrH() - h - 80
    local ty = ry + 10
    
    if _G.VirtusSway then _G.VirtusSway.Begin3D(2.5, rx, ty) end
    
    local c_acc = _G.VIRTUS_GetHUDColor and _G.VIRTUS_GetHUDColor("accent") or Color(0, 150, 255)
    
    surface.SetFont("VirtusHUD_Name")
    local nameW = surface.GetTextSize(wepName)
    
    draw.SimpleText(wepName, "VirtusHUD_Name", rx, ty, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    
    surface.SetDrawColor(c_acc.r, c_acc.g, c_acc.b, 120)
    surface.DrawRect(rx - nameW, ty + 25, nameW, 1)
    
    draw.SimpleText(subText, "VirtusHUD_Job", rx, ty + 34, c_acc, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    
    local barW = math.max(220, nameW)
    local barH = 22
    local bx = rx - barW
    local by = ty + 66
    
    if showGas then
        local gasPct = math.Clamp(gas / 100, 0, 1)
        local gasColor = Color(0, 200, 255)
        if gas < 25 then gasColor = Color(255, 50, 50) 
        elseif gas < 50 then gasColor = Color(255, 170, 0) end
        
        draw.RoundedBox(6, bx, by, barW, barH, Color(10, 10, 15, 140))
        
        local fillW = barW * gasPct
        if fillW > 0 then
            draw.RoundedBox(6, bx, by, fillW, barH, gasColor)
        end
        
        local gasText = math.Round(gas) .. "%"
        surface.SetFont("VirtusHUD_AurebeshBar")
        local txtW, _ = surface.GetTextSize(gasText)
        local numCol = fillW > (barW - txtW - 8) and Color(15, 15, 15, 230) or Color(255, 255, 255, 230)
        draw.SimpleText(gasText, "VirtusHUD_AurebeshBar", bx + barW - 6, by + barH/2 - 1, numCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        
        by = by + barH + 10
    elseif ammoType ~= -1 and wep:Clip1() >= 0 and wep:GetMaxClip1() > 0 then
        local maxClip = wep:GetMaxClip1()
        local clip = wep:Clip1()
        local clipPct = math.Clamp(clip / maxClip, 0, 1)
        
        local clipColor = Color(255, 255, 255)
        if clipPct < 0.25 then clipColor = Color(255, 50, 50) end
        
        draw.RoundedBox(6, bx, by, barW, barH, Color(10, 10, 15, 140))
        
        local fillW = barW * clipPct
        if fillW > 0 then
            draw.RoundedBox(6, bx, by, fillW, barH, clipColor)
        end
        
        local clipText = tostring(clip)
        surface.SetFont("VirtusHUD_AurebeshBar")
        local txtW, _ = surface.GetTextSize(clipText)
        local numCol = fillW > (barW - txtW - 8) and Color(15, 15, 15, 230) or Color(255, 255, 255, 230)
        draw.SimpleText(clipText, "VirtusHUD_AurebeshBar", bx + barW - 6, by + barH/2 - 1, numCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        
        by = by + barH + 10
    end
    
    if ammoType ~= -1 then
        if reserve > 0 then
            local slotW = 12
            local slotH = 14
            local spacing = 4
            local dispRes = math.min(15, reserve)
            
            for i = 1, dispRes do
                local mx = rx - (i * (slotW + spacing)) + spacing
                draw.RoundedBox(4, mx, by, slotW, slotH, Color(c_acc.r, c_acc.g, c_acc.b, 200))
            end
            
            if reserve > dispRes then
                draw.SimpleText("+" .. (reserve - dispRes), "VirtusHUD_AurebeshBar", rx - (dispRes * (slotW + spacing)) - 5, by + slotH/2 - 1, Color(200, 200, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
        else
            draw.SimpleText("SIN CARGADORES", "VirtusHUD_Job", rx, by, Color(255, 50, 50, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end
    end
    
    if _G.VirtusSway then _G.VirtusSway.End3D() end
end)

hook.Add("HUDShouldDraw", "SW_HideDefaultAmmo_GasHUD", function(name)
    if name == "CHudAmmo" or name == "CHudSecondaryAmmo" then
        local ply = LocalPlayer()
        if IsValid(ply) and ply:Alive() then
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and wep.IsTFAWeapon then
                return false
            end
        end
    end
    -- Ocultar el HUD nativo de TFA (el de las barras curvas)
    if name == "TFA_DrawHUD" or name == "TFA_HUDPaint" then
        return false
    end
end)
