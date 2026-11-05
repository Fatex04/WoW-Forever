# DragonflightUI_Luna Changelog

## DragonflightUI_Luna V1.4.3 - 5 November 2026 (WoW: Forever)

- Made the bare DragonflightUI.toc a Forever manifest instead of leaving it marked for Classic clients.
- Added DragonflightUI_Forever.toc alongside the Camelot manifest; all three load the same Forever files and Interface 16001.
- Set an explicit enabled default and a clear "Dragonflight UI Luna - WoW Forever" title for the AddOns list.

## DragonflightUI_Luna V1.4.2 - 5 November 2026 (WoW: Forever)

- Routed Forever through the Era content initialization methods for action bars, unit frames, minimap, cast bars, and other DragonflightUI modules.
- Kept Forever marked as a modern API client so its spell, aura, settings, and other API compatibility paths remain modern.

## DragonflightUI_Luna V1.4.1 - 5 November 2026 (WoW: Forever)

- Added a Camelot-specific UI XML file that reuses Blizzard's existing currency border template instead of redefining the global template.
- Prevented the duplicate deferred XML node warning recorded by the Forever client during DragonflightUI loading.

## DragonflightUI_Luna V1.4.0 - 5 November 2026 (WoW: Forever)

- Added a dedicated `DragonflightUI_Camelot.toc` targeting interface 16001.
- Added guarded compatibility adapters for modern spell, aura, spellbook, quest-log, add-on metadata, and settings APIs used by the Classic UI code.
- Added explicit Forever detection and guarded the optional Classic Seasons API.
- Kept the Vanilla-era layout path while marking Forever as a modern API client.
- Disabled the embedded Classic aura-duration rewrite for Forever and use Blizzard's native duration handling.
- Updated LibRangeCheck's flavor detection so the Camelot client follows its modern API path.
- Let the bundled LibQuestXP load its Classic Era XP reference data for Camelot's Vanilla-era quests.

## DragonflightUI_Luna V1.3.1 - 15 September 2026

- Fixed player and target frame position and scale resets after native layout changes, loading screens and frame visibility changes.
- Added combat-safe anchor recovery without changing native unit-frame or possess-bar visibility.
- Fixed the possess bar being stuck in the upper-left corner by connecting the current Blizzard bar to a dedicated movable Luna Edit Mode anchor; preserved saved positions and added custom-anchor support.
- Prevented the reputation bar from flashing green at its temporary center position before the saved layout is applied.
- Updated addon metadata to 1.3.1 and Classic Era compatibility metadata to Interface 11509 for the installed WoW 1.15.9 client.
- Updated the in-game changelog and added simulated regression checks for frame anchoring, possess-bar movement, combat recovery and reputation-bar initialization.
- Changed the changelog popup to display only the current update's release notes; previous versions remain available in CHANGELOG.md.
- Made the changelog window smaller with a translucent background and added a selectable Discord invite link with copy instructions for bug reports.
- Added the Discord logo beside the invite link, darkened the translucent changelog background, and replaced the whisper instructions with a Discord-only bug and feedback invitation.
- Restored the existing project copyright notices in the packaged LICENSE file.


## DragonflightUI_Luna V1.3 - 11 September 2026

- Added a dismissible first-login update window with the Luna logo and Dragonflight UI Luna title; shown once per account per addon version, with combat-safe deferral.
- Restored Action Bar 1 click access by disabling mouse input on empty Blizzard bar backgrounds.
- Prevented duplicate Blizzard selection overlays for Luna-managed action bars, bags, stance, pet, possess and flight-path stop controls; kept these overlays non-interactive outside Edit Mode.
- Fixed bag-bar snapping after login, loading screens and native layout callbacks, including cached callbacks; restored bag scale and keyring orientation and deferred combat-time repairs.
- Kept chat position and size persistent through late native layout resets, login and loading screens; saved explicit moves and resizes without treating automatic resets as user changes, and preserved layouts whose coordinates match AceDB defaults.
- Prevented stale deferred Edit Mode callbacks from reopening or hiding frames after rapid mode changes or loading-screen cleanup.
- Deferred protected mover cleanup and flight-path button layout changes until combat ends, fixing the logged StopMovingOrSizing error.
- Preserved native flight-path stop button events and visibility, restored its Luna anchor after native layout changes, and avoided displaying a second preview beside the real button.
- Fixed the logged alternate mana-bar initialization error by detecting modern and legacy status-bar APIs and removing duplicate initialization.
- Updated addon metadata and the in-game changelog to V1.3; synchronized the installed package with the repository copyright notice.
- Added Lua 5.1 syntax checks and simulated regression coverage for layout persistence, input overlays, combat deferral, Edit Mode transitions and status-bar API compatibility.

## DragonflightUI_Luna V1.1 - 28 July 2026

### Combat and group safety

- Removed insecure refreshes of Blizzard's protected pooled party and raid frames.
- Fixed party members becoming untargetable after a member leaves.
- Deferred secure action-bar, bag, unit-frame, and state-driver layout work until combat ends.
- Split the full action-bar refresh across frames to prevent `script ran too long` failures.

### Saved layout and visual stability

- Added persistent chat position and size storage across `/reload` and loading screens.
- Automatically captures chat moves made through Blizzard's chat controls or Edit Mode instead of reloading an older saved point.
- Made the DragonflightUI mover the sole scale owner for player and pet frames.
- Prevented Blizzard's original cast bars from reappearing beside DragonflightUI cast bars.
- Reparented the primary action buttons to their DragonflightUI mover so combat cannot pull them back to Blizzard's layout.

### HUD Edit Mode

- Re-enabled missing action-bar, stance, pet, possess, bag, micro-menu, XP, and reputation selections for affected V1.0 profiles.
- Added stronger white selection fills while keeping the normal Edit Mode world brightness.
- Added a dedicated darker background only to the opened changelog panel for readability.
- Fixed an Edit Mode startup error when its frame or grid was not ready.
- Deferred per-system Edit Mode refreshes to avoid combat taint and startup stalls.
- Added the complete V1.1 release notes to the in-game changelog window.

### Additional fixes

- Added safe fallbacks for missing saved action-range colors.
- Fixed invalid minimap ping units and a minimap-button registration typo.
- Prepared the public source repository with the preserved MIT license, contributor attribution, and separate third-party notices.

## DragonflightUI_Luna V1.0 - 24 July 2026

### Fork origin

- Prepared DragonflightUI_Luna as an independently maintained fork of Dragonflight UI Classic.
- Recorded the probable upstream base as Dragonflight UI Classic `v0.40.3`, commit `b8b35451d4621a8097e887385f72ec03e17765f1`.
- Preserved the original MIT notice, `Copyright (c) 2022 Karl-HeinzSchneider`.
- Added `Copyright (c) 2026 Femboybaddie (modifications for DragonflightUI_Luna only)`.
- No ownership is claimed over unchanged upstream code, bundled third-party libraries, Blizzard materials, or other inherited third-party content.

### Classic Era compatibility

- Updated compatibility paths for current World of Warcraft Classic Era clients.
- Repaired obsolete API usage and protected-frame handling affected by client changes.
- Restored missing artwork references, icons, sharp text rendering, and pixel-aligned UI elements.

### HUD Edit Mode

- Added the transparent Luna project logo as a non-interactive image in the upper-left corner while Edit Mode is active.
- Integrated relevant DragonflightUI systems with Blizzard's Edit Mode window.
- Restored selectable and movable action bars, bag bar, micro menu, experience and reputation bars, cast bars, buffs, debuffs, unit frames, and other HUD systems.
- Added clearer selection areas, grid snapping, and center-alignment guides.
- Prevented gameplay actions from passing through Edit Mode overlays.
- Fixed overlapping values, duplicated labels, incorrect selection bounds, and asynchronous action-bar overlays.
- Added startup and reload cleanup for hidden Edit Mode input layers.

### Action bars and bottom HUD

- Reworked Classic Era action-bar registration, positioning, selection, and saved-layout restoration.
- Fixed bars appearing outside the screen or shifting after `/reload`.
- Corrected bag-bar layout, backpack sizing, micro-menu spacing, and bottom-right gaps.
- Fixed experience-bar visibility and position restoration.

### Unit, party, and raid frames

- Restored player, target, focus, pet, party, and raid-frame compatibility.
- Fixed party and raid frames not appearing while grouped.
- Corrected player power-bar layers, portrait artifacts, duplicate resource bars, and click regions.

### Combat UI

- Fixed duplicated buff and debuff containers and restored their Edit Mode controls.
- Restored cast-bar visuals, movement, selection bounds, and saved positions.
- Improved frame update flow while entering or leaving Edit Mode.

### Publication preparation

- Replaced copied upstream promotional text with an original DragonflightUI_Luna description.
- Added `THIRD_PARTY_NOTICES.md`, `CONTRIBUTORS.md`, `CURSEFORGE_DESCRIPTION.md`, `ASSET_PROVENANCE.md`, and a generated asset hash manifest.
- Removed the in-game donation link, supporter-benefit wording, and the unused coffee artwork.
- Removed the upstream CurseForge project ID from DragonflightUI_Luna's TOC metadata to avoid false project association.
- Added a distinct DragonflightUI_Luna project avatar and recorded its AI-generated origin.
- Standardized the final distribution archive name as `DragonflightUI_Luna.zip`.
- Retained third-party license files and copyright notices without shortening or relicensing them.
- Added missing standard XML namespace declarations to the bundled LibTradeSkillRecipes loader without changing its loaded scripts.

## Feedback

Compatibility reports may be submitted through <https://discord.gg/ZfYDHV6Qgs>.
