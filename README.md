# WINDSHEAR

A 3D speed-and-precision platformer. You play Lancer Ivanov, a courier in a
city that a war machine sealed under a canopy, and the sealing is the problem.

Twenty years ago the sky came apart in a global war. High command dropped
something to stop it: a biomechanical siege organism called the Concord. It
worked. Nobody has seen the sun since. You carry parcels for a living, and
the parcels you carry now are not the ones the schedule approved.

Lancer never speaks. Everything Lancer has to say is a line they run.

The mouse is the camera and the mouse does the two triggers, because the
mouse is already in the hand that is pointing at the thing you want to shoot.
Everything else is on the keyboard. `W` and `S` walk forward and back, `A` and
`D` strafe, `Ctrl` slides, `Space` jumps, `Q` grabs a ledge, `E` interacts, `F`
throws the filament. Movement is camera-relative, so forward is wherever you
are looking.

Everything is open source, code and content both. If you want to tell a
different story in the same city, that's what an Edition is: a folder of JSON,
no code required. Nobody has to ask me first, and nobody has to ask you to
change the game you already downloaded.

## The documents

- [Game design](GAME_DESIGN.md) — pillars, the cast, the 25-chapter structure
- [Technical spec](TECH_SPEC.md) — renderer, budgets, every movement number
- [The Concord](docs/CONCORD.md) — what the antagonist actually is, in full
- [The arsenal](docs/ARSENAL.md) — seven weapons, five items, five map utilities
- [The enemy roster](docs/ENEMIES.md) — what the Concord puts between you and the sky
- [Controls](docs/CONTROLS.md) — the defaults, and what the mouse is for
- [Building](docs/BUILDING.md) — how we split the work, and the movement workbench
- [Movement research](docs/MOVEMENT_RESEARCH.md) — the sources behind the movement numbers
- [Dev Stage 1](docs/dev_stage_1.md) — how far the movement base got, and the bug the discovery harness found
- [Authoring by hand](docs/AUTHORING.md) — opening the project and decorating it without touching code
- [The map converter](tools/trenchbroom/README.md) — drawing the base of a section in TrenchBroom
- [Architecture](docs/architecture.md) and [testing](docs/testing.md)
- [Contributing](CONTRIBUTING.md)
- [Start here](START_HERE.md)

## Where it's up to

Dev Stage 1. The project boots, the menu works, Lancer moves.

There are 929 headless checks and they all pass. The movement is frame exact
at 60 Hz and the HUD reads your speed in metres per second. The PSX slider
goes from 0 to 100, so the amount of PSX is the player's call and not mine.
The world grid exists as data: 25 chapters, 12 sections each, 300 sections in
total, gate schedules and all. Five of those chapters are a prequel, played as
Ilsa Renn twenty years before the first present-day chapter.

The game is playable now: **NEW RUN** in the menu loads a section, drops the
player at its start checkpoint, shows the objective, and moves on to the next
section the designer has written when the player reaches the end. The gates
open and close on the schedule, and the section clock runs in the corner. The
sections are made by hand, and the game loads exactly what was laid out.

The base of a section is drawn in **TrenchBroom**, the modern Hammer: a 2D
grid and a 3D view side by side, and a text `.map` file. The converter in
`tools/trenchbroom/` reads that file and writes the section the game runs.
The game folder carries 793 generic CC0 placeholder pictures so the material
can be picked out of a browser while the map is drawn. The game's own
textures, the menus and the GUI stay in Godot.

The canon is data too, and the tests hold it to itself. The cast, the
arsenal, the enemy roster and the player's numbers live in `data/`, and
`tests/test_canon.gd` checks them against each other and against the design
document. If the roster and the design doc disagree, the build fails. I
would rather it failed than have the two drift apart quietly, which is
exactly what they did twice before I wrote the test.

None of it is a finished game yet. The greybox is a measuring rig, one room
with a floor and a wall on every side to kiss. One section is built. There's
no art. The story layer is JSON that nothing in the engine reads yet.
`docs/dev_stage_1.md` §7 has the honest version of that list.

## The short version of the design

| | |
| --- | --- |
| Speed and precision | Momentum routes, frame tight execution, separate Time and Precision leaderboards |
| The pacing | Movement, combat, puzzles and stealth, all sharing the same route |
| The arsenal | Seven real weapons, and a route for everything that a bullet won't do |
| The antagonist | Human made, systemic, and right about the danger |
| Camera | Never leaves Lancer, Cutscenes happen in real time|
| Look | PSX era low poly 3D at 480×270, layered depth, nearest neighbour upscale |
| Fractures | 12 deliberate, stable, nameable bugs. Mastery content |
| Structure | 25 chapters × 12 sections in seven acts. The first act is a prequel |
| Lancer | Lancer Ivanov. No pronouns anywhere, and Lancer never speaks |
| Controls | The mouse is the camera and the triggers. The keyboard carries the rest |
| Speed | Measured in metres per second, on the HUD and in every document |
| Memory | 2.5 GB typical, 4 GB hard ceiling |
| Licence | Code GPL-2.0-or-later, content CC-BY-SA 4.0. Editions have to be open source |

## Running it

```bash
godot --path . --editor                            # the editor
godot --headless --editor --quit-after 20 --path . # import once
godot --headless --path . res://tests/run_all.tscn # the suite
```

The suite runs as a scene, not as a `--script` main loop. A script main loop
doesn't register the autoload singletons as global identifiers, so any test
that touches `WsGame` won't even compile. A test only proves anything about
the game if it runs the way the game runs.

If the editor came up empty the first time you opened it, that's the import
cache and it takes a minute to build. [Authoring by hand](docs/AUTHORING.md)
§1 explains it properly.

## Things I'd like help with

Fracture discoveries are the good ones. Name it, clip it, document it. A
Fracture that has shipped never gets removed, only added, because somebody out
there has a route recorded against it and the route has to keep working.

Editions too. Alternate storylines as data packages, open source, and they go
in the index.

Performance work, because the 4 GB ceiling is a requirement and not a goal.
Assist presets, subtitle scaling, remapping. Translation, since every string
already lives in `data/story/dialogue/`.

## Licence

Code is GPL-2.0-or-later, see [LICENSE](LICENSE). Forks and Editions built on
it stay open. Godot is MIT, so the combination is fine.

Content (levels, models, audio, art, the official story) is CC-BY-SA 4.0.
Reuse it anywhere, including commercial work. Derivatives have to be shared
alike.

Editions have to be open source and GPL/CC compatible to show up in the
official index. The manifest carries a licence field and the index checks it.

"WINDSHEAR" and "The Concord" aren't licensed. Use them all you like, just
don't imply your fork is the official one.
