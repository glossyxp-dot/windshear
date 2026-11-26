# WindShear — speed measurement tests
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
## The speed readout is in metres per second, and it has to stay in metres
## per second. A unit that changes between the tuning file, the HUD and the
## discovery report is a unit nobody can compare. Quoting 14.0 m/s is only
## useful if a player can check it.
extends "res://tests/ws_test.gd"

## The speed meter.
const SpeedMeter := preload("res://addons/windshear/movement/speed_meter.gd")

## The movement tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")


## Name shown in the suite output.
func suite_name() -> String:
	return "the speed is measured in metres per second"


## Exercises the speed meter. The meter is a RefCounted, so the suite leaves
## release to its own reference count. Calling free() on one is an engine
## error, and a suite that prints engine errors is a suite nobody reads.
func run() -> void:
	_test_the_reading()
	_test_the_peak()
	_test_the_reset()
	_test_the_units()


## A reading is the horizontal speed, in metres per second.
func _test_the_reading() -> void:
	heading("the reading")
	var meter := SpeedMeter.new()
	meter.sample(Vector3(12.5, 0.0, 0.0))
	near(meter.current, 12.5, 0.001, "the meter reads 12.5 m/s")

	# Left is left. Velocity direction does not change speed.
	meter.sample(Vector3(-8.0, 0.0, 0.0))
	near(meter.current, 8.0, 0.001, "the meter ignores the direction of travel")

	# Vertical speed is not part of the number. The game moves on the X/Z
	# ground plane.
	meter.sample(Vector3(3.0, 9.0, 0.0))
	near(meter.current, 3.0, 0.001, "the meter reads the horizontal axis only")


## The peak holds the fastest reading until it is reset.
func _test_the_peak() -> void:
	heading("the peak")
	var meter := SpeedMeter.new()
	meter.sample(Vector3(10.0, 0.0, 0.0))
	meter.sample(Vector3(18.0, 0.0, 0.0))
	meter.sample(Vector3(4.0, 0.0, 0.0))
	near(meter.peak, 18.0, 0.001, "the peak keeps the fastest reading")
	near(meter.current, 4.0, 0.001, "the current reading keeps moving")

	# A slower reading does not lower the peak.
	meter.sample(Vector3(1.0, 0.0, 0.0))
	near(meter.peak, 18.0, 0.001, "a slow reading does not lower the peak")


## A respawn clears the peak, so it is the peak of the attempt.
func _test_the_reset() -> void:
	heading("the reset")
	var meter := SpeedMeter.new()
	meter.sample(Vector3(16.0, 0.0, 0.0))
	meter.reset()
	near(meter.current, 0.0, 0.001, "the reset clears the reading")
	near(meter.peak, 0.0, 0.001, "the reset clears the peak")


## The readout says metres per second. That is the whole point.
func _test_the_units() -> void:
	heading("the units")
	var meter := SpeedMeter.new()
	meter.sample(Vector3(Tuning.MAX_RUN_SPEED, 0.0, 0.0))
	ok(meter.current_text().contains("m/s"), "the reading says m/s")
	ok(meter.peak_text().contains("m/s"), "the peak says m/s")
	ok(meter.current_text().contains("%.1f" % Tuning.MAX_RUN_SPEED),
		"the reading quotes the run speed to one decimal")
