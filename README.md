# Inkmancer

*Leia em português: [LEIA-ME.md](LEIA-ME.md)*

You are a necromancer whose magic comes from rubber stamps. Find stamps across the map, engrave them with the unit you want, and stamp an army of ink soldiers into the world. Hold out for five minutes against the waves. Then the boss arrives.

Made in Godot 4.7 for a game jam (FelpoJam 2026.1).

## Play

- **In the browser:** https://tiagojsaraiva.github.io/Inkmancer/
- **Windows:** download `Inkmancer-windows.zip` from [Releases](https://github.com/TiagoJSaraiva/Inkmancer/releases), unzip it and run `Inkmancer.exe`.

The browser version needs WebGL 2 and runs best in Chrome, Edge or Firefox on desktop. Click the game once so it can capture the keyboard.

## Controls

| Action | Input |
|---|---|
| Move | `W` `A` `S` `D` |
| Summon: first click shows the range, second click summons at the cursor | Right click (twice) |
| Select stamp slot | `1` `2` `3` `4` |
| Pause | `P` or `Esc` |

## How to play

1. **Find stamps.** The arrow on screen points to the nearest one. Walk over it to pick it up.
2. **Engrave it.** Choose the unit type and spend the stamp's attribute points on Attack, Health and Speed. Rarity follows the order you pick stamps up: the 1st and 2nd are Common (3 points), the 3rd is Uncommon (6) and the 4th is Rare (9). The engraving is permanent for the run.
   - **Warrior:** melee.
   - **Archer:** single-target ranged.
   - **Cannon:** slow, area damage.
3. **Summon.** Each summon costs ink (the blue potion):

   | Rarity | Ink cost | Cooldown |
   |---|---|---|
   | Common | 30 | 10 s |
   | Uncommon | 35 | 10 s |
   | Rare | 40 | 11 s |

   Ink regenerates over time, and every enemy you kill gives some back.
4. **Mind the ink.** Summoned units dry out after 40, 50 or 60 seconds depending on rarity. There is no limit on how many you can have.
5. **Survive 5:00.** Enemies get tougher every minute. When the timer runs out the boss appears and the waves stop. Defeat the boss to win.

Your health regenerates after a few seconds without taking damage.

## Running from source

1. Install [Godot 4.7.2](https://godotengine.org/download) (standard build, not .NET).
2. Open `game/avelino-inkmancer-3D/project.godot` in the editor and press **F5**.

## Exporting

Export presets for **Web** and **Windows Desktop** are in `game/avelino-inkmancer-3D/export_presets.cfg`. Builds go to `build/` at the repository root, which git ignores.

```sh
cd game/avelino-inkmancer-3D
godot --headless --export-release "Web" ../../build/web/index.html
godot --headless --export-release "Windows Desktop" ../../build/windows/Inkmancer.exe
```

The Web preset has thread support disabled, so the build runs on plain static hosting such as GitHub Pages without COOP/COEP headers. You need the Godot 4.7.2 export templates (*Editor → Manage Export Templates*).

### Continuous deployment

`.github/workflows/deploy.yml` exports both builds on GitHub Actions:

- **Push to `main`:** publishes the Web build to GitHub Pages. Repository settings → Pages → Source must be set to **GitHub Actions**.
- **Push a tag such as `v1.0.0`:** also creates a GitHub Release with `Inkmancer-windows.zip` attached.

## Project layout

```
game/avelino-inkmancer-3D/
├── game/        main scene, timer, boss spawn, procedural chunks
├── player/      player controller, health and ink
├── unit/        base unit + ally/enemy/boss units and projectiles
├── spawner/     enemy waves and difficulty curve
├── carimbo/     stamp pickups and the guide arrow
├── menus/       HUD, pause, victory/defeat, engraving screen
├── SummonSystem.gd   summoning (cost, cooldown, ally cap, lifetime)
└── assets/      models, sounds, music
notes/           design notes and changelog
```

Most balance values are in the unit scenes (`unit/**/*.tscn`). Wave pacing is in `spawner/spawner_manager.gd` and summon economy in `SummonSystem.gd`.

## Credits

**Team:** Tiago Jarruge Saraiva, Matheus Di Giacomo, Luiz Henrique Freitas.

**Music and sound effects:** original, made by the team.

**Third-party assets** (CC BY 4.0):
- [Low poly mushrooms set](https://sketchfab.com/3d-models/low-poly-mushrooms-set-53755c7630754ac49b679e44a79c5a40) by [ClydeXYZ](https://sketchfab.com/ClydeXYZ)
- [Low poly trees](https://sketchfab.com/3d-models/low-poly-trees-51cae4a194344e8bbfbd0a4cff205f76) by [Aditya Graphical](https://sketchfab.com/Adityakm)
- [Nature environment models (Low-poly)](https://sketchfab.com/3d-models/nature-environment-models-low-poly-b687543d05384ce1a8f0429baca02f67) by [Saucy](https://sketchfab.com/saucy)

**Font:** Eagle Lake by Cyreal (SIL Open Font License).

Built with [Godot Engine](https://godotengine.org).
