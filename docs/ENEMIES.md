# The enemy roster

Everything the Concord puts between Lancer and the sky.

The roster is data, in `data/enemies.json`. `tests/test_canon.gd` checks the
availability rules against the acts and checks that the main-game threat never
turns up in a Fracture Year chapter. The short version is in
`GAME_DESIGN.md` §10.

---

## The rule

**Area denial, not a shooting gallery.** The Concord doesn't fight Lancer. It
denies the ground, one room at a time. The level closes, the route changes,
and the run turns into a question of where you were going to be in two
seconds.

Every enemy below is built to be *readable* before you commit to it: its
patrol, its charge, its arc and its wind-up are all visible before they hurt
you. The Concord's whole design assumption is that a threat arrives slowly
enough to be avoided. The trick of the game is that you arrive faster.

---

## The Fracture Year

**Concord military infantry, artillery and synths do not exist in the
prequel.** The Concord is still arriving in those chapters, and what it has
brought with it is biology, not soldiers.

### Concord Dartbug — chaser / swarm
Fast, early-generation bio-construct that rushes in packs and stabs for 10 HP.
Easily killed with the P-20 "Courier" or the V-9 "Vigil". No drop: they come
in numbers, and a pack is an aim check and a momentum check at the same time.

### Concord Ram — chokepoint anchor / juggernaut
A slow, four-legged chitin-armoured bio-construct branched from the original
organism. It locks exclusively onto the player and is nearly invincible to
bullets. Almost everything about it is a problem except the one thing that
isn't: it is heavy, it commits to a line, and it cannot turn quickly.

**Counterplay:** avoid it completely, lure it into pits or craters, collapse
floors under it with an M-44 "Seam-Splitter" as Ilsa, or shatter it head-on
at 100 m/s as Lancer.

**Drop:** chitin shards, or an overcharge spark. Shattering a Ram at 100 m/s
grants Lancer 25 points of decaying overheal.

### Concord Stifler — toxic / hazard
A bloated containment construct grown out of a ruptured Grown Seam. It is
slow and it is obvious, and the fight is not the problem.

**Death effect:** a caustic coolant pool, 5 HP a second, on the floor and the
walls. It kills slide friction, which means the section after the Stifler is
slower and more precise than the one before it.

---

## The present day, first half

The Concord has had twenty years to hire, to manufacture, and to take notes
on couriers.

### Concord Trooper — tactical baseline / infantry
Standard enforcement soldiers patrolling checkpoints and alleys in squads,
with V-9 "Vigil" SMGs and timed fragmentation grenades.

**Drop:** 9mm magazines, fragmentation grenades, and the occasional Field
Ration worth 15 HP.

They are the baseline. Expect them, flank them, and do not let a grenade pin
the route.

### Napalm Mortar — area denier
Arcing incendiary artillery crews locking down high ground, rooftops and
cover lanes with lingering fire. The mortar is not the target; the crew is.

**Drop:** an incendiary fuel canister, which can be thrown or shot as a
fire-bomb if the crew is killed before it fires.

### Concord Overwatch — sniper / roof watcher
A high-perch marksman with an M98 "Longhorn" Carbine and a visible cyan
targeting laser. Forty-five HP a hit, which is most of a health bar, so the
laser is the warning and the laser is always visible.

**Drop:** 7.62mm marksman clips and EMP / Signal Scrambler Flares.

### Concord Diver — chaser / rusher
Pneumatic-legged bio-constructs that fire compressed air from their leg vents
to vault gaps and chase Lancer onto rooftops. Twenty HP a strike, and it
arrives from above, which breaks the habit of watching the floor.

**Drop:** a pressurised pneumatic cell. It restores 15 points of decaying
overheal and resets the Filament cooldown.

### Concord Jammer — disruptor
A heavy spider-legged tripod projecting a static-air sphere that cancels
thermals and jams Filament lock-ons until its rear pressure core is
destroyed. The sphere is the problem, so the core is the target: the M98
handles it from range, the L-01 from close.

**Drop:** a regulator capacitor core, which recharges the L-01 or triggers a
brief updraft.

### Warp Synth — sniper / armoured anchor
A durable 200 HP post-Concord synth that relocates slowly, digs itself into
the ground to anchor, charges a readable lock-on and fires hyper-fast
projectiles. **Immune to bullets.**

It takes explosives: the AT-7 "Goliath" or the L-01 "Arc-Lance". Or a route
it is not watching, which is cheaper.

**Drop:** a high-energy core that fully restores 100 HP and 150 max overheal,
and AT-7 rockets.

---

## The present day, second half

Acts III to VI. The Concord stops policing blocks and starts defending the
machine.

### Concord Special Defense Operations Trooper — elite guard / strike coordinator
Heavy elite containment troops stationed in high-security zones like the
Concord Monolith, once Lancer has planetary significance. They coordinate
squad tactics and direct air support, so the squad is the target.

**Drop:** a heavy armour med-injector worth 35 HP, 7.62mm marksman clips,
and strike targeter beacons used to jam or redirect air strikes.

### Concord C-01 "Scatter" — air-to-ground area denier
A low-altitude defence gunship, directed by an SDO Trooper. It saturates
ground lanes, streets and rooftops with cluster napalm, which forces Lancer
off the floor and onto the walls: wall-kisses and Filament tethers.

**Drop:** none. It is driven off by eliminating the directing SDO Trooper, or
by hitting it with the AT-7 "Goliath" or the L-01 "Arc-Lance".

---

## The drops, in one table

| Enemy | Drops |
| --- | --- |
| Concord Dartbug | Nothing |
| Concord Ram | Chitin shards, overcharge spark |
| Concord Stifler | Caustic coolant pool |
| Concord Trooper | 9mm magazines, fragmentation grenades, occasional Field Ration (+15 HP) |
| Napalm Mortar | Incendiary fuel canister |
| Concord Overwatch | 7.62mm marksman clips, EMP flares |
| Concord Diver | Pressurised pneumatic cell (+15 overheal, Filament cooldown reset) |
| Concord Jammer | Regulator capacitor core |
| Warp Synth | High-energy core (full HP and full overheal), AT-7 rockets |
| Concord SDO Trooper | Heavy armour med-injector (+35 HP), 7.62mm clips, strike targeter beacons |
| Concord C-01 "Scatter" | Nothing |

---

## What is not an enemy

The Concord's area denial is not on this list, because it is not a creature:
it is a **scheduled gate**, a **Quarantine Bulkhead**, a **Purge and
Sterilization Protocol** and an **Interdiction Node**. Those are in
`GAME_DESIGN.md` §10 and in `docs/CONCORD.md`, and they are the actual
antagonist. The creatures are the Concord's hands.
