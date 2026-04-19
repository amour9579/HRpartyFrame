local _, ns = ...

ns.uf = ns.uf or {}

local DEFAULT_SIZE = 36
local DEFAULT_ANCHOR = "CENTER"
local MAX_CENTER_DEBUFFS = 5
local AURA_SCAN_LIMIT = 40
local CENTER_DEBUFF_SPACING = 2
local MAX_PRIVATE_AURAS = 3
local PRIVATE_AURA_SPACING = 2
local DEFAULT_PRIVATE_AURA_ANCHOR = "RIGHT"
local IsSecretValue = issecretvalue or function(...)
    return false
end
local AddPrivateAuraAnchor = C_UnitAuras and C_UnitAuras.AddPrivateAuraAnchor
local RemovePrivateAuraAnchor = C_UnitAuras and C_UnitAuras.RemovePrivateAuraAnchor
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

-- 1차 구현:
-- 출혈은 API만으로 안정 분류가 어려워서 spellID 테이블 기반으로 처리.
-- 아래 테이블은 필요할 때 직접 보강하면 된다.
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

local function GetCenterDebuffDB()
    local cfg = ns:GetPartyConfig()
    return cfg and cfg.debuff
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
        if (n and HIDDEN_UTILITY_DEBUFFS[n] == true) or HIDDEN_UTILITY_DEBUFFS[sid] == true or HIDDEN_UTILITY_DEBUFFS[tostring(sid)] == true then
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
    slot.__typeKey = nil
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
    if not (container and frame and db) then return end

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

local function GetAuraTypeKey(aura)
    if not aura then
        return "none"
    end

    local spellId = aura.spellId
    if spellId and not IsSecretValue(spellId) then
        local normalizedSpellID = tonumber(spellId) or spellId
        if BLEED_SPELL_IDS[normalizedSpellID] then
            return "bleed"
        end
    end

    local dispelName = aura.dispelName
    if not dispelName or IsSecretValue(dispelName) then
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

    local expirationTime = aura.expirationTime
    if expirationTime and not IsSecretValue(expirationTime) and expirationTime > 0 then
        return math.max(0, expirationTime - GetTime())
    end

    return math.huge
end

local function CompareAuras(a, b)
    local aBoss = a.isBossAura and 0 or 1
    local bBoss = b.isBossAura and 0 or 1
    if aBoss ~= bBoss then
        return aBoss < bBoss
    end

    local aType = TYPE_PRIORITY[a.__typeKey] or 99
    local bType = TYPE_PRIORITY[b.__typeKey] or 99
    if aType ~= bType then
        return aType < bType
    end

    local aRemaining = a.__remaining or math.huge
    local bRemaining = b.__remaining or math.huge
    if aRemaining ~= bRemaining then
        return aRemaining < bRemaining
    end

    local aCount = tonumber(a.applications) or 0
    local bCount = tonumber(b.applications) or 0
    if aCount ~= bCount then
        return aCount > bCount
    end

    local aSpell = tonumber(a.spellId) or 0
    local bSpell = tonumber(b.spellId) or 0
    if aSpell ~= bSpell then
        return aSpell < bSpell
    end

    return (tonumber(a.auraInstanceID) or 0) < (tonumber(b.auraInstanceID) or 0)
end
local function GetAurasByFilter(unit, filter, maxCount)
    maxCount = maxCount or AURA_SCAN_LIMIT
    local out = {}

    if C_UnitAuras.GetUnitAuras then
        local auras = C_UnitAuras.GetUnitAuras(unit, filter, maxCount)
        if type(auras) == "table" then
            for i = 1, math.min(#auras, maxCount) do
                local aura = auras[i]
                if aura and aura.auraInstanceID then
                    out[#out + 1] = aura
                end
            end
        end
        return out
    end

    local slots = { C_UnitAuras.GetAuraSlots(unit, filter, maxCount) }
    for i = 2, #slots do
        local aura = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
        if aura and aura.auraInstanceID then
            out[#out + 1] = aura
            if #out >= maxCount then
                break
            end
        end
    end

    return out
end

local function BuildDisplayAuraList(unit, db)
    local filter = db.onlyDispellable and "HARMFUL|RAID_PLAYER_DISPELLABLE" or "HARMFUL"
    local source = GetAurasByFilter(unit, filter, AURA_SCAN_LIMIT)
    local out = {}

    for i = 1, #source do
        local aura = source[i]
        if aura and aura.auraInstanceID and not IsHiddenUtilityAura(aura) then
            local typeKey = GetAuraTypeKey(aura)
            if IsTypeShownInConfig(db, typeKey) then
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

local function HidePrivateAuraContainer(frame)
    local container = frame and frame.PrivateAuraContainer
    if not container then
        return
    end

    for i = 1, #container.slots do
        container.slots[i]:Hide()
    end

    container:Hide()
end

local function ClearPrivateAuraAnchors(frame)
    if not frame then
        return
    end

    if RemovePrivateAuraAnchor then
        if frame.__privateAuraAnchor1 then
            RemovePrivateAuraAnchor(frame.__privateAuraAnchor1)
        end
        if frame.__privateAuraAnchor2 then
            RemovePrivateAuraAnchor(frame.__privateAuraAnchor2)
        end
        if frame.__privateAuraAnchor3 then
            RemovePrivateAuraAnchor(frame.__privateAuraAnchor3)
        end
    end

    frame.__privateAuraAnchor1 = nil
    frame.__privateAuraAnchor2 = nil
    frame.__privateAuraAnchor3 = nil
    frame.__privateAuraSignature = nil
end

local function CreatePrivateAuraContainer(frame)
    if frame.PrivateAuraContainer then
        return frame.PrivateAuraContainer
    end

    local container = CreateFrame("Frame", nil, frame)
    container:SetFrameLevel(frame:GetFrameLevel() + 25)
    container:SetSize(DEFAULT_SIZE, DEFAULT_SIZE)
    container:Hide()
    container.slots = {}

    for i = 1, MAX_PRIVATE_AURAS do
        local holder = CreateFrame("Frame", nil, container)
        holder:SetFrameLevel(container:GetFrameLevel())
        holder:SetSize(DEFAULT_SIZE, DEFAULT_SIZE)
        holder:EnableMouse(true)
        holder:Hide()

        container.slots[i] = holder
    end

    frame.PrivateAuraContainer = container
    return container
end

local function ApplyPrivateAuraLayout(frame, db)
    local container = frame and (frame.PrivateAuraContainer or CreatePrivateAuraContainer(frame))
    if not (container and frame and db) then
        return
    end

    local size = tonumber(db.size) or DEFAULT_SIZE
    local anchor = db.privateAuraAnchor or DEFAULT_PRIVATE_AURA_ANCHOR

    container:ClearAllPoints()

    if anchor == "LEFT" then
        local totalHeight = (size * MAX_PRIVATE_AURAS) + (PRIVATE_AURA_SPACING * (MAX_PRIVATE_AURAS - 1))
        container:SetSize(size, totalHeight)
        container:SetPoint("RIGHT", frame, "LEFT", -2, 0)

        for i = 1, MAX_PRIVATE_AURAS do
            local holder = container.slots[i]
            holder:SetSize(size, size)
            holder:ClearAllPoints()

            if i == 1 then
                holder:SetPoint("TOP", container, "TOP", 0, 0)
            else
                holder:SetPoint("TOP", container.slots[i - 1], "BOTTOM", 0, -PRIVATE_AURA_SPACING)
            end
        end
    elseif anchor == "TOP" then
        local totalWidth = (size * MAX_PRIVATE_AURAS) + (PRIVATE_AURA_SPACING * (MAX_PRIVATE_AURAS - 1))
        container:SetSize(totalWidth, size)
        container:SetPoint("BOTTOM", frame, "TOP", 0, 2)

        for i = 1, MAX_PRIVATE_AURAS do
            local holder = container.slots[i]
            holder:SetSize(size, size)
            holder:ClearAllPoints()

            if i == 1 then
                holder:SetPoint("LEFT", container, "LEFT", 0, 0)
            else
                holder:SetPoint("LEFT", container.slots[i - 1], "RIGHT", PRIVATE_AURA_SPACING, 0)
            end
        end
    elseif anchor == "BOTTOM" then
        local totalWidth = (size * MAX_PRIVATE_AURAS) + (PRIVATE_AURA_SPACING * (MAX_PRIVATE_AURAS - 1))
        container:SetSize(totalWidth, size)
        container:SetPoint("TOP", frame, "BOTTOM", 0, -2)

        for i = 1, MAX_PRIVATE_AURAS do
            local holder = container.slots[i]
            holder:SetSize(size, size)
            holder:ClearAllPoints()

            if i == 1 then
                holder:SetPoint("LEFT", container, "LEFT", 0, 0)
            else
                holder:SetPoint("LEFT", container.slots[i - 1], "RIGHT", PRIVATE_AURA_SPACING, 0)
            end
        end
    else
        local totalHeight = (size * MAX_PRIVATE_AURAS) + (PRIVATE_AURA_SPACING * (MAX_PRIVATE_AURAS - 1))
        container:SetSize(size, totalHeight)
        container:SetPoint("LEFT", frame, "RIGHT", 2, 0)

        for i = 1, MAX_PRIVATE_AURAS do
            local holder = container.slots[i]
            holder:SetSize(size, size)
            holder:ClearAllPoints()

            if i == 1 then
                holder:SetPoint("TOP", container, "TOP", 0, 0)
            else
                holder:SetPoint("TOP", container.slots[i - 1], "BOTTOM", 0, -PRIVATE_AURA_SPACING)
            end
        end
    end
end

local function GetPrivateAuraSignature(frame, db)
    return table.concat({
        tostring(frame and frame.unit or ""),
        tostring(db and db.showPrivateAuras == true),
        tostring(db and db.privateAuraAnchor or DEFAULT_PRIVATE_AURA_ANCHOR),
        tostring(db and db.size or DEFAULT_SIZE),
    }, ":")
end

local function RegisterPrivateAuraAnchors(frame, db)
    if not (frame and db) then
        return
    end

    local container = frame.PrivateAuraContainer or CreatePrivateAuraContainer(frame)
    if not container then
        return
    end

    if not AddPrivateAuraAnchor then
        ClearPrivateAuraAnchors(frame)
        HidePrivateAuraContainer(frame)
        return
    end

    if db.showPrivateAuras ~= true or db.enabled == false or not frame.unit or not UnitExists(frame.unit) then
        ClearPrivateAuraAnchors(frame)
        HidePrivateAuraContainer(frame)
        return
    end

    local signature = GetPrivateAuraSignature(frame, db)
    if frame.__privateAuraSignature == signature and not frame.__privateAuraPending then
        container:Show()
        for i = 1, #container.slots do
            container.slots[i]:Show()
        end
        return
    end

    if InCombatLockdown() then
        frame.__privateAuraPending = true
        return
    end

    frame.__privateAuraPending = nil

    ApplyPrivateAuraLayout(frame, db)
    ClearPrivateAuraAnchors(frame)

    local size = tonumber(db.size) or DEFAULT_SIZE
    local anchorIDs = {}

    for i = 1, MAX_PRIVATE_AURAS do
        local holder = container.slots[i]
        holder:SetSize(size, size)
        holder:Show()

        local auraAnchor = {
            unitToken = frame.unit,
            auraIndex = i,
            parent = holder,
            showCountdownFrame = false,
            showCountdownNumbers = true,
            iconInfo = {
                iconWidth = size,
                iconHeight = size,
                borderScale = 0,
                iconAnchor = {
                    point = "CENTER",
                    relativeTo = holder,
                    relativePoint = "CENTER",
                    offsetX = 0,
                    offsetY = 0,
                },
            },
        }

        anchorIDs[i] = AddPrivateAuraAnchor(auraAnchor)
    end

    frame.__privateAuraAnchor1 = anchorIDs[1]
    frame.__privateAuraAnchor2 = anchorIDs[2]
    frame.__privateAuraAnchor3 = anchorIDs[3]
    frame.__privateAuraSignature = signature

    container:Show()
end
function ns.uf:CreateCenterDebuff(frame)
    if frame.CenterDebuff then
        if not frame.PrivateAuraContainer then
            CreatePrivateAuraContainer(frame)
        end
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
            if not self.auraInstanceID or not frame.unit then
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
    CreatePrivateAuraContainer(frame)
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
    ApplyPrivateAuraLayout(frame, db)
    if db.enabled == false then
        HideAllSlots(container)
        container:Hide()
        ClearPrivateAuraAnchors(frame)
        HidePrivateAuraContainer(frame)
        return
    end
    RegisterPrivateAuraAnchors(frame, db)
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

    HideAllSlots(container)

    local cfg = GetCenterDebuffDB() or {}

    if cfg.enabled == false then
        container:Hide()
        ClearPrivateAuraAnchors(frame)
        HidePrivateAuraContainer(frame)
        return
    end

    ApplyLayout(container, frame, cfg)
    RegisterPrivateAuraAnchors(frame, cfg)
    if cfg.preview then
        self:UpdateCenterDebuffPreview(frame)
        return
    end

    if not frame.unit or not UnitExists(frame.unit) then
        container:Hide()
        ClearPrivateAuraAnchors(frame)
        HidePrivateAuraContainer(frame)
        return
    end

    local auras = BuildDisplayAuraList(frame.unit, cfg)
    if not auras or #auras == 0 then
        container:Hide()
        return
    end

    local shown = 0

    for i = 1, MAX_CENTER_DEBUFFS do
        local aura = auras[i]
        local slot = container.slots[i]

        if aura and slot and aura.auraInstanceID then
            local r, g, b, a = GetAuraBorderColor(frame.unit, aura)
            slot.icon:SetTexture(aura.icon or 136243)
            slot.auraInstanceID = aura.auraInstanceID
            slot.__typeKey = aura.__typeKey

            ShowBorder(slot, r, g, b, a)

            local countText
            if C_UnitAuras.GetAuraApplicationDisplayCount then
                countText = C_UnitAuras.GetAuraApplicationDisplayCount(frame.unit, aura.auraInstanceID, 2, 999)
            end
            if not countText then
                local applications = tonumber(aura.applications) or 0
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
        end
    end

    if shown > 0 then
        AlignVisibleSlots(container)
        container:Show()
    else
        container:Hide()
    end
end
