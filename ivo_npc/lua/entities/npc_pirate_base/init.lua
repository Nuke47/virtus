AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:SetupConfig()
    -- Start with default droid config
    local cfg = self:GetDefaultConfig()
    
    -- Merge pirate defaults
    if self.GetDefaultPirateConfig then
        table.Merge(cfg, self:GetDefaultPirateConfig())
    end
    
    -- Merge specific pirate config
    if istable(self.PirateConfig) then
        table.Merge(cfg, self.PirateConfig)
    end
    
    -- Maintain compatibility with DroidConfig name if it expects it internally
    self.Cfg = cfg
end

local humanVoicesCombat = {
    "vo/npc/male01/gethellout.wav",
    "vo/npc/male01/overhere01.wav",
    "vo/npc/male01/watchout.wav",
    "vo/npc/male01/hax01.wav"
}
local humanVoicesPassive = {
    "vo/npc/male01/hi01.wav",
    "vo/npc/male01/hi02.wav",
    "vo/npc/male01/gordead_ans01.wav"
}

function ENT:PlayVoiceLine(isCombat)
    if CurTime() < (self.NextVoiceTime or 0) then return end
    
    local list = isCombat and humanVoicesCombat or humanVoicesPassive
    if list and #list > 0 then
        local snd = list[math.random(#list)]
        self:EmitSound(snd, 80, math.random(95, 105))
        self.NextVoiceTime = CurTime() + math.random(8, 16)
    end
end

function ENT:PlayFootstep(isSprint)
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
    
    local snd = string.format("player/footsteps/%s%d.wav", matName, math.random(1, 4))
    self:EmitSound(snd, 70, math.random(95, 105), 0.4)
end

function ENT:OnKilled(dmginfo)
    self:EmitSound("vo/npc/male01/pain0" .. math.random(1,9) .. ".wav", 85, math.random(95, 105))

    local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() then
        if attacker.addMoney then
            local mult = (IVO_RTS and IVO_RTS.Config and IVO_RTS.Config.DarkRPRewardMultiplier) or 50
            local reward = self.Cost and (self.Cost * mult) or 50
            attacker:addMoney(reward)
        end
    end
    
    if IsValid(self.WeaponProp) then
        self.WeaponProp:Remove()
    end
    if IsValid(self.ShieldProp) then
        self.ShieldProp:Remove()
    end

    self:BecomeRagdoll(dmginfo)
end
