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
local function OnTooltipSetItem(tooltip, data)
    if not data or not data.id then return end
    
    local itemID = data.id
    local recipes = ns.ReagentToRecipeMap[itemID]

    if recipes then
        local validRecipesToPrint = ns.GetValidRecipesToPrint(recipes)

        -- Print to screen
        if #validRecipesToPrint > 0 then
            tooltip:AddLine(" ")
            tooltip:AddLine("Used In:", 1, 1, 1)

            -- NEW: Assume everything is trivial until we find one that isn't
            local allTrivial = true 

            for _, item in ipairs(validRecipesToPrint) do
                local r, g, b = GetRecipeColor(item.isKnown, item.isLearned)
                
                -- Override with Gray if the recipe is trivial
                if item.isTrivial then
                    r, g, b = 0.5, 0.5, 0.5
                else
                    -- If even one recipe gives experience, flag it as false!
                    allTrivial = false
                end
                
                local status = ""
                -- We removed the item.isTrivial check from here
                if not item.isLearned and ThornCraftOptions.showUnlearnedText then
                    status = " (unlearned)"
                end
                
                local crafterText = ""
                if item.isKnown and item.crafters ~= "" then
                    crafterText = " [" .. item.crafters .. "]"
                end

                local profIcon = C_TradeSkillUI and C_TradeSkillUI.GetTradeSkillTexture(item.data.baseProf)
                if not profIcon then profIcon = FallbackIcons[item.data.baseProf] end

                local prefix = profIcon and ("  |T" .. profIcon .. ":14:14:0:0:64:64:4:60:4:60|t ") or "  • "
                
                tooltip:AddLine(prefix .. item.data.name .. status .. crafterText, r, g, b)
            end

            -- NEW: If the loop finished and every recipe was trivial, print the summary
            if allTrivial then
                local sellColor = ThornCraftOptions.colors.sell or { r = 1, g = 0.82, b = 0 }
                tooltip:AddLine("  |TInterface\\MoneyFrame\\UI-GoldIcon:14:14:0:0|t You can sell this",sellColor.r, sellColor.g, sellColor.b)
            end
        end
    end
end

-- Create an invisible frame to listen for background game events
local eventFrame = CreateFrame("Frame")

-- Tell the frame which specific events to listen for
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD") 
eventFrame:RegisterEvent("SKILL_LINES_CHANGED")   
eventFrame:RegisterEvent("TRADE_SKILL_SHOW")

-- Define what happens when the frame "hears" an event
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        ns.ScanProfessions()
        
    elseif event == "SKILL_LINES_CHANGED" or event == "TRADE_SKILL_SHOW" then
        if ThornCraftCache and ThornCraftCache.Initialized then
            ns.ScanProfessions()
            ns.DebugPrint("ThornCraft: Event " .. event .. " fired, recalculating skills.")
        end
    end
end)

if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
end