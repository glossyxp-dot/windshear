# WindShear — the sections run
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
## The kit is only useful if the game can play what the designer made.
##
## These checks are the seam between the two halves of the project: the
## designer lays a section out in the editor, and the section manager loads
## that same scene, finds the trigger, and works out where the player
## starts. If the two halves drift apart, the game quietly plays the wrong
## section, or plays nothing.
extends "res://tests/ws_test.gd"

## The designer-authored point.
const KitPoint := preload("res://world/kit/ws_kit_point.gd")
## The scene the designer plays their section in.
const PlaygroundScene := preload("res://world/playground/section_playground.tscn")

## The section the example data describes.
const EXAMPLE_ID := "P1.01"
## Where the section manager lives.
const MANAGER_PATH := "/root/WsSections"


func suite_name() -> String:
	return "the sections run"


func run_with_scene(scene: Node) -> void:
	_test_the_manager_is_there(scene)
	_test_the_section_loads(scene)
	_test_the_geometry_is_built_at_runtime(scene)
	_test_a_section_that_is_not_in_the_index_is_refused(scene)
	_test_a_trigger_that_points_at_nothing_is_refused(scene)
	_test_the_playground_puts_the_player_at_the_start(scene)


## The manager is an autoload, so it is there before any scene loads.
func _test_the_manager_is_there(scene: Node) -> void:
	heading("the section manager is there")
	var manager := scene.get_node_or_null(MANAGER_PATH)
	ok(manager != null, "the section manager is loaded")
	if manager == null:
		return
	ok(manager.has_method("load_section"), "the manager can load a section")
	ok(manager.has_method("unload_section"), "the manager can put a section away")
	ok(manager.has_method("register_section"), "the manager takes a trigger")
	text(str(manager.call("scene_path_for", EXAMPLE_ID)),
		"res://data/sections/cP1/sP1_01.tscn",
		"the manager knows where the example section lives")
	text(str(manager.call("scene_path_for", "P9.99")), "",
		"the manager does not know a section that was never made")


## The section loads and its trigger says where the player starts.
func _test_the_section_loads(scene: Node) -> void:
	heading("the section loads")
	var manager := scene.get_node_or_null(MANAGER_PATH)
	if manager == null:
		return

	var loaded: bool = manager.call("load_section", EXAMPLE_ID)
	ok(loaded, "the example section loads")
	text(str(manager.get("current_section_id")), EXAMPLE_ID,
		"the manager says which section is running")
	text(str(manager.get("start_checkpoint_id")), "%s.start" % EXAMPLE_ID,
		"the manager knows where the player starts")
	text(str(manager.get("end_checkpoint_id")), "%s.end" % EXAMPLE_ID,
		"the manager knows where the player ends")
	text(str(manager.get("split_marker_id")), "%s.split" % EXAMPLE_ID,
		"the manager knows where the split goes")

	var section: Node = manager.get("current_section")
	ok(section != null, "the running section is held")
	if section == null:
		return
	ok(section.is_inside_tree(), "the running section is in the tree")

	var trigger := _find_point(section, KitPoint.Kind.SECTION_TRIGGER)
	ok(trigger != null, "the section has its trigger")
	if trigger != null:
		text(str(trigger.get("point_id")), "%s.trigger" % EXAMPLE_ID,
			"the trigger carries its own id")


## The geometry is made when the section runs.
##
## The kit pieces build their mesh and their collision in code, so a
## section that is only a handful of numbers in a file has to grow a body
## the player can stand on when it is loaded.
func _test_the_geometry_is_built_at_runtime(scene: Node) -> void:
	heading("the geometry is built when the section runs")
	var manager := scene.get_node_or_null(MANAGER_PATH)
	if manager == null:
		return
	var section: Node = manager.get("current_section")
	if section == null:
		return

	var room := section.get_node_or_null("Room")
	ok(room != null, "the section has its room")
	if room == null:
		return

	ok(room.get_child_count(true) > 0, "the room grew its pieces")
	var bodies := _count_bodies(room)
	ok(bodies >= 1, "the room has a body the player can stand on (%d found)" % bodies)


## A section the campaign index does not know about is refused.
func _test_a_section_that_is_not_in_the_index_is_refused(scene: Node) -> void:
	heading("a section that is not in the index is refused")
	var manager := scene.get_node_or_null(MANAGER_PATH)
	if manager == null:
		return
	manager.set("announce_problems", false)

	var loaded: bool = manager.call("load_section", "P9.99")
	ok(not loaded, "a section with no scene is not loaded")
	text(str(manager.get("current_section_id")), EXAMPLE_ID,
		"the running section is left alone when a load fails")

	var trigger := _make_a_trigger("P9.99", "P9.99.start", "P9.99.end", "P9.99.split")
	var registered: bool = manager.call("register_section", trigger.get_child(0))
	ok(not registered, "a trigger the index does not know about is refused")
	trigger.free()
	manager.set("announce_problems", true)


## A trigger whose markers point at nothing is refused.
##
## A section that loads but cannot be finished is the failure this catches.
func _test_a_trigger_that_points_at_nothing_is_refused(scene: Node) -> void:
	heading("a trigger that points at nothing is refused")
	var manager := scene.get_node_or_null(MANAGER_PATH)
	if manager == null:
		return
	manager.set("announce_problems", false)

	var broken := _make_a_trigger(EXAMPLE_ID, "nothing.here", "%s.end" % EXAMPLE_ID,
		"%s.split" % EXAMPLE_ID)
	var registered: bool = manager.call("register_section", broken.get_child(0))
	ok(not registered, "a start checkpoint that points at nothing is refused")
	broken.free()

	var no_split := _make_a_trigger(EXAMPLE_ID, "%s.start" % EXAMPLE_ID,
		"%s.end" % EXAMPLE_ID, "nothing.here")
	var split_registered: bool = manager.call("register_section", no_split.get_child(0))
	ok(not split_registered, "a split marker that points at nothing is refused")
	no_split.free()
	manager.set("announce_problems", true)


## The playground drops the player at the start checkpoint of the section.
func _test_the_playground_puts_the_player_at_the_start(scene: Node) -> void:
	heading("the playground plays the section")
	var manager := scene.get_node_or_null(MANAGER_PATH)
	if manager == null:
		return

	var playground := PlaygroundScene.instantiate()
	scene.add_child(playground)

	var player := playground.get_node_or_null("Player")
	ok(player != null, "the playground has a player")
	if player != null:
		var checkpoint: Vector3 = manager.call("checkpoint_position", "%s.start" % EXAMPLE_ID)
		var expected := checkpoint + Vector3(0.0, 0.9, 0.0)
		ok(player.global_position.distance_to(expected) < 0.01,
			"the player starts at the start checkpoint")

	var hud := playground.get_node_or_null("HUD/Label")
	ok(hud != null, "the playground has a readout")
	if hud != null:
		ok(str(hud.get("text")).contains(EXAMPLE_ID),
			"the readout says which section is running")

	playground.free()
	manager.call("unload_section")
	text(str(manager.get("current_section_id")), "",
		"putting the section away clears the record")


## Makes a trigger that is not in the tree, so it does not register itself.
func _make_a_trigger(section_id: String, start_id: String, end_id: String,
		split_id: String) -> Node3D:
	var root := Node3D.new()
	var trigger := KitPoint.new()
	trigger.name = "SectionTrigger"
	trigger.kind = KitPoint.Kind.SECTION_TRIGGER
	trigger.point_id = "%s.trigger" % section_id
	trigger.section_id = section_id
	trigger.start_checkpoint_id = start_id
	trigger.end_checkpoint_id = end_id
	trigger.split_marker_id = split_id
	root.add_child(trigger)
	return root


## Finds a point of a kind in a section.
func _find_point(root: Node, kind: int) -> Node:
	for child in root.get_children():
		if child is KitPoint and int(child.get("kind")) == kind:
			return child
		var found := _find_point(child, kind)
		if found != null:
			return found
	return null


## Counts the static bodies under a node, internal children included.
func _count_bodies(node: Node) -> int:
	var count := 0
	for child in node.get_children(true):
		if child is StaticBody3D:
			count += 1
		count += _count_bodies(child)
	return count
