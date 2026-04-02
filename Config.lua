local addonName, addon = ...

addon.Config = addon.Config or {}

addon.Config.ilvlColorThresholds = {
    { min = 272, color = { 1.00, 0.82, 0.00 } }, -- legendary gold
    { min = 259, color = { 1.00, 0.50, 0.00 } }, -- orange, top-end
    { min = 246, color = { 0.64, 0.21, 0.93 } }, -- epic purple
    { min = 233, color = { 0.00, 0.44, 0.87 } }, -- rare blue
    { min = 220, color = { 0.12, 1.00, 0.00 } }, -- uncommon green
    { min = 0,   color = { 0.62, 0.62, 0.62 } }, -- fallback gray
}

-- Raid difficulties ordered by priority (highest first)
addon.Config.raidDifficulties = {
    { key = "M",   short = "M",   color = { 1.00, 0.50, 0.00 } }, -- Mythic
    { key = "H",   short = "H",   color = { 0.64, 0.21, 0.93 } }, -- Heroic
    { key = "N",   short = "N",   color = { 0.12, 1.00, 0.00 } }, -- Normal
    { key = "LFR", short = "LFR", color = { 0.62, 0.62, 0.62 }, hidden = true }, -- LFR (hidden from tooltip)
}

-- Current tier raids with per-boss statistic IDs per difficulty
-- GetStatistic(id) returns lifetime kill count; GetComparisonStatistic(id) for inspected players
addon.Config.raids = {
    {
        name = "Voidspire",
        encounters = {
            { name = "Imperator Averzian",    stats = { M = 61279, H = 61278, N = 61277, LFR = 61276 } },
            { name = "Vorasius",              stats = { M = 61283, H = 61282, N = 61281, LFR = 61280 } },
            { name = "Fallen-King Salhadaar", stats = { M = 61287, H = 61286, N = 61285, LFR = 61284 } },
            { name = "Vaelgor & Ezzorak",     stats = { M = 61291, H = 61290, N = 61289, LFR = 61288 } },
            { name = "Lightblinded Vanguard", stats = { M = 61295, H = 61294, N = 61293, LFR = 61292 } },
            { name = "Crown of the Cosmos",   stats = { M = 61299, H = 61298, N = 61297, LFR = 61296 } },
        },
    },
    {
        name = "Dreamrift",
        encounters = {
            { name = "Chimaerus", stats = { M = 61477, H = 61476, N = 61475, LFR = 61474 } },
        },
    },
    {
        name = "March on Quel'Danas",
        encounters = {
            { name = "Belo'ren, Child of Al'ar", stats = { M = 61303, H = 61302, N = 61301, LFR = 61300 } },
            { name = "Midnight Falls",           stats = { M = 61307, H = 61306, N = 61305, LFR = 61304 } },
        },
    },
}
