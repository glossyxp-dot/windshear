# WindShear — headless test runner
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
## Runs every suite and exits with a non-zero status if anything failed.
##
## [codeblock]
## godot --headless --path . res://tests/run_all.tscn
## [/codeblock]
##
## The suites are deliberately about the things that break an FPS game:
## frame-exact movement, camera behaviour, determinism, the performance
## budget and the code policy. A generic "does the node exist" test suite
## would not catch a one-frame coyote time bug, and that is the bug that
## actually ruins a speedrun.
##
## The runner is a scene and not a `--script` main loop on purpose. A
## script main loop does not register the autoload singletons as global
## identifiers, so a suite that touches the menu (and the menu touches
## `WsGame`) would not even compile. A scene runs the game the way the
## game runs, which is the only way a test proves anything about the game.
extends Node

## The base test class.
const TestCase := preload("res://tests/ws_test.gd")
## The movement greybox, used by the scene test.
const GreyboxScene := preload("res://world/greybox/movement_greybox.tscn")

## The suites, in the order they run.
const SUITES := [
	preload("res://tests/test_tuning.gd"),
	preload("res://tests/test_movement.gd"),
	preload("res://tests/test_movement_characterization.gd"),
	preload("res://tests/test_movement_discovery.gd"),
	preload("res://tests/test_camera.gd"),
	preload("res://tests/test_input_map.gd"),
	preload("res://tests/test_determinism.gd"),
	preload("res://tests/test_speed_meter.gd"),
	preload("res://tests/test_perf_budget.gd"),
	preload("res://tests/test_code_policy.gd"),
	preload("res://tests/test_world_data.gd"),
	preload("res://tests/test_canon.gd"),
]

## Suites that need a live scene tree.
const SCENE_SUITES := [
	preload("res://tests/test_greybox.gd"),
	preload("res://tests/test_psx.gd"),
]


func _ready() -> void:
	_run()


func _run() -> void:
	print("")
	print("=== WindShear test suite ===")
	var total_checks := 0
	var total_failures := 0
	var failed_names: PackedStringArray = []

	for suite_script in SUITES:
		var suite: TestCase = suite_script.new()
		print("[ RUN      ] " + suite.suite_name())
		suite.run()
		total_checks += suite.checks
		total_failures += suite.failures.size()
		if suite.failures.size() > 0:
			failed_names.append(suite.suite_name())
			for failure in suite.failures:
				print("[   FAIL   ] " + failure)
		print("[       OK  ] %d checks, %d failures" % [suite.checks, suite.failures.size()])

	# The scene suites need a real scene tree, so they run after the plain
	# ones with the greybox instantiated for them.
	var scene := GreyboxScene.instantiate()
	add_child(scene)
	for _frame in 12:
		await get_tree().physics_frame

	for suite_script in SCENE_SUITES:
		var suite: TestCase = suite_script.new()
		print("[ RUN      ] " + suite.suite_name())
		suite.run_with_scene(scene)
		total_checks += suite.checks
		total_failures += suite.failures.size()
		if suite.failures.size() > 0:
			failed_names.append(suite.suite_name())
			for failure in suite.failures:
				print("[   FAIL   ] " + failure)
		print("[       OK  ] %d checks, %d failures" % [suite.checks, suite.failures.size()])

	scene.free()
	await get_tree().process_frame

	print("")
	if total_failures == 0:
		print("=== %d checks passed ===" % total_checks)
		get_tree().quit(0)
		return

	print("=== %d checks, %d FAILURES ===" % [total_checks, total_failures])
	for name in failed_names:
		print("    failed suite: " + name)
	get_tree().quit(1)
