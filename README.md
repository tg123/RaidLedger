# RaidLedger

A ledger for GDKP/gold run raid.

## Special Thanks to [ClassicRaidTracker](https://gitlab.com/wenlock/ClassicRaidTracker)

I would not have been able to build RaidLedger without `ClassicRaidTracker`
Some codes, scrolling ui and loot message parsing, are borrowed from `ClassicRaidTracker`.

## Localization
 <https://www.curseforge.com/wow/addons/raidledger/localization>

 * [中文介绍](README-zhCN.md)

### How to toggle the ledger panel

You can use either way:
 * via `/raidledger`
 * Click `Raid Ledger` button on raid panel

### Features
 
 * Create a summary and report to raid channel
 * Smart looter name autocomplete. `1` for all members in subgroup `1`, `hunter` for all hunters in raid group
 * Loot charges (credit for team) and looter can be modified at any time
 * Customized reason credit for team, e.g. `Package: all rare loot` for 100G
 * Compensation for special raid members
    * `%` Percentage Net Profit mode
    * `*` Multiple Per Member credit mode
    * `Gold` Addtitonal gold mode
   
 * Calculate gold run per member credit for each raid members
 * Loot during raid will be added to ledger automatically
    
    `/raidledlger toggle` to change mode
    
    * On
    * In Raid Only
    * Off
    
 * Easy to export as text in order to copy/paste to a third party website.

## Third Party Licenses
 
 * <https://www.wowace.com/projects/lib-st>

   by gooyit    
   modified by Boshi Lian

   [The GNU General Public License (GPL) Version 2](https://www.wowace.com/project/15433/license)

 * <https://www.wowace.com/projects/deformat>

   by ckknight

   [The GNU General Public License (GPL) Version 2.1](https://www.wowace.com/project/13763/license)

