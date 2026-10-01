-- ============================================================================
-- IVO HABILITIES: SISTEMA DE STAMINA (SHARED)
-- ============================================================================

local BASE_STAMINA = 100
local STAMINA_DRAIN_RATE = 15 -- Puntos por segundo mientras corre
local STAMINA_REGEN_RATE = 10 -- Puntos por segundo descansando
local STAMINA_JUMP_COST = 10

if SERVER then
    util.AddNetworkString("IVO_Habilities_Stamina")
end

local function GetMaxStamina(ply)
    local maxStam = BASE_STAMINA
    if SERVER then
        if IVO_HABILITIES.HasSkill(ply, "gen_stamina_2") then
            maxStam = maxStam * 1.40
        elseif IVO_HABILITIES.HasSkill(ply, "gen_stamina_1") then
            maxStam = maxStam * 1.20
        end
    else
        maxStam = ply:GetNWFloat("IVO_MaxStamina", BASE_STAMINA)
    end
    return maxStam
end

if SERVER then
    hook.Add("PlayerSpawn", "IVO_Stamina_Spawn", function(ply)
        ply.IVO_Stamina = GetMaxStamina(ply)
        ply:SetNWFloat("IVO_Stamina", ply.IVO_Stamina)
        ply:SetNWFloat("IVO_MaxStamina", GetMaxStamina(ply))
    end)
end

hook.Add("SetupMove", "IVO_Stamina_Move", function(ply, mv, cmd)
    if not ply:Alive() then return end
    
    local maxStam = GetMaxStamina(ply)
    
    if SERVER then
        ply.IVO_Stamina = ply.IVO_Stamina or maxStam
    else
        ply.IVO_Stamina = ply:GetNWFloat("IVO_Stamina", maxStam)
    end
    
    local isFirstTime = IsFirstTimePredicted()
    
    -- Manejo del Salto
    if mv:KeyPressed(IN_JUMP) and ply:OnGround() then
        if ply.IVO_Stamina >= STAMINA_JUMP_COST then
            if SERVER or isFirstTime then
                ply.IVO_Stamina = ply.IVO_Stamina - STAMINA_JUMP_COST
            end
        else
            -- Si no tiene suficiente stamina, bloqueamos el salto (salvo que tenga jetpack)
            local hasJetpack = _G.IVO_HasJetpack and _G.IVO_HasJetpack(ply)
            if not hasJetpack then
                mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
            end
        end
    end
    
    -- Drenaje y regeneración
    if mv:KeyDown(IN_SPEED) and ply:GetVelocity():Length2D() > ply:GetWalkSpeed() and ply:OnGround() then
        -- Está corriendo
        if SERVER or isFirstTime then
            ply.IVO_Stamina = math.Clamp(ply.IVO_Stamina - (STAMINA_DRAIN_RATE * FrameTime()), 0, maxStam)
        end
        
        -- Si se queda sin stamina, deja de correr
        if ply.IVO_Stamina <= 0 then
            mv:SetMaxClientSpeed(ply:GetWalkSpeed())
            mv:SetMaxSpeed(ply:GetWalkSpeed())
        end
    else
        -- Regenerando
        if SERVER or isFirstTime then
            ply.IVO_Stamina = math.Clamp(ply.IVO_Stamina + (STAMINA_REGEN_RATE * FrameTime()), 0, maxStam)
        end
    end
    
    if SERVER then
        ply:SetNWFloat("IVO_Stamina", ply.IVO_Stamina)
        ply:SetNWFloat("IVO_MaxStamina", maxStam)
    end
end)
