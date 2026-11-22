<!--
SPDX-FileCopyrightText: 2026 the WINDSHEAR contributors
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Section scenes

The world is twenty chapters of twelve sections. One section is one streaming
cell and one `PackedScene`.

## Naming

A section id is `chapter.section`, with the section zero-padded — `13.03`, not
`13.3`. The scene path follows from it:

```text
res://data/sections/c<chapter>/s<chapter>_<section>.tscn
```

So:

```text
res://data/sections/c1/s1_01.tscn
res://data/sections/c13/s13_03.tscn
res://data/sections/c20/s20_12.tscn
```

`index.json` is the machine-readable index of the whole grid. It holds the id,
the display name, the scene path, the difficulty and the par time for all 240
sections. A scene path in the index has to match the pattern exactly — the
world data test checks it, and so does anything that loads a section by id.

The id is stable. Splits, saves, leaderboards and community route files all use
it, so renaming a section means breaking someone's splits file.

## What goes in a section scene

- Merged geometry — usually `MeshInstance3D` or `MultiMeshInstance3D`.
- Static and moving colliders.
- `SectionTrigger`, which defines the boundary.
- `RegulationGate`, which names a gate id from `data/schedule.json`.
- `WindVolume` for thermals, crosswinds and dead zones.
- `FilamentAnchor` with one of the zip, ring or hold types.
- `Checkpoint` nodes.
- `Parcel` nodes.
- `RegulatorDrone` and `WindRegulator` nodes.
- `HazardVolume` nodes.
- `BeatDirector`, which resolves the section's story file.

Geometry is authored for the play plane, with the staged depth layers behind
it. Node counts stay under the draw-call and memory budgets in `TECH_SPEC.md`
§2.

## SectionTrigger

Every section has exactly one node named `SectionTrigger`. It declares four
things:

```text
section_id             stable chapter.section id
start_checkpoint_id    checkpoint used at section entry
end_checkpoint_id      checkpoint used for the safe respawn at section exit
split_marker_id        marker the speedrun split system uses
```

On entering the tree it registers its section id with the section manager and
hands over the three markers. Registration is rejected if the id isn't in the
index, or if a marker doesn't resolve to a node in the same section — both are
typos that would otherwise produce a section that loads and can't be finished.

`RegulationGate` names its `gate_id`, e.g. `13.03.gate_01`. `BeatDirector`
names the same `section_id` as the trigger, which is how the story service
finds `data/story/beats/<section-id>.beat.json`.

## Boundaries

Every section needs a start checkpoint, an end checkpoint and a split marker.
The start is the respawn state on entry. The end is the state carried into the
next section. The split marker lines up with the section-entry split that
`SectionTimer` emits. Missing any one of the three is a validation error.

One more rule, and it's the one that gets forgotten: a section has to be
finishable without a Fracture route. A closed or cycling gate therefore needs
an alternate line through the section. The scheduled gate is never the only
way through.
