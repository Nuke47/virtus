AddCSLuaFile()

MISSION_SYSTEM = MISSION_SYSTEM or {}
MISSION_SYSTEM.Missions = MISSION_SYSTEM.Missions or {}

if SERVER then
    util.AddNetworkString("IvoQuest_SyncMissions")

    -- Misiones por defecto (Ahora con la nueva estructura de Diálogos y Audio)
    local defaultMissions = {
        ["default"] = {
            Name = "Desconocido",
            NPCName = "Ciudadano",
            Model = "models/Humans/Group01/Male_07.mdl",
            VoiceFolder = "",
            Dialogues = { { Text = "Ahora no tengo tiempo para hablar.", AudioFile = "" } },
            Type = "none"
        },
        ["prueba_zona"] = {
            Name = "Emboscada Combine",
            NPCName = "Comandante Rebelde",
            Model = "models/player/barney.mdl",
            VoiceFolder = "ivo_quest/comandante/", -- Carpeta de prueba para futuros audios
            Dialogues = {
                { Text = "Detectamos movimiento en el Sector Alfa.", AudioFile = "" },
                { Text = "Ve hacia el marcador, asegura la zona y vuelve vivo.", AudioFile = "" }
            },
            Type = "kill", Target = "npc_combine_s", TargetName = "Soldados Combine", 
            ReqAmount = 4, RequireReturn = true, SpawnZone = "sector_alfa", SpawnEntity = "npc_combine_s",
            SpawnAmount = 4, IsRepeatable = true, RepeatCooldown = 120, Instanced = true, -- ¡MAGIA DEL FASEO ACTIVADA!
            InProgressText = "Sigue el radar hacia el Sector Alfa. ¡Ve con cuidado!",
            ReadyText = "Escuché los disparos desde aquí. Buen trabajo."
        }
    }

    function MISSION_SYSTEM.SaveDB()
        file.CreateDir("ivo_quest")
        file.Write("ivo_quest/missions_db.json", util.TableToJSON(MISSION_SYSTEM.Missions, true))
    end

    function MISSION_SYSTEM.LoadDB()
        if not file.Exists("ivo_quest/missions_db.json", "DATA") then
            MISSION_SYSTEM.Missions = defaultMissions
            MISSION_SYSTEM.SaveDB()
        else
            MISSION_SYSTEM.Missions = util.JSONToTable(file.Read("ivo_quest/missions_db.json", "DATA")) or defaultMissions
        end
    end
    hook.Add("Initialize", "IvoQuest_LoadDB", MISSION_SYSTEM.LoadDB)

    -- Sincronizamos la base de datos completa a los jugadores al entrar
    hook.Add("PlayerInitialSpawn", "IvoQuest_SendDB", function(ply)
        timer.Simple(2, function()
            if IsValid(ply) then
                local compressed = util.Compress(util.TableToJSON(MISSION_SYSTEM.Missions))
                net.Start("IvoQuest_SyncMissions")
                net.WriteUInt(#compressed, 32)
                net.WriteData(compressed, #compressed)
                net.Send(ply)
            end
        end)
    end)
else
    -- CLIENTE RECIBE LA BASE DE DATOS
    net.Receive("IvoQuest_SyncMissions", function()
        local len = net.ReadUInt(32)
        local data = net.ReadData(len)
        local uncompressed = util.Decompress(data)
        MISSION_SYSTEM.Missions = util.JSONToTable(uncompressed) or {}
    end)
end