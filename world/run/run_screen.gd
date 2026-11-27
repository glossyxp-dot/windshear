# WindShear — the screen a run is played on
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
## The loop: a section, the player in it, the objective on the screen, and
## the next section when the player gets to the end.
##
## The section is loaded by the section manager, which is the same one the
## designer plays their own section with. The player starts at the start
## checkpoint of the section, so a checkpoint in the wrong place is obvious
## straight away.
##
## The section that comes next is the next one the designer has actually
## made. The campaign is three hundred sections long and most of them are
## not written yet, so the run walks into the next finished one and waits
## there when there is none.
extends Node3D

## The player controller script.
const LancerControllerScript := preload("res://addons/windshear/movement/lancer_controller.gd")
## The speed meter, in m/s.
const SpeedMeter := preload("res://addons/windshear/movement/speed_meter.gd")

## How tall Lancer is, in metres. The start checkpoint says where the feet
## go, so the body is put half its height above it.
const PLAYER_HEIGHT := 0.9

## How close the player has to be to the end checkpoint, in metres.
const CLEAR_RADIUS := 1.8

## How far above or below the checkpoint still counts, in metres.
const CLEAR_HEIGHT := 3.0

## How long the banner stays up before the next section starts, in seconds.
const CLEAR_PAUSE := 1.25

## How far below the section the player has to fall before it puts them back.
const FALL_LIMIT := -60.0

## The section to play. Empty means the one the run started in.
@export var start_section := ""

## Whether the screen goes back to the menu when the campaign ends.
##
## The test turns this off, because a test does not want the menu to
## replace the scene it is running in.
@export var leave_when_the_campaign_ends := true

@onready var _player: LancerControllerScript = $Player
@onready var _rig: Node = $Player/CameraRig
@onready var _hud: Control = $HUD/SectionHUD

## The section that is running.
var _section_id := ""

## The frames spent in the running section.
var _section_frames := 0

## Whether the section has been finished and the banner is up.
var _clearing := false

## Whether the campaign is over and the screen is waiting to leave.
var _finished := false

## The seconds left on the banner.
var _clear_timer := 0.0

## The speed readout, in m/s.
var _meter := SpeedMeter.new()

## The HUD refreshes ten times a second, not every frame.
var _hud_timer := 0.0


func _ready() -> void:
	_section_id = start_section.strip_edges()
	if _section_id.is_empty():
		_section_id = WsGame.current_section
	if _section_id.is_empty():
		_section_id = "P1.01"
	WsGame.start_run(_section_id)
	_apply_camera_settings()
	_load_section(_section_id)


func _physics_process(delta: float) -> void:
	# The HUD is furniture, not a game system: it refreshes ten times a
	# second instead of every frame.
	_hud_timer += delta
	if _hud_timer >= 0.1:
		_hud_timer = 0.0
		_refresh_hud()

	if _clearing:
		_clear_timer -= delta
		if _clear_timer <= 0.0:
			if _finished:
				_leave_after_the_campaign()
			else:
				_advance()
		return

	_section_frames += 1
	if _is_at_the_end():
		_complete()
		return
	if _player.global_position.y < FALL_LIMIT:
		_player.respawn(_start_position(_manager()))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_to_checkpoint"):
		_player.respawn(_start_position(_manager()))
		_meter.reset()
	if event.is_action_pressed("ui_cancel"):
		_leave_to_the_menu()


## Loads a section and puts the player at its start checkpoint.
func _load_section(section_id: String) -> void:
	var manager := _manager()
	if manager == null:
		_hud.set_objective("NO SECTION MANAGER")
		return
	if not manager.call("load_section", section_id):
		_hud.set_objective("NO SECTION %s" % section_id)
		return

	_section_id = section_id
	_section_frames = 0
	_clearing = false
	_finished = false
	_meter.reset()
	_player.respawn(_start_position(manager))
	_hud.set_section(_section_id, _section_name(manager), _objective(manager))
	_hud.set_time(0.0)


## The name the campaign index gives the running section.
func _section_name(manager: Node) -> String:
	var entry: Dictionary = manager.call("section_entry", _section_id)
	return str(entry.get("display_name", ""))


## The objective the designer wrote on the section root.
func _objective(manager: Node) -> String:
	var section: Node = manager.get("current_section")
	if section == null:
		return ""
	if not "objective" in section:
		return ""
	var value: Variant = section.get("objective")
	if value == null:
		return ""
	return str(value)


## Where the player starts, in world space.
##
## The start checkpoint is where the feet go. The body is put half its
## height above that, because the origin of a capsule is its middle.
func _start_position(manager: Node) -> Vector3:
	if manager == null:
		return Vector3.ZERO
	var checkpoint := str(manager.get("start_checkpoint_id"))
	return manager.call("checkpoint_position", checkpoint) + Vector3(0.0, PLAYER_HEIGHT, 0.0)


## Whether the player has reached the end checkpoint.
func _is_at_the_end() -> bool:
	var manager := _manager()
	if manager == null:
		return false
	var checkpoint := str(manager.get("end_checkpoint_id"))
	if checkpoint.is_empty():
		return false
	var target: Vector3 = manager.call("checkpoint_position", checkpoint)
	var feet := _player.global_position - Vector3(0.0, PLAYER_HEIGHT, 0.0)
	var flat := Vector2(feet.x - target.x, feet.z - target.z)
	return flat.length() <= CLEAR_RADIUS and absf(feet.y - target.y) <= CLEAR_HEIGHT


## The section is finished.
func _complete() -> void:
	_clearing = true
	_clear_timer = CLEAR_PAUSE
	_hud.show_banner("SECTION CLEAR")


## The next section starts, or the campaign ends.
func _advance() -> void:
	var manager := _manager()
	var next := ""
	if manager != null:
		next = str(manager.call("next_authored_section_id", _section_id))
	if next.is_empty():
		_finished = true
		_clear_timer = CLEAR_PAUSE
		_hud.show_banner("CAMPAIGN COMPLETE")
		return
	_hud.hide_banner()
	_load_section(next)


## The run is over and the screen goes back to the menu.
func _leave_to_the_menu() -> void:
	_clearing = false
	_finished = false
	WsGame.finish_run()
	if not leave_when_the_campaign_ends:
		return
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")


## The campaign is over, and the screen goes back to the menu.
func _leave_after_the_campaign() -> void:
	_clearing = false
	_finished = false
	WsGame.finish_campaign()
	if not leave_when_the_campaign_ends:
		return
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")


## The section manager.
func _manager() -> Node:
	return get_node_or_null("/root/WsSections")


## Puts the player's settings on the camera.
func _apply_camera_settings() -> void:
	_rig.set("mouse_sensitivity", WsGame.mouse_sensitivity)
	_rig.set("invert_y", WsGame.invert_y)
	_rig.set("base_fov", WsGame.fov)


## Refreshes the clock on the HUD.
func _refresh_hud() -> void:
	_hud.set_time(float(_section_frames) / 60.0)
