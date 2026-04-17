local _, ns = ...

function ns:ApplyUnitButtonClicks(frame)
    if not frame or InCombatLockdown() then return end

    if frame.RegisterForClicks then
        frame:RegisterForClicks("AnyUp")
    end
    frame:EnableMouse(true)
end

if oUF and oUF.RegisterInitCallback and not ns.__hrClickInitCallbackRegistered then
    oUF:RegisterInitCallback(function(frame)
        if ns and ns.ApplyUnitButtonClicks then
            ns:ApplyUnitButtonClicks(frame)
        end
    end)

    ns.__hrClickInitCallbackRegistered = true
end

local function CreateBackground(frame)
    if frame.bg then
        return
    end

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.08, 0.08, 0.9)
    frame.bg = bg
end

local function CreateHealth(frame)
    if frame.Health then
        return
    end

    local health = CreateFrame("StatusBar", nil, frame)
    health:SetAllPoints()
    health:SetStatusBarTexture("Interface\\AddOns\\HRpartyFrame\\Media\\Textures\\NormTex2.tga")
    health.colorTapping = false
    health.colorDisconnected = false
    health.colorClass = true
    health.colorReaction = false
    health.colorHealth = true
    frame.Health = health
end

function ns:GetUnitFrameConfig(frame)
    if frame and frame.__isRaidFrame then
        return self:GetRaidConfig()
    end
    return self:GetPartyConfig()
end

function ns:CreateStyle(frame, unit)
    local cfg = ns:GetUnitFrameConfig(frame)
    if not frame.__isRaidFrame and not InCombatLockdown() then
        frame:SetSize(cfg.width or 140, cfg.height or 36)
    end

    CreateBackground(frame)
    CreateHealth(frame)

    if ns.uf and ns.uf.CreateHealAbsorbOverlay then
        ns.uf:CreateHealAbsorbOverlay(frame)
    end

    if ns.uf and ns.uf.CreateRaidTargetIndicator then
        ns.uf:CreateRaidTargetIndicator(frame)
    end
    if not frame.__isRaidFrame and ns.uf and ns.uf.CreatePower then
        ns.uf:CreatePower(frame)
    end

    if not frame.__isRaidFrame and ns.uf and ns.uf.ApplyPowerSettings then
        ns.uf:ApplyPowerSettings(frame)
    end

    if ns.uf and ns.uf.CreateName then
        ns.uf:CreateName(frame)
    end

    if ns.uf and ns.uf.CreateCenterDebuff then
        ns.uf:CreateCenterDebuff(frame)
    end

    if ns.uf and ns.uf.ApplyCenterDebuffSettings then
        ns.uf:ApplyCenterDebuffSettings(frame)
    end

    if ns.uf and ns.uf.UpdateCenterDebuff then
        ns.uf:UpdateCenterDebuff(frame)
    end

    if ns.uf and ns.uf.UpdateHealAbsorbOverlay then
        ns.uf:UpdateHealAbsorbOverlay(frame)
    end
    if ns.uf and ns.uf.CreateBorder then
        ns.uf:CreateBorder(frame)
    end

    if ns.uf and ns.uf.CreateIndicators then
        ns.uf:CreateIndicators(frame)
    end

    if ns.uf and ns.uf.ApplyIndicatorSettings then
        ns.uf:ApplyIndicatorSettings(frame)
    end

    if ns.uf and ns.uf.UpdateUnitIndicators then
        ns.uf:UpdateUnitIndicators(frame)
    end

    if ns.uf and ns.uf.CreateStatusIcons then
        ns.uf:CreateStatusIcons(frame)
    end

    if ns.uf and ns.uf.ApplyStatusIconSettings then
        ns.uf:ApplyStatusIconSettings(frame)
    end

    if ns.uf and ns.uf.ApplyRaidTargetSettings then
        ns.uf:ApplyRaidTargetSettings(frame)
    end
    if ns.uf and ns.uf.UpdateStatusIcons then
        ns.uf:UpdateStatusIcons(frame)
    end

    if not frame.__clickShowHooked then
        frame.__clickShowHooked = true

        frame:HookScript("OnShow", function(self)
            if ns.ApplyUnitButtonClicks then
                ns:ApplyUnitButtonClicks(self)
            end
        end)
    end

    if not frame.__tooltipHooked then
        frame.__tooltipHooked = true

        frame:HookScript("OnEnter", function(self)
            self.__isHover = true

            if ns.uf and ns.uf.UpdateBorder then
                ns.uf:UpdateBorder(self)
            end

            if self.unit and UnitExists(self.unit) then
                GameTooltip_SetDefaultAnchor(GameTooltip, self)
                GameTooltip:SetUnit(self.unit)
            end
        end)

        frame:HookScript("OnLeave", function(self)
            self.__isHover = nil

            if ns.uf and ns.uf.UpdateBorder then
                ns.uf:UpdateBorder(self)
            end

            GameTooltip:Hide()
        end)
    end
end
