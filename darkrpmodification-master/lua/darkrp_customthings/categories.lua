--[[-----------------------------------------------------------------------
Categories
---------------------------------------------------------------------------
The categories of the default F4 menu.

Please read this page for more information:
https://darkrp.miraheze.org/wiki/DarkRP:Categories

In case that page can't be reached, here's an example with explanation:

DarkRP.createCategory{
    name = "Citizens", -- The name of the category.
    categorises = "jobs", -- What it categorises. MUST be one of "jobs", "entities", "shipments", "weapons", "vehicles", "ammo".
    startExpanded = true, -- Whether the category is expanded when you open the F4 menu.
    color = Color(0, 107, 0, 255), -- The color of the category header.
    canSee = function(ply) return true end, -- OPTIONAL: whether the player can see this category AND EVERYTHING IN IT.
    sortOrder = 100, -- OPTIONAL: With this you can decide where your category is. Low numbers to put it on top, high numbers to put it on the bottom. It's 100 by default.
}


Add new categories under the next line!
---------------------------------------------------------------------------]]

DarkRP.createCategory({
    name = "Cadetes", -- Nombre exacto que aparecerá en el F4 y tu menú IVO
    categorises = "jobs",        -- Le decimos a DarkRP que es una categoría para trabajos
    startExpanded = true,        -- Aparece desplegada por defecto en el F4 nativo
    color = Color(255, 240, 105), -- Color azul institucional para la identidad visual
    canSee = function(ply) return true end, -- Todos los jugadores pueden ver la categoría
    sortOrder = 1               -- Posición en la lista (puedes ajustarlo)
})


DarkRP.createCategory({
    name = "Clone Troopers", -- Nombre exacto que aparecerá en el F4 y tu menú IVO
    categorises = "jobs",        -- Le decimos a DarkRP que es una categoría para trabajos
    startExpanded = true,        -- Aparece desplegada por defecto en el F4 nativo
    color = Color(228, 228, 228), -- Color azul institucional para la identidad visual
    canSee = function(ply) return true end, -- Todos los jugadores pueden ver la categoría
    sortOrder = 2               -- Posición en la lista (puedes ajustarlo)
})

-- Agrega esto en darkrp_customthings/categories.lua

DarkRP.createCategory({
    name = "Shadow Unit", -- Nombre exacto que aparecerá en el F4 y tu menú IVO
    categorises = "jobs",
    startExpanded = true,
    color = Color(35, 13, 48), -- Un color rojo oscuro/mafia para la barra
    canSee = function(ply) return true end, -- Todos pueden ver esta categoría
    sortOrder = 4, -- Orden de posición en el menú F4
})

-- Agrega esto en darkrp_customthings/categories.lua
DarkRP.createCategory({
    name = "Shock Troopers",
    categorises = "jobs",
    startExpanded = true,
    color = Color(165, 47, 47), -- Un color rojo oscuro/mafia para la barra
    canSee = function(ply) return true end, -- Todos pueden ver esta categoría
    sortOrder = 3, -- Orden de posición en el menú F4
})

-- Agrega esto en darkrp_customthings/categories.lua

-- Agrega esto en darkrp_customthings/categories.lua
DarkRP.createCategory({
    name = "Altos Mandos",
    categorises = "jobs",
    startExpanded = true,
    color = Color(36, 37, 37), -- Un color rojo oscuro/mafia para la barra
    canSee = function(ply) return true end, -- Todos pueden ver esta categoría
    sortOrder = 5, -- Orden de posición en el menú F4
})

-- Agrega esto en darkrp_customthings/categories.lua
DarkRP.createCategory({
    name = "Inquisidores",
    categorises = "jobs",
    startExpanded = true,
    color = Color(196, 106, 65), -- Un color rojo oscuro/mafia para la barra
    canSee = function(ply) return true end, -- Todos pueden ver esta categoría
    sortOrder = 11, -- Orden de posición en el menú F4
})

-- Agrega esto en darkrp_customthings/categories.lua
DarkRP.createCategory({
    name = "STAFF",
    categorises = "jobs",
    startExpanded = true,
    color = Color(87, 187, 253), -- Un color rojo oscuro/mafia para la barra
    canSee = function(ply) return true end, -- Todos pueden ver esta categoría
    sortOrder = 12, -- Orden de posición en el menú F4
})

DarkRP.createCategory({
    name = "Bad Batch", -- Nombre exacto que aparecerá en el F4 y tu menú IVO
    categorises = "jobs",        -- Le decimos a DarkRP que es una categoría para trabajos
    startExpanded = true,        -- Aparece desplegada por defecto en el F4 nativo
    color = Color(42, 45, 51), -- Color azul institucional para la identidad visual
    canSee = function(ply) return true end, -- Todos los jugadores pueden ver la categoría
    sortOrder = 7               -- Posición en la lista (puedes ajustarlo)
})

DarkRP.createCategory({
    name = "Red Clandestina Clon", -- Nombre exacto que aparecerá en el F4 y tu menú IVO
    categorises = "jobs",        -- Le decimos a DarkRP que es una categoría para trabajos
    startExpanded = true,        -- Aparece desplegada por defecto en el F4 nativo
    color = Color(103, 135, 199), -- Color azul institucional para la identidad visual
    canSee = function(ply) return true end, -- Todos los jugadores pueden ver la categoría
    sortOrder = 8             -- Posición en la lista (puedes ajustarlo)
})

DarkRP.createCategory({
    name = "Colectivo Sombra", -- Nombre exacto que aparecerá en el F4 y tu menú IVO
    categorises = "jobs",        -- Le decimos a DarkRP que es una categoría para trabajos
    startExpanded = true,        -- Aparece desplegada por defecto en el F4 nativo
    color = Color(228, 73, 73), -- Color azul institucional para la identidad visual
    canSee = function(ply) return true end, -- Todos los jugadores pueden ver la categoría
    sortOrder = 9           -- Posición en la lista (puedes ajustarlo)
})

DarkRP.createCategory({
    name = "CIS",
    categorises = "jobs",
    startExpanded = true,
    color = Color(0, 58, 173),
    canSee = function(ply) return true end,
    sortOrder = 10
})

DarkRP.createCategory({
    name = "Trandoshanos",
    categorises = "jobs",
    startExpanded = true,
    color = Color(50, 150, 50),
    canSee = function(ply) return true end,
    sortOrder = 13
})

DarkRP.createCategory({
    name = "Sol Negro",
    categorises = "jobs",
    startExpanded = true,
    color = Color(20, 20, 20),
    canSee = function(ply) return true end,
    sortOrder = 14
})

DarkRP.createCategory({
    name = "Iconicos Enemigos",
    categorises = "jobs",
    startExpanded = true,
    color = Color(150, 50, 50),
    canSee = function(ply) return true end,
    sortOrder = 15
})