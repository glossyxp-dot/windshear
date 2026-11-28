# WINDSHEAR — Technical Specification

Target: **Godot 4.7.2**, Compatibility renderer, PSX-style low-resolution 3D,
full 3D gameplay on the ground plane, hard RAM ceiling of **4 GB**.

---

## 1. Renderer and art pipeline

| Setting | Value | Why |
| --- | --- | --- |
| Renderer | **Compatibility** (OpenGL) | Lowest VRAM/RAM of the three; PSX look doesn't need Forward+ |
| Internal resolution | **480×270** (320×240 in retro chapters) | 40× fewer pixels than 1080p; authentic PSX |
| Upscale | Nearest-neighbour, integer scale (×2 = 960×540, ×3 = 1440×810, ×4 = 1920×1080) | PSX look, zero cost, no uneven pixels |
| Colour depth | 8-bit, dithered gradients | Palette consistency |
| Texture filtering | Nearest | Pixel look, avoids mip memory |
| Lighting | Forward, baked vertex colours + few dynamic lights | Cheap; shadows only on key lights |
| Fog | Aggressive, per-layer | Depth cueing and hides draw distance |
| Vertex snapping | Custom shader (screen-space quantisation) | PSX jitter |
| Affine texturing | Optional shader toggle | PSX warping authenticity; off by default for readability |
| PSX amount | A global shader uniform, 0.0–1.0, chosen by the player | The look is the player's business |

**PSX shader notes:** the look is four separate artefacts of the 1990s that
happen to sit together, and the shader (`addons/windshear/render/ws_psx.gdshader`)
implements all four as separable knobs:

| Knob | What it does |
| --- | --- |
| `vertex_snap` | Quantises clip-space positions to the 480×270 grid — the geometry wobbles as it moves |
| `affine_warp` | Interpolates UVs in screen space instead of in perspective — flat surfaces swim |
| `color_depth` | 5 bits per channel, as the 15-bit framebuffer had |
| `dither_strength` | A 4×4 Bayer ordered pattern, hiding the banding |

The affine trick is a varying: the vertex stage passes `UV * clip.w`, the
hardware interpolates it with perspective correction, and the fragment stage
divides it by the interpolated `w` again. What is left is the straight
screen-space interpolation the PlayStation did.
The master amount is a **global shader uniform**, registered in
`project.godot` under `shader_globals/`:

```ini
[shader_globals]

psx_amount={
"type": "float",
"value": 1.0
}
psx_affine={
"type": "float",
"value": 0.0
}
```

Every material that uses the shader reads `psx_amount`, so the settings
slider changes the whole game at once without touching a material resource,
and without a per-frame shader parameter push. The authoritative value lives
in GDScript (`WsPsx`) because the headless runner uses the dummy renderer,
where the globals are registered but cannot be read back. The player picks
the amount in the settings panel; the affine warping is a separate toggle and
is off by default, because warped textures are hard to read.

## 2. Memory budget (hard limits)

```
Peak RSS        ≤ 2.5 GB target   |  3.0 GB hard-fail warning  |  4.0 GB absolute ceiling
VRAM            ≤ 512 MB
Internal buffer 480×270 × 4 bytes ≈ 0.5 MB
```

### Allocation rules
- **Cell streaming** — every section is a cell. Resident set = current cell +
  one prefetched cell + a 2-cell hysteresis (unload only when 2 cells away).
- **Per-cell budgets:** ≤ 45 MB textures, ≤ 20 MB meshes, ≤ 12 MB audio.
  Enforced by a CI script that walks the exported PCK and reports per-cell size.
- **No runtime mesh generation** (except ≤ 64-tri decals).
- **Pooled** regulators, parcels, damage numbers, pickups, VFX, audio players.
- **No allocation in `_process`/`_physics_process`** — use preallocated arrays.
- **Texture atlases:** max 8 resident atlas pages per cell; VRAM compressed
  (`VRAM Compressed`) for colour, lossless for masks.

### Streaming implementation
```
CellManager
  ├─ current_cell
  ├─ prefetch_cell
  └─ retired_cells (≤ 2, unloaded after hysteresis)
```
Cells load asynchronously with `ResourceLoader.load_threaded_request()`. Level
geometry is merged per cell into a small number of `MultiMeshInstance3D` /
`MeshInstance3D` nodes to keep draw calls ≤ 220.

## 3. Gameplay architecture

### Movement space
- Gameplay is simulated in full 3D on the **X/Z ground plane**, with Y for
  height. There is no fixed forward axis.
- The camera is a third-person orbit rig on Lancer. Movement is
  camera-relative: `W`/`S` walk along the camera's facing, `A`/`D` strafe
  across it.
- The view the game is played in is first person. The camera sits on the
  eye at 1.7 m, the mouse is captured and locked to the middle of the screen
  while a run is on, and a dot in the middle of the frame is the crosshair.
  `docs/FPS_VIEW.md` has the ground plan for building it.
- Architecture is authored at full depth: foreground occluders, walkable
  ground, mid-ground structures, the city shell and a skybox.
- Entities use `PhysicsBody3D` in 3D. The player's `CharacterBody3D` keeps
  horizontal velocity in X/Z and vertical velocity in Y.

### Player controller
Custom `CharacterBody3D` (not `SourcePlayer`) — speed platforming needs
frame-exact control:

| Feature | Value |
| --- | --- |
| Max run speed | 14.0 m/s |
| Ground accel / decel | 90 / 60 m/s² |
| Air accel | 32 m/s², capped contribution 2.2 m/s (air-strafe) |
| Gravity | 60 m/s² (jump apex ≈ 2.0 m) |
| Jump velocity | 15.5 m/s, variable height, 8f coyote, 10f buffer |
| Slide | 0.45 s, friction 6, starts above 5.0 m/s, cancels into jump |
| Wall-jump | 2-frame window, +0.8 m/s, chain of 3, **hard ceiling 16.4 m/s** |
| Wall-jump, `wall_kiss_chain` Fracture active | chain of 5, ceiling 18.0 m/s |
| Filament lock-on | 0.25 s cone assist, 18° half-angle |
| Fixed timestep | 60 Hz physics, `max_physics_steps_per_frame` 4 |

The numbers above are duplicated in `addons/windshear/core/ws_tuning.gd`, and
`tests/test_tuning.gd` asserts the two against each other. They are the
same document in two forms. If you find yourself editing one and not the
other, the test will tell you, which is the whole point of writing it that
way.

**Wall-jump definition.** A slide opens a 2-frame window. Touching **any
wall** inside that window arms the jump. Jumping on that frame adds +0.8 m/s of
horizontal speed, and the ground acceleration is skipped on that frame so it
cannot eat the boost again. A chain is three wall-jumps long, and it expires
after 30 frames without a kiss.

The **16.4 m/s ceiling** is a hard horizontal speed limit on the boost:
14.0 (run) + 3 × 0.8 (a full chain) = 16.4. It was not in the original
design — it was found by the discovery harness, which reported a wall-kiss
chain reaching 26.00 m/s before the ceiling existed. See
`docs/dev_stage_1.md` §4. The ceiling keeps the full designed value of the
technique and stops it being farmed.

The shipped `wall_kiss_chain` Fracture is what the old 18.0 m/s belongs to.
Its registry text says the chain "stacks to ×5" and registry text never
changes once it has shipped, so the Fracture raises the cap to five and the
ceiling to 18.0 m/s (14.0 + 5 × 0.8). The controller exposes
`enable_wall_kiss_chain_fracture()` for it. The base game is three
wall-jumps and 16.4 m/s; the Fracture is the fifth wall-jump.

I want to be clear about why the base number moved down rather than the
Fracture moving up. The cap was three all along in the design, and the
shipped registry text was the only place saying five. Reconciling it the
other way would have taken a explicit product decision, and nobody made one.

### Input map

`[input]` in `project.godot` is generated by `tools/setup_input_map.gd`. Never
hand-edit it, and never edit the generated section without editing the
generator, because the next run of the generator undoes you.

The scheme is fixed and `tests/test_input_map.gd` enforces it:

| | |
| --- | --- |
| Move | `A` `D` |
| Slide | `Ctrl`, or `S` |
| Jump | `Space`, or `W` |
| Ledge grab | `Q` |
| Interact | `E` |
| Filament | `F` |
| Primary fire | left mouse button |
| Alt fire | right mouse button |
| Camera | the mouse; the right stick on a pad |

The mouse does the camera and the two triggers, because the mouse is already
in the hand doing the camera. Everything else is on the keyboard, and the
keyboard leaves the camera alone. WASD is a normal walk-around cluster, and
the walk follows the camera. The generator also deletes actions that are no
longer in its table, so a renamed action cannot linger in `project.godot`
forever.

### Determinism
- Fixed 60 Hz physics tick, `Engine.physics_ticks_per_second = 60`.
- `physics_jitter_fix = 0.0`. Godot's default jitter fix nudges the timestep
  so that physics lines up with the frame rate. It is a good idea for a
  smooth game and a bad idea for a game where a run is compared frame by
  frame.
- No `randf()` in gameplay logic — seeded `RandomNumberGenerator` per section
  (`section_id` hash) so replays and ghosts match.
- Ghosts record position/rotation/frame at 20 Hz, delta-compressed
  (see §5).
- The movement controller is a pure function of its input and its previous
  state: `simulate(delta, input)`. It does not read the clock, does not
  touch the scene tree beyond the physics queries it needs, and does not
  allocate.

### Movement research
The shapes of these numbers come from Quake, GoldSrc, Doom, ULTRAKILL and
GRACE. The cited sources, evidence confidence, folklore corrections, and
design synthesis are in [`docs/MOVEMENT_RESEARCH.md`](docs/MOVEMENT_RESEARCH.md).

One rule governs the whole file: **a movement glitch is never implemented on
purpose.** The controller implements the verbs and nothing else. The
techniques that exist are consequences of the physics that the discovery
harness finds, not features that were built to be found.

## 4. Level and section format

```
res://
  data/
    sections/            # 25 chapters × 12 sections
      cP1/sP1_01.tscn    # the five-chapter Fracture Year prequel
      ...
      c20/s20_12.tscn
    story/               # STORY LAYER — swappable by Editions
      c1/s1_01.beat.json
      dialogue/en.json
      endings.json
    cast.json            # the cast, their pronouns and their acts
    arsenal.json         # weapons, usable items, map utilities
    enemies.json         # the Concord roster
    player.json          # health, overheal, the speed thresholds
    fractures.json
    schedule.json        # Concord gate/regulation schedules
  world/                 # shared world geometry + rules
  addons/windshear/      # the open-source game code
```

### Section scene
A section is a `PackedScene` containing:
- geometry (merged meshes, per-cell)
- colliders
- `SectionTrigger` volume (start/end, checkpoint, split marker)
- `RegulationGate` nodes (schedule-driven)
- `WindVolume` nodes (thermals, crosswinds, dead zones)
- `FilamentAnchor` nodes (zip / ring / hold)
- `Checkpoint`, `Parcel`, `RegulatorDrone`, `WindRegulator`, `HazardVolume`
- `BeatDirector` nodes (story beats, timed to section time)

### Story layer (Edition-swappable)
`story/` is data-only. The engine resolves beats against section IDs and actor
IDs. An Edition swaps the directory; the game detects it at boot and lists it in
the Edition browser.

## 5. Speedrun systems

| Feature | Implementation |
| --- | --- |
| Timer | `SectionTimer` per section; splits on section entry; frame-accurate (60 Hz) |
| Splits UI | Overlay, `Tab`, shows per-section times and deltas vs PB |
| Ghost (Recall) | Records player transform at 20 Hz into a `PackedFloat32Array`, delta + varint compressed; ~40 KB/minute |
| Ghost playback | Sampled and interpolated between keyframes |
| PB tracking | Per-section best times, stored in `user://` (JSON) and exportable as `.wbsplit` |
| Route sharing | Route files (`.wbroute`) are plain text: section, entry frame, movement flags — shareable via repo/clip |
| Style scoring | Event-driven: chains, threads, no-touch; per-section and per-run |
| Precision mode | Flags in the run config: `fractures=false`, `style=false`, `assists=false` |

### Leaderboards
**No built-in server.** The game ships with:
- local PB + ghost storage
- export/import of `.wbsplit` / `.wbroute` files
- a documented HTTP format so the community can run their own board
  (the game can POST to a configurable URL, opt-in, no telemetry by default)

This keeps the game free, server-free, and fork-friendly.

## 6. Fracture implementation

Each Fracture is a small, self-contained module with a stable id:

```gdscript
class_name Fracture
extends RefCounted

@export var id: StringName          # stable forever
@export var display_name: String
@export var category: StringName    # speed | precision | routing
@export var speedrun_legal: bool = true

func apply(ctx: FractureContext) -> void: ...
func should_trigger(ctx: FractureContext) -> bool: ...
```

Registry in `data/fractures.json`, loaded at boot. Policy: **never remove or
alter a shipped Fracture**; only add. Fracture logic lives outside gameplay
systems so it can be patched without touching core movement.

The **Fracture Codex** in-game is populated from `fractures.json` (official) plus
community submissions from a JSON file the player can drop into `user://`.
Submissions are name + description + optional clip link; the game merges them
without network access unless the player opts in.

## 7. Cutscene system

Two modes, both diegetic and both keeping the camera on Lancer:

```gdscript
enum BeatMode { AMBIENT, MAJOR }
```

| | AMBIENT | MAJOR |
| --- | --- | --- |
| Player control | Full | Locked |
| World time | Normal | `Engine.time_scale = 0` (scripts use unscaled time) |
| Camera | Normal rig on Lancer | Same rig, locked to Lancer's last position, slight push-in |
| Exit | Any time, no penalty | Beat script ends → 2-frame count → resume |

Implementation notes:
- Beat scripts are `AnimationPlayer`-driven on in-frame actors.
- `Engine.time_scale = 0` pauses physics and gameplay, but `process_mode` on
  beat actors is `PROCESS_MODE_ALWAYS` and uses `Time.get_ticks_usec()` for
  unscaled timing.
- The camera rig is parented to Lancer, so freezing Lancer freezes the framing
  automatically. No camera nodes are ever handed to a cutscene.

## 8. Accessibility

- Remappable input (keyboard + controller), no motion-only verbs. The mouse
  carries the camera and the two triggers; everything else is on the keyboard,
  and nothing on the keyboard turns the camera.
- Coyote time / input buffer / corner correction toggles ("Assist" presets:
  Off / Standard / Relaxed) — the assist state is recorded in the run config so
  leaderboards stay honest.
- Colorblind-safe palettes; the wind direction is communicated by particle
  direction, not hue.
- Subtitles always on, scalable, speaker-coloured.
- Screen-shake, flash, and chromatic aberration sliders.
- No flashing above 3 Hz; wind/flash effects respect photosensitivity settings.
- Timer can be hidden for casual play.

## 9. Build and CI

- **Godot 4.7.2** (Compatibility renderer), exported templates pinned in the repo.

### Engine version pin

| Item | Value |
| --- | --- |
| Engine | Godot **4.7.2** |
| Linux binary used in CI / on Arch | `godot 4.7.2.stable.arch_linux.ed1daf0bf` (`pacman -S godot`) |
| Renderer | Compatibility (OpenGL) |
| Export templates | 4.7.2.stable, pinned in the repo |
| Physics | Jolt, fixed 60 Hz tick |

CI and the Arch PKGBUILD must use the **same** engine build as the project
(`project.godot → config/features` records `4.7`). When the engine is bumped:
update this table, `project.godot`, the export templates and the `NOTICE`
header in one commit, so contributors never hit a version mismatch.
- Headless CI: import, unit tests, memory-budget check per cell, smoke test
  that boots each chapter and runs a scripted 60-second route.
  - The test runner is a **scene** (`res://tests/run_all.tscn`), not a
    `--script` main loop: a script main loop does not register the autoload
    singletons as global identifiers, so `WsGame` fails to compile there.
  - The import step is mandatory. Without it there is no `.godot/`, no
    global class cache and no imported textures.
- Release artifacts: Linux (x86_64), Windows (x86_64), plus a "no assets" build
  for developers.
- Deterministic builds: fixed import order, no timestamps in exported data.

## 10. Open-source structure and licensing

```
windshear/
  addons/windshear/        # game code (GPL-2.0-or-later)
  world/                   # shared world content (CC-BY-SA 4.0)
  data/story/              # official story layer (CC-BY-SA 4.0)
  data/sections/           # levels (CC-BY-SA 4.0)
  editions/                # community editions (each must be open source)
  tools/                   # dev tooling, memory budget checker
  docs/
  LICENSE                  # GNU GPL v2 (verbatim)
  NOTICE                   # attribution for bundled third-party assets
```

### Licensing summary
| Part | License | Effect |
| --- | --- | --- |
| Game code | **GPL-2.0-or-later** | Anyone who ships a version built on this code must also ship its source under the same terms. Godot 4.7 is MIT → compatible. |
| Content (levels, models, audio, art) | **CC-BY-SA 4.0** | Reusable in other games, commercial included; derivatives share alike. |
| Official story layer | **CC-BY-SA 4.0** | Alternate storylines inherit share-alike. |
| Community Editions | **Open source required** for the official index | Code is GPL by inheritance; data-only Editions are bound by the share-alike on reused assets. |

### What GPL means for the build and the runtime
- **Source conveyance:** the public repo + release tag *is* the corresponding
  source for every build (§3). No extra source archive needed.
- **No restrictions on running:** no DRM, no activation, no mandatory
  online check, no phone-home. Those would violate the license.
- **No proprietary-linking exception.** Closed-source games cannot link the
  engine. That is intentional: it is the mechanism that keeps community
  versions open.
- **Contributions:** every PR lands under GPL-2.0-or-later (see
  `CONTRIBUTING.md`). Asset PRs land under CC-BY-SA 4.0.
- **Third-party code:** everything vendored goes in `NOTICE` with its own
  license and must be GPL-2.0-compatible. Godot (MIT), GUT/GdUnit (MIT),
  and any CC0 art must be listed.

### Edition format
```
my-edition/
  edition.json      # { "id", "name", "author", "story_path", "description",
                     #   "license": "GPL-2.0-or-later", "source_url": "..." }
  story/            # optional override of data/story
  assets/           # optional replacement art
```

The Edition browser reads `license` and `source_url` from `edition.json`. The
official index refuses to list an Edition that doesn't declare an open license
or doesn't point at its source. Locally installed Editions still load — the
game never blocks what you run, the *official index* only curates.

No accounts, no DRM, no mandatory network.

### Versioning and the copyleft
- Every release is a Git tag; the tag is the "corresponding source" for the
  matching binary.
- Fracture behaviour is part of the game's identity and is version-stable
  (§6), so forks stay compatible with community routes.
- A community fork that wants different licensing can't relicense the GPL code
  — but it *can* write a new game with the same ideas and no borrowed code or
  assets. That's the intended freedom.

## 11. Risk register

| Risk | Mitigation |
| --- | --- |
| Speed feel is hard to tune | Milestone 0 is a 2-week pure-movement prototype with a hard "it feels good" gate |
| Fractures feel like bugs to reviewers | Ship an official Fracture Codex, name them, and explain the design intent in-game |
| Open-sourcing lets a fork dilute the identity | Trademark + clear naming; editions are explicitly supported and credited |
| GPL blocks a commercial closed-source game people want | Accepted deliberately — the copyleft is the point. A closed-source alternative is allowed if it borrows no code or assets |
| RAM creep from community content | Per-cell budgets + CI gate + a "mod content must respect budget" rule in the contribution guide |
| Time-stop cutscenes feel cheap | Keep them rare (8–12 per game), in-frame, and let the world visibly freeze |
| The input scheme drifts away from what was agreed | `tests/test_input_map.gd` reads the map and fails the build on any action without a keyboard binding |
| A wall-jump chain gets farmed for a bigger number | The hard ceiling of 16.4 m/s, plus the characterisation suite that plays the technique against the controller |

The last two are the ones that actually happened. Everything else in this
table is a guess.
