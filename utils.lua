local _, ADDONSELF = ...

local L = ADDONSELF.L

ADDONSELF.print = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|CFFFF0000<|r|CFFFFD100RaidLedger|r|CFFFF0000>|r"..(msg or "nil"))
end

local function GetMoneyStringL(money, separateThousands)
	local goldString, silverString, copperString;
	local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD));
	local silver = floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
	local copper = mod(money, COPPER_PER_SILVER);

    if (separateThousands) then
        goldString = FormatLargeNumber(gold)..GOLD_AMOUNT_SYMBOL;
    else
        goldString = gold..GOLD_AMOUNT_SYMBOL;
    end
    silverString = silver..SILVER_AMOUNT_SYMBOL;
    copperString = copper..COPPER_AMOUNT_SYMBOL;

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

local CRLF = "\r\n"

ADDONSELF.CRLF = CRLF


local calcavg = function(revenue, expense, n)
    local profit = math.max(revenue - expense, 0)
    local avg = 0

    if n > 0 then
        avg = 1.0 * profit / n
        avg = math.max( avg, 0)
        avg = math.floor( avg )
    end

    return profit, avg
end
ADDONSELF.calcavg = calcavg

ADDONSELF.genexport = function(items, n)
    local s = L["Raid Ledger"] .. CRLF
    s = s .. L["Feedback"] .. ": farmer1992@gmail.com" .. CRLF
    s = s .. CRLF

    local revenue = 0
    local expense = 0

    for _, item in pairs(items or {}) do
        local l = item["beneficiary"] or L["[Unknown]"]
        local i = item["detail"]["item"] or ""
        local d = item["detail"]["displayname"] or ""
        local c = item["cost"] or 0
        local t = item["type"]

        if i then
            local n = GetItemInfo(i) or d
            n = n ~= "" and n or nil
            n = n or L["Other"]

            if t == "DEBIT" then
                n = d or L["Compensation"]
            end

            if t == "CREDIT" then
                revenue = revenue + c
            elseif t == "DEBIT" then
                expense = expense + c
            end

            s = s .. "[" ..  n .. "] " .. l .. " " .. GetMoneyStringL(c * 10000) .. CRLF
        end

    end

    revenue = revenue * 10000
    expense = expense * 10000
    
    local profit, avg = calcavg(revenue, expense, n)

    revenue = GetMoneyStringL(revenue)
    expense = GetMoneyStringL(expense)
    profit = GetMoneyStringL(profit)
    avg = GetMoneyStringL(avg)

    s = s .. CRLF
    s = s .. L["Revenue"] .. ":" .. revenue .. CRLF
    s = s .. L["Expense"] .. ":" .. expense .. CRLF
    s = s .. L["Net Profit"] .. ":" .. profit .. CRLF
    s = s .. L["Split into"] .. ":" .. n .. CRLF
    s = s .. L["Gain per member"] .. ":" .. avg .. CRLF

    return s
end

ADDONSELF.genreport = function(items, n)
    local revenue = 0
    local expense = 0

    local grp = {}

    for _, item in pairs(items) do
        local l = item["beneficiary"] or L["[Unknown]"]
        local i = item["detail"]["item"] or ""
        local d = item["detail"]["displayname"] or ""
        local c = item["cost"] or 0
        local t = item["type"]

        if l and i then

            if not grp[l] then
                grp[l] = { 
                    ["cost"] = 0,
                    ["items"] = {},
                    ["compensation"] = 0,
                }
            end

            if t == "DEBIT" then
                grp[l]["compensation"] = grp[l]["compensation"] + (item["cost"] or 0)
            else
                grp[l]["cost"] = grp[l]["cost"] + (item["cost"] or 0)
                
                if not GetItemInfoFromHyperlink(i) then
                    i = item["displayname"]
                end
                table.insert( grp[l]["items"], i)
            end

            if t == "CREDIT" then
                revenue = revenue + c
            elseif t == "DEBIT" then
                expense = expense + c
            end

        end
    end

    revenue = revenue * 10000
    expense = expense * 10000

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
            SendToCurrrentChannel(L["RaidLedger: Top [%d] contributors"]:format(c)) 
        end

        for i = 1, c do
            if looter[i] then
                local l = looter[i]

                local lootitems = ""
                for j = 1, math.min(#l["items"], 5) do
                    lootitems = lootitems .. l["items"][j] .. ","
                end
                
                if #l["items"] > 5 then
                    lootitems = lootitems .. L["etc."]
                end

                SendToCurrrentChannel(l["looter"] .. " [" .. GetMoneyStringL(l["cost"] * 10000) .. "] " .. lootitems) 
            end
        end
    end
    
    if expense > 0 then
        local c = math.min( #compensation, 5)

        local compensation_str = ""

        for i = 1, c do
            compensation_str = compensation_str .. "[" .. compensation[i]["beneficiary"] .. "(" ..  GetMoneyStringL(compensation[i]["compensation"] * 10000) .. ")],"
        end

        if #compensation > 5 then
            compensation_str = compensation_str .. L["etc."]
        end

        SendToCurrrentChannel(L["Expense"] .. " [" .. GetMoneyStringL(expense ) .. "]: " .. compensation_str) 
    end

    local profit, avg = calcavg(revenue, expense, n)

    revenue = GetMoneyStringL(revenue)
    expense = GetMoneyStringL(expense)
    profit = GetMoneyStringL(profit)
    avg = GetMoneyStringL(avg)

    SendToCurrrentChannel(L["Revenue"] .. ": " .. revenue .. " "
                                        .. L["Expense"] .. ": " .. expense .. " "
                                        .. L["Net Profit"] .. ": " .. profit .. " "
                                        .. L["Split into"] .. ": " .. n .. ".")

    SendToCurrrentChannel("RaidLedger " .. L["Per Member credit"] .. ": " .. avg)
end