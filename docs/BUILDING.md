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

This is built. A section is made in the editor, without touching a script.

### The pieces

`world/kit/` holds the pieces you drag into a room. They are scenes, so
editing one edits it everywhere it is used.

| Piece | What it is |
| --- | --- |
| `floor.tscn` | A flat slab. Its size is the number you type. |
| `wall.tscn` | A wall. Same. |
| `platform.tscn` | A thin slab to jump on. |
| `ramp.tscn` | A slab tilted into a slope, with a rise you type. |
| `room_shell.tscn` | A floor, four walls and optionally a ceiling, all from one size. |
| `section_point.tscn` | A point in the room: a gate, a checkpoint, a wind volume, a hazard, a filament anchor, a parcel, a spawn, a split marker. |

The geometry is made from the numbers when the piece loads, in the editor and
in the game. Change the size in the Inspector and the mesh and the collision
follow. There is no mesh file to open and no modelling tool in the loop.

### The points

A point is a thing the designer places and names. Its **kind** decides which
properties the Inspector shows, so a gate never asks you about the wind
strength.

The kinds are: section trigger, regulation gate, checkpoint, wind volume,
hazard volume, filament anchor, parcel, spawn and split marker.

The **section trigger** is the one that matters. Every section has exactly
one, named `SectionTrigger`, and it carries the section id and the three
markers: where the player starts, where the player ends and where the
speedrun split goes.

### Making a section

1. Open the editor. The **Level Tools** dock is on the right.
2. Type the section id, `2.01` for example.
3. Press **create section scene**. The scene is made in the right folder with
   the right ids, a room, a trigger, the checkpoints, the split marker and
   the gates the schedule asks for, and it opens in front of you.
4. Lay the room out. Drag the pieces in, type their sizes, move them.
5. Place the points. Name each one after the id it has in the data.
6. Press **export section data** in the Inspector of the section root, or
   press **export sections** in the dock.

The example section `data/sections/cP1/sP1_01.tscn` is laid out like this.

### What the JSON is for

The game loads the scene. The JSON beside it, `sP1_01.json`, is the mirror:
the same points and the same gate timings, written down so the tests and the
outside tools can read them without opening Godot.

The build checks the mirror against the scene. If you move a gate and forget
to export, the build fails and says so. That is the whole point of it.

### The commands

```bash
godot --headless --path . --script res://tools/export_sections.gd -- --export
godot --headless --path . --script res://tools/export_sections.gd -- --check
```

CI runs the check. You do not have to remember either command, because the
dock does the same thing.

### What the exporter complains about

- a point with no name
- two points with the same name
- a point that says it belongs to another section
- a section with no trigger, or with two
- a trigger that is not called `SectionTrigger`
- a start, an end or a split that points at nothing in the section
- a gate the schedule does not know about
- a gate in the schedule that is not in the scene
- a scene that calls itself something the campaign index does not agree with

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

The kit scenes under `world/kit/` are yours. Change a default size in
`floor.tscn` and every floor in the game changes with it. Nothing in the
build overwrites them.

`assets/icon.svg` and `assets/icon.png` are finished. Do not regenerate them.

## If something breaks

Tell me what you did and what you saw. I will not touch your scenes and
scenes you have not opened. If a change of mine breaks your work, that is my
bug and I fix it, not you.
