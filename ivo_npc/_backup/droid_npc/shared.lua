ENT.Base = "base_nextbot"
ENT.Type = "nextbot"

-- Este es el registro oficial que lo mueve a la pestaña PNJ
list.Set( "NPC", "npc_droide", {
    Name = "Droide B1 Hostil",   -- El nombre que verás en la lista
    Class = "npc_droide",        -- IMPORTANTE: Este debe ser el nombre exacto de la carpeta de tu entidad
    Category = "Star Wars"       -- La categoría/carpeta que se creará dentro de la pestaña PNJ
} )