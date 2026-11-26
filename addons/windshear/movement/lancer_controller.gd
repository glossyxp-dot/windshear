# WindShear — Lancer's movement controller (the FPS and platformer core)
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
## Lancer is a plain [CharacterBody3D] with frame-exact control.
##
## Every number comes from [constant Tuning], which mirrors `TECH_SPEC.md`
## §3. Behaviour goes through [method simulate], a deterministic function of
## the input state and frame length. That lets the test suite replay exact
## frames without a window, a mouse or a physics world. Two runs of the same
## route produce byte-identical velocities.
##
## Three rules are easy to break by accident:
## [br]- movement is camera-relative on the ground plane. [code]W[/code] walks
##   along the camera's facing and [code]A[/code]/[code]D[/code] strafe across
##   it. There is no fixed forward axis.
## [br]- nothing is allocated in the frame loop. The input object is
##   created once and reused.
## [br]- no random numbers. Wind, gates and hazards use the section-seeded
##   generator in [code]WsGame.rng_for_section()[/code].
##
## A wall-jump works like this. A slide opens a two-frame window. Touching a
## wall inside that window arms the jump, and pressing Space adds 0.8 m/s to
## Lancer's speed along the direction of travel while launching Lancer. The
## bonus survives ground acceleration because the jump happens on the same
## frame, so the boost carries through the air.
##
## The base chain holds three wall-jumps and stops at 16.4 m/s.
## The shipped `wall_kiss_chain` Fracture takes it to five and 18.0 m/s.
## Changing that split would require a explicit product decision.
extends CharacterBody3D
class_name LancerController

## Movement tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")
## The per-frame input record.
const LancerInputState := preload("res://addons/windshear/movement/lancer_input.gd")

## Emitted when a wall-jump connects. [param count] is the chain length.
signal wall_kiss_registered(count: int)
## Emitted on every jump, including wall-jump assisted ones.
signal jump_performed()

## When false the controller ignores the keyboard and only uses the state
## pushed into it by [method simulate]. The test suite uses this.
var live_input := true

# --- Public state ---------------------------------------------------------

## Facing direction: 1.0 for right, -1.0 for left.
var facing := 1.0
## Frames of coyote time still available.
var coyote_frames := 0
## Frames the buffered jump press still has left.
var jump_buffer_frames := 0
## Frames the current slide still has left.
var slide_frames := 0
## Frames left in the wall-jump contact window.
var wall_kiss_frames := 0
## True when a wall was touched inside the window and a jump can use it.
var wall_kiss_armed := false
## Wall-jumps in the current chain.
var wall_kiss_count := 0
## Frames since the last wall-jump. The chain expires when this runs out.
var frames_since_kiss := 0
## Speed contributed by air acceleration during the current airborne stretch.
var air_bonus := 0.0
## Frames spent airborne.
var airborne_frames := 0
## Horizontal speed as a fraction of the top speed.
var speed_ratio := 0.0
## True while a slide is running.
var sliding := false

## Wall-jumps allowed in one chain. Three in the base game; the
## `wall_kiss_chain` Fracture raises it.
var wall_kiss_cap := Tuning.WALL_KISS_CAP
## The horizontal speed a chain may not pass. The Fracture raises it too,
## because five boosts need more room than three.
var wall_kiss_speed_ceiling := Tuning.WALL_KISS_SPEED_CEILING

## Live overrides for the movement numbers.
##
## The workbench points this at the same dictionary the `WsTweak` autoload
## holds, so a slider that moves writes straight into the live simulation.
## An empty dictionary means the documented constants, which is what the test
## suite always gets.
var overrides := {}

## True while the shipped `wall_kiss_chain` Fracture is active.
var wall_kiss_fracture_active := false

# --- Private state --------------------------------------------------------

var _input := LancerInputState.new()
var _was_on_floor := true


func _physics_process(delta: float) -> void:
	_gather_input()
	simulate(delta, _input)
	move_and_slide()


## Reads the live input devices into the reusable input record.
func _gather_input() -> void:
	_input.reset()
	if live_input:
		_input.move = Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_back", "move_forward"))
		_input.jump_pressed = Input.is_action_just_pressed("jump")
		_input.jump_held = Input.is_action_pressed("jump")
		_input.jump_released = Input.is_action_just_released("jump")
		_input.slip_pressed = Input.is_action_just_pressed("slip")
		_input.slip_held = Input.is_action_pressed("slip")
		var rig := get_node_or_null("CameraRig") as CameraRig
		if rig != null:
			_input.camera_yaw = rig.yaw
	_input.on_floor = is_on_floor()
	_input.wall_contact = is_on_wall()
	if _input.wall_contact:
		_input.wall_normal = get_wall_normal()


## Advances the movement simulation by one frame.
##
## [param inp] describes what the player did this frame; [param delta] is the
## frame length in seconds. Call this exactly once per physics frame.
func simulate(delta: float, inp: LancerInputState) -> void:
	var jumped := false
	_refresh_wall_kiss_limits()

	# --- frame timers ----------------------------------------------------
	if inp.on_floor:
		coyote_frames = _frames("coyote_frames", Tuning.COYOTE_FRAMES)
	var can_jump := inp.on_floor or coyote_frames > 0
	if inp.jump_pressed:
		jump_buffer_frames = _frames("jump_buffer_frames", Tuning.JUMP_BUFFER_FRAMES)

	# --- landing bookkeeping --------------------------------------------
	if inp.on_floor:
		if not _was_on_floor:
			air_bonus = 0.0
			airborne_frames = 0
	else:
		airborne_frames += 1

	# --- slide ----------------------------------------------------------
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	if inp.slip_pressed and inp.on_floor and slide_frames <= 0 \
			and ground_speed >= _live_value("slide_min_speed", Tuning.SLIDE_MIN_SPEED):
		slide_frames = _slide_frames()
		wall_kiss_frames = _frames("wall_kiss_window_frames", Tuning.WALL_KISS_WINDOW_FRAMES)
		wall_kiss_armed = false

	# --- wall contact ---------------------------------------------------
	if inp.wall_contact:
		# Drop the component pointing into the wall, exactly like the physics
		# engine does, so the simulation and the real body agree.
		var into_wall := velocity.dot(inp.wall_normal)
		if into_wall < 0.0:
			velocity -= inp.wall_normal * into_wall
		if slide_frames > 0 and wall_kiss_frames > 0:
			wall_kiss_armed = true
	else:
		wall_kiss_armed = false

	# --- jump ------------------------------------------------------------
	if jump_buffer_frames > 0 and can_jump:
		velocity.y = _live_value("jump_velocity", Tuning.JUMP_VELOCITY)
		jump_buffer_frames = 0
		coyote_frames = 0
		slide_frames = 0
		sliding = false
		jumped = true
		jump_performed.emit()
		if wall_kiss_armed and wall_kiss_count < wall_kiss_cap:
			_apply_wall_kiss(inp)
	elif jump_buffer_frames > 0:
		jump_buffer_frames -= 1

	# --- horizontal movement ---------------------------------------------
	if jumped:
		# Lancer left the ground this frame: no ground acceleration, so a
		# wall-jump boost is not eaten by the speed cap in the same frame.
		pass
	elif inp.on_floor:
		var horizontal := Vector3(velocity.x, 0.0, velocity.z)
		if slide_frames > 0:
			horizontal = horizontal.move_toward(Vector3.ZERO,
				_live_value("slide_friction", Tuning.SLIDE_FRICTION) * delta)
		else:
			var wish := _wish_direction(inp)
			if wish != Vector3.ZERO:
				horizontal = horizontal.move_toward(
					wish * _live_value("max_run_speed", Tuning.MAX_RUN_SPEED),
					_live_value("ground_accel", Tuning.GROUND_ACCEL) * delta)
			else:
				horizontal = horizontal.move_toward(Vector3.ZERO,
					_live_value("ground_decel", Tuning.GROUND_DECEL) * delta)
		velocity.x = horizontal.x
		velocity.z = horizontal.z
	else:
		_air_control(delta, inp)

	# --- vertical --------------------------------------------------------
	if inp.jump_released and velocity.y > 0.0:
		velocity.y *= _live_value("jump_cut", Tuning.JUMP_CUT)
	if not inp.on_floor:
		velocity.y -= _live_value("gravity", Tuning.GRAVITY) * delta

	# --- speed ceiling ---------------------------------------------------
	# The wall-jump ceiling is a speed limit, not just an X limit. Without
	# this, a player could steer perpendicular to a maxed chain and let air
	# control add on top of it.
	var limit := _speed_limit()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var horizontal_speed := horizontal.length()
	if horizontal_speed > limit:
		horizontal *= limit / horizontal_speed
		velocity.x = horizontal.x
		velocity.z = horizontal.z

	# --- facing and speed readout -----------------------------------------
	var wish := _wish_direction(inp)
	if absf(wish.x) > 0.0:
		facing = signf(wish.x)
	speed_ratio = Vector2(velocity.x, velocity.z).length() \
		/ _live_value("max_run_speed", Tuning.MAX_RUN_SPEED)

	# --- end of frame counters ---------------------------------------------
	if slide_frames > 0:
		slide_frames -= 1
	sliding = slide_frames > 0
	if wall_kiss_frames > 0 and slide_frames > 0:
		wall_kiss_frames -= 1
	if not inp.on_floor and coyote_frames > 0:
		coyote_frames -= 1
	if wall_kiss_count > 0:
		frames_since_kiss += 1
		if frames_since_kiss > _frames("wall_kiss_chain_frames", Tuning.WALL_KISS_CHAIN_FRAMES):
			wall_kiss_count = 0
			frames_since_kiss = 0
	_was_on_floor = inp.on_floor


## Air control accelerates towards the input direction. The total speed it may
## add over one airborne stretch is capped.
func _air_control(delta: float, inp: LancerInputState) -> void:
	var direction := _wish_direction(inp)
	if direction == Vector3.ZERO:
		return
	var top_speed := _live_value("max_run_speed", Tuning.MAX_RUN_SPEED)
	var current := velocity.dot(direction)
	if top_speed - current <= 0.0:
		return
	var add := minf(
		_live_value("air_accel", Tuning.AIR_ACCEL) * delta,
		_live_value("air_accel_max_contrib", Tuning.AIR_ACCEL_MAX_CONTRIB) - air_bonus)
	if add <= 0.0:
		return
	velocity += direction * add
	air_bonus += add


## Turns the stick or WASD into a world-space direction on the ground plane.
##
## Movement is relative to the camera, so "forward" is wherever the camera is
## looking. The yaw travels on the input record because [method simulate] has
## to stay a pure function for the replay and discovery harnesses.
func _wish_direction(inp: LancerInputState) -> Vector3:
	var move := inp.move
	if move.length_squared() <= 0.0:
		return Vector3.ZERO
	# A keyboard diagonal is longer than one; a partly pushed stick is not.
	# Clamp the first and keep the second, so the stick still walks slower.
	if move.length() > 1.0:
		move = move.normalized()
	var forward := Vector3(-sin(inp.camera_yaw), 0.0, -cos(inp.camera_yaw))
	var right := Vector3(cos(inp.camera_yaw), 0.0, -sin(inp.camera_yaw))
	return forward * move.y + right * move.x


## Adds one wall-jump boost along the direction of travel.
##
## The boost is capped, and the cap belongs to the controller rather than the
## tuning file because the Fracture moves it. Three wall-jumps take the running
## speed to 16.4 m/s and not a metre further; five take it to
## 18.0. Without a cap, a long route could stack boosts until Lancer was faster
## than the level designer expected. The discovery suite
## (`tests/test_movement_discovery.gd`) found it.
func _apply_wall_kiss(inp: LancerInputState) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var direction := horizontal.normalized()
	if direction == Vector3.ZERO:
		var fallback := _wish_direction(inp)
		if fallback != Vector3.ZERO:
			direction = fallback.normalized()
	if direction == Vector3.ZERO:
		direction = Vector3(facing, 0.0, 0.0)
	var boost := minf(
		_live_value("wall_kiss_boost", Tuning.WALL_KISS_BOOST),
		_speed_limit() - horizontal.length())
	wall_kiss_armed = false
	if boost <= 0.0:
		return
	velocity += direction * boost
	wall_kiss_count += 1
	frames_since_kiss = 0
	wall_kiss_registered.emit(wall_kiss_count)


## Turns on the shipped `wall_kiss_chain` Fracture.
##
## The registry says the chain stacks to five, and registry text does not
## change once it has shipped. The fourth and fifth wall-jump live here. The
## speed ceiling rises with the count because five boosts of 0.8 metres per
## second need more room above the run speed than three do.
func enable_wall_kiss_chain_fracture() -> void:
	wall_kiss_fracture_active = true
	_refresh_wall_kiss_limits()


## Puts the chain back to the base game's three wall-jumps and 16.4 metres per
## second.
func disable_wall_kiss_chain_fracture() -> void:
	wall_kiss_fracture_active = false
	_refresh_wall_kiss_limits()


## Works out the chain cap and the speed ceiling in force right now.
##
## The Fracture wins over the workbench, because a shipped Fracture is canon
## and a slider is not. Without the Fracture, the numbers are the live ones,
## so a slider can move them while the room is open.
func _refresh_wall_kiss_limits() -> void:
	if wall_kiss_fracture_active:
		wall_kiss_cap = Tuning.WALL_KISS_FRACTURE_CAP
		wall_kiss_speed_ceiling = Tuning.WALL_KISS_FRACTURE_SPEED_CEILING
		return
	wall_kiss_cap = _frames("wall_kiss_cap", Tuning.WALL_KISS_CAP)
	wall_kiss_speed_ceiling = _live_value(
		"wall_kiss_speed_ceiling", Tuning.WALL_KISS_SPEED_CEILING)


## The horizontal speed this chain may not pass.
##
## The documented ceiling is the floor, not the whole answer. A workbench
## that raises the run speed raises the limit with it, so the chain still
## means something and the technique still cannot be farmed. With the shipped
## numbers this is exactly 16.4 m/s: 14.0 plus three boosts of 0.8. With the
## Fracture it is 18.0: 14.0 plus five boosts.
func _speed_limit() -> float:
	var run_speed := _live_value("max_run_speed", Tuning.MAX_RUN_SPEED)
	var boost := _live_value("wall_kiss_boost", Tuning.WALL_KISS_BOOST)
	var chain := float(wall_kiss_cap) * boost
	return maxf(wall_kiss_speed_ceiling, run_speed + chain)


## The live value of one movement number.
##
## Without an override this is the documented constant, which is what the test
## suite always gets. The workbench fills [member overrides] and the slider
## wins.
func _live_value(key: String, fallback: float) -> float:
	if overrides.has(key):
		return float(overrides[key])
	return fallback


## The live value of one movement number, in whole frames.
func _frames(key: String, fallback: int) -> int:
	return int(round(_live_value(key, float(fallback))))


## The live length of a slide, in frames.
##
## The slider moves the duration in seconds and the frames follow, so the two
## numbers can never disagree.
func _slide_frames() -> int:
	var seconds := _live_value("slide_duration", Tuning.SLIDE_DURATION)
	return int(round(seconds * Tuning.PHYSICS_TICK))


## Puts Lancer back at [param spawn_position] with no momentum.
func respawn(spawn_position: Vector3) -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	facing = 1.0
	coyote_frames = 0
	jump_buffer_frames = 0
	slide_frames = 0
	wall_kiss_frames = 0
	wall_kiss_armed = false
	wall_kiss_count = 0
	frames_since_kiss = 0
	air_bonus = 0.0
	airborne_frames = 0
	speed_ratio = 0.0
	sliding = false
	_was_on_floor = true
