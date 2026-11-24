# WindShear — test case base class
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
## A small test harness with no dependency and no plugin. The whole suite runs
## in a headless Godot instance and exits with a non-zero status when something
## fails. CI needs nothing else.
##
## A suite names itself and does its work in [method run]. I wrote the failure
## messages as full sentences because a failing test should read like a
## sentence.
extends RefCounted
class_name WSTest

## Failure messages collected during the run.
var failures: PackedStringArray = []
## Assertions checked so far.
var checks := 0


## Name shown in the suite output.
func suite_name() -> String:
	return "unnamed suite"


## Runs the suite. Override this.
func run() -> void:
	pass


## Runs the suite against a live scene. Override this when the suite needs
## the scene tree. The default does nothing.
func run_with_scene(_scene: Node) -> void:
	pass


## Prints a heading inside the suite output.
func heading(text: String) -> void:
	print("    - " + text)


## Records one assertion.
func ok(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


## Records a floating-point assertion within a tolerance.
func near(actual: float, expected: float, tolerance: float, message: String) -> void:
	checks += 1
	if absf(actual - expected) > tolerance:
		failures.append("%s (expected %.6f +/- %.6f, got %.6f)" % [
			message, expected, tolerance, actual
		])


## Records an integer assertion.
func same(actual: int, expected: int, message: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s (expected %d, got %d)" % [message, expected, actual])


## Records a string assertion.
func text(actual: String, expected: String, message: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s (expected '%s', got '%s')" % [message, expected, actual])
