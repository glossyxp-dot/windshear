# WindShear — play a section
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
## The room the designer plays a section in.
##
## Open this scene, press F6, and you are in the section you built. The
## section id is a number in the Inspector, so changing it and pressing F6
## again is the whole loop.
##
## The section is loaded by the section manager, which is the same one the
## game uses. The player starts at the start checkpoint of the section, so
## a checkpoint that is in the wrong place is obvious straight away.
extends Node3D

## The player controller script.
const LancerControllerScript := preload("res://addons/windshear/movement/lancer_controller.gd")
## The speed meter, in m/s.
const SpeedMeter := preload("res://addons/windshear/movement/speed_meter.gd")

## How tall Lancer is, in metres. The start checkpoint says where the feet
## go, so the body is put half its height above it.
const PLAYER_HEIGHT := 0.9

## The section to play, for example "P1.01".
@export var section_id := "P1.01"

@onready var _player: LancerControllerScript = $Player
@onready var _hud: Label = $HUD/Label
@onready var _help_panel: PanelContainer = $HUD/HelpPanel
@onready var _help_label: Label = $HUD/HelpPanel/Label

## The speed readout, in m/s.
var _meter := SpeedMeter.new()

var _hud_timer := 0.0


func _ready() -> void:
	var manager := get_node_or_null("/root/WsSections")
	if manager == null:
		_hud.text = "no section manager"
		return
	if not manager.call("load_section", section_id):
		_hud.text = "no section called %s" % section_id
		return

	_player.respawn(_start_position(manager))
	_refresh_hud()
	_help_label.text = _build_help_text()
	_help_panel.visible = false


func _physics_process(delta: float) -> void:
	# The HUD is a developer aid, not a game system: it refreshes ten times
	# a second instead of every frame, and it is the only place in this
	# scene that builds a string per update.
	_hud_timer += delta
	if _hud_timer < 0.1:
		return
	_hud_timer = 0.0
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_to_checkpoint"):
		var manager := get_node_or_null("/root/WsSections")
		if manager != null:
			_player.respawn(_start_position(manager))
		_meter.reset()
	if event.is_action_pressed("toggle_help"):
		_help_panel.visible = not _help_panel.visible


## Where the player starts, in world space.
##
## The start checkpoint is where the feet go. The body is put half its
## height above that, because the origin of a capsule is its middle.
func _start_position(manager: Node) -> Vector3:
	var checkpoint := str(manager.get("start_checkpoint_id"))
	return manager.call("checkpoint_position", checkpoint) + Vector3(0.0, PLAYER_HEIGHT, 0.0)


## Builds the mechanics reference from the tuning constants.
func _build_help_text() -> String:
	var lines := PackedStringArray()
	lines.append("SECTION %s" % section_id)
	lines.append("")
	lines.append("W A S D   walk")
	lines.append("CTRL      slide")
	lines.append("SPACE     jump")
	lines.append("mouse     camera")
	lines.append("")
	lines.append("RESET     R")
	lines.append("HELP      F1 or H")
	return "\n".join(lines)


## Refreshes the speed readout.
func _refresh_hud() -> void:
	_meter.sample(_player.velocity)
	var position := _player.global_position
	_hud.text = "SECTION %s   SPEED %6s   PEAK %6s   X %6.1f   Y %5.1f" % [
		section_id, _meter.current_text(), _meter.peak_text(),
		position.x, position.y
	]
