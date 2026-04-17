local _, ns = ...

ns.uf = ns.uf or {}

local DEFAULT_SIZE = 14
local DEFAULT_ANCHOR = "TOPLEFT"
local printedPreviewWarnings = {}
local spellTextureCache = {}

local function IsRaidFrame(frame)
    return frame and frame.__isRaidFrame
end

local function GetIndicatorSettings(frame)
    local cfg = ns:GetUnitFrameConfig(frame)
    return cfg and cfg.indicatorSettings
end

local function GetIndicators(frame)
    local cfg = ns:GetUnitFrameConfig(frame)
    if not cfg then
        return nil
    end

    cfg.classIndicators = cfg.classIndicators or {}

    local _, classTag = UnitClass("player")
    cfg.classIndicators[classTag] = cfg.classIndicators[classTag] or {}

    return cfg.classIndicators[classTag]
end

local function GetEntryEnabled(entry, frame)
    if not entry then
        return false
    end

    if IsRaidFrame(frame) then
        if entry.raidEnabled ~= nil then
            return entry.raidEnabled
        end
    else
        if entry.partyEnabled ~= nil then
            return entry.partyEnabled
        end
    end

    if entry.enabled == nil then
        return true
    end

    return not not entry.enabled
end

local function GetEntryAnchor(entry, frame)
    if not entry then
        return DEFAULT_ANCHOR
    end

    if IsRaidFrame(frame) then
        return entry.raidAnchor or entry.anchor or DEFAULT_ANCHOR
    end

    return entry.partyAnchor or entry.anchor or DEFAULT_ANCHOR
end

local function GetEntryX(entry, frame)
    if not entry then
        return 0
    end

    if IsRaidFrame(frame) then
        local value = entry.raidX
        if value == nil then
            value = entry.x
        end
        return tonumber(value) or 0
    end

    local value = entry.partyX
    if value == nil then
        value = entry.x
    end
    return tonumber(value) or 0
end

local function GetEntryY(entry, frame)
    if not entry then
        return 0
    end

    if IsRaidFrame(frame) then
        local value = entry.raidY
        if value == nil then
            value = entry.y
        end
        return tonumber(value) or 0
    end

    local value = entry.partyY
    if value == nil then
        value = entry.y
    end
    return tonumber(value) or 0
end

local function GetEntrySize(entry, frame, settings)
    if not entry then
        return (settings and settings.size) or DEFAULT_SIZE
    end

    if IsRaidFrame(frame) then
        local value = entry.raidSize
        if value == nil then
            value = entry.size
        end
        return tonumber(value) or (settings and settings.size) or DEFAULT_SIZE
    end

    local value = entry.partySize
    if value == nil then
        value = entry.size
    end
    return tonumber(value) or (settings and settings.size) or DEFAULT_SIZE
end

local function GetSpellInfoSafe(spellID)
    if not spellID then
        return nil
    end

    if C_Spell and C_Spell.GetSpellInfo then
        return C_Spell.GetSpellInfo(spellID)
    end

    return nil
end

local function GetSpellTextureSafe(spellID)
    if not spellID then
        return 136243
    end

    local cached = spellTextureCache[spellID]
    if cached ~= nil then
        return cached
    end

    local info = GetSpellInfoSafe(spellID)
    if info and info.iconID then
        spellTextureCache[spellID] = info.iconID
        return info.iconID
    end

    if not printedPreviewWarnings[spellID] then
        printedPreviewWarnings[spellID] = true
        print("아이콘 조회 실패 등록할 수 없는 주문입니다. 미리보기 중이시면 끄고 삭제 권장합니다.spellID:", spellID)
    end

    spellTextureCache[spellID] = 136243
    return 136243
end

local function HideCooldown(button)
    if button and button.cd then
        button.cd:Hide()
    end
end

local function HideButton(button)
    if not button then
        return
    end

    if button.count then
        button.count:SetText("")
    end

    if button.icon then
        button.icon:SetTexture(nil)
        button.icon:SetDesaturated(false)
        button.icon:SetAlpha(1)
    end

    button.auraInstanceID = nil
    button.__hrLastShown = nil
    button.__hrLastAuraInstanceID = nil
    HideCooldown(button)
    button:Hide()
end

local function HideExtraButtons(frame, maxIndex)
    if not frame or not frame.IndicatorButtons then
        return
    end

    for i = maxIndex + 1, #frame.IndicatorButtons do
        HideButton(frame.IndicatorButtons[i])
    end
end

local function UpdateStackText(button, unit, auraInstanceID, indicator)
    if not button or not button.count then
        return
    end

    if not indicator or not indicator.showStack or not unit or not auraInstanceID then
        button.count:SetText("")
        return
    end

    local countText = C_UnitAuras.GetAuraApplicationDisplayCount(unit, auraInstanceID, 2, 999)
    button.count:SetText(countText or "")
end

local function UpdateIndicatorCooldown(button, unit, auraInstanceID)
    if not button or not button.cd then
        return
    end

    if not unit or not auraInstanceID or not C_UnitAuras or not C_UnitAuras.GetAuraDuration then
        button.cd:Hide()
        return
    end

    local durationInfo = C_UnitAuras.GetAuraDuration(unit, auraInstanceID)
    if durationInfo then
        button.cd:SetCooldownFromDurationObject(durationInfo)
        button.cd:Show()
    else
        button.cd:Hide()
    end
end

--[[local function IsAuraFromPlayer(aura)
    if not aura then
        return false
    end

    if aura.isFromPlayerOrPlayerPet ~= nil then
        return aura.isFromPlayerOrPlayerPet and true or false
    end

    return aura.sourceUnit == "player"
end

local function EntryMatchesSpellID(entry, spellID)
    if not entry or not spellID then
        return false
    end

    if tonumber(entry.spellID) == tonumber(spellID) then
        return true
    end

    if type(entry.includeIDs) == "table" then
        for _, includedID in ipairs(entry.includeIDs) do
            if tonumber(includedID) == tonumber(spellID) then
                return true
            end
        end
    end

    return false
end


local function IsBetterAura(candidate, current, entry)
    if not candidate then
        return false
    end

    if not current then
        return true
    end

    local onlyMine = entry and entry.onlyMine and true or false

    local candMine = IsAuraFromPlayer(candidate)
    local currMine = IsAuraFromPlayer(current)

    if onlyMine then
        if candMine ~= currMine then
            return candMine
        end
    else
        if candMine ~= currMine then
            return candMine
        end
    end

    local candStacks = candidate.applications or candidate.charges or 0
    local currStacks = current.applications or current.charges or 0
    if candStacks ~= currStacks then
        return candStacks > currStacks
    end

    local candExp = candidate.expirationTime or 0
    local currExp = current.expirationTime or 0
    if candExp ~= currExp then
        return candExp > currExp
    end

    local candID = candidate.auraInstanceID or 0
    local currID = current.auraInstanceID or 0
    return candID > currID
end]]

local function GetAuraBySpellID(unit, spellID, onlyMine)
    if not unit or not spellID then
        return nil
    end

    local aura = nil

    if AuraUtil and AuraUtil.FindAuraBySpellID then
        aura = AuraUtil.FindAuraBySpellID(spellID, unit, "HELPFUL")
    end

    if not aura and C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID then
        aura = C_UnitAuras.GetUnitAuraBySpellID(unit, spellID)
    end

    if not aura then
        return nil
    end

    if onlyMine then
        local sourceUnit = aura.sourceUnit

        if sourceUnit == "player" or sourceUnit == "pet" or sourceUnit == "vehicle" then
            return aura
        end

        return nil
    end

    return aura
end

local function FindBestAuraForIndicator(unit, entry, onlyMine)
    if not unit or not entry or not entry.spellID then
        return nil
    end

    if not UnitExists(unit) then
        return nil
    end

    local aura = GetAuraBySpellID(unit, entry.spellID, onlyMine)
    if aura then
        return aura
    end

    if type(entry.includeIDs) == "table" then
        for i = 1, #entry.includeIDs do
            local includedID = tonumber(entry.includeIDs[i])
            if includedID then
                aura = GetAuraBySpellID(unit, includedID, onlyMine)
                if aura then
                    return aura
                end
            end
        end
    end

    return nil
end

local function ApplyButtonLayout(button, frame, indicator, settings)
    if not button or not frame or not indicator then
        return
    end

    local size = GetEntrySize(indicator, frame, settings)
    local anchor = GetEntryAnchor(indicator, frame)
    local x = GetEntryX(indicator, frame)
    local y = GetEntryY(indicator, frame)

    button:ClearAllPoints()
    button:SetPoint(anchor, frame, anchor, x, y)
    button:SetSize(size, size)

    if button.count then
        local countSize = indicator.stackSize or 12
        local stackAnchor = indicator.stackAnchor or "BOTTOMRIGHT"
        local stackX = indicator.stackX or -2
        local stackY = indicator.stackY or 2

        button.count:SetFont(STANDARD_TEXT_FONT, countSize, "OUTLINE")
        button.count:ClearAllPoints()
        button.count:SetPoint(stackAnchor, button, stackAnchor, stackX, stackY)
    end
end

local function EnsureButton(frame, index)
    frame.IndicatorButtons = frame.IndicatorButtons or {}

    if frame.IndicatorButtons[index] then
        return frame.IndicatorButtons[index]
    end

    local button = CreateFrame("Frame", nil, frame)
    button:SetFrameLevel(frame:GetFrameLevel() + 50)
    button:SetSize(DEFAULT_SIZE, DEFAULT_SIZE)
    button:Hide()

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon = icon

    local count = button:CreateFontString(nil, "OVERLAY")
    count:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    count:SetJustifyH("RIGHT")
    count:SetText("")
    button.count = count

    local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cd:SetAllPoints()
    cd:SetReverse(true)
    cd:SetDrawEdge(false)
    cd:SetDrawBling(false)
    button.cd = cd

    frame.IndicatorButtons[index] = button
    return button
end

function ns.uf:CreateIndicators(frame)
    if not frame then
        return
    end

    local indicators = GetIndicators(frame) or {}
    frame.IndicatorButtons = frame.IndicatorButtons or {}

    for i = 1, #indicators do
        EnsureButton(frame, i)
    end
end

local function BuildIndicatorLayoutKey(frame, settings, indicators)
    if not settings then
        return "disabled"
    end

    local parts = {
        tostring(settings.enabled),
        tostring(settings.size),
        tostring(#indicators),
        tostring(IsRaidFrame(frame) and "raid" or "party"),
    }

    for i = 1, #indicators do
        local entry = indicators[i]
        parts[#parts + 1] = table.concat({
            tostring(entry and entry.spellID),
            tostring(entry and GetEntryEnabled(entry, frame)),
            tostring(entry and GetEntryAnchor(entry, frame)),
            tostring(entry and GetEntryX(entry, frame)),
            tostring(entry and GetEntryY(entry, frame)),
            tostring(entry and GetEntrySize(entry, frame, settings)),
            tostring(entry and entry.stackAnchor),
            tostring(entry and entry.stackX),
            tostring(entry and entry.stackY),
            tostring(entry and entry.stackSize),
        }, ":")
    end

    return table.concat(parts, "|")
end

function ns.uf:ApplyIndicatorSettings(frame, force)
    if not frame then
        return
    end

    local settings = GetIndicatorSettings(frame)
    local indicators = GetIndicators(frame) or {}
    if not settings then
        frame.__indicatorLayoutKey = nil
        frame.__indicatorsInitialized = nil
        return
    end

    self:CreateIndicators(frame)

    local layoutKey = BuildIndicatorLayoutKey(frame, settings, indicators)
    if not force and frame.__indicatorLayoutKey == layoutKey then
        return
    end

    for i = 1, #indicators do
        local indicator = indicators[i]
        local button = frame.IndicatorButtons and frame.IndicatorButtons[i]
        if button and indicator then
            ApplyButtonLayout(button, frame, indicator, settings)
        end
    end

    HideExtraButtons(frame, #indicators)
    frame.__indicatorLayoutKey = layoutKey
    frame.__indicatorsInitialized = true
end

function ns.uf:UpdateIndicatorPreview(frame)
    if not frame then
        return
    end

    local settings = GetIndicatorSettings(frame)
    local indicators = GetIndicators(frame) or {}

    if not settings or not settings.enabled or not settings.preview then
        return
    end

    self:CreateIndicators(frame)
    self:ApplyIndicatorSettings(frame)

    for i = 1, #indicators do
        local entry = indicators[i]
        local button = frame.IndicatorButtons and frame.IndicatorButtons[i]
        if button and entry then
            if not GetEntryEnabled(entry, frame) then
                HideButton(button)
            else
                local previewStates = ns.previewIndicatorStates or {}
                local spellID = entry.spellID

                if next(previewStates) and not previewStates[spellID] then
                    HideButton(button)
                else
                    local mode = entry.displayMode or "present"
                    local icon = GetSpellTextureSafe(entry.spellID)

                    if mode == "present" then
                        if icon then
                            button.icon:SetTexture(icon)
                            button.icon:SetDesaturated(false)
                            button.icon:SetAlpha(1)
                            button.count:SetText("")

                            if entry.showStack then
                                local stackAnchor = entry.stackAnchor or "BOTTOMRIGHT"
                                local stackX = entry.stackX or -2
                                local stackY = entry.stackY or 2
                                local stackSize = entry.stackSize or 12

                                button.count:ClearAllPoints()
                                button.count:SetPoint(stackAnchor, button, stackAnchor, stackX, stackY)
                                button.count:SetFont(STANDARD_TEXT_FONT, stackSize, "OUTLINE")
                                button.count:SetText("3")
                            else
                                button.count:SetText("")
                            end

                            UpdateIndicatorCooldown(button, frame.unit, nil)
                            button:Show()
                        else
                            HideButton(button)
                        end
                    elseif mode == "missing" then
                        if icon then
                            button.icon:SetTexture(icon)
                            button.icon:SetDesaturated(false)
                            button.icon:SetAlpha(1)
                            button.count:SetText("")
                            UpdateIndicatorCooldown(button, frame.unit, nil)
                            button:Show()
                        else
                            HideButton(button)
                        end
                    else
                        HideButton(button)
                    end
                end
            end
        end
    end

    HideExtraButtons(frame, #indicators)
end

function ns.uf:UpdateUnitIndicators(frame)
    if not frame or not frame.unit then
        return
    end

    local settings = GetIndicatorSettings(frame)
    local indicators = GetIndicators(frame) or {}

    if not settings or not settings.enabled then
        HideExtraButtons(frame, 0)
        frame.__hrIndicatorAuraKey = nil
        return
    end

    if not UnitExists(frame.unit) then
        HideExtraButtons(frame, 0)
        frame.__hrIndicatorAuraKey = nil
        return
    end

    if not frame.__indicatorsInitialized then
        self:CreateIndicators(frame)
        self:ApplyIndicatorSettings(frame, true)
    end

    if settings.preview then
        self:UpdateIndicatorPreview(frame)
        frame.__hrIndicatorAuraKey = "preview"
        return
    end

    local auraKeyParts = { frame.unit, tostring(IsRaidFrame(frame) and "raid" or "party") }

    for i = 1, #indicators do
        local entry = indicators[i]
        auraKeyParts[#auraKeyParts + 1] = table.concat({
            tostring(entry and entry.spellID or 0),
            tostring(entry and GetEntryEnabled(entry, frame) or false),
            tostring(entry and GetEntryAnchor(entry, frame) or ""),
            tostring(entry and GetEntryX(entry, frame) or 0),
            tostring(entry and GetEntryY(entry, frame) or 0),
            tostring(entry and GetEntrySize(entry, frame, settings) or 0),
        }, ":")
    end

    local auraKey = table.concat(auraKeyParts, ":")

    if frame.__hrIndicatorAuraKey == auraKey then
        return
    end

    frame.__hrIndicatorAuraKey = auraKey

    for i, entry in ipairs(indicators) do
        local button = frame.IndicatorButtons and frame.IndicatorButtons[i]
        if button and entry then
            if not GetEntryEnabled(entry, frame) then
                HideButton(button)
            else
                local mode = entry.displayMode or "present"
                local onlyMine = entry.onlyMine
                if onlyMine == nil then
                    onlyMine = settings.onlyMine
                end

                local aura = FindBestAuraForIndicator(frame.unit, entry, onlyMine)

                if aura and aura.auraInstanceID then
                    if mode == "missing" then
                        HideButton(button)
                    else
                        local auraID = aura.auraInstanceID
                        local iconTex = aura.icon or GetSpellTextureSafe(entry.spellID)

                        if button.__hrLastAuraInstanceID ~= auraID then
                            button.icon:SetTexture(iconTex)
                            button.icon:SetDesaturated(false)
                            button.icon:SetAlpha(1)
                            button.auraInstanceID = auraID
                            button.__hrLastAuraInstanceID = auraID
                        end

                        UpdateStackText(button, frame.unit, auraID, entry)
                        UpdateIndicatorCooldown(button, frame.unit, auraID)

                        if not button.__hrLastShown then
                            button:Show()
                            button.__hrLastShown = true
                        else
                            button:Show()
                        end
                    end
                else
                    if mode == "missing" then
                        local icon = GetSpellTextureSafe(entry.spellID)
                        if icon then
                            if button.__hrLastAuraInstanceID ~= false then
                                button.icon:SetTexture(icon)
                                button.icon:SetDesaturated(false)
                                button.icon:SetAlpha(1)
                                button.auraInstanceID = nil
                                button.__hrLastAuraInstanceID = false
                            end
                            button.count:SetText("")
                            UpdateIndicatorCooldown(button, frame.unit, nil)
                            button:Show()
                            button.__hrLastShown = true
                        else
                            HideButton(button)
                        end
                    else
                        HideButton(button)
                    end
                end
            end
        end
    end

    HideExtraButtons(frame, #indicators)
end
