VIRTUS_CHAT = VIRTUS_CHAT or {}

-- ============================================================================
-- VIRTUS CHATBOX: THEME & CONFIG
-- ============================================================================

-- Colores base del diseño translúcido moderno
VIRTUS_CHAT.Colors = {
    Background = Color(5, 5, 10, 220),
    Header = Color(10, 15, 20, 240),
    Outline = Color(0, 150, 255, 30),
    TabActive = Color(0, 150, 255, 255),
    TabInactive = Color(150, 150, 150, 150),
    TabBgActive = Color(0, 150, 255, 20),
    TabBgInactive = Color(255, 255, 255, 5),
    InputBox = Color(10, 15, 20, 245),
    InputText = Color(255, 255, 255, 255),
    Placeholder = Color(150, 150, 150, 150),
    Scrollbar = Color(150, 150, 150, 30),
    ScrollbarGrip = Color(0, 150, 255, 150),
    ServerMsg = Color(255, 200, 100),
    OOC = Color(100, 200, 255),
    PM = Color(255, 150, 150),
}

-- Definición de fuentes
function VIRTUS_CHAT.UpdateFonts(scale)
    scale = scale or 1
    surface.CreateFont("VChat_Title",         { font = "SansSerifFLF", size = 22 * scale, weight = 400, antialias = true })
    surface.CreateFont("VChat_Tab",           { font = "SansSerifFLF", size = 14 * scale, weight = 400, antialias = true })
    surface.CreateFont("VChat_Msg",           { font = "SansSerifFLF", size = 16 * scale, weight = 400, antialias = true, extended = true })
    surface.CreateFont("VChat_MsgThin",       { font = "SansSerifFLF", size = 16 * scale, weight = 300, antialias = true, extended = true })
    surface.CreateFont("VChat_MsgBold",       { font = "SansSerifFLF", size = 16 * scale, weight = 600, antialias = true, extended = true })
    surface.CreateFont("VChat_ServerMsg",     { font = "SansSerifFLF", size = 16 * scale, weight = 400, antialias = true, extended = true })
    surface.CreateFont("VChat_ServerMsgBold", { font = "SansSerifFLF", size = 16 * scale, weight = 600, antialias = true, extended = true })
    surface.CreateFont("VChat_Input",         { font = "SansSerifFLF", size = 16 * scale, weight = 400, antialias = true, extended = true })
    surface.CreateFont("VChat_Rank",          { font = "SansSerifFLF", size = 14 * scale, weight = 700, antialias = true, extended = true })
    surface.CreateFont("VChat_RankThin",      { font = "SansSerifFLF", size = 14 * scale, weight = 300, antialias = true, extended = true })
    surface.CreateFont("VChat_Time",          { font = "SansSerifFLF", size = 15 * scale, weight = 500, antialias = true })
end
VIRTUS_CHAT.UpdateFonts(cookie.GetNumber("VirtusChat_Scale", 1))

-- Función de desenfoque
local blur = Material("pp/blurscreen")
function VIRTUS_CHAT.DrawBlur(panel, amount)
    local x, y = panel:LocalToScreen(0, 0)
    local scrW, scrH = ScrW(), ScrH()
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blur)
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * (amount or 6))
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
    end
end

-- Configuración cacheada del servidor
VIRTUS_CHAT_CONFIG = VIRTUS_CHAT_CONFIG or {}

net.Receive("VirtusChat_SyncConfig", function()
    VIRTUS_CHAT_CONFIG = net.ReadTable() or {}
end)

-- Tablas de configuración hardcodeadas
VIRTUS_CHAT.CustomTagsBySteamID = {
    ["STEAM_0:0:209652079"] = { name = "CEO", color = Color(255, 50, 50) },
    -- Agrega más SteamIDs aquí siguiendo el mismo formato
}

VIRTUS_CHAT.CustomTagsByRank = {
    ["superadmin"] = { name = "EJECUTIVO VIRTUS", color = Color(255, 50, 50) },
    ["moderador"] = { name = "MODERADOR", color = Color(0, 150, 255) },
    ["vipultimate"] = { name = "VIP ULTIMATE", color = Color(255, 200, 0) },
    -- Agrega más rangos de SAM aquí
}

-- Función para parsear rangos del chatbox
function VIRTUS_CHAT.GetPlayerRankInfo(ply)
    if not IsValid(ply) then return "USUARIO", Color(200, 200, 200) end
    
    local group = ply:GetUserGroup()
    local steamID = ply:SteamID()
    
    local name = "USUARIO"
    local color = Color(150, 150, 150)
    
    -- Prioridad 1: SteamID personalizado
    if VIRTUS_CHAT.CustomTagsBySteamID[steamID] then
        name = VIRTUS_CHAT.CustomTagsBySteamID[steamID].name
        color = VIRTUS_CHAT.CustomTagsBySteamID[steamID].color
    -- Prioridad 2: Rango personalizado de SAM
    elseif VIRTUS_CHAT.CustomTagsByRank[group] then
        name = VIRTUS_CHAT.CustomTagsByRank[group].name
        color = VIRTUS_CHAT.CustomTagsByRank[group].color
    -- Prioridad 3: Resto de rangos / default
    else
        if group == "user" then
            name = "USUARIO"
            color = Color(150, 150, 150)
        else
            -- Si creas un rango nuevo en SAM pero no lo pones en la tabla, usará el nombre del rango
            name = string.upper(group)
            color = Color(150, 150, 150)
        end
    end

    return name, color, false
end
