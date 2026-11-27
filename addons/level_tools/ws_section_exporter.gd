# WindShear — turns the section scenes into the data the tools read
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
## Reads a section scene and writes the section data beside it.
##
## The campaign index says which sections exist and where their scenes live.
## The schedule says when the gates open. The scene says what is in it. This
## reads all three and writes one JSON file per section, which the tests and
## the outside tools read.
##
## The game does not read that file. The game loads the scene, because the
## scene is the thing the designer laid out and the thing the game runs.
## The JSON is the mirror CI compares against, so a scene that was not
## exported fails the build instead of shipping data nobody looked at.
##
## It is the same code behind the editor button and behind the headless run,
## so what the designer exports by hand and what CI checks are the same
## thing.
extends RefCounted
class_name WSSectionExporter

## The campaign index. It says which sections exist.
const INDEX_PATH := "res://data/sections/index.json"
## The gate schedule. It says when the gates open.
const SCHEDULE_PATH := "res://data/schedule.json"

## The designer-authored point this exporter reads.
const KitPoint := preload("res://world/kit/ws_kit_point.gd")

## The schema the exported file carries, so a reader knows what it is.
const SCHEMA := "windshear.section.v1"

## What went wrong, one line per problem.
##
## An empty list means the scene and the schedule agree.
var problems: PackedStringArray = []


## The path the data for a section goes to.
##
## It sits next to the scene, with the same name and a different ending.
static func output_path(scene_path: String) -> String:
	return scene_path.get_basename() + ".json"


## Every section scene that exists.
##
## The index has three hundred sections and most of them are not written
## yet, so only the ones with a scene on disk are listed.
func authored_scenes() -> PackedStringArray:
	var paths := PackedStringArray()
	for section in _index().get("sections", []):
		var scene_path := str(section.get("scene_path", ""))
		if scene_path.is_empty():
			continue
		if ResourceLoader.exists(scene_path):
			paths.append(scene_path)
	return paths


## Builds the data for one section.
##
## Returns the dictionary the exporter would write. The problems are in
## [member problems] either way.
##
## The section id is looked up in the campaign index when it is not given.
## A test can give it, so a fixture that is not in the index can still be
## read.
func build(scene_path: String, section_id: String = "") -> Dictionary:
	problems = PackedStringArray()

	if section_id.is_empty():
		section_id = _section_id_for(scene_path)
	var section := _index_entry(section_id)

	var packed: PackedScene = load(scene_path)
	if packed == null:
		problems.append("%s could not be loaded" % scene_path)
		return {}

	var scene := packed.instantiate()
	if scene == null:
		problems.append("%s could not be opened" % scene_path)
		return {}

	var points := _read_points(scene)
	var metadata := _read_metadata(scene, section_id, section)
	scene.free()

	var clean := _check_points(points, section_id)
	var gates := _merge_gates(clean, _gates_for(section_id), section_id)

	return {
		"_meta": {
			"spdx": "CC-BY-SA-4.0",
			"spdx_file_copyright_text": "2026 the WINDSHEAR contributors",
			"license": "CC-BY-SA-4.0",
			"schema": SCHEMA,
			"description": "The compiled data of one section: the points in it and the timing of every gate.",
			"source": scene_path,
			"generator": "addons/level_tools/ws_section_exporter.gd",
			"tick_rate": 60,
		},
		"version": 1,
		"section": {
			"id": section_id,
			"chapter": str(section.get("chapter", "")),
			"display_name": str(section.get("display_name", "")),
			"difficulty": int(section.get("difficulty", 0)),
			"par_time_frames": int(section.get("par_time_frames", 0)),
			"scene_path": scene_path,
			"authored": true,
			"metadata": metadata,
			"points": clean,
			"gates": gates,
		},
	}


## Writes the data for one section.
##
## Returns false when there are problems, because a file that says the
## scene is wrong is not worth writing.
func write(scene_path: String, section_id: String = "") -> bool:
	var data := build(scene_path, section_id)
	if not problems.is_empty():
		return false
	var file := FileAccess.open(output_path(scene_path), FileAccess.WRITE)
	if file == null:
		problems.append("the section data could not be written")
		return false
	file.store_string(to_text(data))
	return true


## Checks the data for one section against its scene.
##
## Returns false when the file on disk is out of date or when the scene and
## the schedule disagree. Nothing is written.
func check(scene_path: String, section_id: String = "") -> bool:
	var data := build(scene_path, section_id)
	if not problems.is_empty():
		return false
	var path := output_path(scene_path)
	if not FileAccess.file_exists(path):
		problems.append("%s has not been exported yet" % path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		problems.append("%s could not be read" % path)
		return false
	if file.get_as_text() != to_text(data):
		problems.append("%s is out of date, export it again" % path)
		return false
	return true


## Writes the data for every section that has a scene.
func write_all() -> bool:
	var passed := true
	for scene_path in authored_scenes():
		if not write(scene_path):
			passed = false
	return passed


## Checks the data for every section that has a scene.
func check_all() -> bool:
	var passed := true
	for scene_path in authored_scenes():
		if not check(scene_path):
			passed = false
	return passed


## The text of the exported file.
##
## Godot sorts the keys, so the same scene always gives the same bytes and
## a check never fails over the order of two lines.
func to_text(data: Dictionary) -> String:
	return JSON.stringify(data, "\t") + "\n"


## Reads every point in a scene, sorted by where it sits in the scene.
##
## The sort is what makes the exported file stable. The order the points
## come out of the scene tree is not a promise, and a file that reshuffles
## itself every export is a file nobody reviews.
func _read_points(scene: Node) -> Array:
	var nodes: Array = []
	_collect_points(scene, nodes)
	var data: Array = []
	for node in nodes:
		data.append(node.to_data(scene))
	data.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("node", "")) < str(b.get("node", "")))
	return data


## Collects every designer-authored point in a scene.
func _collect_points(node: Node, points: Array) -> void:
	for child in node.get_children():
		if child is KitPoint:
			points.append(child)
		_collect_points(child, points)


## Reads the metadata the section root carries and checks it.
##
## The root may repeat what the campaign index already says. When it does,
## the two have to agree, because a section that says it is the third
## section of a chapter and the index says it is the fourth is one of those
## mistakes that only shows up in the game.
func _read_metadata(scene: Node, section_id: String, section: Dictionary) -> Dictionary:
	var metadata := {
		"section_id": "",
		"display_name": "",
		"difficulty": 0,
		"par_time_frames": 0,
	}
	if not "section_id" in scene:
		return metadata

	var claimed := str(scene.get("section_id"))
	metadata["section_id"] = claimed
	if not claimed.is_empty() and claimed != section_id:
		problems.append("the scene says it is %s and the index says %s" % [
			claimed, section_id])

	var name := str(scene.get("display_name"))
	metadata["display_name"] = name
	if not name.is_empty() and name != str(section.get("display_name", "")):
		problems.append("the scene calls itself %s and the index calls it %s" % [
			name, str(section.get("display_name", ""))])

	var difficulty := int(scene.get("difficulty"))
	metadata["difficulty"] = difficulty
	if difficulty > 0 and difficulty != int(section.get("difficulty", 0)):
		problems.append("the scene says it is difficulty %d and the index says %d" % [
			difficulty, int(section.get("difficulty", 0))])

	var par := int(scene.get("par_time_frames"))
	metadata["par_time_frames"] = par
	if par > 0 and par != int(section.get("par_time_frames", 0)):
		problems.append("the scene says its par time is %d frames and the index says %d" % [
			par, int(section.get("par_time_frames", 0))])

	return metadata


## Writes the name, the difficulty and the par time of a section scene into
## the campaign index.
##
## The root of a scene may repeat what the index says. When the designer
## changes one of those numbers in the Inspector, the index has to hear
## about it, and the index is a JSON file the designer should not have to
## edit by hand. So the dock does it for them.
##
## Only the one entry is rewritten. The rest of the file is left byte for
## byte alone, because the index is three hundred sections long and a
## reshuffled file is a file nobody reviews.
##
## Returns false when there is no such section in the index, or when the
## scene could not be read.
func update_index(scene_path: String, section_id: String = "") -> bool:
	problems = PackedStringArray()
	if section_id.is_empty():
		section_id = _section_id_for(scene_path)
	var section := _index_entry(section_id)
	if section.is_empty():
		problems.append("the campaign index has no section called %s" % section_id)
		return false

	var packed: PackedScene = load(scene_path)
	if packed == null:
		problems.append("%s could not be loaded" % scene_path)
		return false
	var scene := packed.instantiate()
	if scene == null:
		problems.append("%s could not be opened" % scene_path)
		return false

	var metadata := _read_metadata(scene, section_id, section)
	scene.free()

	# The scene is allowed to leave a number out, and then the index keeps
	# saying it. Only what the scene states is written.
	var name := str(metadata.get("display_name", ""))
	if name.is_empty():
		name = str(section.get("display_name", ""))
	var difficulty := int(metadata.get("difficulty", 0))
	if difficulty <= 0:
		difficulty = int(section.get("difficulty", 0))
	var par := int(metadata.get("par_time_frames", 0))
	if par <= 0:
		par = int(section.get("par_time_frames", 0))

	var text := _read_text(INDEX_PATH)
	if text.is_empty():
		problems.append("the campaign index could not be read")
		return false

	var updated := _replace_in_index_entry(text, section_id, name, difficulty, par)
	if updated == text:
		problems.append("the campaign index could not be rewritten")
		return false

	var file := FileAccess.open(INDEX_PATH, FileAccess.WRITE)
	if file == null:
		problems.append("the campaign index could not be written")
		return false
	file.store_string(updated)
	file.close()

	# The metadata check complains that the scene and the index disagree.
	# That disagreement is the thing this call came to fix, so the list is
	# cleared and the dock says it worked.
	problems = PackedStringArray()
	return true


## Rewrites the three fields of one section entry in the index text.
##
## The entry is found by its id, and the fields are replaced inside that
## entry alone. Everything else in the file is left as it was.
func _replace_in_index_entry(text: String, section_id: String, name: String,
		difficulty: int, par: int) -> String:
	var marker := "\"id\": \"%s\"" % section_id
	var at := text.find(marker)
	if at < 0:
		return text

	var start := text.rfind("{", at)
	var finish := text.find("}", at)
	if start < 0 or finish < 0:
		return text
	var entry := text.substr(start, finish - start + 1)

	var replaced := entry
	replaced = _replace_field(replaced, "display_name", "\"%s\"" % name)
	replaced = _replace_field(replaced, "difficulty", str(difficulty))
	replaced = _replace_field(replaced, "par_time_frames", str(par))
	if replaced == entry:
		return text
	return text.substr(0, start) + replaced + text.substr(finish + 1)


## Replaces one field of a JSON object text.
##
## Only the value is replaced. The comma and the spacing around it are
## left alone, so the rewritten entry looks like the rest of the file.
func _replace_field(entry: String, field: String, value: String) -> String:
	var marker := "\"%s\":" % field
	var at := entry.find(marker)
	if at < 0:
		return entry
	var colon := entry.find(":", at)
	var line_end := entry.find("\n", at)
	if line_end < 0:
		line_end = entry.length()
	var value_start := colon + 1
	while value_start < line_end and entry[value_start] in [" ", "\t"]:
		value_start += 1

	var value_end := value_start
	if value_start < line_end and entry[value_start] == "\"":
		var closing := entry.find("\"", value_start + 1)
		if closing < 0 or closing > line_end:
			return entry
		value_end = closing + 1
	else:
		while value_end < line_end and entry[value_end] in ["0", "1", "2", "3", "4",
				"5", "6", "7", "8", "9", "-", ".", "e", "E"]:
			value_end += 1

	return entry.substr(0, value_start) + value + entry.substr(value_end)


## Reads a text file into a string.
func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


## Checks the points of one section and returns them as plain data.
##
## A point with no id, a repeated id, a point that says it belongs to
## another section, a section without exactly one trigger, and markers that
## do not resolve are all problems. The points still come back, so the
## designer can see what the exporter read.
func _check_points(points: Array, section_id: String) -> Array:
	var data: Array = []
	var seen: Dictionary = {}
	var triggers: Array = []

	for point in points:
		var point_data: Dictionary = point
		var point_id := str(point_data.get("id", ""))
		var kind := str(point_data.get("kind", ""))

		if point_id.is_empty():
			problems.append("%s has a %s with no id" % [section_id, kind])
		elif seen.has(point_id):
			problems.append("%s has two points called %s" % [section_id, point_id])
		seen[point_id] = true

		var claimed := str(point_data.get("section_id", ""))
		if not claimed.is_empty() and claimed != section_id:
			problems.append("%s has a point that says it belongs to %s" % [
				section_id, claimed])

		if kind == "section_trigger":
			triggers.append(point_data)

		data.append(point_data)

	if points.size() > 0 and triggers.size() != 1:
		problems.append("%s has %d section triggers, it needs exactly one" % [
			section_id, triggers.size()])
	if triggers.size() > 0:
		var trigger: Dictionary = triggers[0]
		if triggers.size() == 1 and str(trigger.get("node", "")).get_file() != "SectionTrigger":
			problems.append("%s has a section trigger that is not called SectionTrigger" % [
				section_id])
		_check_markers(trigger, data, section_id)

	return data


## Checks that the three markers of the trigger point at something.
##
## A section that loads but cannot be finished is the failure this catches.
## The start and the end have to be checkpoints and the split has to be a
## split marker, all inside the same section.
func _check_markers(trigger: Dictionary, points: Array, section_id: String) -> void:
	_check_marker(trigger, "start_checkpoint_id", "checkpoint", points, section_id)
	_check_marker(trigger, "end_checkpoint_id", "checkpoint", points, section_id)
	_check_marker(trigger, "split_marker_id", "split_marker", points, section_id)


## Checks one marker of the trigger.
func _check_marker(trigger: Dictionary, field: String, kind: String,
		points: Array, section_id: String) -> void:
	var marker_id := str(trigger.get(field, ""))
	if marker_id.is_empty():
		problems.append("%s has a section trigger with no %s" % [section_id, field])
		return
	for point in points:
		if str(point.get("id", "")) != marker_id:
			continue
		if str(point.get("kind", "")) != kind:
			problems.append("%s has a %s called %s and it is a %s" % [
				section_id, field, marker_id, str(point.get("kind", ""))])
		return
	problems.append("%s has a %s called %s and nothing in the section answers to it" % [
		section_id, field, marker_id])


## Puts the schedule timing on the gates the scene holds.
##
## The scene says a gate is there and where it is. The schedule says when it
## opens. A gate in one and not the other is a problem, because the game
## would have a gate it cannot time or a timing with no gate to apply it to.
func _merge_gates(points: Array, schedule_gates: Array, section_id: String) -> Array:
	var gates: Array = []
	var matched: Dictionary = {}

	for point in points:
		if str(point.get("kind", "")) != "regulation_gate":
			continue
		var gate_id := str(point.get("id", ""))
		var timing := _find_gate(schedule_gates, gate_id)
		if timing.is_empty():
			problems.append("%s has a gate called %s and the schedule does not" % [
				section_id, gate_id])
			continue
		matched[gate_id] = true
		gates.append({
			"id": gate_id,
			"state": str(timing.get("state", "open")),
			"cycle_period_frames": int(timing.get("cycle_period_frames", 0)),
			"phase_offset_frames": int(timing.get("phase_offset_frames", 0)),
			"windows": _windows(timing.get("windows", [])),
			"transform": point.get("transform", {}),
		})

	for timing in schedule_gates:
		var gate_id := str(timing.get("gate_id", ""))
		if not matched.has(gate_id):
			problems.append("%s has a gate called %s in the schedule and not in the scene" % [
				section_id, gate_id])

	return gates


## Finds one gate in the schedule.
func _find_gate(schedule_gates: Array, gate_id: String) -> Dictionary:
	for timing in schedule_gates:
		if str(timing.get("gate_id", "")) == gate_id:
			return timing
	return {}


## The windows of a gate, with the frame numbers as whole numbers.
##
## JSON gives every number back as a float. A frame is a frame, so the
## window is written with whole numbers and the file reads like the
## schedule it came from.
func _windows(windows: Variant) -> Array:
	var result: Array = []
	if typeof(windows) != TYPE_ARRAY:
		return result
	for window in windows:
		var end_frame: Variant = window.get("end_frame", null)
		result.append({
			"start_frame": int(window.get("start_frame", 0)),
			"end_frame": null if end_frame == null else int(end_frame),
			"state": str(window.get("state", "open")),
		})
	return result


## The gates of one section.
func _gates_for(section_id: String) -> Array:
	for chapter in _schedule().get("chapters", []):
		for section in chapter.get("sections", []):
			if str(section.get("section_id", "")) == section_id:
				return section.get("gates", [])
	return []


## The id of the section a scene belongs to.
func _section_id_for(scene_path: String) -> String:
	for section in _index().get("sections", []):
		if str(section.get("scene_path", "")) == scene_path:
			return str(section.get("id", ""))
	return ""


## One entry of the campaign index.
func _index_entry(section_id: String) -> Dictionary:
	for section in _index().get("sections", []):
		if str(section.get("id", "")) == section_id:
			return section
	return {}


## The campaign index.
func _index() -> Dictionary:
	return _read_json(INDEX_PATH)


## The gate schedule.
func _schedule() -> Dictionary:
	return _read_json(SCHEDULE_PATH)


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
