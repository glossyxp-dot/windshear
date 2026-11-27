# WindShear — the playable loop
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
## The loop is the promise the whole project makes: the designer lays a
## section out in the editor, and the game plays it, says what the objective
## is, opens the gates when the schedule says they open, and moves on to the
## next section.
##
## These checks are that promise, written down.
extends "res://tests/ws_test.gd"

## The gate schedule.
const Schedule := preload("res://addons/windshear/world/ws_schedule.gd")
## The gates of a running section.
const GateService := preload("res://addons/windshear/world/ws_gate_service.gd")
## The designer-authored point.
const KitPoint := preload("res://world/kit/ws_kit_point.gd")
## The screen a run is played on.
const RunScene := preload("res://world/run/run_screen.tscn")
## The objective HUD.
const HudScene := preload("res://ui/hud/section_hud.tscn")

## The section the example data describes.
const EXAMPLE_ID := "P1.01"
## Where the section manager lives.
const MANAGER_PATH := "/root/WsSections"


func suite_name() -> String:
	return "the game can be played"


func run_with_scene(scene: Node) -> void:
	_test_the_schedule_is_there()
	_test_the_gates_obey_the_schedule()
	_test_the_campaign_has_an_order(scene)
	_test_a_gate_gets_a_body(scene)
	_test_the_hud_says_the_objective(scene)
	_test_the_run_screen_plays_a_section(scene)
	_test_the_run_screen_finishes_a_section(scene)


## The schedule is in the repository and it covers the campaign.
func _test_the_schedule_is_there() -> void:
	heading("the schedule is there")
	var schedule := Schedule.read()
	ok(not schedule.is_empty(), "the gate schedule reads")
	ok(schedule.get("chapters", []).size() == 25, "the schedule has twenty-five chapters")

	var entries := Schedule.index(schedule)
	ok(entries.has("%s.gate_01" % EXAMPLE_ID), "the schedule knows the gate of the example")
	ok(entries.has("P3.01.gate_01"), "the schedule knows the gates of chapter three")


## A gate is open when the schedule says it is, and closed when it does not.
func _test_the_gates_obey_the_schedule() -> void:
	heading("the gates obey the schedule")
	var schedule := Schedule.read()
	var entries := Schedule.index(schedule)

	var open_gate: Dictionary = entries.get("%s.gate_01" % EXAMPLE_ID, {})
	ok(not open_gate.is_empty(), "the example gate is in the schedule")
	text(Schedule.state_at(open_gate, 0), "open", "the example gate is open at the start")
	text(Schedule.state_at(open_gate, 1200), "open", "the example gate is still open later")

	# A cycling gate: a hundred and twenty frames open, then closed, with
	# the cycle a third of a minute long and the phase forty frames in.
	var cycling: Dictionary = entries.get("P3.01.gate_01", {})
	ok(not cycling.is_empty(), "a cycling gate is in the schedule")
	text(Schedule.state_at(cycling, 0), "open", "the cycling gate is open at the start")
	text(Schedule.state_at(cycling, 80), "closed", "the cycling gate is closed in its closed window")
	text(Schedule.state_at(cycling, 200), "closed", "the cycling gate is still closed")
	text(Schedule.state_at(cycling, 320), "open", "the cycling gate opens again on the next cycle")

	text(Schedule.state_at({}, 0), "closed", "a gate the schedule does not know is closed")
	text(Schedule.state_at({"windows": []}, 0), "closed",
		"a gate with no windows is closed")


## The campaign has an order, and the run can walk it.
func _test_the_campaign_has_an_order(scene: Node) -> void:
	heading("the campaign has an order")
	var manager := _manager(scene)
	if manager == null:
		return

	var ids: PackedStringArray = manager.call("section_ids")
	same(ids.size(), 300, "the campaign index has three hundred sections")
	text(str(manager.call("next_section_id", EXAMPLE_ID)), "P1.02",
		"P1.02 comes after P1.01")
	text(str(manager.call("next_section_id", "20.12")), "",
		"there is nothing after the last section")

	var entry: Dictionary = manager.call("section_entry", EXAMPLE_ID)
	text(str(entry.get("display_name", "")), "Platform Nine",
		"the manager knows the name of the example section")

	var next_authored := str(manager.call("next_authored_section_id", EXAMPLE_ID))
	if next_authored.is_empty():
		ok(true, "there is no other section written yet")
	else:
		var path := str(manager.call("scene_path_for", next_authored))
		ok(ResourceLoader.exists(path), "the next written section has a scene")


## A gate in a section gets a body to stand in the way with.
func _test_a_gate_gets_a_body(scene: Node) -> void:
	heading("a gate gets a body")
	var point := KitPoint.new()
	point.kind = KitPoint.Kind.REGULATION_GATE
	point.point_id = "T1.01.gate_01"
	point.section_id = "T1.01"
	point.gate_width = 5.0
	point.gate_height = 2.5

	var root := Node3D.new()
	root.add_child(point)
	scene.add_child(root)

	var service := GateService.new()
	service.configure(root, _fake_schedule())
	same(service.count(), 1, "the service found the gate")
	text(service.gate_ids()[0], "T1.01.gate_01", "the gate carries its own id")

	var body := _first_body(point)
	ok(body != null, "the gate grew a body")
	var mesh := _first_mesh(point)
	ok(mesh != null, "the gate grew a barrier")

	if body != null:
		same(int(body.get("collision_layer")), 0,
			"the gate starts out of the way")
		service.update(10)
		same(int(body.get("collision_layer")), 0,
			"an open gate does not stop the player")
		service.update(60)
		same(int(body.get("collision_layer")), 1,
			"a closed gate stops the player")
		service.update(70)
		same(int(body.get("collision_layer")), 1,
			"the gate stays closed while its window says so")

	if mesh != null:
		service.update(10)
		ok(not bool(mesh.get("visible")), "an open gate has no barrier to see")
		service.update(60)
		ok(bool(mesh.get("visible")), "a closed gate shows its barrier")

	root.free()


## The HUD says what the player has to do.
func _test_the_hud_says_the_objective(scene: Node) -> void:
	heading("the hud says the objective")
	var hud := HudScene.instantiate()
	scene.add_child(hud)

	hud.call("set_section", "P1.01", "Platform Nine", "reach the far gate")
	var section_label := hud.get_node_or_null("Section")
	var objective_label := hud.get_node_or_null("Objective")
	ok(section_label != null, "the hud has a section line")
	ok(objective_label != null, "the hud has an objective line")
	if section_label != null:
		ok(str(section_label.get("text")).contains("P1.01"),
			"the hud says which section is running")
		ok(str(section_label.get("text")).contains("PLATFORM NINE"),
			"the hud says the name of the section")
	if objective_label != null:
		text(str(objective_label.get("text")), "REACH THE FAR GATE",
			"the hud says what the designer wrote")

	hud.call("set_objective", "")
	if objective_label != null:
		text(str(objective_label.get("text")), "REACH THE EXIT",
			"a section with no objective asks for the exit")

	hud.call("set_time", 62.5)
	var timer := hud.get_node_or_null("Timer")
	if timer != null:
		text(str(timer.get("text")), "1:02.50", "the hud counts the section time")

	hud.free()


## The run screen plays the section the designer made.
func _test_the_run_screen_plays_a_section(scene: Node) -> void:
	heading("the run screen plays a section")
	var manager := _manager(scene)
	if manager == null:
		return

	var run := RunScene.instantiate()
	run.set("leave_when_the_campaign_ends", false)
	scene.add_child(run)

	text(str(manager.get("current_section_id")), EXAMPLE_ID,
		"the run screen loaded the section")

	var player := run.get_node_or_null("Player")
	ok(player != null, "the run screen has a player")
	if player != null:
		var checkpoint: Vector3 = manager.call("checkpoint_position", "%s.start" % EXAMPLE_ID)
		var expected := checkpoint + Vector3(0.0, 0.9, 0.0)
		ok(player.global_position.distance_to(expected) < 0.01,
			"the player starts at the start checkpoint")

	var hud := run.get_node_or_null("HUD/SectionHUD")
	ok(hud != null, "the run screen has the objective hud")
	if hud != null:
		var section_label := hud.get_node_or_null("Section")
		if section_label != null:
			ok(str(section_label.get("text")).contains(EXAMPLE_ID),
				"the hud says which section is running")

	run.queue_free()
	manager.call("unload_section")


## Getting to the end of the section finishes it.
func _test_the_run_screen_finishes_a_section(scene: Node) -> void:
	heading("the run screen finishes a section")
	var manager := _manager(scene)
	if manager == null:
		return

	var run := RunScene.instantiate()
	run.set("leave_when_the_campaign_ends", false)
	scene.add_child(run)

	var player := run.get_node_or_null("Player")
	if player == null:
		run.queue_free()
		return

	# Put the player on the end checkpoint. The checkpoint says where the
	# feet go, so the body is half its height above it.
	var end_checkpoint: Vector3 = manager.call("checkpoint_position", "%s.end" % EXAMPLE_ID)
	player.global_position = end_checkpoint + Vector3(0.0, 0.9, 0.0)

	await scene.get_tree().physics_frame
	await scene.get_tree().physics_frame

	var banner := run.get_node_or_null("HUD/SectionHUD/Banner")
	ok(banner != null, "the run screen has a banner")
	if banner != null:
		text(str(banner.get("text")), "SECTION CLEAR",
			"reaching the end checkpoint clears the section")

	# The next section is whatever the designer has made. Only the example
	# exists at the moment, so the campaign ends here.
	run.call("_advance")
	var after := run.get_node_or_null("HUD/SectionHUD/Banner")
	var manager_id := str(manager.get("current_section_id"))
	if manager_id == EXAMPLE_ID:
		ok(str(after.get("text")).contains("COMPLETE"),
			"the campaign ends when there is no next section")
	else:
		ok(manager_id != EXAMPLE_ID, "the run moves on to the next written section")

	run.call("_leave_after_the_campaign")
	ok(WsGame.run_complete, "the game remembers the run was finished")
	same(int(WsGame.mode), int(WsGame.Mode.MENU), "the game goes back to the menu")

	run.queue_free()
	manager.call("unload_section")
	WsGame.run_complete = false


## The section manager.
func _manager(scene: Node) -> Node:
	return scene.get_node_or_null(MANAGER_PATH)


## A schedule with one gate, for the test to play with.
func _fake_schedule() -> Dictionary:
	return {
		"chapters": [{
			"chapter": "T1",
			"sections": [{
				"section_id": "T1.01",
				"gates": [{
					"gate_id": "T1.01.gate_01",
					"state": "cycling",
					"cycle_period_frames": 100,
					"phase_offset_frames": 0,
					"windows": [
						{"start_frame": 0, "end_frame": 50, "state": "open"},
						{"start_frame": 50, "end_frame": 100, "state": "closed"},
					],
				}],
			}],
		}],
	}


## The first static body under a node, internal children included.
func _first_body(node: Node) -> Node:
	for child in node.get_children(true):
		if child is StaticBody3D:
			return child
	return null


## The first mesh under a node, internal children included.
func _first_mesh(node: Node) -> Node:
	for child in node.get_children(true):
		if child is MeshInstance3D:
			return child
	return null
