local _, ns = ...

function ns:GetLayoutOptionsArgs()
    local args = {}

    args.divider1 = {
        type = "header",
        name = "공통 설정",
        order = 1,
    }

    args.nameFont = {
        type = "select",
        name = "이름 폰트",
        order = 1.1,
        values = function()
            return ns.OptionCommon.nameFontValues
        end,
        get = function()
            return ns:GetPartyConfig().unitframes.nameFont or "default"
        end,
        set = function(_, value)
            local partyCfg = ns:GetPartyConfig()
            local raidCfg = ns:GetRaidConfig()

            partyCfg.unitframes = partyCfg.unitframes or {}
            raidCfg.unitframes = raidCfg.unitframes or {}

            partyCfg.unitframes.nameFont = value
            raidCfg.unitframes.nameFont = value

            if ns.uf and ns.uf.UpdateAllNameStyles then
                ns.uf:UpdateAllNameStyles()
            end

            if ns.UpdateRaidPreview then
                ns:UpdateRaidPreview()
            end
        end,
    }

    args.mover = {
        type = "execute",
        name = "파티 위치 이동",
        order = 1.2,
        func = function()
            if ns.TogglePartyMover then
                ns:TogglePartyMover()
            end
        end,
    }

    args.raidMover = {
        type = "execute",
        name = "레이드 위치 이동",
        order = 1.3,
        func = function()
            if ns.ToggleRaidMover then
                ns:ToggleRaidMover()
            end
        end,
    }

    args.divider2 = {
        type = "header",
        name = "파티 프레임 설정",
        order = 1.5,
    }

    args.showSolo = {
        type = "toggle",
        name = "플레이어 항상",
        order = 2,
        get = function()
            return ns:GetPartyConfig().showSolo
        end,
        set = function(_, value)
            ns:GetPartyConfig().showSolo = value
            ns:SafeRefresh()
        end,
    }

    args.showPlayer = {
        type = "toggle",
        name = "플레이어 파티에 포함",
        order = 2.1,
        get = function()
            return ns:GetPartyConfig().showPlayer
        end,
        set = function(_, value)
            ns:GetPartyConfig().showPlayer = value
            ns:SafeRefresh()
        end,
    }

    args.powerEnabled = {
        type = "toggle",
        name = "자원바 사용",
        order = 2.2,
        get = function()
            local cfg = ns:GetPartyConfig()
            return cfg.power and cfg.power.enabled or false
        end,
        set = function(_, value)
            local cfg = ns:GetPartyConfig()
            cfg.power = cfg.power or {}
            cfg.power.enabled = value

            if ns.uf and ns.uf.RefreshPowerLayout then
                ns.uf:RefreshPowerLayout()
            end

            if ns.UpdateHeaderLayout then
                ns:UpdateHeaderLayout()
            end
        end,
    }

    args.showSoloDesc = {
        type = "description",
        name = "|cffffaa00※ secure header 특성상 즉시 반영되지 않으면 /reload 하세요.|r",
        order = 2.3,
    }

    args.width = {
        type = "range",
        name = "프레임 너비",
        order = 3,
        min = 60,
        max = 300,
        step = 1,
        get = function()
            return ns:GetPartyConfig().width or 170
        end,
        set = function(_, value)
            ns:GetPartyConfig().width = value
            ns:SafeRefresh()
        end,
    }

    args.height = {
        type = "range",
        name = "프레임 높이",
        order = 3.1,
        min = 20,
        max = 100,
        step = 1,
        get = function()
            return ns:GetPartyConfig().height or 45
        end,
        set = function(_, value)
            ns:GetPartyConfig().height = value
            ns:SafeRefresh()
        end,
    }

    args.spacing = {
        type = "range",
        name = "프레임 간격",
        order = 3.2,
        min = 0,
        max = 20,
        step = 1,
        get = function()
            return ns:GetPartyConfig().spacing or 3
        end,
        set = function(_, value)
            ns:GetPartyConfig().spacing = value
            ns:SafeRefresh()
        end,
    }

    args.powerHeight = {
        type = "range",
        name = "자원바 높이",
        order = 3.3,
        min = 4,
        max = 16,
        step = 1,
        hidden = function()
            local cfg = ns:GetPartyConfig()
            return not (cfg.power and cfg.power.enabled)
        end,
        get = function()
            local cfg = ns:GetPartyConfig()
            return (cfg.power and cfg.power.height) or 6
        end,
        set = function(_, value)
            local cfg = ns:GetPartyConfig()
            cfg.power = cfg.power or {}
            cfg.power.height = value

            if ns.uf and ns.uf.RefreshPowerLayout then
                ns.uf:RefreshPowerLayout()
            end

            --ns:SafeRefresh()
        end,
    }

    args.break1 = {
        type = "description",
        name = "\n",
        width = "full",
        order = 3.5,
    }

    args.namePoint = {
        type = "select",
        name = "이름 기준점",
        order = 4,
        values = function()
            return ns.OptionCommon.anchorPoints
        end,
        get = function()
            return ns:GetPartyConfig().unitframes.namePoint or "CENTER"
        end,
        set = function(_, value)
            
            local cfg = ns:GetPartyConfig()
            cfg.unitframes = cfg.unitframes or {}
            cfg.unitframes.namePoint = value

            if ns.uf and ns.uf.UpdateAllNameStyles then
                ns.uf:UpdateAllNameStyles()
            end
        end,
    }

    args.nameX = {
        type = "range",
        name = "이름 X",
        order = 4.1,
        min = -100,
        max = 100,
        step = 1,
        get = function()
            return ns:GetPartyConfig().unitframes.nameX or 0
        end,
        set = function(_, value)
            
            local cfg = ns:GetPartyConfig()
            cfg.unitframes = cfg.unitframes or {}
            cfg.unitframes.nameX = value

            if ns.uf and ns.uf.UpdateAllNameStyles then
                ns.uf:UpdateAllNameStyles()
            end
        end,
    }

    args.nameY = {
        type = "range",
        name = "이름 Y",
        order = 4.2,
        min = -100,
        max = 100,
        step = 1,
        get = function()
            return ns:GetPartyConfig().unitframes.nameY or 0
        end,
        set = function(_, value)
            
            local cfg = ns:GetPartyConfig()
            cfg.unitframes = cfg.unitframes or {}
            cfg.unitframes.nameY = value

            if ns.uf and ns.uf.UpdateAllNameStyles then
                ns.uf:UpdateAllNameStyles()
            end
        end,
    }

    args.nameFontSize = {
        type = "range",
        name = "이름 크기",
        order = 4.3,
        min = 8,
        max = 30,
        step = 1,
        get = function()
            return ns:GetPartyConfig().unitframes.nameFontSize or 12
        end,
        set = function(_, value)
            
            local cfg = ns:GetPartyConfig()
            cfg.unitframes = cfg.unitframes or {}
            cfg.unitframes.nameFontSize = value

            if ns.uf and ns.uf.UpdateAllNameStyles then
                ns.uf:UpdateAllNameStyles()
            end
        end,
    }

    args.divider3 = {
        type = "header",
        name = "레이드 프레임 설정",
        order = 5,
    }

    args.raidPreviewVisible = {
        type = "toggle",
        name = "미리보기",
        order = 5.1,
        get = function()
            return ns:GetRaidConfig().previewVisible
        end,
        set = function(_, value)
            ns:GetRaidConfig().previewVisible = value

            if value then
                ns:ShowRaidPreview()
            else
                ns:HideRaidPreview()
            end

            if ns.UpdateRaidHeaderLayout then
                ns:UpdateRaidHeaderLayout()
            end
        end,
    }

    args.raidLayoutMode = {
        type = "select",
        name = "프레임 설정",
        order = 5.3,
        values = {
            auto = "자동",
            ["20"] = "항상 20인",
            ["40"] = "항상 40인",
        },
        get = function()
            return ns:GetRaidConfig().layoutMode or "auto"
        end,
        set = function(_, value)
            ns:GetRaidConfig().layoutMode = value
            ns:SafeRefresh()

            if ns.UpdateRaidHeaderLayout then
                ns:UpdateRaidHeaderLayout()
            end
        end,
    }

    args.stackSettings = {
        type = "group",
        name = "20인 설정",
        inline = true,
        order = 5.5,
        args = {
            raidWidth20 = {
                type = "range",
                name = "20인 너비",
                order = 6,
                min = 40,
                max = 200,
                step = 1,
                get = function() return ns:GetRaidConfig().width20 or 100 end,
                set = function(_, value)
                    ns:GetRaidConfig().width20 = value
                    ns:SafeRefresh()
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },

            raidHeight20 = {
                type = "range",
                name = "20인 높이",
                order = 6.1,
                min = 20,
                max = 100,
                step = 1,
                get = function() return ns:GetRaidConfig().height20 or 40 end,
                set = function(_, value)
                    ns:GetRaidConfig().height20 = value
                    ns:SafeRefresh()
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },

            raidSpacingX20 = {
                type = "range",
                name = "20인 간격 X",
                order = 6.2,
                min = 0,
                max = 20,
                step = 1,
                get = function() return ns:GetRaidConfig().spacingX20 or 4 end,
                set = function(_, value)
                    ns:GetRaidConfig().spacingX20 = value
                    ns:SafeRefresh()
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },

            raidSpacingY20 = {
                type = "range",
                name = "20인 간격 Y",
                order = 6.3,
                min = 0,
                max = 20,
                step = 1,
                get = function() return ns:GetRaidConfig().spacingY20 or 4 end,
                set = function(_, value)
                    ns:GetRaidConfig().spacingY20 = value
                    ns:SafeRefresh()
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },

            break3 = {
                type = "description",
                name = "\n",
                width = "full",
                order = 6.5,
            },

            raidNamePoint20 = {
                type = "select",
                name = "20인 이름 기준점",
                order = 7,
                values = function() return ns.OptionCommon.anchorPoints end,
                get = function() return ns:GetRaidConfig().unitframes.namePoint20 or "CENTER" end,
                set = function(_, value)
                    ns:GetRaidConfig().unitframes.namePoint20 = value
                    if ns.uf and ns.uf.UpdateAllNameStyles then ns.uf:UpdateAllNameStyles() end
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },

            raidNameX20 = {
                type = "range",
                name = "20인 이름 X",
                order = 7.1,
                min = -100,
                max = 100,
                step = 1,
                get = function() return ns:GetRaidConfig().unitframes.nameX20 or 0 end,
                set = function(_, value)
                    ns:GetRaidConfig().unitframes.nameX20 = value
                    if ns.uf and ns.uf.UpdateAllNameStyles then ns.uf:UpdateAllNameStyles() end
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },

            raidNameY20 = {
                type = "range",
                name = "20인 이름 Y",
                order = 7.2,
                min = -100,
                max = 100,
                step = 1,
                get = function() return ns:GetRaidConfig().unitframes.nameY20 or 0 end,
                set = function(_, value)
                    ns:GetRaidConfig().unitframes.nameY20 = value
                    if ns.uf and ns.uf.UpdateAllNameStyles then ns.uf:UpdateAllNameStyles() end
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },

            raidNameFontSize20 = {
                type = "range",
                name = "20인 이름 크기",
                order = 7.3,
                min = 8,
                max = 24,
                step = 1,
                get = function() return ns:GetRaidConfig().unitframes.nameFontSize20 or 11 end,
                set = function(_, value)
                    ns:GetRaidConfig().unitframes.nameFontSize20 = value
                    if ns.uf and ns.uf.UpdateAllNameStyles then ns.uf:UpdateAllNameStyles() end
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },
        }
    }

    args.stackSettings1 = {
        type = "group",
        name = "40인 설정",
        inline = true,
        order = 7.5,
        args = {

            raidWidth40 = {
                type = "range",
                name = "40인 너비",
                order = 8,
                min = 40,
                max = 200,
                step = 1,
                get = function() return ns:GetRaidConfig().width40 or 80 end,
                set = function(_, value)
                    ns:GetRaidConfig().width40 = value
                    ns:SafeRefresh()
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },

            raidHeight40 = {
                type = "range",
                name = "40인 높이",
                order = 8.1,
                min = 20,
                max = 100,
                step = 1,
                get = function() return ns:GetRaidConfig().height40 or 30 end,
                set = function(_, value)
                    ns:GetRaidConfig().height40 = value
                    ns:SafeRefresh()
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },

            raidSpacingX40 = {
                type = "range",
                name = "40인 간격 X",
                order = 8.2,
                min = 0,
                max = 20,
                step = 1,
                get = function() return ns:GetRaidConfig().spacingX40 or 3 end,
                set = function(_, value)
                    ns:GetRaidConfig().spacingX40 = value
                    ns:SafeRefresh()
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },

            raidSpacingY40 = {
                type = "range",
                name = "40인 간격 Y",
                order = 8.3,
                min = 0,
                max = 20,
                step = 1,
                get = function() return ns:GetRaidConfig().spacingY40 or 3 end,
                set = function(_, value)
                    ns:GetRaidConfig().spacingY40 = value
                    ns:SafeRefresh()
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },

            break5 = {
                type = "description",
                name = "\n",
                width = "full",
                order = 8.5,
            },

            raidNamePoint40 = {
                type = "select",
                name = "40인 이름 기준점",
                order = 9,
                values = function() return ns.OptionCommon.anchorPoints end,
                get = function() return ns:GetRaidConfig().unitframes.namePoint40 or "CENTER" end,
                set = function(_, value)
                    ns:GetRaidConfig().unitframes.namePoint40 = value
                    if ns.uf and ns.uf.UpdateAllNameStyles then ns.uf:UpdateAllNameStyles() end
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },

            raidNameX40 = {
                type = "range",
                name = "40인 이름 X",
                order = 9.1,
                min = -100,
                max = 100,
                step = 1,
                get = function() return ns:GetRaidConfig().unitframes.nameX40 or 0 end,
                set = function(_, value)
                    ns:GetRaidConfig().unitframes.nameX40 = value
                    if ns.uf and ns.uf.UpdateAllNameStyles then ns.uf:UpdateAllNameStyles() end
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },

            raidNameY40 = {
                type = "range",
                name = "40인 이름 Y",
                order = 9.2,
                min = -100,
                max = 100,
                step = 1,
                get = function() return ns:GetRaidConfig().unitframes.nameY40 or 0 end,
                set = function(_, value)
                    ns:GetRaidConfig().unitframes.nameY40 = value
                    if ns.uf and ns.uf.UpdateAllNameStyles then ns.uf:UpdateAllNameStyles() end
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },

            raidNameFontSize40 = {
                type = "range",
                name = "40인 이름 크기",
                order = 9.3,
                min = 8,
                max = 24,
                step = 1,
                get = function() return ns:GetRaidConfig().unitframes.nameFontSize40 or 10 end,
                set = function(_, value)
                    ns:GetRaidConfig().unitframes.nameFontSize40 = value
                    if ns.uf and ns.uf.UpdateAllNameStyles then ns.uf:UpdateAllNameStyles() end
                    if ns.UpdateRaidPreview then ns:UpdateRaidPreview() end
                end,
            },
        }
    }

    return args
end
