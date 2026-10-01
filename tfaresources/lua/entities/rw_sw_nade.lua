AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Spawnable = false

function ENT:Draw()
    self:DrawModel()
end


function ENT:Initialize()
    self.Entity:SetNWBool("smoke", 10, true)
    if SERVER then
        self:SetModel( "models/weapons/tfa_starwars/w_thermal.mdl" )
        self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if (IsValid(phys)) then
        phys:SetMass(1)
    end
        self:DrawShadow( true )
    end
    self.ExplodeTimer = CurTime() + 100000
    if CLIENT then
        self.emitter = ParticleEmitter( self:GetPos() , 0 )
    end
end

function ENT:PhysicsCollide( data, phys )
    if  (20 < data.Speed and 0.25 < data.DeltaTime) then
    self.ExplodeTimer = 0
    end
end

function ENT:Think()
    if SERVER and (self.ExplodeTimer and self.ExplodeTimer <= CurTime()) then
        self:Explode()
    end
    self:NextThink(CurTime())

    if CLIENT then
        local pos = self:GetPos() + self:GetForward()
        local emitter = ParticleEmitter( self:GetPos() , 0 )
        local particle = emitter:Add("particle/smokesprites_000"..math.random(1,9), pos )
        for i=1, (1) do
            if (particle) then
                particle:SetVelocity((self:GetForward() * -400)+(VectorRand()* 10) )
                particle:SetDieTime( math.Rand( 0.5, 1.5 ) )
                particle:SetStartAlpha( math.Rand( 75, 50 ) )
                particle:SetEndAlpha( 0 )
                particle:SetStartSize( math.Rand( 20, 20 ) )
                particle:SetEndSize( math.Rand( 15, 15 ) )
                particle:SetRoll( math.Rand(0, 360) )
                particle:SetRollDelta( math.Rand(-1, 1) )
                particle:SetColor( 120 , 120 , 120 ) 
                particle:SetAirResistance( 2500 ) 
                particle:SetGravity( Vector( 0, 0, 0 ) )
            end
        end
    end
    return true
end


function ENT:Think2()
end

function ENT:Explode()
	local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )
    util.Effect("Explosion", effectdata)
    util.BlastDamage( self, self.Owner, self:GetPos(), 300, 200 )
    
    local spos = self:GetPos()
    local trs = util.TraceLine({start=spos + Vector(0,0,64), endpos=spos + Vector(0,0,-32), filter=self})
    util.Decal("Scorch", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal)
    self:Remove()
end

function ENT:OnRemove()
end
