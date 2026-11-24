# WindShear — determinism tests
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
## Replays, ghosts and personal bests only work if the simulation is
## deterministic. These tests run the same input twice and demand identical
## results. They also check that a section seed produces the same sequence
## every time.
extends "res://tests/ws_test.gd"

## The player controller.
const Controller := preload("res://addons/windshear/movement/lancer_controller.gd")
## The per-frame input record.
const InputState := preload("res://addons/windshear/movement/lancer_input.gd")
## The game state script (the autoload singleton).
const GameScript := preload("res://addons/windshear/core/ws_game.gd")

## One physics frame.
const DT := 1.0 / 60.0


func suite_name() -> String:
	return "the simulation is deterministic"


func run() -> void:
	_test_same_inputs_same_result()
	_test_seeded_generator()
	_test_section_seeds()


## Replays a scripted input sequence and returns the trace of velocities.
func _replay(frames: int) -> Array:
	var controller := Controller.new()
	var input := InputState.new()
	var trace := PackedFloat32Array()
	for frame in range(frames):
		# A route with everything in it: running, a jump, a slide and air time.
		input.on_floor = (frame % 97) < 61
		input.move_axis = 1.0 if (frame % 31) < 24 else -1.0
		input.jump_pressed = (frame % 97) == 60
		input.jump_released = (frame % 97) == 66
		input.slip_pressed = (frame % 97) == 20
		input.wall_contact = (frame % 97) >= 20 and (frame % 97) <= 24
		input.wall_normal = Vector3(0.0, 0.0, 1.0)
		controller.simulate(DT, input)
		trace.append(controller.velocity.x)
		trace.append(controller.velocity.y)
	controller.free()
	return trace

func _test_same_inputs_same_result() -> void:
	heading("the same input gives the same result")
	var first := _replay(600)
	var second := _replay(600)
	same(first.size(), second.size(), "both replays have the same length")
	var identical := true
	for index in range(first.size()):
		if first[index] != second[index]:
			identical = false
			break
	ok(identical, "600 frames of movement replay byte for byte")


func _test_seeded_generator() -> void:
	heading("the section-seeded generator")
	var game: Object = GameScript.new()
	var first: Object = game.rng_for_section("1.07")
	var second: Object = game.rng_for_section("1.07")
	var identical := true
	for _draw in range(16):
		if first.randf() != second.randf():
			identical = false
			break
	ok(identical, "the same section always produces the same sequence")

	var other: Object = game.rng_for_section("1.08")
	var differs := false
	first.seed = game.section_seed("1.07")
	other.seed = game.section_seed("1.08")
	for _draw in range(16):
		if first.randf() != other.randf():
			differs = true
			break
	ok(differs, "two different sections produce different sequences")
	game.free()


func _test_section_seeds() -> void:
	heading("section seeds")
	var game: Object = GameScript.new()
	same(game.section_seed("1.01"), game.section_seed("1.01"), "a seed is stable")
	ok(game.section_seed("1.01") != game.section_seed("1.02"), "sections do not share a seed")
	ok(game.section_seed("") != game.section_seed("1.01"), "an empty id is not a valid section")
	ok(game.section_seed("6.12") >= 0, "the seed is a positive integer")
	game.free()
