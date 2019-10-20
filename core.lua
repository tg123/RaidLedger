local ScrollingTable = LibStub("ScrollingTable");
local deformat = LibStub("LibDeformat-3.0");

local FIN_AID = "补助"

local function GetMoneyStringL(money, separateThousands)
	local goldString, silverString, copperString;
	local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD));
	local silver = floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
	local copper = mod(money, COPPER_PER_SILVER);

	if ( true ) then
		if (separateThousands) then
			goldString = FormatLargeNumber(gold)..GOLD_AMOUNT_SYMBOL;
		else
			goldString = gold..GOLD_AMOUNT_SYMBOL;
		end
		silverString = silver..SILVER_AMOUNT_SYMBOL;
		copperString = copper..COPPER_AMOUNT_SYMBOL;
	else
		if (separateThousands) then
			goldString = GOLD_AMOUNT_TEXTURE_STRING:format(FormatLargeNumber(gold), 0, 0);
		else
			goldString = GOLD_AMOUNT_TEXTURE:format(gold, 0, 0);
		end
		silverString = SILVER_AMOUNT_TEXTURE:format(silver, 0, 0);
		copperString = COPPER_AMOUNT_TEXTURE:format(copper, 0, 0);
	end

	local moneyString = "";
	local separator = "";
	if ( gold > 0 ) then
		moneyString = goldString;
		separator = " ";
	end
	if ( silver > 0 ) then
		moneyString = moneyString..separator..silverString;
		separator = " ";
	end
	if ( copper > 0 or moneyString == "" ) then
		moneyString = moneyString..separator..copperString;
	end

	return moneyString;
end

local function GetRoster() 
    local all = {}
    local dict = {}
    for i = 1, MAX_RAID_MEMBERS do
        local name, _, subgroup, _, class = GetRaidRosterInfo(i)

        if name then
            dict[name] = 1
        end
    end

    dict[UnitName("player")] = 1

    for k in pairs(dict) do
        tinsert(all, k)
    end

    return all
end

local function UpdateCountLabel()
    RAIDLEDGER_ReportFrameCountLabel:SetText("分钱人数(" .. "当前" .. #GetRoster() .. "):")
    RAIDLEDGER_ReportFrameCount:SetText(#GetRoster() .. "")
end

local function Sum()
    local n = tonumber(RAIDLEDGER_ReportFrameCount:GetText())
    if not n then
        n = 0
    end

    local sum = 0
    for k, item in pairs(RaidLedger_Ledger["items"] or {}) do
        if item["item"] == FIN_AID then
            sum = sum - (item["cost"] or 0)
        else
            sum = sum + (item["cost"] or 0)
        end
    end

    sum = math.max( sum, 0)
    local avg = 0

    if n > 0 then
        avg = 1.0 * sum / n
        avg = math.max( avg, 0)
        avg = math.floor( avg * 10000 ) / 10000
    end

    return sum, avg , n
end

local function UpdateSumLabel()
    local sum, avg = Sum()
    sum = GetMoneyString(sum * 10000)
    avg = GetMoneyString(avg * 10000)
    RAIDLEDGER_ReportFrameSumLabel:SetText("总收入" .. sum .. "\r\n人均" .. avg)
end

local function SendToCurrrentChannel(msg)
    local chatType = DEFAULT_CHAT_FRAME.editBox:GetAttribute("chatType")
    local whisperTo = DEFAULT_CHAT_FRAME.editBox:GetAttribute("tellTarget")
    if chatType == "WHISPER" then
        SendChatMessage(msg, chatType, nil, whisperTo)
    elseif chatType == "CHANNEL" then
        SendChatMessage(msg, chatType, nil, DEFAULT_CHAT_FRAME.editBox:GetAttribute("channelTarget"))
    elseif chatType == "BN_WHISPER" then
        BNSendWhisper(BNet_GetBNetIDAccount(whisperTo), msg)
    else
        SendChatMessage(msg, chatType)
    end
end

local UpdateLootTable = function() end

local LootLogFrame = ScrollingTable:CreateST({
    {
        ["name"] = "",
        ["width"] = 1,
    },
    {
        ["name"] = "",
        ["width"] = 50,
        ["DoCellUpdate"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table, ...)
            if not fShow then
                return
            end

            local rowdata = table:GetRow(realrow)
            local celldata = table:GetCell(rowdata, column)
            cellvalue = celldata.value;
            -- print(celldata.value)
            local itemTexture =  GetItemIcon(celldata.value)

            -- print(itemTexture)
            -- core copy from https://www.curseforge.com/wow/addons/classic-raid-tracker
            if not (cellFrame.cellItemTexture) then
                cellFrame.cellItemTexture = cellFrame:CreateTexture()
            end

            cellFrame.cellItemTexture:SetTexture(itemTexture)

            if not itemTexture then
                return 
            end

            cellFrame.cellItemTexture:SetTexCoord(0, 1, 0, 1)
            cellFrame.cellItemTexture:Show()
            cellFrame.cellItemTexture:SetPoint("CENTER", cellFrame.cellItemTexture:GetParent(), "CENTER")
            cellFrame.cellItemTexture:SetWidth(30)
            cellFrame.cellItemTexture:SetHeight(30)

            cellFrame:SetScript("OnEnter", function()
                RAIDLEDGER_ItemToolTip:SetOwner(cellFrame, "ANCHOR_RIGHT")
                RAIDLEDGER_ItemToolTip:SetHyperlink(celldata.value)
                RAIDLEDGER_ItemToolTip:Show()
              end)

            cellFrame:SetScript("OnLeave", function()
                RAIDLEDGER_ItemToolTip:Hide()
                RAIDLEDGER_ItemToolTip:SetOwner(UIParent, "ANCHOR_NONE")
            end)
        end,
    },
    {
        ["name"] = "物品",
        ["width"] = 250,
    },
    {
        ["name"] = "拾取",
        ["width"] = 150,
        ["DoCellUpdate"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table, ...)
            if not fShow then
                return
            end

            local rowdata = table:GetRow(realrow)
            local celldata = table:GetCell(rowdata, column)
            cellvalue = celldata.value

            if not (cellFrame.textBox) then
                cellFrame.textBox = CreateFrame("EditBox", nil, cellFrame, "InputBoxTemplate,AutoCompleteEditBoxTemplate")
            end

            cellFrame.textBox:SetPoint("CENTER", cellFrame, "CENTER", -20, 0)
            cellFrame.textBox:SetWidth(120)
            cellFrame.textBox:SetHeight(30)
            cellFrame.textBox:SetAutoFocus(false)
            cellFrame.textBox:SetText(cellvalue)
            cellFrame.textBox.customAutoCompleteFunction = function(editBox, newText, info)
                local n = newText ~= "" and newText or info.name

                if n ~= "" then
                    cellFrame.textBox:SetText(n)
                    local rowdata = table:GetRow(realrow)
                    local idx = rowdata["cols"][1].value
                    RaidLedger_Ledger["items"][idx]["looter"] = n
                    UpdateLootTable()                
                end

                return true
            end

            AutoCompleteEditBox_SetAutoCompleteSource(cellFrame.textBox, function(text)
                -- print(text)

                local data = {}

                for i = 1, MAX_RAID_MEMBERS do
                    local name, _, subgroup, _, class = GetRaidRosterInfo(i)

                    if name then
                        name = string.lower(name)
                        class = string.lower(class)

                        local b = text == ""
                        b = b or (text == "#ONFOCUS")
                        b = b or (strfind(name, text))
                        b = b or (tonumber(text) == subgroup)
                        b = b or (strfind(class, text))

                        if b then
                            tinsert(data, {
                                ["name"] = name,
                                ["priority"] = LE_AUTOCOMPLETE_PRIORITY_IN_GROUP,
                            })
                        end
                    end
                end

                return data
            end)

            cellFrame.textBox:SetScript("OnTextChanged", function(self, userInput)

                AutoCompleteEditBox_OnTextChanged(self, userInput)

                local t = self:GetText()

                if t ~= "" then
                    local rowdata = table:GetRow(realrow)
                    local idx = rowdata["cols"][1].value
                    RaidLedger_Ledger["items"][idx]["looter"] = t
                    UpdateLootTable()
                end

                if t == "" then
                    t = "#ONFOCUS"
                end
                AutoComplete_Update(self, t, 1);
            end)

            cellFrame.textBox:SetScript("OnEditFocusGained", function(self)
                local t = self:GetText()
                if t == "" then
                    t = "#ONFOCUS"
                end
                AutoComplete_Update(self, t, 1);
            end)

        end,
    },
    {
        ["name"] = "价格",
        ["width"] = 100,
        ["align"] = "RIGHT",
        ["DoCellUpdate"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table, ...)
            if not fShow then
                return
            end

            local rowdata = table:GetRow(realrow)
            local celldata = table:GetCell(rowdata, column)
            cellvalue = celldata.value

            if not (cellFrame.textBox) then
                cellFrame.textBox = CreateFrame("EditBox", nil, cellFrame, "InputBoxTemplate")

            end

            cellFrame.text:SetText(GOLD_AMOUNT_TEXTURE_STRING:format(""))
            cellFrame.textBox:SetPoint("CENTER", cellFrame, "CENTER")
            cellFrame.textBox:SetWidth(70)
            cellFrame.textBox:SetHeight(30)
            cellFrame.textBox:SetNumeric(true)
            cellFrame.textBox:SetAutoFocus(false)
            cellFrame.textBox:SetText(cellvalue)



            cellFrame.textBox:SetScript("OnTextChanged", function(self, userInput)
                local rowdata = table:GetRow(realrow)
                local idx = rowdata["cols"][1].value
                RaidLedger_Ledger["items"][idx]["cost"] = tonumber(cellFrame.textBox:GetText()) or 0

                
                UpdateSumLabel()
                UpdateLootTable()
            end)


        end,
    }
}, 12, 30, nil, RAIDLEDGER_ReportFrame)

UpdateLootTable = function()

    local data = {}

    for k, item in pairs(RaidLedger_Ledger["items"] or {}) do

        if item["item"] then
            table.insert(data, {
                ["cols"] = {
                    {
                        ["value"] = #data + 1
                    }, -- id
                    {
                        ["value"] = item["item"]
                    }, -- icon
                    {
                        ["value"] = item["item"]
                    }, -- icon
                    {
                        ["value"] = item["looter"] or ""
                    },
                    {
                        ["value"] = item["cost"] or 0
                    },
                },
            })
        end

    end

    LootLogFrame:SetData(data)
    UpdateSumLabel()
end

local function AddLoot(item, looter, cost, force)
    if not RaidLedger_Ledger["items"] then
        RaidLedger_Ledger["items"] = {}
    end

    if item == FIN_AID then
        table.insert(RaidLedger_Ledger["items"], {
            ["item"] = FIN_AID,
            ["looter"] = looter,
            ["cost"] = cost,
        })

    else

        local _, itemLink, itemRarity = GetItemInfo(item)

        if (not force) and (itemRarity < UIDropDownMenu_GetSelectedValue(RAIDLEDGER_ReportFrameFilterDropDown)) then
            return
        end

        if itemLink then
            table.insert(RaidLedger_Ledger["items"], {
                ["item"] = itemLink,
                ["looter"] = looter,
                ["cost"] = cost,
            })
        end
    end


    UpdateLootTable()
end


local f = CreateFrame("Frame")
local m = {}
f:SetScript("OnEvent",function(self, event, ...) 
    local cb = m[event]
    if cb then
        cb(...)
    end
end)

local function RegEvent(event, cb)
    if m[event] then
        return
    end

    f:RegisterEvent(event)
    m[event] = cb
end



RegEvent("RAID_ROSTER_UPDATE", function()
    UpdateCountLabel()
end)

-- fuck above not working
RegEvent("CHAT_MSG_SYSTEM", function()
    UpdateCountLabel()
end)

RegEvent("CHAT_MSG_LOOT", function(chatmsg)
    local playerName, itemLink, itemCount = deformat(chatmsg, LOOT_ITEM_MULTIPLE);
    -- next try: somebody else received single loot
    if (playerName == nil) then
        itemCount = 1;
        playerName, itemLink = deformat(chatmsg, LOOT_ITEM);
    end
    -- if player == nil, then next try: player received multiple loot
    if (playerName == nil) then
        playerName = UnitName("player");
        itemLink, itemCount = deformat(chatmsg, LOOT_ITEM_SELF_MULTIPLE);
    end
    -- if itemLink == nil, then last try: player received single loot
    if (itemLink == nil) then
        itemCount = 1;
        itemLink = deformat(chatmsg, LOOT_ITEM_SELF);
    end
    -- if itemLink == nil, then there was neither a LOOT_ITEM, nor a LOOT_ITEM_SELF message
    if (itemLink == nil) then
        -- MRT_Debug("No valid loot event received.");
        return;
    end
    -- if code reaches this point, we should have a valid looter and a valid itemLink
    -- print(itemLink)
    for i = 1, itemCount do 
        AddLoot(itemLink, playerName, 0);
    end
end)

RegEvent("ADDON_LOADED", function()
    local FRAMENAME = 'RAIDLEDGER_ReportFrame'

    _G[FRAMENAME .. 'CloseButton']:SetScript('OnClick', function()
        RAIDLEDGER_ReportFrame:Hide()
    end)

    if RaidLedger_Ledger == nil then
        RaidLedger_Ledger = {}
        RaidLedger_Ledger["config"] = {}
        RaidLedger_Ledger["config"]["filterlevel"] = LE_ITEM_QUALITY_RARE
    end

	if RaidLedger_Ledger and RaidLedger_Ledger["config"] and RaidLedger_Ledger["config"]["filterlevel"] then
        UIDropDownMenu_SetSelectedValue(RAIDLEDGER_ReportFrameFilterDropDown, RaidLedger_Ledger["config"]["filterlevel"])
	end


    LootLogFrame.head:SetHeight(15)
    LootLogFrame.frame:SetPoint("TOPLEFT", RAIDLEDGER_ReportFrame, "TOPLEFT", 30, -50)
    -- LootLogFrame:EnableSelection(true)

    UpdateLootTable()

    LootLogFrame:RegisterEvents({
        ["OnClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, sttable, button, ...)
            local rowdata = sttable:GetRow(realrow)
            if not rowdata then
                return
            end
            local idx = rowdata["cols"][1].value
                                
            if button == "RightButton" then
                -- print(idx)
                StaticPopupDialogs["RAIDLEDGER_DELETE_ITEM"].OnAccept = function()
                    StaticPopup_Hide("RAIDLEDGER_DELETE_ITEM")
                    table.remove(RaidLedger_Ledger["items"], idx)
                    UpdateLootTable()
                end
                StaticPopup_Show("RAIDLEDGER_DELETE_ITEM")                
            else
                ChatEdit_InsertLink(RaidLedger_Ledger["items"][idx]["item"])
            end
        end,
    })

    RAIDLEDGER_ReportFrameFinAidButton:SetScript("OnClick", function()
        AddLoot(FIN_AID)
    end)

    RAIDLEDGER_ReportFrameExportButton:SetText("以文本显示")

    RAIDLEDGER_ReportFrameExportButton:SetScript("OnClick", function()
        if RAIDLEDGER_ReportFrameScrollFrame:IsShown() then
            LootLogFrame:Show()
            RAIDLEDGER_ReportFrameCount:Show()
            RAIDLEDGER_ReportFrameCountLabel:Show()

            RAIDLEDGER_ReportFrameScrollFrame:Hide()
            RAIDLEDGER_ReportFrameExportButton:SetText("以文本显示")
        else
            LootLogFrame:Hide()
            RAIDLEDGER_ReportFrameCount:Hide()
            RAIDLEDGER_ReportFrameCountLabel:Hide()

            RAIDLEDGER_ReportFrameScrollFrame:Show()
            RAIDLEDGER_ReportFrameExportButton:SetText("关闭文本显示")
        end

        local edit = RAIDLEDGER_ReportFrameScrollFrameScrollFrame_ChildEditBox

        local s = "RaidLedger 金团统计\r\n"
        s = s .. "问题联系：farmer1992@gmail.com\r\n"
        s = s .. "\r\n"

        for k, item in pairs(RaidLedger_Ledger["items"] or {}) do
            local l = item["looter"] or "[未分配]"
            local i = item["item"]
            local c = item["cost"] or 0

            if i then
                local n = GetItemInfo(i)

                if i == FIN_AID then
                    n = FIN_AID
                end
                s = s .. "[" ..  n .. "] " .. l .. " " .. GetMoneyStringL(c * 10000) .. "\r\n"
            end

        end

        local sum0, avg, n = Sum()
        sum = GetMoneyStringL(sum0 * 10000)
        avg = GetMoneyStringL(avg * 10000)

        s = s .. "\r\n"
        s = s .. "参与分账人数:" .. n .. "\r\n"
        s = s .. "合计收入:" .. sum .. "\r\n"
        s = s .. "人均收入:" .. avg .. "\r\n"

        edit:SetText(s)
    end)

    RAIDLEDGER_ReportFrameSayButton:SetScript("OnClick", function()

        local sum0, avg, n = Sum()
        sum = GetMoneyStringL(sum0 * 10000)
        avg = GetMoneyStringL(avg * 10000)

        local grp = {}

        for k, item in pairs(RaidLedger_Ledger["items"] or {}) do
            local l = item["looter"]
            local i = item["item"]
            if l and i then

                if not grp[l] then
                    grp[l] = { 
                        ["cost"] = 0,
                        ["items"] = {},
                        ["compensation"] = 0,
                    }
                end

                if i == FIN_AID then
                    grp[l]["compensation"] = grp[l]["compensation"] + (item["cost"] or 0)
                else
                    grp[l]["cost"] = grp[l]["cost"] + (item["cost"] or 0)
                    table.insert( grp[l]["items"], i)
                end

            end
        end

        local looter = {}
        local compensation = {}
        local compensation_sum = 0

        for l, k in pairs(grp) do
            table.insert( looter, {
                ["cost"] = k["cost"],
                ["items"] = k["items"],
                ["looter"] = l,
            })

            if k["compensation"] > 0 then
                compensation_sum = compensation_sum + k["compensation"]
                table.insert( compensation, {
                    ["beneficiary"] = l,
                    ["compensation"] = k["compensation"],
                })
            end
        end

        table.sort( looter, function(a, b) 
            return a["cost"] > b["cost"]
        end)

        table.sort( compensation, function(a, b) 
            return a["compensation"] > b["compensation"]
        end)

        if #looter > 0 then
            local c = math.min( #looter, 5)

            while c > 0 and looter[c]["cost"] == 0 do
                c = c - 1
            end

            if c > 0 then
                SendToCurrrentChannel("RaidLedger 统计: 贡献钱 [" .. c .. "] 的老板") 
            end

            for i = 1, c do
                if looter[i] then
                    local l = looter[i]

                    local lootitems = ""
                    for j = 1, math.min(#l["items"], 5) do
                        lootitems = lootitems .. l["items"][j] .. ","
                    end
                    
                    if #l["items"] > 5 then
                        lootitems = lootitems .. "等..."
                    end

                    SendToCurrrentChannel(l["looter"] .. " [" .. GetMoneyStringL(l["cost"] * 10000) .. "] " .. lootitems) 
                end
            end
        end
        
        if compensation_sum > 0 then
            local c = math.min( #compensation, 5)

            local compensation_str = ""

            for i = 1, c do
                compensation_str = compensation_str .. "[" .. compensation[i]["beneficiary"] .. "(" ..  GetMoneyStringL(compensation[i]["compensation"] * 10000) .. ")],"
            end

            if #compensation > 5 then
                compensation_str = compensation_str .. "等..."
            end

            SendToCurrrentChannel("补助花费 [" .. GetMoneyStringL(compensation_sum * 10000) .. "]: " .. compensation_str) 

        end

        SendToCurrrentChannel("RaidLedger 统计总收入: " .. GetMoneyStringL((sum0 + compensation_sum) * 10000) ..  "(消费) - ".. GetMoneyStringL(compensation_sum * 10000) .. "(补助)  = [" .. sum .. "], 分账人数[" .. n .. "]" .. ", 人均收入[" .. avg .. "]") 
    end)

    RAIDLEDGER_ReportFrameClearButton:SetScript("OnClick", function()
        StaticPopupDialogs["RAIDLEDGER_CLEARMSG"].OnAccept = function()
            StaticPopup_Hide("RAIDLEDGER_CLEARMSG")
            RaidLedger_Ledger = {}
            UpdateLootTable()
        end
        StaticPopup_Show("RAIDLEDGER_CLEARMSG")
    end)

    UpdateCountLabel()
    UpdateSumLabel()

    RAIDLEDGER_ReportFrameCount:SetScript("OnTextChanged", function()
        UpdateSumLabel()
    end)

end)


SlashCmdList["RAIDLEDGER"] = function(msg, editbox)
    local cmd, what = msg:match("^(%S*)%s*(%S*)%s*$")

    if cmd == "" then
        UpdateCountLabel()
        RAIDLEDGER_ReportFrame:Show()
    elseif cmd == "clear" then
        RaidLedger_Ledger = {}
        UpdateLootTable()
    else
        local _, itemLink = GetItemInfo(strtrim(msg))
        if itemLink then
            AddLoot(itemLink, nil, 0, true)
        end
    end

end
-- SLASH_RAIDLEDGER1 = "/RL"
SLASH_RAIDLEDGER1 = "/GTUAN"

StaticPopupDialogs["RAIDLEDGER_CLEARMSG"] = {
    text = "确定清空记录?",
    button1 = ACCEPT,
    button2 = CANCEL,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    multiple = 0,
}

StaticPopupDialogs["RAIDLEDGER_DELETE_ITEM"] = {
    text = "确定删除这条记录?",
    button1 = ACCEPT,
    button2 = CANCEL,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    multiple = 0,
}