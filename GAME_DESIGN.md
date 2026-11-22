# WINDSHEAR — Game Design Document

> A cinematic 2.5D speed-and-precision platformer. Free and open source, built so
> the community can tell its own stories inside the same world.

**One-line pitch:** *The city regulates the wind so the storms can't kill you —
and Lancer is going to set the sky free anyway.*

---

## 0. Design pillars

1. **Speed × precision.** Every section is a time trial you can learn by heart.
   The game is about flow: momentum, route knowledge, frame-tight execution.
2. **The world is a machine, not a monster.** The antagonist is human-made: a
   civic operating system called **The Concord**. It cages the world to prevent
   catastrophe. That argument *is* the game's main point.
3. **The main character is Lancer** — and the player frees the world from
   regulation, not from an invasion.
4. **Cinematic 2.5D, camera discipline.** The camera never leaves Lancer. Cutscenes
   happen in the world, not in a separate film.
5. **Shallow depth, hyper depth of world.** PSX-era low-poly 3D rendered at 480×270,
   staged like a diorama: parallax, fog, layered light, big silhouettes.
6. **Fractures are real.** The Concord's simulation has cracks. Some are shipped
   on purpose so hyper-competent players can find, name and exploit them.
7. **Free, open, forkable.** The whole game — code, assets, level format — is
   open source, and alternative storylines are first-class content, not mods of
   an SDK.

---

## 1. The world: the Concord

Not aliens. Not nature. A **human civic system** that has been running itself
for twenty years.

Twenty years ago the **Fracture Year** hit: regulation collapsed, the wind
became ungovernable, and the city tore itself apart. The survivors built the
**Concord** — a distributed civic operating system that now regulates the sky:
wind direction, pressure, thermals, and the geometry of the city itself. Gates
open on schedules. Air moves only where the Concord permits.

**Lancer** is a Runner: a courier licensed to move inside the cage, paid to
carry what the Concord allows. Lancer breaks the law by carrying what it
doesn't.

### What the Concord actually is

It started as software, and it is still software at the top — a scheduling
system with a maintenance voice and no face. Twenty years of self-repair left
marks on the hardware it runs on.

Where a seam tore, the Concord grew a patch. Where a vent froze, it grew a
collar. The growth isn't alive. It doesn't want anything. It just keeps closing
the gap the way a wound keeps closing, and after long enough the original
structure is more scaffold than wall. Lancer calls it the patched thing. The
Concord's own logs call it *continued maintenance*.

Down in the spine basement you can see it: seams that run warm, surfaces that
bleed when you scrape them, a soft edge where a blast door used to meet
concrete. It's the ugliest thing in the game and it's still, technically, a
building inspector's note.

### The blocks

The city is cut into **quarantine blocks** — sealed districts closed after the
Fracture Year so no two of them could ever coordinate a second one. People live
inside them. The Concord feeds them, schedules their gates, and forbids anyone
crossing a sector line with anything the schedule doesn't list.

There are whole blocks the outside world has stopped counting.

### Why it hunts Lancer

Not for being fast. The Concord doesn't care how fast a body is. It cares that
Lancer is a courier moving physical things between places that are not allowed
to know about each other.

A war wound, reconnecting isolated populations, looks exactly like a command
network forming. That is the shape of the threat it was built to stop, and
that is the shape Lancer keeps accidentally being.

Its defenses reflect what it expects. Chokepoints, blast doors, sensor grids,
bio-constructs that patrol lines — all of it is built against someone sneaking
slowly or blowing a wall open. Nothing in the system was designed for someone
who crosses at fourteen metres a second because the route gives them no
choice.

### The dilemma (the main point)
Freeing the world means free wind — and free wind means the Fracture Year can
happen again. The Concord isn't evil; it's a scar-shaped bureaucracy built by
survivors. The game never answers whether regulation is right. It asks who gets
to decide, and shows that both sides have killed people.

### Cast (all non-gendered, including Lancer)
- **Lancer** — Runner, 20s–30s, androgynous on screen and in text. No gender is
  specified anywhere: no pronouns in dialogue, no gendered voice direction, and
  the character creator lets players set a name and body without a gender field.
  Lancer's arc is about learning to move without permission.
- **THE CONCORD** — the system itself. It speaks in maintenance prose and
  scheduling bulletins; it is never a face.
- **Warden Saye** — Concord enforcement. Believes the cage is mercy. Not a
  tyrant; a person who signed the order that closed the city.
- **Ilsa Renn** — a smuggler who taught Lancer to run. Alive, complicit,
  recurring.
- **FIRST RUNNER** — the name the Concord gives to whoever caused the Fracture
  Year. Late twist: the first Runner was Lancer's mentor, and the Concord has
  been running Lancer's own training data for twenty years.

### Endings (3)
- **OPEN WEATHER** — Lancer breaks the sky regulation. The city breathes. Storms
  return, and so do deaths. Free.
- **UNDER REGULATION** — Lancer restores the Concord. Safety returns; the game
  ends with Lancer running laps of a perfect, joyless route.
- **THE SECOND FRACTURE** (hidden, requires Fracture routes) — Lancer doesn't
  choose; they make the world *unregulatable* by exploiting every Fracture at
  once, and the Concord survives as a ruin. Requires all 12 Fractures.

---

## 2. Movement model (the core)

**Plane:** gameplay on X/Y, with Z used for parallax staging, rails and
background layers. Speed reads of the X axis, precision off Y.

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

- **Slide-hop** — jump at slide end. The bread-and-butter combo.
- **Wall-kiss** — hit a wall while sliding, jump on the same frame as contact.
  +0.8 m/s per kiss, capped at 5.
- **Zip** — filament to a *zip anchor* (a taut cable along the route): instant
  launch along the anchor line, preserves your speed through the transition.
- **Overdrive** — carrying an Overcharge Cell; 12 s of +18% speed, timer visible.
- **Thread** — passing through a gap whose clearance is under 0.8 m without
  touching it. +style, +speed on exit.
- **Fracture dash** — the deliberate bugs (§4).

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

Style points: slide chains, wall-kiss chains, thread bonus, no-touch bonus,
air time, "flow" multiplier for chaining without touching ground. Style is a
*secondary* objective so that speedrunners don't have to choose between fast and
cool — but precision runs ban style to keep the two ladders honest.

---

## 4. Fractures: the deliberate bugs

The Concord's simulation is old and patched. It has **cracks**, and some of them
are shipped on purpose by the developers. Finding, naming, and exploiting them
is a legitimate mastery path — and the game treats it as a feature.

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

The twelve are spread across twenty chapters, and no two sit in the same act.
This is a guide, not a promise — a player is meant to find most of them by
breaking the game rather than by reading a list.

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
- **Intentional, not accidental.** Each is deliberately implemented, documented
  internally, and kept stable across versions (versioned in a `fractures.json`).
- **Never mandatory.** Every Fracture route is skippable by a slower line, so
  the base game is complete without them. Fractures are *optional mastery*.
- **Never crash the game.** They must not soft-lock; they are guarded.
- **Discoverable but not advertised.** The game ships with a **Fracture Codex**
  that starts empty. Players can submit names + proof clips; the community
  votes; accepted Fractures get documented in-game *and* in the open repo.
- **Speedrun-safe.** Fractures are legal in Time runs, banned in Precision runs.
- **Version-stable.** A Fracture that gets "fixed" would be a nerf to the
  community. The policy: never remove a Fracture; only add new ones.

---

## 5. 2.5D and the camera

### Staging
Gameplay is planar; the world is built in full 3D for depth. Rendering:
low-poly PSX-style models, internal resolution **480×270** upscaled with
nearest-neighbour, vertex snapping, flat-ish lighting, heavy use of fog and
silhouette. Hyper depth comes from **layered parallax**: foreground occluders,
play plane, mid-ground architecture, distant city shell, skybox, all with
distinct fog densities.

### The camera never leaves Lancer — hard rule
- No cutscene cameras. Ever. No dolly-to-face, no over-the-shoulder cinematic,
  no letterbox cutaways.
- Cutscenes are **diegetic in the play space**: characters walk into frame,
  conversations happen with the player in control, props animate in view.
- Camera behaviour is constant: a 2.5D perspective rig locked to Lancer's
  plane, with speed-based FOV and distance pull-back. It never detaches, never
  cuts, never goes first-person.

### Two kinds of cutscene
| Kind | Player input | World | Used for |
| --- | --- | --- | --- |
| **Ambient / minor** | **Unrestricted.** The player can walk away mid-scene. | Runs in real time. | Barks, overheard conversations, optional story, world texture |
| **Major beat** | **Locked.** Lancer freezes, input ignored. | **Time stops** — the world freezes, the scene plays over it, then time resumes | Chapter transitions, the Concord's bulletins, reveals, endings |

The freeze is literal and readable: time scale drops to 0 for everything except
the scripted actors and VFX, the frame desaturates and the wind sound drops out,
and a subtle scanline crawl marks "the Concord is speaking." After the beat,
control returns on a 2-frame count.

Why this matters: Lancer never feels *acted upon*. The player is always the
protagonist, even when the game stops to talk.

---

## 6. Chapter structure: twenty chapters of twelve sections

Every chapter is **12 numbered sections**. The numbering is a first-class
organizing device — for saves, leaderboards, speedrun splits, modding, and
community routes.

```
1.01  1.02  1.03  ...  1.12
2.01  2.02  ...        2.12
...
20.01 20.02 ...        20.12
```

The game is **Chapter → Section → Beat**. Sections are 30–180 seconds. A
chapter is 12–20 minutes. Twenty chapters ≈ **four and a half hours** of
first-run content — long enough to master, short enough to finish in a week of
evenings.

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

HL2's trick: you are never more than ~40 seconds from a landmark you saw
earlier, and the world is continuous and legible. WindShear copies that feeling
without the sprawl.

**How:**
- **Landmarks** — the Spire is visible from Chapter 1. Every chapter has 3–4
  permanent visual anchors visible from other chapters.
- **Continuous chapters** — no loading screens between sections; sections are
  streaming cells within a live chapter.
- **Loops** — each chapter contains at least one fast-return loop, so mastery
  means learning a circuit, not a corridor.
- **Vertical sightlines** — look down and you see the layer below; the Spire
  rises through Chapters 5, 9, 17 and 19.
- **The Quiet Line** — a high-speed transit spine (capsules, ziplines) crosses
  chapters 9–12; it doubles as a shortcut system and a speedrun line.

**How it is *not* open world:**
- Every section is a hand-authored cell. No procedural sprawl.
- The world is ~4.5 hours of unique content, not 15.
- Freedom is in *how* you traverse a section, not in *where* the world goes.
- The Concord's schedule means some routes are only open at certain times —
  the world changes without being open.

---

## 8. Mechanics beyond wind

The user brief: wind is one mechanic, not the whole game. Full mechanic roster:

### Movement (always available)
- Run / slide / jump / wall-kiss / mantle / air control / ledge grab.
- **The Filament**: a tether to 3 anchor types — *zip anchors* (launch along a
  fixed line), *ring anchors* (swing), *hold anchors* (hang + climb). Aim is
  precision (0.25 s lock-on), use is speed.

### Wind (signature, not universal)
- **Thermals**: updrafts. Hold direction to climb; exit timing is pure precision.
- **Crosswinds**: lateral push, readable from particle direction and cloth.
- **Regulation fields**: Concord zones that *cancel* wind — movement is normal,
  which makes them eerie and slow.
- **Wind regulators**: the Concord's machines. Kill them to kill the wind in a
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
The world remembers your last 12 seconds and renders it as a translucent double.
You can race it. It's a learning aid, a ghost, and a competitive device — all one
system. On death, Recall becomes your respawn: you re-enter the world as your
ghost and have a few seconds of overlap before you diverge.

---

## 9. The 2.5D camera in practice

Camera is a **constrained 3D rig locked to the play plane** — a side-on
2.5D view, but with full 3D scene depth behind it.

- Follows Lancer with **velocity lookahead** (leads in the direction of travel).
- **Speed dolly**: pulls back and widens FOV as speed rises — the single most
  important camera tool for making speed *feel* fast.
- **Air framing**: tilts down slightly on long falls, up on launches.
- **Verticality**: keeps the horizon stable, so a 40 m drop reads as vertical.
- **Never cuts, never detaches, never goes first-person** — always contains
  Lancer, with headroom for the jump arc.
- **Time-stop beats**: the camera *locks* to Lancer's last position; the world
  stops but the framing stays composed, because the camera is Lancer's, not the
  director's.

---

## 10. Enemies and hazards

The Concord does not fight Lancer. It denies her the ground, one room at a
time. Everything below is area denial: the level closes, the route changes,
and the run becomes a question of where you were going to be in two seconds.

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
section and nothing else. By Act VI a section carries four, on three different
cycles, and the slowest one guards the good route. The player learns to read
two or three schedules at once, and the speedrun line is the one that assumes
they can.

**No instant-death.** Hazards reset you to the last checkpoint with a fast
respawn (< 1.2 s) and no loading. Death is cheap; flow is protected.

---

## 11. Open source, community storylines

**The user brief:** free and open source, so the community can build versions of
the game with different storylines — *not* an SDK.

### Position
WindShear is a **complete, playable game** that is open source. Not a toolset
with an example project; the whole thing — engine code, levels, art, audio, the
official story — is in the repo, and anyone can change the story without asking.

### How alternative storylines work
The game separates **world** from **story**:

- **World layer** (the city, the Concord, physics, mechanics, the 20×12 section
  grid) is stable and shared.
- **Story layer** (Lancer's arc, NPC dialogue, major beats, endings) is
  **data-driven**, defined in a `story/*.json` + per-section beat scripts.

A community build ("Edition") supplies an alternate `story/` directory. The game
loads it at boot; everything else stays. Editions can:
- rewrite dialogue, beat scripts, and endings
- reuse the world and mechanics wholesale
- add or remove sections within the 12-per-chapter grid
- ship as a single folder, a Git repo, or a zip

Distribution: **Edition browser** inside the game scans `user://editions/` plus
a configurable community index URL. No account, no DRM, no closed launcher.

### Licensing
| Asset class | License | Rationale |
| --- | --- | --- |
| Game code | **GPL-2.0-or-later** | Copyleft on the code is what guarantees a community version can't be a black box: anything built on it has to ship its source under the same terms. Godot is MIT, so the combination is compatible. |
| Game content (levels, models, audio, art) | **CC-BY-SA 4.0** | Anyone can reuse the assets in their own game, commercial included; anything derived from those assets has to be shared alike. |
| Official story layer | **CC-BY-SA 4.0** | Alternate storylines inherit share-alike, so the commons of story beats keeps growing instead of being hoarded. |
| Community Editions | **Must be open source** and GPL-CC-compatible to be published to the official index | The index validates the declared license. Code in an Edition is GPL by inheritance; pure-data Editions are bound by the share-alike on the story assets they reuse. |
| Trademarks ("WINDSHEAR", "The Concord") | Not licensed; nominative use allowed | Don't let forks become official |

The game is **free forever**. No monetization, no ads, no telemetry. Optional
donation link only.

**Practical notes on the copyleft**
- Shipping a build means shipping the corresponding source: the public repo plus
  the release tag satisfies GPL §3. No separate source tarball required.
- No DRM, no activation, no always-online checks — GPL §0/§1 forbid restricting
  the people who receive the game from running or sharing it.
- No proprietary-linking exception is granted (that would be LGPL-style). If
  closed-source commercial games are ever wanted, that's a deliberate policy
  reversal, not an oversight.
- "Other people have to open-source their version too" is enforceable for code
  (GPL) and for the assets/story they reuse (CC-BY-SA). A version written from
  scratch against the *idea* of WindShear, with no code and no assets, is
  legally their own — that's the intended outcome, not a loophole.

### Contribution surfaces
- Mechanic/level tutorials (in-game, open repo)
- Fracture discoveries (submit name + clip → community vote → in-game Codex)
- Translation (full string tables externalized)
- Accessibility options
- Optimizations for low-end hardware
- **Editions** — the flagship community activity

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
  unload with a 2-cell hysteresis (no thrash). Unload is explicit, not GC-luck.
- **Resource budgets per cell:** ≤ 45 MB textures, ≤ 20 MB meshes, ≤ 12 MB audio.
- **No runtime mesh generation** beyond tiny decals — all geometry pre-baked.
- **Texture atlas discipline** — no more than 8 atlas pages resident per cell.
- **Pooled VFX/particles**; no per-frame allocation in hot paths.
- **Object pooling** for regulators, parcels, damage numbers, pickups.
- **Fixed memory budgets at build time** — CI fails if a cell exceeds budget.
- **Reference hardware:** 8 GB RAM, GTX 950 / integrated Vega 8, 4-core CPU.
  Must run on 4 GB machines without swap.

### Low-poly PSX art direction
Vertex-coloured low-poly models (no per-pixel textures where avoidable),
affine-textured triangles for large surfaces, 15-colour ramps, heavy fog,
vertex-snapped geometry, dithered gradients.

---

## 13. Narrative delivery

- **No cutscene camera, ever.**
- **Ambient scenes**: real time, player free to leave. Most story is ambient.
- **Major beats**: Lancer freezes, world time stops, scene plays in-frame, then
  control resumes. Used ~8–12 times in the whole game.
- **The Concord "speaks"** via in-world surfaces: maintenance bulletins painted
  on walls, spoken PA announcements, schedule displays. Diegetic, no cutscenes.
- **Dialogue**: short, in-frame, subtitled, skippable. No voice acting budget —
  use stylised "tuner" chirps and text.
- **Endings**: three, differing by Fracture state and final choice.

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

1. **The Concord's endgame** — does Lancer destroy it, reform it, or outrun it?
   Three endings cover this; need to lock the middle-act reveal.
2. **Combat depth** — is the drone/regulator combat enough, or do players need
   ranged options? Current answer: no guns, keep it movement-first. Revisit after
   Milestone 1.
3. **Fracture disclosure** — ship with zero documented Fractures (pure hunt), or
   seed one per chapter? Recommend: seed 3, discover 9.
4. **Edition scope** — how much of the 20×12 grid can an Edition rewrite before it
   stops being WindShear?
5. **Wind in Chapter 1** — introduce wind late (Chapter 5) for contrast, or
   front-load it?

---

## Appendix A — Section numbering standard

Sections are addressed as `chapter.section` (e.g. `2.07`). Splits, saves,
leaderboards, Edition scripts, and community route files all use this ID.
Content within a section is addressable as `chapter.section.beat` for major
beats (`13.03.FRACTURE`).

## Appendix B — Fracture registry policy

Fractures live in `data/fractures.json`, each with: id, name, version,
trigger description, effect, category (speed/precision/routing), and
`speedrun_legal` (true in Time, false in Precision). Fractures are **never
removed** once shipped — only added. A removed Fracture is a breaking change to
the community's routes.
