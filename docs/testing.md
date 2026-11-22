# WindShear — Testing

The test suite, how to run it, how to add to it, and what each suite is
actually for.

There is no test framework to install and no plugin to enable. The whole
suite is one Godot scene and a few dozen assertions per file, and it runs
headless in about ten seconds.

---

## 1. Running it

```bash
# import the project once — this builds .godot/ and the global class cache
godot --headless --editor --quit-after 20 --path .

# the suite
godot --headless --path . res://tests/run_all.tscn

# the per-cell memory budget check
godot --headless --path . --script res://tools/cell_budget_checker.gd
```

The suite exits with a non-zero status when a check fails, so CI is one
line and there is nothing to parse.

The current state is **322 checks, 0 failures**.

---

## 2. Why these tests and not those

A generic test suite for a platformer would check that the player node
exists, that the camera is a child of the rig, and that the level loads.
All three of those would pass on a game that drops every second jump on a
60 Hz display and who's coyote window is one frame short.

That is not a useful test suite for this game. The bugs that ruin a speedrun
are frame bugs, and the bugs that ruin a release are budget and policy
bugs. So the suite is built around those:

- **Frame-exact movement.** The coyote window is 8 frames. It is asserted to
  be exactly 8 frames, on the 8th frame and not on the 9th.
- **Determinism.** The same input sequence has to produce the same output,
  every time, on every machine.
- **The performance budget.** The project settings and the cost of a frame
  are measured, not assumed.
- **The code policy.** Four rules from `CONTRIBUTING.md` that a reviewer
  cannot check by reading a diff.

---

## 3. The suites

| Suite | Checks | Covers |
| --- | --- | --- |
| `test_tuning.gd` | 23 | Documented constants in `ws_tuning.gd` against `TECH_SPEC.md` §3 |
| `test_movement.gd` | 42 | Top speed, acceleration rates, turnarounds, jump height, coyote time, jump buffer, air cap, slide, wall-kiss, plane constraint |
| `test_movement_characterization.gd` | 77 | Arming and chain boundaries, collision energy, repeated cycles, adversarial input, full-state replay |
| `test_movement_discovery.gd` | 26 | The discovery report, the invariants, and the bunny-hop promise |
| `test_camera.gd` | 17 | Pitch clamp, yaw wrap, speed dolly, the camera belonging to the rig |
| `test_determinism.gd` | 8 | Identical inputs give identical outputs; the section seed is stable |
| `test_perf_budget.gd` | 10 | The project settings and the cost of a frame |
| `test_code_policy.gd` | 10 | Licence headers, no global random numbers, no allocation in the frame loops, the documentation |
| `test_world_data.gd` | 37 | The 20×12 grid, the gate schedule, the Fracture registry, the endings, the beats and the dialogue |
| `test_greybox.gd` | 33 | The scene: the player, the camera, the plane, the budget, the materials, the help panel, a 90-second route |
| `test_psx.gd` | 39 | The amount dial: the globals, the shader, the clamping, the settings round trip, and the slider in the menu |

### The two kinds of suite

Most suites are **plain**: they extend `WSTest`, implement `run()`, and touch
nothing but the simulation. They do not need a scene tree and they run
first.

Two suites are **scene suites**: `test_greybox.gd` and `test_psx.gd`. They
implement `run_with_scene(scene)` instead, and the runner gives them a live
greybox. The PSX suite needs a live tree because it has to put the main menu
into the tree and move the real slider.

---

## 4. The framework

`tests/ws_test.gd` is the whole framework. It is about eighty lines.

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

`ok`, `near`, `same` and `text` each count a check and collect a failure
message. The failure messages are sentences, not expressions, because the
first thing you read at 2am should tell you what broke, not which operator
disagreed.

Note the `extends "res://tests/ws_test.gd"` — a path extend rather than the
global class name. The global class cache lives in `.godot/` and is not in
the repository, so a fresh clone has no class names until the project has
been imported. Path extends work on a fresh clone.

### The code-policy test

`test_code_policy.gd` is the odd one out: it reads the source tree rather
than running anything.

It checks four things:

1. **Every `.gd` file under `res://` carries the GPL notice.** The copyleft
   depends on it, and a missing header is a legal problem, not a style one.
2. **No global random numbers in gameplay code.** `randf()`, `randi()`,
   `randf_range()`, `randi_range()`, `randfn()` and `randomize()` are not
   allowed in `addons/windshear/`, `world/` or `ui/`. Comments are stripped
   before the scan, so a sentence in a docstring cannot trigger it.
3. **No allocation in the frame loops.** The scan looks inside the bodies of
   `_process` and `_physics_process` in `addons/windshear/` for `.new(`,
   `.instantiate(`, `.duplicate(`, `.append(`, `.filter(`, `.map(`, `= []`,
   `= {}` and `await `. The GC stutter ruins a run.
4. **The documentation says the important things.** That the README names
   both licences, that the LICENSE is the GPL, that the NOTICE credits
   Godot, and that the spec states the memory ceiling and the run speed.

The rule about allocation is enforced on the shipped runtime code under
`addons/windshear/`. Developer tools and the greybox HUD are exempt: a
label that refreshes ten times a second is not a frame loop problem.

---

## 5. The runner is a scene

`tests/run_all.tscn` runs `tests/run_all.gd`, which extends `Node`.

This is not a style choice. A `--script` main loop does **not** register the
autoload singletons as global identifiers, so `WsGame` fails to compile in a
script, and every suite that touches the menu (and the menu touches
`WsGame`) cannot be written at all.

The runner was a `--script` main loop for two days. It worked for every
suite that did not touch the autoload, which is exactly how a bug like this
hides.

Running the suite as a scene also means the suite runs the game the way the
game runs, which is the only way a test proves anything about the game.

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

`test_movement_discovery.gd` is different in kind from the others. It does
not assert a behaviour — it *plays* a set of candidate techniques against
the controller and reports what came out.

```
    movement discovery report
    technique            peak    final  jumps slides kisses      air
    plain run           14.00    14.00      0      0      0     0.00
    bunny hop           14.27    14.27     19      0      0     2.20
    slide-hop           14.43    14.43     10      1      0     0.53
    air flick           14.00     3.60      8      0      0     2.20
    wall-kiss chain     18.00    18.00     15      0      1     0.00
    turnaround          14.00    14.00      0      0      0     0.00
```

The report is printed on every run, so a change in the movement code shows
up in the output even when every assertion still passes. That is the point:
the report is the instrument, the assertions are the guard rails.

The guard rails are:

- Every technique stays under the speed ceiling.
- Every technique never leaves the XY plane.
- Every technique respects the air acceleration cap.
- Every technique respects the wall-kiss chain cap.
- **Bunny hopping is not a speed exploit** — it may not exceed a plain run
  by more than 0.5 m/s.

That last one is the promise the project makes. If it ever fails, somebody
changed the physics on purpose and has to argue for it.

`tests/movement_probe.gd` is the harness underneath: a kinematic rig that
stands the controller up in an empty world and drives it with a per-frame
input function. It has no scene and no physics body, so it runs in
milliseconds.

---

## 7. Writing a new suite

1. Create `tests/test_<thing>.gd`.
2. Extend `"res://tests/ws_test.gd"`.
3. Implement `suite_name()` and `run()`. If it needs a live tree, implement
   `run_with_scene(scene)` instead and add it to `SCENE_SUITES` in
   `tests/run_all.gd`.
4. `preload` your dependencies rather than using global class names.
5. Write the failure messages as sentences.
6. Free everything you allocate. The suite runner exits with a leak report
   if it does not, and a leak in a test is a leak in the game.

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

One suite, `_test_wall_kiss_cap()` in `test_movement.gd`, forgot to free its
controller. The leak report at exit named a `CharacterBody3D`, two
GDScripts and a Jolt RID, and it was the only thing in the exit log, so it
was easy to find — but only because the runner was run with `--verbose`.

Nothing in the game was wrong. The test was simply not tidying up, and a
test that leaks is a test that hides the next leak.

---

## 8. Continuous integration

`.github/workflows/ci.yml` runs on every push and every pull request:

1. Checkout.
2. Install the pinned Godot **4.7.2** build and put it on the path.
3. Cache the Godot download and the `.godot/` import cache.
4. Import the project.
5. Run the test suite.
6. Run the cell budget checker.

Every step fails the job on a non-zero exit. The engine version is pinned in
one place at the top of the workflow and in `TECH_SPEC.md` §9, and the two
are supposed to be the same build — the same table that says which Linux
binary the Arch PKGBUILD uses.

The import step is not optional. Without it there is no `.godot/` directory,
no global class cache and no imported textures, and the suite fails in
confusing ways.

---

## 9. The budget checker

`tools/cell_budget_checker.gd` walks the project and reports the size of
each cell against the budget in `TECH_SPEC.md` §2:

```
Per-cell budgets: ≤ 45 MB textures, ≤ 20 MB meshes, ≤ 12 MB audio
```

It is a gate, not a report. A cell that is over budget fails the check, and
the check fails CI.

---

## 10. What is not tested yet

Honesty is cheaper than a surprised player.

- **The renderer.** The headless runner uses the dummy renderer, so nothing
  checks that the PSX shader actually *looks* right, only that it compiles
  and that the dial reaches it. The visual work is done by hand and verified
  by hand.
- **The levels.** There are no levels yet.
- **The Fractures.** None are implemented.
- **The speedrun systems.** No timer, no ghosts, no splits.

These are listed in `docs/dev_stage_1.md` §7 along with what each stage
needs.
