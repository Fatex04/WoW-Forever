local addonName, ns = ...
local DF = LibStub('AceAddon-3.0'):NewAddon('DragonflightUI', 'AceConsole-3.0')
ns.DF = DF
DF.IsForever = true
-- A running client can cache TOC metadata until its next full restart.
DF.version = '1.2.2'
DF.title = 'Dragonflight UI Forever - Luna'
DF.API = {Version = {
    InterfaceVersion = tonumber((select(4, GetBuildInfo()))) or 0,
    IsForever = true, IsMainline = true, IsClassic = false
}}
DragonflightUI_API = DF.API

DF.defaults = {
    enabled = true, frameTint = false, minimap = true, lunaEditMode = true, windows = true, flyouts = true,
    actionbars = true, actionbarBorders = true, hideBarArt = true,
    hotkeys = true, macroNames = true, hotkeySize = 12, macroSize = 11,
    unitframes = true, unitArt = true, unitTextures = true, unitFontScale = 1,
    auras = true, auraBorders = true, auraFontSize = 11,
    castbars = true, castbarFontSize = 12,
    tooltip = true, tooltipScale = 1,
}

function DF:CopyDefaults(destination)
    for key, value in pairs(self.defaults) do
        if type(destination[key]) ~= type(value) then destination[key] = value end
    end
    return destination
end

local function Secret(value)
    return type(issecretvalue) == 'function' and issecretvalue(value)
end
DF.IsSecretValue = Secret

-- Error messages and callback completion are local SavedVariables data. Never
-- suppress WoW's error display or replace secure/native gameplay callbacks.
local previousErrors
local errors, seenErrors = {}, {}
if type(geterrorhandler) == 'function' and type(seterrorhandler) == 'function' then
    local original = geterrorhandler()
    seterrorhandler(function(message)
        local stack = type(debugstack) == 'function' and debugstack(2, 15, 15) or ''
        if type(message) == 'string' and
            (message:find('DragonflightUI', 1, true) or stack:find('DragonflightUI', 1, true)) then
            if seenErrors[message] then
                seenErrors[message].count = seenErrors[message].count + 1
            elseif #errors < 50 then
                local entry = {message = message, stack = stack, count = 1}
                seenErrors[message] = entry
                errors[#errors + 1] = entry
            end
        end
        return original(message)
    end)
end

function DF:SaveDiagnostics()
    if not DragonflightUIDB then return end
    DragonflightUIDB.global = DragonflightUIDB.global or {}
    DragonflightUIDB.global.foreverDiagnostics = {
        version = self.version, build = {GetBuildInfo()}, nativeRuntime = true,
        errors = errors, previousErrors = previousErrors, modules = self.moduleStatus or {},
        lunaEditMode = {
            hooked = self.editModeHooked == true, enabled = self.settings and self.settings.lunaEditMode == true,
            visible = self.editModeSession ~= nil,
        },
    }
end

function DF:OnInitialize()
    DragonflightUIDB = DragonflightUIDB or {}
    -- SavedVariables are available at ADDON_LOADED, after the Lua chunks run.
    local diagnostics = DragonflightUIDB.global and DragonflightUIDB.global.foreverDiagnostics
    previousErrors = diagnostics and diagnostics.errors
    -- The Classic profiles remain intact. Forever's theme settings have their
    -- own account-wide section. The reference layout is a separate native copy.
    if type(DragonflightUIDB.forever) ~= 'table' then DragonflightUIDB.forever = {} end
    self.settings = self:CopyDefaults(DragonflightUIDB.forever)
    local limits = {
        hotkeySize = {8, 20}, macroSize = {8, 18}, unitFontScale = {0.75, 1.5},
        auraFontSize = {8, 18}, castbarFontSize = {8, 18}, tooltipScale = {0.75, 1.5}
    }
    for key, bounds in pairs(limits) do
        local value = self.settings[key]
        if value ~= value then value = self.defaults[key] end
        self.settings[key] = math.max(bounds[1], math.min(bounds[2], value))
    end
    self.moduleStatus = {}
    self:RegisterChatCommand('df', 'HandleCommand')
    self:RegisterChatCommand('dragonflight', 'HandleCommand')
    self:RegisterChatCommand('editmode', 'ToggleEditMode')
    self:InstallSettingsCategory()
end

function DF:HandleCommand(input)
    local command, argument = (input or ''):match('^%s*(%S*)%s*(.-)%s*$')
    command = command:lower()
    if command == 'classic' then
        if InCombatLockdown() then self:Print('Luna Classic: outside combat only.'); return end
        self:ApplyClassicReferenceLayout(true)
        self:QueueRefresh()
    elseif command == 'windows' or command == 'fenster' then
        self:ToggleWindowBrowser()
    elseif command == 'flyouts' or command == 'flyout' then
        self:ToggleFlyoutEditor(tonumber(argument))
    elseif command == 'patchnotes' or command == 'changelog' or command == 'discord' then
        self:ShowUpdateNotice(true)
    elseif command == 'debug' then
        self:Print(self.version .. ' | Luna frames, bars, minimap | windows: ' .. tostring(self.styledWindowCount or 0))
        for _, entry in ipairs(errors) do self:Print(entry.message) end
    else
        self:ToggleOptions()
    end
end

function DF:OnEnable()
    self.active = true
    self:InstallGameMenuEntry()
    self:InstallLunaEditMode()
    if EventRegistry and not self.layoutHooked then
        self.layoutHooked = true
        EventRegistry:RegisterCallback('EditMode.Exit', self.QueueRefresh, self)
        EventRegistry:RegisterCallback('EditMode.Exit', self.QueueUpdateNotice, self)
        EventRegistry:RegisterCallback('EditMode.SavedLayouts', self.QueueRefresh, self)
    end
    self:QueueRefresh()
    self:QueueUpdateNotice()
    self:Print(self.version .. ' — /df')
end

function DF:OnDisable()
    self.active = false
    self:EndLunaEditMode()
    if self.updateNotice then self.updateNotice:Hide() end
    self:RefreshFlyouts()
    if not InCombatLockdown() then self:ApplyTheme() else self.pendingThemeDisable=true end
end

function DF:QueueRefresh()
    if self.refreshQueued or not self.active then return end
    self.refreshQueued = true
    C_Timer.After(0, function()
        self.refreshQueued = false
        if InCombatLockdown() then
            self.pendingRefresh = true
            return
        end
        self.pendingRefresh = false
        self:ApplyTheme()
        self:SaveDiagnostics()
    end)
end

function DF:OpenLunaEditMode()
    if InCombatLockdown() then
        self:Print('Edit Mode is available outside combat.')
        return
    end
    if not EditModeManagerFrame then C_AddOns.LoadAddOn('Blizzard_EditMode') end
    if EditModeManagerFrame then
        if EditModeManagerFrame.CanEnterEditMode and not EditModeManagerFrame:CanEnterEditMode() then return end
        if self.options then self.options:Hide() end
        HideUIPanel(GameMenuFrame)
        self:InstallLunaEditMode()
        ShowUIPanel(EditModeManagerFrame)
    end
end
-- Keep the earlier entry point usable by integrations.
DF.OpenNativeEditMode = DF.OpenLunaEditMode

function DF:ToggleEditMode()
    local manager = EditModeManagerFrame
    if manager and manager:IsShown() then
        manager.onCloseCallback()
    else
        self:OpenLunaEditMode()
    end
end

function DF:InstallGameMenuEntry()
    local menu = GameMenuFrame
    if self.menuHooked or not menu or type(menu.InitButtons) ~= 'function' or
        type(menu.AddButton) ~= 'function' then return end
    self.menuHooked = true
    hooksecurefunc(menu, 'InitButtons', function()
        if not menu.buttonPool then return end
        local index = menu.closeButton and menu.closeButton.layoutIndex or menu.nextLayoutIndex
        for button in menu.buttonPool:EnumerateActive() do
            if button.layoutIndex and button.layoutIndex >= index then
                button.layoutIndex = button.layoutIndex + 1
            end
        end
        local button = menu:AddButton(DF.title, function()
            HideUIPanel(menu)
            DF:ToggleOptions()
        end)
        button.layoutIndex = index
        button.topPadding = nil
        -- Keep keyboard/gamepad traversal in the same order as the layout.
        if menu.closeButton and menu.buttons then
            for position, other in ipairs(menu.buttons) do
                if other == menu.closeButton then
                    table.remove(menu.buttons, #menu.buttons)
                    table.insert(menu.buttons, position, button)
                    break
                end
            end
        end
        -- The menu owns this pooled button and its lifetime/layout. There are
        -- no floating Classic buttons or changes to native click handlers.
        menu:MarkDirty()
        if menu.SetupGamepadButtons then menu:SetupGamepadButtons() end
    end)
end

local visualEvents = {
    UNIT_HEALTH=true, UNIT_MAXHEALTH=true, UNIT_POWER_UPDATE=true, UNIT_MAXPOWER=true,
    UNIT_DISPLAYPOWER=true, UNIT_NAME_UPDATE=true, UNIT_PORTRAIT_UPDATE=true, UNIT_LEVEL=true,
    UNIT_FLAGS=true, PLAYER_UPDATE_RESTING=true,
}
local portraitEvents = {UNIT_PORTRAIT_UPDATE=true, PLAYER_TARGET_CHANGED=true,
    PLAYER_FOCUS_CHANGED=true, PLAYER_ENTERING_WORLD=true, UNIT_PET=true}
local events = CreateFrame('Frame')
for _, event in ipairs({
    'ADDON_LOADED', 'PLAYER_ENTERING_WORLD', 'PLAYER_REGEN_ENABLED',
    'UPDATE_BINDINGS', 'ACTIONBAR_PAGE_CHANGED', 'SPELLS_CHANGED', 'PLAYER_LOGOUT',
    'PLAYER_TARGET_CHANGED', 'PLAYER_FOCUS_CHANGED', 'UNIT_PET',
    'UI_SCALE_CHANGED', 'DISPLAY_SIZE_CHANGED', 'PLAYER_REGEN_DISABLED', 'EDIT_MODE_LAYOUTS_UPDATED',
    'UNIT_HEALTH', 'UNIT_MAXHEALTH', 'UNIT_POWER_UPDATE', 'UNIT_MAXPOWER',
    'UNIT_DISPLAYPOWER', 'UNIT_NAME_UPDATE', 'UNIT_PORTRAIT_UPDATE', 'UNIT_LEVEL', 'UNIT_FLAGS',
    'PLAYER_UPDATE_RESTING'
}) do events:RegisterEvent(event) end
local flyoutDisplayEvents = {'SPELL_UPDATE_COOLDOWN','SPELL_UPDATE_CHARGES','ACTIONBAR_UPDATE_COOLDOWN','BAG_UPDATE_DELAYED','GET_ITEM_INFO_RECEIVED'}
local flyoutDataEvents = {UPDATE_MACROS=true,EQUIPMENT_SETS_CHANGED=true}
local displayEvents = {}
for _, event in ipairs(flyoutDisplayEvents) do displayEvents[event]=true; events:RegisterEvent(event) end
for event in pairs(flyoutDataEvents) do events:RegisterEvent(event) end
events:SetScript('OnEvent', function(_, event)
    if displayEvents[event] then if DF.active then DF:QueueFlyoutDisplays() end; return end
    if flyoutDataEvents[event] then
        if DF.active then DF:RefreshFlyouts() end
        return
    end
    if event == 'PLAYER_REGEN_ENABLED' and DF.pendingFlyouts then DF:RefreshFlyouts() end
    if event == 'PLAYER_REGEN_ENABLED' and DF.pendingThemeDisable then
        DF.pendingThemeDisable=false
        DF:ApplyTheme()
    end
    if DF.UpdateLunaUnitVisuals and DF.active then DF:UpdateLunaUnitVisuals(portraitEvents[event]) end
    if visualEvents[event] then return end
    if event == 'PLAYER_LOGOUT' then
        DF:SaveDiagnostics()
    elseif event == 'PLAYER_REGEN_DISABLED' then
        DF:EndLunaEditMode()
        DF:RefreshFlyoutMovers()
        if DF.flyoutEditor then DF.flyoutEditor:Hide() end
    elseif DF.active then
        if event == 'ADDON_LOADED' then
            DF:InstallGameMenuEntry()
            DF:InstallSettingsCategory()
            DF:InstallLunaEditMode()
        end
        DF:QueueRefresh()
        if event == 'PLAYER_ENTERING_WORLD' or event == 'PLAYER_REGEN_ENABLED' then DF:QueueUpdateNotice() end
    end
end)
