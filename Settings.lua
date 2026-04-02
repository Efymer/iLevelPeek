local addonName, addon = ...

addon.Settings = addon.Settings or {}

local defaults = {
    showItemLevel       = true,
    showMythicPlus      = true,
    showRaidProgress    = true,
    showTierSet         = true,
    showClassColors     = true,
    showGuildRank       = true,
    showShiftDetails    = true,
}

function addon.Settings:Initialize()
    if not iLevelPeekDB then
        iLevelPeekDB = {}
    end

    -- Fill in any missing defaults
    for key, value in pairs(defaults) do
        if iLevelPeekDB[key] == nil then
            iLevelPeekDB[key] = value
        end
    end

    addon.db = iLevelPeekDB
    self:CreatePanel()
end

function addon.Settings:Get(key)
    if addon.db then
        return addon.db[key]
    end
    return defaults[key]
end

function addon.Settings:CreatePanel()
    local category, layout = Settings.RegisterVerticalLayoutCategory(addonName)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Tooltip Display"))

    self:AddToggle(category, "showItemLevel", "Show Item Level",
        "Display item level in the tooltip.")

    self:AddToggle(category, "showMythicPlus", "Show M+ Score",
        "Display Mythic+ score and top runs in the tooltip.")

    self:AddToggle(category, "showRaidProgress", "Show Raid Progress",
        "Display raid boss kill progress in the tooltip.")

    self:AddToggle(category, "showTierSet", "Show Tier Set Count",
        "Display tier set piece count in the shift-hover tooltip.")

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Tooltip Appearance"))

    self:AddToggle(category, "showClassColors", "Class-Colored Names",
        "Color player names and class text by their class color.")

    self:AddToggle(category, "showGuildRank", "Show Guild Rank",
        "Display guild rank alongside guild name.")

    self:AddToggle(category, "showShiftDetails", "Shift-Hover Details",
        "Enable expanded details when holding Shift over a tooltip.")

    Settings.RegisterAddOnCategory(category)
    self.categoryID = category:GetID()
end

function addon.Settings:AddToggle(category, key, name, tooltip)
    local setting = Settings.RegisterAddOnSetting(category, addonName .. "_" .. key, key, addon.db, type(defaults[key]), name, defaults[key])
    setting:SetValueChangedCallback(function(_, val)
        addon.db[key] = val
    end)
    Settings.CreateCheckbox(category, setting, tooltip)
end

-- Slash command to open settings
SLASH_ILEVELPEEK1 = "/ilevelpeek"
SLASH_ILEVELPEEK2 = "/ilvlpeek"
SlashCmdList["ILEVELPEEK"] = function()
    if addon.Settings.categoryID then
        Settings.OpenToCategory(addon.Settings.categoryID)
    end
end
