# TrenchBroom and the map converter

TrenchBroom draws the **base** of a WindShear section: the floor, the walls,
the platforms, the slopes and the points the game reads. The converter turns
that map into a section the game can run.

Everything else stays in Godot: the textures, the menus, the GUI, the story
and the art. TrenchBroom is a drawing tool here, not a level editor for the
whole game.

```
   TrenchBroom                    the converter                 Godot
 ┌──────────────┐            ┌───────────────────┐        ┌──────────────┐
 │  the map     │  .map      │  a section scene  │  .tscn │  the game    │
 │  the brushes │ ─────────► │  the kit nodes    │ ─────► │  the room    │
 │  the points  │            │  the section data │        │  the texture │
 └──────────────┘            └───────────────────┘        └──────────────┘
```

## Why TrenchBroom

It is the modern Hammer. It has the 2D grid and the 3D view side by side, it
draws with brushes, it places point entities, it imports models, and it writes
a **text** `.map` file, which is the part that matters: a text file can be
read by a program, checked by a test and reviewed in a diff.

The converter is mine to keep. The editor is a program that already exists and
already works.

## Installing TrenchBroom

Either:

```bash
yay -S trenchbroom-bin      # the AUR package. No dependencies.
```

or download the AppImage from the TrenchBroom site and put it somewhere:

```bash
mkdir -p ~/Applications
cp TrenchBroom.AppImage ~/Applications/
chmod +x ~/Applications/TrenchBroom.AppImage
```

On this machine it is already installed at
`~/Applications/TrenchBroom.AppImage`, with a menu entry in
`~/.local/share/applications/trenchbroom.desktop`.

## Installing the WindShear game

TrenchBroom shows a list of games. WindShear is one of them, and it has to be
told where to look:

```bash
mkdir -p ~/.config/TrenchBroom/games
cp -r tools/trenchbroom/game/WindShear ~/.config/TrenchBroom/games/
```

That folder holds three files:

| File | What it is |
| --- | --- |
| `GameConfig.cfg` | The game itself: the name, the map format, the entity list |
| `WindShear.fgd` | The entities, so they can be picked out of a list instead of typed |
| `initial_valve.map` | The map a new WindShear map starts from |

After that, **File → New Map** offers **WindShear**.

The game folder is checked into the repository, so the install is one copy and
it never drifts from the converter.

## The loop

1. Make a starter map for the section:

   ```bash
   godot --headless --path . --script res://tools/trenchbroom/import_map.gd -- \
       --template P1.02 --out maps/P1_02.map
   ```

   It is a room, the points the section needs and a comment that says what
   everything is.

2. Open `maps/P1_02.map` in TrenchBroom. Draw the base of the section: the
   floor, the walls, the platforms, the slopes. Move the points where they
   belong. Save.

3. Convert it:

   ```bash
   godot --headless --path . --script res://tools/trenchbroom/import_map.gd -- \
       --map maps/P1_02.map --section P1.02
   ```

   It writes `data/sections/cP1/sP1_02.tscn` and the JSON beside it, and
   prints a report.

4. Open `data/sections/cP1/sP1_02.tscn` in Godot, or open
   `world/playground/section_playground.tscn` and press **F6** to play it.

## The names

The converter reads these classnames. They are in `WindShear.fgd`, so they
come out of a list in TrenchBroom rather than being typed.

### The points

| Classname | What it is | Properties |
| --- | --- | --- |
| `func_checkpoint_start` | where the player starts | |
| `func_checkpoint_end` | where the player finishes | |
| `func_split_marker` | where the split timer is | |
| `func_gate` | a regulation gate | `width`, `height` |
| `func_hazard` | a hazard volume | `hazkind`, `damage` |
| `func_wind` | a wind volume | `windkind`, `strength`, `direction` |
| `func_filament` | a filament anchor | `anchortype` |
| `func_parcel` | a parcel | |
| `func_spawn` | where something appears | |
| `info_player_start` | where the player starts | |

The choices are words, not numbers, so the map file says `"hazkind" "blade"`
and not `"hazkind" "1"`. The values are:

| Property | Values |
| --- | --- |
| `hazkind` | `fall`, `blade`, `regulator` |
| `windkind` | `thermal`, `crosswind`, `dead_zone` |
| `anchortype` | `zip`, `ring`, `hold` |

The gate's `width` and `height` are in **map units**, and the converter turns
them into metres. The default is 128 by 96 units, which is four metres by
three.

The start, the end and the split have fixed ids, because the section trigger
points at them. The gate takes the id the schedule gives it, in the order the
gates appear in the map. Everything else is numbered in the order it appears.

### The brushes

A brush says what shape it is in two ways, and either one is enough:

| Classname | What it is |
| --- | --- |
| `func_floor` | a floor |
| `func_wall` | a wall |
| `func_platform` | a platform |
| `func_ramp` | a ramp |

| Material name | What it is |
| --- | --- |
| `floor` | a floor |
| `wall` | a wall |
| `platform` | a platform |
| `ramp` | a ramp |

The material name is looked for inside the whole name, so `floor_surface` is a
floor and `wall_charcoal` is a wall. The second word says which of the four
materials the piece wears: `surface`, `deep`, `charcoal` or `glow`.

The material names are **tags**, not pictures. There are no textures in this
folder and none are needed: the texture on a surface is made in Godot.

## Units and axes

The map is in map units and the game is in metres. Quake's world is 32 units
to the metre, and that is the default. A map made for another scale says so
with `--units-per-metre`.

| | In the map | In Godot |
| --- | --- | --- |
| East | +X | +X |
| Up | +Z | +Y |
| North | +Y | -Z |

A point at map `32 64 16` is at Godot `1, 0.5, -2`. A yaw is 90 degrees
different, because the north is the other way round.

## What the converter does with the shapes

The kit a section is built from is made of boxes, so this is the part that
has to be honest.

| The brush | What comes out |
| --- | --- |
| A box, square to the floor | an exact block of the same size |
| A wedge: one slanted face and five square ones | a ramp along the slope, with the surface lying on the slope the mapper drew |
| Anything else | the box around it, and a line in the report saying so |

The ramp is a plank, so it is thinner than the wedge at the low end. The
surface is what matters: it lies on the slope, so the player walks on the
surface that was drawn.

## What the converter refuses to do

**It never writes over a section that is already there.** The converter stops
and says so. `--overwrite` is there for when you mean it, and you have to
type it.

The same is true of the starter map. A map that is already there is never
written over.

## The commands

```bash
# make a starter map
godot --headless --path . --script res://tools/trenchbroom/import_map.gd -- \
    --template P1.02 --out maps/P1_02.map

# convert a map into a section
godot --headless --path . --script res://tools/trenchbroom/import_map.gd -- \
    --map maps/P1_02.map --section P1.02

# the same, but write over the section that is there
godot --headless --path . --script res://tools/trenchbroom/import_map.gd -- \
    --map maps/P1_02.map --section P1.02 --overwrite

# a map made for another scale
godot --headless --path . --script res://tools/trenchbroom/import_map.gd -- \
    --map maps/P1_02.map --section P1.02 --units-per-metre 16
```

The converter prints what it did, one line per thing, and the problems on the
error stream.

## The files

| File | What it is |
| --- | --- |
| `tools/trenchbroom/ws_map_parser.gd` | Reads a `.map` file into plain dictionaries |
| `tools/trenchbroom/ws_map_geometry.gd` | Works out the shape of the brushes |
| `tools/trenchbroom/ws_map_importer.gd` | Turns the map into the nodes of a section |
| `tools/trenchbroom/ws_map_template.gd` | Writes the starter map |
| `tools/trenchbroom/import_map.gd` | The command line |
| `tools/trenchbroom/game/WindShear/` | The game TrenchBroom offers |
| `maps/` | Your maps |
| `tests/test_trenchbroom.gd` | The tests for all of it |

The parser and the geometry do not decide what a map means. They read it, and
the importer decides what a floor is. That is why the tests can check what was
read without a scene tree.

## The tests

```bash
godot --headless --path . res://tests/run_all.tscn
```

`tests/test_trenchbroom.gd` reads the hand-written fixtures in
`tests/fixtures/trenchbroom/`, checks the shape of the brushes, turns map
units into metres, places the points with the ids the trigger and the schedule
expect, lays a ramp along a slope, and checks the converter never writes over
a section that is already there.

## What is not here

- **Textures.** They are made in Godot, by hand. The material names in the map
  are tags.
- **The menus and the GUI.** They are Godot scenes.
- **The story.** It is in `data/story/`, as plain JSON.
- **A skybox.** TrenchBroom can draw one and the map can carry it, but the
  sky of a WindShear section is a Godot environment resource, chosen in the
  section root.
