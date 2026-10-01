AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("Datapad_StartHack")

util.AddNetworkString("Datapad_OpenPINUI")
util.AddNetworkString("Datapad_SubmitPIN")

function ENT:Initialize()
    self:SetModel("models/props_lab/keypad.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end
end

function ENT:HasAccess(ply)
    local reqLvl = self:GetAccessLevel()
    local allowed = self:GetAccessJobs()
    
    -- Si es admin en staff, pasa directo
    if Datapad and Datapad.HasAccess and Datapad:HasAccess(ply, Datapad.Config.StaffJobs) then return true end
    
    -- Chequeo por Nivel de Acceso Jerárquico
    if reqLvl > 0 then
        local plyLvl = Datapad:GetPlayerAccessLevel(ply)
        if plyLvl >= reqLvl then
            return true
        end
    end
    
    -- Chequeo por Trabajos Específicos (Bypass)
    if allowed ~= "" then
        local plyJob = team.GetName(ply:Team())
        local jobs = string.Explode(",", allowed)
        for _, j in ipairs(jobs) do
            local cleanJ = string.Trim(j)
            if cleanJ ~= "" and string.find(string.lower(plyJob), string.lower(cleanJ)) then
                return true
            end
        end
    end
    
    -- Si no requiere nivel y no requiere jobs, es pública
    if reqLvl == 0 and allowed == "" then
        return true
    end
    
    return false
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if self.NextUse and CurTime() < self.NextUse then return end
    self.NextUse = CurTime() + 0.5
    
    local kType = self:GetKeypadType()
    
    if kType == 0 then
        -- IDENTIFICACION (Role-based)
        if self:HasAccess(activator) then
            self:OpenDoors()
        else
            activator:ChatPrint("[Keypad] Acceso Denegado. No posees autorización de seguridad.")
            self:TryHack(activator)
        end
    elseif kType == 1 then
        -- PIN NUMERICO
        net.Start("Datapad_OpenPINUI")
        net.WriteEntity(self)
        net.Send(activator)
    end
end

util.AddNetworkString("Datapad_RequestKeypadHack")

net.Receive("Datapad_RequestKeypadHack", function(len, ply)
    local keypad = net.ReadEntity()
    if not IsValid(keypad) or keypad:GetClass() ~= "ivo_keypad" then return end
    if keypad:GetPos():Distance(ply:GetPos()) > 150 then return end
    
    keypad:TryHack(ply)
end)

function ENT:TryHack(ply)
    local canHack = false
    if Datapad and Datapad.HasAccess and Datapad:HasAccess(ply, Datapad.Config.HackerJobs) then
        canHack = true
    end
    
    if not canHack then
        return
    end
    
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "weapon_ivo_datapad" then
        ply:ChatPrint("[Keypad] Se requiere un Datapad Imperial para iniciar vulneración.")
        return
    end
    
    net.Start("Datapad_StartHack")
    net.WriteEntity(self)
    net.WriteUInt(self:GetHackDifficulty() or 1, 16)
    
    local games = self:GetHackGames()
    if not games or games == "" then games = "1,2,3" end
    net.WriteString(games)
    
    net.Send(ply)
end

net.Receive("Datapad_SubmitPIN", function(len, ply)
    local keypad = net.ReadEntity()
    local pin = net.ReadString()
    
    if not IsValid(keypad) or keypad:GetClass() ~= "ivo_keypad" then return end
    if keypad:GetPos():Distance(ply:GetPos()) > 150 then return end
    
    if pin == keypad.Password then
        keypad:OpenDoors()
    else
        ply:ChatPrint("[Keypad] PIN Incorrecto.")
        keypad:EmitSound("buttons/button10.wav")
    end
end)

function ENT:OpenDoors()
    self:SetIsHacked(true)
    self:EmitSound("buttons/button14.wav")

    local doorFound = false

    local function ToggleAndLock(ent)
        if IsValid(ent) then
            ent:Fire("Unlock")
            ent:Fire("Toggle")
            -- Lo volvemos a bloquear casi al instante para que no funcione con la 'E' ni con los triggers de proximidad del mapa
            ent:Fire("Lock", "", 0.05)
            doorFound = true
        end
    end

    -- 1. Buscar puertas enlazadas temporalmente por la Toolgun
    if self.TargetDoors and table.Count(self.TargetDoors) > 0 then
        for _, ent in pairs(self.TargetDoors) do
            ToggleAndLock(ent)
        end
    end

    -- 2. Buscar puertas vinculadas guardadas (por Map ID, para persistencia)
    local targetDoorsStr = self.TargetDoorsData or ""
    if targetDoorsStr ~= "" then
        local ids = string.Explode(",", targetDoorsStr)
        for _, idStr in ipairs(ids) do
            local id = tonumber(string.Trim(idStr))
            if id then
                local ent = ents.GetMapCreatedEntity(id)
                ToggleAndLock(ent)
            end
        end
    end
    
    -- Fallback si no hay vinculadas: abrir las cercanas
    if not doorFound then
        local entsAround = ents.FindInSphere(self:GetPos(), 100)
        for _, ent in ipairs(entsAround) do
            local class = ent:GetClass()
            if string.find(class, "door") then
                ToggleAndLock(ent)
                break
            end
        end
    end

    timer.Simple(3, function()
        if IsValid(self) then
            self:SetIsHacked(false)
        end
    end)
end

function ENT:OnHackSuccess(ply)
    self:OpenDoors()
    if IsValid(ply) then
        ply:ChatPrint("[Keypad] Has vulnerado el sistema de seguridad.")
    end
end
