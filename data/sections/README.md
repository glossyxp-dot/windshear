<!--
SPDX-FileCopyrightText: 2026 the WINDSHEAR contributors
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Section scenes

The world is divided into six chapters of twelve numbered sections. Each section is one streaming cell and one `PackedScene`.

## Naming and identifiers

A section id is `chapter.section`, with a zero-padded section number, for example `4.03`. Its scene path follows this pattern:

```text
res://data/sections/c<chapter>/s<chapter>_<section>.tscn
```

Examples:

```text
res://data/sections/c1/s1_01.tscn
res://data/sections/c4/s4_03.tscn
res://data/sections/c6/s6_12.tscn
```

`data/sections/index.json` is the machine-readable index of the planned grid. A scene path in the index must match this pattern exactly. A section's stable id is used by every subsystem, including split marker data.

## Scene composition

A section scene may contain the following node types:

- Merged geometry, normally `MeshInstance3D` or `MultiMeshInstance3D`.
- Static and moving colliders.
- `SectionTrigger`, which defines the section boundary.
- `RegulationGate`, which references a gate id in `data/schedule.json`.
- `WindVolume`, covering thermals, crosswinds, and dead zones.
- `FilamentAnchor`, with one of the zip, ring, or hold anchor types.
- `Checkpoint` nodes.
- `Parcel` nodes.
- `RegulatorDrone` nodes.
- `WindRegulator` nodes.
- `HazardVolume` nodes.
- `BeatDirector`, which resolves the section's official or Edition story file.

Geometry and colliders are authored for the cell's plane and staged depth layers. Node counts stay below the draw-call and memory budgets in `TECH_SPEC.md`.

## SectionTrigger registration

Every section contains exactly one node named `SectionTrigger`. It declares:

```text
section_id             Stable chapter.section id
start_checkpoint_id    Checkpoint used at section entry
end_checkpoint_id      Checkpoint used for the safe respawn at section exit
split_marker_id        Marker used by the speedrun split system
```

When the section enters the scene tree, `SectionTrigger` registers its section id with the section manager and provides the start, end, and split markers. The registration is rejected if the id is absent from the section index or if a marker does not resolve to a node in the same section.

A `RegulationGate` declares its matching `gate_id`, such as `1.02.gate_01`. A `BeatDirector` declares the same `section_id` used by the `SectionTrigger` so the story service can resolve `data/story/beats/<section-id>.beat.json`.

## Required boundaries

Every section must declare a start checkpoint, an end checkpoint, and a split marker. The start checkpoint defines the entry respawn state, the end checkpoint defines the state carried into the next section, and the split marker must align with the section-entry split emitted by `SectionTimer`. Missing any of the three is a section validation error.

The section must remain completable without a Fracture route. A closed or cycling Concord gate therefore requires an alternate line through the section rather than making the scheduled gate mandatory.
