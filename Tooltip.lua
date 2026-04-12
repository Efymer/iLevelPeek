local addonName, addon = ...
local L = addon.L

addon.Tooltip = addon.Tooltip or {}

local Tooltip = addon.Tooltip

local function setting(key)
    if addon.Settings and addon.Settings.Get then
        return addon.Settings:Get(key)
    end
    return true
end
local pendingGUID = nil
local pendingUnit = nil
local pendingAchievementGUID = nil
local lastInspectTime = 0
local retryTimer = nil
local lastShiftState = false
local currentTooltipUnit = nil

local MOUSEOVER_INSPECT_THROTTLE = 1.5
local MOUSEOVER_CACHE_TTL = 300
local MPLUS_RETRY_INTERVAL = 3
local MPLUS_RETRY_MAX = 5
local TOOLTIP_LINE_ADDED_KEY = addonName .. "_TooltipLineAdded"
local TIER_SLOTS = {1, 3, 5, 7, 10}

-- Compare two values inside pcall to avoid taint errors in combat
local function safeEquals(a, b)
    local ok, result = pcall(rawequal, a, b)
    if ok then return result end
    ok, result = pcall(function() return a == b end)
    if ok then return result end
    return false
end

-- Return UnitGUID result; may still be tainted but safeEquals handles comparison
local function safeUnitGUID(unit)
    local ok, guid = pcall(UnitGUID, unit)
    if ok and guid then return guid end
    return nil
end

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

-- Find a stable group unit token (party1/raid5/etc.) for a given GUID
local function findGroupUnit(guid)
    local prefix, count
    if IsInRaid() then
        prefix, count = "raid", GetNumGroupMembers()
    elseif IsInGroup() then
        prefix, count = "party", GetNumGroupMembers() - 1
    end
    if not prefix then return nil end
    for i = 1, count do
        local u = prefix .. i
        if safeEquals(safeUnitGUID(u), guid) then
            return u
        end
    end
    return nil
end

-- Fetch and cache M+ data from a rating summary into a member table
local function cacheMythicPlusData(member, summary)
    if not summary or not summary.currentSeasonScore or summary.currentSeasonScore <= 0 then
        return false
    end
    member.mythicPlusRating = summary.currentSeasonScore
    if summary.runs then
        member.mythicPlusRuns = {}
        for _, run in ipairs(summary.runs) do
            member.mythicPlusRuns[#member.mythicPlusRuns + 1] = {
                challengeModeID = run.challengeModeID,
                mapScore = run.mapScore,
                bestRunLevel = run.bestRunLevel,
                finishedSuccess = run.finishedSuccess,
            }
        end
    end
    return true
end

-- Retry M+ fetch for a member whose data wasn't available yet
local function retryMythicPlusFetch(guid, attempt)
    attempt = attempt or 1
    local member = addon.members[guid]
    if not member or member.mythicPlusRating then return end

    local u = findGroupUnit(guid)
    if not u then return end

    local summary = C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary
        and C_PlayerInfo.GetPlayerMythicPlusRatingSummary(u)
    if cacheMythicPlusData(member, summary) then
        -- Refresh tooltip if still showing this player
        if GameTooltip:IsShown() then
            local tooltipUnit = safeGetTooltipUnit(GameTooltip)
            if tooltipUnit and safeEquals(safeUnitGUID(tooltipUnit), guid) then
                clearTooltipFlag(GameTooltip)
                GameTooltip:SetUnit(tooltipUnit)
            end
        end
    elseif attempt < MPLUS_RETRY_MAX then
        C_Timer.After(MPLUS_RETRY_INTERVAL, function()
            retryMythicPlusFetch(guid, attempt + 1)
        end)
    end
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

-- Returns true if a statistic string indicates at least 1 kill
local function statValueHasKill(value)
    if not value or value == "--" or value == "0" then return false end
    return true
end

-- Compute raid progress using a stat lookup function: fn(statID) -> string
local function computeRaidProgress(statFn)
    local raids = addon.Config.raids
    if not raids or #raids == 0 then return nil end

    local difficulties = addon.Config.raidDifficulties
    local results = {}

    for _, raid in ipairs(raids) do
        local raidResult = {
            name = raid.name,
            totalBosses = #raid.encounters,
            difficulties = {},
        }

        for _, diff in ipairs(difficulties) do
            local killed = 0
            for _, enc in ipairs(raid.encounters) do
                local statID = enc.stats[diff.key]
                if statID and statID > 0 and statValueHasKill(statFn(statID)) then
                    killed = killed + 1
                end
            end
            raidResult.difficulties[#raidResult.difficulties + 1] = {
                key = diff.key,
                short = diff.short,
                color = diff.color,
                killed = killed,
                hidden = diff.hidden,
            }
        end

        results[#results + 1] = raidResult
    end

    return results
end

-- Returns raid progress for the local player
local function getSelfRaidProgress()
    return computeRaidProgress(GetStatistic)
end

-- Returns raid progress for an inspected player
local function getComparisonRaidProgress()
    if not GetComparisonStatistic then return nil end
    return computeRaidProgress(GetComparisonStatistic)
end

-- Returns compact summary string like "3/9 H" aggregated across all raids
local function getBestRaidSummary(raidProgressList)
    if not raidProgressList or #raidProgressList == 0 then return nil end

    local difficulties = addon.Config.raidDifficulties
    for _, diff in ipairs(difficulties) do
        if not diff.hidden then
            local totalKilled = 0
            local totalBosses = 0
            for _, raid in ipairs(raidProgressList) do
                for _, rd in ipairs(raid.difficulties) do
                    if rd.key == diff.key then
                        totalKilled = totalKilled + rd.killed
                        totalBosses = totalBosses + raid.totalBosses
                    end
                end
            end
            if totalKilled > 0 then
                return string.format("%d/%d %s", totalKilled, totalBosses, diff.short), diff.color
            end
        end
    end

    return nil
end

local function addShiftHoverLines(tooltip, member, unit)
    -- Tier set count
    if setting("showTierSet") then
        local tierCount = member.tierSetCount or 0
        tooltip:AddLine(string.format("%s: %d/5", L.UNIT_TOOLTIP_TIER_LABEL, tierCount), 0.94, 0.49, 0.72)
    end

    -- M+ dungeon breakdown
    local runs = setting("showMythicPlus") and member.mythicPlusRuns or nil
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

    -- Raid progress breakdown for inspected player
    local raidProgress = setting("showRaidProgress") and member.raidProgress or nil
    if raidProgress then
        local hasAnyProgress = false
        for _, raid in ipairs(raidProgress) do
            for _, diff in ipairs(raid.difficulties) do
                if diff.killed > 0 and not diff.hidden then hasAnyProgress = true break end
            end
            if hasAnyProgress then break end
        end
        if hasAnyProgress then
            tooltip:AddLine(" ")
            tooltip:AddLine(L.UNIT_TOOLTIP_RAID_HEADER, 1.0, 0.82, 0.0)
            for _, raid in ipairs(raidProgress) do
                local hasAny = false
                for _, diff in ipairs(raid.difficulties) do
                    if diff.killed > 0 and not diff.hidden then hasAny = true break end
                end
                if hasAny then
                    tooltip:AddLine(raid.name, 0.95, 0.95, 0.95)
                    for _, diff in ipairs(raid.difficulties) do
                        if diff.killed > 0 and not diff.hidden then
                            tooltip:AddDoubleLine(
                                string.format("  %s", diff.short),
                                string.format("%d/%d", diff.killed, raid.totalBosses),
                                diff.color[1], diff.color[2], diff.color[3],
                                diff.color[1], diff.color[2], diff.color[3]
                            )
                        end
                    end
                end
            end
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
    local mplusText = setting("showMythicPlus") and (mythicPlusRating and string.format("%s: %d", L.UNIT_TOOLTIP_MPLUS_LABEL, mythicPlusRating)
        or string.format("%s: 0", L.UNIT_TOOLTIP_MPLUS_LABEL)) or nil
    local mR, mG, mB = getMythicPlusColor(mythicPlusRating or 0)

    local leftText, rightText
    if setting("showItemLevel") then
        if member.itemLevel then
            leftText = string.format("%s: %.1f", L.UNIT_TOOLTIP_ILVL_LABEL, member.itemLevel)
        else
            leftText = string.format("%s: ...", L.UNIT_TOOLTIP_ILVL_LABEL)
        end
    end

    if leftText and mplusText then
        local iR, iG, iB = member.itemLevel and addon.Colors:GetItemLevelColor(member.itemLevel) or 0.85, 0.82, 0.50
        tooltip:AddDoubleLine(leftText, mplusText, iR, iG, iB, mR, mG, mB)
    elseif leftText then
        local iR, iG, iB = member.itemLevel and addon.Colors:GetItemLevelColor(member.itemLevel) or 0.85, 0.82, 0.50
        tooltip:AddLine(leftText, iR, iG, iB)
    elseif mplusText then
        tooltip:AddLine(mplusText, mR, mG, mB)
    end
    tooltip[TOOLTIP_LINE_ADDED_KEY] = true

    if setting("showRaidProgress") and member.raidProgress then
        local raidSummary, raidColor = getBestRaidSummary(member.raidProgress)
        if raidSummary and raidColor then
            tooltip:AddDoubleLine(" ", string.format("%s: %s", L.UNIT_TOOLTIP_RAID_LABEL, raidSummary),
                0, 0, 0, raidColor[1], raidColor[2], raidColor[3])
        end
    end

    if setting("showShiftDetails") and IsShiftKeyDown() then
        addShiftHoverLines(tooltip, member, unit)
    elseif setting("showShiftDetails") then
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
    local guid = safeUnitGUID(unit)
    if not guid then
        return
    end

    local _, classFile = UnitClass(unit)

    -- Color player name by class
    if setting("showClassColors") and classFile then
        local classColor = RAID_CLASS_COLORS[classFile]
        if classColor then
            local nameLine = _G["GameTooltipTextLeft1"]
            if nameLine then
                nameLine:SetTextColor(classColor.r, classColor.g, classColor.b)
            end
        end
    end

    -- Modify existing guild line to include rank
    if setting("showGuildRank") then
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
    end

    -- Color the class name in the "Level XX Spec Class" line
    if setting("showClassColors") and classFile then
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

        local selfRaidProgress = setting("showRaidProgress") and getSelfRaidProgress() or nil
        local raidSummary, raidColor = getBestRaidSummary(selfRaidProgress)

        if itemLevel and itemLevel > 0 then
            local iR, iG, iB = addon.Colors:GetItemLevelColor(addon:RoundItemLevel(itemLevel))
            local leftText = setting("showItemLevel") and string.format("%s: %.1f", L.UNIT_TOOLTIP_ILVL_LABEL, addon:RoundItemLevel(itemLevel)) or nil
            local rightText = setting("showMythicPlus") and string.format("%s: %d", L.UNIT_TOOLTIP_MPLUS_LABEL, score) or nil

            if leftText and rightText then
                tooltip:AddDoubleLine(leftText, rightText, iR, iG, iB, mR, mG, mB)
            elseif leftText then
                tooltip:AddLine(leftText, iR, iG, iB)
            elseif rightText then
                tooltip:AddLine(rightText, mR, mG, mB)
            end
            tooltip[TOOLTIP_LINE_ADDED_KEY] = true
        end

        if raidSummary and raidColor then
            tooltip:AddDoubleLine(" ", string.format("%s: %s", L.UNIT_TOOLTIP_RAID_LABEL, raidSummary),
                0, 0, 0, raidColor[1], raidColor[2], raidColor[3])
        end

        if setting("showShiftDetails") and IsShiftKeyDown() then
            -- Tier set for self
            if setting("showTierSet") then
                local selfTierCount = countTierSetPieces("player")
                tooltip:AddLine(string.format("%s: %d/5", L.UNIT_TOOLTIP_TIER_LABEL, selfTierCount), 0.94, 0.49, 0.72)
            end

            -- M+ breakdown for self
            if setting("showMythicPlus") then
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
            end

            -- Raid progress breakdown
            if setting("showRaidProgress") and selfRaidProgress then
                local hasAnyProgress = false
                for _, raid in ipairs(selfRaidProgress) do
                    for _, diff in ipairs(raid.difficulties) do
                        if diff.killed > 0 and not diff.hidden then hasAnyProgress = true break end
                    end
                    if hasAnyProgress then break end
                end
                if hasAnyProgress then
                    tooltip:AddLine(" ")
                    tooltip:AddLine(L.UNIT_TOOLTIP_RAID_HEADER, 1.0, 0.82, 0.0)
                    for _, raid in ipairs(selfRaidProgress) do
                        local hasAny = false
                        for _, diff in ipairs(raid.difficulties) do
                            if diff.killed > 0 and not diff.hidden then hasAny = true break end
                        end
                        if hasAny then
                            tooltip:AddLine(raid.name, 0.95, 0.95, 0.95)
                            for _, diff in ipairs(raid.difficulties) do
                                if diff.killed > 0 and not diff.hidden then
                                    tooltip:AddDoubleLine(
                                        string.format("  %s", diff.short),
                                        string.format("%d/%d", diff.killed, raid.totalBosses),
                                        diff.color[1], diff.color[2], diff.color[3],
                                        diff.color[1], diff.color[2], diff.color[3]
                                    )
                                end
                            end
                        end
                    end
                end
            end
        elseif setting("showShiftDetails") then
            tooltip:AddLine(L.UNIT_TOOLTIP_SHIFT_HINT, 0.50, 0.50, 0.50)
        end

        return
    end

    local member = addon.members[guid]

    if member and isMouseoverCacheValid(member) then
        -- Re-try M+ fetch on cached members that are still missing it
        if not member.mythicPlusRating and C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
            local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
            cacheMythicPlusData(member, summary)
        end
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
        cacheMythicPlusData(member, ratingSummary)
    end
    addTooltipLines(tooltip, member, unit)

    -- Achievement comparison works without inspect range — always request it
    if not member.raidProgress then
        pendingAchievementGUID = guid
        SetAchievementComparisonUnit(unit)
    end

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
            if not retryUnit or not safeEquals(safeUnitGUID(retryUnit), retryGUID) then
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
    if not pendingGUID or not safeEquals(pendingGUID, guid) then
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

    -- Resolve a valid unit token for M+ lookup.
    -- "mouseover" may have gone stale while the inspect was in flight,
    -- so fall back to group unit IDs (party1-4 / raid1-40) which are stable.
    local ratingSummary
    if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local mPlusUnit
        if unit and safeEquals(safeUnitGUID(unit), guid) then
            mPlusUnit = unit
        else
            mPlusUnit = findGroupUnit(guid)
        end
        if mPlusUnit then
            ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(mPlusUnit)
        end
    end
    cacheMythicPlusData(member, ratingSummary)

    -- Cache tier set count
    member.tierSetCount = countTierSetPieces(unit)

    if member.itemLevel or member.mythicPlusRating then
        if GameTooltip:IsShown() then
            local tooltipUnit = safeGetTooltipUnit(GameTooltip)
            if tooltipUnit and safeEquals(safeUnitGUID(tooltipUnit), guid) then
                clearTooltipFlag(GameTooltip)
                GameTooltip:SetUnit(tooltipUnit)
            end
        end
    end

    -- If M+ data is still missing, schedule retries — server may deliver it later
    if not member.mythicPlusRating and (IsInGroup() or IsInRaid()) then
        C_Timer.After(MPLUS_RETRY_INTERVAL, function()
            retryMythicPlusFetch(guid, 1)
        end)
    end

    ClearInspectPlayer()
    return true
end

function Tooltip:OnAchievementReady(guid)
    if not pendingAchievementGUID or not safeEquals(pendingAchievementGUID, guid) then
        return false
    end

    local member = addon.members[guid]
    pendingAchievementGUID = nil

    if not member then
        ClearAchievementComparisonUnit()
        return true
    end

    member.raidProgress = getComparisonRaidProgress()

    ClearAchievementComparisonUnit()

    -- Refresh tooltip if still showing this player
    if GameTooltip:IsShown() then
        local tooltipUnit = safeGetTooltipUnit(GameTooltip)
        if tooltipUnit and safeEquals(safeUnitGUID(tooltipUnit), guid) then
            clearTooltipFlag(GameTooltip)
            GameTooltip:SetUnit(tooltipUnit)
        end
    end

    return true
end
