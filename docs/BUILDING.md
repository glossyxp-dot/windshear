# Building WindShear

You build the game. I keep the documents and the plumbing. This is how the
split works, what you do, and what I do.

## The split

| You | I |
| --- | --- |
| Movement feel: drag a slider and feel it change | The code that makes the slider live, and the constants underneath it |
| Maps: draw the base in TrenchBroom, place the points | The kit of reusable pieces, the converter, the exporter, the data checks |
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

### Drawing the base in TrenchBroom

The base of a section — the floor, the walls, the platforms, the slopes and
the points — is drawn in **TrenchBroom**, which is the modern Hammer. It has
the 2D grid and the 3D view side by side, and it writes a text `.map` file, so
the map can be read by a program, checked by a test and reviewed in a diff.

TrenchBroom is a drawing tool here, not a level editor for the whole game. The
textures, the menus, the GUI and the story all stay in Godot.

It is installed at `~/Applications/TrenchBroom.AppImage`, and the WindShear
game is installed beside it:

```bash
mkdir -p ~/.config/TrenchBroom/games
cp -r tools/trenchbroom/game/WindShear ~/.config/TrenchBroom/games/
```

After that, **File → New Map** offers **WindShear**, and the entities come
out of a list instead of being typed.

The loop is four steps:

```bash
# 1. make a starter map for the section
godot --headless --path . --script res://tools/trenchbroom/import_map.gd -- \
    --template P1.02 --out maps/P1_02.map

# 2. draw the base in TrenchBroom and save

# 3. convert it into a section
godot --headless --path . --script res://tools/trenchbroom/import_map.gd -- \
    --map maps/P1_02.map --section P1.02

# 4. open data/sections/cP1/sP1_02.tscn in Godot, or play it in the playground
```

The converter never writes over a section that is already there. It stops and
says so, and `--overwrite` has to be typed to make it do it.

`tools/trenchbroom/README.md` has the whole thing: the names the converter
reads, the units, what happens to a box and what happens to a slope, and the
commands.

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

### Two rules that protect your work

**A scene that is already there is never written over.** Pressing **create
section scene** on a section you have already made opens it instead of
replacing it. The builder refuses to write over a file that exists, and the
test suite checks that it does.

**Renaming a section is one button.** The name, the difficulty and the par
time live in the section root and in the campaign index, and the two have to
agree. Change the name in the Inspector, press **update the index** in the
dock, and the index hears about it. You never open the JSON by hand.

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

This is built too. The look lives in one file and the pieces are scenes you
drag in.

### The styles

`ui/theme/windshear_theme.tres` is where every colour, border and font size
lives. A control picks a style in the Inspector, under **Theme**, **Type
Variation**:

| Style | What it is for |
| --- | --- |
| `WsTitle` | The big name of a screen |
| `WsHeading` | The blue heading of a panel |
| `WsCaption` | The small grey text |
| `WsValue` | The number on the right of a row |
| `WsPanel` | A panel with a brighter edge |

If a control carries its own colour instead of a style, the look is in two
places and changing it means opening every screen. The test suite checks
that the screens point at the theme.

### The pieces

`ui/kit/` holds the pieces you drag into a screen:

| Piece | What it is |
| --- | --- |
| `ws_heading.tscn` | A blue heading |
| `ws_button.tscn` | A button with the right height |
| `ws_row.tscn` | A label on the left, a value on the right |
| `ws_divider.tscn` | A thin rule |
| `ws_panel.tscn` | A panel with a title and a box to fill |

To add a row to a panel, right-click the instance in the scene tree and
turn on **Editable Children**, then drop your rows into the **Content** box.

### The rules that keep it sharp

- The buffer is 480 by 270. Nothing may be wider or taller than that.
- The font sizes are 8, 9, 10, 11, 12 and 30. A new one is a decision, and
  the suite checks.
- A button has a focus style, so a controller player can see what is
  selected. That is why `focus` is in the theme.
- A pause menu is a `PROCESS_MODE_ALWAYS` canvas layer, and the HUD is
  `PROCESS_MODE_PAUSABLE`. That is the whole trick to pausing.
- The theme is yours. Change a colour there and every screen follows.

## Phase four: playing your own section

This is built too. The section you made in the editor is a scene the game
loads, so you can stand in it without anybody writing a line of code.

Open `world/playground/section_playground.tscn` and press **F6**.

The section id is a number in the Inspector. Change it, press **F6** again,
and you are in another section. It is the same loop as the movement room:
change one thing, run it, look at it.

| | |
| --- | --- |
| `W` `A` `S` `D` | walk, camera-relative |
| `Ctrl` | slide |
| `Space` | jump |
| mouse | camera |
| `R` | back to the start checkpoint |
| `F1` or `H` | the controls, on screen |

The player starts at the **start checkpoint** of the section. That checkpoint
is where the feet go, so put it where you want the player to begin. If it is
in the wrong place, you see it immediately.

The line at the top says the section, the speed in m/s, the peak speed, and
where the player is. It refreshes ten times a second, not every frame.

### How the section gets there

`WsSections` is an autoload. It reads `data/sections/index.json`, finds the
scene the id belongs to, loads it and holds it. The **section trigger** in
the scene registers itself with the manager when it enters the tree, and the
manager checks that the three markers point at points that exist. If one of
them does not, the manager says so in the output.

That check is the same one the exporter makes. A section that cannot be
finished never reaches the screen.

### What is not here yet

The hazards are volumes, the filament throws, and the story beats play. The
sections are made and loaded and the player stands in them, the gates open
and close on the schedule, and the HUD shows the objective. The rest is the
next phase.

## Phase five: playing the game

This is the part where the thing you made becomes a game.

Press **NEW RUN** in the menu. The screen loads a section, drops the player
at its start checkpoint, puts the objective in the corner, and waits. Walk to
the end checkpoint and the section clears, the banner says so, and the next
section you have written starts. When there is no next section, the run ends
and the menu says **RUN COMPLETE**.

| | |
| --- | --- |
| `W` `A` `S` `D` | walk, camera-relative |
| `Ctrl` | slide |
| `Space` | jump |
| mouse | camera |
| `R` | back to the start checkpoint |
| `Esc` | back to the menu |

**MOVEMENT ROOM** in the menu still opens the plain greybox, which is where
the movement feel is tested on its own.

### The objective

The section root has an **objective** box in the Inspector. Whatever you
write there is what the HUD shows, in capitals, under the section name.
Leave it empty and the HUD says **REACH THE EXIT**.

It is your own words. The objective is not in the campaign index and nobody
edits it but you.

### The gates

A regulation gate is a point in the room with a width and a height. When the
section loads, the gate grows a barrier: a glowing slab, four metres wide
and three tall by default, standing on the point.

The schedule says when it opens. A gate that does not cycle is open or
closed for the whole run. A gate that cycles moves through its windows, and
the run clock is what it moves on, so a gate keeps its rhythm from one
section to the next.

The gate is a wall while it is closed and nothing at all while it is open.

Two things to know:

- The point says where the gate **meets the floor**, and the barrier grows
  upwards from there.
- The gate turns on its point's rotation. The width runs along the local X
  axis, so a gate across a corridor running north to south is turned a
  quarter turn.

The editor draws the barrier, so you can see the gate you are placing and
size it. The drawing is the editor's copy only; the game makes its own when
the section loads, and neither is ever saved into the scene file.

If you add a gate by hand, the schedule has to have an entry for it or the
build fails and says so. The gates the builder makes for you are already in
the schedule.

### The next section

The campaign is three hundred sections long. The run walks into the next one
**you have written**, so the game keeps playing as you build. When there is
nothing left, the run ends.

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

The maps under `maps/` are yours. The converter reads them and never writes
over a section that is already there.

`assets/icon.svg` and `assets/icon.png` are your own art and they are finished. Nothing regenerates them.

## If something breaks

Tell me what you did and what you saw. I will not touch your scenes and
scenes you have not opened. If a change of mine breaks your work, that is my
bug and I fix it, not you.
