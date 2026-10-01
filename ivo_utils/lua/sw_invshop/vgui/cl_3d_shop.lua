SW_InvShop = SW_InvShop or {}

local function SpaceText(str)
    if not str then return "" end
    if not utf8 or not utf8.codes then return string.Trim(string.gsub(str, ".", "%1 ")) end
    local res = ""
    local success = pcall(function()
        for p, c in utf8.codes(str) do res = res .. utf8.char(c) .. " " end
    end)
    if not success then return string.Trim(string.gsub(str, ".", "%1 ")) end
    return string.Trim(res)
end

-- Recreate Aurebesh fonts after map load to guarantee VirtusBe TTF is mounted
hook.Add("InitPostEntity", "SW_InvShop_ReloadAurebeshFonts", function()
    surface.CreateFont("SW_InvShop_Aurebesh_ExtraSmall", { font = "VirtusBe", size = 9,  weight = 500, antialias = true })
    surface.CreateFont("SW_InvShop_Aurebesh_Medium",     { font = "VirtusBe", size = 18, weight = 500, antialias = true })
    surface.CreateFont("SW_InvShop_Aurebesh_Title",      { font = "VirtusBe", size = 16, weight = 500, antialias = true })
    surface.CreateFont("SW_InvShop_Aurebesh_BigTitle",   { font = "VirtusBe", size = 28, weight = 500, antialias = true })
    surface.CreateFont("SW_Aurebesh_Money",              { font = "VirtusBe", size = 26, weight = 500, antialias = true })
end)

surface.CreateFont("SW_InvShop_Aurebesh_ExtraSmall", {
    font = "VirtusBe",
    size = 9,
    weight = 500,
    antialias = true
})
surface.CreateFont("SW_InvShop_Aurebesh_Medium", {
    font = "VirtusBe",
    size = 18,
    weight = 500,
    antialias = true
})
surface.CreateFont("SW_InvShop_Aurebesh_Title", {
    font = "VirtusBe",
    size = 16,
    weight = 500,
    antialias = true
})
surface.CreateFont("SW_InvShop_BigTitle", {
    font = "SansSerifFLF",
    size = 32,
    weight = 500,
    antialias = true
})
surface.CreateFont("SW_InvShop_Medium", {
    font = "SansSerifFLF",
    size = 20,
    weight = 500,
    antialias = true
})
surface.CreateFont("SW_InvShop_Aurebesh_BigTitle", {
    font = "VirtusBe",
    size = 28,
    weight = 500,
    antialias = true
})
surface.CreateFont("SW_InvShop_Small", {
    font = "SansSerifFLF",
    size = 14,
    weight = 500,
    antialias = true
})
surface.CreateFont("SW_InvShop_Header", {
    font = "SansSerifFLF",
    size = 28,
    weight = 500,
    antialias = true
})

-- =================================================================
-- CONFIGURACIÓN DE POSICIONES Y CÁMARA (TIENDA 3D)
-- =================================================================
SW_InvShop.Config3D_WeaponPos = Vector(-2969.322266, -7158.470703, -14462.227539 - 40)
SW_InvShop.Config3D_WeaponAng = Angle(0, -88.587685, 0)
SW_InvShop.Config3D_WeaponCamOffset = Vector(-60, 0, 10) 

SW_InvShop.Config3D_PlayerPos = Vector(-2827.603760, -6738.113770, -14580)
SW_InvShop.Config3D_PlayerAng = Angle(0, 221.45, 0)
SW_InvShop.Config3D_PlayerCamOffset = Vector(110, -20, -5)
-- =================================================================

_G.SW_Shop3D_Active = false
local Shop3D_NPC = NULL
local Shop3D_IsBlackMarket = false
local Shop3D_Frame = NULL

-- Rotación manual y enfoque dinámico
local Shop3D_ManualRot = 0
local Shop3D_ManualRotPitch = 0
local Shop3D_TargetModelRot = 0
local Shop3D_CurrentModelRot = 0
local Shop3D_TargetCamZOffset = 0
local Shop3D_CurrentCamZOffset = 0
local Shop3D_WeaponCenterOffset = Vector(0,0,0)

local Shop3D_Categories = {}
local Shop3D_WeaponModel = NULL

-- Estado de expansión del menú (Categorías y Subcategorías)
local Shop3D_Expanded = {}

-- Fuentes
surface.CreateFont("SW_Aurebesh_Money", { font = "VirtusBe", size = 26, weight = 500, antialias = true })

local function IsPlayerRightSide(ply, itemData)
    if not SW_InvShop.Config.UnderworldJobs then return true end
    
    local isUnderworld = false
    local myTeam = ply:Team()
    
    for _, jobIdentifier in pairs(SW_InvShop.Config.UnderworldJobs) do
        local requiredID = type(jobIdentifier) == "string" and _G[jobIdentifier] or jobIdentifier
        if requiredID and myTeam == requiredID then 
            isUnderworld = true 
            break 
        end
    end
    
    if itemData.isContraband and not isUnderworld then return false end
    if not itemData.isContraband and isUnderworld then return false end
    
    return true
end

local function CanPlayerUseItem(ply, itemID)
    local itemData = SW_InvShop.Config.Items[itemID]
    if not itemData or not itemData.category then return true end

    if not IsPlayerRightSide(ply, itemData) then return false end

    -- 0. Check Level Restrictions (IVOSAM)
    local reqLevel = itemData.levelReq or 0
    if reqLevel == 0 then
        local catConfigLevel = nil
        if itemData.isContraband then 
            catConfigLevel = SW_InvShop.Config.BMCategories[itemData.category]
        elseif itemData.isAmmo then 
            catConfigLevel = SW_InvShop.Config.AmmoCategories[itemData.category]
        else 
            catConfigLevel = SW_InvShop.Config.Categories[itemData.category]
        end
        if catConfigLevel and catConfigLevel.levelReq then
            reqLevel = catConfigLevel.levelReq
        end
    end
    
    if reqLevel > 0 then
        local plyLevel = ply.GetLevel and ply:GetLevel() or 1
        if plyLevel < reqLevel then return false end
    end

    local myJobNum = ply:Team()
    local myJobName = string.lower(team.GetName(myJobNum) or "")

    local itemHasJobs = (itemData.allowedJobs and table.Count(itemData.allowedJobs) > 0)
    local itemHasKeywords = (itemData.allowedKeywords and table.Count(itemData.allowedKeywords) > 0)

    if itemHasJobs or itemHasKeywords then
        local allowed = false
        if itemHasJobs then
            for _, jobIdentifier in pairs(itemData.allowedJobs) do
                local requiredID = type(jobIdentifier) == "string" and _G[jobIdentifier] or jobIdentifier
                if requiredID and myJobNum == requiredID then allowed = true break end
            end
        end
        if not allowed and itemHasKeywords then
            for _, keyword in pairs(itemData.allowedKeywords) do
                if string.find(myJobName, string.lower(keyword)) then
                    allowed = true
                    break
                end
            end
        end
        if not allowed then return false end
    end

    local catConfig = itemData.isContraband and SW_InvShop.Config.BMCategories[itemData.category] or SW_InvShop.Config.Categories[itemData.category]
    
    if not catConfig then return true end
    
    local catHasJobs = (catConfig.allowedJobs and table.Count(catConfig.allowedJobs) > 0)
    local catHasKeywords = (catConfig.allowedKeywords and table.Count(catConfig.allowedKeywords) > 0)
    
    if not catHasJobs and not catHasKeywords then return true end
    
    if catHasJobs then
        for _, jobIdentifier in pairs(catConfig.allowedJobs) do
            local requiredID = type(jobIdentifier) == "string" and _G[jobIdentifier] or jobIdentifier
            if requiredID and myJobNum == requiredID then return true end
        end
    end
    
    if catHasKeywords then
        for _, keyword in pairs(catConfig.allowedKeywords) do
            if string.find(myJobName, string.lower(keyword)) then
                return true
            end
        end
    end
    
    return false
end

-- Verifica si el modelo del jugador tiene los bodygroups para este accesorio
local function CanEquipAccessory(itemID)
    local rules = SW_InvShop.Config.BodygroupUnlocks and SW_InvShop.Config.BodygroupUnlocks[itemID]
    if not rules then return true end
    
    local keywords = type(rules) == "table" and (rules.keywords or rules) or {rules}
    local myModel = LocalPlayer()
    
    for _, bg in pairs(myModel:GetBodyGroups() or {}) do
        local bgName = string.lower(bg.name or "")
        
        for subID, subName in pairs(bg.submodels or {}) do
            subName = string.lower(subName)
            for _, kw in ipairs(keywords) do
                local kwLower = string.lower(kw)
                if string.find(subName, kwLower) or string.find(bgName, kwLower) then
                    return true
                elseif (string.find(bgName, "bino") or string.find(bgName, "visor")) and (string.find(subName, "up") or string.find(subName, "down")) then
                    return true
                end
            end
        end
    end
    return false
end

local Shop3D_WeaponModels = {}

local function ApplyBodygroupPreview(modelEnt, itemID)
    local rules = SW_InvShop.Config.BodygroupUnlocks and SW_InvShop.Config.BodygroupUnlocks[itemID]
    if not rules then return end
    
    local keywords = type(rules) == "table" and (rules.keywords or rules) or {rules}
    local excludes = type(rules) == "table" and rules.excludes or {}
    
    for _, bg in pairs(modelEnt:GetBodyGroups() or {}) do
        local bgName = string.lower(bg.name or "")
        
        local matchedIndex = nil
        for subID, subName in pairs(bg.submodels or {}) do
            if subID > 0 then
                subName = string.lower(subName)
                
                local match = false
                for _, kw in ipairs(keywords) do
                    local kwLower = string.lower(kw)
                    if string.find(subName, kwLower) or string.find(bgName, kwLower) then
                        match = true
                        break
                    elseif (string.find(bgName, "bino") or string.find(bgName, "visor")) and (string.find(subName, "up") or string.find(subName, "down")) then
                        match = true
                        break
                    end
                end
                
                if match then
                    for _, ex in ipairs(excludes) do
                        if string.find(subName, string.lower(ex)) then
                            match = false
                            break
                        end
                    end
                end
                
                if match then
                    matchedIndex = subID
                    break
                end
            end
        end
        
        if not matchedIndex then
            local match = false
            for _, kw in ipairs(keywords) do
                if string.find(bgName, string.lower(kw)) then match = true break end
            end
            if match then matchedIndex = 1 end
        end
        
        if matchedIndex then
            modelEnt:SetBodygroup(bg.id, matchedIndex)
            break
        end
    end
end

local function CreateWeaponModel(item)
    for _, mdlData in pairs(Shop3D_WeaponModels) do
        if IsValid(mdlData.ent) then mdlData.ent:Remove() end
    end
    Shop3D_WeaponModels = {}
    
    if not item then return end
    
    local isBG = (item.class == "bg_unlock")
    local modelStr = isBG and LocalPlayer():GetModel() or item.model
    
    if item.isWeapon and item.class then
        local wepTbl = weapons.Get(item.class) or weapons.GetStored(item.class)
        if wepTbl then
            -- Intentar extraer el modelo personalizado de WElements (lo que realmente se ve en las manos)
            local wElemModel = nil
            if wepTbl.WElements then
                for k, v in pairs(wepTbl.WElements) do
                    if v.type == "Model" and v.model and v.model ~= "" then
                        wElemModel = v.model
                        break
                    end
                end
            end
            
            if wElemModel then
                modelStr = wElemModel
            elseif wepTbl.WorldModel and wepTbl.WorldModel ~= "" then
                modelStr = wepTbl.WorldModel
            end
        end
    end
    
    if not modelStr or modelStr == "" then return end
    
    local iname = string.lower(item.name)
    if string.find(iname, "jetpack") or string.find(iname, "backpack") or string.find(iname, "jumpack") or string.find(iname, "mochila") then
        Shop3D_TargetModelRot = 180
        Shop3D_TargetCamZOffset = 5
    elseif string.find(iname, "macrobinocular") or string.find(iname, "range finder") or string.find(iname, "casco") or string.find(iname, "visor") or string.find(iname, "head") then
        Shop3D_TargetModelRot = 0
        Shop3D_TargetCamZOffset = 10
    else
        Shop3D_TargetModelRot = 0
        Shop3D_TargetCamZOffset = 0
    end
    Shop3D_ManualRotPitch = 0
    
    Shop3D_WeaponCenterOffset = Vector(0,0,0)
    local mdl = ClientsideModel(modelStr)
    if IsValid(mdl) then
        mdl:SetNoDraw(true)
        if isBG then
            mdl:SetSkin(LocalPlayer():GetSkin())
            for i = 0, LocalPlayer():GetNumBodyGroups() - 1 do
                mdl:SetBodygroup(i, LocalPlayer():GetBodygroup(i))
            end
            ApplyBodygroupPreview(mdl, item.id)
            local seq = mdl:LookupSequence("idle_unarmed")
            if seq <= 0 then seq = mdl:LookupSequence("idle_all_01") end
            if seq <= 0 then seq = mdl:LookupSequence("idle_subtle") end
            if seq > 0 then mdl:ResetSequence(seq) end
        else
            -- Calculate the exact center bounds of the world model for perfect rotation pivot
            local min, max = mdl:GetModelBounds()
            if min and max then
                Shop3D_WeaponCenterOffset = (min + max) / 2
            end
        end
        table.insert(Shop3D_WeaponModels, { ent = mdl, isBase = true, isBG = isBG })
    end
end

function SW_InvShop:Open3DShop(npcEnt, isBlackMarket)
    _G.SW_Shop3D_Active = true
    Shop3D_NPC = npcEnt
    Shop3D_IsBlackMarket = isBlackMarket
    Shop3D_ManualRot = 0
    Shop3D_TargetModelRot = 0
    Shop3D_CurrentModelRot = 0
    Shop3D_TargetCamZOffset = 0
    Shop3D_CurrentCamZOffset = 0
    Shop3D_Expanded = {}
    Shop3D_CurrentCategory = nil
    
    for _, mdlData in pairs(Shop3D_WeaponModels) do
        if IsValid(mdlData.ent) then mdlData.ent:Remove() end
    end
    Shop3D_WeaponModels = {}
    
    Shop3D_Categories = {
        ["Posesiones"] = { ["Armas para Vender"] = {} },
        ["Armas"] = {},
        ["Accesorios"] = {},
        ["Munición"] = {},
        ["Herramientas"] = {},
        ["Otros"] = {}
    }
    
    for id, item in pairs(SW_InvShop.Config.Items) do
        if item.isBaseItem then continue end
        
        -- Agregar a Posesiones si es un arma que el jugador posee
        local isOwned = (SW_InvShop.ActiveInv and SW_InvShop.ActiveInv[id] and SW_InvShop.ActiveInv[id] > 0) or (SW_InvShop.Armario and SW_InvShop.Armario[id] and SW_InvShop.Armario[id] > 0)
        local qty = 0
        if isOwned then
            qty = (SW_InvShop.ActiveInv and SW_InvShop.ActiveInv[id] or 0) + (SW_InvShop.Armario and SW_InvShop.Armario[id] or 0)
            if item.isWeapon then
                local t = table.Copy(item)
                t.id = id
                t.isSellable = true
                t.isOwned = true
                t.ownedQty = qty
                table.insert(Shop3D_Categories["Posesiones"]["Armas para Vender"], t)
            end
        end

        local isBM = item.isContraband or false
        if (isBlackMarket and isBM) or (not isBlackMarket and not isBM) then
            -- Filtrar por permisos del Job del jugador
            if not CanPlayerUseItem(LocalPlayer(), id) then
                continue
            end
            
            -- Si es accesorio, verificar compatibilidad y NO MOSTRAR si es incompatible
            if item.class == "bg_unlock" and not CanEquipAccessory(id) then
                continue
            end
            
            local cat = item.category or "General"
            local catLower = string.lower(cat)
            local mainCat = "Otros"
            
            if item.isAmmo or item.class == "sw_ammo" or string.find(catLower, "muni") then
                mainCat = "Munición"
            elseif item.isWeapon then
                mainCat = "Armas"
            elseif item.isTool or item.class == "sw_tool" or string.find(catLower, "herram") then
                mainCat = "Herramientas"
            elseif item.class == "bg_unlock" or string.find(catLower, "equip") or string.find(catLower, "accesorio") then
                mainCat = "Accesorios"
            else
                mainCat = "Otros"
            end
            
            if not Shop3D_Categories[mainCat][cat] then
                Shop3D_Categories[mainCat][cat] = {}
            end
            
            local t = table.Copy(item)
            t.id = id
            
            local isItemOwned = (SW_InvShop.ActiveInv and SW_InvShop.ActiveInv[id] and SW_InvShop.ActiveInv[id] > 0) or (SW_InvShop.Armario and SW_InvShop.Armario[id] and SW_InvShop.Armario[id] > 0)
            if isItemOwned and not item.isAmmo then
                t.isSellable = true
                t.isOwned = true
            end
            
            table.insert(Shop3D_Categories[mainCat][cat], t)
        end
    end
    
    if IsValid(Shop3D_Frame) then Shop3D_Frame:Remove() end
    
    Shop3D_Frame = vgui.Create("DFrame")
    Shop3D_Frame:SetSize(ScrW(), ScrH())
    Shop3D_Frame:Center()
    Shop3D_Frame:SetTitle("")
    Shop3D_Frame:ShowCloseButton(false)
    Shop3D_Frame:MakePopup()
    
    local function DrawKeyLegend(x, y, key, desc)
        surface.SetFont("SW_InvShop_Medium")
        local tw, th = surface.GetTextSize(key)
        local kw = tw + 20
        local kh = 26
        draw.RoundedBox(6, x, y - kh/2, kw, kh, Color(20, 25, 30, 240))
        draw.RoundedBox(6, x, y - kh/2 + kh - 4, kw, 4, Color(10, 15, 20, 250))
        draw.SimpleText(key, "SW_InvShop_Medium", x + kw/2, y - 2, color_white, 1, 1)
        draw.SimpleText(desc, "SW_InvShop_Medium", x + kw + 10, y - 1, Color(150, 150, 150), 0, 1)
        local dw, _ = surface.GetTextSize(desc)
        return kw + 10 + dw + 30
    end

    Shop3D_Frame.Paint = function(s, w, h)
        local y = h - 35
        -- Calculate total width to center it
        local tW = 0
        surface.SetFont("SW_InvShop_Medium")
        tW = tW + surface.GetTextSize("W / S") + 20 + 10 + surface.GetTextSize("NAVEGAR") + 30
        tW = tW + surface.GetTextSize("ENTER") + 20 + 10 + surface.GetTextSize("AVANZAR / ADQUIRIR / VENDER") + 30
        tW = tW + surface.GetTextSize("BACKSPACE") + 20 + 10 + surface.GetTextSize("VOLVER") + 30
        tW = tW + surface.GetTextSize("CLICK IZQ") + 20 + 10 + surface.GetTextSize("INSPECCIONAR")
        
        local cx = w/2 - tW/2
        
        draw.RoundedBox(12, cx - 30, y - 25, tW + 40, 50, Color(0, 0, 0, 200))
        surface.SetDrawColor(255, 180, 0, 80)
        surface.DrawOutlinedRect(cx - 30, y - 25, tW + 40, 50)
        
        cx = cx + DrawKeyLegend(cx, y, "W / S", "NAVEGAR")
        cx = cx + DrawKeyLegend(cx, y, "ENTER", "AVANZAR / ADQUIRIR / VENDER")
        cx = cx + DrawKeyLegend(cx, y, "BACKSPACE", "VOLVER")
        DrawKeyLegend(cx, y, "CLICK IZQ", "INSPECCIONAR")
    end
    
    local isDragging = false
    local lastMouseX, lastMouseY = 0, 0
    Shop3D_Frame.OnMousePressed = function(s, code)
        if code == MOUSE_LEFT then
            isDragging = true
            lastMouseX, lastMouseY = gui.MouseX(), gui.MouseY()
        end
    end
    Shop3D_Frame.OnMouseReleased = function(s, code)
        if code == MOUSE_LEFT then isDragging = false end
    end
    Shop3D_Frame.Think = function(s)
        if not LocalPlayer():Alive() then
            s:Close()
        elseif not Shop3D_Expanded["Accesorios"] then
            if not IsValid(Shop3D_NPC) or LocalPlayer():GetPos():DistToSqr(Shop3D_NPC:GetPos()) > 60000 then
                s:Close()
            end
        end
        if isDragging then
            local mx, my = gui.MouseX(), gui.MouseY()
            Shop3D_ManualRot = Shop3D_ManualRot + ((mx - lastMouseX) * 0.5)
            Shop3D_ManualRotPitch = math.Clamp(Shop3D_ManualRotPitch + ((my - lastMouseY) * 0.5), -180, 180)
            lastMouseX, lastMouseY = mx, my
        end

    end

    Shop3D_Frame.OnKeyCodePressed = function(s, key)
        if key == KEY_W or key == KEY_S or key == KEY_ENTER or key == KEY_BACKSPACE then
            if key == KEY_BACKSPACE then
                LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5)
                if IsValid(_G.Shop3D_InfoPanel) and _G.Shop3D_SelectedItem then
                    _G.Shop3D_SelectedItem = nil
                    if BuildList then BuildList() end
                elseif Shop3D_CurrentCategory then
                    Shop3D_CurrentCategory = nil
                    if BuildList then BuildList() end
                else
                    s:Close()
                end
                return
            end
            
            local scroll = nil
            if s.MenuPanel and s.MenuPanel.GetChildren then
                for _, child in ipairs(s.MenuPanel:GetChildren()) do
                    if child.GetCanvas then scroll = child; break end
                end
            end
            
            if IsValid(scroll) and scroll.GetCanvas then
                local btns = {}
                for _, p in ipairs(scroll:GetCanvas():GetChildren()) do
                    if p:IsVisible() and p:GetClassName() == "DButton" then
                        table.insert(btns, p)
                    end
                end
                
                if #btns > 0 then
                    s.NavIndex = s.NavIndex or 1
                    if key == KEY_W then
                        s.NavIndex = math.max(1, s.NavIndex - 1)
                        LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5)
                    elseif key == KEY_S then
                        s.NavIndex = math.min(#btns, s.NavIndex + 1)
                        LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5)
                    elseif key == KEY_ENTER then
                        if IsValid(_G.Shop3D_InfoPanel) and _G.Shop3D_SelectedItem then
                            local actBtn = nil
                            for _, child in ipairs(_G.Shop3D_InfoPanel:GetChildren()) do
                                if child:GetClassName() == "DButton" then actBtn = child; break end
                            end
                            if IsValid(actBtn) then actBtn:DoClick() end
                        elseif btns[s.NavIndex] then
                            btns[s.NavIndex]:DoClick()
                        end
                    end
                    
                    for i, b in ipairs(btns) do
                        b.IsNavSelected = (i == s.NavIndex)
                    end
                end
            end
        end
    end
    
    -- Panel lateral estilo esc_menu
    local MenuPanel = vgui.Create("DPanel", Shop3D_Frame)
    Shop3D_Frame.MenuPanel = MenuPanel
    MenuPanel:SetSize(310, 480)
    MenuPanel:SetPos(50, ScrH() * 0.12)
    MenuPanel.Paint = function(s, pw, ph)
        local c = Shop3D_IsBlackMarket and Color(255, 50, 50) or Color(0, 150, 255)
        local shopTitle = Shop3D_IsBlackMarket and "MERCADO NEGRO" or "TIENDA DE SUMINISTROS"
        
        draw.SimpleText(shopTitle, "SW_InvShop_BigTitle", 20, 20, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(shopTitle, "SW_InvShop_Aurebesh_Title", 20, 42, Color(150, 150, 150, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        surface.SetDrawColor(255, 180, 0, 150)
        surface.DrawRect(20, 50, 300, 2)
        
        local myCr = LocalPlayer().getDarkRPVar and LocalPlayer():getDarkRPVar("money") or 0
        local glowAlpha = 100 + math.sin(CurTime() * 4) * 50
        draw.SimpleText("SALDO:", "SW_InvShop_Medium", 20, 77, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("$ " .. string.Comma(myCr), "SW_InvShop_Aurebesh_Medium", 90, 77, Color(255, 200, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("$ " .. string.Comma(myCr), "SW_InvShop_Aurebesh_Medium", 90, 77, Color(255, 200, 0, glowAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        surface.SetDrawColor(255, 180, 0, 150)
        surface.DrawRect(20, 88, 150, 1)
    end
    
    
    btnBack = vgui.Create("DButton", MenuPanel)
    btnBack:SetText("")
    btnBack:Dock(BOTTOM)
    btnBack:DockMargin(10, 10, 10, 10)
    btnBack:SetTall(38)
    btnBack.Paint = function(s, w, h)
        s.HoverP = Lerp(FrameTime() * 15, s.HoverP or 0, s:IsHovered() and 1 or 0)
        if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
        
        draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
        if s.HoverP > 0.01 then
            draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
        end
        
        local tc = Lerp(s.HoverP, 255, 0)
        draw.SimpleText("SALIR DE LA TIENDA", "SW_InvShop_Medium", w/2, h/2, Color(tc, tc, tc), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnBack.DoClick = function()
        Shop3D_Frame:Close()
    end
    local btnBackCat = vgui.Create("DButton", MenuPanel)
    btnBackCat:SetText("")
    btnBackCat:Dock(BOTTOM)
    btnBackCat:DockMargin(10, 5, 10, 0)
    btnBackCat:SetTall(25)
    btnBackCat.HoverP = 0
    btnBackCat.Paint = function(s, w, h)
        s.HoverP = Lerp(FrameTime() * 12, s.HoverP, s:IsHovered() and 1 or 0)
        
        draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
        if s.HoverP > 0.01 then
            draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
        end
        
        local tc = Lerp(s.HoverP, 200, 0)
        draw.SimpleText("< VOLVER", "SW_InvShop_Medium", w/2, h/2, Color(tc, tc, tc), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnBackCat:SetVisible(false)

    local sepPanel = vgui.Create("DPanel", MenuPanel)
    sepPanel:Dock(BOTTOM)
    sepPanel:DockMargin(20, 10, 20, 10)
    sepPanel:SetTall(1)
    sepPanel.Paint = function(s, w, h)
        local c = Shop3D_IsBlackMarket and Color(255, 50, 50) or Color(0, 150, 255)
        surface.SetDrawColor(c.r, c.g, c.b, 50)
        surface.DrawRect(0, 0, w, h)
    end

    local Scroll = vgui.Create("DScrollPanel", MenuPanel)
    Scroll:Dock(FILL)
    Scroll:DockMargin(10, 95, 10, 0)
    
    local sbar = Scroll:GetVBar()
    sbar:SetWide(4)
    sbar:SetHideButtons(true)
    sbar.Paint = function() end
    sbar.btnGrip.Paint = function(s, w, h)
        local c = Shop3D_IsBlackMarket and Color(255, 50, 50, 150) or Color(255, 170, 0, 150)
        draw.RoundedBox(2, 0, 0, w, h, c)
    end

    local function SafeUpper(str)
        if not str then return "" end
        local s = string.gsub(str, "[a-z]", function(c) return string.char(string.byte(c) - 32) end)
        s = string.Replace(s, "á", "Á")
        s = string.Replace(s, "é", "É")
        s = string.Replace(s, "í", "Í")
        s = string.Replace(s, "ó", "Ó")
        s = string.Replace(s, "ú", "Ú")
        s = string.Replace(s, "ñ", "Ñ")
        return s
    end

        local btnBack
    local function BuildList()
        Scroll:Clear()
        
        local totalH = 0
        local order = {"Posesiones", "Armas", "Accesorios", "Munición", "Herramientas", "Otros"}
        
        if Shop3D_CurrentCategory then
            btnBackCat:SetVisible(true)
            btnBackCat.DoClick = function()
                LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                if _G.Shop3D_SelectedItem then
                    _G.Shop3D_SelectedItem = nil
                    if IsValid(_G.Shop3D_InfoPanel) then _G.Shop3D_InfoPanel:Remove() end
                    BuildList()
                    return
                end
                
                local prefix = Shop3D_CurrentCategory and (Shop3D_CurrentCategory .. "_") or ""
                local anySubExp = false
                for k, v in pairs(Shop3D_Expanded) do
                    if v and prefix ~= "" and string.sub(k, 1, #prefix) == prefix then anySubExp = true; break end
                end
                if anySubExp then
                    for k, v in pairs(Shop3D_Expanded) do
                        if string.sub(k, 1, #prefix) == prefix then Shop3D_Expanded[k] = nil end
                    end
                    BuildList()
                    return
                end
                
                Shop3D_CurrentCategory = nil
                Shop3D_Expanded = {}
                BuildList()
            end
            -- Renderizar Categoría principal fija
            local mainCat = Shop3D_CurrentCategory
            if not _G.Shop3D_SelectedItem then
                totalH = totalH + 49
                local btnMainHead = Scroll:Add("DPanel")
                btnMainHead:Dock(TOP)
                btnMainHead:DockMargin(5, 0, 5, 4)
                btnMainHead:SetTall(45)
                btnMainHead.Paint = function(s, w, h)
                    draw.RoundedBox(16, 0, 0, w, h, color_white)
                    draw.SimpleText(SafeUpper(mainCat), "SW_InvShop_Medium", 15, h/2, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end

            -- Renderizar subcategorías de la categoría actual
            local sortedSubKeys = table.GetKeys(Shop3D_Categories[mainCat])
            if mainCat == "Armas" then
                table.RemoveByValue(sortedSubKeys, "TODAS")
                if not Shop3D_Categories[mainCat]["TODAS"] then
                    local allWeps, seen = {}, {}
                    for k, v in pairs(Shop3D_Categories[mainCat]) do
                        for _, itm in ipairs(v) do
                            if not seen[itm.id] then seen[itm.id] = true; table.insert(allWeps, itm) end
                        end
                    end
                    Shop3D_Categories[mainCat]["TODAS"] = allWeps
                end
                table.sort(sortedSubKeys)
                table.insert(sortedSubKeys, 1, "TODAS")
            else
                table.sort(sortedSubKeys)
            end
            
            local anySubExpanded = false
            local prefix = mainCat .. "_"
            for k, v in pairs(Shop3D_Expanded) do
                if v and string.sub(k, 1, #prefix) == prefix then anySubExpanded = k; break end
            end
            
            for _, subCat in ipairs(sortedSubKeys) do
                local nodeID = mainCat .. "_" .. subCat
                if anySubExpanded and anySubExpanded ~= nodeID then continue end
                
                local hasSel = false
                if _G.Shop3D_SelectedItem then
                    for _, itm in ipairs(Shop3D_Categories[mainCat][subCat]) do
                        if itm.id == _G.Shop3D_SelectedItem then hasSel = true; break end
                    end
                    if not hasSel then continue end
                end
                
                if not _G.Shop3D_SelectedItem then
                    local btnSub = Scroll:Add("DButton")
                btnSub:SetText("")
                btnSub:Dock(TOP)
                btnSub:DockMargin(10, 2, 10, 2)
                btnSub:SetTall(35)
                btnSub.HoverP = 0
                btnSub.Paint = function(s, w, h)
                    local isActive = Shop3D_Expanded[nodeID]
                    s.HoverP = Lerp(FrameTime() * 15, s.HoverP, (s:IsHovered() or isActive or s.IsNavSelected) and 1 or 0)
                    if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                    draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                    if s.HoverP > 0.01 then
                        draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
                    end
                    local tc = Lerp(s.HoverP, 200, 0)
                    local txtColor = Color(tc, tc, tc)
                    draw.SimpleText(SafeUpper(subCat), "SW_InvShop_Medium", 20, h/2 - 6, txtColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(SafeUpper(subCat), "SW_InvShop_Aurebesh_ExtraSmall", 20, h/2 + 8, Color(tc, tc, tc, 100 + s.HoverP * 155), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    
                    local cx, cy = 10, h/2
                    surface.SetDrawColor(txtColor)
                    if isActive then
                        
                        
                    else
                        
                        
                    end
                end
                btnSub.DoClick = function()
                    LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                    Shop3D_Expanded[nodeID] = not Shop3D_Expanded[nodeID]
                    BuildList()
                end
                
                end
                
                if not _G.Shop3D_SelectedItem then
                    totalH = totalH + 39
                end
                
                if _G.Shop3D_SelectedItem or Shop3D_Expanded[nodeID] then
                    local items = Shop3D_Categories[mainCat][subCat]
                    table.SortByMember(items, "price", true)
                    
                    for _, itm in ipairs(items) do
                        if _G.Shop3D_SelectedItem and _G.Shop3D_SelectedItem ~= itm.id then continue end
                        local btnItm = Scroll:Add("DButton")
                        btnItm:SetText("")
                        btnItm:Dock(TOP)
                        btnItm:DockMargin(15, 0, 15, 4)
                        btnItm:SetTall(55)
                        btnItm.HoverP = 0
                        
                        totalH = totalH + 59
                        
                        local function GetIsOwned(id) return (SW_InvShop.ActiveInv and SW_InvShop.ActiveInv[id] and SW_InvShop.ActiveInv[id] > 0) or (SW_InvShop.Armario and SW_InvShop.Armario[id] and SW_InvShop.Armario[id] > 0) end

                        
                        btnItm.Paint = function(s, w, h)
                            local isItemSel = (_G.Shop3D_SelectedItem == itm.id)
                            s.HoverP = Lerp(FrameTime() * 15, s.HoverP, (s:IsHovered() or isItemSel or s.IsNavSelected) and 1 or 0)
                            if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                            local isO = GetIsOwned(itm.id) and not itm.isAmmo
                            local c = isO and Color(255, 180, 0) or (Shop3D_IsBlackMarket and Color(255, 50, 50) or Color(0, 150, 255))
                            if s.IsConfirming then c = Color(255, 100, 0) end
                            
                            draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                            
                            if s.IsConfirming then draw.RoundedBox(16, 0, 0, w, h, Color(c.r, c.g, c.b, 60)) end
                            
                            if s.HoverP > 0.01 then
                                draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
                            end
                            
                            local tc = Lerp(s.HoverP, 200, 0)
                            local nameColor = Color(tc, tc, tc)
                            if not itm.isWeapon then
                                draw.SimpleText(itm.name, "SW_InvShop_Medium", 10, h/2 - 6, nameColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                                draw.SimpleText(itm.name, "SW_InvShop_Aurebesh_ExtraSmall", 10, h/2 + 7, Color(tc, tc, tc, 100 + s.HoverP * 155), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            else
                                draw.SimpleText(itm.name, "SW_InvShop_Medium", 10, h/2, nameColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            end
                            
                            if not isO then
                                local dCostStr = itm.price > 0 and ("$ " .. string.Comma(itm.price)) or "GRATIS"
                                local glowAlpha = 100 + math.sin(CurTime() * 4) * 50
                                local priceC = Color(255, 170, 0)
                                if s.HoverP > 0.5 then priceC = color_black end
                                draw.SimpleText(dCostStr, "SW_InvShop_Aurebesh_Medium", w - 10, h/2, priceC, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                                if s.HoverP <= 0.5 then
                                    draw.SimpleText(dCostStr, "SW_InvShop_Aurebesh_Medium", w - 10, h/2, Color(255, 170, 0, glowAlpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                                end
                            else
                                local eqC = Color(46, 204, 113, 150)
                                if s.HoverP > 0.5 then eqC = color_black end
                                draw.SimpleText("EQUIPADO", "SW_InvShop_Aurebesh_Medium", w - 10, h/2, eqC, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                            end
                        end
                        
                        btnItm.OnCursorEntered = function()
                            LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5)
                            CreateWeaponModel(itm)
                        end
                        
                        btnItm.DoClick = function(s, bIsRebuild)
                            if not bIsRebuild then LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5) end
                            if IsValid(_G.Shop3D_InfoPanel) then _G.Shop3D_InfoPanel:Remove() end
                            
                            if not bIsRebuild then
                                _G.Shop3D_SelectedItem = itm.id
                                timer.Simple(0, function()
                                    if IsValid(MenuPanel) then BuildList() end
                                end)
                            end
                            
                            _G.Shop3D_InfoPanel = vgui.Create("DPanel", Shop3D_Frame)
                            local ip = _G.Shop3D_InfoPanel
                            ip:SetSize(400, 230)
                            
                            local dmg, clip, rpm, recoil = 0, 0, 0, 0
                            local wepTable = weapons.Get(itm.class) or weapons.GetStored(itm.class)
                            local isWep = false
                            if wepTable and wepTable.Primary then
                                isWep = true
                                dmg = wepTable.Primary.Damage or 0
                                clip = wepTable.Primary.ClipSize or 0
                                local delay = wepTable.Primary.Delay or 0
                                rpm = wepTable.Primary.RPM or 0
                                if delay > 0 and rpm == 0 then rpm = math.Round(60 / delay) end
                                recoil = wepTable.Primary.Recoil or 0
                            end
                            
                            ip.Think = function(s)
                                if not IsValid(MenuPanel) then s:Remove() return end
                                local targetY = MenuPanel:GetY() + MenuPanel:GetTall() + 10
                                s.curY = Lerp(FrameTime() * 15, s.curY or targetY, targetY)
                                s:SetPos(50, s.curY)
                            end
                            
                            ip.Paint = function(s, w, h)
                                draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 150))
                                local isO = GetIsOwned(itm.id) and not itm.isAmmo
                                local c = isO and Color(255, 180, 0) or (Shop3D_IsBlackMarket and Color(255, 50, 50) or Color(0, 150, 255))
                                
                                surface.SetDrawColor(255, 180, 0, 150)
                                surface.DrawRect(15, 65, w - 30, 1)
                                
                                local costStr = ""
                                if isO then
                                    costStr = "EQUIPADO"
                                else
                                    costStr = itm.price > 0 and ("$ " .. string.Comma(itm.price)) or "GRATIS"
                                end
                                
                                draw.SimpleText(SafeUpper(itm.name), "SW_InvShop_Header", 20, 20, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                                
                                local typeStr = ""
                                if itm.desc then
                                    typeStr = string.match(itm.desc, "Tipo:%s*([^\n]+)") or ""
                                end
                                if typeStr ~= "" then
                                    draw.SimpleText(SafeUpper(typeStr), "SW_InvShop_Small", w - 20, 20, Color(150, 150, 150), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                                end
                                
                                local priceCol = isO and Color(255, 180, 0) or Color(255, 170, 0)
                                
                                if not isO then
                                    draw.SimpleText("PRECIO:", "SW_InvShop_Small", 20, 48, Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                                end
                                
                                local glowAlpha = 100 + math.sin(CurTime() * 4) * 50
                                draw.SimpleText(costStr, "SW_InvShop_Aurebesh_Medium", isO and 20 or 75, 48, priceCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                                draw.SimpleText(costStr, "SW_InvShop_Aurebesh_Medium", isO and 20 or 75, 48, Color(priceCol.r, priceCol.g, priceCol.b, glowAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                                
                                surface.SetDrawColor(c.r, c.g, c.b, 50)
                                surface.DrawRect(20, 65, w - 40, 1)
                                
                                if isWep then
                                    local statY = 85
                                    local function drawStat(name, val, maxVal, yPos)
                                        draw.SimpleText(name, "SW_InvShop_Small", 20, yPos, Color(180, 180, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                                        local barW = w - 150
                                        local fill = math.Clamp(val / maxVal, 0, 1)
                                        
                                        surface.SetDrawColor(0, 0, 0, 180)
                                        surface.DrawRect(110, yPos - 3, barW, 6)
                                        
                                        surface.SetDrawColor(c.r, c.g, c.b, 200)
                                        surface.DrawRect(110, yPos - 3, barW * fill, 6)
                                        
                                        surface.SetDrawColor(c.r, c.g, c.b, 100)
                                        surface.DrawOutlinedRect(110, yPos - 3, barW, 6)
                                    end
                                    drawStat("DAÑO", dmg, 100, statY)
                                    drawStat("CADENCIA", rpm, 1000, statY + 22)
                                    drawStat("CAPACIDAD", clip, 100, statY + 44)
                                    drawStat("PRECISIÓN", math.max(0, 5 - recoil), 5, statY + 66)
                                else
                                    draw.SimpleText("Estadísticas no aplicables", "SW_InvShop_Medium", w/2, 115, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                                end
                            end
                            
                            local btnAct = vgui.Create("DButton", ip)
                            btnAct:SetSize(ip:GetWide() - 40, 35)
                            btnAct:SetPos(20, ip:GetTall() - 45)
                            btnAct:SetText("")
                            btnAct.HoverP = 0
                            btnAct.Paint = function(s, bw, bh)
                                s.HoverP = Lerp(FrameTime() * 15, s.HoverP, s:IsHovered() and 1 or 0)
                            if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                                local isO = GetIsOwned(itm.id) and not itm.isAmmo
                                local c = isO and Color(255, 50, 50) or Color(255, 255, 255)
                                
                                if s.HoverP > 0.01 then
                                    draw.RoundedBox(16, 0, 0, bw, bh, Color(c.r, c.g, c.b, s.HoverP * 255))
                                end
                                
                                local actionTxt = isO and "VENDER ARTÍCULO" or "ADQUIRIR ARTÍCULO"
                                local tc = Lerp(s.HoverP, 200, 0)
                                local nameColor = isO and (s:IsHovered() and color_white or Color(255, 100, 100)) or Color(tc, tc, tc)
                                draw.SimpleText(actionTxt, "SW_InvShop_Medium", bw/2, bh/2, nameColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            end
                            
                            btnAct.DoClick = function()
                                LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                                local isO = GetIsOwned(itm.id) and not itm.isAmmo
                                if isO then
                                    net.Start("SW_SellItem")
                                    net.WriteString(itm.id)
                                    net.SendToServer()
                                    if IsValid(Shop3D_Frame) then Shop3D_Frame:Close() end
                                else
                                    net.Start("SW_BuyItem")
                                    net.WriteString(itm.id)
                                    net.SendToServer()
                                    if IsValid(_G.Shop3D_InfoPanel) then _G.Shop3D_InfoPanel:Remove() end
                                end
                            end
                        end
                        if _G.Shop3D_SelectedItem == itm.id then
                            timer.Simple(0, function() if IsValid(btnItm) then btnItm:DoClick(true) end end)
                        end
                        
                    end
                end
            end
        else            btnBackCat:SetVisible(false)

            -- Renderizar lista principal
            for _, mainCat in ipairs(order) do
                if not Shop3D_Categories[mainCat] or table.Count(Shop3D_Categories[mainCat]) == 0 then continue end
                
                if mainCat == "Posesiones" then
                    local hasAny = false
                    for _, subItems in pairs(Shop3D_Categories[mainCat]) do
                        if #subItems > 0 then hasAny = true; break end
                    end
                    if not hasAny then continue end
                end
                
                totalH = totalH + 49
                
                local btnMain = Scroll:Add("DButton")
                btnMain:SetText("")
                btnMain:Dock(TOP)
                btnMain:DockMargin(5, 0, 5, 4)
                btnMain:SetTall(45)
                btnMain.HoverP = 0
                btnMain.Paint = function(s, w, h)
                    s.HoverP = Lerp(FrameTime() * 12, s.HoverP, (s:IsHovered() or s.IsNavSelected) and 1 or 0)
                    if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                    draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                    if s.HoverP > 0.01 then
                        draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
                    end
                    local tc = Lerp(s.HoverP, 255, 0)
                    local c = Shop3D_IsBlackMarket and Color(255, 50, 50) or Color(0, 150, 255)
                    
                    draw.SimpleText(SafeUpper(mainCat), "SW_InvShop_Medium", 15, h/2 - 6, Color(tc, tc, tc), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(SafeUpper(mainCat), "SW_InvShop_Aurebesh_ExtraSmall", 15, h/2 + 8, Color(tc, tc, tc, 100 + s.HoverP * 155), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    
                    local cx, cy = w - 20, h/2
                    
                    
                end
                btnMain.DoClick = function()
                    LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                    Shop3D_CurrentCategory = mainCat
                    Shop3D_Expanded = {}
                    Shop3D_Expanded[mainCat] = true
                    BuildList()
                end
            end
        end
        
        -- Redimensionar dinámicamente el panel según el alto calculado
        local baseH = 175
        if Shop3D_CurrentCategory then baseH = 205 end
        local maxH = ScrH() * 0.9
        local targetH = math.min(maxH, baseH + totalH)
        MenuPanel:SizeTo(310, targetH, 0.2, 0, -1)
    end
    

    
    BuildList()
    
    Shop3D_Frame.OnClose = function()
        _G.SW_Shop3D_Active = false
        for _, mdlData in pairs(Shop3D_WeaponModels) do
            if IsValid(mdlData.ent) then mdlData.ent:Remove() end
        end
        Shop3D_WeaponModels = {}
        if IsValid(_G.Shop3D_InfoPanel) then _G.Shop3D_InfoPanel:Remove() end
    end
end

local curCamPos, curCamAng

hook.Add("CalcView", "SW_Shop3DView", function(ply, pos, angles, fov)
    if not _G.SW_Shop3D_Active then 
        curCamPos = nil
        curCamAng = nil
        return 
    end
    
    if not IsValid(Shop3D_NPC) then
        _G.SW_Shop3D_Active = false
        if IsValid(Shop3D_Frame) then Shop3D_Frame:Close() end
        return
    end

    local targetCamPos, targetCamAng
    
    -- Lerp the Z offset for head/back tracking
    Shop3D_CurrentCamZOffset = Lerp(FrameTime() * 5, Shop3D_CurrentCamZOffset, Shop3D_TargetCamZOffset)
    
    local isAnyExpanded = false
    local isAccesorios = false
    for cat, exp in pairs(Shop3D_Expanded) do
        if exp and (cat == "Armas" or cat == "Accesorios" or cat == "Munición" or cat == "Herramientas" or cat == "Otros") then
            isAnyExpanded = true
            if cat == "Accesorios" then isAccesorios = true end
            break
        end
    end
    
    if not isAnyExpanded then
        -- Mostrar al NPC
        local npcPos = Shop3D_NPC:GetPos() + Vector(0,0,50)
        local npcAng = Shop3D_NPC:GetAngles()
        local forward = npcAng:Forward()
        local right = npcAng:Right()
        targetCamPos = npcPos + forward * 80 + right * 20
        targetCamAng = (npcPos - targetCamPos):Angle()
    elseif isAccesorios then
        local tPos = Vector(SW_InvShop.Config3D_PlayerPos.x, SW_InvShop.Config3D_PlayerPos.y, LocalPlayer():GetPos().z)
        local tAng = SW_InvShop.Config3D_PlayerAng
        local offset = SW_InvShop.Config3D_PlayerCamOffset
        local forward = tAng:Forward()
        local right = tAng:Right()
        local up = tAng:Up()
        local basePos = tPos + Vector(0, 0, 45 + Shop3D_CurrentCamZOffset)
        
        -- Si estamos mirando la espalda, la cámara pivota y se acerca
        local isBack = (Shop3D_TargetModelRot > 90)
        local isHead = (Shop3D_TargetCamZOffset == 10)
        local finalOffset = offset
        if isBack then
            finalOffset = Vector(offset.x * 0.8, offset.y, offset.z)
        elseif isHead then
            finalOffset = Vector(offset.x * 0.5, offset.y, offset.z)
        end
        
        targetCamPos = basePos + (forward * finalOffset.x) + (right * finalOffset.y) + (up * finalOffset.z)
        targetCamAng = (basePos - targetCamPos):Angle()
    else
        -- Mostrar la mesa de armas
        local tPos = SW_InvShop.Config3D_WeaponPos
        local tAng = SW_InvShop.Config3D_WeaponAng
        local offset = SW_InvShop.Config3D_WeaponCamOffset
        local forward = tAng:Forward()
        local right = tAng:Right()
        local up = tAng:Up()
        targetCamPos = tPos + (forward * offset.x) + (right * offset.y) + (up * offset.z)
        targetCamAng = (tPos - targetCamPos):Angle()
    end
    
    if not curCamPos or curCamPos:DistToSqr(targetCamPos) > 4000000 then
        curCamPos = pos
        curCamAng = angles
    end
    
    curCamPos = LerpVector(FrameTime() * 4, curCamPos, targetCamPos)
    curCamAng = LerpAngle(FrameTime() * 4, curCamAng, targetCamAng)
    
    return {
        origin = curCamPos,
        angles = curCamAng,
        fov = 65,
        drawviewer = true
    }
end)

hook.Add("PostDrawOpaqueRenderables", "SW_Shop3DModel", function()
    if not _G.SW_Shop3D_Active or not IsValid(Shop3D_NPC) then return end
    
    Shop3D_CurrentModelRot = Lerp(FrameTime() * 5, Shop3D_CurrentModelRot, Shop3D_TargetModelRot)
    
    for _, mdlData in ipairs(Shop3D_WeaponModels) do
        if IsValid(mdlData.ent) then
            local targetPos, targetAng
            if mdlData.isBG then
                targetPos = Vector(SW_InvShop.Config3D_PlayerPos.x, SW_InvShop.Config3D_PlayerPos.y, LocalPlayer():GetPos().z)
                targetAng = Angle(0, SW_InvShop.Config3D_PlayerAng.y + Shop3D_CurrentModelRot - Shop3D_ManualRot, 0)
            else
                targetPos = SW_InvShop.Config3D_WeaponPos
                targetAng = Angle(Shop3D_ManualRotPitch, SW_InvShop.Config3D_WeaponAng.y - Shop3D_ManualRot, 0)
            end
            
            local m = Matrix()
            m:Translate(targetPos)
            m:Rotate(targetAng)
            m:Translate(-Shop3D_WeaponCenterOffset)
            
            mdlData.ent:SetPos(m:GetTranslation())
            mdlData.ent:SetAngles(m:GetAngles())
            mdlData.ent:SetupBones()
            
            if mdlData.isBase then mdlData.ent:FrameAdvance(FrameTime()) end
            
            mdlData.ent:DrawModel()
        end
    end
end)

hook.Add("HUDShouldDraw", "SW_Shop3D_HideHUD", function(name)
    if _G.SW_Shop3D_Active then return false end
end)

hook.Add("PrePlayerDraw", "SW_Shop3D_HidePlayers", function(ply)
    if _G.SW_Shop3D_Active then
        return true
    end
end)

local shop_hidden_weps = {}
hook.Add("Think", "SW_Shop3D_HideWeapons_Think", function()
    if _G.SW_Shop3D_Active then
        for _, ply in ipairs(player.GetAll()) do
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and not wep:GetNoDraw() then
                wep:SetNoDraw(true)
                shop_hidden_weps[wep] = true
            end
        end
    else
        for wep, _ in pairs(shop_hidden_weps) do
            if IsValid(wep) then
                wep:SetNoDraw(false)
            end
            shop_hidden_weps[wep] = nil
        end
    end
end)
