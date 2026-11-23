# WindShear — Lancer's movement controller (the FPS/platformer core)
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
## A plain [CharacterBody3D] with frame-exact control.
##
## Every number comes from [constant Tuning] (which mirrors `TECH_SPEC.md`
## §3) and every behaviour is driven through [method simulate], a pure
## function of the input state. That is what lets the test suite replay exact
## frames without a window, a mouse or a physics world — and it is also what
## makes two runs of the same route produce byte-identical velocities.
##
## Rules that are easy to break by accident:
## [br]1. The player never leaves the XY plane. [code]velocity.z[/code] is
##    zeroed every frame.
## [br]2. Nothing is allocated in the frame loop. The input object is
##    created once and reused.
## [br]3. No random numbers. Wind, gates and hazards are driven by the
##    section-seeded generator in [code]WsGame.rng_for_section()[/code].
##
## The wall-kiss in one paragraph: a slide opens a two-frame window; touching
## a side wall (a wall that runs alongside the route) inside that window arms
## a kiss; pressing jump while armed adds 0.8 m/s to the running speed and
## launches Lancer. The bonus survives the ground acceleration because the
## jump happens on the same frame, so the boost is carried through the air.
## A chain is three wall-jumps long in the base game. The `wall_kiss_chain`
## Fracture takes it to five.
extends CharacterBody3D
class_name LancerController

## Movement tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")
## The per-frame input record.
const LancerInputState := preload("res://addons/windshear/movement/lancer_input.gd")

## Emitted when a wall-kiss connects. [param count] is the chain length.
signal wall_kiss_registered(count: int)
## Emitted on every jump, including wall-kiss assisted ones.
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
## Frames left in the wall-kiss contact window.
var wall_kiss_frames := 0
## True when a side wall was touched inside the window and a jump would kiss it.
var wall_kiss_armed := false
## Wall-kisses in the current chain.
var wall_kiss_count := 0
## Frames since the last wall-kiss. The chain expires when this runs out.
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
		_input.move_axis = Input.get_axis("move_left", "move_right")
		_input.jump_pressed = Input.is_action_just_pressed("jump")
		_input.jump_held = Input.is_action_pressed("jump")
		_input.jump_released = Input.is_action_just_released("jump")
		_input.slip_pressed = Input.is_action_just_pressed("slip")
		_input.slip_held = Input.is_action_pressed("slip")
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

	# --- frame timers ----------------------------------------------------
	if inp.on_floor:
		coyote_frames = Tuning.COYOTE_FRAMES
	var can_jump := inp.on_floor or coyote_frames > 0
	if inp.jump_pressed:
		jump_buffer_frames = Tuning.JUMP_BUFFER_FRAMES

	# --- landing bookkeeping --------------------------------------------
	if inp.on_floor:
		if not _was_on_floor:
			air_bonus = 0.0
			airborne_frames = 0
	else:
		airborne_frames += 1

	# --- slide ----------------------------------------------------------
	if inp.slip_pressed and inp.on_floor and slide_frames <= 0 \
			and absf(velocity.x) >= Tuning.SLIDE_MIN_SPEED:
		slide_frames = Tuning.SLIDE_FRAMES
		wall_kiss_frames = Tuning.WALL_KISS_WINDOW_FRAMES
		wall_kiss_armed = false

	# --- wall contact ---------------------------------------------------
	if inp.wall_contact:
		# Drop the component pointing into the wall, exactly like the physics
		# engine does, so the simulation and the real body agree.
		var into_wall := velocity.dot(inp.wall_normal)
		if into_wall < 0.0:
			velocity -= inp.wall_normal * into_wall
		if slide_frames > 0 and wall_kiss_frames > 0 and _is_side_wall(inp.wall_normal):
			wall_kiss_armed = true
	else:
		wall_kiss_armed = false

	# --- jump ------------------------------------------------------------
	if jump_buffer_frames > 0 and can_jump:
		velocity.y = Tuning.JUMP_VELOCITY
		jump_buffer_frames = 0
		coyote_frames = 0
		slide_frames = 0
		sliding = false
		jumped = true
		jump_performed.emit()
		if wall_kiss_armed and wall_kiss_count < wall_kiss_cap:
			_apply_wall_kiss()
	elif jump_buffer_frames > 0:
		jump_buffer_frames -= 1

	# --- horizontal movement ---------------------------------------------
	if jumped:
		# Lancer left the ground this frame: no ground acceleration, so a
		# wall-kiss boost is not eaten by the speed cap in the same frame.
		pass
	elif inp.on_floor:
		if slide_frames > 0:
			velocity.x = move_toward(velocity.x, 0.0, Tuning.SLIDE_FRICTION * delta)
		else:
			var target := inp.move_axis * Tuning.MAX_RUN_SPEED
			if absf(inp.move_axis) > 0.0:
				velocity.x = move_toward(velocity.x, target, Tuning.GROUND_ACCEL * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, Tuning.GROUND_DECEL * delta)
	else:
		_air_control(delta, inp)

	# --- vertical --------------------------------------------------------
	if inp.jump_released and velocity.y > 0.0:
		velocity.y *= Tuning.JUMP_CUT
	if not inp.on_floor:
		velocity.y -= Tuning.GRAVITY * delta

	# --- plane and facing -------------------------------------------------
	velocity.z = 0.0
	if absf(inp.move_axis) > 0.0:
		facing = signf(inp.move_axis)
	speed_ratio = absf(velocity.x) / Tuning.MAX_RUN_SPEED

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
		if frames_since_kiss > Tuning.WALL_KISS_CHAIN_FRAMES:
			wall_kiss_count = 0
			frames_since_kiss = 0
	_was_on_floor = inp.on_floor


## Air control: accelerate towards the wish direction, but the total amount
## the air acceleration may add over one airborne stretch is capped.
func _air_control(delta: float, inp: LancerInputState) -> void:
	if absf(inp.move_axis) <= 0.0:
		return
	var direction := Vector3(signf(inp.move_axis), 0.0, 0.0)
	var current := velocity.dot(direction)
	if Tuning.MAX_RUN_SPEED - current <= 0.0:
		return
	var add := minf(Tuning.AIR_ACCEL * delta, Tuning.AIR_ACCEL_MAX_CONTRIB - air_bonus)
	if add <= 0.0:
		return
	velocity += direction * add
	air_bonus += add


## True when the wall runs alongside the route instead of blocking it.
##
## A side wall has a normal that points mostly along Z; a wall straight ahead
## has a normal along X. Only side walls can be kissed.
func _is_side_wall(normal: Vector3) -> bool:
	return absf(normal.z) >= 0.5


## Adds one wall-kiss boost to the running speed.
##
## The boost is capped, and the cap belongs to the controller rather than to
## the tuning file, because the Fracture moves it. Three kisses take the
## running speed to 16.4 m/s and not a metre further; five take it to 18.0.
## Without a cap a long route could stack kisses until the player was faster
## than the level designer expected — the discovery suite
## (`tests/test_movement_discovery.gd`) is what found it.
func _apply_wall_kiss() -> void:
	var direction := signf(velocity.x)
	if direction == 0.0:
		direction = facing
	var boost := minf(Tuning.WALL_KISS_BOOST,
		wall_kiss_speed_ceiling - absf(velocity.x))
	wall_kiss_armed = false
	if boost <= 0.0:
		return
	velocity.x += direction * boost
	wall_kiss_count += 1
	frames_since_kiss = 0
	wall_kiss_registered.emit(wall_kiss_count)


## Turns the `wall_kiss_chain` Fracture on.
##
## The registry says the chain stacks to five, and registry text does not
## change once it has shipped, so the fourth and fifth wall-jump live here.
## The speed ceiling goes up with the count, because five boosts of 0.8 m/s
## need more room above the run speed than three of them do.
func enable_wall_kiss_chain_fracture() -> void:
	wall_kiss_cap = Tuning.WALL_KISS_FRACTURE_CAP
	wall_kiss_speed_ceiling = Tuning.WALL_KISS_FRACTURE_SPEED_CEILING


## Puts the chain back to the base game's three.
func disable_wall_kiss_chain_fracture() -> void:
	wall_kiss_cap = Tuning.WALL_KISS_CAP
	wall_kiss_speed_ceiling = Tuning.WALL_KISS_SPEED_CEILING


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
