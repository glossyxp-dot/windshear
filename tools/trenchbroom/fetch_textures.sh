#!/usr/bin/env bash
# WindShear — fetch the generic CC0 textures TrenchBroom shows the mapper
# Copyright (C) 2026 the WindShear contributors
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Every texture this script installs is CC0. They are placeholders, so the
# mapper can pick a material while drawing and see something on the brush.
# The game's own art is made by hand in Godot and none of this ships with it.
#
# The script downloads five packs, flattens their names into something a
# texture browser can show, and leaves the licences next to the pictures:
#
#   tools/trenchbroom/game/WindShear/textures/   the pictures
#   tools/trenchbroom/game/WindShear/licenses/   the licences
#   tools/trenchbroom/game/WindShear/CREDITS.md  who made them
#
# Run it again whenever a pack is added. It only writes the texture folder and
# the licence folder, and it never touches anything else.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAME="$HERE/game/WindShear"
TEXTURES="$GAME/textures"
LICENCES="$GAME/licenses"
CACHE="${WINDSHEAR_TEXTURE_CACHE:-$HERE/.texture-cache}"
OPEN_GAME="${WINDSHEAR_TRENCHBROOM_GAMES:-$HOME/.config/TrenchBroom/games}"

# The packs. Every one of them is CC0.
PACKS=(
  "kenney_patternpack.zip|https://opengameart.org/sites/default/files/kenney_patternpack.zip"
  "kenney_pattern-pack-pixel.zip|https://opengameart.org/sites/default/files/kenney_pattern-pack-pixel.zip"
  "kenney_RPGurbanPack.zip|https://opengameart.org/sites/default/files/kenney_RPGurbanPack.zip"
  "sbs_base_materials_128x128.zip|https://opengameart.org/sites/default/files/sbs_-_base_materials_pack_128x128.zip"
  "textures_seamless.zip|https://opengameart.org/sites/default/files/textures%20seamless.zip"
)

say() { printf '%s\n' "$*"; }

need() {
  if ! command -v "$1" > /dev/null 2>&1; then
    say "windshear: $1 is needed and is not here"
    exit 1
  fi
}

download() {
  local name="$1"
  local url="$2"
  local path="$CACHE/$name"
  if [ -f "$path" ]; then
    say "  have $name"
    return 0
  fi
  say "  getting $name"
  curl --fail --location --silent --show-error \
    --user-agent "Mozilla/5.0 (X11; Linux x86_64)" \
    --output "$path.part" "$url"
  mv "$path.part" "$path"
}

unpack() {
  local name="$1"
  local folder="$CACHE/unpacked/${name%.zip}"
  rm -rf "$folder"
  mkdir -p "$folder"
  unzip -qo "$CACHE/$name" -d "$folder"
  say "$folder"
}

# Turns a name into something a texture browser can show: lower case, no
# spaces, no brackets, no dots.
tidy() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^a-z0-9_]/_/g' -e 's/__*/_/g' -e 's/^_//' -e 's/_$//'
}

main() {
  need curl
  need unzip
  need sed

  mkdir -p "$CACHE" "$CACHE/unpacked" "$TEXTURES" "$LICENCES"

  say "windshear: fetching the generic CC0 textures"
  for pack in "${PACKS[@]}"; do
    download "${pack%%|*}" "${pack##*|}"
  done

  say "windshear: unpacking"
  local pattern_folder pixel_folder urban_folder materials_folder seamless_folder
  pattern_folder="$(unpack kenney_patternpack.zip | tail -1)"
  pixel_folder="$(unpack kenney_pattern-pack-pixel.zip | tail -1)"
  urban_folder="$(unpack kenney_RPGurbanPack.zip | tail -1)"
  materials_folder="$(unpack sbs_base_materials_128x128.zip | tail -1)"
  seamless_folder="$(unpack textures_seamless.zip | tail -1)"

  say "windshear: clearing the old set"
  rm -f "$TEXTURES"/*.png

  say "windshear: installing the patterns"
  local index=0
  for picture in "$pattern_folder/PNG/Default size"/pattern*.png; do
    [ -e "$picture" ] || continue
    index=$((index + 1))
    cp "$picture" "$TEXTURES/pattern$(printf '%02d' "$index").png"
  done

  say "windshear: installing the pixel patterns"
  index=0
  for picture in "$pixel_folder/Tiles (Color)"/tile_*.png; do
    [ -e "$picture" ] || continue
    index=$((index + 1))
    cp "$picture" "$TEXTURES/pixel$(printf '%02d' "$index").png"
  done

  say "windshear: installing the small tiles"
  for picture in "$urban_folder/Tiles"/tile_*.png; do
    [ -e "$picture" ] || continue
    local name
    name="$(basename "$picture")"
    name="${name#tile_}"
    cp "$picture" "$TEXTURES/urban_${name%.png}.png"
  done

  say "windshear: installing the materials"
  for picture in "$materials_folder/Base Materials 128x128"/*/*.png; do
    [ -e "$picture" ] || continue
    local name
    name="$(basename "$picture")"
    name="${name%-128x128.png}"
    cp "$picture" "$TEXTURES/$(tidy "$name").png"
  done

  say "windshear: installing the seamless textures"
  for picture in "$seamless_folder"/*.png; do
    [ -e "$picture" ] || continue
    local name
    name="$(basename "$picture")"
    cp "$picture" "$TEXTURES/seamless_$(tidy "${name%.png}").png"
  done

  say "windshear: keeping the licences"
  rm -f "$LICENCES"/*.txt
  cp "$pattern_folder/License.txt" "$LICENCES/kenney_pattern_pack.txt"
  cp "$pixel_folder/License.txt" "$LICENCES/kenney_pattern_pack_pixel.txt"
  cp "$urban_folder/License.txt" "$LICENCES/kenney_rpg_urban_pack.txt"
  cp "$materials_folder/License.txt" "$LICENCES/screaming_brain_base_materials.txt"
  cat > "$LICENCES/heathal_texture_pack_seamless.txt" << 'TEXT'
Texture pack seamless

Created by Heathal (https://opengameart.org/content/texture-pack-seamless)
Published on OpenGameArt.org

			------------------------------

	License: (Creative Commons Zero, CC0)
	http://creativecommons.org/publicdomain/zero/1.0/

	This content is free to use in personal, educational and commercial projects.

			------------------------------
TEXT

  say "windshear: making the sixteen tag textures"
  local godot="${WINDSHEAR_GODOT:-godot}"
  if command -v "$godot" > /dev/null 2>&1; then
    (cd "$HERE/../.." && "$godot" --headless --path . \
      --script res://tools/trenchbroom/make_tag_textures.gd) || \
      say "  the tag textures were not made; run the Godot script by hand"
  else
    say "  godot is not here, so the tag textures were not made"
  fi

  say "windshear: writing the credits"
  cat > "$GAME/CREDITS.md" << 'TEXT'
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
TEXT

  say "windshear: installing into TrenchBroom"
  if [ -d "$OPEN_GAME" ]; then
    mkdir -p "$OPEN_GAME/WindShear"
    cp -r "$GAME"/* "$OPEN_GAME/WindShear/"
    say "  $OPEN_GAME/WindShear"
  else
    say "  $OPEN_GAME is not there, so nothing was installed"
  fi

  local count
  count="$(find "$TEXTURES" -name '*.png' | wc -l)"
  say "windshear: $count textures are in $TEXTURES"
}

main "$@"
