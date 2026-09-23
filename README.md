# WoW: Forever temporary addon fix

<a href="https://www.buymeacoffee.com/zkyxykz"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=☕&slug=zkyxykz&button_colour=FFDD00&font_colour=000000&font_family=Poppins&outline_colour=000000&coffee_colour=ffffff" /></a>

**The beta client writes addon settings on exit, but never reads them back.** Every addon starts from scratch at each login: Leatrix Plus options unchecked, Auctionator config empty, and so on. Your settings are not lost, they sit unused in `WTF\Account\<account>\SavedVariables`.

This is a Blizzard bug in the beta build (client 1.60.1, interface 16001). This script is a stopgap until it is fixed.

## How it works

`SavedVariablesBridge.ps1` generates a small addon of its own, `Interface\AddOns\!SavedVariablesBridge`, which contains a copy of each SavedVariables file. The game happily runs those copies as addon code, so the variables exist before any other addon starts. The `!` in the name makes it load first.

A file watcher re-syncs the copies as soon as the game writes, so a `/reload` or a logout is picked up immediately.

**It never touches your addons' own files.** An earlier approach added a line to each addon's `.toc`; addon updates rewrite that file and silently removed it. Nothing here breaks on update.

## Install

1. Drop `SavedVariablesBridge.ps1` and `RunBridge.cmd` in your **WoW: Forever folder**, the one that contains `WTF` and `Interface` (usually `World of Warcraft\_classic_beta_`).
2. Run `RunBridge.cmd` **before launching the game**, and leave the window open while you play.
3. Launch the game. Your settings are back.

First run only: if your settings were already wiped, set them once, `/reload`, and they stick from then on.

## Addon detection is automatic

WoW names each SavedVariables file after the addon folder, so the script keeps every file that matches a folder in `Interface\AddOns`. Install a new addon and it is covered, with nothing to edit.

Per-character files are copied too, each wrapped in a guard so one character's settings never leak onto another:

```lua
if UnitName("player") == "Yourname" then
  -- your character's saved variables
end
```

The console log shows every file taken, every file ignored and why, and each sync triggered by the game:

```
15:45:00   compte  Leatrix_Plus.lua -> SV_Leatrix_Plus.lua (6183 caracteres, ecrit 15:44:58)
15:45:00   ignore  AUCTIONATOR_CONFIG.lua (aucun addon de ce nom)
15:45:00 pont pret : 17 fichiers charges au prochain demarrage
```

## Good to know

- **The window must stay open.** If it is closed, settings simply stop being refreshed; nothing is lost, the last sync stays in place.
- **A brand new addon is picked up after its first save**, so after one `/reload` or logout.
- **Only files matching an installed addon are copied.** Leftovers from other tools, such as `AUCTIONATOR_CONFIG.lua` or `LeaPlusDB.lua` sitting next to `Auctionator.lua`, are frozen duplicates: loading them would overwrite fresh settings, so they are skipped on purpose.
- **Blizzard's own files** (`Blizzard_*.lua`) are left alone.
- The per-character guard matches the character's first name.

## Uninstall

Close the window and delete `Interface\AddOns\!SavedVariablesBridge`. Nothing else was modified.

## Credits

Same bug independently documented by [forever-addon-kit](https://github.com/Thunderz96/forever-addon-kit).
