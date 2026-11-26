# WindShear — tuning constants must match the technical specification
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
## The numbers in `TECH_SPEC.md` §3 are a contract. If somebody tunes the
## controller and forgets the document, or updates the document and forgets
## the controller, the speedrun community finds out the hard way. This suite
## is the alarm.
extends "res://tests/ws_test.gd"

## Movement tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")


func suite_name() -> String:
	return "tuning constants match TECH_SPEC.md section 3"


func run() -> void:
	heading("simulation")
	same(Tuning.PHYSICS_TICK, 60, "the physics tick is 60 Hz")
	near(Tuning.FRAME_DELTA, 1.0 / 60.0, 0.000001, "one frame is 1/60 s")

	heading("ground movement")
	near(Tuning.MAX_RUN_SPEED, 14.0, 0.0001, "max run speed")
	near(Tuning.GROUND_ACCEL, 90.0, 0.0001, "ground acceleration")
	near(Tuning.GROUND_DECEL, 60.0, 0.0001, "ground deceleration")

	heading("air movement")
	near(Tuning.AIR_ACCEL, 32.0, 0.0001, "air acceleration")
	near(Tuning.AIR_ACCEL_MAX_CONTRIB, 2.2, 0.0001, "air acceleration contribution cap")

	heading("jump")
	near(Tuning.JUMP_VELOCITY, 15.5, 0.0001, "jump velocity")
	same(Tuning.COYOTE_FRAMES, 8, "coyote time in frames")
	same(Tuning.JUMP_BUFFER_FRAMES, 10, "jump buffer in frames")
	ok(Tuning.JUMP_CUT > 0.0 and Tuning.JUMP_CUT < 1.0, "the jump cut makes jump height variable")
	near(Tuning.JUMP_VELOCITY * Tuning.JUMP_VELOCITY / (2.0 * Tuning.GRAVITY), 2.0, 0.01,
		"the jump apex is about 2 m")

	heading("slide")
	near(Tuning.SLIDE_DURATION, 0.45, 0.0001, "slide duration")
	same(Tuning.SLIDE_FRAMES, 27, "slide duration in frames")
	near(Tuning.SLIDE_FRICTION, 6.0, 0.0001, "slide friction")
	near(Tuning.SLIDE_MIN_SPEED, 5.0, 0.0001, "the slide needs 5 m/s to start")

	# The base chain stops at three: 14.0 m/s plus three boosts of 0.8 m/s
	# gives the hard 16.4 m/s ceiling. The shipped wall_kiss_chain Fracture
	# takes the chain to five and the ceiling to 18.0 m/s.
	heading("wall-jump")
	same(Tuning.WALL_KISS_WINDOW_FRAMES, 2, "the wall-jump window is two frames")
	near(Tuning.WALL_KISS_BOOST, 0.8, 0.0001, "the wall-jump boost is 0.8 m/s")
	same(Tuning.WALL_KISS_CAP, 3, "the wall-jump chain cap is three")
	same(Tuning.WALL_KISS_FRACTURE_CAP, 5, "the shipped Fracture chain cap is five")
	same(Tuning.WALL_KISS_CHAIN_FRAMES, 30, "the wall-jump chain expires after 30 frames")
	near(Tuning.WALL_KISS_SPEED_CEILING, 16.4, 0.0001,
		"the wall-jump horizontal speed ceiling is 16.4 m/s")
	near(Tuning.WALL_KISS_FRACTURE_SPEED_CEILING, 18.0, 0.0001,
		"the Fracture horizontal speed ceiling is 18.0 m/s")

	heading("filament")
	near(Tuning.FILAMENT_LOCK_TIME, 0.25, 0.0001, "filament lock-on time")
	near(Tuning.FILAMENT_CONE_DEGREES, 18.0, 0.0001, "filament cone half-angle")
