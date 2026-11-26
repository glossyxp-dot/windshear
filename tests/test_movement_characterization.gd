# WindShear — movement characterization probes
# Copyright (C) 2026 the WindShear contributors
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <https://www.gnu.org/licenses/>.
##
## Probes for movement behavior that should be characterized, not designed.
##
## The named movement mechanics have their own exact tests in
## `test_movement.gd`. This suite covers the boundaries around them: the
## wall-jump timing window, wall contact classification, chain expiry, repeated
## cycles, collision projection, the air budget's direction semantics, and
## deterministic adversarial input sequences.
##
## The base wall-jump chain stops at three. Its horizontal ceiling is
## 16.4 m/s: 14.0 m/s plus three boosts of 0.8 m/s. The shipped
## [code]wall_kiss_chain[/code] Fracture raises the cap to five and the
## ceiling to 18.0 m/s.
##
## A probe that crosses a hard bound fails the build. A probe that changes
## without crossing a bound asks for review. It does not make the result a
## hidden mechanic.
extends "res://tests/ws_test.gd"

## The player controller.
const Controller := preload("res://addons/windshear/movement/lancer_controller.gd")
## The per-frame input record.
const InputState := preload("res://addons/windshear/movement/lancer_input.gd")
## Movement tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")

## One physics frame.
const DT := 1.0 / 60.0
## The base wall-jump ceiling: 14.0 m/s plus three boosts of 0.8 m/s.
const DESIGNED_SPEED_CEILING := 16.4
## The wider envelope that keeps unexpected speed visible.
const DISCOVERY_SPEED_ENVELOPE := 20.2
## Legal horizontal input choices for the deterministic adversarial probe.
const INPUT_AXES := [-1.0, 0.0, 1.0]


func suite_name() -> String:
	return "movement accidents stay characterized"


func run() -> void:
	_test_wall_kiss_arming_boundary()
	_test_any_wall_normal()
	_test_chain_expiry_boundary()
	_test_repeated_landing_slide_cycles()
	_test_repeated_wall_kiss_cycles()
	_test_collision_normal_sweep()
	_test_air_budget_direction_audit()
	_test_air_budget_landing_reset()
	_test_adversarial_input_fuzz()
	_test_full_state_replay_hash()


## Brings a controller up to the top speed and returns it with its input.
func _at_top_speed() -> Array:
	var controller := Controller.new()
	var input := InputState.new()
	input.on_floor = true
	input.move = Vector2(1.0, 0.0)
	for _frame in 120:
		controller.simulate(DT, input)
	return [controller, input]


## Contacts a wall on a selected frame after the slide starts.
##
## [param contact_frame] is zero-based: zero is the slide-start frame, one
## is the next frame, and so on. [param jump_on_contact] decides whether the
## jump is pressed on that contact frame.
func _wall_kiss_contact_result(contact_frame: int, jump_on_contact: bool) -> Dictionary:
	var pair := _at_top_speed()
	var controller: Object = pair[0]
	var input: Object = pair[1]

	input.wall_contact = contact_frame == 0
	input.wall_normal = Vector3(0.0, 0.0, 1.0)
	input.slip_pressed = true
	input.jump_pressed = jump_on_contact and contact_frame == 0
	var speed_before: float = controller.velocity.x
	controller.simulate(DT, input)
	input.slip_pressed = false
	input.jump_pressed = false

	if contact_frame > 0:
		for frame in range(1, contact_frame + 1):
			input.wall_contact = frame == contact_frame
			if frame == contact_frame:
				input.jump_pressed = jump_on_contact
				speed_before = controller.velocity.x
			controller.simulate(DT, input)
			input.jump_pressed = false

	var result := {
		"armed": controller.wall_kiss_armed,
		"count": controller.wall_kiss_count,
		"delta": controller.velocity.x - speed_before,
	}
	controller.free()
	return result


## Checks that only the first two post-slide frames can arm a wall-jump.
func _test_wall_kiss_arming_boundary() -> void:
	heading("the two-frame wall-jump arming window")
	for contact_frame in range(3):
		var armed := _wall_kiss_contact_result(contact_frame, false)
		ok(bool(armed["armed"]) == (contact_frame < 2),
			"contact on post-slide frame %d %s the wall-jump" % [
				contact_frame + 1,
				"arms" if contact_frame < 2 else "does not arm",
			])

		var jumped := _wall_kiss_contact_result(contact_frame, true)
		var expected_boost := Tuning.WALL_KISS_BOOST if contact_frame < 2 else 0.0
		near(float(jumped["delta"]), expected_boost, 0.0001,
			"a jump on post-slide frame %d gives the expected boost" % (contact_frame + 1))
		same(int(jumped["count"]), 1 if contact_frame < 2 else 0,
			"A jump on post-slide frame %d registers the expected wall-jump." % (contact_frame + 1))


## Returns whether a wall with [param normal] arms a wall-jump.
func _arms_with_normal(normal: Vector3) -> bool:
	var pair := _at_top_speed()
	var controller: Object = pair[0]
	var input: Object = pair[1]
	input.wall_contact = true
	input.wall_normal = normal
	input.slip_pressed = true
	controller.simulate(DT, input)
	var armed: bool = controller.wall_kiss_armed
	controller.free()
	return armed


## Checks that any wall can arm a wall-jump now that movement has depth.
func _test_any_wall_normal() -> void:
	heading("any wall can arm a wall-jump")
	var normals := [
		Vector3(-1.0, 0.0, 0.0),
		Vector3(1.0, 0.0, 0.0),
		Vector3(0.0, 0.0, 1.0),
		Vector3(0.0, 0.0, -1.0),
		Vector3(-sqrt(0.5), 0.0, sqrt(0.5)),
	]
	for normal in normals:
		ok(_arms_with_normal(normal),
			"a wall with normal %s arms a wall-jump" % normal)


## Checks that the chain expires after exactly 30 frames without a wall-jump.
func _test_chain_expiry_boundary() -> void:
	heading("the wall-jump chain expiry boundary")
	var pair := _at_top_speed()
	var controller: Object = pair[0]
	var input: Object = pair[1]
	input.wall_contact = true
	input.wall_normal = Vector3(0.0, 0.0, 1.0)
	input.slip_pressed = true
	input.jump_pressed = true
	controller.simulate(DT, input)
	input.slip_pressed = false
	input.jump_pressed = false
	same(controller.wall_kiss_count, 1, "the first wall-jump starts a chain")

	input.wall_contact = false
	for _frame in range(Tuning.WALL_KISS_CHAIN_FRAMES - 1):
		controller.simulate(DT, input)
	same(controller.wall_kiss_count, 1,
		"the chain survives 29 frames without a wall-jump")

	controller.simulate(DT, input)
	same(controller.wall_kiss_count, 0,
		"the chain expires on the 30th frame without a wall-jump")

	input.wall_contact = true
	input.slip_pressed = true
	input.jump_pressed = true
	controller.simulate(DT, input)
	same(controller.wall_kiss_count, 1,
		"a legal wall-jump after expiry starts a fresh chain")
	controller.free()


## Repeated slide-and-land cycles must not accumulate momentum.
func _test_repeated_landing_slide_cycles() -> void:
	heading("repeated landing and slide cycles")
	var pair := _at_top_speed()
	var controller: Object = pair[0]
	var input: Object = pair[1]
	var peak := 0.0
	var max_air := 0.0

	for _cycle in range(100):
		# Start a slide and cancel it into a jump on the same frame.
		input.on_floor = true
		input.slip_pressed = true
		input.jump_pressed = true
		controller.simulate(DT, input)
		input.slip_pressed = false
		input.jump_pressed = false
		peak = maxf(peak, absf(controller.velocity.x))

		# Stay airborne for a complete nominal jump, then land and repeat.
		input.on_floor = false
		for _frame in range(32):
			controller.simulate(DT, input)
			peak = maxf(peak, absf(controller.velocity.x))
			max_air = maxf(max_air, controller.air_bonus)
		controller.velocity.y = 0.0
		input.on_floor = true
		controller.simulate(DT, input)

	ok(peak <= Tuning.MAX_RUN_SPEED + 0.5,
		"100 slide-and-land cycles do not become a speed exploit (%.2f m/s)" % peak)
	ok(max_air <= Tuning.AIR_ACCEL_MAX_CONTRIB + 0.0001,
		"100 slide-and-land cycles keep each air budget bounded")
	same(controller.wall_kiss_count, 0,
		"landing and sliding without a wall never registers a wall-jump")
	controller.free()


## Checks that repeated wall-jump chains cannot farm speed or hide a stale count.
func _test_repeated_wall_kiss_cycles() -> void:
	heading("repeated wall-jump cycles")
	var pair := _at_top_speed()
	var controller: Object = pair[0]
	var input: Object = pair[1]
	input.wall_contact = true
	input.wall_normal = Vector3(0.0, 0.0, 1.0)
	var peak := 0.0

	# A full quick chain of legal wall-jumps reaches the designed speed.
	for _kiss in range(Tuning.WALL_KISS_CAP):
		input.slip_pressed = true
		input.jump_pressed = true
		controller.simulate(DT, input)
		input.slip_pressed = false
		input.jump_pressed = false
		peak = maxf(peak, absf(controller.velocity.x))
	same(controller.wall_kiss_count, Tuning.WALL_KISS_CAP,
		"the quick chain reaches the cap")
	near(peak, Tuning.WALL_KISS_SPEED_CEILING, 0.0001,
		"the quick chain reaches the designed speed ceiling")

	# Every later chain expires before it can add another boost.
	for cycle in range(20):
		input.wall_contact = false
		for _frame in range(Tuning.WALL_KISS_CHAIN_FRAMES + 10):
			controller.simulate(DT, input)
		input.wall_contact = true
		input.slip_pressed = true
		input.jump_pressed = true
		controller.simulate(DT, input)
		input.slip_pressed = false
		input.jump_pressed = false
		peak = maxf(peak, absf(controller.velocity.x))
		same(controller.wall_kiss_count, 1,
			"repeated cycle %d starts from an expired chain" % (cycle + 1))

	ok(peak <= Tuning.WALL_KISS_SPEED_CEILING + 0.0001,
		"repeated wall-jump cycles never farm above the designed ceiling (%.2f m/s)" % peak)
	controller.free()


## Sweeps representative unit wall normals through the collision projection.
func _test_collision_normal_sweep() -> void:
	heading("collision normals cannot create energy")
	var cases := [
		{"normal": Vector3(-1.0, 0.0, 0.0), "expected_x": 0.0,
			"name": "head-on"},
		{"normal": Vector3(-sqrt(0.5), 0.0, sqrt(0.5)), "expected_x": 5.0,
			"name": "45-degree"},
		{"normal": Vector3(-0.1, 0.0, sqrt(0.99)), "expected_x": 9.9,
			"name": "grazing"},
		{"normal": Vector3(0.0, 0.0, 1.0), "expected_x": 10.0,
			"name": "side-parallel"},
	]
	for case in cases:
		var controller := Controller.new()
		var input := InputState.new()
		input.on_floor = false
		input.wall_contact = true
		input.wall_normal = case["normal"]
		controller.velocity = Vector3(10.0, 0.0, 0.0)
		controller.simulate(DT, input)
		near(controller.velocity.x, float(case["expected_x"]), 0.0001,
			"the %s normal removes only the into-wall component" % case["name"])
		ok(absf(controller.velocity.x) <= 10.0 + 0.0001,
			"the %s contact does not increase horizontal speed" % case["name"])
		controller.free()


## Separates the air budget's magnitude from its effect on signed speed.
func _test_air_budget_direction_audit() -> void:
	heading("the air budget measures steering, not free speed")
	var pair := _at_top_speed()
	var controller: Object = pair[0]
	var input: Object = pair[1]
	input.on_floor = false
	input.move = Vector2(-1.0, 0.0)
	controller.simulate(DT, input)
	near(controller.velocity.x, Tuning.MAX_RUN_SPEED - Tuning.AIR_ACCEL * DT, 0.0001,
		"air input against the run direction reduces speed")
	near(controller.air_bonus, Tuning.AIR_ACCEL * DT, 0.0001,
		"the steering magnitude still consumes the air budget")
	for _frame in range(300):
		controller.simulate(DT, input)
	near(controller.air_bonus, Tuning.AIR_ACCEL_MAX_CONTRIB, 0.0001,
		"opposite-direction steering cannot exceed the air budget")
	near(controller.velocity.x, Tuning.MAX_RUN_SPEED - Tuning.AIR_ACCEL_MAX_CONTRIB, 0.0001,
		"the full opposite-direction budget removes at most 2.2 m/s")
	controller.free()

	var same_pair := _at_top_speed()
	var same_controller: Object = same_pair[0]
	var same_input: Object = same_pair[1]
	same_input.on_floor = false
	same_input.move = Vector2(1.0, 0.0)
	same_controller.simulate(DT, same_input)
	near(same_controller.velocity.x, Tuning.MAX_RUN_SPEED, 0.0001,
		"air input at the run speed does not create more speed")
	near(same_controller.air_bonus, 0.0, 0.0001,
		"air input at the run speed does not consume budget")
	same_controller.free()


## Checks that one airborne stretch gets one air budget, not one per jump.
func _test_air_budget_landing_reset() -> void:
	heading("the air budget resets on landing")
	var controller := Controller.new()
	var input := InputState.new()
	input.on_floor = false
	input.move = Vector2(1.0, 0.0)
	for _frame in range(10):
		controller.simulate(DT, input)
	near(controller.air_bonus, Tuning.AIR_ACCEL_MAX_CONTRIB, 0.0001,
		"the first airborne stretch consumes one complete air budget")

	input.on_floor = true
	controller.simulate(DT, input)
	near(controller.air_bonus, 0.0, 0.0,
		"landing clears the airborne contribution budget")

	input.on_floor = false
	controller.simulate(DT, input)
	ok(controller.air_bonus > 0.0,
		"the next airborne stretch receives a fresh budget")
	controller.free()


## Runs a deterministic adversarial input sequence and reports its bounds.
func _adversarial_sequence(seed_value: int, frames: int) -> Dictionary:
	var controller := Controller.new()
	var input := InputState.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var grounded := true
	var height := 0.0
	var peak := 0.0
	var max_air := 0.0
	var max_kisses := 0
	var finite := true
	var jump_down := false
	var slip_down := false

	for _frame in range(frames):
		input.move = Vector2(
			INPUT_AXES[rng.randi_range(0, INPUT_AXES.size() - 1)],
			INPUT_AXES[rng.randi_range(0, INPUT_AXES.size() - 1)])

		# Button transitions remain physically legal: a second press cannot
		# occur before a release, and press/release cannot share a frame.
		var wants_jump := rng.randf() < 0.035
		input.jump_pressed = wants_jump and not jump_down
		input.jump_released = jump_down and rng.randf() < 0.080
		input.jump_held = (jump_down and not input.jump_released) or input.jump_pressed
		jump_down = input.jump_held

		var wants_slip := rng.randf() < 0.025
		var releases_slip := slip_down and rng.randf() < 0.080
		input.slip_pressed = wants_slip and not slip_down
		input.slip_held = (slip_down and not releases_slip) or input.slip_pressed
		slip_down = input.slip_held

		input.wall_contact = rng.randf() < 0.30
		if input.wall_contact:
			match rng.randi_range(0, 2):
				0:
					input.wall_normal = Vector3(0.0, 0.0, 1.0)
				1:
					input.wall_normal = Vector3(-1.0, 0.0, 0.0)
				_:
					input.wall_normal = Vector3(-0.2, 0.0, sqrt(0.96))
		else:
			input.wall_normal = Vector3.ZERO
		input.on_floor = grounded

		controller.simulate(DT, input)
		var speed := Vector2(controller.velocity.x, controller.velocity.z).length()
		if is_nan(speed) or is_inf(speed):
			finite = false
		peak = maxf(peak, speed)
		max_air = maxf(max_air, controller.air_bonus)
		max_kisses = maxi(max_kisses, controller.wall_kiss_count)

		if grounded:
			if controller.velocity.y > 0.0:
				grounded = false
				height = 0.0
			else:
				controller.velocity.y = 0.0
		else:
			height += controller.velocity.y * DT
			if height <= 0.0 and controller.velocity.y <= 0.0:
				grounded = true
				height = 0.0
				controller.velocity.y = 0.0

	var result := {
		"peak": peak,
		"air": max_air,
		"kisses": max_kisses,
		"finite": finite,
		"z": controller.velocity.z,
	}
	controller.free()
	return result


## Legal but adversarial input sequences must remain bounded.
func _test_adversarial_input_fuzz() -> void:
	heading("adversarial input sequences")
	var seeds := [0x13579BDF, 0x2468ACE0]
	for seed_value in seeds:
		var result := _adversarial_sequence(seed_value, 5000)
		print("      fuzz seed %d: peak %.2f m/s, air %.2f m/s, kisses %d" % [
			seed_value, float(result["peak"]), float(result["air"]),
			int(result["kisses"]),
		])
		ok(bool(result["finite"]), "fuzz seed %d keeps all speeds finite" % seed_value)
		ok(float(result["peak"]) <= DESIGNED_SPEED_CEILING + 0.0001,
			"fuzz seed %d stays below the designed 16.4 m/s ceiling" % seed_value)
		ok(float(result["peak"]) <= DISCOVERY_SPEED_ENVELOPE + 0.0001,
			"fuzz seed %d stays inside the 20.2 m/s discovery envelope" % seed_value)
		ok(float(result["air"]) <= Tuning.AIR_ACCEL_MAX_CONTRIB + 0.0001,
			"fuzz seed %d respects the air budget" % seed_value)
		ok(int(result["kisses"]) >= 0, "fuzz seed %d reports a non-negative wall-jump count" % seed_value)
		ok(int(result["kisses"]) <= Tuning.WALL_KISS_CAP,
			"fuzz seed %d respects the wall-jump chain cap" % seed_value)
		ok(is_finite(float(result["z"])), "fuzz seed %d keeps depth finite" % seed_value)


## Replays a route while recording the complete movement state.
func _full_state_trace() -> PackedFloat64Array:
	var controller := Controller.new()
	var input := InputState.new()
	var trace := PackedFloat64Array()
	for frame in range(600):
		input.on_floor = (frame % 97) < 61
		input.move = Vector2(1.0 if (frame % 31) < 24 else -1.0, 0.0)
		input.jump_pressed = (frame % 97) == 60
		input.jump_held = (frame % 97) >= 60 and (frame % 97) <= 66
		input.jump_released = (frame % 97) == 66
		input.slip_pressed = (frame % 97) == 20
		input.slip_held = (frame % 97) >= 20 and (frame % 97) <= 24
		input.wall_contact = (frame % 97) >= 20 and (frame % 97) <= 24
		input.wall_normal = Vector3(0.0, 0.0, 1.0)
		controller.simulate(DT, input)
		trace.append(controller.velocity.x)
		trace.append(controller.velocity.y)
		trace.append(controller.velocity.z)
		trace.append(controller.air_bonus)
		trace.append(controller.airborne_frames)
		trace.append(controller.coyote_frames)
		trace.append(controller.facing)
		trace.append(controller.jump_buffer_frames)
		trace.append(controller.slide_frames)
		trace.append(1.0 if controller.sliding else 0.0)
		trace.append(controller.speed_ratio)
		trace.append(1.0 if controller.wall_kiss_armed else 0.0)
		trace.append(controller.wall_kiss_count)
		trace.append(controller.wall_kiss_frames)
		trace.append(controller.frames_since_kiss)
		trace.append(1.0 if controller._was_on_floor else 0.0)
	controller.free()
	return trace


## Two full movement-state replays must have the same checksum.
func _test_full_state_replay_hash() -> void:
	heading("the full-state replay hash")
	var first := _full_state_trace()
	var second := _full_state_trace()
	var identical := first.size() == second.size()
	if identical:
		for index in range(first.size()):
			if first[index] != second[index]:
				identical = false
				break
	ok(identical, "two 600-frame replays have identical full movement state")
	same(hash(first), hash(second), "the full movement-state replay hash is stable")
