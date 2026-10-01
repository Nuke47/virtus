-- Archivo: lua/autorun/sh_jetpack.lua

-- ==========================================
-- CONFIGURACIÓN DEL JETPACK
-- ==========================================
local cfg = {
    Thrust = 1500,          -- Fuerza de empuje vertical del jetpack
    ForwardThrust = 1200,   -- Fuerza de empuje direccional (hacia adelante/lados)
    MaxSpeedZ = 350,        -- Límite de velocidad ascendente
    MaxSpeedXY = 600,       -- Límite de velocidad horizontal máxima
    Sound = "weapons/flaregun/burn.wav", -- Sonido nativo de GMod que simula propulsión
    MaxFuel = 100,          -- Cantidad máxima de combustible
    FuelDrain = 10,         -- Cantidad de combustible que se gasta por segundo al volar
    FuelRegen = 25,         -- Cantidad de combustible que se recupera por segundo al tocar el suelo

    -- Configuración exclusiva Mochila de Salto (Cody)
    JumpPackCost = 100,     -- Coste por salto (100 = vacía toda la barra)
    JumpPackForceZ = 1200,  -- Impulso vertical masivo (Aumentado para saltar más alto)
    JumpPackForceXY = 350,  -- Impulso horizontal (Reducido para no ir tan hacia adelante)
    JumpSound = "weapons/stunstick/alyx_stunner1.wav" -- Sonido de explosión al saltar
}

-- Exportamos la configuración para que el visor de los binoculares pueda leerla
_G.IVO_JetpackCfg = cfg

-- ==========================================
-- LÓGICA DE VALIDACIÓN (BODYGROUP)
-- ==========================================
local function HasJetpack(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    -- Si el administrador activó el modo admin con SAM, desactivamos ambos jetpacks
    if ply:GetNWBool("Jetpack_AdminDisabled", false) then return false end

    -- Recorremos todos los bodygroups del modelo
    for _, bg in pairs(ply:GetBodyGroups() or {}) do
        local currentVal = ply:GetBodygroup(bg.id)
        
        -- Solo verificamos si hay algo equipado en este bodygroup (valor > 0)
        if currentVal > 0 then
            local bgName = string.lower(bg.name)
            local submodelName = ""
            
            if bg.submodels and bg.submodels[currentVal] then
                submodelName = string.lower(bg.submodels[currentVal])
            end

            -- Comprobamos si el nombre de la categoría o del submodelo contiene "jetpack"
            if string.find(bgName, "jetpack") or string.find(bgName, "jepack") or string.find(submodelName, "jetpack") or string.find(submodelName, "jepack") then
                
                -- Identificamos si es Cody (por el nombre del bodygroup, submodelo, o el propio modelo del jugador)
                if string.find(bgName, "cody") or string.find(submodelName, "cody") or string.find(string.lower(ply:GetModel() or ""), "cody") then
                    return "cody"
                end
                
                return "standard"
            end
        end
    end

    return false
end

-- Exportamos la función de validación
_G.IVO_HasJetpack = HasJetpack

-- ==========================================
-- SISTEMA DE SONIDO (CLIENTE)
-- ==========================================
local function HandleJetpackSound(ply, isFlying)
    if SERVER then return end 

    if isFlying then
        if not ply.JetpackSound then
            ply.JetpackSound = CreateSound(ply, cfg.Sound)
            ply.JetpackSound:PlayEx(0.4, 100)
        elseif not ply.JetpackSound:IsPlaying() then
            ply.JetpackSound:PlayEx(0.4, 100)
        end
    else
        if ply.JetpackSound and ply.JetpackSound:IsPlaying() then
            ply.JetpackSound:Stop()
        end
    end
end

-- ==========================================
-- LÓGICA DE MOVIMIENTO
-- ==========================================
hook.Add("SetupMove", "Bodygroup_Jetpack_Movement", function(ply, mv, cmd)
    local jetpackType = HasJetpack(ply)
    if not IsValid(ply) or not ply:Alive() or not jetpackType then
        if IsFirstTimePredicted() then HandleJetpackSound(ply, false) end
        return
    end

    -- Inicializamos la variable de combustible en el jugador si no existe
    ply.JetpackFuel = ply.JetpackFuel or cfg.MaxFuel
    local isFlying = false
    local isJumping = mv:KeyDown(IN_JUMP)

    if jetpackType == "cody" then
        -- ==========================================
        -- LÓGICA MOCHILA DE SALTO (CODY)
        -- ==========================================
        ply.NextCodyJump = ply.NextCodyJump or 0
        
        -- Requiere doble salto: estar en el aire, volver a presionar espacio y tener energía
        if isJumping and not ply.LastJumpKey and not ply:IsOnGround() and ply.JetpackFuel >= cfg.JumpPackCost and CurTime() > ply.NextCodyJump then
            local vel = mv:GetVelocity()
            
            -- Impulso vertical masivo
            vel.z = cfg.JumpPackForceZ
            
            -- Impulso horizontal (Dash)
            local fwdSpeed = mv:GetForwardSpeed()
            local sideSpeed = mv:GetSideSpeed()
            
            if fwdSpeed ~= 0 or sideSpeed ~= 0 then
                local ang = mv:GetMoveAngles()
                local forward, right = ang:Forward(), ang:Right()
                forward.z, right.z = 0, 0
                forward:Normalize() right:Normalize()
                
                local dir = (forward * fwdSpeed) + (right * sideSpeed)
                dir:Normalize()
                
                vel.x = vel.x + (dir.x * cfg.JumpPackForceXY)
                vel.y = vel.y + (dir.y * cfg.JumpPackForceXY)
            end
            
            mv:SetVelocity(vel)
            
            if IsFirstTimePredicted() then
                ply.JetpackFuel = ply.JetpackFuel - cfg.JumpPackCost
                ply.NextCodyJump = CurTime() + 1 -- Cooldown
            end
            
            if SERVER then
                ply:SetNWFloat("CodyJumpTime", CurTime() + 0.8)
            end
            
            if IsFirstTimePredicted() then
                ply:EmitSound(cfg.JumpSound, 80, math.random(90, 110), 1)
            end
        end
        
        if IsFirstTimePredicted() then
            ply.LastJumpKey = isJumping
        end
        
        if ply:GetNWFloat("CodyJumpTime", 0) > CurTime() then
            isFlying = true
        end
        
    else
        -- ==========================================
        -- LÓGICA JETPACK CONTINUO (ESTÁNDAR)
        -- ==========================================
        if isJumping and not ply:IsOnGround() and ply.JetpackFuel > 0 then
            local vel = mv:GetVelocity()

            if vel.z < cfg.MaxSpeedZ then
                vel.z = vel.z + (cfg.Thrust * FrameTime())
            end
            
            local fwdSpeed = mv:GetForwardSpeed()
            local sideSpeed = mv:GetSideSpeed()
            
            if fwdSpeed ~= 0 or sideSpeed ~= 0 then
                local ang = mv:GetMoveAngles()
                local forward, right = ang:Forward(), ang:Right()
                forward.z, right.z = 0, 0
                forward:Normalize() right:Normalize()
                
                local dir = (forward * fwdSpeed) + (right * sideSpeed)
                dir:Normalize()
                
                vel.x = vel.x + (dir.x * cfg.ForwardThrust * FrameTime())
                vel.y = vel.y + (dir.y * cfg.ForwardThrust * FrameTime())
                
                local currentSpeedXY = math.sqrt(vel.x^2 + vel.y^2)
                if currentSpeedXY > cfg.MaxSpeedXY then
                    local ratio = cfg.MaxSpeedXY / currentSpeedXY
                    vel.x, vel.y = vel.x * ratio, vel.y * ratio
                end
            end

            mv:SetVelocity(vel)
            
            if IsFirstTimePredicted() then
                ply.JetpackFuel = math.max(0, ply.JetpackFuel - (cfg.FuelDrain * FrameTime()))
            end
            isFlying = true
        end
    end

    -- Si no está volando y está tocando el suelo, recargamos el jetpack
    if not isFlying and ply:IsOnGround() then
        if IsFirstTimePredicted() then
            ply.JetpackFuel = math.min(cfg.MaxFuel, ply.JetpackFuel + (cfg.FuelRegen * FrameTime()))
        end
    end

    -- Sincronizamos el estado de vuelo con todos los jugadores para las animaciones
    if SERVER then
        if ply:GetNWBool("JetpackFlying", false) ~= isFlying then
            ply:SetNWBool("JetpackFlying", isFlying)
        end
    end

    if IsFirstTimePredicted() then
        if jetpackType == "standard" then
            HandleJetpackSound(ply, isFlying)
        else
            HandleJetpackSound(ply, false)
        end
    end
end)

-- ==========================================
-- INTEGRACIÓN CON SAM ADMIN (COMANDOS)
-- ==========================================
if SERVER then
    -- Usamos un timer de 2 segundos al iniciar para asegurar que SAM ya haya cargado sus comandos
    timer.Simple(2, function()
        local cmds = concommand.GetTable()
        
        -- 1. Interceptar el comando 'sam_admin'
        local orig_sam_admin = cmds["sam_admin"]
        if orig_sam_admin then
            cmds["sam_admin"] = function(ply, cmd, args, str)
                if IsValid(ply) then ply:SetNWBool("Jetpack_AdminDisabled", true) end
                orig_sam_admin(ply, cmd, args, str)
            end
        end
        
        -- 2. Interceptar el comando 'sam_unadmin'
        local orig_sam_unadmin = cmds["sam_unadmin"]
        if orig_sam_unadmin then
            cmds["sam_unadmin"] = function(ply, cmd, args, str)
                if IsValid(ply) then ply:SetNWBool("Jetpack_AdminDisabled", false) end
                orig_sam_unadmin(ply, cmd, args, str)
            end
        end

        -- 3. Interceptar el comando base 'sam' (Ej: por si usan 'sam admin' con espacio)
        local orig_sam = cmds["sam"]
        if orig_sam then
            cmds["sam"] = function(ply, cmd, args, str)
                if IsValid(ply) and args and args[1] then
                    local action = string.lower(args[1])
                    if action == "admin" then
                        ply:SetNWBool("Jetpack_AdminDisabled", true)
                    elseif action == "unadmin" then
                        ply:SetNWBool("Jetpack_AdminDisabled", false)
                    end
                end
                orig_sam(ply, cmd, args, str)
            end
        end
    end)
    
    -- Failsafe Extra: Detectar si el administrador lo escribe por el chat de texto
    hook.Add("PlayerSay", "Jetpack_SAM_Chat_Admin", function(ply, text)
        local txt = string.lower(text)
        if txt == "!admin" or txt == "/admin" or txt == "!sam_admin" then
            ply:SetNWBool("Jetpack_AdminDisabled", true)
        elseif txt == "!unadmin" or txt == "/unadmin" or txt == "!sam_unadmin" then
            ply:SetNWBool("Jetpack_AdminDisabled", false)
        end
    end)
end

-- ==========================================
-- ANIMACIONES DEL JETPACK
-- ==========================================
hook.Add("CalcMainActivity", "Bodygroup_Jetpack_Animation", function(ply, velocity)
    if ply:GetNWBool("JetpackFlying", false) then
        local seq = -1
        local wep = ply:GetActiveWeapon()
        local holdType = IsValid(wep) and wep.GetHoldType and wep:GetHoldType() or "normal"

        -- Si está desarmado o con un arma pacífica, evitamos que mueva los brazos como nadando
        if holdType == "normal" or holdType == "" or holdType == "passive" then
            -- 'swim_passive' mantiene los brazos rígidos a los lados y conserva la inclinación
            local passiveSeq = ply:LookupSequence("swim_passive")
            if passiveSeq and passiveSeq > 0 then
                seq = passiveSeq
            end
        end

        -- Recuperamos ACT_MP_SWIM para que se incline dinámicamente hacia W, A, S, D
        return ACT_MP_SWIM, seq
    end
end)

-- ==========================================
-- CONTROL DE VELOCIDAD DE ANIMACIÓN
-- ==========================================
hook.Add("UpdateAnimation", "Bodygroup_Jetpack_AnimSpeed", function(ply, velocity, maxSeqGroundSpeed)
    -- Al ralentizar la animación al 1% evitamos que el personaje mueva los brazos (nade),
    -- pero mantenemos la inclinación aerodinámica direccional.
    if ply:GetNWBool("JetpackFlying", false) then
        ply:SetPlaybackRate(0.01)
        return true -- Anula el cálculo por defecto del motor
    end
end)

-- ==========================================
-- HUD DEL JETPACK (CLIENTE)
-- ==========================================
if CLIENT then
    -- ==========================================
    -- EFECTOS VISUALES (PARTÍCULAS)
    -- ==========================================
    local emitter = ParticleEmitter(Vector(0, 0, 0))

    hook.Add("Think", "Bodygroup_Jetpack_Particles", function()
        if not IsValid(LocalPlayer()) then return end
        -- Actualizamos el centro de renderizado del emisor para evitar bugs visuales
        emitter:SetPos(LocalPlayer():GetPos())

        for _, ply in ipairs(player.GetAll()) do
            if ply:GetNWBool("JetpackFlying", false) and ply:Alive() then
                -- Limitamos la creación a ~50 por segundo para no bajar los FPS
                ply.NextJetpackParticle = ply.NextJetpackParticle or 0
                if CurTime() > ply.NextJetpackParticle then
                    local tipoJetpack = HasJetpack(ply) or "standard"
                    ply.NextJetpackParticle = CurTime() + 0.02

                    -- Calculamos la espalda y dirección base (Fallback)
                    local basePos = ply:GetPos() + (ply:GetUp() * 45) - (ply:GetForward() * 20)
                    local rightOffset = ply:GetRight() * 8 -- Separación de propulsores
                    local thrustDir = -ply:GetUp() -- Dirección del fuego por defecto
                    local unSoloPropulsor = false

                    -- Intentamos buscar el hueso de la espalda para máxima precisión visual
                    local bone = ply:LookupBone("ValveBiped.Bip01_Spine2")
                    if bone then
                        local matrix = ply:GetBoneMatrix(bone)
                        if matrix then
                            -- ====================================================
                            -- CONFIGURACIÓN DE EJES (MÉTODO INFALIBLE)
                            -- ====================================================
                            local v1 = matrix:GetForward()
                            local v2 = matrix:GetRight()
                            local v3 = matrix:GetUp()
                            
                            local ejeLados, ejeVertical, ejeEspalda
                            local offsetAtras, offsetAbajo, separacion
                            
                            if tipoJetpack == "cody" then
                                -- ====================================================
                                -- CONFIGURACIÓN PARA: CODY JETPACK
                                -- ====================================================
                                -- Modifica estos hasta que encajen en el modelo de Cody
                                ejeLados    = v3  
                                ejeVertical = v1  
                                ejeEspalda  = v2  
                                
                                offsetAtras = 5   
                                offsetAbajo = -1   -- Disminuye este número (0, -2, etc.) para subir el fuego
                                separacion = 0
                                unSoloPropulsor = true
                            else
                                -- ====================================================
                                -- CONFIGURACIÓN PARA: JETPACK ESTÁNDAR
                                -- ====================================================
                                -- (Estos son los que ya ajustaste y funcionan bien)
                                ejeLados    = v3  
                                ejeVertical = v1  
                                ejeEspalda  = v2  
                                
                                offsetAtras = 5   
                                offsetAbajo = 4   
                                separacion = 6    
                            end
                            
                            -- 1. Lo mandamos a la mochila y lo bajamos
                            basePos = matrix:GetTranslation() + (ejeEspalda * offsetAtras) + (-ejeVertical * offsetAbajo)
                            
                            -- 2. Separamos los propulsores a los lados
                            rightOffset = ejeLados * separacion
                            
                            -- 3. Dirección hacia el suelo (si sale hacia el cielo, quítale el signo -)
                            thrustDir = -ejeVertical
                        end
                    end

                    -- Función para crear fuego y humo
                    local function EmitThruster(pos)
                        -- Fuego
                        local fire = emitter:Add("effects/fire_cloud1", pos)
                        if fire then
                            fire:SetVelocity(ply:GetVelocity() + (thrustDir * 110) + (VectorRand() * 10))
                            fire:SetDieTime(math.Rand(0.08, 0.15))
                            fire:SetStartAlpha(255)
                            fire:SetStartSize(math.Rand(1.5, 2.5)) -- Un poquito más angosto
                            fire:SetEndSize(math.Rand(0.1, 0.8))   -- Tamaño final ajustado
                            fire:SetRoll(math.Rand(0, 360))      -- Rotación aleatoria del sprite
                            fire:SetColor(255, 180, 50)
                        end

                        -- Humo
                        local smoke = emitter:Add("particles/smokey", pos)
                        if smoke then
                            smoke:SetVelocity(ply:GetVelocity() + (thrustDir * 90) + (VectorRand() * 15))
                            smoke:SetDieTime(math.Rand(0.1, 0.2))    -- Desaparece aún más rápido
                            smoke:SetStartAlpha(20)                  -- Humo casi invisible (neblina)
                            smoke:SetStartSize(math.Rand(0.5, 1))    -- Tamaño inicial minúsculo
                            smoke:SetEndSize(math.Rand(1.5, 3))      -- Tamaño final mucho más pequeño
                            smoke:SetRoll(math.Rand(0, 360))
                            smoke:SetColor(100, 100, 100)
                        end
                    end

                    -- Aplicamos el efecto dependiendo del tipo de jetpack
                    if unSoloPropulsor then
                        EmitThruster(basePos)
                    else
                        EmitThruster(basePos + rightOffset)
                        EmitThruster(basePos - rightOffset)
                    end
                end
            end
        end
    end)
end

-- ==========================================
-- COMANDO DE DEPURACIÓN PARA VER BODYGROUPS
-- ==========================================
concommand.Add("jetpack_debug_bodygroups", function(ply, cmd, args)
    if CLIENT then ply = LocalPlayer() end
    print("\n--- BODYGROUPS DE TU MODELO ACTUAL ---")
    for _, bg in pairs(ply:GetBodyGroups() or {}) do
        print("ID: " .. bg.id .. " | Nombre interno: '" .. bg.name .. "' | Valor equipado: " .. ply:GetBodygroup(bg.id))
    end
    print("--------------------------------------\n")
end)

-- ==========================================
-- EVITAR DAÑO POR CAÍDA (SOLO CODY)
-- ==========================================
hook.Add("GetFallDamage", "Bodygroup_Jetpack_NoFallDamage", function(ply, speed)
    if HasJetpack(ply) == "cody" then
        -- Tu lógica: si la mochila se gastó (está vacía), eres inmune al impacto.
        -- Usamos < 5 porque GMod recarga un poquito de energía justo en el milisegundo que tocas el suelo.
        if ply.JetpackFuel and ply.JetpackFuel < 5 then
            return 0 
        end
    end
end)