AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

--[[
    npc_droid_base
    -------------------------------------------------------------------------
    Config-driven CIS battle droid engine. Not spawnable on its own.
    B1 / B2 / BX inherit from this entity and only override ENT.DroidConfig.
    See specs/001-droid-difficulty/ for the spec, plan and tasks.
--]]

-- Defaults. Any field a variant does not set falls back to these values.
function ENT:GetDefaultConfig()
    return {
        -- Appearance / equipment
        Model        = "models/b1/pm_droid_cis_b1.mdl",
        Health       = 100,
        WeaponClass  = "tfa_sw_blaster_e5_upgrade",       -- TFA weapon to read stats from
        WeaponModel  = "models/kuro/sw_battlefront/weapons/e5_blaster.mdl",

        -- Perception (1655 ~= distance between the client's two reference points)
        DetectRadius = 1655,
        FireRange    = 1200,

        -- Accuracy. Spread is flat up to AccurateFraction of FireRange, then
        -- lerps toward MaxSpread at the edge. Lower spread = more accurate.
        BaseSpread       = 0.05,
        MaxSpread        = 0.18,
        AccurateFraction = 0.5,

        -- Combat tuning
        FireRateMult = 1.0,   -- multiplies the TFA delay (lower = faster)
        DamageMult   = 1.0,

        -- Movement
        WalkSpeed    = 80,    -- while firing
        RunSpeed     = 180,   -- repositioning
        RushSpeed    = 220,   -- squad rush

        -- Pathing (lower interval / higher look-ahead = smarter)
        RepathInterval = 0.3,
        LookAhead      = 300,
        GoalTolerance  = 20,

        -- Squad / coordination
        SquadRadius = 700,
        SquadMin    = 2,      -- this many allies nearby -> rush

        -- Targeting cadence
        RetargetInterval = 4,

        -- Reaction time to damage
        ReactionTime = 0.4,

        -- Movement modifiers
        WalkDistanceFrac = 1.2, -- if set, only walk when distance <= FireRange * this fraction
        KeepDistance     = nil, -- if set, force 'hold' (stop moving forward) if closer than this
        NeverHold        = false,
        ZigZagWidth      = nil,
        ZigZagInterval   = 1.0,
        
        -- Custom Model Overrides (for Droidekas etc)
        NoExternalWeapon   = false,
        WeaponOffsets      = nil, -- Array of Vectors for manual blaster positions
        CustomSequenceIdle = nil,
        CustomSequenceWalk = nil,
        CustomSequenceRun  = nil,
        CustomSequenceRush = nil,
        
        -- Custom Sounds
        SoundWeapon   = nil,
        SoundRoll     = nil,
        SoundDeploy   = nil,
        
        -- Escudos
        HasShield        = false,
        ShieldHealth     = 800,
        ShieldRecharge   = 10.0,
        
        -- Contagion / Swarm
        AlertRadius      = nil, -- if set, alerts nearby allies when shooting
        
        ExplodesOnDeath  = false,
        Scale            = 1.0,
    }
end

function ENT:SetupConfig()
    local cfg = self:GetDefaultConfig()
    if istable(self.DroidConfig) then
        table.Merge(cfg, self.DroidConfig)
    end
    self.Cfg = cfg
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:Initialize()
    self:SetupConfig()

    self:SetModel(self.Cfg.Model)
    
    if self.Cfg.Scale and self.Cfg.Scale ~= 1.0 then
        self:SetModelScale(self.Cfg.Scale, 0)
    end

    self:SetHealth(self.Cfg.Health)
    self:SetMaxHealth(self.Cfg.Health)

    self:SetCollisionGroup(COLLISION_GROUP_NPC)
    self:SetSolid(SOLID_BBOX)
    self:SetCustomCollisionCheck(true)
    
    -- Los droides son máquinas, no sangran
    self:SetBloodColor(DONT_BLEED)

    self.Enemy        = nil
    self.NextAttack   = 0
    self.NextRetarget = 0
    self.EngageStyle  = nil       -- "rush" | "rungun" | "hold"
    self.NextStyleEval = 0
    self.LastSeen     = 0

    if self.Cfg.HasShield then
        self.CurrentShield = self.Cfg.ShieldHealth
        self.NextShieldRecharge = 0
        self.ShieldActive = false
    end

    if self.Cfg.BoneManipulations then
        for boneName, angle in pairs(self.Cfg.BoneManipulations) do
            local boneID = self:LookupBone(boneName)
            if boneID then
                self:ManipulateBoneAngles(boneID, angle)
            end
        end
    end

    self:EquipWeapon()
end

ENT.VoiceLines = {
    b1 = {
        combat = { "npcs/voice/b1/acaben.wav", "npcs/voice/b1/casi.wav", "npcs/voice/b1/nopuedes.wav", "npcs/voice/b1/objetivofijado.wav", "npcs/voice/b1/rush.wav", "npcs/voice/b1/trampa.wav" },
        passive = { "npcs/voice/b1/circuitos.wav", "npcs/voice/b1/despliegue_b1.wav", "npcs/voice/b1/entendido.wav", "npcs/voice/b1/escuadron.wav", "npcs/voice/b1/ey.wav", "npcs/voice/b1/finalmente.wav", "npcs/voice/b1/merindo.wav", "npcs/voice/b1/ordencmd.wav", "npcs/voice/b1/poderoso.wav", "npcs/voice/b1/protocolos.wav", "npcs/voice/b1/risa.wav" }
    },
    b2 = {
        combat = { "npcs/voice/b2/activado.wav", "npcs/voice/b2/desplegando.wav", "npcs/voice/b2/escuadron.wav", "npcs/voice/b2/solucionado.wav" },
        passive = { "npcs/voice/b2/ajuste.wav", "npcs/voice/b2/ledi.wav", "npcs/voice/b2/predecesores.wav" }
    },
    bx = {
        combat = { "npcs/voice/bx/acaben.wav", "npcs/voice/bx/ataquenobj.wav", "npcs/voice/bx/defensa.wav", "npcs/voice/bx/dirijanse.wav", "npcs/voice/bx/distancia.wav", "npcs/voice/bx/enlamira.wav", "npcs/voice/bx/escuadron_1.wav", "npcs/voice/bx/escuadron_2.wav", "npcs/voice/bx/exterminen.wav", "npcs/voice/bx/fijado.wav", "npcs/voice/bx/fijando.wav", "npcs/voice/bx/rush.wav", "npcs/voice/bx/siganme.wav", "npcs/voice/bx/trampa.wav", "npcs/voice/bx/trampa_2.wav" },
        passive = { "npcs/voice/bx/activado.wav", "npcs/voice/bx/ajuste.wav", "npcs/voice/bx/bloqueadores.wav", "npcs/voice/bx/carga.wav", "npcs/voice/bx/circuitos.wav", "npcs/voice/bx/escaneando.wav", "npcs/voice/bx/interfiriendo.wav", "npcs/voice/bx/junto.wav", "npcs/voice/bx/problema.wav", "npcs/voice/bx/protejan.wav", "npcs/voice/bx/protocolos.wav", "npcs/voice/bx/rutinas.wav" }
    }
}
function ENT:PlayVoiceLine(isCombat)
    if not self.Cfg.VoiceType then return end
    if CurTime() < (self.NextVoiceTime or 0) then return end
    local lists = self.VoiceLines[self.Cfg.VoiceType]
    if not lists then return end
    
    local list = isCombat and lists.combat or lists.passive
    if list and #list > 0 then
        local snd = list[math.random(#list)]
        self:EmitSound(snd, 80, math.random(95, 105))
        self.NextVoiceTime = CurTime() + math.random(8, 16)
    end
end

function ENT:PlayFootstep(isSprint)
    print("Footstep Called! FootsetType is: ", tostring(self.Cfg.FootsetType))
    if not self.Cfg.FootsetType then return end
    
    local tr = util.TraceLine({
        start = self:GetPos() + Vector(0,0,10),
        endpos = self:GetPos() - Vector(0,0,20),
        filter = self
    })
    local mat = tr.MatType
    local matName = "concrete"
    if mat == MAT_DIRT or mat == MAT_GRASS or mat == MAT_SAND or mat == MAT_SNOW or mat == MAT_SLOSH then
        matName = "dirt"
    elseif mat == MAT_METAL or mat == MAT_GRATE or mat == MAT_VENT then
        matName = "metal"
    elseif mat == MAT_WOOD then
        matName = "wood"
    end
    
    local moveset = self.Cfg.FootsetType
    local pfx = matName:sub(1,1)
    local act = isSprint and "sprint" or "walk"
    if self:GetActivity() == ACT_HL2MP_WALK_CROUCH then act = "cwalk" end
    if moveset == "droideka" then act = "walk" end
    
    local maxVars = moveset == "droideka" and 7 or 6
    local snd = string.format("npcs/move/%s/%s/%s_%s_%d.wav", moveset, matName, pfx, act, math.random(1, maxVars))
    -- print("[IVO_NPC] Paso: ", snd)
    self:EmitSound(snd, 70, math.random(95, 105), 0.4)
end

function ENT:HandleAnimEvent(event, eventTime, cycle, type, options)
    if event == 2050 or event == 3900 or event == 3901 or event == 3902 or string.find(options or "", "step") then
        if not (self.IsRolling and self.Cfg.SoundRoll) then
            local isSprint = (self.loco:GetVelocity():LengthSqr() > 20000)
            self:PlayFootstep(isSprint)
        end
        return true
    end
end

-- Parents the blaster model to the right hand (attachment -> bone -> fallback).
function ENT:EquipWeapon()
    if self.Cfg.NoExternalWeapon then return end

    self.WeaponProp = ents.Create("prop_dynamic")
    if not IsValid(self.WeaponProp) then return end

    self.WeaponProp:SetModel(self.Cfg.WeaponModel)
    self.WeaponProp:SetPos(self:GetPos())
    self.WeaponProp:Spawn()
    self.WeaponProp:SetSolid(SOLID_NONE)

    if self.Cfg.InvisibleWeapon then
        self.WeaponProp:SetNoDraw(true)
    end

    local attachID = self:LookupAttachment("anim_attachment_RH")
    local boneID   = self:LookupBone("ValveBiped.Bip01_R_Hand")

    if attachID and attachID > 0 then
        self.WeaponProp:SetParent(self, attachID)
    elseif boneID then
        self.WeaponProp:SetParent(self)
        self.WeaponProp:FollowBone(self, boneID)
    else
        self.WeaponProp:SetParent(self)
        self.WeaponProp:Fire("setparentattachment", "anim_attachment_RH")
    end

    self.WeaponProp:SetLocalPos(Vector(2, -1, -2))
    self.WeaponProp:SetLocalAngles(Angle(0, 0, 0))
end

-- Reads real damage/sound/cadence from the configured TFA weapon.
function ENT:GetTFAStats()
    local data = weapons.GetStored(self.Cfg.WeaponClass)
    if not data or not data.Primary then return nil end

    local snd = self.Cfg.ShootSound or data.Primary.Sound or "Weapon_AR2.Single"
    if istable(snd) then
        snd = snd[math.random(#snd)]
    end
    
    return {
        Damage    = data.Primary.Damage or 20,
        Sound     = snd,
        Delay     = data.Primary.Delay or 0.3,
        Projectile = data.Primary.Projectile,
        Tracer    = self.Cfg.TracerName or data.TracerName or "effect_sw_laser_red",
    }
end

function ENT:UpdateShield(wantsActive)
    if not self.Cfg.HasShield then return end

    -- Si el escudo estÃ¡ roto, no se puede encender
    if wantsActive and self.CurrentShield <= 0 then
        wantsActive = false
    end

    if wantsActive and not self.ShieldActive then
        self.ShieldActive = true
        self:SetNW2Bool("HasShieldActive", true)
        
        if not IsValid(self.ShieldProp) then
            self.ShieldProp = ents.Create("prop_dynamic")
            if IsValid(self.ShieldProp) then
                -- Usamos un modelo nativo 100% garantizado en GMod (Hoverball) para evitar el ERROR gigante
                self.ShieldProp:SetModel("models/dav0r/hoverball.mdl")
                self.ShieldProp:SetModelScale(8.5, 0) -- Lo escalamos muchÃ­simo porque la hoverball es pequeÃ±a
                self.ShieldProp:SetPos(self:GetPos() + Vector(0,0,35))
                self.ShieldProp:SetParent(self)
                self.ShieldProp:Spawn()
                self.ShieldProp:SetSolid(SOLID_NONE)
                self.ShieldProp:SetRenderMode(RENDERMODE_TRANSALPHA)
                -- Color celeste suave y muy translÃºcido (menos chillÃ³n)
                self.ShieldProp:SetColor(Color(30, 130, 200, 35))
                -- Volvemos al material liso para ese aspecto de holograma puro
                self.ShieldProp:SetMaterial("models/debug/debugwhite")
            end
        end
        
        if IsValid(self.ShieldProp) then
            self.ShieldProp:SetNoDraw(false)
            
            -- Efecto de apariciÃ³n: La burbuja nace pequeÃ±a y se expande rÃ¡pidamente
            self.ShieldProp:SetModelScale(0.1, 0)
            self.ShieldProp:SetModelScale(8.5, 0.4) -- Tarda 0.4s en alcanzar su tamaÃ±o mÃ¡ximo
            
            -- Destello de "igniciÃ³n" en el centro
            local flash = EffectData()
            flash:SetOrigin(self:GetPos() + Vector(0,0,35))
            flash:SetScale(1.5)
            util.Effect("StunstickImpact", flash)
            
            self:EmitSound("weapons/physcannon/physcannon_charge.wav", 75, 120)
        end

    elseif not wantsActive and self.ShieldActive then
        self.ShieldActive = false
        self:SetNW2Bool("HasShieldActive", false)
        if IsValid(self.ShieldProp) then
            self.ShieldProp:SetNoDraw(true)
            self:EmitSound("weapons/physcannon/physcannon_drop.wav", 75, 120)
        end
    end
end

----------------------------------------------------------------------
-- Perception
----------------------------------------------------------------------

local EYE_OFFSET = Vector(0, 0, 50)
local TARGET_OFFSET = Vector(0, 0, 50)
local VEC_UP_10 = Vector(0, 0, 10)
local VEC_UP_20 = Vector(0, 0, 20)
local VEC_UP_40 = Vector(0, 0, 40)
local VEC_DOWN_1 = Vector(0, 0, -1)
local VEC_ZERO = Vector(0, 0, 0)

local function DroidVisionFilter(ent)
    return not ent.IsDroidNPC
end

local DroidVisionTrace = { filter = DroidVisionFilter }

function ENT:CanSee(target)
    if not IsValid(target) then return false end

    local startPos = self:GetPos() + EYE_OFFSET
    
    DroidVisionTrace.start = startPos

    -- 1. Center
    DroidVisionTrace.endpos = target:WorldSpaceCenter()
    local res = util.TraceLine(DroidVisionTrace)
    if res.Entity == target then return true end

    -- 2. Eyes
    DroidVisionTrace.endpos = target.EyePos and target:EyePos() or (target:GetPos() + TARGET_OFFSET)
    res = util.TraceLine(DroidVisionTrace)
    if res.Entity == target then return true end

    -- 3. Pies/rodillas
    DroidVisionTrace.endpos = target:GetPos() + VEC_UP_10
    res = util.TraceLine(DroidVisionTrace)
    if res.Entity == target then return true end
    
    return false
end

-- Returns true if the player should be detected based on stealth, FOV, proximity, and voice rules
function ENT:IsPlayerDetectable(p)
    if not p:Alive() or p:IsFlagSet(FL_NOTARGET) then return false end

    local dist = self:GetPos():Distance(p:GetPos())
    if dist > self.Cfg.DetectRadius then return false end

    if not self:CanSee(p) then return false end

    -- 1. Proximity: unconditionally detected if within 90 units
    if dist <= 90 then return true end

    -- 2. Voice: hearing players talk within 400 units
    if dist <= 400 and p:IsSpeaking() then return true end

    -- 3. Footsteps/Noise: moving without sneaking (crouch/walk)
    local sneaking = p:Crouching() or p:KeyDown(IN_DUCK) or p:KeyDown(IN_WALK)
    local moving = p:GetVelocity():LengthSqr() > 100
    if moving and not sneaking then return true end

    -- 4. Vision: in the droid's FOV (~140 degrees)
    local dirToTarget = (p:GetPos() - self:GetPos()):GetNormalized()
    local dot = self:GetForward():Dot(dirToTarget)
    if dot > 0.3 then return true end

    return false
end

-- All players that are alive, not notarget, inside DetectRadius, visible, and meet detection criteria.
function ENT:FindVisibleTargets()
    local found = {}
    local owner = self:GetNWEntity("CommanderOwner")
    if IsValid(owner) and owner:GetNWBool("IVO_RTS_Passive", false) then return found end

    for _, p in ipairs(player.GetAll()) do
        if self:IsPlayerDetectable(p) then
            found[#found + 1] = p
        end
    end
    return found
end

-- UC-1: pick a RANDOM visible target (not the nearest).
function ENT:PickRandomTarget()
    local targets = self:FindVisibleTargets()
    if #targets == 0 then return nil end
    return targets[math.random(#targets)]
end

-- UC-2: is there a valid player still worth chasing?
function ENT:HasValidEnemy()
    local owner = self:GetNWEntity("CommanderOwner")
    if IsValid(owner) and owner:GetNWBool("IVO_RTS_Passive", false) then return false end

    local e = self.Enemy
    -- If we were just attacked by them recently, bypass distance check so we can react
    if self.PendingAttacker == e and CurTime() < (self.NextReaction or 0) + 3 then
        return true
    end

    if not IsValid(e) or not e:IsPlayer() or not e:Alive() or e:IsFlagSet(FL_NOTARGET) then
        return false
    end

    -- Update memory if the player is fully detectable right now
    if self:IsPlayerDetectable(e) then
        self.MemoryTime = CurTime() + 2 -- remember for 2 seconds
    end

    -- Si todavÃ­a tenemos memoria del jugador (ej: por alerta de contagio), lo mantenemos
    -- sin importar a quÃ© distancia estÃ© temporalmente.
    if CurTime() > (self.MemoryTime or 0) then
        return false
    end

    return true
end

function ENT:OnInjured(info)
    -- Interceptar daÃ±o si el escudo estÃ¡ activo
    if self.Cfg.HasShield and self.ShieldActive and self.CurrentShield > 0 then
        local dmg = info:GetDamage()
        self.CurrentShield = self.CurrentShield - dmg
        
        -- Efecto visual de onda circular en el escudo
        local shieldCenter = self:GetPos() + Vector(0,0,35)
        local impactPos = info:GetDamagePosition()
        local impactNormal = (impactPos - shieldCenter):GetNormalized()
        
        if impactNormal:LengthSqr() == 0 then impactNormal = Vector(0,0,1) end
        
        local effectdata = EffectData()
        effectdata:SetOrigin(shieldCenter)
        effectdata:SetNormal(impactNormal)
        effectdata:SetRadius(43) -- Radio real de la burbuja (Hoverball radius ~5 * 8.5 = 42.5)
        effectdata:SetEntity(self)
        util.Effect("droideka_shield_impact", effectdata)
        
        self:EmitSound("npcs/effects/shield/impact/hit_"..math.random(1,8)..".wav", 80, math.random(95, 105))
        self:EmitSound("npcs/effects/shield/tail/tail_"..math.random(1,5)..".wav", 80, math.random(95, 105))

        if self.CurrentShield <= 0 then
            -- Efecto Star Wars: "Fizzle" elÃ©ctrico y parpadeo en lugar de explosiÃ³n
            self:EmitSound("ambient/energy/zap" .. math.random(1,3) .. ".wav", 85, 100)
            self:EmitSound("weapons/stunstick/stunstick_fleshhit1.wav", 90, 100)
            
            -- Electricidad superficial
            local breakEffect = EffectData()
            breakEffect:SetOrigin(self:GetPos() + Vector(0,0,40))
            breakEffect:SetScale(2)
            breakEffect:SetMagnitude(2)
            util.Effect("TeslaHitboxes", breakEffect)
            
            -- Parpadeo visual (flicker) durante 0.4 segundos antes de apagarse por completo
            if IsValid(self.ShieldProp) then
                local prop = self.ShieldProp
                local count = 0
                timer.Create("DroidekaFlicker_"..self:EntIndex(), 0.05, 8, function()
                    if IsValid(prop) then
                        count = count + 1
                        prop:SetNoDraw(count % 2 == 0)
                        if count == 8 and IsValid(self) then
                            self:UpdateShield(false)
                        end
                    end
                end)
            else
                self:UpdateShield(false)
            end
            
            self.NextShieldRecharge = CurTime() + self.Cfg.ShieldRecharge
        end
        
        info:SetDamage(0)
        return
    end

    local attacker = info:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() and attacker:Alive() and not attacker:IsFlagSet(FL_NOTARGET) then
        -- Alertar a todos instantÃ¡neamente cuando nos disparan
        self:AlertAllies(attacker)
        
        if self.Enemy ~= attacker then
            self.PendingAttacker = attacker
            self.NextReaction = CurTime() + (self.Cfg.ReactionTime or 0.4)
        end
    end
end

function ENT:OnKilled(dmginfo)
    self:EmitSound("npcs/effects/dead/dead_" .. math.random(1,3) .. ".wav", 85, math.random(95, 105))

    if self.Cfg.ExplodesOnDeath then
        -- PequeÃ±a explosiÃ³n visual
        local ed = EffectData()
        ed:SetOrigin(self:GetPos() + Vector(0,0,40))
        ed:SetScale(1)
        util.Effect("AR2Explosion", ed)
        
        local sparks = EffectData()
        sparks:SetOrigin(self:GetPos() + Vector(0,0,40))
        sparks:SetMagnitude(2)
        sparks:SetScale(2)
        sparks:SetRadius(2)
        util.Effect("Sparks", sparks)
        
        -- Sonido de explosiÃ³n pequeÃ±o y agudo
        self:EmitSound("ambient/explosions/explode_9.wav", 85, math.random(110, 130))
    end
    
    local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() then
        if attacker.addMoney then
            local mult = (IVO_RTS and IVO_RTS.Config and IVO_RTS.Config.DarkRPRewardMultiplier) or 50
            local reward = self.Cost and (self.Cost * mult) or 50
            -- attacker:addMoney(reward)
            if DarkRP and DarkRP.notify then
                -- DarkRP.notify(attacker, 0, 4, "Has recibido $" .. reward .. " por destruir una unidad enemiga.")
            end
        end
    end
    
    if IsValid(self.WeaponProp) then
        self.WeaponProp:Remove()
    end
    if IsValid(self.ShieldProp) then
        self.ShieldProp:Remove()
    end

    -- Default nextbot behavior
    self:BecomeRagdoll(dmginfo)
end

----------------------------------------------------------------------
-- Squad coordination
----------------------------------------------------------------------

function ENT:CountNearbyAllies()
    local count = 0
    for _, e in ipairs(ents.FindInSphere(self:GetPos(), self.Cfg.SquadRadius)) do
        if e ~= self and IsValid(e) and e.IsDroidNPC then
            count = count + 1
        end
    end
    return count
end

-- UC-5 / UC-6: rush if grouped, otherwise 50/50 run-and-gun vs hold.
function ENT:DecideEngagementStyle()
    if self:CountNearbyAllies() >= self.Cfg.SquadMin then
        return "rush"
    end
    if self.Cfg.NeverHold then
        return "rungun"
    end
    return (math.random() < 0.5) and "rungun" or "hold"
end

function ENT:AlertAllies(target)
    -- Si shared.lua no recargÃ³, forzamos el radio a 1500 para los B1.
    local radius = self.Cfg.AlertRadius or (string.find(self:GetClass() or "", "b1") and 1500)
    if not radius then return end
    
    if CurTime() < (self.NextAlertTime or 0) then return end
    self.NextAlertTime = CurTime() + 1 

    for _, e in ipairs(ents.FindInSphere(self:GetPos(), radius)) do
        -- Relajamos la verificaciÃ³n de si es un droide por si IsDroidNPC no se estÃ¡ leyendo bien
        if e ~= self and IsValid(e) and (e.IsDroidNPC or string.find(e:GetClass() or "", "npc_droid_")) and e:Health() > 0 then

            -- Solo propagar y re-enfocar si el aliado no estaba ya enfocado en este objetivo
            if e.Enemy ~= target then
                e.Enemy = target
                e.EngageStyle = nil
                e.NextRetarget = CurTime() + e.Cfg.RetargetInterval
                -- Se le da "memoria" extra (10 segundos) para que persiga al jugador
                e.MemoryTime = CurTime() + 10 
                
                -- Efecto contagio: el aliado alerta a los suyos instantÃ¡neamente
                e:AlertAllies(target)
            end
        end
    end
end

----------------------------------------------------------------------
-- Accuracy
----------------------------------------------------------------------

-- UC-3: flat spread within AccurateFraction of range, then degrade to MaxSpread.
function ENT:ComputeSpread(dist)
    local cfg = self.Cfg
    local frac = math.Clamp(dist / cfg.FireRange, 0, 1)
    if frac <= cfg.AccurateFraction then
        return cfg.BaseSpread
    end
    local t = (frac - cfg.AccurateFraction) / (1 - cfg.AccurateFraction)
    return Lerp(t, cfg.BaseSpread, cfg.MaxSpread * 0.5)
end

local function applySpread(dir, spread)
    local ang = dir:Angle()
    -- spread is a 0..1 cone factor; scale to a believable degree cone.
    ang:RotateAroundAxis(ang:Up(),    math.Rand(-1, 1) * spread * 45)
    ang:RotateAroundAxis(ang:Right(), math.Rand(-1, 1) * spread * 45)
    return ang:Forward()
end

----------------------------------------------------------------------
-- Main behaviour loop
----------------------------------------------------------------------

local function ObstacleFilter(ent)
    return not ent.IsDroidNPC and not ent.IsRTSUnit
end

local ObstacleFeelerTrace = {
    mins = Vector(-10, -10, 0),
    maxs = Vector(10, 10, 10),
    filter = ObstacleFilter
}

function ENT:RunBehaviour()
    while true do
        -- Recarga de escudo automÃ¡tica
        if self.Cfg.HasShield and self.CurrentShield <= 0 then
            if CurTime() > self.NextShieldRecharge then
                self.CurrentShield = self.Cfg.ShieldHealth
                self:EmitSound("items/suitchargeok1.wav", 80, 100)
                -- Se activarÃ¡ automÃ¡ticamente en el prÃ³ximo frame si estÃ¡ caminando
            end
        end

        -- React to damage from an attacker
        if IsValid(self.PendingAttacker) and CurTime() >= (self.NextReaction or 0) then
            if self.PendingAttacker:Alive() and not self.PendingAttacker:IsFlagSet(FL_NOTARGET) then
                self.Enemy = self.PendingAttacker
                self.EngageStyle = nil
                self.NextRetarget = CurTime() + self.Cfg.RetargetInterval
            end
            -- Don't clear PendingAttacker immediately so HasValidEnemy can bypass radius for a bit
            if CurTime() > (self.NextReaction or 0) + 3 then
                self.PendingAttacker = nil
            end
        end

        if not self:HasValidEnemy() or CurTime() > self.NextRetarget then
            -- (re)acquire a random visible target
            local newEnemy = self:PickRandomTarget()
            if IsValid(newEnemy) then
                if newEnemy ~= self.Enemy then
                    self.EngageStyle = nil       -- force a fresh decision for a new target
                    self:PlayVoiceLine(IsValid(self.Enemy))
                end
                self.Enemy = newEnemy
            elseif not self:HasValidEnemy() then
                self.Enemy = nil
            end
            self.NextRetarget = CurTime() + self.Cfg.RetargetInterval
        end

        if self.CommanderGoal then
            self:RTSMoveToGoal()
        elseif IsValid(self.Enemy) then
            self:ChaseAndFire()
        else
            self:Patrol()
        end

        coroutine.yield()
    end
end

-- UC-7: wander when there is nothing to shoot.
function ENT:CheckIdleChatter()
    if CurTime() < (self.NextVoiceTime or 0) then return end
    
    local anyPlayerNear = false
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetPos():DistToSqr(self:GetPos()) < 1000000 then -- 1000 units squared
            anyPlayerNear = true
            break
        end
    end
    
    if anyPlayerNear then
        self:PlayVoiceLine(false)
    end
end

function ENT:Patrol()
    self:CheckIdleChatter()
    local owner = self:GetNWEntity("CommanderOwner")
    local holdPos = IsValid(owner) and owner:GetNWBool("IVO_RTS_HoldPos", false)
    
    if holdPos then
        self.loco:SetDesiredSpeed(0)
        if self.Cfg.HasShield then self:UpdateShield(true) end
        
        local waitEndTime = CurTime() + 2
        while CurTime() < waitEndTime do
            if IsValid(self.Enemy) or self.CommanderGoal then return end
            self:PlayActivity(ACT_HL2MP_IDLE_SHOTGUN, self.Cfg.CustomSequenceIdle)
            coroutine.yield()
        end
        return
    end

    self.loco:SetDesiredSpeed(100)
    
    if self.Cfg.HasShield then self:UpdateShield(true) end
    
    -- Creamos un path personalizado para el patrullaje para que sea interrumpible al instante
    local targetPos = self:GetPos() + Vector(math.random(-300, 300), math.random(-300, 300), 0)
    local path = Path("Follow")
    path:SetMinLookAheadDistance(300)
    path:SetGoalTolerance(20)
    path:Compute(self, targetPos)
    
    while path:IsValid() and self:GetPos():Distance(targetPos) > 20 do
        if IsValid(self.Enemy) or self.CommanderGoal then return end -- Rompe el patrullaje AL INSTANTE si es alertado o recibe orden
        
        -- Forzamos la animaciÃ³n en cada frame del bucle (como en ChaseAndFire) para que el motor no la sobrescriba
        self:PlayActivity(ACT_HL2MP_WALK_SHOTGUN, self.Cfg.CustomSequenceWalk)
        
        path:Update(self)
        if self.loco:IsStuck() then
            self.loco:ClearStuck()
            break
        end
        coroutine.yield()
    end
    
    local waitEndTime = CurTime() + 2
    while CurTime() < waitEndTime do
        if IsValid(self.Enemy) or self.CommanderGoal then return end -- Rompe la espera AL INSTANTE
        self:PlayActivity(ACT_HL2MP_IDLE_SHOTGUN, self.Cfg.CustomSequenceIdle)
        coroutine.yield()
    end
end

-- UC-RTS: Commander orders the unit to move to a specific position.
function ENT:RTSMoveToGoal()
    local targetPos = self.CommanderGoal
    if not targetPos then return end
    
    if not self.StartedRTSMove then
        self.StartedRTSMove = true
        self:PlayVoiceLine(IsValid(self.Enemy))
    end

    if self.Cfg.HasShield then self:UpdateShield(false) end
    
    local path = Path("Follow")
    path:SetMinLookAheadDistance(300)
    path:SetGoalTolerance(10)
    path:Compute(self, targetPos)
    
    -- Always sprint/run to the RTS goal to feel responsive
    self.loco:SetDesiredSpeed(self.Cfg.RunSpeed)
    
    while self.CommanderGoal == targetPos do
        local distToGoal = self:GetPos():Distance(targetPos)
        if distToGoal < 15 then break end

        if self.Cfg.HasShield then self:UpdateShield(false) end

        -- If the commander gave a new goal while walking, recompute
        if self.CommanderGoal ~= targetPos then return end

        if not path:IsValid() or path:GetAge() > 2 then
            path:Compute(self, targetPos)
        end

        local isRollingNow = true
        if self.Cfg.WalkDistanceFrac and self.IsRolling ~= isRollingNow then
            if isRollingNow then
                if self.Cfg.SoundRoll then
                    if not self.RollSoundObj then
                        self.RollSoundObj = CreateSound(self, self.Cfg.SoundRoll)
                    end
                    self.RollSoundObj:Play()
                end
            end
            self.IsRolling = isRollingNow
        end

        if IsValid(self.Enemy) and self:CanSee(self.Enemy) then
            local enemyDist = self:GetPos():Distance(self.Enemy:GetPos())
            if enemyDist <= self.Cfg.FireRange then
                self.loco:FaceTowards(self.Enemy:GetPos())
                self:RangedAttack(enemyDist)
            end
        else
            self.loco:FaceTowards(self.loco:GetVelocity() + self:GetPos())
        end

        self:PlayActivity(ACT_HL2MP_RUN_SHOTGUN, self.Cfg.CustomSequenceRun)
        
        path:Update(self)
        
        if self.Cfg.IsJetpack and math.random() < 0.02 and math.abs(self.loco:GetVelocity().z) < 100 and IsValid(self.Enemy) then
            local dist = self:GetPos():Distance(self.Enemy:GetPos())
            if dist > 400 and dist < 1500 then
                self.loco:Jump()
                local dir = (self.Enemy:GetPos() - self:GetPos()):GetNormalized()
                self.loco:SetVelocity(self.loco:GetVelocity() + dir * 600 + Vector(0,0,500))
                self:EmitSound("npcs/jetpack/b2j/j_b2_" .. math.random(1,3) .. ".wav", 90, math.random(95, 105))
                self.IsFlying = CurTime() + 1.2
            end
        end

        if self.loco:IsStuck() then
            self.loco:ClearStuck()
            if self.Cfg.IsJetpack then
                self.loco:SetVelocity(self.loco:GetVelocity() + Vector(0,0,600))
                self:EmitSound("npcs/jetpack/b2j/j_b2_" .. math.random(1,3) .. ".wav", 90, math.random(95, 105))
                self.IsFlying = CurTime() + 1.2
            else
                self.loco:Jump()
            end
            path:Invalidate() -- Force recompute next frame
        else
            -- Feeler for obstacles: jump over props or low walls
            local vel = self.loco:GetVelocity()
            if vel:LengthSqr() > 100 then
                ObstacleFeelerTrace.start = self:GetPos() + VEC_UP_20
                ObstacleFeelerTrace.endpos = ObstacleFeelerTrace.start + vel:GetNormalized() * 30
                local tr = util.TraceHull(ObstacleFeelerTrace)
                if tr.Hit and math.abs(self.loco:GetVelocity().z) < 100 then
                    self.loco:Jump()
                end
            end
        end
        coroutine.yield()
    end

    -- Reached goal or got stuck, clear the goal so it can patrol/chase again
    if self.CommanderGoal == targetPos then
        self.CommanderGoal = nil
        self.StartedRTSMove = false
    end
    
    if self.Cfg.HasShield then self:UpdateShield(true) end

    -- Stop rolling sound if it was playing
    if self.IsRolling then
        if self.RollSoundObj then self.RollSoundObj:Stop() end
        self.NextRollSound = 0
        if self.Cfg.SoundDeploy then self:EmitSound(self.Cfg.SoundDeploy, 85, 100) end
        self.IsRolling = false
    end
end

function ENT:ChaseAndFire()
    self:PlayVoiceLine(true)
    local cfg = self.Cfg

    local owner = self:GetNWEntity("CommanderOwner")

    if not self.EngageStyle then
        self.EngageStyle = self:DecideEngagementStyle()
        self.NextStyleEval = CurTime() + 1
    end

    local path = Path("Follow")
    path:SetMinLookAheadDistance(cfg.LookAhead)
    path:SetGoalTolerance(self.EngageStyle == "rush" and 10 or cfg.GoalTolerance)
    path:Compute(self, self.Enemy:GetPos())

    local zigZagSide = 1
    local nextZigZag = 0

    while IsValid(self.Enemy) and self:HasValidEnemy() do
        -- Si recibe orden RTS, abandonar el combate inmediatamente
        if self.CommanderGoal then return end
        
        -- Hand control back so RunBehaviour can re-pick a random visible target.
        if CurTime() > self.NextRetarget then return end

        -- Periodically re-evaluate squad style (allies may have died/arrived).
        if CurTime() > self.NextStyleEval then
            self.EngageStyle = self:DecideEngagementStyle()
            self.NextStyleEval = CurTime() + 1
        end

        local enemyPos = self.Enemy:GetPos()
        local dist = self:GetPos():Distance(enemyPos)
        
        if CurTime() > (self.NextLOSCheck or 0) then
            self.CachedLOS = self:CanSee(self.Enemy)
            self.NextLOSCheck = CurTime() + math.Rand(0.1, 0.2)
        end
        local hasLOS = self.CachedLOS
        
        local visible = (dist <= cfg.FireRange) and hasLOS

        -- Shield and movement logic
        local holdPos = IsValid(owner) and owner:GetNWBool("IVO_RTS_HoldPos", false)
        local forceHold = (cfg.KeepDistance and dist < cfg.KeepDistance)
        local holding = holdPos or ((self.EngageStyle == "hold" or forceHold) and visible)
        local timeSinceSeen = CurTime() - (self.LastSeen or 0)
        local firingRecently = timeSinceSeen < 3.0
        local shouldWalk = firingRecently

        if cfg.WalkDistanceFrac then
            local walkThresh = cfg.FireRange * cfg.WalkDistanceFrac
            -- HistÃ©resis: si el droide ya estÃ¡ desplegado (caminando/disparando), 
            -- no volverÃ¡ a su modo rÃ¡pido (rueda) a menos que el jugador se aleje 400 unidades extra.
            -- Esto evita que empaque y desempaque repetitivamente por moverse unos pocos metros.
            if not self.IsRolling then
                walkThresh = walkThresh + 400
            end
            shouldWalk = (dist <= walkThresh)
        end
        
        -- Determinar explÃ­citamente si estamos rodando/corriendo ahora
        local isRollingNow = false
        if not forceHold then
            isRollingNow = not holding and not shouldWalk
        end

        if cfg.HasShield then
            -- Solo puede activar el escudo si NO estÃ¡ rodando
            self:UpdateShield(not isRollingNow)
        end

        if holding then
            -- Stand and shoot; only the LOS-based reposition below moves us.
            self.loco:SetDesiredSpeed(0)
        else
            local targetPos = enemyPos
            if cfg.ZigZagWidth then
                -- Check if the enemy is looking directly at the droid
                local isAimingAtUs = false
                if IsValid(self.Enemy) and self.Enemy.GetAimVector and self.Enemy.GetShootPos then
                    local dirToUs = (self:GetPos() - self.Enemy:GetShootPos()):GetNormalized()
                    -- Lower dot product = detects if they are basically anywhere on your screen (~60 degrees)
                    -- Y solo zigzaguea si estÃ¡ a mÃ¡s de 120 unidades de distancia (para que logre llegar a 0)
                    if self.Enemy:GetAimVector():Dot(dirToUs) > 0.5 and dist > 120 then
                        isAimingAtUs = true
                    end
                end

                if isAimingAtUs then
                    if CurTime() > nextZigZag then
                        -- Cambios de direcciÃ³n con cadencia MUY impredecible (a veces instantÃ¡neo, a veces tarda)
                        zigZagSide = (math.random() < 0.5) and 1 or -1
                        nextZigZag = CurTime() + math.Rand(0.05, 0.6)
                        
                        -- El jugador estÃ¡ disparando/atacando (presionando clic izquierdo)
                        local isAttackingUs = false
                        if self.Enemy:IsPlayer() and self.Enemy:KeyDown(IN_ATTACK) then
                            isAttackingUs = true
                        end

                        -- Decide quÃ© tipo de esquive fÃ­sico hacer SOLO si nos estÃ¡n atacando
                        if math.abs(self.loco:GetVelocity().z) < 100 and isAttackingUs then
                            local roll = math.random()
                            if cfg.JumpChance and roll < cfg.JumpChance then
    -- Salto acrob�tico (Jump Dash)
    self.loco:Jump()
    local dir = (enemyPos - self:GetPos()):GetNormalized()
    local right = dir:Angle():Right()
    -- Fuerza de salto impredecible
    if cfg.IsJetpack then
        self.loco:SetVelocity(self.loco:GetVelocity() + right * (zigZagSide * math.Rand(400, 800)) + Vector(0,0,math.Rand(400, 700)))
        self:EmitSound("npcs/jetpack/b2j/j_b2_" .. math.random(1,3) .. ".wav", 90, math.random(95, 105))
        self.IsFlying = CurTime() + 1.2
    else
        self.loco:SetVelocity(self.loco:GetVelocity() + right * (zigZagSide * math.Rand(300, 600)))
    end
                            elseif cfg.DashChance and roll < (cfg.JumpChance or 0) + cfg.DashChance then
                                -- Dash terrestre (solo velocidad lateral, sin salto)
                                local dir = (enemyPos - self:GetPos()):GetNormalized()
                                local right = dir:Angle():Right()
                                -- Fuerza de derrape terrestre impredecible
                                self.loco:SetVelocity(self.loco:GetVelocity() + right * (zigZagSide * math.Rand(500, 1200)))
                            end
                            -- Si no cae en ninguno, hace un zig-zag normal
                        end
                    end
                    local dir = (enemyPos - self:GetPos()):GetNormalized()
                    local right = dir:Angle():Right()
                    
                    -- Se reduce la amplitud del zigzag a medida que se acerca al jugador.
                    -- Esto forma un "embudo" que lo obliga a llegar a 0 en vez de quedarse orbitando.
                    local distScale = math.Clamp(dist / 800, 0.15, 1.0)
                    local randWidth = cfg.ZigZagWidth * math.Rand(0.5, 4.0) * distScale
                    targetPos = enemyPos + right * (randWidth * zigZagSide)
                else
                    nextZigZag = 0
                end
            end

            -- Recompute the path toward the target position with desynchronization.
            if not self.NextRepathTime or CurTime() > self.NextRepathTime or not path:IsValid() then
                path:Compute(self, targetPos)
                self.NextRepathTime = CurTime() + cfg.RepathInterval + math.Rand(-0.1, 0.1)
            end
            if path:IsValid() then
                path:Update(self)
            else
                -- No navmesh / unreachable: still close the gap roughly.
                self.loco:Approach(targetPos, 1)
            end

            if self.loco:IsStuck() then
                self.loco:ClearStuck()
                return
            end
        end

        -- Animation + speed selection ----------------------------------
        local shouldShootBlind = (timeSinceSeen < 3.0)
        if (hasLOS or shouldShootBlind) and not isRollingNow then
            if hasLOS then
                self.LastSeen = CurTime()
            end
            self.loco:FaceTowards(enemyPos)
            local shootDist = dist
            if not hasLOS then shootDist = shootDist * 2 end -- More inaccurate when blind firing
            self:RangedAttack(shootDist)
        end

        if self.IsRolling ~= isRollingNow then
            if isRollingNow then
                if cfg.SoundRoll then
                    if not self.RollSoundObj then
                        self.RollSoundObj = CreateSound(self, cfg.SoundRoll)
                    end
                    self.RollSoundObj:Play()
                end
            else
                if self.RollSoundObj then
                    self.RollSoundObj:Stop()
                end
                self.NextRollSound = 0
                if cfg.SoundDeploy then
                    self:EmitSound(cfg.SoundDeploy, 85, 100)
                end
            end
            self.IsRolling = isRollingNow
        end
        
        -- Forzar el bucle: si seguimos rodando y el sonido se apagÃ³, lo reiniciamos
        if self.IsRolling and cfg.SoundRoll then
            if not self.NextRollSound or CurTime() > self.NextRollSound then
                if self.RollSoundObj then self.RollSoundObj:Stop() end
        self.NextRollSound = 0
                self.RollSoundObj = CreateSound(self, cfg.SoundRoll)
                self.RollSoundObj:Play()
                
                local duration = SoundDuration(cfg.SoundRoll)
                if duration <= 0 then duration = 2 end
                self.NextRollSound = CurTime() + duration - 0.1
            end
        end

        if isRollingNow then
            if self.EngageStyle == "rush" then
                self:PlayActivity(ACT_HL2MP_RUN_SHOTGUN, cfg.CustomSequenceRush)
                self.loco:SetDesiredSpeed(cfg.RushSpeed)
            else
                self:PlayActivity(ACT_HL2MP_RUN_SHOTGUN, cfg.CustomSequenceRun)
                self.loco:SetDesiredSpeed(cfg.RunSpeed)
            end

        elseif holding then
            self:PlayActivity(ACT_HL2MP_IDLE_SHOTGUN, cfg.CustomSequenceIdle)
        else
            self:PlayActivity(ACT_HL2MP_WALK_SHOTGUN, cfg.CustomSequenceWalk)
            self.loco:SetDesiredSpeed(cfg.WalkSpeed)
        end

        if cfg.IsJetpack and math.random() < 0.03 and math.abs(self.loco:GetVelocity().z) < 100 and IsValid(self.Enemy) then
            local distToEnemy = self:GetPos():Distance(self.Enemy:GetPos())
            if distToEnemy > 400 and distToEnemy < 1500 then
                self.loco:Jump()
                local dir = (self.Enemy:GetPos() - self:GetPos()):GetNormalized()
                self.loco:SetVelocity(self.loco:GetVelocity() + dir * 650 + Vector(0,0,500))
                self:EmitSound("npcs/jetpack/b2j/j_b2_" .. math.random(1,3) .. ".wav", 90, math.random(95, 105))
                self.IsFlying = CurTime() + 1.2
            end
        end

        coroutine.yield()
    end
end

-- Fallback map: if an ACT_HL2MP_* constant is nil or 0 (missing on dedicated
-- servers without HL2MP mounted), use a guaranteed base-HL2 activity instead.
local ACTIVITY_FALLBACK = {
    -- will be populated lazily so we don't read globals before they exist
}
local function SafeActivity(act, fallback)
    if act and act > 0 then return act end
    return fallback
end

-- Helper: only switch activity if it actually changed (avoids resetting anims).
function ENT:PlayActivity(act, customSeq)
    if self.Cfg.UseAR2HoldType then
        if act == ACT_HL2MP_IDLE_SHOTGUN then act = ACT_HL2MP_IDLE_AR2 end
        if act == ACT_HL2MP_WALK_SHOTGUN then act = ACT_HL2MP_WALK_AR2 end
        if act == ACT_HL2MP_RUN_SHOTGUN then act = ACT_HL2MP_RUN_AR2 end
    end

    -- Guard: if the activity constant is nil/invalid (e.g. ACT_HL2MP_* missing on
    -- a dedicated server without HL2MP mounted), fall back to a generic equivalent
    -- so we don't call StartActivity(nil/0) which causes the crowbar-hold pose.
    if not act or act <= 0 then
        -- Guess a sensible fallback from the requested slot
        if act == ACT_HL2MP_IDLE_SHOTGUN or act == ACT_HL2MP_IDLE then
            act = ACT_IDLE
        elseif act == ACT_HL2MP_WALK_SHOTGUN or act == ACT_HL2MP_WALK then
            act = ACT_WALK
        elseif act == ACT_HL2MP_RUN_SHOTGUN or act == ACT_HL2MP_RUN then
            act = ACT_RUN
        else
            act = ACT_IDLE
        end
    end

    -- 1. SIEMPRE informar al motor C++ de la actividad base (Walk, Run, Idle)
    -- Esto es crÃ­tico para que la locomociÃ³n interna de NextBot no se rompa y evitar el "deslizamiento".
    if self:GetActivity() ~= act then
        self:StartActivity(act)
    end

    -- 2. Si tenemos una animaciÃ³n personalizada, secuestramos la malla visual
    if customSeq then
        local seqId = self:LookupSequence(customSeq)
        if seqId > 0 then
            if self:GetSequence() ~= seqId then
                self:SetSequence(seqId)
                self:ResetSequenceInfo()
                self:SetCycle(0)
            end
            
            -- Forzar que avance el tiempo
            self:SetPlaybackRate(1)
            
            -- Bucle artificial
            if self:GetCycle() >= 0.99 then
                self:SetCycle(0)
            end
        end
    end
end



function ENT:RangedAttack(dist)
    if CurTime() <= self.NextAttack then return end
    if not self:HasValidEnemy() then return end
    
    if not self.Cfg.NoExternalWeapon and not IsValid(self.WeaponProp) then return end

    local cfg = self.Cfg
    local stats = self:GetTFAStats()
    if not stats then return end

    local spread = self:ComputeSpread(dist or self:GetPos():Distance(self.Enemy:GetPos()))
    
    local origins = {}
    if cfg.WeaponOffsets then
        -- Fuego alternado (uno y uno)
        self.NextWeaponOffsetIdx = (self.NextWeaponOffsetIdx or 0) + 1
        if self.NextWeaponOffsetIdx > #cfg.WeaponOffsets then
            self.NextWeaponOffsetIdx = 1
        end
        local offsetGroup = cfg.WeaponOffsets[self.NextWeaponOffsetIdx]
        
        if cfg.InvisibleWeapon and IsValid(self.WeaponProp) then
            local wPos = self.WeaponProp:GetPos()
            local wAng = self.WeaponProp:GetAngles()
            
            if type(offsetGroup) == "table" and type(offsetGroup[1]) == "Vector" then
                for _, offset in ipairs(offsetGroup) do
                    table.insert(origins, wPos + wAng:Forward() * offset.x + wAng:Right() * offset.y + wAng:Up() * offset.z)
                end
            else
                table.insert(origins, wPos + wAng:Forward() * offsetGroup.x + wAng:Right() * offsetGroup.y + wAng:Up() * offsetGroup.z)
            end
        elseif cfg.WeaponAttachment then
            local attachID = self:LookupAttachment(cfg.WeaponAttachment)
            if attachID and attachID > 0 then
                local attach = self:GetAttachment(attachID)
                if attach then
                    local aPos = attach.Pos
                    local aAng = attach.Ang
                    if type(offsetGroup) == "table" and type(offsetGroup[1]) == "Vector" then
                        for _, offset in ipairs(offsetGroup) do
                            table.insert(origins, aPos + aAng:Forward() * offset.x + aAng:Right() * offset.y + aAng:Up() * offset.z)
                        end
                    else
                        table.insert(origins, aPos + aAng:Forward() * offsetGroup.x + aAng:Right() * offsetGroup.y + aAng:Up() * offsetGroup.z)
                    end
                end
            end
        end
        
        if #origins == 0 and cfg.WeaponBone then
            local boneID = self:LookupBone(cfg.WeaponBone)
            if boneID then
                local bPos, bAng
                local matrix = self:GetBoneMatrix(boneID)
                if matrix then
                    bPos = matrix:GetTranslation()
                    bAng = matrix:GetAngles()
                else
                    bPos, bAng = self:GetBonePosition(boneID)
                end
                
                if type(offsetGroup) == "table" and type(offsetGroup[1]) == "Vector" then
                    for _, offset in ipairs(offsetGroup) do
                        table.insert(origins, bPos + bAng:Forward() * offset.x + bAng:Right() * offset.y + bAng:Up() * offset.z)
                    end
                else
                    table.insert(origins, bPos + bAng:Forward() * offsetGroup.x + bAng:Right() * offsetGroup.y + bAng:Up() * offsetGroup.z)
                end
            end
        end
        
        -- Fallback si no hay WeaponBone/Attachment o fallÃ³ el lookup
        if #origins == 0 then
            if type(offsetGroup) == "table" and type(offsetGroup[1]) == "Vector" then
                for _, offset in ipairs(offsetGroup) do
                    table.insert(origins, self:LocalToWorld(offset))
                end
            else
                table.insert(origins, self:LocalToWorld(offsetGroup))
            end
        end
    elseif cfg.NoExternalWeapon then
        -- Alternar entre dos attachments (brazo izquierdo y derecho) si existen
        self.NextMuzzle = not self.NextMuzzle
        local attachName = self.NextMuzzle and "muzzle_left" or "muzzle_right"
        local attachID = self:LookupAttachment(attachName)
        if attachID and attachID > 0 then
            local attach = self:GetAttachment(attachID)
            if attach then table.insert(origins, attach.Pos) end
        else
            table.insert(origins, self:GetPos() + self:GetUp() * 40 + self:GetForward() * 20)
        end
    else
        table.insert(origins, self.WeaponProp:GetPos() + self:GetForward() * 10 + self:GetUp() * 5)
    end

    for _, origin in ipairs(origins) do
        local baseDir = (self.Enemy:GetPos() + VEC_UP_40 - origin):GetNormalized()
        local dir = applySpread(baseDir, spread)

        if stats.Projectile and stats.Projectile ~= "" then
            local laser = ents.Create(stats.Projectile)
            if IsValid(laser) then
                laser:SetPos(origin)
                laser:SetAngles(dir:Angle())
                laser:SetOwner(self)
                laser:Spawn()
                laser:Activate()
                local phys = laser:GetPhysicsObject()
                if IsValid(phys) then
                    phys:SetVelocity(dir * 3000)
                end
            end
        else
            local bullet = {
                Num        = 1,
                Src        = origin,
                Dir        = dir,
                Spread     = VEC_ZERO, -- Spread ya aplicado en Dir
                Tracer     = 1,
                TracerName = stats.Tracer,
                Force      = 2,
                Damage     = stats.Damage * cfg.DamageMult,
                IgnoreEntity = self,
                Attacker   = self,
            }
            
            local fireEnt = self.Cfg.NoExternalWeapon and self or self.WeaponProp
            fireEnt:FireBullets(bullet)
        end
        
        -- Reproducir sonido desde la posiciÃ³n exacta del caÃ±Ã³n
        if cfg.SoundWeapon then
            sound.Play(cfg.SoundWeapon, origin, 85, math.random(95, 105), 1)
        elseif isstring(stats.Sound) then
            sound.Play(stats.Sound, origin, 85, math.random(95, 105), 1)
        elseif istable(stats.Sound) and #stats.Sound > 0 then
            sound.Play(stats.Sound[math.random(#stats.Sound)], origin, 85, math.random(95, 105), 1)
        end
    end

    -- Avisar a los aliados cercanos de nuestro objetivo (contagio)
    self:AlertAllies(self.Enemy)

    self.NextAttack = CurTime() + stats.Delay * cfg.FireRateMult
end

----------------------------------------------------------------------
-- Animation / cleanup
----------------------------------------------------------------------

local PoseParameters = {
    "aim_pitch", "aim_yaw", "head_pitch", "head_yaw",
    "body_pitch", "body_yaw", "spine_pitch", "spine_yaw"
}

function ENT:BodyUpdate()
    -- Only apply 9-way blending during movement activities; calling it during
    -- idle or custom sequences causes the "crowbar carry" jitter on dedicated servers.
    -- Use explicit number checks to be nil-safe in case ACT_HL2MP_* are missing.
    local act = self:GetActivity()
    local isMoving = (act and act > 0) and (
        (ACT_HL2MP_WALK_SHOTGUN and act == ACT_HL2MP_WALK_SHOTGUN) or
        (ACT_HL2MP_RUN_SHOTGUN  and act == ACT_HL2MP_RUN_SHOTGUN)  or
        (ACT_HL2MP_WALK_AR2 and act == ACT_HL2MP_WALK_AR2) or
        (ACT_HL2MP_RUN_AR2  and act == ACT_HL2MP_RUN_AR2)  or
        act == ACT_WALK or act == ACT_RUN
    )
    if isMoving then
        self:BodyMoveXY()
    end
    
    if (self.IsFlying or 0) > CurTime() then
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos() + Vector(0,0,50))
        effectdata:SetNormal(Vector(0,0,-1))
        effectdata:SetScale(1)
        util.Effect("ThumperDust", effectdata)
        util.Effect("cball_bounce", effectdata)
    end
    
    local vel = self.loco:GetVelocity()
    local speed = vel:Length2D()
    if speed > 20 and math.abs(vel.z) < 100 and not (self.IsRolling and self.Cfg.SoundRoll) then
        if not self.loco:IsOnGround() then print("Speed > 20 but NOT ON GROUND for ", self.Cfg.FootsetType) end
        local stepTime = math.Clamp(160 / speed, 0.25, 0.6)
        if CurTime() > (self.NextFootstep or 0) then
            self:PlayFootstep(speed > 120)
            self.NextFootstep = CurTime() + stepTime
        end
    end

    local isCombat = IsValid(self.Enemy)
    if self.WasInCombat ~= isCombat then
        self.WasInCombat = isCombat
        if self.Cfg.BoneManipulations then
            for boneName, angle in pairs(self.Cfg.BoneManipulations) do
                local boneID = self:LookupBone(boneName)
                if boneID then
                    if isCombat then
                        if self.Cfg.CombatBoneManipulations and self.Cfg.CombatBoneManipulations[boneName] then
                            self:ManipulateBoneAngles(boneID, self.Cfg.CombatBoneManipulations[boneName])
                        else
                            self:ManipulateBoneAngles(boneID, Angle(0, 0, 0))
                        end
                    else
                        self:ManipulateBoneAngles(boneID, angle)
                    end
                end
            end
        end
    end

    if isCombat then
        local dir = (self.Enemy:GetPos() + VEC_UP_40) - (self:GetPos() + EYE_OFFSET)
        local want = dir:Angle()
        local cur = self:GetAngles()
        local pitch = math.NormalizeAngle(want.p - cur.p)
        local yaw   = math.NormalizeAngle(want.y - cur.y)

        self:SetPoseParameter("aim_pitch", pitch)
        self:SetPoseParameter("aim_yaw", yaw)
        self:SetPoseParameter("head_pitch", pitch)
        self:SetPoseParameter("head_yaw", yaw)
        self:SetPoseParameter("body_pitch", pitch)
        self:SetPoseParameter("body_yaw", yaw)
        self:SetPoseParameter("spine_pitch", pitch)
        self:SetPoseParameter("spine_yaw", yaw)
    else
        for _, pp in ipairs(PoseParameters) do
            self:SetPoseParameter(pp, 0)
        end
    end

    self:SetPlaybackRate(1)
    self:FrameAdvance()
end

function ENT:OnRemove()
    if self.RollSoundObj then
        self.RollSoundObj:Stop()
    end
    if IsValid(self.WeaponProp) then
        self.WeaponProp:Remove()
    end
    if IsValid(self.ShieldProp) then
        self.ShieldProp:Remove()
    end
end



















































