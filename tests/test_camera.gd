# WindShear — camera rig tests
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
## The camera is the other half of an FPS game. Two rules are non-negotiable:
## the pitch never flips over the top, and the rig never leaves Lancer.
##
## Mouse movement controls the camera, and so does the right stick. Nothing on
## the keyboard does. The controller reads the rig's yaw and turns WASD into a
## world direction, so forward follows the camera. The speed dolly makes
## 14 m/s read as fast.
extends "res://tests/ws_test.gd"

## The camera rig.
const Rig := preload("res://addons/windshear/movement/camera_rig.gd")
## Movement tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")


func suite_name() -> String:
	return "the camera rig behaves"


func _make_rig() -> Array:
	var rig: Object = Rig.new()
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	rig.add_child(camera)
	return [rig, camera]


func run() -> void:
	_test_pitch_clamp()
	_test_yaw_wraps()
	_test_sensitivity()
	_test_speed_dolly()
	_test_camera_is_a_child()


func _test_pitch_clamp() -> void:
	heading("the pitch clamp")
	var pair := _make_rig()
	var rig: Object = pair[0]
	var limit: float = deg_to_rad(rig.pitch_limit_deg)

	rig.apply_look(0.0, 10.0)
	near(rig.pitch, limit, 0.0001, "the pitch stops at the limit")
	rig.apply_look(0.0, -20.0)
	near(rig.pitch, -limit, 0.0001, "the pitch stops at the lower limit")
	rig.apply_look(0.0, 0.5)
	near(rig.pitch, -limit + 0.5, 0.0001, "the pitch moves freely inside the limit")
	ok(rig.pitch < PI * 0.5, "the camera never flips over the top")
	pair[0].free()

func _test_yaw_wraps() -> void:
	heading("the yaw")
	var pair := _make_rig()
	var rig: Object = pair[0]
	rig.apply_look(TAU * 3.0, 0.0)
	near(rig.yaw_wrapped(), 0.0, 0.0001, "three full turns come back to where they started")
	rig.apply_look(PI * 0.5, 0.0)
	near(rig.yaw_wrapped(), PI * 0.5, 0.0001, "a quarter turn lands on the quarter")
	pair[0].free()

func _test_sensitivity() -> void:
	heading("look sensitivity")
	var pair := _make_rig()
	var rig: Object = pair[0]
	var sensitivity: float = rig.mouse_sensitivity
	rig.apply_look(sensitivity * 100.0, 0.0)
	near(rig.yaw, sensitivity * 100.0, 0.000001,
		"100 pixels of mouse movement turn the camera by 100 times the sensitivity")
	ok(sensitivity > 0.0005 and sensitivity < 0.01, "the sensitivity is in a sane range")
	pair[0].free()

func _test_speed_dolly() -> void:
	heading("the speed dolly")
	var pair := _make_rig()
	var rig: Object = pair[0]
	var camera: Camera3D = pair[1]

	rig.update_speed_framing(0.0)
	near(camera.fov, rig.base_fov, 0.001, "a standstill uses the narrow lens")
	near(camera.position.z, rig.base_distance, 0.001, "a standstill uses the close distance")

	rig.update_speed_framing(1.0)
	near(camera.fov, rig.fast_fov, 0.001, "top speed uses the wide lens")
	near(camera.position.z, rig.fast_distance, 0.001, "top speed pulls the camera back")
	ok(rig.fast_fov > rig.base_fov, "the lens gets wider with speed")
	ok(rig.fast_distance > rig.base_distance, "the camera pulls back with speed")

	rig.update_speed_framing(0.5)
	near(camera.fov, (rig.base_fov + rig.fast_fov) * 0.5, 0.001,
		"half speed is halfway between the two")
	pair[0].free()

func _test_camera_is_a_child() -> void:
	heading("the camera belongs to the rig")
	var pair := _make_rig()
	var rig: Object = pair[0]
	var camera: Camera3D = pair[1]
	ok(camera.get_parent() == rig, "the camera is a child of the rig")
	ok(rig is Node3D, "the rig is a 3D node")
	pair[0].free()
