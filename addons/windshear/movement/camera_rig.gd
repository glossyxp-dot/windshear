# WindShear — the camera rig (camera and speed framing)
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
## The camera rig stays parented to Lancer. There is no separate cutscene
## camera in this game. A major beat freezes the world instead (see
## `GAME_DESIGN.md` §5).
##
## The rig owns three things:
## [br]- mouse and stick look, which orbits the camera around Lancer, with a
##   hard pitch clamp;
## [br]- the speed dolly, which pulls back and widens the field of view as
##   Lancer picks up speed;
## [br]- the vertical framing offset, so Lancer sits below the centre of the
##   frame with headroom for the jump arc.
extends Node3D
class_name CameraRig

## Movement tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")

## Radians of rotation per pixel of mouse movement.
@export var mouse_sensitivity := Tuning.CAMERA_MOUSE_SENSITIVITY
## Radians of rotation per second at full stick deflection.
@export var controller_sensitivity := 3.0
## Maximum pitch in either direction, in degrees.
@export var pitch_limit_deg := 80.0
## Field of view at a standstill, in degrees.
@export var base_fov := Tuning.CAMERA_BASE_FOV
## Field of view at top speed, in degrees.
@export var fast_fov := Tuning.CAMERA_FAST_FOV
## Camera distance at a standstill, in metres.
@export var base_distance := Tuning.CAMERA_BASE_DISTANCE
## Camera distance at top speed, in metres.
@export var fast_distance := Tuning.CAMERA_FAST_DISTANCE
## Height of the camera above Lancer's feet, in metres.
@export var eye_height := Tuning.CAMERA_EYE_HEIGHT

## Current yaw, in radians.
var yaw := 0.0
## Current pitch, in radians.
var pitch := 0.0
## Set to true to mirror the vertical look axis.
var invert_y := false
## Set to false to stop the camera reading the mouse and the stick. The
## workbench turns it off while you are dragging a slider, so the room does
## not spin every time you move the pointer.
var look_enabled := true

## Live overrides for the camera numbers.
##
## The workbench points this at the same dictionary the `WsTweak` autoload
## holds, so a slider that moves writes straight into the live rig. An empty
## dictionary means the exported numbers, which is what the test suite always
## gets.
var overrides := {}

var _target_yaw := 0.0
var _target_pitch := 0.0
var _camera: Camera3D


func _ready() -> void:
	_camera_node()
	_target_yaw = yaw
	_target_pitch = pitch
	_commit_look()


## The camera this rig drives. Looks it up lazily so the rig can be tested
## without being added to a scene tree first.
func _camera_node() -> Camera3D:
	if _camera == null:
		_camera = get_node_or_null("Camera3D") as Camera3D
	return _camera


func _unhandled_input(event: InputEvent) -> void:
	if not look_enabled:
		return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		var vertical := motion.relative.y
		if invert_y:
			vertical = -vertical
		var sensitivity := _live_value("camera_mouse_sensitivity", mouse_sensitivity)
		apply_look(-motion.relative.x * sensitivity, -vertical * sensitivity)


## The look axes.
##
## The mouse controls the camera and nothing on the keyboard does. The rig
## rotates around Lancer, so a mouse turn walks the camera around the body and
## the controller reads that yaw to decide which way "forward" is. The right
## stick is the other route, for a pad. Its vertical axis is negated: in Godot
## a stick pushed down is a positive value, and pushing the stick down has to
## tilt the camera down, the same way the mouse does.
func _process(delta: float) -> void:
	if look_enabled:
		var stick_x := Input.get_axis("look_left", "look_right")
		var stick_y := Input.get_axis("look_up", "look_down")
		if absf(stick_x) > 0.001:
			apply_look(-stick_x * controller_sensitivity * delta, 0.0)
		if absf(stick_y) > 0.001:
			var vertical := -stick_y * controller_sensitivity * delta
			if invert_y:
				vertical = -vertical
			apply_look(0.0, vertical)

	_update_speed_framing()


## The live value of one knob.
##
## The export on the node is the base value and a workbench override wins, so
## a slider beats the Inspector while the room is open. Without an override
## this is just the exported number.
func _live_value(key: String, fallback: float) -> float:
	if overrides.has(key):
		return float(overrides[key])
	return fallback


## Applies a look delta in radians and clamps the pitch.
func apply_look(yaw_delta: float, pitch_delta: float) -> void:
	_target_yaw += yaw_delta
	var limit := deg_to_rad(pitch_limit_deg)
	_target_pitch = clampf(_target_pitch + pitch_delta, -limit, limit)
	_commit_look()


## Writes the current look angles onto the rig.
func _commit_look() -> void:
	yaw = _target_yaw
	pitch = _target_pitch
	rotation.y = yaw
	rotation.x = pitch


## The yaw wrapped into [-PI, PI]. Handy for tests and for the HUD.
func yaw_wrapped() -> float:
	return wrapf(yaw, -PI, PI)


## Pulls the camera back and widens the lens with Lancer's speed.
func update_speed_framing(speed_ratio: float) -> void:
	var camera := _camera_node()
	if camera == null:
		return
	var ratio := clampf(speed_ratio, 0.0, 1.0)
	var fov_from := _live_value("camera_base_fov", base_fov)
	var fov_to := _live_value("camera_fast_fov", fast_fov)
	var back_from := _live_value("camera_base_distance", base_distance)
	var back_to := _live_value("camera_fast_distance", fast_distance)
	var height := _live_value("camera_eye_height", eye_height)
	camera.fov = lerpf(fov_from, fov_to, ratio)
	camera.position = Vector3(0.0, height, lerpf(back_from, back_to, ratio))


## Reads the speed of the body the rig is attached to and frames it.
func _update_speed_framing() -> void:
	if _camera_node() == null:
		return
	var body := get_parent() as CharacterBody3D
	var ratio := 0.0
	if body != null:
		var top_speed := _live_value("max_run_speed", Tuning.MAX_RUN_SPEED)
		ratio = Vector2(body.velocity.x, body.velocity.z).length() / top_speed
	update_speed_framing(ratio)
