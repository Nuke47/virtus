if not CLIENT then return end

surface.CreateFont("Datapad_DocsTitle", {
    font = "Courier New",
    size = 24,
    weight = 800,
})

surface.CreateFont("Datapad_DocsText", {
    font = "Courier New",
    size = 18,
    weight = 500,
})

net.Receive("IVO_Docs_OpenConsoleUI", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end
    
    local isEditing = false
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 500)
    frame:SetTitle("")
    frame:Center()
    frame:MakePopup()
    
    local blur = Material("pp/blurscreen")
    local function DrawBlur(panel, amount)
        local x, y = panel:LocalToScreen(0, 0)
        local scrW, scrH = ScrW(), ScrH()
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(blur)
        for i = 1, 3 do
            blur:SetFloat("$blur", (i / 3) * (amount or 6))
            blur:Recompute()
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
        end
    end

    frame.Paint = function(self, w, h)
        DrawBlur(self, 4)
        draw.RoundedBox(12, 0, 0, w, h, Color(15, 20, 25, 220))
        surface.SetDrawColor(0, 150, 255, 50)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        local headerText = isEditing and "SISTEMA DE REDACCIÓN DE ARCHIVOS" or "PANEL DE EXTRACCIÓN DE DATOS"
        draw.SimpleText(headerText, "Datapad_DocsTitle", 20, 15, Color(0, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(0, 200, 255, 100)
        surface.DrawLine(20, 45, w - 20, 45)
    end
    
    -- Botón de Admin (Configuración)
    if LocalPlayer():IsSuperAdmin() then
        local btnAdmin = vgui.Create("DButton", frame)
        btnAdmin:SetSize(30, 30)
        btnAdmin:SetPos(frame:GetWide() - 40, 10)
        btnAdmin:SetText("")
        btnAdmin.Paint = function(self, w, h)
            if self:IsHovered() then
                surface.SetDrawColor(255, 255, 255, 255)
            else
                surface.SetDrawColor(150, 150, 150, 200)
            end
            surface.SetMaterial(Material("icon16/cog.png"))
            surface.DrawTexturedRect(7, 7, 16, 16)
        end
        btnAdmin.DoClick = function()
            if IVO_Docs_OpenAdminConfig then IVO_Docs_OpenAdminConfig(ent) end
            frame:Close()
        end
        
        -- Botón de Editar Texto
        local btnEdit = vgui.Create("DButton", frame)
        btnEdit:SetSize(30, 30)
        btnEdit:SetPos(frame:GetWide() - 75, 10)
        btnEdit:SetText("")
        btnEdit.Paint = function(self, w, h)
            if self:IsHovered() then
                surface.SetDrawColor(255, 255, 255, 255)
            else
                surface.SetDrawColor(150, 150, 150, 200)
            end
            surface.SetMaterial(Material("icon16/page_edit.png"))
            surface.DrawTexturedRect(7, 7, 16, 16)
        end
        btnEdit.DoClick = function()
            isEditing = not isEditing
            frame:RebuildUI()
        end
    end
    
    local container = vgui.Create("DPanel", frame)
    container:SetPos(20, 60)
    container:SetSize(560, 420)
    container.Paint = function() end
    
    function frame:RebuildUI()
        container:Clear()
        
        if isEditing then
            -- MODO EDICIÓN (SOLO ADMINS)
            local lblTitle = vgui.Create("DLabel", container)
            lblTitle:SetPos(0, 0)
            lblTitle:SetText("TÍTULO DEL DOCUMENTO:")
            lblTitle:SetFont("Datapad_DocsText")
            lblTitle:SetTextColor(Color(100, 200, 255))
            lblTitle:SizeToContents()
            
            local txtTitle = vgui.Create("DTextEntry", container)
            txtTitle:SetPos(0, 25)
            txtTitle:SetSize(560, 40)
            txtTitle:SetFont("Datapad_DocsTitle")
            txtTitle:SetDrawLanguageID(false)
            txtTitle:SetText(ent:GetDocTitle() or "")
            txtTitle:SetTextColor(Color(255, 255, 255))
            txtTitle:SetCursorColor(Color(0, 150, 255))
            txtTitle.Paint = function(self, w, h)
                draw.RoundedBox(8, 0, 0, w, h, Color(0, 20, 30, 200))
                if self:HasFocus() then
                    surface.SetDrawColor(0, 200, 255, 150)
                else
                    surface.SetDrawColor(0, 150, 255, 50)
                end
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                self:DrawTextEntryText(Color(255, 255, 255), Color(0, 150, 255), Color(255, 255, 255))
            end
            
            local lblContent = vgui.Create("DLabel", container)
            lblContent:SetPos(0, 80)
            lblContent:SetText("CONTENIDO CONFIDENCIAL:")
            lblContent:SetFont("Datapad_DocsText")
            lblContent:SetTextColor(Color(100, 200, 255))
            lblContent:SizeToContents()
            
            local txtContent = vgui.Create("DTextEntry", container)
            txtContent:SetPos(0, 105)
            txtContent:SetSize(560, 255)
            txtContent:SetMultiline(true)
            txtContent:SetFont("Datapad_DocsText")
            txtContent:SetDrawLanguageID(false)
            txtContent:SetText(ent:GetDocContent() or "")
            txtContent:SetTextColor(Color(200, 200, 200))
            txtContent:SetCursorColor(Color(0, 150, 255))
            txtContent.Paint = function(self, w, h)
                draw.RoundedBox(8, 0, 0, w, h, Color(0, 20, 30, 200))
                if self:HasFocus() then
                    surface.SetDrawColor(0, 200, 255, 150)
                else
                    surface.SetDrawColor(0, 150, 255, 50)
                end
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                self:DrawTextEntryText(Color(255, 255, 255), Color(0, 150, 255), Color(255, 255, 255))
            end
            
            local btnSave = vgui.Create("DButton", container)
            btnSave:SetPos(0, 375)
            btnSave:SetSize(560, 45)
            btnSave:SetText("GUARDAR CONTENIDO EN LA CONSOLA")
            btnSave:SetFont("Datapad_DocsTitle")
            btnSave:SetTextColor(Color(255, 255, 255))
            btnSave.Paint = function(self, w, h)
                if self:IsHovered() then
                    draw.RoundedBox(8, 0, 0, w, h, Color(0, 150, 50, 200))
                    surface.SetDrawColor(0, 255, 50, 255)
                else
                    draw.RoundedBox(8, 0, 0, w, h, Color(0, 100, 50, 150))
                    surface.SetDrawColor(0, 255, 50, 100)
                end
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            btnSave.DoClick = function()
                net.Start("IVO_Docs_AdminSaveContent")
                net.WriteEntity(ent)
                net.WriteString(string.Trim(txtTitle:GetText()))
                net.WriteString(string.Trim(txtContent:GetText()))
                net.SendToServer()
                isEditing = false
                frame:RebuildUI()
            end
        else
            -- MODO PREVIEW / EXTRACCIÓN (TODOS)
            if ent:GetIsDownloading() then
                local lblWait = vgui.Create("DLabel", container)
                lblWait:SetText("LA CONSOLA SE ENCUENTRA ACTUALMENTE\nEN UN PROCESO DE EXTRACCIÓN.")
                lblWait:SetFont("Datapad_DocsTitle")
                lblWait:SetTextColor(Color(255, 100, 100))
                lblWait:SizeToContents()
                lblWait:Center()
                return
            end
            
            local lblFile = vgui.Create("DLabel", container)
            lblFile:SetPos(0, 0)
            lblFile:SetText("ARCHIVO ENCONTRADO:")
            lblFile:SetFont("Datapad_DocsText")
            lblFile:SetTextColor(Color(100, 200, 255))
            lblFile:SizeToContents()
            
            local titleText = ent:GetDocTitle() or "DESCONOCIDO"
            local lblTitle = vgui.Create("DLabel", container)
            lblTitle:SetPos(0, 25)
            lblTitle:SetText(titleText)
            lblTitle:SetFont("Datapad_DocsTitle")
            lblTitle:SetTextColor(Color(255, 255, 255))
            lblTitle:SizeToContents()
            
            local lblPreviewLabel = vgui.Create("DLabel", container)
            lblPreviewLabel:SetPos(0, 80)
            lblPreviewLabel:SetText("VISTA PREVIA DEL CONTENIDO:")
            lblPreviewLabel:SetFont("Datapad_DocsText")
            lblPreviewLabel:SetTextColor(Color(100, 200, 255))
            lblPreviewLabel:SizeToContents()
            
            local fullContent = ent:GetDocContent() or ""
            local previewContent = string.sub(fullContent, 1, 80)
            if string.len(fullContent) > 80 then
                previewContent = previewContent .. "...\n\n[RESTO DEL DOCUMENTO ENCRIPTADO]\n[REQUIERE EXTRACCIÓN FÍSICA AL DATAPAD PARA LECTURA COMPLETA]"
            end
            
            local lblPreview = vgui.Create("DLabel", container)
            lblPreview:SetPos(0, 110)
            lblPreview:SetSize(560, 200)
            lblPreview:SetText(previewContent)
            lblPreview:SetFont("Datapad_DocsText")
            lblPreview:SetTextColor(Color(200, 200, 200))
            lblPreview:SetWrap(true)
            lblPreview:SetContentAlignment(7)
            
            local hasDatapad = LocalPlayer():HasWeapon("weapon_ivo_datapad")
            
            local btnDownload = vgui.Create("DButton", container)
            btnDownload:SetPos(0, 350)
            btnDownload:SetSize(560, 70)
            btnDownload:SetText(hasDatapad and "INICIAR EXTRACCIÓN DE DATOS" or "NO TIENES UN DATAPAD EQUIPADO")
            btnDownload:SetFont("Datapad_DocsTitle")
            btnDownload:SetTextColor(Color(255, 255, 255))
            btnDownload:SetEnabled(hasDatapad)
            btnDownload.Paint = function(self, w, h)
                if not self:IsEnabled() then
                    draw.RoundedBox(8, 0, 0, w, h, Color(50, 0, 0, 150))
                    surface.SetDrawColor(150, 0, 0, 100)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    return
                end
                
                if self:IsHovered() then
                    draw.RoundedBox(8, 0, 0, w, h, Color(200, 100, 0, 200))
                    surface.SetDrawColor(255, 150, 0, 255)
                else
                    draw.RoundedBox(8, 0, 0, w, h, Color(150, 50, 0, 150))
                    surface.SetDrawColor(255, 150, 0, 100)
                end
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            btnDownload.DoClick = function()
                net.Start("IVO_Docs_StartExtraction")
                net.WriteEntity(ent)
                net.SendToServer()
                frame:Close()
            end
            
            if hasDatapad then
                local lblWarn = vgui.Create("DLabel", container)
                lblWarn:SetPos(0, 325)
                lblWarn:SetSize(560, 20)
                lblWarn:SetText("ADVERTENCIA: Deberás conectar tu Datapad a la terminal (" .. (ent:GetDownloadTime() or 15) .. "s)")
                lblWarn:SetFont("Datapad_DocsText")
                lblWarn:SetTextColor(Color(255, 100, 100))
                lblWarn:SetContentAlignment(5)
            end
        end
    end
    
    frame:RebuildUI()
end)

-- Sistema de sincronización de documentos para el Datapad
IVO_PlayerDocs = IVO_PlayerDocs or {}

net.Receive("IVO_Docs_Sync", function()
    local count = net.ReadUInt(16)
    IVO_PlayerDocs = {}
    
    for i = 1, count do
        table.insert(IVO_PlayerDocs, {
            id = net.ReadUInt(32),
            title = net.ReadString(),
            content = net.ReadString(),
            timestamp = net.ReadUInt(32)
        })
    end
    
    local ply = LocalPlayer()
    if IsValid(ply) then
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_ivo_datapad" then
            if wep.DatapadState == "docs_list" then
                wep:BuildDocsListScreen()
            end
        end
    end
end)
