-- Professions.lua
local ADDON_NAME, ns = ...

function ns.ScanProfessions()
    -- 1. Grab THIS specific character's data folder!
    local playerData = ns:InitPlayerCache()
    if not playerData then return end
    
    -- DO NOT WIPE THE CACHE! Initialize it if it doesn't exist, but keep existing data.
    playerData.KnownProfessions = playerData.KnownProfessions or {}
    
    local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()
    local knownIndices = {prof1, prof2, fishing, cooking, firstAid} 
    
    for _, index in pairs(knownIndices) do
        local name, _, baseSkillLevel, _, _, _, skillLine = GetProfessionInfo(index)
        
        if skillLine then
            local baseID = skillLine
            playerData.KnownProfessions[baseID] = playerData.KnownProfessions[baseID] or {}
            
            local expansionMap = ns.Constants and ns.Constants.SKILL_LINE_IDS and ns.Constants.SKILL_LINE_IDS[baseID]
            
            if expansionMap then
                for expKey, specificSkillID in pairs(expansionMap) do
                    local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(specificSkillID)
                    
                    -- ONLY overwrite the cache if the API gives us a real, loaded number
                    if info and info.skillLevel and info.skillLevel > 0 then
                        -- EXPLICIT DATA SAVE
                        playerData.KnownProfessions[baseID][expKey] = {
                            skillLineId = specificSkillID,
                            level = info.skillLevel,
                            maxLevel = info.maxSkillLevel or 0
                        }
                        ns.DebugPrint("Cached: " .. name .. " | Exp: " .. expKey .. " | Skill: " .. info.skillLevel)
                    end
                end
            else
                -- Fallback for basic Vanilla professions
                if baseSkillLevel > 0 then
                    playerData.KnownProfessions[baseID][1] = {
                        skillLineId = baseID,
                        level = baseSkillLevel,
                        maxLevel = 0 -- Base API doesn't always provide max easily here
                    }
                end
            end
            
            -- Failsafe: If the cache is empty, save the base Vanilla skill so it doesn't error
            if next(playerData.KnownProfessions[baseID]) == nil and baseSkillLevel > 0 then
                 playerData.KnownProfessions[baseID][1] = {
                     skillLineId = baseID,
                     level = baseSkillLevel,
                     maxLevel = 0
                 }
            end
        end
    end
    
    playerData.Initialized = true
end

-- Professions.lua

-- Create a function to filter and validate recipes based on user settings and skill levels
-- ==========================================
-- Recipe Validation (Single Character)
-- ==========================================
function ns.GetValidRecipesForCharacter(recipes, charKey)
    local validRecipes = {}
    
    -- Failsafe: Make sure the cache and character exist
    if not ThornCraftCache or type(ThornCraftCache[charKey]) ~= "table" then
        return validRecipes
    end
    
    local charData = ThornCraftCache[charKey]
    local isCurrentPlayer = (charKey == ns:GetPlayerKey())

    for _, recipeData in ipairs(recipes) do
        -- USE baseProf FOR LOOKUPS! 
        -- If baseProf is missing for some reason, fallback to prof just in case.
        local lookupID = recipeData.baseProf or recipeData.prof

        -- 1. UI Settings
        local profOpt = ThornCraftOptions.professions[lookupID]
        local shouldShow = profOpt and profOpt.show or false
        if profOpt == nil then shouldShow = true end 

        if shouldShow then
            local expKey = recipeData.expansion or ns.Constants.EXPANSION.VANILLA
            local skillLevel = nil
            
            -- 2. Character Skill Lookup
            if charData.KnownProfessions and charData.KnownProfessions[lookupID] then
                local skillData = charData.KnownProfessions[lookupID][expKey]
                if skillData and skillData.level then
                    skillLevel = skillData.level
                end
            end

            -- 3. The Filter 
            if skillLevel ~= nil then
                local isLearned = false
                
                -- Verify learned status for the active character
                if isCurrentPlayer and recipeData.id then
                    local info = C_TradeSkillUI.GetRecipeInfo(recipeData.id)
                    if info and info.learned then
                        isLearned = true
                    end
                end

                local isTrivial = false
                if recipeData.gray and (skillLevel >= recipeData.gray) then
                    isTrivial = true
                end

                local requireLearned = profOpt and profOpt.onlyLearned or false
                local passFilter = true
                
                if requireLearned and isCurrentPlayer and not isLearned then
                    passFilter = false
                end

                -- 4. Save to Payload
                if passFilter then
                    table.insert(validRecipes, { 
                        data = recipeData, 
                        isLearned = isLearned,
                        isTrivial = isTrivial,
                        skillLevel = skillLevel
                    })
                end
            end
        end
    end
    
    return validRecipes
end

-- ==========================================
-- Recipe Validation (Current Player Helper)
-- ==========================================
function ns.GetCurrentPlayerRecipes(recipes)
    -- 1. Grab the current player's unique key (e.g., "ThornHeart-Korgall")
    local currentPlayerKey = ns:GetPlayerKey()
    
    -- 2. Pass the recipes and the key into our newly refactored engine
    return ns.GetValidRecipesForCharacter(recipes, currentPlayerKey)
end

-- ==========================================
-- Trivial Recipe Check
-- ==========================================
function ns.AreAllRecipesTrivial(validRecipes)
    -- Failsafe: if there are no recipes, it can't be a trivial reagent
    if not validRecipes or #validRecipes == 0 then return false end
    
    for _, item in ipairs(validRecipes) do
        -- The moment we find even ONE recipe that grants skill, return false!
        if not item.isTrivial then
            return false
        end
    end
    
    -- If the loop finishes without returning false, everything is trivial
    return true
end