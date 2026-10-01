local function SafeUpper(str)
    if not str then return "" end
    local utf8_lower = "aábcdeéfghiíjklmnñoópqrstuúüvwxyz"
    local utf8_upper = "AÁBCDEÉFGHIÍJKLMNÑOÓPQRSTUÚÜVWXYZ"
    local res = ""
    local success = pcall(function()
        for p, c in utf8.codes(str) do
            local ch = utf8.char(c)
            local idx = utf8_lower:find(ch, 1, true)
            if idx then
                res = res .. utf8_upper:sub(idx, idx + #ch - 1)
            else
                res = res .. string.upper(ch)
            end
        end
    end)
    if not success then return string.upper(str) end
    return res
end

VIRTUSMENU = VIRTUSMENU or {}



-- Fuentes Ultra-Modernas

surface.CreateFont("VF4_Huge", { font = "SansSerifFLF-Demibold", size = 72, weight = 500, antialias = true })
surface.CreateFont("VF4_TitleBig", { font = "SansSerifFLF-Demibold", size = 48, weight = 500, antialias = true })
surface.CreateFont("VF4_Header", { font = "SansSerifFLF-Demibold", size = 28, weight = 500, antialias = true })
surface.CreateFont("VF4_Medium", { font = "SansSerifFLF-Demibold", size = 20, weight = 500, antialias = true })
surface.CreateFont("VF4_Medium_Bold", { font = "SansSerifFLF-Demibold", size = 20, weight = 500, antialias = true })
surface.CreateFont("VF4_Normal", { font = "SansSerifFLF-Demibold", size = 18, weight = 500, antialias = true })
surface.CreateFont("VF4_Small", { font = "SansSerifFLF-Demibold", size = 14, weight = 500, antialias = true })
surface.CreateFont("VF4_Small_Bold", { font = "SansSerifFLF-Demibold", size = 14, weight = 500, antialias = true })
surface.CreateFont("VF4_JobList_Name", { font = "SansSerifFLF-Demibold", size = 22, weight = 500, antialias = true })
surface.CreateFont("VF4_Subtitle_Aurebesh", { font = "VirtusBe", size = 14, weight = 500, antialias = true })
surface.CreateFont("VF4_Subtitle_Aurebesh_Small", { font = "VirtusBe", size = 11, weight = 500, antialias = true })
surface.CreateFont("VF4_Subtitle_Aurebesh_Large", { font = "VirtusBe", size = 20, weight = 500, antialias = true })



-- Categoras Imperiales

local Imperiales = {

    ["Cadetes"] = true,

    ["Clone Troopers"] = true,

    ["Shock Troopers"] = true,

    ["Shadow Unit"] = true,

    ["Altos Mandos"] = true

}



-- Funciones tiles

local function LerpColor(t,f,to) return Color(Lerp(t,f.r,to.r),Lerp(t,f.g,to.g),Lerp(t,f.b,to.b),Lerp(t,f.a or 255,to.a or 255)) end



local function DrawCircle( x, y, radius, seg )

    local cir = {}

    table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )

    for i = 0, seg do

        local a = math.rad( ( i / seg ) * -360 )

        table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

    end

    local a = math.rad( 0 )

    table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

    surface.DrawPoly( cir )

end



local blur = Material("pp/blurscreen")

local function DrawBlur(p, a, d) 

    local x, y = p:LocalToScreen(0,0) 

    surface.SetDrawColor(255, 255, 255) 

    surface.SetMaterial(blur) 

    for i=1, (d or 3) do 

        blur:SetFloat("$blur", (i/3) * (a or 6)) 

        blur:Recompute() 

        render.UpdateScreenEffectTexture() 

        surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH()) 

    end 

end



local function CreateElegantButton(parent, text, x, y, w, h, clickFunc)

    local btn = vgui.Create("DButton", parent)

    btn:SetSize(w, h)

    btn:SetPos(x, y)

    btn:SetText("")

    btn.HoverP = 0

    

    btn.OnCursorEntered = function(s)

        VIRTUSMENU.PlayUI("navigation/movimiento.wav")

    end

    

    btn.Paint = function(s, pw, ph)
        s.HoverP = Lerp(FrameTime() * 12, s.HoverP, s:IsHovered() and 1 or 0)
        
        local lineW = pw * s.HoverP
        if lineW > 0.5 then
            draw.RoundedBox(2, pw/2 - lineW/2, ph - 3, lineW, 3, Color(255, 255, 255, s.HoverP * 255))
        end
        
        local col = s:IsHovered() and Color(255, 255, 255) or Color(180, 180, 180)
        draw.SimpleText(text, "VF4_Small_Bold", pw/2, ph/2 - 2, col, 1, 1)
    end

    btn.DoClick = function(s)

        VIRTUSMENU.PlayUI("navigation/aceptar.wav")

        if clickFunc then clickFunc(s) end

    end

    return btn

end



-- Focus en cabeza para DModelPanel e iluminacin corregida

local function FocusHead(mdl)

    local oldSetModel = mdl.SetModel

    mdl.SetModel = function(self, m)

        -- Fallbacks si el modelo es invlido para evitar bloqueos rojos sin modelo

        if not m or m == "" or type(m) == "table" then m = "models/player/kleiner.mdl" end

        if not util.IsValidModel(m) then m = "models/player/kleiner.mdl" end

        

        oldSetModel(self, m)

        local e = self.Entity

        if IsValid(e) then

            -- Mejorar la iluminacin del modelo para que no se vea oscuro

            self:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))

            self:SetDirectionalLight(BOX_FRONT, Color(255, 255, 255))

            self:SetAmbientLight(Color(120, 120, 120))

            

            timer.Simple(0.1, function()

                if not IsValid(e) then return end

                e:SetAngles(Angle(0, 45, 0)) -- Mirando un poco de lado/frente

                local headBone = e:LookupBone("ValveBiped.Bip01_Head1")

                local headPos

                if headBone then

                    e:SetupBones()

                    headPos = e:GetBonePosition(headBone)

                end

                if not headPos then

                    headPos = e:GetPos() + Vector(0,0,64)

                end

                

                self:SetCamPos(headPos + Vector(35, -15, 0))

                self:SetLookAt(headPos)

                self:SetFOV(30)

            end)

        end

    end

    function mdl:LayoutEntity(e)

        self:RunAnimation() -- Respiracin/Idle quieto sin girar

    end

end



local LoadFactions, LoadCategoryCircles, LoadJobs



LoadJobs = function(parent, categoryName, jobs, faction)
    parent:Clear()
    
    local colorTheme = faction == "Imperio" and Color(0, 150, 255) or Color(255, 50, 50)
    
    local btnBack = CreateElegantButton(parent, "< VOLVER A GRUPOS", 20, 20, 140, 25, function()
        LoadCategoryCircles(parent, faction)
    end)
    
    local lbl = vgui.Create("DLabel", parent)
    lbl:SetText(SafeUpper(categoryName))
    lbl:SetFont("VIRTUS_LogoFont_Small")
    lbl:SetTextColor(colorTheme)
    lbl:SizeToContents()
    lbl:SetPos(parent:GetWide()/2 - lbl:GetWide()/2, 40)
    
    local linePnl = vgui.Create("DPanel", parent)
    linePnl:SetPos(parent:GetWide()/2 - 150, 40 + lbl:GetTall() + 5)
    linePnl:SetSize(300, 2)
    linePnl.Paint = function(s, w, h)
        surface.SetDrawColor(colorTheme.r, colorTheme.g, colorTheme.b, 100)
        surface.DrawRect(0, 0, w, h)
    end
    
    local ply = LocalPlayer()
    
    local function HasWhitelist(ply, job)
        if ply:GetNWBool("VirtusWL_" .. job.command, false) then return true end
        if RPExtraTeams[job.team] and RPExtraTeams[job.team].customCheck then
            return RPExtraTeams[job.team].customCheck(ply)
        end
        return false
    end
    
    local savedFavorites = util.JSONToTable(cookie.GetString("virtus_job_favorites", "{}"))
    local function IsFavorite(job) return savedFavorites[job.command] == true end
    local function ToggleFavorite(job)
        savedFavorites[job.command] = not savedFavorites[job.command]
        cookie.Set("virtus_job_favorites", util.TableToJSON(savedFavorites))
    end
    
    local w = parent:GetWide()
    local h = parent:GetTall()
    
    local leftW = w * 0.25
    
    local filterMode = cookie.GetString("virtus_f4_filter", "all")
    
    -- Si está en whitelist pero no tiene NINGUNA whitelist asignada, forzar a "all"
    if filterMode == "whitelist" then
        local hasAnyWL = false
        for _, job in ipairs(RPExtraTeams or {}) do
            if HasWhitelist(ply, job) then hasAnyWL = true; break end
        end
        if not hasAnyWL then filterMode = "all" end
    end
    
    local filterPnl = vgui.Create("DPanel", parent)
    filterPnl:SetPos(0, 110)
    filterPnl:SetSize(leftW, 25)
    filterPnl.Paint = function() end
    
    local function CreateFilterBtn(x, w, text, mode)
        local btn = vgui.Create("DButton", filterPnl)
        btn:SetPos(x, 0)
        btn:SetSize(w, 25)
        btn:SetText("")
        btn.Paint = function(s, pw, ph)
            local isSel = (filterMode == mode)
            s.HoverP = Lerp(FrameTime() * 10, s.HoverP or 0, (s:IsHovered() or isSel) and 1 or 0)
            
            local bordeAlpha = 50 + s.HoverP * 100
            draw.RoundedBox(4, 0, 0, pw, ph, Color(colorTheme.r, colorTheme.g, colorTheme.b, bordeAlpha))
            
            draw.RoundedBox(4, 1, 1, pw - 2, ph - 2, Color(10, 15, 20, 240))
            
            if s.HoverP > 0.05 then
                draw.RoundedBox(4, 1, 1, pw - 2, ph - 2, Color(colorTheme.r, colorTheme.g, colorTheme.b, s.HoverP * 50))
            end
            
            draw.SimpleText(text, "VF4_Medium_Bold", pw/2, ph/2, isSel and Color(255,255,255) or Color(150,150,150), 1, 1)
        end
        btn.DoClick = function()
            VIRTUSMENU.PlayUI("navigation/movimiento.wav")
            filterMode = mode
            cookie.Set("virtus_f4_filter", mode)
            if parent.PopulateJobs then parent.PopulateJobs() end
        end
    end
    
    local bw = (leftW - 10) / 3
    CreateFilterBtn(0, bw, "WHITELIST", "whitelist")
    CreateFilterBtn(bw + 5, bw, "TODOS", "all")
    CreateFilterBtn((bw + 5) * 2, bw, "FAVORITOS", "favorites")
    
    local leftScroll = vgui.Create("DScrollPanel", parent)
    leftScroll:SetPos(0, 145)
    leftScroll:SetSize(leftW, h - 145)
    VIRTUSMENU.StyleScroll(leftScroll)
    
    local midX = leftW + 20
    local midW = w * 0.4
    local rightX = midX + midW + 20
    local rightW = w - rightX
    local selectedBtn = nil
    
    local glowPnl = vgui.Create("DPanel", parent)
    glowPnl:SetPos(midX, 120)
    glowPnl:SetSize(midW, h - 120)
    glowPnl.Paint = function(s, pw, ph)
        draw.RoundedBox(8, 0, 0, pw, ph, Color(colorTheme.r, colorTheme.g, colorTheme.b, 50))
        draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(15, 20, 25, 180))
    end
    
    local centerModel = vgui.Create("DModelPanel", parent)
    centerModel:SetPos(midX, 120)
    centerModel:SetSize(midW, h - 120)
    centerModel:SetModel("")
    centerModel:SetFOV(30)
    centerModel:SetCamPos(Vector(125, 0, 45))
    centerModel:SetLookAt(Vector(0, 0, 45))
    centerModel:SetAmbientLight(Color(20, 20, 30))
    centerModel:SetDirectionalLight(BOX_TOP, Color(150, 200, 255))
    centerModel:SetDirectionalLight(BOX_FRONT, Color(255, 255, 255))
    centerModel:SetDirectionalLight(BOX_RIGHT, Color(255, 30, 30))
    centerModel.ModelAngle = 0
    centerModel.IsDragging = false
    centerModel.LastX = 0
    
    function centerModel:OnMousePressed(mc) if mc == MOUSE_LEFT then self.IsDragging = true self.LastX = gui.MouseX() end end
    function centerModel:OnMouseReleased(mc) if mc == MOUSE_LEFT then self.IsDragging = false end end
    function centerModel:OnCursorExited() self.IsDragging = false end
    function centerModel:LayoutEntity(ent)
        if self.IsDragging then
            local mx = gui.MouseX()
            self.ModelAngle = self.ModelAngle + (mx - self.LastX) * 0.8
            self.LastX = mx
        end
        ent:SetAngles(Angle(0, self.ModelAngle, 0))
    end
    
    local infoPnl = vgui.Create("DPanel", parent)
    infoPnl:SetPos(rightX, 160)
    infoPnl:SetSize(rightW, h - 200)
    infoPnl.Paint = function(s, pw, ph) 
        draw.RoundedBox(8, 0, 0, pw, ph, Color(colorTheme.r, colorTheme.g, colorTheme.b, 150))
        draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(10, 15, 25, 240))
        
        surface.SetDrawColor(colorTheme.r, colorTheme.g, colorTheme.b, 5)
        for i=0, ph, 8 do 
            surface.DrawLine(0, i, pw, i) 
        end
    end
    infoPnl:SetAlpha(0)
    
    local selName = vgui.Create("DLabel", infoPnl)
    selName:SetFont("VF4_TitleBig")
    selName:SetText("SELECCIONA UN ROL")
    selName:SetPos(20, 15)
    selName:SetSize(rightW - 40, 45)
    
    local selSubName = vgui.Create("DLabel", infoPnl)
    selSubName:SetFont("VF4_Subtitle_Aurebesh_Large")
    selSubName:SetText("SELECCIONA UN ROL")
    selSubName:SetPos(22, 58)
    selSubName:SetSize(rightW - 40, 26)
    selSubName:SetTextColor(Color(150, 150, 150))
    
    local sep = vgui.Create("DPanel", infoPnl)
    sep:SetPos(20, 90)
    sep:SetSize(rightW - 40, 1)
    sep.Paint = function(s, pw, ph) surface.SetDrawColor(colorTheme.r, colorTheme.g, colorTheme.b, 50) surface.DrawRect(0, 0, pw, ph) end
    
    local statsLayout = vgui.Create("DIconLayout", infoPnl)
    statsLayout:SetPos(20, 105)
    statsLayout:SetSize(rightW - 40, infoPnl:GetTall() - 185)
    statsLayout:SetSpaceY(10)
    
    local deployBtn = vgui.Create("DButton", infoPnl)
    deployBtn:SetPos(20, infoPnl:GetTall() - 70)
    deployBtn:SetSize(rightW - 40, 50)
    deployBtn:SetText("")
    deployBtn:SetFont("VF4_Medium")
    deployBtn.Paint = function(s, pw, ph)
        s.HoverP = Lerp(FrameTime() * 10, s.HoverP or 0, s:IsHovered() and 1 or 0)
        local cA = 100 + s.HoverP * 155
        draw.RoundedBox(8, 0, 0, pw, ph, Color(colorTheme.r, colorTheme.g, colorTheme.b, cA))
        
        local bgA = s.HoverP > 0.05 and (s.HoverP * 30) or 0
        draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(10, 15, 20, 240))
        if bgA > 0 then
            draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(colorTheme.r, colorTheme.g, colorTheme.b, bgA))
        end
        
        local txtCol = Color(200 + 55 * s.HoverP, 200 + 55 * s.HoverP, 255)
        draw.SimpleText(s.btnText or "SELECCIONAR", "VF4_Medium", pw/2, ph/2, txtCol, 1, 1)
    end
    
    local favBtn = vgui.Create("DButton", infoPnl)
    favBtn:SetPos(rightW - 70, 20)
    favBtn:SetSize(40, 40)
    favBtn:SetText("")
    favBtn:SetFont("VF4_TitleBig")
    favBtn.Paint = function(s, pw, ph)
        local isFav = s.job and IsFavorite(s.job)
        s:SetTextColor(isFav and Color(255, 200, 0) or Color(100, 100, 100))
    end
    favBtn.DoClick = function(s)
        if s.job then
            ToggleFavorite(s.job)
            if parent.PopulateJobs then parent.PopulateJobs(true) end
        end
    end
    
    parent.PopulateJobs = function(keepSelection)
        leftScroll:Clear()
        local yPos = 10
        local firstAllowedJob = nil
        local firstBtn = nil
        
        for _, job in ipairs(jobs) do
            local hasWL = HasWhitelist(ply, job)
            local isFav = IsFavorite(job)
            
            if filterMode == "whitelist" and not hasWL then continue end
            if filterMode == "favorites" and not isFav then continue end
            if not firstAllowedJob then firstAllowedJob = job end
            
            local btn = vgui.Create("DButton", leftScroll)
            if not firstBtn then firstBtn = btn end
        btn:SetSize(leftW - 15, 100)
        btn:SetPos(0, yPos)
        btn:SetText("")
        yPos = yPos + 110
        
        local bC = job.color or Color(255,255,255)
        local m = type(job.model) == "table" and job.model[1] or job.model
        if not m or m == "" or not util.IsValidModel(m) or string.lower(m) == "models/error.mdl" then m = "models/player/kleiner.mdl" end
        
        local icon = vgui.Create("DModelPanel", btn)
        icon:SetSize(90, 90)
        icon:SetPos(5, 5)
        icon:SetModel(m)
        icon:SetMouseInputEnabled(false)
        icon:SetFOV(30)
        icon:SetCamPos(Vector(40, 0, 62))
        icon:SetLookAt(Vector(0, 0, 62))
        icon:SetAmbientLight(Color(200, 200, 200))
        icon:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
        icon:SetDirectionalLight(BOX_FRONT, Color(255, 255, 255))
        icon.LayoutEntity = function(self, ent)
            ent:SetAngles(Angle(0, 0, 0))
        end
        
        btn.Paint = function(s, pw, ph)
            s.HoverP = Lerp(FrameTime() * 10, s.HoverP or 0, s:IsHovered() and 1 or 0)
            local isSel = (selectedBtn == s)
            
            local cA = isSel and 255 or (100 + s.HoverP * 155)
            draw.RoundedBox(8, 0, 0, pw, ph, Color(bC.r, bC.g, bC.b, cA))
            draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(10, 15, 20, 230))
            
            surface.SetDrawColor(bC.r, bC.g, bC.b, isSel and 15 or 5)
            for k=0, ph, 8 do 
                surface.DrawLine(0, k, pw, k) 
            end
            
            if s.HoverP > 0.05 or isSel then
                local a = isSel and 50 or (s.HoverP * 30)
                draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(bC.r, bC.g, bC.b, a))
            end
            
            surface.SetDrawColor(bC.r, bC.g, bC.b, 50)
            surface.DrawOutlinedRect(5, 5, 90, 90)
            
            local push = s.HoverP * 10
            draw.SimpleText(SafeUpper(job.name), "VF4_JobList_Name", 100 + push, 13, Color(255, 255, 255), 0, 0)
            draw.SimpleText(SafeUpper(job.name), "VF4_Subtitle_Aurebesh_Small", 100 + push, 36, Color(150, 150, 150), 0, 0)
            surface.SetDrawColor(bC.r, bC.g, bC.b, 100)
            surface.DrawRect(100, 55, pw - 120, 1)
        end
        
        btn.DoClick = function(s)
            VIRTUSMENU.PlayUI("navigation/aceptar.wav")
            selectedBtn = s
            favBtn.job = job
            infoPnl:SetAlpha(0)
            infoPnl:AlphaTo(255, 0.3, 0)
            if IsValid(VIRTUSMENU.EscapeMenu.ClonePanel) then
                VIRTUSMENU.EscapeMenu.ClonePanel:SetVisible(false)
            end
            
            centerModel:SetModel(m)
            selName:SetText(SafeUpper(job.name))
            selSubName:SetText(SafeUpper(job.name))
            selName:SetTextColor(bC)
            
            statsLayout:Clear()
            
            -- Descripcion
            local descPnl = statsLayout:Add("DPanel")
            descPnl:SetSize(rightW - 40, 100)
            descPnl.Paint = function(st, ppw, pph)
                draw.RoundedBox(6, 0, 0, ppw, pph, Color(colorTheme.r, colorTheme.g, colorTheme.b, 30))
                draw.RoundedBox(6, 1, 1, ppw - 2, pph - 2, Color(15, 20, 25, 200))
                draw.SimpleText("DESCRIPCION:", "VF4_Small", 15, 15, Color(150, 150, 150), 0, 1)
            end
            
            local lblDesc = vgui.Create("RichText", descPnl)
            lblDesc:SetPos(15, 30)
            lblDesc:SetSize(rightW - 70, 60)
            lblDesc:InsertColorChange(255, 255, 255, 255)
            lblDesc:AppendText(job.description or "Sin descripcion.")
            lblDesc.PerformLayout = function(s) s:SetFontInternal("VF4_Small") end
            
            -- Equipamiento
            local wpnsPnl = statsLayout:Add("DPanel")
            wpnsPnl:SetSize(rightW - 40, 100)
            wpnsPnl.Paint = function(st, ppw, pph)
                draw.RoundedBox(6, 0, 0, ppw, pph, Color(colorTheme.r, colorTheme.g, colorTheme.b, 30))
                draw.RoundedBox(6, 1, 1, ppw - 2, pph - 2, Color(15, 20, 25, 200))
                draw.SimpleText("EQUIPAMIENTO:", "VF4_Small", 15, 15, Color(150, 150, 150), 0, 1)
            end
            
            local wpnsScroll = vgui.Create("DScrollPanel", wpnsPnl)
            wpnsScroll:SetPos(15, 30)
            wpnsScroll:SetSize(rightW - 70, 60)
            VIRTUSMENU.StyleScroll(wpnsScroll)
            
            local weapons = job.weapons or {}
            local wPos = 0
            if #weapons == 0 then
                local l = vgui.Create("DLabel", wpnsScroll)
                l:SetFont("VF4_Small")
                l:SetTextColor(Color(255,255,255))
                l:SetText("Sin equipamiento especial.")
                l:SizeToContents()
                l:SetPos(0, 0)
            else
                for _, wep in ipairs(weapons) do
                    local wepName = wep
                    if weapons.GetStored then
                        local wData = weapons.GetStored(wep)
                        if wData and wData.PrintName then wepName = wData.PrintName end
                    end
                    local l = vgui.Create("DLabel", wpnsScroll)
                    l:SetFont("VF4_Small")
                    l:SetTextColor(Color(255,255,255))
                    l:SetText(" " .. wepName)
                    l:SizeToContents()
                    l:SetPos(0, wPos)
                    wPos = wPos + 20
                end
            end
            
            local limit = job.max == 0 and "Ilimitado" or job.max
            local current = team.NumPlayers(job.team)
            local money = DarkRP and DarkRP.formatMoney and DarkRP.formatMoney(job.salary or 0) or ("$" .. (job.salary or 0))
            
            if IsValid(infoPnl.sueldoPnl) then infoPnl.sueldoPnl:Remove() end
            local sueldoPnl = vgui.Create("DPanel", infoPnl)
            infoPnl.sueldoPnl = sueldoPnl
            sueldoPnl:SetSize(rightW - 40, 45)
            sueldoPnl:SetPos(20, infoPnl:GetTall() - 125)
            sueldoPnl.Paint = function(st, ppw, pph)
                draw.RoundedBox(6, 0, 0, ppw, pph, Color(colorTheme.r, colorTheme.g, colorTheme.b, 30))
                draw.RoundedBox(6, 1, 1, ppw - 2, pph - 2, Color(15, 20, 25, 200))
                draw.SimpleText("SUELDO:", "VF4_Small", 15, pph/2, Color(150, 150, 150), 0, 1)
                draw.SimpleText(money, "VF4_Medium", ppw - 15, pph/2, Color(255, 255, 255), 2, 1)
            end
            
            if ply:Team() == job.team then
                deployBtn.btnText = "YA ERES ESTE ROL"
                deployBtn.DoClick = function() end
            elseif job.max ~= 0 and current >= job.max then
                deployBtn.btnText = "EST LLENO"
                deployBtn.DoClick = function() end
            else
                deployBtn.btnText = job.vote and "VOTAR PARA SER" or "SELECCIONAR ROL"
                deployBtn.DoClick = function()
                    VIRTUSMENU.PlayUI("navigation/aceptar.wav")
                    if job.vote then
                        RunConsoleCommand("say", "/vote" .. job.command)
                    else
                        RunConsoleCommand("darkrp", job.command)
                    end
                    if IsValid(VIRTUSMENU.EscapeMenu) then VIRTUSMENU.EscapeMenu:Remove() end
                end
            end
        end
        end
        
        if firstBtn and not keepSelection then
            firstBtn:DoClick()
        end
    end
    
    parent.PopulateJobs()
end



LoadCategoryCircles = function(parent, faction)
    parent:Clear()
    
    local colorTheme = faction == "Imperio" and Color(0, 150, 255) or Color(255, 50, 50)

    local btnBack = CreateElegantButton(parent, "< CAMBIAR BANDO", 20, 20, 140, 25, function()
        LoadFactions(parent)
    end)

    local title = faction == "Imperio" and "DIVISIONES IMPERIALES" or "DIVISIONES REBELDES"
    local lbl = vgui.Create("DLabel", parent)
    lbl:SetText(title)
    lbl:SetFont("VIRTUS_LogoFont_Small")
    lbl:SetTextColor(colorTheme)
    lbl:SizeToContents()
    lbl:SetPos(parent:GetWide()/2 - lbl:GetWide()/2, 40)
    
    local sub = vgui.Create("DLabel", parent)
    sub:SetText("ELIGE UNA DIVISION")
    sub:SetFont("VF4_Header")
    sub:SetTextColor(Color(180,180,180))
    sub:SizeToContents()
    sub:SetPos(parent:GetWide()/2 - sub:GetWide()/2, 90)
    
    local linePnl = vgui.Create("DPanel", parent)
    linePnl:SetPos(parent:GetWide()/2 - 150, 120)
    linePnl:SetSize(300, 2)
    linePnl.Paint = function(s, w, h)
        surface.SetDrawColor(colorTheme.r, colorTheme.g, colorTheme.b, 100)
        surface.DrawRect(0, 0, w, h)
    end

    local allC = DarkRP and DarkRP.getCategories().jobs or {}
    local validCats = {}
    
    local savedFavorites = util.JSONToTable(cookie.GetString("virtus_job_favorites", "{}"))
    local favMembers = {}
    
    for _, cat in pairs(allC) do
        if not cat.members or table.Count(cat.members) == 0 then continue end
        if cat.name == "Cadetes" then continue end
        
        local isImp = Imperiales[cat.name] and true or false
        if faction == "Imperio" and not isImp then continue end
        if faction == "Enemigos" and isImp then continue end
        
        table.insert(validCats, cat)
        
        for _, job in ipairs(cat.members) do
            if savedFavorites[job.command] then
                table.insert(favMembers, job)
            end
        end
    end
    
    if #favMembers > 0 then
        table.insert(validCats, 1, {
            name = "Favoritos",
            members = favMembers,
            isFavCat = true
        })
    end
    
    if #validCats == 0 then
        local nope = vgui.Create("DLabel", parent)
        nope:SetText("No hay categorias para este bando.")
        nope:SetFont("VF4_Header")
        nope:SetTextColor(Color(150,150,150))
        nope:SizeToContents()
        nope:SetPos(parent:GetWide()/2 - nope:GetWide()/2, parent:GetTall()/2)
        return
    end

    local itemW = #validCats < 5 and 330 or 280
    local itemH = #validCats < 5 and 330 or 280
    local spacingX = 20
    local spacingY = 20
    
    local row1Count = math.ceil(#validCats / 2)
    local row2Count = #validCats - row1Count
    if #validCats <= 4 then
        row1Count = #validCats
        row2Count = 0
    end
    
    local container = vgui.Create("DPanel", parent)
    container:SetSize(parent:GetWide(), parent:GetTall() - 150)
    container:SetPos(0, 150)
    container.Paint = nil

    for i, cat in ipairs(validCats) do
        local jobSample = cat.members[1]

        local isRow1 = i <= row1Count
        local rowIdx = isRow1 and i or (i - row1Count)
        local countInRow = isRow1 and row1Count or row2Count
        
        local totalRowW = (countInRow * itemW) + ((countInRow - 1) * spacingX)
        local startX = (container:GetWide() / 2) - (totalRowW / 2)
        local px = startX + ((rowIdx - 1) * (itemW + spacingX))
        
        local py = (container:GetTall() / 2) - (itemH / 2)
        if row2Count > 0 then
            local totalH = (2 * itemH) + spacingY
            local startY = (container:GetTall() / 2) - (totalH / 2)
            py = isRow1 and startY or (startY + itemH + spacingY)
        end

        local pnl = vgui.Create('DButton', container)
        pnl:SetPos(px, py)
        pnl:SetSize(itemW, itemH)
        pnl:SetText('')
        pnl.HoverP = 0
        pnl.OnCursorEntered = function(s) VIRTUSMENU.PlayUI('navigation/movimiento.wav') end
        pnl.Paint = function(s, w, h)
            s.HoverP = Lerp(FrameTime() * 10, s.HoverP, s:IsHovered() and 1 or 0)
            local c = colorTheme
            
            local bordeAlpha = 100 + s.HoverP * 155
            draw.RoundedBox(8, 0, 0, w, h, Color(c.r, c.g, c.b, bordeAlpha))
            
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, Color(10, 15, 20, 230))
            
            surface.SetDrawColor(c.r, c.g, c.b, 5)
            for k=0, h, 8 do 
                surface.DrawLine(0, k, w, k) 
            end
            
            if s.HoverP > 0.05 then
                draw.RoundedBox(8, 1, 1, w - 2, h - 2, Color(c.r, c.g, c.b, s.HoverP * 25))
            end
            
            -- Borde superior removido
            
            surface.SetDrawColor(c.r, c.g, c.b, 50)
            surface.DrawRect(w/2 - 60, h - 10, 120, 2)
            
            draw.SimpleText(SafeUpper(cat.name), 'VF4_Medium_Bold', w/2 + 1, h - 28 + 1, Color(0, 0, 0, 255), 1, 1)
            draw.SimpleText(SafeUpper(cat.name), 'VF4_Medium_Bold', w/2, h - 28, Color(255, 255, 255, 255), 1, 1)
        end
        pnl.DoClick = function()
            VIRTUSMENU.PlayUI('navigation/aceptar.wav')
            LoadJobs(parent, cat.name, cat.members, faction)
        end

        local mdl = vgui.Create('DModelPanel', pnl)
        mdl:SetSize(itemW - 10, itemH - 50)
        mdl:SetPos(5, 5)
        mdl:SetMouseInputEnabled(false)
        
        local mdlPath = type(jobSample.model) == 'table' and jobSample.model[1] or jobSample.model
        if not util.IsValidModel(mdlPath) then
            for _, alt in ipairs(cat.members) do
                local am = type(alt.model) == 'table' and alt.model[1] or alt.model
                if util.IsValidModel(am) then
                    mdlPath = am
                    break
                end
            end
            if not util.IsValidModel(mdlPath) then mdlPath = "models/player/kleiner.mdl" end
        end
        
        mdl:SetModel(mdlPath)
        mdl:SetFOV(34)
        mdl:SetCamPos(Vector(85, 0, 52))
        mdl:SetLookAt(Vector(0, 0, 52))
        mdl:SetAmbientLight(Color(50, 50, 50))
        mdl:SetDirectionalLight(BOX_TOP, Color(150, 200, 255))
        mdl:SetDirectionalLight(BOX_FRONT, Color(255, 255, 255))
        
        mdl.LayoutEntity = function(self, ent)
            ent:SetAngles(Angle(0, 0, 0))
        end
        
        local glowMat = Material("particle/Particle_Glow_04_Additive")
        local oldPaint = mdl.Paint
        mdl.Paint = function(s, w, h)
            local c = colorTheme
            if cat.isFavCat then c = Color(255, 200, 0) end
            
            surface.SetDrawColor(c.r, c.g, c.b, 20 + pnl.HoverP * 60)
            surface.SetMaterial(glowMat)
            surface.DrawTexturedRect(w/2 - 150, h/2 - 150, 300, 300)
            
            oldPaint(s, w, h)
        end
    end
end

LoadFactions = function(parent)
    parent:Clear()
    parent.Paint = nil
    
    local space = 20
    local cardW = (parent:GetWide() - space) / 2
    local h = parent:GetTall()
    
    local matGradU = Material("vgui/gradient-u")
    local matImp = Material("virtus/imperio", "smooth")
    local matReb = Material("virtus/rebelde", "smooth")
    
    -- Mitad Imperio
    local btnImp = vgui.Create("DButton", parent)
    btnImp:SetSize(cardW, h)
    btnImp:SetPos(0, 0)
    btnImp:SetText("")
    btnImp.HoverP = 0
    btnImp.OnCursorEntered = function(s) VIRTUSMENU.PlayUI("navigation/movimiento.wav") end
    btnImp.Paint = function(s, pw, ph)
        s.HoverP = Lerp(FrameTime() * 10, s.HoverP, s:IsHovered() and 1 or 0)
        
        local btnColor = Color(0, 150, 255)
        
        local bordeAlpha = 50 + s.HoverP * 150
        draw.RoundedBox(8, 0, 0, pw, ph, Color(btnColor.r, btnColor.g, btnColor.b, bordeAlpha))
        
        local interiorAlpha = 220 - (s.HoverP * 10)
        draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(15, 15, 15, interiorAlpha))
        
        if s.HoverP > 0.01 then
            draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(btnColor.r, btnColor.g, btnColor.b, s.HoverP * 25))
        end
        
        s.MapAnim = (s.MapAnim or 0) + FrameTime() * (15 + s.HoverP * 30)
        local mapX = pw * 0.75
        local mapY = ph * 0.45
        
        surface.SetDrawColor(btnColor.r, btnColor.g, btnColor.b, 20 + s.HoverP * 50)
        local function DrawOrbit(cx, cy, radius, dashed, gapSize)
            local step = 4
            local lastX, lastY = cx + radius, cy
            for ang = step, 360, step do
                local rad = math.rad(ang)
                local curX = cx + math.cos(rad) * radius
                local curY = cy + math.sin(rad) * radius
                if not dashed or (ang % (gapSize or 30) < (gapSize or 30)/2) then
                    surface.DrawLine(lastX, lastY, curX, curY)
                end
                lastX, lastY = curX, curY
            end
        end
        
        -- Central Star
        local starR = 8 + math.sin(s.MapAnim * 0.1) * 2
        local dPoly = { {x=mapX, y=mapY-starR}, {x=mapX+starR, y=mapY}, {x=mapX, y=mapY+starR}, {x=mapX-starR, y=mapY} }
        draw.NoTexture()
        surface.SetDrawColor(btnColor.r, btnColor.g, btnColor.b, 150)
        surface.DrawPoly(dPoly)
        
        surface.SetDrawColor(btnColor.r, btnColor.g, btnColor.b, 20 + s.HoverP * 60)
        
        -- Structured Orbits
        DrawOrbit(mapX, mapY, 60, false)
        DrawOrbit(mapX, mapY, 110, true, 20)
        DrawOrbit(mapX, mapY, 180, false)
        DrawOrbit(mapX, mapY, 260, true, 40)
        DrawOrbit(mapX, mapY, 350, true, 10)
        
        -- Planet 1 (Inner)
        local p1Rad = math.rad(s.MapAnim * 1.5)
        local p1X, p1Y = mapX + math.cos(p1Rad)*60, mapY + math.sin(p1Rad)*60
        surface.DrawRect(p1X - 3, p1Y - 3, 6, 6)
        
        -- Planet 2 (Middle) with Moon
        local p2Rad = math.rad(s.MapAnim * 0.8 + 45)
        local p2X, p2Y = mapX + math.cos(p2Rad)*110, mapY + math.sin(p2Rad)*110
        surface.DrawRect(p2X - 5, p2Y - 5, 10, 10)
        surface.DrawOutlinedRect(p2X - 12, p2Y - 12, 24, 24)
        local m1Rad = math.rad(s.MapAnim * -3)
        surface.DrawRect(p2X + math.cos(m1Rad)*18 - 2, p2Y + math.sin(m1Rad)*18 - 2, 4, 4)
        
        -- Planet 3 (Outer) Diamond shape
        local p3Rad = math.rad(s.MapAnim * 0.4 + 180)
        local p3X, p3Y = mapX + math.cos(p3Rad)*260, mapY + math.sin(p3Rad)*260
        local p3Poly = { {x=p3X, y=p3Y-6}, {x=p3X+6, y=p3Y}, {x=p3X, y=p3Y+6}, {x=p3X-6, y=p3Y} }
        surface.SetDrawColor(btnColor.r, btnColor.g, btnColor.b, 100 + s.HoverP * 155)
        surface.DrawPoly(p3Poly)
        surface.SetDrawColor(btnColor.r, btnColor.g, btnColor.b, 20 + s.HoverP * 30)
        surface.DrawLine(mapX, mapY, p3X, p3Y) -- Connector line to outer planet
        
        local iconSize = 250 + (s.HoverP * 30)
        
        s.IconTime = s.IconTime or 0
        if s:IsHovered() then
            s.IconTime = s.IconTime + FrameTime() * 4
        else
            local rem = s.IconTime % (math.pi * 2)
            if rem > math.pi then rem = rem - (math.pi * 2) end
            s.IconTime = Lerp(FrameTime() * 10, rem, 0)
        end
        local cosVal = math.cos(s.IconTime)
        local scale = math.abs(cosVal)
        local currentIconW = iconSize * scale
        
        surface.SetMaterial(matImp)
        surface.SetDrawColor(btnColor.r, btnColor.g, btnColor.b, 50 + s.HoverP * 205)
        
        local ix = (pw / 2) - (currentIconW / 2)
        local iy = (ph / 2) - (iconSize / 2)
        
        if cosVal > 0 then
            surface.DrawTexturedRectUV(ix, iy, currentIconW, iconSize, 0, 0, 1, 1)
        else
            surface.DrawTexturedRectUV(ix, iy, currentIconW, iconSize, 1, 0, 0, 1)
        end
        
        local push = s.HoverP * 10
        draw.SimpleText("IMPERIO GALACTICO", "VF4_TitleBig", 25 + push, 25, Color(255, 255, 255, 255), 0, 0)
        draw.SimpleText("IMPERIO GALACTICO", "VF4_Subtitle_Aurebesh_Large", 27 + push, 72, Color(150, 150, 150, 255), 0, 0)
        
        surface.SetDrawColor(btnColor.r, btnColor.g, btnColor.b, 100 + s.HoverP * 100)
        surface.DrawRect(25 + push, 100, 250, 2)
        
        local actionText = "> ACCEDER A DIVISION"
        local actionColor = Color(btnColor.r, btnColor.g, btnColor.b, 150 + s.HoverP * 105)
        draw.SimpleText(actionText, "VF4_Medium", pw - 25, ph - 35, actionColor, 2, 1)
    end
    btnImp.DoClick = function()
        VIRTUSMENU.PlayUI("navigation/aceptar.wav")
        parent.Paint = function(s, pw, ph) end
        LoadCategoryCircles(parent, "Imperio")
    end
    
    -- Mitad Enemigos
    local btnReb = vgui.Create("DButton", parent)
    btnReb:SetSize(cardW, h)
    btnReb:SetPos(cardW + space, 0)
    btnReb:SetText("")
    btnReb.HoverP = 0
    btnReb.OnCursorEntered = function(s) VIRTUSMENU.PlayUI("navigation/movimiento.wav") end
    btnReb.Paint = function(s, pw, ph)
        s.HoverP = Lerp(FrameTime() * 10, s.HoverP, s:IsHovered() and 1 or 0)
        
        local btnColor = Color(255, 50, 50) -- RED for Rebeldes
        
        local bordeAlpha = 50 + s.HoverP * 150
        draw.RoundedBox(8, 0, 0, pw, ph, Color(btnColor.r, btnColor.g, btnColor.b, bordeAlpha))
        
        local interiorAlpha = 220 - (s.HoverP * 10)
        draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(15, 15, 15, interiorAlpha))
        
        if s.HoverP > 0.01 then
            draw.RoundedBox(8, 1, 1, pw - 2, ph - 2, Color(btnColor.r, btnColor.g, btnColor.b, s.HoverP * 25))
        end
        
        s.MapAnim = (s.MapAnim or 0) + FrameTime() * (20 + s.HoverP * 40)
        local mapX = pw * 0.25
        local mapY = ph * 0.6
        
        surface.SetDrawColor(btnColor.r, btnColor.g, btnColor.b, 15 + s.HoverP * 60)
        local function DrawOrbit(cx, cy, radius, dashed, segments)
            local step = 360 / (segments or 36)
            local lastX, lastY = cx + radius, cy
            for ang = step, 360, step do
                local rad = math.rad(ang)
                local curX = cx + math.cos(rad) * radius
                local curY = cy + math.sin(rad) * radius
                if not dashed or (ang % (step*4) < step*2) then
                    surface.DrawLine(lastX, lastY, curX, curY)
                end
                lastX, lastY = curX, curY
            end
        end
        
        DrawOrbit(mapX, mapY, 60, true, 30)
        DrawOrbit(mapX, mapY, 120, false, 45)
        DrawOrbit(mapX, mapY, 190, true, 60)
        DrawOrbit(mapX, mapY, 280, true, 40)
        
        -- Radar sweep
        local sweepRad = math.rad(s.MapAnim * 2)
        surface.SetDrawColor(btnColor.r, btnColor.g, btnColor.b, 10 + s.HoverP * 40)
        surface.DrawLine(mapX, mapY, mapX + math.cos(sweepRad)*280, mapY + math.sin(sweepRad)*280)
        
        surface.SetDrawColor(btnColor.r, btnColor.g, btnColor.b, 20 + s.HoverP * 60)
        
        -- Tactical Node 1 (Cross)
        local p1Rad = math.rad(s.MapAnim * -1.5)
        local p1X, p1Y = mapX + math.cos(p1Rad)*60, mapY + math.sin(p1Rad)*60
        surface.DrawLine(p1X - 6, p1Y - 6, p1X + 6, p1Y + 6)
        surface.DrawLine(p1X + 6, p1Y - 6, p1X - 6, p1Y + 6)
        
        -- Tactical Node 2 (Square with brackets)
        local p2Rad = math.rad(s.MapAnim * 0.8 + 120)
        local p2X, p2Y = mapX + math.cos(p2Rad)*120, mapY + math.sin(p2Rad)*120
        surface.DrawRect(p2X - 3, p2Y - 3, 6, 6)
        surface.DrawLine(p2X - 8, p2Y - 4, p2X - 8, p2Y + 4)
        surface.DrawLine(p2X + 8, p2Y - 4, p2X + 8, p2Y + 4)
        
        -- Tactical Node 3 (Outer sector highlight)
        local p3Rad = math.rad(s.MapAnim * -0.5 + 240)
        local p3X, p3Y = mapX + math.cos(p3Rad)*190, mapY + math.sin(p3Rad)*190
        surface.DrawOutlinedRect(p3X - 5, p3Y - 5, 10, 10)
        
        -- Connecting lines for tactical view
        surface.SetDrawColor(btnColor.r, btnColor.g, btnColor.b, 15 + s.HoverP * 25)
        surface.DrawLine(p1X, p1Y, p2X, p2Y)
        surface.DrawLine(p2X, p2Y, p3X, p3Y)
        
        local iconSize = 250 + (s.HoverP * 30)
        
        s.IconTime = s.IconTime or 0
        if s:IsHovered() then
            s.IconTime = s.IconTime + FrameTime() * 4
        else
            local rem = s.IconTime % (math.pi * 2)
            if rem > math.pi then rem = rem - (math.pi * 2) end
            s.IconTime = Lerp(FrameTime() * 10, rem, 0)
        end
        local cosVal = math.cos(s.IconTime)
        local scale = math.abs(cosVal)
        local currentIconW = iconSize * scale
        
        surface.SetMaterial(matReb)
        surface.SetDrawColor(btnColor.r, btnColor.g, btnColor.b, 50 + s.HoverP * 205)
        
        local ix = (pw / 2) - (currentIconW / 2)
        local iy = (ph / 2) - (iconSize / 2)
        
        if cosVal > 0 then
            surface.DrawTexturedRectUV(ix, iy, currentIconW, iconSize, 0, 0, 1, 1)
        else
            surface.DrawTexturedRectUV(ix, iy, currentIconW, iconSize, 1, 0, 0, 1)
        end
        
        local push = s.HoverP * 10
        draw.SimpleText("RESTO DE LA GALAXIA", "VF4_TitleBig", pw - 25 - push, 25, Color(255, 255, 255, 255), 2, 0)
        draw.SimpleText("RESTO DE LA GALAXIA", "VF4_Subtitle_Aurebesh_Large", pw - 27 - push, 72, Color(150, 150, 150, 255), 2, 0)
        
        surface.SetDrawColor(btnColor.r, btnColor.g, btnColor.b, 100 + s.HoverP * 100)
        surface.DrawRect(pw - 275 - push, 100, 250, 2)
        
        local actionText = "< ACCEDER A DIVISION"
        local actionColor = Color(btnColor.r, btnColor.g, btnColor.b, 150 + s.HoverP * 105)
        draw.SimpleText(actionText, "VF4_Medium", pw - 25, ph - 35, actionColor, 2, 1)
    end
    btnReb.DoClick = function()
        VIRTUSMENU.PlayUI("navigation/aceptar.wav")
        parent.Paint = function(s, pw, ph) end
        LoadCategoryCircles(parent, "Enemigos")
    end
end
VIRTUSMENU.BuildF4Tab = LoadFactions











