local _, ns = ...

ns.uf = ns.uf or {}
ns.unitAuraCache = ns.unitAuraCache or {}

local eventFrame = CreateFrame("Frame")
ns.eventFrame = eventFrame

local rebuildMapPending = false
local headerRefreshPending = false
local auraFlushPending = false
local pendingAuraUnits = {}
local pendingConnectionRefresh = false
local blizzardRaidHooksInstalled = false
local pendingHideBlizzardRaid = false
local READY_CHECK_REFRESH_DELAY = 0.15
local READY_CHECK_DEFAULT_DURATION = 30
local READY_CHECK_RESULT_HOLD_SECONDS = 5
local readyCheckRefreshToken = 0
local readyCheckQueuedRefreshPending = false

ns.readyCheckState = ns.readyCheckState or {
    active = false,
    expiresAt = 0,
    statuses = {},
}

local function ScheduleReadyCheckRefresh(delaySeconds)
    readyCheckRefreshToken = readyCheckRefreshToken + 1
    local token = readyCheckRefreshToken
    local delay = delaySeconds or 0

    C_Timer.After(delay, function()
        if token ~= readyCheckRefreshToken then
            return
        end

        if ns and ns.RefreshStatusIcons then
            ns:RefreshStatusIcons()
        end
    end)
end

local function QueueReadyCheckRefresh(delaySeconds)
    if readyCheckQueuedRefreshPending then
        return
    end

    readyCheckQueuedRefreshPending = true
    C_Timer.After(delaySeconds or 0.05, function()
        readyCheckQueuedRefreshPending = false
        if ns and ns.RefreshStatusIcons then
            ns:RefreshStatusIcons()
        end
    end)
end

function ns:NormalizeReadyCheckStatus(value)
    if value == "ready" or value == true or value == 1 then
        return "ready"
    end

    if value == "notready" or value == false or value == 0 then
        return "notready"
    end

    if value == "waiting" then
        return "waiting"
    end

    return nil
end

local function SetReadyCheckStatus(unit, status)
    if not unit then
        return
    end

    local state = ns.readyCheckState
    state.statuses = state.statuses or {}
    if status then
        state.statuses[unit] = {
            status = status,
            expiresAt = GetTime() + READY_CHECK_RESULT_HOLD_SECONDS
        }
        ScheduleReadyCheckRefresh(READY_CHECK_RESULT_HOLD_SECONDS + 0.05)
    else
        state.statuses[unit] = nil
    end
end

function ns:GetEffectiveReadyCheckStatus(unit, now)
    now = now or GetTime()

    local status = self:NormalizeReadyCheckStatus(GetReadyCheckStatus and GetReadyCheckStatus(unit))
    if status then
        return status
    end

    local state = self.readyCheckState
    if not state or not state.statuses then
        return nil
    end

    local cached = state.statuses[unit]
    if cached and cached.expiresAt and cached.expiresAt > now then
        return cached.status
    end

    if cached then
        state.statuses[unit] = nil
    end

    return nil
end

local function IsReadyCheckResolvedForAll()
    local hasUnit = false

    if IsInRaid() then
        local count = GetNumGroupMembers() or 0
        for i = 1, count do
            local unit = "raid" .. i
            if UnitExists(unit) then
                hasUnit = true
                local status = ns:GetEffectiveReadyCheckStatus(unit)
                if status ~= "ready" and status ~= "notready" then
                    return false
                end
            end
        end
    elseif IsInGroup() then
        local playerStatus = ns:GetEffectiveReadyCheckStatus("player")
        if UnitExists("player") then
            hasUnit = true
            if playerStatus ~= "ready" and playerStatus ~= "notready" then
                return false
            end
        end

        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) then
                hasUnit = true
                local status = ns:GetEffectiveReadyCheckStatus(unit)
                if status ~= "ready" and status ~= "notready" then
                    return false
                end
            end
        end
    end

    return hasUnit
end

local function FinishReadyCheckState(keepResults)
    if not ns.readyCheckState then
        return
    end

    local state = ns.readyCheckState
    local now = GetTime()

    local hasKeptResult = false
    if keepResults and state.statuses then
        for unit, info in pairs(state.statuses) do
            if info and (info.status == "ready" or info.status == "notready") then
                local keepUntil = now + READY_CHECK_RESULT_HOLD_SECONDS
                info.expiresAt = math.max(info.expiresAt or 0, keepUntil)
                hasKeptResult = true
            else
                state.statuses[unit] = nil
            end
        end
    else
        state.statuses = {}
    end

    state.active = false
    state.expiresAt = 0

    if hasKeptResult then
        ScheduleReadyCheckRefresh(READY_CHECK_RESULT_HOLD_SECONDS + 0.05)
    else
        ScheduleReadyCheckRefresh(0)
    end
end

local function ForceHideFrame(frame)
    if not frame then
        return
    end

    if InCombatLockdown() then
        pendingHideBlizzardRaid = true
        return
    end

    frame:Hide()

    if not frame.__hrHiddenHooked then
        frame.__hrHiddenHooked = true
        frame:HookScript("OnShow", function(self)
            if InCombatLockdown() then
                pendingHideBlizzardRaid = true
            else
                self:Hide()
            end
        end)
    end
end

local function HideBlizzardRaidFrames()
    if InCombatLockdown() then
        pendingHideBlizzardRaid = true
        return
    end

    if CompactRaidFrameManager then
        ForceHideFrame(CompactRaidFrameManager)
    end

    if CompactRaidFrameContainer then
        ForceHideFrame(CompactRaidFrameContainer)
    end

    if CompactRaidFrameManagerDisplayFrameHiddenModeToggle then
        ForceHideFrame(CompactRaidFrameManagerDisplayFrameHiddenModeToggle)
    end
end

local function OnBlizzardRaidFrameShow(self)
    if InCombatLockdown() then
        pendingHideBlizzardRaid = true
        return
    end

    self:Hide()
end

local function SetupBlizzardRaidFrameHooks()
    if blizzardRaidHooksInstalled then
        HideBlizzardRaidFrames()
        return
    end

    blizzardRaidHooksInstalled = true

    -- 1. CompactRaidFrameManager (좌측 레이드 바)
    if CompactRaidFrameManager then
        CompactRaidFrameManager:UnregisterAllEvents()
        if not CompactRaidFrameManager.__hrHideHooked then
            CompactRaidFrameManager.__hrHideHooked = true
            CompactRaidFrameManager:HookScript("OnShow", OnBlizzardRaidFrameShow)
        end
    end

    -- 2. CompactRaidFrameContainer (실제 레이드 프레임 본체)
    if CompactRaidFrameContainer then
        CompactRaidFrameContainer:UnregisterAllEvents()
        if not CompactRaidFrameContainer.__hrHideHooked then
            CompactRaidFrameContainer.__hrHideHooked = true
            CompactRaidFrameContainer:HookScript("OnShow", OnBlizzardRaidFrameShow)
        end
    end

    if CompactUnitFrameProfiles then
        CompactUnitFrameProfiles:UnregisterAllEvents()
    end

    -- 4. 숨김 모드 토글 버튼
    if CompactRaidFrameManagerDisplayFrameHiddenModeToggle then
        if not CompactRaidFrameManagerDisplayFrameHiddenModeToggle.__hrHideHooked then
            CompactRaidFrameManagerDisplayFrameHiddenModeToggle.__hrHideHooked = true
            CompactRaidFrameManagerDisplayFrameHiddenModeToggle:HookScript("OnShow", OnBlizzardRaidFrameShow)
        end
    end

    HideBlizzardRaidFrames()
end

local function ClearTable(t)
    for key in pairs(t) do
        t[key] = nil
    end
end

local function RebuildPartyUnitFrameMap()
    ns.partyUnitFrameMap = ns.partyUnitFrameMap or {}
    ClearTable(ns.partyUnitFrameMap)

    if not ns.header then
        return
    end

    local i = 1
    while true do
        local frame = select(i, ns.header:GetChildren())
        if not frame then
            break
        end

        if frame.unit then
            ns.partyUnitFrameMap[frame.unit] = frame
        end

        i = i + 1
    end
end

local function RebuildRaidUnitFrameMap()
    ns.raidUnitFrameMap = ns.raidUnitFrameMap or {}
    ns.raidUnitFrames = ns.raidUnitFrames or {}

    ClearTable(ns.raidUnitFrameMap)
    ClearTable(ns.raidUnitFrames)

    if not ns.raidHeaders then
        return
    end

    for headerIndex = 1, #ns.raidHeaders do
        local header = ns.raidHeaders[headerIndex]
        if header then
            local i = 1
            while true do
                local frame = select(i, header:GetChildren())
                if not frame then
                    break
                end

                if frame.unit then
                    frame.__isRaidFrame = true
                    ns.raidUnitFrameMap[frame.unit] = frame
                    table.insert(ns.raidUnitFrames, frame)
                end

                i = i + 1
            end
        end
    end
end

local function RebuildUnitFrameMaps()
    rebuildMapPending = false
    RebuildPartyUnitFrameMap()
    RebuildRaidUnitFrameMap()
end

local function ScheduleRebuildUnitFrameMap()
    if rebuildMapPending then
        return
    end

    rebuildMapPending = true
    C_Timer.After(0, RebuildUnitFrameMaps)
end

local function IsSupportedUnit(unit)
    if not unit then
        return false
    end

    if unit == "player" then
        return true
    end

    if unit:match("^party%d+$") then
        return true
    end

    if unit:match("^raid%d+$") then
        return true
    end

    return false
end

local function IsPartyUnit(unit)
    if not unit then
        return false
    end

    return unit:match("^party%d+$") ~= nil
end

local function InvalidateUnitAuraCaches(unit)
    if ns.InvalidateUnitAuraState then
        ns:InvalidateUnitAuraState(unit)
    end
end

local function FindFrameByUnit(unit)
    if not unit then
        return nil
    end

    if ns.partyUnitFrameMap then
        local frame = ns.partyUnitFrameMap[unit]
        if frame and frame.unit == unit then
            return frame
        end
    end

    if ns.raidUnitFrameMap then
        local frame = ns.raidUnitFrameMap[unit]
        if frame and frame.unit == unit then
            return frame
        end
    end

    return nil
end

local function UpdateTargetState()
    ns:ForEachUnitFrame(function(frame)
        local isTarget = UnitExists("target") and UnitIsUnit("target", frame.unit) or nil
        if frame.__isTarget ~= isTarget then
            frame.__isTarget = isTarget
            if ns.uf and ns.uf.UpdateBorder then
                ns.uf:UpdateBorder(frame)
            end
        end
    end)
end

local function UpdateSingleFrame(frame)
    if not frame or not frame.unit then
        return
    end

    frame.__isTarget = UnitExists("target") and UnitIsUnit("target", frame.unit) or nil

    if ns.uf and ns.uf.UpdateUnitName then
        ns.uf:UpdateUnitName(frame)
    end

    if ns.uf and ns.uf.UpdateBorder then
        ns.uf:UpdateBorder(frame)
    end

    if ns.uf and ns.uf.UpdateUnitIndicators then
        ns.uf:UpdateUnitIndicators(frame)
    end

    if ns.uf and ns.uf.UpdateCenterDebuff then
        ns.uf:UpdateCenterDebuff(frame)
    end

    if ns.uf and ns.uf.UpdateHealAbsorbOverlay then
        ns.uf:UpdateHealAbsorbOverlay(frame)
    end
    if ns.uf and ns.uf.UpdateStatusIcons then
        ns.uf:UpdateStatusIcons(frame)
    end
end

local function UpdateAuraFrame(frame)
    if not frame or not frame.unit then
        return
    end

    InvalidateUnitAuraCaches(frame.unit)
    frame.__hrIndicatorAuraKey = nil

    if ns.uf and ns.uf.UpdateUnitIndicators then
        ns.uf:UpdateUnitIndicators(frame)
    end

    if ns.uf and ns.uf.UpdateCenterDebuff then
        ns.uf:UpdateCenterDebuff(frame)
    end

    if ns.uf and ns.uf.UpdateHealAbsorbOverlay then
        ns.uf:UpdateHealAbsorbOverlay(frame)
    end
    if ns.uf and ns.uf.UpdateBorder then
        ns.uf:UpdateBorder(frame)
    end
end

local function UpdateNameOnlyFrame(frame)
    if not frame then
        return
    end
    
    if ns.uf and ns.uf.UpdateUnitName then
        ns.uf:UpdateUnitName(frame)
    end
end

local function UpdateConnectionFrame(frame)
    if not frame then
        return
    end

    UpdateNameOnlyFrame(frame)

    --[[if ns.uf and ns.uf.UpdateBorder then
        ns.uf:UpdateBorder(frame)
    end

    if ns.uf and ns.uf.UpdateRange then
        ns.uf:UpdateRange(frame)
    end]]
end

local function RefreshAllConnectionFrames()
    pendingConnectionRefresh = false

    if ns.RebuildUnitFrameMap then
        ns:RebuildUnitFrameMap()
    end

    ns:ForEachUnitFrame(function(frame)
        if frame and frame.unit then
            UpdateConnectionFrame(frame)
        end
    end)
end

function ns:RequestConnectionRefresh()
    if pendingConnectionRefresh then
        return
    end

    pendingConnectionRefresh = true
    C_Timer.After(0.1, RefreshAllConnectionFrames)
end

local function FlushPendingAuraUpdates()
    auraFlushPending = false

    for unit in pairs(pendingAuraUnits) do
        pendingAuraUnits[unit] = nil
        local frame = FindFrameByUnit(unit)
        if frame then
            UpdateAuraFrame(frame)
        end
    end
end

local function QueueAuraUpdate(unit)
    if not unit or not IsSupportedUnit(unit) then
        return
    end

    pendingAuraUnits[unit] = true
    if auraFlushPending then
        return
    end

    auraFlushPending = true
    C_Timer.After(0, FlushPendingAuraUpdates)
end

local function PerformHeaderRefresh()
    headerRefreshPending = false

    if ns.UpdateHeaderLayout then
        ns:UpdateHeaderLayout()
    end

    if ns.UpdateRaidHeaderLayout then
        ns:UpdateRaidHeaderLayout()
    end

    if ns.UpdateAllRangeStates then
        ns:UpdateAllRangeStates()
    end

    if ns.SafeRefresh then
        ns:SafeRefresh()
    end
end

local function RefreshFrameHeadersState()
    if headerRefreshPending then
        return
    end

    headerRefreshPending = true
    C_Timer.After(0, PerformHeaderRefresh)
end

function ns:UpdateUnitFrame(frame)
    UpdateSingleFrame(frame)
end

local function UpdateFrameWorker(frame)
    if frame and frame:IsShown() then
        UpdateSingleFrame(frame)
    end
end

function ns:UpdateAllUnitFrames()
    if (not self.partyUnitFrameMap or not next(self.partyUnitFrameMap))
        or (self.raidHeader and (not self.raidUnitFrameMap or not next(self.raidUnitFrameMap))) then
        RebuildUnitFrameMaps()
    end

    self:ForEachUnitFrame(UpdateFrameWorker)

    if self.RefreshAllRanges then
        self:RefreshAllRanges()
    end
end

function ns:RebuildPartyUnitFrameMap()
    RebuildPartyUnitFrameMap()
end

function ns:RebuildRaidUnitFrameMap()
    RebuildRaidUnitFrameMap()
end

function ns:RebuildUnitFrameMap()
    RebuildUnitFrameMaps()
end

function ns:OnEvent(event, ...)
    local unit, arg2 = ...

    if event == "PLAYER_LOGIN" then
        local cfg = self:GetPartyConfig()
        if cfg and cfg.indicatorSettings then
            cfg.indicatorSettings.filterType = "none"
            cfg.indicatorSettings.selectedSpellID = nil
        end

        local raidCfg = self:GetRaidConfig()
        if raidCfg and raidCfg.indicatorSettings then
            raidCfg.indicatorSettings.filterType = "none"
            raidCfg.indicatorSettings.selectedSpellID = nil
        end

        InvalidateUnitAuraCaches()
        self:SpawnPartyHeader()

        if self.SpawnRaidHeader and self:GetRaidConfig().enabled ~= false then
            self:SpawnRaidHeader()
        end
        SetupBlizzardRaidFrameHooks()
        ScheduleRebuildUnitFrameMap()
        RefreshFrameHeadersState()
        return
    end

    if event == "PLAYER_ENTERING_WORLD"
        or event == "GROUP_ROSTER_UPDATE"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "PARTY_MEMBER_ENABLE"
        or event == "PARTY_MEMBER_DISABLE" then
        SetupBlizzardRaidFrameHooks()
        ClearTable(pendingAuraUnits)
        InvalidateUnitAuraCaches()
        ScheduleRebuildUnitFrameMap()
        RefreshFrameHeadersState()
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if pendingHideBlizzardRaid then
            pendingHideBlizzardRaid = false
            HideBlizzardRaidFrames()
        end

        if self.pendingRefresh then
            self.pendingRefresh = nil
            self:SafeRefresh()
        end

        if self.pendingRaidLayout then
            self.pendingRaidLayout = nil
            if self.UpdateRaidHeaderLayout then
                self:UpdateRaidHeaderLayout()
            end
        end

        return
    end

    if event == "PLAYER_TARGET_CHANGED" then
        UpdateTargetState()
        return
    end

    if event == "PLAYER_ROLES_ASSIGNED"
        or event == "PARTY_LEADER_CHANGED" then
        self:RefreshStatusIcons()
        return
    end

    if event == "READY_CHECK" then
        local readyCheckTimeout = tonumber(arg2) or READY_CHECK_DEFAULT_DURATION
        local state = ns.readyCheckState
        state.active = true
        state.expiresAt = GetTime() + readyCheckTimeout
        state.statuses = state.statuses or {}
        ScheduleReadyCheckRefresh(readyCheckTimeout + 0.05)

        self:RefreshStatusIcons()
        C_Timer.After(READY_CHECK_REFRESH_DELAY, function()
            if ns and ns.RefreshStatusIcons then
                ns:RefreshStatusIcons()
            end
        end)
        return
    end

    if event == "READY_CHECK_CONFIRM" then
        if unit and IsSupportedUnit(unit) then
            SetReadyCheckStatus(unit, ns:NormalizeReadyCheckStatus(arg2))
        end

        if ns.readyCheckState and ns.readyCheckState.active and IsReadyCheckResolvedForAll() then
            FinishReadyCheckState(true)
        end

        if unit and IsSupportedUnit(unit) then
            local frame = FindFrameByUnit(unit)
            if frame and ns.uf and ns.uf.UpdateStatusIcons then
                ns.uf:UpdateStatusIcons(frame)
            end
        end

        QueueReadyCheckRefresh(0.05)
        return
    end

    if event == "READY_CHECK_FINISHED" then
        FinishReadyCheckState(true)

        self:RefreshStatusIcons()
        C_Timer.After(READY_CHECK_REFRESH_DELAY, function()
            if ns and ns.RefreshStatusIcons then
                ns:RefreshStatusIcons()
            end
        end)
        return
    end

    if event == "INCOMING_RESURRECT_CHANGED"
        or event == "INCOMING_SUMMON_CHANGED" then
        if unit and IsSupportedUnit(unit) then
            local frame = FindFrameByUnit(unit)
            if frame and ns.uf and ns.uf.UpdateStatusIcons then
                ns.uf:UpdateStatusIcons(frame)
            end
        else
            self:RefreshStatusIcons()
        end
        return
    end

    if event == "UNIT_AURA" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
        QueueAuraUpdate(unit)
        return
    end

    if event == "UNIT_NAME_UPDATE"
        or event == "UNIT_HEALTH"
        or event == "UNIT_MAXHEALTH"
        or event == "UNIT_DISPLAYPOWER"
        or event == "UNIT_POWER_UPDATE"
        or event == "UNIT_POWER_FREQUENT"
        or event == "UNIT_MAXPOWER" then
        if unit and IsSupportedUnit(unit) then
            local frame = FindFrameByUnit(unit)
            if frame then
                UpdateSingleFrame(frame)
            end
        end
        return
    end

    if event == "UNIT_CONNECTION" then
        if unit and IsSupportedUnit(unit) then
            local frame = FindFrameByUnit(unit)
            if frame then
                UpdateConnectionFrame(frame)
            else
                ns:RequestConnectionRefresh()
            end
        end
        return
    end

    if event == "PLAYER_FLAGS_CHANGED" then
        if unit and IsPartyUnit(unit) then
            local frame = FindFrameByUnit(unit)
            if frame then
                UpdateNameOnlyFrame(frame)
            end
        end
        return
    end
    if event == "RAID_TARGET_UPDATE" then
        self:RefreshStatusIcons()
        return
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    ns:OnEvent(event, ...)
end)

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PARTY_MEMBER_ENABLE")
eventFrame:RegisterEvent("PARTY_MEMBER_DISABLE")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
eventFrame:RegisterEvent("PARTY_LEADER_CHANGED")
eventFrame:RegisterEvent("READY_CHECK")
eventFrame:RegisterEvent("READY_CHECK_CONFIRM")
eventFrame:RegisterEvent("READY_CHECK_FINISHED")
eventFrame:RegisterEvent("INCOMING_RESURRECT_CHANGED")
eventFrame:RegisterEvent("INCOMING_SUMMON_CHANGED")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
eventFrame:RegisterEvent("UNIT_NAME_UPDATE")
eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("UNIT_MAXHEALTH")
eventFrame:RegisterEvent("UNIT_DISPLAYPOWER")
eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
eventFrame:RegisterEvent("UNIT_POWER_FREQUENT")
eventFrame:RegisterEvent("UNIT_MAXPOWER")
eventFrame:RegisterEvent("UNIT_CONNECTION")
eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("RAID_TARGET_UPDATE")
