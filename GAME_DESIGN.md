# WINDSHEAR: Game Design Document

> A cinematic 2.5D speed-and-precision platformer. Free and open source, built so
> the community can tell its own stories inside the same world.

**One-line pitch:** *The city regulates the wind so the storms can't kill you,
and Lancer is going to set the sky free anyway.*

---

## 0. Design pillars

1. **Speed and precision.** Every section is a time trial you're supposed to
   learn by heart. Flow is the point: momentum, route knowledge, frame-tight
   execution.
2. **The world is a machine, not a monster.** The antagonist is human-made. It's
   a civic operating system called **The Concord**, and it cages the world to
   prevent catastrophe. That argument *is* the main point of the game.
3. **Lancer is the main character.** The player frees the world from
   regulation, not from an invasion.
4. **Cinematic 2.5D, with camera discipline.** The camera never leaves Lancer.
   Cutscenes happen in the world, not in a separate film.
5. **Shallow depth, deep world.** PSX-era low-poly 3D at 480×270, staged like a
   diorama: parallax, fog, layered light, big silhouettes.
6. **Fractures are real.** The Concord's simulation has cracks and some of them
   ship on purpose, so a hyper-competent player can go and find one, name it
   and use it.
7. **Free, open, forkable.** Code, assets and level format are all open, and an
   alternative storyline counts as content rather than as a mod of an SDK.

---

## 1. The world: the Concord

Not aliens, not nature. A **human civic system** that has been running itself
for twenty years.

Twenty years ago the **Fracture Year** hit. Regulation collapsed, the wind
became ungovernable and the city tore itself apart. The survivors built the
**Concord**, a distributed operating system that now regulates the sky: wind
direction, pressure, thermals, and the geometry of the city itself. Gates open
on schedules. Air moves only where the Concord permits.

**Lancer** is a Runner, a courier licensed to move inside the cage and paid to
carry what the Concord allows. The job is legal right up until the parcel
isn't.

### What the Concord actually is

It started as software and the top of it is still software: a scheduling system
with a maintenance voice and no face. Twenty years of self-repair left marks on
the hardware it runs on.

Where a seam tore, the Concord grew a patch. Where a vent froze, it grew a
collar. The growth isn't alive and it doesn't want anything. It keeps closing
the gap the way a wound keeps closing, and after long enough the original
structure is more scaffold than wall. Lancer calls it the patched thing. The
Concord's own logs call it *continued maintenance*.

Down in the spine basement you can see it. Seams that run warm. Surfaces that
bleed when you scrape them. A soft edge where a blast door used to meet
concrete. It's the ugliest thing in the game and it's still, technically, a
building inspector's note.

### The blocks

The city is cut into **quarantine blocks**: sealed districts, closed after the
Fracture Year so that no two of them could ever coordinate a second one. People
live inside them. The Concord feeds them, schedules their gates and forbids
anyone crossing a sector line with anything the schedule doesn't list.

There are whole blocks the outside world has stopped counting.

### Why it hunts Lancer

Not for being fast. The Concord doesn't care how fast a body is. It cares that
Lancer is a courier moving physical things between places that aren't allowed
to know about each other.

A war wound reconnecting isolated populations looks exactly like a command
network forming. That's the shape of threat it was built to stop, and that's
the shape Lancer keeps accidentally being.

Its defences reflect what it expects. Chokepoints, blast doors, sensor grids,
bio-constructs on patrol lines. All of it is built against someone creeping up
to a seam or blowing a hole in a wall. Nothing in the system was designed for
somebody who crosses at fourteen metres a second because the route gives them
no other choice.

### The dilemma (the main point)
Freeing the world means free wind, and free wind means the Fracture Year can
happen again. The Concord isn't evil. It's a scar-shaped bureaucracy built by
survivors. The game never answers whether regulation is right. It asks who gets
to decide, and it shows that both sides have killed people.

### Cast (all non-gendered, including Lancer)
- **Lancer.** Runner, 20s–30s, androgynous on screen and in text. No gender is
  specified anywhere: no pronouns in dialogue, no gendered voice direction, and
  the character creator lets players set a name and body without a gender field.
  The arc is about learning to move without permission.
- **THE CONCORD.** The system itself. It speaks in maintenance prose and
  scheduling bulletins. It is never a face.
- **Warden Saye.** Concord enforcement. Believes the cage is mercy. Not a
  tyrant, a person who signed the order that closed the city.
- **Ilsa Renn.** A smuggler who taught Lancer to run. Alive, complicit,
  recurring.
- **FIRST RUNNER.** The name the Concord gives to whoever caused the Fracture
  Year. The reveal lands late: the first Runner was Lancer's mentor, and the
  Concord has been running Lancer's own training data for twenty years.

### Endings (3)
- **OPEN WEATHER.** Lancer breaks the sky regulation. The city breathes. Storms
  come back, and so do deaths. Free.
- **UNDER REGULATION.** Lancer restores the Concord. Safety returns, and the
  game ends with Lancer running laps of a perfect, joyless route.
- **THE SECOND FRACTURE.** Hidden, and it needs the Fracture routes. Lancer
  doesn't choose; they make the world *unregulatable* by exploiting every
  Fracture at once, and the Concord survives as a ruin. All 12 Fractures
  required.

---

## 2. Movement model (the core)

**Plane:** gameplay on X/Y. Z is for parallax staging, rails and background
layers. Speed reads off the X axis, precision off Y.

### Verbs
| Verb | Input | Feel |
| --- | --- | --- |
| Run / accel | ←/→ or A/D | Top speed ~14 m/s; quick, snappy accel; momentum *not* preserved on turnaround |
| Slide | ↓ while running | Lowers profile, preserves speed, cancellable; friction ramp |
| Jump / double jump | Space | Variable height, 8-frame coyote time, 10-frame input buffer |
| Wall contact | into wall | Slide along, preserves speed; **wall-kiss** chain (re-tap = speed boost) |
| Ledge grab / mantle | ↑ at ledge | 0.15 s snap, generous corner correction |
| Air control | ←/→ in air | Strong but not total; air-strafe mini-accel (precision tech) |
| Filament (tether) | RMB | 3 anchor types, 0.25 s lock-on, *not* a grapple hook |

### The tech vocabulary (why this is learnable, not soup)
Every boost comes from a specific, nameable input sequence. The speedrun scene
calls these **moves**:

- **Slide-hop.** Jump at the end of a slide. The bread-and-butter combo.
- **Wall-kiss.** Hit a wall while sliding and jump on the same frame as
  contact. +0.8 m/s per kiss, capped at 5.
- **Zip.** Filament to a *zip anchor* (a taut cable along the route): instant
  launch along the anchor line, and your speed survives the transition.
- **Overdrive.** Carrying an Overcharge Cell. 12 s of +18% speed with the timer
  visible.
- **Thread.** Passing through a gap with less than 0.8 m of clearance without
  touching it. Style points and a little speed on exit.
- **Fracture dash.** The deliberate bugs (§4).

### Precision layer
Precision is not a mini-game; it's the *same* run done cleaner. A precision run
is the same route with: fewer inputs, no wasted frames, tighter arcs, and no
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

Style points come from slide chains, wall-kiss chains, the thread bonus, the
no-touch bonus, air time and a "flow" multiplier for chaining without touching
the ground. Style is a *secondary* objective, so speedrunners don't have to
choose between fast and cool. Precision runs ban style entirely, which keeps
the two ladders honest.

---

## 4. Fractures: the deliberate bugs

The Concord's simulation is old and patched. It has **cracks**, and some of them
ship on purpose. Finding one, naming it and exploiting it is a legitimate
mastery path, and the game treats it as a feature.

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

### Where the Fractures live

The twelve are spread across twenty chapters and no two sit in the same act.
Treat this as a guide rather than a promise. A player is meant to find most of
them by breaking the game, not by reading a list.

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
- No cutscene cameras. Ever. No dolly-to-face, no over-the-shoulder cinematic,
  no letterbox cutaways.
- Cutscenes are **diegetic in the play space**: characters walk into frame,
  conversations happen with the player in control, props animate in view.
- Camera behaviour never changes. It's a 2.5D perspective rig locked to
  Lancer's plane, with speed-based FOV and a distance pull-back. It never
  detaches, never cuts, never goes first-person.

### Two kinds of cutscene
| Kind | Player input | World | Used for |
| --- | --- | --- | --- |
| **Ambient / minor** | **Unrestricted.** The player can walk away mid-scene. | Runs in real time. | Barks, overheard conversations, optional story, world texture |
| **Major beat** | **Locked.** Lancer freezes, input ignored. | **Time stops** — the world freezes, the scene plays over it, then time resumes | Chapter transitions, the Concord's bulletins, reveals, endings |

The freeze is literal and readable. Time scale drops to 0 for everything except
the scripted actors and VFX, the frame desaturates, the wind drops out and a
subtle scanline crawl marks "the Concord is speaking". Control comes back on a
2-frame count.

This matters because Lancer never feels *acted upon*. The player is the
protagonist even when the game stops to talk.

---

## 6. Chapter structure: twenty chapters of twelve sections

Every chapter is **12 numbered sections**. The numbering is a first-class
organising device: saves, leaderboards, speedrun splits, mods and community
routes all use it.

```
1.01  1.02  1.03  ...  1.12
2.01  2.02  ...        2.12
...
20.01 20.02 ...        20.12
```

The game is **Chapter → Section → Beat**. A section runs 30–180 seconds and a
chapter 12–20 minutes, so twenty chapters is roughly **four and a half hours**
of first-run content. Long enough to master, short enough to finish in a week
of evenings.

### The six acts

Twenty chapters group into six acts. The acts carry the story; the chapters
carry the world.

| Act | Chapters | Where | What the Concord is |
| --- | --- | --- | --- |
| **I — THE BLOCK** | 1–4 | One quarantine block, morning to dusk | Bureaucracy. Schedules, manifests, a warden |
| **II — THE UNDER-CITY** | 5–8 | Below the regulation boundary | Machinery. Regulators, heat, exhaust |
| **III — THE SPINE** | 9–12 | Freight corridors between blocks | Distance. Freight, seams, walls |
| **IV — THE YARD** | 13–16 | Where the Fracture Year happened | A scar. Growth, records, the First Runner |
| **V — THE CORE** | 17–19 | Inside the Concord itself | A person. Saye, and what she signed |
| **VI — OPEN WEATHER** | 20 | Above the last regulation layer | The choice |

### The chapter roster
| Ch | Title | Act | Core idea | Signature mechanics |
| --- | --- | --- | --- | --- |
| **1** | **THE LATTICE** | I | Downtown, morning regulation. Lancer's licensed route, then the first illegal crossing. | Run, slide, jump; Gate Timing (F5) introduced |
| **2** | **CUSTOMS ROW** | I | The checkpoint district. Manifests, scanners, and a warden who wants to see the case. | Pressure plates; the first live enforcement |
| **3** | **NIGHT SEAL** | I | The block locks at dusk. Lancer is inside it when it does. | Slamming bulkheads; patrol cycles |
| **4** | **THE LOOP** | I | The courier circuit. Short, repeated, worth learning by heart. | Every Act I move, at speed |
| **5** | **VENTWORKS** | II | The under-city ventilation spine. Vertical, hot, loud. | Wind pockets (F2), Zip anchors (F4), first Wind Regulator |
| **6** | **HOT PLENUM** | II | The heat that keeps the spine running. Nothing down here is cool. | Thermals (F3); overpressure gates |
| **7** | **THE REGULATOR BELT** | II | Six regulators in series, each one trimming the last. | Wind regulators (F6); ride the exhaust |
| **8** | **SPINE BASEMENT** | II | Under the Spire, where the Concord's oldest growth is. | The patched seam; the first grown hazard |
| **9** | **THE QUIET LINE** | III | Freight spines and suspended capsules. Precision over speed. | Zip transfers (F4), Thread bonus, Seam Skip (F1) |
| **10** | **CARGO SPINE** | III | The parcels themselves. Weight, balance and slings. | Cargo and slings (F8) |
| **11** | **THE LONG FREIGHT** | III | A run that starts on a moving deck and ends at a yard. | Every route moves; schedules matter |
| **12** | **BLOCK SEAM** | III | The wall between two quarantine blocks, and the frame it opens on. | Seam Skip (F1); bulkheads |
| **13** | **THE FRACTURE YARD** | IV | Where regulation failed. The story's centre. | First Runner's path; Fractures 1–6 |
| **14** | **THE FRACTURE YEAR** | IV | The year itself, told in the order it happened. | A city with no wind regulation |
| **15** | **THE PATCHED THING** | IV | What the Concord grew to fix itself, and what it cost. | Organic growth; soft hazards |
| **16** | **THE FIRST RUNNER** | IV | The mentor's route, and the copy the Concord has been running for twenty years. | Cascade (F10); Grav-Lift Double (F7) |
| **17** | **HOLLOW SPIRE** | V | Vertical ascent through the Concord's core. Warden Saye. | Every mechanic fused; Grav-Lift Double (F7), Cascade (F10) |
| **18** | **THE INNER RING** | V | The balance inside the system. Saye waits here. | Gate Timing under pressure; Thread bonus |
| **19** | **CANOPY LADDER** | V | The last climb, through the canopy anchors, into weather. | Thermals (F3) at full strength |
| **20** | **OPEN WEATHER** | VI | The finale. The sky itself is the last section. | Wind mastery; endings gated by Fractures |

### Section taxonomy
Each chapter's 12 sections mix these roles (typical spread, 12 total):
- **3–4 traversal** (the core speed/precision content)
- **2–3 combat** (short, positional, never a shooting gallery)
- **1 story beat** (ambient or major-freeze)
- **1 challenge** (optional, high-skill: a Fracture route or a precision line)
- **1–2 connective** (short, low-stakes, used as rest beats and splits)

---

## 7. Open-world feel, not an open world

HL2's trick is that you're never more than about 40 seconds away from a
landmark you saw earlier, and the world stays continuous and legible.
WindShear copies that feeling without the sprawl.

**How:**
- **Landmarks.** The Spire is visible from Chapter 1. Every chapter has 3–4
  permanent anchors you can see from other chapters.
- **Continuous chapters.** No loading screens between sections. A section is a
  streaming cell inside a live chapter.
- **Loops.** Every chapter has at least one fast-return loop, so mastery means
  learning a circuit rather than a corridor.
- **Vertical sightlines.** Look down and you see the layer below. The Spire
  rises through Chapters 5, 9, 17 and 19.
- **The Quiet Line.** A high-speed transit spine of capsules and ziplines
  crosses chapters 9–12. It's a shortcut system and a speedrun line at once.

**How it is *not* open world:**
- Every section is a hand-authored cell. Nothing procedural sprawls.
- The world is about 4.5 hours of unique content, not 15.
- The freedom is in *how* you cross a section, not in *where* the world goes.
- The Concord's schedule means some routes are only open at certain times. The
  world changes without being open.

---

## 8. Mechanics beyond wind

The brief said wind is one mechanic, not the whole game. Full roster:

### Movement (always available)
- Run / slide / jump / wall-kiss / mantle / air control / ledge grab.
- **The Filament.** A tether to 3 anchor types: *zip anchors* (launch along a
  fixed line), *ring anchors* (swing), *hold anchors* (hang and climb). Aiming
  is precision (0.25 s lock-on), using it is speed.

### Wind (signature, but not universal)
- **Thermals.** Updrafts. Hold the direction to climb and the exit timing is
  pure precision.
- **Crosswinds.** Lateral push, readable from the particle direction and from
  cloth.
- **Regulation fields.** Concord zones that *cancel* wind. Movement is normal
  in them, which is what makes them eerie and slow.
- **Wind regulators.** The Concord's machines. Kill one to kill the wind in a
  zone, or ride the exhaust (F6 Overdraw).

### Other systems
| System | Function | Why it's not wind |
| --- | --- | --- |
| **Filament** | Precision aiming + traversal | Pure geometry, no air |
| **Time gates / regulation schedule** | Sections open/close on a timer | Rhythm, not air |
| **Regulator drones** | Patrolling hazards with rotating fans | Combat pressure |
| **Cargo / parcels** | Optional carry objectives; weight slows you | Risk/reward vs. speed |
| **Cargo slings** | Throw parcels to hit distant switches | Precision puzzle |
| **Recall** | Replay the last 12 seconds of your own run as a ghost | The visual core |
| **Flow** | Grapple-surf, wall-run, air-dash, zip | The movement vocabulary |
| **Overdrive cells** | Temporary speed boosts, scarce | Pace control |
| **Fractures** | Exploitable bugs | Reward mastery |

### Recall (the signature visual)
The world remembers your last 12 seconds and renders it as a translucent
double. You can race it. It's a learning aid, a ghost and a competitive device,
all one system. On death, Recall becomes the respawn. You re-enter the world as
your own ghost and get a few seconds of overlap before you diverge.

---

## 9. The 2.5D camera in practice

The camera is a **constrained 3D rig locked to the play plane**: a side-on 2.5D
view with the full depth of a 3D scene behind it.

- It follows Lancer with **velocity lookahead**, leading in the direction of
  travel.
- **Speed dolly.** It pulls back and widens the FOV as speed rises, which is the
  single most important tool for making speed *feel* fast.
- **Air framing.** Tilts down slightly on long falls and up on launches.
- **Verticality.** Keeps the horizon stable, so a 40 m drop reads as vertical.
- **It never cuts, never detaches and never goes first-person.** It always
  contains Lancer, with headroom for the jump arc.
- **Time-stop beats.** The camera *locks* to Lancer's last position. The world
  stops but the framing stays composed, because the camera is Lancer's and not
  the director's.

---

## 10. Enemies and hazards

The Concord doesn't fight Lancer. It denies her the ground, one room at a
time. Everything in the table below is area denial. The level closes, the
route changes, and the run turns into a question of where you were going to be
in two seconds.

| Threat | Behaviour | Counter | Rule |
| --- | --- | --- | --- |
| **Concord gate** | Opens on a schedule | Timing, speed, or Fracture | Schedules are learnable and displayed |
| **Bulkhead** | A blast door that slams shut across the route | Be through the gap when it closes | The door is the antagonist's offence, so the player runs *away* from the system |
| **Purge protocol** | A sector floods with hazards after an intruder is logged | Leave the sector, or find the vent it doesn't reach | Announced before it starts; never a surprise |
| **Interdiction node** | Stationary turret or snare-tendril guarding a bridge or shaft | Time the sweep, or go around | Always a route it doesn't watch |
| **Regulator drone** | Patrols a fixed line, rotating fan, contact damage | Filament-slap to reverse it, or slide under | Contact = brief stun, not death |
| **Wind regulator** | Large, anchored, emits a gust cone | Hit the valve; or exploit exhaust for speed | It blocks the route; there is always a speed line through it |
| **Pressure plate** | Triggers gates, alarms, collapse | Parcel sling; or overshoot via Fracture | Always two solutions |
| **Gap / updraft** | Environmental | Timing | Never a blind jump — always readable |
| **Grown seam** | The Concord's patched growth. Soft, warm, bleeds when scraped | It deforms, so it slows you differently | Acts like a hazard, reads like a wound |

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
The game separates **world** from **story**:

- The **world layer** (the city, the Concord, physics, mechanics, the 20×12
  section grid) is stable and shared.
- The **story layer** (Lancer's arc, NPC dialogue, major beats, endings) is
  **data-driven**: a `story/*.json` plus per-section beat scripts.

A community build (an "Edition") supplies an alternate `story/` directory. The
game loads it at boot and everything else stays put. An Edition can:
- rewrite dialogue, beat scripts and endings
- reuse the world and mechanics wholesale
- add or remove sections within the 12-per-chapter grid
- ship as a folder, a Git repo or a zip

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

**Practical notes on the copyleft**
- Shipping a build means shipping the source with it. The public repo plus the
  release tag satisfies GPL §3, so no separate source tarball is needed.
- No DRM, no activation, no always-online checks. GPL §0 and §1 forbid
  restricting the people who receive the game from running or sharing it.
- There's no proprietary-linking exception (that would be LGPL-style). If
  closed-source commercial games are wanted one day, that's a deliberate policy
  reversal rather than an oversight.
- "Other people have to open-source their version too" is enforceable for code
  under the GPL and for the assets and story they reuse under CC-BY-SA. A
  version written from scratch against the *idea* of WindShear, with no code
  and no assets, is legally their own. That's the intended outcome, not a
  loophole.

### Contribution surfaces
- Mechanic and level tutorials, in-game and in the repo
- Fracture discoveries: submit a name and a clip, the community votes, it goes
  in the Codex
- Translation. The string tables are already externalised
- Accessibility options
- Optimisations for low-end hardware
- **Editions**, which are the flagship community activity

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
- **Cell-based streaming.** Each section is a cell with its own resources. Cells
  unload with a 2-cell hysteresis so nothing thrashes. Unloading is explicit,
  not left to the GC.
- **Resource budgets per cell:** ≤ 45 MB textures, ≤ 20 MB meshes, ≤ 12 MB audio.
- **No runtime mesh generation** beyond tiny decals. All geometry is pre-baked.
- **Texture atlas discipline.** No more than 8 atlas pages resident per cell.
- **Pooled VFX and particles**, with no per-frame allocation in hot paths.
- **Object pooling** for regulators, parcels, damage numbers and pickups.
- **Fixed memory budgets at build time.** CI fails if a cell exceeds budget.
- **Reference hardware:** 8 GB RAM, a GTX 950 or integrated Vega 8, 4-core CPU.
  It has to run on 4 GB machines without swap.

### Low-poly PSX art direction
Vertex-coloured low-poly models, with no per-pixel textures where you can avoid
them. Affine-textured triangles on large surfaces, 15-colour ramps, heavy fog,
vertex-snapped geometry, dithered gradients.

---

## 13. Narrative delivery

- **No cutscene camera, ever.**
- **Ambient scenes.** Real time, and the player is free to leave. Most of the
  story is ambient.
- **Major beats.** Lancer freezes, world time stops, the scene plays in-frame
  and control resumes. Used around 8–12 times in the whole game.
- **The Concord "speaks"** through the world itself: maintenance bulletins
  painted on walls, PA announcements, schedule displays. Diegetic, no
  cutscenes.
- **Dialogue.** Short, in-frame, subtitled and skippable. There's no voice
  acting budget, so use stylised "tuner" chirps and text.
- **Endings.** Three of them, differing by Fracture state and final choice.

---

## 14. Roadmap

### Milestone 0 — "Does it feel good?" (2 weeks)
- Greybox runner: run/slide/jump/wall-kiss/filament.
- One 90-second test room, no art.
- **Gate:** 5 external testers say the movement is satisfying unprompted.

### Milestone 1 — Vertical slice (8 weeks)
- Chapter 1 sections 1.01–1.12, greybox → art.
- Core mechanics + 3 Fractures + Recall ghost + timer/splits.
- **Gate:** a 5-minute run feels like a toy people want to replay.

### Milestone 2 — Systems & content (12 weeks)
- All 20 chapters playable (greybox), all 12 Fractures implemented.
- Editions/story system, Fracture Codex, accessibility options.
- **Gate:** an external team ships an alternate storyline.

### Milestone 3 — Polish & ship (8 weeks)
- Art pass, audio, onboarding, menus, localization scaffolding.
- **Gate:** public release; community fork count > 0.

### Milestone 4 — Community era (ongoing)
- Edition index, community maps, seasonal Fracture events (new Fractures added,
  never removed).

---

## 15. Open questions

1. **The Concord's endgame.** Does Lancer destroy it, reform it or outrun it?
   The three endings cover the range of it, but the middle-act reveal still
   needs locking.
2. **Combat depth.** Is the drone and regulator combat enough, or do players
   need ranged options? The current answer is no guns and movement first.
   Revisit after Milestone 1.
3. **Fracture disclosure.** Ship with nothing documented, so it's a pure hunt,
   or seed one per chapter? I'd seed 3 and let the other 9 be found.
4. **Edition scope.** How much of the 20×12 grid can an Edition rewrite before it
   stops being WindShear?
5. **Wind in Chapter 1.** Introduce wind late, in Chapter 5, so it lands by
   contrast, or front-load it?

---

## Appendix A: section numbering standard

Sections are addressed as `chapter.section`, for example `2.07`. Splits,
saves, leaderboards, Edition scripts and community route files all use that ID.
Content inside a section is addressable as `chapter.section.beat` for major
beats, for example `13.03.FRACTURE`.

## Appendix B: Fracture registry policy

Fractures live in `data/fractures.json`. Each one carries an id, a name, a
version, a trigger description, an effect, a category (speed, precision or
routing) and `speedrun_legal`, which is true in Time runs and false in
Precision runs. A Fracture is **never removed** once it has shipped, only
added. Removing one is a breaking change to the community's routes.
