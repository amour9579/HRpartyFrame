local _, ns = ...

ns.uf = ns.uf or {}

local rangeElapsed = 0

local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit
local UnitIsConnected = UnitIsConnected
local UnitIsPlayer = UnitIsPlayer
local UnitInPhase = UnitInPhase
local CheckInteractDistance = CheckInteractDistance
local InCombatLockdown = InCombatLockdown
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local IsInInstance = IsInInstance
local UnitPhaseReason = UnitPhaseReason

local PhaseReason = Enum and Enum.PhaseReason

local function IsRangeEnabledForFrame(frame)
    if not frame then
        return false
    end

    local cfg = ns:GetUnitFrameConfig(frame)
    if not cfg or not cfg.rangeCheck then
        return false
    end

    if frame.__isRaidFrame then
        return IsInRaid()
    end

    if not IsInGroup() then
        return false
    end

    if IsInRaid() then
        return false
    end

    return true
end

local function IsUnitPhasedOut(unit)
    if not unit or not UnitExists(unit) then
        return false
    end

    if not UnitIsPlayer(unit) then
        return false
    end

    if UnitPhaseReason and PhaseReason then
        local reason = UnitPhaseReason(unit)

        if reason == PhaseReason.TimerunningHwt then
            if not IsInInstance or not IsInInstance() then
                return true
            end
        elseif reason then
            return true
        end

        return false
    end

    if UnitInPhase then
        return not UnitInPhase(unit)
    end

    return false
end

local function IsUnitInConfiguredRangeByThreshold(unit, threshold)
    if not unit or not UnitExists(unit) then
        return true
    end

    if not ns.RangeCheck or not ns.RangeCheck.GetRange then
        return true
    end

    local minRange, maxRange = ns.RangeCheck:GetRange(unit)

    if not minRange and not maxRange then
        return true
    end

    if minRange and minRange > threshold then
        return false
    end

    if maxRange and maxRange <= threshold then
        return true
    end

    return true
end

local function IsUnitActuallyInRange(frame, threshold)
    if not frame or not frame.unit or not UnitExists(frame.unit) then
        return true
    end

    local unit = frame.unit

    if UnitIsUnit(unit, "player") then
        return true
    end

    if IsUnitPhasedOut(unit) then
        return false
    end

    if not UnitIsConnected(unit) then
        return false
    end

    -- 보호 함수라 비전투에서만 보조 판정
    if not InCombatLockdown() and CheckInteractDistance then
        if threshold <= 10 then
            if CheckInteractDistance(unit, 3) then
                return true
            end
        elseif threshold <= 28 then
            if CheckInteractDistance(unit, 4) then
                return true
            end
        elseif threshold > 28 then
            if CheckInteractDistance(unit, 4) then
                return true
            end
        end
    end

    return IsUnitInConfiguredRangeByThreshold(unit, threshold)
end

local function ApplyFrameAlpha(frame, alpha)
    if not frame then
        return
    end

    if frame.__hrRangeAlpha ~= alpha then
        frame:SetAlpha(alpha)
        frame.__hrRangeAlpha = alpha
    end
end

function ns.uf:UpdateRange(frame)
    if not frame then
        return
    end

    if not IsRangeEnabledForFrame(frame) then
        ApplyFrameAlpha(frame, 1)
        return
    end

    if not frame.unit or not UnitExists(frame.unit) then
        ApplyFrameAlpha(frame, 1)
        return
    end

    local cfg = ns:GetPartyConfig(frame)
    local threshold = cfg.rangeThreshold or 40
    local alpha = (cfg.outOfRangeAlpha or 20) / 100
    local targetAlpha = 1

    if not IsUnitActuallyInRange(frame, threshold) then
        targetAlpha = alpha
    end

    ApplyFrameAlpha(frame, targetAlpha)
end
function ns:RangeOnUpdate(elapsed)
    local partyCfg = self:GetPartyConfig()
    local raidCfg = self:GetRaidConfig()

    local partyFreq = (partyCfg and partyCfg.rangeFrequency) or 0.2
    local raidFreq = (raidCfg and raidCfg.rangeFrequency) or 0.25
    local frequency = math.min(partyFreq, raidFreq)

    rangeElapsed = rangeElapsed + elapsed
    if rangeElapsed < frequency then
        return
    end
    rangeElapsed = 0

    self:RefreshAllRanges()
end

function ns:RefreshAllRanges()
    self:ForEachUnitFrame(function(frame)
        if frame and frame.unit then
            if frame:IsShown() then
                self.uf:UpdateRange(frame)
            else
                ApplyFrameAlpha(frame, 1)
            end
        end
    end)
end

function ns:UpdateAllRangeStates()
    local enabled = false

    self:ForEachUnitFrame(function(frame)
        if IsRangeEnabledForFrame(frame) then
            enabled = true
        end
    end)

    if enabled then
        if not self.rangeUpdaterFrame then
            local updater = CreateFrame("Frame")
            updater:SetScript("OnUpdate", function(_, elapsed)
                ns:RangeOnUpdate(elapsed)
            end)
            self.rangeUpdaterFrame = updater
        end

        self.rangeUpdaterFrame:Show()
    else
        if self.rangeUpdaterFrame then
            self.rangeUpdaterFrame:Hide()
        end
    end

    self:RefreshAllRanges()
end
