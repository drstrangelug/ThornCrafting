local addonName, _ = ...

-- Create the main frame
local frame = CreateFrame("Frame", "LugToolsMoneyFrame", UIParent, "BackdropTemplate")
frame:SetSize(180, 40)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

-- Basic styling
frame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.7)

-- Font string to display the money
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER", frame, "CENTER", 0, 0)

-- Handle moving
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    LugToolsDB.point = point
    LugToolsDB.relativePoint = relativePoint
    LugToolsDB.xOfs = xOfs
    LugToolsDB.yOfs = yOfs
end)

-- Update money function
local function UpdateMoney()
    local money = GetMoney()
    text:SetText(GetCoinTextureString(money))
end

-- Event handling
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_MONEY")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize SavedVariables
        LugToolsDB = LugToolsDB or {}
        
        -- Restore position if it exists
        if LugToolsDB.point then
            self:ClearAllPoints()
            self:SetPoint(LugToolsDB.point, UIParent, LugToolsDB.relativePoint, LugToolsDB.xOfs, LugToolsDB.yOfs)
        end
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_MONEY" then
        UpdateMoney()
    end
end)