SW_InvShop = SW_InvShop or {}
SW_InvShop.Config = SW_InvShop.Config or {}

-- ============================================================================
-- CATEGORIAS LEGALES (Tienda Republica)
-- ============================================================================
-- Puedes usar 'levelReq = 5' en cualquier categoria o en items especificos para
-- restringir su compra y uso por nivel (requiere IVOSAM).
SW_InvShop.Config.Categories = {
    ["Armas Basicas"] = { levelReq = 1 },
    ["Apoyos"] = { allowedKeywords = { "apoyo", "pesado", "arc", "comando" }, levelReq = 5 },
    ["Asaltos"] = { allowedKeywords = { "asalto", "arc", "comando" }, levelReq = 5 },
    ["Reconocimientos"] = { allowedKeywords = { "reconocimiento", "arf", "francotirador", "arc", "comando" }, levelReq = 5 },
    ["ARC"] = { allowedKeywords = { "arc", "comando" }, levelReq = 10 },
    ["Comandantes"] = { allowedKeywords = { "comandante", "cody", "wolffee", "grey", "howzer", "fox", "hound", "thire", "stone", "director", "tarkin", "palpatine", "kalani" }, levelReq = 20 },
    ["Equipamiento"] = {},
    ["Accesorios"] = {},
    ["Municion Pesada"] = {},
}

-- ============================================================================
-- CATEGORIAS ILEGALES (Mercado Negro)
-- ============================================================================
SW_InvShop.Config.BMCategories = {
    ["Mercado Negro"] = { levelReq = 5 }, 
    ["Explosivos Ilegales"] = { levelReq = 10 },
}

SW_InvShop.Config.AmmoCategories = {
    ["Municion Pesada"] = {}, 
    ["Suministros Generales"] = {},
}

SW_InvShop.Config.UnderworldJobs = {
    "TEAM_MERCENARIO",
    "TEAM_CAZARRECOMPENSAS",
    "TEAM_CONTRABANDISTA"
}

-- Moneda del servidor: Cambia a false si no usas DarkRP/StarWarsRP derivado
SW_InvShop.Config.UseDarkRPMoney = true 

-- Limite de espacios para el Inventario Rapido
SW_InvShop.Config.MaxActiveSlots = 3

function SW_InvShop.GetItemSlot(itemID)
    local item = SW_InvShop.Config.Items[itemID]
    if not item then return 4 end
    if not item.isWeapon then return 4 end
    if item.isAmmo then return 4 end

    local class = string.lower(item.class or "")
    
    if string.find(class, "z6") or string.find(class, "rps") or string.find(class, "e60r") or string.find(class, "plx1") or string.find(class, "hh12") or string.find(class, "smartlauncher") or string.find(class, "launcher") then
        return 2 -- Especial
    end
    
    if string.find(class, "dc17") or string.find(class, "dl44") or string.find(class, "rk3") or string.find(class, "s5") or string.find(class, "dt12") or string.find(class, "dt29") or string.find(class, "dl18") or string.find(class, "se14") or string.find(class, "x8") or string.find(class, "defender") or string.find(class, "westar34") or string.find(class, "westar35") or string.find(class, "ll30") or string.find(class, "nn14") or string.find(class, "scoutblaster") or string.find(class, "ib94") or string.find(class, "pistol") then
        return 3 -- Secundaria
    end
    
    return 1 -- Principal
end

-- ============================================================================
-- LISTA MAESTRA DE ITEMS (Todas las armas juntas)
-- ============================================================================
SW_InvShop.Config.Items = {

    -- ------------------------------------------------------------------------
    -- ARMAS DE DOTACION (No se venden, no se compran, se dan al spawnear)
    -- ------------------------------------------------------------------------
    ["base_dc15s"] = {
        name = "DC-15S",
        desc = "Tipo: Carabina",
        class = "rw_sw_dc15s",
        model = "models/jajoff/sps/cgiweapons/tc13j/dc15s.mdl", 
        isWeapon = true,
        isBaseItem = true,
        category = "Asaltos"
    },
    ["base_dp24"] = {
        name = "DP-24",
        desc = "Tipo: Escopeta Pesada",
        class = "rw_sw_dp24",
        model = "models/cs574/weapons/dp24.mdl", 
        isWeapon = true,
        isBaseItem = true,
        category = "Apoyos"
    },
    ["base_dc15x"] = {
        name = "DC-15X",
        desc = "Tipo: Francotirador",
        class = "rw_sw_dc15x",
        model = "models/cs574/weapons/dc15x.mdl", 
        isWeapon = true,
        isBaseItem = true,
        category = "Reconocimientos"
    },
    ["base_dc15a"] = {
        name = "DC-15A",
        desc = "Tipo: Rifle de Asalto",
        class = "rw_sw_dc15a",
        model = "models/weapons/w_dc15a.mdl", 
        isWeapon = true,
        isBaseItem = true,
        category = "Armas Basicas"
    },
    ["base_dc17"] = {
        name = "DC-17",
        desc = "Tipo: Pistola Blaster",
        class = "rw_sw_dc17",
        model = "models/cs574/weapons/dc17.mdl", 
        isWeapon = true,
        isBaseItem = true,
        category = "Armas Basicas"
    },
    ["base_dc15le"] = {
        name = "DC-15LE",
        desc = "Tipo: Rifle de Apoyo",
        class = "rw_sw_dc15le",
        model = "models/weapons/w_dc15a.mdl", 
        isWeapon = true,
        isBaseItem = true,
        category = "Armas Basicas"
    },
    ["base_shield_cg"] = {
        name = "Escudo Antidisturbios",
        desc = "Tipo: Especial (Escudo)",
        class = "rw_sw_shield_cg",
        model = "models/weapons/w_cshield.mdl", 
        isWeapon = true,
        isBaseItem = true,
        category = "Armas Basicas"
    },
    ["base_dual_dc17"] = {
        name = "Duales DC-17",
        desc = "Tipo: Pistolas Duales",
        class = "rw_sw_dual_dc17",
        model = "models/cs574/weapons/dc17.mdl", 
        isWeapon = true,
        isBaseItem = true,
        category = "Armas Basicas"
    },

    -- ------------------------------------------------------------------------
    -- EQUIPAMIENTO DE LA REPUBLICA (Legal en Tienda)
    -- ------------------------------------------------------------------------
    ["DC-15a"] = {
        name = "DC-15A",
        class = "rw_sw_dc15a",
        desc = "Tipo: Rifle de Asalto\n\nRifle estandar de la Republica.",
        model = "models/weapons/w_dc15a.mdl",
        price = 500,
        isWeapon = true,
        category = "Armas Basicas"
    },
    ["DC-15a RN"] = {
        name = "DC-15A",
        class = "rw_sw_dc15a", 
        desc = "Tipo: Rifle de Reconocimiento\n\nVariante de precision para unidades de reconocimiento.",
        model = "models/weapons/w_dc15a.mdl",
        price = 500,
        isWeapon = true,
        category = "Reconocimientos"
    },
    ["DC-15a AP"] = {
        name = "DC-15A",
        class = "rw_sw_dc15a",
        desc = "Tipo: Rifle de Apoyo\n\nRifle adaptado para fuego de supresion.",
        model = "models/weapons/w_dc15a.mdl",
        price = 500,
        isWeapon = true,
        category = "Apoyos"
    },
    ["DP-23 AP"] = {
        name = "DP-23",
        class = "rw_sw_dp23", 
        desc = "Tipo: Escopeta\n\nEscopeta pesada ideal para pasillos cerrados.",
        model = "models/cs574/weapons/dp23.mdl",
        price = 500,
        isWeapon = true,
        category = "Apoyos"
    },
    ["Z-6 AP"] = {
        name = "Z-6",
        class = "rw_sw_z6", 
        desc = "Tipo: Especial (Rotativa)\n\nCanon rotativo devastador. Requiere fuerza para operarlo.",
        model = "models/sw_battlefront/weapons/z6_rotary_cannon.mdl",
        price = 500,
        isWeapon = true,
        category = "Apoyos"
    },
    ["Valken 38a AP"] = {
        name = "Valken 38A",
        class = "rw_sw_valkenx38a", 
        desc = "Tipo: Carabina\n\nRifle de alta cadencia.",
        model = "models/sw_battlefront/weapons/valken_noscope.mdl",
        price = 500,
        isWeapon = true,
        category = "Apoyos"
    },
    ["DC-15a CMD"] = {
        name = "DC-15A",
        class = "rw_sw_dc15a", 
        desc = "Tipo: Rifle de Asalto\n\nRifle estandar con modificaciones para comandantes.",
        model = "models/weapons/w_dc15a.mdl",
        price = 500,
        isWeapon = true,
        category = "Comandantes"
    },
    ["Z-6 CMD"] = {
        name = "Z-6",
        class = "rw_sw_z6", 
        desc = "Tipo: Especial (Rotativa)\n\nCanon rotativo devastador. Requiere fuerza para operarlo.",
        model = "models/sw_battlefront/weapons/z6_rotary_cannon.mdl",
        price = 250000,
        isWeapon = true,
        category = "Comandantes"
    },
    ["E-11 (Asalto)"] = {
        name = "E-11",
        class = "rw_sw_e11",
        desc = "Tipo: Rifle de Asalto\n\nRifle estandar imperial, alto dano y retroceso moderado.",
        model = "models/weapons/w_e11.mdl",
        price = 1000,
        isWeapon = true,
        category = "Asaltos"
    },
    ["CR-2"] = {
        name = "CR-2",
        class = "rw_sw_cr2",
        desc = "Tipo: Carabina\n\nArma compacta de asalto rapido.",
        model = "models/cs574/weapons/cr2.mdl",
        price = 1200,
        isWeapon = true,
        category = "Asaltos"
    },
    ["DLT-19"] = {
        name = "DLT-19",
        class = "rw_sw_dlt19",
        desc = "Tipo: Rifle de Apoyo\n\nArma de repeticion pesada. Ideal para fuego de supresion.",
        model = "models/weapons/w_dlt19.mdl",
        price = 2000,
        isWeapon = true,
        category = "Apoyos"
    },
    ["T-21"] = {
        name = "T-21",
        class = "rw_sw_t21",
        desc = "Tipo: Rifle Pesado\n\nRifle pesado de largo alcance y cadencia lenta.",
        model = "models/weapons/w_t21.mdl",
        price = 2200,
        isWeapon = true,
        category = "Apoyos"
    },
    ["Valken-38x"] = {
        name = "Valken-38X",
        class = "rw_sw_valken38x",
        desc = "Tipo: Francotirador\n\nRifle de precision de alto calibre.",
        model = "models/sw_battlefront/weapons/valken_noscope.mdl",
        price = 3000,
        isWeapon = true,
        category = "Reconocimientos"
    },
    ["DLT-19x"] = {
        name = "DLT-19X",
        class = "rw_sw_dlt19x",
        desc = "Tipo: Francotirador\n\nVariante de precision imperial del DLT-19.",
        model = "models/weapons/w_dlt19.mdl",
        price = 3200,
        isWeapon = true,
        category = "Reconocimientos"
    },
    ["Dual DC-17"] = {
        name = "Duales DC-17",
        class = "rw_sw_dual_dc17",
        desc = "Tipo: Pistolas Duales\n\nDos pistolas blaster, potencia letal a corta distancia.",
        model = "models/cs574/weapons/dc17.mdl",
        price = 4000,
        isWeapon = true,
        category = "ARC"
    },
    ["Westar-M5"] = {
        name = "Westar-M5",
        class = "rw_sw_westarm5",
        desc = "Tipo: Rifle de Asalto\n\nRifle de asalto avanzado preferido por los ARC.",
        model = "models/cs574/weapons/westarm5.mdl",
        price = 4500,
        isWeapon = true,
        category = "ARC"
    },
    ["E-11D"] = {
        name = "E-11D",
        class = "rw_sw_e11d",
        desc = "Tipo: Rifle de Asalto\n\nVariante altamente letal para unidades especiales y Shadow Unit.",
        model = "models/weapons/w_e11d.mdl",
        price = 4500,
        isWeapon = true,
        category = "Asaltos"
    },
    ["TL-50"] = {
        name = "TL-50",
        class = "rw_sw_tl50",
        desc = "Tipo: Repetidor Pesado\n\nArma especial con fuego alternario letal.",
        model = "models/weapons/w_tl50.mdl",
        price = 5000,
        isWeapon = true,
        category = "Apoyos"
    },
    ["RK-3"] = {
        name = "RK-3",
        class = "rw_sw_rk3",
        desc = "Tipo: Pistola\n\nPistola imperial confiable para oficiales.",
        model = "models/weapons/w_rk3.mdl",
        price = 1500,
        isWeapon = true,
        category = "Comandantes"
    },
    ["DL-44"] = {
        name = "DL-44",
        class = "rw_sw_dl44",
        desc = "Tipo: Pistola Pesada\n\nPistola de alto dano, util para el alto mando.",
        model = "models/weapons/w_dl44.mdl",
        price = 2000,
        isWeapon = true,
        category = "Comandantes"
    },
    ["EE-3 Mercenario"] = {
        name = "EE-3",
        class = "rw_sw_ee3",
        desc = "Tipo: Rifle de Rafagas\n\nBlaster de rafagas sin numero de serie. Rastreo imposible.",
        model = "models/sw_battlefront/weapons/ee3_blaster_rifle.mdl",
        price = 2500,
        isWeapon = true,
        isContraband = true,
        category = "Mercado Negro"
    },
    ["Detonador Termal Clandestino"] = {
        name = "Detonador Termal",
        class = "rw_sw_thermaldetonator",
        desc = "Tipo: Explosivo\n\nExplosivo inestable de alto rendimiento. Prohibido por la Republica.",
        model = "models/weapons/w_eq_fraggrenade.mdl",
        price = 1500,
        isWeapon = true,
        isContraband = true,
        category = "Explosivos Ilegales"
    },
    ["bg_macrobinocular"] = {
        name = "Visor Macrobinocular",
        class = "bg_unlock", 
        desc = "Permite equipar visores y macrobinoculares en el configurador de armadura.",
        model = "models/aussiwozzi/cgi/base/unassigned_trp.mdl", 
        preview_auto_bino = true,
        preview_cam = Vector(40, 0, 65),
        preview_lookat = Vector(0, 0, 65),
        preview_spin = false,
        price = 1000,
        isWeapon = false,
        category = "Equipamiento"
    },
    ["bg_jetpack"] = {
        name = "Jetpack",
        class = "bg_unlock", 
        desc = "Permite equipar un Jetpack en el configurador de armadura.",
        model = "models/aussiwozzi/cgi/base/unassigned_arc.mdl", 
        preview_auto_jetpack = true,
        preview_cam = Vector(-40, 0, 50),
        preview_lookat = Vector(0, 0, 50),
        preview_spin = false,
        price = 2500,
        isWeapon = false,
        category = "Equipamiento"
    },
    ["bg_jumpack"] = {
        name = "Jumpack",
        class = "bg_unlock", 
        desc = "Permite equipar un Jumpack en el configurador de armadura.",
        model = "models/aussiwozzi/cgi/base/unassigned_arc.mdl", 
        preview_auto_jumpack = true,
        preview_cam = Vector(-40, 0, 50),
        preview_lookat = Vector(0, 0, 50),
        preview_spin = false,
        price = 2000,
        isWeapon = false,
        category = "Equipamiento"
    },
    ["bg_backpack"] = {
        name = "Mochila Tactica",
        class = "bg_unlock", 
        desc = "Permite equipar mochilas o equipamiento en la espalda.",
        model = "models/aussiwozzi/cgi/base/unassigned_trp.mdl", 
        price = 1500,
        isWeapon = false,
        category = "Equipamiento"
    },
    ["bg_rangefinder"] = {
        name = "Visor Rangefinder",
        class = "bg_unlock", 
        desc = "Permite equipar un Rangefinder (Visor Infrarrojo Tactico).",
        model = "models/aussiwozzi/cgi/base/unassigned_trp.mdl", 
        preview_auto_bino = true,
        preview_cam = Vector(40, 0, 65),
        preview_lookat = Vector(0, 0, 65),
        preview_spin = false,
        price = 1200,
        isWeapon = false,
        category = "Accesorios"
    },
    ["base_defibrillator"] = {
        name = "Desfibrilador",
        class = "weapon_defibrillator",
        model = "models/weapons/w_defibrillator.mdl",
        isWeapon = true,
        isBaseItem = true,
        category = "Armas Basicas"
    }
}

-- ============================================================================
-- LOGICA DE DESBLOQUEO DE BODYGROUPS
-- ============================================================================
SW_InvShop.Config.BodygroupUnlocks = {
    ["bg_macrobinocular"] = { keywords = {"bino", "macrobinocular", "visor"}, excludes = {"sunvisor"} },
    ["bg_rangefinder"] = {"rangefinder", "range finder", "antenna", "rf"},
    ["bg_jetpack"] = { keywords = {"jetpack", "jet pack"}, excludes = {"cody", "arc", "backpack", "mochila", "bag", "pack"} },
    ["bg_jumpack"] = {"jumpack", "jump pack", "cody jetpack"},
    ["bg_backpack"] = { keywords = {"backpack", "mochila", "bag", "pack"}, excludes = {"arc", "attachment", "jetpack", "jet pack", "jumpack", "jump pack", "cody"} }
}

function SW_InvShop.HasBodygroupAccess(ply, bgName, subName)
    if not SW_InvShop.Config.BodygroupUnlocks then return true end
    
    bgName = string.lower(bgName or "")
    subName = string.lower(subName or "")
    
    local matchedItems = {}
    local requiresAny = false

    for itemID, config in pairs(SW_InvShop.Config.BodygroupUnlocks) do
        local keywords = config
        local excludes = {}
        if config.keywords then
            keywords = config.keywords
            excludes = config.excludes or {}
        end

        for _, keyword in ipairs(keywords) do
            keyword = string.lower(keyword)
            
            local matched = false
            if string.find(subName, keyword) then
                matched = true
            elseif (string.find(bgName, "bino") or string.find(bgName, "visor")) and (string.find(subName, "up") or string.find(subName, "down")) then
                matched = true
            end
            
            if matched then
                for _, excl in ipairs(excludes) do
                    if string.find(subName, string.lower(excl)) then
                        matched = false
                        break
                    end
                end
            end
            
            if matched then
                requiresAny = true
                matchedItems[itemID] = true
                break
            end
        end
    end

    if not requiresAny then return true end

    -- Revisa si el jugador posee AL MENOS UNO de los items requeridos
    for itemID, _ in pairs(matchedItems) do
        if SERVER then
            if ply.SW_Data and (ply.SW_Data.active[itemID] or ply.SW_Data.armario[itemID]) then
                return true
            end
        else
            if SW_InvShop.ActiveInv and SW_InvShop.ActiveInv[itemID] then return true end
            if SW_InvShop.Armario and SW_InvShop.Armario[itemID] then return true end
        end
    end

    return false
end

-- ============================================================================
-- LOADOUTS INICIALES POR TRABAJO
-- ============================================================================
SW_InvShop.Config.StarterLoadouts = {
    -- Clases Base
    ["Cadete"] = { "base_dc15a" },
    ["Soldado"] = { "base_dc15a", "base_dc17" },
    ["CT"] = { "base_dc15a", "base_dc17" },
    ["SU"] = { "base_dc15a", "base_dc17" },
    ["SH"] = { "base_dc15a", "base_dc17" },
    ["Agente"] = { "base_dc15a", "base_dc17" },
    ["Especialista"] = { "base_dc15a", "base_dc17" },
    ["Apoyo"] = { "base_dp24", "base_dc17" },
    ["Asalto"] = { "base_defibrillator", "base_dc15s", "base_dc17" },
    ["Reconocimiento"] = { "base_dc15x", "base_dc17" },
    ["ARF"] = { "base_dc15x", "base_dc17" },
    ["ARC"] = { "base_dc15a", "base_dc17" },
    ["Comandante"] = { "base_dc15s", "base_dual_dc17" },
    ["Tarkin"] = { "base_dc17" },
    
    -- Modificadores / Equipamiento Extra
    ["RT"] = { "base_dc15le", "base_shield_cg" },
    ["SAR"] = { "base_squadshield" },
    
    -- Iconicos
    ["Cody"] = { "base_dc15s", "base_dual_dc17" },
    ["Wolffee"] = { "base_dc15s", "base_dual_dc17" },
    ["Grey"] = { "base_dc15s", "base_dual_dc17" },
    ["Howzer"] = { "base_dc15s", "base_dual_dc17" },
    ["Fox"] = { "base_dc15s", "base_dual_dc17" },
    ["Hound"] = { "base_dc15s", "base_dual_dc17" },
    ["Thire"] = { "base_dc15s", "base_dual_dc17" },
    ["Stone"] = { "base_dc15s", "base_dual_dc17" }
}

-- ============================================================================
-- MUNICION (Agregada al final para no romper la tabla principal)
-- ============================================================================
SW_InvShop.Config.Items["RPG_Ammo_Pack"] = {
    name = "Cargador de Misiles RPG",
    class = "RPG_Round", 
    desc = "Pack de 3 misiles explosivos para lanzacohetes RPS.",
    model = "models/Items/BoxSRound.mdl",
    price = 250,
    isAmmo = true,
    ammoType = "RPG_Round",
    ammoCount = 3,
    category = "Municion Pesada"
}

SW_InvShop.Config.Items["Z6_Ammo_Pack"] = {
    name = "Nucleo de Bateria Z-6",
    class = "sw_mag_z6", 
    desc = "Bateria rotatoria para el canon Z-6.",
    model = "models/items/battery.mdl",
    price = 150,
    isAmmo = true,
    ammoType = "sw_mag_z6",
    ammoCount = 1,
    category = "Municion Pesada"
}
