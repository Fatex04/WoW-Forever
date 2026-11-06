# WoW Forever AddOns

This repository packages two independent AddOns for WoW: Forever (Camelot):

- **Dragonflight UI Forever - Luna** — a native Forever UI theme using Luna artwork and appearance controls.
- **BNP BetterNameplates** — Forever's stock Classic plates, readable native numbers, scaling and threat support.

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
DragonflightUI is listed as **Dragonflight UI Forever - Luna**. Its bare,
Forever, and Camelot manifests all target the Forever client in this package.

## Compatibility notes

Dragonflight UI Forever - Luna 1.0 uses the bundled Luna artwork with a complete visual layer
for player, target, focus, pet and target-of-target frames. Native secure unit
buttons and unit-data controllers remain active. Opaque health/power values and
native text are forwarded directly to rendering widgets that accept them; they
are never formatted, calculated or saved by Luna.

The separate **Luna Classic** character layout arranges three central action-bar
rows, two side grids, unit frames, minimap, bags and micro menu. Existing layouts
and Classic profiles are retained. Use `/df classic` to reapply the reference
layout, `/df` for appearance, and **Esc > Edit Mode** or `/editmode` for the Luna
HUD editor with native Save/Revert and layout storage.

The minimap uses Luna's round mask, gold cardinal arrows and zoom buttons.
Native panel chrome also receives Luna artwork, including load-on-demand
Forever panels. `/df windows` opens a window catalog with secure native click
shortcuts. Features missing or locked in the client remain unavailable there.

BNP 1.3.0 selects Forever's **Classic** nameplate style and enlarges the original
native name, health and level labels with an outline and shadow. It supports the
new nested health-bar frame structure, preserves stock plate art/skulls and
native data updates, and avoids duplicate inline labels. Restricted threat data
hides only BNP's custom threat indicator. Existing BNP preferences remain.

Lua 5.1 regression fixtures cover startup, secure handler preservation, opaque
value forwarding, layout copying, editor behavior, panel restoration and BNP's
stock-plate adapter. These do not emulate the WoW taint engine; live client checks
are also necessary. Classic-only favorite flyouts and replacement aura headers
remain outside the Forever runtime.

## Origins and licenses

- DragonflightUI Luna is based on [Fatex04/Dragonflight-UI-Classic---Luna](https://github.com/Fatex04/Dragonflight-UI-Classic---Luna).
- BNP is based on [Fatex04/BetterNameplates](https://github.com/Fatex04/BetterNameplates).

Each AddOn directory keeps its own license, notices, and attribution records.
