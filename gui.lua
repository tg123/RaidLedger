
function RaidLedgerFilterDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, RaidLedgerFilterDropDown_Initialize);
	
	local v = LE_ITEM_QUALITY_RARE

	if RaidLedger_Ledger and RaidLedger_Ledger["config"] and RaidLedger_Ledger["config"]["filterlevel"] then
		v = RaidLedger_Ledger["config"]["filterlevel"]
	end

    UIDropDownMenu_SetSelectedValue(RAIDLEDGER_ReportFrameFilterDropDown, v);
end

local function FilterOnClick(self)
	UIDropDownMenu_SetSelectedValue(RAIDLEDGER_ReportFrameFilterDropDown, self.value);
	if not RaidLedger_Ledger["config"] then
		RaidLedger_Ledger["config"] = {}
	end
	RaidLedger_Ledger["config"]["filterlevel"] = self.value
end

function RaidLedgerFilterDropDown_Initialize()
	local info = UIDropDownMenu_CreateInfo();
	info.text = ALL;
	info.value = -1;
	info.func = FilterOnClick;
	info.classicChecks = true;
	UIDropDownMenu_AddButton(info);
	for i = 0, getn(ITEM_QUALITY_COLORS)-4  do
		info.text = _G["ITEM_QUALITY"..i.."_DESC"];
		info.value = i;
		info.func = FilterOnClick;
		info.checked = nil;
		UIDropDownMenu_AddButton(info);
	end
end