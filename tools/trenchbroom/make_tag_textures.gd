# WindShear — makes the sixteen tag textures the converter reads
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
##
## The converter reads a material name off a brush face and says what shape
## the piece is and which of the four materials it wears. The names it reads
## are `floor_surface`, `wall_charcoal` and so on: four shapes times four
## materials.
##
## Those names have to be real pictures, or the mapper picks a material in
## TrenchBroom and sees nothing. So this makes one picture for each of the
## sixteen, out of the CC0 patterns in the same folder.
##
## [codeblock]
## godot --headless --path . --script res://tools/trenchbroom/make_tag_textures.gd
## [/codeblock]
##
## Nothing here is art for the game. It is a grey placeholder that says
## "this piece is a wall and it is the dark one", so the map can be read at a
## glance. The game's own textures are made by hand in Godot.
extends SceneTree

## Where the pictures live.
const TEXTURE_FOLDER := "res://tools/trenchbroom/game/WindShear/textures"

## The pattern each shape is cut from. They are picked so the four read as
## four different things: brick, a panel, a grid and a grain.
const BASE_PATTERNS := {
	"floor": "pattern19.png",
	"wall": "pattern74.png",
	"platform": "pattern14.png",
	"ramp": "pattern83.png",
}

## The two ends of each material, from the dark end to the light one.
const PALETTES := {
	"surface": [Color(0.22, 0.20, 0.17), Color(0.86, 0.82, 0.71)],
	"deep": [Color(0.03, 0.07, 0.12), Color(0.16, 0.38, 0.47)],
	"charcoal": [Color(0.02, 0.02, 0.03), Color(0.29, 0.29, 0.32)],
	"glow": [Color(0.02, 0.11, 0.13), Color(0.33, 1.00, 0.88)],
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var made := 0
	for shape in BASE_PATTERNS.keys():
		for palette in PALETTES.keys():
			if _make_one(str(shape), str(palette)):
				made += 1
	print("windshear: %d tag textures are in %s" % [made, TEXTURE_FOLDER])
	quit(0 if made == BASE_PATTERNS.size() * PALETTES.size() else 1)


## Makes one tag texture and says whether it worked.
func _make_one(shape: String, palette: String) -> bool:
	var source_path := "%s/%s" % [TEXTURE_FOLDER, str(BASE_PATTERNS[shape])]
	var target_path := "%s/%s_%s.png" % [TEXTURE_FOLDER, shape, palette]

	var image := Image.new()
	if image.load(source_path) != OK:
		printerr("problem: %s could not be read" % source_path)
		return false
	if image.is_compressed():
		if image.decompress() != OK:
			printerr("problem: %s could not be opened" % source_path)
			return false

	var colours: Array = PALETTES[palette]
	var dark: Color = colours[0]
	var light: Color = colours[1]

	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			var brightness := 0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b
			var tint := dark.lerp(light, pow(brightness, 0.85))
			tint.a = pixel.a
			image.set_pixel(x, y, tint)

	var error := image.save_png(target_path)
	if error != OK:
		printerr("problem: %s could not be written" % target_path)
		return false
	return true
