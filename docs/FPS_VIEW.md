# The first-person view, built by hand

How to build the first-person view in the editor, and what it has to do when
it is finished.

The movement is finished and the framing is not. The rig in the tree today
orbits Lancer from behind, seven metres back, so you can see the character
run. The game is played in first person: the camera is at the eye, the mouse
is locked in the middle of the screen, and a dot sits in the middle of the
frame where the mouse is.

This page is the map of the ground. The building is somebody's job; this is
here so the building does not have to be archaeology.

---

## What is in the tree today

| Thing | Where it is |
| --- | --- |
| The camera rig | `addons/windshear/movement/camera_rig.gd`, class `CameraRig` |
| The player body | `addons/windshear/movement/lancer_controller.gd` |
| The run screen | `world/run/run_screen.tscn`, script `world/run/run_screen.gd` |
| The greybox room | `world/greybox/movement_greybox.tscn` |
| The designer's room | `world/playground/section_playground.tscn` |
| The HUD | `ui/hud/section_hud.tscn`, script `ui/hud/section_hud.gd` |
| The look theme | `ui/theme/windshear_theme.tres` |
| The settings | `WsGame`, `addons/windshear/core/ws_game.gd` |
| The live knobs | `WsTweak`, `addons/windshear/core/ws_tweak.gd` |
| The documented numbers | `addons/windshear/core/ws_tuning.gd`, pinned by `TECH_SPEC.md` §3 |

The node tree in every playable scene is the same:

```
Player            CharacterBody3D, lancer_controller.gd
└── CameraRig     Node3D, camera_rig.gd
    └── Camera3D  the camera
```

The rig owns yaw and pitch and nothing else. The camera is its child, and
the rig writes the camera's position and field of view every frame. The
controller reads `rig.yaw` back to work out which way "forward" is, so
movement stays camera-relative no matter where the camera sits.

### The knobs

The rig exports these, and the numbers are also in `ws_tuning.gd`:

| Export | Default | What it is |
| --- | --- | --- |
| `mouse_sensitivity` | 0.0022 rad/px | radians of turn per pixel of mouse |
| `controller_sensitivity` | 3.0 rad/s | radians of turn per second at full stick |
| `pitch_limit_deg` | 80° | how far the view can tilt either way |
| `base_fov` | 72° | field of view standing still |
| `fast_fov` | 82° | field of view at top speed |
| `base_distance` | 7.0 m | how far back the camera sits |
| `fast_distance` | 8.4 m | how far back it sits at top speed |
| `eye_height` | 1.7 m | height of the camera above the feet |

Two of these matter for first person. `base_distance` and `fast_distance`
are the third-person pull-back, and the eye height is the same in both
views: 1.7 m is the documented camera height and the player's eye.

### What the rig already does for you

- It reads **relative** mouse motion (`InputEventMouseMotion.relative`), so
  it keeps working when the mouse is captured. A captured mouse still sends
  relative motion, and that is all the rig looks at.
- It has a `look_enabled` flag, which is the switch for "the menu is open,
  the room should not spin".
- It takes its live numbers from `WsTweak` when the workbench has moved
  them, and from its own exports otherwise.

### What is missing

Nothing in the project touches `Input.mouse_mode`. The cursor is free
today: it wanders off the window, and there is nothing in the middle of the
frame but the world. Those are the two things this page is about.

---

## Building it

### 1. The camera at the eye

Open `world/run/run_screen.tscn` and select `Player/CameraRig/Camera3D`.

The rig writes the camera's position every frame as
`(0, eye_height, distance)`. For a first-person view the distance is zero,
so the camera sits on the eye and the rig still owns the look.

Two ways to get there, both in the editor:

- **Keep the rig, take the distance out.** Set `base_distance` and
  `fast_distance` to `0` on the `CameraRig` node. The speed framing still
  widens the lens from 72° to 82°, which reads as speed rather than as a
  zoom, and the camera never leaves the eye.
- **Build a first-person rig of your own.** A new `Node3D` under `Player`
  with a `Camera3D` under it, at `(0, eye_height, 0)`. The rig it replaces
  still has to publish a yaw, because the controller reads `rig.yaw` for
  camera-relative movement.

If the camera moves out of the rig's reach, keep the name `CameraRig` on the
node the controller reads. `lancer_controller.gd` looks it up by that name.

### 2. The mouse locked in the middle

The mouse is captured while a run is on, and given back when the menu comes
back.

- `Input.mouse_mode = Input.MOUSE_MODE_CAPTURED` when the run starts.
- `Input.mouse_mode = Input.MOUSE_MODE_VISIBLE` when the run ends.

Where those two lines go:

| Place | Why |
| --- | --- |
| `world/run/run_screen.gd`, `_ready()` | the run starts; capture here, next to `_apply_camera_settings()` |
| `world/run/run_screen.gd`, `_leave_to_the_menu()` | the player pressed escape; give the cursor back before `change_scene_to_file` |
| `world/run/run_screen.gd`, `_leave_after_the_campaign()` | the same, at the end of the campaign |
| `ui/main_menu/main_menu.gd`, `_ready()` | belt and braces, so a restart never comes back with a hidden cursor |

The rig needs no change for this. It reads relative motion, and that is
what a captured mouse sends.

While the menu is open the rig's `look_enabled` should be false, so the
room does not spin behind the panel.

### 3. The dot in the middle

The crosshair is a small dot in the middle of the frame, where the mouse
is locked.

- Add a node under the `HUD` `CanvasLayer` in `world/run/run_screen.tscn`:
  a `Panel` or a `ColorRect` three pixels across, or a small `Control` that
  draws a circle in `_draw()`.
- Centre it: anchors 0.5 on both axes, `grow_horizontal = 2`,
  `grow_vertical = 2`, and offsets around zero (say `-2` to `2`).
- `mouse_filter = 2`, so the dot never eats a click.
- Take the colour from the theme, `ui/theme/windshear_theme.tres`, rather
  than writing a colour into the scene. The rest of the HUD does it that
  way and the dot should match.
- If the dot belongs in every scene rather than only the campaign, put it
  in `ui/hud/section_hud.tscn` instead of the run screen.

### 4. The numbers you can move

| Where | What it is for |
| --- | --- |
| `ui/main_menu/main_menu.gd` | the settings panel already has sliders for mouse speed and field of view; they write to `WsGame` and are saved to the user config |
| `tools/movement_workbench.tscn`, press **F6** | the workbench. The "camera" group has live sliders for mouse speed, camera height, camera back, field of view and field of view at speed. Drag one and the rig uses it on the next frame |
| `addons/windshear/core/ws_tuning.gd` | the documented numbers. The suite checks them against `TECH_SPEC.md` §3, so they are a contract, not a suggestion |

The workbench's **write to repo** button writes `data/tuning_profile.json`.
A tuned number is not canon until somebody writes it into the code and the
spec, and the profile is the handoff for that.

---

## Checking it

- `godot --path .` and walk. The cursor should be gone and the dot centred.
- Press **Esc**. The menu comes back and the cursor comes back with it.
- `godot --headless --path . res://tests/run_all.tscn` for the suite.

The tests that watch this part of the tree:

| Suite | What it holds |
| --- | --- |
| `tests/test_camera.gd` | the rig's pitch clamp, its framing and its yaw |
| `tests/test_input_map.gd` | the rig reads the mouse and the stick, and the keyboard never turns the camera |
| `tests/test_code_policy.gd` | nothing may allocate in a frame loop |
| `tests/test_tuning.gd` | the numbers in `TECH_SPEC.md` §3 match the code |

If an export on the rig is renamed, the knob table in `ws_tweak.gd` and
`tests/test_camera.gd` move with it, in the same change.

---

## Writing it down when it is done

- `TECH_SPEC.md` §3 — the camera bullet says the camera is a third-person
  orbit rig. That sentence changes when the view does.
- `docs/CONTROLS.md` — what the mouse does while it is captured.
- `docs/AUTHORING.md` and this page.
- `docs/movement_reference.md`, if the movement changed with the framing.
