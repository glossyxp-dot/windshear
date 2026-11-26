# WindShear — one frame of controller input (the movement input record)
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
## One frame of controller input, kept as plain data.
##
## The movement controller consumes one record per physics frame. I keep input
## separate from movement because the test suite can replay an exact sequence
## of frames without a window, a mouse or a physics world.
extends RefCounted
class_name LancerInput

## Movement input on the ground plane. [code]x[/code] is strafe (A/D),
## [code]y[/code] is forward/back (W/S), both in [-1.0, 1.0].
var move := Vector2.ZERO
## The camera's yaw in radians. Movement is relative to where the camera looks,
## so the controller needs the angle without reaching into the scene tree.
var camera_yaw := 0.0
## True on the frame the jump button went down.
var jump_pressed := false
## True while the jump button is held.
var jump_held := false
## True on the frame the jump button came up.
var jump_released := false
## True on the frame the slide button went down.
var slip_pressed := false
## True while the slide button is held.
var slip_held := false
## True while Lancer is standing on something.
var on_floor := false
## True while Lancer is touching a wall.
var wall_contact := false
## Normal of the wall being touched, pointing away from the wall.
var wall_normal := Vector3.ZERO


## Clears every field. The controller calls this once per frame before it
## writes the live values, so the object is reused instead of reallocated.
func reset() -> void:
	move = Vector2.ZERO
	camera_yaw = 0.0
	jump_pressed = false
	jump_held = false
	jump_released = false
	slip_pressed = false
	slip_held = false
	on_floor = false
	wall_contact = false
	wall_normal = Vector3.ZERO
