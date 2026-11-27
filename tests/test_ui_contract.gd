# WindShear — the theme and the UI kit have to hold together
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
## The theme is the one place the look lives.
##
## When a screen carries its own colours, changing the look means opening
## every screen. When a screen points at a style in the theme, changing the
## look means changing one file. This suite is the alarm for a screen that
## has started doing its own styling, for a button that cannot show a
## controller player where the focus is, and for a kit piece that does not
## fit on the screen the game runs at.
extends "res://tests/ws_test.gd"

## The theme every screen uses.
const THEME_PATH := "res://ui/theme/windshear_theme.tres"

## The pieces the designer drags into a screen.
const KIT_SCENES := [
	"res://ui/kit/ws_heading.tscn",
	"res://ui/kit/ws_button.tscn",
	"res://ui/kit/ws_row.tscn",
	"res://ui/kit/ws_divider.tscn",
	"res://ui/kit/ws_panel.tscn",
]

## The screens that are built by hand.
const SCREENS := [
	"res://ui/main_menu/main_menu.tscn",
	"res://ui/hud/section_hud.tscn",
]

## The font sizes the game uses. A new one is a decision, not an accident.
const ALLOWED_FONT_SIZES := [8, 9, 10, 11, 12, 30]

## The internal resolution the game runs at.
const SCREEN_SIZE := Vector2(480.0, 270.0)

## The kit styles and what they are built on.
const VARIATIONS := {
	"WsHeading": "Label",
	"WsTitle": "Label",
	"WsCaption": "Label",
	"WsValue": "Label",
	"WsPanel": "PanelContainer",
}


func suite_name() -> String:
	return "the theme holds the look"


func run_with_scene(scene: Node) -> void:
	_test_the_theme_has_the_kit_styles()
	_test_the_buttons_can_show_the_focus()
	_test_the_kit_pieces_use_the_theme()
	_test_the_font_sizes_are_known()
	_test_the_kit_fits_the_screen(scene)


## Every kit style exists and is built on the right thing.
##
## A variation without a base type is a style that does nothing.
func _test_the_theme_has_the_kit_styles() -> void:
	heading("the theme has the kit styles")
	var theme := _load_theme()
	if theme == null:
		ok(false, "the theme loads")
		return
	ok(true, "the theme loads")

	for variation in VARIATIONS.keys():
		text(str(theme.get_type_variation_base(variation)), VARIATIONS[variation],
			"%s is built on %s" % [variation, VARIATIONS[variation]])

	for variation in VARIATIONS.keys():
		var has_size := theme.has_font_size("font_size", variation)
		ok(has_size, "%s says how big it is" % variation)
		var has_colour := theme.has_color("font_color", variation)
		ok(has_colour or variation == "WsPanel",
			"%s says what colour it is" % variation)


## A controller player has to be able to see where the focus is.
##
## The focus style is the only thing that says which button is selected
## when there is no mouse.
func _test_the_buttons_can_show_the_focus() -> void:
	heading("the buttons can show the focus")
	var theme := _load_theme()
	if theme == null:
		ok(false, "the theme loads")
		return

	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		ok(theme.get_stylebox(style_name, "Button") != null,
			"a button has a %s style" % style_name)

	ok(theme.get_stylebox("separator", "Separator") != null,
		"a divider has a style")


## The kit pieces and the screens use the theme and not their own colours.
func _test_the_kit_pieces_use_the_theme() -> void:
	heading("the kit pieces use the theme")
	var theme := _load_theme()
	if theme == null:
		ok(false, "the theme loads")
		return

	for path in KIT_SCENES + SCREENS:
		var packed: PackedScene = load(path)
		ok(packed != null, "%s loads" % path)
		if packed == null:
			continue
		var piece := packed.instantiate()
		var bad := PackedStringArray()
		_check_variations(piece, theme, bad)
		ok(bad.is_empty(), "%s uses styles the theme has (%s)" % [
			path, ", ".join(bad)])
		piece.free()


## Every style a screen asks for is a style the theme has.
func _check_variations(node: Node, theme: Theme, bad: PackedStringArray) -> void:
	for child in node.get_children():
		if child is Control:
			var variation := str(child.get("theme_type_variation"))
			if not variation.is_empty():
				if str(theme.get_type_variation_base(variation)).is_empty():
					bad.append(variation)
		_check_variations(child, theme, bad)


## The font sizes the game uses are the ones we agreed on.
##
## A size that is not in the list is a size that was typed in by hand, and
## a size that is typed in by hand is a size that will not change with the
## theme.
func _test_the_font_sizes_are_known() -> void:
	heading("the font sizes are known")
	for path in KIT_SCENES + SCREENS:
		var packed: PackedScene = load(path)
		if packed == null:
			ok(false, "%s loads" % path)
			continue
		var screen := packed.instantiate()
		var bad := PackedStringArray()
		_check_font_sizes(screen, bad)
		ok(bad.is_empty(), "%s uses known font sizes (%s)" % [path, ", ".join(bad)])
		screen.free()


## Walks a screen and collects the font sizes it sets by hand.
func _check_font_sizes(node: Node, bad: PackedStringArray) -> void:
	for child in node.get_children():
		if child is Control:
			var value: Variant = child.get("theme_override_font_sizes/font_size")
			var size := 0
			if value != null:
				size = int(value)
			if size > 0 and not ALLOWED_FONT_SIZES.has(size):
				bad.append("%s uses %d" % [child.name, size])
		_check_font_sizes(child, bad)


## The kit fits on the screen the game runs at.
##
## The internal buffer is 480 by 270. A piece that does not fit is a piece
## the designer has to resize before it can be used.
func _test_the_kit_fits_the_screen(scene: Node) -> void:
	heading("the kit fits the screen")
	var root := Control.new()
	root.size = SCREEN_SIZE
	scene.add_child(root)

	var worst := Vector2.ZERO
	for path in KIT_SCENES:
		var packed: PackedScene = load(path)
		if packed == null:
			continue
		var piece := packed.instantiate()
		root.add_child(piece)
		worst = worst.max(piece.size)
		piece.queue_free()

	ok(worst.x <= SCREEN_SIZE.x, "the kit is no wider than the screen")
	ok(worst.y <= SCREEN_SIZE.y, "the kit is no taller than the screen")

	root.queue_free()


## The theme.
func _load_theme() -> Theme:
	var theme: Theme = load(THEME_PATH)
	return theme
