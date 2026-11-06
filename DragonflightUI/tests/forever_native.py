"""Run with Python + lupa (Lua 5.1). No WoW installation is needed.

Loads the real Forever TOC, embedded Ace libraries, and the whole native runtime.
The fixture rejects legacy templates, secure gameplay mutations and secret-value evaluation.
Opaque widget output may pass directly to the rendering APIs that accept it.
It models the native frame shapes of Blizzard's build 1.60.1.70790.
"""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


def files_in_manifest(path):
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        target = ROOT / line.replace('\\', '/')
        if target.suffix == '.xml':
            for node in ET.parse(target).getroot():
                child = target.parent / node.attrib['file']
                assert child.is_file(), child
                yield child
        else:
            assert target.is_file(), target
            yield target


class NativeRuntime(unittest.TestCase):
    def boot(self, before='', saved_variables=''):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute((ROOT / 'tests/forever_native_fixture.lua').read_text(encoding='utf-8'))
        if before:
            lua.execute(before)
        namespace = lua.table()
        for path in files_in_manifest(ROOT / 'DragonflightUI_Forever.toc'):
            lua.execute(path.read_text(encoding='utf-8-sig'), 'DragonflightUI', namespace, name=str(path))
        if saved_variables:
            lua.execute(saved_variables)
        lua.execute("dispatch('ADDON_LOADED', 'DragonflightUI'); loggedIn = true; dispatch('PLAYER_LOGIN'); flushTimers()")
        self.assertEqual(lua.eval('#reportedErrors'), 0, list(lua.globals().reportedErrors.values()))
        self.assertEqual(lua.eval("DragonflightUI_API.Version.InterfaceVersion"), 16001)
        return lua

    def test_real_manifest_starts_with_current_build(self):
        lua = self.boot()
        self.assertTrue(lua.eval('DragonflightUIDB.global.foreverDiagnostics.nativeRuntime'))
        self.assertEqual(lua.eval('DragonflightUIDB.global.foreverDiagnostics.version'), '1.1')
        self.assertTrue(lua.eval('DragonflightUIDB.global.foreverDiagnostics.modules.Actionbar.setupCompleted'))
        self.assertIsNone(lua.eval('MainMenuBarLeftEndCap'))
        self.assertIsNone(lua.eval('MirrorTimer1'))
        self.assertEqual(lua.eval('PlayerFrame:GetScript("OnClick")()'), 'native-target')
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1]:GetScript("OnClick")()'), 'native-click')
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].secureAction'), 'native-action')
        self.assertTrue(lua.eval('BuffFrame.events.UNIT_AURA'))
        self.assertTrue(lua.eval('BuffFrame.auraFrames[1].nativeCancelBuff'))
        self.assertEqual(lua.eval('PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar.fill.masks[1]'), 'native-mask')
        self.assertEqual(lua.eval('PlayerFrame.PlayerFrameContainer.alpha'), 0)
        self.assertTrue(lua.eval('DragonflightUILunaPlayerFrame.Art.desaturated'))
        self.assertEqual(lua.eval('MainActionBar.BorderArt.alpha'), 0)
        self.assertTrue(lua.eval("MainActionBar.actionButtons[1].normal.texture:find('uiactionbar2x', 1, true) ~= nil"))
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].SlotArt.alpha'), 0)
        self.assertEqual(lua.eval('DragonflightUILunaPlayerFrame.width'), 198)
        self.assertEqual(lua.eval('DragonflightUILunaTargetFrame.width'), 192)
        self.assertTrue(lua.eval('BuffFrame.auraFrames[1].DFLunaForeverEdge.shown'))
        self.assertEqual(lua.eval('PlayerCastingBarFrame.fill.atlas'), 'native-atlas')
        self.assertEqual(lua.eval('PlayerCastingBarFrame.fill.writes'), 0)

    def test_disabled_theme_restores_native_art_fonts_and_alpha(self):
        lua = self.boot()
        lua.execute("DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF.settings.enabled = false; DF:QueueRefresh(); flushTimers()")
        self.assertEqual(lua.eval('MainActionBar.BorderArt.alpha'), 0.8)
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].normal.alpha'), 0.8)
        self.assertIsNone(lua.eval('MainActionBar.actionButtons[1].DFLunaForeverEdge'))
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].normal.atlas'), 'native-atlas')
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].SlotArt.alpha'), 0.8)
        self.assertEqual(lua.eval('PlayerFrame.PlayerFrameContainer.FrameTexture.width'), 232)
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].TextOverlayContainer.HotKey.font[2]'), 10)
        self.assertEqual(lua.eval('PlayerCastingBarFrame.fill.atlas'), 'native-atlas')
        self.assertEqual(lua.eval('GameTooltip.scale'), 0.9)
        self.assertFalse(lua.eval('PlayerFrame.PlayerFrameContainer.FrameTexture.desaturated'))
        self.assertEqual(list(lua.eval('PlayerFrame.PlayerFrameContainer.FrameTexture.vertexColor').values()), [1, 1, 1, 1])

    def test_refresh_defers_in_combat_and_runs_after_regen(self):
        lua = self.boot()
        lua.execute("DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); combat = true; DF.settings.hotkeySize = 17; dispatch('UPDATE_BINDINGS'); flushTimers()")
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].TextOverlayContainer.HotKey.font[2]'), 12)
        self.assertTrue(lua.eval('DF.pendingRefresh'))
        lua.execute("combat = false; dispatch('PLAYER_REGEN_ENABLED'); flushTimers()")
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].TextOverlayContainer.HotKey.font[2]'), 17)

    def test_native_aura_updates_and_private_anchors_are_preserved(self):
        lua = self.boot()
        lua.execute('BuffFrame:UpdateAuraButtons(); BuffFrame:UpdateAuraButtons()')
        self.assertEqual(lua.eval('BuffFrame.nativeUpdates'), 2)
        self.assertIsNone(lua.eval('BuffFrame.auraFrames[2].DFLunaForeverEdge'))
        self.assertTrue(lua.eval('BuffFrame.events.UNIT_AURA'))

    def test_native_flyout_buttons_created_on_first_use_are_styled(self):
        lua = self.boot()
        self.assertEqual(lua.eval('SpellFlyout:Toggle()'), 'native-flyout')
        lua.execute('flushTimers()')
        self.assertEqual(lua.eval('SpellFlyout.nativeToggles'), 1)
        self.assertTrue(lua.eval("SpellFlyout.children[2].normal.texture:find('uiactionbar2x', 1, true) ~= nil"))
        self.assertEqual(lua.eval('SpellFlyout.children[2]:GetScript("OnClick")()'), 'native-click')

    def test_native_edit_mode_opens_without_rewriting_layouts(self):
        lua = self.boot()
        lua.execute("DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF:ToggleOptions(); DF:OpenNativeEditMode()")
        self.assertTrue(lua.eval('EditModeManagerFrame:IsShown()'))
        self.assertFalse(lua.eval('DF.options:IsShown()'))
        lua.execute("MainActionBar.BorderArt.alpha = 1; HideUIPanel(EditModeManagerFrame); flushTimers()")
        self.assertEqual(lua.eval('MainActionBar.BorderArt.alpha'), 0)

    def test_escape_menu_edit_button_opens_luna_editor(self):
        lua = self.boot()
        lua.execute('GameMenuFrame:InitButtons(); GameMenuFrame.buttons[2].callback()')
        self.assertTrue(lua.eval('DragonflightUIEditModeFrame:IsShown()'))
        self.assertTrue(lua.eval('DragonflightUIEditModeDimmer:IsShown()'))
        self.assertTrue(lua.eval('EditModeManagerFrame:IsEditModeActive()'))
        self.assertEqual(lua.eval('EditModeManagerFrame.Title.alpha'), 0)
        self.assertFalse(lua.eval('EditModeManagerFrame:IsMouseEnabled()'))
        self.assertTrue(lua.eval('EditModeManagerFrame.LayoutDropdown:GetParent() == DragonflightUIEditModeFrame'))

    def test_editor_uses_original_native_save_and_revert_controls(self):
        lua = self.boot()
        lua.execute("saveCallback = EditModeManagerFrame.SaveChangesButton:GetScript('OnClick'); "
                    "revertCallback = EditModeManagerFrame.RevertAllChangesButton:GetScript('OnClick'); "
                    "DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF:OpenLunaEditMode()")
        self.assertTrue(lua.eval("EditModeManagerFrame.SaveChangesButton:GetScript('OnClick') == saveCallback"))
        self.assertTrue(lua.eval("EditModeManagerFrame.RevertAllChangesButton:GetScript('OnClick') == revertCallback"))
        lua.execute("EditModeManagerFrame.unsavedChanges = true; saveCallback()")
        self.assertEqual(lua.eval('EditModeManagerFrame.saves'), 1)
        self.assertFalse(lua.eval('EditModeManagerFrame.unsavedChanges'))
        lua.execute("EditModeManagerFrame.unsavedChanges = true; revertCallback()")
        self.assertEqual(lua.eval('EditModeManagerFrame.reverts'), 1)

    def test_editor_keeps_unsaved_warning_and_restores_native_controls(self):
        lua = self.boot()
        lua.execute("DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF:OpenLunaEditMode(); "
                    "EditModeManagerFrame.unsavedChanges = true; DF:ToggleEditMode()")
        self.assertTrue(lua.eval('EditModeManagerFrame.warningShown'))
        self.assertTrue(lua.eval('DragonflightUIEditModeFrame:IsShown()'))
        lua.execute("EditModeManagerFrame.unsavedChanges = false; DF:ToggleEditMode()")
        self.assertFalse(lua.eval('EditModeManagerFrame:IsShown()'))
        self.assertFalse(lua.eval('DragonflightUIEditModeFrame:IsShown()'))
        self.assertFalse(lua.eval('DragonflightUIEditModeDimmer:IsShown()'))
        self.assertTrue(lua.eval('EditModeManagerFrame.LayoutDropdown:GetParent() == EditModeManagerFrame'))
        self.assertEqual(lua.eval('EditModeManagerFrame.Title.alpha'), 0.8)
        self.assertTrue(lua.eval('EditModeManagerFrame:IsMouseEnabled()'))
        self.assertEqual(lua.eval('EditModeManagerFrame.LayoutDropdown.points[1][4]'), 5)

    def test_editor_toggle_restores_native_window_without_leaving_edit_mode(self):
        lua = self.boot()
        lua.execute("DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF:OpenLunaEditMode(); "
                    "DF.settings.lunaEditMode = false; DF:QueueRefresh(); flushTimers()")
        self.assertTrue(lua.eval('EditModeManagerFrame:IsShown()'))
        self.assertTrue(lua.eval('EditModeManagerFrame:IsEditModeActive()'))
        self.assertFalse(lua.eval('DragonflightUIEditModeFrame:IsShown()'))
        self.assertTrue(lua.eval('EditModeManagerFrame.LayoutDropdown:GetParent() == EditModeManagerFrame'))

    def test_editor_combat_cleanup_preserves_pending_layout_changes(self):
        lua = self.boot()
        lua.execute("DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF:OpenLunaEditMode(); "
                    "EditModeManagerFrame.unsavedChanges = true; combat = true; dispatch('PLAYER_REGEN_DISABLED')")
        self.assertFalse(lua.eval('DragonflightUIEditModeFrame:IsShown()'))
        self.assertFalse(lua.eval('DragonflightUIEditModeDimmer:IsShown()'))
        self.assertTrue(lua.eval('EditModeManagerFrame.unsavedChanges'))
        lua.execute("combat = false; dispatch('PLAYER_REGEN_ENABLED'); flushTimers()")
        self.assertTrue(lua.eval('DragonflightUIEditModeFrame:IsShown()'))
        self.assertTrue(lua.eval('EditModeManagerFrame.unsavedChanges'))

    def test_editor_falls_back_when_native_chrome_changes(self):
        lua = self.boot('EditModeManagerFrame.AccountSettings = nil')
        lua.execute("LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'):OpenLunaEditMode()")
        self.assertTrue(lua.eval('EditModeManagerFrame:IsShown()'))
        self.assertEqual(lua.eval('EditModeManagerFrame.Title.alpha'), 0.8)
        self.assertTrue(lua.eval('EditModeManagerFrame:IsMouseEnabled()'))
        self.assertIsNone(lua.eval('DragonflightUIEditModeFrame'))

    def test_editor_follows_native_locked_modal_visibility(self):
        lua = self.boot()
        lua.execute("DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF:OpenLunaEditMode(); "
                    "EditModeManagerFrame.locked = true; HideUIPanel(EditModeManagerFrame)")
        self.assertTrue(lua.eval('EditModeManagerFrame:IsEditModeActive()'))
        self.assertFalse(lua.eval('DragonflightUIEditModeFrame:IsShown()'))
        self.assertTrue(lua.eval('EditModeManagerFrame.LayoutDropdown:GetParent() == EditModeManagerFrame'))
        lua.execute("ShowUIPanel(EditModeManagerFrame); EditModeManagerFrame.locked = false")
        self.assertTrue(lua.eval('DragonflightUIEditModeFrame:IsShown()'))
        self.assertTrue(lua.eval('EditModeManagerFrame.LayoutDropdown:GetParent() == DragonflightUIEditModeFrame'))

    def test_editor_resizes_after_deferred_advanced_settings_layout(self):
        lua = self.boot()
        lua.execute("LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'):OpenLunaEditMode()")
        self.assertEqual(lua.eval('DragonflightUIEditModeFrame.height'), 299)
        lua.execute('EditModeManagerFrame.AccountSettings:SetHeight(320)')
        self.assertEqual(lua.eval('DragonflightUIEditModeFrame.height'), 574)
        lua.execute('EditModeManagerFrame.AccountSettings:SetHeight(45)')
        self.assertEqual(lua.eval('DragonflightUIEditModeFrame.height'), 299)

    def test_selected_system_opens_its_luna_appearance_page(self):
        lua = self.boot()
        lua.execute("DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF:OpenLunaEditMode(); "
                    "EditModeManagerFrame:SelectSystem(MainActionBar); DF:ShowSelectedAppearance()")
        self.assertTrue(lua.eval('EditModeManagerFrame.nativeSelectedSystem == MainActionBar'))
        self.assertTrue(lua.eval('DF.options.pages[2]:IsShown()'))
        self.assertFalse(lua.eval('DF.options.pages[1]:IsShown()'))
        lua.execute("EditModeManagerFrame:SelectSystem(PlayerFrame); DF:ShowSelectedAppearance()")
        self.assertTrue(lua.eval('DF.options.pages[3]:IsShown()'))

    def test_menu_pool_has_one_luna_entry_after_each_reset(self):
        lua = self.boot()
        for _ in range(3):
            lua.execute('GameMenuFrame:InitButtons()')
            self.assertEqual(lua.eval('#GameMenuFrame.buttons'), 5)
            self.assertEqual(lua.eval('GameMenuFrame.closeButton.layoutIndex'), 5)
            self.assertEqual(lua.eval('GameMenuFrame.buttons[1].callback()'), 'native-options')
            self.assertEqual(lua.eval('GameMenuFrame.buttons[2].callback()'), 'native-edit')
            self.assertEqual(lua.eval('GameMenuFrame.buttons[4].text'), 'Dragonflight UI Forever - Luna')
            self.assertEqual(lua.eval('GameMenuFrame.buttons[4].layoutIndex'), 4)
            self.assertEqual(lua.eval('GameMenuFrame.buttons[5].callback()'), 'native-close')
        lua.execute('GameMenuFrame.buttons[4].callback()')
        self.assertTrue(lua.eval('LibStub("AceAddon-3.0"):GetAddon("DragonflightUI").options:IsShown()'))

    def test_gamepad_menu_without_a_close_button(self):
        lua = self.boot('TEST_GAMEPAD = true')
        for _ in range(3):
            lua.execute('GameMenuFrame:InitButtons()')
            self.assertEqual(lua.eval('#GameMenuFrame.buttons'), 4)
            self.assertIsNone(lua.eval('GameMenuFrame.closeButton'))
            self.assertEqual(lua.eval('GameMenuFrame.buttons[4].text'), 'Dragonflight UI Forever - Luna')
            self.assertEqual(lua.eval('GameMenuFrame.buttons[4].layoutIndex'), 4)

    def test_saved_diagnostics_are_read_after_the_lua_files_load(self):
        lua = self.boot(saved_variables="DragonflightUIDB = {global = {foreverDiagnostics = "
                        "{errors = {{message = 'old error'}}}}, profiles = {Default = {kept = true}}}")
        self.assertEqual(lua.eval('DragonflightUIDB.global.foreverDiagnostics.previousErrors[1].message'), 'old error')
        self.assertEqual(lua.eval('#DragonflightUIDB.global.foreverDiagnostics.errors'), 0)
        self.assertTrue(lua.eval('DragonflightUIDB.profiles.Default.kept'))

    def test_options_build_in_both_languages_and_sliders_save(self):
        for locale in ('enUS', 'deDE'):
            lua = self.boot(f"TEST_LOCALE = '{locale}'")
            lua.execute('DF = LibStub("AceAddon-3.0"):GetAddon("DragonflightUI"); DF:ToggleOptions()')
            self.assertEqual(lua.eval('#DF.options.pages'), 5)
            lua.execute("for _, f in ipairs(frames) do if f.kind == 'Slider' then f:SetValue(f.high) end end; flushTimers()")
            self.assertEqual(lua.eval('DF.settings.hotkeySize'), 20)
            self.assertEqual(lua.eval('DF.settings.auraFontSize'), 18)
            self.assertEqual(lua.eval('DF.settings.tooltipScale'), 1.5)
            self.assertEqual(lua.eval('#reportedErrors'), 0)
            # Every control fits below the description and above the footer.
            lua.execute("""
                for _, f in ipairs(frames) do
                    if f.kind == 'Slider' or f.kind == 'CheckButton' and not f.gameplay then
                        local anchor = f.points[1]
                        if anchor and anchor[1] == 'TOPLEFT' and type(anchor[3]) == 'number' then
                            assert(anchor[3] - f.height >= -452, 'Options control overflows its page')
                        end
                    end
                end
            """)

    def test_optional_frames_missing_and_existing_profiles_survive(self):
        lua = self.boot("FocusFrame = nil; FocusFrameToT = nil; SpellFlyout = nil; MirrorTimerContainer = nil; "
                        "DragonflightUIDB = {namespaces = {ExistingProfile = 42}, forever = {hotkeySize = 900, enabled = 'invalid'}}")
        self.assertEqual(lua.eval('DragonflightUIDB.namespaces.ExistingProfile'), 42)
        self.assertTrue(lua.eval('DragonflightUIDB.forever.enabled'))
        self.assertEqual(lua.eval('DragonflightUIDB.forever.hotkeySize'), 20)

    def test_tooltip_scaling_does_not_accumulate(self):
        lua = self.boot()
        lua.execute("DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF.settings.tooltipScale = 1.5; DF:QueueRefresh(); flushTimers(); DF:QueueRefresh(); flushTimers()")
        self.assertAlmostEqual(lua.eval('GameTooltip.scale'), 1.35)

    def test_forbidden_frames_are_skipped(self):
        lua = self.boot('MainActionBar.actionButtons[1].forbidden = true')
        self.assertIsNone(lua.eval('MainActionBar.actionButtons[1].DFLunaForeverEdge'))
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].normal.texture'), 'native-texture')
        self.assertTrue(lua.eval("MainActionBar.actionButtons[2].normal.texture:find('uiactionbar2x', 1, true) ~= nil"))

    def test_native_button_art_updates_keep_luna_skin_and_restore_latest_native_art(self):
        lua = self.boot()
        lua.execute('combat = true; MainActionBar.actionButtons[1]:UpdateButtonArt()')
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].nativeArtUpdates'), 1)
        self.assertTrue(lua.eval("MainActionBar.actionButtons[1].normal.texture:find('uiactionbar2x', 1, true) ~= nil"))
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].normal.width'), 46)
        lua.execute("combat = false; DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); "
                    "DF.settings.actionbarBorders = false; DF:QueueRefresh(); flushTimers()")
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].normal.atlas'), 'updated-native-normal')
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].normal.width'), 51)

    def test_native_unit_art_updates_keep_luna_frames_without_secure_geometry_changes(self):
        lua = self.boot()
        lua.execute('combat = true; PlayerFrame_UpdateArt(); TargetFrame:CheckClassification()')
        self.assertEqual(lua.eval('PlayerFrame.nativeArtUpdates'), 1)
        self.assertEqual(lua.eval('TargetFrame.nativeClassifications'), 1)
        self.assertEqual(lua.eval('DragonflightUILunaPlayerFrame.width'), 198)
        self.assertEqual(lua.eval('DragonflightUILunaTargetFrame.width'), 192)
        self.assertEqual(lua.eval('PlayerFrame:GetScript("OnClick")()'), 'native-target')
        lua.execute("combat = false; DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); "
                    "DF.settings.unitArt = false; DF:QueueRefresh(); flushTimers()")
        self.assertEqual(lua.eval('PlayerFrame.PlayerFrameContainer.FrameTexture.atlas'), 'native-updated-player')
        self.assertEqual(lua.eval('PlayerFrame.PlayerFrameContainer.FrameTexture.width'), 240)
        self.assertEqual(lua.eval('TargetFrame.TargetFrameContainer.FrameTexture.atlas'), 'native-updated-classification')
        self.assertEqual(lua.eval('TargetFrame.TargetFrameContainer.FrameTexture.width'), 238)

    def test_classic_bar_dividers_are_hidden_and_restore_when_disabled(self):
        lua = self.boot()
        lua.execute('MainActionBar:UpdateDividers(); flushTimers()')
        self.assertEqual(lua.eval('MainActionBar.nativeDividerUpdates'), 1)
        self.assertEqual(lua.eval('MainActionBar.HorizontalDividersPool:EnumerateActive()().regions[1].alpha'), 0)
        lua.execute("DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); "
                    "DF.settings.hideBarArt = false; DF:QueueRefresh(); flushTimers()")
        self.assertEqual(lua.eval('MainActionBar.HorizontalDividersPool:EnumerateActive()().regions[1].alpha'), 0.8)

    def test_compact_native_target_art_is_not_stretched_to_full_target_size(self):
        lua = self.boot("TargetFrame.TargetFrameContainer.FrameTexture:SetAtlas('UI-HUD-UnitFrame-Target-MinusMob-PortraitOn')")
        self.assertEqual(lua.eval('TargetFrame.TargetFrameContainer.FrameTexture.atlas'),
                         'UI-HUD-UnitFrame-Target-MinusMob-PortraitOn')
        self.assertEqual(lua.eval('TargetFrame.TargetFrameContainer.FrameTexture.width'), 232)
        self.assertEqual(lua.eval('TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar.fill.atlas'), 'native-atlas')

    def test_missing_font_uses_a_real_fallback_before_text_updates(self):
        lua = self.boot('MainActionBar.actionButtons[1].TextOverlayContainer.HotKey.font = {}')
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].TextOverlayContainer.HotKey.font[1]'), 'Fonts\\FRIZQT__.TTF')
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].TextOverlayContainer.HotKey.font[2]'), 12)

    def test_legacy_globals_are_not_injected(self):
        lua = self.boot('UnitAura = nil')
        self.assertIsNone(lua.eval('UnitAura'))
        self.assertIsNone(lua.eval('GetSpellInfo'))
        self.assertIsNone(lua.eval('FillLocalizedClassList'))

    def test_texture_restores_all_eight_coordinates(self):
        lua = self.boot('PetFrame.healthbar.fill.coords = {0, 0, 0, 1, 1, 0, 1, 1}')
        lua.execute("DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF.settings.enabled = false; DF:QueueRefresh(); flushTimers()")
        self.assertEqual(list(lua.eval('PetFrame.healthbar.fill.coords').values()), [0, 0, 0, 1, 1, 0, 1, 1])

    def test_manifest_aliases_match_and_no_legacy_code_is_loaded(self):
        paths = [ROOT / name for name in ('DragonflightUI.toc', 'DragonflightUI_Camelot.toc', 'DragonflightUI_Forever.toc')]
        self.assertEqual(paths[0].read_bytes(), paths[1].read_bytes())
        self.assertEqual(paths[0].read_bytes(), paths[2].read_bytes())
        loaded = list(files_in_manifest(paths[0]))
        self.assertEqual([p.name for p in loaded if p.parent.name == 'Forever'], ['Core.lua', 'Style.lua', 'Options.lua'])
        self.assertFalse(any(p.parent.name in ('Modules', 'Mixin', 'Embed') for p in loaded))
        for asset in ('uiactionbar2x.blp', 'Art/luna-logo.tga', 'Castbar/CastingBarStandard2.blp',
                      'Unitframe2x/ui-hud-unitframe-player-portraiton-2x.blp',
                      'Unitframe2x/ui-hud-unitframe-target-portraiton-2x.blp',
                      'Unitframe2x/ui-hud-unitframe-targetoftarget-portraiton-2x.blp',
                      'Unitframe/UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health.tga',
                      'Unitframe/UI-HUD-UnitFrame-Target-PortraitOn-Bar-Health.tga'):
            self.assertTrue((ROOT / 'Textures' / asset).is_file(), asset)

    def test_unit_widgets_forward_opaque_native_values_and_text(self):
        lua = self.boot()
        lua.execute("native=PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar; "
                    "native.value=opaque('changed health'); native.TextString.text=opaque('changed label'); "
                    "dispatch('UNIT_HEALTH','player')")
        self.assertTrue(lua.eval('DragonflightUILunaPlayerFrame.Health.value == native.value'))
        self.assertTrue(lua.eval('DragonflightUILunaPlayerFrame.Health.low == native.low'))
        self.assertTrue(lua.eval('DragonflightUILunaPlayerFrame.Health.ValueText.text == native.TextString.text'))
        self.assertEqual(lua.eval('PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.alpha'), 0)
        self.assertEqual(lua.eval('#reportedErrors'), 0)

    def test_native_bar_render_updates_refresh_luna_without_a_full_theme_pass(self):
        lua = self.boot()
        lua.execute("native=TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar; "
                    "native:SetValue(opaque('new target health'))")
        self.assertTrue(lua.eval('DragonflightUILunaTargetFrame.Health.value == native.value'))
        self.assertEqual(lua.eval('#queued'), 0)
        lua.execute("LibStub('AceAddon-3.0'):GetAddon('DragonflightUI').settings.enabled=false; "
                    "LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'):QueueRefresh(); flushTimers()")
        self.assertEqual(lua.eval('PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.alpha'), 1)

    def test_portrait_panels_keep_their_icon_above_the_title_strip_and_restore(self):
        lua = self.boot()
        lua.execute("""
            panel=CreateFrame('Frame','FixturePanel',UIParent)
            panel.NineSlice=CreateFrame('Frame',nil,panel); panel.NineSlice:SetFrameLevel(500)
            for _,key in ipairs({'TopLeftCorner','TopRightCorner','BottomLeftCorner','BottomRightCorner',
                'TopEdge','BottomEdge','LeftEdge','RightEdge'}) do
                panel.NineSlice[key]=panel.NineSlice:CreateTexture()
            end
            panel.PortraitContainer=CreateFrame('Frame',nil,panel)
            panel.PortraitContainer:SetFrameLevel(400)
            panel.PortraitContainer.portrait=panel.PortraitContainer:CreateTexture()
            ShowUIPanel(panel)
        """)
        self.assertEqual(lua.eval('panel.PortraitContainer:GetFrameLevel()'), 501)
        self.assertTrue(lua.eval('panel.DFLunaPortraitBorder.shown'))
        lua.execute("LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'):StyleLunaWindow(panel,false)")
        self.assertEqual(lua.eval('panel.PortraitContainer:GetFrameLevel()'), 400)
        self.assertFalse(lua.eval('panel.DFLunaPortraitBorder.shown'))
        self.assertEqual(lua.eval('panel.NineSlice.TopLeftCorner.atlas'), 'native-atlas')

    def test_reference_layout_is_a_copy_and_applies_only_once(self):
        lua = self.boot()
        lua.execute("""
            function CopyTable(source)
                local copy={}; for key,value in pairs(source) do
                    copy[key]=type(value)=='table' and CopyTable(value) or value
                end; return copy
            end
            UnitGUID=function() return 'fixture-character' end
            Enum={EditModeActionBarSetting={Orientation=0,NumRows=1,NumIcons=2,IconSize=3,IconPadding=4,
                VisibleSetting=5,HideBarArt=6,HideBarScrolling=8,AlwaysShowButtons=9},
                EditModeUnitFrameSetting={},EditModeMinimapSetting={},EditModeMicroMenuSetting={},EditModeBagsSetting={},
                EditModeStatusTrackingBarSetting={},EditModeLayoutType={Character=2},
                ActionBarOrientation={Horizontal=0},ActionBarVisibleSetting={Always=0}}
            local system={system=1,systemIndex=1,settings={}}
            MainActionBar.system=1; MainActionBar.systemIndex=1
            for index=0,9 do system.settings[#system.settings+1]={setting=index,value=99} end
            EditModeManagerFrame.layoutInfo={activeLayout=1,layouts={{layoutName='My layout',layoutType=1,systems={system}}}}
            EditModeSettingDisplayInfoManager={displayInfoMap={[1]={[3]={ConvertValue=function(_,value) return (value-50)/10 end}}}}
            C_CVar={SetCVar=function() end}
            C_EditMode.SaveLayouts=function(info) savedLayouts=info; saves=(saves or 0)+1 end
            C_EditMode.SetActiveLayout=function(index) activeLayout=index end
            DF=LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
            DF:ApplyClassicReferenceLayout(); DF:ApplyClassicReferenceLayout()
        """)
        self.assertEqual(lua.eval('saves'), 1)
        self.assertEqual(lua.eval('savedLayouts.layouts[1].layoutName'), 'My layout')
        self.assertEqual(lua.eval('savedLayouts.layouts[1].systems[1].settings[1].value'), 99)
        self.assertEqual(lua.eval('savedLayouts.layouts[2].layoutName'), 'Luna Classic')
        self.assertEqual(lua.eval('savedLayouts.layouts[2].systems[1].settings[1].value'), 0)
        self.assertEqual(lua.eval('savedLayouts.layouts[2].systems[1].settings[4].value'), 5)
        self.assertEqual(lua.eval('activeLayout'), 2)
        self.assertEqual(lua.eval("DragonflightUIDB.foreverLayouts['fixture-character'].previousLayout"), 'My layout')

    def test_window_browser_uses_secure_click_actions_and_disables_missing_client_features(self):
        lua = self.boot()
        lua.execute("""
            CharacterMicroButton=CreateFrame('Button','CharacterMicroButton',UIParent)
            CharacterMicroButton.scripts.OnClick=function() error('Insecure native click') end
            HousingMicroButton=CreateFrame('Button','HousingMicroButton',UIParent)
            EJMicroButton=CreateFrame('Button','EJMicroButton',UIParent)
            DF=LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF:ToggleWindowBrowser()
        """)
        self.assertTrue(lua.eval('DF.windowBrowser.children[2].secureButton'))
        self.assertEqual(lua.eval("DF.windowBrowser.children[2].attributes.type"), 'click')
        self.assertFalse(lua.eval("DF.windowBrowser.children[2].attributes.useOnKeyDown"))
        self.assertTrue(lua.eval('DF.windowBrowser.children[2].attributes.clickbutton == CharacterMicroButton'))
        self.assertIsNone(lua.eval("DF.windowBrowser.children[2]:GetScript('OnClick')"))
        self.assertTrue(lua.eval('DF.windowBrowser.children[8].disabled'))
        self.assertTrue(lua.eval('DF.windowBrowser.children[12].disabled'))


if __name__ == '__main__':
    unittest.main(verbosity=2)
