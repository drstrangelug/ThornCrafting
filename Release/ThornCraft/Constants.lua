-- Core/Constants.lua
-- CraftLib shared constants
local ADDON_NAME, ns = ...

-- ==========================================
-- Shared Utility Functions
-- ==========================================
function ns.DebugPrint(msg, moduleName)
    if not ThornCraftOptions or not ThornCraftOptions.showDebug then return end
    
    -- Optional: Allow passing a module name so you know WHICH file printed it!
    local prefix = moduleName and ("|" .. moduleName) or ""
    print("|cFF00FFFF[ThornCraft]" .. prefix .. "|r " .. tostring(msg))
end

ns.Constants = {
    -- Game expansions
    EXPANSION = {
        VANILLA = 1,
        TBC = 2,
        WOTLK = 3,
        CATA = 4,
        MOP = 5,
        WOD = 6,
        LEGION = 7,
        BFA = 8,
        SHADOWLANDS = 9,
        DRAGONFLIGHT = 10,
        TWW = 11,
        MIDNIGHT = 12, -- Added from your data mining!
    },

    EXPANSION_NAMES = {
        [1] = "Vanilla",
        [2] = "The Burning Crusade",
        [3] = "Wrath of the Lich King",
        [4] = "Cataclysm",
        [5] = "Mists of Pandaria",
        [6] = "Warlords of Draenor",
        [7] = "Legion",
        [8] = "Battle for Azeroth",
        [9] = "Shadowlands",
        [10] = "Dragonflight",
        [11] = "The Winds of Winter",
        [12] = "Midnight"
    },

    -- Recipe source types
    SOURCE_TYPE = {
        TRAINER = "trainer",
        VENDOR = "vendor",
        DROP = "drop",
        REPUTATION = "reputation",
        QUEST = "quest",
        STARTER = "starter",
        DISCOVERY = "discovery",
        WORLD_DROP = "world_drop",
    },

    -- Profession IDs (spell IDs)
    PROFESSION_ID = {
        -- Primary
        ALCHEMY = 2259,
        BLACKSMITHING = 2018,
        ENCHANTING = 7411,
        ENGINEERING = 4036,
        HERBALISM = 2366,
        JEWELCRAFTING = 25229,
        LEATHERWORKING = 2108,
        MINING = 2575,
        SKINNING = 8613,
        TAILORING = 3908,
        -- Secondary
        COOKING = 2550,
        FIRST_AID = 3273,
        FISHING = 7620,
    },

    -- Skill difficulty colors
    DIFFICULTY = {
        ORANGE = "orange", 
        YELLOW = "yellow",  
        GREEN = "green",    
        GRAY = "gray",      
    },

    -- The Master List of Supported Professions
    PROFESSIONS_LIST = {
        { id = 164, name = "Blacksmithing" },
        { id = 202, name = "Engineering" },
        { id = 171, name = "Alchemy" },
        { id = 165, name = "Leatherworking" },
        { id = 197, name = "Tailoring" },
        { id = 755, name = "Jewelcrafting" },
        { id = 333, name = "Enchanting" },
        { id = 185, name = "Cooking" },
        { id = 186, name = "Mining" },
        { id = 182, name = "Herbalism" },
        { id = 393, name = "Skinning" },
        { id = 773, name = "Inscription" },
        { id = 129, name = "First Aid" },
        { id = 356, name = "Fishing" }
    },

    -- Map: [Base/Parent SkillLineID] = { [ExpansionConstant] = ExactSkillLineID }
    SKILL_LINE_IDS = {
        [773] = { -- Inscription
            [1] = 2514, [2] = 2513, [3] = 2512, [4] = 2511, [5] = 2510, [6] = 2509,
            [7] = 2508, [8] = 2507, [9] = 2756, [10] = 2828, [11] = 2878, [12] = 2913
        },
        [755] = { -- Jewelcrafting
            [1] = 2524, [2] = 2523, [3] = 2522, [4] = 2521, [5] = 2520, [6] = 2519,
            [7] = 2518, [8] = 2517, [9] = 2757, [10] = 2829, [11] = 2879, [12] = 2914
        },
        [186] = { -- Mining
            [1] = 2572, [2] = 2571, [3] = 2570, [4] = 2569, [5] = 2568, [6] = 2567,
            [7] = 2566, [8] = 2565, [9] = 2761, [10] = 2833, [11] = 2881, [12] = 2916
        },
        [164] = { -- Blacksmithing
            [1] = 2477, [2] = 2476, [3] = 2475, [4] = 2474, [5] = 2473, [6] = 2472,
            [7] = 2454, [8] = 2437, [9] = 2751, [10] = 2822, [11] = 2872, [12] = 2907
        },
        [202] = { -- Engineering
            [1] = 2506, [2] = 2505, [3] = 2504, [4] = 2503, [5] = 2502, [6] = 2501,
            [7] = 2500, [8] = 2499, [9] = 2755, [10] = 2827, [11] = 2875, [12] = 2910
        },
        [165] = { -- Leatherworking
            [1] = 2532, [2] = 2531, [3] = 2530, [4] = 2529, [5] = 2528, [6] = 2527,
            [7] = 2526, [8] = 2525, [9] = 2758, [10] = 2830, [11] = 2880, [12] = 2915
        },
        [182] = { -- Herbalism
            [1] = 2556, [2] = 2555, [3] = 2554, [4] = 2553, [5] = 2552, [6] = 2551,
            [7] = 2550, [8] = 2549, [9] = 2760, [10] = 2832, [11] = 2877, [12] = 2912
        },
        [197] = { -- Tailoring
            [1] = 2540, [2] = 2539, [3] = 2538, [4] = 2537, [5] = 2536, [6] = 2535,
            [7] = 2534, [8] = 2533, [9] = 2759, [10] = 2831, [11] = 2883, [12] = 2918
        },
        [393] = { -- Skinning
            [1] = 2564, [2] = 2563, [3] = 2562, [4] = 2561, [5] = 2560, [6] = 2559,
            [7] = 2558, [8] = 2557, [9] = 2762, [10] = 2834, [11] = 2882, [12] = 2917
        },
        [333] = { -- Enchanting
            [1] = 2494, [2] = 2493, [3] = 2492, [4] = 2491, [5] = 2489, [6] = 2488,
            [7] = 2487, [8] = 2486, [9] = 2753, [10] = 2825, [11] = 2874, [12] = 2909
        },
        [171] = { -- Alchemy
            [1] = 2485, [2] = 2484, [3] = 2483, [4] = 2482, [5] = 2481, [6] = 2480,
            [7] = 2479, [8] = 2478, [9] = 2750, [10] = 2823, [11] = 2871, [12] = 2906
        },
        [185] = { -- Cooking (Secondary)
            [1] = 185, [2] = 976, [3] = 1086, [4] = 2548, [5] = 1043, [6] = 1607,
            [7] = 2011, [8] = 2546, [9] = 2752, [10] = 2824, [11] = 2884
        },
    }
}