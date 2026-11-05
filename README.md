# WoW Forever AddOns

This repository packages two independent AddOns for WoW: Forever (Camelot):

- **DragonflightUI Luna** — a Classic-style UI overhaul adapted for Forever.
- **BNP BetterNameplates** — BNP's modern nameplate levels, scaling, and threat display adapted for Forever.

## Install

Copy the `DragonflightUI` and `BetterNameplates` folders into the WoW: Forever
client's `Interface/AddOns` folder, then restart the client or reload the UI.
The flavor-specific TOCs target interface `16001` and use Blizzard's `Camelot`
game-type suffix.

On Windows, the installed folder is typically under:

```text
World of Warcraft\_forever_\Interface\AddOns
```

These remain separate AddOns in game; enable both at character select.

## Compatibility notes

DragonflightUI includes modern API adapters for the Classic-facing spell, aura,
quest-log, spellbook, and settings code. Its WoW: Forever TOC skips the bundled
Classic aura-duration override and keeps Blizzard's native aura handling.

BNP keeps its existing nameplate appearance. If the client restricts a name,
level, or threat value during combat, BNP leaves Blizzard's native label visible
or hides only its custom threat badge.

## Origins and licenses

- DragonflightUI Luna is based on [Fatex04/Dragonflight-UI-Classic---Luna](https://github.com/Fatex04/Dragonflight-UI-Classic---Luna).
- BNP is based on [Fatex04/BetterNameplates](https://github.com/Fatex04/BetterNameplates).

Each AddOn directory keeps its own license, notices, and attribution records.
