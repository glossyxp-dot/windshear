<!--
SPDX-FileCopyrightText: 2026 the WINDSHEAR contributors
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Official story data

The official story is a data-only layer. It supplies dialogue, per-section beats, and ending conditions without changing the shared world, movement code, or section grid.

## Layout

```text
data/story/
  dialogue/en.json
  endings.json
  beats/
    <section-id>.beat.json
```

Every JSON file contains a top-level `_meta` object. Its `spdx` value is the SPDX license identifier, because JSON cannot carry a comment header. The same convention is documented for community Editions in `editions/README.md`.

## Identifiers

- A section id is `chapter.section`, for example `4.03`.
- A beat id is `chapter.section.label`, for example `4.03.FRACTURE`.
- A dialogue id is stable within its locale, for example `en.014`. Consumers resolve by id and must not depend on array position.
- An actor id is a lower-case stable name such as `lancer`, `ilsa`, or `warden_saye`. World scenes expose the id in node metadata under `actor_id`.
- A marker id names a position on an actor path. It is local to the actor and is not a global identifier.

## Beat resolution

The `BeatDirector` in a section asks the story service for the file named `<section-id>.beat.json`. A file applies only to its declared `section_id`; beat files never cross section boundaries.

Each beat contains:

- `mode`: `AMBIENT` or `MAJOR`.
- `trigger`: `section_entry`, `frame`, or `actor_marker` trigger data.
- `actors`: actor ids that the beat animates or binds dialogue to.
- `dialogue`: dialogue ids resolved from the active locale file.
- `duration_frames`: the authored beat length at the fixed 60 Hz tick rate.
- `control` and `world_time`: explicit runtime rules.
- `exit`: the conditions for releasing the beat.

A section-entry trigger starts when the section becomes active. A frame trigger uses a frame offset from section entry. An actor-marker trigger waits for the named actor to reach that marker. Triggers are evaluated in file order and only one beat is active at a time.

The story service resolves every actor id against the current section before starting the beat. Missing actor ids are a content error. The beat director reports the missing actor and skips the beat, so control and world time remain available.

## Beat modes

### AMBIENT

An ambient beat runs at normal world time. Player control remains unrestricted, the player may leave the scene without penalty, and world simulation continues without an override. Ambient dialogue is short, in-frame, subtitled, and skippable.

### MAJOR

A major beat locks player input and freezes world time with `Engine.time_scale = 0`. Scripted actors and their effects use unscaled time while the world is frozen. The camera remains the Lancer rig, locked to Lancer's last position; it never becomes a separate cutscene camera.

When the beat script ends, control and normal world time resume after a two-frame count. A major beat must name every actor it animates. The director validates actor ids before locking input or world time.

## Endings

`endings.json` lists every ending with a stable id, display name, priority, and condition set. The condition evaluator uses typed facts:

- `final_choice` compares the final decision id.
- `fracture_known` checks one Fracture id.
- `fracture_known_count` compares the number of discovered Fractures.
- `section_reached` checks a section id.

The first matching ending in priority order is selected. `THE SECOND FRACTURE` has the highest priority because revealing the First Runner's path overrides the final choice.

## Edition overrides

At boot, an Edition's `story_path` points to its story root. A file at the same relative path replaces the official file: `endings.json` replaces the ending table, `dialogue/en.json` replaces that locale, and a beat file replaces the beat file for its section. Files not supplied by the Edition continue to use the official defaults, allowing an Edition to change one section without copying the entire story layer.

An Edition may rewrite dialogue, beat scripts, and endings while reusing the same world, mechanics, section ids, and actor ids. Changing the world does not require a new Edition, although an Edition may provide replacement assets in its separate `assets/` directory.
