local _, ns = ...
local oUF = oUF

local pendingRaidRefresh = false
local raidStyleRegistered = false

local function EnsureRaidStyleRegistered()
    if raidStyleRegistered then
        return
    end

    oUF:RegisterStyle("HRraidFrameStyle", function(frame, unit)
        frame.__isRaidFrame = true
        ns:CreateStyle(frame, unit)
    end)

    raidStyleRegistered = true
end

local function GetMaxUsedRaidGroup()
    local numMembers = GetNumGroupMembers() or 0
    local maxGroup = 1

    if not IsInRaid() then
        return maxGroup
    end

    for i = 1, numMembers do
        local _, _, subgroup = GetRaidRosterInfo(i)
        if subgroup and subgroup > maxGroup then
            maxGroup = subgroup
        end
    end

    if maxGroup < 1 then
        maxGroup = 1
    elseif maxGroup > 8 then
        maxGroup = 8
    end

    return maxGroup
end

local function PerformRaidSpawnRefresh()
    pendingRaidRefresh = false

    if ns.RebuildRaidUnitFrameMap then
        ns:RebuildRaidUnitFrameMap()
    end

    if ns.ForEachRaidUnitFrame then
        ns:ForEachRaidUnitFrame(function(frame)
            if ns.ApplyUnitButtonClicks then
                ns:ApplyUnitButtonClicks(frame)
            end
        end)
    end

    if ns.SafeRefresh then
        ns:SafeRefresh()
    end
end

function ns:GetRaidAutoLayoutMode()
    local numMembers = GetNumGroupMembers() or 0
    local maxGroup = GetMaxUsedRaidGroup()

    if numMembers > 20 or maxGroup > 4 then
        return "40"
    end

    return "20"
end

function ns:GetRaidLayoutProfile()
    local cfg = self:GetRaidConfig()
    local mode = cfg.layoutMode or "auto"

    if mode == "auto" then
        mode = self:GetRaidAutoLayoutMode()
    end

    local unitcfg = cfg.unitframes or {}

    local layout = {
        mode = mode,
    }

    if mode == "40" then
        layout.width = cfg.width40 or 80
        layout.height = cfg.height40 or 30
        layout.spacingX = cfg.spacingX40 or 3
        layout.spacingY = cfg.spacingY40 or 3

        layout.nameFontSize = unitcfg.nameFontSize40 or 10
        layout.namePoint = unitcfg.namePoint40 or "CENTER"
        layout.nameX = unitcfg.nameX40 or 0
        layout.nameY = unitcfg.nameY40 or 0
    else
        layout.width = cfg.width20 or 100
        layout.height = cfg.height20 or 40
        layout.spacingX = cfg.spacingX20 or 4
        layout.spacingY = cfg.spacingY20 or 4

        layout.nameFontSize = unitcfg.nameFontSize20 or 11
        layout.namePoint = unitcfg.namePoint20 or "CENTER"
        layout.nameX = unitcfg.nameX20 or 0
        layout.nameY = unitcfg.nameY20 or 0
    end

    return layout
end

function ns:GetRaidAnchorSize(layout)
    layout = layout or self:GetRaidLayoutProfile()

    local width = layout.width or 90
    local height = layout.height or 36
    local spacingX = layout.spacingX or 3
    local spacingY = layout.spacingY or 3
    local is40 = layout.mode == "40"
    local unitsPerColumn = 5
    local maxColumns = is40 and 8 or 4

    local moverWidth = (width * maxColumns) + (spacingX * math.max(0, maxColumns - 1))
    local moverHeight = (height * unitsPerColumn) + (spacingY * math.max(0, unitsPerColumn - 1))

    return moverWidth, moverHeight
end

function ns:GetOrCreateRaidAnchor()
    if self.raidAnchor then
        return self.raidAnchor
    end

    local cfg = self:GetRaidConfig()
    local layout = self:GetRaidLayoutProfile()
    local moverWidth, moverHeight = self:GetRaidAnchorSize(layout)

    local anchor = CreateFrame("Frame", "HRraidFrameAnchor", UIParent)
    anchor:SetSize(moverWidth, moverHeight)
    anchor:ClearAllPoints()
    anchor:SetPoint(cfg.point or "TOPLEFT", UIParent, cfg.relativePoint or "TOPLEFT", cfg.x or 20, cfg.y or -300)
    anchor:SetAlpha(0)
    anchor:Hide()

    self.raidAnchor = anchor
    return anchor
end

function ns:GetRaidGroupHeaderName(index)
    return string.format("HRraidFrameHeaderGroup%d", index)
end

function ns:GetRaidActiveGroupCount()
    local layout = self:GetRaidLayoutProfile()
    local is40 = layout and layout.mode == "40"
    local maxColumns = is40 and 8 or 4
    local maxUsedGroup = GetMaxUsedRaidGroup()

    if maxUsedGroup > maxColumns then
        maxColumns = maxUsedGroup
    end

    if maxColumns < 1 then
        maxColumns = 1
    elseif maxColumns > 8 then
        maxColumns = 8
    end

    return maxColumns
end

function ns:ForEachRaidHeader(callback)
    if type(callback) ~= "function" then
        return
    end

    if not self.raidHeaders then
        return
    end

    for i = 1, #self.raidHeaders do
        local header = self.raidHeaders[i]
        if header then
            callback(header, i)
        end
    end
end

function ns:ForEachRaidUnitFrame(callback)
    if type(callback) ~= "function" then
        return
    end

    if self.RebuildRaidUnitFrameMap then
        self:RebuildRaidUnitFrameMap()
    end

    if not self.raidUnitFrames then
        return
    end

    for i = 1, #self.raidUnitFrames do
        local frame = self.raidUnitFrames[i]
        if frame then
            callback(frame, i)
        end
    end
end

function ns:CreateRaidGroupHeader(index)
    self.raidHeaders = self.raidHeaders or {}

    if self.raidHeaders[index] then
        return self.raidHeaders[index]
    end

    local cfg = self:GetRaidConfig()
    local layout = self:GetRaidLayoutProfile()

    EnsureRaidStyleRegistered()
    oUF:SetActiveStyle("HRraidFrameStyle")

    local header = oUF:SpawnHeader(
        self:GetRaidGroupHeaderName(index),
        nil,
        "showParty", false,
        "showRaid", true,
        "showPlayer", cfg.showPlayer and true or false,
        "groupFilter", tostring(index),
        "sortMethod", cfg.sortMethod or "INDEX",
        "point", "TOP",
        "yOffset", -(layout.spacingY or 3),
        "oUF-initialConfigFunction", string.format([[
            self:SetWidth(%d)
            self:SetHeight(%d)
        ]], layout.width or 90, layout.height or 36)
    )

    header.__hrGroupIndex = index
    header:SetVisibility("raid")

    self.raidHeaders[index] = header
    return header
end

function ns:UpdateRaidHeaderLayout()
    if InCombatLockdown() then
        self.pendingRaidLayout = true
        return
    end

    local cfg = self:GetRaidConfig()
    local layout = self:GetRaidLayoutProfile()
    local activeGroups = self:GetRaidActiveGroupCount()
    local anchor = self:GetOrCreateRaidAnchor()
    local moverWidth, moverHeight = self:GetRaidAnchorSize(layout)

    anchor:ClearAllPoints()
    anchor:SetPoint(cfg.point or "TOPLEFT", UIParent, cfg.relativePoint or "TOPLEFT", cfg.x or 20, cfg.y or -300)
    anchor:SetSize(moverWidth, moverHeight)

    if self.raidMover and self.raidMover:IsShown() then
        self.raidMover:SetSize(moverWidth, moverHeight)
        self.raidMover:ClearAllPoints()
        self.raidMover:SetPoint("TOPLEFT", UIParent, "TOPLEFT", cfg.x or 20, cfg.y or -300)

        if self.raidMover.label then
            self.raidMover.label:SetText(string.format("HR Raid\n%s인\n%d x %d", layout.mode or "auto", moverWidth,
                moverHeight))
        end
    end

    if self:IsRaidPreviewVisible() and self.UpdateRaidPreview then
        self:UpdateRaidPreview()
    end

    self.raidHeaders = self.raidHeaders or {}

    for i = 1, activeGroups do
        if not self.raidHeaders[i] then
            self:CreateRaidGroupHeader(i)
        end
    end

    local stepX = (layout.width or 90) + (layout.spacingX or 3)

    for i = 1, 8 do
        local header = self.raidHeaders[i]
        if header then
            header:ClearAllPoints()

            if i <= activeGroups then
                header:SetPoint("TOPLEFT", anchor, "TOPLEFT", (i - 1) * stepX, 0)
                header:SetAttribute("groupFilter", tostring(i))
                header:SetAttribute("sortMethod", cfg.sortMethod or "INDEX")
                header:SetAttribute("point", "TOP")
                header:SetAttribute("yOffset", -(layout.spacingY or 3))
                header:Show()
                header:SetVisibility("raid")

                local childIndex = 1
                while true do
                    local child = select(childIndex, header:GetChildren())
                    if not child then
                        break
                    end

                    child.__isRaidFrame = true
                    child:SetSize(layout.width or 90, layout.height or 36)

                    childIndex = childIndex + 1
                end
            else
                header:Hide()
            end
        end
    end

    if self.RebuildRaidUnitFrameMap then
        self:RebuildRaidUnitFrameMap()
    end
end

function ns:SpawnRaidHeader()
    self.raidHeaders = self.raidHeaders or {}

    local activeGroups = self:GetRaidActiveGroupCount()

    self:GetOrCreateRaidAnchor()

    for i = 1, activeGroups do
        self:CreateRaidGroupHeader(i)
    end

    self.raidHeader = self.raidHeaders[1]

    C_Timer.After(0, function()
        if ns.ForEachRaidUnitFrame then
            ns:ForEachRaidUnitFrame(function(frame)
                frame.__isRaidFrame = true
            end)
        end

        if ns.UpdateAllRangeStates then
            ns:UpdateAllRangeStates()
        end
    end)

    if not pendingRaidRefresh then
        pendingRaidRefresh = true
        C_Timer.After(0, PerformRaidSpawnRefresh)
    end

    self:UpdateRaidHeaderLayout()

    return self.raidHeader
end
