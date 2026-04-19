local _, ns = ...

ns.uf = ns.uf or {}

local DEFAULT_SIZE = 36
local DEFAULT_ANCHOR = "CENTER"
local MAX_CENTER_DEBUFFS = 5
local CENTER_DEBUFF_SPACING = 2

local DEBUG_DEBUFF = false

local IsSecretValue = issecretvalue or function(...)
    return false
end

local CanAccessValue = canaccessvalue or function(value)
    return value == nil or not IsSecretValue(value)
end

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

local TYPE_GENERIC_VISUALS = {
    magic = { kind = "atlas", value = "RaidFrame-Icon-DebuffMagic" },
    curse = { kind = "atlas", value = "RaidFrame-Icon-DebuffCurse" },
    disease = { kind = "atlas", value = "RaidFrame-Icon-DebuffDisease" },
    poison = { kind = "atlas", value = "RaidFrame-Icon-DebuffPoison" },
    bleed = { kind = "atlas", value = "RaidFrame-Icon-DebuffBleed" },
    none = { kind = "texture", value = 134430 },
}
local function DebugLog(...)
    if not DEBUG_DEBUFF then
        return
    end
    print("|cff33ff99HRpartyFrame Debuff:|r", ...)
end

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

    if not CanAccessValue(value) then
        return false
    end

    return true
end

local function SafeNumber(value, default)
    if not IsSafeLookupValue(value) then
        return default
    end

    local n = tonumber(value)
    if n == nil then
        return default
    end

    return n
end

local function SafeString(value, default)
    if not IsSafeLookupValue(value) then
        return default
    end

    return tostring(value)
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
    local id = SafeNumber(spellID, nil)
    if not id then
        return nil
    end

    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(id)
        local iconID = info and info.iconID
        if IsSafeLookupValue(iconID) then
            return iconID
        end
    end

    return nil
end

local function GetGenericVisualForType(typeKey)
    return TYPE_GENERIC_VISUALS[typeKey or "none"] or TYPE_GENERIC_VISUALS.none
end

local function ResolveEntryVisual(entry)
    if entry and entry.icon and entry.icon ~= 136243 then
        return {
            kind = "texture",
            value = entry.icon,
        }
    end

    return GetGenericVisualForType(entry and entry.typeKey or "none")
end

local function ApplySlotVisual(slot, visual)
    if not slot or not slot.icon or not visual then
        return
    end

    if visual.kind == "atlas" then
        slot.icon:SetTexture(nil)
        slot.icon:SetTexCoord(0, 1, 0, 1)
        slot.icon:SetAtlas(visual.value)
    else
        slot.icon:SetTexture(visual.value)
        slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end
local function GetAuraTypeKeyFromReadableFields(aura)
    if not aura then
        return "none"
    end

    local spellId = SafeNumber(aura.spellId, nil)
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
        return nil
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

local function InferTypeKeyFromColor(unit, auraInstanceID)
    if not (unit and auraInstanceID and ns.GetAuraDispelColor) then
        return "none", nil
    end

    local r, g, b = ns:GetAuraDispelColor(unit, auraInstanceID)
    if not IsSafeLookupValue(r) or not IsSafeLookupValue(g) or not IsSafeLookupValue(b) then
        return "none", "secret"
    end

    r = tonumber(r)
    g = tonumber(g)
    b = tonumber(b)
    if not r or not g or not b then
        return "none", "secret"
    end

    local colorKey = ns:AuraResolveCacheBuildColorKey(r, g, b)

    local candidates = {
        magic = { GetFallbackTypeColor("magic") },
        curse = { GetFallbackTypeColor("curse") },
        disease = { GetFallbackTypeColor("disease") },
        poison = { GetFallbackTypeColor("poison") },
        bleed = { GetFallbackTypeColor("bleed") },
        none = { GetFallbackTypeColor("none") },
    }

    local bestKey = "none"
    local bestDist = math.huge

    for key, color in pairs(candidates) do
        local cr, cg, cb = color[1], color[2], color[3]
        if cr and cg and cb then
            local dist = ((r - cr) ^ 2) + ((g - cg) ^ 2) + ((b - cb) ^ 2)
            if dist < bestDist then
                bestDist = dist
                bestKey = key
            end
        end
    end

    return bestKey, colorKey
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

local function CanPlayerDispelAura(aura, typeKey)
    if not aura then
        return false
    end

    if IsSafeLookupValue(aura.canActivePlayerDispel) then
        return aura.canActivePlayerDispel == true
    end

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

local function IsAuraResolved(aura)
    if not aura then
        return false
    end

    return IsSafeLookupValue(aura.spellId)
        or IsSafeLookupValue(aura.name)
        or IsSafeLookupValue(aura.dispelName)
        or IsSafeLookupValue(aura.debuffType)
        or IsSafeLookupValue(aura.icon)
end

local function ResolveDisplayIcon(aura, learned)
    if aura and IsSafeLookupValue(aura.icon) then
        return aura.icon
    end

    local spellTex = aura and GetSpellTextureSafe(aura.spellId) or nil
    if spellTex then
        return spellTex
    end
    if learned and learned.icon then
        return learned.icon
    end

    return 136243
end

local function ShouldShowResolvedAura(aura, db, typeKey)
    if not IsTypeShownInConfig(db, typeKey) then
        return false, "type_filtered:" .. tostring(typeKey)
    end

    if db.onlyDispellable and not CanPlayerDispelAura(aura, typeKey) then
        return false, "not_dispellable"
    end

    return true, "ok"
end

local function CollectDisplayAuras(unit, db)
    ns:AuraResolveCacheBegin(unit)
    local index = 1
    local scanned = 0

    while true do
        local aura = C_UnitAuras.GetDebuffDataByIndex(unit, index)
        if not aura or not aura.auraInstanceID then
            break
        end

        scanned = scanned + 1

        local data = RefreshAuraByInstanceID(unit, aura.auraInstanceID)
        if data and data.auraInstanceID then
            local readableType = GetAuraTypeKeyFromReadableFields(data)
            local inferredType, colorKey = InferTypeKeyFromColor(unit, data.auraInstanceID)
            local resolved = IsAuraResolved(data)
            local typeKey = readableType or inferredType or "none"

            local fingerprint = ns:AuraResolveCacheBuildFingerprint(unit, data, typeKey, colorKey)
            local learned = ns:AuraResolveCacheLookupLearned(fingerprint)

            local icon = ResolveDisplayIcon(data, learned)
            local displayName = SafeString(data.name, learned and learned.displayName or "nil")
            local spellId = SafeNumber(data.spellId, learned and learned.spellId or nil)

            if learned and not readableType and learned.typeKey then
                typeKey = learned.typeKey
            end
            local filterPass = false
            local pendingVisible = false
            local learnedFlag = false
            local reason = "unresolved"

            if resolved or learned then
                filterPass, reason = ShouldShowResolvedAura(data, db, typeKey)
                learnedFlag = learned ~= nil and not resolved
            else
                pendingVisible = InCombatLockdown() == true
            end

            if resolved and fingerprint then
                ns:AuraResolveCacheLearn(fingerprint, {
                    icon = icon,
                    spellId = spellId,
                    displayName = displayName,
                    typeKey = typeKey,
                })
            end

            ns:AuraResolveCacheTrack(unit, {
                auraInstanceID = data.auraInstanceID,
                aura = data,
                resolved = resolved,
                typeKey = typeKey,
                icon = icon,
                filterPass = filterPass,
                pendingVisible = pendingVisible,
                displayName = displayName,
                spellId = spellId,
                fingerprint = fingerprint,
                learned = learnedFlag,
            })

            if DEBUG_DEBUFF then
                if resolved or learned then
                    if filterPass then
                        DebugLog("ACCEPT", unit, "idx", index, "auraID", tostring(data.auraInstanceID), "type",
                            tostring(typeKey), "spellID", tostring(spellId or "nil"), "name",
                            tostring(displayName or "nil"), learnedFlag and "(learned)" or "")
                    else
                        DebugLog("SKIP", unit, "idx", index, "auraID", tostring(data.auraInstanceID), "reason",
                            tostring(reason), "spellID", tostring(spellId or "nil"), "name",
                            tostring(displayName or "nil"))
                    end
                else
                    if pendingVisible then
                        DebugLog("ACCEPT", unit, "idx", index, "auraID", tostring(data.auraInstanceID), "type",
                            tostring(typeKey), "spellID", "nil", "name", "nil", "(unresolved)")
                    else
                        DebugLog("SKIP", unit, "idx", index, "auraID", tostring(data.auraInstanceID), "reason",
                            "unresolved_out_of_combat")
                    end
                end
            end
        elseif DEBUG_DEBUFF then
            DebugLog("SKIP", unit, "idx", index, "reason", "refresh_failed", "auraID", tostring(aura.auraInstanceID))
        end

        index = index + 1
    end

    local entries = ns:AuraResolveCacheCollect(unit, MAX_CENTER_DEBUFFS)

    if DEBUG_DEBUFF then
        DebugLog("SUMMARY", unit, "scanned", scanned, "accepted", #entries)
    end

    return entries
end

local function GetAuraBorderColor(unit, entry)
    if not entry then
        return nil
    end

    local aura = entry.aura
    local r, g, b, a
    if aura and aura.auraInstanceID and ns.GetAuraDispelColor then
        r, g, b, a = ns:GetAuraDispelColor(unit, aura.auraInstanceID)
    end

    if r and g and b then
        return r, g, b, a
    end

    return GetFallbackTypeColor(entry.typeKey or "none")
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

function ns.uf:CreateCenterDebuff(frame)
    if frame.CenterDebuff then
        return frame.CenterDebuff
    end

    local container = CreateFrame("Frame", nil, frame)
    container:SetFrameStrata("TOOLTIP")
    container:SetFrameLevel((frame:GetFrameLevel() or 1) + 200)
    if container.SetIgnoreParentAlpha then
        container:SetIgnoreParentAlpha(true)
    end
    container:SetSize(DEFAULT_SIZE, DEFAULT_SIZE)
    container:SetPoint("CENTER", frame, "CENTER", 0, 0)
    container:EnableMouse(false)
    container:Hide()
    container.slots = {}

    for i = 1, MAX_CENTER_DEBUFFS do
        local slot = CreateFrame("Frame", nil, container)
        slot:SetFrameStrata(container:GetFrameStrata())
        slot:SetFrameLevel(container:GetFrameLevel() + i)
        if slot.SetIgnoreParentAlpha then
            slot:SetIgnoreParentAlpha(true)
        end

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

        slot.icon = slot:CreateTexture(nil, "OVERLAY", nil, 1)
        slot.icon:SetAllPoints()
        slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        slot.count = slot:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        slot.count:SetPoint("BOTTOMRIGHT", 2, 0)
        slot.count:SetText("")

        slot.cd = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate")
        slot.cd:SetFrameStrata(slot:GetFrameStrata())
        slot.cd:SetFrameLevel(slot:GetFrameLevel() + 1)
        if slot.cd.SetIgnoreParentAlpha then
            slot.cd:SetIgnoreParentAlpha(true)
        end
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
        if frame.unit then
            ns:AuraResolveCacheReset(frame.unit)
        end
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
            ApplySlotVisual(slot, GetGenericVisualForType(typeKey))
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

    container:SetFrameStrata("TOOLTIP")
    container:SetFrameLevel((frame:GetFrameLevel() or 1) + 200)
    if container.SetIgnoreParentAlpha then
        container:SetIgnoreParentAlpha(true)
    end
    container:SetAlpha(1)

    local cfg = GetCenterDebuffDB() or {}

    if cfg.enabled == false then
        HideAllSlots(container)
        container:Hide()
        if frame.unit then
            ns:AuraResolveCacheReset(frame.unit)
        end
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
        if frame.unit then
            ns:AuraResolveCacheReset(frame.unit)
        end
        return
    end

    local entries = CollectDisplayAuras(frame.unit, cfg)
    if not entries or #entries == 0 then
        container:Hide()
        return
    end

    local shown = 0
    local needRetry = false

    for i = 1, math.min(#entries, MAX_CENTER_DEBUFFS) do
        local entry = entries[i]
        local slot = container.slots[i]

        if entry and slot and entry.auraInstanceID then
            local visual = ResolveEntryVisual(entry)
            local r, g, b, a = GetAuraBorderColor(frame.unit, entry)

            ApplySlotVisual(slot, visual)
            slot.auraInstanceID = entry.auraInstanceID
            slot.__typeKey = entry.typeKey or "none"

            ShowBorder(slot, r, g, b, a)

            local countText
            if C_UnitAuras.GetAuraApplicationDisplayCount then
                countText = C_UnitAuras.GetAuraApplicationDisplayCount(frame.unit, entry.auraInstanceID, 2, 999)
            end
            slot.count:SetText(countText or "")

            local durationInfo = C_UnitAuras.GetAuraDuration and
                C_UnitAuras.GetAuraDuration(frame.unit, entry.auraInstanceID)
            if durationInfo then
                slot.cd:SetCooldownFromDurationObject(durationInfo)
                slot.cd:Show()
            else
                slot.cd:Hide()
            end

            slot:Show()
            shown = shown + 1
            if entry.resolved ~= true and entry.learned ~= true then
                needRetry = true
            end
        end
    end

    if shown > 0 then
        AlignVisibleSlots(container)
        container:Show()

        if needRetry then
            ns:AuraResolveCacheRequestRetry(frame.unit)
        else
            ns:AuraResolveCacheClearRetry(frame.unit)
        end
        DebugLog("SHOW", frame.unit, "shown", shown)
    else
        container:Hide()
        ns:AuraResolveCacheClearRetry(frame.unit)
        DebugLog("HIDE", frame.unit, "shown_zero_after_render")
    end
end
