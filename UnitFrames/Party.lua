local _, ns = ...

local oUF = oUF
local pendingSpawnRefresh = false

local function PerformSpawnRefresh()
    pendingSpawnRefresh = false

    if not ns.partyHeader and not ns.header then
        return
    end

    if ns.RebuildUnitFrameMap then
        ns:RebuildUnitFrameMap()
    end

    if ns.UpdateHeaderLayout then
        ns:UpdateHeaderLayout()
    end

    ns:ForEachPartyUnitFrame(function(frame)
        if ns.ApplyUnitButtonClicks then
            ns:ApplyUnitButtonClicks(frame)
        end
    end)

    if ns.UpdateAllRangeStates then
        ns:UpdateAllRangeStates()
    end

    if ns.SafeRefresh then
        ns:SafeRefresh()
    end
end

function ns:GetOrCreatePartyAnchor()
    if self.partyAnchor then
        return self.partyAnchor
    end

    local cfg = self:GetPartyConfig()
    local point = cfg.point or "TOP"
    local relativePoint = cfg.relativePoint or "TOP"

    local anchor = CreateFrame("Frame", "HRpartyFrameAnchor", UIParent)
    anchor:SetSize(cfg.width or 170, cfg.height or 45)
    anchor:ClearAllPoints()
    anchor:SetPoint(point, UIParent, relativePoint, cfg.x or 370, cfg.y or -510)
    anchor:Hide()

    self.partyAnchor = anchor
    return anchor
end

function ns:UpdateHeaderLayout()
    if InCombatLockdown() then
        return
    end

    local header = self.header
    if not header then
        return
    end

    local cfg = self:GetPartyConfig()
    local point = cfg.point or "TOP"
    local relativePoint = cfg.relativePoint or "TOP"
    local anchor = self:GetOrCreatePartyAnchor()

    anchor:SetSize(cfg.width or 170, cfg.height or 45)
    anchor:ClearAllPoints()
    anchor:SetPoint(point, UIParent, relativePoint, cfg.x or 370, cfg.y or -510)

    if self.partyMover and self.partyMover:IsShown() then
        self.partyMover:SetSize(cfg.width or 170, cfg.height or 45)
        self.partyMover:ClearAllPoints()
        self.partyMover:SetPoint("TOP", UIParent, "TOP", cfg.x or 370, cfg.y or -510)

        if self.partyMover.label then
            self.partyMover.label:SetText(string.format("HR Party\n%d x %d", cfg.width or 170, cfg.height or 45))
        end
    end

    header:ClearAllPoints()
    header:SetPoint("TOP", anchor, "TOP", 0, 0)

    header:SetAttribute("point", "TOP")
    header:SetAttribute("xOffset", 0)
    header:SetAttribute("yOffset", -(cfg.spacing or 6))
    header:SetAttribute("showSolo", cfg.showSolo and true or false)
    header:SetAttribute("showPlayer", cfg.showPlayer and true or false)

    if self.RebuildUnitFrameMap then
        self:RebuildUnitFrameMap()
    end

    self:ForEachPartyUnitFrame(function(frame)
        frame:SetSize(cfg.width or 170, cfg.height or 45)
    end)

    if cfg.showSolo then
        header:SetVisibility("solo,party")
    else
        header:SetVisibility("party")
    end
end

function ns:SpawnPartyHeader()
    if self.header then
        return self.header
    end

    local cfg = self:GetPartyConfig()

    oUF:RegisterStyle("HRpartyFrameStyle", function(frame, unit)
        ns:CreateStyle(frame, unit)
    end)

    oUF:SetActiveStyle("HRpartyFrameStyle")

    local header = oUF:SpawnHeader(
        "HRpartyFrameHeader",
        nil,
        "showParty", true,
        "showRaid", false,
        "showSolo", cfg.showSolo,
        "showPlayer", cfg.showPlayer,
        "xOffset", 0,
        "yOffset", -(cfg.spacing or 6),
        "point", "TOP",
        "sortMethod", "INDEX",
        "groupFilter", "1,2,3,4,5",
        "oUF-initialConfigFunction", string.format([[self:SetWidth(%d) self:SetHeight(%d)]], cfg.width or 170, cfg.height or 45)
    )

    self.header = header
    self.partyHeader = header
    self:GetOrCreatePartyAnchor()

    if not pendingSpawnRefresh then
        pendingSpawnRefresh = true
        C_Timer.After(0, PerformSpawnRefresh)
    end

    return header
end
