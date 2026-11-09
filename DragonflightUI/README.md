# Dragonflight UI Forever - Luna

Dragonflight UI Forever - Luna 1.2.1 is the dedicated WoW: Forever (Camelot) edition
of the independently maintained DragonflightUI_Luna fork of Dragonflight UI Classic.
Its public Forever version starts at 1.0; earlier Forever engineering builds used
the 1.4–1.7 version series. The addon folder remains `DragonflightUI` so texture
paths and saved settings continue to work.

## What DragonflightUI_Luna changes

DragonflightUI_Luna keeps the established `DragonflightUI` addon folder and saved-variable name. Existing Classic profiles and texture references are retained. The original Classic implementation includes:

- compatibility work for current Classic Era clients;
- fixes for protected-frame and legacy API changes;
- restored HUD Edit Mode integration and saved layouts;
- action-bar, unit-frame, party-frame, raid-frame, cast-bar, buff, debuff, minimap, and utility fixes;
- client-specific TOC files for Classic variants; and
- publication, attribution, and third-party notice preparation.

See [CHANGELOG.md](CHANGELOG.md) for the release history.

## WoW Forever (Camelot)

Version 1.2.1 uses a dedicated native Forever runtime under `Forever/`. The bare,
`_Forever`, and `_Camelot` manifests all target interface 16001 and load this same
runtime. The Classic FrameXML replacements and global legacy API aliases are not
loaded by these manifests.

Luna styles native action buttons, native spell flyouts, Dragonflight unit-frame
artwork, health bars and text, aura borders/text, cast bars, mirror timers, and
tooltip scale. Native
clicks, paging, keybindings, buff cancellation, private auras, spell timing,
portraits, group targeting, and value updates continue to run in Blizzard's UI.
Luna forwards native health/power widget output and native labels directly to
rendering APIs that accept opaque values. It does not evaluate or save those
values in Lua. Aura/casting data controllers remain native.

Open `/df` or `/dragonflight`, the **Dragonflight UI Forever - Luna** entry in the Game Menu,
or the corresponding AddOns settings category. The appearance settings are saved
under `DragonflightUIDB.forever`; the existing Classic profiles are retained.
The first activation creates a separate native **Luna Classic** character
layout with three centered action-bar rows, side grids, unit frames, minimap,
bags and micro menu. `/df classic` reapplies that reference layout. It does not
delete the previous layout. `/df windows` opens a catalog of native windows;
secure click actions open the available micro-menu panels, while missing client
features are disabled. Window styling also covers panels loaded later in the
session, including the new profession, spellbook and Legacy panel structures.
The shop uses an isolated Blizzard UI environment and retains its native frame.
Open **Esc > Edit Mode**, `/editmode` or the Edit Mode button in Luna settings for
the **Luna HUD editor**. It hosts Forever's existing layout dropdown, grid,
snapping, advanced options, Save and Revert controls in a Luna window. Selecting
a highlighted system keeps its native layout controls; **Luna settings** opens
that system's appearance page. Native layout storage and unsaved-changes dialogs
are retained, and the controls return to their original parents when the editor
closes or Luna's editor is disabled. Classic replacement aura headers and cast
simulation are not part of the Forever runtime. Native game windows receive Luna frame artwork without changing their
content or panel callbacks. This native UI theme does not provide full feature
parity with the Classic implementation.

## Extra flyouts and update notes

Version 1.2 adds ten Classic-style extra launchers with twelve slots each. Use
`/df flyouts` or the Extra flyouts page in Luna settings. Drag spells, items,
toys, mounts, macros or equipment sets onto a slot. Right-click a launcher to
configure its name, icon, direction, columns, scale, shortcut and closing behavior.
In the editor, right-click a slot to clear it; on the live flyout, use
Alt+right-click. Shift-drag an action to pick it up. Move the launchers in Luna
Edit Mode. Settings are per character; mage and warlock presets use known spells.

The current patchnotes and selectable Discord invite appear once per account
after each Forever update. Automatic display waits until combat and Edit Mode
end. `/df patchnotes`, `/df discord`, Luna settings and the HUD editor reopen the
window manually. Click the Discord field, then press Ctrl+C to copy the invite.

Tests load the real Forever manifest and embedded libraries in Lua 5.1 against
strict native frame fixtures for build 1.60.1.70790. They check startup, settings,
menu pool reuse, editor entry/exit and modal dialogs, combat deferral, restoration,
native artwork updates and native handler preservation.
They do not emulate the WoW taint engine or replace an in-game client check.

## Usage

The addon can be configured through the in-game AddOns settings or with `/dragonflight` and `/df`. For Forever layouts, use the Edit Mode button in Luna settings or Blizzard's Game Menu.

Do not rename the installed `DragonflightUI` directory. The directory name is retained for technical compatibility and does not represent the public project name.

## Origin, License, and Credits

DragonflightUI_Luna is an independently maintained and modified fork of [Dragonflight UI Classic](https://www.curseforge.com/wow/addons/dragonflight-ui-classic), originally created by Karl-HeinzSchneider. DragonflightUI_Luna is not an official continuation of the original project. The probable upstream base is version `v0.40.3`, commit [`b8b35451d4621a8097e887385f72ec03e17765f1`](https://github.com/Karl-HeinzSchneider/WoW-DragonflightUI/commit/b8b35451d4621a8097e887385f72ec03e17765f1).

- Original source: <https://github.com/Karl-HeinzSchneider/WoW-DragonflightUI>
- DragonflightUI_Luna source: <https://github.com/Fatex04/Dragonflight-UI-Classic---Luna>
- Original CurseForge project: <https://www.curseforge.com/wow/addons/dragonflight-ui-classic>
- Original project copyright: `Copyright (c) 2022 Karl-HeinzSchneider`
- DragonflightUI_Luna modification notice: `Copyright (c) 2026 Femboybaddie (modifications for DragonflightUI_Luna only)`
- DragonflightUI_Luna fork maintainer: Femboybaddie

The upstream project code and DragonflightUI_Luna modifications are distributed under the [MIT License](LICENSE). Bundled libraries, documentation, and other third-party components retain their own licenses and notices. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

The included textures are inherited from the upstream package. DragonflightUI_Luna does not claim ownership of Blizzard Entertainment materials, trademarks, or other third-party artwork and does not represent those materials as DragonflightUI_Luna-authored MIT content. See [ASSET_PROVENANCE.md](ASSET_PROVENANCE.md) and [ASSET_MANIFEST.sha256](ASSET_MANIFEST.sha256).

Verified contribution and attribution information is recorded in [CONTRIBUTORS.md](CONTRIBUTORS.md).

## Support and source links

Bug reports and compatibility feedback may be submitted through the DragonflightUI_Luna community Discord:

<https://discord.gg/ZfYDHV6Qgs>

The original source repository remains linked above for attribution and upstream history. DragonflightUI_Luna does not contain an in-game donation request.

## Important disclaimer

DragonflightUI_Luna is an unofficial, fan-made World of Warcraft addon. It is not affiliated with, endorsed by, sponsored by, or published by Blizzard Entertainment.

World of Warcraft, Warcraft, Blizzard Entertainment, and related names and marks are property of their respective owners. Their inclusion in compatibility descriptions does not imply endorsement or a license of their trademarks or game assets under the MIT License.

This repository documentation is a compliance-oriented record and is not legal advice or a guarantee of legal clearance.
