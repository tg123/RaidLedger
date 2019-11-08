local _, ADDONSELF = ...

ADDONSELF.gui = {
}
local GUI = ADDONSELF.gui

local L = ADDONSELF.L
local ScrollingTable = ADDONSELF.st
local RegEvent = ADDONSELF.regevent
local Database = ADDONSELF.db
local Print = ADDONSELF.print
local calcavg = ADDONSELF.calcavg
local GenExport = ADDONSELF.genexport
local GenReport = ADDONSELF.genreport

local function GetRosterNumber()
    local all = {}
    local dict = {}
    for i = 1, MAX_RAID_MEMBERS do
        local name = GetRaidRosterInfo(i)

        if name then
            dict[name] = 1
        end
    end

    dict[UnitName("player")] = 1

    for k in pairs(dict) do
        tinsert(all, k)
    end

    return #all
end

function GUI:Show()
    self.mainframe:Show()
end

function GUI:Hide()
    self.mainframe:Hide()
end

function GUI:Summary()
    return calcavg(Database:GetCurrentLedger()["items"], self:GetSplitNumber())
end

local CRLF = ADDONSELF.CRLF

function GUI:UpdateSummary()
    local profit, avg, revenue, expense = self:Summary()

    self.summaryLabel:SetText(L["Revenue"] .. " " .. GetMoneyString(revenue) .. CRLF
                           .. L["Expense"] .. " " .. GetMoneyString(expense) .. CRLF
                           .. L["Net Profit"] .. " " .. GetMoneyString(profit) .. CRLF
                           .. L["Per Member"] .. " " .. GetMoneyString(avg)
                        )
end

function GUI:GetSplitNumber()
    return tonumber(self.countEdit:GetText()) or 0
end

function GUI:UpdateLootTableFromDatabase()

    local data = {}

    for _ in pairs(Database:GetCurrentLedger()["items"]) do
        table.insert(data, 1, {
            ["cols"] = {
                {
                    ["value"] = #data + 1
                }, -- id
            },
        })
    end

    self.lootLogFrame:SetData(data)
    self:UpdateSummary()
end

local function GetEntryFromUI(rowFrame, cellFrame, data, cols, row, realrow, column, table)
    local rowdata = table:GetRow(realrow)
    if not rowdata then
        return nil
    end

    local celldata = table:GetCell(rowdata, column)
    local idx = rowdata["cols"][1].value

    local ledger = Database:GetCurrentLedger()
    local entry = ledger["items"][idx]
    return entry, idx
end

local function CreateCellUpdate(cb)
    return function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table, ...)
        if not fShow then
            return
        end

        local entry, idx = GetEntryFromUI(rowFrame, cellFrame, data, cols, row, realrow, column, table)

        if entry then
            cb(cellFrame, entry, idx)
        end
    end
end

function GUI:Init()

    local f = CreateFrame("Frame", nil, UIParent)
    f:SetWidth(650)
    f:SetHeight(550)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 8, right = 8, top = 10, bottom = 10}
    })

    f:SetBackdropColor(0, 0, 0)
    f:SetPoint("CENTER", 0, 0)
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    self.mainframe = f

    -- title
    do
        local t = f:CreateTexture(nil, "ARTWORK")
        t:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")
        t:SetWidth(256)
        t:SetHeight(64)
        t:SetPoint("TOP", f, 0, 12)
        f.texture = t
    end

    do
        local t = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        t:SetText(L["Raid Ledger"])
        t:SetPoint("TOP", f.texture, 0, -14)
    end
    -- title

    -- split member and editbox
    do
        local t = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        t:SetWidth(50)
        t:SetHeight(25)
        t:SetPoint("BOTTOMLEFT", f, 350, 95)
        t:SetAutoFocus(false)
        t:SetMaxLetters(4)
        t:SetNumeric(true)
        t:SetScript("OnTextChanged", function() self:UpdateSummary() end)

        self.countEdit = t
    end

    do
        local t = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        t:SetPoint("BOTTOMLEFT", f, 200, 100)
        local last = -1
        local update = function()
            local n = GetRosterNumber()
            if n == last then
                return
            end
            t:SetText(L["Split into (Current %d)"]:format(n))
            self.countEdit:SetText(n)
            last = GetRosterNumber()
        end
        update()
        RegEvent("GROUP_ROSTER_UPDATE", update)
        RegEvent("CHAT_MSG_SYSTEM", update) -- fuck above not working
    end
    --

    -- sum
    do
        local t = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        t:SetPoint("BOTTOMRIGHT", f, -40, 65)
        t:SetJustifyH("RIGHT")

        self.summaryLabel = t
    end

    -- export editbox
    do
        local t = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        t:SetPoint("TOPLEFT", f, 25, -30)
        t:SetWidth(580)
        t:SetHeight(360)

        local edit = CreateFrame("EditBox", nil, t)
        edit:SetWidth(580)
        edit:SetHeight(320)
        edit:SetPoint("TOPLEFT", t, 10, 0)
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

        self.exportEditbox = edit

        t:SetScrollChild(edit)

        t:Hide()
    end

    -- close btn
    do
        local b = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
        b:SetWidth(100)
        b:SetHeight(25)
        b:SetPoint("BOTTOMRIGHT", -40, 15)
        b:SetText(L["Close"])
        b:SetScript("OnClick", function() f:Hide() end)
    end

    -- clear btn
    do
        local b = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
        b:SetWidth(100)
        b:SetHeight(25)
        b:SetPoint("BOTTOMLEFT", 180, 15)
        b:SetText(L["Clear"])
        b:SetScript("OnClick", function()
            StaticPopup_Show("RAIDLEDGER_CLEARMSG")
        end)
    end

    -- credit
    do
        local b = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
        b:SetWidth(60)
        b:SetHeight(25)
        b:SetPoint("BOTTOMLEFT", 40, 95)
        b:SetText("+" .. L["Credit"])
        b:SetScript("OnClick", function()
            Database:AddCredit("")
            FauxScrollFrame_SetOffset(self.lootLogFrame.scrollframe, 0) -- move to top
        end)
    end

    -- debit
    do
        local b = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
        b:SetWidth(60)
        b:SetHeight(25)
        b:SetPoint("BOTTOMLEFT", 100, 95)
        b:SetText("+" .. L["Debit"])
        b:SetScript("OnClick", function()
            Database:AddDebit(L["Compensation"])
            FauxScrollFrame_SetOffset(self.lootLogFrame.scrollframe, 0) -- move to top
        end)
    end

    -- dropbox filter
    do
        local t = CreateFrame("Frame", nil, f, "UIDropDownMenuTemplate")
        t:SetPoint("BOTTOMLEFT", f, 320, 10)

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

    do
        self.itemtooltip = CreateFrame("GameTooltip", "RaidLedgerTooltipItem" .. random(10000), UIParent, "GameTooltipTemplate")
        self.commtooltip = CreateFrame("GameTooltip", "RaidLedgerTooltipComm" .. random(10000) , UIParent, "GameTooltipTemplate")
    end

    -- logframe
    do
        local tooltip = self.itemtooltip

        local CONVERT = L["#Try to convert to item link"]
        local autoCompleteDebit = function(text)
            text = string.upper(text)

            local data = {}

            for _, name in pairs({
                L["Compensation: Tank"],
                L["Compensation: Healer"],
                L["Compensation: Aqual Quintessence"],
                L["Compensation: Repait Bot"],
                L["Compensation: DPS"],
                L["Compensation: Other"],
            }) do
                local b = text == ""
                b = b or (text == "#ONFOCUS")
                b = b or (strfind(string.upper(name), text))

                if b then
                    tinsert(data, {
                        ["name"] = name,
                        ["priority"] = LE_AUTOCOMPLETE_PRIORITY_IN_GROUP,
                    })
                end
            end

            return data
        end

        local autoCompleteCredit = function(text)
            local data = {}

            txt = strtrim(txt or "")
            txt = strtrim(txt, "[]")
            local name = GetItemInfo(text)

            if name then
                tinsert(data, {
                    ["name"] = CONVERT,
                    ["priority"] = LE_AUTOCOMPLETE_PRIORITY_IN_GROUP,
                })
            end

            return data
        end

        local autoCompleteRaidRoster = function(text)
            local data = {}

            for i = 1, MAX_RAID_MEMBERS do
                local name, _, subgroup, _, class = GetRaidRosterInfo(i)

                if name then
                    name = string.lower(name)
                    class = string.lower(class)

                    local b = text == ""
                    b = b or (text == "#ONFOCUS")
                    b = b or (strfind(name, string.lower(text)))
                    b = b or (tonumber(text) == subgroup)
                    b = b or (strfind(class, string.lower(text)))

                    if b then
                        tinsert(data, {
                            ["name"] = name,
                            ["priority"] = LE_AUTOCOMPLETE_PRIORITY_IN_GROUP,
                        })
                    end
                end
            end

            return data
        end

        local popOnFocus = function(edit)
            edit:SetScript("OnTextChanged", function(self, userInput)

                AutoCompleteEditBox_OnTextChanged(self, userInput)

                local t = self:GetText()

                edit.customTextChangedCallback(t)

                if t == "" then
                    t = "#ONFOCUS"
                end
                AutoComplete_Update(self, t, 1);
            end)

            edit:SetScript("OnEditFocusGained", function(self)
                local t = self:GetText()
                if t == "" then
                    t = "#ONFOCUS"
                end
                AutoComplete_Update(self, t, 1);
            end)
        end

        local iconUpdate = CreateCellUpdate(function(cellFrame, entry)
            if not (cellFrame.cellItemTexture) then
                cellFrame.cellItemTexture = cellFrame:CreateTexture()
                cellFrame.cellItemTexture:SetTexCoord(0, 1, 0, 1)
                cellFrame.cellItemTexture:Show()
                cellFrame.cellItemTexture:SetPoint("CENTER", cellFrame.cellItemTexture:GetParent(), "CENTER")
                cellFrame.cellItemTexture:SetWidth(30)
                cellFrame.cellItemTexture:SetHeight(30)
            end

            cellFrame:SetScript("OnEnter", nil)

            if entry["type"] == "DEBIT" then
                cellFrame.cellItemTexture:SetTexture(135768) -- minus
            else
                cellFrame.cellItemTexture:SetTexture(135769) -- plus
            end

            local detail = entry["detail"]
            if detail["type"] == "ITEM" then
                local itemTexture =  GetItemIcon(detail["item"])
                local _, itemLink = GetItemInfo(detail["item"])

                if itemTexture then
                    cellFrame.cellItemTexture:SetTexture(itemTexture)
                end

                if itemLink then
                    cellFrame:SetScript("OnEnter", function()
                        tooltip:SetOwner(cellFrame, "ANCHOR_RIGHT")
                        tooltip:SetHyperlink(itemLink)
                        tooltip:Show()
                    end)

                    cellFrame:SetScript("OnLeave", function()
                        tooltip:Hide()
                        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
                    end)

                end
            end
        end)

        local entryUpdate = CreateCellUpdate(function(cellFrame, entry)

            if not (cellFrame.textBox) then
                cellFrame.textBox = CreateFrame("EditBox", nil, cellFrame, "InputBoxTemplate,AutoCompleteEditBoxTemplate")
                cellFrame.textBox:SetPoint("CENTER", cellFrame, "CENTER", -20, 0)
                cellFrame.textBox:SetWidth(120)
                cellFrame.textBox:SetHeight(30)
                cellFrame.textBox:SetAutoFocus(false)
                cellFrame.textBox:SetScript("OnEscapePressed", cellFrame.textBox.ClearFocus)
                popOnFocus(cellFrame.textBox)
            end

            cellFrame.textBox:Hide()

            local detail = entry["detail"]
            if detail["type"] == "ITEM" then
                local _, itemLink = GetItemInfo(detail["item"])
                if itemLink then
                    cellFrame.text:SetText(itemLink)
                    return
                end
            end

            if entry["type"] == "DEBIT" then
                cellFrame.text:SetText(L["Debit"])
                AutoCompleteEditBox_SetAutoCompleteSource(cellFrame.textBox, autoCompleteDebit)
            else
                cellFrame.text:SetText(L["Credit"])
                AutoCompleteEditBox_SetAutoCompleteSource(cellFrame.textBox, autoCompleteCredit)
            end

            cellFrame.textBox.customTextChangedCallback = function(t)
                entry["detail"]["displayname"] = t
            end

            -- TODO optimize
            cellFrame.textBox.customAutoCompleteFunction = function(editBox, newText, info)
                local n = newText ~= "" and newText or info.name

                if n ~= "" then
                    if entry["type"] ~= "DEBIT" and n == CONVERT then
                        local txt = editBox:GetText()
                        txt = strtrim(txt)
                        txt = strtrim(txt, "[]")
                        local _, itemLink = GetItemInfo(txt)

                        if itemLink then
                            entry["detail"]["item"] = itemLink
                            entry["detail"]["displayname"] = nil
                            entry["detail"]["type"] = "ITEM"
                            self:UpdateLootTableFromDatabase()
                        else
                            Print(L["convert failed, text can be either item id or item name"])
                        end

                        return true
                    end

                    cellFrame.textBox:SetText(n)
                    entry["detail"]["displayname"] = n
                end

                return true
            end

            cellFrame.textBox:Show()
            cellFrame.textBox:SetText(detail["displayname"] or "")
        end)

        local beneficiaryUpdate = CreateCellUpdate(function(cellFrame, entry)
            if not (cellFrame.textBox) then
                cellFrame.textBox = CreateFrame("EditBox", nil, cellFrame, "InputBoxTemplate,AutoCompleteEditBoxTemplate")
                cellFrame.textBox:SetPoint("CENTER", cellFrame, "CENTER", -20, 0)
                cellFrame.textBox:SetWidth(120)
                cellFrame.textBox:SetHeight(30)
                cellFrame.textBox:SetAutoFocus(false)
                cellFrame.textBox:SetScript("OnEscapePressed", cellFrame.textBox.ClearFocus)
                AutoCompleteEditBox_SetAutoCompleteSource(cellFrame.textBox, autoCompleteRaidRoster)
                popOnFocus(cellFrame.textBox)
            end

            cellFrame.textBox.customTextChangedCallback = function(t)
                entry["beneficiary"] = t
            end

            cellFrame.textBox.customAutoCompleteFunction = function(editBox, newText, info)
                local n = newText ~= "" and newText or info.name

                if n ~= "" then
                    cellFrame.textBox:SetText(n)
                    entry["beneficiary"] = n
                end

                return true
            end

            cellFrame.textBox:SetText(entry.beneficiary or "")
        end)

        local menuFrame = CreateFrame("Frame", nil, UIParent, "UIDropDownMenuTemplate")

        local valueTypeMenuCtx = {}
        local setCostType = function(t)
            local entry = valueTypeMenuCtx.entry
            entry["costtype"] = t
            self:UpdateLootTableFromDatabase()
        end

        local valueTypeMenu = {
            {   
                costtype = "GOLD",
                text = GOLD_AMOUNT_TEXTURE_STRING:format(""), 
                func = function() 
                    setCostType("GOLD")
                end, 
            },
            { 
                costtype = "PROFIT_PERCENT",
                text = " % " .. L["Net Profit"], 
                func = function() 
                    setCostType("PROFIT_PERCENT")
                end, 
            },
            { 
                costtype = "MUL_AVG",
                text = " * " .. L["Per Member credit"], 
                func = function() 
                    setCostType("MUL_AVG")
                end, 
            },
        }        

        local valueUpdate = CreateCellUpdate(function(cellFrame, entry)
            if not (cellFrame.textBox) then
                cellFrame.textBox = CreateFrame("EditBox", nil, cellFrame, "InputBoxTemplate")
                cellFrame.textBox:SetPoint("CENTER", cellFrame, "CENTER")
                cellFrame.textBox:SetWidth(70)
                cellFrame.textBox:SetHeight(30)
                cellFrame.textBox:SetNumeric(true)
                cellFrame.textBox:SetAutoFocus(false)
                cellFrame.textBox:SetMaxLetters(7)
            end
            cellFrame.textBox:SetText(tostring(entry["cost"] or 0))

            local type = entry["costtype"] or "GOLD"

            if type == "PROFIT_PERCENT" then
                cellFrame.text:SetText("%")
            elseif type == "MUL_AVG" then
                cellFrame.text:SetText("*")
            else
                -- GOLD by default
                cellFrame.text:SetText(GOLD_AMOUNT_TEXTURE_STRING:format(""))
            end

            cellFrame:SetScript("OnClick", nil)

            if entry["type"] == "DEBIT" then
                cellFrame:SetScript("OnClick", function()
                    valueTypeMenuCtx.entry = entry
                    for _, m in pairs(valueTypeMenu) do
                        m.checked = m.costtype == type
                    end
                
                    EasyMenu(valueTypeMenu, menuFrame, "cursor", 0 , 0, "MENU");
                end)
            end

            cellFrame.textBox:SetScript("OnTextChanged", function(self, userInput)
                entry["cost"] = tonumber(cellFrame.textBox:GetText()) or 0
                GUI:UpdateLootTableFromDatabase()
            end)

        end)

        self.lootLogFrame = ScrollingTable:CreateST({
            {
                ["name"] = "",
                ["width"] = 1,
            },
            {
                ["name"] = "",
                ["width"] = 50,
                ["DoCellUpdate"] = iconUpdate,
            },
            {
                ["name"] = L["Entry"],
                ["width"] = 250,
                ["DoCellUpdate"] = entryUpdate,
            },
            {
                ["name"] = L["Beneficiary"],
                ["width"] = 150,
                ["DoCellUpdate"] = beneficiaryUpdate,
            },
            {
                ["name"] = L["Value"],
                ["width"] = 100,
                ["align"] = "RIGHT",
                ["DoCellUpdate"] = valueUpdate,
            }
        }, 12, 30, nil, f)

        self.lootLogFrame.head:SetHeight(15)
        self.lootLogFrame.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 30, -50)

        self.lootLogFrame:RegisterEvents({
            ["OnClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, sttable, button, ...)
                local entry, idx = GetEntryFromUI(rowFrame, cellFrame, data, cols, row, realrow, column, sttable)

                if not entry then
                    return
                end

                if button == "RightButton" then

                    StaticPopupDialogs["RAIDLEDGER_DELETE_ITEM"].OnAccept = function()
                        StaticPopup_Hide("RAIDLEDGER_DELETE_ITEM")
                        Database:RemoveEntry(idx)
                    end
                    StaticPopup_Show("RAIDLEDGER_DELETE_ITEM")
                else
                    ChatEdit_InsertLink(entry["detail"]["item"])
                end
            end,
        })
    end


    -- report btn
    do
        local b = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
        b:SetWidth(120)
        b:SetHeight(25)
        b:SetPoint("BOTTOMLEFT", 40, 15)
        b:SetText(L["Report"])
        b:SetScript("OnClick", function()
            GenReport(Database:GetCurrentLedger()["items"], GUI:GetSplitNumber())
        end)
    end

    -- export btn
    do
        local lootLogFrame = self.lootLogFrame
        local exportEditbox = self.exportEditbox
        local countEdit = self.countEdit

        local b = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
        b:SetWidth(120)
        b:SetHeight(25)
        b:SetPoint("BOTTOMLEFT", 40, 60)
        b:SetText(L["Export as text"])
        b:SetScript("OnClick", function()
            if exportEditbox:GetParent():IsShown() then
                lootLogFrame:Show()
                countEdit:Show()
                exportEditbox:GetParent():Hide()
                b:SetText(L["Export as text"])
            else
                countEdit:Hide()
                lootLogFrame:Hide()
                exportEditbox:GetParent():Show()
                b:SetText(L["Close text export"])
            end

            exportEditbox:SetText(GenExport(Database:GetCurrentLedger()["items"], GUI:GetSplitNumber()))
        end)
    end

end

RegEvent("ADDON_LOADED", function()
    GUI:Init()
    Database:RegisterChangeCallback(function()
        GUI:UpdateLootTableFromDatabase()
    end)

    GUI:UpdateLootTableFromDatabase()

    -- raid frame handler

    do
        if _G.RaidFrame then
            local b = CreateFrame("Button", nil, _G.RaidFrame, "UIPanelButtonTemplate")
            b:SetWidth(100)
            b:SetHeight(20)
            b:SetPoint("TOPRIGHT", -25, 0)
            b:SetText(L["Raid Ledger"])
            b:SetScript("OnClick", function()
                if GUI.mainframe:IsShown() then
                    GUI.mainframe:Hide()
                else
                    GUI.mainframe:Show()
                end
            end)
        end

        local hooked = false

        hooksecurefunc("RaidFrame_LoadUI", function()
            if hooked then
                return
            end

            local tooltip = GUI.commtooltip

            local enter = function(l, idx)
                local _, avg = calcavg(Database:GetCurrentLedger()["items"], GUI:GetSplitNumber())

                local c = 0
                for i = 1, MAX_RAID_MEMBERS do
                    local name, _, subgroup = GetRaidRosterInfo(i)
                    if name and subgroup == idx then
                        c = c + 1
                    end
                end

                if c > 0 then
                    local s = L["Per Member"] .. " :" .. GetMoneyString(avg) .. CRLF
                           .. L["Subgroup total"] .. " :" .. GetMoneyString(c * avg)

                    tooltip:SetOwner(l, "ANCHOR_TOP")
                    tooltip:SetText(s)
                    tooltip:Show()
                end
            end

            local leave = function()
                tooltip:Hide()
                tooltip:SetOwner(UIParent, "ANCHOR_NONE")
            end

            for i = 1, NUM_RAID_GROUPS do
                local l = _G["RaidGroup" .. i .."Label"]
                if l then
                    l:SetScript("OnEnter", function() enter(l, i) end)
                    l:SetScript("OnLeave", leave)
                end
            end

            hooked = true
        end)
    end
end)

StaticPopupDialogs["RAIDLEDGER_CLEARMSG"] = {
    text = L["Remove all records?"],
    button1 = ACCEPT,
    button2 = CANCEL,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    multiple = 0,
    OnAccept = function()
        Database:NewLedger()
    end,
}

StaticPopupDialogs["RAIDLEDGER_DELETE_ITEM"] = {
    text = L["Remove this record?"],
    button1 = ACCEPT,
    button2 = CANCEL,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    multiple = 0,
}