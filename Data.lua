local ADDON_NAME, addon = ...

local BLACKSMITHING = 164
local ENGINEERING = 202
local ALCHEMY = 171
local LEATHERWORKING = 165
local TAILORING = 197
local JEWELCRAFTING = 755
local INSCRIPTION = 773
local ENCHANTING = 333
local COOKING = 185
local MINING = 186

-- Data.lua: Defines the recipe database
ThornCraftDB = {
    -- Mapping Reagent Item ID to the recipes that use it
    [2848] = { -- Copper Ore
        {id = 2657, name = "Copper Chain Belt", prof = BLACKSMITHING},
        {id = 2660, name = "Rough Sharpening Stone", prof = BLACKSMITHING},
        {id = 3248, name = "Copper Bracers", prof = BLACKSMITHING}
    },
    [2589] = { -- Linen Cloth
        {id = 2385, name = "Brown Linen Shirt", prof = TAILORING},
        {id = 2393, name = "White Linen Robe", prof = TAILORING}
    },
    [2835] = { -- Rough Stone
        {id = 2660, name = "Rough Sharpening Stone", prof = BLACKSMITHING},
        {id = 3404, name = "Rough Grinding Stone", prof = BLACKSMITHING}
    },
    [2592] = { -- Wool Cloth
        {id = 2396, name = "White Woolen Dress", prof = TAILORING},
        {id = 2399, name = "Gray Woolen Shirt", prof = TAILORING},
        {id = 2402, name = "Tight Mittens", prof = TAILORING}
    }
}
