-- =========================================================================
-- PROBE DROID — RED Y SISTEMA DE VINCULACIÓN
-- =========================================================================

if SERVER then
    util.AddNetworkString("Probe_Link")
    util.AddNetworkString("Probe_Unlink")
    util.AddNetworkString("Probe_LinkConfirm")
    util.AddNetworkString("Probe_StartControl")
    util.AddNetworkString("Probe_StopControl")
    util.AddNetworkString("Probe_InputUpdate")
    util.AddNetworkString("Probe_ForceExit")

    local MAX_GLOBAL_PROBES = 2

    -- ─── Verificar equipo ────────────────────────────────────────────
    local function IsAllowedTeam(ply)
        if not IsValid(ply) then return false end
        local tid = ply:Team()
        if _G["TEAM_SU_SPEC"] and tid == _G["TEAM_SU_SPEC"] then return true end
        if _G["TEAM_SU_ESPECIALISTA"] and tid == _G["TEAM_SU_ESPECIALISTA"] then return true end
        if _G["TEAM_STAFF"]   and tid == _G["TEAM_STAFF"]   then return true end
        return false
    end

    -- ─── Contar probes vinculados ────────────────────────────────────
    local function CountLinkedProbes()
        local count = 0
        for _, ent in ipairs(ents.FindByClass("ent_probe_droid")) do
            if IsValid(ent) and ent:GetProbeLinked() then
                count = count + 1
            end
        end
        return count
    end

    -- ─── Desvincular sonda de un jugador ─────────────────────────────
    local function UnlinkProbe(ply)
        if not IsValid(ply) then return end
        local probe = ply.LinkedProbe
        if not IsValid(probe) then
            ply.LinkedProbe = nil
            return
        end

        probe:SetProbeLinked(false)
        probe:SetProbeOwner(Entity(0))
        probe:SetProbeControlled(false)
        probe.MoveForward = 0
        probe.MoveRight   = 0
        probe.MoveUp      = 0
        ply.LinkedProbe = nil

        net.Start("Probe_ForceExit")
        net.Send(ply)
    end

    -- ─── VINCULAR SONDA (Escaneo completado) ─────────────────────────
    net.Receive("Probe_Link", function(len, ply)
        if not IsValid(ply) then return end
        if not IsAllowedTeam(ply) then
            ply:ChatPrint("[Sonda] Acceso denegado.")
            return
        end

        local probe = net.ReadEntity()
        if not IsValid(probe) or probe:GetClass() ~= "ent_probe_droid" then return end

        if probe:GetProbeLinked() then
            ply:ChatPrint("[Sonda] Esta sonda ya está vinculada a otro operador.")
            return
        end

        if IsValid(ply.LinkedProbe) then
            ply:ChatPrint("[Sonda] Ya tienes una sonda vinculada. Desvincula la actual primero.")
            return
        end

        if CountLinkedProbes() >= MAX_GLOBAL_PROBES then
            ply:ChatPrint("[Sonda] Límite global alcanzado (" .. MAX_GLOBAL_PROBES .. "/" .. MAX_GLOBAL_PROBES .. "). Espere a que se libere una.")
            return
        end

        -- Vincular
        probe:SetProbeLinked(true)
        probe:SetProbeOwner(ply)
        ply.LinkedProbe = probe

        ply:ChatPrint("[Sonda] Droide sonda vinculado exitosamente.")
        probe:EmitSound("lvs/viper/probescan.mp3", 75, 100, 0.8)

        net.Start("Probe_LinkConfirm")
            net.WriteEntity(probe)
        net.Send(ply)
    end)

    -- ─── DESVINCULAR SONDA ───────────────────────────────────────────
    net.Receive("Probe_Unlink", function(len, ply)
        if not IsValid(ply) then return end
        UnlinkProbe(ply)
        ply:ChatPrint("[Sonda] Sonda desvinculada.")
    end)

    -- ─── INICIAR CONTROL ─────────────────────────────────────────────
    net.Receive("Probe_StartControl", function(len, ply)
        if not IsValid(ply) then return end
        local probe = net.ReadEntity()
        if not IsValid(probe) or probe:GetClass() ~= "ent_probe_droid" then return end
        if probe:GetProbeOwner() ~= ply then return end
        if not probe:GetProbeLinked() then return end
        if not IsAllowedTeam(ply) then return end

        probe:SetProbeControlled(true)
        net.Start("Probe_StartControl")
            net.WriteEntity(probe)
        net.Send(ply)
    end)

    -- ─── DETENER CONTROL ─────────────────────────────────────────────
    net.Receive("Probe_StopControl", function(len, ply)
        if not IsValid(ply) then return end
        local probe = ply.LinkedProbe
        if not IsValid(probe) then return end
        probe:SetProbeControlled(false)
        probe.MoveForward = 0
        probe.MoveRight   = 0
        probe.MoveUp      = 0
    end)

    -- ─── INPUT DEL DRON ──────────────────────────────────────────────
    net.Receive("Probe_InputUpdate", function(len, ply)
        if not IsValid(ply) then return end
        local probe = ply.LinkedProbe
        if not IsValid(probe) or probe:GetProbeOwner() ~= ply then return end
        probe.MoveForward = net.ReadFloat()
        probe.MoveRight   = net.ReadFloat()
        probe.MoveUp      = net.ReadFloat()
        probe.AimAngles   = net.ReadAngle()
    end)

    -- ─── ESCANEO DE ENTIDADES ─────────────────────────────────────────
    util.AddNetworkString("Probe_DoScan")
    util.AddNetworkString("Probe_ScanResults")

    net.Receive("Probe_DoScan", function(len, ply)
        if not IsValid(ply) then return end
        local probe = ply.LinkedProbe
        if not IsValid(probe) then return end
        
        -- Cooldown de 5 segundos
        if probe.NextScan and probe.NextScan > CurTime() then return end
        probe.NextScan = CurTime() + 5 
        
        local scanRadius = 2500
        local entsFound = ents.FindInSphere(probe:GetPos(), scanRadius)
        local targets = {}
        for _, v in ipairs(entsFound) do
            if (v:IsPlayer() and v:Alive() and v ~= ply) or v:IsNPC() then
                table.insert(targets, v)
            end
        end
        
        -- Emitir sonido para todos
        probe:EmitSound("buttons/blip1.wav", 75, 100, 0.6)

        -- Buscar a jugadores de "Shadow Unit" para enviar los resultados
        local receivers = {}
        for _, p in ipairs(player.GetAll()) do
            local isShadow = false
            if RPExtraTeams and RPExtraTeams[p:Team()] and RPExtraTeams[p:Team()].category == "Shadow Unit" then
                isShadow = true
            end
            local tName = string.lower(team.GetName(p:Team()))
            if string.find(tName, "shadow") or string.find(tName, "su:") or string.find(tName, "especialista") then
                isShadow = true
            end
            if isShadow or p == ply then
                table.insert(receivers, p)
            end
        end

        net.Start("Probe_ScanResults")
            net.WriteUInt(#targets, 16)
            for _, v in ipairs(targets) do
                net.WriteEntity(v)
            end
            net.WriteFloat(CurTime() + 8) -- Activo por 8 segundos
        net.Send(receivers)
    end)

    -- ─── RESTRICCIÓN DE SPAWN ────────────────────────────────────────
    hook.Add("PlayerSpawnSENT", "ProbeDroid_SpawnRestrict", function(ply, class)
        if class == "ent_probe_droid" then
            if not IsAllowedTeam(ply) and not ply:IsAdmin() then
                ply:ChatPrint("[Sonda] Solo operadores especializados pueden desplegar sondas.")
                return false
            end
        end
    end)

    -- ─── LIMPIEZA: Muerte → Desvincular (no destruir) ────────────────
    hook.Add("PlayerDeath", "ProbeDroid_DeathCleanup", function(ply)
        if IsValid(ply.LinkedProbe) then
            UnlinkProbe(ply)
        end
    end)

    -- ─── LIMPIEZA: Respawn → Desvincular ─────────────────────────────
    hook.Add("PlayerSpawn", "ProbeDroid_RespawnCleanup", function(ply)
        if IsValid(ply.LinkedProbe) then
            UnlinkProbe(ply)
        end
    end)

    -- ─── LIMPIEZA: Cambio de equipo ──────────────────────────────────
    hook.Add("OnPlayerChangedTeam", "ProbeDroid_TeamCheck", function(ply, oldTeam, newTeam)
        if IsValid(ply.LinkedProbe) and not IsAllowedTeam(ply) then
            UnlinkProbe(ply)
        end
    end)

    -- ─── LIMPIEZA: Desconexión ───────────────────────────────────────
    hook.Add("PlayerDisconnected", "ProbeDroid_Cleanup", function(ply)
        if IsValid(ply.LinkedProbe) then
            UnlinkProbe(ply)
        end
    end)
end

-- =========================================================================
-- CLIENTE
-- =========================================================================
if CLIENT then
    net.Receive("Probe_LinkConfirm", function()
        local probe = net.ReadEntity()
        surface.PlaySound("lvs/viper/probescan.mp3")
        
        -- Si el jugador tiene el datapad abierto, guardar la referencia y recargar su pantalla
        local wep = LocalPlayer():GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_ivo_datapad" then
            wep.KnownActiveProbe = probe
            if wep.DatapadState == "hub" then
                wep:BuildHubScreen()
            end
        end
    end)
end
