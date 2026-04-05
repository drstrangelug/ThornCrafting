-- Core.lua
local ADDON_NAME, addon = ...

-- Global Cache
ThornCraftCache = ThornCraftCache or {
    Professions = {},
    KnownProfessions = {},
    Initialized = false
}

local PROFESSION_SKILL_LINE_IDS = {
    164, 165, 171, 182, 185, 186, 197, 202, 333, 356, 393, 755, 773, 794,
}

local function DebugPrint(msg)
    print("|cFF00FFFF[ThornCraft]|r " .. tostring(msg))
end

local function ScanProfessions()
    ThornCraftCache.KnownProfessions = {} 
    DebugPrint("Starting character profession check...")

    local profs = {GetProfessions()} -- Catch all indices
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

local function InitializeOptions()
    if not ThornCraftOptions then
        ThornCraftOptions = { showUntrained = true }
    end
end

local function ConvertColor(r, g, b)
    return r/255, g/255, b/255
end

-- State Coloring Logic
local function GetRecipeColor(isKnownProf, isLearned)
    if isKnownProf and isLearned then
        return ConvertColor(128,255,128) -- White: Trained & Learned
    elseif isKnownProf then
        return ConvertColor(255, 180, 0) -- Orange: Trained but NOT learned
    else
        return ConvertColor(128,128,128) -- Gray: Untrained  
    end
end

-- Main Tooltip Hook
local function OnTooltipSetItem(tooltip, data)
    if not data or not data.id then return end
    
    local itemID = data.id
    local recipes = ThornCraftDB and ThornCraftDB[itemID]

    if recipes then
        tooltip:AddLine(" ")
        tooltip:AddLine("Used In:", 1, 1, 1)

        for _, recipeData in ipairs(recipes) do
            local isKnownProf = ThornCraftCache.KnownProfessions[recipeData.prof]
            local isLearned = false

            -- Only check 'learned' status if we actually have the profession
            if isKnownProf and recipeData.id then
                local info = C_TradeSkillUI.GetRecipeInfo(recipeData.id)
                if info and info.learned then
                    isLearned = true
                end
            end

            -- Filter by Options
            if isKnownProf or ThornCraftOptions.showUntrained then
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
frame:RegisterEvent("PLAYER_LOGIN") -- Better than Entering World for initial scans
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        InitializeOptions()
    elseif event == "PLAYER_LOGIN" then
        -- Delay slightly to ensure Blizzard's Profession UI is ready
        C_Timer.After(2, ScanProfessions)
    end
end)

-- Retail 12.0 Hook
if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
end