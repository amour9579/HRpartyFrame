local _, ns = ...

local anchors = ns.OptionCommon.anchorValues

local function CreateIconGroup(label, dbGetter, order)
    return {
        type = "group",
        name = label,
        order = order,
        inline = true,
        args = {
            enabled = {
                type = "toggle",
                name = "표시",
                order = 1,
                get = function()
                    return dbGetter().enabled
                end,
                set = function(_, value)
                    dbGetter().enabled = value
                    ns:SafeRefresh()
                end,
            },
            size = {
                type = "range",
                name = "크기",
                order = 2,
                min = 8,
                max = 50,
                step = 1,
                get = function()
                    return dbGetter().size or 16
                end,
                set = function(_, value)
                    dbGetter().size = value
                    ns:SafeRefresh()
                end,
            },

            break1 = {
                type = "description",
                name = "",
                width = "full",
                order = 2.5,
            },

            anchor = {
                type = "select",
                name = "기준점",
                order = 3,
                values = anchors,
                get = function()
                    return dbGetter().anchor or "CENTER"
                end,
                set = function(_, value)
                    dbGetter().anchor = value
                    ns:SafeRefresh()
                end,
            },
            x = {
                type = "range",
                name = "X",
                order = 4,
                min = -50,
                max = 50,
                step = 1,
                get = function()
                    return dbGetter().x or 0
                end,
                set = function(_, value)
                    dbGetter().x = value
                    ns:SafeRefresh()
                end,
            },
            y = {
                type = "range",
                name = "Y",
                order = 5,
                min = -50,
                max = 50,
                step = 1,
                get = function()
                    return dbGetter().y or 0
                end,
                set = function(_, value)
                    dbGetter().y = value
                    ns:SafeRefresh()
                end,
            },
        },
    }
end

local function CreateStatusIconsSection(label, dbGetter, order)
    return {
        type = "group",
        name = label,
        order = order,
        args = {
            enabled = {
                type = "toggle",
                name = "전체 사용",
                order = 1,
                get = function()
                    return dbGetter().enabled
                end,
                set = function(_, value)
                    dbGetter().enabled = value
                    ns:SafeRefresh()
                end,
            },
            preview = {
                type = "toggle",
                name = "미리보기",
                order = 2,
                get = function()
                    return dbGetter().preview
                end,
                set = function(_, value)
                    dbGetter().preview = value
                    ns:SafeRefresh()
                end,
            },
            role = CreateIconGroup("역할", function()
                return dbGetter().role
            end, 10),
            leader = CreateIconGroup("리더", function()
                return dbGetter().leader
            end, 20),
            summon = CreateIconGroup("소환", function()
                return dbGetter().summon
            end, 30),
            rez = CreateIconGroup("부활/준비", function()
                return dbGetter().rez
            end, 40),
            tactical = CreateIconGroup("전술 아이콘", function()
                return dbGetter().tactical
            end, 50),
        },
    }
end

function ns:GetStatusIconOptionsArgs()
    return {
        party = CreateStatusIconsSection("파티", function()
            return ns:GetPartyConfig().statusIcons
        end, 10),

        raid = CreateStatusIconsSection("레이드", function()
            return ns:GetRaidConfig().statusIcons
        end, 20),
    }
end
