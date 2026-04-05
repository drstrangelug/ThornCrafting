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

local ProfessionsList = {
    { id = 164, name = "Blacksmithing" },
    { id = 202, name = "Engineering" },
    { id = 171, name = "Alchemy" },
    { id = 165, name = "Leatherworking" },
    { id = 197, name = "Tailoring" },
    { id = 755, name = "Jewelcrafting" },
    { id = 333, name = "Enchanting" },
    { id = 185, name = "Cooking" },
    { id = 186, name = "Mining" },
    { id = 129, name = "First Aid" }
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

local function DebugPrint(msg)
    if not ThornCraftOptions or not ThornCraftOptions.showDebug then return end
    print("|cFF00FFFF[ThornCraft]|Core|r " .. tostring(msg))
end


local function ScanProfessions()
    -- Create the Alt database if it doesn't exist
    ThornCraftCache.AltProfessions = ThornCraftCache.AltProfessions or {} 
    
    -- Get a unique ID for this character (Name-Realm)
    local charName = UnitName("player") .. "-" .. GetRealmName()
    
    -- Wipe ONLY this specific character's old data to start fresh
    ThornCraftCache.AltProfessions[charName] = {} 
    
    DebugPrint("Starting character profession check for " .. charName)

    local profs = {GetProfessions()}
    for _, index in pairs(profs) do
        if index then
            local name, _, _, _, _, _, skillLineID = GetProfessionInfo(index)
            if skillLineID then
                ThornCraftCache.AltProfessions[charName][skillLineID] = true
                DebugPrint(charName .. " knows: " .. name .. " (ID: " .. skillLineID .. ")")
            end
        end
    end
    ThornCraftCache.Initialized = true
end

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
        local validRecipesToPrint = {}

        for _, recipeData in ipairs(recipes) do
            local profOpt = ThornCraftOptions.professions[recipeData.prof]
            
            -- Fallback to true if something went wrong
            local shouldShow = profOpt and profOpt.show or false
            if profOpt == nil then shouldShow = true end 

            if shouldShow then
                local isKnownProf = ThornCraftCache.KnownProfessions[recipeData.prof]
                local knownByNames = ""

                -- Safely check the Alt Database if "Include Alts" is checked
                if profOpt and profOpt.showAlt and ThornCraftCache.AltProfessions then
                    for altName, altProfs in pairs(ThornCraftCache.AltProfessions) do
                        if altProfs[recipeData.prof] then
                            isKnownProf = true
                            local shortName = strsplit("-", altName)
                            knownByNames = knownByNames == "" and shortName or (knownByNames .. ", " .. shortName)
                        end
                    end
                end

                local isLearned = false
                if isKnownProf and recipeData.id then
                    local info = C_TradeSkillUI.GetRecipeInfo(recipeData.id)
                    if info and info.learned then
                        isLearned = true
                    end
                end

                local requireLearned = profOpt and profOpt.onlyLearned or false
                local passFilter = true
                
                -- Hide if they checked "Only Learned" and haven't learned it
                if requireLearned and not isLearned then
                    passFilter = false
                end

                if passFilter then
                    -- Attach all our calculated data safely
                    table.insert(validRecipesToPrint, { 
                        data = recipeData, 
                        isKnown = isKnownProf, 
                        isLearned = isLearned,
                        crafters = knownByNames or ""
                    })
                end
            end
        end

        -- Print to screen
        if #validRecipesToPrint > 0 then
            tooltip:AddLine(" ")
            tooltip:AddLine("Used In:", 1, 1, 1)

            for _, item in ipairs(validRecipesToPrint) do
                local r, g, b = GetRecipeColor(item.isKnown, item.isLearned)
                
                -- 1. Unlearned Text Logic
                local status = ""
                if not item.isLearned and ThornCraftOptions.showUnlearnedText then
                    status = " (unlearned)"
                end
                
                -- 2. Alt Crafters Text Logic
                local crafterText = ""
                if item.isKnown and item.crafters ~= "" then
                    crafterText = " [" .. item.crafters .. "]"
                end

                -- 3. Dynamic Icon Logic (With Fallback!)
                local profIcon = C_TradeSkillUI and C_TradeSkillUI.GetTradeSkillTexture(item.data.prof)
                
                -- Catch retired professions or slow UI cache
                if not profIcon then
                    profIcon = FallbackIcons[item.data.prof]
                end

                local prefix = profIcon and ("  |T" .. profIcon .. ":14:14:0:0:64:64:4:60:4:60|t ") or "  • "
                
                tooltip:AddLine(prefix .. item.data.name .. status .. crafterText, r, g, b)
            end
        end
    end
end

-- ==========================================
-- Options Menu Builder
-- ==========================================
-- Helper to create a clickable color swatch
local function CreateColorButton(parent, labelText, x, y, colorKey)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(18, 18)
    btn:SetPoint("TOPLEFT", x, y)
    
    -- Draw the square color block
    local tex = btn:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    local c = ThornCraftOptions.colors[colorKey]
    tex:SetColorTexture(c.r, c.g, c.b)
    
    -- Add the label text next to it
    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", btn, "RIGHT", 6, 0)
    text:SetText(labelText)
    
    -- Open Blizzard's Color Picker when clicked
    btn:SetScript("OnClick", function()
        local currentR, currentG, currentB = ThornCraftOptions.colors[colorKey].r, ThornCraftOptions.colors[colorKey].g, ThornCraftOptions.colors[colorKey].b
        
        local function OnColorChanged()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            ThornCraftOptions.colors[colorKey].r = nr
            ThornCraftOptions.colors[colorKey].g = ng
            ThornCraftOptions.colors[colorKey].b = nb
            tex:SetColorTexture(nr, ng, nb)
        end
        
        ColorPickerFrame:SetupColorPickerAndShow({
            r = currentR, g = currentG, b = currentB,
            swatchFunc = OnColorChanged,
            cancelFunc = function(previousValues)
                ThornCraftOptions.colors[colorKey].r = previousValues.r
                ThornCraftOptions.colors[colorKey].g = previousValues.g
                ThornCraftOptions.colors[colorKey].b = previousValues.b
                tex:SetColorTexture(previousValues.r, previousValues.g, previousValues.b)
            end,
        })
    end)
    return btn
end

local function BuildOptionsMenu()
    local panel = CreateFrame("Frame", "ThornCraftOptionsPanel")
    panel.name = "ThornCraft"
    
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("ThornCraft Profession Settings")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Configure which professions to show, if they require training, and if Alts should be included.")

    -- ==========================================
    -- GLOBAL SETTINGS
    -- ==========================================
    local cbDebug = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cbDebug:SetPoint("TOPLEFT", 20, -45) 
    cbDebug:SetChecked(ThornCraftOptions.showDebug)
    
    local cbDebugText = cbDebug:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbDebugText:SetPoint("LEFT", cbDebug, "RIGHT", 4, 1)
    cbDebugText:SetText("Enable Debug Logging to Chat Frame")

    cbDebug:SetScript("OnClick", function(self) 
        ThornCraftOptions.showDebug = self:GetChecked() 
    end)

    -- 2. NEW: Show "(unlearned)" Text Checkbox
    local cbUnlearnedText = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cbUnlearnedText:SetPoint("TOPLEFT", 20, -75)  -- Stacked under Debug
    cbUnlearnedText:SetChecked(ThornCraftOptions.showUnlearnedText)
    
    local cbUnlearnedTextLabel = cbUnlearnedText:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbUnlearnedTextLabel:SetPoint("LEFT", cbUnlearnedText, "RIGHT", 4, 1)
    cbUnlearnedTextLabel:SetText("Show '(unlearned)' text on untrained recipes")

    cbUnlearnedText:SetScript("OnClick", function(self) 
        ThornCraftOptions.showUnlearnedText = self:GetChecked() 
    end)

    -- Color Settings Row
    local colorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    colorLabel:SetPoint("TOPLEFT", 20, -110) -- Moved down
    colorLabel:SetText("Tooltip Colors:")
    
    CreateColorButton(panel, "Learned", 120, -108, "learned")
    CreateColorButton(panel, "Unlearned", 210, -108, "unlearned")
    CreateColorButton(panel, "Untrained", 310, -108, "untrained")

    -- ==========================================
    -- PROFESSION SETTINGS
    -- ==========================================
    -- Column Headers (Moved down to accommodate Colors)
    local header1 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header1:SetPoint("TOPLEFT", 20, -145) -- Moved down
    header1:SetText("Show Profession")

    local header2 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header2:SetPoint("TOPLEFT", 180, -145) -- Moved down
    header2:SetText("Only Learned")

    local header3 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header3:SetPoint("TOPLEFT", 320, -145) -- Moved down
    header3:SetText("Include Alts")

    local yOffset = -170 -- Moved down

    for _, prof in ipairs(ProfessionsList) do
        local opt = ThornCraftOptions.professions[prof.id]

        local cbShow = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        cbShow:SetPoint("TOPLEFT", 20, yOffset)
        cbShow:SetChecked(opt.show)
        
        local cbShowText = cbShow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        cbShowText:SetPoint("LEFT", cbShow, "RIGHT", 4, 1)
        cbShowText:SetText(prof.name)

        local cbLearned = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        cbLearned:SetPoint("TOPLEFT", 180, yOffset)
        cbLearned:SetChecked(opt.onlyLearned)

        local cbAlt = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        cbAlt:SetPoint("TOPLEFT", 320, yOffset)
        cbAlt:SetChecked(opt.showAlt)

        cbShow:SetScript("OnClick", function(self) opt.show = self:GetChecked() end)
        cbLearned:SetScript("OnClick", function(self) opt.onlyLearned = self:GetChecked() end)
        cbAlt:SetScript("OnClick", function(self) opt.showAlt = self:GetChecked() end)

        yOffset = yOffset - 35
    end

    local category = Settings.RegisterCanvasLayoutCategory(panel, "ThornCraft")
    Settings.RegisterAddOnCategory(category)
end

-- ==========================================
-- Event Handling
-- ==========================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        
        ThornCraftOptions = ThornCraftOptions or {}
        ThornCraftOptions.professions = ThornCraftOptions.professions or {} 
        
        -- Default Colors (RGB values from 0.0 to 1.0)
        ThornCraftOptions.colors = ThornCraftOptions.colors or {
            learned = { r = 0.5, g = 1.0, b = 0.5 },    -- Success Green
            unlearned = { r = 1.0, g = 0.7, b = 0.0 },  -- Action Amber
            untrained = { r = 0.5, g = 0.5, b = 0.5 }   -- Gray
        }

        if ThornCraftOptions.showDebug == nil then 
            ThornCraftOptions.showDebug = true 
        end

        -- NEW: Default the unlearned text to true
        if ThornCraftOptions.showUnlearnedText == nil then
            ThornCraftOptions.showUnlearnedText = true
        end

        for _, prof in ipairs(ProfessionsList) do
            if not ThornCraftOptions.professions[prof.id] then
                ThornCraftOptions.professions[prof.id] = { show = true, onlyLearned = false, showAlt = false }
            elseif ThornCraftOptions.professions[prof.id].showAlt == nil then
                ThornCraftOptions.professions[prof.id].showAlt = false
            end
        end

        BuildOptionsMenu()
        
    elseif event == "PLAYER_LOGIN" then
        C_Timer.After(2, ScanProfessions)
    end
end)

if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
end