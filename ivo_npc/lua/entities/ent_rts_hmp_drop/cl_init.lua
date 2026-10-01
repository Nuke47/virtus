include("shared.lua")

local matCircle = Material("sgm/playercircle")

local function DrawCircleProgress(x, y, radius, progress, color)
    local poly = {}
    table.insert(poly, { x = x, y = y })
    
    -- Start from top (-90 degrees) and go clockwise
    local segments = 60
    local targetSegs = math.max(1, math.floor(segments * progress))
    
    for i = 0, targetSegs do
        local a = math.rad(-90 + (i / segments) * 360)
        table.insert(poly, { x = x + math.cos(a) * radius, y = y + math.sin(a) * radius })
    end
    
    surface.SetDrawColor(color)
    draw.NoTexture()
    surface.DrawPoly(poly)
end

function ENT:Draw()
    self:DrawModel()
    
    local targetPos = self:GetPos()
    targetPos.z = targetPos.z - 400 -- Approximation of ground
    
    -- Try to find the actual ground
    local tr = util.TraceLine({
        start = self:GetPos(),
        endpos = self:GetPos() - Vector(0, 0, 5000),
        filter = self
    })
    
    if tr.Hit then targetPos = tr.HitPos end
    
    local eta = self:GetETA()
    local ct = CurTime()
    
    if eta > 0 and eta > ct then
        if not LocalPlayer():GetNWBool("IVO_RTSMode", false) then return end

        local timeleft = eta - ct
        local progress = 1 - (timeleft / 4) -- Assumes 4 second drop time
        progress = math.Clamp(progress, 0, 1)
        
        local color = Color(255, 50, 50, 80)
        local isAAT = (self:GetPayloadClass() == "lvs_fakehover_aat")
        if isAAT then color = Color(50, 150, 255, 80) end
        
        -- Draw the 3D2D surface
        cam.Start3D2D(targetPos + Vector(0,0,5), Angle(0,0,0), 1)
            -- Background circle
            surface.SetDrawColor(color.r, color.g, color.b, 20)
            draw.NoTexture()
            DrawCircleProgress(0, 0, 600, 1, Color(color.r, color.g, color.b, 30))
            
            -- Progress wipe
            DrawCircleProgress(0, 0, 600, progress, color)
            
            -- Text
            draw.SimpleText("ZONA DE ATERRIZAJE HMP", "TargetID", 0, -30, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("T-" .. math.Round(timeleft, 1) .. "s", "TargetID", 0, 30, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end


function ENT:Initialize()
    self.Emitter = ParticleEmitter(self:GetPos())
end

function ENT:OnRemove()
    if IsValid(self.Emitter) then
        self.Emitter:Finish()
    end
end

function ENT:Think()
    -- Only emit dust if we are relatively close to the ground
    local tr = util.TraceLine({
        start = self:GetPos(),
        endpos = self:GetPos() - Vector(0, 0, 1500),
        filter = self
    })

    if tr.Hit and IsValid(self.Emitter) then
        -- The closer to the ground, the more intense the dust
        local dist = self:GetPos():Distance(tr.HitPos)
        local intensity = math.Clamp(1 - (dist / 1500), 0.1, 1)
        
        local particlesToSpawn = math.floor(3 * intensity)
        if math.random() < (3 * intensity) - particlesToSpawn then
            particlesToSpawn = particlesToSpawn + 1
        end

        for i = 1, particlesToSpawn do
            local angle = math.random(0, 360)
            local rad = math.rad(angle)
            local dir = Vector(math.cos(rad), math.sin(rad), 0)
            
            -- Spawn particle slightly off the ground
            local p = self.Emitter:Add("particle/smokesprites_000" .. math.random(1,9), tr.HitPos + dir * math.random(50, 200) + Vector(0,0,10))
            if p then
                p:SetVelocity(dir * math.random(400, 800) * intensity + Vector(0,0,math.random(20, 80)))
                p:SetDieTime(math.Rand(1.5, 3))
                p:SetStartAlpha(math.random(30, 60) * intensity)
                p:SetEndAlpha(0)
                p:SetStartSize(math.random(80, 150))
                p:SetEndSize(math.random(200, 400))
                p:SetRoll(math.Rand(0, 360))
                p:SetRollDelta(math.Rand(-1, 1))
                p:SetColor(130, 120, 110) -- Dust/dirt color
                p:SetAirResistance(100)
            end
        end
    end
    
    self:SetNextClientThink(CurTime() + 0.05)
    return true
end

