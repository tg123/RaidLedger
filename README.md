# RaidLedger

A ledger for GDKP/gold run raid.

## Special Thanks to [ClassicRaidTracker](https://gitlab.com/wenlock/ClassicRaidTracker)

I would not have been able to build RaidLedger without `ClassicRaidTracker`
Some codes, scrolling ui and loot message parsing, are borrowed from `ClassicRaidTracker`.

## English

### Usage

 * Open panel `/gtuan`
 * Add item to ledger `/gtuan [itemlink]`

### Features
 
 * Create a summary and report to raid channel
 * Buyout charges and looter can be modified at any time
 * Smart looter name autocomplete. 1 for all members in subgroup 1, hunter for all hunters in raid
 * Compensation for special raid members
 * Calculate gold run income for raid members
 * Loot during raid will be added to ledger automatically
 * Easy to export as text in order to copy/paste to a third party website.


## 中文

专为为目前金团设计
团长可以记账，方便快捷
打工可以记账，童叟无欺

 * [NGA连接](https://bbs.nga.cn/read.php?tid=18961750)

### 使用

 * 界面呼出 `/gtuan`
 * 添加物品 `/gutan [物品]`

### 功能

 * 消费前5名汇总广播
 * 随时修改价格，拾取人
 * 智能自动完成，输入 1 会显示小队1 的成员 输入 猎人 会把 猎人 或者名字带有猎人的人都列出来
 * 可以添加补助，会在总钱数中自动扣除
 * 人数自动计算平均费用
 * 拾取的物品会自动加到账簿 当然还可以手动添加 (物品) 右键点击物品 可以删除记录
 * 可以导出文本 发到 微信群等地方


## Third Party Licenses
 
 * <https://www.wowace.com/projects/lib-st>

   by gooyit    
   modified by Boshi Lian

   [The GNU General Public License (GPL) Version 2](https://www.wowace.com/project/15433/license)

 * <https://www.wowace.com/projects/deformat>

   by ckknight

   [The GNU General Public License (GPL) Version 2.1](https://www.wowace.com/project/13763/license)
 
 * <https://www.wowace.com/projects/libstub>

   by Kaelten

   [Public Domain](https://www.wowace.com/project/14328/license)
