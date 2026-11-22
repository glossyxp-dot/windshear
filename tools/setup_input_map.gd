# WindShear — input map generator
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
## Writes the [code][input][/code] section of `project.godot`.
##
## The input map is generated instead of hand-written because the hand-written
## form is a wall of [code]Object(InputEventKey, ...)[/code] lines that nobody
## can review. Run this after changing a binding:
##
## [codeblock]
## godot --headless --path . --script res://tools/setup_input_map.gd
## [/codeblock]
##
## The comment header at the top of `project.godot` is kept.
extends SceneTree

## The key bindings: action name -> list of InputEvent objects.
func _key(physical_keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode
	return event


## A mouse button binding.
func _mouse(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	return event


## A gamepad button binding.
func _joy_button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	return event


## A gamepad axis binding.
func _joy_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event


## The key bindings: action name -> list of InputEvent objects.
func _bindings() -> Dictionary:
	return {
		"move_left": [_key(KEY_A), _key(KEY_LEFT)],
		"move_right": [_key(KEY_D), _key(KEY_RIGHT)],
		"jump": [_key(KEY_SPACE)],
		"slip": [_key(KEY_S), _key(KEY_DOWN), _key(KEY_CTRL)],
		"mantle": [_key(KEY_W), _key(KEY_UP)],
		"filament": [_mouse(MOUSE_BUTTON_RIGHT), _joy_button(JOY_BUTTON_RIGHT_SHOULDER)],
		"look_left": [_joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"look_right": [_joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"look_up": [_joy_axis(JOY_AXIS_LEFT_Y, -1.0)],
		"look_down": [_joy_axis(JOY_AXIS_LEFT_Y, 1.0)],
		"reset_to_checkpoint": [_key(KEY_R)],
		"toggle_splits": [_key(KEY_TAB)],
	}


func _initialize() -> void:
	var header := _read_header()
	var bindings := _bindings()
	for action_name in bindings.keys():
		ProjectSettings.set_setting("input/" + action_name, {
			"deadzone": 0.2,
			"events": bindings[action_name],
		})
	var error := ProjectSettings.save()
	if error != OK:
		push_error("could not save project.godot: %d" % error)
		quit(1)
		return
	if header != "":
		_write_header(header)
	print("wrote %d input actions to project.godot" % bindings.size())
	quit(0)


## Reads the comment header that sits above the settings in project.godot.
func _read_header() -> String:
	var file := FileAccess.open("res://project.godot", FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	var marker_index := text.find("config_version=")
	if marker_index < 0:
		return ""
	var lines := text.substr(0, marker_index).split("\n")
	var kept := PackedStringArray()
	for line in lines:
		var trimmed := line.strip_edges()
		if trimmed.begins_with(";") or trimmed == "":
			kept.append(line)
		else:
			kept.clear()
			break
	return "\n".join(kept).strip_edges()


## Puts the comment header back on top of the file ProjectSettings saved.
func _write_header(header: String) -> void:
	var file := FileAccess.open("res://project.godot", FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	var marker_index := text.find("config_version=")
	if marker_index < 0:
		return
	file = FileAccess.open("res://project.godot", FileAccess.WRITE)
	if file == null:
		return
	file.store_string(header + "\n\n" + text.substr(marker_index))
