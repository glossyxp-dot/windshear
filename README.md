# WINDSHEAR

A 2.5D speed-and-precision platformer about a courier who carries parcels
between city blocks that aren't supposed to know about each other.

The wind is regulated. A civic operating system called **The Concord** decides
where it goes and when the gates open, because twenty years ago the sky came
apart and killed a lot of people. You are **Lancer**, and the Concord would
very much like you to stop.

Free and open source, all of it — code, levels, art, the official story. If you
want to tell a different story in the same city, ship it as an Edition. Nobody
has to ask me first.

- [Game design](GAME_DESIGN.md)
- [Technical spec](TECH_SPEC.md)
- [The Concord](docs/CONCORD.md) — the antagonist, in full
- [Movement research](docs/MOVEMENT_RESEARCH.md) — cited sources and the design synthesis
- [Dev Stage 1](docs/dev_stage_1.md) — the movement base, and the bug it found
- [Architecture](docs/architecture.md) · [Testing](docs/testing.md)
- [Authoring by hand](docs/AUTHORING.md) — how to open the project and decorate it in the editor
- [Contributing](CONTRIBUTING.md)
- [Start here](START_HERE.md)

---

## Where it is right now

Dev Stage 1. The project boots, the menu works, and Lancer moves.

322 headless checks, all passing. Movement is frame-exact at 60 Hz. The PSX
amount is a slider that goes all the way to zero. The world grid — twenty
chapters of twelve sections — exists as validated data, gate schedules and all.

What isn't there is anything you'd call a level. The greybox is a test rig, not
a game. There's no art. The story layer has beats and dialogue, but nothing in
the engine consumes them yet. `docs/dev_stage_1.md` §7 is blunt about the rest.

## The design in a table

| | |
| --- | --- |
| Speed × precision | Momentum routes, frame-tight execution, two leaderboards (Time and Precision) |
| The antagonist | Human-made, systemic, and right about the danger. That's the point |
| Camera | Never leaves Lancer. Cutscenes happen in the world, not in a film |
| Look | PSX low-poly 3D at 480×270, layered parallax, nearest-neighbour upscale |
| Fractures | 12 deliberate, stable, nameable bugs. Mastery content, not accidents |
| Structure | 20 chapters × 12 sections, six acts, connected like HL2 but linear |
| Lancer | No specified gender, anywhere |
| Memory | 2.5 GB typical, 4 GB hard ceiling |
| Licence | Code GPL-2.0-or-later · content CC-BY-SA 4.0 · Editions must be open source |

## Running it

```bash
# open the editor
godot --path . --editor

# import once, so .godot/ and the class cache exist
godot --headless --editor --quit-after 20 --path .

# the headless suite
godot --headless --path . res://tests/run_all.tscn
```

The runner is a scene, not a `--script` main loop. A script main loop doesn't
register the autoload singletons as global identifiers, so anything that
touches `WsGame` won't even compile. Running the game the way the game runs is
the only way a test proves anything about it.

If you've never opened this repo before, read [Authoring by hand](docs/AUTHORING.md)
first. The editor looks empty on a fresh clone and there's a reason for that.

## Contributing

Read `GAME_DESIGN.md` before you write code. The design is the spec, and the
tests enforce the numbers in `TECH_SPEC.md` §3.

Things that are genuinely wanted:

- **Fracture discoveries.** Name it, clip it, document it. A shipped Fracture is
  never removed, only added.
- **Editions.** Alternate storylines as data packages. Open source to get listed.
- **Performance.** The RAM ceiling is hard. Per-cell budgets run in CI.
- **Accessibility.** Assist presets, subtitle scaling, remapping.
- **Translation.** Every string lives in `data/story/dialogue/`.

## Licence

- **Code:** GPL-2.0-or-later. See [`LICENSE`](LICENSE). Forks and Editions built
  on this code stay open under the same terms. Godot is MIT, so the combination
  is fine.
- **Content** (levels, models, audio, art, official story): CC-BY-SA 4.0. Reuse
  it in anything, including commercial work. Derivatives get shared alike.
- **Editions** have to be open source and GPL/CC-compatible to appear on the
  official index. The manifest carries a licence field and the index checks it.

"WINDSHEAR" and "The Concord" aren't licensed. Nominate them all you like, just
don't imply your fork is official.
