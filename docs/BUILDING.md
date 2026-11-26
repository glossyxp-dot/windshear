# Building WindShear

You build the game. I keep the documents and the plumbing. This is how the
split works, what you do, and what I do.

## The split

| You | I |
| --- | --- |
| Movement feel: drag a slider and feel it change | The code that makes the slider live, and the constants underneath it |
| Maps: lay the geometry out in the editor | The kit of reusable pieces, the exporter, the data checks |
| UI: place and style the controls | The theme, the screens, the wiring behind them |
| Art, by hand | The documents that describe it |
| Deciding what a number should be | Writing that number into the code and into the spec |

The point of the split is that the asking should be about taste and not about
plumbing. If you have to ask me how to move a slider, the plumbing is wrong
and I fix the plumbing.

## The loop

1. Open the editor.
2. Make one change.
3. Run it and look at it.
4. Keep it, undo it, or write down what you want instead.
5. Tell me what you did in one sentence. I write it into the documents and
   update everything that has to agree with it.

## Phase one: the movement workbench

Open `tools/movement_workbench.tscn` and press **F6**.

The window grows to 1280×720 and the room comes with it. Down the right side
there is a panel with a slider for every movement number. Drag one and the
room changes on the next frame, because the controller is reading the slider
rather than a copy of it.

| | |
| --- | --- |
| `W` `A` `S` `D` | walk, camera-relative |
| `Ctrl` | slide |
| `Space` | jump |
| mouse | camera |
| `F2` | hide and show the panel |
| `F3` | type in the notes box |

The mouse still turns the camera when it is over the room. It does not turn
the camera when it is over the panel, because the panel takes the clicks.

### The knobs

| Group | Knobs |
| --- | --- |
| ground | run speed, ground accel, ground decel |
| air | air accel, air cap, gravity |
| jump | jump velocity, jump cut, coyote, jump buffer |
| slide | slide time, slide friction, slide needs |
| wall-jump | wall window, wall boost, wall chain, wall chain life, speed ceiling |
| camera | mouse speed, camera back, camera back at speed, camera height, fov, fov at speed |

A knob in amber is off its documented value. A knob in white is still the
number in `TECH_SPEC.md` §3.

### Two of them talk to each other

The **speed ceiling** is the top of the wall-jump chain: the run speed plus
the boosts, and 16.4 m/s with the shipped numbers. The limit the controller
actually enforces is the higher of that ceiling and the run speed plus a
full chain, so if you raise the run speed the chain still means something and
the technique still cannot be farmed. If you want a wall-jump chain that goes
faster than the ceiling, move both knobs.

### Saving what you found

| Button | What it does |
| --- | --- |
| reset all | every knob back to the documented number |
| save profile | writes to the user data folder, outside the repository |
| load profile | reads it back |
| copy values | puts the numbers and your notes on the clipboard |
| write to repo | writes `data/tuning_profile.json`, which you can commit |

**write to repo** is the handoff. It drops a plain JSON file in the
repository with your numbers and your notes in it. Commit that file, tell me
it is there, and I write the numbers into `ws_tuning.gd`, into
`TECH_SPEC.md` §3 and into the documents, and the workbench goes back to
showing the new documented numbers.

Nothing is written to the repository until you press that button. A tuned
number is not canon until somebody writes it into the code and the spec, and
that is a decision instead of a side effect.

The profile lives in the user data folder:

```text
~/.local/share/godot/app_userdata/WindShear/movement_workbench.json
```

It is outside the repository on purpose. The headless test suite always runs
on the documented numbers, even if you have a saved profile, because only the
workbench loads it.

## Phase two: the map kit

Not built yet. This is the shape it is going to take, so you can tell me
where it is wrong before I build it.

A **kit** is a folder of reusable pieces: a room shell, a platform, a wall,
a gate, a checkpoint, a hazard volume. You drag them into a level scene,
move them around, set their numbers in the Inspector, and save. The pieces
are scenes, so editing one piece edits it everywhere it is used.

A level scene holds one **section trigger** with the section id, the
checkpoints and the split marker on it, written as exported properties. The
exporter reads those properties off the scene and writes the section JSON
the game reads, so the data you laid out in the editor is the data the game
loads. The exporter runs headless too, so CI can check that the committed
JSON still matches the scenes.

## Phase three: the UI kit

Not built yet. Same idea: a folder of reusable screens and panels — the HUD,
the objective banner, the pause menu, the item bar — that you place and
style, with the theme doing the colours and the sizes.

## What is yours and what is mine

**Yours:** everything in `ui/`, `world/` and `assets/`, the movement feel, the
layout of the maps, the look of the UI, and the art.

**Mine:** the code under `addons/windshear/`, the generators under `tools/`,
the tests, and every document in `docs/`.

**Neither, without asking:** `addons/windshear/core/ws_tuning.gd` holds every
documented movement number and `tests/test_tuning.gd` pins them against
`TECH_SPEC.md` §3. The workbench is how you move a number. I am how a number
becomes canon.

`assets/icon.svg` and `assets/icon.png` are finished. Do not regenerate them.

## If something breaks

Tell me what you did and what you saw. I will not touch your scenes and
scenes you have not opened. If a change of mine breaks your work, that is my
bug and I fix it, not you.
