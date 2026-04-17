local _, ns = ...

ns.uf = ns.uf or {}

local function EnsureHealPredictionCalculator(frame)
    if frame.__hrHealPredictionCalculator then
        return frame.__hrHealPredictionCalculator
    end

    if not CreateUnitHealPredictionCalculator then
        return nil
    end

    local calc = CreateUnitHealPredictionCalculator()
    if not calc then
        return nil
    end

    -- 기본 설정으로 초기화
    if calc.SetToDefaults then
        calc:SetToDefaults()
    end

    -- heal absorb를 있는 그대로 보도록 설정
    if calc.SetHealAbsorbMode and Enum and Enum.UnitHealAbsorbMode and Enum.UnitHealAbsorbMode.Total then
        calc:SetHealAbsorbMode(Enum.UnitHealAbsorbMode.Total)
    end

    -- 최대 체력 기준으로 clamp
    if calc.SetHealAbsorbClampMode and Enum and Enum.UnitHealAbsorbClampMode and Enum.UnitHealAbsorbClampMode.MaximumHealth then
        calc:SetHealAbsorbClampMode(Enum.UnitHealAbsorbClampMode.MaximumHealth)
    end

    frame.__hrHealPredictionCalculator = calc
    return calc
end

local function GetHealAbsorbAmount(frame)
    if not frame or not frame.unit or not UnitExists(frame.unit) then
        return 0
    end

    if UnitIsDeadOrGhost(frame.unit) then
        return 0
    end

    local calc = EnsureHealPredictionCalculator(frame)
    if not calc or not UnitGetDetailedHealPrediction then
        return 0
    end

    if calc.Reset then
        calc:Reset()
    elseif calc.SetToDefaults then
        calc:SetToDefaults()
    end

    if calc.SetHealAbsorbMode and Enum and Enum.UnitHealAbsorbMode and Enum.UnitHealAbsorbMode.Total then
        calc:SetHealAbsorbMode(Enum.UnitHealAbsorbMode.Total)
    end

    if calc.SetHealAbsorbClampMode and Enum and Enum.UnitHealAbsorbClampMode and Enum.UnitHealAbsorbClampMode.MaximumHealth then
        calc:SetHealAbsorbClampMode(Enum.UnitHealAbsorbClampMode.MaximumHealth)
    end

    UnitGetDetailedHealPrediction(frame.unit, nil, calc)

    if calc.GetTotalHealAbsorbs then
        return calc:GetTotalHealAbsorbs() or 0
    end

    if calc.GetHealAbsorbs then
        local amount = calc:GetHealAbsorbs()
        return amount or 0
    end

    return 0
end

function ns.uf:CreateHealAbsorbOverlay(frame)
    if not frame or not frame.Health or frame.HealthHealAbsorb then
        return
    end

    local overlay = frame.Health:CreateTexture(nil, "OVERLAY")
    overlay:SetTexture("Interface\\Buttons\\WHITE8x8")
    overlay:SetAllPoints(frame.Health)
    overlay:SetVertexColor(0.10, 0.10, 0.10, 0.45)
    overlay:Hide()

    frame.HealthHealAbsorb = overlay
end

function ns.uf:UpdateHealAbsorbOverlay(frame)
    if not frame or not frame.Health or not frame.HealthHealAbsorb then
        return
    end

    local overlay = frame.HealthHealAbsorb

    if not frame.unit or not UnitExists(frame.unit) or UnitIsDeadOrGhost(frame.unit) then
        overlay:Hide()
        return
    end

    local healAbsorb = GetHealAbsorbAmount(frame)

    -- 12.0.x secret value 방어
    if issecretvalue and issecretvalue(healAbsorb) then
        -- secret이면 직접 비교하지 않고 안전하게 숨김
        -- 필요하면 여기서 항상 Show()로 바꿀 수 있지만, 우선 오작동 방지를 위해 숨김 처리
        overlay:Hide()
        return
    end

    if not healAbsorb or healAbsorb <= 0 then
        overlay:Hide()
        return
    end

    overlay:Show()
end
