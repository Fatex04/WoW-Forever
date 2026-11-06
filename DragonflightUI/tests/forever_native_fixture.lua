-- Deliberately strict native-UI model for the 1.60.1.70790 frame shapes.
-- No legacy player/target globals, aura headers, or generic method fallbacks.
frames, queued, messages, reportedErrors, requestedTemplates = {}, {}, {}, {}, {}
-- WoW extends Lua 5.1 xpcall with callback arguments (used by AceAddon).
local lua51xpcall = xpcall
xpcall = function(callback, handler, ...)
    local arguments, count = {...}, select('#', ...)
    return lua51xpcall(function() return callback(unpack(arguments, 1, count)) end, handler)
end
loggedIn, combat = false, false
STANDARD_TEXT_FONT = 'Fonts\\FRIZQT__.TTF'
UISpecialFrames, SlashCmdList, hash_SlashCmdList = {}, {}, {}
WOW_PROJECT_ID, WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC = 1, 1, 2
GetLocale = function() return TEST_LOCALE or 'enUS' end
GetBuildInfo = function() return '1.60.1', '70790', 'Nov 3 2026', 16001, '', ' ' end
IsLoggedIn = function() return loggedIn end
InCombatLockdown = function() return combat end
issecretvalue = function(value) return type(value) == 'table' and rawget(value, 'secret') == true end
debugstack = function() return 'Interface/AddOns/DragonflightUI/Forever/test callback' end
local errorHandler = function(message) reportedErrors[#reportedErrors + 1] = tostring(message) end
geterrorhandler = function() return errorHandler end
seterrorhandler = function(callback) errorHandler = callback end
wipe = function(t) for k in pairs(t) do t[k] = nil end; return t end
securecallfunction = function(callback, ...) return callback(...) end
DEFAULT_CHAT_FRAME = {AddMessage = function(_, message) messages[#messages + 1] = message end}
C_AddOns = {
    GetAddOnMetadata = function(_, key) return key == 'Version' and '1.6.0' or nil end,
    LoadAddOn = function() error('Unexpected load-on-demand gameplay dependency') end,
}
C_EditMode = {
    SaveLayouts = function() error('Must not rewrite native layouts') end,
    SetActiveLayout = function() error('Must not select/reset native layouts') end,
}
C_Timer = {After = function(_, callback) queued[#queued + 1] = callback end}
function flushTimers()
    local count = 0
    while #queued > 0 do
        count = count + 1
        assert(count < 100, 'refresh loop')
        table.remove(queued, 1)()
    end
end
function hooksecurefunc(object, key, callback)
    if type(object) == 'string' then callback, key, object = key, object, _G end
    local original = assert(object[key], 'Cannot hook missing method: ' .. tostring(key))
    object[key] = function(...)
        local results = {original(...)}
        callback(...)
        return unpack(results)
    end
end

local Region = {}
Region.__index = Region
local function region(kind)
    return setmetatable({kind = kind, alpha = 0.8, font = {'NativeFont', 10, 'OUTLINE'},
        texture = 'native-texture', atlas = 'native-atlas', coords = {0.1, 0.9, 0.2, 0.8},
        shown = true, points = {}, width = 30, height = 30, writes = 0,
        vertexColor = {1, 1, 1, 1}, desaturated = false}, Region)
end
function Region:GetObjectType() return self.kind end
function Region:IsForbidden() return self.forbidden == true end
function Region:SetPoint(...) self.points[#self.points + 1] = {...} end
function Region:ClearAllPoints() self.points = {} end
function Region:SetSize(width, height) self.width, self.height = width, height end
function Region:SetAllPoints(owner) self.points = {{'TOPLEFT', owner, 'TOPLEFT'}, {'BOTTOMRIGHT', owner, 'BOTTOMRIGHT'}} end
function Region:GetWidth() return self.width end
function Region:GetHeight() return self.height end
function Region:SetWidth(width) self.width = width end
function Region:SetHeight(height) self.height = height end
function Region:GetAlpha() return self.alpha end
function Region:SetAlpha(alpha) self.alpha = alpha; self.writes = self.writes + 1 end
function Region:SetTexture(texture) self.texture, self.atlas = texture, nil; self.writes = self.writes + 1 end
function Region:GetTexture() assert(not self.privateContent, 'Read native spell icon'); return self.texture end
function Region:SetAtlas(atlas) self.atlas = atlas end
function Region:GetAtlas() return self.atlas end
function Region:GetTexCoord() return unpack(self.coords) end
function Region:SetTexCoord(...) self.coords = {...} end
function Region:SetColorTexture(...) self.color = {...} end
function Region:GetVertexColor() return unpack(self.vertexColor) end
function Region:SetVertexColor(...) self.vertexColor = {...} end
function Region:IsDesaturated() return self.desaturated end
function Region:SetDesaturated(value) self.desaturated = value end
function Region:GetFont() return unpack(self.font) end
function Region:SetFont(file, size, flags)
    assert(type(file) == 'string' and type(size) == 'number' and size > 0, 'Font not set')
    self.font = {file, size, flags}; self.writes = self.writes + 1
end
function Region:SetText(text) assert(not self.privateContent, 'Reimplemented native unit/aura text'); self.text = text end
function Region:GetText() assert(not self.privateContent, 'Read native unit/aura text'); return self.text end
function Region:SetJustifyH() end
function Region:SetWordWrap() end
function Region:Hide() self.shown = false end
function Region:Show() self.shown = true end
function Region:SetShown(shown) self.shown = shown end

local Frame = {}
Frame.__index = Frame
local function geometryAllowed(self)
    assert(not self.gameplay, 'Modified protected gameplay geometry or lifetime: ' .. tostring(self.name))
end
local function newFrame(kind, name, parent)
    local frame = setmetatable({kind = kind, name = name, parent = parent, children = {},
        events = {}, scripts = {}, scriptHooks = {}, points = {}, width = 200, height = 50,
        scale = 1, alpha = 1, shown = true}, Frame)
    if parent then parent.children[#parent.children + 1] = frame end
    frames[#frames + 1] = frame
    if name then _G[name] = frame end
    return frame
end
function Frame:GetName() return self.name end
function Frame:GetObjectType() return self.kind end
function Frame:IsForbidden() return self.forbidden == true end
function Frame:SetPoint(...) geometryAllowed(self); self.points[#self.points + 1] = {...} end
function Frame:ClearAllPoints() geometryAllowed(self); self.points = {} end
function Frame:GetPoint() return unpack(self.points[1] or {'CENTER', UIParent, 'CENTER', 0, 0}) end
function Frame:SetSize(width, height) geometryAllowed(self); self.width, self.height = width, height end
function Frame:SetWidth(width) geometryAllowed(self); self.width = width end
function Frame:SetHeight(height) geometryAllowed(self); self.height = height end
function Frame:GetWidth() return self.width end
function Frame:GetHeight() return self.height end
function Frame:SetScale(scale) geometryAllowed(self); self.scale = scale end
function Frame:GetScale() return self.scale end
function Frame:GetAlpha() return self.alpha end
function Frame:SetAlpha(alpha) assert(not self.gameplay); self.alpha = alpha end
function Frame:SetFrameStrata() geometryAllowed(self) end
function Frame:SetToplevel() geometryAllowed(self) end
function Frame:SetClampedToScreen() geometryAllowed(self) end
function Frame:EnableMouse(enabled) geometryAllowed(self); self.mouseEnabled = enabled end
function Frame:IsMouseEnabled() return self.mouseEnabled == true end
function Frame:SetFrameLevel(level) geometryAllowed(self); self.frameLevel = level end
function Frame:SetAllPoints(owner) geometryAllowed(self); self.points = {{'TOPLEFT', owner, 'TOPLEFT'}, {'BOTTOMRIGHT', owner, 'BOTTOMRIGHT'}} end
function Frame:GetNumPoints() return #self.points end
function Frame:GetParent() return self.parent end
function Frame:SetParent(parent)
    geometryAllowed(self)
    if self.parent then
        for index, child in ipairs(self.parent.children) do
            if child == self then table.remove(self.parent.children, index); break end
        end
    end
    self.parent = parent
    if parent then parent.children[#parent.children + 1] = self end
end
function Frame:SetMovable() geometryAllowed(self) end
function Frame:RegisterForDrag() geometryAllowed(self) end
function Frame:StartMoving() geometryAllowed(self) end
function Frame:StopMovingOrSizing() geometryAllowed(self) end
function Frame:SetBackdrop() geometryAllowed(self) end
function Frame:SetBackdropColor() geometryAllowed(self) end
function Frame:SetBackdropBorderColor() geometryAllowed(self) end
function Frame:CreateTexture() local r = region('Texture'); r.owner = self; return r end
function Frame:CreateFontString() local r = region('FontString'); r.owner = self; return r end
function Frame:SetScript(event, callback) geometryAllowed(self); self.scripts[event] = callback end
function Frame:GetScript(event) return self.scripts[event] end
function Frame:HookScript(event, callback)
    geometryAllowed(self)
    self.scriptHooks[event] = self.scriptHooks[event] or {}
    table.insert(self.scriptHooks[event], callback)
end
function Frame:RegisterEvent(event) assert(not self.gameplay); self.events[event] = true end
function Frame:UnregisterEvent() error('Must not unregister native gameplay events') end
function Frame:UnregisterAllEvents() error('Must not unregister native gameplay events') end
function Frame:IsShown() return self.shown end
function Frame:Hide()
    geometryAllowed(self)
    local wasShown = self.shown
    self.shown = false
    if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
    if wasShown then for _, callback in ipairs(self.scriptHooks.OnHide or {}) do callback(self) end end
end
function Frame:Show()
    geometryAllowed(self); self.shown = true
    if self.scripts.OnShow then self.scripts.OnShow(self) end
    for _, callback in ipairs(self.scriptHooks.OnShow or {}) do callback(self) end
end
function Frame:SetShown(shown) if shown then self:Show() else self:Hide() end end
function Frame:GetChildren() return unpack(self.children) end
function Frame:GetRegions() return unpack(self.regions or {}) end
function Frame:GetStatusBarTexture() return self.fill end
function Frame:GetValue() error('Must not read concealed native bar values') end
function Frame:GetMinMaxValues() error('Must not read concealed native bar values') end
function Frame:SetAttribute() error('Must not replace secure native actions') end
function Frame:SetNormalTexture(path) self.normal = region('Texture'); self.normal:SetTexture(path) end
function Frame:GetNormalTexture() return self.normal end
function Frame:SetPushedTexture(path) self.pushed = region('Texture'); self.pushed:SetTexture(path) end
function Frame:GetPushedTexture() return self.pushed end
function Frame:SetCheckedTexture(path) self.checkedTexture = region('Texture'); self.checkedTexture:SetTexture(path) end
function Frame:GetCheckedTexture() return self.checkedTexture end
function Frame:SetChecked(checked) self.checked = checked end
function Frame:GetChecked() return self.checked end
function Frame:SetOrientation() end
function Frame:SetMinMaxValues(low, high) self.low, self.high = low, high end
function Frame:SetValueStep(step) self.step = step end
function Frame:SetObeyStepOnDrag() end
function Frame:SetThumbTexture() self.thumb = region('Texture') end
function Frame:GetThumbTexture() return self.thumb end
function Frame:SetValue(value)
    self.value = value
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
end
function Frame:GetText() return self.text end
function Frame:SetText(text) self.text = text end
function Frame:MarkDirty() self.dirty = true end

function CreateFrame(kind, name, parent, template)
    assert(not template or template == 'BackdropTemplate', 'Unexpected UI template: ' .. tostring(template))
    if template then requestedTemplates[#requestedTemplates + 1] = template end
    return newFrame(kind, name, parent)
end
UIParent = newFrame('Frame', 'UIParent')
UIParent.height = 1440
function ShowUIPanel(frame) frame:Show() end
function HideUIPanel(frame) if frame then frame:Hide() end end
Settings = {
    RegisterCanvasLayoutCategory = function(panel, name) return {panel = panel, name = name} end,
    RegisterAddOnCategory = function(category) Settings.category = category end,
}
EditModeManagerFrame = newFrame('Frame', 'EditModeManagerFrame', UIParent)
EditModeManagerFrame:Hide()
EventRegistry = {callbacks = {}}
function EventRegistry:RegisterCallback(event, callback, owner)
    self.callbacks[event] = self.callbacks[event] or {}
    table.insert(self.callbacks[event], {callback, owner})
end
function EventRegistry:TriggerEvent(event)
    for _, registered in ipairs(self.callbacks[event] or {}) do registered[1](registered[2]) end
end
EditModeManagerFrame:EnableMouse(true)
EditModeManagerFrame.Title = region('FontString')
EditModeManagerFrame.LayoutLabel = region('FontString')
for _, key in ipairs({'Border', 'Tutorial', 'CloseButton', 'LayoutDropdown', 'ShowGridCheckButton',
    'GridSpacingSlider', 'EnableSnapCheckButton', 'EnableAdvancedOptionsCheckButton', 'AccountSettings',
    'SaveChangesButton', 'RevertAllChangesButton'}) do
    local control = newFrame('Frame', nil, EditModeManagerFrame)
    control:SetPoint('TOPLEFT', EditModeManagerFrame, 'TOPLEFT', 5, -15)
    control:EnableMouse(true)
    EditModeManagerFrame[key] = control
end
EditModeManagerFrame.AccountSettings.height = 45
function EditModeManagerFrame:CanEnterEditMode() return not combat end
function EditModeManagerFrame:IsEditModeActive() return self.editModeActive == true end
function EditModeManagerFrame:Layout() self.layouts = (self.layouts or 0) + 1 end
function EditModeManagerFrame:SelectSystem(systemFrame) self.nativeSelectedSystem = systemFrame end
function EditModeManagerFrame:EnterEditMode()
    self.editModeActive = true
    EventRegistry:TriggerEvent('EditMode.Enter')
end
EditModeManagerFrame.scripts.OnShow = function(self)
    if not self.locked then self:EnterEditMode() end
    self:Layout()
end
EditModeManagerFrame.scripts.OnHide = function(self)
    if not self.locked then
        self.editModeActive = false
        EventRegistry:TriggerEvent('EditMode.Exit')
    end
end
EditModeManagerFrame.onCloseCallback = function()
    if EditModeManagerFrame.unsavedChanges then
        EditModeManagerFrame.warningShown = true
    else
        HideUIPanel(EditModeManagerFrame)
    end
end
EditModeManagerFrame.SaveChangesButton.scripts.OnClick = function()
    EditModeManagerFrame.saves = (EditModeManagerFrame.saves or 0) + 1
    EditModeManagerFrame.unsavedChanges = false
end
EditModeManagerFrame.RevertAllChangesButton.scripts.OnClick = function()
    EditModeManagerFrame.reverts = (EditModeManagerFrame.reverts or 0) + 1
    EditModeManagerFrame.unsavedChanges = false
end

local function nativeButton(name)
    local button = newFrame('CheckButton', name)
    button.icon = region('Texture'); button.icon.privateContent = true
    button.normal = region('Texture')
    button.pushed = region('Texture')
    button.SlotArt = region('Texture')
    button.SlotBackground = region('Texture')
    button.TextOverlayContainer = {HotKey = region('FontString')}
    button.Name = region('FontString')
    button.secureAction = 'native-action'
    button.scripts.OnClick = function() return 'native-click' end
    button.gameplay = true
    function button:UpdateButtonArt()
        self.nativeArtUpdates = (self.nativeArtUpdates or 0) + 1
        self.normal:SetAtlas('updated-native-normal')
        self.normal:SetSize(51, 51)
        self.pushed:SetAtlas('updated-native-pushed')
    end
    return button
end
for _, name in ipairs({'MainActionBar', 'MultiBarBottomLeft', 'MultiBarBottomRight', 'MultiBarLeft',
    'MultiBarRight', 'MultiBar5', 'MultiBar6', 'MultiBar7', 'PetActionBar', 'StanceBar', 'PossessActionBar'}) do
    local bar = newFrame('Frame', name)
    bar.actionButtons = {nativeButton(name .. 'Button1'), nativeButton(name .. 'Button2')}
    bar.gameplay = true
end
MainActionBar.BorderArt = region('Texture')
MainActionBar.EndCaps = {LeftEndCap = {Texture = region('Texture')}, RightEndCap = {Texture = region('Texture')}}
local divider = newFrame('Frame')
divider.regions = {region('Texture'), region('Texture')}
MainActionBar.HorizontalDividersPool = {EnumerateActive = function()
    local yielded = false
    return function() if not yielded then yielded = true; return divider end end
end}
MainActionBar.VerticalDividersPool = {EnumerateActive = function() return function() end end}
function MainActionBar:UpdateDividers() self.nativeDividerUpdates = (self.nativeDividerUpdates or 0) + 1 end
SpellFlyout = newFrame('Frame', 'SpellFlyout')
SpellFlyout.children = {nativeButton('NativeFlyout1')}
SpellFlyout.gameplay = true
function SpellFlyout:Toggle()
    self.nativeToggles = (self.nativeToggles or 0) + 1
    if #self.children == 1 then self.children[2] = nativeButton('NativeFlyout2') end
    return 'native-flyout'
end

local function statusbar(name)
    local bar = newFrame('StatusBar', name)
    bar.fill = region('Texture')
    bar.fill.masks = {'native-mask'}
    bar.Text = region('FontString'); bar.Text.privateContent = true
    bar.TextString = region('FontString'); bar.TextString.privateContent = true
    bar.LeftText = region('FontString'); bar.LeftText.privateContent = true
    bar.RightText = region('FontString'); bar.RightText.privateContent = true
    bar.gameplay = true
    return bar
end
for _, name in ipairs({'PlayerFrame', 'TargetFrame', 'FocusFrame', 'PetFrame', 'TargetFrameToT', 'FocusFrameToT'}) do
    local frame = newFrame('Button', name)
    local main = {HealthBarsContainer = {HealthBar = statusbar()}, ManaBar = statusbar(), Name = region('FontString')}
    main.Name.privateContent = true
    if name == 'PlayerFrame' then
        frame.PlayerFrameContainer = {FrameTexture = region('Texture')}
        frame.PlayerFrameContainer.FrameTexture:SetSize(232, 100)
        main.ManaBarArea = {ManaBar = main.ManaBar}
        main.ManaBar = nil
        frame.PlayerFrameContent = {PlayerFrameContentMain = main}
    elseif name == 'TargetFrame' or name == 'FocusFrame' then
        frame.TargetFrameContainer = {FrameTexture = region('Texture')}
        frame.TargetFrameContent = {TargetFrameContentMain = main}
        frame.TargetFrameContainer.FrameTexture:SetSize(232, 100)
        function frame:CheckClassification()
            self.nativeClassifications = (self.nativeClassifications or 0) + 1
            self.TargetFrameContainer.FrameTexture:SetAtlas('native-updated-classification')
            self.TargetFrameContainer.FrameTexture:SetSize(238, 105)
            self.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar.fill:SetAtlas('native-updated-health')
        end
        frame.spellbar = statusbar()
    else
        frame.healthbar, frame.manabar, frame.name = main.HealthBarsContainer.HealthBar, main.ManaBar, main.Name
        frame.FrameTexture = region('Texture')
    end
    frame.gameplay = true
    frame.scripts.OnClick = function() return 'native-target' end
end
function PlayerFrame_UpdateArt()
    PlayerFrame.nativeArtUpdates = (PlayerFrame.nativeArtUpdates or 0) + 1
    PlayerFrame.PlayerFrameContainer.FrameTexture:SetAtlas('native-updated-player')
    PlayerFrame.PlayerFrameContainer.FrameTexture:SetSize(240, 110)
end
PlayerCastingBarFrame = statusbar('PlayerCastingBarFrame')
PlayerCastingBarFrame.Border = region('Texture')
MinimapCompassTexture = region('Texture')
MinimapCompassTextureUnderlay = region('Texture')
MirrorTimerContainer = newFrame('Frame', 'MirrorTimerContainer')
MirrorTimerContainer.mirrorTimers = {{StatusBar = statusbar(), Text = region('FontString')}}
MirrorTimerContainer.gameplay = true

for _, name in ipairs({'BuffFrame', 'DebuffFrame'}) do
    local frame = newFrame('Frame', name)
    local aura = newFrame('Button')
    aura.Icon = region('Texture'); aura.Icon.privateContent = true
    aura.Duration = region('FontString'); aura.Duration.privateContent = true
    aura.Count = region('FontString'); aura.Count.privateContent = true
    aura.nativeCancelBuff = true
    aura.gameplay = true
    local privateAnchor = {isAuraAnchor = true, CreateTexture = function() error('Touched private aura') end}
    frame.auraFrames = {aura, privateAnchor}
    frame.events.UNIT_AURA = true
    frame.UpdateAuraButtons = function(self) self.nativeUpdates = (self.nativeUpdates or 0) + 1 end
    frame.gameplay = true
end
GameTooltip = newFrame('GameTooltip', 'GameTooltip')
GameTooltip.scale = 0.9

GameMenuFrame = newFrame('Frame', 'GameMenuFrame')
GameMenuFrame.buttonPool = {active = {}}
function GameMenuFrame.buttonPool:EnumerateActive()
    local index = 0
    return function() index = index + 1; return self.active[index] end
end
function GameMenuFrame:AddButton(label, callback)
    local button = newFrame('Button')
    button.text, button.callback = label, callback
    button.layoutIndex = self.nextLayoutIndex
    self.nextLayoutIndex = self.nextLayoutIndex + 1
    self.buttonPool.active[#self.buttonPool.active + 1] = button
    self.buttons[#self.buttons + 1] = button
    return button
end
function GameMenuFrame:InitButtons()
    self.buttons, self.buttonPool.active, self.nextLayoutIndex = {}, {}, 1
    self:AddButton('Options', function() return 'native-options' end)
    self:AddButton('Edit Mode', function() ShowUIPanel(EditModeManagerFrame); return 'native-edit' end)
    self:AddButton('Logout', function() return 'native-logout' end)
    if not TEST_GAMEPAD then
        self.closeButton = self:AddButton('Return to Game', function() return 'native-close' end)
    else
        self.closeButton = nil
    end
end
function GameMenuFrame:SetupGamepadButtons() self.gamepadUpdates = (self.gamepadUpdates or 0) + 1 end

UnitHealth = function() error('Read secret health') end
UnitPower = function() error('Read secret power') end
UnitAura = function() error('Read secret aura') end
UnitCastingInfo = function() error('Read secret casting data') end

function dispatch(event, ...)
    local listeners = {}
    for _, frame in ipairs(frames) do
        if frame.events[event] then listeners[#listeners + 1] = frame end
    end
    for _, frame in ipairs(listeners) do
        if frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, ...) end
    end
end
