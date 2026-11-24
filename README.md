# TrinketCDs Enhanced

Tracks the cooldowns and procs of your trinkets, rings, cloak, weapon, hands, boots and belt enchants, and also the trinkets of your party and your arena enemies. For World of Warcraft 3.3.5a (WotLK).

Based on **TrinketCDs** by **Ridepad** ([Ridepad/TrinketCDs](https://github.com/Ridepad/TrinketCDs)) and its fork by **suprepupre** ([suprepupre/TrinketCDs](https://github.com/suprepupre/TrinketCDs)). Enemy trinket detection is based on the **TCT** addon. All credit for the original work goes to their authors.

*Leer en español: [README.es.md](README.es.md)*

## What this version does differently

- **Arena enemy trinkets**: PvP trinket and both trinkets of arena1 to arena5, each with its own movable frame. Hidden outside arena.
- **Party trinkets**: the same for your party members, optionally only inside arena.
- **Own menu** opened with `/tcd`, in English or Spanish depending on your game client.
- **Lock / unlock** to drag every frame, and a **Test mode** that shows the final look with glows and cooldowns.
- **Glow per item**: each item can pick its own glow style (Action Button, Pixel or Proc Glow), and the glow can be drawn outside the border.

## Installation

1. Download this repository (**Code → Download ZIP**).
2. Copy the `TrinketCDs` folder into `World of Warcraft/Interface/AddOns/`.
3. Restart the game or type `/reload`.

## Commands

| Command | What it does |
|---|---|
| `/tcd` | Open the menu |
| `/tcd drag` | Lock or unlock the frames |
| `/tcd test` | Test mode |
| `/tcd save <name>` / `/tcd load <name>` / `/tcd delete <name>` | Profiles |
| `/tcd profiles` | List profiles |
| `/tcd help` | All commands |
