-- ============================================================================
-- IVOSAM: TAB DE VOTACIONES
-- ============================================================================

function IVOSAM_BuildVoteTab(parent)
    local header = vgui.Create("DPanel", parent)
    header:Dock(TOP)
    header:SetTall(60)
    header.Paint = function(s, w, h)
        draw.SimpleText("SISTEMA DE VOTACIONES", "IVOSAM_Title", 30, h / 2, IVO_SAM.Theme.TextMain, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:Dock(FILL)
    scroll:DockMargin(30, 10, 30, 20)
    
    local container = vgui.Create("DPanel", scroll)
    container:Dock(TOP)
    container:SetTall(450)
    container.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, IVO_SAM.Theme.CardBg)
    end

    local lblTitle = vgui.Create("DLabel", container)
    lblTitle:SetPos(20, 20)
    lblTitle:SetFont("IVOSAM_Normal")
    lblTitle:SetText("Pregunta / Motivo de Votación:")
    lblTitle:SizeToContents()
    lblTitle:SetTextColor(IVO_SAM.Theme.TextMuted)

    local txtTitle = vgui.Create("DTextEntry", container)
    txtTitle:SetPos(20, 45)
    txtTitle:SetSize(400, 35)
    txtTitle:SetPlaceholderText("Ej: ¿Deberíamos cambiar de mapa?")
    IVO_SAM.StyleModernEntry(txtTitle)

    local optionsLabel = vgui.Create("DLabel", container)
    optionsLabel:SetPos(20, 100)
    optionsLabel:SetFont("IVOSAM_Normal")
    optionsLabel:SetText("Opciones (máximo 5):")
    optionsLabel:SizeToContents()
    optionsLabel:SetTextColor(IVO_SAM.Theme.TextMuted)

    local textEntries = {}
    for i = 1, 5 do
        local txtOpt = vgui.Create("DTextEntry", container)
        txtOpt:SetPos(20, 100 + (i * 45))
        txtOpt:SetSize(300, 35)
        txtOpt:SetPlaceholderText("Opción " .. i .. (i <= 2 and " (Obligatoria)" or " (Opcional)"))
        IVO_SAM.StyleModernEntry(txtOpt)
        table.insert(textEntries, txtOpt)
    end

    local btnCreate = vgui.Create("DButton", container)
    btnCreate:SetPos(20, 380)
    btnCreate:SetSize(200, 40)
    btnCreate:SetText("INICIAR VOTACIÓN")
    btnCreate:SetFont("IVOSAM_Bold")
    btnCreate:SetTextColor(color_white)
    btnCreate.Paint = function(s, w, h)
        local bg = s:IsHovered() and Color(0, 160, 255) or IVO_SAM.Theme.Accent
        draw.RoundedBox(6, 0, 0, w, h, bg)
    end
    btnCreate.DoClick = function()
        local title = txtTitle:GetValue()
        if title == "" then
            chat.AddText(Color(255, 50, 50), "[IVOSAM] Debes ingresar un motivo de votación.")
            return
        end

        local options = {}
        for _, entry in ipairs(textEntries) do
            local val = entry:GetValue()
            if val and val ~= "" then
                table.insert(options, val)
            end
        end

        if #options < 2 then
            chat.AddText(Color(255, 50, 50), "[IVOSAM] Debes ingresar al menos 2 opciones.")
            return
        end

        local cmdString = "sam_vote \"" .. title .. "\" "
        for _, opt in ipairs(options) do
            cmdString = cmdString .. "\"" .. opt .. "\" "
        end
        
        LocalPlayer():ConCommand(string.Trim(cmdString))
    end
end
