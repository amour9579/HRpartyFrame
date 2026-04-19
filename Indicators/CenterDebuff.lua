local _, ns = ...

ns.uf = ns.uf or {}

local DEFAULT_SIZE = 36
local DEFAULT_ANCHOR = "CENTER"
local MAX_CENTER_DEBUFFS = 5
local CENTER_DEBUFF_SPACING = 2

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

-- 필요 시 spellID 추가
local BLEED_SPELL_IDS = {
    -- [12345] = true,
}

local PREVIEW_TYPE_ORDER = {
    "magic",
    "curse",
    "disease",
    "poison",
    "bleed",
    "none",
}

local PREVIEW_ICONS = {
    magic = 136243,
    curse = 136139,
    disease = 136148,
    poison = 132108,
    bleed = 132090,
    none = 134430,
}

local function GetCenterDebuffDB()
    local cfg = ns:GetPartyConfig()
    return cfg and cfg.debuff
end

local function IsSafeLookupValue(value)
    if value == nil then
        return false
    end

    if IsSecretValue(value) then
        return false
    end

    if canaccessvalue and not canaccessvalue(value) then
        return false
    end

    return true
end

local function SafeStringKey(value)
    if not IsSafeLookupValue(value) then
        return nil
    end

    return tostring(value)
end
local function HideBorder(slot)
    if not (slot and slot.border) then
        return
    end

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
    if not slot then
        return
    end

    if slot.count then
        slot.count:SetText("")
    end

    if slot.icon then
        slot.icon:SetTexture(nil)
    end

    if slot.cd then
        slot.cd:Hide()
    end

    slot.auraInstanceID = nil
    slot.__typeKey = nil
    HideBorder(slot)
    slot:Hide()
end

local function HideAllSlots(container)
    if not (container and container.slots) then
        return
    end

    for i = 1, #container.slots do
        HideSlot(container.slots[i])
    end
end

local function AlignVisibleSlots(container)
    if not (container and container.slots) then
        return
    end

    local shown = {}
    for i = 1, #container.slots do
        if container.slots[i]:IsShown() then
            shown[#shown + 1] = container.slots[i]
        end
    end

    if #shown == 0 then
        return
    end

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
    if not (container and frame and db) then
        return
    end

    local size = tonumber(db.size) or DEFAULT_SIZE
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

local function GetSpellTextureSafe(spellID)
    if not spellID then
        return nil
    end

    spellID = tonumber(spellID)
    if not spellID then
        return nil
    end

    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        return info and info.iconID or nil
    end

    return nil
end

local function GetAuraTypeKey(aura)
    if not aura then
        return "none"
    end

    local spellId = nil
    if IsSafeLookupValue(aura.spellId) then
        spellId = tonumber(aura.spellId)
    end
    if spellId and BLEED_SPELL_IDS[spellId] then
        return "bleed"
    end

    local dispelName = nil
    if IsSafeLookupValue(aura.dispelName) then
        dispelName = aura.dispelName
    elseif IsSafeLookupValue(aura.debuffType) then
        dispelName = aura.debuffType
    end
    if not dispelName then
        return "none"
    end

    local key = tostring(dispelName):lower()

    if key == "magic" then
        return "magic"
    elseif key == "curse" then
        return "curse"
    elseif key == "disease" then
        return "disease"
    elseif key == "poison" then
        return "poison"
    elseif key == "bleed" then
        return "bleed"
    end

    return "none"
end

local function IsTypeShownInConfig(db, typeKey)
    if typeKey == "magic" then
        return db.showMagic ~= false
    elseif typeKey == "curse" then
        return db.showCurse ~= false
    elseif typeKey == "disease" then
        return db.showDisease ~= false
    elseif typeKey == "poison" then
        return db.showPoison ~= false
    elseif typeKey == "bleed" then
        return db.showBleed ~= false
    end

    return db.showNone ~= false
end

local function IsHiddenUtilityAura(aura)
    if not aura then
        return false
    end

    local db = GetCenterDebuffDB()
    if not db or db.hideUtilityDebuffs == nil then
        db = { hideUtilityDebuffs = true }
    end

    if db.hideUtilityDebuffs ~= true then
        return false
    end

    local rawSpellId = aura.spellId
    if IsSafeLookupValue(rawSpellId) then
        local spellId = tonumber(rawSpellId)
        if spellId and HIDDEN_UTILITY_DEBUFFS[spellId] then
            return true
        end

        local spellKey = SafeStringKey(rawSpellId)
        if spellKey and HIDDEN_UTILITY_DEBUFFS[spellKey] then
            return true
        end
    end
    local name = aura.name
    if IsSafeLookupValue(name) then
        local nameKey = SafeStringKey(name)
        if nameKey and HIDDEN_UTILITY_DEBUFF_NAMES[nameKey] then
            return true
        end
    end

    return false
end

local function GetPlayerDispelCapabilities()
    local canMagic = false
    local canCurse = false
    local canDisease = false
    local canPoison = false

    local _, classTag = UnitClass("player")
    local specIndex = GetSpecialization and GetSpecialization() or nil
    local specID = specIndex and GetSpecializationInfo(specIndex) or nil

    if classTag == "PRIEST" then
        canMagic = true
        canDisease = true
    elseif classTag == "PALADIN" then
        canPoison = true
        canDisease = true
        if specID == 65 then
            canMagic = true
        end
    elseif classTag == "SHAMAN" then
        canCurse = true
        if specID == 264 then
            canMagic = true
        end
    elseif classTag == "DRUID" then
        canCurse = true
        canPoison = true
        if specID == 105 then
            canMagic = true
        end
    elseif classTag == "MONK" then
        canPoison = true
        canDisease = true
        if specID == 270 then
            canMagic = true
        end
    elseif classTag == "MAGE" then
        canCurse = true
    elseif classTag == "EVOKER" then
        canPoison = true
        if specID == 1468 then
            canCurse = true
            canMagic = true
        end
    end

    return {
        magic = canMagic,
        curse = canCurse,
        disease = canDisease,
        poison = canPoison,
    }
end

local function CanPlayerDispelAura(aura)
    if not aura then
        return false
    end

    if IsSafeLookupValue(aura.canActivePlayerDispel) then
        return aura.canActivePlayerDispel == true
    end

    local typeKey = GetAuraTypeKey(aura)
    if typeKey ~= "magic" and typeKey ~= "curse" and typeKey ~= "disease" and typeKey ~= "poison" then
        return false
    end

    local caps = GetPlayerDispelCapabilities()
    return caps[typeKey] == true
end

local function RefreshAuraByInstanceID(unit, auraInstanceID)
    if not unit or not auraInstanceID then
        return nil
    end

    if C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID then
        return C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
    end

    return nil
end

local function AuraPassesFilters(aura, db)
    if not aura or not aura.auraInstanceID then
        return false
    end

    if IsHiddenUtilityAura(aura) then
        return false
    end

    local typeKey = GetAuraTypeKey(aura)
    if not IsTypeShownInConfig(db, typeKey) then
        return false
    end

    if db.onlyDispellable and not CanPlayerDispelAura(aura) then
        return false
    end

    return true
end

local function CollectDisplayAuras(unit, db)
    local accepted = {}
    local index = 1
    while #accepted < MAX_CENTER_DEBUFFS do
        local aura = C_UnitAuras.GetDebuffDataByIndex(unit, index)
        if not aura or not aura.auraInstanceID then
            break
        end

        if AuraPassesFilters(aura, db) then
            local data = RefreshAuraByInstanceID(unit, aura.auraInstanceID)
            if data and data.auraInstanceID then
                data.__typeKey = GetAuraTypeKey(data)
                accepted[#accepted + 1] = data
            end
        end

        index = index + 1
    end

    return accepted
end

local function GetAuraBorderColor(unit, aura)
    if not aura then
        return nil
    end

    local r, g, b, a
    if aura.auraInstanceID and ns.GetAuraDispelColor then
        r, g, b, a = ns:GetAuraDispelColor(unit, aura.auraInstanceID)
    end

    if r and g and b then
        return r, g, b, a
    end

    return GetFallbackTypeColor(aura.__typeKey or GetAuraTypeKey(aura))
end

local function BuildPreviewTypes(db)
    local out = {}

    for _, typeKey in ipairs(PREVIEW_TYPE_ORDER) do
        if IsTypeShownInConfig(db, typeKey) then
            out[#out + 1] = typeKey
        end

        if #out >= MAX_CENTER_DEBUFFS then
            break
        end
    end

    if #out == 0 then
        out[1] = "magic"
    end

    return out
end

local function ResolveDisplayIcon(aura)
    if not aura then
        return 136243
    end

    if IsSafeLookupValue(aura.icon) then
        return aura.icon
    end

    local spellId = nil
    if IsSafeLookupValue(aura.spellId) then
        spellId = aura.spellId
    end

    return GetSpellTextureSafe(spellId) or 136243
end
function ns.uf:CreateCenterDebuff(frame)
    if frame.CenterDebuff then
        return frame.CenterDebuff
    end

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
            if not self.auraInstanceID or not frame or not frame.unit then
                return
            end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local success = pcall(function()
                GameTooltip:SetUnitDebuffByAuraInstanceID(frame.unit, self.auraInstanceID)
            end)

            if success then
                GameTooltip:Show()
            else
                GameTooltip:Hide()
            end
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
    if not frame then
        return
    end

    local db = GetCenterDebuffDB()
    if not db then
        return
    end

    local container = frame.CenterDebuff or self:CreateCenterDebuff(frame)
    ApplyLayout(container, frame, db)

    if db.enabled == false then
        HideAllSlots(container)
        container:Hide()
    end
end

function ns.uf:UpdateCenterDebuffPreview(frame)
    if not frame or not frame.CenterDebuff then
        return
    end

    local db = GetCenterDebuffDB()
    if not db or db.enabled == false or not db.preview then
        return
    end

    local container = frame.CenterDebuff
    HideAllSlots(container)

    local previewTypes = BuildPreviewTypes(db)
    local shown = 0

    for i = 1, math.min(#previewTypes, MAX_CENTER_DEBUFFS) do
        local typeKey = previewTypes[i]
        local slot = container.slots[i]
        if slot then
            local r, g, b, a = GetFallbackTypeColor(typeKey)
            slot.icon:SetTexture(PREVIEW_ICONS[typeKey] or 136243)
            slot.__typeKey = typeKey
            slot.count:SetText(i == 1 and "3" or "")
            slot.cd:Hide()
            ShowBorder(slot, r, g, b, a)
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

function ns.uf:UpdateCenterDebuff(frame)
    local container = frame and frame.CenterDebuff
    if not container then
        return
    end

    local cfg = GetCenterDebuffDB() or {}

    if cfg.enabled == false then
        HideAllSlots(container)
        container:Hide()
        return
    end

    ApplyLayout(container, frame, cfg)
    HideAllSlots(container)

    if cfg.preview then
        self:UpdateCenterDebuffPreview(frame)
        return
    end

    if not frame.unit or not UnitExists(frame.unit) then
        container:Hide()
        return
    end

    local auras = CollectDisplayAuras(frame.unit, cfg)
    if not auras or #auras == 0 then
        container:Hide()
        return
    end

    local shown = 0

    for i = 1, math.min(#auras, MAX_CENTER_DEBUFFS) do
        local aura = auras[i]
        local slot = container.slots[i]

        if aura and slot and aura.auraInstanceID then
            local iconTex = ResolveDisplayIcon(aura)
            local r, g, b, a = GetAuraBorderColor(frame.unit, aura)

            slot.icon:SetTexture(iconTex)
            slot.auraInstanceID = aura.auraInstanceID
            slot.__typeKey = aura.__typeKey

            ShowBorder(slot, r, g, b, a)

            local countText
            if C_UnitAuras.GetAuraApplicationDisplayCount then
                countText = C_UnitAuras.GetAuraApplicationDisplayCount(frame.unit, aura.auraInstanceID, 2, 999)
            end
            slot.count:SetText(countText or "")

            local durationInfo = C_UnitAuras.GetAuraDuration and
                C_UnitAuras.GetAuraDuration(frame.unit, aura.auraInstanceID)
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
