-- Core.lua
local ADDON_NAME, ns = ... -- Changed 'addon' to 'ns' to match your code

-- ==========================================
-- Slash Commands
-- ==========================================
SLASH_THORNCRAFT1 = "/tc"
SLASH_THORNCRAFT2 = "/thorncraft" -- Fallback alias

SlashCmdList["THORNCRAFT"] = function(msg)
    -- WoW sometimes passes nil or a string with trailing spaces.
    -- strtrim() removes spaces, string.lower() makes it all lowercase.
    local command = msg and strtrim(string.lower(msg)) or ""
    
    if command == "debug" then
        ThornCraftOptions.showDebug = not ThornCraftOptions.showDebug
        print("|cFF00FFFF[ThornCraft]|r Debug mode is now " .. (ThornCraftOptions.showDebug and "ON" or "OFF"))
    -- Add this to your SlashCmdList block!
    elseif command == "mine" then
        print("|cFF00FFFF[ThornCraft]|r Mining Profession IDs from game database...")
        
        -- We need a global table to save this so it writes to your SavedVariables file on logout!
        ThornCraft_DataDump = {} 
        
        local allIDs = C_TradeSkillUI.GetAllProfessionTradeSkillLines()
        for _, skillID in ipairs(allIDs) do
            local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillID)
            
            -- If it has a parent ID, it's an expansion tier!
            if info and info.parentProfessionID then
                local pID = info.parentProfessionID
                ThornCraft_DataDump[pID] = ThornCraft_DataDump[pID] or {}
                
                -- Save it clearly with its name so you know what expansion it is
                ThornCraft_DataDump[pID][skillID] = info.professionName
            end
        end
        print("|cFF00FFFF[ThornCraft]|r Mining complete! Type /reload to save to disk.")
    else
        print("|cFF00FFFF[ThornCraft]|r Version 1.0 Loaded")
        print("|cFF00FFFF[ThornCraft]|r Commands: /tc debug")
    end
end

-- Fallback Icon FileIDs (In case the WoW API fails or the profession is retired)
local FallbackIcons = {
    [164] = 136241, -- Blacksmithing
    [202] = 136243, -- Engineering
    [171] = 136240, -- Alchemy
    [165] = 136247, -- Leatherworking
    [197] = 136249, -- Tailoring
    [755] = 134071, -- Jewelcrafting
    [333] = 136244, -- Enchanting
    [185] = 136246, -- Cooking
    [186] = 136248, -- Mining
    [182] = 136245, -- Herbalism
    [773] = 237171, -- Inscription
    [129] = 135966, -- First Aid (Spell_Holy_SealOfSacrifice)
}

-- IDs (Added missing ones for your source list)
local BLACKSMITHING, ENGINEERING, ALCHEMY = 164, 202, 171
local LEATHERWORKING, TAILORING, JEWELCRAFTING = 165, 197, 755
local INSCRIPTION, ENCHANTING, COOKING, MINING = 773, 333, 185, 186
local HERBALISM, FIRST_AID = 182, 129 -- Standard IDs   



-- ==========================================
-- Tooltip Color Logic
-- ==========================================
local function GetRecipeColor(isKnownProf, isLearned)
    local c = ThornCraftOptions.colors
    if isKnownProf and isLearned then
        return c.learned.r, c.learned.g, c.learned.b
    elseif isKnownProf then
        return c.unlearned.r, c.unlearned.g, c.unlearned.b
    else
        return c.untrained.r, c.untrained.g, c.untrained.b
    end
end

-- ==========================================
-- Tooltip Logic
-- ==========================================
local function AddCurrentPlayerRecipes(tooltip, validRecipesToPrint)
    local allTrivial = true
    tooltip:AddLine(" ")
    tooltip:AddLine("Used In:", 1, 1, 1)

    for _, item in ipairs(validRecipesToPrint) do
        -- Since the list only contains professions the player actually has, isKnown is true
        local r, g, b = GetRecipeColor(true, item.isLearned)
        
        -- Override with Gray if the recipe is trivial
        if item.isTrivial then
            r, g, b = 0.5, 0.5, 0.5
        else
            -- If it grants the player a skill point, we should not tell them to sell it
            allTrivial = false 
        end
        
        local status = ""
        if not item.isLearned and ThornCraftOptions.showUnlearnedText then
            status = " (unlearned)"
        end
        
        local profIcon = C_TradeSkillUI and C_TradeSkillUI.GetTradeSkillTexture(item.data.baseProf)
        if not profIcon then profIcon = FallbackIcons[item.data.baseProf] end

        local prefix = profIcon and ("  |T" .. profIcon .. ":14:14:0:0:64:64:4:60:4:60|t ") or "  • "
        
        tooltip:AddLine(prefix .. item.data.name .. status, r, g, b)
    end

    return allTrivial
end

local function AddAltUsage(tooltip, recipes)
    local altsWhoNeedIt = ns.GetAltsThatNeedItem(recipes)
    local numAlts = #altsWhoNeedIt
    local hasAlts = (numAlts > 0)

    if hasAlts then
        local formattedAlts = {}
        local maxDisplay = 3
        
        for i = 1, math.min(numAlts, maxDisplay) do
            local altData = altsWhoNeedIt[i]
            local iconStr = ""
            
            -- Handle either profIDs (array) or profID (single)
            local profIDs = altData.profIDs or { altData.profID }
            for _, profID in ipairs(profIDs) do
                local profIcon = C_TradeSkillUI and C_TradeSkillUI.GetTradeSkillTexture(profID)
                if not profIcon and FallbackIcons then profIcon = FallbackIcons[profID] end
                
                if profIcon then
                    -- Chain the icons side-by-side
                    iconStr = iconStr .. "|T" .. profIcon .. ":14:14:0:0:64:64:4:60:4:60|t"
                end
            end
            
            -- Add a space after the icon chain if we found any
            if iconStr ~= "" then iconStr = iconStr .. " " end
            
            -- Combine Icons + Cyan Name
            table.insert(formattedAlts, iconStr .. "|cFF00CCFF" .. tostring(altData.name) .. "|r")
        end

        -- Join them with commas
        local finalString = table.concat(formattedAlts, ", ")
        
        -- Tack on "and others" if we hit the limit
        if numAlts > maxDisplay then
            finalString = finalString .. ", and others"
        end

        -- Add it to the tooltip!
        tooltip:AddLine("Usable by Alts: " .. finalString)
    end
    
    return hasAlts
end

local function OnTooltipSetItem(tooltip, data)
    if not data or not data.id then return end
    
    local itemID = data.id
    local recipes = ns.ReagentToRecipeMap[itemID]

    if recipes then
        -- 1. Grab ONLY the current player's valid recipes
        local validRecipesToPrint = ns.GetCurrentPlayerRecipes(recipes)
        local allTrivial = true 

        if #validRecipesToPrint > 0 then
            allTrivial = AddCurrentPlayerRecipes(tooltip, validRecipesToPrint)
        end
        
        local hasAlts = false
        if ThornCraftOptions.alts.showAlt then
            hasAlts = AddAltUsage(tooltip, recipes)
            -- If an alt needs it, protect the item from the auto-sell button!
            if hasAlts then
                allTrivial = false 
            end
        end

        -- Print the summary ONLY if everything in the list is gray/trivial
        if allTrivial and #validRecipesToPrint > 0 then
            local sellColor = ThornCraftOptions.colors.sell or { r = 1, g = 0.82, b = 0 }
            tooltip:AddLine("  |TInterface\\MoneyFrame\\UI-GoldIcon:14:14:0:0|t You can sell this", sellColor.r, sellColor.g, sellColor.b)
        end
    end
end

-- Create a local variable to hold our active timer
local scanTimer = nil

-- Create an invisible frame to listen for background game events
local eventFrame = CreateFrame("Frame")

-- Tell the frame which specific events to listen for
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD") 
eventFrame:RegisterEvent("SKILL_LINES_CHANGED")   
eventFrame:RegisterEvent("TRADE_SKILL_SHOW")

-- Define what happens when the frame "hears" an event
eventFrame:SetScript("OnEvent", function(self, event, ...)
    -- 1. Grab this specific character's data folder using the function from DataCache.lua!
    local playerData = ns:InitPlayerCache()

    if event == "PLAYER_ENTERING_WORLD" then
        -- We usually want the initial login scan to happen immediately
        ns.ScanProfessions()
        
    elseif event == "SKILL_LINES_CHANGED" or event == "TRADE_SKILL_SHOW" then
        -- 2. Check if THIS character's data is initialized, not the global cache
        if playerData and playerData.Initialized then
            
            -- THE DEBOUNCE:
            -- If a timer is already ticking because an event fired 0.1 seconds ago, cancel it!
            if scanTimer then
                scanTimer:Cancel()
            end
            
            -- Start a fresh 0.5 second timer. 
            -- If the game stops spamming events, this will finally reach 0 and run the scan.
            scanTimer = C_Timer.NewTimer(0.5, function()
                ns.ScanProfessions()
                ns.DebugPrint("ThornCraft: Event spam settled. Recalculating skills.")
            end)
            
        end
    end
end)

if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
end