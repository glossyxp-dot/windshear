# WindShear — the PSX amount tests
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
## The PSX look is the one setting in the game that is entirely the
## player's business. Half of this file checks that the dial exists, is
## registered, compiles and survives a trip through the settings file; the
## other half checks that the slider in the menu actually turns it.
extends "res://tests/ws_test.gd"

## The PSX helper.
const Psx := preload("res://addons/windshear/render/ws_psx.gd")
## The PSX shader.
const PsxShader := preload("res://addons/windshear/render/ws_psx.gdshader")
## The main menu, which carries the picker.
const MenuScene := preload("res://ui/main_menu/main_menu.tscn")
## The path of the slider inside the menu.
const SLIDER_PATH := "SettingsPanel/Margin/Column/PsxRow/Psx"
## The path of the amount label inside the menu.
const LABEL_PATH := "SettingsPanel/Margin/Column/PsxRow/PsxValue"
## The path of the affine switch inside the menu.
const TOGGLE_PATH := "SettingsPanel/Margin/Column/AffineRow/Affine"


func suite_name() -> String:
	return "the player picks how much PSX there is"


func run_with_scene(_scene: Node) -> void:
	_test_the_globals_are_registered()
	_test_the_shader_compiles()
	_test_the_amount_is_clamped()
	_test_the_settings_round_trip()
	_test_the_picker_is_wired()


## The two global uniforms have to exist before a shader may name them.
func _test_the_globals_are_registered() -> void:
	heading("the shader globals")
	var globals := RenderingServer.global_shader_parameter_get_list()
	ok(globals.has(&"psx_amount"), "the psx_amount global is registered")
	ok(globals.has(&"psx_affine"), "the psx_affine global is registered")
	ok(ProjectSettings.has_setting("shader_globals/psx_amount"),
		"project.godot declares the psx_amount global")
	ok(ProjectSettings.has_setting("shader_globals/psx_affine"),
		"project.godot declares the psx_affine global")


## The shader has to compile, and it has to expose the four knobs.
func _test_the_shader_compiles() -> void:
	heading("the shader")
	var material := ShaderMaterial.new()
	material.shader = PsxShader
	ok(material.shader != null, "the PSX shader loads")

	var names := PackedStringArray()
	for uniform in PsxShader.get_shader_uniform_list():
		names.append(String(uniform["name"]))

	# A shader that failed to compile comes back with an empty list, so the
	# list itself is the compile check.
	ok(names.size() >= 8, "the shader compiled and exposes its uniforms")
	ok(names.has("albedo_color"), "the shader takes an albedo colour")
	ok(names.has("albedo_texture"), "the shader takes an albedo texture")
	ok(names.has("vertex_snap"), "the shader can snap the vertices")
	ok(names.has("affine_warp"), "the shader can warp the textures")
	ok(names.has("dither_strength"), "the shader can dither")
	ok(names.has("color_depth"), "the shader has a colour depth")
	ok(names.has("psx_grid"), "the shader knows the internal resolution")

	# The two globals live outside the uniform list, because they are
	# global. They have to be named in the source.
	ok(PsxShader.code.contains("global uniform float psx_amount"),
		"the shader reads the amount global")
	ok(PsxShader.code.contains("global uniform float psx_affine"),
		"the shader reads the affine global")

	var made := Psx.make_material(Color(0.5, 0.25, 0.125, 1.0))
	ok(made.shader == PsxShader, "a made material uses the PSX shader")
	var colour: Color = made.get_shader_parameter("albedo_color")
	near(colour.r, 0.5, 0.001, "the made material keeps its colour")


## A broken settings file must not be able to put the game in a state the
## shader was not written for.
func _test_the_amount_is_clamped() -> void:
	heading("the dial")
	Psx.set_amount(-0.5)
	near(Psx.amount(), Psx.MIN_AMOUNT, 0.0001, "the amount clamps at the bottom")
	Psx.set_amount(2.0)
	near(Psx.amount(), Psx.MAX_AMOUNT, 0.0001, "the amount clamps at the top")
	Psx.set_amount(0.42)
	near(Psx.amount(), 0.42, 0.0001, "the amount is kept as it was given")

	Psx.set_affine(true)
	ok(Psx.affine(), "the affine switch turns on")
	Psx.set_affine(false)
	ok(not Psx.affine(), "the affine switch turns off")

	Psx.set_amount(Psx.DEFAULT_AMOUNT)
	Psx.set_affine(Psx.DEFAULT_AFFINE)


## The settings have to survive a trip through the file.
func _test_the_settings_round_trip() -> void:
	heading("the settings file")
	var config := ConfigFile.new()
	Psx.write_config(config, 0.35, true)

	var reread := ConfigFile.new()
	var error := reread.parse(config.encode_to_text())
	same(error, OK, "the settings file parses back")
	var values := Psx.read_config(reread)
	near(float(values["amount"]), 0.35, 0.0001, "the amount survives the round trip")
	ok(bool(values["affine"]), "the affine switch survives the round trip")

	# A file from an older build must not wipe the current settings.
	var empty := ConfigFile.new()
	var missing := Psx.read_config(empty)
	near(float(missing["amount"]), Psx.amount(), 0.0001,
		"a missing key keeps the current amount")
	ok(bool(missing["affine"]) == Psx.affine(),
		"a missing key keeps the current affine switch")


## The slider in the menu has to turn the dial.
func _test_the_picker_is_wired() -> void:
	heading("the picker")
	var tree := Engine.get_main_loop() as SceneTree
	var menu := MenuScene.instantiate()
	tree.root.add_child(menu)

	var slider := menu.get_node_or_null(SLIDER_PATH) as HSlider
	var label := menu.get_node_or_null(LABEL_PATH) as Label
	var toggle := menu.get_node_or_null(TOGGLE_PATH) as CheckButton

	ok(slider != null, "the settings panel has a PSX slider")
	ok(label != null, "the settings panel shows the amount")
	ok(toggle != null, "the settings panel has an affine switch")

	if slider != null:
		same(int(slider.min_value), 0, "the slider starts at zero")
		same(int(slider.max_value), 100, "the slider goes up to a hundred")
		same(int(slider.step), 1, "the slider moves in whole percent")

		slider.value = 37.0
		near(WsGame.psx_amount, 0.37, 0.0001, "the slider sets the amount")
		near(Psx.amount(), 0.37, 0.0001, "the slider reaches the shader")
		if label != null:
			text(label.text, "37%", "the label shows the amount")

	if toggle != null:
		toggle.button_pressed = true
		ok(WsGame.psx_affine, "the switch sets the affine flag")
		ok(Psx.affine(), "the switch reaches the shader")
		toggle.button_pressed = false
		ok(not Psx.affine(), "the switch turns the warping off again")

	# Put the game back the way it was found.
	WsGame.psx_amount = Psx.DEFAULT_AMOUNT
	WsGame.psx_affine = Psx.DEFAULT_AFFINE
	Psx.set_amount(Psx.DEFAULT_AMOUNT)
	Psx.set_affine(Psx.DEFAULT_AFFINE)

	menu.free()
