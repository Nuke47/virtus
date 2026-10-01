AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/b1/pm_droid_cis_b1.mdl")
    self:SetHealth(100)
    
    self:SetCollisionGroup(COLLISION_GROUP_NPC)
    self:SetSolid(SOLID_BBOX)
    
    self.Enemy = nil
    self.NextAttack = 0
    
    -- Invocamos la función para equipar tu modelo específico de Kuro
    self:EquiparArmaPersonalizada()
end

-- Función que pone el modelo de Kuro en la mano del droide
function ENT:EquiparArmaPersonalizada()
    self.WeaponProp = ents.Create("prop_dynamic")
    self.WeaponProp:SetModel("models/kuro/sw_battlefront/weapons/e5_blaster.mdl")
    self.WeaponProp:SetPos(self:GetPos())
    self.WeaponProp:Spawn()
    
    self.WeaponProp:SetSolid(SOLID_NONE)
    
    -- Buscamos el ID del punto de fijación o el hueso de la mano
    local attachID = self:LookupAttachment("anim_attachment_RH")
    local boneID = self:LookupBone("ValveBiped.Bip01_R_Hand")
    
    if attachID > 0 then
        -- Lo pegamos nativamente al attachment. Esto SÍ permite usar Offsets.
        self.WeaponProp:SetParent(self, attachID)
    elseif boneID then
        -- Plan B: Si no tiene attachment, lo pegamos directo al hueso
        self.WeaponProp:SetParent(self)
        self.WeaponProp:FollowBone(self, boneID)
    else
        -- Plan C (Emergencia): Vuelve al método original si el modelo es raro
        self.WeaponProp:SetParent(self)
        self.WeaponProp:Fire("setparentattachment", "anim_attachment_RH")
    end
    
    -- Ajusta el Vector (Adelante/Atrás, Derecha/Izquierda, Arriba/Abajo)
    self.WeaponProp:SetLocalPos(Vector(2, -1, -2))
    
    -- Ajusta el Ángulo (Inclinación Arriba/Abajo, Giro Derecha/Izquierda, Rotación de cañón)
    self.WeaponProp:SetLocalAngles(Angle(0, 0, 0))
end

-- Función para extraer las estadísticas reales del arma TFA
function ENT:ObtenerDatosTFA(clase_arma)
    local datos = weapons.GetStored(clase_arma)
    if not datos then return nil end

    return {
        Danio = datos.Primary.Damage or 20,
        Sonido = datos.Primary.Sound or "Weapon_AR2.Single",
        Cadencia = datos.Primary.Delay or 0.3,
        Proyectil = datos.Primary.Projectile,
        Trazadora = datos.TracerName or "AR2Tracer"
    }
end

function ENT:BuscarEnemigo()
    local jugadores = player.GetAll()
    local objetivoMasCercano = nil
    local distanciaMinima = 3000 * 3000 

    for _, p in ipairs(jugadores) do
        -- Ignora a los jugadores muertos o que tengan el notarget activado
        if p:Alive() and not p:IsFlagSet(FL_NOTARGET) then
            local tr = util.TraceLine({
                start = self:GetPos() + Vector(0,0,50),
                endpos = p:GetPos() + Vector(0,0,50),
                filter = self
            })

            if tr.Entity == p then
                local dist = self:GetPos():DistToSqr(p:GetPos())
                if dist < distanciaMinima then
                    distanciaMinima = dist
                    objetivoMasCercano = p
                end
            end
        end
    end

    return objetivoMasCercano
end

function ENT:RunBehaviour()
    while (true) do
        -- Si no hay enemigo, está muerto, o se puso en notarget, buscamos otro
        if not IsValid(self.Enemy) or not self.Enemy:Alive() or self.Enemy:IsFlagSet(FL_NOTARGET) then
            self.Enemy = self:BuscarEnemigo()
            
            if not IsValid(self.Enemy) then
                self:StartActivity(ACT_HL2MP_WALK_SHOTGUN)
                self.loco:SetDesiredSpeed(100)
                self:MoveToPos(self:GetPos() + Vector(math.random(-300, 300), math.random(-300, 300), 0))
                self:StartActivity(ACT_HL2MP_IDLE_SHOTGUN)
                coroutine.wait(2)
            end
        else
            self:PerseguirYDisparar()
        end
        
        coroutine.yield()
    end
end

function ENT:PerseguirYDisparar()
    local path = Path("Follow")
    path:SetMinLookAheadDistance(300)
    path:SetGoalTolerance(20)
    path:Compute(self, self.Enemy:GetPos())
    
    if not path:IsValid() then return end
    
    -- Interrumpe la persecución si el objetivo se activa el notarget
    while path:IsValid() and IsValid(self.Enemy) and self.Enemy:Alive() and not self.Enemy:IsFlagSet(FL_NOTARGET) do
        if path:GetAge() > 0.2 then
            path:Compute(self, self.Enemy:GetPos())
        end
        
        path:Update(self)
        
        if self.loco:IsStuck() then
            self.loco:ClearStuck()
            return
        end
        
        -- Rango de disparo
        if self:GetPos():DistToSqr(self.Enemy:GetPos()) < (1200 * 1200) then
            local tr = util.TraceLine({
                start = self:GetPos() + Vector(0,0,50),
                endpos = self.Enemy:GetPos() + Vector(0,0,50),
                filter = self
            })

            if tr.Entity == self.Enemy then
                self.UltimaVezVisto = CurTime()

                -- Fuerza al droide a mirar al jugador
                self.loco:FaceTowards(self.Enemy:GetPos()) 
                
                -- Llama al ataque y sigue caminando
                self:AtacarADistancia()
            end
        end

        -- Si está disparando, camina más lento y adopta pose de escopeta. Si no, corre.
        -- Usamos un suavizador (0.5 seg) para que no cambie de animación de golpe si la visión parpadea
        if self.UltimaVezVisto and (CurTime() - self.UltimaVezVisto < 0.5) then
            if self:GetActivity() ~= ACT_HL2MP_WALK_SHOTGUN then
                self:StartActivity(ACT_HL2MP_WALK_SHOTGUN)
            end
            self.loco:SetDesiredSpeed(80) -- Velocidad reducida al disparar
        else
            if self:GetActivity() ~= ACT_HL2MP_RUN_SHOTGUN then
                self:StartActivity(ACT_HL2MP_RUN_SHOTGUN)
            end
            self.loco:SetDesiredSpeed(180) -- Velocidad al correr
        end
        
        coroutine.yield()
    end
end

function ENT:AtacarADistancia()
    if CurTime() > self.NextAttack and IsValid(self.Enemy) and self.Enemy:Alive() and not self.Enemy:IsFlagSet(FL_NOTARGET) then
        
        -- Si por alguna razón el arma no existe, cancelamos el disparo
        if not IsValid(self.WeaponProp) then return end

        -- Reducimos el multiplicador de GetForward() de 25 a 10 para que el disparo salga más atrás.
        -- Si sigue estando muy adelante, puedes bajarlo a 5, o incluso a 0.
        local origenDisparo = self.WeaponProp:GetPos() + self:GetForward() * 10 + self:GetUp() * 5

        local direccion = (self.Enemy:GetPos() + Vector(0,0,40) - origenDisparo):GetNormalized()
        
        local statsArma = self:ObtenerDatosTFA("tfa_sw_blaster_e5_upgrade")
        if not statsArma then return end 

        if statsArma.Proyectil and statsArma.Proyectil ~= "" then
            local laser = ents.Create(statsArma.Proyectil)
            if IsValid(laser) then
                laser:SetPos(origenDisparo)
                laser:SetAngles(direccion:Angle())
                laser:SetOwner(self)
                laser:Spawn()
                laser:Activate()
                
                local phys = laser:GetPhysicsObject()
                if IsValid(phys) then
                    phys:SetVelocity(direccion * 3000)
                end
            end
        else
            local bullet = {}
            bullet.Num = 1
            bullet.Src = origenDisparo
            bullet.Dir = direccion
            bullet.Spread = Vector(0.04, 0.04, 0)
            bullet.Tracer = 1
            bullet.TracerName = statsArma.Trazadora
            bullet.Force = 2
            bullet.Damage = statsArma.Danio
            bullet.Attacker = self -- El droide sigue siendo el responsable del daño

            -- LA MAGIA ESTÁ AQUÍ:
            -- Hacemos que la entidad del prop dispare, no el droide (`self`).
            self.WeaponProp:FireBullets(bullet)
        end
        
        -- Emitimos el sonido desde el arma también
        if type(statsArma.Sonido) == "string" then
            self.WeaponProp:EmitSound(statsArma.Sonido, 85, 100, 1, CHAN_WEAPON)
        elseif type(statsArma.Sonido) == "table" then
            self.WeaponProp:EmitSound(statsArma.Sonido[math.random(1, #statsArma.Sonido)], 85, 100, 1, CHAN_WEAPON)
        end
        
        self.NextAttack = CurTime() + statsArma.Cadencia 
    end
end

function ENT:BodyUpdate()
    -- Forzamos a calcular la dirección de las piernas en cualquier estado
    self:BodyMoveXY()
    
    -- Actualizamos la rotación de los brazos y cabeza hacia el enemigo
    if IsValid(self.Enemy) then
        -- Calculamos el ángulo desde el pecho del droide hacia el enemigo
        local direccion = (self.Enemy:GetPos() + Vector(0, 0, 40)) - (self:GetPos() + Vector(0, 0, 50))
        local anguloObjetivo = direccion:Angle()
        local anguloActual = self:GetAngles()
        
        -- Obtenemos la diferencia y la normalizamos para no romper los brazos del modelo
        local pitch = math.NormalizeAngle(anguloObjetivo.p - anguloActual.p)
        local yaw = math.NormalizeAngle(anguloObjetivo.y - anguloActual.y)
        
        self:SetPoseParameter("aim_pitch", pitch)
        self:SetPoseParameter("aim_yaw", yaw)
        self:SetPoseParameter("head_pitch", pitch)
        self:SetPoseParameter("head_yaw", yaw)
        
        -- Agregamos los parámetros más comunes para doblar la espalda y el torso
        self:SetPoseParameter("body_pitch", pitch)
        self:SetPoseParameter("body_yaw", yaw)
        self:SetPoseParameter("spine_pitch", pitch)
        self:SetPoseParameter("spine_yaw", yaw)
    else
        -- Restablece la pose si no está apuntando a nadie
        self:SetPoseParameter("aim_pitch", 0)
        self:SetPoseParameter("aim_yaw", 0)
        self:SetPoseParameter("head_pitch", 0)
        self:SetPoseParameter("head_yaw", 0)
        
        self:SetPoseParameter("body_pitch", 0)
        self:SetPoseParameter("body_yaw", 0)
        self:SetPoseParameter("spine_pitch", 0)
        self:SetPoseParameter("spine_yaw", 0)
    end
    
    -- Obligamos a la animación a reproducirse a velocidad normal (evita que se congele)
    self:SetPlaybackRate(1)

    self:FrameAdvance()
end

function ENT:OnRemove()
    if IsValid(self.WeaponProp) then
        self.WeaponProp:Remove()
    end
end