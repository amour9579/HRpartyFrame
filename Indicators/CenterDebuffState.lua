local _, ns = ...

ns.CenterDebuffState = ns.CenterDebuffState or {
    units = {},
}

local PENDING_TTL = 0.90
local RESOLVED_GRACE = 0.20

local function GetUnitState(unit)
    if not unit then
        return nil
    end

    local units = ns.CenterDebuffState.units
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

function ns:CenterDebuffStateBegin(unit)
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

function ns:CenterDebuffStateTrack(unit, payload)
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
    entry.typeKey = payload.typeKey or entry.typeKey or "none"
    entry.icon = payload.icon or entry.icon
    entry.filterPass = payload.filterPass == true
    entry.pendingVisible = payload.pendingVisible == true
    entry.displayName = payload.displayName or entry.displayName
    entry.spellId = payload.spellId or entry.spellId

    if entry.resolved then
        entry.lastResolvedAt = state.now or GetTime()
    end

    return entry
end

function ns:CenterDebuffStateCollect(unit, maxCount)
    local state = GetUnitState(unit)
    if not state then
        return {}
    end

    local now = state.now or GetTime()
    local results = {}
    local keepOrder = {}
    local seen = {}

    local function AddVisible(entry)
        if entry and #results < (maxCount or 5) then
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

                if entry.resolved and entry.lastResolvedAt and (now - entry.lastResolvedAt) <= RESOLVED_GRACE then
                    keep = true
                    visible = entry.filterPass
                elseif (not entry.resolved) and entry.lastSeen and (now - entry.lastSeen) <= PENDING_TTL then
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

function ns:CenterDebuffStateReset(unit)
    if unit then
        ns.CenterDebuffState.units[unit] = nil
        return
    end

    ns.CenterDebuffState.units = {}
end
