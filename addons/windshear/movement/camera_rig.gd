# WindShear — the 2.5D camera rig (camera and speed framing)
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
## [br]- mouse, key and stick look, with a hard pitch clamp;
## [br]- the speed dolly, which pulls back and widens the field of view as
##   Lancer picks up speed;
## [br]- the vertical framing offset, so Lancer sits below the centre of the
##   frame with headroom for the jump arc.
extends Node3D
class_name CameraRig

## Movement tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")

## Radians of rotation per pixel of mouse movement.
@export var mouse_sensitivity := 0.0022
## Radians of rotation per second at full stick deflection.
@export var controller_sensitivity := 3.0
## Radians of rotation per second while a look key is held. The arrow keys turn
## and tilt the camera; W and S tilt it only. They don't move Lancer because the
## gameplay plane has no forward axis. The mouse turns the camera by pixels,
## while a key uses a fixed rate. The key rate is slower so a keyboard player
## can line up the camera instead of whipping it past the target.
@export var key_sensitivity := 2.0
## Maximum pitch in either direction, in degrees.
@export var pitch_limit_deg := 80.0
## Field of view at a standstill, in degrees.
@export var base_fov := 72.0
## Field of view at top speed, in degrees.
@export var fast_fov := 82.0
## Camera distance at a standstill, in metres.
@export var base_distance := 7.0
## Camera distance at top speed, in metres.
@export var fast_distance := 8.4
## Height of the camera above Lancer's feet, in metres.
@export var eye_height := 1.7

## Current yaw, in radians.
var yaw := 0.0
## Current pitch, in radians.
var pitch := 0.0
## Set to true to mirror the vertical look axis.
var invert_y := false

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
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		var vertical := motion.relative.y
		if invert_y:
			vertical = -vertical
		apply_look(-motion.relative.x * mouse_sensitivity, -vertical * mouse_sensitivity)


## The look axes.
##
## The mouse controls the camera, but it isn't the only way to look. The arrow
## keys turn and tilt the camera; W and S tilt it. W and S don't move Lancer
## because the gameplay plane has no forward axis. The right stick follows the
## same path at a different rate. Its vertical axis is negated: in Godot a
## stick pushed down is a positive value, and pushing the stick down has to
## tilt the camera down, the same way the mouse does.
func _process(delta: float) -> void:
	var stick_x := Input.get_axis("look_left", "look_right")
	var stick_y := Input.get_axis("look_up", "look_down")
	if absf(stick_x) > 0.001:
		apply_look(-stick_x * controller_sensitivity * delta, 0.0)
	if absf(stick_y) > 0.001:
		var vertical := -stick_y * controller_sensitivity * delta
		if invert_y:
			vertical = -vertical
		apply_look(0.0, vertical)

	var key_x := Input.get_axis("look_key_left", "look_key_right")
	var key_y := Input.get_axis("look_key_up", "look_key_down")
	if absf(key_x) > 0.001:
		apply_look(-key_x * key_sensitivity * delta, 0.0)
	if absf(key_y) > 0.001:
		var vertical := -key_y * key_sensitivity * delta
		if invert_y:
			vertical = -vertical
		apply_look(0.0, vertical)

	_update_speed_framing()


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
	camera.fov = lerpf(base_fov, fast_fov, ratio)
	camera.position = Vector3(0.0, eye_height, lerpf(base_distance, fast_distance, ratio))


## Reads the speed of the body the rig is attached to and frames it.
func _update_speed_framing() -> void:
	if _camera_node() == null:
		return
	var body := get_parent() as CharacterBody3D
	var ratio := 0.0
	if body != null:
		ratio = absf(body.velocity.x) / Tuning.MAX_RUN_SPEED
	update_speed_framing(ratio)
