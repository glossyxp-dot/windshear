# WindShear — live movement overrides for the workbench (the WsTweak autoload)
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
## The canonical movement numbers live in `ws_tuning.gd` and the test suite
## pins them against `TECH_SPEC.md`. This autoload sits on top of them.
##
## The Movement Workbench writes overrides here, the controller and the camera
## rig read them, and the numbers go live while you are standing in the room.
## That is the whole point: you tune the movement by feel, not by editing code
## and re-running the suite.
##
## Overrides are never loaded automatically. Only the workbench loads them, so
## the headless suite always runs on the documented numbers even if somebody
## left a saved profile behind. The profile lives outside the repository, in
## the user data folder, because a tuned number is not canon until somebody
## writes it into the code and the documents.
extends Node

## The canonical tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")

## Where the saved profile lives. It is outside the repository on purpose.
const PROFILE_PATH := "user://movement_workbench.json"

## The file the profile is read from and written to.
##
## It is a property rather than a constant so the test suite can point it
## somewhere harmless. A test must never overwrite the real profile.
var profile_file := PROFILE_PATH

## Every number the workbench can move.
##
## Each entry carries the label, the unit, the range, the step, the default and
## the name of the constant the default came from. The panel builds itself out
## of this table, so adding a knob is one entry and no scene editing. The
## tuning suite checks every default against the constant it claims to come
## from, so the panel cannot quietly start lying.
const TUNABLES := {
	"max_run_speed": {
		"label": "run speed", "unit": "m/s", "group": "ground",
		"min": 4.0, "max": 30.0, "step": 0.1, "integer": false,
		"default": Tuning.MAX_RUN_SPEED, "const": "MAX_RUN_SPEED",
	},
	"ground_accel": {
		"label": "ground accel", "unit": "m/s2", "group": "ground",
		"min": 10.0, "max": 300.0, "step": 1.0, "integer": false,
		"default": Tuning.GROUND_ACCEL, "const": "GROUND_ACCEL",
	},
	"ground_decel": {
		"label": "ground decel", "unit": "m/s2", "group": "ground",
		"min": 10.0, "max": 300.0, "step": 1.0, "integer": false,
		"default": Tuning.GROUND_DECEL, "const": "GROUND_DECEL",
	},
	"air_accel": {
		"label": "air accel", "unit": "m/s2", "group": "air",
		"min": 0.0, "max": 200.0, "step": 1.0, "integer": false,
		"default": Tuning.AIR_ACCEL, "const": "AIR_ACCEL",
	},
	"air_accel_max_contrib": {
		"label": "air cap", "unit": "m/s", "group": "air",
		"min": 0.0, "max": 10.0, "step": 0.1, "integer": false,
		"default": Tuning.AIR_ACCEL_MAX_CONTRIB, "const": "AIR_ACCEL_MAX_CONTRIB",
	},
	"gravity": {
		"label": "gravity", "unit": "m/s2", "group": "air",
		"min": 10.0, "max": 150.0, "step": 1.0, "integer": false,
		"default": Tuning.GRAVITY, "const": "GRAVITY",
	},
	"jump_velocity": {
		"label": "jump velocity", "unit": "m/s", "group": "jump",
		"min": 4.0, "max": 30.0, "step": 0.1, "integer": false,
		"default": Tuning.JUMP_VELOCITY, "const": "JUMP_VELOCITY",
	},
	"jump_cut": {
		"label": "jump cut", "unit": "x", "group": "jump",
		"min": 0.05, "max": 1.0, "step": 0.05, "integer": false,
		"default": Tuning.JUMP_CUT, "const": "JUMP_CUT",
	},
	"coyote_frames": {
		"label": "coyote", "unit": "frames", "group": "jump",
		"min": 0.0, "max": 30.0, "step": 1.0, "integer": true,
		"default": float(Tuning.COYOTE_FRAMES), "const": "COYOTE_FRAMES",
	},
	"jump_buffer_frames": {
		"label": "jump buffer", "unit": "frames", "group": "jump",
		"min": 0.0, "max": 30.0, "step": 1.0, "integer": true,
		"default": float(Tuning.JUMP_BUFFER_FRAMES), "const": "JUMP_BUFFER_FRAMES",
	},
	"slide_duration": {
		"label": "slide time", "unit": "s", "group": "slide",
		"min": 0.1, "max": 1.5, "step": 0.05, "integer": false,
		"default": Tuning.SLIDE_DURATION, "const": "SLIDE_DURATION",
	},
	"slide_friction": {
		"label": "slide friction", "unit": "m/s2", "group": "slide",
		"min": 0.0, "max": 40.0, "step": 0.5, "integer": false,
		"default": Tuning.SLIDE_FRICTION, "const": "SLIDE_FRICTION",
	},
	"slide_min_speed": {
		"label": "slide needs", "unit": "m/s", "group": "slide",
		"min": 0.0, "max": 14.0, "step": 0.5, "integer": false,
		"default": Tuning.SLIDE_MIN_SPEED, "const": "SLIDE_MIN_SPEED",
	},
	"wall_kiss_window_frames": {
		"label": "wall window", "unit": "frames", "group": "wall-jump",
		"min": 1.0, "max": 10.0, "step": 1.0, "integer": true,
		"default": float(Tuning.WALL_KISS_WINDOW_FRAMES), "const": "WALL_KISS_WINDOW_FRAMES",
	},
	"wall_kiss_boost": {
		"label": "wall boost", "unit": "m/s", "group": "wall-jump",
		"min": 0.0, "max": 3.0, "step": 0.05, "integer": false,
		"default": Tuning.WALL_KISS_BOOST, "const": "WALL_KISS_BOOST",
	},
	"wall_kiss_cap": {
		"label": "wall chain", "unit": "jumps", "group": "wall-jump",
		"min": 1.0, "max": 10.0, "step": 1.0, "integer": true,
		"default": float(Tuning.WALL_KISS_CAP), "const": "WALL_KISS_CAP",
	},
	"wall_kiss_chain_frames": {
		"label": "wall chain life", "unit": "frames", "group": "wall-jump",
		"min": 5.0, "max": 120.0, "step": 1.0, "integer": true,
		"default": float(Tuning.WALL_KISS_CHAIN_FRAMES), "const": "WALL_KISS_CHAIN_FRAMES",
	},
	"wall_kiss_speed_ceiling": {
		"label": "speed ceiling", "unit": "m/s", "group": "wall-jump",
		"min": 14.0, "max": 40.0, "step": 0.1, "integer": false,
		"default": Tuning.WALL_KISS_SPEED_CEILING, "const": "WALL_KISS_SPEED_CEILING",
	},
	"camera_mouse_sensitivity": {
		"label": "mouse speed", "unit": "rad/px", "group": "camera",
		"min": 0.0005, "max": 0.01, "step": 0.0001, "integer": false,
		"default": Tuning.CAMERA_MOUSE_SENSITIVITY, "const": "CAMERA_MOUSE_SENSITIVITY",
	},
	"camera_base_distance": {
		"label": "camera back", "unit": "m", "group": "camera",
		"min": 3.0, "max": 15.0, "step": 0.1, "integer": false,
		"default": Tuning.CAMERA_BASE_DISTANCE, "const": "CAMERA_BASE_DISTANCE",
	},
	"camera_fast_distance": {
		"label": "camera back at speed", "unit": "m", "group": "camera",
		"min": 3.0, "max": 20.0, "step": 0.1, "integer": false,
		"default": Tuning.CAMERA_FAST_DISTANCE, "const": "CAMERA_FAST_DISTANCE",
	},
	"camera_eye_height": {
		"label": "camera height", "unit": "m", "group": "camera",
		"min": 0.5, "max": 4.0, "step": 0.05, "integer": false,
		"default": Tuning.CAMERA_EYE_HEIGHT, "const": "CAMERA_EYE_HEIGHT",
	},
	"camera_base_fov": {
		"label": "fov", "unit": "deg", "group": "camera",
		"min": 50.0, "max": 110.0, "step": 1.0, "integer": false,
		"default": Tuning.CAMERA_BASE_FOV, "const": "CAMERA_BASE_FOV",
	},
	"camera_fast_fov": {
		"label": "fov at speed", "unit": "deg", "group": "camera",
		"min": 50.0, "max": 120.0, "step": 1.0, "integer": false,
		"default": Tuning.CAMERA_FAST_FOV, "const": "CAMERA_FAST_FOV",
	},
}

## The groups, in the order the panel shows them.
const GROUPS := ["ground", "air", "jump", "slide", "wall-jump", "camera"]

## The live values, by tunable name. Empty means "use the documented number".
##
## The controller and the camera rig hold a reference to this same dictionary,
## so a slider that moves writes straight into the live simulation.
var overrides := {}

## The player's notes about this profile. They save with it.
var notes := ""


## The live value of one tunable.
func value(key: String) -> float:
	if overrides.has(key):
		return float(overrides[key])
	return float(TUNABLES[key]["default"])


## The live value of one tunable, rounded to whole frames or whole jumps.
func int_value(key: String) -> int:
	return int(round(value(key)))


## True when this tunable has been moved off its documented value.
func is_overridden(key: String) -> bool:
	return overrides.has(key)


## Moves one tunable.
func set_override(key: String, new_value: float) -> void:
	overrides[key] = new_value


## Puts one tunable back to its documented value.
func clear_override(key: String) -> void:
	overrides.erase(key)


## Puts every tunable back to its documented value.
func clear_all() -> void:
	overrides.clear()


## The absolute path of the profile file.
func profile_path() -> String:
	return ProjectSettings.globalize_path(profile_file)


## Loads the saved profile. Returns false when there isn't one.
func load_profile() -> bool:
	if not FileAccess.file_exists(profile_file):
		return false
	var file := FileAccess.open(profile_file, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	overrides.clear()
	var saved: Dictionary = parsed.get("overrides", {})
	for key in saved.keys():
		if TUNABLES.has(key):
			overrides[key] = float(saved[key])
	notes = String(parsed.get("notes", ""))
	return true


## Saves the profile. Returns false when the file could not be written.
func save_profile() -> bool:
	var file := FileAccess.open(profile_file, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({
		"overrides": overrides,
		"notes": notes,
	}, "  "))
	return true


## The profile as a block of text, for pasting into a message.
func profile_text() -> String:
	return JSON.stringify({
		"overrides": overrides,
		"notes": notes,
	}, "  ")
