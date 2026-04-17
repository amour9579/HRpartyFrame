local _, ns = ...

local oUF = oUF

ns.NotSecretValue = ns.NotSecretValue or (oUF and oUF.NotSecretValue)

function ns:UnitIsAFK(unit)
    if not unit or not UnitIsAFK or not self.NotSecretValue then
        return nil
    end

    local afk = UnitIsAFK(unit)
    return self.NotSecretValue(afk) and afk or nil
end

local function SetNameText(frame, text)
    if not frame or not frame.Name then
        return
    end

    text = text or ""
    if frame.__hrNameText ~= text then
        frame.Name:SetText(text)
        frame.__hrNameText = text
    end
end

local function GetJustifyFromPoint(point)
    point = point or "CENTER"

    if point:find("RIGHT") then
        return "RIGHT"
    elseif point:find("CENTER") then
        return "CENTER"
    end

    return "LEFT"
end

local function GetRaidNameSettings(frame)
    if not frame or not frame.__isRaidFrame then
        return nil
    end

    local cfg = ns:GetRaidConfig()
    local db = cfg and cfg.unitframes or {}
    local layout = nil

    if frame.__isRaidPreview and ns.GetRaidPreviewLayoutProfile then
        layout = ns:GetRaidPreviewLayoutProfile()
    elseif ns.GetRaidLayoutProfile then
        layout = ns:GetRaidLayoutProfile()
    end

    if not layout then
        return nil
    end

    return {
        fontPath = ns.GetFontPath and ns:GetFontPath(db.nameFont) or STANDARD_TEXT_FONT,
        fontSize = layout.nameFontSize or 10,
        point = layout.namePoint or "CENTER",
        x = layout.nameX or 0,
        y = layout.nameY or 0,
    }
end

local function GetDefaultNameSettings(frame)
    local cfg = ns.GetUnitFrameConfig and ns:GetUnitFrameConfig(frame)
    local db = cfg and cfg.unitframes
    if not db then
        return nil
    end

    return {
        fontPath = ns.GetFontPath and ns:GetFontPath(db.nameFont) or STANDARD_TEXT_FONT,
        fontSize = db.nameFontSize or 12,
        point = db.namePoint or "CENTER",
        x = db.nameX or 0,
        y = db.nameY or 0,
    }
end

function ns.uf:UpdateNameStyle(frame)
    if not frame or not frame.Name or not frame.Health then
        return
    end

    local settings = GetRaidNameSettings(frame) or GetDefaultNameSettings(frame)
    if not settings then
        return
    end

    local point = settings.point or "CENTER"
    local justifyH = GetJustifyFromPoint(point)

    frame.Name:ClearAllPoints()

    -- width 완전 제거
    frame.Name:SetWidth(0)

    frame.Name:SetJustifyH(justifyH)
    frame.Name:SetWordWrap(false)
    frame.Name:SetMaxLines(1)

    if frame.Name.SetNonSpaceWrap then
        frame.Name:SetNonSpaceWrap(false)
    end

    frame.Name:SetPoint(point, frame, point, settings.x or 0, settings.y or 0)

    frame.Name:SetFont(settings.fontPath, settings.fontSize, "OUTLINE")

    SetNameText(frame, frame.Name:GetText() or "")
end

function ns.uf:CreateName(self)
    if not self or not self.Health then
        return
    end

    local name = self.Health:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    name:SetWordWrap(false)
    name:SetMaxLines(1)
    name:SetWidth(0)

    if name.SetNonSpaceWrap then
        name:SetNonSpaceWrap(false)
    end

    self.Name = name

    if ns.uf.UpdateNameStyle then
        ns.uf:UpdateNameStyle(self)
    end
end

function ns.uf:UpdateUnitName(frame)
    if not frame or not frame.Name or not frame.unit then
        return
    end

    if not UnitExists(frame.unit) then
        SetNameText(frame, "")
        return
    end

    if not UnitIsConnected(frame.unit) then
        SetNameText(frame, "오프라인")
        return
    end

    if UnitIsDeadOrGhost(frame.unit) then
        SetNameText(frame, "죽음")
        return
    end

    if frame.unit:match("^party%d+$") and ns.UnitIsAFK and ns:UnitIsAFK(frame.unit) then
        SetNameText(frame, "자리 비움")
        return
    end

    local name = GetUnitName(frame.unit, false) or ""
    SetNameText(frame, name)
end

function ns.uf:UpdateAllNameStyles()
    if ns.ForEachUnitFrame then
        ns:ForEachUnitFrame(function(frame)
            if frame and frame.Name then
                self:UpdateNameStyle(frame)
            end
        end)
    end

    if ns.raidPreview and ns.raidPreview.buttons then
        for i = 1, #ns.raidPreview.buttons do
            local button = ns.raidPreview.buttons[i]
            if button and button.Name then
                self:UpdateNameStyle(button)
            end
        end
    end
end
