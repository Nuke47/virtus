--[[
    Starfighter HUD - Shared Configuration
    Addon: ivo_starfighter_hud
    Version: 1.0.0
    Author: Ivo
--]]

AddCSLuaFile()

StarfighterHUD = StarfighterHUD or {}

-- Configuration Constants
StarfighterHUD.Version = "1.0.0"

-- Star Wars Themed HUD Color Palette
StarfighterHUD.Colors = {
    HUDGreen      = Color(0, 255, 100, 200), -- main HUD color
    HUDGreenDim   = Color(0, 180, 70, 120),  -- dimmed elements
    HUDRed        = Color(255, 50, 50, 200),  -- hostile/warning
    HUDBlue       = Color(80, 160, 255, 200), -- friendly
    HUDYellow     = Color(255, 200, 0, 200),  -- caution/lock
    HUDWhite      = Color(255, 255, 255, 200),
    HUDBackground = Color(0, 0, 0, 80),       -- semi-transparent bg
    Shield        = Color(50, 150, 255, 200), -- shield bar
    Health        = Color(50, 255, 100, 200), -- health bar
    Heat          = Color(255, 150, 0, 200),  -- heat/overheat
    LockOn        = Color(255, 50, 50, 255),  -- target locked
    Tracking      = Color(255, 200, 0, 180),  -- tracking in progress
}

-- Targeting and Tracking Settings
StarfighterHUD.TrackingCone = 30 -- degrees for lock cone
StarfighterHUD.MaxTargets   = 12 -- max displayed targets
StarfighterHUD.LockTime     = 1.5 -- seconds to achieve lock

---
-- Helper function to determine if an entity is an LVS vehicle.
-- Checks for ent.LVS flag, class prefix 'lvs_', or base class containing 'lvs_base'.
-- @param ent Entity to check
-- @return boolean True if entity is an LVS vehicle
---
function StarfighterHUD.IsLVSVehicle(ent)
    if not IsValid(ent) then return false end

    -- Direct LVS flag check
    if ent.LVS then return true end

    -- Class name prefix check
    local class = ent:GetClass()
    if isstring(class) and string.StartWith(string.lower(class), "lvs_") then
        return true
    end

    -- Base property check
    if ent.Base and isstring(ent.Base) and string.find(string.lower(ent.Base), "lvs_base", 1, true) then
        return true
    end

    -- BaseClass hierarchy check
    local current = ent.BaseClass
    while current do
        if current.LVS then return true end
        if current.ClassName and isstring(current.ClassName) and string.find(string.lower(current.ClassName), "lvs_base", 1, true) then
            return true
        end
        if current.Base and isstring(current.Base) and string.find(string.lower(current.Base), "lvs_base", 1, true) then
            return true
        end
        current = current.BaseClass
    end

    return false
end

---
-- Helper function to determine if an entity is specifically a starfighter-type LVS vehicle.
-- Checks if class contains 'starfighter' or base class is/contains 'lvs_base_starfighter'.
-- @param ent Entity to check
-- @return boolean True if entity is an LVS starfighter
---
function StarfighterHUD.IsStarfighter(ent)
    if not IsValid(ent) then return false end
    if not StarfighterHUD.IsLVSVehicle(ent) then return false end

    local class = ent:GetClass()
    if isstring(class) and string.find(string.lower(class), "starfighter", 1, true) then
        return true
    end

    if ent.Base and isstring(ent.Base) and string.find(string.lower(ent.Base), "lvs_base_starfighter", 1, true) then
        return true
    end

    local current = ent.BaseClass
    while current do
        if current.ClassName and isstring(current.ClassName) and string.find(string.lower(current.ClassName), "lvs_base_starfighter", 1, true) then
            return true
        end
        if current.Base and isstring(current.Base) and string.find(string.lower(current.Base), "lvs_base_starfighter", 1, true) then
            return true
        end
        current = current.BaseClass
    end

    if ent.VehicleSubCategory and isstring(ent.VehicleSubCategory) and string.lower(ent.VehicleSubCategory) == "starfighters" then
        return true
    end

    return false
end
