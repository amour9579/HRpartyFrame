local _, ns = ...

ns.ClassAuraCatalog = {
    DRUID = {
        { spellID = 774, label = "회복", anchor = "TOPLEFT", x = 2, y = -2, onlyMine = true, displayMode = "present" },
        { spellID = 155777, label = "회복 (싹틔우기)", anchor = "TOPLEFT", x = 20, y = -2, onlyMine = true, displayMode = "present" },
        { spellID = 8936, label = "재생", anchor = "TOPRIGHT", x = -2, y = -2, onlyMine = true, displayMode = "present" },
        { spellID = 33763, label = "피어나는 생명", anchor = "BOTTOMLEFT", x = 2, y = 2, onlyMine = true, displayMode = "present" },
        { spellID = 48438, label = "야생 성장", anchor = "BOTTOMRIGHT", x = -2, y = 2, onlyMine = true, displayMode = "present" },
        { spellID = 102351, label = "세나리온 수호물", anchor = "LEFT", x = 2, y = 0, onlyMine = true, displayMode = "present" },
        { spellID = 200389, label = "재배", anchor = "RIGHT", x = -2, y = 0, onlyMine = true, displayMode = "present" },
    },

    PRIEST = {
        { spellID = 139, label = "소생", anchor = "TOPLEFT", x = 2, y = -2, onlyMine = true, displayMode = "present" },
        { spellID = 17, label = "신의 권능: 보호막", anchor = "TOPRIGHT", x = -2, y = -2, onlyMine = true, displayMode = "present" },
        { spellID = 194384, label = "속죄", anchor = "BOTTOMLEFT", x = 2, y = 2, onlyMine = true, displayMode = "present" },
        { spellID = 41635, label = "기도의 마법진", anchor = "BOTTOMRIGHT", x = -2, y = 2, onlyMine = false, displayMode = "present" },
    },

    PALADIN = {
        { spellID = 53563, label = "빛의 봉화", anchor = "TOPLEFT", x = 2, y = -2, onlyMine = true, displayMode = "present" },
        { spellID = 156910, label = "신념의 봉화", anchor = "TOPRIGHT", x = -2, y = -2, onlyMine = true, displayMode = "present" },
        { spellID = 200025, label = "미덕의 봉화", anchor = "TOP", x = 0, y = -2, onlyMine = true, displayMode = "present" },
        { spellID = 1044, label = "자유의 축복", anchor = "BOTTOMLEFT", x = 2, y = 2, onlyMine = false, displayMode = "present" },
        { spellID = 1022, label = "보호의 축복", anchor = "BOTTOMRIGHT", x = -2, y = 2, onlyMine = false, displayMode = "present" },
        { spellID = 6940, label = "희생의 축복", anchor = "BOTTOM", x = 0, y = 2, onlyMine = false, displayMode = "present" },
    },

    SHAMAN = {
        { spellID = 61295, label = "성난 해일", anchor = "TOPLEFT", x = 2, y = -2, onlyMine = true, displayMode = "present" },
        { spellID = 974, label = "대지의 보호막", anchor = "TOPRIGHT", x = -2, y = -2, onlyMine = true, displayMode = "present" },
    },

    MONK = {
        { spellID = 119611, label = "회복의 안개", anchor = "TOPLEFT", x = 2, y = -2, onlyMine = true, displayMode = "present" },
        { spellID = 124682, label = "포용의 안개", anchor = "TOPRIGHT", x = -2, y = -2, onlyMine = true, displayMode = "present" },
        { spellID = 116849, label = "기의 고치", anchor = "BOTTOM", x = 0, y = 2, onlyMine = true, displayMode = "present" },
    },

    EVOKER = {
        { spellID = 364343, label = "메아리", anchor = "TOPLEFT", x = 2, y = -2, onlyMine = true, displayMode = "present" },
        { spellID = 355941, label = "꿈 비행", anchor = "BOTTOMLEFT", x = 2, y = 2, onlyMine = true, displayMode = "present" },
        { spellID = 366155, label = "반전", anchor = "TOPRIGHT", x = -2, y = -2, onlyMine = true, displayMode = "present" },
    },

    MAGE = {
        { spellID = 1459, label = "비전 지능", anchor = "TOP", x = 0, y = -2, onlyMine = false, displayMode = "present" },
    },

    WARLOCK = {
        { spellID = 20707, label = "영혼석", anchor = "TOP", x = 0, y = -2, onlyMine = false, displayMode = "present" },
    },

    HUNTER = {},
    ROGUE = {},
    WARRIOR = {},
    DEATHKNIGHT = {},
    DEMONHUNTER = {},
}
