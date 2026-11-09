"""Flyout secure snippets and once-per-version update UI, in isolated Lua 5.1 fixtures."""
import unittest
import forever_native as native


PLAYER = r'''
UnitGUID=function() return 'Player-Fixture' end
UnitName=function() return 'Luna' end
UnitClass=function() return 'Rogue','ROGUE' end
UnitFactionGroup=function() return 'Alliance' end
GetRealmName=function() return 'Fixture' end
Enum={SpellBookSpellBank={Player=0,Pet=1}}
knownSpells={}
C_SpellBook={IsSpellKnown=function(id) return knownSpells[id] or false end,
    GetSpellBookItemInfo=function(index,bank) return {spellID=1000+index} end}
nativeDuration={privateValues=opaque('private cooldown')}
C_Spell={GetSpellInfo=function(id) return {name='Spell '..id,iconID=100+id} end,
    GetSpellDisplayCount=function() return '' end,
    GetSpellCooldownDuration=function() return nativeDuration end,
    PickupSpell=function(id) pickedUp={type='spell',value=id} end}
C_Item={GetItemInfo=function(id) return 'Item '..id,nil,nil,nil,nil,nil,nil,nil,nil,200+id end,
    GetItemCount=function() return 3 end,
    GetItemCooldown=function() return 0,0 end,
    PickupItem=function(id) pickedUp={type='item',value=id} end}
C_ToyBox={PlayerHasToy=function(id) return id==123 end,
    PickupToyBoxItem=function(id) pickedUp={type='toy',value=id} end}
GetMacroInfo=function(value) return value=='Missing' and nil or 'TestMacro',234,'/wave' end
PickupMacro=function(value) pickedUp={type='macro',value=value} end
C_EquipmentSet={GetEquipmentSetID=function() return 7 end,
    GetEquipmentSetInfo=function() return 'Travel',345 end,
    PickupEquipmentSet=function(value) pickedUp={type='equipmentset',value=value} end}
C_MountJournal={GetMountInfoByID=function() return 'Mount',458,456 end}
GetCursorInfo=function() return unpack(cursor or {}) end
ClearCursor=function()
    cursor=nil
    local root=DragonflightUIForeverFlyouts
    if root then root:SetAttribute('state-cursor','false') end
end
IsShiftKeyDown=function() return true end
IsAltKeyDown=function() return false end
function cursorAction(...)
    cursor={...}
    DragonflightUIForeverFlyouts:SetAttribute('state-cursor','true')
end
function enterCombat(value)
    combat=value
    SECURE_EXECUTION=true
    for frame,drivers in pairs(stateDrivers) do
        if drivers.combat then frame:SetAttribute('state-combat',value and 'true' or 'false') end
    end
    SECURE_EXECUTION=false
    dispatch(value and 'PLAYER_REGEN_DISABLED' or 'PLAYER_REGEN_ENABLED')
end
'''


class Flyouts(unittest.TestCase):
    def boot(self, before='', saved=''):
        lua=native.NativeRuntime().boot(before=PLAYER+before,saved_variables=saved)
        lua.execute("DF=LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); launcher=DF.flyoutButtons[1]")
        return lua

    def test_ten_launchers_and_twelve_slots_leave_native_actions_intact(self):
        lua=self.boot()
        self.assertEqual(lua.eval('#DF.flyoutButtons'),10)
        self.assertEqual(lua.eval('#launcher.slots'),12)
        self.assertTrue(lua.eval('launcher.secureHandler'))
        self.assertTrue(lua.eval('launcher.slots[1]:GetScript("OnClick")==launcher.slots[1].nativeSecureClick'))
        self.assertEqual(lua.eval('MainActionBar.actionButtons[1]:GetScript("OnClick")()'),'native-click')

    def test_launcher_toggle_closes_other_popups_and_registers_mouse_autohide(self):
        lua=self.boot()
        lua.execute("launcher:Click('LeftButton')")
        self.assertTrue(lua.eval('launcher.popup:IsShown()'))
        self.assertEqual(lua.eval('launcher.popup.autoHide'),0.5)
        self.assertTrue(lua.eval('launcher.popup.autoHideParent==launcher'))
        lua.execute("DF.flyoutButtons[2]:Click('LeftButton')")
        self.assertFalse(lua.eval('launcher.popup:IsShown()'))
        self.assertTrue(lua.eval('DF.flyoutButtons[2].popup:IsShown()'))
        lua.execute("DF.flyoutButtons[2]:Click('LeftButton')")
        self.assertFalse(lua.eval('DF.flyoutButtons[2].popup:IsShown()'))

    def test_combined_backdrop_popup_has_no_secure_onload_helpers(self):
        lua=self.boot()
        self.assertIsNone(lua.eval('launcher.popup.SetFrameRef'))
        self.assertIsNone(lua.eval('launcher.popup.WrapScript'))
        self.assertTrue(lua.eval('DF.flyoutFramesReady'))
        self.assertTrue(lua.eval('launcher.popup.refs.controller==DF.flyoutRoot'))
        self.assertTrue(lua.eval('launcher.slots[1].secureWrappers.OnClick.owner==launcher.popup'))
        self.assertTrue(lua.eval('DF:CreateFlyoutFrames()'))

    def test_failed_popup_initialization_stays_hidden_and_does_not_cascade(self):
        lua=native.NativeRuntime().load_runtime(before=PLAYER+"""
            originalFrameRef=SecureHandlerSetFrameRef
            SecureHandlerSetFrameRef=function(frame,label,reference)
                if frame:GetName()=='DragonflightUIForeverFlyout1Popup' then error('Injected popup initialization failure') end
                return originalFrameRef(frame,label,reference)
            end
        """)
        lua.execute("""
            startupOK,startupError=pcall(function()
                dispatch('ADDON_LOADED','DragonflightUI'); loggedIn=true; dispatch('PLAYER_LOGIN'); flushTimers()
            end)
            DF=LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
            SecureHandlerSetFrameRef=originalFrameRef
        """)
        self.assertFalse(lua.eval('startupOK'))
        self.assertIn('Injected popup initialization failure',lua.eval('startupError'))
        self.assertFalse(lua.eval('DF.flyoutFramesReady'))
        self.assertIsNone(lua.eval('DF.flyoutButtons[1].popup'))
        self.assertIsNone(lua.eval('DF.flyoutButtons[1].mover'))
        self.assertFalse(lua.eval('DF.flyoutRoot:IsShown()'))
        lua.execute("""
            DF:RefreshFlyoutDisplays(); DF:RefreshFlyoutMovers(); DF:RefreshFlyouts()
            DF:OpenLunaEditMode(); HideUIPanel(EditModeManagerFrame); flushTimers()
            DF.settings.flyouts=false; DF:RefreshFlyouts(); DF:OnDisable(); flushTimers()
        """)
        self.assertFalse(lua.eval('DF.moduleStatus.Flyouts.setupCompleted'))
        self.assertFalse(lua.eval('DF.flyoutRoot:IsShown()'))
        self.assertEqual(lua.eval('#reportedErrors'),0)

    def test_secure_spell_click_works_in_combat_and_preserves_original_handler(self):
        lua=self.boot()
        lua.execute("DF:SetFlyoutAction(1,1,{type='spell',value=1752}); enterCombat(true); launcher:Click('LeftButton'); launcher.slots[1]:Click('LeftButton')")
        self.assertEqual(lua.eval('secureActions[1][1]'),'spell')
        self.assertEqual(lua.eval('secureActions[1][2]'),1752)
        self.assertFalse(lua.eval('launcher.popup:IsShown()'))
        self.assertFalse(lua.eval("launcher.slots[1]:GetAttribute('useOnKeyDown')"))
        self.assertTrue(lua.eval('launcher.slots[1]:GetScript("OnClick")==launcher.slots[1].nativeSecureClick'))

    def test_close_after_use_can_be_disabled(self):
        lua=self.boot()
        lua.execute("DF.flyoutData.bars[1].closeAfterClick=false; DF:SetFlyoutAction(1,1,{type='item',value=6948}); launcher:Click('LeftButton'); launcher.slots[1]:Click('LeftButton')")
        self.assertTrue(lua.eval('launcher.popup:IsShown()'))
        self.assertEqual(lua.eval('secureActions[1][2]'),'item:6948')

    def test_drag_drop_supports_spells_items_toys_macros_sets_and_mounts(self):
        cases=[("'spell',4,'spell',1752",'spell',1752), ("'spell',9,'spell'",'spell',1009),
               ("'item',6948",'item',6948), ("'item',123",'toy',123),
               ("'macro',3",'macro','TestMacro'), ("'equipmentset','Travel'",'equipmentset',7),
               ("'companion',1",'spell',458)]
        for cursor,kind,value in cases:
            with self.subTest(cursor=cursor):
                lua=self.boot()
                lua.execute(f'cursorAction({cursor}); assert(DF:ReceiveFlyoutAction(1,1))')
                self.assertEqual(lua.eval('DF.flyoutData.bars[1].entries[1].type'),kind)
                self.assertEqual(lua.eval('DF.flyoutData.bars[1].entries[1].value'),value)
                self.assertIsNone(lua.eval('cursor'))

    def test_cursor_click_assigns_without_casting_and_combat_cursor_does_nothing(self):
        lua=self.boot()
        lua.execute("DF:SetFlyoutAction(1,1,{type='spell',value=1752}); cursorAction('item',6948); launcher.slots[1]:Click('LeftButton')")
        self.assertEqual(lua.eval('#secureActions'),0)
        self.assertEqual(lua.eval('DF.flyoutData.bars[1].entries[1].value'),6948)
        lua.execute("cursorAction('spell',1,'spell',1766); enterCombat(true); launcher.slots[1]:Click('LeftButton')")
        self.assertEqual(lua.eval('#secureActions'),0)
        self.assertEqual(lua.eval('DF.flyoutData.bars[1].entries[1].value'),6948)
        self.assertIsNotNone(lua.eval('cursor'))

    def test_replacing_an_action_clears_all_old_secure_attributes(self):
        lua=self.boot()
        lua.execute("DF:SetFlyoutAction(1,1,{type='spell',value=1752}); DF:SetFlyoutAction(1,1,{type='macro',value='TestMacro'})")
        self.assertIsNone(lua.eval("launcher.slots[1]:GetAttribute('spell')"))
        self.assertEqual(lua.eval("launcher.slots[1]:GetAttribute('macro')"),'TestMacro')
        lua.execute('DF:SetFlyoutAction(1,1,nil)')
        self.assertIsNone(lua.eval("launcher.slots[1]:GetAttribute('type1')"))

    def test_layout_and_binding_changes_defer_in_combat(self):
        lua=self.boot()
        lua.execute("originalX=launcher.points[1][4]; enterCombat(true); DF.flyoutData.bars[1].x=170; DF.flyoutData.bars[1].binding='CTRL-F'; DF:RefreshFlyouts()")
        self.assertTrue(lua.eval('DF.pendingFlyouts'))
        self.assertTrue(lua.eval('launcher.points[1][4]==originalX'))
        lua.execute('enterCombat(false); flushTimers()')
        self.assertEqual(lua.eval('launcher.points[1][4]'),170)
        self.assertEqual(lua.eval("overrideBindings[DF.flyoutRoot]['CTRL-F'][1]"),'DragonflightUIForeverFlyout1')

    def test_spell_presets_update_until_the_player_customizes_them(self):
        lua=self.boot("UnitClass=function() return 'Mage','MAGE' end; knownSpells[3561]=true; knownSpells[5504]=true")
        self.assertEqual(lua.eval('DF.flyoutData.bars[1].entries[1].value'),3561)
        self.assertEqual(lua.eval('DF.flyoutData.bars[3].entries[1].value'),5504)
        lua.execute("DF:SetFlyoutAction(1,2,{type='item',value=6948}); knownSpells[3562]=true; knownSpells[5505]=true; dispatch('SPELLS_CHANGED'); flushTimers()")
        self.assertIsNone(lua.eval('DF.flyoutData.bars[1].preset'))
        self.assertEqual(lua.eval('DF.flyoutData.bars[1].entries[2].value'),6948)
        self.assertEqual(lua.eval('DF.flyoutData.bars[3].entries[2].value'),5505)

    def test_saved_character_actions_and_classic_profiles_are_preserved(self):
        lua=self.boot(saved="""DragonflightUIDB={profiles={OldClassic={important=42}},foreverFlyouts={
            ['Player-Fixture']={bars={{name='My items',entries={{type='item',value=6948}}}}},
            ['Another-player']={keep=99}}}""")
        self.assertEqual(lua.eval('DF.flyoutData.bars[1].name'),'My items')
        self.assertEqual(lua.eval('DF.flyoutData.bars[1].entries[1].value'),6948)
        self.assertEqual(lua.eval('DragonflightUIDB.profiles.OldClassic.important'),42)
        self.assertEqual(lua.eval("DragonflightUIDB.foreverFlyouts['Another-player'].keep"),99)

    def test_edit_mode_movers_save_and_disappear_on_combat(self):
        lua=self.boot()
        lua.execute("DF:OpenLunaEditMode(); launcher:ClearAllPoints(); launcher:SetPoint('CENTER',UIParent,'CENTER',91,87); launcher.mover.scripts.OnDragStop();")
        self.assertTrue(lua.eval('launcher.mover:IsShown()'))
        self.assertEqual(lua.eval('DF.flyoutData.bars[1].x'),91)
        lua.execute('enterCombat(true)')
        self.assertFalse(lua.eval('launcher.mover:IsShown()'))
        lua.execute("enterCombat(false); HideUIPanel(EditModeManagerFrame); flushTimers()")
        self.assertFalse(lua.eval('launcher.mover:IsShown()'))

    def test_editor_saves_settings_and_accesses_all_ten_flyouts(self):
        lua=self.boot()
        lua.execute("DF:HandleCommand('flyouts 3'); editor=DF.flyoutEditor; editor.name:SetText('Potions'); editor.scale:SetValue(1.1); editor.columns:SetText('3'); editor.binding:SetText('CTRL-P'); DF:SaveFlyoutEditor()")
        self.assertEqual(lua.eval('DF.flyoutData.bars[3].name'),'Potions')
        self.assertEqual(lua.eval('DF.flyoutData.bars[3].columns'),3)
        self.assertEqual(lua.eval('DF.flyoutButtons[3].scale'),1.1)
        lua.execute("editor.name:SetText('Still potions'); editor.directions.RIGHT:Click('LeftButton'); DF.flyoutButtons[10].mover.scripts.OnMouseDown(DF.flyoutButtons[10].mover,'LeftButton')")
        self.assertEqual(lua.eval('DF.flyoutData.bars[3].name'),'Still potions')
        self.assertEqual(lua.eval('DF.flyoutData.bars[3].direction'),'RIGHT')
        self.assertEqual(lua.eval('editor.index'),10)

    def test_private_cooldown_objects_and_counts_are_not_evaluated(self):
        lua=self.boot()
        lua.execute("C_Spell.GetSpellDisplayCount=function() return opaque('count') end; DF:SetFlyoutAction(1,1,{type='spell',value=1752}); launcher:Click('LeftButton'); enterCombat(true); dispatch('SPELL_UPDATE_COOLDOWN'); flushTimers()")
        self.assertTrue(lua.eval('launcher.slots[1].cooldown.durationObject==nativeDuration'))
        self.assertEqual(lua.eval('launcher.slots[1].Count.text.label'),'count')
        self.assertEqual(lua.eval('#reportedErrors'),0)

    def test_disabled_flyouts_hide_and_clear_only_their_own_bindings(self):
        lua=self.boot()
        lua.execute("DF.flyoutData.bars[1].binding='CTRL-F'; DF:RefreshFlyouts(); DF.settings.flyouts=false; DF:RefreshFlyouts()")
        self.assertFalse(lua.eval('DF.flyoutRoot:IsShown()'))
        self.assertEqual(lua.eval('next(overrideBindings[DF.flyoutRoot])'),None)

    def test_opening_a_popup_refreshes_counts_that_changed_while_hidden(self):
        lua=self.boot()
        lua.execute("DF:SetFlyoutAction(1,1,{type='item',value=6948}); C_Item.GetItemCount=function() return 44 end; launcher:Click('LeftButton')")
        self.assertEqual(lua.eval('launcher.slots[1].Count.text'),44)

    def test_item_cache_events_coalesce_without_rebuilding_or_resetting_editor_fields(self):
        lua=self.boot()
        lua.execute("""
            DF:SetFlyoutAction(1,1,{type='item',value=6948}); DF:HandleCommand('flyouts 1')
            DF.flyoutEditor.name:SetText('Unsaved name'); DF.flyoutEditor.action:SetText('macro:Unsaved')
            C_Item.GetItemInfo=function() return 'Loaded item',nil,nil,nil,nil,nil,nil,nil,nil,777 end
            rebuilt=0; originalRefresh=DF.RefreshFlyouts
            DF.RefreshFlyouts=function(self) rebuilt=rebuilt+1; originalRefresh(self) end
            for i=1,10 do dispatch('GET_ITEM_INFO_RECEIVED') end
            flushTimers()
        """)
        self.assertEqual(lua.eval('rebuilt'),0)
        self.assertEqual(lua.eval('DF.flyoutEditor.name:GetText()'),'Unsaved name')
        self.assertEqual(lua.eval('DF.flyoutEditor.action:GetText()'),'macro:Unsaved')
        self.assertEqual(lua.eval('DF.flyoutEditor.selectedAction.text'),'Slot 1 · Loaded item')

    def test_edit_mode_click_selects_flyout_with_contextual_settings_only(self):
        lua=self.boot()
        self.assertIsNone(lua.eval('DF.flyoutEditor'))
        lua.execute('GameMenuFrame:InitButtons(); GameMenuFrame.buttons[2].callback()')
        self.assertTrue(lua.eval('DF.editModeSession~=nil'))
        self.assertTrue(lua.eval('DF.flyoutButtons[10].mover:IsShown()'))
        self.assertTrue(lua.eval('DF.flyoutButtons[10]:IsShown()'))
        lua.execute("DF.flyoutButtons[10].mover.scripts.OnMouseDown(DF.flyoutButtons[10].mover,'LeftButton')")
        self.assertEqual(lua.eval('DF.selectedFlyout'),10)
        self.assertEqual(lua.eval('DF.flyoutEditor.index'),10)
        self.assertTrue(lua.eval('DF.flyoutEditor:GetParent()==DF.editModeFrame'))
        self.assertTrue(lua.eval('DF.flyoutEditor:IsShown()'))
        self.assertIsNone(lua.eval('DragonflightUIForeverFlyoutEditor'))
        self.assertFalse(lua.eval('DF.flyoutEditor.enabled:GetChecked()'))
        lua.execute('DF.flyoutEditor.enabled:SetChecked(true); DF.flyoutEditor.enabled.scripts.OnClick()')
        self.assertTrue(lua.eval('DF.flyoutData.bars[10].enabled'))

    def test_selecting_a_native_system_closes_the_flyout_settings(self):
        lua=self.boot()
        lua.execute("DF:HandleCommand('flyouts 2'); DF.flyoutEditor.name:SetText('Saved on selection'); EditModeManagerFrame:SelectSystem(PlayerFrame)")
        self.assertFalse(lua.eval('DF.flyoutEditor:IsShown()'))
        self.assertIsNone(lua.eval('DF.selectedFlyout'))
        self.assertTrue(lua.eval('DF.editSelectedSystem==PlayerFrame'))
        self.assertEqual(lua.eval('DF.flyoutData.bars[2].name'),'Saved on selection')
        lua.execute("DF.flyoutButtons[3].mover.scripts.OnMouseDown(DF.flyoutButtons[3].mover,'LeftButton')")
        self.assertEqual(lua.eval('DF.selectedFlyout'),3)
        self.assertIsNone(lua.eval('EditModeManagerFrame.nativeSelectedSystem'))
        lua.execute('EditModeManagerFrame:ClearSelectedSystem()')
        self.assertFalse(lua.eval('DF.flyoutEditor:IsShown()'))

    def test_position_size_changes_and_exit_apply_without_a_separate_menu(self):
        lua=self.boot()
        lua.execute("DF:HandleCommand('flyouts 4'); editor=DF.flyoutEditor; editor.x:SetText('123'); editor.y:SetText('321'); editor.scale:SetValue(1.25); DF:SaveFlyoutEditor()")
        self.assertEqual(lua.eval('DF.flyoutData.bars[4].x'),123)
        self.assertEqual(lua.eval('DF.flyoutData.bars[4].y'),321)
        self.assertEqual(lua.eval('DF.flyoutButtons[4].scale'),1.25)
        lua.execute('HideUIPanel(EditModeManagerFrame); flushTimers()')
        self.assertFalse(lua.eval('editor:IsShown()'))
        self.assertIsNone(lua.eval('DF.selectedFlyout'))
        self.assertFalse(lua.eval('DF.flyoutButtons[10]:IsShown()'))
        self.assertFalse(lua.eval('DF.flyoutButtons[4].mover:IsShown()'))

    def test_combat_closes_selected_flyout_settings_without_changing_secure_geometry(self):
        lua=self.boot()
        lua.execute("DF:HandleCommand('flyouts 1'); enterCombat(true)")
        self.assertFalse(lua.eval('DF.flyoutEditor:IsShown()'))
        self.assertIsNone(lua.eval('DF.selectedFlyout'))
        self.assertEqual(lua.eval('#reportedErrors'),0)

    def test_disabling_flyouts_closes_contextual_settings_and_highlights(self):
        lua=self.boot()
        lua.execute("DF:HandleCommand('flyouts 1'); DF.settings.flyouts=false; DF:RefreshFlyouts()")
        self.assertFalse(lua.eval('DF.flyoutEditor:IsShown()'))
        self.assertIsNone(lua.eval('DF.selectedFlyout'))
        self.assertFalse(lua.eval('launcher.mover:IsShown()'))

    def test_disabling_in_combat_finishes_cleanup_after_regen(self):
        lua=self.boot()
        lua.execute('enterCombat(true); DF:OnDisable()')
        self.assertTrue(lua.eval('DF.pendingFlyouts'))
        lua.execute('enterCombat(false); flushTimers()')
        self.assertFalse(lua.eval('DF.flyoutRoot:IsShown()'))
        self.assertFalse(lua.eval('DF.pendingThemeDisable'))
        self.assertEqual(lua.eval('MainActionBar.BorderArt.alpha'),0.8)


class UpdateNotice(unittest.TestCase):
    def boot(self,before='',saved=''):
        return native.NativeRuntime().boot(before=before,saved_variables=saved)

    def test_first_login_shows_notes_once_per_forever_version(self):
        lua=self.boot()
        self.assertTrue(lua.eval('DragonflightUIForeverChangelog:IsShown()'))
        self.assertEqual(lua.eval('DragonflightUIDB.global.lastForeverUpdateNoticeVersion'),'1.2.2')
        lua.execute("DF=LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF.updateNotice:Hide(); dispatch('PLAYER_ENTERING_WORLD'); DF:QueueUpdateNotice(); flushTimers()")
        self.assertFalse(lua.eval('DF.updateNotice:IsShown()'))

    def test_reload_profile_and_character_changes_do_not_repeat_seen_notes(self):
        lua=self.boot(saved="DragonflightUIDB={global={lastForeverUpdateNoticeVersion='1.2.2'},profiles={Another={}}}")
        self.assertIsNone(lua.eval('DragonflightUIForeverChangelog'))

    def test_new_version_ignores_classic_notice_marker(self):
        lua=self.boot(saved="DragonflightUIDB={global={lastForeverUpdateNoticeVersion='1.2',lastUpdateNoticeVersion='1.3.2'}}")
        self.assertTrue(lua.eval('DragonflightUIForeverChangelog:IsShown()'))
        self.assertEqual(lua.eval('DragonflightUIDB.global.lastUpdateNoticeVersion'),'1.3.2')

    def test_combat_defers_without_marking_the_notice_seen(self):
        lua=self.boot('combat=true')
        self.assertIsNone(lua.eval('DragonflightUIDB.global.lastForeverUpdateNoticeVersion'))
        self.assertIsNone(lua.eval('DragonflightUIForeverChangelog'))
        lua.execute("combat=false; dispatch('PLAYER_REGEN_ENABLED'); flushTimers()")
        self.assertTrue(lua.eval('DragonflightUIForeverChangelog:IsShown()'))

    def test_manual_reopen_and_discord_link_remain_selectable(self):
        lua=self.boot(saved="DragonflightUIDB={global={lastForeverUpdateNoticeVersion='1.2.2'}}")
        lua.execute("DF=LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF:HandleCommand('discord'); link=DF.updateNotice.DiscordLink; link:SetFocus()")
        self.assertEqual(lua.eval('link:GetText()'),'https://discord.gg/ZfYDHV6Qgs')
        self.assertTrue(lua.eval('link.highlighted'))
        lua.execute("link.text='modified'; link.scripts.OnTextChanged(link,true); DF.updateNotice:Hide()")
        self.assertEqual(lua.eval('link:GetText()'),'https://discord.gg/ZfYDHV6Qgs')
        self.assertFalse(lua.eval('link.focused'))

    def test_native_edit_mode_defers_and_shows_after_exit(self):
        lua=self.boot("EditModeManagerFrame.editModeActive=true")
        self.assertIsNone(lua.eval('DragonflightUIForeverChangelog'))
        lua.execute("EditModeManagerFrame.editModeActive=false; EventRegistry:TriggerEvent('EditMode.Exit'); flushTimers()")
        self.assertTrue(lua.eval('DragonflightUIForeverChangelog:IsShown()'))

    def test_patchnotes_can_be_opened_manually_inside_edit_mode(self):
        lua=self.boot(saved="DragonflightUIDB={global={lastForeverUpdateNoticeVersion='1.2.2'}}")
        lua.execute("DF=LibStub('AceAddon-3.0'):GetAddon('DragonflightUI'); DF:OpenLunaEditMode(); DF:ShowUpdateNotice(true)")
        self.assertTrue(lua.eval('DF.updateNotice:IsShown()'))
        self.assertTrue(lua.eval('EditModeManagerFrame:IsEditModeActive()'))


if __name__=='__main__':
    unittest.main(verbosity=2)
