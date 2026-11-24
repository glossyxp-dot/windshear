# WindShear — the PSX look (global shader controls)
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
## The PSX look is four things: vertex snapping, affine texture warping,
## 5-bit colour and ordered dithering. The player chooses how much of it to
## apply.
##
## The global shader uniform keeps this cheap. The amount is registered once
## in `project.godot` under `shader_globals/`, and every material using
## `ws_psx.gdshader` reads it. Moving the slider changes the whole game at
## once. No material resource changes, and no per-frame shader parameter push.
extends RefCounted
class_name WsPsx

## The global shader uniform that carries the amount.
const GLOBAL_AMOUNT := "psx_amount"
## The global shader uniform that carries the affine-texturing toggle.
const GLOBAL_AFFINE := "psx_affine"
## The shader itself.
const PSX_SHADER := preload("res://addons/windshear/render/ws_psx.gdshader")
## The config section the settings live in.
const CONFIG_SECTION := "graphics"
## The smallest amount, which means "no PSX at all".
const MIN_AMOUNT := 0.0
## The largest amount, which means "the full 1995 look".
const MAX_AMOUNT := 1.0
## The amount used when the player has never opened the settings.
const DEFAULT_AMOUNT := 1.0
## Whether the textures swim when the player has never opened the settings.
## Off by default: warped textures are hard to read.
const DEFAULT_AFFINE := false


## The current amount, from [constant MIN_AMOUNT] to [constant MAX_AMOUNT].
static var _amount := DEFAULT_AMOUNT
## True when the textures swim.
static var _affine := DEFAULT_AFFINE


## The amount of PSX currently applied.
static func amount() -> float:
	return _amount


## Sets the amount of PSX and pushes it to the renderer.
##
## The value is clamped, so a broken config file cannot put the game into a
## state the shader was not written for.
static func set_amount(value: float) -> void:
	_amount = clampf(value, MIN_AMOUNT, MAX_AMOUNT)
	_push_amount()


## True when the affine texture warping is on.
static func affine() -> bool:
	return _affine


## Turns the affine texture warping on or off and pushes it to the renderer.
static func set_affine(enabled: bool) -> void:
	_affine = enabled
	_push_affine()


## Reads the PSX settings out of a config file.
##
## Missing keys keep the current value, which is how a settings file from an
## older build keeps working.
static func read_config(config: ConfigFile) -> Dictionary:
	return {
		"amount": float(config.get_value(CONFIG_SECTION, "psx_amount", _amount)),
		"affine": bool(config.get_value(CONFIG_SECTION, "psx_affine", _affine)),
	}


## Writes the PSX settings into a config file.
static func write_config(config: ConfigFile, amount: float, affine: bool) -> void:
	config.set_value(CONFIG_SECTION, "psx_amount", amount)
	config.set_value(CONFIG_SECTION, "psx_affine", affine)


## Builds a material that uses the PSX shader.
##
## The art in this project is made by hand, so this helper keeps that material
## easy to write. Give it a colour, tweak the result in the inspector, and it
## behaves like any other material.
static func make_material(albedo: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = PSX_SHADER
	material.set_shader_parameter("albedo_color", albedo)
	material.set_shader_parameter("use_albedo_texture", false)
	return material


## Sets the affine knob on every PSX material below [param root].
##
## Every material keeps it's own local affine knob. The amount of swimming is an
## art decision: some surfaces should swim and others should not. Setting the
## knob to 1.0 means "follow the player's master switch"; setting it to 0.0
## means "never swim". The player's switch lives in the global `psx_affine`
## uniform and the shader multiplies it in.
static func apply_affine(root: Node, enabled: bool) -> void:
	for node in _psx_materials(root):
		var material := node as ShaderMaterial
		material.set_shader_parameter("affine_warp", 1.0 if enabled else 0.0)


## Every PSX material below [param root].
static func _psx_materials(root: Node) -> Array[ShaderMaterial]:
	var found: Array[ShaderMaterial] = []
	_collect_materials(root, found)
	return found


## Walks the tree and collects the PSX materials.
static func _collect_materials(node: Node, found: Array[ShaderMaterial]) -> void:
	for child in node.get_children():
		var mesh := child as MeshInstance3D
		if mesh != null:
			var material := mesh.material_override as ShaderMaterial
			if material != null and material.shader == PSX_SHADER:
				found.append(material)
		_collect_materials(child, found)


## Pushes the amount to the renderer.
static func _push_amount() -> void:
	if RenderingServer.global_shader_parameter_get_list().has(GLOBAL_AMOUNT):
		RenderingServer.global_shader_parameter_set(GLOBAL_AMOUNT, _amount)


## Pushes the affine toggle to the renderer.
static func _push_affine() -> void:
	if RenderingServer.global_shader_parameter_get_list().has(GLOBAL_AFFINE):
		RenderingServer.global_shader_parameter_set(GLOBAL_AFFINE, 1.0 if _affine else 0.0)
