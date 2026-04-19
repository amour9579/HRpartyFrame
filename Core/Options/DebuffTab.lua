local _, ns = ...

local anchors = ns.OptionCommon.anchorValues

function ns:GetDebuffOptionsArgs()
    local args = {}
    local privateAuraAnchorValues = {
        RIGHT = "오른쪽",
        LEFT = "왼쪽",
        TOP = "위",
        BOTTOM = "아래",
    }

    args.preview = {
        type = "toggle",
        name = "미리 보기",
        order = 1.1,
        get = function()
            return ns:GetPartyConfig().debuff.preview
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.preview = value
            ns:SafeRefresh()
        end,
    }

    args.break1 = {
        type = "description",
        name = "",
        width = "full",
        order = 1.2,
    }

    args.hideUtilityDebuffs = {
        type = "toggle",
        name = "블러드 디버프류/유틸 디버프 숨김",
        desc = "피로, 소진, 시간 변위 등 유틸성 디버프를 숨깁니다.",
        order = 1.3,
        get = function()
            local value = ns:GetPartyConfig().debuff.hideUtilityDebuffs
            if value == nil then
                return true
            end
            return value
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.hideUtilityDebuffs = value
            ns:SafeRefresh()
        end,
    }

    args.onlyDispellable = {
        type = "toggle",
        name = "해제 가능한 약화 효과만 보기",
        order = 1.4,
        get = function()
            return ns:GetPartyConfig().debuff.onlyDispellable ~= false
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.onlyDispellable = value
            ns:SafeRefresh()
        end,
    }

    args.break2 = {
        type = "description",
        name = "",
        width = "full",
        order = 1.5,
    }

    args.showMagic = {
        type = "toggle",
        name = "마법 보기",
        order = 2.1,
        get = function()
            return ns:GetPartyConfig().debuff.showMagic ~= false
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.showMagic = value
            ns:SafeRefresh()
        end,
    }

    args.showCurse = {
        type = "toggle",
        name = "저주 보기",
        order = 2.2,
        get = function()
            return ns:GetPartyConfig().debuff.showCurse ~= false
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.showCurse = value
            ns:SafeRefresh()
        end,
    }

    args.showDisease = {
        type = "toggle",
        name = "질병 보기",
        order = 2.3,
        get = function()
            return ns:GetPartyConfig().debuff.showDisease ~= false
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.showDisease = value
            ns:SafeRefresh()
        end,
    }

    args.showPoison = {
        type = "toggle",
        name = "독 보기",
        order = 2.4,
        get = function()
            return ns:GetPartyConfig().debuff.showPoison ~= false
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.showPoison = value
            ns:SafeRefresh()
        end,
    }

    args.showNone = {
        type = "toggle",
        name = "무속성 보기",
        order = 2.5,
        get = function()
            return ns:GetPartyConfig().debuff.showNone ~= false
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.showNone = value
            ns:SafeRefresh()
        end,
    }

    args.showBleed = {
        type = "toggle",
        name = "출혈 보기",
        order = 2.6,
        get = function()
            return ns:GetPartyConfig().debuff.showBleed ~= false
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.showBleed = value
            ns:SafeRefresh()
        end,
    }

    args.break3 = {
        type = "description",
        name = "",
        width = "full",
        order = 2.7,
    }

    args.showPrivateAuras = {
        type = "toggle",
        name = "개인 오라 표시",
        order = 3.1,
        get = function()
            return ns:GetPartyConfig().debuff.showPrivateAuras == true
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.showPrivateAuras = value
            ns:SafeRefresh()
        end,
    }

    args.privateAuraAnchor = {
        type = "select",
        name = "개인 오라 위치",
        order = 3.2,
        values = privateAuraAnchorValues,
        disabled = function()
            return ns:GetPartyConfig().debuff.showPrivateAuras ~= true
        end,
        get = function()
            return ns:GetPartyConfig().debuff.privateAuraAnchor or "RIGHT"
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.privateAuraAnchor = value
            ns:SafeRefresh()
        end,
    }

    args.break4 = {
        type = "description",
        name = "",
        width = "full",
        order = 3.3,
    }

    args.anchor = {
        type = "select",
        name = "디버프 위치 기준점",
        order = 4.0,
        values = anchors,
        get = function()
            return ns:GetPartyConfig().debuff.anchor or "CENTER"
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.anchor = value
            ns:SafeRefresh()
        end,
    }

    args.x = {
        type = "range",
        name = "X",
        order = 4.1,
        min = -50,
        max = 50,
        step = 1,
        get = function()
            return ns:GetPartyConfig().debuff.x or 0
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.x = value
            ns:SafeRefresh()
        end,
    }

    args.y = {
        type = "range",
        name = "Y",
        order = 4.2,
        min = -50,
        max = 50,
        step = 1,
        get = function()
            return ns:GetPartyConfig().debuff.y or 0
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.y = value
            ns:SafeRefresh()
        end,
    }

    args.break5 = {
        type = "description",
        name = "",
        width = "full",
        order = 4.3,
    }

    args.size = {
        type = "range",
        name = "아이콘 크기",
        order = 5.0,
        min = 8,
        max = 40,
        step = 1,
        get = function()
            return ns:GetPartyConfig().debuff.size or 30
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.size = value
            ns:SafeRefresh()
        end,
    }

    args.iconBorderThickness = {
        type = "range",
        name = "아이콘 테두리 두께",
        order = 5.1,
        min = 1,
        max = 8,
        step = 1,
        get = function()
            return ns:GetPartyConfig().debuff.iconBorderThickness or 2
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.iconBorderThickness = value
            ns:SafeRefresh()
        end,
    }

    args.frameBorderThickness = {
        type = "range",
        name = "프레임 테두리 두께",
        order = 5.2,
        min = 1,
        max = 8,
        step = 1,
        get = function()
            return ns:GetPartyConfig().debuff.frameBorderThickness or 1
        end,
        set = function(_, value)
            ns:GetPartyConfig().debuff.frameBorderThickness = value
            ns:SafeRefresh()
        end,
    }

    return args
end
