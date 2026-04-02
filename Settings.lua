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
    local L = addon.L
    local category, layout = Settings.RegisterVerticalLayoutCategory(addonName)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.SETTINGS_SECTION_DISPLAY))

    self:AddToggle(category, "showItemLevel", L.SETTINGS_SHOW_ILVL_NAME,
        L.SETTINGS_SHOW_ILVL_TIP)

    self:AddToggle(category, "showMythicPlus", L.SETTINGS_SHOW_MPLUS_NAME,
        L.SETTINGS_SHOW_MPLUS_TIP)

    self:AddToggle(category, "showRaidProgress", L.SETTINGS_SHOW_RAID_NAME,
        L.SETTINGS_SHOW_RAID_TIP)

    self:AddToggle(category, "showTierSet", L.SETTINGS_SHOW_TIER_NAME,
        L.SETTINGS_SHOW_TIER_TIP)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.SETTINGS_SECTION_APPEARANCE))

    self:AddToggle(category, "showClassColors", L.SETTINGS_SHOW_COLORS_NAME,
        L.SETTINGS_SHOW_COLORS_TIP)

    self:AddToggle(category, "showGuildRank", L.SETTINGS_SHOW_GUILD_NAME,
        L.SETTINGS_SHOW_GUILD_TIP)

    self:AddToggle(category, "showShiftDetails", L.SETTINGS_SHOW_SHIFT_NAME,
        L.SETTINGS_SHOW_SHIFT_TIP)

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
