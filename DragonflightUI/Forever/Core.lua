local addonName, ns = ...
local DF = LibStub('AceAddon-3.0'):NewAddon('DragonflightUI', 'AceConsole-3.0')
ns.DF = DF
DF.IsForever = true
DF.version = C_AddOns.GetAddOnMetadata(addonName, 'Version')
DF.API = {Version = {
    InterfaceVersion = tonumber((select(4, GetBuildInfo()))) or 0,
    IsForever = true, IsMainline = true, IsClassic = false
}}
DragonflightUI_API = DF.API

DF.defaults = {
    enabled = true, frameTint = true, minimap = true,
    actionbars = true, actionbarBorders = true, hideBarArt = true,
    hotkeys = true, macroNames = true, hotkeySize = 12, macroSize = 11,
    unitframes = true, unitTextures = true, unitFontScale = 1,
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
        errors = errors, previousErrors = previousErrors, modules = self.moduleStatus or {}
    }
end

function DF:OnInitialize()
    DragonflightUIDB = DragonflightUIDB or {}
    -- SavedVariables are available at ADDON_LOADED, after the Lua chunks run.
    local diagnostics = DragonflightUIDB.global and DragonflightUIDB.global.foreverDiagnostics
    previousErrors = diagnostics and diagnostics.errors
    -- The Classic profiles remain intact. Forever's theme settings have their
    -- own account-wide section and do not rewrite server-owned Edit Mode data.
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
    self:RegisterChatCommand('df', 'ToggleOptions')
    self:RegisterChatCommand('dragonflight', 'ToggleOptions')
    self:InstallSettingsCategory()
end

function DF:OnEnable()
    self.active = true
    self:InstallGameMenuEntry()
    if EventRegistry and not self.layoutHooked then
        self.layoutHooked = true
        EventRegistry:RegisterCallback('EditMode.Exit', self.QueueRefresh, self)
        EventRegistry:RegisterCallback('EditMode.SavedLayouts', self.QueueRefresh, self)
    end
    self:QueueRefresh()
    self:Print(self.version .. ' — /df')
end

function DF:OnDisable()
    self.active = false
    if not InCombatLockdown() then self:ApplyTheme() end
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

function DF:OpenNativeEditMode()
    if InCombatLockdown() then
        self:Print('Edit Mode is available outside combat.')
        return
    end
    if not EditModeManagerFrame then C_AddOns.LoadAddOn('Blizzard_EditMode') end
    if EditModeManagerFrame then
        if self.options then self.options:Hide() end
        HideUIPanel(GameMenuFrame)
        ShowUIPanel(EditModeManagerFrame)
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
        local button = menu:AddButton('Dragonflight UI Luna', function()
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

local events = CreateFrame('Frame')
for _, event in ipairs({
    'ADDON_LOADED', 'PLAYER_ENTERING_WORLD', 'PLAYER_REGEN_ENABLED',
    'UPDATE_BINDINGS', 'ACTIONBAR_PAGE_CHANGED', 'SPELLS_CHANGED', 'PLAYER_LOGOUT',
    'PLAYER_TARGET_CHANGED', 'PLAYER_FOCUS_CHANGED', 'UNIT_PET',
    'UI_SCALE_CHANGED', 'DISPLAY_SIZE_CHANGED'
}) do events:RegisterEvent(event) end
events:SetScript('OnEvent', function(_, event)
    if event == 'PLAYER_LOGOUT' then
        DF:SaveDiagnostics()
    elseif DF.active then
        if event == 'ADDON_LOADED' then
            DF:InstallGameMenuEntry()
            DF:InstallSettingsCategory()
        end
        DF:QueueRefresh()
    end
end)
