# WindShear: testing

How to run the suite, how to add to it, and what each suite is for.

There's no framework to install and no plugin to enable. The whole thing is one Godot scene and a few dozen assertions per file. It runs headless in about ten seconds.

---

## 1. Running it

```bash
# import the project once: this builds .godot/ and the global class cache
godot --headless --editor --quit-after 20 --path .

# the suite
godot --headless --path . res://tests/run_all.tscn

# the per-cell memory budget check
godot --headless --path . --script res://tools/cell_budget_checker.gd
```

A failed check gives the suite a non-zero exit status. CI is one line, and there's nothing to parse.

The current state is **929 checks, 0 failures**, in twenty suites.

---

## 2. Why these tests and not those

A generic platformer test checks that the player node exists, that the camera is a child of the rig, and that the level loads. All of that can pass on a game which drops every second jump on a 60 Hz display and has a coyote window one frame short.

That won't do here. The bugs that ruin a speedrun are frame bugs. The bugs that ruin a release are budget and policy bugs. The suite goes after those.

The coyote window has to be exactly 8 frames, accepted on frame 8 and rejected on frame 9. The same input sequence must produce the same output on every machine. Project settings and frame cost get measured instead of assumed. Four rules from `CONTRIBUTING.md` are checked in code because a reviewer can't reliably check them from a diff.

The canon tests keep the cast, arsenal, roster and player's numbers honest. Those are data, and data drifts. The input suite holds the agreed scheme in place: `W`/`S` walk forward and back, `A`/`D` strafe, `Ctrl` slides, `Space` jumps, `Q` grabs a ledge, `E` interacts, `F` throws the filament, the mouse handles the camera, and the left and right mouse buttons fire. Nothing on the keyboard turns the camera, and the suite checks that no action claims the arrows. The mouse triggers are the only mouse-only actions.

I spent a long time convinced that a good test suite was about coverage. It isn't, for this kind of game. It's about having one test per thing that would be embarrassing to get wrong, and about that test failing with a message somebody can act on without reading the source. Most of the assertions here are checking a number against a number, and that's deliberate.

---

## 3. The suites

| Suite | Checks | Covers |
| --- | --- | --- |
| `test_tuning.gd` | 25 | Tuning constants match `TECH_SPEC.md` section 3 |
| `test_movement.gd` | 54 | Movement is frame-exact |
| `test_movement_characterization.gd` | 77 | Movement accidents stay characterized |
| `test_movement_discovery.gd` | 26 | What the movement permits |
| `test_camera.gd` | 17 | The camera rig behaves |
| `test_input_map.gd` | 26 | The input map is the scheme we said |
| `test_determinism.gd` | 8 | The simulation is deterministic |
| `test_speed_meter.gd` | 11 | The speed is measured in metres per second |
| `test_perf_budget.gd` | 10 | The performance budget holds |
| `test_code_policy.gd` | 10 | The code policy holds |
| `test_world_data.gd` | 41 | The world data holds together |
| `test_canon.gd` | 115 | The canon holds |
| `test_trenchbroom.gd` | 221 | The trenchbroom converter works |
| `test_greybox.gd` | 36 | The greybox holds together |
| `test_psx.gd` | 39 | The player picks how much PSX there is |
| `test_workbench.gd` | 13 | The workbench tunes the movement |
| `test_level_tools.gd` | 86 | The level tools make sections |
| `test_ui_contract.gd` | 45 | The theme holds the look |
| `test_section_runtime.gd` | 28 | The sections run |
| `test_playable_loop.gd` | 41 | The game can be played |

The tuning suite compares the documented constants in `ws_tuning.gd` with `TECH_SPEC.md` §3. The movement suite pins the top speed, acceleration rates, turnarounds, jump height, coyote time, jump buffer, air cap, slide, wall-jump and camera-relative direction. Characterization keeps the arming and chain boundaries, collision energy, repeated cycles, adversarial input and full-state replay from drifting.

The camera suite checks the pitch clamp, yaw wrap, speed dolly and the camera's ownership by the rig. Determinism checks that identical inputs produce identical outputs and that the section seed stays stable. The speed-meter suite covers the reading, peak, reset and unit string.

The world-data suite keeps the 25×12 grid, prequel, gate schedule, Fracture registry, endings, beats and dialogue together. The canon suite covers the cast, silence, arsenal, enemy roster, health and speed numbers, and the documents that have to agree with them. The TrenchBroom suite reads hand-written map fixtures in both the Valve and the Standard shape, works out the shape of the brushes, turns map units into metres, places the points with the ids the trigger and the schedule expect, lays a ramp along a slope, checks the converter never writes over a section that is already there, and checks the texture folder has a real picture for every name the converter reads, with the licences beside them. The greybox suite covers the scene, player, camera, floor, budget, materials, help panel and a 90-second route. The PSX suite checks the globals, shader, clamping, settings round trip and the slider in the menu.

Most of these are **plain** suites. They extend `WSTest`, implement `run()`, touch nothing but the simulation, and don't need a scene tree. They run first.

`test_greybox.gd` and `test_psx.gd` are the two **scene suites**. They implement `run_with_scene(scene)` instead, and the runner gives them a live greybox. The PSX suite needs a live tree because it puts the main menu into the tree and moves the real slider.

---

## 4. The framework

`tests/ws_test.gd` is the whole framework. It's about eighty lines.

```gdscript
extends "res://tests/ws_test.gd"

const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")

func suite_name() -> String:
	return "the thing under test"

func run() -> void:
	heading("a group of assertions")
	ok(condition, "a sentence that says what was expected")
	near(actual, expected, tolerance, "a float comparison")
	same(actual, expected, "an integer comparison")
	text(actual, expected, "a string comparison")
```

`ok`, `near`, `same` and `text` each count one check and collect a failure message. Messages are sentences rather than expressions. At 2am, the first line should tell you what broke, not which operator disagreed.

Notice the `extends "res://tests/ws_test.gd"`. It's a path extend, not a global class name. The global class cache lives in `.godot/` and isn't in the repository, so a fresh clone has no class names until the project has been imported. A path extend works straight away.

### The code-policy test

`test_code_policy.gd` reads the source tree rather than running anything. It checks four things.

Every `.gd` file under `res://` must carry the GPL notice. The copyleft depends on that, and a missing header is a legal problem rather than a style problem.

Gameplay code can't use global random numbers. `randf()`, `randi()`, `randf_range()`, `randi_range()`, `randfn()` and `randomize()` are forbidden in `addons/windshear/`, `world/` or `ui/`. Comments are stripped before the scan so a docstring can't trigger it.

The frame loops can't allocate. The scan looks inside `_process` and `_physics_process` in `addons/windshear/` for `.new(`, `.instantiate(`, `.duplicate(`, `.append(`, `.filter(`, `.map(`, `= []`, `= {}` and `await `. GC stutter ruins a run.

Finally, the documentation has to say the important things. The README must name both licences, the LICENSE must be the GPL, the NOTICE must credit Godot, and the spec must state the memory ceiling and run speed.

That allocation rule applies to shipped runtime code under `addons/windshear/`. Developer tools and the greybox HUD are exempt. A label that refreshes ten times a second isn't a frame-loop problem.

---

## 5. The runner is a scene

`tests/run_all.tscn` runs `tests/run_all.gd`, which extends `Node`.

A `--script` main loop doesn't register the autoload singletons as global identifiers. `WsGame` fails to compile in a script, which means a suite that touches the menu can't be written at all, since the menu touches `WsGame`.

The runner was a `--script` main loop for two days. It worked for every suite that didn't touch the autoload. That's exactly how this kind of bug hides.

Running the suite as a scene also runs the game the way the game runs. It's the only way a test proves anything about the game.

```gdscript
extends Node

func _ready() -> void:
	_run()

func _run() -> void:
	# ... run the plain suites ...
	# ... instantiate the greybox and wait twelve physics frames ...
	# ... run the scene suites ...
	get_tree().quit(0 if total_failures == 0 else 1)
```

---

## 6. The discovery suite

`test_movement_discovery.gd` works differently from the others. It doesn't assert a behaviour. It *plays* candidate techniques against the controller and reports what came out.

```
    movement discovery report
    technique            peak    final  jumps slides kisses      air
    plain run           14.00    14.00      0      0      0     0.00
    bunny hop           14.27    14.27     19      0      0     2.20
    slide-hop           14.43    14.43     10      1      0     0.53
    air flick           14.00     3.60      8      0      0     2.20
    wall-kiss chain     16.40    16.40     15      0      1     0.00
    turnaround          14.00    14.00      0      0      0     0.00
```

The report prints on every run. A movement change shows up in the output even when all the assertions still pass. The report is the instrument; the assertions are the guard rails.

Every technique stays under the speed ceiling and keeps its depth finite. It respects the air acceleration cap and the wall-jump chain cap. On top of that, bunny hopping can't beat a plain run by more than 0.5 m/s. That's the promise the project makes. If it ever fails, somebody changed the physics on purpose and has to argue for it.

`tests/movement_probe.gd` is the harness underneath. It's a kinematic rig that stands the controller up in an empty world and drives it with a per-frame input function. No scene, no physics body, so it runs in milliseconds.

---

## 7. Writing a new suite

Create `tests/test_<thing>.gd` and extend `"res://tests/ws_test.gd"`. Implement `suite_name()` and `run()`. If it needs a live tree, implement `run_with_scene(scene)` and add it to `SCENE_SUITES` in `tests/run_all.gd`.

Use `preload` for dependencies instead of global class names. Write failure messages as sentences. Free everything you allocate; the suite runner exits with a leak report if you don't, and a leak in a test is a leak in the game.

```gdscript
extends "res://tests/ws_test.gd"

const Controller := preload("res://addons/windshear/movement/lancer_controller.gd")


func suite_name() -> String:
	return "the thing under test"


func run() -> void:
	heading("a group of assertions")
	var controller := Controller.new()
	# ...
	controller.free()
```

### The leak that was

One suite, `_test_wall_kiss_cap()` in `test_movement.gd`, forgot to free its controller. The exit report named a `CharacterBody3D`, two GDScripts and a Jolt RID. It was the only thing in the exit log, so it was easy to find, although only after the runner had been started with `--verbose`.

Nothing in the game was wrong. The test wasn't tidying up, and a test that leaks hides the next leak.

---

## 8. Continuous integration

`.github/workflows/ci.yml` runs on every push and every pull request. It checks out the repository, installs the pinned Godot **4.7.2** build and puts it on the path, then caches both the Godot download and the `.godot/` import cache. After that it imports the project, runs the test suite and runs the cell budget checker.

Every step fails the job on a non-zero exit. The engine version is pinned in one place at the top of the workflow and in `TECH_SPEC.md` §9. Both are meant to name the same build, the same table that says which Linux binary the Arch PKGBUILD uses.

Don't skip the import step. Without it there's no `.godot/` directory, no global class cache and no imported textures. The suite then fails in confusing ways.

---

## 9. The budget checker

`tools/cell_budget_checker.gd` walks the project and reports the size of each cell against the budget in `TECH_SPEC.md` §2:

```
Per-cell budgets: ≤ 45 MB textures, ≤ 20 MB meshes, ≤ 12 MB audio
```

It's a gate, not a report. A cell over budget fails the check, and the check fails CI.

---

## 10. What is not tested yet

The headless runner uses the dummy renderer, so it can't tell whether the PSX shader actually *looks* right. It only checks that the shader compiles and that the dial reaches it. The visual work is done by hand and verified by hand.

There are no levels yet. Most Fractures have no gameplay implementation; `wall_kiss_chain` is the exception, with its controller behaviour and stable registry entry in place. The rest of the speedrun stack is still ahead of us: the splits view can be opened with `Tab`, but there's no timer, ghost or leaderboard format yet.

These gaps are listed in `docs/dev_stage_1.md` §7 along with what each stage needs.
