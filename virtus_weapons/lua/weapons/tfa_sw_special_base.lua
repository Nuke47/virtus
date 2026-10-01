if SERVER then
    AddCSLuaFile()
end
SWEP.Base = "tfa_3dscoped_base"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false

DEFINE_BASECLASS( SWEP.Base )

function SWEP:Initialize(...)
    self.Primary.DefaultClip = 0
    return BaseClass.Initialize(self, ...)
end

function SWEP:IsSWSpecialWeapon()
    return true
end

function SWEP:Equip(...)
    local ply = self:GetOwner()
    if IsValid(ply) and self:GetPrimaryAmmoType() ~= -1 then
        timer.Simple(0.1, function()
            if IsValid(self) and IsValid(ply) then
                self:SetClip1(self:GetMaxClip1() > 0 and self:GetMaxClip1() or 1)
            end
        end)
    end
    if BaseClass.Equip then
        return BaseClass.Equip(self, ...)
    end
end
