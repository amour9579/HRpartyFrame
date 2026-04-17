local _, ns = ...

ns.name = "HRpartyFrame"
ns.frames = ns.frames or {}
ns.config = ns.config or {}
ns.uf = ns.uf or {}

function ns:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffHRpartyFrame|r: " .. tostring(msg))
end

if ns.CreateBlizzardPanel then
    ns:CreateBlizzardPanel()
end

ns.RangeCheck = LibStub and LibStub("LibRangeCheck-3.0", true)
