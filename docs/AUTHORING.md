# Authoring by hand

Everything here is done in the Godot editor with the mouse. No code, no
command line, no regeneration step. If a change needs a script, it's in a
different document.

This is the document to read if the editor looked empty and you closed it.

---

## 1. Why the editor looks empty

`.godot/` isn't in the repository. It's a cache — Godot builds it when it
imports a project, and it contains nothing you'd want in git. A fresh clone
therefore has a `project.godot` but no imported assets, no class cache and no
scene thumbnails.

Godot doesn't open a folder like that. It opens a **project**, and until it has
imported one it has nothing to show.

Two ways to fix it:

**From the Project Manager.** Open Godot, click *Import*, browse to the
`project.godot` inside your clone, and press *Import & Edit*. Godot imports
everything and then opens the editor with a populated FileSystem dock.

**From the command line, if you prefer.**

```bash
godot --headless --editor --quit-after 20 --path /path/to/windshear
```

That imports without opening a window. Then launch the editor normally.

Either way, once it's done, the FileSystem dock shows `addons/`, `assets/`,
`data/`, `docs/`, `tests/`, `tools/`, `ui/` and `world/`. If it doesn't, use
*Project → Reload Current Project* and give it a minute. The first import is
slower than every later one.

## 2. Launching

```bash
godot --path /path/to/windshear --editor    # the editor
godot --path /path/to/windshear             # the game
```

In the editor, **F5** runs the project, which starts at the main menu. **F6**
runs the scene you currently have open, which is how you jump straight into the
movement room without going through the menu.

The main scene is set in *Project Settings → Application → Run → Main Scene*.
It's `ui/main_menu/main_menu.tscn`.

## 3. What's where

```
ui/main_menu/main_menu.tscn        the menu, the settings panel, the PSX slider
ui/theme/windshear_theme.tres      every colour, border and font size the menu uses
world/greybox/movement_greybox.tscn  the movement test room
assets/materials/                  the four PSX materials the greybox uses
assets/icon.svg / icon.png         the project icon. Finished. Don't touch.
addons/windshear/                  the game code
data/                              sections, schedules, story — plain JSON
tests/                             the headless suite
docs/                              everything else
```

The greybox is a test rig. It's one room with a floor, some platforms, a ramp,
one wall to kiss, and a strip of blue wayfinding so the route reads without
art. It is not a level. It exists so the movement has somewhere to be measured.

## 4. The movement room, and its controls

Open `world/greybox/movement_greybox.tscn` and press **F6**.

| Action | Key |
| --- | --- |
| Run | A / D or ← / → |
| Slide | S, ↓ or Ctrl |
| Jump | Space |
| Wall-kiss | slide into a wall, jump on contact |
| Reset to the spawn | R |
| Mechanics reference | F1 or H |

The reference panel is built from the tuning constants when the room opens, so
it can't drift away from what the controller actually does. It also says, in
plain text, which verbs are not built yet. Right now that's the filament and
the mantle.

The camera is mouse-look. Click into the window if the mouse is captured, and
Escape releases it.

## 5. The PSX amount

Run the project (F5), then *Settings*. The `PSX` slider runs from 0% to 100%.
At 0% the game is clean; at 100% it's the full 1995 look — vertex wobble, 5-bit
colour, dither, and (if you tick *AFFINE*) texture swim.

The slider writes a global shader uniform, so it changes every surface at once.
You don't need to touch a single material to change how much PSX the game has.

The value is saved to the player's config and read back at boot.

## 6. Decorating the GUI by hand

The menu is a normal Godot scene. Nothing about it is generated.

**Colours and borders** live in `ui/theme/windshear_theme.tres`. Double-click
it in the FileSystem dock and the theme editor opens along the bottom of the
screen. The entries you'll actually want:

- `Button` → *Normal*, *Hover*, *Pressed* — these are `StyleBoxFlat` resources.
  Change `bg_color`, `border_color`, `border_width_*` and `corner_radius_*`.
- `Label` → `font_color`.
- `PanelContainer` → *Panel* — the settings panel's background.
- `HSlider` → the grabber and the bar.

Every control in the menu inherits from the theme, so a change there lands on
all of them. If you want one control to differ, select it and use
*Inspector → Theme Overrides* — that's how the title and the footer already get
their own font sizes.

**Layout** lives in `ui/main_menu/main_menu.tscn`. Select a node and drag it,
or edit its offsets in the Inspector. The node names are readable:
`Title`, `Subtitle`, `Buttons/NewRun`, `SettingsPanel/Margin/Column/PsxRow/Psx`.

**Fonts.** There are no font files in the repository yet, so the menu uses
Godot's default. To change that by hand:

1. Drop a `.ttf` or `.otf` into `assets/fonts/`. Godot imports it on its own.
2. Open `ui/theme/windshear_theme.tres`.
3. In the theme editor, add a *Font* entry and set it as the theme's default
   font, or assign it to the `Button` and `Label` types specifically.
4. Adjust sizes per type in the same panel. The sizes currently in use are 8,
   9, 10, 11 and 30 px.

**The icon.** `assets/icon.svg` and `assets/icon.png` are the project icon and
the menu's title art. They're done. Leave them alone — the test suite and
`tools/make_icon.py` both treat them as fixed.

## 7. Making a material by hand

The greybox uses four materials in `assets/materials/`:

| File | Use |
| --- | --- |
| `psx_surface.tres` | the plain one. Start here for new surfaces |
| `psx_charcoal.tres` | the main walls and platforms |
| `psx_deep.tres` | recesses and the floor |
| `psx_glow.tres` | the blue wayfinding strips |

They all use `addons/windshear/render/ws_psx.gdshader`, so they all respond to
the PSX slider automatically.

To dress a surface:

1. Select a `MeshInstance3D` in the greybox scene.
2. Inspector → *Geometry* → *Material Override* → *Quick Load*.
3. Pick one of the `.tres` files in `assets/materials/`.
4. To use a texture instead of a flat colour, tick *Use Albedo Texture* on the
   material and drop the texture into *Albedo Texture*. Set *Albedo Color* to
   tint it.
5. To make a new material, right-click `assets/materials/` in the FileSystem
   dock → *New Resource…* → *ShaderMaterial* → set its shader to
   `ws_psx.gdshader`, then save it into the same folder. It shows up in *Quick
   Load* like the others.

The important part is that the material is a **file**, not an inline block
buried in the scene. A material file can be reused, edited once and updated
everywhere, and it survives a scene rewrite. The test suite checks that every
surface in the greybox points at a file in `assets/` and uses the PSX shader,
so a stray inline material will fail CI.

## 8. Resolution and scaling

*Project Settings → Display → Window*:

| Setting | Value | Why |
| --- | --- | --- |
| Viewport Width / Height | 480 / 270 | the internal buffer. Every pixel of the PSX look is one of these |
| Window Width / Height Override | 960 / 540 | exactly 2× the buffer |
| Stretch Mode | `canvas_items` | scales the canvas, not the 3D buffer |
| Stretch Aspect | `keep` | no stretching, letterboxed instead |

960×540 is 2× 480×270, so every internal pixel lands on a clean 2×2 block.
1440×810 (3×) and 1920×1080 (4×) work the same way. 1280×720 doesn't — it's
2.67×, so the last row and column of pixels get squeezed unevenly. If you want
a bigger window, pick a multiple.

*Project Settings → Rendering → Textures → Canvas Textures → Default Texture
Filter* must stay **Nearest**. Linear filtering blurs the pixel grid and
undoes the entire look.

## 9. What not to touch by hand

- `addons/windshear/core/ws_tuning.gd`. Every movement number is locked by
  `TECH_SPEC.md` §3 and asserted by `tests/test_tuning.gd`. Change one and the
  build fails, which is the point.
- `project.godot`'s `[input]` section. It's generated by
  `tools/setup_input_map.gd`; hand-editing it means the next run of that tool
  throws your edit away.
- The tests. If a test is wrong, say so and change the design first.

Everything else in `ui/`, `world/` and `assets/` is yours.
