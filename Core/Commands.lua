local _, ns = ...

SLASH_HRPARTYFRAME1 = "/hrpf"
SLASH_HRPARTYFRAME2 = "/hrpartyframe"

SlashCmdList["HRPARTYFRAME"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

    if msg == "" or msg == "config" then
        if InCombatLockdown() then
            ns:Print("전투 중에는 설정창을 열 수 없습니다.")
            return
        end

        ns:ToggleConfigWindow()
        return
    end

    if msg == "reset" then
        local cfg = ns:GetPartyConfig()
        cfg.point = "TOP"
        cfg.relativePoint = "TOP"
        cfg.x = 370
        cfg.y = -510

        if ns.UpdateHeaderLayout then
            ns:UpdateHeaderLayout()
        end
        return
    end

    if msg == "mover" then
        if ns.TogglePartyMover then
            ns:TogglePartyMover()
        end
        return
    end

    ns:ToggleConfigWindow()
end

SLASH_HRUIWINDOW1 = "/hrwin"
SlashCmdList["HRUIWINDOW"] = function()
    local frame = ns.optionsFrame
    if not frame then
        print("설정창이 열려있지 않습니다.")
        return
    end

    print("설정창 크기:", math.floor(frame:GetWidth()), math.floor(frame:GetHeight()))
    print("위치:", math.floor(frame:GetLeft()), math.floor(frame:GetTop()))
end
