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

    -- autoadd filter
    do
        -- TODO const
        local AUTOADDLOOT_TYPE_ALL = 0
        -- local AUTOADDLOOT_TYPE_PARTY = 1
        local AUTOADDLOOT_TYPE_RAID = 1
        local AUTOADDLOOT_TYPE_DISABLE = 2

        local t = CreateFrame("Frame", nil, f, "UIDropDownMenuTemplate")
        t:SetPoint("TOPLEFT", f, 150, -30)

        local tt = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tt:SetPoint("BOTTOMLEFT", t, "TOPLEFT", 20, 0)
        tt:SetText(L["Auto recording loot"])

        local onclick = function(self)
            UIDropDownMenu_SetSelectedValue(t, self.value)
            Database:SetConfig("autoaddloot", self.value)
        end

        UIDropDownMenu_Initialize(t, function()
            do
                local info = UIDropDownMenu_CreateInfo()
                info.text = ALL
                info.value = 0
                info.func = onclick
                UIDropDownMenu_AddButton(info)
            end

            do
                local info = UIDropDownMenu_CreateInfo()
                info.text = L["In Raid Only"]
                info.value = 1
                info.func = onclick
                UIDropDownMenu_AddButton(info)
            end

            do
                local info = UIDropDownMenu_CreateInfo()
                info.text = NONE
                info.value = 2
                info.func = onclick
                UIDropDownMenu_AddButton(info)
            end
        end)

        UIDropDownMenu_SetSelectedValue(t, Database:GetConfigOrDefault("autoaddloot", AUTOADDLOOT_TYPE_RAID))
    end

    local editDebitTemplate
    do
        local t = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        t:SetPoint("TOPLEFT", f, 25, -110)
        t:SetWidth(550)
        t:SetHeight(200)
        t:SetBackdrop({ 
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileEdge = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },    
        })
        t:SetBackdropColor(0, 0, 0);
    

        local edit = CreateFrame("EditBox", nil, t)
        edit.cursorOffset = 0
        edit:SetTextInsets(20, 20, 20, 20)
        edit:SetWidth(500)
        edit:SetHeight(150)
        -- edit:SetPoint("CENTER")
        edit:SetAutoFocus(false)
        edit:EnableMouse(true)
        edit:SetMaxLetters(99999999)
        edit:SetMultiLine(true)
        edit:SetFontObject(GameTooltipText)
        edit:SetScript("OnTextChanged", function(self)
            ScrollingEdit_OnTextChanged(self, t)
        end)
        edit:SetScript("OnCursorChanged", ScrollingEdit_OnCursorChanged)
        edit:SetScript("OnEscapePressed", edit.ClearFocus)

        t:SetScrollChild(edit)

        editDebitTemplate = edit
    end    

    do
        local t = CreateFrame("Frame", nil, f, "UIDropDownMenuTemplate")
        t:SetPoint("TOPLEFT", f, 5, -80)

        local tt = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tt:SetPoint("BOTTOMLEFT", t, "TOPLEFT", 20, 0)
        tt:SetText(L["Debit Template"])

        local onclick = function(self)
            UIDropDownMenu_SetSelectedValue(t, self.value)
            Database:SetConfig("debittemplateidx", self.value)
        end


        do
            local b = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
            b:SetWidth(70)
            b:SetHeight(25)
            b:SetPoint("TOPLEFT", t, 160, 0)
            b:SetText(NEW)
            b:SetScript("OnClick", function()
            end)
        end

        do
            local b = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
            b:SetWidth(70)
            b:SetHeight(25)
            b:SetPoint("TOPLEFT", t, 235, 0)
            b:SetText(SAVE)
            b:SetScript("OnClick", function()
            end)
        end

        do
            local b = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
            b:SetWidth(70)
            b:SetHeight(25)
            b:SetPoint("TOPLEFT", t, 310, 0)
            b:SetText(DELETE)
            b:SetScript("OnClick", function()
            end)
        end
       
        do
            local b = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
            b:SetWidth(70)
            b:SetHeight(25)
            b:SetPoint("TOPLEFT", t, 385, 0)
            b:SetText(L["Rename"])
            b:SetScript("OnClick", function()
            end)
        end

        do
            local b = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
            b:SetWidth(125)
            b:SetHeight(25)
            b:SetPoint("TOPLEFT", t, 460, 0)
            b:SetText(L["Import from ledger"])
            b:SetScript("OnClick", function()
            end)
        end

        -- UIDropDownMenu_Initialize(t, function()
        --     local info = UIDropDownMenu_CreateInfo()
        --     info.text = ALL
        --     info.value = -1
        --     info.func = onclick
        --     info.classicChecks = true
        --     UIDropDownMenu_AddButton(info)
        --     for i = 0, getn(ITEM_QUALITY_COLORS)-4  do
        --         info.text = _G["ITEM_QUALITY"..i.."_DESC"]
        --         info.value = i
        --         info.func = onclick
        --         info.checked = nil
        --         UIDropDownMenu_AddButton(info)
        --     end
        -- end)

        -- UIDropDownMenu_SetSelectedValue(t, Database:GetConfigOrDefault("filterlevel", LE_ITEM_QUALITY_RARE))        
    end

end)