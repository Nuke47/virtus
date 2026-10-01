SW_InvShop = SW_InvShop or {}

local K_Color_BG = Color(10, 12, 16, 252)
local K_Color_Header = Color(16, 20, 26, 255)
local K_Color_Card = Color(22, 28, 36, 150)
local K_Color_CardHover = Color(30, 38, 48, 220)
local K_Color_Text = Color(240, 244, 250)
local K_Color_Green = Color(0, 255, 150)

local function SafeUpper(str) if not str then return "" end if type(str) ~= "string" then str = tostring(str) end return string.upper(str) end

local function SkinModernScrollbar(scrollPanel, thumbColor)
    local sbar = scrollPanel:GetVBar()
    sbar:SetWide(6)
    sbar:SetHideButtons(true)
    sbar.Paint = function(s, w, h) end
    sbar.btnUp.Paint = function(s, w, h) end
    sbar.btnDown.Paint = function(s, w, h) end
    sbar.btnGrip.Paint = function(s, w, h)
        local col = s:IsHovered() and Color(thumbColor.r, thumbColor.g, thumbColor.b, 200) or Color(150, 150, 150, 50)
        draw.RoundedBox(3, 0, 0, w, h, col)
    end
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


local function DrawElegantPanel(w, h, themeColor)
    -- Fondos y contenedores eliminados
end


function SW_InvShop:OpenMainFrame(menuType)
    if IsValid(SW_InvShop.MainMenu) then SW_InvShop.MainMenu:Remove() end

    local themeColor = Color(0, 195, 255) 
    if menuType == "armario" then themeColor = K_Color_Green
    elseif menuType == "blackmarket" then themeColor = Color(230, 50, 50) 
    elseif menuType == "ammoshop" then themeColor = Color(255, 150, 0) end 

    local frame = vgui.Create("DFrame")
    frame:SetSize(ScrW(), ScrH())
    frame:MakePopup()
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:Center()
    
    frame.Paint = function(self, w, h)
        if VIRTUSMENU and VIRTUSMENU.DrawStars then
            VIRTUSMENU.DrawStars(w, h)
        end
        Derma_DrawBackgroundBlur(self, SysTime())
    end
    SW_InvShop.MainMenu = frame

    local header = vgui.Create("DPanel", frame)
    header:SetHeight(85)
    header:Dock(TOP)
    header.Paint = function(self, w, h)
        draw.NoTexture()
        surface.SetDrawColor(themeColor.r, themeColor.g, themeColor.b, 150)
        surface.DrawRect(0, h - 2, w, 2)

        local title = "SISTEMA PRINCIPAL"
        local subtitle = "Cargando datos..."
        
        if menuType == "armario" then 
            title = "ALMACÉN DE INVENTARIO MULTIFUNCIÓN"
            subtitle = "Gestiona tu armamento. (Click derecho en un objeto para Venderlo)"
        elseif menuType == "tienda" then 
            title = "SUMINISTROS DEL IMPERIO"
            subtitle = "Adquiere armamento autorizado para tu rango y facción."
        elseif menuType == "blackmarket" then 
            title = "MERCADO NEGRO - RED CRIMINAL"
            subtitle = "Armamento sin registrar. Sin preguntas. Sin devoluciones."
        elseif menuType == "ammoshop" then
            title = "DEPÓSITO DE MUNICIONES"
            subtitle = "Adquiere suministros balísticos y explosivos."
        elseif menuType == "vestimenta" then
            title = "DATAPAD TÁCTICO - VESTIMENTA"
            subtitle = "Personaliza tus variantes de modelo, skins y equipamiento de armadura."
        end
        
        draw.SimpleText(title, "VF4_TitleBig", 40, 15, K_Color_Text)
        draw.SimpleText(subtitle, "VF4_Normal", 41, 50, Color(140, 150, 165))

        if (menuType == "tienda" or menuType == "blackmarket" or menuType == "ammoshop") and LocalPlayer().getDarkRPVar then
            local money = LocalPlayer():getDarkRPVar("money") or 0
            draw.SimpleText("CRÉDITOS: " .. string.Comma(money) .. " cr", "VF4_TitleBig", w - 150, 26, themeColor, TEXT_ALIGN_RIGHT)
        end
    end

    local closeBtn = vgui.Create("DButton", header)
    closeBtn:SetSize(40, 40)
    closeBtn:Dock(RIGHT)
    closeBtn:DockMargin(0, 22, 40, 23)
    closeBtn:SetText("X")
    closeBtn:SetFont("VF4_Medium")
    closeBtn:SetTextColor(K_Color_Text)
    closeBtn.Paint = function(self, w, h)
        self.HoverP = Lerp(FrameTime() * 12, self.HoverP or 0, self:IsHovered() and 1 or 0)
        if self.HoverP > 0.01 then
            draw.RoundedBox(16, 0, 0, w, h, Color(231, 76, 60, self.HoverP * 255))
        end
        if self:IsHovered() then self:SetTextColor(color_white) else self:SetTextColor(K_Color_Text) end
    end
    closeBtn.DoClick = function() frame:Remove() end

    local mainArea = vgui.Create("DPanel", frame)
    mainArea:Dock(FILL)
    mainArea:DockMargin(40, 30, 40, 40)
    mainArea.Paint = function() end

    local inspectorWidth = math.floor(ScrW() * 0.22)
    local inspectorPanel = vgui.Create("DPanel", mainArea)
    inspectorPanel:SetWide(inspectorWidth)
    inspectorPanel:Dock(RIGHT)
    inspectorPanel:DockMargin(20, 0, 0, 0)
    inspectorPanel.Paint = function(s, w, h)
        DrawElegantPanel(w, h, themeColor)
    end

    function frame:UpdateInspector(itemID)
        inspectorPanel:Clear()
        if not itemID then
            local empty = vgui.Create("DLabel", inspectorPanel)
            empty:SetText("SISTEMA DE DIAGNÓSTICO\n\nPasa el cursor sobre un objeto para escanear sus especificaciones técnicas.")
            empty:SetFont("VF4_Normal")
            empty:SetTextColor(Color(110, 125, 140))
            empty:SetWrap(true)
            empty:Dock(FILL)
            empty:DockMargin(40, 0, 40, 0)
            empty:SetContentAlignment(5)
            return
        end

        local itemData = SW_InvShop.Config.Items[itemID]
        if not itemData then return end

        local iTitle = vgui.Create("DPanel", inspectorPanel)
        iTitle:SetHeight(45)
        iTitle:Dock(TOP)
        iTitle.Paint = function(s, w, h)
            draw.NoTexture()
            surface.SetDrawColor(themeColor)
            surface.DrawRect(0, h-2, w, 2)
        end

        local iTitleLbl = vgui.Create("DLabel", iTitle)
        iTitleLbl:SetText(SafeUpper(itemData.name))
        iTitleLbl:SetFont("VF4_Header")
        iTitleLbl:SetTextColor(K_Color_Text)
        iTitleLbl:Dock(FILL)
        iTitleLbl:DockMargin(20, 0, 20, 0)
        iTitleLbl:SetContentAlignment(4)

        local iModel = vgui.Create("DModelPanel", inspectorPanel)
        iModel:SetHeight(220)
        iModel:Dock(TOP)
        iModel:SetModel(itemData.model)
        
        local ent = iModel:GetEntity()
        if IsValid(ent) then
            if itemData.preview_auto_bino then
                for _, bg in pairs(ent:GetBodyGroups() or {}) do
                    local bgName = string.lower(bg.name)
                    if bg.submodels then
                        for subId, subName in pairs(bg.submodels) do
                            subName = string.lower(subName)
                            if string.find(subName, "bino") or string.find(subName, "visor") or string.find(subName, "nvg") then
                                if string.find(subName, "down") then
                                    ent:SetBodygroup(bg.id, subId)
                                    break
                                end
                            elseif (string.find(bgName, "bino") or string.find(bgName, "visor") or string.find(bgName, "nvg")) and string.find(subName, "down") then
                                ent:SetBodygroup(bg.id, subId)
                                break
                            end
                        end
                    end
                end
            elseif itemData.preview_auto_jetpack then
                for _, bg in pairs(ent:GetBodyGroups() or {}) do
                    local bgName = string.lower(bg.name or "")
                    if bg.submodels then
                        for subId, subName in pairs(bg.submodels) do
                            local fullSearch = bgName .. " " .. string.lower(subName)
                            if string.find(fullSearch, "jetpack") then
                                ent:SetBodygroup(bg.id, subId)
                                break
                            end
                        end
                    end
                end
            elseif itemData.preview_auto_jumpack then
                for _, bg in pairs(ent:GetBodyGroups() or {}) do
                    local bgName = string.lower(bg.name or "")
                    if bg.submodels then
                        for subId, subName in pairs(bg.submodels) do
                            local fullSearch = bgName .. " " .. string.lower(subName)
                            if string.find(fullSearch, "cody") or string.find(fullSearch, "jumpack") or string.find(fullSearch, "jump pack") then
                                ent:SetBodygroup(bg.id, subId)
                                break
                            end
                        end
                    end
                end
            elseif itemData.preview_auto_backpack then
                for _, bg in pairs(ent:GetBodyGroups() or {}) do
                    local bgName = string.lower(bg.name or "")
                    if bg.submodels then
                        for subId, subName in pairs(bg.submodels) do
                            local fullSearch = bgName .. " " .. string.lower(subName)
                            if string.find(fullSearch, "backpack") or string.find(fullSearch, "pack") or string.find(fullSearch, "mochila") then
                                ent:SetBodygroup(bg.id, subId)
                                break
                            end
                        end
                    end
                end
            end
            if itemData.preview_bodygroups then
                for bgId, bgVal in pairs(itemData.preview_bodygroups) do
                    ent:SetBodygroup(bgId, bgVal)
                end
            end
            if itemData.preview_skin then
                ent:SetSkin(itemData.preview_skin)
            end
        end

        local camPos = itemData.preview_cam or Vector(30, 30, 10)
        local lookAt = itemData.preview_lookat or Vector(0, 0, 0)
        local fov = itemData.preview_fov or 45

        iModel:SetLookAt(lookAt)
        iModel:SetCamPos(camPos)
        iModel:SetFOV(fov)
        function iModel:LayoutEntity(Entity)
            if itemData.preview_spin == false then return end
            Entity:SetAngles(Angle(0, RealTime() * 25, 0))
        end

        local iContent = vgui.Create("DPanel", inspectorPanel)
        iContent:Dock(FILL)
        iContent:DockMargin(20, 10, 20, 20)
        iContent.Paint = function() end

        local catLbl = vgui.Create("DLabel", iContent)
        catLbl:SetText("CATEGORÍA: " .. SafeUpper(itemData.category or "General"))
        catLbl:SetFont("VF4_Small")
        catLbl:SetTextColor(themeColor)
        catLbl:Dock(TOP)

        local line = vgui.Create("DPanel", iContent)
        line:SetHeight(1)
        line:Dock(TOP)
        line:DockMargin(0, 8, 0, 15)
        line.Paint = function(s,w,h) surface.SetDrawColor(255,255,255,10) surface.DrawRect(0,0,w,h) end

        local descLbl = vgui.Create("DLabel", iContent)
        descLbl:SetText(itemData.desc or "Sin descripción técnica en la base de datos.")
        descLbl:SetFont("VF4_Normal")
        descLbl:SetTextColor(Color(165, 175, 190))
        descLbl:SetWrap(true)
        descLbl:Dock(TOP)
        descLbl:SetContentAlignment(7)

        local stats = vgui.Create("DPanel", iContent)
        stats:Dock(BOTTOM)
        stats:SetHeight(110)
        stats.Paint = function(s, w, h)
            draw.NoTexture()
            surface.SetDrawColor(0,0,0,120)
            surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(255,255,255,10)
            surface.DrawOutlinedRect(0,0,w,h,1)
            
            draw.SimpleText("REGISTRO DE RED:", "VF4_Small", 15, 18, Color(120, 135, 150))
            draw.SimpleText(itemData.class or "Entidad", "VF4_Small", w - 15, 18, K_Color_Text, TEXT_ALIGN_RIGHT)
            
            draw.SimpleText("ESTADO DE ACCESO:", "VF4_Small", 15, 46, Color(120, 135, 150))
            local allowed = CanPlayerUseItem(LocalPlayer(), itemID)
            local statusStr = allowed and "AUTORIZADO" or "RESTRINGIDO"
            local statusCol = allowed and K_Color_Green or Color(240, 70, 70)
            draw.SimpleText(statusStr, "VF4_Small", w - 15, 46, statusCol, TEXT_ALIGN_RIGHT)
            
            local priceTitle = (menuType == "blackmarket") and "PRECIO EN NEGRO:" or "VALOR LOGÍSTICO:"
            draw.SimpleText(priceTitle, "VF4_Small", 15, 74, Color(120, 135, 150))
            draw.SimpleText((itemData.price or 0) .. " CR", "VF4_Small", w - 15, 74, themeColor, TEXT_ALIGN_RIGHT)
        end
    end
    frame:UpdateInspector(nil)

    if menuType == "tienda" or menuType == "blackmarket" then
        local sidebarWidth = 260
        local sidebar = vgui.Create("DPanel", mainArea)
        sidebar:SetWide(sidebarWidth)
        sidebar:Dock(LEFT)
        sidebar:DockMargin(0, 0, 20, 0)
        sidebar.Paint = function(self, w, h)
            DrawElegantPanel(w, h, themeColor)
        end

        local lblSide = vgui.Create("DLabel", sidebar)
        lblSide:SetText("SECCIONES")
        lblSide:SetFont("VF4_Medium")
        lblSide:SetTextColor(themeColor)
        lblSide:Dock(TOP)
        lblSide:DockMargin(20, 20, 20, 12)

        local scrollCats = vgui.Create("DScrollPanel", sidebar)
        scrollCats:Dock(FILL)
        scrollCats:DockMargin(12, 0, 12, 15)
        SkinModernScrollbar(scrollCats, themeColor)

        local itemsArea = vgui.Create("DScrollPanel", mainArea)
        itemsArea:Dock(FILL)
        SkinModernScrollbar(itemsArea, themeColor)

        local itemGrid = vgui.Create("DIconLayout", itemsArea)
        itemGrid:Dock(TOP)
        itemGrid:SetSpaceX(18)
        itemGrid:SetSpaceY(18)

        local activeCategory = nil

        local function LoadCategoryItems(categoryName)
            itemGrid:Clear()
            frame:UpdateInspector(nil)
            itemsArea:InvalidateLayout(true)
            local safeAreaWidth = ScrW() - 40 - sidebarWidth - 20 - 20 - inspectorWidth - 40 - 25
            local columns = 3
            local spacing = 18
            local calculatedCardWidth = math.floor((safeAreaWidth - (spacing * (columns - 1))) / columns)

            for itemID, item in pairs(SW_InvShop.Config.Items) do
                if item.isBaseItem then continue end
                
                local itemCat = item.category or "General"
                local isItemBM = item.isContraband or false
                local isMenuBM = (menuType == "blackmarket")

                if itemCat == categoryName and isItemBM == isMenuBM then
                    local card = itemGrid:Add("DPanel")
                    card:SetSize(calculatedCardWidth, 310)
                    card.HoverP = 0
                    card.Paint = function(self, w, h)
                        self.HoverP = Lerp(FrameTime() * 10, self.HoverP or 0, self:IsHovered() and 1 or 0)
                        draw.NoTexture()
                        
                        surface.SetDrawColor(themeColor.r, themeColor.g, themeColor.b, 100 + self.HoverP * 155)
                        local lw, lh = w - 1, h - 1
                        surface.DrawLine(0, 0, lw, 0)
                        surface.DrawLine(lw, 0, lw, lh - 20)
                        surface.DrawLine(lw, lh - 20, lw - 20, lh)
                        surface.DrawLine(lw - 20, lh, 0, lh)
                        surface.DrawLine(0, lh, 0, 0)
                    end

                    local model = vgui.Create("DModelPanel", card)
                    model:SetSize(calculatedCardWidth, 135)
                    model:Dock(TOP)
                    model:SetModel(item.model)
                    
                    local ent = model:GetEntity()
                    if IsValid(ent) then
                        if item.preview_auto_bino then
                            for _, bg in pairs(ent:GetBodyGroups() or {}) do
                                local bgName = string.lower(bg.name)
                                if bg.submodels then
                                    for subId, subName in pairs(bg.submodels) do
                                        subName = string.lower(subName)
                                        if string.find(subName, "bino") or string.find(subName, "visor") or string.find(subName, "nvg") then
                                            if string.find(subName, "down") then
                                                ent:SetBodygroup(bg.id, subId)
                                                break
                                            end
                                        elseif (string.find(bgName, "bino") or string.find(bgName, "visor") or string.find(bgName, "nvg")) and string.find(subName, "down") then
                                            ent:SetBodygroup(bg.id, subId)
                                            break
                                        end
                                    end
                                end
                            end
                        elseif item.preview_auto_jetpack then
                            for _, bg in pairs(ent:GetBodyGroups() or {}) do
                                local bgName = string.lower(bg.name or "")
                                if bg.submodels then
                                    for subId, subName in pairs(bg.submodels) do
                                        local fullSearch = bgName .. " " .. string.lower(subName)
                                        if string.find(fullSearch, "jetpack") then
                                            ent:SetBodygroup(bg.id, subId)
                                            break
                                        end
                                    end
                                end
                            end
                        elseif item.preview_auto_jumpack then
                            for _, bg in pairs(ent:GetBodyGroups() or {}) do
                                local bgName = string.lower(bg.name or "")
                                if bg.submodels then
                                    for subId, subName in pairs(bg.submodels) do
                                        local fullSearch = bgName .. " " .. string.lower(subName)
                                        if string.find(fullSearch, "cody") or string.find(fullSearch, "jumpack") or string.find(fullSearch, "jump pack") then
                                            ent:SetBodygroup(bg.id, subId)
                                            break
                                        end
                                    end
                                end
                            end
                        elseif item.preview_auto_backpack then
                            for _, bg in pairs(ent:GetBodyGroups() or {}) do
                                local bgName = string.lower(bg.name or "")
                                if bg.submodels then
                                    for subId, subName in pairs(bg.submodels) do
                                        local fullSearch = bgName .. " " .. string.lower(subName)
                                        if string.find(fullSearch, "backpack") or string.find(fullSearch, "pack") or string.find(fullSearch, "mochila") then
                                            ent:SetBodygroup(bg.id, subId)
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        if item.preview_bodygroups then
                            for bgId, bgVal in pairs(item.preview_bodygroups) do
                                ent:SetBodygroup(bgId, bgVal)
                            end
                        end
                        if item.preview_skin then
                            ent:SetSkin(item.preview_skin)
                        end
                    end

                    local camPos = item.preview_cam or Vector(32, 32, 12)
                    local lookAt = item.preview_lookat or Vector(0, 0, 0)
                    local fov = item.preview_fov or 48

                    model:SetLookAt(lookAt)
                    model:SetCamPos(camPos)
                    model:SetFOV(fov)
                    function model:LayoutEntity(Entity)
                        if item.preview_spin == false then return end
                        Entity:SetAngles(Angle(0, RealTime() * 15, 0))
                    end

                    card.OnCursorEntered = function() frame:UpdateInspector(itemID) end
                    model.OnCursorEntered = function() frame:UpdateInspector(itemID) end

                    local name = vgui.Create("DLabel", card)
                    name:SetText(item.name)
                    name:SetFont("VF4_Header")
                    name:SetTextColor(K_Color_Text)
                    name:Dock(TOP)
                    name:DockMargin(15, 8, 15, 2)

                    local desc = vgui.Create("DLabel", card)
                    desc:SetText(item.desc or "")
                    desc:SetFont("VF4_Small")
                    desc:SetTextColor(Color(140, 150, 165))
                    desc:Dock(TOP)
                    desc:DockMargin(15, 0, 15, 10)
                    desc:SetHeight(32)
                    desc:SetWrap(true)

                    local isWeaponOwned = false
                    if (SW_InvShop.ActiveInv and SW_InvShop.ActiveInv[itemID] and SW_InvShop.ActiveInv[itemID] > 0) or 
                       (SW_InvShop.Armario and SW_InvShop.Armario[itemID] and SW_InvShop.Armario[itemID] > 0) then
                        isWeaponOwned = true
                    end
                    local canPlayerUse = CanPlayerUseItem(LocalPlayer(), itemID)
                    
                    -- Check level manually for UI display if needed
                    local reqLevel = item.levelReq or 0
                    if reqLevel == 0 then
                        local catConfigLevel = nil
                        if item.isContraband then catConfigLevel = SW_InvShop.Config.BMCategories[item.category]
                        elseif item.isAmmo then catConfigLevel = SW_InvShop.Config.AmmoCategories[item.category]
                        else catConfigLevel = SW_InvShop.Config.Categories[item.category] end
                        if catConfigLevel and catConfigLevel.levelReq then reqLevel = catConfigLevel.levelReq end
                    end
                    local plyLevel = LocalPlayer().GetLevel and LocalPlayer():GetLevel() or 1
                    local isBlockedByLevel = (reqLevel > 0 and plyLevel < reqLevel)

                    local buyBtn = vgui.Create("DButton", card)
                    buyBtn:Dock(BOTTOM)
                    buyBtn:SetHeight(40)
                    buyBtn:DockMargin(15, 0, 15, 15)
                    buyBtn:SetFont("VF4_Medium")
                    buyBtn.HoverP = 0

                    if not canPlayerUse then
                        if isBlockedByLevel then
                            buyBtn:SetText("NIVEL " .. reqLevel .. " REQ.")
                            buyBtn.Paint = function(s,w,h) s:SetTextColor(Color(120, 120, 120)) end
                            buyBtn:SetEnabled(false)
                        else
                            buyBtn:SetText("NO PERMITIDO")
                            buyBtn.Paint = function(s,w,h) s:SetTextColor(Color(120, 120, 120)) end
                            buyBtn:SetEnabled(false)
                        end
                        buyBtn:SetTooltip("No posees el trabajo/rango necesario para adquirir este ítem.")
                    elseif isWeaponOwned then
                        local sellPrice = math.floor((item.price or 0) * 0.4)
                        buyBtn:SetText("VENDER / +" .. sellPrice .. " CR")
                        buyBtn.Paint = function(s,w,h)
                            s.HoverP = Lerp(FrameTime() * 12, s.HoverP or 0, s:IsHovered() and 1 or 0)
                        if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                            if s.HoverP > 0.01 then
                                draw.RoundedBox(16, 0, 0, w, h, Color(230, 50, 50, s.HoverP * 255))
                            end
                            if s:IsHovered() then s:SetTextColor(color_white) else s:SetTextColor(Color(255, 100, 100)) end
                        end
                        buyBtn.DoClick = function()
                            net.Start("SW_SellItem")
                            net.WriteString(itemID)
                            net.SendToServer()
                        end
                    else
                        buyBtn:SetText("ADQUIRIR / " .. item.price .. " CR")
                        buyBtn.Paint = function(s,w,h)
                            s.HoverP = Lerp(FrameTime() * 12, s.HoverP or 0, s:IsHovered() and 1 or 0)
                        if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                            if s.HoverP > 0.01 then
                                draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
                            end
                            local tc = Lerp(s.HoverP, 255, 0)
                            s:SetTextColor(Color(tc, tc, tc, 255))
                        end
                        buyBtn.Clicks = 0
                        buyBtn.DoClick = function(s)
                            s.Clicks = s.Clicks + 1
                            if s.Clicks >= 2 then
                                net.Start("SW_BuyItem")
                                net.WriteString(itemID)
                                net.SendToServer()
                                s.Clicks = 0
                            else
                                s:SetText("CONFIRMAR COMPRA")
                                s:SetTextColor(Color(255, 150, 0))
                                timer.Simple(3, function()
                                    if IsValid(s) and s.Clicks == 1 then
                                        s.Clicks = 0
                                        s:SetText("ADQUIRIR / " .. item.price .. " CR")
                                        s:SetTextColor(K_Color_Text)
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end

        function frame:Refresh()
            scrollCats:Clear()
            local categoriesDef = SW_InvShop.Config.Categories
            if menuType == "blackmarket" then categoriesDef = SW_InvShop.Config.BMCategories end
            
            categoriesDef = categoriesDef or { ["General"] = {} }
            local firstCat = nil

            for catName, catConfig in pairs(categoriesDef) do
                if not firstCat then firstCat = catName end
                
                local allowed = true
                
                local hasJobs = (catConfig.allowedJobs and table.Count(catConfig.allowedJobs) > 0)
                local hasKeywords = (catConfig.allowedKeywords and table.Count(catConfig.allowedKeywords) > 0)
                
                if hasJobs or hasKeywords then
                    allowed = false
                    local myJob = LocalPlayer():Team()
                    
                    if hasJobs then
                        for _, jobIdentifier in pairs(catConfig.allowedJobs) do
                            local targetJob = type(jobIdentifier) == "string" and _G[jobIdentifier] or jobIdentifier
                            if targetJob and myJob == targetJob then allowed = true break end
                        end
                    end
                    
                    if not allowed and hasKeywords then
                        local myJobName = string.lower(team.GetName(myJob) or "")
                        for _, keyword in pairs(catConfig.allowedKeywords) do
                            if string.find(myJobName, string.lower(keyword)) then
                                allowed = true
                                break
                            end
                        end
                    end
                end

                local btnCat = scrollCats:Add("DButton")
                btnCat:SetText("  " .. SafeUpper(catName))
                btnCat:Dock(TOP)
                btnCat:SetTall(42)
                btnCat:DockMargin(0, 0, 0, 6)
                btnCat:SetFont("VF4_Medium")
                btnCat:SetContentAlignment(4)
                
                if allowed then btnCat:SetTextColor(K_Color_Text) else btnCat:SetTextColor(Color(100, 110, 125)) end
                
                btnCat.HoverP = 0
                btnCat.OnCursorEntered = function(s) if VIRTUSMENU and VIRTUSMENU.PlayUI then VIRTUSMENU.PlayUI("navigation/movimiento.wav") end end
                btnCat.Paint = function(s, w, h)
                    s.HoverP = Lerp(FrameTime() * 12, s.HoverP or 0, (s:IsHovered() or activeCategory == catName) and 1 or 0)
                    draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                    if s.HoverP > 0.01 then
                        draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
                    end
                    local tc = Lerp(s.HoverP, 200, 0)
                    if allowed then s:SetTextColor(Color(tc, tc, tc, 255)) else s:SetTextColor(Color(100, 110, 125)) end
                end

                btnCat.DoClick = function()
                    activeCategory = catName
                    LoadCategoryItems(catName)
                end
            end

            if activeCategory or firstCat then
                activeCategory = activeCategory or firstCat
                LoadCategoryItems(activeCategory)
            end
        end

    elseif menuType == "armario" then
        local leftContainer = vgui.Create("DPanel", mainArea)
        leftContainer:SetWide(math.floor(ScrW() * 0.38))
        leftContainer:Dock(LEFT)
        leftContainer:DockMargin(0, 0, 20, 0)
        leftContainer.Paint = function(s, w, h)
            DrawElegantPanel(w, h, K_Color_Green)
        end

        local slotsColumn = vgui.Create("DScrollPanel", leftContainer)
        slotsColumn:SetWide(105)
        slotsColumn:Dock(LEFT)
        slotsColumn:DockMargin(15, 15, 0, 15)
        SkinModernScrollbar(slotsColumn, K_Color_Green)

        local beltColumn = vgui.Create("DScrollPanel", leftContainer)
        beltColumn:SetWide(105)
        beltColumn:Dock(RIGHT)
        beltColumn:DockMargin(0, 15, 15, 15)
        SkinModernScrollbar(beltColumn, K_Color_Green)

        local modelContainer = vgui.Create("DPanel", leftContainer)
        modelContainer:Dock(FILL)
        modelContainer:DockMargin(10, 15, 10, 15)
        modelContainer.Paint = function() end

        local playerModel = vgui.Create("DModelPanel", modelContainer)
        playerModel:Dock(FILL)
        playerModel:SetModel(LocalPlayer():GetModel())
        playerModel:SetCamPos(Vector(80, 0, 42)) 
        playerModel:SetLookAt(Vector(0, 0, 36))
        playerModel:SetFOV(38)
        
        local ent = playerModel:GetEntity()
        if IsValid(ent) then
            playerModel.HeadBone = ent:LookupBone("ValveBiped.Bip01_Head1") 
            ent:SetSkin(LocalPlayer():GetSkin())
            for _, bg in ipairs(LocalPlayer():GetBodyGroups() or {}) do
                ent:SetBodygroup(bg.id, LocalPlayer():GetBodygroup(bg.id))
            end
        end

        function playerModel:LayoutEntity(Entity)
            local anim = Entity:LookupSequence("idle_all_01") or 0
            if Entity:GetSequence() != anim then Entity:SetSequence(anim) end
            Entity:FrameAdvance(FrameTime())
            self:RunAnimation()
            if not self.HeadBone then return end
            local mouseX, mouseY = self:CursorPos()
            local w, h = self:GetSize()
            local inputX = (math.Clamp(mouseX, 0, w) / w) - 0.5
            local inputY = (math.Clamp(mouseY, 0, h) / h) - 0.5
            Entity:ManipulateBoneAngles(self.HeadBone, Angle(0, -inputY * 40, inputX * 45))
        end

        local btnVestimenta = vgui.Create("DButton", modelContainer)
        btnVestimenta:Dock(BOTTOM)
        btnVestimenta:SetTall(35)
        btnVestimenta:DockMargin(0, 10, 0, 0)
        btnVestimenta:SetText("MODIFICAR VESTIMENTA (BODYGROUPS)")
        btnVestimenta:SetFont("VF4_Small")
        btnVestimenta:SetTextColor(color_white)
        btnVestimenta.Paint = function(s, w, h)
            s.HoverP = Lerp(FrameTime() * 12, s.HoverP or 0, s:IsHovered() and 1 or 0)
                        if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
            draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
            if s.HoverP > 0.01 then
                draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
            end
            local tc = Lerp(s.HoverP, 255, 0)
            s:SetTextColor(Color(tc, tc, tc, 255))
        end
        btnVestimenta.DoClick = function()
            frame:Remove()
            SW_InvShop:OpenMainFrame("vestimenta")
        end

        local vaultContainer = vgui.Create("DPanel", mainArea)
        vaultContainer:Dock(FILL)
        vaultContainer.Paint = function(s, w, h)
            DrawElegantPanel(w, h, K_Color_Green)
        end

        local lblArmario = vgui.Create("DLabel", vaultContainer)
        lblArmario:SetText("BAÚL DE SEGURIDAD GENERAL")
        lblArmario:SetFont("VF4_Medium")
        lblArmario:SetTextColor(K_Color_Green)
        lblArmario:Dock(TOP)
        lblArmario:DockMargin(25, 20, 20, 10)

        local scrollArmario = vgui.Create("DScrollPanel", vaultContainer)
        scrollArmario:Dock(FILL)
        scrollArmario:DockMargin(25, 5, 25, 25)
        SkinModernScrollbar(scrollArmario, K_Color_Green)
        
        scrollArmario:Receiver("SW_InventoryDragDrop", function(receiver, droppedPanels, bDoDrop)
            if bDoDrop and droppedPanels[1] and droppedPanels[1].ItemID then
                net.Start("SW_MoveItem")
                net.WriteString(droppedPanels[1].ItemID)
                net.WriteString("armario")
                net.SendToServer()
            end
        end)

        frame.SlotsColumn = slotsColumn
        frame.BeltColumn = beltColumn
        frame.ScrollArmario = scrollArmario

        function frame:Refresh()
            frame.ScrollArmario:Clear()
            frame.SlotsColumn:Clear()
            frame.BeltColumn:Clear()

            local activeItemsList = {}
            local ammoItemsList = {}
            for itemID, qty in pairs(SW_InvShop.ActiveInv or {}) do
                local itemData = SW_InvShop.Config.Items[itemID]
                if not itemData then continue end
                
                if itemData.isAmmo then
                    for k=1, qty do
                        table.insert(ammoItemsList, itemID)
                    end
                else
                    local stype = SW_InvShop.GetItemSlot and SW_InvShop.GetItemSlot(itemID) or 1
                    if stype <= 3 and not activeItemsList[stype] then
                        activeItemsList[stype] = itemID
                    else
                        for j = 1, 3 do
                            if not activeItemsList[j] then
                                activeItemsList[j] = itemID
                                break
                            end
                        end
                    end
                end
            end

            -- Determinar si tiene mochila para slots de munición
            local hasBackpack = false
            if IsValid(LocalPlayer()) then
                for _, bg in pairs(LocalPlayer():GetBodyGroups() or {}) do
                    local current = LocalPlayer():GetBodygroup(bg.id)
                    if current > 0 and bg.submodels and bg.submodels[current] then
                        local subName = string.lower(bg.submodels[current])
                        if string.find(subName, "backpack") or string.find(subName, "pack") or string.find(subName, "mochila") then
                            hasBackpack = true
                            break
                        end
                    end
                end
            end

            local slotNames = {"PRINCIPAL", "ESPECIAL", "SECUNDARIA"}
            local maxSlots = SW_InvShop.Config.MaxActiveSlots or 3
            
            local function CreateSlotBox(i, isAmmo)
                local slotBox = frame.SlotsColumn:Add("DPanel")
                slotBox:SetSize(80, 80)
                slotBox:Dock(TOP)
                slotBox:DockMargin(0, 0, 0, 12)
                slotBox.Paint = function(s, w, h)
                    draw.NoTexture()
                    
                    local colorOut = isAmmo and Color(255, 150, 0, 100) or Color(0, 195, 255, 100)
                    surface.SetDrawColor(colorOut)
                    local lw, lh = w - 1, h - 1
                    surface.DrawLine(0, 0, lw, 0)
                    surface.DrawLine(lw, 0, lw, lh - 15)
                    surface.DrawLine(lw, lh - 15, lw - 15, lh)
                    surface.DrawLine(lw - 15, lh, 0, lh)
                    surface.DrawLine(0, lh, 0, 0)
                    
                    local itemList = isAmmo and ammoItemsList or activeItemsList
                    if not itemList[i] then
                        local n = isAmmo and "MUNICIÓN" or (slotNames[i] or ("SLOT " .. i))
                        draw.SimpleText(n, "VF4_Small", w/2, h/2, Color(255, 255, 255, 30), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end

                slotBox:Receiver("SW_InventoryDragDrop", function(receiver, droppedPanels, bDoDrop)
                    if bDoDrop and droppedPanels[1] and droppedPanels[1].ItemID then
                        net.Start("SW_MoveItem")
                        net.WriteString(droppedPanels[1].ItemID)
                        net.WriteString("active")
                        net.SendToServer()
                    end
                end)

                local itemList = isAmmo and ammoItemsList or activeItemsList
                local currentItemID = itemList[i]
                if currentItemID then
                    local itemData = SW_InvShop.Config.Items[currentItemID]
                    if itemData then
                        local icon = vgui.Create("SpawnIcon", slotBox)
                        icon:Dock(FILL)
                        icon:SetModel(itemData.model)
                        icon:SetTooltip("Arrastra al baúl derecho para guardar.")
                        icon:Droppable("SW_InventoryDragDrop")
                        icon.ItemID = currentItemID
                        icon.OnCursorEntered = function() frame:UpdateInspector(currentItemID) end
                        
                        icon.DoRightClick = function()
                            local menu = DermaMenu()
                            local sellPrice = math.floor((itemData.price or 0) * 0.4)
                            menu:AddOption("Vender por " .. sellPrice .. " CR", function()
                                net.Start("SW_SellItem")
                                net.WriteString(currentItemID)
                                net.SendToServer()
                            end):SetIcon("icon16/money_delete.png")
                            menu:Open()
                        end
                    end
                end
            end

            -- Generar Slots de Armas
            for i = 1, maxSlots do
                CreateSlotBox(i, false)
            end
            
            -- Generar Slots de Munición
            local maxAmmoSlots = hasBackpack and 2 or 0
            for i = 1, maxAmmoSlots do
                CreateSlotBox(i, true)
            end

            -- Lógica visual del CINTURÓN (Belt)
            local function CreateBeltSlot(title, hasAmmo)
                local beltBox = frame.BeltColumn:Add("DPanel")
                beltBox:SetSize(80, 80)
                beltBox:Dock(TOP)
                beltBox:DockMargin(0, 0, 0, 12)
                beltBox.Paint = function(s, w, h)
                    draw.NoTexture()
                    
                    local colorOut = hasAmmo and Color(0, 255, 100, 100) or Color(255, 50, 50, 100)
                    surface.SetDrawColor(colorOut)
                    local lw, lh = w - 1, h - 1
                    surface.DrawLine(0, 0, lw, 0)
                    surface.DrawLine(lw, 0, lw, lh - 15)
                    surface.DrawLine(lw, lh - 15, lw - 15, lh)
                    surface.DrawLine(lw - 15, lh, 0, lh)
                    surface.DrawLine(0, lh, 0, 0)
                    
                    draw.SimpleText(title, "VF4_Small", w/2, 12, Color(255, 255, 255, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                    if hasAmmo then
                        draw.SimpleText("LLENO", "VF4_Medium", w/2, h/2 + 5, Color(0, 255, 100, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    else
                        draw.SimpleText("VACÍO", "VF4_Medium", w/2, h/2 + 5, Color(255, 50, 50, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end
            end

            local ply = LocalPlayer()
            local primaryCells = 0
            local secCells = 0
            local primaryEquipped = (ply:GetNW2Int("CellStatus_Primary", 0) > 0)
            local secEquipped = (ply:GetNW2Int("CellStatus_Secondary", 0) > 0)
            
            local foundPri = false
            local foundSec = false
            
            for k, wep in pairs(ply:GetWeapons()) do
                if wep.IsTFAWeapon and not (wep.IsSWSpecialWeapon and wep:IsSWSpecialWeapon()) then
                    local isSec = (wep.Slot == 1)
                    if not isSec then
                        local clipSize = wep:GetMaxClip1() > 0 and wep:GetMaxClip1() or 50
                        local resAmmo = ply:GetAmmoCount(wep:GetPrimaryAmmoType())
                        primaryCells = math.ceil(resAmmo / clipSize)
                        if wep:Clip1() > 0 then primaryEquipped = true end
                        foundPri = true
                    elseif isSec then
                        local clipSize = wep:GetMaxClip1() > 0 and wep:GetMaxClip1() or 50
                        local resAmmo = ply:GetAmmoCount(wep:GetPrimaryAmmoType())
                        secCells = math.ceil(resAmmo / clipSize)
                        if wep:Clip1() > 0 then secEquipped = true end
                        foundSec = true
                    end
                end
            end
            
            if not foundPri then primaryCells = ply:GetAmmoCount("ar2") > 0 and 2 or 0 end
            if not foundSec then secCells = ply:GetAmmoCount("pistol") > 0 and 1 or 0 end

            CreateBeltSlot("PRI - ARMA", primaryEquipped)
            CreateBeltSlot("PRI - RES 1", primaryCells >= 1)
            CreateBeltSlot("PRI - RES 2", primaryCells >= 2)
            
            CreateBeltSlot("SEC - ARMA", secEquipped)
            CreateBeltSlot("SEC - RES 1", secCells >= 1)

            local groupedArmario = {}
            local hasItems = false

            for itemID, qty in pairs(SW_InvShop.Armario or {}) do
                local itemData = SW_InvShop.Config.Items[itemID]
                if not itemData then continue end
                
                if not IsPlayerRightSide(LocalPlayer(), itemData) then continue end
                
                local cat = itemData.category or "General"
                if not groupedArmario[cat] then groupedArmario[cat] = {} end
                table.insert(groupedArmario[cat], { id = itemID, qty = qty, data = itemData })
                hasItems = true
            end

            if hasItems then
                local sortedCategories = {}
                for cat, _ in pairs(groupedArmario) do table.insert(sortedCategories, cat) end
                table.sort(sortedCategories)

                for _, cat in ipairs(sortedCategories) do
                    local items = groupedArmario[cat]

                    local catHeader = frame.ScrollArmario:Add("DPanel")
                    catHeader:Dock(TOP)
                    catHeader:SetTall(35)
                    catHeader:DockMargin(0, 0, 0, 12)
                    catHeader.Paint = function(s, w, h)
                        draw.SimpleText(SafeUpper(cat), "VF4_Medium", 0, h/2 - 2, K_Color_Green, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        surface.SetDrawColor(K_Color_Green.r, K_Color_Green.g, K_Color_Green.b, 40)
                        surface.DrawRect(0, h - 2, w, 2)
                    end

                    local catGrid = frame.ScrollArmario:Add("DIconLayout")
                    catGrid:Dock(TOP)
                    catGrid:SetSpaceX(15)
                    catGrid:SetSpaceY(15)
                    catGrid:DockMargin(0, 0, 0, 25)

                    for _, itemInfo in ipairs(items) do
                        local itemBlock = catGrid:Add("DPanel")
                        itemBlock:SetSize(85, 85)
                        itemBlock.HoverP = 0
                        itemBlock.Paint = function(s, w, h)
                            s.HoverP = Lerp(FrameTime() * 10, s.HoverP or 0, s:IsHovered() and 1 or 0)
                            draw.NoTexture()
                            surface.SetDrawColor(K_Color_Green.r, K_Color_Green.g, K_Color_Green.b, 50 + s.HoverP * 155)
                            local lw, lh = w - 1, h - 1
                            surface.DrawLine(0, 0, lw, 0)
                            surface.DrawLine(lw, 0, lw, lh - 15)
                            surface.DrawLine(lw, lh - 15, lw - 15, lh)
                            surface.DrawLine(lw - 15, lh, 0, lh)
                            surface.DrawLine(0, lh, 0, 0)
                            draw.SimpleText("x" .. itemInfo.qty, "VF4_Small", w - 8, h - 15, K_Color_Green, TEXT_ALIGN_RIGHT)
                        end

                        local icon = vgui.Create("SpawnIcon", itemBlock)
                        icon:SetSize(75, 75)
                        icon:Center()
                        icon:SetModel(itemInfo.data.model)
                        icon:SetTooltip("Arrastra a los slots de la izquierda para equipar.")
                        icon:Droppable("SW_InventoryDragDrop")
                        icon.ItemID = itemInfo.id

                        itemBlock.OnCursorEntered = function() frame:UpdateInspector(itemInfo.id) end
                        icon.OnCursorEntered = function() frame:UpdateInspector(itemInfo.id) end
                        
                        icon.DoRightClick = function()
                            local menu = DermaMenu()
                            local sellPrice = math.floor((itemInfo.data.price or 0) * 0.4)
                            menu:AddOption("Vender por " .. sellPrice .. " CR", function()
                                net.Start("SW_SellItem")
                                net.WriteString(itemInfo.id)
                                net.SendToServer()
                            end):SetIcon("icon16/money_delete.png")
                            menu:Open()
                        end
                    end
                end
            else
                local emptyMsg = frame.ScrollArmario:Add("DLabel")
                emptyMsg:SetText("EL ALMACÉN SE ENCUENTRA VACÍO O SIN ARMAS PARA TU FACCIÓN ACTUAL")
                emptyMsg:SetFont("VF4_Medium")
                emptyMsg:SetTextColor(Color(100, 110, 120))
                emptyMsg:Dock(TOP)
                emptyMsg:DockMargin(0, 60, 0, 0)
                emptyMsg:SetContentAlignment(5)
            end
        end
    elseif menuType == "vestimenta" then
        if v_bodygroups and v_bodygroups.PopulateOptions then
            v_bodygroups.PopulateOptions()
            
            local leftContainer = vgui.Create("DPanel", mainArea)
            leftContainer:SetWide(math.floor(ScrW() * 0.38))
            leftContainer:Dock(LEFT)
            leftContainer:DockMargin(0, 0, 20, 0)
            leftContainer.Paint = function(s, w, h)
                DrawElegantPanel(w, h, Color(46, 204, 113))
            end

            local modelContainer = vgui.Create("DPanel", leftContainer)
            modelContainer:Dock(FILL)
            modelContainer:DockMargin(15, 15, 15, 15)
            modelContainer.Paint = function() end

            local playerModel = vgui.Create("DModelPanel", modelContainer)
            playerModel:Dock(FILL)
            playerModel:SetModel(LocalPlayer():GetModel())
            playerModel:SetCamPos(Vector(80, 0, 42)) 
            playerModel:SetLookAt(Vector(0, 0, 36))
            playerModel:SetFOV(38)
            
            local ent = playerModel:GetEntity()
            if IsValid(ent) then
                playerModel.HeadBone = ent:LookupBone("ValveBiped.Bip01_Head1") 
                ent:SetSkin(LocalPlayer():GetSkin())
                for _, bg in ipairs(LocalPlayer():GetBodyGroups() or {}) do
                    ent:SetBodygroup(bg.id, LocalPlayer():GetBodygroup(bg.id))
                end
            end

            function playerModel:LayoutEntity(Entity)
                local anim = Entity:LookupSequence("idle_all_01") or 0
                if Entity:GetSequence() != anim then Entity:SetSequence(anim) end
                Entity:FrameAdvance(FrameTime())
                self:RunAnimation()
                if not self.HeadBone then return end
                local mouseX, mouseY = self:CursorPos()
                local w, h = self:GetSize()
                local inputX = (math.Clamp(mouseX, 0, w) / w) - 0.5
                local inputY = (math.Clamp(mouseY, 0, h) / h) - 0.5
                Entity:ManipulateBoneAngles(self.HeadBone, Angle(0, -inputY * 40, inputX * 45))
            end
            
            local btnVolver = vgui.Create("DButton", modelContainer)
            btnVolver:Dock(BOTTOM)
            btnVolver:SetTall(35)
            btnVolver:DockMargin(0, 10, 0, 0)
            btnVolver:SetText("VOLVER AL ARMARIO")
            btnVolver:SetFont("VF4_Small")
            btnVolver:SetTextColor(color_white)
            btnVolver.Paint = function(s, w, h)
                s.HoverP = Lerp(FrameTime() * 12, s.HoverP or 0, s:IsHovered() and 1 or 0)
                        if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                if s.HoverP > 0.01 then
                    draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
                end
                local tc = Lerp(s.HoverP, 255, 0)
                s:SetTextColor(Color(tc, tc, tc, 255))
            end
            btnVolver.DoClick = function()
                frame:Remove()
                SW_InvShop:OpenMainFrame("armario")
            end

            local optionsContainer = vgui.Create("DPanel", mainArea)
            optionsContainer:Dock(FILL)
            optionsContainer.Paint = function(s, w, h)
                DrawElegantPanel(w, h, Color(46, 204, 113))
            end
            
            local lblOpciones = vgui.Create("DLabel", optionsContainer)
            lblOpciones:SetText("PANEL DE CONFIGURACIÓN TÁCTICA")
            lblOpciones:SetFont("VF4_Medium")
            lblOpciones:SetTextColor(Color(46, 204, 113))
            lblOpciones:Dock(TOP)
            lblOpciones:DockMargin(25, 20, 20, 10)

            local scroll = vgui.Create("DScrollPanel", optionsContainer)
            scroll:Dock(FILL)
            scroll:DockMargin(25, 5, 25, 25)
            SkinModernScrollbar(scroll, Color(46, 204, 113))
            
            for _, opt in ipairs(v_bodygroups.Options) do
                local pnl = scroll:Add("DPanel")
                pnl:Dock(TOP)
                pnl:SetTall(50)
                pnl:DockMargin(0, 0, 0, 10)
                pnl.Paint = function(s, w, h)
                    surface.SetDrawColor(255, 255, 255, 10)
                    surface.DrawOutlinedRect(0, 0, w, h)
                    draw.SimpleText(SafeUpper(opt.title), "VF4_Medium", 15, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                
                local combo = vgui.Create("DComboBox", pnl)
                combo:Dock(RIGHT)
                combo:SetWide(200)
                combo:DockMargin(10, 10, 10, 10)
                combo:SetValue(opt.title == "Modelo del Trabajo" and (opt.val + 1) or opt.val)
                combo.Paint = function(s, w, h)
                    surface.SetDrawColor(0, 0, 0, 200)
                    surface.DrawRect(0, 0, w, h)
                    surface.SetDrawColor(255, 255, 255, 50)
                    surface.DrawOutlinedRect(0, 0, w, h)
                    draw.SimpleText(s:GetText(), "VF4_Small", 10, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                
                for j = 0, opt.max - 1 do
                    combo:AddChoice(tostring(j + (opt.title == "Modelo del Trabajo" and 1 or 0)), j)
                end
                
                combo.OnSelect = function(self, index, value, data)
                    local isLocked = false
                    if opt.title ~= "Modelo del Trabajo" and opt.title ~= "Variante de Skin" and SW_InvShop and SW_InvShop.HasBodygroupAccess then
                        local bgName = LocalPlayer():GetBodygroupName(opt.bgIndex)
                        local subName = ""
                        for _, bg in pairs(LocalPlayer():GetBodyGroups() or {}) do
                            if bg.id == opt.bgIndex then
                                subName = bg.submodels and bg.submodels[data] or ""
                                break
                            end
                        end
                        if not SW_InvShop.HasBodygroupAccess(LocalPlayer(), bgName, subName) then
                            isLocked = true
                        end
                    end
                    
                    if isLocked then
                        chat.AddText(Color(255,50,50), "No tienes acceso a esta variante.")
                        self:SetValue(opt.title == "Modelo del Trabajo" and (opt.val + 1) or opt.val)
                        return
                    end
                    
                    opt.val = data
                    opt.onUpdate(data)
                    
                    if IsValid(playerModel.Entity) then
                        if opt.title == "Modelo del Trabajo" then
                            playerModel:SetModel(LocalPlayer():GetModel())
                        elseif opt.title == "Variante de Skin" then
                            playerModel.Entity:SetSkin(data)
                        else
                            playerModel.Entity:SetBodygroup(opt.bgIndex, data)
                        end
                    end
                end
            end
            
            -- Guardar Preset y Cargar Preset
            local pnlPresets = scroll:Add("DPanel")
            pnlPresets:Dock(TOP)
            pnlPresets:SetTall(50)
            pnlPresets:DockMargin(0, 20, 0, 10)
            pnlPresets.Paint = function() end
            
            local btnSave = vgui.Create("DButton", pnlPresets)
            btnSave:Dock(LEFT)
            btnSave:SetWide(250)
            btnSave:SetText("GUARDAR COMBINACIÓN")
            btnSave:SetFont("VF4_Small")
            btnSave:SetTextColor(color_white)
            btnSave.Paint = function(s, w, h)
                s.HoverP = Lerp(FrameTime() * 12, s.HoverP or 0, s:IsHovered() and 1 or 0)
                        if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                if s.HoverP > 0.01 then
                    draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
                end
                local tc = Lerp(s.HoverP, 255, 0)
                s:SetTextColor(Color(tc, tc, tc, 255))
            end
            btnSave.DoClick = function()
                LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                local ply = LocalPlayer()
                local currentOutfit = { skin = ply:GetSkin(), bgs = {} }
                for i = 0, ply:GetNumBodyGroups() - 1 do currentOutfit.bgs[i] = ply:GetBodygroup(i) end
                local modelClean = string.gsub(string.lower(ply:GetModel()), "[/%s%.]", "_")
                if not file.Exists("v_bodygroups", "DATA") then file.CreateDir("v_bodygroups") end
                file.Write("v_bodygroups/" .. modelClean .. ".txt", util.TableToJSON(currentOutfit))
                chat.AddText(Color(46, 204, 113), "[Vestimenta] ¡Combinación guardada!")
            end
            
            local btnLoad = vgui.Create("DButton", pnlPresets)
            btnLoad:Dock(RIGHT)
            btnLoad:SetWide(250)
            btnLoad:SetText("CARGAR DATOS")
            btnLoad:SetFont("VF4_Small")
            btnLoad:SetTextColor(color_white)
            btnLoad.Paint = function(s, w, h)
                s.HoverP = Lerp(FrameTime() * 12, s.HoverP or 0, s:IsHovered() and 1 or 0)
                        if s:IsHovered() and not s._playHover then s._playHover = true; LocalPlayer():EmitSound("navigation/movimiento.wav", 75, 100, 0.5) elseif not s:IsHovered() then s._playHover = false end
                draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 80))
                if s.HoverP > 0.01 then
                    draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, s.HoverP * 255))
                end
                local tc = Lerp(s.HoverP, 255, 0)
                s:SetTextColor(Color(tc, tc, tc, 255))
            end
            btnLoad.DoClick = function()
                local ply = LocalPlayer()
                local modelClean = string.gsub(string.lower(ply:GetModel()), "[/%s%.]", "_")
                local filePath = "v_bodygroups/" .. modelClean .. ".txt"
                if not file.Exists(filePath, "DATA") then
                    surface.PlaySound("common/wpn_denyselect.wav")
                    chat.AddText(Color(236, 59, 59), "[Vestimenta] No tienes presets para este modelo.")
                    return
                end
                local savedData = file.Read(filePath, "DATA")
                local outfit = util.JSONToTable(savedData)
                if outfit then
                    LocalPlayer():EmitSound("navigation/aceptar.wav", 75, 100, 0.5)
                    net.Start("v_bodygroups_Update")
                        net.WriteString("preset")
                        net.WriteInt(0, 8) 
                        net.WriteInt(0, 8) 
                        net.WriteString(ply:GetModel()) 
                        net.WriteString(savedData)
                    net.SendToServer()
                    if outfit.skin then ply:SetSkin(outfit.skin) end
                    if outfit.bgs then
                        for bgID, val in pairs(outfit.bgs) do
                            ply:SetBodygroup(tonumber(bgID), tonumber(val))
                        end
                    end
                    frame:Remove()
                    SW_InvShop:OpenMainFrame("vestimenta")
                    chat.AddText(Color(34, 255, 144), "[Vestimenta] ¡Preset aplicado!")
                end
            end
        else
            local errorLbl = vgui.Create("DLabel", mainArea)
            errorLbl:SetText("EL MÓDULO DE VESTIMENTA (BODYGROUPS) NO ESTÁ INSTALADO O ACTIVO.")
            errorLbl:SetFont("VF4_TitleBig")
            errorLbl:SetTextColor(Color(255, 50, 50))
            errorLbl:Dock(FILL)
            errorLbl:SetContentAlignment(5)
        end
    end

    if frame.Refresh then frame:Refresh() end
end

net.Receive("SW_OpenArmarioMenu", function()
    local armEnt = net.ReadEntity()
    if IsValid(SW_InvShop.MainMenu) then SW_InvShop.MainMenu:Remove() end
    if IsValid(armEnt) and armEnt:GetClass() == "sw_armario" and SW_InvShop.Open3DArmario then
        SW_InvShop:Open3DArmario(armEnt)
    else
        SW_InvShop:OpenMainFrame("armario")
    end
end)

net.Receive("SW_OpenShopMenu", function()
    local shopEnt = net.ReadEntity()
    if IsValid(SW_InvShop.MainMenu) then SW_InvShop.MainMenu:Remove() end
    if IsValid(shopEnt) and shopEnt:GetClass() == "sw_tienda" and SW_InvShop.Open3DShop then
        SW_InvShop:Open3DShop(shopEnt, false)
    else
        SW_InvShop:OpenMainFrame("tienda")
    end
end)

net.Receive("SW_OpenBlackMarketMenu", function()
    local shopEnt = net.ReadEntity()
    if IsValid(SW_InvShop.MainMenu) then SW_InvShop.MainMenu:Remove() end
    if IsValid(shopEnt) and shopEnt:GetClass() == "sw_tienda_cr" and SW_InvShop.Open3DShop then
        SW_InvShop:Open3DShop(shopEnt, true)
    else
        SW_InvShop:OpenMainFrame("blackmarket")
    end
end)

net.Receive("SW_SyncData", function()
    SW_InvShop.ActiveInv = net.ReadTable()
    SW_InvShop.Armario = net.ReadTable()
    if IsValid(SW_InvShop.MainMenu) then
        SW_InvShop.MainMenu:Refresh()
    end
    hook.Run("SW_InventorySynced")
end)

net.Receive("SW_OpenAmmoShopMenu", function()
    if IsValid(SW_InvShop.MainMenu) then SW_InvShop.MainMenu:Remove() end
    SW_InvShop:OpenMainFrame("ammoshop")
end)





