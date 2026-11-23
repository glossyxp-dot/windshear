<!--
SPDX-FileCopyrightText: 2026 the WINDSHEAR contributors
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Official story data

The story is a data layer. It supplies dialogue, per-section beats and ending
conditions, and it doesn't touch the world, the movement code or the section
grid. That's why an Edition can replace all of it without forking the game.

The current story layer has 73 dialogue lines across 10 speakers, plus 19 beat
files under `data/story/beats/`. The speakers are Lancer, Ilsa Renn, Warden
Saye, THE CONCORD, FIRST RUNNER, CIVIL DEFENSE, Dr. Aris Thorne, Sergeant
Miller, Henrik Solberg and Talia Korr.

## Layout

```text
data/story/
  dialogue/en.json
  endings.json
  beats/
    <section-id>.beat.json
```

Every JSON file has a top-level `_meta` object with an `spdx` key, because
JSON can't hold a comment header. Community Editions follow the same
convention, and `editions/README.md` writes it up.

## Who is allowed to speak

Lancer Ivanov never speaks. There are no spoken Lancer lines in the dialogue
file. The lines attached to the `lancer` speaker are bracketed action
directions, and that speaker entry carries `"silent": true`, so a tool can
tell the difference between a character talking and a character doing
something.

Ilsa Renn is she/her, and she's silent throughout the five Fracture Year
prequel chapters, `P1` to `P5`. She is the playable character in Act 0, and
the canon suite fails the build if one of her spoken lines turns up in a
prequel beat. In the present day she talks, and what she says is usually a
route.

Every other character speaks. Warden Saye is she/her. Dr. Aris Thorne,
Sergeant Miller and Henrik Solberg are he/him, and Talia Korr is she/her.
Lancer is the only character with no pronouns, anywhere, in any locale.

The full cast registry lives in `data/cast.json`. It records each character's
pronouns, the acts they appear in and whether they may speak. Every speaker
id used in this directory, including every id in the dialogue file, has to be
in that registry; if one isn't, the canon suite fails the build.

## Identifiers

A section id is `chapter.section`, for example `13.03`. A beat id is
`chapter.section.label`, for example `13.03.FRACTURE`. Dialogue ids stay
stable within their locale, for example `en.014`, so resolve them by id;
array position isn't part of the contract.

Actor ids are lower-case stable names such as `lancer`, `ilsa_renn` or
`warden_saye`. World scenes expose them as node metadata under `actor_id`. A
marker id names a position on one actor's path. It's local to that actor and
never a global identifier.

## How a beat gets resolved

The `BeatDirector` in a section asks the story service for
`<section-id>.beat.json`. A beat file only applies to the `section_id` it
declares, and files never reach across section boundaries.

A beat declares its `mode`, either `AMBIENT` or `MAJOR`, and its `trigger`:
`section_entry`, a frame offset or an `actor_marker`. The `actors` are the
actor ids the beat animates or binds dialogue to. Its `dialogue` is resolved
from the active locale, while `duration_frames` gives the authored length at
the 60 Hz tick. `control` and `world_time` spell out the runtime rules rather
than leaving them implied, and `exit` says what releases the beat.

A section-entry trigger fires when the section becomes active. A frame
trigger counts from section entry. An actor-marker trigger waits for that
actor to reach that marker. Triggers are evaluated in file order, and only
one beat runs at a time.

Before a beat starts, every actor id is resolved against the current section.
A missing actor is a content error. The director names it, skips the beat and
leaves control and world time alone. Freezing the game and only then
discovering that the actor isn't there is the worst possible order of
operations.

## AMBIENT

Normal world time. The player keeps control and can walk out mid-sentence
without a penalty. Dialogue is short, in-frame and skippable. This is what
most beats should be: the world talking to itself while you run through it.

## MAJOR

Input locks and world time freezes (`Engine.time_scale = 0`). Scripted actors
and their effects run on unscaled time so they can still move. The camera
stays the Lancer rig, locked to Lancer's last position. It never becomes a
cutscene camera.

When the script ends, control and normal time come back after a two-frame
count. A major beat has to name every actor it animates, and the director
validates those ids before it locks anything.

## The prequel

Act 0 is five chapters played as Ilsa Renn, twenty years before the first
present-day chapter. Its sections are keyed `P1` to `P5`, so a prequel beat
file is `P4.12.beat.json` and a prequel section id is `P4.12`.

The prequel has its own rules and its own tone. There is no Concord for the
first two chapters, only a war, so the bulletins come from civil defence
instead. The Concord arrives in P3 and the canopy closes in P4. By P5 the
city is walled and quiet, and the Concord is reading the courier's telemetry.

That telemetry is the point of P5. Ilsa breaches the wall through an
uncalibrated vent and a Grown Seam, and does not know that the route she
just ran has become the FIRST RUNNER baseline, the movement profile the
Concord has been running as a patrol training model for twenty years.

The prequel has its own arsenal too. The P-20 "Courier", V-9 "Vigil" and
M98 "Longhorn" are shared with the present day. The M-44 "Seam-Splitter" and
Pneumatic Grapple Spool are prequel only.

Its roster is separate as well. Concord military infantry, artillery and
synths don't exist in 20XX; the only Concord constructs are the early
bio-constructs.

## Endings

`endings.json` lists each ending with a stable id, a display name, a priority
and a condition set. The conditions are typed facts. `final_choice` compares
the final decision id, `fracture_known` checks one Fracture id,
`fracture_known_count` compares how many Fractures the player knows, and
`section_reached` checks a section id.

The first matching ending in priority order wins. `THE SECOND FRACTURE` sits
at the top because finding the First Runner's path overrides whatever the
player picked at the end.

## How an Edition overrides this

At boot, an Edition's `story_path` points at its own story root. A file at the
same relative path replaces the official one: `endings.json` replaces the
ending table, `dialogue/en.json` replaces that locale, and a beat file
replaces the beat for its section. Anything the Edition doesn't supply keeps
the official default, so changing one section doesn't mean copying the whole
story layer.

An Edition can rewrite dialogue, beats and endings and still reuse the world,
the mechanics, the section ids and the actor ids. Replacing the world is a
different job and doesn't need an Edition at all, though an Edition is
allowed to ship replacement art in its own `assets/` directory.
