--[[
    Panel Unificado del Menú Contextual (C)
    Oculta los iconos por defecto y crea un botón único que abre un panel con los accesos seleccionados.
]]

surface.CreateFont("PanelUnificado_Font", { font = "Montserrat", size = 18, weight = 700, antialias = true })

surface.CreateFont("PanelUnificado_BtnFont", { font = "Montserrat", size = 15, weight = 600, antialias = true })

local customMenuBtn = nil
local CustomMainPanel = nil

CreateClientConVar("virtus_hud_bg", "10 15 20 160", true, false)



local function OpenCustomPanel()
    if IsValid(CustomMainPanel) then CustomMainPanel:Remove() end
    
    local allWindows = list.Get("DesktopWindows")
    if not allWindows then return end
    
    CustomMainPanel = vgui.Create("DFrame", g_ContextMenu)
    CustomMainPanel:SetSize(400, 350)
    CustomMainPanel:Center()
    CustomMainPanel:SetTitle("")
    CustomMainPanel:MakePopup()
    CustomMainPanel:ShowCloseButton(false)
    CustomMainPanel:DockPadding(0, 0, 0, 0)
    CustomMainPanel.Paint = function(self, w, h)
        _G.VIRTUS_DrawHoloBackground(w, h)
        draw.SimpleText('SISTEMA TACTICO', 'PanelUnificado_Font', 20, 25, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(Color(255, 255, 255, 10))
        surface.DrawRect(20, 42, w - 40, 1)
    end
    
    local scroll = vgui.Create("DScrollPanel", CustomMainPanel)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 55, 10, 15)
    
    -- Filtramos solo las opciones que queremos
    local targetKeywords = {
        "lvs",
        "wos",
        "dynabase",
        "wiltos",
        "viewer",
        "third person",
        "music",
        "musica",
        "música"
    }
    
    local addedAny = false
    
    for k, wdgt in pairs(allWindows) do
        local title = wdgt.title or ""
        local titleLower = string.lower(title)
        
        local isTarget = false
        for _, keyword in ipairs(targetKeywords) do
            if string.find(titleLower, keyword) then
                isTarget = true
                break
            end
        end
        
        if isTarget then
            addedAny = true
            
            local btn = scroll:Add("DButton")
            btn:Dock(TOP)
            btn:SetTall(36)
            btn:DockMargin(15, 6, 15, 2)
            btn:SetText("")
            
            local matIcon = nil
            if wdgt.icon then
                matIcon = Material(wdgt.icon)
            end
            
            btn.Paint = function(self, w, h)
                local hover = self:IsHovered()
                _G.VIRTUS_DrawHoloButton(w, h, hover, self)
                if matIcon and not matIcon:IsError() then
                    surface.SetDrawColor(color_white)
                    surface.SetMaterial(matIcon)
                    surface.DrawTexturedRect(12, h/2 - 10, 20, 20)
                end
                draw.SimpleText(string.upper(title), 'PanelUnificado_BtnFont', wdgt.icon and 42 or 15, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            
            btn.DoClick = function()
                -- Lógica nativa del menú de spawn para abrir estas ventanas
                if wdgt.onewindow and IsValid(btn.Window) then
                    btn.Window:Center()
                    return
                end
                
                if IsValid(btn.Window) and btn.Window:GetParent() ~= g_ContextMenu then
                    btn.Window:Remove()
                end
                
                local newWdgt = list.GetEntry("DesktopWindows", k) or wdgt
                
                btn.Window = g_ContextMenu:Add("DFrame")
                btn.Window:SetSize(newWdgt.width or 800, newWdgt.height or 600)
                                btn.Window:SetTitle("")
                btn.Window:ShowCloseButton(false)
                btn.Window:DockPadding(0, 0, 0, 0)
                btn.Window:Center()
                
                if newWdgt.init then
                    newWdgt.init(btn, btn.Window)
                end

                local customClose = vgui.Create("DButton", btn.Window)
                customClose:SetSize(40, 40)
                customClose:SetPos(btn.Window:GetWide() - 40, 0)
                customClose:SetZPos(32767)
                customClose:SetText("")
                customClose.Paint = function(s, w, h)
                    if _G.VIRTUS_DrawHoloCloseButton then _G.VIRTUS_DrawHoloCloseButton(w, h, s:IsHovered()) end
                end
                local theWindow = btn.Window
                customClose.DoClick = function()
                    if IsValid(theWindow) then theWindow:Remove() end
                end
                
                -- FIX: Algunos addons como LVS crean su propia ventana dentro de init y dejan esta ventana en blanco.
                -- Si el init no agregó nada a nuestra ventana generada, o si es de LVS, la borramos.
                if string.find(titleLower, "lvs") and IsValid(btn.Window) then
                    btn.Window:Remove()
                end
                
                CustomMainPanel:Remove() -- Cierra nuestro menú
            end
        end
    end
    
    if not addedAny then
        local lbl = scroll:Add("DLabel")
        lbl:Dock(TOP)
        lbl:SetText("No se encontraron los paneles especificados.")
        lbl:SetContentAlignment(5)
        lbl:SetTextColor(Color(255, 100, 100))
        lbl:SetTall(50)
    end
end

-- Hook para ocultar la barra lateral por defecto y crear el cuadrado
hook.Add("ContextMenuOpened", "Custom_C_Menu_Logic", function()
    if IsValid(g_ContextMenu) then
        if IsValid(g_ContextMenu.DesktopWidgets) then
            g_ContextMenu.DesktopWidgets:SetVisible(false)
        end
        
        if not IsValid(customMenuBtn) then
            customMenuBtn = vgui.Create("DButton", g_ContextMenu)
            customMenuBtn:SetSize(220, 40)
            customMenuBtn:SetPos(20, 110) -- Se bajó un poco respecto a (20, 20)
            customMenuBtn:SetText("")
            
            customMenuBtn.Paint = function(self, w, h)
                local hover = self:IsHovered()
                if _G.VIRTUS_DrawHoloButton then _G.VIRTUS_DrawHoloButton(w, h, hover, self) end
                draw.SimpleText("PANEL PRINCIPAL", "PanelUnificado_Font", 15, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            
            customMenuBtn.DoClick = function()
                OpenCustomPanel()
            end
        end
        
        if IsValid(customMenuBtn) then
            customMenuBtn:SetVisible(true)
        end
    end
end)

-- Asegurarnos de limpiar si el menú se cierra
hook.Add("ContextMenuClosed", "Custom_C_Menu_Close", function()
    if IsValid(CustomMainPanel) then
        CustomMainPanel:Remove()
    end
end)







if IsValid(customMenuBtn) then customMenuBtn:Remove() end

















