local addonName, addon = ...

addon.Config = addon.Config or {}

-- Midnight Season 2 (12.1.0) upgrade track starting item levels
-- (Season 1 + 46: Veteran 6/6 = 296, Champion 1/6 = 292)
addon.Config.ilvlColorThresholds = {
    { min = 318, color = { 1.00, 0.82, 0.00 } }, -- Myth track, legendary gold
    { min = 305, color = { 1.00, 0.50, 0.00 } }, -- Hero track, orange
    { min = 292, color = { 0.64, 0.21, 0.93 } }, -- Champion track, epic purple
    { min = 279, color = { 0.00, 0.44, 0.87 } }, -- Veteran track, rare blue
    { min = 266, color = { 0.12, 1.00, 0.00 } }, -- Adventurer track, uncommon green
    { min = 0,   color = { 0.62, 0.62, 0.62 } }, -- fallback gray
}

-- Raid difficulties ordered by priority (highest first)
addon.Config.raidDifficulties = {
    { key = "M",   short = "M",   color = { 1.00, 0.50, 0.00 } }, -- Mythic
    { key = "H",   short = "H",   color = { 0.64, 0.21, 0.93 } }, -- Heroic
    { key = "N",   short = "N",   color = { 0.12, 1.00, 0.00 } }, -- Normal
    { key = "LFR", short = "LFR", color = { 0.62, 0.62, 0.62 }, hidden = true }, -- LFR (hidden from tooltip)
}

-- Current tier raids (Midnight Season 2) with per-boss statistic IDs per difficulty
-- GetStatistic(id) returns lifetime kill count; GetComparisonStatistic(id) for inspected players
-- IDs from the Achievement DB2 (statistics category 15542), build 12.1.0.69933
addon.Config.raids = {
    {
        name = "The Venomous Abyss",
        encounters = {
            { name = "Nek'zali the Soulcoiler", stats = { M = 63536, H = 63535, N = 63534, LFR = 63533 } },
            { name = "Entombed Sentinels",      stats = { M = 63540, H = 63539, N = 63538, LFR = 63537 } },
            { name = "The Lost Explorers",      stats = { M = 63554, H = 63553, N = 63552, LFR = 63541 } },
            { name = "Vashnik the Malignant",   stats = { M = 63557, H = 63556, N = 63555, LFR = 63547 } },
            { name = "Sszorak",                 stats = { M = 63560, H = 63559, N = 63558, LFR = 63548 } },
            { name = "The Twin Fangs",          stats = { M = 63563, H = 63562, N = 63561, LFR = 63549 } },
            { name = "The Coiled Altar",        stats = { M = 63566, H = 63565, N = 63564, LFR = 63550 } },
            { name = "Ula'tek",                 stats = { M = 63569, H = 63568, N = 63567, LFR = 63551 } },
        },
    },
    {
        name = "The Tidebound Grotto",
        encounters = {
            { name = "Nymrissa Wavecaller", stats = { M = 63616, H = 63615, N = 63614 } },
        },
    },
}
