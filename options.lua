local _, ADDONSELF = ...
local L = ADDONSELF.L
local RegEvent = ADDONSELF.regevent
local Database = ADDONSELF.db


local f = CreateFrame("Frame", nil, UIParent)
f.name = L["Raid Ledger"]
InterfaceOptions_AddCategory(f)

RegEvent("ADDON_LOADED", function()
    -- dropbox filter
    do
        local t = CreateFrame("Frame", nil, f, "UIDropDownMenuTemplate")
        t:SetPoint("TOPLEFT", f, 5, -30)

        local tt = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tt:SetPoint("BOTTOMLEFT", t, "TOPLEFT", 20, 0)
        tt:SetText(L["Auto record quality"])

        local onclick = function(self)
            UIDropDownMenu_SetSelectedValue(t, self.value)
            Database:SetConfig("filterlevel", self.value)
        end

        UIDropDownMenu_Initialize(t, function()
            local info = UIDropDownMenu_CreateInfo()
            info.text = ALL
            info.value = -1
            info.func = onclick
            info.classicChecks = true
            UIDropDownMenu_AddButton(info)
            for i = 0, getn(ITEM_QUALITY_COLORS)-4  do
                info.text = _G["ITEM_QUALITY"..i.."_DESC"]
                info.value = i
                info.func = onclick
                info.checked = nil
                UIDropDownMenu_AddButton(info)
            end
        end)

        UIDropDownMenu_SetSelectedValue(t, Database:GetConfigOrDefault("filterlevel", LE_ITEM_QUALITY_RARE))
    end
end)

-- 

