# iLevelPeek

`iLevelPeek` is a lightweight World of Warcraft Midnight (12.0.0+) addon that injects item level, M+ score, raid progress, tier count and dungeon run breakdown directly into unit tooltips.

## Features

- Class-colored player name in the tooltip
- Guild rank shown as `Rank of <Guild Name>`
- Class-colored spec line (e.g. "Level 80 Holy **Paladin**")
- Single line showing equipped item level and M+ score side by side
- Raid progress summary (e.g. `Raid: 6/9 H`) showing lifetime best kills at the highest difficulty
- Works on both yourself and inspected players (raid progress loads even out of inspect range)
- **Shift-hover** expanded view:
  - Tier set piece count (X/5)
  - Top 5 M+ dungeon runs with key level, timed/depleted indicator and per-dungeon score
  - Per-raid, per-difficulty boss kill breakdown (Mythic/Heroic/Normal)
- **Config panel** with toggles for every feature (item level, M+ score, raid progress, tier set, class colors, guild rank, shift details)

## Installation

1. Close World of Warcraft.
2. Place the `iLevelPeek` folder into:
   `World of Warcraft\_retail_\Interface\AddOns\`
3. Start the game and enable `iLevelPeek` in the AddOns list.

The final installed path should be:

```
World of Warcraft\_retail_\Interface\AddOns\iLevelPeek\iLevelPeek.toc
```

## Usage

Hover over any player unit frame to see their stats. Hold **Shift** while hovering to expand the tooltip with tier set count, M+ run breakdown and raid progress.

Type `/ilevelpeek` or `/ilvlpeek` to open the settings panel, or find it under **Options > AddOns > iLevelPeek**.
