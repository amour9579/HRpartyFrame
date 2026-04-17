local _, ns = ...

ns.uf = ns.uf or {}
ns.dispellableDebuffState = ns.dispellableDebuffState or {}
local dispelColorCurve

local function NormalizeColor(color)
    if type(color) ~= "table" then
        return nil
    end

    if color.GetRGBA then
        local r, g, b, a = color:GetRGBA()
        if r and g and b then
            return r, g, b, a or 1
        end
    end

    local r = color.r or color[1]
    local g = color.g or color[2]
    local b = color.b or color[3]
    local a = color.a or color[4] or 1
    if r and g and b then
        return r, g, b, a
    end

    return nil
end

local function EnsureDispelColorCurve()
    if dispelColorCurve then
        return dispelColorCurve
    end

    if not (C_CurveUtil and C_CurveUtil.CreateColorCurve) then
        return nil
    end

    local curve = C_CurveUtil.CreateColorCurve()
    if not curve then
        return nil
    end

    if Enum and Enum.LuaCurveType and curve.SetType then
        curve:SetType(Enum.LuaCurveType.Step)
    end

    if curve.AddPoint then
        if DEBUFF_TYPE_NONE_COLOR then
            curve:AddPoint(0, DEBUFF_TYPE_NONE_COLOR)
        end
        if DEBUFF_TYPE_MAGIC_COLOR then
            curve:AddPoint(1, DEBUFF_TYPE_MAGIC_COLOR)
        end
        if DEBUFF_TYPE_CURSE_COLOR then
            curve:AddPoint(2, DEBUFF_TYPE_CURSE_COLOR)
        end
        if DEBUFF_TYPE_DISEASE_COLOR then
            curve:AddPoint(3, DEBUFF_TYPE_DISEASE_COLOR)
        end
        if DEBUFF_TYPE_POISON_COLOR then
            curve:AddPoint(4, DEBUFF_TYPE_POISON_COLOR)
        end
        if DEBUFF_TYPE_BLEED_COLOR then
            curve:AddPoint(9, DEBUFF_TYPE_BLEED_COLOR)  -- Enrage
            curve:AddPoint(11, DEBUFF_TYPE_BLEED_COLOR) -- Bleed
        end
    end

    dispelColorCurve = curve
    return dispelColorCurve
end

local function GetFirstDispellableAura(unit)
    local slots = { C_UnitAuras.GetAuraSlots(unit, "HARMFUL|RAID_PLAYER_DISPELLABLE", 32) }
    for i = 2, #slots do
        local aura = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
        if aura and aura.auraInstanceID then
            return aura
        end
    end

    -- Some client/build combinations do not fully support RAID_PLAYER_DISPELLABLE.
    slots = { C_UnitAuras.GetAuraSlots(unit, "HARMFUL|RAID", 32) }
    for i = 2, #slots do
        local aura = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
        if aura and aura.auraInstanceID then
            return aura
        end
    end

    return nil
end

local function SetBorderColor(frame, r, g, b, a)
    if not frame or not frame.Border then
        return
    end

    frame.Border:SetBackdropBorderColor(r, g, b, a)
end

local function ApplyBorderThickness(frame)
    if not frame or not frame.Border then
        return
    end

    local cfg = ns:GetUnitFrameConfig(frame)
    local debuffCfg = cfg and cfg.debuff or nil
    local thickness = tonumber(debuffCfg and debuffCfg.frameBorderThickness) or 1
    local inset = thickness + 1

    if frame.__hrBorderThickness == thickness then
        return
    end

    frame.Border:SetPoint("TOPLEFT", frame, "TOPLEFT", -inset, inset)
    frame.Border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", inset, -inset)
    frame.Border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = thickness,
    })
    frame.__hrBorderThickness = thickness
end

function ns:InvalidateUnitAuraState(unit)
    self.dispellableDebuffState = self.dispellableDebuffState or {}

    if unit then
        self.dispellableDebuffState[unit] = nil
        return
    end

    for key in pairs(self.dispellableDebuffState) do
        self.dispellableDebuffState[key] = nil
    end
end

function ns:HasDispellableDebuff(unit)
    if not unit then
        return false
    end

    self.dispellableDebuffState = self.dispellableDebuffState or {}

    local cached = self.dispellableDebuffState[unit]
    if cached ~= nil then
        return cached.hasDebuff == true
    end

    local aura = GetFirstDispellableAura(unit)
    local state = { hasDebuff = false }
    if aura and aura.auraInstanceID then
        state.hasDebuff = true
        state.auraInstanceID = aura.auraInstanceID
    end

    self.dispellableDebuffState[unit] = state
    return state.hasDebuff
end

function ns:GetDispellableDebuffColor(unit)
    if not unit then
        return nil
    end

    self.dispellableDebuffState = self.dispellableDebuffState or {}
    local cached = self.dispellableDebuffState[unit]
    if cached == nil then
        self:HasDispellableDebuff(unit)
        cached = self.dispellableDebuffState[unit]
    end

    if not cached or not cached.hasDebuff or not cached.auraInstanceID then
        return nil
    end

    return self:GetAuraDispelColor(unit, cached.auraInstanceID)
end

function ns:GetAuraDispelColor(unit, auraInstanceID)
    if not unit or not auraInstanceID then
        return nil
    end

    if C_UnitAuras.GetAuraDispelTypeColor then
        local color = C_UnitAuras.GetAuraDispelTypeColor(unit, auraInstanceID, EnsureDispelColorCurve())
        local r, g, b, a = NormalizeColor(color)
        if r and g and b then
            return r, g, b, a
        end
    end

    return nil
end

function ns.uf:CreateBorder(frame)
    if frame.Border then
        return
    end

    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0, 0, 0, 0.15)

    frame.Border = border
    frame.__hrBorderThickness = nil
    ApplyBorderThickness(frame)
end

function ns.uf:UpdateBorder(frame)
    if not frame or not frame.Border then
        return
    end

    if not frame.unit or not UnitExists(frame.unit) then
        ApplyBorderThickness(frame)
        SetBorderColor(frame, 0, 0, 0, 0.15)
        return
    end

    local threat = UnitThreatSituation(frame.unit)
    ApplyBorderThickness(frame)

    local dr, dg, db, da = ns:GetDispellableDebuffColor(frame.unit)
    if dr then
        SetBorderColor(frame, dr, dg, db, da)
    elseif threat and threat >= 2 and UnitGroupRolesAssigned(frame.unit) ~= "TANK" then
        SetBorderColor(frame, 1, 0.2, 0.2, 1)
    elseif frame.__isHover then
        SetBorderColor(frame, 1, 1, 1, 0.8)
    elseif frame.__isTarget then
        SetBorderColor(frame, 0, 0, 0.25, 0.8)
    else
        SetBorderColor(frame, 0, 0, 0, 0.15)
    end
end
