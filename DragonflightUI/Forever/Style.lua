local _, ns = ...
local DF = ns.DF
local textureBase = 'Interface\\AddOns\\DragonflightUI\\Textures\\'
local fontBases, alphaBases, textureBases, colorBases = {}, {}, {}, {}
local unitArtData = {
    Player = {'ui-hud-unitframe-player-portraiton-2x', 198, 71, 396 / 512, 142 / 256},
    Target = {'ui-hud-unitframe-target-portraiton-2x', 192, 67, 384 / 512, 134 / 256},
    TargetofTarget = {'ui-hud-unitframe-targetoftarget-portraiton-2x', 120, 49, 240 / 256, 98 / 128},
}

local function Allowed(object)
    return object and (type(object) == 'table' or type(object) == 'userdata') and
        not (object.IsForbidden and object:IsForbidden())
end

local function Alpha(object, value, apply)
    if not Allowed(object) then return end
    if alphaBases[object] == nil then
        local original = object:GetAlpha()
        -- Never branch on a concealed UI value.
        if DF.IsSecretValue(original) then return end
        alphaBases[object] = original
    end
    object:SetAlpha(apply and value or alphaBases[object])
end

local function Font(object, size, apply, relative)
    if not Allowed(object) or not object.GetFont then return end
    local base = fontBases[object]
    if not base then
        local file, height, flags = object:GetFont()
        if DF.IsSecretValue(height) then return end
        base = {file or STANDARD_TEXT_FONT, height or 12, flags or ''}
        fontBases[object] = base
    end
    local height = apply and (relative and base[2] * size or size) or base[2]
    object:SetFont(base[1], height, base[3])
end

local function Tint(object, apply)
    if not Allowed(object) or not object.GetVertexColor then return end
    local base = colorBases[object]
    if not base then
        local r, g, b, a = object:GetVertexColor()
        if DF.IsSecretValue(r) or DF.IsSecretValue(g) or DF.IsSecretValue(b) or DF.IsSecretValue(a) then return end
        base = {r, g, b, a, object.IsDesaturated and object:IsDesaturated() or false}
        colorBases[object] = base
    end
    if apply then
        object:SetDesaturated(true)
        object:SetVertexColor(0.78, 0.74, 0.88, base[4])
    else
        object:SetDesaturated(base[5])
        object:SetVertexColor(base[1], base[2], base[3], base[4])
    end
end

local function Texture(texture, path, apply, coords)
    if not Allowed(texture) then return end
    local base = textureBases[texture]
    if not base then
        local original = texture:GetTexture()
        if DF.IsSecretValue(original) then return end
        base = {texture = original, atlas = texture:GetAtlas(), coords = {texture:GetTexCoord()}}
        textureBases[texture] = base
    end
    if apply then
        texture:SetTexture(path)
        texture:SetTexCoord(unpack(coords or {0, 1, 0, 1}))
    else
        if base.atlas and base.atlas ~= '' then
            texture:SetAtlas(base.atlas)
        else
            texture:SetTexture(base.texture)
        end
        texture:SetTexCoord(unpack(base.coords))
    end
end

local geometryBases = {}
local function Geometry(region, owner, width, height, point, x, y, enabled)
    if not Allowed(region) then return end
    if not geometryBases[region] then
        local base = {width=region:GetWidth(), height=region:GetHeight(), points={}}
        for index=1, region:GetNumPoints() do base.points[index] = {region:GetPoint(index)} end
        geometryBases[region] = base
    end
    region:ClearAllPoints()
    if enabled then
        region:SetSize(width, height)
        region:SetPoint(point, owner, point, x, y)
    else
        local base = geometryBases[region]
        region:SetSize(base.width, base.height)
        for _, anchor in ipairs(base.points) do region:SetPoint(unpack(anchor)) end
    end
end

local function ForgetNativeArt(texture)
    if texture then textureBases[texture], geometryBases[texture] = nil, nil end
end

local function Edge(owner, icon, enabled, inset)
    if not Allowed(owner) or not Allowed(icon) then return end
    local edge = owner.DFLunaForeverEdge
    if not edge and enabled then
        edge = owner:CreateTexture(nil, 'BORDER')
        edge:SetTexture(textureBase .. 'uiactionbar2x')
        edge:SetTexCoord(0.701171875, 0.880859375, 0.31689453125, 0.36083984375)
        edge:SetPoint('TOPLEFT', icon, 'TOPLEFT', -inset, inset)
        edge:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMRIGHT', inset, -inset)
        owner.DFLunaForeverEdge = edge
    end
    if edge then
        edge:SetShown(enabled)
        Tint(edge, DF.settings.frameTint)
    end
end

local function UnitParts(frame)
    if not frame then return end
    local main = frame.PlayerFrameContent and frame.PlayerFrameContent.PlayerFrameContentMain
        or frame.TargetFrameContent and frame.TargetFrameContent.TargetFrameContentMain
    local content = main and (main.HealthBarsContainer or main)
    local health = frame.healthbar or frame.HealthBar or content and content.HealthBar
    local power = frame.manabar or frame.ManaBar or main and
        (main.ManaBar or main.ManaBarArea and main.ManaBarArea.ManaBar)
    local name = frame.name or frame.Name or main and main.Name
    return health, power, name
end

function DF:StyleActionButton(button, enabled)
    if not Allowed(button) then return end
    local settings = self.settings
    local icon = button.icon or button.Icon
    local overlay = button.TextOverlayContainer
    local hotkey = button.HotKey or overlay and overlay.HotKey
    local macro = button.Name
    if not macro and button.GetName and button:GetName() then macro = _G[button:GetName() .. 'Name'] end
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    local pushed = button.GetPushedTexture and button:GetPushedTexture()
    local borders = enabled and settings.actionbarBorders
    Edge(button, icon, borders and not normal, 1)
    Texture(normal, textureBase .. 'uiactionbar2x', borders,
        {0.701171875, 0.880859375, 0.31689453125, 0.36083984375})
    Texture(pushed, textureBase .. 'uiactionbar2x', borders,
        {0.701171875, 0.880859375, 0.43017578125, 0.47412109375})
    Geometry(normal, button, 46, 45, 'TOPLEFT', 0, 0, borders)
    Geometry(pushed, button, 46, 45, 'TOPLEFT', 0, 0, borders)
    Geometry(icon, button, 45, 45, 'CENTER', 0, 0, borders)
    Texture(button.IconMask, textureBase .. 'maskNew', borders)
    if button.IconMask then Geometry(button.IconMask, button, 45, 45, 'CENTER', 0, 0, borders) end
    for _, pair in ipairs({
        {button.Border, {0.701171875,0.880859375,0.36181640625,0.40576171875}},
        {button.GetHighlightTexture and button:GetHighlightTexture(), {0.701171875,0.880859375,0.52001953125,0.56396484375}},
        {button.GetCheckedTexture and button:GetCheckedTexture(), {0.701171875,0.880859375,0.52001953125,0.56396484375}},
    }) do
        Texture(pair[1], textureBase .. 'uiactionbar2x', borders, pair[2])
        Geometry(pair[1], button, 46, 45, 'TOPLEFT', 0, 0, borders)
    end
    Alpha(button.SlotArt, 0, borders)
    Alpha(button.SlotBackground, 0, borders)
    Font(hotkey, settings.hotkeySize, enabled)
    Font(macro, settings.macroSize, enabled)
    Alpha(hotkey, 0, enabled and not settings.hotkeys)
    Alpha(macro, 0, enabled and not settings.macroNames)
    if not button.DFLunaArtHooked and type(button.UpdateButtonArt) == 'function' then
        button.DFLunaArtHooked = true
        hooksecurefunc(button, 'UpdateButtonArt', function()
            -- Blizzard may choose a different atlas when the bar art changes.
            -- Record that native choice before applying Luna's artwork.
            ForgetNativeArt(button:GetNormalTexture())
            ForgetNativeArt(button.GetPushedTexture and button:GetPushedTexture())
            self:StyleActionButton(button, self.active and self.settings.enabled and self.settings.actionbars)
        end)
    end
end

function DF:StyleActionBars(enabled)
    for _, name in ipairs({
        'MainActionBar', 'MultiBarBottomLeft', 'MultiBarBottomRight', 'MultiBarLeft',
        'MultiBarRight', 'MultiBar5', 'MultiBar6', 'MultiBar7', 'PetActionBar',
        'StanceBar', 'PossessActionBar'
    }) do
        local bar = _G[name]
        if Allowed(bar) then
            for _, button in ipairs(bar.actionButtons or {}) do self:StyleActionButton(button, enabled) end
        end
    end
    local bar = MainActionBar
    if Allowed(bar) then
        Alpha(bar.BorderArt, 0, enabled and self.settings.hideBarArt)
        local caps = bar.EndCaps
        if caps then
            Alpha(caps.LeftEndCap and caps.LeftEndCap.Texture, 0, enabled and self.settings.hideBarArt)
            Alpha(caps.RightEndCap and caps.RightEndCap.Texture, 0, enabled and self.settings.hideBarArt)
        end
        for _, key in ipairs({'HorizontalDividersPool', 'VerticalDividersPool'}) do
            local pool = bar[key]
            if pool then
                for divider in pool:EnumerateActive() do
                    for _, region in ipairs({divider:GetRegions()}) do
                        Alpha(region, 0, enabled and self.settings.hideBarArt)
                    end
                end
            end
        end
        if not self.dividersHooked and type(bar.UpdateDividers) == 'function' then
            self.dividersHooked = true
            hooksecurefunc(bar, 'UpdateDividers', function() self:QueueRefresh() end)
        end
    end
    -- Native spell flyouts retain their secure spell/action setup.
    if Allowed(SpellFlyout) then
        for _, button in ipairs({SpellFlyout:GetChildren()}) do
            if button.GetObjectType and button:GetObjectType() == 'CheckButton' then
                self:StyleActionButton(button, enabled)
            end
        end
        -- The native pool creates flyout buttons lazily on first use.
        if not self.flyoutHooked and type(SpellFlyout.Toggle) == 'function' then
            self.flyoutHooked = true
            hooksecurefunc(SpellFlyout, 'Toggle', function() self:QueueRefresh() end)
        end
    end
end

function DF:StyleAuraFrame(frame, enabled)
    if not Allowed(frame) then return end
    for _, button in ipairs(frame.auraFrames or {}) do
        -- Private aura anchors are managed by the secure UI environment.
        if not button.isAuraAnchor and Allowed(button) then
            Edge(button, button.Icon, enabled and self.settings.auraBorders, 1)
            Font(button.Duration, self.settings.auraFontSize, enabled)
            Font(button.Count, self.settings.auraFontSize, enabled)
        end
    end
    if not frame.DFLunaForeverHooked and type(frame.UpdateAuraButtons) == 'function' then
        frame.DFLunaForeverHooked = true
        hooksecurefunc(frame, 'UpdateAuraButtons', function()
            if InCombatLockdown() then self.pendingRefresh = true; return end
            self:StyleAuraFrame(frame, self.active and self.settings.enabled and self.settings.auras)
        end)
    end
end

function DF:StyleCastBars(enabled)
    local bars = {
        PlayerCastingBarFrame or false,
        TargetFrame and TargetFrame.spellbar or TargetFrameSpellBar or false,
        FocusFrame and FocusFrame.spellbar or FocusFrameSpellBar or false,
    }
    for _, bar in ipairs(bars) do
        if Allowed(bar) then
            -- Native fill art and colors distinguish crafting, channels and
            -- interrupted casts. Do not replace them with a static fill.
            Font(bar.Text, self.settings.castbarFontSize, enabled)
            Tint(bar.Border, enabled and self.settings.frameTint)
        end
    end
    for _, timer in ipairs(MirrorTimerContainer and MirrorTimerContainer.mirrorTimers or {}) do
        Font(timer.Text, self.settings.castbarFontSize, enabled)
        Tint(timer.Border, enabled and self.settings.frameTint)
    end
end

function DF:StyleTooltip(enabled)
    if not Allowed(GameTooltip) then return end
    if not self.tooltipBaseScale then self.tooltipBaseScale = GameTooltip:GetScale() end
    GameTooltip:SetScale(self.tooltipBaseScale * (enabled and self.settings.tooltipScale or 1))
end

function DF:ApplyTheme()
    if InCombatLockdown() then self.pendingRefresh = true; return end
    self:ApplyClassicReferenceLayout()
    local enabled = self.active and self.settings.enabled
    self:StyleActionBars(enabled and self.settings.actionbars)
    self:StyleLunaMicroBags(enabled and self.settings.actionbars)
    self:StyleUnitFrames(enabled and self.settings.unitframes)
    self:StyleAuraFrame(BuffFrame, enabled and self.settings.auras)
    self:StyleAuraFrame(DebuffFrame, enabled and self.settings.auras)
    self:StyleCastBars(enabled and self.settings.castbars)
    self:StyleTooltip(enabled and self.settings.tooltip)
    self:StyleLunaWindows(enabled and self.settings.windows)
    self:StyleLunaMinimap(enabled and self.settings.minimap)
    self:RefreshLunaEditMode()
    for name, key in pairs({Actionbar = 'actionbars', Unitframe = 'unitframes', Buffs = 'auras', Castbar = 'castbars', Tooltip = 'tooltip', Minimap = 'minimap'}) do
        self.moduleStatus[name] = {enabled = enabled and self.settings[key] == true, setupCompleted = true, native = true}
    end
end

local function SetLayoutSetting(system, setting, value)
    if setting == nil then return end
    local displays = EditModeSettingDisplayInfoManager.displayInfoMap[system.system] or {}
    local display = displays[setting]
    local raw = display and display.ConvertValue and display:ConvertValue(value, false) or value
    for _, item in ipairs(system.settings or {}) do
        if item.setting == setting then item.value = raw; return end
    end
end

function DF:ApplyClassicReferenceLayout(force)
    local manager = EditModeManagerFrame
    if not self.active or not self.settings.enabled or self.applyingReference or InCombatLockdown() or not manager or not manager.layoutInfo or
        not manager.layoutInfo.layouts or not EditModeSettingDisplayInfoManager or manager:IsEditModeActive() then return end
    local key = UnitGUID and UnitGUID('player')
    if self.IsSecretValue(key) or not key then return end
    DragonflightUIDB.foreverLayouts = DragonflightUIDB.foreverLayouts or {}
    local saved = DragonflightUIDB.foreverLayouts
    if saved[key] and not force then return end
    local source = manager.layoutInfo.layouts[manager.layoutInfo.activeLayout]
    if not source then return end
    local layout = CopyTable(source)
    local actions, units = Enum.EditModeActionBarSetting, Enum.EditModeUnitFrameSetting
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    local frames = {
        {MainActionBar, 'BOTTOM', 'BOTTOM', 0, 8, actions, {NumRows=1,NumIcons=12,IconSize=100,IconPadding=2,HideBarArt=1,HideBarScrolling=1,AlwaysShowButtons=1}},
        {MultiBarBottomLeft, 'BOTTOM', 'BOTTOM', 0, 56, actions, {NumRows=1,NumIcons=12,IconSize=100,IconPadding=2,AlwaysShowButtons=1}},
        {MultiBarBottomRight, 'BOTTOM', 'BOTTOM', 0, 104, actions, {NumRows=1,NumIcons=12,IconSize=100,IconPadding=2,AlwaysShowButtons=1}},
        {MultiBarRight, 'BOTTOM', 'BOTTOM', -390, 8, actions, {NumRows=3,NumIcons=12,IconSize=100,IconPadding=2,AlwaysShowButtons=1}},
        {MultiBarLeft, 'BOTTOM', 'BOTTOM', 390, 8, actions, {NumRows=3,NumIcons=12,IconSize=100,IconPadding=2,AlwaysShowButtons=1}},
        {PlayerFrame, 'CENTER', 'CENTER', -width * 0.14, -height * 0.18, units, {FrameSize=125,HidePortrait=0}},
        {TargetFrame, 'CENTER', 'CENTER', width * 0.14, -height * 0.18, units, {FrameSize=125,HidePortrait=0}},
        {FocusFrame, 'CENTER', 'CENTER', width * 0.14, -height * 0.04, units, {FrameSize=100,HidePortrait=0}},
        {MinimapCluster, 'TOPRIGHT', 'TOPRIGHT', -4, -4, Enum.EditModeMinimapSetting, {Size=100,RotateMinimap=0,HeaderUnderneath=0}},
        {MicroMenuContainer, 'BOTTOMRIGHT', 'BOTTOMRIGHT', -4, 0, Enum.EditModeMicroMenuSetting, {Orientation=0,Size=100}},
        {BagsBar, 'BOTTOMRIGHT', 'BOTTOMRIGHT', -8, 43, Enum.EditModeBagsSetting, {Orientation=0,Size=100,BagSlotPadding=2}},
        {StatusTrackingBarManager and StatusTrackingBarManager.MainStatusTrackingBarContainer, 'BOTTOM', 'BOTTOM', 0, 156,
            Enum.EditModeStatusTrackingBarSetting, {Size=50}},
        {StatusTrackingBarManager and StatusTrackingBarManager.SecondaryStatusTrackingBarContainer, 'BOTTOM', 'BOTTOM', 0, 169,
            Enum.EditModeStatusTrackingBarSetting, {Size=50}},
    }
    for _, row in ipairs(frames) do
        local frame = row[1]
        if frame and frame.system then
            for _, system in ipairs(layout.systems) do
                if system.system == frame.system and system.systemIndex == frame.systemIndex then
                    system.isInDefaultPosition = false
                    system.anchorInfo = {point=row[2],relativeTo='UIParent',relativePoint=row[3],offsetX=row[4],offsetY=row[5]}
                    for setting, value in pairs(row[7]) do SetLayoutSetting(system, row[6][setting], value) end
                    if row[6] == actions then
                        SetLayoutSetting(system, actions.Orientation, Enum.ActionBarOrientation.Horizontal)
                        SetLayoutSetting(system, actions.VisibleSetting, Enum.ActionBarVisibleSetting.Always)
                    end
                end
            end
        end
    end
    local info = CopyTable(manager.layoutInfo)
    local index
    for candidate, existing in ipairs(info.layouts) do
        if existing.layoutName == 'Luna Classic' and existing.layoutType == Enum.EditModeLayoutType.Character then index = candidate end
    end
    if not index then
        local count = 0
        for _, existing in ipairs(info.layouts) do
            if existing.layoutType == Enum.EditModeLayoutType.Character then count = count + 1 end
        end
        local maximum = Constants and Constants.EditModeConsts and Constants.EditModeConsts.EditModeMaxLayoutsPerType or 5
        if count >= maximum then
            if not self.layoutLimitReported then self.layoutLimitReported = true; self:Print('No free character layout slot for Luna Classic.') end
            return
        end
        index = #info.layouts + 1
    end
    layout.layoutName, layout.layoutType = 'Luna Classic', Enum.EditModeLayoutType.Character
    info.layouts[index] = layout
    info.activeLayout = index
    self.applyingReference = true
    local ok, message = pcall(function()
        C_EditMode.SaveLayouts(info)
        C_EditMode.SetActiveLayout(index)
    end)
    self.applyingReference = false
    if not ok then error(message); return end
    saved[key] = {previousLayout = source.layoutName, version = 1}
    for number = 1, 4 do C_CVar.SetCVar('showMultiActionBar' .. number, '1') end
    self.settings.frameTint = false
end

local minimapSkin
function DF:StyleLunaMinimap(enabled)
    if not Minimap then return end
    if not minimapSkin then
        local border = Minimap:CreateTexture('DragonflightUILunaMinimapBorder', 'ARTWORK', nil, 7)
        border:SetTexture(textureBase .. 'uiminimap2x')
        border:SetTexCoord(0.001953125, 0.857421875, 0.056640625, 0.505859375)
        border:SetPoint('CENTER', Minimap, 'CENTER', 1, 0)
        minimapSkin = {border = border, mask = Minimap.GetMaskTexture and Minimap:GetMaskTexture() or
            'ui-hud-minimap-frame-generic-mask'}
    end
    local width = Minimap:GetWidth()
    minimapSkin.border:SetSize(width * 156 / 140, width * 162 / 140)
    minimapSkin.border:SetShown(enabled)
    Alpha(MinimapCompassTexture, 0, enabled)
    Alpha(MinimapCompassTextureUnderlay, 0, enabled)
    Alpha(MinimapNorthTag, 0, enabled)
    Minimap:SetMaskTexture(enabled and textureBase .. 'tempportraitalphamask' or minimapSkin.mask)
    local container = MinimapCluster and MinimapCluster.MinimapContainer
    local zoomIn = Minimap.ZoomIn or container and container.ZoomIn or MinimapZoomIn
    local zoomOut = Minimap.ZoomOut or container and container.ZoomOut or MinimapZoomOut
    for _, pair in ipairs({{zoomIn, {0.001953125, 0.068359375, 0.5390625, 0.572265625}},
        {zoomOut, {0.353515625, 0.419921875, 0.5, 0.533203125}}}) do
        local button, crop = pair[1], pair[2]
        if button then
            Texture(button:GetNormalTexture(), textureBase .. 'uiminimap2x', enabled, crop)
            Texture(button:GetPushedTexture(), textureBase .. 'uiminimap2x', enabled, crop)
            Texture(button:GetHighlightTexture(), textureBase .. 'uiminimap2x', enabled, crop)
            if minimapSkin[button] == nil then minimapSkin[button] = {shown=button:IsShown()} end
            if enabled then button:Show() else button:SetShown(minimapSkin[button].shown) end
        end
    end
    if not self.zoomSkinHooked and type(Minimap.OnLeave)=='function' then
        self.zoomSkinHooked=true
        hooksecurefunc(Minimap,'OnLeave',function()
            if self.active and self.settings.enabled and self.settings.minimap then
                if Minimap.ZoomIn then Minimap.ZoomIn:Show() end
                if Minimap.ZoomOut then Minimap.ZoomOut:Show() end
            end
        end)
    end
    local zone = MinimapCluster and MinimapCluster.ZoneTextButton
    if zone then
        Alpha(zone.StateTexture, 0, enabled)
        Alpha(zone.AddTexture, 0, enabled)
    end
    if GameTimeFrame and zone then
        if not minimapSkin.timePoints then
            minimapSkin.timePoints = {}
            for index = 1, GameTimeFrame:GetNumPoints() do
                minimapSkin.timePoints[index] = {GameTimeFrame:GetPoint(index)}
            end
            minimapSkin.timeSize = {GameTimeFrame:GetWidth(), GameTimeFrame:GetHeight()}
            local day = GameTimeFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
            day:SetPoint('CENTER')
            minimapSkin.day = day
        end
        Alpha(GameTimeFrame.GetNormalTexture and GameTimeFrame:GetNormalTexture(), 0, enabled)
        Alpha(GameTimeFrame.StateTexture, 0, enabled)
        Alpha(GameTimeFrame.AddTexture, 0, enabled)
        minimapSkin.day:SetShown(enabled)
        GameTimeFrame:ClearAllPoints()
        if enabled then
            GameTimeFrame:SetSize(18, 18)
            GameTimeFrame:SetPoint('RIGHT', zone, 'RIGHT', -2, 0)
            if C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime then
                minimapSkin.day:SetText(C_DateAndTime.GetCurrentCalendarTime().monthDay)
            end
        else
            GameTimeFrame:SetSize(unpack(minimapSkin.timeSize))
            for _, point in ipairs(minimapSkin.timePoints) do GameTimeFrame:SetPoint(unpack(point)) end
        end
    end
    if MinimapCluster and not self.minimapSkinHooked then
        self.minimapSkinHooked = true
        if type(MinimapCluster.UpdateMinimapConfig) == 'function' then
            hooksecurefunc(MinimapCluster, 'UpdateMinimapConfig', function() self:QueueRefresh() end)
        end
    end
end

-- Apply the same Luna metal frame to native panels, including load-on-demand
-- Forever panels. Only chrome is changed: content, panel layout and callbacks
-- remain native. Never walk arbitrary content textures (item/spell colors).
local windowSkins = {}
local panelNames = {
    'CharacterFrame', 'SpellBookFrame', 'PlayerSpellsFrame', 'ProfessionsFrame',
    'PlayerTalentFrame', 'ClassTalentFrame', 'LegacySystemFrame', 'HousingDashboardFrame',
    'CollectionsJournal', 'QuestLogFrame', 'WorldMapFrame', 'FriendsFrame',
    'CommunitiesFrame', 'GuildFrame', 'LFGParentFrame', 'PVEFrame', 'EncounterJournal',
    'GameMenuFrame', 'MerchantFrame', 'ClassTrainerFrame', 'GossipFrame', 'QuestFrame',
    'BankFrame', 'MailFrame', 'TradeFrame', 'AuctionHouseFrame', 'DressUpFrame',
    'ItemTextFrame', 'LootFrame', 'InspectFrame', 'ProfessionsBookFrame',
    'ContainerFrameCombinedBags',
}
local sliceArt = {
    TopLeftCorner = {'uiframemetal2x', {0.00195312,0.294922,0.00195312,0.294922},75,74,'TOPLEFT',-12,16},
    TopRightCorner = {'uiframemetal2x', {0.298828,0.591797,0.00195312,0.294922},75,74,'TOPRIGHT',4,16},
    BottomLeftCorner = {'uiframemetal2x', {0.298828,0.423828,0.298828,0.423828},32,32,'BOTTOMLEFT',-12,-3},
    BottomRightCorner = {'uiframemetal2x', {0.427734,0.552734,0.298828,0.423828},32,32,'BOTTOMRIGHT',4,-3},
    TopEdge = {'UIFrameMetalHorizontal2x',{0,1,0.00390625,0.589844}},
    BottomEdge = {'UIFrameMetalHorizontal2x',{0,0.5,0.597656,0.847656}},
    LeftEdge = {'UIFrameMetalVertical2x',{0.00195312,0.294922,0,1}},
    RightEdge = {'UIFrameMetalVertical2x',{0.298828,0.591797,0,1}},
}

function DF:StyleLunaWindow(frame, enabled)
    if not Allowed(frame) or InCombatLockdown() then return end
    local slice = frame.NineSlice or frame.BorderFrame and frame.BorderFrame.NineSlice
    if not slice then return end
    local owner = slice.GetParent and slice:GetParent() or frame
    local first = not windowSkins[frame]
    windowSkins[frame] = true
    if first then
        self.styledWindowCount = (self.styledWindowCount or 0) + 1
        frame:HookScript('OnShow', function()
            if InCombatLockdown() then self.pendingRefresh = true; return end
            self:StyleLunaWindow(frame, self.active and self.settings.enabled and self.settings.windows)
        end)
    end
    for key, data in pairs(sliceArt) do
        local piece = slice[key]
        Texture(piece, textureBase .. 'UI\\' .. data[1], enabled, data[2])
        if data[3] then
            Geometry(piece, owner, data[3], data[4], data[5], data[6], data[7], enabled)
        elseif piece then
            -- Cache the original edge points before stretching between Luna's
            -- corners. A zero-size intermediary is never shown to the player.
            Geometry(piece, owner, piece:GetWidth(), piece:GetHeight(), 'CENTER', 0, 0, enabled)
            if enabled then
                piece:ClearAllPoints()
                if key == 'TopEdge' or key == 'BottomEdge' then
                    local top = key == 'TopEdge'
                    local left = top and slice.TopLeftCorner or slice.BottomLeftCorner
                    local right = top and slice.TopRightCorner or slice.BottomRightCorner
                    if left and right then
                        piece:SetHeight(top and 74 or 32)
                        piece:SetPoint('TOPLEFT', left, 'TOPRIGHT', 0, 0)
                        piece:SetPoint('TOPRIGHT', right, 'TOPLEFT', 0, 0)
                    end
                else
                    local left = key == 'LeftEdge'
                    local top = left and slice.TopLeftCorner or slice.TopRightCorner
                    local bottom = left and slice.BottomLeftCorner or slice.BottomRightCorner
                    if top and bottom then
                        piece:SetWidth(75)
                        piece:SetPoint('TOPLEFT', top, 'BOTTOMLEFT', 0, 0)
                        piece:SetPoint('BOTTOMLEFT', bottom, 'TOPLEFT', 0, 0)
                    end
                end
            end
        end
    end
    local portraits = frame.PortraitContainer
    local portrait = portraits and portraits.portrait
    if portrait then
        if not frame.DFLunaPortraitBorder then
            local border = portraits:CreateTexture(nil,'OVERLAY',nil,7)
            border:SetTexture(textureBase .. 'UI\\UI-Frame-PortraitMetal-CornerTopLeft')
            border:SetTexCoord(0.0078125,0.6171875,0.0078125,0.6171875)
            border:SetSize(84,84)
            border:SetPoint('CENTER',portrait,'CENTER',0,0)
            border:SetDesaturated(true)
            border:SetVertexColor(0.5,0.55,0.62,1)
            frame.DFLunaPortraitBorder = border
            frame.DFLunaPortraitLevel = portraits:GetFrameLevel()
        end
        frame.DFLunaPortraitBorder:SetShown(enabled)
        -- Luna's plain metal title strip has no portrait cutout. Draw the
        -- native portrait above it instead of letting the strip cut it in half.
        portraits:SetFrameLevel(enabled and math.max(frame.DFLunaPortraitLevel,slice:GetFrameLevel()+1) or frame.DFLunaPortraitLevel)
    end
    local close = frame.CloseButton or frame.ClosePanelButton
    if close and close.GetNormalTexture then
        for _, pair in ipairs({
            {close:GetNormalTexture(),{0.152344,0.292969,0.0078125,0.304688}},
            {close.GetDisabledTexture and close:GetDisabledTexture(),{0.152344,0.292969,0.320312,0.617188}},
            {close:GetPushedTexture(),{0.152344,0.292969,0.632812,0.929688}},
            {close:GetHighlightTexture(),{0.449219,0.589844,0.0078125,0.304688}},
        }) do Texture(pair[1], textureBase .. 'UI\\redbutton2x', enabled, pair[2]) end
    end
end

function DF:StyleLunaWindows(enabled)
    for _, name in ipairs(panelNames) do self:StyleLunaWindow(_G[name], enabled) end
    for _, frame in ipairs(ContainerFrameContainer and ContainerFrameContainer.ContainerFrames or {}) do
        self:StyleLunaWindow(frame, enabled)
    end
    for name in pairs(UIPanelWindows or {}) do self:StyleLunaWindow(_G[name], enabled) end
    -- Include frames after they are removed from the native panel registry so
    -- disabling the skin still restores everything previously styled.
    for frame in pairs(windowSkins) do self:StyleLunaWindow(frame, enabled) end
    if not self.panelsHooked then
        self.panelsHooked = true
        hooksecurefunc('ShowUIPanel', function(frame)
            self:StyleLunaWindow(frame, self.active and self.settings.enabled and self.settings.windows)
        end)
    end
end

-- A complete visual layer is necessary on Camelot: its internal portrait,
-- health, mana, level and flash geometry is deliberately different from Luna.
-- Keep Blizzard's secure unit button and data controllers intact and render
-- their output through widgets that accept secret values. Never format,
-- compare, calculate or save health/power values in Lua.
local unitVisuals, suppressed = {}, {}
local unitTokens = {PlayerFrame = 'player', TargetFrame = 'target', FocusFrame = 'focus',
    PetFrame = 'pet', TargetFrameToT = 'targettarget', FocusFrameToT = 'focustarget'}

local function Suppress(region, enabled)
    if not Allowed(region) then return end
    local saved = suppressed[region]
    if not saved then saved = {alpha = region:GetAlpha()}; suppressed[region] = saved end
    if enabled then region:SetAlpha(0) else region:SetAlpha(saved.alpha) end
end

local function NewLabel(parent, size)
    local text = parent:CreateFontString(nil, 'OVERLAY')
    text:SetFont(STANDARD_TEXT_FONT, size, 'OUTLINE')
    text:SetShadowColor(0, 0, 0, 1)
    text:SetShadowOffset(1, -1)
    text:SetWordWrap(false)
    return text
end

local function NewBar(parent, width, height, kind, resource, maskFile, maskW, maskH, maskX, maskY)
    local bar = CreateFrame('StatusBar', nil, parent)
    bar:SetSize(width, height)
    bar:EnableMouse(false)
    local textureKind = kind == 'TargetofTarget' and 'Target' or kind
    bar:SetStatusBarTexture(textureBase .. 'Unitframe\\UI-HUD-UnitFrame-' .. textureKind .. '-PortraitOn-Bar-' .. resource)
    bar:SetStatusBarColor(1, 1, 1, 1)
    local mask = bar:CreateMaskTexture(nil, 'ARTWORK')
    mask:SetTexture(textureBase .. 'Unitframe2x\\' .. maskFile, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    mask:SetSize(maskW, maskH)
    mask:SetPoint('TOPLEFT', bar, 'TOPLEFT', maskX, maskY)
    bar:GetStatusBarTexture():AddMaskTexture(mask)
    bar.ValueText = NewLabel(bar, 12)
    bar.ValueText:SetPoint('CENTER', 0, resource == 'Health' and 0 or -0.75)
    return bar
end

local function CopyLabel(destination, source)
    if source and source.GetText then destination:SetText(source:GetText()) else destination:SetText('') end
end

local function CreateUnitVisual(name, root)
    local kind = name == 'PlayerFrame' and 'Player' or
        (name == 'TargetFrame' or name == 'FocusFrame') and 'Target' or 'TargetofTarget'
    local data = unitArtData[kind]
    local frame = CreateFrame('Frame', 'DragonflightUILuna' .. name, root)
    frame:SetSize(data[2], data[3])
    frame:SetPoint('CENTER', root, 'CENTER', 0, 0)
    frame:EnableMouse(false)
    frame:SetFrameLevel(root:GetFrameLevel() + 5)
    local hud = {frame = frame, root = root, kind = kind, unit = unitTokens[name], portraitDirty = true}
    unitVisuals[name] = hud
    frame.Art = frame:CreateTexture(nil, 'BORDER')
    frame.Art:SetTexture(textureBase .. 'Unitframe2x\\' .. data[1])
    frame.Art:SetTexCoord(0, data[4], 0, data[5])
    frame.Art:SetAllPoints(frame)
    frame.Art:SetDesaturated(true)
    frame.Art:SetVertexColor(0.42, 0.45, 0.50, 1)
    frame.Portrait = frame:CreateTexture(nil, 'BACKGROUND')
    local portraitMask = frame:CreateMaskTexture(nil, 'ARTWORK')
    portraitMask:SetAllPoints(frame.Portrait)
    portraitMask:SetTexture(textureBase .. (kind == 'Player' and 'uiunitframeplayerportraitmask' or 'tempportraitalphamask'),
        'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    frame.Portrait:AddMaskTexture(portraitMask)
    frame.Name = NewLabel(frame, 12)
    frame.Name:SetTextColor(1, 0.82, 0)
    frame.Level = NewLabel(frame, 12)
    frame.Level:SetTextColor(1, 0.82, 0)
    frame.Level:SetSize(24, 12)
    if kind == 'Player' then
        frame.Portrait:SetSize(57, 57)
        frame.Portrait:SetPoint('TOPLEFT', 8.5, -6.5)
        frame.Health = NewBar(frame, 124, 20, kind, 'Health', 'uiunitframeplayerhealthmask2x', 128, 32, -2, 6)
        frame.Health:SetPoint('TOPLEFT', 68, -26.05)
        frame.Power = NewBar(frame, 124, 10.5, kind, 'Mana', 'uiunitframeplayermanamask2x', 128, 16, -2, 2)
        frame.Power:SetPoint('TOPLEFT', 68, -46.3)
        frame.Name:SetPoint('BOTTOMLEFT', frame.Health, 'TOPLEFT', 0, 1)
        frame.Level:SetPoint('BOTTOMRIGHT', frame.Health, 'TOPRIGHT', -5, 1)
        frame.Level:SetJustifyH('RIGHT')
    elseif kind == 'Target' then
        frame.Portrait:SetSize(56, 56)
        frame.Portrait:SetPoint('CENTER', frame, 'CENTER', 61, 2)
        frame.Health = NewBar(frame, 126, 20, kind, 'Health', 'uiunitframetargethealthmask2x', 129, 32, -1, 6)
        frame.Health:SetPoint('CENTER', frame, 'CENTER', -30.5, 0)
        frame.Power = NewBar(frame, 134, 10, kind, 'Mana', 'uiunitframetargetmanamask2x', 259, 16, -62, 3)
        frame.Power:SetPoint('TOPLEFT', frame.Health, 'BOTTOMLEFT', 0, -1)
        frame.Name:SetPoint('BOTTOMRIGHT', frame.Health, 'TOPRIGHT', -2, 1)
        frame.Level:SetPoint('BOTTOMLEFT', frame.Health, 'TOPLEFT', 5, 1)
        frame.Level:SetJustifyH('LEFT')
    else
        frame.Portrait:SetSize(37, 37)
        frame.Portrait:SetPoint('TOPLEFT', 5.5, -4.5)
        frame.Health = NewBar(frame, 70, 10.5, kind, 'Health', 'uipartyframeportraitonhealthmask', 128, 16.5, -29, 3)
        frame.Health:SetPoint('BOTTOMLEFT', 44, 22)
        frame.Power = NewBar(frame, 74, 7.5, kind, 'Mana', 'uipartyframeportraitonmanamask', 128, 16.5, -27, 4)
        frame.Power:SetPoint('TOPLEFT', frame.Health, 'BOTTOMLEFT', -4, -0.5)
        frame.Name:SetPoint('BOTTOMLEFT', frame.Health, 'TOPLEFT', 0, 1)
        frame.Level:Hide()
    end
    frame.Name:SetSize(kind == 'TargetofTarget' and 68 or 100, 12)
    frame.Rest = NewLabel(frame, 11)
    frame.Rest:SetText('Zzz')
    frame.Rest:SetTextColor(1, 0.82, 0)
    frame.Rest:SetPoint('BOTTOMRIGHT', frame.Portrait, 'TOPRIGHT', 0, -4)
    frame.Rest:Hide()
    frame:Hide()
    return hud
end

local function MirrorBar(destination, source)
    if not source then destination:SetAlpha(0); return end
    destination:SetMinMaxValues(source:GetMinMaxValues())
    destination:SetValue(source:GetValue())
    destination:SetStatusBarColor(source:GetStatusBarColor())
    -- IsShown can be secret: hand it straight to the native rendering setter.
    destination:SetAlphaFromBoolean(source:IsShown(), 1, 0)
    CopyLabel(destination.ValueText, source.TextString or source.CenterText or source.HealthBarText or source.ManaBarText)
end

local visualHooked = setmetatable({}, {__mode='k'})
local function HookVisualSource(source, text)
    if not source or visualHooked[source] then return end
    visualHooked[source] = true
    -- These are posthooks of rendering setters, not replacements for unit
    -- events/controllers. Forward opaque secret values only to widgets.
    for _, method in ipairs(text and {'SetText', 'SetFormattedText'} or {'SetValue','SetMinMaxValues','SetStatusBarColor'}) do
        if source[method] then
        hooksecurefunc(source, method, function() DF:UpdateLunaUnitVisuals() end)
        end
    end
end

local function SyncUnitVisual(hud)
    if not hud.enabled then return end
    local frame, root = hud.frame, hud.root
    local health, power, name = UnitParts(root)
    local main = root.PlayerFrameContent and root.PlayerFrameContent.PlayerFrameContentMain or
        root.TargetFrameContent and root.TargetFrameContent.TargetFrameContentMain
    MirrorBar(frame.Health, health)
    MirrorBar(frame.Power, power)
    if hud.textureEnabled ~= DF.settings.unitTextures then
        hud.textureEnabled = DF.settings.unitTextures
        local textureKind = hud.kind == 'TargetofTarget' and 'Target' or hud.kind
        frame.Health:SetStatusBarTexture(hud.textureEnabled and
            textureBase .. 'Unitframe\\UI-HUD-UnitFrame-' .. textureKind .. '-PortraitOn-Bar-Health' or 'Interface\\TargetingFrame\\UI-StatusBar')
        hud.powerResource = nil
    end
    CopyLabel(frame.Name, name or (hud.unit == 'player' and PlayerName))
    CopyLabel(frame.Level, hud.unit == 'player' and PlayerLevelText or main and main.LevelText)
    if hud.portraitDirty and type(SetPortraitTexture) == 'function' then
        SetPortraitTexture(frame.Portrait, root.unit or hud.unit, true)
        hud.portraitDirty = false
    end
    if power and type(UnitPowerType) == 'function' then
        local _, token = UnitPowerType(root.unit or hud.unit)
        if not DF.IsSecretValue(token) then
            local resources = {MANA = 'Mana', RAGE = 'Rage', FOCUS = 'Focus', ENERGY = 'Energy', RUNIC_POWER = 'RunicPower'}
            local resource = resources[token] or 'Mana'
            if hud.powerResource ~= resource then
                local textureKind = hud.kind == 'TargetofTarget' and 'Target' or hud.kind
                frame.Power:SetStatusBarTexture(hud.textureEnabled and
                    textureBase .. 'Unitframe\\UI-HUD-UnitFrame-' .. textureKind .. '-PortraitOn-Bar-' .. resource or 'Interface\\TargetingFrame\\UI-StatusBar')
                hud.powerResource = resource
            end
        end
    end
    frame.Rest:SetShown(hud.unit == 'player' and type(IsResting) == 'function' and IsResting())
end

function DF:UpdateLunaUnitVisuals(portraits)
    for _, hud in pairs(unitVisuals) do
        if portraits then hud.portraitDirty = true end
        SyncUnitVisual(hud)
    end
end

-- Replace the earlier texture-only adapter. All parts now share Luna's own
-- coordinate system; no Classic level circle or portrait flash is left behind.
function DF:StyleUnitFrames(enabled)
    local show = enabled and self.settings.unitArt
    for name in pairs(unitTokens) do
        local root = _G[name]
        if Allowed(root) then
            local hud = unitVisuals[name]
            if show and not hud and not InCombatLockdown() then hud = CreateUnitVisual(name, root) end
            local health, power, nameText = UnitParts(root)
            local main = root.PlayerFrameContent and root.PlayerFrameContent.PlayerFrameContentMain or
                root.TargetFrameContent and root.TargetFrameContent.TargetFrameContentMain
            local art = root.PlayerFrameContainer or root.TargetFrameContainer
            Suppress(art, show)
            -- PlayerFrame_OnUpdate changes StatusTexture's alpha every frame.
            -- Suppress its parent visual layer, not that animated alpha alone.
            if main and main.GetAlpha then Suppress(main, show) end
            Suppress(health and health:GetParent(), show and main ~= nil)
            Suppress(power, show)
            Suppress(nameText or (name == 'PlayerFrame' and PlayerName), show)
            if main then
                Suppress(main.ReputationColor, show)
                Suppress(main.LevelBackgroundCircle, show)
                Suppress(main.LevelText, show)
                Suppress(main.StatusTexture, show)
                Suppress(main.PlayerPortraitCornerIcon, show)
            end
            local contextual = root.PlayerFrameContent and root.PlayerFrameContent.PlayerFrameContentContextual
            if contextual then
                Suppress(contextual.PlayerRestLoop, show)
                Suppress(contextual.PlayerPortraitCornerIcon, show)
                Suppress(contextual.AttackIcon, show)
            end
            Suppress(name == 'PlayerFrame' and PlayerLevelText, show)
            if not art then
                Suppress(root.FrameTexture or (name == 'PetFrame' and PetFrameTexture), show)
                Suppress(root.Portrait, show)
                Suppress(health, show)
                Suppress(name == 'PetFrame' and PetFrameFlash, show)
                Suppress(name == 'PetFrame' and PetAttackModeTexture, show)
            end
            if hud then
                hud.enabled = show
                hud.frame:SetShown(show)
                Tint(hud.frame.Art, show and self.settings.frameTint)
                local size = (hud.kind == 'TargetofTarget' and 9 or 12) * self.settings.unitFontScale
                for _, text in ipairs({hud.frame.Name, hud.frame.Level, hud.frame.Health.ValueText, hud.frame.Power.ValueText}) do
                    text:SetFont(STANDARD_TEXT_FONT, size, 'OUTLINE')
                end
                SyncUnitVisual(hud)
                HookVisualSource(health)
                HookVisualSource(power)
                for _, bar in ipairs({health or false, power or false}) do
                    if bar then HookVisualSource(bar.TextString or bar.CenterText or bar.HealthBarText or bar.ManaBarText, true) end
                end
                HookVisualSource(nameText or (name == 'PlayerFrame' and PlayerName), true)
                HookVisualSource(name == 'PlayerFrame' and PlayerLevelText or main and main.LevelText, true)
            end
        end
    end
end

-- Sprite coordinates from the bundled Classic Luna micromenu atlas.
local microAtlas = {
    ['ButtonBG-Down']={0.0654297,0.12793,0.330078,0.490234},
    ['ButtonBG-Up']={0.0654297,0.12793,0.494141,0.654297},
    ['ButtonBG-Down']={0.0654297,0.12793,0.330078,0.490234},
    ['ButtonBG-Up']={0.0654297,0.12793,0.494141,0.654297},
    ['Achievements-Disabled']={0.000976562,0.0634766,0.00195312,0.162109},
    ['Achievements-Down']={0.000976562,0.0634766,0.166016,0.326172},
    ['Achievements-Mouseover']={0.000976562,0.0634766,0.330078,0.490234},
    ['Achievements-Up']={0.000976562,0.0634766,0.494141,0.654297},
    ['AdventureGuide-Disabled']={0.000976562,0.0634766,0.658203,0.818359},
    ['AdventureGuide-Down']={0.000976562,0.0634766,0.822266,0.982422},
    ['AdventureGuide-Mouseover']={0.0654297,0.12793,0.00195312,0.162109},
    ['AdventureGuide-Up']={0.0654297,0.12793,0.166016,0.326172},
    ['Collections-Disabled']={0.0654297,0.12793,0.658203,0.818359},
    ['Collections-Down']={0.0654297,0.12793,0.822266,0.982422},
    ['Collections-Mouseover']={0.129883,0.192383,0.00195312,0.162109},
    ['Collections-Up']={0.129883,0.192383,0.166016,0.326172},
    ['Communities-Icon-Notification']={0.581055,0.608398,0.166016,0.220703},
    ['GameMenu-Disabled']={0.129883,0.192383,0.330078,0.490234},
    ['GameMenu-Down']={0.129883,0.192383,0.494141,0.654297},
    ['GameMenu-Mouseover']={0.129883,0.192383,0.658203,0.818359},
    ['GameMenu-Up']={0.129883,0.192383,0.822266,0.982422},
    ['Groupfinder-Disabled']={0.194336,0.256836,0.00195312,0.162109},
    ['Groupfinder-Down']={0.194336,0.256836,0.166016,0.326172},
    ['Groupfinder-Mouseover']={0.194336,0.256836,0.330078,0.490234},
    ['Groupfinder-Up']={0.194336,0.256836,0.494141,0.654297},
    ['GuildCommunities-Disabled']={0.194336,0.256836,0.658203,0.818359},
    ['GuildCommunities-Down']={0.194336,0.256836,0.822266,0.982422},
    ['GuildCommunities-Mouseover']={0.258789,0.321289,0.658203,0.818359},
    ['GuildCommunities-Up']={0.258789,0.321289,0.822266,0.982422},
    ['Highlightalert']={0.323242,0.385742,0.00195312,0.162109},
    ['Questlog-Disabled']={0.323242,0.385742,0.494141,0.654297},
    ['Questlog-Down']={0.323242,0.385742,0.658203,0.818359},
    ['Questlog-Mouseover']={0.323242,0.385742,0.822266,0.982422},
    ['Questlog-Up']={0.387695,0.450195,0.00195312,0.162109},
    ['Shop-Disabled']={0.387695,0.450195,0.166016,0.326172},
    ['Shop-Mouseover']={0.387695,0.450195,0.330078,0.490234},
    ['Shop-Down']={0.387695,0.450195,0.494141,0.654297},
    ['Shop-Up']={0.387695,0.450195,0.658203,0.818359},
    ['SpecTalents-Disabled']={0.387695,0.450195,0.822266,0.982422},
    ['SpecTalents-Down']={0.452148,0.514648,0.00195312,0.162109},
    ['SpecTalents-Mouseover']={0.452148,0.514648,0.166016,0.326172},
    ['SpecTalents-Up']={0.452148,0.514648,0.330078,0.490234},
    ['SpellbookAbilities-Disabled']={0.452148,0.514648,0.494141,0.654297},
    ['SpellbookAbilities-Down']={0.452148,0.514648,0.658203,0.818359},
    ['SpellbookAbilities-Mouseover']={0.452148,0.514648,0.822266,0.982422},
    ['SpellbookAbilities-Up']={0.516602,0.579102,0.00195312,0.162109},
    ['StreamDLGreen-Down']={0.516602,0.579102,0.166016,0.326172},
    ['StreamDLGreen-Up']={0.516602,0.579102,0.330078,0.490234},
    ['StreamDLRed-Down']={0.516602,0.579102,0.494141,0.654297},
    ['StreamDLRed-Up']={0.516602,0.579102,0.658203,0.818359},
    ['StreamDLYellow-Down']={0.516602,0.579102,0.822266,0.982422},
    ['StreamDLYellow-Up']={0.581055,0.643555,0.00195312,0.162109},
    ['ButtonBG-Down']={0.0654297,0.12793,0.330078,0.490234},
    ['ButtonBG-Up']={0.0654297,0.12793,0.494141,0.654297},
    ['Portrait-Shadow-2x']={0.323242,0.385742,0.330078,0.490234},
    ['Portrait-Down-2x']={0.323242,0.385742,0.166016,0.326172},
    ['GuildCommunities-GuildColor-Disabled']={0.258789,0.321289,0.00195312,0.162109},
    ['GuildCommunities-GuildColor-Down']={0.258789,0.321289,0.166016,0.326172},
    ['GuildCommunities-GuildColor-Mouseover']={0.258789,0.321289,0.330078,0.490234},
    ['GuildCommunities-GuildColor-Up']={0.258789,0.321289,0.494141,0.654297},
}


function DF:StyleLunaMicroBags(enabled)
    local path = textureBase .. 'Micromenu\\uimicromenu2x'
    local glyphs = {SpellbookMicroButton='SpellbookAbilities',TalentMicroButton='SpecTalents',
        QuestLogMicroButton='Questlog',GuildMicroButton='GuildCommunities',
        LFDMicroButton='Groupfinder',CollectionsMicroButton='Collections',
        EJMicroButton='AdventureGuide',MainMenuMicroButton='GameMenu',StoreMicroButton='Shop'}
    for _, button in ipairs(MicroMenu and {MicroMenu:GetChildren()} or {}) do
        if Allowed(button) and button.GetNormalTexture then
            Texture(button.Background,path,enabled,microAtlas['ButtonBG-Up'])
            Texture(button.PushedBackground,path,enabled,microAtlas['ButtonBG-Down'])
            local key = glyphs[button:GetName()]
            if key then
                for _, state in ipairs({{'GetNormalTexture','Up'},{'GetPushedTexture','Down'},
                    {'GetDisabledTexture','Disabled'},{'GetHighlightTexture','Mouseover'}}) do
                    local crop = microAtlas[key .. '-' .. state[2]]
                    if crop and button[state[1]] then Texture(button[state[1]](button),path,enabled,crop) end
                end
            end
        end
    end
    local character = CharacterMicroButton
    if character then Texture(character.PortraitMask,textureBase .. 'Micromenu\\uimicromenuportraitmask2x',enabled) end
    if BagsBar then
        Alpha(BagsBar.BorderArt,0,enabled)
        for _, pool in ipairs({BagsBar.HorizontalDividersPool or false, BagsBar.VerticalDividersPool or false}) do
            if pool then
                for divider in pool:EnumerateActive() do
                    for _, piece in ipairs({divider:GetRegions()}) do Alpha(piece,0,enabled) end
                end
            end
        end
        if not self.bagSkinHooked and type(BagsBar.UpdateDividers)=='function' then
            self.bagSkinHooked=true
            hooksecurefunc(BagsBar,'UpdateDividers',function() self:QueueRefresh() end)
        end
    end
    for index=0,3 do
        local button=_G['CharacterBag'..index..'Slot']
        if button then
            local icon=button.icon or button.Icon or _G['CharacterBag'..index..'SlotIconTexture']
            local size=button:GetWidth()
            Texture(button:GetNormalTexture(),textureBase..'bagslots2x',enabled,{0.576172,0.695312,0.0078125,0.484375})
            Geometry(button:GetNormalTexture(),button,size,size,'CENTER',0,0,enabled)
            Texture(button.SquareMask,textureBase..'bagmask',enabled)
            if button.SquareMask then Geometry(button.SquareMask,button,size,size,'CENTER',0,0,enabled) end
            Geometry(icon,button,size,size,'CENTER',0,0,enabled)
        end
    end
    local bag=MainMenuBarBackpackButton
    if bag then
        Texture(bag.icon or bag.Icon,textureBase..'bigbag',enabled)
        Texture(bag:GetNormalTexture(),textureBase..'bagslotCutout',enabled)
    end
end
