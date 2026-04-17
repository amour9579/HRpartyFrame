local _, ns = ...

ns.IndicatorOptions = ns.IndicatorOptions or {}
local I = ns.IndicatorOptions

local function GetPartyIndicatorSettings()
    local cfg = ns:GetPartyConfig()
    cfg.indicatorSettings = cfg.indicatorSettings or {}
    return cfg.indicatorSettings
end

local function GetRaidIndicatorSettings()
    local cfg = ns:GetRaidConfig()
    cfg.indicatorSettings = cfg.indicatorSettings or {}
    return cfg.indicatorSettings
end

local function GetCurrentClassIndicators()
    local cfg = ns:GetPartyConfig()
    cfg.classIndicators = cfg.classIndicators or {}

    local classTag = ns:GetCurrentClassTag()
    cfg.classIndicators[classTag] = cfg.classIndicators[classTag] or {}

    return cfg.classIndicators[classTag], classTag
end

local function NormalizeSharedEntry(entry)
    if type(entry) ~= "table" then
        return
    end

    local partySettings = GetPartyIndicatorSettings()
    local raidSettings = GetRaidIndicatorSettings()

    entry.partyAnchor = entry.partyAnchor or entry.anchor or "TOPLEFT"
    entry.partyX = tonumber(entry.partyX)
    if entry.partyX == nil then
        entry.partyX = tonumber(entry.x) or 2
    end
    entry.partyY = tonumber(entry.partyY)
    if entry.partyY == nil then
        entry.partyY = tonumber(entry.y) or -2
    end
    entry.partySize = tonumber(entry.partySize)
    if entry.partySize == nil then
        entry.partySize = tonumber(entry.size) or partySettings.size or 20
    end

    entry.raidAnchor = entry.raidAnchor or entry.anchor or entry.partyAnchor or "TOPLEFT"
    entry.raidX = tonumber(entry.raidX)
    if entry.raidX == nil then
        entry.raidX = tonumber(entry.x)
        if entry.raidX == nil then
            entry.raidX = entry.partyX or 2
        end
    end
    entry.raidY = tonumber(entry.raidY)
    if entry.raidY == nil then
        entry.raidY = tonumber(entry.y)
        if entry.raidY == nil then
            entry.raidY = entry.partyY or -2
        end
    end
    entry.raidSize = tonumber(entry.raidSize)
    if entry.raidSize == nil then
        entry.raidSize = tonumber(entry.size) or raidSettings.size or partySettings.size or 16
    end

    if entry.partyEnabled == nil then
        if entry.enabled == nil then
            entry.partyEnabled = true
        else
            entry.partyEnabled = not not entry.enabled
        end
    else
        entry.partyEnabled = not not entry.partyEnabled
    end

    if entry.raidEnabled == nil then
        if entry.enabled == nil then
            entry.raidEnabled = true
        else
            entry.raidEnabled = not not entry.enabled
        end
    else
        entry.raidEnabled = not not entry.raidEnabled
    end

    if entry.onlyMine == nil then
        entry.onlyMine = partySettings.onlyMine ~= false
    else
        entry.onlyMine = not not entry.onlyMine
    end

    if entry.showStack == nil then
        entry.showStack = true
    else
        entry.showStack = not not entry.showStack
    end

    entry.stackSize = tonumber(entry.stackSize)
        or (partySettings.stack and tonumber(partySettings.stack.size))
        or 20
    entry.stackAnchor = entry.stackAnchor
        or (partySettings.stack and partySettings.stack.anchor)
        or "CENTER"
    entry.stackX = tonumber(entry.stackX)
        or (partySettings.stack and tonumber(partySettings.stack.x))
        or 0
    entry.stackY = tonumber(entry.stackY)
        or (partySettings.stack and tonumber(partySettings.stack.y))
        or 0

    if entry.displayMode ~= "missing" then
        entry.displayMode = "present"
    end

    if type(entry.includeIDs) == "table" then
        local normalized = {}
        for i = 1, #entry.includeIDs do
            local includedID = tonumber(entry.includeIDs[i])
            if includedID and includedID > 0 then
                normalized[#normalized + 1] = includedID
            end
        end
        if #normalized > 0 then
            entry.includeIDs = normalized
        else
            entry.includeIDs = nil
        end
    else
        entry.includeIDs = nil
    end

    -- 구형 필드 호환용: 파티값을 대표값으로 유지
    entry.enabled = entry.partyEnabled
    entry.anchor = entry.partyAnchor
    entry.x = entry.partyX
    entry.y = entry.partyY
    entry.size = entry.partySize
end

function I.GetSelectableAuraValues()
    return I.GetRemovableAuraValues()
end

function I.GetSelectableSpellList()
    local result = {}
    local indicators = I.GetActiveIndicators()

    for _, entry in ipairs(indicators) do
        local spellID = tonumber(entry.spellID)
        if spellID then
            table.insert(result, spellID)
        end
    end

    return result
end

function I.DisableAllPreviewAuras()
    ns.previewIndicatorStates = {}

    local partySettings = GetPartyIndicatorSettings()
    local raidSettings = GetRaidIndicatorSettings()

    partySettings.preview = false
    raidSettings.preview = false
end

function I.GetSpellDisplayName(spellID)
    local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
    if name and name ~= "" then
        return name
    end

    if GetSpellInfo then
        local oldName = GetSpellInfo(spellID)
        if oldName and oldName ~= "" then
            return oldName
        end
    end

    return tostring(spellID)
end

function I.ResolveSpellID(input)
    if not input or input == "" then
        return nil
    end

    local numeric = tonumber(input)
    if numeric then
        return numeric
    end

    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(input)
        if info and info.spellID then
            return info.spellID
        end
    end

    return nil
end

function I.GetActiveIndicators()
    return GetCurrentClassIndicators()
end

function I.FindIndicatorBySpellID(spellID)
    local indicators = I.GetActiveIndicators()

    for i = 1, #indicators do
        if indicators[i].spellID == spellID then
            return indicators[i], i
        end
    end
end

function I.SortIndicatorsByCatalog()
    local indicators, classTag = I.GetActiveIndicators()
    local catalog = ns.ClassAuraCatalog and ns.ClassAuraCatalog[classTag]

    if not catalog then
        table.sort(indicators, function(a, b)
            return (a.spellID or 0) < (b.spellID or 0)
        end)
        return
    end

    local orderMap = {}
    for index, aura in ipairs(catalog) do
        orderMap[aura.spellID] = index
    end

    table.sort(indicators, function(a, b)
        local aOrder = orderMap[a.spellID] or 999999
        local bOrder = orderMap[b.spellID] or 999999

        if aOrder == bOrder then
            return (a.spellID or 0) < (b.spellID or 0)
        end

        return aOrder < bOrder
    end)
end

function I.ResetCurrentClassIndicatorsFromCatalog()
    local indicators, classTag = I.GetActiveIndicators()
    local catalog = ns.ClassAuraCatalog and ns.ClassAuraCatalog[classTag]
    if not catalog then
        return
    end

    local partySettings = GetPartyIndicatorSettings()
    local raidSettings = GetRaidIndicatorSettings()

    wipe(indicators)

    for _, aura in ipairs(catalog) do
        local entry = {
            spellID = aura.spellID,
            includeIDs = nil,

            partyEnabled = true,
            raidEnabled = true,

            partyAnchor = aura.anchor or "TOPLEFT",
            partyX = aura.x or 2,
            partyY = aura.y or -2,
            partySize = aura.size or partySettings.size or 20,

            raidAnchor = aura.raidAnchor or aura.anchor or "TOPLEFT",
            raidX = (aura.raidX ~= nil) and aura.raidX or (aura.x or 2),
            raidY = (aura.raidY ~= nil) and aura.raidY or (aura.y or -2),
            raidSize = aura.raidSize or raidSettings.size or aura.size or 16,

            onlyMine = (aura.onlyMine ~= nil) and aura.onlyMine or (partySettings.onlyMine ~= false),
            showStack = true,
            stackSize = (partySettings.stack and partySettings.stack.size) or 20,
            stackAnchor = (partySettings.stack and partySettings.stack.anchor) or "CENTER",
            stackX = (partySettings.stack and partySettings.stack.x) or 0,
            stackY = (partySettings.stack and partySettings.stack.y) or 0,
            displayMode = aura.displayMode or "present",
        }

        NormalizeSharedEntry(entry)
        table.insert(indicators, entry)
    end

    I.SortIndicatorsByCatalog()

    if partySettings.filterType == "class" then
        if catalog[1] then
            partySettings.selectedSpellID = catalog[1].spellID
        else
            partySettings.selectedSpellID = nil
        end
    end
end

function I.EnsureIndicatorDefaults(entry, settings)
    if type(entry) ~= "table" then
        return
    end

    NormalizeSharedEntry(entry)
end

function I.GetClassAuraValues()
    local values = {}
    local indicators, classTag = I.GetActiveIndicators()
    local catalog = ns.ClassAuraCatalog and ns.ClassAuraCatalog[classTag]

    if not catalog then
        return values
    end

    local catalogMap = {}
    for _, aura in ipairs(catalog) do
        catalogMap[aura.spellID] = true
    end

    for _, entry in ipairs(indicators) do
        local spellID = tonumber(entry.spellID)
        if spellID and catalogMap[spellID] then
            values[tostring(spellID)] = string.format("%s [%d]", I.GetSpellDisplayName(spellID), spellID)
        end
    end

    return values
end

function I.GetCurrentClassRegisteredSpellList()
    local result = {}
    local indicators, classTag = I.GetActiveIndicators()
    local catalog = ns.ClassAuraCatalog and ns.ClassAuraCatalog[classTag]

    if not catalog then
        return result
    end

    local catalogOrder = {}
    for index, aura in ipairs(catalog) do
        catalogOrder[aura.spellID] = index
    end

    for _, entry in ipairs(indicators) do
        local spellID = tonumber(entry.spellID)
        if spellID and catalogOrder[spellID] then
            table.insert(result, spellID)
        end
    end

    table.sort(result, function(a, b)
        local aOrder = catalogOrder[a] or 999999
        local bOrder = catalogOrder[b] or 999999
        if aOrder == bOrder then
            return a < b
        end
        return aOrder < bOrder
    end)

    return result
end

function I.GetSelectedSpellID()
    local selected = ns:GetPartyConfig().indicatorSettings.selectedSpellID
    return selected and tonumber(selected) or nil
end

function I.SetSelectedSpellID(spellID)
    ns:GetPartyConfig().indicatorSettings.selectedSpellID = spellID and tonumber(spellID) or nil
end

function I.GetSelectedIndicator()
    local spellID = I.GetSelectedSpellID()
    if not spellID then
        return nil
    end

    local entry = I.FindIndicatorBySpellID(spellID)
    if entry then
        I.EnsureIndicatorDefaults(entry, GetPartyIndicatorSettings())
        return entry
    end

    return nil
end

function I.GetPreviewStateForSpell(spellID)
    return ns.previewIndicatorStates[spellID] == true
end

function I.UpdatePreviewFlag()
    local anyPreview = false

    for _, enabled in pairs(ns.previewIndicatorStates) do
        if enabled then
            anyPreview = true
            break
        end
    end

    GetPartyIndicatorSettings().preview = anyPreview
    GetRaidIndicatorSettings().preview = anyPreview
end

function I.AddIndicatorFromInput(inputValue)
    local partySettings = GetPartyIndicatorSettings()
    local raidSettings = GetRaidIndicatorSettings()
    local indicators = I.GetActiveIndicators()

    local spellID = I.ResolveSpellID(inputValue)
    if not spellID then
        ns:Print("잘못된 주문 이름 또는 ID 입니다.")
        return false
    end

    local entry = I.FindIndicatorBySpellID(spellID)
    if entry then
        ns:Print("이미 등록된 버프입니다.")
        I.SetSelectedSpellID(spellID)
        partySettings.filterType = "class"
        ns:RefreshOptions()
        return false
    end

    local newEntry = {
        spellID = spellID,
        includeIDs = nil,

        partyEnabled = true,
        raidEnabled = true,

        partyAnchor = "TOPLEFT",
        partyX = 2,
        partyY = -2,
        partySize = partySettings.size or 20,

        raidAnchor = "TOPLEFT",
        raidX = 2,
        raidY = -2,
        raidSize = raidSettings.size or 16,

        onlyMine = partySettings.onlyMine,
        showStack = true,
        stackSize = (partySettings.stack and partySettings.stack.size) or 20,
        stackAnchor = (partySettings.stack and partySettings.stack.anchor) or "CENTER",
        stackX = (partySettings.stack and partySettings.stack.x) or 0,
        stackY = (partySettings.stack and partySettings.stack.y) or 0,
        displayMode = "present",
    }

    NormalizeSharedEntry(newEntry)
    table.insert(indicators, newEntry)

    I.SortIndicatorsByCatalog()

    ns.pendingIndicatorInput = ""
    I.SetSelectedSpellID(spellID)
    partySettings.filterType = "class"

    ns:RefreshOptions()
    ns:SafeRefresh()
    ns:Print("버프 추가: " .. I.GetSpellDisplayName(spellID))
    return true
end

function I.RemoveIndicatorBySpellID(spellID)
    local cfg = ns:GetPartyConfig()
    local indicators = I.GetActiveIndicators()
    if not spellID then
        return
    end

    local _, index = I.FindIndicatorBySpellID(spellID)
    if index then
        table.remove(indicators, index)
    end

    ns.previewIndicatorStates[spellID] = nil
    I.UpdatePreviewFlag()

    if cfg.indicatorSettings.selectedSpellID == spellID then
        cfg.indicatorSettings.selectedSpellID = nil

        local spellList = I.GetCurrentClassRegisteredSpellList()
        if #spellList > 0 then
            cfg.indicatorSettings.selectedSpellID = spellList[1]
        end
    end

    ns:RefreshOptions()
    ns:SafeRefresh()
    ns:Print("버프 삭제: " .. I.GetSpellDisplayName(spellID))
end

function I.ShowRemoveIndicatorPopup(spellID)
    if not spellID then
        return
    end

    StaticPopupDialogs["HRPARTYFRAME_CONFIRM_REMOVE_AURA"] = StaticPopupDialogs["HRPARTYFRAME_CONFIRM_REMOVE_AURA"] or {
        text = "이 오라를 제거할까요?\n|cffffff00%s|r",
        button1 = YES,
        button2 = NO,
        OnAccept = function(_, data)
            I.RemoveIndicatorBySpellID(data)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    local dialog = StaticPopup_Show(
        "HRPARTYFRAME_CONFIRM_REMOVE_AURA",
        string.format("%s [%d]", I.GetSpellDisplayName(spellID), spellID),
        nil,
        spellID
    )

    if dialog then
        dialog:SetFrameStrata("TOOLTIP")
        dialog:SetFrameLevel(400)
    end
end

function I.GetRemovableAuraValues()
    local values = {}
    local indicators = I.GetActiveIndicators()

    for _, entry in ipairs(indicators) do
        local spellID = tonumber(entry.spellID)
        if spellID then
            values[tostring(spellID)] = string.format("%s [%d]", I.GetSpellDisplayName(spellID), spellID)
        end
    end

    return values
end
