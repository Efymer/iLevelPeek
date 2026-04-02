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

-- Settings panel
L.SETTINGS_SECTION_DISPLAY    = "Tooltip Display"
L.SETTINGS_SECTION_APPEARANCE = "Tooltip Appearance"

L.SETTINGS_SHOW_ILVL_NAME     = "Show Item Level"
L.SETTINGS_SHOW_ILVL_TIP      = "Display item level in the tooltip."
L.SETTINGS_SHOW_MPLUS_NAME    = "Show M+ Score"
L.SETTINGS_SHOW_MPLUS_TIP     = "Display Mythic+ score and top runs in the tooltip."
L.SETTINGS_SHOW_RAID_NAME     = "Show Raid Progress"
L.SETTINGS_SHOW_RAID_TIP      = "Display raid boss kill progress in the tooltip."
L.SETTINGS_SHOW_TIER_NAME     = "Show Tier Set Count"
L.SETTINGS_SHOW_TIER_TIP      = "Display tier set piece count in the shift-hover tooltip."
L.SETTINGS_SHOW_COLORS_NAME   = "Class-Colored Names"
L.SETTINGS_SHOW_COLORS_TIP    = "Color player names and class text by their class color."
L.SETTINGS_SHOW_GUILD_NAME    = "Show Guild Rank"
L.SETTINGS_SHOW_GUILD_TIP     = "Display guild rank alongside guild name."
L.SETTINGS_SHOW_SHIFT_NAME    = "Shift-Hover Details"
L.SETTINGS_SHOW_SHIFT_TIP     = "Enable expanded details when holding Shift over a tooltip."

local locale = GetLocale()

if locale == "ruRU" then
    L.UNIT_TOOLTIP_TIER_LABEL  = "Уровень"
    L.UNIT_TOOLTIP_SHIFT_HINT  = "[Shift] Подробности"
    L.UNIT_TOOLTIP_RAID_LABEL  = "Рейд"
    L.UNIT_TOOLTIP_RAID_HEADER = "Прогресс рейда"

    L.SETTINGS_SECTION_DISPLAY    = "Отображение подсказки"
    L.SETTINGS_SECTION_APPEARANCE = "Внешний вид подсказки"
    L.SETTINGS_SHOW_ILVL_NAME     = "Показывать уровень предметов"
    L.SETTINGS_SHOW_ILVL_TIP      = "Отображать уровень предметов в подсказке."
    L.SETTINGS_SHOW_MPLUS_NAME    = "Показывать рейтинг М+"
    L.SETTINGS_SHOW_MPLUS_TIP     = "Отображать рейтинг М+ и лучшие прохождения в подсказке."
    L.SETTINGS_SHOW_RAID_NAME     = "Показывать прогресс рейда"
    L.SETTINGS_SHOW_RAID_TIP      = "Отображать прогресс убийств боссов рейда в подсказке."
    L.SETTINGS_SHOW_TIER_NAME     = "Показывать части тир-сета"
    L.SETTINGS_SHOW_TIER_TIP      = "Отображать количество частей тир-сета в расширенной подсказке."
    L.SETTINGS_SHOW_COLORS_NAME   = "Цвета классов"
    L.SETTINGS_SHOW_COLORS_TIP    = "Окрашивать имена игроков и текст класса в цвет класса."
    L.SETTINGS_SHOW_GUILD_NAME    = "Показывать ранг в гильдии"
    L.SETTINGS_SHOW_GUILD_TIP     = "Отображать ранг в гильдии рядом с названием гильдии."
    L.SETTINGS_SHOW_SHIFT_NAME    = "Подробности по Shift"
    L.SETTINGS_SHOW_SHIFT_TIP     = "Показывать расширенную информацию при удержании Shift."

elseif locale == "esES" or locale == "esMX" then
    L.UNIT_TOOLTIP_TIER_LABEL  = "Tier"
    L.UNIT_TOOLTIP_SHIFT_HINT  = "[Shift] Detalles"
    L.UNIT_TOOLTIP_RAID_LABEL  = "Banda"
    L.UNIT_TOOLTIP_RAID_HEADER = "Progreso de banda"

    L.SETTINGS_SECTION_DISPLAY    = "Información del tooltip"
    L.SETTINGS_SECTION_APPEARANCE = "Apariencia del tooltip"
    L.SETTINGS_SHOW_ILVL_NAME     = "Mostrar nivel de objeto"
    L.SETTINGS_SHOW_ILVL_TIP      = "Muestra el nivel de objeto en el tooltip."
    L.SETTINGS_SHOW_MPLUS_NAME    = "Mostrar puntuación M+"
    L.SETTINGS_SHOW_MPLUS_TIP     = "Muestra la puntuación M+ y las mejores carreras en el tooltip."
    L.SETTINGS_SHOW_RAID_NAME     = "Mostrar progreso de banda"
    L.SETTINGS_SHOW_RAID_TIP      = "Muestra el progreso de jefes de banda en el tooltip."
    L.SETTINGS_SHOW_TIER_NAME     = "Mostrar piezas de tier"
    L.SETTINGS_SHOW_TIER_TIP      = "Muestra la cantidad de piezas de tier en el tooltip expandido."
    L.SETTINGS_SHOW_COLORS_NAME   = "Nombres con color de clase"
    L.SETTINGS_SHOW_COLORS_TIP    = "Colorea los nombres y texto de clase según su clase."
    L.SETTINGS_SHOW_GUILD_NAME    = "Mostrar rango de hermandad"
    L.SETTINGS_SHOW_GUILD_TIP     = "Muestra el rango de hermandad junto al nombre de la hermandad."
    L.SETTINGS_SHOW_SHIFT_NAME    = "Detalles con Shift"
    L.SETTINGS_SHOW_SHIFT_TIP     = "Muestra información expandida al mantener Shift sobre el tooltip."
end
