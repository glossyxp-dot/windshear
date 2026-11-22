# The Concord

The antagonist, written down properly. `GAME_DESIGN.md` §1 has the short
version, this is the long one.

## What it actually is

The Concord is a machine that people built. A biomechanical siege organism,
dropped on the cities during the Fracture Year by a high command that was
watching a global war run out of road.

It was not designed to rule a planet. It was designed to stop one war, and it
did that, and then nobody switched it off. War casualties went to zero. The
cost was the sky.

Twenty years on it occupies every surface city directly and holds the upper
atmosphere beneath a canopy of its own tissue. The canopy is not a roof and
not a shield. It is a lung, and it breathes the sky into the city and the
city's exhaust back out, and nobody outside has seen the sun since the day it
closed.

It has no face and no ego. It talks through PA chimes, klaxons, street
displays and schedule boards:

> CONTAINMENT COMPLETE. ZERO ACTIVE COMBATANTS. REMAIN IN ASSIGNED SECTOR.

> Carrier deviation recorded. Recovery route authorized.

> Atmospheric canopy closing. No traffic is scheduled above the last regulation layer.

It never explains itself and never argues its case, because it doesn't know it
has one. The moral argument belongs to the player. The game doesn't settle it.

## What it enforces

Three rules, and every denial in the game comes from one of them.

**Crossing sector walls is forbidden.** People live in Quarantine Blocks on the
surface, sealed off from each other by walls of concrete and chitin. Rations
are delivered, streets are patrolled, the central Spire looms over the fog.
People inside a block are fed and kept safe and never asked to leave.

**Climbing toward the canopy is forbidden.** The canopy is the last regulation
layer. There is no traffic above it.

**Carrying unapproved hardware or data between blocks is forbidden.** No radio
transceivers, no memory drives, no tools that aren't on the manifest.

The reason is the same reason for all three. The Concord was built to stop
human factions from coordinating a second war, and the thing that stops
factions coordinating is making sure they never meet.

## The growth

Where concrete tore in the fighting, it grew. What came out is called a
**Grown Seam** in the field: living scar tissue that runs warm, deforms
underfoot and bleeds when you scrape it. Where industrial vents froze, it
grew collars. Where a blast door's track warped, it grew a way to keep the
door sliding.

None of it is alive in any way a person would recognise. It doesn't want
anything. It closes gaps because closing gaps is what it was told to do, and
it was told to do that by something that is still, at the top, a piece of
military automation executing its last standing order.

Down in the spine basement you can see it. Warm pillars that aren't pillars
any more. Dark fluid where the rebar pushes through. A soft edge where a blast
door used to meet concrete. It's the ugliest thing in the game and it is still,
technically, a repair log.

## How it fights you

It doesn't fight. It denies ground. Four answers, and every one of them is a
shape rather than a fight.

**The scheduled gate.** The ordinary case. It opens and closes on a timetable,
the timetable is published, and a player who memorises it can walk through.
This is bureaucracy, and in Act I it's all you get.

**Quarantine Bulkheads.** A living blast door that decides to close while
you're underneath it. The sound arrives before the door does, which is the
tell. The counter was never "beat it", it's "be somewhere else when it moves",
and the honest counter is having read the schedule two rooms earlier. The door
is the Concord's offence, so Act V has the player running away from the system
rather than towards a goal, and it should feel exactly that way.

**Purge and Sterilization Protocols.** When an intruder gets logged in a
restricted zone the sector floods. Barbed chitin walls extend. Superheated
exhaust vents open. Air shafts seal. It's the loudest thing in the game and it
is always announced first: a bulletin, a warning tone, the floor lights going
red. It never kills you outright. It makes the sector a worse place to be, and
you leave.

**Interdiction nodes.** Stationary. A turret on a bridge, a snare tendril in a
lift shaft, something anchored across the canopy arms. They cover a fixed arc
and they hold it. Every one of them watches a route you wanted, and every one
of them leaves a gap you can read in about a second and a half.

And in Act IV there's the **grown seam**, which is the Concord's own patching
acting like a hazard. It deforms under a body instead of breaking, so it
slows you differently. It's the only threat in the game the Concord didn't
build on purpose, and it's the reason the threat model stops working in the
last third of the campaign.

## The blind spot

Every defence above was built against a slow infiltrator or a demolition team.
Chokepoints, blast doors, sensor grids, bio-constructs on fixed lines. All of
it assumes somebody is going to creep up to a seam and try to cut through it.

Nobody designed it for somebody who crosses at fourteen metres a second
because the route gives them no other choice.

Wind isn't illegal either. Nobody thought to make it illegal. It's just the
one thing in the city that moves faster than a door can close.

## Why it goes after Lancer

Lancer is a courier. Licensed to run approved manifests inside one block, paid
to carry what the schedule lists. Lancer carries what the schedule doesn't:
messages, radio transceivers, memory drives, whatever one block needs to hear
from another.

A courier reconnecting isolated populations looks exactly like a command
network forming. That's the shape of threat it was built to stop, and that's
the shape Lancer keeps accidentally being.

It doesn't care that Lancer is fast. It cares what Lancer is carrying, and
where.

## How it escalates

Gates per section go up with the acts and the schedule slows down as it goes.
That's the whole difficulty curve of the threat model and it lives in the data
rather than in a hand-tuned table.

| Act | Gates per section | What you're reading |
| --- | --- | --- |
| 0 — The Fracture Year | 1 | Nothing yet. The Concord is still arriving |
| I — The Block | 1 | One schedule |
| II — The Under-City | 1–2 | One schedule and a bulkhead on a second cycle |
| III — The Spine | 2–3 | Two schedules, and freight moving on a third |
| IV — The Yard | 2–3 | Schedules plus hazards that aren't on a schedule |
| V — The Core | 3 | Three at once, and the slow one guards the good route |
| VI — Open Weather | 4 | Everything, on four cycles |

`data/schedule.json` holds the windows. A cycling gate's state is resolved from
the global schedule frame and the gate's phase offset, so two gates on
different periods open at different moments and by Act VI you're holding three
of them in your head at once. The speedrun line is the one that assumes you
can.

## The people inside it

**THE CONCORD.** The organism. No face, no ego, no motive beyond the order.
It speaks in containment logs and it never explains itself. Not a villain with
a grudge. A machine with a standing order, and the order is twenty years out
of date.

**Warden Saye** (she/her). Human containment enforcement. In the prequel she's
a young logistics officer watching the war spiral and waving runners through
breaches. Twenty years later she's the administrator who signed the isolation
accords, exhausted, certain that the cage is the only way humanity survives.
She's the only one who argues. Lancer doesn't argue back. Lancer runs.

**Ilsa Renn** (she/her). A scientist now, and the original First Runner. She
was a military dispatch runner during the Fracture Year and she is the courier
whose breach the Concord built itself around. These days she studies movement
data, she noticed what Lancer could do, and she brought Lancer to the team.
She isn't Lancer's teacher. She isn't going to train them either.

**FIRST RUNNER.** The designation the Concord gives Ilsa's recorded movement
profile. For twenty years it has been running her route as a patrol training
model, against every courier it can see, and it still hasn't caught up.

## Three rules

So the argument can't drift into a straight fight:

1. The Concord is human made. Even the parts that grew.
2. Both sides have killed people. The Concord's record isn't clean and the
   endings only work if it isn't.
3. Lancer doesn't fight it. Lancer crosses it.

Break one of those and it isn't a balance patch. It's a different game.
