local _, ns = ...

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local function GetRealFrame(widget)
    if not widget then
        return nil
    end

    return widget.frame or widget
end

local function SaveWindowPosition(frame)
    local cfg = ns:GetWindowConfig()
    if not cfg or not frame then
        return
    end

    cfg.left = frame:GetLeft()
    cfg.top = frame:GetTop()
    cfg.width = math.floor(frame:GetWidth() + 0.5)
    cfg.height = math.floor(frame:GetHeight() + 0.5)

    local status = AceConfigDialog:GetStatusTable("HRpartyFrame")
    if status then
        status.left = cfg.left
        status.top = cfg.top
        status.width = cfg.width
        status.height = cfg.height
    end
end

local function ApplyWindowState(frame)
    local cfg = ns:GetWindowConfig()
    if not cfg or not frame then
        return
    end

    local minWidth, minHeight = 970, 750
    local width = math.max(cfg.width or 1400, minWidth)
    local height = math.max(cfg.height or 1000, minHeight)

    cfg.width = width
    cfg.height = height

    frame:ClearAllPoints()

    if cfg.left and cfg.top then
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cfg.left, cfg.top)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    frame:SetSize(width, height)

    local status = AceConfigDialog:GetStatusTable("HRpartyFrame")
    if status then
        status.left = cfg.left
        status.top = cfg.top
        status.width = width
        status.height = height
    end
end

ns.ApplyWindowState = ApplyWindowState

local function SetupWindow(widget)
    local frame = GetRealFrame(widget)
    if not frame or frame.__hrpfSetup then
        return
    end

    frame:SetParent(UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetResizable(true)

    if frame.SetResizeBounds then
        frame:SetResizeBounds(970, 750, 1400, 1000)
    end

    frame:SetScript("OnDragStart", function(f)
        f:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        SaveWindowPosition(f)
    end)

    if widget and widget.sizer_se then
        widget.sizer_se:Show()
        widget.sizer_se:HookScript("OnMouseUp", function()
            local wcfg = ns:GetWindowConfig()
            wcfg.width = math.floor(frame:GetWidth() + 0.5)
            wcfg.height = math.floor(frame:GetHeight() + 0.5)
            SaveWindowPosition(frame)
        end)
    end

    frame.__hrpfSetup = true
end

function ns:OpenConfigWindow()
    self:RegisterOptions()

    local cfg = ns:GetWindowConfig()
    local minWidth, minHeight = 970, 750

    cfg.width = math.max(cfg.width or 1400, minWidth)
    cfg.height = math.max(cfg.height or 1000, minHeight)

    AceConfigDialog:Open("HRpartyFrame")

    local widget = AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["HRpartyFrame"]
    if not widget then
        return
    end

    local frame = GetRealFrame(widget)
    if not frame then
        return
    end

    frame:HookScript("OnHide", function()
        if ns.HideRaidPreview then
            ns:HideRaidPreview()
        end
    end)

    local status = AceConfigDialog:GetStatusTable("HRpartyFrame")
    if status then
        status.width = cfg.width
        status.height = cfg.height

        if status.left == nil or status.top == nil then
            status.left = cfg.left
            status.top = cfg.top
        end

        widget:SetStatusTable(status)
    end

    SetupWindow(widget)
    ApplyWindowState(frame)

    self.optionsFrame = frame
    self.optionsWidget = widget

    frame:Show()

    if self.GetRaidConfig and self.ShowRaidPreview then
        local cfg = self:GetRaidConfig()
        if cfg.previewVisible then
            self:ShowRaidPreview()
        end
    end
end

function ns:CloseConfigWindow()
    if self.HideRaidPreview then
        self:HideRaidPreview()
    end

    AceConfigDialog:Close("HRpartyFrame")
end

function ns:ToggleConfigWindow()
    if AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["HRpartyFrame"] then
        self:CloseConfigWindow()
    else
        self:OpenConfigWindow()
    end
end
