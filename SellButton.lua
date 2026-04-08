-- SellButton.lua
local ADDON_NAME, ns = ...

-- ==========================================
-- Merchant Auto-Sell UI (Icon Button)
-- ==========================================

local iconSource = "Interface\\Icons\\INV_Misc_Coin_01";

local sellButton = CreateFrame("Button", "ThornCraftSellButton", MerchantFrame)

-- Reduced to 28x28 to fit nicely in the header area
sellButton:SetSize(28, 28) 

-- Anchored to the top left. 
-- Tweak the 65 (left/right) or -30 (up/down) to perfectly center it in that gap!
sellButton:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 65, -30) 

-- ==========================================
-- Visual Styling: Native WoW Look
-- ==========================================

-- 1. THE ICON (Background Layer)
local icon = sellButton:CreateTexture(nil, "BACKGROUND")
icon:SetAllPoints(sellButton) 
icon:SetTexture(iconSource) 
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) 

-- 2. THE NATIVE BORDER (Overlay Layer)
local border = sellButton:CreateTexture(nil, "OVERLAY")
-- Scaled down proportionally (51x51) to keep the gold ring aligned with the 28x28 button
border:SetSize(51, 51) 
border:SetPoint("CENTER", sellButton, "CENTER", 0, 0)
border:SetTexture("Interface\\Buttons\\UI-Quickslot2")

-- 3. THE CLICK EFFECT & HOVER
sellButton:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
local pushed = sellButton:GetPushedTexture()
pushed:SetSize(51, 51) -- Match the new border size
pushed:ClearAllPoints()
pushed:SetPoint("CENTER", sellButton, "CENTER", 0, 0)

sellButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
local hover = sellButton:GetHighlightTexture()
hover:SetAllPoints(sellButton)

-- (Keep all your Tooltip, OnClick, and hooksecurefunc code below this exactly as it is!)

-- ==========================================
-- Interactivity
-- ==========================================

-- Wire up the Tooltip
sellButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Sell Outleveled Recipes", 1, 1, 1) 
    GameTooltip:AddLine("Automatically sell all recipes that no longer grant skill points from any of your learnt professions.", 1, 0.82, 0, true) 
    GameTooltip:Show()
end)

sellButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local function GetTrivialReagents()
    local itemsToSell = {}

    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            
            if itemID then
                local recipes = ns.ReagentToRecipeMap[itemID]
                if recipes then
                    local validRecipes = ns.GetValidRecipesToPrint(recipes)
                    
                    -- NEW: Pass the list directly to our helper function
                    if ns.AreAllRecipesTrivial(validRecipes) then
                        local _, _, _, _, _, _, _, _, _, _, itemSellPrice = C_Item.GetItemInfo(itemID)
                        
                        if itemSellPrice and itemSellPrice > 0 then
                            local stackInfo = C_Container.GetContainerItemInfo(bag, slot)
                            local stackCount = stackInfo and stackInfo.stackCount or 1
                            
                            table.insert(itemsToSell, {
                                bag = bag,
                                slot = slot,
                                price = itemSellPrice,
                                count = stackCount
                            })
                        end
                    end
                end
            end
        end
    end
    
    return itemsToSell
end

-- Wire up the click action
-- ==========================================
-- Interactivity
-- ==========================================
-- Wire up the click action
sellButton:SetScript("OnClick", function()
    local trivialItems = GetTrivialReagents()
    local totalEarned = 0
    local itemsSold = 0

    -- If the list is empty, stop here and tell the player
    if #trivialItems == 0 then
        print("|cFF00FFFF[ThornCraft]|r No outleveled reagents found to sell.")
        return
    end

    -- Process the list
    for _, item in ipairs(trivialItems) do
        -- Physically click the item in the bag to sell it
        C_Container.UseContainerItem(item.bag, item.slot) 
        
        totalEarned = totalEarned + (item.price * item.count)
        itemsSold = itemsSold + 1
    end
    
    -- Print the summary
    print("|cFF00FFFF[ThornCraft]|r Sold " .. itemsSold .. " stack(s) of outleveled reagents for " .. C_CurrencyInfo.GetCoinTextureString(totalEarned) .. ".")
end)

-- ==========================================
-- Buyback Tab Visibility Fix
-- ==========================================
-- Hook into WoW's native Merchant window update function
hooksecurefunc("MerchantFrame_Update", function()
    -- selectedTab == 1 is the main Vendor screen. Tab 2 is Buyback.
    if MerchantFrame.selectedTab == 1 then
        ThornCraftSellButton:Show()
    else
        ThornCraftSellButton:Hide()
    end
end)


-- ==========================================
-- State Management (Enable/Disable)
-- ==========================================
local function UpdateButtonState()
    -- Stop if the button is hidden (e.g., on the Buyback tab)
    if not sellButton:IsVisible() then return end
    
    local trivialItems = GetTrivialReagents()
    
    if #trivialItems > 0 then
        sellButton:Enable()
        icon:SetDesaturated(false) -- Restore the vibrant gold color
    else
        sellButton:Disable()
        icon:SetDesaturated(true)  -- Grey out the coin
    end
end

-- Fix the WoW quirk: Allow the tooltip to show even when the button is disabled
sellButton:SetMotionScriptsWhileDisabled(true)

-- Tell the button to update its state the moment it appears on screen
sellButton:SetScript("OnShow", UpdateButtonState)

-- Tell the button to update its state whenever your bag contents change
sellButton:RegisterEvent("BAG_UPDATE_DELAYED")
sellButton:SetScript("OnEvent", function(self, event)
    if event == "BAG_UPDATE_DELAYED" then
        UpdateButtonState()
    end
end)