--[[
    Dev/test helpers for the CIS droid tiers. Server-side, superadmin-only.
    Safe to delete in production. See /TESTING.md.

    Console commands (run in your listen-server console or as superadmin):
      droid_spawn <b1|b2|bx> [count]   spawn N droids ~150u in front of you
      droid_clear                      remove every droid in the map
      droid_debug <0|1>                toggle a live debug overlay on every droid
--]]

local VALID = {
    b1 = "npc_droid_b1",
    b2 = "npc_droid_b2",
    bx = "npc_droid_bx",
}

local function canUse(ply)
    if not IsValid(ply) then return true end          -- server console
    return ply:IsSuperAdmin()
end

concommand.Add("droid_spawn", function(ply, _, args)
    if not canUse(ply) then return end

    local tier = string.lower(args[1] or "b1")
    local class = VALID[tier]
    if not class then
        if IsValid(ply) then ply:ChatPrint("Use: droid_spawn <b1|b2|bx> [count]") end
        return
    end

    local count = math.Clamp(tonumber(args[2]) or 1, 1, 24)

    local base, fwd, right
    if IsValid(ply) then
        base  = ply:GetPos()
        fwd   = ply:GetAimVector(); fwd.z = 0; fwd:Normalize()
        right = fwd:Cross(Vector(0, 0, 1))
    else
        base  = Vector(0, 0, 0)
        fwd   = Vector(1, 0, 0)
        right = Vector(0, 1, 0)
    end

    for i = 1, count do
        local offset = fwd * 150 + right * ((i - 1) * 60 - (count - 1) * 30)
        local d = ents.Create(class)
        if IsValid(d) then
            d:SetPos(base + offset + Vector(0, 0, 10))
            d:Spawn()
            d:Activate()
        end
    end
    if IsValid(ply) then ply:ChatPrint(("Spawned %d x %s"):format(count, class)) end
end)

concommand.Add("droid_clear", function(ply)
    if not canUse(ply) then return end
    local n = 0
    for _, e in ipairs(ents.GetAll()) do
        if IsValid(e) and e.IsDroidNPC then e:Remove(); n = n + 1 end
    end
    if IsValid(ply) then ply:ChatPrint(("Removed %d droids"):format(n)) end
end)

-- Live overlay: tier, target, engagement style, ally count, range/spread.
local debugOn = false
concommand.Add("droid_debug", function(ply, _, args)
    if not canUse(ply) then return end
    debugOn = tobool(args[1] or "1")
    if IsValid(ply) then ply:ChatPrint("droid_debug = " .. tostring(debugOn)) end
end)

hook.Add("Think", "droid_debug_overlay", function()
    if not debugOn then return end
    for _, e in ipairs(ents.GetAll()) do
        if IsValid(e) and e.IsDroidNPC and e.Cfg then
            local enemy = IsValid(e.Enemy) and e.Enemy:Nick() or "none"
            local dist = IsValid(e.Enemy) and math.Round(e:GetPos():Distance(e.Enemy:GetPos())) or 0
            local spread = IsValid(e.Enemy) and e:ComputeSpread(dist) or 0
            local txt = string.format(
                "%s\nstyle: %s  allies: %d\ntarget: %s  dist: %d\nspread: %.3f  HP: %d",
                e:GetClass(), tostring(e.EngageStyle), e:CountNearbyAllies(),
                enemy, dist, spread, e:Health())
            debugoverlay.Text(e:GetPos() + Vector(0, 0, 90), txt, 0.1, false)
            debugoverlay.Sphere(e:GetPos(), e.Cfg.DetectRadius, 0.1, Color(0, 150, 255, 4), true)
        end
    end
end)
