# Start here

The design is settled (`GAME_DESIGN.md`, `TECH_SPEC.md`). This is the shortest
path from "I've cloned the repo" to "I'm running round the movement room and I
know what to do next".

## Get it running

You want **Godot 4.7.2**, the same build CI uses. Not 4.6, not 4.8.

```bash
git clone https://github.com/glossyxp-dot/windshear.git
cd windshear

# import once, so .godot/ and the class cache exist
godot --headless --editor --quit-after 20 --path .

# the test suite
godot --headless --path . res://tests/run_all.tscn

# the game
godot --path .
```

Prefer not to use a terminal? Open the Godot project manager, click *Import*,
point it at `project.godot`. Same result.

The editor will look empty for a minute on the first import. That's normal.
`.godot/` isn't in the repo and Godot has to build it. `docs/AUTHORING.md` §1
explains it properly.

## What's already done

Don't rebuild any of this:

| | |
| --- | --- |
| Project settings | 480×270 internal, 960×540 window, `canvas_items` and `keep`, nearest filter, Jolt, 60 Hz |
| Movement | Walk, slide, jump, wall-jump. Camera-relative, frame exact, locked to `TECH_SPEC.md` §3 |
| Camera | Mouse-look orbit rig parented to Lancer. It never leaves |
| PSX | The shader plus a 0–100% slider. The player picks the amount |
| Menu | Main menu, settings panel, PSX slider, affine toggle |
| Greybox | One test room: floor, platforms, a ramp, a wall on every side to kiss, a help panel |
| Tests | 653 checks in 18 suites, headless, about ten seconds |
| World data | 25 chapters × 12 sections, 600 gate schedules, 12 Fractures, 19 beats, 73 dialogue lines |
| Canon data | 10 cast entries, 7 weapons, 5 items, 5 map utilities, 11 enemies |
| Controls | The mouse is the camera and the triggers. The keyboard carries the rest |
| Speed | Measured in metres per second, shown on the HUD as current and peak |
| CI | Pinned Godot, SHA-256 checked, import then tests then budget |

## What's yours

The visual work is by hand. The code for this stage is done.

1. **Play the greybox.** Open `world/greybox/movement_greybox.tscn`, press F6,
   press F1 for the mechanics reference. The HUD in the corner reads your speed
   in m/s, current and peak. If the movement doesn't feel good yet, that's
   the only thing that matters this week. `W` and `S` walk forward and back,
   `A` and `D` strafe, `Ctrl` slides, `Space` jumps, and the mouse does the
   camera and the two triggers.
2. **Tune the movement in the workbench.** Open `tools/movement_workbench.tscn`
   and press F6. Every movement number is a slider, and the room changes as
   you drag it. `docs/BUILDING.md` explains the loop and how a tuned number
   becomes canon.
3. **Install the export templates** for 4.7.2. You can't export without them.
4. **Build Level 2.** The greybox is a rig. `2.01` is the first section that
   has to be fun.
5. **Implement the filament.** Last of the core movement verbs, and the first
   one that touches something other than the ground.
6. **Do the art**, by hand, in the editor. `docs/AUTHORING.md` covers the
   materials, the theme, the fonts and the resolution.
7. **Get five external testers** on the movement. That's Milestone 0's gate
   and it's the only thing between you and Milestone 1.

One design question is still open and it's worth knowing about before you
build a route around it. The `wall_kiss_chain` Fracture used to be a duplicate
of the core wall-jump verb, which was silly. It's not any more: the base
chain is three wall-jumps and the Fracture takes it to five, which is where
the old 18.0 m/s ceiling went. `docs/MOVEMENT_RESEARCH.md` §16.3 has the
argument, and the third ending still needs all twelve Fractures.

## The numbers you'll be held to

| Feature | Value |
| --- | --- |
| Max run speed | 14.0 m/s |
| Ground accel / decel | 90 / 60 m/s² |
| Air accel | 32 m/s², capped contribution 2.2 m/s |
| Gravity | 60 m/s² (jump apex ≈ 2.0 m) |
| Jump velocity | 15.5 m/s, variable height, 8-frame coyote, 10-frame buffer |
| Slide | 0.45 s, friction 6, cancels into a jump |
| Wall-jump | 2-frame window, +0.8 m/s, chain of 3, hard ceiling 16.4 m/s |
| Wall-jump, with the Fracture | chain of 5, ceiling 18.0 m/s |
| Filament lock-on | 0.25 s, 18° half-angle |
| Health | 100 HP base. Lancer overheals to 150 and decays back down; Ilsa is capped at 100 |
| Ram shatter | 100 m/s, head-on. The Concord has no defence for it |
| Thermal cloak | Breaks above 8 m/s, and on any sprint, slide or shot |
| Tick | 60 Hz fixed, `max_physics_steps_per_frame` 4 |
| Ground plane | Gameplay on X/Z, Y for height. Movement is camera-relative; `W`/`S` walk, `A`/`D` strafe |

`tests/test_tuning.gd` asserts all of that against `TECH_SPEC.md` §3. Change
one without the other and the build fails. That's the deal.

Also: no `randf()` in gameplay logic. Section randomness comes from a seeded
`RandomNumberGenerator` per section, so ghosts and replays match. I know
it's a small rule to write down. It's also the rule that decides whether a
leaderboard means anything, so it stays written down.

## The milestones

Locked in `GAME_DESIGN.md` §14. Don't re-open them while Milestone 0 runs.

| Milestone | Length | Gate |
| --- | --- | --- |
| 0 — Movement prototype | 2 weeks | 5 external testers say it's satisfying, unprompted |
| 1 — Vertical slice | 8 weeks | a 5-minute run is a toy people replay |
| 2 — Systems & content | 12 weeks | an external team ships an alternate storyline |
| 3 — Polish & ship | 8 weeks | public release, community forks > 0 |
| 4 — Community era | ongoing | edition index, community maps, seasonal Fractures |

## Don't do these yet

No combat in Milestone 1. Movement first. The arsenal is written down and
locked as canon in `data/arsenal.json` and `docs/ARSENAL.md`, and the guns
land in Milestone 2.

No new Fractures beyond what Milestone 1 needs, and never remove one that has
shipped.

No accounts, no DRM, no mandatory network. That's the licence and the point.

Nothing that breaks the 4 GB ceiling or the Compatibility renderer.

## Where to read next

| Document | What it locks |
| --- | --- |
| `GAME_DESIGN.md` | Pillars, the Concord, movement, Fractures, the 25-chapter structure, roadmap |
| `TECH_SPEC.md` | Renderer, budgets, controller numbers, formats, CI, licensing |
| `docs/CONCORD.md` | The antagonist in full: threat model, escalation, the people |
| `docs/ARSENAL.md` | The weapons, the items and the map utilities |
| `docs/ENEMIES.md` | The Concord roster, with counters and drops |
| `docs/CONTROLS.md` | The default bindings, and what the mouse is for |
| `docs/BUILDING.md` | How the work is split, and the movement workbench |
| `docs/AUTHORING.md` | Doing the visual work by hand in the editor |
| `docs/MOVEMENT_RESEARCH.md` | Cited movement sources, evidence confidence, design synthesis |
| `docs/dev_stage_1.md` | What the movement base is, and the bug the discovery harness found |
| `docs/architecture.md` | How the codebase fits together |
| `docs/testing.md` | The suite, and how to add to it |
| `CONTRIBUTING.md` | How to land a PR, and what your contribution is licensed as |
