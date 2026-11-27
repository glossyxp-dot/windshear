# WindShear — loads the sections and keeps track of the one that is running
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
## The section manager, registered as `WsSections`.
##
## It does two things. It loads a section scene when the game asks for one,
## and it keeps the record of the section that is running: its id, where the
## player starts, where the player ends and where the speedrun split goes.
##
## The trigger of a section registers itself when it enters the tree. That
## is the only handshake between the data the designer laid out and the
## game that runs it.
extends Node

## The campaign index. It says which sections exist and where they live.
const INDEX_PATH := "res://data/sections/index.json"

## The designer-authored point.
const KitPoint := preload("res://world/kit/ws_kit_point.gd")
## The gate schedule.
const Schedule := preload("res://addons/windshear/world/ws_schedule.gd")
## The gates of the running section.
const GateService := preload("res://addons/windshear/world/ws_gate_service.gd")

## The section that is running.
var current_section: Node = null
## The id of the section that is running.
var current_section_id := ""
## The checkpoint the player enters the section at.
var start_checkpoint_id := ""
## The checkpoint the player ends the section at.
var end_checkpoint_id := ""
## The marker the speedrun split system reads.
var split_marker_id := ""

## Whether the manager says out loud when something is wrong.
##
## The test suite turns this off while it provokes the failures on purpose,
## so a run of the suite does not print warnings that look like accidents.
var announce_problems := true

## The scene path of every section, read once from the index.
var _paths: Dictionary = {}

## Every section id, in campaign order.
var _order: PackedStringArray = PackedStringArray()

## What the campaign index says about every section.
var _entries: Dictionary = {}

## The gate schedule.
var _schedule: Dictionary = {}

## The gate schedule, by gate id.
var _schedule_index: Dictionary = {}

## The gates of the running section.
var _gates: WsGateService = null


func _ready() -> void:
	_read_the_index()
	_schedule = Schedule.read()
	_schedule_index = Schedule.index(_schedule)


## The gates of the running section.
##
## The screen that plays the section asks this where the gates are.
func gates() -> WsGateService:
	return _gates


## Every section id, in campaign order.
func section_ids() -> PackedStringArray:
	if _order.is_empty():
		_read_the_index()
	return _order


## What the campaign index says about a section.
##
## An empty dictionary means the index has no section with that id.
func section_entry(section_id: String) -> Dictionary:
	if _entries.is_empty():
		_read_the_index()
	return _entries.get(section_id, {})


## The section after [param section_id].
##
## An empty string means there is no next section: the campaign is over.
func next_section_id(section_id: String) -> String:
	var ids := section_ids()
	var at := ids.find(section_id)
	if at < 0 or at + 1 >= ids.size():
		return ""
	return ids[at + 1]


## The section after [param section_id] that the designer has actually made.
##
## The campaign is three hundred sections long and most of them are not
## written yet. This walks past the ones that have no scene, so the run
## continues into the next section the designer has finished.
##
## An empty string means there is nothing left to play.
func next_authored_section_id(section_id: String) -> String:
	var ids := section_ids()
	var at := ids.find(section_id)
	if at < 0:
		return ""
	for index in range(at + 1, ids.size()):
		var candidate := ids[index]
		var path := str(section_entry(candidate).get("scene_path", ""))
		if path.is_empty():
			continue
		if ResourceLoader.exists(path):
			return candidate
	return ""


## The state of a gate on a frame of the global clock.
##
## "closed" is the answer when the schedule has no such gate.
func gate_state(gate_id: String, global_frame: int) -> String:
	if _gates != null:
		return _gates.state_of(gate_id, global_frame)
	var timing: Dictionary = _schedule_index.get(gate_id, {})
	return Schedule.state_at(timing, global_frame)


## Where the scene of a section lives.
##
## An empty string means the campaign index has no section with that id.
func scene_path_for(section_id: String) -> String:
	if _paths.is_empty():
		_read_the_index()
	return str(_paths.get(section_id, ""))


## Loads a section and makes it the one that is running.
##
## The old section is freed. Returns false when there is no such section or
## when its scene could not be loaded.
func load_section(section_id: String) -> bool:
	var path := scene_path_for(section_id)
	if path.is_empty():
		_warn("the campaign index has no section called %s" % section_id)
		return false
	var packed: PackedScene = load(path)
	if packed == null:
		_warn("%s could not be loaded" % path)
		return false
	var scene := packed.instantiate()
	if scene == null:
		_warn("%s could not be opened" % path)
		return false

	if current_section != null:
		current_section.queue_free()
		current_section = null
	current_section_id = ""
	start_checkpoint_id = ""
	end_checkpoint_id = ""
	split_marker_id = ""

	add_child(scene)
	current_section = scene
	current_section_id = section_id
	_configure_gates(scene)
	return true


## Puts the running section away and forgets it.
##
## The section is freed and the three marker ids are cleared, so a screen
## that is not playing a section does not have half of one left over.
func unload_section() -> void:
	if current_section != null:
		current_section.queue_free()
		current_section = null
	current_section_id = ""
	start_checkpoint_id = ""
	end_checkpoint_id = ""
	split_marker_id = ""
	_configure_gates(null)


## Opens and closes the gates of the running section.
##
## The clock is the run clock, so a gate that cycles keeps its rhythm from
## one section to the next.
func _physics_process(_delta: float) -> void:
	if _gates == null:
		return
	_gates.update(_global_frame())


## Gives the gates of a section their bodies and puts them in their first
## state.
func _configure_gates(section: Node) -> void:
	if _gates == null:
		_gates = GateService.new()
	_gates.configure(section, _schedule)
	_gates.update(_global_frame())


## The frame of the global clock.
##
## The run clock is the clock the schedule is written against. When there
## is no game yet, the clock is at zero.
func _global_frame() -> int:
	var game := get_node_or_null("/root/WsGame")
	if game == null:
		return 0
	return int(game.get("run_frames"))


## Takes the registration of a section trigger.
##
## The id has to be in the campaign index and the three markers have to
## point at something in the same section. A section that loads but cannot
## be finished is the failure this catches.
func register_section(trigger: Node) -> bool:
	var section_id := str(trigger.get("section_id"))
	if section_id.is_empty():
		_warn("a section trigger has no section id")
		return false
	if scene_path_for(section_id).is_empty():
		_warn("a section trigger says %s and the campaign index does not" % [
			section_id])
		return false

	var points := _points_in(_section_root(trigger))
	var start := str(trigger.get("start_checkpoint_id"))
	var end := str(trigger.get("end_checkpoint_id"))
	var split := str(trigger.get("split_marker_id"))

	if not _resolves(points, start, KitPoint.Kind.CHECKPOINT):
		_warn("%s has a start checkpoint called %s and nothing answers to it" % [
			section_id, start])
		return false
	if not _resolves(points, end, KitPoint.Kind.CHECKPOINT):
		_warn("%s has an end checkpoint called %s and nothing answers to it" % [
			section_id, end])
		return false
	if not _resolves(points, split, KitPoint.Kind.SPLIT_MARKER):
		_warn("%s has a split marker called %s and nothing answers to it" % [
			section_id, split])
		return false

	current_section_id = section_id
	start_checkpoint_id = start
	end_checkpoint_id = end
	split_marker_id = split
	return true


## Where a checkpoint of the running section is.
##
## The origin means there is no such point.
func checkpoint_position(point_id: String) -> Vector3:
	if current_section == null:
		return Vector3.ZERO
	for point in _points_in(current_section):
		if str(point.get("point_id")) == point_id:
			return point.global_position
	return Vector3.ZERO


## The top of the section a node is in.
func _section_root(node: Node) -> Node:
	var current := node
	while current.get_parent() is Node3D:
		current = current.get_parent()
	return current


## Every designer-authored point under a node.
func _points_in(root: Node) -> Array:
	var points: Array = []
	_collect_points(root, points)
	return points


## Collects the points under a node.
func _collect_points(node: Node, points: Array) -> void:
	for child in node.get_children():
		if child is KitPoint:
			points.append(child)
		_collect_points(child, points)


## Whether a point with that id and that kind is there.
func _resolves(points: Array, point_id: String, kind: int) -> bool:
	if point_id.is_empty():
		return false
	for point in points:
		if str(point.get("point_id")) != point_id:
			continue
		return int(point.get("kind")) == kind
	return false


## Says out loud that something is wrong, when it is allowed to.
func _warn(message: String) -> void:
	if announce_problems:
		push_warning(message)


## Reads the scene path of every section out of the campaign index.
func _read_the_index() -> void:
	_paths.clear()
	_order = PackedStringArray()
	_entries.clear()
	if not FileAccess.file_exists(INDEX_PATH):
		return
	var file := FileAccess.open(INDEX_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for section in parsed.get("sections", []):
		var section_id := str(section.get("id", ""))
		var path := str(section.get("scene_path", ""))
		if section_id.is_empty() or path.is_empty():
			continue
		_paths[section_id] = path
		_order.append(section_id)
		_entries[section_id] = section
