local _, ns = ...

ns.uf = ns.uf or {}

local DEFAULT_SIZE = 36
local DEFAULT_ANCHOR = "CENTER"

local MAX_CENTER_DEBUFFS = 5
local AURA_SCAN_LIMIT = 32
local CENTER_DEBUFF_SPACING = 2

local IsSecretValue = issecretvalue or function(...)
    return false
end

local CanAccessValue = canaccessvalue or function(value)
    return value == nil or not IsSecretValue(value)
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

-- 1차 안정판:
-- 출혈은 spellID 테이블 기반으로 분류.
-- 필요하면 이후 spellID를 추가해 정확도를 높이면 됨.
local BLEED_SPELL_IDS = {
    -- [12345] = true,
}

local TYPE_PRIORITY = {
    magic = 1,
    curse = 2,
    disease = 3,
    poison = 4,
    bleed = 5,
    none = 6,
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

-- 표시 개수에 따라 가운데 정렬된 슬롯 인덱스 사용
local DISPLAY_SLOT_MAP = {
    [1] = { 3 },
    [2] = { 2, 4 },
    [3] = { 2, 3, 4 },
    [4] = { 1, 2, 4, 5 },
    [5] = { 1, 2, 3, 4, 5 },
}

local function GetCenterDebuffDB()
    local cfg = ns:GetPartyConfig()
    return cfg and cfg.debuff
end

local function SafeBoolean(value, default)
    if value == nil or IsSecretValue(value) then
        return default == true
    end
    return value == true
end

local function SafeNumber(value, default)
    if value == nil or IsSecretValue(value) then
        return default
    end

    local n = tonumber(value)
    if n == nil then
        return default
    end

    return n
end

local function SafeValue(value, default)
    if value == nil or IsSecretValue(value) then
        return default
    end

    if canaccessvalue and not canaccessvalue(value) then
        return default
    end

    return value
end

local function IsReadableValue(value)
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

local function GetFallbackTypeColor(typeKey)
    local color

    if typeKey == "magic" then
        color = DEBUFF_TYPE_MAGIC_COLOR or (DebuffTypeColor and DebuffTypeColor.Magic)
    elseif typeKey == "curse" then
        color = DEBUFF_TYPE_CURSE_COLOR or (DebuffTypeColor and DebuffTypeColor.Curse)
    elseif typeKey == "disease" then
        color = DEBUFF_TYPE_DISEASE_COLOR or (DebuffTypeColor and DebuffTypeColor.Disease)
    elseif typeKey == "poison" then
        color = DEBUFF_TYPE_POISON_COLOR or (DebuffTypeColor and DebuffTypeColor.Poison)
    elseif typeKey == "bleed" then
        color = DEBUFF_TYPE_BLEED_COLOR or (DebuffTypeColor and DebuffTypeColor.Bleed)
    else
        color = DEBUFF_TYPE_NONE_COLOR
    end

    local r, g, b, a = NormalizeColor(color)
    if r and g and b then
        return r, g, b, a
    end

    if typeKey == "none" then
        return 0.65, 0.65, 0.65, 1
    elseif typeKey == "bleed" then
        return 0.78, 0.25, 0.25, 1
    end

    return 1, 1, 1, 1
end

local function IsUtilityDebuffFilterEnabled()
    local db = GetCenterDebuffDB()
    if not db or db.hideUtilityDebuffs == nil then
        return true
    end
    return db.hideUtilityDebuffs == true
end

local function IsHiddenUtilityAura(data)
    if not IsUtilityDebuffFilterEnabled() then
        return false
    end

    local sid = data and data.spellId
    if sid and not IsSecretValue(sid) then
        local n = tonumber(sid)
        if (n and HIDDEN_UTILITY_DEBUFFS[n] == true)
            or HIDDEN_UTILITY_DEBUFFS[sid] == true
            or HIDDEN_UTILITY_DEBUFFS[tostring(sid)] == true then
            return true
        end
    end

    local auraName = data and data.name
    if auraName and not IsSecretValue(auraName) and HIDDEN_UTILITY_DEBUFF_NAMES[auraName] == true then
        return true
    end

    return false
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

local function ApplyLayout(container, frame, db)
    if not (container and frame and db) then
        return
    end

    local size = tonumber(db.size) or DEFAULT_SIZE
    local thickness = tonumber(db.iconBorderThickness) or 2
    local totalWidth = (size * MAX_CENTER_DEBUFFS) + (CENTER_DEBUFF_SPACING * (MAX_CENTER_DEBUFFS - 1))
    local centerIndex = (MAX_CENTER_DEBUFFS + 1) / 2

    container:ClearAllPoints()
    container:SetPoint(db.anchor or DEFAULT_ANCHOR, frame, db.anchor or DEFAULT_ANCHOR, db.x or 0, db.y or 0)
    container:SetSize(totalWidth, size)

    for i = 1, #container.slots do
        local slot = container.slots[i]
        local offsetIndex = i - centerIndex
        local offsetX = offsetIndex * (size + CENTER_DEBUFF_SPACING)

        slot:ClearAllPoints()
        slot:SetPoint("CENTER", container, "CENTER", offsetX, 0)
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
    local id = SafeNumber(spellID, nil)
    if not id then
        return nil
    end

    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(id)
        local iconID = info and info.iconID
        if IsReadableValue(iconID) then
            return iconID
        end
    end

    return nil
end

local function ResolveAuraIcon(aura)
    if not aura then
        return nil
    end

    if IsReadableValue(aura.icon) then
        return aura.icon
    end

    local spellID = SafeNumber(aura.spellId, nil)
    if spellID then
        return GetSpellTextureSafe(spellID)
    end

    return nil
end
local function GetAuraTypeKey(aura)
    if not aura then
        return "none"
    end

    local spellId = SafeNumber(aura.spellId, nil)
    if spellId and BLEED_SPELL_IDS[spellId] then
        return "bleed"
    end

    local dispelName = nil
    if IsReadableValue(aura.dispelName) then
        dispelName = aura.dispelName
    elseif IsReadableValue(aura.debuffType) then
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

local function GetAuraRemainingTime(aura)
    if not aura then
        return math.huge
    end

    local expirationTime = SafeNumber(aura.expirationTime, nil)
    if expirationTime and expirationTime > 0 then
        return math.max(0, expirationTime - GetTime())
    end

    return math.huge
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

    if IsReadableValue(aura.canActivePlayerDispel) then
        return aura.canActivePlayerDispel == true
    end
    local typeKey = GetAuraTypeKey(aura)
    if typeKey ~= "magic" and typeKey ~= "curse" and typeKey ~= "disease" and typeKey ~= "poison" then
        return false
    end

    local caps = GetPlayerDispelCapabilities()
    return caps[typeKey] == true
end

local function CompareAuras(a, b)
    local aType = TYPE_PRIORITY[a and a.__typeKey] or 99
    local bType = TYPE_PRIORITY[b and b.__typeKey] or 99
    if aType ~= bType then
        return aType < bType
    end

    local aRemaining = SafeNumber(a and a.__remaining, math.huge)
    local bRemaining = SafeNumber(b and b.__remaining, math.huge)
    if aRemaining ~= bRemaining then
        return aRemaining < bRemaining
    end

    local aCount = SafeNumber(a and a.applications, 0)
    local bCount = SafeNumber(b and b.applications, 0)
    if aCount ~= bCount then
        return aCount > bCount
    end

    local aSpell = SafeNumber(a and a.spellId, 0)
    local bSpell = SafeNumber(b and b.spellId, 0)
    if aSpell ~= bSpell then
        return aSpell < bSpell
    end

    local aAuraID = SafeNumber(a and a.auraInstanceID, 0)
    local bAuraID = SafeNumber(b and b.auraInstanceID, 0)
    return aAuraID < bAuraID
end

local function RefreshAuraByInstanceID(unit, aura)
    if not unit or not aura or not aura.auraInstanceID then
        return nil
    end

    if C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID then
        local refreshed = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, aura.auraInstanceID)
        if refreshed and refreshed.auraInstanceID then
            return refreshed
        end
    end

    return aura
end

local function CollectCandidateAuras(unit, db, maxCount)
    maxCount = maxCount or AURA_SCAN_LIMIT
    local out = {}
    local seen = {}

    if not unit or not UnitExists(unit) then
        return out
    end

    local function AddAura(aura)
        if not aura or not aura.auraInstanceID then
            return
        end

        if seen[aura.auraInstanceID] then
            return
        end

        local refreshed = RefreshAuraByInstanceID(unit, aura)
        if not refreshed or not refreshed.auraInstanceID then
            return
        end

        seen[refreshed.auraInstanceID] = true
        out[#out + 1] = refreshed
    end

    -- 예전 안정 버전 흐름:
    -- 해제 가능 우선이면 HARMFUL|RAID 슬롯 먼저 본다.
    if db and db.onlyDispellable and C_UnitAuras and C_UnitAuras.GetAuraSlots and C_UnitAuras.GetAuraDataBySlot then
        local slots = { C_UnitAuras.GetAuraSlots(unit, "HARMFUL|RAID", maxCount) }
        for i = 2, #slots do
            local aura = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
            AddAura(aura)
            if #out >= maxCount then
                return out
            end
        end
    end

    -- 예전 안정 버전 흐름:
    -- 전체 디버프는 GetDebuffDataByIndex 순차 탐색을 우선 사용.
    if C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex then
        local index = 1
        while #out < maxCount do
            local aura = C_UnitAuras.GetDebuffDataByIndex(unit, index)
            if not aura or not aura.auraInstanceID then
                break
            end

            AddAura(aura)
            index = index + 1
        end
    end

    -- 최후 fallback
    if #out == 0 and C_UnitAuras and C_UnitAuras.GetAuraSlots and C_UnitAuras.GetAuraDataBySlot then
        local slots = { C_UnitAuras.GetAuraSlots(unit, "HARMFUL", maxCount) }
        for i = 2, #slots do
            local aura = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
            AddAura(aura)
            if #out >= maxCount then
                break
            end
        end
    end

    return out
end

local function HasRenderableAuraData(aura)
    if not aura or not aura.auraInstanceID then
        return false
    end

    return ResolveAuraIcon(aura) ~= nil
end
local function BuildDisplayAuraList(unit, db)
    local source = CollectCandidateAuras(unit, db, AURA_SCAN_LIMIT)
    local out = {}

    for i = 1, #source do
        local aura = source[i]
        if aura
            and aura.auraInstanceID
            and HasRenderableAuraData(aura)
            and not IsHiddenUtilityAura(aura) then
            local typeKey = GetAuraTypeKey(aura)

            if db.onlyDispellable and not CanPlayerDispelAura(aura) then
                -- skip
            elseif IsTypeShownInConfig(db, typeKey) then
                aura.__typeKey = typeKey
                aura.__remaining = GetAuraRemainingTime(aura)
                out[#out + 1] = aura
            end
        end
    end

    table.sort(out, CompareAuras)

    if #out > MAX_CENTER_DEBUFFS then
        for i = #out, MAX_CENTER_DEBUFFS + 1, -1 do
            out[i] = nil
        end
    end

    return out
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

local function GetDisplaySlotsForCount(count)
    if count < 1 then
        return nil
    end

    if count > MAX_CENTER_DEBUFFS then
        count = MAX_CENTER_DEBUFFS
    end

    return DISPLAY_SLOT_MAP[count] or DISPLAY_SLOT_MAP[MAX_CENTER_DEBUFFS]
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
            local ok = pcall(function()
                GameTooltip:SetUnitDebuffByAuraInstanceID(frame.unit, self.auraInstanceID)
            end)

            if ok then
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
    local shownCount = math.min(#previewTypes, MAX_CENTER_DEBUFFS)
    local slotIndices = GetDisplaySlotsForCount(shownCount)

    if not slotIndices then
        container:Hide()
        return
    end

    local shown = 0
    for auraIndex = 1, shownCount do
        local typeKey = previewTypes[auraIndex]
        local physicalIndex = slotIndices[auraIndex]
        local slot = physicalIndex and container.slots[physicalIndex]

        if slot then
            local r, g, b, a = GetFallbackTypeColor(typeKey)
            slot.icon:SetTexture(PREVIEW_ICONS[typeKey] or 136243)
            slot.__typeKey = typeKey
            slot.count:SetText(auraIndex == 1 and "3" or "")
            slot.cd:Hide()
            ShowBorder(slot, r, g, b, a)
            slot:Show()
            shown = shown + 1
        end
    end

    if shown > 0 then
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

    local auras = BuildDisplayAuraList(frame.unit, cfg)
    local shownCount = auras and #auras or 0
    if shownCount == 0 then
        container:Hide()
        return
    end

    local slotIndices = GetDisplaySlotsForCount(shownCount)
    if not slotIndices then
        container:Hide()
        return
    end

    local shown = 0

    for auraIndex = 1, shownCount do
        local aura = auras[auraIndex]
        local physicalIndex = slotIndices[auraIndex]
        local slot = physicalIndex and container.slots[physicalIndex]

        if aura and slot and aura.auraInstanceID then
            local iconTex = ResolveAuraIcon(aura)
            if iconTex then
                local r, g, b, a = GetAuraBorderColor(frame.unit, aura)

                slot.icon:SetTexture(iconTex)
                slot.auraInstanceID = aura.auraInstanceID
                slot.__typeKey = aura.__typeKey

                ShowBorder(slot, r, g, b, a)

                local countText
                if C_UnitAuras.GetAuraApplicationDisplayCount then
                    countText = C_UnitAuras.GetAuraApplicationDisplayCount(frame.unit, aura.auraInstanceID, 2, 999)
                end
                if not countText then
                    local applications = SafeNumber(aura.applications, 0)
                    countText = applications > 1 and applications or ""
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
            else
                HideSlot(slot)
            end
        end
    end

    if shown > 0 then
        container:Show()
    else
        container:Hide()
    end
end
