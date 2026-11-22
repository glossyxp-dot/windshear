# WindShear — Dev Stage 1: the movement base

**Level 1** of the development stages. This is the stage where the game stops
being documents and starts being a thing you can move around in, and where
the movement gets its numbers.

What exists now:

- A Godot 4.7.2 project that boots to a menu and into a movement greybox.
- A frame-exact movement controller with every number in `TECH_SPEC.md` §3.
- A camera rig that never leaves Lancer.
- A test suite of **271 checks** that runs headless in about ten seconds.
- A discovery harness that plays candidate movement techniques against the
  controller and reports what it finds.

What does not exist yet: levels, art, story in the engine, the speedrun
systems, the Fractures. Those are later stages. Level 1 is the floor, and the
floor has to be good before anything is built on top of it.

---

## 1. Why the movement is built this way

The numbers did not come from taste. They came from released movement source
where it is available, official data where the engine is closed, and clearly
labelled community documentation otherwise. Those sources were compared, and
then the parts that survived the comparison were written down. That research
is in [`docs/MOVEMENT_RESEARCH.md`](MOVEMENT_RESEARCH.md), and this document
does not repeat it.

What survives here is one principle, and it is the reason the whole stage
exists:

> **A movement technique is found, not built.**

The controller implements five verbs — run, slide, jump, wall-kiss, filament —
and nothing else. There is no bunny hop button, no "speed boost" move, no
hidden state that rewards a specific input sequence. The techniques that
exist are consequences of the physics, and the job of this stage was to find
out what those consequences are before a single level was designed around
them.

---

## 2. How the controller is built

The controller (`addons/windshear/movement/lancer_controller.gd`) has one
public method:

```gdscript
func simulate(delta: float, input: LancerInput) -> void
```

It is a pure function of the input and the previous state. It does not touch
the scene tree, it does not read the clock, and it does not allocate. That
matters for three reasons:

1. The tests can drive it frame by frame with no scene and no waiting.
2. A replay is just the list of inputs.
3. It can be stepped in a worker thread, which is where the ghost system
   will live.

The numbers live in one file, `addons/windshear/core/ws_tuning.gd`, and
`tests/test_tuning.gd` asserts every one of them against `TECH_SPEC.md`
§3. Change a number in the code without changing the document, and the build
breaks.

---

## 3. The discovery harness

`tests/movement_probe.gd` is a kinematic harness: it stands the controller up
in an empty world and drives it with a per-frame input function. No scene, no
physics, just the simulation and a synthetic floor.

`tests/test_movement_discovery.gd` runs six candidate techniques through it
and prints a report:

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

Reading it:

- **plain run** is the baseline. 14.00 m/s, exactly the run speed.
- **bunny hop** — jump on every landing, 19 times — reaches 14.27 m/s. That
  is 0.27 m/s above a plain run, and it is *not* a speed exploit. It is the
  air cap being spent a little at a time, which is the whole point of the
  cap.
- **slide-hop** reaches 14.43 m/s. Sliding into a jump costs a little speed
  and buys a little height, and the net is a small gain.
- **air flick** — run right, then pull left in the air — peaks at 14.00 and
  ends at 3.60. It does what it does in every game with a Quake-style air
  cap: you can steer, you cannot cheat.
- **wall-kiss chain** reaches 18.00 m/s. That is the run speed plus the
  full chain of five kisses at +0.8 m/s each. It is the fastest thing in
  the game, and it is 18.00 exactly, because of the ceiling below.
- **turnaround** — reverse the stick at full speed — comes back to 14.00.
  The turn costs nothing in the long run, but it costs frames, and frames
  are the currency of this game.

After the report the suite asserts four invariants for every technique (the
speed stays under the ceiling, the player never leaves the XY plane, the air
cap holds, the kiss chain cap holds) and one promise:

> bunny hopping is not a speed exploit.

If that assertion ever fails, somebody changed the physics on purpose, and
the change has to be argued for rather than assumed.

---

## 4. The wall-kiss ceiling — a bug that was found, not a feature

This is the part of the stage worth reading twice.

The wall-kiss is a WindShear verb: a slide opens a two-frame window, and if
you touch a side wall and jump on that frame, you get +0.8 m/s of horizontal
speed. The chain of five kisses is the ceiling on how many you can take
before you have to land.

The **first** version of the implementation had a chain cap but no speed
ceiling. The discovery harness reported this:

```
    wall-kiss chain     26.00    26.00     15      0      5     0.00
```

Twenty-six metres per second. Nearly twice the run speed, reached by
holding a button against a wall. The chain cap of five was doing nothing —
the speed went up by 0.8 per kiss, and each kiss also triggered another
kiss, and the only thing that stopped it was the chain cap, which the
player could reset by touching the ground and doing it again.

A route that ran along a wall at 26 m/s was not a technique. It was a
different movement game layered on top of the first one, and it made every
other speed number meaningless. The greybox has a guide wall at z = -0.5
specifically so this could be found early.

The fix was a **hard horizontal speed ceiling of 18.0 m/s** — the run speed
plus the full chain — applied to the wall-kiss boost. The chain of five
kisses still reaches exactly 18.00 m/s, so the mechanic keeps its full
value; it simply cannot be repeated into a bigger number.

Two things about this are worth stating plainly:

- **The exploit was not designed in.** Nothing in the code said "let the
  player chain infinitely". It was a consequence of the boost being
  uncapped, found by a harness that plays the technique and prints the
  number.
- **The fix is a ceiling, not a removal.** The technique still works, still
  has its full designed value, and still rewards the player for setting it
  up. All that changed is that it cannot be farmed.

This is also why the rule in `docs/MOVEMENT_RESEARCH.md` §1 exists. The
distance between a good speedrun technique and a movement exploit is often
just a missing clamp, and the only way to find out which one you have is to
go and look.

---

## 5. What the tests actually cover

271 checks, in ten suites. They are deliberately *not* "does the node
exist" tests.

| Suite | Checks | What it is for |
| --- | --- | --- |
| tuning | 23 | Documented constants in `ws_tuning.gd` match `TECH_SPEC.md` §3 |
| movement | 42 | Frame-exact movement: top speed, acceleration rates, coyote time, jump buffer, air cap, slide, wall-kiss, plane constraint |
| characterization | 77 | Arming and chain boundaries, collision energy, repeated cycles, adversarial input, full-state replay |
| discovery | 26 | The report above, the invariants, and the bunny-hop promise |
| camera | 17 | Pitch clamp, yaw wrap, speed dolly, the camera belonging to the rig |
| determinism | 8 | The same inputs give the same outputs; the section-seeded generator is stable |
| performance | 10 | The project settings and the cost of a frame |
| code policy | 10 | Licence headers, no global `randf()`, no allocation in the frame loops |
| greybox | 19 | The scene: the player, the camera, the plane, the budget, a 90-second route |
| PSX | 39 | The amount dial: the globals, the shader, the clamping, the settings round trip, and the slider in the menu |

The camera, movement and determinism suites are the ones that matter most.
A one-frame error in the coyote window is invisible in a screenshot and
ruins every recorded route, so it is asserted to the frame.

The code-policy suite is the one that protects the project rather than the
game. It enforces the four rules from `CONTRIBUTING.md` that a reviewer
cannot check by reading a diff: every script carries the GPL notice, no
global random numbers in gameplay code, no allocation in the frame loops,
and no `await` in the frame loops.

---

## 6. How to run it

```bash
# import the project once (this builds .godot/ and the class cache)
godot --headless --editor --quit-after 20 --path .

# the test suite
godot --headless --path . res://tests/run_all.tscn

# the per-cell memory budget check
godot --headless --path . --script res://tools/cell_budget_checker.gd
```

The runner is a **scene** (`res://tests/run_all.tscn`) and not a `--script`
main loop. That is not a style choice: a script main loop does not register
the autoload singletons as global identifiers, so `WsGame` fails to compile
there, and a suite that touches the menu cannot be written at all. The
runner was a script for two days and it was a lie about how the game runs.

It exits non-zero when a check fails, so CI is one line.

---

## 7. What is deliberately not here yet

- **Levels.** The greybox is a test rig, not a level. No section geometry
  beyond what the movement tests need.
- **Art.** The materials in the greybox are flat placeholder colours. All
  the visual work is done by hand, outside the engine.
- **The Fractures.** None of the twelve from `GAME_DESIGN.md` §4 are
  implemented. They are data (`data/fractures.json`), and their triggers
  will be built once the movement is settled, because a Fracture that
  depends on a movement behaviour that later changes is not a Fracture, it
  is a bug report.
- **The speedrun systems.** No timer, no ghosts, no splits, no leaderboard
  format yet.
- **The story layer.** The data is written (`data/story/`), the engine is
  not.

---

## 8. What Level 2 needs

Level 2 is the first playable section, and it needs three things from this
stage:

1. **A movement feel that survives contact with a real level.** The
   greybox has no obstacles that demand a precise line. Level 2 needs one.
2. **The filament verb.** It is tuned (`0.25 s`, `18°`) but not implemented
   yet, because it is the first verb that touches something other than the
   ground.
3. **The first Fracture.** The fracture site in chapter 4 (`4.03`) is the
   design's promise that the movement has depth worth exploiting — and it
   will only work if the movement underneath it is stable.

The number that matters most for Level 2 is 18.00. A section built around
routes that peak at 18 m/s and fall back to 14 m/s has room for both
approaches, and a section built around a wall that can be farmed has
nothing.
