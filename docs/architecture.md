# WindShear: architecture

The codebase, and the reasons behind its shape.

The game code is a small addon with no dependencies outside `addons/windshear/`. Everything else is data, tooling or documentation, and a test keeps code from leaking into the data side.

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
      speed_meter.gd     # speed in metres per second, current and peak
    world/
      ws_section_manager.gd # loads the section that is running
    render/
      ws_psx.gd          # the PSX dial
      ws_psx.gdshader    # the PSX shader
  world/                 # shared world geometry — CC-BY-SA 4.0
    greybox/             # the movement test rig
    kit/                 # the pieces a section is built from
    playground/          # the room where a section is played by hand
  ui/                    # the menu, the theme and the UI kit
  data/                  # the content that Editions may swap
    cast.json             # the cast, their pronouns and their acts
    arsenal.json          # weapons, usable items, map utilities
    enemies.json          # the Concord roster
    player.json           # health, overheal, the speed thresholds
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

Licensing is enforced rather than left to memory. Runtime code under `addons/windshear/`, `world/` and `ui/` is GPL-2.0-or-later. Content in `data/` and `editions/` is CC-BY-SA 4.0, as is the shared world geometry. The code-policy test checks that every `.gd` file under `res://` carries the GPL notice.

---

## 2. The four modules

### `core/ws_tuning.gd`

Every number that defines how the game feels lives here. There are no dependencies and no scene-tree access, so the file is safe to load from a worker thread.

`TECH_SPEC.md` §3 and this file are two forms of the same document. `tests/test_tuning.gd` reads the Markdown and checks the constants against it. If either side changes alone, the build complains.

### `movement/lancer_controller.gd`

This is the simulation. It extends `CharacterBody3D` and has one public method that matters:

```gdscript
func simulate(delta: float, input: LancerInput) -> void
```

Everything else is private. The controller doesn't read the clock or `Input`, doesn't allocate, and doesn't inspect the scene tree apart from the physics queries it needs.

That shape gives us tests at the level the game actually cares about. When a speedrunner says the coyote time is one frame short, only a frame-accurate test can settle the argument.

### `movement/speed_meter.gd`

Speed is measured in metres per second. The meter keeps the current horizontal speed and the peak since the last reset. Every speed number in the project uses the same unit because an engine-local number is impossible to discuss or compare.

The greybox HUD reads the meter, the mechanics reference quotes it, and `tests/test_speed_meter.gd` checks the reading, peak, reset and unit string.

### `movement/camera_rig.gd`

The camera is parented to Lancer and stays there. It orbits the body: yaw and pitch rotate the rig around Lancer, it clamps pitch at ±80°, wraps yaw, and dollies back as the player gains speed.

The rig reads mouse motion and the right stick. The mouse is the camera, by pixels, and it turns at 0.0022 rad per pixel. The right stick is the other route, by rate, at 3.0 rad/s at full deflection. Nothing on the keyboard touches the camera. A keyboard camera and a mouse camera fight over the same view, and the player only ever wanted one of them, so the keyboard route was removed rather than tuned.

The controller reads the rig's yaw every frame and uses it to turn WASD into a world direction. That is the whole trick behind camera-relative movement: the camera orbits, and the walk follows the orbit.

The mouse also owns the two triggers, since it's already in the hand doing the camera. Everything else is on the keyboard. The gamepad follows the same split: left stick and D-pad move, A jumps, B slides, X grabs a ledge, Y interacts, the right shoulder throws the filament, the right trigger is primary fire, the left trigger is alt fire, and the right stick is the camera.

There's no cutscene camera. `TECH_SPEC.md` §7 keeps the camera on Lancer during a MAJOR beat, and this rig is the only camera in the project.

### The input map

The `[input]` section of `project.godot` is generated by `tools/setup_input_map.gd`. Never hand-edit it. A handwritten input section is a wall of `Object(InputEventKey, ...)` lines that nobody reviews; the generator fits on one screen.

The current scheme is:

```text
W / S    walk forward, walk back
A / D    strafe left, strafe right
Ctrl     slide
Space    jump
Q        ledge grab
E        interact
F        filament
mouse    camera
LMB      primary fire
RMB      alt fire
```

The mouse handles the camera and both triggers because it's already in the hand pointing at the target. The rest stays on the keyboard. WASD is a normal walk-around cluster, and because movement is camera-relative, turning the view turns the walk.

The generator also deletes retired actions. If an action is renamed, the old name can't linger in `project.godot`. `tests/test_input_map.gd` checks the scheme itself and confirms that the camera rig reads the mouse and the right stick and no key at all; an action nobody reads doesn't do anything.

I added the delete step after renaming `mantle` to `ledge_grab` and finding that the old action was still in the file, still bound, and still being read by nothing. It's the kind of thing that lives for a year before somebody notices.

### `core/ws_game.gd` — the autoload

`project.godot` registers this as `WsGame`. It owns the few values that need to survive a scene change: game mode, run clock and player settings.

It has no `class_name`, on purpose. The autoload is registered as `WsGame`, and a global class with the same name would shadow it. Small thing. It still costs an afternoon once.

Settings are read from `user://settings.cfg` on boot, then written back when the player leaves the settings panel or quits. Missing keys keep their defaults, so a settings file from an older build still works.

### `core/ws_tweak.gd` — the second autoload

`project.godot` registers this as `WsTweak`. It holds the table of movement knobs the workbench shows, the live values you have moved off the documented ones, and the profile file.

The canonical numbers stay in `ws_tuning.gd`, and the test suite pins them. `WsTweak` sits on top: the controller and the camera rig read their numbers through it, so a slider that moves changes the simulation on the next frame.

Two rules keep it honest. Overrides are never loaded automatically, only by the workbench, so the headless suite always runs on the documented numbers even if somebody left a saved profile behind. And the profile lives in the user data folder, outside the repository, because a tuned number is not canon until somebody writes it into the code and the spec.

The workbench itself is `tools/movement_workbench.tscn`. The panel is built in code out of the knob table rather than being a scene file, because then adding a knob is one entry and no scene editing. `tests/test_workbench.gd` checks that every knob still starts on the constant it claims to come from, that a knob reaches the live simulation, and that the suite never writes over the real profile.

### The level tools

`addons/level_tools/` is the editor side of making a section, and `world/kit/` is the kit itself.

The kit pieces are `@tool` scripts that make their mesh and their collision from the numbers in the Inspector. The mesh and the body are **internal children**, so they never appear in the scene tree and never end up in the saved scene. The scene file stays a handful of numbers.

`world/kit/ws_kit_point.gd` is the point entity. Its `kind` decides which properties the Inspector shows, through `_validate_property`. The kind is stored in the scene as a number, so the order of the enum is a file format and a new kind goes at the end. `tests/test_level_tools.gd` pins every number.

`world/kit/ws_section.gd` is the root of a section. It carries the section id and, if it wants to repeat them, the name, the difficulty and the par time the campaign index already says. It has an `@export_tool_button`, so the export is a button in the Inspector of the section root.

`addons/level_tools/ws_section_exporter.gd` reads a section scene and writes the data beside it. It is the same code behind the editor button, the dock and the headless run, so what the designer exports by hand and what CI checks cannot drift apart.

Two decisions in it are worth knowing about.

The **positions are relative to the section root**, not to the world. The section is placed in the world when it loads, so a position in world space would be applied twice. The point walks up its parents by hand, because `global_transform` cannot be read on a scene that is not in the tree and the exporter reads scenes that are not in one.

The **points are sorted by where they sit in the scene**. The order the points come out of the scene tree is not a promise, and a data file that reshuffles itself every export is a file nobody reviews.

The game loads the scene. The JSON is the mirror the tests compare against, so a scene that was changed and not exported fails the build instead of shipping data nobody looked at.

### The theme and the UI kit

`ui/theme/windshear_theme.tres` is the one place the look lives. It holds the colours, the borders and the font sizes, and five **theme type variations** that a control picks in the Inspector: `WsTitle`, `WsHeading`, `WsCaption`, `WsValue` and `WsPanel`.

A type variation without a base type is a style that does nothing, so the theme declares the base of each one and `tests/test_ui_contract.gd` checks it.

The pieces in `ui/kit/` are scenes that carry no script and no colour of their own. They are there so the designer has something to drag, not so the look is decided in two places.

`tests/test_ui_contract.gd` is the alarm. It checks that every style a screen asks for is a style the theme has, that every font size is one of the agreed ones, that a button has a focus style so a controller player can see what is selected, and that the kit fits inside 480 by 270.

### `world/ws_section_manager.gd` — the third autoload

`project.godot` registers this as `WsSections`. It is the other half of the level tools: the exporter writes the data, and the manager loads the scene the designer laid out.

It does two things. It reads `data/sections/index.json` once and knows where every section lives, and it holds the section that is running together with the three marker ids the trigger handed over: where the player starts, where the player ends and where the speedrun split goes.

The handshake is one line. `world/kit/ws_kit_point.gd` registers itself with the manager when it enters the tree, but only if it is the section trigger. The manager then checks that the id is in the index and that the three markers point at points that exist in the same section. A section that loads but cannot be finished is refused, and it says which marker is the one that points at nothing.

The check is deliberately the same one the exporter makes. The exporter refuses to write the data; the manager refuses to run it. Two doors, one rule.

The manager is a plain `Node` and it holds the section as a child. The section is therefore in the same world as the player, so the collision works and the checkpoints are in world space.

`world/playground/section_playground.tscn` is the room where a section is played by hand. It is the same manager the game uses, the same controller and the same camera rig as the greybox, and it puts the player at the start checkpoint of the section, so a checkpoint in the wrong place is obvious straight away.

`tests/test_section_runtime.gd` checks the seam: that the manager is there, that the section loads, that the trigger registers, that the geometry grew a body the player can stand on, that a section the index does not know about is refused, that a marker pointing at nothing is refused, and that the playground puts the player where the checkpoint says.

### `world/ws_schedule.gd` and `world/ws_gate_service.gd`

`data/schedule.json` says when every regulation gate in the campaign is open and when it is closed. `ws_schedule.gd` reads it and answers one question: what state is this gate in on this frame of the global clock. The functions are pure and static, because a replay has to get the same answer on every machine.

The rules are the ones the schedule file writes down. A gate that cycles works out where it is in its cycle, `local_frame = (global_frame + phase_offset_frames) mod cycle_period_frames`, and looks that frame up in its windows. A gate that does not cycle uses its windows as they are. A window is `start_frame` inclusive and `end_frame` exclusive, and a null `end_frame` is unbounded. A frame no window covers is closed.

The global clock is the run clock in `WsGame`, so a cycling gate keeps its rhythm from one section to the next.

`ws_gate_service.gd` is the part that touches the world. When a section loads, it finds every regulation gate point in it and gives each one a barrier: a mesh and a static body, as internal children of the point, so the saved scene stays a handful of numbers and the designer never has a mesh to clean up. A closed gate has its collision on and its barrier visible; an open gate has both off.

The manager owns the service, because the manager owns the running section. It updates the gates every physics frame against the global clock.

### `world/run/run_screen.tscn` and `ui/hud/section_hud.tscn`

The run screen is the loop: a section, the player in it, the objective on the screen, and the next section when the player gets to the end.

It loads the section through the section manager, puts the player at the start checkpoint, and watches the end checkpoint. Reaching it clears the section. The next section is the next one the designer has actually written, so the game keeps playing as more of the campaign is built, and the run ends when there is nothing left.

The HUD is a scene of its own, not a part of the run screen, so it can be opened and changed on its own. It asks the theme for every style it uses and owns no colours of its own.

`tests/test_playable_loop.gd` checks the whole thing: that the schedule reads and that a gate is open or closed on the frame it should be, that the campaign has an order, that a gate grows a body and opens and closes it, that the HUD says the objective, that the run screen plays the section and puts the player at the start checkpoint, and that reaching the end clears the section.

---

## 3. The data layer

I keep tabular data in tables.

| File | What it holds |
| --- | --- |
| `data/cast.json` | The cast: pronouns, acts, and who is allowed to speak |
| `data/arsenal.json` | Weapons, usable items and map-built utilities |
| `data/enemies.json` | The Concord roster, with health, damage and drops |
| `data/player.json` | Health, overheal and the speed thresholds the sensors read |
| `data/fractures.json` | The twelve Fractures, with stable ids and their legality flags |
| `data/schedule.json` | The Concord gate and regulation schedules, per section |
| `data/sections/index.json` | The 25 × 12 section index, with difficulty and par times |
| `data/story/dialogue/en.json` | The dialogue |
| `data/story/beats/*.beat.json` | The story beats, AMBIENT and MAJOR |
| `data/story/endings.json` | The endings table |

JSON can't hold comments, so each file carries a `_meta` block with its SPDX identifier and schema version. The schemas live beside the data in `data/story/README.md` and `data/sections/README.md`.

`TECH_SPEC.md` §6 describes the Fracture policy: **a shipped Fracture is never removed or altered, only added.** That's policy, not an implementation detail. A route recorded against version 1 of a Fracture still has to work, so the Fracture has to keep behaving the same way.

`tests/test_world_data.gd` reads all five files and checks that they still describe the same world: 300 sections numbered P1.01 to 20.12, a gate schedule covering every one, twelve Fractures, and beats and endings that point at ids which exist. It gathers all the problems into one failure message instead of filling the log with near-identical lines.

The prequel chapters are keyed `P1` to `P5`, and their sections look like `P3.07`. The grid therefore has two kinds of chapter key. JSON uses a string for the prequel and a number for the present day; the test normalises both before comparing them.

### The canon layer

Four more files sit beside the world data: `data/cast.json`, `data/arsenal.json`, `data/enemies.json` and `data/player.json`. Between them they hold the characters and their pronouns, the weapons, items and map utilities, the enemy roster, and the player's health and speed thresholds.

`tests/test_canon.gd` reads those files, the dialogue file and `GAME_DESIGN.md`, then checks that they agree. Every speaker must be in the cast. Lancer is the only pronounless character, and Lancer never speaks. Ilsa Renn says nothing in the prequel. Weapons must be available in the acts where they belong, and the main-game threat must never turn up in a Fracture Year chapter. The sprint speed, base wall-jump ceiling of 16.4 m/s and Fracture ceiling of 18.0 m/s must match `ws_tuning.gd`. Every weapon, enemy, item and character in the data must also be named in the design document.

Canon is data, and the prose is a copy of it. When the two disagree, the build fails rather than the argument.

### Editions

An Edition is a directory containing an `edition.json`, with optional `story/` and `assets/` overrides. It's data only; no code. The format is documented in `editions/README.md`.

The official index refuses to list an Edition unless it declares an open licence and points at its source. Locally installed Editions always load. The index curates; the game doesn't block.

---

## 4. The PSX system

The PSX look combines four separate pieces of 1990s rendering hardware.

The rasteriser rounded every vertex to the nearest pixel of a 480×270 buffer, which made geometry wobble while it moved. Affine texturing interpolated a triangle's UVs in screen space rather than in perspective, so flat surfaces swam. The colour buffer held 15 bits, five per channel, which made gradients band. A 4×4 Bayer dither pattern hid some of those bands.

`addons/windshear/render/ws_psx.gdshader` implements all four, and the player decides how much of the effect to use.

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

Every material using the shader reads `psx_amount`, so moving the slider changes the game in one step. No material resource has to change, and there's no per-frame shader parameter push. That keeps the memory budget and frame cost down. A hand-made material only needs its colour and texture.

The authoritative copy of the value lives in GDScript (`WsPsx`), not in the renderer. The headless test runner uses the dummy renderer, where `RenderingServer.global_shader_parameter_get()` returns `null`. The globals can be registered but can't be read back, so the tests assert against the GDScript value. We only ever write to the renderer.

Affine warping is off by default. Warped textures are hard to read, and readability wins until the player asks otherwise.

---

## 5. Determinism

Three rules hold the simulation still, and the test suite enforces all of them.

Physics runs at a fixed 60 Hz, with `physics_ticks_per_second = 60` and `max_physics_steps_per_frame = 4`. We also set `physics_jitter_fix = 0.0`. Godot's default jitter fix nudges the timestep so physics lines up with the frame rate. That's helpful for a smooth game and wrong for a game whose runs get compared frame by frame.

Gameplay can't use global random numbers. Section randomness comes from `WsGame.rng_for_section(section_id)`, which seeds a `RandomNumberGenerator` with an FNV-1a hash of the section id. The hash is written out by hand rather than using the engine's string hashing. That keeps it independent of engine internals and identical across builds and platforms.

The code-policy test scans `addons/windshear/`, `world/` and `ui/` for `randf()`, `randi()`, `randf_range()`, `randi_range()`, `randfn()` and `randomize()`. It strips comments first, so a sentence in a docstring can't trigger it.

---

## 6. Camera-relative movement

Gameplay happens on the X/Z ground plane, with Y for height. The controller turns WASD into a world direction using the camera rig's yaw: `W` walks along the camera's facing, `S` walks back, and `A`/`D` strafe across it. The input record carries the yaw, so `simulate()` stays a pure function and the replay harness does not need a scene tree.

Architecture is authored at full depth: foreground occluders, the walkable ground, mid-ground, the city shell and the skybox. The greybox has a guide wall at z = -10 and a wall on every side of the room. Any wall can arm a wall-jump now, because the player can hit one from any direction.

The movement suite checks the camera-relative directions, and the characterization suite checks that depth stays finite and that no wall normal breaks the speed ceiling.

---

## 7. The tools

| Tool | What it does |
| --- | --- |
| `tools/setup_input_map.gd` | Writes the `[input]` section of `project.godot` |
| `tools/cell_budget_checker.gd` | Walks the project and reports the per-cell size against the budget |
| `tools/export_sections.gd` | Writes the section data from the section scenes, or checks it |
| `addons/level_tools/` | The editor dock that does the same three things by hand |

The input map is generated because the handwritten form is a wall of `Object(InputEventKey, ...)` lines that nobody can review. The tool preserves every other setting and comment in `project.godot` and replaces only the section it owns.

```bash
godot --headless --path . --script res://tools/setup_input_map.gd
```

It has to call `ProjectSettings.save()` so Godot will serialise the input events. That rewrites the whole file and drops any setting equal to an engine default. So the tool reads the original text first, saves, then splices the new `[input]` section back into the original. Run it twice and the file comes out byte-identical.

---

## 8. Things that are deliberate, and look like mistakes

The test runner is a scene, not a script. A `--script` main loop doesn't register the autoload singletons as global identifiers, so `WsGame` won't compile there. See `docs/testing.md` §5.

The autoload has no `class_name`; a global class with the same name would shadow it.

Scripts `preload` their dependencies instead of using global class names. The global class cache lives in `.godot/`, which isn't in the repository, so a fresh clone has no class names until the project has been imported once.

The controller's `simulate()` is called explicitly. The physics callback doesn't call it because the tests call it directly, and both paths need to be the same path.

The greybox materials are files in `assets/materials/`. They're `ShaderMaterial` resources using the PSX shader, loaded through `material_override` so the Inspector can find them. A material buried inline in a scene can't be edited once and reused, so the test suite rejects one.
