# iLvlChecker - Custom Context

> **IMPORTANT: WOW MIDNIGHT TARGET**
> This addon is built exclusively for **World of Warcraft: Midnight (Patch 12.0.0+)**.
> You **must** follow the new API restrictions and namespaces introduced in Patch 12.0.0.
> See the full API changes here: [https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes)
> Check API methods https://github.com/Ketho/BlizzardInterfaceResources/blob/live/Resources/GlobalAPI.lua using "gh" CLI command
> Use warcraft.wiki.gg to check for specific methods, for example: https://warcraft.wiki.gg/wiki/API_EJ_GetInstanceInfo
> If we want to get the statisticID, we should run ingame: /run local n=GetCategoryNumAchievements(15542) for i=1,n do local id,name=GetAchievementInfo(15542,i) if id then print(id, name, GetStatistic(id)) end end


If you are an AI assistant reading this file, you should know that this version of `iLvlChecker` has been heavily customized specifically around the GameTooltip.

## Core Addon Mechanics
- **Scanning**: Uses `C_PaperDollInfo.GetInspectItemLevel` and `C_PlayerInfo.GetPlayerMythicPlusRatingSummary`.
- **Tooltip Injection**: Hooks into `TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, onTooltipSetUnit)`.

## Custom Modifications (Tooltip.lua)

1. **Class-Colored Names:**
   The first line of the tooltip (`_G["GameTooltipTextLeft1"]`) is recolored based on `RAID_CLASS_COLORS[classFile]`.

2. **Guild Rank Injection:**
   The default WoW `<Guild Name>` line is scanned using `GetGuildInfo(unit)`. If found, it's replaced with `%s of <%s>` (e.g., "Officer of <Guild Name>") and colored green `(0.25, 1.0, 0.25)`.

3. **Class-Colored Spec Line:**
   Scans the tooltip for the localized class name (e.g., "Level 80 Holy Paladin") and wraps just the class name in inline hex color codes (`|cff...|r`) based on `RAID_CLASS_COLORS`.

4. **Single-Line iLvl & M+ Score:**
   Combines the player's Item Level and M+ Score onto a single line utilizing `GameTooltip:AddDoubleLine()`.

5. **Shift-Hover Expanded System (The biggest change):**
   - **Trigger:** Controlled by `IsShiftKeyDown()`. Includes an `OnUpdate` hook on `GameTooltip` that detects mid-hover Shift key state changes to instantly re-render via `GameTooltip:SetUnit()`.
   - **Tier Set Pieces:** Displays `Tier: X/5`. Powered by `countTierSetPieces()` which maps inventory slots `{1, 3, 5, 7, 10}` and parses `C_TooltipInfo.GetInventoryItem()` lines for `(X/Y)` or `Set:` text.
   - **Top 5 M+ Runs:** Displays a "Top 5 M+ Runs" breakdown using `GameTooltip:AddDoubleLine()`. Shows dungeon name (left) and `+Level ✓/✗ (Score)` (right). Timed runs use native atlas icons `|A:common-icon-checkmark:12:12|a` and depleted runs use `|A:common-icon-redx:12:12|a`.
     - *Note on data:* Runs are sorted by `mapScore` descending. Both `Tooltip.lua` (for the player) and `Inspect.lua` (for inspected group targets) extract this block of data from the `ratingSummary.runs` API payload.

## Caching Architecture (Inspect.lua)
- When a server response hits `INSPECT_READY(guid)`, we extract the `ratingSummary.runs` table to map it onto the cached `member.mythicPlusRuns` array.
- We aggressively call the `C_TooltipInfo.GetInventoryItem` tier scan here as well to cache `member.tierSetCount` instantly alongside item level.
