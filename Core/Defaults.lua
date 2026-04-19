local _, ns = ...

local configInitialized = false

local defaults = {
    party = {
        width = 170,
        height = 45,
        spacing = 3,

        unitframes = {
            nameFont = "default",
            nameFontSize = 12,
            namePoint = "CENTER",
            nameX = 0,
            nameY = 0,
        },

        point = "TOP",
        relativePoint = "TOP",
        x = 370,
        y = -510,

        showPlayer = true,
        showSolo = true,

        rangeCheck = true,
        rangeThreshold = 40,
        outOfRangeAlpha = 20,
        rangeFrequency = 0.2,

        indicatorSettings = {
            enabled = true,
            size = 20,
            onlyMine = true,
            showStack = true,
            preview = false,

            filterType = "none",
            selectedSpellID = nil,

            stack = {
                anchor = "CENTER",
                x = 20,
                y = 0,
                size = 20,
            },
        },

        raidTarget = {
            enabled = true,
            size = 18,
            anchor = "TOP",
            x = 0,
            y = 10,
        },
        classIndicators = {
            DRUID = {
                {
                    spellID = 33763,
                    partyEnabled = true,
                    raidEnabled = true,
                    partyAnchor = "TOPLEFT",
                    partyX = 2,
                    partyY = -1,
                    partySize = 20,
                    raidAnchor = "TOPLEFT",
                    raidX = 1,
                    raidY = -1,
                    raidSize = 16,
                    onlyMine = true,
                    displayMode = "present",
                },
                {
                    spellID = 48438,
                    partyEnabled = true,
                    raidEnabled = true,
                    partyAnchor = "BOTTOMLEFT",
                    partyX = 2,
                    partyY = 1,
                    partySize = 20,
                    raidAnchor = "BOTTOMLEFT",
                    raidX = 1,
                    raidY = 1,
                    raidSize = 16,
                    onlyMine = true,
                    displayMode = "present",
                },
                {
                    spellID = 8936,
                    partyEnabled = true,
                    raidEnabled = true,
                    partyAnchor = "BOTTOMRIGHT",
                    partyX = -2,
                    partyY = 1,
                    partySize = 20,
                    raidAnchor = "BOTTOMRIGHT",
                    raidX = -1,
                    raidY = 1,
                    raidSize = 16,
                    onlyMine = true,
                    displayMode = "present",
                },
                {
                    spellID = 774,
                    partyEnabled = true,
                    raidEnabled = true,
                    partyAnchor = "TOPRIGHT",
                    partyX = -2,
                    partyY = -1,
                    partySize = 20,
                    raidAnchor = "TOPRIGHT",
                    raidX = -1,
                    raidY = -1,
                    raidSize = 16,
                    onlyMine = true,
                    displayMode = "present",
                },
                {
                    spellID = 155777,
                    partyEnabled = true,
                    raidEnabled = false,
                    partyAnchor = "TOPRIGHT",
                    partyX = -25,
                    partyY = -1,
                    partySize = 20,
                    raidAnchor = "TOPRIGHT",
                    raidX = -25,
                    raidY = -1,
                    raidSize = 16,
                    onlyMine = true,
                    displayMode = "present",
                },
            },
        },

        power = {
            enabled = false,
            height = 6,
        },

        debuff = {
            size = 30,
            anchor = "CENTER",
            x = 0,
            y = 0,
            hideUtilityDebuffs = true,
            preview = false,
            iconBorderThickness = 2,
            frameBorderThickness = 1,
            onlyDispellable = true,

            showMagic = true,
            showCurse = true,
            showDisease = true,
            showPoison = true,
            showNone = true,
            showBleed = true,

            showPrivateAuras = true,
            privateAuraAnchor = "RIGHT",
        },

        statusIcons = {
            enabled = true,
            preview = false,

            role = {
                enabled = true,
                size = 15,
                anchor = "LEFT",
                x = 5,
                y = 0,
            },

            leader = {
                enabled = true,
                size = 15,
                anchor = "TOPRIGHT",
                x = 2,
                y = 12,
            },

            summon = {
                enabled = true,
                size = 45,
                anchor = "CENTER",
                x = 0,
                y = 0,
            },

            rez = {
                enabled = true,
                size = 25,
                anchor = "CENTER",
                x = 0,
                y = 0,
            },
            
        },
        healAbsorb = {
            enabled = true,
            side = "right",     -- left / right
            texture = "shield", -- shield / flat / normtex
        },
    },

    raid = {
        enabled = true,

        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        x = 20,
        y = -300,

        showPlayer = true,

        layoutMode = "auto",
        previewVisible = true,

        width20 = 100,
        height20 = 40,
        spacingX20 = 4,
        spacingY20 = 4,
        
        width40 = 80,
        height40 = 30,
        spacingX40 = 3,
        spacingY40 = 3,
        
        sortMethod = "INDEX",

        unitframes = {
            nameFont = "default",

            nameFontSize20 = 11,
            namePoint20 = "CENTER",
            nameX20 = 0,
            nameY20 = 0,

            nameFontSize40 = 10,
            namePoint40 = "CENTER",
            nameX40 = 0,
            nameY40 = 0,
        },

        indicatorSettings = {
            enabled = true,
            size = 16,
            onlyMine = true,
            showStack = true,
            preview = false,

            filterType = "none",
            selectedSpellID = nil,

            stack = {
                anchor = "CENTER",
                x = 16,
                y = 0,
                size = 14,
            },
        },

        raidTarget = {
            enabled = true,
            size = 14,
            anchor = "TOP",
            x = 0,
            y = 8,
        },
        classIndicators = {
            DRUID = {
                {
                    spellID = 33763,
                    partyEnabled = true,
                    raidEnabled = true,
                    partyAnchor = "TOPLEFT",
                    partyX = 2,
                    partyY = -1,
                    partySize = 20,
                    raidAnchor = "TOPLEFT",
                    raidX = 1,
                    raidY = -1,
                    raidSize = 16,
                    onlyMine = true,
                    displayMode = "present",
                },
                {
                    spellID = 48438,
                    partyEnabled = true,
                    raidEnabled = true,
                    partyAnchor = "BOTTOMLEFT",
                    partyX = 2,
                    partyY = 1,
                    partySize = 20,
                    raidAnchor = "BOTTOMLEFT",
                    raidX = 1,
                    raidY = 1,
                    raidSize = 16,
                    onlyMine = true,
                    displayMode = "present",
                },
                {
                    spellID = 8936,
                    partyEnabled = true,
                    raidEnabled = true,
                    partyAnchor = "BOTTOMRIGHT",
                    partyX = -2,
                    partyY = 1,
                    partySize = 20,
                    raidAnchor = "BOTTOMRIGHT",
                    raidX = -1,
                    raidY = 1,
                    raidSize = 16,
                    onlyMine = true,
                    displayMode = "present",
                },
                {
                    spellID = 774,
                    partyEnabled = true,
                    raidEnabled = true,
                    partyAnchor = "TOPRIGHT",
                    partyX = -2,
                    partyY = -1,
                    partySize = 20,
                    raidAnchor = "TOPRIGHT",
                    raidX = -1,
                    raidY = -1,
                    raidSize = 16,
                    onlyMine = true,
                    displayMode = "present",
                },
                {
                    spellID = 155777,
                    partyEnabled = true,
                    raidEnabled = false,
                    partyAnchor = "TOPRIGHT",
                    partyX = -25,
                    partyY = -1,
                    partySize = 20,
                    raidAnchor = "TOPRIGHT",
                    raidX = -25,
                    raidY = -1,
                    raidSize = 16,
                    onlyMine = true,
                    displayMode = "present",
                },
            },
        },

        debuff = {
            size = 30,
            anchor = "CENTER",
            x = 0,
            y = 0,
            hideUtilityDebuffs = true,
            preview = false,
            iconBorderThickness = 2,
            frameBorderThickness = 1,
            onlyDispellable = true,

            showMagic = true,
            showCurse = true,
            showDisease = true,
            showPoison = true,
            showNone = true,
            showBleed = true,

            showPrivateAuras = true,
            privateAuraAnchor = "RIGHT",
        },

        statusIcons = {
            enabled = true,
            preview = false,

            role = {
                enabled = true,
                size = 12,
                anchor = "LEFT",
                x = 3,
                y = 0,
            },

            leader = {
                enabled = true,
                size = 12,
                anchor = "TOPRIGHT",
                x = 1,
                y = 8,
            },

            summon = {
                enabled = true,
                size = 35,
                anchor = "CENTER",
                x = 0,
                y = 0,
            },

            rez = {
                enabled = true,
                size = 18,
                anchor = "CENTER",
                x = 0,
                y = 0,
            },
        },
    },

    window = {
        width = 950,
        height = 600,
        x = 0,
        y = 0,
    },
}

local function IsArray(tbl)
    if type(tbl) ~= "table" then
        return false
    end

    local count = 0
    for k in pairs(tbl) do
        if type(k) ~= "number" then
            return false
        end
        count = count + 1
    end

    return count > 0
end

local function DeepCopy(src)
    if type(src) ~= "table" then
        return src
    end

    local dst = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = DeepCopy(v)
        else
            dst[k] = v
        end
    end
    return dst
end

local function CopyDefaults(src, dst)
    if type(src) ~= "table" then
        return dst
    end

    if type(dst) ~= "table" then
        dst = {}
    end

    for k, v in pairs(src) do
        if type(v) == "table" then
            if IsArray(v) then
                if dst[k] == nil then
                    dst[k] = DeepCopy(v)
                end
            else
                dst[k] = CopyDefaults(v, dst[k])
            end
        else
            if dst[k] == nil then
                dst[k] = v
            end
        end
    end

    return dst
end

local function GetCurrentClassTag()
    local _, classTag = UnitClass("player")
    return classTag
end

local function NormalizeIndicatorEntry(entry, partySettings, raidSettings)
    if type(entry) ~= "table" then
        return nil
    end

    local spellID = tonumber(entry.spellID)
    if not spellID then
        return nil
    end

    partySettings = partySettings or {}
    raidSettings = raidSettings or {}

    local partyStack = partySettings.stack or {}
    local raidStack = raidSettings.stack or {}

    entry.spellID = spellID

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

    -- 기존 UI 호환용 공용 필드 유지 (기본은 파티 기준)
    entry.enabled = entry.partyEnabled
    entry.anchor = entry.partyAnchor
    entry.x = entry.partyX
    entry.y = entry.partyY
    entry.size = entry.partySize

    if entry.onlyMine == nil then
        if partySettings.onlyMine ~= nil then
            entry.onlyMine = partySettings.onlyMine
        elseif raidSettings.onlyMine ~= nil then
            entry.onlyMine = raidSettings.onlyMine
        else
            entry.onlyMine = true
        end
    else
        entry.onlyMine = not not entry.onlyMine
    end

    if entry.showStack == nil then
        if partySettings.showStack ~= nil then
            entry.showStack = partySettings.showStack
        elseif raidSettings.showStack ~= nil then
            entry.showStack = raidSettings.showStack
        else
            entry.showStack = true
        end
    else
        entry.showStack = not not entry.showStack
    end

    entry.stackSize = tonumber(entry.stackSize)
        or tonumber(partyStack.size)
        or tonumber(raidStack.size)
        or 20

    entry.stackAnchor = entry.stackAnchor
        or partyStack.anchor
        or raidStack.anchor
        or "CENTER"

    entry.stackX = tonumber(entry.stackX)
    if entry.stackX == nil then
        entry.stackX = tonumber(partyStack.x)
        if entry.stackX == nil then
            entry.stackX = tonumber(raidStack.x) or 0
        end
    end

    entry.stackY = tonumber(entry.stackY)
    if entry.stackY == nil then
        entry.stackY = tonumber(partyStack.y)
        if entry.stackY == nil then
            entry.stackY = tonumber(raidStack.y) or 0
        end
    end

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

    return entry
end

local function SortClassIndicatorsByCatalog(classTag, indicators)
    indicators = indicators or {}

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

local function NormalizeConfigIndicators(cfg)
    cfg.indicatorSettings = cfg.indicatorSettings or {}

    local settings = cfg.indicatorSettings
    settings.enabled = settings.enabled ~= false
    settings.size = tonumber(settings.size) or 20
    settings.onlyMine = settings.onlyMine ~= false
    settings.showStack = settings.showStack ~= false
    settings.preview = settings.preview == true

    settings.filterType = settings.filterType or "none"
    if settings.filterType ~= "none" and settings.filterType ~= "class" then
        settings.filterType = "none"
    end

    settings.selectedSpellID = tonumber(settings.selectedSpellID) or nil

    settings.stack = settings.stack or {}
    settings.stack.anchor = settings.stack.anchor or "CENTER"
    settings.stack.x = tonumber(settings.stack.x) or 20
    settings.stack.y = tonumber(settings.stack.y) or 0
    settings.stack.size = tonumber(settings.stack.size) or 20

    cfg.classIndicators = cfg.classIndicators or {}

    local classTag = GetCurrentClassTag()
    cfg.classIndicators[classTag] = cfg.classIndicators[classTag] or {}

    if type(cfg.indicators) == "table" and #cfg.indicators > 0 then
        local target = cfg.classIndicators[classTag]
        if #target == 0 then
            for _, entry in ipairs(cfg.indicators) do
                table.insert(target, DeepCopy(entry))
            end
        end
        cfg.indicators = nil
    end
end

local function CopyIndicatorList(src, partySettings, raidSettings)
    local result = {}

    if type(src) ~= "table" then
        return result
    end

    for i = 1, #src do
        local entry = DeepCopy(src[i])
        entry = NormalizeIndicatorEntry(entry, partySettings, raidSettings)
        if entry then
            result[#result + 1] = entry
        end
    end

    return result
end

local function EnsureSharedClassIndicatorLists(db)
    local party = db.party or {}
    local raid = db.raid or {}

    party.classIndicators = party.classIndicators or {}
    raid.classIndicators = raid.classIndicators or {}

    local partySettings = party.indicatorSettings or {}
    local raidSettings = raid.indicatorSettings or {}

    local classTags = {}

    for tag in pairs(party.classIndicators) do
        classTags[tag] = true
    end
    for tag in pairs(raid.classIndicators) do
        classTags[tag] = true
    end

    local currentClassTag = GetCurrentClassTag()
    classTags[currentClassTag] = true

    for classTag in pairs(classTags) do
        local partyList = party.classIndicators[classTag]
        local raidList = raid.classIndicators[classTag]

        if type(partyList) ~= "table" then
            partyList = {}
        end

        if #partyList == 0 and type(raidList) == "table" and #raidList > 0 then
            partyList = CopyIndicatorList(raidList, partySettings, raidSettings)
        else
            partyList = CopyIndicatorList(partyList, partySettings, raidSettings)
        end

        SortClassIndicatorsByCatalog(classTag, partyList)

        party.classIndicators[classTag] = partyList
        raid.classIndicators[classTag] = partyList
    end
end

function ns:GetConfig()
    HRpartyFrameDB = HRpartyFrameDB or {}

    if not configInitialized then
        HRpartyFrameDB = CopyDefaults(defaults, HRpartyFrameDB)

        if HRpartyFrameDB.party then
            NormalizeConfigIndicators(HRpartyFrameDB.party)
        end

        if HRpartyFrameDB.raid then
            NormalizeConfigIndicators(HRpartyFrameDB.raid)
        end

        EnsureSharedClassIndicatorLists(HRpartyFrameDB)

        configInitialized = true
    end

    return HRpartyFrameDB
end

function ns:GetPartyConfig()
    return self:GetConfig().party
end

function ns:GetRaidConfig()
    return self:GetConfig().raid
end

function ns:GetWindowConfig()
    return self:GetConfig().window
end
