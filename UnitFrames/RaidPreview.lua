local _, ns = ...

ns.uf = ns.uf or {}

local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min

local CLASS_ORDER = {
    "PRIEST", "DRUID", "PALADIN", "SHAMAN", "MONK",
    "WARRIOR", "DEATHKNIGHT", "DEMONHUNTER", "ROGUE", "MAGE",
    "WARLOCK", "HUNTER", "EVOKER"
}

local PREVIEW_NAMES = {
    "탱커1", "힐러1", "딜러1", "딜러2", "딜러3",
    "탱커2", "힐러2", "딜러4", "딜러5", "딜러6",
    "탱커3", "힐러3", "딜러7", "딜러8", "딜러9",
    "탱커4", "힐러4", "딜러10", "딜러11", "딜러12",
    "탱커5", "힐러5", "딜러13", "딜러14", "딜러15",
    "탱커6", "힐러6", "딜러16", "딜러17", "딜러18",
    "탱커7", "힐러7", "딜러19", "딜러20", "딜러21",
    "탱커8", "힐러8", "딜러22", "딜러23", "딜러24",
}

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

function ns:GetRaidAutoLayoutMode()
    local numMembers = GetNumGroupMembers() or 0
    local maxGroup = GetMaxUsedRaidGroup()

    if numMembers > 20 or maxGroup > 4 then
        return "40"
    end

    return "20"
end

function ns:GetRaidPreviewLayoutProfile()
    return self:GetRaidLayoutProfile()
end

function ns:GetRaidPreviewSize(layout)
    if not layout then
        return 0, 0, 0, 0
    end

    local is40 = layout.mode == "40"
    local unitsPerColumn = 5
    local maxColumns = is40 and 8 or 4
    local count = layout.previewCount or (is40 and 40 or 20)

    local visibleCount = min(count, unitsPerColumn * maxColumns)
    local columnsUsed = max(min(ceil(visibleCount / unitsPerColumn), maxColumns), 1)
    local rowsUsed = max(min(visibleCount, unitsPerColumn), 1)

    local totalWidth = (layout.width * columnsUsed) + (layout.spacingX * max(columnsUsed - 1, 0))
    local totalHeight = (layout.height * rowsUsed) + (layout.spacingY * max(rowsUsed - 1, 0))

    return totalWidth, totalHeight, columnsUsed, visibleCount
end

local function CreatePreviewBackdrop(frame)
    if frame.bg then
        return
    end

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.08, 0.08, 0.9)
    frame.bg = bg
end

local function CreatePreviewHealth(frame)
    if frame.Health then
        return
    end

    local health = CreateFrame("StatusBar", nil, frame)
    health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    health:SetAllPoints()
    health:SetMinMaxValues(0, 100)
    health:SetValue(100)
    frame.Health = health
end

local function EnsurePreviewName(frame)
    if frame.Name then
        return
    end

    local name = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.Name = name
end

local function EnsurePreviewBorder(frame)
    if frame.Border then
        return
    end

    local border = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    border:SetBackdropBorderColor(0, 0, 0, 0.35)
    frame.Border = border
end

local function GetPreviewClassColor(index)
    local classTag = CLASS_ORDER[((index - 1) % #CLASS_ORDER) + 1]
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classTag]

    if color then
        return color.r, color.g, color.b
    end

    return 0.2, 0.8, 0.2
end

local function EnsurePreviewButton(parent, index)
    parent.buttons = parent.buttons or {}

    if parent.buttons[index] then
        return parent.buttons[index]
    end

    local button = CreateFrame("Frame", nil, parent)
    button.__isRaidFrame = true
    button.__isRaidPreview = true
    button.index = index

    CreatePreviewBackdrop(button)
    CreatePreviewHealth(button)
    EnsurePreviewName(button)
    EnsurePreviewBorder(button)

    parent.buttons[index] = button
    return button
end

local function ApplyPreviewButtonStyle(button, layout, shownIndex)
    if not button or not layout then
        return
    end

    button:SetSize(layout.width, layout.height)

    if button.Health then
        local r, g, b = GetPreviewClassColor(shownIndex)
        button.Health:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        button.Health:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)

        button.Health:SetStatusBarColor(r, g, b)
        button.Health:SetValue(100)
    end

    if button.Name then
        button.Name:ClearAllPoints()
        button.Name:SetPoint(
            layout.namePoint or "CENTER",
            button,
            layout.namePoint or "CENTER",
            layout.nameX or 0,
            layout.nameY or 0
        )
        button.Name:SetFont(STANDARD_TEXT_FONT, layout.nameFontSize or 10, "OUTLINE")
        button.Name:SetText(PREVIEW_NAMES[shownIndex] or ("미리보기" .. shownIndex))
    end
end

function ns:GetOrCreateRaidPreview()
    if self.raidPreview then
        return self.raidPreview
    end

    local preview = CreateFrame("Frame", "HRraidFramePreview", UIParent)
    preview:SetFrameStrata("HIGH")
    preview:SetFrameLevel(30)
    preview:SetClampedToScreen(true)
    preview:Hide()

    local title = preview:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("BOTTOMLEFT", preview, "TOPLEFT", 0, 6)
    title:SetJustifyH("LEFT")
    preview.title = title

    self.raidPreview = preview
    return preview
end

function ns:UpdateRaidPreviewPosition()
    local preview = self:GetOrCreateRaidPreview()
    local cfg = self:GetRaidConfig()

    preview:ClearAllPoints()
    preview:SetPoint(cfg.point or "TOPLEFT", UIParent, cfg.relativePoint or "TOPLEFT", cfg.x or 20, cfg.y or -300)
end

function ns:UpdateRaidPreview()
    local cfg = self:GetRaidConfig()
    if not cfg.previewVisible then
        if self.raidPreview then
            self.raidPreview:Hide()
        end
        return
    end

    local preview = self:GetOrCreateRaidPreview()
    local layout = self:GetRaidPreviewLayoutProfile()
    local totalWidth, totalHeight, columnsUsed, visibleCount = self:GetRaidPreviewSize(layout)
    local is40 = layout and layout.mode == "40"
    local unitsPerColumn = 5
    local maxColumns = is40 and 8 or 4
    local capacity = unitsPerColumn * maxColumns

    self:UpdateRaidPreviewPosition()
    preview:SetSize(totalWidth, totalHeight)

    if preview.title then
        local suffix = ""
        if capacity < (layout.previewCount or (is40 and 40 or 20)) then
            suffix = string.format(" |cffff8080(현재 설정으로 %d명만 표시)|r", capacity)
        end

        preview.title:SetText(string.format(
            "레이드 미리보기 %s인  |cffaaaaaa%d x %d|r  |cffaaaaaa%d열|r%s",
            layout.mode,
            totalWidth,
            totalHeight,
            columnsUsed or 0,
            suffix
        ))
    end

    for i = 1, 40 do
        local button = EnsurePreviewButton(preview, i)

        if i <= visibleCount then
            local column = floor((i - 1) / unitsPerColumn)
            local row = (i - 1) % unitsPerColumn

            local x = column * ((layout.width or 90) + (layout.spacingX or 3))
            local y = -row * ((layout.height or 36) + (layout.spacingY or 3))

            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", preview, "TOPLEFT", x, y)

            ApplyPreviewButtonStyle(button, layout, i)
            button:Show()
        else
            button:Hide()
        end
    end

    preview:Show()
end

function ns:ShowRaidPreview()
    if InCombatLockdown() then
        return
    end

    local cfg = self:GetRaidConfig()
    if not cfg.previewVisible then
        return
    end

    self:UpdateRaidPreview()

    if self.raidPreview then
        self.raidPreview:Show()
    end
end

function ns:HideRaidPreview()
    if self.raidPreview then
        self.raidPreview:Hide()
    end
end

function ns:IsRaidPreviewVisible()
    return self.raidPreview and self.raidPreview:IsShown()
end
