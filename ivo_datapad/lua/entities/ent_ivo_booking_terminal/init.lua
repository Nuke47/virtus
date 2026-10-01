AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("IvoDatapad_OpenArrestMenu")
util.AddNetworkString("IvoDatapad_SubmitArrest")

function ENT:Initialize()
    self:SetModel("models/kingpommes/starwars/misc/palp_panel1.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    -- Verificar si es de la 65th
    if not (Datapad and Datapad.HasAccess) then return end
    if not Datapad:HasAccess(activator, Datapad.Config.ShockJobs) and not Datapad:HasAccess(activator, Datapad.Config.RiotJobs) then
        activator:PrintMessage(HUD_PRINTTALK, "[Terminal] Acceso Denegado: Exclusivo para 65th.")
        return
    end
    
    -- Buscar a la víctima (alguien cerca de la terminal que NO sea el activador y esté esposado)
    local target = nil
    local minDist = 60000 -- Radio aprox 245 unidades
    
    for _, ply in ipairs(player.GetAll()) do
        if ply ~= activator and ply:Alive() and ply:GetNWBool("CH_ADVARREST_Handcuffed") then
            local dist = ply:GetPos():DistToSqr(self:GetPos())
            if dist < minDist then
                minDist = dist
                target = ply
            end
        end
    end
    
    if not IsValid(target) then
        activator:PrintMessage(HUD_PRINTTALK, "[Terminal] No hay ningún individuo posicionado en el área de procesamiento.")
        return
    end
    
    -- Enviar el menú al guardia
    net.Start("IvoDatapad_OpenArrestMenu")
        net.WriteEntity(target)
    net.Send(activator)
end

-- Timer de cárcel activo
local activeJails = {}

net.Receive("IvoDatapad_SubmitArrest", function(len, ply)
    local target = net.ReadEntity()
    local reason = net.ReadString()
    local time = net.ReadUInt(16)
    
    if not IsValid(target) or not target:IsPlayer() then return end
    if not Datapad:HasAccess(ply, Datapad.Config.ShockJobs) and not Datapad:HasAccess(ply, Datapad.Config.RiotJobs) then return end
    if target:GetPos():DistToSqr(ply:GetPos()) > 40000 then return end -- Anti exploit
    
    -- Identificar tipo de ID actual (Debe coincidir con la lógica del escáner)
    local nick = target:Nick()
    
    local hasNumbers = false
    for word in string.gmatch(nick, "%S+") do
        if string.match(word, "%d+") then
            hasNumbers = true
            break
        end
    end
    
    local isImperialJob = false
    if Datapad and Datapad.IsImperial then
        isImperialJob = Datapad:IsImperial(target)
    end
    
    local isCivilian = false
    if not hasNumbers and not isImperialJob then
        isCivilian = true
    end
    
    -- Registrar en base de datos
    if IvoDB and IvoDB.AddArrest then
        IvoDB.AddArrest(target, isCivilian)
        
        -- Si tenía warrant, limpiarlo al arrestarlo
        local record = IvoDB.GetRecord(target, isCivilian)
        if record and record.warrant then
            IvoDB.SetWarrant(target, isCivilian, false)
        end
    end
    
    -- Encarcelar usando el sistema nativo de DarkRP
    if target.arrest then
        target:arrest(time, ply)
    end
    
    target:PrintMessage(HUD_PRINTCENTER, "HAS SIDO ARRESTADO\nMotivo: " .. reason)
    ply:PrintMessage(HUD_PRINTTALK, "[65TH] Arresto de " .. target:Nick() .. " procesado exitosamente.")
end)
