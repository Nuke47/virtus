--[[
    ivo_bombs - Kit de Desactivación (SWEP)
    Arma que permite desactivar bombas al presionar E o Click
]]

SWEP.PrintName    = "Kit de Desactivación"
SWEP.Author       = "Ivo"
SWEP.Category     = "ivo_bombs"
SWEP.Purpose      = "Desactivar bombas"
SWEP.Instructions = "Apunta a una bomba y presiona E o Click Izquierdo"

SWEP.Spawnable      = true
SWEP.AdminSpawnable = true

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo        = "none"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

SWEP.Weight         = 5
SWEP.AutoSwitchTo   = false
SWEP.AutoSwitchFrom = false
SWEP.Slot           = 0
SWEP.SlotPos        = 5
SWEP.DrawAmmo       = false
SWEP.DrawCrosshair  = false

SWEP.ViewModel  = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.HoldType   = "slam"

function SWEP:Initialize()
    self:SetHoldType("slam")
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 1)

    if CLIENT then
        local ply = self:GetOwner()
        if not IsValid(ply) then return end

        local tr = ply:GetEyeTrace()
        local ent = tr.Entity

        if not IsValid(ent) then return end
        if ent:GetClass() ~= "ent_ivo_bomb" then return end
        if tr.HitPos:Distance(ply:GetPos()) > 250 then return end
        if not ent:GetArmed() or ent:GetDefused() then return end

        net.Start("ivo_bombs_request_defuse")
            net.WriteEntity(ent)
        net.SendToServer()
    end
end

function SWEP:SecondaryAttack() end
function SWEP:Reload() end

-- ============================================================
-- HUD del SWEP
-- ============================================================
if CLIENT then
    local FONT_CREATED = false

    local function EnsureFonts()
        if FONT_CREATED then return end
        FONT_CREATED = true
        surface.CreateFont("DefuserHUD", {
            font = "Roboto", size = 18, weight = 600, antialias = true,
        })
        surface.CreateFont("DefuserHUDSmall", {
            font = "Roboto", size = 14, weight = 500, antialias = true,
        })
    end

    function SWEP:DrawHUD()
        EnsureFonts()

        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local tr = ply:GetEyeTrace()
        local ent = tr.Entity

        local scrW, scrH = ScrW(), ScrH()
        local cx, cy = scrW / 2, scrH / 2

        -- Cruz de mira personalizada
        local col = Color(0, 200, 255, 200)

        surface.SetDrawColor(col)
        -- Horizontal
        surface.DrawRect(cx - 14, cy - 1, 10, 2)
        surface.DrawRect(cx + 5, cy - 1, 10, 2)
        -- Vertical
        surface.DrawRect(cx - 1, cy - 14, 2, 10)
        surface.DrawRect(cx - 1, cy + 5, 2, 10)
        -- Punto central
        surface.DrawRect(cx - 1, cy - 1, 2, 2)

        -- Indicador de bomba detectada
        if IsValid(ent) and ent:GetClass() == "ent_ivo_bomb" then
            local dist = tr.HitPos:Distance(ply:GetPos())

            if ent:GetArmed() and not ent:GetDefused() and dist <= 250 then
                -- Borde de detección
                local pulse = math.abs(math.sin(CurTime() * 3))
                local borderCol = Color(255, 80, 40, 150 + pulse * 105)
                surface.SetDrawColor(borderCol)
                surface.DrawOutlinedRect(cx - 20, cy - 20, 40, 40, 2)

                -- Esquinas
                local s = 8
                surface.DrawRect(cx - 20, cy - 20, s, 2)
                surface.DrawRect(cx - 20, cy - 20, 2, s)
                surface.DrawRect(cx + 20 - s, cy - 20, s, 2)
                surface.DrawRect(cx + 18, cy - 20, 2, s)
                surface.DrawRect(cx - 20, cy + 18, s, 2)
                surface.DrawRect(cx - 20, cy + 20 - s, 2, s)
                surface.DrawRect(cx + 20 - s, cy + 18, s, 2)
                surface.DrawRect(cx + 18, cy + 20 - s, 2, s)

                -- Texto
                draw.SimpleText("[E] / [CLICK] DESACTIVAR", "DefuserHUD", cx, cy + 30,
                    Color(255, 200, 80, 200 + pulse * 55), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

                -- Dificultad de la bomba
                local diff = ent:GetDifficulty()
                local config = IVO_BOMBS and IVO_BOMBS.Difficulties[diff]
                if config then
                    draw.SimpleText("Dificultad: " .. config.name, "DefuserHUDSmall", cx, cy + 52,
                        config.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                end
            elseif ent:GetDefused() then
                draw.SimpleText("DESACTIVADA", "DefuserHUD", cx, cy + 30,
                    Color(80, 255, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end

        -- Nombre del arma abajo
        draw.SimpleText("Kit de Desactivación", "DefuserHUDSmall",
            scrW / 2, scrH - 40, Color(0, 200, 255, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end
