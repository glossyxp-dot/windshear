# Controls

The defaults, and why they are what they are.

---

## The short version

| | |
| --- | --- |
| Walk forward / back | `W` / `S` |
| Strafe left / right | `A` / `D` |
| Slide | `Ctrl` |
| Jump | `Space` |
| Wall-jump | jump while sliding against a wall |
| Ledge grab | `Q` |
| Interact | `E` |
| Filament | `F` |
| Primary fire | left mouse button |
| Alt fire | right mouse button |
| Camera | the mouse |

The wall-jump chain is three long. Slide into a wall, press jump on the frame
you touch it, and you get a boost and a launch. Do it three times in a row
and the chain is done. The `wall_kiss_chain` Fracture takes it to five, which
is where the old 18.0 m/s ceiling went. The movement research calls this
move the wall-kiss; it's the same thing.

## Why the mouse does the camera and nothing else

The mouse is the camera, so the mouse is already in the hand that is pointing
at the thing you want to shoot. The triggers go there too. Everything the
player does with their left hand is on the keyboard, which means the keyboard
carries movement while the mouse carries aim.

The keyboard does not carry the camera, and it used to. The arrows turned and
tilted it, and `W` and `S` tilted it as well. That gave the camera two owners
and they spent the whole run arguing. If you are on the mouse, the mouse
should be the entire camera. If you are on a pad, the right stick should be
the entire camera. So the keyboard route is gone.

That leaves WASD as a normal walk-around cluster, which is what it always
wanted to be. `W` and `S` walk forward and back along the camera's facing, and
`A` and `D` strafe across it. Turning the mouse turns the camera, and the walk
follows the camera, so the controls stay relative to what you can see. There
is no fixed forward axis any more. Forward is wherever you are looking.

I changed my mind about this one. The game started as a side-on 2.5D thing,
and side-on has no forward and no back, so `W` and `S` were sitting on jump
and slide. That was a clever answer to a problem I made for myself. Full 3D
walk-around is the honest answer, and it means the whole keyboard can do the
obvious thing.

If you would rather keep both hands on the arrows, that is what remapping is
for. The defaults just don't ask you to.

I've been asked for a keyboard fire binding more than once. I don't have one
in the defaults, because the mouse is doing the camera and a second job on
the same hand is the whole point of the layout. If you need it, the input
map is editable and `tools/setup_input_map.gd` is the file to edit.

## The mouse is locked in the middle

While a run is on, the mouse is captured. The pointer is gone, it cannot
leave the window, and the middle of the screen is where the mouse always is.
A small dot sits in that middle, and it is the crosshair: it is where you
are aiming.

**Esc** gives the cursor back, because the menu needs it. The menu gives it
back again when a run starts.

On a pad nothing is captured and nothing is locked, because there is no
pointer to lock. The right stick looks, exactly as it does now.

## The rest of the keyboard

| | |
| --- | --- |
| Reload | `C` |
| Use item | `B` |
| Next weapon | `V`, or the mouse wheel |
| Back to the spawn | `R` |
| Splits | `Tab` |
| Mechanics reference | `F1`, or `H` |

Reload, use item and weapon cycling weren't part of the original scheme. The
arsenal grew seven guns and five items after that scheme was written, and
those three need somewhere to live. They're on the keyboard because they're
secondary verbs and the primary ones are already busy.

## The gamepad

| | |
| --- | --- |
| Move | left stick, D-pad |
| Camera | right stick |
| Jump | A |
| Slide | B |
| Ledge grab | X |
| Interact | Y |
| Filament | right shoulder |
| Primary fire | right trigger |
| Alt fire | left trigger |
| Use item | D-pad up |
| Reload | D-pad down |
| Next weapon | right stick click |
| Back / splits / reference | back, start, guide |

The left stick moves and the right stick looks, so the two never fight over
the same axis. The left stick walks the same way the keyboard does: push it
forward and Lancer walks away from the camera.

## Remapping

The bindings live in `project.godot` under `[input]`, and they are meant to be
edited. The generator, `tools/setup_input_map.gd`, writes that section, so
if you change a binding by hand, change it in the generator too, or the next
person who runs the generator will quietly undo your work.

The generator also deletes actions that are no longer in its table. An old
action used to sit in `project.godot` forever after it was renamed, which is
how you end up with two names for one thing and no way to tell which one the
game is reading.

`tests/test_input_map.gd` checks the scheme itself: that every action except
the two triggers and the stick look has a key, that the triggers are on the
mouse buttons they are supposed to be on, that `A` is `A`, that `W` walks
forward, that `S` walks back, and that neither of them is still hiding on jump
or slide. It also checks that the camera rig reads the mouse and the stick and
no key at all. It also checks that nothing claims the arrow keys, because a
stray arrow binding is exactly how the old keyboard camera would come back. An
action that nobody reads is an action that does nothing, so those last two
are worth a test.

It also checks that nothing new turns up in the map without a keyboard
binding. I added that one after a new action landed in `project.godot` with
a gamepad binding and nothing else, and nobody noticed for a month.

## The greybox

Open `world/greybox/movement_greybox.tscn` and press `F1`. The panel lists
the movement numbers straight out of the tuning constants, and the new
bindings underneath them. If the panel and the code ever disagree, the panel
is built at runtime from the constants, so it can't.
