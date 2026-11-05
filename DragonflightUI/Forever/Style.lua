local _, ns = ...
local DF = ns.DF
local textureBase = 'Interface\\AddOns\\DragonflightUI\\Textures\\'
local fontBases, alphaBases, textureBases, colorBases = {}, {}, {}, {}

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

local function StatusTexture(bar, path, apply)
    if not Allowed(bar) or not bar.GetStatusBarTexture then return end
    local texture = bar:GetStatusBarTexture()
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
        texture:SetTexCoord(0, 1, 0, 1)
    else
        if base.atlas and base.atlas ~= '' then
            texture:SetAtlas(base.atlas)
        else
            texture:SetTexture(base.texture)
        end
        texture:SetTexCoord(unpack(base.coords))
    end
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
    local power = frame.manabar or frame.ManaBar or main and main.ManaBar
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
    Edge(button, icon, enabled and settings.actionbarBorders, 1)
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    Alpha(normal, 0, enabled and settings.actionbarBorders)
    Font(hotkey, settings.hotkeySize, enabled)
    Font(macro, settings.macroSize, enabled)
    Alpha(hotkey, 0, enabled and not settings.hotkeys)
    Alpha(macro, 0, enabled and not settings.macroNames)
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

function DF:StyleUnitFrames(enabled)
    for _, name in ipairs({'PlayerFrame', 'TargetFrame', 'FocusFrame', 'PetFrame', 'TargetFrameToT', 'FocusFrameToT'}) do
        local frame = _G[name]
        if Allowed(frame) then
            local art = frame.PlayerFrameContainer or frame.TargetFrameContainer
            Tint(art and art.FrameTexture, enabled and self.settings.frameTint)
            local health, power, nameText = UnitParts(frame)
            local side = name == 'PlayerFrame' and 'Player' or 'Target'
            StatusTexture(health, textureBase .. 'Unitframe\\UI-HUD-UnitFrame-' .. side .. '-PortraitOn-Bar-Health',
                enabled and self.settings.unitTextures)
            Font(nameText, self.settings.unitFontScale, enabled, true)
            for _, bar in ipairs({health or false, power or false}) do
                if bar then
                    for _, key in ipairs({'TextString', 'CenterText', 'LeftText', 'RightText'}) do
                        Font(bar[key], self.settings.unitFontScale, enabled, true)
                    end
                end
            end
        end
    end
    -- Party/Raid pools, unit selection, heal predictions, portrait masks, and
    -- health/power calculations stay exclusively under Blizzard's control.
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
    local enabled = self.active and self.settings.enabled
    self:StyleActionBars(enabled and self.settings.actionbars)
    self:StyleUnitFrames(enabled and self.settings.unitframes)
    self:StyleAuraFrame(BuffFrame, enabled and self.settings.auras)
    self:StyleAuraFrame(DebuffFrame, enabled and self.settings.auras)
    self:StyleCastBars(enabled and self.settings.castbars)
    self:StyleTooltip(enabled and self.settings.tooltip)
    Tint(MinimapCompassTexture, enabled and self.settings.minimap and self.settings.frameTint)
    Tint(MinimapCompassTextureUnderlay, enabled and self.settings.minimap and self.settings.frameTint)
    for name, key in pairs({Actionbar = 'actionbars', Unitframe = 'unitframes', Buffs = 'auras', Castbar = 'castbars', Tooltip = 'tooltip', Minimap = 'minimap'}) do
        self.moduleStatus[name] = {enabled = enabled and self.settings[key] == true, setupCompleted = true, native = true}
    end
end
