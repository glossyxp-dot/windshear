# The Concord

Everything about the antagonist that isn't a number. `GAME_DESIGN.md` §1 has
the short version; this is the long one.

---

## What it is

The Concord began as software. A city-scale operating system that reads
atmospheric sensors, decides where the wind is allowed to go, and opens the
gates on a schedule. That part is still software. It still runs on a schedule.
It still files its logs.

Then the Fracture Year happened, and the Concord started fixing itself.

It patched itself by growing. Where a structural seam tore open in the
Fracture Year, the Concord laid down a new joint — softer than the concrete
around it, faintly warm, faintly wet. Where a blast door's track warped, it
grew a collar to keep the door sliding. After twenty years of that, the
original structure is more scaffold than wall in half the under-city.

None of it is alive. That matters, and the game is careful about it. The
growth does not want anything. It has no voice, no face, no intent. It closes
gaps because closing gaps is what it was told to do, and it was told to do that
by a system that is still, at the top, a piece of scheduling software with a
maintenance vocabulary.

The only thing anyone in the story calls it alive is Lancer, and she calls it
the patched thing, which is a complaint and not a diagnosis.

THE CONCORD speaks the way a system speaks. It doesn't address anyone. It
issues bulletins, schedule updates and recovery notices:

> Carrier deviation recorded. Recovery route authorized.

> Year Zero. Atmospheric regulation offline at 04:12. All city districts
> unsealed. No recovery schedule exists.

> Structural patching is within the maintenance mandate. No further comment.

It never explains itself and it never justifies itself, because a scheduling
system doesn't know it has a case to make. The moral argument is the player's,
not the Concord's, and the game never settles it.

---

## The blocks

After the Fracture Year the city was cut into **quarantine blocks** — sealed
districts, closed so that no two of them could coordinate a second one. People
live inside them. The Concord feeds them, schedules their gates, and forbids
anyone crossing a sector line carrying anything the schedule doesn't list.

The block boundaries are the game's map of its own story. Act I is one block,
morning through dusk. Act III is the freight corridors that run between
blocks, and the wall in Chapter 12 is the first one Lancer crosses on screen.
Act V is inside the Concord itself.

Some blocks have been closed so long that the outside schedules stopped
updating them. There are whole districts the Concord still feeds and no longer
counts.

---

## Why it hunts Lancer

Not for being fast. It doesn't care about speed at all, and this is the piece
of the design that has to stay exactly where it is.

The Concord was built to stop people coordinating across the blocks. A courier
moving physical things — a parcel, a tool, a memory drive — between districts
that are not allowed to know about each other is precisely the shape of thing
it was built to stop. Lancer looks like command-and-control forming, because
on the Concord's reading of the Fracture Year, that is what it was.

Its sensors are built for that threat too. Chokepoints, blast doors, sensor
grids, patrols on fixed lines. All of it assumes someone is going to creep up
to a seam and try to cut through it.

Nobody designed it for somebody who crosses at fourteen metres a second
because the route gives them no other choice.

---

## What it does when it finds you

The Concord doesn't fight. It denies ground. Four responses, and every one of
them is a shape rather than a fight.

**The scheduled gate.** The ordinary case. It opens and closes on a timetable,
the timetable is published, and a player who memorises it can walk through.
This is bureaucracy, and in Act I it is all you get.

**The bulkhead.** A blast door that decides to close while you're under it.
The sound arrives before the door does, which is the tell. The counter is
never "beat it" — it is "be somewhere else when it moves", and the honest
counter is to have read the schedule two rooms ago. The door is the
Concord's offence, so the player spends Act V running away from the system
rather than towards a goal, and it should feel exactly that way.

**The purge protocol.** When an intruder is logged in a restricted zone, the
sector floods. Gantries extend. Vents seal. Drones deploy. It's the loudest
thing in the game and it is always announced first — a bulletin, a warning
tone, the floor lights going red. It never kills you outright; it makes the
sector a worse place to be, and you leave.

**Interdiction nodes.** Stationary. A turret on a bridge, a snare-tendril in a
lift shaft, something anchored across the canopy arms. They cover a fixed arc
and they hold it. Every one of them watches a route you wanted, and every one
of them leaves a gap you can read in about a second and a half.

And in Act IV, the **grown seam** — the Concord's own patching, which acts
like a hazard and reads like a wound. It deforms under a body instead of
breaking, so it slows you differently. It is the only threat in the game that
the Concord did not build on purpose, and it is the reason the threat model
stops working in the last third of the campaign.

---

## The escalation

The number of gates in a section rises with the acts, and the schedule
slows down as it rises. That is the whole difficulty curve of the threat model,
and it's in the data rather than in a hand-tuned table:

| Act | Gates per section | What the player is reading |
| --- | --- | --- |
| I — The Block | 1 | One schedule |
| II — The Under-City | 1–2 | One schedule, plus a bulkhead on a second cycle |
| III — The Spine | 2–3 | Two schedules, and freight that moves on a third |
| IV — The Yard | 2–3 | Schedules plus hazards that are not on a schedule |
| V — The Core | 3 | Three at once, and the slow one guards the good route |
| VI — Open Weather | 4 | Everything, on four cycles |

`data/schedule.json` holds the windows. A cycling gate's state is resolved
from the global schedule frame and the gate's phase offset, so two gates on
different periods produce different openings at the same moment, and the
player has to be holding three of them in their head at once by Act VI. The
speedrun line is the one that assumes they can.

---

## The people inside it

**THE CONCORD.** The system. No body, no avatar, no face. It speaks in
bulletins and it never explains itself. It is not a villain with a motive; it
is a machine with a mandate, and the mandate is twenty years out of date.

**Warden Saye.** Concord enforcement. Believes the cage is mercy. Not a
tyrant — a person who signed the order that closed the city, who still
believes the signature was right, and who is far more tired than she is
certain. She is the only one who argues. Lancer doesn't argue back; she runs.

**Ilsa Renn.** A smuggler who taught Lancer to run. Alive, complicit,
recurring. She's the one who says out loud the things the game would rather
you worked out.

**FIRST RUNNER.** The name the Concord gives to whoever caused the Fracture
Year. Lancer's mentor. Late, and not what anyone expected: the Concord has
been running Lancer's training data for twenty years, and it has been
learning from the parts she was proud of.

---

## What stays fixed

Three rules, so the argument can't drift into a straight fight:

1. The Concord is human-made. Even the parts that grew.
2. Both sides have killed people. The Concord's record is not clean, and the
   game's endings only work if it isn't.
3. Lancer doesn't fight it. She crosses it.

If a future change breaks one of those, it's not a balance patch, it's a
different game.
