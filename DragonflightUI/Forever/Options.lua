local _, ns = ...
local DF = ns.DF
local german = GetLocale() == 'deDE'
local function T(en, de) return german and de or en end

local function Text(parent, text, x, y, width, template)
    local label = parent:CreateFontString(nil, 'OVERLAY', template or 'GameFontHighlight')
    label:SetPoint('TOPLEFT', x, y)
    label:SetWidth(width)
    label:SetJustifyH('LEFT')
    label:SetText(text)
    return label
end

local function Button(parent, text, width, callback)
    local button = CreateFrame('Button', nil, parent, 'BackdropTemplate')
    button:SetSize(width, 30)
    button:SetBackdrop({bgFile = 'Interface\\Buttons\\WHITE8X8', edgeFile = 'Interface\\Buttons\\WHITE8X8', edgeSize = 1})
    button:SetBackdropColor(0.10, 0.09, 0.14, 1)
    button:SetBackdropBorderColor(0.32, 0.25, 0.45, 1)
    button.Label = button:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    button.Label:SetPoint('CENTER')
    button.Label:SetText(text)
    button:SetScript('OnClick', callback)
    button:SetScript('OnEnter', function(self) self:SetBackdropColor(0.20, 0.14, 0.29, 1) end)
    button:SetScript('OnLeave', function(self) self:SetBackdropColor(0.10, 0.09, 0.14, 1) end)
    return button
end

local pages = {
    {title = T('General', 'Allgemein'), description = T(
        'Open Luna HUD Edit Mode from Esc > Edit Mode, /editmode or the button below. Select and move a highlighted element, then save your layout.',
        'Öffne Lunas HUD-Bearbeitungsmodus über Esc > Edit Mode, /editmode oder den Knopf unten. Wähle einen markierten Bereich, verschiebe ihn und speichere dein Layout.'), controls = {
        {'enabled', T('Enable Luna appearance', 'Luna-Gestaltung aktivieren')},
        {'lunaEditMode', T('Luna HUD Edit Mode', 'Luna-HUD-Bearbeitungsmodus')},
        {'frameTint', T('Silver-violet frame accents', 'Silber-violette Rahmenakzente')},
        {'minimap', T('Style the native minimap border', 'Native Minimap-Umrandung gestalten')},
    }},
    {title = T('Action bars', 'Aktionsleisten'), description = T(
        'Native action buttons keep their paging, shortcuts and combat behavior. Luna changes only their artwork and text.',
        'Die nativen Aktionsknöpfe behalten Seitenwechsel, Tastenbelegungen und Kampfverhalten. Luna ändert ihre Gestaltung und Beschriftung.'), controls = {
        {'actionbars', T('Style action bars and native flyouts', 'Aktionsleisten und native Zaubermenüs gestalten')},
        {'actionbarBorders', T('Luna button borders', 'Luna-Knopfumrandungen')},
        {'hideBarArt', T('Hide decorative bar art and gryphons', 'Leistendekoration und Greifen ausblenden')},
        {'hotkeys', T('Show keybindings', 'Tastenbelegungen anzeigen')},
        {'macroNames', T('Show macro names', 'Makronamen anzeigen')},
        {'hotkeySize', T('Keybinding font size', 'Schriftgröße der Tastenbelegung'), 8, 20, 1},
        {'macroSize', T('Macro font size', 'Schriftgröße der Makronamen'), 8, 18, 1},
    }},
    {title = T('Unit frames', 'Einheitenrahmen'), description = T(
        'Health, power, portraits, private auras and group targeting are handled by Blizzard. Party and raid layouts remain available in native Edit Mode.',
        'Gesundheit, Ressourcen, Porträts, private Auren und Gruppenauswahl verarbeitet Blizzard. Gruppen- und Schlachtzugslayouts stehen im nativen Bearbeitungsmodus bereit.'), controls = {
        {'unitframes', T('Style player, target, focus and pet frames', 'Spieler-, Ziel-, Fokus- und Begleiterrahmen gestalten')},
        {'unitArt', T('Dragonflight frame artwork', 'Dragonflight-Rahmengestaltung')},
        {'unitTextures', T('Luna health-bar textures', 'Luna-Texturen für Gesundheitsleisten')},
        {'unitFontScale', T('Unit-frame text size', 'Schriftgröße der Einheitenrahmen'), 0.75, 1.5, 0.05},
    }},
    {title = T('Buffs & cast bars', 'Buffs & Zauberleisten'), description = T(
        'The native aura and casting systems stay active, including buff cancellation, dispel colors, crafting, breathing and interrupted casts.',
        'Die nativen Aura- und Zaubersysteme bleiben aktiv, einschließlich Buff-Abbruch, Bannfarben, Handwerk, Atem und unterbrochener Zauber.'), controls = {
        {'auras', T('Style native buffs and debuffs', 'Native Buffs und Debuffs gestalten')},
        {'auraBorders', T('Luna aura borders', 'Luna-Aurenumrandungen')},
        {'auraFontSize', T('Aura text size', 'Schriftgröße der Auren'), 8, 18, 1},
        {'castbars', T('Style casting and mirror-timer bars', 'Zauber- und Atemleisten gestalten')},
        {'castbarFontSize', T('Cast-bar text size', 'Schriftgröße der Zauberleisten'), 8, 18, 1},
    }},
    {title = T('Tooltip', 'Tooltip'), description = T(
        'Blizzard supplies tooltip content and health values. Other tooltip addons can be used by turning this section off.',
        'Blizzard liefert Tooltip-Inhalte und Gesundheitswerte. Für andere Tooltip-AddOns kannst du diesen Bereich ausschalten.'), controls = {
        {'tooltip', T('Adjust native tooltip scale', 'Skalierung des nativen Tooltips anpassen')},
        {'tooltipScale', T('Tooltip scale', 'Tooltip-Skalierung'), 0.75, 1.5, 0.05},
    }},
}

function DF:CreateOptions()
    if self.options then return self.options end
    local frame = CreateFrame('Frame', 'DragonflightUIForeverOptions', UIParent, 'BackdropTemplate')
    self.options = frame
    frame:SetSize(740, 620)
    frame:SetPoint('CENTER')
    frame:SetScale(math.min(1, math.max(0.5, (UIParent:GetHeight() - 40) / 620)))
    frame:SetFrameStrata('DIALOG')
    frame:SetFrameLevel(300)
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart', frame.StartMoving)
    frame:SetScript('OnDragStop', function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        DragonflightUIDB.foreverWindow = {point, relativePoint, x, y}
    end)
    local position = DragonflightUIDB.foreverWindow
    if type(position) == 'table' and type(position[1]) == 'string' and type(position[2]) == 'string'
        and type(position[3]) == 'number' and type(position[4]) == 'number' then
        frame:ClearAllPoints()
        frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
    end
    frame:SetBackdrop({bgFile = 'Interface\\Buttons\\WHITE8X8', edgeFile = 'Interface\\Buttons\\WHITE8X8', edgeSize = 1})
    frame:SetBackdropColor(0.035, 0.03, 0.055, 0.98)
    frame:SetBackdropBorderColor(0.42, 0.32, 0.60, 1)
    local logo = frame:CreateTexture(nil, 'ARTWORK')
    logo:SetTexture('Interface\\AddOns\\DragonflightUI\\Textures\\Art\\luna-logo.tga')
    logo:SetSize(58, 58)
    logo:SetPoint('TOPLEFT', 20, -15)
    Text(frame, 'Dragonflight UI Luna', 90, -25, 560, 'GameFontNormalLarge')
    Text(frame, 'WoW Forever  |  ' .. self.version, 90, -51, 540, 'GameFontHighlightSmall')
    local close = Button(frame, '×', 30, function() frame:Hide() end)
    close:SetPoint('TOPRIGHT', -12, -12)
    local edit = Button(frame, T('Edit Mode', 'Bearbeitungsmodus'), 150, function() DF:OpenLunaEditMode() end)
    edit:SetPoint('BOTTOMLEFT', 16, 18)
    local reset = Button(frame, T('Defaults', 'Standardwerte'), 110, function()
        DragonflightUIDB.forever = DF:CopyDefaults({})
        DF.settings = DragonflightUIDB.forever
        for _, refresh in ipairs(frame.refreshers) do refresh() end
        DF:QueueRefresh()
    end)
    reset:SetPoint('BOTTOMRIGHT', -18, 18)
    Text(frame, T('Layout and visibility: Esc > Edit Mode.', 'Layout und Sichtbarkeit: Esc > Edit Mode.'),
        184, -578, 405, 'GameFontHighlightSmall')

    frame.refreshers = {}
    frame.pages = {}
    for index, data in ipairs(pages) do
        local page = CreateFrame('Frame', nil, frame)
        page:SetPoint('TOPLEFT', 184, -98)
        page:SetPoint('BOTTOMRIGHT', -22, 70)
        frame.pages[index] = page
        Text(page, data.title, 0, 0, 510, 'GameFontNormalLarge')
        local description = Text(page, data.description, 0, -35, 510, 'GameFontHighlightSmall')
        description:SetWordWrap(true)
        description:SetHeight(68)
        local y = -113
        for _, control in ipairs(data.controls) do
            local key, label = control[1], control[2]
            if not control[3] then
                local check = CreateFrame('CheckButton', nil, page)
                check:SetSize(510, 27)
                check:SetPoint('TOPLEFT', 0, y)
                check:SetNormalTexture('Interface\\Buttons\\UI-CheckBox-Up')
                check:SetPushedTexture('Interface\\Buttons\\UI-CheckBox-Down')
                check:SetCheckedTexture('Interface\\Buttons\\UI-CheckBox-Check')
                for _, texture in ipairs({check:GetNormalTexture(), check:GetPushedTexture(), check:GetCheckedTexture()}) do
                    texture:ClearAllPoints()
                    texture:SetSize(24, 24)
                    texture:SetPoint('LEFT', 0, 0)
                end
                Text(check, label, 30, -6, 475)
                check:SetScript('OnClick', function(self)
                    DF.settings[key] = self:GetChecked() == true
                    DF:QueueRefresh()
                end)
                local function refresh() check:SetChecked(DF.settings[key]) end
                frame.refreshers[#frame.refreshers + 1] = refresh
                y = y - 35
            else
                local low, high, step = control[3], control[4], control[5]
                local slider = CreateFrame('Slider', nil, page)
                slider:SetSize(460, 17)
                slider:SetPoint('TOPLEFT', 3, y - 26)
                slider:SetOrientation('HORIZONTAL')
                slider:SetMinMaxValues(low, high)
                slider:SetValueStep(step)
                slider:SetObeyStepOnDrag(true)
                local track = slider:CreateTexture(nil, 'BACKGROUND')
                track:SetColorTexture(0.22, 0.18, 0.30, 1)
                track:SetPoint('LEFT')
                track:SetPoint('RIGHT')
                track:SetHeight(4)
                slider:SetThumbTexture('Interface\\Buttons\\UI-SliderBar-Button-Horizontal')
                local thumb = slider:GetThumbTexture()
                thumb:SetSize(24, 24)
                Text(page, label, 0, y, 430)
                local valueText = Text(page, '', 455, y, 52, 'GameFontNormal')
                slider:SetScript('OnValueChanged', function(self, value)
                    local rounded = math.floor(value / step + 0.5) * step
                    valueText:SetText(step < 1 and string.format('%.2f', rounded) or tostring(math.floor(rounded)))
                    if not self.refreshing then
                        DF.settings[key] = rounded
                        DF:QueueRefresh()
                    end
                end)
                local function refresh()
                    slider.refreshing = true
                    slider:SetValue(DF.settings[key])
                    valueText:SetText(step < 1 and string.format('%.2f', DF.settings[key]) or tostring(DF.settings[key]))
                    slider.refreshing = false
                end
                frame.refreshers[#frame.refreshers + 1] = refresh
                y = y - 68
            end
        end
        page:Hide()
        local tab = Button(frame, data.title, 152, function()
            for _, other in ipairs(frame.pages) do other:Hide() end
            page:Show()
        end)
        tab:SetPoint('TOPLEFT', 16, -98 - (index - 1) * 40)
    end
    frame:SetScript('OnShow', function()
        for _, refresh in ipairs(frame.refreshers) do refresh() end
    end)
    frame.pages[1]:Show()
    table.insert(UISpecialFrames, 'DragonflightUIForeverOptions')
    frame:Hide()
    return frame
end

function DF:ToggleOptions()
    local options = self:CreateOptions()
    options:SetShown(not options:IsShown())
end

function DF:InstallSettingsCategory()
    if not Settings or not Settings.RegisterCanvasLayoutCategory or self.settingsCategory then return end
    local panel = CreateFrame('Frame')
    panel:Hide()
    Text(panel, 'Dragonflight UI Luna', 16, -20, 570, 'GameFontNormalLarge')
    Text(panel, T('Luna appearance for the native WoW Forever interface.', 'Luna-Gestaltung für die native WoW-Forever-Oberfläche.'),
        16, -56, 570)
    local options = Button(panel, T('Open Luna settings', 'Luna-Einstellungen öffnen'), 220, function() DF:ToggleOptions() end)
    options:SetPoint('TOPLEFT', 16, -100)
    local edit = Button(panel, T('Luna HUD Edit Mode', 'Luna-HUD-Bearbeitungsmodus'), 220, function() DF:OpenLunaEditMode() end)
    edit:SetPoint('TOPLEFT', 16, -142)
    local category = Settings.RegisterCanvasLayoutCategory(panel, 'Dragonflight UI Luna')
    Settings.RegisterAddOnCategory(category)
    self.settingsCategory = category
end

-- Classic Luna combines an HUD editor, grid, selectable systems and per-system
-- options. Forever already supplies the secure selection/layout controllers:
-- retain their callbacks and data, and host their controls in the Luna window.
local editControls = {
    'LayoutDropdown', 'ShowGridCheckButton', 'GridSpacingSlider',
    'EnableSnapCheckButton', 'EnableAdvancedOptionsCheckButton', 'AccountSettings',
    'SaveChangesButton', 'RevertAllChangesButton',
}

local function RememberControl(control)
    local saved = {parent = control:GetParent(), width = control:GetWidth(), height = control:GetHeight(), points = {}}
    for index = 1, control:GetNumPoints() do saved.points[index] = {control:GetPoint(index)} end
    return saved
end

local function RestoreControl(control, saved)
    control:SetParent(saved.parent)
    control:ClearAllPoints()
    control:SetSize(saved.width, saved.height)
    for _, point in ipairs(saved.points) do control:SetPoint(unpack(point)) end
end

function DF:CreateLunaEditMode()
    if self.editModeFrame then return self.editModeFrame end
    local frame = CreateFrame('Frame', 'DragonflightUIEditModeFrame', UIParent, 'BackdropTemplate')
    self.editModeFrame = frame
    frame:SetSize(510, 300)
    frame:SetPoint('TOP', 0, -100)
    frame:SetFrameStrata('DIALOG')
    frame:SetFrameLevel(190)
    frame:SetClampedToScreen(true)
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart', frame.StartMoving)
    frame:SetScript('OnDragStop', frame.StopMovingOrSizing)
    frame:SetBackdrop({bgFile = 'Interface\\Buttons\\WHITE8X8', edgeFile = 'Interface\\Buttons\\WHITE8X8', edgeSize = 1})
    frame:SetBackdropColor(0.035, 0.03, 0.055, 0.97)
    frame:SetBackdropBorderColor(0.42, 0.32, 0.60, 1)
    local logo = frame:CreateTexture(nil, 'ARTWORK')
    logo:SetTexture('Interface\\AddOns\\DragonflightUI\\Textures\\Art\\luna-logo.tga')
    logo:SetSize(36, 36)
    logo:SetPoint('TOPLEFT', 16, -12)
    Text(frame, 'HUD Edit Mode', 64, -14, 385, 'GameFontNormalLarge')
    Text(frame, 'Dragonflight UI Luna', 64, -36, 385, 'GameFontHighlightSmall')
    Text(frame, T('Layout', 'Layout'), 25, -56, 200, 'GameFontNormalSmall')
    local close = Button(frame, '×', 26, function()
        if EditModeManagerFrame then EditModeManagerFrame.onCloseCallback() end
    end)
    close:SetPoint('TOPRIGHT', -8, -8)
    local appearance = Button(frame, T('Luna settings', 'Luna-Einstellungen'), 180, function() DF:ShowSelectedAppearance() end)
    appearance:SetPoint('TOPRIGHT', -25, -69)
    frame:SetScript('OnHide', function()
        if DF.editModeSession and not DF.restoringEditMode and EditModeManagerFrame:IsShown() then
            EditModeManagerFrame.onCloseCallback()
        end
    end)
    frame:Hide()

    -- Match Luna's Classic dimmer. It has no mouse handling.
    local dimmer = CreateFrame('Frame', 'DragonflightUIEditModeDimmer', UIParent)
    dimmer:SetAllPoints(UIParent)
    dimmer:SetFrameStrata('LOW')
    dimmer:SetFrameLevel(0)
    dimmer:EnableMouse(false)
    local shade = dimmer:CreateTexture(nil, 'BACKGROUND')
    shade:SetAllPoints(dimmer)
    shade:SetColorTexture(0, 0, 0, 0.34)
    dimmer:Hide()
    self.editModeDimmer = dimmer
    return frame
end

function DF:LayoutLunaEditMode()
    if not self.editModeSession or self.restoringEditMode or InCombatLockdown() then return end
    local manager, frame = EditModeManagerFrame, self.editModeFrame
    local function Place(control, point, relativePoint, x, y)
        control:ClearAllPoints()
        control:SetPoint(point, frame, relativePoint, x, y)
    end
    Place(manager.LayoutDropdown, 'TOPLEFT', 'TOPLEFT', 25, -76)
    Place(manager.ShowGridCheckButton, 'TOPLEFT', 'TOPLEFT', 20, -116)
    Place(manager.GridSpacingSlider, 'TOPLEFT', 'TOPLEFT', 165, -116)
    Place(manager.EnableSnapCheckButton, 'TOPLEFT', 'TOPLEFT', 20, -151)
    Place(manager.EnableAdvancedOptionsCheckButton, 'TOPLEFT', 'TOPLEFT', 260, -151)
    Place(manager.AccountSettings, 'TOP', 'TOP', 0, -190)
    Place(manager.RevertAllChangesButton, 'BOTTOMLEFT', 'BOTTOMLEFT', 25, 18)
    Place(manager.SaveChangesButton, 'BOTTOMRIGHT', 'BOTTOMRIGHT', -25, 18)
    frame:SetHeight(254 + manager.AccountSettings:GetHeight())
end

function DF:BeginLunaEditMode()
    local manager = EditModeManagerFrame
    if not self.active or not self.settings.lunaEditMode or self.editModeSession or InCombatLockdown()
        or not manager or not manager:IsShown() then return end
    -- If a future build changes its chrome, leave its editor intact.
    for _, name in ipairs(editControls) do if not manager[name] then return end end
    local frame = self:CreateLunaEditMode()
    local session = {controls = {}, chrome = {}, mouse = manager:IsMouseEnabled()}
    self.editModeSession = session
    for _, name in ipairs(editControls) do
        local control = manager[name]
        session.controls[control] = RememberControl(control)
        control:SetParent(frame)
    end
    for _, name in ipairs({'Title', 'LayoutLabel', 'Border', 'Tutorial', 'CloseButton'}) do
        local region = manager[name]
        if region then
            local saved = {alpha = region:GetAlpha()}
            if region.IsMouseEnabled then
                saved.mouse = region:IsMouseEnabled()
                region:EnableMouse(false)
            end
            session.chrome[region] = saved
            region:SetAlpha(0)
        end
    end
    -- The invisible original window must not intercept clicks.
    manager:EnableMouse(false)
    self:LayoutLunaEditMode()
    self.editModeDimmer:Show()
    frame:Show()
end

function DF:EndLunaEditMode()
    local session = self.editModeSession
    if not session or self.restoringEditMode then return end
    self.restoringEditMode = true
    for control, saved in pairs(session.controls) do RestoreControl(control, saved) end
    for region, saved in pairs(session.chrome) do
        region:SetAlpha(saved.alpha)
        if saved.mouse ~= nil then region:EnableMouse(saved.mouse) end
    end
    if EditModeManagerFrame then EditModeManagerFrame:EnableMouse(session.mouse) end
    self.editModeSession = nil
    self.editModeFrame:Hide()
    self.editModeDimmer:Hide()
    self.restoringEditMode = false
end

function DF:RefreshLunaEditMode()
    local manager = EditModeManagerFrame
    if self.active and self.settings.lunaEditMode and manager and manager:IsShown()
        and manager.IsEditModeActive and manager:IsEditModeActive() and not InCombatLockdown() then
        self:BeginLunaEditMode()
    else
        self:EndLunaEditMode()
    end
end

function DF:ShowSelectedAppearance()
    local frame = self.editSelectedSystem
    local name = frame and frame.GetName and frame:GetName() or ''
    local pageIndex = 1
    if frame and frame.actionButtons then
        pageIndex = 2
    elseif name:find('PlayerFrame', 1, true) or name:find('TargetFrame', 1, true)
        or name:find('FocusFrame', 1, true) or name == 'PetFrame' then
        pageIndex = 3
    elseif name == 'BuffFrame' or name == 'DebuffFrame' or name:find('CastingBar', 1, true)
        or name == 'MirrorTimerContainer' then
        pageIndex = 4
    elseif name == 'GameTooltip' or name == 'HudTooltip' then
        pageIndex = 5
    end
    local options = self:CreateOptions()
    for index, page in ipairs(options.pages) do page:SetShown(index == pageIndex) end
    options:Show()
end

function DF:InstallLunaEditMode()
    local manager = EditModeManagerFrame
    if not manager or not manager.EnterEditMode or self.editModeHooked then return end
    self.editModeHooked = true
    -- The normal Esc > Edit Mode callback still opens the native controller.
    -- Its enter event displays the Luna editor regardless of the entry point.
    EventRegistry:RegisterCallback('EditMode.Enter', self.BeginLunaEditMode, self)
    EventRegistry:RegisterCallback('EditMode.Exit', self.EndLunaEditMode, self)
    -- Native layout import/new-layout dialogs temporarily hide and lock the
    -- manager without leaving Edit Mode. Mirror that visibility as Classic
    -- Luna does, so no detached editor remains above a native modal dialog.
    manager:HookScript('OnShow', function() self:BeginLunaEditMode() end)
    manager:HookScript('OnHide', function() self:EndLunaEditMode() end)
    if manager.AccountSettings then
        -- VerticalLayoutFrame finishes its expanded/collapsed height later in
        -- the frame; the manager's Layout callback can still see the old size.
        manager.AccountSettings:HookScript('OnSizeChanged', function() self:LayoutLunaEditMode() end)
    end
    hooksecurefunc(manager, 'Layout', function() self:LayoutLunaEditMode() end)
    if manager.SelectSystem then
        hooksecurefunc(manager, 'SelectSystem', function(_, systemFrame) self.editSelectedSystem = systemFrame end)
    end
    self:RefreshLunaEditMode()
end
