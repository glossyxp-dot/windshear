# Start here

The design is locked (`GAME_DESIGN.md`, `TECH_SPEC.md`). This is the shortest
path from "I cloned the repo" to "I'm running around the movement room and I
know what to do next".

---

## 1. Get it running

You need **Godot 4.7.2**, the same build CI uses. Not 4.6, not 4.8.

```bash
git clone https://github.com/glossyxp-dot/windshear.git
cd windshear

# import once — builds .godot/ and the class cache
godot --headless --editor --quit-after 20 --path .

# the test suite
godot --headless --path . res://tests/run_all.tscn

# the game
godot --path .
```

If you'd rather not use the command line, open the Godot project manager,
click *Import*, and point it at `project.godot`. Same result.

The editor will look empty for a minute on the first import. That's normal —
`.godot/` isn't in the repo and Godot has to build it. `docs/AUTHORING.md` §1
explains it properly.

## 2. What's already done

Don't rebuild these:

| | |
| --- | --- |
| Project settings | 480×270 internal, 960×540 window, `canvas_items` + `keep`, nearest filter, Jolt, 60 Hz |
| Movement | Run, slide, jump, wall-kiss. Frame-exact, locked to `TECH_SPEC.md` §3 |
| Camera | Mouse-look rig parented to Lancer. It never leaves |
| PSX | Shader plus a 0–100% slider. The player picks the amount |
| Menu | Main menu, settings panel, PSX slider, affine toggle |
| Greybox | One test room with a floor, platforms, a ramp, a wall to kiss and a help panel |
| Tests | 322 checks, 11 suites, headless, ~10 seconds |
| World data | 20 chapters × 12 sections, 540 gate schedules, 12 Fractures, 11 beats, 43 dialogue lines |
| CI | Pinned Godot, SHA-256 checked, import → tests → budget |

## 3. What's yours

The visual work is by hand. The code is done for this stage.

1. **Play the greybox.** Open `world/greybox/movement_greybox.tscn`, press F6,
   and press F1 for the mechanics reference. If the movement doesn't feel good
   yet, that's the only thing that matters this week.
2. **Decide the `wall_kiss_chain` Fracture.** It duplicates the core wall-kiss
   verb exactly. Redefine it, remove it, or change the core verb — but the
   third ending's condition needs twelve Fractures, so "remove" means a design
   change too. `docs/MOVEMENT_RESEARCH.md` §16.3 has the details.
3. **Install the export templates** for 4.7.2. You need them before any export.
4. **Build Level 2.** The greybox is a rig, not a level. `2.01` is the first
   section that has to be fun.
5. **Implement the filament.** It's the last of the five verbs and the first
   one that touches something other than the ground.
6. **Do the art**, by hand, in the editor. `docs/AUTHORING.md` covers the
   materials, the theme, the fonts and the resolution.
7. **Get five external testers** on the movement. That's Milestone 0's gate and
   it's the only thing between you and Milestone 1.

## 4. The numbers you'll be held to

| Feature | Value |
| --- | --- |
| Max run speed | 14.0 m/s |
| Ground accel / decel | 90 / 60 m/s² |
| Air accel | 32 m/s², capped contribution 2.2 m/s |
| Gravity | 60 m/s² (jump apex ≈ 2.0 m) |
| Jump velocity | 15.5 m/s, variable height, 8-frame coyote, 10-frame buffer |
| Slide | 0.45 s, friction 6, cancels into a jump |
| Wall-kiss | 2-frame window, +0.8 m/s, chain of 5, hard ceiling 18.0 m/s |
| Filament lock-on | 0.25 s, 18° half-angle |
| Tick | 60 Hz fixed, `max_physics_steps_per_frame` 4 |
| Plane | Gameplay on XY, `velocity.z = 0`, walls on the plane |

These are asserted by `tests/test_tuning.gd` against `TECH_SPEC.md` §3. Change
one without changing the other and the build fails. That's the deal.

Also: no `randf()` in gameplay code. Section randomness comes from a seeded
`RandomNumberGenerator` per section, so ghosts and replays match.

## 5. The milestones

Locked in `GAME_DESIGN.md` §14. Don't re-open them while Milestone 0 runs.

| Milestone | Length | Gate |
| --- | --- | --- |
| 0 — Movement prototype | 2 weeks | 5 external testers say it's satisfying, unprompted |
| 1 — Vertical slice | 8 weeks | a 5-minute run is a toy people replay |
| 2 — Systems & content | 12 weeks | an external team ships an alternate storyline |
| 3 — Polish & ship | 8 weeks | public release, community forks > 0 |
| 4 — Community era | ongoing | edition index, community maps, seasonal Fractures |

## 6. Don't do these yet

- No combat. Movement first; there are no guns in Milestone 1.
- No new Fractures beyond what Milestone 1 needs. And never *remove* one that
  shipped.
- No accounts, no DRM, no mandatory network. That's the licence and the point.
- No engine or plugin that breaks the 4 GB ceiling or the Compatibility
  renderer.

## 7. Where to read next

| Document | What it locks |
| --- | --- |
| `GAME_DESIGN.md` | Pillars, the Concord, movement, Fractures, the 20-chapter structure, roadmap |
| `TECH_SPEC.md` | Renderer, budgets, controller numbers, formats, CI, licensing |
| `docs/CONCORD.md` | The antagonist in full: threat model, escalation, the people |
| `docs/AUTHORING.md` | Doing the visual work by hand in the editor |
| `docs/MOVEMENT_RESEARCH.md` | Cited movement sources, evidence confidence, design synthesis |
| `docs/dev_stage_1.md` | What the movement base is, and the bug the discovery harness found |
| `docs/architecture.md` | How the codebase fits together |
| `docs/testing.md` | The suite, and how to add to it |
| `CONTRIBUTING.md` | How to land a PR, and what your contribution is licensed as |
