local _, ns = ...

local I = ns.IndicatorOptions
local anchors = ns.OptionCommon.anchorValues

function ns:GetIndicatorOptionsArgs()
    local args = {}

    args.divider = {
        type = "header",
        name = "필터 설정",
        order = 1,
    }

    args.filterType = {
        type = "select",
        name = "필터 선택",
        order = 1.1,
        values = {
            none = "없음",
            class = "직업 전용",
        },
        get = function()
            return ns:GetPartyConfig().indicatorSettings.filterType or "none"
        end,
        set = function(_, value)
            local cfg = ns:GetPartyConfig()
            cfg.indicatorSettings.filterType = value

            if value == "class" then
                local selected = I.GetSelectedSpellID()
                local values = I.GetSelectableAuraValues()

                if not selected or not values[tostring(selected)] then
                    cfg.indicatorSettings.selectedSpellID = nil

                    local spellList = I.GetSelectableSpellList()
                    if #spellList > 0 then
                        cfg.indicatorSettings.selectedSpellID = spellList[1]
                    end
                end
            else
                cfg.indicatorSettings.selectedSpellID = nil
            end

            ns:RefreshOptions()
            ns:SafeRefresh()
        end,
    }

    args.spacer = {
        type = "description",
        name = " ",
        order = 1.12,
        width = 0.1,
    }

    args.previewOffAll = {
        type = "execute",
        name = "미리 보기 전체 끄기",
        order = 1.15,
        func = function()
            I.DisableAllPreviewAuras()
            ns:RefreshOptions()
            ns:SafeRefresh()
            ns:Print("모든 오라 미리 보기를 종료했습니다.")
        end,
    }

    args.filterTypeHelp = {
        type = "description",
        name = "|cffffcc00직업 전용 선택 시 현재 클래스에 등록된 오라 목록이 표시됩니다. 기본값 복원 시 클래스 기본 프리셋 위치로 다시 등록됩니다.|r",
        order = 1.2,
        width = "full",
    }

    args.break1 = {
        type = "description",
        name = "\n\n",
        width = "full",
        order = 1.3,
    }

    args.stackSettings = {
        type = "group",
        name = "오라 설정",
        inline = true,
        order = 2,
        hidden = function()
            return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
        end,
        args = {
            auraSelect = {
                type = "select",
                name = "오라 선택",
                order = 3,
                width = 1.5,
                values = function()
                    return I.GetSelectableAuraValues()
                end,
                get = function()
                    local selected = I.GetSelectedSpellID()
                    return selected and tostring(selected) or nil
                end,
                set = function(_, value)
                    I.SetSelectedSpellID(tonumber(value))
                    ns:RefreshOptions()
                end,
            },

            spacer1 = {
                type = "description",
                name = " ",
                order = 3.05,
                width = 0.1,
            },

            resetClassFilter = {
                type = "execute",
                name = "기본값 복원",
                order = 3.1,
                width = 1.5,
                confirm = true,
                confirmText = "현재 클래스의 직업 전용 필터를 기본 프리셋 위치로 다시 등록할까요?",
                func = function()
                    I.ResetCurrentClassIndicatorsFromCatalog()
                    ns:RefreshOptions()
                    ns:SafeRefresh()
                    ns:Print("현재 클래스 직업 전용 필터를 기본 프리셋으로 복원했습니다.")
                end,
            },

            break2 = {
                type = "description",
                name = "",
                width = "full",
                order = 3.2,
            },

            addInput = {
                type = "input",
                name = "주문명 or 오라 ID 추가",
                order = 3.3,
                width = 1.5,
                get = function()
                    return ns.pendingIndicatorInput or ""
                end,
                set = function(_, value)
                    ns.pendingIndicatorInput = value
                    I.AddIndicatorFromInput(value)
                end,
            },

            spacer2 = {
                type = "description",
                name = " ",
                order = 3.35,
                width = 0.1,
            },

            removeAuraSelect = {
                type = "select",
                name = "오라 제거",
                order = 3.4,
                width = 1.5,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                values = function()
                    return I.GetRemovableAuraValues()
                end,
                get = function()
                    return nil
                end,
                set = function(_, value)
                    local spellID = tonumber(value)
                    if not spellID then return end
                    I.ShowRemoveIndicatorPopup(spellID)
                end,
            },

            help = {
                type = "description",
                name = "|cffffcc00직업 전용 선택 시 현재 클래스 목록이 오라 선택 드롭다운에 표시됩니다. 수동 추가한 주문도 상세 편집 대상으로 선택 가능합니다.|r",
                order = 3.5,
                fontSize = "medium",
                width = "full",
            },

            selectedPartyEnabled = {
                type = "toggle",
                name = "파티 사용",
                order = 4,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    return I.GetSelectedIndicator() == nil
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and entry.partyEnabled ~= false or false
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.partyEnabled = value
                    entry.enabled = value
                    ns:SafeRefresh()
                end,
            },

            selectedRaidEnabled = {
                type = "toggle",
                name = "레이드 사용",
                order = 4.05,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    return I.GetSelectedIndicator() == nil
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and entry.raidEnabled ~= false or false
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.raidEnabled = value
                    ns:SafeRefresh()
                end,
            },

            selectedOnlyMine = {
                type = "toggle",
                name = "내 주문만",
                order = 4.1,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    return I.GetSelectedIndicator() == nil
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and entry.onlyMine or false
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.onlyMine = value
                    ns:SafeRefresh()
                end,
            },

            selectedDisplayMode = {
                type = "toggle",
                name = "없을 때 표시",
                order = 4.2,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    return I.GetSelectedIndicator() == nil
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and entry.displayMode == "missing"
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.displayMode = value and "missing" or "present"
                    ns:SafeRefresh()
                end,
            },

            selectedShowStack = {
                type = "toggle",
                name = "중첩 표시",
                order = 4.3,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    return I.GetSelectedIndicator() == nil
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and entry.showStack or false
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.showStack = value
                    ns:SafeRefresh()
                end,
            },

            selectedPreview = {
                type = "execute",
                order = 4.4,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    return I.GetSelectedIndicator() == nil
                end,
                name = function()
                    local spellID = I.GetSelectedSpellID()
                    if not spellID then
                        return "미리보기 켜기"
                    end

                    return I.GetPreviewStateForSpell(spellID) and "미리보기 끄기" or "미리보기 켜기"
                end,
                func = function()
                    local spellID = I.GetSelectedSpellID()
                    if not spellID then return end

                    ns.previewIndicatorStates[spellID] = not ns.previewIndicatorStates[spellID]
                    I.UpdatePreviewFlag()
                    ns:RefreshOptions()
                    ns:SafeRefresh()
                end,
            },

            separator2 = {
                type = "header",
                name = "파티 오라 위치",
                order = 5,
            },

            selectedPartySize = {
                type = "range",
                name = "파티 버프 크기",
                order = 5.1,
                min = 6,
                max = 32,
                step = 1,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    return I.GetSelectedIndicator() == nil
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and (entry.partySize or ns:GetPartyConfig().indicatorSettings.size or 20) or 20
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.partySize = value
                    entry.size = value
                    ns:SafeRefresh()
                end,
            },

            selectedPartyAnchor = {
                type = "select",
                name = "파티 기준점",
                order = 5.2,
                values = anchors,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    return I.GetSelectedIndicator() == nil
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and (entry.partyAnchor or "TOPLEFT") or "TOPLEFT"
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.partyAnchor = value
                    entry.anchor = value
                    ns:SafeRefresh()
                end,
            },

            selectedPartyX = {
                type = "range",
                name = "파티 X",
                order = 5.3,
                min = -50,
                max = 50,
                step = 1,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    return I.GetSelectedIndicator() == nil
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and (entry.partyX or 0) or 0
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.partyX = value
                    entry.x = value
                    ns:SafeRefresh()
                end,
            },

            selectedPartyY = {
                type = "range",
                name = "파티 Y",
                order = 5.4,
                min = -50,
                max = 50,
                step = 1,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    return I.GetSelectedIndicator() == nil
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and (entry.partyY or 0) or 0
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.partyY = value
                    entry.y = value
                    ns:SafeRefresh()
                end,
            },

            break3 = {
                type = "description",
                name = "\n\n",
                width = "full",
                order = 5.5,
            },

            separatorRaid = {
                type = "header",
                name = "레이드 오라 위치",
                order = 5.6,
            },

            selectedRaidSize = {
                type = "range",
                name = "레이드 버프 크기",
                order = 5.7,
                min = 6,
                max = 32,
                step = 1,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    return I.GetSelectedIndicator() == nil
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and (entry.raidSize or ns:GetRaidConfig().indicatorSettings.size or 16) or 16
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.raidSize = value
                    ns:SafeRefresh()
                end,
            },

            selectedRaidAnchor = {
                type = "select",
                name = "레이드 기준점",
                order = 5.8,
                values = anchors,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    return I.GetSelectedIndicator() == nil
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and (entry.raidAnchor or "TOPLEFT") or "TOPLEFT"
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.raidAnchor = value
                    ns:SafeRefresh()
                end,
            },

            selectedRaidX = {
                type = "range",
                name = "레이드 X",
                order = 5.9,
                min = -50,
                max = 50,
                step = 1,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    return I.GetSelectedIndicator() == nil
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and (entry.raidX or 0) or 0
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.raidX = value
                    ns:SafeRefresh()
                end,
            },

            selectedRaidY = {
                type = "range",
                name = "레이드 Y",
                order = 5.95,
                min = -50,
                max = 50,
                step = 1,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    return I.GetSelectedIndicator() == nil
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and (entry.raidY or 0) or 0
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.raidY = value
                    ns:SafeRefresh()
                end,
            },

            break4 = {
                type = "description",
                name = "\n\n",
                width = "full",
                order = 6,
            },

            separator3 = {
                type = "header",
                name = "중첩 위치",
                order = 7,
            },

            selectedStackSize = {
                type = "range",
                name = "중첩 글자 크기",
                order = 7.1,
                min = 6,
                max = 24,
                step = 1,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    local entry = I.GetSelectedIndicator()
                    return entry == nil or not entry.showStack
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and (entry.stackSize or 20) or 20
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.stackSize = value
                    ns:SafeRefresh()
                end,
            },

            selectedStackAnchor = {
                type = "select",
                name = "중첩 기준점",
                order = 7.2,
                values = anchors,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    local entry = I.GetSelectedIndicator()
                    return entry == nil or not entry.showStack
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and (entry.stackAnchor or "CENTER") or "CENTER"
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.stackAnchor = value
                    ns:SafeRefresh()
                end,
            },

            selectedStackX = {
                type = "range",
                name = "중첩 X",
                order = 7.3,
                min = -30,
                max = 30,
                step = 1,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    local entry = I.GetSelectedIndicator()
                    return entry == nil or not entry.showStack
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and (entry.stackX or 0) or 0
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.stackX = value
                    ns:SafeRefresh()
                end,
            },

            selectedStackY = {
                type = "range",
                name = "중첩 Y",
                order = 7.4,
                min = -30,
                max = 30,
                step = 1,
                hidden = function()
                    return (ns:GetPartyConfig().indicatorSettings.filterType or "none") ~= "class"
                end,
                disabled = function()
                    local entry = I.GetSelectedIndicator()
                    return entry == nil or not entry.showStack
                end,
                get = function()
                    local entry = I.GetSelectedIndicator()
                    return entry and (entry.stackY or 0) or 0
                end,
                set = function(_, value)
                    local entry = I.GetSelectedIndicator()
                    if not entry then return end
                    entry.stackY = value
                    ns:SafeRefresh()
                end,
            },
        }
    }

    return args
end
