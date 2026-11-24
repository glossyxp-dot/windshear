# WindShear — movement probe harness
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
## A kinematic harness for playing one technique and measuring what the
## movement code actually does with it.
##
## The interesting mechanics are the ones nobody planned. WindShear finds a
## technique with this harness first. Only afterwards does somebody decide
## whether it is a feature, a bug or a non-starter. The game code does not
## make a technique work. It makes the verb work, and the technique falls out
## of the numbers.
##
## There is no physics engine here. The controller runs frame by frame and
## the harness keeps a crude ground model of it's own. That is enough for speed
## questions in metres per second, and it keeps every probe deterministic.
extends RefCounted
class_name MovementProbe

## The player controller.
const Controller := preload("res://addons/windshear/movement/lancer_controller.gd")
## The per-frame input record.
const InputState := preload("res://addons/windshear/movement/lancer_input.gd")
## Movement tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")

## One physics frame.
const DT := 1.0 / 60.0
## The height of Lancer's centre when standing on the floor.
const FLOOR_Y := 0.9

## The fastest speed seen during the probe.
var peak_speed := 0.0
## The speed at the end of the probe.
var final_speed := 0.0
## The number of jumps that happened.
var jumps := 0
## The number of slides that started.
var slides := 0
## The longest wall-jump chain that happened. The counter keeps the old
## internal name.
var kisses := 0
## The largest air acceleration contribution that was reached.
var max_air_bonus := 0.0
## The largest z velocity that was reached.
var max_z_velocity := 0.0
## Where Lancer ended up.
var position := Vector3.ZERO
## True while Lancer is on the floor.
var grounded := true

var _controller := Controller.new()
var _input := InputState.new()


func _init(start: Vector3 = Vector3.ZERO) -> void:
	position = start


## Runs [param frames] frames of movement.
##
## [param script] is called before every frame with the arguments
## (frame, input, controller, probe), so it can set the input and look at
## what happened so far.
func run(frames: int, script: Callable) -> void:
	for frame in range(frames):
		script.call(frame, _input, _controller, self)
		_input.on_floor = grounded
		var vertical_before := _controller.velocity.y
		_controller.simulate(DT, _input)
		if vertical_before <= 0.0 and _controller.velocity.y > 0.0:
			jumps += 1
		if _controller.sliding and slides == 0:
			slides += 1
		kisses = maxi(kisses, _controller.wall_kiss_count)
		max_air_bonus = maxf(max_air_bonus, _controller.air_bonus)
		max_z_velocity = maxf(max_z_velocity, absf(_controller.velocity.z))
		peak_speed = maxf(peak_speed, absf(_controller.velocity.x))
		_update_ground()
	final_speed = absf(_controller.velocity.x)


## Returns the controller so a probe script can inspect its state.
func controller() -> Object:
	return _controller


## Releases the probe's objects.
func release() -> void:
	if is_instance_valid(_controller):
		_controller.free()


## Keeps Lancer on the floor.
func _update_ground() -> void:
	if grounded and _controller.velocity.y > 0.0:
		grounded = false
	if grounded:
		_controller.velocity.y = 0.0
		position.x += _controller.velocity.x * DT
	else:
		position += _controller.velocity * DT
		if position.y <= FLOOR_Y and _controller.velocity.y <= 0.0:
			grounded = true
			position.y = FLOOR_Y
			_controller.velocity.y = 0.0
