local addonName, addon = ...

addon.members = addon.members or {}
addon.initialized = addon.initialized or false
addon.Tooltip = addon.Tooltip or {}

local floor = math.floor

local eventFrame = addon.EventFrame or CreateFrame("Frame")
addon.EventFrame = eventFrame

function addon:GetTimestamp()
    return GetTime()
end

function addon:RoundItemLevel(value)
    if not value then return nil end
    return floor((value * 10) + 0.5) / 10
end

function addon:GetOrCreateMember(guid)
    local member = self.members[guid]
    if member then return member end
    member = { guid = guid, status = "unknown" }
    self.members[guid] = member
    return member
end

function addon:PLAYER_LOGIN()
    if self.initialized then return end
    self.initialized = true

    if self.Tooltip and self.Tooltip.Initialize then
        self.Tooltip:Initialize()
    end

    eventFrame:RegisterEvent("INSPECT_READY")
end

function addon:INSPECT_READY(guid)
    if self.Tooltip and self.Tooltip.OnInspectReady then
        self.Tooltip:OnInspectReady(guid)
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local handler = addon[event]
    if handler then
        handler(addon, ...)
    end
end)

eventFrame:RegisterEvent("PLAYER_LOGIN")
