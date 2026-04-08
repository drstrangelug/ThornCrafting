-- Options.lua
local ADDON_NAME, ns = ...

-- ==========================================
-- Helper Functions
-- ==========================================
local function CreateColorButton(parent, labelText, x, y, colorKey)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(18, 18)
    btn:SetPoint("TOPLEFT", x, y)
    
    local tex = btn:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    local c = ThornCraftOptions.colors[colorKey]
    tex:SetColorTexture(c.r, c.g, c.b)
    
    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", btn, "RIGHT", 6, 0)
    text:SetText(labelText)
    
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

-- ==========================================
-- Sub-Panel: General Options
-- ==========================================
local function BuildGeneralPanel(parentCategory)
    local panel = CreateFrame("Frame", "ThornCraftGeneralPanel")
    
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("General Settings")

    -- GLOBAL SETTINGS
    local cbDebug = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cbDebug:SetPoint("TOPLEFT", 20, -45) 
    cbDebug:SetChecked(ThornCraftOptions.showDebug)
    
    local cbDebugText = cbDebug:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbDebugText:SetPoint("LEFT", cbDebug, "RIGHT", 4, 1)
    cbDebugText:SetText("Enable Debug Logging to Chat Frame")

    cbDebug:SetScript("OnClick", function(self) ThornCraftOptions.showDebug = self:GetChecked() end)

    local cbUnlearnedText = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cbUnlearnedText:SetPoint("TOPLEFT", 20, -75) 
    cbUnlearnedText:SetChecked(ThornCraftOptions.showUnlearnedText)
    
    local cbUnlearnedTextLabel = cbUnlearnedText:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbUnlearnedTextLabel:SetPoint("LEFT", cbUnlearnedText, "RIGHT", 4, 1)
    cbUnlearnedTextLabel:SetText("Show '(unlearned)' text on untrained recipes")

    cbUnlearnedText:SetScript("OnClick", function(self) ThornCraftOptions.showUnlearnedText = self:GetChecked() end)

    -- COLORS
    local colorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    colorLabel:SetPoint("TOPLEFT", 20, -110) 
    colorLabel:SetText("Tooltip Colors:")
    
    CreateColorButton(panel, "Learned", 120, -108, "learned")
    CreateColorButton(panel, "Unlearned", 210, -108, "unlearned")
    CreateColorButton(panel, "Untrained", 310, -108, "untrained")
    
    -- Failsafe for the new color
    ThornCraftOptions = ThornCraftOptions or {}
    ThornCraftOptions.colors = ThornCraftOptions.colors or {}
    ThornCraftOptions.colors.sell = ThornCraftOptions.colors.sell or { r = 1.0, g = 0.82, b = 0.0 }
    
    CreateColorButton(panel, "Sell", 410, -108, "sell")

    -- MISSING LINE RESTORED HERE:
    Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, "General")
end

-- ==========================================
-- Sub-Panel: Professions (With ScrollFrame)
-- ==========================================
local function BuildProfessionsPanel(parentCategory)
    local panel = CreateFrame("Frame", "ThornCraftProfessionsPanel")
    
    local scrollFrame = CreateFrame("ScrollFrame", "ThornCraftScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10) 

    local scrollChild = CreateFrame("Frame", "ThornCraftScrollChild", scrollFrame)
    -- FIX: Hardcode a safe width of 600 so Lua's truthy '0' doesn't squish our UI!
    scrollChild:SetSize(600, 100) 
    scrollFrame:SetScrollChild(scrollChild)

    local title = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 6, -6)
    title:SetText("Profession Tracking")

    local subtitle = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Configure which professions to show, if they require training, and if Alts should be included.")

    local header1 = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header1:SetPoint("TOPLEFT", 10, -45) 
    header1:SetText("Show Profession")

    local header2 = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header2:SetPoint("TOPLEFT", 170, -45) 
    header2:SetText("Only Learned")

    local header3 = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header3:SetPoint("TOPLEFT", 310, -45) 
    header3:SetText("Include Alts")

    local yOffset = -70 

    for _, prof in ipairs(ns.Constants.PROFESSIONS_LIST) do
        local opt = ThornCraftOptions.professions[prof.id]

        local cbShow = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
        cbShow:SetPoint("TOPLEFT", 10, yOffset)
        cbShow:SetChecked(opt.show)
        
        local cbShowText = cbShow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        cbShowText:SetPoint("LEFT", cbShow, "RIGHT", 4, 1)
        cbShowText:SetText(prof.name)

        local cbLearned = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
        cbLearned:SetPoint("TOPLEFT", 170, yOffset)
        cbLearned:SetChecked(opt.onlyLearned)

        local cbAlt = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
        cbAlt:SetPoint("TOPLEFT", 310, yOffset)
        cbAlt:SetChecked(opt.showAlt)

        cbShow:SetScript("OnClick", function(self) opt.show = self:GetChecked() end)
        cbLearned:SetScript("OnClick", function(self) opt.onlyLearned = self:GetChecked() end)
        cbAlt:SetScript("OnClick", function(self) opt.showAlt = self:GetChecked() end)

        yOffset = yOffset - 35
    end

    scrollChild:SetHeight(math.abs(yOffset) + 20)

    -- Register as a subcategory of the main ThornCraft node
    Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, "Professions")
end

-- ==========================================
-- Main Options Initialization
-- ==========================================
local function BuildOptionsMenu()
    -- Create the Root Parent Frame (Landing Page)
    local mainPanel = CreateFrame("Frame", "ThornCraftMainPanel")
    mainPanel.name = "ThornCraft"
    
    local title = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("ThornCraft")

    local version = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    version:SetText("Version 1.0.0")

    local instructions = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    instructions:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -20)
    instructions:SetText("Please select a category from the menu on the left to configure ThornCraft.")

    -- Register the main parent category with WoW
    local category = Settings.RegisterCanvasLayoutCategory(mainPanel, "ThornCraft")
    Settings.RegisterAddOnCategory(category)

    -- Build and attach the children to the parent category
    BuildGeneralPanel(category)
    BuildProfessionsPanel(category)
end

-- ==========================================
-- Variable Initialization Event
-- ==========================================
-- ==========================================
-- Variable Initialization & Login Events
-- ==========================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN") -- NEW: Wait for character data!

frame:SetScript("OnEvent", function(self, event, arg1)
    
    -- STEP 1: Addon loads. Set up the empty tables and raw defaults.
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        ThornCraftOptions = ThornCraftOptions or {}
        ThornCraftOptions.professions = ThornCraftOptions.professions or {} 
        
        ThornCraftOptions.colors = ThornCraftOptions.colors or {
            learned = { r = 0.5, g = 1.0, b = 0.5 },    
            unlearned = { r = 1.0, g = 0.7, b = 0.0 },  
            untrained = { r = 0.5, g = 0.5, b = 0.5 },
            sell = { r = .9, g = 0.9, b = 0.9 }
        }

        if ThornCraftOptions.showDebug == nil then ThornCraftOptions.showDebug = false end
        if ThornCraftOptions.showUnlearnedText == nil then ThornCraftOptions.showUnlearnedText = true end

    -- STEP 2: Player enters the world. Character data is now safe to read!
    elseif event == "PLAYER_LOGIN" then
        local activeProfIDs = {}
        
        -- By wrapping the function in {} and using pairs, it perfectly 
        -- captures all professions, even if there are empty slots between them!
        local profs = { GetProfessions() } 

        for _, profIndex in pairs(profs) do
            local _, _, _, _, _, _, skillLine = GetProfessionInfo(profIndex)
            if skillLine then 
                activeProfIDs[skillLine] = true 
            end
        end

        -- Build the profession defaults based on actual character skills
        for _, prof in ipairs(ns.Constants.PROFESSIONS_LIST) do
            if not ThornCraftOptions.professions[prof.id] then
                local playerHasSkill = activeProfIDs[prof.id] or false
                ThornCraftOptions.professions[prof.id] = { 
                    show = playerHasSkill, 
                    onlyLearned = false, 
                    showAlt = false 
                }
            elseif ThornCraftOptions.professions[prof.id].showAlt == nil then
                ThornCraftOptions.professions[prof.id].showAlt = false
            end
        end

        -- NOW build the menu, using the accurate data
        BuildOptionsMenu()
    end
end)