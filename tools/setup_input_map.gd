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
## Only the [code][input][/code] section is touched. `ProjectSettings.save()`
## rewrites the whole file and drops every setting that happens to equal the
## engine default — the stretch aspect and the physics tick rate both
## disappear that way — so the new section is generated through Godot and
## then spliced back into the original text.
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
		"toggle_help": [_key(KEY_F1), _key(KEY_H)],
	}


func _initialize() -> void:
	var original := _read_file("res://project.godot")
	if original == "":
		push_error("could not read project.godot")
		quit(1)
		return

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

	# Godot has just rewritten the whole file. Take the [input] section it
	# produced and put it back into the text we started with, so every other
	# setting, comment and section order survives untouched.
	var generated := _read_file("res://project.godot")
	var new_section := _extract_section(generated, "input")
	var old_section := _extract_section(original, "input")
	if new_section == "":
		push_error("the generated file has no [input] section")
		quit(1)
		return

	var spliced := original
	if old_section != "":
		spliced = spliced.replace(old_section, new_section)
	else:
		spliced = spliced.replace("[input]", new_section.rstrip("\n"))
	_write_file("res://project.godot", spliced)
	print("wrote %d input actions to project.godot" % bindings.size())
	quit(0)


## Reads a whole file.
func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


## Writes a whole file.
func _write_file(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text)


## Returns the text of one section, header included.
##
## A section runs from its [code][name][/code] header to the next header or
## to the end of the file. Only a line that is exactly the header counts:
## the comment at the top of `project.godot` mentions `[input]` in passing.
func _extract_section(text: String, name: String) -> String:
	var lines := text.split("\n")
	var header := "[%s]" % name
	var start := -1
	for index in lines.size():
		if lines[index].strip_edges() == header:
			start = index
			break
	if start < 0:
		return ""
	var end := lines.size()
	for index in range(start + 1, lines.size()):
		var line := lines[index].strip_edges()
		if line.begins_with("[") and line.ends_with("]"):
			end = index
			break
	return "\n".join(lines.slice(start, end))
