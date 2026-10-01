ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Consola de Datos"
ENT.Category = "Ivo Datapad"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "ConsoleModel")
    self:NetworkVar("String", 1, "AccessJobs")
    self:NetworkVar("String", 2, "DocTitle")
    self:NetworkVar("String", 3, "DocContent")
    
    self:NetworkVar("Int", 0, "HackDifficulty")
    self:NetworkVar("Int", 1, "DownloadTime")
    
    self:NetworkVar("Bool", 0, "IsDownloading")
    self:NetworkVar("Float", 0, "DownloadEndTime")
    self:NetworkVar("Entity", 0, "DownloadingPlayer")
    self:NetworkVar("Float", 1, "HackedUntil")
    
    if SERVER then
        self:SetConsoleModel("models/props_lab/monitor01a.mdl")
        self:SetAccessJobs("")
        self:SetHackDifficulty(45)
        self:SetDocTitle("ARCHIVO ENCRIPTADO")
        self:SetDocContent("El servidor de datos ha sido inicializado sin contenido...")
        self:SetDownloadTime(15) -- 15 segundos por defecto
        self:SetIsDownloading(false)
    end
end

-- Custom accessors for HackGames since NetworkVar only supports 4 string slots
function ENT:SetHackGames(val)
    self:SetNWString("HackGames", val)
end

function ENT:GetHackGames()
    return self:GetNWString("HackGames", "1,2,3")
end
