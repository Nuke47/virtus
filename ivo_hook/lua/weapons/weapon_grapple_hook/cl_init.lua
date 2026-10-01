-- ============================================================
--  SW:RP Grappling Hook - cl_init.lua  (CLIENT)
-- ============================================================
include("shared.lua")

local MAT_ROPE = Material("cable/cable2")
local MAT_GLOW = Material("sprites/light_glow02_add")

surface.CreateFont("GrappleHUD_Title", { font = "SansSerifFLF", size = 20, weight = 500, antialias = true })
surface.CreateFont("GrappleHUD_Desc", { font = "SansSerifFLF", size = 14, weight = 500, antialias = true })
surface.CreateFont("GrappleHUD_Aurebesh", { font = "VirtusBe", size = 11, weight = 500, antialias = true })

local C = {
    bg      = Color(0, 0, 0, 150),
    accent  = Color(0, 150, 255, 150),
    text    = Color(200, 200, 200, 255),
    dim     = Color(150, 150, 150, 255),
}

function SWEP:DoDrawCrosshair(x, y) return true end

function SWEP:PreDrawViewModel(vm, wep, ply)
    local hands = ply:GetHands()
    if IsValid(hands) then
        local expectedModel = "models/aussiwozzi/cgi/base/trooper_arms.mdl"
        if hands:GetModel() ~= expectedModel then
            hands.GrappleOldModel = hands:GetModel()
            hands:SetModel(expectedModel)
        end
    end
end

function SWEP:RestoreHands()
    local ply = LocalPlayer()
    if IsValid(ply) then
        local hands = ply:GetHands()
        if IsValid(hands) and hands.GrappleOldModel then
            hands:SetModel(hands.GrappleOldModel)
            hands.GrappleOldModel = nil
        end
    end
end

function SWEP:Holster() self:RestoreHands(); return true end
function SWEP:OnRemove() self:RestoreHands() end

function SWEP:DrawHUD()
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:GetActiveWeapon() ~= self then return end

    local active  = self:GetHookActive()
    local ropeLen = self:GetCurrentRopeLength()
    local brk     = self:GetBreakProgress()
    
    local w, h = 420, 75
    local x = ScrW() / 2 - w / 2
    local y = ScrH() - 140

    draw.RoundedBox(16, x, y, w, h, C.bg)
    
    surface.SetDrawColor(C.accent)
    surface.DrawRect(x + 20, y + 45, w - 40, 1)
    
    local textX = x + w / 2
    
    if active then
        local tStr = "CABLE: " .. math.floor(ropeLen) .. "m"
        draw.SimpleText(tStr, "GrappleHUD_Title", textX, y + 20, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(tStr, "GrappleHUD_Aurebesh", textX, y + 36, Color(100, 255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        draw.SimpleText("[LMB/ENTER] SUBIR   [RMB] BAJAR   [E] IMPULSO   [R] SOLTAR", "GrappleHUD_Desc", textX, y + 58, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        draw.SimpleText("SISTEMA EN ESPERA", "GrappleHUD_Title", textX, y + 20, C.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("SISTEMA EN ESPERA", "GrappleHUD_Aurebesh", textX, y + 36, Color(150, 150, 150, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        draw.SimpleText("[LMB] DISPARAR GANCHO", "GrappleHUD_Desc", textX, y + 58, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    if brk > 0 then
        draw.RoundedBox(4, x + 20, y + h - 6, (w - 40) * (brk / 100), 4, Color(255, 80, 80))
    end
end

function SWEP:DrawWorldModel() self:DrawModel() end

function SWEP:GetViewModelPosition(pos, ang)
    return pos + ang:Right() * 10 - ang:Up() * 5 + ang:Forward() * 5, ang
end

hook.Add("PostDrawOpaqueRenderables", "GrappleHook_DrawRope", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "weapon_grapple_hook" or not wep:GetRopeVisible() then return end

    local startPos = ply:GetShootPos()
    if ply == LocalPlayer() and not ply:ShouldDrawLocalPlayer() then
        local vm = ply:GetViewModel()
        if IsValid(vm) then startPos = (vm:GetAttachment(1) and vm:GetAttachment(1).Pos) or (vm:GetPos() + ply:GetAimVector() * 20) end
    else
        startPos = (wep:GetAttachment(1) and wep:GetAttachment(1).Pos) or wep:GetPos()
    end
    local endPos = wep:GetHookWorldPos()
    if endPos == vector_origin or (endPos - startPos):Length() < 10 then return end

    render.SetMaterial(MAT_ROPE)
    render.DrawBeam(startPos, endPos, wep.GrappleConfig.BeamWidth, 0, (endPos - startPos):Length() / 64, wep.GrappleConfig.RopeColor)

    render.SetMaterial(MAT_GLOW)
    local gs = 10 + math.sin(CurTime() * 5) * 2
    render.DrawSprite(endPos, gs, gs, Color(255, 215, 80, 220))
end)

local lastActive = false
local lastEnter  = false

function SWEP:Think()
    local active = self:GetHookActive()

    -- Polling de cliente para la tecla ENTER
    if active then
        local isEnterDown = input.IsKeyDown(KEY_ENTER) or input.IsKeyDown(KEY_PAD_ENTER)
        if isEnterDown ~= lastEnter then
            net.Start("GrappleHook_EnterKey")
            net.WriteBool(isEnterDown)
            net.SendToServer()
            lastEnter = isEnterDown
        end
    end

    if active and not lastActive then
        local pos = self:GetHookWorldPos()
        if pos ~= vector_origin then
            local e = ParticleEmitter(pos)
            if e then
                for i = 1, 14 do
                    local p = e:Add("effects/spark", pos)
                    if p then
                        p:SetVelocity(VectorRand() * math.Rand(60, 220))
                        p:SetDieTime(math.Rand(0.15, 0.5))
                        p:SetStartAlpha(255); p:SetEndAlpha(0)
                        p:SetStartSize(2); p:SetEndSize(0)
                        p:SetColor(255, 195, 60)
                        p:SetGravity(Vector(0, 0, -500))
                    end
                end
                e:Finish()
            end
        end
    end
    lastActive = active
end

hook.Add("HUDPaint", "GrappleHook_HUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == "weapon_grapple_hook" then wep:DrawHUD() end
end)