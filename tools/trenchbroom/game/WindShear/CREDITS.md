# The textures in the WindShear game folder

Every picture in `textures/` is **CC0**. It is public domain: use it,
change it, sell it, do not mention us. Attribution is not needed.

They are **placeholders**. They are here so the mapper can pick a material
while drawing and see something on the brush. The game's own art is made by
hand in Godot and none of this is used by the game.

| Pack | Who | What it gives | Licence |
| --- | --- | --- | --- |
| Pattern Pack | Kenney | 84 seamless black and white patterns, 256×256 | CC0 1.0 |
| Pattern Pack Pixel | Kenney | 64 small pixel patterns, 16×16 | CC0 1.0 |
| RPG Urban Pack | Kenney | 486 small tiles for props and decals, 16×16 | CC0 1.0 |
| Base Materials | Screaming Brain Studios | 128 materials: cardboard, clay, cloth, concrete, marble, metal, plaster, stone, wood | CC0 1.0 |
| Texture Pack Seamless | Heathal | 11 seamless textures: dirt, fabric, fire, grit, ice, metal, scratch, splatter, stone | CC0 1.0 |

The sixteen files named `floor_surface`, `floor_deep`, `floor_charcoal`,
`floor_glow`, `wall_surface`, `wall_deep`, `wall_charcoal`, `wall_glow`,
`platform_surface`, `platform_deep`, `platform_charcoal`, `platform_glow`,
`ramp_surface`, `ramp_deep`, `ramp_charcoal` and `ramp_glow` are made from
the Pattern Pack by `tools/trenchbroom/make_tag_textures.gd`. They are the
names the converter reads, so every one of them is a real picture and every
one of them is CC0 as well.

The full licence texts are in `licenses/`. `tools/trenchbroom/fetch_textures.sh`
puts them there again.
