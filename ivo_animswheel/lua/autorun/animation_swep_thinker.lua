--[[
Only allowed to use in Addons by
Mattis 'Mattzimann' Krämer
Edited to use a Radial Menu by Antigravity
]]--

AddCSLuaFile()

AnimationSWEP = {}

local AnimationsList = {
    {
        name = "Comunicador",
        id = "comlink",
        deactivateOnMove = 5,
        gesture = {
            ["ValveBiped.Bip01_R_UpperArm"] = Angle(32.9448, -103.5211, 2.2273),
            ["ValveBiped.Bip01_R_Forearm"] = Angle(-90.3271, -31.3616, -41.8804),
            ["ValveBiped.Bip01_R_Hand"] = Angle(0,0,-24),
        }
    },
    {
        name = "Cruzar los Brazos",
        id = "cross_arms_infront",
        deactivateOnMove = 5,
        buyable = true,
        gesture = {
            ["ValveBiped.Bip01_R_Forearm"] = Angle(-43.779933929443,-107.18412780762,15.918969154358),
            ["ValveBiped.Bip01_R_UpperArm"] = Angle(20.256689071655, -57.223915100098, -6.1269416809082),
            ["ValveBiped.Bip01_L_UpperArm"] = Angle(-28.913911819458, -59.408206939697, 1.0253102779388),
            ["ValveBiped.Bip01_R_Thigh"] = Angle(4.7250719070435, -6.0294013023376, -0.46876749396324),
            ["ValveBiped.Bip01_L_Thigh"] = Angle(-7.6583762168884, -0.21996378898621, 0.4060270190239),
            ["ValveBiped.Bip01_L_Forearm"] = Angle(51.038677215576, -120.44165039063, -18.86986541748),
            ["ValveBiped.Bip01_R_Hand"] = Angle(14.424224853516, -33.406204223633, -7.2624106407166),
            ["ValveBiped.Bip01_L_Hand"] = Angle(25.959447860718, 31.564517974854, -14.979378700256),
        }
    },
    {
        name = "Manos en la espalda",
        id = "cross_arms",
        deactivateOnMove = 5,
        buyable = true,
        gesture = {
            ["ValveBiped.Bip01_R_UpperArm"] = Angle(3.809, 15.382, 2.654),
            ["ValveBiped.Bip01_R_Forearm"] = Angle(-63.658, 1.8 , -84.928),
            ["ValveBiped.Bip01_L_UpperArm"] = Angle(3.809, 15.382, 2.654),
            ["ValveBiped.Bip01_L_Forearm"] = Angle(53.658, -29.718, 31.455),
            ["ValveBiped.Bip01_R_Thigh"] = Angle(4.829, 0, 0),
            ["ValveBiped.Bip01_L_Thigh"] = Angle(-8.89, 0, 0),
        }
    },
    {
        name = "Dame los 5",
        id = "high_five",
        deactivateOnMove = 110,
        buyable = true,
        gesture = {
            ["ValveBiped.Bip01_L_Forearm"] = Angle(25,-65,25),
            ["ValveBiped.Bip01_L_UpperArm"] = Angle(-70,-180,70),
        }
    },
    {
        name = "Holocomunicador",
        id = "hololink",
        deactivateOnMove = 5,
        gesture = {
            ["ValveBiped.Bip01_R_UpperArm"] = Angle(10,-20),
            ["ValveBiped.Bip01_R_Hand"] = Angle(0,1,50),
            ["ValveBiped.Bip01_Head1"] = Angle(0,-30,-20),
            ["ValveBiped.Bip01_R_Forearm"] = Angle(0,-65,39.8863),
        }
    },
    {
        name = "Dedo del medio",
        id = "middlefinger",
        deactivateOnMove = 110,
        buyable = true,
        gesture = {
            ["ValveBiped.Bip01_R_UpperArm"] = Angle(15,-55,-0),
            ["ValveBiped.Bip01_R_Forearm"] = Angle(0,-55,-0),
            ["ValveBiped.Bip01_R_Hand"] = Angle(20,20,90),
            ["ValveBiped.Bip01_R_Finger1"] = Angle(20,-40,-0),
            ["ValveBiped.Bip01_R_Finger3"] = Angle(0,-30,0),
            ["ValveBiped.Bip01_R_Finger4"] = Angle(-10,-40,0),
            ["ValveBiped.Bip01_R_Finger11"] = Angle(-0,-70,-0),
            ["ValveBiped.Bip01_R_Finger31"] = Angle(0,-70,0),
            ["ValveBiped.Bip01_R_Finger41"] = Angle(0,-70,0),
            ["ValveBiped.Bip01_R_Finger12"] = Angle(-0,-70,-0),
            ["ValveBiped.Bip01_R_Finger32"] = Angle(0,-70,0),
            ["ValveBiped.Bip01_R_Finger42"] = Angle(0,-70,-0),
        }
    },
    {
        name = "Señalar",
        id = "point_in_direction",
        deactivateOnMove = 110,
        buyable = true,
        gesture = {
            ["ValveBiped.Bip01_R_Finger2"] = Angle(4.151602268219, -52.963024139404, 0.42117667198181),
            ["ValveBiped.Bip01_R_Finger21"] = Angle(0.00057629722869024, -58.618747711182, 0.001297949347645),
            ["ValveBiped.Bip01_R_Finger3"] = Angle(4.151602268219, -52.963024139404, 0.42117667198181),
            ["ValveBiped.Bip01_R_Finger31"] = Angle(0.00057629722869024, -58.618747711182, 0.001297949347645),
            ["ValveBiped.Bip01_R_Finger4"] = Angle(4.151602268219, -52.963024139404, 0.42117667198181),
            ["ValveBiped.Bip01_R_Finger41"] = Angle(0.00057629722869024, -58.618747711182, 0.001297949347645),
            ["ValveBiped.Bip01_R_UpperArm"] = Angle(25.019514083862, -87.288040161133, -0.0012286090059206),
        }
    },
    {
        name = "Saludo",
        id = "salute",
        deactivateOnMove = 100,
        gesture = {
            ["ValveBiped.Bip01_R_UpperArm"] = Angle(80, -95, -77.5),
            ["ValveBiped.Bip01_R_Forearm"] = Angle(35, -125, -5),
        }
    },
    {
        name = "Rendirse",
        id = "surrender",
        deactivateOnMove = 110,
        gesture = {
            ["ValveBiped.Bip01_L_Forearm"] = Angle(25,-65,25),
            ["ValveBiped.Bip01_R_Forearm"] = Angle(-25,-65,-25),
            ["ValveBiped.Bip01_L_UpperArm"] = Angle(-70,-180,70),
            ["ValveBiped.Bip01_R_UpperArm"] = Angle(70,-180,-70),
        }
    },
    {
        name = "Baile (Dance)",
        id = "act_dance",
        type = "engine_act",
        buyable = true,
        act = ACT_GMOD_TAUNT_DANCE
    },
    {
        name = "Baile (Muscle)",
        id = "act_muscle",
        type = "engine_act",
        buyable = true,
        act = ACT_GMOD_TAUNT_MUSCLE
    },
    {
        name = "Bailarín",
        id = "seq_bailarin",
        type = "sequence",
        sequence = "wos_genji_dance"
    },
    {
        name = "Baile del Robot",
        id = "seq_robot",
        type = "engine_act",
        act = ACT_GMOD_TAUNT_ROBOT
    },
    {
        name = "Entendido",
        id = "seq_agree",
        type = "sequence",
        sequence = "cwa_emo_nodyes"
    },
    {
        name = "Señalar",
        id = "seq_point",
        type = "sequence",
        sequence = "cwa_emo_point"
    },
    {
        name = "Reverencia",
        id = "seq_bow",
        type = "sequence",
        sequence = "cwa_emo_bow"
    },
    {
        name = "Baile Básico 1",
        id = "seq_dance1",
        type = "sequence",
        sequence = "cwa_emo_dancebasic1"
    },
    {
        name = "Baile Básico 3",
        id = "seq_dance3",
        type = "sequence",
        sequence = "cwa_emo_dancebasic3"
    },
    {
        name = "Flexiones",
        id = "seq_pushups",
        type = "sequence",
        sequence = "cwa_amb_pushups"
    },
    {
        name = "Saludo de Guardia",
        id = "seq_guardsalute",
        type = "sequence",
        sequence = "cwa_amb_guardsalute"
    },
    {
        name = "Guardia Firme",
        id = "seq_guardstand",
        type = "sequence",
        sequence = "cwa_amb_guardstand"
    },
    {
        name = "Meditar",
        id = "seq_meditate",
        type = "sequence",
        sequence = "cwa_emo_sitandmeditate"
    }
}

local function IsAnimBuyable(id)
    for _, anim in ipairs(AnimationsList) do
        if anim.id == id then
            return anim.buyable or (anim.price and anim.price > 0)
        end
    end
    return false
end

if SERVER then
    util.AddNetworkString("EGM_Animation_Toggle")
    util.AddNetworkString("EGM_Animation_ForceAct")
    util.AddNetworkString("EGM_Animation_ForceSequence")
    util.AddNetworkString("EGM_Animation_PlaySequence")
    util.AddNetworkString("IvoAnims_SyncUnlocked")
    
    -- DB Logic
    hook.Add("IVOSAM_DatabaseConnected", "IvoAnims_InitDB", function()
        if IVO_SAM and IVO_SAM.DB then
            IVO_SAM.DB.Query([[
                CREATE TABLE IF NOT EXISTS ivo_anims_purchases (
                    steamid VARCHAR(30) NOT NULL,
                    anim_id VARCHAR(50) NOT NULL,
                    PRIMARY KEY (steamid, anim_id)
                )
            ]], function()
                print("[IvoAnims] Database initialized.")
            end)
        end
    end)
    
    -- API for the store to give animations
    function IvoAnims_GiveAnimation(ply, anim_id)
        if not IsValid(ply) or not IVO_SAM then return false end
        local sid = ply:SteamID64()
        if not sid then return false end
        
        -- Use INSERT IGNORE for MySQL or similar logic. 
        -- If it's SQLite, INSERT OR IGNORE works too.
        local queryStr = "INSERT IGNORE INTO ivo_anims_purchases (steamid, anim_id) VALUES (%s, %s)"
        if not IVO_SAM.Config.USE_MYSQL then
            queryStr = "INSERT OR IGNORE INTO ivo_anims_purchases (steamid, anim_id) VALUES (%s, %s)"
        end
        
        IVO_SAM.DB.Query(string.format(queryStr, 
            IVO_SAM.DB.Escape(sid), IVO_SAM.DB.Escape(anim_id)), function()
            
            ply.IvoAnims_Unlocked = ply.IvoAnims_Unlocked or {}
            ply.IvoAnims_Unlocked[anim_id] = true
            
            -- Sync to client
            net.Start("IvoAnims_SyncUnlocked")
                net.WriteString(anim_id)
                net.WriteBool(true)
            net.Send(ply)
        end)
    end
    
    -- API for the store to remove animations
    function IvoAnims_RemoveAnimation(ply, anim_id)
        if not IsValid(ply) or not IVO_SAM then return false end
        local sid = ply:SteamID64()
        if not sid then return false end
        
        IVO_SAM.DB.Query(string.format("DELETE FROM ivo_anims_purchases WHERE steamid = %s AND anim_id = %s", 
            IVO_SAM.DB.Escape(sid), IVO_SAM.DB.Escape(anim_id)), function()
            
            ply.IvoAnims_Unlocked = ply.IvoAnims_Unlocked or {}
            ply.IvoAnims_Unlocked[anim_id] = false
            
            -- Sync to client
            net.Start("IvoAnims_SyncUnlocked")
                net.WriteString(anim_id)
                net.WriteBool(false)
            net.Send(ply)
        end)
    end
    
    hook.Add("PlayerInitialSpawn", "IvoAnims_LoadPurchases", function(ply)
        ply.IvoAnims_Unlocked = {}
        timer.Simple(2, function()
            if not IsValid(ply) or not IVO_SAM then return end
            local sid = ply:SteamID64()
            if not sid then return end
            
            IVO_SAM.DB.Query(string.format("SELECT anim_id FROM ivo_anims_purchases WHERE steamid = %s", IVO_SAM.DB.Escape(sid)), function(data)
                if not IsValid(ply) then return end
                if data then
                    for _, row in ipairs(data) do
                        ply.IvoAnims_Unlocked[row.anim_id] = true
                    end
                end
                
                net.Start("IvoAnims_SyncUnlocked")
                    net.WriteString("ALL")
                    net.WriteTable(ply.IvoAnims_Unlocked)
                net.Send(ply)
            end)
        end)
    end)

    net.Receive("EGM_Animation_Toggle", function(len, ply)
        local id = net.ReadString()
        if id == "" then
            AnimationSWEP:Toggle(ply, false)
        else
            if IsAnimBuyable(id) then
                if not ply.IvoAnims_Unlocked or not ply.IvoAnims_Unlocked[id] then
                    ply:ChatPrint("No tienes esta animación desbloqueada. ¡Cómprala en la tienda!")
                    return
                end
            end
            
            local deactivateOnMove = net.ReadInt(16)
            if not ply:GetNWBool("animationStatus") or ply:GetNWString("animationClass") ~= id then
                if not ply:Crouching() and ply:GetVelocity():Length() < 5 and not ply:InVehicle() then
                    AnimationSWEP:Toggle(ply, true, id, deactivateOnMove)
                end
            end
        end
    end)
    
    net.Receive("EGM_Animation_ForceAct", function(len, ply)
        local act = net.ReadInt(32)
        
        local anim_id
        for _, anim in ipairs(AnimationsList) do
            if anim.type == "engine_act" and anim.act == act then
                anim_id = anim.id
                break
            end
        end
        
        if anim_id and IsAnimBuyable(anim_id) then
            if not ply.IvoAnims_Unlocked or not ply.IvoAnims_Unlocked[anim_id] then
                ply:ChatPrint("No tienes esta animación desbloqueada. ¡Cómprala en la tienda!")
                return
            end
        end
        
        -- Desactivar cualquier gesto estático primero (sin restaurar arma)
        ply:SetNWBool("animationStatus", false)
        ply:SetNWInt("deactivateOnMove", 5)
        ply.EGM_SeqActive = nil
        ply.EGM_SeqClass = nil
        ply.EGM_SeqStartTime = nil
        
        -- Forzar a manos vacías para que el baile se vea bien
        local emptyWeapons = {"unarmed", "keys", "weapon_fists", "gmod_camera", "none"}
        local activeWep = ply:GetActiveWeapon()
        local needsSwitch = false
        if IsValid(activeWep) and not table.HasValue(emptyWeapons, activeWep:GetClass()) then
            ply.IvoAnim_PrevWeapon = activeWep:GetClass()
            for _, emptyClass in ipairs(emptyWeapons) do
                if ply:HasWeapon(emptyClass) then
                    ply:SelectWeapon(emptyClass)
                    needsSwitch = true
                    break
                end
            end
        end

        local function PlayGesture()
            if not IsValid(ply) then return end
            ply:DoCustomAnimEvent(PLAYERANIMEVENT_CUSTOM_GESTURE, act)
            ply:AnimRestartGesture(GESTURE_SLOT_CUSTOM, act, true)
            ply:AnimRestartGesture(GESTURE_SLOT_TAUNT, act, true)
        end
        
        if needsSwitch then
            timer.Simple(0.5, PlayGesture)
        else
            PlayGesture()
        end
    end)


end

if CLIENT then
    CreateClientConVar("virtus_bind_anims", "109", true, false)
    
    local function IsAnimKeyDown()
        local val = GetConVar("virtus_bind_anims")
        if not val then return input.IsMouseDown(MOUSE_MIDDLE) end
        val = val:GetInt()
        if val == 0 then return false end
        if val >= 107 and val <= 113 then
            return input.IsMouseDown(val)
        else
            return input.IsKeyDown(val)
        end
    end

    local LocalPlayerUnlockedAnims = {}
    
    net.Receive("IvoAnims_SyncUnlocked", function()
        local type = net.ReadString()
        if type == "ALL" then
            LocalPlayerUnlockedAnims = net.ReadTable()
        else
            local status = net.ReadBool()
            LocalPlayerUnlockedAnims[type] = status
        end
    end)



    AnimationSWEP.GestureAngles = {}
    for _, anim in ipairs(AnimationsList) do
        AnimationSWEP.GestureAngles[anim.id] = anim.gesture
    end

    local function applyAnimation(ply, targetValue, class)
        if not IsValid(ply) then return end
        if ply.animationSWEPAngle ~= targetValue then
            ply.animationSWEPAngle = Lerp(FrameTime() * 5, ply.animationSWEPAngle, targetValue)
        end

        local oldanimationclass = ply:GetNWString("oldanimationClass")
        if oldanimationclass ~= class and AnimationSWEP.GestureAngles[oldanimationclass] then
        	for boneName, angle in pairs(AnimationSWEP.GestureAngles[oldanimationclass]) do
            local bone = ply:LookupBone(boneName)

            if bone then
                ply:ManipulateBoneAngles( bone, angle * 0)
            end
       		end
        end

       	ply:SetNWString("oldanimationClass",class)

       if AnimationSWEP.GestureAngles[class] then
        for boneName, angle in pairs(AnimationSWEP.GestureAngles[class]) do
            local bone = ply:LookupBone(boneName)

            if bone then
                ply:ManipulateBoneAngles( bone, angle * ply.animationSWEPAngle)
            end
        end
   		end

        if math.Round(ply.animationSWEPAngle, 2) == targetValue and targetValue == 0 then
            ply:SetNWString("animationClass", "")
        end
    end

    hook.Add("Think", "AnimationSWEP.Think", function ()
       	for _, ply in pairs( player.GetHumans() ) do
            local animationClass = ply:GetNWString("animationClass")

            if animationClass ~= "" then
                if not ply.animationSWEPAngle then
                    ply.animationSWEPAngle = 0
                end

                if ply:GetNWBool("animationStatus") then
                    applyAnimation(ply, 1, animationClass)
                else
                    applyAnimation(ply, 0, animationClass)
                end
            end
    	end
	end)
    
    local blurMat = Material("pp/blurscreen")
    local matLock = Material("icon16/lock.png")

    local function DrawBlur(alpha)
        surface.SetDrawColor(255, 255, 255, alpha)
        surface.SetMaterial(blurMat)
        for i = 1, 3 do
            blurMat:SetFloat("$blur", (i / 3) * 6 * (alpha/255))
            blurMat:Recompute()
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        end
        surface.SetDrawColor(0, 0, 0, alpha * 0.4)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end

    local function DrawSlice(centerX, centerY, radius, innerRadius, startAngle, endAngle, color, cutDepth, outlineColor)
        cutDepth = cutDepth or 18
        local cutAngle = 0.05
        
        if radius <= innerRadius then return end
        
        local currentCutDepth = math.min(cutDepth, (radius - innerRadius) * 0.8)
        local segments = math.max(12, math.ceil(80 * (endAngle - startAngle) / (math.pi * 2)))
        local step = (endAngle - startAngle) / segments
        
        local function GetInnerPos(a)
            if a <= endAngle - cutAngle + 0.0001 then
                return {x = centerX + math.cos(a) * innerRadius, y = centerY + math.sin(a) * innerRadius}
            else
                local pStart = {x = centerX + math.cos(endAngle - cutAngle) * innerRadius, y = centerY + math.sin(endAngle - cutAngle) * innerRadius}
                local pEnd = {x = centerX + math.cos(endAngle) * (innerRadius + currentCutDepth), y = centerY + math.sin(endAngle) * (innerRadius + currentCutDepth)}
                local fraction = math.Clamp((a - (endAngle - cutAngle)) / cutAngle, 0, 1)
                return {x = Lerp(fraction, pStart.x, pEnd.x), y = Lerp(fraction, pStart.y, pEnd.y)}
            end
        end

        surface.SetDrawColor(color)
        draw.NoTexture()
        
        local outlinePointsOuter = {}
        local outlinePointsInner = {}

        for i = 0, segments - 1 do
            local a1 = startAngle + i * step
            local a2 = startAngle + (i + 1) * step
            if i == segments - 1 then a2 = endAngle end
            
            local p1 = {x = centerX + math.cos(a1) * radius, y = centerY + math.sin(a1) * radius}
            local p2 = {x = centerX + math.cos(a2) * radius, y = centerY + math.sin(a2) * radius}
            local p3 = GetInnerPos(a2)
            local p4 = GetInnerPos(a1)
            
            surface.DrawPoly({p1, p2, p3, p4})
            
            if i == 0 then
                table.insert(outlinePointsOuter, p1)
                table.insert(outlinePointsInner, p4)
            end
            table.insert(outlinePointsOuter, p2)
            table.insert(outlinePointsInner, p3)
        end
        
        if outlineColor then
            surface.SetDrawColor(outlineColor)
            
            for i = 1, #outlinePointsOuter - 1 do
                surface.DrawLine(outlinePointsOuter[i].x, outlinePointsOuter[i].y, outlinePointsOuter[i+1].x, outlinePointsOuter[i+1].y)
            end
            
            for i = 1, #outlinePointsInner - 1 do
                surface.DrawLine(outlinePointsInner[i].x, outlinePointsInner[i].y, outlinePointsInner[i+1].x, outlinePointsInner[i+1].y)
            end
            
            surface.DrawLine(outlinePointsInner[1].x, outlinePointsInner[1].y, outlinePointsOuter[1].x, outlinePointsOuter[1].y)
            surface.DrawLine(outlinePointsInner[#outlinePointsInner].x, outlinePointsInner[#outlinePointsInner].y, outlinePointsOuter[#outlinePointsOuter].x, outlinePointsOuter[#outlinePointsOuter].y)
        end
    end

    surface.CreateFont("Virtus_AnimFont", {
        font = "Montserrat",
        size = 18,
        weight = 800,
        antialias = true,
        shadow = false
    })
    
    surface.CreateFont("Virtus_AnimFont_Title", {
        font = "Montserrat",
        size = 24,
        weight = 800,
        antialias = true,
        shadow = true
    })

    local radialPanel = nil
    local wasMiddleDown = false
    
    local function OpenRadial()
        if IsValid(radialPanel) then return end
        
        radialPanel = vgui.Create("DFrame")
        radialPanel:SetSize(ScrW(), ScrH())
        radialPanel:SetTitle("")
        radialPanel:SetDraggable(false)
        radialPanel:ShowCloseButton(false)
        radialPanel:SetPaintShadow(false)
        radialPanel:MakePopup()
        radialPanel:SetKeyboardInputEnabled(false)
        radialPanel.StartTime = SysTime()
        radialPanel.AlphaAnim = 0
        
        radialPanel.SegHover = {}
        radialPanel.CenterHover = 0
        
        -- Filter visible animations based on ownership
        radialPanel.AllOwnedAnims = {}
        for _, anim in ipairs(AnimationsList) do
            local isBuyable = anim.buyable or (anim.price and anim.price > 0)
            local hasAnim = not isBuyable or LocalPlayerUnlockedAnims[anim.id]
            if hasAnim then
                table.insert(radialPanel.AllOwnedAnims, anim)
            end
        end
        
        radialPanel.CurrentPage = 1
        radialPanel.MaxPerPage = 8
        radialPanel.TotalPages = math.ceil(#radialPanel.AllOwnedAnims / radialPanel.MaxPerPage)
        if radialPanel.TotalPages == 0 then radialPanel.TotalPages = 1 end
        
        radialPanel.BuildPage = function(self)
            self.VisibleAnims = {}
            local startIdx = (self.CurrentPage - 1) * self.MaxPerPage + 1
            local endIdx = math.min(startIdx + self.MaxPerPage - 1, #self.AllOwnedAnims)
            
            for i = startIdx, endIdx do
                table.insert(self.VisibleAnims, self.AllOwnedAnims[i])
            end
        end
        radialPanel:BuildPage()
        
        local centerX, centerY = ScrW() / 2, ScrH() / 2
        local outerRadius = 240
        local innerRadius = 140
        
        gui.SetMousePos(centerX, centerY)
        
        radialPanel.Paint = function(self, w, h)
            local animProgress = math.Clamp((SysTime() - self.StartTime) / 0.2, 0, 1)
            self.AlphaAnim = Lerp(FrameTime() * 10, self.AlphaAnim, self.Closing and 0 or 255 * animProgress)
            
            if self.Closing and self.AlphaAnim < 5 then
                self:Remove()
                return
            end
            
            DrawBlur(self.AlphaAnim)
            
            local numAnims = #self.VisibleAnims
            
            -- If no animations are owned (very rare if there are free ones), don't break
            if numAnims == 0 then
                surface.SetFont("Virtus_AnimFont_Title")
                local noAnimsText = "NO TIENES ANIMACIONES"
                local tw, th = surface.GetTextSize(noAnimsText)
                surface.SetTextColor(255, 100, 100, self.AlphaAnim)
                surface.SetTextPos(centerX - tw/2, centerY - th/2)
                surface.DrawText(noAnimsText)
                
                if not IsAnimKeyDown() and not self.Closing then
                    self.Closing = true
                end
                return
            end
            
            local mouseX, mouseY = input.GetCursorPos()
            
            local dx = mouseX - centerX
            local dy = mouseY - centerY
            local dist = math.sqrt(dx*dx + dy*dy)
            
            local mouseAngle = math.atan2(dy, dx)
            if mouseAngle < 0 then mouseAngle = mouseAngle + math.pi * 2 end
            
            local segmentAngle = math.pi * 2 / numAnims
            
            local hoveredIndex = nil
            if dist > 50 then
                local adjustedAngle = mouseAngle + segmentAngle / 2
                if adjustedAngle > math.pi * 2 then adjustedAngle = adjustedAngle - math.pi * 2 end
                hoveredIndex = math.floor(adjustedAngle / segmentAngle) + 1
            end
            self.HoveredIndex = hoveredIndex
            
            for i, anim in ipairs(self.VisibleAnims) do
                local startAngle = (i - 1) * segmentAngle - (segmentAngle / 2)
                local endAngle = startAngle + segmentAngle
                local padAngle = 0.04
                
                local isHovered = (i == hoveredIndex)
                
                self.SegHover[i] = Lerp(FrameTime() * 12, self.SegHover[i] or 0, isHovered and 1 or 0)
                local hp = self.SegHover[i]
                
                local sliceAlpha = (self.AlphaAnim / 255)
                local baseColor = Color(20, 20, 20, 220 * sliceAlpha)
                local borderColor = Color(255, 255, 255, 25 * sliceAlpha)
                
                local animOuterRadius = outerRadius * (0.8 + 0.2 * animProgress)
                DrawSlice(centerX, centerY, animOuterRadius, innerRadius, startAngle + padAngle, endAngle - padAngle, baseColor, 18, borderColor)
                
                if hp > 0.01 then
                    local animRadius = innerRadius + (animOuterRadius - innerRadius) * hp
                    local hoverColor = Color(0, 150, 255, 200 * hp * sliceAlpha)
                    local hoverBorder = Color(0, 180, 255, 255 * hp * sliceAlpha)
                    DrawSlice(centerX, centerY, animRadius, innerRadius, startAngle + padAngle, endAngle - padAngle, hoverColor, 18, hoverBorder)
                end
                
                local midAngle = (startAngle + endAngle) / 2
                local textRadius = innerRadius + (animOuterRadius - innerRadius) / 2
                local tx = centerX + math.cos(midAngle) * textRadius
                local ty = centerY + math.sin(midAngle) * textRadius
                
                surface.SetFont("Virtus_AnimFont")
                local text = anim.name
                local tw, th = surface.GetTextSize(text)
                
                local tc = Lerp(hp, 180, 255)
                local textAlpha = tc * sliceAlpha
                
                surface.SetTextColor(tc, tc, tc, textAlpha)
                surface.SetTextPos(tx - tw / 2, ty - th / 2)
                surface.DrawText(text)
            end
            
            local isCancelHovered = (dist <= 50)
            self.CenterHover = Lerp(FrameTime() * 12, self.CenterHover, isCancelHovered and 1 or 0)
            
            -- Center UI Hub
            surface.SetDrawColor(0, 0, 0, 150 * (self.AlphaAnim/255))
            draw.NoTexture()
            
            -- Draw inner circle
            local circlePoly = {}
            for i=0, 32 do
                local a = math.rad( (i/32) * -360 )
                table.insert(circlePoly, {x = centerX + math.cos(a) * (innerRadius - 10), y = centerY + math.sin(a) * (innerRadius - 10)})
            end
            surface.DrawPoly(circlePoly)
            
            -- Center text logic
            local centerTitle = "ANIMACIONES"
            local centerSub = isCancelHovered and "CANCELAR" or "Selecciona una..."
            local titleColor = Color(255, 255, 255, self.AlphaAnim)
            local subColor = Color(180, 180, 180, self.AlphaAnim)
            
            if self.HoveredIndex then
                local anim = self.VisibleAnims[self.HoveredIndex]
                centerTitle = string.upper(anim.name)
                if self.TotalPages > 1 then
                    centerSub = "Equipar (Q/E: Pág " .. self.CurrentPage .. "/" .. self.TotalPages .. ")"
                else
                    centerSub = "Equipar"
                end
                subColor = Color(100, 255, 100, self.AlphaAnim)
            elseif isCancelHovered then
                subColor = Color(255, Lerp(self.CenterHover, 255, 100), Lerp(self.CenterHover, 255, 100), self.AlphaAnim)
                centerTitle = "CERRAR"
                centerSub = ""
            else
                if self.TotalPages > 1 then
                    centerSub = "Q/E: Paginar (" .. self.CurrentPage .. "/" .. self.TotalPages .. ")"
                end
            end
            
            surface.SetFont("Virtus_AnimFont_Title")
            local tW, tH = surface.GetTextSize(centerTitle)
            surface.SetTextColor(titleColor.r, titleColor.g, titleColor.b, titleColor.a)
            surface.SetTextPos(centerX - tW/2, centerY - (centerSub == "" and tH/2 or 10))
            surface.DrawText(centerTitle)
            
            if centerSub ~= "" then
                surface.SetFont("Virtus_AnimFont")
                local sW, sH = surface.GetTextSize(centerSub)
                surface.SetTextColor(subColor.r, subColor.g, subColor.b, subColor.a)
                surface.SetTextPos(centerX - sW/2, centerY + 10)
                surface.DrawText(centerSub)
            end
        end
        
        radialPanel.Think = function(self)
            if self.TotalPages > 1 then
                local leftDown = input.IsKeyDown(KEY_E)
                local rightDown = input.IsKeyDown(KEY_Q)
                
                if leftDown and not self.WasLeftDown then
                    self.CurrentPage = self.CurrentPage + 1
                    if self.CurrentPage > self.TotalPages then self.CurrentPage = 1 end
                    self:BuildPage()
                    surface.PlaySound("UI/buttonrollover.wav")
                end
                
                if rightDown and not self.WasRightDown then
                    self.CurrentPage = self.CurrentPage - 1
                    if self.CurrentPage < 1 then self.CurrentPage = self.TotalPages end
                    self:BuildPage()
                    surface.PlaySound("UI/buttonrollover.wav")
                end
                
                self.WasLeftDown = leftDown
                self.WasRightDown = rightDown
            end

            if not IsAnimKeyDown() and not self.Closing then
                self.Closing = true
                if self.HoveredIndex and self.VisibleAnims[self.HoveredIndex] then
                    local anim = self.VisibleAnims[self.HoveredIndex]
                    if anim.type == "engine_act" then
                        net.Start("EGM_Animation_ForceAct")
                        net.WriteInt(anim.act, 32)
                        net.SendToServer()
                    else
                        net.Start("EGM_Animation_Toggle")
                        net.WriteString(anim.id)
                        net.WriteInt(anim.deactivateOnMove or 5, 16)
                        net.SendToServer()
                    end
                else
                    net.Start("EGM_Animation_Toggle")
                    net.WriteString("")
                    net.SendToServer()
                end
            end
        end
    end

    hook.Add("PlayerBindPress", "EGM_RadialMenu_Binds", function(ply, bind, pressed)
        if IsValid(radialPanel) and not radialPanel.Closing then
            if bind:find("menu") or bind:find("use") then
                return true
            end
        end
    end)

    hook.Add("Think", "EGM_RadialMenu_Check", function()
        local isDown = IsAnimKeyDown()
        if isDown and not wasMiddleDown then
            if not IsValid(radialPanel) then
                OpenRadial()
            end
        end
        wasMiddleDown = isDown
    end)
else
	local function VelocityIsHigher(ply, value)
		local x, y, z = math.abs(ply:GetVelocity().x), math.abs(ply:GetVelocity().y), math.abs(ply:GetVelocity().z)
		if x > value or y > value or z > value then
			return true
		else
			return false
		end
	end

    local emptyWeapons = {
        "unarmed",
        "keys",
        "weapon_fists",
        "gmod_camera"
    }

    hook.Add("SetupMove", "AnimationSWEP.SetupMove", function(ply, moveData, cmd)
        if ply:GetNWBool("animationStatus") then
        	local deactivateOnMove = ply:GetNWInt("deactivateOnMove", 5)
        	
	            if VelocityIsHigher(ply, deactivateOnMove) then
	                AnimationSWEP:Toggle(ply, false)
	            end

	            if ply:KeyDown(IN_DUCK) then
	                AnimationSWEP:Toggle(ply, false)
	            end

	            if ply:KeyDown(IN_USE) then
	                AnimationSWEP:Toggle(ply, false)
	            end

	            if ply:KeyDown(IN_JUMP) then
	                AnimationSWEP:Toggle(ply, false)
	            end
                
                if ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_ATTACK2) then
                    AnimationSWEP:Toggle(ply, false)
                end
        end
    end)
    
    hook.Add("PlayerSwitchWeapon", "AnimationSWEP.SwitchWeapon", function(ply, oldWep, newWep)
        if ply:GetNWBool("animationStatus") then
            -- No cancelar si el addon mismo está cambiando el arma
            if ply.IvoAnim_SwitchingWeapon then return end
            -- Solo cancela si el jugador cambia a un arma que no es de manos vacías
            if newWep and not table.HasValue(emptyWeapons, newWep:GetClass()) then
                AnimationSWEP:Toggle(ply, false)
            end
        end
    end)

    function AnimationSWEP:Toggle(ply, crossing, class, deactivateOnMove)
        if not IsValid(ply) then return end
        if crossing then
            ply:SetNWBool("animationStatus", true)
            
            if class then
                ply:SetNWString("animationClass", class)
            end
            
            ply:SetNWInt("deactivateOnMove", deactivateOnMove)
            
            local activeWep = ply:GetActiveWeapon()
            if IsValid(activeWep) and not table.HasValue(emptyWeapons, activeWep:GetClass()) then
                ply.IvoAnim_PrevWeapon = activeWep:GetClass()
                
                ply.IvoAnim_SwitchingWeapon = true
                for _, emptyClass in ipairs(emptyWeapons) do
                    if ply:HasWeapon(emptyClass) then
                        ply:SelectWeapon(emptyClass)
                        break
                    end
                end
                timer.Simple(0.5, function()
                    if IsValid(ply) then
                        ply.IvoAnim_SwitchingWeapon = false
                    end
                end)
            end
        else
            ply:SetNWBool("animationStatus", false)
            ply:SetNWInt("deactivateOnMove", 5)
            
            ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
            ply:AnimResetGestureSlot(GESTURE_SLOT_TAUNT)
            
            -- Limpiar tracking de secuencias para que la próxima vez arranque de cero
            ply.EGM_SeqActive = nil
            ply.EGM_SeqClass = nil
            ply.EGM_SeqStartTime = nil
            ply.IvoAnim_SwitchingWeapon = false

            if ply.IvoAnim_PrevWeapon and ply:HasWeapon(ply.IvoAnim_PrevWeapon) then
                ply:SelectWeapon(ply.IvoAnim_PrevWeapon)
                ply.IvoAnim_PrevWeapon = nil
            end
        end
    end
end

local SequenceMap = {}
for _, anim in ipairs(AnimationsList) do
    if anim.type == "sequence" then
        SequenceMap[anim.id] = anim.sequence
    end
end

hook.Add("CalcMainActivity", "EGM_Sequence_Override", function(ply, velocity)
    if ply:GetNWBool("animationStatus") then
        local class = ply:GetNWString("animationClass")
        local seqName = SequenceMap[class]
        if seqName then
            local seqId = ply:LookupSequence(seqName)
            if seqId and seqId > 0 then
                if not ply.EGM_SeqActive or ply.EGM_SeqClass ~= class then
                    ply.EGM_SeqClass = class
                    ply.EGM_SeqActive = true
                    ply.EGM_SeqStartTime = CurTime()
                end
                
                -- Esperar al menos 1 segundo antes de revisar el ciclo,
                -- porque GetCycle() puede tener el valor del ciclo anterior
                local elapsed = CurTime() - (ply.EGM_SeqStartTime or CurTime())
                if elapsed > 1 then
                    local cycle = ply:GetCycle()
                    if cycle >= 0.95 then
                        if SERVER then
                            AnimationSWEP:Toggle(ply, false)
                        end
                        ply.EGM_SeqActive = nil
                        ply.EGM_SeqClass = nil
                        ply.EGM_SeqStartTime = nil
                        return
                    end
                end
                
                return -1, seqId
            end
        end
    else
        ply.EGM_SeqActive = nil
        ply.EGM_SeqClass = nil
        ply.EGM_SeqStartTime = nil
    end
end)

hook.Add("UpdateAnimation", "EGM_Sequence_Update", function(ply, velocity, maxSeqGroundSpeed)
    if ply:GetNWBool("animationStatus") then
        local class = ply:GetNWString("animationClass")
        if SequenceMap[class] then
            ply:SetPlaybackRate(1)
            return true
        end
    end
end)