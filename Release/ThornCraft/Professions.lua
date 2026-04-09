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
function ns.GetValidRecipesToPrint(recipes)
    local validRecipesToPrint = {}

    for _, recipeData in ipairs(recipes) do
        local profOpt = ThornCraftOptions.professions[recipeData.prof]
        
        -- Fallback to true if something went wrong
        local shouldShow = profOpt and profOpt.show or false
        if profOpt == nil then shouldShow = true end 

        if shouldShow then
            -- 1. Determine which expansion this specific recipe belongs to
            local expKey = recipeData.expansion or ns.Constants.EXPANSION.VANILLA
            
            -- Grab the current player's data to check their skills
            local playerData = ns:InitPlayerCache()

            -- 2. Look up the skill level inside that specific expansion folder
            local skillLevel = nil
            if playerData.KnownProfessions[recipeData.prof] then
                local skillData = playerData.KnownProfessions[recipeData.prof][expKey]
                
                -- Extract the actual number out of our new data table!
                if skillData and skillData.level then
                    skillLevel = skillData.level
                end
            end
            
            local isKnownProf = (skillLevel ~= nil)
            local knownByNames = ""

            -- 3. Update the Alt-tracker to also check the specific expansion folder!
            if profOpt and profOpt.showAlt and ThornCraftCache.AltProfessions then
                for altName, altProfs in pairs(ThornCraftCache.AltProfessions) do
                    if altProfs[recipeData.prof] and altProfs[recipeData.prof][expKey] then
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

            -- NEW: Check if the recipe is completely grayed out for the current character
            local isTrivial = false
            if skillLevel and recipeData.gray and (skillLevel >= recipeData.gray) then
                isTrivial = true
            end

            local requireLearned = profOpt and profOpt.onlyLearned or false
            local passFilter = true
            
            if requireLearned and not isLearned then
                passFilter = false
            end

            if passFilter then
                table.insert(validRecipesToPrint, { 
                    data = recipeData, 
                    isKnown = isKnownProf, 
                    isLearned = isLearned,
                    isTrivial = isTrivial,
                    skillLevel = skillLevel and skillLevel or 0,
                    crafters = knownByNames or ""
                })
            end
        end
    end
    
    return validRecipesToPrint
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