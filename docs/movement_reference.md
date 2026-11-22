# WindShear — Movement Reference

How the movement in WindShear is grounded, where each number came from, and
which of the things we found are ours on purpose and which ones we found by
playing.

This document is the companion to `TECH_SPEC.md` §3. The spec says what the
numbers *are*; this one says where they *come from*, and its the place to
look when somebody asks "why is the air cap 2.2 m/s?".

---

## 1. The method, and the one rule

Movement in this project was not invented from scratch and it was not copied
from one game either. Five sources were read — engine source where the engine
is open, community documentation where it is not — and their numbers were
compared against each other. Then the parts that survived the comparison were
written down in `TECH_SPEC.md` §3, implemented in `ws_tuning.gd`, and checked
frame by frame in `tests/test_movement.gd`.

The one rule that governs the whole thing:

> **A movement glitch is never implemented on purpose.**
>
> If a behaviour is a mechanic, it is in the spec, it has a name, it has a
> tuning constant, and it is tested. If a behaviour is a bug, it is a bug. We
> find it by playing, we characterise it with a test, we decide whether it is
> fun, and we either leave it or we put a ceiling on it. We do not build it
> on purpose and we do not put it in the design document as a feature.

That rule is why `docs/dev_stage_1.md` reads like a lab notebook and not like
a feature list.

### The two categories

| | **Borrowed** | **Emergent** |
| --- | --- | --- |
| Where it comes from | A mechanic in another game, understood well enough to re-implement | A consequence of the physics as written |
| In the spec? | Yes, with a name and a number | Sometimes, as a *constraint* rather than a feature |
| In the tests? | Asserted as intended behaviour | Asserted as an invariant, or watched for change |
| Can it be relied on? | Yes | No — it is a side effect and may change with any tuning change |

The classic examples of the second column are bunny hopping and strafe
jumping. Both exist in the sources below. Neither is in `TECH_SPEC.md` §3 as
a mechanic, and both are *promised not to be a speed exploit* in
`tests/test_movement_discovery.gd`.

---

## 2. The sources

| Source | What was read | License of the source material |
| --- | --- | --- |
| Quake (1996) | `WinQuake/sv_user.c`, the actual server movement code | GPL (id Software released it under the GPL in 1999) |
| Quake II (1997) | `game/qcommon/pmove.c`, the client movement code | GPL |
| Half-Life / GoldSrc (1998) | The movement values Valve ships as engine defaults, cross-checked against the SDK | SDK is public; the engine is closed source |
| Doom (1993) | The movement bible, derived from the original source | The engine source was never released |
| ULTRAKILL (2017) | The community wiki's measurement pages | Documentation |
| GRACE (2024, Roblox) | The community wiki and speedrunner guides | Documentation |

---

## 3. Quake — the source of the whole family

Quake's movement code is four functions in one file, and everything the
GoldSrc family does is a variation on it. From
[`WinQuake/sv_user.c`](https://github.com/id-Software/Quake/blob/master/WinQuake/sv_user.c):

```c
cvar_t	sv_maxspeed = {"sv_maxspeed", "320", false, true};
cvar_t	sv_accelerate = {"sv_accelerate", "10"};
```

**Friction** (`SV_UserFriction`) is not a constant deceleration. It scales
with speed, but with a floor:

```c
control = speed < sv_stopspeed.value ? sv_stopspeed.value : speed;
newspeed = speed - host_frametime*control*friction;
```

Below the stop speed, the deceleration is *constant*; above it, it is
*proportional*. That is why a Quake player sliding to a halt decelerates
hard at first and then coasts, and why the sensation of "setting up a slide"
exists at all.

**Ground acceleration** (`SV_Accelerate`) accelerates along the *wish
direction* only, and only up to the wish speed:

```c
currentspeed = DotProduct (velocity, wishdir);
addspeed = wishspeed - currentspeed;
if (addspeed <= 0)
    return;
accelspeed = sv_accelerate.value*host_frametime*wishspeed;
if (accelspeed > addspeed)
    accelspeed = addspeed;
```

This is the key to everything: if the component of your velocity along the
direction you are holding already exceeds what you asked for, you get
nothing. Turning while running therefore costs you speed, and the famous
acceleration tricks come from finding an angle where the projection stays
below the wish speed.

**Air acceleration** (`SV_AirAccelerate`) is the same idea with one
crucial difference:

```c
wishspd = VectorNormalize (wishveloc);
if (wishspd > 30)
    wishspd = 30;
```

The wish speed is clamped to 30 units. This is the famous "air strafe
cap", and it is the entire reason a player can gain speed by turning in the
air: the cap is so low that the *projection* of your velocity onto the wish
direction falls below it, so the engine keeps adding, and the added vector
is not aligned with your current velocity, so your total speed grows. No
friction is applied in the air at all.

### What WindShear takes from Quake

- **Acceleration along the wish direction only.** Not "accelerate towards the
  input vector at a fixed rate". It is why turning has a cost.
- **No air friction.** Air control is the only thing that changes your
  velocity in the air.
- **A hard air cap.** WindShear's air acceleration contributes at most
  2.2 m/s over the whole jump (see §4).

### What WindShear does not take from Quake

- **The strafe-jump exploit itself.** The physics above *permits* it. We did
  not add anything to make it work, and the test suite asserts that bunny
  hopping does not become a speed exploit (§7).

---

## 4. The numbers, and why they are what they are

Quake's units are inches — about 39.37 units to the metre. Our numbers are
in metres per second, so the conversion matters, and the comparison is not
one-to-one.

| WindShear | Value | Where the shape comes from |
| --- | --- | --- |
| Run speed | 14.0 m/s | Chosen to sit near Quake's 320 units/s (8.13 m/s) but faster, because WindShear is a platformer and the camera is on the character |
| Ground accel | 90 m/s² | Quake's `sv_accelerate` is 10 units/frame² at the engine's frame rate — an acceleration constant with a very different unit |
| Ground decel | 60 m/s² | The friction floor idea from `SV_UserFriction`, expressed as a plain deceleration |
| Air accel | 32 m/s², capped at 2.2 m/s total | Quake's air wish-speed clamp of 30 units, expressed as a budget over the whole airtime rather than a per-frame clamp |
| Jump | 15.5 m/s, gravity 60 m/s² | Apex ≈ 2.0 m, which is about two and a half body heights. Quake's 45-unit jump is 1.14 m; ULTRAKILL is a platformer, not a shooter |
| Coyote time | 8 frames | Not from any source. It is a forgiveness window, and 133 ms is the number that stopped feeling like a bug |
| Jump buffer | 10 frames | Same, 166 ms |
| Slide | 0.45 s, friction 6 | ULTRAKILL's slide is 24 units/s with no acceleration while sliding; ours is a short burst that can be cancelled into a jump |
| Wall-kiss | 2-frame window, +0.8 m/s, chain of 5 | GRACE's two wall-kicks before touching the ground, made a *chain* instead, with a ceiling |

### The air cap, in more detail

Quake clamps the *wish speed* to 30 units per frame. We clamp the
*contribution* to 2.2 m/s over the entire time spent in the air. The two are
not the same shape, but they do the same job: they put a hard number on how
much a jump can add, and they make the answer "a little bit", which is what
air control should feel like.

The consequence is that the air cap is a *budget*, not a rate. Once it is
spent, further air input does nothing until the player lands. That is a
deliberate choice — it makes the cap legible. A player who holds a direction
through a long fall does not get a surprise speed gain, and the tests can
assert an exact number instead of a range.

---

## 5. Quake II — the game that removed the exploit on purpose

Quake II's `pmove.c` is the same shape as Quake's, with two numbers changed
and one feature deleted:

| | Quake | Quake II |
| --- | --- | --- |
| Max speed | 320 | **300** (`qcommon/pmove.c:54`) |
| Friction | 4 | **6** (`qcommon/pmove.c:59`) |
| Air acceleration | 10 | **0 by default** |

Quake II shipped with `pm_airaccelerate` defaulted to zero. There is no air
control in Quake II, and therefore no strafe jumping and no bunny hopping.
Players noticed, and id added the cvar back in a patch, but the default
stayed at zero for a long time.

This is the most useful single data point in the whole reference, because it
shows that **the industry deliberately removed a movement exploit rather
than living with it** — while keeping the same underlying movement code.

WindShear takes the lesson and not the number: we keep the air cap small
enough that the classic exploits have no room, and we say so in the tests.

> Quake II's air acceleration default of 0 is the historical precedent for
> the rule in §1. A movement glitch is not a feature. It is either
> prevented, capped, or left alone.

---

## 6. Half-Life / GoldSrc — the engine that tried to kill bunny hopping

Half-Life's engine is closed source, so the movement values are the
well-known engine defaults rather than something read out of a file:

| Setting | Value |
| --- | --- |
| `sv_maxspeed` | 320 |
| `sv_accelerate` | 10 |
| `sv_airaccelerate` | 10 |
| `sv_friction` | 4 |
| `sv_stopspeed` | 100 |
| Air wish-speed cap | 30 units |

These are the same values as Quake, which is not a coincidence: GoldSrc
inherited Quake's movement code.

What is interesting is what Valve did next. The Half-Life SDK contains a
function called `PM_PreventMegaBunnyJumping`, which crops the player's
velocity once it passes 1.7× the maximum speed:

```c
fraction = (maxscaledspeed / spd) * 0.65;
VectorScale (pmove->velocity, fraction, pmove->velocity);
```

Half-Life *actively punishes* bunny hopping. The physics allowed it, and
the engine noticed and took the speed away.

This is the direct ancestor of WindShear's wall-kiss ceiling, and it is
worth being explicit about the difference. GoldSrc's crop is a blunt
instrument: it scales the whole velocity vector down by 65%, which throws
away height as well as speed. Our wall-kiss ceiling clamps the *horizontal*
speed to a fixed number and leaves the vertical motion alone, which is more
forgiving and, in our opinion, reads better.

Source: [SUCC — How accurate are the presets?](https://bearlikelion.github.io/SUCC/explanation/engine-accuracy/)
and the [KZ-Guide on bunnyhopping](https://kzguide.gitlab.io/techniques/bunnyhop/).

### The floaty lesson

Source (Half-Life 2) lowered gravity from 800 to 600 and hardcoded the jump
impulse at 160, which is why it feels floatier than Half-Life. We did not
copy the floatiness — WindShear is a platformer and needs predictable jump
heights — but the observation is that gravity is the single strongest lever
on how a movement feels, and it is the first thing to change when a section
feels wrong.

---

## 7. Doom — no air control, and a strafe-run that is honest

Doom (1993) had no jumping and no air control at all. Its movement, from
the [Doom Movement Bible](https://www.doomworld.com/forum/topic/87199-the-doom-movement-bible/):

- Thrust of 0.03125 units per command, per tic.
- Friction of 0.90625 per tic, applied at 35 Hz.
- A top run speed of about 16.7 units per tic.
- A hard cap of 30 units per tic.
- **No air control**, because there is no air.

The interesting number is the strafe-run: holding forward and a strafe
together gives a speed of √(50² + 40²) ≈ 64 units per tic, about 1.28× the
straight-line run speed. That is a *large* gain, and it was entirely
legitimate — the game told you to run diagonally.

Doom's lesson is that a movement system can have a satisfying speed
exploitation built into it as a plain, visible consequence of the physics,
with no special case in the code. The player holds two keys and goes
faster. There is no hidden mechanic to learn, and no exploit to patch.

Modern Doom (2016) and Doom 3 added air control. Doom 3 in particular was
notorious for how little it gave you in the air.

### What WindShear takes from Doom

- **Diagonal movement should be genuinely faster.** It is, and it is a
  consequence of the numbers rather than a special case.
- **The air cap should be a number the player can feel.** 2.2 m/s over a
  jump is about a fifth of the run speed, which is enough to correct a line
  and not enough to replace running.

---

## 8. ULTRAKILL — the platformer that made air control a resource

ULTRAKILL is the closest of the sources to what WindShear actually is: a
first-person movement game where the camera is the character and the
movement is the content. From the
[ULTRAKILL movement wiki](https://ultrakill.wiki.gg/wiki/Movement):

| Mechanic | Value |
| --- | --- |
| Dash | 49.5 units/s, costs 1 stamina |
| Dash-jump | Costs 2 stamina |
| Stamina | 3 maximum, recharges over time, does not recharge while sliding |
| Slide | 24 units/s, zero acceleration while sliding |
| Slideways | 5 units/s sideways while sliding |
| Top slide speed | 72–77 units/s |
| Wall jump | Up to 3 in a row |
| Wall cling | Falls at up to 100 units/s |
| Air control | Yes |

Two ideas here are worth stealing.

**The stamina budget.** Every air move costs something, and the resource
refills on a timer. It turns "hold the jump button" into a decision.

**Sliding at a fixed speed.** A slide does not accelerate you; it puts you
at a speed and holds you there, with a small sideways allowance. That makes
the slide a *precision* tool — a way to hold a line through a corridor —
rather than a speed tool.

WindShear does not have stamina. It has a **frame budget** instead, and it
is the same idea wearing different clothes: the wall-kiss window is 2
frames, the chain is 5 kisses, the chain expires after 30 frames without a
kiss. You cannot hold the button; you have to press it at the right moment.
The budget is in frames, not in a meter, because frames are what a
speedrunner's route is made of.

---

## 9. GRACE — the game that proves momentum chains are a design

GRACE is a first-person horror speedrun game on Roblox by The Fartering
Few: procedurally generated corridors, a timer, and a movement system built
entirely out of momentum. Its
[community wiki](https://grace.miraheze.org/wiki/Mechanics) lists the
mechanics, and the speedrunner guides are the interesting part, because
they are a list of things players *found*.

The basic mechanics:

- **Sprint** to go faster.
- **Slide** by sprinting and crouching; slides build momentum down stairs.
- **Wall-kick** by jumping against a wall in the air. Two kicks before you
  must touch the ground again.

The techniques players found on top of that:

- **Power slide** — slide, then *release* the sprint key. Releasing sprint
  removes the internal slide speed cap, and the slide suddenly keeps much
  more speed. This is not a feature in the code. It is the absence of a
  clamp, and the whole community found it.
- **Trimping / crimping** — power slide into a lip or a stair corner and
  jump as you wedge. Horizontal velocity becomes vertical launch.
- **Darting** — wall-kick while falling fast, and the game converts your
  vertical velocity into horizontal velocity. You go forwards like a dart.
- **B-hopping** — jump the instant you land, to keep the momentum and reset
  your wall-kicks.
- **Corner clipping** — align flat in a corner and wall-jump while sliding.
  Inconsistent, requires luck, and gives an immense amount of speed.

### What WindShear takes from GRACE

- **A wall-kick is a budgeted, directional thing.** Two kicks in GRACE, five
  kisses in WindShear, and in both cases you have to land to get them back.
- **Wall-kicks give a small, predictable amount of speed.** GRACE's
  wall-kick boost is "small"; ours is a fixed +0.8 m/s per kiss with a
  ceiling on the chain.
- **The hard ceiling.** GRACE does not have one, which is why the
  community's fastest lines are the ones that clip corners. We do.

### What WindShear does not take from GRACE

- **The velocity conversion.** GRACE converts falling speed into forward
  speed on a wall-kick. It is spectacular and it is exactly the kind of
  thing that turns a speed game into a geometry puzzle. WindShear's
  wall-kiss adds a flat amount, so it rewards timing rather than geometry.
- **The power slide.** The slide in WindShear has a fixed duration and a
  fixed friction. A speed cap that disappears when you let go of a key is a
  beautiful mechanic and it is also a mechanic whose entire skill
  expression is "notice the cap is gone". We keep the slide legible.

---

## 10. The summary table

| Mechanic | Quake | GoldSrc | Quake II | Doom | ULTRAKILL | GRACE | WindShear |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Air control | Yes, wish speed capped at 30 | Yes, capped at 30 | **No** (default 0) | No | Yes | Yes | Yes, capped at 2.2 m/s total |
| Friction | Proportional above a stop speed | Same | Proportional, friction 6 | 0.90625/tic | Slide has none | Slide has a cap | Ground decel 60 m/s² |
| Strafe-run gain | Large | Large | Small (no air) | ~1.28× | n/a | Yes | Present, not tuned for gain |
| Bunny hop | Permitted, no ceiling | **Explicitly punished** | Impossible by default | Impossible | Possible | Possible | **Asserted not to be an exploit** |
| Wall move | No | No | No | No | 3 wall jumps, wall cling | 2 wall kicks, velocity conversion | 5-kiss chain, +0.8 each, 18 m/s ceiling |
| Slide | No | No | No | No | 24 u/s fixed, no accel | Sprint+crouch, power slide variant | 0.45 s, friction 6, cancels into jump |
| Forgiveness | None | None | None | None | Stamina | Traits | Coyote 8f, buffer 10f |

---

## 11. The rules this produced

1. **The air cap is a budget, not a rate.** 2.2 m/s over the whole airtime.
2. **The wall-kiss chain is capped at 5 kisses and 18.0 m/s.** The ceiling
   was not in the original spec — it was found by the discovery harness and
   added afterwards. See `docs/dev_stage_1.md` §4.
3. **The ground acceleration follows Quake's shape.** Accelerating along the
   wish direction means turning costs speed, and a player can feel the
   difference between a wide turn and a tight one.
4. **Every forgiveness window is a number in the spec.** No "feels about
   right" values.
5. **Bunny hopping is not a speed exploit.** Asserted, not hoped for.

---

## 12. Sources

- Quake server movement — <https://github.com/id-Software/Quake/blob/master/WinQuake/sv_user.c>
- Quake II client movement — <https://github.com/id-Software/Quake-II/blob/master/game/qcommon/pmove.c>
- SUCC, engine accuracy — <https://bearlikelion.github.io/SUCC/explanation/engine-accuracy/>
- SUCC, preset values — <https://bearlikelion.github.io/SUCC/reference/presets/>
- Half-Life strafe physics — <https://kz-rush.ru/en/page/strafe-physics>
- KZ-Guide, bunnyhopping — <https://kzguide.gitlab.io/techniques/bunnyhop/>
- The Doom Movement Bible — <https://www.doomworld.com/forum/topic/87199-the-doom-movement-bible/>
- ULTRAKILL movement — <https://ultrakill.wiki.gg/wiki/Movement>
- GRACE mechanics — <https://grace.miraheze.org/wiki/Mechanics>
- GRACE speedrunning guide — <https://www.speedrun.com/grace/guides/2mn2y>
