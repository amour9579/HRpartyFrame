local _, ns = ...

local anchors = ns.OptionCommon.anchorValues

function ns:GetDebuffOptionsArgs()
    local args = {}
    local displayModeValues = {
        dispellableOnly = "해제 가능한 약화만",
        all = "모든 약화 효과",
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

    args.break2 = {
        type = "description",
        name = "",
        width = "full",
        order = 1.2,
    }

    args.displayMode = {
        type = "select",
        name = "디버프 표시 모드",
        order = 1.3,
        values = displayModeValues,
        get = function()
            local value = ns:GetPartyConfig().debuff.displayMode
            if value ~= "dispellableOnly" and value ~= "all" then
                value = "all"
            end
            return value
        end,
        set = function(_, value)
            if value ~= "dispellableOnly" and value ~= "all" then
                value = "all"
            end
            ns:GetPartyConfig().debuff.displayMode = value
            ns:SafeRefresh()
        end,
    }

    args.hideUtilityDebuffs = {
        type = "toggle",
        name = "블러드 디버프류/유틸 디버프 숨김",
        desc = "피로, 소진, 시간 변위 등 유틸성 디버프를 숨깁니다.",
        order = 1.4,
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

    args.break3 = {
        type = "description",
        name = "",
        width = "full",
        order = 1.5,
    }

    args.anchor = {
        type = "select",
        name = "기준점",
        order = 3,
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
        order = 4,
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
        order = 5,
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

    args.break4 = {
        type = "description",
        name = "",
        width = "full",
        order = 5.1,
    }
    

    args.size = {
        type = "range",
        name = "아이콘 크기",
        order = 5.5,
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
        order = 6,
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
        order = 7,
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
