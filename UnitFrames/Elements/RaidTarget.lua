local _, ns = ...

ns.uf = ns.uf or {}

function ns.uf:CreateRaidTargetIndicator(frame)
    if not frame or frame.HRRaidTargetIndicatorFrame then
        return
    end

    local holder = CreateFrame("Frame", nil, frame)
    holder:SetFrameStrata(frame:GetFrameStrata())
    holder:SetFrameLevel(frame:GetFrameLevel() + 40)
    holder:SetSize(18, 18)
    holder:Hide()

    local icon = holder:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints()
    icon:SetAlpha(1)

    frame.HRRaidTargetIndicatorFrame = holder
    frame.HRRaidTargetIndicator = icon
    frame.RaidTargetIndicator = icon
end

function ns.uf:ApplyRaidTargetSettings(frame)
    if not frame or not frame.HRRaidTargetIndicatorFrame or not frame.HRRaidTargetIndicator then
        return
    end

    local cfg = ns:GetUnitFrameConfig(frame)
    local opts = cfg and cfg.raidTarget

    local holder = frame.HRRaidTargetIndicatorFrame
    local icon = frame.HRRaidTargetIndicator
    if not opts or opts.enabled == false then
        holder:Hide()
        frame.RaidTargetIndicator = nil
        return
    end

    frame.RaidTargetIndicator = icon

    local anchor = opts.anchor or "TOP"
    local x = opts.x or 0
    local y = opts.y or 10
    local size = opts.size or 18

    holder:ClearAllPoints()
    holder:SetPoint(anchor, frame, anchor, x, y)
    holder:SetSize(size, size)
    holder:SetFrameLevel(frame:GetFrameLevel() + 40)
    holder:Show()
end
