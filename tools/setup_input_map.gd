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
## The bindings live here instead of in `project.godot` because a hand-written
## input section is a wall of [code]Object(InputEventKey, ...)[/code] lines.
## Nobody reviews that wall. This file is one screen long and you can see
## what changed in a diff. Run it after you touch a binding:
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

## A keyboard binding.
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


## The bindings: action name -> list of InputEvent objects.
##
## The scheme, so you don't have to read the table:
##
## [codeblock]
## A / D    run left, run right
## Ctrl     slide
## Space    jump
## Q        ledge grab
## E        interact
## F        filament
## W / S    tilt the camera
## arrows   turn and tilt the camera
## LMB      primary fire
## RMB      alt fire
## [/codeblock]
##
## The mouse has the camera and the two triggers, because the mouse is
## already in the hand that is doing the camera. Everything else sits on the
## keyboard. The arrows are there so the camera still has a keyboard route
## for anybody who would rather not use the mouse at all.
##
## W and S tilt the camera rather than moving Lancer, because the game plays
## on one plane. There is no forward and there is no back. Up and down are
## the only directions a side-on route does not have.
func _bindings() -> Dictionary:
	return {
		"move_left": [_key(KEY_A), _joy_axis(JOY_AXIS_LEFT_X, -1.0),
			_joy_button(JOY_BUTTON_DPAD_LEFT)],
		"move_right": [_key(KEY_D), _joy_axis(JOY_AXIS_LEFT_X, 1.0),
			_joy_button(JOY_BUTTON_DPAD_RIGHT)],
		"jump": [_key(KEY_SPACE), _joy_button(JOY_BUTTON_A)],
		"slip": [_key(KEY_CTRL), _joy_button(JOY_BUTTON_B)],
		"ledge_grab": [_key(KEY_Q), _joy_button(JOY_BUTTON_X)],
		"interact": [_key(KEY_E), _joy_button(JOY_BUTTON_Y)],
		"filament": [_key(KEY_F), _joy_button(JOY_BUTTON_RIGHT_SHOULDER)],
		"primary_fire": [_mouse(MOUSE_BUTTON_LEFT), _joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
		"alt_fire": [_mouse(MOUSE_BUTTON_RIGHT), _joy_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)],
		"reload": [_key(KEY_C), _joy_button(JOY_BUTTON_DPAD_DOWN)],
		"use_item": [_key(KEY_B), _joy_button(JOY_BUTTON_DPAD_UP)],
		"cycle_weapon": [_key(KEY_V), _mouse(MOUSE_BUTTON_WHEEL_UP), _mouse(MOUSE_BUTTON_WHEEL_DOWN),
			_joy_button(JOY_BUTTON_RIGHT_STICK)],
		"look_left": [_joy_axis(JOY_AXIS_RIGHT_X, -1.0)],
		"look_right": [_joy_axis(JOY_AXIS_RIGHT_X, 1.0)],
		"look_up": [_joy_axis(JOY_AXIS_RIGHT_Y, -1.0)],
		"look_down": [_joy_axis(JOY_AXIS_RIGHT_Y, 1.0)],
		"look_key_left": [_key(KEY_LEFT)],
		"look_key_right": [_key(KEY_RIGHT)],
		"look_key_up": [_key(KEY_W), _key(KEY_UP)],
		"look_key_down": [_key(KEY_S), _key(KEY_DOWN)],
		"reset_to_checkpoint": [_key(KEY_R), _joy_button(JOY_BUTTON_BACK)],
		"toggle_splits": [_key(KEY_TAB), _joy_button(JOY_BUTTON_START)],
		"toggle_help": [_key(KEY_F1), _key(KEY_H), _joy_button(JOY_BUTTON_GUIDE)],
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
	_drop_retired_actions(bindings)
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


## Deletes any action that is no longer in the table.
##
## The project is already loaded when this runs, so the old `[input]` section
## is sitting in ProjectSettings and a renamed action would keep living in
## `project.godot` forever. Setting a setting to null is how you get rid of
## one.
func _drop_retired_actions(bindings: Dictionary) -> void:
	for property in ProjectSettings.get_property_list():
		var setting_name := String(property.get("name", ""))
		if not setting_name.begins_with("input/"):
			continue
		if bindings.has(setting_name.substr("input/".length())):
			continue
		ProjectSettings.set_setting(setting_name, null)


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
