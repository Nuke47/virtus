-- ============================================================
--  SW:RP Grappling Hook - shared.lua
-- ============================================================
SWEP.Base              = "weapon_base"
SWEP.PrintName         = "Grappling Hook"
SWEP.Author            = "SW:RP Addon"
SWEP.Instructions      = "LMB: Disparar/Subir | RMB: Bajar | ENTER: Subir | E: Impulso | R: Soltar"
SWEP.Category          = "SW:RP Equipment"

SWEP.Spawnable         = true
SWEP.AdminSpawnable    = true
SWEP.UseHands          = true
SWEP.ViewModel         = "models/jajoff/sps/cgiweapons/tc13j/btx42_pistol.mdl"
SWEP.WorldModel        = "models/jajoff/sps/cgiweapons/tc13j/btx42_pistol.mdl"
SWEP.ViewModelFOV      = 62

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = "none"
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"

SWEP.GrappleConfig = {
    MaxRopeLength       = 1200,
    MinRopeLength       = 0,
    GrappleSpeed        = 1800,
    PullForce           = 900,
    ReelSpeed           = 300,
    FireCooldown        = 0.6,
    RopeColor           = Color(150, 150, 150),
    HookModel           = "models/props_c17/TrapPropeller_Lever.mdl",
    BeamWidth           = 1.5,
    SoundFire           = "weapons/ar2/fire1.wav",
    SoundHit            = "physics/metal/metal_box_impact_hard3.wav",
    SoundDetach         = "physics/metal/metal_box_impact_bullet1.wav",
}

SWEP.HookDeployed      = false
SWEP.HookEntity        = nil

function SWEP:SetupDataTables()
    self:NetworkVar("Bool",   0, "HookActive")
    self:NetworkVar("Vector", 0, "HookWorldPos")
    self:NetworkVar("Float",  0, "CurrentRopeLength")
    self:NetworkVar("Bool",   1, "RopeVisible")
    self:NetworkVar("Float",  1, "BreakProgress") 
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_DRAW)
    self:SetNextPrimaryFire(CurTime())
    if CLIENT then
        notification.AddLegacy("[Grappling Hook] Equipado", NOTIFY_HINT, 3)
    end
    return true
end

function SWEP:PrimaryAttack()
    -- Si el gancho ya está lanzado, bloquea el disparo (el Think detectará el clic para subir)
    if SERVER and (self.HookDeployed or self.HookInFlight) then return end
    if CLIENT and self:GetHookActive() then return end
    
    self:SetNextPrimaryFire(CurTime() + self.GrappleConfig.FireCooldown)
    
    if SERVER and self.FireHook then self:FireHook() end
    
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
    self:EmitSound(self.GrappleConfig.SoundFire, 75, 100, 1, CHAN_WEAPON)
end

function SWEP:SecondaryAttack() end

function SWEP:Reload()
    if not self:GetHookActive() then return end
    if SERVER and self.RetractHook then self:RetractHook() end
end