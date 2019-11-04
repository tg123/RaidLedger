local _, ADDONSELF = ...

local L = ADDONSELF.L
local GUI = ADDONSELF.gui
local Database = ADDONSELF.db
local Print = ADDONSELF.print
local deformat = ADDONSELF.deformat
local RegEvent = ADDONSELF.regevent

hooksecurefunc("SetItemRef", function(link)
    if GUI.mainframe:IsShown() and IsShiftKeyDown() then
        local linkType, target = strsplit(":", link)

        if linkType == "item" then
            local _, itemLink = GetItemInfo(target)
            if itemLink then
                Print(L["Item added"] .. " " .. itemLink)
                Database:AddLoot(itemLink, 1, "", 0, true)
                GUI:UpdateLootTableFromDatabase()
            end
        elseif linkType == "player" then
            local playerName = strsplit("-", target)
            Print(L["Compensation added"] .. " " .. playerName)
            Database:AddDebit("", playerName)
            GUI:UpdateLootTableFromDatabase()
        end
    end
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
        Database:AddLoot(itemLink, 1, playerName, 0);
        GUI:UpdateLootTableFromDatabase()
    end
end)

SlashCmdList["RAIDLEDGER"] = function(msg, editbox)
    local cmd, what = msg:match("^(%S*)%s*(%S*)%s*$")

    if cmd == "" then
        GUI:Show()

        Print(L["Shift + item/name to add to record"])
        Print(L["Right click to remove record"])
        Print("[".. L["/raidledger"] .. " toggle] " .. L["toggle Auto recording on/off"])

    elseif cmd == "toggle" then
        AutoAddLoot = not AutoAddLoot
        if AutoAddLoot then
            Print(L["Auto recording loot: On"])
        else
            Print(L["Auto recording loot: Off"])
        end
    else
        local _, itemLink = GetItemInfo(strtrim(msg))
        if itemLink then
            Database:AddLoot(itemLink, 1, "", 0, true)
            GUI:UpdateLootTableFromDatabase()
            Print(L["Item added"] .. " " .. itemLink)
        end
    end

end
-- -- SLASH_RAIDLEDGER1 = "/RL"
SLASH_RAIDLEDGER1 = "/GTUAN"
SLASH_RAIDLEDGER2 = "/RAIDLEDGER"