# Worlds

Tempest is structured as a sequence of worlds. Each world contains **3 levels**, with the third level ending in a **boss fight**. Defeating a boss awards a new ability (or — for World 0 — strips them all).

World 0 is the existing prototype arc (The Ascending Ruin → The Fractured Gallery → The Chronolith). After the Chronolith falls, its collapse shockwave rips every ability from the player. The game continues: the player lands in World 1 with nothing but the ability to jump. Each subsequent boss returns one ability.

## Ability recovery order

Abilities are earned back in the order they appear in the original prototype's difficulty curve — shallowest first.

| Order | Ability             | Granted by |
|-------|---------------------|------------|
| 0     | Jump                | default    |
| 1     | Sideways movement   | W1 boss    |
| 2     | Wall jump           | W2 boss    |
| 3     | Gravity shift       | W3 boss    |
| 4     | Time slowdown bubble| W4 boss    |
| 5     | Era shift           | W5 boss    |

After World 5, the player has the full kit again. The loop closes.

## Worlds

### World 0 — The Chronolith Arc *(existing)*

- **0-1** The Ascending Ruin — gravity rotation tutorial.
- **0-2** The Fractured Gallery — time dilation + era shift.
- **0-3** The Chronolith — boss combining all three mechanics.

Outcome: abilities stripped, dropped into World 1.

### World 1 — The Still Plaza

Minimal geometry; player has only jump. Pitfalls everywhere — a single misstep is terminal.

- **1-1** Spawn platform over a pit. One moving platform overhead. Exit gate one jump above the moving platform, in the middle.
- **1-2** Three Tier Tempo — same pit/spawn shape, but three moving platforms stacked one jump apart. Each platform is faster than the one below, so the timing window tightens as the player climbs. Exit one jump above the top platform.
- **1-3** Sentry Gate — walled column of three moving platforms (only the topmost escapes the right wall). Ride it over and drop into the arena. Boss: a patrolling sentinel, defeated by stomping from above. Grants **sideways movement**.

### World 2 — The Vertical Well

Tall, narrow chambers. Jump + sideways is enough to cross, but every vertical section is at the edge of reach without wall-jump — the player is on the cusp of needing it throughout.

- **2-1** The Rising Stair — a diagonal gap-chain of fixed platforms climbing up and to the right. Pure warm-up for jump + sideways.
- **2-2** The Narrow Shaft — a tall shaft with alternating wall-affixed ledges, overlapping by a single tile at the center. The overlap is the "safe" straight-up jump; drifting the wrong way drops the player into the void.
- **2-3** The Wall Crawler — boss arena. The spider clings to the ceiling firing webs, then cycles through a brief floor-patrol window where it can be stomped. Grants **wall jump**.

### World 3 — The Inverted Cloister

Drops from ceilings, upside-down geometry. The player never voluntarily shifts gravity in W3 — triggers and the boss rotate the world around them — but experiences every angle before the ability arrives.

- **3-1** The Ceiling Loop — three wall-jump shafts linked by teleport seams. Climb each shaft, the seam flings you across the screen into the next shaft's floor. Third shaft's summit holds the exit.
- **3-2** The Inverted Corridor — horizontal corridor with floor + ceiling both walkable. Three invisible trigger zones flip gravity 180° on contact, alternating the player between floor and ceiling. Staggered spikes on both surfaces.
- **3-3** The Tumbler — a stomp boss inside a fully-walled arena. Each stomp forces a 90° CW gravity rotation, so the arena tumbles around the player between hits. Grants **gravity shift**.

### World 4 — The Acceleratorium

Fast projectile corridors and hyper-speed moving platforms. Without dilation the player must rely on pattern-reading and wall-jump recovery; the reward for surviving is the ability itself.

- **4-1** Bullet Storm Gallery — horizontal corridor with staggered ceiling/floor turrets. Time the gaps; use gravity to swap surfaces for better angles of attack.
- **4-2** Racing Platforms — enclosed shaft with four moving-platform tiers escalating from 120 to 420 px/s. Wall-jumpable side walls catch recoveries from missed jumps.
- **4-3** The Phantom — walled arena with four permanent dilation fields pinned to the corners. The boss drifts near centre firing radial projectile bursts; each cycle it marks one of the fields with a weak-point. The player navigates through slowed projectiles inside a field to strike the weak-point. Three hits grants **time slowdown bubble**.

### World 5 — The Fractured Archive

Era-layered puzzles. The player never voluntarily era-shifts in W5 — triggers and the boss do it — but every era gets seen before the ability is granted.

- **5-1** The Stacked Archive — horizontal corridor with a gap bridged only in Past and a wall absent only in Future. Era triggers before each obstacle author the path.
- **5-2** The Shifting Halls — three hazard zones: Present-lethal, Past-lethal, Future-lethal. Era-locked spikes turn invisible and harmless in the safe era. Triggers before each zone flip to the matching era.
- **5-3** The Archivist — walled arena layered across all three eras. The boss drifts near centre, forces an era shift every cycle, and spawns an era-locked weak-point at that era's pocket. Three hits grants **era shift** — the final ability, closing the loop back to W0's full kit.

After W5, the full kit loops back to W0 (optional replay) or unlocks a final challenge world (TBD).

## The Infinity Visor (true-ending item)

Three shards of a shattered Infinity Visor are hidden across World 0 — one per era, one per level:

| Shard | Level | Era |
|-------|-------|-----|
| Past shard | W0-L1 | Past |
| Present shard | W0-L2 | Present |
| Future shard | W0-L3 | Future |

Each shard is only visible and collectable while the matching era is active. **W0-L1 was retrofitted with full Past / Present / Future tilemaps** (identical geometry across all three) so a replay run with era-shift available can reach the Past shard.

Collecting all three assembles the visor in the player's persistent inventory. Pressing **V** at any time toggles it on or off (the HUD shows a trefoil-knot indicator — dim before assembly, bright when active).

### Effect in the Chronolith fight (W0-L3)

- **Visor OFF** (default): Chronolith fight plays as designed — conventional weak-points spawn per phase, can be hit to damage the boss. Defeat via conventional weak-points triggers the original space-time shockwave: abilities are stripped and the player is dropped into W1-L1 to begin the recovery arc.
- **Visor ON**: Conventional weak-points are suppressed — they don't spawn and can't be hit. A single **true core** weak-point appears persistently near the boss, never expiring. It rotates its era-lock every 3.5s so the player must match the current era to strike it. Three clean hits defeat the Chronolith **without** triggering the shockwave — abilities remain intact, the visor is retained, and the **true-ending** scene plays.

The visor can be toggled mid-fight. Switching on mid-fight clears any active conventional weak-points and spawns the true core. Switching off mid-fight despawns the true core and lets conventional weak-points resume on the next phase-scheduled spawn.

## Save game

The save file persists, in addition to the existing fields:

- `world` — current world index (0-indexed).
- `level` — current level index within that world.
- `abilities` — dictionary of ability flag → bool.
- `collected_items` — regular collectibles (cleared on Chronolith defeat so a recovery run starts fresh).
- `persistent_items` — shards + visor state; **never** cleared by a world reset. Only the true-ending scene or final victory (both of which delete the save file entirely) clears these.
- `visor_active` — whether the visor is currently worn.

Default abilities when starting a fresh game: all true (World 0 keeps the existing design). After the Chronolith is defeated via conventional weak-points, all flags except `jump` are set to false. Bosses flip their corresponding flag back to true. The true-ending path preserves every flag.
