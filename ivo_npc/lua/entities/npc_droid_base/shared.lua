ENT.Base = "base_nextbot"
ENT.Type = "nextbot"

-- This is the non-spawnable engine. B1/B2/BX inherit from it via ENT.Base = "npc_droid_base".
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.PrintName = "Droid (Base)"
ENT.Category = "Star Wars"

-- Tag so droids can recognize each other as squad allies (see CountNearbyAllies).
ENT.IsDroidNPC = true
ENT.AutomaticFrameAdvance = true



local function StaticShieldCallback(attacker, tr, dmginfo)
    local ent = tr.Entity
    if IsValid(ent) and ent.IsDroidNPC and ent:GetNW2Bool("HasShieldActive", false) then
        return true
    end
end

hook.Add("EntityFireBullets", "DroidekaShield_SuppressBulletImpact", function(entity, data)
    local oldCb = data.Callback
    if not oldCb then
        data.Callback = StaticShieldCallback
    else
        data.Callback = function(attacker, tr, dmginfo)
            local ent = tr.Entity
            if IsValid(ent) and ent.IsDroidNPC and ent:GetNW2Bool("HasShieldActive", false) then
                oldCb(attacker, tr, dmginfo)
                return true
            end
            return oldCb(attacker, tr, dmginfo)
        end
    end
    return true
end)
