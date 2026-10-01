AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self.BaseClass.Initialize(self)
    self:SetColor(Color(100, 100, 100)) -- Darker tone
    
    self.SniperState = "IDLE" -- Inicialmente se acuesta y escanea
    self.ScanAngle = self:GetAngles().y
    self.SniperBasePosAngle = self.ScanAngle
    self.ScanDirection = 1
    self.SniperBasePos = self:GetPos()
    self.IdealSniperPos = nil
    self.LastSeen = 0
end

-- Sobrescribimos el comportamiento principal
function ENT:RunBehaviour()
    while true do
        -- Si hay una orden RTS, respetarla por sobre todo
        if self.CommanderGoal then
            self.SniperState = "RTS"
            self:RTSMoveToGoal()
            coroutine.yield()
            continue
        end

        local enemy = self.Enemy
        if not self:HasValidEnemy() then
            enemy = self:PickRandomTarget()
            self.Enemy = enemy
        end

        -- Transiciones de estado
        local dist = IsValid(enemy) and self:GetPos():Distance(enemy:GetPos()) or math.huge
        local hpFrac = self:Health() / self:GetMaxHealth()

        if IsValid(enemy) then
            if dist < 600 then
                self.SniperState = "CLOSE_COMBAT"
                self.Cfg.JumpChance = 0.6
                self.Cfg.DashChance = 0.6
                self.Cfg.KeepDistance = nil
                self.Cfg.NeverHold = true
                self.Cfg.WalkDistanceFrac = 0.15
                self.Cfg.ZigZagWidth = 150
                self.Cfg.WalkSpeed = 150
                self.Cfg.RunSpeed = 350
                self.Cfg.RushSpeed = 450
            elseif self.SniperState == "CLOSE_COMBAT" and dist > 1000 then
                self.SniperState = "IDLE"
                self.Cfg.JumpChance = 0
                self.Cfg.DashChance = 0
                self.Cfg.KeepDistance = 800
                self.Cfg.NeverHold = false
                self.Cfg.WalkDistanceFrac = nil
                self.Cfg.ZigZagWidth = nil
                self.Cfg.WalkSpeed = 100
                self.Cfg.RunSpeed = 200
                self.Cfg.RushSpeed = 300
            end
        else
            if self.SniperState == "CLOSE_COMBAT" then
                self.SniperState = "IDLE"
                self.Cfg.KeepDistance = 800
                self.Cfg.NeverHold = false
                self.Cfg.WalkDistanceFrac = nil
                self.Cfg.ZigZagWidth = nil
                self.Cfg.WalkSpeed = 100
                self.Cfg.RunSpeed = 200
                self.Cfg.RushSpeed = 300
            end
        end

        -- Si está herido (<50%) y le acaban de disparar, se reposiciona
        if hpFrac < 0.5 and IsValid(self.PendingAttacker) and self.SniperState ~= "CLOSE_COMBAT" and self.SniperState ~= "REPOSITIONING" then
            self.SniperState = "REPOSITIONING"
        end

        local targetEnemy = enemy
        if self.SniperState == "IDLE" and IsValid(enemy) and dist > 600 then
            local dirToEnemy = (enemy:GetPos() - self:GetPos()):GetNormalized()
            local aimDir = Angle(0, self.ScanAngle, 0):Forward()
            -- dot > 0.85 es aprox un cono de visión del escáner
            if aimDir:Dot(dirToEnemy) > 0.85 and self:CanSee(enemy) then
                self.SniperState = "SNIPING"
                self.LastSeen = CurTime()
            else
                targetEnemy = nil
            end
        end

        if self.SniperState == "PATROL" then
            self:Patrol()
            self.SniperState = "IDLE"
            self.ScanAngle = self:GetAngles().y
            self.SniperBasePosAngle = self.ScanAngle
        elseif self.SniperState == "CLOSE_COMBAT" then
            if not self.NextRetarget or CurTime() > self.NextRetarget then
                self.NextRetarget = CurTime() + 4
            end
            self:ChaseAndFire()
        elseif self.SniperState == "REPOSITIONING" then
            self:RepositionTask()
        elseif IsValid(targetEnemy) then
            self.SniperState = "SNIPING"
            self:SnipeEnemy()
        else
            self.SniperState = "IDLE"
            self:SniperScan()
        end

        coroutine.yield()
    end
end

function ENT:SniperScan()
    self.loco:SetDesiredSpeed(0)
    
    if self:GetActivity() ~= ACT_HL2MP_IDLE_CROUCH_AR2 then
        self:PlayActivity(ACT_HL2MP_IDLE_CROUCH_AR2)
    end

    -- Velocidad de escaneo: 25 grados por segundo
    self.ScanAngle = self.ScanAngle + (25 * FrameTime() * self.ScanDirection)
    if math.abs(math.AngleDifference(self.ScanAngle, self.SniperBasePosAngle)) > 45 then
        self.ScanDirection = self.ScanDirection * -1
    end
end

function ENT:SnipeEnemy()
    self.loco:SetDesiredSpeed(0)
    
    if self:GetActivity() ~= ACT_HL2MP_IDLE_CROUCH_AR2 then
        self:PlayActivity(ACT_HL2MP_IDLE_CROUCH_AR2)
    end

    local enemyPos = self.Enemy:GetPos()
    local dist = self:GetPos():Distance(enemyPos)
    local visible = (dist <= self.Cfg.FireRange) and self:CanSee(self.Enemy)

    if visible then
        self.LastSeen = CurTime()
        self.loco:FaceTowards(enemyPos)

        -- Cálculo de precisión por "sweet spot"
        local dirToEnemy = (enemyPos - self:GetPos()):GetNormalized()
        local aimDir = Angle(0, self.ScanAngle, 0):Forward()
        -- Dot product: 1.0 es perfecto en el centro, < 0.8 está en los bordes
        local centerScore = aimDir:Dot(dirToEnemy)

        -- Actualizamos gradualmente el ángulo de escaneo para trackear al jugador
        local targetAng = dirToEnemy:Angle().y
        self.ScanAngle = math.ApproachAngle(self.ScanAngle, targetAng, 150 * FrameTime())

        if CurTime() > self.NextAttack then
            self:SniperRangedAttack(dist, centerScore)
        end
    else
        -- Si no lo ve, mantiene la posición (trackeando ciegamente) por 3 segundos
        if CurTime() - (self.LastSeen or 0) > 3 then
            self.SniperState = "IDLE"
            self.SniperBasePosAngle = self.ScanAngle -- Centra el nuevo rastrillaje donde lo vio por última vez
        end
    end

    local attackedRecently = self.PendingAttacker and (CurTime() - (self.LastAttackedTime or 0) < 2)

    -- Solo huye si lo hieren (ataque real)
    if attackedRecently then
        self.SniperState = "REPOSITIONING"
        self.PendingAttacker = nil
    end
end

function ENT:SniperRangedAttack(dist, centerScore)
    if not self.Cfg.NoExternalWeapon and not IsValid(self.WeaponProp) then return end
    local stats = self:GetTFAStats()
    if not stats then return end

    local spread = self:ComputeSpread(dist) * 1.5 -- Que falle un poco más
    
    -- Ajuste de mira a la cabeza o al pecho dependiendo de centerScore
    local targetBonePos = self.Enemy:GetPos() + Vector(0,0,40) -- default pecho/centro
    
    if centerScore > 0.98 then
        -- Tiro perfecto a la cabeza si está en el centro de la mira
        local headBone = self.Enemy:LookupBone("ValveBiped.Bip01_Head1")
        if headBone then
            local bp, ba = self.Enemy:GetBonePosition(headBone)
            if bp then targetBonePos = bp end
        else
            targetBonePos = self.Enemy:GetPos() + Vector(0,0,65) -- fallback head pos
        end
        spread = 0.001 -- Ultra preciso
    elseif centerScore > 0.8 then
        -- Tiro al pecho
        spread = 0.005
    else
        -- Tiro impreciso a las extremidades o falla
        spread = 0.02
        targetBonePos = targetBonePos + Vector(math.random(-20,20), math.random(-20,20), math.random(-20,20))
    end

    local origin = self.WeaponProp:GetPos() + self:GetForward() * 10 + self:GetUp() * 5
    local baseDir = (targetBonePos - origin):GetNormalized()
    local ang = baseDir:Angle()
    ang:RotateAroundAxis(ang:Up(), math.Rand(-1, 1) * spread * 45)
    ang:RotateAroundAxis(ang:Right(), math.Rand(-1, 1) * spread * 45)
    local dir = ang:Forward()

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
            -- Para snipers, multiplicamos el daño del proyectil si es posible
            if laser.Damage then laser.Damage = laser.Damage * self.Cfg.DamageMult end
        end
    else
        local bullet = {
            Num        = 1,
            Src        = origin,
            Dir        = dir,
            Spread     = Vector(0,0,0),
            Tracer     = 1,
            TracerName = stats.Tracer,
            Force      = 5,
            Damage     = stats.Damage * self.Cfg.DamageMult,
            IgnoreEntity = self,
            Attacker   = self,
        }
        
        local fireEnt = self.Cfg.NoExternalWeapon and self or self.WeaponProp
        fireEnt:FireBullets(bullet)
    end
    
    if self.Cfg.SoundWeapon then
        sound.Play(self.Cfg.SoundWeapon, origin, 85, math.random(95, 105), 1)
    elseif isstring(stats.Sound) then
        sound.Play(stats.Sound, origin, 85, math.random(95, 105), 1)
    elseif istable(stats.Sound) and #stats.Sound > 0 then
        sound.Play(stats.Sound[math.random(#stats.Sound)], origin, 85, math.random(95, 105), 1)
    end

    self:AlertAllies(self.Enemy)
    self.NextAttack = CurTime() + stats.Delay * self.Cfg.FireRateMult
end

function ENT:RepositionTask()
    -- Se levanta (animación de correr)
    self:PlayActivity(ACT_HL2MP_RUN_SHOTGUN, self.Cfg.CustomSequenceRun)
    self.loco:SetDesiredSpeed(self.Cfg.RunSpeed)
    
    -- Busca un lugar alejado del enemigo (pero con línea de visión si es posible)
    local enemyPos = IsValid(self.Enemy) and self.Enemy:GetPos() or self:GetPos()
    local hideDir = (self:GetPos() - enemyPos):GetNormalized()
    
    -- Se mueve hacia atrás unos 1000 units
    local targetPos = self:GetPos() + hideDir * 1000 + Vector(math.random(-300, 300), math.random(-300, 300), 0)
    
    local path = Path("Follow")
    path:SetMinLookAheadDistance(300)
    path:SetGoalTolerance(50)
    path:Compute(self, targetPos)
    
    local maxMoveTime = CurTime() + 4 -- Máximo 4 segundos corriendo para reposicionarse
    while path:IsValid() and self:GetPos():Distance(targetPos) > 50 do
        if CurTime() > maxMoveTime then break end
        
        -- Si de repente el enemigo se nos pega a menos de 600, abortar y entrar en combate cercano
        if IsValid(self.Enemy) and self:GetPos():Distance(self.Enemy:GetPos()) < 600 then
            self.SniperState = "CLOSE_COMBAT"
            return
        end

        self:PlayActivity(ACT_HL2MP_RUN_SHOTGUN, self.Cfg.CustomSequenceRun)
        path:Update(self)
        if self.loco:IsStuck() then
            self.loco:ClearStuck()
            break
        end
        coroutine.yield()
    end
    
    -- Llegó al lugar, vuelve a modo sniper mirando hacia el enemigo
    local lookDir = (enemyPos - self:GetPos()):GetNormalized()
    
    -- Girar el cuerpo para mirar hacia el enemigo ANTES de tirarse al suelo
    local faceWait = CurTime() + 0.5
    while CurTime() < faceWait do
        self.loco:FaceTowards(enemyPos)
        coroutine.yield()
    end

    self.SniperBasePosAngle = lookDir:Angle().y
    self.ScanAngle = self.SniperBasePosAngle
    
    self.SniperState = "IDLE"
    self.PendingAttacker = nil -- Limpia el atacante
end

function ENT:BodyUpdate()
    self.BaseClass.BodyUpdate(self)
    
    if self.SniperState == "IDLE" then
        -- Mover solo la cabeza/mira sin girar el cuerpo completo
        local curYaw = self:GetAngles().y
        local diff = math.NormalizeAngle(self.ScanAngle - curYaw)
        
        self:SetPoseParameter("head_yaw", diff)
        self:SetPoseParameter("aim_yaw", diff)
        self:SetPoseParameter("body_yaw", diff)
    end
end

function ENT:OnInjured(info)
    self.BaseClass.OnInjured(self, info)
    local attacker = info:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() then
        self.PendingAttacker = attacker
        self.LastAttackedTime = CurTime()
    end
end

function ENT:KiteEnemy()
    -- Cuando el jugador está muy cerca, corre hacia atrás mirándolo y disparando (agilidad extrema)
    self:PlayActivity(ACT_HL2MP_RUN_AR2)
    self.loco:SetDesiredSpeed(self.Cfg.RunSpeed * 1.2)
    
    local enemy = self.Enemy
    if not IsValid(enemy) then return end
    
    local dist = self:GetPos():Distance(enemy:GetPos())
    
    -- Calcula hacia donde correr (lejos del jugador)
    local hideDir = (self:GetPos() - enemy:GetPos()):GetNormalized()
    local targetPos = self:GetPos() + hideDir * 1000 + Vector(math.random(-300, 300), math.random(-300, 300), 0)
    
    local path = Path("Follow")
    path:SetMinLookAheadDistance(300)
    path:SetGoalTolerance(20)
    path:Compute(self, targetPos)
    
    local endTime = CurTime() + math.Rand(2, 4)
    while path:IsValid() and CurTime() < endTime and IsValid(self.Enemy) do
        -- Mantener la mira en el jugador mientras retrocede
        self.loco:FaceTowards(self.Enemy:GetPos())
        
        path:Update(self)
        if self.loco:IsStuck() then
            self.loco:ClearStuck()
            self.loco:Jump()
        end
        
        -- Disparos rápidos a quemarropa sin precisión perfecta de sniper
        if CurTime() > self.NextAttack then
            local stats = self:GetTFAStats()
            if stats then
                self:SniperRangedAttack(dist, 0.7) -- centerScore bajo para que use el esparcimiento (spread)
                self.NextAttack = CurTime() + stats.Delay * 0.5 -- Dispara más rápido en desesperación
            end
        end
        
        -- Probabilidades de esquive
        if math.random() < 0.05 and self.loco:IsOnGround() then
            self.loco:Jump()
        end
        
        coroutine.yield()
    end
end
