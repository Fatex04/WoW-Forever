local _, addonTable = ...
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

-- This file is loaded only by DragonflightUI_Camelot.toc.
DF.IsForever = true

if type(_G.FillLocalizedClassList) ~= 'function' then
    _G.FillLocalizedClassList = function(destination, female)
        local names = female and LOCALIZED_CLASS_NAMES_FEMALE or LOCALIZED_CLASS_NAMES_MALE
        for token, name in pairs(names or {}) do destination[token] = name end
        return destination
    end
end

-- Keep a bounded local record of startup failures. FrameXML.log does not
-- contain Lua callback errors; forward every error to the existing handler.
local previousErrors = DragonflightUIDB and DragonflightUIDB.global and
    DragonflightUIDB.global.foreverDiagnostics and DragonflightUIDB.global.foreverDiagnostics.errors
local diagnostics = {
    version = C_AddOns.GetAddOnMetadata('DragonflightUI', 'Version'),
    build = {GetBuildInfo()},
    errors = {},
    previousErrors = previousErrors,
    modules = {}
}
DF.ForeverDiagnostics = diagnostics

local function SaveDiagnostics()
    if DF.db then
        DF.db.global.foreverDiagnostics = diagnostics
    else
        DragonflightUIDB = DragonflightUIDB or {}
        DragonflightUIDB.global = DragonflightUIDB.global or {}
        DragonflightUIDB.global.foreverDiagnostics = diagnostics
    end
end

if type(geterrorhandler) == 'function' and type(seterrorhandler) == 'function' then
    local originalHandler = geterrorhandler()
    seterrorhandler(function(message)
        local stack = type(debugstack) == 'function' and debugstack(2, 20, 20) or ''
        if type(message) == 'string' and
            (message:find('DragonflightUI', 1, true) or stack:find('DragonflightUI', 1, true)) then
            if #diagnostics.errors < 10 then
                diagnostics.errors[#diagnostics.errors + 1] = {message = message, stack = stack}
                SaveDiagnostics()
            end
        end
        return originalHandler(message)
    end)
end

local diagnosticFrame = CreateFrame('Frame')
diagnosticFrame:RegisterEvent('PLAYER_LOGIN')
diagnosticFrame:RegisterEvent('PLAYER_LOGOUT')
diagnosticFrame:SetScript('OnEvent', function(_, event)
    if event == 'PLAYER_LOGOUT' then
        SaveDiagnostics()
        return
    end
    C_Timer.After(3, function()
        local ace = LibStub('AceAddon-3.0')
        for name, module in pairs(DF.modules) do
            diagnostics.modules[name] = {
                enabled = ace.statuses[module.name] == true,
                requested = module.enabledState == true,
                setupEntered = module.wasEnabled == true
            }
        end
        SaveDiagnostics()
    end)
end)

local function GetSpellInfoCompat(spell)
    if not C_Spell or type(C_Spell.GetSpellInfo) ~= 'function' then return nil end

    local spellInfo = C_Spell.GetSpellInfo(spell)
    if not spellInfo then return nil end

    return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange,
        spellInfo.spellID, spellInfo.originalIconID
end

if type(_G.GetSpellInfo) ~= 'function' then _G.GetSpellInfo = GetSpellInfoCompat end
if type(_G.GetItemInfo) ~= 'function' and C_Item and type(C_Item.GetItemInfo) == 'function' then
    _G.GetItemInfo = C_Item.GetItemInfo
end
if type(_G.GetItemInfoInstant) ~= 'function' and C_Item and type(C_Item.GetItemInfoInstant) == 'function' then
    _G.GetItemInfoInstant = C_Item.GetItemInfoInstant
end
if type(_G.GetAddOnMetadata) ~= 'function' and C_AddOns and type(C_AddOns.GetAddOnMetadata) == 'function' then
    _G.GetAddOnMetadata = C_AddOns.GetAddOnMetadata
end

local function GetAuraData(unit, index, filter)
    if not C_UnitAuras or type(C_UnitAuras.GetAuraDataByIndex) ~= 'function' then return nil end
    return C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
end

local function AuraDataToLegacyReturns(aura)
    if not aura then return nil end

    return aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration, aura.expirationTime,
        aura.sourceUnit, aura.isStealable, aura.nameplateShowPersonal, aura.spellId, aura.canApplyAura,
        aura.isBossAura, aura.isFromPlayerOrPlayerPet, aura.nameplateShowAll, aura.timeMod,
        aura.value1, aura.value2, aura.value3
end

if type(_G.UnitAura) ~= 'function' then
    _G.UnitAura = function(unit, index, filter)
        return AuraDataToLegacyReturns(GetAuraData(unit, index, filter))
    end
end
if type(_G.UnitBuff) ~= 'function' then
    _G.UnitBuff = function(unit, index, filter)
        return _G.UnitAura(unit, index, filter or 'HELPFUL')
    end
end
if type(_G.UnitDebuff) ~= 'function' then
    _G.UnitDebuff = function(unit, index, filter)
        return _G.UnitAura(unit, index, filter or 'HARMFUL')
    end
end

if type(_G.GetSpellBookItemInfo) ~= 'function' and C_SpellBook and
    type(C_SpellBook.GetSpellBookItemInfo) == 'function' then
    local spellBookItemTypes = {
        [1] = 'SPELL',
        [2] = 'FUTURESPELL',
        [3] = 'PETACTION',
        [4] = 'FLYOUT'
    }

    _G.GetSpellBookItemInfo = function(index, spellBookType)
        local spellBookBank = Enum and Enum.SpellBookSpellBank
        if type(spellBookType) == 'string' and spellBookBank then
            spellBookType = string.lower(spellBookType) == 'pet' and spellBookBank.Pet or spellBookBank.Player
        elseif spellBookType == nil and spellBookBank then
            spellBookType = spellBookBank.Player
        end

        local info = C_SpellBook.GetSpellBookItemInfo(index, spellBookType)
        if not info then return nil end

        local itemType = info.itemType
        local itemTypeName = spellBookItemTypes[itemType]
        if not itemTypeName and type(itemType) == 'string' then itemTypeName = string.upper(itemType) end

        return itemTypeName or 'NONE', info.spellID, info
    end
end

if type(_G.InterfaceOptionsFrame_OpenToCategory) ~= 'function' and Settings and
    type(Settings.OpenToCategory) == 'function' then
    _G.InterfaceOptionsFrame_OpenToCategory = function(category)
        if type(category) == 'table' and category.GetName then
            category = category:GetName()
        end
        return Settings.OpenToCategory(category)
    end
end

if C_QuestLog then
    if type(_G.GetNumQuestLogEntries) ~= 'function' and type(C_QuestLog.GetNumQuestLogEntries) == 'function' then
        _G.GetNumQuestLogEntries = C_QuestLog.GetNumQuestLogEntries
    end

    if type(_G.GetQuestLogTitle) ~= 'function' and type(C_QuestLog.GetInfo) == 'function' then
        _G.GetQuestLogTitle = function(index)
            local info = C_QuestLog.GetInfo(index)
            if not info then return nil end

            return info.title, info.level, info.suggestedGroup, info.isHeader, info.isCollapsed, info.isComplete,
                info.frequency, info.questID, info.isOnMap, info.hasLocalPOI, info.isTask, info.isBounty,
                info.isStory or info.isCampaign, info.isHidden, info.isScaling
        end
    end

    if type(_G.GetQuestLogSelection) ~= 'function' and type(C_QuestLog.GetSelectedQuest) == 'function' and
        type(C_QuestLog.GetLogIndexForQuestID) == 'function' then
        _G.GetQuestLogSelection = function()
            local questID = C_QuestLog.GetSelectedQuest()
            return questID and C_QuestLog.GetLogIndexForQuestID(questID) or nil
        end
    end

    if type(_G.SelectQuestLogEntry) ~= 'function' and type(C_QuestLog.GetInfo) == 'function' and
        type(C_QuestLog.SetSelectedQuest) == 'function' then
        _G.SelectQuestLogEntry = function(index)
            local info = C_QuestLog.GetInfo(index)
            if info and info.questID then return C_QuestLog.SetSelectedQuest(info.questID) end
        end
    end
end

-- Forever provides modern aura-duration handling. The bundled duration override
-- is Classic-only, so keep the legacy call site harmless without loading it.
local auraDurations = LibStub('AuraDurations-1.0', true)
if not auraDurations then auraDurations = LibStub:NewLibrary('AuraDurations-1.0', 2) end
if auraDurations and not auraDurations.frame then
    auraDurations.frame = {
        SetState = function() end
    }
end
