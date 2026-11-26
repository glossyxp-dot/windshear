# WindShear — makes a new section scene with the right ids in it
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
## Makes the scene a new section starts from.
##
## A new section has to have the section trigger, the two checkpoints, the
## split marker and the gates the schedule asks for, with the right ids in
## them. Writing those by hand every time is how a section ends up with a
## gate the schedule does not know about.
##
## The builder does that part. The designer does the rest.
extends RefCounted
class_name WSSectionBuilder

## The designer-authored point.
const KitPoint := preload("res://world/kit/ws_kit_point.gd")
## The room shell.
const KitRoom := preload("res://world/kit/ws_kit_room.gd")
## The root of a section.
const KitSection := preload("res://world/kit/ws_section.gd")
## The gate schedule.
const SCHEDULE_PATH := "res://data/schedule.json"


## Makes a section scene and writes it to disk.
##
## The entry is the section's entry in the campaign index. Returns false
## when the scene could not be written.
func build(section_id: String, scene_path: String, entry: Dictionary) -> bool:
	var root := KitSection.new()
	root.name = scene_path.get_file().get_basename()
	root.section_id = section_id
	root.display_name = str(entry.get("display_name", ""))
	root.difficulty = int(entry.get("difficulty", 0))
	root.par_time_frames = int(entry.get("par_time_frames", 0))

	var room := KitRoom.new()
	room.name = "Room"
	root.add_child(room)
	room.owner = root

	var trigger := KitPoint.new()
	trigger.name = "SectionTrigger"
	trigger.kind = KitPoint.Kind.SECTION_TRIGGER
	trigger.point_id = "%s.trigger" % section_id
	trigger.section_id = section_id
	trigger.start_checkpoint_id = "%s.start" % section_id
	trigger.end_checkpoint_id = "%s.end" % section_id
	trigger.split_marker_id = "%s.split" % section_id
	root.add_child(trigger)
	trigger.owner = root

	var start := KitPoint.new()
	start.name = "StartCheckpoint"
	start.kind = KitPoint.Kind.CHECKPOINT
	start.point_id = "%s.start" % section_id
	start.section_id = section_id
	root.add_child(start)
	start.owner = root

	var end := KitPoint.new()
	end.name = "EndCheckpoint"
	end.kind = KitPoint.Kind.CHECKPOINT
	end.point_id = "%s.end" % section_id
	end.section_id = section_id
	end.position = Vector3(0.0, 0.0, 10.0)
	root.add_child(end)
	end.owner = root

	var split := KitPoint.new()
	split.name = "SplitMarker"
	split.kind = KitPoint.Kind.SPLIT_MARKER
	split.point_id = "%s.split" % section_id
	split.section_id = section_id
	root.add_child(split)
	split.owner = root

	for gate_id in scheduled_gate_ids(section_id):
		var gate := KitPoint.new()
		gate.name = safe_name(gate_id)
		gate.kind = KitPoint.Kind.REGULATION_GATE
		gate.point_id = gate_id
		gate.section_id = section_id
		gate.gate_state = "open"
		root.add_child(gate)
		gate.owner = root

	var packed := PackedScene.new()
	var packed_error := packed.pack(root)
	root.free()
	if packed_error != OK:
		return false

	var directory := ProjectSettings.globalize_path(scene_path.get_base_dir())
	DirAccess.make_dir_recursive_absolute(directory)
	return ResourceSaver.save(packed, scene_path) == OK


## The gates the schedule has for a section.
func scheduled_gate_ids(section_id: String) -> PackedStringArray:
	var ids := PackedStringArray()
	var schedule := _read_json(SCHEDULE_PATH)
	for chapter in schedule.get("chapters", []):
		for section in chapter.get("sections", []):
			if str(section.get("section_id", "")) != section_id:
				continue
			for gate in section.get("gates", []):
				ids.append(str(gate.get("gate_id", "")))
	return ids


## A node name Godot will take.
static func safe_name(text: String) -> String:
	return text.replace(".", "_").replace("/", "_")


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
