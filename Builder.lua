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
local constantsChunk, err = loadfile("Recipes/Constants.lua")
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
                    table.insert(ReagentMap[rID], {
                        id = recipe.id,
                        name = recipe.name,
                        prof = source.prof
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
            out:write(string.format("        { id = %d, name = %q, prof = %d },\n", r.id, r.name, r.prof))
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
copyFile("ThornCraft.toc", "Release/ThornCraft/ThornCraft.toc")
copyFile("Core.lua", "Release/ThornCraft/Core.lua")
copyFile("ReagentIndex.lua", "Release/ThornCraft/ReagentIndex.lua")

print("\n[DONE] Build Complete! The 'Release/ThornCraft' folder is clean and ready to zip.")