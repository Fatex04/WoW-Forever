local _, ns = ...
local DF = ns.DF
local textureBase = 'Interface\\AddOns\\DragonflightUI\\Textures\\'
local fontBases, alphaBases, textureBases, colorBases, artSizes = {}, {}, {}, {}, {}
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

local function StatusTexture(bar, path, apply)
    if Allowed(bar) and bar.GetStatusBarTexture then Texture(bar:GetStatusBarTexture(), path, apply) end
end

-- Only resize decorative texture regions. Secure frame geometry, hit rectangles
-- and the positions/values of the health and power bars stay native.
local function ArtSize(texture, width, height, apply)
    if not Allowed(texture) then return end
    if not artSizes[texture] then
        artSizes[texture] = {texture:GetWidth(), texture:GetHeight()}
    end
    local base = artSizes[texture]
    texture:SetSize(apply and width or base[1], apply and height or base[2])
end

local function ForgetNativeArt(texture)
    if texture then textureBases[texture], artSizes[texture] = nil, nil end
end

local function IsCompactTarget(texture)
    if not Allowed(texture) then return false end
    local atlas = textureBases[texture] and textureBases[texture].atlas or texture:GetAtlas()
    if DF.IsSecretValue(atlas) then return true end
    return type(atlas) == 'string' and atlas:find('MinusMob', 1, true) ~= nil
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
    ArtSize(normal, 46, 45, borders)
    ArtSize(pushed, 46, 45, borders)
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

function DF:StyleUnitFrames(enabled)
    for _, name in ipairs({'PlayerFrame', 'TargetFrame', 'FocusFrame', 'PetFrame', 'TargetFrameToT', 'FocusFrameToT'}) do
        local frame = _G[name]
        if Allowed(frame) then
            local art = frame.PlayerFrameContainer or frame.TargetFrameContainer
            local small = name == 'PetFrame' or name == 'TargetFrameToT' or name == 'FocusFrameToT'
            local frameTexture = art and art.FrameTexture or frame.FrameTexture or
                name == 'PetFrame' and PetFrameTexture
            local compact = IsCompactTarget(frameTexture)
            local unitArt = enabled and self.settings.unitArt and not compact
            local kind = small and 'TargetofTarget' or name == 'PlayerFrame' and 'Player' or 'Target'
            local data = unitArtData[kind]
            Texture(frameTexture, textureBase .. 'Unitframe2x\\' .. data[1], unitArt, {0, data[4], 0, data[5]})
            ArtSize(frameTexture, data[2], data[3], unitArt)
            Tint(frameTexture, enabled and self.settings.frameTint)
            if art and art.AlternatePowerFrameTexture then
                Texture(art.AlternatePowerFrameTexture, textureBase .. 'Unitframe2x\\' .. data[1],
                    unitArt, {0, data[4], 0, data[5]})
                ArtSize(art.AlternatePowerFrameTexture, data[2], data[3], unitArt)
                Tint(art.AlternatePowerFrameTexture, enabled and self.settings.frameTint)
            end
            local health, power, nameText = UnitParts(frame)
            StatusTexture(health, textureBase .. 'Unitframe\\UI-HUD-UnitFrame-' .. kind .. '-PortraitOn-Bar-Health',
                enabled and self.settings.unitTextures and not compact)
            Font(nameText, self.settings.unitFontScale, enabled, true)
            for _, bar in ipairs({health or false, power or false}) do
                if bar then
                    for _, key in ipairs({'TextString', 'CenterText', 'LeftText', 'RightText'}) do
                        Font(bar[key], self.settings.unitFontScale, enabled, true)
                    end
                end
            end
        end
        if Allowed(frame) and type(frame.CheckClassification) == 'function' and not frame.DFLunaClassificationHooked then
            frame.DFLunaClassificationHooked = true
            hooksecurefunc(frame, 'CheckClassification', function()
                local container = frame.TargetFrameContainer
                ForgetNativeArt(container and container.FrameTexture)
                local health = UnitParts(frame)
                if health then ForgetNativeArt(health:GetStatusBarTexture()) end
                self:StyleUnitFrames(self.active and self.settings.enabled and self.settings.unitframes)
            end)
        end
    end
    if not self.playerArtHooked and type(PlayerFrame_UpdateArt) == 'function' then
        self.playerArtHooked = true
        hooksecurefunc('PlayerFrame_UpdateArt', function()
            local art = PlayerFrame and PlayerFrame.PlayerFrameContainer
            if art then
                ForgetNativeArt(art.FrameTexture)
                ForgetNativeArt(art.AlternatePowerFrameTexture)
            end
            self:StyleUnitFrames(self.active and self.settings.enabled and self.settings.unitframes)
        end)
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
    self:RefreshLunaEditMode()
    for name, key in pairs({Actionbar = 'actionbars', Unitframe = 'unitframes', Buffs = 'auras', Castbar = 'castbars', Tooltip = 'tooltip', Minimap = 'minimap'}) do
        self.moduleStatus[name] = {enabled = enabled and self.settings[key] == true, setupCompleted = true, native = true}
    end
end
