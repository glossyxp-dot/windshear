# WindShear — the level tools dock
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
## The level tools, in the editor.
##
## Three buttons and a box to type in. A section scene is made from the
## campaign index, so it starts out with the right ids and the right gates.
## The export writes the data the game loads, and the check says whether the
## data still matches the scenes.
##
## Everything here does the same thing as the headless run does, so a
## section that passes in the editor passes in CI.
@tool
extends EditorPlugin

## The exporter.
const Exporter := preload("res://addons/level_tools/ws_section_exporter.gd")
## The builder that makes a new section scene.
const Builder := preload("res://addons/level_tools/ws_section_builder.gd")

## The dock the tools live in.
var _dock: VBoxContainer
## Where the section id is typed.
var _section_input: LineEdit
## What the tools said last.
var _status: Label


func _enter_tree() -> void:
	_build_the_dock()


func _exit_tree() -> void:
	if _dock == null:
		return
	remove_control_from_docks(_dock)
	_dock.queue_free()
	_dock = null


## Builds the dock and puts it in the editor.
func _build_the_dock() -> void:
	_dock = VBoxContainer.new()
	_dock.name = "LevelTools"

	var heading := Label.new()
	heading.text = "Level Tools"
	_dock.add_child(heading)

	_section_input = LineEdit.new()
	_section_input.placeholder_text = "2.01"
	_section_input.tooltip_text = "The section to make, for example 2.01."
	_dock.add_child(_section_input)

	var create := Button.new()
	create.text = "create section scene"
	create.pressed.connect(_on_create)
	_dock.add_child(create)

	var export_button := Button.new()
	export_button.text = "export sections"
	export_button.pressed.connect(_on_export)
	_dock.add_child(export_button)

	var check := Button.new()
	check.text = "check sections"
	check.pressed.connect(_on_check)
	_dock.add_child(check)

	_status = Label.new()
	_status.text = ""
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(_status)

	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)


## Makes the section scene, or opens it when it is already there.
func _on_create() -> void:
	var section_id := _section_input.text.strip_edges()
	if section_id.is_empty():
		_set_status("type a section id first, like 2.01")
		return

	var index := _read_json(Exporter.INDEX_PATH)
	var wanted := ""
	var entry: Dictionary = {}
	for section in index.get("sections", []):
		if str(section.get("id", "")) == section_id:
			wanted = str(section.get("scene_path", ""))
			entry = section
			break
	if wanted.is_empty():
		_set_status("the campaign index has no section called %s" % section_id)
		return

	if ResourceLoader.exists(wanted):
		EditorInterface.open_scene_from_path(wanted)
		_set_status("opened %s" % wanted)
		return

	if not _write_a_starter_scene(section_id, wanted, entry):
		return

	EditorInterface.get_resource_filesystem().scan()
	EditorInterface.open_scene_from_path(wanted)
	_set_status("made %s" % wanted)


## Writes a section scene with the ids and the gates the data expects.
func _write_a_starter_scene(section_id: String, scene_path: String,
		entry: Dictionary) -> bool:
	var builder := Builder.new()
	if not builder.build(section_id, scene_path, entry):
		_set_status("the section scene could not be written")
		return false
	return true


## The gates the schedule has for a section.
func _scheduled_gate_ids(section_id: String) -> PackedStringArray:
	var builder := Builder.new()
	return builder.scheduled_gate_ids(section_id)


## Writes the section data.
func _on_export() -> void:
	var exporter := Exporter.new()
	if exporter.write_all():
		EditorInterface.get_resource_filesystem().scan()
		_set_status("the section data was exported")
		return
	_set_status(_problem_text(exporter.problems))


## Checks the section data against the scenes.
func _on_check() -> void:
	var exporter := Exporter.new()
	if exporter.check_all():
		_set_status("the section data matches the scenes")
		return
	_set_status(_problem_text(exporter.problems))


## Says what happened in the dock.
func _set_status(message: String) -> void:
	_status.text = message
	print("level tools: %s" % message)


## The problems as one piece of text.
func _problem_text(problems: PackedStringArray) -> String:
	if problems.is_empty():
		return "something went wrong and nothing said why"
	var lines := PackedStringArray()
	for problem in problems:
		lines.append("problem: %s" % problem)
	return "\n".join(lines)


## Reads a JSON file into a dictionary.
func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
