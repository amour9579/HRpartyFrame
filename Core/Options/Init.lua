local _, ns = ...

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

function ns:RefreshOptions()
    if not self.options then
        self:GetOptions()
    end

    AceConfigRegistry:NotifyChange("HRpartyFrame")
end

function ns:GetOptions()
    self.options = {
        type = "group",
        name = "HRpartyFrame",
        childGroups = "tab",
        args = {
            layout = {
                type = "group",
                name = "프레임",
                order = 1,
                args = ns:GetLayoutOptionsArgs(),
            },
            rangecheck = {
                type = "group",
                name = "거리체크",
                order = 2,
                args = ns:GetRangeCheckOptionsArgs(),
            },
            indicators = {
                type = "group",
                name = "버프 설정",
                order = 3,
                args = ns:GetIndicatorOptionsArgs(),
            },
            debuff = {
                type = "group",
                name = "디버프 설정",
                order = 4,
                args = ns:GetDebuffOptionsArgs(),
            },
            statusIcons = {
                type = "group",
                name = "아이콘",
                order = 5,
                args = ns:GetStatusIconOptionsArgs(),
            },
        },
    }

    return self.options
end

function ns:RegisterOptions()
    AceConfig:RegisterOptionsTable("HRpartyFrame", function()
        return ns:GetOptions()
    end)

    ns:RefreshOptions()

    if ns.CreateBlizzardPanel then
        ns:CreateBlizzardPanel()
    end
end
