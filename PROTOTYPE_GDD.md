# Tempest — Prototype Game Design Document

> *Where gravity bends, time fractures, and impossible architecture is the only path forward.*

---

## 1. Overview

| Field | Detail |
|-------|--------|
| **Title** | Tempest |
| **Genre** | 2.5D Puzzle-Platformer |
| **Engine** | Godot 4.x (GDScript) |
| **Camera** | Orthographic, fixed-angle with controlled rotations |
| **Art Style** | Escher-inspired — impossible geometry, high-contrast linework, surreal architecture, tessellated patterns |
| **Target Playtime** | ~15 minutes (3 levels, ~5 min each) |
| **Players** | Single-player |

### Concept Statement

Tempest is a 2.5D platformer set inside an impossible architectural construct that exists across three temporal eras simultaneously. The player manipulates **gravity**, **time dilation**, and **era shifts** to navigate Escher-like spaces where staircases loop into themselves, floors become ceilings, and the past literally reshapes the ground beneath your feet.

---

## 2. Core Mechanics

### 2.1 Gravity Manipulation

The player can **rotate gravity in 90° increments** (0°, 90°, 180°, 270°). When gravity rotates, the camera smoothly follows, and what was a wall becomes the floor.

| Property | Detail |
|----------|--------|
| **Input** | `Q` / `E` (rotate gravity left/right by 90°) |
| **Transition** | Smooth 0.25s lerp; player is briefly airborne during rotation |
| **Controls** | Always screen-relative (up = jump, regardless of gravity direction) |
| **Constraint** | Can only rotate when grounded on a solid surface |
| **Cooldown** | 0.5s between rotations |

**Design intent:** Gravity rotation recontextualizes the level geometry — an unreachable ledge above becomes a simple walk when gravity points sideways. Combined with the orthographic camera, this creates FEZ-like moments where spatial relationships change with orientation.

### 2.2 Time Dilation Field

The player can cast a **localized time-dilation bubble** that slows everything inside it to 20% speed. The player themselves are always immune (move at normal speed).

| Property | Detail |
|----------|--------|
| **Input** | `RMB` (hold to aim) → release to place |
| **Range** | Medium — cast onto a visible surface within ~8 tiles |
| **Radius** | ~3 tile radius sphere of influence |
| **Duration** | 4 seconds, then dissipates |
| **Cooldown** | 2 seconds after field expires |
| **Affects** | Enemies, moving platforms, projectiles, physics objects, hazards |
| **Does NOT affect** | Player, static geometry, era-locked objects |

**Design intent:** Dilation fields turn frantic action sequences into navigable puzzles. A volley of projectiles becomes a slow-motion corridor to weave through. A fast-collapsing bridge holds just long enough to cross.

### 2.3 Era Shift

The level exists in three temporal states — **Past**, **Present**, and **Future**. The player can shift between adjacent eras. Each era shares the same architectural skeleton but with critical differences in geometry, hazards, and atmosphere.

| Property | Detail |
|----------|--------|
| **Input** | `Shift+Left` (shift to earlier era), `Shift+Right` (shift to later era) |
| **Transition** | 0.5s cross-fade with chromatic aberration pulse |
| **Constraint** | Cannot shift if the destination era's geometry would embed the player in a wall (visual warning flash) |
| **Cooldown** | 1.5 seconds |

**Era characteristics:**

| Era | Geometry | Palette | Mood |
|-----|----------|---------|------|
| **Past** | Complete, ornate — grand stairways, intact bridges, decorative tessellations | Warm sepia and gold | A cathedral at its peak |
| **Present** | Partially collapsed — gaps in floors, cracked pillars, overgrown with impossible vines | Muted grays and greens | Abandonment and entropy |
| **Future** | Abstract and alien — geometry folds in on itself, platforms float unmoored, spaces loop | Cool blues and violet | Transcendence beyond physics |

**Design intent:** Era shifting is both a puzzle tool and a worldbuilding device. The player experiences the lifecycle of the impossible architecture, and every shift communicates: *this place had a past, is decaying now, and will become something incomprehensible.*

---

## 3. Player Character

**The Wanderer** — a small, silhouetted humanoid figure (Limbo-esque) with a faintly glowing geometric eye. No backstory is given; the architecture *is* the story.

| Attribute | Value |
|-----------|-------|
| **Movement** | Walk, run (hold `Shift` when not era-shifting), wall-slide |
| **Jump** | Single jump + wall-jump |
| **Health** | 3 hits (represented by fractures in the character's silhouette) |
| **Respawn** | Generous checkpoints; death rewinds the player to the last checkpoint with a brief time-rewind visual effect |

---

## 4. Visual & Audio Direction

### 4.1 Escher Aesthetic Pillars

1. **Impossible geometry**: Penrose staircases, infinite loops, and perspective-dependent connections. Platforms that are disconnected in 3D space but visually adjacent from the orthographic camera — stepping onto them works *because they look connected*.
2. **Tessellations**: Floors and walls use animated Escher-style tessellation patterns (e.g., interlocking birds that morph into fish during era shifts). Implemented via UV-scrolling shaders.
3. **Architectural surrealism**: Arches leading nowhere, staircases that descend upward, water flowing along ceilings. The environment should constantly challenge the player's spatial intuition.
4. **High-contrast linework**: Thick black outlines on geometry, minimal texture detail, cel-shaded lighting. The world feels like an animated etching.

### 4.2 Audio

| Element | Approach |
|---------|----------|
| **Music** | Ambient, generative — layered drones that shift pitch/timbre with era changes. Past: warm strings. Present: sparse piano + static. Future: synthetic, crystalline |
| **Time dilation SFX** | Everything inside the bubble pitch-shifts down; bass rumble at bubble edges |
| **Gravity rotation SFX** | Stone grinding + a tonal "settling" chord when new gravity locks in |
| **Era shift SFX** | Reversed reverb tail (whoosh-into-silence) followed by the new era's ambient bed fading in |

---

## 5. Level Design

### Teaching Philosophy

Each level follows the **Introduce → Develop → Twist → Conclude** pattern. Only one new mechanic is introduced per level. By Level 3, all mechanics combine.

---

### Level 1 — "The Ascending Ruin"

**Theme:** A crumbling stone tower that loops vertically — Escher's *Ascending and Descending* brought to life.

**New mechanic taught:** Gravity Manipulation

**Era:** Locked to Present (era shift not yet available).

#### Structure

| Section | Description | Purpose |
|---------|-------------|---------|
| **1A — The Courtyard** | Simple horizontal platforming across broken archways. Standard gaps and moving platforms. A Penrose staircase in the background loops endlessly — pure visual foreshadowing. | Establish movement, jump, wall-jump |
| **1B — The Sealed Chamber** | A room with a door on the ceiling and a glowing gravity-shift altar on the floor. The room has both a floor and ceiling with safe landing. A prompt teaches `Q`/`E`. | Introduce gravity rotation in a zero-risk sandbox |
| **1C — The Vertical Labyrinth** | A tall shaft with platforms on all four walls. The player must rotate gravity multiple times to ascend, navigating around spike hazards that only threaten from certain orientations. A Penrose-style staircase becomes *functional* — rotating gravity at the right point lets you walk "up" the impossible stairs. | Develop gravity rotation with light stakes |
| **1D — The Gatehouse** | A corridor where gravity must be rotated in quick succession: floor drops away → rotate to wall → wall spikes emerge → rotate to ceiling → ceiling gap → rotate to opposite wall → reach exit. Forgiving checkpoints every two rotations. | Test gravity mastery; gate to Level 2 |

**Escher moment:** In section 1C, a staircase visually loops back to its own base (Penrose stairs). Rotating gravity at the loop point actually connects the geometry — what seemed impossible is the solution.

---

### Level 2 — "The Fractured Gallery"

**Theme:** A grand art gallery suspended in void, its wings existing in different eras — Escher's *Relativity* meets *Metamorphosis*.

**New mechanics taught:** Time Dilation Field, Era Shift

**Gravity rotation:** Available from Level 1.

#### Structure

| Section | Description | Purpose |
|---------|-------------|---------|
| **2A — The Slow Hall** | A long corridor with fast-moving pendulum blades. A glowing time-dilation orb sits before the first blade. Prompt teaches `RMB` casting. Placing a field on a blade slows it enough to walk under. | Introduce time dilation in isolation, zero gravity complexity |
| **2B — The Triptych** | Three versions of the same room visible through translucent "time windows." A bridge exists in the Past but is collapsed in the Present. Prompt teaches era shift. The player shifts to Past, crosses, shifts back. The walls are covered in tessellations that morph between eras — birds in the Past become skeletal fish in the Present. | Introduce era shift in isolation |
| **2C — The Shattered Atrium** | A large open space. In the Present: a gap too wide to jump across, with fast-moving debris. In the Past: the gap has a bridge, but a massive swinging pendulum blocks it. Solution: shift to Past (bridge appears), cast time dilation on the pendulum (it slows to a crawl), cross, shift back to Present. | Combine time dilation + era shift |
| **2D — The Impossible Corridor** | A hallway where gravity, time, and era must all work together. The floor collapses in the Present → rotate gravity to walk on the wall → a fast-moving crusher blocks the wall-path → cast dilation to slow it → the wall-path dead-ends in Present but continues in the Past → era shift to Past → reach the exit. | Combine all three mechanics; gate to Level 3 |

**Escher moment:** In section 2B, the three era versions of the room are *simultaneously visible* through archways, like Escher's impossible windows — you can see yourself standing in the Past from the Present.

---

### Level 3 — "The Chronolith"

**Theme:** The heart of the impossible structure — a massive vertical arena built around a sentient geometric monolith (the Chronolith). Escher's *Another World* — staircases and arches open to alien skies in every direction.

**New element:** Boss fight — The Chronolith

**All mechanics available and required.**

#### Structure

| Section | Description | Purpose |
|---------|-------------|---------|
| **3A — The Approach** | A gauntlet combining all mechanics in a flowing sequence. Moving platforms require dilation to time correctly. Gaps require era-shifting to bridge. Walls require gravity rotation to traverse. No single section is harder than Level 2's gate — this is a warm-up, not a spike. | Re-establish all mechanics before the boss |
| **3B — The Chronolith (Boss Fight)** | See boss design below. | Climactic test of all skills |

#### Boss: The Chronolith

A massive rotating geometric form (think an Escher-style impossible polyhedron) at the center of a square arena with platforms on all four walls/floor/ceiling.

**Behavior loop (3 phases):**

**Phase 1 — "Gravity" (HP: 100%–66%)**
- The Chronolith fires slow-tracking projectiles and periodically **forces a gravity shift** (the arena rotates, taking the player with it).
- Glowing weak points appear on the side that is currently the "ceiling" — the player must **voluntarily rotate gravity** to reach the ceiling and strike the weak point before the Chronolith forces another rotation.
- **Teaching callback:** Gravity mastery from Level 1.

**Phase 2 — "Time" (HP: 66%–33%)**
- The Chronolith begins spawning **temporal echoes** — shadow copies of the player's past movement that deal damage on contact.
- The Chronolith accelerates: projectiles fire in rapid bursts, gravity shifts happen faster.
- Weak points now only appear for 2 seconds — the player must **cast time dilation on the weak point** to extend the window long enough to reach and strike it.
- **Teaching callback:** Time dilation from Level 2.

**Phase 3 — "Era" (HP: 33%–0%)**
- The Chronolith **fractures the arena across eras**. Different sections of the floor/walls exist in different eras. Some platforms only exist in the Past, others only in the Future.
- The Chronolith's weak point shifts between eras — visible as a ghostly outline in the wrong era, solid and strikable only in the correct one.
- The player must **rotate gravity** to reach the correct wall, **era shift** to materialize the platform and the weak point, and **cast dilation** on the Chronolith's now-frantic projectile barrage to survive the approach.
- **Teaching callback:** All mechanics combined.

**Defeat:** The Chronolith collapses into itself, tessellating into smaller and smaller geometric forms — an Escher *Print Gallery* spiral that zooms infinitely inward. The screen whites out. The Wanderer stands in the original courtyard from Level 1, but every staircase now leads somewhere different. End of prototype.

---

## 6. Technical Architecture

### 6.1 Engine: Godot 4.x

| Choice | Rationale |
|--------|-----------|
| **Godot 4** | Free, open-source, excellent 2.5D support, GDScript for rapid prototyping, orthographic camera built-in, lightweight |
| **GDScript** | Fast iteration; C# available if performance bottlenecks arise |
| **Orthographic camera** | Essential for Escher geometry tricks — no perspective to reveal spatial cheats |

### 6.2 Core Systems

```
TimeManager (Singleton)
├── game_time_scale: float          # Global time multiplier
├── dilation_fields: Array[Field]   # Active dilation bubbles
├── current_era: Enum {PAST, PRESENT, FUTURE}
├── get_scaled_delta(node) → float  # Returns delta adjusted for dilation proximity
└── era_shift(direction) → bool     # Returns false if shift would embed player

GravityManager (Singleton)
├── gravity_angle: int              # 0, 90, 180, 270
├── gravity_vector: Vector2         # Derived from angle
├── rotate(direction) → void        # Triggers lerp + camera rotation
└── is_rotating: bool               # Lock input during transition

LevelStateManager (Singleton)
├── era_layers: Dict[Era, TileMap]  # Parallel tilemaps per era
├── swap_era(new_era) → void        # Cross-fade + collision swap
└── get_active_tilemap() → TileMap
```

### 6.3 Escher Geometry Implementation

- **Visual connections:** Disconnected 3D meshes that align from the orthographic camera angle. A `ConnectionBridge` node enables collision between them only when visually overlapping (checked via screen-space projection).
- **Penrose stairs:** A looping staircase mesh with a teleport trigger at the loop seam — the player is silently repositioned when the camera angle hides the seam.
- **Tessellation shaders:** Fragment shaders that tile Escher-pattern textures, with a `morph` uniform that blends between era variants (0.0 = Past, 0.5 = Present, 1.0 = Future).

### 6.4 State Snapshot (for rewind-on-death)

On death, play a brief (1s) visual rewind using recorded snapshots:

```
Snapshot:
  - player_position: Vector2
  - player_velocity: Vector2
  - gravity_angle: int
  - current_era: Enum
  - timestamp: float
```

Record every 0.1s, keep the last 30 snapshots (3 seconds). On death, replay in reverse over 1 second, then restore to last checkpoint.

---

## 7. Controls Summary

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move | `A` / `D` | Left stick |
| Jump | `Space` | `A` / Cross |
| Wall-jump | `Space` (against wall) | `A` / Cross (against wall) |
| Rotate gravity left | `Q` | `LB` |
| Rotate gravity right | `E` | `RB` |
| Cast time dilation | `RMB` (hold to aim, release to place) | `RT` (hold to aim, release) |
| Era shift earlier | `Shift + A` | `LT + D-pad Left` |
| Era shift later | `Shift + D` | `LT + D-pad Right` |

---

## 8. Prototype Scope & Priorities

### In Scope (Prototype)

- [x] Player movement, jump, wall-jump
- [x] Gravity rotation (4 directions) with camera follow
- [x] Time dilation field casting
- [x] Era shift (3 eras) with geometry/visual swap
- [x] 3 levels with progressive teaching
- [x] Boss fight (The Chronolith, 3 phases)
- [x] Orthographic camera with Escher-style visual connections
- [x] Death/checkpoint system with rewind visual
- [x] Basic tessellation shaders for era transitions
- [x] Placeholder audio (ambient + SFX)

### Out of Scope (Post-Prototype)

- Story/narrative/dialogue
- Additional levels
- Save system
- Settings menu
- Accessibility options
- Multiplayer
- Steam/platform integration
- Full original soundtrack
- Complex NPC AI beyond the boss

---

## 9. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Escher geometry is disorienting / nauseating | Medium | High | Generous visual cues (color-coded surfaces per gravity orientation), optional reduced-motion camera transitions |
| Three mechanics is too many for 3 levels | Medium | Medium | Each level teaches exactly one; combinations only in L2D, L3A, and boss. Cut Phase 3 of boss if overwhelming |
| Gravity + era shift creates impossible-to-debug collision edge cases | High | Medium | Strict "cannot shift if embedded" check. Keep era geometry variants conservative — share 80% of collision, vary 20% |
| Prototype scope creep | High | High | This document is the ceiling. No new mechanics, no new levels, no narrative systems until all 8.1 items are playable |
