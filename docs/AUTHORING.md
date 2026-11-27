# Authoring by hand

Everything in here is done in the Godot editor with the mouse. No code, no command line, no regeneration step. If a change needs a script, it belongs in a different document.

Read this one if the editor came up empty and you closed it.

Nothing here is a generated asset. The icon, the theme and the menu are all
files you open and edit.

The icon is **yours**. `assets/icon.svg` is your own vector of it and
`assets/icon.png` is your own picture, and those two files are the one thing
in the repository nobody regenerates. There is no script that writes them. If
you want a new icon, make a new picture and replace them yourself.

## The editor looks empty because it hasn't imported yet

`.godot/` isn't in the repository. It's a cache. Godot builds it on import, and there's nothing in there that belongs in git. A fresh clone gives you a `project.godot` with no imported assets, no class cache and no thumbnails.

Godot also doesn't open a folder. It opens a project. Until it has imported one, it has nothing to show you.

There are two ways to fix that. From the Project Manager, open Godot, click *Import*, browse to the `project.godot` inside your clone, and press *Import & Edit*. Godot imports everything and opens the editor with a populated FileSystem dock.

Or from a terminal, if you'd rather:

```bash
godot --headless --editor --quit-after 20 --path /path/to/windshear
```

That imports without opening a window. Then launch the editor normally.

Either way, the FileSystem dock eventually shows `addons/`, `assets/`, `data/`, `docs/`, `tests/`, `tools/`, `ui/` and `world/`. If it doesn't, use *Project → Reload Current Project* and give it a minute. The first import is slower than every import after it.

## Launching

```bash
godot --path /path/to/windshear --editor   # the editor
godot --path /path/to/windshear            # the game
```

**F5** runs the project and starts at the main menu. **F6** runs whichever scene is open in the editor, which is the quick way into the movement room without going through the menu.

The main scene is `ui/main_menu/main_menu.tscn`. It lives in *Project Settings → Application → Run → Main Scene* if you ever need to change it.

## What's where

```
ui/main_menu/main_menu.tscn         the menu, the settings panel, the PSX slider
ui/theme/windshear_theme.tres       every colour, border and font size the menu uses
ui/kit/                             the pieces a screen is built from
world/greybox/movement_greybox.tscn the movement test room
world/kit/                          the pieces a section is built from
world/playground/                   the room where you play your own section
data/sections/                      the section scenes, one folder per chapter
assets/materials/                   the four PSX materials the greybox uses
assets/icon.svg, assets/icon.png   the project icon. Your art. Don't touch.
addons/windshear/                   the game code
addons/level_tools/                 the editor dock that makes and exports sections
data/                               sections, schedules, story, all plain JSON
tests/                              the headless suite
docs/                               everything else
```

The greybox is a test rig: one room with a floor, some platforms, a ramp, a wall on every side to kiss and a strip of blue wayfinding so the route reads without art. It isn't a level. It's there so the movement has somewhere to be measured.

## The movement room and its controls

Open `world/greybox/movement_greybox.tscn` and press **F6**.

| Action | Binding |
| --- | --- |
| Walk forward / back | `W` / `S` |
| Strafe left / right | `A` / `D` |
| Slide | `Ctrl` |
| Jump | `Space` |
| Ledge grab | `Q` |
| Interact | `E` |
| Filament | `F` |
| Primary fire | left mouse button |
| Alt fire | right mouse button |
| Camera | mouse |

The mouse does the camera and both triggers because it's already in the hand pointing at the target. Everything else is on the keyboard, and the keyboard leaves the camera alone. `W` and `S` walk forward and back, `A` and `D` strafe, and the walk follows the camera. Click into the window if the mouse is captured; Escape lets it go.

There are a few extra bindings too:

| Action | Binding |
| --- | --- |
| Reset to the spawn | `R` |
| Show splits | `Tab` |
| Mechanics reference | `F1` or `H` |
| Reload | `C` |
| Use an item | `B` |
| Cycle weapons | `V` or the mouse wheel |

The gamepad has its own layout:

| Action | Gamepad |
| --- | --- |
| Move | left stick and D-pad |
| Camera | right stick |
| Jump | A |
| Slide | B |
| Ledge grab | X |
| Interact | Y |
| Filament | right shoulder |
| Primary fire | right trigger |
| Alt fire | left trigger |

The wall-jump isn't a separate button. Slide into a wall and press jump on the contact frame. The base chain is three wall-jumps and tops out at 16.4 m/s. The shipped `wall_kiss_chain` Fracture takes the chain to five and the ceiling to 18.0 m/s.

The full control table is in `docs/CONTROLS.md`.

## The movement workbench

Open `tools/movement_workbench.tscn` and press **F6**. It is the same room
with a panel of sliders down the side, and every slider is a live movement
number. Drag one and the controller is using the new number on the next
frame.

That is the whole point: you tune the movement by feel, in the editor, without
opening a script. The panel is built out of a table in
`addons/windshear/core/ws_tweak.gd`, so adding a knob is one entry and no
scene editing.

| Button | What it does |
| --- | --- |
| reset all | every knob back to the documented number |
| save profile | writes to the user data folder, outside the repository |
| load profile | reads it back |
| copy values | puts the numbers and your notes on the clipboard |
| write to repo | writes `data/tuning_profile.json`, which you can commit |

**F2** hides and shows the panel, **F3** types in the notes box, and the
mouse turns the camera whenever it is over the room rather than over the
panel.

Nothing reaches the repository until you press **write to repo**. A tuned
number is not canon until somebody writes it into the code and the spec, and
the workbench profile is the handoff for that. `docs/BUILDING.md` has the
whole loop.

The reference panel is built from the tuning constants when the room opens, so it can't drift from what the controller actually does. It also says which verbs aren't built yet. Right now that's the filament, the ledge grab and interact.

The small readout in the corner is the speed in metres per second. It shows the current horizontal speed and the peak since the last respawn. It refreshes ten times a second rather than every frame, so it costs almost nothing.

## Making a section

The **Level Tools** dock is on the right of the editor. It has four
buttons and a box to type in.

1. Type the section id, `2.01` for example.
2. Press **create section scene**. The scene appears in
   `data/sections/c2/s2_01.tscn` with a room, a section trigger, the
   checkpoints, the split marker and the gates the schedule asks for, and it
   opens in front of you.
3. Lay the room out with the pieces in `world/kit/`. Drag one in, type its
   size in the Inspector, move it. The mesh and the collision follow.
4. Place the points. Each point is named after the id it has in the data, so
   `P1.01.gate_01` is the gate the schedule calls `P1.01.gate_01`.
5. Press **export section data** in the Inspector of the section root, or
   **export sections** in the dock.

**check sections** tells you whether the data still matches the scenes. The
build does the same thing, so a forgotten export is a failed build instead of
a surprise in the game.

### Two rules that protect your work

**A scene that is already there is never written over.** Pressing **create
section scene** on a section you have already made opens it instead of
replacing it. The builder refuses to write over a file that exists, and the
test suite checks that it does. There is no undo for a file.

**Renaming a section is one button.** The name, the difficulty and the par
time live in the section root and in `data/sections/index.json`, and the two
have to agree. Change the name in the Inspector, type the id in the dock and
press **update the index**, and the index hears about it. You never open the
JSON by hand. Only the one entry in the file is rewritten; the other 299 are
left byte for byte alone.

The pieces in `world/kit/` are yours. Change `floor.tscn` and every floor in
the game changes with it.

## Playing your section

Open `world/playground/section_playground.tscn` and press **F6**. The
section id is a number in the Inspector: change it, press **F6** again, and
you are in another section.

| | |
| --- | --- |
| `W` `A` `S` `D` | walk, camera-relative |
| `Ctrl` | slide |
| `Space` | jump |
| mouse | camera |
| `R` | back to the start checkpoint |
| `F1` or `H` | the controls, on screen |

You start at the **start checkpoint**, so that checkpoint is where the feet
go. Put it where you want the player to begin.

The line at the top says the section, the speed in m/s, the peak speed and
where you are.

## Playing the whole game

Press **NEW RUN** in the menu and you are in the first section. Walk to the
**end checkpoint** and the section clears, the banner says so, and the next
section you have written starts. When there is nothing left to play, the run
ends and the menu says **RUN COMPLETE**.

That is the same section you made, loaded by the same manager, with three
things added on top:

- The **objective** on the section root, in the Inspector, is what the HUD
  shows under the section name. Leave it empty and the HUD says **REACH THE
  EXIT**.
- The **regulation gates** in the room open and close on the schedule. A
  gate is a wall while it is closed and nothing at all while it is open. Its
  width and height are in the Inspector; the point is where the gate meets
  the floor. The editor draws the barrier, so you can see what you are
  placing.
- The section clock in the corner, which is the thing a speedrunner looks
  at.

`Esc` goes back to the menu. `R` puts the player back at the start
checkpoint.

## The UI kit

The look lives in `ui/theme/windshear_theme.tres`. The pieces live in
`ui/kit/`.

A control picks a style in the Inspector, under **Theme**, **Type
Variation**: `WsTitle`, `WsHeading`, `WsCaption`, `WsValue` and `WsPanel`.
That is how a screen gets the look without carrying its own colours.

Drag a piece from `ui/kit/` into your screen:

| Piece | What it is |
| --- | --- |
| `ws_heading.tscn` | A blue heading |
| `ws_button.tscn` | A button with the right height |
| `ws_row.tscn` | A label on the left, a value on the right |
| `ws_divider.tscn` | A thin rule |
| `ws_panel.tscn` | A panel with a title and a box to fill |

To add a row to a panel, right-click the instance in the scene tree and
turn on **Editable Children**, then drop your rows into the **Content** box.

The font sizes are 8, 9, 10, 11, 12 and 30. The buffer is 480 by 270, so
nothing may be wider or taller than that. The suite checks both.

A pause menu is a canvas layer with **Process Mode** set to **Always**, and
the HUD is **Pausable**. That is the whole trick to pausing.

## The PSX amount

Run the project (F5) and open *Settings*. The `PSX` slider runs from 0% to 100%. At 0% the game is clean. At 100% you get the full 1995 look: vertex wobble, 5-bit colour and dither, plus texture swim if you tick *AFFINE*.

The slider writes a global shader uniform, so it changes every surface at once. You don't touch a single material to change how much PSX the game has.

The value is written to the player's config and read back at boot.

## Decorating the GUI by hand

The menu is a normal Godot scene. Nothing about it is generated.

Colours and borders live in `ui/theme/windshear_theme.tres`. Double-click it in the FileSystem dock and the theme editor opens along the bottom of the screen.

For `Button`, edit *Normal*, *Hover* and *Pressed*. Those are `StyleBoxFlat` resources, so you can change `bg_color`, `border_color`, `border_width_*` and `corner_radius_*`. `Label` has a `font_color`. The `PanelContainer` entry called *Panel* is the settings panel's background, and `HSlider` gives you the grabber and bar.

Every control in the menu inherits from the theme, so a change there lands on all of them. When you want one control to differ, select it and use *Inspector → Theme Overrides*. The title and footer already get their own sizes that way.

Layout lives in `ui/main_menu/main_menu.tscn`. Drag nodes or edit their offsets in the Inspector. The names are readable, which helps: `Title`, `Subtitle`, `Buttons/NewRun`, `SettingsPanel/Margin/Column/PsxRow/Psx`.

Fonts are another manual job. There are no font files in the repo yet, so the menu uses Godot's default. Drop a `.ttf` or `.otf` into `assets/fonts/` and Godot imports it on its own. Open `ui/theme/windshear_theme.tres`, add a *Font* entry in the theme editor, and set it as the theme's default font, or assign it to `Button` and `Label` separately. Set the sizes in the same panel. The sizes in use right now are 8, 9, 10, 11 and 30 px.

The icon, `assets/icon.svg` and `assets/icon.png`, is the project icon and the menu's title art. It is your own art, in both a vector and a picture. Leave it alone, and nothing regenerates it. If you want a new one, replace those files with your new art yourself.

## Making a material by hand

The greybox uses four materials, all in `assets/materials/`:

| File | Use |
| --- | --- |
| `psx_surface.tres` | the plain one. Start here for new surfaces |
| `psx_charcoal.tres` | main walls and platforms |
| `psx_deep.tres` | recesses and the floor |
| `psx_glow.tres` | the blue wayfinding strips |

They all use `addons/windshear/render/ws_psx.gdshader`, so they all follow the PSX slider without any extra work.

To dress a surface, select a `MeshInstance3D` in the greybox scene and go to *Inspector → Geometry → Material Override → Quick Load*. Pick one of the `.tres` files in `assets/materials/`. For a texture, tick *Use Albedo Texture* on the material and drop the texture into *Albedo Texture*. Set *Albedo Color* to tint it.

To make a new one, right-click `assets/materials/` in the FileSystem dock, choose *New Resource…* → *ShaderMaterial*, point its shader at `ws_psx.gdshader`, and save it in the same folder. It turns up in *Quick Load* like the others.

The important part is that a material is a **file**, not an inline block buried in the scene. A file can be reused, edited once and updated everywhere, and it survives a scene rewrite. The test suite checks that every surface in the greybox points at a file under `assets/` and uses the PSX shader, so a stray inline material fails CI.

## Resolution and scaling

In *Project Settings → Display → Window*:

| Setting | Value | Why |
| --- | --- | --- |
| Viewport Width / Height | 480 / 270 | the internal buffer. Every pixel of the PSX look is one of these |
| Window Width / Height Override | 960 / 540 | exactly 2× the buffer |
| Stretch Mode | `canvas_items` | scales the canvas, not the 3D buffer |
| Stretch Aspect | `keep` | no stretching, letterboxed instead |

960×540 is 2× 480×270, so every internal pixel lands on a clean 2×2 block. 1440×810 (3×) and 1920×1080 (4×) behave the same way. 1280×720 doesn't: it's 2.67×, so the last row and column get squeezed unevenly. If you want a bigger window, pick a multiple.

*Project Settings → Rendering → Textures → Canvas Textures → Default Texture Filter* has to stay on **Nearest**. Linear filtering blurs the pixel grid and undoes the whole look.

## Leave these alone

`addons/windshear/core/ws_tuning.gd` holds every movement number. They're locked by `TECH_SPEC.md` §3 and asserted by `tests/test_tuning.gd`. Change one and the build fails, which is the point.

The movement workbench is how you move a number without touching that file. Open `tools/movement_workbench.tscn`, press F6, drag the slider, feel it, and press **write to repo** when you like what you found. The profile that comes out is the handoff, and the constants get written from it on purpose.

The `[input]` section of `project.godot` is generated by `tools/setup_input_map.gd`. Never hand-edit it. The generator also removes retired actions, so a renamed action can't leave an old binding behind.

Leave the tests alone too. If a test is wrong, say so and change the design first.

Everything else in `ui/`, `world/` and `assets/` is yours.
