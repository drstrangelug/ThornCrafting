-- Core.lua
local ADDON_NAME, ns = ... -- Changed 'addon' to 'ns' to match your code

-- Global Cache
ThornCraftCache = ThornCraftCache or {
    Professions = {},
    KnownProfessions = {},
    Initialized = false
}

-- IDs (Added missing ones for your source list)
local BLACKSMITHING, ENGINEERING, ALCHEMY = 164, 202, 171
local LEATHERWORKING, TAILORING, JEWELCRAFTING = 165, 197, 755
local INSCRIPTION, ENCHANTING, COOKING, MINING = 773, 333, 185, 186
local HERBALISM, FIRST_AID = 182, 129 -- Standard IDs

local function DebugPrint(msg)
    if not ThornCraftOptions or not ThornCraftOptions.showDebug then return end
    print("|cFF00FFFF[ThornCraft]|Core|r " .. tostring(msg))
end


ns.ReagentToRecipeMap = {}

-- Logic for building the index
local function BuildReverseLookupIndex(recipeTable, profID)
    if not recipeTable then return 0, 0 end
    local localRecipes = 0
    local localReagents = 0
    
    for _, recipe in ipairs(recipeTable) do
        localRecipes = localRecipes + 1
        if recipe.reagents then
            for _, reagent in ipairs(recipe.reagents) do
                localReagents = localReagents + 1
                local rID = reagent.itemId
                ns.ReagentToRecipeMap[rID] = ns.ReagentToRecipeMap[rID] or {}
                table.insert(ns.ReagentToRecipeMap[rID], {
                    id = recipe.id,
                    name = recipe.name,
                    prof = profID
                })
            end
        end
    end
    return localRecipes, localReagents
end

local function InitializeDatabase()
    DebugPrint("Initializing Recipe Database...")
    local totalRecipes = 0
    local totalReagents = 0
    
    local sources = {
        { data = ns.BlacksmithingRecipes, prof = BLACKSMITHING },
        { data = ns.CookingRecipes,       prof = COOKING },
        { data = ns.EnchantingRecipes,    prof = ENCHANTING },
        { data = ns.EngineeringRecipes,   prof = ENGINEERING },
        { data = ns.FirstAidRecipes,      prof = FIRST_AID },
        { data = ns.HerbalismRecipes,     prof = HERBALISM },
        { data = ns.JewelCraftingRecipes, prof = JEWELCRAFTING },
        { data = ns.LeatherWorkingRecipes,prof = LEATHERWORKING },
        { data = ns.MiningRecipes,        prof = MINING },
        { data = ns.TailoringRecipes,     prof = TAILORING }
    }

    for _, source in ipairs(sources) do
        if source.data then
            local rCount, reCount = BuildReverseLookupIndex(source.data, source.prof)
            totalRecipes = totalRecipes + rCount
            totalReagents = totalReagents + reCount
        end
    end
    
    DebugPrint(string.format("Database Indexing Complete: %d recipes found using %d total reagents.", totalRecipes, totalReagents))
end

local function ScanProfessions()
    ThornCraftCache.KnownProfessions = {} 
    DebugPrint("Starting character profession check...")

    local profs = {GetProfessions()}
    for _, index in pairs(profs) do
        if index then
            local name, _, _, _, _, _, skillLineID = GetProfessionInfo(index)
            if skillLineID then
                ThornCraftCache.KnownProfessions[skillLineID] = true
                DebugPrint("Character knows: " .. name .. " (ID: " .. skillLineID .. ")")
            end
        end
    end
    ThornCraftCache.Initialized = true
end

-- Helper for color conversion
local function GetWoWColor(r, g, b)
    return r/255, g/255, b/255
end

local function GetRecipeColor(isKnownProf, isLearned)
    if isKnownProf and isLearned then
        return GetWoWColor(128, 255, 128) -- Success Green
    elseif isKnownProf then
        return GetWoWColor(255, 180, 0)   -- Action Amber
    else
        return GetWoWColor(128, 128, 128) -- Untrained Gray
    end
end

local function OnTooltipSetItem(tooltip, data)
    if not data or not data.id then return end
    
    local itemID = data.id
    -- Now looking at our NEW generated map
    local recipes = ns.ReagentToRecipeMap[itemID]

    if recipes then
        tooltip:AddLine(" ")
        tooltip:AddLine("Used In:", 1, 1, 1)

        for _, recipeData in ipairs(recipes) do
            local isKnownProf = ThornCraftCache.KnownProfessions[recipeData.prof]
            local isLearned = false

            if isKnownProf and recipeData.id then
                local info = C_TradeSkillUI.GetRecipeInfo(recipeData.id)
                if info and info.learned then
                    isLearned = true
                end
            end

            if isKnownProf or (ThornCraftOptions and ThornCraftOptions.showUntrained) then
                local r, g, b = GetRecipeColor(isKnownProf, isLearned)
                local status = isLearned and "" or " (unlearned)"
                tooltip:AddLine("  • " .. recipeData.name .. status, r, g, b)
            end
        end
    end
end

-- Event Handling
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        -- 1. Create the table if it's a brand new character
        ThornCraftOptions = ThornCraftOptions or {}
        
        -- 2. Inject missing defaults WITHOUT overwriting user choices
        if ThornCraftOptions.showUntrained == nil then 
            ThornCraftOptions.showUntrained = true 
        end
        if ThornCraftOptions.showDebug == nil then 
            ThornCraftOptions.showDebug = true 
        end

        -- Initialize everything when the addon loads
        if not ThornCraftOptions then ThornCraftOptions = { showUntrained = true } end
        InitializeDatabase() 
    elseif event == "PLAYER_LOGIN" then
        C_Timer.After(2, ScanProfessions)
    end
end)

if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
end