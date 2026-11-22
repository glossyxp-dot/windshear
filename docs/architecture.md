# WindShear — Architecture

How the codebase is put together and why it is put together that way.

The short version: the game code is a small, self-contained addon with no
dependencies outside `addons/windshear/`, the content is data, and the
boundary between the two is enforced by a test.

---

## 1. The shape of the repository

```
windshear/
  project.godot          # engine settings, the input map, the shader globals
  addons/windshear/      # the game code — GPL-2.0-or-later
    core/
      ws_tuning.gd       # every movement number, in one file
      ws_game.gd         # the autoload: mode, run clock, settings
    movement/
      lancer_input.gd    # one frame of input
      lancer_controller.gd # the movement simulation
      camera_rig.gd      # the camera that never leaves Lancer
    render/
      ws_psx.gd          # the PSX dial
      ws_psx.gdshader    # the PSX shader
  world/                 # shared world geometry — CC-BY-SA 4.0
    greybox/             # the movement test rig
  ui/                    # the menu and the theme
  data/                  # the content that Editions may swap
    fractures.json
    schedule.json
    sections/
    story/
  editions/              # the format community Editions use
  tools/                 # developer tooling
    setup_input_map.gd
    cell_budget_checker.gd
  tests/                 # the test suite
  docs/                  # this directory
```

The licence boundary is the important part. `addons/windshear/`, `world/` and
`ui/` are the game code and are GPL-2.0-or-later. `data/` and `editions/`
are content and are CC-BY-SA 4.0. The split is not a convention — the
code-policy test checks that every `.gd` file under `res://` carries the GPL
notice.

---

## 2. The four modules

### `core/ws_tuning.gd`

Every number that defines how the game feels. One file, no dependencies, no
scene tree access. It is safe to load from a worker thread.

The rule is that this file and `TECH_SPEC.md` §3 are the same document in two
forms. `tests/test_tuning.gd` reads the Markdown and asserts that the
constants match, so they cannot drift apart silently.

### `movement/lancer_controller.gd`

The simulation. It extends `CharacterBody3D` and exposes one method that
matters:

```gdscript
func simulate(delta: float, input: LancerInput) -> void
```

Everything else is private. The controller does not read the clock, does not
read `Input`, does not allocate, and does not look at the scene tree beyond
the physics queries it needs.

This shape is what makes the game testable at the level the game cares
about. A speedrunner's complaint is always about a frame — "the coyote time
is one frame short" — and a frame-accurate test is the only thing that can
answer it.

### `movement/camera_rig.gd`

The camera is parented to Lancer. It never leaves. It does pitch clamping
(±80°), yaw wrapping, and a speed dolly that pulls back as the player gets
faster.

There is no cutscene camera and there never will be. `TECH_SPEC.md` §7 says
the camera stays on Lancer during a MAJOR beat, and the rig is the only
camera in the project.

### `core/ws_game.gd` — the autoload

Registered in `project.godot` as `WsGame`. It owns the handful of values that
have to survive a scene change: the game mode, the run clock, and the
player's settings.

It deliberately has **no `class_name`**. The autoload is registered under the
name `WsGame`, and a global class with the same name would shadow it. That
is the sort of small thing that costs an afternoon once.

Settings are read from `user://settings.cfg` on boot and written back when
the player leaves the settings panel or quits. Missing keys keep their
defaults, so a settings file from an older build keeps working.

---

## 3. The data layer

Everything that can be a table, is a table.

| File | What it holds |
| --- | --- |
| `data/fractures.json` | The twelve Fractures, with stable ids and their legality flags |
| `data/schedule.json` | The Concord gate and regulation schedules, per section |
| `data/sections/index.json` | The 6 × 12 section index, with difficulty and par times |
| `data/story/dialogue/en.json` | The dialogue |
| `data/story/beats/*.beat.json` | The story beats, AMBIENT and MAJOR |
| `data/story/endings.json` | The endings table |

JSON files cannot hold comments, so each one carries a `_meta` block with
its SPDX identifier and its schema version instead. The schema is documented
next to the data, in `data/story/README.md` and `data/sections/README.md`.

The rule for the Fractures is in `TECH_SPEC.md` §6 and it is a policy, not an
implementation detail: **a shipped Fracture is never removed or altered,
only added.** Routes recorded against version 1 of a Fracture have to keep
working, so the Fracture has to keep behaving the same way.

### Editions

An Edition is a directory with an `edition.json` and optional `story/` and
`assets/` overrides. It is data only — no code. The format is documented in
`editions/README.md`.

The official index refuses to list an Edition that does not declare an open
licence and does not point at its source. Locally installed Editions always
load; the index curates, the game does not block.

---

## 4. The PSX system

The PSX look is four separate artefacts of the 1990s that happen to sit
together:

1. **Vertex snapping** — the rasteriser rounded every vertex to the nearest
   pixel of a 480×270 buffer, and the geometry wobbled as it moved.
2. **Affine texturing** — the UVs of a triangle were interpolated in screen
   space instead of in perspective, so flat surfaces visibly swam.
3. **5-bit colour** — the colour buffer was 15 bits, five per channel, so
   gradients banded.
4. **Ordered dithering** — a 4×4 Bayer pattern hid the banding.

`addons/windshear/render/ws_psx.gdshader` implements all four, and the
player picks how much of it there is.

### The global uniform trick

The amount is a **global shader uniform**, registered in `project.godot`:

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

Every material that uses the shader reads `psx_amount`, so moving the slider
changes the whole game at once without touching a single material resource
and without a per-frame shader parameter push. That matters for the memory
budget and for the frame cost, and it means a hand-made material only has to
set its colour and its texture.

The authoritative copy of the value lives in GDScript (`WsPsx`), not in the
renderer. The headless test runner uses the dummy renderer, where
`RenderingServer.global_shader_parameter_get()` returns `null` — the globals
are registered, but they cannot be read back. The tests therefore assert
against the GDScript value, and the renderer is only ever written to.

The affine warping is off by default. Warped textures are hard to read, and
readability wins until the player asks otherwise.

---

## 5. Determinism

Three rules, all of them enforced by the test suite:

1. **Fixed 60 Hz physics.** `physics_ticks_per_second = 60`,
   `max_physics_steps_per_frame = 4`.
2. **`physics_jitter_fix = 0.0`.** Godot's default jitter fix nudges the
   timestep so that physics lines up with the frame rate. It is a good idea
   for a smooth game and a bad idea for a game where a run is compared
   frame by frame.
3. **No global random numbers in gameplay.** Section randomness comes from
   `WsGame.rng_for_section(section_id)`, which seeds a
   `RandomNumberGenerator` with an FNV-1a hash of the section id. The hash is
   written out by hand rather than using the engine's string hashing, so it
   does not depend on the engine's internals and stays identical across
   builds and platforms.

The code-policy test scans `addons/windshear/`, `world/` and `ui/` for
`randf()`, `randi()`, `randf_range()`, `randi_range()`, `randfn()` and
`randomize()`, with comments stripped first so that a sentence in a
docstring cannot trigger it.

---

## 6. The 2.5D plane

The gameplay is on the XY plane. The player's Z velocity is forced to zero
every frame, and the level geometry is placed on that plane.

The depth is visual, and it is staged: foreground occluders, the play plane,
mid-ground, the city shell, the skybox. The greybox has a guide wall at
z = -0.5 — a side wall rather than a back wall — because the wall-kiss needs
a wall whose normal points along Z.

This is checked by the greybox suite and by the discovery suite, which
asserts that no technique ever produces a Z velocity.

---

## 7. The tools

| Tool | What it does |
| --- | --- |
| `tools/setup_input_map.gd` | Writes the `[input]` section of `project.godot` |
| `tools/cell_budget_checker.gd` | Walks the project and reports the per-cell size against the budget |

The input map is generated rather than hand-written because the hand-written
form is a wall of `Object(InputEventKey, ...)` lines that nobody can review.
The tool preserves the comment header of `project.godot` and rewrites only
the section it owns.

```bash
godot --headless --path . --script res://tools/setup_input_map.gd
```

Note that `ProjectSettings.save()` drops any setting that equals the engine
default, so a full save will quietly remove things. The input tool does not
use it.

---

## 8. Things that are deliberate, and look like mistakes

- **The test runner is a scene, not a script.** A `--script` main loop does
  not register the autoload singletons as global identifiers, so `WsGame`
  does not compile there. See `docs/testing.md` §5.
- **The autoload has no `class_name`.** A global class with the same name
  would shadow it.
- **Scripts `preload` their dependencies instead of using global class
  names.** The global class cache lives in `.godot/`, which is not in the
  repository, so a fresh clone has no class names until the project has been
  imported once.
- **The controller's `simulate()` is called explicitly.** The physics
  callback does not call it, because the tests call it directly and the two
  paths must be the same path.
- **The greybox materials are `StandardMaterial3D`, not the PSX shader.** All
  the visual work is done by hand outside the engine, and the shader is
  shipped ready to be used rather than imposed on placeholder art.
