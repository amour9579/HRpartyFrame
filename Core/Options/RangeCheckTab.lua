local _, ns = ...

function ns:GetRangeCheckOptionsArgs()
    local args = {}

    args.rangeCheck = {
        type = "toggle",
        name = "거리 체크 사용",
        order = 1,
        get = function()
            return ns:GetPartyConfig().rangeCheck
        end,
        set = function(_, value)
            ns:GetPartyConfig().rangeCheck = value

            if ns.UpdateAllRangeStates then
                ns:UpdateAllRangeStates()
            end
            ns:SafeRefresh()
        end,
    }

    args.rangeThreshold = {
        type = "range",
        name = "거리 기준",
        order = 2,
        min = 5,
        max = 45,
        step = 1,
        disabled = function()
            return not ns:GetPartyConfig().rangeCheck
        end,
        get = function()
            return ns:GetPartyConfig().rangeThreshold or 40
        end,
        set = function(_, value)
            ns:GetPartyConfig().rangeThreshold = value
            ns:SafeRefresh()
        end,
    }

    args.outOfRangeAlpha = {
        type = "range",
        name = "사거리 밖 투명도",
        order = 3,
        min = 0,
        max = 100,
        step = 1,
        disabled = function()
            return not ns:GetPartyConfig().rangeCheck
        end,
        get = function()
            return ns:GetPartyConfig().outOfRangeAlpha or 20
        end,
        set = function(_, value)
            ns:GetPartyConfig().outOfRangeAlpha = value
            ns:SafeRefresh()
        end,
    }

    args.rangeFrequency = {
        type = "range",
        name = "갱신 주기",
        order = 4,
        min = 0.1,
        max = 1.0,
        step = 0.1,
        isPercent = false,
        disabled = function()
            return not ns:GetPartyConfig().rangeCheck
        end,
        get = function()
            return ns:GetPartyConfig().rangeFrequency or 0.2
        end,
        set = function(_, value)
            ns:GetPartyConfig().rangeFrequency = value
            ns:SafeRefresh()
        end,
    }

    return args
end
