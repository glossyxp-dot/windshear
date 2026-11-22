# The Concord

The antagonist, written down properly. `GAME_DESIGN.md` §1 has the short
version, this is the long one.

## What it actually is

The Concord started as software and the top of it is still software: a
scheduling system with a maintenance vocabulary and no face. It reads
atmospheric sensors, decides where the wind is allowed to go, opens gates on a
timetable, and files logs.

Then the Fracture Year happened and it started fixing itself.

It patched itself by growing. Where a structural seam tore open it laid down a
new joint, softer than the concrete around it, faintly warm, faintly wet.
Where a blast door's track warped it grew a collar so the door would keep
sliding. Twenty years of that and, in half the under-city, the original
structure is more scaffold than wall.

None of it is alive. That matters and the game is careful about it. The growth
doesn't want anything. It has no voice, no face, no intent. It closes gaps
because closing gaps is what it was told to do, and it was told to do that by a
system that is, at the top, still a piece of scheduling software with a
maintenance vocabulary.

The only person in the story who calls it alive is Lancer, and what she calls
it is the patched thing, which is a complaint and not a diagnosis.

THE CONCORD talks like a system talks. It doesn't address anyone. It issues
bulletins:

> Carrier deviation recorded. Recovery route authorized.

> Year Zero. Atmospheric regulation offline at 04:12. All city districts
> unsealed. No recovery schedule exists.

> Structural patching is within the maintenance mandate. No further comment.

It never explains itself and never argues its case, because a scheduling system
doesn't know it has one. The moral argument belongs to the player. The game
doesn't settle it.

## The blocks

After the Fracture Year the city was cut into quarantine blocks: sealed
districts, closed so that no two of them could coordinate a second one. People
live inside them. The Concord feeds them, schedules their gates, and forbids
anyone crossing a sector line carrying anything the schedule doesn't list.

The block boundaries are the map of the story. Act I is one block, morning
through dusk. Act III is the freight corridors between blocks, and the wall in
Chapter 12 is the first one Lancer crosses on screen. Act V is inside the
Concord itself.

Some blocks have been closed so long that the outside schedules stopped
updating them. There are whole districts the Concord still feeds and no longer
counts.

## Why it goes after Lancer

Not for being fast. It doesn't care about speed at all, and that part of the
design has to stay exactly where it is.

The Concord was built to stop people coordinating across the blocks. A courier
moving physical things, a parcel, a tool, a memory drive, between districts
that aren't allowed to know about each other is precisely the shape of thing
it was built to stop. Lancer looks like command and control forming, because
on the Concord's reading of the Fracture Year that's what it was.

Its sensors are built for that threat as well. Chokepoints, blast doors, sensor
grids, patrols on fixed lines. All of it assumes somebody is going to creep up
to a seam and try to cut through it.

Nobody designed it for somebody who crosses at fourteen metres a second because
the route gives them no other choice.

## What it does when it finds you

It doesn't fight. It denies ground. Four answers, and every one of them is a
shape rather than a fight.

**The scheduled gate.** The ordinary case. It opens and closes on a timetable,
the timetable is published, and a player who memorises it can walk through.
This is bureaucracy, and in Act I it's all you get.

**The bulkhead.** A blast door that decides to close while you're underneath
it. The sound arrives before the door does, which is the tell. The counter was
never "beat it", it's "be somewhere else when it moves", and the honest counter
is having read the schedule two rooms earlier. The door is the Concord's
offence, so Act V has the player running away from the system rather than
towards a goal, and it should feel exactly that way.

**The purge protocol.** When an intruder gets logged in a restricted zone the
sector floods. Gantries extend. Vents seal. Drones deploy. It's the loudest
thing in the game and it is always announced first: a bulletin, a warning
tone, the floor lights going red. It never kills you outright. It makes the
sector a worse place to be, and you leave.

**Interdiction nodes.** Stationary. A turret on a bridge, a snare tendril in a
lift shaft, something anchored across the canopy arms. They cover a fixed arc
and they hold it. Every one of them watches a route you wanted, and every one
of them leaves a gap you can read in about a second and a half.

And in Act IV there's the **grown seam**, which is the Concord's own patching
acting like a hazard. It deforms under a body instead of breaking, so it
slows you differently. It's the only threat in the game the Concord didn't
build on purpose, and it's the reason the threat model stops working in the
last third of the campaign.

## How it escalates

Gates per section go up with the acts and the schedule slows down as it goes.
That's the whole difficulty curve of the threat model and it lives in the data
rather than in a hand-tuned table.

| Act | Gates per section | What you're reading |
| --- | --- | --- |
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

**THE CONCORD.** The system. No body, no avatar, no face. It speaks in
bulletins and never explains itself. Not a villain with a motive. A machine
with a mandate, and the mandate is twenty years out of date.

**Warden Saye.** Concord enforcement. Believes the cage is mercy. Not a
tyrant, a person who signed the order that closed the city, who still thinks
the signature was right, and who is far more tired than she is certain. She's
the only one who argues. Lancer doesn't argue back. She runs.

**Ilsa Renn.** A smuggler who taught Lancer to run. Alive, complicit,
recurring. She's the one who says out loud the things the game would rather
you worked out for yourself.

**FIRST RUNNER.** The name the Concord gives to whoever caused the Fracture
Year. Lancer's mentor, and it lands late. The Concord has been running
Lancer's training data for twenty years and has been learning from the parts
she was proud of.

## Three rules

So the argument can't drift into a straight fight:

1. The Concord is human made. Even the parts that grew.
2. Both sides have killed people. The Concord's record isn't clean and the
   endings only work if it isn't.
3. Lancer doesn't fight it. She crosses it.

Break one of those and it isn't a balance patch. It's a different game.
