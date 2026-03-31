local addonName, addon = ...

addon.Colors = addon.Colors or {}

local Colors = addon.Colors

function Colors:GetItemLevelColor(itemLevel)
    if not itemLevel then
        return 0.62, 0.62, 0.62
    end

    for _, threshold in ipairs(addon.Config.ilvlColorThresholds) do
        if itemLevel >= threshold.min then
            return threshold.color[1], threshold.color[2], threshold.color[3]
        end
    end

    return 0.62, 0.62, 0.62
end
