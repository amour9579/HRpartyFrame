local _, ns = ...

ns.uf = ns.uf or {}

function ns.uf:CreatePower(frame)
    if not frame or frame.Power then
        return
    end

    local power = CreateFrame("StatusBar", nil, frame)
    power:SetStatusBarTexture("Interface\\AddOns\\HRpartyFrame\\Media\\Textures\\NormTex2.tga")
    power.colorPower = true
    power.colorClass = false
    power.colorReaction = false
    power.colorDisconnected = false
    power.colorTapping = false
    power.frequentUpdates = true
    power.displayAltPower = false
    power.Smooth = true

    local bg = power:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.04, 0.04, 0.04, 0.9)
    power.bg = bg

    frame.Power = power
end

function ns.uf:ApplyPowerSettings(frame)
    if not frame or not frame.Health then
        return
    end

    if not frame.Power and ns.uf.CreatePower then
        ns.uf:CreatePower(frame)
    end

    local cfg = ns:GetUnitFrameConfig(frame)
    local powerCfg = cfg and cfg.power
    local enabled = powerCfg and powerCfg.enabled
    local height = (powerCfg and powerCfg.height) or 6

    frame.Health:ClearAllPoints()

    if enabled and frame.Power then
        frame.Power:ClearAllPoints()
        frame.Power:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        frame.Power:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        frame.Power:SetHeight(height)
        frame.Power:Show()

        frame.Health:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame.Health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        frame.Health:SetPoint("BOTTOMLEFT", frame.Power, "TOPLEFT", 0, 1)
        frame.Health:SetPoint("BOTTOMRIGHT", frame.Power, "TOPRIGHT", 0, 1)
    else
        if frame.Power then
            frame.Power:Hide()
        end

        frame.Health:SetAllPoints()
    end
end

function ns.uf:RefreshPowerLayout()
    ns:ForEachUnitFrame(function(frame)
        if frame and frame.unit then
            self:ApplyPowerSettings(frame)
        end
    end)
end
