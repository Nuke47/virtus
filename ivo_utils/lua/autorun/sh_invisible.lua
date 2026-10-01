-- sh_su_invisibility_vidrio_plano.lua

local function IsShadowUnit(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    local SU_TEAMS = {
        [TEAM_SU_AGT or -1] = true,
        [TEAM_SU_ARF or -1] = true,
        [TEAM_SU_ENG or -1] = true,
        [TEAM_SU_FRN or -1] = true,
        [TEAM_SU_ARC or -1] = true,
        [TEAM_SU_CMD or -1] = true,
        [TEAM_SU_MED or -1]  = true,
	[TEAM_SU_HEAVY or -1]  = true,
	[TEAM_SU_SPEC or -1]  = true,
    }

    return SU_TEAMS[ply:Team()] or false
end

local TRANSITION_TIME = 1.8 

-- CONFIGURACIÃ“N DE INTENSIDAD (Solo admin puede cambiar en consola)
local c_alpha = CreateConVar("sv_su_invis_alpha", "0.3", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Opacidad del camuflaje fantasma. 0 a 1.")

--- ====================================================================
--- SERVIDOR
--- ====================================================================
if SERVER then
    util.AddNetworkString("SU_ToggleInvisibilityPlano")

    -- Detectar la tecla X especÃ­ficamente para el chat de voz local
    hook.Add("PlayerButtonDown", "SU_Invis_VoiceKey", function(ply, button)
        if button == KEY_X then ply:SetNWBool("SU_HoldingX", true) end
    end)
    hook.Add("PlayerButtonUp", "SU_Invis_VoiceKeyUp", function(ply, button)
        if button == KEY_X then ply:SetNWBool("SU_HoldingX", false) end
    end)

    -- Consumo de energÃ­a y regeneraciÃ³n del Camuflaje
    hook.Add("Think", "SU_Invis_Energy", function()
        for _, ply in ipairs(player.GetAll()) do
            if IsShadowUnit(ply) then
                local isInv = ply:GetNWBool("SU_Invisible", false)
                local energy = ply:GetNWFloat("SU_InvisEnergy", 100)
                
                local speaking = ply:IsSpeaking() and ply:GetNWBool("SU_HoldingX", false)
                local recentlyDamaged = CurTime() < ply:GetNWFloat("SU_LastDamageTime", 0) + 1.5

                if isInv then
                    energy = math.max(0, energy - (100 / 30) * FrameTime()) -- 30s de duraciÃ³n
                    if energy == 0 then
                        ply:SetNWBool("SU_Invisible", false)
                        ply:DrawShadow(true)
                        isInv = false
                    end
                else
                    energy = math.min(100, energy + (100 / 20) * FrameTime()) -- 20s de recarga
                end
                
                if energy ~= ply:GetNWFloat("SU_InvisEnergy", 100) then
                    ply:SetNWFloat("SU_InvisEnergy", energy)
                end

                -- Control de NoTarget: NPCs lo ignoran si estÃ¡ invisible, no habla y no recibiÃ³ daÃ±o reciente
                local shouldNoTarget = isInv and not (speaking or recentlyDamaged)
                if ply.SU_LastNoTarget ~= shouldNoTarget then
                    ply:SetNoTarget(shouldNoTarget)
                    ply.SU_LastNoTarget = shouldNoTarget
                end
            end
        end
    end)

    -- Detector de DaÃ±o para el Glitch
    hook.Add("EntityTakeDamage", "SU_Invis_Damage", function(target, dmginfo)
        if target:IsPlayer() and IsShadowUnit(target) and target:GetNWBool("SU_Invisible", false) then
            target:SetNWFloat("SU_LastDamageTime", CurTime())
        end
    end)

    net.Receive("SU_ToggleInvisibilityPlano", function(len, ply)
        if not IsValid(ply) or not ply:Alive() or not IsShadowUnit(ply) then return end

        ply.SU_InvisCooldown = ply.SU_InvisCooldown or 0
        if CurTime() < ply.SU_InvisCooldown then return end
        ply.SU_InvisCooldown = CurTime() + (TRANSITION_TIME + 0.2)

        local isInv = ply:GetNWBool("SU_Invisible", false)
        local energy = ply:GetNWFloat("SU_InvisEnergy", 100)
        
        -- No permitir encender si tiene menos del 10% de energÃ­a
        if not isInv and energy < 10 then return end

        local newState = not isInv
        
        ply:SetNWBool("SU_Invisible", newState)
        ply:DrawShadow(not newState)
    end)

    hook.Add("PlayerDeath", "SU_Invis_ResetDeath", function(ply)
        if ply:GetNWBool("SU_Invisible", false) then
            ply:SetNWBool("SU_Invisible", false)
            ply:DrawShadow(true)
        end
        ply:SetNoTarget(false)
        ply.SU_LastNoTarget = false
    end)
    hook.Add("PlayerSpawn", "SU_Invis_ResetSpawn", function(ply)
        ply:SetNWBool("SU_Invisible", false)
        ply:DrawShadow(true)
        ply:SetNoTarget(false)
        ply.SU_LastNoTarget = false
    end)
end

--- ====================================================================
--- CLIENTE
--- ====================================================================
if CLIENT then
    local matDistortion = nil
    local function GetOverlayMaterial()
        if not matDistortion then
            matDistortion = CreateMaterial("SU_OpticalCamo_CleanGhost_v2", "VertexLitGeneric", {
                ["$basetexture"] = "color/white",
                ["$color2"]      = "[0.2 0.2 0.2]",    
                ["$additive"]    = "1",                
                ["$envmap"]      = "env_cubemap",      
                ["$envmaptint"]  = "[0.02 0.02 0.02]", 
                ["$translucent"] = "1",
                ["$model"]       = "1"
            })
        end
        return matDistortion
    end

    -- FUNCIÃ“N MAESTRA DE RENDERIZADO (Evita el bug del arma chiquita)
    -- Retorna true si el modelo debe ocultarse por completo (para optimizar)
    local function SetupRenderState(ent, camo, alphaMult)
        alphaMult = alphaMult or 1
        if camo == 1 then return false end
        
        -- Si tenemos el visor infrarrojo puesto, ANULAMOS el camuflaje para los demÃ¡s.
        -- AsÃ­ veremos a nuestros compaÃ±eros invisibles resaltados por la firma tÃ©rmica.
        if _G.SU_IR_Active and IsValid(ent) and ent ~= LocalPlayer() then
            return false
        end

        if camo > 0.5 then
            -- Fase 1: Desvanecer el arma/jugador con sus texturas originales (1.0 -> 0.0)
            local alpha = (camo - 0.5) * 2
            render.SetBlend(alpha)
            return false
        else
            -- Fase 2: Aplicar material de cristal y regular transparencia (0.0 -> Admin Alpha)
            local targetAlpha = c_alpha:GetFloat() * alphaMult
            local ghostProg = 1 - (camo * 2) 
            local alpha = ghostProg * targetAlpha
            
            if alpha <= 0 then return true end -- Ocultar totalmente (Ahorra FPS)
            
            render.MaterialOverride(GetOverlayMaterial())
            render.SetBlend(alpha)
            return false
        end
    end

    local function ResetRenderState()
        render.MaterialOverride(nil)
        render.SetBlend(1)
    end

    hook.Add("PlayerButtonDown", "SU_Invis_KeyPress", function(ply, button)
        if (button == (GetConVar("virtus_bind_invis") and GetConVar("virtus_bind_invis"):GetInt() or KEY_M)) and IsFirstTimePredicted() and ply == LocalPlayer() and IsShadowUnit(ply) then
            net.Start("SU_ToggleInvisibilityPlano")
            net.SendToServer()
        end
    end)

    -- CÃLCULO PROGRESIVO Y ARMAS EN 3RA PERSONA
    hook.Add("Think", "SU_Invis_Update", function()
        for _, ply in ipairs(player.GetAll()) do
            local isInv = ply:GetNWBool("SU_Invisible", false)
            local speaking = ply:IsSpeaking() and ply:GetNWBool("SU_HoldingX", false)
            local recentlyDamaged = CurTime() < ply:GetNWFloat("SU_LastDamageTime", 0) + 1.5
            
            local target = 1 
            if isInv then
                if speaking then
                    target = 0.85 -- Se revela casi por completo al hablar
                else
                    target = 0
                end
            end
            
            ply.SU_CamoAmount = ply.SU_CamoAmount or target
            
            if isInv and recentlyDamaged then
                -- DistorsiÃ³n errÃ¡tica (Glitch) al recibir daÃ±o
                ply.SU_CamoAmount = math.Clamp(0.3 + math.sin(CurTime() * 40) * 0.4 + math.Rand(-0.1, 0.1), 0, 1)
            elseif ply.SU_CamoAmount ~= target then
                -- TransiciÃ³n rÃ¡pida si estÃ¡ hablando, lenta si se camufla normalmente
                local speed = (isInv and speaking) and (FrameTime() * 8) or (FrameTime() / TRANSITION_TIME)
                ply.SU_CamoAmount = math.Approach(ply.SU_CamoAmount, target, speed)
            end
            
            local camo = ply.SU_CamoAmount
            -- Forzamos RenderMode para que render.SetBlend() funcione en el jugador
            if camo < 1 then
                if ply:GetRenderMode() ~= RENDERMODE_TRANSALPHA then ply:SetRenderMode(RENDERMODE_TRANSALPHA) end
            else
                if ply:GetRenderMode() ~= RENDERMODE_NORMAL then ply:SetRenderMode(RENDERMODE_NORMAL) end
            end

            -- Optimizamos evitando ply:GetWeapons() para no generar fugas de memoria por creaciÃ³n masiva de tablas
            local activeWep = ply:GetActiveWeapon()
            
            if ply.SU_LastActiveWeapon ~= activeWep then
                local oldWep = ply.SU_LastActiveWeapon
                if IsValid(oldWep) then
                    if oldWep:GetRenderMode() ~= RENDERMODE_NORMAL then oldWep:SetRenderMode(RENDERMODE_NORMAL) end
                    if oldWep.SU_HasCamoMaterial then
                        oldWep:SetColor(Color(255, 255, 255, 255))
                        oldWep:SetMaterial(oldWep.SU_OriginalMaterial or "")
                        oldWep.SU_OriginalMaterial = nil
                        oldWep.SU_HasCamoMaterial = false
                    end
                    if oldWep.SU_HasCamoDraw then
                        oldWep.DrawWorldModel = oldWep.SU_OldDrawWorldModel
                        oldWep.SU_OldDrawWorldModel = nil
                        oldWep.SU_CamoDrawWorldModel = nil
                        oldWep.RenderOverride = oldWep.SU_OldRenderOverride
                        oldWep.SU_OldRenderOverride = nil
                        oldWep.SU_CamoRenderOverride = nil
                        oldWep.SU_HasCamoDraw = false
                    end
                end
                ply.SU_LastActiveWeapon = activeWep
            end

            if IsValid(activeWep) then
                local wep = activeWep
                    if camo < 1 then
                        if wep:GetRenderMode() ~= RENDERMODE_TRANSALPHA then wep:SetRenderMode(RENDERMODE_TRANSALPHA) end
                        
                        -- FUSIÃ“N 1: Propiedades Nativas (Atrapa armas C++ de Half-Life 2 y SWEPs simples)
                        if not wep.SU_HasCamoMaterial then
                            wep.SU_OriginalMaterial = wep:GetMaterial()
                            wep.SU_HasCamoMaterial = true
                        end
                        
                        if camo > 0.5 then
                            local alpha = math.floor((camo - 0.5) * 510)
                            wep:SetColor(Color(255, 255, 255, alpha))
                            wep:SetMaterial(wep.SU_OriginalMaterial or "")
                        else
                            local targetAlpha = c_alpha:GetFloat() * 0.95 -- Multiplicador: 65% mÃ¡s transparente que el jugador
                            local ghostProg = 1 - (camo * 2) 
                            local alpha = math.floor(ghostProg * targetAlpha * 255)
                            wep:SetColor(Color(255, 255, 255, alpha))
                            wep:SetMaterial("!" .. GetOverlayMaterial():GetName())
                        end

                        -- FUSIÃ“N 2: IntercepciÃ³n de Hooks (Atrapa accesorios y miras de bases como TFA o ArcCW)
                        if not wep.SU_HasCamoDraw then
                            wep.SU_OldDrawWorldModel = wep.DrawWorldModel
                            wep.SU_CamoDrawWorldModel = function(self, flags)
                                local owner = self:GetOwner()
                                local currentCamo = IsValid(owner) and owner.SU_CamoAmount or 1
                                
                                if currentCamo == 1 then
                                    if self.SU_OldDrawWorldModel then self:SU_OldDrawWorldModel(flags) else self:DrawModel(flags) end
                                    return
                                end
                                
                                local hide = SetupRenderState(owner or self, currentCamo, 0.05)
                                if not hide then
                                    self.DrawWorldModel = self.SU_OldDrawWorldModel
                                    if self.DrawWorldModel then self:DrawWorldModel(flags) else self:DrawModel(flags) end
                                    self.DrawWorldModel = self.SU_CamoDrawWorldModel
                                end
                                ResetRenderState()
                            end
                            wep.DrawWorldModel = wep.SU_CamoDrawWorldModel

                            wep.SU_OldRenderOverride = wep.RenderOverride
                            wep.SU_CamoRenderOverride = function(self)
                                local owner = self:GetOwner()
                                local currentCamo = IsValid(owner) and owner.SU_CamoAmount or 1
                                
                                if currentCamo == 1 then
                                    if self.SU_OldRenderOverride then self:SU_OldRenderOverride() else self:DrawModel() end
                                    return
                                end
                                
                                local hide = SetupRenderState(owner or self, currentCamo, 0.35)
                                if not hide then
                                    self.RenderOverride = self.SU_OldRenderOverride
                                    if self.RenderOverride then self:RenderOverride() else self:DrawModel() end
                                    self.RenderOverride = self.SU_CamoRenderOverride
                                end
                                ResetRenderState()
                            end
                            wep.RenderOverride = wep.SU_CamoRenderOverride

                            wep.SU_HasCamoDraw = true
                        end
                    else
                        if wep:GetRenderMode() ~= RENDERMODE_NORMAL then wep:SetRenderMode(RENDERMODE_NORMAL) end
                        
                        if wep.SU_HasCamoMaterial then
                            wep:SetColor(Color(255, 255, 255, 255))
                            wep:SetMaterial(wep.SU_OriginalMaterial or "")
                            wep.SU_OriginalMaterial = nil
                            wep.SU_HasCamoMaterial = false
                        end

                        if wep.SU_HasCamoDraw then
                            wep.DrawWorldModel = wep.SU_OldDrawWorldModel
                            wep.SU_OldDrawWorldModel = nil
                            wep.SU_CamoDrawWorldModel = nil
                            wep.RenderOverride = wep.SU_OldRenderOverride
                            wep.SU_OldRenderOverride = nil
                            wep.SU_CamoRenderOverride = nil
                            wep.SU_HasCamoDraw = false
                        end
                    end
            end
        end
    end)

    -- 3RA PERSONA (Jugador)
    hook.Add("PrePlayerDraw", "SU_Invis_PreDraw", function(ply)
        local camo = ply.SU_CamoAmount or 1
        if camo == 1 then return end
        if SetupRenderState(ply, camo) then return true end
    end)

    hook.Add("PostPlayerDraw", "SU_Invis_PostDraw", function(ply)
        ResetRenderState()
    end)

    -- 1RA PERSONA (Vista Local de Armas)
    hook.Add("PreDrawViewModel", "SU_Invis_VMPre", function(vm, ply, wep)
        if _G.SU_IR_Active then return end -- Si el visor estÃ¡ encendido, el arma NO debe ser translÃºcida
        if not IsValid(ply) then return end
        local camo = ply.SU_CamoAmount or 1
        if camo == 1 then return end
        
        if SetupRenderState(ply, camo, 0.85) then return true end -- Armas locales mÃ¡s transparentes
    end)
    hook.Add("PostDrawViewModel", "SU_Invis_VMPost", function(vm, ply, wep)
        ResetRenderState()
    end)
    
    -- 1RA PERSONA (Vista Local de Brazos/Guantes)
    hook.Add("PreDrawPlayerHands", "SU_Invis_HandsPre", function(hands, vm, ply, wep)
        if _G.SU_IR_Active then return end -- Si el visor estÃ¡ encendido, las manos NO deben ser translÃºcidas
        if not IsValid(ply) then return end
        local camo = ply.SU_CamoAmount or 1
        if camo == 1 then return end
        
        if SetupRenderState(ply, camo, 0.35) then return true end -- Manos mÃ¡s transparentes
    end)
    hook.Add("PostDrawPlayerHands", "SU_Invis_HandsPost", function(hands, vm, ply, wep)
        ResetRenderState()
    end)

    -- ==========================================
    -- HUD ESTÃNDAR DEL CAMUFLAJE
    -- ==========================================
    hook.Add("HUDPaint", "SU_Invis_StandardHUD", function()
        -- Si estamos con el Visor IR, ocultamos este HUD para usar el Integrado
        if _G.SU_IR_Active and not LocalPlayer():ShouldDrawLocalPlayer() then return end

        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() or not IsShadowUnit(ply) then return end

        local energy = ply:GetNWFloat("SU_InvisEnergy", 100)
        local isInv = ply:GetNWBool("SU_Invisible", false)
        
        if energy >= 99 and not isInv then return end

        local hudW, hudH = 260, 25
        local x = (ScrW() / 2) - (hudW / 2)
        local y = ScrH() - 130 -- Posicionado justo arriba del jetpack

        surface.SetDrawColor(10, 15, 20, 200)
        surface.DrawRect(x, y, hudW, hudH)
        
        surface.SetDrawColor(100, 150, 200, 100)
        surface.DrawOutlinedRect(x, y, hudW, hudH, 1)

        local text = isInv and "CAMUFLAJE ACTIVO" or "RECARGANDO CAMUFLAJE"
        local col = isInv and Color(150, 200, 255) or Color(200, 100, 100)
        
        draw.SimpleText(text, "TargetID", x + hudW/2, y - 12, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local barX, barY, barW, barH = x + 5, y + 5, hudW - 10, hudH - 10
        surface.SetDrawColor(30, 40, 50, 255)
        surface.DrawRect(barX, barY, barW, barH)

        if energy > 0 then
            surface.SetDrawColor(col)
            surface.DrawRect(barX, barY, barW * (energy / 100), barH)
        end
    end)
end
