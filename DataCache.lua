-- Core/Constants.lua
-- Handles all cache functions
local ADDON_NAME, ns = ...

-- Grab the addon name and the shared addon namespace table
local addonName, addonTable = ... 

-- Create our helper function to generate the key
function addonTable:GetPlayerKey()
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    return playerName .. "-" .. realmName
end

-- Create a function to initialize and return the current player's data
function addonTable:InitPlayerCache()
    -- Ensure the global save exists
    ThornCraftCache = ThornCraftCache or {}
    
    local playerKey = self:GetPlayerKey()
    
    -- Ensure this specific character's folder exists
    ThornCraftCache[playerKey] = ThornCraftCache[playerKey] or {}
    
    -- Set up their internal tables
    ThornCraftCache[playerKey]["KnownProfessions"] = ThornCraftCache[playerKey]["KnownProfessions"] or {}
    ThornCraftCache[playerKey]["Professions"] = ThornCraftCache[playerKey]["Professions"] or {}
    ThornCraftCache[playerKey]["Initialized"] = true
    
    -- Return a direct reference to this character's data for easy access
    return ThornCraftCache[playerKey]
end