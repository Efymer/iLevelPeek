local addonName, addon = ...
local L = addon.L

addon.Tooltip = addon.Tooltip or {}

local Tooltip = addon.Tooltip
local pendingGUID = nil
local pendingUnit = nil
local lastInspectTime = 0
local retryTimer = nil
local lastShiftState = false
local currentTooltipUnit = nil

local MOUSEOVER_INSPECT_THROTTLE = 1.5
local MOUSEOVER_CACHE_TTL = 300
local TOOLTIP_LINE_ADDED_KEY = addonName .. "_TooltipLineAdded"
local TIER_SLOTS = {1, 3, 5, 7, 10}

-- Wrapper for tooltip:GetUnit() that returns nil for secret/tainted values
-- (Patch 12.0.0 marks unit tokens as secret in certain contexts like combat)
local function safeGetTooltipUnit(tooltip)
    local _, unit = tooltip:GetUnit()
    if not unit then return nil end
    local ok = pcall(UnitExists, unit)
    if not ok then return nil end
    return unit
end

local function isMouseoverCacheValid(member)
    if not member or not member.itemLevel or not member.lastScanAt then
        return false
    end

    return (addon:GetTimestamp() - member.lastScanAt) < MOUSEOVER_CACHE_TTL
end

local function canInspectMouseover()
    local now = addon:GetTimestamp()
    return (now - lastInspectTime) >= MOUSEOVER_INSPECT_THROTTLE
end

local function getMythicPlusColor(score)
    if not score or score <= 0 then
        return 0.62, 0.62, 0.62
    end

    if C_ChallengeMode and C_ChallengeMode.GetDungeonScoreRarityColor then
        local color = C_ChallengeMode.GetDungeonScoreRarityColor(score)
        if color then
            return color.r, color.g, color.b
        end
    end

    return 1.0, 1.0, 1.0
end

local function countTierSetPieces(unit)
    local count = 0
    if not C_TooltipInfo or not C_TooltipInfo.GetInventoryItem then
        return count
    end
    for _, slot in ipairs(TIER_SLOTS) do
        local tooltipData = C_TooltipInfo.GetInventoryItem(unit, slot)
        if tooltipData and tooltipData.lines then
            for _, lineData in ipairs(tooltipData.lines) do
                local lt = lineData.leftText
                if lt and (lt:find("%(%d+/%d+%)") or lt:find("Set:")) then
                    count = count + 1
                    break
                end
            end
        end
    end
    return count
end

local function addShiftHoverLines(tooltip, member, unit)
    -- Tier set count
    local tierCount = member.tierSetCount or 0
    tooltip:AddLine(string.format("%s: %d/5", L.UNIT_TOOLTIP_TIER_LABEL, tierCount), 0.94, 0.49, 0.72)

    -- M+ dungeon breakdown
    local runs = member.mythicPlusRuns
    if runs and #runs > 0 then
        table.sort(runs, function(a, b) return (a.mapScore or 0) > (b.mapScore or 0) end)
        tooltip:AddLine(" ")
        tooltip:AddLine("Top 5 M+ Runs", 1.0, 0.82, 0.0)
        local count = 0
        for _, run in ipairs(runs) do
            count = count + 1
            if count > 5 then break end
            local dungeonName = "Unknown"
            if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
                local name = C_ChallengeMode.GetMapUIInfo(run.challengeModeID)
                if name then
                    dungeonName = name
                end
            end
            local levelText = string.format("+%d", run.bestRunLevel or 0)
            if run.finishedSuccess then
                levelText = levelText .. " |A:common-icon-checkmark:12:12|a"
            else
                levelText = levelText .. " |A:common-icon-redx:12:12|a"
            end
            local scoreR, scoreG, scoreB = getMythicPlusColor(run.mapScore or 0)
            tooltip:AddDoubleLine(
                dungeonName,
                string.format("%s  (%d)", levelText, run.mapScore or 0),
                0.85, 0.85, 0.85,
                scoreR, scoreG, scoreB
            )
        end
    end
end

local function addTooltipLines(tooltip, member, unit)
    if tooltip[TOOLTIP_LINE_ADDED_KEY] then
        return
    end

    if not member then
        return
    end

    local mythicPlusRating = member.mythicPlusRating
    local mplusText = mythicPlusRating and string.format("%s: %d", L.UNIT_TOOLTIP_MPLUS_LABEL, mythicPlusRating)
        or string.format("%s: 0", L.UNIT_TOOLTIP_MPLUS_LABEL)
    local mR, mG, mB = getMythicPlusColor(mythicPlusRating or 0)

    if member.itemLevel then
        local iR, iG, iB = addon.Colors:GetItemLevelColor(member.itemLevel)
        tooltip:AddDoubleLine(
            string.format("%s: %.1f", L.UNIT_TOOLTIP_ILVL_LABEL, member.itemLevel),
            mplusText,
            iR, iG, iB, mR, mG, mB
        )
    else
        tooltip:AddDoubleLine(
            string.format("%s: ...", L.UNIT_TOOLTIP_ILVL_LABEL),
            mplusText,
            0.85, 0.82, 0.50, mR, mG, mB
        )
    end
    tooltip[TOOLTIP_LINE_ADDED_KEY] = true

    if IsShiftKeyDown() then
        addShiftHoverLines(tooltip, member, unit)
    else
        tooltip:AddLine(L.UNIT_TOOLTIP_SHIFT_HINT, 0.50, 0.50, 0.50)
    end
end

local function clearTooltipFlag(tooltip)
    tooltip[TOOLTIP_LINE_ADDED_KEY] = nil
end

local function onTooltipSetUnit(tooltip, data)
    if not addon.initialized then
        return
    end

    clearTooltipFlag(tooltip)

    local unit = safeGetTooltipUnit(tooltip)
    if not unit or not UnitIsPlayer(unit) then
        currentTooltipUnit = nil
        return
    end

    currentTooltipUnit = unit
    local guid = UnitGUID(unit)
    if not guid then
        return
    end

    -- Color player name by class
    local _, classFile = UnitClass(unit)
    if classFile then
        local classColor = RAID_CLASS_COLORS[classFile]
        if classColor then
            local nameLine = _G["GameTooltipTextLeft1"]
            if nameLine then
                nameLine:SetTextColor(classColor.r, classColor.g, classColor.b)
            end
        end
    end

    -- Modify existing guild line to include rank
    local guildName, guildRankName = GetGuildInfo(unit)
    if guildName and guildRankName then
        for i = 2, tooltip:NumLines() do
            local line = _G["GameTooltipTextLeft" .. i]
            if line then
                local text = line:GetText()
                if text and text:find(guildName, 1, true) then
                    line:SetText(string.format("%s of <%s>", guildRankName, guildName))
                    line:SetTextColor(0.25, 1.0, 0.25)
                    break
                end
            end
        end
    end

    -- Color the class name in the "Level XX Spec Class" line
    if classFile then
        local classColor = RAID_CLASS_COLORS[classFile]
        local localizedClass = UnitClass(unit)
        if classColor and localizedClass then
            local colorCode = string.format("|cff%02x%02x%02x",
                math.floor(classColor.r * 255),
                math.floor(classColor.g * 255),
                math.floor(classColor.b * 255))
            for i = 2, tooltip:NumLines() do
                local line = _G["GameTooltipTextLeft" .. i]
                if line then
                    local text = line:GetText()
                    if text and text:find(localizedClass, 1, true) then
                        local newText = text:gsub(localizedClass, colorCode .. localizedClass .. "|r")
                        line:SetText(newText)
                        break
                    end
                end
            end
        end
    end

    if UnitIsUnit(unit, "player") then
        local averageItemLevel, equippedItemLevel = GetAverageItemLevel()
        local itemLevel = equippedItemLevel or averageItemLevel
        local score = C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore and C_ChallengeMode.GetOverallDungeonScore() or 0
        local mR, mG, mB = getMythicPlusColor(score)

        if itemLevel and itemLevel > 0 then
            local iR, iG, iB = addon.Colors:GetItemLevelColor(addon:RoundItemLevel(itemLevel))
            tooltip:AddDoubleLine(
                string.format("%s: %.1f", L.UNIT_TOOLTIP_ILVL_LABEL, addon:RoundItemLevel(itemLevel)),
                string.format("%s: %d", L.UNIT_TOOLTIP_MPLUS_LABEL, score),
                iR, iG, iB, mR, mG, mB
            )
            tooltip[TOOLTIP_LINE_ADDED_KEY] = true
        end

        if IsShiftKeyDown() then
            -- Tier set for self
            local selfTierCount = countTierSetPieces("player")
            tooltip:AddLine(string.format("%s: %d/5", L.UNIT_TOOLTIP_TIER_LABEL, selfTierCount), 0.94, 0.49, 0.72)
            -- M+ breakdown for self
            local selfSummary = C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary
                and C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
            if selfSummary and selfSummary.runs then
                local sortedRuns = {}
                for i, run in ipairs(selfSummary.runs) do sortedRuns[i] = run end
                table.sort(sortedRuns, function(a, b) return (a.mapScore or 0) > (b.mapScore or 0) end)
                tooltip:AddLine(" ")
                tooltip:AddLine("Top 5 M+ Runs", 1.0, 0.82, 0.0)
                local count = 0
                for _, run in ipairs(sortedRuns) do
                    count = count + 1
                    if count > 5 then break end
                    local dungeonName = "Unknown"
                    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
                        local name = C_ChallengeMode.GetMapUIInfo(run.challengeModeID)
                        if name then dungeonName = name end
                    end
                    local levelText = string.format("+%d", run.bestRunLevel or 0)
                    if run.finishedSuccess then
                        levelText = levelText .. " |A:common-icon-checkmark:12:12|a"
                    else
                        levelText = levelText .. " |A:common-icon-redx:12:12|a"
                    end
                    local sR, sG, sB = getMythicPlusColor(run.mapScore or 0)
                    tooltip:AddDoubleLine(
                        dungeonName,
                        string.format("%s  (%d)", levelText, run.mapScore or 0),
                        0.85, 0.85, 0.85, sR, sG, sB
                    )
                end
            end
        else
            tooltip:AddLine(L.UNIT_TOOLTIP_SHIFT_HINT, 0.50, 0.50, 0.50)
        end

        return
    end

    local member = addon.members[guid]

    if member and isMouseoverCacheValid(member) then
        addTooltipLines(tooltip, member, unit)
        return
    end

    if not member then
        member = addon:GetOrCreateMember(guid)
        local _, classFile = UnitClass(unit)
        local shortName = UnitName(unit)
        member.name = shortName or GetUnitName(unit, false) or UNKNOWN
        member.classFile = classFile
        member.mouseoverOnly = true
    end

    -- Pre-fetch M+ data immediately — works regardless of inspect range
    if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
        if ratingSummary and ratingSummary.currentSeasonScore and ratingSummary.currentSeasonScore > 0 then
            member.mythicPlusRating = ratingSummary.currentSeasonScore
            if ratingSummary.runs then
                member.mythicPlusRuns = {}
                for _, run in ipairs(ratingSummary.runs) do
                    member.mythicPlusRuns[#member.mythicPlusRuns + 1] = {
                        challengeModeID = run.challengeModeID,
                        mapScore = run.mapScore,
                        bestRunLevel = run.bestRunLevel,
                        finishedSuccess = run.finishedSuccess,
                    }
                end
            end
        end
    end
    addTooltipLines(tooltip, member, unit)

    if retryTimer then
        retryTimer:Cancel()
        retryTimer = nil
    end

    if canInspectMouseover() and CanInspect(unit, false) then
        pendingGUID = guid
        pendingUnit = unit
        lastInspectTime = addon:GetTimestamp()
        NotifyInspect(unit)
    else
        local retryGUID = guid
        local now = addon:GetTimestamp()
        local remaining = math.max(MOUSEOVER_INSPECT_THROTTLE - (now - lastInspectTime), 0.1)

        retryTimer = C_Timer.NewTimer(remaining, function()
            retryTimer = nil

            if not GameTooltip:IsShown() then
                return
            end

            local retryUnit = safeGetTooltipUnit(GameTooltip)
            if not retryUnit or UnitGUID(retryUnit) ~= retryGUID then
                return
            end

            if not CanInspect(retryUnit, false) then
                return
            end

            pendingGUID = retryGUID
            pendingUnit = retryUnit
            lastInspectTime = addon:GetTimestamp()
            NotifyInspect(retryUnit)
        end)
    end
end

local function onTooltipCleared(tooltip)
    clearTooltipFlag(tooltip)
    currentTooltipUnit = nil

    if retryTimer then
        retryTimer:Cancel()
        retryTimer = nil
    end
end

function Tooltip:Initialize()
    if self.initialized then
        return
    end

    self.initialized = true

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, onTooltipSetUnit)
    else
        GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
            onTooltipSetUnit(tooltip, nil)
        end)
    end

    GameTooltip:HookScript("OnTooltipCleared", onTooltipCleared)

    -- Dynamic shift detection: re-render tooltip when shift state changes
    GameTooltip:HookScript("OnUpdate", function(tip)
        if not currentTooltipUnit then
            lastShiftState = false
            return
        end
        local shiftNow = IsShiftKeyDown()
        if shiftNow ~= lastShiftState then
            lastShiftState = shiftNow
            clearTooltipFlag(tip)
            tip:SetUnit(currentTooltipUnit)
        end
    end)
end

function Tooltip:OnInspectReady(guid)
    if not pendingGUID or pendingGUID ~= guid then
        return false
    end

    local member = addon.members[guid]
    local unit = pendingUnit

    pendingGUID = nil
    pendingUnit = nil

    if not member or not unit then
        return true
    end

    local itemLevel = C_PaperDollInfo.GetInspectItemLevel(unit)

    if itemLevel and itemLevel > 0 then
        member.itemLevel = addon:RoundItemLevel(itemLevel)
        member.lastScanAt = addon:GetTimestamp()
        member.status = "ready"

    end

    local ratingSummary
    if unit and UnitGUID(unit) == guid and C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
    end
    if ratingSummary and ratingSummary.currentSeasonScore and ratingSummary.currentSeasonScore > 0 then
        member.mythicPlusRating = ratingSummary.currentSeasonScore
    end

    -- Cache M+ runs for shift-hover
    if ratingSummary and ratingSummary.runs then
        member.mythicPlusRuns = {}
        for _, run in ipairs(ratingSummary.runs) do
            member.mythicPlusRuns[#member.mythicPlusRuns + 1] = {
                challengeModeID = run.challengeModeID,
                mapScore = run.mapScore,
                bestRunLevel = run.bestRunLevel,
                finishedSuccess = run.finishedSuccess,
            }
        end
    end

    -- Cache tier set count
    member.tierSetCount = countTierSetPieces(unit)

    if member.itemLevel or member.mythicPlusRating then
        if GameTooltip:IsShown() then
            local tooltipUnit = safeGetTooltipUnit(GameTooltip)
            if tooltipUnit and UnitGUID(tooltipUnit) == guid then
                clearTooltipFlag(GameTooltip)
                GameTooltip:SetUnit(tooltipUnit)
            end
        end
    end

    ClearInspectPlayer()
    return true
end
