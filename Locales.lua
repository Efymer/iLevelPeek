local addonName, addon = ...

addon.L = addon.L or {}

local L = addon.L

-- English (default)
L.UNIT_TOOLTIP_ILVL_LABEL  = "iLvl"
L.UNIT_TOOLTIP_MPLUS_LABEL = "M+"
L.UNIT_TOOLTIP_TIER_LABEL  = "Tier"
L.UNIT_TOOLTIP_SHIFT_HINT  = "[Shift] Details"
L.UNIT_TOOLTIP_RAID_LABEL  = "Raid"
L.UNIT_TOOLTIP_RAID_HEADER = "Raid Progress"

local locale = GetLocale()

if locale == "ruRU" then
    L.UNIT_TOOLTIP_TIER_LABEL  = "Уровень"
    L.UNIT_TOOLTIP_SHIFT_HINT  = "[Shift] Подробности"
    L.UNIT_TOOLTIP_RAID_LABEL  = "Рейд"
    L.UNIT_TOOLTIP_RAID_HEADER = "Прогресс рейда"
elseif locale == "esES" or locale == "esMX" then
    L.UNIT_TOOLTIP_TIER_LABEL  = "Tier"
    L.UNIT_TOOLTIP_SHIFT_HINT  = "[Shift] Detalles"
    L.UNIT_TOOLTIP_RAID_LABEL  = "Banda"
    L.UNIT_TOOLTIP_RAID_HEADER = "Progreso de banda"
end
