# WindShear — frame-exact movement tests
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
## These are the tests that matter for a speed game. They count frames.
##
## A controller that is one frame late with the coyote window, one frame early
## with the jump buffer, or a fraction off on acceleration feels wrong to a
## player and shatters every recorded route. The numbers come straight from
## `TECH_SPEC.md` §3. Speed is always in metres per second.
extends "res://tests/ws_test.gd"

## The player controller.
const Controller := preload("res://addons/windshear/movement/lancer_controller.gd")
## The per-frame input record.
const InputState := preload("res://addons/windshear/movement/lancer_input.gd")
## Movement tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")

## One physics frame.
const DT := 1.0 / 60.0


func suite_name() -> String:
	return "movement is frame-exact"


func run() -> void:
	_test_top_speed()
	_test_acceleration_rates()
	_test_turnaround_keeps_acceleration()
	_test_jump_velocity()
	_test_variable_jump_height()
	_test_coyote_time()
	_test_jump_buffer()
	_test_air_acceleration_cap()
	_test_slide()
	_test_slide_cancels_into_jump()
	_test_wall_kiss()
	_test_wall_kiss_cap()
	_test_wall_kiss_fracture()
	_test_wall_kiss_speed_ceiling()
	_test_camera_relative_movement()


## Brings a controller up to the top speed and returns it with its input.
func _at_top_speed() -> Array:
	var controller := Controller.new()
	var input := InputState.new()
	input.on_floor = true
	input.move = Vector2(1.0, 0.0)
	for _frame in 120:
		controller.simulate(DT, input)
	return [controller, input]

func _test_top_speed() -> void:
	heading("top speed")
	var pair := _at_top_speed()
	var controller: Object = pair[0]
	near(controller.velocity.x, Tuning.MAX_RUN_SPEED, 0.0001, "the top speed is 14 m/s")

	# It never runs past the cap.
	var input: Object = pair[1]
	for _frame in 120:
		controller.simulate(DT, input)
	near(controller.velocity.x, Tuning.MAX_RUN_SPEED, 0.0001, "the top speed is a hard cap")
	pair[0].free()

func _test_acceleration_rates() -> void:
	heading("acceleration and deceleration")
	var controller := Controller.new()
	var input := InputState.new()
	input.on_floor = true
	input.move = Vector2(1.0, 0.0)
	controller.simulate(DT, input)
	near(controller.velocity.x, Tuning.GROUND_ACCEL * DT, 0.0001,
		"the first frame accelerates at 90 m/s^2")

	for _frame in 120:
		controller.simulate(DT, input)
	input.move = Vector2(0.0, 0.0)
	controller.simulate(DT, input)
	near(controller.velocity.x, Tuning.MAX_RUN_SPEED - Tuning.GROUND_DECEL * DT, 0.0001,
		"releasing the stick decelerates at 60 m/s^2")
	controller.free()

func _test_turnaround_keeps_acceleration() -> void:
	heading("turnaround")
	var pair := _at_top_speed()
	var controller: Object = pair[0]
	var input: Object = pair[1]
	input.move = Vector2(-1.0, 0.0)
	controller.simulate(DT, input)
	near(controller.velocity.x, Tuning.MAX_RUN_SPEED - Tuning.GROUND_ACCEL * DT, 0.0001,
		"a turnaround uses the acceleration rate, not the deceleration rate")
	pair[0].free()

func _test_jump_velocity() -> void:
	heading("jump")
	var controller := Controller.new()
	var input := InputState.new()
	input.on_floor = true
	input.jump_pressed = true
	controller.simulate(DT, input)
	near(controller.velocity.y, Tuning.JUMP_VELOCITY, 0.0001, "the jump velocity is 15.5 m/s")
	same(controller.jump_buffer_frames, 0, "the jump buffer is consumed by the jump")
	controller.free()

func _test_variable_jump_height() -> void:
	heading("variable jump height")
	var controller := Controller.new()
	var input := InputState.new()
	input.on_floor = true
	input.jump_pressed = true
	controller.simulate(DT, input)
	near(controller.velocity.y, Tuning.JUMP_VELOCITY, 0.0001, "the jump starts at full speed")

	input.on_floor = false
	input.jump_pressed = false
	input.jump_released = true
	controller.simulate(DT, input)
	var expected := Tuning.JUMP_VELOCITY * Tuning.JUMP_CUT - Tuning.GRAVITY * DT
	near(controller.velocity.y, expected, 0.0001, "releasing early cuts the jump short")
	ok(controller.velocity.y < Tuning.JUMP_VELOCITY * 0.6, "a cut jump is much lower than a full one")
	controller.free()

func _test_coyote_time() -> void:
	heading("coyote time")
	var controller := Controller.new()
	var input := InputState.new()
	input.on_floor = true
	controller.simulate(DT, input)
	input.on_floor = false

	# A jump on the eighth frame after leaving the ground still works.
	for frame in range(8):
		input.jump_pressed = frame == 7
		controller.simulate(DT, input)
	near(controller.velocity.y, Tuning.JUMP_VELOCITY - Tuning.GRAVITY * DT, 0.0001,
		"coyote time lasts 8 frames after leaving the ground")

	# A jump on the ninth frame does not.
	var late := Controller.new()
	var late_input := InputState.new()
	late_input.on_floor = true
	late.simulate(DT, late_input)
	late_input.on_floor = false
	for frame in range(9):
		late_input.jump_pressed = frame == 8
		late.simulate(DT, late_input)
	ok(late.velocity.y < 0.0, "coyote time has expired after 8 frames")
	same(late.coyote_frames, 0, "the coyote counter is empty")
	controller.free()
	late.free()

func _test_jump_buffer() -> void:
	heading("jump buffer")
	var controller := Controller.new()
	var input := InputState.new()
	input.on_floor = false
	input.jump_pressed = true
	controller.simulate(DT, input)
	input.jump_pressed = false
	for _frame in 4:
		controller.simulate(DT, input)
	input.on_floor = true
	controller.simulate(DT, input)
	near(controller.velocity.y, Tuning.JUMP_VELOCITY, 0.0001,
		"a jump pressed 5 frames early fires on the landing frame")

	# The buffer runs out after 10 frames.
	var stale := Controller.new()
	var stale_input := InputState.new()
	stale_input.on_floor = false
	stale_input.jump_pressed = true
	stale.simulate(DT, stale_input)
	stale_input.jump_pressed = false
	for _frame in 10:
		stale.simulate(DT, stale_input)
	stale_input.on_floor = true
	stale.simulate(DT, stale_input)
	ok(stale.velocity.y < Tuning.JUMP_VELOCITY,
		"a jump pressed 11 frames early is dropped")
	controller.free()
	stale.free()

func _test_air_acceleration_cap() -> void:
	heading("air acceleration")
	var controller := Controller.new()
	var input := InputState.new()
	input.on_floor = false
	input.move = Vector2(1.0, 0.0)
	for _frame in 300:
		controller.simulate(DT, input)
	near(controller.velocity.x, Tuning.AIR_ACCEL_MAX_CONTRIB, 0.001,
		"air acceleration contributes at most 2.2 m/s")
	near(controller.air_bonus, Tuning.AIR_ACCEL_MAX_CONTRIB, 0.001,
		"the air contribution counter stops at the cap")
	controller.free()

func _test_slide() -> void:
	heading("slide")
	var pair := _at_top_speed()
	var controller: Object = pair[0]
	var input: Object = pair[1]

	# A slide needs some speed in the first place.
	var slow := Controller.new()
	var slow_input := InputState.new()
	slow_input.on_floor = true
	slow_input.move = Vector2(1.0, 0.0)
	slow.simulate(DT, slow_input)
	slow_input.slip_pressed = true
	slow.simulate(DT, slow_input)
	same(slow.slide_frames, 0, "a slide does not start below the minimum speed")

	input.move = Vector2(0.0, 0.0)
	input.slip_pressed = true
	controller.simulate(DT, input)
	near(controller.velocity.x, Tuning.MAX_RUN_SPEED - Tuning.SLIDE_FRICTION * DT, 0.0001,
		"the slide friction is 6 m/s^2")
	ok(controller.sliding, "the slide is running")

	input.slip_pressed = false
	for _frame in 26:
		controller.simulate(DT, input)
	same(controller.slide_frames, 0, "the slide lasts 27 frames (0.45 s)")
	ok(not controller.sliding, "the slide has ended")
	near(controller.velocity.x, Tuning.MAX_RUN_SPEED - 27.0 * Tuning.SLIDE_FRICTION * DT, 0.001,
		"the slide removes 2.7 m/s in total")
	pair[0].free()
	slow.free()

func _test_slide_cancels_into_jump() -> void:
	heading("slide cancels into jump")
	var pair := _at_top_speed()
	var controller: Object = pair[0]
	var input: Object = pair[1]
	input.move = Vector2(0.0, 0.0)
	input.slip_pressed = true
	controller.simulate(DT, input)
	ok(controller.sliding, "the slide started")
	input.jump_pressed = true
	controller.simulate(DT, input)
	same(controller.slide_frames, 0, "the slide is cancelled by the jump")
	ok(not controller.sliding, "the slide is no longer running")
	near(controller.velocity.y, Tuning.JUMP_VELOCITY, 0.0001, "the jump still happened")
	pair[0].free()

func _test_wall_kiss() -> void:
	heading("wall-jump")
	var pair := _at_top_speed()
	var controller: Object = pair[0]
	var input: Object = pair[1]

	# any wall can arm a wall-jump now that the route has depth
	input.wall_contact = true
	input.wall_normal = Vector3(-1.0, 0.0, 0.0)
	input.slip_pressed = true
	controller.simulate(DT, input)
	ok(controller.wall_kiss_armed, "a wall straight ahead arms a wall-jump")

	# a wall alongside the route can too
	var side := _at_top_speed()
	var side_controller: Object = side[0]
	var side_input: Object = side[1]
	side_input.wall_contact = true
	side_input.wall_normal = Vector3(0.0, 0.0, 1.0)
	side_input.slip_pressed = true
	side_controller.simulate(DT, side_input)
	ok(side_controller.wall_kiss_armed, "a wall alongside the route arms a wall-jump")

	# jumping on the contact frame adds the boost
	var before: float = side_controller.velocity.x
	side_input.slip_pressed = false
	side_input.jump_pressed = true
	side_controller.simulate(DT, side_input)
	near(side_controller.velocity.x - before, Tuning.WALL_KISS_BOOST, 0.0001,
		"the wall-jump adds 0.8 m/s")
	near(side_controller.velocity.y, Tuning.JUMP_VELOCITY, 0.0001,
		"the wall-jump launches Lancer")
	same(side_controller.wall_kiss_count, 1, "the chain counter went up")
	pair[0].free()
	side[0].free()

func _test_wall_kiss_cap() -> void:
	heading("wall-jump chain cap")
	var pair := _at_top_speed()
	var controller: Object = pair[0]
	var input: Object = pair[1]
	input.wall_contact = true
	input.wall_normal = Vector3(0.0, 0.0, 1.0)

	for kiss in range(6):
		input.slip_pressed = true
		input.jump_pressed = false
		controller.simulate(DT, input)
		input.slip_pressed = false
		var before: float = controller.velocity.x
		input.jump_pressed = true
		controller.simulate(DT, input)
		input.jump_pressed = false
		if kiss < Tuning.WALL_KISS_CAP:
			near(controller.velocity.x - before, Tuning.WALL_KISS_BOOST, 0.0001,
				"Wall-jump %d adds the boost." % (kiss + 1))
		else:
			near(controller.velocity.x - before, 0.0, 0.0001,
				"Wall-jump %d adds nothing because the chain is capped at %d." % [
					kiss + 1, Tuning.WALL_KISS_CAP])

	same(controller.wall_kiss_count, Tuning.WALL_KISS_CAP,
		"the chain never goes past the cap")
	pair[0].free()


## The shipped [code]wall_kiss_chain[/code] Fracture takes the chain from three
## wall-jumps to five. The ceiling goes from 16.4 m/s to 18.0 m/s.
func _test_wall_kiss_fracture() -> void:
	heading("the wall-jump Fracture")
	var pair := _at_top_speed()
	var controller: Object = pair[0]
	var input: Object = pair[1]
	input.wall_contact = true
	input.wall_normal = Vector3(0.0, 0.0, 1.0)

	same(controller.wall_kiss_cap, Tuning.WALL_KISS_CAP,
		"the base chain is three wall-jumps")
	controller.enable_wall_kiss_chain_fracture()
	same(controller.wall_kiss_cap, Tuning.WALL_KISS_FRACTURE_CAP,
		"the Fracture takes the chain to five")
	near(controller.wall_kiss_speed_ceiling, Tuning.WALL_KISS_FRACTURE_SPEED_CEILING,
		0.0001, "the Fracture raises the speed ceiling")

	# A full Fracture chain from the run speed.
	for _kiss in range(Tuning.WALL_KISS_FRACTURE_CAP):
		input.slip_pressed = true
		input.jump_pressed = true
		controller.simulate(DT, input)
		input.slip_pressed = false
		input.jump_pressed = false
	same(controller.wall_kiss_count, Tuning.WALL_KISS_FRACTURE_CAP,
		"the Fracture chain reaches five")
	near(absf(controller.velocity.x), Tuning.WALL_KISS_FRACTURE_SPEED_CEILING, 0.0001,
		"the Fracture chain reaches 18.0 m/s")

	controller.disable_wall_kiss_chain_fracture()
	same(controller.wall_kiss_cap, Tuning.WALL_KISS_CAP,
		"turning the Fracture off puts the chain back to three")
	pair[0].free()


func _test_wall_kiss_speed_ceiling() -> void:
	heading("the wall-jump speed ceiling")
	var pair := _at_top_speed()
	var controller: Object = pair[0]
	var input: Object = pair[1]
	input.wall_contact = true
	input.wall_normal = Vector3(0.0, 0.0, 1.0)

	# Wall-jump over and over, with enough frames between the chains for the
	# counter to expire. The speed must still stop at the ceiling.
	for chain in range(6):
		for _frame in 40:
			input.move = Vector2(1.0, 0.0)
			controller.simulate(DT, input)
		input.slip_pressed = true
		controller.simulate(DT, input)
		input.slip_pressed = false
		input.jump_pressed = true
		controller.simulate(DT, input)
		input.jump_pressed = false
		input.on_floor = false
		for _frame in 32:
			controller.simulate(DT, input)
		input.on_floor = true

	ok(absf(controller.velocity.x) <= Tuning.WALL_KISS_SPEED_CEILING + 0.0001,
		"the speed never passes the wall-jump ceiling of %.1f m/s (%.2f)" % [
			Tuning.WALL_KISS_SPEED_CEILING, absf(controller.velocity.x)])
	pair[0].free()

func _test_camera_relative_movement() -> void:
	heading("camera-relative movement")
	var controller := Controller.new()
	var input := InputState.new()
	input.on_floor = true
	input.move = Vector2(0.0, 1.0)
	input.camera_yaw = 0.0
	for _frame in 60:
		controller.simulate(DT, input)
	near(controller.velocity.z, -Tuning.MAX_RUN_SPEED, 0.001,
		"w walks away from the camera")
	near(controller.velocity.x, 0.0, 0.001,
		"w does not drift sideways")
	controller.free()

	var turned := Controller.new()
	var turned_input := InputState.new()
	turned_input.on_floor = true
	turned_input.move = Vector2(0.0, 1.0)
	turned_input.camera_yaw = PI * 0.5
	for _frame in 60:
		turned.simulate(DT, turned_input)
	near(turned.velocity.x, -Tuning.MAX_RUN_SPEED, 0.001,
		"a quarter turn sends w along the new forward")
	turned.free()

	var strafe := Controller.new()
	var strafe_input := InputState.new()
	strafe_input.on_floor = true
	strafe_input.move = Vector2(1.0, 0.0)
	for _frame in 60:
		strafe.simulate(DT, strafe_input)
	near(strafe.velocity.x, Tuning.MAX_RUN_SPEED, 0.001,
		"d strafes across the camera")
	near(strafe.velocity.z, 0.0, 0.001,
		"a pure strafe does not drift forward")
	strafe.free()

	var diagonal := Controller.new()
	var diagonal_input := InputState.new()
	diagonal_input.on_floor = true
	diagonal_input.move = Vector2(1.0, 1.0)
	for _frame in 60:
		diagonal.simulate(DT, diagonal_input)
	near(Vector2(diagonal.velocity.x, diagonal.velocity.z).length(),
		Tuning.MAX_RUN_SPEED, 0.001,
		"a diagonal walks at the same top speed, not faster")
	diagonal.free()

	# Depth is real movement now, so it is not clamped away.
	var depth := Controller.new()
	var depth_input := InputState.new()
	depth_input.on_floor = true
	depth.velocity = Vector3(0.0, 0.0, 5.0)
	depth.simulate(DT, depth_input)
	ok(depth.velocity.z > 0.0, "depth is no longer forced to zero")
	depth.free()

	# A partly pushed stick walks slower, the same way the old axis did.
	var analog := Controller.new()
	var analog_input := InputState.new()
	analog_input.on_floor = true
	analog_input.move = Vector2(0.0, 0.5)
	for _frame in 120:
		analog.simulate(DT, analog_input)
	near(Vector2(analog.velocity.x, analog.velocity.z).length(),
		Tuning.MAX_RUN_SPEED * 0.5, 0.01,
		"a half-pushed stick walks at half speed")
	analog.free()
