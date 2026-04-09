-- builder.lua
print("Starting ThornCraft Build & Package Script...")

-- ==========================================
-- 1. CLEAN WORKSPACE
-- ==========================================
print("Cleaning old Release folder...")
local isWindows = package.config:sub(1,1) == '\\'

-- Safely delete the old directory and create a new one
if isWindows then
    os.execute('rmdir /s /q "Release" 2>nul')
    os.execute('mkdir "Release\\ThornCraft" 2>nul')
else
    os.execute('rm -rf "Release"')
    os.execute('mkdir -p "Release/ThornCraft"')
end

-- ==========================================
-- 2. INDEX GENERATOR
-- ==========================================
local ns = {}

-- Load Constants (Reads from the root folder now)
local constantsChunk, err = loadfile("Constants.lua")
if constantsChunk then
    constantsChunk("ThornCraft", ns)
else
    print("[ERROR] Could not load Constants.lua: " .. tostring(err))
    print("Make sure Constants.lua is in the same folder as this script!")
    return
end

-- Load your single recipe file
local files = {
    "Recipes/Blacksmithing.lua",
    "Recipes/Cooking.lua",
    "Recipes/Enchanting.lua",
    "Recipes/Alchemy.lua",
    "Recipes/Engineering.lua",
    "Recipes/JewelCrafting.lua",
    "Recipes/LeatherWorking.lua",
    "Recipes/Mining.lua",
    "Recipes/Tailoring.lua"
}

for _, file in ipairs(files) do
    local chunk, loadErr = loadfile(file)
    if chunk then
        chunk("ThornCraft", ns) 
    else
        print("Failed to load: " .. file .. " - " .. tostring(loadErr))
    end
end

local ReagentMap = {}
local sources = {
    { data = ns.BlacksmithingRecipes,  prof = 164 },
    { data = ns.EngineeringRecipes,    prof = 202 },
    { data = ns.AlchemyRecipes,        prof = 171 },
    { data = ns.LeatherWorkingRecipes, prof = 165 },
    { data = ns.TailoringRecipes,      prof = 197 },
    { data = ns.JewelCraftingRecipes,  prof = 755 },
    { data = ns.EnchantingRecipes,     prof = 333 },
    { data = ns.InscriptionRecipes,    prof = 773 },
    { data = ns.CookingRecipes,        prof = 185 },
    { data = ns.TailoringRecipes,         prof = 186 }
}

local recipeCount = 0
for _, source in ipairs(sources) do
    if source.data then
        for _, recipe in ipairs(source.data) do
            recipeCount = recipeCount + 1
            if recipe.reagents then
                for _, reagent in ipairs(recipe.reagents) do
                    local rID = reagent.itemId
                    ReagentMap[rID] = ReagentMap[rID] or {}
                    
                    -- Grab the gray level safely, default to nil if it doesn't exist
                    local grayLevel = (recipe.skillRange and recipe.skillRange.gray) or nil

                    -- Double check the table name matches what you have in Constants.lua!
                    local expKey = recipe.expansion or ns.Constants.EXPANSION.VANILLA
                    local expansionMap = ns.Constants.SKILL_LINE_IDS[source.prof] 
                    local specificSkillLineID = nil
                    if expansionMap then
                        specificSkillLineID = expansionMap[expKey] or expansionMap[ns.Constants.EXPANSION.VANILLA]
                    end

                    table.insert(ReagentMap[rID], {
                        id = recipe.id,
                        name = recipe.name,
                        baseProf = source.prof,          -- KEEP THIS: For Options menu and Fallback Icons (171)
                        prof = specificSkillLineID,      -- NEW: For your specific expansion skill check (2485)
                        expansion = expKey,              -- NEW: Expansion key (1)
                        gray = grayLevel                 
                    })
                end
            end
        end
    end
end

-- Write the index to the ROOT folder
local out = io.open("ReagentIndex.lua", "w")
if out then
    out:write("-- AUTO-GENERATED FILE. DO NOT EDIT MANUALLY.\n")
    out:write("local _, ns = ...\n\n")
    out:write("ns.ReagentToRecipeMap = {\n")

    for reagentID, recipes in pairs(ReagentMap) do
        out:write("    [" .. reagentID .. "] = {\n")
        for _, r in ipairs(recipes) do
            -- Format the gray value so it prints the number, or "nil" if it doesn't have one
            local grayStr = r.gray and tostring(r.gray) or "nil"
            
            -- Convert potentially nil values to strings so string.format doesn't crash
            local profStr = r.prof and tostring(r.prof) or "nil"
            local expStr = r.expansion and tostring(r.expansion) or "nil"
            local grayStr = r.gray and tostring(r.gray) or "nil"

            out:write(string.format("        { id = %d, name = %q, baseProf = %d, prof = %s, expansion = %s, gray = %s },\n", 
                r.id, 
                r.name, 
                r.baseProf, 
                profStr, 
                expStr, 
                grayStr))
        end
        out:write("    },\n")
    end

    out:write("}\n")
    out:close()
    print("[SUCCESS] Indexed " .. recipeCount .. " recipes into ReagentIndex.lua")
else
    print("[ERROR] Could not write ReagentIndex.lua.")
    return
end

-- ==========================================
-- 3. COPY FILES TO BUILD FOLDER
-- ==========================================
print("\nPackaging files...")

local function copyFile(sourcePath, destPath)
    local infile = io.open(sourcePath, "rb")
    if not infile then 
        print("  [SKIP] Could not find: " .. sourcePath)
        return false 
    end
    local content = infile:read("*a")
    infile:close()
    
    local outfile = io.open(destPath, "wb")
    if not outfile then
        print("  [ERROR] Could not write to: " .. destPath)
        return false
    end
    outfile:write(content)
    outfile:close()
    print("  [COPY] " .. sourcePath)
    return true
end

-- Copy everything into the flat Release/ThornCraft folder
sourceFiles ={
    "ThornCraft.toc",
    "Core.lua",
    "Constants.lua",
    "Options.lua",
    "DataCache.lua",
    "Professions.lua",
    "ReagentIndex.lua",
    "SellButton.lua",
    "SellOutdatedIcon.tga"
}
for _, file in ipairs(sourceFiles) do
    copyFile(file, "Release/ThornCraft/" .. file)
end

print("\n[DONE] Build Complete! The 'Release/ThornCraft' folder is clean and ready to zip.")