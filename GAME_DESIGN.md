# WINDSHEAR: dev directions

> A goldsrc 2.5D speed-and-precision platformer. Free and open source, built so
> the community can tell its own stories inside the same world.

**One-line pitch:** *Twenty years ago, Longhorn Science made a hypersmart organism that took over the world
Today, Lancer Ivanov is
going to punch through the sky-canopy and set the world free.*

---

## 0. Design pillars

1. **Velocity is only part of it.** The pacing splits between movement,
   combat, puzzles and stealth. A section usually asks for one of them, and
   punishes you for solving it with the others. Speed is the sharpest tool in
   the box, not the whole box.
2. **The world is a machine, not a monster.** The antagonist is human-made. It's
   a war organism called **The Concord**, and it caged the world to prevent
   catastrophe. That argument *is* the main point of the game.
3. **Lancer is the main character, and Lancer never speaks.** Everything
   Lancer says is a line they run. The player frees the world from
   containment, not from an invasion.
4. **Cinematic 2.5D, with camera discipline.** The camera never leaves Lancer.
   Cutscenes happen in the world, not in a separate film.
5. **Shallow depth, deep world.** PSX-era low-poly 3D at 480×270, staged like a
   diorama: parallax, fog, layered light, big silhouettes.
6. **Fractures are real.** The Concord is old and patched, and some of the
   cracks ship on purpose, so a hyper-competent player can go and find one,
   name it and use it.
7. **Free, open, forkable.** Code, assets and level format are all open, and an
   alternative storyline counts as content rather than as a mod of an SDK.

---

## 1. The world: the Concord

Not aliens, not nature. A machine that a human high command deployed, twenty
years ago, to stop a war that was very nearly the end of everything.

### The Fracture Year

A modern global war escalated toward total human extinction. High command
dropped an autonomous biomechanical siege organism out of the **Longhorn
Biological Facility** and called it **The Concord**. It took the cities in
weeks. War casualties hit zero, and the price was the sky.

The Concord occupies every surface city directly now and holds the upper
atmosphere beneath a sun-choking canopy. Under that canopy humanity survives
in **Quarantine Blocks**: sealed districts on the surface, rations delivered,
streets patrolled, the central Spire looming over the fog. People live
there. They are fed, kept safe, and not asked what they think about it.

### The Concord Monolith

The Concord was housed in the Longhorn Biological Facility, and it swallowed
the place. What is left standing over the ruins is the **Concord Monolith**: a
massive, featureless biomechanical cube. Inside, the corridors are eerily
familiar — same tile floors, same lab signage, Longhorn's own wayfinding —
only stretched to cathedral proportions, with vertical shafts that go up
further than the building ever did and dozens of extra pathways that no
engineer drew. The Concord didn't design it. It grew it, and it kept the
signage, because signage was cheap and a building full of labels still looks
like a building.

Act IV is the inside of that cube, and it's the place the game's history is
kept: Dr. Aris Thorne is still alive in the observation bunker, twenty years
after he handed a dispatch runner a master override key on the worst day of
the war.

### What it enforces

Crossing sector walls, climbing toward the canopy, or carrying unapproved
hardware or data between blocks is forbidden. All three, because all three
are how a second war would start.

It enforces those rules the only way it can, by denying ground. **Quarantine
Bulkheads** slam shut across a street. **Purge and Sterilization Protocols**
flood a sector with hazards. **Interdiction Nodes** sit over the bridges and
the shafts and hold their arc.

### The blind spot

Every one of those defences was built against a slow infiltrator or a
demolition team. Chokepoints, blast doors, sensor grids, bio-constructs on
patrol lines. None of it was designed for somebody who crosses at fourteen
metres a second because the route gives them no other choice.

Wind isn't illegal either. Nobody thought to make it illegal. It's just the
one thing in the city that moves faster than a door can close.

The Concord's sensors read speed in the same unit the rest of the game does.
Fourteen metres a second is a sprint and gets logged as one. Sixteen point
four, reached through a wall-jump chain, is a route it has to answer. A
hundred, head-on, is the only number that opens a Concord Ram.

### Why it hunts Lancer

Lancer Ivanov is a courier. Licensed to run approved manifests inside one
block, paid to carry what the schedule lists. Lancer carries what the schedule
doesn't: messages, radio transceivers, memory drives, whatever one block needs
to hear from another.

To a siege organism built to stop factions coordinating, a courier
reconnecting isolated populations looks exactly like a command network
forming. That's the shape of threat it was built to stop, and that's the
shape Lancer keeps accidentally being.

### The growth

Where concrete tore in the fighting, the Concord grew living scar tissue:
**Grown Seams** that run warm, deform underfoot and bleed when scraped. Where
industrial vents froze, it grew organic collars. It has no face and no ego,
and it talks through PA chimes, klaxons and schedule boards.

The seams aren't alive in any way a person would recognise. They close gaps
because closing gaps is what they were told to do.

### The dilemma

Freeing the sky means the war can start again. The Concord isn't evil and it
isn't stupid. It did what it was told, and it has kept doing it for twenty
years, and nobody has ever asked it whether the cage is worth the sky.

The game never answers that. It asks who gets to decide, and it shows that
both sides have killed people.

### Cast

The full roster, with pronouns and acts, lives in `data/cast.json`. The
canon test checks that every speaker in the dialogue file is on that list and
that only Lancer is silent and pronounless.

- **Lancer Ivanov** (no pronouns). A surface courier in their twenties or
  thirties. Lancer never speaks. Everything Lancer communicates is a line
  they run, a parcel they hand over, or a parcel they don't. No pronouns in
  dialogue, no gendered voice direction, no gendered framing, anywhere in any
  locale.
- **Ilsa Renn** (she/her). The prequel protagonist, Lancer's mentor, and the
  Concord's FIRST RUNNER. A veteran smuggler who trained Lancer, and a
  military dispatch runner during the Fracture Year who survived the Concord's
  drop and carved the first illegal routes across the walls. She is silent in
  the prequel, like Lancer. In the present day she talks, and what she says is
  usually a route.
- **Warden Saye** (she/her). Human containment enforcement. In the prequel
  she's a young logistics officer watching the war spiral; twenty years later
  she's the exhausted administrator who signed the isolation accords and
  believes the walled blocks are the only way humanity survives. She talks at
  Lancer across checkpoints and security glass, and never gets an answer back.
- **THE CONCORD.** The siege organism itself. It speaks in containment logs
  and schedule bulletins. It is never a face.
- **FIRST RUNNER.** The designation the Concord gives Ilsa's recorded movement
  profile. It has been running her route as a patrol training model for twenty
  years, against every courier it can see.
- **Dr. Aris Thorne** (he/him). Lead biomechanical containment researcher at
  the Longhorn Biological Facility. In the Fracture Year he gives Ilsa the
  facility's master override key during the drop. Twenty years later Lancer
  finds his audio logs, and a frail, surviving Thorne inside the expanded
  Concord Monolith.
- **Sergeant Miller** (he/him). An exhausted infantry squad leader holding the
  perimeter around Central Station and the Longhorn Facility while Ilsa runs
  encryption keys through active warzones. Prequel only, chapters P1 to P3.
- **Henrik Solberg** (he/him). An underground block machinist in Quarantine
  Block 404 and a former Wind Regulator technician. He maintains Lancer's
  Filament tether, repairs salvaged rifles, and assembles the L-01 Arc-Lance
  out of regulator parts.
- **Talia Korr** (she/her). A signal operator for the Free-Band Network. She
  links shortwave transmitters across the Block Seam and feeds Lancer tactical
  intel over a one-way earpiece while Lancer stays silent.
- **CIVIL DEFENSE.** The civil-defence broadcasts of the Fracture Year. A
  channel with a voice on it and nobody behind it, and the last thing anybody
  hears before the Concord takes the sky.

### Endings (3)

**OPEN WEATHER.** Lancer shatters the canopy regulator core. The iris tears
open, flooding the walled cities below with direct sunlight and wild storms.
Humanity is free to reconnect, and free to fight again.

**UNDER REGULATION.** Lancer leaves the canopy core intact, accepting Saye's
bargain, and walks back down into the overcast, walled-in city to run safe,
scheduled laps forever.

**THE SECOND FRACTURE.** Hidden, and it needs the Fracture routes. Lancer
doesn't choose; they make the world *uncontainable* by exploiting every
Fracture at once, short-circuiting the area-denial grid so the Concord can
never seal a sector wall or close the sky again. The war-organism lives on
as a hollowed-out monument beneath an open sky. All 12 Fractures required.

---

## 2. Movement model (the core)

**Plane:** gameplay on X/Y. Z is for parallax staging, rails and background
layers. Speed reads off the X axis, precision off Y.

### Verbs

| Verb | Input | Feel |
| --- | --- | --- |
| Move | W, A, S,D| Top speed ~14 m/s; quick, snappy accel; momentum *not* preserved on turnaround |
| Slide | `Ctrl` while running | Lowers profile, preserves speed, cancellable; friction ramp |
| Jump / double jump | `Space` | Variable height, 8-frame coyote time, 10-frame input buffer |
| Wall contact | into a wall | Slide along, preserves speed; **wall-jump chain**, three jumps long |
| Ledge grab | `Q` at a ledge | 0.15 s snap, generous corner correction |
| Air control | `A` `D` in air | Strong but not total; air-strafe mini-accel (precision tech) |
| Filament (tether) | `F` | 3 anchor types, 0.25 s lock-on, *not* a grapple hook |

The mouse does the camera and the two triggers, so the keyboard carries
everything else. `W` and `S` tilt the camera rather than move Lancer, because
the gameplay plane has no forward axis. The full scheme is in
`docs/CONTROLS.md`.

### Possible Techniques (why this is learnable, not soup)

Every boost comes from a specific, nameable input sequence. The speedrun scene
calls these **moves**:

- **Slide-hop.** Jump at the end of a slide. The bread-and-butter combo.
- **Wall-jump.** Hit a wall while sliding and jump on the same frame as
  contact. +0.8 m/s per jump, and a chain of three in the base game. The
  `wall_kiss_chain` Fracture takes the chain to five.
- **Zip.** Filament to a *zip anchor* (a taut cable along the route): instant
  launch along the anchor line, and your speed survives the transition.
- **Overdrive.** Carrying an Overcharge Cell. 12 s of +18% speed with the timer
  visible.
- **Thread.** Passing through a gap with less than 0.8 m of clearance without
  touching it. Style points and a little speed on exit.
- **Fracture dash.** The deliberate bugs (§4).

### Precision layer

Precision is not a mini-game; it's the *same* run done cleaner. A precision run
is the same route with fewer inputs, no wasted frames, tighter arcs, and no
style. The game ranks both. The leaderboards are **time** (any route) and
**precision** (no style, no Fractures, no assists).

---

## 3. Speed and precision as a scoring system

Two independent rankings, so there's always a ladder:

| Run type | Rules | What it rewards |
| --- | --- | --- |
| **Time** | Any route, any assists, Fractures allowed | Knowing the fastest line |
| **Precision** | No Fractures, no style moves, no assists, all routes legal | Frame-tight execution |
| **Style** | Scored separately, 0–100k | Flow: chains, threads, no wall bumps |

Style points come from slide chains, wall-jump chains, the thread bonus, the
no-touch bonus, air time and a "flow" multiplier for chaining without touching
the ground. Style is a *secondary* objective, so speedrunners don't have to
choose between fast and cool. Precision runs ban style entirely, which keeps
the two ladders honest.

---

## 4. Fractures: the deliberate bugs

The Concord is old and patched, and it has **cracks**. Some of them ship on
purpose. Finding one, naming it and exploiting it is a legitimate mastery
path, and the game treats it as a feature.

### The twelve Fractures

| # | Name | Trigger | Effect |
| --- | --- | --- | --- |
| 1 | **Seam Skip** | Crossing the seam between two streaming cells during a load frame | Zero speed loss, skips a checkpoint |
| 2 | **Wind Pocket** | Leaving a downdraft at the exact frame | 1.6× launch impulse |
| 3 | **Wall-Kiss Chain** | Contacting a wall within 2 frames of a slide start | +0.8 m/s, stacks to ×5 |
| 4 | **Zip Transfer** | Releasing a zip anchor within 3 frames of contact | Keeps 140% of speed |
| 5 | **Gate Timing** | Passing a closing Concord gate on the frame it starts to open | Gate never re-closes on you |
| 6 | **Regulator Overdraw** | Sliding along a wind regulator's exhaust vent | Free acceleration, ignores friction |
| 7 | **Grav-Lift Double** | Re-grabbing a filament anchor during ascent | Second pull at full force |
| 8 | **Frame Skip** | Jump buffering across a 2-frame landing | Skips the landing animation entirely |
| 9 | **The Long Fall** | Falling past a floor's collision LOD switch | Passes through one floor, lands below |
| 10 | **Cascade** | Killing a regulator drone mid-spin | +0.4 s of air control, no friction |
| 11 | **Sound Skip** | Triggering a sound cue on the exact frame of a section transition | Cue doesn't play, doesn't interrupt |
| 12 | **The First Runner's Path** | Reaching Chapter 13's fracture site with all 11 other Fractures known | Unlocks the third ending |

Fracture 3 is worth a note. The base wall-jump chain is three and tops out at
16.4 m/s. The Fracture is what takes the chain to five and the ceiling to
18.0 m/s, and the registry text above is the shipped wording, which doesn't
change. `addons/windshear/movement/lancer_controller.gd` has
`enable_wall_kiss_chain_fracture()` for it.

### Where the Fractures live

The twelve are spread across the present-day chapters and no two sit in the
same act. Treat this as a guide rather than a promise. A player is meant to
find most of them by breaking the game, not by reading a list.

| # | Name | First reachable | Master route |
| --- | --- | --- | --- |
| 1 | Seam Skip | 9 — THE QUIET LINE | 12 — BLOCK SEAM |
| 2 | Wind Pocket | 5 — VENTWORKS | 6 — HOT PLENUM |
| 3 | Wall-Kiss Chain | 1 — THE LATTICE | 4 — THE LOOP |
| 4 | Zip Transfer | 9 — THE QUIET LINE | 10 — CARGO SPINE |
| 5 | Gate Timing | 1 — THE LATTICE | 18 — THE INNER RING |
| 6 | Regulator Overdraw | 5 — VENTWORKS | 7 — THE REGULATOR BELT |
| 7 | Grav-Lift Double | 6 — HOT PLENUM | 17 — HOLLOW SPIRE |
| 8 | Frame Skip | 8 — SPINE BASEMENT | 10 — CARGO SPINE |
| 9 | The Long Fall | 6 — HOT PLENUM | 8 — SPINE BASEMENT |
| 10 | Cascade | 7 — THE REGULATOR BELT | 16 — THE FIRST RUNNER |
| 11 | Sound Skip | 11 — THE LONG FREIGHT | 19 — CANOPY LADDER |
| 12 | The First Runner's Path | 13 — THE FRACTURE YARD | needs the other eleven |

### Design rules for Fractures

- **Intentional, not accidental.** Each one is deliberately implemented,
  documented internally and kept stable across versions (versioned in
  `fractures.json`).
- **Never mandatory.** Every Fracture route is skippable by a slower line, so
  the base game is complete without them. They're *optional mastery*.
- **Never crash the game.** They must not soft-lock, so they're guarded.
- **Discoverable but not advertised.** The game ships with a **Fracture Codex**
  that starts empty. Players submit a name and a proof clip, the community
  votes, and accepted Fractures get documented in-game *and* in the repo.
- **Speedrun-safe.** Fractures are legal in Time runs and banned in Precision
  runs.
- **Version-stable.** "Fixing" a Fracture would be a nerf for the community. The
  policy is simple: never remove one, only add new ones.

---

## 5. 2.5D and the camera

### Staging

Gameplay is planar, but the world is built in full 3D so there's depth behind
it. Rendering is low-poly PSX-style models at an internal **480×270**, upscaled
with nearest-neighbour, with vertex snapping, flat-ish lighting and a lot of
fog and silhouette. The depth comes from **layered parallax**: foreground
occluders, the play plane, mid-ground architecture, the distant city shell and
a skybox, each with its own fog density.

### The camera never leaves Lancer. Hard rule.

No cutscene cameras. Ever. No dolly-to-face, no over-the-shoulder cinematic,
no letterbox cutaways.

Cutscenes are **diegetic in the play space**: characters walk into frame,
conversations happen with the player in control, props animate in view.

Camera behaviour never changes. It's a 2.5D perspective rig locked to Lancer's
plane, with speed-based FOV and a distance pull-back. It never detaches, never
cuts, never goes first-person.

### Two kinds of cutscene

| Kind | Player input | World | Used for |
| --- | --- | --- | --- |
| **Ambient / minor** | **Unrestricted.** The player can walk away mid-scene. | Runs in real time. | Barks, overheard conversations, optional story, world texture |
| **Major beat** | **Locked.** Lancer freezes, input ignored. | **Time stops** — the world freezes, the scene plays over it, then time resumes | Chapter transitions, the Concord's bulletins, reveals, endings |

The freeze is literal and readable. Time scale drops to 0 for everything except
the scripted actors and VFX, the frame desaturates, the wind drops out and a
subtle scanline crawl marks "the Concord is speaking". Control comes back on a
2-frame count.

Lancer never feels like a puppet while this is happening. The player is still
the protagonist when the game stops to talk.

---

## 6. Chapter structure: twenty-five chapters of twelve sections

Every chapter is **12 numbered sections**. The numbering is a first-class
organising device: saves, leaderboards, speedrun splits, mods and community
routes all use it.

```
P1.01  P1.02  P1.03  ...  P1.12
...
P5.01  P5.02  ...        P5.12
1.01   1.02   ...        1.12
...
20.01 20.02  ...        20.12
```

The game is **Chapter → Section → Beat**. A section runs 30–180 seconds and a
chapter 12–20 minutes, so the present day is roughly **four and a half hours**
of first-run content, with the prequel in front of it. Long enough to master,
short enough to finish in a week of evenings.

### The seven acts

Twenty-five chapters group into seven acts. The acts carry the story and the
chapters carry the world. Act 0 is the prequel: five chapters played as Ilsa
Renn, twenty years before the first chapter of the present day.

| Act | Chapters | Where | What the Concord is |
| --- | --- | --- | --- |
| **0 — THE FRACTURE YEAR** | P1–P5 | Twenty years ago, in daylight | Arrival. The drop, the war, the canopy |
| **I — THE BLOCK** | 1–4 | One quarantine block, morning to dusk | Bureaucracy. Schedules, manifests, a warden |
| **II — THE UNDER-CITY** (Infrastructure & The Patched Organism) | 5–8 | Below the regulation boundary | Machinery. Regulators, heat, exhaust |
| **III — THE SPINE** (Crossing the Dead Zones) | 9–12 | Freight corridors between blocks | Distance. Freight, seams, walls, and the second half's threat |
| **IV — THE YARD & THE MONOLITH** (Origin of the Siege Organism) | 13–16 | Where the Fracture Year happened | A scar. Growth, records, the First Runner |
| **V — THE CORE** (The Canopy Anchors) | 17–19 | Inside the Concord itself | A person. Saye, and what she signed |
| **VI — OPEN WEATHER** (Breaking the Sky) | 20 | Above the last regulation layer | The choice |

### The chapter roster

Every chapter opens in frame, with the camera on the player, and then lets
loose. The full start and play notes for each one live in
`data/sections/index.json`.

| Ch | Title | Act | What happens | Signature mechanics |
| --- | --- | --- | --- | --- |
| **P1** | **OPEN SKY** | 0 | A commuter rail over a sunlit city, fighter jets, civil-defence tickers, and artillery over the harbour | Core verbs, rooftop access, stalled trains; Sergeant Miller's perimeter |
| **P2** | **REDLINE** | 0 | Pinned under a highway overpass with armour rolling past; young Saye waves you through a sandbag breach | Urban combat, cover, M-44 breaching charges, collapse puzzles |
| **P3** | **CONTAINMENT PROTOCOL** | 0 | The seed-cores land and the city starts growing walls in the street; Dr. Aris Thorne throws you the master override key | Shifting geometry, escaping bulkheads, the first Rams |
| **P4** | **THE SKY CLOSES** | 0 | The canopy closes like an iris while Saye signs the override below | Exterior climb on the Pneumatic Grapple Spool, sealing airlocks |
| **P5** | **ZERO CASUALTIES** | 0 | Silence, a walled neighbourhood, and a PA saying the war is over | Stealth, route-finding, the First Runner baseline |
| **1** | **THE LATTICE** | I | A ration tram through Block 404, and Ilsa putting an off-manifest drive in your bag | Traversal, patrol rhythms, Parcel Chutes; Wall-Kiss Chain (F3), Gate Timing (F5) |
| **2** | **CUSTOMS ROW** | I | Saye lectures you through ballistic glass while a scanner arm sweeps your bag | Checkpoint infiltration, pressure plates, Hardline Terminals |
| **3** | **NIGHT SEAL** | I | Dusk. Floodlights go out sector by sector and the bulkheads come down | Alley ambushes with the K-12, slipping under doors |
| **4** | **THE LOOP** | I | Midnight in the Lower Tier, three neighbourhood reps around a shortwave set in Solberg's workshop | Multi-route navigation, Overwatch evasion, escapes |
| **5** | **VENTWORKS** | II | A storm grate, fifty feet, and house-sized turbines pulling air down from the scrubbers | Vertical platforming, Pressure Valve puzzles; Wind Pocket (F2), Regulator Overdraw (F6) |
| **6** | **HOT PLENUM** | II | Heat exchangers boiling under the grid, steam on timers | Hazard timing, overpressure gates, Stiflers; Grav-Lift Double (F7), The Long Fall (F9) |
| **7** | **THE REGULATOR BELT** | II | Six regulators in a row and a PA announcing a sweep | Turbine sabotage, Jammers, riding exhaust; Cascade (F10) |
| **8** | **SPINE BASEMENT** | II | Ankle-deep water under the Spire, where the pillars are warm and no longer concrete | Organic terrain, tendrils, Dartbug nests; Frame Skip (F8) |
| **9** | **THE QUIET LINE** | III | A trestle over the Dead Zone, capsules gliding on high-tension cables | Filament zips, Overwatch nests; Seam Skip (F1), Zip Transfer (F4) |
| **10** | **CARGO SPINE** | III | Cranes loading sealed containers and a relay crate too heavy to pocket | Cargo slings, physics escort, the first C-01 Scatter strike |
| **11** | **THE LONG FREIGHT** | III | The roof of an accelerating armoured train, into a canyon of interdiction nodes | Moving-train combat, Warp Synths, AT-7 rockets; Sound Skip (F11) |
| **12** | **BLOCK SEAM** | III | A thousand-foot living sea-wall, and every siren on it going off at once | Bulkhead puzzles, SDO Troopers, delivering the relay across the divide |
| **13** | **THE FRACTURE YARD** | IV | The rail-yard from the prequel, frozen in time, with the Monolith cube standing over it | Ruin exploration, Rams at 100 m/s; the site of The First Runner's Path (F12) |
| **14** | **THE MONOLITH** | IV | Inside the swallowed Longhorn facility, and an elderly Thorne tapping on the glass of an observation bunker | Lab labyrinth, SDO Troopers, Jammers, Warp Synths, the Arc-Lance |
| **15** | **THE PATCHED THING** | IV | Twenty years of "repair" grown into chitin, and a purge protocol starting | Organic mazes, escaping sterilisation |
| **16** | **THE FIRST RUNNER** | IV | A telemetry chamber at the apex, a cyan ghost, and a model that predicts you | Using Ilsa's recorded route knowledge |
| **17** | **HOLLOW SPIRE** | V | A shaft miles high, with the lockdown floor closing upward behind you | Vertical climb, lift turbines, SDO platforms |
| **18** | **THE INNER RING** | V | Saye alone at the console in a glass gallery above the clouds | Infiltration, the argument, the airlock |
| **19** | **CANOPY LADDER** | V | The Spire's outside, tendons everywhere, hurricane-force updrafts | Exposed assault, wind shear, C-01 gunships |
| **20** | **OPEN WEATHER** | VI | The crown of the Spire, under a mile-wide iris, with sunlight coming down | Final guardians, three endings |

### Section taxonomy

Each chapter's 12 sections mix these roles (typical spread, 12 total): 3 or 4
traversal sections, the core speed and precision content; 2 or 3 combat
sections, short and positional or a firefight that has to be broken open with a
route; one story beat, ambient or major-freeze; one challenge, optional and
high-skill, a Fracture route or a precision line; and one or two connective
sections, short, low-stakes, used as rest beats and splits.

---

## 7. Open-world feel, not an open world

HL2's trick is that you're never more than about 40 seconds away from a
landmark you saw earlier, and the world stays continuous and legible.
WindShear copies that feeling without the sprawl.

**How:** the Spire is visible from Chapter 1, standing over the fog under the
canopy, and the Concord Monolith is visible from the yard in Chapter 13. Every
chapter has three or four permanent anchors you can see from other chapters.
There are no loading screens between sections; a section is a streaming cell
inside a live chapter. Every chapter has at least one fast-return loop, so
mastery means learning a circuit rather than a corridor. Look down and you see
the layer below, and above you the canopy closing off the sky; the Spire
rises through Chapters 5, 9, 17 and 19. The Quiet Line, a high-speed transit
spine of capsules and ziplines, crosses chapters 9 to 12, and it's a shortcut
system and a speedrun line at once.

**How it is *not* open world:** every section is a hand-authored cell, and
nothing procedural sprawls. The world is about 4.5 hours of unique content,
not 15. The freedom is in *how* you cross a section, not in *where* the world
goes. And the Concord's schedule means some routes are only open at certain
times, so the world changes without being open.

---

## 8. Mechanics beyond movement

The brief said velocity is only part of it. Full roster:

### Movement (always available)

Run, slide, jump, wall-jump, ledge grab, air control. And the **Filament**, a
tether to three anchor types: *zip anchors* (launch along a fixed line),
*ring anchors* (swing), *hold anchors* (hang and climb). Aiming is precision
(0.25 s lock-on), using it is speed.

### Wind (signature, but not universal)

**Thermals** are updrafts; hold the direction to climb and the exit timing is
pure precision. **Crosswinds** push laterally, readable from the particle
direction and from cloth. **Regulation fields** are Concord zones that cancel
wind; movement is normal in them, which is what makes them eerie and slow.
**Wind regulators** are the Concord's machines: kill one to kill the wind in a
zone, or ride the exhaust (F6 Overdraw).

### Combat

The game has guns, and they are not the point. They are the second verb, the
one that stops the movement verbs from carrying every section on their own.
The full table is in `docs/ARSENAL.md`; the roster of what you can shoot is in
`docs/ENEMIES.md`.

Seven weapons, two characters. Ilsa and Lancer share the P-20 "Courier", the
V-9 "Vigil" and the M98 "Longhorn". The M-44 "Seam-Splitter" is prequel only.
The K-12 "Key", the AT-7 "Goliath" and the L-01 "Arc-Lance" are Lancer's.

Position beats damage. A Concord Ram is nearly invincible to bullets and
locks onto the player. The answer is always a route: lure it into a pit, drop
a floor under it, or hit it head-on at 100 m/s. Some things need the right
tool, too. The Warp Synth has 200 HP and is immune to bullets; it takes the
AT-7 or the L-01. The K-12 shreds chitin inside eight metres and is a loud
stick outside it.

And the Filament is still a weapon. Grapples, slaps and shoves work on
anything that isn't armoured, and the world is full of barrels, valves and
bulkhead timers that don't care what you're holding.

### Health and decaying overheal

| | Lancer Ivanov | Ilsa Renn |
| --- | --- | --- |
| Base health | 100 HP | 100 HP |
| Ceiling | 150 HP | 100 HP, all through the prequel |
| How the ceiling is reached | Momentum chains, style moves, and shattering Concord Rams or Warp Synths | It isn't |
| What happens after | The overheal decays steadily back down to 100 | Nothing, because there is nothing to decay |

The overheal is the game's second risk curve. A Ram shattered at 100 m/s is
worth 25 HP of overheal that you will lose in about twenty seconds of not
running into anything, and the Fight-or-burn decision at the top of a wall is
a decision about timing rather than about damage.

### Usable items

| Item | When | What it does |
| --- | --- | --- |
| **Field Ration / Trauma Kit** | Both halves | Restores 25 HP, capped at the 100 HP base |
| **Adrenaline Stim-Pen** | Main game | Clears movement slow effects such as Concord Stifler coolant drag, and triggers 25 points of decaying overheal for 10 seconds |
| **EMP / Signal Scrambler Flare** | Main game | Blinds sensor pylons, scrambles Warp Synth lock-on charges for 3 seconds, and delays Quarantine Bulkhead timers |
| **Thermal-Foil Cloak** | Both halves | Masks body heat from automated scanners while crouched or moving below 8 m/s, and breaks the instant you sprint, slide or fire |
| **Pneumatic Grapple Spool** | Prequel only | Slow vertical climbs and rappels, before the Filament tether existed |

### Map-built utilities

| Utility | When | What it does |
| --- | --- | --- |
| **Pneumatic Parcel Chutes** | Main game | Dead-drop tubes for smuggled drives and relays, built into alleys and stations |
| **Concord Med-Dispenser** | Both halves | Dispenses a Field Ration worth 25 HP. Unlocked in 20XX; cracked open with a cipher key or gunfire in the present day, and gunfire sets off a local patrol chime |
| **Pressure Valves** | Main game | Heavy wheel-valves on Wind Regulators and Ventworks pipes that vent scalding steam onto patrols or open a high-velocity thermal |
| **Coolant & Fuel Barrels** | Both halves | Pressurised steel drums that detonate when shot or kicked into a hazard, damaging Warp Synths or collapsing walkways |
| **Hardline Terminals** | Main game | Exposed junction boxes that override local area denial for 15 seconds when keyed |

### Other systems

| System | Function | Why it's not movement |
| --- | --- | --- |
| **Filament** | Precision aiming + traversal | Pure geometry, no air |
| **Time gates / regulation schedule** | Sections open/close on a timer | Rhythm, not air |
| **Bio-constructs** | Patrols, chases, anchors and projectors | Combat pressure |
| **Cargo / parcels** | Optional carry objectives; weight slows you | Risk/reward vs. speed |
| **Cargo slings** | Throw parcels to hit distant switches | Precision puzzle |
| **Recall** | Replay the last 12 seconds of your own run as a ghost | The visual core |
| **Flow** | Grapple-surf, wall-run, air-dash, zip | The movement vocabulary |
| **Overdrive cells** | Temporary speed boosts, scarce | Pace control |
| **Fractures** | Exploitable bugs | Reward mastery |
| **Speed readout** | Current and peak speed, in metres per second | A number you can check |

### The speed readout

Speed is measured in **metres per second** everywhere: the tuning file, the
mechanics reference, the discovery report and the HUD. The HUD shows the
current horizontal speed and the peak since the last respawn, because a
speedrunner wants the second number and everybody else can ignore it. There
are no pixels per second anywhere in the project. A number that only means
something inside the engine is a number nobody can argue with.

The Concord's sensors and turrets read the same unit. Fourteen metres a
second is a sprint. Sixteen point four is a wall-jump chain, and a hundred,
head-on, is the only speed that opens a Concord Ram.

### Recall (the signature visual)

The world remembers your last 12 seconds and renders it as a translucent
double. You can race it. It's a learning aid, a ghost and a competitive device,
all one system. On death, Recall becomes the respawn. You re-enter the world as
your own ghost and get a few seconds of overlap before you diverge.

---

## 9. The 2.5D camera in practice

The camera is a **constrained 3D rig locked to the play plane**: a side-on 2.5D
view with the full depth of a 3D scene behind it.

It follows Lancer with **velocity lookahead**, leading in the direction of
travel. The **speed dolly** pulls back and widens the FOV as speed rises, which
is the single most important tool for making speed *feel* fast. **Air
framing** tilts down slightly on long falls and up on launches. **Verticality**
keeps the horizon stable, so a 40 m drop reads as vertical. During a **time-stop
beat** the camera *locks* to Lancer's last position; the world stops but the
framing stays composed, because the camera is Lancer's and not the director's.

It never cuts, never detaches and never goes first-person. It always contains
Lancer, with headroom for the jump arc.

The mouse is the camera, and it does the two triggers as well. The keyboard
carries movement and everything else, and the camera also has a keyboard route:
the arrows turn it and `W` and `S` tilt it, at a slower rate than the mouse,
so a keyboard player can line up a shot instead of whipping past it. The
defaults are in `docs/CONTROLS.md`, and `tests/test_input_map.gd` fails the
build if the scheme ever drifts.

---

## 10. Enemies and hazards

The Concord doesn't fight Lancer. It denies the ground, one room at a time.
Everything in the first table below is area denial. The level closes, the
route changes, and the run turns into a question of where you were going to
be in two seconds.

| Threat | Behaviour | Counter | Rule |
| --- | --- | --- | --- |
| **Concord gate** | Opens on a schedule | Timing, speed, or Fracture | Schedules are learnable and displayed |
| **Quarantine Bulkhead** | A living blast door slams shut across the route | Be through the gap when it closes | The door is the antagonist's offence, so the player runs *away* from the system |
| **Purge and Sterilization Protocol** | A sector floods with hazards once an intruder is logged | Leave the sector, or find the shaft it doesn't reach | Announced before it starts; never a surprise |
| **Interdiction node** | Stationary turret or snare-tendril guarding a bridge or shaft | Time the sweep, or go around | Always a route it doesn't watch |
| **Wind regulator** | Large, anchored, emits a gust cone | Hit the valve; or exploit exhaust for speed | It blocks the route; there is always a speed line through it |
| **Pressure plate** | Triggers gates, alarms, collapse | Parcel sling; or overshoot via Fracture | Always two solutions |
| **Gap / updraft** | Environmental | Timing | Never a blind jump, always readable |
| **Grown seam** | The Concord's own scar tissue. Soft, warm, bleeds when scraped | It deforms, so it slows you differently | Acts like a hazard, reads like a wound |

### The bio-constructs

| Enemy | Role | Damage | Counter |
| --- | --- | --- | --- |
| **Concord Dartbug** | Chaser / swarm | 10 a stab | P-20 or V-9. They come in packs, so it's an aim check and a momentum check at once |
| **Concord Ram** | Chokepoint anchor / juggernaut | Contact damage | Nearly invincible to bullets, and it locks onto the player. Avoid it, lure it into a pit, drop a weakened floor under it with an M-44, or shatter it head-on at 100 m/s |
| **Concord Stifler** | Toxic / hazard | Caustic pool, 5 HP/s | Grown out of a ruptured Grown Seam. It dies into a pool that kills slide friction, so the floor after it is worse than the fight. The Adrenaline Stim-Pen clears the drag |

### The present day's threat

| Enemy | Role | Damage | Counter |
| --- | --- | --- | --- |
| **Concord Trooper** | Tactical infantry | Squad fire, timed grenades | The baseline. Expect them, flank them, don't let a grenade pin the route |
| **Napalm Mortar** | Area denier | Lingering fire | Kill the crew before it fires and the canister can be thrown back as a fire-bomb |
| **Concord Overwatch** | Sniper / roof watcher | 45 a hit | The cyan targeting laser is the warning. Forty-five HP a hit means one mistake is most of a health bar |
| **Concord Diver** | Chaser / rusher | 20 a strike | Pneumatic-legged, vaults gaps, closes from above. The K-12 shreds them inside eight metres |
| **Concord Jammer** | Disruptor | Static field | Its static-air sphere cancels thermals and jams Filament lock-ons. The sphere is the problem, so hit the rear pressure core |
| **Warp Synth** | Sniper / armoured anchor | Hyper-fast projectiles | 200 HP and immune to bullets. It takes the AT-7 or the L-01, or a route it is not watching |
| **Concord Special Defense Operations Trooper** | Elite guard / strike coordinator | Squad coordination | Heavy elite troops who coordinate rather than hold. The squad is the target |
| **Concord C-01 "Scatter"** | Air-to-ground area denier | Cluster napalm | A gunship directed by an SDO Trooper. Leave the floor: walls, wall-jumps, Filament. Kill the SDO and it goes home |

**Concord military infantry, artillery and synths do not exist in the Fracture
Year prequel.** Only the early bio-constructs do. The roster is data, in
`data/enemies.json`, and the canon test checks that the main-game threat never
turns up in a prequel chapter.

The escalation runs with the acts. Act I gives you one scheduled gate per
section and nothing else. By Act VI a section carries four, spread across three
different cycles, and the slowest one guards the good route. By then you're
reading two or three schedules at once, and the speedrun line is the one that
assumes you can.

**No instant-death.** Hazards reset you to the last checkpoint with a fast
respawn (< 1.2 s) and no loading. Death is cheap; flow is protected.

---

## 11. Open source, community storylines

The brief: free and open source, so the community can build versions of the
game with different storylines. Not an SDK.

### Position

WindShear is a **complete, playable game** and it's open source. Not a toolset
with an example project. The engine code, the levels, the art, the audio and
the official story are all in the repo, and anyone can change the story without
asking anyone.

### How alternative storylines work

The game separates **world** from **story**. The **world layer** (the city, the
Concord, physics, mechanics, the 25×12 section grid) is stable and shared.
The **story layer** (Lancer's arc, NPC dialogue, major beats, endings) is
**data-driven**: a `story/*.json` plus per-section beat scripts.

A community build (an "Edition") supplies an alternate `story/` directory. The
game loads it at boot and everything else stays put. An Edition can rewrite
dialogue, beat scripts and endings; reuse the world and mechanics wholesale;
add or remove sections within the 12-per-chapter grid; and ship as a folder, a
Git repo or a zip.

Distribution is an **Edition browser** inside the game. It scans
`user://editions/` and a configurable community index URL. No account, no DRM,
no closed launcher.

### Licensing

| Asset class | License | Rationale |
| --- | --- | --- |
| Game code | **GPL-2.0-or-later** | Copyleft on the code is what guarantees a community version can't be a black box: anything built on it has to ship its source under the same terms. Godot is MIT, so the combination is compatible. |
| Game content (levels, models, audio, art) | **CC-BY-SA 4.0** | Anyone can reuse the assets in their own game, commercial included; anything derived from those assets has to be shared alike. |
| Official story layer | **CC-BY-SA 4.0** | Alternate storylines inherit share-alike, so the commons of story beats keeps growing instead of being hoarded. |
| Community Editions | **Must be open source** and GPL-CC-compatible to be published to the official index | The index validates the declared license. Code in an Edition is GPL by inheritance; pure-data Editions are bound by the share-alike on the story assets they reuse. |
| Trademarks ("WINDSHEAR", "The Concord") | Not licensed; nominative use allowed | Don't let forks become official |

The game is **free forever**. No monetisation, no ads, no telemetry. There's an
optional donation link and nothing else.

**Practical notes on the copyleft.** Shipping a build means shipping the source
with it. The public repo plus the release tag satisfies GPL §3, so no separate
source tarball is needed. There's no DRM, no activation and no always-online
check; GPL §0 and §1 forbid restricting the people who receive the game from
running or sharing it. There's no proprietary-linking exception either, which
would be LGPL-style. If closed-source commercial games are wanted one day,
that's a deliberate policy reversal rather than an oversight.

The point of the copyleft, in practice: "other people have to open-source their
version too" is enforceable for code under the GPL and for the assets and
story they reuse under CC-BY-SA. A version written from scratch against the
*idea* of WindShear, with no code and no assets, is legally their own. That's
the intended outcome, not a loophole.

### Contribution surfaces

Mechanic and level tutorials, in-game and in the repo. Fracture discoveries:
submit a name and a clip, the community votes, it goes in the Codex.
Translation, since the string tables are already externalised. Accessibility
options. Optimisations for low-end hardware. And **Editions**, which are the
flagship community activity.

---

## 12. RAM and performance budget (hard target: under 4 GB)

Godot 4.7.2, **Compatibility renderer**, PSX-style low-res internal buffer.

### Targets

| Metric | Target |
| --- | --- |
| **Peak RAM** | **≤ 2.5 GB** (hard fail above 3.0 GB; never exceed 4 GB) |
| VRAM | ≤ 512 MB |
| Internal resolution | 480×270 (some areas 320×240 for retro sections) |
| Frame time | 16.6 ms @ 1080p output, 60 fps |
| Triangle budget | ≤ 35k visible, ≤ 180k loaded |
| Draw calls | ≤ 220 |
| Level streaming | 1 chapter resident + 1 prefetch |
| Audio | 48 kHz Vorbis, mono SFX, streamed music |

### Memory rules

**Cell-based streaming.** Each section is a cell with its own resources. Cells
unload with a 2-cell hysteresis so nothing thrashes, and unloading is explicit
rather than left to the GC. **Per-cell budgets:** ≤ 45 MB textures, ≤ 20 MB
meshes, ≤ 12 MB audio, enforced by CI. No runtime mesh generation beyond tiny
decals; all geometry is pre-baked. **Texture atlases:** no more than 8 atlas
pages resident per cell. **Pooled VFX and particles**, with no per-frame
allocation in hot paths. **Object pooling** for regulators, parcels, damage
numbers and pickups. And **fixed memory budgets at build time**: CI fails if a
cell exceeds budget.

Reference hardware: 8 GB RAM, a GTX 950 or integrated Vega 8, 4-core CPU. It
has to run on 4 GB machines without swap.

### Low-poly PSX art direction

Vertex-coloured low-poly models, with no per-pixel textures where you can avoid
them. Affine-textured triangles on large surfaces, 15-colour ramps, heavy fog,
vertex-snapped geometry, dithered gradients.

---

## 13. Narrative delivery

**No cutscene camera, ever.**

**Lancer never speaks.** There are no Lancer lines in the dialogue file.
Anything Lancer has to say is said by running, handing over a parcel, or
refusing to hand one over. Other characters talk at Lancer across glass and
across checkpoints, and Lancer answers with movement.

**Ilsa is silent in the prequel.** The five Fracture Year chapters are played
as her, and she does not speak in them, the same way Lancer does not. She
starts talking again in the present day, and what she says is a route.

**Ambient scenes** run in real time and the player is free to leave. Most of
the story is ambient. **Major beats** freeze Lancer, stop world time, play the
scene in-frame and resume control; there are 8 to 12 of them in the whole game.

The Concord "speaks" through the world itself: containment bulletins on street
displays, PA announcements, schedule boards. Diegetic, no cutscenes.

**Dialogue** is short, in-frame, subtitled and skippable. There's no voice
acting budget, so use stylised "tuner" chirps and text.

**Endings:** three of them, differing by Fracture state and final choice.

---

## 14. Roadmap

### Milestone 0 — "Does it feel good?" (2 weeks)

Greybox runner: run/slide/jump/wall-jump/filament. One 90-second test room, no
art. The gate is 5 external testers saying the movement is satisfying
unprompted.

### Milestone 1 — Vertical slice (8 weeks)

The prequel's five chapters in greybox, so the story starts at the Fracture
Year rather than twenty years after it. Chapter 1 sections 1.01 to 1.12,
greybox to art. Core mechanics, 3 Fractures, the Recall ghost, timer and
splits. The gate is a 5-minute run that feels like a toy people want to
replay.

### Milestone 2 — Systems & content (12 weeks)

All 25 chapters playable in greybox, all 12 Fractures implemented. The
arsenal: P-20, V-9 and M98 in the prequel and the present day; K-12 and AT-7
from Act I; the L-01 from Act III. Editions and the story system, the Fracture
Codex, accessibility options. The gate is an external team shipping an
alternate storyline.

### Milestone 3 — Polish & ship (8 weeks)

Art pass, audio, onboarding, menus, localization scaffolding. The gate is a
public release and a community fork count above zero.

### Milestone 4 — Community era (ongoing)

Edition index, community maps, seasonal Fracture events (new Fractures added,
never removed).

---

## 15. Open questions

1. **The Concord's endgame.** Does Lancer destroy it, reform it or outrun it?
   The three endings cover the range of it, but the middle-act reveal still
   needs locking.
2. **The team.** Lancer runs for people now: Ilsa, Solberg, Talia and the
   Free-Band Network. What is the network called in the fiction, and what
   happens to it when Saye starts asking questions?
3. **Solberg and the Arc-Lance.** He assembles the L-01 out of regulator
   parts, and the prototype itself is in the Monolith in Act IV. Does he meet
   Lancer again between the yard and the Monolith, or does Lancer carry the
   prototype alone?
4. **Fracture disclosure.** Ship with nothing documented, so it's a pure hunt,
   or seed one per chapter? I'd seed 3 and let the other 9 be found.
5. **Edition scope.** How much of the 25×12 grid can an Edition rewrite before
   it stops being WindShear?
6. **Wind in Chapter 1.** Introduce wind late, in Chapter 5, so it lands by
   contrast, or front-load it?
7. **The prequel's length.** Five chapters is twenty-four hours of game time
   before the present day starts. Is that the right size for a prologue, or
   should the prequel be a cut-down version of the same chapters?
8. **How much of Ilsa's silence survives.** She is silent in the prequel and
   talks in the present day. Does she talk more than she does now, or is the
   mentor's job mostly written routes?

---

## Appendix A: section numbering standard

Sections are addressed as `chapter.section`, for example `2.07`. The prequel
uses `P1` to `P5`, so `P3.07` is a real section and so is `13.07`. Splits,
saves, leaderboards, Edition scripts and community route files all use that ID.
Content inside a section is addressable as `chapter.section.beat` for major
beats, for example `13.03.FRACTURE`.

## Appendix B: Fracture registry policy

Fractures live in `data/fractures.json`. Each one carries an id, a name, a
version, a trigger description, an effect, a category (speed, precision or
routing) and `speedrun_legal`, which is true in Time runs and false in
Precision runs. A Fracture is **never removed** once it has shipped, only
added. Removing one is a breaking change to the community's routes.

The registry's wording for Fracture 12 still says "Chapter 4's fracture
site", because that is the text it shipped with and shipped Fractures are
immutable. The site is Chapter 13, THE FRACTURE YARD, which is where Ilsa's
route was recorded in the first place.

The same rule is why Fracture 3 still says "stacks to ×5" while the base
wall-jump chain is three. The fifth wall-jump is the Fracture.

## Appendix C: the canon files

| File | What it holds |
| --- | --- |
| `data/cast.json` | Every character, their pronouns, their acts and who may speak |
| `data/arsenal.json` | Weapons, usable items and map-built utilities |
| `data/enemies.json` | The Concord roster, with health, damage and drops |
| `data/player.json` | Health, overheal and the speed thresholds the sensors read |
| `data/sections/index.json` | The 25×12 grid, with the opening and the play of every chapter |
| `data/schedule.json` | 600 gate windows |
| `data/fractures.json` | The twelve Fractures, versioned and immutable |
| `data/story/dialogue/en.json` | Every spoken line, and the brackets that stand in for Lancer |
| `data/story/beats/` | The beat scripts, one file per section |
| `data/story/endings.json` | The three endings and their conditions |

`tests/test_canon.gd` reads those files and checks them against each other
and against this document. If the roster and the design doc disagree, the
build fails.
