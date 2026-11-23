# The arsenal

What Lancer and Ilsa can carry, what it does, and where it comes from.

The numbers in here are canon and they live in `data/arsenal.json`.
`tests/test_canon.gd` reads that file, checks the availability rules against
the acts, and checks that every weapon, item and character in it is named in
`GAME_DESIGN.md`. If the document and the data stop agreeing, the build fails.

---

## Why there are guns at all

Movement first, guns second. A weapon solves a problem the movement
vocabulary can't: the Warp Synth has 200 HP and is immune to bullets, the
Concord Ram is nearly invincible to gunfire and locks onto the player, and
those two are not going to be outrun. Everything else, Lancer can do with a
wall.

So the guns are deliberately small. There are seven, they're all real weapons
from the war or from the Concord, and none of them is a machine gun that
solves a room by itself. The V-9 "Vigil" is loud enough to be a liability.
The M98 "Longhorn" is a rifle that wants a sightline, which is the opposite
of a speedrunner's route.

## Who carries what

| | Ilsa Renn (prequel) | Lancer Ivanov (present day) |
| --- | --- | --- |
| P-20 "Courier" | ✓ | ✓ |
| V-9 "Vigil" | ✓ | ✓ |
| M98 "Longhorn" | ✓ | ✓ |
| M-44 "Seam-Splitter" | ✓ | — |
| K-12 "Key" | — | ✓ |
| AT-7 "Goliath" | — | ✓ |
| L-01 "Arc-Lance" | — | ✓, from Act III |

The M-44 is a prequel weapon because the modern Concord grew past demolition
charges: by the present day its own body is the obstacle, and you break it
with speed instead.

---

## The weapons

### P-20 "Courier" — service pistol, 9mm

The standard-issue 20XX dispatch runner sidearm. Lightweight, accurate, and
the gun every runner carries and every runner forgets about until it isn't
there.

It works on Dartbugs, switches, valves and anything unarmoured. It does not
work on chitin. Nine millimetre ammunition is shared with the V-9, so the two
guns never compete for the same belt, which matters when you are carrying
both.

### V-9 "Vigil" — 9mm containment SMG

Named after the Concord's Vigilance Protocols, which is the sort of thing a
bureaucracy does with a gun. Compact, chambered in 9mm, and built for exactly
the fight the Concord expects: four troopers in a corridor.

It's the loudest common weapon in the game, and the Concord logs noise.
Firing a V-9 is a decision about the next two minutes as much as about the
next two seconds.

### M98 "Longhorn" — designated marksman carbine, 7.62mm

Semi-automatic, developed by the pre-war defence contractor attached to the
Longhorn Biological Facility. The name is the facility's, which is either a
coincidence or the most expensive joke in the story.

It's for long sightlines: a Napalm Mortar crew on a roof, an Overwatch
marksman on a gantry, and the rear pressure core of a Concord Jammer that's
looking the other way. It hits the Jammer core because the sphere is the
problem and the core is the only part you can actually shoot.

### M-44 "Seam-Splitter" — breaching charge, prequel only

A magnetic 20XX demolition brick. It opens collapsed concrete, opens welded
airlocks, and drops a weakened floor out from under a charging Concord Ram,
which is the prequel's answer to a problem the present day answers with a
hundred metres a second.

Ilsa carries these. Lancer cannot: the Concord's grown shell doesn't take the
charge.

### K-12 "Key" — 12-gauge flechette shotgun, present day

A sawed-off pump-action breach shotgun loaded with hardened steel flechettes.
It shreds chitin armour and Concord Divers at point-blank range, under eight
metres. Outside eight metres it's a very loud stick, and the name is because
it opens things: a lock, a door, a shell of a chitin plate.

### AT-7 "Goliath" — anti-tank rocket launcher, present day

A heavy 20XX rocket launcher. The only thing in the ordinary arsenal that
cracks a 200 HP Warp Synth or a reinforced barricade.

It's also the loudest thing Lancer can carry, and the Concord logs the noise.
The Warp Synth doesn't care about the noise; the rest of the level does.

### L-01 "Arc-Lance" — rail emitter, second half only

A prototype electromagnetic tungsten-slug accelerator, salvaged from the
Concord Monolith and assembled by Henrik Solberg out of regulator parts. It
pierces a Jammer's static-air sphere and damages a Warp Synth, and it's the
reason the second half of the campaign sounds different.

It arrives late on purpose. The first half of the present day is a courier
story with a gun in it; the second half is a siege, and the Arc-Lance is the
sound of a siege.

---

## The usable items

**Field Ration / Trauma Kit** restores 25 HP, capped at the 100 HP base. It
won't push you over the base into overheal; that's what the momentum and the
Ram kills are for. A Trauma Kit is the same thing by hand, and a Concord
Med-Dispenser drops one.

The **Adrenaline Stim-Pen** is main game only. It clears movement slow
effects, the most common of them being the Concord Stifler's coolant drag,
and triggers 25 points of decaying overheal for 10 seconds. A pen is 10
seconds of being above the cap and a Stifler pool is 5 HP a second of not
sliding.

The **EMP / Signal Scrambler Flare** is main game only, and it's thrown rather
than aimed. It blinds sensor pylons, scrambles Warp Synth lock-on charges for
3 seconds, and delays Quarantine Bulkhead timers. Three seconds is enough to
cross a sensor arc and not enough to fight in it.

The **Thermal-Foil Cloak** works in both halves. It's a courier poncho that
masks body heat from automated scanners while you're crouched or moving below
8 m/s, and it breaks the instant Lancer sprints, slides or fires. Eight
metres a second is the line and the cloak doesn't care why you crossed it.

The **Pneumatic Grapple Spool** is prequel only. A heavy 20XX military rescue
line, from before the Filament tether existed. It gets Ilsa up the Spire and
down it again, and it's why the prequel climbs feel different from the present
day: the spool is slow, heavy and committed, where the Filament is fast, light
and precise.

---

## The map utilities

These are built into the level, not carried. They're the Concord's own
infrastructure, repurposed.

**Pneumatic Parcel Chutes** are rusted vacuum tubes built into alleys and
stations. Lancer deposits smuggled drives and relays mid-run. A parcel in a
chute is a parcel in another block, and the chute decides how fast.

The **Concord Med-Dispenser** is a wall-mounted stainless-steel unit that
dispenses a Field Ration worth 25 HP. It was unlocked in 20XX. In the present
day it has to be cracked open with a cipher key or with gunfire, and gunfire
sets off a local patrol chime, so the medication costs you a patrol.

**Pressure Valves** are heavy industrial wheel-valves on Wind Regulators and
Ventworks pipes. They vent scalding steam onto patrols, or open a
high-velocity thermal. A valve is a weapon that nobody thinks to shoot back.

**Coolant & Fuel Barrels** are pressurised steel drums that detonate when
shot or kicked into a hazard, damaging Warp Synths or collapsing walkways
under Concord Rams. The barrel under the thing you can't kill is the barrel
that matters.

**Hardline Terminals** are exposed junction boxes wired into Quarantine
Bulkheads and Interdiction Nodes. Keyed, they override the local area denial
for 15 seconds. Fifteen seconds of the Concord not enforcing its own rules,
and then it does again.
