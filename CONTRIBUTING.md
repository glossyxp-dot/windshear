# Contributing

WindShear is GPL code and CC-BY-SA content, and it's going to stay that way. If
that's a problem, this isn't the project for you, and that's fine.

## What your contribution is licensed as

Code goes out under **GPL-2.0-or-later**. See `LICENSE`. Opening a PR means
you're licensing it that way, so don't send code you don't have the right to
relicense.

Assets (models, textures, audio, animation) go out under **CC-BY-SA 4.0**.
Story and beats go out under **CC-BY-SA 4.0** as well, same layer, same terms.

Third-party code has to be GPL-2.0-compatible, and it goes in `NOTICE` with its
licence and where you got it.

No CLA and no copyright assignment. You keep your copyright. The licence does
the work.

## Editions

Editions are the reason for the open licence. Same city, same movement,
somebody else's story. They're the community activity I actually want to see.

An Edition that reuses the **code** inherits the GPL and has to be open source.
One that reuses the **art or the official story** inherits CC-BY-SA and has to
be shared alike.

Editions on the official index declare a licence and a `source_url` in
`edition.json`. The index checks both and lists nothing else. A local Edition
always loads, because there's no activation step to get around. The index
curates, it doesn't gate.

The format is written up in `editions/README.md`. It's a folder of JSON and a
manifest, and you can build one in an afternoon.

## Fractures

Fractures are a feature. The game ships twelve of them on purpose, they're
documented, and speedrunners are expected to build routes on top of them.

If you find a new one, name it, give the exact inputs (frame numbers if you
have them) and attach a clip. Open it in the Fracture Codex issue tracker. If
it's accepted it goes into `data/fractures.json` and into the game.

**A shipped Fracture is never removed or altered. Only added.** Somebody has a
route recorded against version 1 of it and that route has to keep working.
Leaving a weird bit of physics in the game is a much smaller sin than breaking
everybody's splits.

## The performance rules are hard

This isn't "we'd like it to be fast". The game has to run on a 4 GB machine
with no swap, holding the whole city in memory.

- Peak RAM ≤ 2.5 GB, ceiling 4 GB.
- Per cell: ≤ 45 MB textures, ≤ 20 MB meshes, ≤ 12 MB audio.
- ≤ 220 draw calls, ≤ 35k visible triangles.
- No allocation in `_process` or `_physics_process`.
- CI fails the build if a cell goes over.

The per-cell numbers are checked by `tools/cell_budget_checker.gd` and the
frame-loop rules by the code-policy suite. Both run in CI, so you'll find out
before I do.

## Before you open a PR

- [ ] You've read `GAME_DESIGN.md`. It's the spec, not a mood board.
- [ ] New mechanics fit the existing verbs: run, slide, jump, wall-kiss,
      filament, wind. A new core verb is a design conversation before it's a PR.
- [ ] The camera never leaves Lancer. Major beats freeze the player and the
      world, and the framing stays composed because the camera is hers.
- [ ] 60 Hz determinism holds. No `randf()` in gameplay logic; use the
      section-seeded generator so ghosts and replays match.
- [ ] `godot --headless --path . res://tests/run_all.tscn` passes.
- [ ] The memory budget check passes.
- [ ] Lancer's gender is still unspecified, and Lancer still never speaks.
      Saye and Ilsa have pronouns; Lancer has none. No pronouns in Lancer's
      dialogue, no gendered voice direction, no gendered framing. This one
      isn't negotiable and it's easy to break by accident.

## How a PR actually lands

Small PRs land fast. One thing per PR, a sentence about why, tests green. If a
PR touches movement numbers in `ws_tuning.gd`, it also touches `TECH_SPEC.md`
§3, because `test_tuning.gd` reads the Markdown and compares. Change one
without the other and the build fails on purpose.

Not sure whether something is wanted? Open an issue first. I'd rather talk it
through for ten minutes than review a week of work that went the wrong way.
