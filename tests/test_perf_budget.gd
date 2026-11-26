# WindShear — performance budget tests
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
## The budgets from `TECH_SPEC.md` §9 and §12, checked against the project
## settings and the real cost of a frame of movement.
##
## A speed game that drops frames is a speed game nobody can speedrun. The
## frame budget is a correctness requirement, not an optimisation goal.
extends "res://tests/ws_test.gd"

## The player controller.
const Controller := preload("res://addons/windshear/movement/lancer_controller.gd")
## The per-frame input record.
const InputState := preload("res://addons/windshear/movement/lancer_input.gd")

## One physics frame.
const DT := 1.0 / 60.0
## The frame budget at 60 fps, in milliseconds.
const FRAME_BUDGET_MS := 16.6
## How much of the frame budget the movement simulation may use.
const MOVEMENT_BUDGET_MS := 0.5


func suite_name() -> String:
	return "the performance budget holds"


func run() -> void:
	_test_project_settings()
	_test_simulation_cost()


func _test_project_settings() -> void:
	heading("the project settings")
	var ticks := int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 0))
	same(ticks, 60, "the physics tick is 60 Hz")

	var steps := int(ProjectSettings.get_setting("physics/common/max_physics_steps_per_frame", 0))
	same(steps, 4, "at most 4 physics steps per frame")

	var width := int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
	same(width, 480, "the internal width is 480")
	var height := int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	same(height, 270, "the internal height is 270")

	var method := String(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	text(method, "gl_compatibility", "the Compatibility renderer is used")

	var filter := int(ProjectSettings.get_setting(
		"rendering/textures/canvas_textures/default_texture_filter", -1))
	same(filter, 0, "the default texture filter is nearest neighbour")

	var features: PackedStringArray = ProjectSettings.get_setting(
		"application/config/features", PackedStringArray())
	ok(features.has("4.7"), "the project records the engine version")

	var engine := String(ProjectSettings.get_setting("physics/3d/physics_engine", ""))
	text(engine, "Jolt Physics", "the Jolt physics engine is used")


func _test_simulation_cost() -> void:
	heading("the cost of a frame")
	var controller := Controller.new()
	var input := InputState.new()
	input.on_floor = true
	input.move = Vector2(1.0, 0.0)

	# Warm up first so the measured call does not pay for lazy initialisation.
	for _frame in 120:
		controller.simulate(DT, input)

	var frames := 5400
	var started := Time.get_ticks_usec()
	for frame in range(frames):
		input.jump_pressed = (frame % 97) == 60
		input.slip_pressed = (frame % 97) == 20
		controller.simulate(DT, input)
	var elapsed := Time.get_ticks_usec() - started

	var per_frame_ms := float(elapsed) / float(frames) / 1000.0
	ok(per_frame_ms < MOVEMENT_BUDGET_MS,
		"a frame of movement costs %.4f ms, the budget is %.2f ms" % [per_frame_ms, MOVEMENT_BUDGET_MS])
	ok(per_frame_ms < FRAME_BUDGET_MS * 0.25,
		"the movement simulation leaves most of the frame for rendering")
	controller.free()
