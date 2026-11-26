# WindShear — the movement workbench has to work
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
## The workbench is how the movement gets tuned without editing code, so it
## has to actually work.
##
## Three things can go wrong with a tuning panel and all three are quiet. The
## panel can show a number the controller is not using. The panel can show a
## default that has drifted away from the constant it claims to come from. And
## the panel can write over the owner's real saved profile while the test
## suite runs. This suite is the alarm for all three.
extends "res://tests/ws_test.gd"

## The workbench scene.
const WorkbenchScene := preload("res://tools/movement_workbench.tscn")
## The live override store and the table of knobs.
const Tweak := preload("res://addons/windshear/core/ws_tweak.gd")
## The canonical tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")
## The movement input record.
const InputState := preload("res://addons/windshear/movement/lancer_input.gd")

## One frame.
const DT := 1.0 / 60.0

## Where this suite writes its profile, so the real one survives.
const TEST_PROFILE := "user://workbench_suite_profile.json"


func suite_name() -> String:
	return "the workbench tunes the movement"


## The workbench is a scene, so it needs a tree to live in. The runner hands
## over the greybox and this suite hangs the workbench off it, then takes it
## down again.
func run_with_scene(scene: Node) -> void:
	_test_the_knobs_match_the_constants()
	_test_the_workbench_builds(scene)
	_test_a_knob_reaches_the_simulation(scene)
	_test_the_profile_round_trips()


## Every knob starts on the constant it claims to come from.
##
## The panel is built out of this table, so a default that drifts away from
## the code means the panel is lying about what the game does.
func _test_the_knobs_match_the_constants() -> void:
	heading("the knobs start on the constants")
	var tuning_script: Script = load("res://addons/windshear/core/ws_tuning.gd")
	var constants: Dictionary = tuning_script.get_script_constant_map()
	var wrong := PackedStringArray()
	for key in Tweak.TUNABLES.keys():
		var entry: Dictionary = Tweak.TUNABLES[key]
		var const_name := String(entry["const"])
		if not constants.has(const_name):
			wrong.append("%s has no constant called %s" % [key, const_name])
			continue
		if absf(float(constants[const_name]) - float(entry["default"])) > 0.000001:
			wrong.append("%s says %.6f and the constant says %.6f" % [
				key, float(entry["default"]), float(constants[const_name])
			])
	ok(wrong.is_empty(), "every knob starts on its constant (%s)" % ", ".join(wrong))
	ok(Tweak.TUNABLES.size() >= 20,
		"the workbench has a knob for every movement number")


## The workbench opens, builds its panel and wires the room up.
func _test_the_workbench_builds(scene: Node) -> void:
	heading("the workbench opens")
	var workbench := _open_the_workbench(scene)
	if workbench == null:
		ok(false, "the workbench scene loads")
		return
	ok(true, "the workbench scene loads")

	var panel := workbench.find_child("WorkbenchPanel", true, false)
	ok(panel != null, "the workbench builds its panel")

	var player := workbench.get_node_or_null("Room/Player")
	ok(player != null, "the workbench brings the room with it")
	if player != null:
		ok(player.get("overrides") == WsTweak.overrides,
			"the room and the panel share one set of overrides")
	_close_the_workbench(workbench)


## A knob that moves has to reach the simulation on the next frame.
func _test_a_knob_reaches_the_simulation(scene: Node) -> void:
	heading("a knob reaches the simulation")
	var workbench := _open_the_workbench(scene)
	if workbench == null:
		ok(false, "the workbench opens for the live test")
		return
	var player := workbench.get_node_or_null("Room/Player")
	if player == null:
		ok(false, "the workbench has a player for the live test")
		_close_the_workbench(workbench)
		return

	WsTweak.set_override("max_run_speed", 20.0)
	var speed := _run_for_a_while(player, 120)
	near(speed, 20.0, 0.01, "the room runs at the number on the slider")

	WsTweak.clear_all()
	speed = _run_for_a_while(player, 120)
	near(speed, Tuning.MAX_RUN_SPEED, 0.01,
		"the room is back on the documented number")
	_close_the_workbench(workbench)


## The profile saves, loads and stays out of the repository.
func _test_the_profile_round_trips() -> void:
	heading("the profile round trips")
	var original := WsTweak.profile_file
	WsTweak.profile_file = TEST_PROFILE
	WsTweak.set_override("jump_velocity", 18.0)
	WsTweak.notes = "the suite was here"
	var saved := WsTweak.save_profile()
	ok(saved, "the profile saves")

	WsTweak.clear_all()
	WsTweak.notes = ""
	var loaded := WsTweak.load_profile()
	ok(loaded, "the profile loads")
	near(WsTweak.value("jump_velocity"), 18.0, 0.0001,
		"the loaded profile still holds the number")
	text(WsTweak.notes, "the suite was here", "the loaded profile still holds the notes")

	ok(not WsTweak.profile_path().begins_with(ProjectSettings.globalize_path("res://")),
		"the profile lives outside the repository")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PROFILE))
	WsTweak.profile_file = original
	WsTweak.clear_all()
	WsTweak.notes = ""


## Opens the workbench in the live tree and hands it back.
func _open_the_workbench(parent: Node) -> Node:
	var workbench: Node = WorkbenchScene.instantiate()
	workbench.set("adjust_window", false)
	parent.add_child(workbench)
	return workbench


## Closes the workbench again. A suite that leaves nodes behind leaks them
## into the report at the end of the run.
func _close_the_workbench(workbench: Node) -> void:
	if workbench == null:
		return
	workbench.get_parent().remove_child(workbench)
	workbench.free()


## Drives the controller for a number of frames and returns the speed.
func _run_for_a_while(player: Node, frames: int) -> float:
	var input := InputState.new()
	input.on_floor = true
	input.move = Vector2(0.0, 1.0)
	for _frame in frames:
		player.call("simulate", DT, input)
	var velocity: Vector3 = player.get("velocity")
	return Vector2(velocity.x, velocity.z).length()
