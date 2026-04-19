local _, ns = ...

ns.AuraResolveCache = ns.AuraResolveCache or {
    units = {},
    learned = {},
    retry = {},
}

local CACHE_PENDING_TTL = 1.00
local CACHE_RESOLVED_GRACE = 0.20
local CACHE_MAX_RETRIES = 8
local CACHE_RETRY_DELAY = 0.08

local IsSecretValue = issecretvalue or function(...)
    return false
end

local CanAccessValue = canaccessvalue or function(value)
    return value == nil or not IsSecretValue(value)
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

local function GetUnitState(unit)
    if not unit then
        return nil
    end

    local units = ns.AuraResolveCache.units
    local state = units[unit]
    if not state then
        state = {
            entries = {},
            order = {},
            passOrder = {},
            now = 0,
        }
        units[unit] = state
    end

    return state
end

function ns:AuraResolveCacheReset(unit)
    if unit then
        self.AuraResolveCache.units[unit] = nil
        self.AuraResolveCache.retry[unit] = nil
        return
    end

    self.AuraResolveCache.units = {}
    self.AuraResolveCache.retry = {}
end

function ns:AuraResolveCacheBegin(unit)
    local state = GetUnitState(unit)
    if not state then
        return nil
    end

    state.now = GetTime()
    state.passOrder = {}

    for _, auraID in ipairs(state.order) do
        local entry = state.entries[auraID]
        if entry then
            entry.seenThisPass = false
        end
    end

    return state
end

local function QuantizeColor(r, g, b)
    if not IsSafeLookupValue(r) or not IsSafeLookupValue(g) or not IsSafeLookupValue(b) then
        return "secret"
    end

    r = tonumber(r)
    g = tonumber(g)
    b = tonumber(b)
    if not r or not g or not b then
        return "secret"
    end

    local function q(v)
        return tostring(math.floor((v * 10) + 0.5))
    end

    return table.concat({ q(r), q(g), q(b) }, ":")
end

function ns:AuraResolveCacheBuildFingerprint(unit, aura, typeKey, colorKey)
    if not aura then
        return nil
    end

    local count = SafeNumber(aura.applications, 0)
    local duration = SafeNumber(aura.duration, 0)
    local durationBucket = duration > 0 and math.floor((duration * 10) + 0.5) or 0
    local dispellable = IsSafeLookupValue(aura.canActivePlayerDispel) and (aura.canActivePlayerDispel == true and 1 or 0) or
    -1
    local typePart = typeKey or "unknown"
    local colorPart = colorKey or "0:0:0"
    local nameplateAll = IsSafeLookupValue(aura.nameplateShowAll) and (aura.nameplateShowAll and 1 or 0) or -1
    local nameplatePersonal = IsSafeLookupValue(aura.nameplateShowPersonal) and (aura.nameplateShowPersonal and 1 or 0) or
    -1
    local raidFlag = IsSafeLookupValue(aura.isRaid) and (aura.isRaid and 1 or 0) or -1

    return table.concat({
        typePart,
        colorPart,
        tostring(count),
        tostring(durationBucket),
        tostring(dispellable),
        tostring(nameplateAll),
        tostring(nameplatePersonal),
        tostring(raidFlag),
    }, "|")
end

function ns:AuraResolveCacheLookupLearned(fingerprint)
    if not fingerprint then
        return nil
    end

    return self.AuraResolveCache.learned[fingerprint]
end

function ns:AuraResolveCacheLearn(fingerprint, payload)
    if not fingerprint or not payload then
        return
    end

    local store = self.AuraResolveCache.learned
    local current = store[fingerprint]

    if current and current.icon and current.spellId and current.typeKey then
        return
    end

    store[fingerprint] = {
        icon = payload.icon,
        spellId = payload.spellId,
        displayName = payload.displayName,
        typeKey = payload.typeKey,
        learnedAt = GetTime(),
    }
end

function ns:AuraResolveCacheTrack(unit, payload)
    local state = GetUnitState(unit)
    if not state or not payload or not payload.auraInstanceID then
        return nil
    end

    local auraID = payload.auraInstanceID
    local entry = state.entries[auraID]

    if not entry then
        entry = {
            auraInstanceID = auraID,
            firstSeen = state.now or GetTime(),
        }
        state.entries[auraID] = entry
        table.insert(state.order, auraID)
    end

    if not entry.seenThisPass then
        table.insert(state.passOrder, auraID)
    end

    entry.seenThisPass = true
    entry.lastSeen = state.now or GetTime()

    entry.aura = payload.aura or entry.aura
    entry.resolved = payload.resolved == true
    entry.filterPass = payload.filterPass == true
    entry.pendingVisible = payload.pendingVisible == true
    entry.typeKey = payload.typeKey or entry.typeKey or "none"
    entry.icon = payload.icon or entry.icon
    entry.displayName = payload.displayName or entry.displayName
    entry.spellId = payload.spellId or entry.spellId
    entry.fingerprint = payload.fingerprint or entry.fingerprint
    entry.learned = payload.learned == true or entry.learned == true

    if entry.resolved then
        entry.lastResolvedAt = state.now or GetTime()
    end

    return entry
end

function ns:AuraResolveCacheCollect(unit, maxCount)
    local state = GetUnitState(unit)
    if not state then
        return {}
    end

    local now = state.now or GetTime()
    local results = {}
    local keepOrder = {}
    local seen = {}
    maxCount = maxCount or 5

    local function AddVisible(entry)
        if entry and #results < maxCount then
            table.insert(results, entry)
        end
    end

    for _, auraID in ipairs(state.passOrder) do
        local entry = state.entries[auraID]
        if entry then
            seen[auraID] = true
            table.insert(keepOrder, auraID)

            if entry.filterPass or entry.pendingVisible then
                AddVisible(entry)
            end
        end
    end

    for _, auraID in ipairs(state.order) do
        if not seen[auraID] then
            local entry = state.entries[auraID]
            if entry then
                local keep = false
                local visible = false

                if entry.resolved and entry.lastResolvedAt and (now - entry.lastResolvedAt) <= CACHE_RESOLVED_GRACE then
                    keep = true
                    visible = entry.filterPass
                elseif (not entry.resolved) and entry.lastSeen and (now - entry.lastSeen) <= CACHE_PENDING_TTL then
                    keep = true
                    visible = entry.pendingVisible
                end

                if keep then
                    table.insert(keepOrder, auraID)
                    if visible then
                        AddVisible(entry)
                    end
                else
                    state.entries[auraID] = nil
                end
            end
        end
    end

    state.order = keepOrder
    return results
end

local function RetryUpdateUnit(unit)
    if not unit or not ns.ForEachUnitFrame then
        return
    end

    ns:ForEachUnitFrame(function(frame)
        if frame and frame.unit == unit and frame:IsShown() then
            if ns.uf and ns.uf.UpdateCenterDebuff then
                ns.uf:UpdateCenterDebuff(frame)
            end
        end
    end)
end

function ns:AuraResolveCacheRequestRetry(unit)
    if not unit then
        return
    end

    local retry = self.AuraResolveCache.retry
    local info = retry[unit]

    if not info then
        info = {
            attempts = 0,
            scheduled = false,
        }
        retry[unit] = info
    end

    if info.scheduled then
        return
    end

    if info.attempts >= CACHE_MAX_RETRIES then
        return
    end

    info.attempts = info.attempts + 1
    info.scheduled = true

    C_Timer.After(CACHE_RETRY_DELAY, function()
        local current = retry[unit]
        if not current then
            return
        end

        current.scheduled = false
        RetryUpdateUnit(unit)
    end)
end

function ns:AuraResolveCacheClearRetry(unit)
    if not unit then
        return
    end

    self.AuraResolveCache.retry[unit] = nil
end

function ns:AuraResolveCacheBuildColorKey(r, g, b)
    return QuantizeColor(r, g, b)
end
