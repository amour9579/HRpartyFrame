local _, ns = ...

ns.uf = ns.uf or {}

local pairs = pairs

local function RefreshNameWorker(frame)
    if ns.uf and ns.uf.UpdateUnitName then
        ns.uf:UpdateUnitName(frame)
    end
end

local function RefreshBorderWorker(frame)
    if ns.uf and ns.uf.UpdateBorder then
        ns.uf:UpdateBorder(frame)
    elseif ns.UpdateBorder then
        ns:UpdateBorder(frame)
    end
end

local function RefreshIndicatorWorker(frame)
    frame.__indicatorsInitialized = nil
    frame.__indicatorLayoutKey = nil
    frame.__hrIndicatorAuraKey = nil

    if ns.uf and ns.uf.ApplyIndicatorSettings then
        ns.uf:ApplyIndicatorSettings(frame, true)
    end

    if ns.uf and ns.uf.UpdateUnitIndicators then
        ns.uf:UpdateUnitIndicators(frame)
    end
end

local function RefreshCenterDebuffWorker(frame)
    if ns.uf and ns.uf.ApplyCenterDebuffSettings then
        ns.uf:ApplyCenterDebuffSettings(frame)
    end

    if ns.uf and ns.uf.UpdateCenterDebuff then
        ns.uf:UpdateCenterDebuff(frame)
    end
end

local function RefreshStatusIconWorker(frame)
    if ns.uf and ns.uf.ApplyStatusIconSettings then
        ns.uf:ApplyStatusIconSettings(frame)
    end

    if ns.uf and ns.uf.UpdateStatusIcons then
        ns.uf:UpdateStatusIcons(frame)
    end
end

local function RefreshRaidTargetWorker(frame)
    if ns.uf and ns.uf.ApplyRaidTargetSettings then
        ns.uf:ApplyRaidTargetSettings(frame)
    end
end
local function RefreshPowerWorker(frame)
    if ns.uf and ns.uf.ApplyPowerSettings then
        ns.uf:ApplyPowerSettings(frame)
    end
end

function ns:ForEachPartyUnitFrame(callback)
    if not callback then
        return
    end

    local map = self.partyUnitFrameMap
    if type(map) ~= "table" then
        return
    end

    for unit, frame in pairs(map) do
        if frame and frame.unit == unit then
            callback(frame, unit)
        end
    end
end

function ns:ForEachRaidUnitFrame(callback)
    if not callback then
        return
    end

    local map = self.raidUnitFrameMap
    if type(map) ~= "table" then
        return
    end

    for unit, frame in pairs(map) do
        if frame and frame.unit == unit then
            callback(frame, unit)
        end
    end
end

function ns:ForEachUnitFrame(callback)
    self:ForEachPartyUnitFrame(callback)
    self:ForEachRaidUnitFrame(callback)
end

function ns:RefreshNames()
    if not (self.uf and self.uf.UpdateUnitName) then
        return
    end

    self:ForEachUnitFrame(RefreshNameWorker)
end

function ns:RefreshBorders()
    self:ForEachUnitFrame(RefreshBorderWorker)
end

function ns:RefreshIndicators()
    self:ForEachUnitFrame(RefreshIndicatorWorker)
end

function ns:RefreshCenterDebuff()
    self:ForEachUnitFrame(RefreshCenterDebuffWorker)
end

function ns:RefreshStatusIcons()
    self:ForEachUnitFrame(RefreshStatusIconWorker)
end

function ns:RefreshRaidTargets()
    self:ForEachUnitFrame(RefreshRaidTargetWorker)
end
function ns:RefreshPower()
    self:ForEachUnitFrame(RefreshPowerWorker)
end

function ns:RefreshAllUnitFrames()
    self:RefreshPower()
    self:RefreshNames()
    self:RefreshBorders()
    self:RefreshIndicators()
    self:RefreshCenterDebuff()
    self:RefreshStatusIcons()
    self:RefreshRaidTargets()

    if self.RefreshAllRanges then
        self:RefreshAllRanges()
    end
end

function ns:SafeRefresh()
    if InCombatLockdown() then
        self.pendingRefresh = true
        return
    end

    if self.UpdateHeaderLayout then
        self:UpdateHeaderLayout()
    end

    if self.UpdateRaidHeaderLayout then
        self:UpdateRaidHeaderLayout()
    end

    self:RefreshAllUnitFrames()
end

function ns:RequestRefresh()
    self:SafeRefresh()
end
