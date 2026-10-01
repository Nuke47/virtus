-- Servidor: Gestión de Persistencia (SQLite)
if not SERVER then return end

v_bodygroups = v_bodygroups or {}

-- Guardar los bodygroups actuales del jugador
function v_bodygroups.SavePlayerBodygroups(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    
    local model = ply:GetModel()
    local bgData = {}

    -- Recorremos todos los bodygroups editables del modelo actual
    for i = 0, ply:GetNumBodyGroups() - 1 do
        bgData[i] = ply:GetBodygroup(i)
    end

    -- Guardamos también el skin por si acaso
    local dataToSave = {
        skin = ply:GetSkin(),
        bodygroups = bgData
    }

    -- Guardamos en formato JSON asociado al modelo para que si cambia de modelo no se rompa
    local key = "v_bg_" .. string.Explode("/", model)[#string.Explode("/", model)]
    ply:SetPData(key, util.TableToJSON(dataToSave))
end

-- Cargar y aplicar los bodygroups guardados
function v_bodygroups.LoadPlayerBodygroups(ply)
    if not IsValid(ply) then return end
    
    local model = ply:GetModel()
    local key = "v_bg_" .. string.Explode("/", model)[#string.Explode("/", model)]
    local savedData = ply:GetPData(key)

    if savedData then
        local data = util.JSONToTable(savedData)
        if data then
            ply.v_SavedBGsCache = ply.v_SavedBGsCache or {}
            
            -- Aplicar Skin
            if data.skin then 
                ply:SetSkin(data.skin) 
                ply.v_SavedSkinsCache = data.skin
            end
            
            -- Aplicar Bodygroups
            if data.bodygroups then
                for bgID, value in pairs(data.bodygroups) do
                    local numID, numVal = tonumber(bgID), tonumber(value)
                    ply:SetBodygroup(numID, numVal)
                    ply.v_SavedBGsCache[numID] = numVal
                end
            end
        end
    end
end

-- Detour para atrapar CUALQUIER cambio de modelo (Ej: Scripts de Admin, Cambio de Trabajo)
local meta = FindMetaTable("Player")
if not meta.v_bodygroups_OldSetModel then
    meta.v_bodygroups_OldSetModel = meta.SetModel
    function meta:SetModel(mdl)
        if not IsValid(self) then 
            self:v_bodygroups_OldSetModel(mdl)
            return 
        end
        
        local oldMdl = self:GetModel() or ""
        self:v_bodygroups_OldSetModel(mdl)
        
        local newMdl = self:GetModel() or ""
        if string.lower(oldMdl) ~= string.lower(newMdl) then
            self.v_SavedSkinsCache = 0
            self.v_SavedBGsCache = {}
            self:SetSkin(0)
            for i = 0, self:GetNumBodyGroups() - 1 do self:SetBodygroup(i, 0) end
            
            -- GMod Quirk: El cliente necesita un instante para registrar el nuevo modelo antes de aceptar bodygroups
            timer.Simple(0.1, function()
                if not IsValid(self) or self:GetModel() ~= newMdl then return end
                
                -- Limpieza forzada tras asentar el modelo
                self:SetSkin(0)
                for i = 0, self:GetNumBodyGroups() - 1 do self:SetBodygroup(i, 0) end

                -- Cargar desde Base de Datos (Aislado completamente por nombre de modelo)
                v_bodygroups.LoadPlayerBodygroups(self)
            end)
        end
    end
end

-- Hooks automáticos para guardar y cargar al spawnear o desconectarse
hook.Add("PlayerSpawn", "v_bodygroups_LoadOnSpawn", function(ply)
    -- Pequeño delay para asegurar que el modelo se aplicó correctamente si hay sistemas de Ranks/Jobs
    timer.Simple(0.5, function()
        if IsValid(ply) then
            v_bodygroups.LoadPlayerBodygroups(ply)
        end
    end)
end)

hook.Add("PlayerDisconnected", "v_bodygroups_SaveOnDisconnect", function(ply)
    v_bodygroups.SavePlayerBodygroups(ply)
end)