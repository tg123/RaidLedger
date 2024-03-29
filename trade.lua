local _, ADDONSELF = ...

local L = ADDONSELF.L
local GUI = ADDONSELF.gui
local Database = ADDONSELF.db
local Print = ADDONSELF.print
local RegEvent = ADDONSELF.regevent

local f = CreateFrame("Frame", nil, TradeFrame, BackdropTemplateMixin and "BackdropTemplate" or nil)
f:SetWidth(172)
f:SetHeight(40)
f:SetBackdrop({
    -- bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",

    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileEdge = true,
    tileSize = 16,
    edgeSize = 24,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },   
})

f:SetPoint("TOPRIGHT", TradeFrame, "BOTTOMRIGHT", 0, 0)
f:SetToplevel(true)
f:EnableMouse(true)
f:SetFrameLevel(TradeFrame:GetFrameLevel() + 1)

local addtoCheckbtn = nil
do
    local b = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.text:SetPoint("LEFT", b, "RIGHT", 0, 1)
    b:SetPoint("LEFT", f, 5, 0)
    b.text:SetText(L["Add to"] .. " " .. L["Raid Ledger"])

    f:SetWidth(b.text:GetStringWidth() + 50)
    addtoCheckbtn = b
end


local currTrade = nil

-- local function UpdateCheckButton()
--     -- print(1)
-- end

-- RegEvent("TRADE_SHOW", function()
--     addtoCheckbtn:SetChecked(UnitInRaid("player"))
-- end)

-- RegEvent("TRADE_UPDATE", UpdateCheckButton)
-- RegEvent("TRADE_PLAYER_ITEM_CHANGED", UpdateCheckButton)
-- RegEvent("TRADE_MONEY_CHANGED", UpdateCheckButton)

RegEvent("TRADE_ACCEPT_UPDATE", function(p, t)
    currTrade = {
        target = GetUnitName("NPC", true),
        targetmoney = GetTargetTradeMoney(),
        playermoney = GetPlayerTradeMoney(),

        targetitems = {},
        playeritems = {},
    }

    for i = 1, 6 do
        local t = GetTradeTargetItemLink(i)

        if t then
            table.insert(currTrade.targetitems, {
                item = t,
                count = select(3, GetTradeTargetItemInfo(i)),
            })
        end
        
        local p = GetTradePlayerItemLink(i)
        if p then
            table.insert(currTrade.playeritems, {
                item = p,
                count = select(3, GetTradePlayerItemInfo(i)),
            })
        end
    end
end)

local POPUPOUTSTANDING_TYPE_ALL = 0
local POPUPOUTSTANDING_TYPE_RAID = 1
local POPUPOUTSTANDING_TYPE_DISABLE = 2

local function AddLootFromTrade(beneficiary, cost, items)
    local isoutstanding = false
    -- if cost is 0, may it is outstanding payment
    if cost == 0 then
        isoutstanding = true
    end

    for _, item in ipairs(items) do
        -- record outstanding amount
        if isoutstanding then           
            -- record first
            Database:AddOrUpdateLoot(item.item, item.count, beneficiary, cost, true)
            -- then popup
            local popupoutstanding = Database:GetConfigOrDefault("popupoutstanding", POPUPOUTSTANDING_TYPE_RAID)
            if popupoutstanding  == POPUPOUTSTANDING_TYPE_ALL or (popupoutstanding == POPUPOUTSTANDING_TYPE_RAID and IsInRaid()) then
                StaticPopupDialogs["OUTSTANDING_AMOUNT"].OnAccept = function (self)
                    cost = tonumber(self.editBox:GetText())     
                    Database:AddOrUpdateLoot(item.item, item.count, beneficiary, cost, true)
                end
                StaticPopup_Show("OUTSTANDING_AMOUNT", item)
            end
        else
            Database:AddOrUpdateLoot(item.item, item.count, beneficiary, cost / 10000, false)
            Print(L["Item added"] .. " " .. item.item .. " " .. L["Beneficiary"] .. " " .. beneficiary .. " " ..
                      GetMoneyString(cost))
        end
        -- only record item in database
        -- only first item will be update cost and outstanding payment
        cost = 0
        isoutstanding = false
    end
end

RegEvent("UI_INFO_MESSAGE", function(_, text)
    if text == ERR_TRADE_COMPLETE then

        if not addtoCheckbtn:GetChecked() then
            return
        end

        AddLootFromTrade(currTrade.target, currTrade.targetmoney, currTrade.playeritems)
        AddLootFromTrade(UnitName("player"), currTrade.playermoney, currTrade.targetitems)
    end

    currTrade = nil
end)

StaticPopupDialogs["OUTSTANDING_AMOUNT"] = {
    text = L["Input Outstanding Amount"],
    button1 = ACCEPT,
    button2 = CANCEL,
    timeout = 0,
    whileDead = 1,
    hasEditBox = 1,
    hideOnEscape = 1,
    multiple = 0,
    OnShow = function (self)
        self.editBox:SetText("0")
    end,
}
