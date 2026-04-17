local _, ns = ...

ns.uf = ns.uf or {}

local DEFAULT_ANCHOR = "TOPLEFT"
local ICON_GAP = 2

function ns:GetStatusIconsDB(frame)
    local cfg = self:GetUnitFrameConfig(frame)
    return cfg and cfg.statusIcons
end

local function ApplyIconLayout(iconFrame, parent, opts, extraX, extraY)
    if not iconFrame or not parent or not opts then
        return
    end

    local anchor = opts.anchor or DEFAULT_ANCHOR
    local size = opts.size or 14
    local x = (opts.x or 0) + (extraX or 0)
    local y = (opts.y or 0) + (extraY or 0)

    iconFrame:ClearAllPoints()
    iconFrame:SetPoint(anchor, parent, anchor, x, y)
    iconFrame:SetSize(size, size)
end

local function SetRoleIcon(texture, role)
    if not texture then
        return
    end

    local key = role or "NONE"
    if texture.__hrRoleKey == key then
        return
    end
    texture.__hrRoleKey = key

    if role == "TANK" then
        texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        texture:SetTexCoord(0, 19 / 64, 22 / 64, 41 / 64)
        texture:SetAlpha(1)
    elseif role == "HEALER" then
        texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        texture:SetTexCoord(20 / 64, 39 / 64, 1 / 64, 20 / 64)
        texture:SetAlpha(1)
    elseif role == "DAMAGER" then
        texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        texture:SetTexCoord(20 / 64, 39 / 64, 22 / 64, 41 / 64)
        texture:SetAlpha(1)
    else
        texture:SetAlpha(0)
    end
end

local function SetLeaderIcon(texture, visible)
    if not texture then
        return
    end

    local key = visible and 1 or 0
    if texture.__hrLeaderKey == key then
        return
    end
    texture.__hrLeaderKey = key

    if visible then
        texture:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetAlpha(1)
    else
        texture:SetAlpha(0)
    end
end

local STATE_SUMMON_TEXTURE = "Interface\\RaidFrame\\Raid-Icon-SummonPending"
local STATE_REZ_TEXTURE = "Interface\\RaidFrame\\Raid-Icon-Rez"
local READY_CHECK_HOLD_SECONDS = 1
local readyCheckStatusCache = {}
local READY_CHECK_READY_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Ready"
local READY_CHECK_NOT_READY_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-NotReady"
local READY_CHECK_WAITING_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Waiting"

local function IsReadyCheckActive(now)
    local state = ns.readyCheckState
    return state and state.active and state.expiresAt and state.expiresAt > now
end

local function GetSummonIconInfo(unit)
    if unit == "player" and StaticPopup_FindVisible("CONFIRM_SUMMON") then
        return STATE_SUMMON_TEXTURE
    end

    if C_IncomingSummon and C_IncomingSummon.IncomingSummonStatus then
        local summonStatus = C_IncomingSummon.IncomingSummonStatus(unit)
        if summonStatus == 1 or summonStatus == 2 then
            return STATE_SUMMON_TEXTURE
        end
    end

    return nil
end

local function GetRezIconInfo(unit)
    local isRez = UnitHasIncomingResurrection and UnitHasIncomingResurrection(unit)
    if isRez then
        return STATE_REZ_TEXTURE
    end

    local now = GetTime()
    local ready = ns.GetEffectiveReadyCheckStatus and ns:GetEffectiveReadyCheckStatus(unit, now)
    local isReadyCheckActive = IsReadyCheckActive(now)

    if ready == "ready" then
        readyCheckStatusCache[unit] = {
            status = ready,
            expiresAt = now + READY_CHECK_HOLD_SECONDS
        }
        return READY_CHECK_READY_TEXTURE
    elseif ready == "notready" then
        readyCheckStatusCache[unit] = {
            status = ready,
            expiresAt = now + READY_CHECK_HOLD_SECONDS
        }
        return READY_CHECK_NOT_READY_TEXTURE
    elseif ready == "waiting" and isReadyCheckActive then
        return READY_CHECK_WAITING_TEXTURE
    elseif isReadyCheckActive then
        -- Event says ready check is active; show waiting even if API has not populated unit yet.
        return READY_CHECK_WAITING_TEXTURE
    end

    local cached = readyCheckStatusCache[unit]
    if cached and cached.expiresAt and cached.expiresAt > now then
        if cached.status == "ready" then
            return READY_CHECK_READY_TEXTURE
        elseif cached.status == "notready" then
            return READY_CHECK_NOT_READY_TEXTURE
        end
    end

    readyCheckStatusCache[unit] = nil

    return nil
end

local function SetRezTexture(texture, iconFrame, path)
    if not texture or not iconFrame then
        return
    end

    local key = path or "NONE"
    if texture.__hrRezKey == key then
        return
    end
    texture.__hrRezKey = key

    if path then
        iconFrame:Show()
        texture:SetTexture(path)
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetAlpha(1)
    else
        iconFrame:Hide()
        texture:SetAlpha(0)
    end
end

local function EnsureRoleIcon(frame)
    if frame.RoleIcon then
        return
    end

    local roleFrame = CreateFrame("Frame", nil, frame)
    roleFrame:SetFrameLevel(frame:GetFrameLevel() + 30)
    roleFrame:SetSize(14, 14)

    local role = roleFrame:CreateTexture(nil, "OVERLAY")
    role:SetAllPoints()
    role:SetAlpha(0)
    roleFrame.icon = role

    frame.RoleIcon = roleFrame
end

local function EnsureLeaderIcon(frame)
    if frame.LeaderIcon then
        return
    end

    local leaderFrame = CreateFrame("Frame", nil, frame)
    leaderFrame:SetFrameLevel(frame:GetFrameLevel() + 30)
    leaderFrame:SetSize(12, 12)

    local leader = leaderFrame:CreateTexture(nil, "OVERLAY")
    leader:SetAllPoints()
    leader:SetAlpha(0)
    leaderFrame.icon = leader

    frame.LeaderIcon = leaderFrame
end

local function EnsureSummonIcon(frame)
    if frame.SummonIcon then
        return
    end

    local summonFrame = CreateFrame("Frame", nil, frame)
    summonFrame:SetFrameLevel(frame:GetFrameLevel() + 30)
    summonFrame:SetSize(16, 16)

    local summon = summonFrame:CreateTexture(nil, "OVERLAY")
    summon:SetAllPoints()
    summon:SetAlpha(0)
    summonFrame.icon = summon

    frame.SummonIcon = summonFrame
end

local function EnsureRezIcon(frame)
    if frame.RezIcon then
        return
    end

    local rezFrame = CreateFrame("Frame", nil, frame)
    rezFrame:SetFrameLevel(frame:GetFrameLevel() + 30)
    rezFrame:SetSize(16, 16)

    local rez = rezFrame:CreateTexture(nil, "OVERLAY")
    rez:SetAllPoints()
    rez:SetAlpha(0)
    rezFrame.icon = rez

    frame.RezIcon = rezFrame
end

local function BuildLayoutKey(frame, db)
    local roleShown = db and db.enabled and db.role and db.role.enabled and frame.RoleIcon and frame.RoleIcon:IsShown() and "1" or "0"
    local leaderShown = db and db.enabled and db.leader and db.leader.enabled and frame.LeaderIcon and frame.LeaderIcon:IsShown() and "1" or "0"
    local summonShown = db and db.enabled and db.summon and db.summon.enabled and frame.SummonIcon and frame.SummonIcon:IsShown() and "1" or "0"
    local rezShown = db and db.enabled and db.rez and db.rez.enabled and frame.RezIcon and frame.RezIcon:IsShown() and "1" or "0"

    return table.concat({
        roleShown,
        leaderShown,
        summonShown,
        rezShown,
        db and db.role and (db.role.anchor or DEFAULT_ANCHOR) or "",
        tostring(db and db.role and db.role.size or 0),
        tostring(db and db.role and db.role.x or 0),
        tostring(db and db.role and db.role.y or 0),
        db and db.leader and (db.leader.anchor or DEFAULT_ANCHOR) or "",
        tostring(db and db.leader and db.leader.size or 0),
        tostring(db and db.leader and db.leader.x or 0),
        tostring(db and db.leader and db.leader.y or 0),
        db and db.summon and (db.summon.anchor or DEFAULT_ANCHOR) or "",
        tostring(db and db.summon and db.summon.size or 0),
        tostring(db and db.summon and db.summon.x or 0),
        tostring(db and db.summon and db.summon.y or 0),
        db and db.rez and (db.rez.anchor or DEFAULT_ANCHOR) or "",
        tostring(db and db.rez and db.rez.size or 0),
        tostring(db and db.rez and db.rez.x or 0),
        tostring(db and db.rez and db.rez.y or 0),
    }, ":")
end

local function ApplyAutoLayout(frame, db)
    local layoutKey = BuildLayoutKey(frame, db)
    if frame.__hrStatusLayoutKey == layoutKey then
        return
    end
    frame.__hrStatusLayoutKey = layoutKey

    local roleOpts = db and db.role
    local leaderOpts = db and db.leader
    local summonOpts = db and db.summon
    local rezOpts = db and db.rez

    ApplyIconLayout(frame.RoleIcon, frame, roleOpts)
    ApplyIconLayout(frame.LeaderIcon, frame, leaderOpts)
    ApplyIconLayout(frame.SummonIcon, frame, summonOpts)
    ApplyIconLayout(frame.RezIcon, frame, rezOpts)
end

function ns.uf:CreateStatusIcons(frame)
    if not frame then
        return
    end

    EnsureRoleIcon(frame)
    EnsureLeaderIcon(frame)
    EnsureSummonIcon(frame)
    EnsureRezIcon(frame)
end

function ns.uf:ApplyStatusIconSettings(frame)
    if not frame then
        return
    end

    self:CreateStatusIcons(frame)

    local db = ns:GetStatusIconsDB(frame)
    if not db then
        return
    end

    if not db.enabled then
        frame.RoleIcon:Hide()
        frame.LeaderIcon:Hide()
        frame.RezIcon:Hide()
        frame.__hrStatusLayoutKey = nil
        return
    end

    if db.role and db.role.enabled then
        frame.RoleIcon:Show()
    else
        frame.RoleIcon:Hide()
        if frame.RoleIcon.icon then
            frame.RoleIcon.icon:SetAlpha(0)
        end
    end

    if db.leader and db.leader.enabled then
        frame.LeaderIcon:Show()
    else
        frame.LeaderIcon:Hide()
        if frame.LeaderIcon.icon then
            frame.LeaderIcon.icon:SetAlpha(0)
        end
    end

    if db.summon and db.summon.enabled then
        frame.SummonIcon:Show()
    else
        frame.SummonIcon:Hide()
        if frame.SummonIcon.icon then
            frame.SummonIcon.icon:SetAlpha(0)
        end
    end

    if db.rez and db.rez.enabled then
        frame.RezIcon:Show()
    else
        frame.RezIcon:Hide()
        if frame.RezIcon.icon then
            frame.RezIcon.icon:SetAlpha(0)
        end
    end

    frame.__hrStatusLayoutKey = nil
    ApplyAutoLayout(frame, db)
end

function ns.uf:UpdateStatusIconPreview(frame)
    if not frame then
        return
    end

    self:CreateStatusIcons(frame)

    local db = ns:GetStatusIconsDB(frame)
    if not db or not db.enabled or not db.preview then
        return
    end

    if db.role and db.role.enabled then
        frame.RoleIcon:Show()
        SetRoleIcon(frame.RoleIcon.icon, "HEALER")
    else
        frame.RoleIcon:Hide()
        frame.RoleIcon.icon:SetAlpha(0)
    end

    if db.leader and db.leader.enabled then
        frame.LeaderIcon:Show()
        SetLeaderIcon(frame.LeaderIcon.icon, true)
    else
        frame.LeaderIcon:Hide()
        frame.LeaderIcon.icon:SetAlpha(0)
    end

    if db.summon and db.summon.enabled then
        SetRezTexture(frame.SummonIcon.icon, frame.SummonIcon, STATE_SUMMON_TEXTURE)
    else
        frame.SummonIcon:Hide()
        frame.SummonIcon.icon:SetAlpha(0)
    end

    if db.rez and db.rez.enabled then
        SetRezTexture(frame.RezIcon.icon, frame.RezIcon, STATE_REZ_TEXTURE)
    else
        frame.RezIcon:Hide()
        frame.RezIcon.icon:SetAlpha(0)
    end

    ApplyAutoLayout(frame, db)
end

function ns.uf:UpdateStatusIcons(frame)
    if not frame or not frame.unit then
        return
    end

    self:CreateStatusIcons(frame)

    local db = ns:GetStatusIconsDB(frame)
    if not db then
        return
    end

    if not db.enabled then
        frame.RoleIcon:Hide()
        frame.LeaderIcon:Hide()
        frame.RezIcon:Hide()
        frame.__hrStatusLayoutKey = nil
        return
    end

    if db.preview then
        self:UpdateStatusIconPreview(frame)
        return
    end

    local unit = frame.unit

    if db.role and db.role.enabled then
        frame.RoleIcon:Show()
        SetRoleIcon(frame.RoleIcon.icon, UnitGroupRolesAssigned(unit))
    else
        frame.RoleIcon:Hide()
        frame.RoleIcon.icon:SetAlpha(0)
    end

    if db.leader and db.leader.enabled then
        frame.LeaderIcon:Show()
        SetLeaderIcon(frame.LeaderIcon.icon, UnitIsGroupLeader(unit))
    else
        frame.LeaderIcon:Hide()
        frame.LeaderIcon.icon:SetAlpha(0)
    end

    if db.summon and db.summon.enabled then
        local summonTexture = GetSummonIconInfo(unit)
        SetRezTexture(frame.SummonIcon.icon, frame.SummonIcon, summonTexture)
    else
        frame.SummonIcon:Hide()
        frame.SummonIcon.icon:SetAlpha(0)
    end

    if db.rez and db.rez.enabled then
        local rezTexture = GetRezIconInfo(unit)
        SetRezTexture(frame.RezIcon.icon, frame.RezIcon, rezTexture)
    else
        frame.RezIcon:Hide()
        frame.RezIcon.icon:SetAlpha(0)
    end

    ApplyAutoLayout(frame, db)
end
