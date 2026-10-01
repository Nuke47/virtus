surface.CreateFont("Ivan_UI_Title", { font = "Roboto", size = 20, weight = 600, antialias = true })
surface.CreateFont("Ivan_UI_Text", { font = "Roboto", size = 16, weight = 500, antialias = true })
surface.CreateFont("Ivan_UI_Bold", { font = "Roboto", size = 16, weight = 800, antialias = true })

local C_BG = Color(35, 35, 40, 250)
local C_TOP = Color(25, 25, 30, 255)
local C_PANEL = Color(45, 45, 50, 255)
local C_ACCENT = Color(0, 150, 255, 255)
local C_ACCENT_HOVER = Color(0, 180, 255, 255)
local C_RED = Color(220, 50, 50, 255)
local C_RED_HOVER = Color(250, 70, 70, 255)
local C_GREEN = Color(50, 200, 50, 255)
local C_GREEN_HOVER = Color(70, 230, 70, 255)
local C_TEXT = Color(230, 230, 230, 255)

CreateClientConVar("ivan_spawns_admineyes", "0", true, false)

hook.Add("HUDPaint", "IvanSpawns_AdminEyesESP", function()
    if not GetConVar("ivan_spawns_admineyes"):GetBool() then return end
    
    local ply = LocalPlayer()
    local isAdmin = ply:IsUserGroup("superadmin")
    if SAM then isAdmin = ply:HasPermission("manage_spawns") or ply:IsSuperAdmin() end
    if IVO_SAM then isAdmin = IVO_SAM.HasPermission(ply, "manage_spawns") or ply:IsSuperAdmin() end
    
    if not isAdmin then return end
    
    for _, ent in ipairs(ents.FindByClass("ivan_spawn_point")) do
        if IsValid(ent) then
            local pos = ent:GetPos() + Vector(0,0,20)
            local screenPos = pos:ToScreen()
            
            if screenPos.visible then
                local name = ent:GetSpawnName()
                if name == "" then name = "Spawn" end
                
                local dist = ply:GetPos():Distance(ent:GetPos())
                local alpha = math.Clamp(255 - (dist / 20), 50, 255)
                
                draw.SimpleTextOutlined(name, "Trebuchet24", screenPos.x, screenPos.y, Color(0, 255, 0, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))
                draw.SimpleTextOutlined(math.Round(dist/40).."m", "Trebuchet18", screenPos.x, screenPos.y + 20, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))
            end
        end
    end
end)

local function PaintFlatButton(s, w, h, baseCol, hoverCol)
    draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and hoverCol or baseCol)
end

local function OpenSpawnMenu(ent, data)
    local frame = vgui.Create("DFrame")
    frame:SetSize(650, 550)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, C_BG)
        draw.RoundedBoxEx(6, 0, 0, w, 35, C_TOP, true, true, false, false)
        draw.SimpleText("Configuración de Spawn", "Ivan_UI_Title", 10, 17, C_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(35, 35)
    closeBtn:SetPos(frame:GetWide() - 35, 0)
    closeBtn:SetText("X")
    closeBtn:SetFont("Ivan_UI_Bold")
    closeBtn:SetTextColor(Color(200,200,200))
    closeBtn.Paint = function(s, w, h)
        if s:IsHovered() then draw.RoundedBoxEx(6, 0, 0, w, h, C_RED, false, true, false, false) end
    end
    closeBtn.DoClick = function() frame:Close() end

    -- ADMIN EYES BUTTON
    local btnAdminEyes = vgui.Create("DButton", frame)
    btnAdminEyes:SetSize(140, 25)
    btnAdminEyes:SetPos(frame:GetWide() - 185, 5)
    btnAdminEyes:SetFont("Ivan_UI_Bold")
    btnAdminEyes:SetTextColor(color_white)
    local isEyesOn = GetConVar("ivan_spawns_admineyes"):GetBool()
    btnAdminEyes:SetText(isEyesOn and "Ocultar Admin Eyes" or "Activar Admin Eyes")
    btnAdminEyes.Paint = function(s, w, h) PaintFlatButton(s, w, h, isEyesOn and C_ACCENT or C_PANEL, isEyesOn and C_ACCENT_HOVER or Color(60,60,65)) end
    btnAdminEyes.DoClick = function(s)
        local newState = not GetConVar("ivan_spawns_admineyes"):GetBool()
        RunConsoleCommand("ivan_spawns_admineyes", newState and "1" or "0")
        isEyesOn = newState
        s:SetText(isEyesOn and "Ocultar Admin Eyes" or "Activar Admin Eyes")
    end

    local propsPanel = vgui.Create("DPanel", frame)
    propsPanel:Dock(TOP)
    propsPanel:DockMargin(10, 45, 10, 10)
    propsPanel:SetTall(90)
    propsPanel.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, C_PANEL)
    end

    local nameLabel = vgui.Create("DLabel", propsPanel)
    nameLabel:SetText("Nombre del Spawn:")
    nameLabel:SetFont("Ivan_UI_Text")
    nameLabel:SetTextColor(C_TEXT)
    nameLabel:SetPos(15, 15)
    nameLabel:SizeToContents()

    local nameEntry = vgui.Create("DTextEntry", propsPanel)
    nameEntry:SetPos(160, 13)
    nameEntry:SetSize(200, 24)
    nameEntry:SetFont("Ivan_UI_Text")
    nameEntry:SetValue(ent:GetSpawnName())
    nameEntry.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 25))
        s:DrawTextEntryText(C_TEXT, C_ACCENT, C_TEXT)
    end

    local function CreateCustomCheckbox(parent, text, x, y, defaultVal)
        local pnl = vgui.Create("DPanel", parent)
        pnl:SetPos(x, y)
        pnl:SetSize(250, 24)
        pnl.Paint = function() end
        
        local chk = vgui.Create("DCheckBox", pnl)
        chk:SetPos(0, 4)
        chk:SetSize(16, 16)
        chk:SetValue(defaultVal)
        
        local lbl = vgui.Create("DLabel", pnl)
        lbl:SetPos(25, 2)
        lbl:SetText(text)
        lbl:SetFont("Ivan_UI_Text")
        lbl:SetTextColor(C_TEXT)
        lbl:SizeToContents()
        
        return chk
    end

    local chkShowName = CreateCustomCheckbox(propsPanel, "Mostrar Nombre 3D", 380, 13, ent:GetShowName())
    local chkInvisible = CreateCustomCheckbox(propsPanel, "Cubo Invisible", 15, 50, ent:GetIsInvisible())
    local chkPersistent = CreateCustomCheckbox(propsPanel, "Persistente (Guardar)", 380, 50, data.IsPersistent or false)

    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)
    sheet:DockMargin(10, 0, 10, 10)
    sheet.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 20, w, h-20, C_PANEL)
    end
    
    local function CreateListPanel()
        local pnl = vgui.Create("DScrollPanel", sheet)
        pnl.Paint = function(s, w, h) end
        return pnl
    end

    local function PopulateChecks(panel, dataTbl, items, getNameFunc)
        local y = 10
        local checks = {}
        for k, v in pairs(items) do
            local name = getNameFunc(v)
            local chk = CreateCustomCheckbox(panel, name, 15, y, dataTbl[name] or false)
            checks[name] = chk
            y = y + 30
        end
        return checks
    end

    -- Jobs Tab
    local pnlJobs = CreateListPanel()
    sheet:AddSheet("Jobs", pnlJobs, "icon16/user_suit.png")
    local jobChecks = RPExtraTeams and PopulateChecks(pnlJobs, data.AllowedJobs, RPExtraTeams, function(v) return v.name end) or {}

    -- Categories Tab
    local pnlCats = CreateListPanel()
    sheet:AddSheet("Categorías", pnlCats, "icon16/folder.png")
    local catsList = (DarkRP and DarkRP.getCategories and DarkRP.getCategories().jobs) or {}
    local catChecks = PopulateChecks(pnlCats, data.AllowedCategories, catsList, function(v) return v.name end)

    -- SAM Ranks Tab
    local pnlRanks = CreateListPanel()
    sheet:AddSheet("SAM Ranks", pnlRanks, "icon16/shield.png")
    local commonRanks = {"user", "vip", "admin", "superadmin"}
    if IVO_SAM and IVO_SAM.Ranks then
        commonRanks = {}
        for rankName, _ in pairs(IVO_SAM.Ranks) do table.insert(commonRanks, rankName) end
    elseif SAM and sam and sam.ranks then
        commonRanks = {}
        for rankName, _ in pairs(sam.ranks.get_ranks()) do table.insert(commonRanks, rankName) end
    end
    local rankChecks = PopulateChecks(pnlRanks, data.AllowedSAMRanks, commonRanks, function(v) return v end)

    -- SteamIDs Tab
    local pnlSteam = vgui.Create("DPanel", sheet)
    pnlSteam.Paint = function() end
    sheet:AddSheet("SteamIDs", pnlSteam, "icon16/vcard.png")
    
    local steamList = vgui.Create("DListView", pnlSteam)
    steamList:Dock(FILL)
    steamList:DockMargin(10, 10, 10, 10)
    steamList:AddColumn("SteamID Autorizado")
    
    for sid, _ in pairs(data.AllowedSteamIDs) do steamList:AddLine(sid) end
    
    local pnlSteamBot = vgui.Create("DPanel", pnlSteam)
    pnlSteamBot:Dock(BOTTOM)
    pnlSteamBot:SetTall(40)
    pnlSteamBot:DockMargin(10, 0, 10, 10)
    pnlSteamBot.Paint = function() end
    
    local steamEntry = vgui.Create("DTextEntry", pnlSteamBot)
    steamEntry:Dock(FILL)
    steamEntry:DockMargin(0, 5, 10, 5)
    steamEntry:SetFont("Ivan_UI_Text")
    steamEntry.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 25))
        s:DrawTextEntryText(C_TEXT, C_ACCENT, C_TEXT)
    end
    
    local btnAddSteam = vgui.Create("DButton", pnlSteamBot)
    btnAddSteam:Dock(RIGHT)
    btnAddSteam:SetWide(120)
    btnAddSteam:DockMargin(0, 5, 5, 5)
    btnAddSteam:SetText("Añadir SteamID")
    btnAddSteam:SetTextColor(color_white)
    btnAddSteam:SetFont("Ivan_UI_Bold")
    btnAddSteam.Paint = function(s, w, h) PaintFlatButton(s, w, h, C_ACCENT, C_ACCENT_HOVER) end
    btnAddSteam.DoClick = function()
        local txt = steamEntry:GetValue()
        if txt ~= "" then
            steamList:AddLine(txt)
            steamEntry:SetValue("")
        end
    end
    
    local btnRemSteam = vgui.Create("DButton", pnlSteamBot)
    btnRemSteam:Dock(RIGHT)
    btnRemSteam:SetWide(160)
    btnRemSteam:DockMargin(0, 5, 0, 5)
    btnRemSteam:SetText("Eliminar Seleccionado")
    btnRemSteam:SetTextColor(color_white)
    btnRemSteam:SetFont("Ivan_UI_Bold")
    btnRemSteam.Paint = function(s, w, h) PaintFlatButton(s, w, h, C_RED, C_RED_HOVER) end
    btnRemSteam.DoClick = function()
        local selected = steamList:GetSelectedLine()
        if selected then steamList:RemoveLine(selected) end
    end

    -- Bottom Global Buttons
    local botPanel = vgui.Create("DPanel", frame)
    botPanel:Dock(BOTTOM)
    botPanel:SetTall(45)
    botPanel:DockMargin(10, 0, 10, 10)
    botPanel.Paint = function() end

    local btnSave = vgui.Create("DButton", botPanel)
    btnSave:Dock(FILL)
    btnSave:DockMargin(0, 0, 10, 0)
    btnSave:SetText("Guardar Configuración")
    btnSave:SetFont("Ivan_UI_Title")
    btnSave:SetTextColor(color_white)
    btnSave.Paint = function(s, w, h) PaintFlatButton(s, w, h, C_GREEN, C_GREEN_HOVER) end
    btnSave.DoClick = function()
        local newData = {
            AllowedJobs = {}, AllowedCategories = {}, AllowedSteamIDs = {}, AllowedSAMRanks = {},
            IsPersistent = chkPersistent:GetChecked()
        }
        for name, chk in pairs(jobChecks) do if chk:GetChecked() then newData.AllowedJobs[name] = true end end
        for name, chk in pairs(catChecks) do if chk:GetChecked() then newData.AllowedCategories[name] = true end end
        for name, chk in pairs(rankChecks) do if chk:GetChecked() then newData.AllowedSAMRanks[name] = true end end
        for _, line in pairs(steamList:GetLines()) do newData.AllowedSteamIDs[line:GetValue(1)] = true end
        
        net.Start("IvanSpawns_SaveConfig")
        net.WriteEntity(ent)
        net.WriteString(nameEntry:GetValue())
        net.WriteBool(chkShowName:GetChecked())
        net.WriteBool(chkInvisible:GetChecked())
        net.WriteTable(newData)
        net.SendToServer()
        frame:Close()
    end
    
    local btnDel = vgui.Create("DButton", botPanel)
    btnDel:Dock(RIGHT)
    btnDel:SetWide(180)
    btnDel:SetText("Eliminar Spawn")
    btnDel:SetFont("Ivan_UI_Title")
    btnDel:SetTextColor(color_white)
    btnDel.Paint = function(s, w, h) PaintFlatButton(s, w, h, C_RED, C_RED_HOVER) end
    btnDel.DoClick = function()
        Derma_Query("¿Seguro que quieres eliminar este spawn?", "Confirmar Eliminación", 
            "Sí, eliminar", function()
                net.Start("IvanSpawns_Delete")
                net.WriteEntity(ent)
                net.SendToServer()
                frame:Close()
            end, "Cancelar", function() end)
    end
    
    timer.Simple(0.1, function()
        if not IsValid(sheet) then return end
        for _, panel in pairs(sheet.Items) do
            if panel.Tab then
                panel.Tab.Paint = function(s, w, h)
                    draw.RoundedBoxEx(4, 0, 0, w, h, s:IsActive() and C_PANEL or Color(30,30,35), true, true, false, false)
                end
            end
        end
    end)
end

net.Receive("IvanSpawns_OpenMenu", function()
    local ent = net.ReadEntity()
    local data = net.ReadTable()
    if IsValid(ent) then OpenSpawnMenu(ent, data) end
end)