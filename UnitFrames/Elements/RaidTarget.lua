local _, ns = ...

ns.uf = ns.uf or {}

function ns.uf:CreateRaidTargetIndicator(frame)
    if not frame or frame.HRRaidTargetIndicator then
        return
    end

    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetSize(18, 18)
    icon:SetPoint("TOP", frame, "TOP", 0, 10)
    icon:SetDrawLayer("OVERLAY", 7)
    icon:Hide()

    frame.HRRaidTargetIndicator = icon
    frame.RaidTargetIndicator = icon
end

function ns.uf:ApplyRaidTargetSettings(frame)
    if not frame or not frame.HRRaidTargetIndicator then
        return
    end

    local cfg = ns:GetUnitFrameConfig(frame)
    local opts = cfg and cfg.raidTarget

    if not opts or opts.enabled == false then
        frame.HRRaidTargetIndicator:Hide()
        frame.RaidTargetIndicator = nil
        return
    end

    frame.RaidTargetIndicator = frame.HRRaidTargetIndicator

    local anchor = opts.anchor or "TOP"
    local x = opts.x or 0
    local y = opts.y or 10
    local size = opts.size or 18

    local icon = frame.HRRaidTargetIndicator
    icon:ClearAllPoints()
    icon:SetPoint(anchor, frame, anchor, x, y)
    icon:SetSize(size, size)
    icon:Show()
end
