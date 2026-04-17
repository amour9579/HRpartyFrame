local _, ns = ...

ns.uf = ns.uf or {}

local function GetHealAbsorbAmount(unit)
    if not unit or not UnitExists(unit) then
        return 0
    end

    if UnitIsDeadOrGhost(unit) then
        return 0
    end

    if UnitGetTotalHealAbsorbs then
        return UnitGetTotalHealAbsorbs(unit) or 0
    end

    return 0
end

function ns.uf:CreateHealAbsorbOverlay(frame)
    if not frame or not frame.Health or frame.HealthHealAbsorb then
        return
    end

    local overlay = frame.Health:CreateTexture(nil, "OVERLAY")
    overlay:SetTexture("Interface\\Buttons\\WHITE8x8")
    overlay:SetVertexColor(0.05, 0.05, 0.05, 0.65)
    overlay:SetPoint("TOPRIGHT", frame.Health, "TOPRIGHT", 0, 0)
    overlay:SetPoint("BOTTOMRIGHT", frame.Health, "BOTTOMRIGHT", 0, 0)
    overlay:SetWidth(0)
    overlay:Hide()

    frame.HealthHealAbsorb = overlay
end

function ns.uf:UpdateHealAbsorbOverlay(frame)
    if not frame or not frame.Health or not frame.HealthHealAbsorb or not frame.unit then
        return
    end

    local overlay = frame.HealthHealAbsorb

    if not UnitExists(frame.unit) then
        overlay:Hide()
        return
    end

    local maxHealth = UnitHealthMax(frame.unit) or 0
    if maxHealth <= 0 then
        overlay:Hide()
        return
    end

    local healAbsorb = GetHealAbsorbAmount(frame.unit)
    if healAbsorb <= 0 then
        overlay:Hide()
        return
    end

    local barWidth = frame.Health:GetWidth() or frame:GetWidth() or 0
    if barWidth <= 0 then
        overlay:Hide()
        return
    end

    local ratio = healAbsorb / maxHealth
    if ratio > 1 then
        ratio = 1
    elseif ratio < 0 then
        ratio = 0
    end

    local width = barWidth * ratio
    if width < 1 then
        overlay:Hide()
        return
    end

    overlay:ClearAllPoints()
    overlay:SetPoint("TOPRIGHT", frame.Health, "TOPRIGHT", 0, 0)
    overlay:SetPoint("BOTTOMRIGHT", frame.Health, "BOTTOMRIGHT", 0, 0)
    overlay:SetWidth(width)
    overlay:Show()
end
