local _, ns = ...

ns.uf = ns.uf or {}

local BAR_TEXTURE = "Interface\\RaidFrame\\Shield-Fill"
local BG_TEXTURE = "Interface\\Buttons\\WHITE8x8"

local function EnsureCalculator(frame)
    if frame.__hrHealAbsorbCalc then
        return frame.__hrHealAbsorbCalc
    end

    if not CreateUnitHealPredictionCalculator then
        return nil
    end

    local calc = CreateUnitHealPredictionCalculator()
    if not calc then
        return nil
    end

    if calc.SetToDefaults then
        calc:SetToDefaults()
    end

    if calc.SetHealAbsorbMode and Enum and Enum.UnitHealAbsorbMode and Enum.UnitHealAbsorbMode.Total then
        calc:SetHealAbsorbMode(Enum.UnitHealAbsorbMode.Total)
    end

    frame.__hrHealAbsorbCalc = calc
    return calc
end

local function GetAttachedHealAbsorb(frame)
    print("healAbsorb =", healAbsorb)
    if not frame or not frame.unit or not UnitExists(frame.unit) then
        return nil
    end

    if UnitIsDeadOrGhost(frame.unit) then
        return 0
    end

    local calc = EnsureCalculator(frame)
    if not calc or not UnitGetDetailedHealPrediction then
        return nil
    end

    if calc.Reset then
        calc:Reset()
    elseif calc.SetToDefaults then
        calc:SetToDefaults()
    end

    if calc.SetHealAbsorbMode and Enum and Enum.UnitHealAbsorbMode and Enum.UnitHealAbsorbMode.Total then
        calc:SetHealAbsorbMode(Enum.UnitHealAbsorbMode.Total)
    end

    UnitGetDetailedHealPrediction(frame.unit, nil, calc)

    if calc.HasSecretValues and calc:HasSecretValues() then
        return nil
    end
    if calc.GetTotalHealAbsorbs then
        return calc:GetTotalHealAbsorbs() or 0
    end

    return nil
end

local function GetHealthValues(frame)
    if not frame or not frame.unit or not UnitExists(frame.unit) then
        return nil, nil
    end

    local health = UnitHealth(frame.unit)
    local maxHealth = UnitHealthMax(frame.unit)

    if issecretvalue and (issecretvalue(health) or issecretvalue(maxHealth)) then
        return nil, nil
    end

    health = tonumber(health)
    maxHealth = tonumber(maxHealth)

    if not health or not maxHealth or maxHealth <= 0 then
        return nil, nil
    end

    return health, maxHealth
end

function ns.uf:CreateHealAbsorbOverlay(frame)
    if not frame or not frame.Health or frame.HealthHealAbsorbBar then
        return
    end

    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetFrameLevel(frame.Health:GetFrameLevel() + 20)
    bar:SetStatusBarTexture(BAR_TEXTURE)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:Hide()

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(BG_TEXTURE)
    bg:SetVertexColor(0.10, 0.45, 0.65, 0.20)
    bar.bg = bg

    local border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    border:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({
        edgeFile = BG_TEXTURE,
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0.10, 0.75, 1.00, 0.90)
    bar.border = border

    frame.HealthHealAbsorbBar = bar
end

function ns.uf:UpdateHealAbsorbOverlay(frame)
    if not frame or not frame.Health or not frame.HealthHealAbsorbBar then
        return
    end

    local bar = frame.HealthHealAbsorbBar

    if not frame.unit or not UnitExists(frame.unit) or UnitIsDeadOrGhost(frame.unit) then
        bar:Hide()
        return
    end

    local health, maxHealth = GetHealthValues(frame)
    if not health or not maxHealth then
        bar:Hide()
        return
    end

    local healAbsorb = GetAttachedHealAbsorb(frame)
    if not healAbsorb then
        bar:Hide()
        return
    end

    if issecretvalue and issecretvalue(healAbsorb) then
        bar:Hide()
        return
    end

    healAbsorb = tonumber(healAbsorb) or 0
    if healAbsorb <= 0 then
        bar:Hide()
        return
    end

    local missingHealth = maxHealth - health
    if missingHealth < 0 then
        missingHealth = 0
    end

    local attachedHealAbsorb = healAbsorb
    if attachedHealAbsorb > missingHealth then
        attachedHealAbsorb = missingHealth
    end

    if attachedHealAbsorb <= 0 then
        bar:Hide()
        return
    end

    local healthBar = frame.Health
    local healthWidth = healthBar:GetWidth()
    local healthHeight = healthBar:GetHeight()

    if not healthWidth or healthWidth <= 0 or not healthHeight or healthHeight <= 0 then
        bar:Hide()
        return
    end

    local absorbWidth = math.floor((attachedHealAbsorb / maxHealth) * healthWidth + 0.5)
    if absorbWidth <= 0 then
        bar:Hide()
        return
    end

    local currentHealthWidth = math.floor((health / maxHealth) * healthWidth + 0.5)
    local rightEdgeOffset = healthWidth - currentHealthWidth

    --[[bar:ClearAllPoints()
    bar:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", -rightEdgeOffset, 0)
    bar:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", -rightEdgeOffset, 0)
    bar:SetWidth(absorbWidth)
    bar:SetMinMaxValues(0, maxHealth)
    bar:SetValue(attachedHealAbsorb)
    bar:Show()]]

    bar:ClearAllPoints()
    bar:SetAllPoints(healthBar)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    bar:GetStatusBarTexture():SetVertexColor(1, 0, 0, 0.6)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar:Show()
end
