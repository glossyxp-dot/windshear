# WindShear — the movement greybox (Milestone 0 test room)
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
## A plain room with nothing in it but the things Lancer can touch: a floor,
## a few platforms, one ramp, one wall to kiss, and a line of wayfinding
## strips so the route reads at a glance even without any art.
##
## The art here is deliberately unfinished — charcoal boxes and a thin blue
## line. It exists to answer one question: does the movement feel good?
extends Node3D
class_name MovementGreybox

## Movement tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")
## The player controller script.
const LancerControllerScript := preload("res://addons/windshear/movement/lancer_controller.gd")

## Where Lancer starts (and respawns).
@export var spawn_position := Vector3(-24.0, 1.2, 0.0)

@onready var _player: LancerControllerScript = $Player
@onready var _hud: Label = $HUD/Label
@onready var _help_panel: PanelContainer = $HUD/HelpPanel
@onready var _help_label: Label = $HUD/HelpPanel/Label

var _hud_timer := 0


func _ready() -> void:
	_player.respawn(spawn_position)
	_hud.text = ""
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
		_player.respawn(spawn_position)
	if event.is_action_pressed("toggle_help"):
		_help_panel.visible = not _help_panel.visible


## The mechanics reference, read straight off the tuning constants.
##
## It is built once, when the room opens, so it can never drift away from
## what the controller actually does.
func _build_help_text() -> String:
	var lines := PackedStringArray()
	lines.append("LANCER")
	lines.append("")
	lines.append("RUN     A / D         %4.1f m/s" % Tuning.MAX_RUN_SPEED)
	lines.append("SLIDE   S / Ctrl      %4.2f s, friction %d" % [
		Tuning.SLIDE_DURATION, int(Tuning.SLIDE_FRICTION)
	])
	lines.append("JUMP    SPACE        %4.1f m/s, apex %4.1f m" % [
		Tuning.JUMP_VELOCITY, _jump_apex()
	])
	lines.append("AIR     A / D in air  +%4.1f m/s a jump" % Tuning.AIR_ACCEL_MAX_CONTRIB)
	lines.append("KISS    slide + jump +%4.1f m/s, x%d, max %4.1f" % [
		Tuning.WALL_KISS_BOOST, Tuning.WALL_KISS_CAP, Tuning.WALL_KISS_SPEED_CEILING
	])
	lines.append("")
	lines.append("coyote %d f   buffer %d f   chain %d f" % [
		Tuning.COYOTE_FRAMES, Tuning.JUMP_BUFFER_FRAMES, Tuning.WALL_KISS_CHAIN_FRAMES
	])
	lines.append("")
	lines.append("not built yet: filament, mantle")
	lines.append("")
	lines.append("RESET   R")
	lines.append("HELP    F1 or H")
	return "\n".join(lines)


## How high a full jump goes, in metres.
func _jump_apex() -> float:
	return Tuning.JUMP_VELOCITY * Tuning.JUMP_VELOCITY / (2.0 * Tuning.GRAVITY)


func _refresh_hud() -> void:
	var speed := absf(_player.velocity.x)
	var position := _player.global_position
	_hud.text = "SPEED %5.1f m/s    X %6.1f    Y %5.1f    KISS %d" % [
		speed, position.x, position.y, _player.wall_kiss_count
	]
