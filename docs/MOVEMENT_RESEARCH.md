# WindShear — Movement Mechanics Research

**Research snapshot:** 2026-11-22
**Status:** canonical reference for WindShear's movement design
**Scope:** Half-Life/Source, Quake 1/2/3 and QuakeWorld, Challenge ProMode Arena, Doom (1993), Doom 3, Doom (2016), Roblox GRACE, and ULTRAKILL

This document records what the source material actually does, what is only
reported by the community, and which parts are appropriate for WindShear.
It is not a claim that every engine in this family behaves identically.

The governing design rule remains:

> **A movement technique may be an intended mechanic or an accidental
> consequence. An accidental consequence is characterized, bounded if
> necessary, and never deliberately reproduced as a hidden speed button.**

WindShear's locked values live in [`TECH_SPEC.md`](../TECH_SPEC.md) and
[`ws_tuning.gd`](../addons/windshear/core/ws_tuning.gd). This document explains
their provenance and boundaries.

---

## 1. Evidence policy

Movement folklore is unusually good at turning a projection limit into a
speed limit, a per-tic impulse into a top speed, and a community measurement
into engine source. The labels below are therefore part of the result, and
not decoration.

| Label | Meaning | Example |
| --- | --- | --- |
| **[S] Source-verified** | Read directly from released engine or game source at the pinned revision linked below | Quake's 30-unit projection cap |
| **[O] Official** | Stated by an official product page, executable/cvar dump, or developer patch note | ULTRAKILL's *Fraud Hotfix #2* notes |
| **[C] Community / secondary** | Community wiki, guide, measurement, or reverse-engineering report; useful but not authoritative source | GRACE wall-kick counts |
| **[D] Unofficial decompilation** | A decompiled binary snapshot; not original developer source | ULTRAKILL's `ssjMaxFrames` field |
| **[Calc] Computed here** | Arithmetic derived from cited values; not a separately measured in-game result | A one-tick Source speed example |

“Unverified” below means that no released source or official statement was
found for the claim. It does not mean the claim is false.

### 1.1 Units are not interchangeable

- Quake, GoldSrc, and Source use **engine units**. A value such as `320 u/s`
  is not automatically `320 m/s` or a particular number of real-world metres.
- Doom uses **map units**, with a nominal 35 Hz simulation.
- ULTRAKILL uses **Unity units** (`u` and `u/s`).
- GRACE's community pages do not expose a stable movement-unit definition.
- WindShear uses **metres per second** (`m/s`).

No speed in this report is converted between those systems. The useful
comparison is structural: projection, impulse, friction, budget, and timing.

### 1.2 The important distinction: a projection cap is not a total-speed cap

The Quake-family air rule is often summarized as “a 30 u/s air-speed cap.”
That wording is wrong. The 30-unit value limits the **desired velocity
component along the player's input direction**. The player's existing total
velocity is not clamped to 30.

For a normalized wish direction `w` and velocity `v`:

```text
c          = dot(v, w)
cappedWish = min(wishSpeed, 30)
addSpeed   = cappedWish - c
accelSpeed = min(airAccel * wishSpeed * dt, addSpeed)   # if addSpeed > 0
v         += accelSpeed * w
```

Two details are easy to miss:

1. The **30-unit cap applies to `cappedWish`**, the target used to calculate
   `addSpeed`.
2. The acceleration magnitude uses the **uncapped** `wishSpeed` in Quake,
   GoldSrc, and Source.

Therefore a player moving at 320 u/s can receive an air acceleration vector
who's length is greater than 30 u/s. The vector can be mostly perpendicular
to existing velocity, so total speed can grow. This is the structural reason
classic strafe-jumping works; there is no separate “strafe-jump code.”

---

## 2. Cross-family summary

| Game / family | Verified movement shape | WindShear relevance |
| --- | --- | --- |
| Quake 1 | Directional acceleration; 30-unit air projection cap; ground-only friction | Borrow the shape of input-relative acceleration, not the speed gain |
| QuakeWorld | Quake-like air projection plus jump-before-friction ordering | A good example of one-frame ordering changing momentum |
| GoldSrc / Half-Life | Executable defaults `270/10/10/4/100`; 30-unit projection cap; edge friction | Borrow explicit limits; do not import “unlimited air speed” folklore |
| Source / Half-Life 2 | `320/10/10/4/100`; 30-unit projection cap; no air friction | Source verifies the projection rule most precisely |
| Quake II | Strong air acceleration disabled by default; weak coefficient-1 steering remains | Precedent for deliberately closing an exploit without deleting air control |
| Quake III | No 30-unit cap; weak acceleration toward the full wish speed | Shows that “no cap” and “strong air control” are different claims |
| CPM | Forward/back steering preserves speed; side steering uses a smaller target and stronger acceleration | Direction-specific air control is more legible than a universal projection rule |
| Doom (1993) | Ground-only forward and side impulses; per-tic friction; no air steering | Honest diagonal speed comes from separate visible inputs |
| Doom 3 | Weak wish-direction air acceleration, no air friction, collision projection | Useful model for readable air control and slide collision response |
| Doom (2016) | A rune explicitly adds meaningful air control; base air control is described as insignificant | Make strong air control an explicit upgrade or resource, not an invisible default |
| GRACE | Sprint-gated, count-limited wall kicks; extensive speedrun techniques found around slides and corners | Borrow the move budget; leave momentum conversion and clipping emergent |
| ULTRAKILL | Stamina budget, friction-based slide, wall-jump count, short timing windows, temporary Wind State | Borrow legible budgets and frame windows; avoid copying hidden speed tech |
| WindShear | 14 m/s run; 32 m/s² air acceleration with a 2.2 m/s lifetime budget; explicit slide and wall-kiss | A deliberately bounded platformer movement model |

### 2.1 Constant snapshot

These values are useful as a map of the family. They are **not** SI speeds and
must not be compared directly with WindShear's m/s values.

| Game | Max/wish speed | Ground accel | Air accel | Ground friction | Stop speed | Air projection cap | Air friction |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Quake 1 | `sv_maxspeed=320` | `sv_accelerate=10` | uses `sv_accelerate=10` | `sv_friction=4` | `sv_stopspeed=100` | `30` | none |
| QuakeWorld | `sv_maxspeed=320` | `sv_accelerate=10` | `sv_airaccelerate=0.7` declared; client movement passes `accelerate=10` | `sv_friction=4` | `sv_stopspeed=100` | `30` | none |
| GoldSrc executable | `sv_maxspeed=270` | `sv_accelerate=10` | `sv_airaccelerate=10` | `sv_friction=4` | `sv_stopspeed=100` | `30` | none |
| Source SDK 2013 | `sv_maxspeed=320` | `sv_accelerate=10` | `sv_airaccelerate=10` | `sv_friction=4` | `sv_stopspeed=100` | `30` | none |
| Quake II | `pm_maxspeed=300` | `pm_accelerate=10` | `pm_airaccelerate=0` default; weak coefficient `1` fallback | `pm_friction=6` | `pm_stopspeed=100` | `30` only in the optional Quake-style path | none |
| Quake III | `g_speed=320` | `pm_accelerate=10` | `pm_airaccelerate=1` | `pm_friction=6` | `pm_stopspeed=100` | none | none |
| Doom 3 | `pm_runspeed=220` | `PM_ACCELERATE=10` | `PM_AIRACCELERATE=1` | `PM_FRICTION=6` | `PM_STOPSPEED=100` | none | `PM_AIRFRICTION=0` |

Sources for each row are given in the corresponding section and in
[§13, Sources](#13-sources).

---

## 3. Quake 1 (1996)

### 3.1 Verified facts — [S]

Quake's released server movement defines:

```c
cvar_t sv_maxspeed   = {"sv_maxspeed", "320", false, true};
cvar_t sv_accelerate = {"sv_accelerate", "10"};
```

([Quake source, `sv_user.c` L167-L168](https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/WinQuake/sv_user.c#L167-L168)).
The shared physics cvars give `sv_friction=4` and `sv_stopspeed=100`
([`sv_phys.c` L42-L43](https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/WinQuake/sv_phys.c#L42-L43)),
while the player movement file sets `edgefriction=2`
([`sv_user.c` L26-L28](https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/WinQuake/sv_user.c#L26-L28)).

**Ground friction** is speed-dependent:

```text
control  = speed < sv_stopspeed ? sv_stopspeed : speed
newspeed = speed - dt * control * sv_friction
```

The velocity is then scaled to `newspeed`. Below the stop speed the
deceleration is effectively constant; above it, it is proportional to speed.
Near a drop-off, `edgefriction=2` multiplies the friction ([source
L122-L160](https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/WinQuake/sv_user.c#L122-L160)).

**Ground acceleration** is directional:

```text
c          = dot(v, wishdir)
addSpeed   = wishSpeed - c
accelSpeed = min(sv_accelerate * dt * wishSpeed, addSpeed)
v         += accelSpeed * wishdir
```

If the velocity component along the requested direction is already at least
the wish speed, there is no acceleration in that direction ([source
L190-L205](https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/WinQuake/sv_user.c#L190-L205)).

**Air acceleration** keeps the directional projection but caps the projected
wish speed at 30. Quake 1 has no separate `sv_airaccelerate` cvar in this
path; it uses `sv_accelerate` for the acceleration coefficient ([source
L207-L226](https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/WinQuake/sv_user.c#L207-L226)).
Friction is invoked only on the ground branch, so there is no ordinary air
friction ([source L357-L369](https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/WinQuake/sv_user.c#L357-L369)).

### 3.2 What this means

The famous speed gain is an emergent consequence of the general acceleration
rule. It is not a separate “bunny-hop multiplier.” WindShear can borrow the
rule that acceleration follows the requested direction without copying the
low projection target that makes total speed grow.

### 3.3 Not established

- Quake 1 does not expose a reliable fixed simulation rate in the movement
  file alone. The historical server tick is commonly 10 Hz for movement, but
  this report does not use that as a tuning input.
- A frequently repeated “Quake max speed is 320 m/s” is a unit error.
  `320` is an engine-unit wish-speed value.

---

## 4. QuakeWorld

### 4.1 Verified facts — [S]

The QuakeWorld branch in the same released source tree defines:

```c
sv_maxvelocity     = 2000
sv_stopspeed       = 100
sv_maxspeed        = 320
sv_accelerate      = 10
sv_airaccelerate   = 0.7
sv_friction        = 4
```

([QuakeWorld `sv_phys.c` L42-L52](https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/QW/server/sv_phys.c#L42-L52)).

Its client movement retains the 30-unit air projection cap and the
uncapped-wish-speed acceleration magnitude ([QuakeWorld `pmove.c`
L390-L434](https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/QW/client/pmove.c#L390-L434)).

Two source-level details are unusually instructive:

1. **`sv_airaccelerate` is not passed to the client air function.** The client
   calls `PM_AirAccelerate(..., movevars.accelerate)`, not
   `movevars.airaccelerate` ([source L539-L554](https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/QW/client/pmove.c#L539-L554)).
   In this code path the declared `0.7` is therefore not the coefficient used.
2. **Jump is processed before friction.** `JumpButton()` clears the on-ground
   state and adds the jump impulse; only then does `PlayerMove()` call
   `PM_Friction()` ([jump logic L645-L684](https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/QW/client/pmove.c#L645-L684),
   [ordering L862-L900](https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/QW/client/pmove.c#L862-L900)).
   The first launch frame consequently skips the ground friction that would
   otherwise apply.

### 4.2 WindShear lesson

Small ordering decisions are movement design. WindShear's fixed 60 Hz,
explicit timer order, and frame tests exist for the same reason: a one-frame
ordering change must not silently alter a recorded route.

---

## 5. GoldSrc / Half-Life (1998)

### 5.1 Executable defaults — [O]

The archived Valve Developer Community cvar dump was captured from a
Half-Life executable and records these defaults:

| Cvar | Default |
| --- | ---: |
| `sv_maxspeed` | `270` |
| `sv_accelerate` | `10` |
| `sv_airaccelerate` | `10` |
| `sv_friction` | `4` |
| `sv_stopspeed` | `100` |
| `edgefriction` | `2` |
| `sv_maxvelocity` | `2000` |

See the [archived VDC cvar list, revision 431607](https://web.archive.org/web/20251220074152id_/https://developer.valvesoftware.com/wiki/List_of_Half-Life_console_commands_and_variables)
and its [permanent wiki revision](https://developer.valvesoftware.com/w/index.php?title=List_of_Half-Life_console_commands_and_variables&oldid=431607).

The commonly repeated `sv_maxspeed=320` is **not** the default recorded by
that executable list. Later game-specific configurations and modern Source
defaults are different cases.

### 5.2 Published movement code — [S]

The published Half-Life SDK movement code keeps the 30-unit air projection
cap and uses the uncapped wish speed for acceleration magnitude
([`PM_AirAccelerate`, L1279-L1313](https://github.com/ValveSoftware/halflife/blob/b1b5cf5892918535619b2937bb927e46cb097ba1/pm_shared/pm_shared.c#L1279-L1313)).
It also retains the edge-friction multiplier near a drop-off
([L1225-L1257](https://github.com/ValveSoftware/halflife/blob/b1b5cf5892918535619b2937bb927e46cb097ba1/pm_shared/pm_shared.c#L1225-L1257)).

The SDK additionally contains `PM_PreventMegaBunnyJumping()`: above
`1.7 × maxspeed`, it scales the full velocity vector by
`(maxscaledspeed / speed) * 0.65` ([L2435-L2467](https://github.com/ValveSoftware/halflife/blob/b1b5cf5892918535619b2937bb927e46cb097ba1/pm_shared/pm_shared.c#L2435-L2467)).
This is source evidence for an explicit historical clamp in the SDK code; it
is not evidence that every GoldSrc derivative behaved identically.

### 5.3 WindShear lesson

GoldSrc is the clearest precedent for making a movement limit explicit. Its
defaults and edge-friction multiplier are legible numbers, while its
projected-air rule still permits speed growth. WindShear uses the opposite
choice where necessary: preserve the useful steering, but bound total
airborne contribution.

---

## 6. Source / Half-Life 2

### 6.1 Verified constants and formula — [S]

Source SDK 2013 defines:

```text
sv_maxspeed      = 320
sv_accelerate    = 10
sv_airaccelerate = 10
sv_friction      = 4
sv_stopspeed     = 100
sv_maxvelocity   = 3500  # per axis, for ballistically moving objects
```

([`movevars_shared.cpp` L37-L102](https://github.com/ValveSoftware/source-sdk-2013/blob/3e957b70b167929f120360115d359d1ecb4c1699/src/game/shared/movevars_shared.cpp#L37-L102)).

The base game movement class returns `30.f` from `GetAirSpeedCap()`
([`gamemovement.h` L101-L105](https://github.com/ValveSoftware/source-sdk-2013/blob/3e957b70b167929f120360115d359d1ecb4c1699/src/game/shared/gamemovement.h#L101-L105)).
`AirAccelerate()` then implements the projection rule exactly as described
in [§1.2](#12-the-important-distinction-a-projection-cap-is-not-a-total-speed-cap):
the cap controls `wishspd`, while the acceleration magnitude uses the
original `wishspeed` ([`gamemovement.cpp`
L1705-L1746](https://github.com/ValveSoftware/source-sdk-2013/blob/3e957b70b167929f120360115d359d1ecb4c1699/src/game/shared/gamemovement.cpp#L1705-L1746)).

`Friction()` applies ordinary friction only when a ground entity is present.
There is no ordinary air-friction term ([`gamemovement.cpp`
L1620-L1677](https://github.com/ValveSoftware/source-sdk-2013/blob/3e957b70b167929f120360115d359d1ecb4c1699/src/game/shared/gamemovement.cpp#L1620-L1677)).

Half-Life 2's gameplay speed cvars are separate movement-state values:
`hl2_walkspeed=150`, `hl2_normspeed=190`, and `hl2_sprintspeed=320`
([`hl2_player.cpp` L84-L92](https://github.com/ValveSoftware/source-sdk-2013/blob/3e957b70b167929f120360115d359d1ecb4c1699/src/game/server/hl2/hl2_player.cpp#L84-L92)).
They should not be confused with the air projection target.

### 6.2 Corrected worked example — [Calc]

Assume:

- current velocity: `320 u/s` along X;
- wish direction: +Y, exactly perpendicular;
- wish speed: `320 u/s`;
- air acceleration coefficient: `10`;
- tick: `0.008 s`.

Then:

```text
c          = 0
cappedWish = min(320, 30) = 30
addSpeed   = 30
accelSpeed = min(10 * 320 * 0.008, 30)
           = min(25.6, 30) = 25.6
newSpeed   = sqrt(320² + 25.6²) ≈ 321.02237 u/s
```

The acceleration vector is 25.6 u/s long even though the **projected target**
is only 30 u/s. The total velocity is not clamped to 30 or 320.

This is a computed example from the source formula, not a measured route.

### 6.3 Unsupported folklore — [unverified]

The claim that a later Source engine has an air speed of “about 60 u/s” was
not supported by the released Source SDK 2013 code or by the sources reviewed
here. It is not used in WindShear's design and is not repeated as fact.

---

## 7. Quake II (1997)

### 7.1 Verified constants — [S]

Quake II's shared movement code defines:

```text
pm_stopspeed     = 100
pm_maxspeed      = 300
pm_accelerate    = 10
pm_airaccelerate = 0
pm_friction      = 6
```

([`qcommon/pmove.c` L53-L59](https://github.com/id-Software/Quake-2/blob/372afde46e7defc9dd2d719a1732b8ace1fa096e/qcommon/pmove.c#L53-L59)).

Its optional `PM_AirAccelerate()` is Quake-like and retains the 30-unit
projection cap ([L397-L430](https://github.com/id-Software/Quake-2/blob/372afde46e7defc9dd2d719a1732b8ace1fa096e/qcommon/pmove.c#L397-L430)).
The important selection logic is in `PM_AirMove()`:

```c
if (pm_airaccelerate)
    PM_AirAccelerate(wishdir, wishspeed, pm_accelerate);
else
    PM_Accelerate(wishdir, wishspeed, 1);
```

([L635-L660](https://github.com/id-Software/Quake-2/blob/372afde46e7defc9dd2d719a1732b8ace1fa096e/qcommon/pmove.c#L635-L660)).

In deathmatch, the server forwards `sv_airaccelerate` to the shared value; in
single-player it explicitly forces the shared value to zero
([`server/sv_init.c` L190-L205](https://github.com/id-Software/Quake-2/blob/372afde46e7defc9dd2d719a1732b8ace1fa096e/server/sv_init.c#L190-L205)).
The server cvar itself defaults to zero
([`server/sv_main.c` L968-L978](https://github.com/id-Software/Quake-2/blob/372afde46e7defc9dd2d719a1732b8ace1fa096e/server/sv_main.c#L968-L978)).

### 7.2 Correction: “no air control” is too strong

With the default value, Quake II does **not** call the Quake-style 30-unit
projection function. It retains a weak coefficient-1 `PM_Accelerate()` call.
That call can still provide a small amount of directional steering. The
accurate description is:

> **Strong, speed-accumulating air acceleration is disabled by default;
> weak wish-direction steering remains.**

The optional nonzero path is also unusual: when selected, it passes
`pm_accelerate`—not `pm_airaccelerate`—as the coefficient to the 30-unit
Quake-style function.

### 7.3 WindShear lesson

This is a useful precedent for closing a movement exploit without pretending
that “air control” is one binary switch. WindShear can retain useful steering
while bounding the amount it can contribute.

---

## 8. Quake III Arena (1999)

### 8.1 Verified constants and formula — [S]

Quake III defines:

```text
pm_stopspeed     = 100
pm_accelerate    = 10
pm_airaccelerate = 1
pm_friction      = 6
g_speed          = 320
```

([`bg_pmove.c` L34-L44](https://github.com/id-Software/Quake-III-Arena/blob/dbe4ddb10315479fc00086f08e25d968b4b43c49/code/game/bg_pmove.c#L34-L44),
[`g_main.c` L136-L146](https://github.com/id-Software/Quake-III-Arena/blob/dbe4ddb10315479fc00086f08e25d968b4b43c49/code/game/g_main.c#L136-L146)).

`PM_Accelerate()` has no 30-unit projection cap:

```text
c          = dot(v, wishdir)
addSpeed   = wishSpeed - c
accelSpeed = min(pm_airaccelerate * dt * wishSpeed, addSpeed)
v         += accelSpeed * wishdir
```

([`bg_pmove.c` L240-L258](https://github.com/id-Software/Quake-III-Arena/blob/dbe4ddb10315479fc00086f08e25d968b4b43c49/code/game/bg_pmove.c#L240-L258)).
Air movement calls it with `pm_airaccelerate=1`
([L600-L638](https://github.com/id-Software/Quake-III-Arena/blob/dbe4ddb10315479fc00086f08e25d968b4b43c49/code/game/bg_pmove.c#L600-L638)).
There is no ordinary air friction. `CmdScale()` normalizes diagonal command
input so that it does not receive a `sqrt(2)` speed penalty
([L281-L311](https://github.com/id-Software/Quake-III-Arena/blob/dbe4ddb10315479fc00086f08e25d968b4b43c49/code/game/bg_pmove.c#L281-L311)).

### 8.2 Corrected worked example — [Calc]

At `320 u/s`, perpendicular input, an `8 ms` tick, and
`pm_airaccelerate=1`:

```text
accelSpeed = 1 * 320 * 0.008 = 2.56 u/s
newSpeed   = sqrt(320² + 2.56²) ≈ 320.01024 u/s
```

It is **not** `322.56 u/s`: `2.56` is the length of the perpendicular
acceleration vector, not a `2.56 u/s` increase in total speed.

### 8.3 Design meaning

Quake III demonstrates that “there is no 30 cap” and “there is strong air
acceleration” are separate claims. VQ3-style movement gains are possible, but
the air coefficient is weak and the input geometry matters.

### 8.4 Unverified

Exact behavior under every combination of client prediction, packet timing,
and server correction is not reconstructed here. No measured VQ3 speed record
is used as a WindShear design input.

---

## 9. Challenge ProMode Arena (CPM)

### 9.1 Source-availability caveat

The original Challenge ProMode Arena source was not publicly available for
this research. The code examined is
[GPP-1-1](https://github.com/ZdrytchX/GPP-1-1), a CPM-derived reimplementation
with additional game-specific features. Its constants are therefore **GPP
constants**, not proven historical CPMA constants.

### 9.2 GPP constants — [S] for GPP; [C] for historical CPM attribution

GPP initializes `cpm_pm_aircontrol=165`, then its CPM setup changes it to
`150`. The same setup uses `cpm_pm_wishspeed=30`,
`cpm_pm_strafeaccelerate=70`, `cpm_pm_airstopaccelerate=2.5`,
`pm_accelerate=15`, and `pm_friction=8` ([`bg_promode.c`
L195-L209](https://github.com/ZdrytchX/GPP-1-1/blob/6bde6e8278f270c147b182d8c0c0cf137cedf814/src/game/bg_promode.c#L195-L209)
and [L291-L328](https://github.com/ZdrytchX/GPP-1-1/blob/6bde6e8278f270c147b182d8c0c0cf137cedf814/src/game/bg_promode.c#L291-L328)).
The mismatch between the initial `165` and setup-time `150` is why these
numbers should not be quoted as original CPMA values.

### 9.3 Verified GPP movement shape

GPP's air path does three materially different things:

1. A normal weak `PM_Accelerate()` call.
2. For pure side input, a second acceleration call with a **30-unit wish
   target** and the much larger `cpm_pm_strafeaccelerate=70` coefficient.
3. A dedicated `CPM_PM_Aircontrol()` path for forward/back input. It removes
   vertical velocity, computes an angle-sensitive steering amount, rotates
   the horizontal velocity, and restores its original magnitude.

The dedicated steering function preserves speed by normalizing the horizontal
velocity, changing its direction, and multiplying by the saved magnitude
([`bg_promode.c` L330-L371](https://github.com/ZdrytchX/GPP-1-1/blob/6bde6e8278f270c147b182d8c0c0cf137cedf814/src/game/bg_promode.c#L330-L371)).
The side-specific target and acceleration are selected in
[`bg_pmove.c` L1194-L1249](https://github.com/ZdrytchX/GPP-1-1/blob/6bde6e8278f270c147b182d8c0c0cf137cedf814/src/game/bg_pmove.c#L1194-L1249).

In practical terms:

- forward/back air steering preserves horizontal speed while changing
  direction;
- A/D uses a smaller target and stronger acceleration;
- diagonal input remains closer to the VQ3-style path.

GPP also contains explicit bunny-hop acceleration and a class-scaled
bunny-hop speed cap of `1200` in its CPM setup
([`bg_promode.c` L238-L264](https://github.com/ZdrytchX/GPP-1-1/blob/6bde6e8278f270c147b182d8c0c0cf137cedf814/src/game/bg_promode.c#L238-L264)
and [L306-L313](https://github.com/ZdrytchX/GPP-1-1/blob/6bde6e8278f270c147b182d8c0c0cf137cedf814/src/game/bg_promode.c#L306-L313)).
That is evidence about GPP, not proof of CPMA's historical cap.

### 9.4 WindShear lesson

CPM's most transferable idea is not a magic constant. It is **different air
inputs can have different, legible jobs**. WindShear has only a 1D run axis,
so it does not need CPM's three-way input split, but it can still make the
air-control budget an explicit player-facing rule.

---

## 10. Doom (1993)

### 10.1 Verified constants and impulse model — [S]

Original Doom runs at `TICRATE=35`
([`doomdef.h` L121-L123](https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/doomdef.h#L121-L123)).
Normal running uses forward input `0x32` (50); normal strafing uses side
input `0x28` (40) ([`g_game.c` L171-L177](https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/g_game.c#L171-L177)).

`P_MovePlayer()` applies forward and side thrusts only when the player is on
the ground:

```c
if (cmd->forwardmove && onground)
    P_Thrust(player, angle, cmd->forwardmove * 2048);
if (cmd->sidemove && onground)
    P_Thrust(player, angle - ANG90, cmd->sidemove * 2048);
```

([`p_user.c` L148-L170](https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/p_user.c#L148-L170)).
There is no ordinary air steering because there is no player jump and no
mid-air input acceleration.

The straight-run thrust is:

```text
T = 50 × 2048 / 65536 = 1.5625 map units/tic
```

The side component at input 40 is `1.25 map units/tic`. These are separate
vectors, so holding forward and side produces faster diagonal movement.

### 10.2 Friction and ordering — [S]

Ground friction is a per-tic multiplier:

```text
STOPSPEED = 0x1000
FRICTION  = 0xe800
f         = 0xe800 / 0x10000 = 0.90625
```

([`p_mobj.c` L109-L113](https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/p_mobj.c#L109-L113)
and [L114-L240](https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/p_mobj.c#L114-L240)).
The player is moved using the current momentum first and is then multiplied by
the friction factor. The equivalent steady-state model is:

```text
u[n+1] = f × (u[n] + T)
```

where `u` is Doom's stored displacement-per-tic momentum.

### 10.3 Correct unit interpretation

The number `54.6875` is **not** Doom's straight-run top speed:

- `1.5625 map units/tic` is the straight-run thrust increment in Doom's
  native velocity state.
- Multiplying that one-tic increment by `35 tic/s` expresses the velocity
  change after one tic in SI-style map-units-per-second notation:
  `1.5625 × 35 = 54.6875 map units/s`.
- It is neither a speed cap nor the equilibrium run speed.
- Strict acceleration, converting Doom's `map units/tic²` to
  `map units/s²`, is `1.5625 × 35² = 1,914.0625 map units/s²`.

At steady state, the per-tic **displacement** in the forward component is:

```text
T / (1 - f) = 1.5625 / 0.09375 = 16.6667 map units/tic
```

or about `16.67 × 35 = 583.33 map units/s` of straight-run travel.

Without new input, the retained fraction after one second is
`0.90625^35 ≈ 3.19%`.

### 10.4 Established speed table — [S] plus [C]

The Doom Wiki's player-data table records the familiar theoretical speeds:

| Movement | Map units/tic | Map units/s |
| --- | ---: | ---: |
| Straight run | `16.67` | `583.33` |
| SR40 (run 50 + strafe 40) | `21.34` | `747.03` |
| SR50 (run 50 + strafe 50) | `23.57` | `824.94` |

See [Doom Wiki: Player, “Player data (original)”](https://doomwiki.org/wiki/Player).
The source-level thrust/friction model above explains why diagonal SR40/SR50
exceed straight running: Doom adds two visible ground impulses and friction
acts independently on each component.

### 10.5 Honest implication

Doom's diagonal speed is not a hidden exploit. The player holds two visible
movement inputs and the game applies two ordinary impulses. WindShear does
not need a diagonal bonus because its gameplay route is one-dimensional; its
equivalent design principle is that legitimate speed changes should have an
honest input and a predictable bound.

### 10.6 Collision folklore

Doom's wall-running, corner boosts, and elastic wall collisions are known
source-analysis phenomena, but they are not useful canonical movement
mechanics. They depend on collision geometry, fixed-point rounding, and
specific source behavior. WindShear should treat any analogous result as an
accident to characterize, not as a feature to reproduce.

---

## 11. Doom 3 (2004)

### 11.1 Verified constants — [S]

Doom 3's physics player defines:

```text
PM_STOPSPEED      = 100
PM_ACCELERATE     = 10
PM_AIRACCELERATE  = 1
PM_FRICTION       = 6
PM_AIRFRICTION    = 0
OVERCLIP          = 1.001
```

([`Physics_Player.cpp` L37-L55](https://github.com/id-Software/DOOM-3/blob/a9c49da5afb18201d31e3f0a429a037e56ce2b9a/neo/game/physics/Physics_Player.cpp#L37-L55)).

Its movement cvars default to:

```text
pm_walkspeed   = 140
pm_runspeed    = 220
pm_crouchspeed = 80
```

([`SysCvar.cpp` L229-L243](https://github.com/id-Software/DOOM-3/blob/a9c49da5afb18201d31e3f0a429a037e56ce2b9a/neo/game/gamesys/SysCvar.cpp#L229-L243)).

### 11.2 Air movement and collision

`PM_Accelerate()` uses the Quake II-style full-wish target and no 30-unit
projection cap ([`Physics_Player.cpp` L118-L157](https://github.com/id-Software/DOOM-3/blob/a9c49da5afb18201d31e3f0a429a037e56ce2b9a/neo/game/physics/Physics_Player.cpp#L118-L157)).
Air movement calls it with `PM_AIRACCELERATE=1`; ground friction is applied
through the separate `Friction()` path and `PM_AIRFRICTION=0` means there is
no ordinary air drag ([air path L600-L639](https://github.com/id-Software/DOOM-3/blob/a9c49da5afb18201d31e3f0a429a037e56ce2b9a/neo/game/physics/Physics_Player.cpp#L600-L639)).

Collision removes velocity entering a plane and retains the tangential part.
The projection uses `OVERCLIP=1.001` to avoid numerical gaps
([collision path L320-L404](https://github.com/id-Software/DOOM-3/blob/a9c49da5afb18201d31e3f0a429a037e56ce2b9a/neo/game/physics/Physics_Player.cpp#L320-L404)).

`CmdScale()` normalizes diagonal command input, so diagonal movement does not
suffer a `sqrt(2)` penalty ([L72-L114](https://github.com/id-Software/DOOM-3/blob/a9c49da5afb18201d31e3f0a429a037e56ce2b9a/neo/game/physics/Physics_Player.cpp#L72-L114)).

### 11.3 WindShear lesson

Doom 3 provides weak, readable air steering and explicit collision
projection. WindShear adopts the readability, but strengthens the player's
ability to correct a line while retaining a hard **total** 2.2 m/s airborne
contribution budget.

---

## 12. Doom (2016)

### 12.1 Evidence limitation

No public id Software source for Doom (2016)'s player movement was located.
The following are therefore secondary descriptions, not exact engine
constants. No fabricated acceleration, friction, collision, or speed values
are given here.

### 12.2 Verified-by-secondary-documentation facts — [C]

- The Delta V jump-boots enable a second, thruster-based mid-air jump
  ([Doom Wiki: Delta V jump-boots](https://doomwiki.org/wiki/Delta_V_jump-boots)).
- The In-Flight Mobility rune provides a “significant increase in control over
  in-air movement after a double-jump.” Its mastered ability applies
  air control to a single jump ([Doom Wiki: Rune (Doom 2016)](https://doomwiki.org/wiki/Rune_(Doom_2016))).
- The In-Flight Mobility trial passage explicitly tells the player that they
  “lack significant air control” during the trial ([Doom Wiki: Rune trial
  passage](https://doomwiki.org/wiki/Rune_trial_passage)).

Together these descriptions are strong evidence that ordinary base movement
does not provide the sort of significant air control that the rune adds. The
careful conclusion is:

> **Doom (2016) makes meaningful air control an explicit upgrade. Exact
> base and rune coefficients remain unverified.**

### 12.3 What is not established

- The exact base air-acceleration formula.
- The exact In-Flight Mobility multiplier or curve.
- Exact ground-friction constants.
- Exact collision-slide and momentum-conversion coefficients.
- Whether every movement edge case in the shipping game matches the engine
  behavior observed through external tools.

### 12.4 WindShear lesson

Making strong air control an explicit upgrade, resource, or mode is a good
design pattern. WindShear does not need Doom (2016)'s rune economy, but the
principle applies: if a future assist raises air authority, it should be
named, bounded, visible in run configuration, and tested.

---

## 13. GRACE (Roblox)

### 13.1 Official product facts — [O]

The official Roblox listing identifies:

- place ID: `138837502355157`;
- universe ID: `6508759464`;
- title: **Grace [GRACE BUT EVIL]**;
- creator: **The Fartering Few**;
- description: “A Rooms game with a focus on chaos, movement and speed.”

See the [official Roblox game page](https://www.roblox.com/games/138837502355157/Grace)
and [Roblox Games API response](https://games.roblox.com/v1/games?universeIds=6508759464).

This official evidence confirms the game's identity and its movement-and-speed
focus. It does **not** confirm individual movement constants.

### 13.2 Community mechanics — [C]

The community [GRACE Movement page](https://grace-rbx.fandom.com/wiki/Movement)
and [Miraheze Mechanics revision 27998](https://grace.miraheze.org/wiki/Mechanics?oldid=27998)
report the following:

| Mechanic | Community-reported behavior |
| --- | --- |
| Sprint | Holding sprint runs faster |
| Slide | Sprinting and crouching at sufficient speed starts a slide; stairs/slopes can build momentum |
| Wall kick | Jumping against a wall in the air; requires sprint |
| Wall-kick limit | 2 base; 4 with 10-Point Crampons; 1 with Propeller Cap; unlimited in Zen/Reprieve |
| Wall-kick boost | A small boost in the player's movement direction |
| Momentum conversion | Vertical speed at a wall kick can become forward speed |
| Chained slide jumping | Continued jumping while sliding and not holding sprint reduces friction-related speed loss |
| Trimping | Sliding, releasing sprint, and jumping into an obstacle launches the player higher with more momentum |
| Darting | Uses wall-bounce vertical-to-horizontal conversion to gain and maintain speed |
| Corner clipping | Can produce immense speed, but is described as inconsistent and luck-dependent |

These pages are living community documentation. The details may describe
different GRACE versions.

### 13.3 Unverified quantities

The current community pages do **not** expose a reliable numeric wall-kick
boost, air-control coefficient, wall-kick conversion ratio, or “slide soft
cap.” This report therefore does not invent one. Sprint-release/friction
interactions are described only qualitatively.

### 13.4 WindShear lesson

GRACE demonstrates that a wall move can be a learnable, count-limited
technique rather than an unlimited accelerator. WindShear borrows that
legibility:

- five kisses maximum;
- a two-frame arming window;
- a fixed `+0.8 m/s` boost;
- an explicit horizontal ceiling of `18.0 m/s`.

WindShear deliberately does not borrow vertical-to-horizontal momentum
conversion, corner clipping, or a slide cap that disappears when sprint is
released.

---

## 14. ULTRAKILL

### 14.1 Evidence tiers

ULTRAKILL has three different evidence classes in this report:

1. **Official developer patch notes** [O].
2. **The community wiki** [C], pinned here to revision `35179` from
   `2026-11-17T04:20:38Z`.
3. **An unofficial binary-decompilation snapshot** [D], pinned to commit
   `3ac66af8ebf0ef3ff2b813243da15576c015dfc8`. This is not original
   developer source and may contain decompiler artifacts.

### 14.2 Movement values — [C]

The pinned [ULTRAKILL Movement wiki revision 35179](https://ultrakill.wiki.gg/wiki/Movement?oldid=35179)
gives:

| Action | Speed |
| --- | ---: |
| Walking | `16.5 u/s` |
| Sliding | `24 u/s` |
| Dashing | `49.5 u/s` |
| Slamming | `100 u/s` |
| Whiplash reeling | `60 u/s` |
| Rocket riding | `65 u/s` |

Stamina has a maximum of 3. A dash costs 1 stamina and a dash jump costs 2.
Regeneration is `1.4/s` on Harmless, `1.05/s` on Lenient, and `0.7/s` on
Standard and higher; it pauses during a slide.

The wiki also reports:

- slideways adds a lateral `5 u/s` vector;
- maximum slide speed is `72 u/s`, or `77 u/s` with slideways;
- a player can make at most three wall jumps in the air before landing or
  enemy-stepping restores the count;
- wall cling reaches a maximum fall speed of `100 u/s`;
- Wind State lasts `0.5 s` after a wall-slide jump, dash/dive enemy step, or
  dash extension, and `0.75 s` after a rocket jump.

The exact revision content can be retrieved through the
[MediaWiki revision API](https://ultrakill.wiki.gg/api.php?action=query&prop=revisions&revids=35179&rvprop=ids%7Ctimestamp%7Ccontent&rvslots=main&format=json).

### 14.3 Official patch history — [O]

The official Steam news entry titled **Fraud Hotfix #2**, dated 2026-04-12,
says:

- Wind State was added, triggered by a non-damaging rocket jump, a wall jump
  while diving, a dash extension, or dashing into an enemy step;
- Dash Extension was restored;
- the SSJ speedrun technique was made frame-rate independent and prioritized
  over dash jumps.

See the [official ULTRAKILL Steam news archive](https://store.steampowered.com/oldnews?appgroupname=ULTRAKILL&appids=1229490)
and the [announcement entry](https://steamcommunity.com/games/1229490/announcements/detail/498351387739950731).
Community patch histories map this release to patch `17b3`; the official name
used here is **Fraud Hotfix #2**.

### 14.4 Unofficial decompilation details — [D]

The 17d4 decompilation snapshot contains:

```text
ssjMaxFrames       = 4f
ONE_PHYSICS_FRAME  = 0.008f
```

([`NewMovement.cs` L298-L322](https://github.com/SmolFlexan/ULTRAKILL/blob/3ac66af8ebf0ef3ff2b813243da15576c015dfc8/NewMovement.cs#L298-L322)).
`TrySSJ()` calculates an integer frame index and rejects indices of 0 or 4
or greater, while the wall-jump SSJ path uses the four-frame boundary
([L1663-L1711](https://github.com/SmolFlexan/ULTRAKILL/blob/3ac66af8ebf0ef3ff2b813243da15576c015dfc8/NewMovement.cs#L1663-L1711)
and [L1755-L1775](https://github.com/SmolFlexan/ULTRAKILL/blob/3ac66af8ebf0ef3ff2b813243da15576c015dfc8/NewMovement.cs#L1755-L1775)).

The same snapshot shows:

- active Wind State multiplying the air-acceleration term from `1×` to `4×`
  ([L1349-L1380](https://github.com/SmolFlexan/ULTRAKILL/blob/3ac66af8ebf0ef3ff2b813243da15576c015dfc8/NewMovement.cs#L1349-L1380));
- ground velocity interpolation by `0.25 × friction`
  ([L1296-L1329](https://github.com/SmolFlexan/ULTRAKILL/blob/3ac66af8ebf0ef3ff2b813243da15576c015dfc8/NewMovement.cs#L1296-L1329));
- dash storage set to one second and decremented by `Time.fixedDeltaTime`
  ([L1071](https://github.com/SmolFlexan/ULTRAKILL/blob/3ac66af8ebf0ef3ff2b813243da15576c015dfc8/NewMovement.cs#L1071),
  [L1486-L1492](https://github.com/SmolFlexan/ULTRAKILL/blob/3ac66af8ebf0ef3ff2b813243da15576c015dfc8/NewMovement.cs#L1486-L1492));
- a normal wall-jump force expression `2000f * wallJumpPower`
  ([L1768-L1775](https://github.com/SmolFlexan/ULTRAKILL/blob/3ac66af8ebf0ef3ff2b813243da15576c015dfc8/NewMovement.cs#L1768-L1775)).

The snapshot does not serialize the relevant player/prefab values. Therefore
`walkSpeed`, `jumpPower`, `airAcceleration`, `wallJumpPower`, and related
prefab fields cannot be extracted authoritatively from this snapshot.

### 14.5 Preserving the SSJ discrepancy

The community wiki says Super Slide Jump occurs “three frames or less
[?]” after a slide and lists first-, second-, and third-frame boosts of
`24.75`, `12.375`, and `6.1875 u/s`. The unofficial decompilation instead
shows a four-frame boundary (`4 × 0.008 = 0.032 s`) while accepting computed
indices 1, 2, and 3.

These statements are close enough to be reconcilable as “three valid frame
indices inside a four-frame boundary,” but the wiki explicitly marks its
frame count as uncertain and the decompilation is not developer source. This
report preserves both claims rather than replacing one with the other.

### 14.6 WindShear lesson

ULTRAKILL makes movement resources and timing windows visible:

- stamina limits dashes and dash jumps;
- slide friction returns an over-speed player to a known state;
- wall jumps have a count;
- short state windows reward precise inputs;
- Wind State is temporary rather than permanent.

WindShear does not need stamina or Wind State now. Its equivalent
legibility comes from a fixed-duration slide, a two-frame wall-kiss window,
a five-kiss chain, and a hard speed ceiling.

---

## 15. WindShear's current movement model

### 15.1 Locked values — [S]

The authoritative values are in
[`ws_tuning.gd`](../addons/windshear/core/ws_tuning.gd) and checked against
[`TECH_SPEC.md`](../TECH_SPEC.md) by
[`test_tuning.gd`](../tests/test_tuning.gd):

| Feature | WindShear value |
| --- | ---: |
| Simulation | fixed 60 Hz |
| Plane | XY only; `velocity.z = 0` every frame |
| Max run | `14.0 m/s` |
| Ground acceleration | `90 m/s²` |
| Ground deceleration | `60 m/s²` |
| Air acceleration | `32 m/s²` |
| Total air contribution per airborne stretch | `2.2 m/s` |
| Gravity | `60 m/s²` |
| Jump | `15.5 m/s`, variable height |
| Full-hold jump apex | `15.5² / (2 × 60) ≈ 2.002 m` |
| Coyote time | `8 frames` (`133.33 ms`) |
| Jump buffer | `10 frames` (`166.67 ms`) |
| Slide | `27 frames` (`0.45 s`) |
| Slide friction | `6 m/s²` (`2.7 m/s` lost over a full slide) |
| Wall-kiss arming window | `2 frames` after slide start |
| Side-wall test | `abs(normal.z) >= 0.5` |
| Wall-kiss boost | `+0.8 m/s` |
| Wall-kiss chain | maximum `5` |
| Chain expiry | `30 frames` without a kiss |
| Wall-kiss horizontal ceiling | `18.0 m/s` |

### 15.2 How WindShear differs from Quake projection

WindShear's controller does **not** implement Quake's full 2D projection
rule. Its route is one-dimensional. In the air it:

1. chooses `direction = sign(move_axis)`;
2. computes the current signed velocity along that direction;
3. adds at most `32 × dt` in that direction;
4. limits the total added amount across the airborne stretch to `2.2 m/s`;
5. resets the budget on landing.

The implementation is in
[`lancer_controller.gd`](../addons/windshear/movement/lancer_controller.gd#L210-L223).
It also does not add air contribution while already moving at or above the
14 m/s run speed in the requested direction. The explicit wall-kiss ceiling
is 18 m/s.

The discovery suite uses `20.2 m/s` as a **conservative overall probe
ceiling**:

```text
14.0 run + 2.2 maximum air contribution + 5 × 0.8 wall-kiss boosts = 20.2
```

This is intentionally conservative. Current air control does not add above
14 m/s in the same direction, and the wall-kiss path itself is capped at
18 m/s. The `20.2` value is an envelope for finding unknowns, not a declared
player speed.
### 15.3 Wall-kiss semantics

A slide opens a two-frame window. A route-parallel side-wall contact during
that window arms the kiss. Jumping while armed adds `+0.8 m/s` horizontally;
the jump frame skips ground acceleration so the boost is not immediately
eaten by the run-speed target. A chain is limited to five kisses and expires
after 30 frames without one. The explicit horizontal ceiling is 18 m/s.

This is fully specified and testable. It is not the GRACE wall-kick, and it
must not be implemented a second time by a Fracture module.

---

## 16. What WindShear should borrow — and what should stay accidental

### 16.1 Borrow deliberately

| Principle | Provenance | WindShear form |
| --- | --- | --- |
| Input-relative steering | Quake, Source, Doom 3 | Air input changes direction without becoming a free speed source |
| No ordinary air friction | Quake, Source, Doom 3 | Airborne momentum persists unless explicitly bounded |
| Explicit air budget | Design synthesis | `2.2 m/s` total per airborne stretch, reset on landing |
| Strong but bounded wall move | GRACE, ULTRAKILL | Two-frame arming window, five-kiss chain |
| Explicit slide state | ULTRAKILL | Fixed 27-frame slide with fixed linear friction |
| Forgiveness windows | Platformer practice, not a classic-engine constant | Eight-frame coyote time and ten-frame jump buffer |
| Fixed-step determinism | Modern reproducibility requirement | 60 Hz physics and frame-exact tests |
| Collision must not create energy | Physics safety | Remove the into-wall component; retain tangential speed |

### 16.2 Leave emergent

These are legitimate movements in other games, but they are not WindShear
features:

| Potential accident | Why it must not be deliberately reproduced |
| --- | --- |
| Quake/Source strafe-jump speed growth | It invalidates the 14 m/s run economy and replaces route design with angle optimisation |
| Bunny-hop momentum accumulation | It turns repeated landing inputs into the primary speed mechanic |
| Repeated wall-kiss farming | WindShear already has a five-kiss cap and an 18 m/s ceiling |
| GRACE-style vertical-to-horizontal wall conversion | It rewards geometry and falling speed rather than a legible input |
| GRACE-style corner clipping | It is inconsistent and luck-dependent by community description |
| GRACE-style sprint-release slide-cap removal | It hides the governing limit from the player |
| Doom-style collision rounding or wall-running | It depends on implementation accidents, not a stable contract |
| ULTRAKILL-style SSJ/wind-state speed stacking | It is a separate resource and timing system WindShear does not have |
| Collision projection that increases speed | It violates basic energy sanity and breaks level budgets |
| A Fracture module masking the core wall-kiss | It makes the base verb depend on optional code and creates two owners for one mechanic |

If one of these appears accidentally, the correct response is to characterize
it, reproduce it deterministically in a test, and decide whether to cap it.
The answer is not to add a hidden code path that rewards the sequence.

### 16.3 Fractures remain a separate system

`GAME_DESIGN.md` defines Fractures as deliberate, optional, stable mastery
paths. The core wall-kiss is already a named movement verb with locked
numbers. These are different categories.

The current `data/fractures.json` contains a `wall_kiss_chain` entry whose
trigger and effect duplicate the core wall-kiss. That is a release-blocking
ownership ambiguity:

- the core controller must always implement the normal wall-kiss;
- a Fracture must not own, gate, replace, or mask that core behavior;
- if the registry entry has shipped, its ID and route compatibility must be
  preserved and its effect must be redefined around a distinct optional
  behavior;
- if it has not shipped, the registry can be corrected before release,
  subject to the project's immutable-Fracture policy.

No registry or controller change is made by this research document because
the shipped/not-shipped status and the intended Fracture identity require a
explicit product decision.

---

## 17. Characterization and invariant tests

A movement accident needs two kinds of protection:

- a **hard invariant**, which fails the build if broken;
- a **characterization probe**, which reports a change so humans can decide
  whether it matters.

### 17.1 Hard invariants

| Test | Assertion | Why |
| --- | --- | --- |
| Airborne contribution | `air_bonus <= 2.2 m/s` during one airborne stretch | No unlimited air accumulation |
| Landing reset | `air_bonus == 0` on landing | One budget per jump, not one per frame |
| Plane | `velocity.z == 0` every tick | XY-only gameplay |
| Kiss count | A chain never exceeds 5 | Explicit move budget |
| Kiss ceiling | A wall-kiss boost never takes horizontal speed above 18 m/s | A full designed chain is allowed; farming is not |
| Collision energy | A wall contact cannot increase horizontal speed | No collision-created speed |
| Determinism | The same input sequence and initial state produce the same state sequence | Replay and ghost integrity |
| Fixed step | Gameplay advances in exactly 1/60 s ticks | Frame-exact routes |

These invariants are covered across
[`test_movement.gd`](../tests/test_movement.gd),
[`test_movement_characterization.gd`](../tests/test_movement_characterization.gd),
[`test_movement_discovery.gd`](../tests/test_movement_discovery.gd), and
[`test_determinism.gd`](../tests/test_determinism.gd).

### 17.2 Implemented characterization probes

The following probes are now explicit tests rather than assumptions:

| Probe | Assertion | Purpose |
| --- | --- | --- |
| Two-frame arming boundary | Contact and jump on each of frames 1, 2, and 3; only the first two arm | Catch an off-by-one window |
| Side-wall normal boundary | Test unit normals around `abs(z)=0.5`; front walls cannot arm the kiss | Preserve the route-parallel wall rule |
| Chain expiry boundary | The chain survives 29 kiss-free frames and expires on the 30th | Preserve the documented chain lifetime |
| Repeated landing/slide cycles | Run 100 slide-and-land cycles and report peak speed and air budget | Detect a hidden refill exploit |
| Repeated wall-kiss cycles | Run a full chain and 20 expired chains; report peak speed and chain count | Detect stale-count or ceiling farming |
| Direction-change fuzz | Run two seeded 5,000-tick legal input sequences; report peak speed, air budget, and kiss count | Characterize combinations not covered by named techniques |
| Collision normal sweep | Test head-on, 45-degree, grazing, and side-parallel unit normals | Verify only the into-wall component is removed |
| Replay hash | Record the complete controller state for 600 frames and compare two runs and their hashes | Detect hidden clocks, allocation-order effects, or unseeded randomness |
| Air-budget sign audit | Opposite-direction steering consumes budget while reducing speed; same-direction input at 14 m/s consumes none | Distinguish steering magnitude from speed creation |
| Air-budget landing reset | Consume one airborne budget, land, and verify it is zero before the next airborne stretch | Prevent a per-frame or per-jump refill |

The current bunny-hop promise — peak speed remains within `0.5 m/s` of a
plain run — is a good characterization invariant and should remain
([current probe](../tests/test_movement_discovery.gd#L173-L191)).

### 17.3 Remaining valuable probes

| Probe | Required setup | Purpose |
| --- | --- | --- |
| Corner/crease contacts | A live physics scene that can return multiple contact normals in one tick | Detect geometry-dependent energy gain |
| Fixed-step accumulator replay | An integration harness that runs the same input route at different render rates with a fixed accumulator | Prove render-rate independence in the running game |
| Core/Fracture isolation | A runnable Fracture runtime and a resolved `wall_kiss_chain` identity | Prevent optional modules from masking base movement |

These are deliberately not represented by synthetic unit tests that would
claim more than the harness can prove. The corner probe needs real crease
contacts; the accumulator probe needs the engine's render/physics boundary;
and Fracture isolation cannot be meaningful until the duplicate Fracture's
shipped status and intended identity are resolved.

### 17.4 What “bounded” should mean

There are two distinct bounds in WindShear and they should not be conflated:

1. **Mechanic ceiling:** 18 m/s for the wall-kiss chain.
2. **Discovery envelope:** 20.2 m/s for the current test probes.

The larger envelope exists so an unexpected combination is visible instead
of silently clipped by the test. If a future probe exceeds 18 m/s, it must be
reviewed: it may reveal a new legal interaction, an implementation bug, or a
missing global ceiling. The envelope should not be advertised as a player
speed.

---

## 18. Claims that should not be repeated as fact

| Claim | Assessment |
| --- | --- |
| “Quake/Source air speed is capped at 30 u/s” | **False as stated.** It caps the input-direction projection, not total velocity |
| “Later Source has about 60 u/s” | **Unverified.** No supporting source was found; not used |
| “GoldSrc's default `sv_maxspeed` is 320” | **Incorrect for the archived executable list.** It records 270; later configurations may differ |
| “Quake II has no air control” | **Too strong.** Strong air acceleration is off by default; weak coefficient-1 steering remains |
| “Quake III adds 2.56 u/s to total speed in one perpendicular tick at 320” | **Incorrect.** Magnitude becomes about 320.01024 u/s |
| “Doom's straight-run speed is 54.6875 u/s” | **Incorrect.** That number is a one-tic velocity-increment shorthand; equilibrium travel is about 583.33 map units/s |
| “Doom's diagonal speed is a hidden exploit” | **Misleading.** It follows directly from visible separate forward and side impulses |
| “GRACE has a known numeric slide soft cap” | **Unverified.** Current community pages expose qualitative behavior, not a reliable number |
| “Doom (2016) has zero air control” | **Not established.** Strong secondary evidence says ordinary significant air control is absent and a rune adds it |
| “The ULTRAKILL wiki is developer source” | **Incorrect.** It is community documentation; the decompilation is separately unofficial |
| “CPM's exact historical constants are the GPP values” | **Unverified.** Original CPMA source was not available; GPP is a derivative implementation |
| “A speed exploit should become a Fracture because Fractures are bugs” | **Wrong category.** Fractures are deliberate optional mechanics; core movement bugs are characterized and bounded as movement bugs |

---

## 19. Recommended movement direction

WindShear should preserve the current model:

1. **Bounded air steering.** A player can correct a line by up to 2.2 m/s
   of total airborne contribution. The amount is finite, visible in the
   tuning, and reset on landing.
2. **Explicit slide.** A fixed 27-frame state with fixed friction is easier
   to learn than a context-sensitive momentum cap.
3. **Explicit wall-kiss.** The two-frame window, fixed boost, five-kiss cap,
   and 18 m/s ceiling make the move a timing skill with a known payoff.
4. **Forgiveness that is measured in frames.** Coyote time and jump buffering
   improve execution without changing the underlying speed economy.
5. **A fixed simulation.** Route state, replay, and character testing depend
   on the 60 Hz contract.
6. **No deliberate speed-accumulation sequence.** If an angle, corner, frame
   order, or collision produces a repeatable gain, characterize it. Do not
   add it to the controller as a hidden mechanic.
7. **A separate Fracture namespace.** Fractures may add optional mastery
   around the core system, but they may not be required to make the core
   movement work.

This gives WindShear the best of the source material: Quake's readable
input-relative motion, Doom's honesty about visible impulses, GRACE's
learnable wall-move budget, and ULTRAKILL's legible timing windows—without
importing the classic engines' unbounded momentum exploits.

---

## 20. Sources

All source-code links below are pinned to the exact revisions examined.

### 20.1 Quake family

- [Quake 1 — `WinQuake/sv_user.c`, pinned revision](https://github.com/id-Software/Quake/tree/bf4ac424ce754894ac8f1dae6a3981954bc9852d)
- [QuakeWorld — `QW/client/pmove.c`, pinned revision](https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/QW/client/pmove.c)
- [QuakeWorld — `QW/server/sv_phys.c`, pinned revision](https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/QW/server/sv_phys.c)
- [Quake II — `qcommon/pmove.c`, pinned revision](https://github.com/id-Software/Quake-2/blob/372afde46e7defc9dd2d719a1732b8ace1fa096e/qcommon/pmove.c)
- [Quake II — `server/sv_init.c`, pinned revision](https://github.com/id-Software/Quake-2/blob/372afde46e7defc9dd2d719a1732b8ace1fa096e/server/sv_init.c)
- [Quake III — `code/game/bg_pmove.c`, pinned revision](https://github.com/id-Software/Quake-III-Arena/blob/dbe4ddb10315479fc00086f08e25d968b4b43c49/code/game/bg_pmove.c)
- [Quake III — `code/game/g_main.c`, pinned revision](https://github.com/id-Software/Quake-III-Arena/blob/dbe4ddb10315479fc00086f08e25d968b4b43c49/code/game/g_main.c)

### 20.2 GoldSrc and Source

- [Valve Half-Life SDK — published GoldSrc movement code, pinned revision](https://github.com/ValveSoftware/halflife/blob/b1b5cf5892918535619b2937bb927e46cb097ba1/pm_shared/pm_shared.c)
- [Archived Valve Developer Community Half-Life executable cvar list](https://web.archive.org/web/20251220074152id_/https://developer.valvesoftware.com/wiki/List_of_Half-Life_console_commands_and_variables)
- [VDC cvar-list permanent revision 431607](https://developer.valvesoftware.com/w/index.php?title=List_of_Half-Life_console_commands_and_variables&oldid=431607)
- [Source SDK 2013 — movement cvars, pinned revision](https://github.com/ValveSoftware/source-sdk-2013/blob/3e957b70b167929f120360115d359d1ecb4c1699/src/game/shared/movevars_shared.cpp)
- [Source SDK 2013 — `CGameMovement`, pinned revision](https://github.com/ValveSoftware/source-sdk-2013/blob/3e957b70b167929f120360115d359d1ecb4c1699/src/game/shared/gamemovement.cpp)
- [Source SDK 2013 — Half-Life 2 player speeds, pinned revision](https://github.com/ValveSoftware/source-sdk-2013/blob/3e957b70b167929f120360115d359d1ecb4c1699/src/game/server/hl2/hl2_player.cpp)

### 20.3 CPM

- [GPP-1-1 CPM-derived reimplementation, pinned revision](https://github.com/ZdrytchX/GPP-1-1/tree/6bde6e8278f270c147b182d8c0c0cf137cedf814)

### 20.4 Doom

- [Original Doom source, pinned revision](https://github.com/id-Software/DOOM/tree/a77dfb96cb91780ca334d0d4cfd86957558007e0)
- [Doom Wiki — Player data and established speed table](https://doomwiki.org/wiki/Player)
- [Doom 3 source, pinned revision](https://github.com/id-Software/DOOM-3/tree/a9c49da5afb18201d31e3f0a429a037e56ce2b9a)
- [Doom Wiki — Rune (Doom 2016)](https://doomwiki.org/wiki/Rune_(Doom_2016))
- [Doom Wiki — Rune trial passage](https://doomwiki.org/wiki/Rune_trial_passage)
- [Doom Wiki — Delta V jump-boots](https://doomwiki.org/wiki/Delta_V_jump-boots)

### 20.5 GRACE

- [Official Roblox listing — Grace](https://www.roblox.com/games/138837502355157/Grace)
- [Official Roblox Games API — universe 6508759464](https://games.roblox.com/v1/games?universeIds=6508759464)
- [GRACE community wiki — Movement](https://grace-rbx.fandom.com/wiki/Movement)
- [GRACE Miraheze wiki — Mechanics revision 27998](https://grace.miraheze.org/wiki/Mechanics?oldid=27998)

### 20.6 ULTRAKILL

- [Official Steam news archive](https://store.steampowered.com/oldnews?appgroupname=ULTRAKILL&appids=1229490)
- [Official Fraud Hotfix #2 announcement entry](https://steamcommunity.com/games/1229490/announcements/detail/498351387739950731)
- [Community Movement wiki revision 35179](https://ultrakill.wiki.gg/wiki/Movement?oldid=35179)
- [Movement wiki revision 35179 through the MediaWiki API](https://ultrakill.wiki.gg/api.php?action=query&prop=revisions&revids=35179&rvprop=ids%7Ctimestamp%7Ccontent&rvslots=main&format=json)
- [Unofficial ULTRAKILL 17d4 decompilation, pinned revision](https://github.com/SmolFlexan/ULTRAKILL/tree/3ac66af8ebf0ef3ff2b813243da15576c015dfc8)
