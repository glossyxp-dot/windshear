# Contributing to WINDSHEAR

## License of contributions

- **Code** contributions land under **GPL-2.0-or-later** (see `LICENSE`).
  By opening a PR you agree your code is licensed that way. Don't submit code
  you don't have the right to license.
- **Asset** contributions (models, textures, audio, animation) land under
  **CC-BY-SA 4.0**.
- **Story/beat** contributions land under **CC-BY-SA 4.0** (same as the rest of
  the story layer).
- Third-party code must be GPL-2.0-compatible and be listed in `NOTICE` with
  its license and source.

## Community Editions

Editions (alternate storylines) are the flagship community activity.

- Editions that reuse the game **code** inherit the GPL and must be open source.
- Editions that reuse the **assets or the official story** inherit CC-BY-SA and
  must be shared alike.
- Editions published to the official index must declare a license and a source
  URL in `edition.json`. The index only lists open-licensed editions.
- Nothing stops you running anything locally — the game never blocks a local
  folder. The index just curates.

## Fractures

Fractures are a feature, not bugs. If you find one:

1. Name it, describe the exact inputs, and record a clip.
2. Submit it in the Fracture Codex issue tracker.
3. Accepted Fractures get documented in `data/fractures.json` and in-game.

**Shipped Fractures are never removed or altered** — only added. Changing one
breaks community speedrun routes, which is a bigger sin than leaving a quirky
behaviour in place.

## Performance rules (hard requirements)

- Peak RAM ≤ 2.5 GB, hard ceiling 4 GB.
- Per-cell budgets: ≤ 45 MB textures, ≤ 20 MB meshes, ≤ 12 MB audio.
- ≤ 220 draw calls, ≤ 35k visible triangles.
- No allocation in `_process` / `_physics_process`.
- CI fails the build if a cell exceeds its budget.

The RAM ceiling is a design requirement, not an optimisation goal — the game
has to run on 4 GB machines without swap, and it has to run on them while
holding the whole city in memory.

## Before you open a PR

- [ ] Reads `GAME_DESIGN.md` — the design is the spec, not a suggestion.
- [ ] New mechanics fit the existing verb list (run / slide / jump / wall-kiss /
      filament / wind). If it adds a fifth core verb, that's a design
      conversation first.
- [ ] Cutscenes never take the camera off Lancer, and major beats freeze the
      player and the world.
- [ ] 60 Hz physics determinism preserved — no `randf()` in gameplay logic;
      use the section-seeded RNG.
- [ ] Tests pass: `godot --headless --path . res://tests/run_all.tscn`
- [ ] Memory budget check passes.
- [ ] No Lancer gender is specified anywhere in your content (no pronouns in
      dialogue, no gendered voice direction, no gendered framing).
