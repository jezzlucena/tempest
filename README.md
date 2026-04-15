# Tempest

> *Where gravity bends, time fractures, and impossible architecture is the only path forward.*

A 2.5D puzzle-platformer inspired by M.C. Escher's impossible geometry. Manipulate gravity, slow time, and shift between temporal eras to navigate surreal architecture and defeat the Chronolith.

## Requirements

- **Godot 4.4+** (tested on 4.6.1)
- No external dependencies or assets required

## Running the Game

```bash
# Clone and run
git clone <repo-url> tempest
cd tempest
godot --path .
```

Or open the project in the Godot editor and press F5.

## Controls

| Action | Keys |
|--------|------|
| Move | A / D or Left / Right |
| Jump / Wall-jump | Space / W / Up |
| Rotate gravity | Q (left) / E (right) |
| Time dilation field | Right-click (hold to aim, release to place) |
| Era shift | Shift + Left (earlier) / Shift + Right (later) |
| Menu | Esc |

## Core Mechanics

### Gravity Rotation
Press Q/E to rotate gravity 90 degrees. The entire world reorients — walls become floors, ceilings become walkable surfaces. Works mid-air. 0.5s cooldown between rotations.

### Time Dilation
Right-click to place a bubble that slows everything inside it to 20% speed. Lasts 4 seconds. The player is immune. Use it to slow fast-moving platforms, pendulum blades, and boss projectiles.

### Era Shift
Shift between Past, Present, and Future. Each era has different level geometry — bridges that exist in the Past may be collapsed in the Present. Cannot shift if the destination geometry would trap the player.

## Levels

### Level 1 — The Ascending Ruin
Teaches gravity rotation across 4 sections: a courtyard with platforming fundamentals, a sealed chamber requiring a gravity flip to escape, a vertical shaft with platforms on all four walls, and a gatehouse corridor demanding rapid rotations.

### Level 2 — The Fractured Gallery
Introduces time dilation and era shifting. Pendulum blades must be slowed with dilation fields. A triptych room requires era-shifting to cross a collapsed bridge. Later sections combine all three mechanics.

### Level 3 — The Chronolith
A gauntlet combining every skill, followed by a boss fight against the Chronolith — a rotating geometric monolith at the heart of the impossible architecture.

**Boss phases:**
1. **Gravity** — Forced gravity shifts, weak points appear on the ceiling
2. **Time** — Burst-fire projectiles, weak points require dilation to extend their window
3. **Era** — Weak points are locked to specific eras, requiring era shifts to hit

## Features

- Save system with checkpoint persistence
- Continue from last checkpoint with retained HP
- 9 hidden health collectibles across all levels (+1 max HP each)
- Collapsing platforms, moving platforms, patrol enemies
- Escher-style tessellation background shaders that morph between eras
- Level select and controls screen
- Post-completion screen

## Project Structure

```
tempest/
├── project.godot              # Engine config, autoloads, display settings
├── scenes/                    # .tscn scene files
│   ├── levels/                # Level 1, 2, 3
│   ├── player/                # Player scene
│   ├── objects/               # Checkpoint, spikes, platforms, dilation field, etc.
│   ├── enemies/               # Basic patrol enemy
│   ├── boss/                  # Chronolith + weak points
│   └── ui/                    # HUD, main menu, completion screen
├── scripts/                   # GDScript source
│   ├── autoload/              # Singletons: Input, Gravity, Time, LevelState, Game
│   ├── player/                # Player controller + state machine (7 states)
│   ├── levels/                # Level builder utility + level scripts
│   ├── objects/               # Game object scripts
│   ├── enemies/               # Enemy AI
│   ├── boss/                  # Boss logic (3 phases)
│   ├── camera/                # Gravity-following camera
│   └── ui/                    # HUD, menus
├── shaders/                   # GDShader files (outline, tessellation, effects)
├── assets/audio/              # Placeholder audio stubs
├── PROTOTYPE_GDD.md           # Full game design document
└── README.md
```

## Architecture

All game logic is in GDScript. Level geometry is built programmatically via `LevelBuilder` (no hand-authored tilemap data). Visuals are code-drawn using `_draw()` — no external sprite assets.

**Autoload singletons:**
- `GravityManager` — gravity angle, rotation tweens, vector computation
- `TimeManager` — dilation fields, era state, era shift logic
- `LevelStateManager` — per-era TileMapLayer toggling
- `GameManager` — scene transitions, checkpoints, save/load, respawn

**Player state machine:** Idle, Run, Jump, Fall, Wall Slide, Hurt, Dead — each with distinct visual poses.

## License

See [LICENSE](LICENSE).
