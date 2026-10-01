local function GetArmarioSaveFile()
    return "sw_armarios_" .. game.GetMap() .. ".json"
end

local function SaveArmarios(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("Solo superadmins pueden guardar los armarios.")
        return
    end

    local armarios = {}
    for _, ent in ipairs(ents.FindByClass("sw_armario")) do
        table.insert(armarios, {
            pos = ent:GetPos(),
            ang = ent:GetAngles()
        })
    end

    file.Write(GetArmarioSaveFile(), util.TableToJSON(armarios, true))
    
    if IsValid(ply) then
        ply:ChatPrint("Se han guardado " .. #armarios .. " armarios permanentemente en " .. game.GetMap() .. ".")
    else
        print("Armarios guardados para el mapa " .. game.GetMap() .. ".")
    end
end
concommand.Add("sw_savearmarios", SaveArmarios)

local function LoadArmarios()
    if file.Exists(GetArmarioSaveFile(), "DATA") then
        local data = util.JSONToTable(file.Read(GetArmarioSaveFile(), "DATA") or "[]")
        if data then
            for _, t in ipairs(data) do
                local ent = ents.Create("sw_armario")
                if IsValid(ent) then
                    ent:SetPos(t.pos)
                    ent:SetAngles(t.ang)
                    ent:Spawn()
                    local phys = ent:GetPhysicsObject()
                    if IsValid(phys) then 
                        phys:EnableMotion(false)
                        phys:Sleep()
                    end
                end
            end
        end
    end
end
hook.Add("InitPostEntity", "SW_LoadArmarios", LoadArmarios)
hook.Add("PostCleanupMap", "SW_LoadArmarios", LoadArmarios)
