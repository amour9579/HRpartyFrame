local _, ns = ...

ns.Movers = ns.Movers or {}

local function CreateMoverBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.1, 0.6, 1, 0.20)
    frame:SetBackdropBorderColor(0.1, 0.6, 1, 0.9)
end

local function GetTopPosition(frame, fallbackX, fallbackY)
    if not frame then
        return fallbackX, fallbackY
    end

    local scale = UIParent:GetEffectiveScale()
    local frameScale = frame:GetEffectiveScale()
    local ratio = frameScale / scale

    local centerX = frame:GetCenter()
    local topY = frame:GetTop()

    if not centerX or not topY then
        return fallbackX, fallbackY
    end

    local uiWidth = UIParent:GetWidth()
    local uiHeight = UIParent:GetHeight()

    local x = centerX / ratio - (uiWidth / 2)
    local y = topY / ratio - uiHeight

    return math.floor(x + 0.5), math.floor(y + 0.5)
end

local function GetTopLeftPosition(frame, fallbackX, fallbackY)
    if not frame then
        return fallbackX, fallbackY
    end

    local scale = UIParent:GetEffectiveScale()
    local frameScale = frame:GetEffectiveScale()
    local ratio = frameScale / scale

    local left = frame:GetLeft()
    local top = frame:GetTop()

    if not left or not top then
        return fallbackX, fallbackY
    end

    local uiHeight = UIParent:GetHeight()

    local x = left / ratio
    local y = top / ratio - uiHeight

    return math.floor(x + 0.5), math.floor(y + 0.5)
end

local function GetRaidMoverLayout()
    if ns.IsRaidPreviewVisible and ns:IsRaidPreviewVisible() and ns.GetRaidPreviewLayoutProfile then
        return ns:GetRaidPreviewLayoutProfile()
    end

    return ns:GetRaidLayoutProfile()
end

local function GetRaidMoverSize()
    local layout = GetRaidMoverLayout()
    local totalWidth, totalHeight = ns:GetRaidAnchorSize(layout)

    layout.modeText = layout.mode == "40" and "40인" or "20인"
    return totalWidth, totalHeight, layout
end

function ns:CreateMover(name, width, height, labelText)
    local mover = self.Movers[name]
    if mover then
        mover:SetSize(width or mover:GetWidth(), height or mover:GetHeight())
        if mover.label and labelText then
            mover.label:SetText(labelText)
        end
        return mover
    end

    mover = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    mover:SetSize(width or 100, height or 30)
    mover:SetFrameStrata("HIGH")
    mover:SetFrameLevel(100)
    mover:SetClampedToScreen(true)
    mover:SetMovable(true)
    mover:EnableMouse(true)
    mover:RegisterForDrag("LeftButton")
    mover:Hide()

    CreateMoverBackdrop(mover)

    local label = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetText(labelText or name)
    mover.label = label

    self.Movers[name] = mover
    return mover
end

function ns:GetOrCreatePartyMover()
    if self.partyMover then
        return self.partyMover
    end

    local cfg = self:GetPartyConfig()
    local mover = self:CreateMover("HRpartyFrameMover", cfg.width or 170, cfg.height or 45, "HR Party")

    mover:SetScript("OnDragStart", function(frame)
        if InCombatLockdown() then
            return
        end
        frame:StartMoving()
    end)

    mover:SetScript("OnDragStop", function(frame)
        if InCombatLockdown() then
            return
        end

        frame:StopMovingOrSizing()

        local cfg2 = ns:GetPartyConfig()
        local x, y = GetTopPosition(frame, 370, -510)

        cfg2.point = "TOP"
        cfg2.relativePoint = "TOP"
        cfg2.x = x
        cfg2.y = y

        if ns.UpdateHeaderLayout then
            ns:UpdateHeaderLayout()
        end

        frame:ClearAllPoints()
        frame:SetPoint("TOP", UIParent, "TOP", cfg2.x or 370, cfg2.y or -510)
    end)

    self.partyMover = mover
    return mover
end

function ns:GetOrCreateRaidMover()
    if self.raidMover then
        return self.raidMover
    end

    local width, height, layout = GetRaidMoverSize()
    local mover = self:CreateMover("HRraidFrameMover", width, height, "HR Raid")

    mover:SetScript("OnDragStart", function(frame)
        if InCombatLockdown() then
            return
        end
        frame:StartMoving()
    end)

    mover:SetScript("OnDragStop", function(frame)
        if InCombatLockdown() then
            return
        end

        frame:StopMovingOrSizing()

        local cfg = ns:GetRaidConfig()
        local x, y = GetTopLeftPosition(frame, 20, -300)

        cfg.point = "TOPLEFT"
        cfg.relativePoint = "TOPLEFT"
        cfg.x = x
        cfg.y = y

        if ns.UpdateRaidHeaderLayout then
            ns:UpdateRaidHeaderLayout()
        end

        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", cfg.x or 20, cfg.y or -300)
    end)

    self.raidMover = mover

    if mover.label then
        mover.label:SetText(string.format("HR Raid\n%s\n%d x %d", layout.modeText or "자동", width, height))
    end

    return mover
end

function ns:ShowPartyMover()
    if InCombatLockdown() then
        self:Print("전투 중에는 무버를 열 수 없습니다.")
        return
    end

    local cfg = self:GetPartyConfig()
    local mover = self:GetOrCreatePartyMover()

    mover:SetSize(cfg.width or 170, cfg.height or 45)
    mover:ClearAllPoints()
    mover:SetPoint("TOP", UIParent, "TOP", cfg.x or 370, cfg.y or -510)

    if mover.label then
        mover.label:SetText(string.format("HR Party\n%d x %d", cfg.width or 170, cfg.height or 45))
    end

    mover:Show()
end

function ns:HidePartyMover()
    if self.partyMover then
        self.partyMover:Hide()
    end
end

function ns:TogglePartyMover()
    local mover = self:GetOrCreatePartyMover()
    if mover:IsShown() then
        self:HidePartyMover()
    else
        self:ShowPartyMover()
    end
end

function ns:ShowRaidMover()
    if InCombatLockdown() then
        self:Print("전투 중에는 무버를 열 수 없습니다.")
        return
    end

    local cfg = self:GetRaidConfig()
    local width, height, layout = GetRaidMoverSize()
    local mover = self:GetOrCreateRaidMover()

    mover:SetSize(width, height)
    mover:ClearAllPoints()
    mover:SetPoint("TOPLEFT", UIParent, "TOPLEFT", cfg.x or 20, cfg.y or -300)

    if mover.label then
        mover.label:SetText(string.format("HR Raid\n%s\n%d x %d", layout.modeText or "자동", width, height))
    end

    mover:Show()
end

function ns:HideRaidMover()
    if self.raidMover then
        self.raidMover:Hide()
    end
end

function ns:ToggleRaidMover()
    local mover = self:GetOrCreateRaidMover()
    if mover:IsShown() then
        self:HideRaidMover()
    else
        self:ShowRaidMover()
    end
end
