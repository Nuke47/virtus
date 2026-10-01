-- =========================================================================
-- CORE UI DEL DATAPAD — MENÚ PRINCIPAL CON SIDEBAR
-- =========================================================================
Datapad = Datapad or {}
Datapad.Modules = Datapad.Modules or {}

-- Fuentes base
surface.CreateFont("Datapad_Title", { font = "Roboto", size = 22, weight = 800, antialias = true })
surface.CreateFont("Datapad_Text",  { font = "Roboto", size = 15, weight = 600, antialias = true })

local DATAPAD_FRAME = nil

-- ─── Helper: color seguro ─────────────────────────────────────────────────
local function GetThemeColor(key, default)
    if Datapad.Config and Datapad.Config.Colors and Datapad.Config.Colors[key] then
        return Datapad.Config.Colors[key]
    end
    return default
end

-- ─── Helper: scrollbar minimalista ───────────────────────────────────────
local function CustomScrollbar(scrollPanel, accentColor)
    local sbar = scrollPanel:GetVBar()
    if not IsValid(sbar) then return end
    local clr = accentColor or Color(0, 150, 255)
    sbar:SetWide(4)
    sbar.Paint      = function() end
    sbar.btnUp.Paint  = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(2, 0, 0, w, h, Color(clr.r, clr.g, clr.b, s:IsHovered() and 200 or 90))
    end
end

-- =========================================================================
-- APERTURA DEL MENÚ PRINCIPAL
-- =========================================================================
function Datapad:OpenMenu()
    if IsValid(DATAPAD_FRAME) then DATAPAD_FRAME:Remove() end

    local ply = LocalPlayer()

    local clrBg      = GetThemeColor("Background", Color(14, 16, 22))
    local clrSidebar = GetThemeColor("Sidebar",    Color(23, 27, 38))
    local clrAccent  = GetThemeColor("Accent",     Color(0, 153, 204))
    local clrText    = GetThemeColor("Text",        color_white)
    local clrWarning = GetThemeColor("Warning",     Color(220, 60, 60))

    -- Marco principal
    DATAPAD_FRAME = vgui.Create("DFrame")
    
    -- ======== AJUSTE DE PANTALLA (OVERLAY) ========
    -- Cambia el tamaño y posición para que el menú 2D encaje justo encima del cristal del datapad
    local menuWidth = 350
    local menuHeight = 450
    local offsetX = 0      -- Mover a izquierda/derecha (0 es el centro)
    local offsetY = 120    -- Mover arriba/abajo
    
    DATAPAD_FRAME:SetSize(menuWidth, menuHeight)
    DATAPAD_FRAME:SetPos((ScrW() / 2) - (menuWidth / 2) + offsetX, (ScrH() / 2) - (menuHeight / 2) + offsetY)
    DATAPAD_FRAME:SetTitle("")
    DATAPAD_FRAME:MakePopup()
    DATAPAD_FRAME:ShowCloseButton(false)
    DATAPAD_FRAME:SetAlpha(0)
    DATAPAD_FRAME:AlphaTo(255, 0.12, 0)
    
    Datapad.MenuFrame = DATAPAD_FRAME

    DATAPAD_FRAME.Paint = function(self, w, h)
        -- Fondo totalmente transparente para que se vea la pantalla 3D de atrás
        -- Solo dibujaremos una línea muy tenue para guiarnos si hace falta
        -- draw.RoundedBox(8, 0, 0, w, h, Color(0,0,0,0))
    end

    -- Botón de cierre
    local closeBtn = vgui.Create("DButton", DATAPAD_FRAME)
    closeBtn:SetSize(45, 45)
    closeBtn:SetPos(DATAPAD_FRAME:GetWide() - 45, 0)
    closeBtn:SetText("✕")
    closeBtn:SetTextColor(Color(130, 140, 160))
    closeBtn:SetFont("Datapad_Title")
    closeBtn.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBoxEx(8, 0, 0, w, h, clrWarning, false, true, false, false)
            self:SetTextColor(color_white)
        else
            self:SetTextColor(Color(130, 140, 160))
        end
    end
    closeBtn.DoClick = function() DATAPAD_FRAME:Close() end

    -- Sidebar
    local sidebarWidth = math.floor(DATAPAD_FRAME:GetWide() * 0.35) -- 35% del ancho total
    
    local sidebar = vgui.Create("DScrollPanel", DATAPAD_FRAME)
    sidebar:SetSize(sidebarWidth, DATAPAD_FRAME:GetTall() - 45)
    sidebar:SetPos(0, 45)
    sidebar.Paint = function(self, w, h)
        -- Fondo transparente
    end
    CustomScrollbar(sidebar, clrAccent)

    -- Área de contenido
    local contentArea = vgui.Create("DPanel", DATAPAD_FRAME)
    contentArea:SetSize(DATAPAD_FRAME:GetWide() - sidebarWidth, DATAPAD_FRAME:GetTall() - 45)
    contentArea:SetPos(sidebarWidth, 45)
    contentArea.Paint = function() end

    -- ─── Ordenar y filtrar módulos por permisos ──────────────────────────
    local sortedModules = {}
    for id, mod in pairs(Datapad.Modules or {}) do
        local canAccess = false
        pcall(function()
            if mod.CanAccess and isfunction(mod.CanAccess) then
                canAccess = mod.CanAccess(ply)
            end
        end)
        if canAccess then
            table.insert(sortedModules, mod)
        end
    end
    table.sort(sortedModules, function(a, b) return (a.Order or 0) < (b.Order or 0) end)

    local activeMenuButton = nil
    local firstModule = true

    for _, mod in ipairs(sortedModules) do
        local btn = sidebar:Add("DButton")
        btn:SetText("  " .. string.upper(mod.Name))
        btn:SetFont("Datapad_Text")
        btn:SetTextColor(Color(170, 180, 195))
        btn:SetTall(48)
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, 1)
        btn:SetContentAlignment(4)

        btn.Paint = function(self, w, h)
            local isSelected = (activeMenuButton == self)
            local isHovered  = self:IsHovered()
            if isSelected then
                draw.RoundedBox(0, 0, 0, w, h, Color(clrAccent.r, clrAccent.g, clrAccent.b, 15))
                draw.RoundedBox(0, 0, 0, 4, h, clrAccent)
                self:SetTextColor(color_white)
            elseif isHovered then
                draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 4))
                draw.RoundedBox(0, 0, 0, 4, h, Color(255, 255, 255, 20))
                self:SetTextColor(color_white)
            else
                self:SetTextColor(Color(150, 160, 175))
            end
        end

        btn.DoClick = function(self)
            activeMenuButton = self
            contentArea:Clear()
            if mod.UI and isfunction(mod.UI) then
                local ok, err = pcall(function() mod.UI(contentArea) end)
                if not ok then
                    print("[Datapad ERROR] Fallo al renderizar módulo: ", err)
                end
            end
        end

        if firstModule then
            btn:DoClick()
            firstModule = false
        end
    end

    -- Sin módulos disponibles
    if #sortedModules == 0 then
        local lbl = vgui.Create("DLabel", contentArea)
        lbl:SetText("ACCESO DENEGADO: NO TIENES CREDENCIALES DE RED")
        lbl:SetFont("Datapad_Title")
        lbl:SetTextColor(clrWarning)
        lbl:SizeToContents()
        lbl:Center()
    end
end

-- =========================================================================
-- COMANDO DE CONSOLA
-- =========================================================================
concommand.Add("swrp_datapad", function()
    Datapad:OpenMenu()
end)
