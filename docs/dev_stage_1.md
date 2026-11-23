# WindShear: Dev Stage 1, the movement base

**Level 1** of the development stages. This is where the game stops being documents and starts being something you can move around in, and where the movement gets its numbers.

We have a Godot 4.7.2 project that boots to a menu and into a movement greybox. The movement controller is frame-exact, with every number tied to `TECH_SPEC.md` §3. The camera stays with Lancer. A test suite of **485 checks** runs headless in about ten seconds, and a discovery harness plays candidate movement techniques against the controller so we can see what it finds.

Levels, art, story in the engine, the speedrun systems and the remaining Fractures come later. Level 1 is the floor, and the floor needs to be good before anything gets built on it.

---

## 1. Why the movement is built this way

The numbers didn't come from taste. They came from released movement source where it was available, official data where the engine was closed, and clearly labelled community documentation otherwise. I compared those sources, then wrote down the parts that survived the comparison. That research is in [`docs/MOVEMENT_RESEARCH.md`](MOVEMENT_RESEARCH.md), and this document doesn't repeat it.

One principle survived the whole process. It's the reason this stage exists:

> **A movement technique is found, not built.**

The base controller implements five verbs: run, slide, jump, wall-kiss and filament. There's no bunny-hop button, no generic "speed boost" move and no hidden state that pays out for a favourite input sequence. Techniques emerge from the physics. This stage found out what they were before a level was designed around them.

---

## 2. How the controller is built

The controller (`addons/windshear/movement/lancer_controller.gd`) has one public method:

```gdscript
func simulate(delta: float, input: LancerInput) -> void
```

It behaves like a pure function of the input and the previous state. It doesn't touch the scene tree, read the clock or allocate. The tests can drive it frame by frame without a scene or any waiting, a replay is just the list of inputs, and it can be stepped in a worker thread where the ghost system will live.

All the numbers live in `addons/windshear/core/ws_tuning.gd`. `tests/test_tuning.gd` asserts every one of them against `TECH_SPEC.md` §3. Change a number in the code without changing the document and the build breaks.

The controls around that controller are:

```text
A / D    run left, run right
Ctrl     slide
Space    jump
Q        ledge grab
E        interact
F        filament
LMB      primary fire
RMB      alt fire
W / S    tilt the camera
arrows   turn and tilt the camera
mouse    camera
```

The mouse handles the camera and both triggers because it's already in the hand pointing at the target. Everything else is on the keyboard. The arrows and `W`/`S` leave a camera route for players who don't want to use the mouse. `R` resets to the spawn, `Tab` shows splits, `F1` or `H` opens the mechanics reference, `C` reloads, `B` uses an item, and `V` or the mouse wheel cycles weapons.

---

## 3. The discovery harness

`tests/movement_probe.gd` is a kinematic harness. It stands the controller up in an empty world and drives it with a per-frame input function. No scene, no physics, just the simulation and a synthetic floor.

`tests/test_movement_discovery.gd` runs six candidate techniques through it and prints this report:

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

The plain run is the baseline at 14.00 m/s, exactly the run speed. The bunny hop jumps on every landing, 19 times, and reaches 14.27 m/s. That's 0.27 m/s above a plain run, so it isn't a speed exploit. It's the air cap being spent a little at a time, which is the whole point of the cap.

The slide-hop reaches 14.43 m/s. Sliding into a jump costs a little speed and buys a little height, and the net is a small gain. The air flick runs right and then pulls left in the air; it peaks at 14.00 and ends at 3.60. You can steer, but you can't cheat.

The base wall-kiss chain reaches 16.40 m/s. The chain is capped at three, and each wall-jump adds 0.8 m/s: 14.0 + 3 × 0.8 = 16.4 m/s. A turnaround, which reverses the stick at full speed, comes back to 14.00. The turn costs nothing in the long run, but it costs frames, and frames are the currency of this game.

After the report, the suite asserts four invariants for every technique. Speed stays under the ceiling, the player never leaves the XY plane, the air cap holds and the wall-kiss chain cap holds. It also checks one promise:

> bunny hopping is not a speed exploit.

If that assertion ever fails, somebody changed the physics on purpose. The change has to be argued for rather than assumed.

---

## 4. The wall-kiss ceiling — a bug that was found, not a feature

This is the part of the stage worth reading twice.

The wall-kiss is a WindShear verb, and the movement research calls the chain a wall-kiss. A slide opens a two-frame window. If you touch a side wall and jump on that frame, you get +0.8 m/s of horizontal speed. In the base game the chain is three wall-jumps long.

The **first** version of the implementation had a chain cap but no speed ceiling. The discovery harness reported this:

```
    wall-kiss chain     26.00    26.00     15      0      5     0.00
```

Twenty-six metres per second. Nearly twice the run speed, reached by holding a button against a wall. The old five-kiss limit wasn't doing its job. Speed went up by 0.8 per kiss, each kiss triggered another, and the only thing stopping the run was a limit the player could reset by touching the ground and doing it all again.

A route that ran along a wall at 26 m/s wasn't a technique. It was a different movement game sitting on top of the first one, and it made every other speed number meaningless. The greybox has a guide wall at z = -0.5 specifically so this would be found early.

The fix was a **hard horizontal speed ceiling of 16.4 m/s** for the base wall-jump chain, together with a base cap of three. Three boosts still reach exactly 16.40 m/s, so the mechanic keeps its full base value. It just can't be repeated into a bigger number.

The shipped `wall_kiss_chain` Fracture is the one thing that extends the chain. Its registry text says "stacks to ×5", and registry text never changes once it has shipped. The controller method `enable_wall_kiss_chain_fracture()` applies that registry behaviour: the chain goes to five and the ceiling goes to **18.0 m/s**, the Fracture ceiling. That's where 18.0 m/s belongs. It isn't the base ceiling.

Two points are worth stating plainly. The exploit wasn't designed in. Nothing in the code said "let the player chain infinitely"; it followed from an uncapped boost, and the harness found it by playing the technique and printing the number. The fix was also a ceiling rather than a removal. The technique still works and still rewards a player who sets it up. It just can't be farmed.

This is why the rule in `docs/MOVEMENT_RESEARCH.md` §16.2 exists. Sometimes the distance between a good speedrun technique and a movement exploit is one missing clamp. The only way to know which one you have is to go and look.

---

## 5. What the tests actually cover

There are 485 checks in fourteen suites. They aren't "does the node exist" tests.

| Suite | Checks | What it is for |
| --- | --- | --- |
| tuning | 25 | Tuning constants match `TECH_SPEC.md` section 3 |
| movement | 48 | Movement is frame-exact |
| characterization | 77 | Movement accidents stay characterized |
| discovery | 26 | What the movement permits |
| camera | 17 | The camera rig behaves |
| input map | 24 | The input map is the scheme we said |
| determinism | 8 | The simulation is deterministic |
| speed meter | 11 | The speed is measured in metres per second |
| performance | 10 | The performance budget holds |
| code policy | 10 | The code policy holds |
| world data | 39 | The world data holds together |
| canon | 115 | The canon holds |
| greybox | 36 | The greybox holds together |
| PSX | 39 | The player picks how much PSX there is |

The movement suite pins the top speed, acceleration rates, coyote time, jump buffer, air cap, slide, wall-kiss and plane constraint. Characterization preserves the arming and chain boundaries, collision energy, repeated cycles, adversarial input and full-state replay. The camera suite checks the pitch clamp, yaw wrap, speed dolly and the camera's ownership by the rig.

The determinism suite checks that the same inputs give the same outputs and that the section-seeded generator is stable. The speed-meter suite covers the current reading, peak, reset and units. Performance checks the project settings and the cost of a frame.

The world-data suite keeps the 25×12 grid, prequel, gate schedule, Fracture registry, endings and beats together. The canon suite covers the cast, silence, arsenal, enemy roster, numbers and the documents that have to agree with them. The greybox suite covers the scene, player, camera, plane, budget, materials, help panel and a 90-second route. The PSX suite checks the globals, shader, clamping, settings round trip and the slider in the menu.

The camera, movement and determinism suites matter most to the game. A one-frame error in the coyote window is invisible in a screenshot and ruins every recorded route, so it's asserted to the frame.

The code-policy suite protects the project rather than the game. It enforces the four rules from `CONTRIBUTING.md` that a reviewer can't check from a diff: every script carries the GPL notice, gameplay code has no global random numbers, the frame loops have no allocations, and the frame loops have no `await`.

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

The runner is a **scene** (`res://tests/run_all.tscn`), not a `--script` main loop. A script main loop doesn't register the autoload singletons as global identifiers, so `WsGame` fails to compile there and a suite that touches the menu can't be written at all. The runner was a script for two days and it was a lie about how the game runs.

It exits non-zero when a check fails, so CI is one line.

---

## 7. What is deliberately not here yet

The greybox is a test rig, not a level. There isn't any section geometry beyond what the movement tests need.

The art is flat placeholder colour. All the visual work is done by hand outside the engine.

Most Fractures are still data. `wall_kiss_chain` has its controller behaviour and stable registry entry now; the other eleven have no gameplay implementation. Their triggers will be built once the movement settles, because a Fracture that depends on movement behaviour which later changes is a bug report.

The full speedrun systems aren't here. `Tab` can show splits, but there's no timer, ghost or leaderboard format yet.

The story data is written in `data/story/`. The engine doesn't read it yet.

---

## 8. What Level 2 needs

Level 2 is the first playable section, and it needs three things from this stage.

First, a movement feel that survives contact with a real level. The greybox has no obstacles that demand a precise line. Level 2 needs one.

Second, the filament verb. It's tuned (`0.25 s`, `18°`) but isn't implemented, because it's the first verb that touches something other than the ground.

Third, the first Fracture. The fracture site in chapter 13 (`13.03`) is the design's promise that the movement has depth worth exploiting, and it only works if the movement underneath it is stable.

The number that matters most for Level 2 is 16.40. A base route that peaks at 16.4 m/s and falls back to 14 m/s has room for both approaches. A section built around a wall that can be farmed has nothing. The Fracture route may reach 18.0 m/s, but that ceiling belongs to `wall_kiss_chain`, not to the base movement.
