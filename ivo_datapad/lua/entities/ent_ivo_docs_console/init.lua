AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("IVO_Docs_OpenConsoleUI")

function ENT:Initialize()
    self:SetModel(self:GetConsoleModel())
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end
    
    self.TempHackedBy = {} -- Tabla de jugadores que la hackearon
end

function ENT:Think()
    local mdl = self:GetConsoleModel()
    if self:GetModel() ~= mdl and mdl ~= "" then
        self:SetModel(mdl)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
    end
    
    -- Chequear estado de descarga
    if self:GetIsDownloading() then
        local ply = self:GetDownloadingPlayer()
        if not IsValid(ply) or not ply:Alive() then
            -- Solo cancela si el jugador muere o se desconecta
            self:SetIsDownloading(false)
            self:SetDownloadingPlayer(NULL)
        end
    end
    
    self:NextThink(CurTime() + 1)
    return true
end

function ENT:HasAccess(ply)
    local allowed = self:GetAccessJobs()
    if allowed == "" then return true end -- Pública
    
    -- Si es admin en staff
    if Datapad and Datapad.HasAccess and Datapad:HasAccess(ply, Datapad.Config.StaffJobs) then return true end
    
    -- Chequear si fue hackeada recientemente (Acceso global temporal)
    if CurTime() < self:GetHackedUntil() then return true end
    
    local plyJob = team.GetName(ply:Team())
    local jobs = string.Explode(",", allowed)
    for _, j in ipairs(jobs) do
        local cleanJ = string.Trim(j)
        if cleanJ ~= "" and string.find(string.lower(plyJob), string.lower(cleanJ)) then
            return true
        end
    end
    
    return false
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if self.NextUse and CurTime() < self.NextUse then return end
    self.NextUse = CurTime() + 0.5
    
    if self:GetIsDownloading() then
        if activator == self:GetDownloadingPlayer() then
            if CurTime() >= self:GetDownloadEndTime() then
                -- Finalizar extracción
                self:SetIsDownloading(false)
                self:SetDownloadingPlayer(NULL)
                activator:Give("weapon_ivo_datapad")
                activator:ChatPrint("[Consola] Datapad recuperado. Extracción exitosa.")
                
                -- Inyectar archivo
                if IVO_Docs_InjectDocument then
                    IVO_Docs_InjectDocument(activator, self:GetDocTitle(), self:GetDocContent())
                end
            else
                activator:ChatPrint("[Consola] La extracción aún está en curso. Espera.")
            end
        else
            activator:ChatPrint("[Consola] La terminal está bloqueada extrayendo datos para otro usuario.")
        end
        return
    end
    
    if self:HasAccess(activator) then
        net.Start("IVO_Docs_OpenConsoleUI")
        net.WriteEntity(self)
        net.Send(activator)
    else
        activator:ChatPrint("[Consola] Acceso denegado. Permisos insuficientes.")
        
        -- Verificar si el jugador tiene el rol necesario para hackear
        local canHack = false
        if Datapad and Datapad.HasAccess and Datapad:HasAccess(activator, Datapad.Config.HackerJobs) then
            canHack = true
        end
        
        if not canHack then
            activator:ChatPrint("[Consola] Tu unidad no posee el equipo o entrenamiento para vulnerar esta red.")
            return
        end
        
        -- Verificar si tiene el datapad activo en la mano
        local wep = activator:GetActiveWeapon()
        local hasDatapadEquipped = IsValid(wep) and wep:GetClass() == "weapon_ivo_datapad"
        
        if not hasDatapadEquipped then
            activator:ChatPrint("[Consola] Necesitas tener tu Datapad en la mano para iniciar el hackeo.")
            return
        end
        
        net.Start("Datapad_StartHack")
        net.WriteEntity(self)
        net.WriteUInt(self:GetHackDifficulty(), 16)
        
        local games = self:GetHackGames()
        if not games or games == "" then games = "1,2,3" end
        net.WriteString(games)
        
        net.Send(activator)
    end
end

function ENT:StartExtraction(ply)
    if not IsValid(ply) then return end
    if self:GetIsDownloading() then return end
    if not ply:HasWeapon("weapon_ivo_datapad") then return end
    
    ply:StripWeapon("weapon_ivo_datapad")
    self:SetIsDownloading(true)
    self:SetDownloadingPlayer(ply)
    self:SetDownloadEndTime(CurTime() + (self:GetDownloadTime() or 15))
    
    ply:ChatPrint("[Consola] Extracción iniciada. Puedes retirarte, recupera tu Datapad al terminar.")
end

-- Llamado por sv_hacking.lua cuando el minijuego de hackeo tiene éxito
function ENT:OnHackSuccess(ply)
    if not IsValid(ply) then return end
    
    -- Establecer el acceso global por 2 minutos
    self:SetHackedUntil(CurTime() + 120)
    
    -- Avisar a todos cerca que se abrieron las puertas de datos
    for _, p in ipairs(player.GetAll()) do
        if p:GetPos():Distance(self:GetPos()) < 500 then
            p:ChatPrint("[Consola] ¡Se ha vulnerado la seguridad! Terminal expuesta temporalmente.")
        end
    end
    
    -- Abrir automáticamente la consola al hacker
    net.Start("IVO_Docs_OpenConsoleUI")
    net.WriteEntity(self)
    net.Send(ply)
end
