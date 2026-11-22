# WINDSHEAR

A cinematic 2.5D **speed-and-precision** platformer set in a city whose wind is
regulated by a civic operating system called **The Concord**. You play
**Lancer**, a courier who breaks the law to set the sky free.

**Free and open source.** The whole game — code, world, official story — is
open. The community can build alternate storylines as *Editions*, not mods of
an SDK.

- 📘 [Game Design Document](GAME_DESIGN.md)
- 🛠 [Technical Specification](TECH_SPEC.md)
- 🏃 [Movement Reference](docs/movement_reference.md) — where the movement comes from
- 📓 [Dev Stage 1](docs/dev_stage_1.md) — the movement base, and the bug it found
- 🧱 [Architecture](docs/architecture.md) · [Testing](docs/testing.md)
- 🤝 [Contributing](CONTRIBUTING.md)
- 🚀 [Start Here](START_HERE.md) — how to begin implementation

---

## Status

**Dev Stage 1 — the movement base.** The project boots, the menu works, and
Lancer moves. 192 headless checks pass, the movement is frame-exact, and the
PSX amount is the player's to pick. No levels, no art, no story in the engine
yet — see [Dev Stage 1](docs/dev_stage_1.md) §7 for what is missing and why.

## Pillars at a glance

| Pillar | Commitment |
| --- | --- |
| Speed × precision | Momentum routes, frame-tight execution, two leaderboard ladders (Time / Precision) |
| The antagonist | Human-made, systemic, and *right* about the danger — that's the point |
| Camera | Never leaves Lancer. Cutscenes happen in the world, not in a film |
| Depth | PSX low-poly 3D rendered at 480×270, staged as layered parallax |
| Fractures | 12 deliberate, stable, nameable bugs for mastery players |
| Structure | 6 chapters × 12 sections, connected like HL2 but linear |
| Lancer | No specified gender, anywhere |
| Memory | Peak RAM ≤ 2.5 GB, hard ceiling 4 GB |
| License | Code GPL-2.0-or-later · Content CC-BY-SA 4.0 · Editions must be open source |

## Running it

```bash
# Editor
godot --path . --editor

# Import the project once (builds .godot/ and the global class cache)
godot --headless --editor --quit-after 20 --path .

# Headless test suite
godot --headless --path . res://tests/run_all.tscn
```

The test runner is a **scene**, not a `--script` main loop: a script main
loop does not register the autoload singletons as global identifiers, so
`WsGame` fail to compile there.

## Contributing

Read `GAME_DESIGN.md` first — the design is the spec. Notable contribution
surfaces:

- **Fracture discoveries** — name it, document it, submit it. Shipped Fractures
  are never removed, only added.
- **Editions** — alternate storylines as data-only packages; must be open
  source to be listed on the official index.
- **Performance** — the RAM ceiling is a hard requirement; per-cell budgets are
  enforced in CI.
- **Accessibility** — assist presets, subtitle scaling, input remapping.
- **Translation** — all strings live in `data/story/dialogue/`.

## License

- **Game code:** **GPL-2.0-or-later** (full text in [`LICENSE`](LICENSE)).
  Any version, fork, or Edition built on this code must also be open source
  under the same terms. Godot itself is MIT, so the combination is fine.
- **Game content** (levels, models, audio, art, official story): **CC-BY-SA 4.0**.
  Free to reuse in other games, including commercial ones — derivatives of those
  assets just have to be shared alike.
- **Community Editions** must be open source and GPL/CC-compatible to be
  published through the official index. The engine ships a license field that
  the index checks.

"WINDSHEAR" and "The Concord" are not licensed; nominative use by forks is
fine, but a fork must not imply official status.
