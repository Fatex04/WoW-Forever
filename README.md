# Dragonflight UI Forever - Luna

This repository contains **Dragonflight UI Forever - Luna**, a standalone UI addon
for WoW: Forever (Camelot), using Luna artwork and appearance controls.

## Install

Copy only the `DragonflightUI` folder into the WoW: Forever client's
`Interface/AddOns` folder, then fully exit and restart the client.
The flavor-specific TOCs target interface `16001` and use Blizzard's `Camelot`
game-type suffix.

On Windows, the installed folder is typically under:

```text
World of Warcraft\_forever_\Interface\AddOns
```

Enable **Dragonflight UI Forever - Luna** at character select. Its bare,
Forever, and Camelot manifests all target the Forever client in this package.

## Release ZIP

Run `python tools/package_forever.py --output-dir <output-directory>` from the
repository root to build `Dragonflight UI Forever - Luna 1.0.zip`. The builder
includes only the `DragonflightUI` folder, its Forever runtime, required libraries,
artwork and notices. It verifies the archive, manifest references and asset hashes.

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

Lua 5.1 regression fixtures cover startup, secure handler preservation, opaque
value forwarding, layout copying, editor behavior and panel restoration.
These do not emulate the WoW taint engine; live client checks
are also necessary. Classic-only favorite flyouts and replacement aura headers
remain outside the Forever runtime.

## Origins and licenses

- DragonflightUI Luna is based on [Fatex04/Dragonflight-UI-Classic---Luna](https://github.com/Fatex04/Dragonflight-UI-Classic---Luna).

The `DragonflightUI` directory keeps its license, notices and attribution records.
