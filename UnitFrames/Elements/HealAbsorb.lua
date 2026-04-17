local _, ns = ...

ns.uf = ns.uf or {}

local BAR_TEXTURE = "Interface\\RaidFrame\\Shield-Fill"
local BG_TEXTURE = "Interface\\Buttons\\WHITE8x8"

function ns.uf:CreateHealAbsorbOverlay(frame)
    if not frame or not frame.Health or frame.HealthHealAbsorbBar then
        return
    end

    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetParent(frame)
    bar:SetFrameStrata(frame:GetFrameStrata())
    bar:SetFrameLevel(frame.Health:GetFrameLevel() + 12)
    bar:SetStatusBarTexture(BAR_TEXTURE)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:EnableMouse(false)
    bar:Hide()

    local tex = bar:GetStatusBarTexture()
    if tex then
        tex:SetDrawLayer("ARTWORK", 1)
        tex:SetHorizTile(false)
        tex:SetVertTile(false)
        tex:SetTexCoord(0, 1, 0, 1)
        tex:SetVertexColor(0.85, 0.15, 0.15, 0.70)
    end
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(BG_TEXTURE)
    bg:SetVertexColor(0, 0, 0, 0.35)
    bar.bg = bg

    frame.HealthHealAbsorbBar = bar
end

function ns.uf:UpdateHealAbsorbOverlay(frame)
    if not frame or not frame.Health or not frame.HealthHealAbsorbBar then
        return
    end

    local bar = frame.HealthHealAbsorbBar
    local unit = frame.unit

    if not unit or not UnitExists(unit) or UnitIsDeadOrGhost(unit) then
        bar:Hide()
        return
    end

    if not UnitHealthMax or not UnitGetTotalHealAbsorbs then
        bar:Hide()
        return
    end

    local maxHealth = UnitHealthMax(unit)
    local healAbsorb = UnitGetTotalHealAbsorbs(unit)

    if maxHealth == nil or healAbsorb == nil then
        bar:Hide()
        return
    end

    local healthBar = frame.Health
    bar:ClearAllPoints()
    bar:SetAllPoints(healthBar)

    local okMinMax = pcall(bar.SetMinMaxValues, bar, 0, maxHealth)
    local okValue = pcall(bar.SetValue, bar, healAbsorb)

    if not okMinMax or not okValue then
        bar:Hide()
        return
    end

    bar:Show()
end
