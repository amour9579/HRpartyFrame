local _, ns = ...

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

ns.pendingIndicatorInput = ns.pendingIndicatorInput or ""
ns.previewIndicatorStates = ns.previewIndicatorStates or {}

ns.OptionCommon = ns.OptionCommon or {}

function ns:GetFontPath(fontKey)
    if not fontKey or fontKey == "default" then
        return STANDARD_TEXT_FONT
    end

    if fontKey == "2002" then
        return "Fonts\\2002.ttf"
    elseif fontKey == "2002B" then
        return "Fonts\\2002B.ttf"
    elseif fontKey == "K_Damage" then
        return "Fonts\\K_Damage.ttf"
    end

    return "Interface\\AddOns\\HRpartyFrame\\Media\\Fonts\\" .. fontKey .. ".ttf"
end

ns.OptionCommon.anchorValues = {
    TOPLEFT = "TOPLEFT",
    TOP = "TOP",
    TOPRIGHT = "TOPRIGHT",
    LEFT = "LEFT",
    CENTER = "CENTER",
    RIGHT = "RIGHT",
    BOTTOMLEFT = "BOTTOMLEFT",
    BOTTOM = "BOTTOM",
    BOTTOMRIGHT = "BOTTOMRIGHT",
}

ns.OptionCommon.anchorPoints = {
    LEFT = "좌측",
    CENTER = "중앙",
    RIGHT = "우측",
}

ns.OptionCommon.nameFontValues = {
    default = "기본",
    ["2002"] = "2002",
    ["2002B"] = "2002 Bold",
    ["K_Damage"] = "데미지 글꼴",
    ["GmarketSansTTFBold"] = "G마켓 산스",
    ["ChosunCentennial_ttf"] = "조선 굴림체",
    ["Maplestory Light"] = "넥슨 메이플",
    ["ActionMan"] = "ActionMan",
}

function ns:RefreshOptions()
    AceConfigRegistry:NotifyChange("HRpartyFrame")
end

function ns:GetCurrentClassTag()
    local _, classTag = UnitClass("player")
    return classTag
end
