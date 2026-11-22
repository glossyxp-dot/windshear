# WindShear — what the movement code actually permits
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
## The discovery suite.
##
## Every movement game has techniques that nobody designed: bunny hopping,
## the strafe flick, the slide-hop, the wall-kiss chain. The rule in this
## project is that those techniques are *found*, not *built*. The game code
## implements the verbs — run, slide, jump, wall-kiss — with the numbers in
## `TECH_SPEC.md` §3, and this suite plays the candidate techniques against
## that code and reports what happens.
##
## Nothing here is a feature list. The suite asserts three kinds of thing:
## [br]- the invariants (the speed is bounded, the plane holds, the air
##   contribution cap holds, the chain cap holds);
## [br]- the honesty of the report (every probe is printed, so a change in
##   the movement code shows up in the output);
## [br]- one promise: bunny hopping is not a speed exploit in WindShear.
##   If that assertion ever fails, somebody changed the physics on purpose
##   and has to decide what the change means.
extends "res://tests/ws_test.gd"

## The probe harness.
const Probe := preload("res://tests/movement_probe.gd")
## Movement tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")

## The fastest speed the design can produce: the run speed, plus one full
## air acceleration contribution, plus a full wall-kiss chain.
const SPEED_CEILING := 20.2
## How much faster than a plain run a technique may be before it counts as
## an exploit rather than a technique.
const EXPLOIT_MARGIN := 0.5

## The probes, in the order they are reported.
var _report: Array[Dictionary] = []


func suite_name() -> String:
	return "what the movement permits"


func run() -> void:
	_probe_plain_run()
	_probe_bunny_hop()
	_probe_slide_hop()
	_probe_air_flick()
	_probe_wall_kiss_chain()
	_probe_turnaround()
	_print_report()
	_assert_invariants()


## Just running.
func _probe_plain_run() -> void:
	var probe: Object = Probe.new(Vector3(-24.0, 0.9, 0.0))
	probe.run(300, func(_frame, input, _controller, _probe):
		input.move_axis = 1.0
	)
	_record("plain run", probe, "the baseline: hold the stick")
	probe.release()


## Jumping on every landing. The classic bunny hop.
func _probe_bunny_hop() -> void:
	var probe: Object = Probe.new(Vector3(-24.0, 0.9, 0.0))
	probe.run(600, func(_frame, input, _controller, _probe):
		input.move_axis = 1.0
		input.jump_pressed = _probe.grounded
	)
	_record("bunny hop", probe, "jump on every landing")
	probe.release()


## Sliding into the jump: the slide-hop.
func _probe_slide_hop() -> void:
	var probe: Object = Probe.new(Vector3(-24.0, 0.9, 0.0))
	probe.run(420, func(frame, input, _controller, _probe):
		input.move_axis = 1.0
		if frame == 120:
			input.slip_pressed = true
		if frame == 121:
			input.jump_pressed = true
	)
	_record("slide-hop", probe, "slide, then jump on the next frame")
	probe.release()


## Running one way and pulling the other way in the air.
func _probe_air_flick() -> void:
	var probe: Object = Probe.new(Vector3(-24.0, 0.9, 0.0))
	probe.run(300, func(frame, input, _controller, _probe):
		if frame < 60:
			input.move_axis = 1.0
		elif frame == 60:
			input.move_axis = 1.0
			input.jump_pressed = true
		else:
			input.move_axis = -1.0
	)
	_record("air flick", probe, "run right, pull left in the air")
	probe.release()


## The wall-kiss chain: slide into a side wall and jump on the contact frame.
func _probe_wall_kiss_chain() -> void:
	var probe: Object = Probe.new(Vector3(-24.0, 0.9, 0.0))
	probe.run(600, func(frame, input, _controller, _probe):
		input.move_axis = 1.0
		input.wall_contact = true
		input.wall_normal = Vector3(0.0, 0.0, 1.0)
		if _probe.grounded and frame > 120:
			input.slip_pressed = true
			input.jump_pressed = true
	)
	_record("wall-kiss chain", probe, "slide and jump against a side wall")
	probe.release()


## Turning around on the ground.
func _probe_turnaround() -> void:
	var probe: Object = Probe.new(Vector3(-24.0, 0.9, 0.0))
	probe.run(300, func(frame, input, _controller, _probe):
		input.move_axis = 1.0 if frame < 120 else -1.0
	)
	_record("turnaround", probe, "reverse the stick at full speed")
	probe.release()


## Stores one probe result for the report.
func _record(name: String, probe: Object, note: String) -> void:
	_report.append({
		"name": name,
		"note": note,
		"peak": probe.peak_speed,
		"final": probe.final_speed,
		"jumps": probe.jumps,
		"slides": probe.slides,
		"kisses": probe.kisses,
		"air": probe.max_air_bonus,
		"z": probe.max_z_velocity,
	})


## Prints what the probes found.
func _print_report() -> void:
	print("")
	print("    movement discovery report")
	print("    %-16s %8s %8s %6s %6s %6s %8s" % [
		"technique", "peak", "final", "jumps", "slides", "kisses", "air"
	])
	for entry in _report:
		print("    %-16s %8.2f %8.2f %6d %6d %6d %8.2f" % [
			entry["name"], entry["peak"], entry["final"],
			entry["jumps"], entry["slides"], entry["kisses"], entry["air"]
		])
	print("")


## Checks the invariants that must hold whatever the techniques turn out to be.
func _assert_invariants() -> void:
	heading("the invariants")
	for entry in _report:
		var name: String = entry["name"]
		ok(entry["peak"] <= SPEED_CEILING,
			"%s stays under the %.1f m/s ceiling (%.2f)" % [name, SPEED_CEILING, entry["peak"]])
		ok(entry["z"] == 0.0, "%s never leaves the XY plane" % name)
		ok(entry["air"] <= Tuning.AIR_ACCEL_MAX_CONTRIB + 0.0001,
			"%s respects the air acceleration cap" % name)
		ok(entry["kisses"] <= Tuning.WALL_KISS_CAP,
			"%s respects the wall-kiss chain cap" % name)

	heading("the promise")
	var plain := _entry("plain run")
	var hop := _entry("bunny hop")
	ok(hop["peak"] <= plain["peak"] + EXPLOIT_MARGIN,
		"bunny hopping is not a speed exploit (%.2f against %.2f)" % [hop["peak"], plain["peak"]])
	ok(hop["jumps"] > 5, "the bunny hop really did jump repeatedly (%d jumps)" % hop["jumps"])


## Finds one entry of the report by name.
func _entry(name: String) -> Dictionary:
	for entry in _report:
		if entry["name"] == name:
			return entry
	return {}
