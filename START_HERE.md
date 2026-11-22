# WindShear — Start Here

The design is locked (`GAME_DESIGN.md`, `TECH_SPEC.md`). This is the shortest
path from "documents exist" to "a playable greybox".

---

## Step 0 — Create the Godot project (you, ~5 minutes)

Godot → **Create** → *Project name* `WindShear` → *Path* wherever you want it
(keep it on the same drive as this repo) → **Renderer: Compatibility** →
**Create & Edit**.

Then set these **before** anything else:

**Project Settings → Display → Window**
| Setting | Value |
| --- | --- |
| Viewport Width / Height | `480` / `270` |
| Window Width / Height Override | `1280` / `720` |
| Stretch Mode | `canvas_items` |
| Stretch Aspect | `keep` |
| VSync Mode | Enabled |

**Project Settings → Rendering**
| Setting | Value |
| --- | --- |
| Rendering Method | `gl_compatibility` |
| Textures → Canvas Textures → Default Texture Filter | **Nearest** |
| Environment → Defaults → Clear Color | `#000000` |

**Project Settings → Physics**
| Setting | Value |
| --- | --- |
| 3D Physics Engine | **Jolt Physics** |
| Common → Physics Ticks Per Second | `60` |
| Common → Max Physics Steps Per Frame | `4` |

**Project Settings → Physics → 2D** is irrelevant for now; 3D only.

---

## Step 1 — Repo scaffold (WindShear's job, ~5 minutes)

Copy the tree from `TECH_SPEC.md` §10 into the new project:

```
WindShear/
  addons/windshear/     # game code (GPL-2.0-or-later)
  world/                # shared world content (CC-BY-SA 4.0)
  data/story/           # official story layer (CC-BY-SA 4.0)
  data/sections/        # levels (CC-BY-SA 4.0)
  editions/             # community editions
  tools/                # dev tooling + cell budget checker
  docs/
  tests/                # headless test runner
  LICENSE               # GNU GPL v2 (verbatim) — copy from this folder
  NOTICE                # copy from this folder
  assets/               # icon.svg / icon.png — copy from this folder
```

Two rules that must hold from the very first commit:

1. **Every `.gd` file starts with the GPL-2.0-or-later header:**
   ```gdscript
   # WindShear — <file purpose>
   # Copyright (C) 2026 the WindShear contributors
   #
   # This program is free software; you can redistribute it and/or modify it
   # under the terms of the GNU General Public License as published by the
   # Free Software Foundation; either version 2 of the License, or (at your
   # option) any later version.
   #
   # This program is distributed in the hope that it will be useful, but
   # WITHOUT ANY WARRANTY; without even the implied warranty of
   # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
   # Public License for more details.
   ```
2. **`project.godot` records the engine**: `config/features` must contain `"4.7"`.

---

## Step 2 — Lock the UI visually (you, then WindShear)

The UI reference tool turns into a Godot Theme + scene:

```
tools/ui_reference_editor.html   →  Export .css  →  windshear_ui_reference.css
```

Hand that file over and you get back:
- `ui/theme/windshear_theme.tres` — every colour, radius, font size, hover /
  focus / pressed StyleBox
- `ui/main_menu/main_menu.tscn` — the node tree, every element at the same
  coordinates, still editable by hand in the editor

Same for `assets/icon.svg` → project icon + menu title art.

---

## Step 3 — Milestone 0: the movement prototype (2 weeks)

`GAME_DESIGN.md` §14 Milestone 0 — "Does it feel good?"
Gate: **5 external testers say the movement is satisfying unprompted.**

> **This step is done in code.** The runner, the controller, the greybox and
> the camera rig are all in the repository, and the discovery harness has
> already found one bug in the wall-kiss (§4 of `docs/dev_stage_1.md`). What
> is left is the part that need humans: five testers, and a filament
> prototype.

Build order:

| # | Deliverable | Notes | State |
| --- | --- | --- | --- |
| 1 | `tests/run_all.tscn` headless runner + a CI cell-budget checker | every later step depends on it | done |
| 2 | `addons/windshear/movement/lancer_controller.gd` | `CharacterBody3D`, 60 Hz, the exact numbers in `TECH_SPEC.md` §3 | done |
| 3 | `world/greybox/movement_greybox.tscn` | one 90-second room, no art | done |
| 4 | Camera rig parented to Lancer | the camera is never handed to a cutscene | done |
| 5 | Filament (tether) prototype | 0.25 s lock-on, 18° cone assist | to do |

### Controller numbers (TECH_SPEC §3 — implement exactly)

| Feature | Value |
| --- | --- |
| Max run speed | 14.0 m/s |
| Ground accel / decel | 90 / 60 m/s² |
| Air accel | 32 m/s², capped contribution 2.2 m/s (air-strafe) |
| Gravity | 60 m/s² (jump apex ≈ 2.0 m) |
| Jump velocity | 15.5 m/s, variable height, 8f coyote, 10f buffer |
| Slide | 0.45 s, friction 6, cancels into jump |
| Wall-kiss | 2-frame window, +0.8 m/s, chain of 5, hard ceiling 18.0 m/s |
| Filament lock-on | 0.25 s cone assist, 18° half-angle |
| Fixed timestep | 60 Hz physics, `max_physics_steps_per_frame` 4 |
| 2.5D constraint | gameplay on XY; `velocity.z = 0`; walls on the plane |

Also: no `randf()` in gameplay logic — seeded `RandomNumberGenerator` per
section so ghosts and replays match.

Run the suite with:

```bash
godot --headless --editor --quit-after 20 --path .   # once, to import
godot --headless --path . res://tests/run_all.tscn
```

---

## Step 4 — PSX look (Compatibility renderer)

- Vertex snapping shader (screen-space quantisation to the 480×270 grid)
- Affine texturing toggle (off by default, per `TECH_SPEC.md` §1)
- Nearest-neighbour upscale — already set in Step 0
- **The amount is the player's to pick** — a slider in the settings panel,
  driven by the `psx_amount` global shader uniform

> **Done in code.** `addons/windshear/render/ws_psx.gdshader` and
> `ws_psx.gd` are in the repository, and `tests/test_psx.gd` checks the
> globals, the shader, the clamping, the settings round trip and the slider.
> What is left is the art, and the art is done by hand.

---

## Step 5 — The rest of the milestones

Locked in `GAME_DESIGN.md` §14 — do not re-open them while Milestone 0 runs:

| Milestone | Length | Gate |
| --- | --- | --- |
| 1 — Vertical slice | 8 weeks | a 5-minute run feels like a toy people replay |
| 2 — Systems & content | 12 weeks | an external team ships an alternate storyline |
| 3 — Polish & ship | 8 weeks | public release; community fork count > 0 |
| 4 — Community era | ongoing | edition index, community maps, seasonal Fractures |

---

## Do not do these yet

- No combat (movement-first; the design says no guns in Milestone 1)
- No Fractures beyond the ones Milestone 1 needs — but never *remove* one
  that shipped
- No accounts, no DRM, no mandatory network (GPL + trust)
- No engine/plugin that breaks the 4 GB RAM ceiling or the Compatibility
  renderer

---

## Reference

| Document | What it locks |
| --- | --- |
| `GAME_DESIGN.md` | pillars, movement model, Fractures, story, roadmap |
| `TECH_SPEC.md` | renderer, budgets, controller numbers, formats, CI, licensing |
| `CONTRIBUTING.md` | how to land a PR, licence of contributions |
| `docs/movement_reference.md` | where the movement numbers come from, and the rule about glitches |
| `docs/dev_stage_1.md` | what the movement base is, and the bug the discovery harness found |
| `docs/architecture.md` | how the codebase is put together |
| `docs/testing.md` | the suite, and how to add to it |
| `tools/ui_reference_editor.html` | visual UI reference editor → `.css` export |
| `assets/icon.svg` | project icon + title art |
