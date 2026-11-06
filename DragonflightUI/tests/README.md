Run the regression checks from the `DragonflightUI` directory:

Dragonflight UI Forever - Luna 1.0:

```text
python -m pip install lupa
python tests/forever_native.py
```

These checks load the actual Forever manifest and embedded Ace libraries in Lua
5.1. The native-frame fixture rejects legacy templates, protected gameplay-frame
mutations, and Lua evaluation of concealed health/casting/aura text or values.
Opaque native widget output can pass directly to compatible rendering setters.
It also checks
the new options window in both languages and repeated Game Menu pool resets.
The editor tests exercise the normal Game Menu callback, retained Save/Revert
callbacks, unsaved warnings, selected-system appearance pages, combat cleanup,
restoration and native modal visibility. Artwork tests cover native refreshes
and restoring the latest native atlas rather than a stale initial choice.
The fixture models source frame shapes and does not emulate WoW's taint engine.
Client validation still requires checking native bar clicks/paging, targeting,
buff cancellation, casts/crafting, breathing, Esc > Edit Mode, `/editmode`, `/df`, and new
session diagnostics. No native layouts or user profiles should be reset as part
of that check.

Classic layout checks (not loaded by the Forever runtime):

```text
python -m pip install lupa
python tests/layout_regressions.py
```

The runner parses all Lua files with Lua 5.1 and executes the changed layout routines against simulated WoW frames, events and timers. It does not simulate WoW's secure execution/taint engine or replace in-game testing.

Before considering a client test complete:

- Click the center and edges of all twelve Action Bar 1 buttons, including after closing Edit Mode.
- Move and resize chat using its tab and native Edit Mode; check Save/Cancel, reload, relog and a loading screen.
- Check the bag bar on an existing and a new character, after bag changes and after a loading screen.
- Open Edit Mode from both Luna and the General chat menu; confirm one flight-path stop control and one selection per Luna system.
- Enter combat during Edit Mode and verify recovery afterwards without new protected-frame errors.
- Take a flight and confirm the native stop button works and disappears normally afterwards.
- Test a druid's alternate mana bar in shapeshift form and check BugSack for new errors.

Existing BugGrabber reports are historical. Compare new session errors without erasing the user's saved reports.

V1.3.1 live checks:

- Move player, target and possess selections in Edit Mode, close it, reload and cross a loading screen; verify the saved positions persist.
- Change targets repeatedly and enter/leave combat; check positions, scale, click targeting and BugSack.
- Activate possession (for example Mind Control), check that its buttons work and that the native bar disappears when possession ends.
- Log in with a watched friendly faction and verify that no green reputation bar flashes in the center.
