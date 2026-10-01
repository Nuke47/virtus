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
hook.Add("InitPostEntity", "SW_Armario_ReloadAurebeshFonts", function()
    surface.CreateFont("SW_InvShop_Aurebesh_ExtraSmall", { font = "VirtusBe", size = 9,  weight = 500, antialias = true })
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

_G.SW_Armario3D_Active = false
local Armario3D_NPC = NULL
local Armario3D_IsBlackMarket = false
local Armario3D_Frame = NULL

-- Rotación manual y enfoque dinámico
local Armario3D_ManualRot = 0
local Armario3D_ManualRotPitch = 0
local Armario3D_TargetModelRot = 0
local Armario3D_CurrentModelRot = 0
local Armario3D_TargetCamZOffset = 0
local Armario3D_CurrentCamZOffset = 0
local Armario3D_WeaponCenterOffset = Vector(0,0,0)

local Armario3D_Categories = {}
local Armario3D_WeaponModel = NULL

-- Estado de expansión del menú (Categorías y Subcategorías)
local Armario3D_Expanded = {}

-- Fuentes
surface.CreateFont("SW_Aurebesh_Money", { font = "VirtusBe", size = 26, weight = 500, antialias = true })
local function SafeUpper(str)
    if not str then return "" end
    local s = string.upper(str)
    s = string.Replace(s, "á", "A")
    s = string.Replace(s, "é", "E")
    s = string.Replace(s, "í", "I")
    s = string.Replace(s, "ó", "O")
    s = string.Replace(s, "ú", "U")
    s = string.Replace(s, "Á", "A")
    s = string.Replace(s, "É", "E")
    s = string.Replace(s, "Í", "I")
    s = string.Replace(s, "Ó", "O")
    s = string.Replace(s, "Ú", "U")
    s = string.Replace(s, "ñ", "Ñ")
    s = string.Replace(s, "Ñ", "Ñ")
    return s
end

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

local Armario3D_WeaponModels = {}

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
    for _, mdlData in pairs(Armario3D_WeaponModels) do
        if IsValid(mdlData.ent) then mdlData.ent:Remove() end
    end
    Armario3D_WeaponModels = {}
    
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
        Armario3D_TargetModelRot = 180
        Armario3D_TargetCamZOffset = 5
    elseif string.find(iname, "macrobinocular") or string.find(iname, "range finder") or string.find(iname, "casco") or string.find(iname, "visor") or string.find(iname, "head") then
        Armario3D_TargetModelRot = 0
        Armario3D_TargetCamZOffset = 20
    else
        Armario3D_TargetModelRot = 0
        Armario3D_TargetCamZOffset = 0
    end
    Armario3D_ManualRotPitch = 0
    
    Armario3D_WeaponCenterOffset = Vector(0,0,0)
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
                Armario3D_WeaponCenterOffset = (min + max) / 2
            end
        end
        table.insert(Armario3D_WeaponModels, { ent = mdl, isBase = true })
    end
end


function SW_InvShop:Open3DArmario(armarioEnt)
    _G.SW_Armario3D_Active = true
    Armario3D_Ent = armarioEnt
    Armario3D_ManualRot = 0
    Armario3D_TargetModelRot = 0
    Armario3D_CurrentModelRot = 0
    Armario3D_TargetCamZOffset = 0
    Armario3D_CurrentCamZOffset = 0
    Armario3D_Expanded = {}
    Armario3D_CurrentCategory = nil
    
    for _, mdlData in pairs(Armario3D_WeaponModels) do
        if IsValid(mdlData.ent) then mdlData.ent:Remove() end
    end
    Armario3D_WeaponModels = {}
    Armario3D_Expanded["vestimenta"] = true
    CreateWeaponModel({class = "bg_unlock", name = "fullbody"})
    
    if IsValid(Armario3D_Frame) then Armario3D_Frame:Remove() end
    
    Armario3D_Frame = vgui.Create("DFrame")
    Armario3D_Frame:SetSize(ScrW(), ScrH())
    Armario3D_Frame:MakePopup()
    Armario3D_Frame:SetTitle("")
    Armario3D_Frame:SetDraggable(false)
    Armario3D_Frame:ShowCloseButton(false)
    
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

    Armario3D_Frame.Paint = function(self, w, h)
        local y = h - 35
        local tW = 0
        surface.SetFont("SW_InvShop_Medium")
        tW = tW + surface.GetTextSize("W / S") + 20 + 10 + surface.GetTextSize("NAVEGAR") + 30
        tW = tW + surface.GetTextSize("ENTER") + 20 + 10 + surface.GetTextSize("AVANZAR / EQUIPAR") + 30
        tW = tW + surface.GetTextSize("BACKSPACE") + 20 + 10 + surface.GetTextSize("VOLVER") + 30
        tW = tW + surface.GetTextSize("CLICK IZQ") + 20 + 10 + surface.GetTextSize("INSPECCIONAR")
        
        local cx = w/2 - tW/2
        
        draw.RoundedBox(12, cx - 30, y - 25, tW + 40, 50, Color(0, 0, 0, 200))
        surface.SetDrawColor(255, 180, 0, 80)
        surface.DrawOutlinedRect(cx - 30, y - 25, tW + 40, 50)
        
        cx = cx + DrawKeyLegend(cx, y, "W / S", "NAVEGAR")
        cx = cx + DrawKeyLegend(cx, y, "ENTER", "AVANZAR / EQUIPAR")
        cx = cx + DrawKeyLegend(cx, y, "BACKSPACE", "VOLVER")
        DrawKeyLegend(cx, y, "CLICK IZQ", "INSPECCIONAR")
    end

    Armario3D_Frame.OnKeyCodePressed = function(s, key)
        if key == KEY_W or key == KEY_S or key == KEY_ENTER or key == KEY_BACKSPACE then
            if key == KEY_BACKSPACE then
                LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5)
                if IsValid(_G.Armario3D_InfoPanel) and _G.Armario3D_SelectedItem then
                    _G.Armario3D_SelectedItem = nil
                    if BuildList then BuildList() end
                elseif Armario3D_CurrentCategory then
                    Armario3D_CurrentCategory = nil
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
                        if IsValid(_G.Armario3D_InfoPanel) and _G.Armario3D_SelectedItem then
                            local actBtn = nil
                            for _, child in ipairs(_G.Armario3D_InfoPanel:GetChildren()) do
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
    
    local MenuPanel = vgui.Create("DPanel", Armario3D_Frame)
    Armario3D_Frame.MenuPanel = MenuPanel
    MenuPanel:SetSize(310, 480)
    MenuPanel:SetPos(50, ScrH() * 0.12)
    MenuPanel.Paint = function(s, w, h)
        local c = Color(255, 180, 0)
    end
    
    local Header = vgui.Create("DPanel", MenuPanel)
    Header:Dock(TOP)
    Header:SetTall(60)
    Header:DockMargin(15, 15, 15, 5)
    Header.Paint = function(s, w, h)
        local plyName = LocalPlayer():Nick() or "Soldado"
        local armTitle = "ARMARIO PERSONAL"
        
        draw.SimpleText(armTitle, "SW_InvShop_BigTitle", 10, 20, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(armTitle, "SW_InvShop_Aurebesh_Title", 10, 42, Color(150, 150, 150, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        surface.SetDrawColor(255, 180, 0, 150)
        surface.DrawRect(10, 50, 300, 2)
    end
    
    local btnBack = vgui.Create("DButton", MenuPanel)
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
        draw.SimpleText("CERRAR ARMARIO", "SW_InvShop_Medium", w/2, h/2, Color(tc, tc, tc), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnBack.DoClick = function()
        Armario3D_Frame:Close()
    end
    local btnBackCat = vgui.Create("DButton", MenuPanel)
    btnBackCat:SetText("")
    btnBackCat:Dock(BOTTOM)
    btnBackCat:DockMargin(10, 5, 10, 0)
    btnBackCat:SetTall(40)
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

    -- Separator line between category list and exit button
    local sepPanel = vgui.Create("DPanel", MenuPanel)
    sepPanel:Dock(BOTTOM)
    sepPanel:DockMargin(20, 5, 20, 5)
    sepPanel:SetTall(1)
    sepPanel.Paint = function(s, w, h)
        surface.SetDrawColor(255, 255, 255, 20)
        surface.DrawRect(0, 0, w, h)
    end

    local Scroll = vgui.Create("DScrollPanel", MenuPanel)
    Scroll:Dock(FILL)
    Scroll:DockMargin(10, 5, 10, 5)
    
    local sbar = Scroll:GetVBar()
    sbar:SetWide(4)
    sbar:SetHideButtons(true)
    sbar.Paint = function() end
    sbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(2, 0, 0, w, h, Color(255, 255, 255, 10))
    end
    

local function BuildList()
        Scroll:Clear()
        if IsValid(_G.Armario3D_RightPanel) then _G.Armario3D_RightPanel:Remove() end
        local totalH = 0
        local hasAccessories = false
        if SW_InvShop and SW_InvShop.Config and SW_InvShop.Config.Items then
            for itemID, qty in pairs(SW_InvShop.ActiveInv or {}) do
                local itm = SW_InvShop.Config.Items[itemID]
                if itm and itm.class == "bg_unlock" and qty > 0 then hasAccessories = true break end
            end
            if not hasAccessories then
                for itemID, qty in pairs(SW_InvShop.Armario or {}) do
                    local itm = SW_InvShop.Config.Items[itemID]
                    if itm and itm.class == "bg_unlock" and qty > 0 then hasAccessories = true break end
                end
            end
        end

        local mainCats = {
            { id = "active", name = "Equipamiento" },
            { id = "armario", name = "Baúl de Armas" }
        }
        if hasAccessories then
            table.insert(mainCats, { id = "accesorios", name = "Accesorios" })
        end
        table.insert(mainCats, { id = "vestimenta", name = "Vestimenta (Bodygroups)" })
        
        if Armario3D_CurrentCategory then
            btnBackCat:SetVisible(true)
            btnBackCat.DoClick = function()
                LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                if _G.Armario3D_SelectedItem then
                    _G.Armario3D_SelectedItem = nil
                    if IsValid(_G.Armario3D_InfoPanel) then _G.Armario3D_InfoPanel:Remove() end
                    BuildList()
                    return
                end
                Armario3D_CurrentCategory = nil
                Armario3D_Expanded = {}
                for _, mdlData in pairs(Armario3D_WeaponModels) do
                    if IsValid(mdlData.ent) then mdlData.ent:Remove() end
                end
                Armario3D_WeaponModels = {}
                Armario3D_Expanded["vestimenta"] = true
                CreateWeaponModel({class = "bg_unlock", name = "fullbody"})
                if IsValid(_G.Armario3D_InfoPanel) then _G.Armario3D_InfoPanel:Remove() end
                BuildList()
            end

            local mainCat = Armario3D_CurrentCategory
            local catName = "Categoría"
            for _, v in ipairs(mainCats) do if v.id == mainCat then catName = v.name break end end
            if not _G.Armario3D_SelectedItem then
                totalH = totalH + 49
                
                local btnMainHead = Scroll:Add("DPanel")
                btnMainHead:Dock(TOP)
                btnMainHead:DockMargin(5, 0, 5, 4)
                btnMainHead:SetTall(45)
                btnMainHead.Paint = function(s, w, h)
                    draw.RoundedBox(16, 0, 0, w, h, color_white)
                    draw.SimpleText(SafeUpper(catName), "SW_InvShop_Medium", 15, h/2 - 6, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(SafeUpper(catName), "SW_InvShop_Aurebesh_ExtraSmall", 15, h/2 + 8, Color(0, 0, 0, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end
            if mainCat == "active" then
                local actWeps, actAccs, actAmmo = {}, {}, {}
                local hasMochila = false
                for itemID, qty in pairs(SW_InvShop.ActiveInv or {}) do
                    if qty > 0 and SW_InvShop.Config.Items[itemID] then
                        local itm = SW_InvShop.Config.Items[itemID]
                        if itm.isAmmo then table.insert(actAmmo, {id=itemID, data=itm})
                        elseif not itm.isWeapon or itm.class == "bg_unlock" then table.insert(actAccs, {id=itemID, data=itm}) if string.find(string.lower(itm.name), "mochila") then hasMochila = true end
                        else table.insert(actWeps, {id=itemID, data=itm}) end
                    end
                end
                local slots = {
                    { name = "ARMA PRINCIPAL", item = nil },
                    { name = "ARMA SECUNDARIA", item = nil },
                    { name = "ARMA ESPECIAL", item = nil }
                }
                for _, w in ipairs(actWeps) do
                    local slotIdx = SW_InvShop.GetItemSlot(w.id)
                    if slotIdx == 1 and not slots[1].item then slots[1].item = w
                    elseif slotIdx == 3 and not slots[2].item then slots[2].item = w
                    elseif slotIdx == 2 and not slots[3].item then slots[3].item = w end
                end
                -- Accessories removed from right panel entirely as requested
                local totalRightH = 65 + 15 + 15 + (#slots * 75) + (hasMochila and 50 or 0)
                _G.Armario3D_RightPanel = vgui.Create("DPanel", Armario3D_Frame)
                local rp = _G.Armario3D_RightPanel
                rp:SetSize(400, totalRightH)
                rp:SetPos(ScrW() - 450, ScrH() / 2 - totalRightH / 2)
                rp.Paint = function(s, w, h)
                    draw.SimpleText("EQUIPAMIENTO", "SW_InvShop_Header", w - 20, 25, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    surface.SetDrawColor(255, 180, 0, 150)
                    surface.DrawRect(20, 55, w - 40, 2)
                end
                local rScroll = vgui.Create("DScrollPanel", rp)
                rScroll:Dock(FILL)
                rScroll:DockMargin(15, 65, 15, 15)
                for i, sData in ipairs(slots) do
                    local sp = rScroll:Add("DPanel")
                    sp:Dock(TOP)
                    sp:DockMargin(0, 0, 0, 15)
                    sp:SetTall(60)
                    sp.Paint = function(s, w, h)
                        draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                        draw.SimpleText(sData.name, "SW_InvShop_Small", 15, 10, Color(150,150,150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        if sData.item then
                            draw.SimpleText(SafeUpper(sData.item.data.name), "SW_InvShop_Medium", 15, 28, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        else
                            draw.SimpleText("VACIO", "SW_InvShop_Medium", 15, 28, Color(255,255,255,30), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        end
                    end
                    if sData.item then
                        local btnUnequip = vgui.Create("DButton", sp)
                        btnUnequip:SetText("")
                        btnUnequip:Dock(RIGHT)
                        btnUnequip:DockMargin(10, 10, 10, 10)
                        btnUnequip:SetWide(120)
                        btnUnequip.Paint = function(s, w, h)
                            s.HoverP = Lerp(FrameTime() * 15, s.HoverP or 0, s:IsHovered() and 1 or 0)
        if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                            if s.HoverP > 0.01 then
                                draw.RoundedBox(16, 0, 0, w, h, Color(255, 50, 50, s.HoverP * 255))
                            end
                            local tc = Lerp(s.HoverP, 255, 0)
                            local cT = s:IsHovered() and color_white or Color(255, 100, 100)
                            draw.SimpleText("DESEQUIPAR", "SW_InvShop_Small", w/2, h/2, cT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        end
                        btnUnequip.DoClick = function()
                            LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                            net.Start("SW_MoveItem")
                            net.WriteString(sData.item.id)
                            net.WriteString("armario")
                            net.SendToServer()
                        end
                    end
                end
                if hasMochila then
                    local btnInv = rScroll:Add("DButton")
                    btnInv:SetText("")
                    btnInv:Dock(TOP)
                    btnInv:DockMargin(20, 10, 20, 10)
                    btnInv:SetTall(40)
                    btnInv.Paint = function(s, w, h)
                        s.HoverP = Lerp(FrameTime() * 15, s.HoverP or 0, s:IsHovered() and 1 or 0)
        if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                        if s.HoverP > 0.01 then
                            draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
                        end
                        local tc = Lerp(s.HoverP, 200, 0)
                        draw.SimpleText("VER INVENTARIO DE MOCHILA", "SW_InvShop_Small", w/2, h/2, Color(tc, tc, tc), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                    btnInv.DoClick = function()
                        LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                        Armario3D_Frame:Remove()
                        RunConsoleCommand("say", "!armario")
                    end
                end
            end
            if mainCat == "active" or mainCat == "armario" or mainCat == "accesorios" then
                local itemsToRender = {}
                if mainCat == "accesorios" then
                    for itemID, qty in pairs(SW_InvShop.Armario or {}) do
                        if qty > 0 and SW_InvShop.Config.Items[itemID] and SW_InvShop.Config.Items[itemID].class == "bg_unlock" then
                            table.insert(itemsToRender, {id = itemID, qty = qty, data = SW_InvShop.Config.Items[itemID], isEq = false})
                        end
                    end
                    for itemID, qty in pairs(SW_InvShop.ActiveInv or {}) do
                        if qty > 0 and SW_InvShop.Config.Items[itemID] and SW_InvShop.Config.Items[itemID].class == "bg_unlock" then
                            table.insert(itemsToRender, {id = itemID, qty = qty, data = SW_InvShop.Config.Items[itemID], isEq = true})
                        end
                    end
                elseif mainCat == "armario" then
                    for itemID, qty in pairs(SW_InvShop.Armario or {}) do
                        if qty > 0 and SW_InvShop.Config.Items[itemID] and SW_InvShop.Config.Items[itemID].class ~= "bg_unlock" then
                            table.insert(itemsToRender, {id = itemID, qty = qty, data = SW_InvShop.Config.Items[itemID], isEq = false})
                        end
                    end
                elseif mainCat == "active" then
                    local pWeps, sWeps, spWeps = {}, {}, {}
                    local function AddToCats(invTable, isEq)
                        for itemID, qty in pairs(invTable or {}) do
                            if qty > 0 and SW_InvShop.Config.Items[itemID] and SW_InvShop.Config.Items[itemID].class ~= "bg_unlock" and not SW_InvShop.Config.Items[itemID].isAmmo then
                                if CanPlayerUseItem(LocalPlayer(), itemID) then
                                    local cat = SW_InvShop.GetItemSlot(itemID)
                                    local entry = {id = itemID, qty = qty, data = SW_InvShop.Config.Items[itemID], isEq = isEq}
                                    if cat == 1 then table.insert(pWeps, entry)
                                    elseif cat == 3 then table.insert(sWeps, entry)
                                    elseif cat == 2 then table.insert(spWeps, entry) end
                                end
                            end
                        end
                    end
                    AddToCats(SW_InvShop.Armario, false)
                    AddToCats(SW_InvShop.ActiveInv, true)
                    if #pWeps > 0 then
                        table.insert(itemsToRender, {isHeader = true, name = "ARMAS PRINCIPALES"})
                        if Armario3D_Expanded["ARMAS PRINCIPALES"] ~= false then
                            for _, v in ipairs(pWeps) do table.insert(itemsToRender, v) end
                        end
                    end
                    if #sWeps > 0 then
                        table.insert(itemsToRender, {isHeader = true, name = "ARMAS SECUNDARIAS"})
                        if Armario3D_Expanded["ARMAS SECUNDARIAS"] ~= false then
                            for _, v in ipairs(sWeps) do table.insert(itemsToRender, v) end
                        end
                    end
                    if #spWeps > 0 then
                        table.insert(itemsToRender, {isHeader = true, name = "ARMAS ESPECIALES"})
                        if Armario3D_Expanded["ARMAS ESPECIALES"] ~= false then
                            for _, v in ipairs(spWeps) do table.insert(itemsToRender, v) end
                        end
                    end
                end
                
                if #itemsToRender == 0 then
                    local emptyLbl = Scroll:Add("DLabel")
                    emptyLbl:SetText("Vacío.")
                    emptyLbl:SetFont("SW_InvShop_Small")
                    emptyLbl:SetTextColor(Color(150, 150, 150))
                    emptyLbl:Dock(TOP)
                    emptyLbl:DockMargin(25, 5, 5, 10)
                    totalH = totalH + 25
                end
                
                for _, itm in ipairs(itemsToRender) do
                    if _G.Armario3D_SelectedItem then
                        if itm.isHeader or not itm.data or itm.data.class ~= _G.Armario3D_SelectedItem then continue end
                    end
                    if itm.isHeader then
                        local isExpanded = Armario3D_Expanded[itm.name] ~= false
                        local btnSub = Scroll:Add("DButton")
                        btnSub:SetText("")
                        btnSub:Dock(TOP)
                        btnSub:DockMargin(10, 5, 10, 5)
                        btnSub:SetTall(35)
                        btnSub.HoverP = 0
                        btnSub.Paint = function(s, w, h)
                            s.HoverP = Lerp(FrameTime() * 15, s.HoverP, s:IsHovered() and 1 or 0)
                            if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                            draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                            if s.HoverP > 0.01 then
                                draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
                            end
                            
                            local tc = Lerp(s.HoverP, 200, 0)
                            local titleColor = isExpanded and color_white or Color(tc, tc, tc)
                            if s.HoverP > 0.9 then titleColor = Color(0, 0, 0) end
                            draw.SimpleText((isExpanded and "v " or "> ") .. itm.name, "SW_InvShop_Medium", 15, h/2 - 6, titleColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            draw.SimpleText(itm.name, "SW_InvShop_Aurebesh_ExtraSmall", 15, h/2 + 8, Color(tc, tc, tc, 100 + s.HoverP * 155), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        end
                        btnSub.DoClick = function()
                            LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                            Armario3D_Expanded[itm.name] = not isExpanded
                            BuildList()
                        end
                        totalH = totalH + 45
                        continue
                    end
                    local btnItm = Scroll:Add("DButton")
                    btnItm:SetText("")
                    btnItm:Dock(TOP)
                    btnItm:DockMargin(15, 0, 15, 4)
                    btnItm:SetTall(55)
                    btnItm.HoverP = 0
                    
                    btnItm.Paint = function(s, w, h)
                        local isItemSel = (_G.Armario3D_SelectedItem == itm.data.class)
                        s.HoverP = Lerp(FrameTime() * 15, s.HoverP, (s:IsHovered() or isItemSel or s.IsNavSelected) and 1 or 0)
                            if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                        
                        draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                        
                        if s.HoverP > 0.01 then
                            draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
                        end
                        
                        local tc = Lerp(s.HoverP, 200, 0)
                        local nameColor = Color(tc, tc, tc)
                        if s.HoverP > 0.9 then nameColor = Color(0, 0, 0) end
                        
                        local prefix = itm.isEq and "[ACTIVO] " or ""
                        if not itm.data.isWeapon then
                            draw.SimpleText(prefix .. itm.data.name, "SW_InvShop_Medium", 10, h/2 - 6, nameColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            draw.SimpleText(itm.data.name, "SW_InvShop_Aurebesh_ExtraSmall", 10, h/2 + 7, Color(tc, tc, tc, 100 + s.HoverP * 155), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        else
                            draw.SimpleText(prefix .. itm.data.name, "SW_InvShop_Medium", 10, h/2, nameColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        end
                    end
                    
                    btnItm.OnCursorEntered = function()
                        LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5)
                        if mainCat ~= "active" then
                            CreateWeaponModel(itm.data)
                        end
                    end
                    
                    btnItm.DoClick = function(s, bIsRebuild)
                        if not bIsRebuild then LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5) end
                        if IsValid(_G.Armario3D_InfoPanel) then _G.Armario3D_InfoPanel:Remove() end
                        
                        if not bIsRebuild then
                            _G.Armario3D_SelectedItem = itm.data.class
                            timer.Simple(0, function()
                                if IsValid(MenuPanel) then BuildList() end
                            end)
                        end
                        
                        _G.Armario3D_InfoPanel = vgui.Create("DPanel", Armario3D_Frame)
                        local ip = _G.Armario3D_InfoPanel
                        ip:SetSize(400, 230)
                        
                        local dmg, clip, rpm, recoil = 0, 0, 0, 0
                        local wepTable = weapons.Get(itm.data.class) or weapons.GetStored(itm.data.class)
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
                            draw.SimpleText(SafeUpper(itm.data.name), "SW_InvShop_Header", 20, 20, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            
                            surface.SetDrawColor(255, 180, 0, 150)
                            surface.DrawRect(20, 65, w - 40, 1)
                            
                            if isWep then
                                local statY = 85
                                local function drawStat(name, val, maxVal, yPos)
                                    draw.SimpleText(name, "SW_InvShop_Small", 20, yPos, Color(180, 180, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                                    local barW = w - 150
                                    local fill = math.Clamp(val / maxVal, 0, 1)
                                    
                                    surface.SetDrawColor(0, 0, 0, 180)
                                    surface.DrawRect(110, yPos - 3, barW, 6)
                                    
                                    surface.SetDrawColor(255, 180, 0, 200)
                                    surface.DrawRect(110, yPos - 3, barW * fill, 6)
                                    
                                    surface.SetDrawColor(255, 180, 0, 100)
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
                        
                        local canUse = CanPlayerUseItem(LocalPlayer(), itm.id)
                        local btnAct = vgui.Create("DButton", ip)
                        btnAct:SetSize(ip:GetWide() - 40, 35)
                        btnAct:SetPos(20, ip:GetTall() - 45)
                        btnAct:SetText("")
                        btnAct.HoverP = 0
                        if not canUse and not itm.isEq then
                            btnAct.Paint = function(s, bw, bh)
                                draw.RoundedBox(16, 0, 0, bw, bh, Color(255, 50, 50, 30))
                                draw.SimpleText("CLASE RESTRINGIDA", "SW_InvShop_Medium", bw/2, bh/2, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            end
                            btnAct.DoClick = function()
                                LocalPlayer():EmitSound("buttons/button10.wav", 75, 100, 0.5)
                            end
                        else
                            btnAct.Paint = function(s, bw, bh)
                                s.HoverP = Lerp(FrameTime() * 15, s.HoverP, s:IsHovered() and 1 or 0)
                                if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                                
                                local bgAlpha = Lerp(s.HoverP, 255, 50)
                                draw.RoundedBox(16, 0, 0, bw, bh, Color(255, 255, 255, bgAlpha))
                                
                                local tc = Lerp(s.HoverP, 0, 255)
                                local nameColor = Color(tc, tc, tc)
                                
                                local realText = itm.isEq and "DESEQUIPAR" or "EQUIPAR"
                                draw.SimpleText(realText, "SW_InvShop_Medium", bw/2, bh/2, nameColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            end
                            btnAct.DoClick = function()
                                LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                                net.Start("SW_MoveItem")
                                net.WriteString(itm.id)
                                net.WriteString(itm.isEq and "armario" or "active")
                                net.SendToServer()
                                if IsValid(_G.Armario3D_InfoPanel) then _G.Armario3D_InfoPanel:Remove() end
                            end
                        end
                    end
                    if _G.Armario3D_SelectedItem == itm.data.class then
                        timer.Simple(0, function() if IsValid(btnItm) then btnItm:DoClick(true) end end)
                    end
                    totalH = totalH + 59
                end
            elseif mainCat == "vestimenta" then
                if v_bodygroups and v_bodygroups.PopulateOptions then
                    v_bodygroups.PopulateOptions()
                    
                    for _, opt in ipairs(v_bodygroups.Options) do
                        local tLow = string.lower(opt.title or "")

                        local isExpanded = Armario3D_Expanded[opt.title]
                        
                        local btnSub = Scroll:Add("DButton")
                        btnSub:SetText("")
                        btnSub:Dock(TOP)
                        btnSub:DockMargin(10, 0, 10, 2)
                        btnSub:SetTall(35)
                        btnSub.HoverP = 0
                        
                        btnSub.Paint = function(s, w, h)
                            s.HoverP = Lerp(FrameTime() * 15, s.HoverP, s:IsHovered() and 1 or 0)
                            if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                            
                            draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                            if s.HoverP > 0.01 then
                                draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
                            end
                            
                            local tc = Lerp(s.HoverP, 200, 0)
                            local titleColor = isExpanded and color_white or Color(tc, tc, tc)
                            if s.HoverP > 0.9 then titleColor = Color(0, 0, 0) end
                            
                            draw.SimpleText((isExpanded and "v " or "> ") .. SafeUpper(opt.title), "SW_InvShop_Medium", 15, h/2, titleColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        end
                        
                        btnSub.DoClick = function()
                            LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                            Armario3D_Expanded[opt.title] = not Armario3D_Expanded[opt.title]
                            BuildList()
                        end
                        
                        totalH = totalH + 37
                        
                        if isExpanded then
                            for j = 0, opt.max - 1 do
                                local optIndex = j
                                local optStr = tostring(j + (opt.title == "Modelo del Trabajo" and 1 or 0))
                                local realName = SafeUpper(realName)
                                local skipSubmodel = false
                                if opt.title ~= "Modelo del Trabajo" and opt.title ~= "Variante de Skin" then
                                    for _, bg in ipairs(LocalPlayer():GetBodyGroups() or {}) do
                                        if bg.id == opt.bgIndex then
                                            local sub = bg.submodels and bg.submodels[j] or ""
                                            if sub ~= "" then
                                                realName = string.Replace(sub, ".smd", "")
                                                realName = string.Replace(realName, "_", " ")
                                                local lowName = string.lower(string.Trim(realName))
                                                if lowName == "empty" or lowName == "blank" or lowName == "none" then
                                                    realName = "NINGUNO"
                                                elseif SW_InvShop and SW_InvShop.HasBodygroupAccess and not SW_InvShop.HasBodygroupAccess(LocalPlayer(), opt.title, sub) then
                                                    skipSubmodel = true
                                                end
                                            end
                                            break
                                        end
                                    end
                                end
                                
                                if skipSubmodel then continue end
                                
                                local btnItm = Scroll:Add("DButton")
                                btnItm:SetText("")
                                btnItm:Dock(TOP)
                                btnItm:DockMargin(15, 0, 15, 2)
                                btnItm:SetTall(30)
                                btnItm.HoverP = 0
                                
                                local isSelected = (opt.val == optIndex)
                                
                                btnItm.Paint = function(s, w, h)
                                    s.HoverP = Lerp(FrameTime() * 15, s.HoverP, (s:IsHovered() or isSelected) and 1 or 0)
                                    
                                    draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                                    if s.HoverP > 0.01 then
                                        draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
                                    end
                                    
                                    local tc = Lerp(s.HoverP, 150, 0)
                                    local nameColor = isSelected and color_white or Color(tc, tc, tc)
                                    if s.HoverP > 0.9 then nameColor = Color(0, 0, 0) end
                                    
                                    draw.SimpleText(SafeUpper(realName), "SW_InvShop_Medium", 10, h/2 - 6, nameColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                                    draw.SimpleText(SafeUpper(realName), "SW_InvShop_Aurebesh_ExtraSmall", 10, h/2 + 7, Color(tc, tc, tc, 100 + s.HoverP * 155), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                                    if isSelected then
                                        draw.SimpleText("EQUIPADO", "SW_InvShop_Small", w - 10, h/2, nameColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                                    end
                                end
                                
                                btnItm.DoClick = function()
                                    LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                                    local isLocked = false
                                    if opt.title ~= "Modelo del Trabajo" and opt.title ~= "Variante de Skin" and SW_InvShop and SW_InvShop.HasBodygroupAccess then
                                        local bgName = LocalPlayer():GetBodygroupName(opt.bgIndex)
                                        local subName = ""
                                        for _, bg in pairs(LocalPlayer():GetBodyGroups() or {}) do
                                            if bg.id == opt.bgIndex then
                                                subName = bg.submodels and bg.submodels[optIndex] or ""
                                                break
                                            end
                                        end
                                        if not SW_InvShop.HasBodygroupAccess(LocalPlayer(), bgName, subName) then
                                            isLocked = true
                                        end
                                    end
                                    if isLocked then
                                        chat.AddText(Color(255,50,50), "No tienes acceso a esta variante.")
                                        return
                                    end
                                    opt.val = optIndex
                                    opt.onUpdate(optIndex)
                                    timer.Simple(0.1, function()
                                        local ply = LocalPlayer()
                                        local currentOutfit = { skin = ply:GetSkin(), bgs = {} }
                                        for i = 0, ply:GetNumBodyGroups() - 1 do currentOutfit.bgs[i] = ply:GetBodygroup(i) end
                                        local modelClean = string.gsub(string.lower(ply:GetModel()), "[/%s%.]", "_")
                                        if not file.Exists("v_bodygroups", "DATA") then file.CreateDir("v_bodygroups") end
                                        file.Write("v_bodygroups/" .. ply:Team() .. "_" .. modelClean .. ".txt", util.TableToJSON(currentOutfit))
                                        net.Start("SW_ReEnforceBGs")
                                        net.SendToServer()
                                    end)
                                    for _, mdlData in ipairs(Armario3D_WeaponModels) do
                                        if IsValid(mdlData.ent) and mdlData.isBase then
                                            if opt.title == "Modelo del Trabajo" then
                                                mdlData.ent:SetModel(LocalPlayer():GetModel())
                                            elseif opt.title == "Variante de Skin" then
                                                mdlData.ent:SetSkin(optIndex)
                                            else
                                                mdlData.ent:SetBodygroup(opt.bgIndex, optIndex)
                                            end
                                        end
                                    end
                                    BuildList()
                                end
                                totalH = totalH + 32
                            end
                        end
                    end
                    

                else
                    local errLbl = Scroll:Add("DLabel")
                    errLbl:SetText("MÓDULO DE VESTIMENTA INACTIVO")
                    errLbl:SetTextColor(Color(255, 50, 50))
                    errLbl:Dock(TOP)
                    errLbl:DockMargin(25, 5, 5, 10)
                    totalH = totalH + 25
                end
            end

        else            btnBackCat:SetVisible(false)

            for _, catData in ipairs(mainCats) do
                local mainCat = catData.id
                
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
                    draw.SimpleText(SafeUpper(mainCat), "SW_InvShop_Medium", 15, h/2, Color(tc, tc, tc), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    
                    local cx, cy = w - 20, h/2
                    surface.SetDrawColor(tc, tc, tc, 150)
                    
                    
                end
                btnMain.DoClick = function()
                    LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                    Armario3D_CurrentCategory = mainCat
                    Armario3D_Expanded = {}
                    Armario3D_Expanded[mainCat] = true
                    if mainCat == "vestimenta" or mainCat == "accesorios" then
                        CreateWeaponModel({class = "bg_unlock", name = "fullbody"})
                    end
                    BuildList()
                end
            end
        end
    local baseH = 160
    if Armario3D_CurrentCategory then baseH = 190 end
    local maxH = ScrH() * 0.9
    local targetH = math.min(maxH, baseH + totalH + 15)
    MenuPanel:SizeTo(310, targetH, 0.2, 0, -1)
    
    timer.Simple(0.1, function()
        if not IsValid(Armario3D_Frame) then return end
        if _G.Armario3D_SelectedItem then
            local itmData = SW_InvShop.Config.Items[_G.Armario3D_SelectedItem]
            if itmData then CreateWeaponModel(itmData) end
        elseif Armario3D_CurrentCategory == "vestimenta" or Armario3D_CurrentCategory == "accesorios" then
            CreateWeaponModel({class = "bg_unlock", name = "fullbody"})
        end
    end)
end



    
    hook.Add("SW_InventorySynced", "Armario3D_Sync", function()
        if IsValid(Armario3D_Frame) then 
            BuildList() 
            timer.Simple(0.3, function()
                if not IsValid(Armario3D_Frame) then return end
                for _, mdlData in pairs(Armario3D_WeaponModels) do
                    if IsValid(mdlData.ent) and mdlData.isBase then
                        for i = 0, LocalPlayer():GetNumBodyGroups() - 1 do
                            mdlData.ent:SetBodygroup(i, LocalPlayer():GetBodygroup(i))
                        end
                    end
                end
            end)
        else 
            hook.Remove("SW_InventorySynced", "Armario3D_Sync") 
        end
    end)
    BuildList()
    
    Armario3D_Frame.OnClose = function()
        _G.SW_Armario3D_Active = false
        for _, mdlData in pairs(Armario3D_WeaponModels) do
            if IsValid(mdlData.ent) then mdlData.ent:Remove() end
        end
        Armario3D_WeaponModels = {}
        if IsValid(_G.Armario3D_InfoPanel) then _G.Armario3D_InfoPanel:Remove() end
    end
end


local curCamPos, curCamAng

hook.Add("CalcView", "SW_Armario3DView", function(ply, pos, angles, fov)
    if not _G.SW_Armario3D_Active then 
        curCamPos = nil
        curCamAng = nil
        return 
    end
    
    local targetCamPos, targetCamAng
    Armario3D_CurrentCamZOffset = Lerp(FrameTime() * 5, Armario3D_CurrentCamZOffset, Armario3D_TargetCamZOffset)
    
    local npcPos = IsValid(Armario3D_Ent) and Armario3D_Ent:GetPos() or LocalPlayer():GetPos()
    local npcAng = IsValid(Armario3D_Ent) and Armario3D_Ent:GetAngles() or LocalPlayer():GetAngles()
    
    local isPlayerView = Armario3D_Expanded["vestimenta"] or Armario3D_CurrentCategory == "active" or Armario3D_CurrentCategory == "accesorios" or not Armario3D_CurrentCategory
    if isPlayerView then
        local tPos = Vector(npcPos.x, npcPos.y, npcPos.z) + npcAng:Forward() * 55
        local basePos = tPos + Vector(0, 0, 45 + Armario3D_CurrentCamZOffset)
        local offset = Vector(130, 0, 0) -- Camera 65 units in front of player dummy
        
        local isBack = (Armario3D_TargetModelRot > 90)
        local isHead = (Armario3D_TargetCamZOffset == 20)
        if isBack then offset = Vector(70, 0, 0) end
        if isHead then offset = Vector(40, 0, 0) end
        
        targetCamPos = basePos + (npcAng:Forward() * offset.x) + (npcAng:Right() * offset.y) + (npcAng:Up() * offset.z)
        targetCamAng = (basePos - targetCamPos):Angle()
    else
        local tPos = Vector(npcPos.x, npcPos.y, npcPos.z) + npcAng:Forward() * 55 + Vector(0, 0, 45)
        local offset = Vector(90, 0, 5) -- Camera 40 units in front of weapon
        targetCamPos = tPos + (npcAng:Forward() * offset.x) + (npcAng:Right() * offset.y) + (npcAng:Up() * offset.z)
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

hook.Add("PostDrawOpaqueRenderables", "SW_Armario3DModel", function()
    if not _G.SW_Armario3D_Active then return end
    
    Armario3D_CurrentModelRot = Lerp(FrameTime() * 5, Armario3D_CurrentModelRot, Armario3D_TargetModelRot)
    
    for _, mdlData in ipairs(Armario3D_WeaponModels) do
        if IsValid(mdlData.ent) then
            local targetPos, targetAng
            local npcPos = IsValid(Armario3D_Ent) and Armario3D_Ent:GetPos() or LocalPlayer():GetPos()
            local npcAng = IsValid(Armario3D_Ent) and Armario3D_Ent:GetAngles() or LocalPlayer():GetAngles()
            
            local isPlayerView = Armario3D_Expanded["vestimenta"] or Armario3D_CurrentCategory == "active" or Armario3D_CurrentCategory == "accesorios" or not Armario3D_CurrentCategory
            if isPlayerView then
                targetPos = Vector(npcPos.x, npcPos.y, npcPos.z) + npcAng:Forward() * 55
                -- Player dummy faces the camera (which is in front of it)
                targetAng = Angle(0, npcAng.y + Armario3D_CurrentModelRot - Armario3D_ManualRot, 0)
            else
                targetPos = Vector(npcPos.x, npcPos.y, npcPos.z) + npcAng:Forward() * 55 + Vector(0, 0, 45)
                targetAng = Angle(Armario3D_ManualRotPitch, npcAng.y + Armario3D_CurrentModelRot - Armario3D_ManualRot, 0)
            end
            
            local m = Matrix()
            m:Translate(targetPos)
            m:Rotate(targetAng)
            m:Translate(-Armario3D_WeaponCenterOffset)
            
            mdlData.ent:SetPos(m:GetTranslation())
            mdlData.ent:SetAngles(m:GetAngles())
            mdlData.ent:SetupBones()
            
            if mdlData.isBase then mdlData.ent:FrameAdvance(FrameTime()) end
            
            mdlData.ent:DrawModel()
        end
    end
end)

hook.Add("HUDShouldDraw", "SW_Armario3D_HideHUD", function(name)
    if _G.SW_Armario3D_Active then return false end
end)

hook.Add("PrePlayerDraw", "SW_Armario3D_HidePlayers", function(ply)
    if _G.SW_Armario3D_Active then
        if Armario3D_Expanded["vestimenta"] and ply == LocalPlayer() then
            return true
        end
        return true
    end
end)

local armario_hidden_weps = {}
hook.Add("Think", "SW_Armario3D_HideWeapons_Think", function()
    if _G.SW_Armario3D_Active then
        for _, ply in ipairs(player.GetAll()) do
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and not wep:GetNoDraw() then
                wep:SetNoDraw(true)
                armario_hidden_weps[wep] = true
            end
        end
    else
        for wep, _ in pairs(armario_hidden_weps) do
            if IsValid(wep) then
                wep:SetNoDraw(false)
            end
            armario_hidden_weps[wep] = nil
        end
    end
end)
