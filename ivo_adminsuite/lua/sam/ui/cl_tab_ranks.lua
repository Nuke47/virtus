-- ============================================================================
-- IVOSAM: TAB EDITOR DE RANGOS — PREMIUM UI
-- ============================================================================

function IVOSAM_BuildRanksTab(tabPanel)
    local rightE
    local activeRankSelected = nil

    tabPanel.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
    end

    local leftE = vgui.Create("DPanel", tabPanel)
    leftE:SetSize(320, 0)
    leftE:Dock(LEFT)
    leftE:DockPadding(15, 15, 15, 15)
    leftE.Paint = function(s, w, h)
        draw.RoundedBoxEx(0, 0, 0, w, h, IVO_SAM.Theme.BgBase, false, false, false, false)
        surface.SetDrawColor(255, 255, 255, 5)
        surface.DrawRect(w - 1, 0, 1, h)
    end

    local l1 = vgui.Create("DLabel", leftE)
    l1:SetText("CREAR NUEVO RANGO")
    l1:SetFont("IVOSAM_Bold")
    l1:SetTextColor(IVO_SAM.Theme.TextMain)
    l1:Dock(TOP)
    l1:DockMargin(0, 0, 0, 10)

    local nameEntry = vgui.Create("DTextEntry", leftE)
    nameEntry:Dock(TOP)
    nameEntry:SetTall(35)
    nameEntry:DockMargin(0, 0, 0, 10)
    nameEntry:SetPlaceholderText("ID (ej: moderador)")
    IVO_SAM.StyleModernEntry(nameEntry)

    local wangContainer = vgui.Create("DPanel", leftE)
    wangContainer:Dock(TOP)
    wangContainer:SetTall(40)
    wangContainer:DockMargin(0, 0, 0, 15)
    wangContainer.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, IVO_SAM.Theme.BgTop)
        draw.SimpleText("Nivel de Poder:", "IVOSAM_Normal", 10, h / 2, IVO_SAM.Theme.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local valueWang = vgui.Create("DNumberWang", wangContainer)
    valueWang:Dock(RIGHT)
    valueWang:SetWide(80)
    valueWang:DockMargin(5, 5, 5, 5)
    valueWang:SetMinMax(1, 100)
    valueWang:SetValue(10)
    valueWang:SetFont("IVOSAM_Bold")
    valueWang:SetTextColor(IVO_SAM.Theme.TextMain)
    valueWang.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 40))
        s:DrawTextEntryText(IVO_SAM.Theme.TextMain, IVO_SAM.Theme.Accent, IVO_SAM.Theme.TextMain)
    end

    local btnCreate = vgui.Create("DButton", leftE)
    btnCreate:SetText("REGISTRAR RANGO")
    btnCreate:SetTall(40)
    btnCreate:Dock(TOP)
    btnCreate:DockMargin(0, 0, 0, 20)
    btnCreate.HoverVal = 0
    btnCreate.Paint = function(s, w, h)
        s.HoverVal = math.Clamp(s.HoverVal + (s:IsHovered() and 5 or -5) * FrameTime(), 0, 1)
        
        draw.RoundedBox(8, 0, 0, w, h, IVO_SAM.Theme.Accent)
        if s.HoverVal > 0 then
            draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, 30 * s.HoverVal))
        end
        draw.SimpleText(s:GetText(), "IVOSAM_Bold", w / 2, h / 2, IVO_SAM.Theme.TextMain, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return true
    end
    btnCreate.DoClick = function()
        local name = nameEntry:GetValue():lower():gsub(" ", "")
        local val = valueWang:GetValue()
        if name == "" then return end
        RunConsoleCommand("say", "!createrank " .. name .. " " .. val)
        nameEntry:SetText("")
        surface.PlaySound("UI/buttonrollover.wav")
    end

    local l2 = vgui.Create("DLabel", leftE)
    l2:SetText("LISTA DE RANGOS")
    l2:SetFont("IVOSAM_Bold")
    l2:SetTextColor(IVO_SAM.Theme.TextMuted)
    l2:Dock(TOP)
    l2:DockMargin(0, 5, 0, 10)

    local rankScroll = vgui.Create("DScrollPanel", leftE)
    rankScroll:Dock(FILL)
    local sbar = rankScroll:GetVBar()
    sbar:SetWide(4)
    function sbar:Paint(w, h) end
    function sbar.btnUp:Paint() end
    function sbar.btnDown:Paint() end
    function sbar.btnGrip:Paint(w, h) draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 10)) end

    rightE = vgui.Create("DPanel", tabPanel)
    rightE:Dock(FILL)
    rightE:DockMargin(20, 20, 20, 20)
    rightE.Paint = nil

    local function LoadRankSettings(rankName, rankVal)
        rightE:Clear()
        activeRankSelected = rankName

        local header = vgui.Create("DPanel", rightE)
        header:Dock(TOP)
        header:SetTall(70)
        header:DockMargin(0, 0, 0, 20)
        header.Paint = function(s, w, h)
            draw.RoundedBox(12, 0, 0, w, h, IVO_SAM.Theme.BgTop)
            draw.RoundedBoxEx(12, 0, 0, 6, h, IVO_SAM.Theme.Accent, true, false, true, false)
            draw.SimpleText(rankName:upper(), "IVOSAM_Title", 20, h/2 - 12, IVO_SAM.Theme.TextMain, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("Nivel SAM: " .. rankVal, "IVOSAM_Normal", 20, h/2 + 12, IVO_SAM.Theme.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        if rankName ~= "superadmin" and rankName ~= "user" then
            local btnDelete = vgui.Create("DButton", rightE)
            btnDelete:Dock(BOTTOM)
            btnDelete:SetTall(45)
            btnDelete:DockMargin(0, 15, 0, 0)
            btnDelete:SetText("ELIMINAR RANGO")
            btnDelete.HoverVal = 0
            btnDelete.Paint = function(s, w, h)
                s.HoverVal = math.Clamp(s.HoverVal + (s:IsHovered() and 5 or -5) * FrameTime(), 0, 1)
                draw.RoundedBox(8, 0, 0, w, h, Color(160, 40, 40))
                if s.HoverVal > 0 then
                    draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, 30 * s.HoverVal))
                end
                draw.SimpleText("ELIMINAR ESTE RANGO", "IVOSAM_Bold", w / 2, h / 2, IVO_SAM.Theme.TextMain, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                return true
            end
            btnDelete.DoClick = function()
                local confirmFrame = vgui.Create("DFrame")
                confirmFrame:SetSize(380, 200)
                confirmFrame:Center()
                confirmFrame:SetTitle("")
                confirmFrame:MakePopup()
                confirmFrame:ShowCloseButton(false)
                confirmFrame.Paint = function(s, w, h)
                    draw.RoundedBox(12, 0, 0, w, h, Color(20, 20, 25, 250))
                    surface.SetDrawColor(255, 60, 60, 120)
                    surface.DrawOutlinedRect(0, 0, w, h, 2)
                    draw.SimpleText("¡ADVERTENCIA!", "IVOSAM_Title", w / 2, 40, Color(255, 60, 60), TEXT_ALIGN_CENTER)
                    draw.SimpleText("¿Estás seguro de eliminar el rango?", "IVOSAM_Normal", w / 2, 75, IVO_SAM.Theme.TextMuted, TEXT_ALIGN_CENTER)
                    draw.SimpleText("'" .. rankName:upper() .. "'", "IVOSAM_Bold", w / 2, 95, IVO_SAM.Theme.TextMain, TEXT_ALIGN_CENTER)
                end

                local yes = vgui.Create("DButton", confirmFrame)
                yes:SetSize(140, 40)
                yes:SetPos(40, 135)
                yes:SetText("SÍ, ELIMINAR")
                yes:SetFont("IVOSAM_Bold")
                yes:SetTextColor(Color(255, 255, 255))
                yes.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and Color(220, 50, 50) or Color(160, 40, 40)) end
                yes.DoClick = function()
                    RunConsoleCommand("say", "!deleterank " .. rankName)
                    confirmFrame:Remove()
                    rightE:Clear()
                    activeRankSelected = nil
                end

                local no = vgui.Create("DButton", confirmFrame)
                no:SetSize(140, 40)
                no:SetPos(200, 135)
                no:SetText("CANCELAR")
                no:SetFont("IVOSAM_Bold")
                no:SetTextColor(Color(255, 255, 255))
                no.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and Color(80, 80, 85) or Color(55, 55, 60)) end
                no.DoClick = function() confirmFrame:Remove() end
            end
        end

        local scrollPermisos = vgui.Create("DScrollPanel", rightE)
        scrollPermisos:Dock(FILL)
        local pSbar = scrollPermisos:GetVBar()
        pSbar:SetWide(6)
        function pSbar:Paint(w, h) end
        function pSbar.btnUp:Paint() end
        function pSbar.btnDown:Paint() end
        function pSbar.btnGrip:Paint(w, h) draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 10)) end

        local perms = {
            { id = "menu",        desc = "Acceso al Menú (!menu)" },
            { id = "tickets",     desc = "Atender Tickets (!asay)" },
            { id = "defcon",      desc = "Sistema Defcon (!defcon)" },
            { id = "spectate",    desc = "Modo Espectador (!spectate)" },
            { id = "goto",        desc = "Teletransporte: Goto (!goto)" },
            { id = "bring",       desc = "Teletransporte: Bring (!bring)" },
            { id = "return",      desc = "Teletransporte: Return (!return)" },
            { id = "noclip",      desc = "Vuelo Noclip (!noclip)" },
            { id = "god",         desc = "Modo Dios (!god / !ungod)" },
            { id = "cloak",       desc = "Invisibilidad (!cloak / !uncloak)" },
            { id = "freeze",      desc = "Congelar (!freeze / !unfreeze)" },
            { id = "jail",        desc = "Encarcelar (!jail / !unjail)" },
            { id = "slay",        desc = "Matar (!slay)" },
            { id = "kick",        desc = "Expulsar (!kick)" },
            { id = "ban",         desc = "Banear (!ban / !unban)" },
            { id = "banid",       desc = "Banear Offline (!banid)" },
            { id = "gag",         desc = "Bloquear Voz (!gag / !ungag)" },
            { id = "mute",        desc = "Bloquear Chat (!mute / !unmute)" },
            { id = "strip",       desc = "Quitar Armas (!strip)" },
            { id = "hp",          desc = "Dar Salud (!hp)" },
            { id = "armor",       desc = "Dar Chaleco (!armor)" },
            { id = "give",        desc = "Dar Arma (!give)" },
            { id = "cleardecals", desc = "Limpiar Mapa (!cleardecals)" },
            { id = "respawn",     desc = "Revivir (!respawn)" },
            { id = "setmodel",    desc = "Cambiar Modelo (!setmodel)" },
            { id = "admin",       desc = "Forzar Modo Admin (!admin / !unadmin)" },
            { id = "ignite",      desc = "Quemar (!ignite)" },
            { id = "slap",        desc = "Abofetear (!slap)" },
            { id = "scale",       desc = "Cambiar Tamaño (!scale)" },
            { id = "vote",        desc = "Crear Votación (!vote)" }
        }

        for _, p in ipairs(perms) do
            local pnl = scrollPermisos:Add("DPanel")
            pnl:Dock(TOP)
            pnl:SetTall(50)
            pnl:DockMargin(0, 0, 10, 8)
            pnl.IsChecked = false
            if IVO_SAM.Ranks[rankName] and IVO_SAM.Ranks[rankName].permissions then
                pnl.IsChecked = IVO_SAM.Ranks[rankName].permissions[p.id] or false
            end
            
            pnl.Paint = function(s, w, h)
                local bgCol = s.IsChecked and Color(0, 140, 255, 15) or IVO_SAM.Theme.CardBg
                draw.RoundedBox(8, 0, 0, w, h, bgCol)
                
                if s.IsChecked then
                    surface.SetDrawColor(0, 140, 255, 60)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end

                draw.SimpleText(p.desc, "IVOSAM_Bold", 20, h / 2, s.IsChecked and IVO_SAM.Theme.Accent or IVO_SAM.Theme.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            
            local toggle = vgui.Create("DButton", pnl)
            toggle:SetSize(46, 24)
            toggle.AnimVal = pnl.IsChecked and 1 or 0
            toggle:SetText("")
            pnl.PerformLayout = function(s, w, h) toggle:SetPos(w - 65, h / 2 - 12) end
            
            toggle.Paint = function(s, w, h)
                s.AnimVal = math.Clamp(s.AnimVal + (pnl.IsChecked and 5 or -5) * FrameTime(), 0, 1)
                local bg = Color(
                    Lerp(s.AnimVal, 50, 0),
                    Lerp(s.AnimVal, 50, 140),
                    Lerp(s.AnimVal, 55, 255)
                )
                draw.RoundedBox(12, 0, 0, w, h, bg)
                
                local knobX = Lerp(s.AnimVal, 2, w - 22)
                draw.RoundedBox(10, knobX, 2, 20, 20, Color(255, 255, 255))
            end
            
            toggle.DoClick = function(s)
                pnl.IsChecked = not pnl.IsChecked
                net.Start("IVO_UpdateRankPermissions")
                    net.WriteString(rankName)
                    net.WriteString(p.id)
                    net.WriteBool(pnl.IsChecked)
                net.SendToServer()
                surface.PlaySound("UI/buttonclick.wav")
            end
        end
    end

    function RefreshRankList()
        if not IsValid(rankScroll) then return end
        rankScroll:Clear()
        local ranksSorted = {}
        local ranks = IVO_SAM.Ranks or {}
        for name, data in pairs(ranks) do
            table.insert(ranksSorted, { name = name, power = data.val or data.power or 0 })
        end
        table.SortByMember(ranksSorted, "power", false)
        for _, rData in ipairs(ranksSorted) do
            local card = rankScroll:Add("DButton")
            card:Dock(TOP)
            card:SetTall(55)
            card:DockMargin(0, 0, 10, 8)
            card:SetText("")
            card.HoverVal = 0
            card.Paint = function(s, w, h)
                local isCurrent = (activeRankSelected == rData.name)
                
                if s:IsHovered() then
                    s.HoverVal = math.Clamp(s.HoverVal + 5 * FrameTime(), 0, 1)
                else
                    s.HoverVal = math.Clamp(s.HoverVal - 5 * FrameTime(), 0, 1)
                end

                local bgCol = isCurrent and Color(0, 140, 255, 25) or IVO_SAM.Theme.CardBg
                draw.RoundedBox(8, 0, 0, w, h, bgCol)
                
                if s.HoverVal > 0 and not isCurrent then
                    draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, 5 * s.HoverVal))
                end

                if isCurrent then draw.RoundedBoxEx(8, 0, 0, 4, h, IVO_SAM.Theme.Accent, true, false, true, false) end
                
                draw.SimpleText(rData.name:upper(), "IVOSAM_Bold", 15, h / 2, isCurrent and IVO_SAM.Theme.TextMain or IVO_SAM.Theme.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                
                local powerBoxW = 40
                draw.RoundedBox(6, w - powerBoxW - 10, h/2 - 12, powerBoxW, 24, Color(0, 0, 0, 100))
                draw.SimpleText(rData.power, "IVOSAM_Bold", w - 30, h / 2, IVO_SAM.Theme.Accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            card.DoClick = function()
                LoadRankSettings(rData.name, rData.power)
                surface.PlaySound("UI/buttonrollover.wav")
            end
        end
    end

    RefreshRankList()
end
