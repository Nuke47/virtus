-- virtustfa/lua/weapons/tfa_sw_gun_base.lua

SWEP.Base = "tfa_gun_base"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false

DEFINE_BASECLASS( SWEP.Base )

-- =================================================================
-- SISTEMA DE ENFRIAMIENTO TIPO BATTLEFRONT II
-- =================================================================

SWEP.CoolingDuration = 1.5       
SWEP.SweetSpotStart = 0.40       
SWEP.SweetSpotEnd = 0.55         
SWEP.PenaltyTime = 2.5
SWEP.AutoCoolDelay = 0.8 
SWEP.AutoCoolRate = 0.1 

function SWEP:Initialize(...)
    if not self:IsSWSpecialWeapon() then
        if self.Slot == 1 then
            self.Primary.Ammo = "pistol"
        else
            self.Primary.Ammo = "ar2"
        end
    end
    self.Primary.DefaultClip = 0
    
    self:SetNW2Float("BF2_LastShotTime", 0)
    self:SetNW2Float("BF2_NextAutoCoolTime", 0)
    self:SetNW2Bool("BF2_IsCooling", false)
    self:SetNW2Float("BF2_CoolStartTime", 0)
    self:SetNW2Bool("BF2_HasClicked", false)
    self:SetNW2Bool("IsCellReloading", false)
    return BaseClass.Initialize(self, ...)
end

function SWEP:GetCellStatusKey()
    return (self.Slot == 1) and "CellStatus_Secondary" or "CellStatus_Primary"
end

function SWEP:GetCellStatus()
    local ply = self:GetOwner()
    if IsValid(ply) then
        local key = self:GetCellStatusKey()
        local status = ply:GetNW2Int(key, -1)
        if status == -1 then
            ply:SetNW2Int(key, 100)
            return 100
        end
        return status
    end
    return 100
end

function SWEP:DecreaseCellStatus(amt)
    if SERVER or IsFirstTimePredicted() then
        local ply = self:GetOwner()
        if not IsValid(ply) then return end
        
        local current = self:GetCellStatus()
        current = math.max(0, current - amt)
        ply:SetNW2Int(self:GetCellStatusKey(), current)
        
        if current <= 0 then
            self:SetClip1(0) -- Obligar recarga
        end
    end
end

function SWEP:Equip(...)
    local ply = self:GetOwner()
    if IsValid(ply) and self:GetPrimaryAmmoType() ~= -1 then
        timer.Simple(0.1, function()
            if IsValid(self) and IsValid(ply) then
                local cell = self:GetCellStatus()
                if cell <= 0 then
                    self:SetClip1(0)
                else
                    self:SetClip1(self:GetMaxClip1() > 0 and self:GetMaxClip1() or 50)
                end
                
                if not self:IsSWSpecialWeapon() then
                    local ammoType = self:GetPrimaryAmmoType()
                    if ply:GetAmmoCount(ammoType) <= 0 then
                        local isSec = (self.Slot == 1)
                        local maxCells = isSec and 1 or 2
                        local clipSize = self:GetMaxClip1() > 0 and self:GetMaxClip1() or 50
                        ply:SetAmmo(maxCells * clipSize, ammoType)
                    end
                end
            end
        end)
    end
    return BaseClass.Equip(self, ...)
end

if SERVER then
    hook.Add("PlayerDeath", "SaveSWCells", function(ply)
        ply.SavedCellData = {
            primary = ply:GetNW2Int("CellStatus_Primary", 100),
            secondary = ply:GetNW2Int("CellStatus_Secondary", 100),
            pos = ply:GetPos()
        }
        
        ply.SavedAmmoData = {}
        for k, v in pairs(ply:GetWeapons()) do
            local ammoType = v:GetPrimaryAmmoType()
            if ammoType and ammoType ~= -1 then
                ply.SavedAmmoData[ammoType] = ply:GetAmmoCount(ammoType)
            end
        end
    end)

    hook.Add("PlayerSpawn", "RestoreSWCells", function(ply)
        timer.Simple(0.3, function()
            if not IsValid(ply) or not ply:Alive() then return end
            
            local wasRevived = ply.SW_IsBeingRevived
            
            if wasRevived then
                if ply.SavedCellData then
                    ply:SetNW2Int("CellStatus_Primary", ply.SavedCellData.primary or 100)
                    ply:SetNW2Int("CellStatus_Secondary", ply.SavedCellData.secondary or 100)
                end
                
                if ply.SavedAmmoData then
                    for ammoType, count in pairs(ply.SavedAmmoData) do
                        ply:SetAmmo(count, ammoType)
                    end
                end
            else
                ply:SetNW2Int("CellStatus_Primary", 100)
                ply:SetNW2Int("CellStatus_Secondary", 100)
            end
        end)
        
        timer.Simple(1.5, function()
            if not IsValid(ply) or not ply:Alive() then return end
            
            local wasRevived = ply.SW_IsBeingRevived
            
            if not wasRevived then
                ply:SetAmmo(9999, "ar2")
                ply:SetAmmo(9999, "pistol")
                
                for k, wep in pairs(ply:GetWeapons()) do
                    if wep.IsTFAWeapon then
                        if wep.IsSWSpecialWeapon and wep:IsSWSpecialWeapon() then continue end
                        local isSec = (wep.Slot == 1)
                        local maxCells = isSec and 1 or 2
                        local clipSize = wep:GetMaxClip1() > 0 and wep:GetMaxClip1() or (wep.Primary and wep.Primary.ClipSize or 50)
                        local maxAmmo = maxCells * clipSize
                        ply:SetAmmo(maxAmmo, wep:GetPrimaryAmmoType())
                        wep:SetClip1(clipSize)
                    end
                end
            end
        end)
    end)
end

function SWEP:Deploy(...)
    return BaseClass.Deploy(self, ...)
end

function SWEP:DecreaseCellStatus(amt)
    if SERVER or IsFirstTimePredicted() then
        local current = self:GetCellStatus()
        current = math.max(0, current - amt)
        local ply = self:GetOwner()
        if IsValid(ply) then
            ply:SetNW2Int(self:GetCellStatusKey(), current)
        end
        if current <= 0 then
            self:SetClip1(0)
        end
    end
end

function SWEP:HandleMinigameClick()
    if not self:GetNW2Bool("BF2_IsCooling") then return end
    if self:GetNW2Bool("BF2_IsPenalty") then return end
    if self:GetNW2Bool("BF2_HasClicked") then return end
    
    local startTime = self:GetNW2Float("BF2_CoolStartTime")
    if CurTime() - startTime < 0.1 then return end

    self:SetNW2Bool("BF2_HasClicked", true)
    
    local ply = self:GetOwner()
    local progress = (CurTime() - startTime) / self.CoolingDuration

    local blueStart = self:GetNW2Float("BF2_BlueStart", 0.30)
    local blueEnd = self:GetNW2Float("BF2_BlueEnd", 0.45)
    local yellowStart = self:GetNW2Float("BF2_YellowStart", 0.45)
    local yellowEnd = self:GetNW2Float("BF2_YellowEnd", 0.50)

    if progress >= yellowStart and progress <= yellowEnd then
        self:SetNW2Bool("BF2_IsCooling", false)
        self:SetClip1(self.Primary.ClipSize) 
        self:SetNW2Float("BF2_SupercooledUntil", CurTime() + 7) 
        self:DecreaseCellStatus(5)
        
        if self.SetStatus then self:SetStatus(TFA.Enum.STATUS_IDLE) end
        self:SetNextPrimaryFire(CurTime())
        
        if IsFirstTimePredicted() then
            local snd = self.Primary.ReloadSound or "w/heavy.wav"
            self:EmitSound(snd, 75, 130)
        end
    elseif progress >= blueStart and progress <= blueEnd then
        self:SetNW2Bool("BF2_IsCooling", false)
        self:SetClip1(self:GetMaxClip1()) 
        self:DecreaseCellStatus(10)
        
        if self.SetStatus then self:SetStatus(TFA.Enum.STATUS_IDLE) end
        self:SetNextPrimaryFire(CurTime())
        
        if IsFirstTimePredicted() then
            local snd = self.Primary.ReloadSound or "w/heavy.wav"
            self:EmitSound(snd, 75, 115)
        end
    else
        self:SetNW2Bool("BF2_IsPenalty", true)
        self:SetNW2Float("BF2_PenaltyStartTime", CurTime())
        self:SetNextPrimaryFire(CurTime() + self.PenaltyTime) 
        self:SetNW2Float("BF2_NextAutoCoolTime", CurTime() + self.PenaltyTime)
        self:DecreaseCellStatus(20)
        
        if self.SetStatus then self:SetStatus(TFA.Enum.STATUS_IDLE) end
        
        if IsFirstTimePredicted() then
            local snd = self.Primary.ReloadSound or "w/heavy.wav"
            self:EmitSound(snd, 75, 100)
        end
    end
end

function SWEP:PrimaryAttack(...)
    if self:GetNW2Bool("BF2_IsCooling") then 
        return 
    end
    
    if self:GetCellStatus() <= 0 and CurTime() >= self:GetNW2Float("BF2_SupercooledUntil", 0) then
        return
    end
    
    local clipBefore = self:Clip1()
    local ret = BaseClass.PrimaryAttack(self, ...)
    
    if CurTime() < self:GetNW2Float("BF2_SupercooledUntil", 0) then
        self:SetClip1(clipBefore)
    end
    
    if IsFirstTimePredicted() then
        self:SetNW2Float("BF2_LastShotTime", CurTime())
        
        local fireDelay = 60 / (self.Primary.RPM or 600)
        local coolDelay = self.AutoCoolDelay or 1.5
        if coolDelay <= fireDelay then
            coolDelay = fireDelay + 0.8
        end
        
        self:SetNW2Float("BF2_NextAutoCoolTime", CurTime() + coolDelay)
        
        if self:Clip1() <= 0 and not self:GetNW2Bool("BF2_IsCooling") and self:GetCellStatus() > 0 then
            self:StartCoolingMinigame()
        end
    end
    
    return ret
end

function SWEP:StartCoolingMinigame()
    self:SetNW2Bool("BF2_IsCooling", true)
    self:SetNW2Bool("BF2_IsPenalty", false)
    self:SetNW2Float("BF2_CoolStartTime", CurTime())
    self:SetNW2Bool("BF2_HasClicked", false)
    
    if SERVER or IsFirstTimePredicted() then
        local blueSize = math.Rand(0.15, 0.25)
        local yellowSize = math.Rand(0.04, 0.08)
        
        local blueStart = math.Rand(0.15, 0.4)
        local blueEnd = blueStart + blueSize
        
        local gap = math.Rand(0, 0.15)
        local yellowStart = blueEnd + gap
        
        if yellowStart + yellowSize > 0.95 then
            yellowStart = 0.95 - yellowSize
        end
        
        self:SetNW2Float("BF2_BlueStart", blueStart)
        self:SetNW2Float("BF2_BlueEnd", blueEnd)
        self:SetNW2Float("BF2_YellowStart", yellowStart)
        self:SetNW2Float("BF2_YellowEnd", yellowStart + yellowSize)
    end
    
    self:SetNextPrimaryFire(CurTime() + self.CoolingDuration + 0.5) 
    if self.SetStatus then
        self:SetStatus(TFA.Enum.STATUS_IDLE)
    end
end

function SWEP:CanReload()
    if self:GetCellStatus() <= 0 then
        return BaseClass.CanReload(self)
    end
    return false
end

function SWEP:Reload(...)
    local ply = self:GetOwner()
    
    if self:GetNW2Bool("BF2_IsCooling") then 
        if IsValid(ply) and ply:KeyPressed(IN_RELOAD) then
            self:HandleMinigameClick()
        end
        return false
    end

    if self:GetCellStatus() <= 0 then
        if self:Clip1() == self.Primary.ClipSize then
            self:SetClip1(0)
        end
        local b = BaseClass.Reload(self, ...)
        if b or (self.GetStatus and self:GetStatus() == TFA.Enum.STATUS_RELOADING) then
            self:SetNW2Bool("IsCellReloading", true)
        end
        return b
    end

    if IsValid(ply) and ply:KeyPressed(IN_RELOAD) then
        local maxClip = self.Primary.ClipSize or 0
        if maxClip > 0 then
            local heat = 1 - math.Clamp(self:Clip1() / maxClip, 0, 1)
            if heat > 0.5 and self:GetCellStatus() > 0 then
                self:StartCoolingMinigame()
                if IsFirstTimePredicted() then
                    local snd = self.Primary.ReloadSound or "w/heavy.wav"
                    self:EmitSound(snd, 75, 100) 
                end
            end
        end
    end
    
    return false
end

function SWEP:IsSWSpecialWeapon()
    local cls = string.lower(self:GetClass() or "")
    if string.find(cls, "z6") or string.find(cls, "rps") or self.IsSpecialWeapon then
        return true
    end
    return false
end

function SWEP:Think2(...)
    BaseClass.Think2(self, ...)

    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    
    if SERVER and not self:IsSWSpecialWeapon() then
        local ammoType = self:GetPrimaryAmmoType()
        if ammoType and ammoType ~= -1 then
            local isSec = (self.Slot == 1)
            local maxCells = isSec and 1 or 2
            local clipSize = self:GetMaxClip1() > 0 and self:GetMaxClip1() or (self.Primary and self.Primary.ClipSize or 50)
            local maxAmmo = maxCells * clipSize
            local curAmmo = ply:GetAmmoCount(ammoType)
            if curAmmo > maxAmmo then
                ply:SetAmmo(maxAmmo, ammoType)
            end
        end
    end
    
    if self:GetNW2Bool("IsCellReloading") then
        if self:GetStatus() ~= TFA.Enum.STATUS_RELOADING then
            self:SetNW2Bool("IsCellReloading", false)
            if SERVER or IsFirstTimePredicted() then
                ply:SetNW2Int(self:GetCellStatusKey(), 100)
            end
        end
    end

    if not self:GetNW2Bool("BF2_IsCooling") then
        if CurTime() >= self:GetNW2Float("BF2_NextAutoCoolTime") and self:GetNW2Float("BF2_LastShotTime") > 0 then
            local clipSize = self:GetMaxClip1() > 0 and self:GetMaxClip1() or (self.Primary and self.Primary.ClipSize or 50)
            if self:Clip1() < clipSize and self:GetCellStatus() > 0 then
                self:SetClip1(self:Clip1() + 1)
                self:SetNW2Float("BF2_NextAutoCoolTime", CurTime() + self.AutoCoolRate)
            end
        end
    else
        local isPenalty = self:GetNW2Bool("BF2_IsPenalty")
        local progress = 0

        if isPenalty then
            progress = (CurTime() - self:GetNW2Float("BF2_PenaltyStartTime")) / self.PenaltyTime
        else
            local startTime = self:GetNW2Float("BF2_CoolStartTime")
            progress = (CurTime() - startTime) / self.CoolingDuration
        end
        
        if self.SetStatus then
            self:SetStatus(TFA.Enum.STATUS_IDLE)
        end
        self:SetNextPrimaryFire(CurTime() + 0.2)

        if not isPenalty and ply:KeyPressed(IN_RELOAD) then
            self:HandleMinigameClick()
        end

        if progress > 1 then
            if isPenalty then
                self:SetNW2Bool("BF2_IsCooling", false)
                self:SetNW2Bool("BF2_IsPenalty", false)
                if self:GetCellStatus() > 0 then
                    self:SetClip1(self.Primary.ClipSize)
                end
                if self.SetStatus then
                    self:SetStatus(TFA.Enum.STATUS_IDLE)
                end
                self:SetNextPrimaryFire(CurTime())
            else
                if not self:GetNW2Bool("BF2_HasClicked") then
                    self:SetNW2Bool("BF2_IsPenalty", true)
                    self:SetNW2Float("BF2_PenaltyStartTime", CurTime())
                    self:SetNextPrimaryFire(CurTime() + self.PenaltyTime)
                    self:SetNW2Float("BF2_NextAutoCoolTime", CurTime() + self.PenaltyTime)
                    self:DecreaseCellStatus(20)
                    
                    if IsFirstTimePredicted() then
                        local snd = self.Primary.ReloadSound or "w/heavy.wav"
                        self:EmitSound(snd, 75, 100) 
                    end
                end
            end
        end
    end
end
  
if CLIENT then  
    function SWEP:DrawHUDUI(...)  
        BaseClass.DrawHUDUI(self, ...)  
    end  
end 
