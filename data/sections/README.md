<!--
SPDX-FileCopyrightText: 2026 the WINDSHEAR contributors
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Section scenes

The campaign is a grid of 25 chapters with 12 sections each: 300 sections in
all. Chapters `P1` through `P5` are the Fracture Year prequel. Each section is
one streaming cell and one `PackedScene`.

## Naming

A section id is `chapter.section`, with the section number zero-padded, so
`13.03` is valid and `13.3` isn't. The scene path follows from the id:

```text
res://data/sections/c<chapter>/s<chapter>_<section>.tscn
```

That gives you:

```text
res://data/sections/c1/s1_01.tscn
res://data/sections/c13/s13_03.tscn
res://data/sections/c20/s20_12.tscn
```

`index.json` is the machine-readable index of the whole grid. It holds the id,
display name, scene path, difficulty and par time for all 300 sections, plus
the opening and the play of every chapter. The prequel chapters are keyed `P1` to
`P5`, so their scenes start with
`res://data/sections/cP1/sP1_01.tscn`. Present-day chapters are keyed 1 to 20.
In `index.json`, a prequel chapter key is a string and a present-day chapter
key is a number; the tests normalise both forms before comparing them.

Every scene path in the index has to match the pattern exactly. The world data
test checks it, and so does anything that loads a section by id.

The id is stable. Splits, saves, leaderboards and community route files all
use it, so renaming a section breaks somebody's splits file. I've renumbered
exactly one section in this project and I still think about it.

## What goes in a section scene

A section scene starts with merged geometry, usually a `MeshInstance3D` or a
`MultiMeshInstance3D`, plus static and moving colliders. `SectionTrigger`
defines the boundary, while `RegulationGate` names a gate id from
`data/schedule.json`. `WindVolume` covers thermals, crosswinds and dead zones.
`FilamentAnchor` uses one of the zip, ring or hold types. There are also
`Checkpoint` nodes and `Parcel` nodes.

A scene can also contain `RegulatorDrone`, `WindRegulator` and
`HazardVolume` nodes. `BeatDirector` resolves the section's story file.

Geometry is authored at full depth. Node counts stay under the draw-call and
memory budgets in `TECH_SPEC.md` §2.

### The kit

The geometry does not have to be hand-modelled. The pieces in `world/kit/`
are scenes whose mesh and collision are made from the numbers in the
Inspector:

| Piece | What it is |
| --- | --- |
| `floor.tscn` | A flat slab |
| `wall.tscn` | A wall |
| `platform.tscn` | A thin slab to jump on |
| `ramp.tscn` | A slab tilted into a slope |
| `room_shell.tscn` | A floor, four walls and optionally a ceiling |
| `section_point.tscn` | A point in the room |

The points are `WSKitPoint` nodes. Their kind decides which properties the
Inspector shows, so a gate never asks about the wind strength. The kinds are
section trigger, regulation gate, checkpoint, wind volume, hazard volume,
filament anchor, parcel, spawn and split marker.

The kind is written into the scene as a number, so the order of the enum is a
file format. A new kind goes at the end and an old one never moves.
`tests/test_level_tools.gd` pins every number.

### The root

The root of the scene is a `WSSection`. It carries the section id and, when
it wants to repeat them, the name, the difficulty and the par time the index
already says. The exporter checks the two against each other.

### The data beside it

Each section has a JSON file beside its scene with the same name and a
`.json` ending. It holds the points and the gate timings.

The game does not read that file. The game loads the scene. The JSON is the
mirror the tests and the outside tools read, and the build fails when it no
longer matches the scene, so a forgotten export is a failed build instead of
a surprise in the game.

```bash
godot --headless --path . --script res://tools/export_sections.gd -- --export
godot --headless --path . --script res://tools/export_sections.gd -- --check
```

## SectionTrigger

Every section has exactly one node named `SectionTrigger`, and it declares
four things:

```text
section_id             stable chapter.section id
start_checkpoint_id    checkpoint used at section entry
end_checkpoint_id      checkpoint used for the safe respawn at section exit
split_marker_id        marker the speedrun split system uses
```

When it enters the tree, the trigger registers its section id with the section
manager and hands over the three markers. Registration is rejected if the id
isn't in the index, or if a marker doesn't resolve to a node in the same
section. Those are easy typos to make, and either one leaves you with a
section that loads but can't be finished.

The exporter checks the same rules before it writes anything, and the build
fails when it finds one of them broken.

`RegulationGate` names its `gate_id`, for example `13.03.gate_01`.
`BeatDirector` names the same `section_id` as the trigger, which is how the
story service finds `data/story/beats/<section-id>.beat.json`.

## Boundaries

Every section needs a start checkpoint, an end checkpoint and a split marker.
The start is the respawn state on entry, the end is the state carried into
the next section, and the split marker lines up with the section-entry split
that `SectionTimer` emits. Missing any one of the three is a validation
error.

There's one more requirement, and it's the one that gets forgotten: a section
has to be finishable without a Fracture route. A closed or cycling gate
therefore needs an alternate line through the section. The scheduled gate is
never the only way through.
