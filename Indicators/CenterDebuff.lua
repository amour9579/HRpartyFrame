local _, ns = ...

ns.uf = ns.uf or {}

local DEFAULT_SIZE = 36
local DEFAULT_ANCHOR = "CENTER"
local MAX_CENTER_DEBUFFS = 3
local CENTER_DEBUFF_SPACING = 2
local IsSecretValue = issecretvalue or function(...)
    return false
end
local HIDDEN_UTILITY_DEBUFFS = {
    [57723] = true,  -- Exhaustion
    [57724] = true,  -- Sated
    [80354] = true,  -- Temporal Displacement
    [95809] = true,  -- Insanity (hunter pet)
    [160455] = true, -- Fatigued (hunter pet)
    [264689] = true, -- Fatigued (hunter pet)
    [390435] = true, -- Exhaustion
    [382912] = true,
}
local HIDDEN_UTILITY_DEBUFF_NAMES = {
    ["Exhaustion"] = true,
    ["Sated"] = true,
    ["Temporal Displacement"] = true,
    ["Insanity"] = true,
    ["Fatigued"] = true,
    ["피로"] = true,
    ["소진"] = true,
    ["탈진"] = true,
    ["만족함"] = true,
    ["시간 변위"] = true,
}

local function GetHiddenUtilityDebuffs()
    return HIDDEN_UTILITY_DEBUFFS
end

local function IsUtilityDebuffFilterEnabled()
    local cfg = ns:GetPartyConfig()
    local db = cfg and cfg.debuff
    if not db or db.hideUtilityDebuffs == nil then
        return true
    end
    return db.hideUtilityDebuffs == true
end

local function IsHiddenUtilityAura(data)
    if not IsUtilityDebuffFilterEnabled() then
        return false
    end

    local hidden = GetHiddenUtilityDebuffs()
    local sid = data and data.spellId
    if sid and not IsSecretValue(sid) then
        local n = tonumber(sid)
        if (n and hidden[n] == true) or hidden[sid] == true or hidden[tostring(sid)] == true then
            return true
        end
    end

    local auraName = data and data.name
    if auraName and not IsSecretValue(auraName) and HIDDEN_UTILITY_DEBUFF_NAMES[auraName] == true then
        return true
    end

    return false
end

local function GetCenterDebuffDB()
    local cfg = ns:GetPartyConfig()
    return cfg and cfg.debuff
end

local function HideBorder(slot)
    if not (slot and slot.border) then return end
    slot.border.top:Hide()
    slot.border.bottom:Hide()
    slot.border.left:Hide()
    slot.border.right:Hide()
end

local function ShowBorder(slot, r, g, b, a)
    if not (slot and slot.border and r and g and b) then
        HideBorder(slot)
        return
    end
    slot.border.top:SetColorTexture(r, g, b, a or 1)
    slot.border.bottom:SetColorTexture(r, g, b, a or 1)
    slot.border.left:SetColorTexture(r, g, b, a or 1)
    slot.border.right:SetColorTexture(r, g, b, a or 1)
    slot.border.top:Show()
    slot.border.bottom:Show()
    slot.border.left:Show()
    slot.border.right:Show()
end

local function HideSlot(slot)
    if not slot then return end
    if slot.count then slot.count:SetText("") end
    if slot.icon then slot.icon:SetTexture(nil) end
    if slot.cd then slot.cd:Hide() end
    slot.auraInstanceID = nil
    HideBorder(slot)
    slot:Hide()
end

local function HideAllSlots(container)
    if not (container and container.slots) then return end
    for i = 1, #container.slots do
        HideSlot(container.slots[i])
    end
end

local function AlignVisibleSlots(container)
    if not (container and container.slots) then return end

    local shown = {}
    for i = 1, #container.slots do
        if container.slots[i]:IsShown() then
            shown[#shown + 1] = container.slots[i]
        end
    end
    if #shown == 0 then return end

    local size = shown[1]:GetWidth() or DEFAULT_SIZE
    local totalWidth = (#shown * size) + ((#shown - 1) * CENTER_DEBUFF_SPACING)
    local startX = -(totalWidth / 2) + (size / 2)

    for i = 1, #shown do
        local slot = shown[i]
        slot:ClearAllPoints()
        slot:SetPoint("CENTER", container, "CENTER", startX + ((i - 1) * (size + CENTER_DEBUFF_SPACING)), 0)
    end
end

local function ApplyLayout(container, frame, db)
    if not (container and frame and db) then return end

    local size = db.size or DEFAULT_SIZE
    local thickness = tonumber(db.iconBorderThickness) or 2
    local totalWidth = (size * MAX_CENTER_DEBUFFS) + (CENTER_DEBUFF_SPACING * (MAX_CENTER_DEBUFFS - 1))

    container:ClearAllPoints()
    container:SetPoint(db.anchor or DEFAULT_ANCHOR, frame, db.anchor or DEFAULT_ANCHOR, db.x or 0, db.y or 0)
    container:SetSize(totalWidth, size)

    for i = 1, #container.slots do
        local slot = container.slots[i]
        slot:SetSize(size, size)
        if slot.count then
            slot.count:SetFont(STANDARD_TEXT_FONT, math.max(10, math.floor(size * 0.33)), "OUTLINE")
        end

        slot.border.top:ClearAllPoints()
        slot.border.top:SetPoint("TOPLEFT", slot, "TOPLEFT", -thickness, thickness)
        slot.border.top:SetPoint("TOPRIGHT", slot, "TOPRIGHT", thickness, thickness)
        slot.border.top:SetHeight(thickness)

        slot.border.bottom:ClearAllPoints()
        slot.border.bottom:SetPoint("BOTTOMLEFT", slot, "BOTTOMLEFT", -thickness, -thickness)
        slot.border.bottom:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", thickness, -thickness)
        slot.border.bottom:SetHeight(thickness)

        slot.border.left:ClearAllPoints()
        slot.border.left:SetPoint("TOPLEFT", slot, "TOPLEFT", -thickness, thickness)
        slot.border.left:SetPoint("BOTTOMLEFT", slot, "BOTTOMLEFT", -thickness, -thickness)
        slot.border.left:SetWidth(thickness)

        slot.border.right:ClearAllPoints()
        slot.border.right:SetPoint("TOPRIGHT", slot, "TOPRIGHT", thickness, thickness)
        slot.border.right:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", thickness, -thickness)
        slot.border.right:SetWidth(thickness)
    end
end

local function GetAurasByFilter(unit, filter, maxCount)
    maxCount = maxCount or MAX_CENTER_DEBUFFS
    local out = {}

    if C_UnitAuras.GetUnitAuras then
        local auras = C_UnitAuras.GetUnitAuras(unit, filter, maxCount)
        if type(auras) == "table" then
            for i = 1, math.min(#auras, maxCount) do
                local aura = auras[i]
                if aura and aura.auraInstanceID and not IsHiddenUtilityAura(aura) then
                    out[#out + 1] = aura
                end
            end
        end
        return out
    end

    local slots = { C_UnitAuras.GetAuraSlots(unit, filter, 32) }
    for i = 2, #slots do
        local aura = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
        if aura and aura.auraInstanceID and not IsHiddenUtilityAura(aura) then
            out[#out + 1] = aura
            if #out >= maxCount then
                break
            end
        end
    end

    return out
end

function ns.uf:CreateCenterDebuff(frame)
    if frame.CenterDebuff then return frame.CenterDebuff end

    local container = CreateFrame("Frame", nil, frame)
    container:SetFrameLevel(frame:GetFrameLevel() + 20)
    container:SetSize(DEFAULT_SIZE, DEFAULT_SIZE)
    container:SetPoint("CENTER", frame, "CENTER", 0, 0)
    container:Hide()
    container.slots = {}

    for i = 1, MAX_CENTER_DEBUFFS do
        local slot = CreateFrame("Frame", nil, container)
        slot:SetFrameLevel(container:GetFrameLevel())
        slot:SetSize(DEFAULT_SIZE, DEFAULT_SIZE)
        slot:EnableMouse(true)
        slot.border = {}

        slot.border.top = slot:CreateTexture(nil, "OVERLAY")
        slot.border.bottom = slot:CreateTexture(nil, "OVERLAY")
        slot.border.left = slot:CreateTexture(nil, "OVERLAY")
        slot.border.right = slot:CreateTexture(nil, "OVERLAY")
        for _, tex in pairs(slot.border) do
            tex:SetTexture("Interface\\Buttons\\WHITE8x8")
            tex:Hide()
        end

        slot.icon = slot:CreateTexture(nil, "ARTWORK")
        slot.icon:SetAllPoints()
        slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        slot.count = slot:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        slot.count:SetPoint("BOTTOMRIGHT", 2, 0)
        slot.count:SetText("")

        slot.cd = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate")
        slot.cd:SetAllPoints()
        slot.cd:SetReverse(true)
        slot.cd:SetDrawEdge(false)
        slot.cd:SetDrawBling(false)

        slot:SetScript("OnEnter", function(self)
            if not self.auraInstanceID or not frame.unit then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local ok = pcall(function()
                GameTooltip:SetUnitDebuffByAuraInstanceID(frame.unit, self.auraInstanceID)
            end)
            if ok then GameTooltip:Show() else GameTooltip:Hide() end
        end)
        slot:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            if GameTooltip:GetOwner() == self then
                GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
            end
        end)

        slot:Hide()
        container.slots[i] = slot
    end

    frame.CenterDebuff = container
    return container
end

function ns.uf:ApplyCenterDebuffSettings(frame)
    if not frame then return end
    local db = GetCenterDebuffDB()
    if not db then return end

    local container = frame.CenterDebuff or self:CreateCenterDebuff(frame)
    ApplyLayout(container, frame, db)
    if db.enabled == false then
        HideAllSlots(container)
        container:Hide()
    end
end

function ns.uf:UpdateCenterDebuffPreview(frame)
    if not frame or not frame.CenterDebuff then return end
    local db = GetCenterDebuffDB()
    if not db or db.enabled == false or not db.preview then return end

    local container = frame.CenterDebuff
    HideAllSlots(container)
    local slot = container.slots[1]
    if not slot then return end

    slot.icon:SetTexture(136243)
    slot.count:SetText("3")
    slot.cd:Hide()
    if DebuffTypeColor and DebuffTypeColor.Magic then
        local c = DebuffTypeColor.Magic
        ShowBorder(slot, c.r or c[1], c.g or c[2], c.b or c[3], c.a or c[4] or 1)
    else
        ShowBorder(slot, 0.2, 0.6, 1, 1)
    end
    slot:Show()
    AlignVisibleSlots(container)
    container:Show()
end

function ns.uf:UpdateCenterDebuff(frame)
    local container = frame and frame.CenterDebuff
    if not container then return end

    HideAllSlots(container)

    local cfg = GetCenterDebuffDB() or {}
    if cfg.enabled == false then
        container:Hide()
        return
    end

    ApplyLayout(container, frame, cfg)
    if cfg.preview then
        self:UpdateCenterDebuffPreview(frame)
        return
    end
    if not frame.unit or not UnitExists(frame.unit) then
        container:Hide()
        return
    end

    local mode = cfg.displayMode
    if mode ~= "dispellableOnly" and mode ~= "all" then
        mode = "all"
    end
    local auras
    if mode == "dispellableOnly" then
        auras = GetAurasByFilter(frame.unit, "HARMFUL|RAID_PLAYER_DISPELLABLE", MAX_CENTER_DEBUFFS)
    else
        auras = GetAurasByFilter(frame.unit, "HARMFUL", MAX_CENTER_DEBUFFS)
    end

    if not auras or #auras == 0 then
        container:Hide()
        return
    end

    local shown = 0
    for i = 1, MAX_CENTER_DEBUFFS do
        local aura = auras[i]
        local slot = container.slots[i]
        if aura and slot and aura.auraInstanceID then
            slot.icon:SetTexture(aura.icon or 136243)
            slot.auraInstanceID = aura.auraInstanceID
            ShowBorder(slot, ns:GetAuraDispelColor(frame.unit, aura.auraInstanceID))

            local countText = C_UnitAuras.GetAuraApplicationDisplayCount(frame.unit, aura.auraInstanceID, 2, 999)
            slot.count:SetText(countText or "")

            local durationInfo = C_UnitAuras.GetAuraDuration(frame.unit, aura.auraInstanceID)
            if durationInfo then
                slot.cd:SetCooldownFromDurationObject(durationInfo)
                slot.cd:Show()
            else
                slot.cd:Hide()
            end

            slot:Show()
            shown = shown + 1
        end
    end

    if shown > 0 then
        AlignVisibleSlots(container)
        container:Show()
    else
        container:Hide()
    end
end
