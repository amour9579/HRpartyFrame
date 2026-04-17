local _, ns = ...

function ns:CreateBlizzardPanel()
    if self.blizzardPanel then
        return self.blizzardPanel
    end

    local panel = CreateFrame("Frame", "HRpartyFrameBlizzardPanel", UIParent)
    local categoryName = "HRpartyFrame 안내"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("HRpartyFrame")

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    desc:SetJustifyH("LEFT")
    desc:SetSpacing(4)
    desc:SetText("파티 프레임 설정창을 바로 열거나 명령어를 확인할 수 있습니다.")

    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetSize(160, 24)
    button:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
    button:SetText("설정창 열기")
    button:SetScript("OnClick", function()
        if InCombatLockdown() then
            if ns and ns.Print then
                ns:Print("전투 중에는 설정창을 열 수 없습니다.")
            else
                print("|cffff3333[HRpartyFrame]|r 전투 중에는 설정창을 열 수 없습니다.")
            end
            return
        end

        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
        elseif InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
            HideUIPanel(InterfaceOptionsFrame)
        end

        if ns.ToggleConfigWindow then
            ns:ToggleConfigWindow()
        end
    end)

    local cmdTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    cmdTitle:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -24)
    cmdTitle:SetText("HRpartyFrame 명령어:")

    local cmdText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    cmdText:SetPoint("TOPLEFT", cmdTitle, "BOTTOMLEFT", 0, -8)
    cmdText:SetJustifyH("LEFT")
    cmdText:SetSpacing(3)
    cmdText:SetText(
        "/hrpf - 설정창 열기/닫기\n" ..
        "/hrpf mover - 이동 모드 ON/OFF\n" ..
        "/hrpf reset - 위치 초기화"
    )

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, categoryName)
        Settings.RegisterAddOnCategory(category)
    else
        panel.name = categoryName
        InterfaceOptions_AddCategory(panel)
    end

    self.blizzardPanel = panel
    return panel
end

local f = CreateFrame("Frame")

f:RegisterEvent("ADDON_LOADED")

--[[f:SetScript("OnEvent", function(_, event, addon)
    if addon ~= "HRpartyFrame" then
        return
    end

    if ns and ns.Print then
        ns:Print("명령어: /hrpf (설정)  /hrpf mover (위치 이동)  /hrpf reset (위치 초기화)")
    else
        print("|cff00ffff[HRpartyFrame]|r /hrpf | /hrpf mover | /hrpf reset")
    end
end)]]
