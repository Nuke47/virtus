VIRTUS_CHAT = VIRTUS_CHAT or {}

function VIRTUS_CHAT.OpenRankConfigMenu()
    print("[Virtus] OpenRankConfigMenu called!")
    if IsValid(VIRTUS_CHAT.RankConfigFrame) then
        VIRTUS_CHAT.RankConfigFrame:Remove()
    end

    local w, h = 400, 500
    local frame = vgui.Create("DFrame")
    frame:SetSize(w, h)
    frame:Center()
    frame:SetTitle("Configuración de Rangos (Servidor)")
    frame:MakePopup()
    VIRTUS_CHAT.RankConfigFrame = frame

    frame.Paint = function(self, pw, ph)
        VIRTUS_CHAT.DrawBlur(self, 8)
        draw.NoTexture()
        local bgC = VIRTUS_CHAT.Colors.Background
        surface.SetDrawColor(bgC.r, bgC.g, bgC.b, bgC.a)
        local bg_poly = { {x=0, y=0}, {x=pw, y=0}, {x=pw, y=ph-10}, {x=pw-10, y=ph}, {x=0, y=ph} }
        surface.DrawPoly(bg_poly)
        
        surface.SetDrawColor(190, 180, 190, 8)
        for k = 2, ph - 2, 4 do surface.DrawLine(0, k, pw, k) end
        
        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawRect(0, 0, pw, 25)
        local tA = VIRTUS_CHAT.Colors.TabActive
        surface.SetDrawColor(tA.r, tA.g, tA.b, 150)
        surface.DrawRect(0, 25, pw, 1)
        
        local outC = VIRTUS_CHAT.Colors.Outline
        surface.SetDrawColor(outC.r, outC.g, outC.b, outC.a)
        surface.DrawLine(0, 0, pw, 0)
        surface.DrawLine(pw, 0, pw, ph - 10)
        surface.DrawLine(pw, ph - 10, pw - 10, ph)
        surface.DrawLine(pw - 10, ph, 0, ph)
        surface.DrawLine(0, ph, 0, 0)
        
        surface.SetDrawColor(tA.r, tA.g, tA.b, 200)
        surface.DrawRect(0, 0, 8, 2)
        surface.DrawRect(0, 0, 2, 8)
        surface.DrawRect(pw - 8, 0, 8, 2)
        surface.DrawRect(pw - 2, 0, 2, 8)

        draw.SimpleTextOutlined("Configuración de Rangos (Servidor)", "DermaDefaultBold", 8, 12, VIRTUS_CHAT.Colors.InputText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 200))
    end

    -- Copia local de la configuración
    local localConfig = table.Copy(VIRTUS_CHAT_CONFIG or {})

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)

    local function Populate()
        scroll:Clear()
        
        for groupID, data in pairs(localConfig) do
            if type(data) ~= "table" then continue end
            
            local pnl = vgui.Create("DPanel", scroll)
            pnl:Dock(TOP)
            pnl:SetTall(80)
            pnl:DockMargin(0, 0, 0, 5)
            pnl.Paint = function(self, pw, ph)
                draw.RoundedBox(4, 0, 0, pw, ph, Color(0,0,0,100))
                draw.SimpleText("ID Rango: " .. tostring(groupID), "DermaDefaultBold", 5, 5, Color(255,255,255))
            end

            local nameLabel = vgui.Create("DLabel", pnl)
            nameLabel:SetPos(5, 25)
            nameLabel:SetText("Texto Visible del Tag:")
            nameLabel:SizeToContents()

            local nameEntry = vgui.Create("DTextEntry", pnl)
            nameEntry:SetPos(5, 45)
            nameEntry:SetSize(120, 20)
            nameEntry:SetText(tostring(data.name or groupID))
            nameEntry.OnChange = function(self)
                localConfig[groupID].name = self:GetText()
            end

            local cMixer = vgui.Create("DColorMixer", pnl)
            cMixer:SetPos(135, 5)
            cMixer:SetSize(150, 70)
            cMixer:SetPalette(false)
            cMixer:SetAlphaBar(false)
            cMixer:SetWangs(false)
            if data.color and type(data.color) == "table" then
                cMixer:SetColor(Color(tonumber(data.color.r) or 255, tonumber(data.color.g) or 255, tonumber(data.color.b) or 255))
            end
            cMixer.ValueChanged = function(self, col)
                localConfig[groupID].color = {r = col.r, g = col.g, b = col.b}
            end

            local checkGlow = vgui.Create("DCheckBoxLabel", pnl)
            checkGlow:SetPos(295, 10)
            checkGlow:SetText("Efecto Destello")
            checkGlow:SetValue(tobool(data.glow))
            checkGlow.OnChange = function(self, val)
                localConfig[groupID].glow = val
            end

            local btnDel = vgui.Create("DButton", pnl)
            btnDel:SetPos(295, 35)
            btnDel:SetSize(60, 20)
            btnDel:SetText("Eliminar")
            btnDel.DoClick = function()
                localConfig[groupID] = nil
                Populate()
            end
        end
    end

    Populate()

    local bottomPnl = vgui.Create("DPanel", frame)
    bottomPnl:Dock(BOTTOM)
    bottomPnl:SetTall(30)
    bottomPnl:DockMargin(10, 0, 10, 10)
    bottomPnl.Paint = function() end

    local newIDEntry = vgui.Create("DTextEntry", bottomPnl)
    newIDEntry:Dock(LEFT)
    newIDEntry:SetWide(130)
    newIDEntry:SetPlaceholderText("Rango o SteamID...")

    local btnAdd = vgui.Create("DButton", bottomPnl)
    btnAdd:Dock(LEFT)
    btnAdd:DockMargin(5, 0, 0, 0)
    btnAdd:SetText("Añadir")
    btnAdd.DoClick = function()
        local rawTxt = string.Trim(newIDEntry:GetValue())
        if rawTxt == "" then return end
        
        local txt = string.lower(rawTxt)
        -- Si parece un SteamID, mantenerlo en mayúsculas
        if string.match(txt, "^steam_%d:%d:%d+$") then
            txt = string.upper(txt)
        end
        
        if not localConfig[txt] then
            localConfig[txt] = { name = string.upper(txt), color = {r=255, g=255, b=255} }
            newIDEntry:SetText("")
            Populate()
        end
    end

    local btnSave = vgui.Create("DButton", bottomPnl)
    btnSave:Dock(RIGHT)
    btnSave:SetWide(80)
    btnSave:SetText("Guardar Red")
    btnSave.DoClick = function()
        net.Start("VirtusChat_SaveConfig")
        net.WriteTable(localConfig)
        net.SendToServer()
        frame:Close()
    end
end

function VIRTUS_CHAT.OpenConfigMenu()
    print("[Virtus] OpenConfigMenu called!")
    if IsValid(VIRTUS_CHAT.ConfigFrame) then
        VIRTUS_CHAT.ConfigFrame:Remove()
    end

    local w, h = 300, 180
    local frame = vgui.Create("DFrame")
    frame:SetSize(w, h)
    frame:Center()
    frame:SetTitle("Ajustes Locales del Chat")
    frame:MakePopup()
    VIRTUS_CHAT.ConfigFrame = frame

    frame.Paint = function(self, pw, ph)
        VIRTUS_CHAT.DrawBlur(self, 8)
        draw.NoTexture()
        local bgC = VIRTUS_CHAT.Colors.Background
        surface.SetDrawColor(bgC.r, bgC.g, bgC.b, bgC.a)
        local bg_poly = { {x=0, y=0}, {x=pw, y=0}, {x=pw, y=ph-10}, {x=pw-10, y=ph}, {x=0, y=ph} }
        surface.DrawPoly(bg_poly)
        
        surface.SetDrawColor(190, 180, 190, 8)
        for k = 2, ph - 2, 4 do surface.DrawLine(0, k, pw, k) end
        
        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawRect(0, 0, pw, 25)
        local tA = VIRTUS_CHAT.Colors.TabActive
        surface.SetDrawColor(tA.r, tA.g, tA.b, 150)
        surface.DrawRect(0, 25, pw, 1)
        
        local outC = VIRTUS_CHAT.Colors.Outline
        surface.SetDrawColor(outC.r, outC.g, outC.b, outC.a)
        surface.DrawLine(0, 0, pw, 0)
        surface.DrawLine(pw, 0, pw, ph - 10)
        surface.DrawLine(pw, ph - 10, pw - 10, ph)
        surface.DrawLine(pw - 10, ph, 0, ph)
        surface.DrawLine(0, ph, 0, 0)
        
        surface.SetDrawColor(tA.r, tA.g, tA.b, 200)
        surface.DrawRect(0, 0, 8, 2)
        surface.DrawRect(0, 0, 2, 8)
        surface.DrawRect(pw - 8, 0, 8, 2)
        surface.DrawRect(pw - 2, 0, 2, 8)

        draw.SimpleTextOutlined("Ajustes Locales del Chat", "DermaDefaultBold", 8, 12, VIRTUS_CHAT.Colors.InputText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 200))
    end

    local currentScale = cookie.GetNumber("VirtusChat_Scale", 1)

    local scaleSlider = vgui.Create("DNumSlider", frame)
    scaleSlider:SetPos(15, 40)
    scaleSlider:SetSize(270, 40)
    scaleSlider:SetText("Escala del Texto")
    scaleSlider:SetMin(0.5)
    scaleSlider:SetMax(2.0)
    scaleSlider:SetDecimals(2)
    scaleSlider:SetValue(currentScale)

    local btnApply = vgui.Create("DButton", frame)
    btnApply:SetPos(15, 90)
    btnApply:SetSize(270, 30)
    btnApply:SetText("Aplicar Escala")
    btnApply.DoClick = function()
        local newScale = scaleSlider:GetValue()
        cookie.Set("VirtusChat_Scale", tostring(newScale))
        VIRTUS_CHAT.UpdateFonts(newScale)
        chat.AddText(Color(0, 255, 0), "Escala aplicada. El cambio se verá reflejado en los mensajes nuevos.")
        if VIRTUS_CHAT.RefreshMessages then
            timer.Simple(0.1, function() VIRTUS_CHAT.RefreshMessages() end)
        end
    end

    if LocalPlayer():IsSuperAdmin() then
        h = 230
        frame:SetSize(w, h)
        local btnAdmin = vgui.Create("DButton", frame)
        btnAdmin:SetPos(15, 135)
        btnAdmin:SetSize(270, 30)
        btnAdmin:SetText("Abrir Configuración de Servidor")
        btnAdmin:SetTextColor(Color(255, 100, 100))
        btnAdmin.DoClick = function()
            print("[Virtus] Opening Rank Config Menu!")
            VIRTUS_CHAT.OpenRankConfigMenu()
            frame:Close()
        end
    end
end
