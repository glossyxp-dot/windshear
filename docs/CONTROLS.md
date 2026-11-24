# Controls

The defaults, and why they are what they are.

---

## The short version

| | |
| --- | --- |
| Run | `A` `D` |
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

## Why the mouse does two jobs

The mouse is the camera, so the mouse is already in the hand that is pointing
at the thing you want to shoot. The triggers go there too. Everything the
player does with their left hand is on the keyboard, which means the keyboard
is carrying movement while the mouse carries aim.

The camera also has a keyboard route, because some people don't want to
wobble a mouse while they run. The arrow keys turn and tilt it, `W` and `S`
tilt it as well.

`W` and `S` don't move Lancer, and that is worth explaining once. The game
plays on a single plane. There is no forward and there is no back. Up and
down are the only two directions a side-on route does not have, so they tilt
the camera instead.

| | |
| --- | --- |
| Turn the camera | `←` `→` |
| Tilt the camera | `↑` `↓`, or `W` `S` |

A key turns the camera at a fixed rate, 2.0 rad/s, and the mouse turns it by
pixels, 0.0022 rad a pixel. Those are deliberately different numbers. A key
at 2.0 rad/s is slow enough to line the camera up on something before you
commit to the shot. A mouse is faster and finer, which is what you want once
you are actually aiming.

I've been asked for a keyboard fire binding more than once. I don't have one
in the defaults, because the mouse is doing the camera and a second job on
the same hand is the whole point of the layout. If you need it, the input
map is editable and `tools/setup_input_map.gd` is the file to edit.

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
the same axis.

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
the two triggers has a key, that the triggers are on the mouse buttons they
are supposed to be on, that `A` is `A`, and that the camera rig actually reads
the keyboard look actions. An action that nobody reads is an action that does
nothing, so that last one is worth a test.

It also checks that nothing new turns up in the map without a keyboard
binding. I added that one after a new action landed in `project.godot` with
a gamepad binding and nothing else, and nobody noticed for a month.

## The greybox

Open `world/greybox/movement_greybox.tscn` and press `F1`. The panel lists
the movement numbers straight out of the tuning constants, and the new
bindings underneath them. If the panel and the code ever disagree, the panel
is built at runtime from the constants, so it can't.
