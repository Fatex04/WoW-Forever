"""Run with Python + lupa (Lua 5.1). No WoW installation is needed.

Loads the real Forever TOC, embedded Ace libraries, and the whole native runtime.
The fixture rejects legacy templates, secure gameplay mutations and value reads.
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
        self.assertEqual(lua.eval('DragonflightUIDB.global.foreverDiagnostics.version'), '1.5.0')
        self.assertTrue(lua.eval('DragonflightUIDB.global.foreverDiagnostics.modules.Actionbar.setupCompleted'))
        self.assertIsNone(lua.eval('MainMenuBarLeftEndCap'))
        self.assertIsNone(lua.eval('MirrorTimer1'))
        self.assertEqual(lua.eval('PlayerFrame:GetScript("OnClick")()'), 'native-target')
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1]:GetScript("OnClick")()'), 'native-click')
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].secureAction'), 'native-action')
        self.assertTrue(lua.eval('BuffFrame.events.UNIT_AURA'))
        self.assertTrue(lua.eval('BuffFrame.auraFrames[1].nativeCancelBuff'))
        self.assertEqual(lua.eval('PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar.fill.masks[1]'), 'native-mask')
        self.assertTrue(lua.eval('PlayerFrame.PlayerFrameContainer.FrameTexture.desaturated'))
        self.assertEqual(lua.eval('MainActionBar.BorderArt.alpha'), 0)
        self.assertTrue(lua.eval('MainActionBar.actionButtons[1].DFLunaForeverEdge.shown'))
        self.assertTrue(lua.eval('BuffFrame.auraFrames[1].DFLunaForeverEdge.shown'))
        self.assertEqual(lua.eval('PlayerCastingBarFrame.fill.atlas'), 'native-atlas')
        self.assertEqual(lua.eval('PlayerCastingBarFrame.fill.writes'), 0)

    def test_disabled_theme_restores_native_art_fonts_and_alpha(self):
        lua = self.boot()
        lua.execute("DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF.settings.enabled = false; DF:QueueRefresh(); flushTimers()")
        self.assertEqual(lua.eval('MainActionBar.BorderArt.alpha'), 0.8)
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1].normal.alpha'), 0.8)
        self.assertFalse(lua.eval('MainActionBar.actionButtons[1].DFLunaForeverEdge.shown'))
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
        self.assertTrue(lua.eval('SpellFlyout.children[2].DFLunaForeverEdge.shown'))
        self.assertEqual(lua.eval('SpellFlyout.children[2]:GetScript("OnClick")()'), 'native-click')

    def test_native_edit_mode_opens_without_rewriting_layouts(self):
        lua = self.boot()
        lua.execute("DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF:ToggleOptions(); DF:OpenNativeEditMode()")
        self.assertTrue(lua.eval('EditModeManagerFrame:IsShown()'))
        self.assertFalse(lua.eval('DF.options:IsShown()'))
        lua.execute("MainActionBar.BorderArt.alpha = 1; EventRegistry:TriggerEvent('EditMode.Exit'); flushTimers()")
        self.assertEqual(lua.eval('MainActionBar.BorderArt.alpha'), 0)

    def test_menu_pool_has_one_luna_entry_after_each_reset(self):
        lua = self.boot()
        for _ in range(3):
            lua.execute('GameMenuFrame:InitButtons()')
            self.assertEqual(lua.eval('#GameMenuFrame.buttons'), 5)
            self.assertEqual(lua.eval('GameMenuFrame.closeButton.layoutIndex'), 5)
            self.assertEqual(lua.eval('GameMenuFrame.buttons[1].callback()'), 'native-options')
            self.assertEqual(lua.eval('GameMenuFrame.buttons[2].callback()'), 'native-edit')
            self.assertEqual(lua.eval('GameMenuFrame.buttons[4].text'), 'Dragonflight UI Luna')
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
            self.assertEqual(lua.eval('GameMenuFrame.buttons[4].text'), 'Dragonflight UI Luna')
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
        self.assertTrue(lua.eval('MainActionBar.actionButtons[2].DFLunaForeverEdge.shown'))

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
                      'Unitframe/UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health.tga',
                      'Unitframe/UI-HUD-UnitFrame-Target-PortraitOn-Bar-Health.tga'):
            self.assertTrue((ROOT / 'Textures' / asset).is_file(), asset)


if __name__ == '__main__':
    unittest.main(verbosity=2)
