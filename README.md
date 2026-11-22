# WINDSHEAR

A 2.5D speed-and-precision platformer. You play Lancer, a courier in a city
where the wind is regulated by software, and the regulation is the problem.

The Concord decides where the air goes and when a gate unlocks. It exists
because twenty years ago the sky came apart and killed a lot of people, so the
survivors built it. You carry parcels for a living. The parcels you carry now
are not the ones it approved.

Everything is open source, code and content both. If you want to tell a
different story in the same city, that's what an Edition is: a folder of JSON,
no code required. Nobody has to ask me first, and nobody has to ask you to
change the game you already downloaded.

## The documents

- [Game design](GAME_DESIGN.md) — pillars, the cast, the 20-chapter structure
- [Technical spec](TECH_SPEC.md) — renderer, budgets, every movement number
- [The Concord](docs/CONCORD.md) — what the antagonist actually is, in full
- [Movement research](docs/MOVEMENT_RESEARCH.md) — the sources behind the movement numbers
- [Dev Stage 1](docs/dev_stage_1.md) — how far the movement base got, and the bug the discovery harness found
- [Authoring by hand](docs/AUTHORING.md) — opening the project and decorating it without touching code
- [Architecture](docs/architecture.md) and [testing](docs/testing.md)
- [Contributing](CONTRIBUTING.md)
- [Start here](START_HERE.md)

## Where it's up to

Dev Stage 1. The project boots, the menu works, Lancer moves.

There are 322 headless checks and they all pass. The movement is frame exact
at 60 Hz. The PSX slider goes from 0 to 100, so the amount of PSX is the
player's call and not mine. The world grid exists as data: 20 chapters, 12
sections each, 240 sections in total, gate schedules and all.

None of it is a game yet. The greybox is a measuring rig, one room with a floor
and a wall to kiss. There's no art. The story layer is JSON that nothing in the
engine reads yet. `docs/dev_stage_1.md` §7 has the honest version of that list.

## The short version of the design

| | |
| --- | --- |
| Speed and precision | Momentum routes, frame tight execution, separate Time and Precision leaderboards |
| The antagonist | Human made, systemic, and right about the danger |
| Camera | Never leaves Lancer. Cutscenes happen in the world |
| Look | PSX era low poly 3D at 480×270, parallax, nearest neighbour upscale |
| Fractures | 12 deliberate, stable, nameable bugs. Mastery content |
| Structure | 20 chapters × 12 sections in six acts. Linear, but connected like HL2 |
| Lancer | No gender specified anywhere, and I'd like to keep it that way |
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
that touches `WsGame` won't even compile. Running the game the way the game
runs is the only way a test proves anything about it.

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
