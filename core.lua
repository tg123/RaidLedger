local _, ADDONSELF = ...

local ScrollingTable = LibStub("ScrollingTable");
local deformat = LibStub("LibDeformat-3.0");

local FIN_AID = "补助" -- TODO to types

local TYPE_COMP = "COMPENSATION"
local TYPE_ITEM = "ITEM"
local TYPE_INCOME = "INCOME" -- not used TODO


local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|CFFFF0000<|r|CFFFFD100RaidLedger|r|CFFFF0000>|r"..(msg or "nil"))
end

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
    local compensation = 0
    for k, item in pairs(RaidLedger_Ledger["items"] or {}) do
        if item["item"] == FIN_AID then
            compensation = compensation + (item["cost"] or 0)
        else
            sum = sum + (item["cost"] or 0)
        end
    end

    sum = math.max( sum, 0)
    local total = math.max(sum - compensation, 0)
    local avg = 0

    if n > 0 then
        avg = 1.0 * total / n
        avg = math.max( avg, 0)
        avg = math.floor( avg * 10000 ) / 10000
    end

    return sum, compensation, total, avg, n
end

local function UpdateSumLabel()
    local income, comp, sum, avg = Sum()
    income = GetMoneyString(income * 10000)
    comp = GetMoneyString(comp * 10000)
    sum = GetMoneyString(sum * 10000)
    avg = GetMoneyString(avg * 10000)
    RAIDLEDGER_ReportFrameSumLabel:SetText("总收入" .. income .. "\r\n - 总支出" .. comp .. "\r\n实际收入" .. sum ..  "\r\n人均" .. avg)
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
            local idx = rowdata["cols"][1].value
            local entry = RaidLedger_Ledger["items"][idx]

            cellvalue = celldata.value;
            -- print(celldata.value)
            local itemTexture =  GetItemIcon(celldata.value)

            -- print(itemTexture)
            -- core copy from https://www.curseforge.com/wow/addons/classic-raid-tracker
            if not (cellFrame.cellItemTexture) then
                cellFrame.cellItemTexture = cellFrame:CreateTexture()
            end

            cellFrame.cellItemTexture:SetTexCoord(0, 1, 0, 1)
            cellFrame.cellItemTexture:Show()
            cellFrame.cellItemTexture:SetPoint("CENTER", cellFrame.cellItemTexture:GetParent(), "CENTER")
            cellFrame.cellItemTexture:SetWidth(30)
            cellFrame.cellItemTexture:SetHeight(30)

            if not itemTexture then
                
                if entry["type"] == TYPE_COMP then
                    cellFrame.cellItemTexture:SetTexture(135768) -- minus
                else
                    cellFrame.cellItemTexture:SetTexture(135769) -- plus
                end

                return 
            end

            cellFrame.cellItemTexture:SetTexture(itemTexture)

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
        ["name"] = "账目",
        ["width"] = 250,
        ["DoCellUpdate"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table, ...)
            if not fShow then
                return
            end

            local rowdata = table:GetRow(realrow)
            local idx = rowdata["cols"][1].value
            local entry = RaidLedger_Ledger["items"][idx]
            local item = entry["item"]

            if entry["type"] ~= TYPE_COMP then
                local _, itemLink = GetItemInfo(item)
                if itemLink then
                    cellFrame.text:SetText(itemLink)
                    if cellFrame.textBox then
                        cellFrame.textBox:Hide()
                    end
                    return
                end
            end


            cellvalue = RaidLedger_Ledger["items"][idx]["displayname"] or item -- for old data

            if not (cellFrame.textBox) then
                cellFrame.textBox = CreateFrame("EditBox", nil, cellFrame, "InputBoxTemplate,AutoCompleteEditBoxTemplate")
            end
            cellFrame.textBox:Show()

            cellFrame.textBox:SetPoint("CENTER", cellFrame, "CENTER", -20, 0)
            cellFrame.textBox:SetWidth(120)
            cellFrame.textBox:SetHeight(30)
            cellFrame.textBox:SetAutoFocus(false)
            cellFrame.textBox:SetText(cellvalue)

            if entry["type"] == TYPE_COMP or entry["item"] == FIN_AID then
                cellFrame.text:SetText("支出")
            else 
                cellFrame.text:SetText("收入")
            end

            local CONVERT = "#尝试转换为物品链接"

            cellFrame.textBox.customAutoCompleteFunction = function(editBox, newText, info)
                local n = newText ~= "" and newText or info.name

                if n ~= "" then
                    if entry["type"] ~= TYPE_COM and n == CONVERT then
                        local txt = editBox:GetText()
                        txt = strtrim(txt)
                        txt = strtrim(txt, "[]")
                        -- print(txt)
                        local _, itemLink = GetItemInfo(txt)

                        if itemLink then
                            entry["item"] = itemLink
                            entry["displayname"] = nil
                            UpdateLootTable()
                        else
                            Print("转换失败, 名称可以是物品ID, 物品名称(可能会失败)")
                        end

                        -- print (itemLink)
                        return true
                    end

                    cellFrame.textBox:SetText(n)
                    entry["displayname"] = n
                end

                return true
            end

           
            AutoCompleteEditBox_SetAutoCompleteSource(cellFrame.textBox, function(text)
                local data = {}

                if entry["type"] == TYPE_COMP or entry["item"] == FIN_AID then
                    if text == "" or text == "#ONFOCUS" then
                        for _, name in pairs({
                            "坦克补助",
                            "灭火补助",
                            "治疗补助",
                            "输出补助",
                            "其他补助",
                        }) do
                            tinsert(data, {
                                ["name"] = name,
                                ["priority"] = LE_AUTOCOMPLETE_PRIORITY_IN_GROUP,
                            })
                        end
                    end

                else
                    tinsert(data, {
                        ["name"] = CONVERT,
                        ["priority"] = LE_AUTOCOMPLETE_PRIORITY_IN_GROUP,
                    })
                end

                return data
            end)

            cellFrame.textBox:SetScript("OnTextChanged", function(self, userInput)

                AutoCompleteEditBox_OnTextChanged(self, userInput)

                local t = self:GetText()

                entry["displayname"] = t

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
        end
    },
    {
        ["name"] = "拾取",
        ["width"] = 150,
        ["DoCellUpdate"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table, ...)
            if not fShow then
                return
            end

            local rowdata = table:GetRow(realrow)
            local idx = rowdata["cols"][1].value
            local entry = RaidLedger_Ledger["items"][idx]

            -- local celldata = table:GetCell(rowdata, column)
            cellvalue = RaidLedger_Ledger["items"][idx]["looter"] or ""

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

                if userInput and t ~= "" then
                    local rowdata = table:GetRow(realrow)
                    local idx = rowdata["cols"][1].value
                    RaidLedger_Ledger["items"][idx]["looter"] = t
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
            -- local celldata = table:GetCell(rowdata, column)
            local idx = rowdata["cols"][1].value
            local entry = RaidLedger_Ledger["items"][idx]

            -- local celldata = table:GetCell(rowdata, column)
            cellvalue = tostring(RaidLedger_Ledger["items"][idx]["cost"]) or ""
            -- cellvalue = celldata.value

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
            cellFrame.textBox:SetMaxLetters(7)

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
            table.insert(data, 1, {
                ["cols"] = {
                    {
                        ["value"] = #data + 1
                    }, -- id
                    {
                        ["value"] = item["item"]
                    }, -- icon
                    {
                        ["value"] = item["displayname"]
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

local function AddLoot(item, looter, cost, force, type)
    if not RaidLedger_Ledger["items"] then
        RaidLedger_Ledger["items"] = {}
    end

    local type = type or TYPE_ITEM
    local entry = {}

    entry["item"] = item
    entry["displayname"] = item
    entry["looter"] = looter
    entry["cost"] = cost
    entry["type"] = type

    if type == TYPE_ITEM then
        local _, itemLink, itemRarity = GetItemInfo(item)

        if not force then
            if not itemLink then
                return
            end

            if (itemRarity < UIDropDownMenu_GetSelectedValue(RAIDLEDGER_ReportFrameFilterDropDown)) then
                return
            end

        end

        entry["displayname"] = itemLink
        entry["itemid"] = GetItemInfoFromHyperlink(itemLink or "")
    end

    table.insert(RaidLedger_Ledger["items"], entry)

    -- if item == FIN_AID then
    --     table.insert(RaidLedger_Ledger["items"], {
    --         ["item"] = FIN_AID,
    --         ["displayname"] = FIN_AID,
    --         ["looter"] = looter,
    --         ["cost"] = cost,
    --         ["type"] = TYPE_COMP,
    --     })

    -- else


    --     if itemLink then
    --         table.insert(RaidLedger_Ledger["items"], {
    --             ["item"] = itemLink,
    --             ["displayname"] = itemLink,
    --             ["looter"] = looter,
    --             ["cost"] = cost,
    --             ["type"] = TYPE_ITEM,
    --         })
    --     end
    -- end


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

local GuessLootEnable = false

local function GuessLoot(msg)
    if not GuessLootEnable then
        return
    end

    local itemId = GetItemInfoFromHyperlink(msg)
    if itemId then
        local _, link = GetItemInfo(itemId)

        Print("加入" .. link .. "到账本") 
        AddLoot(link, nil, 0, true)
        GuessLootEnable = false
    end
end

-- RegEvent("CHAT_MSG_PARTY", function(msg)
--     GuessLoot(msg)
-- end)

RegEvent("CHAT_MSG_RAID", function(msg)
    GuessLoot(msg)
end)

local AutoAddLoot = true

RegEvent("CHAT_MSG_LOOT", function(chatmsg)

    if not AutoAddLoot then
        return
    end

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
        AddLoot(FIN_AID, nil, 0, true, TYPE_COMP)
        -- local function AddLoot(item, looter, cost, force, type)
    end)

    RAIDLEDGER_ReportFrameFinItemButton:SetScript("OnClick", function()
        AddLoot("", nil, 0, true, TYPE_ITEM)
        -- local function AddLoot(item, looter, cost, force, type)
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
            local d = item["displayname"]
            local c = item["cost"] or 0
            local t = item["type"] or 0

            if i then
                local n = GetItemInfo(i) or d
                n = n ~= "" and n or nil
                n = n or "其他收入"

                if i == FIN_AID or t == TYPE_COMP then
                    n = d or FIN_AID
                end
                s = s .. "[" ..  n .. "] " .. l .. " " .. GetMoneyStringL(c * 10000) .. "\r\n"
            end

        end

        local income, comp, sum, avg, n = Sum()
        income = GetMoneyStringL(income * 10000)
        comp = GetMoneyStringL(comp * 10000)
        sum = GetMoneyStringL(sum * 10000)
        avg = GetMoneyStringL(avg * 10000)

        s = s .. "\r\n"
        s = s .. "参与分账人数:" .. n .. "\r\n"
        s = s .. "总收入:" .. income .. "\r\n"
        s = s .. "总支出:" .. comp .. "\r\n"
        s = s .. "合计收入:" .. sum .. "\r\n"
        s = s .. "人均收入:" .. avg .. "\r\n"

        edit:SetText(s)
    end)

    RAIDLEDGER_ReportFrameSayButton:SetScript("OnClick", function()

        local income, compensation_sum, sum, avg, n = Sum()
        income = GetMoneyStringL(income * 10000)
        -- comp = GetMoneyStringL(avg * 10000)
        sum = GetMoneyStringL(sum * 10000)
        avg = GetMoneyStringL(avg * 10000)

        local grp = {}

        for k, item in pairs(RaidLedger_Ledger["items"] or {}) do
            local l = item["looter"]
            local i = item["item"]
            local t = item["type"]
            if l and i then

                if not grp[l] then
                    grp[l] = { 
                        ["cost"] = 0,
                        ["items"] = {},
                        ["compensation"] = 0,
                    }
                end

                if i == FIN_AID or t == TYPE_COMP then
                    grp[l]["compensation"] = grp[l]["compensation"] + (item["cost"] or 0)
                else
                    grp[l]["cost"] = grp[l]["cost"] + (item["cost"] or 0)
                    
                    if not GetItemInfoFromHyperlink(i) then
                        i = item["displayname"]
                    end
                    table.insert( grp[l]["items"], i)
                end

            end
        end

        local looter = {}
        local compensation = {}

        for l, k in pairs(grp) do
            table.insert( looter, {
                ["cost"] = k["cost"],
                ["items"] = k["items"],
                ["looter"] = l,
            })

            if k["compensation"] > 0 then
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

        SendToCurrrentChannel("RaidLedger 统计总收入: " .. income ..  "(消费) - ".. GetMoneyStringL(compensation_sum * 10000) .. "(补助)  = [" .. sum .. "], 分账人数[" .. n .. "]" .. ", 人均收入[" .. avg .. "]") 
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

        Print("/gtuan cap 捕获下一次团队聊天中的物品到记录")
        Print("/gtuan toggle 开启/关闭自动拾取记录")

    elseif cmd == "clear" then
        RaidLedger_Ledger = {}
        UpdateLootTable()
    elseif cmd == "cap" then
        Print("下一个出现在团队聊天的物品将被自动加入记录")
        GuessLootEnable = true
    elseif cmd == "toggle" then
        AutoAddLoot = not AutoAddLoot
        if AutoAddLoot then
            Print("自动记录开启")
        else
            Print("自动记录关闭")
        end

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