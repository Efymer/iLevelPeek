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
