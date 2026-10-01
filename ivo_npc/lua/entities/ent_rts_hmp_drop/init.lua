AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/salty/cis-hmp-gunship.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    
    self:SetMaxHealth(2000)
    self:SetHealth(2000)
    
    self.State = 0
    self.DropCount = 0
    
    local hoffset = 250
    if self.PayloadClass == "lvs_fakehover_aat" then
        hoffset = 150
    end
    
    self.StartPos = self:GetPos() + Vector(0, 0, 3000)
    self.TargetPos = self:GetPos() + Vector(0, 0, hoffset)
    
    self:SetPos(self.StartPos)
    self.StartTime = CurTime()
    self.DescendDuration = 4
    
    self:SetETA(self.StartTime + self.DescendDuration)
    if self.PayloadClass then self:SetPayloadClass(self.PayloadClass) end
    
    self.EngineSound = CreateSound(self, "hmp/hmp_gunship_engineidleing.wav")
    self.EngineSound:SetSoundLevel(100)
    self.EngineSound:Play()
    
    self.PayloadTable = self.PayloadTable or {}
    if #self.PayloadTable == 0 and self.PayloadClass then
        -- Retrocompatibility
        local ct = self.PayloadCount or 10
        for i=1, ct do
            table.insert(self.PayloadTable, self.PayloadClass)
        end
    end
    self.MaxDrops = #self.PayloadTable
end

function ENT:OnRemove()
    if self.EngineSound then self.EngineSound:Stop() end
    
    -- Refund population if destroyed before dropping
    if not self.HasDropped and IsValid(self.CommanderOwner) then
        local cost = self.PayloadCost or 0
        local count = self.PayloadCount or 1
        local popCost = cost * count
        
        self.CommanderOwner.IVOPopulation = (self.CommanderOwner.IVOPopulation or 0) - popCost
        self.CommanderOwner:SetNWInt("IVO_RTSPop", self.CommanderOwner.IVOPopulation)
        self.CommanderOwner:ChatPrint("¡Despliegue interceptado! Se ha liberado la población ocupada.")
    end
end

function ENT:OnTakeDamage(dmginfo)
    if self:Health() <= 0 then return end
    
    self:SetHealth(self:Health() - dmginfo:GetDamage())
    if self:Health() <= 0 then
        -- Cancel deployment
        self.HasDropped = true 
        
        local ed = EffectData()
        ed:SetOrigin(self:GetPos())
        util.Effect("Explosion", ed)
        
        local ed2 = EffectData()
        ed2:SetOrigin(self:GetPos())
        ed2:SetScale(2)
        ed2:SetMagnitude(2)
        util.Effect("HelicopterMegaBomb", ed2)
        
        self:EmitSound("ambient/explosions/explode_9.wav", 100, 80)
        
        -- Distribute money to attacker if applicable
        local attacker = dmginfo:GetAttacker()
        if IsValid(attacker) and attacker:IsPlayer() and attacker ~= self.CommanderOwner then
            if attacker.addMoney then
                local reward = 1000
                attacker:addMoney(reward)
                if DarkRP and DarkRP.notify then
                    DarkRP.notify(attacker, 0, 4, "Has recibido $" .. reward .. " por interceptar una cañonera.")
                end
            end
        end
        
        self:Remove()
    end
end

function ENT:Think()
    local ct = CurTime()
    
    if self.State == 0 then
        -- Descending
        local progress = math.Clamp((ct - self.StartTime) / self.DescendDuration, 0, 1)
        local ease = 1 - math.pow(1 - progress, 3)
        self:SetPos(LerpVector(ease, self.StartPos, self.TargetPos))
        
        if progress >= 1 then
            self.State = 1
            self.NextDrop = ct + 0.5
        end
    elseif self.State == 1 then
        -- Dropping all at once
        if ct > self.NextDrop and not self.HasDropped then
            self.HasDropped = true
            
            for i = 1, self.MaxDrops do
                self:DropPayload(i)
            end
            
            self.State = 2
            self.AscendStart = ct + 1.5
            self.StartPos = self:GetPos()
            self.TargetPos = self.StartPos + (self:GetForward() * 5000) + Vector(0, 0, 3000)
            self.AscendDuration = 5
        end
    elseif self.State == 2 then
        if ct > self.AscendStart then
            self.State = 3
            self.StartTime = ct
            self.StartAngle = self:GetAngles()
            self.TargetAngle = Angle(-20, self:GetAngles().y, 0)
            self:EmitSound("hmp/throttlepunch_6.mp3", 110, 100)
        end
    elseif self.State == 3 then
        local progress = math.Clamp((ct - self.StartTime) / self.AscendDuration, 0, 1)
        local ease = progress * progress
        self:SetPos(LerpVector(ease, self.StartPos, self.TargetPos))
        
        local angleEase = math.min(progress * 2, 1)
        self:SetAngles(LerpAngle(angleEase, self.StartAngle, self.TargetAngle))
        
        if progress >= 1 then
            self:Remove()
        end
    end
    
    self:NextThink(ct)
    return true
end

function ENT:DropPayload(index)
    local pclass = self.PayloadTable[index] or self.PayloadClass or "npc_droid_b1"
    local ent = ents.Create(pclass)
    if not IsValid(ent) then return end
    
    local dropPos = self:GetPos() - Vector(0, 0, 150)
    
    if pclass == "lvs_fakehover_aat" then
        -- AAT drops in the center
        dropPos = self:GetPos() - Vector(0, 0, 100)
    else
        -- B1s drop in formation
        local row = math.ceil(index / 2)
        local isRight = (index % 2 == 0)
        local fwdOffset = 30 - (row * 50)
        local rightOffset = isRight and 100 or -100
        dropPos = self:GetPos() + (self:GetForward() * fwdOffset) + (self:GetRight() * rightOffset) - Vector(0, 0, 150)
    end
    
    ent:SetPos(dropPos)
    ent:SetAngles(Angle(0, self:GetAngles().y, 0))
    ent:Spawn()
    ent:Activate()
    
    if ent.SetAI then ent:SetAI(true) end
    
    if IsValid(self.CommanderOwner) then
        ent:SetNWEntity("CommanderOwner", self.CommanderOwner)
        ent.CommanderOwnerRaw = self.CommanderOwner
        ent.Cost = (IVO_RTS and IVO_RTS.Config and IVO_RTS.Config.UnitCostsGMP and IVO_RTS.Config.UnitCostsGMP[pclass]) or 1
        ent.IsRTSUnit = true
        
        if ent.SetAITEAM then
            ent:SetAITEAM(1)
        end
        
        -- Inject AAT logic if it's the AAT
        if pclass == "lvs_fakehover_aat" and IVO_RTS and IVO_RTS.InjectAAT_AI then
            IVO_RTS.InjectAAT_AI(ent)
        end
    end
end
