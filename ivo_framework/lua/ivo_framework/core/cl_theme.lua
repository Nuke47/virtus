-- Tema, colores y fuentes principales del Framework
IVO_FW.Theme = IVO_FW.Theme or {}

-- Paleta de Colores unificada
IVO_FW.Theme.Colors = {
    Primary = Color(25, 25, 25, 240),
    Secondary = Color(40, 40, 40, 240),
    Accent = Color(0, 150, 255, 255), -- Azul Sci-Fi por defecto (ej: Star Wars)
    Text = Color(255, 255, 255, 255),
    TextDark = Color(180, 180, 180, 255),
    Background = Color(15, 15, 15, 200),
    Success = Color(46, 204, 113, 255),
    Danger = Color(231, 76, 60, 255),
    Warning = Color(241, 196, 15, 255),
    Health = Color(220, 50, 50, 255),
    Armor = Color(50, 150, 255, 255),
    Stamina = Color(255, 200, 50, 255)
}

-- Definición de Fuentes (Fonts) compartidas
surface.CreateFont("IVOFW_Title", {
    font = "Roboto",
    size = 28,
    weight = 800,
    antialias = true
})

surface.CreateFont("IVOFW_Text", {
    font = "Roboto",
    size = 18,
    weight = 500,
    antialias = true
})

surface.CreateFont("IVOFW_HUD_Big", {
    font = "Roboto",
    size = 36,
    weight = 800,
    antialias = true
})

surface.CreateFont("IVOFW_HUD_Small", {
    font = "Roboto",
    size = 14,
    weight = 500,
    antialias = true
})

-- Funciones de Utilidad para Interfaz (Botones, Paneles)
function IVO_FW.Theme.DrawPanel(x, y, w, h, color)
    draw.RoundedBox(6, x, y, w, h, color or IVO_FW.Theme.Colors.Primary)
end

function IVO_FW.Theme.DrawOutlinedPanel(x, y, w, h, color, outlineColor)
    draw.RoundedBox(6, x, y, w, h, color or IVO_FW.Theme.Colors.Primary)
    surface.SetDrawColor(outlineColor or IVO_FW.Theme.Colors.Secondary)
    surface.DrawOutlinedRect(x, y, w, h)
end

function IVO_FW.Theme.DrawButton(pnl, w, h)
    local color = IVO_FW.Theme.Colors.Secondary
    local textColor = IVO_FW.Theme.Colors.Text
    
    if pnl:IsHovered() then
        color = IVO_FW.Theme.Colors.Accent
    end
    if pnl:IsDown() then
        color = Color(IVO_FW.Theme.Colors.Accent.r - 20, IVO_FW.Theme.Colors.Accent.g - 20, IVO_FW.Theme.Colors.Accent.b - 20)
    end
    
    draw.RoundedBox(4, 0, 0, w, h, color)
    
    -- Si el botón tiene texto (SetText), lo dibujamos centrado
    if pnl:GetText() and pnl:GetText() ~= "" then
        draw.SimpleText(pnl:GetText(), "IVOFW_Text", w/2, h/2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        pnl:SetText("") -- Ocultamos el texto nativo
    end
end
