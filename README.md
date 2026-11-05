# WoW Forever AddOns

This repository packages two independent AddOns for WoW: Forever (Camelot):

- **DragonflightUI Luna** — a native Forever UI theme using Luna artwork and appearance controls.
- **BNP BetterNameplates** — BNP's modern nameplate levels, scaling, and threat display adapted for Forever.

## Install

Copy the `DragonflightUI` and `BetterNameplates` folders into the WoW: Forever
client's `Interface/AddOns` folder, then fully exit and restart the client.
The flavor-specific TOCs target interface `16001` and use Blizzard's `Camelot`
game-type suffix.

On Windows, the installed folder is typically under:

```text
World of Warcraft\_forever_\Interface\AddOns
```

These remain separate AddOns in game; enable both at character select.
DragonflightUI is listed as **Dragonflight UI Luna - WoW Forever**. Its bare,
Forever, and Camelot manifests all target the Forever client in this package.

## Compatibility notes

DragonflightUI 1.5.0 uses a dedicated native runtime. Its Forever manifests do
not load Classic FrameXML replacements or inject legacy API globals. Action
buttons, unit data, auras, cast bars, and mirror timers remain owned by Blizzard;
Luna applies its artwork and text settings. Configure appearance with `/df` and
layouts with Blizzard Edit Mode. Legacy Classic-only custom aura headers,
favorite flyout buttons, cast simulation and dialog rewrites are not loaded.
The original Classic profiles are retained; native theme settings are stored
separately. See `DragonflightUI/README.md` for the scope and validation limits.

BNP keeps its existing nameplate appearance. If the client restricts a name,
level, or threat value during combat, BNP leaves Blizzard's native label visible
or hides only its custom threat badge.

## Origins and licenses

- DragonflightUI Luna is based on [Fatex04/Dragonflight-UI-Classic---Luna](https://github.com/Fatex04/Dragonflight-UI-Classic---Luna).
- BNP is based on [Fatex04/BetterNameplates](https://github.com/Fatex04/BetterNameplates).

Each AddOn directory keeps its own license, notices, and attribution records.
